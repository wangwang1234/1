extends Node3D
## 开发用：快速检查三渲二材质（godot --path game res://scenes/dev/showcase.tscn -- --shot <路径>）

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.045, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.36, 0.62)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_hdr_threshold = 1.3
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var moon := DirectionalLight3D.new(); moon.light_color = Color(0.55, 0.6, 1.0); moon.light_energy = 0.35
	moon.rotation_degrees = Vector3(-60, -30, 0); moon.shadow_enabled = true; add_child(moon)
	var spot := SpotLight3D.new(); spot.position = Vector3(0.6, 1.4, 1.2); spot.light_color = Color(1, 0.9, 0.7)
	spot.light_energy = 1.6; spot.spot_range = 5.0; spot.spot_angle = 35; spot.shadow_enabled = true; add_child(spot)
	spot.look_at(Vector3(0, 0.2, 0))
	for i in 3:
		for j in 3:
			var f := ToonMaterials.instance("res://assets/models/env/env_floor_wood.glb", 0.0)
			f.position = Vector3(-2 + i * 2, 0, -2 + j * 2); add_child(f)
	var ham := ToonMaterials.instance("res://assets/models/characters/chr_hamster.glb", 2.0)
	add_child(ham)
	ham.rotation_degrees.y = 200
	for n in ham.find_children("expr_*", "", true, false):
		n.visible = n.name in ["expr_eyes_open", "expr_mouth_idle"]
	var ap := ham.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap: ap.play("hold_rifle")
	var sk := ham.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk:
		var ba := BoneAttachment3D.new(); ba.bone_name = "weapon_socket"; sk.add_child(ba)
		var gun := ToonMaterials.instance("res://assets/models/weapons/wpn_ak47.glb", 1.5)
		ba.add_child(gun)
		var rest := sk.get_bone_global_rest(sk.find_bone("weapon_socket"))
		gun.transform = Transform3D(rest.basis.inverse(), Vector3.ZERO)
	var ham2 := ToonMaterials.instance("res://assets/models/characters/chr_hamster.glb", 2.0)
	ham2.position = Vector3(0.7, 0, -0.3); add_child(ham2)
	ToonMaterials.set_param(ham2, "team_index", 1); ToonMaterials.set_param(ham2, "skin_index", 2)
	for n in ham2.find_children("expr_*", "", true, false):
		n.visible = n.name in ["expr_eyes_happy", "expr_mouth_open"]
	var ap2 := ham2.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap2: ap2.play("victory")
	var cam := Camera3D.new(); add_child(cam)
	cam.fov = 34
	cam.position = Vector3(0.35, 1.3, 1.6); cam.look_at(Vector3(0.35, 0.18, 0))
	await get_tree().create_timer(0.6).timeout
	var args := OS.get_cmdline_user_args()
	var out := "user://showcase.png"
	if args.size() >= 2 and args[0] == "--shot": out = args[1]
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
