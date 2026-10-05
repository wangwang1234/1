// 特效粒子公共代码（见 fx_particle_add / fx_particle_mix）。
// INSTANCE_CUSTOM.x = 形状：0 圆（硬边） 1 四角星 2 拉长条 3 卡通烟团（带亮暗两阶） 4 绒毛 5 方块碎屑
// INSTANCE_CUSTOM.y = 生命进度 0..1；COLOR = 颜色 + 透明度
uniform float intensity = 1.0;

varying vec4 v_custom;
varying vec4 v_color;

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	// 颜色在代码里按 sRGB 写（和美术取色一致），这里转线性，否则暗色烟雾会发灰发白
	v_color = vec4(mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb)), COLOR.a);
}

float star(vec2 p) {
	p = abs(p);
	return 1.0 - smoothstep(0.0, 0.08, p.x * p.y * 9.0 + max(p.x, p.y) * 0.55 - 0.22 + 0.0);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	int shape = int(v_custom.x + 0.5);
	float k = v_custom.y;
	float a = 0.0;
	vec3 c = v_color.rgb;
	if (shape == 0) {
		a = 1.0 - smoothstep(0.82, 0.92, length(p));
	} else if (shape == 1) {
		float d = length(p);
		float rays = max(1.0 - abs(p.x) * 5.0 - abs(p.y) * 0.9, 1.0 - abs(p.y) * 5.0 - abs(p.x) * 0.9);
		a = clamp(max(rays, 1.0 - smoothstep(0.25, 0.35, d)), 0.0, 1.0);
		c = mix(c, vec3(1.0), 1.0 - smoothstep(0.0, 0.35, d));
	} else if (shape == 2) {
		a = (1.0 - smoothstep(0.75, 0.95, abs(p.y))) * (1.0 - smoothstep(0.6, 1.0, abs(p.x)));
	} else if (shape == 3) {
		float d = length(p);
		a = 1.0 - smoothstep(0.86, 0.94, d);
		float lit = step(0.0, -p.x * 0.55 + p.y * 0.85 - 0.15);
		c = mix(c * 0.72, c * 1.15, lit);
		a *= 1.0 - smoothstep(0.55, 1.0, k);
	} else if (shape == 4) {
		float d = length(p * vec2(1.0, 1.6));
		a = 1.0 - smoothstep(0.7, 0.9, d);
	} else {
		a = step(abs(p.x), 0.7) * step(abs(p.y), 0.7);
	}
	a *= v_color.a;
	if (a < 0.02) { discard; }
#ifdef FX_ADDITIVE
	ALBEDO = c * a * intensity;
#else
	ALBEDO = c;
	ALPHA = a;
#endif
}
