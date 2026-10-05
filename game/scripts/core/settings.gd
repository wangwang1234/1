extends Node
## 设置（自动加载 Settings）：音量、特效强度、伤害数字、全屏。保存在 user://settings.cfg。
## 批次 1 只做最常用的几项，批次 5 做完整设置菜单（按键、画质、语言）。

const PATH := "user://settings.cfg"

var master_volume := 1.0
var sfx_volume := 1.0
var music_volume := 0.7
var fx_strength := 1.0
var show_damage_numbers := true
var fullscreen := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_cfg()
	apply()


func load_cfg() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	master_volume = float(c.get_value("audio", "master", master_volume))
	sfx_volume = float(c.get_value("audio", "sfx", sfx_volume))
	music_volume = float(c.get_value("audio", "music", music_volume))
	fx_strength = float(c.get_value("game", "fx", fx_strength))
	show_damage_numbers = bool(c.get_value("game", "numbers", show_damage_numbers))
	fullscreen = bool(c.get_value("video", "fullscreen", fullscreen))


func save_cfg() -> void:
	var c := ConfigFile.new()
	c.set_value("audio", "master", master_volume)
	c.set_value("audio", "sfx", sfx_volume)
	c.set_value("audio", "music", music_volume)
	c.set_value("game", "fx", fx_strength)
	c.set_value("game", "numbers", show_damage_numbers)
	c.set_value("video", "fullscreen", fullscreen)
	c.save(PATH)


func apply() -> void:
	_bus("Master", master_volume)
	_bus("SFX", sfx_volume)
	_bus("UI", sfx_volume)
	_bus("Music", music_volume, -6.0)
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want and not (want == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
			DisplayServer.window_set_mode(want)


func _bus(nm: String, v: float, base_db: float = 0.0) -> void:
	var i := AudioServer.get_bus_index(nm)
	if i < 0:
		return
	AudioServer.set_bus_volume_db(i, base_db + linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(i, v <= 0.001)
