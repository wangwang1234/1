extends "res://tests/test_case.gd"
## 2026-10 进化重做：每一级都是看得见的新效果。检查数据完整性，以及新加的通用机制在局里真的生效。


func _solo(weapon: String, evo: Dictionary = {}) -> SimWorld:
	## 一只玩家仓鼠站在完整地图中间的空地上朝右
	var w := make_world("full", 5, 0, 0, [{"team": "blue", "ctl": "player", "name": "测", "weapon": weapon}])
	var h := w.hams[0]
	h.evo = {"a": int(evo.get("a", 0)), "b": int(evo.get("b", 0)), "c": int(evo.get("c", 0))}
	h.ammo = SimWeapons.mag_size(h)
	h.x = 2520.0
	h.y = 1548.0
	h.aim = 0.0
	h.inp.aim = 0.0
	h.iframes = 0.0
	for e in w.mobs:
		e.dead = true
	w.mobs.clear()
	w.wave_next = 1e9
	return w


func _dummy(w: SimWorld, x: float, y: float, hp: float = 500.0) -> SimMinion:
	var m := w.spawn_minion("red", w.map.lanes.keys()[0])
	m.x = x
	m.y = y
	m.px = x
	m.py = y
	m.hp = hp
	m.max_hp = hp
	m.stun = 99.0
	return m


func _step(w: SimWorld, sec: float) -> void:
	for i in int(sec * 60.0):
		w.step(1.0 / 60.0)


func _shoot(w: SimWorld, sec: float) -> void:
	var h := w.hams[0]
	h.inp.fire = true
	for i in int(sec * 60.0):
		h.inp.aim = 0.0
		w.step(1.0 / 60.0)
	h.inp.fire = false


func test_every_level_has_its_own_effect() -> void:
	## 18 把武器 × 3 条路线 × 9 级：每一级都有卡面文字，且参数和上一级不同（不会出现“空升级”）
	var n := 0
	for wid: String in Data.weapons():
		var paths: Array = Data.evolutions().paths[wid]
		for i in 3:
			var p: Dictionary = paths[i]
			var texts: Array = p.get("lv", [])
			eq(texts.size(), 9, "%s·%s 有 9 级文字" % [wid, p.name])
			for L in range(1, 10):
				check(L - 1 < texts.size() and String(texts[L - 1]).length() > 1, "%s·%s 第 %d 级有文字" % [wid, p.name, L])
				var lo := [0, 0, 0]
				var hi := [0, 0, 0]
				lo[i] = L - 1
				hi[i] = L
				var a := JSON.stringify(SimWeapons.params_for(wid, lo), "", true)
				var b := JSON.stringify(SimWeapons.params_for(wid, hi), "", true)
				if check(a != b, "%s·%s 第 %d 级真的改变了参数" % [wid, p.name, L]):
					n += 1
	note = "%d 级全部有效果" % n


func test_card_text_per_level() -> void:
	var w := _solo("smg")
	var h := w.hams[0]
	var L1 := SimCards.label(h, {"t": "evo", "k": "a"})
	eq(String(L1.desc), "双管：并排两条弹道", "冲锋枪 A 第 1 级卡面")
	h.evo.a = 8
	var L9 := SimCards.label(h, {"t": "evo", "k": "a"})
	check(String(L9.desc).begins_with("质变："), "第 9 级标“质变”")
	eq(String(L9.badge), "质变", "第 9 级角标")


func test_twin_barrels() -> void:
	var w := _solo("smg", {"a": 3})
	_dummy(w, 2800.0, 1548.0)
	var h := w.hams[0]
	h.inp.fire = true
	w.step(1.0 / 60.0)
	h.inp.fire = false
	eq(w.bullets.filter(func(b): return b.owner == h).size(), 3, "冲锋枪 A3 三管：一发打出 3 条平行弹道")
	var ys := w.bullets.filter(func(b): return b.owner == h).map(func(b): return snappedf(b.y, 1.0))
	check(ys.max() - ys.min() >= 15.0, "三条弹道左右错开（%s）" % str(ys))


func test_even_fan_hits_center() -> void:
	## 多弹道围着准星等距摆：偶数发时正前方的敌人也能打中（修复前 2 发分别飞向散布两端，正中间是空的）
	var w := _solo("smg")
	var h := w.hams[0]
	h.st.multi = 1
	var ok := 0
	for k in 10:
		h.fire_cd = 0.0
		h.bloom = 0.0
		var before := w.bullets.size()
		SimWeapons.fire(w, h)
		var center := false
		for i in range(before, w.bullets.size()):
			var bl: SimBullet = w.bullets[i]
			if absf(150.0 * tan(atan2(bl.vy, bl.vx))) < 16.0:
				center = true
		if center:
			ok += 1
		w.bullets.clear()
	check(ok >= 8, "两发弹道时 150 外正前方仍在弹道上（10 次里 %d 次）" % ok)


func test_fan_every_and_heavy() -> void:
	var w := _solo("pistol", {"a": 9})
	var h := w.hams[0]
	var max_n := 0
	var heavy := false
	h.inp.fire = true
	for i in 120:
		h.inp.aim = 0.0
		w.step(1.0 / 60.0)
		max_n = maxi(max_n, w.bullets.filter(func(b): return b.owner == h).size())
		for b in w.bullets:
			if b.owner == h and b.big:
				heavy = true
	check(max_n >= 6, "手枪 A9 扇射：同时在飞的子弹 ≥6（%d）" % max_n)
	check(heavy, "手枪 A6 每第 5 发是重弹")


func test_ricochet_to_next_enemy() -> void:
	var w := _solo("pistol", {"b": 6})
	var a := _dummy(w, 2700.0, 1548.0, 2000.0)
	var b := _dummy(w, 2700.0, 1700.0, 2000.0)
	_shoot(w, 0.6)
	_step(w, 0.5)
	check(a.hp < 2000.0, "第一个敌人被打")
	check(b.hp < 2000.0, "子弹弹射到旁边的敌人（剩 %.0f）" % b.hp)


func test_under_barrel_grenade() -> void:
	var w := _solo("ak47", {"a": 2})
	var h := w.hams[0]
	var got := false
	h.inp.fire = true
	for i in 150:
		h.inp.aim = 0.0
		w.step(1.0 / 60.0)
		if w.lobs.any(func(L): return L.kind == "bomb" and L.owner == h):
			got = true
	check(got, "AK A2 每第 12 发打出一颗小榴弹")


func test_reload_ring_and_shock() -> void:
	var w := _solo("dual", {"c": 4})
	var h := w.hams[0]
	var m := _dummy(w, 2600.0, 1548.0)
	h.ammo = 0
	SimHamsterLogic.start_reload(w, h)
	var ring := false
	for i in 180:
		w.step(1.0 / 60.0)
		if w.bullets.filter(func(b): return b.owner == h).size() >= 8:
			ring = true
	check(ring, "双持 C4 换弹完成时射出一圈子弹")
	check(Vector2(m.x - 2600.0, m.y - 1548.0).length() > 5.0 or m.hp < 500.0, "双持 C2 换弹震开身边的敌人")


func test_kill_blast_and_heal() -> void:
	var w := _solo("deagle", {"a": 7, "c": 6})
	var h := w.hams[0]
	h.hp = h.max_hp * 0.5
	var hp0 := h.hp
	var a := _dummy(w, 2660.0, 1548.0, 5.0)
	var b := _dummy(w, 2690.0, 1560.0, 500.0)
	_shoot(w, 0.4)
	_step(w, 0.3)
	check(a.dead, "目标被打死")
	check(b.hp < 500.0, "尸体爆炸炸到旁边的敌人（剩 %.0f）" % b.hp)
	check(h.hp > hp0, "沙鹰 C6 击杀回血")


func test_katana_spin_and_leech() -> void:
	var w := _solo("katana", {"a": 7})
	var h := w.hams[0]
	var back := _dummy(w, 2460.0, 1548.0, 2000.0)     # 身后
	h.hp = h.max_hp * 0.5
	var hp0 := h.hp
	h.inp.fire = true
	for i in 150:
		h.inp.aim = 0.0
		w.step(1.0 / 60.0)
	check(back.hp < 2000.0, "武士刀 A7 旋风斩砍到身后的敌人")
	check(h.hp > hp0, "武士刀 A5 挥刀吸血")


func test_flame_nozzles_and_gl_multi() -> void:
	var w := _solo("flame", {"a": 6})
	var h := w.hams[0]
	h.inp.fire = true
	w.step(1.0 / 60.0)
	h.inp.fire = false
	eq(w.bullets.filter(func(b): return b.owner == h and b.kind == "flame").size(), 3, "喷火 A6 三喷嘴")
	var w2 := _solo("gl", {"a": 7})
	var h2 := w2.hams[0]
	h2.inp.fire = true
	w2.step(1.0 / 60.0)
	h2.inp.fire = false
	eq(w2.lobs.filter(func(L): return L.owner == h2).size(), 3, "榴弹 A7 一次打出 3 颗")


func test_laser_pierce_refract_and_numbers() -> void:
	var w := _solo("laser", {"a": 3})
	var a := _dummy(w, 2640.0, 1548.0, 2000.0)
	var b := _dummy(w, 2720.0, 1548.0, 2000.0)
	_shoot(w, 1.0)
	check(a.hp < 2000.0 and b.hp < 2000.0, "激光 A3 光束穿透 1 个敌人（%.0f / %.0f）" % [a.hp, b.hp])
	var w2 := _solo("laser", {"b": 9})
	var c := _dummy(w2, 2700.0, 1548.0, 2000.0)
	var d := _dummy(w2, 2700.0, 1700.0, 2000.0)
	var e := _dummy(w2, 2700.0, 1850.0, 2000.0)
	_shoot(w2, 1.0)
	check(d.hp < 2000.0 and e.hp < 2000.0, "激光 B9 折射连锁到第三个敌人")


func test_laser_wider_beam() -> void:
	## 激光光束有粗细：准星偏一点也能照到（小兵半径 12，偏 16 原来照不到）
	var w := _solo("laser")
	var m := _dummy(w, 2700.0, 1564.0, 2000.0)
	_shoot(w, 1.0)
	check(m.hp < 2000.0, "擦边也照得到（剩 %.0f）" % m.hp)


func test_dash_mine_and_gl_ice() -> void:
	var w := _solo("smg", {"b": 2})
	var h := w.hams[0]
	h.inp.dash = true
	w.step(1.0 / 60.0)
	check(w.lobs.any(func(L): return L.kind == "bomb" and L.owner == h), "冲锋枪 B2 翻滚留下小炸弹")
	var w2 := _solo("gl", {"c": 9})
	var h2 := w2.hams[0]
	var m := _dummy(w2, 2800.0, 1548.0, 2000.0)
	h2.inp.has_aim_point = true
	h2.inp.aim_x = 2800.0
	h2.inp.aim_y = 1548.0
	var frozen := false
	h2.inp.fire = true
	for i in 600:
		h2.inp.aim = 0.0
		w2.step(1.0 / 60.0)
		if m.frozen_until > w2.t:
			frozen = true
	check(frozen, "榴弹 C9 冰冻弹能冻住敌人")


func test_ai_uses_every_new_mechanic_without_errors() -> void:
	## 每把枪三条路线都点到 9 级，AI 对打 8 秒，不报错
	var count := 0
	for wid: String in Data.rule("scope.weapons"):
		var w := make_world("slice", 300 + count, 2, 2)
		for h in w.hams:
			h.weapon_id = wid
			h.evo = {"a": 9, "b": 9, "c": 9}
			h.ammo = SimWeapons.mag_size(h)
			h.x = w.map.base_pos.blue.x + 1500.0 + (180.0 if h.team == "red" else -180.0)
			h.y = 1548.0 + (h.idx % 3) * 40.0
		run(w, 8.0)
		check(w.errors == 0, "%s 全满进化无逻辑错误" % wid)
		count += 1
