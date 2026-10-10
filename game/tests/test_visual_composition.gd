extends "res://tests/test_case.gd"
## 桌面组合必须落在原有掩体内；静态地图采用空间分块，检查两种地图与多个种子。

func test_surface_dressing_fits_existing_cover_and_keeps_rng() -> void:
	for mode in ["full", "slice"]:
		for seed_ in [5, 11, 37]:
			var world := make_world(mode, seed_)
			var state := world.rng.state
			var original_solids := world.map.solids.size()
			var view := MapView.new()
			view.build(world.map, seed_)
			eq(world.rng.state, state, "生活场景组合不能改变战斗随机流")
			eq(world.map.solids.size(), original_solids, "台面精修不能增加战斗障碍")
			check(view.surface_placements.size() > 0, "两种地图都应有台面组合")
			for placement in view.surface_placements:
				var half := Vector2(48.0, 27.5) * float(placement.scale)
				if not placement.long_x:
					half = Vector2(half.y, half.x)
				var bounds: Rect2 = placement.bounds
				check(bounds.encloses(Rect2(placement.position - half, half * 2.0)), "台面组合不能悬空或伸到通道")
			view.free()
			world.dispose()


func test_batches_have_local_bounds_for_visibility_culling() -> void:
	var world := make_world("full", 11)
	var view := MapView.new()
	view.build(world.map, 11)
	var maximum := float(VisualStyle.section("composition").batchSizeMeters) + 5.0
	var found := false
	for child in view.get_children():
		if child is MultiMeshInstance3D:
			found = true
			var bounds := (child as MultiMeshInstance3D).get_aabb()
			check(bounds.size.x < maximum and bounds.size.z < maximum, "MultiMesh 不能用整张地图的包围盒")
	check(found, "地图应生成局部 MultiMesh")
	view.free()
	world.dispose()
