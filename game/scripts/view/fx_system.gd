class_name FxSystem
extends Node3D
## 表现层特效（不影响逻辑）。全部池化：
## - 粒子：加法（火花、闪光星、火焰、余烬）/ 透明（烟团、灰尘、绒毛、碎屑），CPU 更新 + MultiMesh 绘制
## - 地面冲击环、闪光灯（OmniLight 池）、伤害数字（Label3D 池）、弹壳（带弹跳）、曳光弹、经验瓜子、手雷、焦痕
## 坐标单位：米（逻辑坐标 × 0.01）。

const MAX_ADD := 700
const MAX_MIX := 500
const MAX_RING := 32
const MAX_SHELL := 160
const MAX_TRACER := 500
const MAX_GEM := 300

enum { S_CIRCLE, S_STAR, S_STREAK, S_SMOKE, S_FUR, S_CHUNK }

class Particle:
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var life := 0.0
	var max_life := 1.0
	var size := 0.1
	var grow := 0.0
	var color := Color.WHITE
	var shape := 0
	var grav := 0.0
	var drag := 0.0
	var bounce := false
	var stretch := 0.0

var camera: Camera3D
var fx_scale := 1.0     # 特效强度（设置里的“特效：强烈/普通”）
var _add: Array = []
var _mix: Array = []
var _mm_add: MultiMesh
var _mm_mix: MultiMesh
var _rings: Array = []   # {pos, r, grow, life, max, color, w}
var _mm_ring: MultiMesh
var _lights: Array = []  # {light, t, max, energy}
var _labels: Array = []  # {label, t, max, vel}
var _shells: Array = []  # {pos, vel, rot, vr, life, tinks, red}
var _mm_shell: MultiMesh
var _mm_shell_red: MultiMesh
var _mm_tracer: MultiMesh
var _mm_gem: MultiMesh
var _mm_gem_big: MultiMesh
var _lob_nodes := {}
var _cheese_nodes := {}
var _decals: Array = []
var _scorch_tex: Texture2D
var _rng := RandomNumberGenerator.new()
var on_shell_tink: Callable


func _ready() -> void:
	_rng.randomize()
	_mm_add = _make_mm(preload("res://shaders/fx_particle_add.gdshader"), MAX_ADD, true)
	_mm_mix = _make_mm(preload("res://shaders/fx_particle_mix.gdshader"), MAX_MIX, true)
	_mm_ring = _make_mm(preload("res://shaders/fx_ring.gdshader"), MAX_RING, true)
	_mm_tracer = _make_mm(preload("res://shaders/tracer.gdshader"), MAX_TRACER, true)
	_mm_shell = _make_toon_mm(_palette_box("brass", Vector3(0.012, 0.012, 0.028)), MAX_SHELL)
	_mm_shell_red = _make_toon_mm(_palette_box("shell_red", Vector3(0.018, 0.018, 0.04)), 60)
	_mm_gem = _make_toon_mm(ToonMaterials.merged_mesh("res://assets/models/props/prop_seed.glb", 1.0), MAX_GEM)
	_mm_gem_big = _make_toon_mm(ToonMaterials.merged_mesh("res://assets/models/props/prop_seed_big.glb", 1.0), 80)
	for i in 8:
		var l := OmniLight3D.new()
		l.visible = false
		l.light_specular = 0.0
		l.omni_attenuation = 1.4
		add_child(l)
		_lights.append({"light": l, "t": 0.0, "max": 1.0, "energy": 1.0})
	var font: Font = load("res://assets/fonts/ZCOOLKuaiLe.ttf")
	for i in 48:
		var lb := Label3D.new()
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		lb.fixed_size = true
		lb.pixel_size = 0.0011
		lb.font = font
		lb.font_size = 40
		lb.outline_size = 12
		lb.outline_modulate = Color(0.1, 0.06, 0.16, 1)
		lb.render_priority = 10
		lb.outline_render_priority = 9
		lb.visible = false
		add_child(lb)
		_labels.append({"label": lb, "t": 0.0, "max": 1.0, "vel": 0.0})
	_scorch_tex = _make_scorch()


func _make_mm(shader: Shader, n: int, custom: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = custom
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	q.material = mat
	mm.mesh = q
	mm.instance_count = n
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 10000.0
	add_child(mmi)
	return mm


func _make_toon_mm(mesh: Mesh, n: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.extra_cull_margin = 10000.0
	add_child(mmi)
	return mm


static var _pal: Dictionary = {}


static func palette_uv(color_name: String) -> Vector2:
	if _pal.is_empty():
		var f := FileAccess.open("res://assets/textures/palette.json", FileAccess.READ)
		if f:
			_pal = JSON.parse_string(f.get_as_text())
	var rc: Array = _pal.get(color_name, [0, 15])
	return Vector2((float(rc[1]) + 0.5) / 16.0, (float(rc[0]) + 0.5) / 16.0)


static func _palette_box(color_name: String, size: Vector3) -> ArrayMesh:
	var b := BoxMesh.new()
	b.size = size
	var arr := b.get_mesh_arrays()
	var uv := PackedVector2Array()
	var u := palette_uv(color_name)
	for i in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
		uv.append(u)
	arr[Mesh.ARRAY_TEX_UV] = uv
	var cols := PackedColorArray()
	for n in (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array):
		cols.append(Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	arr[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	m.surface_set_material(0, ToonMaterials.material(3, 1.0))
	return m


func _make_scorch() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 32.0
			var n := r.randf() * 0.15
			var a := clampf(1.0 - smoothstep(0.55, 1.0, d + n), 0.0, 1.0)
			img.set_pixel(x, y, Color(0.05, 0.04, 0.06, a * 0.8))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# 发射
# ---------------------------------------------------------------------------

func spawn(pos: Vector3, vel: Vector3, life: float, size: float, color: Color, shape: int, additive: bool, grav: float = 0.0, drag: float = 1.5, grow: float = 0.0, bounce: bool = false, stretch: float = 0.0) -> void:
	var list: Array = _add if additive else _mix
	if list.size() >= (MAX_ADD if additive else MAX_MIX):
		return
	var p := Particle.new()
	p.pos = pos
	p.vel = vel
	p.life = life
	p.max_life = life
	p.size = size
	p.color = color
	p.shape = shape
	p.grav = grav
	p.drag = drag
	p.grow = grow
	p.bounce = bounce
	p.stretch = stretch
	list.append(p)


func _n(x: float) -> int:
	return maxi(1, roundi(x * fx_scale))


func rand_dir(spread: float = PI) -> Vector3:
	var a := _rng.randf() * TAU
	return Vector3(cos(a), 0, sin(a))


func flash_light(pos: Vector3, color: Color, energy: float, rng_m: float, dur: float) -> void:
	var best: Dictionary = _lights[0]
	for L in _lights:
		if float(L.t) <= 0.0:
			best = L
			break
		if float(L.t) < float(best.t):
			best = L
	var l: OmniLight3D = best.light
	l.position = pos
	l.light_color = color
	l.omni_range = rng_m
	l.light_energy = energy
	l.visible = true
	best.t = dur
	best.max = dur
	best.energy = energy


func ring(pos: Vector3, r0: float, grow: float, life: float, color: Color, width: float = 0.25) -> void:
	if _rings.size() >= MAX_RING:
		_rings.pop_front()
	_rings.append({"pos": pos, "r": r0, "grow": grow, "life": life, "max": life, "color": color, "w": width})


func number(pos: Vector3, text: String, color: Color, size: float = 1.0) -> void:
	var best: Dictionary = _labels[0]
	for L in _labels:
		if float(L.t) <= 0.0:
			best = L
			break
		if float(L.t) < float(best.t):
			best = L
	var lb: Label3D = best.label
	lb.text = text
	lb.modulate = color
	lb.position = pos + Vector3(_rng.randf_range(-0.08, 0.08), 0, _rng.randf_range(-0.05, 0.05))
	lb.font_size = int(40 * size)
	lb.visible = true
	best.t = 0.7
	best.max = 0.7
	best.vel = 0.9


func scorch(pos: Vector3, radius: float) -> void:
	var d := Decal.new()
	d.texture_albedo = _scorch_tex
	d.size = Vector3(radius * 1.25, 0.6, radius * 1.25)
	d.position = pos + Vector3(0, 0.1, 0)
	d.rotation.y = _rng.randf() * TAU
	d.modulate = Color(1, 1, 1, 0.4)
	add_child(d)
	_decals.append({"node": d, "t": 20.0})
	if _decals.size() > 30:
		var old: Dictionary = _decals.pop_front()
		(old.node as Node).queue_free()


# ---------------------------------------------------------------------------
# 组合特效（对应原型 gunFx / onHitFx / rocketBoom / bigBoom / deathFx 等）
# ---------------------------------------------------------------------------

func muzzle(pos: Vector3, dir: Vector3, weapon: Dictionary) -> void:
	var F: Dictionary = weapon.get("fx", {"fl": 15, "sm": 1, "sp": 3, "li": 1.6, "side": 0})
	var fl := float(F.get("fl", 15)) * 0.01
	spawn(pos + dir * fl * 0.3, Vector3.ZERO, 0.05 + fl * 0.12, fl * 2.4, Color(1.0, 0.96, 0.76), S_STAR, true, 0, 0)
	spawn(pos + dir * fl * 0.9, dir * 0.5, 0.045, fl * 1.6, Color(1.0, 0.82, 0.48), S_STREAK, true, 0, 0, 0.0, false, 1.0)
	if int(F.get("side", 0)) > 0:
		var side := dir.cross(Vector3.UP)
		for s: float in [-1.0, 1.0]:
			spawn(pos + side * s * fl * 0.3, side * s * 0.2, 0.045, fl * 1.1, Color(1.0, 0.82, 0.48), S_STAR, true, 0, 0)
	for i in _n(float(F.get("sm", 1))):
		spawn(pos + dir * _rng.randf_range(0, 0.1), dir * _rng.randf_range(0.3, 0.9) + Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0.1, 0.3), _rng.randf_range(-0.2, 0.2)), _rng.randf_range(0.4, 0.8), _rng.randf_range(0.06, 0.1) * fl * 6.0, Color(0.66, 0.64, 0.72, 0.75), S_SMOKE, false, -0.35, 2.0, 0.28)
	for i in _n(float(F.get("sp", 3))):
		var d := (dir + Vector3(_rng.randf_range(-0.45, 0.45), _rng.randf_range(0.0, 0.3), _rng.randf_range(-0.45, 0.45))).normalized()
		spawn(pos, d * _rng.randf_range(2.2, 4.8), _rng.randf_range(0.06, 0.13), 0.02, Color(1.0, 0.82, 0.48), S_STREAK, true, 5.2, 1.5, 0.0, false, 0.6)
	flash_light(pos + Vector3(0, 0.1, 0), Color(1.0, 0.85, 0.55), float(F.get("li", 1.6)) * 1.6, 2.4, 0.07)


func eject_shell(pos: Vector3, side: Vector3, fwd: Vector3, red: bool) -> void:
	if _shells.size() >= MAX_SHELL:
		_shells.pop_front()
	_shells.append({"pos": pos, "vel": side * _rng.randf_range(0.9, 1.5) - fwd * _rng.randf_range(0.1, 0.4) + Vector3(0, _rng.randf_range(1.5, 2.4), 0), "rot": Vector3(_rng.randf() * TAU, _rng.randf() * TAU, 0), "vr": Vector3(_rng.randf_range(-20, 20), _rng.randf_range(-20, 20), 0), "life": 3.5, "tinks": 0, "red": red})


func hit(pos: Vector3, color: Color, big: bool) -> void:
	spawn(pos, Vector3.ZERO, 0.07, (0.15 if big else 0.1) * (0.75 + 0.3 * fx_scale), color, S_STAR, true, 0, 0)
	for i in _n(6 if big else 3):
		var d := (rand_dir() + Vector3(0, _rng.randf_range(0.2, 1.8), 0)).normalized()
		spawn(pos, d * _rng.randf_range(0.9, 2.8), _rng.randf_range(0.1, 0.22), 0.025, color, S_STREAK, true, 5.2, 1.5, 0.0, false, 0.5)
	if big:
		ring(pos * Vector3(1, 0, 1) + Vector3(0, 0.02, 0), 0.03, 1.4 * fx_scale, 0.16, color, 0.3)


func wall_hit(pos: Vector3, color: Color) -> void:
	for i in _n(4):
		var d := (rand_dir() + Vector3(0, _rng.randf_range(0.3, 1.2), 0)).normalized()
		spawn(pos, d * _rng.randf_range(0.8, 2.2), _rng.randf_range(0.08, 0.16), 0.02, color, S_STREAK, true, 5.2, 1.5, 0.0, false, 0.5)
	spawn(pos, Vector3(_rng.randf_range(-0.2, 0.2), 0.15, _rng.randf_range(-0.2, 0.2)), 0.4, 0.05, Color(0.6, 0.58, 0.68, 0.7), S_SMOKE, false, -0.3, 2.0, 0.24)


func explosion(pos: Vector3, radius: float, big: bool) -> void:
	var k := radius / 1.3
	spawn(pos + Vector3(0, 0.3, 0), Vector3.ZERO, 0.12, radius * 1.1, Color(1.0, 0.95, 0.75), S_STAR, true, 0, 0)
	for i in _n(14.0 * k + 6):
		var d := rand_dir()
		spawn(pos + Vector3(0, _rng.randf_range(0.05, 0.4), 0), d * _rng.randf_range(0.3, 1.5) * k + Vector3(0, _rng.randf_range(0.3, 1.4), 0), _rng.randf_range(0.25, 0.5), _rng.randf_range(0.22, 0.42) * k, Color(1.0, _rng.randf_range(0.45, 0.75), 0.2), S_CIRCLE, true, -0.4, 2.5, -0.2)
	for i in _n(24.0 * k + 8):
		var d2 := (rand_dir() + Vector3(0, _rng.randf_range(0.4, 1.6), 0)).normalized()
		spawn(pos + Vector3(0, 0.2, 0), d2 * _rng.randf_range(1.6, 4.4), _rng.randf_range(0.6, 1.2), 0.025, Color(1.0, 0.69, 0.29), S_STREAK, true, 3.2, 0.6, 0.0, true, 0.4)
	for i in _n(12.0 * k + 4):
		spawn(pos + Vector3(_rng.randf_range(-0.4, 0.4) * k, _rng.randf_range(0.2, 0.5), _rng.randf_range(-0.4, 0.4) * k), Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(0.4, 1.0), _rng.randf_range(-0.4, 0.4)), _rng.randf_range(1.0, 1.8), _rng.randf_range(0.26, 0.44) * k, Color(0.21, 0.19, 0.24, 0.9), S_SMOKE, false, -0.25, 1.2, 0.3)
	for i in _n(8.0 * k):
		var d3 := (rand_dir() + Vector3(0, _rng.randf_range(0.6, 1.8), 0)).normalized()
		spawn(pos + Vector3(0, 0.15, 0), d3 * _rng.randf_range(1.5, 3.2), _rng.randf_range(0.7, 1.2), 0.035, Color(0.3, 0.26, 0.24), S_CHUNK, false, 9.0, 0.5, 0.0, true)
	ring(pos + Vector3(0, 0.03, 0), 0.2, 4.2 * k * fx_scale, 0.4, Color(1.0, 0.69, 0.4), 0.18)
	ring(pos + Vector3(0, 0.035, 0), 0.1, 2.6 * k * fx_scale, 0.55, Color(1.0, 0.42, 0.16), 0.25)
	flash_light(pos + Vector3(0, 0.6, 0), Color(1.0, 0.6, 0.3), 5.0 if big else 3.2, radius * 3.5, 0.45 if big else 0.32)
	scorch(pos, radius * 0.7)


func death_burst(pos: Vector3, team_color: Color, fur: Color) -> void:
	spawn(pos + Vector3(0, 0.2, 0), Vector3.ZERO, 0.1, 0.5, Color.WHITE, S_STAR, true, 0, 0)
	for i in _n(16):
		var d := (rand_dir() + Vector3(0, _rng.randf_range(0.6, 2.4), 0)).normalized()
		spawn(pos + Vector3(0, 0.18, 0), d * _rng.randf_range(0.6, 2.6), _rng.randf_range(0.5, 0.95), _rng.randf_range(0.04, 0.07), fur if i % 2 == 0 else Color("#fff2df"), S_FUR, false, 0.9, 3.5)
	for i in _n(8):
		var d2 := (rand_dir() + Vector3(0, _rng.randf_range(0.8, 2.4), 0)).normalized()
		spawn(pos + Vector3(0, 0.18, 0), d2 * _rng.randf_range(0.8, 2.2), 0.65, _rng.randf_range(0.07, 0.11), team_color, S_STAR, true, 2.5, 2.5)
	ring(pos + Vector3(0, 0.03, 0), 0.1, 2.6, 0.32, team_color, 0.25)
	ring(pos + Vector3(0, 0.035, 0), 0.06, 1.7, 0.42, Color.WHITE, 0.2)


func small_death(pos: Vector3, color: Color, n: int) -> void:
	for i in _n(n):
		var d := (rand_dir() + Vector3(0, _rng.randf_range(0.8, 2.4), 0)).normalized()
		spawn(pos + Vector3(0, 0.12, 0), d * _rng.randf_range(0.4, 2.2), _rng.randf_range(0.35, 0.65), _rng.randf_range(0.025, 0.045), color, S_CHUNK, false, 9.0, 1.5, 0.0, true)
	spawn(pos + Vector3(0, 0.12, 0), Vector3.ZERO, 0.07, 0.2, Color(1.0, 0.88, 0.69), S_STAR, true, 0, 0)
	ring(pos + Vector3(0, 0.02, 0), 0.06, 1.5, 0.22, color, 0.25)


func dust(pos: Vector3, dir: Vector3, n: int, strength: float = 1.0) -> void:
	for i in _n(n):
		spawn(pos + Vector3(_rng.randf_range(-0.08, 0.08), 0.04, _rng.randf_range(-0.06, 0.06)), -dir * _rng.randf_range(0.3, 0.9) * strength + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.1, 0.3), _rng.randf_range(-0.3, 0.3)), _rng.randf_range(0.3, 0.55), _rng.randf_range(0.09, 0.14), Color(0.91, 0.87, 0.8, 0.85), S_SMOKE, false, -0.1, 2.0, 0.22)


func stars(pos: Vector3, color: Color, n: int, speed: float = 1.1) -> void:
	for i in _n(n):
		var d := rand_dir()
		spawn(pos, d * speed + Vector3(0, _rng.randf_range(0.6, 1.8), 0), 0.7, 0.07, color, S_STAR, true, 2.5, 2.5)


func burn(pos: Vector3) -> void:
	spawn(pos + Vector3(_rng.randf_range(-0.06, 0.06), _rng.randf_range(0.05, 0.25), _rng.randf_range(-0.06, 0.06)), Vector3(0, _rng.randf_range(0.3, 0.7), 0), _rng.randf_range(0.25, 0.45), _rng.randf_range(0.07, 0.11), Color(1.0, 0.55, 0.15), S_CIRCLE, true, -0.6, 2.5, -0.15)


# ---------------------------------------------------------------------------
# 每帧更新
# ---------------------------------------------------------------------------

func update(delta: float) -> void:
	var cam_basis := camera.global_transform.basis if camera else Basis.IDENTITY
	_upd_particles(_add, _mm_add, delta, cam_basis)
	_upd_particles(_mix, _mm_mix, delta, cam_basis)
	# 环
	var i := _rings.size() - 1
	while i >= 0:
		var r: Dictionary = _rings[i]
		r.life = float(r.life) - delta
		r.r = float(r.r) + float(r.grow) * delta
		if float(r.life) <= 0.0:
			_rings.remove_at(i)
		i -= 1
	_mm_ring.visible_instance_count = _rings.size()
	for k in _rings.size():
		var r: Dictionary = _rings[k]
		var s := float(r.r) * 2.0
		_mm_ring.set_instance_transform(k, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3(s, s, s)), r.pos))
		var c: Color = r.color
		c.a = clampf(float(r.life) / float(r.max), 0.0, 1.0)
		_mm_ring.set_instance_color(k, c)
		_mm_ring.set_instance_custom_data(k, Color(float(r.w), 0, 0, 0))
	# 灯
	for L in _lights:
		if float(L.t) > 0.0:
			L.t = float(L.t) - delta
			var l: OmniLight3D = L.light
			l.light_energy = float(L.energy) * clampf(float(L.t) / float(L.max), 0.0, 1.0)
			if float(L.t) <= 0.0:
				l.visible = false
	# 数字
	for L in _labels:
		if float(L.t) > 0.0:
			L.t = float(L.t) - delta
			var lb: Label3D = L.label
			lb.position.y += float(L.vel) * delta
			L.vel = float(L.vel) * exp(-3.0 * delta)
			var k2 := float(L.t) / float(L.max)
			lb.modulate.a = clampf(k2 * 2.2, 0.0, 1.0)
			if float(L.t) <= 0.0:
				lb.visible = false
	# 弹壳
	var n := 0
	var nr := 0
	i = _shells.size() - 1
	while i >= 0:
		var s: Dictionary = _shells[i]
		s.life = float(s.life) - delta
		if float(s.life) <= 0.0:
			_shells.remove_at(i)
			i -= 1
			continue
		var p: Vector3 = s.pos
		var v: Vector3 = s.vel
		if p.y > 0.0 or v.y != 0.0:
			v.y -= 9.0 * delta
			p += v * delta
			if p.y <= 0.006:
				p.y = 0.006
				if v.y < -0.6:
					s.tinks = int(s.tinks) + 1
					if int(s.tinks) <= 2 and on_shell_tink.is_valid():
						on_shell_tink.call(p, bool(s.red))
					v.y = -v.y * 0.4
					v.x *= 0.6
					v.z *= 0.6
					s.vr = (s.vr as Vector3) * 0.5
				else:
					v.y = 0.0
		var f := exp(-(0.5 if p.y > 0.01 else 6.0) * delta)
		v.x *= f
		v.z *= f
		s.pos = p
		s.vel = v
		s.rot = (s.rot as Vector3) + (s.vr as Vector3) * delta * (1.0 if p.y > 0.01 else 0.0)
		i -= 1
	for s in _shells:
		var rot: Vector3 = s.rot
		var xf := Transform3D(Basis.from_euler(Vector3(PI * 0.5 if s.pos.y <= 0.0065 else rot.x, rot.y, 0)), s.pos)
		if s.red:
			if nr < 60:
				_mm_shell_red.set_instance_transform(nr, xf)
				nr += 1
		else:
			_mm_shell.set_instance_transform(n, xf)
			n += 1
	_mm_shell.visible_instance_count = n
	_mm_shell_red.visible_instance_count = nr
	# 焦痕淡出
	i = _decals.size() - 1
	while i >= 0:
		var d: Dictionary = _decals[i]
		d.t = float(d.t) - delta
		var dn: Decal = d.node
		dn.modulate.a = clampf(float(d.t) / 6.0, 0.0, 0.9)
		if float(d.t) <= 0.0:
			dn.queue_free()
			_decals.remove_at(i)
		i -= 1


func _upd_particles(list: Array, mm: MultiMesh, delta: float, cam: Basis) -> void:
	var i := list.size() - 1
	while i >= 0:
		var p: Particle = list[i]
		p.life -= delta
		if p.life <= 0.0:
			list[i] = list[list.size() - 1]
			list.pop_back()
			i -= 1
			continue
		if p.drag > 0.0:
			p.vel *= exp(-p.drag * delta)
		p.vel.y -= p.grav * delta
		p.pos += p.vel * delta
		if p.pos.y < 0.0:
			p.pos.y = 0.0
			if p.bounce and p.vel.y < -0.4:
				p.vel.y *= -0.35
				p.vel.x *= 0.6
				p.vel.z *= 0.6
			else:
				p.vel = Vector3(p.vel.x * 0.85, 0.0, p.vel.z * 0.85)
		p.size = maxf(0.001, p.size + p.grow * delta)
		i -= 1
	mm.visible_instance_count = list.size()
	for k in list.size():
		var p: Particle = list[k]
		var b: Basis
		if p.stretch > 0.0 and p.vel.length_squared() > 0.01:
			# 拉长条：沿速度方向（屏幕上）拉长
			var dir := p.vel.normalized()
			var right := dir
			var up := cam.z.cross(right).normalized()
			var len := p.size + p.vel.length() * 0.035 * p.stretch
			b = Basis(right * len, up * p.size, cam.z)
		else:
			b = Basis(cam.x * p.size, cam.y * p.size, cam.z)
		mm.set_instance_transform(k, Transform3D(b, p.pos))
		var c := p.color
		var lf := p.life / p.max_life
		if p.shape == S_STAR or p.shape == S_STREAK or p.shape == S_CIRCLE:
			c.a *= clampf(lf * 1.6, 0.0, 1.0)
		mm.set_instance_color(k, c)
		mm.set_instance_custom_data(k, Color(float(p.shape), 1.0 - lf, 0, 0))


func sync_tracers(bullets: Array, alpha: float, cam: Basis, team_vis: Callable) -> void:
	var n := 0
	for b: SimBullet in bullets:
		if n >= MAX_TRACER:
			break
		if b.kind == "rocket" or b.kind == "flame" or b.kind == "swave":
			continue   # 火箭 / 火焰 / 剑气由 WorldFx 画
		var x := lerpf(b.px, b.x, alpha) * 0.01
		var z := lerpf(b.py, b.y, alpha) * 0.01
		var pos := Vector3(x, b.h * 0.01, z)
		if not team_vis.call(b, pos):
			continue
		var v := Vector3(b.vx, 0, b.vy) * 0.01
		var sp := v.length()
		var dir := v / maxf(sp, 0.001)
		var len := clampf(sp * 0.03, 0.06, 0.5)
		var wdt := 0.03
		var col := Color("#bfe0ff") if b.team == "blue" else (Color("#ffd2b8") if b.team == "red" else Color("#ffb3e6"))
		match b.kind:
			"pel":
				len *= 0.6
				wdt = 0.03
			"seed":
				len = 0.16
				wdt = 0.12
				col = Color("#5fb0ff") if b.team == "blue" else Color("#ff6070")
			"mpea":
				len = 0.1
				wdt = 0.06
				col = Color("#6fb8ff") if b.team == "blue" else Color("#ff6f8a")
			"snipe":
				len = clampf(sp * 0.05, 0.3, 0.9)
				wdt = 0.045
				col = Color("#bff4ff")
			"orb":
				len = 0.14
				wdt = 0.14
				col = Color("#ff7fd0")
			"rat":
				len = 0.12
				wdt = 0.07
				col = Color("#ffb070")
			"spike":
				len = 0.1
				wdt = 0.04
				col = Color("#d9b48a")
		var up := cam.z.cross(dir).normalized()
		var basis := Basis(dir * len, up * wdt, cam.z)
		_mm_tracer.set_instance_transform(n, Transform3D(basis, pos - dir * len * 0.4))
		_mm_tracer.set_instance_color(n, col)
		n += 1
	_mm_tracer.visible_instance_count = n


func sync_items(items: Array, alpha: float, t: float) -> void:
	var n := 0
	var nb := 0
	var seen := {}
	for g: SimItem in items:
		var pos := Vector3(g.x * 0.01, 0.02 + g.z * 0.01 + 0.015 * sin(t * 4.0 + g.id), g.y * 0.01)
		if g.type == "gem":
			var xf := Transform3D(Basis(Vector3.UP, t * 2.0 + g.id).rotated(Vector3.RIGHT, 0.25), pos)
			if g.big:
				if nb < 80:
					_mm_gem_big.set_instance_transform(nb, xf)
					nb += 1
			elif n < MAX_GEM:
				_mm_gem.set_instance_transform(n, xf)
				n += 1
		else:
			seen[g.id] = true
			if not _cheese_nodes.has(g.id):
				var c := ToonMaterials.instance("res://assets/models/props/prop_cheese.glb", 1.2)
				add_child(c)
				_cheese_nodes[g.id] = c
			var cn: Node3D = _cheese_nodes[g.id]
			cn.position = pos
			cn.rotation.y = t * 1.5
	_mm_gem.visible_instance_count = n
	_mm_gem_big.visible_instance_count = nb
	for id in _cheese_nodes.keys():
		if not seen.has(id):
			(_cheese_nodes[id] as Node).queue_free()
			_cheese_nodes.erase(id)


const LOB_MODEL := {
	"frag": ["res://assets/models/props/prop_frag.glb", 1.6], "molo": ["res://assets/models/props/gad_molotov.glb", 1.0],
	"flsh": ["res://assets/models/props/gad_flash.glb", 1.1], "smk": ["res://assets/models/props/gad_smoke.glb", 1.1],
	"flr": ["res://assets/models/props/gad_flare.glb", 1.0], "frz": ["res://assets/models/props/gad_freeze.glb", 1.1],
	"gnade": ["res://assets/models/props/fx_gnade.glb", 1.4], "bomb": ["res://assets/models/props/fx_bomb.glb", 1.3],
}


func sync_lobs(lobs: Array) -> void:
	var seen := {}
	for L: SimLob in lobs:
		seen[L.id] = true
		if not _lob_nodes.has(L.id):
			var spec: Array = LOB_MODEL.get(L.kind, LOB_MODEL.frag)
			var n := ToonMaterials.instance(String(spec[0]), 1.2)
			n.scale = Vector3.ONE * float(spec[1])
			add_child(n)
			_lob_nodes[L.id] = n
		var node: Node3D = _lob_nodes[L.id]
		node.position = Vector3(L.x * 0.01, L.z * 0.01, L.y * 0.01)
		if L.att == null and not L.stuck:
			node.rotation = Vector3(L.rot, L.rot * 0.7, 0)
		if L.fuse >= 0.0 and L.fuse < 0.6:
			ToonMaterials.set_param(node, "flash", 0.6 if fmod(L.fuse, 0.16) < 0.08 else 0.0)
		elif L.sticky:
			ToonMaterials.set_param(node, "flash", 0.5 if fmod(Time.get_ticks_msec() / 1000.0, 0.5) < 0.1 else 0.0)
		if (L.kind == "molo" or L.kind == "flr") and _rng.randf() < 0.6:
			spawn(node.position + Vector3(0, 0.12, 0), Vector3(0, 0.3, 0), 0.18, _rng.randf_range(0.05, 0.08), Color(1.0, 0.6, 0.2), S_CIRCLE, true, -0.5, 2.0, -0.1)
		elif _rng.randf() < 0.4:
			spawn(node.position, Vector3(_rng.randf_range(-0.1, 0.1), 0.08, _rng.randf_range(-0.1, 0.1)), 0.35, _rng.randf_range(0.03, 0.05), Color(0.72, 0.7, 0.77, 0.5), S_SMOKE, false, -0.1, 2.0, 0.1)
	for id in _lob_nodes.keys():
		if not seen.has(id):
			(_lob_nodes[id] as Node).queue_free()
			_lob_nodes.erase(id)
