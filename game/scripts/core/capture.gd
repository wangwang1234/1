extends Node
## 截图 / 审阅图 / 帧率测试（自动加载 Capture）。只有命令行带 --capture 时才工作。
## 用法（-- 之后）：--capture <场景> --out <目录> [--seed N] [--dur 秒] [--every 秒]
## 场景：
##   menu       主菜单
##   style      风格帧：AI 对局里按间隔连拍（带 HUD + 无 HUD 两版）
##   gameplay   玩法截图序列：AI 对局，每 --every 秒一张
##   cards      升级三选一卡片
##   loadout    游戏内武器进化配件对比（每把枪：基础 / A9 / B9 / C9）
##   lineup     游戏内皮肤 × 队伍一排
##   screens    暂停菜单 + 设置面板 + 结算界面
##   codex      图鉴八页各一张（第一次打开要现场拍模型快照，等得久一些）；--tabs a,b 只拍部分分页
##   arsenal    批次 2：18 把武器在局里开火的样子（各带一条 9 级路线）；--weapons a,b 只拍部分
##   b2world    批次 2：野区、鼠王、战术道具、宠物
##   ui2        批次 2：开局大厅（单人 / 双人）、设置三页
##   duo        批次 2：本地双人分屏 AI 对局（--n 张，--every 秒）
##   perf       帧率测试：AI 对局实时跑 --dur 秒，写 perf.json / perf.csv（逻辑耗时、帧时间、1% 低帧）
## 建议配合 --fixed-fps 60（截图确定性，每帧 = 一步逻辑）；perf 不要加 --fixed-fps。

var args := {}
var out_dir := ""
var main: Node


func _ready() -> void:
	args = _parse(OS.get_cmdline_user_args())
	if not args.has("capture"):
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	out_dir = String(args.get("out", "user://capture"))
	if out_dir.is_relative_path() and not out_dir.begins_with("user://") and not out_dir.begins_with("res://"):
		# 相对路径：开发时相对当前目录；导出的 exe 相对 exe 所在目录
		var base := OS.get_environment("PWD")
		if base == "" or OS.has_feature("template"):
			base = OS.get_executable_path().get_base_dir()
		out_dir = base.path_join(out_dir)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


static func _parse(list: PackedStringArray) -> Dictionary:
	var out := {}
	var i := 0
	while i < list.size():
		var a := list[i]
		if a.begins_with("--"):
			var k := a.substr(2)
			if i + 1 < list.size() and not list[i + 1].begins_with("--"):
				out[k] = list[i + 1]
				i += 1
			else:
				out[k] = true
		i += 1
	return out


func _run() -> void:
	main = get_tree().current_scene
	var sc := String(args.capture)
	print("[capture] 场景 %s → %s" % [sc, out_dir])
	match sc:
		"menu":
			await _menu()
		"style":
			await _style()
		"codex":
			await _codex()
		"arsenal":
			await _arsenal()
		"ui2":
			await _ui2()
		"duo":
			await _duo()
		"b2world":
			await _b2world()
		"gameplay":
			await _gameplay()
		"cards":
			await _cards()
		"loadout":
			await _loadout()
		"lineup":
			await _lineup()
		"perf":
			await _perf()
		"screens":
			await _screens()
		_:
			push_error("未知截图场景：" + sc)
	print("[capture] 完成")
	get_tree().quit(0)


# ---------------------------------------------------------------------------
# 工具
# ---------------------------------------------------------------------------

func _wait(sec: float, fast: bool = false) -> void:
	## fast = 期间关掉 3D 渲染和界面（逻辑和表现层照常跑），软件渲染下截长序列能快很多
	var vp := get_viewport()
	var huds: Array = []
	var vps: Array = []
	var mv: MatchView = main.match_view if main != null else null
	var was_3d_off := vp.disable_3d
	if fast and not args.has("no-fast"):
		vp.disable_3d = true
		if mv != null:
			for pl in mv.players:
				if pl.vp != null:
					pl.vp.disable_3d = true
					vps.append(pl.vp)
				if pl.hud != null:
					huds.append(pl.hud)
			if mv.players.is_empty() and mv.hud != null:
				huds.append(mv.hud)
		for h in huds:
			(h as Hud).visible = false
			(h as Hud).portrait_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var t := 0.0
	while t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()
	if fast and not args.has("no-fast"):
		vp.disable_3d = was_3d_off if (mv == null or not mv.split) else true
		for v in vps:
			if is_instance_valid(v):
				(v as SubViewport).disable_3d = false
		for h in huds:
			if is_instance_valid(h):
				(h as Hud).visible = true
				(h as Hud).portrait_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await _frames(3)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := out_dir.path_join(name + ".png")
	img.save_png(p)
	print("[capture] %s（%.1f 秒）" % [p, Time.get_ticks_msec() / 1000.0])


func _start(autoplay: bool, weapon: String = "pistol") -> MatchView:
	var o := {"skin": String(args.get("skin", "gold")), "weapon": String(args.get("weapon", weapon)), "mode": String(args.get("mode", "slice")), "seed": int(args.get("seed", 11)), "autoplay": autoplay}
	main.opts.merge(o, true)
	main.start_match(main.opts, true)
	while main.match_view == null or main.match_view.world == null:
		await get_tree().process_frame
	await _frames(3)
	return main.match_view


# ---------------------------------------------------------------------------
# 场景
# ---------------------------------------------------------------------------

func _menu() -> void:
	main.show_menu(true)
	await _wait(2.5)
	await shot("menu")
	# 换皮肤 + 换枪各拍一张
	main.menu.opts.skin = "silver"
	main.menu.opts.weapon = "ak47"
	main.menu._refresh_hero()
	await _wait(1.2)
	await shot("menu_silver_ak47")


func _codex() -> void:
	main.show_menu(true)
	await _wait(1.0)
	main.menu._open_codex()
	var cx: Codex = null
	for c in main.menu.root.get_children():
		if c is Codex:
			cx = c
	var only := String(args.get("tabs", ""))    # --tabs talent,pet 只拍部分分页
	for t in Codex.TABS:
		if only != "" and not only.split(",").has(String(t[0])):
			continue
		cx.show_tab(String(t[0]))
		await _wait(0.5)
		# 等这一页的快照拍完
		var guard := 0
		while Snapshot._busy and guard < 600:
			await get_tree().process_frame
			guard += 1
		await _wait(0.3)
		await shot("codex_" + String(t[0]))


func _open_spot(w: SimWorld, r: float) -> Vector2:
	## 找一块前方（+x）比较空的地方当靶场
	for y in [1548.0, 2124.0, 971.0, 1300.0, 1800.0, 600.0, 2500.0]:
		for x in range(800, 4200, 60):
			var ok := true
			for k in 6:
				if w.map.overlaps_solid(x + k * 90.0, y, r):
					ok = false
					break
			if ok:
				return Vector2(x, y)
	return Vector2(2520, 1548)


func _clear_fx(w: SimWorld) -> void:
	w.bullets.clear()
	w.lobs.clear()
	w.fires.clear()
	w.zones.clear()
	w.smokes.clear()
	w.corrs.clear()


func _steps(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _arsenal() -> void:
	args["mode"] = "full"
	var mv := await _start(true)
	var w := mv.world
	var h := mv.local
	h.ctl = "player"
	h.ai = null
	h.inp.mx = 0.0
	h.inp.my = 0.0
	for e in w.mobs:
		e.dead = true
	for o in w.hams:
		if o != h:
			o.alive = false
			o.respawn_t = 9999.0
	var spot := _open_spot(w, 70.0)
	var targets: Array = []
	for k in 3:
		var m := w.spawn_minion("red", w.map.lanes.keys()[0])
		targets.append(m)
	var all_ids: Array = Data.weapons().keys()
	var ids: Array = all_ids
	if args.has("weapons"):
		ids = String(args.weapons).split(",", false)
	for wid: String in ids:
		var i := all_ids.find(wid)    # 文件编号按完整武器表，只补拍几把时也不会错位
		_clear_fx(w)
		mv.fx.clear()
		h.weapon_id = wid
		h.fire_cd = 0.0
		h.spin = 0.0
		h.charge = 0.0
		var evo := {"a": 0, "b": 0, "c": 0}
		evo[["a", "b", "c"][i % 3]] = 9
		evo[["a", "b", "c"][(i + 1) % 3]] = 3
		h.evo = evo
		h.ammo = SimWeapons.mag_size(h)
		h.reload_t = 0.0
		h.x = spot.x
		h.y = spot.y
		h.px = h.x
		h.py = h.y
		h.hp = h.max_hp
		h.iframes = 99.0
		h.aim = 0.0
		h.inp.aim = 0.0
		h.inp.has_aim_point = true
		h.inp.aim_x = spot.x + 300.0
		h.inp.aim_y = spot.y
		for k in targets.size():
			var m: SimMinion = targets[k]
			m.dead = false
			m.hp = 99999.0
			m.max_hp = 99999.0
			m.stun = 999.0
			m.x = spot.x + 260.0 + k * 50.0
			m.y = spot.y + (k - 1) * 70.0
			m.px = m.x
			m.py = m.y
		await _steps(20)
		h.inp.fire = true
		var kind := String(Data.weapon(wid).get("kind", "bullet"))
		match kind:
			"rail":
				await _steps(50)
				h.inp.fire = false
				await _steps(3)
			"melee":
				await _steps(16)
			"lob":
				await _steps(70)
			"rocket":
				await _steps(22)
			_:
				await _steps(32)
		await shot("arsenal_%02d_%s" % [i, wid])
		h.inp.fire = false


func _b2world() -> void:
	args["mode"] = "full"
	var mv := await _start(true)
	var w := mv.world
	var h := mv.local
	h.ctl = "player"
	h.ai = null
	h.inp.mx = 0.0    # 清掉 AI 留下的移动输入，否则会一直朝最后的方向走
	h.inp.my = 0.0
	h.inp.fire = false
	for o in w.hams:
		if o != h:
			o.alive = false
			o.respawn_t = 9999.0
	h.iframes = 9999.0
	h.weapon_id = "ak47"
	h.ammo = SimWeapons.mag_size(h)
	var parts := String(args.get("parts", "jungle,boss,gadgets")).split(",")    # --parts boss 只补拍鼠王
	if parts.has("jungle"):
		# 1) 蟑螂窝
		var roach: Dictionary = w.camps.filter(func(c): return c.type == "roach")[0]
		h.x = float(roach.x) - 170.0
		h.y = float(roach.y)
		h.px = h.x
		h.py = h.y
		h.inp.aim = 0.0
		await _steps(90)
		await shot("b2_jungle_roach")
		# 2) 鼠帮枪手
		var rat: Dictionary = w.camps.filter(func(c): return c.type == "rat")[0]
		h.x = float(rat.x) - 300.0
		h.y = float(rat.y)
		h.px = h.x
		h.py = h.y
		for e in w.mobs:
			if e.kind == "roach":
				e.target = null
				e.returning = true
		await _steps(75)
		await shot("b2_jungle_rat")
	if parts.has("boss"):
		# 3) 鼠王
		w.t = float(Data.progression().bossFirst) - 0.05
		await _steps(4)
		var b := w.boss
		if b != null:
			# 站在鼠王南边（鼠王面朝镜头），镜头焦点往北挪 1.1 米，鼠王落在画面中部、不被顶部比分条挡住；
			# 南边站不下就站北边（看到的是背影）。拍摄期间把鼠王钉在原地，弹幕照常
			for cand in [[PI * 0.5, 200.0], [PI * 0.5, 240.0], [-PI * 0.5, 190.0], [-PI * 0.5, 230.0]]:
				h.x = b.x + cos(float(cand[0])) * float(cand[1])
				h.y = b.y + sin(float(cand[0])) * float(cand[1])
				if w.map.has_los(b.x, b.y, h.x, h.y) and not w.map.overlaps_solid(h.x, h.y, h.r):
					mv.cam_focus_offset = Vector3(0, 0, -1.1) if float(cand[0]) > 0.0 else Vector3.ZERO
					break
			h.px = h.x
			h.py = h.y
			h.inp.aim = atan2(b.y - h.y, b.x - h.x)
			var bx := b.x
			var by := b.y
			for k in 150:
				b.x = bx
				b.y = by
				await _steps(1)
			await shot("b2_boss")
			for k in 60:
				b.x = bx
				b.y = by
				await _steps(1)
			await shot("b2_boss_2")
			w.deal_dmg(b, 99999.0, {"team": "blue", "owner": h, "x": b.x, "y": b.y})
			await _steps(30)
			await shot("b2_boss_down")
			mv.cam_focus_offset = Vector3.ZERO
	if not parts.has("gadgets"):
		return
	# 4) 道具 + 宠物展示
	_clear_fx(w)
	for e in w.mobs:
		e.dead = true
	var spot := _open_spot(w, 90.0)
	h.x = spot.x
	h.y = spot.y
	h.px = h.x
	h.py = h.y
	h.aim = 0.0
	h.inp.aim = 0.0
	h.inp.has_aim_point = true
	for pt in ["chick", "firefly", "hedgehog"]:
		h.pet_list.append(SimMobs.make_pet(w, pt, h))
	var foe := w.spawn_minion("red", w.map.lanes.keys()[0])
	foe.x = spot.x + 230.0
	foe.y = spot.y + 60.0
	foe.hp = 99999.0
	foe.max_hp = 99999.0
	foe.stun = 999.0
	var plan := [["sentry", 0, 0], ["decoy", 0, 0], ["mine", 0, 0], ["smoke", 420, -160], ["molotov", 300, 140], ["flare", 120, -60], ["eshield", 0, 0]]
	for g in plan:
		h.gadget = {"id": g[0], "lvl": 1, "cd": 0.0}
		h.inp.aim_x = spot.x + float(g[1])
		h.inp.aim_y = spot.y + float(g[2])
		h.aim = 0.3 if g[0] == "sentry" else (-0.4 if g[0] == "decoy" else 0.0)
		h.inp.aim = h.aim
		SimGadgets.use(w, h)
		if g[0] == "mine":
			w.mines[-1].x = spot.x - 60.0
		await _steps(8)
	h.inp.aim = 0.0
	await _steps(90)
	await shot("b2_gadgets")
	await _steps(60)
	await shot("b2_gadgets_2")


func _ui2() -> void:
	main.show_menu(true)
	await _wait(1.5)
	var menu: MainMenu = main.menu
	await shot("ui2_menu")
	menu._open_lobby()
	await _wait(0.8)
	await shot("ui2_lobby_solo")
	menu._lobby.o.duo = true
	menu._lobby.o.p2_input = "keys2"
	menu._lobby._refresh()
	await _wait(0.5)
	await shot("ui2_lobby_duo")
	menu._lobby._close()
	await _wait(0.4)
	menu._open_settings()
	await _wait(0.5)
	for k in ["video", "audio", "controls"]:
		menu._settings._show(k)
		await _wait(0.3)
		await shot("ui2_settings_" + k)


func _duo() -> void:
	main.opts.merge({"duo": true, "p2_input": "keys2", "p1_team": "blue", "p2_team": "red", "mode": "full", "seed": int(args.get("seed", 12)), "autoplay": true,
		"ai_blue": 3, "ai_red": 3}, true)
	main.start_match(main.opts, true)
	while main.match_view == null or main.match_view.world == null:
		await get_tree().process_frame
	await _frames(3)
	var t0 := float(args.get("from", 20.0))
	var every := float(args.get("every", 15.0))
	var n := int(args.get("n", 3))
	await _wait(t0, true)
	for i in n:
		await shot("duo_%02d" % i)
		await _wait(every, true)


func _style() -> void:
	var mv := await _start(true)
	var t0 := float(args.get("from", 24.0))
	var every := float(args.get("every", 3.0))
	var n := int(args.get("n", 10))
	await _wait(t0, true)
	for i in n:
		# 等到本地玩家在交战（活着、血量过半、附近有看得见的敌人）再拍，最多多等 20 秒，免得拍到在鼠窝回血
		for k in 20:
			if _in_action(mv):
				break
			await _wait(1.0, true)
		await shot("style_%02d" % i)
		mv.hud.visible = false
		await shot("style_%02d_clean" % i)
		mv.hud.visible = true
		await _wait(every, true)


func _in_action(mv: MatchView) -> bool:
	var h := mv.local
	if h == null or not h.alive or h.hp < h.max_hp * 0.5:
		return false
	var w := mv.world
	for e in w.hams:
		if e.alive and e.team != h.team and w.vis[h.team].has(e.id) and Vector2(e.x - h.x, e.y - h.y).length() < 650.0:
			return true
	for m in w.minions:
		if not m.dead and m.team != h.team and w.vis[h.team].has(m.id) and Vector2(m.x - h.x, m.y - h.y).length() < 550.0:
			return true
	return false


func _gameplay() -> void:
	var mv := await _start(true)
	await _wait(0.6)     # 等开局淡入结束
	var dur := float(args.get("dur", 120.0))
	var every := float(args.get("every", 2.0))
	var t := 0.0
	var i := 0
	while t < dur and not mv.world.over:
		await shot("seq_%03d" % i)
		i += 1
		await _wait(every, true)
		t += every
	print("[capture] 对局时间 %.1f 秒，结束=%s 胜方=%s" % [mv.world.t, mv.world.over, mv.world.winner])


func _cards() -> void:
	var mv := await _start(false, String(args.get("weapon", "ak47")))
	await _wait(2.0)
	var h := mv.local
	# 先给一点进化让面板上有徽章，再升一级弹卡
	h.evo = {"a": 4, "b": 2, "c": 0}
	h.ab = {"speed": 1, "armor": 2}
	SimHamsterLogic.calc_stats(h)
	SimHamsterLogic.give_xp(mv.world, h, float(h.xp_next - h.xp) + 1.0)
	await _wait(1.0)
	await shot("cards")
	h.inp.card = 1
	await _wait(1.2)
	await shot("cards_after")


func _screens() -> void:
	var mv := await _start(true)
	await _wait(30.0, true)
	main._on_pause()
	await _wait(0.5)
	await shot("pause")
	main.pause_menu._open_settings()
	await _wait(0.4)
	await shot("settings")
	main._resume()
	await _wait(1.0)
	# 结算：用当前战绩模拟一局结束（真实对局要 5–8 分钟才分胜负）
	var st := mv._stats()
	st.winner = "blue"
	main._on_finished("blue", st)
	await _wait(1.2)
	await shot("result")


func _stage() -> Node3D:
	main._clear()
	main._fade.color.a = 0.0
	var st := Node3D.new()
	main.add_child(st)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.05, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.4, 0.66)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.5
	e.glow_hdr_threshold = 1.15
	we.environment = e
	st.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.95, 0.88)
	key.rotation_degrees = Vector3(-42, 28, 0)
	key.shadow_enabled = true
	key.light_specular = 0.0
	st.add_child(key)
	for i in range(-3, 4):
		for j in range(-2, 1):
			var f := ToonMaterials.instance("res://assets/models/env/env_floor_wood.glb", 0.0)
			f.position = Vector3(i * 2.0, 0, j * 2.0 + 0.8)
			st.add_child(f)
	return st


func _fake(st: Node3D, team: String, x: float, z: float, weapon: String, evo: Dictionary, skin: String = "gold") -> HamsterView:
	var h := SimHamster.new()
	h.team = team
	h.skin = skin
	h.x = x * 100.0
	h.y = z * 100.0
	h.px = h.x
	h.py = h.y
	h.aim = PI * 0.5 - 0.9
	h.weapon_id = weapon
	h.evo = evo
	h.st = {"scale": 1.0}
	var v := HamsterView.new()
	st.add_child(v)
	v.setup(h, false)
	v.flashlight.visible = false
	v.set_meta("h", h)
	return v


func _sync_all(st: Node3D, sec: float) -> void:
	var t := 0.0
	while t < sec:
		for v in st.get_children():
			if v is HamsterView:
				var hv := v as HamsterView
				hv.sync(hv.get_meta("h"), 1.0, 1.0 / 60.0, true)
				hv.beam.visible = false
				hv.flashlight.visible = false
		await get_tree().process_frame
		t += get_process_delta_time()


func _caption(st: Node3D, pos: Vector3, text: String, col: Color, size: int = 64) -> void:
	UiTheme.fonts()
	var l := Label3D.new()
	l.text = text
	l.font = UiTheme.body_font
	l.font_size = size
	l.outline_size = 14
	l.modulate = col
	l.outline_modulate = UiTheme.INK
	l.pixel_size = 0.0018
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	st.add_child(l)


func _loadout() -> void:
	var paths: Dictionary = Data.evolutions().paths
	var wl: Array = Data.weapons().keys()
	if args.has("weapons"):
		wl = String(args.weapons).split(",", false)
	for w: String in wl:
		var st := _stage()
		var cam := Camera3D.new()
		cam.fov = 26
		st.add_child(cam)
		cam.position = Vector3(0, 1.25, 3.3)
		cam.look_at(Vector3(0, 0.22, 0))
		cam.current = true
		var combos := [{"a": 0, "b": 0, "c": 0}, {"a": 9, "b": 0, "c": 0}, {"a": 0, "b": 9, "c": 0}, {"a": 0, "b": 0, "c": 9}]
		var names := ["基础"]
		for p: Dictionary in paths[w]:
			names.append("%s Lv9" % p.name)
		for i in 4:
			var x := -1.02 + i * 0.68
			_fake(st, "blue", x, 0.0, w, combos[i])
			_caption(st, Vector3(x, 0.62, 0.0), names[i], UiTheme.CREAM if i == 0 else UiTheme.PATH_COLORS[i - 1], 56)
		_caption(st, Vector3(0, 0.85, -0.3), String(Data.weapon(w).name), UiTheme.GOLD, 88)
		await _sync_all(st, 1.0)
		await shot("loadout_" + w)
		# 同一把枪全满（三条路线都 9 级）的样子，近景
		for v in st.get_children():
			if v is HamsterView or v is Label3D:
				v.queue_free()
		await get_tree().process_frame
		var hv := _fake(st, "blue", 0.0, 0.3, w, {"a": 9, "b": 9, "c": 9})
		cam.position = Vector3(0.3, 0.72, 1.75)
		cam.look_at(Vector3(0.08, 0.24, 0.3))
		hv.get_meta("h").aim = PI * 0.5 - 1.25
		await _sync_all(st, 0.8)
		await shot("loadout_%s_max" % w)
		st.queue_free()
		await get_tree().process_frame


func _lineup() -> void:
	var st := _stage()
	var cam := Camera3D.new()
	cam.fov = 26
	st.add_child(cam)
	cam.position = Vector3(0, 1.4, 4.9)
	cam.look_at(Vector3(0, 0.25, 0))
	cam.current = true
	var skins := Data.skin_ids()
	var weapons := ["pistol", "ak47", "shotgun", "pistol"]
	var i := 0
	for team: String in ["blue", "red"]:
		for s in skins:
			var x := -1.4 + i * 0.4
			var v := _fake(st, team, x, -0.15 if team == "red" else 0.15, weapons[i % 4], {"a": 0, "b": 0, "c": 0}, String(s))
			v.get_meta("h").aim = PI * 0.5 + (0.0 if i % 2 == 0 else -0.4)
			_caption(st, Vector3(x, 0.6, 0.15 if team == "blue" else -0.15), String(Data.skins()[s].name), UiTheme.BLUE if team == "blue" else UiTheme.RED, 44)
			i += 1
	await _sync_all(st, 1.0)
	await shot("lineup")


func _perf() -> void:
	var dur := float(args.get("dur", 60.0))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)    # 测真实上限，不被显示器刷新率卡住
	var mv := await _start(true)
	await _wait(2.0)
	var frames: PackedFloat32Array = []
	var sim_ms: PackedFloat32Array = []
	var csv := ["t,frame_ms,fps,draw_calls,primitives,objects,sim_ms_avg"]
	var t := 0.0
	var last := Time.get_ticks_usec()
	var sim_acc := 0.0
	var sim_n := 0
	var last_row := 0.0
	# 单独测一下逻辑耗时：每帧多跑一份影子世界（同种子），不影响画面
	var shadow := SimWorld.new()
	shadow.setup(main.make_cfg(main.opts))
	while t < dur:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ft := (now - last) / 1000.0
		last = now
		t += ft / 1000.0
		frames.append(ft)
		var s0 := Time.get_ticks_usec()
		shadow.step(1.0 / 60.0)
		shadow.events.clear()
		var sm := (Time.get_ticks_usec() - s0) / 1000.0
		sim_ms.append(sm)
		sim_acc += sm
		sim_n += 1
		if frames.size() % 30 == 0 or t - last_row >= 1.0:    # 每 30 帧或每秒记一行（软件渲染很慢时也有数据）
			last_row = t
			csv.append("%.2f,%.2f,%.1f,%d,%d,%d,%.3f" % [t, ft, Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), sim_acc / maxf(1.0, sim_n)])
			sim_acc = 0.0
			sim_n = 0
	var sorted := frames.duplicate()
	sorted.sort()
	var n := sorted.size()
	var avg := 0.0
	for f in frames:
		avg += f
	avg /= maxf(1.0, n)
	var p99 := sorted[int(n * 0.99)] if n > 0 else 0.0
	var savg := 0.0
	for s in sim_ms:
		savg += s
	savg /= maxf(1.0, sim_ms.size())
	var ssorted := sim_ms.duplicate()
	ssorted.sort()
	var rep := {
		"frames": n, "seconds": t, "avg_ms": avg, "avg_fps": 1000.0 / maxf(avg, 0.001), "p99_ms": p99, "low1_fps": 1000.0 / maxf(p99, 0.001),
		"max_ms": sorted[n - 1] if n > 0 else 0.0, "sim_avg_ms": savg, "sim_p99_ms": ssorted[int(ssorted.size() * 0.99)] if ssorted.size() > 0 else 0.0,
		"resolution": "%dx%d" % [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
		"adapter": RenderingServer.get_video_adapter_name(), "vendor": RenderingServer.get_video_adapter_vendor(),
		"api": RenderingServer.get_video_adapter_api_version(), "os": OS.get_name(), "cpu": OS.get_processor_name(), "threads": OS.get_processor_count(),
		"hams": mv.world.hams.size(), "minions_end": mv.world.minions.size(), "match_t": mv.world.t,
	}
	var f := FileAccess.open(out_dir.path_join("perf.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(rep, "  "))
	f.close()
	var f2 := FileAccess.open(out_dir.path_join("perf.csv"), FileAccess.WRITE)
	f2.store_string("\n".join(csv))
	f2.close()
	print("[capture] 帧率：平均 %.1f fps，1%% 低 %.1f fps，逻辑 %.3f ms/步（%s）" % [rep.avg_fps, rep.low1_fps, savg, rep.adapter])
