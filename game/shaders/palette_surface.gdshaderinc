// Shared palette, skin masks, material response and feedback.
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
// Shared surface data; the environment and character shaders choose their own lighting.
uniform int surface_mode = 0; // 0 物件，1 木头，2 瓷砖，3 织物，4 毛线，5 毛皮
uniform bool skin_blend = false;
uniform float detail_strength = 0.0;
uniform float material_roughness = 0.8;
uniform float material_specular = 0.5;
uniform float metal_roughness = 0.32;
uniform float bump_strength = 0.0;
uniform float neutral_amount = 0.0;
uniform vec3 surface_color : source_color = vec3(1.0);
uniform float surface_color_blend = 0.0;
uniform float surface_saturation = 1.0;
uniform float vertex_tint_strength = 0.0;
varying vec3 world_position;
varying vec3 local_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_position = VERTEX;
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
	if (kind == 1 && skin_blend) {
		vec3 cream = texture(palette, uv + vec2(0.0, 1.0 / 32.0)).rgb;
		vec3 stripe = texture(palette, uv + vec2(0.0, 2.0 / 32.0)).rgb;
		col = mix(col, stripe, clamp(UV2.y, 0.0, 1.0));
		col = mix(col, cream, clamp(UV2.x, 0.0, 1.0));
	}
	col = mix(col, surface_color, surface_color_blend);
	col *= mix(vec3(1.0), COLOR.rgb, vertex_tint_strength);
	col = mix(vec3(dot(col, vec3(0.2126, 0.7152, 0.0722))), col, surface_saturation);
	// 低幅、低频的材质变化；不使用随机像素噪声，远处自动过滤。
	if (surface_mode == 1) {
		float wave = sin(world_position.x * 52.0 + sin(world_position.z * 1.8) * 0.6);
		float visible = 1.0 - smoothstep(0.35, 1.0, fwidth(world_position.x * 52.0));
		col *= 1.0 + wave * 0.018 * visible;
	} else if (surface_mode == 3) {
		float weave = sin(world_position.x * 125.0) * sin(world_position.z * 125.0);
		float visible = 1.0 - smoothstep(0.25, 1.0, length(fwidth(world_position.xz * 125.0)));
		col *= 1.0 + weave * 0.025 * visible;
	} else if (surface_mode == 4) {
		float a = atan(local_position.z, local_position.x);
		float ribs = cos(a * 36.0);
		float rows = cos(local_position.y * 800.0 + sin(a * 36.0) * 1.5);
		float visible = 1.0 - smoothstep(0.35, 1.1, max(fwidth(a * 36.0), fwidth(local_position.y * 800.0)));
		col *= 1.0 + (ribs * 0.7 + rows * 0.3) * detail_strength * visible;
	} else if (surface_mode == 5) {
		float fur = sin(local_position.x * 310.0 + sin(local_position.y * 150.0) * 1.6) * sin(local_position.z * 160.0);
		float visible = 1.0 - smoothstep(0.25, 1.0, length(fwidth(local_position * 310.0)));
		col *= 1.0 + fur * detail_strength * visible;
	} else if (surface_mode == 6) {
		// 低对比织毯：世界坐标连续，避免每个模块各有一枚同样的 V 字。
		vec2 cell = abs(fract(world_position.xz / 1.4 + vec2(0.17, 0.31)) - 0.5);
		float diamond = cell.x + cell.y;
		float aa = max(fwidth(diamond), 0.003);
		float border = 1.0 - smoothstep(0.012, 0.012 + aa, abs(diamond - 0.35));
		float inside = 1.0 - smoothstep(0.13, 0.13 + aa, diamond);
		float thread = sin(world_position.x * 160.0) * sin(world_position.z * 160.0);
		float visible = 1.0 - smoothstep(0.25, 1.0, length(fwidth(world_position.xz * 160.0)));
		col *= 1.0 + border * 0.16 + inside * 0.04 + thread * 0.016 * visible;
	}
	vec3 emi = texture(palette, uv + vec2(0.0, 0.5)).rgb;
	if (dissolve > 0.0) {
		float n = hash(floor(UV * 2048.0) + floor(FRAGCOORD.xy * 0.25));
		if (n < dissolve) { discard; }
	}
	vec3 base = col * tint.rgb;
	base = mix(base, vec3(0.32), neutral_amount);
	ALBEDO = mix(base, vec3(1.0), clamp(flash, 0.0, 1.0));
	float e = emission_energy;
	if (kind == 5) { e *= 1.8; }
	else if (kind == 4 || kind == 6) { e *= 0.9; }
	else if (kind == 8) { e *= glow * 3.0; }
	else { e *= 0.8; }
	vec3 em = emi * e + col * glow * (kind == 8 ? 0.0 : 0.6);
	// 边缘光：保证黑暗里也能看清轮廓
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float rim = smoothstep(0.12, 0.85, fres);
	vec3 rc = mix(rim_color, rim_tint.rgb, rim_tint.a);
	em += rc * rim * (rim_strength + rim_boost) * (0.35 + 0.65 * base);
	em += vec3(1.0) * flash * 0.6;
	EMISSION = em;
	// Fine grain affects orientation and roughness as well as albedo.
	float height_field = 0.0;
	float roughness_variation = 0.0;
	if (surface_mode == 1) {
		float grain = sin(world_position.x * 52.0 + sin(world_position.z * 1.8) * 0.6);
		float visible = 1.0 - smoothstep(0.35, 1.0, fwidth(world_position.x * 52.0));
		height_field = grain * bump_strength * visible;
		roughness_variation = grain * 0.018 * visible + sin(world_position.x * 0.7 + world_position.z * 0.9) * 0.035;
	}
	if (bump_strength > 0.0) {
		vec3 dx = dFdx(VERTEX);
		vec3 dy = dFdy(VERTEX);
		vec3 rx = cross(dy, NORMAL);
		vec3 ry = cross(NORMAL, dx);
		float det = dot(dx, rx);
		vec3 grad = (dFdx(height_field) * rx + dFdy(height_field) * ry) / max(abs(det), 0.0000001) * sign(det);
		NORMAL = normalize(NORMAL - grad);
	}
	ROUGHNESS = clamp(kind == 3 ? metal_roughness : (kind == 4 || kind == 6 ? 0.19 : material_roughness + roughness_variation), 0.12, 1.0);
	SPECULAR = material_specular;
	METALLIC = kind == 3 ? 0.78 : 0.0;
}
