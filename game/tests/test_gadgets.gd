extends "res://tests/test_case.gd"
## 批次 2 战术道具：13 种道具逐个使用，检查效果。


func _solo(gadget: String) -> SimWorld:
	var w := make_world("full", 9, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	var h := w.hams[0]
	h.gadget = {"id": gadget, "lvl": 1, "cd": 0.0}
	h.x = 2520.0
	h.y = 1548.0
	h.aim = 0.0
	h.inp.aim = 0.0
	h.inp.has_aim_point = true
	h.inp.aim_x = h.x + 260.0
	h.inp.aim_y = h.y
	for e in w.mobs:
		e.dead = true
	w.mobs.clear()
	return w


func _foe(w: SimWorld, x: float, y: float, ctl: String = "player") -> SimHamster:
	var f := w._make_ham("red", ctl, "靶子", 9, "gold")
	f.x = x
	f.y = y
	f.px = x
	f.py = y
	return f


func _use(w: SimWorld) -> void:
	w.hams[0].inp.gadget = true
	w.step(1.0 / 60.0)


func _step(w: SimWorld, sec: float) -> void:
	for i in int(sec * 60.0):
		w.step(1.0 / 60.0)


func test_frag() -> void:
	var w := _solo("frag")
	var m := w.spawn_minion("red", "mid")
	m.x = 2780.0
	m.y = 1548.0
	m.stun = 99.0
	_use(w)
	eq(w.lobs.size(), 1, "扔出手雷")
	_step(w, 2.0)
	check(m.dead or m.hp < m.max_hp, "手雷炸到小兵")


func test_molotov_fire() -> void:
	var w := _solo("molotov")
	_use(w)
	_step(w, 1.5)
	check(w.fires.any(func(f): return f.src == "molotov"), "燃烧瓶落地起火")


func test_flash_blinds_ai() -> void:
	var w := _solo("flash")
	var f := _foe(w, 2800.0, 1548.0, "ai")
	f.stun_t = 99.0
	_use(w)
	_step(w, 1.4)
	check(f.blind_t > 0.0, "闪光致盲 AI")


func test_mine_triggers() -> void:
	var w := _solo("mine")
	_use(w)
	eq(w.mines.size(), 1, "放下地雷")
	var f := _foe(w, 2700.0, 1548.0)
	_step(w, 1.0)
	f.x = 2525.0
	f.y = 1548.0
	_step(w, 0.2)
	eq(w.mines.size(), 0, "敌人踩雷爆炸")
	check(f.hp < f.max_hp or not f.alive, "地雷伤害")


func test_sentry_fires() -> void:
	var w := _solo("sentry")
	_use(w)
	var s: Array = w.structs.filter(func(q): return q.kind == "sentry")
	eq(s.size(), 1, "放下哨戒炮")
	var m := w.spawn_minion("red", "mid")
	m.x = 2700.0
	m.y = 1548.0
	m.stun = 99.0
	_step(w, 1.5)
	check(m.hp < m.max_hp, "哨戒炮打小兵")
	_step(w, 16.0)
	eq(w.structs.filter(func(q): return q.kind == "sentry").size(), 0, "到时间自动消失")


func test_eshield_absorbs() -> void:
	var w := _solo("eshield")
	var h := w.hams[0]
	_use(w)
	check(h.eshield > 0.0, "获得护盾")
	var hp0 := h.hp
	w.deal_dmg(h, 30.0, {"team": "red", "owner": null, "x": h.x, "y": h.y})
	eq(h.hp, hp0, "护盾吸收伤害")


func test_smoke_blocks_vision() -> void:
	var w := _solo("smoke")
	var h := w.hams[0]
	var f := _foe(w, 2900.0, 1548.0)
	SimVision.compute(w)
	check(w.vis.blue.has(f.id), "没烟时手电照得到")
	_use(w)
	_step(w, 1.2)
	check(w.smokes.size() > 0, "烟雾生成")
	SimVision.compute(w)
	check(not w.vis.blue.has(f.id), "烟雾挡住视线")


func test_flare_reveals() -> void:
	var w := _solo("flare")
	var h := w.hams[0]
	h.inp.aim_x = h.x
	h.inp.aim_y = h.y + 300.0
	h.aim = PI   # 手电朝后
	h.inp.aim = PI
	var f := _foe(w, h.x + 20.0, h.y + 900.0)
	_use(w)
	_step(w, 1.0)
	check(w.flares.size() > 0, "照明弹升空")
	if w.flares.is_empty():
		return
	var fl: Dictionary = w.flares[0]
	# 找一个照明弹看得见、但仓鼠自己看不见的位置
	for a in range(0, 360, 15):
		var x := float(fl.x) + cos(deg_to_rad(a)) * 380.0
		var y := float(fl.y) + sin(deg_to_rad(a)) * 380.0
		if w.map.has_los(fl.x, fl.y, x, y) and not w.map.overlaps_solid(x, y, f.r) and Vector2(x - h.x, y - h.y).length() > 300.0:
			f.x = x
			f.y = y
			break
	SimVision.compute(w)
	check(w.vis.blue.has(f.id), "照明弹照亮敌人")
	w.flares.clear()
	SimVision.compute(w)
	check(not w.vis.blue.has(f.id), "没有照明弹就看不见")


func test_decoy() -> void:
	var w := _solo("decoy")
	_use(w)
	eq(w.decoys.size(), 1, "放出诱饵")
	var d: SimDecoy = w.decoys[0]
	w.deal_dmg(d, 999.0, {"team": "red", "owner": null, "x": d.x, "y": d.y})
	w.step(1.0 / 60.0)
	eq(w.decoys.size(), 0, "诱饵被打爆")


func test_jetpack() -> void:
	var w := _solo("jetpack")
	var h := w.hams[0]
	var x0 := h.x
	_use(w)
	check(not h.air.is_empty(), "起飞")
	_step(w, 0.8)
	check(h.air.is_empty() and h.x > x0 + 100.0, "飞过去落地")


func test_medkit_heals() -> void:
	var w := _solo("medkit")
	var h := w.hams[0]
	h.hp = 30.0
	_use(w)
	_step(w, 3.1)
	check(h.hp > 60.0, "急救包回血（%.1f）" % h.hp)


func test_freeze() -> void:
	var w := _solo("freeze")
	var f := _foe(w, 2780.0, 1548.0)
	_use(w)
	_step(w, 1.3)
	check(f.stun_t > 0.0 or f.frozen_until > w.t, "冰冻弹定住敌人")


func test_beacon_teleport() -> void:
	var w := _solo("beacon")
	var h := w.hams[0]
	_use(w)
	check(not h.beacon.is_empty(), "插下信标")
	h.x += 400.0
	h.gadget.cd = 0.0
	_use(w)
	near(h.x, 2520.0, 2.0, "传送回信标")


func test_gadget_levels_cd() -> void:
	var w := _solo("frag")
	var h := w.hams[0]
	h.gadget.lvl = 4
	_use(w)
	near(float(h.gadget.cd), 7.0 * 0.55, 0.01, "4 级道具冷却 -45%")
