class_name NetSnapshotChunks
extends RefCounted
## Four data shards plus one XOR shard repair a single loss per stripe.
const CHUNK_BYTES := 900
var frames: Dictionary = {}
var last_tick := -1
var _net: Dictionary = Data.load_json("network")

static func xor_into(out: PackedByteArray, part: PackedByteArray) -> void:
	var words := part.size() >> 3
	for i in words:
		out.encode_u64(i * 8, out.decode_u64(i * 8) ^ part.decode_u64(i * 8))
	for i in range(words * 8, part.size()):
		out[i] = out[i] ^ part[i]

static func parity(blob: PackedByteArray, group_size: int) -> Array:
	var result: Array = []
	if group_size < 2:
		return result
	var total := ceili(float(blob.size()) / CHUNK_BYTES)
	for first in range(0, total, group_size):
		var bytes := PackedByteArray()
		bytes.resize(CHUNK_BYTES)
		for i in range(first, mini(first + group_size, total)):
			xor_into(bytes, blob.slice(i * CHUNK_BYTES, mini(blob.size(), (i + 1) * CHUNK_BYTES)))
		result.append({"first": first, "data": bytes})
	return result

func clear(tick: int = -1) -> void:
	frames.clear()
	last_tick = tick

func _frame(tick: int, total: int) -> Dictionary:
	var max_parts := ceili(float(_net.maxSnapshotBytes) / CHUNK_BYTES)
	if tick <= last_tick or total < 1 or total > max_parts:
		return {}
	if not frames.has(tick):
		frames[tick] = {"total": total, "size": -1, "parts": {}, "parity": {}, "repaired": 0}
	if frames.size() > int(_net.snapshotBufferFrames):
		var keys: Array = frames.keys()
		keys.sort()
		frames.erase(keys[0])
	if not frames.has(tick) or frames[tick].total != total:
		return {}
	return frames[tick]

func data(tick: int, index: int, total: int, bytes: PackedByteArray) -> Dictionary:
	if index < 0 or index >= total or bytes.is_empty() or bytes.size() > CHUNK_BYTES:
		return {}
	if index != total - 1 and bytes.size() != CHUNK_BYTES:
		return {}
	var frame := _frame(tick, total)
	if frame.is_empty():
		return {}
	if index == total - 1:
		var size := (total - 1) * CHUNK_BYTES + bytes.size()
		if size > int(_net.maxSnapshotBytes) or (frame.size != -1 and frame.size != size):
			return {}
		frame.size = size
	frame.parts[index] = bytes
	return _finish(tick, frame)

func repair(tick: int, first: int, total: int, size: int, bytes: PackedByteArray) -> Dictionary:
	var group_size := int(_net.snapshotParityGroup)
	if group_size < 2 or first < 0 or first >= total or first % group_size != 0 or bytes.size() != CHUNK_BYTES:
		return {}
	if size < 1 or size > int(_net.maxSnapshotBytes) or ceili(float(size) / CHUNK_BYTES) != total:
		return {}
	var frame := _frame(tick, total)
	if frame.is_empty() or (frame.size != -1 and frame.size != size):
		return {}
	frame.size = size
	frame.parity[first] = bytes
	return _finish(tick, frame)

func _finish(tick: int, frame: Dictionary) -> Dictionary:
	var group_size := int(_net.snapshotParityGroup)
	for first: int in frame.parity.keys():
		var missing := -1
		var count := 0
		for i in range(first, mini(first + group_size, int(frame.total))):
			if not frame.parts.has(i):
				missing = i
				count += 1
		if count != 1:
			continue
		var bytes: PackedByteArray = frame.parity[first].duplicate()
		for i in range(first, mini(first + group_size, int(frame.total))):
			if i != missing:
				xor_into(bytes, frame.parts[i])
		var size := mini(CHUNK_BYTES, int(frame.size) - missing * CHUNK_BYTES)
		frame.parts[missing] = bytes.slice(0, size)
		frame.repaired += 1
	if frame.parts.size() != frame.total:
		return {}
	var blob := PackedByteArray()
	for i in int(frame.total):
		blob.append_array(frame.parts[i])
	last_tick = tick
	for key in frames.keys():
		if int(key) <= tick:
			frames.erase(key)
	return {"blob": blob, "repaired": frame.repaired}
