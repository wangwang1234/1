"""生成聚光灯投影贴图（gobo，Pillow）：白 = 透光，黑 = 被画面外的巨物挡住。

这些贴图给 SpotLight3D.light_projector 用，在地上投出窗框、百叶、桌椅腿、龟背竹叶子、冰箱门缝的光形，
用“画面外的巨大家具的影子”交代仓鼠有多小。投影灯不开阴影贴图，开销和普通聚光一样。

用法：python3 tools/build_gobos.py            （全部重新生成到 game/assets/textures/）
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / "game/assets/textures"
S = 1024          # 先按 2 倍画，缩小时自带抗锯齿
FINAL = 512


def canvas(fill="black"):
    img = Image.new("L", (S, S), fill)
    return img, ImageDraw.Draw(img)


def save(img, name, blur):
    img = img.resize((FINAL, FINAL), Image.LANCZOS).filter(ImageFilter.GaussianBlur(blur))
    img.convert("RGB").save(OUT / name)
    print(OUT / name)


def window_frame(d, box, cols, rows, bar):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill="white")
    for i in range(1, cols):
        x = x0 + (x1 - x0) * i / cols
        d.rectangle((x - bar / 2, y0, x + bar / 2, y1), fill="black")
    for j in range(1, rows):
        y = y0 + (y1 - y0) * j / rows
        d.rectangle((x0, y - bar / 2, x1, y + bar / 2), fill="black")


def monstera_leaf(d, cx, cy, length, width, angle, rng):
    """龟背竹叶：心形大叶 + 从边缘切向叶脉的裂口 + 叶脉旁的小洞。"""
    ca, sa = math.cos(angle), math.sin(angle)

    def tr(u, v):          # 叶子坐标（u 沿叶脉 0..1，v 横向 -1..1）→ 画布
        x = u * length
        y = v * width * 0.5
        return (cx + x * ca - y * sa, cy + x * sa + y * ca)

    outline = []
    n = 48
    for side in (1, -1):
        rng_side = range(n + 1) if side == 1 else range(n, -1, -1)
        for i in rng_side:
            u = i / n
            # 心形：基部有凹口，最宽处在 0.4，叶尖收拢
            half = math.sin(math.pi * min(1.0, u * 1.05)) ** 0.75 * (1.0 - 0.25 * u)
            if u < 0.08:
                half *= u / 0.08 * 0.85 + 0.15
            outline.append(tr(u, side * half))
    d.polygon(outline, fill="black")
    # 裂口：从叶缘斜着切到靠近叶脉
    for side in (1, -1):
        for k in range(4):
            u = 0.24 + k * 0.17 + rng.uniform(-0.02, 0.02)
            if u > 0.86:
                continue
            gap = 0.022
            p = [tr(u - gap, side * 1.2), tr(u + gap, side * 1.2), tr(u + 0.05 + gap * 0.4, side * 0.28), tr(u + 0.05, side * 0.24)]
            d.polygon(p, fill="white")
    # 叶脉旁的小椭圆洞
    for side in (1, -1):
        for k in range(3):
            u = 0.28 + k * 0.17
            x, y = tr(u, side * 0.16)
            r = length * 0.018
            d.ellipse((x - r, y - r, x + r, y + r), fill="white")
    # 叶柄
    d.line([tr(0.0, 0.0), tr(-0.55, 0.12)], fill="black", width=int(width * 0.05) + 2)


def gobo_window_plant():
    """客厅月光：两扇窗格，窗台上一盆龟背竹的大叶子挡住左下角。"""
    img, d = canvas()
    window_frame(d, (120, 150, 904, 874), 2, 3, 26)
    rng = random.Random(7)
    leaves = [(330, 820, 470, 380, -0.55), (300, 760, 520, 400, -1.4), (250, 800, 380, 300, -2.35)]
    for cx, cy, l, w, a in leaves:
        # 每片叶子单独画，裂口只挖自己，不会把后面的叶子也切开
        layer, ld = canvas("white")
        monstera_leaf(ld, cx, cy, l, w, a, rng)
        img = ImageChops.darker(img, layer)
    d = ImageDraw.Draw(img)
    # 花盆口沿
    d.rectangle((110, 900, 520, 1024), fill="black")
    save(img, "gobo_window_plant.png", 3.2)


def gobo_blinds():
    """路灯透过百叶窗：亮条纹；有一片叶子折弯、一片掉了。"""
    img, d = canvas()
    x0, y0, x1, y1 = 140, 120, 884, 904
    slats = 13
    step = (y1 - y0) / slats
    for i in range(slats):
        top = y0 + i * step + step * 0.52      # 叶片之间的缝透光（约 48%）
        bot = y0 + (i + 1) * step
        if i == 4:
            # 折弯的叶片：缝变成一条弧
            pts = []
            for k in range(41):
                t = k / 40
                x = x0 + (x1 - x0) * t
                bend = math.exp(-((t - 0.62) / 0.12) ** 2) * step * 0.55
                pts.append((x, top - bend))
            pts += [(x1, bot), (x0, bot)]
            d.polygon(pts, fill="white")
        elif i == 8:
            d.rectangle((x0, y0 + i * step, x1, bot), fill="white")   # 掉了的那片
        else:
            d.rectangle((x0, top, x1, bot), fill="white")
    for x in (x0 + (x1 - x0) * 0.3, x0 + (x1 - x0) * 0.7):        # 拉绳
        d.rectangle((x - 5, y0, x + 5, y1), fill="black")
    save(img, "gobo_blinds.png", 2.6)


def chair(d, x, y, w, h):
    """椅子剪影（光从低处的窗子照进来时看到的形状）：外撇的细腿、薄坐面、窄一点的靠背和竖条。"""
    leg = w * 0.1
    seat = y + h * 0.48
    # 腿往外撇
    d.polygon([(x + w * 0.08, seat), (x + w * 0.08 + leg, seat), (x + leg * 0.6, y + h), (x - leg * 0.4, y + h)], fill="black")
    d.polygon([(x + w * 0.92 - leg, seat), (x + w * 0.92, seat), (x + w + leg * 0.4, y + h), (x + w - leg * 0.6, y + h)], fill="black")
    d.rectangle((x, seat - h * 0.03, x + w, seat + h * 0.02), fill="black")      # 坐面
    bx0, bx1 = x + w * 0.12, x + w * 0.88                                        # 靠背比坐面窄
    for bx in (bx0, bx1 - leg):
        d.rectangle((bx, y, bx + leg, seat), fill="black")
    for k in range(1, 3):
        sx = bx0 + (bx1 - bx0) * k / 3
        d.rectangle((sx - leg * 0.3, y + h * 0.1, sx + leg * 0.3, seat), fill="black")
    d.rounded_rectangle((bx0 - w * 0.03, y, bx1 + w * 0.03, y + h * 0.09), radius=int(h * 0.03), fill="black")


def gobo_table_chairs():
    """厨房月光：窗光从餐桌和两把椅子下面穿过来，地上是巨大的桌腿、椅腿和靠背条的影子。"""
    img, d = canvas()
    window_frame(d, (60, 60, 964, 964), 1, 1, 0)
    # 餐桌：桌面挡住上半部分的边缘，两条粗桌腿
    d.rectangle((60, 60, 964, 250), fill="black")
    d.rectangle((60, 250, 964, 285), fill="black")      # 桌裙
    d.rectangle((150, 250, 215, 964), fill="black")
    d.rectangle((800, 250, 865, 964), fill="black")
    chair(d, 270, 300, 250, 664)
    chair(d, 560, 380, 220, 584)
    save(img, "gobo_table_chairs.png", 3.0)


def gobo_fridge_wedge():
    """冰箱门开了一条缝：楔形冷光，里面有隔板和瓶子的影子。"""
    img, d = canvas()
    d.polygon([(430, 0), (594, 0), (930, 1024), (94, 1024)], fill="white")
    for y in (300, 560):
        d.rectangle((0, y, S, y + 26), fill="black")      # 隔板
    for bx, bw, bh in ((430, 40, 170), (500, 32, 120), (560, 46, 210)):
        d.rectangle((bx, 300 - bh, bx + bw, 300), fill="black")   # 瓶子
        d.ellipse((bx - 4, 300 - bh - 26, bx + bw + 4, 300 - bh + 10), fill="black")
    img2 = Image.new("L", (S, S), "black")
    # 越远越暗：门缝光往外扩散时变弱
    grad = Image.linear_gradient("L").resize((S, S))
    img = Image.composite(img, img2, grad.point(lambda v: 255 - int(v * 0.55)))
    save(img, "gobo_fridge_wedge.png", 4.0)


def office_chair(d, cx, cy, r):
    """办公椅：五星脚 + 轮子 + 气杆 + 坐面边缘（书房窗光里）。"""
    for k in range(5):
        a = -math.pi / 2 + k * 2 * math.pi / 5 + 0.3
        ex, ey = cx + math.cos(a) * r, cy + math.sin(a) * r * 0.55
        d.line([(cx, cy), (ex, ey)], fill="black", width=int(r * 0.11))
        d.ellipse((ex - r * 0.1, ey - r * 0.1, ex + r * 0.1, ey + r * 0.1), fill="black")
    d.rectangle((cx - r * 0.06, cy - r * 1.3, cx + r * 0.06, cy), fill="black")
    d.ellipse((cx - r * 0.9, cy - r * 1.55, cx + r * 0.9, cy - r * 1.15), fill="black")


def gobo_study_window():
    """书房窗光：原来的四格窗 + 窗前办公椅的影子。"""
    img, d = canvas()
    d.rectangle((130, 210, 894, 814), fill="white")
    d.rectangle((372, 210, 398, 814), fill="black")
    d.rectangle((626, 210, 652, 814), fill="black")
    d.rectangle((130, 496, 894, 524), fill="black")
    office_chair(d, 300, 800, 170)
    save(img, "study_window.png", 5.0)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    gobo_window_plant()
    gobo_blinds()
    gobo_table_chairs()
    gobo_fridge_wedge()
    gobo_study_window()
