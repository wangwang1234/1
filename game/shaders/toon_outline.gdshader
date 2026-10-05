// 描边：反向外壳（next_pass），线宽按屏幕像素恒定（1080p 下角色约 2 px、物件约 1.5 px）。
// 外壳方向用顶点色里存的平滑法线（Blender 构建时写入，硬边模型也不会断线）。
// 线色 = 固有色压暗（保留色相），不用纯黑。
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, diffuse_lambert, specular_disabled, shadows_disabled, fog_disabled;

uniform sampler2D palette : source_color, filter_nearest, repeat_disable;
uniform int kind = 0;
uniform float width_px = 2.0;
uniform float lightness = 0.35;
uniform vec3 line_tint : source_color = vec3(0.78, 0.72, 0.95);

instance uniform int skin_index : instance_index(0) = 0;
instance uniform int team_index : instance_index(1) = 0;
instance uniform int path_index : instance_index(2) = 0;
instance uniform float dissolve : instance_index(7) = 0.0;
instance uniform float outline_scale : instance_index(9) = 1.0;

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
	vec3 n = COLOR.rgb * 2.0 - 1.0;
	if (dot(n, n) < 0.01) { n = NORMAL; }
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 nv = mat3(MODELVIEW_MATRIX) * n;
	vec2 nc = (PROJECTION_MATRIX * vec4(nv, 0.0)).xy;
	float l = length(nc);
	if (l > 1e-5) { nc /= l; }
	float px = width_px * outline_scale * (VIEWPORT_SIZE.y / 1080.0);
	clip.xy += nc * px * 2.0 / VIEWPORT_SIZE * clip.w;
	// 往后推一点，减少和本体的深度打架
	clip.z -= 0.0002 * clip.w;
	POSITION = clip;
}

void fragment() {
	vec2 uv = v_uv;
	if (kind == 1) { uv.x += float(skin_index) / 16.0; }
	if (kind == 2) { uv.y += float(team_index) / 16.0; }
	if (kind == 8) { uv.x += float(path_index) / 16.0; }
	if (dissolve > 0.0) { discard; }
	vec3 c = texture(palette, uv).rgb;
	ALBEDO = c * lightness * line_tint;
}
