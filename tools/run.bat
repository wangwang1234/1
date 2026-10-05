@echo off
rem 运行游戏。参数原样传给游戏，例如：
rem   tools\run.bat                        正常进主菜单
rem   tools\run.bat --match --weapon ak47  直接开局
rem   tools\run.bat --match --autoplay     AI 自动对打（观战）
rem 用环境变量 GODOT 指定 Godot 可执行文件（默认 PATH 里的 godot）。
chcp 65001 >nul
if "%GODOT%"=="" set GODOT=godot
"%GODOT%" --path "%~dp0..\game" -- %*
