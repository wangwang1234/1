#!/bin/bash
# 直接开一局完整地图 AI 自动对打（观战模式），用来看画面和测稳定性。
cd "$(dirname "$0")"
"./满载而鼠.app/Contents/MacOS/满载而鼠" -- --match --autoplay --mode full
