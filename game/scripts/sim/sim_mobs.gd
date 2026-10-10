class_name SimMobs
extends RefCounted
## 野区（蟑螂窝、鼠帮枪手营地）、鼠王、宠物。对应原型 n2.js 的 mkMob / spawnCamp / aggro / mobShoot / updMob / mkPet / updPet。
## 数值在 units.json（mobs 的半径、血量、速度）和 rules.json 的 mobs / boss / pets；鼠王出现时间和奖励在 progression.json。


# ---------------------------------------------------------------------------
# 营地与生成
# ---------------------------------------------------------------------------

static func make_mob(w: SimWorld, type: String, camp: Dictionary, x: float, y: float) -> SimMob:
	var T: Dictionary = Data.units().mobs[type]
	var e := SimMob.new()
	e.id = w.new_uid()
	e.kind = type
	e.team = "neutral"
	e.camp = camp
	e.x = x
	e.y = y
	e.px = x
	e.py = y
	e.hx = x
	e.hy = y
	e.tx = x
	e.ty = y
	e.r = float(T.r)
	e.hp = float(T.hp)
	e.max_hp = e.hp
	e.spd = float(T.spd)
	e.aim = w.rand(0.0, TAU)
	e.heading = w.rand(0.0, TAU)
	e.t = w.rand(0.0, 5.0)
	e.ph = w.rand(0.0, TAU)
	e.cd = w.rand(0.6, 1.4)
	e.leash = float(w.R.boss.leash) if type == "boss" else float(w.R.mobs.leash)
	e.ring_t = float(w.R.boss.ringFirst)
	e.sum_t = float(w.R.boss.sumFirst)
	w.map.resolve_circle(e, e.r)
	w.mobs.append(e)
	w.register(e)
	w.emit({"t": "spawn", "id": e.id, "kind": type})
	return e


static func spawn_camp(w: SimWorld, c: Dictionary) -> void:
	var M: Dictionary = w.R.mobs
	var n := int(M[c.type].camp)
	var j := float(M.campJitter)
	for i in n:
		make_mob(w, String(c.type), c, float(c.x) + w.rand(-j, j), float(c.y) + w.rand(-j, j))
	c.alive = n
	c.resp = 1e9


static func spawn_boss(w: SimWorld) -> void:
	var b := make_mob(w, "boss", {}, w.map.boss_pos.x, w.map.boss_pos.y)
	w.boss = b
	w.toast_all("鼠王出现在地图上方正中！", "#ffd166", 3.0)
	w.add_feed("鼠王出现了", "#ffd166")
	w.emit({"t": "boss_spawn", "id": b.id, "x": b.x, "y": b.y})


static func update_spawns(w: SimWorld) -> void:
	if w.map.boss_pos != Vector2.ZERO:
		if w.boss == null and w.t >= w.boss_next:
			spawn_boss(w)
		if w.boss != null and w.boss.dead:
			w.boss = null
	for c in w.camps:
		if int(c.alive) <= 0 and w.t >= float(c.resp):
			spawn_camp(w, c)


static func aggro(w: SimWorld, e: SimMob, o: SimEntity) -> void:
	if e.dead or o == null or not (o is SimHamster or o is SimMinion):
		return
	if o is SimHamster and not (o as SimHamster).alive:
		return
	var grp: Array = []
	if not e.camp.is_empty():
		for m in w.mobs:
			if m.camp == e.camp and not m.dead:
				grp.append(m)
	else:
		grp = [e]
	for m: SimMob in grp:
		if m.target == null:
			m.target = o
			m.returning = false


static func on_kill(w: SimWorld, t: SimMob, src: Dictionary) -> void:
	var M: Dictionary = w.R.mobs
	t.dead = true
	var killer: SimHamster = src.get("owner") as SimHamster if src.get("owner") is SimHamster else null
	if t.kind == "boss":
		var PR: Dictionary = Data.progression()
		var B: Dictionary = w.R.boss
		w.boss_next = w.t + float(PR.get("bossRespawn", 150))
		if killer != null:
			SimHamsterLogic.give_xp(w, killer, float(B.killXp))
			for h in w.hams:
				if h.team == killer.team:
					SimHamsterLogic.give_xp(w, h, float(PR.bossReward.xpEach))
					h.crown_t = float(PR.bossReward.crownSeconds)
					SimHamsterLogic.calc_stats(h)
			w.add_feed("%s 击败了鼠王！" % killer.name, "#ffd166")
			w.toast_all("%s击败鼠王，全队获得王冠加成！" % w.tname(killer.team), "#ffd166", 3.0)
		for i in int(B.gems):
			w.drop_gem(t.x, t.y, float(B.gemXp))
		w.emit({"t": "kill", "id": t.id, "kind": "boss", "x": t.x, "y": t.y, "team": "neutral", "killer": killer.id if killer != null else -1})
		w.emit({"t": "explode", "x": t.x, "y": t.y, "r": 200.0, "big": true})
		return
	var D: Dictionary = M[t.kind]
	if not t.camp.is_empty():
		t.camp.alive = int(t.camp.alive) - 1
		if int(t.camp.alive) <= 0:
			t.camp.resp = w.t + float(D.resp)
	w.xp_near(killer, t, float(D.xp))
	w.drop_loot(t.x, t.y, D)
	if t.kind == "rat":
		w.emit({"t": "pop", "x": t.x, "y": t.y, "h": t.r * 2.8, "text": "吱！", "color": "#ffb3c1", "size": 18})
	w.emit({"t": "kill", "id": t.id, "kind": t.kind, "x": t.x, "y": t.y, "team": "neutral", "killer": killer.id if killer != null else -1})


# ---------------------------------------------------------------------------
# 野怪行为
# ---------------------------------------------------------------------------

static func _shoot(w: SimWorld, e: SimMob, a: float, kind: String, spd: float, dmg: float, r: float) -> void:
	var M: Dictionary = w.R.mobs
	e.reveal_t = 0.4
	if w.rnd() < 0.5:
		w.noise(e.x, e.y, "monster", 1.3 if e.kind == "boss" else 0.8, e)
	var b := w.new_bullet(kind, e, e.x + cos(a) * e.r, e.y + sin(a) * e.r, e.r * 0.95, a, spd, dmg, float(M.shotRange))
	b.r = r
	b.kb = float(M.shotKb)
	w.bullets.append(b)


static func update(w: SimWorld, e: SimMob, dt: float) -> void:
	var M: Dictionary = w.R.mobs
	e.save_prev()
	e.t += dt
	e.flash = maxf(0.0, e.flash - dt)
	e.slow_t = maxf(0.0, e.slow_t - dt)
	e.reveal_t = maxf(0.0, e.reveal_t - dt)
	e.recoil = maxf(0.0, e.recoil - dt * 8.0)
	w.burn_tick(e, dt)
	if e.dead:
		return
	e.kx = SimUtil.damp(e.kx, 0.0, 9.0, dt)
	e.ky = SimUtil.damp(e.ky, 0.0, 9.0, dt)
	var t := e.target
	if t != null and (t.dead or (t is SimHamster and not (t as SimHamster).alive) or Vector2(e.x - e.hx, e.y - e.hy).length() > e.leash or Vector2(t.x - e.x, t.y - e.y).length() > float(M.dropTarget)):
		e.target = null
		t = null
		e.returning = true
		e.tele = 0.0
		e.burst = 0
	if t == null and not e.returning:
		e.los_t -= dt
		if e.los_t <= 0.0:
			e.los_t = float(M.losCheck)
			var R := float(w.R.boss.aggroR) if e.kind == "boss" else float(M[e.kind].aggroR)
			var f: SimEntity = null
			for c: SimEntity in w.hash_range(e.x, e.y, R):
				if ((c is SimHamster and (c as SimHamster).alive) or c is SimMinion) and not c.dead and Vector2(c.x - e.x, c.y - e.y).length() < R and w.map.has_los(e.x, e.y, c.x, c.y):
					f = c
					break
			if f != null:
				aggro(w, e, f)
				t = e.target
	var sp := e.spd * (0.6 if e.slow_t > 0.0 else 1.0)
	if e.frozen_until > w.t:
		sp = 0.0
	if e.stun > 0.0:
		e.stun -= dt
		e.vx = SimUtil.damp(e.vx, 0.0, 8.0, dt)
		e.vy = SimUtil.damp(e.vy, 0.0, 8.0, dt)
	elif e.returning:
		var dx := e.hx - e.x
		var dy := e.hy - e.y
		var d := Vector2(dx, dy).length()
		if d < 30.0:
			e.returning = false
		else:
			e.vx = SimUtil.damp(e.vx, dx / d * sp * 1.2, 6.0, dt)
			e.vy = SimUtil.damp(e.vy, dy / d * sp * 1.2, 6.0, dt)
		e.hp = minf(e.max_hp, e.hp + e.max_hp * float(M.returnHeal) * dt)
	elif t == null:
		e.wt -= dt
		if e.wt <= 0.0:
			e.wt = w.rand(1.0, 2.6)
			var a := w.rand(0.0, TAU)
			var rr := w.rand(0.0, float(M[e.kind].wander) if e.kind != "boss" else 110.0)
			e.tx = e.hx + cos(a) * rr
			e.ty = e.hy + sin(a) * rr
		var tx := e.tx - e.x
		var ty := e.ty - e.y
		var tl := Vector2(tx, ty).length()
		if tl > 8.0:
			e.vx = SimUtil.damp(e.vx, tx / tl * sp * 0.4, 6.0, dt)
			e.vy = SimUtil.damp(e.vy, ty / tl * sp * 0.4, 6.0, dt)
			e.aim = atan2(ty, tx)
		else:
			e.vx = SimUtil.damp(e.vx, 0.0, 8.0, dt)
			e.vy = SimUtil.damp(e.vy, 0.0, 8.0, dt)
	else:
		var dx := t.x - e.x
		var dy := t.y - e.y
		var d := maxf(0.001, Vector2(dx, dy).length())
		var ta := atan2(dy, dx)
		var los := w.map.has_los(e.x, e.y, t.x, t.y)
		match e.kind:
			"roach":
				_roach(w, e, t, dx, dy, d, los, sp, dt)
			"rat":
				_rat(w, e, t, dx, dy, d, ta, los, sp, dt)
			_:
				_boss(w, e, t, dx, dy, d, ta, los, sp, dt)
	e.x += (e.vx + e.kx) * dt
	e.y += (e.vy + e.ky) * dt
	w.map.resolve_circle(e, e.r)
	if e.kind != "roach":
		e.walk += Vector2(e.vx, e.vy).length() * dt * 0.17
	else:
		e.walk += Vector2(e.vx, e.vy).length() * dt * 0.5
	if Vector2(e.vx, e.vy).length() > 8.0:
		e.heading = SimUtil.turn_to(e.heading, atan2(e.vy, e.vx), 12.0 * dt)


static func _roach(w: SimWorld, e: SimMob, t: SimEntity, dx: float, dy: float, d: float, los: bool, sp: float, dt: float) -> void:
	var D: Dictionary = w.R.mobs.roach
	var mx: float
	var my: float
	if los:
		mx = dx / d
		my = dy / d
	else:
		var f := w.map.field_dir(w.map.field_to(t.x, t.y), e.x, e.y, t.x, t.y)
		mx = f.x
		my = f.y
	var z := sin(e.t * 10.0 + e.ph) * float(D.zigzag)
	var px := -my
	var py := mx
	mx += px * z
	my += py * z
	var ml := maxf(0.001, Vector2(mx, my).length())
	e.vx = SimUtil.damp(e.vx, mx / ml * sp, 9.0, dt)
	e.vy = SimUtil.damp(e.vy, my / ml * sp, 9.0, dt)
	e.aim = atan2(e.vy, e.vx)
	e.bcd -= dt
	if d < e.r + t.r + 5.0 and e.bcd <= 0.0:
		e.bcd = float(D.biteCd)
		w.deal_dmg(t, float(D.bite), {"team": "neutral", "owner": null, "by": e, "x": e.x, "y": e.y})
		w.knock(t, dx, dy, float(D.biteKb))
		w.emit({"t": "bite", "id": e.id, "target": t.id, "x": t.x, "y": t.y})


static func _rat(w: SimWorld, e: SimMob, t: SimEntity, dx: float, dy: float, d: float, ta: float, los: bool, sp: float, dt: float) -> void:
	var D: Dictionary = w.R.mobs.rat
	if e.tele > 0.0 or e.burst > 0:
		e.vx = SimUtil.damp(e.vx, 0.0, 10.0, dt)
		e.vy = SimUtil.damp(e.vy, 0.0, 10.0, dt)
		if e.tele > 0.0:
			e.aim = SimUtil.turn_to(e.aim, ta, 2.4 * dt)
			e.tele -= dt
			if e.tele <= 0.0:
				e.burst = int(D.burst)
				e.bt = 0.0
		else:
			e.bt -= dt
			if e.bt <= 0.0:
				_shoot(w, e, e.aim + w.rand(-float(D.spread), float(D.spread)), "rat", float(D.shotSpd), float(D.shotDmg), float(D.shotR))
				w.emit({"t": "mob_fire", "id": e.id, "kind": "rat", "x": e.x, "y": e.y, "aim": e.aim})
				e.recoil = 1.0
				e.burst -= 1
				e.bt = float(D.burstGap)
				if e.burst <= 0:
					var cd: Array = D.cd
					e.cd = w.rand(float(cd[0]), float(cd[1]))
	else:
		e.cd -= dt
		if los and d < float(D.engage):
			e.st_t -= dt
			if e.st_t <= 0.0:
				e.st_t = w.rand(0.9, 1.9)
				e.sdir = -1.0 if w.rnd() < 0.5 else 1.0
			var ux := dx / d
			var uy := dy / d
			var rad := clampf((d - float(D.keep)) / 120.0, -1.0, 1.0)
			var mx := ux * rad - uy * e.sdir * 0.75
			var my := uy * rad + ux * e.sdir * 0.75
			var ml := maxf(0.001, Vector2(mx, my).length())
			e.vx = SimUtil.damp(e.vx, mx / ml * sp, 6.0, dt)
			e.vy = SimUtil.damp(e.vy, my / ml * sp, 6.0, dt)
			e.aim = SimUtil.turn_to(e.aim, ta, 6.0 * dt)
			if e.cd <= 0.0:
				e.tele = float(D.tele)
				e.cd = 99.0
				w.emit({"t": "mob_aim", "id": e.id})
		else:
			var f := w.map.field_dir(w.map.field_to(t.x, t.y), e.x, e.y, t.x, t.y)
			e.vx = SimUtil.damp(e.vx, f.x * sp, 6.0, dt)
			e.vy = SimUtil.damp(e.vy, f.y * sp, 6.0, dt)
			e.aim = SimUtil.turn_to(e.aim, atan2(f.y, f.x), 6.0 * dt)


static func _boss(w: SimWorld, e: SimMob, t: SimEntity, dx: float, dy: float, d: float, ta: float, los: bool, sp: float, dt: float) -> void:
	var B: Dictionary = w.R.boss
	e.aim = SimUtil.turn_to(e.aim, ta, 3.0 * dt)
	var rad := clampf((d - float(B.keep)) / 150.0, -1.0, 1.0)
	e.vx = SimUtil.damp(e.vx, dx / d * rad * sp, 4.0, dt)
	e.vy = SimUtil.damp(e.vy, dy / d * rad * sp, 4.0, dt)
	e.cd -= dt
	e.ring_t -= dt
	e.sum_t -= dt
	if e.cd <= 0.0 and los:
		e.cd = float(B.fanCd)
		var n := int(B.fanN)
		for k in n:
			_shoot(w, e, ta + (k - (n - 1) * 0.5) * float(B.fanStep), "orb", float(B.fanSpd), float(B.fanDmg), float(B.orbR))
		e.recoil = 1.0
		w.emit({"t": "mob_fire", "id": e.id, "kind": "boss_fan", "x": e.x, "y": e.y, "aim": ta})
	if e.ring_t <= 0.0:
		e.ring_t = float(B.ringCd)
		var n2 := int(B.ringN)
		for k in n2:
			_shoot(w, e, float(k) / n2 * TAU + e.t, "orb", float(B.ringSpd), float(B.ringDmg), float(B.orbR))
		w.emit({"t": "boss_ring", "id": e.id, "x": e.x, "y": e.y, "r": e.r})
	if e.sum_t <= 0.0:
		e.sum_t = float(B.sumCd)
		var cur := 0
		for m in w.mobs:
			if m.summoned and not m.dead:
				cur += 1
		for k in int(B.sumN):
			if cur + k >= int(B.sumMax):
				break
			var m2 := make_mob(w, "rat", {}, e.x + w.rand(-60.0, 60.0), e.y + w.rand(-60.0, 60.0))
			m2.hx = e.hx
			m2.hy = e.hy
			m2.summoned = true
			m2.target = t
			w.emit({"t": "summon", "id": m2.id, "x": m2.x, "y": m2.y})


# ---------------------------------------------------------------------------
# 宠物
# ---------------------------------------------------------------------------

static func make_pet(w: SimWorld, type: String, owner: SimHamster) -> SimPet:
	var p := SimPet.new()
	p.id = w.new_uid()
	p.kind = "pet"
	p.type = type
	p.owner = owner
	p.team = owner.team
	p.x = owner.x
	p.y = owner.y
	p.px = p.x
	p.py = p.y
	p.h = float(w.R.pets.firefly.h) if type == "firefly" else 0.0
	p.cd = w.rand(0.3, 1.0)
	p.t = w.rand(0.0, 5.0)
	p.r = 8.0
	w.pets.append(p)
	w.emit({"t": "spawn", "id": p.id, "kind": "pet", "type": type, "owner": owner.id})
	return p


static func update_pet(w: SimWorld, p: SimPet, dt: float) -> void:
	var PD: Dictionary = w.R.pets
	var o := p.owner
	p.save_prev()
	p.t += dt
	p.cd -= dt
	if o == null or not w.hams.has(o):
		p.dead = true
		return
	var base: Vector2 = w.map.base_pos[o.team]
	var ax := o.x if o.alive else base.x
	var ay := o.y if o.alive else base.y
	match p.type:
		"firefly":
			var F: Dictionary = PD.firefly
			var a := p.t * float(F.spin)
			p.x = SimUtil.damp(p.x, ax + cos(a) * float(F.orbit), 10.0, dt)
			p.y = SimUtil.damp(p.y, ay + sin(a) * float(F.orbit), 10.0, dt)
			p.h = float(F.h) + sin(p.t * 5.0) * 6.0
			if p.cd <= 0.0 and o.alive:
				var e := w.nearest_foe(p.team, p.x, p.y, float(F.range))
				if e != null:
					p.cd = maxf(float(F.cdMin), float(F.cdBase) - float(F.cdPer) * p.lvl)
					w.deal_dmg(e, (float(F.dmg) + float(F.dmgPer) * p.lvl) * float(o.st.dmg), {"team": p.team, "owner": o, "x": p.x, "y": p.y})
					w.emit({"t": "zap", "x0": p.x, "y0": p.y, "h0": p.h, "x1": e.x, "y1": e.y, "h1": e.r, "pet": p.id})
		"chick":
			var C: Dictionary = PD.chick
			if p.target != null and (p.target.dead or (p.target is SimHamster and not (p.target as SimHamster).alive) or Vector2(p.target.x - ax, p.target.y - ay).length() > float(C.leash)):
				p.target = null
			if p.target == null and o.alive and p.cd <= 0.0:
				p.target = w.nearest_foe(p.team, ax, ay, float(C.range))
			var tx: float
			var ty: float
			if p.target != null:
				tx = p.target.x
				ty = p.target.y
			else:
				var a2 := o.aim
				tx = ax - cos(a2) * 30.0 - sin(a2) * 22.0
				ty = ay - sin(a2) * 30.0 + cos(a2) * 22.0
			var dx := tx - p.x
			var dy := ty - p.y
			var d := maxf(0.001, Vector2(dx, dy).length())
			var sp := float(C.speed) if p.target != null else minf(float(C.follow), d * 6.0)
			p.vx = dx / d * sp
			p.vy = dy / d * sp
			p.x += p.vx * dt
			p.y += p.vy * dt
			if d > 2.0:
				p.aim = atan2(dy, dx)
			if p.target != null and d < p.target.r + float(C.reach) and p.cd <= 0.0:
				p.cd = float(C.cd)
				w.deal_dmg(p.target, (float(C.dmg) + float(C.dmgPer) * p.lvl) * float(o.st.dmg), {"team": p.team, "owner": o, "x": p.x, "y": p.y})
				w.emit({"t": "peck", "pet": p.id, "x": p.target.x, "y": p.target.y})
		_:
			var Hh: Dictionary = PD.hedgehog
			var a3 := o.aim
			var tx2 := ax - cos(a3) * 34.0 + sin(a3) * 20.0
			var ty2 := ay - sin(a3) * 34.0 - cos(a3) * 20.0
			p.x = SimUtil.damp(p.x, tx2, 6.0, dt)
			p.y = SimUtil.damp(p.y, ty2, 6.0, dt)
			if p.cd <= 0.0 and o.alive:
				var e2 := w.nearest_foe(p.team, p.x, p.y, float(Hh.range))
				if e2 != null:
					p.cd = maxf(float(Hh.cdMin), float(Hh.cdBase) - float(Hh.cdPer) * p.lvl)
					var b0 := atan2(e2.y - p.y, e2.x - p.x)
					p.aim = b0
					for k in [-1, 0, 1]:
						var b := w.new_bullet("spike", p, p.x, p.y, 10.0, b0 + k * float(Hh.spread), float(Hh.spd), (float(Hh.dmg) + float(Hh.dmgPer) * p.lvl) * float(o.st.dmg), float(Hh.bulletRange))
						b.r = float(Hh.r)
						b.kb = float(Hh.kb)
						b.owner = o
						b.weapon = "spike"
						w.bullets.append(b)
					w.emit({"t": "pet_fire", "pet": p.id, "x": p.x, "y": p.y, "aim": b0})
