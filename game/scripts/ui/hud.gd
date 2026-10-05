class_name Hud
extends CanvasLayer
## 局内界面（GDD 第 16 节 / ART_BIBLE 第 9 节）。全部绘制在一个全屏 Control 上（自绘），外加 3D 头像子视口。
## 布局以 1920×1080 为基准，按屏幕高度缩放。

const NCOL := {"gun": Color("#ffb04a"), "boom": Color("#ff5b4a"), "monster": Color("#ffd166"), "step": Color("#ffffff"), "pad": Color("#7fe3ff")}
const NICON := {"gun": "枪", "boom": "爆", "monster": "怪", "step": "脚", "pad": "弹"}

var mv: MatchView
var root: Control
var canvas: HudCanvas
var portrait_vp: SubViewport
var portrait_ham: Node3D
var _portrait_anim: AnimationPlayer
var _portrait_tex: ViewportTexture
var icons := {}
var toasts: Array = []      # 当前 toast
var feeds: Array = []
var hit_t := 0.0
var hit_kill := false
var hurt := 0.0
var white := 0.0
var cards_t := 0.0
var cards_out := 0.0
var card_rects: Array = []
var card_hover := -1
var paused := false
var _reload_hint := 0.0


func setup(m: MatchView) -> void:
	mv = m
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.theme()
	add_child(root)
	canvas = HudCanvas.new()
	canvas.hud = self
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(canvas)
	for w: String in ["pistol", "ak47", "shotgun"]:
		var p := "res://assets/icons/wpn_%s.png" % w
		if ResourceLoader.exists(p):
			icons[w] = load(p)
	_setup_portrait()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if not mv.autoplay else Input.MOUSE_MODE_VISIBLE


func _setup_portrait() -> void:
	portrait_vp = SubViewport.new()
	portrait_vp.size = Vector2i(256, 256)
	portrait_vp.transparent_bg = true
	portrait_vp.own_world_3d = true
	portrait_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(portrait_vp)
	var w3 := Node3D.new()
	portrait_vp.add_child(w3)
	var cam := Camera3D.new()
	cam.fov = 26
	w3.add_child(cam)
	cam.position = Vector3(0, 0.27, 0.95)
	cam.look_at(Vector3(0, 0.235, 0))
	var key := DirectionalLight3D.new()
	key.light_energy = 1.4
	key.rotation_degrees = Vector3(-35, 25, 0)
	w3.add_child(key)
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.45, 0.7)
	e.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = e
	w3.add_child(we)
	var h := mv.local if mv.local != null else mv.world.hams[0]
	portrait_ham = ToonMaterials.instance(HamsterView.MODEL, 2.0)
	w3.add_child(portrait_ham)
	portrait_ham.rotation.y = deg_to_rad(18)
	ToonMaterials.set_param(portrait_ham, "team_index", 0 if h.team == "blue" else 1)
	ToonMaterials.set_param(portrait_ham, "skin_index", maxi(0, Data.skin_ids().find(h.skin)))
	_portrait_anim = portrait_ham.find_child("AnimationPlayer", true, false)
	if _portrait_anim:
		_portrait_anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		_portrait_anim.play("idle")
	_portrait_tex = portrait_vp.get_texture()


func _portrait_expr(eyes: String, mouth: String) -> void:
	for n in portrait_ham.find_children("expr_*", "", true, false):
		n.visible = n.name == "expr_eyes_" + eyes or n.name == "expr_mouth_" + mouth


# ---------------------------------------------------------------------------
# 事件接口（MatchView 调用）
# ---------------------------------------------------------------------------

func toast(id: int, text: String, color: Color, dur: float) -> void:
	if id >= 0 and (mv.local == null or id != mv.local.id):
		return
	for t in toasts:
		if t.text == text:
			return
	# 新提示来了：正在显示的那条（已显示 0.4 秒以上）提前淡出，避免反馈排队变慢
	if not toasts.is_empty() and float(toasts[0].t) > 0.4:
		toasts[0].dur = minf(float(toasts[0].dur), float(toasts[0].t) + 0.3)
	toasts.append({"text": text, "color": color, "dur": dur, "t": 0.0})
	if toasts.size() > 3:
		toasts.pop_front()


func feed(text: String, color: Color) -> void:
	feeds.append({"text": text, "color": color, "t": 0.0})
	if feeds.size() > 5:
		feeds.pop_front()


func hitmark(kill: bool) -> void:
	hit_t = 0.14
	hit_kill = kill


func hurt_pulse() -> void:
	hurt = 1.0


func flash_white(a: float) -> void:
	white = maxf(white, a)


func toast_reload() -> void:
	_reload_hint = 0.0


func show_cards() -> void:
	cards_t = 0.0
	cards_out = 0.0


func cards_picked() -> void:
	cards_out = 0.25
	cards_t = 0.0


func card_at(p: Vector2) -> int:
	for i in card_rects.size():
		if (card_rects[i] as Rect2).has_point(p):
			return i
	return -1


func set_paused(p: bool) -> void:
	paused = p
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if p or mv.autoplay else Input.MOUSE_MODE_HIDDEN


func refresh(delta: float) -> void:
	hit_t = maxf(0.0, hit_t - delta)
	hurt = maxf(0.0, hurt - delta * 2.5)
	white = maxf(0.0, white - delta * 1.2)
	cards_t += delta
	cards_out = maxf(0.0, cards_out - delta)
	for t in toasts:
		t.t = float(t.t) + delta
	while not toasts.is_empty() and float(toasts[0].t) > float(toasts[0].dur):
		toasts.pop_front()
	for f in feeds:
		f.t = float(f.t) + delta
	while not feeds.is_empty() and float(feeds[0].t) > 6.0:
		feeds.pop_front()
	var h := mv.local
	if h != null and portrait_ham:
		if not h.alive:
			_portrait_expr("dead", "open")
		elif h.hurt_t > 0.0:
			_portrait_expr("hurt", "open")
		elif h.munch_t > 0.0:
			_portrait_expr("happy", "open")
		else:
			_portrait_expr("blink" if fmod(Time.get_ticks_msec() / 1000.0, 3.3) < 0.12 else "open", "idle")
		var sk := portrait_ham.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk:
			for nm: String in ["cheek_L", "cheek_R"]:
				var bi := sk.find_bone(nm)
				if bi >= 0:
					sk.set_bone_pose_scale(bi, Vector3.ONE * (1.0 + 0.7 * h.puff))
	canvas.queue_redraw()


class HudCanvas:
	extends Control
	var hud: Hud

	func _draw() -> void:
		hud.draw_all(self)


# ---------------------------------------------------------------------------
# 绘制
# ---------------------------------------------------------------------------

func _s() -> float:
	return root.size.y / 1080.0


func draw_all(c: Control) -> void:
	if mv.world == null:
		return
	var s := _s()
	var w := mv.world
	var h := mv.local
	_draw_world_ui(c, s)
	_draw_hearing(c, s)
	if hurt > 0.01 or (h != null and h.alive and h.hp / h.max_hp < 0.3):
		var low := 0.0
		if h != null and h.alive and h.hp / h.max_hp < 0.3:
			low = 0.2 + 0.12 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
		_vignette(c, Color(1, 0.16, 0.24), maxf(hurt * 0.45, low))
	if h != null:
		_draw_panel(c, s, h)
		_draw_crosshair(c, s, h)
	_draw_score(c, s)
	_draw_minimap(c, s)
	_draw_feed(c, s)
	_draw_toasts(c, s)
	if h != null:
		_draw_cards(c, s, h)
		if not h.alive:
			var txt := "%d 秒后复活" % ceili(h.respawn_t)
			UiTheme.draw_text_outline(c, UiTheme.display_font, Vector2(0, root.size.y * 0.42), "被打倒了…", int(44 * s), Color("#ff8a7a"), HORIZONTAL_ALIGNMENT_CENTER, 10, root.size.x)
			UiTheme.draw_text_outline(c, UiTheme.body_font, Vector2(0, root.size.y * 0.42 + 50 * s), txt, int(26 * s), UiTheme.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 8, root.size.x)
	if white > 0.0:
		c.draw_rect(Rect2(Vector2.ZERO, root.size), Color(1, 1, 1, clampf(white, 0.0, 1.0)))


func _vignette(c: Control, col: Color, a: float) -> void:
	var sz := root.size
	var n := 24
	for i in n:
		var k := float(i) / n
		var inset := k * minf(sz.x, sz.y) * 0.22
		var cc := col
		cc.a = a * (1.0 - k) * 0.12
		c.draw_rect(Rect2(Vector2(inset, inset), sz - Vector2(inset, inset) * 2.0), cc, false, minf(sz.x, sz.y) * 0.22 / n + 1.0)


func _panel(c: Control, r: Rect2, radius: float = 18.0, a: float = 0.86) -> void:
	var sb := UiTheme.panel_box(Color(0.102, 0.071, 0.149, a), int(radius))
	sb.content_margin_left = 0
	var k := clampf(a / 0.86, 0.0, 1.0)       # 淡出时边框和投影一起淡
	sb.border_color.a *= k
	sb.shadow_color.a *= k
	c.draw_style_box(sb, r)


func _bar(c: Control, r: Rect2, k: float, col: Color, bg: Color = Color(1, 1, 1, 0.12)) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(r.size.y * 0.5))
	sb.anti_aliasing = true
	c.draw_style_box(sb, r)
	if k > 0.0:
		var fr := r
		fr.size.x = maxf(r.size.y, r.size.x * clampf(k, 0.0, 1.0))
		var sb2 := sb.duplicate() as StyleBoxFlat
		sb2.bg_color = col
		c.draw_style_box(sb2, fr)


func _txt(c: Control, p: Vector2, t: String, size: float, col: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, display: bool = false, width: float = -1.0, outline: int = 6) -> void:
	UiTheme.draw_text_outline(c, UiTheme.display_font if display else UiTheme.body_font, p, t, int(size), col, align, outline, width)


func _draw_panel(c: Control, s: float, h: SimHamster) -> void:
	var x := 16.0 * s
	var y := 16.0 * s
	var w := 470.0 * s
	var ph := 190.0 * s
	_panel(c, Rect2(x, y, w, ph), 22 * s)
	var pc := Vector2(x + 92 * s, y + ph * 0.5)
	var R := 74.0 * s
	var tc := UiTheme.BLUE if h.team == "blue" else UiTheme.RED
	c.draw_circle(pc, R, Color(tc.r, tc.g, tc.b, 0.16))
	c.draw_arc(pc, R, 0, TAU, 64, Color(1, 1, 1, 0.14), 7 * s, true)
	var xf := 1.0 if h.lvl >= 30 else clampf(h.xp / float(h.xp_next), 0.0, 1.0)
	c.draw_arc(pc, R, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.001, xf), 64, UiTheme.GOLD, 7 * s, true)
	if _portrait_tex:
		var ps := R * 1.9
		c.draw_texture_rect(_portrait_tex, Rect2(pc - Vector2(ps, ps) * 0.5 - Vector2(0, 6 * s), Vector2(ps, ps)), false, Color(1, 1, 1, 1.0 if h.alive else 0.45))
	# 武器小图
	if icons.has(h.weapon_id):
		var ic: Texture2D = icons[h.weapon_id]
		c.draw_texture_rect(ic, Rect2(pc + Vector2(-8, 26) * s, Vector2(84, 84) * s), false)
	# 道具冷却
	var gpos := pc + Vector2(58, 52) * s
	var gr := 21.0 * s
	c.draw_circle(gpos, gr, Color(0.086, 0.063, 0.15, 0.95))
	var gcd := float(h.gadget.cd)
	var gmax := float(Data.gadgets().get(String(h.gadget.id), {"cd": 7}).cd) * float(h.st.get("gcd", 1.0))
	if gcd > 0.0:
		var k := clampf(gcd / maxf(0.1, gmax), 0.0, 1.0)
		var pts := PackedVector2Array([gpos])
		for i in 33:
			var a := -PI * 0.5 + TAU * k * float(i) / 32.0
			pts.append(gpos + Vector2(cos(a), sin(a)) * gr)
		c.draw_colored_polygon(pts, Color(0.04, 0.02, 0.08, 0.7))
	c.draw_arc(gpos, gr, 0, TAU, 40, Color(1, 1, 1, 0.3) if gcd > 0.0 else Color("#c77dff"), 3 * s, true)
	_txt(c, gpos + Vector2(-9, 9) * s, "雷", 20 * s, UiTheme.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true)
	_txt(c, gpos + Vector2(12, 24) * s, "Q" if mv.input.device == "kbm" else "LB", 15 * s, UiTheme.CREAM)
	# 右侧信息
	var bx := x + 182 * s
	var bw := x + w - 18 * s - bx
	_txt(c, Vector2(bx, y + 44 * s), _fmt_time(mv.world.t), 36 * s, UiTheme.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true)
	var lv := "Lv %d" % h.lvl
	var lw := 74.0 * s
	var lr := Rect2(x + w - 18 * s - lw, y + 16 * s, lw, 32 * s)
	var sb := StyleBoxFlat.new()
	sb.bg_color = tc
	sb.set_corner_radius_all(int(16 * s))
	sb.anti_aliasing = true
	c.draw_style_box(sb, lr)
	_txt(c, lr.position + Vector2(0, 24 * s), lv, 21 * s, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, true, lw, 4)
	var hf := clampf(h.hp / h.max_hp, 0.0, 1.0)
	_bar(c, Rect2(bx, y + 60 * s, bw, 15 * s), hf, UiTheme.GREEN if hf > 0.35 else Color("#ff6b5e"))
	_txt(c, Vector2(bx + bw - 4 * s, y + 73 * s), "%d / %d" % [int(ceil(h.hp)), int(h.max_hp)], 13 * s, UiTheme.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, false, -1, 4)
	var W := h.weapon()
	_txt(c, Vector2(bx, y + 103 * s), String(W.get("name", "")), 20 * s, Color("#ffd8a8"))
	var nmw := UiTheme.body_font.get_string_size(String(W.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * s)).x
	_txt(c, Vector2(bx + nmw + 10 * s, y + 103 * s), "射程 %d" % int(SimWeapons.range_of(h)), 15 * s, UiTheme.SUB)
	var mag := SimWeapons.mag_size(h)
	if mag > 0:
		if h.reload_t > 0.0:
			var k2 := 1.0 - h.reload_t / maxf(0.01, h.reload_dur)
			_txt(c, Vector2(x + w - 18 * s, y + 103 * s), "换弹中", 18 * s, UiTheme.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
			_bar(c, Rect2(bx, y + 112 * s, bw, 5 * s), k2, UiTheme.GOLD)
		else:
			_txt(c, Vector2(x + w - 18 * s, y + 104 * s), "%d / %d" % [h.ammo, mag], 22 * s, Color("#ff8a7a") if h.ammo <= mag * 0.25 else UiTheme.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, true)
	# 进化路线 + 强化图标
	var ax := bx
	var ay := y + 138 * s
	var paths: Array = Data.evolutions().get("paths", {}).get(h.weapon_id, [])
	for i in 3:
		var l := h.evo_lv(["a", "b", "c"][i])
		if l <= 0 or i >= paths.size():
			continue
		var cc: Color = UiTheme.PATH_COLORS[i]
		c.draw_circle(Vector2(ax + 14 * s, ay), 14 * s, cc)
		if l >= 9:
			c.draw_arc(Vector2(ax + 14 * s, ay), 17 * s, 0, TAU, 32, UiTheme.CREAM, 2.5 * s, true)
		var nm := String(paths[i].name)
		_txt(c, Vector2(ax, ay + 6 * s), nm.substr(0, 1), 15 * s, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER, true, 28 * s, 0)
		# 小进度点：每 3 级一颗
		for d in 3:
			var on := l >= (d + 1) * 3
			c.draw_circle(Vector2(ax + 6 * s + d * 8 * s, ay + 21 * s), 2.5 * s, cc if on else Color(1, 1, 1, 0.2))
		ax += 36 * s
	for id in h.ab.keys():
		if ax > x + w - 34 * s:
			_txt(c, Vector2(ax, ay + 6 * s), "…", 20 * s, UiTheme.CREAM)
			break
		_ability_badge(c, Vector2(ax + 14 * s, ay), 14 * s, String(id), int(h.ab[id]))
		ax += 34 * s
	if h.ab.is_empty() and h.evo_total() == 0:
		_txt(c, Vector2(bx, ay + 6 * s), "还没有能力，升级来拿", 15 * s, Color(1, 0.95, 0.88, 0.45))
	if not h.choices.is_empty():
		_txt(c, Vector2(bx, y + 176 * s), "按 1 / 2 / 3 选升级" if mv.input.device == "kbm" else "按 X / Y / B 选升级", 16 * s, UiTheme.GOLD)
	else:
		_txt(c, Vector2(bx, y + 176 * s), "击败 %d    阵亡 %d" % [h.kills, h.deaths], 16 * s, UiTheme.SUB)


func _ability_badge(c: Control, p: Vector2, r: float, id: String, lv: int) -> void:
	var col := UiTheme.ability_group_color(id)
	c.draw_circle(p, r, Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 0.95))
	c.draw_arc(p, r, 0, TAU, 32, col, 2.0 * _s(), true)
	var ic := String(Data.abilities().get(id, {}).get("ic", "?"))
	_txt(c, p + Vector2(-r, r * 0.45), ic, r * 1.15, col.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, true, r * 2.0, 3)
	if lv > 1:
		for i in mini(lv, 5):
			c.draw_circle(p + Vector2(-r * 0.7 + i * r * 0.35, r + 3), 1.6 * _s(), col)


func _fmt_time(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _draw_crosshair(c: Control, s: float, h: SimHamster) -> void:
	if mv.autoplay or paused:
		return
	var p := c.get_local_mouse_position()
	var col := UiTheme.CREAM
	var r := 11.0 * s
	for k: int in [0, 1, 2, 3]:
		var a := k * PI * 0.5
		var d := Vector2(cos(a), sin(a))
		c.draw_line(p + d * r * 0.55, p + d * r * 1.35, Color(0.1, 0.06, 0.16, 0.9), 5 * s, true)
		c.draw_line(p + d * r * 0.55, p + d * r * 1.35, col, 2.4 * s, true)
	c.draw_circle(p, 2.2 * s, col)
	if h.reload_t > 0.0:
		var k2 := 1.0 - h.reload_t / maxf(0.01, h.reload_dur)
		c.draw_arc(p, 20 * s, 0, TAU, 40, Color(0.08, 0.05, 0.12, 0.8), 6 * s, true)
		c.draw_arc(p, 20 * s, -PI * 0.5, -PI * 0.5 + TAU * k2, 40, UiTheme.GOLD, 3.5 * s, true)
	if hit_t > 0.0:
		var k3 := hit_t / 0.14
		var d1 := (8.0 + (1.0 - k3) * 5.0) * s
		var d2 := (17.0 + (1.0 - k3) * 5.0) * s
		var hc := Color("#ff4d5e") if hit_kill else Color.WHITE
		hc.a = minf(1.0, k3 * 1.6)
		for dx: int in [-1, 1]:
			for dy: int in [-1, 1]:
				var v := Vector2(dx, dy).normalized()
				c.draw_line(p + v * d1, p + v * d2, hc, 3.2 * s, true)


func _draw_score(c: Control, s: float) -> void:
	var w := mv.world
	var cw := 520.0 * s
	var cx := root.size.x * 0.5
	var r := Rect2(cx - cw * 0.5, 12 * s, cw, 62 * s)
	_panel(c, r, 31 * s, 0.82)
	for team: String in ["blue", "red"]:
		var side := -1.0 if team == "blue" else 1.0
		var tc := UiTheme.BLUE if team == "blue" else UiTheme.RED
		var base: SimStructure = null
		var turrets: Array = []
		for st in w.structs:
			if st.team == team:
				if st.kind == "base":
					base = st
				else:
					turrets.append(st)
		var bxp := cx + side * 190 * s
		# 鼠窝血量
		var hk := base.hp / base.max_hp if base else 0.0
		var br := Rect2(bxp - 60 * s, 42 * s, 120 * s, 12 * s)
		_bar(c, br, hk, tc)
		_txt(c, Vector2(bxp - 60 * s, 36 * s), "蓝队鼠窝" if team == "blue" else "红队鼠窝", 16 * s, tc.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, true, 120 * s, 4)
		if base and base.shielded:
			c.draw_arc(Vector2(bxp + side * 78 * s, 43 * s), 11 * s, 0, TAU, 24, Color("#9fe8ff"), 2.5 * s, true)
			_txt(c, Vector2(bxp + side * 78 * s - 10 * s, 49 * s), "盾", 14 * s, Color("#9fe8ff"), HORIZONTAL_ALIGNMENT_CENTER, true, 20 * s, 3)
		for i in turrets.size():
			var t: SimStructure = turrets[i]
			var tp := Vector2(cx + side * (62 + i * 22) * s, 43 * s)
			var col := tc if not t.dead else Color(0.45, 0.42, 0.5)
			c.draw_rect(Rect2(tp - Vector2(8, 8) * s, Vector2(16, 16) * s), col)
			if not t.dead:
				c.draw_arc(tp, 13 * s, -PI * 0.5, -PI * 0.5 + TAU * t.hp / t.max_hp, 24, col.lightened(0.3), 2.5 * s, true)
	_txt(c, Vector2(cx - 30 * s, 52 * s), "VS", 22 * s, UiTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, true, 60 * s)
	var nxt := w.wave_next - w.t
	_txt(c, Vector2(cx - 120 * s, 98 * s), "下一波小兵 %d 秒" % ceili(maxf(0.0, nxt)), 16 * s, UiTheme.SUB, HORIZONTAL_ALIGNMENT_CENTER, false, 240 * s, 4)


func _draw_minimap(c: Control, s: float) -> void:
	var w := mv.world
	var m := w.map
	var mw := 360.0 * s
	var mh := mw * (m.max_y - m.min_y) / (m.max_x - m.min_x)
	var x0 := root.size.x - mw - 18 * s
	var y0 := 16.0 * s
	var k := mw / (m.max_x - m.min_x)
	_panel(c, Rect2(x0 - 8 * s, y0 - 8 * s, mw + 16 * s, mh + 16 * s), 12 * s, 0.82)
	var to := func(px: float, py: float) -> Vector2: return Vector2(x0 + (px - m.min_x) * k, y0 + (py - m.min_y) * k)
	for ln in m.lanes:
		var pts := PackedVector2Array()
		for p in m.lanes[ln]:
			pts.append(to.call(p.x, p.y))
		c.draw_polyline(pts, Color(0.76, 0.67, 0.53, 0.45), 4 * s, true)
	for so in m.solids:
		if so.kind == "wall" or so.off:
			continue
		if so.circle:
			c.draw_circle(to.call(so.x, so.y), maxf(1.0, so.r * k), Color(1, 1, 1, 0.14))
		else:
			c.draw_rect(Rect2(to.call(so.x, so.y), Vector2(so.w, so.h) * k), Color(1, 1, 1, 0.14))
	var team := mv.local_team
	for st in w.structs:
		var sz := (11.0 if st.kind == "base" else 7.0) * s
		var col := Color(0.47, 0.47, 0.5) if st.dead else (UiTheme.BLUE if st.team == "blue" else UiTheme.RED)
		var p: Vector2 = to.call(st.x, st.y)
		c.draw_rect(Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), col)
		if st.kind == "base" and st.shielded and not st.dead:
			c.draw_rect(Rect2(p - Vector2(sz, sz) * 0.5 - Vector2(3, 3) * s, Vector2(sz, sz) + Vector2(6, 6) * s), Color("#9fe8ff"), false, 1.5 * s)
	for mm in w.minions:
		if not mm.dead and mv.team_sees(mm):
			var p2: Vector2 = to.call(mm.x, mm.y)
			c.draw_rect(Rect2(p2 - Vector2(2, 2) * s, Vector2(4, 4) * s), UiTheme.BLUE if mm.team == "blue" else UiTheme.RED)
	for cr in w.crates:
		c.draw_circle(to.call(cr.x, cr.y), 2.5 * s, Color(1, 0.82, 0.4, 0.7))
	for hh in w.hams:
		if not hh.alive or not (hh.team == team or w.vis[team].has(hh.id)):
			continue
		var p3: Vector2 = to.call(hh.x, hh.y)
		var me := hh == mv.local
		var rr := (6.5 if me else 4.5) * s
		c.draw_circle(p3, rr, UiTheme.BLUE if hh.team == "blue" else UiTheme.RED)
		if hh.ctl == "player" or me:
			c.draw_arc(p3, rr, 0, TAU, 20, Color.WHITE, 1.8 * s, true)
	# 镜头范围
	var cam := mv.cam
	var corners := [Vector2.ZERO, Vector2(root.size.x, 0), root.size, Vector2(0, root.size.y)]
	var poly := PackedVector2Array()
	for cc in corners:
		var g := cam.screen_to_ground(cc)
		poly.append(to.call(g.x * 100.0, g.z * 100.0))
	poly.append(poly[0])
	var clip := PackedVector2Array()
	for p4 in poly:
		clip.append(Vector2(clampf(p4.x, x0, x0 + mw), clampf(p4.y, y0, y0 + mh)))
	c.draw_polyline(clip, Color(1, 1, 1, 0.45), 1.5 * s, true)


func _draw_feed(c: Control, s: float) -> void:
	var y := 16.0 * s + 360.0 * s * (mv.world.map.max_y - mv.world.map.min_y) / (mv.world.map.max_x - mv.world.map.min_x) + 40 * s
	for f in feeds:
		var a := clampf((6.0 - float(f.t)) * 2.0, 0.0, 1.0)
		var col: Color = f.color
		col.a = a
		var tw := UiTheme.body_font.get_string_size(String(f.text), HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * s)).x
		var r := Rect2(root.size.x - 18 * s - tw - 24 * s, y - 22 * s, tw + 24 * s, 32 * s)
		_panel(c, r, 12 * s, 0.7 * a)
		_txt(c, Vector2(r.position.x + 12 * s, y), String(f.text), 18 * s, col)
		y += 38 * s


func _draw_toasts(c: Control, s: float) -> void:
	if toasts.is_empty():
		return
	var t: Dictionary = toasts[0]
	var k := minf(1.0, minf(float(t.t) / 0.18, (float(t.dur) - float(t.t)) / 0.3))
	var col: Color = t.color
	col.a = clampf(k, 0.0, 1.0)
	var tw := UiTheme.display_font.get_string_size(String(t.text), HORIZONTAL_ALIGNMENT_LEFT, -1, int(28 * s)).x
	var r := Rect2(root.size.x * 0.5 - tw * 0.5 - 30 * s, 128 * s - (1.0 - clampf(k, 0.0, 1.0)) * 10 * s, tw + 60 * s, 52 * s)
	_panel(c, r, 26 * s, 0.86 * col.a)
	_txt(c, r.position + Vector2(0, 37 * s), String(t.text), 28 * s, col, HORIZONTAL_ALIGNMENT_CENTER, true, r.size.x)


func _draw_world_ui(c: Control, s: float) -> void:
	var w := mv.world
	var cam := mv.cam
	var team := mv.local_team
	var proj := func(x: float, y: float, hgt: float) -> Vector2:
		return cam.unproject_position(Vector3(x * 0.01, hgt, y * 0.01))
	for st in w.structs:
		if st.dead:
			continue
		var hgt := 2.85 if st.kind == "base" else 1.35
		var p: Vector2 = proj.call(st.x, st.y, hgt)
		var bw := (150.0 if st.kind == "base" else 84.0) * s
		_bar(c, Rect2(p.x - bw * 0.5, p.y, bw, 10 * s), st.hp / st.max_hp, UiTheme.BLUE if st.team == "blue" else UiTheme.RED, Color(0.05, 0.03, 0.08, 0.75))
		if st.kind == "base" and st.shielded:
			_txt(c, Vector2(p.x - 150 * s, p.y - 8 * s), "护盾中：先拆掉中路炮台", 15 * s, Color("#9fe8ff"), HORIZONTAL_ALIGNMENT_CENTER, false, 300 * s, 5)
	for m in w.minions:
		if m.dead or m.hp >= m.max_hp or not mv.team_sees(m):
			continue
		var p2: Vector2 = proj.call(m.x, m.y, 0.42)
		_bar(c, Rect2(p2.x - 16 * s, p2.y, 32 * s, 5 * s), m.hp / m.max_hp, UiTheme.BLUE if m.team == "blue" else UiTheme.RED, Color(0.05, 0.03, 0.08, 0.75))
	for cr in w.crates:
		if cr.hp >= cr.max_hp:
			continue
		var p3: Vector2 = proj.call(cr.x, cr.y, 0.8 if cr.big else 0.55)
		_bar(c, Rect2(p3.x - 22 * s, p3.y, 44 * s, 6 * s), cr.hp / cr.max_hp, Color("#ffd8a8"), Color(0.05, 0.03, 0.08, 0.75))
	for h in w.hams:
		if not h.alive:
			continue
		if h != mv.local and not (h.team == team or w.vis[team].has(h.id)):
			continue
		var p4: Vector2 = proj.call(h.x, h.y, 0.62 + h.z * 0.01)
		var hk := h.hp / h.max_hp
		var bw := 62.0 * s
		var col := UiTheme.GREEN if h.team == team else Color("#ff6b5e")
		_bar(c, Rect2(p4.x - bw * 0.5, p4.y, bw, 8 * s), hk, col, Color(0.05, 0.03, 0.08, 0.8))
		var tc := UiTheme.BLUE if h.team == "blue" else UiTheme.RED
		_txt(c, Vector2(p4.x - 100 * s, p4.y - 7 * s), "%s Lv%d" % [h.name, h.lvl], 21 * s, tc.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, false, 200 * s, 6)
		if h.shield > 0:
			_txt(c, Vector2(p4.x + bw * 0.5 + 4 * s, p4.y + 9 * s), "◎".repeat(h.shield), 12 * s, Color("#9fe8ff"))
	# 本地玩家：射程圈
	var me := mv.local
	if me != null and me.alive and not mv.autoplay:
		var rr := SimWeapons.range_of(me) * float(me.weapon().get("eff", 1.0))
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			pts.append(proj.call(me.x + cos(a) * rr, me.y + sin(a) * rr, 0.02))
		for i in 48:
			if i % 2 == 0:
				c.draw_line(pts[i], pts[i + 1], Color(1, 0.95, 0.85, 0.14), 2 * s, true)


func _draw_hearing(c: Control, s: float) -> void:
	var w := mv.world
	var me := mv.local
	if me == null or not me.alive:
		return
	var team := mv.local_team
	var hear := float(Data.rule("hearing.stepRange", 340)) * float(me.st.get("hearK", 1.0))
	var sz := root.size
	var center := sz * 0.5
	var shown := 0
	for n: Dictionary in w.noises:
		if shown > 8:
			break
		if String(n.team) == team:
			continue
		var src: SimEntity = w.entities.get(int(n.src))
		if src != null and (src.team == team or w.vis[team].has(src.id)):
			continue
		var d := Vector2(float(n.x) - me.x, float(n.y) - me.y).length()
		var max_d := hear if n.type == "step" else 1600.0 * float(n.loud) * float(me.st.get("hearK", 1.0))
		if d > max_d:
			continue
		var sp := mv.cam.unproject_position(Vector3(float(n.x) * 0.01, 0, float(n.y) * 0.01))
		var on_screen := sp.x > 40 * s and sp.x < sz.x - 40 * s and sp.y > 40 * s and sp.y < sz.y - 40 * s
		var k := 1.0 - float(n.t) / float(n.life)
		var col: Color = NCOL.get(String(n.type), Color.WHITE)
		col.a = clampf(k, 0.0, 1.0)
		if on_screen:
			# 屏幕内但看不见：在声源位置画一个扩散的声波圈
			var rr := (14.0 + (1.0 - k) * 26.0) * s
			c.draw_arc(sp, rr, 0, TAU, 32, col, 2.5 * s, true)
			c.draw_arc(sp, rr * 0.6, 0, TAU, 24, col * Color(1, 1, 1, 0.6), 2.0 * s, true)
		else:
			var dir := (sp - center).normalized()
			var t := minf((sz.x * 0.5 - 30 * s) / maxf(0.001, absf(dir.x)), (sz.y * 0.5 - 30 * s) / maxf(0.001, absf(dir.y)))
			var ep := center + dir * t
			var ang := dir.angle()
			c.draw_arc(ep, 34 * s, ang - 0.5, ang + 0.5, 16, col, 6 * s, true)
			c.draw_arc(ep, 24 * s, ang - 0.35, ang + 0.35, 12, col * Color(1, 1, 1, 0.6), 4 * s, true)
			var ip := ep - dir * 50 * s
			c.draw_circle(ip, 15 * s, Color(0.08, 0.05, 0.12, 0.85 * col.a))
			_txt(c, ip + Vector2(-15, 7) * s, String(NICON.get(String(n.type), "?")), 17 * s, col, HORIZONTAL_ALIGNMENT_CENTER, true, 30 * s, 3)
			_txt(c, ip + Vector2(-30, 34) * s, "%d米" % int(d * 0.01), 14 * s, col, HORIZONTAL_ALIGNMENT_CENTER, false, 60 * s, 4)
		shown += 1


func _draw_cards(c: Control, s: float, h: SimHamster) -> void:
	card_rects.clear()
	if h.choices.is_empty() or not h.alive:
		return
	var n := h.choices.size()
	var gap := 18.0 * s
	var cw := 300.0 * s
	var ch := 178.0 * s
	var tw := n * cw + (n - 1) * gap
	var x0 := root.size.x * 0.5 - tw * 0.5
	var y0 := root.size.y - ch - 40 * s
	var title := "天赋解锁！三选一" if String(h.choices[0].t) == "tal" else ("升级！选一个（还剩 %d 次）" % h.pending if h.pending > 1 else "升级！选一个奖励")
	var ta := clampf(cards_t * 5.0, 0.0, 1.0)
	_txt(c, Vector2(0, y0 - 20 * s), title, 30 * s, Color(1, 0.82, 0.4, ta), HORIZONTAL_ALIGNMENT_CENTER, true, root.size.x, 8)
	var mouse := c.get_local_mouse_position()
	var keys := ["1", "2", "3"] if mv.input.device == "kbm" else ["X", "Y", "B"]
	for i in n:
		var cd: Dictionary = h.choices[i]
		var L := SimCards.label(h, cd)
		var col: Color = UiTheme.CARD_COLORS.get(String(L.type), Color("#5fd38a"))
		var k := clampf((cards_t - i * 0.06) * 6.0, 0.0, 1.0)
		var ease := 1.0 - pow(1.0 - k, 3.0)
		var r := Rect2(x0 + i * (cw + gap), y0 + (1.0 - ease) * 60 * s, cw, ch)
		var hov := r.has_point(mouse) and not mv.autoplay
		if hov:
			r = r.grow(6 * s)
			r.position.y -= 8 * s
		card_rects.append(r)
		var sb := UiTheme.panel_box(Color(0.12, 0.08, 0.18, 0.94 * ease), int(20 * s), col if not hov else col.lightened(0.3), int((4 if hov else 3) * s))
		if String(L.badge) == "质变":
			sb.shadow_color = Color(col.r, col.g, col.b, 0.7)
			sb.shadow_size = int(18 * s)
		c.draw_style_box(sb, r)
		# 类型标签
		var tag := Rect2(r.position + Vector2(16, 14) * s, Vector2(70, 26) * s)
		var sbt := StyleBoxFlat.new()
		sbt.bg_color = col
		sbt.set_corner_radius_all(int(13 * s))
		sbt.anti_aliasing = true
		c.draw_style_box(sbt, tag)
		_txt(c, tag.position + Vector2(0, 20 * s), String(L.type), 16 * s, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER, true, tag.size.x, 0)
		if String(L.badge) != "":
			_txt(c, Vector2(r.end.x - 16 * s, r.position.y + 34 * s), String(L.badge), 20 * s, UiTheme.GOLD if L.badge != "质变" else col.lightened(0.4), HORIZONTAL_ALIGNMENT_RIGHT, true)
		# 图标
		var ic_c := r.position + Vector2(56, 98) * s
		match String(cd.t):
			"evo":
				c.draw_circle(ic_c, 36 * s, Color(col.r, col.g, col.b, 0.18))
				c.draw_arc(ic_c, 36 * s, 0, TAU, 40, col, 3 * s, true)
				if icons.has(h.weapon_id):
					c.draw_texture_rect(icons[h.weapon_id], Rect2(ic_c - Vector2(40, 40) * s, Vector2(80, 80) * s), false)
			"weap":
				if icons.has(String(cd.id)):
					c.draw_texture_rect(icons[String(cd.id)], Rect2(ic_c - Vector2(48, 48) * s, Vector2(96, 96) * s), false)
			"abil":
				_ability_badge(c, ic_c, 30 * s, String(cd.id), 1)
			_:
				c.draw_circle(ic_c, 30 * s, col)
		# 名字 + 描述
		var tx := r.position.x + 108 * s
		_txt(c, Vector2(tx, r.position.y + 78 * s), String(L.name), 26 * s, UiTheme.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true)
		var lines := _wrap(String(L.desc), cw - 124 * s, int(17 * s))
		for li in mini(3, lines.size()):
			_txt(c, Vector2(tx, r.position.y + 110 * s + li * 24 * s), lines[li], 17 * s, Color(1, 0.95, 0.88, 0.82), HORIZONTAL_ALIGNMENT_LEFT, false, -1, 4)
		if L.has("pathColor"):
			c.draw_rect(Rect2(r.position + Vector2(18, ch - 20) * s, Vector2(40, 6) * s), col)
		if String(cd.t) == "weap":
			var W2 := Data.weapon(String(cd.id))
			var rg := int(float(W2.get("range", 0)))
			_txt(c, Vector2(r.position.x + 18 * s, r.end.y - 14 * s), "射程 %d%s" % [rg, (" · 有效 %d" % int(rg * float(W2.eff))) if W2.has("eff") and float(W2.eff) < 1.0 else ""], 14 * s, UiTheme.SUB)
		var kc := Vector2(r.end.x - 26 * s, r.end.y - 26 * s)
		c.draw_circle(kc, 16 * s, UiTheme.GOLD)
		_txt(c, kc + Vector2(-16, 7) * s, keys[i], 19 * s, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER, true, 32 * s, 0)


func _wrap(text: String, width: float, size: int) -> Array:
	## 按字宽折行：中文逐字可断；数字 / 英文 / 百分号连在一起不拆；标点不放行首（避头尾）
	var tokens: Array = []
	var i := 0
	while i < text.length():
		var ch := text[i]
		if _is_word_char(ch):
			var j := i
			while j < text.length() and _is_word_char(text[j]):
				j += 1
			tokens.append(text.substr(i, j - i))
			i = j
		else:
			tokens.append(ch)
			i += 1
	var out: Array = []
	var cur := ""
	for tk: String in tokens:
		var t := cur + tk
		if UiTheme.body_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and cur.strip_edges() != "" and not _no_line_start(tk):
			out.append(cur.strip_edges(false, true))
			cur = tk.strip_edges(true, false)
		else:
			cur = t
	if cur != "":
		out.append(cur)
	return out


func _is_word_char(ch: String) -> bool:
	var c := ch.unicode_at(0)
	return (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or ch in ["%", ".", "+", "-", "×", "/"]


func _no_line_start(tk: String) -> bool:
	return tk in ["，", "。", "；", "：", "、", "！", "？", "）", "」", "”", ",", ".", ";", ":", "%", ")"]
