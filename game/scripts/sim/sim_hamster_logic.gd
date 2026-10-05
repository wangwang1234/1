class_name SimHamsterLogic
extends RefCounted
## 仓鼠每帧逻辑。对应原型 updHam / startDash / startReload / useGadget / calcStats / giveXP / respawn。


static func calc_stats(h: SimHamster) -> void:
	var a := h.ab
	var T := h.tal
	var A: Dictionary = Data.rules().abilities
	var HR: Dictionary = Data.rules().hamster
	var U: Dictionary = Data.units().hamster
	var giant := T.has("giant")
	var lv := func(k: String) -> float: return float(a.get(k, 0))
	var st := {}
	st.speed = float(U.speed) * (1.0 + float(A.speed.speed) * lv.call("speed")) * (0.92 if giant else 1.0)
	st.maxHp = (float(U.maxHp) * (1.0 + float(A.strong.maxHp) * lv.call("strong")) + (h.lvl - 1) * float(U.hpPerLevel)) * (1.6 if giant else 1.0)
	st.regen = float(A.regen.regen) * lv.call("regen")
	st.vamp = float(A.vamp.vamp) * lv.call("vamp") + (0.15 if T.has("vampire") else 0.0)
	st.crit = float(A.crit.crit) * lv.call("crit")
	st.critDmg = float(Data.rule("combat.critDmg", 2))
	st.multi = 1 if T.has("overdrive") else 0
	st.dashCd = float(U.dashCd) * (1.0 + float(A.dash.dashCd) * lv.call("dash")) * (0.5 if T.has("phantom") else 1.0)
	st.dashDmg = float(A.dash.dashDmg) * lv.call("dash")
	st.shield = 2 if T.has("aegis") else 0
	st.shieldCd = 3.0
	st.magnet = float(U.magnet) * (1.0 + float(A.magnet.magnet) * lv.call("magnet"))
	st.chain = float(A.chain.chain) * lv.call("chain") + (0.3 if T.has("storm") else 0.0)
	st.frost = lv.call("frost")
	st.dmg = (1.0 + float(A.rage.dmg) * lv.call("rage")) * (1.0 + float(HR.dmgPerLevel) * (h.lvl - 1)) * (float(Data.progression().bossReward.crownDamage) if h.crown_t > 0.0 else 1.0) * (1.15 if giant else 1.0)
	st.rate = (1.0 + float(A.rate.rate) * lv.call("rate")) * (1.2 if T.has("overdrive") else 1.0)
	st.rl = 1.0 / 1.5 if T.has("bottomless") else 1.0
	st.armor = float(A.armor.armor) * lv.call("armor")
	st.scav = float(A.scav.scav) * lv.call("scav")
	st.xpK = 1.0 + float(A.scholar.xpK) * lv.call("scholar")
	st.gcd = 1.0 + float(A.gcd.gcd) * lv.call("gcd")
	st.aura = float(A.aura.aura) * lv.call("aura")
	st.lightK = 1.0 + float(A.torch.lightK) * lv.call("torch")
	st.wideK = lv.call("wide")
	st.hearK = 1.0 + float(A.ears.hearK) * lv.call("ears")
	st.nvg = (float(A.nvg.nvgBase) + float(A.nvg.nvgPer) * lv.call("nvg")) if lv.call("nvg") > 0.0 else 0.0
	st.recon = float(A.recon.recon) * lv.call("recon")
	st.banner = float(A.banner.banner) * lv.call("banner")
	st.scale = 1.0 + float(A.strong.scale) * lv.call("strong")
	h.st = st
	h.r = (float(HR.giantRadius) if giant else float(U.radius)) * float(st.scale)
	var f := h.hp / h.max_hp if h.max_hp > 0.0 else 1.0
	h.max_hp = float(st.maxHp)
	h.hp = minf(h.max_hp, maxf(1.0, f * h.max_hp))


static func place_at_base(w: SimWorld, h: SimHamster) -> void:
	var HR: Dictionary = w.R.hamster
	var b: Vector2 = w.map.base_pos[h.team]
	var s := 1.0 if h.team == "blue" else -1.0
	var j: Array = HR.spawnJitter
	h.x = b.x + s * float(HR.spawnOffset) + w.rand(-float(j[0]), float(j[0]))
	h.y = b.y + w.rand(-float(j[1]), float(j[1]))
	h.vx = 0.0
	h.vy = 0.0
	w.map.resolve_circle(h, h.r)
	h.px = h.x
	h.py = h.y


static func respawn(w: SimWorld, h: SimHamster) -> void:
	h.alive = true
	calc_stats(h)
	h.hp = h.max_hp
	place_at_base(w, h)
	h.iframes = float(w.R.hamster.spawnIframes)
	h.roll_t = 0.0
	h.slow_t = 0.0
	h.burn_t = 0.0
	h.shield = int(h.st.shield)
	h.ammo = SimWeapons.mag_size(h)
	h.reload_t = 0.0
	h.bloom = 0.0
	h.blind_t = 0.0
	h.undy_used = false
	h.air = {}
	h.z = 0.0
	h.invis_t = 0.0
	h.stun_t = 0.0
	h.ramp = 0.0
	h.burst_n = 0
	if h.ai != null:
		h.ai.wp = 1
		h.ai.state = "push"
		h.ai.target = null
		h.ai.inv = {}
	w.emit({"t": "respawn", "id": h.id, "x": h.x, "y": h.y, "team": h.team})
	w.toast(h, "复活！", "#8de0a6", 1.2)


static func give_xp(w: SimWorld, h: SimHamster, n: float) -> void:
	var maxl := int(Data.progression().get("maxLevel", 30))
	if h == null or h.lvl >= maxl:
		return
	h.xp += n * float(h.st.get("xpK", 1.0))
	var talent_levels: Array = Data.progression().get("talentLevels", [10, 20, 30])
	var talents_on := bool(Data.rule("scope.talents", true))
	while h.xp >= h.xp_next and h.lvl < maxl:
		h.xp -= h.xp_next
		h.lvl += 1
		h.xp_next = Data.xp_need(h.lvl)
		h.pending += 1
		calc_stats(h)
		h.hp = minf(h.max_hp, h.hp + h.max_hp * float(Data.progression().get("levelUpHeal", 0.2)))
		var is_talent := talents_on and talent_levels.has(h.lvl)
		if is_talent:
			h.talent_pend += 1
		w.emit({"t": "levelup", "id": h.id, "lvl": h.lvl, "talent": is_talent})
		w.emit({"t": "pop", "x": h.x, "y": h.y, "h": h.r * 3.2, "text": "+HP", "color": "#8de0a6", "size": 15})
		if is_talent:
			w.toast(h, "Lv%d！解锁一个强大天赋" % h.lvl, "#ff9ff0", 2.2)
		else:
			w.toast(h, "咕咚！升到 Lv%d，选一个奖励" % h.lvl, "#ffd166", 2.2)
	if h.lvl >= maxl:
		h.xp = 0.0
	if h.pending > 0 and h.choices.is_empty():
		SimCards.roll(w, h)


static func start_dash(w: SimWorld, h: SimHamster) -> void:
	var HR: Dictionary = w.R.hamster
	var dx := h.inp.mx
	var dy := h.inp.my
	if Vector2(dx, dy).length() < 0.2:
		dx = cos(h.aim)
		dy = sin(h.aim)
	var l := maxf(0.0001, Vector2(dx, dy).length())
	h.rdx = dx / l
	h.rdy = dy / l
	h.roll_t = float(HR.rollTime)
	h.dash_cd = float(h.st.dashCd)
	h.iframes = maxf(h.iframes, float(HR.rollIframes))
	h.dash_hit = {}
	if h.tal.has("phantom"):
		h.invis_t = 1.5
	w.emit({"t": "dash", "id": h.id, "x": h.x, "y": h.y, "dx": h.rdx, "dy": h.rdy})


static func start_reload(w: SimWorld, h: SimHamster) -> void:
	var W := h.weapon()
	if int(W.get("mag", 0)) <= 0 or h.reload_t > 0.0:
		return
	w.noise(h.x, h.y, "step", 0.4, h)
	h.reload_dur = SimWeapons.reload_time(h)
	h.reload_t = h.reload_dur
	w.emit({"t": "reload", "id": h.id, "dur": h.reload_dur, "weapon": h.weapon_id})


static func gadget_target(w: SimWorld, h: SimHamster) -> Vector2:
	var G: Dictionary = w.R.gadgets
	var tx: float
	var ty: float
	if h.inp.has_aim_point:
		tx = h.inp.aim_x
		ty = h.inp.aim_y
	else:
		var tg: SimEntity = h.ai.target if h.ai != null else null
		if tg != null and Vector2(tg.x - h.x, tg.y - h.y).length() < 560.0:
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


static func use_gadget(w: SimWorld, h: SimHamster) -> void:
	var id := String(h.gadget.id)
	var L := int(h.gadget.lvl)
	var G0: Dictionary = Data.gadgets().get(id, {"cd": 7})
	h.gadget.cd = float(G0.cd) * (1.0 + float(w.R.gadgets.cdPerLevel) * (L - 1)) * float(h.st.gcd)
	var p := gadget_target(w, h)
	h.spit_t = 0.2
	match id:
		_:
			var F: Dictionary = w.R.gadgets.frag
			w.throw_lob(h, "frag", p.x, p.y, {"sp": float(F.speed), "fuse": float(F.fuse), "aoe": float(F.aoe), "dmg": float(F.dmg) * (1.0 + float(F.dmgPerLevel) * (L - 1)), "kb": float(F.kb)})


static func update(w: SimWorld, h: SimHamster, dt: float) -> void:
	var HR: Dictionary = w.R.hamster
	if not h.alive:
		h.respawn_t -= dt
		if h.respawn_t <= 0.0 and not w.over:
			respawn(w, h)
		return
	var st := h.st
	var inp := h.inp
	h.fire_cd -= dt
	h.dash_cd -= dt
	h.iframes -= dt
	h.hurt_t = maxf(0.0, h.hurt_t - dt)
	h.flash = maxf(0.0, h.flash - dt)
	h.heat = maxf(0.0, h.heat - dt * float(HR.heatDecay))
	h.munch_t = maxf(0.0, h.munch_t - dt)
	h.spit_t = maxf(0.0, h.spit_t - dt)
	h.slow_t = maxf(0.0, h.slow_t - dt)
	h.gadget.cd = maxf(0.0, float(h.gadget.cd) - dt)
	h.blind_t = maxf(0.0, h.blind_t - dt)
	if h.crown_t > 0.0:
		h.crown_t -= dt
		if h.crown_t <= 0.0:
			calc_stats(h)
	w.burn_tick(h, dt)
	if not h.alive:
		return
	h.pad_cd = maxf(0.0, h.pad_cd - dt)
	h.invis_t = maxf(0.0, h.invis_t - dt)
	h.reveal_t = maxf(0.0, h.reveal_t - dt)
	h.puff = 1.0 if h.lvl >= 30 else clampf(h.xp / float(h.xp_next), 0.0, 1.0)
	# 治疗光环
	if float(st.aura) > 0.0:
		var ar := float(Data.rule("abilities.aura.auraRadius", 220))
		for o in w.hams:
			if o.alive and o.team == h.team and o.hp < o.max_hp and Vector2(o.x - h.x, o.y - h.y).length() < ar:
				o.hp = minf(o.max_hp, o.hp + float(st.aura) * dt)
	# 眩晕
	if h.stun_t > 0.0:
		h.stun_t -= dt
		inp.fire = false
		inp.dash = false
		h.vx *= 0.85
		h.vy *= 0.85
		h.x += h.vx * dt
		h.y += h.vy * dt
		w.map.resolve_circle(h, h.r)
		return
	SimWeapons.evo_tick(w, h, dt)
	# 弹射飞行
	if not h.air.is_empty():
		var A := h.air
		A.t += dt
		var k := minf(1.0, float(A.t) / float(A.dur))
		h.x = lerpf(float(A.x0), float(A.x1), k)
		h.y = lerpf(float(A.y0), float(A.y1), k)
		h.z = sin(k * PI) * float(A.hgt)
		h.moving = true
		h.walk += dt * 8.0
		h.aim = inp.aim
		var Wa := h.weapon()
		if inp.fire and h.fire_cd <= 0.0 and h.reload_t <= 0.0 and Wa.get("kind", "") == "bullet" and (int(Wa.get("mag", 0)) == 0 or h.ammo > 0):
			SimWeapons.fire(w, h)
		if k >= 1.0:
			w.land(h)
		return
	# 回血：再生 + 鼠窝附近
	var ob: Vector2 = w.map.base_pos[h.team]
	var heal := float(st.regen)
	if Vector2(h.x - ob.x, h.y - ob.y).length() < float(HR.baseHealRadius):
		heal += float(HR.baseHeal)
	if heal > 0.0 and h.hp < h.max_hp:
		h.hp = minf(h.max_hp, h.hp + heal * dt)
	if int(st.shield) > 0 and h.shield < int(st.shield):
		h.shield_t -= dt
		if h.shield_t <= 0.0:
			h.shield += 1
			h.shield_t = float(st.shieldCd)
	# 选卡
	if inp.card >= 0:
		if not h.choices.is_empty():
			SimCards.apply(w, h, inp.card)
		inp.card = -1
	h.aim = inp.aim
	if inp.dash:
		if h.dash_cd <= 0.0 and h.roll_t <= 0.0:
			start_dash(w, h)
		inp.dash = false
	var spd := float(st.speed) * (float(HR.slowMul) if h.slow_t > 0.0 else 1.0) * SimWeapons.move_mul(h)
	if h.roll_t > 0.0:
		h.roll_t -= dt
		var k := maxf(0.0, h.roll_t / float(HR.rollTime))
		var rs := float(HR.rollSpeed) * (0.5 + 0.5 * k)
		h.vx = h.rdx * rs
		h.vy = h.rdy * rs
		if float(st.dashDmg) > 0.0:
			for e: SimEntity in w.hash_range(h.x, h.y, h.r + 30.0):
				if h.dash_hit.has(e.id) or not w.can_hit(h.team, e) or e.kind == "base" or e.kind == "turret":
					continue
				if Vector2(e.x - h.x, e.y - h.y).length() < h.r + e.r + 4.0:
					h.dash_hit[e.id] = true
					w.deal_dmg(e, float(st.dashDmg) * float(st.dmg), {"team": h.team, "owner": h, "x": h.x, "y": h.y})
					w.knock(e, e.x - h.x, e.y - h.y, 220.0)
	else:
		var acc := float(HR.accelInput) if inp.ml > 0.05 else float(HR.accelIdle)
		h.vx = SimUtil.damp(h.vx, inp.mx * spd, acc, dt)
		h.vy = SimUtil.damp(h.vy, inp.my * spd, acc, dt)
	var ox := h.x
	var oy := h.y
	h.x += h.vx * dt
	h.y += h.vy * dt
	w.map.resolve_circle(h, h.r)
	var moved := Vector2(h.x - ox, h.y - oy).length()
	h.moving = moved > 0.35
	h.walk += moved * 0.17
	# 脚步声（看不见的敌人在附近移动时能听到）
	if h.moving and h.roll_t <= 0.0:
		h.step_t -= dt
		if h.step_t <= 0.0:
			h.step_t = float(w.R.hearing.stepInterval)
			w.noise(h.x, h.y, "step", 0.5, h)
	var W := h.weapon()
	var mag := int(W.get("mag", 0))
	if h.reload_t > 0.0:
		h.reload_t -= dt
		if h.reload_t <= 0.0:
			h.reload_t = 0.0
			h.ammo = SimWeapons.mag_size(h)
			w.emit({"t": "reload_done", "id": h.id})
	if inp.reload:
		inp.reload = false
		if mag > 0 and h.ammo < SimWeapons.mag_size(h):
			start_reload(w, h)
	if mag > 0 and h.ammo <= 0 and h.reload_t <= 0.0:
		start_reload(w, h)
	if inp.gadget:
		inp.gadget = false
		if float(h.gadget.cd) <= 0.0 and h.roll_t <= 0.0:
			use_gadget(w, h)
	var can_shoot := h.roll_t <= 0.0 and h.reload_t <= 0.0 and (mag == 0 or h.ammo > 0)
	SimWeapons.try_fire(w, h, can_shoot)
	h.bloom = maxf(0.0, h.bloom - dt * (float(HR.bloomDecayFiring) if inp.fire else float(HR.bloomDecayIdle)))
