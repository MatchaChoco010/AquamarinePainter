shader_type canvas_item;
render_mode unshaded;

uniform sampler2D gradient_texture;
uniform vec2 start_point = vec2(0, 0);
uniform vec2 end_point = vec2(1, 0);

void fragment() {
	vec2 v = end_point - start_point;
	float t = dot(SCREEN_UV - start_point, v) / dot(v, v);
	COLOR = texture(gradient_texture, vec2(t, 0.5));
}
