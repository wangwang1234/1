# 合并后主线验证（2026-10-11，UTC）

## 验证基线与环境

- 仓库：`wangwang1234/1`，目标主线 `claude/new-session-w3yl0l`。
- 开工先执行 `git fetch origin claude/new-session-w3yl0l`，从最新提交 `823be47b4c4df9f49a2b8a9539a83e493a59d073` 新建 `codex/verify-merge`。未使用预置旧提交 `64fb52a`，未使用导出包恢复源码。
- 已读 `CLAUDE.md`、`review/merge_lan/REPORT.md`、`review/lan10/REPORT.md`、`docs/LAN.md` 和 `docs/ROADMAP.md`。
- Debian 13，CPU 配额约 2 核，内存上限 8 GiB；Python 3.12.14。
- 官方 Linux Godot：`4.7.2.stable.official.ed1daf0bf`。下载自 Godot 官方 `godotengine/godot-builds` 的 `4.7.2-stable` Release，工作目录的 `bin/godot` 放到 PATH 前端；未使用预置 4.6.3。
- 官方 ZIP 的 SHA-256：`cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`（本次下载的指纹）。
- 窗口环境：Xvfb / xvfb-run、Mesa Vulkan 25.0.7，Forward+ 使用 llvmpipe；依赖解压在工作目录，没有修改系统安装。Godot 的配置、缓存和用户数据使用可写的 XDG 工作目录。

## 最终测试结果

以下自动结果来自本分支全部源码修复后的最终顺序重跑；导入、LAN、全量退出码均为 0。

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| `godot --headless --path game --import` | 通过，退出码 0，无 `ERROR` / `SCRIPT ERROR` | [导入日志](logs/import_final.log) |
| `tools/test.sh` | **通过**，退出码 0，最后一行 `全部通过` | [完整日志](logs/full_final.log) |
| 全量 sim | **145 项，失败 0 项**，565.2 秒 | 完整日志包含搜房刷新、技能与辅助瞄准网络输入等断言 |
| 表现层冒烟 | 2 分钟 AI 对局、18 把武器及进化 / 技能、13 种道具、野怪 / 鼠王 / 宠物、双人分屏均通过 | `tools/test.sh` 检查子进程日志 |
| 主菜单冒烟 | 通过 | `tools/test.sh` |
| `python3 tools/test_lan_resume.py` | **15 项全部通过**，退出码 0，最后两行 `ten passed`、`lobby passed` | [完整输出](logs/lan_final.log)、[40 条成功回执](integration.json) |
| 双窗口大厅检查 | **通过**：菜单、附近发现、创建 / 加入、蓝红人数、准备、开始按钮 | [附近房间](nearby_room.png)、[房主大厅](lobby_host.png)、[客户端大厅](lobby_client.png)、[双方准备](lobby_ready.png) |
| 双窗口进入对局、右键技能、Tab | **未完成验收**：默认 Forward+ 的完整地图与中路小图加载均出现客户端离开 | [完整地图掉线](full_map_disconnect.png)、[小图房主](slice_host_loading.png)、[小图客户端](slice_client_disconnect.png)；详情见下 |

冒烟测试覆盖全部 18 把保留武器的开火 / 进化代码，并直接调用开放 10 把的技能；大厅仍只开放 10 把。这些 headless 检查不等于真实窗口右键输入验收。

全量测试最终尾部：

```text
测试：145 项，失败 0 项，用时 565.2 秒
== 表现层冒烟：2 分钟 AI 对局 ==
表现层冒烟：通过
== 表现层冒烟：18 把武器 × 进化、13 种道具、野怪鼠王宠物、双人分屏 ==
武器 / 道具 / 分屏冒烟：通过
== 主菜单冒烟 ==
主菜单冒烟：通过
全部通过
```

日志仍包含与首轮相同的退出资源统计（648 ObjectDB 实例、8 个资源）；仓库原有 `check_log` 会过滤无声卡和退出资源统计，其余 `ERROR` / `SCRIPT ERROR` 均判失败。完整日志保留了这些原始输出。

最终联机输出完整 15 行：

```text
resume passed
expiry passed
invalid passed
mismatch passed
quality passed
ui passed
ghost passed
pending passed
malformed passed
stress passed
return passed
return_ui passed
actions passed
ten passed
lobby passed
```

十人回归的普通客户端收到 187～269 个状态快照、各自移动 1339～2892 距离；退出玩家收到 45 个快照后离开，房主断言九名真人及一名 AI，通过后等所有客户端完成再退出。压力测试客户端收到 1863 个状态快照、恢复 1860 个分片缺失快照，经历一次自动重连；特效峰值 8101 个 / 46 批，未超过 8192 个 / 64 批上限。详细数字均来自最终修复后的 `integration.json`（40 条回执全部 `ok: true`）；房主采样平均状态包 13594 字节、每客户端上行约 2124 kbps。

## 发现并修复的问题

### 失焦通知在场景挂接期间同步创建暂停菜单（联机 / UI）

实际窗口日志捕获到 `Main._notification()` 在场景添加子节点期间调用 `_on_pause()`，同步添加暂停菜单失败。将失焦处理改成 `_on_pause.call_deferred()`，下一轮再创建暂停菜单；原有暂停条件和联机不中断模拟的行为保留。

`game/tests/lan_resume_peer.gd` 的 UI 场景增加永久回归：在 Main 子节点进入场景树期间触发失焦通知。旧实现确实报错，修复后 `LAN_ONLY=ui` 通过，并继续验证两次重连和第二局。完整失败输出见 [失焦回归日志](logs/focus_before.log)。

```text
ERROR: Parent node is busy setting up children, `add_child()` failed. Consider using `add_child.call_deferred(child)` instead.
   at: add_child (scene/main/node.cpp:1721)
   GDScript backtrace (most recent call first):
       [0] _on_pause (res://scripts/core/main.gd:223)
       [1] _notification (res://scripts/core/main.gd:274)
       [2] _enter_tree (res://tests/lan_resume_peer.gd:44)
```

### 低帧率挤压 / 后坐弹簧发散（画面）

实际窗口在软件渲染低帧率下，主菜单仓鼠反复被压扁、拉长，见 `menu_before.png`。`HamsterView.sync()` 的显式弹簧积分直接使用帧间隔；帧间隔较大时速度发散，体型只剩上下限之间的跳变，开火后模型后坐位置也会发散。

- `game/scripts/view/hamster_view.gd`：仅将挤压和后坐积分步长限制到 `0.05` 秒，与现有耳尾弹簧一致；正常 60 FPS 的积分不变。
- `game/tests/view_smoke.gd`：加入拾取 / 开火后的 60 FPS、5 FPS、一秒卡帧回归；检查数值有限、有界并恢复正常体型及后坐位置。这是保留的回归测试，不是一次性截图脚本。

修复前的完整错误片段：

```text
ERROR: 低帧率弹簧发散：dt=0.2，sq=-1.82，kick=38.0799999999565
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _low_fps_springs (res://tests/view_smoke.gd:69)
       [1] _solo (res://tests/view_smoke.gd:30)
       [2] _ready (res://tests/view_smoke.gd:9)
```

### 十人回归依赖各进程模拟时钟同步（测试时序）

在 CPU 配额受限的环境，各 Godot 进程的模拟时间推进速度不同。旧测试允许客户端达到自己的 14 秒就退出，而房主在自己的 10 秒检查九个真人席位、18 秒关闭。复现了两个方向的误报：客户端先退出导致房主人数检查失败；房主先关闭导致仍在检查移动的客户端报重连超时。独立运行也能复现，不只是首轮并行负载。

`game/tests/lan_multi_peer.gd` 的修正只影响测试：

- 房主完成 AI 接管和九个真人席位断言后，通过测试场景专用可靠 RPC 发出检查点；普通客户端等待检查点再结束。
- 房主等待其余客户端完成并离开，再结束自己的进程。
- 退出玩家仍至少运行 4 秒且收到超过 30 个快照；普通客户端仍至少运行 14 秒、收到超过 120 个快照、移动超过 60。保留总超时和 Python 进程超时，不降低断言门槛。
- 未修改生产联机协议、房间容量、状态同步或玩法逻辑。

针对性 `LAN_ONLY=ten python3 tools/test_lan_resume.py` 已通过；九个客户端各自移动、掉线角色由 AI 接管、超员拒绝仍实际执行。

各轮失败的完整 Python 错误片段和十人进程回执见 `logs/`，最终完整套件结果另列于上方。

独立运行时，房主通过但先退出造成客户端失败的完整片段：

```text
Traceback (most recent call last):
  File "/workspace/1/tools/test_lan_resume.py", line 118, in <module>
    assert len(rows) == 1 and rows[0]["ok"], path.name + "\n" + text[-4000:]
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError: ten_client3.log
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[audio] 载入 74 种音效
RECEIPT {"case":"ten","elapsed_seconds":14.566666666667,"idx":3,"match_seconds":7.36666666666665,"ok":false,"reason":"session ended: 重连超时：房主可能已退出，请重新加入房间","role":"client","snapshots":281}
```

### 返回房间的快照检查边界（测试时序）

完整回归中还复现了一次 `return_ui` 边界：已正确返回大厅并进入第二局，客户端在一秒检查点累计收到恰好 20 个快照，旧测试要求超过 20 个，因而误报失败。`game/tests/lan_resume_peer.gd` 的返回房间场景改为等待客户端满足原来的快照数量断言，房主等待客户端离开后再关闭；仍验证仅返回一次、没有续局重连、第二局更换凭据，保留总超时。生产代码未改。

完整失败片段：

```text
Traceback (most recent call last):
  File "/workspace/1/tools/test_lan_resume.py", line 84, in <module>
    assert code == 0 and not errors, text[-4000:]
           ^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError: Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[audio] 载入 74 种音效
RECEIPT {"case":"return","checks":20,"discarded_events":0,"elapsed_seconds":3.96666666666666,"lobby_returns":1,"matches":2,"max_event_count":0,"max_event_frames":0,"ok":false,"reason":"host returned during reconnect and both played second match","repaired_snapshots":0,"resumes":0,"role":"client","snapshots":20}
```

## 首轮验证的环境问题

### 导入：沙箱网络和配置目录

首次导入退出码为 0，但出现以下完整错误片段，不能据此判定导入干净通过：

```text
ERROR: Condition "_sock == -1" is true. Returning: FAILED
   at: _inet_open (drivers/unix/net_socket_unix.cpp:288)
ERROR: Condition "err != OK" is true. Returning: ERR_CANT_CREATE
   at: listen (core/io/tcp_server.cpp:56)
ERROR: Can't save resource to empty path. Provide non-empty path or a Resource with non-empty resource_path.
   at: save (core/io/resource_saver.cpp:108)
ERROR: Error saving editor settings to 
   at: save (editor/settings/editor_settings.cpp:1525)
```

原因是执行沙箱未启用网络 socket、默认编辑器配置目录不可写。启用执行权限并将 `XDG_CONFIG_HOME` / `XDG_CACHE_HOME` / `XDG_DATA_HOME` 指向工作目录后，重跑导入退出码 0，无上述错误；无需修改游戏源码。

### 全量测试：并行搜房端口冲突

首轮错误地并行执行了全量、联机和窗口验证。全部 145 项 sim 测试中仅搜房测试失败，因为 `start_host(row, 0)` 实际使用默认发现端口 UDP 28766，已被另一联机房主占用。完整片段：

```text
ERROR: Condition "!is_open()" is true. Returning: FAILED
   at: get_socket_address (drivers/unix/net_socket_unix.cpp:762)
   GDScript backtrace (most recent call first):
       [0] test_discovery_refreshes_map_and_version (res://tests/test_network.gd:132)
       [1] _init (res://tests/run_all.gd:39)
ERROR: Condition "!is_open()" is true. Returning: FAILED
   at: get_socket_address (drivers/unix/net_socket_unix.cpp:762)
   GDScript backtrace (most recent call first):
       [0] test_discovery_refreshes_map_and_version (res://tests/test_network.gd:132)
       [1] _init (res://tests/run_all.gd:39)
  FAIL test_network.test_discovery_refreshes_map_and_version
       - discovery host
       - map and version changes notify UI：期望 2，实际 0
测试：145 项，失败 1 项，用时 1689.5 秒
sim 测试：失败
```

此轮在 sim 阶段退出，后续表现层和主菜单冒烟没有执行。最终改为顺序验证，不为本次验证的端口占用修改生产代码。首轮完整日志见 `logs/full_initial.log`。

## 窗口流程与检查

先看大厅截图，再看掉线截图；`menu_before.png` / `menu_after.png` 对照低帧率弹簧修复前后。截图来自实际窗口鼠标操作，不是重建 UI。

| 实际操作 | 观察结果 |
| --- | --- |
| 同机两个默认 Forward+ 实例，主菜单 → 局域网联机 | 两端均可进入大厅 |
| 房主创建完整地图房间，另一实例从“附近房间”直接加入 | 发现信息为 1/10、可加入；加入后房间 2/10 |
| 客户端切到红队 | 两端均显示蓝队 1/5、红队 1/5；此前同蓝队时显示蓝队 2/5、红队 0/5 |
| 双方点击准备 | 两端准备勾选，房主“开始对局”亮起 |
| 房主点击开始，完整地图 | 房主短暂出现对局画面，客户端返回离线大厅，提示“房主已离开，连接结束”；未形成可操作的双端对局 |
| 关闭两端后，以 640×360 默认 Forward+ 再走中路小图流程 | 正确显示房间 2/6、蓝红各 1/3、双方准备；房主加载到 HUD 0:00，客户端仍返回大厅，未完成同步开始 |
| 右键武器技能、Tab 比分板 | **未完成真实双窗口验证**。自动技能 / 网络输入断言通过，但不能替代这两项手动输入检查 |

默认渲染器窗口日志只打印引擎 / GPU / 音效信息，首次房主另外打印了上述失焦竞态；掉线原因在大厅状态和截图里，日志没有更详细的网络错误堆栈。完整保留 [首次房主日志](logs/manual_initial_host.log)、[首次客户端日志](logs/manual_initial_client.log)、[最终小图房主日志](logs/manual_final_host.log)、[最终小图客户端日志](logs/manual_final_client.log)。小图重试中没有 `ERROR` / `SCRIPT ERROR`。

这台机器没有物理 GPU，两实例共享约两核 CPU，软件 Vulkan 窗口约 1～3 FPS，场景加载明显很慢。长帧 / 冷编译与 ENet 加载掉线相关，但**尚未证明具体原因，也未证明目标 GPU 上不会发生**。没有为了让云端窗口通过而增大生产超时或改动加载协议。需要导演或 Claude 在目标 GPU 上复查完整地图双端加载；若仍掉线，优先记录各端加载耗时与网络断开时点，再定位联机问题。这是本轮保留的未解决问题。

另试过命令行 `--rendering-method gl_compatibility` 的两个窗口，希望减少软件渲染负载；这不是项目默认的验收配置。虽然大厅流程可走通，画面出现大块过曝，完整地图报阴影模式不支持和实例变量上限，立即停用，**不计为画面或对局通过**。没有修改项目渲染配置来适配该诊断尝试。完整日志见 [兼容房主](logs/manual_compat_host.log)、[兼容客户端](logs/manual_compat_client.log)，重复错误的完整单次片段如下：

```text
ERROR: Too many instances using shader instance variables. Consider increasing rendering/limits/global_shader_variables/buffer_size in the Project Settings. Maximum items supported by this hardware is: 4096.
   at: global_shader_parameters_instance_allocate (drivers/gles3/storage/material_storage.cpp:2101)
ERROR: Dual paraboloid shadow mode not supported in the Compatibility renderer. Please use CubeMap shadow mode instead.
   at: _render_shadow_pass (drivers/gles3/rasterizer_scene_gles3.cpp:2300)
```

## 我替导演做的决定

- 仅修复已实际复现的画面弹簧、失焦 UI 竞态，以及联机回归自身的时序；不调整玩法数值，不扩大功能范围。
- 全量 / 联机 / 窗口检查顺序执行，保留首轮失败记录。
- 软件渲染窗口未完成的两项输入检查如实记录，留给目标 GPU 验收；本轮不宣布可以打包。

## 下一步

1. Claude 审阅本 PR 的两处生产修复及测试时序修正，按报告复查完整地图双窗口加载。
2. 目标 GPU 上完成右键技能、Tab 比分板，以及跨电脑附近发现 / 10 人实机验证。
3. 导演确认测试与手动结果后，按既定 0.3.7 流程导出 Windows / macOS 并上传 Release。

## 边界与后续

- 玩法 / 内容代码和数值未修改。本次未发现需要移交 Claude 的玩法失败；最终以测试结果表为准。
- 同机 Xvfb 检查不能代表跨电脑 Wi-Fi 广播、Windows / macOS 真机联机或目标 GPU 帧率。既有的房主约 18 Mbps 上行、无房主迁移、联机大厅无 AI 难度选择等限制仍需真机验收。
- 本轮不导出安装包、不建立 Release；待导演确认验证结果后另行打包。
- 一次性命令、测量和窗口控制材料留在仓库外的 `work/`，不提交。仅提交原始源码中的小范围画面 / UI 修复、联机测试时序修正和永久回归测试、中文报告和当批审阅证据。
