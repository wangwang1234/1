"""前后对比拼图：同名截图左右并排，上面标“改前 / 改后”。

用法：python3 tools/review/compare_pairs.py <改前目录> <改后目录> <输出目录> [名字1 名字2 ...]
不给名字时，两边都有的 PNG 全部拼。输出 JPG（对比_<名字>.jpg）。
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONT_PATHS = [
    Path(__file__).resolve().parents[2] / "game/assets/fonts/NotoSansSC.ttf",
    Path("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"),
]


def font(size):
    for p in FONT_PATHS:
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size)
            except OSError:
                pass
    return ImageFont.load_default()


def main():
    before, after, out = (Path(a) for a in sys.argv[1:4])
    names = sys.argv[4:]
    out.mkdir(parents=True, exist_ok=True)
    if not names:
        names = sorted(p.stem for p in before.glob("*.png") if (after / p.name).exists())
    f = font(30)
    for n in names:
        a = Image.open(before / f"{n}.png").convert("RGB")
        b = Image.open(after / f"{n}.png").convert("RGB")
        gap, head = 12, 52
        im = Image.new("RGB", (a.width + b.width + gap, max(a.height, b.height) + head), (24, 20, 34))
        im.paste(a, (0, head))
        im.paste(b, (a.width + gap, head))
        d = ImageDraw.Draw(im)
        d.text((16, 8), "改前", font=f, fill=(255, 243, 224))
        d.text((a.width + gap + 16, 8), "改后", font=f, fill=(255, 209, 102))
        target = out / f"对比_{n}.jpg"
        im.save(target, quality=88)
        print(target)


if __name__ == "__main__":
    main()
