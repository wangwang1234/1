extends SceneTree
## Deterministic shard-loss replay, not an ENet or GPU benchmark.
func _init() -> void:
	var w := SimWorld.new()
	w.setup({"mode": "full", "seed": 7, "ai": {"blue": 5, "red": 5}})
	var baseline := NetSnapshot.baseline_index(NetSnapshot.capture(w))
	var rng := RandomNumberGenerator.new()
	rng.seed = 731
	var rows: Array = []
	var original_bytes := 0
	var parity_bytes := 0
	var complete_original := 0
	var complete_repaired := 0
	var restored := 0
	var parity_us: Array = []
	for step in 7200:
		w.step(1.0 / 60.0)
		w.events.clear()
		if step % 3 != 2: continue
		var blob := NetSnapshot.compress(NetSnapshot.delta(NetSnapshot.capture(w), baseline))
		var started := Time.get_ticks_usec()
		var stripes := NetSnapshotChunks.parity(blob, 4)
		parity_us.append(Time.get_ticks_usec() - started)
		original_bytes += blob.size()
		parity_bytes += stripes.size() * 900
		var total := ceili(float(blob.size()) / 900)
		var decoder := NetSnapshotChunks.new()
		var missing := 0
		var result := {}
		for i in total:
			if rng.randf() < 0.04:
				missing += 1
				continue
			var ready := decoder.data(w.tick, i, total, blob.slice(i * 900, mini(blob.size(), (i + 1) * 900)))
			if not ready.is_empty(): result = ready
		if missing == 0: complete_original += 1
		for stripe: Dictionary in stripes:
			if rng.randf() < 0.04: continue
			var ready := decoder.repair(w.tick, int(stripe.first), total, blob.size(), stripe.data)
			if not ready.is_empty(): result = ready
		if not result.is_empty():
			if result.blob != blob:
				push_error("Repaired bytes differ")
				quit(1)
				return
			complete_repaired += 1
			if missing > 0: restored += 1
		rows.append({"tick": w.tick, "bytes": blob.size(), "parts": total, "missing": missing, "complete": not result.is_empty()})
	var sum_us := 0
	for value: int in parity_us: sum_us += value
	parity_us.sort()
	var report := {"model": "independent 4% shard loss, same original masks, parity also loses 4%, no arrival deadlines", "seed": 731, "simulation_seed": 7, "simulation_seconds": w.t, "frames": rows.size(), "original_complete": complete_original, "with_parity_complete": complete_repaired, "restored_frames": restored, "original_bytes": original_bytes, "parity_bytes": parity_bytes, "parity_encode_avg_ms": float(sum_us) / parity_us.size() / 1000.0, "parity_encode_p99_ms": float(parity_us[int(parity_us.size() * 0.99)]) / 1000.0}
	print("REPAIR_REPLAY ", JSON.stringify(report))
	var path := ProjectSettings.globalize_path("res://../review/lan_recovery_fec/snapshot_replay.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	w.dispose()
	quit(0)
