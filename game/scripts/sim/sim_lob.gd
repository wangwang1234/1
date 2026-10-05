class_name SimLob
extends RefCounted
## 抛物投掷物（手雷等）。对应原型 throwLob / updLobs。

var kind := "frag"
var team := "neutral"
var owner: SimHamster = null
var x := 0.0
var y := 0.0
var z := 20.0
var vx := 0.0
var vy := 0.0
var vz := 0.0
var fuse := -1.0
var aoe := 130.0
var dmg := 70.0
var kb := 380.0
var impact := false
var t := 0.0
var rot := 0.0
var dead := false
var id := 0
