class_name KillArtConfig
extends Resource
## Claude提供的静态素材；原PNG保持不变，透明边界只用于绘制时保持比例。

@export var textures: Dictionary = {}
@export var regions: Dictionary = {}


func draw(canvas: Control, rect: Rect2, key: String, opacity: float = 1.0, crop: bool = true) -> bool:
	var texture: Texture2D = textures.get(key)
	if texture == null:
		return false
	var region: Rect2 = regions.get(key, Rect2(Vector2.ZERO, texture.get_size())) if crop else Rect2(Vector2.ZERO, texture.get_size())
	var factor := minf(rect.size.x / region.size.x, rect.size.y / region.size.y)
	var target_size := region.size * factor
	var target := Rect2(rect.position + (rect.size - target_size) * 0.5, target_size)
	canvas.draw_texture_rect_region(texture, target, region, Color(1, 1, 1, opacity))
	return true


func draw_slashed_seed(canvas: Control, rect: Rect2, opacity: float) -> void:
	# 只改变Godot取样区域和摆放，不修改用户PNG；上下两片形成可辨认的分离剪影。
	var texture: Texture2D = textures.reward_seed
	var region: Rect2 = regions.reward_seed
	var factor := minf(rect.size.x / region.size.x, rect.size.y / region.size.y) * 0.8
	var whole_size := region.size * factor
	var origin := rect.get_center() - whole_size * 0.5
	var gap := rect.size * 0.08
	var half_size := Vector2(whole_size.x, whole_size.y * 0.5)
	canvas.draw_texture_rect_region(texture, Rect2(origin - gap * 0.5, half_size), Rect2(region.position, Vector2(region.size.x, region.size.y * 0.5)), Color(1, 1, 1, opacity))
	canvas.draw_texture_rect_region(texture, Rect2(origin + Vector2(0, half_size.y) + gap * 0.5, half_size), Rect2(region.position + Vector2(0, region.size.y * 0.5), Vector2(region.size.x, region.size.y * 0.5)), Color(1, 1, 1, opacity))
