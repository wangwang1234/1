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

## 常用命令（已在本机验证；Windows 下把 `tools/xxx.sh` 换成 `tools\xxx.bat`）
- 运行游戏：`tools/run.sh`（= `godot --path game`）；直接开局 `tools/run.sh --match --weapon ak47`；AI 观战 `tools/run.sh --match --autoplay`
  - 游戏参数（写在 `--` 之后）：`--match` `--autoplay` `--mode slice|full` `--seed N` `--skin gold|pudding|silver|stripe` `--weapon pistol|ak47|shotgun` `--quit-after 秒`
- 全部测试：`tools/test.sh`（sim 测试 + 表现层 headless 跑 2 分钟 AI 对局 + 主菜单冒烟，日志里有 SCRIPT ERROR 即失败）
  - 只跑 sim 测试：`godot --headless --path game -s res://tests/run_all.gd`（`-- --only 名称` 只跑一个文件）
- 生成资产：`tools/assets.sh`（全部模型 + 预览图 + 音效 + 重新导入）；单个模型 `tools/assets.sh chr_hamster`
  - 等价于 `blender --background --python tools/blender/build.py -- --asset <名称>`（`--all` 全部，`--list` 列出）；没有显示器时要套 `xvfb-run -a`（EEVEE 需要）
- 生成音效：`python3 tools/audio/build.py --all`
- 改了调色板 / 模型 / 音效后让 Godot 重新导入：`godot --headless --path game --import`
- 截图（窗口模式；无显示器时自动套 xvfb-run）：`tools/capture.sh <场景> <输出目录> [分辨率] [参数]`
  - 场景：`menu` `style` `gameplay` `cards` `loadout` `lineup` `perf`，说明见 `game/scripts/core/capture.gd` 开头
  - 例：`tools/capture.sh style review/x 1920x1080 --n 6 --from 30 --every 5`
- 录屏：`tools/record.sh out.mp4 [秒数] [分辨率] [种子]`（Godot Movie Maker 固定 30 帧 + ffmpeg 转码）
- 帧率测试：`tools/capture.sh perf <目录> 1920x1080 --dur 60` → `perf.json` / `perf.csv`；导出版里双击 `帧率测试.bat`
- 导出 Windows：`tools/export.sh windows`（= `godot --headless --path game --export-release "Windows Desktop" <绝对路径>/build/win/manzai.exe`）

## 环境（2026-10 第一次会话填写；云端容器，无 GPU）
- 操作系统：Ubuntu 24.04（Linux 容器，4 核，无显示器、无声卡、无 GPU）
- Godot：4.7.2-stable，**从源码编译**（官方下载被网络策略挡住，git 克隆可用）
  - 编辑器：`/home/user/godotengine/godot/bin/godot.linuxbsd.editor.x86_64`，软链到 `/usr/local/bin/godot`
  - Windows 导出模板（同样从源码交叉编译，mingw）：`~/.local/share/godot/export_templates/4.7.2.stable/windows_release_x86_64.exe`
  - 窗口模式靠 `xvfb-run` + Mesa lavapipe（软件 Vulkan，Forward+ 能跑但 1080p 只有 1–3 帧/秒）：截图一律加 `--fixed-fps`，画面和机器快慢无关
- Blender：4.0.2，`/usr/bin/blender`（apt 安装；内置 Python 3.12 + python3-numpy）
- Python：3.11（`python3`；音频脚本用 numpy / scipy，审阅拼图用 Pillow）
- ffmpeg 6.1（音效转 OGG、录屏转码）
- GitHub：本会话 push 返回 403（Claude 的 GitHub 权限没装到这个仓库），提交都在本地分支 `claude/new-session-w3yl0l`

## 第一次会话
1. 检查 Godot、Blender、Python、git 是否可用；缺什么就告诉导演怎么安装（这属于需要导演操作的事），装好后继续。
2. 初始化 git，提交交接包。
3. 直接开始批次 1。

## 当前进度
- 已完成：批次 0（交接包：设计文档、美术规范、管线规范、数值数据、可玩原型）。
- 下一步：批次 1 垂直切片。
