class_name SimCards
extends RefCounted
## 升级卡：抽卡、卡面文字、应用、AI 选择。对应原型 n2c.js 的 rollChoices / choiceLabel / applyChoice / aiPick。
## 批次 1 的卡池范围由 rules.json 的 scope 控制。

const PK := ["a", "b", "c"]
const TYPE_COLOR := {"进化": "#ff9a3c", "强化": "#5fb0ff", "道具": "#c77dff", "天赋": "#ff6fd0", "宠物": "#5fd38a", "换武器": "#d9d4e2"}


static func _scope_weapons() -> Array:
	return Data.rule("scope.weapons", Data.weapons().keys())


static func _scope_abilities() -> Array:
	return Data.rule("scope.abilities", Data.abilities().keys())


static func roll(w: SimWorld, h: SimHamster) -> void:
	var C: Dictionary = w.R.cards
	if h.talent_pend > 0 and bool(Data.rule("scope.talents", true)):
		var tp: Array = []
		for k in Data.talents().keys():
			if not h.tal.has(k):
				tp.append(k)
		var o: Array = []
		while o.size() < 3 and not tp.is_empty():
			o.append({"t": "tal", "id": tp.pop_at(int(w.rnd() * tp.size()) % tp.size())})
		if not o.is_empty():
			h.choices = o
			return
		h.talent_pend = 0
	var out: Array = []
	var evs: Array = []
	for k in PK:
		if h.evo_lv(k) < int(Data.evolutions().get("maxLevel", 9)):
			evs.append({"t": "evo", "k": k, "id": h.weapon_id})
	var gens: Array = []
	var A := Data.abilities()
	for id in _scope_abilities():
		if A.has(id) and int(h.ab.get(id, 0)) < int(A[id].max):
			gens.append(id)
	var pick_evo := func() -> Variant:
		if evs.is_empty():
			return null
		var s := 0.0
		var ws: Array = []
		for e in evs:
			var v := 1.0 + float(C.evoWeightPerLevel) * h.evo_lv(e.k)
			s += v
			ws.append(v)
		var r := w.rnd() * s
		for i in evs.size():
			r -= float(ws[i])
			if r <= 0.0:
				return evs.pop_at(i)
		return evs.pop_back()
	var pick_gen := func(pref: Array) -> Variant:
		var pool: Array = gens if pref.is_empty() else gens.filter(func(g): return pref.has(g))
		if pool.is_empty():
			return null
		var id: String = pool[int(w.rnd() * pool.size()) % pool.size()]
		gens.erase(id)
		return {"t": "abil", "id": id}
	var add := func(c: Variant) -> void:
		if c == null:
			return
		for x in out:
			if x.t == c.t and x.id == c.id and x.get("k", "") == c.get("k", ""):
				return
		out.append(c)
	add.call(pick_evo.call())
	add.call(pick_gen.call([]))
	var ev_tot := h.evo_total()
	var WS: Dictionary = C.weaponSwap
	var pw := float(WS.fresh) if (ev_tot == 0 and h.lvl < int(WS.freshLevel)) else (float(WS.early) if ev_tot < int(WS.earlyEvoTotal) else float(WS.late))
	var B: Dictionary = C.branches
	var r := w.rnd()
	var gad_on := bool(Data.rule("scope.gadgetCards", true))
	var pets_on := bool(Data.rule("scope.pets", true))
	var third: Variant = null
	if r < pw:
		var ws: Array = []
		for id in _scope_weapons():
			if id != h.weapon_id:
				ws.append(id)
		if not ws.is_empty():
			third = {"t": "weap", "id": ws[int(w.rnd() * ws.size()) % ws.size()]}
	elif r < pw + float(B.gadget):
		if gad_on:
			if w.rnd() < float(C.gadgetUpgradeChance) and int(h.gadget.lvl) < 4:
				third = {"t": "glvl", "id": h.gadget.id}
			else:
				var gs: Array = []
				for id in Data.rule("scope.gadgets", Data.gadgets().keys()):
					if id != h.gadget.id:
						gs.append(id)
				third = {"t": "gad", "id": gs[int(w.rnd() * gs.size()) % gs.size()]}
	elif r < pw + float(B.gadget) + float(B.pet):
		if pets_on:
			var ps: Array = []
			var pmax := int(w.R.pets.maxLevel)
			for id in Data.pets().keys():
				var lvl := 0
				for p in h.pet_list:
					if p.type == id:
						lvl = p.lvl
				if lvl < pmax:
					ps.append(id)
			if not ps.is_empty():
				third = {"t": "pet", "id": ps[int(w.rnd() * ps.size()) % ps.size()]}
	elif r < pw + float(B.gadget) + float(B.pet) + float(B.evo):
		third = pick_evo.call()
	else:
		third = pick_gen.call(C.visionAbilities)
		if third == null:
			third = pick_gen.call([])
	add.call(third)
	while out.size() < 3:
		var c: Variant = pick_evo.call()
		if c == null:
			c = pick_gen.call([])
		if c == null:
			break
		add.call(c)
	h.choices = out.slice(0, 3)
	w.emit({"t": "choices", "id": h.id})


static func label(h: SimHamster, c: Dictionary) -> Dictionary:
	## 卡面：类型、名字、角标（不显示等级数字：只有“新”“质变”“换上”）、描述、进化路线色
	match String(c.t):
		"tal":
			var T: Dictionary = Data.talents()[c.id]
			return {"type": "天赋", "name": T.name, "badge": "", "desc": T.desc}
		"evo":
			var i := PK.find(c.k)
			var p: Dictionary = Data.evolutions().paths[h.weapon_id][i]
			var lv := h.evo_lv(c.k) + 1
			var desc := String(p.perLevel)
			if lv >= 9:
				desc = "质变：" + String(p.lv9)
			elif lv == 3:
				desc = String(p.perLevel) + "；" + String(p.lv3)
			elif lv == 6:
				desc = String(p.perLevel) + "；" + String(p.lv6)
			return {"type": "进化", "name": p.name, "badge": "质变" if lv >= 9 else "", "desc": desc, "path": i, "pathColor": Data.evolutions().pathColors[i], "weapon": h.weapon_id}
		"weap":
			var W := Data.weapon(c.id)
			return {"type": "换武器", "name": W.name, "badge": "换上", "desc": String(W.get("desc", "")) + "（进化清零）", "weapon": c.id}
		"gad":
			var G: Dictionary = Data.gadgets()[c.id]
			return {"type": "道具", "name": G.name, "badge": "换上", "desc": G.desc}
		"glvl":
			var G2: Dictionary = Data.gadgets()[c.id]
			return {"type": "道具", "name": G2.name, "badge": "", "desc": "冷却更短，效果更强"}
		"abil":
			var A: Dictionary = Data.abilities()[c.id]
			var l := int(h.ab.get(c.id, 0)) + 1
			return {"type": "强化", "name": A.name, "badge": "新" if l == 1 else "", "desc": A.desc, "abil": c.id}
		_:
			var P: Dictionary = Data.pets()[c.id]
			var has := false
			for p in h.pet_list:
				if p.type == c.id:
					has = true
			return {"type": "宠物", "name": P.name, "badge": "" if has else "新", "desc": P.desc if not has else "升级：伤害更高、攻击更快", "pet": c.id}


static func apply(w: SimWorld, h: SimHamster, i: int) -> void:
	if i < 0 or i >= h.choices.size():
		return
	var c: Dictionary = h.choices[i]
	var lab := label(h, c)
	match String(c.t):
		"evo":
			if h.evo_lv(c.k) < int(Data.evolutions().get("maxLevel", 9)):
				h.evo[c.k] = h.evo_lv(c.k) + 1
		"weap":
			h.weapon_id = String(c.id)
			h.evo = {"a": 0, "b": 0, "c": 0}
			h.ramp = 0.0
			h.burst_n = 0
			h.spin = 0.0
			h.charge = 0.0
			h.ch_hold = 0.0
			h.beams = []
			h.marks.clear()
			h.mark_hold = 0.0
			h.mark_acc = 0.0
			h.flame_t = 0.0
			h.fire_cd = 0.0    # 换上新枪立刻能开火（不继承旧枪的射击冷却）
		"gad":
			h.gadget = {"id": c.id, "lvl": 1, "cd": 0.0}
			h.beacon = {}
		"glvl":
			h.gadget.lvl = mini(int(w.R.gadgets.maxLevel), int(h.gadget.lvl) + 1)
		"tal":
			h.tal[c.id] = true
			h.talent_pend = maxi(0, h.talent_pend - 1)
		"abil":
			h.ab[c.id] = int(h.ab.get(c.id, 0)) + 1
		"pet":
			var found: SimPet = null
			for p in h.pet_list:
				if p.type == c.id:
					found = p
			if found != null:
				found.lvl += 1
			else:
				h.pet_list.append(SimMobs.make_pet(w, String(c.id), h))
	h.pending = maxi(0, h.pending - 1)
	h.choices = []
	SimHamsterLogic.calc_stats(h)
	if c.t == "tal" and c.id == "aegis":
		h.shield = int(h.st.shield)
	if c.t == "weap":
		h.ammo = SimWeapons.mag_size(h)
		h.reload_t = 0.0
		h.bloom = 0.0
	elif c.t == "evo":
		var m := SimWeapons.mag_size(h)
		h.ammo = mini(m, h.ammo + ceili(m * float(w.R.hamster.evoAmmoRefill)))
	var col: String = lab.get("pathColor", "#ffd166")
	var prefix := (String(h.weapon().name) + "·") if lab.type == "进化" else ""
	w.toast(h, "获得：%s%s%s" % [prefix, lab.name, "（质变）" if lab.badge == "质变" else ""], col, 1.6)
	w.emit({"t": "picked", "id": h.id, "card": c, "label": lab})
	if h.pending > 0:
		roll(w, h)


static func ai_pick(w: SimWorld, h: SimHamster) -> int:
	var PW: Dictionary = w.R.ai.pickWeights
	var bi := 0
	var bw := -1.0
	var ev_tot := h.evo_total()
	for i in h.choices.size():
		var c: Dictionary = h.choices[i]
		var base := 1.0
		match String(c.t):
			"evo": base = float(PW.evo)
			"abil": base = float(PW.abil)
			"glvl": base = float(PW.glvl)
			"gad": base = float(PW.gad)
			"pet": base = float(PW.pet)
			"weap": base = float(PW.weapFresh) if ev_tot == 0 else float(PW.weap)
		var wv := base + w.rnd() * float(PW.random)
		if wv > bw:
			bw = wv
			bi = i
	return bi
