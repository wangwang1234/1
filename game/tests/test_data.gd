extends "res://tests/test_case.gd"
## 数据完整性：所有 JSON 能读，关键字段齐全，批次 1 范围内的内容都有进化数值。


func test_all_json_load() -> void:
	for n: String in ["weapons", "evolutions", "units", "progression", "abilities", "gadgets", "talents", "pets", "skins", "map_layout", "rules"]:
		var d: Variant = Data.load_json(n)
		check(d is Dictionary and not (d as Dictionary).is_empty(), "%s.json 读取失败或为空" % n)


func test_weapons_have_fields() -> void:
	eq(Data.weapons().size(), 18, "武器数量")
	for id in Data.weapons():
		var W: Dictionary = Data.weapon(id)
		for k: String in ["name", "rate", "dmg", "kind"]:
			check(W.has(k), "武器 %s 缺少 %s" % [id, k])


func test_evolutions_cover_all_weapons() -> void:
	var E: Dictionary = Data.evolutions()
	for id in Data.weapons():
		check(E.paths.has(id), "进化缺少武器 %s" % id)
		eq((E.paths[id] as Array).size(), 3, "%s 进化路线数" % id)
	for id in Data.rule("scope.weapons"):
		for p in E.paths[id]:
			check(p.has("effects"), "批次 1 武器 %s 的路线 %s 缺少 effects 数值" % [id, p.name])


func test_scope_abilities_exist() -> void:
	for id in Data.rule("scope.abilities"):
		check(Data.abilities().has(id), "scope 里的强化 %s 不存在" % id)
		check(Data.rules().abilities.has(id), "rules.abilities 缺少 %s" % id)


func test_xp_curve_matches_formula() -> void:
	for L in range(1, 31):
		eq(Data.xp_need(L), int(round(24.0 + 15.0 * L + 2.4 * L * L)), "Lv%d 升级经验" % L)
