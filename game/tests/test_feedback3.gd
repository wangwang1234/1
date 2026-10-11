extends "res://tests/test_case.gd"
## 导演反馈第三轮（2026-10-11）：金瓜子、小兵都掉经验、前期升级更快、左键按住连续射击、宠物加强、望远镜强化。


func _clear(w: SimWorld) -> void:
	for e in w.mobs:
		e.dead = true
	for m in w.minions:
		m.dead = true
	w.items.clear()


func test_gold_seeds_drop_and_give_lots_of_xp() -> void:
	var w := make_world("full", 21, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	_clear(w)
	var G: Dictionary = w.R.items.gold
	w.drop_gold_chance(2520.0, 1548.0, "boss")
	var golds := w.items.filter(func(it): return it.gold)
	eq(golds.size(), int(G.boss), "鼠王固定掉金瓜子")
	check(float(G.xp) >= 4.0 * float(w.R.minion.drop.gemXp), "金瓜子经验要远多于普通瓜子")
	var h := w.hams[0]
	h.x = 2520.0
	h.y = 1548.0
	var lv0 := h.lvl
	var xp0 := h.xp
	for i in 120:
		w.step(1.0 / 60.0)
	check(w.items.filter(func(it): return it.gold).is_empty(), "站在旁边会被吸过来吃掉")
	check(h.lvl > lv0 or h.xp > xp0 + float(G.xp), "吃到金瓜子拿到大量经验")
	w.dispose()


func test_minions_drop_seeds_even_without_hamster_killer() -> void:
	var w := make_world("full", 22, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	_clear(w)
	var m := w.spawn_minion("red", w.map.lanes.keys()[0])
	m.x = 2000.0
	m.y = 1548.0
	w.deal_dmg(m, 99999.0, {"team": "blue", "owner": null, "x": m.x, "y": m.y})
	check(w.items.filter(func(it): return it.type == "gem").size() >= 1, "被小兵 / 炮台打死的小兵也掉瓜子")
	w.dispose()


func test_early_levels_are_faster() -> void:
	var need: Array = Data.progression().xpNeed
	check(float(need[0]) <= 25.0, "升到 2 级只要很少经验（%s）" % str(need[0]))
	check(float(need[4]) < 130.0, "前 5 级都打折")
	eq(int(need[9]), 414, "第 10 级起和原来一样")
	for i in range(1, need.size()):
		check(float(need[i]) > float(need[i - 1]), "经验需求要递增")


func test_holding_fire_keeps_shooting() -> void:
	var w := make_world("slice", 23, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	_clear(w)
	var h := w.hams[0]
	eq(h.weapon_id, "pistol", "前提：手枪")
	h.inp.fire = true
	h.inp.aim = 0.0
	var shots := 0
	var last_ammo := h.ammo
	for i in 120:
		h.inp.fire = true
		w.step(1.0 / 60.0)
		if h.ammo < last_ammo:
			shots += last_ammo - h.ammo
		last_ammo = h.ammo
	check(shots >= 6, "按住左键 2 秒，手枪要连续开好几枪（实际 %d）" % shots)
	w.dispose()


func test_pets_are_stronger_and_firefly_chains() -> void:
	eq(int(Data.rule("pets.maxLevel", 0)), 5, "宠物最多 5 级")
	var F: Dictionary = Data.rule("pets.firefly", {})
	check(float(F.dmg) + float(F.dmgPer) >= 15.0, "萤火虫 1 级伤害要比原来高（原来 8）")
	var w := make_world("full", 24, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	_clear(w)
	var h := w.hams[0]
	h.x = 2520.0
	h.y = 1548.0
	var p: SimPet = SimMobs.make_pet(w, "firefly", h)
	p.lvl = int(F.chainFrom)
	var a := w.spawn_minion("red", w.map.lanes.keys()[0])
	var b := w.spawn_minion("red", w.map.lanes.keys()[0])
	a.x = h.x + 80.0
	a.y = h.y
	b.x = h.x + 160.0
	b.y = h.y
	for m: SimMinion in [a, b]:
		m.stun = 99.0
		m.hp = 9999.0
		m.max_hp = 9999.0
	var zaps := 0
	w.events.clear()
	for i in 90:
		w.step(1.0 / 60.0)
		for ev in w.events:
			if ev.t == "zap" and ev.get("pet", -1) == p.id:
				zaps += 1
		w.events.clear()
	check(a.hp < 9999.0 and b.hp < 9999.0, "高等级萤火虫的电击会跳到第二个敌人")
	check(zaps >= 2, "有连锁电弧")
	w.dispose()


func test_binoculars_widen_view_and_dark_sight() -> void:
	var A: Dictionary = Data.abilities()
	check(A.has("binoc"), "有望远镜强化")
	check((Data.rule("scope.abilities", []) as Array).has("binoc"), "望远镜在卡池里")
	var w := make_world("full", 25, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	_clear(w)
	var h := w.hams[0]
	h.x = 2520.0
	h.y = 1548.0
	h.aim = PI
	h.inp.aim = PI
	var rr := float(w.R.vision.dim.range)
	var f := w._make_ham("red", "player", "靶子", 9, "gold")
	var spot := Vector2.INF
	for a in range(-80, 81, 5):
		var q := Vector2(h.x, h.y) + Vector2.RIGHT.rotated(deg_to_rad(a)) * (rr + 60.0)
		if not w.map.overlaps_solid(q.x, q.y, 24.0) and w.map.has_los(h.x, h.y, q.x, q.y):
			spot = q
			break
	if not check(spot != Vector2.INF, "要找得到视线通的远处位置"):
		return
	f.x = spot.x
	f.y = spot.y
	SimVision.compute(w)
	check(not w.seen.blue.has(f.id), "没有望远镜时太远看不到")
	h.ab["binoc"] = 3
	SimHamsterLogic.calc_stats(h)
	check(float(h.st.viewK) > 1.3, "3 级望远镜画面范围明显变大")
	SimVision.compute(w)
	check(w.seen.blue.has(f.id), "有望远镜就能看到更远的暗处敌人")
	w.dispose()
