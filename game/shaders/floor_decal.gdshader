// 地面贴花：图集 4×4，INSTANCE_CUSTOM = (格子编号, 不透明度, 粗糙度, 0)。受光（暗处看不见，手电照到才显出来）。
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx, shadows_disabled;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform int grid = 4;
varying vec2 cell_uv;
varying float opacity;
varying float rough;

void vertex() {
	float cell = INSTANCE_CUSTOM.x;
	vec2 cr = vec2(mod(cell, float(grid)), floor(cell / float(grid)));
	cell_uv = (cr + clamp(UV, 0.004, 0.996)) / float(grid);
	opacity = INSTANCE_CUSTOM.y;
	rough = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec4 t = texture(atlas, cell_uv);
	ALBEDO = t.rgb;
	ALPHA = t.a * opacity;
	ROUGHNESS = rough;
	SPECULAR = 0.4;
}
