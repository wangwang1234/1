extends "res://tests/test_case.gd"

func test_bindings_conflict_restore_and_corrupt_save() -> void:
	InputBindings.load_saved({})
	eq(InputBindings.assign("p1", "dash", KEY_F), "", "可重新绑定翻滚")
	eq(InputBindings.code("p1", "dash"), KEY_F, "新键位生效")
	check(InputBindings.assign("p1", "reload", KEY_F) != "", "拒绝冲突")
	check(InputBindings.assign("p1", "fire", KEY_ESCAPE) != "", "Esc 保留返回")
	eq(InputBindings.assign("p1", "gadget", -MOUSE_BUTTON_XBUTTON1), "", "支持鼠标侧键")
	var saved := InputBindings.bindings.duplicate(true)
	InputBindings.load_saved(saved)
	eq(InputBindings.code("p1", "gadget"), -MOUSE_BUTTON_XBUTTON1, "保存配置可恢复")
	saved.p1.reload = KEY_F
	InputBindings.load_saved(saved)
	eq(InputBindings.code("p1", "dash"), KEY_SPACE, "损坏配置整组回退")
	InputBindings.restore("p1")
	InputBindings.restore("p2")

func test_action_map_is_idempotent_and_esc_fallback() -> void:
	InputBindings.load_saved({})
	InputBindings.assign("p1", "pause", KEY_TAB)
	PlayerInput.ensure_actions()
	PlayerInput.ensure_actions()
	eq(InputMap.action_get_events("pause").size(), 3, "菜单键、Esc、Start 不重复")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_TAB
	ev.pressed = true
	check(ev.is_action_pressed("pause"), "菜单新键生效")
	ev.physical_keycode = KEY_ESCAPE
	check(ev.is_action_pressed("pause"), "Esc 始终可返回")
	InputBindings.restore("p1")

func test_resume_suppresses_held_commands_until_release() -> void:
	var pin := PlayerInput.new()
	pin._blocked = {"fire": true, "pad_dash": true}
	check(not pin._gate("fire", true), "恢复后按住射击不发射")
	check(not pin._gate("fire", true), "持续按住仍抑制")
	check(not pin._gate("fire", false), "松开解除屏蔽")
	check(pin._gate("fire", true), "新按下恢复射击")
	check(not pin._gate("pad_dash", true), "手柄翻滚同样屏蔽")
	pin._gate("pad_dash", false)
	check(pin._gate("pad_dash", true), "手柄松开后可翻滚")

func test_card_and_gadget_hints_follow_profile() -> void:
	InputBindings.load_saved({})
	InputBindings.assign("p1", "card_1", KEY_F)
	InputBindings.assign("p1", "gadget", KEY_G)
	var pin := PlayerInput.new()
	eq(pin.card_keys()[0], "F", "卡牌提示读取新键位")
	eq(pin.gadget_key(), "G", "道具提示读取新键位")
	pin.scheme = "keys2"
	pin.device = "keys2"
	eq(pin.card_keys(), ["8", "9", "0"], "2P 卡牌提示正确")
	pin.device = "pad"
	eq(pin.card_keys(), ["X", "Y", "B"], "手柄提示保持布局")
	InputBindings.load_saved({})
	InputBindings.apply_actions()
