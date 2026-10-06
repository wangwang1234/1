class_name MatchView
extends Node3D
## 一局对战的表现层总控：持有 SimWorld，60Hz 推进逻辑，事件分发到各表现节点 / 特效 / 音效 / 镜头 / 界面。
## 逻辑与表现分离：这里只读 sim 状态，唯一写入的是本地玩家的输入。

signal finished(winner: String, stats: Dictionary)
signal pause_requested

const TEAM_COL := {"blue": Color("#4fa3ff"), "red": Color("#ff5b5b"), "neutral": Color("#ffd166")}

var world: SimWorld
var local: SimHamster
var local_team := "blue"
var map_view: MapView
var fx: FxSystem
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
var _dead_time := 0.0
var _last_alive := Vector3.ZERO


func start(cfg: Dictionary) -> void:
	_cfg = cfg
	PlayerInput.ensure_actions()
	world = SimWorld.new()
	world.setup(cfg)
	autoplay = bool(cfg.get("autoplay", false))
	for h in world.hams:
		if h.ctl == "player":
			local = h
			local_team = h.team
	if local != null and autoplay:
		local.ctl = "ai"
		local.ai = SimHamster.AiState.new()
		local.ai.lane = "mid"
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
	cam = GameCamera.new()
	cam.name = "Camera"
	add_child(cam)
	cam.current = true
	listener = AudioListener3D.new()
	listener.name = "Listener"
	add_child(listener)
	listener.make_current()
	cam.bounds = Rect2(world.map.min_x * 0.01, world.map.min_y * 0.01, (world.map.max_x - world.map.min_x) * 0.01, (world.map.max_y - world.map.min_y) * 0.01)
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
	var focus := local if local != null else world.hams[0]
	cam.snap(Vector3(focus.x * 0.01, 0, focus.y * 0.01))
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.setup(self)
	Audio.play_ambience(true)


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
	v.setup(h, h == local)
	ham_views[h.id] = v


func team_sees(e: SimEntity) -> bool:
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


func _physics_process(dt: float) -> void:
	if world == null or paused:
		return
	if hitstop > 0.0:
		hitstop -= dt
		return
	if local != null and not autoplay:
		_mouse = get_viewport().get_mouse_position()
		input.poll(local, cam, _mouse, not local.choices.is_empty())
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
		Audio.play2d("win" if world.winner == local_team else "lose", -4.0, 0.0, 1.0)
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
		(ham_views[h.id] as HamsterView).sync(h, alpha, delta, h.team == local_team or world.vis[local_team].has(h.id))
		if h.burn_t > 0.0 and randf() < 0.45:
			fx.burn(Vector3(h.x * 0.01, 0.1, h.y * 0.01))
	var alive_ids := {}
	for m in world.minions:
		alive_ids[m.id] = true
		if not minion_views.has(m.id):
			var mv := UnitViews.MinionView.new()
			add_child(mv)
			mv.setup(m)
			minion_views[m.id] = mv
		(minion_views[m.id] as UnitViews.MinionView).sync(m, alpha, delta, team_sees(m))
	for id in minion_views.keys():
		if not alive_ids.has(id):
			(minion_views[id] as Node).queue_free()
			minion_views.erase(id)
	for s in world.structs:
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
	# 镜头
	var focus := local if local != null else world.hams[0]
	var fpos := Vector3(lerpf(focus.px, focus.x, alpha) * 0.01, 0, lerpf(focus.py, focus.y, alpha) * 0.01)
	if focus.alive:
		_dead_time = 0.0
		_last_alive = fpos
	else:
		# 倒下后先在倒下的地方停 1.8 秒（看清是谁打的），再慢慢移到己方鼠窝门口（门朝向敌方，往外多看一点兵线）
		_dead_time += delta
		fpos = _last_alive
		if _dead_time > 1.8:
			var b: Vector2 = world.map.base_pos[focus.team]
			fpos = Vector3(b.x * 0.01 + (3.6 if focus.team == "blue" else -3.6), 0, b.y * 0.01)
	var aim_pt := fpos + Vector3(cos(focus.aim), 0, sin(focus.aim)) * 3.0
	if input.device == "kbm" and not autoplay and focus.inp.has_aim_point:
		aim_pt = Vector3(focus.inp.aim_x * 0.01, 0, focus.inp.aim_y * 0.01)
	cam.update(delta, fpos, aim_pt, focus.alive)
	# 听者放在角色头顶（不是 10 米高的镜头上），否则所有 3D 音效都像隔得很远；朝向沿用镜头，左右声道和画面一致
	listener.global_transform = Transform3D(cam.global_transform.basis, fpos + Vector3(0, 1.2, 0))
	fx.sync_tracers(world.bullets, alpha, cam.global_transform.basis, func(b, _p): return true)
	fx.sync_items(world.items, alpha, Time.get_ticks_msec() / 1000.0)
	fx.sync_lobs(world.lobs)
	fx.update(delta)
	hud.refresh(delta)


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
				var hv: HamsterView = ham_views.get(ev.id)
				if hv:
					hv.on_event(ev)
				var h := world.ham_by_id(int(ev.id))
				var W := Data.weapon(String(ev.weapon))
				var aim := float(ev.aim)
				var dir := Vector3(cos(aim), 0, sin(aim))
				var mpos := _wpos(float(ev.gx), float(ev.gy), float(ev.gh))
				if hv and hv.weapon_node:
					var mz := hv.weapon_node.find_child("muzzle", true, false) as Node3D
					if mz:
						mpos = mz.global_position
				if h == null or team_sees(h):
					fx.muzzle(mpos, dir, W)
					var sh := String(W.get("fx", {}).get("sh", ""))
					if sh != "" and sh != "<null>":
						fx.eject_shell(mpos - dir * 0.12, dir.cross(Vector3.UP) * -1.0, dir, sh == "red")
				var snd := "shot_" + String(ev.weapon)
				Audio.play3d(snd if Audio.has(snd) else "shot_pistol", mpos, -2.0 if h == local else -5.0, 0.05, 0.0)
				if String(ev.weapon) == "shotgun":
					get_tree().create_timer(0.3).timeout.connect(func(): Audio.play3d("pump", mpos, -6.0))
				if h == local:
					var F: Dictionary = W.get("fx", {})
					cam.add_trauma(float(F.get("shk", 0.06)) * Settings.fx_strength)
					cam.add_kick(dir, float(F.get("kick", 3.0)) * 0.008)
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
				if local != null and int(ev.id) == local.id:
					hud.hitmark(bool(ev.kill))
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
					Audio.play3d("reload_" + cls, _wpos(h2.x, h2.y, 20.0), -6.0 if h2 == local else -12.0, 0.0, 0.1)
				if h2 == local:
					hud.toast_reload()
			"empty":
				if local != null and int(ev.id) == local.id:
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
				if h5 == local:
					Audio.play2d("levelup", -3.0, 0.0)
			"choices":
				if local != null and int(ev.id) == local.id:
					Audio.play2d("card_appear", -6.0, 0.0)
					hud.show_cards()
			"picked":
				var hv6: HamsterView = ham_views.get(ev.id)
				if hv6:
					hv6.on_event(ev)
				var h6 := world.ham_by_id(int(ev.id))
				if h6 and team_sees(h6):
					var col := Color(String(ev.label.get("pathColor", "#ffd166")))
					fx.stars(_wpos(h6.x, h6.y, 30), col, 10)
					fx.ring(_wpos(h6.x, h6.y, 3), 0.16, 1.8, 0.35, col, 0.3)
				if h6 == local:
					Audio.play2d("card_pick", -4.0, 0.0)
					hud.cards_picked()
			"gem":
				var hv7: HamsterView = ham_views.get(ev.id)
				if hv7:
					hv7.on_event(ev)
				var h7 := world.ham_by_id(int(ev.id))
				if h7 == local:
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
				hud.toast(int(ev.id), String(ev.text), Color(String(ev.color)), float(ev.dur))
			"feed":
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
				if local != null and int(ev.id) == local.id:
					hud.flash_white(float(ev.amount))


func _on_damage(ev: Dictionary) -> void:
	var id := int(ev.id)
	var e: SimEntity = world.entities.get(id)
	var p := _wpos(float(ev.x), float(ev.y), float(ev.r) * 2.4 + 12.0)
	var seen := e == null or team_sees(e)
	if e is SimHamster:
		var hv: HamsterView = ham_views.get(id)
		if hv:
			hv.on_event(ev)
		if e == local:
			hud.hurt_pulse()
			cam.add_trauma(0.2 * Settings.fx_strength)
			Audio.play2d("hurt", -6.0, 0.08, 0.08)
		elif seen and not bool(ev.quiet):
			Audio.play3d("hurt", p, -10.0, 0.1, 0.1)
	if seen and Settings.show_damage_numbers and (not bool(ev.quiet) or bool(ev.crit)):
		var amt := int(round(float(ev.amount)))
		if amt <= 0:
			return
		var crit := bool(ev.crit)
		var col := Color("#ffd166") if crit else (Color("#ff8a8a") if String(ev.kind) == "ham" else Color("#ffffff"))
		var by_local := local != null and int(ev.get("by", -1)) == local.id
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
			var involves_local := local != null and (int(ev.id) == local.id or int(ev.killer) == local.id)
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


func _stats() -> Dictionary:
	var out := {"time": world.t, "winner": world.winner, "players": []}
	for h in world.hams:
		out.players.append({"name": h.name, "team": h.team, "lvl": h.lvl, "kills": h.kills, "deaths": h.deaths, "dmg": int(h.dmg_dealt), "bdmg": int(h.bdmg), "local": h == local})
	return out


func _exit_tree() -> void:
	if world != null:
		world.dispose()


func set_paused(p: bool) -> void:
	paused = p
	hud.set_paused(p)
