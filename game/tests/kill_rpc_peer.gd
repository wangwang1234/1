extends Node
## 两个真实ENet进程：同帧可靠击败事件、预算压力、AI接管后的重连。

var role := "host"
var port := 29840
var mode := "reward"
var w: SimWorld
var elapsed := 0.0
var age := 0.0
var sent := false
var done := false
var dropped := false
var saw_takeover := false
var resumes := 0
var failed: Array[String] = []
var local_id_before := -1


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size() - 1:
		match args[i]:
			"--role": role = args[i + 1]
			"--port": port = int(args[i + 1])
			"--case": mode = args[i + 1]
	LanSession._net.reconnectGrace = 0.6
	LanSession._net.reconnectRetry = 0.1
	LanSession._net.connectTimeout = 0.2
	LanSession.match_requested.connect(_begin)
	LanSession.snapshot_received.connect(func(packet: Dictionary) -> void: NetSnapshot.apply(w, packet))
	LanSession.resume_received.connect(func() -> void:
		resumes += 1
		_check(LanSession.peer_hams[LanSession.local_id()].id == local_id_before, "stable hamster on resume"))
	if role == "host":
		_check(LanSession.host({"name": "赏金测试房主", "team": "blue"}, {"mode": "slice"}, port) == OK, "host opened")
	else:
		_check(LanSession.join("127.0.0.1", {"name": "赏金测试客户端", "team": "red"}, port) == OK, "client joined")


func _begin(cfg: Dictionary) -> void:
	w = SimWorld.new()
	w.setup(cfg)
	LanSession.attach(w)
	local_id_before = LanSession.peer_hams[LanSession.local_id()].id
	if role == "host":
		for h in w.hams:
			h.ctl = "player"
			h.ai = null


func _physics_process(dt: float) -> void:
	if done:
		return
	elapsed += dt
	if elapsed > 15.0:
		_check(false, "timeout")
		_finish()
		return
	if not LanSession.running and not LanSession.loading and not LanSession.reconnecting:
		if LanSession.roster.has(LanSession.local_id()) and not LanSession.roster[LanSession.local_id()].ready:
			LanSession.set_ready(true)
		if LanSession.can_start():
			LanSession.start_game()
	if w == null:
		return
	if role == "host" and LanSession.running:
		age += dt
		LanSession.before_step(dt)
		# 推进服务端时钟即可；此测试不需要随机AI战斗。
		w.tick += 1
		w.t += dt
		if mode == "takeover":
			for h in LanSession.peer_hams.values():
				if h.ctl == "ai":
					saw_takeover = true
			if saw_takeover and age > 3.0 and multiplayer.get_peers().size() == 1 and LanSession._resume_wait.is_empty():
				for peer in LanSession.peer_hams:
					if peer != 1:
						_check(LanSession.peer_hams[peer].ctl == "player", "reclaimed player control")
						_check(LanSession.peer_hams[peer].bounty_connected, "player bounty eligible")
				_finish()
		elif not sent and age > 0.3:
			sent = true
			_send_reward()
		LanSession.publish(w.drain_events())
	elif role == "client":
		if mode == "takeover":
			if LanSession.running and not dropped:
				dropped = true
				var h: SimHamster = LanSession.peer_hams[LanSession.local_id()]
				h.seed_total = 123.0 # 客户端此修改不作为任何权威数值。
				LanSession._server_lost()
				LanSession._endpoint = "127.0.0.2"
			if LanSession.reconnecting and LanSession._reconnect_age > 1.2:
				LanSession._endpoint = "127.0.0.1"
			if resumes == 1 and LanSession.running:
				_check(not w.authoritative, "client still presentation only")
				_ack.rpc_id(1, "takeover")
				_finish()
		else:
			for event: Dictionary in LanSession.drain_events():
				if event.get("t") == "kill_event":
					_check(event.killer_reward == 81, "network reward81")
					_check(event.assists.size() == 2, "two assists")
					_check(event.assists[0].reward == 18 and event.assists[1].reward == 9, "network assists18/9")
					_check(w.kill_system.history.is_empty(), "client did not calculate rewards")
					_ack.rpc_id(1, "reward")
					_finish()


func _send_reward() -> void:
	var blues: Array = w.hams.filter(func(h: SimHamster) -> bool: return h.team == "blue")
	var reds: Array = w.hams.filter(func(h: SimHamster) -> bool: return h.team == "red")
	var k: SimHamster = blues[0]
	var a: SimHamster = blues[1]
	var b: SimHamster = blues[2]
	var v: SimHamster = reds[0]
	for h: SimHamster in w.hams:
		h.seed_total = 1000.0
		h.max_hp = 100.0
		h.hp = 100.0
		h.iframes = 0.0
		h.st.armor = 0.0
		h.st.crit = 0.0
	k.seed_total = 800.0
	b.seed_total = 400.0
	w.deal_dmg(v, 30.0, {"owner": a}, true)
	w.deal_dmg(v, 10.0, {"owner": b}, true)
	w.deal_dmg(v, 50.0, {"owner": k}, true)
	w.deal_dmg(v, 50.0, {"owner": k}, true)
	var events := w.drain_events()
	var effects: Array = []
	effects.resize(int(LanSession._net.eventBatchLimit) + 50)
	effects.fill({"t": "test_effect"})
	effects.append_array(events) # KillEvent 位于预算之后，也必须可靠到达。
	LanSession.publish(effects)


@rpc("any_peer", "call_remote", "reliable", 0)
func _ack(received: String) -> void:
	if role == "host":
		if received == "takeover":
			_check(saw_takeover, "host observed actual AI takeover")
		_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed.append(message)


func _finish() -> void:
	if done:
		return
	done = true
	print("KILL_RPC_RESULT " + JSON.stringify({"role": role, "case": mode, "ok": failed.is_empty(), "failures": failed}))
	# 留出可靠ACK发送时间；不改变模拟时钟。
	await get_tree().create_timer(0.2).timeout
	LanSession.leave()
	if w != null:
		w.dispose()
	get_tree().quit(0 if failed.is_empty() else 1)
