class_name StudyFloor
extends RefCounted
## Continuous staggered boards, batched in local chunks. Floor remains a visual
## surface, with no collision and an independent deterministic random stream.

static func build(parent: Node3D, map: SimMap) -> void:
	if not RoomArchitecture.has_study_wall(map):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 43
	var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/textures/palette.json"))
	var cell: Array = palette["floor_wood"]
	var uv := Vector2((float(cell[1]) + 0.5) / 16.0, (float(cell[0]) + 0.5) / 32.0)
	var end_x := minf(12.0, map.max_x * 0.01)
	var end_z := map.max_y * 0.01
	var chunks: Dictionary = {}
	var board_width := 0.25
	for column in floori(end_x / board_width):
		var x := float(column) * board_width
		var z := -rng.randf_range(0.0, 2.8)
		while z < end_z:
			var length_ := rng.randf_range(1.8, 3.1)
			var start := maxf(0.0, z)
			var finish := minf(end_z, z + length_)
			if finish - start > 0.025:
				var key := Vector2i(floori(x / 6.0), floori(start / 6.0))
				if not chunks.has(key):
					var st := SurfaceTool.new()
					st.begin(Mesh.PRIMITIVE_TRIANGLES)
					chunks[key] = st
				var value := rng.randf_range(0.92, 1.08)
				board(chunks[key], Vector3(x + board_width * 0.5, 0.004, (start + finish) * 0.5),
					Vector2(board_width - 0.002, finish - start - 0.002), uv, Color(value, value, value))
			z += length_
	for key: Vector2i in chunks:
		var instance := MeshInstance3D.new()
		instance.name = "StudyPlanks_%d_%d" % [key.x, key.y]
		instance.mesh = (chunks[key] as SurfaceTool).commit()
		instance.material_override = ToonMaterials.material(0, 0.0, "planks")
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)
	# A dark substrate is visible only through the fine physical seams.
	var substrate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(end_x, 0.02, end_z)
	substrate.mesh = box
	substrate.position = Vector3(end_x * 0.5, -0.014, end_z * 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#342b25")
	material.roughness = 1.0
	substrate.material_override = material
	substrate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(substrate)


static func board(tool: SurfaceTool, center: Vector3, size: Vector2, uv: Vector2, tone: Color) -> void:
	var bevel := 0.0015
	var half := size * 0.5
	var outer := [Vector3(-half.x, -bevel, -half.y), Vector3(half.x, -bevel, -half.y),
		Vector3(half.x, -bevel, half.y), Vector3(-half.x, -bevel, half.y)]
	var inner := [Vector3(-half.x + bevel, 0, -half.y + bevel), Vector3(half.x - bevel, 0, -half.y + bevel),
		Vector3(half.x - bevel, 0, half.y - bevel), Vector3(-half.x + bevel, 0, half.y - bevel)]
	for index: int in [0, 1, 2, 0, 2, 3]:
		tool.set_normal(Vector3.UP)
		tool.set_uv(uv)
		tool.set_color(tone)
		tool.add_vertex(center + inner[index])
	for edge in 4:
		var next := (edge + 1) % 4
		var vertices := [inner[edge], outer[edge], outer[next], inner[edge], outer[next], inner[next]]
		for point: Vector3 in vertices:
			var n := Vector3.UP if point.y == 0.0 else Vector3(point.x / half.x, 1.0, point.z / half.y).normalized()
			tool.set_normal(n)
			tool.set_uv(uv)
			tool.set_color(tone)
			tool.add_vertex(center + point)
