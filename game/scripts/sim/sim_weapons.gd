class_name SimWeapons
extends RefCounted
## 武器开火、进化数值、命中效果。对应原型 n2c.js 的 evp / fireWeapon / onBulletHit / evoTick。
## 进化数值全部来自 evolutions.json 的 effects。

const PK := ["a", "b", "c"]


static func params(h: SimHamster) -> Dictionary:
	var key := "%s_%d_%d_%d" % [h.weapon_id, h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c")]
	if key == h.evo_key:
		return h.evo_params
	h.evo_key = key
	h.evo_params = _compute_params(h)
	return h.evo_params


static func _compute_params(h: SimHamster) -> Dictionary:
	var P := {
		"rate": 1.0, "dmg": 1.0, "spread": 1.0, "n": 0, "pierce": 0, "bounce": 0, "bounceK": 0.85,
		"spd": 1.0, "kb": 1.0, "range": 1.0, "eff": 1.0, "magMul": 1.0, "magAdd": 0, "rl": 1.0,
		"crit": 0.0, "ign": 0.0, "ignK": 1.0, "slow": 0.0, "stun": 0.0, "mark": 0.0,
		"lightRange": 1.0, "lightCos": 0.0, "aoe": 1.0, "aoeDmg": 1.0, "special": {},
	}
	var paths: Array = Data.evolutions().get("paths", {}).get(h.weapon_id, [])
	for i in mini(3, paths.size()):
		var L := h.evo_lv(PK[i])
		if L <= 0:
			continue
		var eff: Dictionary = paths[i].get("effects", {})
		if eff.is_empty():
			continue
		for key in eff.get("base", {}):
			P[key] = float(eff.base[key])
		var floor_ := float(eff.get("spreadFloor", 0.0))
		for key in eff.get("perLevel", {}):
			var v := float(eff.perLevel[key])
			match key:
				"spreadMul":
					P.spread *= maxf(floor_, 1.0 + v * L)
				"rlMul":
					P.rl *= maxf(0.2, 1.0 + v * L)
				_:
					P[key] = float(P.get(key, 0.0)) + v * L
		var at: Dictionary = eff.get("at", {})
		var levels := at.keys()
		levels.sort_custom(func(a, b): return int(a) < int(b))
		for lv in levels:
			if L < int(lv):
				continue
			var m: Dictionary = at[lv]
			for key in m:
				var v: Variant = m[key]
				match key:
					"spdMul":
						P.spd *= float(v)
					"rlMul":
						P.rl *= float(v)
					"ignK":
						P.ignK = float(v)
					"special":
						for sk in v:
							P.special[sk] = v[sk]
					_:
						P[key] = float(P.get(key, 0.0)) + float(v)
	P.n = int(P.n)
	P.pierce = int(P.pierce)
	P.magAdd = int(P.magAdd)
	P.bounce = int(P.bounce)
	return P


static func special(h: SimHamster, key: String) -> Variant:
	return params(h).special.get(key, null)


static func mag_size(h: SimHamster) -> int:
	var W := h.weapon()
	if int(W.get("mag", 0)) <= 0:
		return 0
	var P := params(h)
	return maxi(1, roundi(float(W.mag) * float(P.magMul)) + int(P.magAdd))


static func reload_time(h: SimHamster) -> float:
	var W := h.weapon()
	return float(W.get("rl", 1.0)) * float(h.st.get("rl", 1.0)) * float(params(h).rl)


static func range_of(h: SimHamster) -> float:
	var W := h.weapon()
	if W.get("kind", "") == "melee":
		return float(W.get("reach", 88))
	return float(W.get("range", 0.0)) * float(params(h).range)


static func light_range(h: SimHamster) -> float:
	var r := float(Data.rule("vision.lightRange", 540))
	if h.tal.has("nightvision"):
		r *= float(Data.rule("vision.nightvisionLightMul", 1.6))
	r *= float(h.st.get("lightK", 1.0))
	r *= float(params(h).lightRange)
	return r


static func light_cos(h: SimHamster) -> float:
	return float(Data.rule("vision.lightCos", 0.82)) - float(Data.rule("vision.lightWideCos", 0.05)) * float(h.st.get("wideK", 0)) + float(params(h).lightCos)


static func move_mul(h: SimHamster) -> float:
	var W := h.weapon()
	var m := 1.0
	var firing := h.inp.fire and h.reload_t <= 0.0
	if W.has("slow") and firing:
		m *= float(W.slow)
	return m


static func muzzle_r(id: String) -> float:
	return float(Data.evolutions().get("muzzleOffsetR", {}).get(id, 2.0))


# ---------------------------------------------------------------------------
# 开火
# ---------------------------------------------------------------------------

static func fire(w: SimWorld, h: SimHamster, extra: bool = false) -> void:
	var id := h.weapon_id
	var W := h.weapon()
	var st := h.st
	var P := params(h)
	var S: Dictionary = P.special
	var a := h.evo_lv("a")
	var b := h.evo_lv("b")
	var c := h.evo_lv("c")
	var a0 := h.aim
	var co := cos(a0)
	var si := sin(a0)
	var rx := -si
	var ry := co
	var R := h.r
	var gh := R + h.z
	var berserk := h.tal.has("berserk") and h.hp < h.max_hp * 0.4
	var rate := float(W.rate) * float(st.rate) * float(P.rate) * (1.3 if berserk else 1.0)
	if not extra:
		h.fire_cd = 1.0 / rate
	var pause := w.t - h.last_shot_t
	var dmg := float(W.dmg) * float(st.dmg) * float(P.dmg) * (1.4 if berserk else 1.0)
	var crit_add := float(P.crit)
	var force_crit := false
	var pierce := int(W.get("pierce", 0)) + int(P.pierce)
	if S.has("rampDmg"):
		dmg *= 1.0 + minf(float(S.rampMax), h.ramp * float(S.rampDmg))
	if S.has("firstShot") and pause > float(S.firstShot):
		dmg *= float(S.firstDmg)
		pierce += int(S.firstPierce)
	h.last_shot_t = w.t
	h.shot_n += 1
	if id == "ak47" or id == "autoshot":
		h.ramp = minf(h.ramp + 1.0, 40.0)
	var use := int(W.get("mag", 0)) > 0
	if use and h.tal.has("bottomless") and w.rnd() < 0.35:
		use = false
	if use:
		h.ammo -= 1
	var so := float(W.get("muzzleSide", 0.14))
	var ln := muzzle_r(id)
	var gx := h.x + co * R * ln + rx * R * so
	var gy := h.y + si * R * ln + ry * R * so
	var bx := h.x + co * R * 0.8 + rx * R * so
	var by := h.y + si * R * 0.8 + ry * R * so
	var rng_ := float(W.get("range", 600)) * float(P.range)
	var shotty := id == "shotgun" or id == "autoshot"
	var n := int(W.get("n", 1)) + int(st.get("multi", 0)) + int(P.n)
	var base_sp: float
	if shotty:
		base_sp = float(W.spread) * float(P.spread)
	else:
		base_sp = (float(W.spread) + h.bloom) * float(P.spread)
	var sp := base_sp + 0.06 * (n - 1) if (n > 1 and not shotty) else base_sp
	var kind := "pel" if shotty else ("snipe" if id == "sniper" or id == "amr" else "trc")
	var mode := -1
	if S.has("ammoCycle"):
		mode = h.shot_n % int(S.ammoCycle)
	var eff := 1.0
	if W.has("eff"):
		eff = minf(1.0, float(W.eff) * float(P.eff))
	for i in n:
		var off: float
		if n == 1:
			off = w.rand(-sp, sp)
		else:
			off = (float(i) / float(n - 1) - 0.5) * 2.0 * sp + w.rand(-0.03, 0.03)
		var bl := w.new_bullet(kind, h, bx, by, gh, a0 + off, float(W.spd) * float(P.spd) * w.rand(0.95, 1.05), dmg, rng_)
		bl.eff = eff
		bl.min_f = float(W.get("minF", 1.0))
		bl.pierce = pierce + (int(S.get("cyclePierce", 0)) if mode == 1 else 0)
		bl.kb = float(W.kb) * float(P.kb)
		bl.r = 5.0 if kind == "snipe" else float(Data.rule("combat.bulletRadius", 4.5))
		bl.bounce = int(W.get("bounce", 0)) + int(P.bounce)
		bl.bounce_k = float(P.bounceK)
		bl.weapon = id
		bl.fx = {
			"src": id, "lv": [a, b, c],
			"ign": 1.0 if mode == 0 else float(P.ign), "ignK": float(P.ignK),
			"slow": float(P.slow), "stun": float(P.stun), "mark": float(P.mark),
			"crit": crit_add, "force": force_crit, "expl": mode == 2,
		}
		w.bullets.append(bl)
	if W.has("bloom"):
		h.bloom = minf(float(W.bmax), h.bloom + float(W.bloom))
	h.reveal_t = float(Data.rule("hamster.revealOnFire", 0.45))
	w.noise(h.x, h.y, "gun", 1.0, h)
	var skb := float(W.get("selfKb", 0.0))
	if skb > 0.0:
		h.vx -= co * skb
		h.vy -= si * skb
	if S.has("fireField"):
		var d := float(S.fireField)
		w.add_fire(h.x + co * d, h.y + si * d, float(S.fieldR), float(S.fieldLife), h.team, h, float(S.fieldDps))
	if S.has("burst") and not extra:
		h.burst_n = int(S.burst)
		h.burst_t = float(S.get("burstGap", 0.07))
	h.heat = minf(1.0, h.heat + float(Data.rule("hamster.heatPerShot", 0.08)))
	w.emit({"t": "fire", "id": h.id, "weapon": id, "x": h.x, "y": h.y, "gx": gx, "gy": gy, "gh": gh, "aim": a0, "n": n, "team": h.team, "extra": extra, "mode": mode})


static func try_fire(w: SimWorld, h: SimHamster, can_shoot: bool) -> void:
	if h.inp.fire and h.fire_cd <= 0.0 and can_shoot:
		fire(w, h)
	elif h.inp.fire and h.fire_cd <= 0.0 and h.reload_t <= 0.0 and h.roll_t <= 0.0 and h.ammo <= 0 and h.ctl == "player":
		w.emit({"t": "empty", "id": h.id})
		h.fire_cd = 0.25


# ---------------------------------------------------------------------------
# 每帧进化效果（原型 evoTick 的子集：手枪连发、AK 压制计数、手枪晃瞎）
# ---------------------------------------------------------------------------

static func evo_tick(w: SimWorld, h: SimHamster, dt: float) -> void:
	var still := Vector2(h.vx, h.vy).length() < 25.0 and h.inp.ml < 0.1
	h.steady_t = h.steady_t + dt if still else 0.0
	if not h.inp.fire:
		if w.t - h.last_shot_t > 0.6:
			h.ramp = 0.0
	if h.burst_n > 0:
		h.burst_t -= dt
		if h.ammo <= 0:
			h.burst_n = 0
		elif h.burst_t <= 0.0:
			h.burst_n -= 1
			h.burst_t = float(special(h, "burstGap") if special(h, "burstGap") != null else 0.07)
			fire(w, h, true)
	var dz: Variant = special(h, "dazzle")
	if dz != null:
		h.dazzle_t -= dt
		if h.dazzle_t <= 0.0:
			var S: Dictionary = params(h).special
			h.dazzle_t = float(S.get("dazzleEvery", 0.3))
			dazzle(w, h, S)


static func dazzle(w: SimWorld, h: SimHamster, S: Dictionary) -> void:
	var R := float(S.dazzle)
	var cs := cos(h.aim)
	var sn := sin(h.aim)
	for e: SimEntity in w.all_targets():
		if e.team == h.team:
			continue
		var dx := e.x - h.x
		var dy := e.y - h.y
		var d := sqrt(dx * dx + dy * dy)
		if d > R or d < 1.0:
			continue
		if (dx * cs + dy * sn) / d < float(S.get("dazzleCos", 0.8)):
			continue
		if not w.map.has_los(h.x, h.y, e.x, e.y):
			continue
		if e.dazzle_until > w.t:
			continue
		e.dazzle_until = w.t + float(S.get("dazzleCd", 2.0))
		if e is SimHamster:
			var eh := e as SimHamster
			if eh.ctl == "player":
				w.emit({"t": "blind", "id": eh.id, "amount": 0.35})
			else:
				eh.blind_t = maxf(eh.blind_t, float(S.get("dazzleBlind", 0.7)))
		else:
			w.stun_e(e, float(S.get("dazzleStun", 0.5)))
		w.emit({"t": "pop", "x": e.x, "y": e.y, "h": e.r * 2.6, "text": "晃！", "color": "#fff6c2", "size": 13})


# ---------------------------------------------------------------------------
# 命中
# ---------------------------------------------------------------------------

static func on_bullet_hit(w: SimWorld, b: SimBullet, e: SimEntity) -> void:
	var dm := b.dmg
	if b.eff < 1.0:
		var d := Vector2(b.x - b.x0, b.y - b.y0).length()
		var e0 := b.max_d * b.eff
		if d > e0:
			dm *= lerpf(1.0, b.min_f, clampf((d - e0) / maxf(1.0, b.max_d - e0), 0.0, 1.0))
	var f := b.fx
	var o := b.owner
	var lv: Array = f.get("lv", [0, 0, 0])
	var src := String(f.get("src", ""))
	if o != null:
		var S: Dictionary = params(o).special if o.weapon_id == src else {}
		if S.has("litDmg") and w.is_visible_to(o.team, e):
			dm *= 1.0 + float(S.litDmg)
		if S.has("structDmg") and (e.kind == "turret" or e.kind == "base"):
			dm *= 1.0 + float(S.structDmg)
	var dealt := w.deal_dmg(e, dm, {"team": b.team, "owner": o, "by": b.by, "x": b.x, "y": b.y, "critAdd": float(f.get("crit", 0.0)), "forceCrit": bool(f.get("force", false))})
	if dealt > 0.0 and o != null:
		w.emit({"t": "hitmark", "id": o.id, "target": e.id, "kill": e.dead or (e is SimHamster and not (e as SimHamster).alive)})
	var l := maxf(0.001, Vector2(b.vx, b.vy).length())
	var ux := b.vx / l
	var uy := b.vy / l
	w.knock(e, ux, uy, b.kb)
	var big := b.kind == "snipe" or b.kind == "trc" or b.kind == "seed"
	w.emit({"t": "bullet_hit", "x": b.x, "y": b.y, "h": b.h, "team": b.team, "kind": b.kind, "big": big, "target": e.id})
	if o != null and o.is_alive():
		if float(f.get("ign", 0.0)) > 0.0 and w.rnd() < float(f.ign):
			e.burn_t = maxf(e.burn_t, float(Data.rule("combat.burnTime", 2.2)))
			e.burn_by = o
			e.burn_k = float(f.get("ignK", 1.0))
			if src == "shotgun" and int(lv[1]) >= 6:
				w.slow_e(e, 1.0)
		if float(f.get("slow", 0.0)) > 0.0:
			w.slow_e(e, float(f.slow))
		if float(f.get("stun", 0.0)) > 0.0:
			w.stun_e(e, float(f.stun))
		if float(f.get("mark", 0.0)) > 0.0:
			w.mark_e(e, o.team, float(f.mark))
		if float(o.st.get("recon", 0.0)) > 0.0:
			w.mark_e(e, o.team, float(o.st.recon))
		if bool(f.get("expl", false)):
			var S2: Dictionary = params(o).special
			w.mini_blast(b.x, b.y, float(S2.get("blastR", 45)), dm * float(S2.get("blastDmg", 0.5)), b.team, o)
		if src == "shotgun" and o.weapon_id == "shotgun":
			var S3: Dictionary = params(o).special
			if S3.has("pointBlank") and Vector2(e.x - o.x, e.y - o.y).length() < float(S3.pointBlank) + e.r:
				w.knock(e, ux, uy, float(S3.pbKb))
				w.stun_e(e, float(S3.pbStun))
		if float(o.st.get("frost", 0)) > 0.0:
			var fr := float(Data.rule("abilities.frost.frostBase", 0.8)) + float(Data.rule("abilities.frost.frostPer", 0.3)) * float(o.st.frost)
			w.slow_e(e, fr)
		if float(o.st.get("chain", 0.0)) > 0.0 and w.rnd() < float(o.st.chain):
			w.chain_lightning(e, b.dmg * float(Data.rule("abilities.chain.chainDmg", 0.45)), o)
