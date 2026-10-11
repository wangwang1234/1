extends Node
## Three real ENet matches with death snapshots and result-screen ready votes.
var role := "host"
var w: SimWorld
var age := 0.0
var elapsed := 0.0
var rounds := 0
var returns := 0
var voted := false
var result: ResultScreen
var failures: Array[String] = []

func check(ok: bool, reason: String) -> void:
	if not ok:
		failures.append(reason)
		push_error(reason)

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var port := 29921
	for i in args.size() - 1:
		if args[i] == "--test-role": role = args[i + 1]
		if args[i] == "--port": port = int(args[i + 1])
	LanSession.match_requested.connect(_begin)
	LanSession.snapshot_received.connect(func(packet: Dictionary) -> void: NetSnapshot.apply(w, packet))
	LanSession.session_ended.connect(_ended)
	if role == "host":
		check(LanSession.host({"name": "房主", "team": "blue"}, {"mode": "slice"}, port) == OK, "host")
	else:
		check(LanSession.join("127.0.0.1", {"name": "客机", "team": "blue"}, port) == OK, "join")

func _begin(config: Dictionary) -> void:
	w = SimWorld.new()
	w.setup(config)
	LanSession.attach(w)
	rounds += 1
	age = 0.0
	voted = false

func _ended(reason: String) -> void:
	if returns >= 3:
		return
	check(reason == "", "return keeps session")
	check(LanSession.active() and LanSession.room_options.mode == "slice", "room and map retained")
	for row in LanSession.roster.values():
		check(row.team == "blue" and row.ready, "team and ready retained")
	returns += 1
	if result != null:
		result.queue_free()
		result = null
	w.dispose()
	w = null
	if returns == 3:
		await get_tree().create_timer(0.5).timeout
		print("QOL_LAN_RECEIPT ", JSON.stringify({"ok": failures.is_empty(), "role": role, "rounds": rounds, "returns": returns, "failures": failures}))
		LanSession.leave()
		get_tree().quit(0 if failures.is_empty() else 1)

func _physics_process(dt: float) -> void:
	if returns >= 3:
		return
	elapsed += dt
	if elapsed > 30:
		check(false, "timeout")
		get_tree().quit(1)
		return
	if not LanSession.running:
		if returns == 0 and LanSession.roster.has(LanSession.local_id()) and not LanSession.roster[LanSession.local_id()].ready:
			LanSession.set_ready(true)
		if LanSession.can_start():
			LanSession.start_game()
		return
	age += dt
	if role == "host":
		LanSession.before_step(dt)
		w.step(dt)
		if age > 0.6:
			w.hams[0].alive = false
			w.hams[0].dead = true
			w.hams[0].respawn_t = 8.0
			w.hams[0].death_source = "同步测试炮台"
			w.over = true
			w.winner = "red"
		LanSession.publish(w.drain_events())
	if w.over and not voted and age > (1.0 if role == "host" else 1.3):
		check(w.hams[0].death_source == "同步测试炮台", "death source delivered by snapshot")
		var observer := SpectatorState.new()
		w.over = false
		var watched := observer.update(w, w.hams[0], 2.0, 1.2, LanSession.player_connected)
		check(watched != null and watched.team == "blue", "same-team network spectating")
		w.over = true
		result = ResultScreen.new()
		result.networked = true
		add_child(result)
		result.show_result("blue", {"winner": "red", "time": w.t, "players": [], "locals": []})
		check(result.again_button.text == "准备下一局" and not result.again_button.disabled, "either peer can ready from result screen")
		if role == "host":
			LanSession._accept_next_ready(1, int(LanSession.config.match_id) - 1, true)
			check(LanSession.next_ready.is_empty(), "old-match vote rejected")
		voted = true
		result.again_button.pressed.emit()
