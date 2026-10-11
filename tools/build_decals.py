"""生成地面贴花图集（Pillow + numpy）：4×4 格，每格 256 px，RGBA。

都是人类生活留下的痕迹，按仓鼠尺度放大铺在地上（一个咖啡杯印有仓鼠那么大，一只袜子脚印比仓鼠长两倍），
用来打破地板的重复感、交代尺度。颜色直接画在贴图里，着色器只乘一个不透明度。

格子编号（行优先）：
  0 咖啡杯印   1 果汁渍     2 灰尘里的袜子脚印   3 水杯印
  4 擦痕       5 墨水渍     6 汽水黏渍           7 蜡笔涂鸦
  8 灰尘团     9 饼干碎屑   10 鞋底泥印          11 茶包水渍
  12 左脚袜子脚印

用法：python3 tools/build_decals.py
"""
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / "game/assets/textures/decals.png"
CELL = 256
GRID = 4
SS = 2                      # 先按 2 倍画
N = CELL * SS


def blank():
    return Image.new("L", (N, N), 0)


def noise(seed, scale, octaves=3):
    rng = np.random.default_rng(seed)
    out = np.zeros((N, N), np.float32)
    amp = 1.0
    total = 0.0
    for o in range(octaves):
        s = max(2, int(N / scale * (2 ** o)))
        small = rng.random((s, s)).astype(np.float32)
        big = np.array(Image.fromarray((small * 255).astype(np.uint8)).resize((N, N), Image.BICUBIC), np.float32) / 255.0
        out += big * amp
        total += amp
        amp *= 0.5
    return out / total


def rgba(color, alpha):
    """color: (r,g,b) 0..255；alpha: L 图或 numpy 0..1 → RGBA 图（缩到最终尺寸）"""
    a = np.asarray(alpha, np.float32) / (255.0 if not isinstance(alpha, np.ndarray) else 1.0)
    a = np.clip(a, 0, 1)
    img = np.zeros((N, N, 4), np.float32)
    img[..., 0] = color[0]
    img[..., 1] = color[1]
    img[..., 2] = color[2]
    img[..., 3] = a * 255
    im = Image.fromarray(img.astype(np.uint8), "RGBA")
    return im.resize((CELL, CELL), Image.LANCZOS)


def ring(seed, inner, outer, gap_from, gap_to, rim):
    """杯底印：一圈环，边缘更深，有一段断开"""
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    c = N / 2
    r = np.hypot(xx - c, yy - c) / (N / 2)
    ang = (np.degrees(np.arctan2(yy - c, xx - c)) + 360) % 360
    n = noise(seed, 40)
    band = np.clip((r - inner) / 0.02, 0, 1) * np.clip((outer - r) / 0.02, 0, 1)
    edge = np.exp(-((r - outer + 0.012) / 0.012) ** 2) * rim
    a = band * (0.35 + 0.4 * n) + edge
    gap = (ang > gap_from) & (ang < gap_to)
    a[gap] *= 0.15
    a *= np.clip(1.0 - (r - outer) / 0.01, 0, 1)
    return np.clip(a, 0, 1)


def blob(seed, radius, lobes, rim):
    """不规则的液体渍：几个圆叠出来的外形 + 边缘干掉后更深的一圈"""
    rng = random.Random(seed)
    m = blank()
    d = ImageDraw.Draw(m)
    c = N / 2
    for i in range(lobes):
        a = rng.uniform(0, math.tau)
        dist = rng.uniform(0, radius * 0.45) * N / 2
        rr = rng.uniform(0.35, 0.7) * radius * N / 2
        x, y = c + math.cos(a) * dist, c + math.sin(a) * dist
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=255)
    for i in range(lobes * 2):                         # 溅出去的小点
        a = rng.uniform(0, math.tau)
        dist = rng.uniform(0.6, 1.0) * radius * N / 2
        rr = rng.uniform(0.02, 0.06) * N / 2
        x, y = c + math.cos(a) * dist, c + math.sin(a) * dist
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(6))
    base = np.asarray(m, np.float32) / 255.0
    inner = np.asarray(m.filter(ImageFilter.GaussianBlur(14)), np.float32) / 255.0
    edge = np.clip(base - inner, 0, 1) * 2.0 * rim
    n = noise(seed + 1, 30)
    return np.clip(np.clip((base - 0.5) * 6, 0, 1) * (0.45 + 0.35 * n) + edge, 0, 1)


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def sock_print(seed):
    """一大片灰尘，中间被人类的袜子踩出一个脚印（脚印处灰尘少）"""
    n = noise(seed, 60, 4)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    c = N / 2
    r = np.hypot((xx - c) / 1.0, (yy - c) / 0.75) / (N / 2)
    dust = np.clip((1.0 - r) * 1.25, 0, 1) ** 1.1 * np.clip(n * 1.5 - 0.15, 0, 1)
    foot = blank()
    d = ImageDraw.Draw(foot)
    # 右脚脚掌朝上：脚跟在下，外侧边连续，内侧足弓内凹，五个脚趾
    outline = []
    for k in range(64):
        t = k / 63
        y = 0.86 - t * 0.59
        width = 0.095 + 0.05 * smooth(t / 0.75)                                 # 脚跟 0.095，前掌 0.145
        width -= 0.03 * max(0.0, (t - 0.85) / 0.15)                             # 前掌顶端收圆
        arch = 0.05 * math.exp(-((t - 0.42) / 0.15) ** 2)                       # 内侧足弓
        outline.append((0.5 + width + 0.04 * t, y))
        outline.insert(0, (0.5 - width + arch + 0.01 * t, y))
    d.polygon([(x * N, y * N) for x, y in outline], fill=255)
    d.ellipse((N * 0.405, N * 0.76, N * 0.595, N * 0.9), fill=255)          # 脚跟圆头
    for x, y, rr in [(0.44, 0.205, 0.05), (0.53, 0.18, 0.034), (0.6, 0.185, 0.03), (0.66, 0.205, 0.027), (0.705, 0.24, 0.024)]:
        d.ellipse((N * (x - rr), N * (y - rr), N * (x + rr), N * (y + rr)), fill=255)
    foot = np.asarray(foot.filter(ImageFilter.GaussianBlur(3)), np.float32) / 255.0
    return np.clip(dust * (1.0 - foot * 0.85), 0, 1)


def scuffs(seed):
    rng = random.Random(seed)
    m = blank()
    d = ImageDraw.Draw(m)
    for i in range(7):
        x = rng.uniform(0.15, 0.85) * N
        y = rng.uniform(0.15, 0.85) * N
        a = rng.uniform(-0.4, 0.4)
        L = rng.uniform(0.25, 0.6) * N
        w = rng.uniform(3, 9) * SS
        d.line([(x - math.cos(a) * L / 2, y - math.sin(a) * L / 2), (x + math.cos(a) * L / 2, y + math.sin(a) * L / 2)], fill=int(rng.uniform(120, 255)), width=int(w))
    m = m.filter(ImageFilter.GaussianBlur(3))
    return np.asarray(m, np.float32) / 255.0 * 0.7


def crayon(seed):
    rng = random.Random(seed)
    m = blank()
    d = ImageDraw.Draw(m)
    pts = []
    x, y = N * 0.2, N * 0.5
    for i in range(60):
        x += rng.uniform(-8, 14) * SS
        y += math.sin(i * 0.7) * 28 * SS + rng.uniform(-6, 6) * SS
        pts.append((min(max(x, 20), N - 20), min(max(y, 20), N - 20)))
    d.line(pts, fill=255, width=7 * SS, joint="curve")
    m = m.filter(ImageFilter.GaussianBlur(1.5))
    n = noise(seed, 8)
    return np.asarray(m, np.float32) / 255.0 * (0.5 + 0.5 * n)


def dust_patch(seed):
    n = noise(seed, 30, 4)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    r = np.hypot(xx - N / 2, yy - N / 2) / (N / 2)
    return np.clip((1.0 - r) * 1.6, 0, 1) * np.clip((n - 0.35) * 2.2, 0, 1)


def crumbs(seed):
    rng = random.Random(seed)
    m = blank()
    d = ImageDraw.Draw(m)
    for i in range(120):
        a = rng.uniform(0, math.tau)
        dist = abs(rng.gauss(0, 0.28)) * N / 2
        x, y = N / 2 + math.cos(a) * dist, N / 2 + math.sin(a) * dist
        rr = rng.uniform(1.5, 6) * SS
        d.polygon([(x + math.cos(a + k * 2.1) * rr, y + math.sin(a + k * 2.1) * rr) for k in range(3)], fill=255)
    return np.asarray(m, np.float32) / 255.0


def shoe_mud(seed):
    m = blank()
    d = ImageDraw.Draw(m)
    # 鞋底纹的一截：几条横纹
    for i in range(9):
        y = N * (0.18 + i * 0.075)
        d.rounded_rectangle((N * 0.25, y, N * 0.75, y + N * 0.035), radius=8, fill=255)
    m = m.filter(ImageFilter.GaussianBlur(2))
    n = noise(seed, 20)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    fade = np.clip(1.0 - np.abs(yy / N - 0.5) * 1.6, 0, 1)
    return np.asarray(m, np.float32) / 255.0 * np.clip(n * 1.6 - 0.3, 0, 1) * fade


CELLS = [
    ((92, 58, 34), lambda: ring(1, 0.62, 0.86, 200, 250, 0.9)),       # 0 咖啡杯印
    ((150, 98, 46), lambda: blob(2, 0.85, 6, 0.8) * 0.7),                  # 1 果汁渍
    ((214, 208, 200), lambda: sock_print(3)),                         # 2 灰尘里的袜子脚印
    ((200, 210, 220), lambda: ring(4, 0.80, 0.9, 30, 60, 0.6) * 0.6),  # 3 水杯印
    ((24, 22, 26), lambda: scuffs(5)),                                # 4 擦痕
    ((26, 30, 64), lambda: blob(6, 0.6, 5, 0.6)),                     # 5 墨水渍
    ((120, 70, 40), lambda: blob(7, 0.9, 7, 1.0) * 0.85),             # 6 汽水黏渍
    ((150, 110, 190), lambda: crayon(8)),                             # 7 蜡笔涂鸦
    ((150, 146, 150), lambda: dust_patch(9)),                         # 8 灰尘团
    ((196, 150, 90), lambda: crumbs(10)),                             # 9 饼干碎屑
    ((58, 44, 34), lambda: shoe_mud(11)),                             # 10 鞋底泥印
    ((140, 96, 50), lambda: blob(12, 0.7, 4, 1.2) * 0.8),             # 11 茶包水渍
    ((214, 208, 200), lambda: sock_print(3)[:, ::-1]),                # 12 灰尘里的左脚袜子脚印（12 号的镜像）
]


def main():
    atlas = Image.new("RGBA", (CELL * GRID, CELL * GRID), (0, 0, 0, 0))
    for i, (color, fn) in enumerate(CELLS):
        tile = rgba(color, fn())
        atlas.paste(tile, ((i % GRID) * CELL, (i // GRID) * CELL))
    atlas.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
