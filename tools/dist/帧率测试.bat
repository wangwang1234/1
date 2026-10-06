@echo off
rem 帧率测试：全屏跑 60 秒完整地图 5 对 5 AI 对局（不锁垂直同步），结果写到 perf\perf.json 和 perf\perf.csv。
rem 跑完把 perf 文件夹发回来即可。
chcp 65001 >nul
cd /d "%~dp0"
echo 正在测试帧率，约 70 秒，请不要动鼠标键盘……
manzai.exe --fullscreen -- --capture perf --out perf --dur 60 --mode full
echo.
type perf\perf.json
echo.
echo 结果已保存在 %~dp0perf\
pause
