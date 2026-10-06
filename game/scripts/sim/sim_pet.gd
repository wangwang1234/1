class_name SimPet
extends SimEntity
## 宠物：小鸡战友（chick）、萤火虫（firefly）、刺猬炮台（hedgehog）。不可被攻击。对应原型 mkPet / updPet。

var type := "chick"
var owner: SimHamster = null
var h := 0.0                  # 离地高度
var lvl := 1
var cd := 0.5
var t := 0.0
var target: SimEntity = null
var zap := {}                 # 萤火虫最近一次电击 {x1, y1, h1, t}
