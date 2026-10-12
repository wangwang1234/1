extends Node
## 冻结的开发展示场景。无真实赏金发放；F8可切换任意次数、角色、图标与标签。
## KILL_UI_CAPTURE=<目录> 时在真实游戏画面上输出审阅截图后退出。

var mv: MatchView
var sequence: int = 0


func _ready() -> void:
	await _make_match(false)
	var directory := OS.get_environment("KILL_UI_CAPTURE")
	if directory.is_empty():
		mv.kill_debug.toggle()
		return
	DirAccess.make_dir_recursive_absolute(directory)
	for item: Dictionary in [
		{"name": "01_four", "streak": 4}, {"name": "02_five", "streak": 5, "first": true},
		{"name": "03_unstoppable", "streak": 6, "shutdown": true},
		{"name": "04_twenty_seven", "streak": 27}, {"name": "05_feed_methods", "streak": 3},
		{"name": "06_mobile_clearance", "streak": 10}]:
		mv.kill_ui.reset_display()
		mv.hud.touch_mode = item.name == "06_mobile_clearance"
		mv.hud.refresh(0.0)
		if item.name == "05_feed_methods":
			for method in ["normal", "explosion", "burn", "slash", "reflect"]:
				var packet := _packet(mv.local.id, mv.world.hams.back().id, 3)
				packet.method = method
				packet.assists = [{"player_id": 9001, "reward": 18, "connected": true}, {"player_id": 9002, "reward": 0, "connected": false}]
				packet.identities[9001] = {"name": "小麦", "team": "blue", "connected": true}
				packet.identities[9002] = {"name": "断线队友", "team": "blue", "connected": false}
				mv.kill_ui.preview(packet)
		else:
			var packet := _packet(mv.local.id, mv.world.hams.back().id, int(item.streak))
			packet.is_first_kill = bool(item.get("first", false))
			packet.is_shutdown = bool(item.get("shutdown", false))
			packet.victim_streak_before = 7 if packet.is_shutdown else 0
			mv.kill_ui.preview(packet)
		await _capture(directory, item.name)
	mv.queue_free()
	await get_tree().process_frame
	await _make_match(true)
	var left: SimHamster = mv.players[0].ham
	var right: SimHamster = mv.players[1].ham
	mv.kill_ui.preview(_packet(left.id, mv.world.hams.back().id, 5))
	mv.kill_ui.preview(_packet(right.id, mv.world.hams.back().id, 6))
	await _capture(directory, "07_split_independent")
	mv.kill_ui.reset_display()
	var assist := _packet(left.id, mv.world.hams.back().id, 4)
	assist.assists = [{"player_id": right.id, "reward": 18, "connected": true}]
	mv.kill_ui.preview(assist)
	await _capture(directory, "08_split_assist")
	mv.kill_ui.reset_display()
	mv.kill_ui.preview(_packet(right.id, left.id, 1))
	await _capture(directory, "09_split_defeated")
	mv.kill_ui.reset_display()
	var no_killer := _packet(-1, left.id, 0)
	no_killer.killer_connected = false
	mv.kill_ui.preview(no_killer)
	await _capture(directory, "10_no_killer")
	print("[kill_preview] 完成 (done)")
	get_tree().quit(0)


func _make_match(duo: bool) -> void:
	mv = MatchView.new()
	add_child(mv)
	var players: Array = [{"team": "blue", "ctl": "player", "name": "瓜瓜"}]
	if duo:
		players.append({"team": "blue", "ctl": "player", "name": "豆豆", "input": "keys2"})
	mv.start({"mode": "slice", "seed": 11, "players": players, "ai": {"blue": 0, "red": 1}})
	mv.set_physics_process(false)
	mv.set_process(false)
	mv.kill_ui.set_process(false)
	for h in mv.world.hams:
		h.x = 500.0 + h.idx * 130.0
		h.y = 1000.0
		h.px = h.x
		h.py = h.y
	for pl in mv.players:
		pl.cam.snap(Vector3(pl.ham.x * 0.01, 0, pl.ham.y * 0.01))
	await get_tree().process_frame
	mv._process(0.0)


func _packet(killer: int, victim: int, streak: int) -> Dictionary:
	sequence += 1
	var event := KillEvent.new()
	event.event_id = sequence
	event.killer_id = killer
	event.victim_id = victim
	event.victim_death_count = -1
	event.method = "normal"
	event.killer_streak = streak
	event.killer_reward = 81
	event.killer_connected = true
	for h in mv.world.hams:
		event.identities[h.id] = {"name": h.name, "team": h.team, "connected": true}
	return event.to_dict()


func _capture(directory: String, label: String) -> void:
	mv._process(0.0)
	mv.kill_ui._process(0.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png"))
	assert(error == OK, "审阅截图保存失败")
	print("[kill_preview] captured ", label)
