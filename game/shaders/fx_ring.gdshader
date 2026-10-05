// 地面冲击环 / 拾取环（平铺在地上的四边形，画一个圆环）。COLOR.a 控制淡出，INSTANCE_CUSTOM.x = 环宽比例。
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

varying vec4 v_c;
varying vec4 v_u;

void vertex() {
	v_c = vec4(mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb)), COLOR.a);
	v_u = INSTANCE_CUSTOM;
}

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float wdt = max(0.04, v_u.x);
	float a = smoothstep(1.0 - wdt, 1.0 - wdt * 0.6, d) * (1.0 - smoothstep(0.96, 1.0, d));
	ALBEDO = v_c.rgb * a * v_c.a * 2.0;
}
