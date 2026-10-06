class_name MatchView
extends Node3D
## 一局对战的表现层总控：持有 SimWorld，60Hz 推进逻辑，事件分发到各表现节点 / 特效 / 音效 / 镜头 / 界面。
## 逻辑与表现分离：这里只读 sim 状态，唯一写入的是本地玩家的输入。

signal finished(winner: String, stats: Dictionary)
signal pause_requested

const TEAM_COL := {"blue": Color("#4fa3ff"), "red": Color("#ff5b5b"), "neutral": Color("#ffd166")}
## 渲染层：1 = 地图等静态物体；动态单位按“哪队看得见”放在 2（蓝）/ 3（红）层，分屏时每个镜头只看自己队伍的层
const TEAM_BIT := {"blue": 2, "red": 4}


class LocalPlayer:
	extends RefCounted
	var ham: SimHamster
	var team := "blue"
	var cam: GameCamera
	var input: PlayerInput
	var hud: Hud
	var vp: SubViewport
	var box: SubViewportContainer
	var dead_time := 0.0
	var last_alive := Vector3.ZERO

var world: SimWorld
var local: SimHamster
var local_team := "blue"
var map_view: MapView
var fx: FxSystem
var wfx: WorldFx
var cam: GameCamera
var hud: Hud
var input := PlayerInput.new()
var env: WorldEnvironment
var listener: AudioListener3D
var moon: DirectionalLight3D
var ham_views := {}
var minion_views := {}
var struct_views := {}
var prop_views := {}
var crate_views := {}
var autoplay := false          # 截图/录屏时让本地玩家也由 AI 控制
var hitstop := 0.0
var time_scale := 1.0
var _over_handled := false
var _t := 0.0
var _mouse := Vector2.ZERO
var _cfg := {}
var paused := false
var players: Array = []          # LocalPlayer（本地玩家，分屏时两个）
var split := false
var split_layer: CanvasLayer


func start(cfg: Dictionary) -> void:
	_cfg = cfg
	PlayerInput.ensure_actions()
	world = SimWorld.new()
	world.setup(cfg)
	autoplay = bool(cfg.get("autoplay", false))
	var pcfg: Array = cfg.get("players", [])
	var pi := 0
	for h in world.hams:
		if h.ctl == "player":
			var pl := LocalPlayer.new()
			pl.ham = h
			pl.team = h.team
			pl.input = PlayerInput.new() if pi > 0 else input
			var pc: Dictionary = pcfg[pi] if pi < pcfg.size() else {}
			pl.input.scheme = String(pc.get("input", "kbm"))
			pl.input.pad_index = int(pc.get("pad", 0))
			players.append(pl)
			pi += 1
	if not players.is_empty():
		local = players[0].ham
		local_team = local.team
	split = players.size() > 1
	if split:
		var p2: LocalPlayer = players[1]
		players[0].input.allow_pad = p2.input.scheme != "pad"
		players[0].input.arrows = p2.input.scheme != "keys2"
	if local != null and autoplay:
		for pl in players:
			pl.ham.ctl = "ai"
			pl.ham.ai = SimHamster.AiState.new()
			pl.ham.ai.lane = "mid"
	_setup_env()
	map_view = MapView.new()
	map_view.name = "Map"
	add_child(map_view)
	map_view.build(world.map, int(cfg.get("seed", 1)))
	fx = FxSystem.new()
	fx.name = "Fx"
	add_child(fx)
	fx.fx_scale = Settings.fx_strength
	fx.on_shell_tink = func(p: Vector3, red: bool) -> void: Audio.play3d("tink", p, -14.0 if red else -10.0, 0.1, 0.04)
	wfx = WorldFx.new()
	wfx.name = "WorldFx"
	wfx.fx = fx
	wfx.mv = self
	add_child(wfx)
	if split:
		_setup_split()
		fx.set_number_scale(0.75)
	else:
		cam = GameCamera.new()
		cam.name = "Camera"
		add_child(cam)
		cam.current = true
		cam.cull_mask = 1 | int(TEAM_BIT.get(local_team, 2))
		if not players.is_empty():
			players[0].cam = cam
	listener = AudioListener3D.new()
	listener.name = "Listener"
	add_child(listener)
	listener.make_current()
	for c in _cams():
		c.bounds = Rect2(world.map.min_x * 0.01, world.map.min_y * 0.01, (world.map.max_x - world.map.min_x) * 0.01, (world.map.max_y - world.map.min_y) * 0.01)
	fx.camera = cam
	for s in world.structs:
		var v := UnitViews.StructureView.new()
		add_child(v)
		v.setup(s)
		struct_views[s.id] = v
	for p in world.props:
		var v := UnitViews.PropView.new()
		add_child(v)
		v.setup(p)
		prop_views[p.id] = v
	for h in world.hams:
		_make_ham_view(h)
	if players.is_empty():
		var focus := world.hams[0]
		cam.snap(Vector3(focus.x * 0.01, 0, focus.y * 0.01))
		cam.cull_mask = 1 | 2 | 4
	for pl in players:
		pl.cam.snap(Vector3(pl.ham.x * 0.01, 0, pl.ham.y * 0.01))
		pl.hud = Hud.new()
		pl.hud.name = "Hud"
		if split:
			pl.vp.add_child(pl.hud)
		else:
			add_child(pl.hud)
		pl.hud.setup(self, pl.ham, pl.cam, pl.input, split)
	if players.is_empty():
		hud = Hud.new()
		hud.name = "Hud"
		add_child(hud)
		hud.setup(self)
	else:
		hud = players[0].hud
	Audio.play_ambience(true)


func _setup_split() -> void:
	## 本地 2 人分屏：左右两个子视口共用同一个 3D 世界，各有自己的镜头和界面
	split_layer = CanvasLayer.new()
	split_layer.layer = 0
	add_child(split_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_layer.add_child(root)
	for i in players.size():
		var pl: LocalPlayer = players[i]
		var box := SubViewportContainer.new()
		box.stretch = true
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.anchor_left = 0.5 * i
		box.anchor_right = 0.5 * (i + 1)
		box.anchor_top = 0.0
		box.anchor_bottom = 1.0
		box.offset_left = 2.0 if i == 1 else 0.0
		box.offset_right = -2.0 if i == 0 else 0.0
		root.add_child(box)
		var vp := SubViewport.new()
		vp.handle_input_locally = false
		vp.audio_listener_enable_3d = false
		vp.msaa_3d = get_viewport().msaa_3d
		vp.screen_space_aa = get_viewport().screen_space_aa
		vp.scaling_3d_scale = get_viewport().scaling_3d_scale
		box.add_child(vp)
		var c := GameCamera.new()
		c.name = "Camera%d" % i
		c.view_width = GameCamera.VIEW_WIDTH * 0.7
		vp.add_child(c)
		c.current = true
		c.cull_mask = 1 | int(TEAM_BIT.get(pl.team, 2))
		pl.cam = c
		pl.vp = vp
		pl.box = box
	var div := ColorRect.new()
	div.color = Color(0.05, 0.03, 0.08)
	div.anchor_left = 0.5
	div.anchor_right = 0.5
	div.anchor_bottom = 1.0
	div.offset_left = -2.0
	div.offset_right = 2.0
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(div)
	cam = players[0].cam
	get_viewport().disable_3d = true


func _cams() -> Array:
	var out: Array = []
	for pl in players:
		out.append(pl.cam)
	if out.is_empty() and cam != null:
		out.append(cam)
	return out


func player_of(id: int) -> LocalPlayer:
	for pl in players:
		if pl.ham.id == id:
			return pl
	return null


func is_local_id(id: int) -> bool:
	return player_of(id) != null


func hud_of(id: int) -> Hud:
	var pl := player_of(id)
	return pl.hud if pl != null else null


func vis_mask(e: SimEntity) -> int:
	## 这个单位对哪些本地玩家的队伍可见（渲染层位）
	if players.is_empty():
		return 2 | 4
	var m := 0
	for pl in players:
		var bit := int(TEAM_BIT.get(pl.team, 2))
		if e.team == pl.team or world.vis[pl.team].has(e.id):
			m |= bit
	return m


static func apply_mask(n: Node, mask: int) -> void:
	## 把一个表现节点（及子节点里所有几何体）放到指定渲染层；只在变化时遍历
	if n == null or int(n.get_meta("vis_mask", -1)) == mask:
		return
	n.set_meta("vis_mask", mask)
	var layers := maxi(mask, 1 << 19) if mask == 0 else mask
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).layers = layers
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).layers = layers
	# 点光 / 聚光（手电、枪口光）也按相机的渲染层过滤：分屏对打时，看不见的敌人的手电不会照亮另一边的画面
	for l in n.find_children("*", "Light3D", true, false):
		if not l is DirectionalLight3D:
			(l as Light3D).layers = layers


func _setup_env() -> void:
	env = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.035, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.40, 0.34, 0.62)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	e.glow_enabled = true
	e.glow_intensity = 0.55
	e.glow_strength = 1.0
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = 1.15
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.08
	e.adjustment_contrast = 1.04
	env.environment = e
	add_child(env)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color(0.55, 0.62, 1.0)
	moon.light_energy = 0.32
	moon.rotation_degrees = Vector3(-62, -35, 0)
	moon.shadow_enabled = true
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	moon.directional_shadow_max_distance = 22.0
	moon.light_specular = 0.0
	add_child(moon)


func _make_ham_view(h: SimHamster) -> void:
	var v := HamsterView.new()
	add_child(v)
	v.setup(h, is_local_id(h.id if h != null else -1))
	ham_views[h.id] = v


func team_sees(e: SimEntity) -> bool:
	if players.size() > 1:
		return vis_mask(e) != 0
	return e.team == local_team or world.vis[local_team].has(e.id)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_mouse = (ev as InputEventMouseMotion).position
		input.device = "kbm"
	elif ev is InputEventMouseButton:
		_mouse = (ev as InputEventMouseButton).position
		input.device = "kbm"
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and local != null and not local.choices.is_empty():
			var i := hud.card_at(mb.position)
			if i >= 0:
				local.inp.card = i
				get_viewport().set_input_as_handled()
	if ev.is_action_pressed("pause"):
		pause_requested.emit()
	elif ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_START:
		pause_requested.emit()


func _physics_process(dt: float) -> void:
	if world == null or paused:
		return
	if hitstop > 0.0:
		hitstop -= dt
		return
	if local != null and not autoplay:
		for pl in players:
			var mp := get_viewport().get_mouse_position()
			if split:
				mp = pl.box.get_local_mouse_position()
			pl.input.poll(pl.ham, pl.cam, mp, not pl.ham.choices.is_empty(), world)
	var steps := 1
	if time_scale < 1.0:
		# 慢动作：按比例跳过逻辑帧
		_t += time_scale
		steps = int(_t)
		_t -= steps
	for i in steps:
		world.step(dt)
	_dispatch(world.drain_events())
	if world.over and not _over_handled:
		_over_handled = true
		time_scale = 0.35
		for id in ham_views:
			var h := world.ham_by_id(id)
			if h != null and h.team == world.winner:
				(ham_views[id] as HamsterView).set_victory(true)
		var any_win := false
		for pl in players:
			any_win = any_win or pl.team == world.winner
		Audio.play2d("win" if any_win or players.is_empty() else "lose", -4.0, 0.0, 1.0)
	if world.over and world.end_t <= 0.0 and time_scale < 1.0:
		time_scale = 1.0
		finished.emit(world.winner, _stats())


func _process(delta: float) -> void:
	if world == null:
		return
	var alpha := Engine.get_physics_interpolation_fraction()
	if hitstop > 0.0 or paused:
		alpha = 1.0
	for h in world.hams:
		if not ham_views.has(h.id):
			_make_ham_view(h)
		var hvw: HamsterView = ham_views[h.id]
		hvw.frozen = h.frozen_until > world.t
		var hm := vis_mask(h)
		hvw.sync(h, alpha, delta, hm != 0)
		apply_mask(hvw, hm)
		if hvw.visible and h.alive:
			var hp := Vector3(h.x * 0.01, h.z * 0.01, h.y * 0.01)
			if h.burn_t > 0.0 and randf() < 0.45:
				fx.burn(hp + Vector3(0, 0.1, 0))
			if h.stun_t > 0.0 and randf() < delta * 8.0:
				fx.spawn(hp + Vector3(randf_range(-0.1, 0.1), h.r * 0.024, randf_range(-0.1, 0.1)), Vector3(0, 0.2, 0), 0.4, 0.06, Color("#ffd166"), FxSystem.S_STAR, true, 0.0, 0.0)
			if h.med_t > 0.0 and randf() < delta * 6.0:
				fx.spawn(hp + Vector3(randf_range(-0.12, 0.12), randf_range(0.2, 0.4), randf_range(-0.12, 0.12)), Vector3(0, 0.5, 0), 0.6, 0.06, Color("#8de0a6"), FxSystem.S_STAR, true, 0.0, 0.0)
			if h.jet_t > 0.0:
				var back := Vector3(-cos(h.aim), 0, -sin(h.aim)) * h.r * 0.008
				for k in 2:
					fx.spawn(hp + back + Vector3(randf_range(-0.04, 0.04), h.r * 0.012, randf_range(-0.04, 0.04)), Vector3(randf_range(-0.2, 0.2), randf_range(-1.2, -0.6), randf_range(-0.2, 0.2)), 0.25, randf_range(0.08, 0.12), Color(1.0, 0.6, 0.2), FxSystem.S_CIRCLE, true, 0.0, 1.0, -0.2)
			if float(h.st.get("regen", 0.0)) > 0.0 and h.hp < h.max_hp and randf() < delta * 3.0:
				fx.spawn(hp + Vector3(randf_range(-0.14, 0.14), randf_range(0.1, 0.34), randf_range(-0.14, 0.14)), Vector3(0, 0.3, 0), 0.6, 0.04, Color("#8de0a6"), FxSystem.S_STAR, true, 0.0, 0.0)
			if float(h.st.get("aura", 0.0)) > 0.0 and randf() < delta * 0.8:
				fx.ring(hp + Vector3(0, 0.03, 0), 0.2, 2.2, 0.9, Color("#8de0a6"), 0.12)
			if int(h.ab.get("dash", 0)) > 0 and h.roll_t > 0.0:
				fx.spawn(hp + Vector3(randf_range(-0.1, 0.1), randf_range(0.05, 0.3), randf_range(-0.1, 0.1)), Vector3(-h.rdx, 0, -h.rdy) * 2.0, 0.15, 0.03, Color.WHITE, FxSystem.S_STREAK, true, 0.0, 1.0, 0.0, false, 0.6)
			if int(h.ab.get("frost", 0)) > 0 and randf() < delta * 2.0:
				fx.spawn(hp + Vector3(cos(h.aim), 0, sin(h.aim)) * 0.3 + Vector3(0, 0.18, 0), Vector3(0, 0.1, 0), 0.5, 0.035, Color("#cfefff"), FxSystem.S_STAR, true, 0.0, 0.0)
			if h.haste_t > 0.0 and randf() < delta * 10.0:
				fx.spawn(hp + Vector3(randf_range(-0.12, 0.12), randf_range(0.05, 0.3), randf_range(-0.12, 0.12)), Vector3(-h.vx, 0, -h.vy) * 0.004, 0.25, 0.03, Color("#ffd166"), FxSystem.S_STREAK, true, 0.0, 1.0, 0.0, false, 0.6)
	var alive_ids := {}
	for m in world.minions:
		alive_ids[m.id] = true
		if not minion_views.has(m.id):
			var mv := UnitViews.MinionView.new()
			add_child(mv)
			mv.setup(m)
			minion_views[m.id] = mv
		var mm := vis_mask(m)
		(minion_views[m.id] as UnitViews.MinionView).sync(m, alpha, delta, mm != 0)
		apply_mask(minion_views[m.id], mm)
	for m in world.minions:
		if m.stun > 0.0 and minion_views.has(m.id) and (minion_views[m.id] as Node3D).visible and randf() < delta * 6.0:
			fx.spawn(Vector3(m.x * 0.01, 0.3, m.y * 0.01), Vector3(0, 0.2, 0), 0.4, 0.05, Color("#ffd166"), FxSystem.S_STAR, true, 0.0, 0.0)
	for id in minion_views.keys():
		if not alive_ids.has(id):
			(minion_views[id] as Node).queue_free()
			minion_views.erase(id)
	for s in world.structs:
		if struct_views.has(s.id):
			(struct_views[s.id] as UnitViews.StructureView).sync(s, delta)
	for p in world.props:
		(prop_views[p.id] as UnitViews.PropView).sync(p, delta)
	alive_ids.clear()
	for c in world.crates:
		alive_ids[c.id] = true
		if not crate_views.has(c.id):
			var cv := UnitViews.CrateView.new()
			add_child(cv)
			cv.setup(c)
			crate_views[c.id] = cv
		(crate_views[c.id] as UnitViews.CrateView).sync(c, delta)
	for id in crate_views.keys():
		if not alive_ids.has(id):
			(crate_views[id] as Node).queue_free()
			crate_views.erase(id)
	for i in map_view.pad_tops.size():
		var pt: Dictionary = map_view.pad_tops[i]
		if pt.node and i < world.map.pads.size():
			var k := float(world.map.pads[i].anim) / 0.35
			(pt.node as Node3D).position.y = float(pt.base_y) + sin(k * PI) * 0.18 * k
	# 镜头（每个本地玩家一个）
	if players.is_empty():
		var f0 := world.hams[0]
		var fp0 := Vector3(lerpf(f0.px, f0.x, alpha) * 0.01, 0, lerpf(f0.py, f0.y, alpha) * 0.01)
		cam.update(delta, fp0, fp0 + Vector3(cos(f0.aim), 0, sin(f0.aim)) * 3.0, f0.alive)
		listener.global_transform = Transform3D(cam.global_transform.basis, fp0 + Vector3(0, 1.2, 0))
	for pl in players:
		var focus: SimHamster = pl.ham
		var fpos := Vector3(lerpf(focus.px, focus.x, alpha) * 0.01, 0, lerpf(focus.py, focus.y, alpha) * 0.01)
		if focus.alive:
			pl.dead_time = 0.0
			pl.last_alive = fpos
		else:
			# 倒下后先在倒下的地方停 1.8 秒（看清是谁打的），再慢慢移到己方鼠窝门口（门朝向敌方，往外多看一点兵线）
			pl.dead_time += delta
			fpos = pl.last_alive
			if pl.dead_time > 1.8:
				var b: Vector2 = world.map.base_pos[focus.team]
				fpos = Vector3(b.x * 0.01 + (3.6 if focus.team == "blue" else -3.6), 0, b.y * 0.01)
		var aim_pt := fpos + Vector3(cos(focus.aim), 0, sin(focus.aim)) * 3.0
		if pl.input.device == "kbm" and not autoplay and focus.inp.has_aim_point:
			aim_pt = Vector3(focus.inp.aim_x * 0.01, 0, focus.inp.aim_y * 0.01)
		pl.cam.update(delta, fpos, aim_pt, focus.alive)
		if pl == players[0]:
			# 听者放在角色头顶（不是 10 米高的镜头上），否则所有 3D 音效都像隔得很远；朝向沿用镜头，左右声道和画面一致
			listener.global_transform = Transform3D(pl.cam.global_transform.basis, fpos + Vector3(0, 1.2, 0))
	fx.sync_tracers(world.bullets, alpha, cam.global_transform.basis, func(b, _p): return true)
	fx.sync_items(world.items, alpha, Time.get_ticks_msec() / 1000.0)
	fx.sync_lobs(world.lobs)
	wfx.sync(world, alpha, delta, cam.global_transform.basis)
	fx.update(delta)
	if players.is_empty():
		hud.refresh(delta)
	for pl in players:
		pl.hud.refresh(delta)


# ---------------------------------------------------------------------------
# 事件
# ---------------------------------------------------------------------------

func _wpos(x: float, y: float, h: float = 0.0) -> Vector3:
	return Vector3(x * 0.01, h * 0.01, y * 0.01)


func _near_local(p: Vector3, r: float = 9.0) -> float:
	var f := local if local != null else world.hams[0]
	var d := p.distance_to(Vector3(f.x * 0.01, 0, f.y * 0.01))
	return clampf(1.0 - d / r, 0.0, 1.0)


func _dispatch(events: Array) -> void:
	for ev: Dictionary in events:
		var t := String(ev.t)
		match t:
			"fire":
				_on_fire(ev)
			"minion_fire":
				var mv: UnitViews.MinionView = minion_views.get(ev.id)
				if mv:
					mv.on_fire()
				var p := _wpos(float(ev.x), float(ev.y), 14.0) + Vector3(cos(float(ev.aim)), 0, sin(float(ev.aim))) * 0.16
				if mv and mv.visible:
					fx.spawn(p, Vector3.ZERO, 0.05, 0.1, Color(1, 0.95, 0.75), FxSystem.S_STAR, true, 0, 0)
				Audio.play3d("shot_minion", p, -14.0, 0.1, 0.05)
			"struct_fire":
				var sv: UnitViews.StructureView = struct_views.get(ev.id)
				if sv:
					sv.on_fire()
				var p2 := _wpos(float(ev.x), float(ev.y), float(ev.h))
				if String(ev.kind) == "sentry":
					wfx.sentry_fired(int(ev.id))
					fx.spawn(p2, Vector3.ZERO, 0.04, 0.12, Color("#fff6c2"), FxSystem.S_STAR, true, 0, 0)
					Audio.play3d("shot_sentry", p2, -10.0, 0.08, 0.05)
				else:
					fx.spawn(p2, Vector3.ZERO, 0.07, 0.35, TEAM_COL[String(ev.team)], FxSystem.S_STAR, true, 0, 0)
					fx.flash_light(p2, TEAM_COL[String(ev.team)], 2.0, 2.5, 0.08)
					Audio.play3d("shot_turret", p2, -6.0, 0.05, 0.05)
			"bullet_hit":
				var p3 := _wpos(float(ev.x), float(ev.y), float(ev.h))
				var c := Color("#bfe0ff") if ev.team == "blue" else (Color("#ffc8c8") if ev.team == "red" else Color("#ffb3e6"))
				fx.hit(p3, c, bool(ev.big))
				Audio.play3d("hit", p3, -10.0, 0.1, 0.03)
			"wall_hit":
				var p4 := _wpos(float(ev.x), float(ev.y), float(ev.h))
				fx.wall_hit(p4, Color("#ffe2a8"))
				Audio.play3d("wall_hit", p4, -16.0, 0.12, 0.05)
			"ricochet":
				Audio.play3d("ricochet", _wpos(float(ev.x), float(ev.y)), -10.0)
			"damage":
				_on_damage(ev)
			"hitmark":
				var hh := hud_of(int(ev.id))
				if hh != null:
					hh.hitmark(bool(ev.kill))
					Audio.play2d("hitmark", -8.0, 0.05, 0.03)
			"kill":
				_on_kill(ev)
			"explode":
				var p5 := _wpos(float(ev.x), float(ev.y))
				var r := float(ev.r) * 0.01
				if bool(ev.get("mini", false)):
					fx.hit(p5 + Vector3(0, 0.15, 0), Color(1, 0.7, 0.3), true)
				else:
					fx.explosion(p5, r, bool(ev.big))
					Audio.play3d("boom_big" if bool(ev.big) else "boom_small", p5, 0.0, 0.08, 0.05)
					cam.add_trauma(0.45 * _near_local(p5, 12.0) * Settings.fx_strength)
					hitstop = maxf(hitstop, 0.035 * _near_local(p5, 6.0))
			"reload":
				var hv2: HamsterView = ham_views.get(ev.id)
				if hv2:
					hv2.on_event(ev)
				var h2 := world.ham_by_id(int(ev.id))
				var cls: String = HamsterView.CLASS_OF.get(String(ev.weapon), "pistol")
				if h2 != null:
					Audio.play3d("reload_" + String(HamsterView.RELOAD_SND.get(cls, "pistol")), _wpos(h2.x, h2.y, 20.0), -6.0 if is_local_id(h2.id if h2 != null else -1) else -12.0, 0.0, 0.1)
				if h2 != null and is_local_id(h2.id):
					hud_of(h2.id).toast_reload()
			"empty":
				if is_local_id(int(ev.id)):
					Audio.play2d("empty", -6.0)
			"dash":
				var hv3: HamsterView = ham_views.get(ev.id)
				if hv3:
					hv3.on_event(ev)
				var p6 := _wpos(float(ev.x), float(ev.y))
				if hv3 and hv3.visible:
					fx.dust(p6, Vector3(float(ev.dx), 0, float(ev.dy)), 6)
				Audio.play3d("roll", p6, -8.0)
			"launch":
				var h3 := world.ham_by_id(int(ev.id))
				if h3:
					Audio.play3d("boing", _wpos(h3.x, h3.y), -4.0)
					fx.ring(_wpos(h3.x, h3.y, 3), 0.1, 2.0, 0.35, Color("#ffd166"), 0.25)
			"land":
				var hv4: HamsterView = ham_views.get(ev.id)
				if hv4:
					hv4.on_event(ev)
				var p7 := _wpos(float(ev.x), float(ev.y))
				fx.ring(p7 + Vector3(0, 0.03, 0), 0.1, 2.2, 0.35, Color("#ffe2a8"), 0.3)
				fx.dust(p7, Vector3.ZERO, 10, 2.0)
				Audio.play3d("thud", p7, -3.0)
				cam.add_trauma(0.3 * _near_local(p7, 6.0))
			"throw":
				var h4 := world.ham_by_id(int(ev.id))
				if h4:
					Audio.play3d("throw", _wpos(h4.x, h4.y), -6.0)
			"lob_bounce":
				Audio.play3d("clank", _wpos(float(ev.x), float(ev.y)), -10.0, 0.1, 0.06)
			"levelup":
				var hv5: HamsterView = ham_views.get(ev.id)
				if hv5:
					hv5.on_event(ev)
				var h5 := world.ham_by_id(int(ev.id))
				if h5 and team_sees(h5):
					var p8 := _wpos(h5.x, h5.y, 30)
					fx.stars(p8, Color("#ffe27a"), 10)
					fx.ring(_wpos(h5.x, h5.y, 3), 0.16, 2.2, 0.4, Color("#ffd166"), 0.3)
				if is_local_id(h5.id if h5 != null else -1):
					Audio.play2d("levelup", -3.0, 0.0)
			"choices":
				if is_local_id(int(ev.id)):
					Audio.play2d("card_appear", -6.0, 0.0)
					hud_of(int(ev.id)).show_cards()
			"picked":
				var hv6: HamsterView = ham_views.get(ev.id)
				if hv6:
					hv6.on_event(ev)
				var h6 := world.ham_by_id(int(ev.id))
				if h6 and team_sees(h6):
					var col := Color(String(ev.label.get("pathColor", "#ffd166")))
					fx.stars(_wpos(h6.x, h6.y, 30), col, 10)
					fx.ring(_wpos(h6.x, h6.y, 3), 0.16, 1.8, 0.35, col, 0.3)
				if h6 != null and is_local_id(h6.id):
					Audio.play2d("card_pick", -4.0, 0.0)
					hud_of(h6.id).cards_picked()
			"gem":
				var hv7: HamsterView = ham_views.get(ev.id)
				if hv7:
					hv7.on_event(ev)
				var h7 := world.ham_by_id(int(ev.id))
				if is_local_id(h7.id if h7 != null else -1):
					Audio.play2d("munch", -10.0, 0.15, 0.04)
			"cheese":
				var h8 := world.ham_by_id(int(ev.id))
				if h8:
					fx.ring(_wpos(h8.x, h8.y, 3), 0.16, 1.2, 0.3, Color("#8de0a6"), 0.3)
					Audio.play3d("munch", _wpos(h8.x, h8.y), -4.0)
			"prop_hit":
				var p9 := _wpos(float(ev.x), float(ev.y), 40)
				if String(ev.kind) == "box":
					fx.small_death(p9, Color("#c89359"), 2)
			"prop_break":
				var p10 := _wpos(float(ev.x), float(ev.y))
				match String(ev.kind):
					"lamp":
						Audio.play3d("glass", p10, -2.0)
						fx.stars(p10 + Vector3(0, 0.6, 0), Color("#fff1c0"), 10, 1.6)
						fx.flash_light(p10 + Vector3(0, 0.6, 0), Color(1, 0.9, 0.7), 3.0, 4.0, 0.15)
					"box":
						Audio.play3d("crate_open", p10, -2.0)
						fx.small_death(p10 + Vector3(0, 0.2, 0), Color("#c89359"), 18)
						fx.dust(p10, Vector3.ZERO, 8, 1.5)
			"prop_respawn":
				pass
			"respawn":
				var hv8: HamsterView = ham_views.get(ev.id)
				if hv8:
					hv8.on_event(ev)
				var p11 := _wpos(float(ev.x), float(ev.y))
				fx.ring(p11 + Vector3(0, 0.03, 0), 0.1, 2.0, 0.4, TEAM_COL[String(ev.team)], 0.3)
				Audio.play3d("respawn", p11, -4.0)
			"toast":
				for pl in players:
					pl.hud.toast(int(ev.id), String(ev.text), Color(String(ev.color)), float(ev.dur))
				if players.is_empty():
					hud.toast(int(ev.id), String(ev.text), Color(String(ev.color)), float(ev.dur))
			"feed":
				for pl in players:
					pl.hud.feed(String(ev.text), Color(String(ev.color)))
				if players.is_empty():
					hud.feed(String(ev.text), Color(String(ev.color)))
			"pop":
				fx.number(_wpos(float(ev.x), float(ev.y), float(ev.h)), String(ev.text), Color(String(ev.color)), float(ev.get("size", 15)) / 15.0)
			"shield_block":
				var h9 := world.ham_by_id(int(ev.id))
				if h9:
					fx.ring(_wpos(h9.x, h9.y, 20), 0.12, 1.2, 0.25, Color("#9fe8ff"), 0.3)
			"base_shield":
				fx.hit(_wpos(float(ev.x), float(ev.y), 60), Color("#9fe8ff"), false)
			"blind":
				if is_local_id(int(ev.id)):
					hud_of(int(ev.id)).flash_white(float(ev.amount))
			_:
				_dispatch_b2(t, ev)


func _on_damage(ev: Dictionary) -> void:
	var id := int(ev.id)
	var e: SimEntity = world.entities.get(id)
	var p := _wpos(float(ev.x), float(ev.y), float(ev.r) * 2.4 + 12.0)
	var seen := e == null or team_sees(e)
	if e is SimHamster:
		var hv: HamsterView = ham_views.get(id)
		if hv:
			hv.on_event(ev)
		if is_local_id(id):
			var pl := player_of(id)
			pl.hud.hurt_pulse()
			pl.cam.add_trauma(0.2 * Settings.fx_strength)
			Audio.play2d("hurt", -6.0, 0.08, 0.08)
		elif seen and not bool(ev.quiet):
			Audio.play3d("hurt", p, -10.0, 0.1, 0.1)
	if seen and Settings.show_damage_numbers and (not bool(ev.quiet) or bool(ev.crit)):
		var amt := int(round(float(ev.amount)))
		if amt <= 0:
			return
		var crit := bool(ev.crit)
		var col := Color("#ffd166") if crit else (Color("#ff8a8a") if String(ev.kind) == "ham" else Color("#ffffff"))
		var by_local := is_local_id(int(ev.get("by", -1)))
		if not by_local and e != local and String(ev.kind) != "ham":
			col = col.darkened(0.25)
		fx.number(p, ("暴击 " if crit else "") + str(amt), col, 1.25 if crit else 0.9)


func _on_kill(ev: Dictionary) -> void:
	var p := _wpos(float(ev.x), float(ev.y))
	var team := String(ev.team)
	match String(ev.kind):
		"ham":
			var h := world.ham_by_id(int(ev.id))
			var fur := Color("#f2a54a")
			if h:
				fur = Color(String(Data.skins().get(h.skin, {}).get("fur", "#f2a54a")))
			fx.death_burst(p, TEAM_COL.get(team, Color.WHITE), fur)
			Audio.play3d("death", p, -2.0)
			var involves_local := is_local_id(int(ev.id)) or is_local_id(int(ev.killer))
			if involves_local:
				hitstop = maxf(hitstop, 0.07)
				cam.add_trauma(0.35 * Settings.fx_strength)
		"minion":
			fx.small_death(p, TEAM_COL.get(team, Color.WHITE), 8)
			Audio.play3d("hit", p, -8.0)
		"crate":
			fx.small_death(p + Vector3(0, 0.15, 0), Color("#ff8a3d") if not bool(ev.get("big", false)) else Color("#ffcf3a"), 14)
			fx.stars(p + Vector3(0, 0.3, 0), Color("#ffe27a"), 6, 0.8)
			Audio.play3d("crate_open", p, -2.0)
		"turret", "base":
			hitstop = maxf(hitstop, 0.08)
		"roach":
			fx.small_death(p, Color("#7a4a22"), 12)
			fx.scorch(p, 0.18)
			Audio.play3d("skitter", p, -6.0, 0.15, 0.1)
		"rat":
			fx.death_burst(p, Color("#c9cbd4"), Color("#8a8796"))
			Audio.play3d("squeak", p, -4.0, 0.1, 0.1)
		"boss":
			fx.explosion(p, 2.4, true)
			fx.death_burst(p, Color("#ffd166"), Color("#6d6070"))
			Audio.play3d("boss_roar", p, 0.0, 0.0, 0.0)
			Audio.play2d("fanfare", -6.0, 0.0)
			hitstop = maxf(hitstop, 0.12)
			cam.add_trauma(0.6 * Settings.fx_strength)
		"sentry":
			fx.small_death(p, TEAM_COL.get(team, Color.WHITE), 10)
			Audio.play3d("clank", p, -6.0)
		"decoy":
			fx.small_death(p + Vector3(0, 0.2, 0), TEAM_COL.get(team, Color.WHITE), 12)
			fx.ring(p + Vector3(0, 0.03, 0), 0.1, 1.6, 0.25, Color.WHITE, 0.25)
			fx.number(p + Vector3(0, 0.5, 0), "噗！", Color.WHITE, 1.1)
			Audio.play3d("boing", p, -4.0)


func _on_fire(ev: Dictionary) -> void:
	var hv: HamsterView = ham_views.get(ev.id)
	if hv:
		hv.on_event(ev)
	var h := world.ham_by_id(int(ev.id))
	var wid := String(ev.weapon)
	var W := Data.weapon(wid)
	var kind := String(ev.get("kind", "bullet"))
	var aim := float(ev.aim)
	var dir := Vector3(cos(aim), 0, sin(aim))
	var mpos := _wpos(float(ev.gx), float(ev.gy), float(ev.gh))
	if hv and hv.weapon_node:
		var mz := hv.muzzle_node(int(ev.get("side", 0)))
		if mz:
			mpos = mz.global_position
	var seen := h == null or team_sees(h)
	var vol := -2.0 if is_local_id(h.id if h != null else -1) else -5.0
	match kind:
		"melee":
			Audio.play3d("swish", mpos, vol, 0.12, 0.08)
			if is_local_id(h.id if h != null else -1):
				player_of(h.id).cam.add_trauma(0.08 * Settings.fx_strength)
			return
		"flame":
			if seen and randf() < 0.3:
				fx.flash_light(mpos, Color(1.0, 0.6, 0.25), 1.6, 2.4, 0.08)
			if Audio.has("flame"):
				Audio.play3d("flame", mpos, vol - 4.0, 0.1, 0.1)
			return
		"rail":
			return
	if seen:
		fx.muzzle(mpos, dir, W)
		var sh: Variant = W.get("fx", {}).get("sh")
		if sh is String and sh != "":
			fx.eject_shell(mpos - dir * 0.12, dir.cross(Vector3.UP) * -1.0, dir, sh == "red")
		if kind == "rocket":
			for i in fx._n(6):
				fx.spawn(mpos - dir * 0.25, -dir * randf_range(0.8, 2.0) + Vector3(randf_range(-0.3, 0.3), randf_range(0.1, 0.4), randf_range(-0.3, 0.3)), randf_range(0.5, 0.9), randf_range(0.1, 0.16), Color(0.6, 0.58, 0.67, 0.8), FxSystem.S_SMOKE, false, -0.2, 2.0, 0.34)
		if bool(ev.get("dragon", false)):
			for i in 3:
				fx.burn(mpos + dir * 0.1)
		if float(ev.get("trail", 0.0)) > 0.0:
			var L := float(ev.trail) * 0.01
			wfx.add_beam(mpos, mpos + dir * L, 0.05 if wid == "sniper" else 0.08, Color("#bff4ff"), 0.9, 0.9)
			for i in fx._n(6):
				fx.spawn(mpos + dir * randf() * L, Vector3(0, 0.1, 0), randf_range(0.6, 1.0), randf_range(0.05, 0.09), Color(0.75, 0.75, 0.82, 0.5), FxSystem.S_SMOKE, false, -0.1, 1.0, 0.1)
	var snd := "shot_" + (String(W.snd) if W.get("snd") is String else wid)
	if not Audio.has(snd):
		snd = "shot_" + wid
	Audio.play3d(snd if Audio.has(snd) else "shot_pistol", mpos, vol, 0.05, 0.0)
	if wid == "shotgun":
		get_tree().create_timer(0.3).timeout.connect(func(): Audio.play3d("pump", mpos, -6.0))
	elif bool(W.get("bolt", false)):
		get_tree().create_timer(0.38).timeout.connect(func(): Audio.play3d("bolt", mpos, -6.0))
	if is_local_id(h.id if h != null else -1):
		var F: Dictionary = W.get("fx", {})
		var pc := player_of(h.id).cam
		pc.add_trauma(float(F.get("shk", 0.06)) * Settings.fx_strength)
		pc.add_kick(dir, float(F.get("kick", 3.0)) * 0.008)


func _dispatch_b2(t: String, ev: Dictionary) -> void:
	## 批次 2 新事件：道具、新武器、野怪、宠物
	match t:
		"gadget":
			var hv: HamsterView = ham_views.get(ev.id)
			if hv:
				hv.on_event(ev)
			var h := world.ham_by_id(int(ev.id))
			if h == null:
				return
			var p := _wpos(h.x, h.y, 20)
			match String(ev.gadget):
				"eshield":
					Audio.play3d("shield_up", p, -2.0)
					fx.ring(p, 0.1, 1.6, 0.4, Color("#7fe3ff"), 0.3)
				"medkit":
					Audio.play3d("heal", p, -3.0)
				"jetpack":
					Audio.play3d("jet", p, -2.0)
					fx.dust(_wpos(h.x, h.y), Vector3.ZERO, 8, 1.6)
				"mine", "sentry", "beacon":
					Audio.play3d("beep", p, -4.0)
				"decoy":
					Audio.play3d("boing", p, -4.0)
					fx.ring(_wpos(h.x, h.y, 3), 0.08, 1.4, 0.3, TEAM_COL[h.team], 0.3)
				_:
					Audio.play3d("throw", p, -6.0)
		"teleport":
			for k in 2:
				var x := float(ev.x0) if k == 0 else float(ev.x1)
				var y := float(ev.y0) if k == 0 else float(ev.y1)
				var p2 := _wpos(x, y, 3)
				fx.ring(p2, 0.03, 2.4, 0.4, Color("#7fe3ff"), 0.3)
				fx.stars(p2 + Vector3(0, 0.2, 0), Color("#9fe8ff"), 14, 1.6)
				fx.flash_light(p2 + Vector3(0, 0.3, 0), Color("#9fe8ff"), 2.0, 3.0, 0.2)
			Audio.play3d("teleport", _wpos(float(ev.x1), float(ev.y1)), -2.0)
		"smoke":
			Audio.play3d("hiss", _wpos(float(ev.x), float(ev.y)), -2.0)
		"flare":
			Audio.play3d("boing", _wpos(float(ev.x), float(ev.y)), -8.0)
		"flashbang":
			var p3 := _wpos(float(ev.x), float(ev.y), 20)
			Audio.play3d("bang", p3, 0.0)
			fx.spawn(p3, Vector3.ZERO, 0.18, 0.7, Color.WHITE, FxSystem.S_STAR, true, 0, 0)
			fx.ring(p3, 0.03, 6.0, 0.35, Color.WHITE, 0.2)
			fx.flash_light(p3 + Vector3(0, 0.4, 0), Color.WHITE, 6.0, 6.0, 0.35)
			cam.add_trauma(0.25 * _near_local(p3, 8.0))
		"freeze":
			var p4 := _wpos(float(ev.x), float(ev.y), 10)
			var r := float(ev.r) * 0.01
			Audio.play3d("freeze", p4, -2.0)
			fx.ring(p4, 0.04, r * 2.2 / 0.35, 0.35, Color("#bfefff"), 0.3)
			for i in fx._n(20):
				var d := fx.rand_dir()
				fx.spawn(p4, d * randf_range(0.6, 2.6) + Vector3(0, randf_range(0.4, 1.6), 0), randf_range(0.4, 0.8), randf_range(0.05, 0.09), Color("#cfefff"), FxSystem.S_STAR, true, 2.5, 2.0)
			fx.flash_light(p4, Color("#bfefff"), 2.0, 3.0, 0.2)
		"molotov":
			var p5 := _wpos(float(ev.x), float(ev.y), 8)
			Audio.play3d("glass", p5, -2.0)
			for i in fx._n(14):
				var d2 := fx.rand_dir()
				fx.spawn(p5, d2 * randf_range(0.6, 2.0) + Vector3(0, randf_range(0.4, 1.2), 0), randf_range(0.3, 0.6), randf_range(0.14, 0.24), Color(1.0, 0.55, 0.15), FxSystem.S_CIRCLE, true, 1.0, 2.0, -0.2)
			fx.flash_light(p5 + Vector3(0, 0.3, 0), Color(1.0, 0.6, 0.25), 1.8, 4.0, 0.4)
		"mine":
			Audio.play3d("beep", _wpos(float(ev.x), float(ev.y)), -8.0)
		"rail_beam":
			var col := Color("#9fe8ff") if String(ev.team) == "blue" else Color("#ff8fc0")
			var ch := float(ev.ch)
			var wd := float(ev.w) * 0.012
			var first := true
			for sg in ev.segs:
				var a := _wpos(float(sg[0]), float(sg[1]), float(ev.h))
				var b := _wpos(float(sg[2]), float(sg[3]), float(ev.h))
				wfx.add_beam(a, b, wd * 2.2, col, 0.4, 0.3)
				wfx.add_beam(a, b, wd * 0.7, Color(1, 1, 1), 0.3, 1.0)
				for i in fx._n(10.0 * ch + 4.0):
					fx.spawn(a.lerp(b, randf()) + Vector3(0, randf_range(-0.04, 0.04), 0), Vector3(randf_range(-0.3, 0.3), randf_range(0.1, 0.5), randf_range(-0.3, 0.3)), randf_range(0.3, 0.6), randf_range(0.04, 0.07), col, FxSystem.S_STAR, true, 0.0, 1.0)
				if first:
					first = false
					fx.spawn(a, Vector3.ZERO, 0.1, 0.26 + 0.2 * ch, Color("#bff4ff"), FxSystem.S_STAR, true, 0, 0)
					fx.flash_light(a + Vector3(0, 0.1, 0), col, 3.5, 3.0, 0.12)
					Audio.play3d("shot_rail", a, 0.0 if is_local_id(int(ev.id)) else -4.0, 0.05, 0.0)
			if is_local_id(int(ev.id)):
				player_of(int(ev.id)).cam.add_trauma((0.15 + 0.3 * ch) * Settings.fx_strength)
		"charge_start":
			var h2 := world.ham_by_id(int(ev.id))
			if h2 and (is_local_id(h2.id if h2 != null else -1) or team_sees(h2)):
				Audio.play3d("charge", _wpos(h2.x, h2.y, 20), -6.0 if is_local_id(h2.id if h2 != null else -1) else -12.0)
		"laser_tick":
			var h3 := world.ham_by_id(int(ev.id))
			if h3 and Time.get_ticks_msec() / 1000.0 - wfx._laser_snd_t > 0.09:
				wfx._laser_snd_t = Time.get_ticks_msec() / 1000.0
				Audio.play3d("shot_laser", _wpos(h3.x, h3.y, 20), -8.0 if is_local_id(h3.id if h3 != null else -1) else -14.0, 0.05, 0.05)
		"swing":
			var h4 := world.ham_by_id(int(ev.id))
			if h4 == null or not team_sees(h4):
				return
			wfx.slash(_wpos(float(ev.x), float(ev.y), float(ev.h)), float(ev.a), float(ev.reach) * 0.01, float(ev.arc), float(ev.dir), Color("#ff9ff0") if bool(ev.big) else Color("#d8f0ff"))
		"melee_hit", "iaido_hit":
			var p6 := _wpos(float(ev.x), float(ev.y), float(ev.h))
			fx.hit(p6, Color("#e8f4ff"), true)
			Audio.play3d("hit", p6, -6.0, 0.1, 0.05)
			if t == "iaido_hit":
				wfx.slash(_wpos(float(ev.x), float(ev.y), float(ev.h)), float(ev.a), 0.4, 1.2, 1.0, Color("#d8f0ff"), 0.15)
		"deflect":
			for pt in ev.pts:
				var pp := _wpos(float(pt[0]), float(pt[1]), float(pt[2]))
				fx.hit(pp, Color("#9fe8ff"), false)
			var p7 := _wpos(float(ev.x), float(ev.y), 20)
			Audio.play3d("ting", p7, -2.0, 0.05, 0.08)
			if bool(ev.perfect):
				fx.ring(p7, 0.16, 2.0, 0.3, Color("#ffd166"), 0.3)
		"bullet_burn":
			fx.hit(_wpos(float(ev.x), float(ev.y), float(ev.h)), Color("#ffb04a"), false)
		"bullet_block":
			fx.hit(_wpos(float(ev.x), float(ev.y), float(ev.h)), Color("#9fe8ff"), false)
			Audio.play3d("tink", _wpos(float(ev.x), float(ev.y)), -10.0, 0.1, 0.05)
		"lob_stick":
			Audio.play3d("clank", _wpos(float(ev.x), float(ev.y)), -6.0)
		"gl_detonate":
			var h5 := world.ham_by_id(int(ev.id))
			if h5:
				Audio.play3d("beep", _wpos(h5.x, h5.y), -4.0)
		"split", "wall_pierce":
			fx.wall_hit(_wpos(float(ev.x), float(ev.y), float(ev.h)), Color("#ffe2a8"))
		"wall_slam":
			var p8 := _wpos(float(ev.x), float(ev.y), 16)
			fx.hit(p8, Color.WHITE, true)
			fx.ring(_wpos(float(ev.x), float(ev.y), 3), 0.1, 1.2, 0.2, Color.WHITE, 0.3)
			Audio.play3d("thud", p8, -2.0)
		"shockwave":
			fx.ring(_wpos(float(ev.x), float(ev.y), 3), 0.1, float(ev.r) * 0.01 * 4.0, 0.25, Color("#d9e8ff"), 0.25)
		"gun_kata":
			var p9 := _wpos(float(ev.x), float(ev.y), 16)
			fx.ring(_wpos(float(ev.x), float(ev.y), 3), 0.1, 2.0, 0.25, Color("#ffd166"), 0.25)
			Audio.play3d("shot_pistol", p9, -2.0)
		"roll_reload":
			var h6 := world.ham_by_id(int(ev.id))
			if is_local_id(h6.id if h6 != null else -1):
				Audio.play2d("reload_pistol", -8.0)
		"kill_refund":
			var h7 := world.ham_by_id(int(ev.id))
			if h7:
				fx.number(_wpos(h7.x, h7.y, 50), "+1", Color("#ffd166"), 0.9)
		"spin_up":
			var h8 := world.ham_by_id(int(ev.id))
			if h8 and (is_local_id(h8.id if h8 != null else -1) or team_sees(h8)):
				Audio.play3d("spin", _wpos(h8.x, h8.y, 20), -6.0 if is_local_id(h8.id if h8 != null else -1) else -12.0)
		"turret_jam":
			var e: SimEntity = world.entities.get(int(ev.id))
			if e:
				fx.stars(_wpos(e.x, e.y, 60), Color("#9fe8ff"), 8, 0.8)
		"focus_max":
			var e2: SimEntity = world.entities.get(int(ev.target))
			if e2:
				fx.burn(_wpos(e2.x, e2.y, 10))
		"mob_fire":
			var e3: SimEntity = world.entities.get(int(ev.id))
			var p10 := _wpos(float(ev.x), float(ev.y), 18)
			if e3 and team_sees(e3):
				fx.spawn(p10 + Vector3(cos(float(ev.aim)), 0, sin(float(ev.aim))) * (e3.r * 0.02), Vector3.ZERO, 0.06, 0.18 if String(ev.kind) == "boss_fan" else 0.1, Color("#ff9fd8") if String(ev.kind) == "boss_fan" else Color("#ffd2a0"), FxSystem.S_STAR, true, 0, 0)
			Audio.play3d("shot_rat", p10, -6.0 if String(ev.kind) == "boss_fan" else -10.0, 0.1, 0.05)
		"boss_ring":
			var p11 := _wpos(float(ev.x), float(ev.y), 4)
			fx.ring(p11, float(ev.r) * 0.01, 3.0, 0.35, Color("#ff7fd0"), 0.3)
			Audio.play3d("thud", p11, 0.0)
			cam.add_trauma(0.2 * _near_local(p11, 10.0))
		"boss_spawn":
			Audio.play2d("boss_roar", -2.0, 0.0)
			var p12 := _wpos(float(ev.x), float(ev.y), 4)
			fx.ring(p12, 0.2, 4.0, 0.6, Color("#ffd166"), 0.3)
		"summon":
			fx.ring(_wpos(float(ev.x), float(ev.y), 3), 0.08, 1.4, 0.3, Color("#c9cbd4"), 0.3)
		"bite":
			Audio.play3d("skitter", _wpos(float(ev.x), float(ev.y)), -8.0, 0.15, 0.1)
		"peck":
			wfx.pet_pecked(int(ev.pet))
			fx.hit(_wpos(float(ev.x), float(ev.y), 14), Color("#fff2a0"), false)
			Audio.play3d("peck", _wpos(float(ev.x), float(ev.y)), -8.0, 0.1, 0.1)
		"zap":
			var a2 := _wpos(float(ev.x0), float(ev.y0), float(ev.get("h0", 20.0)))
			var b2 := _wpos(float(ev.x1), float(ev.y1), float(ev.get("h1", 16.0)))
			var mid := (a2 + b2) * 0.5 + Vector3(randf_range(-0.1, 0.1), randf_range(0.0, 0.1), randf_range(-0.1, 0.1))
			wfx.add_beam(a2, mid, 0.03, Color("#9fe8ff"), 0.14, 1.0)
			wfx.add_beam(mid, b2, 0.03, Color("#9fe8ff"), 0.14, 1.0)
			Audio.play3d("zap", b2, -8.0, 0.1, 0.1)
		"pet_fire":
			Audio.play3d("shot_pistol", _wpos(float(ev.x), float(ev.y)), -14.0, 0.2, 0.1)
		"squad":
			fx.ring(_wpos(float(ev.x), float(ev.y), 3), 0.1, 1.8, 0.35, TEAM_COL[String(ev.team)], 0.3)
		"deadeye_mark":
			Audio.play3d("hitmark", _wpos(float(ev.x), float(ev.y)), -10.0)
		"reload_jam":
			var e4: SimEntity = world.entities.get(int(ev.id))
			if e4:
				fx.number(_wpos(e4.x, e4.y, 50), "卡壳", Color("#ff8a7a"), 0.8)


func _stats() -> Dictionary:
	var out := {"time": world.t, "winner": world.winner, "players": []}
	for h in world.hams:
		out.players.append({"name": h.name, "team": h.team, "lvl": h.lvl, "kills": h.kills, "deaths": h.deaths, "dmg": int(h.dmg_dealt), "bdmg": int(h.bdmg), "local": is_local_id(h.id if h != null else -1)})
	return out


func _exit_tree() -> void:
	if split:
		get_viewport().disable_3d = false
	if world != null:
		world.dispose()


func set_paused(p: bool) -> void:
	paused = p
	for pl in players:
		pl.hud.set_paused(p)
	if players.is_empty():
		hud.set_paused(p)
