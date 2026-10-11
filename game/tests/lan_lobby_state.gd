extends Node
func _ready() -> void:
	var lobby := LanLobby.new()
	add_child(lobby)
	LanSession.role = "client"
	LanSession._room({1: LanSession.clean_profile({"name": "房主"})}, {"mode": "slice"})
	var ok := lobby._value(lobby.map_pick) == "slice" and lobby.map_pick.disabled
	LanSession._room({1: LanSession.clean_profile({"name": "房主"})}, {"mode": "full"})
	ok = ok and lobby._value(lobby.map_pick) == "full"
	LanSession.leave()
	lobby._select(lobby.map_pick, "slice")
	lobby._refresh()
	ok = ok and lobby._value(lobby.map_pick) == "slice" and not lobby.map_pick.disabled
	print("RECEIPT ", JSON.stringify({"ok": ok, "case": "lobby_map", "reason": "host maps update; offline selection retained"}))
	lobby.queue_free()
	get_tree().quit(0 if ok else 1)
