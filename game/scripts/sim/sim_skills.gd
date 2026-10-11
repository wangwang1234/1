class_name SimSkills
extends RefCounted
## 右键武器专属技能（2026-10-11 导演定：右键 = 武器专属技能，配合武器精简到 10 把）。
## 每把武器在 weapons.json 里有一个 skill：type 决定效果，cd 冷却秒数，其余是参数；aiRange 是 AI 在多远时会用。
##   burst    三连速射：立刻连开 n 枪，不耗子弹（手枪）
##   frenzy   扫射：time 秒内射速 × rateK（冲锋枪）
##   nade     枪挂榴弹：朝准星打出一颗榴弹（AK）
##   spin     满膛火力：瞬间转满，time 秒内不耗子弹（加特林）
##   slug     独头弹：一发远射程重弹（霰弹枪）
##   mark     标记射击：一发加伤的标记弹，打中的敌人全队可见 mark 秒（狙击枪）
##   salvo    三联火箭：扇形打出 n 发小火箭（火箭筒）
##   slash    拔刀斩：朝准星冲刺，砍中路上所有敌人（武士刀）
##   firewall 火墙：前方一排燃烧带（喷火器）
##   overload 过载光束：time 秒内光束伤害 × dmgK、穿透、不耗电，松手也照射（激光枪）


static func def(h: SimHamster) -> Dictionary:
	return h.weapon().get("skill", {})


static func ready(h: SimHamster) -> bool:
	return h.alive and h.skill_cd <= 0.0 and not def(h).is_empty()


static func tick(w: SimWorld, h: SimHamster, dt: float) -> void:
	h.skill_cd = maxf(0.0, h.skill_cd - dt)
	for k in ["sk_free_t", "sk_rate_t", "sk_spin_t", "sk_slash_t", "sk_od_t"]:
		var v: float = h.get(k)
		if v > 0.0:
			h.set(k, maxf(0.0, v - dt))
	if h.sk_spin_t > 0.0:
		h.spin = 1.0
	if h.inp.skill:
		h.inp.skill = false
		if ready(h) and h.stun_t <= 0.0 and h.frozen_until <= w.t and h.blind_t <= 0.0:
			use(w, h)


static func use(w: SimWorld, h: SimHamster) -> bool:
	var D := def(h)
	if D.is_empty():
		return false     # 没开放的武器没有技能
	var W := h.weapon()
	var P := SimWeapons.params(h)
	var co := cos(h.aim)
	var si := sin(h.aim)
	var mag := int(W.get("mag", 0))
	match String(D.type):
		"burst":
			if h.reload_t > 0.0 or (mag > 0 and h.ammo <= 0):
				return false
			h.sk_free_t = float(D.n) * float(D.get("gap", 0.07)) + 0.25
			SimWeapons.fire(w, h, true)
			h.burst_n = int(D.n) - 1
			h.burst_t = float(D.get("gap", 0.07))
		"frenzy":
			h.sk_rate_t = float(D.time)
			h.sk_rate_k = float(D.rateK)
		"nade":
			var d := float(D.range)
			var tx := h.x + co * d
			var ty := h.y + si * d
			if h.inp.has_aim_point and Vector2(h.inp.aim_x - h.x, h.inp.aim_y - h.y).length() < d:
				tx = h.inp.aim_x
				ty = h.inp.aim_y
			w.throw_lob_from(h.x, h.y, h.r, h.team, h, "bomb", tx, ty, {"sp": float(D.spd), "fuse": float(D.fuse), "aoe": float(D.aoe),
				"dmg": float(D.dmg) * float(h.st.dmg), "kb": 180.0})
		"spin":
			h.spin = 1.0
			h.sk_spin_t = float(D.time)
			h.sk_free_t = float(D.time)
		"slug":
			var b := _bullet(w, h, "snipe", float(D.dmg) * float(h.st.dmg), float(D.spd), float(D.range))
			b.pierce = int(D.get("pierce", 0))
			b.kb = float(D.get("kb", 200))
			b.r = 8.0
			b.big = true
		"mark":
			var dmg := float(W.dmg) * float(P.dmg) * float(h.st.dmg) * float(D.dmgK)
			var b2 := _bullet(w, h, "snipe", dmg, float(W.spd) * float(P.spd), float(W.range) * float(P.range))
			b2.fx.mark = float(D.mark)
			b2.r = 6.0
			b2.big = true
		"salvo":
			var a0 := h.aim
			var n := int(D.n)
			h.sk_dmg_k = float(D.dmgK)
			h.sk_free_t = maxf(h.sk_free_t, 0.05)
			var keep_cd := h.fire_cd
			var keep_ammo := h.ammo
			for i in n:
				h.aim = a0 + (float(i) - (n - 1) * 0.5) * float(D.spread)
				SimWeapons.fire(w, h, true)
			h.aim = a0
			h.sk_dmg_k = 1.0
			h.fire_cd = keep_cd
			h.ammo = keep_ammo
		"slash":
			if h.roll_t > 0.0:
				return false
			var keep_dash := h.dash_cd
			var mx := h.inp.mx
			var my := h.inp.my
			h.inp.mx = 0.0     # 拔刀斩一律朝准星冲
			h.inp.my = 0.0
			SimHamsterLogic.start_dash(w, h)
			h.inp.mx = mx
			h.inp.my = my
			h.dash_cd = keep_dash      # 不占翻滚冷却
			h.dash_spd = float(D.dashSpd)
			h.sk_slash_t = float(w.R.hamster.rollTime)
			h.sk_slash_k = float(D.dmgK)
		"firewall":
			for i in int(D.n):
				var dd := float(D["from"]) + float(i) * float(D.gap)
				var fx := h.x + co * dd
				var fy := h.y + si * dd
				if w.map.point_solid(fx, fy, 1.0) != null:
					break      # 火墙到墙为止
				w.add_fire(fx, fy, float(D.r), float(D.life), h.team, h, float(D.dps) * float(h.st.dmg), "skill")
		"overload":
			h.sk_od_t = float(D.time)
			h.sk_od_k = float(D.dmgK)
		_:
			return false
	h.skill_cd = float(D.cd)
	h.reveal_t = maxf(h.reveal_t, float(Data.rule("hamster.revealOnFire", 0.45)))
	w.noise(h.x, h.y, "gun", 1.0, h)
	w.emit({"t": "skill", "id": h.id, "skill": String(D.type), "name": String(D.get("name", "")), "x": h.x, "y": h.y, "aim": h.aim, "team": h.team})
	return true


static func _bullet(w: SimWorld, h: SimHamster, kind: String, dmg: float, spd: float, rng_: float) -> SimBullet:
	## 技能弹：结构和普通子弹一样（进化效果字典给全默认值），从枪口打出
	var P := SimWeapons.params(h)
	var co := cos(h.aim)
	var si := sin(h.aim)
	var b := w.new_bullet(kind, h, h.x + co * h.r * 0.8, h.y + si * h.r * 0.8, h.r + h.z, h.aim, spd, dmg, rng_)
	b.weapon = h.weapon_id
	b.fx = {"src": h.weapon_id, "lv": [h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c")], "P": P, "S": {},
		"ign": 0.0, "ignK": 1.0, "slow": 0.0, "stun": 0.0, "mark": 0.0, "crit": 0.0, "force": false, "expl": false, "skill": true}
	w.bullets.append(b)
	w.emit({"t": "fire", "id": h.id, "weapon": h.weapon_id, "kind": "bullet", "x": h.x, "y": h.y, "gx": b.x, "gy": b.y, "gh": h.r + h.z,
		"aim": h.aim, "n": 1, "team": h.team, "extra": true, "mode": -1, "side": 0, "skill": true})
	return b


static func ai_want(w: SimWorld, h: SimHamster, tg: SimEntity, d: float) -> bool:
	## AI 什么时候放技能：目标在 aiRange 以内（拔刀斩 / 火墙这种近身技能要更近），冷却好了
	if not ready(h) or tg == null:
		return false
	var D := def(h)
	return d < float(D.get("aiRange", 400)) + tg.r
