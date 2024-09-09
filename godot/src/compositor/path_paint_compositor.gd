## booleanのパスのviewportの結果を解決して塗りを与えるcompositor。
class_name PathPaintCompositor
extends RefCounted


var texture: Texture2DRD

var texture_size: Vector2i

## ラスタライズのグラフィクスシェーダー。
var _rasterize_render_shader: RID
## ラスタライズのグラフィクスパイプライン。
var _rasterize_render_pipeline: RID
## バーテックスバッファのフォーマット。
var _rasterize_vertex_format: int
## ラスタライズ結果を保存するテクスチャ。
var _rasterize_texture_rids: Array[RID]
## ラスタライズ結果を保存するテクスチャのフレームバッファ。
var _rasterize_framebuffers: Array[RID]
## フレームバッファのフォーマット。
var _rasterize_framebuffer_format: int

## 塗り合成コンピュートシェーダー。
var _path_composite_shader: RID
## 塗り合成コンピュートパイプライン。
var _path_composite_pipeline: RID

## サンプラー。
var _sampler: RID

## Jump Flood Algorithm初期化のコンピュートシェーダー。
var _init_jfa_line_shader: RID
## Jump Flood Algorithm初期化のコンピュートパイプライン。
var _init_jfa_line_pipeline: RID

## Jump Flood Algorithmのコンピュートシェーダー。
var _jfa_line_shader: RID
## Jump Flood Algorithmのコンピュートパイプライン。
var _jfa_line_pipeline: RID

## ライン付きの塗り合成コンピュートシェーダー。
var _path_composite_jfa_line_shader: RID
## ライン付きの塗り合成コンピュートパイプライン。
var _path_composite_jfa_line_pipeline: RID

## Jump Flood Algorithmに使うテクスチャとそのUniformのバインドセット。
var _jfa_texture_rids: Array[RID] = []
var _init_jfa_texture_set: RID
var _jfa_texture_sets: Array[RID] = []
var _path_composite_jfa_line_texture_sets: Array[RID]

## 内部で結果を一時的に描画するバッファ。
var _internal_texture_rid: RID

## スケールダウンのコンピュートシェーダー。
var _scale_down_shader: RID
## スケールダウンのコンピュートパイプライン。
var _scale_down_pipeline: RID


func _init() -> void:
	texture = Texture2DRD.new()
	RenderingServer.call_on_render_thread(_initialize_compositor)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var free_compute_resource := func(
			rasterize_render_shader: RID,
			path_composite_shader: RID,
			sampler: RID,
			init_jfa_line_shader: RID,
			jfa_line_shader: RID,
			path_composite_jfa_line_shader: RID,
			jfa_texture_rids: Array[RID]
		) -> void:
			var rd := RenderingServer.get_rendering_device()
			if rasterize_render_shader:
				rd.free_rid(rasterize_render_shader)
			if path_composite_shader:
				rd.free_rid(path_composite_shader)
			if sampler:
				rd.free_rid(sampler)
			if init_jfa_line_shader:
				rd.free_rid(init_jfa_line_shader)
			if jfa_line_shader:
				rd.free_rid(jfa_line_shader)
			if path_composite_jfa_line_shader:
				rd.free_rid(path_composite_jfa_line_shader)
			for rid in jfa_texture_rids:
				rd.free_rid(rid)
		RenderingServer.call_on_render_thread(free_compute_resource.bind(
			_rasterize_render_shader, _path_composite_shader, _sampler,
			_init_jfa_line_shader, _jfa_line_shader, _path_composite_jfa_line_shader, _jfa_texture_rids))


func _initialize_compositor() -> void:
	var rd := RenderingServer.get_rendering_device()

	var attachments: Array[RDAttachmentFormat] = []
	var attachment_format := RDAttachmentFormat.new()
	attachment_format.set_format(RenderingDevice.DATA_FORMAT_R8G8_SNORM)
	attachment_format.set_samples(RenderingDevice.TEXTURE_SAMPLES_1)
	attachment_format.usage_flags = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + \
		RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	attachments.push_back(attachment_format)
	_rasterize_framebuffer_format = rd.framebuffer_format_create(attachments)

	var vertex_attrs := [RDVertexAttribute.new()]
	vertex_attrs[0].format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT
	vertex_attrs[0].location = 0
	vertex_attrs[0].stride = 4 * 2
	_rasterize_vertex_format = rd.vertex_format_create(vertex_attrs)

	var blend := RDPipelineColorBlendState.new()
	var blend_attachment := RDPipelineColorBlendStateAttachment.new()
	blend_attachment.write_r = true
	blend_attachment.write_g = true
	blend_attachment.write_b = true
	blend_attachment.enable_blend = false
	blend.attachments.push_back(blend_attachment)

	var rasterize_render_shader_file: RDShaderFile = load("res://shaders/composite/rasterize.glsl")
	var rasterize_render_shader_spirv := rasterize_render_shader_file.get_spirv()
	_rasterize_render_shader = rd.shader_create_from_spirv(rasterize_render_shader_spirv)
	_rasterize_render_pipeline = rd.render_pipeline_create(
		_rasterize_render_shader,
		_rasterize_framebuffer_format,
		_rasterize_vertex_format,
		RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,
		RDPipelineRasterizationState.new(),
		RDPipelineMultisampleState.new(),
		RDPipelineDepthStencilState.new(),
		blend)

	var path_composite_shader_file: RDShaderFile = load("res://shaders/composite/path_composite.glsl")
	var path_composite_shader_spirv := path_composite_shader_file.get_spirv()
	_path_composite_shader = rd.shader_create_from_spirv(path_composite_shader_spirv)
	_path_composite_pipeline = rd.compute_pipeline_create(_path_composite_shader)

	var sampler_state := RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	_sampler = rd.sampler_create(sampler_state)

	var init_jfa_line_shader_file: RDShaderFile = load("res://shaders/composite/init_jfa_line.glsl")
	var init_jfa_line_shader_spirv := init_jfa_line_shader_file.get_spirv()
	_init_jfa_line_shader = rd.shader_create_from_spirv(init_jfa_line_shader_spirv)
	_init_jfa_line_pipeline = rd.compute_pipeline_create(_init_jfa_line_shader)

	var jfa_line_shader_file: RDShaderFile = load("res://shaders/composite/jfa_line.glsl")
	var jfa_line_shader_spirv := jfa_line_shader_file.get_spirv()
	_jfa_line_shader = rd.shader_create_from_spirv(jfa_line_shader_spirv)
	_jfa_line_pipeline = rd.compute_pipeline_create(_jfa_line_shader)

	var path_composite_jfa_line_shader_file: RDShaderFile = load("res://shaders/composite/path_composite_jfa_line.glsl")
	var path_composite_jfa_line_shader_spirv := path_composite_jfa_line_shader_file.get_spirv()
	_path_composite_jfa_line_shader = rd.shader_create_from_spirv(path_composite_jfa_line_shader_spirv)
	_path_composite_jfa_line_pipeline = rd.compute_pipeline_create(_path_composite_jfa_line_shader)

	var scale_down_shader_file: RDShaderFile = load("res://shaders/composite/mipmap_generate.glsl")
	var scale_down_shader_spirv := scale_down_shader_file.get_spirv()
	_scale_down_shader = rd.shader_create_from_spirv(scale_down_shader_spirv)
	_scale_down_pipeline = rd.compute_pipeline_create(_scale_down_shader)


func _recreate_texture(size: Vector2i) -> void:
	var rd := RenderingServer.get_rendering_device()

	texture_size = size

	var rasterize_tf := RDTextureFormat.new()
	rasterize_tf.format = RenderingDevice.DATA_FORMAT_R8G8_SNORM
	rasterize_tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	rasterize_tf.width = texture_size.x * 2
	rasterize_tf.height = texture_size.y * 2
	rasterize_tf.depth = 1
	rasterize_tf.array_layers = 1
	rasterize_tf.mipmaps = 1
	rasterize_tf.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + \
		RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	_rasterize_texture_rids = [
		rd.texture_create(rasterize_tf, RDTextureView.new()),
		rd.texture_create(rasterize_tf, RDTextureView.new()),
	]
	_rasterize_framebuffers = [
		rd.framebuffer_create([_rasterize_texture_rids[0]], _rasterize_framebuffer_format),
		rd.framebuffer_create([_rasterize_texture_rids[1]], _rasterize_framebuffer_format),
	]

	_jfa_texture_rids.clear()
	_jfa_texture_sets.clear()
	_path_composite_jfa_line_texture_sets.clear()

	var jfa_tf := RDTextureFormat.new()
	jfa_tf.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	jfa_tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	jfa_tf.width = texture_size.x * 2
	jfa_tf.height = texture_size.y * 2
	jfa_tf.depth = 1
	jfa_tf.array_layers = 1
	jfa_tf.mipmaps = 1
	jfa_tf.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT

	for idx in 2:
		var texture_rid := rd.texture_create(jfa_tf, RDTextureView.new(), [])
		_jfa_texture_rids.append(texture_rid)

	var init_jfa_uniform := RDUniform.new()
	init_jfa_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	init_jfa_uniform.binding = 0
	init_jfa_uniform.add_id(_jfa_texture_rids[0])
	_init_jfa_texture_set = rd.uniform_set_create([init_jfa_uniform], _init_jfa_line_shader, 0)

	for idx in 2:
		var jfa_uniform := RDUniform.new()
		jfa_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		jfa_uniform.binding = 0
		jfa_uniform.add_id(_jfa_texture_rids[idx])
		var texture_set := rd.uniform_set_create([jfa_uniform], _jfa_line_shader, 0)
		_jfa_texture_sets.append(texture_set)

	for idx in 2:
		var path_composite_jfa_uniform := RDUniform.new()
		path_composite_jfa_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		path_composite_jfa_uniform.binding = 0
		path_composite_jfa_uniform.add_id(_jfa_texture_rids[idx])
		var texture_set := rd.uniform_set_create([path_composite_jfa_uniform], _path_composite_jfa_line_shader, 0)
		_path_composite_jfa_line_texture_sets.append(texture_set)

	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = texture_size.x * 2
	tf.height = texture_size.y * 2
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 6
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + \
		RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	_internal_texture_rid = rd.texture_create(tf, RDTextureView.new(), [])
	rd.texture_clear(_internal_texture_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)


func resize(size: Vector2i) -> void:
	if texture_size != size:
		RenderingServer.call_on_render_thread(_recreate_texture.bind(size))


func _path_clear_render_process(composite_texture: PaintCompositor.TextureHandle) -> void:
	var rd := RenderingServer.get_rendering_device()
	rd.texture_clear(composite_texture.texture_rid, Color(0, 0, 0, 0), 0, 1, 0, 1, )


func path_clear(composite_texture: PaintCompositor.TextureHandle) -> void:
	RenderingServer.call_on_render_thread(_path_clear_render_process.bind(composite_texture))


func _path_composite_render_process(composite_texture: PaintCompositor.TextureHandle, path_layer: PathPaintLayer, material: PaintMaterial) -> void:
	var rd := RenderingServer.get_rendering_device()

	if not rd.texture_is_valid(composite_texture.texture_rid):
		return

	var x_group := (texture_size.x * 2 - 1) / 8 + 1
	var y_group := (texture_size.y * 2 - 1) / 8 + 1

	# === ラスタライズ ===

	rd.texture_clear(_rasterize_texture_rids[0], Color(0, 0, 0, 0), 0, 1, 0, 1)
	rd.texture_clear(_rasterize_texture_rids[1], Color(0, 0, 0, 0), 0, 1, 0, 1)
	var framebuffer_index := 0

	if path_layer.filled:

		var clear_color_values := PackedColorArray([Color(0, 0, 0, 0)])
		var draw_list := rd.draw_list_begin(
			_rasterize_framebuffers[framebuffer_index],
			RenderingDevice.INITIAL_ACTION_KEEP,
			RenderingDevice.FINAL_ACTION_READ,
			RenderingDevice.INITIAL_ACTION_KEEP,
			RenderingDevice.FINAL_ACTION_READ,
			clear_color_values)
		rd.draw_list_bind_render_pipeline(draw_list, _rasterize_render_pipeline)

		for path in path_layer.paths:
			if not path.visible:
				continue
			if path.indices.size() <= 2:
				continue

			if path.boolean == Path.Boolean.Intersect or path.boolean == Path.Boolean.Xor:
				rd.draw_list_end()
				framebuffer_index = 1 - framebuffer_index
				rd.texture_copy(
					_rasterize_texture_rids[1 - framebuffer_index],
					_rasterize_texture_rids[framebuffer_index],
					Vector3(0, 0, 0),
					Vector3(0, 0, 0),
					Vector3(texture_size.x * 2, texture_size.y * 2, 0),
					0, 0, 0, 0)
				draw_list = rd.draw_list_begin(
					_rasterize_framebuffers[framebuffer_index],
					RenderingDevice.INITIAL_ACTION_KEEP,
					RenderingDevice.FINAL_ACTION_READ,
					RenderingDevice.INITIAL_ACTION_KEEP,
					RenderingDevice.FINAL_ACTION_READ,
					clear_color_values)
				rd.draw_list_bind_render_pipeline(draw_list, _rasterize_render_pipeline)

			# index bufferの作成
			var index_bytes := path.indices.to_byte_array()
			var index_buffer := rd.index_buffer_create(path.indices.size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, index_bytes)
			var index_array := rd.index_array_create(index_buffer, 0, path.indices.size())

			# vertex bufferの作成
			var vertex_bytes := path.vertices.to_byte_array()
			var vertex_buffers := [rd.vertex_buffer_create(vertex_bytes.size(), vertex_bytes)]
			var vertex_array := rd.vertex_array_create(path.vertices.size(), _rasterize_vertex_format, vertex_buffers)

			# framebufferのuniformのバインド
			var framebuffer_texture_uniform := RDUniform.new()
			framebuffer_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
			framebuffer_texture_uniform.binding = 0
			framebuffer_texture_uniform.add_id(_sampler)
			framebuffer_texture_uniform.add_id(_rasterize_texture_rids[1 - framebuffer_index])
			var framebuffer_texture_set := rd.uniform_set_create([framebuffer_texture_uniform], _rasterize_render_shader, 0)

			# push_counstantsを詰める
			var rasterize_push_constant := PackedInt32Array()
			rasterize_push_constant.push_back(int(Main.document_size.x))
			rasterize_push_constant.push_back(int(Main.document_size.y))
			if path.boolean == Path.Boolean.Union:
				rasterize_push_constant.push_back(0)
			elif path.boolean == Path.Boolean.Diff:
				rasterize_push_constant.push_back(1)
			elif path.boolean == Path.Boolean.Intersect:
				rasterize_push_constant.push_back(2)
			elif path.boolean == Path.Boolean.Xor:
				rasterize_push_constant.push_back(3)
			rasterize_push_constant.push_back(0) # dummy
			var rasterize_push_constant_bytes := rasterize_push_constant.to_byte_array()

			rd.draw_list_bind_index_array(draw_list, index_array)
			rd.draw_list_bind_vertex_array(draw_list, vertex_array)
			rd.draw_list_bind_uniform_set(draw_list, framebuffer_texture_set, 0)
			rd.draw_list_set_push_constant(draw_list, rasterize_push_constant_bytes, rasterize_push_constant_bytes.size())
			rd.draw_list_draw(draw_list, true, 1)

			# intersectの2つ目のパス
			if path.boolean == Path.Boolean.Intersect:
				rd.draw_list_end()
				framebuffer_index = 1 - framebuffer_index
				rd.texture_copy(
					_rasterize_texture_rids[1 - framebuffer_index],
					_rasterize_texture_rids[framebuffer_index],
					Vector3(0, 0, 0),
					Vector3(0, 0, 0),
					Vector3(texture_size.x * 2, texture_size.y * 2, 0),
					0, 0, 0, 0)
				draw_list = rd.draw_list_begin(
					_rasterize_framebuffers[framebuffer_index],
					RenderingDevice.INITIAL_ACTION_KEEP,
					RenderingDevice.FINAL_ACTION_READ,
					RenderingDevice.INITIAL_ACTION_KEEP,
					RenderingDevice.FINAL_ACTION_READ,
					clear_color_values)
				rd.draw_list_bind_render_pipeline(draw_list, _rasterize_render_pipeline)

				# vertex bufferの作成
				var rect_vertices := PackedVector2Array([
					Vector2(0, 0),
					Vector2(texture_size.x * 2, 0),
					Vector2(texture_size.x * 2, texture_size.y * 2),
					Vector2(0, 0),
					Vector2(texture_size.x * 2, texture_size.y * 2),
					Vector2(0, texture_size.y * 2),
				])
				var rect_vertex_bytes := rect_vertices.to_byte_array()
				var rect_vertex_buffers := [rd.vertex_buffer_create(rect_vertex_bytes.size(), rect_vertex_bytes)]
				var rect_vertex_array := rd.vertex_array_create(6, _rasterize_vertex_format, rect_vertex_buffers)

				# framebufferのuniformのバインド
				var rect_framebuffer_texture_uniform := RDUniform.new()
				rect_framebuffer_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				rect_framebuffer_texture_uniform.binding = 0
				rect_framebuffer_texture_uniform.add_id(_sampler)
				rect_framebuffer_texture_uniform.add_id(_rasterize_texture_rids[1 - framebuffer_index])
				var rect_framebuffer_texture_set := rd.uniform_set_create([rect_framebuffer_texture_uniform], _rasterize_render_shader, 0)

				# push_counstantsを詰める
				var rect_rasterize_push_constant := PackedInt32Array()
				rect_rasterize_push_constant.push_back(texture_size.x * 2)
				rect_rasterize_push_constant.push_back(texture_size.y * 2)
				rect_rasterize_push_constant.push_back(5)
				rect_rasterize_push_constant.push_back(0) # dummy
				var rect_rasterize_push_constant_bytes := rect_rasterize_push_constant.to_byte_array()

				rd.draw_list_bind_vertex_array(draw_list, rect_vertex_array)
				rd.draw_list_bind_uniform_set(draw_list, rect_framebuffer_texture_set, 0)
				rd.draw_list_set_push_constant(draw_list, rect_rasterize_push_constant_bytes, rect_rasterize_push_constant_bytes.size())
				rd.draw_list_draw(draw_list, true, 1)

		rd.draw_list_end()
	else:
		var clear_color_values := PackedColorArray([Color(0, 0, 0, 0)])
		var draw_list := rd.draw_list_begin(
			_rasterize_framebuffers[framebuffer_index],
			RenderingDevice.INITIAL_ACTION_KEEP,
			RenderingDevice.FINAL_ACTION_READ,
			RenderingDevice.INITIAL_ACTION_KEEP,
			RenderingDevice.FINAL_ACTION_READ,
			clear_color_values)
		rd.draw_list_bind_render_pipeline(draw_list, _rasterize_render_pipeline)

		for path in path_layer.paths:
			if not path.visible:
				continue
			if path.line_indices.size() <= 2:
				continue

			# index bufferの作成
			var index_bytes := path.line_indices.to_byte_array()
			var index_buffer := rd.index_buffer_create(path.line_indices.size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, index_bytes)
			var index_array := rd.index_array_create(index_buffer, 0, path.line_indices.size())

			# vertex bufferの作成
			var vertex_bytes := path.line_vertices.to_byte_array()
			var vertex_buffers := [rd.vertex_buffer_create(vertex_bytes.size(), vertex_bytes)]
			var vertex_array := rd.vertex_array_create(path.line_vertices.size(), _rasterize_vertex_format, vertex_buffers)

			# framebufferのuniformのバインド
			var framebuffer_texture_uniform := RDUniform.new()
			framebuffer_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
			framebuffer_texture_uniform.binding = 0
			framebuffer_texture_uniform.add_id(_sampler)
			framebuffer_texture_uniform.add_id(_rasterize_texture_rids[1 - framebuffer_index])
			var framebuffer_texture_set := rd.uniform_set_create([framebuffer_texture_uniform], _rasterize_render_shader, 0)

			# push_counstantsを詰める
			var rasterize_push_constant := PackedInt32Array()
			rasterize_push_constant.push_back(int(Main.document_size.x))
			rasterize_push_constant.push_back(int(Main.document_size.y))
			rasterize_push_constant.push_back(0)
			rasterize_push_constant.push_back(0) # dummy
			var rasterize_push_constant_bytes := rasterize_push_constant.to_byte_array()

			rd.draw_list_bind_index_array(draw_list, index_array)
			rd.draw_list_bind_vertex_array(draw_list, vertex_array)
			rd.draw_list_bind_uniform_set(draw_list, framebuffer_texture_set, 0)
			rd.draw_list_set_push_constant(draw_list, rasterize_push_constant_bytes, rasterize_push_constant_bytes.size())
			rd.draw_list_draw(draw_list, true, 1)

		rd.draw_list_end()

	# === ラスタライズの結果をもとにcompositeする ===

	# 出力画像のuniform
	var internal_texture_uniform := RDUniform.new()
	internal_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	internal_texture_uniform.binding = 0
	internal_texture_uniform.add_id(_internal_texture_rid)
	var internal_texture_set := rd.uniform_set_create([internal_texture_uniform], _path_composite_shader, 0)

	# rasterize画像のuniform
	var rasterize_uniform := RDUniform.new()
	rasterize_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	rasterize_uniform.binding = 0
	rasterize_uniform.add_id(_sampler)
	rasterize_uniform.add_id(_rasterize_texture_rids[framebuffer_index])
	var rasterize_uniform_set := rd.uniform_set_create([rasterize_uniform], _path_composite_shader, 1)

	# グラデーションのテクスチャのuniform
	var gradient_texture_uniform := RDUniform.new()
	gradient_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	gradient_texture_uniform.binding = 0
	gradient_texture_uniform.add_id(_sampler)
	if material is ColorPaintMaterial:
		gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	elif material is LinearGradientPaintMaterial:
		var linear_gradient_material := material as LinearGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(linear_gradient_material.gradient_texture)
		gradient_texture_uniform.add_id(gradient_rid)
	elif material is RadialGradientPaintMaterial:
		var radial_gradient_material := material as RadialGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(radial_gradient_material.gradient_texture)
		gradient_texture_uniform.add_id(gradient_rid)
	elif material == null:
		gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	var gradient_texture_set := rd.uniform_set_create([gradient_texture_uniform], _path_composite_shader, 2)

	# push_counstantsを詰める
	var push_constant := PackedInt32Array()
	push_constant.push_back(texture_size.x * 2)
	push_constant.push_back(texture_size.y * 2)

	if material is ColorPaintMaterial:
		var color_material := material as ColorPaintMaterial
		push_constant.push_back(0) # material type
		push_constant.push_back(color_material.color.r8)
		push_constant.push_back(color_material.color.g8)
		push_constant.push_back(color_material.color.b8)
		push_constant.push_back(color_material.color.a8)
		push_constant.push_back(0) # dummmy
		var pos_bytes := PackedVector2Array([
			Vector2(0, 0),
			Vector2(0, 0),
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif material is LinearGradientPaintMaterial:
		var linear_gradient_material := material as LinearGradientPaintMaterial
		push_constant.push_back(1) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # dummmy
		var pos_bytes := PackedVector2Array([
			linear_gradient_material.start_point,
			linear_gradient_material.end_point,
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif material is RadialGradientPaintMaterial:
		var radial_gradient_material := material as RadialGradientPaintMaterial
		push_constant.push_back(2) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # dummmy
		var pos_bytes := PackedVector2Array([
			radial_gradient_material.center_point,
			radial_gradient_material.handle_1_point,
			radial_gradient_material.handle_2_point,
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif material == null:
		push_constant.push_back(3) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # dummmy
		var pos_bytes := PackedVector2Array([
			Vector2(0, 0),
			Vector2(0, 0),
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)

	push_constant.push_back(0) # pading
	push_constant.push_back(0) # pading

	# コマンドを発行
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, _path_composite_pipeline)
	rd.compute_list_bind_uniform_set(compute_list, internal_texture_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, rasterize_uniform_set, 1)
	rd.compute_list_bind_uniform_set(compute_list, gradient_texture_set, 2)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_group, y_group, 1)
	rd.compute_list_end()

	# === 縮小して合成結果を書き出す ===

	var x_group_scale_down := (texture_size.x - 1) / 8 + 1
	var y_group_scale_down := (texture_size.y - 1) / 8 + 1

	# 出力画像のuniform
	var texture_uniform := RDUniform.new()
	texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	texture_uniform.binding = 0
	texture_uniform.add_id(composite_texture.texture_rid)
	var texture_set := rd.uniform_set_create([texture_uniform], _scale_down_shader, 0)

	# 入力画像のuniform
	var scale_down_baseLtexture_uniform := RDUniform.new()
	scale_down_baseLtexture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	scale_down_baseLtexture_uniform.binding = 0
	scale_down_baseLtexture_uniform.add_id(_sampler)
	scale_down_baseLtexture_uniform.add_id(_internal_texture_rid)
	var scale_down_baseLtexture_set := rd.uniform_set_create([scale_down_baseLtexture_uniform], _scale_down_shader, 1)

	# push_counstantsを詰める
	var scale_down_push_constant := PackedInt32Array()
	scale_down_push_constant.push_back(texture_size.x * 1)
	scale_down_push_constant.push_back(texture_size.y * 1)
	scale_down_push_constant.push_back(0) # padding
	scale_down_push_constant.push_back(0) # padding

	# コマンドを発行
	var scale_down_compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(scale_down_compute_list, _scale_down_pipeline)
	rd.compute_list_bind_uniform_set(scale_down_compute_list, texture_set, 0)
	rd.compute_list_bind_uniform_set(scale_down_compute_list, scale_down_baseLtexture_set, 1)
	rd.compute_list_set_push_constant(scale_down_compute_list, scale_down_push_constant.to_byte_array(), scale_down_push_constant.size() * 4)
	rd.compute_list_dispatch(scale_down_compute_list, x_group_scale_down, y_group_scale_down, 1)
	rd.compute_list_end()


func path_composite(composite_texture: PaintCompositor.TextureHandle, path_layer: PathPaintLayer, material: PaintMaterial) -> void:
	RenderingServer.call_on_render_thread(_path_composite_render_process.bind(composite_texture, path_layer, material))


func _path_composite_jfa_line_render_process(composite_texture: PaintCompositor.TextureHandle, path_layer: PathPaintLayer, fill_material: PaintMaterial, line_material: PaintMaterial, line_width: float) -> void:
	var rd := RenderingServer.get_rendering_device()

	if not rd.texture_is_valid(composite_texture.texture_rid):
		return

	var x_group := (texture_size.x * 2 - 1) / 8 + 1
	var y_group := (texture_size.y * 2 - 1) / 8 + 1

	# === ラスタライズ ===

	rd.texture_clear(_rasterize_texture_rids[0], Color(0, 0, 0, 0), 0, 1, 0, 1)
	rd.texture_clear(_rasterize_texture_rids[1], Color(0, 0, 0, 0), 0, 1, 0, 1)
	var framebuffer_index := 0

	var clear_color_values := PackedColorArray([Color(0, 0, 0, 0)])
	var draw_list := rd.draw_list_begin(
		_rasterize_framebuffers[framebuffer_index],
		RenderingDevice.INITIAL_ACTION_KEEP,
		RenderingDevice.FINAL_ACTION_READ,
		RenderingDevice.INITIAL_ACTION_KEEP,
		RenderingDevice.FINAL_ACTION_READ,
		clear_color_values)
	rd.draw_list_bind_render_pipeline(draw_list, _rasterize_render_pipeline)

	for path in path_layer.paths:
		if not path.visible:
			continue
		if path.indices.size() <= 2:
			continue

		# backbufferとの交換
		if path.boolean == Path.Boolean.Intersect or path.boolean == Path.Boolean.Xor:
			rd.draw_list_end()
			framebuffer_index = 1 - framebuffer_index
			rd.texture_copy(
				_rasterize_texture_rids[1 - framebuffer_index],
				_rasterize_texture_rids[framebuffer_index],
				Vector3(0, 0, 0),
				Vector3(0, 0, 0),
				Vector3(texture_size.x * 2, texture_size.y * 2, 0),
				0, 0, 0, 0)
			draw_list = rd.draw_list_begin(
				_rasterize_framebuffers[framebuffer_index],
				RenderingDevice.INITIAL_ACTION_KEEP,
				RenderingDevice.FINAL_ACTION_READ,
				RenderingDevice.INITIAL_ACTION_KEEP,
				RenderingDevice.FINAL_ACTION_READ,
				clear_color_values)
			rd.draw_list_bind_render_pipeline(draw_list, _rasterize_render_pipeline)

		# index bufferの作成
		var index_bytes := path.indices.to_byte_array()
		var index_buffer := rd.index_buffer_create(path.indices.size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, index_bytes)
		var index_array := rd.index_array_create(index_buffer, 0, path.indices.size())

		# vertex bufferの作成
		var vertex_bytes := path.vertices.to_byte_array()
		var vertex_buffers := [rd.vertex_buffer_create(vertex_bytes.size(), vertex_bytes)]
		var vertex_array := rd.vertex_array_create(path.vertices.size(), _rasterize_vertex_format, vertex_buffers)

		# framebufferのuniformのバインド
		var framebuffer_texture_uniform := RDUniform.new()
		framebuffer_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		framebuffer_texture_uniform.binding = 0
		framebuffer_texture_uniform.add_id(_sampler)
		framebuffer_texture_uniform.add_id(_rasterize_texture_rids[1 - framebuffer_index])
		var framebuffer_texture_set := rd.uniform_set_create([framebuffer_texture_uniform], _rasterize_render_shader, 0)

		# push_counstantsを詰める
		var rasterize_push_constant := PackedInt32Array()
		rasterize_push_constant.push_back(int(Main.document_size.x))
		rasterize_push_constant.push_back(int(Main.document_size.y))
		if path.boolean == Path.Boolean.Union:
			rasterize_push_constant.push_back(0)
		elif path.boolean == Path.Boolean.Diff:
			rasterize_push_constant.push_back(1)
		elif path.boolean == Path.Boolean.Intersect:
			rasterize_push_constant.push_back(2)
		elif path.boolean == Path.Boolean.Xor:
			rasterize_push_constant.push_back(3)
		rasterize_push_constant.push_back(0) # dummy
		var rasterize_push_constant_bytes := rasterize_push_constant.to_byte_array()

		rd.draw_list_bind_index_array(draw_list, index_array)
		rd.draw_list_bind_vertex_array(draw_list, vertex_array)
		rd.draw_list_bind_uniform_set(draw_list, framebuffer_texture_set, 0)
		rd.draw_list_set_push_constant(draw_list, rasterize_push_constant_bytes, rasterize_push_constant_bytes.size())
		rd.draw_list_draw(draw_list, true, 1)

		# intersectの2つ目のパス
		if path.boolean == Path.Boolean.Intersect:
			rd.draw_list_end()
			framebuffer_index = 1 - framebuffer_index
			rd.texture_copy(
				_rasterize_texture_rids[1 - framebuffer_index],
				_rasterize_texture_rids[framebuffer_index],
				Vector3(0, 0, 0),
				Vector3(0, 0, 0),
				Vector3(texture_size.x * 2, texture_size.y * 2, 0),
				0, 0, 0, 0)
			draw_list = rd.draw_list_begin(
				_rasterize_framebuffers[framebuffer_index],
				RenderingDevice.INITIAL_ACTION_KEEP,
				RenderingDevice.FINAL_ACTION_READ,
				RenderingDevice.INITIAL_ACTION_KEEP,
				RenderingDevice.FINAL_ACTION_READ,
				clear_color_values)
			rd.draw_list_bind_render_pipeline(draw_list, _rasterize_render_pipeline)

			# vertex bufferの作成
			var rect_vertices := PackedVector2Array([
				Vector2(0, 0),
				Vector2(texture_size.x * 2, 0),
				Vector2(texture_size.x * 2, texture_size.y * 2),
				Vector2(0, 0),
				Vector2(texture_size.x * 2, texture_size.y * 2),
				Vector2(0, texture_size.y * 2),
			])
			var rect_vertex_bytes := rect_vertices.to_byte_array()
			var rect_vertex_buffers := [rd.vertex_buffer_create(rect_vertex_bytes.size(), rect_vertex_bytes)]
			var rect_vertex_array := rd.vertex_array_create(6, _rasterize_vertex_format, rect_vertex_buffers)

			# framebufferのuniformのバインド
			var rect_framebuffer_texture_uniform := RDUniform.new()
			rect_framebuffer_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
			rect_framebuffer_texture_uniform.binding = 0
			rect_framebuffer_texture_uniform.add_id(_sampler)
			rect_framebuffer_texture_uniform.add_id(_rasterize_texture_rids[1 - framebuffer_index])
			var rect_framebuffer_texture_set := rd.uniform_set_create([rect_framebuffer_texture_uniform], _rasterize_render_shader, 0)

			# push_counstantsを詰める
			var rect_rasterize_push_constant := PackedInt32Array()
			rect_rasterize_push_constant.push_back(texture_size.x * 2)
			rect_rasterize_push_constant.push_back(texture_size.y * 2)
			rect_rasterize_push_constant.push_back(5)
			rect_rasterize_push_constant.push_back(0) # dummy
			var rect_rasterize_push_constant_bytes := rect_rasterize_push_constant.to_byte_array()

			rd.draw_list_bind_vertex_array(draw_list, rect_vertex_array)
			rd.draw_list_bind_uniform_set(draw_list, rect_framebuffer_texture_set, 0)
			rd.draw_list_set_push_constant(draw_list, rect_rasterize_push_constant_bytes, rect_rasterize_push_constant_bytes.size())
			rd.draw_list_draw(draw_list, false, 1)

	rd.draw_list_end()

	# === Jump FLood Algorithmの初期 ===

	# rasterize画像のuniform
	var rasterize := RDUniform.new()
	rasterize.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	rasterize.binding = 0
	rasterize.add_id(_rasterize_texture_rids[framebuffer_index])
	var rasterize_set := rd.uniform_set_create([rasterize], _init_jfa_line_shader, 1)

	# push_counstantsを詰める
	var init_push_constant := PackedInt32Array()
	init_push_constant.push_back(texture_size.x * 2)
	init_push_constant.push_back(texture_size.y * 2)
	init_push_constant.push_back(0) # padding
	init_push_constant.push_back(0) # padding

	# コマンドを発行
	var init_compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(init_compute_list, _init_jfa_line_pipeline)
	rd.compute_list_bind_uniform_set(init_compute_list, _init_jfa_texture_set, 0)
	rd.compute_list_bind_uniform_set(init_compute_list, rasterize_set, 1)
	rd.compute_list_set_push_constant(init_compute_list, init_push_constant.to_byte_array(), init_push_constant.size() * 4)
	rd.compute_list_dispatch(init_compute_list, x_group, y_group, 1)
	rd.compute_list_end()

	# === Jump FLood Algorithm本体 ===

	var space := 1
	while line_width >= space:
		space *= 2

	var tex_index := 0
	while space > 1:
		# push_counstantsを詰める
		var jfa_push_constant := PackedInt32Array()
		jfa_push_constant.push_back(texture_size.x * 2)
		jfa_push_constant.push_back(texture_size.y * 2)
		jfa_push_constant.push_back(space / 2)
		jfa_push_constant.push_back(0) # padding

		# コマンドを発行
		var jfa_compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(jfa_compute_list, _jfa_line_pipeline)
		rd.compute_list_bind_uniform_set(jfa_compute_list, _jfa_texture_sets[1 - tex_index], 0)
		rd.compute_list_bind_uniform_set(jfa_compute_list, _jfa_texture_sets[tex_index], 1)
		rd.compute_list_set_push_constant(jfa_compute_list, jfa_push_constant.to_byte_array(), jfa_push_constant.size() * 4)
		rd.compute_list_dispatch(jfa_compute_list, x_group, y_group, 1)
		rd.compute_list_end()

		tex_index = 1 - tex_index
		space /= 2

	# === Jump FLood Algorithmの結果をもとにcompositeする ===

	# 出力画像のuniform
	var internal_texture_uniform := RDUniform.new()
	internal_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	internal_texture_uniform.binding = 0
	internal_texture_uniform.add_id(_internal_texture_rid)
	var internal_texture_set := rd.uniform_set_create([internal_texture_uniform], _path_composite_shader, 0)

	# 塗りのグラデーションのテクスチャのuniform
	var fill_gradient_texture_uniform := RDUniform.new()
	fill_gradient_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	fill_gradient_texture_uniform.binding = 0
	fill_gradient_texture_uniform.add_id(_sampler)
	if fill_material is ColorPaintMaterial:
		fill_gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	elif fill_material is LinearGradientPaintMaterial:
		var linear_gradient_material := fill_material as LinearGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(linear_gradient_material.gradient_texture)
		fill_gradient_texture_uniform.add_id(gradient_rid)
	elif fill_material is RadialGradientPaintMaterial:
		var radial_gradient_material := fill_material as RadialGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(radial_gradient_material.gradient_texture)
		fill_gradient_texture_uniform.add_id(gradient_rid)
	elif fill_material == null:
		fill_gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	var fill_gradient_texture_set := rd.uniform_set_create([fill_gradient_texture_uniform], _path_composite_jfa_line_shader, 2)

	# 線のグラデーションのテクスチャのuniform
	var line_gradient_texture_uniform := RDUniform.new()
	line_gradient_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	line_gradient_texture_uniform.binding = 0
	line_gradient_texture_uniform.add_id(_sampler)
	if line_material is ColorPaintMaterial:
		line_gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	elif line_material is LinearGradientPaintMaterial:
		var linear_gradient_material := line_material as LinearGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(linear_gradient_material.gradient_texture)
		line_gradient_texture_uniform.add_id(gradient_rid)
	elif line_material is RadialGradientPaintMaterial:
		var radial_gradient_material := line_material as RadialGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(radial_gradient_material.gradient_texture)
		line_gradient_texture_uniform.add_id(gradient_rid)
	elif line_material == null:
		line_gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	var line_gradient_texture_set := rd.uniform_set_create([line_gradient_texture_uniform], _path_composite_jfa_line_shader, 3)

	# push_counstantsを詰める
	var push_constant := PackedInt32Array()
	push_constant.push_back(texture_size.x * 2)
	push_constant.push_back(texture_size.y * 2)

	if fill_material is ColorPaintMaterial:
		var color_material := fill_material as ColorPaintMaterial
		push_constant.push_back(0) # material type
		push_constant.push_back(color_material.color.r8)
		push_constant.push_back(color_material.color.g8)
		push_constant.push_back(color_material.color.b8)
		push_constant.push_back(color_material.color.a8)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			Vector2(0, 0),
			Vector2(0, 0),
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif fill_material is LinearGradientPaintMaterial:
		var linear_gradient_material := fill_material as LinearGradientPaintMaterial
		push_constant.push_back(1) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			linear_gradient_material.start_point,
			linear_gradient_material.end_point,
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif fill_material is RadialGradientPaintMaterial:
		var radial_gradient_material := fill_material as RadialGradientPaintMaterial
		push_constant.push_back(2) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			radial_gradient_material.center_point,
			radial_gradient_material.handle_1_point,
			radial_gradient_material.handle_2_point,
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif fill_material == null:
		push_constant.push_back(3) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			Vector2(0, 0),
			Vector2(0, 0),
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)

	if line_material is ColorPaintMaterial:
		var color_material := line_material as ColorPaintMaterial
		push_constant.push_back(0) # material type
		push_constant.push_back(color_material.color.r8)
		push_constant.push_back(color_material.color.g8)
		push_constant.push_back(color_material.color.b8)
		push_constant.push_back(color_material.color.a8)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			Vector2(0, 0),
			Vector2(0, 0),
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif line_material is LinearGradientPaintMaterial:
		var linear_gradient_material := line_material as LinearGradientPaintMaterial
		push_constant.push_back(1) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			linear_gradient_material.start_point,
			linear_gradient_material.end_point,
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif line_material is RadialGradientPaintMaterial:
		var radial_gradient_material := line_material as RadialGradientPaintMaterial
		push_constant.push_back(2) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			radial_gradient_material.center_point,
			radial_gradient_material.handle_1_point,
			radial_gradient_material.handle_2_point,
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)
	elif line_material == null:
		push_constant.push_back(3) # material type
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0) # padding
		var pos_bytes := PackedVector2Array([
			Vector2(0, 0),
			Vector2(0, 0),
			Vector2(0, 0),
		]).to_byte_array().to_int32_array()
		push_constant.append_array(pos_bytes)

	var line_width_float := PackedFloat32Array([line_width * texture_size.x / Main.document_size.x])
	push_constant.append_array(line_width_float.to_byte_array().to_int32_array())

	push_constant.push_back(0) # padding

	# コマンドを発行
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, _path_composite_jfa_line_pipeline)
	rd.compute_list_bind_uniform_set(compute_list, internal_texture_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, _path_composite_jfa_line_texture_sets[tex_index], 1)
	rd.compute_list_bind_uniform_set(compute_list, fill_gradient_texture_set, 2)
	rd.compute_list_bind_uniform_set(compute_list, line_gradient_texture_set, 3)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_group, y_group, 1)
	rd.compute_list_end()

	# === 縮小して合成結果を書き出す ===

	var x_group_scale_down := (texture_size.x - 1) / 8 + 1
	var y_group_scale_down := (texture_size.y - 1) / 8 + 1

	# 出力画像のuniform
	var texture_uniform := RDUniform.new()
	texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	texture_uniform.binding = 0
	texture_uniform.add_id(composite_texture.texture_rid)
	var texture_set := rd.uniform_set_create([texture_uniform], _scale_down_shader, 0)

	# 入力画像のuniform
	var scale_down_baseLtexture_uniform := RDUniform.new()
	scale_down_baseLtexture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	scale_down_baseLtexture_uniform.binding = 0
	scale_down_baseLtexture_uniform.add_id(_sampler)
	scale_down_baseLtexture_uniform.add_id(_internal_texture_rid)
	var scale_down_baseLtexture_set := rd.uniform_set_create([scale_down_baseLtexture_uniform], _scale_down_shader, 1)

	# push_counstantsを詰める
	var scale_down_push_constant := PackedInt32Array()
	scale_down_push_constant.push_back(texture_size.x * 1)
	scale_down_push_constant.push_back(texture_size.y * 1)
	scale_down_push_constant.push_back(0) # padding
	scale_down_push_constant.push_back(0) # padding

	# コマンドを発行
	var scale_down_compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(scale_down_compute_list, _scale_down_pipeline)
	rd.compute_list_bind_uniform_set(scale_down_compute_list, texture_set, 0)
	rd.compute_list_bind_uniform_set(scale_down_compute_list, scale_down_baseLtexture_set, 1)
	rd.compute_list_set_push_constant(scale_down_compute_list, scale_down_push_constant.to_byte_array(), scale_down_push_constant.size() * 4)
	rd.compute_list_dispatch(scale_down_compute_list, x_group_scale_down, y_group_scale_down, 1)
	rd.compute_list_end()


func path_composite_jfa_line(composite_texture: PaintCompositor.TextureHandle, path_layer: PathPaintLayer, fill_material: PaintMaterial, line_material: PaintMaterial, line_width: float) -> void:
	RenderingServer.call_on_render_thread(_path_composite_jfa_line_render_process.bind(composite_texture, path_layer, fill_material, line_material, line_width))
