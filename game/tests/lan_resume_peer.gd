extends Node
## Real ENet / UDP integration fixture; run through tools/test_lan_resume.py.
var w: SimWorld
var role := ""
var scenario := ""
var elapsed := 0.0
var match_age := 0.0
var matches := 0
var resumes := 0
var drops := 0
var received := 0
var ended := ""
var local_ham: SimHamster
var original_id := -1
var snapshots_at_drop := 0
var checks := 0
var done := false
var ui_main: Node
var drop_tick := 0
var first_token := ""
var mv: MatchView
var raw_stage := 0
var pending_observed := false
var bad_actions_sent := false
var action_acknowledged := false
var max_events := 0
var max_frames := 0
var discarded_events := 0
var gap_sent := false
var lobby_returns := 0
var returned_during_reconnect := false
var seat_reserved := false

class FocusLossProbe extends Node:
	func _enter_tree() -> void:
		# Main is still entering its child hierarchy, as during a native focus change.
		var main := get_parent()
		var placeholder := MatchView.new()
		placeholder.networked = true
		placeholder.hud = Hud.new()
		placeholder.hud.mv = placeholder
		placeholder.add_child(placeholder.hud)
		main.match_view = placeholder
		main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		queue_free()

func _ready() -> void:
	var args: Dictionary = get_tree().root.get_node("Main").parse_args(OS.get_cmdline_user_args()) if get_tree().root.has_node("Main") else _args()
	role = String(args.get("test-role", "host"))
	scenario = String(args.get("case", "resume"))
	LanSession._net.reconnectGrace = 30.0 if scenario == "stress" else (5.0 if args.has("quality") else 2.5)
	LanSession._net.reconnectRetry = 0.5 if scenario == "return" else 0.15
	LanSession._net.connectTimeout = 8.0 if scenario == "stress" else (3.0 if args.has("quality") else 0.6)
	if args.has("ui"):
		ui_main = load("res://scenes/main.tscn").instantiate()
		ui_main.add_child(FocusLossProbe.new())
		get_tree().root.add_child.call_deferred(ui_main)
		ui_main.match_started.connect(_view_begin)
	LanSession.match_requested.connect(_begin)
	LanSession.snapshot_received.connect(_snapshot)
	LanSession.resume_received.connect(_resumed)
	LanSession.session_ended.connect(func(reason: String) -> void:
		ended = reason
		if reason.is_empty():
			lobby_returns += 1
			_check(not LanSession.reconnecting and LanSession.config.is_empty(), "room transition clears recovery")
			if ui_main == null:
				w.dispose()
			w = null
			local_ham = null)
	if ui_main != null:
		await ui_main.ready
	var port := int(args.get("port", "29865"))
	if role == "host":
		_check(LanSession.host({"name": "集成测试房主"}, {"mode": "full" if scenario == "stress" else "slice"}, port) == OK, "create host")
	elif scenario == "pending":
		# A connected peer that never sends registration must release its slot.
		multiplayer.connected_to_server.disconnect(LanSession._on_connected)
		multiplayer.server_disconnected.connect(_raw_disconnected)
		var raw := ENetMultiplayerPeer.new()
		_check(raw.create_client("127.0.0.1", port, 4) == OK, "raw pending peer")
		multiplayer.multiplayer_peer = raw
	else:
		LanSession.scan_rooms()

func _args() -> Dictionary:
	var result := {}
	var args := OS.get_cmdline_user_args()
	for i in args.size() - 1:
		if args[i].begins_with("--"):
			result[args[i].substr(2)] = args[i + 1]
	return result

func _begin(config: Dictionary) -> void:
	if ui_main != null:
		return
	w = SimWorld.new()
	w.setup(config)
	LanSession.attach(w)
	local_ham = LanSession.peer_hams[LanSession.local_id()]
	if original_id < 0:
		original_id = local_ham.id
	match_age = 0
	_check_round_token()
	matches += 1

func _snapshot(packet: Dictionary) -> void:
	if ui_main != null:
		_view_snapshot.call_deferred(packet)
		return
	_check(NetSnapshot.apply(w, packet) or int(packet.state.tick) == w.tick, "snapshot applies")
	if scenario == "malformed" and int(packet.get("action_ack", {}).get(LanSession.local_id(), 0)) == 1:
		action_acknowledged = true
	received += 1
	_check(local_ham.id == original_id, "same player entity")
	checks += 1

func _resumed() -> void:
	resumes += 1
	_check(local_ham == LanSession.peer_hams[LanSession.local_id()], "seat rebound without replacing player")
	_check(local_ham.id == original_id, "preserve player identity")
	_check(w.tick >= drop_tick and w.tick > 0, "continue existing match clock")
	_check(LanSession.queued_events.is_empty() and LanSession._chunks.is_empty(), "clear old packets")

func _physics_process(dt: float) -> void:
	if done:
		return
	elapsed += dt
	if elapsed > (150 if scenario == "stress" else 20):
		_finish(false, "timeout")
	if role == "client" and not LanSession.active() and ended.is_empty() and (scenario != "pending" or raw_stage > 0):
		LanSession.discovery.query("127.0.0.1")
		for row in LanSession.discovery.rooms.values():
			_check(row.name == "集成测试房主" and row.port == int(_args().get("port", "29865")), "discovery metadata")
			if scenario == "mismatch":
				LanSession._signature = "different-version"
			LanSession.join(row.address, {"name": "测试客户端", "team": "red"}, int(_args().get("join-port", row.port)))
			break
	if scenario == "pending" and role == "host" and not LanSession._joining.is_empty():
		pending_observed = true
	if _args().has("ghost") and role == "host" and not LanSession._reserved.is_empty():
		LanSession._reserved.clear()
	if scenario == "return" and role == "host" and not LanSession._reserved.is_empty() and not returned_during_reconnect:
		returned_during_reconnect = true
		var sent := LanSession.snapshots_sent
		LanSession.publish([{"kind": "stale_effect"}])
		_check(LanSession.snapshots_sent == sent and LanSession._pending_events.is_empty(), "no encoding or stale effects without recipient")
		LanSession.return_to_room()
		ended = ""
	if not LanSession.running and not LanSession.loading and not LanSession.reconnecting and LanSession.active():
		if LanSession.roster.has(LanSession.local_id()) and not LanSession.roster[LanSession.local_id()].ready:
			LanSession.set_ready(true)
		if LanSession.can_start() and ended.is_empty():
			LanSession.start_game()
	if LanSession.running:
		match_age += dt
		if role == "host" and ui_main == null:
			LanSession.before_step(dt)
			w.step(dt)
			var events := w.drain_events()
			if scenario == "stress" and match_age >= 1 and match_age < 4:
				# Keep reliable effects arriving while state snapshots are withheld.
				if w.tick % 3 == 0:
					var effects: Array = []
					effects.resize(180)
					effects.fill({"kind": "test"})
					for id in LanSession.roster:
						if id != 1:
							LanSession._events.rpc_id(id, int(LanSession.config.match_id), w.tick, effects)
				gap_sent = true
			else:
				LanSession.publish(events)
		elif role == "client" and ui_main == null:
			local_ham.inp.mx = 0.3 if match_age < 2 else -0.3
			local_ham.inp.ml = 0.3
			LanSession.send_input(local_ham)
			max_events = maxi(max_events, LanSession.event_buffer.count)
			max_frames = maxi(max_frames, LanSession.queued_events.size())
			discarded_events = maxi(discarded_events, LanSession.event_buffer.discarded)
			_check(max_events <= 8192 and max_frames <= 64, "effect queue bounded")
			LanSession.drain_events()
			if scenario == "malformed" and not bad_actions_sent:
				bad_actions_sent = true
				var valid := NetInput.pack_actions(local_ham.inp, local_ham.choices, LanSession._send_seq)
				valid.dash = true
				for bad in [{}, [], NAN, INF, "1"]:
					var invalid := valid.duplicate(true)
					invalid.card = bad
					LanSession._actions.rpc_id(1, int(LanSession.config.match_id), 900, invalid)
				for field in ["choices", "input", "input_seq"]:
					var invalid := valid.duplicate(true)
					invalid[field] = {}
					LanSession._actions.rpc_id(1, int(LanSession.config.match_id), 900, invalid)
				LanSession._actions.rpc_id(1, int(LanSession.config.match_id), 1, valid)
		if scenario in ["pending", "malformed"] and match_age > (3.0 if role == "host" else 2.0):
			_finish((pending_observed and LanSession._joining.is_empty()) if role == "host" and scenario == "pending" else (role == "host" or received > 20 and (scenario != "malformed" or action_acknowledged)), "pending slot recovered / malformed RPC sequence remains usable")
		if scenario == "stress" and match_age > (140.0 if role == "host" else 120.0):
			_finish(gap_sent if role == "host" else resumes >= 1 and received > 800 and discarded_events > 0 and LanSession.repaired_snapshots > 0, "120 seconds of jitter, loss, snapshot gap, parity repair and automatic recovery")
		if scenario in ["expiry", "invalid"] and role == "client" and drops == 0 and match_age > 1:
			drops += 1
			if scenario == "invalid":
				LanSession._token = "0".repeat(64)
			drop_tick = w.tick
			LanSession._server_lost()
			if scenario == "expiry":
				LanSession._endpoint = "127.0.0.2"
		if scenario == "return" and role == "client" and matches == 1 and drops == 0 and match_age > 1:
			drops += 1
			LanSession._server_lost()
			LanSession._retry_age = 0.0
		if scenario == "return" and matches == 2 and match_age > (2.0 if role == "host" else 1.0):
			# Let the client finish its snapshot checks before the host closes the room.
			# Different process clocks can otherwise end this test at exactly 20 packets.
			if (role == "host" and LanSession.roster.size() == 1) or (role == "client" and received > 20):
				_finish(lobby_returns == 1 and resumes == 0 and (role == "host" or received > 20), "host returned during reconnect and both played second match")
		if scenario == "resume" and role == "client" and matches == 1 and match_age > 1.0 + 1.7 * drops and drops < 2:
			drops += 1
			snapshots_at_drop = received
			drop_tick = w.tick
			LanSession._server_lost()
		if scenario == "resume" and role == "host" and matches == 1 and match_age > (8.0 if _args().has("quality") else 5.0) and LanSession._reserved.is_empty() and LanSession._resume_wait.is_empty() and LanSession.roster.keys().all(func(id: int) -> bool: return id == 1 or multiplayer.get_peers().has(id)):
			_check(LanSession._reserved.is_empty() and LanSession._resume_wait.is_empty(), "resume acknowledged")
			LanSession.return_to_room()
			ended = ""
		if scenario == "resume" and matches == 2 and match_age > (2.0 if role == "host" else 1.0):
			_finish(role == "host" or (resumes == 2 and received > snapshots_at_drop + 10), "two reconnects and second match")
	if scenario in ["expiry", "invalid"] and role == "host" and not LanSession._reserved.is_empty():
		seat_reserved = true
	if scenario in ["expiry", "invalid"] and role == "host" and seat_reserved and LanSession._reserved.is_empty():
		var takeover := w.hams.filter(func(h: SimHamster) -> bool: return h.name == "测试客户端")
		_finish(LanSession.running and ended.is_empty() and LanSession.roster.size() == 1 and takeover.size() == 1 and takeover[0].ctl == "ai" and takeover[0].ai != null,
			"expired seat handed to AI while the match continues")
	if scenario in ["expiry", "invalid"] and not ended.is_empty():
		_finish(not LanSession.active() and resumes == 0, "expired or invalid seat rejected: " + ended)
	if scenario == "mismatch" and (not ended.is_empty() or (role == "host" and elapsed > 3)):
		_finish(matches == 0, "version mismatch rejected")
	if scenario in ["resume", "stress", "pending", "malformed", "return"] and not ended.is_empty():
		_finish(false, ended)

func _check(ok: bool, reason: String) -> void:
	if not ok:
		_finish(false, reason)

func _finish(ok: bool, reason: String) -> void:
	if done:
		return
	done = true
	print("RECEIPT ", JSON.stringify({"ok": ok, "role": role, "case": scenario, "reason": reason,
		"matches": matches, "resumes": resumes, "lobby_returns": lobby_returns, "snapshots": received, "repaired_snapshots": LanSession.repaired_snapshots, "checks": checks, "elapsed_seconds": elapsed, "max_event_count": max_events, "max_event_frames": max_frames, "discarded_events": discarded_events}))
	LanSession.leave()
	if w != null and ui_main == null:
		w.dispose()
	w = null
	local_ham = null
	get_tree().quit(0 if ok else 1)


func _view_begin(view: MatchView) -> void:
	mv = view
	w = view.world
	local_ham = view.local
	_check(view.players.size() == 1 and not view.split, "one screen and one HUD per computer")
	_check(view.networked and view.hud != null, "real network view")
	if original_id < 0:
		original_id = local_ham.id
	_check_round_token()
	matches += 1
	match_age = 0

func _view_snapshot(packet: Dictionary) -> void:
	if w == null or done:
		return
	_check(w.tick >= int(packet.state.tick), "view applies snapshot")
	_check(local_ham == mv.local and local_ham.id == original_id, "HUD and view retain player")
	_check(mv.prediction != null and mv.prediction.history.size() <= 21, "view prediction bounded")
	received += 1
	checks += 1


func _check_round_token() -> void:
	if role != "client":
		return
	if matches == 0:
		first_token = LanSession._token
	else:
		_check(LanSession._token != first_token, "new match invalidates previous reconnect identity")

func _raw_disconnected() -> void:
	if scenario != "pending" or raw_stage > 0:
		return
	raw_stage = 1
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	multiplayer.connected_to_server.connect(LanSession._on_connected)
	LanSession.scan_rooms()
