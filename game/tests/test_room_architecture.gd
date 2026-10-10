extends "res://tests/test_case.gd"


func test_shell_stays_in_existing_boundary_and_leaves_routes_clear() -> void:
	for mode in ["full", "slice"]:
		var world := make_world(mode, 11)
		var rng_state := world.rng.state
		var solids := world.map.solids.size()
		var root := Node3D.new()
		RoomArchitecture.build(root, world.map)
		eq(world.rng.state, rng_state, "建筑不能改变战斗随机流")
		eq(world.map.solids.size(), solids, "建筑不能改变导航与碰撞")
		for node in root.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			for surface in mi.mesh.get_surface_count():
				var vertices: PackedVector3Array = mi.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					check(vertex.x <= 0.6 or vertex.z <= 0.6, "建筑几何不能侵入既有边界墙之外的游戏通道")
					var outside := vertex.x < 0.0 or vertex.z < 0.0
					check(outside or world.map.point_solid(vertex.x * 100.0, vertex.z * 100.0, 0.5) != null, "可见建筑必须对应原有阻挡区域或地图外部")
		if mode == "full":
			check(root.find_child("glass", true, false) != null, "完整地图应有可见窗户")
		else:
			eq(root.get_child_count(), 0, "切片地图不能出现位于原点的房屋外壳")
		root.free()
		world.dispose()
