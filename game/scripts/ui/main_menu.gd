class_name MainMenu
extends Node3D
## 主菜单：右侧是夜里桌面一角的 3D 展示台（选中皮肤 + 初始武器的仓鼠，手电光，台灯，零食箱，远处一只红队鼠），
## 左侧是标题和按钮。复用对局里的 HamsterView，所以看到的就是游戏里的样子。

signal start_requested(opts: Dictionary)
signal quit_requested

const WEAPONS := ["pistol", "ak47", "shotgun"]
const M := "res://assets/models/"

var opts := {"skin": "gold", "weapon": "pistol", "autoplay": false}
var ui: CanvasLayer
var root: Control
var hero: HamsterView
var hero_h: SimHamster
var rival: HamsterView
var rival_h: SimHamster
var cam: Camera3D
var lamp_light: OmniLight3D
var skin_label: Label
var weapon_btns: Array[Button] = []
var buttons: VBoxContainer
var _t := 0.0
var _mouse := Vector2(0.5, 0.5)
var _settings: SettingsPanel


func _ready() -> void:
	PlayerInput.ensure_actions()
	_build_stage()
	_build_ui()
	_refresh_hero()
	Audio.play_ambience(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ---------------------------------------------------------------------------
# 3D 展示台
# ---------------------------------------------------------------------------

func _build_stage() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.035, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.40, 0.34, 0.62)
	e.ambient_light_energy = 0.3
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.5
	e.glow_hdr_threshold = 1.15
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.08
	e.adjustment_contrast = 1.04
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.07, 0.05, 0.11)
	e.fog_depth_begin = 2.6
	e.fog_depth_end = 6.5
	e.fog_density = 1.0
	we.environment = e
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.62, 0.68, 1.0)
	moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-38, -32, 0)
	moon.shadow_enabled = true
	moon.light_specular = 0.0
	add_child(moon)
	cam = Camera3D.new()
	cam.fov = 30.0
	add_child(cam)
	cam.position = Vector3(0.0, 0.62, 2.0)
	cam.look_at(Vector3(-0.1, 0.22, 0.0))
	cam.current = true
	# 地板：木地板（2 m 一块）
	for i in range(-2, 2):
		for j in range(-3, 1):
			_put("env/env_floor_wood", Vector3(i * 2.0 + 1.0, 0, j * 2.0 + 0.6), 0.0, 1.0, 0.0)
	# 远处的墙 + 书架（雾里压暗）
	for i in range(-3, 4):
		_put("env/env_wall", Vector3(i * 2.0, 0, -4.2), 0.0)
		_put("env/env_shelf", Vector3(i * 2.0, 0, -3.78), 0.0)
	# 主角的“舞台光”：左前上方一束暖白聚光（像队友的手电）
	var key := SpotLight3D.new()
	key.light_color = Color(1.0, 0.94, 0.82)
	key.light_energy = 2.3
	key.spot_range = 4.0
	key.spot_angle = 16.0
	key.spot_attenuation = 0.4
	key.shadow_enabled = true
	key.light_specular = 0.0
	add_child(key)
	key.position = Vector3(-0.9, 1.7, 1.6)
	key.look_at(Vector3(0.32, 0.18, 0.0))
	# 台灯（右后）：暖色轮廓光
	_put("props/prop_lamp", Vector3(1.5, 0, -1.7), -0.6)
	lamp_light = OmniLight3D.new()
	lamp_light.light_color = Color(1.0, 0.72, 0.38)
	lamp_light.light_energy = 1.6
	lamp_light.omni_range = 3.2
	lamp_light.omni_attenuation = 1.6
	lamp_light.shadow_enabled = true
	lamp_light.light_specular = 0.0
	lamp_light.position = Vector3(1.45, 0.95, -1.55)
	add_child(lamp_light)
	# 后景：箱子、零食箱、礼物；前景散落瓜子、奶酪、小玩意
	_put("props/prop_box", Vector3(-1.6, 0, -1.9), 0.35)
	_put("props/prop_box", Vector3(-1.45, 0.6, -2.05), -0.2, 0.8)
	_put("props/prop_crate", Vector3(-0.55, 0, -1.25), 0.5, 0.8)
	_put("props/prop_gift", Vector3(1.75, 0, -1.6), -0.4, 0.7)
	_put("props/prop_seed", Vector3(0.62, 0, 0.42), 1.2)
	_put("props/prop_seed", Vector3(0.82, 0, 0.28), 2.6)
	_put("props/prop_seed", Vector3(0.05, 0, 0.62), 0.4)
	_put("props/prop_seed_big", Vector3(-0.3, 0, 0.35), 0.7)
	_put("props/prop_cheese", Vector3(0.5, 0, -0.35), -0.6)
	_put("env/env_deco_marble", Vector3(1.0, 0, 0.75), 0.0)
	_put("env/env_deco_dice", Vector3(1.15, 0, 0.45), 0.5)
	_put("env/env_deco_paperball", Vector3(1.3, 0, -0.2), 0.0)
	# 主角（蓝队）
	hero_h = _fake_ham("blue", 0.3, 0.0)
	hero = HamsterView.new()
	add_child(hero)
	hero.setup(hero_h, true)
	# 远处的红队鼠，躲在箱子后面
	rival_h = _fake_ham("red", 0.95, -1.35)
	rival_h.skin = "stripe"
	rival_h.weapon_id = "shotgun"
	rival_h.aim = deg_to_rad(150.0)
	rival = HamsterView.new()
	add_child(rival)
	rival.setup(rival_h, false)


func _put(module: String, pos: Vector3, yaw: float, sc: float = 1.0, outline: float = 1.6) -> Node3D:
	var n := ToonMaterials.instance(M + module + ".glb", outline)
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * sc
	add_child(n)
	return n


func _fake_ham(team: String, x: float, z: float) -> SimHamster:
	var h := SimHamster.new()
	h.team = team
	h.x = x * 100.0
	h.y = z * 100.0
	h.px = h.x
	h.py = h.y
	h.aim = PI * 0.5 + 0.35
	h.st = {"scale": 1.0}
	return h


func _refresh_hero() -> void:
	hero_h.skin = String(opts.skin)
	hero_h.weapon_id = String(opts.weapon)
	ToonMaterials.set_param(hero.model, "skin_index", maxi(0, Data.skin_ids().find(hero_h.skin)))
	skin_label.text = String(Data.skins().get(hero_h.skin, {}).get("name", hero_h.skin))
	for i in weapon_btns.size():
		weapon_btns[i].button_pressed = WEAPONS[i] == opts.weapon
	hero.on_event({"t": "picked"})


func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport().get_visible_rect().size
	var m := get_viewport().get_mouse_position() / vp
	if Capture.args.has("capture"):
		m = Vector2(0.5, 0.5)
	_mouse = _mouse.lerp(m, 1.0 - exp(-4.0 * delta))
	# 主角朝鼠标方向微微转头，手电跟着扫
	hero_h.aim = PI * 0.5 + 0.35 + (_mouse.x - 0.5) * -0.9
	hero.sync(hero_h, 1.0, delta, true)
	# 红队鼠左右张望
	rival_h.aim = deg_to_rad(150.0 + sin(_t * 0.6) * 25.0)
	rival.sync(rival_h, 1.0, delta, true)
	# 镜头轻微视差 + 呼吸
	cam.position = Vector3(0.0 + (_mouse.x - 0.5) * 0.12, 0.62 + (_mouse.y - 0.5) * -0.05 + sin(_t * 0.5) * 0.008, 2.0)
	cam.look_at(Vector3(-0.1, 0.22, 0.0))
	lamp_light.light_energy = 1.6 + sin(_t * 7.3) * 0.03 + sin(_t * 2.1) * 0.05


# ---------------------------------------------------------------------------
# 界面
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	# 左侧暗角，压住背景让文字清楚
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0.04, 0.025, 0.07, 0.95), Color(0.04, 0.025, 0.07, 0.7), Color(0.04, 0.025, 0.07, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 256
	gt.height = 4
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 1150
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	# 标题
	var left := VBoxContainer.new()
	left.position = Vector2(120, 120)
	left.add_theme_constant_override("separation", 6)
	root.add_child(left)
	var title := UiTheme.label("满载而鼠", 150, UiTheme.CREAM, true, 18)
	title.add_theme_color_override("font_shadow_color", Color(0.94, 0.53, 0.16, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 8)
	title.add_theme_constant_override("shadow_outline_size", 18)
	left.add_child(title)
	var sub := UiTheme.label("夜里的桌面，零食归谁？", 32, UiTheme.GOLD, false, 10)
	left.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 48)
	left.add_child(gap)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	left.add_child(buttons)
	var b_start := _button("开始对战", func() -> void: _start(false))
	b_start.custom_minimum_size = Vector2(360, 0)
	_button("观战：AI 自动对打", func() -> void: _start(true), true)
	_button("设置", _open_settings, true)
	var b_codex := _button("图鉴（下一批）", func() -> void: pass, true)
	b_codex.disabled = true
	_button("退出", func() -> void: quit_requested.emit(), true)
	b_start.call_deferred("grab_focus")
	# 右下：皮肤与初始武器
	var pick := PanelContainer.new()
	pick.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pick.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pick.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pick.offset_right = -80
	pick.offset_bottom = -70
	root.add_child(pick)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	pick.add_child(pv)
	var sh := HBoxContainer.new()
	sh.alignment = BoxContainer.ALIGNMENT_CENTER
	sh.add_theme_constant_override("separation", 14)
	pv.add_child(sh)
	sh.add_child(UiTheme.label("皮肤", 22, UiTheme.SUB))
	sh.add_child(_arrow("‹", -1))
	skin_label = UiTheme.label("金丝熊", 34, UiTheme.CREAM, true, 8)
	skin_label.custom_minimum_size = Vector2(150, 0)
	skin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sh.add_child(skin_label)
	sh.add_child(_arrow("›", 1))
	pv.add_child(UiTheme.label("初始武器（试玩用，正式版固定手枪起步）", 18, UiTheme.SUB, false, 4))
	var wh := HBoxContainer.new()
	wh.add_theme_constant_override("separation", 10)
	pv.add_child(wh)
	var grp := ButtonGroup.new()
	for w in WEAPONS:
		var b := Button.new()
		b.theme_type_variation = "GhostButton"
		b.toggle_mode = true
		b.button_group = grp
		b.text = String(Data.weapon(w).get("name", w))
		var ip := "res://assets/icons/wpn_%s.png" % w
		if ResourceLoader.exists(ip):
			b.icon = load(ip)
			b.expand_icon = false
			b.add_theme_constant_override("icon_max_width", 56)
		b.pressed.connect(func() -> void:
			opts.weapon = w
			Audio.play2d("pump" if w == "shotgun" else "reload_pistol", -10.0)
			_refresh_hero())
		wh.add_child(b)
		weapon_btns.append(b)
	# 左下：操作说明 + 版本
	var help := UiTheme.label("WASD 移动 · 鼠标瞄准 · 左键射击 · 空格翻滚 · R 换弹 · Q 手雷 · 1/2/3 选升级 · Esc 暂停     手柄也可以玩", 18, UiTheme.SUB, false, 4)
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.offset_left = 120
	help.offset_bottom = -40
	root.add_child(help)
	var ver := UiTheme.label("v" + String(ProjectSettings.get_setting("application/config/version", "")), 16, Color(1, 1, 1, 0.35), false, 0)
	ver.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ver.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ver.offset_right = -24
	ver.offset_top = 16
	root.add_child(ver)


func _button(text: String, cb: Callable, ghost: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	if ghost:
		b.theme_type_variation = "GhostButton"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void:
		Audio.play2d("ui_click", -6.0)
		cb.call())
	b.mouse_entered.connect(func() -> void: Audio.play2d("ui_hover", -14.0, 0.05, 0.05))
	buttons.add_child(b)
	return b


func _arrow(text: String, dir: int) -> Button:
	var b := Button.new()
	b.theme_type_variation = "GhostButton"
	b.text = text
	b.custom_minimum_size = Vector2(52, 0)
	b.pressed.connect(func() -> void:
		var ids := Data.skin_ids()
		var i := ids.find(String(opts.skin))
		opts.skin = ids[(i + dir + ids.size()) % ids.size()]
		Audio.play2d("ui_click", -8.0)
		_refresh_hero())
	return b


func _open_settings() -> void:
	if _settings != null:
		return
	_settings = SettingsPanel.new()
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	cc.add_child(_settings)
	buttons.visible = false
	_settings.closed.connect(func() -> void:
		cc.queue_free()
		_settings = null
		buttons.visible = true
		(buttons.get_child(2) as Button).grab_focus())


func _start(autoplay: bool) -> void:
	var o := opts.duplicate()
	o.autoplay = autoplay
	start_requested.emit(o)
