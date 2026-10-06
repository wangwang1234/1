class_name SimGadgets
extends RefCounted
## 战术道具（13 种）：手雷、燃烧瓶、闪光弹、地雷、哨戒炮、能量护盾、烟雾弹、照明弹、诱饵、喷射背包、急救包、冰冻弹、传送信标。
## 对应原型 n2c.js 的 useGadget / lobBoom / updEvoWorld（烟雾、照明、诱饵）与 n2.js 的 placeMine / updMines / placeSentry / flashBang。
## 数值全部在 rules.json 的 gadgets。


static func lvl_k(L: int, per: float) -> float:
	return 1.0 + per * (L - 1)


static func target(w: SimWorld, h: SimHamster) -> Vector2:
	var G: Dictionary = w.R.gadgets
	var tx: float
	var ty: float
	if h.inp.has_aim_point:
		tx = h.inp.aim_x
		ty = h.inp.aim_y
	else:
		var tg: SimEntity = h.ai.target if h.ai != null else SimWeapons.auto_aim(w, h, 520.0)
		if tg != null and not tg.dead and Vector2(tg.x - h.x, tg.y - h.y).length() < 560.0:
			tx = tg.x
			ty = tg.y
		else:
			tx = h.x + cos(h.aim) * 300.0
			ty = h.y + sin(h.aim) * 300.0
	var dx := tx - h.x
	var dy := ty - h.y
	var d := maxf(0.001, Vector2(dx, dy).length())
	var dd := clampf(d, float(G.throwMin), float(G.throwMax))
	return Vector2(h.x + dx / d * dd, h.y + dy / d * dd)


static func use(w: SimWorld, h: SimHamster) -> void:
	var G: Dictionary = w.R.gadgets
	var id := String(h.gadget.id)
	var L := int(h.gadget.lvl)
	var G0: Dictionary = Data.gadgets().get(id, {"cd": 7})
	h.gadget.cd = float(G0.cd) * maxf(0.2, 1.0 + float(G.cdPerLevel) * (L - 1)) * float(h.st.gcd)
	w.emit({"t": "gadget", "id": h.id, "gadget": id, "lvl": L})
	match id:
		"mine":
			_place_mine(w, h, L)
			return
		"sentry":
			_place_sentry(w, h, L)
			return
		"eshield":
			var E: Dictionary = G.eshield
			h.eshield = h.max_hp * float(E.hpK) * lvl_k(L, float(E.hpPerLevel))
			h.eshield_t = float(E.dur)
			w.toast(h, "能量护盾！", "#7fe3ff", 1.0)
			return
		"medkit":
			var M: Dictionary = G.medkit
			h.med_t = float(M.dur)
			h.med_rate = h.max_hp * float(M.heal) * lvl_k(L, float(M.healPerLevel)) / float(M.dur)
			w.toast(h, "嚼嚼回血", "#8de0a6", 1.0)
			return
		"jetpack":
			var J: Dictionary = G.jetpack
			var p := target(w, h)
			var dx := p.x - h.x
			var dy := p.y - h.y
			var d := maxf(0.001, Vector2(dx, dy).length())
			var dd := clampf(d, float(J.min), float(J.max) + float(J.maxPerLevel) * (L - 1))
			h.air = {"t": 0.0, "dur": float(J.dur), "x0": h.x, "y0": h.y, "x1": h.x + dx / d * dd, "y1": h.y + dy / d * dd, "hgt": float(J.hgt), "jet": true}
			h.jet_t = float(J.jetT)
			h.roll_t = 0.0
			return
		"decoy":
			_spawn_decoy(w, h, L)
			return
		"beacon":
			var B: Dictionary = G.beacon
			if not h.beacon.is_empty():
				var fx := h.x
				var fy := h.y
				h.x = float(h.beacon.x)
				h.y = float(h.beacon.y)
				h.px = h.x
				h.py = h.y
				h.vx = 0.0
				h.vy = 0.0
				h.beacon = {}
				h.iframes = maxf(h.iframes, float(B.iframes))
				w.emit({"t": "teleport", "id": h.id, "x0": fx, "y0": fy, "x1": h.x, "y1": h.y, "team": h.team})
			else:
				h.beacon = {"x": h.x, "y": h.y, "until": w.t + float(B.life)}
				h.gadget.cd = float(B.armCd)
				w.emit({"t": "beacon_set", "id": h.id, "x": h.x, "y": h.y, "team": h.team})
				w.toast(h, "信标已插好，再按一次传送回来", "#7fe3ff", 1.6)
			return
	var p2 := target(w, h)
	h.spit_t = 0.2
	match id:
		"molotov":
			w.throw_lob(h, "molo", p2.x, p2.y, {"sp": float(G.molotov.speed), "lvl": L})
		"flash":
			w.throw_lob(h, "flsh", p2.x, p2.y, {"sp": float(G.flash.speed), "fuse": float(G.flash.fuse), "lvl": L})
		"smoke":
			w.throw_lob(h, "smk", p2.x, p2.y, {"sp": float(G.smoke.speed), "lvl": L})
		"flare":
			w.throw_lob(h, "flr", p2.x, p2.y, {"sp": float(G.flare.speed), "lvl": L})
		"freeze":
			w.throw_lob(h, "frz", p2.x, p2.y, {"sp": float(G.freeze.speed), "fuse": float(G.freeze.fuse), "lvl": L})
		_:
			var F: Dictionary = G.frag
			w.throw_lob(h, "frag", p2.x, p2.y, {"sp": float(F.speed), "fuse": float(F.fuse), "aoe": float(F.aoe), "dmg": float(F.dmg) * lvl_k(L, float(F.dmgPerLevel)), "kb": float(F.kb), "lvl": L})


static func tick_hamster(w: SimWorld, h: SimHamster, dt: float) -> void:
	## 原型 evoTick 里的道具计时：能量护盾、急救包、喷射背包
	if h.eshield_t > 0.0:
		h.eshield_t -= dt
		if h.eshield_t <= 0.0:
			h.eshield = 0.0
	if h.med_t > 0.0:
		h.med_t -= dt
		h.hp = minf(h.max_hp, h.hp + h.med_rate * dt)
		h.munch_t = maxf(h.munch_t, 0.15)
	if h.jet_t > 0.0:
		h.jet_t -= dt


# ---------------------------------------------------------------------------
# 投掷物落地（燃烧瓶 / 闪光 / 烟雾 / 冰冻）
# ---------------------------------------------------------------------------

static func lob_boom(w: SimWorld, b: SimLob) -> void:
	var G: Dictionary = w.R.gadgets
	var L := b.lvl
	match b.kind:
		"molo":
			var M: Dictionary = G.molotov
			w.add_fire(b.x, b.y, float(M.r) + float(M.rPerLevel) * (L - 1), float(M.life) + float(M.lifePerLevel) * (L - 1), b.team, b.owner,
				float(M.dps) * lvl_k(L, float(M.dpsPerLevel)), "molotov")
			w.noise(b.x, b.y, "boom", 0.8, null)
			w.emit({"t": "molotov", "x": b.x, "y": b.y})
		"flsh":
			flash_bang(w, b.x, b.y, b.team)
		"smk":
			var S: Dictionary = G.smoke
			add_smoke(w, b.x, b.y, float(S.r) * lvl_k(L, float(S.rPerLevel)), float(S.life) + float(S.lifePerLevel) * (L - 1))
		"frz":
			var Z: Dictionary = G.freeze
			var R := float(Z.r) + float(Z.rPerLevel) * (L - 1)
			w.emit({"t": "freeze", "x": b.x, "y": b.y, "r": R})
			for e: SimEntity in w.hash_range(b.x, b.y, R + 40.0):
				if not w.can_hit(b.team, e) or e.is_prop or e.kind in ["crate", "base", "turret"]:
					continue
				if Vector2(e.x - b.x, e.y - b.y).length() - e.r > R:
					continue
				w.stun_e(e, float(Z.stun))
				e.frozen_until = w.t + (float(Z.frozenHam) if e is SimHamster else float(Z.frozen))
				w.deal_dmg(e, float(Z.dmg), {"team": b.team, "owner": b.owner, "x": b.x, "y": b.y})


static func add_smoke(w: SimWorld, x: float, y: float, r: float, life: float) -> void:
	var s := {"id": w.new_uid(), "x": x, "y": y, "r": r, "t": 0.0, "life": life}
	w.smokes.append(s)
	w.emit({"t": "smoke", "sid": s.id, "x": x, "y": y, "r": r, "life": life})


static func flash_bang(w: SimWorld, x: float, y: float, team: String) -> void:
	var F: Dictionary = w.R.gadgets.flash
	var R := float(F.r)
	w.noise(x, y, "boom", 1.2, null)
	w.emit({"t": "flashbang", "x": x, "y": y, "r": R})
	w.boom_light(x, y)
	for h in w.hams:
		if not h.alive or h.team == team:
			continue
		var d := Vector2(h.x - x, h.y - y).length()
		if d > R or not w.map.has_los(x, y, h.x, h.y):
			continue
		var k := clampf(float(F.kBase) - d / R, float(F.kMin), 1.0)
		if h.ctl == "player":
			w.emit({"t": "blind", "id": h.id, "amount": float(F.blind) * k})
		else:
			h.blind_t = maxf(h.blind_t, float(F.blindAi) * k)
	for m in w.minions:
		if not m.dead and m.team != team and Vector2(m.x - x, m.y - y).length() < R:
			m.stun = float(F.stun)
	for e in w.mobs:
		if not e.dead and Vector2(e.x - x, e.y - y).length() < R:
			e.stun = float(F.stun)


# ---------------------------------------------------------------------------
# 地雷
# ---------------------------------------------------------------------------

static func _place_mine(w: SimWorld, h: SimHamster, L: int) -> void:
	var M: Dictionary = w.R.gadgets.mine
	var own: Array = w.mines.filter(func(m): return m.owner == h)
	if own.size() >= int(M.max):
		w.mines.erase(own[0])
		w.emit({"t": "mine_gone", "mid": own[0].id})
	var m := {"id": w.new_uid(), "x": h.x, "y": h.y, "team": h.team, "owner": h, "arm": float(M.arm), "lvl": L, "t": 0.0, "r": float(M.visR)}
	w.mines.append(m)
	w.emit({"t": "mine", "mid": m.id, "x": h.x, "y": h.y, "team": h.team, "id": h.id})


static func update_mines(w: SimWorld, dt: float) -> void:
	var M: Dictionary = w.R.gadgets.mine
	var i := w.mines.size() - 1
	while i >= 0:
		var m: Dictionary = w.mines[i]
		m.t += dt
		if m.arm > 0.0:
			m.arm -= dt
			i -= 1
			continue
		var trig := false
		for e: SimEntity in w.hash_range(m.x, m.y, float(M.scanR)):
			if not w.can_hit(m.team, e) or e.is_prop or e.kind in ["crate", "base", "turret", "sentry"]:
				continue
			if Vector2(e.x - m.x, e.y - m.y).length() < e.r + float(M.trigR):
				trig = true
				break
		if trig:
			w.mines.remove_at(i)
			w.emit({"t": "mine_gone", "mid": m.id})
			var o: SimHamster = m.owner if is_instance_valid(m.owner) else null
			w.blast(m.x, m.y, float(M.blastR), float(M.dmg) * lvl_k(int(m.lvl), float(M.dmgPerLevel)), m.team, o, float(M.kb), {"src": "mine"})
		i -= 1


# ---------------------------------------------------------------------------
# 哨戒炮（作为 SimStructure，kind = sentry，由 SimWorld._upd_struct 驱动）
# ---------------------------------------------------------------------------

static func _place_sentry(w: SimWorld, h: SimHamster, L: int) -> void:
	var S: Dictionary = w.R.gadgets.sentry
	for s in w.structs:
		if s.kind == "sentry" and s.owner == h and not s.dead:
			s.dead = true
			w.emit({"t": "kill", "id": s.id, "kind": "sentry", "x": s.x, "y": s.y, "team": s.team, "killer": -1})
	var a := h.aim
	var s2 := SimStructure.new()
	s2.id = w.new_uid()
	s2.kind = "sentry"
	s2.team = h.team
	s2.owner = h
	s2.x = h.x + cos(a) * float(S.dist)
	s2.y = h.y + sin(a) * float(S.dist)
	s2.r = float(S.r)
	s2.hp = float(S.hp) * lvl_k(L, float(S.hpPerLevel))
	s2.max_hp = s2.hp
	s2.cd = 0.5
	s2.cd_max = float(S.cd)
	s2.range_ = float(S.range)
	s2.dmg = float(S.dmg) * lvl_k(L, float(S.dmgPerLevel))
	s2.aim = a
	s2.life = float(S.life) + float(S.lifePerLevel) * (L - 1)
	s2.muzzle_h = float(S.muzzleH)
	w.map.resolve_circle(s2, s2.r)
	s2.px = s2.x
	s2.py = s2.y
	w.structs.append(s2)
	w.register(s2)
	w.emit({"t": "spawn", "id": s2.id, "kind": "sentry", "team": h.team})


static func update_sentry(w: SimWorld, s: SimStructure, dt: float) -> void:
	var S: Dictionary = w.R.gadgets.sentry
	s.life -= dt
	if s.life <= 0.0:
		s.dead = true
		w.emit({"t": "kill", "id": s.id, "kind": "sentry", "x": s.x, "y": s.y, "team": s.team, "killer": -1})
		return
	if s.t_t <= 0.0:
		s.t_t = float(S.retarget)
		s.target = w.struct_target(s)
	var tg := s.target
	if tg != null and (tg.dead or (tg is SimHamster and not (tg as SimHamster).alive)):
		tg = null
	if tg == null:
		return
	var a := atan2(tg.y - s.y, tg.x - s.x)
	s.aim = SimUtil.turn_to(s.aim, a, float(S.turn) * dt)
	if s.cd <= 0.0 and absf(SimUtil.ang_diff(s.aim, a)) < float(S.fireAngle):
		s.cd = float(S.cd)
		var gx := s.x + cos(s.aim) * float(S.muzzle)
		var gy := s.y + sin(s.aim) * float(S.muzzle)
		var b := w.new_bullet("trc", s, gx, gy, float(S.muzzleH), s.aim + w.rand(-float(S.spread), float(S.spread)), float(S.bulletSpeed), s.dmg, s.range_ + 60.0)
		b.r = float(S.bulletR)
		b.kb = float(S.kb)
		b.owner = s.owner if is_instance_valid(s.owner) and s.owner.team == s.team else null
		b.weapon = "sentry"
		w.bullets.append(b)
		w.noise(s.x, s.y, "gun", 0.5, s)
		w.emit({"t": "struct_fire", "id": s.id, "x": gx, "y": gy, "h": float(S.muzzleH), "aim": s.aim, "team": s.team, "kind": "sentry"})


# ---------------------------------------------------------------------------
# 诱饵
# ---------------------------------------------------------------------------

static func _spawn_decoy(w: SimWorld, h: SimHamster, L: int) -> void:
	var D: Dictionary = w.R.gadgets.decoy
	var a := h.aim
	var d := SimDecoy.new()
	d.id = w.new_uid()
	d.kind = "decoy"
	d.team = h.team
	d.owner = h
	d.skin = h.skin
	d.weapon_id = h.weapon_id
	d.x = h.x + cos(a) * float(D.dist)
	d.y = h.y + sin(a) * float(D.dist)
	d.r = float(D.r)
	d.hp = float(D.hp) * lvl_k(L, float(D.hpPerLevel))
	d.max_hp = d.hp
	d.life = float(D.life) + float(D.lifePerLevel) * (L - 1)
	d.aim = a
	w.map.resolve_circle(d, d.r)
	d.px = d.x
	d.py = d.y
	w.decoys.append(d)
	w.register(d)
	w.emit({"t": "spawn", "id": d.id, "kind": "decoy", "team": h.team})


static func update_world(w: SimWorld, dt: float) -> void:
	## 烟雾、照明弹、诱饵、信标过期（原型 updEvoWorld 的道具部分）
	var i := w.smokes.size() - 1
	while i >= 0:
		var s: Dictionary = w.smokes[i]
		s.t += dt
		if s.t >= s.life:
			w.smokes.remove_at(i)
		i -= 1
	var F: Dictionary = w.R.gadgets.flare
	i = w.flares.size() - 1
	while i >= 0:
		var f: Dictionary = w.flares[i]
		f.t += dt
		f.h = maxf(16.0, float(f.h) - dt * float(F.sink))
		if f.t >= f.life:
			w.flares.remove_at(i)
			w.emit({"t": "flare_end", "fid": f.id})
		i -= 1
	var D: Dictionary = w.R.gadgets.decoy
	for d in w.decoys:
		if d.dead:
			continue
		d.save_prev()
		d.t += dt
		d.flash = maxf(0.0, d.flash - dt)
		d.step_t -= dt
		if d.step_t <= 0.0:
			d.step_t = float(D.stepInterval)
			w.noise(d.x, d.y, "step", 0.6, d)
		if d.t >= d.life:
			d.dead = true
			w.emit({"t": "kill", "id": d.id, "kind": "decoy", "x": d.x, "y": d.y, "team": d.team, "killer": -1})
	for h in w.hams:
		if not h.beacon.is_empty() and w.t > float(h.beacon.until):
			h.beacon = {}
			w.emit({"t": "beacon_gone", "id": h.id})


static func smoke_blocks(w: SimWorld, x1: float, y1: float, x2: float, y2: float) -> bool:
	if w.smokes.is_empty():
		return false
	var k := float(w.R.gadgets.smoke.block)
	for s: Dictionary in w.smokes:
		var dx := x2 - x1
		var dy := y2 - y1
		var L2 := maxf(1e-6, dx * dx + dy * dy)
		var t := clampf(((float(s.x) - x1) * dx + (float(s.y) - y1) * dy) / L2, 0.0, 1.0)
		var rr := float(s.r) * k
		if SimUtil.d2(x1 + dx * t, y1 + dy * t, float(s.x), float(s.y)) < rr * rr:
			return true
	return false


static func ai_want(w: SimWorld, h: SimHamster, t: SimEntity) -> bool:
	## 原型 aiWantGadget
	var gid := String(h.gadget.id)
	var d := Vector2(t.x - h.x, t.y - h.y).length() if t != null else 9999.0
	match gid:
		"eshield":
			return h.hurt_t > 0.0 and h.hp < h.max_hp * 0.7
		"medkit":
			return h.hp < h.max_hp * 0.5
		"beacon":
			return h.hp > h.max_hp * 0.8 if h.beacon.is_empty() else h.hp < h.max_hp * 0.3
	if t == null:
		return false
	match gid:
		"mine":
			return d < 220.0
		"sentry":
			return d < 460.0
		"jetpack":
			return d > 260.0 and d < 480.0
		"decoy":
			return d < 520.0
	var gr: Array = w.R.ai.gadgetRange
	return d > float(gr[0]) and d < float(gr[1])
