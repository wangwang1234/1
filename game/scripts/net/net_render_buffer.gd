class_name NetRenderBuffer
extends RefCounted


var frames: Array = []
var cursor: = -1.0
var delay: = 0.0
var jitter: = 0.0
var _arrival: = -1.0
var _last_tick: = -1
var _net: Dictionary = Data.load_json("network")


func push(packet: Dictionary, arrival: float) -> void :
	var tick: = int(packet.state.tick)
	if tick <= _last_tick:
		return
	if _last_tick >= 0:
		var deviation: = absf((arrival - _arrival) - float(tick - _last_tick) / 60.0)
		jitter = lerpf(jitter, deviation, 0.15)
	_last_tick = tick
	_arrival = arrival
	delay = clampf(float(_net.interpolationMin) + jitter * float(_net.jitterMultiplier), float(_net.interpolationMin), float(_net.interpolationMax))
	var poses: = {}
	for group in packet.groups:
		for row: Dictionary in packet.groups[group]:
			if not row.has("x") or not row.has("y"):
				continue
			var pose: = {}
			for key in ["x", "y", "z", "aim", "vx", "vy", "alive", "dead", "roll_t", "rdx", "rdy"]:
				if row.has(key):
					pose[key] = row[key]
			poses[int(row.id)] = pose
	frames.append({"tick": tick, "poses": poses})
	if cursor < 0:
		cursor = tick - delay * 60.0
	while frames.size() > int(_net.renderBufferFrames):
		frames.pop_front()


func advance(dt: float) -> void :
	if frames.is_empty():
		return
	var latest: = float(frames[-1].tick)
	var target: = latest - delay * 60.0
	if target - cursor > float(_net.interpolationMax) * 60.0:
		cursor = target
	var rate: = clampf(1.0 + (target - cursor) * float(_net.clockCorrection), 0.9, 1.1)
	cursor = minf(cursor + dt * 60.0 * rate, latest + float(_net.extrapolationMax) * 60.0)
	while frames.size() > 2 and float(frames[1].tick) <= cursor:
		frames.pop_front()


func sample(id: int) -> Dictionary:
	if frames.is_empty():
		return {}
	var older: Dictionary = frames[0]
	var newer: Dictionary = older
	for frame: Dictionary in frames:
		newer = frame
		if float(frame.tick) >= cursor:
			break
		older = frame
	var b: Dictionary = newer.poses.get(id, {})
	var a: Dictionary = older.poses.get(id, {})
	if b.is_empty():
		return {}
	if a.is_empty():
		return b
	if a.get("alive", true) != b.get("alive", true) or a.get("dead", false) != b.get("dead", false) or Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y)) > float(_net.teleportDistance):
		return b
	var gap: = float(newer.tick) - float(older.tick)
	var alpha: = clampf((cursor - float(older.tick)) / gap, 0, 1) if gap > 0 else 1.0
	var out: = b.duplicate()
	for key in ["x", "y", "z", "vx", "vy"]:
		if a.has(key) and b.has(key):
			out[key] = lerpf(float(a[key]), float(b[key]), alpha)
	if a.has("aim") and b.has("aim"):
		out.aim = lerp_angle(float(a.aim), float(b.aim), alpha)

	if cursor > float(newer.tick) and b.has("vx") and b.has("vy"):
		var extra: = minf((cursor - float(newer.tick)) / 60.0, float(_net.extrapolationMax))
		out.x = float(b.x) + float(b.vx) * extra
		out.y = float(b.y) + float(b.vy) * extra
	return out
