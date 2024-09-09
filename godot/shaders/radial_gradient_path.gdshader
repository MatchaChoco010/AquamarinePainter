shader_type canvas_item;
render_mode unshaded;

uniform sampler2D gradient_texture;
uniform vec2 center_point = vec2(0, 0);
uniform vec2 handle_1_point = vec2(1, 0);
uniform vec2 handle_2_point = vec2(1, 0);

void fragment() {
	vec2 a = handle_1_point - center_point;
	vec2 b = handle_2_point - center_point;
	float aLength = length(a);
	float bLength = length(b);
	vec2 aNorm = a / aLength;
	vec2 bNorm = b / bLength;
	if (aLength < 0.0001 || bLength < 0.0001) {
		COLOR = texture(gradient_texture, vec2(1.0, 0.5));
	} else {
		vec2 uv = SCREEN_UV;
		vec2 p = uv - center_point;
		vec2 pp = dot(p, aNorm) * aNorm + dot(p, bNorm) * bNorm / bLength * aLength;
		float t = length(pp) / aLength;
		COLOR = texture(gradient_texture, vec2(t, 0.5));
	}
}
