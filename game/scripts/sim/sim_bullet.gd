class_name SimBullet
extends RefCounted
## 子弹 / 弹丸 / 火箭 / 小兵和建筑的弹体。对应原型 mkBullet。

var kind := "trc"         # trc / pel / snipe / rocket / flame / mpea / seed / orb / rat / spike / swave / sentry
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
var home := 0.0            # 追踪转向速度（弧度/秒，>0 = 追踪）
var home_after := 0.0      # 第一次反弹后开始追踪
var home_t := 0.0
var home_tgt := 0          # 追踪目标 id
var split_at := 0.0        # 飞出这么远后分裂
var wr := 1.0              # 剑气宽度
var big := false
var dead := false
var id := 0


func clone() -> SimBullet:
	var b := SimBullet.new()
	for p in ["kind", "team", "by", "owner", "x", "y", "h", "px", "py", "vx", "vy", "dmg", "r", "life", "pierce", "kb", "aoe", "aoe_dmg",
			"bounce", "bounce_k", "wall_pierce", "x0", "y0", "eff", "min_f", "max_d", "fx", "weapon", "home", "home_after", "home_t", "home_tgt", "split_at", "wr", "big"]:
		b.set(p, get(p))
	b.hit = hit.duplicate()
	return b
