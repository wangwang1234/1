class_name PlayerInput
extends RefCounted





var scheme: = "kbm"
var device: = "kbm"
var pad_index: = 0
var allow_pad: = true
var arrows: = true
var position_hint: = Vector2(INF, INF)
var _pad_aim: = 0.0
var _edge: = {}

static var right_shift_down: = false


static func ensure_actions() -> void:
	InputBindings.apply_actions()


var _blocked := {}

func profile() -> String:
	return "p2" if scheme == "keys2" else "p1"

func block_held() -> void:
	# Only held controls need a release. Never swallow the first fresh press.
	_blocked.clear()
	for a in InputBindings.DEFAULTS[profile()]:
		if InputBindings.down(profile(), a):
			_blocked[a] = true
	for a in ["pad_fire", "pad_dash", "pad_reload", "pad_gadget", "pad_card0", "pad_card1", "pad_card2", "pad_move"]:
		if _pad_down(a):
			_blocked[a] = true
	_edge.clear()

func _pad_down(a: String) -> bool:
	match a:
		"pad_fire":
			return Input.get_joy_axis(pad_index, JOY_AXIS_TRIGGER_RIGHT) > 0.4 or Input.is_joy_button_pressed(pad_index, JOY_BUTTON_RIGHT_SHOULDER)
		"pad_dash":
			return Input.is_joy_button_pressed(pad_index, JOY_BUTTON_A)
		"pad_reload", "pad_card0":
			return Input.is_joy_button_pressed(pad_index, JOY_BUTTON_X)
		"pad_gadget":
			return Input.is_joy_button_pressed(pad_index, JOY_BUTTON_LEFT_SHOULDER)
		"pad_card1":
			return Input.is_joy_button_pressed(pad_index, JOY_BUTTON_Y)
		"pad_card2":
			return Input.is_joy_button_pressed(pad_index, JOY_BUTTON_B)
		"pad_move":
			return Vector2(Input.get_joy_axis(pad_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad_index, JOY_AXIS_LEFT_Y)).length() > 0.2
	return false

func _gate(a: String, down: bool) -> bool:
	if _blocked.has(a):
		if not down:
			_blocked.erase(a)
		return false
	return down

func _action(a: String) -> bool:
	return _gate(a, InputBindings.down(profile(), a))


func _key(k: int) -> bool:
	return Input.is_physical_key_pressed(k)


func _pressed_edge(name: String, down: bool) -> bool:
	var was: = bool(_edge.get(name, false))
	_edge[name] = down
	return down and not was


func poll(h: SimHamster, cam: GameCamera, mouse_screen: Vector2, picking_cards: bool, w: SimWorld = null) -> void :
	if h == null:
		return
	var origin: = position_hint if position_hint.is_finite() else Vector2(h.x, h.y)
	var inp: = h.inp
	var mv: = Vector2.ZERO
	var pad_mv: = Vector2.ZERO
	var pad_aim: = Vector2.ZERO
	var use_pad: = scheme == "pad" or (scheme == "kbm" and allow_pad)
	if use_pad:
		pad_mv = Vector2(Input.get_joy_axis(pad_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad_index, JOY_AXIS_LEFT_Y))
		pad_aim = Vector2(Input.get_joy_axis(pad_index, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad_index, JOY_AXIS_RIGHT_Y))
	match scheme:
		"keys2":
			device = "keys2"
			mv = Vector2(float(_action("move_right")) - float(_action("move_left")), float(_action("move_down")) - float(_action("move_up")))
		"pad":
			device = "pad"
			mv = pad_mv if pad_mv.length() > 0.2 else Vector2.ZERO
		_:
			mv = Vector2(float(_action("move_right")) - float(_action("move_left")), float(_action("move_down")) - float(_action("move_up")))
			var keyboard_active := false
			for a in InputBindings.DEFAULTS[profile()]:
				if a != "pause" and not String(a).begins_with("spectate_") and not _blocked.has(a) and InputBindings.down(profile(), a):
					keyboard_active = true
			if keyboard_active:
				device = "kbm"
			elif use_pad:
				if pad_mv.length() > 0.25 or pad_aim.length() > 0.3:
					device = "pad"
				for a in ["pad_fire", "pad_dash", "pad_reload", "pad_gadget", "pad_card1", "pad_card2"]:
					if not _blocked.has(a) and _pad_down(a):
						device = "pad"
			if device == "pad" and pad_mv.length() > 0.2:
				mv = pad_mv
	if _blocked.has("pad_move"):
		if pad_mv.length() <= 0.2:
			_blocked.erase("pad_move")
		elif device == "pad":
			mv = Vector2.ZERO
	if mv.length() > 1.0:
		mv = mv.normalized()
	inp.mx = mv.x
	inp.my = mv.y
	inp.ml = mv.length()
	if device == "kbm" and cam != null:
		var g: = cam.screen_to_ground(mouse_screen, 0.16)
		var gx: = g.x * 100.0
		var gy: = g.z * 100.0
		inp.aim = atan2(gy - origin.y, gx - origin.x)
		inp.aim_x = gx
		inp.aim_y = gy
		inp.has_aim_point = true
	else:
		if pad_aim.length() > 0.3:
			_pad_aim = atan2(pad_aim.y, pad_aim.x)
		else:

			var t: SimEntity = SimWeapons.auto_aim(w, h, maxf(300.0, minf(SimWeapons.range_of(h), 640.0))) if w != null else null
			if t != null:
				_pad_aim = atan2(t.y - origin.y, t.x - origin.x)
			elif mv.length() > 0.3:
				_pad_aim = atan2(mv.y, mv.x)
		inp.aim = _pad_aim
		inp.has_aim_point = false
	var fire: = false
	match scheme:
		"keys2":
			fire = _action("fire")
		"pad":
			fire = _gate("pad_fire", Input.get_joy_axis(pad_index, JOY_AXIS_TRIGGER_RIGHT) > 0.4 or Input.is_joy_button_pressed(pad_index, JOY_BUTTON_RIGHT_SHOULDER))
		_:
			fire = _action("fire") or (use_pad and _gate("pad_fire", _pad_down("pad_fire")))
	inp.fire = fire and not picking_cards
	var kb: = scheme != "pad"
	var dash: = (kb and _action("dash")) or (use_pad and _gate("pad_dash", Input.is_joy_button_pressed(pad_index, JOY_BUTTON_A)))
	var reload: = (kb and _action("reload")) or (use_pad and _gate("pad_reload", Input.is_joy_button_pressed(pad_index, JOY_BUTTON_X)) and h.choices.is_empty())
	var gadget: = (kb and _action("gadget")) or (use_pad and _gate("pad_gadget", Input.is_joy_button_pressed(pad_index, JOY_BUTTON_LEFT_SHOULDER)))
	if _pressed_edge("dash", dash):
		inp.dash = true
	if _pressed_edge("reload", reload):
		inp.reload = true
	if _pressed_edge("gadget", gadget):
		inp.gadget = true
	for i in 3:
		var down: = kb and _action("card_%d" % (i + 1))
		if _pressed_edge("card%d" % i, down):
			inp.card = i
	if use_pad:
		var btns: = [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B]
		for i in 3:
			# Observe releases between upgrades too, so a later fresh press works.
			var pressed := _pressed_edge("pcard%d" % i, _gate("pad_card%d" % i, Input.is_joy_button_pressed(pad_index, btns[i])))
			if pressed and not h.choices.is_empty():
				inp.card = i
				device = "pad"


static func track_key(ev: InputEvent) -> void :

	var k: = ev as InputEventKey
	if k == null or k.echo or k.physical_keycode != KEY_SHIFT:
		return

	if k.location != KEY_LOCATION_LEFT:
		right_shift_down = k.pressed


func card_hint() -> String:
	match device:
		"pad":
			return "按 X / Y / B 选升级"
		"keys2":
			return "按 %s 选升级" % " / ".join(card_keys())
	return "按 %s 选升级" % " / ".join(card_keys())


func gadget_key() -> String:
	match device:
		"pad":
			return "LB"
		"keys2":
			return InputBindings.caption("p2", "gadget", true)
	return InputBindings.caption("p1", "gadget", true)


func card_keys() -> Array:
	if device == "pad":
		return ["X", "Y", "B"]
	return [InputBindings.caption(profile(), "card_1", true), InputBindings.caption(profile(), "card_2", true), InputBindings.caption(profile(), "card_3", true)]

func spectate_direction(ev: InputEvent) -> int:
	if scheme != "pad":
		if InputBindings.event_matches(profile(), "spectate_prev", ev):
			device = "keys2" if scheme == "keys2" else "kbm"
			return -1
		if InputBindings.event_matches(profile(), "spectate_next", ev):
			device = "keys2" if scheme == "keys2" else "kbm"
			return 1
	if (scheme == "pad" or allow_pad) and ev is InputEventJoypadButton and ev.device == pad_index and ev.pressed:
		if ev.button_index == JOY_BUTTON_DPAD_LEFT:
			device = "pad"
			return -1
		if ev.button_index == JOY_BUTTON_DPAD_RIGHT:
			device = "pad"
			return 1
	return 0

func spectate_hint() -> String:
	if device == "pad" or scheme == "pad":
		return "十字键左右切换队友"
	return "%s / %s 切换队友" % [InputBindings.caption(profile(), "spectate_prev", true), InputBindings.caption(profile(), "spectate_next", true)]
