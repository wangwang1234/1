shader_type canvas_item;
uniform vec4 top_color : source_color = vec4(1.0);
uniform vec4 bottom_color : source_color = vec4(1.0);
uniform float gradient_height = 64.0;
varying vec2 glyph_position;
void vertex() {
	glyph_position = VERTEX;
}
void fragment() {
	vec4 sampled = texture(TEXTURE, UV);
	// Label 描边颜色是棕色；只给近白色的字面着色，保留描边。
	float face = step(0.8, min(COLOR.r, min(COLOR.g, COLOR.b)));
	vec3 gradient = mix(top_color.rgb, bottom_color.rgb, clamp(glyph_position.y / gradient_height, 0.0, 1.0));
	COLOR = vec4(mix(COLOR.rgb, gradient, face), COLOR.a) * sampled;
}
