class_name SimAI
extends RefCounted
## AI 仓鼠。对应原型 n2.js 的 aiThink / aiTarget / aimAt 与 n2c.js 的 aiWantGadget。
## AI 遵守同样的视野规则：只在本队可见集合里选目标（贴脸 90 内除外）。
## 难度（difficulty.json）决定枪法、反应、点射节奏，以及会不会用这些战术：躲子弹、集火残血、不越塔、回家补血、
## 捡瓜子 / 奶酪、被围就撤、支援队友、丢失目标后去最后看到的位置找、换弹时后撤。


static func prof(w: SimWorld, h: SimHamster) -> Dictionary:
	if h.ai.prof.is_empty():
		h.ai.prof = w.ai_profile(h.team)    # 观战模式下中途接管的仓鼠
	return h.ai.prof


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
	# 加速决战：目标优先是建筑，只和贴近的敌人缠斗（否则两边 AI 在中路对耗，谁也推不动）
	var objective := w.sudden and bool(A.get("pushInSudden", false))
	var focus := float(prof(w, h).get("focus", 0.0))
	for e in w.hams:
		if e.alive and e.team != h.team and sees.call(e):
			# 集火：残血的仓鼠看起来“更近”（focus = 1 时满血 ×1、空血 ×0.55）
			var fk := lerpf(1.0, 0.55 + 0.45 * e.hp / maxf(1.0, e.max_hp), focus)
			consider.call(e, float(WT.ham) * fk, float(A.get("suddenHamRange", RG.ham)) if objective else float(RG.ham))
	for e in w.decoys:
		if not e.dead and e.team != h.team and sees.call(e):
			consider.call(e, float(WT.decoy), float(RG.decoy))
	for e in w.minions:
		if not e.dead and e.team != h.team and sees.call(e):
			consider.call(e, float(WT.minion), float(RG.minion))
	for e in w.mobs:
		if not e.dead and (e.target == h or (h.ai.state == "jungle" and sees.call(e))):
			consider.call(e, float(WT.mob), float(RG.mob))
	# 人数占优（对面有人在等复活）或进入加速决战时，没有小兵掩护也去拆建筑
	var alive_diff := 0
	for e in w.hams:
		if e.alive:
			alive_diff += 1 if e.team == h.team else -1
	var push := alive_diff >= int(A.get("pushAhead", 99)) or (w.sudden and bool(A.get("pushInSudden", false)))
	for s in w.structs:
		if s.dead or s.team == h.team or (s.kind == "base" and s.shielded):
			continue
		var allies := push
		for m in w.minions:
			if not m.dead and m.team == h.team and Vector2(m.x - s.x, m.y - s.y).length() < s.range_:
				allies = true
				break
		if s.kind == "sentry":
			consider.call(s, float(WT.struct), s.range_ + float(RG.structExtra))
		elif objective:
			consider.call(s, float(WT.struct) * float(A.get("suddenStructWeight", 1.0)), 1e9)
		elif allies or s.hp < s.max_hp * float(A.structLowHp):
			consider.call(s, float(WT.struct), s.range_ + float(RG.structExtra))
	for c in w.crates:
		if not c.dead:
			consider.call(c, float(WT.crate), float(RG.crate))
	var best: SimEntity = acc.best
	if best != null and (not w.map.has_los(h.x, h.y, best.x, best.y) or SimGadgets.smoke_blocks(w, h.x, h.y, best.x, best.y)):
		return null
	return best


static func _aim_at(w: SimWorld, h: SimHamster, tg: SimEntity) -> void:
	var P := prof(w, h)
	var tx := tg.x
	var ty := tg.y
	var kind := String(h.weapon().get("kind", "bullet"))
	if (tg.vx != 0.0 or tg.vy != 0.0) and kind != "laser" and kind != "rail" and kind != "melee":
		# 预判提前量按弹速算；激光 / 电磁炮是瞬间命中，不需要提前量（以前按默认弹速 900 算，总瞄在敌人前面）
		var d := Vector2(tx - h.x, ty - h.y).length()
		var sp := float(h.weapon().get("spd", 900))
		var tt := d / sp
		var lk := float(P.get("leadK", w.R.ai.leadK))
		tx += tg.vx * tt * lk
		ty += tg.vy * tt * lk
	# 瞄准误差 = 缓慢摆动（像手在晃）+ 每帧抖动，枪法差的 AI 是“晃着打”，不是白噪声
	var j := float(P.get("aimJitter", w.R.ai.aimJitter))
	var sway := sin(w.t * 2.3 + h.id * 1.7) * 0.6 + sin(w.t * 5.1 + h.id) * 0.25
	h.inp.aim = atan2(ty - h.y, tx - h.x) + j * sway + w.rand(-j, j) * 0.4


static func _want_gadget(w: SimWorld, h: SimHamster, tg: SimEntity) -> bool:
	return SimGadgets.ai_want(w, h, tg)


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
	var P := prof(w, h)
	if not h.choices.is_empty():
		ai.card_t += dt
		if ai.card_t > float(P.get("cardDelay", A.cardDelay)):
			ai.card_t = 0.0
			inp.card = SimCards.ai_pick(w, h)
	ai.retarget -= dt
	if ai.retarget <= 0.0:
		ai.retarget = w.rand(float(A.retarget[0]), float(A.retarget[1]))
		ai.target = _target(w, h)
	var tg := ai.target
	if tg != null and (tg.dead or (tg is SimHamster and not (tg as SimHamster).alive)):
		tg = null
		ai.seen = {}
	# 反应时间：换到一个新目标后要过一会儿才开火（对小兵 / 建筑反应快一些）
	if tg != null and tg.id != ai.last_tid:
		ai.last_tid = tg.id
		var rc: Array = P.get("react", [0.0, 0.0])
		ai.react_t = w.rand(float(rc[0]), float(rc[1])) * (1.0 if tg is SimHamster else 0.4)
	ai.react_t -= dt
	# 记忆：丢失仓鼠目标（躲到墙后 / 走出视野）后去最后看到的位置找
	if tg is SimHamster:
		ai.seen = {"x": tg.x, "y": tg.y}
	elif tg == null and not ai.seen.is_empty():
		if float(P.get("memory", 0.0)) > 0.0:
			ai.inv = {"x": float(ai.seen.x), "y": float(ai.seen.y), "t": float(P.memory)}
		ai.seen = {}
	var W := h.weapon()
	var wkind := String(W.get("kind", "bullet"))
	var rng_ := minf(float(W.get("range", 560)) * maxf(0.45, float(W.get("eff", 1.0))) * 0.95, float(A.maxRange)) * float(P.get("engageK", 1.0))
	if wkind == "melee":
		rng_ = float(W.get("reach", 88)) * float(A.meleeRangeK)
		var wr := float(SimWeapons.params(h).waveRange)
		if wr > 0.0:
			rng_ = maxf(rng_, wr * 0.8)
	elif wkind == "flame":
		rng_ = float(W.get("range", 300)) * float(A.flameRangeK)
	var dive_ok := _dive_ok(w, h)
	# 撤退：血少；不打架时血量低于 recallHp 回家（鼠窝回血很快）；被围且血量不高
	# 加速决战时拼命推：撤退线降到 suddenLowHp，不再主动回家补血、不因被围而撤
	var hpk := h.hp / maxf(1.0, h.max_hp)
	var allin := w.sudden and bool(A.get("pushInSudden", false))
	if hpk < float(A.get("suddenLowHp", A.lowHp) if allin else A.lowHp):
		ai.state = "retreat"
	elif allin:
		pass
	elif tg == null and hpk < float(P.get("recallHp", 0.0)):
		ai.state = "retreat"
	elif hpk < float(P.get("outnumberHp", 0.0)) and _outnumbered(w, h):
		ai.state = "retreat"
	if ai.state == "retreat" and hpk > float(A.recoverHp):
		ai.state = "push"
	var gx := 0.0
	var gy := 0.0
	var has_goal := false
	var fight := false
	if tg != null and not (ai.state == "retreat" and tg.kind != "ham"):
		fight = true
		var dx := tg.x - h.x
		var dy := tg.y - h.y
		var d := maxf(0.001, sqrt(dx * dx + dy * dy))
		_aim_at(w, h, tg)
		if d < rng_ + tg.r and ai.react_t <= 0.0 and _burst_ok(ai, P, tg, dt):
			inp.fire = true
		if ai.state == "retreat":
			var b: Vector2 = w.map.base_pos[h.team]
			gx = b.x
			gy = b.y
			has_goal = true
		else:
			var want := rng_ * float(A.buildingRatio) if (tg.kind == "base" or tg.kind == "turret") else rng_ * float(A.keepRatio)
			if wkind == "melee":
				want = tg.r + float(A.meleeKeep)
			elif h.reload_t > 0.0 and tg is SimHamster:
				want += float(P.get("reloadBack", 0.0))     # 换弹时往后退
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
		if tg.kind == "ham" and ai.dash_t <= 0.0:
			var dk := float(P.get("dashK", 1.0))
			if h.hurt_t > 0.0:
				if w.rnd() < dk:
					inp.dash = true
				ai.dash_t = w.rand(float(A.dashEvery[0]), float(A.dashEvery[1]))
			elif w.rnd() < float(A.dashChance) * dk:
				inp.dash = true
				ai.dash_t = w.rand(float(A.dashEvery[0]), float(A.dashEvery[1]))
	else:
		if not ai.inv.is_empty():
			ai.inv.t = float(ai.inv.t) - dt
			if float(ai.inv.t) <= 0.0 or Vector2(float(ai.inv.x) - h.x, float(ai.inv.y) - h.y).length() < 80.0:
				ai.inv = {}
		ai.jungle_t -= dt
		if ai.state == "push" and ai.jungle_t <= 0.0 and h.lvl < int(A.jungle.maxLevel):
			var ev: Array = A.jungle.every
			ai.jungle_t = w.rand(float(ev[0]), float(ev[1]))
			var mid := (w.map.min_x + w.map.max_x) * 0.5
			var own: Array = w.camps.filter(func(c): return int(c.alive) > 0 and ((h.team == "blue" and float(c.x) < mid) or (h.team == "red" and float(c.x) > mid)))
			if not own.is_empty():
				ai.camp = own[int(w.rnd() * own.size()) % own.size()]
				ai.state = "jungle"
		if ai.state == "jungle":
			if ai.camp.is_empty() or int(ai.camp.alive) <= 0:
				ai.state = "push"
				ai.camp = {}
			else:
				gx = float(ai.camp.x)
				gy = float(ai.camp.y)
				has_goal = true
		if ai.state == "retreat":
			var b: Vector2 = w.map.base_pos[h.team]
			gx = b.x
			gy = b.y
			has_goal = true
		if ai.state == "push":
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
		# 战术目标：捡瓜子 / 吃奶酪、支援交火中的队友
		_tactics(w, h, P, dt)
		if not ai.pick.is_empty() and (ai.state != "retreat" or String(ai.pick.why) == "cheese"):
			gx = float(ai.pick.x)
			gy = float(ai.pick.y)
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
	# 不越塔：没有己方小兵在敌方炮台 / 鼠窝射程里扛着时，不走进去（目标就是这座建筑、或允许强推时除外）
	if bool(P.get("towerSafe", false)) and not dive_ok:
		var away := _tower_avoid(w, h, tg)
		inp.mx += away.x
		inp.my += away.y
	# 躲子弹
	_dodge(w, h, P, dt)
	if ai.dodge_left > 0.0:
		inp.mx += ai.dodge_x * 1.3
		inp.my += ai.dodge_y * 1.3
	if float(h.gadget.cd) <= 0.0 and w.rnd() < dt * float(A.gadgetRate) * float(P.get("gadgetK", 1.0)) and _want_gadget(w, h, tg):
		inp.gadget = true
	# 左轮神枪手：对建筑 / 箱子这类不能标记的目标改成点射（按住不放永远不会开火）
	if inp.fire and tg != null and SimWeapons.special(h, "deadeye") != null and not (tg is SimHamster or tg is SimMinion or tg is SimMob or tg is SimDecoy):
		inp.fire = h.mark_hold <= 0.0
	elif inp.fire and SimWeapons.special(h, "deadeye") != null:
		# 神枪手：身前只有一个敌人时直接点射；两个以上才按住标记，标到 2 个就松手连射（一直按着要 1.6 秒才自动放）
		var DS: Dictionary = SimWeapons.params(h).special
		if SimWeapons.foes_sorted(w, h, float(DS.get("markR", 700)), float(DS.get("markCone", 0.62))).size() < 2:
			inp.fire = h.mark_hold <= 0.0
		elif h.marks.size() >= mini(2, h.ammo) or (not h.marks.is_empty() and h.mark_hold > 0.6):
			inp.fire = false
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


static func _burst_ok(ai: SimHamster.AiState, P: Dictionary, tg: SimEntity, dt: float) -> bool:
	## 点射节奏（低难度）：对仓鼠连射 burst[0] 秒、停 burst[1] 秒；打小兵 / 建筑不停
	var B: Variant = P.get("burst")
	if not (B is Array) or not (tg is SimHamster):
		return true
	ai.burst_t -= dt
	if ai.burst_t <= -float(B[1]):
		ai.burst_t = float(B[0])
	return ai.burst_t > 0.0


static func _dive_ok(w: SimWorld, h: SimHamster) -> bool:
	## 允许强推建筑的情况（和 _target 一致）：人数占优，或加速决战
	var A: Dictionary = w.R.ai
	if w.sudden and bool(A.get("pushInSudden", false)):
		return true
	var diff := 0
	for e in w.hams:
		if e.alive:
			diff += 1 if e.team == h.team else -1
	return diff >= int(A.get("pushAhead", 99))


static func _outnumbered(w: SimWorld, h: SimHamster) -> bool:
	## 看得见的敌方仓鼠比身边（含自己）的队友多 2 只以上
	var R := float(w.R.ai.get("outnumberR", 560))
	var VV: Dictionary = w.vis[h.team]
	var foes := 0
	var mates := 0
	for e in w.hams:
		if not e.alive or Vector2(e.x - h.x, e.y - h.y).length() > R:
			continue
		if e.team == h.team:
			mates += 1
		elif VV.has(e.id):
			foes += 1
	return foes >= mates + 2


static func _tower_avoid(w: SimWorld, h: SimHamster, tg: SimEntity) -> Vector2:
	var out := Vector2.ZERO
	var margin := float(w.R.ai.get("towerMargin", 40))
	for s in w.structs:
		if s.dead or s.team == h.team or s == tg or (s.kind != "turret" and s.kind != "base"):
			continue
		var dx := h.x - s.x
		var dy := h.y - s.y
		var d := sqrt(dx * dx + dy * dy)
		var edge := s.range_ + h.r + margin
		if d >= edge or d < 0.001:
			continue
		var covered := false
		for m in w.minions:
			if not m.dead and m.team == h.team and Vector2(m.x - s.x, m.y - s.y).length() < s.range_:
				covered = true
				break
		if covered:
			continue
		var k := clampf((edge - d) / 80.0, 0.0, 1.6)
		out += Vector2(dx / d, dy / d) * k
	return out


static func _dodge(w: SimWorld, h: SimHamster, P: Dictionary, dt: float) -> void:
	## 每 0.15 秒看一眼有没有子弹朝自己飞来；按难度的概率往弹道侧面闪（有时顺便翻滚）
	var ai := h.ai
	ai.dodge_left = maxf(0.0, ai.dodge_left - dt)
	ai.dodge_t -= dt
	var pr := float(P.get("dodge", 0.0))
	if ai.dodge_t > 0.0 or pr <= 0.0:
		return
	var D: Dictionary = w.R.ai.dodge
	ai.dodge_t = float(D.every)
	if ai.dodge_left > 0.0 or w.rnd() >= pr:
		return
	var look := float(D.look)
	for b in w.bullets:
		if b.dead or b.team == h.team:
			continue
		var rx := h.x - b.x
		var ry := h.y - b.y
		if absf(rx) > look or absf(ry) > look:
			continue
		var sp := sqrt(b.vx * b.vx + b.vy * b.vy)
		if sp < 1.0:
			continue
		var ux := b.vx / sp
		var uy := b.vy / sp
		var along := rx * ux + ry * uy
		if along <= 0.0 or along > look:
			continue
		var cross := rx * uy - ry * ux       # 在弹道哪一侧
		if absf(cross) > h.r + b.r + float(D.pad):
			continue
		var side := 1.0 if cross >= 0.0 else -1.0
		ai.dodge_x = -uy * side
		ai.dodge_y = ux * side
		ai.dodge_left = float(D.time)
		if h.dash_cd <= 0.0 and w.rnd() < float(P.get("dodgeDash", 0.0)):
			h.inp.dash = true
		return


static func _tactics(w: SimWorld, h: SimHamster, P: Dictionary, dt: float) -> void:
	## 不打架时每 0.5 秒想一次：残血去吃附近的奶酪 → 去支援交火的队友 → 捡附近的瓜子
	var ai := h.ai
	if not ai.pick.is_empty():
		ai.pick.t = float(ai.pick.t) - dt
		var reached := Vector2(float(ai.pick.x) - h.x, float(ai.pick.y) - h.y).length() < 40.0
		var gone: bool = ai.pick.has("item") and (ai.pick.item as SimItem).dead
		if reached or gone or float(ai.pick.t) <= 0.0:
			ai.pick = {}
	ai.goal_t -= dt
	if ai.goal_t > 0.0:
		return
	ai.goal_t = float(w.R.ai.get("tacticsEvery", 0.5))
	var pr := float(P.get("pickup", 0.0))
	var hpk := h.hp / maxf(1.0, h.max_hp)
	if pr > 0.0 and hpk < 0.75:
		var c := _nearest_item(w, h, "cheese", pr * 1.4)
		if c != null:
			ai.pick = {"x": c.x, "y": c.y, "why": "cheese", "item": c, "t": 4.0}
			return
	if ai.state == "retreat":
		return
	var hr := float(P.get("help", 0.0))
	if hr > 0.0:
		var best: SimHamster = null
		var bd := hr
		for o in w.hams:
			if o == h or not o.alive or o.team != h.team:
				continue
			var busy := o.ai != null and o.ai.target is SimHamster
			if not busy and o.ctl == "player":
				busy = o.hurt_t > 0.0 or w.t - o.last_shot_t < 0.6
			if not busy:
				continue
			var d := Vector2(o.x - h.x, o.y - h.y).length()
			if d < bd:
				bd = d
				best = o
		if best != null and bd > 160.0:
			ai.pick = {"x": best.x, "y": best.y, "why": "help", "t": 2.5}
			return
	if pr > 0.0 and ai.pick.is_empty():
		var g := _nearest_item(w, h, "gem", pr)
		if g != null:
			ai.pick = {"x": g.x, "y": g.y, "why": "gem", "item": g, "t": 3.0}


static func _nearest_item(w: SimWorld, h: SimHamster, type: String, rr: float) -> SimItem:
	var best: SimItem = null
	var bd := rr * rr
	for it in w.items:
		if it.dead or it.type != type:
			continue
		var d := SimUtil.d2(it.x, it.y, h.x, h.y)
		if d < bd and w.map.has_los(h.x, h.y, it.x, it.y):
			bd = d
			best = it
	return best


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
