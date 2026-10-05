#!/usr/bin/env bash
# 全部自动测试：
#   1) sim 单元 / 对局测试（headless）：tests/test_*.gd
#   2) 表现层冒烟：完整画面逻辑（headless，不出图）跑 2 分钟 AI 对局，日志里不能有报错
# 用法：tools/test.sh [--only 名称]
set -e
source "$(dirname "$0")/_env.sh"
LOG="$(mktemp)"
echo "== sim 测试 =="
"$GODOT" --headless --path "$ROOT/game" -s res://tests/run_all.gd -- "$@"
echo "== 表现层冒烟：2 分钟 AI 对局 =="
"$GODOT" --headless --path "$ROOT/game" --fixed-fps 60 -- --match --autoplay --seed 3 --quit-after 125 >"$LOG" 2>&1 || true
if check_log "$LOG"; then echo "表现层冒烟：通过"; else echo "表现层冒烟：失败"; exit 1; fi
echo "== 主菜单冒烟 =="
"$GODOT" --headless --path "$ROOT/game" --fixed-fps 60 -- --quit-after 5 >"$LOG" 2>&1 || true
if check_log "$LOG"; then echo "主菜单冒烟：通过"; else echo "主菜单冒烟：失败"; exit 1; fi
rm -f "$LOG"
echo "全部通过"
