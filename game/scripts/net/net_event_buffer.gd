class_name NetEventBuffer
extends RefCounted
## These are transient effects; combat and victory remain in snapshots.
var frames: Array = []
var count := 0
var discarded := 0
var last_tick := -1
var _net: Dictionary = Data.load_json("network")

func push(tick: int, events: Array) -> void:
	if tick <= last_tick or events.is_empty():
		return
	last_tick = tick
	var accepted := events.slice(0, int(_net.eventBatchLimit))
	discarded += events.size() - accepted.size()
	frames.append({"tick": tick, "events": accepted})
	count += accepted.size()
	while frames.size() > int(_net.eventBufferFrames) or count > int(_net.eventBufferLimit):
		discarded += _pop().events.size()

func _pop() -> Dictionary:
	var frame: Dictionary = frames.pop_front()
	count -= frame.events.size()
	return frame

func take(world: SimWorld) -> Array:
	var out: Array = []
	if world == null:
		return out
	var oldest := world.tick - roundi(60.0 * float(_net.eventMaxAge))
	while not frames.is_empty() and int(frames[0].tick) <= world.tick:
		var frame := _pop()
		if int(frame.tick) < oldest:
			discarded += frame.events.size()
		else:
			out.append_array(NetSnapshot.decode(frame.events, world.entities))
	return out

func clear() -> void:
	frames.clear()
	count = 0
	discarded = 0
	last_tick = -1
