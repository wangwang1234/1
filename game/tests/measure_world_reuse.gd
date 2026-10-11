extends SceneTree
## Six short matches plus cyclic dead-minion removals; no RSS claim.
func _one(seed_: int) -> Dictionary:
	var w := SimWorld.new()
	w.setup({"mode": "full", "seed": seed_, "ai": {"blue": 5, "red": 5}})
	var refs: Array[WeakRef] = [weakref(w)]
	for h in w.hams: refs.append(weakref(h))
	for p in w.props: refs.append(weakref(p))
	for pair in 32:
		var a := SimMinion.new()
		var b := SimMinion.new()
		a.id = w.new_uid(); b.id = w.new_uid()
		a.dead = true; b.dead = true; a.target = b; b.target = a
		w.minions.append(a); w.minions.append(b); w.register(a); w.register(b)
		refs.append(weakref(a)); refs.append(weakref(b))
	for i in 1200:
		w.step(1.0 / 60.0)
		w.events.clear()
	for c in w.crates: refs.append(weakref(c))
	w.dispose()
	w = null
	return {"seed": seed_, "refs": refs}

func _init() -> void:
	var rows: Array = []
	for seed_ in range(7, 13):
		# Inspect after _one returns so its loop variables cannot keep an entity alive.
		var result := _one(seed_)
		var row := {"seed": seed_, "tracked": result.refs.size(), "retained": result.refs.filter(func(r: WeakRef) -> bool: return r.get_ref() != null).size()}
		result.refs.clear()
		row.objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
		rows.append(row)
	var ok := rows.all(func(row: Dictionary) -> bool: return row.retained == 0)
	print("WORLD_REUSE ", JSON.stringify({"ok": ok, "simulated_seconds": 120, "rows": rows}))
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../review/lan_recovery_fec/world_reuse.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok": ok, "simulated_seconds": 120, "rows": rows}, "  "))
	file.close()
	quit(0 if ok else 1)
