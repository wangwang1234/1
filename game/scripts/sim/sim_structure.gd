class_name SimStructure
extends SimEntity
## 鼠窝（base）/ 炮台（turret）。对应原型 mkStruct / updStruct。

var range_ := 480.0
var dmg := 30.0
var cd := 0.5
var cd_max := 1.0
var target: SimEntity = null
var t_t := 0.0
var alt := 0
var muzzle_h := 60.0
var alt_off := 0.0
var owner: SimHamster = null
var life := 0.0
