extends Node
## Real ENet room with up to ten processes; run through tools/test_lan_resume.py (scenario "ten").
## host: waits for --players seats, all ready, then runs the full map.
## client --idx N: asks for the blue team (host must balance 5 / 5), moves in its own direction.
## The client with --quit 1 leaves mid-match; the host must hand its hamster to AI and keep playing.
## The client with --overflow 1 joins after the room is full and must be refused.
var w: SimWorld
var role := ""
var args := {}
var elapsed := 0.0
var match_age := 0.0
var received := 0
var ended := ""
var local_ham: SimHamster
var start_pos := Vector2.ZERO
var done := false
var dir := Vector2.RIGHT
var seen_reserved := false
var team_counts := {}
var start_bytes := 0
var start_sent := 0
var verdict := {}


func _ready() -> void:
	args = _args()
	role = String(args.get("test-role", "host"))
	LanSession._net.reconnectGrace = 2.0
	LanSession._net.connectTimeout = 8.0
	LanSession._net.loadTimeout = 90.0
	LanSession.match_requested.connect(_begin)
	LanSession.snapshot_received.connect(_snapshot)
	LanSession.session_ended.connect(func(reason: String) -> void: ended = reason if not reason.is_empty() else "returned")
	var port := int(args.get("port", "29900"))
	var idx := int(args.get("idx", "0"))
	dir = Vector2.RIGHT.rotated(TAU * float(idx) / 9.0)
	if role == "host":
		_check(LanSession.host({"name": "十人房主", "team": "blue", "weapon": "ak47"}, {"mode": "full"}, port) == OK, "create host")
		_check(LanSession.capacity() == 10 and LanSession.capacity("slice") == 6, "full map seats 10, slice seats 6")
	else:
		LanSession.scan_rooms()


func _args() -> Dictionary:
	var result := {}
	var list := OS.get_cmdline_user_args()
	for i in list.size() - 1:
		if list[i].begins_with("--"):
			result[list[i].substr(2)] = list[i + 1]
	return result


func _begin(config: Dictionary) -> void:
	w = SimWorld.new()
	w.setup(config)
	LanSession.attach(w)
	local_ham = LanSession.peer_hams.get(LanSession.local_id())
	_check(local_ham != null, "own seat mapped")
	start_pos = Vector2(local_ham.x, local_ham.y)
	if role == "host":
		for t in ["blue", "red"]:
			team_counts[t] = config.players.filter(func(p: Dictionary) -> bool: return p.team == t).size()
		_check(team_counts.blue == 5 and team_counts.red == 5, "requested teams balanced to 5 / 5")
		_check(int(config.ai.blue) == 0 and int(config.ai.red) == 0, "ten humans need no AI filler")
	else:
		_check(local_ham.name == "玩家%d" % int(args.idx), "seat is this client's own hamster")


func _snapshot(packet: Dictionary) -> void:
	if w == null:
		return
	NetSnapshot.apply(w, packet)
	received += 1


func _physics_process(dt: float) -> void:
	if done:
		return
	elapsed += dt
	if elapsed > float(args.get("timeout", "150")):
		_finish(false, "timeout (roster %d, running %s, ended %s)" % [LanSession.roster.size(), LanSession.running, ended])
		return
	if role == "client" and not LanSession.active() and ended.is_empty():
		LanSession.discovery.query("127.0.0.1")
		for row in LanSession.discovery.rooms.values():
			if args.has("overflow") and int(row.count) < int(row.capacity):
				break
			LanSession.join(row.address, {"name": "玩家%d" % int(args.idx), "team": "blue", "weapon": "pistol"}, int(row.port))
			break
	if args.has("overflow"):
		if not ended.is_empty():
			_finish(ended.contains("已满") and w == null, "eleventh player refused: " + ended)
		return
	if not ended.is_empty() and not args.has("quit"):
		_finish(false, "session ended: " + ended)
		return
	if not LanSession.running and not LanSession.loading and LanSession.active():
		if LanSession.roster.has(LanSession.local_id()) and not LanSession.roster[LanSession.local_id()].ready:
			LanSession.set_ready(true)
		if role == "host" and LanSession.roster.size() == int(args.get("players", "10")) and LanSession.can_start():
			LanSession.start_game()
	if not LanSession.running:
		return
	match_age += dt
	if role == "host":
		LanSession.before_step(dt)
		w.step(dt)
		LanSession.publish(w.drain_events())
		if match_age > 1.0 and start_sent == 0:
			start_sent = LanSession.snapshots_sent
			start_bytes = LanSession.snapshot_bytes
		seen_reserved = seen_reserved or not LanSession._reserved.is_empty()
		if match_age > 10.0 and verdict.is_empty():
			var quitter := w.hams.filter(func(h: SimHamster) -> bool: return h.name == "玩家9")
			var sent := LanSession.snapshots_sent - start_sent
			var bytes := LanSession.snapshot_bytes - start_bytes
			print("METRIC ", JSON.stringify({"snapshots": sent, "avg_snapshot_bytes": bytes / maxi(1, sent),
				"host_upload_kbps_per_client": float(bytes) / maxf(1.0, match_age - 1.0) / 1024.0 * 8.0,
				"clients": LanSession.peer_hams.size() - 1, "tick": w.tick}))
			verdict = {"ok": seen_reserved and quitter.size() == 1 and quitter[0].ctl == "ai" and LanSession.peer_hams.size() == 9 and LanSession.roster.size() == 9}
		# Stay up until every client has checked its own movement.
		if match_age > 18.0:
			_finish(bool(verdict.get("ok", false)), "9 seats still human, dropped seat played by AI, match continues")
		return
	local_ham.inp.mx = dir.x
	local_ham.inp.my = dir.y
	local_ham.inp.ml = 1.0
	LanSession.send_input(local_ham)
	LanSession.drain_events()
	if args.has("quit") and match_age > 4.0:
		_finish(received > 30, "left mid-match after %d snapshots" % received)
		return
	if match_age > 14.0:
		var moved := Vector2(local_ham.x, local_ham.y).distance_to(start_pos)
		_finish(received > 120 and moved > 60.0, "own hamster moved %.0f, %d snapshots" % [moved, received])


func _check(ok: bool, reason: String) -> void:
	if not ok:
		_finish(false, reason)


func _finish(ok: bool, reason: String) -> void:
	if done:
		return
	done = true
	print("RECEIPT ", JSON.stringify({"ok": ok, "role": role, "case": "ten", "idx": int(args.get("idx", "-1")), "reason": reason,
		"snapshots": received, "elapsed_seconds": elapsed, "match_seconds": match_age}))
	LanSession.leave()
	if w != null:
		w.dispose()
	w = null
	local_ham = null
	get_tree().quit.call_deferred(0)
