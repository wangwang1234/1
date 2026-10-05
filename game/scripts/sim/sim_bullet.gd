class_name SimBullet
extends RefCounted
## 子弹 / 弹丸 / 火箭 / 小兵和建筑的弹体。对应原型 mkBullet。

var kind := "trc"         # trc / pel / snipe / rocket / flame / mpea / seed / orb / rat / spike / swave
var team := "neutral"
var by: SimEntity = null   # 发射者实体
var owner: SimHamster = null  # 计分 / 进化效果归属
var x := 0.0
var y := 0.0
var h := 16.0
var px := 0.0
var py := 0.0
var vx := 0.0
var vy := 0.0
var dmg := 10.0
var r := 4.5
var life := 1.0
var pierce := 0
var kb := 40.0
var aoe := 0.0
var aoe_dmg := 0.0
var hit := {}              # 已命中的实体 id
var bounce := 0
var bounce_k := 0.85
var wall_pierce := 0
var in_solid: Object = null
var x0 := 0.0
var y0 := 0.0
var eff := 1.0
var min_f := 1.0
var max_d := 600.0
var fx := {}               # 进化效果：src, lv, ign, ignK, slow, stun, mark, crit, force, expl
var weapon := ""
var dead := false
var id := 0
