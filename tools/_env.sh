# 公共设置：被其它 .sh 脚本 source。可以用环境变量 GODOT / BLENDER 指定可执行文件。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"
BLENDER="${BLENDER:-blender}"
# 没有显示器（服务器 / 容器）时用 xvfb-run 包一层，软件渲染也能截图
with_display() {
	if [ -z "$DISPLAY" ] && command -v xvfb-run >/dev/null 2>&1; then
		xvfb-run -a -s "-screen 0 1920x1080x24" "$@"
	else
		"$@"
	fi
}
# 过滤掉无害的噪声（容器里没有声卡、退出时的资源统计），其余 ERROR / SCRIPT ERROR 计为失败
check_log() {
	local log="$1"
	if grep -E "SCRIPT ERROR|^ERROR" "$log" | grep -vE "ALSA|init_output_device|resources still in use at exit|ObjectDB instances were leaked" | grep -q .; then
		echo "日志里有报错：" >&2
		grep -E -A3 "SCRIPT ERROR|^ERROR" "$log" | grep -vE "ALSA|init_output_device|resources still in use|ObjectDB instances" | head -40 >&2
		return 1
	fi
	return 0
}
