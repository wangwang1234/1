class_name KillFeedUI
extends RefCounted
## 每客户端一个信息条模型，各分屏视口绘制相同内容；没有客户端奖励计算。

var config: KillConfig
var rows: Array[Dictionary] = []
var canvases: Array[Control] = []


func _init(settings: KillConfig) -> void:
	config = settings
	UiTheme.fonts()


func attach(parent: Node) -> FeedCanvas:
	var canvas := FeedCanvas.new()
	canvas.model = self
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvases.append(canvas)
	return canvas


func receive(event: Dictionary) -> void:
	rows.append({"event": event.duplicate(true), "age": 0.0})
	while rows.size() > config.feed_max_rows:
		rows.pop_front()
	_redraw()


func tick(delta: float) -> void:
	for row in rows:
		row.age += delta
	rows = rows.filter(func(row: Dictionary) -> bool: return float(row.age) < config.feed_stay + config.feed_fade)
	_redraw()


func clear() -> void:
	rows.clear()
	_redraw()


func _redraw() -> void:
	for canvas in canvases:
		if is_instance_valid(canvas):
			canvas.queue_redraw()


class FeedCanvas:
	extends Control
	var model: KillFeedUI
	var top_exclusion: float = 0.0

	func _draw() -> void:
		if model == null:
			return
		var cfg := model.config
		var scale := size.y / cfg.reference_height
		var width := minf(cfg.feed_width * scale, size.x - cfg.feed_margin * scale * 2.0)
		var y := maxf(cfg.feed_top * scale, top_exclusion)
		var x := size.x - cfg.feed_margin * scale - width
		for row in model.rows:
			var opacity := clampf(1.0 - maxf(0.0, float(row.age) - cfg.feed_stay) / cfg.feed_fade, 0.0, 1.0)
			_draw_row(row.event, Rect2(x, y, width, cfg.feed_row_height * scale), scale, opacity)
			y += cfg.feed_row_height * scale

	func _draw_row(event: Dictionary, rect: Rect2, scale: float, opacity: float) -> void:
		var cfg := model.config
		var icon_size := cfg.method_icon_size * scale
		var gap := cfg.seed_gap * scale
		var font_size := maxi(1, roundi(cfg.feed_font_size * scale))
		var small_size := maxi(1, roundi(cfg.feed_assist_size * scale))
		var killer := int(event.get("killer_id", -1))
		var victim := int(event.get("victim_id", -1))
		var spans: Array[Dictionary] = []
		var icons: Array[String] = []
		if bool(event.get("is_first_kill", false)):
			icons.append("first")
		if bool(event.get("is_shutdown", false)):
			icons.append("shutdown")
		icons.append(String(event.get("method", "normal")))
		var assists: Array = event.get("assists", [])
		var assist_width := 0.0 if assists.is_empty() else minf(cfg.feed_assist_width * scale, rect.size.x * 0.28)
		var name_width := minf(cfg.feed_name_width * scale, maxf(0.0, (rect.size.x - icons.size() * (icon_size + gap) - assist_width - gap * 4.0) / 2.0))
		if killer >= 0:
			_add_text(spans, KillUIStyle.name_of(event, killer), font_size, name_width, KillUIStyle.color_of(event, killer, cfg, bool(event.get("killer_connected", false))))
		if not assists.is_empty():
			var remaining := assist_width
			for i in assists.size():
				var assist: Dictionary = assists[i]
				var id := int(assist.player_id)
				var name := ("+ " if i == 0 else "、") + KillUIStyle.name_of(event, id)
				var max_width := remaining / float(assists.size() - i)
				var actual := _add_text(spans, name, small_size, max_width, KillUIStyle.color_of(event, id, cfg, bool(assist.get("connected", true))))
				remaining -= actual
		for icon in icons:
			spans.append({"icon": icon, "width": icon_size})
		_add_text(spans, KillUIStyle.name_of(event, victim), font_size, name_width, KillUIStyle.color_of(event, victim, cfg))
		if killer < 0:
			_add_text(spans, "被击败", font_size, name_width, cfg.white_title)
		var total := gap * maxf(0.0, spans.size() - 1)
		for span in spans:
			total += float(span.width)
		var x := rect.end.x - total
		draw_rect(Rect2(x - gap, rect.position.y, total + gap, rect.size.y), Color(0.08, 0.05, 0.04, opacity * 0.55))
		for span in spans:
			if span.has("icon"):
				KillUIStyle.icon(self, Rect2(x, rect.position.y + (rect.size.y - icon_size) * 0.5, icon_size, icon_size), span.icon, cfg, true, opacity)
			else:
				var color: Color = span.color
				color.a *= opacity
				var baseline := rect.position.y + (rect.size.y + UiTheme.body_font.get_ascent(span.font_size) - UiTheme.body_font.get_descent(span.font_size)) * 0.5
				KillUIStyle.text(self, Vector2(x, baseline), span.text, UiTheme.body_font, span.font_size, color, cfg, roundi(cfg.subtitle_outline * scale))
			x += float(span.width) + gap

	func _add_text(spans: Array[Dictionary], value: String, font_size: int, width: float, color: Color) -> float:
		var text := KillUIStyle.elide(value, UiTheme.body_font, font_size, width)
		var actual := UiTheme.body_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		spans.append({"text": text, "width": actual, "font_size": font_size, "color": color})
		return actual
