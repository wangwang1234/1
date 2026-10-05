// 三渲二主着色器（ART_BIBLE 第 3 节）。
// 颜色全部来自调色板贴图（上半张固有色、下半张自发光色）。
// kind：0 普通 1 毛色(按皮肤偏移) 2 队伍色(按队伍偏移) 3 金属 4 玻璃 5 发光件 6 眼睛 7 贴面小件 8 进化路线色(按路线偏移)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D palette : source_color, filter_nearest, repeat_disable;
uniform int kind = 0;
uniform float emission_energy = 1.0;
uniform float terminator = 0.3;
uniform float softness = 0.035;
uniform float rim_strength = 0.18;
uniform float rim_power = 3.5;
uniform vec3 rim_color : source_color = vec3(1.0, 0.92, 0.8);
uniform float spec_threshold = 0.92;
uniform float spec_strength = 0.0;
uniform float light_bands = 1.0;   // 1 = 点光/聚光的衰减做成分段光圈

instance uniform int skin_index : instance_index(0) = 0;
instance uniform int team_index : instance_index(1) = 0;
instance uniform int path_index : instance_index(2) = 0;
instance uniform float flash : instance_index(3) = 0.0;
instance uniform float glow : instance_index(4) = 0.0;
instance uniform float rim_boost : instance_index(5) = 0.0;
instance uniform vec4 tint : instance_index(6) = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float dissolve : instance_index(7) = 0.0;
instance uniform vec4 rim_tint : instance_index(8) = vec4(0.0, 0.0, 0.0, 0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	if (kind == 1) { uv.x += float(skin_index) / 16.0; }
	if (kind == 2) { uv.y += float(team_index) / 16.0; }
	if (kind == 8) { uv.x += float(path_index) / 16.0; }
	vec3 col = texture(palette, uv).rgb;
	vec3 emi = texture(palette, uv + vec2(0.0, 0.5)).rgb;
	if (dissolve > 0.0) {
		float n = hash(floor(UV * 2048.0) + floor(FRAGCOORD.xy * 0.25));
		if (n < dissolve) { discard; }
	}
	vec3 base = col * tint.rgb;
	ALBEDO = mix(base, vec3(1.0), clamp(flash, 0.0, 1.0));
	float e = emission_energy;
	if (kind == 5) { e *= 1.8; }
	else if (kind == 4 || kind == 6) { e *= 0.9; }
	else if (kind == 8) { e *= glow * 3.0; }
	else { e *= 0.8; }
	vec3 em = emi * e + col * glow * (kind == 8 ? 0.0 : 0.6);
	// 边缘光：保证黑暗里也能看清轮廓
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float rim = smoothstep(0.45, 0.55, fres);
	vec3 rc = mix(rim_color, rim_tint.rgb, rim_tint.a);
	em += rc * rim * (rim_strength + rim_boost) * (0.35 + 0.65 * base);
	em += vec3(1.0) * flash * 0.6;
	EMISSION = em;
	ROUGHNESS = 0.8;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(terminator - softness, terminator + softness, ndl);
	float att = ATTENUATION;
	if (light_bands > 0.5 && !LIGHT_IS_DIRECTIONAL) {
		// 分段光圈：越近越亮，边缘硬切
		float a = att;
		att = smoothstep(0.02, 0.05, a) * 0.35 + smoothstep(0.18, 0.24, a) * 0.35 + smoothstep(0.5, 0.58, a) * 0.3;
	} else {
		att = smoothstep(0.35, 0.65, att) * 0.85 + 0.15 * att;
	}
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * att;
	if (kind == 3 || kind == 4 || kind == 6) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = dot(NORMAL, h);
		float sp = smoothstep(spec_threshold - 0.01, spec_threshold + 0.01, s);
		SPECULAR_LIGHT += LIGHT_COLOR / PI * sp * att * max(spec_strength, kind == 6 ? 0.9 : 0.45) * lit;
	}
}
