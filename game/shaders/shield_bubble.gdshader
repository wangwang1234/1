// 鼠窝护盾：六边形格子 + 菲涅耳边缘，被打时闪亮。
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 color : source_color = vec4(0.3, 0.64, 1.0, 1.0);
uniform float hit = 0.0;

float hexdist(vec2 p) {
	p = abs(p);
	return max(dot(p, normalize(vec2(1.0, 1.732))), p.x);
}

vec4 hexcoords(vec2 uv) {
	vec2 r = vec2(1.0, 1.732);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return vec4(gv, uv - gv);
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	vec4 hc = hexcoords(UV * vec2(28.0, 14.0));
	float edge = smoothstep(0.42, 0.48, hexdist(hc.xy));
	float pulse = 0.5 + 0.5 * sin(TIME * 2.0 + hc.z * 0.7 + hc.w * 0.5);
	float a = fres * 0.55 + edge * (0.08 + 0.06 * pulse) + hit * 0.4 * (edge + fres);
	ALBEDO = color.rgb * a * 1.6;
}
