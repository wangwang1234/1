class_name SimGadgets
extends RefCounted
## 道具：Q / E 双槽（2026-10-12）。Q = 战术道具（投掷 / 部署，作用于战场），E = 强化道具（即时生效，作用于自己）。
## 每个槽 {id, cd, ch}：ch 是剩余充能，没满时 cd 倒计时，到 0 回一格。冷却 = gadgets.json 的 cd × 通用升级（冷却缩短）× 强化 gcd；
## 上限 = charges + 通用升级（携带上限）。h.gup 记通用升级张数，换道具时保留。
## 效果按 gadgets.json 每个道具的 fx.type 分派：deploy 部署物（SimStructure kind = dep，功能件见 _fxDoc）、decoy 全息分身、summon 呼叫小兵、
## buff 增益、shield 护盾、teleport 读条传送、vision 夜视、pulse 声呐；旧道具（frag … beacon）沿用原来的代码，参数在 rules.json 的 gadgets。
## AI：每个道具的 ai.when 条件（见 gadgets.json 的 _aiDoc），两个槽同时想用时按 ai.cat 的优先级（保命 > 交战 > 情报）。
## 对应原型 n2c.js 的 useGadget / lobBoom / updEvoWorld（烟雾、照明、诱饵）与 n2.js 的 placeMine / updMines / placeSentry / flashBang。

const SLOTS := ["q", "e"]
const LEGACY_LVL := 1     # 旧道具的等级参数（道具等级已取消，按 1 级算）


static func lvl_k(L: int, per: float) -> float:
	return 1.0 + per * (L - 1)


static func def(id: String) -> Dictionary:
	return Data.gadget(id)


static func fx_of(id: String) -> Dictionary:
	return def(id).get("fx", {"type": id})


static func new_slot(id: String, h: SimHamster, cd: float = 0.0) -> Dictionary:
	## 一个装满的槽（换上新道具时）；cd > 0 时从空槽开始充能（开局）
	var mx := max_charges(h, id)
	return {"id": id, "cd": cd, "ch": 0 if cd > 0.0 else mx}


static func max_charges(h: SimHamster, id: String) -> int:
	var U: Dictionary = Data.gadgets().upgrades
	return maxi(1, int(def(id).get("charges", 1)) + int(h.gup.get("gcap", 0)) * int(U.gcap.per))


static func cd_mul(h: SimHamster) -> float:
	var U: Dictionary = Data.gadgets().upgrades
	return maxf(0.2, 1.0 + float(U.gcdx.per) * int(h.gup.get("gcdx", 0))) * float(h.st.get("gcd", 1.0))


static func cd_full(h: SimHamster, id: String) -> float:
	return float(def(id).get("cd", 7)) * cd_mul(h)


static func equip(w: SimWorld, h: SimHamster, id: String) -> void:
	## 换上新道具：只替换它所属的槽，通用升级保留
	var slot := String(def(id).get("slot", "q"))
	var old := String(h.gad.get(slot, {}).get("id", ""))
	if old == "beacon":
		h.beacon = {}
	h.gad[slot] = new_slot(id, h)
	w.emit({"t": "gadget_equip", "id": h.id, "slot": slot, "gadget": id})


static func force_use(w: SimWorld, h: SimHamster, id: String) -> void:
	## 截图 / 冒烟测试用：把道具装进它所属的槽（充满）并立刻使用
	var slot := String(def(id).get("slot", "q"))
	h.gad[slot] = new_slot(id, h)
	use(w, h, slot)


static func add_upgrade(h: SimHamster, uid: String) -> void:
	var U: Dictionary = Data.gadgets().upgrades
	h.gup[uid] = mini(int(U[uid].max), int(h.gup.get(uid, 0)) + 1)
	if uid == "gcap":
		for slot in SLOTS:
			var S: Dictionary = h.gad[slot]
			S.ch = mini(max_charges(h, String(S.id)), int(S.ch) + int(U.gcap.per))


static func tick_charges(h: SimHamster, dt: float) -> void:
	for slot in SLOTS:
		var S: Dictionary = h.gad[slot]
		var mx := max_charges(h, String(S.id))
		if int(S.ch) >= mx:
			S.ch = mx
			S.cd = 0.0
			continue
		S.cd = float(S.cd) - dt
		if float(S.cd) <= 0.0:
			S.ch = int(S.ch) + 1
			S.cd = cd_full(h, String(S.id)) if int(S.ch) < mx else 0.0


static func ready(w: SimWorld, h: SimHamster, slot: String) -> bool:
	var S: Dictionary = h.gad[slot]
	if String(S.id) == "beacon" and not h.beacon.is_empty():
		return w.t >= float(h.beacon.get("arm", 0.0))
	return int(S.ch) > 0


static func target(w: SimWorld, h: SimHamster) -> Vector2:
	var G: Dictionary = w.R.gadgets
	var tx: float
	var ty: float
	if h.inp.has_aim_point:
		tx = h.inp.aim_x
		ty = h.inp.aim_y
	else:
		# 手柄 / 方向键 / AI 没有落点：扔向当前目标（太远就沿瞄准方向扔一段）
		var tg: SimEntity = h.ai.target if h.ai != null else SimWeapons.auto_aim(w, h, float(G.autoTarget))
		if tg != null and not tg.dead and Vector2(tg.x - h.x, tg.y - h.y).length() < float(G.autoTargetMax):
			tx = tg.x
			ty = tg.y
		else:
			tx = h.x + cos(h.aim) * float(G.noTargetDist)
			ty = h.y + sin(h.aim) * float(G.noTargetDist)
	var dx := tx - h.x
	var dy := ty - h.y
	var d := maxf(0.001, Vector2(dx, dy).length())
	var dd := clampf(d, float(G.throwMin), float(G.throwMax))
	return Vector2(h.x + dx / d * dd, h.y + dy / d * dd)


static func use(w: SimWorld, h: SimHamster, slot: String = "q") -> void:
	## 按下 Q / E：有充能就用掉一格（传送信标的“传回”不耗充能）
	var S: Dictionary = h.gad[slot]
	var id := String(S.id)
	if not ready(w, h, slot):
		return
	var back := id == "beacon" and not h.beacon.is_empty()
	if not back:
		S.ch = int(S.ch) - 1
		if float(S.cd) <= 0.0:
			S.cd = cd_full(h, id)
	w.emit({"t": "gadget", "id": h.id, "gadget": id, "slot": slot, "lvl": LEGACY_LVL})
	var F := fx_of(id)
	match String(F.get("type", id)):
		"deploy":
			_deploy(w, h, id, F)
		"decoy":
			_spawn_decoy(w, h, LEGACY_LVL, F)
		"summon":
			_summon(w, h, F)
		"buff":
			h.buff_t = float(F.dur)
			h.buff_rate = float(F.get("rate", 1.0))
			h.buff_speed = float(F.get("speed", 1.0))
			h.after_t = 0.0
			h.buff_id = id
			w.emit({"t": "buff", "id": h.id, "gadget": id, "dur": h.buff_t})
			w.toast(h, def(id).name + "！", "#ffb347", 1.0)
		"shield":
			h.eshield = h.max_hp * float(F.hpK)
			h.eshield_t = float(F.dur)
			h.eshield_id = id
			w.emit({"t": "eshield_up", "id": h.id, "gadget": id})
			w.toast(h, def(id).name + "！", "#7fe3ff", 1.0)
		"teleport":
			h.tp_t = float(F.cast)
			h.tp_id = id
			w.emit({"t": "tp_cast", "id": h.id, "dur": h.tp_t, "x": h.x, "y": h.y, "team": h.team})
			w.toast(h, "传送读条中…别挨打", "#7fe3ff", float(F.cast))
		"vision":
			h.nvg_t = float(F.dur)
			h.nvg_r = float(F.r)
			w.emit({"t": "nvg_on", "id": h.id, "dur": h.nvg_t})
			w.toast(h, "夜视仪开启", "#9dff8a", 1.0)
		"pulse":
			_pulse(w, h, F)
		_:
			_use_legacy(w, h, id, LEGACY_LVL)


static func _use_legacy(w: SimWorld, h: SimHamster, id: String, L: int) -> void:
	var G: Dictionary = w.R.gadgets
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
			h.eshield_id = id
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
			_spawn_decoy(w, h, L, {})
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
				h.beacon = {"x": h.x, "y": h.y, "until": w.t + float(B.life), "arm": w.t + float(B.armCd)}
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
	## 道具计时：护盾、急救包、喷射背包、增益 / 增益后的减速、读条传送、夜视
	if h.eshield_t > 0.0:
		h.eshield_t -= dt
		if h.eshield_t <= 0.0:
			h.eshield = 0.0
			h.eshield_id = ""
	if h.med_t > 0.0:
		h.med_t -= dt
		h.hp = minf(h.max_hp, h.hp + h.med_rate * dt)
		h.munch_t = maxf(h.munch_t, 0.15)
	if h.jet_t > 0.0:
		h.jet_t -= dt
	if h.buff_t > 0.0:
		h.buff_t -= dt
		if h.buff_t <= 0.0:
			var A: Dictionary = fx_of(h.buff_id).get("after", {})
			h.buff_rate = 1.0
			h.buff_speed = 1.0
			if not A.is_empty():
				h.after_t = float(A.dur)
				h.after_speed = float(A.speed)
				w.emit({"t": "buff_after", "id": h.id, "dur": h.after_t})
	elif h.after_t > 0.0:
		h.after_t -= dt
	if h.nvg_t > 0.0:
		h.nvg_t -= dt
	if h.root_t > 0.0:
		h.root_t -= dt
	if h.tp_t > 0.0:
		h.tp_t -= dt
		if h.tp_t <= 0.0:
			_teleport(w, h, fx_of(h.tp_id))


static func move_mul(h: SimHamster) -> float:
	## 增益道具对移速的倍率（SimMotion 用）
	if h.buff_t > 0.0:
		return h.buff_speed
	if h.after_t > 0.0:
		return h.after_speed
	return 1.0


static func rate_mul(h: SimHamster) -> float:
	return h.buff_rate if h.buff_t > 0.0 else 1.0


static func on_hurt(w: SimWorld, h: SimHamster) -> void:
	## 受到伤害：打断传送读条
	if h.tp_t > 0.0:
		h.tp_t = 0.0
		w.emit({"t": "tp_cancel", "id": h.id, "x": h.x, "y": h.y})
		w.toast(h, "传送被打断了！", "#ff8a7a", 1.2)


# ---------------------------------------------------------------------------
# 新道具的通用效果
# ---------------------------------------------------------------------------

static func _teleport(w: SimWorld, h: SimHamster, F: Dictionary) -> void:
	## 传送到地图四角区域里一个能走到、不在敌方鼠窝附近的随机点
	var M := w.map
	var cw := (M.max_x - M.min_x) * float(F.get("corner", 0.28))
	var ch := (M.max_y - M.min_y) * float(F.get("corner", 0.28))
	var eb: Vector2 = M.base_pos[SimWorld.ENEMY[h.team]]
	var avoid := float(F.get("avoidR", 900))
	var reach := M.field_to(M.base_pos[h.team].x, M.base_pos[h.team].y)
	var cands: Array = []
	for i in int(F.get("tries", 48)):
		var right := (i % 2) == 1
		var bottom := ((i / 2) % 2) == 1
		var x := (M.max_x - h.r - w.rnd() * cw) if right else (M.min_x + h.r + w.rnd() * cw)
		var y := (M.max_y - h.r - w.rnd() * ch) if bottom else (M.min_y + h.r + w.rnd() * ch)
		if M.overlaps_solid(x, y, h.r + 4.0) or Vector2(x - eb.x, y - eb.y).length() < avoid:
			continue
		var c := M.cell_of(x, y)
		if M.nav_pass.size() > c and M.nav_pass[c] == 0:
			continue
		if not reach.is_empty() and reach[c] < 0:
			continue
		cands.append(Vector2(x, y))
	if cands.is_empty():
		w.toast(h, "附近没有能落脚的角落", "#ff8a7a", 1.2)
		return
	var p: Vector2 = cands[int(w.rnd() * cands.size()) % cands.size()]
	var fx := h.x
	var fy := h.y
	h.x = p.x
	h.y = p.y
	h.px = h.x
	h.py = h.y
	h.vx = 0.0
	h.vy = 0.0
	M.resolve_circle(h, h.r)
	h.iframes = maxf(h.iframes, 0.3)
	w.emit({"t": "teleport", "id": h.id, "x0": fx, "y0": fy, "x1": h.x, "y1": h.y, "team": h.team})


static func _pulse(w: SimWorld, h: SimHamster, F: Dictionary) -> void:
	## 声呐：范围内的敌方单位在 dur 秒里对本队可见（穿墙）
	var R := float(F.r)
	var n := 0
	for e: SimEntity in w.foe_candidates(true):
		if e.team == h.team or Vector2(e.x - h.x, e.y - h.y).length() > R + e.r:
			continue
		e.ping_team = h.team
		e.ping_until = w.t + float(F.dur)
		if e is SimHamster:
			n += 1
	w.emit({"t": "sonar", "id": h.id, "x": h.x, "y": h.y, "r": R, "team": h.team, "dur": float(F.dur)})
	w.noise(h.x, h.y, "step", 0.6, h)
	w.toast(h, "声呐：%d 只敌方仓鼠" % n if n > 0 else "声呐：附近没有敌方仓鼠", "#7fe3ff", 1.4)


static func _summon(w: SimWorld, h: SimHamster, F: Dictionary) -> void:
	## 信号弹：在身边呼叫 n 个己方小兵，跟随主人 follow 秒，之后回最近的兵线
	var lane := _nearest_lane(w, h)
	if lane.is_empty():
		return
	var sp := float(F.get("spread", 40))
	for k in int(F.n):
		var m := w.spawn_minion(h.team, String(lane.lane))
		var a := TAU * k / maxf(1.0, float(F.n)) + w.rand(-0.4, 0.4)
		m.x = h.x + cos(a) * sp
		m.y = h.y + sin(a) * sp
		m.px = m.x
		m.py = m.y
		m.wp = mini(int(lane.i) + 1, m.path.size() - 1)
		m.follow = h
		m.follow_until = w.t + float(F.follow)
		w.map.resolve_circle(m, m.r)
	w.emit({"t": "signal", "id": h.id, "x": h.x, "y": h.y, "team": h.team})
	w.toast(h, "援兵到！", "#8de0a6", 1.2)


static func _nearest_lane(w: SimWorld, h: SimHamster) -> Dictionary:
	var best := {}
	var bd := 1e18
	for lane in w.map.lanes.keys():
		var path := w.lane_path(h.team, lane)
		for i in path.size():
			var d := SimUtil.d2(path[i].x, path[i].y, h.x, h.y)
			if d < bd:
				bd = d
				best = {"lane": lane, "i": i}
	return best


static func minion_follow_end(w: SimWorld, m: SimMinion) -> void:
	## 跟随结束：从离自己最近的兵线点继续推进
	m.follow = null
	var bi := m.wp
	var bd := 1e18
	for i in m.path.size():
		var d := SimUtil.d2(m.path[i].x, m.path[i].y, m.x, m.y)
		if d < bd:
			bd = d
			bi = i
	m.wp = mini(bi + 1, m.path.size() - 1)


static func _deploy(w: SimWorld, h: SimHamster, id: String, F: Dictionary) -> void:
	## 部署物：一个 SimStructure（kind = dep，dep = 道具 id，cfg = fx），由 update_dep 驱动
	var mx := int(F.get("max", 1))
	var own: Array = w.structs.filter(func(s): return s.kind == "dep" and s.dep == id and s.owner == h and not s.dead)
	while own.size() >= mx:
		var old: SimStructure = own.pop_front()
		old.dead = true
		w.emit({"t": "kill", "id": old.id, "kind": "dep", "dep": id, "x": old.x, "y": old.y, "team": old.team, "killer": -1})
	var a := h.aim
	var px := h.x
	var py := h.y
	match String(F.get("place", "front")):
		"front":
			var dist := float(F.get("dist", 34))
			var free := w.map.raycast_len(h.x, h.y, cos(a), sin(a), dist + float(F.get("r", 14)), 8.0)
			dist = maxf(0.0, minf(dist, free - float(F.get("r", 14))))
			px = h.x + cos(a) * dist
			py = h.y + sin(a) * dist
		"throw":
			var p := target(w, h)
			# 扔出去：沿直线飞到第一面墙为止，贴在墙面或落点的地面上
			var dx := p.x - h.x
			var dy := p.y - h.y
			var d := maxf(0.001, Vector2(dx, dy).length())
			var free2 := w.map.raycast_len(h.x, h.y, dx / d, dy / d, d, 8.0)
			var dd := minf(d, free2)
			px = h.x + dx / d * dd
			py = h.y + dy / d * dd
	var s := SimStructure.new()
	s.id = w.new_uid()
	s.kind = "dep"
	s.dep = id
	s.cfg = F
	s.team = h.team
	s.owner = h
	s.x = px
	s.y = py
	s.r = float(F.get("r", 14))
	s.hp = float(F.get("hp", 100))
	s.max_hp = s.hp
	s.aim = a
	s.life = float(F.get("life", 10))
	s.life_max = s.life
	s.cd = 0.5
	var P: Dictionary = F.get("parts", {})
	if P.has("shoot"):
		s.range_ = float(P.shoot.range)
		s.dmg = float(P.shoot.dmg)
		s.cd_max = float(P.shoot.cd)
		s.muzzle_h = float(P.shoot.get("muzzleH", 24))
	if String(F.get("place", "front")) != "throw":
		w.map.resolve_circle(s, s.r)
	s.px = s.x
	s.py = s.y
	w.structs.append(s)
	w.register(s)
	w.emit({"t": "spawn", "id": s.id, "kind": "dep", "dep": id, "team": h.team, "x": s.x, "y": s.y})
	if String(F.get("place", "")) == "throw":
		h.spit_t = 0.2


static func update_dep(w: SimWorld, s: SimStructure, dt: float) -> void:
	s.life -= dt
	if s.life <= 0.0:
		s.dead = true
		w.emit({"t": "kill", "id": s.id, "kind": "dep", "dep": s.dep, "x": s.x, "y": s.y, "team": s.team, "killer": -1})
		return
	var P: Dictionary = s.cfg.get("parts", {})
	if P.has("heal"):
		var HP: Dictionary = P.heal
		var rr := float(HP.r)
		for o in w.hams:
			if o.alive and o.team == s.team and o.hp < o.max_hp and Vector2(o.x - s.x, o.y - s.y).length() < rr + o.r:
				o.hp = minf(o.max_hp, o.hp + o.max_hp * float(HP.hps) * dt)
	if P.has("watch"):
		var WP: Dictionary = P.watch
		var rr2 := float(WP.r)
		var inside := {}
		for e: SimEntity in w.foe_candidates(false):
			if e.team == s.team or e.team == "neutral":
				continue
			if Vector2(e.x - s.x, e.y - s.y).length() > rr2 + e.r:
				continue
			inside[e.id] = true
			if not s.inside.has(e.id) and e is SimHamster:
				s.alert_t = w.t
				w.emit({"t": "cam_alert", "id": s.id, "x": s.x, "y": s.y, "team": s.team, "foe": e.id})
		s.inside = inside
	if P.has("snare"):
		var SN: Dictionary = P.snare
		for e: SimEntity in w.hash_range(s.x, s.y, float(SN.trigR) + 40.0):
			if not w.can_hit(s.team, e) or e.team == "neutral" or not (e is SimHamster or e is SimMinion or e is SimMob):
				continue
			if e.kind == "boss":
				continue
			if Vector2(e.x - s.x, e.y - s.y).length() < e.r + float(SN.trigR):
				if e is SimHamster:
					var th := e as SimHamster
					th.root_t = maxf(th.root_t, float(SN.root))
					th.roll_t = 0.0
				else:
					e.stun = maxf(e.stun, float(SN.root))
				var o: SimHamster = s.owner if is_instance_valid(s.owner) and s.owner.team == s.team else null
				w.deal_dmg(e, float(SN.dmg), {"team": s.team, "owner": o, "x": s.x, "y": s.y})
				s.dead = true
				w.emit({"t": "snare", "id": s.id, "x": s.x, "y": s.y, "team": s.team, "victim": e.id, "dur": float(SN.root)})
				w.emit({"t": "kill", "id": s.id, "kind": "dep", "dep": s.dep, "x": s.x, "y": s.y, "team": s.team, "killer": -1, "quiet": true})
				return
	if P.has("reflect"):
		var RF: Dictionary = P.reflect
		var rr3 := float(RF.r)
		for b in w.bullets:
			if b.dead or b.kind != "rocket" or b.team == s.team or b.reflected:
				continue
			if SimUtil.d2(b.x, b.y, s.x, s.y) > rr3 * rr3:
				continue
			# 原路反弹：速度反向，归属改成反射器这一队，射程按已飞过的距离重新算
			var flown := Vector2(b.x - b.x0, b.y - b.y0).length()
			b.vx = -b.vx
			b.vy = -b.vy
			b.team = s.team
			b.by = s
			b.owner = s.owner if is_instance_valid(s.owner) and s.owner.team == s.team else null
			b.hit.clear()
			b.x0 = b.x
			b.y0 = b.y
			b.reflected = true
			var spd := maxf(1.0, Vector2(b.vx, b.vy).length())
			b.life = maxf(b.life, (flown + 160.0) / spd)
			s.uses += 1
			w.emit({"t": "reflect", "id": s.id, "x": b.x, "y": b.y, "team": s.team})
			if s.uses >= int(RF.max):
				s.dead = true
				w.emit({"t": "kill", "id": s.id, "kind": "dep", "dep": s.dep, "x": s.x, "y": s.y, "team": s.team, "killer": -1})
				return
	if P.has("shoot"):
		_dep_shoot(w, s, P.shoot, dt)


static func _dep_shoot(w: SimWorld, s: SimStructure, S: Dictionary, dt: float) -> void:
	if s.t_t <= 0.0:
		s.t_t = float(S.get("retarget", 0.25))
		s.target = w.struct_target(s)
		if s.target == null and bool(S.get("mobs", false)):
			s.target = _nearest_mob(w, s)
	var tg := s.target
	if tg != null and (tg.dead or (tg is SimHamster and not (tg as SimHamster).alive)):
		tg = null
	if tg == null or not w.map.has_los(s.x, s.y, tg.x, tg.y):
		return
	var a := atan2(tg.y - s.y, tg.x - s.x)
	s.aim = SimUtil.turn_to(s.aim, a, float(S.get("turn", 10)) * dt)
	if s.cd <= 0.0 and absf(SimUtil.ang_diff(s.aim, a)) < float(S.get("fireAngle", 0.25)):
		s.cd = s.cd_max
		var gx := s.x + cos(s.aim) * float(S.get("muzzle", 20))
		var gy := s.y + sin(s.aim) * float(S.get("muzzle", 20))
		var sp := float(S.get("spread", 0.05))
		var b := w.new_bullet("trc", s, gx, gy, s.muzzle_h, s.aim + w.rand(-sp, sp), float(S.get("bulletSpeed", 1100)), s.dmg, s.range_ + 60.0)
		b.r = float(S.get("bulletR", 4))
		b.kb = float(S.get("kb", 20))
		b.owner = s.owner if is_instance_valid(s.owner) and s.owner.team == s.team else null
		b.weapon = "sentry"
		w.bullets.append(b)
		w.noise(s.x, s.y, "gun", 0.45, s)
		w.emit({"t": "struct_fire", "id": s.id, "x": gx, "y": gy, "h": s.muzzle_h, "aim": s.aim, "team": s.team, "kind": "dep"})


static func _nearest_mob(w: SimWorld, s: SimStructure) -> SimEntity:
	var best: SimEntity = null
	var bd := s.range_ * s.range_
	for e in w.mobs:
		if e.dead:
			continue
		var d := SimUtil.d2(e.x, e.y, s.x, s.y)
		if d < bd:
			bd = d
			best = e
	return best


static func cover_block(w: SimWorld, b: SimBullet) -> SimStructure:
	## 子弹是否打在某块展开式掩体的半圆板上（双方子弹都挡）；返回挡住它的掩体
	for s in w.covers:
		if s.dead:
			continue
		var B: Dictionary = s.cfg.parts.block
		var R := float(B.arcR)
		var th := float(B.thick) * 0.5 + b.r
		var dx := b.x - s.x
		var dy := b.y - s.y
		var d2 := dx * dx + dy * dy
		if d2 > (R + th) * (R + th) or d2 < (R - th) * (R - th):
			continue
		if absf(SimUtil.ang_diff(atan2(dy, dx), s.aim)) > float(B.half):
			continue
		return s
	return null


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
			freeze_at(w, b.x, b.y, float(Z.r) + float(Z.rPerLevel) * (L - 1), b.team, b.owner)


static func freeze_at(w: SimWorld, x: float, y: float, R: float, team: String, owner: SimHamster) -> void:
	## 冰冻爆炸（冰冻手雷、榴弹发射器的冰冻弹共用）
	var Z: Dictionary = w.R.gadgets.freeze
	w.emit({"t": "freeze", "x": x, "y": y, "r": R})
	for e: SimEntity in w.hash_range(x, y, R + 40.0):
		if not w.can_hit(team, e) or e.is_prop or e.kind in ["crate", "base", "turret"]:
			continue
		if Vector2(e.x - x, e.y - y).length() - e.r > R:
			continue
		w.stun_e(e, float(Z.stun))
		e.frozen_until = w.t + (float(Z.frozenHam) if e is SimHamster else float(Z.frozen))
		w.deal_dmg(e, float(Z.dmg), {"team": team, "owner": owner, "x": x, "y": y})


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

static func _spawn_decoy(w: SimWorld, h: SimHamster, L: int, F: Dictionary) -> void:
	## 诱饵：旧道具“诱饵仓鼠”（充气气球，参数在 rules.json）或全息诱饵（F = gadgets.json 的 fx，look = holo 和主人一模一样）
	var D: Dictionary = w.R.gadgets.decoy
	var a := h.aim
	var d := SimDecoy.new()
	d.id = w.new_uid()
	d.kind = "decoy"
	d.team = h.team
	d.owner = h
	d.skin = h.skin
	d.weapon_id = h.weapon_id
	d.x = h.x + cos(a) * float(F.get("dist", D.dist))
	d.y = h.y + sin(a) * float(F.get("dist", D.dist))
	d.r = float(F.get("r", D.r))
	d.hp = float(F.hp) if F.has("hp") else float(D.hp) * lvl_k(L, float(D.hpPerLevel))
	d.max_hp = d.hp
	d.life = float(F.life) if F.has("life") else float(D.life) + float(D.lifePerLevel) * (L - 1)
	d.lure = float(F.get("lure", 1.0))
	d.look = String(F.get("look", "balloon"))
	d.aim = a
	w.map.resolve_circle(d, d.r)
	d.px = d.x
	d.py = d.y
	w.decoys.append(d)
	w.register(d)
	w.emit({"t": "spawn", "id": d.id, "kind": "decoy", "team": h.team, "look": d.look})
	if F.has("lureR"):
		# 正在打主人的敌方 AI、小兵、野怪改打分身
		var LR := float(F.lureR)
		for o in w.hams:
			if o.ai != null and o.alive and o.team != h.team and o.ai.target == h and Vector2(o.x - d.x, o.y - d.y).length() < LR:
				o.ai.target = d
				o.ai.retarget = maxf(o.ai.retarget, 1.5)
		for m in w.minions:
			if not m.dead and m.team != h.team and m.target == h and Vector2(m.x - d.x, m.y - d.y).length() < LR:
				m.target = d
				m.t_t = maxf(m.t_t, 1.5)
		for e in w.mobs:
			if not e.dead and e.target == h and Vector2(e.x - d.x, e.y - d.y).length() < LR:
				SimMobs.aggro(w, e, d)


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


# ---------------------------------------------------------------------------
# AI：按 gadgets.json 每个道具的 ai 条件决定用哪个槽
# ---------------------------------------------------------------------------

static func ai_pick_slot(w: SimWorld, h: SimHamster, tg: SimEntity) -> String:
	## 两个槽里想用且能用的那个；都想用时按优先级（保命 > 交战 > 情报）。都不想用返回 ""
	var PR: Dictionary = w.R.ai.gadgetItem.prio
	var best := ""
	var bp := -1
	for slot in SLOTS:
		if not ready(w, h, slot):
			continue
		var cat := ai_want_cat(w, h, String(h.gad[slot].id), tg)
		if cat.is_empty():
			continue
		var p := int(PR.get(cat, 0))
		if p > bp:
			bp = p
			best = slot
	return best


static func ai_want_cat(w: SimWorld, h: SimHamster, id: String, tg: SimEntity) -> String:
	## 满足哪一组条件就返回它的类别（组里可以写 cat 覆盖道具的类别），都不满足返回 ""
	var A: Dictionary = def(id).get("ai", {})
	var when: Variant = A.get("when", [])
	var groups: Array = when if when is Array else [when]
	for g: Dictionary in groups:
		if _ai_cond(w, h, id, tg, g):
			return String(g.get("cat", A.get("cat", "fight")))
	return ""


static func ai_want(w: SimWorld, h: SimHamster, t: SimEntity, slot: String = "q") -> bool:
	return not ai_want_cat(w, h, String(h.gad[slot].id), t).is_empty()


static func _ai_cond(w: SimWorld, h: SimHamster, id: String, tg: SimEntity, g: Dictionary) -> bool:
	var GI: Dictionary = w.R.ai.gadgetItem
	var hpk := h.hp / maxf(1.0, h.max_hp)
	var d := Vector2(tg.x - h.x, tg.y - h.y).length() if tg != null else 1e9
	for k: String in g:
		var v: Variant = g[k]
		match k:
			"cat":
				continue
			"hpBelow":
				if hpk >= float(v):
					return false
			"hpAbove":
				if hpk <= float(v):
					return false
			"hurt":
				if (h.hurt_t > 0.0) != bool(v):
					return false
			"fight":
				if (tg is SimHamster) != bool(v):
					return false
			"target":
				if (tg != null) != bool(v):
					return false
			"foeDist":
				if tg == null or d < float(v[0]) or d > float(v[1]):
					return false
			"retreat":
				if (h.ai != null and h.ai.state == "retreat") != bool(v):
					return false
			"chased":
				if _foes_near(w, h, float(v[0])) <= 0:
					return false
			"lockedBy":
				if _locked_by(w, h, GI) < int(v):
					return false
			"hurtAllies":
				var n := 0
				for o in w.hams:
					if o.alive and o.team == h.team and o.hp < o.max_hp * float(v[2]) and Vector2(o.x - h.x, o.y - h.y).length() < float(v[1]):
						n += 1
				if n < int(v[0]):
					return false
			"noCover":
				if tg == null or not w.map.has_los(h.x, h.y, tg.x, tg.y):
					return false
				for s in w.covers:
					if not s.dead and s.team == h.team and Vector2(s.x - h.x, s.y - h.y).length() < float(GI.coverNear):
						return false
			"jungle":
				if _in_jungle(w, h, float(GI.junglePR)) != bool(v):
					return false
			"enemyZone":
				var mid := (w.map.min_x + w.map.max_x) * 0.5
				if ((h.x > mid) if h.team == "blue" else (h.x < mid)) != bool(v):
					return false
			"blackout":
				if w.blackout != bool(v):
					return false
			"foeRocket":
				var found := false
				for o in w.hams:
					if o.alive and o.team != h.team and o.weapon_id == "rocket" and w.vis[h.team].has(o.id) and Vector2(o.x - h.x, o.y - h.y).length() < float(v[0]):
						found = true
						break
				if not found:
					return false
			"defend":
				if not _defending(w, h, float(v[0])):
					return false
			"pushing":
				var mates := false
				for m in w.minions:
					if not m.dead and m.team == h.team and Vector2(m.x - h.x, m.y - h.y).length() < 400.0:
						mates = true
						break
				if mates != bool(v) or (h.ai != null and h.ai.state == "retreat"):
					return false
			"spot":
				if not _at_spot(w, h, id, float(v[0]), float(GI.spotSpacing)):
					return false
			"dimFoe":
				if tg == null or tg.team == h.team or w.vis[h.team].has(tg.id) != not bool(v):
					return false
			"noActive":
				if _active(h, id) == bool(v):
					return false
			"chance":
				if w.rnd() >= float(v):
					return false
	return true


static func _active(h: SimHamster, id: String) -> bool:
	## 同类效果是否还在生效（避免叠着浪费）
	match String(fx_of(id).get("type", id)):
		"buff":
			return h.buff_t > 0.0
		"shield", "eshield":
			return h.eshield_t > 0.0 and h.eshield > 0.0
		"vision":
			return h.nvg_t > 0.0
		"medkit":
			return h.med_t > 0.0
		"teleport":
			return h.tp_t > 0.0
	return false


static func _foes_near(w: SimWorld, h: SimHamster, R: float) -> int:
	var n := 0
	for o in w.hams:
		if o.alive and o.team != h.team and w.is_seen_by(h.team, o) and Vector2(o.x - h.x, o.y - h.y).length() < R:
			n += 1
	return n


static func _locked_by(w: SimWorld, h: SimHamster, GI: Dictionary) -> int:
	## 有几个敌方单位正在打自己：AI 仓鼠、小兵、野怪看它们的目标；真人看是不是在射程内正对着自己
	var n := 0
	for o in w.hams:
		if not o.alive or o.team == h.team:
			continue
		if o.ai != null:
			if o.ai.target == h:
				n += 1
		elif Vector2(o.x - h.x, o.y - h.y).length() < float(GI.lockRange) and absf(SimUtil.ang_diff(o.aim, atan2(h.y - o.y, h.x - o.x))) < float(GI.lockFacing):
			n += 1
	for m in w.minions:
		if not m.dead and m.team != h.team and m.target == h:
			n += 1
	for e in w.mobs:
		if not e.dead and e.target == h:
			n += 1
	for s in w.structs:
		if not s.dead and s.team != h.team and s.target == h:
			n += 1
	return n


static func _in_jungle(w: SimWorld, h: SimHamster, R: float) -> bool:
	if h.ai != null and h.ai.state == "jungle":
		return true
	for c in w.camps:
		if Vector2(float(c.x) - h.x, float(c.y) - h.y).length() < R:
			return true
	return false


static func _defending(w: SimWorld, h: SimHamster, R: float) -> bool:
	var near_home := false
	for s in w.structs:
		if not s.dead and s.team == h.team and (s.kind == "turret" or s.kind == "base") and Vector2(s.x - h.x, s.y - h.y).length() < R:
			near_home = true
			break
	if not near_home:
		return false
	for e: SimEntity in w.foe_candidates(false):
		if e.team != h.team and e.team != "neutral" and Vector2(e.x - h.x, e.y - h.y).length() < R + 200.0:
			return true
	return false


static func _at_spot(w: SimWorld, h: SimHamster, id: String, R: float, spacing: float) -> bool:
	## 路口（兵线拐点）、野区入口（营地外圈）、基地入口（鼠窝外圈）附近，且附近没有自己的同种部署物
	for s in w.structs:
		if not s.dead and s.kind == "dep" and s.dep == id and s.team == h.team and Vector2(s.x - h.x, s.y - h.y).length() < spacing:
			return false
	for c in w.camps:
		var dc := Vector2(float(c.x) - h.x, float(c.y) - h.y).length()
		if dc > 220.0 and dc < 220.0 + R * 2.0:
			return true
	for team in SimWorld.TEAMS:
		var b: Vector2 = w.map.base_pos[team]
		var db := Vector2(b.x - h.x, b.y - h.y).length()
		if db > 360.0 and db < 360.0 + R * 2.0:
			return true
	for lane in w.map.lanes.keys():
		var path: PackedVector2Array = w.map.lanes[lane]
		for i in range(1, path.size() - 1):
			var a0 := (path[i] - path[i - 1]).angle()
			var a1 := (path[i + 1] - path[i]).angle()
			if absf(SimUtil.ang_diff(a0, a1)) > 0.5 and Vector2(path[i].x - h.x, path[i].y - h.y).length() < R:
				return true
	return false
