class_name HamsterRig
extends SkeletonModifier3D
## 动画之后叠加的程序动作：腮帮子鼓起（经验进度）、耳朵/尾巴弹簧摆动、头部微转。
## 挂在仓鼠模型的 Skeleton3D 下面，由 HamsterView 每帧写入 puff / accel / turn。

var puff := 0.0            # 0..1
var accel := Vector3.ZERO  # 角色局部坐标下的加速度（米/秒²）
var turn_rate := 0.0       # 弧度/秒
var ear_scale := 1.0
var munch := 0.0

var _ear := Vector2.ZERO
var _ear_v := Vector2.ZERO
var _tail := 0.0
var _tail_v := 0.0
var _ids := {}


func _ready() -> void:
	active = true


func _bone(sk: Skeleton3D, n: String) -> int:
	if not _ids.has(n):
		_ids[n] = sk.find_bone(n)
	return _ids[n]


func _process_modification_with_delta(delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	var dt := clampf(delta, 0.0, 0.05)
	# 弹簧：耳朵受前后加速度和转身影响
	var target := Vector2(clampf(-accel.z * 0.012, -0.6, 0.6), clampf(turn_rate * 0.08 + accel.x * 0.006, -0.5, 0.5))
	_ear_v += ((target - _ear) * 180.0 - _ear_v * 14.0) * dt
	_ear += _ear_v * dt
	_tail_v += ((clampf(accel.x * 0.01 + turn_rate * 0.1, -0.7, 0.7) - _tail) * 120.0 - _tail_v * 8.0) * dt
	_tail += _tail_v * dt
	var cs := 1.0 + 0.7 * clampf(puff, 0.0, 1.1) + 0.12 * sin(munch * 48.0) * (1.0 if munch > 0.0 else 0.0)
	for n: String in ["cheek_L", "cheek_R"]:
		var i := _bone(sk, n)
		if i >= 0:
			var p := sk.get_bone_pose(i)
			p.basis = p.basis.scaled(Vector3.ONE * cs)
			sk.set_bone_pose(i, p)
	for side: float in [-1.0, 1.0]:
		var i := _bone(sk, "ear_L" if side < 0 else "ear_R")
		if i >= 0:
			var p := sk.get_bone_pose(i)
			var q := Quaternion(Vector3.RIGHT, _ear.x) * Quaternion(Vector3.FORWARD, _ear.y * side)
			p.basis = Basis(q) * p.basis
			p.basis = p.basis.scaled(Vector3.ONE * ear_scale)
			sk.set_bone_pose(i, p)
	var ti := _bone(sk, "tail")
	if ti >= 0:
		var p := sk.get_bone_pose(ti)
		p.basis = Basis(Vector3.UP, _tail) * p.basis
		sk.set_bone_pose(ti, p)
