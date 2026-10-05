class_name HamsterView
extends Node3D
## 仓鼠表现：模型、动画树、表情、武器与进化配件、手电、挤压拉伸、受击闪白。
## 只读 SimHamster 状态 + 处理事件，不改逻辑。

const MODEL := "res://assets/models/characters/chr_hamster.glb"
const UPPER := ["spine", "weapon_socket", "arm_L", "forearm_L", "arm_R", "forearm_R"]
const HURT_BONES := ["root", "pelvis", "head", "ear_L", "ear_R"]
const LOOPS := ["idle", "run_fwd", "run_back", "run_left", "run_right", "hold_pistol", "hold_rifle", "hold_shotgun", "victory"]
const CLASS_OF := {"pistol": "pistol", "deagle": "pistol", "revolver": "pistol", "dual": "pistol", "ak47": "rifle", "smg": "rifle", "sniper": "rifle", "lmg": "rifle", "amr": "rifle", "minigun": "rifle", "rail": "rifle", "laser": "rifle", "flame": "rifle", "katana": "pistol", "rocket": "shotgun", "gl": "shotgun", "shotgun": "shotgun", "autoshot": "shotgun"}

var sim_id := 0
var team := "blue"
var is_local := false
var model: Node3D
var skel: Skeleton3D
var anim: AnimationPlayer
var tree: AnimationTree
var rig: HamsterRig
var socket: BoneAttachment3D
var weapon_node: Node3D
var weapon_id := ""
var evo_sig := ""
var flashlight: SpotLight3D
var beam: MeshInstance3D
var exprs := {}
var _sock_fix := Transform3D.IDENTITY
var _cls := ""
var _blink_t := 2.0
var _blink := 0.0
var _happy_t := 0.0
var _squint_t := 0.0
var _sq := 1.0
var _sq_v := 0.0
var _kick := 0.0
var _kick_v := 0.0
var _prev_vel := Vector3.ZERO
var _prev_aim := 0.0
var _dead := false
var _won := false
var _vis := 1.0
var _shown := true
var _air_spin := 0.0


func setup(h: SimHamster, local: bool) -> void:
	sim_id = h.id
	team = h.team
	is_local = local
	name = "Ham_%s" % h.name
	model = ToonMaterials.instance(MODEL, 2.0)
	add_child(model)
	skel = model.find_child("Skeleton3D", true, false)
	anim = model.find_child("AnimationPlayer", true, false)
	for n in model.find_children("expr_*", "", true, false):
		exprs[String(n.name)] = n
	ToonMaterials.set_param(model, "team_index", 0 if h.team == "blue" else 1)
	ToonMaterials.set_param(model, "skin_index", maxi(0, Data.skin_ids().find(h.skin)))
	var tc := Color("#4fa3ff") if h.team == "blue" else Color("#ff5b5b")
	ToonMaterials.set_param(model, "rim_tint", Color(tc.r, tc.g, tc.b, 0.55))
	ToonMaterials.set_param(model, "rim_boost", 0.2)
	ToonMaterials.set_param(model, "glow", 0.22)     # 夜里给角色一点自身亮度，俯视角下也认得出毛色
	_setup_anim()
	if skel:
		rig = HamsterRig.new()
		skel.add_child(rig)
		socket = BoneAttachment3D.new()
		socket.bone_name = "weapon_socket"
		skel.add_child(socket)
		var bi := skel.find_bone("weapon_socket")
		if bi >= 0:
			var rest := skel.get_bone_global_rest(bi)
			_sock_fix = Transform3D(rest.basis.inverse(), Vector3.ZERO)
	_setup_light()
	_set_expr("open", "idle")


func _setup_anim() -> void:
	if anim == null:
		return
	for nm in LOOPS:
		if anim.has_animation(nm):
			anim.get_animation(nm).loop_mode = Animation.LOOP_LINEAR
	var track_prefix := ""
	var a0 := anim.get_animation("hold_pistol")
	if a0 and a0.get_track_count() > 0:
		var p := String(a0.track_get_path(0))
		track_prefix = p.substr(0, p.find(":") + 1)
	tree = AnimationTree.new()
	model.add_child(tree)
	tree.anim_player = tree.get_path_to(anim)
	var bt := AnimationNodeBlendTree.new()
	var bs := AnimationNodeBlendSpace2D.new()
	bs.add_blend_point(_a("idle"), Vector2.ZERO, -1, "idle")
	bs.add_blend_point(_a("run_fwd"), Vector2(0, 1), -1, "run_fwd")
	bs.add_blend_point(_a("run_back"), Vector2(0, -1), -1, "run_back")
	bs.add_blend_point(_a("run_left"), Vector2(-1, 0), -1, "run_left")
	bs.add_blend_point(_a("run_right"), Vector2(1, 0), -1, "run_right")
	bs.sync = true
	bt.add_node("loco", bs, Vector2(0, 0))
	bt.add_node("hold", _a("hold_pistol"), Vector2(0, 200))
	var up := AnimationNodeBlend2.new()
	_filter(up, track_prefix, UPPER)
	bt.add_node("upper", up, Vector2(250, 100))
	bt.connect_node("upper", 0, "loco")
	bt.connect_node("upper", 1, "hold")
	var fire := AnimationNodeOneShot.new()
	fire.fadein_time = 0.02
	fire.fadeout_time = 0.06
	_filter(fire, track_prefix, UPPER)
	bt.add_node("fire", fire, Vector2(500, 100))
	bt.add_node("fire_anim", _a("fire_pistol"), Vector2(250, 300))
	bt.connect_node("fire", 0, "upper")
	bt.connect_node("fire", 1, "fire_anim")
	var rl := AnimationNodeOneShot.new()
	rl.fadein_time = 0.08
	rl.fadeout_time = 0.12
	_filter(rl, track_prefix, UPPER)
	bt.add_node("reload", rl, Vector2(750, 100))
	bt.add_node("reload_anim", _a("reload_pistol"), Vector2(500, 300))
	var ts := AnimationNodeTimeScale.new()
	bt.add_node("reload_ts", ts, Vector2(620, 300))
	bt.connect_node("reload_ts", 0, "reload_anim")
	bt.connect_node("reload", 0, "fire")
	bt.connect_node("reload", 1, "reload_ts")
	var hurt := AnimationNodeOneShot.new()
	hurt.fadein_time = 0.02
	hurt.fadeout_time = 0.1
	_filter(hurt, track_prefix, HURT_BONES)
	bt.add_node("hurt", hurt, Vector2(1000, 100))
	bt.add_node("hurt_anim", _a("hurt"), Vector2(750, 300))
	bt.connect_node("hurt", 0, "reload")
	bt.connect_node("hurt", 1, "hurt_anim")
	var roll := AnimationNodeOneShot.new()
	roll.fadein_time = 0.03
	roll.fadeout_time = 0.08
	bt.add_node("roll", roll, Vector2(1250, 100))
	bt.add_node("roll_anim", _a("dash_roll"), Vector2(1000, 300))
	bt.connect_node("roll", 0, "hurt")
	bt.connect_node("roll", 1, "roll_anim")
	var pop := AnimationNodeOneShot.new()
	pop.fadein_time = 0.0
	pop.fadeout_time = 0.1
	bt.add_node("pop", pop, Vector2(1500, 100))
	bt.add_node("pop_anim", _a("respawn_pop"), Vector2(1250, 300))
	bt.connect_node("pop", 0, "roll")
	bt.connect_node("pop", 1, "pop_anim")
	var st := AnimationNodeTransition.new()
	st.add_input("alive")
	st.add_input("dead")
	st.add_input("win")
	st.xfade_time = 0.08
	bt.add_node("state", st, Vector2(1750, 100))
	bt.add_node("dead_anim", _a("death"), Vector2(1500, 300))
	bt.add_node("win_anim", _a("victory"), Vector2(1500, 450))
	bt.connect_node("state", 0, "pop")
	bt.connect_node("state", 1, "dead_anim")
	bt.connect_node("state", 2, "win_anim")
	bt.connect_node("output", 0, "state")
	tree.tree_root = bt
	tree.active = true
	tree.set("parameters/upper/blend_amount", 1.0)


func _a(nm: String) -> AnimationNodeAnimation:
	var n := AnimationNodeAnimation.new()
	n.animation = nm
	return n


func _filter(node: AnimationNode, prefix: String, bones: Array) -> void:
	node.filter_enabled = true
	for b in bones:
		node.set_filter_path(NodePath(prefix + String(b)), true)


func _setup_light() -> void:
	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(1.0, 0.93, 0.78)
	flashlight.light_energy = 2.4 if is_local else 1.6
	flashlight.spot_attenuation = 0.6
	flashlight.shadow_enabled = is_local
	flashlight.shadow_bias = 0.05
	flashlight.light_specular = 0.0
	flashlight.top_level = true      # 朝向直接取瞄准角，不跟随身体的平滑转身（否则会叠加两次旋转）
	add_child(flashlight)
	beam = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 24
	cone.rings = 1
	cone.cap_bottom = false
	cone.cap_top = false
	beam.mesh = cone
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/light_beam.gdshader")
	beam.material_override = m
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.top_level = true
	add_child(beam)


func _set_expr(eyes: String, mouth: String) -> void:
	for k in exprs:
		var n: Node3D = exprs[k]
		n.visible = k == "expr_eyes_" + eyes or k == "expr_mouth_" + mouth


func _set_weapon(h: SimHamster) -> void:
	weapon_id = h.weapon_id
	if weapon_node:
		weapon_node.queue_free()
		weapon_node = null
	var path := "res://assets/models/weapons/wpn_%s.glb" % weapon_id
	if not ResourceLoader.exists(path):
		path = "res://assets/models/weapons/wpn_pistol.glb"
	weapon_node = ToonMaterials.instance(path, 1.5)
	if socket:
		socket.add_child(weapon_node)
		weapon_node.transform = _sock_fix
	_cls = CLASS_OF.get(weapon_id, "pistol")
	if tree:
		var bt := tree.tree_root as AnimationNodeBlendTree
		(bt.get_node("hold") as AnimationNodeAnimation).animation = "hold_" + _cls
		(bt.get_node("fire_anim") as AnimationNodeAnimation).animation = "fire_" + _cls
		(bt.get_node("reload_anim") as AnimationNodeAnimation).animation = "reload_" + _cls
	evo_sig = ""


func _sync_attachments(h: SimHamster) -> void:
	var sig := "%s_%d_%d_%d_%s" % [h.weapon_id, h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c"), str(h.ab.get("rate", 0)) + str(h.ab.get("torch", 0) + h.ab.get("wide", 0))]
	if sig == evo_sig or weapon_node == null:
		return
	evo_sig = sig
	for c in weapon_node.find_children("evo_*", "", true, false):
		c.queue_free()
	var types: Array = Data.evolutions().get("attachmentType", {}).get(h.weapon_id, [])
	for i in mini(3, types.size()):
		var lv := h.evo_lv(["a", "b", "c"][i])
		if lv < 3:
			continue
		var t := String(types[i])
		var holder := weapon_node.find_child("att_" + t, true, false) as Node3D
		var p := "res://assets/models/attachments/att_%s.glb" % t
		if holder == null or not ResourceLoader.exists(p):
			continue
		var a := ToonMaterials.instance(p, 1.2)
		a.name = "evo_%s_%d" % [t, i]
		var sc := 1.2 if lv >= 9 else (1.0 if lv >= 6 else 0.8)
		a.scale = Vector3.ONE * sc
		holder.add_child(a)
		ToonMaterials.set_param(a, "path_index", i)
		ToonMaterials.set_param(a, "glow", 0.6 if lv >= 9 else 0.0)
	# 强化外观：连点手指 = 枪管金环；强光手电 / 广角镜头 = 枪上大手电
	if int(h.ab.get("rate", 0)) > 0:
		var holder2 := weapon_node.find_child("att_coil", true, false) as Node3D
		if holder2:
			var r := ToonMaterials.instance("res://assets/models/attachments/att_ring.glb", 1.2)
			r.name = "evo_ring"
			r.position = Vector3(0, 0, 0.03)
			holder2.add_child(r)
	if int(h.ab.get("torch", 0)) + int(h.ab.get("wide", 0)) > 0:
		var holder3 := weapon_node.find_child("att_torch", true, false) as Node3D
		if holder3 and holder3.get_child_count() == 0:
			var tb := ToonMaterials.instance("res://assets/models/attachments/att_torch_big.glb", 1.2)
			tb.name = "evo_torchbig"
			tb.scale = Vector3.ONE * (1.0 + 0.1 * (int(h.ab.get("torch", 0)) + int(h.ab.get("wide", 0))))
			holder3.add_child(tb)


static func yaw_for(a: float) -> float:
	## 逻辑朝向（原型平面角）-> 模型绕 Y 旋转（模型正面朝 -Z）
	return -a - PI * 0.5


func sync(h: SimHamster, alpha: float, delta: float, visible_to_local: bool) -> void:
	# 迷雾：看不见的敌人直接隐藏
	var want := visible_to_local and (h.alive or _dead)
	_vis = move_toward(_vis, 1.0 if want else 0.0, delta * 8.0)
	visible = _vis > 0.02
	if not visible:
		return
	if h.weapon_id != weapon_id:
		_set_weapon(h)
	_sync_attachments(h)
	var x := lerpf(h.px, h.x, alpha) * 0.01
	var z := lerpf(h.py, h.y, alpha) * 0.01
	position = Vector3(x, h.z * 0.01, z)
	var face := h.aim
	if h.roll_t > 0.0:
		face = atan2(h.rdy, h.rdx)
	rotation.y = lerp_angle(rotation.y, yaw_for(face), 1.0 - exp(-30.0 * delta))
	var vel := Vector3(h.vx, 0, h.vy) * 0.01
	var local_v := vel.rotated(Vector3.UP, -rotation.y)
	var speed := vel.length()
	var run := clampf(speed / 2.3, 0.0, 1.2)
	if tree:
		var bp := Vector2(local_v.x, -local_v.z) / 2.3
		if bp.length() > 1.0:
			bp = bp.normalized()
		if speed < 0.15:
			bp = Vector2.ZERO
		tree.set("parameters/loco/blend_position", bp)
	# 挤压拉伸弹簧 + 后坐
	_sq_v += ((1.0 - _sq) * 260.0 - _sq_v * 11.0) * delta
	_sq += _sq_v * delta
	_kick_v += ((0.0 - _kick) * 400.0 - _kick_v * 22.0) * delta
	_kick += _kick_v * delta
	var s := float(h.st.get("scale", 1.0)) * (1.35 if h.tal.has("giant") else 1.0)
	var sq := clampf(_sq, 0.6, 1.5)
	model.scale = Vector3(s * sq, s * (2.0 - sq), s * sq)
	model.position = Vector3(0, 0, _kick * 0.01)
	if not h.air.is_empty():
		_air_spin += delta * TAU / float(h.air.get("dur", 1.15))
		model.rotation.x = -_air_spin
	else:
		_air_spin = 0.0
		model.rotation.x = 0.0
	# 程序叠加
	if rig:
		var acc := (vel - _prev_vel) / maxf(delta, 0.001)
		rig.accel = acc.rotated(Vector3.UP, -rotation.y)
		rig.turn_rate = SimUtil.ang_diff(_prev_aim, h.aim) / maxf(delta, 0.001)
		rig.puff = h.puff
		rig.munch = h.munch_t
		rig.ear_scale = 1.0 + 0.14 * float(h.ab.get("ears", 0))
	_prev_vel = vel
	_prev_aim = h.aim
	# 状态：死亡 / 胜利
	if tree:
		var state := "alive"
		if not h.alive:
			state = "dead"
		elif _won:
			state = "win"
		if tree.get("parameters/state/current_state") != state:
			tree.set("parameters/state/transition_request", state)
	_dead = not h.alive
	# 表情
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = randf_range(2.0, 4.5)
		_blink = 0.12
	_blink = maxf(0.0, _blink - delta)
	_happy_t = maxf(0.0, _happy_t - delta)
	_squint_t = maxf(0.0, _squint_t - delta)
	if not h.alive:
		_set_expr("dead", "open")
	elif h.hurt_t > 0.0:
		_set_expr("hurt", "open")
	elif _won or _happy_t > 0.0:
		_set_expr("happy", "open")
	elif h.munch_t > 0.0:
		_set_expr("happy" if fmod(h.munch_t, 0.1) < 0.05 else "open", "open")
	elif _squint_t > 0.0:
		_set_expr("squint", "idle")
	elif _blink > 0.0:
		_set_expr("blink", "idle")
	else:
		_set_expr("open", "idle")
	# 受击闪白、无敌闪烁
	ToonMaterials.set_param(model, "flash", clampf(h.flash / 0.09, 0.0, 1.0) * 0.85)
	var inv := h.iframes > 0.0 and h.roll_t <= 0.0 and h.alive and fmod(Time.get_ticks_msec() / 1000.0, 0.16) < 0.08
	ToonMaterials.set_param(model, "tint", Color(1.6, 1.6, 1.8, 1) if inv else Color(1, 1, 1, 1))
	if weapon_node:
		weapon_node.visible = h.roll_t <= 0.0 and h.alive
	# 手电
	var lr := SimWeapons.light_range(h) * 0.01
	var lc := SimWeapons.light_cos(h)
	var ang := rad_to_deg(acos(clampf(lc, -1.0, 1.0)))
	flashlight.visible = h.alive
	flashlight.spot_range = lr * 1.05
	flashlight.spot_angle = ang
	flashlight.global_transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-9.0), yaw_for(h.aim), 0)), global_position + Vector3(0, 0.55, 0))
	beam.visible = h.alive
	var bl := lr * 0.62
	var br := tan(deg_to_rad(ang)) * bl * 0.55
	var dir := Vector3(cos(h.aim), 0, sin(h.aim))
	beam.global_transform = Transform3D(Basis(Vector3.UP, yaw_for(h.aim)) * Basis(Vector3.RIGHT, deg_to_rad(90.0)) * Basis.from_scale(Vector3(br, bl, br)), global_position + Vector3(0, 0.36, 0) + dir * bl * 0.5)


func on_event(ev: Dictionary) -> void:
	match String(ev.t):
		"fire":
			_kick_v -= 14.0 * float(Data.weapon(weapon_id).get("fx", {}).get("gk", 4.0))
			_squint_t = 0.18
			if tree:
				tree.set("parameters/fire/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"reload":
			if tree:
				var dur := maxf(0.2, float(ev.dur))
				tree.set("parameters/reload_ts/scale", 1.0 / dur)
				tree.set("parameters/reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"dash":
			_sq = 0.75
			_sq_v = 0.0
			if tree:
				tree.set("parameters/roll/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"damage":
			if tree and not bool(ev.get("quiet", false)):
				tree.set("parameters/hurt/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"respawn":
			_dead = false
			if tree:
				tree.set("parameters/state/transition_request", "alive")
				tree.set("parameters/pop/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"levelup", "picked":
			_happy_t = 0.8
			_sq = 1.3
			_sq_v = 0.0
		"land":
			_sq = 0.6
			_sq_v = 0.0
		"gem":
			_sq_v += 2.0


func set_victory(v: bool) -> void:
	_won = v
