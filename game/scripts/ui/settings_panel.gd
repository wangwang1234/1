class_name SettingsPanel
extends PanelContainer
## 设置面板（主菜单和暂停菜单共用）：画面 / 声音 / 操作 三页。

signal closed

var pages := {}
var tab_btns := {}
var binding_profile := "p1"
var binding_buttons := {}
var binding_status: Label
var capture_action := ""


func _ready() -> void:
	theme = UiTheme.theme()
	custom_minimum_size = Vector2(760, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var title := UiTheme.label("设置", 46, UiTheme.GOLD, true, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	var grp := ButtonGroup.new()
	for t in [["video", "画面"], ["audio", "声音"], ["controls", "操作"]]:
		var b := Button.new()
		b.theme_type_variation = "GhostButton"
		b.toggle_mode = true
		b.button_group = grp
		b.text = t[1]
		b.custom_minimum_size = Vector2(120, 0)
		var key: String = t[0]
		b.pressed.connect(func() -> void:
			Audio.play2d("ui_click", -8.0)
			_show(key))
		tabs.add_child(b)
		tab_btns[key] = b
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 12)
		page.custom_minimum_size = Vector2(0, 360)
		v.add_child(page)
		pages[key] = page
	var pv: VBoxContainer = pages.video
	_slider(pv, "特效强度", Settings.fx_strength, 0.3, 1.5, func(x: float) -> void: Settings.fx_strength = x)
	_slider(pv, "屏幕震动", Settings.shake, 0.0, 1.5, func(x: float) -> void: Settings.shake = x)
	_slider(pv, "渲染精度", Settings.render_scale, 0.5, 1.0, func(x: float) -> void: Settings.render_scale = x)
	_check(pv, "显示伤害数字", Settings.show_damage_numbers, func(b: bool) -> void: Settings.show_damage_numbers = b)
	_check(pv, "显示帧率", Settings.show_fps, func(b: bool) -> void: Settings.show_fps = b)
	_check(pv, "全屏", Settings.fullscreen, func(b: bool) -> void: Settings.fullscreen = b)
	_check(pv, "垂直同步", Settings.vsync, func(b: bool) -> void: Settings.vsync = b)
	var pa: VBoxContainer = pages.audio
	_slider(pa, "总音量", Settings.master_volume, 0.0, 1.0, func(x: float) -> void: Settings.master_volume = x)
	_slider(pa, "音效", Settings.sfx_volume, 0.0, 1.0, func(x: float) -> void: Settings.sfx_volume = x)
	_slider(pa, "音乐", Settings.music_volume, 0.0, 1.0, func(x: float) -> void: Settings.music_volume = x)
	_check(pa, "切到后台静音", Settings.mute_background, func(b: bool) -> void: Settings.mute_background = b)
	var pc: VBoxContainer = pages.controls
	var profiles := _row(pc, "键位配置")
	var pick := OptionButton.new()
	pick.add_item("玩家 1（键鼠 / 联机）")
	pick.add_item("玩家 2（同机键盘）")
	pick.item_selected.connect(func(i: int) -> void:
		capture_action = ""
		binding_profile = "p1" if i == 0 else "p2"
		_refresh_bindings())
	profiles.add_child(pick)
	var reset := Button.new()
	reset.text = "恢复本组默认"
	reset.pressed.connect(func() -> void:
		capture_action = ""
		InputBindings.restore(binding_profile)
		Settings.controls_changed.emit()
		Settings.save_cfg()
		_refresh_bindings())
	profiles.add_child(reset)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for action in InputBindings.LABELS:
		var row := _row(rows, String(InputBindings.LABELS[action]))
		var button := Button.new()
		button.custom_minimum_size.x = 290
		button.add_theme_font_size_override("font_size", 20)
		var a: String = action
		button.pressed.connect(func() -> void:
			capture_action = a
			binding_status.text = "请按键盘或鼠标按钮；Esc 取消，Delete 设为默认。"
			button.text = "等待按键…")
		binding_buttons[a] = button
		row.add_child(button)
	binding_status = UiTheme.label("", 17, UiTheme.SUB)
	binding_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binding_status.custom_minimum_size.x = 700
	pc.add_child(binding_status)
	_refresh_bindings()

	var ok := Button.new()
	ok.text = "好的"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_close)
	v.add_child(ok)
	_show("video")
	ok.call_deferred("grab_focus")


func _show(key: String) -> void:
	capture_action = ""
	_refresh_bindings()
	for k in pages:
		(pages[k] as Control).visible = k == key
	(tab_btns[key] as Button).button_pressed = true


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
	s.custom_minimum_size = Vector2(340, 32)
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
	c.theme_type_variation = "GhostButton"    # 开 = 橙边高亮、关 = 暗底，一眼分得清
	c.custom_minimum_size = Vector2(128, 0)
	c.button_pressed = val
	c.text = "开" if val else "关"
	c.toggled.connect(func(b: bool) -> void:
		c.text = "开" if b else "关"
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


func _refresh_bindings() -> void:
	if binding_status == null:
		return
	for a in binding_buttons:
		var button: Button = binding_buttons[a]
		button.get_parent().visible = InputBindings.DEFAULTS[binding_profile].has(a)
		button.text = InputBindings.caption(binding_profile, a) if InputBindings.DEFAULTS[binding_profile].has(a) else ""
	binding_status.text = "点击按键修改；支持鼠标侧键。同机双人请避免两组使用同一个键。手柄保持原有布局。"

func _input(ev: InputEvent) -> void:
	if capture_action == "":
		return
	# Consume the whole capture gesture, including release events.
	get_viewport().set_input_as_handled()
	var key := 0
	if ev is InputEventKey:
		if not ev.pressed or ev.echo:
			return
		if ev.physical_keycode == KEY_ESCAPE:
			capture_action = ""
			_refresh_bindings()
			return
		key = ev.physical_keycode
		if key == KEY_DELETE:
			key = InputBindings.DEFAULTS[binding_profile][capture_action]
		elif binding_profile == "p2" and key == KEY_SHIFT and ev.location == KEY_LOCATION_LEFT:
			binding_status.text = "玩家 2 请使用右 Shift，或选择其他按键。"
			return
	elif ev is InputEventMouseButton:
		if not ev.pressed:
			return
		key = -ev.button_index
	else:
		return
	var error := InputBindings.assign(binding_profile, capture_action, key)
	if error != "":
		binding_status.text = error + "；请选择其他键，或按 Esc 取消。"
		return
	capture_action = ""
	_refresh_bindings()
	Settings.controls_changed.emit()
	Settings.save_cfg()
