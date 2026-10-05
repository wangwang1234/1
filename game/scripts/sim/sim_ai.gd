class_name SimAI
extends RefCounted
## AI 仓鼠。对应原型 n2.js 的 aiThink / aiTarget / aimAt 与 n2c.js 的 aiWantGadget。
## AI 遵守同样的视野规则：只在本队可见集合里选目标（贴脸 90 内除外）。


static func _target(w: SimWorld, h: SimHamster) -> SimEntity:
	var A: Dictionary = w.R.ai
	var WT: Dictionary = A.weights
	var RG: Dictionary = A.ranges
	var near := float(w.R.vision.aiNearSee)
	var VV: Dictionary = w.vis[h.team]
	var acc := {"best": null, "bs": 1e9}   # lambda 按值捕获局部变量，用字典承载结果
	var sees := func(e: SimEntity) -> bool: return VV.has(e.id) or Vector2(e.x - h.x, e.y - h.y).length() < near
	var consider := func(e: SimEntity, wgt: float, max_d: float) -> void:
		var d := Vector2(e.x - h.x, e.y - h.y).length() - e.r
		if d > max_d:
			return
		if d * wgt < float(acc.bs):
			acc.bs = d * wgt
			acc.best = e
	for e in w.hams:
		if e.alive and e.team != h.team and sees.call(e):
			consider.call(e, float(WT.ham), float(RG.ham))
	for e in w.minions:
		if not e.dead and e.team != h.team and sees.call(e):
			consider.call(e, float(WT.minion), float(RG.minion))
	for s in w.structs:
		if s.dead or s.team == h.team or (s.kind == "base" and s.shielded):
			continue
		var allies := false
		for m in w.minions:
			if not m.dead and m.team == h.team and Vector2(m.x - s.x, m.y - s.y).length() < s.range_:
				allies = true
				break
		if allies or s.hp < s.max_hp * float(A.structLowHp):
			consider.call(s, float(WT.struct), s.range_ + float(RG.structExtra))
	for c in w.crates:
		if not c.dead:
			consider.call(c, float(WT.crate), float(RG.crate))
	var best: SimEntity = acc.best
	if best != null and not w.map.has_los(h.x, h.y, best.x, best.y):
		return null
	return best


static func _aim_at(w: SimWorld, h: SimHamster, tg: SimEntity) -> void:
	var A: Dictionary = w.R.ai
	var tx := tg.x
	var ty := tg.y
	if tg.vx != 0.0 or tg.vy != 0.0:
		var d := Vector2(tx - h.x, ty - h.y).length()
		var sp := float(h.weapon().get("spd", 900))
		var tt := d / sp
		tx += tg.vx * tt * float(A.leadK)
		ty += tg.vy * tt * float(A.leadK)
	h.inp.aim = atan2(ty - h.y, tx - h.x) + w.rand(-float(A.aimJitter), float(A.aimJitter))


static func _want_gadget(w: SimWorld, h: SimHamster, tg: SimEntity) -> bool:
	if tg == null:
		return false
	var gr: Array = w.R.ai.gadgetRange
	var d := Vector2(tg.x - h.x, tg.y - h.y).length()
	return d > float(gr[0]) and d < float(gr[1])


static func think(w: SimWorld, h: SimHamster, dt: float) -> void:
	var A: Dictionary = w.R.ai
	var ai := h.ai
	var inp := h.inp
	inp.fire = false
	inp.dash = false
	inp.reload = false
	inp.gadget = false
	inp.card = -1
	inp.mx = 0.0
	inp.my = 0.0
	inp.ml = 0.0
	inp.has_aim_point = false
	if not h.alive:
		return
	if h.blind_t > 0.0:
		inp.mx = cos(w.t * 3.0 + h.id)
		inp.my = sin(w.t * 2.3 + h.id)
		inp.ml = 1.0
		return
	if not h.choices.is_empty():
		ai.card_t += dt
		if ai.card_t > float(A.cardDelay):
			ai.card_t = 0.0
			inp.card = SimCards.ai_pick(w, h)
	ai.retarget -= dt
	if ai.retarget <= 0.0:
		ai.retarget = w.rand(float(A.retarget[0]), float(A.retarget[1]))
		ai.target = _target(w, h)
	var tg := ai.target
	if tg != null and (tg.dead or (tg is SimHamster and not (tg as SimHamster).alive)):
		tg = null
	var W := h.weapon()
	var rng_ := minf(float(W.get("range", 560)) * maxf(0.45, float(W.get("eff", 1.0))) * 0.95, float(A.maxRange))
	var low := h.hp < h.max_hp * float(A.lowHp)
	var gx := 0.0
	var gy := 0.0
	var has_goal := false
	var fight := false
	if low:
		ai.state = "retreat"
	if ai.state == "retreat" and h.hp > h.max_hp * float(A.recoverHp):
		ai.state = "push"
	if tg != null and not (ai.state == "retreat" and tg.kind != "ham"):
		fight = true
		var dx := tg.x - h.x
		var dy := tg.y - h.y
		var d := maxf(0.001, sqrt(dx * dx + dy * dy))
		_aim_at(w, h, tg)
		if d < rng_ + tg.r:
			inp.fire = true
		if ai.state == "retreat":
			var b: Vector2 = w.map.base_pos[h.team]
			gx = b.x
			gy = b.y
			has_goal = true
		else:
			var want := rng_ * float(A.buildingRatio) if (tg.kind == "base" or tg.kind == "turret") else rng_ * float(A.keepRatio)
			ai.strafe_t -= dt
			if ai.strafe_t <= 0.0:
				ai.strafe_t = w.rand(float(A.strafe[0]), float(A.strafe[1]))
				ai.strafe = -1.0 if w.rnd() < 0.5 else 1.0
			var ux := dx / d
			var uy := dy / d
			var rad := clampf((d - want) / 120.0, -1.0, 1.0)
			var sw := 0.8 if tg.kind == "ham" else 0.3
			inp.mx = ux * rad - uy * ai.strafe * sw
			inp.my = uy * rad + ux * ai.strafe * sw
		ai.dash_t -= dt
		if tg.kind == "ham" and ai.dash_t <= 0.0 and (h.hurt_t > 0.0 or w.rnd() < float(A.dashChance)):
			inp.dash = true
			ai.dash_t = w.rand(float(A.dashEvery[0]), float(A.dashEvery[1]))
	else:
		if not ai.inv.is_empty():
			ai.inv.t = float(ai.inv.t) - dt
			if float(ai.inv.t) <= 0.0 or Vector2(float(ai.inv.x) - h.x, float(ai.inv.y) - h.y).length() < 80.0:
				ai.inv = {}
		if ai.state == "retreat":
			var b: Vector2 = w.map.base_pos[h.team]
			gx = b.x
			gy = b.y
			has_goal = true
		if ai.state == "push" or ai.state == "jungle":
			ai.state = "push"
			var path := w.lane_path(h.team, ai.lane) if w.map.lanes.has(ai.lane) else w.lane_path(h.team, String(w.map.lanes.keys()[0]))
			var wp := path[mini(ai.wp, path.size() - 1)]
			gx = wp.x
			gy = wp.y
			has_goal = true
			if Vector2(gx - h.x, gy - h.y).length() < float(A.waypointRadius) and ai.wp < path.size() - 1:
				ai.wp += 1
		if not ai.inv.is_empty() and ai.state != "retreat":
			gx = float(ai.inv.x)
			gy = float(ai.inv.y)
			has_goal = true
	if has_goal:
		var F := PackedInt32Array() if w.map.has_los(h.x, h.y, gx, gy) else w.map.field_to(gx, gy)
		var f := w.map.field_dir(F, h.x, h.y, gx, gy)
		inp.mx = f.x
		inp.my = f.y
		if not fight:
			inp.aim = atan2(f.y, f.x) if f.length() > 0.0 else inp.aim
	elif fight and tg != null and not w.map.has_los(h.x, h.y, tg.x, tg.y):
		var f2 := w.map.field_dir(w.map.field_to(tg.x, tg.y), h.x, h.y, tg.x, tg.y)
		inp.mx = f2.x
		inp.my = f2.y
		inp.fire = false
	if float(h.gadget.cd) <= 0.0 and w.rnd() < dt * float(A.gadgetRate) and _want_gadget(w, h, tg):
		inp.gadget = true
	if tg == null and int(W.get("mag", 0)) > 0 and h.reload_t <= 0.0 and h.ammo < SimWeapons.mag_size(h) * 0.5:
		inp.reload = true
	inp.ml = Vector2(inp.mx, inp.my).length()
	if inp.ml > 1.0:
		inp.mx /= inp.ml
		inp.my /= inp.ml
		inp.ml = 1.0
	if Vector2(h.x - ai.last_x, h.y - ai.last_y).length() < 0.6 and inp.ml > 0.5:
		ai.stuck_t += dt
	else:
		ai.stuck_t = 0.0
	ai.last_x = h.x
	ai.last_y = h.y
	if ai.stuck_t > float(A.stuckTime):
		inp.dash = true
		ai.stuck_t = 0.0


static func hear(w: SimWorld, x: float, y: float, loud: float, src: SimEntity) -> void:
	var H: Dictionary = w.R.hearing
	var rr := float(H.aiRadius) * loud
	for h in w.hams:
		if h.ctl != "ai" or not h.alive or h.ai.target != null:
			continue
		if src != null and src.team == h.team:
			continue
		var d := Vector2(h.x - x, h.y - y).length() * (1.0 / float(h.st.get("hearK", 1.0)))
		if d > rr:
			continue
		var j := float(H.investigateJitter)
		if h.ai.inv.is_empty() or d < Vector2(h.x - float(h.ai.inv.x), h.y - float(h.ai.inv.y)).length():
			h.ai.inv = {"x": x + w.rand(-j, j), "y": y + w.rand(-j, j), "t": float(H.investigateTime)}
