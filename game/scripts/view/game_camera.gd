class_name GameCamera
extends Camera3D
## 俯视斜角跟随相机（ART_BIBLE 第 2 节）：俯角 56°、视野角 34°，按屏幕宽高自动定距离，
## 跟随玩家并往准星方向带一点前瞻；震屏（trauma²）+ 开火后坐偏移。地图边缘夹紧。

const PITCH_DEG := 56.0
const FOV_DEG := 34.0
## 1080p 下画面横向能看到的地图宽度（米）。原型是约 6.4 米；PC 大屏放宽到 9 米，保留更多战场信息。
const VIEW_WIDTH := 7.2

var target := Vector3.ZERO
var lead := Vector3.ZERO
var trauma := 0.0
var kick := Vector3.ZERO
var bounds := Rect2(0, 0, 50.4, 30.96)
var _pos := Vector3.ZERO
var _t := 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	fov = FOV_DEG
	near = 0.2
	far = 120.0
	_noise.seed = 7
	_noise.frequency = 1.0


func distance() -> float:
	var vp := get_viewport().get_visible_rect().size
	var asp := maxf(0.5, vp.x / maxf(1.0, vp.y))
	var hfov := 2.0 * atan(tan(deg_to_rad(FOV_DEG) * 0.5) * asp)
	return VIEW_WIDTH * 0.5 / tan(hfov * 0.5)


func snap(p: Vector3) -> void:
	_pos = p
	target = p
	_apply(0.0)


func add_trauma(a: float) -> void:
	trauma = minf(1.0, trauma + a)


func add_kick(dir: Vector3, amount: float) -> void:
	kick -= dir * amount


func update(delta: float, follow: Vector3, aim_point: Vector3, alive: bool) -> void:
	_t += delta
	var want := follow
	if alive:
		var d := (aim_point - follow)
		d.y = 0
		want += d.limit_length(9.0) * 0.18
	_pos = _pos.lerp(want, 1.0 - exp(-(7.0 if alive else 3.0) * delta))
	trauma = maxf(0.0, trauma - delta * 1.7)
	kick = kick.lerp(Vector3.ZERO, 1.0 - exp(-14.0 * delta))
	_apply(delta)


func _apply(_delta: float) -> void:
	var dist := distance()
	var pitch := deg_to_rad(PITCH_DEG)
	var p := _pos + kick
	# 地图边缘夹紧（让画面不出界太多）
	var half_w := VIEW_WIDTH * 0.5
	var vis_h := dist * tan(deg_to_rad(FOV_DEG) * 0.5) * 2.0 / sin(pitch)
	if bounds.size.x > half_w * 2.0:
		p.x = clampf(p.x, bounds.position.x + half_w - 0.6, bounds.end.x - half_w + 0.6)
	if bounds.size.y > vis_h * 0.7:
		p.z = clampf(p.z, bounds.position.y + vis_h * 0.32, bounds.end.y - vis_h * 0.22)
	var sh := trauma * trauma
	var off := Vector3(_noise.get_noise_2d(_t * 25.0, 0.0), 0.0, _noise.get_noise_2d(0.0, _t * 25.0)) * sh * 0.35
	var roll := _noise.get_noise_2d(_t * 20.0, 50.0) * sh * 0.05
	var focus := p + off
	position = focus + Vector3(0, sin(pitch) * dist, cos(pitch) * dist)
	look_at(focus, Vector3.UP)
	rotate_object_local(Vector3.FORWARD, roll)


func screen_to_ground(screen: Vector2, height: float = 0.0) -> Vector3:
	var o := project_ray_origin(screen)
	var d := project_ray_normal(screen)
	if absf(d.y) < 1e-5:
		return o
	var t := (height - o.y) / d.y
	return o + d * t
