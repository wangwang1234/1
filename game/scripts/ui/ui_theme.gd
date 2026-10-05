class_name UiTheme
extends RefCounted
## UI 主题（ART_BIBLE 第 9 节）：圆角面板、奶油色文字、深紫半透明底、强调金；游戏内文字一律带描边。
## 字体：思源黑体（Noto Sans SC，OFL）做正文，站酷快乐体（ZCOOL KuaiLe，OFL）做标题和数字。

const CREAM := Color("#fff3e0")
const INK := Color("#1a1226")
const PANEL := Color(0.102, 0.071, 0.149, 0.88)
const GOLD := Color("#ffd166")
const ACCENT := Color("#f0862a")
const BLUE := Color("#4fa3ff")
const RED := Color("#ff5b5b")
const GREEN := Color("#7ee08a")
const SUB := Color(1.0, 0.953, 0.878, 0.62)
const CARD_COLORS := {"进化": Color("#ff9a3c"), "强化": Color("#5fb0ff"), "道具": Color("#c77dff"), "天赋": Color("#ff6fd0"), "宠物": Color("#5fd38a"), "换武器": Color("#d9d4e2")}
const PATH_COLORS := [Color("#ff9a3c"), Color("#5fb0ff"), Color("#c77dff")]

static var body_font: Font
static var display_font: Font
static var _theme: Theme


static func fonts() -> void:
	if body_font == null:
		var f: FontFile = load("res://assets/fonts/NotoSansSC.ttf")
		var v := FontVariation.new()
		v.base_font = f
		v.variation_opentype = {"wght": 600}
		body_font = v
		display_font = load("res://assets/fonts/ZCOOLKuaiLe.ttf")


static func panel_box(bg: Color = PANEL, radius: int = 18, border: Color = Color(1, 1, 1, 0.08), bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.anti_aliasing = true
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	fonts()
	var t := Theme.new()
	t.default_font = body_font
	t.default_font_size = 22
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 6)
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "Panel", panel_box())
	# 按钮：强调色药丸
	var normal := panel_box(ACCENT, 999, Color(0, 0, 0, 0.0), 0)
	normal.shadow_color = Color(0, 0, 0, 0.3)
	normal.shadow_offset = Vector2(0, 5)
	normal.shadow_size = 0
	normal.content_margin_left = 34
	normal.content_margin_right = 34
	normal.content_margin_top = 12
	normal.content_margin_bottom = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = ACCENT.lightened(0.15)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = ACCENT.darkened(0.12)
	pressed.shadow_offset = Vector2(0, 1)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(3)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.4, 0.36, 0.45, 0.6)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color(1, 1, 1, 0.9))
	t.set_color("font_outline_color", "Button", Color(0.35, 0.16, 0.05))
	t.set_constant("outline_size", "Button", 4)
	t.set_font("font", "Button", display_font)
	t.set_font_size("font_size", "Button", 30)
	# 次要按钮（type variation：GhostButton）
	t.add_type("GhostButton")
	t.set_type_variation("GhostButton", "Button")
	var g := panel_box(Color(1, 1, 1, 0.04), 999, Color(1, 0.953, 0.878, 0.28), 2)
	g.shadow_size = 0
	g.content_margin_left = 26
	g.content_margin_right = 26
	g.content_margin_top = 9
	g.content_margin_bottom = 10
	var gh := g.duplicate() as StyleBoxFlat
	gh.bg_color = Color(1, 1, 1, 0.12)
	var gp := g.duplicate() as StyleBoxFlat
	gp.bg_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.32)
	gp.border_color = GOLD
	gp.set_border_width_all(3)
	var gf := g.duplicate() as StyleBoxFlat
	gf.draw_center = false
	gf.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.8)
	t.set_stylebox("normal", "GhostButton", g)
	t.set_stylebox("hover", "GhostButton", gh)
	t.set_stylebox("pressed", "GhostButton", gp)
	t.set_stylebox("hover_pressed", "GhostButton", gp)
	t.set_stylebox("focus", "GhostButton", gf)
	t.set_stylebox("disabled", "GhostButton", g)
	t.set_color("font_pressed_color", "GhostButton", Color.WHITE)
	t.set_color("font_hover_pressed_color", "GhostButton", Color.WHITE)
	t.set_color("font_disabled_color", "GhostButton", Color(1, 0.953, 0.878, 0.35))
	t.set_font("font", "GhostButton", body_font)
	t.set_font_size("font_size", "GhostButton", 22)
	t.set_color("font_color", "GhostButton", CREAM)
	t.set_color("font_hover_color", "GhostButton", Color.WHITE)
	t.set_constant("outline_size", "GhostButton", 0)
	_theme = t
	return t


static func label(text: String, size: int = 22, color: Color = CREAM, display: bool = false, outline: int = 6) -> Label:
	fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", display_font if display else body_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	return l


static func draw_text_outline(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, outline: int = 6, width: float = -1.0) -> void:
	ci.draw_string_outline(font, pos, text, align, width, size, outline, Color(INK.r, INK.g, INK.b, color.a))
	ci.draw_string(font, pos, text, align, width, size, color)


static func ability_group_color(id: String) -> Color:
	if id in ["strong", "armor", "regen", "vamp"]:
		return Color("#7ee08a")
	if id in ["speed", "dash", "magnet"]:
		return Color("#ffd166")
	if id in ["torch", "wide", "ears", "nvg", "recon"]:
		return Color("#9fe8ff")
	if id in ["rage", "crit", "rate", "frost", "chain"]:
		return Color("#ff8a7a")
	return Color("#c9a2ff")
