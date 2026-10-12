# 击败系统接入（第一阶段）

权威模拟为 `SimWorld`。离线与分屏默认 `authoritative=true`；客户端由 `LanSession.attach` 设为false。

伤害必须走 `deal_dmg`。`src.owner` 是仓鼠主体，`src.contributor_id` 是放置/发射时的贡献来源，`src.method` 是 normal / explosion / burn / slash / reflect。即时攻击可省略contributor_id，服务端取当前控制身份；持久攻击必须保存来源，禁止命中时改成主人的当前身份。

`SimWorld.kill_system` 保存每局记录与来源注册表。`SimHamster.id`、`seed_total`、`kill_streak`、`consecutive_deaths` 归仓鼠主体；`contributor_id` 与 `player_contributor_id` 管控制身份。AI接管前的来源固定；重连时AI来源通过别名归并到玩家。不要改写已有投射物的来源；反射是例外，应在反射时把主人、贡献来源和reflected标记一起改为反射者。

治疗走 `heal_player(provider, recipient, requested)`，只记录实际恢复的生命。护盾控制器在吸收时调用 `record_support(provider, recipient, actual_absorbed, "shield")`。控制器只在真正开始/结束时调用 `begin_assist_control(provider, victim, source)` / `end_assist_control(victim_id, token)`。侦察真正命中后调用 `record_recon(provider, victim, "sonar"或"camera")`。仓鼠球及捕鼠夹来源分别为hamster_ball / mousetrap；其他控制不自动算成这两种道具。

配置使用KillConfig资源，所有第一阶段数值均在data/kill_config*.tres。当前实战为CAP120；可在建局cfg中传入 `kill_config: "res://data/kill_config.tres"` 切换默认方案。修改以后必须让所有联机端使用相同文件。

服务器死亡链路只结算一次，先冻结归属/份额，再发放原额经验并生成KillEvent。外部控制器不要自己调用give_xp来额外发放PvP击败经验。`give_xp(..., false)` 跳过经验倍率，并在满级继续增加累计S。

客户端在MatchView的kill_event分发分支消费事件。第二阶段已接入KillPresentationUI、KillFeedUI、每视口StreakBannerUI和GlobalBannerUI；依据killer_connected和各assist.connected控制个人提示，依据身份快照给断线名字置灰。调试面板preview_requested只用于本地预览，不发送网络消息，不修改服务器状态。

测试：tools/test.sh；python3 tools/test_kill_rpc.py；python3 tools/test_lan_resume.py。独立调试场景为res://scenes/dev/kill_debug.tscn，局内F8打开面板。

上述治疗、护盾、侦察与控制开始接口都有可选的contributor_id参数；持久力场、护盾、摄像头、捕鼠夹必须传入放置时保存的来源。即时技能可省略。


已同步主线Q/E道具：声呐、摄像头、捕鼠夹、再生力场、哨戒炮、反射器和信号弹召唤小兵接入上述服务器接口。部署物/召唤物保留 `owner_contributor_id`；捕鼠夹的 `trap_controls` 只保存token和结束时刻，根控提前解除也停止记录。当前护盾展开器仅自盾，无支援助攻；仓鼠球及队友护盾玩法仍需提供控制器。

## 第二阶段展示接入

`KillPresentationUI`每局一个，信息条与全场横幅模型各客户端共享，分别绘制在各视口；`StreakBannerUI`只绑定所属本地仓鼠。所有Control设为忽略输入。客户端只消费服务器连续数和奖励，重复event_id不重复播报。

KillEvent的`victim_death_count`是服务端死亡次序快照，避免旧alive快照抹掉新死亡提示。复活事件与对应死亡次数的alive快照均能清除提示。重连清除旧展示，不修改服务器状态。

新增布局和停留参数在`kill_config*.tres`；`bottom_exclusion`可传入视口内触控区域最上边界，保证瓜子排留出配置中的净空。当前接入Q/E触控按钮，未来双摇杆也须提供相同边界。

按导演确认：全场横幅含首次击败、5连、每段6连和终结；超过四颗金瓜子合并为一颗×总数；无击败者信息条为“方式图标+受害者名+被击败”。同时触发的标签在同一个横幅中展示，后续事件排队。

独立视觉预览：`res://scenes/dev/kill_preview.tscn`；场景验证：`res://tests/kill_ui_smoke.tscn`，已接入`tools/test.sh`。图标为程序占位；完整Tween动画、音效和正式部件按后续阶段替换。


## 第三阶段Claude素材（当前展示）

用户提供guazi_stamp.zip并明确采用徽章中心数字＋缎带文字：1～2普通、3～4银色、5及以上金色；红色仅作终结标签。此布局替代第二阶段私人瓜子排；服务端规则及事件路由不变。原PNG位于game/assets/ui/kill_stamp，资源目录为data/kill_art.tres。新增尺寸、字号及档位参数仍在kill_config*.tres。

信息条方式基于同包瓜子／碎片／射线，由Godot程序叠加方法符号。刀斩使用原瓜子贴图的上下区域分离取样，原PNG不改写。所有文字数字由字体绘制；原包preview.png仅为审阅参考。
