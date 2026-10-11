class_name NetSnapshot
extends RefCounted



const GROUPS: = {"hams": preload("res://scripts/sim/sim_hamster.gd"), "minions": preload("res://scripts/sim/sim_minion.gd"), "structs": preload("res://scripts/sim/sim_structure.gd"),
	"props": preload("res://scripts/sim/sim_prop.gd"), "crates": preload("res://scripts/sim/sim_crate.gd"), "bullets": preload("res://scripts/sim/sim_bullet.gd"), "lobs": preload("res://scripts/sim/sim_lob.gd"),
	"items": preload("res://scripts/sim/sim_item.gd"), "mobs": preload("res://scripts/sim/sim_mob.gd"), "pets": preload("res://scripts/sim/sim_pet.gd"), "decoys": preload("res://scripts/sim/sim_decoy.gd")}
const FIELDS: = ["t", "tick", "over", "winner", "end_t", "sudden", "min_mul", "wave_n",
	"boss", "boss_next", "boom", "feed", "vis", "noises", "fires", "mines", "smokes", "flares", "zones", "corrs", "camps"]
const SKIP: = ["ai", "inp", "solid", "in_solid", "px", "py"]
static var _fields: = {}


static func fields(o: Object) -> Array:
	var script: String = (o.get_script() as Script).resource_path
	if not _fields.has(script):
		var names: Array = []
		for p in o.get_property_list():
			if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and not String(p.name) in SKIP:
				names.append(String(p.name))
		_fields[script] = names
	return _fields[script]


static func encode(v: Variant) -> Variant:
	if v is Object:
		return {"$ref": int(v.get("id"))} if v != null else null
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(encode(x))
		return a
	if v is Dictionary:
		var d: = {}
		for k in v:
			d[k] = encode(v[k])
		return d
	return v


static func decode(v: Variant, refs: Dictionary) -> Variant:
	if v is Dictionary:
		if v.has("$ref"):
			return refs.get(int(v["$ref"]))
		var d: = {}
		for k in v:
			d[k] = decode(v[k], refs)
		return d
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(decode(x, refs))
		return a
	return v


static func capture(w: SimWorld) -> Dictionary:
	var out: = {"state": {}, "groups": {}, "pads": []}
	for k in FIELDS:
		out.state[k] = encode(w.get(k))
	for group in GROUPS:
		var arr: Array = []
		for o in w.get(group):
			var d: = {}
			for k in fields(o):
				d[k] = encode(o.get(k))
			arr.append(d)
		out.groups[group] = arr
	for pad in w.map.pads:
		out.pads.append(float(pad.anim))
	return out


static func baseline_index(packet: Dictionary) -> Dictionary:
	var out: = {"state": packet.state, "pads": packet.pads, "groups": {}, "digest": var_to_bytes(packet).hex_encode().sha256_text()}
	for group in GROUPS:
		var rows: = {}
		for row: Dictionary in packet.groups[group]:
			rows[int(row.id)] = row
		out.groups[group] = rows
	return out


static func delta(packet: Dictionary, baseline: Dictionary) -> Dictionary:


	var out: = {"baseline": baseline.digest, "state": {}, "groups": {}, "pads": packet.pads}
	for key in packet.state:
		if packet.state[key] != baseline.state.get(key):
			out.state[key] = packet.state[key]
	for group in GROUPS:
		var rows: Array = []
		for row: Dictionary in packet.groups[group]:
			var original: Dictionary = baseline.groups[group].get(int(row.id), {})
			var changes: = {"id": row.id}
			for key in row:
				if key != "id" and ( not original.has(key) or row[key] != original[key]):
					changes[key] = row[key]
			rows.append(changes)
		out.groups[group] = rows
	for key in ["input_ack", "action_ack"]:
		if packet.has(key):
			out[key] = packet[key]
	return out


static func expand_delta(packet: Dictionary, baseline: Dictionary) -> Dictionary:
	if packet.get("baseline", "") != baseline.get("digest", "invalid") or not packet.get("state") is Dictionary or not packet.get("groups") is Dictionary:
		return {}
	var out: = {"state": baseline.state.duplicate(), "groups": {}, "pads": packet.get("pads", baseline.pads)}
	out.state.merge(packet.state, true)
	for group in GROUPS:
		if not packet.groups.get(group) is Array:
			return {}
		var rows: Array = []
		for row: Variant in packet.groups[group]:
			if not row is Dictionary or not row.has("id"):
				return {}
			var original: Dictionary = baseline.groups[group].get(int(row.id), {})
			var expanded: = original.duplicate()
			expanded.merge(row, true)
			rows.append(expanded)
		out.groups[group] = rows
	for key in ["input_ack", "action_ack"]:
		if packet.has(key):
			out[key] = packet[key]
	return out


static func apply(w: SimWorld, packet: Dictionary) -> bool:
	if not packet.has("state") or not packet.has("groups") or int(packet.state.get("tick", -1)) <= w.tick:
		return false
	var refs: = {}

	for group in GROUPS:
		var existing: = {}
		for o in w.get(group):
			existing[o.id] = o
		var list: Array = w.get(group)
		var next: Array = []
		for row: Dictionary in packet.groups.get(group, []):
			var id: = int(row.id)
			var o: Object = existing.get(id)
			if o == null:
				o = GROUPS[group].new()
				o.set("id", id)
				if row.has("x"):
					o.set("x", row.x)
					o.set("y", row.y)
			next.append(o)
			refs[id] = o

		for o in list:
			if not o in next:
				SimLifecycle.release(o)
		list.assign(next)
	for group in GROUPS:
		for row: Dictionary in packet.groups.get(group, []):
			var o: Object = refs[int(row.id)]
			var names: = fields(o)
			if "x" in names and "y" in names and not o is SimLob and not o is SimItem:
				o.set("px", o.get("x"))
				o.set("py", o.get("y"))
			for key in row:
				if key in names:
					o.set(key, decode(row[key], refs))
	for k in FIELDS:
		if packet.state.has(k):
			w.set(k, decode(packet.state[k], refs))

	for prop: SimProp in w.props:
		if prop.solid != null:
			prop.solid.off = prop.dead
	w.entities.clear()
	for o in refs.values():
		if o is SimEntity:
			w.entities[o.id] = o
	for i in mini(w.map.pads.size(), packet.get("pads", []).size()):
		w.map.pads[i].anim = float(packet.pads[i])
	return true


static func compress(packet: Dictionary) -> PackedByteArray:
	var raw: = var_to_bytes(packet)
	var out: = PackedByteArray()
	out.resize(4)
	out.encode_u32(0, raw.size())
	out.append_array(raw.compress(FileAccess.COMPRESSION_FASTLZ))
	return out


static func decompress(blob: PackedByteArray) -> Dictionary:
	if blob.size() < 5:
		return {}
	var size: = int(blob.decode_u32(0))
	if size <= 0 or size > int(Data.load_json("network").maxSnapshotBytes):
		return {}
	var raw: = blob.slice(4).decompress(size, FileAccess.COMPRESSION_FASTLZ)
	if raw.size() != size:
		return {}
	var result: Variant = bytes_to_var(raw)
	return result if result is Dictionary else {}
