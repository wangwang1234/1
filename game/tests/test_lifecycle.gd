extends "res://tests/test_case.gd"

func test_removed_minion_cycles_are_released() -> void:
	var w := make_world("slice", 7, 0, 0)
	var a := SimMinion.new()
	var b := SimMinion.new()
	a.id = w.new_uid(); b.id = w.new_uid()
	a.dead = true; b.dead = true
	a.target = b; b.target = a
	a.burn_by = b; b.burn_by = a
	var ar: WeakRef = weakref(a)
	var br: WeakRef = weakref(b)
	w.minions.append(a); w.minions.append(b)
	w.register(a); w.register(b)
	a = null; b = null
	w.step(0); w.step(0)
	check(ar.get_ref() == null and br.get_ref() == null, "removed minions release before match ends")

func test_reusing_world_releases_old_props_and_players() -> void:
	var w := make_world("slice", 7, 1, 1)
	var prop: WeakRef = weakref(w.props[0])
	var ham: WeakRef = weakref(w.hams[0])
	for i in 20:
		w.setup({"mode": "slice", "seed": 7, "ai": {"blue": 1, "red": 1}})
	check(prop.get_ref() == null and ham.get_ref() == null, "setup tears down previous match")

func test_snapshot_removal_releases_cycles_and_retains_live_identity() -> void:
	var w := make_world("slice", 7, 1, 1)
	var alive: SimHamster = w.hams[0]
	var a := SimMinion.new(); var b := SimMinion.new()
	a.id = w.new_uid(); b.id = w.new_uid()
	a.target = b; b.target = a
	a.burn_by = b; b.burn_by = a
	var ar: WeakRef = weakref(a); var br: WeakRef = weakref(b)
	w.minions.append(a); w.minions.append(b); w.register(a); w.register(b)
	a = null; b = null
	var packet := NetSnapshot.capture(w)
	packet.state.tick = 1
	packet.groups.minions = []
	check(NetSnapshot.apply(w, packet), "snapshot removes minions")
	check(ar.get_ref() == null and br.get_ref() == null, "snapshot releases reference cycles")
	check(w.hams[0] == alive, "live local entity stays identical")

func test_crate_slot_cycle_released_without_changing_replacement() -> void:
	var w := make_world("full", 7, 0, 0)
	w.crate_spots[0].cur = w._make_crate(w.crate_spots[0])
	var box: WeakRef = weakref(w.crate_spots[0].cur)
	w.dispose()
	check(box.get_ref() == null, "crate and respawn slot cycle released on exit")
	var old := SimCrate.new()
	var replacement := SimCrate.new()
	var spot := {"cur": replacement, "resp": 17.0}
	old.spot = spot
	SimLifecycle.release(old)
	check(spot.cur == replacement and spot.resp == 17.0, "new occupant and respawn time unchanged")
