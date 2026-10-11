extends SceneTree
func _init() -> void:
 var w := SimWorld.new()
 w.setup({"mode":"slice", "ai":{"blue":0,"red":0}})
 var a := SimMinion.new();var b := SimMinion.new()
 a.id=w.new_uid(); b.id=w.new_uid()
 a.dead=true; b.dead=true; a.target=b; b.target=a
 var ar: WeakRef = weakref(a);var br: WeakRef = weakref(b)
 w.minions.append(a);w.minions.append(b);w.register(a);w.register(b)
 a=null;b=null
 w.step(0);w.step(0)
 w.dispose();w=null
 print("BASELINE ", JSON.stringify({"removed_minion_a_retained":ar.get_ref()!=null,"removed_minion_b_retained":br.get_ref()!=null}))
 # Break the reproduced baseline cycle so the diagnostic itself does not leak.
 if ar.get_ref()!=null: ar.get_ref().target=null
 if br.get_ref()!=null: br.get_ref().target=null
 quit()
