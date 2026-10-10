class_name PlayerInput
extends RefCounted
## 玩家输入 → SimHamster.HamInput。三种方案：
## - kbm：WASD 移动、鼠标瞄准（开火时带轻微辅助瞄准，强度见设置）、左键射击、空格翻滚、R 换弹、Q 道具、1/2/3 选卡（单人时也接手柄 0 号）
## - pad：左摇杆移动、右摇杆瞄准（不推右摇杆时自动瞄准最近的敌人）、RT 射击、A 翻滚、X 换弹、LB 道具、X/Y/B 选卡
## - keys2（本地 2P 方向键）：方向键移动、回车射击（自动瞄准）、右 Shift 翻滚、/ 换弹、. 道具、8/9/0 选卡

const ACTIONS := {
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"dash": [KEY_SPACE], "reload": [KEY_R], "gadget": [KEY_Q], "card_1": [KEY_1], "card_2": [KEY_2], "card_3": [KEY_3], "pause": [KEY_ESCAPE, KEY_P],
}
const KEYS_P1 := {"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D, "dash": KEY_SPACE, "reload": KEY_R, "gadget": KEY_Q, "card": [KEY_1, KEY_2, KEY_3]}
const KEYS_P2 := {"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "fire": KEY_ENTER, "dash": KEY_SHIFT, "reload": KEY_SLASH, "gadget": KEY_PERIOD, "card": [KEY_8, KEY_9, KEY_0]}

var scheme := "kbm"      # kbm / pad / keys2
var device := "kbm"      # 当前实际在用的设备（kbm 方案里接上手柄会切到 pad）
var pad_index := 0
var allow_pad := true    # kbm 方案是否同时接手柄（2P 用手柄时，手柄归 2P）
var arrows := true       # kbm 方案是否也认方向键（2P 用方向键时方向键归 2P）
var _pad_aim := 0.0
var _edge := {}
var _press_on_card := false   # 这次左键是按在升级卡上按下去的（那就是选卡，按住期间不开火）
## 右 Shift 是否按着（Input 分不清左右 Shift，所以由 MatchView._input 按按键事件的 location 记下来；2P 方向键方案的翻滚只认右 Shift）
static var right_shift_down := false
## 手动瞄准辅助强度（Settings.apply 按设置写入；鼠标和推右摇杆时生效，自动瞄准时不叠加）
static var assist_level := 1.0


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


func _key(k: int) -> bool:
	return Input.is_physical_key_pressed(k)


func _pressed_edge(name: String, down: bool) -> bool:
	var was := bool(_edge.get(name, false))
	_edge[name] = down
	return down and not was


func poll(h: SimHamster, cam: GameCamera, mouse_screen: Vector2, over_card: bool, w: SimWorld = null) -> void:
	## over_card：鼠标正停在升级卡上（这时左键是选卡，不开火；其余时候选卡期间照样能射击）
	if h == null:
		return
	var inp := h.inp
	var mv := Vector2.ZERO
	var pad_mv := Vector2.ZERO
	var pad_aim := Vector2.ZERO
	var use_pad := scheme == "pad" or (scheme == "kbm" and allow_pad)
	if use_pad:
		pad_mv = Vector2(Input.get_joy_axis(pad_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad_index, JOY_AXIS_LEFT_Y))
		pad_aim = Vector2(Input.get_joy_axis(pad_index, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad_index, JOY_AXIS_RIGHT_Y))
	match scheme:
		"keys2":
			device = "keys2"
			mv = Vector2(float(_key(KEYS_P2.right)) - float(_key(KEYS_P2.left)), float(_key(KEYS_P2.down)) - float(_key(KEYS_P2.up)))
		"pad":
			device = "pad"
			mv = pad_mv if pad_mv.length() > 0.2 else Vector2.ZERO
		_:
			mv = Vector2(float(_key(KEY_D) or (arrows and _key(KEY_RIGHT))) - float(_key(KEY_A) or (arrows and _key(KEY_LEFT))),
				float(_key(KEY_S) or (arrows and _key(KEY_DOWN))) - float(_key(KEY_W) or (arrows and _key(KEY_UP))))
			if use_pad and (pad_mv.length() > 0.25 or pad_aim.length() > 0.3):
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
		inp.assist = assist_level
	else:
		inp.assist = 0.0
		if pad_aim.length() > 0.3:
			_pad_aim = atan2(pad_aim.y, pad_aim.x)
			inp.assist = assist_level
		else:
			# 没推右摇杆 / 方向键：自动瞄准射程内最近的敌人，没有就朝移动方向
			var t: SimEntity = SimWeapons.auto_aim(w, h, maxf(300.0, minf(SimWeapons.range_of(h), 640.0))) if w != null else null
			if t != null:
				_pad_aim = atan2(t.y - h.y, t.x - h.x)
			elif mv.length() > 0.3:
				_pad_aim = atan2(mv.y, mv.x)
		inp.aim = _pad_aim
		inp.has_aim_point = false
	var fire := false
	match scheme:
		"keys2":
			fire = _key(KEYS_P2.fire)
		"pad":
			fire = Input.get_joy_axis(pad_index, JOY_AXIS_TRIGGER_RIGHT) > 0.4 or Input.is_joy_button_pressed(pad_index, JOY_BUTTON_RIGHT_SHOULDER)
		_:
			fire = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (use_pad and Input.get_joy_axis(pad_index, JOY_AXIS_TRIGGER_RIGHT) > 0.4)
	# 选卡期间照样能射击：只有在升级卡上按下的那一下算选卡；从卡外按住开火、准星扫过卡片时不会断火
	var lmb := device == "kbm" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if _pressed_edge("lmb", lmb):
		_press_on_card = over_card
	elif not lmb:
		_press_on_card = false
	inp.fire = fire and not _press_on_card
	var K: Dictionary = KEYS_P2 if scheme == "keys2" else KEYS_P1
	var kb := scheme != "pad"
	var kb_dash := right_shift_down if scheme == "keys2" else _key(K.dash)
	var dash := (kb and kb_dash) or (use_pad and Input.is_joy_button_pressed(pad_index, JOY_BUTTON_A))
	var reload := (kb and _key(K.reload)) or (use_pad and Input.is_joy_button_pressed(pad_index, JOY_BUTTON_X) and h.choices.is_empty())
	var gadget := (kb and _key(K.gadget)) or (use_pad and Input.is_joy_button_pressed(pad_index, JOY_BUTTON_LEFT_SHOULDER))
	if _pressed_edge("dash", dash):
		inp.dash = true
	if _pressed_edge("reload", reload):
		inp.reload = true
	if _pressed_edge("gadget", gadget):
		inp.gadget = true
	for i in 3:
		var down := kb and _key(int(K.card[i]))
		if _pressed_edge("card%d" % i, down):
			inp.card = i
	if use_pad and not h.choices.is_empty():
		var btns := [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B]
		for i in 3:
			if _pressed_edge("pcard%d" % i, Input.is_joy_button_pressed(pad_index, btns[i])):
				inp.card = i
				device = "pad"


static func track_key(ev: InputEvent) -> void:
	## 由 MatchView._input 调用：记录右 Shift 的按下 / 松开（左 Shift 不算）
	var k := ev as InputEventKey
	if k == null or k.echo or k.physical_keycode != KEY_SHIFT:
		return
	# 平台报不出左右（UNSPECIFIED）时按右 Shift 处理，至少不比以前差
	if k.location != KEY_LOCATION_LEFT:
		right_shift_down = k.pressed


func card_hint() -> String:
	match device:
		"pad":
			return "按 X / Y / B 选升级，不耽误射击"
		"keys2":
			return "按 8 / 9 / 0 选升级，不耽误射击"
	return "按 1 / 2 / 3 选升级，不耽误射击"


func gadget_key() -> String:
	match device:
		"pad":
			return "LB"
		"keys2":
			return "."
	return "Q"
