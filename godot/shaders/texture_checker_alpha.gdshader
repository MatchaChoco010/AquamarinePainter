shader_type canvas_item;
render_mode unshaded;

uniform sampler2D main_texture: hint_default_transparent, filter_linear_mipmap, source_color;
uniform vec2 document_size = vec2(480, 720);
uniform float document_scale = 1.0;

void fragment() {
	vec4 main_color = texture(main_texture, UV);

	vec2 checker_count = vec2(1.0) / SCREEN_PIXEL_SIZE / 24.0;
	float checker = mod(dot(vec2(1.0), step(vec2(0.5), fract(SCREEN_UV * checker_count))), 2.0);
	vec3 checker_color = mix(vec3(1.0, 1.0, 1.0), vec3(0.8, 0.8, 0.8), checker);

	// Godot標準のpre-multiply alphaテクスチャではなく、
	// 自前のcompositeしたテクスチャを使うので通常のalpha計算を行っている
	COLOR.rgb = main_color.rgb * main_color.a + checker_color * (1.0 - main_color.a);
	COLOR.a = 1.0;
}
