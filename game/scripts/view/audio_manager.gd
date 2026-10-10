extends Node
## 音频（自动加载 Audio）：SFX / Music / UI 三条总线；随机变体 + 随机音高；3D 音效有距离衰减。
## 音效文件：res://assets/audio/sfx/<名称>_<变体>.ogg（tools/audio/build.py 生成）。
## 音乐：res://assets/audio/music/<名称>.ogg（tools/audio/music.py 生成），play_music 交叉淡入淡出；只走 Music 总线（设置里的“音乐”音量）。
## 环境底噪走 SFX 总线，跟随“音效”音量。

const SFX_DIR := "res://assets/audio/sfx/"
const N3D := 40
const N2D := 16
const MUSIC_DIR := "res://assets/audio/music/"
const MUSIC_LOOPS := ["menu", "match", "rush", "boss"]   # 循环曲；其余（victory / defeat）是一次性短曲
const MUSIC_DUCK_DB := -10.0                              # 暂停时音乐压低
const AMBIENCE_DB := -17.0                                # 底噪改走 SFX 总线后的音量（和原来在 Music 总线时听感一致）

var _banks := {}          # 名称 -> Array[AudioStream]
var _p3d: Array[AudioStreamPlayer3D] = []
var _p2d: Array[AudioStreamPlayer] = []
var _i3 := 0
var _i2 := 0
var _last := {}           # 名称 -> 上次播放时间（限频）
var _ambience: AudioStreamPlayer
var muted := false
var music_name := ""      # 正在放（或正在淡入）的曲子，空 = 静音
var _music: Array[AudioStreamPlayer] = []    # 两个播放器轮流用，做交叉淡入淡出
var _mi := 0
var _music_cache := {}
var _music_tw := {}       # 播放器 -> 正在跑的音量补间
var _duck := false
var _resume := ""         # 短曲放完后要恢复的循环曲（空 = 放完就停）


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
	_ambience.bus = "SFX"
	add_child(_ambience)
	for i in 2:
		var mp := AudioStreamPlayer.new()
		mp.bus = "Music"
		mp.volume_db = -80.0
		add_child(mp)
		mp.finished.connect(_on_music_finished.bind(mp))
		_music.append(mp)


func _setup_buses() -> void:
	for nm: String in ["SFX", "Music", "UI"]:
		if AudioServer.get_bus_index(nm) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nm)
			AudioServer.set_bus_send(i, "Master")
	# 总线：压缩（密集枪战时不炸）+ 补偿增益 + 限幅（峰值不超过 -1 dB）
	var comp := AudioEffectCompressor.new()
	comp.threshold = -12.0
	comp.ratio = 3.0
	comp.gain = 6.0
	comp.attack_us = 2000.0
	comp.release_ms = 120.0
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = -1.0
	if AudioServer.get_bus_effect_count(0) == 0:
		AudioServer.add_bus_effect(0, comp)
		AudioServer.add_bus_effect(0, lim)
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
	_ambience.volume_db = AMBIENCE_DB
	if not _ambience.playing:
		_ambience.play()


func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)


# ---------------------------------------------------------------------------
# 音乐
# ---------------------------------------------------------------------------

func _music_stream(nm: String) -> AudioStream:
	if _music_cache.has(nm):
		return _music_cache[nm]
	var path := MUSIC_DIR + nm + ".ogg"
	var st: AudioStream = load(path) if ResourceLoader.exists(path) else null
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = nm in MUSIC_LOOPS
	_music_cache[nm] = st
	return st


func _music_db() -> float:
	return MUSIC_DUCK_DB if _duck else 0.0


func _fade(p: AudioStreamPlayer, to_db: float, dur: float, stop_after: bool = false) -> void:
	if _music_tw.has(p):
		(_music_tw[p] as Tween).kill()
		_music_tw.erase(p)
	if dur <= 0.0:
		p.volume_db = to_db
		if stop_after:
			p.stop()
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", to_db, dur)
	if stop_after:
		tw.tween_callback(p.stop)
	_music_tw[p] = tw


## 切换背景音乐（交叉淡入淡出 fade 秒）。循环曲（menu / match / rush / boss）自动循环；
## 短曲（victory / defeat）放一次：resume_after = true 时放完回到之前的循环曲，否则放完就安静。
## 同一首正在放时什么也不做，所以可以每帧调用。
func play_music(nm: String, fade := 1.0, resume_after := false) -> void:
	if nm == "":
		stop_music(fade)
		return
	if nm == music_name:
		return
	var st := _music_stream(nm)
	if st == null:
		stop_music(fade)
		return
	var prev := music_name
	_resume = prev if resume_after and prev in MUSIC_LOOPS else ""
	var old := _music[_mi]
	_mi = 1 - _mi
	var p := _music[_mi]
	p.stream = st
	p.volume_db = -40.0 if fade > 0.0 else _music_db()
	p.play()
	music_name = nm
	_fade(p, _music_db(), fade)
	if old.playing:
		_fade(old, -60.0, maxf(fade, 0.05), true)


func stop_music(fade := 1.0) -> void:
	music_name = ""
	_resume = ""
	for p in _music:
		if p.playing:
			_fade(p, -60.0, maxf(fade, 0.05), true)


## 暂停菜单打开时压低音乐
func set_music_duck(on: bool) -> void:
	if _duck == on:
		return
	_duck = on
	if music_name != "":
		_fade(_music[_mi], _music_db(), 0.3)


func _on_music_finished(p: AudioStreamPlayer) -> void:
	if p != _music[_mi] or music_name == "" or music_name in MUSIC_LOOPS:
		return
	var nxt := _resume
	music_name = ""
	_resume = ""
	if nxt != "":
		play_music(nxt, 1.5)
