class_name KillUIStyle
extends RefCounted
## 占位美术仅程序绘制；文字一直使用可商用字体，第三阶段替换图标。

static func name_of(event: Dictionary, id: int) -> String:
	var info: Dictionary = event.get("identities", {}).get(id, {})
	return String(info.get("name", str(id))).replace("\n", " ").replace("\r", " ")


static func color_of(event: Dictionary, id: int, config: KillConfig, connected: bool = true) -> Color:
	var info: Dictionary = event.get("identities", {}).get(id, {})
	if not connected or not bool(info.get("connected", true)):
		return config.disconnected_color
	return UiTheme.BLUE if String(info.get("team", "blue")) == "blue" else UiTheme.RED


static func title(streak: int, config: KillConfig) -> String:
	var ordinary := ["", "击败", "双重击败", "三重击败", "四重击败", "五重击败"]
	if streak >= config.unstoppable_streak:
		return "鼠向披靡"
	return ordinary[clampi(streak, 0, ordinary.size() - 1)]


static func tags(event: Dictionary) -> PackedStringArray:
	var labels := PackedStringArray()
	if bool(event.get("is_first_kill", false)):
		labels.append("首次击败")
	if bool(event.get("is_shutdown", false)):
		labels.append("终结 · 对方 %d 连击败" % int(event.get("victim_streak_before", 0)))
	return labels


static func gold_counts(streak: int, config: KillConfig) -> Dictionary:
	var total := maxi(streak, 0) / config.gold_seed_value
	return {"total": total, "visible": 1 if total > config.gold_row_max else total,
		"multiplier": total if total > config.gold_row_max else 0, "normal": maxi(streak, 0) % config.gold_seed_value}


static func elide(text: String, font: Font, font_size: int, width: float) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return text
	var result := text
	while not result.is_empty() and font.get_string_size(result + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		result = result.left(result.length() - 1)
	return result + "…"


static func text(c: Control, pos: Vector2, value: String, font: Font, font_size: int, color: Color, config: KillConfig, outline: int = -1) -> void:
	var edge := config.title_outline if outline < 0 else outline
	var ink := config.title_ink
	ink.a = color.a
	c.draw_string_outline(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, edge, ink)
	c.draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func icon(c: Control, rect: Rect2, kind: String, config: KillConfig, cracked: bool = true, opacity: float = 1.0) -> void:
	# 归一化几何不是玩法数值；位置、显示尺寸与颜色由配置控制。
	c.draw_set_transform(rect.position, 0.0, rect.size)
	var ink := config.title_ink
	var shell := Color("#535058")
	var cream := config.subtitle_color
	var gold := config.gold_top
	ink.a *= opacity; shell.a *= opacity; cream.a *= opacity; gold.a *= opacity
	var shape := PackedVector2Array([Vector2(0.5, 0.04), Vector2(0.85, 0.4), Vector2(0.88, 0.73), Vector2(0.72, 0.94), Vector2(0.28, 0.94), Vector2(0.12, 0.73), Vector2(0.15, 0.4)])
	if kind == "explosion":
		var burst := PackedVector2Array()
		for i in 16:
			var a := TAU * float(i) / 16.0
			burst.append(Vector2(0.5, 0.5) + Vector2(cos(a), sin(a)) * (0.47 if i % 2 == 0 else 0.2))
		c.draw_colored_polygon(burst, Color(1.0, 0.58, 0.12, opacity))
		c.draw_polyline(burst + PackedVector2Array([burst[0]]), ink, 0.06, true)
	else:
		c.draw_colored_polygon(shape, gold if kind in ["gold", "first", "shutdown"] else shell)
		c.draw_polyline(shape + PackedVector2Array([shape[0]]), ink, 0.06, true)
		if kind == "seed" and cracked:
			c.draw_line(Vector2(0.5, 0.27), Vector2(0.5, 0.81), cream, 0.22, true)
		else:
			c.draw_line(Vector2(0.35, 0.4), Vector2(0.35, 0.75), cream, 0.06, true)
		if kind == "normal":
			c.draw_polyline(PackedVector2Array([Vector2(0.73, 0.15), Vector2(0.4, 0.46), Vector2(0.61, 0.56), Vector2(0.25, 0.87)]), cream, 0.09, true)
		elif kind == "burn":
			c.draw_colored_polygon(PackedVector2Array([Vector2(0.16, 0.56), Vector2(0.28, 0.06), Vector2(0.5, 0.32), Vector2(0.63, 0.0), Vector2(0.85, 0.53)]), Color(1.0, 0.34, 0.12, opacity))
		elif kind == "slash":
			c.draw_line(Vector2(0.03, 0.76), Vector2(0.95, 0.24), cream, 0.12, true)
		elif kind == "reflect":
			c.draw_arc(Vector2(0.5, 0.48), 0.43, -0.5, PI * 1.3, 24, Color(0.48, 0.83, 1.0, opacity), 0.1, true)
			c.draw_colored_polygon(PackedVector2Array([Vector2(0.0, 0.15), Vector2(0.12, 0.54), Vector2(0.34, 0.26)]), Color(0.48, 0.83, 1.0, opacity))
		elif kind == "first":
			c.draw_line(Vector2(0.5, 0.32), Vector2(0.5, 0.04), Color(0.4, 0.86, 0.4, opacity), 0.09, true)
			c.draw_colored_polygon(PackedVector2Array([Vector2(0.5, 0.13), Vector2(0.23, 0.02), Vector2(0.24, 0.23)]), Color(0.4, 0.86, 0.4, opacity))
		elif kind == "shutdown":
			c.draw_line(Vector2(0.08, 0.78), Vector2(0.94, 0.78), ink, 0.16, true)
			c.draw_colored_polygon(PackedVector2Array([Vector2(0.5, 0.85), Vector2(0.2, 0.62), Vector2(0.8, 0.62)]), cream)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
