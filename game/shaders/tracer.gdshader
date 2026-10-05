// 曳光 / 子弹：沿速度方向拉长的发光条，头亮尾暗。COLOR = 队伍色。
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

varying vec4 v_c;

void vertex() {
	v_c = vec4(mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb)), COLOR.a);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float across = 1.0 - smoothstep(0.35, 1.0, abs(p.y));
	float along = smoothstep(-1.0, 0.6, p.x) * (1.0 - smoothstep(0.85, 1.0, p.x));
	float core = (1.0 - smoothstep(0.0, 0.35, abs(p.y))) * smoothstep(0.2, 0.9, p.x);
	vec3 c = mix(v_c.rgb, vec3(1.0), core * 0.8);
	ALBEDO = c * across * along * v_c.a * 2.2;
}
