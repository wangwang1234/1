#!/usr/bin/env bash
# 截图 / 帧率测试（窗口模式；没有显示器时自动套 xvfb-run）。
#   tools/capture.sh <场景> <输出目录> [分辨率] [其它参数...]
#   场景：menu style gameplay cards loadout lineup perf（说明见 game/scripts/core/capture.gd）
#   例：tools/capture.sh style review/batch1/style 1920x1080 --n 6 --from 30
#       tools/capture.sh perf review/batch1/perf 1920x1080 --dur 60
set -e
source "$(dirname "$0")/_env.sh"
SC="$1"; OUT="$2"; RES="${3:-1920x1080}"; shift 3 || shift $#
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
FPS="--fixed-fps 60"
[ "$SC" = "perf" ] && FPS=""
with_display "$GODOT" --path "$ROOT/game" --resolution "$RES" $FPS -- --capture "$SC" --out "$OUT" "$@"
