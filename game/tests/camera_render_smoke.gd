extends Node
## GPU smoke for both camera-local effects and buffer recreation on resize.
## Run with a display and Forward+; not a headless simulation test.

var output := ""
var root: Window


func _ready() -> void:
	root = get_tree().root
	output = OS.get_environment("TASK_CAMERA_REVIEW")
	_run.call_deferred()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _capture(name_: String, expected: Vector2i) -> bool:
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if picture.get_size() != expected:
		push_error("camera_render_smoke: incorrect resized output")
		return false
	if picture.save_png(output.path_join(name_ + ".png")) != OK:
		push_error("camera_render_smoke: capture failed")
		return false
	print("[camera_render_smoke] " + name_ + " " + str(expected))
	return true


func _run() -> void:
	if output == "" or RenderingServer.get_current_rendering_method() != "forward_plus":
		push_error("camera_render_smoke requires Forward+ and TASK_CAMERA_REVIEW")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960, 540)
	var match_ := MatchView.new()
	root.add_child(match_)
	match_.start({"mode": "full", "seed": 11, "autoplay": true,
		"players": [{"team": "blue", "ctl": "player", "name": "玩家1", "input": "kbm"},
			{"team": "red", "ctl": "player", "name": "玩家2", "input": "keys2"}],
		"ai": {"blue": 2, "red": 2}})
	await _frames(4)
	match_.paused = true
	match_.set_process(false)
	match_.set_physics_process(false)
	var cameras := match_._cams()
	if cameras.size() != 2 or cameras[0].motion_blur == null or cameras[1].motion_blur == null or cameras[0].motion_blur == cameras[1].motion_blur:
		push_error("camera_render_smoke: independent camera effects missing")
		get_tree().quit(1)
		return
	var success := await _capture("duo_initial", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await _frames(4)
	success = (await _capture("duo_resized", Vector2i(1280, 720))) and success
	root.size = Vector2i(960, 540)
	await _frames(4)
	success = (await _capture("duo_restored", Vector2i(960, 540))) and success
	match_.queue_free()
	await _frames(3)
	print("[camera_render_smoke] done: " + str(success))
	get_tree().quit(0 if success else 1)
