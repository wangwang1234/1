#!/usr/bin/env bash
# 导出可执行文件（需要对应平台的导出模板，见 CLAUDE.md“环境”）。
#   tools/export.sh [windows|linux|mac]   默认 windows → build/win/manzai.exe；mac → build/mac/manzai.zip（内含 .app，通用版、临时签名）
set -e
source "$(dirname "$0")/_env.sh"
T="${1:-windows}"
case "$T" in
	windows) P="Windows Desktop"; OUT="$ROOT/build/win/manzai.exe" ;;
	linux)   P="Linux"; OUT="$ROOT/build/linux/manzai.x86_64" ;;
	mac)     P="macOS"; OUT="$ROOT/build/mac/manzai.zip" ;;
	*) echo "未知平台 $T"; exit 1 ;;
esac
mkdir -p "$(dirname "$OUT")"
"$GODOT" --headless --path "$ROOT/game" --export-release "$P" "$OUT"
# Windows 版附带：帧率测试 / AI 观战的快捷方式和说明
[ "$T" = "windows" ] && cp "$ROOT/tools/dist/"* "$(dirname "$OUT")/"
ls -la "$(dirname "$OUT")"
