class_name SimWeapons
extends RefCounted
## 武器开火、进化数值、命中效果（子弹类武器）。对应原型 n2c.js 的 evp / fireWeapon / tryFire / onBulletHit / evoTick / startDash / onKill。
## 进化数值全部来自 evolutions.json 的 effects（格式见 _effectsDoc）；火箭 / 武士刀 / 喷火 / 榴弹 / 电磁 / 激光的开火方式在 SimWeaponModes。

const PK := ["a", "b", "c"]
## 默认值为 1 的参数（其余默认 0）
const ONE_KEYS := ["rate", "dmg", "spread", "spd", "kb", "range", "eff", "magMul", "rl", "ignK", "bounceK", "lightRange", "aoe", "aoeDmg",
	"spinMul", "dashCdMul", "execMul", "flipK", "arc", "charge", "cost"]
const ZERO_KEYS := ["n", "pierce", "bounce", "magAdd", "crit", "ign", "slow", "stun", "mark", "lightCos", "home", "homeAfter", "wp", "fireMove",
	"slowAdd", "execDmg", "execHp", "stillT", "stillDmg", "stillCrit", "deployNeed", "deployDmg", "aimLen", "scoutT", "altChance", "deDmg",
	"fragChance", "fragR", "stormCap", "stormRamp", "shockR", "deflect", "wave", "waveRange", "iaido", "burn", "heat", "fuse", "cluster",
	"railSlow", "focusCap", "focusStep", "sideK"]
const AT_MUL := {"spdMul": "spd", "rlMul": "rl", "spreadMul": "spread", "spinMul": "spinMul", "dashCdMul": "dashCdMul", "dmgMul": "dmg", "chargeMul": "charge"}
const AT_SET := ["ignK", "bounceK"]
const INT_KEYS := ["n", "pierce", "magAdd", "bounce", "wp"]

static var _cache := {}


static func clear_cache() -> void:
	_cache.clear()


static func params(h: SimHamster) -> Dictionary:
	var key := "%s_%d_%d_%d" % [h.weapon_id, h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c")]
	if key == h.evo_key:
		return h.evo_params
	h.evo_key = key
	h.evo_params = params_for(h.weapon_id, [h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c")])
	return h.evo_params


static func params_for(id: String, lv: Array) -> Dictionary:
	## 按武器 + 三条路线等级计算进化参数（结果缓存、只读：子弹在开火时把引用带走）
	var key := "%s_%d_%d_%d" % [id, int(lv[0]), int(lv[1]), int(lv[2])]
	if _cache.has(key):
		return _cache[key]
	var P := {"special": {}}
	for k in ONE_KEYS:
		P[k] = 1.0
	for k in ZERO_KEYS:
		P[k] = 0.0
	var paths: Array = Data.evolutions().get("paths", {}).get(id, [])
	for i in mini(3, paths.size()):
		var L := int(lv[i])
		if L <= 0:
			continue
		var eff: Dictionary = paths[i].get("effects", {})
		if eff.is_empty():
			continue
		for k in eff.get("base", {}):
			P[k] = float(eff.base[k])
		var sp_floor := float(eff.get("spreadFloor", 0.0))
		var rl_floor := float(eff.get("rlFloor", 0.2))
		for k in eff.get("perLevel", {}):
			var v := float(eff.perLevel[k])
			match k:
				"spreadMul":
					P.spread *= maxf(sp_floor, 1.0 + v * L)
				"rlMul":
					P.rl *= maxf(rl_floor, 1.0 + v * L)
				_:
					P[k] = float(P.get(k, 0.0)) + v * L
		var at: Dictionary = eff.get("at", {})
		var levels := at.keys()
		levels.sort_custom(func(x, y): return int(x) < int(y))
		for l in levels:
			if L < int(l):
				continue
			var m: Dictionary = at[l]
			for k in m:
				var v: Variant = m[k]
				if k == "special":
					for sk in v:
						P.special[sk] = v[sk]
				elif AT_MUL.has(k):
					P[AT_MUL[k]] = float(P.get(AT_MUL[k], 1.0)) * float(v)
				elif k in AT_SET:
					P[k] = float(v)
				else:
					P[k] = float(P.get(k, 0.0)) + float(v)
	for k in INT_KEYS:
		P[k] = int(P[k])
	P.make_read_only()
	_cache[key] = P
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
		var wr := float(params(h).waveRange)
		return wr if wr > 0.0 else float(W.get("reach", 88))
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


static func spin_mul(h: SimHamster) -> float:
	return maxf(float(h.weapon().get("spinMulMin", 0.3)), float(params(h).spinMul))


static func deploy_need(h: SimHamster) -> float:
	return float(h.weapon().get("deploy", 0.4)) + float(params(h).deployNeed)


static func is_deployed(h: SimHamster) -> bool:
	return h.weapon().has("deploy") and h.steady_t >= deploy_need(h)


static func move_mul(h: SimHamster) -> float:
	var W := h.weapon()
	var P := params(h)
	var m := 1.0
	var firing := h.inp.fire and h.reload_t <= 0.0
	if W.has("slow") and firing:
		m *= minf(float(W.get("slowCap", 1.0)), float(W.slow) + float(P.slowAdd))
	if W.has("spinup") and h.spin > float(W.get("spinIdleMin", 0.2)) and not h.inp.fire:
		m *= float(W.get("spinIdleMove", 0.8))
	if firing:
		m *= 1.0 + float(P.fireMove)
	return m


static func muzzle_r(id: String) -> float:
	return float(Data.evolutions().get("muzzleOffsetR", {}).get(id, 2.0))


static func firing_recently(w: SimWorld, h: SimHamster, window: float) -> bool:
	return w.t - h.last_shot_t < window


# ---------------------------------------------------------------------------
# 找目标（原型 foesSorted / altTarget / multiTargets / autoAim）
# ---------------------------------------------------------------------------

static func foes_sorted(w: SimWorld, h: SimHamster, rr: float, cone: float) -> Array:
	## 本队看得见的敌方单位（仓鼠、小兵、野怪、诱饵），按距离排序（仓鼠距离 ×0.7 优先）；cone > 0 时只要准星前方的
	var V: Dictionary = w.vis[h.team]
	var hw := float(Data.rule("combat.foeHamWeight", 0.7))
	var tmp: Array = []
	for e: SimEntity in w.foe_candidates():
		if e.team == h.team or not V.has(e.id):
			continue
		var dx := e.x - h.x
		var dy := e.y - h.y
		var d := sqrt(dx * dx + dy * dy)
		if d > rr:
			continue
		if cone > 0.0 and absf(SimUtil.ang_diff(h.aim, atan2(dy, dx))) > cone:
			continue
		tmp.append([d * (hw if e is SimHamster else 1.0), e])
	tmp.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
	var out: Array = []
	for p in tmp:
		out.append(p[1])
	return out


static func alt_target(w: SimWorld, h: SimHamster, rr: float) -> SimEntity:
	var l := foes_sorted(w, h, rr, 0.0)
	if l.size() > 1:
		return l[1]
	return l[0] if not l.is_empty() else null


static func auto_aim(w: SimWorld, h: SimHamster, rr: float) -> SimEntity:
	## 手柄辅助瞄准（原型 autoAim）：看得见的敌方仓鼠 → 小兵 / 野怪（0.75 倍距离）→ 没有护盾的敌方建筑
	var V: Dictionary = w.vis[h.team]
	var best: SimEntity = null
	var bd := rr * rr
	for e in w.hams:
		if e.alive and e.team != h.team and V.has(e.id):
			var d := SimUtil.d2(e.x, e.y, h.x, h.y)
			if d < bd and w.map.has_los(h.x, h.y, e.x, e.y):
				bd = d
				best = e
	if best != null:
		return best
	bd = rr * rr * 0.56
	for e: SimEntity in w.foe_candidates():
		if e is SimHamster or e.team == h.team or not V.has(e.id):
			continue
		var d := SimUtil.d2(e.x, e.y, h.x, h.y)
		if d < bd and w.map.has_los(h.x, h.y, e.x, e.y):
			bd = d
			best = e
	if best != null:
		return best
	for s in w.structs:
		if s.dead or s.team == h.team or (s.kind == "base" and s.shielded):
			continue
		var d := SimUtil.d2(s.x, s.y, h.x, h.y)
		if d < bd:
			bd = d
			best = s
	return best


# ---------------------------------------------------------------------------
# 开火：公共前段（射速、伤害、弹药、枪口位置）
# ---------------------------------------------------------------------------

static func prologue(w: SimWorld, h: SimHamster, extra: bool) -> Dictionary:
	var id := h.weapon_id
	var W := h.weapon()
	var st := h.st
	var P := params(h)
	var S: Dictionary = P.special
	var berserk := h.tal.has("berserk") and h.hp < h.max_hp * 0.4
	var still := float(P.stillDmg) > 0.0 and h.steady_t >= float(P.stillT)
	var deployed := is_deployed(h)
	var base_rate := float(W.rate)
	if W.has("spinup"):
		base_rate = float(W.spinBase) + (float(W.rate) - float(W.spinBase)) * h.spin
	var rate := base_rate * float(st.rate) * float(P.rate) * (1.3 if berserk else 1.0)
	if h.haste_t > 0.0:
		rate *= float(Data.rule("combat.hasteRate", 1.3))
	if float(P.stormCap) > 0.0:
		rate *= 1.0 + minf(float(P.stormCap), h.ramp * float(P.stormRamp))
	if S.has("deployRate") and deployed:
		rate *= float(S.deployRate)
	if not extra:
		# 累加式冷却：60Hz 逻辑帧下射速不会被量化（同一帧最多一发）
		h.fire_cd = maxf(h.fire_cd, -1.0 / float(Data.rule("tick", 60))) + 1.0 / rate
	if W.has("dual"):
		h.dual_side = -h.dual_side
	var pause := w.t - h.last_shot_t
	var dmg := float(W.dmg) * float(st.dmg) * float(P.dmg) * (1.4 if berserk else 1.0)
	var crit_add := float(P.crit)
	var force := false
	var pierce := int(W.get("pierce", 0)) + int(P.pierce)
	if S.has("rampDmg"):
		dmg *= 1.0 + minf(float(S.rampMax), h.ramp * float(S.rampDmg))
	if S.has("quickShot") and pause < float(S.quickShot):
		dmg *= float(S.quickDmg)
	if still:
		dmg *= 1.0 + float(P.stillDmg)
		crit_add += float(P.stillCrit)
		if S.has("stillForce"):
			force = true
	if float(P.deployDmg) > 0.0 and deployed:
		dmg *= 1.0 + float(P.deployDmg)
	if S.has("critEvery") and (h.shot_n + 1) % int(S.critEvery) == 0:
		force = true
	if h.deadeye_shot:
		dmg *= 1.0 + float(P.deDmg)
		pierce += int(S.get("dePierce", 0))
		if S.has("deForce"):
			force = true
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
	if use and S.has("stillFree") and Vector2(h.vx, h.vy).length() < float(S.stillFree):
		use = false
	if use:
		h.ammo -= 1
	var a0 := h.aim
	var co := cos(a0)
	var si := sin(a0)
	var rx := -si
	var ry := co
	var R := h.r
	var so := float(h.dual_side) * float(W.dualSide) if W.has("dual") else float(W.get("muzzleSide", 0.14))
	var ln := muzzle_r(id)
	return {
		"P": P, "S": S, "W": W, "lv": [h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c")], "rate": rate, "dmg": dmg, "crit": crit_add, "force": force,
		"pierce": pierce, "deployed": deployed, "a0": a0, "co": co, "si": si, "rx": rx, "ry": ry, "R": R, "gh": R + h.z,
		"gx": h.x + co * R * ln + rx * R * so, "gy": h.y + si * R * ln + ry * R * so,
		"bx": h.x + co * R * 0.8 + rx * R * so, "by": h.y + si * R * 0.8 + ry * R * so, "extra": extra,
	}


static func epilogue(w: SimWorld, h: SimHamster, ctx: Dictionary, kind: String, ev: Dictionary) -> void:
	var W: Dictionary = ctx.W
	if kind in ["bullet", "rocket", "lob"]:
		h.reveal_t = float(Data.rule("hamster.revealOnFire", 0.45))
		w.noise(h.x, h.y, "gun", 1.0, h)
	var skb := float(W.get("selfKb", 0.0))
	if skb > 0.0:
		h.vx -= float(ctx.co) * skb
		h.vy -= float(ctx.si) * skb
	h.heat = minf(1.0, h.heat + float(Data.rule("hamster.heatPerShot", 0.08)))
	var e := {"t": "fire", "id": h.id, "weapon": h.weapon_id, "kind": kind, "x": h.x, "y": h.y, "gx": ctx.gx, "gy": ctx.gy, "gh": ctx.gh,
		"aim": ctx.a0, "n": 1, "team": h.team, "extra": ctx.extra, "mode": -1, "side": h.dual_side if W.has("dual") else 0}
	e.merge(ev, true)
	w.emit(e)


# ---------------------------------------------------------------------------
# 开火
# ---------------------------------------------------------------------------

static func fire(w: SimWorld, h: SimHamster, extra: bool = false) -> void:
	match String(h.weapon().get("kind", "bullet")):
		"rocket":
			SimWeaponModes.fire_rocket(w, h, extra)
		"lob":
			SimWeaponModes.fire_gl(w, h, extra)
		"melee":
			SimWeaponModes.swing(w, h, extra)
		"flame":
			SimWeaponModes.fire_flame(w, h, extra)
		"rail":
			SimWeaponModes.fire_rail(w, h)
		"laser":
			SimWeaponModes.laser_tick(w, h)
		_:
			_fire_bullets(w, h, extra)


static func _fire_bullets(w: SimWorld, h: SimHamster, extra: bool) -> void:
	var ctx := prologue(w, h, extra)
	var id := h.weapon_id
	var W: Dictionary = ctx.W
	var P: Dictionary = ctx.P
	var S: Dictionary = ctx.S
	var lv: Array = ctx.lv
	var a0: float = ctx.a0
	var co: float = ctx.co
	var si: float = ctx.si
	var rng_ := float(W.get("range", 600)) * float(P.range)
	if S.has("rangeMapMul"):
		rng_ = w.map.width * float(S.rangeMapMul)
	var shotty := id == "shotgun" or id == "autoshot"
	var n := int(W.get("n", 1)) + int(h.st.get("multi", 0)) + int(P.n)
	var base_sp: float
	if shotty:
		base_sp = float(W.spread) * float(P.spread)
	else:
		base_sp = (float(W.spread) + h.bloom) * float(P.spread) * (float(W.get("deploySpread", 1.0)) if bool(ctx.deployed) else 1.0)
	var sp := base_sp + 0.06 * (n - 1) if (n > 1 and not shotty) else base_sp
	var kind := "pel" if shotty else ("snipe" if id == "sniper" or id == "amr" else "trc")
	var mode := -1
	if S.has("ammoCycle"):
		mode = h.shot_n % int(S.ammoCycle)
	var eff := 1.0
	if W.has("eff"):
		eff = minf(1.0, float(W.eff) * float(P.eff))
	var gx: float = ctx.gx
	var gy: float = ctx.gy
	var aim := a0
	if W.has("dual") and h.dual_side < 0 and float(P.altChance) > 0.0 and (S.has("altAlways") or w.rnd() < float(P.altChance)):
		var t2 := alt_target(w, h, float(S.get("altR", 450)))
		if t2 != null:
			aim = atan2(t2.y - gy, t2.x - gx)
	var dragon := S.has("dragonLast") and h.ammo < int(S.dragonLast)
	var wp := maxi(int(W.get("wallPierce", 0)), maxi(int(P.wp), int(S.get("wallPierce", 0))))
	var off_mul := float(S.get("offDmg", 1.0)) if (W.has("dual") and h.dual_side < 0) else 1.0
	var dmg: float = ctx.dmg
	for i in n:
		var off: float
		if n == 1:
			off = w.rand(-sp, sp)
		else:
			off = (float(i) / float(n - 1) - 0.5) * 2.0 * sp + w.rand(-0.03, 0.03)
		var bdmg := dmg * (float(W.extraDmg) if (i > 0 and W.has("extraDmg")) else 1.0) * off_mul
		var bl := w.new_bullet(kind, h, ctx.bx, ctx.by, ctx.gh, aim + off, float(W.spd) * float(P.spd) * w.rand(0.95, 1.05), bdmg, rng_)
		bl.eff = eff
		bl.min_f = float(W.get("minF", 1.0))
		bl.pierce = int(ctx.pierce) + (int(S.get("cyclePierce", 0)) if mode == 1 else 0)
		bl.kb = float(W.kb) * float(P.kb)
		bl.r = 5.0 if kind == "snipe" else float(Data.rule("combat.bulletRadius", 4.5))
		bl.bounce = int(W.get("bounce", 0)) + int(P.bounce)
		bl.bounce_k = float(P.bounceK)
		bl.wall_pierce = wp
		bl.home_after = float(P.homeAfter)
		bl.split_at = float(S.get("splitAt", 0.0))
		bl.weapon = id
		bl.fx = {
			"src": id, "lv": lv, "P": P, "S": S,
			"ign": 1.0 if mode == 0 else float(P.ign) + (float(S.dragonIgn) if dragon else 0.0), "ignK": float(P.ignK),
			"slow": float(P.slow), "stun": float(P.stun), "mark": float(P.mark),
			"crit": ctx.crit, "force": ctx.force, "expl": mode == 2,
		}
		if S.has("explEvery") and h.shot_n % int(S.explEvery) == 0:
			bl.fx.expl = true
		w.bullets.append(bl)
	if W.has("bloom"):
		h.bloom = minf(float(W.bmax), h.bloom + float(W.bloom))
	var trail := 0.0
	if kind == "snipe":
		trail = w.map.raycast_len(gx, gy, co, si, minf(rng_, float(W.get("trailMax", rng_))), 16.0)
	if float(P.scoutT) > 0.0:
		var L2 := minf(rng_, float(W.get("trailMax", 2400)))
		var c := {"x0": gx, "y0": gy, "x1": gx + co * L2, "y1": gy + si * L2, "w": float(S.get("scoutW", 60)), "until": w.t + float(P.scoutT), "team": h.team}
		w.corrs.append(c)
		w.emit({"t": "corridor", "team": h.team, "x0": c.x0, "y0": c.y0, "x1": c.x1, "y1": c.y1, "w": c.w, "until": c.until})
	if S.has("fireField"):
		var d := float(S.fireField)
		w.add_fire(h.x + co * d, h.y + si * d, float(S.fieldR), float(S.fieldLife), h.team, h, float(S.fieldDps), "field")
	if S.has("burst") and not extra:
		h.burst_n = int(S.burst)
		h.burst_t = float(S.get("burstGap", 0.07))
	epilogue(w, h, ctx, "bullet", {"n": n, "mode": mode, "trail": trail, "deadeye": h.deadeye_shot, "dragon": dragon, "spin": h.spin,
		"flip_k": maxf(float(W.get("flipKMin", 0.3)), float(P.flipK))})


static func try_fire(w: SimWorld, h: SimHamster, can_shoot: bool, dt: float = 1.0 / 60.0) -> void:
	var W := h.weapon()
	if params(h).special.has("deadeye"):
		deadeye(w, h, can_shoot, dt)
		return
	if h.inp.fire and h.fire_cd <= 0.0 and can_shoot and (not W.has("spinup") or h.spin > float(W.get("spinFire", 0.3))):
		fire(w, h)
	elif h.inp.fire and h.fire_cd <= 0.0 and h.reload_t <= 0.0 and h.roll_t <= 0.0 and h.ammo <= 0 and int(W.get("mag", 0)) > 0 and h.ctl == "player":
		w.emit({"t": "empty", "id": h.id})
		h.fire_cd = 0.25


# ---------------------------------------------------------------------------
# 左轮 B：神枪手（按住标记、松开连射）
# ---------------------------------------------------------------------------

static func deadeye_pick(w: SimWorld, h: SimHamster, S: Dictionary) -> SimEntity:
	var l := foes_sorted(w, h, float(S.get("markR", 700)), float(S.get("markCone", 0.62)))
	for e: SimEntity in l:
		if not h.marks.has(e.id):
			return e
	return l[0] if not l.is_empty() else null


static func deadeye(w: SimWorld, h: SimHamster, can_shoot: bool, dt: float) -> void:
	var S: Dictionary = params(h).special
	if h.inp.fire and can_shoot:
		h.mark_hold += dt
		if h.mark_hold > float(S.markTap):
			h.mark_acc += dt
			if h.mark_acc >= float(S.markIv) and h.marks.size() < mini(int(S.markMax), h.ammo):
				h.mark_acc = 0.0
				var t := deadeye_pick(w, h, S)
				if t != null:
					h.marks.append(t.id)
					w.emit({"t": "deadeye_mark", "id": h.id, "target": t.id, "x": t.x, "y": t.y, "h": t.r * 2.6})
					w.emit({"t": "pop", "x": t.x, "y": t.y, "h": t.r * 2.6, "text": "◎", "color": "#ff5b5b", "size": 16})
		if h.mark_hold > float(S.markMaxHold):
			release_deadeye(w, h)
	else:
		if h.mark_hold > 0.0:
			if not h.marks.is_empty():
				release_deadeye(w, h)
			elif h.mark_hold <= float(S.markTap) and h.fire_cd <= 0.0 and can_shoot:
				fire(w, h)
		h.mark_hold = 0.0
		h.mark_acc = 0.0


static func release_deadeye(w: SimWorld, h: SimHamster) -> void:
	var S: Dictionary = params(h).special
	var a0 := h.aim
	h.deadeye_shot = true
	var n := 0
	for id in h.marks:
		if h.ammo <= 0:
			break
		var t: Variant = w.entities.get(id)
		if t == null or (t as SimEntity).dead or (t is SimHamster and not (t as SimHamster).alive):
			continue
		h.aim = atan2((t as SimEntity).y - h.y, (t as SimEntity).x - h.x)
		fire(w, h, true)
		n += 1
	h.deadeye_shot = false
	h.aim = a0
	h.marks.clear()
	h.fire_cd = float(S.get("releaseCd", 0.45))
	h.mark_hold = 0.0
	h.mark_acc = 0.0
	w.emit({"t": "deadeye_release", "id": h.id, "n": n})


# ---------------------------------------------------------------------------
# 每帧进化效果（原型 evoTick）
# ---------------------------------------------------------------------------

static func evo_tick(w: SimWorld, h: SimHamster, dt: float) -> void:
	var still := Vector2(h.vx, h.vy).length() < 25.0 and h.inp.ml < 0.1
	h.steady_t = h.steady_t + dt if still else 0.0
	if h.haste_t > 0.0:
		h.haste_t -= dt
	if not h.inp.fire:
		h.flame_t = 0.0
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
	var S: Dictionary = params(h).special
	if h.weapon_id == "katana":
		SimWeaponModes.katana_tick(w, h, dt)
	if S.has("frontShield") and is_deployed(h):
		front_shield(w, h, S)
	if S.has("dazzle"):
		h.dazzle_t -= dt
		if h.dazzle_t <= 0.0:
			h.dazzle_t = float(S.get("dazzleEvery", 0.3))
			dazzle(w, h, S)


static func dazzle(w: SimWorld, h: SimHamster, S: Dictionary) -> void:
	var R := float(S.dazzle)
	var cs := cos(h.aim)
	var sn := sin(h.aim)
	for e: SimEntity in w.foe_candidates(false):
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


static func front_shield(w: SimWorld, h: SimHamster, S: Dictionary) -> void:
	## 轻机枪 C9：架枪时正面挡子弹
	var rr := float(S.frontShield)
	var i := w.bullets.size() - 1
	while i >= 0:
		var bl: SimBullet = w.bullets[i]
		if bl.team != h.team and bl.kind != "flame":
			var dx := bl.x - h.x
			var dy := bl.y - h.y
			if dx * dx + dy * dy <= rr * rr and absf(SimUtil.ang_diff(h.aim, atan2(dy, dx))) <= float(S.get("shieldArc", 0.9)):
				w.emit({"t": "bullet_block", "id": h.id, "x": bl.x, "y": bl.y, "h": bl.h})
				bl.dead = true
				w.bullets[i] = w.bullets[w.bullets.size() - 1]
				w.bullets.pop_back()
		i -= 1


# ---------------------------------------------------------------------------
# 命中（原型 onBulletHit）
# ---------------------------------------------------------------------------

static func on_bullet_hit(w: SimWorld, b: SimBullet, e: SimEntity) -> void:
	if b.kind == "rocket":
		SimWeaponModes.explode_rocket(w, b)
		return
	if b.kind == "flame":
		SimWeaponModes.flame_hit(w, b, e)
		return
	if b.kind == "swave":
		SimWeaponModes.wave_hit(w, b, e)
		return
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
	var FP: Dictionary = f.get("P", {})
	var FS: Dictionary = f.get("S", {})
	if o != null:
		if float(FP.get("execDmg", 0.0)) > 0.0 and e.hp < e.max_hp * float(FP.execHp):
			dm *= (1.0 + float(FP.execDmg)) * float(FP.execMul)
		if FS.has("litDmg") and w.is_visible_to(o.team, e):
			dm *= 1.0 + float(FS.litDmg)
		if FS.has("structDmg") and (e.kind == "turret" or e.kind == "base"):
			dm *= 1.0 + float(FS.structDmg)
	var dealt := w.deal_dmg(e, dm, {"team": b.team, "owner": o, "by": b.by, "x": b.x, "y": b.y, "critAdd": float(f.get("crit", 0.0)), "forceCrit": bool(f.get("force", false))})
	if dealt > 0.0 and o != null:
		w.emit({"t": "hitmark", "id": o.id, "target": e.id, "kill": e.dead or (e is SimHamster and not (e as SimHamster).alive)})
	var l := maxf(0.001, Vector2(b.vx, b.vy).length())
	var ux := b.vx / l
	var uy := b.vy / l
	w.knock(e, ux, uy, b.kb)
	var big := b.kind == "snipe" or b.kind == "trc" or b.kind == "seed"
	w.emit({"t": "bullet_hit", "x": b.x, "y": b.y, "h": b.h, "team": b.team, "kind": b.kind, "big": big, "target": e.id})
	if o == null or not o.is_alive():
		return
	if float(f.get("ign", 0.0)) > 0.0 and w.rnd() < float(f.ign):
		e.burn_t = maxf(e.burn_t, float(Data.rule("combat.burnTime", 2.2)))
		e.burn_by = o
		e.burn_k = float(f.get("ignK", 1.0))
		if src == "shotgun" and int(lv[1]) >= 6:
			w.slow_e(e, 1.0)
	if float(f.get("slow", 0.0)) > 0.0:
		w.slow_e(e, float(f.slow))
		if FS.has("supp"):
			e.supp_until = w.t + float(FS.supp)
		if FS.has("slowSplash"):
			var sr := float(FS.slowSplash)
			for q: SimEntity in w.hash_range(b.x, b.y, sr + 40.0):
				if q == e or q.is_prop or q.kind == "crate" or not w.can_hit(o.team, q):
					continue
				if Vector2(q.x - b.x, q.y - b.y).length() - q.r <= sr:
					w.slow_e(q, float(f.slow) * float(FS.get("slowSplashK", 0.6)))
	if float(f.get("stun", 0.0)) > 0.0:
		w.stun_e(e, float(f.stun))
	if float(f.get("mark", 0.0)) > 0.0:
		w.mark_e(e, o.team, float(f.mark))
	if float(o.st.get("recon", 0.0)) > 0.0:
		w.mark_e(e, o.team, float(o.st.recon))
	if bool(f.get("expl", false)):
		w.mini_blast(b.x, b.y, float(FS.get("blastR", 45)), dm * float(FS.get("blastDmg", 0.5)), b.team, o)
	if FS.has("wallSlam"):
		wall_slam(w, e, ux, uy, o, FS)
	if FS.has("pointBlank") and Vector2(e.x - o.x, e.y - o.y).length() < float(FS.pointBlank) + e.r:
		w.knock(e, ux, uy, float(FS.pbKb))
		w.stun_e(e, float(FS.pbStun))
	if float(FP.get("fragChance", 0.0)) > 0.0 and w.rnd() < float(FP.fragChance):
		w.mini_blast(b.x, b.y, float(FP.fragR), dm * float(FS.get("fragDmg", 0.5)), b.team, o)
		if FS.has("fragBits"):
			for k in [-1, 1]:
				var nb := w.new_bullet(b.kind, o, b.x, b.y, b.h, atan2(uy, ux) + k * float(FS.fragAng), float(FS.fragSpd), dm * float(FS.fragBitDmg), float(FS.fragRange))
				nb.r = float(FS.fragBitR)
				nb.kb = float(FS.fragBitKb)
				nb.hit[e.id] = true
				nb.fx = {}
				nb.weapon = src
				w.bullets.append(nb)
	if FS.has("reloadJam") and e is SimHamster and (e as SimHamster).reload_t > 0.0:
		(e as SimHamster).reload_t += float(FS.reloadJam)
		w.emit({"t": "reload_jam", "id": e.id, "add": float(FS.reloadJam)})
	if float(FP.get("shockR", 0.0)) > 0.0:
		shockwave(w, b.x, b.y, float(FP.shockR), FS, o)
	if float(o.st.get("frost", 0)) > 0.0:
		var fr := float(Data.rule("abilities.frost.frostBase", 0.8)) + float(Data.rule("abilities.frost.frostPer", 0.3)) * float(o.st.frost)
		w.slow_e(e, fr)
	if float(o.st.get("chain", 0.0)) > 0.0 and w.rnd() < float(o.st.chain):
		w.chain_lightning(e, b.dmg * float(Data.rule("abilities.chain.chainDmg", 0.45)), o)


static func wall_slam(w: SimWorld, e: SimEntity, dx: float, dy: float, o: SimHamster, S: Dictionary) -> void:
	## 沙鹰 A9：把敌人打到墙上眩晕
	if e.kind == "base" or e.kind == "turret" or e.is_prop or e.dead:
		return
	if e is SimHamster and not (e as SimHamster).alive:
		return
	var px := e.x + dx * (e.r + float(S.wallSlam))
	var py := e.y + dy * (e.r + float(S.wallSlam))
	if w.map.point_solid(px, py, float(S.get("slamProbeR", 4))) == null:
		return
	w.stun_e(e, float(S.get("slamStun", 0.8)))
	w.emit({"t": "wall_slam", "target": e.id, "x": px, "y": py, "r": e.r})
	w.emit({"t": "pop", "x": e.x, "y": e.y, "h": e.r * 2.6, "text": "撞墙！", "color": "#ffd166", "size": 15})
	w.deal_dmg(e, float(S.get("slamDmg", 20)), {"team": o.team, "owner": o, "x": e.x, "y": e.y})


static func shockwave(w: SimWorld, x: float, y: float, rr: float, S: Dictionary, o: SimHamster) -> void:
	## 反器材 B：命中时震退周围（原型只实现了 B9，1–8 级按卡面文字补全，见批次 2 汇报）
	var fo := float(Data.rule("combat.blastFalloff", 0.5))
	for q: SimEntity in w.hash_range(x, y, rr + 40.0):
		if q.is_prop or q.kind in ["base", "turret", "crate"] or not w.can_hit(o.team, q):
			continue
		var d := Vector2(q.x - x, q.y - y).length() - q.r
		if d > rr:
			continue
		var k := 1.0 - maxf(0.0, d) / rr * fo
		w.knock(q, q.x - x, q.y - y, float(S.get("shockKb", 220)) * k)
		if S.has("shockStun"):
			w.stun_e(q, float(S.shockStun))
	w.emit({"t": "shockwave", "x": x, "y": y, "r": rr, "stun": S.has("shockStun"), "team": o.team})


# ---------------------------------------------------------------------------
# 击杀 / 翻滚钩子（原型 onKill / startDash）
# ---------------------------------------------------------------------------

static func on_kill(w: SimWorld, tg: SimEntity, src: Dictionary) -> void:
	var K: SimHamster = src.get("owner") as SimHamster if src.get("owner") is SimHamster else null
	if K == null or tg.team == K.team or tg.kind == "crate" or tg.is_prop:
		return
	var S: Dictionary = params(K).special
	if S.has("killRefund"):
		K.ammo = mini(mag_size(K), K.ammo + int(S.killRefund))
		K.fire_cd = 0.0
		w.emit({"t": "kill_refund", "id": K.id, "ammo": K.ammo})
	if S.has("killAmmo"):
		var m := mag_size(K)
		K.ammo = mini(m, K.ammo + ceili(m * float(S.killAmmo)))
	if S.has("killResetDash"):
		K.dash_cd = 0.0


static func on_dash(w: SimWorld, h: SimHamster) -> void:
	var S: Dictionary = params(h).special
	if S.has("rollReload"):
		h.ammo = mag_size(h)
		h.reload_t = 0.0
		h.haste_t = float(S.get("hasteT", 3))
		w.emit({"t": "roll_reload", "id": h.id, "kind": "full", "haste": h.haste_t})
	if S.has("rollRefill"):
		var m := mag_size(h)
		h.ammo = mini(m, h.ammo + ceili(m * float(S.rollRefill)))
		h.reload_t = 0.0
		w.emit({"t": "roll_reload", "id": h.id, "kind": "half", "haste": 0.0})
	if S.has("emptyRollReload") and h.ammo <= 0:
		h.ammo = mag_size(h)
		h.reload_t = 0.0
		w.emit({"t": "roll_reload", "id": h.id, "kind": "empty", "haste": 0.0})
	if S.has("gunKata"):
		var W := h.weapon()
		var lv := [h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c")]
		var n := int(S.gunKata)
		for k in n:
			var bl := w.new_bullet("trc", h, h.x, h.y, h.r, float(k) / n * TAU, float(S.get("kataSpd", 1100)), float(W.dmg) * float(h.st.dmg), float(S.get("kataRange", 500)))
			bl.r = float(S.get("kataR", 4.5))
			bl.kb = float(S.get("kataKb", 60))
			bl.fx = {"src": h.weapon_id, "lv": lv}
			bl.weapon = h.weapon_id
			w.bullets.append(bl)
		w.noise(h.x, h.y, "gun", 1.0, h)
		w.emit({"t": "gun_kata", "id": h.id, "x": h.x, "y": h.y})


# ---------------------------------------------------------------------------
# 子弹飞行中的进化效果：追踪、分裂（原型 homeB / splitB）
# ---------------------------------------------------------------------------

static func home_step(w: SimWorld, b: SimBullet, dt: float) -> void:
	var H: Dictionary = w.R.homing
	b.home_t -= dt
	var t: SimEntity = w.entities.get(b.home_tgt) as SimEntity if b.home_tgt != 0 and w.entities.has(b.home_tgt) else null
	if t != null and (t.dead or (t is SimHamster and not (t as SimHamster).alive)):
		t = null
		b.home_tgt = 0
	if t == null and b.home_t <= 0.0:
		b.home_t = float(H.retarget)
		var FS: Dictionary = b.fx.get("S", {})
		var rr := float(FS.get("homeRange", H.range))
		var cone := float(FS.get("homeCone", H.cone))
		var sp0 := atan2(b.vy, b.vx)
		var best: SimEntity = null
		var bd := rr * rr
		for e: SimEntity in w.hash_range(b.x, b.y, rr):
			if not w.can_hit(b.team, e) or e.is_prop or e.kind == "crate" or (e.kind == "base" and e.shielded):
				continue
			if b.team != "neutral" and e.team != "neutral" and not w.vis[b.team].has(e.id):
				continue
			var d := SimUtil.d2(b.x, b.y, e.x, e.y)
			if d < bd and absf(SimUtil.ang_diff(sp0, atan2(e.y - b.y, e.x - b.x))) < cone:
				bd = d
				best = e
		b.home_tgt = best.id if best != null else 0
		t = best
	if t == null:
		return
	var sp := Vector2(b.vx, b.vy).length()
	var na := SimUtil.turn_to(atan2(b.vy, b.vx), atan2(t.y - b.y, t.x - b.x), b.home * dt)
	b.vx = cos(na) * sp
	b.vy = sin(na) * sp


static func split_bullet(w: SimWorld, b: SimBullet) -> void:
	var FS: Dictionary = b.fx.get("S", {})
	var a := atan2(b.vy, b.vx)
	var sp := Vector2(b.vx, b.vy).length()
	for k in [-1, 1]:
		var nb := b.clone()
		nb.id = w.new_uid()
		nb.vx = cos(a + k * float(FS.get("splitAng", 0.2))) * sp
		nb.vy = sin(a + k * float(FS.get("splitAng", 0.2))) * sp
		nb.dmg = b.dmg * float(FS.get("splitDmg", 0.7))
		nb.split_at = 0.0
		nb.px = b.x
		nb.py = b.y
		w.bullets.append(nb)
	w.emit({"t": "split", "x": b.x, "y": b.y, "h": b.h})
