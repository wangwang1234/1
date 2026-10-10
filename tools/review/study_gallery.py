"""Build a portable screenshot gallery; never retouch source captures."""
from pathlib import Path
import argparse
import html
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("review", type=Path)
args = parser.parse_args()
root = args.review
for folder in ("neutral", "combat", "walk"):
    for p in (root / folder).glob("*.png"):
        if folder == "walk" and p.stem not in ["walk_000", "walk_015", "walk_031"]:
            continue
        with Image.open(p) as im:
            im.convert("RGB").save(p.with_suffix(".jpg"), quality=90, optimize=True, subsampling=0)
items = [
    ("书房同机位：第三轮 → 本轮", "comparison_study.jpg"),
    ("正常视宽实机截图", "final/visual_study_hud.jpg"),
    ("桌面与角色", "final/visual_study_corner.jpg"),
    ("角色近景", "comparison_character.jpg"),
    ("书架附近正常视宽", "final/visual_study_room.jpg"),
    ("统一灰材质诊断", "neutral/visual_study_corner.jpg"),
    ("厨房材质复查", "comparison_kitchen.jpg"),
    ("客厅全局参数复查", "comparison_living.jpg"),
    ("实际 AI 对局", "combat/style_00.jpg"),
]
cards = "\n".join(f'<figure><figcaption>{html.escape(t)}</figcaption><a href="{p}"><img loading="lazy" src="{p}" alt="{html.escape(t)}"></a></figure>' for t, p in items)
page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>满载而鼠 · 书房渲染样板</title><style>
body{margin:0;background:#111722;color:#d7dfeb;font:16px/1.7 system-ui,sans-serif}main{max-width:1280px;margin:auto;padding:32px 20px}h1{font-size:28px;color:#ffd38e}p{max-width:920px}figure{margin:28px 0}figcaption{margin:10px 0;color:#ffd38e}img,video{width:100%;display:block;border-radius:8px}a{color:#9ac8ff}small{color:#a3afc2}</style>
<main><h1>满载而鼠 · 书房灯光与渲染样板</h1>
<p>Godot 实机渲染。对比图保持站位、朝向、视宽一致，没有截图调色。环境连续明暗，角色保留柔化阶调。人工填充与反弹尚非真实 GI。</p>
<p><a href="REPORT.md">中文汇报</a> · <a href="METRICS.md">绘制规模</a></p>
''' + cards + '''<figure><figcaption>移动受光检查 · 暂停战斗模拟，人工驱动角色</figcaption><video controls preload="metadata" src="lighting_walk.mp4" poster="walk/walk_015.jpg"></video></figure>
<p><small>本轮是书房样板，尚未达到参考游戏的整体完成度。74 项测试及游戏冒烟通过；软件 Vulkan 的渲染速度不代表目标电脑帧率。截图与移动序列的原始 PNG、位置数据和日志保留在对应文件夹。</small></p></main></html>'''
(root / "gallery.html").write_text(page, encoding="utf-8")
