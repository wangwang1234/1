shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
#define FX_ADDITIVE
#include "res://shaders/fx_particle.gdshaderinc"
