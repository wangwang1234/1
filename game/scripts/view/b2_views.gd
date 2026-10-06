class_name B2Views
extends RefCounted
## 批次 2 新实体的表现节点：野怪（蟑螂 / 鼠帮枪手 / 鼠王）、宠物、诱饵、哨戒炮、地雷、信标、照明弹。
## 全部程序动作（无骨骼），只读 sim 状态。

const TEAM_COL := {"blue": Color("#4fa3ff"), "red": Color("#ff5b5b"), "neutral": Color("#ffd166")}


static func _tex_laser() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.15, 0.2, 0.8)
	m.no_depth_test = false
	return m


class MobView:
	extends Node3D
	var sim_id := 0
	var kind := ""
	var model: Node3D
	var body: Node3D
	var legs_a: Node3D
	var legs_b: Node3D
	var antennae: Node3D
	var head: Node3D
	var tail: Node3D
	var gun: Node3D
	var crown: Node3D
	var laser: MeshInstance3D
	var _vis := 0.0
	var _t := 0.0
	var _pop := 0.0

	func setup(e: SimMob) -> void:
		sim_id = e.id
		kind = e.kind
		model = ToonMaterials.instance("res://assets/models/units/mob_%s.glb" % e.kind, 2.6 if e.kind == "boss" else 1.8)
		add_child(model)
		body = model.find_child("body", true, false)
		legs_a = model.find_child("legsA", true, false)
		legs_b = model.find_child("legsB", true, false)
		antennae = model.find_child("antennae", true, false)
		head = model.find_child("head", true, false)
		tail = model.find_child("tail", true, false)
		gun = model.find_child("gun", true, false)
		crown = model.find_child("crown", true, false)
		ToonMaterials.set_param(model, "glow", 0.12)
		if e.kind == "rat" or e.kind == "boss":
			# 蹲下瞄准时的红色激光（原型：rat 蓄力 0.45 秒）
			laser = MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.006, 0.006, 1.0)
			laser.mesh = bm
			laser.material_override = B2Views._tex_laser()
			laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			laser.visible = false
			add_child(laser)
		model.scale = Vector3.ONE * 0.2

	func sync(e: SimMob, alpha: float, delta: float, seen: bool) -> void:
		_t += delta
		_vis = move_toward(_vis, 1.0 if seen else 0.0, delta * 8.0)
		visible = _vis > 0.02
		if not visible:
			return
		_pop = minf(1.0, _pop + delta * 4.0)
		position = Vector3(lerpf(e.px, e.x, alpha) * 0.01, 0, lerpf(e.py, e.y, alpha) * 0.01)
		var face := e.heading if e.kind == "roach" else e.aim
		rotation.y = lerp_angle(rotation.y, HamsterView.yaw_for(face), 1.0 - exp(-14.0 * delta))
		var sp := Vector2(e.vx, e.vy).length() / maxf(1.0, e.spd)
		var ph := e.walk * (6.0 if kind == "roach" else 1.0)
		var sc := 0.2 + 0.8 * _pop
		var wob := sin(_t * 30.0) * 0.08 if e.stun > 0.0 else 0.0
		model.scale = Vector3.ONE * sc
		model.rotation.z = wob
		match kind:
			"roach":
				if legs_a:
					legs_a.rotation.z = sin(ph) * 0.35 * sp
				if legs_b:
					legs_b.rotation.z = -sin(ph) * 0.35 * sp
				if antennae:
					antennae.rotation.x = sin(_t * 9.0 + e.ph) * 0.25
				model.position.y = absf(sin(ph)) * 0.008 * sp
			_:
				var k := 2.4 if kind == "boss" else 1.0
				if body:
					body.position.y = absf(sin(ph)) * 0.015 * sp * k
					body.rotation.x = -0.1 * sp
				if tail:
					tail.rotation.y = sin(_t * 3.0 + e.ph) * 0.4
				if gun:
					gun.position.z = e.recoil * 0.025 * k
				if head:
					head.rotation.x = -0.25 if e.tele > 0.0 else 0.0
				if crown:
					crown.position.y = sin(_t * 2.0) * 0.01
				# 蹲下瞄准
				model.position.y = -0.03 * k if e.tele > 0.0 else 0.0
				if laser:
					laser.visible = e.tele > 0.0
					if laser.visible:
						var L := 4.5
						var a := e.aim
						var mh := 0.17 * k
						laser.global_transform = Transform3D(Basis(Vector3.UP, HamsterView.yaw_for(a)).scaled(Vector3(1, 1, L)), global_position + Vector3(cos(a), 0, sin(a)) * (L * 0.5 + 0.2 * k) + Vector3(0, mh, 0))
						(laser.material_override as StandardMaterial3D).albedo_color.a = 0.4 + 0.4 * sin(_t * 40.0)
		ToonMaterials.set_param(model, "flash", clampf(e.flash / 0.09, 0.0, 1.0) * 0.85)
		ToonMaterials.set_param(model, "tint", Color(0.7, 0.92, 1.35, 1) if e.frozen_until > 0.0 and e.stun > 0.0 else Color(1, 1, 1, 1))


class PetView:
	extends Node3D
	var sim_id := 0
	var type := ""
	var model: Node3D
	var wings: Node3D
	var light: OmniLight3D
	var _t := 0.0
	var _peck := 0.0
	var _vis := 0.0

	func setup(p: SimPet) -> void:
		sim_id = p.id
		type = p.type
		model = ToonMaterials.instance("res://assets/models/units/pet_%s.glb" % p.type, 1.6)
		add_child(model)
		wings = model.find_child("wings", true, false)
		if p.type == "firefly":
			light = OmniLight3D.new()
			light.light_color = Color("#c8ff6a")
			light.light_energy = 0.8
			light.omni_range = 1.2
			light.light_specular = 0.0
			light.position = Vector3(0, 0.05, 0)
			add_child(light)
			ToonMaterials.set_param(model, "glow", 0.4)

	func sync(p: SimPet, alpha: float, delta: float, seen: bool) -> void:
		_t += delta
		_vis = move_toward(_vis, 1.0 if seen else 0.0, delta * 8.0)
		visible = _vis > 0.02
		if not visible:
			return
		position = Vector3(lerpf(p.px, p.x, alpha) * 0.01, p.h * 0.01, lerpf(p.py, p.y, alpha) * 0.01)
		var moving := Vector2(p.x - p.px, p.y - p.py).length() > 0.3
		match type:
			"chick":
				rotation.y = lerp_angle(rotation.y, HamsterView.yaw_for(p.aim), 1.0 - exp(-14.0 * delta))
				model.position.y = absf(sin(_t * 14.0)) * 0.02 if moving else 0.0
				_peck = move_toward(_peck, 0.0, delta * 5.0)
				model.rotation.x = -_peck * 0.6
			"firefly":
				rotation.y = lerp_angle(rotation.y, HamsterView.yaw_for(atan2(p.y - p.py, p.x - p.px)) if moving else rotation.y, 1.0 - exp(-8.0 * delta))
				if wings:
					wings.scale.x = 0.6 + 0.4 * absf(sin(_t * 40.0))
				if light:
					light.light_energy = 0.7 + 0.25 * sin(_t * 6.0)
			_:
				rotation.y = lerp_angle(rotation.y, HamsterView.yaw_for(p.aim), 1.0 - exp(-10.0 * delta))
				model.position.y = absf(sin(_t * 10.0)) * 0.01 if moving else 0.0

	func peck() -> void:
		_peck = 1.0


class DecoyView:
	extends Node3D
	var sim_id := 0
	var model: Node3D
	var _t := 0.0
	var _vis := 0.0

	func setup(d: SimDecoy) -> void:
		sim_id = d.id
		model = ToonMaterials.instance("res://assets/models/props/gad_decoy.glb", 1.8)
		add_child(model)
		ToonMaterials.set_param(model, "team_index", 0 if d.team == "blue" else 1)
		ToonMaterials.set_param(model, "skin_index", maxi(0, Data.skin_ids().find(d.skin)))
		model.scale = Vector3.ONE * 0.1

	func sync(d: SimDecoy, delta: float, seen: bool) -> void:
		_t += delta
		_vis = move_toward(_vis, 1.0 if seen else 0.0, delta * 8.0)
		visible = _vis > 0.02
		if not visible:
			return
		position = Vector3(d.x * 0.01, 0, d.y * 0.01)
		rotation.y = HamsterView.yaw_for(d.aim)
		var k := minf(1.0, _t * 4.0)
		var bob := sin(_t * 3.0) * 0.03
		model.scale = Vector3.ONE * (k + sin(k * PI) * 0.2) * (1.0 + 0.03 * sin(_t * 5.0))
		model.position.y = 0.02 + bob
		model.rotation.z = sin(_t * 2.3) * 0.08
		ToonMaterials.set_param(model, "flash", clampf(d.flash / 0.09, 0.0, 1.0) * 0.8)


class SentryView:
	extends Node3D
	var sim_id := 0
	var model: Node3D
	var head: Node3D
	var light: OmniLight3D
	var _t := 0.0
	var _recoil := 0.0
	var _vis := 0.0

	func setup(s: SimStructure) -> void:
		sim_id = s.id
		model = ToonMaterials.instance("res://assets/models/props/gad_sentry.glb", 1.6)
		add_child(model)
		ToonMaterials.set_param(model, "team_index", 0 if s.team == "blue" else 1)
		head = model.find_child("head", true, false)
		position = Vector3(s.x * 0.01, 0, s.y * 0.01)
		light = OmniLight3D.new()
		light.light_color = B2Views.TEAM_COL[s.team]
		light.light_energy = 0.5
		light.omni_range = 1.2
		light.light_specular = 0.0
		light.position = Vector3(0, 0.25, 0)
		add_child(light)
		model.scale = Vector3.ONE * 0.1

	func sync(s: SimStructure, delta: float, seen: bool) -> void:
		_t += delta
		_vis = move_toward(_vis, 1.0 if seen else 0.0, delta * 8.0)
		visible = _vis > 0.02 and not s.dead
		if not visible:
			return
		var k := minf(1.0, _t * 4.0)
		model.scale = Vector3.ONE * (k + sin(k * PI) * 0.25)
		if head:
			head.rotation.y = lerp_angle(head.rotation.y, HamsterView.yaw_for(s.aim) - rotation.y, 1.0 - exp(-20.0 * delta))
			_recoil = move_toward(_recoil, 0.0, delta * 0.3)
			head.position.y = 0.17 - _recoil * 0.2
		# 快到时间时闪烁
		var blink := s.life < 3.0 and fmod(_t, 0.3) < 0.15
		ToonMaterials.set_param(model, "flash", maxf(clampf(s.flash / 0.09, 0.0, 1.0) * 0.8, 0.4 if blink else 0.0))

	func on_fire() -> void:
		_recoil = 0.06


class SimpleNode:
	## 地雷、信标、照明弹等：只需要位置和简单动画的模型
	extends Node3D
	var key := ""
	var model: Node3D
	var light: OmniLight3D
	var _t := 0.0
	var kind := ""

	func setup(kind_: String, path: String, team: String, light_col: Color = Color.BLACK, light_e: float = 0.0, light_r: float = 1.0) -> void:
		kind = kind_
		model = ToonMaterials.instance(path, 1.4)
		add_child(model)
		ToonMaterials.set_param(model, "team_index", 0 if team == "blue" else 1)
		if light_e > 0.0:
			light = OmniLight3D.new()
			light.light_color = light_col
			light.light_energy = light_e
			light.omni_range = light_r
			light.light_specular = 0.0
			add_child(light)

	func tick(delta: float) -> void:
		_t += delta
		match kind:
			"mine":
				ToonMaterials.set_param(model, "glow", 0.9 if fmod(_t, 1.0) < 0.15 else 0.1)
			"beacon":
				model.rotation.y = _t * 1.5
				if light:
					light.light_energy = 0.6 + 0.3 * sin(_t * 5.0)
			"flare":
				model.rotation.y = _t * 0.7
				model.position.x = sin(_t * 1.3) * 0.04
				if light:
					light.light_energy = 2.6 + 0.5 * sin(_t * 23.0) + 0.3 * sin(_t * 7.0)
