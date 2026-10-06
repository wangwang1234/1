@echo off
rem 直接开一局本地双人分屏：玩家 1 键鼠，玩家 2 手柄（没接手柄时先用方向键）。
chcp 65001 >nul
cd /d "%~dp0"
manzai.exe -- --match --duo --p2 pad --mode full
