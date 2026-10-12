class_name Data
extends RefCounted
## 数值数据（game/data/*.json）的唯一入口。纯静态，不依赖自动加载，headless 测试也能用。

const DIR := "res://data/"

static var _cache: Dictionary = {}


static func load_json(name: String) -> Variant:
	if _cache.has(name):
		return _cache[name]
	var path := DIR + name + ".json"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Data: 无法打开 %s" % path)
		return {}
	var txt := f.get_as_text()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed == null:
		push_error("Data: JSON 解析失败 %s" % path)
		return {}
	_cache[name] = parsed
	return parsed


static func weapons() -> Dictionary: return load_json("weapons")
static func evolutions() -> Dictionary: return load_json("evolutions")
static func units() -> Dictionary: return load_json("units")
static func progression() -> Dictionary: return load_json("progression")
static func abilities() -> Dictionary: return load_json("abilities")
static func gadgets() -> Dictionary: return load_json("gadgets")
static func talents() -> Dictionary: return load_json("talents")
static func pets() -> Dictionary: return load_json("pets")
static func skins() -> Dictionary: return load_json("skins")
static func map_layout() -> Dictionary: return load_json("map_layout")
static func difficulty() -> Dictionary: return load_json("difficulty")
static func rules() -> Dictionary: return load_json("rules")


static func active_weapons() -> Array:
	## 当前开放的武器（rules.json 的 scope.weapons；2026-10-11 精简到 10 把，其余代码和数据保留，加回来改这个列表就行）
	var all := weapons().keys()
	return (rule("scope.weapons", all) as Array).filter(func(id): return all.has(id))


static func weapon(id: String) -> Dictionary:
	return weapons().get(id, {})


static func gadget_ids() -> Array:
	## 全部道具 id（gadgets.json 里有 slot 的条目；_doc / slots / upgrades 不算）
	var out: Array = []
	var G := gadgets()
	for k: String in G:
		if G[k] is Dictionary and (G[k] as Dictionary).has("slot"):
			out.append(k)
	return out


static func gadget(id: String) -> Dictionary:
	var g: Variant = gadgets().get(id, {})
	return g if g is Dictionary and (g as Dictionary).has("slot") else {}


static func gadget_pool(slot: String, pool: String) -> Array:
	## 某个槽（q / e）的某个池（start 开局池 / upgrade 升级池）里的道具 id，按 gadgets.json 里的顺序
	return gadget_ids().filter(func(id): return String(gadget(id).slot) == slot and String(gadget(id).get("pool", "")) == pool)


static func gadget_default(slot: String) -> String:
	## 开局默认装备：开局池的第一个
	var p := gadget_pool(slot, "start")
	return String(p[0]) if not p.is_empty() else ""


static func rule(path: String, default: Variant = null) -> Variant:
	## rule("hamster.rollTime") 这样按点号取值
	var cur: Variant = rules()
	for part in path.split("."):
		if cur is Dictionary and (cur as Dictionary).has(part):
			cur = (cur as Dictionary)[part]
		else:
			return default
	return cur


static func xp_need(level: int) -> int:
	if level >= int(progression().maxLevel):
		return 0 # 50级表没有“50升51”，不得套旧公式生成额外门槛。
	var arr: Array = progression().get("xpNeed", [])
	if level >= 1 and level <= arr.size():
		return int(arr[level - 1])
	push_error("成长档位不在升级表内：%d" % level)
	return 0


static func skin_ids() -> Array:
	return skins().keys()


static func clear_cache() -> void:
	_cache.clear()
