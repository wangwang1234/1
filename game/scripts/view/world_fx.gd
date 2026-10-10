class_name WorldFx
extends Node3D
## 批次 2 的持续性世界特效（只读 sim 状态）：火焰区域、烟雾、毒气 / 电流带、侦察弹道、电磁炮 / 激光光束、
## 飞行中的火箭、喷火器火流、剑气、武士刀刀光、照明弹、地雷、信标、哨戒炮、诱饵、宠物、野怪。
## 坐标：米（逻辑坐标 × 0.01）。

const MAX_BEAM := 160

var fx: FxSystem
var mv: MatchView
var _mm_beam: MultiMesh
var _beams: Array = []            # 一次性光束：{a: Vector3, b: Vector3, w, col, core, t, life}
var _fire_lights := {}            # fid -> OmniLight3D
var _rockets := {}                # bullet id -> Node3D
var _mob_views := {}
var _pet_views := {}
var _decoy_views := {}
var _sentry_views := {}
var _simple := {}                 # key -> SimpleNode（地雷、信标、照明弹）
var _rng := RandomNumberGenerator.new()
var _laser_snd_t := 0.0


func _ready() -> void:
	_rng.randomize()
	_mm_beam = MultiMesh.new()
	_mm_beam.transform_format = MultiMesh.TRANSFORM_3D
	_mm_beam.use_colors = true
	_mm_beam.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/beam.gdshader")
	q.material = mat
	_mm_beam.mesh = q
	_mm_beam.instance_count = MAX_BEAM
	_mm_beam.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm_beam
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 10000.0
	add_child(mmi)


static func w3(x: float, y: float, h: float = 0.0) -> Vector3:
	return Vector3(x * 0.01, h * 0.01, y * 0.01)


func add_beam(a: Vector3, b: Vector3, w: float, col: Color, life: float, core: float = 0.8) -> void:
	if _beams.size() >= MAX_BEAM / 2:
		_beams.pop_front()
	_beams.append({"a": a, "b": b, "w": w, "col": col, "core": core, "t": 0.0, "life": life})


func slash(pos: Vector3, a: float, reach: float, arc: float, dir: float, col: Color = Color("#d8f0ff"), life: float = 0.18) -> void:
	## 刀光：沿弧线摆一圈短光束，0.18 秒淡出
	var n := 9
	for i in n:
		var k0 := float(i) / n
		var k1 := float(i + 1) / n
		var a0 := a + (k0 - 0.5) * arc * dir
		var a1 := a + (k1 - 0.5) * arc * dir
		var r := reach * (0.85 + 0.15 * sin(k0 * PI))
		var p0 := pos + Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := pos + Vector3(cos(a1), 0, sin(a1)) * r
		add_beam(p0, p1, 0.05 + 0.05 * sin(k0 * PI), col, life * (0.6 + 0.4 * k0), 0.9)
	for i in fx._n(5):
		var aa := a + _rng.randf_range(-arc, arc) * 0.5
		var p := pos + Vector3(cos(aa), 0, sin(aa)) * reach * _rng.randf_range(0.7, 1.05)
		fx.spawn(p, Vector3(-sin(aa), 0.2, cos(aa)) * dir * 2.6, 0.18, 0.02, col, FxSystem.S_STREAK, true, 0.0, 2.0, 0.0, false, 0.6)


func _beam_xf(a: Vector3, b: Vector3, w: float, cam: Basis, flat: bool) -> Transform3D:
	var d := b - a
	var len := d.length()
	if len < 0.001:
		return Transform3D(Basis.from_scale(Vector3.ZERO), a)
	var dir := d / len
	var side: Vector3
	var nrm: Vector3
	if flat:
		side = dir.cross(Vector3.UP).normalized()
		nrm = Vector3.UP
	else:
		side = cam.z.cross(dir).normalized()
		nrm = cam.z
	return Transform3D(Basis(dir * len, side * w, nrm), (a + b) * 0.5)


# ---------------------------------------------------------------------------
# 每帧同步
# ---------------------------------------------------------------------------

func sync(w: SimWorld, alpha: float, delta: float, cam: Basis) -> void:
	var team := mv.local_team
	var teams: Array = mv.players.map(func(q): return q.team)
	var n := 0
	# 一次性光束
	var i := _beams.size() - 1
	while i >= 0:
		var B: Dictionary = _beams[i]
		B.t = float(B.t) + delta
		if float(B.t) >= float(B.life):
			_beams.remove_at(i)
		i -= 1
	for B in _beams:
		if n >= MAX_BEAM:
			break
		var k := float(B.t) / float(B.life)
		var c: Color = B.col
		c.a *= 1.0 - k
		_mm_beam.set_instance_transform(n, _beam_xf(B.a, B.b, float(B.w) * (1.0 + 0.8 * k), cam, false))
		_mm_beam.set_instance_color(n, c)
		_mm_beam.set_instance_custom_data(n, Color(float(B.core), 0, 0, 0))
		n += 1
	# 激光（每帧按仓鼠当前光束画）
	for h in w.hams:
		if h.beams.is_empty() or not h.alive or w.t - h.beam_tick_t > 0.15 or not mv.team_sees(h):
			continue
		var col := Color("#9fe8ff") if h.team == "blue" else Color("#ff8fb4")
		for bm: Dictionary in h.beams:
			if n >= MAX_BEAM - 1:
				break
			var a := w3(float(bm.x0), float(bm.y0), float(bm.h))
			var b := w3(float(bm.x1), float(bm.y1), float(bm.h))
			var wk := 0.6 if bool(bm.side) else 1.0
			_mm_beam.set_instance_transform(n, _beam_xf(a, b, 0.07 * wk * (1.0 + 0.15 * sin(w.t * 60.0)), cam, false))
			_mm_beam.set_instance_color(n, Color(col.r, col.g, col.b, 0.85))
			_mm_beam.set_instance_custom_data(n, Color(1.0, 0, 0, 0))
			n += 1
			if bool(bm.hit) and _rng.randf() < 0.5:
				fx.spawn(b, fx.rand_dir() * 1.2 + Vector3(0, 0.6, 0), 0.15, 0.02, col, FxSystem.S_STREAK, true, 3.0, 2.0, 0.0, false, 0.5)
	# 侦察弹道（只有本队看得到）
	for c in w.corrs:
		if not (c.team in teams) or n >= MAX_BEAM:
			continue
		var left := float(c.until) - w.t
		_mm_beam.set_instance_transform(n, _beam_xf(w3(c.x0, c.y0, 3), w3(c.x1, c.y1, 3), float(c.w) * 0.02, cam, true))
		_mm_beam.set_instance_color(n, Color(0.6, 0.9, 1.0, 0.18 * clampf(left, 0.0, 1.0)))
		_mm_beam.set_instance_custom_data(n, Color(0.2, 0, 0, 0))
		n += 1
	# 电流带 / 毒气
	for z in w.zones:
		if z.has("seg"):
			var g: Array = z.seg
			if n < MAX_BEAM:
				_mm_beam.set_instance_transform(n, _beam_xf(w3(g[0], g[1], 2), w3(g[2], g[3], 2), float(z.w) * 0.02, cam, true))
				_mm_beam.set_instance_color(n, Color(0.5, 0.9, 1.0, 0.25 + 0.1 * sin(w.t * 30.0)))
				_mm_beam.set_instance_custom_data(n, Color(0.5, 0, 0, 0))
				n += 1
			if _rng.randf() < delta * 14.0:
				var k2 := _rng.randf()
				var p := w3(lerpf(g[0], g[2], k2), lerpf(g[1], g[3], k2), 4)
				fx.spawn(p, fx.rand_dir() * 0.6 + Vector3(0, 0.8, 0), 0.2, 0.02, Color("#9fe8ff"), FxSystem.S_STREAK, true, 3.0, 2.0, 0.0, false, 0.5)
		elif _rng.randf() < delta * 12.0 * fx.fx_scale:
			var rr := float(z.r) * 0.01
			var p2 := w3(float(z.x), float(z.y)) + Vector3(_rng.randf_range(-rr, rr) * 0.7, _rng.randf_range(0.04, 0.2), _rng.randf_range(-rr, rr) * 0.6)
			fx.spawn(p2, Vector3(0, 0.08, 0), 1.0, _rng.randf_range(0.3, 0.44), Color(0.6, 0.83, 0.42, 0.55), FxSystem.S_SMOKE, false, -0.05, 1.0, 0.1)
	# 剑气：每颗画一道弯月
	for b: SimBullet in w.bullets:
		if b.kind != "swave" or n >= MAX_BEAM - 8:
			continue
		var pos := w3(lerpf(b.px, b.x, alpha), lerpf(b.py, b.y, alpha), b.h)
		var an := atan2(b.vy, b.vx)
		var rr2 := b.r * 1.3 * 0.01
		var col2 := Color("#ff9ff0") if b.big else Color("#c9b8ff")
		for j in 6:
			var t0 := -1.1 + 2.2 * float(j) / 6.0
			var t1 := -1.1 + 2.2 * float(j + 1) / 6.0
			var bend0 := 0.6 + 0.4 * sin(float(j) / 6.0 * PI)
			var p0 := pos + Vector3(cos(an + t0), 0, sin(an + t0)) * rr2 * bend0
			var p1 := pos + Vector3(cos(an + t1), 0, sin(an + t1)) * rr2 * (0.6 + 0.4 * sin(float(j + 1) / 6.0 * PI))
			_mm_beam.set_instance_transform(n, _beam_xf(p0, p1, 0.022 * b.wr * 2.0, cam, false))
			_mm_beam.set_instance_color(n, col2)
			_mm_beam.set_instance_custom_data(n, Color(0.9, 0, 0, 0))
			n += 1
	_mm_beam.visible_instance_count = n
	# 火流 / 火箭
	var seen_r := {}
	for b: SimBullet in w.bullets:
		if b.kind == "flame":
			if _rng.randf() < 0.8 * fx.fx_scale:
				var blue := bool(b.fx.get("blue", false))
				var fc := Color(0.55, 0.75, 1.0) if blue else Color(1.0, _rng.randf_range(0.45, 0.7), 0.18)
				fx.spawn(w3(b.x, b.y, b.h), Vector3(b.vx, 0, b.vy) * 0.003 + Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0.1, 0.4), _rng.randf_range(-0.2, 0.2)),
					_rng.randf_range(0.18, 0.32), b.r * 0.01 * _rng.randf_range(0.9, 1.4), fc, FxSystem.S_CIRCLE, true, -0.6, 2.0, -0.1)
		elif b.kind == "rocket":
			seen_r[b.id] = true
			if not _rockets.has(b.id):
				var rn := ToonMaterials.instance("res://assets/models/props/fx_rocket.glb", 1.2)
				rn.scale = Vector3.ONE * 1.3
				add_child(rn)
				_rockets[b.id] = rn
			var node: Node3D = _rockets[b.id]
			var p := w3(lerpf(b.px, b.x, alpha), lerpf(b.py, b.y, alpha), b.h)
			node.position = p
			node.rotation = Vector3(0, HamsterView.yaw_for(atan2(b.vy, b.vx)), 0)
			var back := -Vector3(b.vx, 0, b.vy).normalized()
			if _rng.randf() < 0.8 * fx.fx_scale:
				fx.spawn(p + back * 0.1, Vector3(_rng.randf_range(-0.15, 0.15), _rng.randf_range(0.05, 0.2), _rng.randf_range(-0.15, 0.15)), _rng.randf_range(0.4, 0.7), _rng.randf_range(0.06, 0.1), Color(0.64, 0.61, 0.71, 0.75), FxSystem.S_SMOKE, false, -0.1, 1.5, 0.22)
				fx.spawn(p + back * 0.08, back * 0.6, 0.12, _rng.randf_range(0.08, 0.12), Color(1.0, 0.7, 0.3), FxSystem.S_CIRCLE, true, 0.0, 2.0, -0.2)
	for id in _rockets.keys():
		if not seen_r.has(id):
			(_rockets[id] as Node).queue_free()
			_rockets.erase(id)
	_sync_fires(w, delta)
	_sync_smokes(w, delta)
	_sync_entities(w, alpha, delta)
	_sync_simple(w, delta)


func _sync_fires(w: SimWorld, delta: float) -> void:
	var seen := {}
	for f in w.fires:
		var fid := int(f.id)
		seen[fid] = true
		var k := float(f.t) / maxf(0.01, float(f.life))
		var r := float(f.r) * 0.01
		var c := w3(float(f.x), float(f.y))
		for j in 2:
			if _rng.randf() < delta * 14.0 * fx.fx_scale:
				var a := _rng.randf() * TAU
				var rr := sqrt(_rng.randf()) * r
				var fs := _rng.randf_range(0.14, 0.26) * (1.0 - k * 0.5)
				fx.spawn(c + Vector3(cos(a) * rr, fs * 0.55, sin(a) * rr * 0.8), Vector3(_rng.randf_range(-0.1, 0.1), _rng.randf_range(0.4, 0.9), _rng.randf_range(-0.1, 0.1)),
					_rng.randf_range(0.3, 0.6), fs, Color(1.0, _rng.randf_range(0.4, 0.7), 0.15), FxSystem.S_FLAME if j == 0 else FxSystem.S_CIRCLE, true, -0.4, 2.0, -0.2)
		if _rng.randf() < delta * 5.0:
			fx.spawn(c + Vector3(_rng.randf_range(-r, r) * 0.6, _rng.randf_range(0.2, 0.4), _rng.randf_range(-r, r) * 0.5), Vector3(0, 0.45, 0), _rng.randf_range(1.0, 1.6), _rng.randf_range(0.2, 0.34), Color(0.23, 0.2, 0.25, 0.7), FxSystem.S_SMOKE, false, -0.3, 1.0, 0.2)
		if not _fire_lights.has(fid) and _fire_lights.size() < 8:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.55, 0.2)
			l.light_specular = 0.0
			l.omni_range = r + 1.5
			l.position = c + Vector3(0, 0.3, 0)
			add_child(l)
			_fire_lights[fid] = l
			fx.scorch(c, r)
		if _fire_lights.has(fid):
			var l2: OmniLight3D = _fire_lights[fid]
			l2.light_energy = (0.9 + 0.25 * sin(w.t * 17.0 + fid) + 0.15 * sin(w.t * 5.0)) * clampf((1.0 - k) * 4.0, 0.0, 1.0)
	for fid in _fire_lights.keys():
		if not seen.has(fid):
			(_fire_lights[fid] as Node).queue_free()
			_fire_lights.erase(fid)


func _sync_smokes(w: SimWorld, delta: float) -> void:
	for s in w.smokes:
		var k := float(s.t) / maxf(0.01, float(s.life))
		var r := float(s.r) * 0.01
		var c := w3(float(s.x), float(s.y))
		var rate := 22.0 if k < 0.85 else 6.0
		for j in 2:
			if _rng.randf() < delta * rate * 0.5 * fx.fx_scale:
				var a := _rng.randf() * TAU
				var rr := sqrt(_rng.randf()) * r
				fx.spawn(c + Vector3(cos(a) * rr, _rng.randf_range(0.1, 0.6), sin(a) * rr * 0.85), Vector3(_rng.randf_range(-0.12, 0.12), _rng.randf_range(0.04, 0.14), _rng.randf_range(-0.12, 0.12)),
					_rng.randf_range(1.4, 2.2), _rng.randf_range(0.46, 0.7) * (1.0 - k * 0.3), Color(0.55, 0.54, 0.6, 0.85), FxSystem.S_SMOKE, false, -0.02, 0.8, 0.14)


func _sync_entities(w: SimWorld, alpha: float, delta: float) -> void:
	# 野怪
	var seen := {}
	for e in w.mobs:
		seen[e.id] = true
		if not _mob_views.has(e.id):
			var v := B2Views.MobView.new()
			add_child(v)
			v.setup(e)
			_mob_views[e.id] = v
		var mvw: B2Views.MobView = _mob_views[e.id]
		var mk := mv.vis_mask(e)
		var vis := mk != 0
		mvw.sync(e, alpha, delta, vis)
		MatchView.apply_mask(mvw, mk)
		if vis and e.burn_t > 0.0 and _rng.randf() < 0.45:
			fx.burn(w3(e.x, e.y, 10))
		if vis and e.stun > 0.0 and _rng.randf() < delta * 8.0:
			fx.spawn(w3(e.x + _rng.randf_range(-10, 10), e.y + _rng.randf_range(-10, 10), e.r * 2.4), Vector3(0, 0.2, 0), 0.4, 0.06, Color("#ffd166"), FxSystem.S_STAR, true, 0.0, 0.0)
	for id in _mob_views.keys():
		if not seen.has(id):
			(_mob_views[id] as Node).queue_free()
			_mob_views.erase(id)
	# 宠物
	seen.clear()
	for p in w.pets:
		seen[p.id] = true
		if not _pet_views.has(p.id):
			var v2 := B2Views.PetView.new()
			add_child(v2)
			v2.setup(p)
			_pet_views[p.id] = v2
		var pmk := mv.vis_mask(p.owner) if p.owner != null else 0
		(_pet_views[p.id] as B2Views.PetView).sync(p, alpha, delta, pmk != 0)
		MatchView.apply_mask(_pet_views[p.id], pmk)
	for id in _pet_views.keys():
		if not seen.has(id):
			(_pet_views[id] as Node).queue_free()
			_pet_views.erase(id)
	# 诱饵
	seen.clear()
	for d in w.decoys:
		seen[d.id] = true
		if not _decoy_views.has(d.id):
			var v3 := B2Views.DecoyView.new()
			add_child(v3)
			v3.setup(d)
			_decoy_views[d.id] = v3
		var dmk := mv.vis_mask(d)
		(_decoy_views[d.id] as B2Views.DecoyView).sync(d, delta, dmk != 0)
		MatchView.apply_mask(_decoy_views[d.id], dmk)
	for id in _decoy_views.keys():
		if not seen.has(id):
			(_decoy_views[id] as Node).queue_free()
			_decoy_views.erase(id)
	# 哨戒炮
	seen.clear()
	for s in w.structs:
		if s.kind != "sentry":
			continue
		seen[s.id] = true
		if not _sentry_views.has(s.id):
			var v4 := B2Views.SentryView.new()
			add_child(v4)
			v4.setup(s)
			_sentry_views[s.id] = v4
		var smk := mv.vis_mask(s)
		(_sentry_views[s.id] as B2Views.SentryView).sync(s, delta, smk != 0)
		MatchView.apply_mask(_sentry_views[s.id], smk)
	for id in _sentry_views.keys():
		if not seen.has(id):
			(_sentry_views[id] as Node).queue_free()
			_sentry_views.erase(id)


func sentry_fired(id: int) -> void:
	if _sentry_views.has(id):
		(_sentry_views[id] as B2Views.SentryView).on_fire()


func pet_pecked(id: int) -> void:
	if _pet_views.has(id):
		(_pet_views[id] as B2Views.PetView).peck()


func _sync_simple(w: SimWorld, delta: float) -> void:
	var want := {}
	var masks := {}
	for m in w.mines:
		var key := "mine_%d" % int(m.id)
		var mk := 0
		for pl in mv.players:
			if m.team == pl.team or w.vis[pl.team].has(key):
				mk |= int(MatchView.TEAM_BIT.get(pl.team, 2))
		if mv.players.is_empty():
			mk = 6
		masks[key] = mk
		if mk != 0:
			want[key] = {"kind": "mine", "path": "res://assets/models/props/gad_mine.glb", "team": m.team, "pos": w3(m.x, m.y), "lc": B2Views.TEAM_COL[m.team], "le": 0.0, "lr": 0.6}
	for h in w.hams:
		if not h.beacon.is_empty() and h.team in mv.players.map(func(q): return q.team):
			masks["beacon_%d" % h.id] = int(MatchView.TEAM_BIT.get(h.team, 2))
			want["beacon_%d" % h.id] = {"kind": "beacon", "path": "res://assets/models/props/gad_beacon.glb", "team": h.team, "pos": w3(float(h.beacon.x), float(h.beacon.y)), "lc": Color("#7fe3ff"), "le": 0.8, "lr": 1.4}
	for f in w.flares:
		want["flare_%d" % int(f.id)] = {"kind": "flare", "path": "res://assets/models/props/gad_flare.glb", "team": f.team, "pos": w3(float(f.x), float(f.y), float(f.h)), "lc": Color(1.0, 0.45, 0.35), "le": 2.8, "lr": 6.0}
	for key in want:
		var d: Dictionary = want[key]
		if not _simple.has(key):
			var sn := B2Views.SimpleNode.new()
			add_child(sn)
			sn.setup(String(d.kind), String(d.path), String(d.team), d.lc, float(d.le), float(d.lr))
			_simple[key] = sn
		var node: B2Views.SimpleNode = _simple[key]
		MatchView.apply_mask(node, int(masks.get(key, 6)))
		node.position = d.pos
		node.tick(delta)
		if d.kind == "flare" and _rng.randf() < delta * 14.0:
			fx.spawn(node.position, Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.8, -0.2), _rng.randf_range(-0.3, 0.3)), _rng.randf_range(0.3, 0.6), 0.02, Color("#ff9a6a"), FxSystem.S_STREAK, true, 3.0, 1.0, 0.0, false, 0.4)
	for key in _simple.keys():
		if not want.has(key):
			(_simple[key] as Node).queue_free()
			_simple.erase(key)


func bolt(a: Vector3, b: Vector3, col: Color = Color("#9fe8ff"), w: float = 0.03, life: float = 0.14, segs: int = 5) -> void:
	## 锯齿闪电：a→b 之间折几段，末端炸一点火花
	var prev := a
	var side := (b - a).cross(Vector3.UP).normalized()
	for i in range(1, segs + 1):
		var t := float(i) / segs
		var p := a.lerp(b, t)
		if i < segs:
			var j := (a.distance_to(b) * 0.12) * (1.0 if i % 2 == 0 else -1.0) * _rng.randf_range(0.5, 1.2)
			p += side * j + Vector3(0, _rng.randf_range(-0.03, 0.06), 0)
		add_beam(prev, p, w, col, life, 1.0)
		prev = p
	fx.spawn(b, Vector3.ZERO, 0.08, 0.12, col.lightened(0.4), FxSystem.S_STAR, true, 0, 0)


func pillar(pos: Vector3, col: Color, h: float = 2.2, life: float = 0.45) -> void:
	## 光柱（传送、复活）：一根竖直的粗光束 + 往上飘的光点
	add_beam(pos, pos + Vector3(0, h, 0), 0.28, col, life, 0.9)
	add_beam(pos, pos + Vector3(0, h * 0.7, 0), 0.12, col.lightened(0.5), life * 0.8, 1.0)
	for i in fx._n(10):
		fx.spawn(pos + Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0.0, 0.4), _rng.randf_range(-0.2, 0.2)), Vector3(0, _rng.randf_range(1.2, 2.6), 0), _rng.randf_range(0.4, 0.7), 0.03, col.lightened(0.3), FxSystem.S_STREAK, true, -1.0, 0.5, 0.0, false, 0.8)
