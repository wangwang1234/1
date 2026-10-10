#!/bin/bash
# 帧率测试：全屏跑 60 秒完整地图 5 对 5 AI 对局，结果写到同目录 perf/perf.json 和 perf/perf.csv。跑完把 perf 文件夹发回来即可。
cd "$(dirname "$0")"
echo "正在测试帧率，约 70 秒，请不要动鼠标键盘……"
"./满载而鼠.app/Contents/MacOS/满载而鼠" --fullscreen -- --capture perf --out "$(pwd)/perf" --dur 60 --mode full
echo
cat perf/perf.json
echo
echo "结果已保存在 $(pwd)/perf/"
