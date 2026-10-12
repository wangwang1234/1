class_name SimLifecycle
extends RefCounted
## Break links only when an object leaves the match permanently.
static func release(e: Object) -> void:
	if e is SimEntity:
		e.burn_by = null
	if e is SimHamster:
		if e.ai != null:
			e.ai.target = null
		e.dash_hit.clear()
		e.pet_list.clear()
	elif e is SimMinion:
		e.target = null
		e.follow = null
		e.owner = null
	elif e is SimStructure:
		e.target = null
		e.owner = null
	elif e is SimProp:
		if e.solid != null:
			e.solid.prop = null
		e.solid = null
	elif e is SimCrate:
		if e.spot.get("cur") == e:
			e.spot.cur = null
		e.spot = {}
	elif e is SimBullet:
		e.by = null
		e.owner = null
		e.in_solid = null
	elif e is SimLob:
		e.owner = null
		e.att = null
	elif e is SimMob:
		e.target = null
		e.camp = {}
	elif e is SimPet:
		if e.owner != null:
			e.owner.pet_list.erase(e)
		e.owner = null
		e.target = null
	elif e is SimDecoy:
		e.owner = null
