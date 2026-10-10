// 手电光锥的假体积光：加法混合、边缘和末端淡出，很淡，只为了在黑暗里看出光束方向。
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.92, 0.72, 1.0);
uniform float strength = 0.018;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float intersection_softness = 0.3;

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
	ALBEDO = color.rgb;
	ALPHA = strength * body * fade * soft_intersection;
}
