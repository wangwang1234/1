extends "res://tests/test_case.gd"
## 导演反馈第一轮：选卡时能射击、鼠窝快速回血、小怪掉瓜子 / 奶酪、手动瞄准辅助、AI 难度分级和新战术、射程收短。


func _step(w: SimWorld, sec: float) -> void:
	for i in int(sec * 60.0):
		w.step(1.0 / 60.0)
		w.events.clear()


func _player_world(seed_: int = 5, ai_blue: int = 0, ai_red: int = 0, diff: String = "normal") -> SimWorld:
	var w := SimWorld.new()
	w.setup({"mode": "slice", "seed": seed_, "players": [{"team": "blue", "ctl": "player", "name": "测"}],
		"ai": {"blue": ai_blue, "red": ai_red}, "difficulty": diff})
	return w


func _open_spot(w: SimWorld, h: SimHamster, dist: float) -> Vector2:
	## 找一处 h 正右方 dist 远、中间没有墙的位置（从鼠窝往中路方向找）
	var b: Vector2 = w.map.base_pos.blue
	for ox in range(500, 3000, 60):
		for oy in [0.0, -120.0, 120.0, -240.0, 240.0, -360.0, 360.0]:
			var x := b.x + float(ox)
			var y := b.y + float(oy)
			if w.map.has_los(x, y, x + dist, y) and w.map.has_los(x, y - 20.0, x + dist, y - 20.0):
				h.x = x
				h.y = y
				return Vector2(x + dist, y)
	return Vector2(h.x + dist, h.y)


func test_fire_while_choosing_cards() -> void:
	var w := _player_world()
	var h := w.hams[0]
	SimHamsterLogic.give_xp(w, h, 200.0)
	check(not h.choices.is_empty(), "升级后出现三选一")
	h.inp.fire = true
	h.inp.aim = 0.0
	var n0 := h.shot_n
	_step(w, 0.5)
	check(h.shot_n > n0, "三选一还没选的时候照样能开火（开了 %d 枪）" % (h.shot_n - n0))
	check(not h.choices.is_empty(), "开火不会误选卡")


func test_base_heal_ticks_fast() -> void:
	var w := _player_world()
	var h := w.hams[0]
	h.hp = h.max_hp * 0.1
	var hp0 := h.hp
	_step(w, 1.0)
	var gain := (h.hp - hp0) / h.max_hp
	# 一进范围立刻回第一跳，之后每 0.3 秒一跳：1 秒内 4 跳 × 7.5% = 30%
	near(gain, 0.30, 0.02, "鼠窝里 1 秒回 4 跳（每秒 25%，每 0.3 秒一次）")
	_step(w, 3.0)
	near(h.hp, h.max_hp, 0.01, "几秒内回满")


func test_minion_and_mob_drops() -> void:
	var w := _player_world(8)
	var h := w.hams[0]
	var gems := func() -> int: return w.items.filter(func(it): return it.type == "gem").size()
	var m := w.spawn_minion("red", "mid")
	var g0: int = gems.call()
	w.deal_dmg(m, 9999.0, {"team": "blue", "owner": h, "x": m.x, "y": m.y})
	var g1: int = gems.call()
	check(g1 - g0 >= 1, "仓鼠打死的小兵掉瓜子（掉了 %d 颗）" % (g1 - g0))
	var m2 := w.spawn_minion("red", "mid")
	w.deal_dmg(m2, 9999.0, {"team": "blue", "x": m2.x, "y": m2.y})
	eq(gems.call(), g1, "小兵互殴（没有仓鼠参与）不掉瓜子")
	# 多打几只，奶酪也会掉
	var cheese := 0
	for i in 80:
		var mm := w.spawn_minion("red", "mid")
		w.deal_dmg(mm, 9999.0, {"team": "blue", "owner": h, "x": mm.x, "y": mm.y})
	cheese = w.items.filter(func(it): return it.type == "cheese").size()
	check(cheese >= 1, "打小兵偶尔掉奶酪（80 只掉了 %d 块）" % cheese)
	var wf := make_world("full", 9, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	var hf := wf.hams[0]
	var roach: SimMob = wf.mobs.filter(func(e): return e.kind == "roach")[0]
	var n0 := wf.items.size()
	wf.deal_dmg(roach, 9999.0, {"team": "blue", "owner": hf, "x": roach.x, "y": roach.y})
	check(wf.items.size() > n0, "蟑螂必掉瓜子")


func test_cheese_kept_at_full_hp() -> void:
	var w := _player_world()
	var h := w.hams[0]
	var c := w._add_item("cheese", h.x, h.y, 0.0)
	c.z = 0.0
	c.vx = 0.0
	c.vy = 0.0
	c.vz = 0.0
	_step(w, 1.0)
	check(not c.dead, "满血走过奶酪不会吃掉")
	h.hp = h.max_hp * 0.5
	h.x = c.x
	h.y = c.y
	for i in 30:
		h.x = c.x
		h.y = c.y
		w.step(1.0 / 60.0)
		w.events.clear()
	check(c.dead, "掉血后能吃")


func test_aim_assist() -> void:
	var w := _player_world(11, 0, 1)
	var h := w.hams[0]
	var e: SimHamster = w.hams[1]
	h.weapon_id = "ak47"
	var p := _open_spot(w, h, 300.0)
	e.x = p.x
	e.y = p.y
	w.vis.blue[e.id] = true
	var a0 := SimWeapons.aim_assist(w, h, 0.1, 1.0)
	check(a0 < 0.1 and a0 > 0.0, "准星偏 0.1 弧度时往目标拉回一些（%.3f）" % a0)
	near(SimWeapons.aim_assist(w, h, 0.6, 1.0), 0.6, 0.0001, "偏太多不吸附")
	near(SimWeapons.aim_assist(w, h, 0.1, 0.0), 0.1, 0.0001, "关掉时不吸附")
	check(SimWeapons.aim_assist(w, h, 0.1, 1.4) < a0, "强档拉得更多")
	w.vis.blue.erase(e.id)
	near(SimWeapons.aim_assist(w, h, 0.1, 1.0), 0.1, 0.0001, "看不见的敌人不吸附")


func test_difficulty_profiles() -> void:
	var w := _player_world(12, 4, 5, "easy")
	for h in w.hams:
		if h.ctl != "ai":
			continue
		eq(String(h.ai.prof.id), "easy" if h.team == "red" else "normal", "%s %s 的难度档" % [h.team, h.name])
	var red: SimHamster = w.hams.filter(func(q): return q.team == "red")[0]
	var blue: SimHamster = w.hams.filter(func(q): return q.team == "blue" and q.ctl == "ai")[0]
	check(float(red.st.dmg) < float(blue.st.dmg), "简单难度的敌人伤害更低")
	var wh := _player_world(12, 4, 5, "hell")
	for h in wh.hams:
		if h.ctl == "ai":
			eq(String(h.ai.prof.id), "hell" if h.team == "red" else "hard", "地狱难度：敌人 hell、队友 hard")
	var wa := make_world("slice", 12, 3, 3)
	for h in wa.hams:
		eq(String(h.ai.prof.id), "normal", "纯 AI 对局默认普通")
	var wb := SimWorld.new()
	wb.setup({"mode": "slice", "seed": 1, "players": [], "ai": {"blue": 1, "red": 1}, "difficulty": "不存在"})
	eq(wb.difficulty, "normal", "未知难度回落到默认")


func test_difficulty_changes_outcome() -> void:
	## 同一张图 3 对 3，蓝队地狱、红队简单：蓝队应该明显更能打
	var w := make_world("slice", 41, 3, 3)
	var L: Dictionary = Data.difficulty().levels
	for h in w.hams:
		h.ai.prof = (L.hell if h.team == "blue" else L.easy).duplicate()
		SimHamsterLogic.calc_stats(h)
	run(w, 240.0)
	var k := {"blue": 0, "red": 0}
	for h in w.hams:
		k[h.team] += h.kills
	check(int(k.blue) > int(k.red), "地狱队击杀多于简单队（%d : %d）" % [k.blue, k.red])
	note = "地狱 vs 简单 4 分钟击杀 %d : %d%s" % [k.blue, k.red, "，%s 获胜" % w.winner if w.over else ""]


func test_ai_dodges_bullets() -> void:
	var w := make_world("slice", 13, 1, 1)
	var h: SimHamster = w.hams.filter(func(q): return q.team == "blue")[0]
	h.ai.prof = (Data.difficulty().levels.hell as Dictionary).duplicate()
	h.ai.prof.dodge = 1.0
	var b := SimBullet.new()
	b.team = "red"
	b.x = h.x + 200.0
	b.y = h.y
	b.vx = -900.0
	b.vy = 0.0
	w.bullets.append(b)
	h.ai.dodge_t = 0.0
	SimAI._dodge(w, h, h.ai.prof, 1.0 / 60.0)
	check(h.ai.dodge_left > 0.0, "看到子弹飞来会躲")
	check(absf(h.ai.dodge_y) > 0.9, "往弹道侧面闪")
	var h2: SimHamster = w.hams.filter(func(q): return q.team == "red")[0]
	h2.ai.prof = (Data.difficulty().levels.easy as Dictionary).duplicate()
	h2.ai.dodge_t = 0.0
	var b2 := SimBullet.new()
	b2.team = "blue"
	b2.x = h2.x - 200.0
	b2.y = h2.y
	b2.vx = 900.0
	w.bullets.append(b2)
	SimAI._dodge(w, h2, h2.ai.prof, 1.0 / 60.0)
	eq(h2.ai.dodge_left, 0.0, "简单难度不躲子弹")


func test_ai_tower_safe() -> void:
	var w := make_world("full", 14, 1, 0)
	var h: SimHamster = w.hams[0]
	var tur: SimStructure = w.structs.filter(func(s): return s.team == "red" and s.kind == "turret")[0]
	h.x = tur.x - tur.range_ * 0.7
	h.y = tur.y
	w.minions.clear()
	var away := SimAI._tower_avoid(w, h, null)
	check(away.x < -0.1, "没有小兵掩护时从敌方炮台射程里往外退")
	eq(SimAI._tower_avoid(w, h, tur), Vector2.ZERO, "目标就是这座炮台时不退")
	var m := w.spawn_minion("blue", "mid")
	m.x = tur.x - 100.0
	m.y = tur.y
	eq(SimAI._tower_avoid(w, h, null), Vector2.ZERO, "有己方小兵扛炮台时可以进")


func test_ranges_fit_screen() -> void:
	## 画面横向约 720（7.2 米）：普通枪的射程不超过 620，狙击类不超过 900
	var long := ["sniper", "amr", "rail"]
	for id: String in Data.weapons():
		var W: Dictionary = Data.weapon(id)
		if not W.has("range"):
			continue
		var lim := 900.0 if long.has(id) else 620.0
		check(float(W.range) <= lim, "%s 射程 %d 不超过 %d" % [id, int(W.range), int(lim)])


func test_ai_full_match_each_difficulty() -> void:
	## 每档难度（玩家位置也交给 AI）跑 3 分钟完整地图，不报错、AI 会开火
	for d: String in Data.difficulty().order:
		var w := SimWorld.new()
		w.setup({"mode": "full", "seed": 50, "players": [], "ai": {"blue": 5, "red": 5}, "difficulty": d})
		run(w, 180.0)
		var shots := 0
		for h in w.hams:
			shots += h.shot_n
		check(shots > 100, "%s 难度 AI 正常交火（%d 枪）" % [d, shots])
		check(w.errors == 0, "%s 难度无逻辑错误" % d)
