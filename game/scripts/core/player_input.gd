class_name PlayerInput
extends RefCounted
## 玩家输入 → SimHamster.HamInput。键鼠：WASD 移动、鼠标瞄准、左键射击、空格翻滚、R 换弹、Q 道具、1/2/3 选卡。
## 手柄：左摇杆移动、右摇杆瞄准（松开保持朝向，靠近敌人时轻微吸附）、RT 射击、A 翻滚、X 换弹、LB 道具、X/Y/B 选卡。

const ACTIONS := {
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"dash": [KEY_SPACE], "reload": [KEY_R], "gadget": [KEY_Q], "card_1": [KEY_1], "card_2": [KEY_2], "card_3": [KEY_3], "pause": [KEY_ESCAPE, KEY_P],
}

var device := "kbm"      # kbm / pad
var _pad_aim := 0.0
var _edge := {}


static func ensure_actions() -> void:
	for a in ACTIONS:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.25)
			for k in ACTIONS[a]:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(a, ev)
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire", 0.25)
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", mb)
		var rt := InputEventJoypadMotion.new()
		rt.axis = JOY_AXIS_TRIGGER_RIGHT
		rt.axis_value = 1.0
		InputMap.action_add_event("fire", rt)
	var pad := {"dash": JOY_BUTTON_A, "reload": JOY_BUTTON_X, "gadget": JOY_BUTTON_LEFT_SHOULDER, "pause": JOY_BUTTON_START}
	for a in pad:
		var jb := InputEventJoypadButton.new()
		jb.button_index = pad[a]
		InputMap.action_add_event(a, jb)


func poll(h: SimHamster, cam: GameCamera, mouse_screen: Vector2, picking_cards: bool) -> void:
	if h == null:
		return
	var inp := h.inp
	var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var pad_mv := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	var pad_aim := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if pad_mv.length() > 0.25 or pad_aim.length() > 0.3:
		device = "pad"
	if pad_mv.length() > 0.2:
		mv = pad_mv
	if mv.length() > 1.0:
		mv = mv.normalized()
	inp.mx = mv.x
	inp.my = mv.y
	inp.ml = mv.length()
	if device == "kbm" and cam != null:
		var g := cam.screen_to_ground(mouse_screen, 0.16)
		var gx := g.x * 100.0
		var gy := g.z * 100.0
		inp.aim = atan2(gy - h.y, gx - h.x)
		inp.aim_x = gx
		inp.aim_y = gy
		inp.has_aim_point = true
	else:
		if pad_aim.length() > 0.3:
			_pad_aim = atan2(pad_aim.y, pad_aim.x)
		elif mv.length() > 0.3:
			_pad_aim = atan2(mv.y, mv.x)
		inp.aim = _pad_aim
		inp.has_aim_point = false
	inp.fire = Input.is_action_pressed("fire") and not picking_cards
	if Input.is_action_just_pressed("dash"):
		inp.dash = true
	if Input.is_action_just_pressed("reload"):
		inp.reload = true
	if Input.is_action_just_pressed("gadget"):
		inp.gadget = true
	for i in 3:
		if Input.is_action_just_pressed("card_%d" % (i + 1)):
			inp.card = i
	if device == "pad" and not h.choices.is_empty():
		var btns := [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B]
		for i in 3:
			var down := Input.is_joy_button_pressed(0, btns[i])
			if down and not _edge.get(i, false):
				inp.card = i
			_edge[i] = down
