## 塗りつぶしレイヤーを描画成するcompositor。
class_name FillPaintCompositor
extends RefCounted


var texture_size: Vector2i

## コンピュートシェーダー。
var _shader: RID
## コンピュートパイプライン。
var _pipeline: RID

## サンプラー。
var _sampler: RID


func _init() -> void:
	RenderingServer.call_on_render_thread(_initialize_compute_shader)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var free_compute_resource := func(shader: RID, sampler: RID) -> void:
			var rd := RenderingServer.get_rendering_device()
			if shader:
				rd.free_rid(shader)
			if sampler:
				rd.free_rid(sampler)
		RenderingServer.call_on_render_thread(free_compute_resource.bind(_shader, _sampler))


func _initialize_compute_shader() -> void:
	var rd := RenderingServer.get_rendering_device()

	var shader_file: RDShaderFile = load("res://shaders/composite/fill_composite.glsl")
	var shader_spirv := shader_file.get_spirv()
	_shader = rd.shader_create_from_spirv(shader_spirv)
	_pipeline = rd.compute_pipeline_create(_shader)

	var sampler_state := RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	_sampler = rd.sampler_create(sampler_state)


func resize(size: Vector2i) -> void:
	if texture_size != size:
		texture_size = size


func _render_process(output_texture: PaintCompositor.TextureHandle, fill_material: PaintMaterial) -> void:
	var rd := RenderingServer.get_rendering_device()

	if not rd.texture_is_valid(output_texture.texture_rid):
		return

	var x_group := (texture_size.x * 1 - 1) / 8 + 1
	var y_group := (texture_size.y * 1 - 1) / 8 + 1

	var texture_uniform := RDUniform.new()
	texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	texture_uniform.binding = 0
	texture_uniform.add_id(output_texture.texture_rid)
	var texture_set := rd.uniform_set_create([texture_uniform], _shader, 0)
	rd.texture_clear(output_texture.texture_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)

	var gradient_texture_uniform := RDUniform.new()
	gradient_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	gradient_texture_uniform.binding = 0
	gradient_texture_uniform.add_id(_sampler)
	if fill_material is ColorPaintMaterial:
		gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	elif fill_material is LinearGradientPaintMaterial:
		var linear_gradient_material := fill_material as LinearGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(linear_gradient_material.gradient_texture)
		gradient_texture_uniform.add_id(gradient_rid)
	elif fill_material is RadialGradientPaintMaterial:
		var radial_gradient_material := fill_material as RadialGradientPaintMaterial
		var gradient_rid := RenderingServer.texture_get_rd_texture(radial_gradient_material.gradient_texture)
		gradient_texture_uniform.add_id(gradient_rid)
	elif fill_material == null:
		gradient_texture_uniform.add_id(RenderingServer.texture_get_rd_texture(RenderingServer.get_white_texture()))
	var gradient_texture_set := rd.uniform_set_create([gradient_texture_uniform], _shader, 1)

	# push_counstantsを詰める
	var push_constant := PackedInt32Array()
	push_constant.push_back(texture_size.x * 1)
	push_constant.push_back(texture_size.y * 1)

	if fill_material is ColorPaintMaterial:
		var color_material := fill_material as ColorPaintMaterial
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
	elif fill_material is LinearGradientPaintMaterial:
		var linear_gradient_material := fill_material as LinearGradientPaintMaterial
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
	elif fill_material is RadialGradientPaintMaterial:
		var radial_gradient_material := fill_material as RadialGradientPaintMaterial
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
	elif fill_material == null:
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
	push_constant.push_back(0) # dummmy
	push_constant.push_back(0) # dummmy

	# コマンドを発行
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	rd.compute_list_bind_uniform_set(compute_list, texture_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, gradient_texture_set, 1)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_group, y_group, 1)
	rd.compute_list_end()


func composite(output_texture: PaintCompositor.TextureHandle, fill_material: PaintMaterial) -> void:
	RenderingServer.call_on_render_thread(_render_process.bind(output_texture, fill_material))
