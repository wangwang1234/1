extends "res://tests/test_case.gd"
## 武器与进化数值（2026-10 进化重做后按 evolutions.json 的新设计核对）。


func _ham(w: SimWorld, weapon: String, a: int, b: int, c: int) -> SimHamster:
	var h := w.hams[0]
	h.weapon_id = weapon
	h.evo = {"a": a, "b": b, "c": c}
	h.evo_key = ""
	return h


func test_pistol_params() -> void:
	## 2026-10 进化重做：每一级都是一条具体效果（evolutions.json 的 lv）
	var w := make_world("slice", 1, 1, 0)
	var h := _ham(w, "pistol", 4, 0, 0)
	var P := SimWeapons.params(h)
	near(P.spd, 1.25, 1e-6, "手枪 A1 弹速")
	near(P.spread, 0.6, 1e-6, "手枪 A1 更直")
	eq(int(P.special.lastN), 3, "手枪 A2 最后 3 发加伤")
	eq(int(P.special.burst), 1, "手枪 A3 双击")
	eq(SimWeapons.mag_size(h), 18, "手枪 A4 弹匣 +6")
	h = _ham(w, "pistol", 9, 0, 0)
	P = SimWeapons.params(h)
	eq(int(P.special.burst), 2, "手枪 A7 三连发")
	eq(int(P.special.heavyEvery), 5, "手枪 A6 重弹")
	eq(int(P.special.fanEvery), 3, "手枪 A9 扇射")
	h = _ham(w, "pistol", 0, 6, 0)
	P = SimWeapons.params(h)
	eq(P.pierce, 2, "手枪 B3 穿透 2")
	near(P.crit, 0.15, 1e-6, "手枪 B5 暴击")
	eq(int(P.special.rico), 1, "手枪 B6 弹射")
	h = _ham(w, "pistol", 0, 9, 0)
	P = SimWeapons.params(h)
	eq(int(P.special.critEvery), 6, "手枪 B9 每 6 发必暴击")
	eq(P.wp, 1, "手枪 B9 穿薄障碍")
	h = _ham(w, "pistol", 0, 0, 3)
	near(SimWeapons.light_cos(h), 0.82 - 0.04, 1e-6, "手枪 C1 光束更宽")
	near(SimWeapons.light_range(h), 540.0 * 1.3, 1e-3, "手枪 C1 手电更远")
	near(float(SimWeapons.params(h).special.litDmg), 0.15, 1e-6, "手枪 C3 照到加伤")


func test_ak_params() -> void:
	var w := make_world("slice", 1, 1, 0)
	var h := _ham(w, "ak47", 0, 6, 0)
	eq(SimWeapons.mag_size(h), 50, "AK B4 弹匣 30+10+10")
	near(SimWeapons.params(h).rl, 0.75, 1e-6, "AK B2 换弹")
	eq(int(SimWeapons.params(h).special.twin), 1, "AK B3 双管")
	eq(int(SimWeapons.params(h).special.fanEvery), 6, "AK B6 扇形弹")
	h = _ham(w, "ak47", 0, 0, 5)
	var P := SimWeapons.params(h)
	near(P.spread, 0.5, 1e-6, "AK C1 散布减半")
	near(P.eff, 1.7, 1e-6, "AK C3 远距离不掉伤害")
	near(P.spd, 1.25, 1e-6, "AK C2 弹速")
	near(P.mark, 2.0, 1e-6, "AK C5 标记")
	h = _ham(w, "ak47", 0, 0, 9)
	eq(int(SimWeapons.params(h).special.rico), 2, "AK C9 弹射 2 次")
	h = _ham(w, "ak47", 3, 0, 0)
	near(SimWeapons.params(h).ign, 0.15, 1e-6, "AK A1 燃烧几率")
	eq(SimWeapons.params(h).pierce, 1, "AK A3 穿甲")
	eq(int(SimWeapons.params(h).special.nadeEvery), 12, "AK A2 枪挂榴弹")


func test_shotgun_params() -> void:
	var w := make_world("slice", 1, 1, 0)
	var h := _ham(w, "shotgun", 6, 0, 0)
	var P := SimWeapons.params(h)
	eq(P.n, 4, "霰弹 A2+A4+A6 共多 4 弹丸")
	near(P.spread, 0.75, 1e-6, "霰弹 A1 更集中")
	eq(P.pierce, 1, "霰弹 A3 穿透")
	eq(int(P.special.heavyEvery), 3, "霰弹 A5 独头重弹")
	h = _ham(w, "shotgun", 0, 4, 0)
	P = SimWeapons.params(h)
	near(P.ign, 0.2, 1e-6, "霰弹 B1 点燃几率")
	near(P.ignK, 1.5, 1e-6, "霰弹 B3 燃烧伤害")
	near(float(P.special.fireField), 140.0, 1e-6, "霰弹 B2 小火苗")
	check(P.special.has("burnSlow"), "霰弹 B4 点燃减速")
	h = _ham(w, "shotgun", 0, 0, 6)
	P = SimWeapons.params(h)
	near(P.kb, 1.5, 1e-6, "霰弹 C1 击退")
	near(P.stun, 0.2, 1e-6, "霰弹 C2 眩晕")
	check(P.special.has("wallSlam"), "霰弹 C6 撞墙眩晕")


func test_fire_spawns_bullets_and_uses_ammo() -> void:
	var w := make_world("slice", 3, 0, 0, [{"team": "blue", "ctl": "player", "name": "P"}])
	var h := w.hams[0]
	h.weapon_id = "shotgun"
	h.evo_key = ""
	h.ammo = SimWeapons.mag_size(h)
	var before := h.ammo
	h.inp.fire = true
	h.fire_cd = 0.0
	SimWeapons.try_fire(w, h, true)
	eq(w.bullets.size(), 8, "霰弹一枪 8 颗弹丸")
	eq(h.ammo, before - 1, "消耗 1 发")


func test_damage_falloff() -> void:
	var w := make_world("slice", 3, 0, 1, [{"team": "blue", "ctl": "player", "name": "P"}])
	var h := w.hams[0]
	var foe := w.hams[1]
	var b := w.new_bullet("trc", h, 0, 0, 16, 0, 1000, 10.0, 680.0)
	b.eff = 0.6
	b.min_f = 0.55
	b.x = 680.0
	b.y = 0.0
	foe.hp = 100.0
	foe.iframes = 0.0
	SimWeapons.on_bullet_hit(w, b, foe)
	near(100.0 - foe.hp, 5.5, 0.01, "射程尽头伤害降到 55%")


func test_pvp_hit_cap() -> void:
	var w := make_world("slice", 3, 0, 1, [{"team": "blue", "ctl": "player", "name": "P"}])
	var h := w.hams[0]
	var foe := w.hams[1]
	foe.iframes = 0.0
	foe.hp = foe.max_hp
	w.deal_dmg(foe, 9999.0, {"team": "blue", "owner": h, "x": 0, "y": 0})
	near(foe.hp, foe.max_hp * 0.45, 0.01, "单发最多打掉 55% 生命")
