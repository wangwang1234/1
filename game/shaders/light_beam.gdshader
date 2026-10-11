// 手电光锥的假体积光：加法混合、边缘和末端淡出，很淡，只为了在黑暗里看出光束方向。
// 光束里漂着灰尘颗粒：世界坐标里固定的随机点场（缓慢漂移），光锥扫过时点被“照亮”，转动手电时会闪烁。
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.92, 0.72, 1.0);
uniform float strength = 0.018;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float intersection_softness = 0.3;
uniform float mote_strength = 0.0;     // 0 = 关
uniform float mote_density = 14.0;     // 每米格子数
uniform float mote_size = 0.16;        // 颗粒半径（占格子比例）
uniform float mote_fill = 0.35;        // 有颗粒的格子比例
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}

float motes(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	vec3 h = hash3(cell);
	if (h.x > mote_fill) {
		return 0.0;
	}
	vec3 c = 0.2 + 0.6 * hash3(cell + 17.0);
	float d = length(f - c);
	// 亮度各不相同，偶尔有一颗特别亮
	return (1.0 - smoothstep(mote_size * 0.35, mote_size, d)) * (0.35 + 0.65 * h.y * h.y);
}

void fragment() {
	// UV.y：0 = 尖端（光源），1 = 底部（远端）
	float along = UV.y;
	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	float body = pow(clamp(1.0 - edge, 0.0, 1.0), 3.0);
	float fade = smoothstep(0.0, 0.24, along) * (1.0 - smoothstep(0.55, 1.0, along));
	// Transparent additive pass, with a soft intersection against scene geometry.
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 scene_position = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_distance = -scene_position.z / scene_position.w;
	float soft_intersection = clamp((scene_distance + VERTEX.z) / intersection_softness, 0.0, 1.0);
	float dust = 0.0;
	if (mote_strength > 0.0) {
		vec3 drift = vec3(TIME * 0.035, TIME * 0.05, -TIME * 0.025);
		vec3 p = world_position * mote_density + drift * mote_density;
		dust = motes(p) + motes(p * 0.61 + 31.0) * 0.7;
		// 光锥中段最明显；远端和光源附近淡出
		dust *= smoothstep(0.08, 0.3, along) * (1.0 - smoothstep(0.5, 0.95, along));
	}
	ALBEDO = color.rgb;
	ALPHA = clamp(strength * body * fade * soft_intersection + mote_strength * dust * soft_intersection, 0.0, 1.0);
}
