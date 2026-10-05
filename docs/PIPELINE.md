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
  assets/<类别>/<名称>.py  每个资产一个脚本，build(params) 生成；皮肤、颜色、等级等都是参数
```
- 运行方式：`blender --background --python tools/blender/build.py -- --asset chr_hamster`
- 输出：模型到 `game/assets/models/<类别>/`，预览图到 `review/previews/<类别>/`。
- 好处：风格参数集中，改一处（比如描边粗细、调色板）就能整批重新生成。
- **质量要求**：
  - 不能有“默认几何体拼起来”的感觉。有机形体用细分 / metaball / remesh 后再整理；硬表面用倒角加加权法线。
  - 每个资产都要渲染预览图（近似游戏里的三渲二效果），自己看图检查剪影、比例、穿插，有问题先修再交。
  - 最终以 Godot 里的游戏镜头截图为准。

## 4. 材质约定
- Blender 里只放材质槽名和调色板 UV。Godot 导入脚本按材质名换成 toon 着色器：`M_toon_<部位>`、`M_metal`、`M_emissive_<色名>`、`M_glass`、`M_team`（运行时换队伍色）。
- 调色板贴图 `palette.png`，256×256，每格 16×16 一个色块；上半部分是固有色，下半部分是自发光色。

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
- 固定逻辑帧 60Hz，渲染插值；随机数用带种子的 RNG，方便复现和联机。
- 大量重复物体（子弹、弹壳、小兵、装饰）用 MultiMesh 或对象池。

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

## 9. 测试
- **sim 测试（headless）**：全部 18 把武器 × 各进化等级的 AI 对局，跑 2 分钟无报错（原型就是这样压力测试的）；同种子结果一致；升级卡规则（不出满级路线、换武器清零等）。
- **截图测试（窗口模式，headless 不渲染画面）**：固定场景、固定镜头批量截图到 `review/`，用来自查和给导演审阅。
- **性能**：固定场景记录帧时间。目标 PC 1080p 稳 60（争取 120），中端手机稳 30（争取 60）。

## 10. 构建与发布
- `export_presets.cfg`：Windows、Linux（Steam Deck）、Android、iOS。
- Steam 用 GodotSteam 插件接入；Android 签名用的 keystore 由用户保管；iOS 构建需要 Mac + Xcode。
- 需要用户本人做的事：注册开发者账号并付费、提供签名证书、在真机上测试。
