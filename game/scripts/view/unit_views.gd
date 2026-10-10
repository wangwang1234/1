class_name UnitViews
extends RefCounted
## 小兵、建筑、物件、箱子的表现节点（程序动作，无骨骼）。


class MinionView:
	extends Node3D
	var sim_id := 0
	var model: Node3D
	var body: Node3D
	var gun: Node3D
	var leg_l: Node3D
	var leg_r: Node3D
	var _kick := 0.0
	var _vis := 0.0
	var _dying := 0.0

	func setup(m: SimMinion) -> void:
		sim_id = m.id
		model = ToonMaterials.instance("res://assets/models/units/unit_minion.glb", 1.8)
		add_child(model)
		ToonMaterials.set_param(model, "team_index", 0 if m.team == "blue" else 1)
		var tc := Color("#4fa3ff") if m.team == "blue" else Color("#ff5b5b")
		ToonMaterials.set_param(model, "rim_tint", Color(tc.r, tc.g, tc.b, 0.5))
		body = model.find_child("body", true, false)
		gun = model.find_child("gun", true, false)
		leg_l = model.find_child("leg_L", true, false)
		leg_r = model.find_child("leg_R", true, false)

	func sync(m: SimMinion, alpha: float, delta: float, seen: bool) -> void:
		_vis = move_toward(_vis, 1.0 if seen else 0.0, delta * 8.0)
		visible = _vis > 0.02
		if not visible:
			return
		position = Vector3(lerpf(m.px, m.x, alpha) * 0.01, 0, lerpf(m.py, m.y, alpha) * 0.01)
		rotation.y = lerp_angle(rotation.y, HamsterView.yaw_for(m.aim), 1.0 - exp(-14.0 * delta))
		var sp := Vector2(m.vx, m.vy).length() / 95.0
		var ph := m.walk
		if body:
			body.position.y = absf(sin(ph)) * 0.02 * sp
			body.rotation.x = -0.12 * sp
			body.rotation.z = sin(ph) * 0.06 * sp
		if leg_l:
			leg_l.position.z = sin(ph) * 0.03 * sp
			leg_l.position.y = maxf(0.0, cos(ph)) * 0.015 * sp
		if leg_r:
			leg_r.position.z = -sin(ph) * 0.03 * sp
			leg_r.position.y = maxf(0.0, -cos(ph)) * 0.015 * sp
		_kick = move_toward(_kick, 0.0, delta * 0.2)
		if gun:
			gun.position.z = _kick
		ToonMaterials.set_param(model, "flash", clampf(m.flash / 0.09, 0.0, 1.0) * 0.8)

	func on_fire() -> void:
		_kick = 0.02


class StructureView:
	extends Node3D
	var sim_id := 0
	var kind := ""
	var team := ""
	var model: Node3D
	var head: Node3D
	var flag: Node3D
	var shield: MeshInstance3D
	var light: OmniLight3D
	var _t := 0.0
	var _recoil := 0.0
	var _dead := false
	var _smoke_t := 0.0
	var fx: FxSystem
	var _stage := -1
	var _dmg: Array = []          # [dmg1, dmg2]（底座 / 鼠窝本体上的破损件）
	var _hdmg: Array = []         # [hdmg1, hdmg2]（炮塔头上的破损件，跟着炮塔头转）
	var _wreck: Node3D
	var _intact: Array = []       # 被摧毁后隐藏的部件
	var _thr: Array = [0.66, 0.33]
	var _smoke_every := 0.18

	func setup(s: SimStructure) -> void:
		sim_id = s.id
		kind = s.kind
		team = s.team
		var path := "res://assets/models/units/unit_base.glb" if s.kind == "base" else "res://assets/models/units/unit_turret.glb"
		model = ToonMaterials.instance(path, 2.5 if s.kind == "base" else 2.0)
		add_child(model)
		ToonMaterials.set_param(model, "team_index", 0 if s.team == "blue" else 1)
		head = model.find_child("head", true, false)
		flag = model.find_child("flag", true, false)
		position = Vector3(s.x * 0.01, 0, s.y * 0.01)
		_thr = Data.rule("view.structDamage", [0.66, 0.33])
		_smoke_every = float(Data.rule("view.structSmokeEvery", 0.18))
		for nm: String in ["dmg1", "dmg2"]:
			_dmg.append(model.find_child(nm, true, false))
		for nm: String in ["hdmg1", "hdmg2"]:
			_hdmg.append(model.find_child(nm, true, false))
		_wreck = model.find_child("wreck", true, false)
		for nm: String in ["house", "base", "head", "pole", "flag"]:
			var n := model.find_child(nm, true, false)
			if n:
				_intact.append(n)
		_set_stage(0)
		if s.kind == "base":
			# 鼠窝的门朝向敌方
			model.rotation.y = 0.0 if s.team == "blue" else PI
			shield = MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 1.0
			sph.height = 2.0
			sph.radial_segments = 48
			sph.rings = 24
			shield.mesh = sph
			var m := ShaderMaterial.new()
			m.shader = preload("res://shaders/shield_bubble.gdshader")
			var c := Color("#4fa3ff") if s.team == "blue" else Color("#ff5b5b")
			m.set_shader_parameter("color", c)
			shield.material_override = m
			shield.scale = Vector3(1.7, 1.45, 1.7)
			shield.position = Vector3(0, 0.4, 0)
			shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(shield)
		light = OmniLight3D.new()
		light.light_color = Color("#4fa3ff") if s.team == "blue" else Color("#ff5b5b")
		light.light_energy = 0.6
		light.omni_range = 2.2 if s.kind == "base" else 1.8
		light.position = Vector3(0, 1.3 if s.kind == "base" else 0.8, 0)
		light.light_specular = 0.55
		light.light_size = 0.14
		add_child(light)

	func sync(s: SimStructure, delta: float) -> void:
		_t += delta
		if head:
			head.rotation.y = lerp_angle(head.rotation.y, HamsterView.yaw_for(s.aim), 1.0 - exp(-20.0 * delta))
			_recoil = move_toward(_recoil, 0.0, delta * 0.4)
			head.position.y = 0.6 - _recoil * 0.3
		if flag:
			flag.rotation.z = sin(_t * 3.1) * 0.12
			flag.rotation.y = sin(_t * 1.7) * 0.2
		if shield:
			shield.visible = s.shielded and not s.dead
			(shield.material_override as ShaderMaterial).set_shader_parameter("hit", s.shield_hit / 0.15)
		ToonMaterials.set_param(model, "flash", clampf(s.flash / 0.09, 0.0, 1.0) * 0.6)
		var hpk := clampf(s.hp / s.max_hp, 0.0, 1.0)
		var st := 3 if s.dead else (2 if hpk <= float(_thr[1]) else (1 if hpk <= float(_thr[0]) else 0))
		if st != _stage:
			_set_stage(st)
		if s.dead and not _dead:
			_dead = true
			ToonMaterials.set_param(model, "tint", Color(0.62, 0.58, 0.64, 1))
			light.visible = false
			_burst()
		if not s.dead:
			ToonMaterials.set_param(model, "tint", Color(1, 1, 1, 1).lerp(Color(0.85, 0.8, 0.82, 1), 1.0 - hpk))
		_emit(delta)

	func _set_stage(st: int) -> void:
		## 0 完好 / 1 轻损 / 2 重损 / 3 摧毁（只显示废墟）
		var up := st > _stage and _stage >= 0
		_stage = st
		for i in 2:
			var on := st >= i + 1 and st < 3
			if _dmg[i]:
				(_dmg[i] as Node3D).visible = on
			if _hdmg[i]:
				(_hdmg[i] as Node3D).visible = on
		if _wreck:
			_wreck.visible = st == 3
			for n: Node3D in _intact:
				n.visible = st != 3
		elif st == 3 and head:
			head.rotation.x = 0.5
			head.position.y = 0.45
		if up and st < 3:
			Audio.play3d("clank", global_position + Vector3(0, 0.5, 0), -3.0, 0.15, 0.2)
		if up and fx and st < 3:
			# 掉一个破损阶段：一小撮碎片 + 尘土
			var p := global_position + Vector3(0, 1.0 if kind == "base" else 0.5, 0)
			for i in 8:
				var d := Vector3(randf_range(-1, 1), randf_range(0.5, 1.4), randf_range(-1, 1))
				fx.spawn(p, d * 1.6, randf_range(0.5, 0.9), randf_range(0.04, 0.07), Color("#c89359") if kind == "base" else Color("#8c8a99"), FxSystem.S_CHUNK, false, 6.0, 0.5, 0.0, true)
			for i in 5:
				fx.spawn(p + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)), Vector3(randf_range(-0.3, 0.3), 0.5, randf_range(-0.3, 0.3)), randf_range(0.7, 1.1), randf_range(0.16, 0.26), Color(0.55, 0.52, 0.6, 0.8), FxSystem.S_SMOKE, false, -0.2, 1.5, 0.3)

	func _burst() -> void:
		## 被摧毁：大团尘土 + 碎片四散
		if fx == null:
			return
		var big := kind == "base"
		var p := global_position + Vector3(0, 0.6 if big else 0.3, 0)
		for i in (26 if big else 14):
			var d := Vector3(randf_range(-1, 1), randf_range(0.6, 1.6), randf_range(-1, 1))
			fx.spawn(p, d * (2.6 if big else 1.8), randf_range(0.6, 1.1), randf_range(0.05, 0.1), Color("#c89359") if big and i % 3 != 0 else Color("#8c8a99"), FxSystem.S_CHUNK, false, 7.0, 0.4, 0.0, true)
		for i in (16 if big else 9):
			var o := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * (1.2 if big else 0.5)
			fx.spawn(p + o, Vector3(o.x, 0.6, o.z) * 0.5, randf_range(1.2, 2.0), randf_range(0.35, 0.6) * (1.3 if big else 1.0), Color(0.42, 0.4, 0.46, 0.85), FxSystem.S_SMOKE, false, -0.15, 1.2, 0.35)

	func _emit(delta: float) -> void:
		## 重损冒黑烟、偶尔冒火花；废墟冒一阵细烟
		if fx == null or _stage < 2:
			return
		_smoke_t -= delta
		if _smoke_t > 0.0:
			return
		_smoke_t = _smoke_every * (2.5 if _stage == 3 else 1.0) * randf_range(0.7, 1.3)
		var top := Vector3(randf_range(-0.4, 0.4), 1.6, randf_range(-0.4, 0.4)) if kind == "base" else Vector3(randf_range(-0.15, 0.15), 0.5, randf_range(-0.15, 0.15))
		if _stage == 3:
			top.y *= 0.3
		fx.spawn(global_position + top, Vector3(randf_range(-0.1, 0.1), 0.45, randf_range(-0.1, 0.1)), randf_range(1.2, 1.8), randf_range(0.14, 0.22) * (1.4 if kind == "base" else 1.0), Color(0.2, 0.19, 0.23, 0.75), FxSystem.S_SMOKE, false, -0.12, 1.0, 0.22)
		if _stage == 2 and randf() < 0.25:
			for i in 4:
				fx.spawn(global_position + top, Vector3(randf_range(-1, 1), randf_range(0.6, 1.5), randf_range(-1, 1)), 0.3, 0.025, Color("#ffd166"), FxSystem.S_STAR, true, 5.0, 0.6)

	func on_fire() -> void:
		_recoil = 0.12


class PropView:
	extends Node3D
	var sim_id := 0
	var kind := ""
	var model: Node3D
	var light: OmniLight3D
	var _dead := false
	var _pop := 1.0
	var _t := 0.0

	func setup(p: SimProp) -> void:
		sim_id = p.id
		kind = p.kind
		model = ToonMaterials.instance("res://assets/models/props/prop_%s.glb" % p.kind, 1.5)
		add_child(model)
		position = Vector3(p.x * 0.01, 0, p.y * 0.01)
		model.rotation.y = p.rot
		if p.kind == "lamp":
			light = OmniLight3D.new()
			light.light_color = Color(1.0, 0.82, 0.55)
			light.light_energy = 1.5
			light.omni_range = 3.6
			light.omni_attenuation = 1.0
			light.position = Vector3(0, 0.46, 0)
			light.shadow_enabled = true
			light.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID   # 2 次阴影渲染（立方体是 6 次）
			light.light_specular = 0.55
			light.light_size = 0.14
			add_child(light)

	func sync(p: SimProp, delta: float) -> void:
		_t += delta
		if p.dead != _dead:
			_dead = p.dead
			model.visible = not _dead
			if light:
				light.visible = not _dead
			if not _dead:
				_pop = 0.0
		if not _dead:
			_pop = minf(1.0, _pop + delta * 4.0)
			var k := _pop
			var sc := 1.0 + sin(k * PI) * 0.15 * (1.0 - k) if k < 1.0 else 1.0
			model.scale = Vector3.ONE * (0.2 + 0.8 * k) * sc
			ToonMaterials.set_param(model, "flash", clampf(p.flash / 0.1, 0.0, 1.0) * 0.7)
			if light:
				light.light_energy = 1.5 + sin(_t * 23.0) * 0.03 + sin(_t * 7.0) * 0.04


class CrateView:
	extends Node3D
	var sim_id := 0
	var model: Node3D
	var _t := 0.0

	func setup(c: SimCrate) -> void:
		sim_id = c.id
		model = ToonMaterials.instance("res://assets/models/props/prop_gift.glb" if c.big else "res://assets/models/props/prop_crate.glb", 1.5)
		add_child(model)
		position = Vector3(c.x * 0.01, 0, c.y * 0.01)
		model.rotation.y = fmod(c.x * 0.37 + c.y * 0.11, TAU)
		model.scale = Vector3.ONE * 0.1

	func sync(c: SimCrate, delta: float) -> void:
		_t += delta
		var k := minf(1.0, _t * 3.0)
		model.scale = Vector3.ONE * (k + sin(k * PI) * 0.2)
		var hk := 1.0 - c.hp / c.max_hp
		model.rotation.z = sin(_t * 40.0) * 0.06 * c.flash / 0.09
		ToonMaterials.set_param(model, "flash", clampf(c.flash / 0.09, 0.0, 1.0) * 0.6)
