class_name SettingsPanel
extends PanelContainer
## 设置面板（主菜单和暂停菜单共用）：总音量、音效、环境音、特效强度、伤害数字、全屏。

signal closed


func _ready() -> void:
	theme = UiTheme.theme()
	custom_minimum_size = Vector2(620, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var title := UiTheme.label("设置", 46, UiTheme.GOLD, true, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_slider(v, "总音量", Settings.master_volume, 0.0, 1.0, func(x: float) -> void: Settings.master_volume = x)
	_slider(v, "音效", Settings.sfx_volume, 0.0, 1.0, func(x: float) -> void: Settings.sfx_volume = x)
	_slider(v, "环境音", Settings.music_volume, 0.0, 1.0, func(x: float) -> void: Settings.music_volume = x)
	_slider(v, "特效强度", Settings.fx_strength, 0.3, 1.5, func(x: float) -> void: Settings.fx_strength = x)
	_check(v, "显示伤害数字", Settings.show_damage_numbers, func(b: bool) -> void: Settings.show_damage_numbers = b)
	_check(v, "全屏", Settings.fullscreen, func(b: bool) -> void: Settings.fullscreen = b)
	var ok := Button.new()
	ok.text = "好的"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_close)
	v.add_child(ok)
	ok.call_deferred("grab_focus")


func _row(v: VBoxContainer, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	var l := UiTheme.label(text, 24)
	l.custom_minimum_size = Vector2(170, 0)
	h.add_child(l)
	v.add_child(h)
	return h


func _slider(v: VBoxContainer, text: String, val: float, lo: float, hi: float, cb: Callable) -> void:
	var h := _row(v, text)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = val
	s.custom_minimum_size = Vector2(300, 32)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pct := UiTheme.label("%d%%" % roundi(val * 100.0), 22, UiTheme.SUB)
	pct.custom_minimum_size = Vector2(72, 0)
	s.value_changed.connect(func(x: float) -> void:
		cb.call(x)
		pct.text = "%d%%" % roundi(x * 100.0)
		Settings.apply())
	h.add_child(s)
	h.add_child(pct)


func _check(v: VBoxContainer, text: String, val: bool, cb: Callable) -> void:
	var h := _row(v, text)
	var c := CheckButton.new()
	c.button_pressed = val
	c.toggled.connect(func(b: bool) -> void:
		cb.call(b)
		Settings.apply()
		Audio.play2d("ui_click", -8.0))
	h.add_child(c)


func _close() -> void:
	Settings.save_cfg()
	Audio.play2d("ui_click", -6.0)
	closed.emit()
	queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
