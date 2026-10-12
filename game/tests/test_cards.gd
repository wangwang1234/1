extends "res://tests/test_case.gd"
## 升级卡规则：四张不重复、第一张是进化、不出满级路线、换武器清零进化、范围限制、换武器概率；新道具卡只出升级池里身上没有的。
## 起手手枪（weapons.json 的 noEvo）不出进化卡，第一张固定是换武器（2026-10-11 导演）；其余规则用 AK 测。


func test_roll_basic() -> void:
	var w := make_world("slice", 11, 1, 0)
	var h := w.hams[0]
	h.weapon_id = "ak47"
	for i in 200:
		h.choices = []
		SimCards.roll(w, h)
		eq(h.choices.size(), int(Data.rule("cards.count")), "四张卡")
		eq(String(h.choices[0].t), "evo", "第一张是进化")
		var keys := {}
		for c in h.choices:
			var k := "%s_%s_%s" % [c.t, c.id, c.get("k", "")]
			check(not keys.has(k), "卡不重复")
			keys[k] = true
			check(c.t in ["evo", "abil", "weap", "gad", "gup", "pet"], "卡片类型未知：%s" % c.t)
			if c.t == "weap":
				check(Data.rule("scope.weapons").has(c.id), "换武器只在开放范围内")
			if c.t == "gad":
				var slot := String(Data.gadget(c.id).slot)
				check(Data.gadget_pool(slot, "upgrade").has(c.id) and c.id != String(h.gad[slot].id), "新道具在升级池里且不是身上那个")
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
	## 换武器按 weaponSwap 阶段权重：刚开局（没点进化、等级 < 6）常见，进化多了以后少见
	var w := make_world("slice", 14, 1, 0)
	var h := w.hams[0]
	h.weapon_id = "ak47"
	var n := 3000
	var swaps := 0
	h.lvl = 2
	for i in n:
		h.choices = []
		SimCards.roll(w, h)
		for c in h.choices:
			if c.t == "weap":
				swaps += 1
	var p_fresh := float(swaps) / n
	check(p_fresh > 0.25 and p_fresh < 0.7, "没点进化且等级<6 时换武器常见（实际 %.3f）" % p_fresh)
	h.evo = {"a": 6, "b": 1, "c": 0}
	swaps = 0
	for i in n:
		h.choices = []
		SimCards.roll(w, h)
		for c in h.choices:
			if c.t == "weap":
				swaps += 1
	var p_late := float(swaps) / n
	check(p_late < 0.15 and p_fresh > p_late * 3.0, "进化总等级≥6 时少见（实际 %.3f）" % p_late)
	note = "换武器卡出现率：刚开局 %.2f，后期 %.2f" % [p_fresh, p_late]


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


func test_pistol_never_offers_evolutions_and_leads_with_weapons() -> void:
	var w := make_world("slice", 16, 1, 0)
	var h := w.hams[0]
	eq(h.weapon_id, "pistol", "前提：起手手枪")
	var two := 0
	for i in 500:
		h.choices = []
		SimCards.roll(w, h)
		eq(String(h.choices[0].t), "weap", "拿手枪时第一张固定是换武器")
		var nweap := 0
		for c in h.choices:
			check(c.t != "evo", "手枪不出进化卡")
			if c.t == "weap":
				nweap += 1
				check(c.id != "pistol", "不会换成手枪")
		if nweap >= 2:
			two += 1
		if not failures.is_empty():
			return
	check(two > 150, "拿手枪时经常同时给两把枪选（实际 %d / 500）" % two)
