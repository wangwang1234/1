extends "res://tests/test_case.gd"
## 整局压力测试：AI 对局 2 分钟无报错；同种子结果一致；三把枪 × 各进化等级都能打。


func test_ai_match_slice_2min() -> void:
	var w := make_world("slice", 21, 3, 3)
	var t0 := Time.get_ticks_msec()
	run(w, 120.0)
	var ms := Time.get_ticks_msec() - t0
	check(w.t >= 119.9 or w.over, "跑满 2 分钟")
	check(w.minions.size() > 0 or w.wave_n > 0, "有小兵出生")
	var kills := 0
	var lv := 0
	for h in w.hams:
		kills += h.kills
		lv = maxi(lv, h.lvl)
	check(lv >= 3, "有人升级（最高 Lv%d）" % lv)
	note = "slice 2 分钟：%d ms，最高 Lv%d，击杀 %d，小兵 %d，波次 %d" % [ms, lv, kills, w.minions.size(), w.wave_n]


func test_ai_match_full_2min() -> void:
	var w := make_world("full", 22, 4, 4)
	var t0 := Time.get_ticks_msec()
	run(w, 120.0)
	note = "full 2 分钟：%d ms" % (Time.get_ticks_msec() - t0)
	check(w.t >= 119.9 or w.over, "跑满 2 分钟")


func test_determinism() -> void:
	var a := make_world("slice", 33, 3, 3)
	var b := make_world("slice", 33, 3, 3)
	run(a, 40.0)
	run(b, 40.0)
	eq(a.state_hash(), b.state_hash(), "同种子 40 秒后状态一致")
	var c := make_world("slice", 34, 3, 3)
	run(c, 40.0)
	check(a.state_hash() != c.state_hash(), "不同种子结果不同")


func test_all_weapon_evo_levels() -> void:
	## 三把枪 × 三条路线 × 0..9 级，每种 AI 打 6 秒
	var count := 0
	for wid in Data.rule("scope.weapons"):
		for k: String in ["a", "b", "c"]:
			for lv: int in [1, 3, 6, 9]:
				var w := make_world("slice", 100 + count, 2, 2)
				for h in w.hams:
					h.weapon_id = String(wid)
					h.evo = {"a": 0, "b": 0, "c": 0}
					h.evo[k] = lv
					h.ammo = SimWeapons.mag_size(h)
					# 拉近距离保证交火
					h.x = w.map.base_pos.blue.x + 1500.0 + (60.0 if h.team == "red" else -60.0) * 3.0
					h.y = 1548.0 + (h.idx % 3) * 40.0
				run(w, 6.0)
				var shots := 0
				for h in w.hams:
					shots += h.shot_n
				check(shots > 0, "%s %s%d 开过火" % [wid, k, lv])
				count += 1
	note = "%d 种组合" % count


func test_match_can_end() -> void:
	## 让蓝队强行推掉红方炮台和鼠窝，验证胜负判定
	var w := make_world("slice", 41, 1, 1)
	for s in w.structs:
		if s.team == "red" and s.kind == "turret":
			w.deal_dmg(s, 99999.0, {"team": "blue", "owner": w.hams[0], "x": s.x, "y": s.y})
	w.step(1.0 / 60.0)
	var base: SimStructure = null
	for s in w.structs:
		if s.team == "red" and s.kind == "base":
			base = s
	check(not base.shielded, "炮台被拆后鼠窝护盾消失")
	w.deal_dmg(base, 99999.0, {"team": "blue", "owner": w.hams[0], "x": base.x, "y": base.y})
	check(w.over and w.winner == "blue", "打爆鼠窝蓝队获胜")


func test_dispose_frees_world() -> void:
	## 一局结束后 dispose() 要断开实体间的循环引用，否则每开一局都漏内存
	var w := make_world("slice", 5, 3, 3)
	run(w, 40.0)
	var probe: WeakRef = weakref(w.hams[0])
	var probe2: WeakRef = weakref(w.props[0]) if not w.props.is_empty() else null
	w.dispose()
	w = null
	check(probe.get_ref() == null, "仓鼠对象已释放")
	if probe2 != null:
		check(probe2.get_ref() == null, "物件对象已释放")
