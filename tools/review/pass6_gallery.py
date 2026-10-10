"""Assemble unretouched engine captures for visual pass 6."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2] / "review/visual_pass6"
FONT_PATH = Path(__file__).resolve().parents[2] / "game/assets/fonts/NotoSansSC.ttf"
font = ImageFont.truetype(str(FONT_PATH), 25)
rows = []
for zone, title in [("study", "书房"), ("living", "客厅"), ("kitchen", "厨房")]:
    images = []
    for folder in ["before", "final"]:
        picture = Image.open(ROOT / folder / f"visual_{zone}.png").convert("RGB")
        picture.save(ROOT / folder / f"visual_{zone}.jpg", quality=94, subsampling=0)
        images.append(picture)
    w, h = images[0].size
    canvas = Image.new("RGB", (w, 2 * (h + 48)), "#111722")
    draw = ImageDraw.Draw(canvas)
    for i, (label, picture) in enumerate(zip(["第五轮", "第六轮"], images)):
        y = i * (h + 48)
        draw.text((20, y + 7), f"{title} · {label} · 同机位 1280×720", font=font, fill="#e9e3d8")
        canvas.paste(picture, (0, y + 48))
    canvas.save(ROOT / f"comparison_{zone}.jpg", quality=94, subsampling=0)
    metrics = [json.loads((ROOT / folder / f"visual_{zone}_metrics.json").read_text()) for folder in ["before", "final"]]
    rows.append(f"| {title} | {metrics[0]['draw_calls']} → {metrics[1]['draw_calls']} | {metrics[0]['primitives']:,} → {metrics[1]['primitives']:,} |")
metrics_text = "# 绘制规模\n\n同机位、1280×720、Forward+ 软件 Vulkan。恢复小装饰投影增加了阴影提交；此表不能推导目标硬件帧率。\n\n| 区域 | 绘制调用：第五轮 → 第六轮 | 图元：第五轮 → 第六轮 |\n| --- | --- | --- |\n" + "\n".join(rows) + "\n\n新增反射采集只更新一次，会增加启动阶段开销。本轮未新增后处理通道。\n"
(ROOT / "METRICS.md").write_text(metrics_text)
figures = "\n".join(f'<figure><figcaption>{title} · 上方第五轮，下方第六轮</figcaption><a href="comparison_{zone}.jpg"><img loading="lazy" src="comparison_{zone}.jpg" alt="{title}同机位前后对照"></a></figure>' for zone, title in [("study", "书房"), ("living", "客厅"), ("kitchen", "厨房")])
page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>满载而鼠 · 第六轮</title><style>body{margin:0;background:#111722;color:#dbe2ec;font:16px/1.7 system-ui,sans-serif}main{max-width:1280px;margin:auto;padding:28px 20px}h1{font-size:28px;color:#eecfa3}a{color:#a5cdff}img{width:100%;display:block}figure{margin:32px 0}figcaption{margin:12px 0}</style><main><h1>满载而鼠 · 画质第六轮</h1><p>灯具高光、较厚装饰投影、房间反射与暗部层次。全部来自实际 Godot 渲染，图片未作外部调色。</p><p><a href="REPORT.md">修改与验证说明</a> · <a href="METRICS.md">绘制规模</a></p>''' + figures + '''<p>当前仍未达到参考游戏的整体资产与场景完成度。软件渲染验证不能替代目标电脑帧率测试。</p></main></html>'''
(ROOT / "gallery.html").write_text(page)
