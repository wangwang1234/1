extends "res://tests/test_case.gd"
## 画面个性化：分离色调调色、光岛、地面贴花。都只影响表现：不改战斗随机流、不加障碍、不压在掩体 / 鼠窝 / 弹射板上。


func _dist(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func test_grade_tints_shadows_violet_and_keeps_team_colors() -> void:
	var p := ColorGrade.prepare(VisualStyle.section("grade"))
	var black := ColorGrade.grade(Color(0, 0, 0), p)
	check(black.b > black.g and black.r > black.g and black.b > 0.005, "纯黑要抬成深靛紫，不是死黑：%s" % str(black))
	var dark := ColorGrade.grade(Color(0.16, 0.16, 0.16), p)
	check(dark.b > dark.g + 0.01, "暗部灰色要往冷紫偏：%s" % str(dark))
	var bright := ColorGrade.grade(Color(0.85, 0.85, 0.85), p)
	check(bright.r > bright.b, "亮部要往暖偏：%s" % str(bright))
	for hex in ["#4fa3ff", "#ff5b5b", "#ffd166"]:
		var c := Color(hex)
		check(_dist(ColorGrade.grade(c, p), c) < 0.08, "队伍色 / 中立色调色后不能明显变：%s → %s" % [hex, str(ColorGrade.grade(c, p))])
	var tex := ColorGrade.texture()
	check(tex != null and tex.get_width() == int(VisualStyle.section("grade").lutSize), "要生成查找表")
	var e := VisualStyle.environment()
	check(e.adjustment_color_correction != null, "对局环境要挂上调色查找表")


func test_light_islands_are_visual_only_and_clear_of_cover() -> void:
	var world := make_world("full", 11)
	var state := world.rng.state
	var solids := world.map.solids.size()
	var view := MapView.new()
	view.build(world.map, 11)
	eq(world.rng.state, state, "光岛不能改变战斗随机流")
	eq(world.map.solids.size(), solids, "光岛不能增加障碍")
	var isl := view.islands
	check(isl != null and isl.lights.size() >= 4, "完整地图要有光岛灯")
	for l in isl.lights:
		check(l.get_parent() != null, "光岛灯要挂进场景")
		if l is SpotLight3D:
			check((l as SpotLight3D).light_projector != null, "光岛聚光要有投影贴图：" + l.name)
	check(isl.placements.size() > 0, "要有手机和彩灯这些实物")
	for p: Dictionary in isl.placements:
		var pos: Vector2 = p.position
		check(not world.map.overlaps_solid(pos.x, pos.y, float(p.radius)), "光岛实物不能压在掩体上：%s %s" % [p.module, str(pos)])
		for team: String in ["blue", "red"]:
			check(pos.distance_to(world.map.base_pos[team]) > 300.0, "光岛实物不能放在鼠窝上")
	# 电线、灯串线的每个采样点都不能穿进掩体
	var cfg := VisualStyle.section("lightIslands")
	var paths: Array = [cfg.phone.cable]
	paths.append_array(cfg.fairy.strands)
	for path: Array in paths:
		var pts: Array[Vector2] = []
		for q: Array in path:
			pts.append(Vector2(float(q[0]), float(q[1])))
		for q in LightIslands.smooth_path(pts, 10):
			# 钻进地图边界墙（沙发裙边底下）的那一截可以；其余不能穿过掩体
			var so := world.map.point_solid(q.x, q.y, 3.0)
			check(so == null or so.kind == "wall", "电线 / 灯串不能穿过掩体：%s" % str(q))
	view.free()
	world.dispose()


func test_light_islands_respect_quality_and_slice_map() -> void:
	var old := VisualStyle.quality
	VisualStyle.quality = "low"
	var world := make_world("full", 11)
	var view := MapView.new()
	view.build(world.map, 11)
	var omni := 0
	for l in view.islands.lights:
		if l.name.begins_with("fairy_glow"):
			omni += 1
		if l is SpotLight3D and (l as SpotLight3D).light_projector != null:
			check(l.shadow_enabled, "带投影贴图的灯低档也要开阴影，否则投影贴图不生效")
	eq(omni, 0, "低档不建彩灯补光")
	check(view.islands.lights.size() >= 4, "低档也要保留光岛聚光（光岛是画面个性，不是可选特效）")
	view.free()
	world.dispose()
	VisualStyle.quality = old
	var slice := make_world("slice", 11)
	var v2 := MapView.new()
	v2.build(slice.map, 11)
	eq(v2.islands.lights.size(), 0, "切片地图不建光岛（坐标按完整地图写的）")
	v2.free()
	slice.dispose()


func test_floor_decals_are_deterministic_and_keep_clearance() -> void:
	for mode in ["full", "slice"]:
		var first: Array = []
		for run in 2:
			var world := make_world(mode, 37)
			var state := world.rng.state
			var view := MapView.new()
			view.build(world.map, 37)
			eq(world.rng.state, state, "贴花不能改变战斗随机流")
			var list: Array = view.decals.placements
			check(list.size() > 10, "%s 地图要有足够的贴花" % mode)
			for d: Dictionary in list:
				var p: Vector2 = d.position
				check(not world.map.overlaps_solid(p.x, p.y, float(d.radius) * 0.5), "贴花不能大半压在掩体下：%s" % str(p))
				for team: String in ["blue", "red"]:
					check(p.distance_to(world.map.base_pos[team]) > 300.0, "贴花不能盖住鼠窝地毯")
				for pad in world.map.pads:
					check(p.distance_to(Vector2(pad.x, pad.y)) > 60.0, "贴花不能盖住弹射板")
			var sig := list.map(func(d): return [d.cell, d.position])
			if run == 0:
				first = sig
			else:
				eq(sig, first, "同一种子贴花摆放要一样")
			view.free()
			world.dispose()


func test_scale_textures_exist() -> void:
	for path in ["res://assets/textures/gobo_window_plant.png", "res://assets/textures/gobo_blinds.png", "res://assets/textures/gobo_table_chairs.png",
			"res://assets/textures/gobo_fridge_wedge.png", "res://assets/textures/study_window.png", "res://assets/textures/decals.png"]:
		check(load(path) is Texture2D, "缺少贴图：" + path)
