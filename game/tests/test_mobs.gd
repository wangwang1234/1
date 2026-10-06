extends "res://tests/test_case.gd"
## 批次 2 野区、鼠王、宠物、天赋。


func _step(w: SimWorld, sec: float) -> void:
	for i in int(sec * 60.0):
		w.step(1.0 / 60.0)
		w.events.clear()


func test_camps_spawn_full_map() -> void:
	var w := make_world("full", 3, 0, 0)
	eq(w.camps.size(), 8, "全图 8 个营地（蟑螂 4 + 枪手 4）")
	var roach := w.mobs.filter(func(e): return e.kind == "roach").size()
	var rat := w.mobs.filter(func(e): return e.kind == "rat").size()
	eq(roach, 24, "蟑螂 4 窝 × 6")
	eq(rat, 12, "枪手 4 伙 × 3")
	check(w.map.boss_pos != Vector2.ZERO, "鼠王出生点")


func test_mobs_aggro_and_attack() -> void:
	var w := make_world("full", 4, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	var h := w.hams[0]
	var c: Dictionary = w.camps.filter(func(q): return q.type == "roach")[0]
	h.x = float(c.x) + 120.0
	h.y = float(c.y)
	var hp0 := h.hp
	_step(w, 3.0)
	check(w.mobs.any(func(e): return e.target == h), "蟑螂发现并追击")
	check(h.hp < hp0, "被咬掉血")


func test_camp_clear_and_respawn() -> void:
	var w := make_world("full", 6, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	var h := w.hams[0]
	var c: Dictionary = w.camps.filter(func(q): return q.type == "rat")[0]
	var xp0 := h.xp + h.lvl * 1000
	for e in w.mobs.duplicate():
		if e.camp == c:
			w.deal_dmg(e, 9999.0, {"team": "blue", "owner": h, "x": e.x, "y": e.y})
	w.step(1.0 / 60.0)
	eq(int(c.alive), 0, "清空营地")
	check(h.xp + h.lvl * 1000 > xp0, "打野获得经验")
	check(float(c.resp) > w.t, "营地进入重生倒计时")
	_step(w, 71.0)
	eq(int(c.alive), 3, "70 秒后重生")


func test_boss_spawn_and_crown() -> void:
	var w := make_world("full", 8, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}, {"team": "blue", "ctl": "player", "name": "队友"}])
	var h := w.hams[0]
	w.t = float(Data.progression().bossFirst) - 0.1
	_step(w, 0.2)
	check(w.boss != null, "鼠王按时出现")
	var b := w.boss
	eq(b.max_hp, 2600.0, "鼠王血量")
	for a in [PI * 0.5, PI, 0.0, -PI * 0.5, PI * 0.75, PI * 0.25]:
		h.x = b.x + cos(a) * 220.0
		h.y = b.y + sin(a) * 220.0
		if w.map.has_los(b.x, b.y, h.x, h.y) and not w.map.overlaps_solid(h.x, h.y, h.r):
			break
	_step(w, 4.0)
	check(w.bullets.any(func(q): return q.kind == "orb") or h.hp < h.max_hp, "鼠王放弹幕")
	w.deal_dmg(b, 99999.0, {"team": "blue", "owner": h, "x": b.x, "y": b.y})
	check(b.dead, "鼠王被击败")
	for q in w.hams:
		check(q.crown_t > 0.0, "%s 获得王冠" % q.name)
	near(float(w.hams[1].st.dmg) / (1.0 + 0.03 * (w.hams[1].lvl - 1)), 1.25, 0.01, "王冠伤害 +25%")
	check(w.boss_next > w.t + 100.0, "鼠王 150 秒后重生")


func test_pets() -> void:
	var w := make_world("full", 10, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	var h := w.hams[0]
	h.x = 2520.0
	h.y = 1548.0
	for e in w.mobs:
		e.dead = true
	for type in ["chick", "firefly", "hedgehog"]:
		h.choices = [{"t": "pet", "id": type}]
		h.pending = 1
		SimCards.apply(w, h, 0)
	eq(h.pet_list.size(), 3, "三只宠物")
	h.choices = [{"t": "pet", "id": "chick"}]
	h.pending = 1
	SimCards.apply(w, h, 0)
	eq(h.pet_list.size(), 3, "重复选同一宠物是升级")
	eq(h.pet_list.filter(func(p): return p.type == "chick")[0].lvl, 2, "小鸡升到 2 级")
	var m := w.spawn_minion("red", "mid")
	m.x = h.x + 150.0
	m.y = h.y
	m.hp = 9999.0
	m.max_hp = 9999.0
	m.stun = 99.0
	_step(w, 4.0)
	check(m.hp < 9999.0, "宠物攻击敌人")


func test_talent_squad_and_detonate() -> void:
	var w := make_world("full", 12, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	var h := w.hams[0]
	h.tal["squad"] = true
	h.squad_t = 0.01
	var n0 := w.minions.size()
	w.step(1.0 / 60.0)
	eq(w.minions.size(), n0 + 3, "小队天赋召唤 3 个小兵")
	h.tal["detonate"] = true
	var m := w.spawn_minion("red", "mid")
	m.x = h.x + 300.0
	m.y = h.y
	var m2 := w.spawn_minion("red", "mid")
	m2.x = h.x + 330.0
	m2.y = h.y
	w.deal_dmg(m, 9999.0, {"team": "blue", "owner": h, "x": m.x, "y": m.y})
	_step(w, 0.2)
	check(m2.hp < m2.max_hp, "殉爆炸到旁边的敌人")


func test_full_match_5min_everything() -> void:
	## 全图 5v5 AI 打 5 分钟：野区、鼠王、道具、宠物都会出现，不报错
	var w := make_world("full", 99, 5, 5)
	var t0 := Time.get_ticks_msec()
	var seen := {}
	for i in 300 * 60:
		w.step(1.0 / 60.0)
		for ev in w.events:
			seen[ev.t] = int(seen.get(ev.t, 0)) + 1
		w.events.clear()
		if w.over:
			break
	var lv := 0
	var pets := 0
	var gads := {}
	for h in w.hams:
		lv = maxi(lv, h.lvl)
		pets += h.pet_list.size()
		gads[h.gadget.id] = true
	check(seen.has("boss_spawn"), "鼠王出现过")
	check(seen.has("gadget") or seen.has("throw"), "用过道具")
	check(lv >= 8, "有人升到 8 级以上（%d）" % lv)
	note = "full 5v5 5 分钟：%d ms，最高 Lv%d，宠物 %d，道具种类 %d，事件种类 %d，结束=%s" % [Time.get_ticks_msec() - t0, lv, pets, gads.size(), seen.size(), str(w.over)]
	w.dispose()
