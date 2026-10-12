class_name SimCards
extends RefCounted
## 升级卡：抽卡、卡面文字、应用、AI 选择。对应原型 n2c.js 的 rollChoices / choiceLabel / applyChoice / aiPick。
## 批次 1 的卡池范围由 rules.json 的 scope 控制；每次 rules.json cards.count 张（4 张），类别权重在 cards.weights。
## 道具卡：gad 新道具（只替换它所属的 Q / E 槽），gup 道具通用升级（冷却缩短 / 携带上限，同时作用于 Q 和 E）。卡面不显示等级数字。

const PK := ["a", "b", "c"]
const TYPE_COLOR := {"进化": "#ff9a3c", "强化": "#5fb0ff", "战术道具": "#c77dff", "强化道具": "#ffb347", "道具升级": "#e7a6ff", "天赋": "#ff6fd0", "宠物": "#5fd38a", "换武器": "#d9d4e2"}


static func _scope_weapons() -> Array:
	return Data.active_weapons()


static func _scope_abilities() -> Array:
	return Data.rule("scope.abilities", Data.abilities().keys())


static func roll(w: SimWorld, h: SimHamster) -> void:
	var C: Dictionary = w.R.cards
	var n_cards := int(C.get("count", 4))
	if h.talent_pend > 0 and bool(Data.rule("scope.talents", true)):
		var tp: Array = []
		for k in Data.talents().keys():
			if not h.tal.has(k):
				tp.append(k)
		var o: Array = []
		while o.size() < n_cards and not tp.is_empty():
			o.append({"t": "tal", "id": tp.pop_at(int(w.rnd() * tp.size()) % tp.size())})
		if not o.is_empty():
			h.choices = o
			return
		h.talent_pend = 0
	var out: Array = []
	var evs: Array = []
	# 起手武器（weapons.json 的 noEvo，目前是手枪）不出进化卡：升级都留给换武器和强化（2026-10-11 导演）
	var no_evo := bool(h.weapon().get("noEvo", false))
	for k in PK:
		if not no_evo and h.evo_lv(k) < int(Data.evolutions().get("maxLevel", 9)):
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
	var pick_weap := func() -> Variant:
		var ws: Array = []
		for id in _scope_weapons():
			if id != h.weapon_id:
				var taken := false
				for x in out:
					if x.t == "weap" and x.id == id:
						taken = true
				if not taken:
					ws.append(id)
		if ws.is_empty():
			return null
		return {"t": "weap", "id": ws[int(w.rnd() * ws.size()) % ws.size()]}
	# 新道具卡：Q / E 两个升级池里身上没装的（同一次不重复）
	var gads: Array = []
	if bool(Data.rule("scope.gadgetCards", true)):
		for slot in SimGadgets.SLOTS:
			for id in Data.gadget_pool(slot, "upgrade"):
				if id != String(h.gad[slot].id):
					gads.append(id)
	var pick_gad := func() -> Variant:
		if gads.is_empty():
			return null
		return {"t": "gad", "id": gads.pop_at(int(w.rnd() * gads.size()) % gads.size())}
	# 道具通用升级卡（冷却缩短 / 携带上限）：没满的
	var gups: Array = []
	var U: Dictionary = Data.gadgets().upgrades
	for uid in ["gcdx", "gcap"]:
		if int(h.gup.get(uid, 0)) < int(U[uid].max):
			gups.append(uid)
	var pick_gup := func() -> Variant:
		if gups.is_empty():
			return null
		return {"t": "gup", "id": gups.pop_at(int(w.rnd() * gups.size()) % gups.size())}
	var pick_pet := func() -> Variant:
		if not bool(Data.rule("scope.pets", true)):
			return null
		var ps: Array = []
		var pmax := int(w.R.pets.maxLevel)
		for id in Data.pets().keys():
			var lvl := 0
			for p in h.pet_list:
				if p.type == id:
					lvl = p.lvl
			var taken := out.any(func(x): return x.t == "pet" and x.id == id)
			if lvl < pmax and not taken:
				ps.append(id)
		if ps.is_empty():
			return null
		return {"t": "pet", "id": ps[int(w.rnd() * ps.size()) % ps.size()]}
	# 第 1 张：进化（手枪：换武器）；第 2 张：通用强化
	add.call(pick_weap.call() if no_evo else pick_evo.call())
	add.call(pick_gen.call([]))
	# 其余按类别权重抽（rules.json cards.weights + weaponSwap 阶段权重）
	var ev_tot := h.evo_total()
	var WS: Dictionary = C.weaponSwap
	var pw := float(WS.fresh) if (ev_tot == 0 and h.lvl < int(WS.freshLevel)) else (float(WS.early) if ev_tot < int(WS.earlyEvoTotal) else float(WS.late))
	if no_evo:
		pw = float(WS.get("noEvo", pw))
	var CW: Dictionary = C.weights
	var cats := {"evo": float(CW.evo), "abil": float(CW.abil), "vision": float(CW.get("vision", 0.0)), "gad": float(CW.gad), "gup": float(CW.gup), "pet": float(CW.pet), "weap": pw}
	var draw := func(cat: String) -> Variant:
		match cat:
			"evo": return pick_evo.call()
			"abil": return pick_gen.call([])
			"vision": return pick_gen.call(C.visionAbilities)
			"gad": return pick_gad.call()
			"gup": return pick_gup.call()
			"pet": return pick_pet.call()
			"weap": return pick_weap.call()
		return null
	var guard := 0
	while out.size() < n_cards and guard < 24:
		guard += 1
		var tot := 0.0
		for k in cats:
			tot += float(cats[k])
		if tot <= 0.0:
			break
		var r := w.rnd() * tot
		var cat := ""
		for k in cats:
			r -= float(cats[k])
			if r <= 0.0:
				cat = k
				break
		if cat.is_empty():
			cat = String(cats.keys().back())
		var before := out.size()
		add.call(draw.call(cat))
		if out.size() == before:
			cats[cat] = 0.0     # 这一类抽不出新卡了
	h.choices = out.slice(0, n_cards)
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
			# 每一级都有自己的效果（evolutions.json 的 lv）；第 9 级是质变
			var texts: Array = p.get("lv", [])
			var desc := String(texts[mini(lv, texts.size()) - 1]) if not texts.is_empty() else String(p.perLevel)
			if lv >= 9:
				desc = "质变：" + desc
			return {"type": "进化", "name": p.name, "badge": "质变" if lv >= 9 else "", "desc": desc, "path": i, "pathColor": Data.evolutions().pathColors[i], "weapon": h.weapon_id}
		"weap":
			var W := Data.weapon(c.id)
			return {"type": "换武器", "name": W.name, "badge": "换上", "desc": String(W.get("desc", "")) + "（进化清零）", "weapon": c.id}
		"gad":
			# 卡面标明是战术道具（Q）还是强化道具（E），换上只替换那个槽
			var G: Dictionary = Data.gadget(c.id)
			var slot := String(G.slot)
			var SL: Dictionary = Data.gadgets().slots[slot]
			var cur := String(Data.gadget(String(h.gad[slot].id)).get("name", ""))
			return {"type": String(SL.name), "name": G.name, "badge": "换 " + slot.to_upper(), "desc": "%s（替换 %s）" % [G.desc, cur], "slot": slot, "gadget": c.id}
		"gup":
			var U: Dictionary = Data.gadgets().upgrades[c.id]
			var n := int(h.gup.get(c.id, 0))
			var now := ""
			if n > 0:
				now = "（已 −%d%%）" % roundi(-100.0 * float(U.per) * n) if c.id == "gcdx" else "（已 +%d）" % (int(U.per) * n)
			return {"type": "道具升级", "name": U.name, "badge": "Q+E", "desc": String(U.desc) + now, "gup": c.id}
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
			# 右键技能：换枪后 2 秒内可用，上一把的技能效果清掉
			h.skill_cd = minf(h.skill_cd, 2.0)
			h.sk_free_t = 0.0
			h.sk_rate_t = 0.0
			h.sk_spin_t = 0.0
			h.sk_slash_t = 0.0
			h.sk_od_t = 0.0
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
			SimGadgets.equip(w, h, String(c.id))
		"gup":
			SimGadgets.add_upgrade(h, String(c.id))
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
			"gup": base = float(PW.gup)
			"gad": base = float(PW.gad)
			"pet": base = float(PW.pet)
			"weap": base = float(PW.weapFresh) if ev_tot == 0 else float(PW.weap)
		var wv := base + w.rnd() * float(PW.random)
		if wv > bw:
			bw = wv
			bi = i
	return bi
