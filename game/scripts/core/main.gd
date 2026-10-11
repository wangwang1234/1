extends Node











signal match_started(mv: MatchView)

var menu: MainMenu
var match_view: MatchView
var pause_menu: PauseMenu
var result: ResultScreen
var opts: = {"skin": "gold", "weapon": "pistol", "mode": "full", "seed": 0, "autoplay": false}
var args: = {}
var _fade: ColorRect
var _fps: Label
var _busy: = false
var _network_transition: = false


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	args = parse_args(OS.get_cmdline_user_args())
	LanSession.match_requested.connect(start_network_match)
	LanSession.session_ended.connect(_network_ended)
	for k: String in ["skin", "weapon", "mode"]:
		if args.has(k):
			opts[k] = String(args[k])
	if args.has("seed"):
		opts.seed = int(args.seed)
	opts.autoplay = args.has("autoplay")
	if args.has("duo"):
		opts.duo = true
		opts.p2_input = String(args.get("p2", "pad"))
	var fl: = CanvasLayer.new()
	fl.layer = 100
	add_child(fl)
	_fade = ColorRect.new()
	_fade.color = Color(0.04, 0.025, 0.07, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(_fade)
	_fps = UiTheme.label("", 15, Color("#9fe8a0"), false, 4)
	_fps.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_fps.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_fps.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps.offset_right = -8
	_fps.offset_bottom = -2
	_fps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(_fps)
	if args.has("quit-after"):
		get_tree().create_timer(float(args["quit-after"]), true, false, true).timeout.connect( func() -> void : get_tree().quit(0))
	if args.has("capture"):
		return
	if args.has("lan-host") or args.has("lan-join"):
		show_menu(true, true)
		var profile: = {"name": String(args.get("name", "房主" if args.has("lan-host") else "玩家2")),
			"team": String(args.get("team", "blue" if args.has("lan-host") else "red")), "skin": opts.skin, "weapon": opts.weapon}
		var port: = int(args.get("port", Data.load_json("network").port))
		if args.has("lan-host"):
			LanSession.host(profile, opts, port)
		else:
			LanSession.join(String(args["lan-join"]), profile, port)
	elif args.has("match"):
		start_match(opts)
	else:
		show_menu()


static func parse_args(list: PackedStringArray) -> Dictionary:
	var out: = {}
	var i: = 0
	while i < list.size():
		var a: = list[i]
		if a.begins_with("--"):
			var k: = a.substr(2)
			if k.contains("="):
				out[k.get_slice("=", 0)] = k.get_slice("=", 1)
			elif i + 1 < list.size() and not list[i + 1].begins_with("--"):
				out[k] = list[i + 1]
				i += 1
			else:
				out[k] = true
		i += 1
	return out


func _clear() -> void :
	get_tree().paused = false
	Audio.set_music_duck(false)
	for n in [menu, match_view, pause_menu, result]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	menu = null
	match_view = null
	pause_menu = null
	result = null


func _fade_to(cb: Callable, instant: bool = false) -> void :
	if _busy:
		return
	_busy = true
	if not instant:
		var tw: = create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.22)
		await tw.finished
	cb.call()

	await get_tree().process_frame
	await get_tree().process_frame
	var tw2: = create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.35)
	_busy = false


func show_menu(instant: bool = false, lan: bool = false) -> void :
	if not lan:
		LanSession.leave()
	_fade_to( func() -> void :
		_clear()
		menu = MainMenu.new()
		menu.name = "MainMenu"
		menu.opts.skin = opts.skin
		menu.opts.weapon = opts.weapon
		add_child(menu)
		menu.start_requested.connect( func(o: Dictionary) -> void :
			opts.merge(o, true)
			start_match(opts))
		menu.quit_requested.connect( func() -> void : get_tree().quit())
		if lan:
			menu.open_lan_lobby(), instant)


func make_cfg(o: Dictionary) -> Dictionary:
	var sd: = int(o.get("seed", 0))
	if sd == 0:
		sd = int(Time.get_unix_time_from_system()) % 100000 + 1
	var mode: = String(o.get("mode", "full"))
	var duo: = bool(o.get("duo", false))
	var ai: = {}
	if o.has("ai_blue"):
		ai = {"blue": int(o.ai_blue), "red": int(o.ai_red)}
	var w: = String(o.get("weapon", "pistol"))
	var players: Array = [{"team": String(o.get("p1_team", "blue")), "ctl": "player", "name": "玩家1" if duo else "你", "skin": String(o.get("skin", "gold")), "weapon": w, "input": "kbm"}]
	if duo:
		var p2in: = String(o.get("p2_input", "pad"))
		var want_pad: = p2in == "pad"
		var pads: = Input.get_connected_joypads()
		if p2in == "pad" and pads.is_empty():
			p2in = "keys2"
		players.append({"team": String(o.get("p2_team", "red")), "ctl": "player", "name": "玩家2", "skin": String(o.get("skin2", "pudding")), "weapon": w,
			"input": p2in, "pad": int(pads[0]) if not pads.is_empty() else 0, "want_pad": want_pad})
	if not o.has("ai_blue"):

		var size: = int(Lobby.TEAM_SIZE.get(mode, 5))
		var hum: = {"blue": 0, "red": 0}
		for p in players:
			hum[p.team] = int(hum.get(p.team, 0)) + 1
		ai = {"blue": maxi(0, size - int(hum.get("blue", 0))), "red": maxi(0, size - int(hum.get("red", 0)))}
	return {"mode": mode, "seed": sd, "autoplay": bool(o.get("autoplay", false)), "players": players, "ai": ai}


func start_match(o: Dictionary, instant: bool = false) -> void :
	LanSession.leave()
	_fade_to( func() -> void :
		_clear()
		match_view = MatchView.new()
		match_view.name = "Match"
		add_child(match_view)
		match_view.start(make_cfg(o))
		match_view.pause_requested.connect(_on_pause)
		match_view.finished.connect(_on_finished)
		match_started.emit(match_view), instant)


func start_network_match(cfg: Dictionary) -> void :
	while _busy:
		await get_tree().process_frame
	if not LanSession.active() or not LanSession.loading:
		return
	_network_transition = true
	await _fade_to( func() -> void :
		if not LanSession.active() or not LanSession.loading:
			return
		_clear()
		match_view = MatchView.new()
		match_view.name = "Match"
		add_child(match_view)
		match_view.start(cfg)
		match_view.pause_requested.connect(_on_pause)
		match_view.finished.connect(_on_finished)
		match_started.emit(match_view), args.has("lan-auto"))
	_network_transition = false


func _network_ended(_reason: String) -> void :
	if match_view != null or _network_transition:
		while _busy:
			await get_tree().process_frame
		show_menu(false, true)


func _on_pause() -> void :
	if pause_menu != null or result != null or match_view == null:
		return
	get_tree().paused = not match_view.networked
	match_view.set_paused(true)
	Audio.set_music_duck(true)
	Audio.play2d("ui_click", -6.0)
	pause_menu = PauseMenu.new()
	pause_menu.networked = match_view.networked
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_resume)
	pause_menu.restart_requested.connect( func() -> void :
		if match_view.networked:
			LanSession.return_to_room()
		else:
			start_match(opts))
	pause_menu.menu_requested.connect( func() -> void : show_menu())


func _resume() -> void :
	if pause_menu != null:
		pause_menu.queue_free()
		pause_menu = null
	get_tree().paused = false
	Audio.set_music_duck(false)
	if match_view != null:
		match_view.set_paused(false)


func _on_finished(_winner: String, stats: Dictionary) -> void :
	if result != null:
		return
	result = ResultScreen.new()
	result.networked = match_view.networked
	add_child(result)
	result.show_result(match_view.local_team, stats)
	result.again_requested.connect( func() -> void :
		if match_view.networked:
			LanSession.return_to_room()
		else:
			start_match(opts))
	result.menu_requested.connect( func() -> void : show_menu())


func _process(_delta: float) -> void :

	if args.has("lan-auto") and LanSession.active() and not LanSession.loading and not LanSession.running:
		var profile: Dictionary = LanSession.roster.get(LanSession.local_id(), {})
		if not profile.is_empty() and not bool(profile.ready):
			LanSession.set_ready(true)
		if LanSession.can_start() and not _busy:
			LanSession.start_game()
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS" % roundi(Engine.get_frames_per_second())


func _notification(what: int) -> void :

	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and match_view != null and not match_view.autoplay and result == null and not args.has("capture") and not args.has("lan-auto"):
		_on_pause()
