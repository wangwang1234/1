class_name SimMap
extends RefCounted
## 地图：墙体与障碍（矩形/圆）、碰撞推出、视线、寻路流场。对应原型 n1.js 的物理与寻路部分。
## 坐标单位与原型一致（1 = 1 厘米），平面坐标 (x, y)。

class Solid:
	extends RefCounted
	var circle := false
	var x := 0.0
	var y := 0.0
	var w := 0.0
	var h := 0.0
	var r := 0.0
	var kind := ""
	var ht := 50.0
	var off := false
	var prop: Object = null   # 可破坏物件（SimProp）
	# 包围盒
	var x0 := 0.0
	var y0 := 0.0
	var x1 := 0.0
	var y1 := 0.0

	func update_aabb() -> void:
		if circle:
			x0 = x - r; y0 = y - r; x1 = x + r; y1 = y + r
		else:
			x0 = x; y0 = y; x1 = x + w; y1 = y + h


const GRID := 64.0
const NAV_CELL := 50.0
const NAV_CLEARANCE := 20.0

var width := 5040.0
var height := 3096.0
var min_x := 0.0
var min_y := 0.0
var max_x := 5040.0
var max_y := 3096.0
var solids: Array[Solid] = []
var lanes: Dictionary = {}          # name -> PackedVector2Array（蓝队方向）
var pads: Array = []                # [{x,y,tx,ty}]
var crate_spots: Array = []         # [{x,y,big}]
var prop_spots: Array = []          # [{kind,x,y}]
var base_pos: Dictionary = {}       # team -> Vector2
var turret_pos: Dictionary = {}     # team -> Array[Vector2]
var mode := "full"

var _grid: Dictionary = {}          # int key -> Array[Solid]
var nav_gc := 0
var nav_gr := 0
var nav_pass := PackedByteArray()
var _field_cache: Dictionary = {}   # cell -> PackedInt32Array
var _field_order: Array = []


func build(mode_: String = "full") -> void:
	mode = mode_
	var L: Dictionary = Data.map_layout()
	width = float(L.get("WW", 5040))
	height = float(L.get("WH", 3096))
	min_x = 0.0; min_y = 0.0; max_x = width; max_y = height
	var heights: Dictionary = L.get("solidHeights", {})
	var bounds := Rect2(0, 0, width, height)
	var slice: Dictionary = Data.rule("match.slice", {})
	if mode == "slice":
		var b: Array = slice.get("bounds", [0, 0, width, height])
		bounds = Rect2(float(b[0]), float(b[1]), float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
		min_x = bounds.position.x; min_y = bounds.position.y; max_x = bounds.end.x; max_y = bounds.end.y
	solids.clear()
	for s: Dictionary in L.get("solids", []):
		var kind: String = s.get("kind", "")
		if kind in ["pbox", "plamp", "pbarrel"]:
			continue  # 可破坏物件由 SimProp 创建
		if kind == "wall" and mode == "slice":
			continue
		var so := Solid.new()
		so.kind = kind
		so.ht = float(heights.get(kind, 50))
		if s.has("r"):
			so.circle = true
			so.x = float(s.x); so.y = float(s.y); so.r = float(s.r)
		else:
			so.x = float(s.x); so.y = float(s.y); so.w = float(s.w); so.h = float(s.h)
		so.update_aabb()
		if mode == "slice":
			var c := Vector2((so.x0 + so.x1) * 0.5, (so.y0 + so.y1) * 0.5)
			if not bounds.has_point(c):
				continue
		solids.append(so)
	if mode == "slice":
		var t := 60.0
		_add_rect(bounds.position.x, bounds.position.y, bounds.size.x, t, "wall", float(heights.get("wall", 160)))
		_add_rect(bounds.position.x, bounds.end.y - t, bounds.size.x, t, "wall", 24.0)
		_add_rect(bounds.position.x, bounds.position.y, t, bounds.size.y, "wall", 120.0)
		_add_rect(bounds.end.x - t, bounds.position.y, t, bounds.size.y, "wall", 120.0)
	# 兵线
	lanes.clear()
	var lane_names: Array = ["top", "mid", "bot"]
	if mode == "slice":
		lane_names = slice.get("lanes", ["mid"])
	for ln in lane_names:
		var pts := PackedVector2Array()
		for p in L.lanes[ln]:
			pts.append(Vector2(float(p[0]), float(p[1])))
		lanes[ln] = pts
	base_pos = {"blue": Vector2(float(L.base.blue.x), float(L.base.blue.y)), "red": Vector2(float(L.base.red.x), float(L.base.red.y))}
	turret_pos = {}
	for team in ["blue", "red"]:
		var arr: Array = []
		var idxs: Array = [0, 1, 2]
		if mode == "slice":
			idxs = slice.get("turrets", {}).get(team, [1])
		for i in idxs:
			var p: Array = L.turrets[team][int(i)]
			arr.append(Vector2(float(p[0]), float(p[1])))
		turret_pos[team] = arr
	# 物件、箱子、弹射装置
	prop_spots.clear()
	for p: Dictionary in L.get("props", []):
		var pv := Vector2(float(p.x), float(p.y))
		if bounds.has_point(pv):
			prop_spots.append({"kind": p.kind, "x": pv.x, "y": pv.y})
	crate_spots.clear()
	for c in _crate_list(L):
		if bounds.has_point(Vector2(c.x, c.y)):
			crate_spots.append(c)
	pads.clear()
	var pad_targets: Array = slice.get("padTargets", [])
	var i_pad := 0
	for p: Dictionary in L.get("pads", []):
		var pv := Vector2(float(p.x), float(p.y))
		var tv := Vector2(float(p.tx), float(p.ty))
		if mode == "slice" and i_pad < pad_targets.size():
			tv = Vector2(float(pad_targets[i_pad][0]), float(pad_targets[i_pad][1]))
		i_pad += 1
		if bounds.has_point(pv):
			pads.append({"x": pv.x, "y": pv.y, "tx": tv.x, "ty": tv.y, "anim": 0.0})
	rebuild_grid()
	build_nav()


func _crate_list(L: Dictionary) -> Array:
	## 原型：CRATE_Q 在原始坐标里四象限镜像，再按 SX/SY 缩放；外加下方中央的大礼箱。
	var T: Dictionary = L.get("protoTransform", {"SX": 0.7, "SY": 0.86, "OW": 7200, "OH": 3600})
	var sx := float(T.SX)
	var sy := float(T.SY)
	var ow := float(T.OW)
	var oh := float(T.OH)
	var out: Array = []
	for c in L.get("crates", []):
		var x := float(c[0])
		var y := float(c[1])
		for fx in [false, true]:
			for fy in [false, true]:
				var px := (ow - x if fx else x) * sx
				var py := (oh - y if fy else y) * sy
				out.append({"x": px, "y": py, "big": false})
	var bc: Dictionary = L.get("bigCrate", {})
	if not bc.is_empty():
		out.append({"x": float(bc.x), "y": float(bc.y), "big": true})
	return out


func _add_rect(x: float, y: float, w: float, h: float, kind: String, ht: float) -> Solid:
	var so := Solid.new()
	so.x = x; so.y = y; so.w = w; so.h = h; so.kind = kind; so.ht = ht
	so.update_aabb()
	solids.append(so)
	return so


func add_solid(so: Solid) -> void:
	so.update_aabb()
	solids.append(so)
	_grid_insert(so)


func rebuild_grid() -> void:
	_grid.clear()
	for so in solids:
		_grid_insert(so)


func _grid_insert(so: Solid) -> void:
	var cx0 := floori(so.x0 / GRID)
	var cx1 := floori(so.x1 / GRID)
	var cy0 := floori(so.y0 / GRID)
	var cy1 := floori(so.y1 / GRID)
	for cx in range(cx0, cx1 + 1):
		for cy in range(cy0, cy1 + 1):
			var k := cx * 4096 + cy
			if not _grid.has(k):
				_grid[k] = []
			(_grid[k] as Array).append(so)


func _near(x: float, y: float, r: float) -> Array:
	var cx0 := floori((x - r) / GRID)
	var cx1 := floori((x + r) / GRID)
	var cy0 := floori((y - r) / GRID)
	var cy1 := floori((y + r) / GRID)
	if cx0 == cx1 and cy0 == cy1:
		return _grid.get(cx0 * 4096 + cy0, [])
	var out: Array = []
	for cx in range(cx0, cx1 + 1):
		for cy in range(cy0, cy1 + 1):
			for so in _grid.get(cx * 4096 + cy, []):
				if not out.has(so):
					out.append(so)
	return out


# ---------------------------------------------------------------------------
# 碰撞查询
# ---------------------------------------------------------------------------

func overlaps_solid(x: float, y: float, r: float) -> bool:
	for so: Solid in _near(x, y, r):
		if so.off:
			continue
		if so.circle:
			var rr := so.r + r
			if SimUtil.d2(x, y, so.x, so.y) < rr * rr - 0.01:
				return true
		else:
			var cx := clampf(x, so.x, so.x + so.w)
			var cy := clampf(y, so.y, so.y + so.h)
			if SimUtil.d2(x, y, cx, cy) < r * r - 0.01:
				return true
	return false


func point_solid(x: float, y: float, r: float) -> Solid:
	for so: Solid in _near(x, y, r):
		if so.off:
			continue
		if so.circle:
			var rr := so.r + r
			if SimUtil.d2(x, y, so.x, so.y) < rr * rr:
				return so
		elif x > so.x - r and x < so.x + so.w + r and y > so.y - r and y < so.y + so.h + r:
			return so
	return null


func solid_at(x: float, y: float, r: float) -> Solid:
	for so: Solid in _near(x, y, r):
		if so.off:
			continue
		if so.circle:
			var rr := so.r + r
			if SimUtil.d2(x, y, so.x, so.y) < rr * rr:
				return so
		elif x + r > so.x and x - r < so.x + so.w and y + r > so.y and y - r < so.y + so.h:
			return so
	# 地图边界
	if x < min_x or y < min_y or x > max_x or y > max_y:
		return _edge
	return null


var _edge: Solid = _make_edge()


static func _make_edge() -> Solid:
	var s := Solid.new()
	s.kind = "wall"
	return s


func resolve_circle(o: Object, r: float) -> bool:
	## o 需要有 x、y 字段。把圆从障碍里推出去，返回是否发生了推动。
	var any := false
	for _it in 4:
		var moved := false
		for so: Solid in _near(o.x, o.y, r + 2.0):
			if so.off:
				continue
			if so.circle:
				var dx: float = o.x - so.x
				var dy: float = o.y - so.y
				var dd := dx * dx + dy * dy
				var rr := r + so.r
				if dd < rr * rr:
					var d := sqrt(dd)
					if d < 0.0001:
						d = 0.0001
					var p := rr - d
					o.x += dx / d * p
					o.y += dy / d * p
					moved = true
			else:
				var cx := clampf(o.x, so.x, so.x + so.w)
				var cy := clampf(o.y, so.y, so.y + so.h)
				var dx: float = o.x - cx
				var dy: float = o.y - cy
				var dd := dx * dx + dy * dy
				if dd < r * r:
					if dd > 1e-8:
						var d := sqrt(dd)
						var p := r - d
						o.x += dx / d * p
						o.y += dy / d * p
					else:
						var l: float = o.x - so.x
						var rg: float = so.x + so.w - o.x
						var t: float = o.y - so.y
						var b: float = so.y + so.h - o.y
						var m := minf(minf(l, rg), minf(t, b))
						if m == l:
							o.x = so.x - r
						elif m == rg:
							o.x = so.x + so.w + r
						elif m == t:
							o.y = so.y - r
						else:
							o.y = so.y + so.h + r
					moved = true
		# 边界
		if o.x < min_x + r:
			o.x = min_x + r; moved = true
		if o.x > max_x - r:
			o.x = max_x - r; moved = true
		if o.y < min_y + r:
			o.y = min_y + r; moved = true
		if o.y > max_y - r:
			o.y = max_y - r; moved = true
		if not moved:
			break
		any = true
	return any


func has_los(x1: float, y1: float, x2: float, y2: float) -> bool:
	var ax0 := minf(x1, x2)
	var ax1 := maxf(x1, x2)
	var ay0 := minf(y1, y2)
	var ay1 := maxf(y1, y2)
	for so in solids:
		if so.off:
			continue
		if so.x1 < ax0 or so.x0 > ax1 or so.y1 < ay0 or so.y0 > ay1:
			continue
		if so.circle:
			if SimUtil.seg_circ(x1, y1, x2, y2, so.x, so.y, so.r):
				return false
		elif SimUtil.seg_rect(x1, y1, x2, y2, so.x, so.y, so.w, so.h):
			return false
	return true


func raycast_len(x: float, y: float, dx: float, dy: float, max_len: float, step: float = 16.0) -> float:
	var l := 0.0
	while l < max_len and point_solid(x + dx * l, y + dy * l, 1.0) == null:
		l += step
	return minf(l, max_len)


# ---------------------------------------------------------------------------
# 寻路：格子 + 广度优先流场（原型 fieldTo / fieldDir）
# ---------------------------------------------------------------------------

func build_nav() -> void:
	nav_gc = ceili(width / NAV_CELL)
	nav_gr = ceili(height / NAV_CELL)
	nav_pass.resize(nav_gc * nav_gr)
	for j in nav_gr:
		for i in nav_gc:
			var x := (i + 0.5) * NAV_CELL
			var y := (j + 0.5) * NAV_CELL
			var ok := x > min_x and x < max_x and y > min_y and y < max_y and not overlaps_solid(x, y, NAV_CLEARANCE)
			nav_pass[j * nav_gc + i] = 1 if ok else 0
	_field_cache.clear()
	_field_order.clear()


func nav_patch(px: float, py: float, radius: float) -> void:
	var c0 := maxi(0, floori((px - radius) / NAV_CELL))
	var c1 := mini(nav_gc - 1, floori((px + radius) / NAV_CELL))
	var r0 := maxi(0, floori((py - radius) / NAV_CELL))
	var r1 := mini(nav_gr - 1, floori((py + radius) / NAV_CELL))
	for j in range(r0, r1 + 1):
		for i in range(c0, c1 + 1):
			var x := (i + 0.5) * NAV_CELL
			var y := (j + 0.5) * NAV_CELL
			var ok := x > min_x and x < max_x and y > min_y and y < max_y and not overlaps_solid(x, y, NAV_CLEARANCE)
			nav_pass[j * nav_gc + i] = 1 if ok else 0
	_field_cache.clear()
	_field_order.clear()


func cell_of(x: float, y: float) -> int:
	return clampi(floori(y / NAV_CELL), 0, nav_gr - 1) * nav_gc + clampi(floori(x / NAV_CELL), 0, nav_gc - 1)


func field_to(x: float, y: float) -> PackedInt32Array:
	var k := cell_of(x, y)
	var gc := nav_gc
	var gr := nav_gr
	if nav_pass[k] == 0:
		var ci := k % gc
		var cj := k / gc
		var best := -1
		var bd := 1 << 30
		for dj in range(-4, 5):
			for di in range(-4, 5):
				var i := ci + di
				var j := cj + dj
				if i < 0 or j < 0 or i >= gc or j >= gr:
					continue
				var kk := j * gc + i
				if nav_pass[kk] == 0:
					continue
				var dd := di * di + dj * dj
				if dd < bd:
					bd = dd
					best = kk
		if best < 0:
			return PackedInt32Array()
		k = best
	if _field_cache.has(k):
		return _field_cache[k]
	if _field_order.size() > 40:
		_field_cache.erase(_field_order.pop_front())
	var F := PackedInt32Array()
	F.resize(gc * gr)
	F.fill(-1)
	var Q := PackedInt32Array()
	Q.resize(gc * gr)
	var head := 0
	var tail := 0
	F[k] = 0
	Q[tail] = k
	tail += 1
	while head < tail:
		var c := Q[head]
		head += 1
		var i := c % gc
		var j := c / gc
		var dv := F[c] + 1
		for dj in range(-1, 2):
			for di in range(-1, 2):
				if di == 0 and dj == 0:
					continue
				var ni := i + di
				var nj := j + dj
				if ni < 0 or nj < 0 or ni >= gc or nj >= gr:
					continue
				var nk := nj * gc + ni
				if nav_pass[nk] == 0 or F[nk] >= 0:
					continue
				if di != 0 and dj != 0 and (nav_pass[j * gc + ni] == 0 or nav_pass[nj * gc + i] == 0):
					continue
				F[nk] = dv
				Q[tail] = nk
				tail += 1
	_field_cache[k] = F
	_field_order.append(k)
	return F


func field_dir(F: PackedInt32Array, x: float, y: float, tx: float, ty: float) -> Vector2:
	var dx := tx - x
	var dy := ty - y
	if not F.is_empty():
		var gc := nav_gc
		var gr := nav_gr
		var i := clampi(floori(x / NAV_CELL), 0, gc - 1)
		var j := clampi(floori(y / NAV_CELL), 0, gr - 1)
		var here := F[j * gc + i]
		var best := 32767 if here < 0 else here
		var bx := 0.0
		var by := 0.0
		var found := false
		for dj in range(-1, 2):
			for di in range(-1, 2):
				if di == 0 and dj == 0:
					continue
				var ni := i + di
				var nj := j + dj
				if ni < 0 or nj < 0 or ni >= gc or nj >= gr:
					continue
				var f := F[nj * gc + ni]
				if f < 0:
					continue
				if di != 0 and dj != 0 and (F[j * gc + ni] < 0 or F[nj * gc + i] < 0):
					continue
				if f < best:
					best = f
					bx = (ni + 0.5) * NAV_CELL
					by = (nj + 0.5) * NAV_CELL
					found = true
		if found and best > 1:
			dx = bx - x
			dy = by - y
	var l := sqrt(dx * dx + dy * dy)
	if l < 1e-6:
		return Vector2.ZERO
	return Vector2(dx / l, dy / l)
