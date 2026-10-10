class_name SimWeaponModes
extends RefCounted
## 特殊开火方式：火箭筒（rocket）、武士刀（melee）、喷火器（flame）、榴弹发射器（lob）、电磁炮（rail）、激光枪（laser）。
## 对应原型 n2c.js 的 fireWeapon 各分支、explode、katanaDeflect、iaido、fireRail、laserTick、updLobs/lobBoom（榴弹部分）。


# ---------------------------------------------------------------------------
# 火箭筒
# ---------------------------------------------------------------------------

static func fire_rocket(w: SimWorld, h: SimHamster, extra: bool) -> void:
	var ctx := SimWeapons.prologue(w, h, extra)
	var W: Dictionary = ctx.W
	var P: Dictionary = ctx.P
	var S: Dictionary = ctx.S
	var aoe := float(W.aoe) * float(P.aoe)
	var a_d := float(W.aoeDmg) * float(P.aoeDmg) * float(h.st.dmg)
	var dmg: float = ctx.dmg
	var a0: float = ctx.a0
	var mk := func(ang: float, dm: float, tgt: SimEntity) -> void:
		var b := w.new_bullet("rocket", h, ctx.bx, ctx.by, ctx.gh, ang, float(W.spd) * float(P.spd), dm, float(W.range) * float(P.range))
		b.r = float(W.get("bulletR", 7))
		b.aoe = aoe
		b.aoe_dmg = a_d * (dm / maxf(dmg, 0.001))
		b.kb = float(W.kb) * float(P.kb)
		b.fx = {"src": "rocket", "lv": ctx.lv, "P": P, "S": S}
		b.home = float(P.home)
		b.home_tgt = tgt.id if tgt != null else 0
		b.weapon = "rocket"
		w.bullets.append(b)
	var n := 1
	if S.has("multi"):
		var foes := SimWeapons.foes_sorted(w, h, float(S.get("multiRange", 820)), float(S.get("multiCone", 1.2)))
		n = int(S.multi)
		for i in n:
			mk.call(a0 + (i - (n - 1) * 0.5) * float(S.multiSpread), dmg * float(S.multiDmg), foes[i] if i < foes.size() else null)
		if not extra:
			h.fire_cd *= float(S.get("multiCd", 1.3))
	elif S.has("twin"):
		n = 2
		mk.call(a0 - float(S.twin), dmg, null)
		mk.call(a0 + float(S.twin), dmg, null)
	else:
		mk.call(a0, dmg, null)
	SimWeapons.epilogue(w, h, ctx, "rocket", {"n": n})


static func explode_rocket(w: SimWorld, b: SimBullet) -> void:
	if b.dead and b.aoe <= 0.0:
		return
	var P: Dictionary = b.fx.get("P", SimWeapons.params_for("rocket", b.fx.get("lv", [0, 0, 0])))
	var S: Dictionary = P.special
	var R := b.aoe
	b.aoe = 0.0   # 只炸一次
	w.blast(b.x, b.y, R, b.aoe_dmg + b.dmg, b.team, b.owner, b.kb, {"slow": float(S.get("blastSlow", 0.0)), "src": "rocket", "h": b.h, "by": b.by})
	if S.has("bombs"):
		var C: Dictionary = Data.weapon("rocket").get("cluster", {})
		var n := int(S.bombs)
		var dist: Array = C.get("dist", [70, 130])
		for i in n:
			var ang := float(i) / n * TAU + w.rand(-float(C.get("jitter", 0.3)), float(C.get("jitter", 0.3)))
			var d := w.rand(float(dist[0]), float(dist[1]))
			w.throw_lob_from(b.x, b.y, float(C.get("throwR", 6)), b.team, b.owner, "bomb", b.x + cos(ang) * d, b.y + sin(ang) * d,
				{"sp": float(C.get("sp", 300)), "fuse": float(C.get("fuse", 0.55)), "aoe": float(C.get("aoe", 55)), "dmg": (b.aoe_dmg + b.dmg) * float(P.cluster), "kb": float(C.get("kb", 120)), "silent": true})
	if S.has("crater"):
		w.add_fire(b.x, b.y, R * float(S.crater), float(S.get("craterLife", 4)), b.team, b.owner, float(S.get("craterDps", 18)), "crater")


# ---------------------------------------------------------------------------
# 榴弹发射器
# ---------------------------------------------------------------------------

static func lob_target(w: SimWorld, h: SimHamster, max_d: float) -> Vector2:
	var W := h.weapon()
	var tx := h.x + cos(h.aim) * float(W.get("aimDefault", 360))
	var ty := h.y + sin(h.aim) * float(W.get("aimDefault", 360))
	if h.inp.has_aim_point:
		tx = h.inp.aim_x
		ty = h.inp.aim_y
	else:
		var t: SimEntity = h.ai.target if h.ai != null else SimWeapons.auto_aim(w, h, float(W.get("autoAim", 560)))
		if t != null and not t.dead:
			tx = t.x
			ty = t.y
	var dx := tx - h.x
	var dy := ty - h.y
	var d := maxf(0.001, Vector2(dx, dy).length())
	var dd := clampf(d, float(W.get("minDist", 90)), max_d)
	return Vector2(h.x + dx / d * dd, h.y + dy / d * dd)


static func fire_gl(w: SimWorld, h: SimHamster, extra: bool) -> void:
	var ctx := SimWeapons.prologue(w, h, extra)
	var W: Dictionary = ctx.W
	var P: Dictionary = ctx.P
	var S: Dictionary = ctx.S
	if S.has("detonate"):
		var n := 0
		for L in w.lobs:
			if L.owner == h and L.sticky and not L.dead:
				L.fuse = 0.01
				n += 1
		if n > 0:
			h.fire_cd = float(S.get("detonateCd", 0.25))
			w.emit({"t": "gl_detonate", "id": h.id, "n": n})
			return
	var p := lob_target(w, h, float(W.range) * float(P.range))
	var round_ := ""
	if S.has("rounds"):
		h.gl_n += 1
		var every := int(S.get("specialEvery", 1))
		var rounds: Array = S.rounds
		if every <= 1 or h.gl_n % every == 0:
			round_ = String(rounds[h.gl_n % rounds.size()])
	var fuse := float(S.stickyFuse) if S.has("detonate") else float(W.fuse) + float(P.fuse)
	# 多管：一次打出几颗，往准星两侧散开（副弹伤害 glDmg）
	var extra_n := int(S.get("glMulti", 0))
	var dist := Vector2(p.x - h.x, p.y - h.y).length()
	var base_a := atan2(p.y - h.y, p.x - h.x)
	for gi in 1 + extra_n:
		var side := 0.0 if gi == 0 else float((gi + 1) / 2) * float(S.get("glAng", 0.25)) * (1.0 if gi % 2 == 1 else -1.0)
		var tp := Vector2(h.x + cos(base_a + side) * dist, h.y + sin(base_a + side) * dist)
		var gk := 1.0 if gi == 0 else float(S.get("glDmg", 0.6))
		var L := w.throw_lob_from(h.x, h.y, h.r, h.team, h, "gnade", tp.x, tp.y, {"sp": float(W.get("lobSpeed", 560)) * float(P.spd), "fuse": fuse,
			"aoe": float(W.aoe) * float(P.aoe), "dmg": float(W.aoeDmg) * float(P.dmg) * float(h.st.dmg) * gk, "kb": float(W.kb), "impact": not S.has("sticky"), "silent": true})
		L.bounce_n = int(S.get("bounces", 0))
		L.split_on_bounce = S.has("splitOnBounce")
		L.split_ang = float(S.get("splitAng", 0.7))
		L.split_vz = float(S.get("splitVz", 0.4))
		L.sticky = S.has("sticky")
		L.slow_stick = float(S.get("stickSlow", 0.0))
		L.special = round_ if gi == 0 else ""
		if L.special == "" and S.has("glFire"):
			L.special = "fire"     # 黏弹 B6：爆炸后留下一片火
		if S.has("gas"):
			L.gas_r = float(S.gas)
			L.gas_life = float(S.get("gasLife", 3))
			L.gas_dps = float(S.get("gasDps", 6))
			L.gas_slow = float(S.get("gasSlow", 0.5))
	SimWeapons.epilogue(w, h, ctx, "lob", {"special": round_, "tx": p.x, "ty": p.y})


# ---------------------------------------------------------------------------
# 武士刀
# ---------------------------------------------------------------------------

static func swing(w: SimWorld, h: SimHamster, extra: bool) -> void:
	var ctx := SimWeapons.prologue(w, h, extra)
	var W: Dictionary = ctx.W
	var P: Dictionary = ctx.P
	var S: Dictionary = ctx.S
	var a0: float = ctx.a0
	var dmg: float = ctx.dmg
	h.swing_t = float(W.get("swingTime", 0.22))
	h.swing_dir = -h.swing_dir
	h.swing_n += 1
	var reach := float(W.reach)
	var arc := float(W.arc) * float(P.arc)
	var spin := S.has("spinEvery") and h.swing_n % int(S.spinEvery) == 0
	if spin:
		arc = TAU     # 旋风斩：这一刀砍一整圈
		reach *= float(S.get("spinReach", 1.15))
	for e: SimEntity in w.hash_range(h.x, h.y, reach + 60.0):
		if not w.can_hit(h.team, e):
			continue
		var dd := Vector2(e.x - h.x, e.y - h.y).length() - e.r
		if dd > reach:
			continue
		if not spin and absf(SimUtil.ang_diff(a0, atan2(e.y - h.y, e.x - h.x))) > arc * 0.5 and dd > e.r * 0.5:
			continue
		var dealt := w.deal_dmg(e, dmg, {"team": h.team, "owner": h, "x": h.x, "y": h.y, "critAdd": float(ctx.crit)})
		if dealt > 0.0:
			SimWeapons.hit_status(w, h, e, P)
			SimWeapons.hit_extras(w, h, e, S, dealt, dmg)
			w.knock(e, e.x - h.x, e.y - h.y, float(W.kb))
			w.emit({"t": "melee_hit", "id": h.id, "target": e.id, "x": e.x, "y": e.y, "h": e.r})
			w.emit({"t": "hitmark", "id": h.id, "target": e.id, "kill": e.dead or (e is SimHamster and not (e as SimHamster).alive)})
	var waves := 0
	var big := false
	if float(P.wave) > 0.0:
		var WV: Dictionary = W.get("wave", {})
		big = S.has("bigEvery") and h.swing_n % int(S.bigEvery) == 0
		var wr := float(S.get("waveWide", 1.0)) * (float(S.get("bigWide", 1.8)) if big else 1.0)
		var angs: Array = [a0 - float(S.get("bigSpread", 0.5)), a0 + float(S.get("bigSpread", 0.5))] if big else [a0]
		for an in angs:
			var bl := w.new_bullet("swave", h, h.x + cos(an) * h.r, h.y + sin(an) * h.r, h.r, an, float(WV.get("speed", 720)),
				dmg * float(P.wave) * (float(S.get("bigDmg", 1.5)) if big else 1.0), float(P.waveRange))
			bl.r = float(WV.get("r", 14)) * wr
			bl.kb = float(WV.get("kb", 120))
			bl.pierce = 99 if (S.has("wavePierce") or big) else 0
			bl.wr = wr
			bl.big = big
			bl.fx = {"src": "katana", "lv": ctx.lv, "P": P, "S": S}
			bl.weapon = "katana"
			w.bullets.append(bl)
			waves += 1
	w.emit({"t": "swing", "id": h.id, "x": h.x, "y": h.y, "h": h.r * 1.1, "a": a0, "reach": reach, "arc": arc, "dir": h.swing_dir, "big": big or spin, "waves": waves, "spin": spin})
	SimWeapons.epilogue(w, h, ctx, "melee", {"n": waves})


static func katana_tick(w: SimWorld, h: SimHamster, dt: float) -> void:
	var P := SimWeapons.params(h)
	var S: Dictionary = P.special
	if h.swing_t > 0.0 or (S.has("rollDeflect") and h.roll_t > 0.0):
		var W := h.weapon()
		var perfect := S.has("perfectWindow") and h.swing_t > 0.0 and (float(W.get("swingTime", 0.22)) - h.swing_t) < float(S.perfectWindow)
		deflect(w, h, P, perfect)
	if float(P.iaido) > 0.0 and h.roll_t > 0.0 and h.iaido_on:
		iaido(w, h, P)


static func deflect(w: SimWorld, h: SimHamster, P: Dictionary, perfect: bool) -> void:
	var W := h.weapon()
	var S: Dictionary = P.special
	var reach := float(W.reach) + float(W.get("deflectReach", 12))
	var arc := float(W.arc) * float(P.arc)
	var full := h.roll_t > 0.0 and h.swing_t <= 0.0
	var pts: Array = []
	for bl: SimBullet in w.bullets:
		if bl.team == h.team or bl.kind == "flame" or bl.kind == "swave":
			continue
		var dx := bl.x - h.x
		var dy := bl.y - h.y
		if dx * dx + dy * dy > reach * reach:
			continue
		if not full and absf(SimUtil.ang_diff(h.aim, atan2(dy, dx))) > arc * 0.5:
			continue
		var shooter := bl.by
		var sp := Vector2(bl.vx, bl.vy).length()
		var ang := atan2(dy, dx) if full else h.aim
		bl.vx = cos(ang) * sp * float(W.get("deflectSpeed", 1.1))
		bl.vy = sin(ang) * sp * float(W.get("deflectSpeed", 1.1))
		bl.team = h.team
		bl.owner = h
		bl.by = h
		bl.dmg *= (float(W.get("deflectBase", 1.2)) + float(P.deflect)) * (float(S.get("perfectMul", 3)) if perfect else 1.0)
		bl.hit = {}
		bl.life = maxf(bl.life, float(W.get("deflectLife", 0.9)))
		if bl.kind in ["orb", "rat", "mpea", "seed", "spike"]:
			bl.kind = "trc"
		if S.has("deflectHome") and shooter != null:
			bl.home = float(S.deflectHome)
			bl.home_tgt = shooter.id
		pts.append([bl.x, bl.y, bl.h])
	if pts.is_empty():
		return
	if perfect:
		h.iframes = maxf(h.iframes, float(S.get("perfectIframes", 0.6)))
	w.emit({"t": "deflect", "id": h.id, "x": h.x, "y": h.y, "n": pts.size(), "perfect": perfect, "pts": pts})
	w.emit({"t": "pop", "x": h.x, "y": h.y, "h": h.r * 3.0, "text": "完美格挡！" if perfect else "反弹！", "color": "#ffd166" if perfect else "#9fe8ff", "size": 17 if perfect else 13})


static func iaido(w: SimWorld, h: SimHamster, P: Dictionary) -> void:
	var W := h.weapon()
	var I: Dictionary = W.get("iaido", {})
	var dmg := float(W.dmg) * float(h.st.dmg) * float(P.iaido)
	for e: SimEntity in w.hash_range(h.x, h.y, h.r + float(I.get("scan", 40))):
		if h.iaido_hit.has(e.id) or not w.can_hit(h.team, e) or e.kind == "base" or e.kind == "turret" or e.is_prop:
			continue
		if Vector2(e.x - h.x, e.y - h.y).length() < h.r + e.r + float(I.get("pad", 10)):
			h.iaido_hit[e.id] = true
			w.deal_dmg(e, dmg, {"team": h.team, "owner": h, "x": h.x, "y": h.y})
			w.emit({"t": "iaido_hit", "id": h.id, "target": e.id, "x": e.x, "y": e.y, "h": e.r, "a": atan2(h.rdy, h.rdx)})
			w.emit({"t": "hitmark", "id": h.id, "target": e.id, "kill": e.dead or (e is SimHamster and not (e as SimHamster).alive)})


static func wave_hit(w: SimWorld, b: SimBullet, e: SimEntity) -> void:
	var o := b.owner
	var dealt := w.deal_dmg(e, b.dmg, {"team": b.team, "owner": o, "by": b.by, "x": b.x, "y": b.y})
	if dealt > 0.0 and o != null and b.fx.has("P"):
		SimWeapons.hit_status(w, o, e, b.fx.P)
		SimWeapons.hit_extras(w, o, e, b.fx.S, dealt, b.dmg)
	if dealt > 0.0 and o != null:
		w.emit({"t": "hitmark", "id": o.id, "target": e.id, "kill": e.dead or (e is SimHamster and not (e as SimHamster).alive)})
	var l := maxf(0.001, Vector2(b.vx, b.vy).length())
	w.knock(e, b.vx / l, b.vy / l, b.kb)
	w.emit({"t": "bullet_hit", "x": b.x, "y": b.y, "h": b.h, "team": b.team, "kind": "swave", "big": true, "target": e.id})


# ---------------------------------------------------------------------------
# 喷火器
# ---------------------------------------------------------------------------

static func fire_flame(w: SimWorld, h: SimHamster, extra: bool) -> void:
	var ctx := SimWeapons.prologue(w, h, extra)
	var W: Dictionary = ctx.W
	var P: Dictionary = ctx.P
	var S: Dictionary = ctx.S
	var a0: float = ctx.a0
	var fr := float(W.range) * float(P.range)
	var spr := float(W.spread) * float(P.spread)
	var jit: Array = W.get("spdJitter", [0.85, 1.1])
	var n := 1 + int(float(h.st.get("multi", 0)) / 2.0) + int(S.get("flameN", 0))
	var fa := float(S.get("flameAng", 0.2))
	for i in n:
		# 多喷嘴：第 2、3 道火焰往两侧偏开
		var side := 0.0 if i == 0 else (float((i + 1) / 2) * fa * (1.0 if i % 2 == 1 else -1.0))
		var b := w.new_bullet("flame", h, ctx.gx, ctx.gy, ctx.gh, a0 + side + w.rand(-spr, spr), float(W.spd) * float(P.spd) * w.rand(float(jit[0]), float(jit[1])),
			float(ctx.dmg) * (1.0 if i == 0 else float(S.get("flameDmg", 0.6))), fr)
		b.r = float(W.get("bulletR", 11))
		b.kb = float(W.kb) * float(P.kb)
		b.fx = {"src": "flame", "lv": ctx.lv, "burn": float(W.get("burnBase", 2.5)) + float(P.burn), "spread": float(S.get("burnSpread", 0.0)), "blue": S.has("blue"), "slow": float(P.slow)}
		b.weapon = "flame"
		w.bullets.append(b)
	if S.has("puddle") and w.t - h.puddle_t > float(S.get("puddleCd", 0.8)):
		h.puddle_t = w.t
		var k := fr * float(S.get("puddleAt", 0.8))
		w.add_fire(h.x + cos(a0) * k, h.y + sin(a0) * k, float(S.puddle), float(S.get("puddleLife", 2)), h.team, h, float(S.get("puddleDps", 10)), "puddle")
	if float(P.heat) > 0.0:
		var rr := fr * (1.0 if S.has("heatFull") else float(P.heat))
		var cone := float(W.get("heatCone", 0.5))
		var i2 := w.bullets.size() - 1
		while i2 >= 0:
			var bl: SimBullet = w.bullets[i2]
			if bl.team != h.team and not (bl.kind in ["flame", "rocket", "swave"]):
				var dx := bl.x - h.x
				var dy := bl.y - h.y
				if dx * dx + dy * dy <= rr * rr and absf(SimUtil.ang_diff(a0, atan2(dy, dx))) <= cone:
					w.emit({"t": "bullet_burn", "x": bl.x, "y": bl.y, "h": bl.h, "by": h.id})
					bl.dead = true
					w.bullets[i2] = w.bullets[w.bullets.size() - 1]
					w.bullets.pop_back()
			i2 -= 1
	if S.has("flameBurst"):
		h.flame_t += 1.0 / maxf(0.001, float(ctx.rate))
		if h.flame_t >= float(S.flameBurst):
			h.flame_t = 0.0
			w.blast(h.x, h.y, float(S.get("burstR", 170)), float(S.get("burstDmg", 90)) * float(h.st.dmg), h.team, h, float(S.get("burstKb", 300)), {"src": "flame_burst"})
	SimWeapons.epilogue(w, h, ctx, "flame", {"n": n, "blue": S.has("blue")})


static func flame_hit(w: SimWorld, b: SimBullet, e: SimEntity) -> void:
	var o := b.owner
	if w.deal_dmg(e, b.dmg, {"team": b.team, "owner": o, "by": b.by, "x": b.x, "y": b.y}) > 0.0 and o != null:
		w.emit({"t": "hitmark", "id": o.id, "target": e.id, "kill": e.dead or (e is SimHamster and not (e as SimHamster).alive)})
	var l := maxf(0.001, Vector2(b.vx, b.vy).length())
	w.knock(e, b.vx / l, b.vy / l, b.kb)
	if e.is_prop or e.kind == "crate" or e.kind == "base" or e.kind == "turret":
		return
	e.burn_t = maxf(e.burn_t, float(b.fx.get("burn", 2.5)))
	e.burn_by = o
	if float(b.fx.get("slow", 0.0)) > 0.0:
		w.slow_e(e, float(b.fx.slow))
	if float(b.fx.get("spread", 0.0)) > 0.0:
		e.burn_spread_until = w.t + float(b.fx.spread)


# ---------------------------------------------------------------------------
# 电磁炮
# ---------------------------------------------------------------------------

static func rail_update(w: SimWorld, h: SimHamster, dt: float, can_shoot: bool) -> void:
	var W := h.weapon()
	var P := SimWeapons.params(h)
	if h.inp.fire and can_shoot:
		if h.charge == 0.0:
			w.emit({"t": "charge_start", "id": h.id})
		h.charge = minf(1.0, h.charge + dt / (float(W.charge) * maxf(float(W.get("chargeFloor", 0.4)), float(P.charge))))
		if h.charge >= 1.0:
			h.ch_hold += dt
		if h.ch_hold > float(W.get("holdMax", 0.45)):
			fire_rail(w, h)
	elif h.charge > 0.0:
		if h.charge > float(W.get("minCharge", 0.15)) and can_shoot:
			fire_rail(w, h)
		else:
			h.charge = 0.0
			h.ch_hold = 0.0
			w.emit({"t": "charge_cancel", "id": h.id})


static func fire_rail(w: SimWorld, h: SimHamster) -> void:
	var W := h.weapon()
	var P := SimWeapons.params(h)
	var S: Dictionary = P.special
	h.reveal_t = float(Data.rule("hamster.revealOnFire", 0.45))
	w.noise(h.x, h.y, "gun", 1.1, h)
	var ch := h.charge
	h.charge = 0.0
	h.ch_hold = 0.0
	h.ammo -= 1
	h.fire_cd = float(W.get("fireCd", 0.3))
	h.shot_n += 1
	h.last_shot_t = w.t
	var co := cos(h.aim)
	var si := sin(h.aim)
	var R := h.r
	var gh := R + h.z
	var dmg := (float(W.dmg) + float(W.get("chargeDmg", 140)) * ch) * float(P.dmg) * float(h.st.dmg)
	var rng_ := float(W.range) * float(P.range)
	var walls := int(S.get("walls", 0))
	var refl := int(S.get("reflect", 0))
	var x := h.x + co * R * float(W.get("muzzleR", 2.4))
	var y := h.y + si * R * float(W.get("muzzleR", 2.4))
	var dx := co
	var dy := si
	var left := rng_
	var segs: Array = []
	var step := float(W.get("step", 10))
	var max_segs := int(W.get("maxSegs", 4))
	var cx := (w.map.min_x + w.map.max_x) * 0.5
	var cy := (w.map.min_y + w.map.max_y) * 0.5
	var hw := (w.map.max_x - w.map.min_x) * 0.5
	var hh := (w.map.max_y - w.map.min_y) * 0.5
	var edge := float(W.get("edgeMargin", 80))
	while left > 0.0 and segs.size() < max_segs:
		var L := 0.0
		var in_s: Object = null
		var reflected := false
		while L < left:
			var px := x + dx * L
			var py := y + dy * L
			var sd := w.map.point_solid(px, py, 1.0)
			if sd != null and sd != in_s:
				if sd.prop != null:
					w.prop_hit(sd.prop as SimProp, dmg * float(W.get("propPassDmg", 0.5)), h)
				if sd.kind == "wall":
					if refl > 0:
						refl -= 1
						segs.append([x, y, px, py])
						var nx := -1.0 if absf(px - cx) > hw - edge else 1.0
						var ny := -1.0 if absf(py - cy) > hh - edge else 1.0
						x = px - dx * float(W.get("reflectBack", 12))
						y = py - dy * float(W.get("reflectBack", 12))
						if nx < 0.0:
							dx = -dx
						if ny < 0.0:
							dy = -dy
						left -= L
						reflected = true
					break
				if walls > 0:
					walls -= 1
					in_s = sd
				else:
					break
			elif sd == null:
				in_s = null
			L += step
		if reflected:
			continue
		var len_ := minf(L, left)
		segs.append([x, y, x + dx * len_, y + dy * len_])
		break
	var hit_set := {}
	var last: SimEntity = null
	var pad := float(W.get("hitPad", 10)) * (0.5 + ch) + float(S.get("railPad", 0.0))
	for sg: Array in segs:
		var sx := float(sg[2]) - float(sg[0])
		var sy := float(sg[3]) - float(sg[1])
		var sl := maxf(1.0, sqrt(sx * sx + sy * sy))
		var ux := sx / sl
		var uy := sy / sl
		for e: SimEntity in w.rail_candidates():
			if hit_set.has(e.id) or not w.can_hit(h.team, e):
				continue
			var tt := clampf((e.x - float(sg[0])) * ux + (e.y - float(sg[1])) * uy, 0.0, sl)
			var px := float(sg[0]) + ux * tt
			var py := float(sg[1]) + uy * tt
			if Vector2(e.x - px, e.y - py).length() >= e.r + pad:
				continue
			hit_set[e.id] = true
			var dealt := w.deal_dmg(e, dmg, {"team": h.team, "owner": h, "x": px, "y": py, "pvpCap": float(W.get("pvpCap", 0.0))})
			if dealt > 0.0:
				last = e
				SimWeapons.hit_status(w, h, e, P)
				SimWeapons.hit_extras(w, h, e, S, dealt, dmg)
			w.knock(e, ux, uy, float(W.kb) * ch)
			w.emit({"t": "bullet_hit", "x": e.x, "y": e.y, "h": e.r, "team": h.team, "kind": "rail", "big": true, "target": e.id})
			if float(P.railSlow) > 0.0:
				w.slow_e(e, float(P.railSlow))
				if e is SimHamster and (e as SimHamster).reload_t > 0.0 and S.has("reloadDrag"):
					(e as SimHamster).reload_t += float(S.reloadDrag)
			if S.has("turretJam") and e.kind == "turret":
				(e as SimStructure).cd = maxf((e as SimStructure).cd, float(S.turretJam))
				w.emit({"t": "turret_jam", "id": e.id, "dur": float(S.turretJam)})
			if S.has("arcChain") and ch >= float(S.get("arcFull", 0.99)):
				w.chain_lightning(e, dmg * float(S.arcChain), h)
		for p in w.props:
			if p.dead:
				continue
			var tt2 := clampf((p.x - float(sg[0])) * ux + (p.y - float(sg[1])) * uy, 0.0, sl)
			if Vector2(p.x - float(sg[0]) - ux * tt2, p.y - float(sg[1]) - uy * tt2).length() < p.r + float(W.get("propPad", 12)):
				w.prop_hit(p, dmg, h)
		if S.has("trail"):
			w.add_zone({"seg": [sg[0], sg[1], sg[2], sg[3]], "w": float(S.trail), "until": w.t + float(S.get("trailLife", 3)), "team": h.team, "owner": h,
				"dps": float(S.get("trailDps", 20)), "kind": "arc"})
	if last != null:
		w.emit({"t": "hitmark", "id": h.id, "target": last.id, "kill": last.dead or (last is SimHamster and not (last as SimHamster).alive)})
	var bw: Array = W.get("beamW", [3, 6])
	w.emit({"t": "rail_beam", "id": h.id, "team": h.team, "ch": ch, "h": gh, "w": float(bw[0]) + float(bw[1]) * ch, "life": 0.4, "segs": segs})
	var rc: Array = W.get("recoil", [80, 180])
	h.vx -= co * (float(rc[0]) + float(rc[1]) * ch)
	h.vy -= si * (float(rc[0]) + float(rc[1]) * ch)
	h.heat = minf(1.0, h.heat + 0.08)
	w.emit({"t": "fire", "id": h.id, "weapon": "rail", "kind": "rail", "x": h.x, "y": h.y, "gx": segs[0][0] if not segs.is_empty() else h.x, "gy": segs[0][1] if not segs.is_empty() else h.y,
		"gh": gh, "aim": h.aim, "n": 1, "team": h.team, "extra": false, "mode": -1, "side": 0, "ch": ch})


# ---------------------------------------------------------------------------
# 激光枪
# ---------------------------------------------------------------------------

static func laser_update(w: SimWorld, h: SimHamster, dt: float, can_shoot: bool) -> void:
	var W := h.weapon()
	if h.inp.fire and can_shoot:
		h.beam_t -= dt
		if h.beam_t <= 1e-6:
			h.beam_t = float(W.get("tick", 0.1))
			laser_tick(w, h)
	elif not h.beams.is_empty():
		h.beams = []
		w.emit({"t": "laser_stop", "id": h.id})


static func overdrive(w: SimWorld, h: SimHamster) -> bool:
	var S: Dictionary = SimWeapons.params(h).special
	return S.has("overdrive") and fmod(w.t, float(S.overdrive)) < float(S.get("odWindow", 3))


static func laser_tick(w: SimWorld, h: SimHamster) -> void:
	var W := h.weapon()
	var P := SimWeapons.params(h)
	var S: Dictionary = P.special
	h.reveal_t = maxf(h.reveal_t, float(W.get("reveal", 0.3)))
	if w.rnd() < float(W.get("noiseChance", 0.3)):
		w.noise(h.x, h.y, "gun", float(W.get("noise", 0.55)), h)
	h.beam_tick_t = w.t
	h.shot_n += 1
	h.last_shot_t = w.t
	var od := overdrive(w, h)
	var cost := 0.0 if od else maxf(float(W.get("costFloor", 0.2)), float(P.cost))
	h.ammo_f += cost
	while h.ammo_f >= 1.0:
		h.ammo_f -= 1.0
		h.ammo -= 1
	var rng_ := float(W.range) * float(P.range)
	var base := float(W.dmg) * float(P.dmg) * float(h.st.dmg) * (float(S.get("odDmg", 1.3)) if od else 1.0)
	var angs: Array = [[0.0, 1.0]]
	var sa := float(S.get("sideAng", 0.22))
	var side_n := int(S.get("sideBeams", 0))
	if od and S.has("odBeams"):
		side_n = maxi(side_n, int(S.odBeams))     # 超载时额外分出光束
	if side_n >= 1:
		angs.append([sa, float(P.sideK) if int(S.get("sideBeams", 0)) >= 1 else 0.5])
	if side_n >= 2:
		angs.append([-sa, float(P.sideK) if int(S.get("sideBeams", 0)) >= 2 else 0.5])
	# 穿透：光束打中后继续往前照，后面的敌人吃 beamPierceK 倍伤害
	var pierce := int(S.get("beamPierce", 0)) + (int(S.get("odPierce", 0)) if od else 0)
	var R := h.r
	var gh := R + h.z
	var step := float(W.get("step", 8))
	var hit_pad := float(W.get("hitPad", 0.0)) + float(S.get("beamPad", 0.0))     # 光束有一定粗细：擦到边也算照到
	var mr := float(W.get("muzzleR", 2.3))
	h.beams = []
	var main_hit: SimEntity = null
	var cands_all := w.rail_candidates()
	for pair in angs:
		var off := float(pair[0])
		var k := float(pair[1])
		var an := h.aim + off
		var co := cos(an)
		var si := sin(an)
		var gx := h.x + co * R * mr
		var gy := h.y + si * R * mr
		# 先沿光束找到第一堵墙（或物件），再按“敌人到光束线段的距离”挑出被照到的敌人
		# （原来只查光束点所在的空间网格格子，敌人中心在隔壁格子里时擦身而过也算没照到）
		var wall_d := rng_
		var d := 0.0
		while d < rng_:
			var sd := w.map.point_solid(gx + co * d, gy + si * d, 1.0)
			if sd != null:
				if sd.prop != null:
					w.prop_hit(sd.prop as SimProp, base * k, h)
				wall_d = d
				break
			d += step
		var cands: Array = []
		for e: SimEntity in cands_all:
			if not w.can_hit(h.team, e) or e.is_prop:
				continue
			var ex := e.x - gx
			var ey := e.y - gy
			var along := ex * co + ey * si
			if along < -e.r or along > wall_d + e.r:
				continue
			if absf(ex * si - ey * co) < e.r + hit_pad:
				cands.append([along, e])
		cands.sort_custom(func(p1, p2): return float(p1[0]) < float(p2[0]))
		var hits: Array = []
		for c in cands:
			if hits.size() > pierce:
				break
			hits.append(c[1])
		d = wall_d
		if hits.size() > pierce:
			d = clampf(float(cands[pierce][0]), 0.0, wall_d)
		h.beams.append({"x0": gx, "y0": gy, "x1": gx + co * d, "y1": gy + si * d, "h": gh, "hit": not hits.is_empty(), "side": off != 0.0})
		for hi in hits.size():
			var hit: SimEntity = hits[hi]
			var dm := base * k * (1.0 if hi == 0 else float(S.get("beamPierceK", 0.7)))
			if off == 0.0 and hi == 0:
				main_hit = hit
				if float(P.focusCap) > 0.0:
					if h.focus_id == hit.id:
						h.focus_n += 1
					else:
						h.focus_id = hit.id
						h.focus_n = 0
					var cap := float(P.focusCap)
					var ramp := minf(cap, h.focus_n * float(P.focusStep))
					dm *= 1.0 + ramp
					if S.has("focusIgnite") and ramp >= cap - 1e-6:
						hit.burn_t = maxf(hit.burn_t, float(S.focusIgnite))
						hit.burn_by = h
						h.ammo = mini(SimWeapons.mag_size(h), h.ammo + int(S.get("focusRefill", 1)))
						w.emit({"t": "focus_max", "id": h.id, "target": hit.id})
			var dealt := w.deal_dmg(hit, dm, {"team": h.team, "owner": h, "x": hit.x, "y": hit.y, "canCrit": true}, true)
			if dealt > 0.0:
				if off == 0.0:
					SimWeapons.hit_status(w, h, hit, P)
					SimWeapons.hit_extras(w, h, hit, S, dealt, dm)
				w.emit({"t": "hitmark", "id": h.id, "target": hit.id, "kill": hit.dead or (hit is SimHamster and not (hit as SimHamster).alive)})
	if S.has("refract") and main_hit != null:
		# 折射：从被照的敌人跳到附近的下一个，refractN 次
		var cur := main_hit
		var done := {main_hit.id: true}
		var dm2 := base * float(S.get("refractK", 0.5))
		for j in int(S.get("refractN", 1)):
			var o2: SimEntity = null
			var bd := float(S.refract) * float(S.refract)
			for q: SimEntity in w.hash_range(cur.x, cur.y, float(S.refract)):
				if done.has(q.id) or q.is_prop or q.kind == "crate" or not w.can_hit(h.team, q) or (q.kind == "base" and q.shielded):
					continue
				var dq := SimUtil.d2(q.x, q.y, cur.x, cur.y)
				if dq < bd:
					bd = dq
					o2 = q
			if o2 == null:
				break
			done[o2.id] = true
			w.deal_dmg(o2, dm2, {"team": h.team, "owner": h, "x": o2.x, "y": o2.y, "canCrit": true}, true)
			h.beams.append({"x0": cur.x, "y0": cur.y, "x1": o2.x, "y1": o2.y, "h": gh, "hit": true, "side": true})
			cur = o2
	w.emit({"t": "laser_tick", "id": h.id, "od": od, "hit": main_hit != null})


# ---------------------------------------------------------------------------
# 武器开火分派（每帧，仓鼠更新里调用）
# ---------------------------------------------------------------------------

static func update_weapon(w: SimWorld, h: SimHamster, dt: float, can_shoot: bool) -> void:
	match String(h.weapon().get("kind", "bullet")):
		"rail":
			rail_update(w, h, dt, can_shoot)
		"laser":
			laser_update(w, h, dt, can_shoot)
		_:
			SimWeapons.try_fire(w, h, can_shoot, dt)
