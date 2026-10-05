#!/usr/bin/env bash
# 录一段 AI 对局视频（Godot Movie Maker，固定 30 帧，不受机器快慢影响），再用 ffmpeg 转 mp4。
#   tools/record.sh <输出.mp4> [秒数=40] [分辨率=1280x720] [种子=5]
set -e
source "$(dirname "$0")/_env.sh"
OUT="$1"; DUR="${2:-40}"; RES="${3:-1280x720}"; SEED="${4:-5}"
TMP="$(mktemp -d)"
with_display "$GODOT" --path "$ROOT/game" --resolution "$RES" --write-movie "$TMP/movie.avi" --fixed-fps 30 -- --match --autoplay --seed "$SEED" --quit-after "$DUR"
ffmpeg -y -loglevel error -i "$TMP/movie.avi" -c:v libx264 -pix_fmt yuv420p -crf 22 -preset slow -c:a aac -b:a 128k "$OUT"
rm -rf "$TMP"
echo "已保存 $OUT"
