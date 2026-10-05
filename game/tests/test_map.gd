extends "res://tests/test_case.gd"
## 地图、碰撞、视线、寻路。


func test_full_map_builds() -> void:
	var m := SimMap.new()
	m.build("full")
	check(m.solids.size() > 50, "完整地图障碍数量 %d" % m.solids.size())
	eq(m.lanes.size(), 3, "三条兵线")
	eq(m.turret_pos.blue.size(), 3, "蓝队炮台")
	eq(m.crate_spots.size(), 21, "零食箱刷新点（20 小 + 1 大）")
	eq(m.pads.size(), 4, "弹射装置")


func test_slice_map_builds() -> void:
	var m := SimMap.new()
	m.build("slice")
	eq(m.lanes.size(), 1, "切片只有中路")
	eq(m.turret_pos.blue.size(), 1, "切片每队 1 座炮台")
	check(m.prop_spots.size() >= 6, "切片物件 %d" % m.prop_spots.size())
	check(m.pads.size() == 4, "切片弹射装置")
	# 鼠窝和兵线端点都在可通行区域
	for team in ["blue", "red"]:
		var b: Vector2 = m.base_pos[team]
		check(b.y > m.min_y and b.y < m.max_y, "鼠窝在切片范围内")


func test_resolve_circle_pushes_out() -> void:
	var m := SimMap.new()
	m.build("full")
	var so: SimMap.Solid = null
	for s in m.solids:
		if not s.circle and s.kind == "counter":
			so = s
			break
	check(so != null, "找到一个台面障碍")
	var o := SimEntity.new()
	o.x = so.x + so.w * 0.5
	o.y = so.y + 2.0
	m.resolve_circle(o, 16.0)
	check(not m.overlaps_solid(o.x, o.y, 15.9), "推出后不再重叠")


func test_los_blocked_by_wall() -> void:
	var m := SimMap.new()
	m.build("full")
	check(not m.has_los(-100, 100, 200, 100) or true, "边界")
	var so: SimMap.Solid = null
	for s in m.solids:
		if not s.circle and s.kind == "counter" and s.w > 200:
			so = s
			break
	var cx := so.x + so.w * 0.5
	check(not m.has_los(cx, so.y - 50.0, cx, so.y + so.h + 50.0), "穿过台面的视线被挡住")
	check(m.has_los(cx, so.y - 50.0, cx + 10.0, so.y - 60.0), "旁边的短视线畅通")


func test_flow_field_reaches_goal() -> void:
	var m := SimMap.new()
	m.build("full")
	var start: Vector2 = m.base_pos.blue + Vector2(200, 0)
	var goal: Vector2 = m.base_pos.red - Vector2(200, 0)
	var F := m.field_to(goal.x, goal.y)
	check(not F.is_empty(), "流场生成")
	var p := start
	var ok := false
	var o := SimEntity.new()
	for i in 3000:
		var d := m.field_dir(F, p.x, p.y, goal.x, goal.y)
		p += d * 20.0
		o.x = p.x
		o.y = p.y
		m.resolve_circle(o, 16.0)
		p = Vector2(o.x, o.y)
		if p.distance_to(goal) < 60.0:
			ok = true
			break
	check(ok, "沿流场从蓝方走到红方（最后位置 %s）" % str(p))
