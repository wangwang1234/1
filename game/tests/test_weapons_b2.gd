extends "res://tests/test_case.gd"
## 批次 2 武器：进化参数、各种开火方式（火箭 / 刀 / 喷火 / 榴弹 / 电磁 / 激光）、特殊效果（转管、神枪手、弹反、分裂、追踪）。


func _solo(weapon: String, evo: Dictionary = {}) -> SimWorld:
	## 只有一只玩家仓鼠的全图，放在空旷处朝右
	var w := make_world("full", 5, 0, 0, [{"team": "blue", "ctl": "player", "name": "测", "weapon": weapon}])
	var h := w.hams[0]
	h.evo = {"a": int(evo.get("a", 0)), "b": int(evo.get("b", 0)), "c": int(evo.get("c", 0))}
	h.ammo = SimWeapons.mag_size(h)
	h.x = 2520.0
	h.y = 1548.0
	h.aim = 0.0
	h.inp.aim = 0.0
	# 清掉附近的野怪，避免干扰
	for e in w.mobs:
		e.dead = true
	w.mobs.clear()
	return w


func _dummy(w: SimWorld, x: float, y: float, hp: float = 500.0) -> SimMinion:
	var m := w.spawn_minion("red", w.map.lanes.keys()[0])
	m.x = x
	m.y = y
	m.px = x
	m.py = y
	m.hp = hp
	m.max_hp = hp
	m.stun = 99.0   # 站着不动当靶子
	return m


func _step(w: SimWorld, sec: float) -> void:
	for i in int(sec * 60.0):
		w.step(1.0 / 60.0)


func test_params_sample() -> void:
	var P := SimWeapons.params_for("deagle", [6, 0, 0])
	near(float(P.kb), 2.0, 0.001, "沙鹰 A1+A4 击退")
	eq(float(P.slow), 0.5, "沙鹰 A2 减速")
	eq(int(P.special.heavyEvery), 4, "沙鹰 A5 重弹")
	near(float(P.shockR), 80.0, 0.001, "沙鹰 A3+A6 震波")
	P = SimWeapons.params_for("deagle", [0, 3, 0])
	eq(float(P.spread), 0.0, "沙鹰 B1 零散布")
	P = SimWeapons.params_for("smg", [6, 0, 0])
	eq(int(P.special.twin), 3, "冲锋枪 A6 四管")
	eq(int(P.special.fanEvery), 4, "冲锋枪 A4 扇形弹每 4 发")
	eq(int(P.special.fanN), 5, "冲锋枪 A5 扇形弹 5 发")
	P = SimWeapons.params_for("smg", [0, 0, 6])
	eq(float(P.bounceK), 1.2, "冲锋枪 C4 反弹加伤")
	eq(int(P.bounce), 2, "冲锋枪 C3 反弹 2 次")
	P = SimWeapons.params_for("dual", [0, 0, 9])
	near(float(P.rl), 0.8, 0.001, "双持 C1 换弹")
	eq(int(P.special.lastN), 6, "双持 C9 最后 6 发")
	P = SimWeapons.params_for("rocket", [4, 0, 0])
	near(float(P.home), 2.2, 0.001, "火箭 A1+A2 追踪")
	near(float(P.spd), 0.85 * 1.25, 0.001, "火箭 A1 降速、A4 提速")
	P = SimWeapons.params_for("flame", [9, 0, 0])
	near(float(P.dmg), 1.8, 0.001, "喷火 A3×A9 伤害")
	near(float(P.slow), 0.4, 0.001, "喷火 A5 减速")
	eq(int(P.special.flameN), 2, "喷火 A6 三喷嘴")
	P = SimWeapons.params_for("rail", [3, 0, 0])
	near(float(P.charge), 0.7225, 0.001, "电磁 A1×A3 蓄力")
	P = SimWeapons.params_for("laser", [0, 0, 4])
	near(float(P.cost), 0.55, 0.001, "激光 C1+C4 耗能")
	eq(int(P.special.reloadRing), 8, "激光 C3 换电池环形弹")
	var h := SimHamster.new()
	h.weapon_id = "minigun"
	h.evo = {"a": 9, "b": 0, "c": 0}
	near(SimWeapons.spin_mul(h), 0.56, 0.001, "加特林 A1×A4 预热")
	P = SimWeapons.params_for("revolver", [4, 0, 0])
	near(float(P.bounceK), 1.4, 0.001, "左轮 A4 反弹系数")
	eq(int(P.bounce), 1, "左轮 A1 多反弹一次")
	eq(int(P.special.rico), 1, "左轮 A3 弹射")
	var h2 := SimHamster.new()
	h2.weapon_id = "lmg"
	h2.evo = {"a": 6, "b": 0, "c": 0}
	eq(SimWeapons.mag_size(h2), 130, "轻机枪 A1 弹匣 +30")


func test_every_path_has_effects() -> void:
	for wid in Data.weapons():
		var paths: Array = Data.evolutions().paths[wid]
		eq(paths.size(), 3, "%s 三条路线" % wid)
		for p in paths:
			check(p.has("effects") and not (p.effects as Dictionary).is_empty(), "%s·%s 有进化效果" % [wid, p.name])


func test_rocket_explodes() -> void:
	var w := _solo("rocket")
	var h := w.hams[0]
	var m := _dummy(w, h.x + 240.0, h.y)
	h.inp.fire = true
	_step(w, 0.05)
	h.inp.fire = false
	var rockets := w.bullets.filter(func(b): return b.kind == "rocket")
	eq(rockets.size(), 1, "发射一枚火箭")
	_step(w, 1.0)
	check(m.hp < 500.0 - 50.0, "火箭爆炸伤害 >50（剩 %.1f）" % m.hp)


func test_rocket_cluster_and_multi() -> void:
	var w := _solo("rocket", {"a": 9, "c": 9})
	var h := w.hams[0]
	h.inp.fire = true
	_step(w, 0.05)
	h.inp.fire = false
	eq(w.bullets.filter(func(b): return b.kind == "rocket").size(), 3, "A9 三连发（优先于 C9 双发）")
	_step(w, 2.5)
	var w2 := _solo("rocket", {"c": 6})
	var h2 := w2.hams[0]
	_dummy(w2, h2.x + 200.0, h2.y)
	h2.inp.fire = true
	_step(w2, 0.05)
	h2.inp.fire = false
	_step(w2, 0.6)
	check(w2.lobs.filter(func(L): return L.kind == "bomb").size() == 6, "C6 散出 6 颗子炸弹")


func test_katana_swing_and_deflect() -> void:
	var w := _solo("katana")
	var h := w.hams[0]
	var m := _dummy(w, h.x + 50.0, h.y)
	h.inp.fire = true
	_step(w, 0.05)
	h.inp.fire = false
	check(m.hp < 500.0, "近战砍到")
	check(h.swing_t > 0.0, "挥刀中")
	# 弹反：敌方子弹从正前方飞来
	var shooter := _dummy(w, h.x + 400.0, h.y)
	var b := w.new_bullet("mpea", shooter, h.x + 60.0, h.y, 11.0, PI, 500.0, 10.0, 400.0)
	w.bullets.append(b)
	h.swing_t = 0.2
	SimWeaponModes.katana_tick(w, h, 1.0 / 60.0)
	eq(b.team, "blue", "子弹被弹回来变成己方")
	check(b.vx > 0.0, "子弹朝前飞")


func test_katana_wave_and_iaido() -> void:
	var w := _solo("katana", {"b": 9, "c": 9})
	var h := w.hams[0]
	for i in 3:
		h.fire_cd = 0.0
		h.inp.fire = true
		w.step(1.0 / 60.0)
	h.inp.fire = false
	var waves := w.bullets.filter(func(b): return b.kind == "swave")
	check(waves.size() >= 3, "剑气（含第三刀的双剑气）：%d" % waves.size())
	var m := _dummy(w, h.x + 60.0, h.y)
	h.inp.mx = 1.0
	h.inp.ml = 1.0
	h.inp.dash = true
	h.dash_cd = 0.0
	_step(w, 0.3)
	check(m.hp < 500.0, "居合翻滚斩")


func test_flame() -> void:
	var w := _solo("flame", {"b": 3})
	var h := w.hams[0]
	var m := _dummy(w, h.x + 90.0, h.y)
	h.inp.fire = true
	_step(w, 0.5)
	h.inp.fire = false
	check(w.bullets.any(func(b): return b.kind == "flame") or m.burn_t > 0.0, "喷出火焰")
	check(m.burn_t > 0.0, "点燃")
	check(w.fires.size() > 0, "B3 火洼")


func test_gl_lob_and_sticky() -> void:
	var w := _solo("gl")
	var h := w.hams[0]
	var m := _dummy(w, h.x + 300.0, h.y)
	h.inp.has_aim_point = true
	h.inp.aim_x = m.x
	h.inp.aim_y = m.y
	h.inp.fire = true
	_step(w, 0.05)
	h.inp.fire = false
	eq(w.lobs.size(), 1, "抛出一颗榴弹")
	_step(w, 1.5)
	check(m.hp < 500.0, "榴弹爆炸伤害")
	var w2 := _solo("gl", {"b": 9})
	var h2 := w2.hams[0]
	h2.inp.fire = true
	_step(w2, 0.05)
	h2.inp.fire = false
	check(w2.lobs.size() == 2 and w2.lobs.all(func(L): return L.sticky), "B 黏弹（B4 起一次 2 颗）")
	_step(w2, 1.2)
	h2.fire_cd = 0.0
	h2.inp.fire = true
	w2.step(1.0 / 60.0)
	h2.inp.fire = false
	w2.step(1.0 / 60.0)
	w2.step(1.0 / 60.0)
	eq(w2.lobs.size(), 0, "B9 再扣扳机引爆黏弹")


func test_rail_charge_and_beam() -> void:
	var w := _solo("rail", {"b": 6})
	var h := w.hams[0]
	var m := _dummy(w, h.x + 600.0, h.y, 1000.0)
	h.inp.fire = true
	_step(w, 0.6)
	check(h.charge > 0.4, "按住蓄力")
	h.inp.fire = false
	w.step(1.0 / 60.0)
	eq(h.charge, 0.0, "松开发射")
	check(m.hp < 1000.0 - 40.0, "光束命中（%.1f）" % m.hp)


func test_laser_ticks() -> void:
	var w := _solo("laser", {"b": 6})
	var h := w.hams[0]
	var m := _dummy(w, h.x + 200.0, h.y)
	var a0 := h.ammo
	h.inp.fire = true
	_step(w, 1.0)
	check(m.hp < 500.0 - 30.0, "激光持续伤害（%.1f）" % m.hp)
	check(h.ammo < a0, "消耗能量")
	eq(h.beams.size(), 3, "B6 主光束 + 两道副光束")


func test_minigun_spin() -> void:
	var w := _solo("minigun")
	var h := w.hams[0]
	h.inp.fire = true
	w.step(1.0 / 60.0)
	eq(h.shot_n, 0, "转速不够不开火")
	_step(w, 0.6)
	check(h.spin >= 0.99, "预热满")
	var n0 := h.shot_n
	_step(w, 1.0)
	var rate := h.shot_n - n0
	check(rate >= 25 and rate <= 29, "满转速约 28 发/秒（实际 %d）" % rate)


func test_revolver_deadeye() -> void:
	var w := _solo("revolver", {"b": 3})
	var h := w.hams[0]
	_dummy(w, h.x + 300.0, h.y - 40.0)
	_dummy(w, h.x + 320.0, h.y + 40.0)
	SimVision.compute(w)
	h.inp.fire = true
	_step(w, 0.9)
	check(h.marks.size() >= 2, "按住标记目标（%d）" % h.marks.size())
	h.inp.fire = false
	w.step(1.0 / 60.0)
	eq(h.marks.size(), 0, "松开连射")
	check(h.shot_n >= 2, "连射至少两发")


func test_smg_split_and_bounce_home() -> void:
	var w := _solo("smg", {"a": 9})
	var h := w.hams[0]
	h.inp.fire = true
	w.step(1.0 / 60.0)
	h.inp.fire = false
	var n0 := w.bullets.size()
	_step(w, 0.25)
	check(w.bullets.size() > n0, "子弹飞出 150 后分裂（%d → %d）" % [n0, w.bullets.size()])


func test_dual_alternates() -> void:
	var w := _solo("dual")
	var h := w.hams[0]
	var sides: Array = []
	for i in 4:
		h.fire_cd = 0.0
		SimWeapons.fire(w, h)
		sides.append(h.dual_side)
	eq(sides, [-1, 1, -1, 1], "左右手交替")


func test_amr_wall_pierce() -> void:
	var w := _solo("amr")
	var h := w.hams[0]
	SimWeapons.fire(w, h)
	var b: SimBullet = w.bullets[0]
	eq(b.wall_pierce, 1, "反器材穿透障碍")


func test_all_kinds_ai_full_match() -> void:
	## 全图 4v4，AI 随机分配 18 把武器打 90 秒，统计开火
	var w := SimWorld.new()
	var ids: Array = Data.weapons().keys()
	w.setup({"mode": "full", "seed": 77, "players": [], "ai": {"blue": 4, "red": 4}, "ai_weapons": {"blue": ids.slice(0, 9), "red": ids.slice(9, 18)}})
	var i := 0
	for h in w.hams:
		h.weapon_id = String(ids[i % ids.size()])
		h.ammo = SimWeapons.mag_size(h)
		i += 1
	run(w, 90.0)
	var shots := 0
	for h in w.hams:
		shots += h.shot_n
	check(shots > 50, "90 秒里大家开过火（%d）" % shots)
	w.dispose()
