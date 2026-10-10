extends "res://tests/test_case.gd"
## 装饰构图不得改变战斗模拟的随机流、遮挡或交互物件净空。

func test_layout_keeps_simulation_state_and_is_reproducible() -> void:
	var w := make_world("full", 11)
	var before_state := w.rng.state
	var before_solids := w.map.solids.size()
	var a := MapView.new()
	a.build(w.map, 11)
	var b := MapView.new()
	b.build(w.map, 11)
	eq(w.rng.state, before_state, "美术不能消耗战斗 RNG")
	eq(w.map.solids.size(), before_solids, "装饰不能新增战斗碰撞")
	eq(a.decor_placements, b.decor_placements, "同种子美术必须可复现")
	check(a.decor_placements.size() > 0, "地图应有装饰")
	a.free()
	b.free()
	w.dispose()


func test_decorations_clear_solids_pads_and_objectives() -> void:
	for seed_ in [5, 11, 37]:
		var w := make_world("full", seed_)
		var view := MapView.new()
		view.build(w.map, seed_)
		for entry: Dictionary in view.decor_placements:
			var p: Vector2 = entry.position
			var radius := float(entry.radius)
			check(not w.map.overlaps_solid(p.x, p.y, radius), "%s 不能穿进掩体" % entry.module)
			check(p.x - radius >= w.map.min_x and p.x + radius <= w.map.max_x and p.y - radius >= w.map.min_y and p.y + radius <= w.map.max_y, "装饰不能超出地图")
			for pad in w.map.pads:
				check(p.distance_to(Vector2(pad.x, pad.y)) >= 60.0 + radius, "弹射板净空")
			for team: String in ["blue", "red"]:
				check(p.distance_to(w.map.base_pos[team]) >= 240.0 + radius, "鼠窝净空")
				for turret: Vector2 in w.map.turret_pos[team]:
					check(p.distance_to(turret) >= 90.0 + radius, "炮台净空")
		view.free()
		w.dispose()
