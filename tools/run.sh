#!/usr/bin/env bash
# 运行游戏。参数原样传给游戏，例如：
#   tools/run.sh                       正常进主菜单
#   tools/run.sh --match --weapon ak47 直接开局
#   tools/run.sh --match --autoplay    AI 自动对打（观战）
source "$(dirname "$0")/_env.sh"
exec "$GODOT" --path "$ROOT/game" -- "$@"
