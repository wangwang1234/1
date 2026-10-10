#!/bin/bash
# 直接开一局本地双人分屏：玩家 1 键鼠，玩家 2 手柄（没接手柄时先用方向键）。
cd "$(dirname "$0")"
"./满载而鼠.app/Contents/MacOS/满载而鼠" -- --match --duo --p2 pad --mode full
