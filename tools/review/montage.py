"""把一组预览图拼成一张审阅图（带文件名标签）。
用法：python tools/review/montage.py <输出.png> <图1> <图2> ... [--cols N] [--size 256]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont


def main():
    args = sys.argv[1:]
    cols = 4
    size = 256
    if "--cols" in args:
        i = args.index("--cols"); cols = int(args[i + 1]); del args[i:i + 2]
    if "--size" in args:
        i = args.index("--size"); size = int(args[i + 1]); del args[i:i + 2]
    out, files = args[0], args[1:]
    files = [f for f in files if os.path.exists(f)]
    rows = (len(files) + cols - 1) // cols
    lab = 18
    sheet = Image.new("RGB", (cols * size, rows * (size + lab)), (26, 18, 38))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "fonts", "NotoSansSC.ttf"), 12)
    except Exception:
        font = ImageFont.load_default()
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGB")
        im.thumbnail((size, size))
        x = (i % cols) * size
        y = (i // cols) * (size + lab)
        sheet.paste(im, (x + (size - im.width) // 2, y))
        d.text((x + 4, y + size + 2), os.path.splitext(os.path.basename(f))[0][-36:], fill=(255, 243, 224), font=font)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    sheet.save(out)
    print(out, sheet.size)


if __name__ == "__main__":
    main()
