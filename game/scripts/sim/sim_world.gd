class_name SimWorld
extends RefCounted
## 一局对战的完整逻辑状态（不依赖任何渲染节点，headless 可跑完整局）。
## 固定 60Hz 逻辑帧，所有随机数来自带种子的 rng。表现层通过 events 和实体数组读取状态。
## 对应原型 n2.js / n2c.js 的 update / setupWorld 及其调用的系统。

signal match_over(winner: String)

const TEAMS := ["blue", "red"]
const ENEMY := {"blue": "red", "red": "blue"}
const HC := 128.0

var rng := RandomNumberGenerator.new()
var seed_value := 1
var t := 0.0
var tick := 0
var map := SimMap.new()
var mode := "slice"
var R: Dictionary = {}

var hams: Array[SimHamster] = []
var minions: Array[SimMinion] = []
var structs: Array[SimStructure] = []
var props: Array[SimProp] = []
var crates: Array[SimCrate] = []
var bullets: Array[SimBullet] = []
var lobs: Array[SimLob] = []
var items: Array[SimItem] = []
var fires: Array = []            # {x, y, r, t, life, team, owner, dps, tick}
var noises: Array = []           # {x, y, type, loud, team, src, t, life}
var events: Array = []           # 给表现层的事件
var feed: Array = []             # 击杀播报 {text, color, t}
var crate_spots: Array = []      # {x, y, big, resp, cur}
var entities := {}               # id -> SimEntity
var vis := {"blue": {}, "red": {}}
var vis_t := 0.0
var spawn_q: Array = []
var wave_next := 15.0
var wave_n := 0
var over := false
var winner := ""
var end_t := 0.0
var sudden := false
var min_mul := 1.0
var uid := 1
var shield_turrets := 3
var errors := 0
var _hash := {}


# ---------------------------------------------------------------------------
# 建局
# ---------------------------------------------------------------------------

func setup(cfg: Dictionary) -> void:
	## cfg: {mode: "slice"/"full", seed: int, players: [{team, ctl, name, skin}], ai: {blue: n, red: n}, weapons: {name: id}}
	R = Data.rules()
	seed_value = int(cfg.get("seed", 1))
	rng.seed = seed_value
	mode = String(cfg.get("mode", "slice"))
	map.build(mode)
	t = 0.0
	tick = 0
	uid = 1
	hams.clear(); minions.clear(); structs.clear(); props.clear(); crates.clear()
	bullets.clear(); lobs.clear(); items.clear(); fires.clear(); noises.clear(); events.clear(); feed.clear()
	entities.clear()
	vis = {"blue": {}, "red": {}}
	spawn_q.clear()
	wave_next = float(Data.progression().get("firstWave", 15))
	over = false
	winner = ""
	sudden = false
	min_mul = 1.0
	shield_turrets = int(Data.rule("match.slice.shieldTurrets", 1)) if mode == "slice" else 3
	for team in TEAMS:
		_add_struct("base", team, map.base_pos[team])
		for p in map.turret_pos[team]:
			_add_struct("turret", team, p)
	# 物件
	for spot in map.prop_spots:
		_add_prop(String(spot.kind), float(spot.x), float(spot.y))
	crate_spots.clear()
	for c in map.crate_spots:
		var C: Dictionary = R.crates.big if c.big else R.crates.small
		var first: Variant = C.first
		var resp := float(first) if not (first is Array) else rand(float(first[0]), float(first[1]))
		crate_spots.append({"x": float(c.x), "y": float(c.y), "big": bool(c.big), "resp": resp, "cur": null})
	# 仓鼠
	var idx := 0
	var names_used := {}
	for p: Dictionary in cfg.get("players", []):
		var h := _make_ham(String(p.get("team", "blue")), String(p.get("ctl", "player")), String(p.get("name", "玩家")), idx, String(p.get("skin", "gold")))
		if p.has("weapon"):
			h.weapon_id = String(p.weapon)
			h.ammo = SimWeapons.mag_size(h)
		idx += 1
		names_used[h.name] = true
	var ai_names := ["豆豆", "团子", "花卷", "布丁", "毛毛", "球球", "糯米", "芝麻", "可可", "饭团", "奶糖", "栗子"]
	var ai_cfg: Dictionary = cfg.get("ai", {"blue": 2, "red": 3})
	var skin_ids := Data.skin_ids()
	var forced: Dictionary = cfg.get("ai_weapons", {})
	for team in TEAMS:
		for i in int(ai_cfg.get(team, 0)):
			var nm: String = ai_names[(idx * 7 + i) % ai_names.size()]
			while names_used.has(nm):
				nm = nm + "2"
			names_used[nm] = true
			var h := _make_ham(team, "ai", nm, idx, String(skin_ids[rng.randi() % skin_ids.size()]))
			if forced.has(team):
				var wl: Array = forced[team]
				h.weapon_id = String(wl[i % wl.size()])
				h.ammo = SimWeapons.mag_size(h)
			idx += 1
	_compute_vis()


func _new_id() -> int:
	uid += 1
	return uid


func _register(e: Object) -> void:
	entities[e.id] = e


func _add_struct(kind: String, team: String, pos: Vector2) -> SimStructure:
	var D: Dictionary = R.structure[kind]
	var s := SimStructure.new()
	s.id = _new_id()
	s.kind = kind
	s.team = team
	s.x = pos.x; s.y = pos.y; s.px = s.x; s.py = s.y
	s.r = float(D.r)
	s.hp = float(D.hp); s.max_hp = s.hp
	if mode == "slice":
		# 切片只有一条兵线、一座炮台，推进压力比全图小得多：建筑血量按比例缩小，否则一局打不完
		s.hp *= float(Data.rule("match.slice.structHpMul.%s" % kind, 1.0))
		s.max_hp = s.hp
	s.range_ = float(D.range)
	s.dmg = float(D.dmg)
	s.cd_max = float(D.cd)
	s.cd = rand(0.5, 1.0)
	s.muzzle_h = float(D.muzzleH)
	s.alt_off = float(D.alt)
	s.aim = 0.0 if team == "blue" else PI
	s.shielded = kind == "base"
	structs.append(s)
	_register(s)
	return s


func _add_prop(kind: String, x: float, y: float) -> SimProp:
	var D: Dictionary = R.props[kind]
	var p := SimProp.new()
	p.id = _new_id()
	p.kind = kind
	p.is_prop = true
	p.x = x; p.y = y; p.px = x; p.py = y
	p.r = float(D.r)
	p.hp = float(D.hp); p.max_hp = p.hp
	p.ht = float(D.ht)
	p.rot = fmod(x * 0.013 + y * 0.007, TAU)
	var so := SimMap.Solid.new()
	so.kind = "p" + kind
	so.ht = p.ht
	so.prop = p
	if kind == "box":
		var hf := float(D.half)
		so.x = x - hf; so.y = y - hf; so.w = hf * 2.0; so.h = hf * 2.0
	else:
		so.circle = true
		so.x = x; so.y = y; so.r = p.r
	p.solid = so
	map.add_solid(so)
	map.nav_patch(x, y, float(R.props.navPatch))
	props.append(p)
	_register(p)
	return p


func _make_ham(team: String, ctl: String, name: String, idx: int, skin: String) -> SimHamster:
	var h := SimHamster.new()
	h.id = _new_id()
	h.kind = "ham"
	h.team = team
	h.ctl = ctl
	h.name = name
	h.idx = idx
	h.skin = skin
	h.aim = 0.0 if team == "blue" else PI
	h.xp_next = Data.xp_need(1)
	h.gadget = {"id": "frag", "lvl": 1, "cd": 2.0}
	if ctl == "ai":
		h.ai = SimHamster.AiState.new()
		var lanes := map.lanes.keys()
		h.ai.lane = String(lanes[idx % lanes.size()]) if not lanes.is_empty() else "mid"
		h.ai.dash_t = rand(1.0, 3.0)
	SimHamsterLogic.calc_stats(h)
	h.hp = h.max_hp
	h.ammo = SimWeapons.mag_size(h)
	SimHamsterLogic.place_at_base(self, h)
	h.inp.aim = h.aim
	hams.append(h)
	_register(h)
	return h


# ---------------------------------------------------------------------------
# 随机数（全部经过这里，保证同种子可复现）
# ---------------------------------------------------------------------------

func rnd() -> float:
	return rng.randf()


func rand(a: float, b: float) -> float:
	return a + rng.randf() * (b - a)


func rand_int(a: int, b: int) -> int:
	return a + int(floor(rng.randf() * float(b - a + 1)))


# ---------------------------------------------------------------------------
# 事件
# ---------------------------------------------------------------------------

func emit(ev: Dictionary) -> void:
	if events.size() < 4000:
		events.append(ev)


func drain_events() -> Array:
	var out := events
	events = []
	return out


func dispose() -> void:
	## 断开实体之间的互相引用（RefCounted 循环引用不会自动释放），一局结束 / 退出时调用
	var all: Array = []
	all.append_array(hams); all.append_array(minions); all.append_array(structs); all.append_array(props); all.append_array(crates)
	all.append_array(bullets); all.append_array(lobs); all.append_array(items); all.append_array(entities.values())
	for e in all:
		if e is SimEntity:
			(e as SimEntity).burn_by = null
		if e is SimHamster:
			var h := e as SimHamster
			if h.ai != null:
				h.ai.target = null
			h.dash_hit.clear()
		elif e is SimMinion:
			(e as SimMinion).target = null
		elif e is SimStructure:
			(e as SimStructure).target = null
			(e as SimStructure).owner = null
		elif e is SimProp:
			(e as SimProp).solid = null
		elif e is SimBullet:
			(e as SimBullet).by = null
			(e as SimBullet).owner = null
			(e as SimBullet).in_solid = null
		elif e is SimLob:
			(e as SimLob).owner = null
	for so in map.solids:
		so.prop = null
	hams.clear(); minions.clear(); structs.clear(); props.clear(); crates.clear()
	bullets.clear(); lobs.clear(); items.clear(); fires.clear(); noises.clear(); events.clear()
	entities.clear(); _hash.clear(); spawn_q.clear(); crate_spots.clear()


func toast(h: SimHamster, text: String, color: String = "#ffffff", dur: float = 2.0) -> void:
	emit({"t": "toast", "id": h.id if h != null else -1, "text": text, "color": color, "dur": dur})


func toast_all(text: String, color: String = "#ffffff", dur: float = 2.4) -> void:
	emit({"t": "toast", "id": -1, "text": text, "color": color, "dur": dur})


func add_feed(text: String, color: String) -> void:
	feed.append({"text": text, "color": color, "t": 0.0})
	if feed.size() > 5:
		feed.pop_front()
	emit({"t": "feed", "text": text, "color": color})


# ---------------------------------------------------------------------------
# 主循环
# ---------------------------------------------------------------------------

func step(dt: float) -> void:
	tick += 1
	t += dt
	for h in hams:
		h.save_prev()
	for m in minions:
		m.save_prev()
	if not over:
		if t >= wave_next:
			wave_next += float(Data.progression().get("waveInterval", 30))
			_spawn_wave()
			if wave_n == 1:
				toast_all("第一波小兵出发了", "#cfe8ff", 2.0)
		while not spawn_q.is_empty() and float(spawn_q[0].t) <= t:
			var q: Dictionary = spawn_q.pop_front()
			if minions.size() < int(R.minion.maxMinions):
				_spawn_minion(String(q.team), String(q.lane))
		for s in crate_spots:
			if s.cur == null and t >= float(s.resp):
				var c := _make_crate(s)
				s.cur = c
		var sd: Dictionary = R.combat.sudden
		var sd_time := float(Data.rule("match.slice.suddenTime", sd.time)) if mode == "slice" else float(sd.time)
		if not sudden and t >= sd_time:
			sudden = true
			min_mul = float(sd.minionMul)
			toast_all("加速决战！建筑受到双倍伤害", "#ff8a7a", 3.5)
	_hash_all()
	vis_t -= dt
	if vis_t <= 0.0:
		vis_t = float(R.vision.interval)
		_compute_vis()
	for h in hams:
		if h.ctl == "ai":
			SimAI.think(self, h, dt)
	for h in hams:
		SimHamsterLogic.update(self, h, dt)
	for m in minions:
		_upd_minion(m, dt)
	for s in structs:
		_upd_struct(s, dt)
	_upd_pads(dt)
	_upd_props(dt)
	_separate()
	_upd_bullets(dt)
	_upd_lobs(dt)
	_upd_fires(dt)
	_upd_items(dt)
	_upd_noises(dt)
	for f in feed:
		f.t += dt
	while not feed.is_empty() and float(feed[0].t) > 6.0:
		feed.pop_front()
	# 清理
	if minions.any(func(m): return m.dead):
		var keep: Array[SimMinion] = []
		for m in minions:
			if m.dead:
				entities.erase(m.id)
			else:
				keep.append(m)
		minions = keep
	if crates.any(func(c): return c.dead):
		var keep2: Array[SimCrate] = []
		for c in crates:
			if c.dead:
				entities.erase(c.id)
			else:
				keep2.append(c)
		crates = keep2
	if over:
		end_t -= dt


func is_over() -> bool:
	return over


# ---------------------------------------------------------------------------
# 空间哈希
# ---------------------------------------------------------------------------

func _hash_add(e: SimEntity) -> void:
	var r := e.r
	var x0 := floori((e.x - r) / HC)
	var x1 := floori((e.x + r) / HC)
	var y0 := floori((e.y - r) / HC)
	var y1 := floori((e.y + r) / HC)
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var k := cx * 4096 + cy
			if not _hash.has(k):
				_hash[k] = []
			(_hash[k] as Array).append(e)


func _hash_all() -> void:
	_hash.clear()
	for p in props:
		if not p.dead:
			_hash_add(p)
	for h in hams:
		if h.alive:
			_hash_add(h)
	for m in minions:
		if not m.dead:
			_hash_add(m)
	for s in structs:
		if not s.dead:
			_hash_add(s)
	for c in crates:
		if not c.dead:
			_hash_add(c)


func hash_at(x: float, y: float) -> Array:
	return _hash.get(floori(x / HC) * 4096 + floori(y / HC), [])


func hash_range(x: float, y: float, r: float) -> Array:
	var x0 := floori((x - r) / HC)
	var x1 := floori((x + r) / HC)
	var y0 := floori((y - r) / HC)
	var y1 := floori((y + r) / HC)
	var seen := {}
	var out: Array = []
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			for e in _hash.get(cx * 4096 + cy, []):
				if seen.has(e.id):
					continue
				seen[e.id] = true
				out.append(e)
	return out


func can_hit(team: String, e: SimEntity) -> bool:
	if e.dead:
		return false
	if e is SimHamster and not (e as SimHamster).alive:
		return false
	if team == "neutral":
		return e.kind == "ham" or e.kind == "minion"
	return e.team != team


func nearest_foe(team: String, x: float, y: float, rr: float) -> SimEntity:
	var best: SimEntity = null
	var bd := rr * rr
	for e: SimEntity in hash_range(x, y, rr):
		if not can_hit(team, e) or e.is_prop or e.kind == "crate":
			continue
		if e.kind == "base" and e.shielded:
			continue
		var d := SimUtil.d2(x, y, e.x, e.y)
		if d < bd:
			bd = d
			best = e
	return best


func all_targets() -> Array:
	var out: Array = []
	for h in hams:
		if h.alive:
			out.append(h)
	for m in minions:
		if not m.dead:
			out.append(m)
	return out


func is_visible_to(team: String, e: SimEntity) -> bool:
	return e.team == team or vis[team].has(e.id)


func ham_by_id(id: int) -> SimHamster:
	var e: Variant = entities.get(id)
	return e as SimHamster if e is SimHamster else null


# ---------------------------------------------------------------------------
# 状态效果
# ---------------------------------------------------------------------------

func stun_e(e: SimEntity, d: float) -> void:
	if e is SimHamster:
		var h := e as SimHamster
		h.stun_t = maxf(h.stun_t, d * float(Data.progression().get("ccOnPlayers", 0.5)))
	elif e.kind != "base" and e.kind != "turret" and not e.is_prop:
		e.stun = maxf(e.stun, d)


func slow_e(e: SimEntity, d: float) -> void:
	var k := float(Data.progression().get("ccOnPlayers", 0.5)) if e is SimHamster else 1.0
	e.slow_t = maxf(e.slow_t, d * k)


func mark_e(e: SimEntity, team: String, d: float) -> void:
	if e == null or e.team == team:
		return
	e.mark_team = team
	e.mark_until = maxf(e.mark_until, t + d)


func knock(e: SimEntity, dx: float, dy: float, kb: float) -> void:
	if kb <= 0.0 or e.kind == "base" or e.kind == "turret" or e.kind == "crate" or e.is_prop:
		return
	if e is SimHamster:
		var h := e as SimHamster
		if h.tal.has("giant"):
			return
	var l := sqrt(dx * dx + dy * dy)
	if l < 1e-6:
		return
	if e is SimHamster:
		e.vx += dx / l * kb
		e.vy += dy / l * kb
	else:
		var m := float(R.combat.bossKnockMul) if e.kind == "boss" else 1.0
		e.kx += dx / l * kb * m
		e.ky += dy / l * kb * m


func burn_tick(e: SimEntity, dt: float) -> void:
	if e.burn_t <= 0.0:
		return
	e.burn_t -= dt
	e.burn_acc += dt
	if e.burn_acc >= float(R.combat.burnTick):
		e.burn_acc = 0.0
		var team := e.burn_by.team if e.burn_by != null else "neutral"
		deal_dmg(e, float(R.combat.burnDmg) * e.burn_k, {"team": team, "owner": e.burn_by as SimHamster if e.burn_by is SimHamster else null, "x": e.x, "y": e.y}, true)


# ---------------------------------------------------------------------------
# 伤害与击杀（原型 dealDmg / killEnt）
# ---------------------------------------------------------------------------

func deal_dmg(tg: SimEntity, dmg: float, src: Dictionary, quiet: bool = false) -> float:
	if tg.dead:
		return 0.0
	var th: SimHamster = tg as SimHamster if tg is SimHamster else null
	if th != null and not th.alive:
		return 0.0
	if tg.is_prop:
		_prop_hit(tg as SimProp, dmg, src.get("owner"))
		return dmg
	if th != null:
		if th.iframes > 0.0:
			return 0.0
		if th.shield > 0:
			th.shield -= 1
			th.shield_t = 8.0
			emit({"t": "shield_block", "id": th.id})
			return 0.0
	if tg.kind == "base" and tg.shielded:
		tg.shield_hit = 0.15
		emit({"t": "base_shield", "id": tg.id, "x": float(src.get("x", tg.x)), "y": float(src.get("y", tg.y))})
		return 0.0
	if (tg.kind == "base" or tg.kind == "turret") and sudden:
		dmg *= float(R.combat.sudden.structMul)
	var o: SimHamster = src.get("owner") as SimHamster if src.get("owner") is SimHamster else null
	var crit := false
	if o != null:
		var cc := float(o.st.get("crit", 0.0)) + float(src.get("critAdd", 0.0))
		if not quiet and (bool(src.get("forceCrit", false)) or (cc > 0.0 and rnd() < cc)):
			dmg *= float(o.st.get("critDmg", 2.0))
			crit = true
		dmg *= o.banner_k
	if tg.supp_until > t:
		dmg *= 1.2
	if th != null:
		if o != null:
			dmg = minf(dmg, th.max_hp * float(Data.progression().get("pvpHitCap", 0.55)))
		dmg *= 1.0 - float(th.st.get("armor", 0.0))
		if th.hp - dmg <= 0.0 and th.tal.has("undying") and not th.undy_used:
			th.undy_used = true
			th.hp = th.max_hp * 0.4
			th.iframes = 2.0
			toast(th, "不死鼠发动！", "#ffd166", 1.6)
			return 0.0
	tg.hp -= dmg
	tg.flash = float(R.hamster.flashTime)
	if th != null:
		th.hurt_t = float(R.hamster.hurtTime)
		if o != null:
			o.aggro_t = t + float(R.hamster.aggroTime)
	if o != null:
		o.dmg_dealt += dmg
		if tg.kind == "base" or tg.kind == "turret":
			o.bdmg += dmg
		var vamp := float(o.st.get("vamp", 0.0))
		if vamp > 0.0 and o.alive:
			o.hp = minf(o.max_hp, o.hp + dmg * vamp)
	emit({"t": "damage", "id": tg.id, "amount": dmg, "crit": crit, "x": tg.x, "y": tg.y, "r": tg.r, "kind": tg.kind, "team": tg.team, "quiet": quiet and not crit, "by": o.id if o != null else -1})
	if tg.hp <= 0.0:
		kill_ent(tg, src)
	return dmg


func xp_near(o: SimEntity, tg: SimEntity, n: float) -> void:
	if o is SimHamster:
		var oh := o as SimHamster
		SimHamsterLogic.give_xp(self, oh, n)
		var ar := float(R.hamster.assistRadius)
		for h in hams:
			if h != oh and h.alive and h.team == oh.team and Vector2(h.x - tg.x, h.y - tg.y).length() < ar:
				SimHamsterLogic.give_xp(self, h, roundf(n * float(R.hamster.assistShare)))
	else:
		var team := o.team if o != null else ""
		for h in hams:
			if h.alive and (team == "" or h.team == team) and Vector2(h.x - tg.x, h.y - tg.y).length() < float(R.minion.nearRadiusNonHam):
				SimHamsterLogic.give_xp(self, h, roundf(n * float(R.minion.nearShareNonHam)))


func kill_ent(tg: SimEntity, src: Dictionary) -> void:
	var killer: SimHamster = src.get("owner") as SimHamster if src.get("owner") is SimHamster else null
	var by: Variant = src.get("by")
	var o: SimEntity = killer if killer != null else (by as SimEntity if by is SimEntity else null)
	if killer != null and killer.alive and tg.kind != "crate" and tg.team != killer.team:
		if killer.tal.has("vampire"):
			killer.hp = minf(killer.max_hp, killer.hp + 25.0)
		var scav := float(killer.st.get("scav", 0.0))
		if scav > 0.0 and int(killer.weapon().get("mag", 0)) > 0:
			var m := SimWeapons.mag_size(killer)
			killer.ammo = mini(m, killer.ammo + ceili(m * scav))
	match tg.kind:
		"ham":
			var th := tg as SimHamster
			th.alive = false
			th.hp = 0.0
			th.deaths += 1
			th.kill_streak = 0
			th.respawn_t = minf(float(R.hamster.respawnMax), float(R.hamster.respawnBase) + th.lvl * float(R.hamster.respawnPerLevel))
			if killer != null:
				killer.kills += 1
				killer.kill_streak += 1
				SimHamsterLogic.give_xp(self, killer, float(R.hamster.killXpBase) + th.lvl * float(R.hamster.killXpPerLevel))
				add_feed("%s 击败了 %s" % [killer.name, th.name], _tcol(killer.team))
				toast(killer, "击败 %s！" % th.name, "#ffd166", 1.5)
			else:
				add_feed("%s 倒下了" % th.name, "#cfc6d8")
			for i in int(R.hamster.deathGemsBase) + th.lvl / 2:
				drop_gem(th.x, th.y, float(R.hamster.deathGemXp))
			toast(th, "被打倒了…", "#ff8a7a", 2.0)
			emit({"t": "kill", "id": th.id, "kind": "ham", "x": th.x, "y": th.y, "team": th.team, "killer": killer.id if killer != null else -1})
		"minion":
			tg.dead = true
			xp_near(o, tg, float(R.minion.xp))
			emit({"t": "kill", "id": tg.id, "kind": "minion", "x": tg.x, "y": tg.y, "team": tg.team, "killer": killer.id if killer != null else -1})
		"turret":
			tg.dead = true
			for h in hams:
				if h.team != tg.team:
					SimHamsterLogic.give_xp(self, h, float(R.structure.turretXp))
			add_feed("%s的炮台被摧毁" % _tname(tg.team), _tcol(ENEMY[tg.team]))
			toast_all("%s的炮台被摧毁了" % _tname(tg.team), _tcol(ENEMY[tg.team]), 2.4)
			emit({"t": "kill", "id": tg.id, "kind": "turret", "x": tg.x, "y": tg.y, "team": tg.team, "killer": killer.id if killer != null else -1})
			emit({"t": "explode", "x": tg.x, "y": tg.y, "r": 150.0, "big": true})
		"base":
			tg.dead = true
			over = true
			winner = ENEMY[tg.team]
			end_t = 3.0
			toast_all("%s打爆了对方的仓鼠窝！" % _tname(winner), _tcol(winner), 3.0)
			emit({"t": "kill", "id": tg.id, "kind": "base", "x": tg.x, "y": tg.y, "team": tg.team, "killer": killer.id if killer != null else -1})
			emit({"t": "explode", "x": tg.x, "y": tg.y, "r": 220.0, "big": true})
			emit({"t": "match_over", "winner": winner})
			match_over.emit(winner)
		"crate":
			tg.dead = true
			var cr := tg as SimCrate
			var sp: Dictionary = cr.spot
			var C: Dictionary = R.crates.big if cr.big else R.crates.small
			sp.cur = null
			sp.resp = t + float(C.resp)
			var g: Array = C.gems
			var n := rand_int(int(g[0]), int(g[1]))
			for i in n:
				drop_gem(tg.x, tg.y, float(C.gemXp))
			if rnd() < float(C.cheese):
				_add_item("cheese", tg.x, tg.y, 0.0)
			emit({"t": "kill", "id": tg.id, "kind": "crate", "x": tg.x, "y": tg.y, "big": cr.big, "team": "neutral", "killer": killer.id if killer != null else -1})
		_:
			tg.dead = true
			emit({"t": "kill", "id": tg.id, "kind": tg.kind, "x": tg.x, "y": tg.y, "team": tg.team, "killer": -1})


func _tname(team: String) -> String:
	return "蓝队" if team == "blue" else "红队"


func _tcol(team: String) -> String:
	return "#4fa3ff" if team == "blue" else "#ff5b5b"


# ---------------------------------------------------------------------------
# 爆炸
# ---------------------------------------------------------------------------

func blast(x: float, y: float, rr: float, dmg: float, team: String, owner: SimHamster, kb: float) -> void:
	emit({"t": "explode", "x": x, "y": y, "r": rr, "big": false})
	noise(x, y, "boom", 1.2, null)
	var fo := float(R.combat.blastFalloff)
	var hit: SimEntity = null
	for e: SimEntity in hash_range(x, y, rr + 60.0):
		if not can_hit(team, e):
			continue
		var d := Vector2(e.x - x, e.y - y).length() - e.r
		if d > rr:
			continue
		var f := 1.0 - maxf(0.0, d) / rr * fo
		if deal_dmg(e, dmg * f, {"team": team, "owner": owner, "x": x, "y": y}) > 0.0:
			hit = e
		knock(e, e.x - x, e.y - y, kb * f)
	if hit != null and owner != null:
		emit({"t": "hitmark", "id": owner.id, "target": hit.id, "kill": hit.dead})


func blast_all(x: float, y: float, rr: float, dmg: float, owner: SimHamster, kb: float) -> void:
	## 爆炸罐：不分敌我
	emit({"t": "explode", "x": x, "y": y, "r": rr, "big": true})
	noise(x, y, "boom", 1.4, null)
	var fo := float(R.combat.blastFalloff)
	for e: SimEntity in hash_range(x, y, rr + 60.0):
		if e.kind == "base" or e.kind == "turret" or e.dead:
			continue
		if e is SimHamster and not (e as SimHamster).alive:
			continue
		var d := Vector2(e.x - x, e.y - y).length() - e.r
		if d > rr:
			continue
		var f := 1.0 - maxf(0.0, d) / rr * fo
		var ow: SimHamster = owner if owner != null and e.team != owner.team else null
		deal_dmg(e, dmg * f, {"team": "neutral", "owner": ow, "x": x, "y": y})
		knock(e, e.x - x, e.y - y, kb * f)


func mini_blast(x: float, y: float, rr: float, dmg: float, team: String, o: SimHamster) -> void:
	emit({"t": "explode", "x": x, "y": y, "r": rr, "big": false, "mini": true})
	for e: SimEntity in hash_range(x, y, rr + 40.0):
		if not can_hit(team, e):
			continue
		if Vector2(e.x - x, e.y - y).length() - e.r > rr:
			continue
		deal_dmg(e, dmg, {"team": team, "owner": o, "x": x, "y": y}, true)


func chain_lightning(e: SimEntity, dmg: float, o: SimHamster) -> void:
	var cur := e
	var hit := {e.id: true}
	var rr := float(Data.rule("abilities.chain.chainRange", 170))
	for k in int(Data.rule("abilities.chain.chainJumps", 2)):
		var nx: SimEntity = null
		var bd := rr * rr
		for c: SimEntity in hash_range(cur.x, cur.y, rr):
			if hit.has(c.id) or c.is_prop or not can_hit(o.team, c):
				continue
			var d := SimUtil.d2(c.x, c.y, cur.x, cur.y)
			if d < bd:
				bd = d
				nx = c
		if nx == null:
			break
		emit({"t": "zap", "x0": cur.x, "y0": cur.y, "x1": nx.x, "y1": nx.y})
		deal_dmg(nx, dmg, {"team": o.team, "owner": o, "x": cur.x, "y": cur.y})
		hit[nx.id] = true
		cur = nx


func add_fire(x: float, y: float, rr: float, life: float, team: String, owner: SimHamster, dps: float) -> void:
	fires.append({"x": x, "y": y, "r": rr, "t": 0.0, "life": life, "team": team, "owner": owner, "dps": dps, "tick": 0.0, "id": _new_id()})


func _upd_fires(dt: float) -> void:
	var i := fires.size() - 1
	while i >= 0:
		var f: Dictionary = fires[i]
		f.t += dt
		f.tick -= dt
		if f.tick <= 0.0:
			f.tick = 0.25
			for e: SimEntity in hash_range(f.x, f.y, f.r + 40.0):
				if not can_hit(f.team, e) or e.kind == "crate":
					continue
				if Vector2(e.x - f.x, e.y - f.y).length() < f.r + e.r * 0.5:
					deal_dmg(e, f.dps * 0.25, {"team": f.team, "owner": f.owner, "x": f.x, "y": f.y}, true)
					e.burn_t = maxf(e.burn_t, 1.2)
					e.burn_by = f.owner
		if f.t >= f.life:
			fires.remove_at(i)
		i -= 1


# ---------------------------------------------------------------------------
# 子弹
# ---------------------------------------------------------------------------

func new_bullet(kind: String, by: SimEntity, x: float, y: float, h: float, a: float, spd: float, dmg: float, rng_: float) -> SimBullet:
	var b := SimBullet.new()
	b.id = _new_id()
	b.kind = kind
	b.team = by.team
	b.by = by
	b.owner = by as SimHamster if by is SimHamster else null
	b.x = x; b.y = y; b.h = h; b.px = x; b.py = y
	b.x0 = x; b.y0 = y
	b.vx = cos(a) * spd
	b.vy = sin(a) * spd
	b.dmg = dmg
	b.life = rng_ / maxf(spd, 1.0)
	b.max_d = rng_
	return b


func _upd_bullets(dt: float) -> void:
	var sub := float(R.combat.bulletSubstep)
	var i := bullets.size() - 1
	while i >= 0:
		var b := bullets[i]
		var dead := false
		var sp := sqrt(b.vx * b.vx + b.vy * b.vy)
		var steps := maxi(1, ceili(sp * dt / sub))
		var sdt := dt / steps
		for s in steps:
			if dead:
				break
			b.px = b.x
			b.py = b.y
			b.x += b.vx * sdt
			b.y += b.vy * sdt
			var sd := map.solid_at(b.x, b.y, b.r * 0.5)
			if sd != null:
				var fresh := b.in_solid != sd
				b.in_solid = sd
				if fresh and sd.prop != null:
					_prop_hit(sd.prop as SimProp, b.dmg, b.owner)
				if b.wall_pierce > 0 and (sd.kind != "wall" or b.wall_pierce > 1):
					pass
				elif b.bounce > 0:
					b.bounce -= 1
					var hx := map.solid_at(b.px + b.vx * sdt, b.py, b.r * 0.5)
					var hy := map.solid_at(b.px, b.py + b.vy * sdt, b.r * 0.5)
					if hx != null or hy == null:
						b.vx = -b.vx
					if hy != null or hx == null:
						b.vy = -b.vy
					b.x = b.px
					b.y = b.py
					b.hit.clear()
					b.dmg *= b.bounce_k
					b.in_solid = null
					emit({"t": "ricochet", "x": b.x, "y": b.y, "h": b.h})
					continue
				else:
					dead = true
					_bullet_end(b, true)
					break
			else:
				b.in_solid = null
			for e: SimEntity in hash_at(b.x, b.y):
				if b.hit.has(e.id) or e == b.by or not can_hit(b.team, e):
					continue
				var rr := e.r + b.r
				if SimUtil.d2(b.x, b.y, e.x, e.y) >= rr * rr:
					continue
				b.hit[e.id] = true
				_on_bullet_hit(b, e)
				if b.pierce > 0:
					b.pierce -= 1
					continue
				dead = true
				break
		if not dead:
			b.life -= dt
			if b.life <= 0.0:
				dead = true
				_bullet_end(b, false)
		if dead:
			b.dead = true
			bullets[i] = bullets[bullets.size() - 1]
			bullets.pop_back()
		i -= 1


func _on_bullet_hit(b: SimBullet, e: SimEntity) -> void:
	if b.owner != null:
		SimWeapons.on_bullet_hit(self, b, e)
		return
	# 小兵、建筑、野怪的弹体
	var d := deal_dmg(e, b.dmg, {"team": b.team, "owner": null, "by": b.by, "x": b.x, "y": b.y})
	var l := maxf(0.001, Vector2(b.vx, b.vy).length())
	knock(e, b.vx / l, b.vy / l, b.kb)
	emit({"t": "bullet_hit", "x": b.x, "y": b.y, "h": b.h, "team": b.team, "kind": b.kind, "big": b.kind == "seed", "target": e.id})


func _bullet_end(b: SimBullet, wall: bool) -> void:
	if wall:
		emit({"t": "wall_hit", "x": b.x - b.vx * float(R.combat.wallHitBack), "y": b.y - b.vy * float(R.combat.wallHitBack), "h": b.h, "team": b.team, "kind": b.kind})


# ---------------------------------------------------------------------------
# 投掷物
# ---------------------------------------------------------------------------

func throw_lob(h: SimHamster, kind: String, tx: float, ty: float, o: Dictionary) -> SimLob:
	var dx := tx - h.x
	var dy := ty - h.y
	var d := maxf(40.0, sqrt(dx * dx + dy * dy))
	var sp := float(o.get("sp", 520))
	var tt := d / sp
	var L := SimLob.new()
	L.id = _new_id()
	L.kind = kind
	L.team = h.team
	L.owner = h
	L.x = h.x + dx / d * h.r
	L.y = h.y + dy / d * h.r
	L.z = h.r * 1.2
	L.vx = dx / d * sp
	L.vy = dy / d * sp
	L.vz = float(R.lob.launchVz) * tt
	L.fuse = float(o.get("fuse", -1.0))
	L.aoe = float(o.get("aoe", 0))
	L.dmg = float(o.get("dmg", 0))
	L.kb = float(o.get("kb", 0))
	L.impact = bool(o.get("impact", false))
	lobs.append(L)
	if lobs.size() > 40:
		lobs.pop_front()
	emit({"t": "throw", "id": h.id, "lob": L.id, "kind": kind})
	return L


func _upd_lobs(dt: float) -> void:
	var G := float(R.lob.gravity)
	var i := lobs.size() - 1
	while i >= 0:
		var b := lobs[i]
		b.t += dt
		b.rot += dt * 12.0
		var boom := false
		var nx := b.x + b.vx * dt
		var ny := b.y + b.vy * dt
		if map.solid_at(nx, ny, 5.0) != null:
			var hx := map.solid_at(nx, b.y, 5.0)
			var hy := map.solid_at(b.x, ny, 5.0)
			if hx != null or hy == null:
				b.vx *= -0.5
			if hy != null or hx == null:
				b.vy *= -0.5
		else:
			b.x = nx
			b.y = ny
		b.vz -= G * dt
		b.z += b.vz * dt
		if b.z <= 2.0:
			b.z = 2.0
			if b.vz < -float(R.lob.bounceMinVz):
				b.vz = -b.vz * float(R.lob.bounce)
				b.vx *= float(R.lob.friction)
				b.vy *= float(R.lob.friction)
				emit({"t": "lob_bounce", "x": b.x, "y": b.y})
			else:
				b.vz = 0.0
				var f := exp(-6.0 * dt)
				b.vx *= f
				b.vy *= f
		if b.impact and b.z < 40.0:
			for e: SimEntity in hash_at(b.x, b.y):
				if not can_hit(b.team, e) or e.is_prop:
					continue
				if SimUtil.d2(b.x, b.y, e.x, e.y) < (e.r + 8.0) * (e.r + 8.0):
					boom = true
					break
		if b.fuse >= 0.0:
			b.fuse -= dt
			if b.fuse <= 0.0:
				boom = true
		if b.t > float(R.lob.maxLife):
			boom = true
		if boom:
			b.dead = true
			lobs.remove_at(i)
			blast(b.x, b.y, b.aoe, b.dmg, b.team, b.owner, b.kb)
		i -= 1


# ---------------------------------------------------------------------------
# 小兵（原型 spawnWave / mkMinion / updMinion）
# ---------------------------------------------------------------------------

func _spawn_wave() -> void:
	wave_n += 1
	var per := int(Data.progression().get("minionsPerLanePerWave", 3))
	var spacing := float(R.minion.spawnSpacing)
	for team in TEAMS:
		for lane in map.lanes.keys():
			for i in per:
				spawn_q.append({"team": team, "lane": lane, "t": t + i * spacing})
	spawn_q.sort_custom(func(a, b): return float(a.t) < float(b.t))
	emit({"t": "wave", "n": wave_n})


func lane_path(team: String, lane: String) -> PackedVector2Array:
	var p: PackedVector2Array = map.lanes[lane]
	if team == "blue":
		return p
	var rev := PackedVector2Array()
	for i in range(p.size() - 1, -1, -1):
		rev.append(p[i])
	return rev


func _spawn_minion(team: String, lane: String) -> SimMinion:
	var U: Dictionary = Data.units().minion
	var M: Dictionary = R.minion
	var m := SimMinion.new()
	m.id = _new_id()
	m.kind = "minion"
	m.team = team
	m.lane = lane
	m.path = lane_path(team, lane)
	m.wp = 1
	var p0 := m.path[0]
	var j := float(M.spawnJitter)
	m.x = p0.x + rand(-j, j)
	m.y = p0.y + rand(-j, j)
	m.px = m.x; m.py = m.y
	m.r = float(U.radius)
	m.hp = float(U.hp) * min_mul
	m.max_hp = m.hp
	m.dmg = float(U.dmg) * min_mul
	m.cd = rand(0.3, 1.1)
	m.aim = 0.0 if team == "blue" else PI
	minions.append(m)
	_register(m)
	emit({"t": "spawn", "id": m.id, "kind": "minion"})
	return m


func _minion_target(m: SimMinion) -> SimEntity:
	var M: Dictionary = R.minion
	var best: SimEntity = null
	var bs := 1e9
	var W: Dictionary = M.weights
	for e: SimEntity in hash_range(m.x, m.y, float(M.searchRadius)):
		if not can_hit(m.team, e) or e.team == "neutral":
			continue
		if e.kind == "base" and e.shielded:
			continue
		var d := Vector2(e.x - m.x, e.y - m.y).length() - e.r
		if d > float(M.targetRange):
			continue
		var w := float(W.minion) if e.kind == "minion" else (float(W.ham) if e.kind == "ham" else float(W.other))
		if d * w < bs:
			bs = d * w
			best = e
	return best


func _upd_minion(m: SimMinion, dt: float) -> void:
	var M: Dictionary = R.minion
	m.flash = maxf(0.0, m.flash - dt)
	m.slow_t = maxf(0.0, m.slow_t - dt)
	m.reveal_t = maxf(0.0, m.reveal_t - dt)
	burn_tick(m, dt)
	if m.dead:
		return
	if m.stun > 0.0:
		m.stun -= dt
		m.vx *= 0.85
		m.vy *= 0.85
		return
	m.kx = SimUtil.damp(m.kx, 0.0, 9.0, dt)
	m.ky = SimUtil.damp(m.ky, 0.0, 9.0, dt)
	m.cd -= dt
	m.t_t -= dt
	if m.t_t <= 0.0:
		m.t_t = rand(float(M.retarget[0]), float(M.retarget[1]))
		m.target = _minion_target(m)
	var tg := m.target
	if tg != null and (tg.dead or (tg is SimHamster and not (tg as SimHamster).alive)):
		tg = null
	var sp := float(M.speed) * (float(M.slowMul) if m.slow_t > 0.0 else 1.0)
	var mx := 0.0
	var my := 0.0
	if tg != null:
		var dx := tg.x - m.x
		var dy := tg.y - m.y
		var d := maxf(0.001, sqrt(dx * dx + dy * dy))
		m.aim = atan2(dy, dx)
		if d > float(M.attackRange) + tg.r:
			mx = dx / d
			my = dy / d
		elif m.cd <= 0.0:
			m.cd = rand(float(M.cooldown[0]), float(M.cooldown[1]))
			var a := m.aim + rand(-float(M.spread), float(M.spread))
			var b := new_bullet("mpea", m, m.x + cos(a) * 14.0, m.y + sin(a) * 14.0, 11.0, a, float(M.bulletSpeed), m.dmg, float(M.bulletRange))
			b.r = float(M.bulletRadius)
			b.kb = float(M.bulletKb)
			bullets.append(b)
			m.reveal_t = 0.4
			noise(m.x, m.y, "gun", 0.35, m)
			emit({"t": "minion_fire", "id": m.id, "x": m.x, "y": m.y, "aim": a, "team": m.team})
	else:
		var wp := m.path[mini(m.wp, m.path.size() - 1)]
		var dx := wp.x - m.x
		var dy := wp.y - m.y
		var d := maxf(0.001, sqrt(dx * dx + dy * dy))
		if d < float(M.waypointRadius) and m.wp < m.path.size() - 1:
			m.wp += 1
		mx = dx / d
		my = dy / d
		m.aim = atan2(dy, dx)
	m.vx = SimUtil.damp(m.vx, mx * sp, float(M.accel), dt)
	m.vy = SimUtil.damp(m.vy, my * sp, float(M.accel), dt)
	var ox := m.x
	var oy := m.y
	m.x += (m.vx + m.kx) * dt
	m.y += (m.vy + m.ky) * dt
	map.resolve_circle(m, m.r)
	m.walk += Vector2(m.x - ox, m.y - oy).length() * 0.2


# ---------------------------------------------------------------------------
# 建筑（原型 updStruct）
# ---------------------------------------------------------------------------

func _struct_target(s: SimStructure) -> SimEntity:
	var S: Dictionary = R.structure
	var best: SimEntity = null
	var bs := 1e9
	for e: SimEntity in hash_range(s.x, s.y, s.range_):
		if e.team == s.team or e.team == "neutral" or e.kind == "base" or e.kind == "turret":
			continue
		if e is SimHamster and not (e as SimHamster).alive:
			continue
		if e.dead:
			continue
		var d := Vector2(e.x - s.x, e.y - s.y).length() - e.r
		if d > s.range_:
			continue
		var w := d
		if e is SimHamster:
			w *= float(S.aggroHamMul) if (e as SimHamster).aggro_t > t else float(S.hamMul)
		if w < bs:
			bs = w
			best = e
	return best


func _upd_struct(s: SimStructure, dt: float) -> void:
	if s.dead:
		return
	var S: Dictionary = R.structure
	s.flash = maxf(0.0, s.flash - dt)
	s.shield_hit = maxf(0.0, s.shield_hit - dt)
	s.cd -= dt
	s.t_t -= dt
	if s.kind == "base":
		var n := 0
		for o in structs:
			if o.kind == "turret" and o.team == s.team and not o.dead:
				n += 1
		s.shielded = n >= shield_turrets
	if s.t_t <= 0.0:
		s.t_t = float(S.retarget)
		s.target = _struct_target(s)
	var tg := s.target
	if tg != null and (tg.dead or (tg is SimHamster and not (tg as SimHamster).alive)):
		tg = null
	if tg == null:
		return
	var a := atan2(tg.y - s.y, tg.x - s.x)
	s.aim = SimUtil.turn_to(s.aim, a, float(S.turnRate) * dt)
	if s.cd <= 0.0 and absf(SimUtil.ang_diff(s.aim, a)) < float(S.fireAngle):
		s.cd = s.cd_max
		s.alt ^= 1
		var off := (s.alt_off if s.alt == 1 else -s.alt_off)
		var gx := s.x + cos(s.aim) * s.r * 0.9 - sin(s.aim) * off
		var gy := s.y + sin(s.aim) * s.r * 0.9 + cos(s.aim) * off
		var b := new_bullet("seed", s, gx, gy, s.muzzle_h, a, float(S.bulletSpeed), s.dmg, s.range_ + float(S.bulletRangeExtra))
		b.r = float(S.bulletRadius)
		b.kb = float(S.bulletKb)
		bullets.append(b)
		emit({"t": "struct_fire", "id": s.id, "x": gx, "y": gy, "h": s.muzzle_h, "aim": s.aim, "team": s.team, "kind": s.kind})
		noise(s.x, s.y, "gun", 0.7, s)


# ---------------------------------------------------------------------------
# 物件（台灯 / 爆炸罐 / 纸箱）、弹射装置
# ---------------------------------------------------------------------------

func _prop_hit(p: SimProp, dmg: float, owner: Variant) -> void:
	if p.dead:
		return
	p.hp -= dmg
	p.flash = 0.1
	emit({"t": "prop_hit", "id": p.id, "kind": p.kind, "x": p.x, "y": p.y})
	if p.hp <= 0.0:
		_destroy_prop(p, owner as SimHamster if owner is SimHamster else null)


func _destroy_prop(p: SimProp, owner: SimHamster) -> void:
	p.dead = true
	p.solid.off = true
	map.nav_patch(p.x, p.y, float(R.props.navPatch))
	p.resp_at = t + float(R.props[p.kind].resp)
	emit({"t": "prop_break", "id": p.id, "kind": p.kind, "x": p.x, "y": p.y})
	if p.kind == "barrel":
		var D: Dictionary = R.props.barrel
		blast_all(p.x, p.y, float(D.blastR), float(D.blastDmg), owner, float(D.blastKb))
	elif p.kind == "lamp":
		noise(p.x, p.y, "boom", 0.6, null)


func _upd_props(dt: float) -> void:
	for p in props:
		p.flash = maxf(0.0, p.flash - dt)
		if p.dead and t >= p.resp_at:
			var blocked := false
			for h in hams:
				if h.alive and Vector2(h.x - p.x, h.y - p.y).length() < p.r + h.r + float(R.props.respawnBlock):
					blocked = true
			if not blocked:
				p.dead = false
				p.hp = p.max_hp
				p.solid.off = false
				map.nav_patch(p.x, p.y, float(R.props.navPatch))
				emit({"t": "prop_respawn", "id": p.id, "kind": p.kind})
			else:
				p.resp_at = t + 2.0


func _upd_pads(dt: float) -> void:
	var P: Dictionary = R.pads
	for p in map.pads:
		p.anim = maxf(0.0, float(p.anim) - dt)
	for h in hams:
		if not h.alive or not h.air.is_empty() or h.pad_cd > 0.0:
			continue
		for i in map.pads.size():
			var p: Dictionary = map.pads[i]
			if SimUtil.d2(h.x, h.y, p.x, p.y) < float(P.triggerR) * float(P.triggerR):
				_launch(h, p, i)
				break


func _launch(h: SimHamster, p: Dictionary, idx: int) -> void:
	var P: Dictionary = R.pads
	var j := float(P.jitter)
	h.air = {"t": 0.0, "dur": float(P.dur), "x0": h.x, "y0": h.y, "x1": float(p.tx) + rand(-j, j), "y1": float(p.ty) + rand(-j, j), "hgt": float(P.height)}
	h.pad_cd = float(P.cooldown)
	h.roll_t = 0.0
	h.vx = 0.0
	h.vy = 0.0
	p.anim = 0.35
	noise(p.x, p.y, "pad", 0.8, h)
	emit({"t": "launch", "id": h.id, "pad": idx})
	toast(h, "起飞！", "#ffd166", 0.9)


func land(h: SimHamster) -> void:
	var P: Dictionary = R.pads
	h.air = {}
	h.z = 0.0
	map.resolve_circle(h, h.r)
	emit({"t": "land", "id": h.id, "x": h.x, "y": h.y})
	for e: SimEntity in hash_range(h.x, h.y, float(P.landR) + 30.0):
		if not can_hit(h.team, e) or e.kind == "base" or e.kind == "turret" or e.is_prop:
			continue
		if Vector2(e.x - h.x, e.y - h.y).length() < float(P.landR) + e.r:
			deal_dmg(e, float(P.landDmg) * float(h.st.dmg), {"team": h.team, "owner": h, "x": h.x, "y": h.y})
			knock(e, e.x - h.x, e.y - h.y, float(P.landKb))


# ---------------------------------------------------------------------------
# 箱子、经验、拾取
# ---------------------------------------------------------------------------

func _make_crate(spot: Dictionary) -> SimCrate:
	var C: Dictionary = R.crates.big if spot.big else R.crates.small
	var c := SimCrate.new()
	c.id = _new_id()
	c.kind = "crate"
	c.team = "neutral"
	c.x = float(spot.x); c.y = float(spot.y); c.px = c.x; c.py = c.y
	c.r = float(C.r)
	c.hp = float(C.hp); c.max_hp = c.hp
	c.big = bool(spot.big)
	c.spot = spot
	crates.append(c)
	_register(c)
	emit({"t": "spawn", "id": c.id, "kind": "crate"})
	return c


func drop_gem(x: float, y: float, xp: float) -> void:
	if items.size() > int(R.items.gemMax):
		return
	_add_item("gem", x, y, xp)


func _add_item(type: String, x: float, y: float, xp: float) -> SimItem:
	var g := SimItem.new()
	g.id = _new_id()
	g.type = type
	g.x = x
	g.y = y
	var a := rand(0.0, TAU)
	var s := rand(60.0, 180.0) if type == "gem" else 90.0
	g.vx = cos(a) * s
	g.vy = sin(a) * s
	g.vz = rand(160.0, 280.0) if type == "gem" else 220.0
	g.z = 12.0
	g.xp = xp
	g.big = xp >= float(R.items.gemBigXp)
	items.append(g)
	return g


func _item_phys(g: SimItem, dt: float) -> void:
	if g.vx != 0.0 or g.vy != 0.0:
		g.x += g.vx * dt
		g.y += g.vy * dt
		var f := exp(-(1.2 if g.z > 0.0 else 7.0) * dt)
		g.vx *= f
		g.vy *= f
		if g.z <= 0.0 and absf(g.vx) < 4.0 and absf(g.vy) < 4.0:
			g.vx = 0.0
			g.vy = 0.0
		if map.resolve_circle(g, 6.0):
			g.vx *= -0.4
			g.vy *= -0.4
	if g.z > 0.0 or g.vz != 0.0:
		g.vz -= float(R.items.gravity) * dt
		g.z += g.vz * dt
		if g.z <= 0.0:
			g.z = 0.0
			g.vz = -g.vz * 0.35 if g.vz < -120.0 else 0.0


func _upd_items(dt: float) -> void:
	var I: Dictionary = R.items
	var i := items.size() - 1
	while i >= 0:
		var g := items[i]
		g.t += dt
		_item_phys(g, dt)
		var removed := false
		if g.type == "gem":
			if g.t > float(I.gemDelay):
				var best: SimHamster = null
				var bd := 1e9
				for h in hams:
					if not h.alive:
						continue
					var d := Vector2(h.x - g.x, h.y - g.y).length()
					var mg := float(h.st.magnet)
					if d < mg and d < bd:
						bd = d
						best = h
				if best != null:
					var d := maxf(bd, 1.0)
					var sp := float(I.gemSpeed) + (1.0 - d / float(best.st.magnet)) * float(I.gemSpeedNear)
					g.x += (best.x - g.x) / d * sp * dt
					g.y += (best.y - g.y) / d * sp * dt
					if d < best.r + 8.0:
						removed = true
						SimHamsterLogic.give_xp(self, best, g.xp)
						best.munch_t = 0.25
						emit({"t": "gem", "id": best.id, "big": g.big})
			if not removed and g.t > float(I.gemLife):
				removed = true
		else:
			if g.t >= float(I.pickupDelay):
				for h in hams:
					if not h.alive or Vector2(h.x - g.x, h.y - g.y).length() > h.r + 14.0:
						continue
					h.hp = minf(h.max_hp, h.hp + float(I.cheeseHeal))
					emit({"t": "cheese", "id": h.id})
					emit({"t": "pop", "x": h.x, "y": h.y, "h": h.r * 2.8, "text": "+%d" % int(I.cheeseHeal), "color": "#8de0a6", "size": 16})
					removed = true
					break
			if not removed and g.t > float(I.cheeseLife):
				removed = true
		if removed:
			g.dead = true
			items.remove_at(i)
		i -= 1


# ---------------------------------------------------------------------------
# 分离（单位之间、单位与建筑/箱子）
# ---------------------------------------------------------------------------

func _separate() -> void:
	var mv: Array = []
	for h in hams:
		if h.alive and h.air.is_empty():
			mv.append(h)
	for m in minions:
		if not m.dead:
			mv.append(m)
	var C := 64.0
	var grid := {}
	for a: SimEntity in mv:
		var k := floori(a.x / C) * 10000 + floori(a.y / C)
		if not grid.has(k):
			grid[k] = []
		(grid[k] as Array).append(a)
	for a: SimEntity in mv:
		var cx := floori(a.x / C)
		var cy := floori(a.y / C)
		for i in range(-1, 2):
			for j in range(-1, 2):
				for b: SimEntity in grid.get((cx + i) * 10000 + cy + j, []):
					if b.id <= a.id:
						continue
					var rr := a.r + b.r
					var dx := a.x - b.x
					var dy := a.y - b.y
					var dd := dx * dx + dy * dy
					if dd < rr * rr and dd > 1e-4:
						var d := sqrt(dd)
						var p := (rr - d) / 2.0
						var nx := dx / d
						var ny := dy / d
						var wa := 0.2 if a.kind == "boss" else 1.0
						var wb := 0.2 if b.kind == "boss" else 1.0
						a.x += nx * p * wa
						a.y += ny * p * wa
						b.x -= nx * p * wb
						b.y -= ny * p * wb
	for s in structs:
		if s.dead:
			continue
		for a: SimEntity in mv:
			var rr := a.r + s.r
			var dx := a.x - s.x
			var dy := a.y - s.y
			var dd := dx * dx + dy * dy
			if dd < rr * rr and dd > 1e-4:
				var d := sqrt(dd)
				a.x = s.x + dx / d * rr
				a.y = s.y + dy / d * rr
	for c in crates:
		if c.dead:
			continue
		for a: SimEntity in mv:
			var rr := a.r + c.r
			var dx := a.x - c.x
			var dy := a.y - c.y
			var dd := dx * dx + dy * dy
			if dd < rr * rr and dd > 1e-4:
				var d := sqrt(dd)
				a.x = c.x + dx / d * rr
				a.y = c.y + dy / d * rr
	for a: SimEntity in mv:
		map.resolve_circle(a, a.r)


# ---------------------------------------------------------------------------
# 视野与听觉
# ---------------------------------------------------------------------------

func _compute_vis() -> void:
	SimVision.compute(self)


func noise(x: float, y: float, type: String, loud: float, src: SimEntity) -> void:
	var H: Dictionary = R.hearing
	var life := float(H.life.get(type, H.life.default))
	var team := ""
	if src != null and src.team != "neutral":
		team = src.team
	noises.append({"x": x, "y": y, "type": type, "loud": loud, "team": team, "src": src.id if src != null else -1, "t": 0.0, "life": life, "id": _new_id()})
	if noises.size() > int(H.maxNoises):
		noises.pop_front()
	if type != "step":
		SimAI.hear(self, x, y, loud, src)


func _upd_noises(dt: float) -> void:
	var i := noises.size() - 1
	while i >= 0:
		var n: Dictionary = noises[i]
		n.t += dt
		if n.t >= n.life:
			noises.remove_at(i)
		i -= 1


# ---------------------------------------------------------------------------
# 校验与摘要（测试用）
# ---------------------------------------------------------------------------

func state_hash() -> int:
	var parts := PackedStringArray()
	parts.append("%d" % tick)
	for h in hams:
		parts.append("%s:%.3f,%.3f,%.3f,%d,%d,%s,%d%d%d" % [h.name, h.x, h.y, h.hp, h.lvl, h.ammo, h.weapon_id, h.evo_lv("a"), h.evo_lv("b"), h.evo_lv("c")])
	for m in minions:
		parts.append("m%d:%.3f,%.3f,%.2f" % [m.id, m.x, m.y, m.hp])
	for s in structs:
		parts.append("s%d:%.2f" % [s.id, s.hp])
	parts.append("b%d,i%d" % [bullets.size(), items.size()])
	return "|".join(parts).hash()
