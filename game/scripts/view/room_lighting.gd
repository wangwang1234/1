class_name RoomLighting
extends RefCounted
## Authored window, fill and bounce approximation. No baked or real-time GI is claimed.
## Reflection captures static layer 1 only, avoiding hidden-enemy reflections.

static func vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

static func inside_map(pos: Vector3, map: SimMap) -> bool:
	return pos.x >= map.min_x * 0.01 and pos.x <= map.max_x * 0.01 and pos.z >= map.min_y * 0.01 and pos.z <= map.max_y * 0.01


static func add_reflection(parent: Node3D, item: Dictionary, map: SimMap) -> void:
	if not bool(item.enabled) or not inside_map(vector(item.position), map):
		return
	var probe := ReflectionProbe.new()
	probe.name = String(item.get("name", "StaticRoomReflection"))
	probe.position = vector(item.position)
	probe.size = vector(item.size)
	probe.intensity = float(item.intensity)
	probe.max_distance = probe.size.length()
	probe.box_projection = true
	probe.cull_mask = 1
	probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	parent.add_child(probe)


static func build_study(parent: Node3D, map: SimMap) -> void:
	var cfg := VisualStyle.section("studyLighting")
	var other := VisualStyle.section("roomLighting")
	var room := Node3D.new()
	room.name = "RoomLighting"
	parent.add_child(room)
	var lights: Array = cfg.lights.duplicate() if bool(cfg.enabled) else []
	lights.append_array(other.get("lights", []))
	for item: Dictionary in lights:
		var pos := vector(item.position)
		if not inside_map(pos, map):
			continue
		var light: Light3D
		if String(item.type) == "spot":
			var spot := SpotLight3D.new()
			spot.spot_range = float(item.range)
			spot.spot_angle = float(item.angle)
			spot.spot_attenuation = float(item.attenuation)
			spot.spot_angle_attenuation = float(item.coneAttenuation)
			if item.has("projector"):
				spot.light_projector = load(String(item.projector)) as Texture2D
			light = spot
		else:
			var omni := OmniLight3D.new()
			omni.omni_range = float(item.range)
			omni.omni_attenuation = float(item.attenuation)
			omni.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID
			light = omni
		light.name = String(item.name)
		light.light_color = Color(String(item.color))
		light.light_energy = float(item.energy)
		light.light_specular = float(item.specular)
		light.light_size = float(item.size)
		light.shadow_enabled = bool(item.shadow)
		light.shadow_bias = 0.025
		light.shadow_normal_bias = 0.15
		room.add_child(light)
		light.position = pos
		if item.has("target"):
			# Works while constructing off-tree maps as well as in the live scene.
			light.basis = Basis.looking_at(vector(item.target) - pos, Vector3.UP)
	if bool(cfg.enabled):
		add_reflection(room, cfg.reflection, map)
	for reflection: Dictionary in other.get("reflections", []):
		add_reflection(room, reflection, map)
