"""Compress actual Godot captures and build labeled comparisons (requires Pillow).

Run from the repository root after capturing before/ and final/:
    python3 tools/review_visual.py
The source PNG captures are preserved; no color correction is applied.
"""
import json
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / "review/visual_pass1"


def main():
    global REVIEW
    parser = argparse.ArgumentParser()
    parser.add_argument("--review", default="review/visual_pass1")
    parser.add_argument("--before-label", default="原版")
    parser.add_argument("--after-label", default="画面升级第一轮")
    parser.add_argument("--caption", default="Godot 实机渲染 · 同种子 / 站位 / 朝向 · 相机俯角 56° → 52° · 未作截图调色")
    args = parser.parse_args()
    REVIEW = ROOT / args.review
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
        draw.text((20, 8), label + " · " + args.before_label, font=font, fill="#c8d1df")
        draw.text((820, 8), label + " · " + args.after_label, font=font, fill="#ffcf84")
        for i, folder in enumerate(("before", "final")):
            with Image.open(REVIEW / folder / f"visual_{scene}.jpg") as image:
                sheet.paste(image.resize((800, 450), Image.Resampling.LANCZOS), (i * 800, 44))
        draw.line((800, 44, 800, 494), fill="#121824", width=2)
        draw.text((20, 498), args.caption, font=small, fill="#aab8cb")
        sheet.save(REVIEW / f"comparison_{scene}.jpg", quality=92, optimize=True, subsampling=0)
    metrics = json.loads((REVIEW / "final/visual_study_metrics.json").read_text())
    lines = ["# 固定机位绘制规模", "", metrics["resolution"] + "，Forward+ / llvmpipe。数值为无 HUD 截图附近一帧的总绘制调用与提交图元，包含阴影绘制，不能当成模型自身面数或硬件 GPU 帧率。", "", f"| 区域 | {args.before_label} draw calls | {args.after_label} draw calls | {args.before_label}提交图元 | {args.after_label}提交图元 |", "| --- | ---: | ---: | ---: | ---: |"]
    for scene in ("study", "kitchen", "living"):
        before = json.loads((REVIEW / "before" / f"visual_{scene}_metrics.json").read_text())
        after = json.loads((REVIEW / "final" / f"visual_{scene}_metrics.json").read_text())
        lines.append(f"| {names[scene]} | {before['draw_calls']} | {after['draw_calls']} | {before['primitives']:,} | {after['primitives']:,} |")
    lines += ["", "提交图元包含重复的阴影绘制，分件材质与模型细节会增加绘制成本。不同視角、LOD 和阴影剔除也会影响统计；应在目标 GPU 实测帧率，以上仅供审阅。", "", "原始数据保留在 before/ 与 final/ 的 *_metrics.json。"]
    (REVIEW / "METRICS.md").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
