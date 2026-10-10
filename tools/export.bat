@echo off
rem 导出 Windows 可执行文件到 build\win\manzai.exe（需要 Godot 4.7.2 的 Windows 导出模板）。
chcp 65001 >nul
if "%GODOT%"=="" set GODOT=godot
if not exist "%~dp0..\build\win" mkdir "%~dp0..\build\win"
"%GODOT%" --headless --path "%~dp0..\game" --export-release "Windows Desktop" "%~dp0..\build\win\manzai.exe"
copy /y "%~dp0dist\*" "%~dp0..\build\win\" >nul
