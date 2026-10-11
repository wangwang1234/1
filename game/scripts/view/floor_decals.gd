class_name FloorDecals
extends RefCounted
## 地面贴花：人类生活留下的痕迹按仓鼠尺度放大（咖啡杯印有仓鼠那么大、灰尘里一只比仓鼠长两倍的袜子脚印、果汁渍、蜡笔涂鸦……），
## 打破地板重复感、交代尺度。图集由 tools/build_decals.py 生成；参数在 visual_style.json 的 floorDecals。
## 平贴在地上、不投影、不参与碰撞；用自己的随机数（不碰战斗随机流），按空间格合批。

var placements: Array[Dictionary] = []    # {cell, position(cm), radius(cm), angle, size}


static func build(parent: MapView, map: SimMap, seed_: int) -> FloorDecals:
	var fd := FloorDecals.new()
	var cfg := VisualStyle.section("floorDecals")
	if cfg.is_empty() or not bool(cfg.get("enabled", true)):
		return fd
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 7919 + 17
	var sizes: Dictionary = cfg.sizesCm
	for f: Dictionary in cfg.get("fixed", []):
		var p := Vector2(float(f.position[0]), float(f.position[1]))
		fd._try(parent, map, int(f.cell), p, deg_to_rad(float(f.angleDeg)), float(f.sizeCm), cfg)
	var zones: Dictionary = cfg.zones
	var counts := {}
	var tries := 0
	var want := 0
	for z: String in zones:
		want += int(zones[z].count)
	while tries < want * 40:
		tries += 1
		var p := Vector2(rng.randf_range(map.min_x + 60.0, map.max_x - 60.0), rng.randf_range(map.min_y + 120.0, map.max_y - 60.0))
		var z := parent.zone(p.x, p.y)
		if not zones.has(z) or int(counts.get(z, 0)) >= int(zones[z].count):
			continue
		var cell := _pick(rng, zones[z].kinds)
		var range_: Array = sizes.get(str(cell), [60, 80])
		var size := rng.randf_range(float(range_[0]), float(range_[1]))
		if fd._try(parent, map, cell, p, rng.randf() * TAU, size, cfg):
			counts[z] = int(counts.get(z, 0)) + 1
	fd._flush(parent, cfg)
	return fd


static func _pick(rng: RandomNumberGenerator, kinds: Array) -> int:
	var total := 0
	for k: Array in kinds:
		total += int(k[1])
	var r := rng.randi() % total
	for k: Array in kinds:
		r -= int(k[1])
		if r < 0:
			return int(k[0])
	return int(kinds[0][0])


func _try(view: MapView, map: SimMap, cell: int, p: Vector2, angle: float, size: float, cfg: Dictionary) -> bool:
	var radius := size * 0.5
	if p.x - radius < map.min_x or p.x + radius > map.max_x or p.y - radius < map.min_y or p.y + radius > map.max_y:
		return false
	# 中心和大半个贴花不能压在掩体底下（看不见又浪费）
	if map.overlaps_solid(p.x, p.y, radius * 0.55):
		return false
	for team: String in ["blue", "red"]:
		if p.distance_to(map.base_pos[team]) < float(cfg.get("baseClearCm", 360.0)) + radius:
			return false
	for pad in map.pads:
		if p.distance_to(Vector2(pad.x, pad.y)) < 70.0 + radius:
			return false
	for old: Dictionary in view.decor_placements:
		if String(old.module).begins_with("dress_") and p.distance_to(old.position) < float(old.radius) + radius:
			return false     # 不叠在成组的小地毯上（同高度会闪）
	for old: Dictionary in placements:
		if p.distance_to(old.position) < (radius + float(old.radius)) * 0.8:
			return false
	placements.append({"cell": cell, "position": p, "radius": radius, "angle": angle, "size": size})
	return true


func _flush(parent: Node3D, cfg: Dictionary) -> void:
	var cell_size := float(VisualStyle.section("composition").batchSizeMeters)
	var groups := {}
	for d: Dictionary in placements:
		var w := MapView.w(d.position.x, d.position.y, float(cfg.get("heightM", 0.009)))
		var key := Vector2i(floori(w.x / cell_size), floori(w.z / cell_size))
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(d)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/floor_decal.gdshader")
	mat.set_shader_parameter("atlas", load("res://assets/textures/decals.png"))
	mat.set_shader_parameter("grid", int(cfg.get("grid", 4)))
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	var rough: Dictionary = cfg.get("roughness", {})
	var root := Node3D.new()
	root.name = "FloorDecals"
	parent.add_child(root)
	for key: Vector2i in groups:
		var list: Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = plane
		mm.instance_count = list.size()
		for i in list.size():
			var d: Dictionary = list[i]
			var s := float(d.size) * 0.01
			var xf := Transform3D(Basis(Vector3.UP, float(d.angle)).scaled(Vector3(s, 1.0, s)), MapView.w(d.position.x, d.position.y, float(cfg.get("heightM", 0.009))))
			mm.set_instance_transform(i, xf)
			mm.set_instance_custom_data(i, Color(float(d.cell), float(cfg.get("opacity", 0.85)), float(rough.get(str(d.cell), 0.85)), 0.0))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "decals_%d_%d" % [key.x, key.y]
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)
