extends Node3D
var views: Array = []
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#252a35")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#bfcfe5")
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.8
	add_child(light)
	var cam := Camera3D.new()
	add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 5.0
	cam.position = Vector3(2.3, 2.4, 3.8)
	cam.look_at(Vector3(0.0, 0.35, 0.0))
	cam.current = true
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#444c59")
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)
	var weapons := ["pistol", "ak47", "minigun", "katana"]
	for i in weapons.size():
		var h := SimHamster.new()
		h.weapon_id = weapons[i]
		h.aim = 0.6
		h.x = (i - 1.5) * 90.0
		h.px = h.x
		h.y = 60
		h.py = h.y
		var hv := HamsterView.new()
		add_child(hv)
		hv.setup(h, true)
		hv.sync(h, 1.0, 1.0, true)
		hv.tree.advance(0.2)
		views.append(hv)
		caption(weapons[i], Vector3(h.x * 0.01, 0.02, 1.05))
	var mob := SimMob.new()
	mob.kind = "boss"
	mob.x = 90
	mob.px = mob.x
	mob.y = -70
	mob.py = mob.y
	mob.aim = 0.6
	var boss := B2Views.MobView.new()
	add_child(boss)
	boss.setup(mob)
	boss._intro = -1.0
	boss._pop = 1.0
	boss.sync(mob, 1.0, 0.2, true)
	caption("鼠王 · 王冠随头部", Vector3(0.9, 0.02, -0.05))
	var minion := SimMinion.new()
	minion.x = -90
	minion.px = minion.x
	minion.y = -70
	minion.py = minion.y
	minion.aim = 0.6
	var soldier := UnitViews.MinionView.new()
	add_child(soldier)
	soldier.setup(minion)
	soldier.sync(minion, 1.0, 0.2, true)
	caption("小兵 · 武器归位", Vector3(-0.9, 0.02, -0.05))
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("BUGFIX_REVIEW")
	get_viewport().get_texture().get_image().save_png(out.path_join("attachments.png"))
	cam.size = 2.9
	cam.position = Vector3(0.7, 1.4, 2.3)
	cam.look_at(Vector3(0, 0.15, 0.65))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("weapons_closeup.png"))
	cam.size = 1.8
	cam.position = Vector3(2.1, 1.6, 1.1)
	cam.look_at(Vector3(0.9, 0.55, -0.7))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("boss_closeup.png"))
	print("ATTACHMENT_REVIEW_DONE")
	get_tree().quit()
func caption(text_: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_
	label.font = load("res://assets/fonts/NotoSansSC.ttf")
	label.font_size = 40
	label.pixel_size = 0.0025
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
