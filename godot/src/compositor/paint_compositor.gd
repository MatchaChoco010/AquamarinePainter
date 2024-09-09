## レイヤーなどの合成を行うクラス。
class_name PaintCompositor
extends Node


var _path_compositor: PathPaintCompositor = PathPaintCompositor.new()
var _fill_compositor: FillPaintCompositor = FillPaintCompositor.new()
var _group_compositor: GroupPaintCompositor = GroupPaintCompositor.new()
var _root_compositor: RootPaintCompositor = RootPaintCompositor.new()


var texture_size: Vector2i

var _texture_pool: Array[TextureHandle] = []

var _create_texture_callables: Array[Callable] = []

class TextureHandle extends RefCounted:
	var valid: bool = false
	var texture: Texture2DRD
	var texture_rid: RID
	var texture_size: Vector2i


class MipTextureHandle extends RefCounted:
	var valid: bool = false
	var texture: Texture2DRD
	var texture_rid: RID
	var texture_size: Vector2i
	var mipmap_texture_rids: Array[RID] = []
	var mip_size: int


var composite_textures: Dictionary = {}

var root_composite_texture: MipTextureHandle = null

var need_composite: bool = false


## テクスチャを一度に大量に生成するとvmaがエラーを起こしてテクスチャの生成に失敗するので、
## 一度に大量にテクスチャを生成しないようにフレーム分散して生成する。
func step_create_texture() -> void:
	# 1フレーム中にテクスチャ生成は最大32個まで
	if _create_texture_callables.size() > 0:
		for i in 32:
			if _create_texture_callables.size() == 0:
				break
			var callable: Callable = _create_texture_callables.pop_front()
			RenderingServer.call_on_render_thread(callable)


## テクスチャをレンダースレッドで生成する。
func _create_texture_in_render_thread(handle: TextureHandle, create_texture_size: Vector2i) -> void:
	var rd := RenderingServer.get_rendering_device()

	var texture := Texture2DRD.new()

	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = create_texture_size.x * 1
	tf.height = create_texture_size.y * 1
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + \
		RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var texture_rid := rd.texture_create(tf, RDTextureView.new(), [])
	rd.texture_clear(texture_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)

	texture.texture_rd_rid = texture_rid

	handle.texture = texture
	handle.texture_rid = texture_rid
	handle.texture_size = create_texture_size
	handle.valid = true


## テクスチャをレンダースレッドで解放する。
func _free_texture_in_render_thread(handle: TextureHandle) -> void:
	handle.valid = false
	var rd := RenderingServer.get_rendering_device()
	rd.free_rid(handle.texture_rid)


## テクスチャをプールから取得する。
func _get_texture_from_pool() -> TextureHandle:
	if _texture_pool.size() > 1:
		return _texture_pool.pop_back()
	var texture_handle := TextureHandle.new()
	_create_texture_callables.append(_create_texture_in_render_thread.bind(texture_handle, texture_size))
	return texture_handle


## テクスチャをプールに返却する。
func _free_texture_to_pool(handle: TextureHandle) -> void:
	if handle.texture_size == texture_size:
		_texture_pool.append(handle)
	else:
		RenderingServer.call_on_render_thread(_free_texture_in_render_thread.bind(handle))


## Mipテクスチャをレンダースレッドで生成する。
func _create_mip_texture_in_render_thread(handle: MipTextureHandle, create_texture_size: Vector2i) -> void:
	var rd := RenderingServer.get_rendering_device()

	var texture := Texture2DRD.new()

	var mip_size := int(log(maxf(create_texture_size.x, create_texture_size.y)) / log(2.0)) + 1

	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = create_texture_size.x * 1
	tf.height = create_texture_size.y * 1
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = mip_size
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + \
		RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var texture_rid := rd.texture_create(tf, RDTextureView.new(), [])
	rd.texture_clear(texture_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)

	texture.texture_rd_rid = texture_rid

	var mipmap_texture_rids: Array[RID] = []
	for i in mip_size:
		mipmap_texture_rids.append(rd.texture_create_shared_from_slice(RDTextureView.new(), texture_rid, 0, i))

	handle.texture = texture
	handle.texture_rid = texture_rid
	handle.texture_size = create_texture_size
	handle.mipmap_texture_rids = mipmap_texture_rids
	handle.mip_size = mip_size
	handle.valid = true


## Mipテクスチャをレンダースレッドで解放する。
func _free_mip_texture_in_render_thread(handle: MipTextureHandle) -> void:
	handle.valid = false
	var rd := RenderingServer.get_rendering_device()
	for rid in handle.mipmap_texture_rids:
		rd.free_rid(rid)
	rd.free_rid(handle.texture_rid)


## Mipテクスチャをプールから取得する。
func _create_mip_texture() -> MipTextureHandle:
	var mip_texture_handle := MipTextureHandle.new()
	RenderingServer.call_on_render_thread(_create_mip_texture_in_render_thread.bind(mip_texture_handle, texture_size))
	return mip_texture_handle


## Mipテクスチャをプールに返却する。
func _free_mip_texture(handle: MipTextureHandle) -> void:
	RenderingServer.call_on_render_thread(_free_mip_texture_in_render_thread.bind(handle))


## ペイントレイヤーのcomposite_texturesをrootに合わせて生成破棄する。
func update() -> void:
	var ids: Array[String] = []
	for layer: PaintLayer in Main.layers.get_flatten_layers():
		ids.append(layer.id)
	for id: String in composite_textures.keys():
		if not ids.has(id):
			@warning_ignore("unsafe_cast")
			var texture_handle := composite_textures[id] as TextureHandle
			_free_texture_to_pool(texture_handle)
			composite_textures.erase(id)
	for id in ids:
		if not composite_textures.has(id):
			composite_textures[id] = _get_texture_from_pool()


## compositorをリサイズする。
func resize(size: Vector2i) -> void:
	_texture_pool.clear()
	_path_compositor.resize(size)
	_fill_compositor.resize(size)
	_group_compositor.resize(size)
	_root_compositor.resize(size)
	texture_size = size
	for id: String in composite_textures:
		@warning_ignore("unsafe_cast")
		var texture_handle := composite_textures[id] as TextureHandle
		_free_texture_to_pool(texture_handle)
		composite_textures[id] = _get_texture_from_pool()
	if root_composite_texture != null:
		_free_mip_texture(root_composite_texture)
	root_composite_texture = _create_mip_texture()


## 子孫をたどってneed_compositeとneed_parent_compositeを見てmark_compositeを有効にする。
func _update_mark_composite_group_layer(group_layer: GroupPaintLayer, force_composite: bool) -> bool:
	for layer in group_layer.child_layers:
		# テクスチャが確保されるまでcompositeをスキップする
		if not composite_textures[layer.id].valid:
			return false
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			if not _update_mark_composite_group_layer(gl, force_composite):
				return false
		if layer.need_parent_composite:
			group_layer.need_composite = true
		if layer.need_composite or force_composite:
			group_layer.need_composite = true
			layer.mark_composite = true
		layer.need_parent_composite = false
		layer.need_composite = false
	return true


## パスレイヤーをcompositeする。
func _composite_path_layer(path_layer: PathPaintLayer) -> void:
	if path_layer.filled:
		if path_layer.outlined:
			var fill_material := Main.materials.get_material(path_layer.fill_material_id)
			var line_material := Main.materials.get_material(path_layer.outline_material_id)
			@warning_ignore("unsafe_cast")
			var texture_handle := composite_textures[path_layer.id] as TextureHandle
			_path_compositor.path_composite_jfa_line(texture_handle, path_layer, fill_material, line_material, path_layer.outline_width)
		else:
			var fill_material := Main.materials.get_material(path_layer.fill_material_id)
			@warning_ignore("unsafe_cast")
			var texture_handle := composite_textures[path_layer.id] as TextureHandle
			_path_compositor.path_composite(texture_handle, path_layer, fill_material)
	elif path_layer.outlined:
		var line_material := Main.materials.get_material(path_layer.outline_material_id)
		@warning_ignore("unsafe_cast")
		var texture_handle := composite_textures[path_layer.id] as TextureHandle
		_path_compositor.path_composite(texture_handle, path_layer, line_material)
	else:
		@warning_ignore("unsafe_cast")
		var texture_handle := composite_textures[path_layer.id] as TextureHandle
		_path_compositor.path_clear(texture_handle)


## 塗りレイヤーをcompositeする。
func _composite_fill_layer(fill_layer: FillPaintLayer) -> void:
	var fill_material := Main.materials.get_material(fill_layer.fill_material_id)
	@warning_ignore("unsafe_cast")
	var texture_handle := composite_textures[fill_layer.id] as TextureHandle
	_fill_compositor.composite(texture_handle, fill_material)


## グループレイヤーをcompositeする。
func _composite_group_layer(group_layer: GroupPaintLayer) -> void:
	# 子要素のcompositeを更新
	for layer in group_layer.child_layers:
		if layer.mark_composite:
			if layer is PathPaintLayer:
				var pl := layer as PathPaintLayer
				_composite_path_layer(pl)
			elif layer is FillPaintLayer:
				var fl := layer as FillPaintLayer
				_composite_fill_layer(fl)
			elif layer is GroupPaintLayer:
				var gl := layer as GroupPaintLayer
				_composite_group_layer(gl)
			layer.mark_composite = false

	# compositeする
	var texture_rids: Array[RID] = []
	var blend_modes: Array[PaintLayer.BlendMode] = []
	var clippings: Array[bool] = []
	var alphas: Array[int] = []
	for layer in group_layer.child_layers:
		if not layer.visible:
			continue
		texture_rids.append(composite_textures[layer.id].texture_rid)
		blend_modes.append(layer.blend_mode)
		clippings.append(layer.clipped)
		alphas.append(layer.alpha)
	@warning_ignore("unsafe_cast")
	var texture_handle := composite_textures[group_layer.id] as TextureHandle
	_group_compositor.composite(texture_handle, texture_rids, blend_modes, clippings, alphas)


## rootからたどって必要な部分をcompositeし直す。
## テクスチャの生成がなされていない場合など、compositeができない場合はfalseを返す。
func composite(root: Array[PaintLayer], force_composite: bool = false) -> bool:
	# テクスチャが確保されるまでcompositeをスキップする
	if not root_composite_texture.valid:
		return false

	# rootの子孫をたどってneed_compositeとneed_parent_compositeを見てmark_compositeを有効にする
	var mark_composite_root := force_composite or need_composite
	for layer in root:
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			if not _update_mark_composite_group_layer(gl, force_composite):
				return false

		# テクスチャが確保されるまでcompositeをスキップする
		if not composite_textures[layer.id].valid:
			return false

		if layer.need_parent_composite:
			mark_composite_root = true
		if layer.need_composite or force_composite:
			mark_composite_root = true
			layer.mark_composite = true
		layer.need_parent_composite = false
		layer.need_composite = false
	if need_composite:
		mark_composite_root = true
	need_composite = false

	if not mark_composite_root:
		return true

	# mark_compositeな部分だけ深さ優先でcompositeしていく
	for layer in root:
		if layer.mark_composite:
			if layer is PathPaintLayer:
				var pl := layer as PathPaintLayer
				_composite_path_layer(pl)
			elif layer is FillPaintLayer:
				var fl := layer as FillPaintLayer
				_composite_fill_layer(fl)
			elif layer is GroupPaintLayer:
				var gl := layer as GroupPaintLayer
				_composite_group_layer(gl)
			layer.mark_composite = false

	# compositeする
	var texture_rids: Array[RID] = []
	var blend_modes: Array[PaintLayer.BlendMode] = []
	var clippings: Array[bool] = []
	var alphas: Array[int] = []
	for layer in root:
		if not layer.visible:
			continue
		texture_rids.append(composite_textures[layer.id].texture_rid)
		blend_modes.append(layer.blend_mode)
		clippings.append(layer.clipped)
		alphas.append(layer.alpha)
	_root_compositor.composite(root_composite_texture, texture_rids, blend_modes, clippings, alphas)

	return true
