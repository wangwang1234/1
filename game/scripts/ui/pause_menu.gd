class_name PauseMenu
extends CanvasLayer
## 暂停菜单：继续 / 设置 / 重新开始 / 返回主菜单 + 操作说明。暂停时逻辑停走（MatchView.set_paused）。

signal resume_requested
signal restart_requested
signal menu_requested

var root: Control
var box: VBoxContainer
var _settings: SettingsPanel
var _t := 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.025, 0.07, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	cc.add_child(panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := UiTheme.label("暂停", 64, UiTheme.GOLD, true, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var b := _btn("继续", func() -> void: resume_requested.emit())
	_btn("设置", _open_settings, true)
	_btn("重新开始", func() -> void: restart_requested.emit(), true)
	_btn("返回主菜单", func() -> void: menu_requested.emit(), true)
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 18)
	box.add_child(sep)
	var help := UiTheme.label(
		"键鼠：WASD 移动 · 鼠标瞄准 · 左键射击 · 空格翻滚\nR 换弹 · Q 手雷 · 1 / 2 / 3 选升级卡 · Esc 暂停\n手柄：左摇杆移动 · 右摇杆瞄准 · RT 射击 · A 翻滚\nX 换弹 · LB 手雷 · X / Y / B 选升级卡 · Start 暂停", 19, UiTheme.SUB, false, 4)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)
	b.call_deferred("grab_focus")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _btn(text: String, cb: Callable, ghost: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	if ghost:
		b.theme_type_variation = "GhostButton"
	b.custom_minimum_size = Vector2(320, 0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void:
		Audio.play2d("ui_click", -6.0)
		cb.call())
	b.mouse_entered.connect(func() -> void: Audio.play2d("ui_hover", -14.0, 0.05, 0.05))
	box.add_child(b)
	return b


func _open_settings() -> void:
	if _settings != null:
		return
	_settings = SettingsPanel.new()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	cc.add_child(_settings)
	box.get_parent().visible = false
	_settings.closed.connect(func() -> void:
		cc.queue_free()
		_settings = null
		box.get_parent().visible = true
		(box.get_child(2) as Button).grab_focus())


func _unhandled_input(ev: InputEvent) -> void:
	if _settings == null and ev.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()
