// 手电光锥的假体积光：加法混合、边缘和末端淡出，很淡，只为了在黑暗里看出光束方向。
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.92, 0.72, 1.0);
uniform float strength = 0.10;

void fragment() {
	// UV.y：0 = 尖端（光源），1 = 底部（远端）
	float along = UV.y;
	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	float body = pow(clamp(1.0 - edge, 0.0, 1.0), 2.0);
	float fade = smoothstep(0.0, 0.12, along) * (1.0 - smoothstep(0.55, 1.0, along));
	ALBEDO = color.rgb * strength * body * fade;
}
