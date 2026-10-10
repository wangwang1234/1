shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 base_color : source_color;
uniform float roughness = 0.8;
uniform float grain = 0.0;
uniform float emission = 0.0;
uniform float neutral_amount = 0.0;

void fragment() {
	float grain_phase = UV.y * 45.0 + sin(UV.x * 2.0) * 0.8;
	float filter_weight = 1.0 - smoothstep(0.3, 1.0, fwidth(grain_phase));
	float detail = sin(grain_phase) * grain * filter_weight;
	ALBEDO = mix(base_color * (1.0 + detail), vec3(0.32), neutral_amount);
	ROUGHNESS = clamp(roughness + detail * 0.1, 0.18, 1.0);
	SPECULAR = 0.35;
	EMISSION = base_color * emission;
}
