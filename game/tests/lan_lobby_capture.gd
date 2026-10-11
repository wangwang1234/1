extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#171020")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var lobby := LanLobby.new()
	center.add_child(lobby)
	LanSession.discovery.rooms = {
		"192.168.1.23:28765": {"address": "192.168.1.23", "port": 28765, "name": "朋友的房间", "count": 7, "capacity": 10, "state": "open", "mode": "full", "signature": LanSession.signature(), "age": 0.0},
		"192.168.1.28:28765": {"address": "192.168.1.28", "port": 28765, "name": "另一场对局", "count": 6, "capacity": 6, "state": "playing", "mode": "slice", "signature": LanSession.signature(), "age": 0.0}}
	lobby._refresh_rooms()
	for i in 8:
		await get_tree().process_frame
	var rect := lobby.get_global_rect()
	assert(rect.position.y >= 0 and rect.end.y <= size.y + 1, "lobby fits screen")
	assert(not lobby.room_join.disabled, "available room enables join")
	lobby.room_pick.select(1)
	lobby._select_found()
	assert(lobby.room_join.disabled, "playing room blocks join")
	lobby.room_pick.select(0)
	lobby._select_found()
	print("LOBBY_LAYOUT ", JSON.stringify({"width": rect.size.x, "height": rect.size.y, "screen": [size.x, size.y], "room_states_checked": true}))
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var result := get_viewport().get_texture().get_image().save_png(args[0])
		assert(result == OK)
	if args.size() > 1:
		# Second shot: a hosted full-map room with seven seats taken (fake peers, nothing is sent to them).
		LanSession.host({"name": "房主", "team": "blue", "weapon": "ak47"}, {"mode": "full"}, 29990)
		var names := ["团子", "花卷", "年糕", "毛毛", "球球", "糯米"]
		var weapons := Data.active_weapons()
		for i in names.size():
			LanSession.roster[100 + i] = {"name": names[i], "team": "blue" if i < 4 else "red", "skin": "gold", "weapon": weapons[(i * 3 + 1) % weapons.size()], "ready": i % 3 != 2}
		LanSession.roster[1].ready = true
		lobby._refresh()
		assert(lobby.team.is_item_disabled(1) == false and LanSession.team_count("blue") == 5, "blue full, red open")
		for i in 8:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		assert(get_viewport().get_texture().get_image().save_png(args[1]) == OK)
	LanSession.leave()
	get_tree().quit()
