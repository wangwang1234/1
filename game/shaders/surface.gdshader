// Environment: continuous diffuse + GGX direct light and radiance reflection.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
#include "palette_surface.gdshaderinc"
