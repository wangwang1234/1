class_name MapView
extends Node3D
## 按 SimMap（来自 map_layout.json）把场景模块拼成地图：分区地面（书房 / 厨房 / 客厅 / 书架 / 沙发底 / 冰箱 / 礼物区，见 map_layout.json 的 art）、
## 边界（墙、书架、冰箱、橱柜、沙发裙边）、障碍物（按碰撞尺寸拉伸/平铺）、弹射装置、按区域散布装饰（带种子，避开障碍）、区域灯光。
## 大量重复物体用 MultiMesh。

const M := "res://assets/models/"
const BOOKS := ["book_blue", "book_red", "book_green", "book_yellow", "book_purple", "book_orange"]
# 各区域的装饰：[模块, 缩放, 权重]。批次 1 的老装饰模型偏大，散布时缩小；批次 3 的分区装饰按 1 倍做好。
const DECOS := {
	"study": [["pencil", 0.55, 2], ["eraser", 0.6, 2], ["paperball", 0.6, 2], ["sticky", 0.6, 2], ["clip", 0.7, 2], ["ruler", 0.42, 1], ["crayon", 0.55, 1],
		["pen", 1.0, 2], ["tape", 1.0, 1], ["sharpener", 1.0, 1], ["tack", 1.0, 2], ["band", 1.0, 2], ["notebook", 0.9, 1], ["glue", 1.0, 1],
		["staples", 1.0, 1], ["highlighter", 1.0, 1], ["paper", 0.9, 1], ["shells", 0.9, 2]],
	"kitchen": [["spoon", 1.0, 2], ["fork", 1.0, 2], ["sugar", 1.0, 2], ["cookie", 1.0, 2], ["cereal", 1.0, 3], ["pasta", 1.0, 2], ["peas", 1.0, 2],
		["teabag", 1.0, 1], ["match", 1.0, 2], ["chopstick", 0.9, 1], ["cap", 0.6, 2], ["crumbs", 1.0, 3], ["shells", 0.9, 2], ["puddle", 0.7, 1]],
	"living": [["block", 0.5, 2], ["marble", 0.7, 2], ["dice", 0.5, 1], ["coin", 0.5, 2], ["button", 0.6, 2], ["car", 1.0, 1], ["puzzle", 1.0, 2],
		["card", 1.0, 2], ["popcorn", 1.0, 3], ["chip", 1.0, 2], ["wrapper", 1.0, 2], ["crayon", 0.55, 1], ["shells", 0.9, 3]],
	"shelf": [["paperball", 0.6, 2], ["pencil", 0.55, 2], ["crayon", 0.55, 1], ["block", 0.5, 1], ["marble", 0.7, 1], ["card", 1.0, 1],
		["notebook", 0.9, 1], ["paper", 0.9, 1], ["pen", 1.0, 1], ["dust", 0.8, 2], ["coin", 0.5, 1], ["shells", 0.9, 2]],
	"sofa": [["dust", 1.0, 4], ["sock", 1.0, 1], ["hairtie", 1.0, 2], ["remote", 0.8, 1], ["crumbs", 1.0, 3], ["coin", 0.5, 2], ["popcorn", 1.0, 2],
		["chip", 1.0, 1], ["button", 0.6, 2], ["wrapper", 1.0, 1], ["shells", 0.9, 2]],
	"fridge": [["magnet", 1.0, 3], ["ice", 1.0, 2], ["grape", 1.0, 2], ["puddle", 1.0, 2], ["cap", 0.6, 1], ["peas", 1.0, 1], ["crumbs", 1.0, 1]],
	"gift": [["ribbon", 1.0, 3], ["bow", 1.0, 2], ["confetti", 1.0, 5], ["tag", 1.0, 1], ["balloon", 1.0, 1], ["wrapper", 1.0, 1]],
}
# 区域装饰密度倍数（沙发底更乱、礼物区满地彩纸）
const DENSITY := {"study": 1.0, "kitchen": 1.0, "living": 0.8, "shelf": 1.1, "sofa": 1.5, "fridge": 1.2, "gift": 2.2}
const FLOORS := {"study": "env/env_floor_wood", "shelf": "env/env_floor_wood", "kitchen": "env/env_floor_tile", "fridge": "env/env_floor_tile_white",
	"sofa": "env/env_floor_wood_dusty", "living": "env/env_floor_carpet", "gift": "env/env_floor_carpet"}

var map: SimMap
var _batches := {}          # 模块路径 + 空间格 -> {path, transforms}，避免整张地图一起提交
var pad_tops: Array = []    # [{node, base_y}]
var rng := RandomNumberGenerator.new()
var art: Dictionary = {}
var _big := Vector2(-1e9, -1e9)    # 大礼箱位置（礼物区中心）
var _flicker: Array = []           # [{light, base}]
var _t := 0.0
var decor_placements: Array[Dictionary] = [] # 审阅与碰撞净空测试使用，厘米坐标
var surface_placements: Array[Dictionary] = [] # 台面组合：完整落在既有静态掩体内


func build(m: SimMap, seed_: int = 1234) -> void:
	map = m
	rng.seed = seed_
	art = Data.map_layout().get("art", {})
	for c in map.crate_spots:
		if bool(c.big):
			_big = Vector2(float(c.x), float(c.y))
	_build_floor()
	StudyFloor.build(self, map)
	_build_bounds()
	_build_obstacles()
	_build_pads()
	_build_base_rugs()
	_build_zone_props()
	_build_surface_dressing()
	_build_room_accents()
	_build_decor_clusters()
	_scatter_decor()
	_flush()
	_build_lights()
	RoomArchitecture.build(self, map)
	RoomLighting.build_study(self, map)


func zone(x: float, y: float) -> String:
	## 地图坐标 → 美术区域名
	if x < float(art.get("studyMaxX", 1300)):
		return "study"
	if x > float(art.get("kitchenMinX", 3740)):
		return "kitchen"
	var fr: Dictionary = art.get("fridge", {})
	if not fr.is_empty() and absf(x - float(fr.x)) < float(fr.halfW) and y < float(fr.maxY):
		return "fridge"
	if Vector2(x, y).distance_to(_big) < float(art.get("giftR", 300)):
		return "gift"
	if y < float(art.get("shelfMaxY", 680)):
		return "shelf"
	if y > float(art.get("sofaMinY", 2420)):
		return "sofa"
	return "living"


func _process(delta: float) -> void:
	if _flicker.is_empty():
		return
	_t += delta
	for f: Dictionary in _flicker:
		# 电视光：缓慢起伏 + 偶尔跳一下（换镜头）
		var l: OmniLight3D = f.light
		l.light_energy = float(f.base) * (0.8 + 0.15 * sin(_t * 1.3) + 0.1 * sin(_t * 7.7) * sin(_t * 0.37))


func _add(module: String, xf: Transform3D) -> void:
	var p := M + module + ".glb"
	var cell_size := float(VisualStyle.section("composition").batchSizeMeters)
	var cell := Vector2i(floori(xf.origin.x / cell_size), floori(xf.origin.z / cell_size))
	var key := "%s_%d_%d" % [p, cell.x, cell.y]
	if not _batches.has(key):
		_batches[key] = {"path": p, "transforms": []}
	(_batches[key].transforms as Array).append(xf)


func _flush() -> void:
	for key in _batches:
		var p: String = _batches[key].path
		var xfs: Array = _batches[key].transforms
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var outline := 0.0 if String(p).contains("floor") or String(p).contains("rug") else (1.3 if String(p).contains("deco") else 1.6)
		mm.mesh = ToonMaterials.merged_mesh(p, outline)
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = String(p).get_file().get_basename()
		var flat := String(p).contains("floor") or String(p).contains("rug")
		var thin_decor := String(p).contains("deco") and mm.mesh.get_aabb().size.y < float(VisualStyle.section("decor").get("shadowMinHeightMeters", 0.045))
		if flat or thin_decor:
			# 纸张和薄碎屑不进入阴影通道；有明显厚度的装饰保留受光投影。
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
	_batches.clear()


static func w(x: float, y: float, h: float = 0.0) -> Vector3:
	return Vector3(x * 0.01, h, y * 0.01)


# ---------------------------------------------------------------------------

func _build_floor() -> void:
	var tile := 200.0
	var kinds := {}
	var x := floorf(map.min_x / tile) * tile
	while x < map.max_x:
		var y := floorf(map.min_y / tile) * tile
		while y < map.max_y:
			var z := zone(x + tile * 0.5, y + tile * 0.5)
			var k: String = FLOORS.get(z, "env/env_floor_carpet")
			kinds[Vector2i(int(x / tile), int(y / tile))] = k
			var rot := Basis(Vector3.UP, PI * 0.5 * (rng.randi() % 4)) if not k.contains("wood") else Basis(Vector3.UP, PI * (rng.randi() % 2))
			if not (RoomArchitecture.has_study_wall(map) and x + tile * 0.5 < 1300.0):
				_add(k, Transform3D(rot, w(x + tile * 0.5, y + tile * 0.5)))
			y += tile
		x += tile
	# 地毯流苏边：地毯格旁边不是地毯的那几条边
	var carpet := "env/env_floor_carpet"
	for key: Vector2i in kinds:
		if kinds[key] != carpet:
			continue
		var cx := (key.x + 0.5) * tile
		var cy := (key.y + 0.5) * tile
		for d: Array in [[Vector2i(0, -1), 0.0], [Vector2i(0, 1), PI], [Vector2i(1, 0), -PI * 0.5], [Vector2i(-1, 0), PI * 0.5]]:
			var nb: Vector2i = key + (d[0] as Vector2i)
			if not kinds.has(nb) or kinds[nb] == carpet:
				continue
			for half: float in [-0.5, 0.5]:
				var off := Vector2(d[0].x, d[0].y) * tile * 0.5 + Vector2(-d[0].y, d[0].x) * tile * 0.5 * half
				_add("env/env_rug_edge", Transform3D(Basis(Vector3.UP, float(d[1])), w(cx + off.x, cy + off.y, 0.012)))


func _build_bounds() -> void:
	# 上边界：墙 + 靠墙书架（冰箱那一段换成冰箱）；左边书房墙；右边厨房橱柜；下边界（靠镜头一侧）沙发底那段挂沙发裙边，其余保持很低
	var seg := 200.0
	var fr: Dictionary = art.get("fridge", {})
	var x := map.min_x
	while x < map.max_x - 1.0:
		var cx := x + seg * 0.5
		if not fr.is_empty() and cx > float(fr.wallFrom) and cx < float(fr.wallTo):
			_add("env/env_fridge", Transform3D(Basis.IDENTITY, w(cx, map.min_y + 40.0)))
		else:
			if not (RoomArchitecture.has_study_wall(map) and cx < 1300.0):
				_add("env/env_wall", Transform3D(Basis.IDENTITY, w(cx, map.min_y + 40.0)))
			_add("env/env_shelf", Transform3D(Basis.IDENTITY, w(cx, map.min_y + 82.0)))
		if zone(cx, map.max_y - 80.0) == "sofa":
			_add("env/env_sofa_skirt", Transform3D(Basis(Vector3.UP, PI), w(cx, map.max_y - 22.0)))
			if int(cx / seg) % 3 == 1:
				_add("env/env_sofa_leg", Transform3D(Basis.IDENTITY, w(cx, map.max_y - 40.0)))
		x += seg
	for side: int in [0, 1]:
		var xx := map.min_x + 20.0 if side == 0 else map.max_x - 20.0
		# 模块正面是 +Z（地图南边）；左墙朝东、右墙朝西
		var b := Basis(Vector3.UP, PI * 0.5 if side == 0 else -PI * 0.5)
		var y := map.min_y
		while y < map.max_y - 1.0:
			if side == 0 and RoomArchitecture.has_study_wall(map) and y + seg * 0.5 < 1400.0:
				y += seg
				continue
			var mod := "env/env_cabinet" if zone(xx, y + seg * 0.5) == "kitchen" else "env/env_wall"
			_add(mod, Transform3D(b, w(xx, y + seg * 0.5)))
			y += seg


func _build_zone_props() -> void:
	## 礼物区圆地毯（压在地毯上，不挡路）
	if _big.x > map.min_x and _big.x < map.max_x and _big.y > map.min_y and _big.y < map.max_y:
		var r := float(art.get("giftR", 300)) / 250.0
		_add("env/env_rug_party", Transform3D(Basis.IDENTITY.scaled(Vector3(r, 1.0, r)), w(_big.x, _big.y, 0.006)))


func _build_surface_dressing() -> void:
	# 台面组合的包围盒为 96×55 cm；不新增高于玩家的独立地面障碍。
	var cfg := VisualStyle.section("composition")
	for solid in map.solids:
		if solid.prop != null or solid.kind != "counter" or solid.circle:
			continue
		var long_x: bool = solid.w >= solid.h
		var length_: float = solid.w if long_x else solid.h
		var depth: float = solid.h if long_x else solid.w
		var count := maxi(1, floori(length_ / float(cfg.surfaceSpacingCm)))
		var step := length_ / count
		var scale_ := minf(1.0, minf((step - 8.0) / 96.0, (depth - 8.0) / 55.0))
		if scale_ < 0.5:
			continue
		for i in count:
			var t := (float(i) + 0.5) * step
			var p := Vector2(solid.x + (t if long_x else solid.w * 0.5), solid.y + (solid.h * 0.5 if long_x else t))
			var z := zone(p.x, p.y)
			var variants: Array = cfg.surfaces.get(z, cfg.surfaces.living)
			var module := String(variants[i % variants.size()])
			var b := Basis.IDENTITY if long_x else Basis(Vector3.UP, PI * 0.5)
			_add("env/env_dress_" + module, Transform3D(b.scaled(Vector3.ONE * scale_), w(p.x, p.y, solid.ht * 0.01 + 0.008)))
			surface_placements.append({"module": module, "position": p, "scale": scale_, "long_x": long_x,
				"bounds": Rect2(solid.x, solid.y, solid.w, solid.h), "height": solid.ht * 0.01 + 0.008})


func _build_room_accents() -> void:
	# 平铺织物只覆盖地板，不影响战斗碰撞；与鼠窝、炮台、弹射板保持同样净空。
	for item: Array in VisualStyle.section("composition").rugs:
		var p := Vector2(float(item[0]), float(item[1]))
		var s := float(item[2])
		var radius := 137.0 * s
		if not _decoration_clear(p, radius):
			continue
		var a := deg_to_rad(float(item[3]))
		var module := String(item[4]) if item.size() > 4 else "rug"
		_add("env/env_dress_" + module, Transform3D(Basis(Vector3.UP, a).scaled(Vector3(s, 1.0, s)), w(p.x, p.y, 0.005)))
		decor_placements.append({"module": "dress_" + module, "position": p, "radius": radius, "angle": a, "scale": s})


func _build_lights() -> void:
	## 区域光：冰箱冷光、电视蓝光（闪烁）、厨房橱柜暖光。不投影，便宜
	for L: Dictionary in art.get("lights", []):
		var x := float(L.x)
		var y := float(L.y)
		if x < map.min_x - 200.0 or x > map.max_x + 200.0 or y < map.min_y - 200.0 or y > map.max_y + 200.0:
			continue
		var l := OmniLight3D.new()
		l.light_color = Color(String(L.color))
		l.light_energy = float(L.energy)
		l.omni_range = float(L.range)
		l.omni_attenuation = 1.2
		l.light_specular = 0.5
		l.shadow_enabled = false
		l.position = w(x, y, float(L.get("h", 1.0)))
		add_child(l)
		if bool(L.get("flicker", false)):
			_flicker.append({"light": l, "base": float(L.energy)})


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
	var n := int(area * 0.0001 * float(art.get("decoPerM2", 0.34)) * float(VisualStyle.section("decor").looseDensityScale))
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 8:
		tries += 1
		var x := rng.randf_range(map.min_x + 80.0, map.max_x - 80.0)
		var y := rng.randf_range(map.min_y + 140.0, map.max_y - 40.0)
		if map.overlaps_solid(x, y, 30.0):
			continue
		var z := zone(x, y)
		# 离障碍物/边界越近越容易放；各区域密度不同
		var near := map.overlaps_solid(x, y, 110.0) or y < map.min_y + 260.0 or y > map.max_y - 140.0
		if not near and rng.randf() > 0.35:
			continue
		if rng.randf() > float(DENSITY.get(z, 1.0)) / 2.2:
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
		var d: Array = _pick_deco(z)
		var s := float(d[1]) * rng.randf_range(0.85, 1.1)
		if _place_decor(String(d[0]), s, Vector2(x, y), rng.randf() * TAU):
			placed += 1


func _pick_deco(z: String) -> Array:
	var list: Array = DECOS.get(z, DECOS["living"])
	var total := 0
	for d: Array in list:
		total += int(d[2])
	var r := rng.randi() % total
	for d: Array in list:
		r -= int(d[2])
		if r < 0:
			return d
	return list[0]


func _decor_radius(module: String, scale_: float) -> float:
	var footprints: Dictionary = VisualStyle.section("decor").footprintsCm
	return float(footprints.get(module, 25.0)) * scale_


func _decoration_clear(p: Vector2, radius: float) -> bool:
	# 以整件物体的包围半径检查，避免叉子、纸张穿进掩体或铺到地图之外。
	if p.x - radius < map.min_x or p.x + radius > map.max_x or p.y - radius < map.min_y or p.y + radius > map.max_y:
		return false
	if map.overlaps_solid(p.x, p.y, radius + 4.0):
		return false
	for team: String in ["blue", "red"]:
		if p.distance_to(map.base_pos[team]) < 240.0 + radius:
			return false
		for tp: Vector2 in map.turret_pos[team]:
			if p.distance_to(tp) < 90.0 + radius:
				return false
	for pad in map.pads:
		if p.distance_to(Vector2(pad.x, pad.y)) < 60.0 + radius:
			return false
	for old: Dictionary in decor_placements:
		if p.distance_to(old.position) < (radius + float(old.radius)) * 0.7:
			return false
	return true


func _place_decor(module: String, scale_: float, p: Vector2, angle: float) -> bool:
	var radius := _decor_radius(module, scale_)
	if not _decoration_clear(p, radius):
		return false
	_add("env/env_deco_" + module, Transform3D(Basis(Vector3.UP, angle).scaled(Vector3.ONE * scale_), w(p.x, p.y, 0.004)))
	decor_placements.append({"module": module, "position": p, "radius": radius, "angle": angle, "scale": scale_})
	return true


func _build_decor_clusters() -> void:
	# 少量成组物件交代人的生活痕迹；靠掩体摆放，交战路面保留空白。
	var cfg := VisualStyle.section("decor")
	var recipes: Dictionary = cfg.recipes
	var anchors: Array[Vector2] = []
	var budget := int(cfg.clusters)
	for attempt in budget * 30:
		if anchors.size() >= budget:
			break
		var p := Vector2(rng.randf_range(map.min_x + 160.0, map.max_x - 160.0), rng.randf_range(map.min_y + 160.0, map.max_y - 160.0))
		if not _decoration_clear(p, 70.0):
			continue
		if not map.overlaps_solid(p.x, p.y, 220.0) and p.y > map.min_y + 300.0 and p.y < map.max_y - 250.0:
			continue
		var spaced := true
		for previous: Vector2 in anchors:
			if p.distance_to(previous) < 310.0:
				spaced = false
		if not spaced:
			continue
		anchors.append(p)
		var recipe: Array = recipes.get(zone(p.x, p.y), recipes["living"])
		var angle := rng.randf() * TAU
		for item: Array in recipe.slice(0, int(cfg.members)):
			var offset := Vector2(float(item[2]), float(item[3])).rotated(angle) * float(cfg.clusterRadiusCm) / 45.0
			_place_decor(String(item[0]), float(item[1]), p + offset, angle + rng.randf_range(-0.2, 0.2))
