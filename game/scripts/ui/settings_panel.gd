class_name SettingsPanel
extends PanelContainer
## 设置面板（主菜单和暂停菜单共用）：画面 / 声音 / 操作 三页。

signal closed

var pages := {}
var tab_btns := {}


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
	_slider(pa, "环境音", Settings.music_volume, 0.0, 1.0, func(x: float) -> void: Settings.music_volume = x)
	var pc: VBoxContainer = pages.controls
	var rows := [
		["移动", "WASD", "左摇杆", "方向键"], ["瞄准", "鼠标", "右摇杆（不推时自动瞄准）", "自动瞄准"],
		["射击", "鼠标左键", "RT", "回车"], ["翻滚", "空格", "A", "右 Shift"], ["换弹", "R", "X", "/"],
		["道具", "Q", "LB", "."], ["选升级", "1 / 2 / 3", "X / Y / B", "8 / 9 / 0"], ["暂停", "Esc", "Start", "Esc"],
	]
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 8)
	pc.add_child(grid)
	for hd in ["", "键鼠", "手柄", "2P 方向键"]:
		grid.add_child(UiTheme.label(hd, 22, UiTheme.GOLD, true, 4))
	for r in rows:
		for i in 4:
			grid.add_child(UiTheme.label(String(r[i]), 20, UiTheme.CREAM if i > 0 else UiTheme.SUB, false, 0))
	var note := UiTheme.label("按键自定义会在后续版本加入。手柄按任意键即可切换到手柄操作。", 17, UiTheme.SUB, false, 0)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(680, 0)
	pc.add_child(note)
	var ok := Button.new()
	ok.text = "好的"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_close)
	v.add_child(ok)
	_show("video")
	ok.call_deferred("grab_focus")


func _show(key: String) -> void:
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
