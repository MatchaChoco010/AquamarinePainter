shader_type canvas_item;
render_mode unshaded;

uniform sampler2D gradient_texture;
uniform vec2 document_size = vec2(480, 720);
uniform float document_scale = 1.0;

void fragment() {
	vec2 uv = vec2(length(UV - vec2(0.5)) * 2.0, 0.5);
	vec4 gradient_color = texture(gradient_texture, uv);

	vec2 checker_count = document_size * document_scale / 20.0;
	float checker = mod(dot(vec2(1.0), step(vec2(0.5), fract(UV * checker_count))), 2.0);
	vec3 checker_color = mix(vec3(1.0, 1.0, 1.0), vec3(0.8, 0.8, 0.8), checker);

	COLOR.rgb = gradient_color.rgb * gradient_color.a + checker_color * (1.0 - gradient_color.a);
	COLOR.a = 1.0;
}
