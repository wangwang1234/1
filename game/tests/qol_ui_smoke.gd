extends Node
## Runtime test: uses actual autoloads, UI, polling, camera and split viewports.
var failures: Array[String] = []
var output := ""

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func key_event(k: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func screenshot(name_: String) -> void:
	if output == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name_ + ".png"))

func _ready() -> void:
	output = OS.get_environment("QOL_REVIEW")
	if output != "":
		DirAccess.make_dir_recursive_absolute(output)
	var old_bindings := InputBindings.bindings.duplicate(true)
	var old_mute: bool = Settings.mute_background
	var saved_file: PackedByteArray = FileAccess.get_file_as_bytes(Settings.PATH) if FileAccess.file_exists(Settings.PATH) else PackedByteArray()
	var had_file := FileAccess.file_exists(Settings.PATH)
	var unit = load("res://tests/qol_behavior_tests.gd").new()
	for method in unit.get_method_list():
		if String(method.name).begins_with("test_"):
			unit.call(method.name)
	failures.append_array(unit.failures)
	InputBindings.load_saved({})
	InputBindings.assign("p1", "dash", KEY_F)
	InputBindings.assign("p1", "fire", KEY_G)
	Settings.mute_background = true
	Settings.save_cfg()
	InputBindings.load_saved({})
	Settings.load_cfg()
	check(InputBindings.code("p1", "dash") == KEY_F and Settings.mute_background, "settings survive save/reload")
	Settings._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(AudioServer.is_bus_mute(0), "background mute activates")
	Settings._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not AudioServer.is_bus_mute(0), "foreground restores audio")
	var pin := PlayerInput.new()
	pin.allow_pad = false
	var h := SimHamster.new()
	key_event(KEY_G, true)
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.fire, "rebound fire key reaches actual input polling")
	pin.block_held()
	pin.poll(h, null, Vector2.ZERO, false)
	check(not h.inp.fire, "actual polling blocks held fire on resume")
	key_event(KEY_G, false)
	pin.poll(h, null, Vector2.ZERO, false)
	key_event(KEY_G, true)
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.fire, "new press after release fires")
	key_event(KEY_G, false)
	InputBindings.load_saved({})
	InputBindings.apply_actions()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := SettingsPanel.new()
	center.add_child(panel)
	panel._show("controls")
	await get_tree().process_frame
	await get_tree().process_frame
	check(panel.size.y <= get_viewport().get_visible_rect().size.y, "settings fit viewport height")
	panel.capture_action = "dash"
	key_event(KEY_R, true)
	check(panel.capture_action == "dash" and InputBindings.code("p1", "dash") == KEY_SPACE, "conflicting capture stays pending")
	key_event(KEY_R, false)
	key_event(KEY_F, true)
	check(panel.capture_action == "" and InputBindings.code("p1", "dash") == KEY_F, "actual UI captures binding")
	key_event(KEY_F, false)
	check(panel.binding_buttons.dash.text == "F", "binding button updates")
	await screenshot("settings_controls")
	panel.binding_profile = "p2"
	panel._refresh_bindings()
	await get_tree().process_frame
	check(panel.binding_buttons.card_1.text == "8", "second-player UI shows correct bindings")
	center.queue_free()
	await get_tree().process_frame
	var mv := MatchView.new()
	add_child(mv)
	mv.start({"mode": "slice", "seed": 7, "players": [{"team": "blue", "ctl": "player", "input": "kbm"}, {"team": "red", "ctl": "player", "input": "keys2"}], "ai": {"blue": 1, "red": 1}})
	mv.set_physics_process(false)
	await get_tree().process_frame
	var p1 = mv.players[0]
	var p2 = mv.players[1]
	p1.ham.alive = false
	p1.ham.dead = true
	p1.ham.hp = 0.0
	p1.ham.death_source = "测试炮台"
	p1.ham.respawn_t = 8.0
	var mid: Vector2 = mv.world.map.lanes.mid[mv.world.map.lanes.mid.size() / 2]
	for player in mv.world.hams:
		if player.alive:
			player.x = mid.x + (80.0 if player.team == "blue" else 180.0)
			player.y = mid.y + 60.0
			player.px = player.x
			player.py = player.y
	mv._process(1.3)
	check(mv.spectating(p1.ham) != null and mv.spectating(p1.ham).team == "blue", "split death automatically follows teammate")
	check(p2.camera_subject == p2.ham.id, "other split camera stays on living player")
	check(p1.cam.cull_mask == 3 and p2.cam.cull_mask == 5, "spectating preserves team visibility masks")
	await get_tree().process_frame
	await screenshot("split_spectating")
	p1.ham.alive = true
	p1.ham.dead = false
	mv._process(0.01)
	check(p1.camera_subject == p1.ham.id and mv.spectating(p1.ham) == null, "respawn returns camera to self")
	p1.ham.inp.fire = true
	mv.set_paused(true)
	check(not p1.ham.inp.fire, "opening menu clears gameplay input immediately")
	mv.set_paused(false)
	check(mv._resume_guard > 0, "resume has an input guard")
	mv.queue_free()
	await get_tree().process_frame
	InputBindings.load_saved(old_bindings)
	InputBindings.apply_actions()
	Settings.mute_background = old_mute
	Settings.apply()
	if had_file:
		var file := FileAccess.open(Settings.PATH, FileAccess.WRITE)
		file.store_buffer(saved_file)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.PATH))
	print("QOL_UI_RECEIPT ", JSON.stringify({"ok": failures.is_empty(), "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
