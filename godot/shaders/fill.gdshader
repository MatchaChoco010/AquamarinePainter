shader_type canvas_item;
render_mode unshaded;

uniform vec4 fill_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	COLOR.rgb = fill_color.rgb;
	COLOR.a *= fill_color.a;
}
