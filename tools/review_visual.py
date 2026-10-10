"""Compress actual Godot captures and build labeled comparisons (requires Pillow).

Run from the repository root after capturing before/ and final/:
    python3 tools/review_visual.py
The source PNG captures are preserved; no color correction is applied.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / "review/visual_pass1"


def main():
    font = ImageFont.truetype(str(ROOT / "game/assets/fonts/NotoSansSC.ttf"), 24)
    small = ImageFont.truetype(str(ROOT / "game/assets/fonts/NotoSansSC.ttf"), 17)
    for folder in ("before", "final"):
        for source in (REVIEW / folder).glob("*.png"):
            with Image.open(source) as image:
                image.convert("RGB").save(source.with_suffix(".jpg"), quality=90, optimize=True, subsampling=0)
    names = {"study": "书房", "kitchen": "厨房", "character": "角色近景", "living": "客厅"}
    for scene, label in names.items():
        sheet = Image.new("RGB", (1600, 522), "#121824")
        draw = ImageDraw.Draw(sheet)
        draw.text((20, 8), label + " · 原版", font=font, fill="#c8d1df")
        draw.text((820, 8), label + " · 画面升级第一轮", font=font, fill="#ffcf84")
        for i, folder in enumerate(("before", "final")):
            with Image.open(REVIEW / folder / f"visual_{scene}.jpg") as image:
                sheet.paste(image.resize((800, 450), Image.Resampling.LANCZOS), (i * 800, 44))
        draw.line((800, 44, 800, 494), fill="#121824", width=2)
        draw.text((20, 498), "Godot 实机渲染 · 同种子 / 站位 / 朝向 · 相机俯角 56° → 52° · 未作截图调色", font=small, fill="#aab8cb")
        sheet.save(REVIEW / f"comparison_{scene}.jpg", quality=92, optimize=True, subsampling=0)
    lines = ["# 固定机位绘制规模", "", "1600×900，Forward+ / llvmpipe。数值为无 HUD 截图附近一帧的总绘制调用与提交图元，包含阴影绘制，不能当成模型自身面数或硬件 GPU 帧率。", "", "| 区域 | 原版 draw calls | 修改后 draw calls | 原版提交图元 | 修改后提交图元 |", "| --- | ---: | ---: | ---: | ---: |"]
    for scene in ("study", "kitchen", "living"):
        before = json.loads((REVIEW / "before" / f"visual_{scene}_metrics.json").read_text())
        after = json.loads((REVIEW / "final" / f"visual_{scene}_metrics.json").read_text())
        lines.append(f"| {names[scene]} | {before['draw_calls']} | {after['draw_calls']} | {before['primitives']:,} | {after['primitives']:,} |")
    lines += ["", "增加来自级联阴影、软阴影与更细的模型等。本轮还启用了 SSAO / SSIL；这些屏幕空间效果的成本也需要在目标 GPU 测量。不同视角会影响可见图元，以上仅供审阅。", "", "原始数据保留在 before/ 与 final/ 的 *_metrics.json。"]
    (REVIEW / "METRICS.md").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
