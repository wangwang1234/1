// 彩灯串的小灯泡：颜色来自 MultiMesh 实例色，亮度轻轻闪烁（INSTANCE_CUSTOM.x 是每个灯泡的相位）。
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform float emission_energy = 3.0;
uniform float twinkle = 0.35;
varying vec4 bulb_color;
varying float phase;

void vertex() {
	bulb_color = COLOR;
	phase = INSTANCE_CUSTOM.x;
}

void fragment() {
	float t = 1.0 - twinkle + twinkle * (0.5 + 0.5 * sin(TIME * 1.7 + phase * 6.2831));
	ALBEDO = bulb_color.rgb * 0.35;
	ROUGHNESS = 0.25;
	EMISSION = bulb_color.rgb * emission_energy * t;
}
