class_name Snapshot
extends Node
## 3D 快照：在一个离屏 SubViewport 里依次摆放模型、渲染一帧、存成贴图（图鉴、大厅用）。
## 同一个 key 只渲染一次，结果缓存在静态字典里。用法：var tex := await Snapshot.get_tex(self, key, builder)
## builder: Callable(world: Node3D) -> Dictionary {"aabb_center": Vector3, "size": float}，在 world 下摆好模型。

static var _cache := {}
static var _busy := false

const SIZE := 256


static func cached(key: String) -> Texture2D:
	return _cache.get(key, null)


static func get_tex(host: Node, key: String, builder: Callable) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	while _busy:
		await host.get_tree().process_frame
	if _cache.has(key):
		return _cache[key]
	_busy = true
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.72)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var key_l := DirectionalLight3D.new()
	key_l.light_energy = 1.3
	key_l.rotation_degrees = Vector3(-40, 35, 0)
	key_l.light_specular = 0.0
	world.add_child(key_l)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.5
	rim.light_color = Color(0.7, 0.8, 1.0)
	rim.rotation_degrees = Vector3(-20, -150, 0)
	rim.light_specular = 0.0
	world.add_child(rim)
	var holder := Node3D.new()
	world.add_child(holder)
	var info: Dictionary = builder.call(holder)
	var c: Vector3 = info.get("center", Vector3(0, 0.15, 0))
	var sz := float(info.get("size", 0.5))
	var cam := Camera3D.new()
	cam.fov = 30.0
	world.add_child(cam)
	var dir := Vector3(0.55, 0.42, 1.0).normalized()
	cam.position = c + dir * (sz * 0.5 / tan(deg_to_rad(15.0))) * 1.15
	cam.look_at(c, Vector3.UP)
	cam.current = true
	# 等动画树 / 材质就绪，再渲染一帧
	await host.get_tree().process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await host.get_tree().process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var tex := ImageTexture.create_from_image(img) if img != null else null
	vp.queue_free()
	_cache[key] = tex
	_busy = false
	return tex


static func model(path: String, size: float = -1.0, yaw: float = 0.0, outline: float = 1.6, zoom: float = 1.0) -> Callable:
	## 常用 builder：放一个 glb，自动按包围盒取景
	return func(holder: Node3D) -> Dictionary:
		var n := ToonMaterials.instance(path, outline)
		n.rotation.y = yaw
		holder.add_child(n)
		var ab := _aabb(n)
		var s := size if size > 0.0 else maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
		return {"center": ab.get_center(), "size": maxf(0.05, s * zoom)}


static func _aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var ab := mi.global_transform * mi.mesh.get_aabb()
		if first:
			out = ab
			first = false
		else:
			out = out.merge(ab)
	return out
