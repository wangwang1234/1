extends "res://tests/test_case.gd"
## 武器与进化数值：对照原型 n2c.js 的 evp() 手算结果。


func _ham(w: SimWorld, weapon: String, a: int, b: int, c: int) -> SimHamster:
	var h := w.hams[0]
	h.weapon_id = weapon
	h.evo = {"a": a, "b": b, "c": c}
	h.evo_key = ""
	return h


func test_pistol_params() -> void:
	var w := make_world("slice", 1, 1, 0)
	var h := _ham(w, "pistol", 4, 0, 0)
	var P := SimWeapons.params(h)
	near(P.rate, 1.28, 1e-6, "手枪 A4 射速倍率")
	near(P.spd, 1.25, 1e-6, "手枪 A≥3 弹速")
	eq(SimWeapons.mag_size(h), 12, "手枪 A4 弹匣")
	h = _ham(w, "pistol", 6, 0, 0)
	eq(SimWeapons.mag_size(h), 16, "手枪 A6 弹匣 +4")
	h = _ham(w, "pistol", 0, 6, 0)
	P = SimWeapons.params(h)
	eq(P.pierce, 2, "手枪 B6 穿透")
	near(P.dmg, 1.42, 1e-6, "手枪 B6 伤害")
	h = _ham(w, "pistol", 0, 9, 0)
	near(SimWeapons.params(h).crit, 0.25, 1e-6, "手枪 B9 暴击")
	h = _ham(w, "pistol", 0, 0, 3)
	near(SimWeapons.light_cos(h), 0.82 - 0.06, 1e-6, "手枪 C3 光束更宽")
	near(SimWeapons.light_range(h), 540.0 * 1.3, 1e-3, "手枪 C3 手电更远")


func test_ak_params() -> void:
	var w := make_world("slice", 1, 1, 0)
	var h := _ham(w, "ak47", 0, 6, 0)
	# magMul = 1 + 0.12*6 + 0.2 = 1.92 -> 30*1.92 = 57.6 -> 58
	eq(SimWeapons.mag_size(h), 58, "AK B6 弹匣")
	near(SimWeapons.params(h).rl, 0.85, 1e-6, "AK B≥3 换弹")
	h = _ham(w, "ak47", 0, 0, 5)
	var P := SimWeapons.params(h)
	near(P.spread, 1.0 - 0.35, 1e-6, "AK C5 散布")
	near(P.eff, 1.4, 1e-6, "AK C5 有效射程")
	near(P.spd, 1.2, 1e-6, "AK C≥3 弹速")
	h = _ham(w, "ak47", 0, 0, 9)
	near(SimWeapons.params(h).spread, 0.37, 1e-6, "AK C9 散布 1-0.63")
	h = _ham(w, "ak47", 3, 0, 0)
	near(SimWeapons.params(h).ign, 0.15, 1e-6, "AK A3 燃烧几率")


func test_shotgun_params() -> void:
	var w := make_world("slice", 1, 1, 0)
	var h := _ham(w, "shotgun", 6, 0, 0)
	var P := SimWeapons.params(h)
	eq(P.n, 2, "霰弹 A6 多 2 弹丸")
	near(P.spread, 1.0 - 0.24, 1e-6, "霰弹 A6 更集中")
	h = _ham(w, "shotgun", 0, 4, 0)
	P = SimWeapons.params(h)
	near(P.ign, 0.15 + 0.28, 1e-6, "霰弹 B4 点燃几率")
	near(P.ignK, 1.5, 1e-6, "霰弹 B≥3 燃烧伤害")
	h = _ham(w, "shotgun", 0, 0, 6)
	P = SimWeapons.params(h)
	near(P.kb, 1.0 + 0.9 + 0.3, 1e-6, "霰弹 C6 击退")
	near(P.stun, 0.25, 1e-6, "霰弹 C≥3 眩晕")


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
