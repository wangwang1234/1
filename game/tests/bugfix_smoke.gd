extends Node
## Real input polling, focus lifecycle and imported skeleton/grip regression.
var failures: Array[String] = []
var worst_grip := 0.0
var stage: Node3D

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func key(k: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func mouse(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bindings := InputBindings.bindings.duplicate(true)
	InputBindings.load_saved({})
	InputBindings.apply_actions()
	var h := SimHamster.new()
	var pin := PlayerInput.new()
	pin.allow_pad = false
	InputBindings.release_controls()
	pin.block_held()
	key(KEY_W, true)
	mouse(true)
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.my == -1.0 and h.inp.fire, "first fresh movement and click work immediately after resume")
	pin.block_held()
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.my == 0.0 and not h.inp.fire, "held movement and menu click suppressed")
	key(KEY_W, false)
	mouse(false)
	pin.poll(h, null, Vector2.ZERO, false)
	key(KEY_W, true)
	mouse(true)
	pin.poll(h, null, Vector2.ZERO, false)
	check(h.inp.my == -1.0 and h.inp.fire, "released controls resume normally")
	InputBindings.release_controls()
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.7).timeout
	main.start_match({"mode": "slice", "seed": 7})
	await main.match_started
	var mv: MatchView = main.match_view
	mv.set_physics_process(false)
	for cycle in 3:
		key(KEY_W, true)
		mouse(true)
		main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		await get_tree().process_frame
		check(mv.paused and get_tree().paused and main.pause_menu != null, "focus loss pauses offline game")
		check(not Input.is_physical_key_pressed(KEY_W) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "focus loss clears stale OS inputs")
		main._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
		await get_tree().process_frame
		await get_tree().process_frame
		check(not mv.paused and not get_tree().paused and main.pause_menu == null, "focus return automatically restores control")
		mv._resume_guard = 0
		key(KEY_D, true)
		mv._physics_process(1.0 / 60.0)
		check(mv.local.inp.mx == 1.0, "fresh movement reaches simulation after focus recovery")
		key(KEY_D, false)
	# Coalesced OS notifications must not let a stale focus-in resume a newer loss.
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	main._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	check(mv.paused and main.pause_menu != null, "rapid focus loss/gain/loss remains paused in background")
	main._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await get_tree().process_frame
	check(not mv.paused, "rapid focus switches recover on final focus gain")
	main._on_pause()
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	main._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await get_tree().process_frame
	check(mv.paused and main.pause_menu != null, "manual pause remains paused across focus changes")
	main._resume()
	mv.networked = true
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	check(mv.paused and not get_tree().paused, "LAN focus loss blocks local input without pausing simulation")
	main._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await get_tree().process_frame
	check(not mv.paused, "LAN input restores on focus return")
	mv.networked = false
	main._clear()
	main.queue_free()
	await get_tree().process_frame
	await test_attachments()
	InputBindings.release_controls()
	InputBindings.load_saved(bindings)
	InputBindings.apply_actions()
	print("BUGFIX_RECEIPT ", JSON.stringify({"ok": failures.is_empty(), "failures": failures, "worst_grip_m": worst_grip, "weapons": Data.weapons().size()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func test_attachments() -> void:
	stage = Node3D.new()
	add_child(stage)
	var h := SimHamster.new()
	h.st = {"scale": 1.0}
	h.aim = -PI * 0.5
	var hv := HamsterView.new()
	stage.add_child(hv)
	hv.setup(h, true)
	for wid in Data.weapons():
		h.weapon_id = wid
		hv.sync(h, 1.0, 1.0 / 60.0, true)
		# Advance the actual AnimationTree so upper-body filters are exercised.
		hv.tree.advance(0.15)
		await get_tree().process_frame
		await get_tree().process_frame
		for side in ["R", "L"]:
			var idx := hv.skel.find_bone(HamsterView.bone_name(hv.skel, "forearm_" + side))
			var rest := hv.skel.get_bone_global_rest(idx)
			var wrist := Vector3(0.066 if side == "R" else -0.066, 0.108, -0.145)
			var hand := hv.skel.global_transform * hv.skel.get_bone_global_pose(idx) * (rest.affine_inverse() * wrist)
			var grip: Node3D = hv.weapon_node.find_child("grip_" + side, true, false)
			check(grip != null, wid + " has grip " + side)
			if grip != null:
				var gap := hand.distance_to(grip.global_position)
				worst_grip = maxf(worst_grip, gap)
				check(gap < 0.036, "%s hand %s within grip, gap=%f" % [wid, side, gap])
		check(hv.skel.find_bone(HamsterView.bone_name(hv.skel, "arm_R")) >= 0, "imported upper arm resolved")
		h.vx = 150.0
		hv.sync(h, 1.0, 1.0 / 60.0, true)
		hv.on_event({"t": "fire", "weapon": wid})
		for frame in 4:
			hv.tree.advance(0.04)
			await get_tree().process_frame
			var bi := hv.skel.find_bone("forearm_R")
			var wrist_rest := Vector3(0.066, 0.108, -0.145)
			var palm := hv.skel.global_transform * hv.skel.get_bone_global_pose(bi) * (hv.skel.get_bone_global_rest(bi).affine_inverse() * wrist_rest)
			var grip: Node3D = hv.weapon_node.find_child("grip_R", true, false)
			check(palm.distance_to(grip.global_position) < 0.04, wid + " right hand follows firing/running weapon")
		h.vx = 0.0
	check(hv.rig._bone(hv.skel, "ear_L") >= 0 and hv.rig._bone(hv.skel, "cheek_R") >= 0 and hv.rig._bone(hv.skel, "tail") >= 0, "secondary rig resolves imported bone names")
	hv.queue_free()
	await get_tree().process_frame
	var mob := SimMob.new()
	mob.kind = "boss"
	var boss := B2Views.MobView.new()
	stage.add_child(boss)
	boss.setup(mob)
	var crown_rest := boss.crown.position
	var gun_rest := boss.gun.position
	check(boss.body != null and boss.head != null and boss.tail != null, "boss imported suffixed parts resolve")
	check(boss.crown.get_parent() == boss.head, "crown follows head")
	for i in 120:
		mob.tele = 0.3 if i % 2 == 0 else 0.0
		mob.recoil = 1.0 if i % 2 == 0 else 0.0
		boss.sync(mob, 1.0, 1.0 / 60.0, true)
		check(boss.crown.position.is_equal_approx(crown_rest), "crown preserves authored height during intro and aiming")
	check(boss.gun.position.distance_to(gun_rest) < 0.001, "boss gun returns to authored rest after recoil")
	var minion := SimMinion.new()
	var soldier := UnitViews.MinionView.new()
	stage.add_child(soldier)
	soldier.setup(minion)
	var minion_gun := soldier.gun.position
	soldier.sync(minion, 1.0, 0.1, true)
	check(soldier.gun.position.is_equal_approx(minion_gun), "minion gun preserves authored offset")
	var rat := B2Views.MobView.new()
	var rat_sim := SimMob.new()
	rat_sim.kind = "rat"
	stage.add_child(rat)
	rat.setup(rat_sim)
	check(rat.head != null and rat.body != null and rat.tail != null, "rat imported suffixed parts resolve")
	rat.queue_free()
	boss.queue_free()
	soldier.queue_free()
	await get_tree().process_frame
