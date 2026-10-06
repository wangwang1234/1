// 光束 / 发光条带（电磁炮、激光、侦察弹道、电流带、剑气）：横向柔边、纵向均匀，中心偏白。
// COLOR = 颜色（sRGB）+ 透明度；INSTANCE_CUSTOM.r = 中心白芯强度。
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

varying vec4 v_c;
varying float v_core;

void vertex() {
	v_c = vec4(mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb)), COLOR.a);
	v_core = INSTANCE_CUSTOM.r;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float across = 1.0 - smoothstep(0.2, 1.0, abs(p.y));
	float ends = 1.0 - smoothstep(0.92, 1.0, abs(p.x));
	float core = 1.0 - smoothstep(0.0, 0.3, abs(p.y));
	vec3 c = mix(v_c.rgb, vec3(1.0), core * v_core);
	ALBEDO = c * across * ends * v_c.a * 2.0;
}
