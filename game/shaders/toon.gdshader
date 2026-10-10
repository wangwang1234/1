// 三渲二主着色器（ART_BIBLE 第 3 节）。
// 颜色全部来自调色板贴图（上半张固有色、下半张自发光色）。
// kind：0 普通 1 毛色(按皮肤偏移) 2 队伍色(按队伍偏移) 3 金属 4 玻璃 5 发光件 6 眼睛 7 贴面小件 8 进化路线色(按路线偏移)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D palette : source_color, filter_nearest, repeat_disable;
uniform int kind = 0;
uniform float emission_energy = 1.0;
uniform float terminator = 0.3;
uniform float softness = 0.075;
uniform float rim_strength = 0.18;
uniform float rim_power = 3.5;
uniform vec3 rim_color : source_color = vec3(1.0, 0.92, 0.8);
uniform float spec_threshold = 0.92;
uniform float spec_strength = 0.0;
// 明暗仍保留三渲二阶调；光源衰减和阴影必须连续，不能量化成扇形色片。
uniform int surface_mode = 0; // 0 物件，1 木地板，2 瓷砖，3 织物
uniform float material_roughness = 0.8;
uniform vec3 surface_color : source_color = vec3(1.0);
uniform float surface_color_blend = 0.0;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

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
	if (kind == 2) { uv.y += float(team_index) / 32.0; }
	if (kind == 8) { uv.x += float(path_index) / 16.0; }
	vec3 col = texture(palette, uv).rgb;
	col = mix(col, surface_color, surface_color_blend);
	// 低幅、低频的材质变化；不使用随机像素噪声，远处自动过滤。
	if (surface_mode == 1) {
		float wave = sin(world_position.x * 52.0 + sin(world_position.z * 1.8) * 0.6);
		float visible = 1.0 - smoothstep(0.35, 1.0, fwidth(world_position.x * 52.0));
		col *= 1.0 + wave * 0.018 * visible;
	} else if (surface_mode == 3) {
		float weave = sin(world_position.x * 125.0) * sin(world_position.z * 125.0);
		float visible = 1.0 - smoothstep(0.25, 1.0, length(fwidth(world_position.xz * 125.0)));
		col *= 1.0 + weave * 0.025 * visible;
	}
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
	ROUGHNESS = kind == 3 ? 0.38 : (kind == 4 || kind == 6 ? 0.2 : material_roughness);
	SPECULAR = 0.0;
	METALLIC = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(terminator - softness, terminator + softness, ndl);
	// 主要大形仍由阶调定义；少量包裹光让圆脸、倒角有体积，阴影中不加自发光补偿。
	float shape = mix(max(ndl, 0.0), band, 0.72);
	float att = ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * shape * att;
	if (kind == 3 || kind == 4 || kind == 6 || surface_mode == 2) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = max(dot(NORMAL, h), 0.0);
		float exponent = kind == 6 ? 100.0 : (surface_mode == 2 ? 42.0 : 64.0);
		float broad = pow(s, exponent);
		float hard = smoothstep(spec_threshold - 0.02, spec_threshold + 0.02, s);
		float strength = surface_mode == 2 ? 0.1 : max(spec_strength, kind == 6 ? 0.65 : 0.28);
		SPECULAR_LIGHT += LIGHT_COLOR / PI * mix(broad, hard, 0.28) * strength * att * max(ndl, 0.0);
	}
}
