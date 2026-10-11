extends "res://tests/test_case.gd"
## 暗处可见（2026-10-11 导演改黑暗思路）：视线内的敌人即使没被照亮也画出来（world.seen），但不算“被发现”（world.vis）；
## 墙、掩体、烟雾挡住就看不见；超出距离、隐身中的不算；辅助瞄准会吸附；AI 只在更短距离内察觉，反应更慢。


func _world(ai_blue: int = 0) -> SimWorld:
	var players: Array = [] if ai_blue > 0 else [{"team": "blue", "ctl": "player", "name": "测"}]
	var w := make_world("full", 9, ai_blue, 0, players)
	for e in w.mobs:
		e.dead = true
	for m in w.minions:
		m.dead = true
	var h := w.hams[0]
	h.x = 2520.0
	h.y = 1548.0
	h.px = h.x
	h.py = h.y
	h.aim = PI      # 手电朝西
	h.inp.aim = PI
	return w


func _foe(w: SimWorld, x: float, y: float) -> SimHamster:
	var f := w._make_ham("red", "player", "靶子", 9, "gold")
	f.x = x
	f.y = y
	f.px = x
	f.py = y
	return f


func _spot(w: SimWorld, h: SimHamster, dist: float, want_los: bool) -> Vector2:
	## 在仓鼠身后（东侧半圆，手电照不到）找一个距离 dist、视线通 / 不通的空地
	for a in range(-80, 81, 5):
		var p := Vector2(h.x, h.y) + Vector2.RIGHT.rotated(deg_to_rad(a)) * dist
		if w.map.overlaps_solid(p.x, p.y, 24.0):
			continue
		if w.map.has_los(h.x, h.y, p.x, p.y) == want_los:
			return p
	return Vector2.INF


func test_dark_enemy_in_sight_is_seen_but_not_revealed() -> void:
	var w := _world()
	var h := w.hams[0]
	var p := _spot(w, h, 420.0, true)
	if not check(p != Vector2.INF, "要找得到视线通的位置"):
		return
	var f := _foe(w, p.x, p.y)
	SimVision.compute(w)
	check(not w.vis.blue.has(f.id), "手电没照到：不算被发现（没血条、不上小地图）")
	check(w.seen.blue.has(f.id), "视线内：要画出来")
	check(w.is_seen_by("blue", f) and not w.is_visible_to("blue", f), "两个判定要分开")
	# 被照亮的一定也在 seen 里
	h.aim = 0.0
	h.inp.aim = 0.0
	f.x = h.x + 300.0
	f.y = h.y
	if w.map.has_los(h.x, h.y, f.x, f.y):
		SimVision.compute(w)
		check(w.vis.blue.has(f.id) and w.seen.blue.has(f.id), "照亮的同时也在视线集合里")
	w.dispose()


func test_walls_range_smoke_and_stealth_hide_dark_enemies() -> void:
	var w := _world()
	var h := w.hams[0]
	var rr := float(w.R.vision.dim.range)
	var far := _spot(w, h, rr + 120.0, true)
	if far != Vector2.INF:
		var f1 := _foe(w, far.x, far.y)
		SimVision.compute(w)
		check(not w.seen.blue.has(f1.id), "超出距离不显示")
		f1.alive = false
	var blocked := Vector2.INF
	for dist: float in [300.0, 380.0, 460.0, 540.0]:
		for a in range(0, 360, 10):
			var q: Vector2 = Vector2(h.x, h.y) + Vector2.RIGHT.rotated(deg_to_rad(a)) * dist
			if blocked == Vector2.INF and not w.map.overlaps_solid(q.x, q.y, 24.0) and not w.map.has_los(h.x, h.y, q.x, q.y):
				blocked = q
	if blocked != Vector2.INF:
		# 挡住的那一侧也要在手电外：手电朝反方向
		h.aim = atan2(h.y - blocked.y, h.x - blocked.x)
		h.inp.aim = h.aim
	if check(blocked != Vector2.INF, "要找得到被挡住的位置"):
		var f2 := _foe(w, blocked.x, blocked.y)
		SimVision.compute(w)
		check(not w.seen.blue.has(f2.id), "墙 / 掩体挡住就不显示")
		f2.alive = false
	h.aim = PI
	h.inp.aim = PI
	var p := _spot(w, h, 420.0, true)
	var f3 := _foe(w, p.x, p.y)
	w.smokes.append({"id": 99999, "x": (h.x + p.x) * 0.5, "y": (h.y + p.y) * 0.5, "r": 120.0, "t": 0.0, "life": 10.0})
	SimVision.compute(w)
	check(not w.seen.blue.has(f3.id), "烟雾挡住就不显示")
	w.smokes.clear()
	f3.invis_t = 2.0
	SimVision.compute(w)
	check(not w.seen.blue.has(f3.id), "隐身中的仓鼠不显示")
	f3.invis_t = 0.0
	SimVision.compute(w)
	check(w.seen.blue.has(f3.id), "烟散了、隐身结束就又能看到")
	w.dispose()


func test_aim_assist_pulls_toward_dark_enemy() -> void:
	var w := _world()
	var h := w.hams[0]
	var p := _spot(w, h, 300.0, true)
	var f := _foe(w, p.x, p.y)
	SimVision.compute(w)
	check(not w.vis.blue.has(f.id), "前提：暗处")
	var exact := atan2(f.y - h.y, f.x - h.x)
	var aim := exact + 0.08
	var out := SimWeapons.aim_assist(w, h, aim, 1.0)
	check(absf(SimUtil.ang_diff(out, exact)) < absf(SimUtil.ang_diff(aim, exact)), "辅助瞄准要往暗处的敌人吸")
	w.dispose()


func test_ai_notices_dark_enemies_only_up_close_and_reacts_slower() -> void:
	var w := _world(1)
	var h := w.hams[0]
	h.ctl = "ai"
	var see := SimAI.dim_see_range(w, h)
	check(see < float(w.R.vision.dim.range), "AI 察觉暗处敌人的距离要比玩家画面里能看到的短")
	var near := _spot(w, h, see * 0.7, true)
	var f := _foe(w, near.x, near.y)
	SimVision.compute(w)
	check(SimAI.is_dim_target(w, h, f), "前提：暗处目标")
	eq(SimAI._target(w, h), f, "近处的暗处敌人 AI 要能察觉")
	var far := _spot(w, h, minf(see + 160.0, float(w.R.vision.dim.range) - 40.0), true)
	if far != Vector2.INF:
		f.x = far.x
		f.y = far.y
		SimVision.compute(w)
		check(w.seen.blue.has(f.id), "前提：玩家画面里看得到")
		check(SimAI._target(w, h) != f, "超出 AI 察觉距离的暗处敌人不选")
	# 照亮之后就不是暗处目标
	w.vis.blue[f.id] = true
	check(not SimAI.is_dim_target(w, h, f), "被照亮的不算暗处目标")
	var P: Dictionary = w.ai_profile("blue")
	check(float(P.get("dimReactK", 1.0)) > 1.0 and float(P.get("dimAimK", 1.0)) > 1.0, "难度里要有暗处的反应 / 瞄准惩罚")
	w.dispose()


func test_difficulty_scales_dark_perception() -> void:
	var D: Dictionary = Data.load_json("difficulty").levels
	var last := 0.0
	for lv in ["easy", "normal", "hard", "hell"]:
		var s := float(D[lv].dimSee)
		check(s > last, "难度越高察觉暗处敌人越远：" + lv)
		last = s
