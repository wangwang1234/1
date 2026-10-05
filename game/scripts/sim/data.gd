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
static func rules() -> Dictionary: return load_json("rules")


static func weapon(id: String) -> Dictionary:
	return weapons().get(id, {})


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
	var arr: Array = progression().get("xpNeed", [])
	if level >= 1 and level <= arr.size():
		return int(arr[level - 1])
	return int(round(24.0 + 15.0 * level + 2.4 * level * level))


static func skin_ids() -> Array:
	return skins().keys()


static func clear_cache() -> void:
	_cache.clear()
