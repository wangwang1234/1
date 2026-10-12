class_name GadgetViews
extends RefCounted
## Q / E 双槽新道具的表现（2026-10-12）：
## - DepView：道具部署物（SimStructure kind = dep）。模型 res://assets/models/props/gad_<道具>.glb（tools/blender/assets/props/gadget_kit2.py），
##   底座有队伍色灯圈 + 队伍色小灯；按功能件加范围指示（再生力场的绿圈、反射器的青圈、己方摄像头的视野圈）。
## - HoloView：全息诱饵 = 一只和主人一模一样的 HamsterView（同皮肤、同武器、同挂件）；只有己方看得出是全息影像（青色闪烁）。
## - SnapFx：捕鼠夹夹住的瞬间，在受害者脚下摆一个合上的夹子，定身时间到就消失。

const MODEL_SCALE := {"cam": 1.7, "trap": 1.5, "cover": 1.0, "regen": 1.45, "guardgun": 1.45, "reflector": 1.5}
const FIELD_COL := {"regen": Color("#8de0a6"), "reflector": Color("#7fe3ff"), "cam": Color("#ffffff")}


static func _ring_mesh(r: float, w: float, col: Color, a: float) -> MeshInstance3D:
	## 贴地的细环（范围指示）
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = maxf(0.001, r - w)
	tm.outer_radius = r
	tm.rings = 48
	tm.ring_segments = 4
	mi.mesh = tm
	mi.scale = Vector3(1, 0.05, 1)
	mi.material_override = _glow_mat(col, a)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _glow_mat(col: Color, a: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r, col.g, col.b, a)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


class DepView:
	extends Node3D
	var sim_id := 0
	var dep := ""
	var team := "blue"
	var model: Node3D
	var head: Node3D
	var light: OmniLight3D
	var field: MeshInstance3D       # 范围指示（环）
	var _t := 0.0
	var _vis := 0.0
	var _recoil := 0.0
	var _flash := 0.0
	var _base_scale := 1.0

	func setup(s: SimStructure, own: bool) -> void:
		sim_id = s.id
		dep = s.dep
		team = s.team
		_base_scale = float(GadgetViews.MODEL_SCALE.get(dep, 1.4))
		var path := "res://assets/models/props/gad_%s.glb" % dep
		if not ResourceLoader.exists(path):
			path = "res://assets/models/props/gad_sentry.glb"
		model = ToonMaterials.instance(path, 1.5)
		add_child(model)
		ToonMaterials.set_param(model, "team_index", 0 if team == "blue" else 1)
		head = model.find_child("head", true, false)
		position = Vector3(s.x * 0.01, 0, s.y * 0.01)
		rotation.y = HamsterView.yaw_for(s.aim)
		var tc: Color = B2Views.TEAM_COL[team]
		if dep != "trap":
			light = OmniLight3D.new()
			light.light_color = tc
			light.light_energy = 0.45
			light.omni_range = 1.0
			light.light_specular = 0.0
			light.position = Vector3(0, 0.22, 0)
			add_child(light)
		var P: Dictionary = s.cfg.get("parts", {})
		if P.has("heal"):
			field = GadgetViews._ring_mesh(float(P.heal.r) * 0.01, 0.05, GadgetViews.FIELD_COL.regen, 0.55)
		elif P.has("reflect"):
			field = GadgetViews._ring_mesh(float(P.reflect.r) * 0.01, 0.03, GadgetViews.FIELD_COL.reflector, 0.5)
		elif P.has("watch") and own:
			field = GadgetViews._ring_mesh(float(P.watch.r) * 0.01, 0.02, tc.lightened(0.3), 0.35)
		if field:
			field.position.y = 0.012
			add_child(field)
			field.top_level = true     # 不跟着模型转
		model.scale = Vector3.ONE * 0.1 * _base_scale

	func sync(s: SimStructure, delta: float, seen: bool, alert: bool) -> void:
		_t += delta
		_vis = move_toward(_vis, 1.0 if seen else 0.0, delta * 8.0)
		visible = _vis > 0.02 and not s.dead
		if not visible:
			return
		position = Vector3(s.x * 0.01, 0, s.y * 0.01)
		if field:
			field.global_position = global_position + Vector3(0, 0.012, 0)
		var k := minf(1.0, _t * 4.0)
		model.scale = Vector3.ONE * (k + sin(k * PI) * 0.25) * _base_scale
		if head:
			head.rotation.y = lerp_angle(head.rotation.y, HamsterView.yaw_for(s.aim) - rotation.y, 1.0 - exp(-20.0 * delta))
			_recoil = move_toward(_recoil, 0.0, delta * 0.3)
			head.position.y = 0.115 - _recoil * 0.2
		# 快到时间时闪烁；受击闪白
		var blink := s.life < 2.5 and fmod(_t, 0.3) < 0.15
		_flash = move_toward(_flash, 0.0, delta * 3.0)
		ToonMaterials.set_param(model, "flash", maxf(maxf(clampf(s.flash / 0.09, 0.0, 1.0) * 0.8, _flash), 0.4 if blink else 0.0))
		if light:
			light.light_energy = 0.45 + (0.9 * absf(sin(_t * 14.0)) if alert else 0.0)
			light.light_color = Color("#ff4d5e") if alert else B2Views.TEAM_COL[team]
		if field:
			var pulse := 1.0 + 0.04 * sin(_t * 4.0)
			field.scale = Vector3(pulse, 0.05, pulse)

	func on_fire() -> void:
		_recoil = 0.05

	func on_hit() -> void:
		_flash = 0.6


class HoloView:
	extends Node3D
	## 全息分身：用一份“代理仓鼠”驱动 HamsterView，外观和主人完全一样
	var sim_id := 0
	var proxy := SimHamster.new()
	var view: HamsterView
	var own := false
	var _t := 0.0
	var _glitch := 0.0

	func setup(d: SimDecoy, own_: bool) -> void:
		sim_id = d.id
		own = own_
		_copy(d)
		view = HamsterView.new()
		add_child(view)
		view.setup(proxy, false)

	func _copy(d: SimDecoy) -> void:
		var o: SimHamster = d.owner if d.owner != null and is_instance_valid(d.owner) else null
		proxy.id = d.id
		proxy.team = d.team
		proxy.skin = d.skin
		proxy.weapon_id = d.weapon_id
		proxy.name = o.name if o != null else "?"
		if o != null:
			proxy.ab = o.ab
			proxy.evo = o.evo
			proxy.lvl = o.lvl
			proxy.r = o.r
			proxy.st = o.st
			proxy.max_hp = o.max_hp
		proxy.alive = true
		proxy.hp = d.hp
		proxy.px = d.px
		proxy.py = d.py
		proxy.x = d.x
		proxy.y = d.y
		proxy.aim = d.aim
		proxy.flash = d.flash

	func sync(d: SimDecoy, alpha: float, delta: float, seen: bool) -> void:
		_t += delta
		_copy(d)
		proxy.walk += delta * 3.0
		view.sync(proxy, alpha, delta, seen)
		if own and view.model:
			# 己方看得出是全息影像：青色闪烁 + 偶尔一帧错位
			_glitch = maxf(0.0, _glitch - delta)
			if randf() < delta * 1.5:
				_glitch = 0.08
			ToonMaterials.set_param(view.model, "flash", 0.25 + 0.15 * sin(_t * 9.0) + (0.4 if _glitch > 0.0 else 0.0))
			view.model.position.x = 0.02 if _glitch > 0.0 else 0.0


class SnapFx:
	extends Node3D
	## 合上的捕鼠夹，摆在被夹住的仓鼠脚下
	var model: Node3D
	var life := 1.5
	var _t := 0.0

	func setup(pos: Vector3, team: String, dur: float) -> void:
		position = pos
		life = dur
		model = ToonMaterials.instance("res://assets/models/props/gad_trap_shut.glb", 1.5)
		add_child(model)
		ToonMaterials.set_param(model, "team_index", 0 if team == "blue" else 1)
		model.scale = Vector3.ONE * 1.5
		rotation.y = randf() * TAU

	func _process(delta: float) -> void:
		_t += delta
		model.position.y = 0.02 * sin(minf(1.0, _t * 8.0) * PI)
		if _t > life:
			queue_free()
