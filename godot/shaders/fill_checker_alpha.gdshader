shader_type canvas_item;
render_mode unshaded;

uniform vec4 fill_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 document_size = vec2(480, 720);
uniform float document_scale = 1.0;

void fragment() {
	vec2 checker_count = document_size * document_scale / 20.0;
	float checker = mod(dot(vec2(1.0), step(vec2(0.5), fract(UV * checker_count))), 2.0);
	vec3 checker_color = mix(vec3(1.0, 1.0, 1.0), vec3(0.8, 0.8, 0.8), checker);

	COLOR.rgb = fill_color.rgb * fill_color.a + checker_color * (1.0 - fill_color.a);
	COLOR.a = 1.0;
}
