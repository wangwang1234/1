@echo off
rem 直接开一局 AI 自动对打（观战模式），用来看画面和测稳定性。
chcp 65001 >nul
cd /d "%~dp0"
manzai.exe -- --match --autoplay
