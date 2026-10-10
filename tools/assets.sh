#!/usr/bin/env bash
# 重新生成全部资产：Blender 模型 + 预览图 + 图标，音效，音乐（约 4 分钟）。
#   tools/assets.sh            全部
#   tools/assets.sh chr_hamster  只生成一个模型（参数传给 build.py --asset）
set -e
source "$(dirname "$0")/_env.sh"
if [ -n "$1" ]; then
	with_display "$BLENDER" --background --factory-startup --python "$ROOT/tools/blender/build.py" -- --asset "$1"
	exit 0
fi
with_display "$BLENDER" --background --factory-startup --python "$ROOT/tools/blender/build.py" -- --all
python3 "$ROOT/tools/audio/build.py" --all
python3 "$ROOT/tools/audio/music.py" --all
# 让 Godot 重新导入
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
