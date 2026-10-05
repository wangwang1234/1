class_name SimMinion
extends SimEntity
## 兵线小兵。对应原型 mkMinion / updMinion。

var lane := "mid"
var path := PackedVector2Array()
var wp := 1
var cd := 0.5
var dmg := 6.0
var target: SimEntity = null
var t_t := 0.0
var walk := 0.0
