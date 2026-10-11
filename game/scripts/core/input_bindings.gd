class_name InputBindings
extends RefCounted
## 键鼠动作映射。P1、P2 分开保存，手柄保持原有布局。

const LABELS := {"move_up": "向前移动", "move_down": "向后移动", "move_left": "向左移动", "move_right": "向右移动", "fire": "射击", "dash": "翻滚", "reload": "换弹", "gadget": "使用道具", "card_1": "选择升级 1", "card_2": "选择升级 2", "card_3": "选择升级 3", "spectate_prev": "观战上一位", "spectate_next": "观战下一位", "pause": "打开菜单"}
const DEFAULTS := {
	"p1": {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "fire": -MOUSE_BUTTON_LEFT, "dash": KEY_SPACE, "reload": KEY_R, "gadget": KEY_Q, "card_1": KEY_1, "card_2": KEY_2, "card_3": KEY_3, "spectate_prev": KEY_BRACKETLEFT, "spectate_next": KEY_BRACKETRIGHT, "pause": KEY_ESCAPE},
	"p2": {"move_up": KEY_UP, "move_down": KEY_DOWN, "move_left": KEY_LEFT, "move_right": KEY_RIGHT, "fire": KEY_ENTER, "dash": KEY_SHIFT, "reload": KEY_SLASH, "gadget": KEY_PERIOD, "card_1": KEY_8, "card_2": KEY_9, "card_3": KEY_0, "spectate_prev": KEY_5, "spectate_next": KEY_6},
}
static var bindings: Dictionary = DEFAULTS.duplicate(true)

static func valid_code(code: int) -> bool:
	return (code > 0 and OS.get_keycode_string(code) != "") or code in [-MOUSE_BUTTON_LEFT, -MOUSE_BUTTON_RIGHT, -MOUSE_BUTTON_MIDDLE, -MOUSE_BUTTON_XBUTTON1, -MOUSE_BUTTON_XBUTTON2]

static func code(profile: String, action: String) -> int:
	return int(bindings.get(profile, {}).get(action, DEFAULTS.get(profile, {}).get(action, 0)))

static func caption(profile: String, action: String, compact: bool = false) -> String:
	var k := code(profile, action)
	if k < 0:
		if compact:
			return {-1: "左键", -2: "右键", -3: "中键", -8: "侧键1", -9: "侧键2"}.get(k, "鼠标键")
		return {-1: "鼠标左键", -2: "鼠标右键", -3: "鼠标中键", -8: "鼠标侧键 1", -9: "鼠标侧键 2"}.get(k, "鼠标键")
	if profile == "p2" and k == KEY_SHIFT:
		return "右 Shift"
	return {KEY_SPACE: "空格", KEY_ENTER: "回车", KEY_UP: "↑", KEY_DOWN: "↓", KEY_LEFT: "←", KEY_RIGHT: "→", KEY_BRACKETLEFT: "[", KEY_BRACKETRIGHT: "]", KEY_SLASH: "/", KEY_PERIOD: ".", KEY_ESCAPE: "Esc"}.get(k, OS.get_keycode_string(k))

static func conflict(profile: String, action: String, k: int) -> String:
	if k == KEY_ESCAPE and action != "pause":
		return "Esc 保留用于返回菜单"
	for a in DEFAULTS[profile]:
		if a != action and code(profile, a) == k:
			return "已用于「%s」" % LABELS[a]
	return ""

static func assign(profile: String, action: String, k: int) -> String:
	if not DEFAULTS.has(profile) or not DEFAULTS[profile].has(action) or not valid_code(k):
		return "不支持这个按键"
	var reason := conflict(profile, action, k)
	if reason != "":
		return reason
	bindings[profile][action] = k
	apply_actions()
	return ""

static func restore(profile: String) -> void:
	bindings[profile] = DEFAULTS[profile].duplicate()
	apply_actions()

static func load_saved(saved: Variant) -> void:
	bindings = DEFAULTS.duplicate(true)
	if not saved is Dictionary:
		return
	# Validate whole profiles: malformed/duplicate bindings fall back safely.
	for p in DEFAULTS:
		if not saved.get(p) is Dictionary:
			continue
		var candidate: Dictionary = DEFAULTS[p].duplicate()
		var seen := {}
		var valid := true
		for a in candidate:
			var v: Variant = saved[p].get(a, candidate[a])
			if not v is int or not valid_code(v) or seen.has(v) or (v == KEY_ESCAPE and a != "pause"):
				valid = false
				break
			candidate[a] = v
			seen[v] = true
		if valid:
			bindings[p] = candidate

static func apply_actions() -> void:
	for a in DEFAULTS.p1:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		InputMap.action_erase_events(a)
		var k := code("p1", a)
		var ev: InputEvent
		if k < 0:
			var mb := InputEventMouseButton.new()
			mb.button_index = -k
			ev = mb
		else:
			var key := InputEventKey.new()
			key.physical_keycode = k
			ev = key
		InputMap.action_add_event(a, ev)
	# Esc is always an escape route even if the gameplay menu key changes.
	if code("p1", "pause") != KEY_ESCAPE:
		var esc := InputEventKey.new()
		esc.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", esc)
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	InputMap.action_add_event("pause", start)

static func down(profile: String, action: String) -> bool:
	var k := code(profile, action)
	if k < 0:
		return Input.is_mouse_button_pressed(-k)
	if profile == "p2" and k == KEY_SHIFT:
		return PlayerInput.right_shift_down
	return Input.is_physical_key_pressed(k)

static func event_matches(profile: String, action: String, ev: InputEvent) -> bool:
	var k := code(profile, action)
	if ev is InputEventKey:
		var key := ev as InputEventKey
		return key.pressed and not key.echo and key.physical_keycode == k and not (profile == "p2" and k == KEY_SHIFT and key.location == KEY_LOCATION_LEFT)
	if ev is InputEventMouseButton:
		return ev.pressed and -ev.button_index == k
	return false

static func help(profile: String = "p1") -> String:
	return "%s/%s/%s/%s 移动 · %s 射击 · %s 翻滚 · %s 换弹 · %s 道具 · %s/%s/%s 选升级" % [caption(profile, "move_up"), caption(profile, "move_left"), caption(profile, "move_down"), caption(profile, "move_right"), caption(profile, "fire"), caption(profile, "dash"), caption(profile, "reload"), caption(profile, "gadget"), caption(profile, "card_1"), caption(profile, "card_2"), caption(profile, "card_3")]
