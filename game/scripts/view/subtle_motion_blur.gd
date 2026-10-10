class_name SubtleMotionBlur
extends CompositorEffect
## Current-frame velocity blur, not temporal accumulation. Opaque motion vectors
## and depth rejection keep different surfaces from bleeding into each other.
## Each camera owns its focus and shutter state; UI is rendered afterwards.

const CODE := """
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;
layout(set = 0, binding = 1) uniform sampler2D source_image;
layout(set = 0, binding = 2) uniform sampler2D velocity_image;
layout(set = 0, binding = 3) uniform sampler2D depth_image;
layout(rgba16f, set = 0, binding = 4) uniform image2D scratch_image;
layout(push_constant, std430) uniform Params {
 vec2 size;
 vec2 focus;
 float shutter;
 float maximum_px;
 float amount;
 float operation;
} params;

float linear_depth(float d) {
 return 0.2 * 120.0 / (0.2 + d * (120.0 - 0.2));
}

void main() {
 ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
 if (any(greaterThanEqual(pixel, ivec2(params.size)))) return;
 vec4 base = imageLoad(color_image, pixel);
 if (params.operation < 0.5) {
  imageStore(scratch_image, pixel, base);
  return;
 }
 vec2 uv = (vec2(pixel) + 0.5) / params.size;
 vec2 velocity = textureLod(velocity_image, uv, 0.0).xy;
 vec2 travel = velocity * params.size * params.shutter;
 float pixels = length(travel);
 if (pixels < 0.35 || pixels > params.size.x * 0.2) return;
 // Preserve the player and aiming area, with a smooth elliptical transition.
 vec2 focus_delta = (uv - params.focus) * vec2(params.size.x / params.size.y, 1.0);
 float focus_weight = smoothstep(0.12, 0.28, length(focus_delta));
 float amount = params.amount * focus_weight * smoothstep(0.35, 1.2, pixels);
 if (amount < 0.001) return;
 vec2 offset = travel / max(pixels, 0.0001) * min(pixels, params.maximum_px) / params.size;
 float center_depth = linear_depth(textureLod(depth_image, uv, 0.0).r);
 vec4 total = base * 2.0;
 float weight_sum = 2.0;
 for (int i = 0; i < 4; i++) {
  float step_offset = (i < 2 ? -1.0 : 1.0) * (i % 2 == 0 ? 0.5 : 0.25);
  vec2 sample_uv = uv + offset * step_offset;
  if (any(lessThan(sample_uv, vec2(0.0))) || any(greaterThan(sample_uv, vec2(1.0)))) continue;
  float sample_depth = linear_depth(textureLod(depth_image, sample_uv, 0.0).r);
  float weight = 1.0 - smoothstep(0.025, max(0.06, center_depth * 0.008), abs(sample_depth - center_depth));
  total += textureLod(source_image, sample_uv, 0.0) * weight;
  weight_sum += weight;
 }
 imageStore(color_image, pixel, mix(base, total / weight_sum, amount));
}
"""

var _rd: RenderingDevice
var _shader := RID()
var _pipeline := RID()
var _sampler := RID()
var _mutex := Mutex.new()
var _focus := Vector2(0.5, 0.5)
var _shutter := 0.33
var _maximum := 1.8
var _amount := 0.42
var _failed := false


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	access_resolved_color = true
	access_resolved_depth = true
	needs_motion_vectors = true
	var cfg: Dictionary = VisualStyle.section("camera").get("motionBlur", {})
	_maximum = float(cfg.get("maximumPixels720p", 1.8))
	_amount = float(cfg.get("amount", 0.42))
	enabled = bool(cfg.get("enabled", true))


func set_focus(point: Vector2, delta: float) -> void:
	_mutex.lock()
	_focus = point.clamp(Vector2.ZERO, Vector2.ONE)
	# A fixed exposure makes the blur independent of the displayed frame rate.
	_shutter = clampf((1.0 / 180.0) / maxf(delta, 1.0 / 240.0), 0.015, 0.75)
	_mutex.unlock()


func _compile() -> bool:
	if _failed:
		return false
	if _pipeline.is_valid():
		return true
	_rd = RenderingServer.get_rendering_device()
	if _rd == null:
		return false
	var source := RDShaderSource.new()
	source.source_compute = CODE
	var spirv := _rd.shader_compile_spirv_from_source(source)
	if spirv.compile_error_compute != "":
		push_error("SubtleMotionBlur: " + spirv.compile_error_compute)
		_failed = true
		return false
	_shader = _rd.shader_create_from_spirv(spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	var sampler := RDSamplerState.new()
	sampler.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	_sampler = _rd.sampler_create(sampler)
	print("[motion] depth-aware velocity blur compiled")
	return _pipeline.is_valid()


func _render_callback(callback: int, data: RenderData) -> void:
	if callback != effect_callback_type or not _compile():
		return
	var buffers := data.get_render_scene_buffers() as RenderSceneBuffersRD
	if buffers == null:
		return
	var size := buffers.get_internal_size()
	if size.x == 0 or size.y == 0:
		return
	var context := &"subtle_motion_blur"
	if not buffers.has_texture(context, &"source"):
		buffers.create_texture(context, &"source", RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT,
			RenderingDevice.TEXTURE_SAMPLES_1, size, buffers.get_view_count(), 1, false, false)
	_mutex.lock()
	var focus := _focus
	var shutter := _shutter
	_mutex.unlock()
	for view in buffers.get_view_count():
		var color := buffers.get_color_layer(view)
		var velocity := buffers.get_velocity_layer(view)
		var depth := buffers.get_depth_layer(view)
		var scratch := buffers.get_texture_slice(context, &"source", view, 0, 1, 1)
		if not color.is_valid() or not velocity.is_valid() or not depth.is_valid():
			continue
		var uniforms: Array[RDUniform] = []
		for binding in 5:
			var uniform := RDUniform.new()
			uniform.binding = binding
			if binding == 0 or binding == 4:
				uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				uniform.add_id(color if binding == 0 else scratch)
			else:
				uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				uniform.add_id(_sampler)
				uniform.add_id(scratch if binding == 1 else (velocity if binding == 2 else depth))
			uniforms.append(uniform)
		var uniform_set := UniformSetCacheRD.get_cache(_shader, 0, uniforms)
		var constants := PackedFloat32Array([size.x, size.y, focus.x, focus.y, shutter,
			_maximum * float(size.y) / 720.0, _amount, 0.0])
		var list := _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(list, _pipeline)
		_rd.compute_list_bind_uniform_set(list, uniform_set, 0)
		_rd.compute_list_set_push_constant(list, constants.to_byte_array(), 32)
		_rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(size.y / 8.0), 1)
		_rd.compute_list_add_barrier(list)
		constants[7] = 1.0
		_rd.compute_list_set_push_constant(list, constants.to_byte_array(), 32)
		_rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(size.y / 8.0), 1)
		_rd.compute_list_end()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rd != null:
		if _shader.is_valid():
			_rd.free_rid(_shader)
		if _sampler.is_valid():
			_rd.free_rid(_sampler)
