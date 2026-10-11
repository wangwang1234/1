extends Node
## ENet regression: lost controls, then action older than confirmed controls.
var role := "host"
var w: SimWorld
var h: SimHamster
var elapsed := 0.0
var stage := 0
var input_ack := 0
var action_ack := 0
var checked := 0
var done := false
var verified_age := 0.0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var port := 29877
	for i in args.size() - 1:
		if args[i] == "--test-role": role = args[i + 1]
		if args[i] == "--port": port = int(args[i + 1])
	LanSession.match_requested.connect(_begin)
	LanSession.snapshot_received.connect(_snapshot)
	if role == "host":
		_check(LanSession.host({"name": "动作测试"}, {"mode": "slice"}, port) == OK, "host")
	else:
		_check(LanSession.join("127.0.0.1", {"name": "客机", "team": "red"}, port) == OK, "join")

func _begin(config: Dictionary) -> void:
	w = SimWorld.new()
	w.setup(config)
	LanSession.attach(w)
	for id in LanSession.peer_hams:
		if id != 1: h = LanSession.peer_hams[id]

func _snapshot(packet: Dictionary) -> void:
	NetSnapshot.apply(w, packet)
	input_ack = int(packet.get("input_ack", {}).get(LanSession.local_id(), 0))
	action_ack = int(packet.get("action_ack", {}).get(LanSession.local_id(), 0))

func _physics_process(dt: float) -> void:
	if done: return
	elapsed += dt
	if elapsed > 15:
		_finish(false, "timeout")
		return
	if not LanSession.running:
		if LanSession.roster.has(LanSession.local_id()) and not LanSession.roster[LanSession.local_id()].ready:
			LanSession.set_ready(true)
		if LanSession.can_start(): LanSession.start_game()
		return
	if role == "host":
		LanSession.before_step(dt)
		w.step(dt)
		var events := w.drain_events()
		if w.tick == 1:
			var burst: Array = []
			burst.resize(5000)
			burst.fill({"kind": "budget_test"})
			events.append_array(burst)
		LanSession.publish(events)
		_check(LanSession._pending_events.size() <= int(LanSession._net.eventBatchLimit), "effect burst bounded before encoding")
		if done: return
		for id in LanSession.peer_hams:
			if id == 1: continue
			var ack := int(LanSession._consumed_action.get(id, 0))
			if ack > checked and h.roll_t > 0:
				_check(h.rdx < -0.99, "press-time direction")
				if done: return
				if ack == 1:
					_check(int(LanSession._last_input[id]) == 101 and h.inp.mx < 0, "recover missing controls")
				else:
					_check(int(LanSession._last_input[id]) == 200 and h.inp.mx > 0, "never rewind newer controls")
				if done: return
				checked = ack
		if checked == 2:
			verified_age += dt
			if verified_age > 1: _finish(true, "two arrival orders and send budget verified")
	else:
		if stage == 0:
			_control(100, 0.3)
			stage = 1
		elif stage == 1 and input_ack == 100:
			_action(1, 101)
			stage = 2
		elif stage == 1:
			_control(100, 0.3)
		elif stage == 2 and action_ack >= 1 and h.dash_cd <= 0 and h.roll_t <= 0:
			_control(200, 0.3)
			stage = 3
		elif stage == 3 and input_ack == 200:
			_action(2, 150)
			stage = 4
		elif stage == 3:
			_control(200, 0.3)
		elif stage == 4 and action_ack >= 2:
			_check(h.rdx < -0.99, "snapshot agrees with dash direction")
			_finish(true, "missing and newer controls with reliable actions")

func _control(seq: int, x: float) -> void:
	var input := NetInput.pack(h.inp)
	input.mx = x
	LanSession._controls.rpc_id(1, int(LanSession.config.match_id), seq, input)

func _action(seq: int, controls_seq: int) -> void:
	var pressed := SimHamster.HamInput.new()
	pressed.mx = -0.3
	pressed.dash = true
	LanSession._actions.rpc_id(1, int(LanSession.config.match_id), seq, NetInput.pack_actions(pressed, h.choices, controls_seq))

func _check(ok: bool, reason: String) -> void:
	if not ok: _finish(false, reason)

func _finish(ok: bool, reason: String) -> void:
	if done: return
	done = true
	print("RECEIPT ", JSON.stringify({"ok": ok, "role": role, "case": "actions", "reason": reason, "checked": checked}))
	LanSession.leave()
	if w != null: w.dispose()
	w = null
	h = null
	get_tree().quit(0 if ok else 1)
