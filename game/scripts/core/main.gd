extends Node
## 游戏入口（main.tscn）：主菜单 ↔ 对局 ↔ 结算，暂停菜单，切换时淡入淡出。
## 命令行（写在 -- 之后）：
##   --match              跳过主菜单直接开局
##   --autoplay           本地玩家也交给 AI（观战 / 录屏 / 压测）
##   --mode full|slice    地图（默认 full = 完整三路地图；slice = 批次 1 的中路小图）
##   --duo                本地双人分屏（2P 默认用手柄，--p2 keys2 改用方向键）
##   --seed N             随机种子（默认按时间）
##   --skin gold|pudding|silver|stripe   --weapon <武器 id>（见 weapons.json）
##   --quit-after S       S 秒后自动退出（无人值守跑局用，退出码 0 = 无报错）
## 截图 / 录屏 / 帧率测试见 Capture 自动加载（--capture ...）。

signal match_started(mv: MatchView)

var menu: MainMenu
var match_view: MatchView
var pause_menu: PauseMenu
var result: ResultScreen
var opts := {"skin": "gold", "weapon": "pistol", "mode": "full", "seed": 0, "autoplay": false}
var args := {}
var _fade: ColorRect
var _fps: Label          # 设置里“显示帧率”打开时，右下角显示帧率
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	args = parse_args(OS.get_cmdline_user_args())
	for k: String in ["skin", "weapon", "mode"]:
		if args.has(k):
			opts[k] = String(args[k])
	if args.has("seed"):
		opts.seed = int(args.seed)
	opts.autoplay = args.has("autoplay")
	if args.has("duo"):
		opts.duo = true
		opts.p2_input = String(args.get("p2", "pad"))
	var fl := CanvasLayer.new()
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
		get_tree().create_timer(float(args["quit-after"]), true, false, true).timeout.connect(func() -> void: get_tree().quit(0))
	if args.has("capture"):
		return    # Capture 自动加载接管流程
	if args.has("match"):
		start_match(opts)
	else:
		show_menu()


static func parse_args(list: PackedStringArray) -> Dictionary:
	var out := {}
	var i := 0
	while i < list.size():
		var a := list[i]
		if a.begins_with("--"):
			var k := a.substr(2)
			if k.contains("="):
				out[k.get_slice("=", 0)] = k.get_slice("=", 1)
			elif i + 1 < list.size() and not list[i + 1].begins_with("--"):
				out[k] = list[i + 1]
				i += 1
			else:
				out[k] = true
		i += 1
	return out


func _clear() -> void:
	get_tree().paused = false
	for n in [menu, match_view, pause_menu, result]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	menu = null
	match_view = null
	pause_menu = null
	result = null


func _fade_to(cb: Callable, instant: bool = false) -> void:
	if _busy:
		return
	_busy = true
	if not instant:
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.22)
		await tw.finished
	cb.call()
	# 等两帧让新场景完成第一次绘制再淡入（避免看到着色器编译时的空白帧）
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.35)
	_busy = false


func show_menu(instant: bool = false) -> void:
	_fade_to(func() -> void:
		_clear()
		menu = MainMenu.new()
		menu.name = "MainMenu"
		menu.opts.skin = opts.skin
		menu.opts.weapon = opts.weapon
		add_child(menu)
		menu.start_requested.connect(func(o: Dictionary) -> void:
			opts.merge(o, true)
			start_match(opts))
		menu.quit_requested.connect(func() -> void: get_tree().quit()), instant)


func make_cfg(o: Dictionary) -> Dictionary:
	var sd := int(o.get("seed", 0))
	if sd == 0:
		sd = int(Time.get_unix_time_from_system()) % 100000 + 1
	var mode := String(o.get("mode", "full"))
	var duo := bool(o.get("duo", false))
	var ai := {"blue": 2, "red": 3} if mode == "slice" else {"blue": 4, "red": 5}
	if o.has("ai_blue"):
		ai = {"blue": int(o.ai_blue), "red": int(o.ai_red)}
	var w := String(o.get("weapon", "pistol"))
	var players: Array = [{"team": String(o.get("p1_team", "blue")), "ctl": "player", "name": "玩家1" if duo else "你", "skin": String(o.get("skin", "gold")), "weapon": w, "input": "kbm"}]
	if duo:
		var p2in := String(o.get("p2_input", "pad"))
		var pads := Input.get_connected_joypads()
		if p2in == "pad" and pads.is_empty():
			p2in = "keys2"
		players.append({"team": String(o.get("p2_team", "red")), "ctl": "player", "name": "玩家2", "skin": String(o.get("skin2", "pudding")), "weapon": w,
			"input": p2in, "pad": int(pads[0]) if not pads.is_empty() else 0})
	elif not o.has("ai_blue"):
		# 默认 5 对 5：玩家在哪队，哪队少补一个 AI
		var pt := String(o.get("p1_team", "blue"))
		ai = {"blue": ai.blue + (0 if pt == "blue" else 1), "red": ai.red - (1 if pt == "red" else 0)}
	return {"mode": mode, "seed": sd, "autoplay": bool(o.get("autoplay", false)), "players": players, "ai": ai}


func start_match(o: Dictionary, instant: bool = false) -> void:
	_fade_to(func() -> void:
		_clear()
		match_view = MatchView.new()
		match_view.name = "Match"
		add_child(match_view)
		match_view.start(make_cfg(o))
		match_view.pause_requested.connect(_on_pause)
		match_view.finished.connect(_on_finished)
		match_started.emit(match_view), instant)


func _on_pause() -> void:
	if pause_menu != null or result != null or match_view == null:
		return
	get_tree().paused = true
	match_view.set_paused(true)
	Audio.play2d("ui_click", -6.0)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_resume)
	pause_menu.restart_requested.connect(func() -> void: start_match(opts))
	pause_menu.menu_requested.connect(func() -> void: show_menu())


func _resume() -> void:
	if pause_menu != null:
		pause_menu.queue_free()
		pause_menu = null
	get_tree().paused = false
	if match_view != null:
		match_view.set_paused(false)


func _on_finished(_winner: String, stats: Dictionary) -> void:
	if result != null:
		return
	result = ResultScreen.new()
	add_child(result)
	result.show_result(match_view.local_team, stats)
	result.again_requested.connect(func() -> void: start_match(opts))
	result.menu_requested.connect(func() -> void: show_menu())


func _process(_delta: float) -> void:
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS" % roundi(Engine.get_frames_per_second())


func _notification(what: int) -> void:
	# 窗口失焦时自动暂停（对局中）
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and match_view != null and not match_view.autoplay and result == null and not args.has("capture"):
		_on_pause()
