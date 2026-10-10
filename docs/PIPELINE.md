# 满载而鼠 — 资源管线与技术规范

## 1. 工具与版本
- 引擎：Godot 4.x 最新稳定版，GDScript（静态类型）。不用 C#（手机导出支持不稳定）。
- 资产：Blender 4.x，全部用 Python 脚本在后台生成。
- 音频：Python 3（numpy / scipy 离线合成），可选 MIDI 生成 + FluidSynth + 可商用音色库渲染音乐。
- 版本管理：git。第一次会话时检查 `godot`、`blender`、`python` 是否可用，把实际的命令和版本号写进 CLAUDE.md 的“环境”一节。

## 2. 单位与坐标
- 数据（`game/data/*.json`）保持原型单位：1 单位 = 1 厘米。加载时乘 0.01 换成 Godot 的米。
- 原型的 2D 平面 (x, y) 对应 Godot 的 (x, z)，高度是 y。
- Blender 用米，导出 glTF（+Y 向上，应用修改器）。仓鼠半径 0.16 米。

## 3. 资产即代码（tools/blender/）
```
tools/blender/
  build.py              命令行入口：--asset <名> / --category <类> / --all
  lib/style.py          调色板、材质命名、描边参数、全局风格参数
  lib/shapes.py         圆角盒、胶囊、倒角、细分、metaball/remesh 有机形体、布尔
  lib/rig.py            骨架模板（仓鼠、四足、昆虫）
  lib/anim.py           关键姿势、插值缓动、循环、挤压拉伸
  lib/export.py         glTF 导出设置
  lib/preview.py        预览渲染（游戏镜头 / 正面 / 侧面 / 转台）、图标渲染
  lib/gun_parts.py      枪械通用零件和细节件（螺丝、抛壳窗、贴花、警示条纹、爪印贴纸、背带环）
  assets/<类别>/<名称>.py  每个资产一个脚本，build(params) 生成；皮肤、颜色、等级等都是参数
  assets/env/env_zone_kit.py   批次 3 分区美术：冰箱、橱柜、沙发裙边、分区地面、41 种分区装饰
  assets/icons/icon_kit.py     全套图标（道具 / 宠物 / 强化 / 天赋 / 进化配件），只出 PNG 到 game/assets/icons/
```
- 运行方式：`blender --background --python tools/blender/build.py -- --asset chr_hamster`
- 输出：模型到 `game/assets/models/<类别>/`，预览图到 `review/previews/<类别>/`。一个脚本导出多件时可以用 `item_previews` 给每件单独出图。
- 图标：3D 模型直接渲染（3/4 视角、描边、透明底、256×256）。武器图标由武器脚本自己出（`wpn_<id>.png`），其余由 `icon_kit.py` 出：`gad_<道具>`、`pet_<宠物>`、`abl_<强化>`、`tal_<天赋>`、`evo_<配件类>_<a|b|c>`（进化路线按 `evolutions.json` 的 `attachmentType` 对应到配件图）。界面里统一用 `UiTheme.icon(名)` / `card_icon()` / `evo_icon()` 取。
- 好处：风格参数集中，改一处（比如描边粗细、调色板）就能整批重新生成。
- **质量要求**：
  - 不能有“默认几何体拼起来”的感觉。有机形体用细分 / metaball / remesh 后再整理；硬表面用倒角加加权法线。
  - 每个资产都要渲染预览图（近似游戏里的三渲二效果），自己看图检查剪影、比例、穿插，有问题先修再交。
  - 最终以 Godot 里的游戏镜头截图为准。

## 4. 材质约定
- Blender 里只放材质槽名和调色板 UV。Godot 导入脚本按材质名换成 toon 着色器：`M_toon_<部位>`、`M_metal`、`M_emissive_<色名>`、`M_glass`、`M_team`（运行时换队伍色）。
- 调色板贴图 `palette.png`，256×512（批次 3 从 256×256 扩大），16 列 × 32 行，每格 16×16 一个色块；上半部分（第 0～15 行）是固有色，下半部分是对应的自发光色。队伍色在第 6 / 7 行（运行时按 1/32 纵向偏移）、皮肤色和路线色按 1/16 横向偏移。颜色名 → 格子见 `palette.json`（Godot 端程序生成的网格用）。

## 5. 骨骼与动画
- 仓鼠骨架：root、pelvis、spine、head、ear_L/R、arm_L/R（2 节）、leg_L/R（2 节）、tail（2 节），挂点 weapon_socket、hat_socket、back_socket、face_socket。
- 武器 glb 里预留空节点作为配件挂点：`att_scope`、`att_muzzle`、`att_drum`、`att_tank`、`att_coil`、`att_radar`、`att_torch`、`muzzle`（枪口焰位置）、`grip_L` / `grip_R`（手的位置）。
- 动画清单和命名见 ASSET_LIST.md。Godot 里用 AnimationTree：下半身移动混合 × 上半身持枪姿势；开火后坐、受击、挤压拉伸、耳朵和尾巴的弹簧摆动在代码里叠加。

## 6. Godot 工程结构（game/ 就是工程根目录）
```
game/
  project.godot
  data/              数值数据（JSON，唯一来源）
  scripts/sim/       纯逻辑：单位、武器、进化、道具、伤害、AI、视野、听觉、兵线、建筑（不依赖渲染节点）
  scripts/view/      表现：模型、动画、特效、灯光、相机、音效
  scripts/ui/        界面
  scenes/            .tscn
  shaders/           toon.gdshader、outline.gdshader、特效着色器
  assets/            models / textures / audio / fonts / icons（由 tools/ 生成）
  tests/             headless 测试
```
- **逻辑和表现分离**：sim 可以在 headless 下跑整局（自动测试和以后的联机都靠它）。
- 批次 1 落地后的关键文件（详细说明见各文件开头注释）：
  - `scripts/sim/sim_world.gd`（一局的全部状态和规则，事件队列给表现层）、`sim_weapons.gd`（武器参数 = weapons.json + evolutions.json 的 effects）、`sim_cards.gd`、`sim_ai.gd`、`sim_map.gd`。
  - `scripts/view/match_view.gd`（60Hz 推进 sim + 事件分发）、`hamster_view.gd`、`unit_views.gd`、`map_view.gd`、`fx_system.gd`、`toon_materials.gd`（按材质名前缀换 toon 着色器）。
  - `scripts/ui/`（主题、HUD、主菜单、暂停、设置、结算）、`scripts/core/main.gd`（入口和命令行参数）、`scripts/core/capture.gd`（截图 / 帧率测试场景）。
  - `data/rules.json`：原型里写死的常数；`evolutions.json` 的 `effects`：进化效果（格式见 `_effectsDoc`）。
- 批次 2 新增：
  - sim：`sim_weapon_modes.gd`（火箭 / 榴弹 / 武士刀 / 喷火 / 电磁炮 / 激光这些不走普通子弹的开火方式）、`sim_gadgets.gd`（13 种道具 + AI 用道具的判断）、`sim_mobs.gd`（野怪营地、鼠王、宠物）、实体 `sim_mob.gd` / `sim_pet.gd` / `sim_decoy.gd`。
  - 表现：`world_fx.gd`（光束、刀光、火区、烟雾、冲击波、火箭、野怪 / 鼠王 / 宠物 / 诱饵 / 自动炮台等新实体的节点）、`b2_views.gd`、`shaders/beam.gdshader`；`hamster_view.gd` 里的强化挂件（`ACC` 表）。
  - 界面：`lobby.gd`（开局大厅）、`codex.gd` + `snapshot.gd`（图鉴 8 页 + 模型快照）、`settings_panel.gd`（3 页设置）、`player_input.gd`（键鼠 / 手柄 / 2P 方向键）。
  - 本地分屏：两个 SubViewport 共用主 3D 世界，每人一个 `GameCamera` + 一套 `Hud`；视野靠渲染层（蓝队第 2 位、红队第 3 位，相机 `cull_mask = 1 | 队伍位`），`MatchView.apply_mask()` 把几何体和点光 / 聚光放到“哪些本地队伍看得见”的层上。
- 固定逻辑帧 60Hz，渲染插值；随机数用带种子的 RNG，方便复现和联机。
- 大量重复物体（子弹、弹壳、小兵、装饰）用 MultiMesh 或对象池。
- 批次 3 新增：地图分区美术（`map_view.gd` 按 `map_layout.json` 的 `art` 分区铺地面、边界、装饰和区域灯光；地面、地毯和小装饰不投影）；建筑三阶段破损（模型里的 `dmg1` / `dmg2` / `wreck` 节点，阈值在 `rules.json` 的 `view.structDamage`）；鼠王出场演出和披风摆动（`b2_views.gd`）；新特效形状（冰晶、六边形、加号、火舌）、锯齿闪电和光柱（`fx_system.gd`、`world_fx.gd`）。

## 7. 渲染方案
- toon.gdshader：色阶明暗、冷紫阴影色、边缘光、队伍色、受击闪白、溶解消失。
- 描边：反向外壳（next_pass 材质，按屏幕空间控制线宽）。
- 黑暗：环境光压得很低，场景亮度来自实时光源（手电 SpotLight3D、台灯 OmniLight3D、火焰和爆炸临时光）。手电光锥另外叠一层假体积光网格。
- 视野：由 sim 计算每队的可见集合，表现层对不可见的敌人直接隐藏（和原型一致）。
- 后处理：辉光、色调映射、暗角、受伤时轻微色差。手机档位关闭昂贵效果。
- 两套画质：PC 用 Forward+；手机用 Mobile 渲染器。动态光数量、阴影、后处理按档位裁剪。

## 8. 音频（tools/audio/）
- 用 Python 离线合成音效，参照原型 `reference/prototype/src/n1b.js` 的枪声配方（瞬态 + 主体 + 尾音 + 混响 + 弹壳），每种至少 3 个变体，导出 OGG。
- 可以加入 CC0（公有领域）素材补足质感；来源和授权写进 `game/assets/audio/CREDITS.md`。不用任何不可商用的素材。
- Godot 里用随机变体和音高、3D 衰减，分 SFX / 音乐 / UI 三条总线。
- 音乐（批次 3）：`tools/audio/music.py --all` 合成 6 首（menu / match / rush / boss 循环曲，victory / defeat 短曲），乐谱写在脚本里、固定种子；`--analyze` 出频谱图和响度数据到 `review/batch3/audio/`。游戏里 `Audio.play_music()` 交叉淡入淡出，对局按状态切 match / rush / boss。

## 9. 测试
- **sim 测试（headless）**：全部 18 把武器 × 各进化等级的 AI 对局，跑 2 分钟无报错（原型就是这样压力测试的）；同种子结果一致；升级卡规则（不出满级路线、换武器清零等）。
  - 现状（批次 2～3）：`tests/test_*.gd`，`godot --headless --path game -s res://tests/run_all.gd`。武器 × 路线 × 等级共 504 种组合、13 种道具、野怪 / 鼠王 / 宠物 / 天赋、切片和完整地图对局都能分出胜负。
- **表现层冒烟（headless，带自动加载）**：`tests/view_smoke.tscn` 把 18 把武器 × 进化、13 种道具、野怪鼠王宠物、双人分屏的表现层全部跑一遍，日志里不能有 SCRIPT ERROR。`-s` 脚本模式下没有自动加载，所以用到 Settings / Audio 的测试要写成场景。
- **截图测试（窗口模式，headless 不渲染画面）**：固定场景、固定镜头批量截图到 `review/`，用来自查和给导演审阅。
- **性能**：固定场景记录帧时间。目标 PC 1080p 稳 60（争取 120），中端手机稳 30（争取 60）。

## 10. 构建与发布
- `export_presets.cfg`：Windows、Linux（Steam Deck）、Android、iOS。
- Steam 用 GodotSteam 插件接入；Android 签名用的 keystore 由用户保管；iOS 构建需要 Mac + Xcode。
- 需要用户本人做的事：注册开发者账号并付费、提供签名证书、在真机上测试。
