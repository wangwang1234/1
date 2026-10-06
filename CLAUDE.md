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
  - 游戏参数（写在 `--` 之后）：`--match` `--autoplay` `--mode full|slice`（默认 full 完整地图）`--seed N` `--skin gold|pudding|silver|stripe` `--weapon <武器 id>`（18 把，见 `weapons.json`）`--duo`（本地双人分屏）`--p2 pad|keys2`（2P 用手柄 / 方向键）`--quit-after 秒`
- 全部测试：`tools/test.sh`（sim 测试 + 表现层 headless 跑 2 分钟 AI 对局 + `tests/view_smoke.tscn`（18 把武器 × 进化、13 种道具、野怪鼠王宠物、双人分屏）+ 主菜单冒烟，日志里有 SCRIPT ERROR 即失败）
  - 只跑 sim 测试：`godot --headless --path game -s res://tests/run_all.gd`（`-- --only 名称` 只跑一个文件）
  - 注意：`-s` 脚本模式下没有自动加载（Settings / Audio / Capture），用到它们的表现层测试要写成场景（`godot --headless --path game res://tests/view_smoke.tscn`）
- 生成资产：`tools/assets.sh`（全部模型 + 预览图 + 音效 + 重新导入）；单个模型 `tools/assets.sh chr_hamster`
  - 等价于 `blender --background --python tools/blender/build.py -- --asset <名称>`（`--all` 全部，`--list` 列出）；没有显示器时要套 `xvfb-run -a`（EEVEE 需要）
- 生成音效：`python3 tools/audio/build.py --all`
- 改了调色板 / 模型 / 音效后让 Godot 重新导入：`godot --headless --path game --import`
- 截图（窗口模式；无显示器时自动套 xvfb-run）：`tools/capture.sh <场景> <输出目录> [分辨率] [参数]`
  - 场景：`menu` `style` `gameplay` `cards` `loadout` `lineup` `screens` `codex` `arsenal` `b2world` `ui2` `duo` `perf`，说明见 `game/scripts/core/capture.gd` 开头
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
- GitHub：远程 `origin` = github.com/wangwang1234/1，开发分支 `claude/new-session-w3yl0l`（`git push -u origin claude/new-session-w3yl0l`）

## 第一次会话
1. 检查 Godot、Blender、Python、git 是否可用；缺什么就告诉导演怎么安装（这属于需要导演操作的事），装好后继续。
2. 初始化 git，提交交接包。
3. 直接开始批次 1。

## 当前进度
- 已完成：批次 0（交接包）；**批次 1 垂直切片**（2026-10，审阅包 `review/batch1/`，汇报 `review/batch1/REPORT.md`，Windows 包 `release/manzai_batch1_win64.zip`）。
  - 工具链：Godot 4.7.2（源码编译）、Blender 资产管线、音频合成、截图 / 录屏 / 帧率测试、Windows 导出、`tools/*.sh|.bat`。
  - 内容：仓鼠（4 皮肤、19 动作、表情）、手枪 / AK-47 / 霰弹枪 + 3×3 条进化路线（逻辑 + 配件外观）、小兵、炮台、鼠窝、场景物件和装饰、39 种音效。
  - 玩法：切片模式（全宽中路带、3 对 3、中路炮台护盾规则、第 5 分钟加速决战）；全图模式（`--mode full`，三条兵线 5 对 5）也能跑，地图按 map_layout 自动拼装，但野怪、鼠王等是批次 2 的内容。
  - 界面：主菜单、HUD、升级卡、暂停、设置、结算。
- 等导演：试玩反馈（风格、手感、节奏）；在目标电脑上跑 `帧率测试.bat` 把 `perf` 文件夹发回来（容器里没有显卡，测不了真实帧率）。
- 下一步：批次 2 全部系统（先处理导演对批次 1 的反馈）。
- 约定 / 坑：
  - 数值全在 `game/data/*.json`；原型里写死的常数在 `rules.json`；进化效果格式见 `evolutions.json` 的 `_effectsDoc`；切片专用调整在 `rules.json` 的 `match.slice`。
  - 改了调色板 / 模型 / 音效后要 `godot --headless --path game --import`，否则运行时还是旧资源。
  - 特效颜色在代码里按 sRGB 写，着色器里转线性；MultiMesh 实例色不会自动转换。
  - SimWorld 用完要 `dispose()`（实体间有循环引用），MatchView 退出时已自动调用。
  - 截图在软件渲染下很慢：长时间快进用 Capture 的 `_wait(秒, true)`（关 3D 渲染只跑逻辑）。
  - 软件渲染 + 实时模式下，开局 3 秒内就退出（如 `--quit-after 3`）会卡在引擎退出流程（等后台着色器编译）；自动化脚本请用 `--fixed-fps` 或 headless，或者 `--quit-after` 给到 10 秒以上。
