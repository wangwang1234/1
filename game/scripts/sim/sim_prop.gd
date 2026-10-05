class_name SimProp
extends SimEntity
## 场景互动物件：台灯（lamp）、爆炸罐（barrel）、纸箱（box）。可打坏，一段时间后复原。

var resp_at := 0.0
var solid: SimMap.Solid = null
var rot := 0.0
var ht := 50.0
