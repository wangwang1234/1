extends Node
## 音频（自动加载 Audio）：SFX / Music / UI 三条总线；随机变体 + 随机音高；3D 音效有距离衰减。
## 音效文件：res://assets/audio/sfx/<名称>_<变体>.ogg（tools/audio/build.py 生成）。

const SFX_DIR := "res://assets/audio/sfx/"
const N3D := 40
const N2D := 16

var _banks := {}          # 名称 -> Array[AudioStream]
var _p3d: Array[AudioStreamPlayer3D] = []
var _p2d: Array[AudioStreamPlayer] = []
var _i3 := 0
var _i2 := 0
var _last := {}           # 名称 -> 上次播放时间（限频）
var _ambience: AudioStreamPlayer
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_load_bank()
	for i in N3D:
		var p := AudioStreamPlayer3D.new()
		p.bus = "SFX"
		p.unit_size = 4.0
		p.max_distance = 22.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.panning_strength = 0.8
		add_child(p)
		_p3d.append(p)
	for i in N2D:
		var p := AudioStreamPlayer.new()
		p.bus = "UI"
		add_child(p)
		_p2d.append(p)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Music"
	add_child(_ambience)


func _setup_buses() -> void:
	for nm: String in ["SFX", "Music", "UI"]:
		if AudioServer.get_bus_index(nm) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nm)
			AudioServer.set_bus_send(i, "Master")
	var comp := AudioEffectCompressor.new()
	comp.threshold = -14.0
	comp.ratio = 4.0
	if AudioServer.get_bus_effect_count(0) == 0:
		AudioServer.add_bus_effect(0, comp)
	Settings.apply()


func _load_bank() -> void:
	var files: PackedStringArray = ResourceLoader.list_directory(SFX_DIR)
	for f in files:
		if not f.ends_with(".ogg"):
			continue
		var base := f.get_basename()
		var nm := base.substr(0, base.rfind("_"))
		var st: AudioStream = load(SFX_DIR + f)
		if st == null:
			continue
		if not _banks.has(nm):
			_banks[nm] = []
		(_banks[nm] as Array).append(st)
	print("[audio] 载入 %d 种音效" % _banks.size())


func has(nm: String) -> bool:
	return _banks.has(nm)


func _pick(nm: String) -> AudioStream:
	var b: Array = _banks.get(nm, [])
	if b.is_empty():
		return null
	return b[randi() % b.size()]


func _limit(nm: String, gap: float) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if _last.has(nm) and now - float(_last[nm]) < gap:
		return false
	_last[nm] = now
	return true


func play3d(nm: String, pos: Vector3, vol_db: float = 0.0, pitch_var: float = 0.06, gap: float = 0.02) -> void:
	if muted or not _limit(nm + str(pos.snapped(Vector3.ONE * 0.5)), gap):
		return
	var st := _pick(nm)
	if st == null:
		return
	var p := _p3d[_i3]
	_i3 = (_i3 + 1) % N3D
	p.stream = st
	p.global_position = pos
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func play2d(nm: String, vol_db: float = 0.0, pitch_var: float = 0.04, gap: float = 0.03) -> void:
	if muted or not _limit(nm, gap):
		return
	var st := _pick(nm)
	if st == null:
		return
	var p := _p2d[_i2]
	_i2 = (_i2 + 1) % N2D
	p.stream = st
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func play_ambience(on: bool) -> void:
	if not on:
		_ambience.stop()
		return
	var st := _pick("ambience")
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	_ambience.stream = st
	_ambience.volume_db = -8.0
	if not _ambience.playing:
		_ambience.play()


func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)
