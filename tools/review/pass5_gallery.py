"""Build the fifth visual review from actual engine captures, without retouching."""
from pathlib import Path
import html
from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / "review/visual_pass5"
for folder in ("combat", "duo"):
    for path in (ROOT / folder).glob("*.png"):
        with Image.open(path) as image:
            image.convert("RGB").save(path.with_suffix(".jpg"), quality=92, subsampling=0)
cards = [
    ("书房：上一轮 → 本轮 · 同机位", "comparison_study.jpg"),
    ("客厅：上一轮 → 本轮 · 同机位", "comparison_living.jpg"),
    ("书房 · 正常游戏视宽 7.2 米", "final/visual_study_hud.jpg"),
    ("靠近边界 · 正常游戏视宽 7.2 米", "final/visual_study_window.jpg"),
    ("房间空间审阅 · 12 米视宽、焦点抬高 0.85 米", "final/visual_study_overview.jpg"),
    ("书房台面细节 · 审阅视宽 5.2 米", "final/visual_study_corner.jpg"),
    ("厨房 · 正常游戏视宽 7.2 米", "final/visual_kitchen_hud.jpg"),
    ("实际 AI 交战 · 960×540", "combat/style_00.jpg"),
    ("双人分屏 · 窗口恢复至 960×540", "duo/duo_restored.jpg"),
]
figures = "\n".join(
    f'<figure><figcaption>{html.escape(label)}</figcaption>'
    f'<a href="{path}"><img loading="lazy" src="{path}" alt="{html.escape(label)}"></a></figure>'
    for label, path in cards
)
page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>满载而鼠 · 画质第五轮</title><style>
body{margin:0;background:#111722;color:#d7dfeb;font:16px/1.7 system-ui,sans-serif}
main{max-width:1280px;margin:auto;padding:32px 20px}h1{font-size:28px;color:#ffd38e}
p{max-width:980px}figure{margin:30px 0}figcaption{margin:10px 0;color:#ffd38e}
img,video{width:100%;display:block;border-radius:8px}a{color:#9ac8ff}small{color:#a3afc2}
</style><main><h1>满载而鼠 · 画质第五轮</h1>
<p>连续错缝木板、边界窗框与墙面、分区灯光、宽过渡景深与轻微速度模糊。
全部来自实际 Godot 渲染；对照图没有外部调色。当前仍未达到参考游戏的整体完成度。</p>
<p><a href="REPORT.md">中文说明</a> · <a href="METRICS.md">绘制规模</a> ·
<a href="verification/MOTION.md">运动模糊开关对照</a></p>
''' + figures + '''<figure><figcaption>移动与受光诊断 · 人工驱动角色，暂停战斗模拟 · 12 帧/秒</figcaption>
<video controls preload="metadata" src="lighting_walk.mp4"></video></figure>
<p><small>窗口与墙面的空间审阅使用更宽机位，默认战斗相机保持 7.2 米。
软件 Vulkan 截图与视频不能替代目标电脑帧率测试。Mac / Windows 已导出，原生平台尚需设备试跑。</small></p>
</main></html>'''
(ROOT / "gallery.html").write_text(page, encoding="utf-8")
