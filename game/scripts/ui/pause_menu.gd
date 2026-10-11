class_name PauseMenu
extends CanvasLayer


signal resume_requested
signal restart_requested
signal menu_requested

var root: Control
var box: VBoxContainer
var _settings: SettingsPanel
var _t: = 0.0
var help: Label
var networked: = false


func _ready() -> void :
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.theme()
	add_child(root)
	var dim: = ColorRect.new()
	dim.color = Color(0.04, 0.025, 0.07, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc: = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	cc.add_child(panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title: = UiTheme.label("联机菜单" if networked else "暂停", 64, UiTheme.GOLD, true, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var b: = _btn("继续", func() -> void : resume_requested.emit())
	_btn("设置", _open_settings, true)
	var restart: = _btn("返回房间" if networked else "重新开始", func() -> void : restart_requested.emit(), true)
	if networked:
		restart.disabled = not LanSession.is_host()
		box.add_child(UiTheme.label("对局继续进行；菜单打开时，你的角色停止操作。", 18, UiTheme.SUB))
	_btn("返回主菜单", func() -> void : menu_requested.emit(), true)
	var sep: = HSeparator.new()
	sep.add_theme_constant_override("separation", 18)
	box.add_child(sep)
	help = UiTheme.label("", 19, UiTheme.SUB, false, 4)
	_refresh_help()
	Settings.controls_changed.connect(_refresh_help)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)
	b.call_deferred("grab_focus")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _btn(text: String, cb: Callable, ghost: bool = false) -> Button:
	var b: = Button.new()
	b.text = text
	if ghost:
		b.theme_type_variation = "GhostButton"
	b.custom_minimum_size = Vector2(320, 0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect( func() -> void :
		Audio.play2d("ui_click", -6.0)
		cb.call())
	b.mouse_entered.connect( func() -> void : Audio.play2d("ui_hover", -14.0, 0.05, 0.05))
	box.add_child(b)
	return b


func _open_settings() -> void :
	if _settings != null:
		return
	_settings = SettingsPanel.new()
	var cc: = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	cc.add_child(_settings)
	box.get_parent().visible = false
	_settings.closed.connect( func() -> void :
		cc.queue_free()
		_settings = null
		box.get_parent().visible = true
		(box.get_child(2) as Button).grab_focus())


func _unhandled_input(ev: InputEvent) -> void :
	if _settings == null and ev.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()


func _refresh_help() -> void:
	help.text = InputBindings.help() + "\n" + InputBindings.caption("p1", "pause") + " / Esc 打开菜单 · 死亡后自动观战己方队友\n手柄：左摇杆移动 · 右摇杆瞄准 · RT 射击 · A 翻滚\nX 换弹 · LB 道具 · X / Y / B 选升级 · 十字键左右切换观战"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size.x = 510
