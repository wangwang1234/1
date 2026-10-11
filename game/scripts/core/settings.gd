extends Node
## 设置（自动加载 Settings）：音量、特效强度、震屏、伤害数字、帧率显示、全屏、垂直同步、渲染比例，以及开局大厅上次的选择。
## 保存在 user://settings.cfg，包括 P1 / P2 自定义键位。

signal controls_changed

const PATH := "user://settings.cfg"

var master_volume := 1.0
var sfx_volume := 1.0
var music_volume := 0.7
var mute_background := false
var _background := false
var fx_strength := 1.0
var show_damage_numbers := true
var fullscreen := false
var shake := 1.0
var show_fps := false
var vsync := true
var render_scale := 1.0
var lobby := {}               # 开局大厅上次的选择


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_cfg()
	InputBindings.apply_actions()
	apply()


func load_cfg() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	master_volume = float(c.get_value("audio", "master", master_volume))
	sfx_volume = float(c.get_value("audio", "sfx", sfx_volume))
	music_volume = float(c.get_value("audio", "music", music_volume))
	mute_background = bool(c.get_value("audio", "mute_background", false))
	InputBindings.load_saved(c.get_value("controls", "bindings", {}))
	fx_strength = float(c.get_value("game", "fx", fx_strength))
	show_damage_numbers = bool(c.get_value("game", "numbers", show_damage_numbers))
	fullscreen = bool(c.get_value("video", "fullscreen", fullscreen))
	shake = float(c.get_value("game", "shake", shake))
	show_fps = bool(c.get_value("game", "fps", show_fps))
	vsync = bool(c.get_value("video", "vsync", vsync))
	render_scale = float(c.get_value("video", "scale", render_scale))
	lobby = c.get_value("lobby", "last", {})


func save_cfg() -> void:
	var c := ConfigFile.new()
	c.set_value("audio", "master", master_volume)
	c.set_value("audio", "sfx", sfx_volume)
	c.set_value("audio", "music", music_volume)
	c.set_value("audio", "mute_background", mute_background)
	c.set_value("controls", "bindings", InputBindings.bindings)
	c.set_value("game", "fx", fx_strength)
	c.set_value("game", "numbers", show_damage_numbers)
	c.set_value("video", "fullscreen", fullscreen)
	c.set_value("game", "shake", shake)
	c.set_value("game", "fps", show_fps)
	c.set_value("video", "vsync", vsync)
	c.set_value("video", "scale", render_scale)
	c.set_value("lobby", "last", lobby)
	c.save(PATH)


func apply() -> void:
	_bus("Master", master_volume)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), master_volume <= 0.001 or (mute_background and _background))
	_bus("SFX", sfx_volume)
	_bus("UI", sfx_volume)
	_bus("Music", music_volume, -6.0)
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want and not (want == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
			DisplayServer.window_set_mode(want)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var tree := get_tree()
	if tree != null and tree.root != null:
		tree.root.scaling_3d_scale = clampf(render_scale, 0.5, 1.0)


func _bus(nm: String, v: float, base_db: float = 0.0) -> void:
	var i := AudioServer.get_bus_index(nm)
	if i < 0:
		return
	AudioServer.set_bus_volume_db(i, base_db + linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(i, v <= 0.001)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_background = what == NOTIFICATION_APPLICATION_FOCUS_OUT
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), master_volume <= 0.001 or (mute_background and _background))
