extends "res://tests/test_case.gd"

func _blob(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size)
	for i in size:
		bytes[i] = (i * 73 + i / 11) % 256
	return bytes

func test_single_loss_in_every_stripe_and_tail_recovered() -> void:
	for size in [1, 899, 900, 901, 3600, 3601, 8107]:
		var blob := _blob(size)
		var total := ceili(float(size) / 900)
		for loss in total:
			var decoder := NetSnapshotChunks.new()
			var result := {}
			# Parity arrives first; data arrive in reverse order.
			for stripe: Dictionary in NetSnapshotChunks.parity(blob, 4):
				var ready := decoder.repair(3, int(stripe.first), total, size, stripe.data)
				if not ready.is_empty(): result = ready
			for i in range(total - 1, -1, -1):
				if i == loss: continue
				var ready := decoder.data(3, i, total, blob.slice(i * 900, mini(size, (i + 1) * 900)))
				if not ready.is_empty(): result = ready
			check(not result.is_empty(), "recover any single loss")
			if not result.is_empty(): eq(result.blob, blob, "exact bytes including short tail")

func test_two_losses_wait_then_recover_late_data() -> void:
	var blob := _blob(3595)
	var decoder := NetSnapshotChunks.new()
	decoder.data(3, 0, 4, blob.slice(0, 900))
	decoder.data(3, 3, 4, blob.slice(2700))
	check(decoder.repair(3, 0, 4, blob.size(), NetSnapshotChunks.parity(blob, 4)[0].data).is_empty(), "two missing cannot be fabricated")
	var result := decoder.data(3, 1, 4, blob.slice(900, 1800))
	eq(result.blob, blob, "one late shard permits recovery")
	check(decoder.data(3, 2, 4, blob.slice(1800, 2700)).is_empty(), "late duplicate never emits again")

func test_one_loss_per_stripe_recovers_together() -> void:
	var blob := _blob(8107)
	var decoder := NetSnapshotChunks.new()
	var result := {}
	for stripe: Dictionary in NetSnapshotChunks.parity(blob, 4):
		var ready := decoder.repair(3, int(stripe.first), 10, blob.size(), stripe.data)
		if not ready.is_empty(): result = ready
	for i in 10:
		if i in [1, 5, 9]: continue
		var ready := decoder.data(3, i, 10, blob.slice(i * 900, mini(blob.size(), (i + 1) * 900)))
		if not ready.is_empty(): result = ready
	eq(result.blob, blob, "three distinct stripes repaired exactly")
	eq(result.repaired, 3, "counts recovered shards")

func test_bounds_and_newer_snapshot_survive_incomplete_frames() -> void:
	var decoder := NetSnapshotChunks.new()
	var blob := _blob(3601)
	var stripe: Dictionary = NetSnapshotChunks.parity(blob, 4)[0]
	for tick in [3, 6, 9, 12, 15]:
		decoder.data(tick, 0, 5, blob.slice(0, 900))
		check(decoder.frames.size() <= 3, "bounded partial frame count")
	check(decoder.repair(15, 1, 5, blob.size(), stripe.data).is_empty(), "bad stripe alignment")
	check(decoder.repair(15, 0, 5, 900, stripe.data).is_empty(), "bad original size")
	check(decoder.data(15, 1, 5, PackedByteArray([1])).is_empty(), "short interior shard rejected")
	var result := decoder.data(18, 0, 1, PackedByteArray([42]))
	eq(result.blob, PackedByteArray([42]), "later complete frame supersedes missing one")
	check(decoder.frames.is_empty(), "obsolete frames cleared")
	decoder.clear()
	check(not decoder.data(1, 0, 1, PackedByteArray([7])).is_empty(), "new match resets tick")
