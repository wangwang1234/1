class_name SimEntity
extends RefCounted
## 所有逻辑实体的基类（仓鼠、小兵、建筑、物件、箱子、野怪）。坐标为原型单位。

var id := 0
var kind := ""            # ham / minion / base / turret / sentry / crate / lamp / barrel / box / roach / rat / boss / decoy / pet
var team := "neutral"
var x := 0.0
var y := 0.0
var px := 0.0             # 上一逻辑帧位置（表现层插值用）
var py := 0.0
var r := 16.0
var hp := 1.0
var max_hp := 1.0
var dead := false
var flash := 0.0
var vx := 0.0
var vy := 0.0
var kx := 0.0             # 击退速度（非仓鼠）
var ky := 0.0
var aim := 0.0
var is_prop := false
var shielded := false
var stun := 0.0
var slow_t := 0.0
var burn_t := 0.0
var burn_acc := 0.0
var burn_k := 1.0
var burn_by: SimEntity = null
var reveal_t := 0.0
var mark_team := ""
var mark_until := 0.0
var supp_until := 0.0
var dazzle_until := 0.0
var frozen_until := 0.0
var shield_hit := 0.0
var burn_spread_until := 0.0


func is_alive() -> bool:
	return not dead


func save_prev() -> void:
	px = x
	py = y
