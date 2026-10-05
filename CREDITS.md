# 素材来源与授权（CREDITS）

只使用自己生成的素材，或 CC0 / OFL 等可商用授权的素材。新增任何外部素材都要登记在这里。

## 3D 模型、贴图、图标
全部由 `tools/blender/` 下的 Python 脚本在 Blender 里程序化生成（本项目自制）。
调色板贴图 `game/assets/textures/palette.png` 由 `tools/blender/lib/style.py` 生成。

## 音效
全部由 `tools/audio/build.py` 用 numpy / scipy 离线合成（本项目自制），没有使用外部采样。详见 `game/assets/audio/CREDITS.md`。

## 字体（SIL Open Font License 1.1，可商用、可嵌入）
| 文件 | 字体 | 作者 | 授权 |
|---|---|---|---|
| `game/assets/fonts/NotoSansSC.ttf` | Noto Sans SC（思源黑体，可变字重） | Google / Adobe | OFL 1.1，见 `OFL_NotoSansSC.txt` |
| `game/assets/fonts/ZCOOLKuaiLe.ttf` | ZCOOL KuaiLe（站酷快乐体） | 站酷 ZCOOL / 刘兵克 | OFL 1.1，见 `OFL_ZCOOLKuaiLe.txt` |

## 引擎与工具
- Godot Engine 4.7.2（MIT）— https://godotengine.org ，发布版需要在游戏内“关于”或随附文件里附上 Godot 的 MIT 许可声明（批次 5 做“关于”页面时加上）。
- Blender 4.0（GPL，只用作工具，产出的模型不受 GPL 约束）。
