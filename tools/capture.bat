@echo off
rem 截图 / 帧率测试：tools\capture.bat <场景> <输出目录> [分辨率] [其它参数...]
rem 场景：menu style gameplay cards loadout lineup perf（说明见 game\scripts\core\capture.gd）
chcp 65001 >nul
if "%GODOT%"=="" set GODOT=godot
set SC=%1
set OUT=%~f2
set RES=%3
if "%RES%"=="" set RES=1920x1080
if not exist "%OUT%" mkdir "%OUT%"
set FPS=--fixed-fps 60
if "%SC%"=="perf" set FPS=
"%GODOT%" --path "%~dp0..\game" --resolution %RES% %FPS% -- --capture %SC% --out "%OUT%" %4 %5 %6 %7 %8 %9
