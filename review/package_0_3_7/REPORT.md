# 0.3.7 Windows / macOS 打包报告（2026-10-12）

## 源码与确认

导演确认现有验证结果并要求开始打包，随后明确批准先合并 PR #6。

- PR #6 已合并到默认主线 `claude/new-session-w3yl0l`，合并提交 `c384c78e4e2855400c9a734ebc85797bce09fbfe`。
- 合并后执行 `git fetch`，从该最新主线新建 `codex/package-0.3.7`，未使用旧副本或导出包恢复源码。
- 打包前重读 `CLAUDE.md`（AI 协作 / 当前进度）、`review/merge_lan/REPORT.md`、`review/lan10/REPORT.md`、`docs/LAN.md`。
- 游戏源码与上述主线提交一致。本分支仅更新随包说明、CLAUDE 进度及打包审阅材料；不修改功能代码。
- 继承已验证的官方 Godot 4.7.2-stable：145 项 sim 零失败、全量末行“全部通过”、15 项 LAN 回归全通过，详见 [验证报告](../verify_merge/REPORT.md)。本次不重复无代码变化的完整对局测试。

## 模板与导出

从官方 `godotengine/godot-builds` Release 下载 `Godot_v4.7.2-stable_export_templates.tpz`（1281349702 字节），压缩包内 `templates/version.txt` 为 `4.7.2.stable`。读取 ZIP 内条目时校验 CRC，将 `windows_release_x86_64.exe` 与 `macos.zip` 放到：

```text
~/.local/share/godot/export_templates/4.7.2.stable/
```

模板文件的大小与 SHA-256 见 [templates.json](templates.json)。执行环境 XDG 数据目录使用指向上述模板目录的链接。

| 步骤 | 结果 | 日志 |
| --- | --- | --- |
| `godot --headless --path game --import` | 退出码 0，无 ERROR / SCRIPT ERROR | [import.log](logs/import.log) |
| `tools/export.sh windows` | 退出码 0，无 ERROR / SCRIPT ERROR，生成 `build/win/manzai.exe` 并附带说明 / .bat | [Windows 导出日志](logs/export_windows.log) |
| `tools/export.sh mac` | 退出码 0，无 ERROR / SCRIPT ERROR，生成 `build/mac/manzai.zip` | [Mac 导出日志](logs/export_mac.log) |

日志中的嵌入 ICU 提示保留；编辑器与导出模板均来自同一官方版本。本次未使用自编译模板。

## 两个安装包

| 文件 | 字节数 | 压缩包检查 |
| --- | --- | --- |
| `manzai_0.3.7_win64.zip` | 72271443（约 68.9 MiB） | CRC 全通过、仅一个顶层文件夹 |
| `manzai_0.3.7_mac.zip` | 94895841（约 90.5 MiB） | CRC 全通过、仅一个顶层文件夹 |

两包顶层文件夹均为 `满载而鼠_0.3.7`。

- Windows：`manzai.exe`、`说明.txt`、`帧率测试.bat`、`AI观战.bat`、`双人分屏.bat`；PE 头确认 x86-64，游戏资源嵌入 exe。
- macOS：先解压导出的 .app，再附 `tools/dist_mac/` 文件；.app 的 Mach-O 包含 x86-64 / arm64 两种架构，两架构均存在临时签名标记，包内保留 `_CodeSignature/CodeResources`。未公证。Info.plist 版本为 0.3.7、标识 `com.manzaiershu.game`，包含局域网权限说明。
- Mac 启动脚本和主程序在最终 ZIP 中保留可执行权限；目录、符号链接按 Unix 属性写入。
- ZIP 条目无测试脚本或 .godot 工作目录；导出日志也没有打入 `res://tests/`。
- 随包说明补齐右键 / E、Tab、手柄 LT、2P 逗号技能；Mac 说明修正旧“批次3”解压路径和误复制的 Windows 权限提示。
- 以上为导出、压缩结构及二进制 / 签名结构检查；Linux 环境未执行 Windows exe 或 macOS .app，不替代真机启动或 macOS `codesign --verify`。

完整结构检查见 [checks.json](checks.json)，校验值见 [SHA256SUMS.txt](SHA256SUMS.txt)：

```text
99416f87127dd4b42b4f1a3ac5bcdfe77016ff91adcd145f8ea3f391b2789d5c  manzai_0.3.7_win64.zip
6769cb183e3a5979206ab112b23ee065c9c7c25ad72b57dd61293d70493dda04  manzai_0.3.7_mac.zip
```

安装包留在共享执行工作区 `/workspace/output/`，仓库内的 `release/` 另有相同副本并被 .gitignore 忽略；**未提交安装包**。临时操作材料在仓库外 `work/`，没有提交一次性测量 / 截图脚本。

## Release 发布受阻与交接

预定标签 `v0.3.7`，目标分支 `claude/new-session-w3yl0l`，游戏对应提交为上述 `c384c78`。发布说明已经写好：[RELEASE_NOTES.md](RELEASE_NOTES.md)。

当前 **没有建立 Release、没有创建 v0.3.7 标签、没有上传附件**，原因是当前执行环境的 CLI GitHub API 请求被拒绝；可用 GitHub 连接器能合并 PR、开 PR，但没有创建 Release / 上传附件接口。未通过其他域名或外部平台绕过网络限制。

实际失败的完整输出片段：

```text
Get "https://api.github.com/repos/wangwang1234/1/releases/tags/v0.3.7": Forbidden
```

[API 失败日志](logs/release_api.log)。仓库 PR 写入权限正常；缺的是执行环境内可用的 GitHub CLI/API 授权及 `api.github.com`、`uploads.github.com` 的网络访问，不能据此判断导演账号缺少仓库权限。API 被拒绝，亦未能确认是否已有同名 Release；发布前须先核对，不能覆盖既有附件。

聊天原先指定的 `/codex/browser/projectless/.../output` 不存在于此云端执行器，创建目录也被底层文件权限拒绝，因此无法提供该目录的聊天下载链接。两个包、校验值、发布说明和发布命令均已准备在 `/workspace/output/`，可从共享工作区取走；若需继续在本环境上传 Release，需要补齐上述 API 访问与授权。

导演在具备 GitHub 授权的本机，将两个 ZIP 与 RELEASE_NOTES.md 放在同一目录后，可执行：

```bash
gh release create v0.3.7 manzai_0.3.7_win64.zip manzai_0.3.7_mac.zip --repo wangwang1234/1 --target claude/new-session-w3yl0l --title '满载而鼠 0.3.7 · 局域网联机试玩版' --notes-file RELEASE_NOTES.md
```

## 保留的验收问题

导演确认按现有结果打包，不代表未完成项已经通过：云端软件 Vulkan 双窗口加载掉线原因仍未确定，真实右键 / Tab 双窗口操作、跨电脑 Wi-Fi、Windows / macOS 真机联机及目标 GPU 帧率待实机验收。发布说明保留这些边界。
