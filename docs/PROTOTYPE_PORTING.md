# 原型代码对照表

原型在 `reference/prototype/`：`manzai-ershu-pvp.html` 可以直接用浏览器打开玩；`src/` 是拆开的源码。
**移植规则，不移植代码**：行为和数值以原型为准，代码结构按 Godot 和 PIPELINE.md 重写。原型的 WebGL 渲染器和 2D 绘制只当外观参考。

| 原型文件 | 内容 | 移植到 |
|---|---|---|
| n0.html | 界面外壳：主菜单、大厅、暂停、结算、图鉴的布局和文案 | scenes/ui |
| n1.js | 工具函数、地图常量、兵线、碰撞（resolveCircle）、视线（hasLOS）、寻路网格 | scripts/sim（地图、物理、寻路） |
| n1b.js | 枪声合成配方（GSFX：每把枪的分层和混响） | tools/audio |
| n2.js | 主体逻辑：仓鼠（makeHam、updHam、respawn）、AI（aiThink、aiTarget）、子弹（updBullets）、伤害（dealDmg、killEnt）、兵线（spawnWave）、建筑、野怪和鼠王、零食箱和经验、场景物件、听觉（noise） | scripts/sim |
| n2c.js | 武器进化（EVO、evp、fireWeapon、onBulletHit、explode、updLobs、evoTick）、13 个道具（useGadget）、视野最终版（computeVis、litBy、smokeBlocks）、升级卡（rollChoices、choiceLabel、applyChoice、aiPick）、属性（calcStats） | scripts/sim（武器、进化、道具、卡池、属性） |
| n3.js | WebGL 渲染器 | 不移植（Godot 自带） |
| n4.js | 程序模型、仓鼠姿势（poseHam）、配件挂载（pushAtt）、特效、灯光 | 外观和动作参考 → tools/blender、scripts/view |
| n5a.js | 2D 仓鼠头像和图标绘制 | 外观参考 |
| n5b.js | HUD、升级卡、小地图、听觉光带、图鉴、输入、流程 | scripts/ui |

注意：n2c.js 里有和 n2.js 同名的函数，**以 n2c.js 为准**（原型拼接时后定义的覆盖前面的）。
