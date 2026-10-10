extends SceneTree
## 武器平衡测量（不是测试，run_all 不会跑它）：
##   godot --headless --path game -s res://tests/bench_weapons.gd [-- --part dummy,duel --trials 4 --out 路径.json --weapons a,b]
## dummy：对着木桩打 8 秒（静止 / 左右跑动；距离 150 / 300 / 450，武士刀贴身 60），记每秒伤害
## duel ：两只“困难”AI 各拿一把枪 1 对 1（同等级、同进化），18 把枪循环对打，记胜率；开局距离一半 160、一半 340，左右轮换
## 进化配置：base = 不进化（Lv1）；mid = 三条路线各 3 级（Lv10）；late = 两条路线各 6 级（Lv16）；a9 / b9 / c9 = 只点满一条路线（Lv10，只测木桩）

const TC := preload("res://tests/test_case.gd")
const CONFIGS := {"base": [0, 0, 0, 1], "mid": [3, 3, 3, 10], "late": [6, 6, 0, 16], "a9": [9, 0, 0, 10], "b9": [0, 9, 0, 10], "c9": [0, 0, 9, 10]}

var spot := Vector2.ZERO
var debug := false


func _world(seed_: int, n_players: int) -> SimWorld:
	var players: Array = []
	for i in n_players:
		players.append({"team": "blue" if i == 0 else "red", "ctl": "player", "name": "p%d" % i})
	var w := SimWorld.new()
	w.setup({"mode": "slice", "seed": seed_, "players": players, "ai": {"blue": 0, "red": 0}, "difficulty": "hard"})
	w.wave_next = 1e9
	w.boss_next = 1e9
	for c in w.crate_spots:
		c.resp = 1e9
	for c in w.crates:
		c.dead = true
	w.crates.clear()
	if spot == Vector2.ZERO:
		spot = _find_spot(w)
	return w


func _find_spot(w: SimWorld) -> Vector2:
	## 中路一块开阔地：往右 520、上下 ±160 都没有遮挡
	var b: Vector2 = w.map.base_pos.blue
	for ox in range(900, 3500, 40):
		for oy in [0.0, -80.0, 80.0, -160.0, 160.0, -240.0, 240.0]:
			var x := b.x + float(ox)
			var y := b.y + float(oy)
			var ok := true
			for dy in [-170.0, -60.0, 0.0, 60.0, 170.0]:
				if not w.map.has_los(x, y + dy, x + 540.0, y + dy) or w.map.point_solid(x + 540.0, y + dy, 20.0) != null:
					ok = false
					break
			if ok:
				return Vector2(x, y)
	return b + Vector2(1500, 0)


func _equip(w: SimWorld, h: SimHamster, wid: String, cfg: Array) -> void:
	h.weapon_id = wid
	h.evo = {"a": int(cfg[0]), "b": int(cfg[1]), "c": int(cfg[2])}
	h.lvl = int(cfg[3])
	SimHamsterLogic.calc_stats(h)
	h.hp = h.max_hp
	h.ammo = SimWeapons.mag_size(h)
	h.iframes = 0.0
	h.reload_t = 0.0


func _place(w: SimWorld, h: SimHamster, p: Vector2) -> void:
	h.x = p.x
	h.y = p.y
	h.px = p.x
	h.py = p.y
	h.vx = 0.0
	h.vy = 0.0


func _dummy(wid: String, cfg: Array, dist: float, strafe: bool, seed_: int) -> float:
	var w := _world(seed_, 2)
	var s: SimHamster = w.hams[0]
	var t: SimHamster = w.hams[1]
	_equip(w, s, wid, cfg)
	t.max_hp = 1e7
	t.hp = 1e7
	t.iframes = 0.0
	_place(w, s, spot)
	_place(w, t, spot + Vector2(dist, 0))
	var dur := 8.0
	var steps := int(dur * 60.0)
	for i in steps:
		var tt := i / 60.0
		t.iframes = 0.0
		t.inp.mx = 0.0
		t.inp.my = (1.0 if fmod(tt, 1.6) < 0.8 else -1.0) if strafe else 0.0
		t.inp.ml = absf(t.inp.my)
		t.inp.fire = false
		t.x = spot.x + dist
		s.inp.mx = 0.0
		s.inp.my = 0.0
		s.inp.ml = 0.0
		s.x = spot.x
		s.y = spot.y
		s.inp.aim = atan2(t.y - s.y, t.x - s.x)
		s.inp.aim_x = t.x
		s.inp.aim_y = t.y
		s.inp.has_aim_point = true
		s.inp.fire = true
		w.vis.blue[t.id] = true
		w.step(1.0 / 60.0)
		w.events.clear()
	var dps := (1e7 - t.hp) / dur
	w.dispose()
	return dps


func _duel(wa: String, wb: String, cfg: Array, seed_: int, swap: bool, gap: float = 340.0) -> float:
	## 返回 wa 的得分：赢 1、输 0、超时按剩余血量比例
	var w := _world(seed_, 0)
	var A := w._make_ham("blue", "ai", "A", 0, "gold")
	var B := w._make_ham("red", "ai", "B", 1, "pudding")
	for h in [A, B]:
		h.ai.prof = (Data.difficulty().levels.hard as Dictionary).duplicate()
		h.ai.prof.recallHp = 0.0
		h.ai.prof.outnumberHp = 0.0
		h.ai.jungle_t = 1e9
	_equip(w, A, wa, cfg)
	_equip(w, B, wb, cfg)
	var pa := spot + Vector2(0, 0)
	var pb := spot + Vector2(gap, 0)
	_place(w, A, pb if swap else pa)
	_place(w, B, pa if swap else pb)
	A.aim = atan2(B.y - A.y, B.x - A.x)
	B.aim = atan2(A.y - B.y, A.x - B.x)
	A.inp.aim = A.aim
	B.inp.aim = B.aim
	var res := -1.0
	for i in int(30.0 * 60.0):
		w.step(1.0 / 60.0)
		w.events.clear()
		if not A.alive or not B.alive:
			res = 1.0 if A.alive else 0.0
			break
	if debug:
		print("  %s vs %s 距离 %d：%s，用时 %.1f 秒；A 开火 %d 次 造成 %d 伤害 剩血 %d%%；B 开火 %d 次 造成 %d 伤害 剩血 %d%%" % [wa, wb, int(gap),
			"A 赢" if res == 1.0 else ("B 赢" if res == 0.0 else "超时"), w.t, A.shot_n, int(A.dmg_dealt), int(A.hp / A.max_hp * 100), B.shot_n, int(B.dmg_dealt), int(B.hp / B.max_hp * 100)])
	if res < 0.0:
		var ka := A.hp / A.max_hp
		var kb := B.hp / B.max_hp
		res = 0.5 + 0.5 * (ka - kb)
	w.dispose()
	return res


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var parts := "dummy,duel"
	var trials := 4
	var out := ""
	var only := ""
	var duel_cfgs := "base,mid"
	var vs := ""     # --vs pistol：只让 --weapons 里的枪逐局对打这把，打印每局细节
	var cfgs_arg := ""    # 自定义进化配置：--cfg 3.0.0.10/0.0.3.10（a.b.c.仓鼠等级）
	for i in args.size():
		match args[i]:
			"--part": parts = args[i + 1]
			"--trials": trials = int(args[i + 1])
			"--out": out = args[i + 1]
			"--weapons": only = args[i + 1]
			"--cfg": cfgs_arg = args[i + 1]
			"--duel": duel_cfgs = args[i + 1]
			"--vs": vs = args[i + 1]
	# 测量时 AI 不因残血撤退（否则 1 对 1 经常拖成超时）
	(Data.rules().ai as Dictionary).lowHp = 0.0
	var ids: Array = Data.rule("scope.weapons")
	if only != "":
		ids = Array(only.split(","))
	var result := {"dummy": {}, "duel": {}}
	if parts.contains("dummy"):
		print("== 木桩每秒伤害（静止 / 跑动）==")
		var cfgs := CONFIGS.duplicate()
		if cfgs_arg != "":
			cfgs = {}
			for c in cfgs_arg.split("/"):
				cfgs[c] = Array(c.split(".")).map(func(x): return int(x))
		for cname: String in cfgs:
			var cfg: Array = cfgs[cname]
			print("-- %s --" % cname)
			for wid: String in ids:
				var row := {}
				var line := "%-9s" % wid
				var dists := [60.0] if Data.weapon(wid).get("kind", "") == "melee" else [150.0, 300.0, 450.0]
				for d: float in dists:
					var a := _dummy(wid, cfg, d, false, 3)
					var b := _dummy(wid, cfg, d, true, 3)
					row["%d" % int(d)] = [snappedf(a, 0.1), snappedf(b, 0.1)]
					line += "  %3d: %6.1f / %6.1f" % [int(d), a, b]
				result.dummy["%s_%s" % [cname, wid]] = row
				print(line)
	if vs != "":
		debug = true
		for cname: String in duel_cfgs.split(","):
			for wid: String in ids:
				for k in trials:
					_duel(wid, vs, CONFIGS[cname], 100 + k, k % 2 == 1, 160.0 if (k / 2) % 2 == 0 else 340.0)
		quit(0)
		return
	if parts.contains("duel"):
		for cname: String in duel_cfgs.split(","):
			var cfg: Array = CONFIGS[cname]
			var score := {}
			var games := {}
			for wid in ids:
				score[wid] = 0.0
				games[wid] = 0
			var all: Array = Data.rule("scope.weapons")
			for i in ids.size():
				for opp: String in all:
					if opp == ids[i] or (only == "" and all.find(opp) <= all.find(ids[i])):
						continue
					for k in trials:
						var r := _duel(ids[i], opp, cfg, 100 + k, k % 2 == 1, 160.0 if (k / 2) % 2 == 0 else 340.0)
						score[ids[i]] += r
						games[ids[i]] += 1
						if score.has(opp):
							score[opp] += 1.0 - r
							games[opp] += 1
			var rows: Array = []
			for wid in ids:
				rows.append([wid, float(score[wid]) / maxf(1.0, float(games[wid]))])
			rows.sort_custom(func(p, q): return float(p[1]) > float(q[1]))
			print("== 1 对 1 胜率（%s，每对 %d 局）==" % [cname, trials])
			for r in rows:
				print("  %-9s %5.1f%%" % [r[0], float(r[1]) * 100.0])
				result.duel["%s_%s" % [cname, r[0]]] = snappedf(float(r[1]), 0.001)
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify(result, " ", true))
	quit(0)
