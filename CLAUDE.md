# 满载而鼠 — Claude Code 工作规则

## 项目
俯视角 3D 三渲二红蓝对战射击：两队仓鼠在黑暗的地图里推兵线、拆炮台、打爆对方鼠窝；局内肉鸽成长（武器进化 + 通用强化 + 战术道具）。
- 引擎 Godot 4（GDScript）。**全部资产由你用脚本生成**：模型和动画用 Blender Python 脚本，音效和音乐用音频脚本。
- 发布目标：Steam（PC）+ 手机安装版（Android / iOS）。
- 品质目标：画面、UI、手感、细节对标《逃离鸭科夫》的完成度；风格是我们自己的三渲二。
- 导演（用户）负责方向和验收，其余一切由你完成。

## 文档地图（开始一个批次前，先读和这个批次相关的部分）
- `docs/ROADMAP.md` — 批次划分和验收标准（每次会话先看这里）
- `docs/GDD.md` — 玩法规则和全部设计
- `docs/ART_BIBLE.md` — 美术风格（生成任何资产前对照）
- `docs/PIPELINE.md` — 资源管线、工程结构、渲染、音频、测试、构建
- `docs/ASSET_LIST.md` — 资产清单和优先级
- `docs/PROTOTYPE_PORTING.md` — 原型代码对照表
- `game/data/*.json` — 数值的唯一来源
- `reference/prototype/manzai-ershu-pvp.html` — 可玩原型（浏览器打开即可），行为和手感的参照

## 工作方式（最重要）
- 导演希望**一口气推进大量内容**。每次会话以 ROADMAP 里的一个批次为单位连续工作：先把批次拆成任务清单，然后逐项做完，中途不要为小决定停下来问。
- 遇到小的不确定，按文档的精神做合理决定，记进批次汇报的“我替你做的决定”一栏。
- **只有这些情况才停下来问导演**：
  - 要改变文档里已经确定的方向；
  - 需要导演本人操作（注册账号、付费、安装软件、真机测试）；
  - 同一个问题连续 3 次尝试仍无法解决。
- 每个批次结束必须交付：
  1. 自动测试全部通过；
  2. 审阅包 `review/<批次名>/`：截图、截图序列或录屏、资产预览图、性能数据；
  3. 中文汇报 `review/<批次名>/REPORT.md`：做了什么、先看哪几张图、我替你做的决定、已知问题、下一批计划；
  4. git 提交。
- 生成任何美术资产后，必须渲染预览图并自己看图检查（剪影、比例、穿插、风格一致），明显的问题先自己修好再交。
- 每个批次结束时更新本文件的“当前进度”。
- 和导演交流一律用中文。

## 代码规范
- 数据驱动：数值从 `game/data/*.json` 读取，代码里不写死数值。
- 逻辑（`scripts/sim`）和表现（`scripts/view`、`scripts/ui`）分离；sim 必须能在 headless 下跑完整局。
- 固定逻辑帧 60Hz + 渲染插值；随机数用带种子的 RNG。
- 文件和节点命名用 snake_case；场景和脚本同名同目录。
- 每个系统都要有 headless 测试；新武器、新道具上线前跑全量 AI 对局测试。
- 只用自己生成的，或 CC0、OFL 等可商用授权的素材，来源写进 CREDITS。

## 常用命令（第一次会话时按本机实际情况补全并验证）
- 运行游戏：`godot --path game`
- headless 测试：`godot --headless --path game -s res://tests/run_all.gd`
- 生成资产：`blender --background --python tools/blender/build.py -- --asset <名称>`（`--all` 生成全部）
- 生成音效：`python tools/audio/build.py --all`
- 截图（必须窗口模式，headless 不渲染画面）：`godot --path game -- --capture <场景> --out review/...`
- 导出 Windows：`godot --headless --path game --export-release "Windows Desktop" ../build/win/manzai.exe`

## 环境（第一次会话时填写）
- 操作系统：
- Godot 版本和路径：
- Blender 版本和路径：
- Python 版本：

## 第一次会话
1. 检查 Godot、Blender、Python、git 是否可用；缺什么就告诉导演怎么安装（这属于需要导演操作的事），装好后继续。
2. 初始化 git，提交交接包。
3. 直接开始批次 1。

## 当前进度
- 已完成：批次 0（交接包：设计文档、美术规范、管线规范、数值数据、可玩原型）。
- 下一步：批次 1 垂直切片。
