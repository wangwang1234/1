class_name SimVision
extends RefCounted
## 黑暗视野（全队共享）。对应原型 n2c.js 的 computeVis / litBy。
## 结果写入 world.vis[team]：id -> true。表现层对不在集合里的敌人直接隐藏，AI 也只在可见集合里选目标。


static func _lit_by(w: SimWorld, lights: Array, e: SimEntity) -> bool:
	var V: Dictionary = w.R.vision
	var cone_min := float(V.coneMinDist)
	var los_min := float(V.losMinDist)
	for s: Dictionary in lights:
		if s.has("seg"):
			var g: Array = s.seg
			if SimUtil.seg_point_dist(e.x, e.y, g[0], g[1], g[2], g[3]) < float(s.w) + e.r:
				return true
			continue
		var dx := e.x - float(s.x)
		var dy := e.y - float(s.y)
		var d := sqrt(dx * dx + dy * dy)
		if d > float(s.r) + e.r:
			continue
		if s.has("dir") and d > e.r + cone_min:
			var c := (dx * cos(float(s.dir)) + dy * sin(float(s.dir))) / maxf(d, 0.001)
			if c < float(s.cos):
				continue
		if bool(s.get("los", false)) and d > e.r + los_min:
			if not w.map.has_los(float(s.x), float(s.y), e.x, e.y):
				continue
			if SimGadgets.smoke_blocks(w, float(s.x), float(s.y), e.x, e.y):
				continue
		return true
	return false


static func lights_for(w: SimWorld, team: String) -> Array:
	## 某队的全部光源 / 视野源（表现层也用它画手电和视野）
	var V: Dictionary = w.R.vision
	var L: Array = []
	for p in w.props:
		if p.kind == "lamp" and not p.dead:
			L.append({"x": p.x, "y": p.y, "r": float(V.lampRadius), "los": true})
	for f in w.fires:
		L.append({"x": f.x, "y": f.y, "r": float(f.r) + float(V.fireExtra), "los": true})
	if float(w.boom.t) > 0.0:
		L.append({"x": float(w.boom.x), "y": float(w.boom.y), "r": float(V.boomRadius), "los": true})
	for f in w.flares:
		if f.team == team:
			L.append({"x": f.x, "y": f.y, "r": float(w.R.gadgets.flare.radius), "los": true})
	for c in w.corrs:
		if c.team == team:
			L.append({"seg": [c.x0, c.y0, c.x1, c.y1], "w": c.w})
	for h in w.hams:
		if not h.alive or h.team != team:
			continue
		var nv := float(h.st.get("nvg", 0.0))
		var tal_nv := h.tal.has("nightvision")
		var nr := maxf(float(V.nightvisionRadius) if tal_nv else float(V.selfRadius), nv) + h.r
		L.append({"x": h.x, "y": h.y, "r": nr, "los": not (nv > 0.0 or tal_nv)})
		L.append({"x": h.x, "y": h.y, "r": SimWeapons.light_range(h), "dir": h.aim, "cos": SimWeapons.light_cos(h), "los": true, "torch": h.id})
		var P := SimWeapons.params(h)
		if P.special.has("aimLine"):
			var ln := float(P.aimLen)
			L.append({"seg": [h.x, h.y, h.x + cos(h.aim) * ln, h.y + sin(h.aim) * ln], "w": float(P.special.aimLine)})
	for s in w.structs:
		if s.dead or s.team != team:
			continue
		var rr := float(V.baseRadius) if s.kind == "base" else (s.range_ + float(V.turretExtra) if s.kind == "turret" else float(V.sentryRadius))
		L.append({"x": s.x, "y": s.y, "r": rr, "los": true})
	for m in w.minions:
		if not m.dead and m.team == team:
			L.append({"x": m.x, "y": m.y, "r": float(V.minionRadius), "los": true})
	return L


static func compute(w: SimWorld) -> void:
	for team in SimWorld.TEAMS:
		var VS := {}
		var L := lights_for(w, team)
		for h in w.hams:
			if h.alive and h.team != team and (h.invis_t <= 0.0 or h.reveal_t > 0.0):
				if h.reveal_t > 0.0 or (h.mark_team == team and w.t < h.mark_until) or _lit_by(w, L, h):
					VS[h.id] = true
		for m in w.minions:
			if not m.dead and m.team != team:
				if m.reveal_t > 0.0 or (m.mark_team == team and w.t < m.mark_until) or _lit_by(w, L, m):
					VS[m.id] = true
		for e in w.mobs:
			if not e.dead:
				if e.reveal_t > 0.0 or (e.mark_team == team and w.t < e.mark_until) or _lit_by(w, L, e):
					VS[e.id] = true
		for d in w.decoys:
			if not d.dead and d.team != team and _lit_by(w, L, d):
				VS[d.id] = true
		for s in w.structs:
			if not s.dead and s.kind == "sentry" and s.team != team and _lit_by(w, L, s):
				VS[s.id] = true
		var MR := float(w.R.gadgets.mine.visR)
		var probe := SimEntity.new()
		probe.r = MR
		for m in w.mines:
			if m.team != team:
				probe.x = float(m.x)
				probe.y = float(m.y)
				if _lit_by(w, L, probe):
					VS["mine_%d" % int(m.id)] = true
		w.vis[team] = VS
