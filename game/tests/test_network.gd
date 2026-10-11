extends "res://tests/test_case.gd"

func test_snapshot_roundtrip_loss_and_baseline_return() -> void:
	var players := [{"team": "blue", "ctl": "player", "name": "A"}, {"team": "red", "ctl": "player", "name": "B"}]
	var host := make_world("slice", 7, 0, 0, players)
	var guest := make_world("slice", 7, 0, 0, players)
	var baseline := NetSnapshot.baseline_index(NetSnapshot.capture(host))
	var identity: SimHamster = guest.hams[0]
	for frame in 120:
		host.hams[0].inp.mx = 1.0 if frame < 60 else 0.0
		host.hams[0].inp.ml = host.hams[0].inp.mx
		host.step(1.0 / 60.0)
		host.events.clear()
		if frame % 4 != 3:
			continue
		var packed := NetSnapshot.compress(NetSnapshot.delta(NetSnapshot.capture(host), baseline))
		var packet := NetSnapshot.expand_delta(NetSnapshot.decompress(packed), baseline)
		check(NetSnapshot.apply(guest, packet), "apply independently after lost frames")
		near(guest.hams[0].x, host.hams[0].x, 0.0001, "authority position")
		eq(guest.hams[0].hp, host.hams[0].hp, "authority health")
		check(guest.hams[0] == identity, "preserve entity")
	host.dispose()
	guest.dispose()

func test_prediction_isolated_and_bounded() -> void:
	var w := make_world("slice", 7, 0, 0, [{"team": "blue", "ctl": "player"}])
	var h: SimHamster = w.hams[0]
	var x := h.x
	var predictor := NetPrediction.new()
	predictor.reset(h)
	for i in 60:
		var inp := NetInput.pack(h.inp)
		inp.mx = 1.0
		predictor.advance(w, {"seq": i + 1, "input": inp, "dash": false, "action": 0}, 1.0 / 60.0)
	eq(h.x, x, "never moves authoritative player")
	check(predictor.history.size() <= 21, "bounded on outage")
	w.dispose()

func test_input_validation() -> void:
	var h := SimHamster.new()
	var valid := NetInput.pack(h.inp)
	valid.mx = 100.0
	check(NetInput.apply(h.inp, valid), "accept finite controls")
	near(h.inp.mx, 1.0, 0.00001, "normalize movement")
	valid.mx = NAN
	check(not NetInput.apply(h.inp, valid), "reject NaN")

func test_discovery_validation_and_expiry() -> void:
	var row := {"name": "房间", "port": 28765, "mode": "slice", "state": "open", "count": 1, "capacity": 6, "signature": "a".repeat(64)}
	check(not LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "valid room")
	row.port = 999999
	check(LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "invalid port")
	row.port = 28765
	row.state = "bad"
	check(LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "invalid state")
	row.state = "open"
	row.count = 7
	row.capacity = 10
	check(not LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "ten-seat room with seven players")
	row.count = 11
	check(LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "more players than seats rejected")
	row.count = 3
	row.capacity = 11
	check(LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "capacity above maxPlayers rejected")
	row.erase("capacity")
	check(LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "missing capacity rejected")
	var discovery := LanDiscovery.new()
	check(discovery.start_scan() == OK, "ephemeral scan socket")
	discovery.rooms["test"] = {"age": 0.0}
	discovery.advance(6)
	check(discovery.rooms.is_empty(), "remove stale room")
	discovery.stop()

func test_action_validation_is_atomic() -> void:
	var h := SimHamster.new()
	var choices: Array = ["a", "b"]
	var action := NetInput.pack_actions(h.inp, choices, 1)
	action.dash = true
	action.card = 1
	for bad in [{}, [], NAN, INF, "1", 1.5]:
		var invalid := action.duplicate()
		invalid.card = bad
		check(not NetInput.apply_actions(h.inp, invalid, choices), "invalid card rejected")
		check(not h.inp.dash and h.inp.card == -1, "reject without partial dash")
	var invalid := action.duplicate()
	invalid.choices = {}
	check(not NetInput.apply_actions(h.inp, invalid, choices), "invalid choice hash rejected")
	invalid = action.duplicate()
	invalid.dash = 1
	check(not NetInput.apply_actions(h.inp, invalid, choices), "boolean edge required")
	check(NetInput.apply_actions(h.inp, action, choices), "valid action still works")
	eq(h.inp.card, 1, "selected matching choices")
	NetInput.clear(h.inp)
	action.choices = 0
	check(NetInput.apply_actions(h.inp, action, choices), "stale card does not block independent dash")
	eq(h.inp.card, -1, "old choice not selected")
	check(h.inp.dash, "dash remains valid")

func test_event_outage_bounded_and_stale_effects_discarded() -> void:
	var w := make_world("slice", 7, 0, 0)
	var buffer := NetEventBuffer.new()
	for tick in range(3, 603, 3):
		var events: Array = []
		events.resize(180)
		events.fill({"kind": "test"})
		buffer.push(tick, events)
		check(buffer.frames.size() <= 64 and buffer.count <= 8192, "bounded while snapshots unavailable")
	check(buffer.discarded > 0, "overflow discarded")
	w.tick = 600
	var effects := buffer.take(w)
	eq(effects.size(), 1980, "only last half-second effects replay")
	check(buffer.frames.is_empty() and buffer.count == 0, "drained consistently")
	buffer.push(599, [{"kind": "duplicate"}])
	check(buffer.frames.is_empty(), "late events never replay")
	buffer.clear()
	buffer.push(3, [{"kind": "new match"}])
	eq(buffer.count, 1, "new match resets sequence")
	w.dispose()

func test_discovery_refreshes_map_and_version() -> void:
	var host := LanDiscovery.new()
	var scanner := LanDiscovery.new()
	var row := {"name": "房间", "port": 28765, "mode": "slice", "state": "open", "count": 1, "capacity": 6, "signature": "a".repeat(64)}
	check(host.start_host(row, 0) == OK, "discovery host")
	check(scanner.start_scan() == OK, "discovery scanner")
	var notifications := [0]
	scanner.changed.connect(func() -> void: notifications[0] += 1)
	for pass_index in 2:
		if pass_index == 1:
			host.advertisement.mode = "full"
			host.advertisement.signature = "b".repeat(64)
		scanner.query("127.0.0.1", host.socket.get_local_port())
		for i in 20:
			host.advance(0.001)
			scanner.advance(0.001)
			if notifications[0] > pass_index:
				break
	eq(notifications[0], 2, "map and version changes notify UI")
	if not scanner.rooms.is_empty():
		eq(scanner.rooms.values()[0].mode, "full", "new map visible")
	row.port = INF
	check(LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "infinite port rejected")
	row.port = 28765.5
	check(LanDiscovery.clean_room(row, "127.0.0.1").is_empty(), "fractional port rejected")
	host.stop()
	scanner.stop()

func test_dash_context_survives_new_controls() -> void:
	var w := make_world("slice", 7, 0, 0, [{"team": "blue", "ctl": "player"}])
	var h: SimHamster = w.hams[0]
	var pressed := SimHamster.HamInput.new()
	pressed.mx = -1.0
	pressed.dash = true
	check(NetInput.apply_actions(h.inp, NetInput.pack_actions(pressed, h.choices, 4), h.choices), "accept press direction")
	var newer := NetInput.pack(h.inp)
	newer.mx = 1.0
	NetInput.apply(h.inp, newer)
	SimMotion.start_roll(h, w.R.hamster)
	near(h.rdx, -1, 0.0001, "newer movement cannot redirect dash")
	eq(h.inp.dash_direction, Vector2.ZERO, "consume context")
	SimMotion.start_roll(h, w.R.hamster)
	near(h.rdx, 1, 0.0001, "no stale direction on next local dash")

func test_idle_dash_aim_and_input_timeout() -> void:
	var w := make_world("slice", 7, 0, 0, [{"team": "blue", "ctl": "player"}])
	var h: SimHamster = w.hams[0]
	var pressed := SimHamster.HamInput.new()
	pressed.aim = PI / 2
	pressed.dash = true
	check(NetInput.apply_actions(h.inp, NetInput.pack_actions(pressed, h.choices, 1), h.choices), "idle dash")
	h.inp.mx = 1
	h.inp.fire = true
	NetInput.clear_continuous(h.inp)
	check(h.inp.mx == 0 and not h.inp.fire and h.inp.dash, "stop continuous input without losing reliable edge")
	SimMotion.start_roll(h, w.R.hamster)
	near(h.rdx, 0, 0.0001, "idle press aim X")
	near(h.rdy, 1, 0.0001, "idle press aim Y")
	NetInput.clear(h.inp)
	check(not h.inp.dash and h.inp.dash_direction == Vector2.ZERO, "disconnect clears all input")

func test_action_context_validation_atomic() -> void:
	var input := SimHamster.HamInput.new()
	var action := NetInput.pack_actions(input, [], 1)
	action.dash = true
	for bad in [null, {}, {"mx": NAN}, []]:
		var invalid := action.duplicate(true)
		invalid.input = bad
		check(not NetInput.apply_actions(input, invalid, []), "invalid context")
		check(not input.dash and input.dash_direction == Vector2.ZERO, "reject without latching")
	for bad in [0, -1, 1.5, "1"]:
		var invalid := action.duplicate(true)
		invalid.input_seq = bad
		check(not NetInput.apply_actions(input, invalid, []), "invalid sequence")
	check(NetInput.apply_actions(input, action, []), "valid action after rejection")

func test_prediction_keeps_press_direction_after_input_ack() -> void:
	var w := make_world("slice", 7, 0, 0, [{"team": "blue", "ctl": "player"}])
	var source: SimHamster = w.hams[0]
	var prediction := NetPrediction.new()
	prediction.reset(source)
	var input := NetInput.pack(source.inp)
	input.mx = -1.0
	prediction.advance(w, {"seq": 1, "input": input.duplicate(), "dash": true, "action": 1}, 1.0 / 60.0)
	prediction.reconcile(w, source, 1, 0)
	near(prediction.ham.rdx, -1, 0.0001, "press input removed but action still in flight")
	input.mx = 1.0
	prediction.advance(w, {"seq": 2, "input": input, "dash": false, "action": 0}, 1.0 / 60.0)
	prediction.reconcile(w, source, 1, 0)
	near(prediction.ham.rdx, -1, 0.0001, "replayed later input cannot change pending dash")


func test_dropped_player_handed_to_ai() -> void:
	var w := SimWorld.new()
	var players: Array = []
	for i in 10:
		players.append({"team": "blue" if i < 5 else "red", "ctl": "player", "name": "P%d" % i, "skin": "gold", "weapon": "pistol"})
	w.setup({"mode": "full", "seed": 7, "players": players, "ai": {"blue": 0, "red": 0}})
	check(w.hams.size() == 10 and w.hams.all(func(h: SimHamster) -> bool: return h.ctl == "player"), "ten human seats, no AI filler")
	var h: SimHamster = w.hams[3]
	h.inp.fire = true
	var start := Vector2(h.x, h.y)
	w.hand_to_ai(h)
	check(h.ctl == "ai" and h.ai != null and not h.inp.fire, "takeover resets input and creates AI state")
	for i in 60 * 8:
		w.step(1.0 / 60.0)
	check(Vector2(h.x, h.y).distance_to(start) > 50.0, "AI drives the abandoned hamster")
	w.dispose()


func test_skill_and_assist_cross_the_network() -> void:
	var local := SimHamster.new()
	local.inp.skill = true
	local.inp.assist = 1.4
	var remote := SimHamster.new()
	check(NetInput.apply_actions(remote.inp, NetInput.pack_actions(local.inp, [], 1), []), "action with skill accepted")
	check(remote.inp.skill, "right-click skill edge reaches the host")
	check(NetInput.apply(remote.inp, NetInput.pack(local.inp)), "controls accepted")
	near(remote.inp.assist, 1.4, 0.0001, "aim-assist strength travels with controls")
	var cheat := NetInput.pack(local.inp)
	cheat.assist = 50.0
	check(NetInput.apply(remote.inp, cheat) and remote.inp.assist <= 1.4001, "assist clamped to the strongest setting")
	NetInput.clear(remote.inp)
	check(not remote.inp.skill, "clear drops pending skill")
