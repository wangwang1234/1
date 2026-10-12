extends "res://tests/test_case.gd"
## 道具 Q / E 双槽（2026-10-12）：开局装备、开局池选择、换道具只替换所属槽、通用升级（冷却缩短 / 携带上限）与保留、
## 充能、13 个新道具的效果、部署物阵营 / 耐久 / 可被摧毁、AI 两个槽都会用、联机快照同步。


func _solo(gadget: String = "") -> SimWorld:
	var w := make_world("full", 21, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	var h := w.hams[0]
	if not gadget.is_empty():
		h.gad[_slot(gadget)] = SimGadgets.new_slot(gadget, h)
	h.x = 2520.0
	h.y = 1548.0
	h.px = h.x
	h.py = h.y
	h.aim = 0.0
	h.inp.aim = 0.0
	h.inp.has_aim_point = true
	h.inp.aim_x = h.x + 260.0
	h.inp.aim_y = h.y
	for e in w.mobs:
		e.dead = true
	w.mobs.clear()
	return w


func _slot(id: String) -> String:
	return String(Data.gadget(id).slot)


func _foe(w: SimWorld, x: float, y: float, ctl: String = "player") -> SimHamster:
	var f := w._make_ham("red", ctl, "靶子", 9, "gold")
	f.x = x
	f.y = y
	f.px = x
	f.py = y
	return f


func _use(w: SimWorld, id: String) -> void:
	var h := w.hams[0]
	if _slot(id) == "q":
		h.inp.gadget = true
	else:
		h.inp.gadget2 = true
	w.step(1.0 / 60.0)


func _step(w: SimWorld, sec: float) -> void:
	for i in int(sec * 60.0):
		w.step(1.0 / 60.0)


func _deps(w: SimWorld, id: String) -> Array:
	return w.structs.filter(func(s): return s.kind == "dep" and s.dep == id and not s.dead)


# ---------------------------------------------------------------------------
# 槽位与卡
# ---------------------------------------------------------------------------

func test_data_pools() -> void:
	## 规格里的分配：Q 开局池破片手雷，升级池 9 个；E 开局池医疗包，升级池 6 个；每个道具都有名字、槽、冷却、上限、效果、AI 条件
	eq(Data.gadget_pool("q", "start"), ["frag"], "Q 开局池")
	eq(Data.gadget_pool("e", "start"), ["medkit"], "E 开局池")
	var qu := Data.gadget_pool("q", "upgrade")
	var eu := Data.gadget_pool("e", "upgrade")
	for id in ["mine", "trap", "cam", "cover", "regen", "holo", "guardgun", "signal", "reflector"]:
		check(qu.has(id), "Q 升级池有 %s" % id)
	for id in ["adren", "bubble", "jetpack", "warp", "goggles", "sonar"]:
		check(eu.has(id), "E 升级池有 %s" % id)
	eq(qu.size(), 9, "Q 升级池 9 个")
	eq(eu.size(), 6, "E 升级池 6 个")
	for id in Data.gadget_ids():
		var G := Data.gadget(id)
		for k in ["name", "desc", "slot", "pool", "cd", "charges", "fx", "ai"]:
			check(G.has(k), "%s 有 %s" % [id, k])
		check(String(G.slot) in ["q", "e"], "%s 的槽是 q / e" % id)
		check((G.ai as Dictionary).has("when") and String(G.ai.cat) in ["save", "fight", "intel"], "%s 有 AI 条件和类别" % id)


func test_start_loadout_and_choice() -> void:
	var w := _solo()
	var h := w.hams[0]
	eq(String(h.gad.q.id), "frag", "开局 Q = 破片手雷")
	eq(String(h.gad.e.id), "medkit", "开局 E = 医疗包")
	eq(int(h.gad.q.ch), 0, "开局先充能")
	_step(w, 2.1)
	eq(int(h.gad.q.ch), 1, "2 秒后能用")
	# 开局池选择：只认开局池里的；不在池里的回到默认
	var w2 := make_world("slice", 22, 0, 0, [{"team": "blue", "ctl": "player", "name": "甲", "gq": "frag", "ge": "medkit"}, {"team": "red", "ctl": "player", "name": "乙", "gq": "cover", "ge": "nope"}])
	eq(String(w2.hams[0].gad.q.id), "frag", "选了开局池里的")
	eq(String(w2.hams[1].gad.q.id), "frag", "升级池道具不能开局带")
	eq(String(w2.hams[1].gad.e.id), "medkit", "无效 id 用默认")


func test_new_gadget_card_replaces_only_its_slot() -> void:
	var w := _solo()
	var h := w.hams[0]
	h.choices = [{"t": "gad", "id": "cover"}]
	h.pending = 1
	var L := SimCards.label(h, h.choices[0])
	eq(String(L.type), "战术道具", "卡面标明战术道具")
	check(not String(L.badge).contains("Lv") and not String(L.desc).contains("Lv"), "卡面没有 Lv")
	SimCards.apply(w, h, 0)
	eq(String(h.gad.q.id), "cover", "Q 换成掩体")
	eq(String(h.gad.e.id), "medkit", "E 不变")
	h.choices = [{"t": "gad", "id": "sonar"}]
	h.pending = 1
	eq(String(SimCards.label(h, h.choices[0]).type), "强化道具", "卡面标明强化道具")
	SimCards.apply(w, h, 0)
	eq(String(h.gad.q.id), "cover", "Q 不变")
	eq(String(h.gad.e.id), "sonar", "E 换成声呐")


func test_universal_upgrades_stack_cap_and_persist() -> void:
	var w := _solo("frag")
	var h := w.hams[0]
	for i in 5:
		h.choices = [{"t": "gup", "id": "gcdx"}, {"t": "gup", "id": "gcap"}]
		h.pending = 1
		SimCards.apply(w, h, 0)
		h.choices = [{"t": "gup", "id": "gcdx"}, {"t": "gup", "id": "gcap"}]
		h.pending = 1
		SimCards.apply(w, h, 1)
	eq(int(h.gup.gcdx), 3, "冷却缩短最多 3 张")
	eq(int(h.gup.gcap), 3, "携带上限最多 +3")
	near(SimGadgets.cd_mul(h), 0.55, 0.001, "冷却最多 −45%")
	eq(SimGadgets.max_charges(h, "frag"), 4, "手雷上限 1 + 3")
	eq(SimGadgets.max_charges(h, "medkit"), 4, "E 也 +3（一张卡同时作用于 Q 和 E）")
	# 满了以后不再出这两种卡
	for i in 100:
		h.choices = []
		SimCards.roll(w, h)
		for c in h.choices:
			check(c.t != "gup", "满了不再出通用升级卡")
	# 换道具后升级保留
	SimGadgets.equip(w, h, "trap")
	SimGadgets.equip(w, h, "adren")
	eq(int(h.gup.gcdx), 3, "换道具后冷却缩短保留")
	eq(SimGadgets.max_charges(h, "trap"), int(Data.gadget("trap").charges) + 3, "换上的新道具也吃携带上限")
	eq(int(h.gad.q.ch), SimGadgets.max_charges(h, "trap"), "换上新道具充满")
	near(SimGadgets.cd_full(h, "adren"), float(Data.gadget("adren").cd) * 0.55, 0.01, "新道具也吃冷却缩短")


func test_charges_consume_and_recharge() -> void:
	var w := _solo("frag")
	var h := w.hams[0]
	h.gup = {"gcap": 1}
	h.gad.q = SimGadgets.new_slot("frag", h)
	eq(int(h.gad.q.ch), 2, "上限 +1：两格")
	_use(w, "frag")
	_use(w, "frag")
	eq(int(h.gad.q.ch), 0, "连扔两颗")
	eq(w.lobs.size(), 2, "两颗手雷在飞")
	_use(w, "frag")
	eq(w.lobs.size(), 2, "没充能扔不出")
	_step(w, 7.1)
	eq(int(h.gad.q.ch), 1, "一个冷却回一格")
	_step(w, 7.1)
	eq(int(h.gad.q.ch), 2, "再一个冷却回满")


func test_card_roll_four_with_gadget_types() -> void:
	var w := _solo()
	var h := w.hams[0]
	h.weapon_id = "ak47"
	var seen := {}
	for i in 600:
		h.choices = []
		SimCards.roll(w, h)
		eq(h.choices.size(), 4, "每次 4 张")
		for c in h.choices:
			seen[c.t] = int(seen.get(c.t, 0)) + 1
			if c.t == "gad":
				var slot := _slot(c.id)
				check(c.id != String(h.gad[slot].id), "不出身上已有的道具")
		if not failures.is_empty():
			return
	for t in ["evo", "abil", "gad", "gup", "pet", "weap"]:
		check(seen.has(t), "出现过 %s 卡" % t)
	note = "600 次抽卡类别分布：%s" % str(seen)


# ---------------------------------------------------------------------------
# 新道具效果（Q）
# ---------------------------------------------------------------------------

func test_cam_watches_and_alerts() -> void:
	var w := _solo("cam")
	var h := w.hams[0]
	_use(w, "cam")
	var c: Array = _deps(w, "cam")
	eq(c.size(), 1, "摄像头粘上")
	var cam: SimStructure = c[0]
	eq(cam.team, "blue", "带阵营")
	h.x = 1800.0     # 主人走远
	h.y = 1548.0
	var f := _foe(w, cam.x + 120.0, cam.y)
	if w.map.overlaps_solid(f.x, f.y, f.r) or not w.map.has_los(cam.x, cam.y, f.x, f.y):
		f.x = cam.x - 120.0
	_step(w, 0.3)
	SimVision.compute(w)
	check(w.vis.blue.has(f.id), "摄像头提供区域视野")
	check(w.t - cam.alert_t < 1.0, "敌人进入时小地图标红")
	w.deal_dmg(cam, 999.0, {"team": "red", "owner": f, "x": cam.x, "y": cam.y})
	check(cam.dead, "可被击毁")


func test_trap_roots_and_hidden() -> void:
	var w := _solo("trap")
	var h := w.hams[0]
	_use(w, "trap")
	var t: Array = _deps(w, "trap")
	eq(t.size(), 1, "放下捕鼠夹")
	var tr: SimStructure = t[0]
	var f := _foe(w, tr.x + 400.0, tr.y)
	h.x = 1900.0
	SimVision.compute(w)
	check(not w.seen.red.has(tr.id), "远处看不见捕鼠夹")
	f.x = tr.x + 100.0
	SimVision.compute(w)
	check(w.seen.red.has(tr.id), "走近才看得见")
	var hp0 := f.hp
	f.x = tr.x + 5.0
	_step(w, 0.1)
	check(f.root_t > 1.0, "敌人被夹住约 1.5 秒（%.2f）" % f.root_t)
	check(f.hp < hp0, "夹子造成伤害")
	check(tr.dead, "夹子触发后消失")
	var x0 := f.x
	f.inp.mx = 1.0
	f.inp.ml = 1.0
	_step(w, 0.5)
	near(f.x, x0, 1.0, "被夹住不能移动")


func test_cover_blocks_both_sides() -> void:
	var w := _solo("cover")
	var h := w.hams[0]
	_use(w, "cover")
	var cv: Array = _deps(w, "cover")
	eq(cv.size(), 1, "立起掩体")
	var c: SimStructure = cv[0]
	eq(int(c.max_hp), 300, "耐久 300")
	near(c.life, 15.0, 0.1, "持续 15 秒")
	# 敌方子弹从前方打来：被挡、扣耐久
	var f := _foe(w, h.x + 300.0, h.y)
	var b := w.new_bullet("trc", f, h.x + 200.0, h.y, 16.0, PI, 1200.0, 20.0, 600.0)
	b.owner = f
	w.bullets.append(b)
	var hp0 := h.hp
	_step(w, 0.4)
	eq(h.hp, hp0, "敌方子弹被挡住")
	check(c.hp < c.max_hp, "掩体扣耐久")
	# 己方子弹从外侧往里打也被挡（双方都可利用）
	var b2 := w.new_bullet("trc", h, h.x + 200.0, h.y, 16.0, PI, 1200.0, 20.0, 600.0)
	b2.owner = h
	w.bullets.append(b2)
	var n0 := w.bullets.size()
	_step(w, 0.15)
	check(w.bullets.size() < n0, "掩体也挡己方子弹")
	w.deal_dmg(c, 999.0, {"team": "red", "owner": f, "x": c.x, "y": c.y})
	check(c.dead, "敌方可摧毁")


func test_regen_heals_until_destroyed() -> void:
	var w := _solo("regen")
	var h := w.hams[0]
	h.hp = h.max_hp * 0.3
	var mate := w._make_ham("blue", "player", "队友", 8, "gold")
	mate.x = h.x + 60.0
	mate.y = h.y
	mate.hp = mate.max_hp * 0.3
	_use(w, "regen")
	_step(w, 2.0)
	check(h.hp > h.max_hp * 0.35 and mate.hp > mate.max_hp * 0.35, "范围内队友回血")
	var s: SimStructure = _deps(w, "regen")[0]
	w.deal_dmg(s, 999.0, {"team": "red", "owner": null, "x": s.x, "y": s.y})
	w.step(1.0 / 60.0)
	var hp1 := mate.hp
	_step(w, 1.0)
	near(mate.hp, hp1, 0.5, "装置被打掉就中断")


func test_holo_lures_ai_minions_mobs() -> void:
	var w := _solo("holo")
	var h := w.hams[0]
	var f := _foe(w, h.x + 300.0, h.y, "ai")
	f.ai.target = h
	var m := w.spawn_minion("red", "mid")
	m.x = h.x + 200.0
	m.y = h.y + 40.0
	m.target = h
	_use(w, "holo")
	eq(w.decoys.size(), 1, "生成全息分身")
	var d: SimDecoy = w.decoys[0]
	eq(d.look, "holo", "外观和自己一样")
	eq(d.skin, h.skin, "同皮肤")
	eq(f.ai.target, d, "敌方机器人改打分身")
	eq(m.target, d, "小兵改打分身")
	_step(w, 8.2)
	eq(w.decoys.size(), 0, "8 秒后消失")


func test_guardgun_shoots_minions_and_mobs() -> void:
	var w := _solo("guardgun")
	_use(w, "guardgun")
	var g: Array = _deps(w, "guardgun")
	eq(g.size(), 1, "放下哨戒炮")
	var m := w.spawn_minion("red", "mid")
	m.x = 2700.0
	m.y = 1548.0
	m.stun = 99.0
	_step(w, 1.5)
	check(m.hp < m.max_hp, "哨戒炮打小兵")
	_step(w, 19.0)
	eq(_deps(w, "guardgun").size(), 0, "20 秒后消失")


func test_signal_summons_followers() -> void:
	var w := _solo("signal")
	var h := w.hams[0]
	var n0 := w.minions.size()
	_use(w, "signal")
	eq(w.minions.size() - n0, 3, "呼叫 3 个小兵")
	var mine: Array = w.minions.filter(func(m): return m.follow == h)
	eq(mine.size(), 3, "跟随主人")
	eq(String(mine[0].team), "blue", "己方小兵")
	h.x -= 300.0
	_step(w, 4.0)
	var near_n := 0
	for m in mine:
		if Vector2(m.x - h.x, m.y - h.y).length() < 200.0:
			near_n += 1
	check(near_n >= 2, "小兵跟上来了（%d）" % near_n)
	_step(w, 17.0)
	check(mine.all(func(m): return m.dead or m.follow == null), "20 秒后回兵线")


func test_reflector_returns_rockets() -> void:
	var w := _solo("reflector")
	var h := w.hams[0]
	_use(w, "reflector")
	var r: SimStructure = _deps(w, "reflector")[0]
	var f := _foe(w, h.x + 500.0, h.y)
	for k in 2:
		var b := w.new_bullet("rocket", f, r.x + 200.0, r.y, 16.0, PI, 600.0, 50.0, 900.0)
		b.owner = f
		w.bullets.append(b)
		_step(w, 0.3)
		check(b.team == "blue" and b.vx > 0.0, "第 %d 发火箭被原路弹回" % (k + 1))
	check(r.dead, "弹满 2 发后消失")


# ---------------------------------------------------------------------------
# 新道具效果（E）
# ---------------------------------------------------------------------------

func test_adrenaline_then_slow() -> void:
	var w := _solo("adren")
	var h := w.hams[0]
	_use(w, "adren")
	near(SimGadgets.rate_mul(h), 1.3, 0.001, "攻速 +30%")
	near(SimGadgets.move_mul(h), 1.15, 0.001, "移速 +15%")
	_step(w, 6.1)
	check(SimGadgets.move_mul(h) < 1.0, "结束后减速")
	near(SimGadgets.rate_mul(h), 1.0, 0.001, "攻速恢复")
	_step(w, 2.1)
	near(SimGadgets.move_mul(h), 1.0, 0.001, "减速 2 秒后恢复")


func test_bubble_shield_breaks() -> void:
	var w := _solo("bubble")
	var h := w.hams[0]
	_use(w, "bubble")
	near(h.eshield, h.max_hp * 0.3, 0.01, "护盾 = 最大生命 30%")
	w.events.clear()
	w.deal_dmg(h, h.max_hp * 0.31, {"team": "red", "owner": null, "x": h.x, "y": h.y})
	check(w.events.any(func(e): return e.t == "eshield_break"), "护盾碎裂事件")
	eq(h.eshield_t, 0.0, "护盾没了")


func test_warp_teleports_to_corner_and_interrupts() -> void:
	var w := _solo("warp")
	var h := w.hams[0]
	_use(w, "warp")
	check(h.tp_t > 0.9, "开始读条")
	w.deal_dmg(h, 5.0, {"team": "red", "owner": null, "x": h.x, "y": h.y})
	eq(h.tp_t, 0.0, "受击打断")
	near(h.x, 2520.0, 30.0, "没传走")
	h.gad.e.ch = 1
	_use(w, "warp")
	_step(w, 1.1)
	var M := w.map
	var cx := (h.x - M.min_x) < (M.max_x - M.min_x) * 0.3 or (M.max_x - h.x) < (M.max_x - M.min_x) * 0.3
	var cy := (h.y - M.min_y) < (M.max_y - M.min_y) * 0.3 or (M.max_y - h.y) < (M.max_y - M.min_y) * 0.3
	check(cx and cy, "落在地图角落（%.0f, %.0f）" % [h.x, h.y])
	var eb: Vector2 = M.base_pos.red
	check(Vector2(h.x - eb.x, h.y - eb.y).length() > 900.0, "不在敌方鼠窝范围")
	check(not M.overlaps_solid(h.x, h.y, h.r - 1.0), "不卡在墙里")


func test_goggles_dark_sight() -> void:
	var w := _solo("goggles")
	var h := w.hams[0]
	h.aim = PI
	h.inp.aim = PI
	var f := _foe(w, h.x + 300.0, h.y)
	if not w.map.has_los(h.x, h.y, f.x, f.y):
		f.y += 80.0
	SimVision.compute(w)
	check(not w.vis.blue.has(f.id), "没戴夜视仪：背后暗处看不清")
	_use(w, "goggles")
	h.aim = PI
	SimVision.compute(w)
	check(w.vis.blue.has(f.id), "戴上夜视仪：暗处可视")
	_step(w, 20.2)
	eq(h.nvg_t <= 0.0, true, "20 秒后失效")


func test_sonar_reveals_through_walls() -> void:
	var w := _solo("sonar")
	var h := w.hams[0]
	# 找一个墙后的位置
	var f := _foe(w, h.x, h.y)
	var placed := false
	for a in range(0, 360, 10):
		for d: float in [300.0, 450.0, 600.0]:
			var x := h.x + cos(deg_to_rad(a)) * d
			var y := h.y + sin(deg_to_rad(a)) * d
			if not w.map.overlaps_solid(x, y, f.r) and not w.map.has_los(h.x, h.y, x, y):
				f.x = x
				f.y = y
				placed = true
				break
		if placed:
			break
	check(placed, "找到墙后的位置")
	SimVision.compute(w)
	check(not w.vis.blue.has(f.id), "墙后看不见")
	_use(w, "sonar")
	SimVision.compute(w)
	check(w.vis.blue.has(f.id), "声呐穿墙显示轮廓")
	_step(w, 3.2)
	SimVision.compute(w)
	check(not w.vis.blue.has(f.id), "3 秒后消失")


func test_new_gadgets_keep_legacy_effects() -> void:
	## 规格里的 4 个旧道具（破片手雷、医疗包、火箭喷射包、隐形地雷）效果不变：走旧代码、用 rules.json 参数
	for id in ["frag", "medkit", "jetpack", "mine"]:
		eq(String(Data.gadget(id).fx.type), id, "%s 沿用旧效果" % id)
		check((Data.rules().gadgets as Dictionary).has(id), "%s 参数仍在 rules.json" % id)


# ---------------------------------------------------------------------------
# AI 与联机
# ---------------------------------------------------------------------------

func test_ai_uses_both_slots() -> void:
	## AI 对局里每个 AI 轮流装上所有道具：Q、E 两个槽的每一个道具都要被用过
	var w := make_world("full", 23, 5, 5)
	var used := {}
	var ids := Data.gadget_pool("q", "upgrade") + Data.gadget_pool("q", "start") + Data.gadget_pool("e", "upgrade") + Data.gadget_pool("e", "start")
	var qs := Data.gadget_pool("q", "start") + Data.gadget_pool("q", "upgrade")
	var es := Data.gadget_pool("e", "start") + Data.gadget_pool("e", "upgrade")
	var t0 := Time.get_ticks_msec()
	for round_i in 7:
		for i in w.hams.size():
			var h := w.hams[i]
			h.gad.q = SimGadgets.new_slot(String(qs[(i + round_i * 3) % qs.size()]), h)
			h.gad.e = SimGadgets.new_slot(String(es[(i + round_i * 2) % es.size()]), h)
			h.gup = {"gcdx": 3, "gcap": 1}
		for k in 60 * 60:
			w.step(1.0 / 60.0)
			for ev in w.events:
				if ev.t == "gadget":
					used[String(ev.gadget)] = int(used.get(String(ev.gadget), 0)) + 1
			w.events.clear()
			if w.over:
				break
		if w.over:
			break
	var missing: Array = ids.filter(func(id): return not used.has(id))
	check(missing.is_empty(), "AI 用过两个槽的全部道具（没用过：%s）" % str(missing))
	note = "7 分钟 AI 对局 %d ms，用道具次数：%s" % [Time.get_ticks_msec() - t0, str(used)]


func test_ai_priority_save_over_fight() -> void:
	## 同一时刻两个槽都想用时：保命 > 交战 > 情报
	var w := _solo()
	var h := w.hams[0]
	w.hand_to_ai(h)
	h.gad.q = SimGadgets.new_slot("cover", h)     # 交战
	h.gad.e = SimGadgets.new_slot("medkit", h)    # 保命
	var f := _foe(w, h.x + 300.0, h.y)
	h.hp = h.max_hp * 0.3
	eq(SimGadgets.ai_pick_slot(w, h, f), "e", "血少时先用医疗包")
	h.hp = h.max_hp
	eq(SimGadgets.ai_pick_slot(w, h, f), "q", "满血交火时用掩体")


func test_snapshot_syncs_slots_and_deployables() -> void:
	var players := [{"team": "blue", "ctl": "player", "name": "A"}, {"team": "red", "ctl": "player", "name": "B"}]
	var host := make_world("slice", 24, 0, 0, players)
	var guest := make_world("slice", 24, 0, 0, players)
	var baseline := NetSnapshot.baseline_index(NetSnapshot.capture(host))
	var h := host.hams[0]
	SimGadgets.equip(host, h, "cover")
	SimGadgets.add_upgrade(h, "gcap")
	_step(host, 2.1)
	h.inp.gadget = true
	host.step(1.0 / 60.0)
	host.events.clear()
	var packet := NetSnapshot.expand_delta(NetSnapshot.decompress(NetSnapshot.compress(NetSnapshot.delta(NetSnapshot.capture(host), baseline))), baseline)
	check(NetSnapshot.apply(guest, packet), "快照应用")
	var g := guest.hams[0]
	eq(String(g.gad.q.id), "cover", "槽位同步")
	eq(int(g.gad.q.ch), int(h.gad.q.ch), "充能同步")
	eq(int(g.gup.get("gcap", 0)), 1, "通用升级同步")
	var dep: Array = guest.structs.filter(func(s): return s.kind == "dep")
	eq(dep.size(), 1, "部署物同步")
	if not dep.is_empty():
		eq(String(dep[0].dep), "cover", "部署物种类")
		eq(String(dep[0].team), "blue", "部署物阵营")
		near(float(dep[0].hp), 300.0, 0.1, "部署物耐久")
	host.dispose()
	guest.dispose()


func test_actions_carry_e_slot() -> void:
	var i := SimHamster.HamInput.new()
	i.gadget2 = true
	var p := NetInput.pack_actions(i, [], 1)
	var j := SimHamster.HamInput.new()
	check(NetInput.apply_actions(j, p, []), "带 E 的动作包合法")
	check(j.gadget2, "E 键动作传到主机")
