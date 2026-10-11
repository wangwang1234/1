class_name SimMotion
extends RefCounted



static func start_roll(h: SimHamster, rules: Dictionary) -> void :
	var dir: = h.inp.dash_direction if h.inp.dash_direction != Vector2.ZERO else Vector2(h.inp.mx, h.inp.my)
	h.inp.dash_direction = Vector2.ZERO
	if dir.length() < 0.2:
		dir = Vector2(cos(h.aim), sin(h.aim))
	dir = dir.normalized()
	h.rdx = dir.x
	h.rdy = dir.y
	h.roll_t = float(rules.rollTime)
	var params: = SimWeapons.params(h)
	h.dash_cd = float(h.st.dashCd) * float(params.dashCdMul)
	h.dash_spd = float(params.special.get("dashSpd", 1.0))


static func velocity(h: SimHamster, rules: Dictionary, dt: float) -> void :
	var speed: = float(h.st.speed) * (float(rules.slowMul) if h.slow_t > 0.0 else 1.0) * SimWeapons.move_mul(h)
	if h.roll_t > 0.0:
		h.roll_t -= dt
		var k: = maxf(0.0, h.roll_t / float(rules.rollTime))
		var roll_speed: = float(rules.rollSpeed) * h.dash_spd * (0.5 + 0.5 * k)
		h.vx = h.rdx * roll_speed
		h.vy = h.rdy * roll_speed
	else:
		var accel: = float(rules.accelInput) if h.inp.ml > 0.05 else float(rules.accelIdle)
		h.vx = SimUtil.damp(h.vx, h.inp.mx * speed, accel, dt)
		h.vy = SimUtil.damp(h.vy, h.inp.my * speed, accel, dt)


static func integrate(map: SimMap, h: SimHamster, dt: float) -> void :
	var previous: = Vector2(h.x, h.y)
	h.x += h.vx * dt
	h.y += h.vy * dt
	map.resolve_circle(h, h.r)
	var moved: = previous.distance_to(Vector2(h.x, h.y))
	h.moving = moved > 0.35
	h.walk += moved * 0.17
