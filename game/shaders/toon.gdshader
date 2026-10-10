// Character: gentle toon diffuse, continuous attenuation and roughness-driven GGX.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "palette_surface.gdshaderinc"
uniform float toon_weight = 0.38;
void light() {
	float nl = max(dot(NORMAL, LIGHT), 0.0);
	float band = smoothstep(terminator - softness, terminator + softness, nl);
	float shape = mix(nl, band, toon_weight);
	float metal = kind == 3 ? 0.78 : 0.0;
	vec3 f0 = mix(vec3(0.08 * material_specular), ALBEDO, metal);
	vec3 h = normalize(LIGHT + VIEW);
	float nv = max(dot(NORMAL, VIEW), 0.001);
	float nh = max(dot(NORMAL, h), 0.0);
	float vh = max(dot(VIEW, h), 0.0);
	float alpha = max(ROUGHNESS * ROUGHNESS, 0.02);
	float a2 = alpha * alpha;
	float denom = nh * nh * (a2 - 1.0) + 1.0;
	float distribution = a2 / max(PI * denom * denom, 0.0001);
	float k = (ROUGHNESS + 1.0) * (ROUGHNESS + 1.0) * 0.125;
	float geometry = (nl / max(nl * (1.0 - k) + k, 0.001)) * (nv / (nv * (1.0 - k) + k));
	vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - vh, 5.0);
	DIFFUSE_LIGHT += (1.0 - fresnel) * (1.0 - metal) * LIGHT_COLOR / PI * shape * ATTENUATION;
	SPECULAR_LIGHT += distribution * geometry * fresnel / max(4.0 * nv, 0.001) * LIGHT_COLOR * ATTENUATION * SPECULAR_AMOUNT;
}
