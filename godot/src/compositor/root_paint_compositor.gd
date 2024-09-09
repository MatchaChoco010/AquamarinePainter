## 複数のレイヤーをアルファブレンドしながら合成するcompositor。
## GroupPaintCompositorの機能に加えてmipmapを6段階生成している。
class_name RootPaintCompositor
extends RefCounted


var texture: Texture2DRD

var texture_size: Vector2i

## コンピュートシェーダー。
var _shader: RID
## コンピュートパイプライン。
var _pipeline: RID

## mipamp生成のコンピュートシェーダー。
var _mipmap_shader: RID
## mipamp生成のコンピュートパイプライン。
var _mipmap_pipeline: RID

## サンプラー。
var _sampler: RID


func _init() -> void:
	texture = Texture2DRD.new()
	RenderingServer.call_on_render_thread(_initialize_compute_shader)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var free_compute_resource := func(shader: RID, mipmap_shader: RID, sampler: RID) -> void:
			var rd := RenderingServer.get_rendering_device()
			if shader:
				rd.free_rid(shader)
			if mipmap_shader:
				rd.free_rid(mipmap_shader)
			if sampler:
				rd.free_rid(sampler)
		RenderingServer.call_on_render_thread(free_compute_resource.bind(_shader, _mipmap_shader, _sampler))


func _initialize_compute_shader() -> void:
	var rd := RenderingServer.get_rendering_device()

	var shader_file: RDShaderFile = load("res://shaders/composite/group_composite.glsl")
	var shader_spirv := shader_file.get_spirv()
	_shader = rd.shader_create_from_spirv(shader_spirv)
	_pipeline = rd.compute_pipeline_create(_shader)

	var mipmap_shader_file: RDShaderFile = load("res://shaders/composite/mipmap_generate.glsl")
	var mipmap_shader_spirv := mipmap_shader_file.get_spirv()
	_mipmap_shader = rd.shader_create_from_spirv(mipmap_shader_spirv)
	_mipmap_pipeline = rd.compute_pipeline_create(_mipmap_shader)

	var sampler_state := RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	_sampler = rd.sampler_create(sampler_state)


func resize(size: Vector2i) -> void:
	if texture_size != size:
		texture_size = size


func _render_process(output_texture: PaintCompositor.MipTextureHandle, texture_rids: Array[RID], blend_modes: Array[PaintLayer.BlendMode], clippings: Array[bool], alphas: Array[int]) -> void:
	var rd := RenderingServer.get_rendering_device()

	if not rd.texture_is_valid(output_texture.texture_rid):
		return
	for rid in texture_rids:
		if not rd.texture_is_valid(rid):
			return

	var x_group := (texture_size.x * 1 - 1) / 8 + 1
	var y_group := (texture_size.y * 1 - 1) / 8 + 1

	var texture_uniform := RDUniform.new()
	texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	texture_uniform.binding = 0
	texture_uniform.add_id(output_texture.texture_rid)
	var texture_set := rd.uniform_set_create([texture_uniform], _shader, 0)
	rd.texture_clear(output_texture.texture_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)

	for index in texture_rids.size():
		# 合成のforeground画像をbindする
		var foreground := RDUniform.new()
		foreground.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		foreground.binding = 0
		foreground.add_id(texture_rids[index])
		var foreground_set := rd.uniform_set_create([foreground], _shader, 1)

		# 合成のclippingの親に当たる画像を探してbindする
		var clipping_index := -1
		if clippings[index]:
			for i in index:
				if not clippings[index - i - 1]:
					clipping_index = index - i - 1
					break
		var clipping := RDUniform.new()
		clipping.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		clipping.binding = 0
		if clipping_index == -1:
			clipping.add_id(output_texture.texture_rid)
		else:
			clipping.add_id(texture_rids[clipping_index])
		var clipping_set := rd.uniform_set_create([clipping], _shader, 2)

		# クリッピングのアルファ値も計算する
		var clipping_alpha := 100
		if clipping_index != -1:
			clipping_alpha = alphas[clipping_index]

		# push_counstantsを詰める
		var push_constant := PackedInt32Array()
		push_constant.push_back(blend_modes[index])
		push_constant.push_back(clippings[index])
		push_constant.push_back(texture_size.x * 1)
		push_constant.push_back(texture_size.y * 1)
		push_constant.push_back(alphas[index])
		push_constant.push_back(clipping_alpha)
		push_constant.push_back(1 if Main.mirror else 0)
		push_constant.push_back(0) # dummy

		# コマンドを発行
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
		rd.compute_list_bind_uniform_set(compute_list, texture_set, 0)
		rd.compute_list_bind_uniform_set(compute_list, foreground_set, 1)
		rd.compute_list_bind_uniform_set(compute_list, clipping_set, 2)
		rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
		rd.compute_list_dispatch(compute_list, x_group, y_group, 1)
		rd.compute_list_end()

	# mipmapの生成
	var mipmap_in_texture_sets: Array[RID] = []
	var mipmap_out_texture_sets: Array[RID] = []
	for i in output_texture.mip_size - 1:
		var in_uniform := RDUniform.new()
		in_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		in_uniform.binding = 0
		in_uniform.add_id(_sampler)
		in_uniform.add_id(output_texture.mipmap_texture_rids[i])
		mipmap_in_texture_sets.append(rd.uniform_set_create([in_uniform], _mipmap_shader, 1))
		var out_uniform := RDUniform.new()
		out_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		out_uniform.binding = 0
		out_uniform.add_id(output_texture.mipmap_texture_rids[i + 1])
		mipmap_out_texture_sets.append(rd.uniform_set_create([out_uniform], _mipmap_shader, 0))

	for i in output_texture.mip_size - 1:
		var x_group_mipmap := (texture_size.x * 1 / (2 ** (i + 1)) - 1) / 8 + 1
		var y_group_mipmap := (texture_size.y * 1 / (2 ** (i + 1)) - 1) / 8 + 1

		# push_counstantsを詰める
		var push_constant := PackedInt32Array()
		push_constant.push_back(texture_size.x * 1 / (2 ** (i + 1)))
		push_constant.push_back(texture_size.y * 1 / (2 ** (i + 1)))
		push_constant.push_back(0) # dummy
		push_constant.push_back(0) # dummy

		# コマンドを発行
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, _mipmap_pipeline)
		rd.compute_list_bind_uniform_set(compute_list, mipmap_out_texture_sets[i], 0)
		rd.compute_list_bind_uniform_set(compute_list, mipmap_in_texture_sets[i], 1)
		rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
		rd.compute_list_dispatch(compute_list, x_group_mipmap, y_group_mipmap, 1)
		rd.compute_list_end()


func composite(output_texture: PaintCompositor.MipTextureHandle, texture_rids: Array[RID], blend_modes: Array[PaintLayer.BlendMode], clippings: Array[bool], alphas: Array[int]) -> void:
	RenderingServer.call_on_render_thread(_render_process.bind(output_texture, texture_rids, blend_modes, clippings, alphas))


## コンポジットした結果のミップマップ付きのテクスチャを取得
func get_mipmap_texture() -> Texture2D:
	return texture
