class_name NetPrediction
extends RefCounted


var ham: = SimHamster.new()
var history: Array = []
var correction: = Vector2.ZERO
var last_error: = 0.0
var _rules: Dictionary = Data.rules().hamster
var _net: Dictionary = Data.load_json("network")
var _valid: = false
var _acked: = 0
var _action_ack: = 0
var _authority_pos: = Vector2.ZERO
var _authority_alive: = true
var _pending_dash: = {}
var _render_collision: = SimEntity.new()


func _copy(h: SimHamster) -> void :
	for key in NetSnapshot.fields(h):
		var value: Variant = h.get(key)
		ham.set(key, value.duplicate(true) if value is Dictionary or value is Array else value)
	ham.px = ham.x
	ham.py = ham.y


func reset(h: SimHamster) -> void :
	_copy(h)
	history.clear()
	_pending_dash.clear()
	correction = Vector2.ZERO
	_authority_pos = Vector2(h.x, h.y)
	_authority_alive = h.alive
	_valid = true


func reconcile(w: SimWorld, source: SimHamster, ack: int, action_ack: int) -> void :
	if not _valid:
		reset(source)
	var old: = Vector2(ham.x, ham.y) + correction
	var discontinuity: = source.alive != _authority_alive or _authority_pos.distance_to(Vector2(source.x, source.y)) > float(_net.teleportDistance)
	_authority_pos = Vector2(source.x, source.y)
	_authority_alive = source.alive
	_acked = maxi(_acked, ack)
	_action_ack = maxi(_action_ack, action_ack)
	while not history.is_empty() and int(history[0].seq) <= _acked:
		history.pop_front()
	if not _pending_dash.is_empty() and int(_pending_dash.action) <= _action_ack:
		_pending_dash.clear()
	_copy(source)
	if discontinuity or not source.alive or w.over:
		history.clear()
		_pending_dash.clear()
		correction = Vector2.ZERO
		return


	var dash_replayed: = false
	for command: Dictionary in history:
		var dash: = not _pending_dash.is_empty() and not dash_replayed and int(command.seq) >= int(_pending_dash.seq)
		if dash:
			var pressed := SimHamster.HamInput.new()
			NetInput.apply(pressed, _pending_dash.input)
			ham.inp.dash_direction = NetInput.roll_direction(pressed)
		_step(w, command.input, float(command.dt), dash)
		dash_replayed = dash_replayed or dash
	if not _pending_dash.is_empty() and not dash_replayed:
		NetInput.apply(ham.inp, _pending_dash.input)
		if ham.dash_cd <= 0 and ham.roll_t <= 0 and ham.stun_t <= 0 and ham.air.is_empty():
			ham.inp.dash_direction = NetInput.roll_direction(ham.inp)
			SimMotion.start_roll(ham, _rules)
	last_error = old.distance_to(Vector2(ham.x, ham.y))
	correction = old - Vector2(ham.x, ham.y) if last_error < float(_net.teleportDistance) else Vector2.ZERO
	ham.px = ham.x
	ham.py = ham.y


func advance(w: SimWorld, command: Dictionary, dt: float) -> void :
	if command.is_empty():
		return
	if not _valid:
		return
	var max_frames: = ceili(float(_net.predictionMaxSeconds) * 60.0)

	if history.size() >= max_frames:
		return
	var frame: = command.duplicate(true)
	frame.dt = dt
	history.append(frame)
	var dash: = bool(frame.get("dash", false)) and int(frame.get("action", 0)) > _action_ack and ham.dash_cd <= dt and ham.roll_t <= 0 and ham.stun_t <= 0 and ham.air.is_empty()
	if dash:
		_pending_dash = frame.duplicate(true)
	ham.save_prev()
	_step(w, frame.input, dt, dash)


func _step(w: SimWorld, input: Dictionary, dt: float, dash: bool) -> void :
	var pressed_direction := ham.inp.dash_direction
	ham.inp.dash_direction = Vector2.ZERO
	NetInput.apply(ham.inp, input)
	if not ham.alive or w.over:
		return
	ham.dash_cd -= dt
	ham.slow_t = maxf(0, ham.slow_t - dt)
	if ham.stun_t > 0:
		ham.stun_t -= dt
		ham.vx *= 0.85
		ham.vy *= 0.85
		SimMotion.integrate(w.map, ham, dt)
		return
	ham.aim = ham.inp.aim
	if not ham.air.is_empty():
		ham.air.t = minf(float(ham.air.dur), float(ham.air.t) + dt)
		var k: = float(ham.air.t) / maxf(0.001, float(ham.air.dur))
		ham.x = lerpf(float(ham.air.x0), float(ham.air.x1), k)
		ham.y = lerpf(float(ham.air.y0), float(ham.air.y1), k)
		ham.z = sin(k * PI) * float(ham.air.hgt)

		return
	if dash and ham.dash_cd <= 0 and ham.roll_t <= 0:
		ham.inp.dash_direction = pressed_direction
		SimMotion.start_roll(ham, _rules)
	SimMotion.velocity(ham, _rules, dt)
	SimMotion.integrate(w.map, ham, dt)


func render_offset(w: SimWorld, dt: float) -> Vector2:
	correction *= exp( - dt / float(_net.correctionSeconds))
	_render_collision.x = ham.x + correction.x
	_render_collision.y = ham.y + correction.y
	if ham.alive and ham.air.is_empty():
		w.map.resolve_circle(_render_collision, ham.r)
	return Vector2(_render_collision.x - ham.x, _render_collision.y - ham.y)
