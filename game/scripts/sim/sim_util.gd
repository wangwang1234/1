class_name SimUtil
extends RefCounted
## 纯数学工具（原型 n1.js 的工具函数）。

const TAU_F := TAU


static func ang_diff(a: float, b: float) -> float:
	var d := fmod(b - a, TAU)
	if d > PI:
		d -= TAU
	elif d < -PI:
		d += TAU
	return d


static func turn_to(a: float, b: float, m: float) -> float:
	return a + clampf(ang_diff(a, b), -m, m)


static func damp(c: float, t: float, k: float, dt: float) -> float:
	return c + (t - c) * (1.0 - exp(-k * dt))


static func d2(ax: float, ay: float, bx: float, by: float) -> float:
	var dx := ax - bx
	var dy := ay - by
	return dx * dx + dy * dy


static func seg_rect(x1: float, y1: float, x2: float, y2: float, sx: float, sy: float, sw: float, sh: float) -> bool:
	var t0 := 0.0
	var t1 := 1.0
	var dx := x2 - x1
	var dy := y2 - y1
	var p := [-dx, dx, -dy, dy]
	var q := [x1 - sx, sx + sw - x1, y1 - sy, sy + sh - y1]
	for i in 4:
		var pi_: float = p[i]
		var qi: float = q[i]
		if pi_ == 0.0:
			if qi < 0.0:
				return false
		else:
			var t := qi / pi_
			if pi_ < 0.0:
				if t > t1:
					return false
				if t > t0:
					t0 = t
			else:
				if t < t0:
					return false
				if t < t1:
					t1 = t
	return true


static func seg_circ(x1: float, y1: float, x2: float, y2: float, cx: float, cy: float, r: float) -> bool:
	var dx := x2 - x1
	var dy := y2 - y1
	var l2 := dx * dx + dy * dy
	if l2 <= 0.0:
		l2 = 1.0
	var t := clampf(((cx - x1) * dx + (cy - y1) * dy) / l2, 0.0, 1.0)
	return d2(x1 + dx * t, y1 + dy * t, cx, cy) < r * r


static func seg_point_dist(px: float, py: float, x1: float, y1: float, x2: float, y2: float) -> float:
	var sx := x2 - x1
	var sy := y2 - y1
	var l2 := sx * sx + sy * sy
	if l2 <= 0.0:
		l2 = 1.0
	var t := clampf(((px - x1) * sx + (py - y1) * sy) / l2, 0.0, 1.0)
	return sqrt(d2(px, py, x1 + sx * t, y1 + sy * t))
