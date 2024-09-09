shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 checker_count = vec2(1.0) / SCREEN_PIXEL_SIZE / 24.0;
	float checker = mod(dot(vec2(1.0), step(vec2(0.5), fract(SCREEN_UV * checker_count))), 2.0);
	vec3 checker_color = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), checker);

	COLOR.rgb = checker_color;
	COLOR.a = 1.0;
}
