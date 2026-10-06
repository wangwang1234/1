class_name Codex
extends Control
## 图鉴：武器 / 道具 / 强化 / 天赋 / 宠物 / 怪物 / 场景 / 形象 八页。
## 文字和数值全部从 data/*.json 读；配图用游戏内的三渲二着色器现场拍快照（Snapshot），强化和天赋用字标。

signal closed

const TABS := [["weapon", "武器"], ["gadget", "道具"], ["abil", "强化"], ["talent", "天赋"], ["pet", "宠物"], ["mob", "怪物"], ["scene", "场景"], ["skin", "形象"]]
const CARD_W := 560.0
const PIC := 132.0
const SKIN_DESC := {"gold": "经典橙色配奶白肚皮。", "pudding": "奶黄色的布丁仓鼠。", "silver": "雪白带一点灰。", "stripe": "灰色毛，背上有一道深色条纹。"}
const LEGEND := Color("#ffcf3a")

var tab := "weapon"
var grid: GridContainer
var scroll: ScrollContainer
var tab_btns := {}
var _gen := 0


func _ready() -> void:
	theme = UiTheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.06, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 80)
	m.add_theme_constant_override("margin_top", 48)
	m.add_theme_constant_override("margin_bottom", 40)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	m.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	v.add_child(head)
	var title := UiTheme.label("图鉴", 64, UiTheme.GOLD, true, 10)
	head.add_child(title)
	var hint := UiTheme.label("所有能在局里遇到的东西都在这里", 22, UiTheme.SUB, false, 4)
	hint.size_flags_vertical = Control.SIZE_SHRINK_END
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hint)
	var back := Button.new()
	back.text = "返回"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	head.add_child(back)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	var grp := ButtonGroup.new()
	for t in TABS:
		var b := Button.new()
		b.theme_type_variation = "GhostButton"
		b.toggle_mode = true
		b.button_group = grp
		b.text = t[1]
		b.custom_minimum_size = Vector2(110, 0)
		var key: String = t[0]
		b.pressed.connect(func() -> void:
			Audio.play2d("ui_click", -8.0)
			show_tab(key))
		b.mouse_entered.connect(func() -> void: Audio.play2d("ui_hover", -14.0, 0.05, 0.05))
		tabs.add_child(b)
		tab_btns[key] = b
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var cc := CenterContainer.new()
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cc)
	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	cc.add_child(grid)
	resized.connect(_relayout)
	show_tab(tab)
	(tab_btns[tab] as Button).call_deferred("grab_focus")


func _relayout() -> void:
	var w := size.x - 160.0
	grid.columns = maxi(1, int((w + 18.0) / (CARD_W + 18.0)))


func show_tab(key: String) -> void:
	tab = key
	_gen += 1
	(tab_btns[key] as Button).button_pressed = true
	for c in grid.get_children():
		c.queue_free()
	_relayout()
	for e in entries(key):
		grid.add_child(_card(e))
	scroll.scroll_vertical = 0


# ---------------------------------------------------------------------------
# 内容（和原型 codexList 对应）
# ---------------------------------------------------------------------------

static func entries(key: String) -> Array:
	var out := []
	match key:
		"weapon":
			var evo: Dictionary = Data.evolutions().get("paths", {})
			for id in Data.weapons():
				var w: Dictionary = Data.weapon(id)
				var st := []
				var kind := String(w.get("kind", "bullet"))
				var dmg := float(w.get("dmg", 0))
				match kind:
					"bullet":
						var n := int(w.get("n", 1))
						st.append("伤害 %d%s　射速 %s/秒" % [roundi(dmg), (" × %d 发" % n) if n > 1 else "", _num(w.get("rate", 0))])
					"rocket", "lob":
						st.append("爆炸伤害 %d　半径 %d" % [roundi(dmg + float(w.get("aoeDmg", 0))), int(w.get("aoe", 0))])
					"melee":
						st.append("伤害 %d　攻速 %s/秒　距离 %d" % [roundi(dmg), _num(w.get("rate", 0)), int(w.get("reach", 0))])
					"flame":
						st.append("每发伤害 %s，会点燃敌人" % _num(dmg))
					"rail":
						st.append("蓄力伤害 %d～%d，贯穿整条线" % [roundi(dmg), roundi(dmg + float(Data.rule("weapons.rail.chargeBonus", 140)))])
					"laser":
						st.append("持续伤害约 %d/秒" % roundi(dmg * float(w.get("rate", 0))))
				if int(w.get("mag", 0)) > 0:
					st.append("弹匣 %d　换弹 %s 秒" % [int(w.mag), _num(w.get("rl", 0))])
				if w.has("range") and kind != "melee":
					var eff := float(w.get("eff", 1.0))
					if eff < 1.0:
						st.append("射程 %d（有效 %d，超出后伤害衰减）" % [int(w.range), roundi(float(w.range) * eff)])
					else:
						st.append("射程 %d" % int(w.range))
				var paths := []
				for p in evo.get(id, []):
					paths.append(String(p.get("name", "")))
				out.append({"name": w.get("name", id), "desc": ("开局默认武器。" if id == "pistol" else "") + String(w.get("desc", "")), "stats": st, "paths": paths,
					"icon": "res://assets/icons/wpn_%s.png" % id, "snap": "res://assets/models/weapons/wpn_%s.glb" % id, "yaw": -PI * 0.5})
		"gadget":
			for id in Data.gadgets():
				var g: Dictionary = Data.gadgets()[id]
				var model := "res://assets/models/props/prop_frag.glb" if id == "frag" else "res://assets/models/props/gad_%s.glb" % id
				out.append({"name": g.get("name", id), "desc": String(g.get("desc", "")) + ("。开局默认道具" if id == "frag" else ""),
					"stats": ["冷却 %s 秒" % _num(g.get("cd", 0)), "用升级卡可以升级：冷却更短、效果更强"], "snap": model})
		"abil":
			for id in Data.abilities():
				var a: Dictionary = Data.abilities()[id]
				out.append({"name": a.get("name", id), "desc": a.get("desc", ""), "stats": ["可以叠加 %d 次" % int(a.get("max", 1))],
					"badge": String(a.get("ic", String(a.get("name", "?")).left(1))), "badge_col": UiTheme.ability_group_color(id)})
		"talent":
			var lv: Array = Data.evolutions().get("traitLevels", [10, 20, 30])
			var lv_txt := "、".join(lv.map(func(x: Variant) -> String: return str(int(x))))
			for id in Data.talents():
				var t: Dictionary = Data.talents()[id]
				out.append({"name": t.get("name", id), "rar": "天赋", "rar_col": Color("#ff6fd0"), "desc": t.get("desc", ""), "stats": ["第 %s 级三选一" % lv_txt],
					"badge": String(t.get("name", "?")).left(1), "badge_col": Color("#ff6fd0")})
		"pet":
			for id in Data.pets():
				var p: Dictionary = Data.pets()[id]
				out.append({"name": p.get("name", id), "desc": p.get("desc", ""), "stats": ["可以升级 %d 次，伤害越来越高" % int(Data.rule("pets.maxLevel", 3))],
					"snap": "res://assets/models/units/pet_%s.glb" % id})
		"mob":
			var mobs: Dictionary = Data.units().get("mobs", {})
			out.append({"name": "蟑螂", "desc": "成群住在野区的窝里，一靠近就整群冲上来咬人。",
				"stats": ["生命 %d　速度很快" % int(mobs.get("roach", {}).get("hp", 28)), "击败经验 %d，有几率掉落瓜子" % int(Data.rule("mobs.roach.xp", 6))],
				"snap": "res://assets/models/units/mob_roach.glb"})
			out.append({"name": "鼠帮枪手", "desc": "戴墨镜的老鼠，会蹲下瞄准（红色激光）后三连发，三只一伙守着野区。",
				"stats": ["生命 %d" % int(mobs.get("rat", {}).get("hp", 95)), "击败经验 %d" % int(Data.rule("mobs.rat.xp", 16))],
				"snap": "res://assets/models/units/mob_rat.glb"})
			out.append({"name": "鼠王", "rar": "首领", "rar_col": LEGEND,
				"desc": "开局 %s 后出现在地图上方中央。扇形弹幕、环形弹幕，还会召唤小弟。" % _dur(float(Data.rule("boss.spawnAt", 120))),
				"stats": ["生命 %d" % int(mobs.get("boss", {}).get("hp", 2600)),
					"击败后全队获得 %d 秒王冠加成（伤害 +%d%%）" % [int(Data.rule("boss.crownDur", 60)), roundi(float(Data.rule("boss.crownDmg", 0.25)) * 100.0)],
					"被击败后 %d 秒重生" % int(Data.rule("boss.respawn", 150))],
				"snap": "res://assets/models/units/mob_boss.glb"})
			out.append({"name": "小兵", "desc": "双方每 %d 秒在三条兵线各出 %d 个，自动朝敌方推进。" % [int(Data.rule("waves.interval", 30)), int(Data.rule("waves.perLane", 3))],
				"stats": ["生命 %d" % int(Data.units().get("minion", {}).get("hp", 70)), "击败经验 %d" % int(Data.rule("minion.xp", 7))],
				"snap": "res://assets/models/units/unit_minion.glb"})
			out.append({"name": "炮台", "desc": "每方三座。优先打小兵，但你攻击敌方仓鼠时会被锁定。",
				"stats": ["生命 %d　射程 %d" % [int(Data.rule("structure.turret.hp", 1700)), int(Data.rule("structure.turret.range", 480))], "摧毁一座后，对方仓鼠窝的护盾消失"],
				"snap": "res://assets/models/units/unit_turret.glb"})
		"scene":
			out.append({"name": "超级弹射装置", "desc": "踩上去翻着跟头飞进野区，空中可以开枪，落地有冲击波。", "stats": ["两边基地附近各两个"], "snap": "res://assets/models/props/prop_pad.glb"})
			out.append({"name": "爆炸桶", "desc": "打爆后范围爆炸，不分敌我，能连锁引爆。", "stats": ["%d 秒后复原" % int(Data.rule("props.barrel.resp", 50))], "snap": "res://assets/models/props/prop_barrel.glb"})
			out.append({"name": "纸箱掩体", "desc": "挡子弹也挡视线，可以打碎。", "stats": ["%d 秒后复原" % int(Data.rule("props.box.resp", 60))], "snap": "res://assets/models/props/prop_box.glb"})
			out.append({"name": "落地灯", "desc": "照亮周围一圈，被照到的敌人全队可见。打碎后这片区域变黑。", "stats": ["%d 秒后修好" % int(Data.rule("props.lamp.resp", 45))], "snap": "res://assets/models/props/prop_lamp.glb"})
			out.append({"name": "零食箱", "desc": "打开会掉落瓜子（经验），偶尔有回血奶酪。", "stats": ["%d 秒后刷新" % int(Data.rule("crates.small.resp", 40))], "snap": "res://assets/models/props/prop_crate.glb"})
			out.append({"name": "大礼箱", "desc": "地图下方正中央，掉落一大堆经验和奶酪。", "stats": ["%d 秒后刷新" % int(Data.rule("crates.big.resp", 90))], "snap": "res://assets/models/props/prop_gift.glb"})
		"skin":
			for id in Data.skins():
				out.append({"name": Data.skins()[id].get("name", id), "desc": SKIN_DESC.get(id, ""), "stats": ["在开局设置里选择，AI 随机"], "skin": id})
	return out


static func _num(x: Variant) -> String:
	var f := float(x)
	return str(int(f)) if is_equal_approx(f, roundf(f)) else str(snappedf(f, 0.01))


static func _dur(sec: float) -> String:
	if sec >= 60.0 and fmod(sec, 60.0) < 0.01:
		return "%d 分钟" % int(sec / 60.0)
	return "%d 秒" % int(sec)


# ---------------------------------------------------------------------------
# 卡片
# ---------------------------------------------------------------------------

func _card(e: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, 0)
	var sb := UiTheme.panel_box(Color(0.14, 0.1, 0.2, 0.92), 16, Color(1, 1, 1, 0.07), 2)
	sb.shadow_size = 6
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)
	var frame := PanelContainer.new()
	var fsb := UiTheme.panel_box(Color(0.06, 0.04, 0.1, 0.9), 12, Color(1, 1, 1, 0.05), 1)
	fsb.shadow_size = 0
	fsb.set_content_margin_all(2)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.custom_minimum_size = Vector2(PIC, PIC)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(frame)
	if e.has("badge"):
		frame.add_child(_badge(String(e.badge), e.get("badge_col", UiTheme.GOLD)))
	else:
		var pic := TextureRect.new()
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(PIC - 4, PIC - 4)
		frame.add_child(pic)
		if e.has("icon") and ResourceLoader.exists(String(e.icon)):
			pic.texture = load(String(e.icon))
		_fill_snapshot(pic, e)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var nr := HBoxContainer.new()
	nr.add_theme_constant_override("separation", 10)
	info.add_child(nr)
	nr.add_child(UiTheme.label(String(e.name), 32, UiTheme.CREAM, true, 6))
	if e.has("rar"):
		var tag := PanelContainer.new()
		var tsb := UiTheme.panel_box(e.get("rar_col", LEGEND), 999, Color(0, 0, 0, 0), 0)
		tsb.shadow_size = 0
		tsb.content_margin_left = 10
		tsb.content_margin_right = 10
		tsb.content_margin_top = 1
		tsb.content_margin_bottom = 2
		tag.add_theme_stylebox_override("panel", tsb)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tl := UiTheme.label(String(e.rar), 17, UiTheme.INK, false, 0)
		tag.add_child(tl)
		nr.add_child(tag)
	var desc := UiTheme.label(String(e.get("desc", "")), 20, UiTheme.CREAM, false, 0)
	desc.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	desc.custom_minimum_size = Vector2(CARD_W - PIC - 70, 0)
	info.add_child(desc)
	for s in e.get("stats", []):
		var l := UiTheme.label(String(s), 18, UiTheme.SUB, false, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		l.custom_minimum_size = Vector2(CARD_W - PIC - 70, 0)
		info.add_child(l)
	if e.has("paths") and not (e.paths as Array).is_empty():
		var pr := HBoxContainer.new()
		pr.add_theme_constant_override("separation", 8)
		pr.add_child(UiTheme.label("进化路线", 18, UiTheme.SUB, false, 0))
		for i in (e.paths as Array).size():
			var col: Color = UiTheme.PATH_COLORS[i % UiTheme.PATH_COLORS.size()]
			pr.add_child(UiTheme.label(String(e.paths[i]), 18, col, false, 3))
		info.add_child(pr)
	return card


func _badge(text: String, col: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(PIC - 4, PIC - 4)
	c.draw.connect(func() -> void:
		var ctr := c.size * 0.5
		var r := minf(c.size.x, c.size.y) * 0.36
		c.draw_circle(ctr + Vector2(0, 4), r, Color(0, 0, 0, 0.35))
		c.draw_circle(ctr, r, col.darkened(0.45))
		c.draw_circle(ctr, r * 0.86, col)
		c.draw_arc(ctr, r * 0.86, PI * 1.1, PI * 1.6, 16, Color(1, 1, 1, 0.45), r * 0.1, true)
		UiTheme.fonts()
		var fs := int(r * 1.05)
		var f := UiTheme.display_font
		var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		UiTheme.draw_text_outline(c, f, ctr + Vector2(-ts.x * 0.5, fs * 0.36), text, fs, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 8))
	return c


func _fill_snapshot(pic: TextureRect, e: Dictionary) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var key := ""
	var builder: Callable
	if e.has("skin"):
		key = "skin_" + String(e.skin)
		builder = _skin_builder(String(e.skin))
	elif e.has("snap") and ResourceLoader.exists(String(e.snap)):
		key = String(e.snap)
		builder = Snapshot.model(key, -1.0, float(e.get("yaw", 0.0)))
	else:
		return
	var cached := Snapshot.cached(key)
	if cached != null:
		pic.texture = cached
		return
	var gen := _gen
	var tex: Texture2D = await Snapshot.get_tex(self, key, builder)
	if gen == _gen and is_instance_valid(pic) and tex != null:
		pic.texture = tex


static func _skin_builder(skin: String) -> Callable:
	return func(holder: Node3D) -> Dictionary:
		var n := ToonMaterials.instance(HamsterView.MODEL, 1.8)
		holder.add_child(n)
		ToonMaterials.set_param(n, "skin_index", maxi(0, Data.skin_ids().find(skin)))
		ToonMaterials.set_param(n, "team_index", 0)
		for x in n.find_children("expr_*", "", true, false):
			(x as Node3D).visible = String(x.name) in ["expr_eyes_happy", "expr_mouth_open"]
		var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
		if ap and ap.has_animation("idle"):
			ap.play("idle")
			ap.seek(0.4, true)
		n.rotation.y = deg_to_rad(-20.0)
		return {"center": Vector3(0, 0.17, 0), "size": 0.42}


func _close() -> void:
	_gen += 1
	Audio.play2d("ui_click", -6.0)
	closed.emit()
	queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
		return
	# 手柄肩键 / Q E 切页
	var dir := 0
	if ev is InputEventJoypadButton and ev.pressed:
		if ev.button_index == JOY_BUTTON_LEFT_SHOULDER:
			dir = -1
		elif ev.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			dir = 1
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_Q:
			dir = -1
		elif ev.keycode == KEY_E:
			dir = 1
	if dir != 0:
		var i := 0
		for k in TABS.size():
			if TABS[k][0] == tab:
				i = k
		var nk: String = TABS[(i + dir + TABS.size()) % TABS.size()][0]
		Audio.play2d("ui_click", -8.0)
		show_tab(nk)
		get_viewport().set_input_as_handled()
