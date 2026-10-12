extends Node
## 表现层冒烟（headless，带自动加载）：godot --headless --path game res://tests/view_smoke.tscn
## 完整画面逻辑下，18 把武器 × 一条 9 级路线逐个开火并放右键技能，13 种道具逐个使用，野怪 / 鼠王 / 宠物都在场，最后切一次双人分屏。
## 运行时报错会出现在日志里（tools/test.sh 检查 SCRIPT ERROR）。


func _ready() -> void:
	await get_tree().process_frame
	await _solo()
	await _duo()
	print("[view_smoke] 完成 (done)")
	get_tree().quit(0)


func _drive(mv: MatchView, frames: int) -> void:
	for k in frames:
		mv._physics_process(1.0 / 60.0)
		mv._process(1.0 / 60.0)
		if k % 20 == 0:
			await get_tree().process_frame


func _solo() -> void:
	var mv := MatchView.new()
	add_child(mv)
	mv.start({"mode": "full", "seed": 5, "players": [{"team": "blue", "ctl": "player", "name": "测"}], "ai": {"blue": 2, "red": 2}})
	mv.autoplay = true
	var w := mv.world
	var h := mv.local
	_low_fps_springs(mv.ham_views[h.id], h)
	var i := 0
	for wid in Data.weapons().keys():
		h.weapon_id = String(wid)
		h.evo = {"a": 0, "b": 0, "c": 0}
		h.evo[["a", "b", "c"][i % 3]] = 9
		h.ammo = SimWeapons.mag_size(h)
		h.inp.fire = true
		await _drive(mv, 40)
		h.inp.fire = false
		# 右键武器技能（开放的 10 把有）
		h.skill_cd = 0.0
		SimSkills.use(w, h)     # 直接放（输入轮询会覆盖 inp.skill）
		await _drive(mv, 30)
		await _drive(mv, 3)
		i += 1
	print("[view_smoke] 18 把武器开火完成（含右键技能）")
	# 全部道具（旧 13 种 + Q / E 新 13 种）：装进所属槽并使用；部署物挨一枪、再被打掉
	for gid in Data.gadget_ids():
		h.hp = h.max_hp * 0.5
		SimGadgets.force_use(w, h, gid)
		await _drive(mv, 24)
		for s in w.structs:
			if s.kind == "dep" and not s.dead:
				w.deal_dmg(s, 1.0, {"team": "red", "owner": null, "x": s.x, "y": s.y})
		await _drive(mv, 6)
	for s in w.structs:
		if s.kind == "dep" and not s.dead:
			w.deal_dmg(s, 99999.0, {"team": "red", "owner": null, "x": s.x, "y": s.y})
	# 护盾展开器被打碎、传送被打断、捕鼠夹夹住敌人
	SimGadgets.force_use(w, h, "bubble")
	w.deal_dmg(h, h.max_hp, {"team": "red", "owner": null, "x": h.x, "y": h.y})
	h.hp = h.max_hp
	SimGadgets.force_use(w, h, "warp")
	await _drive(mv, 10)
	w.deal_dmg(h, 1.0, {"team": "red", "owner": null, "x": h.x, "y": h.y})
	SimGadgets.force_use(w, h, "trap")
	var foe := w._make_ham("red", "ai", "夹子靶", 99, "gold")
	foe.x = h.x
	foe.y = h.y + 2.0
	await _drive(mv, 30)
	foe.alive = false
	foe.respawn_t = 9999.0
	# HUD：两个道具槽 + 触屏按钮 + 4 张卡（含新道具卡和道具通用升级卡）
	var hud: Hud = mv.hud_of(h.id)
	hud.touch_mode = true
	await _drive(mv, 3)
	hud.press_slot("e")
	h.gup = {"gcdx": 2, "gcap": 2}
	h.choices = [{"t": "gad", "id": "cover"}, {"t": "gad", "id": "sonar"}, {"t": "gup", "id": "gcdx"}, {"t": "gup", "id": "gcap"}]
	h.pending = 1
	hud.show_cards()
	await _drive(mv, 20)
	h.inp.card = 0
	await _drive(mv, 10)
	hud.touch_mode = false
	print("[view_smoke] %d 种道具完成（Q / E 双槽、部署物、全息诱饵、触屏按钮、4 张卡）" % Data.gadget_ids().size())
	for type in ["chick", "firefly", "hedgehog"]:
		h.pet_list.append(SimMobs.make_pet(w, type, h))
	w.t = float(Data.progression().bossFirst) - 0.1
	await _drive(mv, 300)
	print("[view_smoke] 鼠王：%s，野怪 %d，宠物 %d" % [str(w.boss != null), w.mobs.size(), w.pets.size()])
	mv.queue_free()
	await get_tree().process_frame


func _low_fps_springs(view: HamsterView, h: SimHamster) -> void:
	# 软件渲染 / 卡帧后仍应回到正常体型，后坐不能把模型弹到远处。
	for dt in [1.0 / 60.0, 0.2, 1.0]:
		view.on_event({"t": "picked"})
		view.on_event({"t": "fire"})
		for frame in 120:
			view.sync(h, 1.0, dt, true)
			if not is_finite(view._sq) or not is_finite(view._kick) or absf(view._sq) > 2.0 or absf(view._kick) > 10.0:
				push_error("低帧率弹簧发散：dt=%s，sq=%s，kick=%s" % [dt, view._sq, view._kick])
				return
		if absf(view._sq - 1.0) > 0.01 or absf(view._kick) > 0.01:
			push_error("低帧率弹簧未回稳：dt=%s" % dt)
			return
	print("[view_smoke] 挤压 / 后坐：60 FPS、5 FPS、1 秒卡帧均回稳")


func _duo() -> void:
	var mv := MatchView.new()
	add_child(mv)
	mv.start({"mode": "full", "seed": 6, "players": [{"team": "blue", "ctl": "player", "name": "玩家1", "input": "kbm"}, {"team": "red", "ctl": "player", "name": "玩家2", "input": "keys2"}],
		"ai": {"blue": 3, "red": 3}})
	await _drive(mv, 240)
	print("[view_smoke] 双人分屏：%d 个镜头" % mv.players.size())
	# 2P 中途接上手柄：模拟手柄接入 → 2P 切到手柄方案（没有真手柄时摇杆读数为 0，只验证这条代码路径不报错），再拔掉切回方向键
	mv.players[1].want_pad = true
	mv._on_joy_changed(0, true)
	var switched: bool = mv.players[1].input.scheme == "pad" and not mv.players[0].input.allow_pad
	await _drive(mv, 60)
	mv._on_joy_changed(0, false)
	var back: bool = mv.players[1].input.scheme == "keys2" and mv.players[0].input.allow_pad
	await _drive(mv, 30)
	print("[view_smoke] 2P 手柄热插拔：切到手柄=%s，拔掉切回=%s" % [switched, back])
	if not switched or not back:
		push_error("2P 手柄热插拔切换失败")
	mv.queue_free()
	await get_tree().process_frame
