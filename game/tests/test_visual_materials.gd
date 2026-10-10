extends "res://tests/test_case.gd"
## 检查实际导入后的材质、第二套 UV、动画，以及 MultiMesh 分件保留。

func test_environment_and_character_use_distinct_lighting() -> void:
	var wood := ToonMaterials.material(0, 0.0, "wood")
	var fur := ToonMaterials.material(1, 0.0, "fur")
	eq(wood.shader, ToonMaterials.SURFACE, "环境采用连续漫反射和标准 GGX")
	eq(fur.shader, ToonMaterials.TOON, "毛皮保留柔化阶调")
	check(float(wood.get_shader_parameter("material_roughness")) > 0.6, "木地板反光不能变成镜面")
	check(float(fur.get_shader_parameter("toon_weight")) < 0.5, "角色仍有连续体积明暗")


func test_room_reflection_excludes_team_visibility_layers() -> void:
	var world := make_world("full", 11)
	var rng_state := world.rng.state
	var solids := world.map.solids.size()
	var parent := Node3D.new()
	RoomLighting.build_study(parent, world.map)
	var probe := parent.find_child("StaticRoomReflection", true, false) as ReflectionProbe
	check(probe != null, "书房有静态环境反射")
	if probe != null:
		eq(probe.cull_mask, 1, "反射不能采集隐藏敌人的队伍层")
		eq(probe.update_mode, ReflectionProbe.UPDATE_ONCE, "反射只采集静态场景一次")
	eq(world.rng.state, rng_state, "灯光不能改变战斗随机流")
	eq(world.map.solids.size(), solids, "灯光不能改变碰撞")
	parent.free()
	world.dispose()

func test_character_keeps_skin_masks_team_materials_and_animation() -> void:
	var model := ToonMaterials.instance(HamsterView.MODEL, 2.0)
	var skin_found := false
	var knit_found := false
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var material := mi.get_surface_override_material(s) as ShaderMaterial
			if material.get_shader_parameter("skin_blend") == true:
				skin_found = true
				var uv2: PackedVector2Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_TEX_UV2]
				check(uv2.size() > 0, "毛色遮罩必须保留到导入后的网格")
				var cream_min := 1.0
				var cream_max := 0.0
				var stripe_min := 1.0
				var stripe_max := 0.0
				for uv in uv2:
					cream_min = minf(cream_min, uv.x)
					cream_max = maxf(cream_max, uv.x)
					stripe_min = minf(stripe_min, uv.y)
					stripe_max = maxf(stripe_max, uv.y)
				check(cream_min < 0.05 and cream_max > 0.9, "脸腹部奶油色遮罩范围")
				check(stripe_min < 0.05 and stripe_max > 0.7, "背部条纹遮罩范围")
			if material.get_shader_parameter("surface_mode") == 4:
				knit_found = true
				eq(material.get_shader_parameter("kind"), 2, "毛线帽仍使用队伍色")
	check(skin_found, "导入模型应有渐变毛色表面")
	check(knit_found, "导入模型应有毛线材质")
	var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	check(anim != null, "角色动画播放器不能丢失")
	if anim != null:
		for name_ in HamsterView.LOOPS:
			check(anim.has_animation(name_), "保留动画 " + name_)
	model.free()


func test_every_room_reflection_respects_map_bounds_and_team_visibility() -> void:
	for mode in ["full", "slice"]:
		var world := make_world(mode, 11)
		var root := Node3D.new()
		RoomLighting.build_study(root, world.map)
		var probes := root.find_children("*", "ReflectionProbe", true, false)
		if mode == "full":
			eq(probes.size(), 3, "完整地图的三处房间有各自反射")
		for node in probes:
			var probe := node as ReflectionProbe
			check(RoomLighting.inside_map(probe.position, world.map), "切片地图不能生成地图之外的反射采集")
			eq(probe.cull_mask, 1, "每处房间反射排除敌方可见层")
			eq(probe.update_mode, ReflectionProbe.UPDATE_ONCE, "反射不逐帧重新采集")
		root.free()
		world.dispose()


func test_merged_furniture_keeps_wood_and_metal_surfaces() -> void:
	var path := "res://assets/models/env/env_counter.glb"
	var instance := ToonMaterials.instance(path)
	var modes := {}
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s) as ShaderMaterial
			modes["%d_%d" % [int(mat.get_shader_parameter("kind")), int(mat.get_shader_parameter("surface_mode"))]] = true
	var merged := ToonMaterials.merged_mesh(path)
	var merged_modes := {}
	for s in merged.get_surface_count():
		var mat := merged.surface_get_material(s) as ShaderMaterial
		merged_modes["%d_%d" % [int(mat.get_shader_parameter("kind")), int(mat.get_shader_parameter("surface_mode"))]] = true
	eq(modes, merged_modes, "MultiMesh 合并后保留分件材质")
	check(merged_modes.has("0_1"), "木柜应有哑光木材表面")
	check(merged_modes.has("3_0"), "把手应保留金属表面")
	instance.free()


func test_graphics_quality_tiers() -> void:
	## 画质档位：低档关掉屏幕空间效果和多级阴影，高档全开；数据里三档齐全
	var Q: Dictionary = VisualStyle.section("quality")
	for k in ["low", "medium", "high"]:
		check(Q.has(k), "画质档 %s 存在" % k)
	var old := VisualStyle.quality
	VisualStyle.quality = "low"
	var e := VisualStyle.environment()
	check(not e.ssao_enabled and not e.ssil_enabled, "低档关掉环境光遮蔽和间接光")
	var m := VisualStyle.moon()
	eq(m.directional_shadow_mode, DirectionalLight3D.SHADOW_ORTHOGONAL, "低档月光阴影不分级")
	m.free()
	VisualStyle.quality = "high"
	e = VisualStyle.environment()
	check(e.ssao_enabled and e.ssil_enabled, "高档全开")
	m = VisualStyle.moon()
	eq(m.directional_shadow_mode, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "高档 4 级阴影")
	m.free()
	VisualStyle.quality = "nope"
	check(VisualStyle.environment().ssao_enabled, "未知档位按高档处理")
	VisualStyle.quality = old
