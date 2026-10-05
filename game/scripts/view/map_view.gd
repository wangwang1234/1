class_name MapView
extends Node3D
## 按 SimMap（来自 map_layout.json）把场景模块拼成地图：地面分区、边界墙和书架、障碍物（按碰撞尺寸拉伸/平铺）、
## 弹射装置、装饰散布（带种子，避开障碍）。大量重复物体用 MultiMesh。

const M := "res://assets/models/"
const BOOKS := ["book_blue", "book_red", "book_green", "book_yellow", "book_purple", "book_orange"]
# 装饰：[模块, 缩放, 权重]。模型按“仓鼠眼里的大小”做得偏大，散布时再缩到不抢戏的尺寸；数线类长物件少放。
const DECOS := [["pencil", 0.55, 2], ["eraser", 0.6, 2], ["paperball", 0.6, 2], ["sticky", 0.6, 2], ["coin", 0.5, 2], ["button", 0.6, 3],
	["block", 0.5, 1], ["marble", 0.7, 2], ["dice", 0.5, 1], ["clip", 0.7, 3], ["cap", 0.6, 2], ["crayon", 0.55, 2], ["ruler", 0.42, 1], ["shells", 0.9, 5]]

var map: SimMap
var _batches := {}          # 模块路径 -> Array[Transform3D]
var pad_tops: Array = []    # [{node, base_y}]
var rng := RandomNumberGenerator.new()


func build(m: SimMap, seed_: int = 1234) -> void:
	map = m
	rng.seed = seed_
	_build_floor()
	_build_bounds()
	_build_obstacles()
	_build_pads()
	_build_base_rugs()
	_scatter_decor()
	_flush()


func _add(module: String, xf: Transform3D) -> void:
	var p := M + module + ".glb"
	if not _batches.has(p):
		_batches[p] = []
	(_batches[p] as Array).append(xf)


func _flush() -> void:
	for p in _batches:
		var xfs: Array = _batches[p]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var outline := 0.0 if String(p).contains("floor") or String(p).contains("rug_edge") else (1.3 if String(p).contains("deco") else 1.6)
		mm.mesh = ToonMaterials.merged_mesh(p, outline)
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = String(p).get_file().get_basename()
		if String(p).contains("floor"):
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
	_batches.clear()


static func w(x: float, y: float, h: float = 0.0) -> Vector3:
	return Vector3(x * 0.01, h, y * 0.01)


# ---------------------------------------------------------------------------

func _floor_kind(x: float, y: float) -> String:
	var mid := map.width * 0.5
	if absf(x - mid) < 1000.0 and absf(y - map.height * 0.5) < 900.0:
		return "env/env_floor_carpet"
	if x < mid:
		return "env/env_floor_wood"
	return "env/env_floor_tile"


func _build_floor() -> void:
	var tile := 200.0
	var x := floorf(map.min_x / tile) * tile
	while x < map.max_x:
		var y := floorf(map.min_y / tile) * tile
		while y < map.max_y:
			var k := _floor_kind(x + tile * 0.5, y + tile * 0.5)
			var rot := Basis(Vector3.UP, PI * 0.5 * (rng.randi() % 4)) if k != "env/env_floor_wood" else Basis(Vector3.UP, PI * 0.5 * (rng.randi() % 2) * 2.0)
			_add(k, Transform3D(rot, w(x + tile * 0.5, y + tile * 0.5)))
			y += tile
		x += tile
	# 地毯流苏边
	var cx := map.width * 0.5
	var cy := map.height * 0.5
	for side: float in [-1.0, 1.0]:
		var ex := cx + side * 1000.0
		var yy := cy - 900.0
		while yy < cy + 900.0:
			if yy > map.min_y and yy < map.max_y:
				_add("env/env_rug_edge", Transform3D(Basis(Vector3.UP, -side * PI * 0.5), w(ex, yy + 50.0, 0.012)))
			yy += 100.0


func _build_bounds() -> void:
	# 上边界：墙 + 靠墙书架；左右：墙；下边界（靠镜头一侧）保持很低，只放踢脚线色的地板边
	var seg := 200.0
	var x := map.min_x
	while x < map.max_x - 1.0:
		_add("env/env_wall", Transform3D(Basis.IDENTITY, w(x + seg * 0.5, map.min_y + 40.0)))
		_add("env/env_shelf", Transform3D(Basis.IDENTITY, w(x + seg * 0.5, map.min_y + 82.0)))
		x += seg
	for side: int in [0, 1]:
		var xx := map.min_x + 20.0 if side == 0 else map.max_x - 20.0
		var y := map.min_y
		while y < map.max_y - 1.0:
			_add("env/env_wall", Transform3D(Basis(Vector3.UP, -PI * 0.5 if side == 0 else PI * 0.5), w(xx, y + seg * 0.5)))
			y += seg


func _build_obstacles() -> void:
	for so in map.solids:
		if so.prop != null:
			continue
		match so.kind:
			"counter":
				_counter(so)
			"books":
				_books(so)
			"box":
				var b := Basis.from_scale(Vector3(so.w / 70.0, so.ht / 60.0, so.h / 70.0))
				_add("props/prop_box", Transform3D(b, w(so.x + so.w * 0.5, so.y + so.h * 0.5)))
			"bottles":
				var b2 := Basis.from_scale(Vector3(so.w / 100.0, so.ht / 70.0, so.h / 100.0))
				_add("env/env_bottles", Transform3D(b2, w(so.x + so.w * 0.5, so.y + so.h * 0.5)))
			"can":
				var s := so.r / 40.0
				_add("env/env_can", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, so.ht / 52.0, s)), w(so.x, so.y)))
			"pot":
				var s2 := so.r / 46.0
				_add("env/env_pot", Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s2, s2, s2)), w(so.x, so.y)))


func _counter(so: SimMap.Solid) -> void:
	var long_x := so.w >= so.h
	var L := so.w if long_x else so.h
	var D := so.h if long_x else so.w
	var n := maxi(1, roundi(L / 100.0))
	var seg := L / n
	for i in n:
		var t := (i + 0.5) * seg
		var pos := w(so.x + (t if long_x else so.w * 0.5), so.y + (so.h * 0.5 if long_x else t))
		var b := Basis.IDENTITY if long_x else Basis(Vector3.UP, PI * 0.5)
		b = b * Basis.from_scale(Vector3(seg / 100.0, so.ht / 63.0, D / 70.0))
		_add("env/env_counter", Transform3D(b, pos))


func _books(so: SimMap.Solid) -> void:
	var long_x := so.w >= so.h
	var L := so.w if long_x else so.h
	var D := so.h if long_x else so.w
	var t := 0.0
	while t < L - 6.0:
		var th := rng.randf_range(9.0, 15.0)
		th = minf(th, L - t)
		var mod: String = BOOKS[rng.randi() % BOOKS.size()]
		var hs := so.ht / 62.0 * rng.randf_range(0.88, 1.15)
		var c := t + th * 0.5
		var pos := w(so.x + (c if long_x else so.w * 0.5), so.y + (so.h * 0.5 if long_x else c))
		# 书的厚度轴（模块 X）沿书墙方向；深度轴（模块 Z）沿短边
		var b := Basis.IDENTITY if long_x else Basis(Vector3.UP, PI * 0.5)
		b = b * Basis(Vector3.FORWARD, deg_to_rad(rng.randf_range(-3.0, 3.0))) * Basis.from_scale(Vector3(th / 12.0, hs, D / 44.0))
		_add("env/env_" + mod, Transform3D(b, pos))
		t += th + 0.6


func _build_pads() -> void:
	for p in map.pads:
		var n := ToonMaterials.instance(M + "props/prop_pad.glb", 1.6)
		n.position = w(p.x, p.y)
		n.rotation.y = HamsterView.yaw_for(atan2(float(p.ty) - float(p.y), float(p.tx) - float(p.x))) + PI * 0.5
		add_child(n)
		var top := n.find_child("top", true, false) as Node3D
		pad_tops.append({"node": top, "base_y": top.position.y if top else 0.0})


func _build_base_rugs() -> void:
	for team: String in ["blue", "red"]:
		var b: Vector2 = map.base_pos[team]
		var rug := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		var rr := float(Data.rule("hamster.baseHealRadius", 340)) * 0.01
		cyl.top_radius = rr
		cyl.bottom_radius = rr
		cyl.height = 0.02
		cyl.radial_segments = 64
		rug.mesh = cyl
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/team_rug.gdshader")
		m.set_shader_parameter("color", Color("#2e2c3a"))
		m.set_shader_parameter("color2", Color("#363445"))
		m.set_shader_parameter("accent", Color("#4fa3ff") if team == "blue" else Color("#ff5b5b"))
		rug.material_override = m
		rug.position = w(b.x, b.y, 0.012)
		rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rug)


func _scatter_decor() -> void:
	## 装饰：靠边、靠障碍物更密，路中间稀疏。不参与碰撞。
	var area := (map.max_x - map.min_x) * (map.max_y - map.min_y)
	var n := int(area / 30000.0)
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 8:
		tries += 1
		var x := rng.randf_range(map.min_x + 80.0, map.max_x - 80.0)
		var y := rng.randf_range(map.min_y + 140.0, map.max_y - 40.0)
		if map.overlaps_solid(x, y, 30.0):
			continue
		# 离障碍物/边界越近越容易放
		var near := map.overlaps_solid(x, y, 110.0) or y < map.min_y + 260.0 or y > map.max_y - 140.0
		if not near and rng.randf() > 0.35:
			continue
		# 不压在鼠窝和炮台上
		var bad := false
		for team: String in ["blue", "red"]:
			if Vector2(x, y).distance_to(map.base_pos[team]) < 240.0:
				bad = true
			for tp in map.turret_pos[team]:
				if Vector2(x, y).distance_to(tp) < 90.0:
					bad = true
		for p in map.pads:
			if Vector2(x, y).distance_to(Vector2(p.x, p.y)) < 60.0:
				bad = true
		if bad:
			continue
		var d: Array = _pick_deco()
		var s := float(d[1]) * rng.randf_range(0.85, 1.1)
		_add("env/env_deco_" + String(d[0]), Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), w(x, y, 0.004)))
		placed += 1


func _pick_deco() -> Array:
	var total := 0
	for d: Array in DECOS:
		total += int(d[2])
	var r := rng.randi() % total
	for d: Array in DECOS:
		r -= int(d[2])
		if r < 0:
			return d
	return DECOS[0]
