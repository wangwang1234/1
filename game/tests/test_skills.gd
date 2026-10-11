extends "res://tests/test_case.gd"
## 右键武器专属技能（2026-10-11）：10 把开放武器每把都有技能、放出来真的有效果、进冷却；AI 会在对局里用。


func _setup(weapon: String, dist: float = 240.0) -> Array:
	var w := make_world("slice", 31, 0, 0, [{"team": "blue", "ctl": "player", "name": "测"}])
	for e in w.mobs:
		e.dead = true
	for m in w.minions:
		m.dead = true
	var h := w.hams[0]
	h.weapon_id = weapon
	h.evo = {"a": 0, "b": 0, "c": 0}
	SimHamsterLogic.calc_stats(h)
	h.ammo = SimWeapons.mag_size(h)
	h.x = 2200.0
	h.y = 1548.0
	h.px = h.x
	h.py = h.y
	h.aim = 0.0
	h.inp.aim = 0.0
	h.iframes = 999.0
	var t := w.spawn_minion("red", w.map.lanes.keys()[0])
	t.x = h.x + dist
	t.y = h.y
	t.px = t.x
	t.py = t.y
	t.stun = 99.0
	t.hp = 99999.0
	t.max_hp = 99999.0
	return [w, h, t]


func _step(w: SimWorld, h: SimHamster, sec: float, fire := false) -> Array:
	var evs: Array = []
	for i in int(sec * 60.0):
		h.inp.aim = 0.0
		h.inp.fire = fire
		w.step(1.0 / 60.0)
		evs.append_array(w.events)
		w.events.clear()
	return evs


func test_every_open_weapon_has_a_skill() -> void:
	for id in Data.active_weapons():
		var D: Dictionary = Data.weapon(id).get("skill", {})
		check(not D.is_empty(), "%s 要有右键技能" % id)
		check(float(D.get("cd", 0)) >= 4.0, "%s 技能要有冷却" % id)
		check(String(D.get("name", "")) != "" and String(D.get("desc", "")) != "", "%s 技能要有名字和说明" % id)


func test_skills_take_effect_and_go_on_cooldown() -> void:
	for id in Data.active_weapons():
		var r := _setup(id, 150.0 if id in ["katana", "flame"] else 240.0)
		var w: SimWorld = r[0]
		var h: SimHamster = r[1]
		var t: SimMinion = r[2]
		var ammo0 := h.ammo
		var lobs0 := w.lobs.size()
		var fires0 := w.fires.size()
		h.inp.skill = true
		var evs := _step(w, h, 0.05)
		var D: Dictionary = SimSkills.def(h)
		check(h.skill_cd > float(D.cd) - 0.5, "%s 放完进冷却（%.2f）" % [id, h.skill_cd])
		check(evs.any(func(e): return e.t == "skill"), "%s 发出技能事件" % id)
		match String(D.type):
			"burst":
				evs.append_array(_step(w, h, 0.4))
				var shots := evs.filter(func(e): return e.t == "fire").size()
				check(shots >= int(D.n), "手枪三连速射要连开 %d 枪（实际 %d）" % [int(D.n), shots])
				eq(h.ammo, ammo0, "三连速射不耗子弹")
			"frenzy":
				check(h.sk_rate_t > 0.0 and h.sk_rate_k > 1.0, "扫射提高射速")
			"nade":
				check(w.lobs.size() > lobs0, "打出榴弹")
			"spin":
				eq(h.spin, 1.0, "加特林瞬间满转")
				_step(w, h, 0.8, true)
				eq(h.ammo, ammo0, "满膛火力期间不耗子弹")
			"slug", "mark":
				_step(w, h, 0.6)
				check(t.hp < t.max_hp, "%s 技能弹打中目标" % id)
				if String(D.type) == "mark":
					check(t.mark_team == "blue" and t.mark_until > w.t, "标记射击：目标被标记")
			"salvo":
				var rockets := w.bullets.filter(func(b): return b.kind == "rocket").size()
				check(rockets >= int(D.n), "三联火箭打出 %d 发（实际 %d）" % [int(D.n), rockets])
			"slash":
				_step(w, h, 0.4)
				check(t.hp < t.max_hp, "拔刀斩砍中路上的敌人")
				check(h.x > 2200.0 + 40.0, "拔刀斩向前冲")
			"firewall":
				check(w.fires.size() >= fires0 + 3, "火墙留下一排燃烧带")
			"overload":
				_step(w, h, 0.6)     # 不按左键也在照射
				check(t.hp < t.max_hp, "过载光束不用按左键也会照射伤害")
		# 冷却中再按没反应
		var cd := h.skill_cd
		h.inp.skill = true
		var evs2 := _step(w, h, 0.05)
		check(not evs2.any(func(e): return e.t == "skill"), "%s 冷却中不能再放" % id)
		check(h.skill_cd < cd, "冷却在走")
		w.dispose()


func test_weapon_swap_keeps_skill_quick() -> void:
	var r := _setup("sniper")
	var w: SimWorld = r[0]
	var h: SimHamster = r[1]
	h.inp.skill = true
	_step(w, h, 0.05)
	check(h.skill_cd > 5.0, "前提：狙击技能在冷却")
	h.choices = [{"t": "weap", "id": "ak47"}]
	h.pending = 1
	SimCards.apply(w, h, 0)
	check(h.skill_cd <= 2.0, "换枪后 2 秒内就能放新武器的技能")
	w.dispose()


func test_ai_uses_skills_in_matches() -> void:
	var w := make_world("slice", 32, 3, 3)
	var n := 0
	for i in 60 * 90:
		w.step(1.0 / 60.0)
		for e in w.events:
			if e.t == "skill":
				n += 1
		w.events.clear()
	check(n >= 3, "AI 对局 90 秒里要用几次右键技能（实际 %d）" % n)
	w.dispose()
