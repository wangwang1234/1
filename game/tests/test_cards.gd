extends "res://tests/test_case.gd"
## 升级卡规则：三张不重复、第一张是进化、不出满级路线、换武器清零进化、范围限制、换武器概率。


func test_roll_basic() -> void:
	var w := make_world("slice", 11, 1, 0)
	var h := w.hams[0]
	for i in 200:
		h.choices = []
		SimCards.roll(w, h)
		eq(h.choices.size(), 3, "三张卡")
		eq(String(h.choices[0].t), "evo", "第一张是进化")
		var keys := {}
		for c in h.choices:
			var k := "%s_%s_%s" % [c.t, c.id, c.get("k", "")]
			check(not keys.has(k), "卡不重复")
			keys[k] = true
			check(c.t in ["evo", "abil", "weap", "gad", "glvl", "pet"], "卡片类型未知：%s" % c.t)
			if c.t == "weap":
				check(Data.rule("scope.weapons").has(c.id), "换武器只在开放范围内")
			if c.t == "gad":
				check(Data.rule("scope.gadgets").has(c.id) and c.id != h.gadget.id, "换道具在开放范围内且不是当前道具")
			if c.t == "abil":
				check(Data.rule("scope.abilities").has(c.id), "强化在开放范围内")
		if not failures.is_empty():
			return


func test_no_maxed_path() -> void:
	var w := make_world("slice", 12, 1, 0)
	var h := w.hams[0]
	h.evo = {"a": 9, "b": 9, "c": 8}
	for i in 100:
		h.choices = []
		SimCards.roll(w, h)
		for c in h.choices:
			if c.t == "evo":
				eq(String(c.k), "c", "只会出没满级的路线")


func test_weapon_swap_resets_evo() -> void:
	var w := make_world("slice", 13, 1, 0)
	var h := w.hams[0]
	h.evo = {"a": 3, "b": 1, "c": 0}
	h.choices = [{"t": "weap", "id": "ak47"}]
	h.pending = 1
	SimCards.apply(w, h, 0)
	eq(h.weapon_id, "ak47", "换上 AK")
	eq(h.evo_total(), 0, "进化清零")
	eq(h.ammo, SimWeapons.mag_size(h), "弹匣装满")


func test_swap_probability() -> void:
	var w := make_world("slice", 14, 1, 0)
	var h := w.hams[0]
	var n := 3000
	var swaps := 0
	h.lvl = 2
	for i in n:
		h.choices = []
		SimCards.roll(w, h)
		for c in h.choices:
			if c.t == "weap":
				swaps += 1
	var p := float(swaps) / n
	check(absf(p - 0.35) < 0.04, "没点进化且等级<6 时换武器约 35%%（实际 %.3f）" % p)
	h.evo = {"a": 6, "b": 1, "c": 0}
	swaps = 0
	for i in n:
		h.choices = []
		SimCards.roll(w, h)
		for c in h.choices:
			if c.t == "weap":
				swaps += 1
	p = float(swaps) / n
	check(absf(p - 0.05) < 0.02, "进化总等级≥6 时约 5%%（实际 %.3f）" % p)


func test_label_hides_level_numbers() -> void:
	var w := make_world("slice", 15, 1, 0)
	var h := w.hams[0]
	for k: String in ["a", "b", "c"]:
		for lv in range(0, 9):
			h.evo[k] = lv
			var L := SimCards.label(h, {"t": "evo", "k": k, "id": h.weapon_id})
			check(not String(L.badge).contains("Lv"), "卡面不显示等级数字")
			if lv == 8:
				eq(String(L.badge), "质变", "第 9 级标质变")
		h.evo[k] = 0
	var L2 := SimCards.label(h, {"t": "abil", "id": "strong"})
	eq(String(L2.badge), "新", "新强化标“新”")
