@echo off
rem 全部自动测试：sim 测试（headless）+ 表现层 2 分钟 AI 对局冒烟。
chcp 65001 >nul
if "%GODOT%"=="" set GODOT=godot
"%GODOT%" --headless --path "%~dp0..\game" -s res://tests/run_all.gd -- %*
if errorlevel 1 exit /b 1
echo == 表现层冒烟：2 分钟 AI 对局 ==
"%GODOT%" --headless --path "%~dp0..\game" --fixed-fps 60 -- --match --autoplay --seed 3 --quit-after 125 > "%TEMP%\manzai_smoke.log" 2>&1
findstr /C:"SCRIPT ERROR" "%TEMP%\manzai_smoke.log" >nul && (echo 表现层冒烟：失败，见 %TEMP%\manzai_smoke.log & exit /b 1)
echo 表现层冒烟：通过
echo == 武器 / 道具 / 分屏冒烟 ==
"%GODOT%" --headless --path "%~dp0..\game" --fixed-fps 60 res://tests/view_smoke.tscn > "%TEMP%\manzai_vsmoke.log" 2>&1
findstr /C:"SCRIPT ERROR" "%TEMP%\manzai_vsmoke.log" >nul && (echo 武器 / 道具 / 分屏冒烟：失败，见 %TEMP%\manzai_vsmoke.log & exit /b 1)
echo 武器 / 道具 / 分屏冒烟：通过
