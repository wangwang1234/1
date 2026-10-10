// 鼠窝下的圆形队伍色地毯（同心圆条纹 + 白色点缀边），接受光照的平涂。
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 color : source_color = vec4(0.17, 0.31, 0.53, 1.0);
uniform vec4 color2 : source_color = vec4(0.23, 0.39, 0.66, 1.0);
uniform vec4 accent : source_color = vec4(0.31, 0.64, 1.0, 1.0);   // 队伍色：只用在边缘一圈（= 回血范围）

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// 圆柱顶面 UV 在 [0,1]²，取到中心距离
	float r = length((UV - vec2(0.5)) * 2.0);
	float band = step(0.5, fract(r * 4.0));
	vec3 c = mix(color.rgb, color2.rgb, band);
	float edge = smoothstep(0.9, 0.91, r) * (1.0 - smoothstep(0.96, 0.97, r));
	float dots = step(0.6, sin(atan(UV.y - 0.5, UV.x - 0.5) * 24.0)) * smoothstep(0.84, 0.85, r) * (1.0 - smoothstep(0.87, 0.88, r));
	c = mix(c, accent.rgb, edge * 0.85);
	c = mix(c, vec3(0.95, 0.91, 0.85), dots * 0.8);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.25, 0.32, ndl);
	float a = ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * a;
}
