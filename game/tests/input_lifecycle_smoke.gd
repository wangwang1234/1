extends Node
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	print("CHECK ", message, " ", ok)
	if not ok:
		failures.append(message)
func key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func button(code: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _ready() -> void:
	var saved := InputBindings.bindings.duplicate(true)
	InputBindings.load_saved({})
	InputBindings.apply_actions()
	InputBindings.release_controls()
	var mv := MatchView.new()
	add_child(mv)
	mv.start({"mode": "slice", "seed": 9, "players": [{"team": "blue", "ctl": "player"}]})
	mv.set_physics_process(false)
	var h := mv.local
	var pin := mv.input
	pin.allow_pad = false
	for action in ["dash", "reload", "gadget"]:
		var code := InputBindings.code("p1", action)
		key(code, true)
		pin.poll(h, null, Vector2.ZERO, false)
		NetInput.clear(h.inp)
		h.alive = false
		h.respawn_t = 10.0
		key(code, false)
		mv._physics_process(0.0)
		h.alive = true
		key(code, true)
		pin.poll(h, null, Vector2.ZERO, false)
		check(bool(h.inp.get(action)), "respawn first fresh " + action)
		key(code, false)
		pin.poll(h, null, Vector2.ZERO, false)
		NetInput.clear(h.inp)
	# A fresh press arriving during the resume guard must survive the guard.
	mv.set_paused(false)
	key(KEY_D, true)
	mv._physics_process(0.0)
	mv._resume_guard = 0
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.mx == 1.0, "fresh movement during resume guard is not latched as held menu input")
	key(KEY_D, false)
	# A held action across death must require release, then accept a fresh press.
	key(KEY_SPACE, true)
	pin.poll(h, null, Vector2.ZERO, false)
	h.alive = false
	mv._physics_process(0.0)
	h.alive = true
	NetInput.clear(h.inp)
	pin.poll(h, null, Vector2.ZERO, false)
	check(not h.inp.dash, "held dash across death suppressed")
	key(KEY_SPACE, false)
	pin.poll(h, null, Vector2.ZERO, false)
	key(KEY_SPACE, true)
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.dash, "held death action recovers after release")
	InputBindings.release_controls()
	pin = PlayerInput.new()
	pin.scheme = "pad"
	for btn in [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B]:
		for cycle in 3:
			h.choices = [{"t": "weap", "id": "ak47"}, {"t": "weap", "id": "pistol"}, {"t": "weap", "id": "shotgun"}]
			button(btn, true)
			pin.poll(h, null, Vector2.ZERO, true)
			check(h.inp.card == [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B].find(btn), "pad upgrade %d cycle %d" % [btn, cycle])
			NetInput.clear(h.inp)
			h.choices.clear()
			button(btn, false)
			pin.poll(h, null, Vector2.ZERO, false)
	# A reload held as the next upgrade appears must not select it automatically.
	NetInput.clear(h.inp)
	button(JOY_BUTTON_X, true)
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.reload, "X still reloads outside upgrades")
	h.choices = [{"t": "weap", "id": "ak47"}]
	NetInput.clear(h.inp)
	pin.poll(h, null, Vector2.ZERO, true)
	check(h.inp.card == -1, "held reload does not select a newly appearing upgrade")
	button(JOY_BUTTON_X, false)
	pin.poll(h, null, Vector2.ZERO, true)
	button(JOY_BUTTON_X, true)
	pin.poll(h, null, Vector2.ZERO, true)
	check(h.inp.card == 0, "upgrade accepts X after release")
	button(JOY_BUTTON_X, false)
	h.choices.clear()
	button(JOY_BUTTON_RIGHT_SHOULDER, true)
	pin.scheme = "kbm"
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.fire, "hybrid controller shoulder fires")
	button(JOY_BUTTON_RIGHT_SHOULDER, false)
	pin.device = "pad"
	key(KEY_W, true)
	pin.poll(h, mv.cam, Vector2(400, 300), false)
	check(pin.device == "kbm" and h.inp.has_aim_point, "keyboard returns mouse aiming without mouse motion")
	key(KEY_W, false)
	InputBindings.load_saved(saved)
	InputBindings.apply_actions()
	InputBindings.release_controls()
	# Optional rendered review of the actual upgrade HUD.
	var out := OS.get_environment("LIFECYCLE_REVIEW")
	if out != "" and DisplayServer.get_name() != "headless":
		mv.input.device = "pad"
		SimCards.roll(mv.world, h)
		for frame in 40:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg(out.path_join("upgrade_hud.jpg"), 0.9)
	mv.queue_free()
	await get_tree().process_frame
	var duo := MatchView.new()
	add_child(duo)
	duo.start({"mode": "slice", "seed": 9, "players": [{"team": "blue", "ctl": "player", "input": "kbm"}, {"team": "red", "ctl": "player", "input": "keys2"}]})
	duo.set_physics_process(false)
	for i in 2:
		var pl = duo.players[i]
		var code := InputBindings.code(pl.input.profile(), "reload")
		key(code, true)
		pl.input.poll(pl.ham, null, Vector2.ZERO, false)
		pl.ham.alive = false
		pl.ham.respawn_t = 10.0
		key(code, false)
		duo._physics_process(0.0)
		pl.ham.alive = true
		NetInput.clear(pl.ham.inp)
		key(code, true)
		pl.input.poll(pl.ham, null, Vector2.ZERO, false)
		check(pl.ham.inp.reload, "split player %d fresh reload after death" % i)
		key(code, false)
		InputBindings.release_controls()
	duo.queue_free()
	await get_tree().process_frame
	print("LIFECYCLE_RECEIPT ", JSON.stringify({"ok": failures.is_empty(), "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
