extends Node
## 表现层冒烟（headless，带自动加载）：godot --headless --path game res://tests/view_smoke.tscn
## 完整画面逻辑下，18 把武器 × 一条 9 级路线逐个开火，13 种道具逐个使用，野怪 / 鼠王 / 宠物都在场，最后切一次双人分屏。
## 运行时报错会出现在日志里（tools/test.sh 检查 SCRIPT ERROR）。


func _ready() -> void:
	await get_tree().process_frame
	await _solo()
	await _duo()
	print("[view_smoke] 完成")
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
	var i := 0
	for wid in Data.weapons().keys():
		h.weapon_id = String(wid)
		h.evo = {"a": 0, "b": 0, "c": 0}
		h.evo[["a", "b", "c"][i % 3]] = 9
		h.ammo = SimWeapons.mag_size(h)
		h.inp.fire = true
		await _drive(mv, 40)
		h.inp.fire = false
		await _drive(mv, 3)
		i += 1
	print("[view_smoke] 18 把武器开火完成")
	for gid in Data.gadgets().keys():
		h.gadget = {"id": gid, "lvl": 2, "cd": 0.0}
		h.inp.gadget = true
		await _drive(mv, 30)
	print("[view_smoke] 13 种道具完成")
	for type in ["chick", "firefly", "hedgehog"]:
		h.pet_list.append(SimMobs.make_pet(w, type, h))
	w.t = float(Data.progression().bossFirst) - 0.1
	await _drive(mv, 300)
	print("[view_smoke] 鼠王：%s，野怪 %d，宠物 %d" % [str(w.boss != null), w.mobs.size(), w.pets.size()])
	mv.queue_free()
	await get_tree().process_frame


func _duo() -> void:
	var mv := MatchView.new()
	add_child(mv)
	mv.start({"mode": "full", "seed": 6, "players": [{"team": "blue", "ctl": "player", "name": "玩家1", "input": "kbm"}, {"team": "red", "ctl": "player", "name": "玩家2", "input": "keys2"}],
		"ai": {"blue": 3, "red": 3}})
	await _drive(mv, 240)
	print("[view_smoke] 双人分屏：%d 个镜头" % mv.players.size())
	mv.queue_free()
	await get_tree().process_frame
