"""音效离线合成（PIPELINE 第 8 节）。参照原型 n1b.js 的枪声配方：瞬态（高通噪声）+ 主体（低通噪声）+ 低频冲击（下滑正弦）
+ 机械声（带通咔哒）+ 环境混响（卷积），每种至少 3 个变体，导出 OGG（Vorbis）。

    python tools/audio/build.py --all
    python tools/audio/build.py --only shot_pistol,reload_rifle
输出：game/assets/audio/sfx/<名称>_<变体>.ogg。全部为自己合成，无外部素材。
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "game", "assets", "audio", "sfx")


class Synth:
    def __init__(self, seed):
        self.rng = np.random.default_rng(seed)

    def t(self, dur):
        return np.arange(int(dur * SR)) / SR

    def noise(self, dur):
        return self.rng.uniform(-1, 1, int(dur * SR))

    def env(self, dur, attack=0.001, decay=0.1, curve="exp"):
        t = self.t(dur)
        a = np.clip(t / max(attack, 1e-5), 0, 1)
        if curve == "exp":
            d = np.exp(-np.maximum(t - attack, 0) / max(decay, 1e-5) * 5.0)
        else:
            d = np.clip(1 - (t - attack) / max(decay, 1e-5), 0, 1)
        return a * d

    def filt(self, x, kind, f, q=0.7, order=2):
        nyq = SR / 2
        if kind == "lp":
            b, a = signal.butter(order, min(f / nyq, 0.99), "low")
        elif kind == "hp":
            b, a = signal.butter(order, min(f / nyq, 0.99), "high")
        else:
            bw = f / max(q, 0.1)
            lo = max(20, f - bw / 2) / nyq
            hi = min(nyq * 0.98, f + bw / 2) / nyq
            b, a = signal.butter(order, [lo, hi], "band")
        return signal.lfilter(b, a, x)

    def sweep(self, f0, f1, dur, wave="sine"):
        t = self.t(dur)
        f = f0 * (f1 / f0) ** (t / max(dur, 1e-5))
        ph = 2 * np.pi * np.cumsum(f) / SR
        if wave == "sine":
            return np.sin(ph)
        if wave == "square":
            return np.sign(np.sin(ph))
        if wave == "saw":
            return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
        return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1.0) - 1) - 1

    def reverb(self, x, length=1.4, mix=0.25, lp=3400):
        n = int(length * SR)
        t = np.arange(n) / SR
        ir = self.rng.uniform(-1, 1, n) * (1 - t / length) ** 2.2 * np.exp(-t * 2.4)
        ir[: int(0.01 * SR)] *= 0.25
        wet = signal.fftconvolve(x, ir)
        wet = self.filt(wet, "lp", lp)
        out = np.zeros(len(wet))
        out[: len(x)] += x
        out += wet * mix / (np.max(np.abs(wet)) + 1e-9) * np.max(np.abs(x))
        return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def place(x, offset_s, total=None):
    pad = np.zeros(int(offset_s * SR))
    y = np.concatenate([pad, x])
    if total:
        y = np.pad(y, (0, max(0, int(total * SR) - len(y))))
    return y


def trim(x, thresh=1e-4):
    idx = np.where(np.abs(x) > thresh)[0]
    if len(idx) == 0:
        return x[:100]
    return x[: idx[-1] + int(0.02 * SR)]


def normalize(x, peak_db=-1.0):
    p = np.max(np.abs(x)) + 1e-9
    g = 10 ** (peak_db / 20) / p
    y = x * g
    # 首尾淡入淡出，避免爆音
    f = min(len(y) // 4, int(0.004 * SR))
    y[:f] *= np.linspace(0, 1, f)
    f2 = min(len(y) // 4, int(0.03 * SR))
    y[-f2:] *= np.linspace(1, 0, f2)
    return y


# ---------------------------------------------------------------------------
# 枪声配方（与原型 GSFX.P 对应：hp 瞬态高通、cr 瞬态音量、lp 主体低通、bd 主体衰减、bg 主体音量、
# t0/t1/td/tg 低频冲击的起止频率/时长/音量、rev 混响、mech 机械声）
# ---------------------------------------------------------------------------
GUN = {
    "pistol": dict(hp=2600, cr=0.55, lp=1900, bd=0.10, bg=0.75, t0=170, t1=60, td=0.07, tg=0.55, rev=0.22),
    "ak47": dict(hp=2400, cr=0.6, lp=1500, bd=0.13, bg=0.85, t0=150, t1=48, td=0.09, tg=0.7, rev=0.28, mech=1),
    "shotgun": dict(hp=1800, cr=0.75, lp=950, bd=0.3, bg=1.1, t0=110, t1=32, td=0.17, tg=1.0, rev=0.48),
    "minion": dict(hp=3400, cr=0.22, lp=2600, bd=0.05, bg=0.28, t0=230, t1=110, td=0.035, tg=0.18, rev=0.08),
    "turret": dict(hp=1500, cr=0.35, lp=900, bd=0.16, bg=0.7, t0=110, t1=40, td=0.12, tg=0.7, rev=0.3),
    # 批次 2：其余枪械（数值照抄原型 GSFX.P）
    "deagle": dict(hp=2200, cr=0.75, lp=1250, bd=0.22, bg=1.05, t0=125, t1=36, td=0.15, tg=0.95, rev=0.45),
    "smg": dict(hp=3000, cr=0.42, lp=2300, bd=0.07, bg=0.55, t0=190, t1=80, td=0.05, tg=0.4, rev=0.16),
    "sniper": dict(hp=3300, cr=0.9, lp=1100, bd=0.34, bg=1.05, t0=95, t1=28, td=0.2, tg=1.0, rev=0.8),
    "lmg": dict(hp=2300, cr=0.62, lp=1300, bd=0.13, bg=0.9, t0=130, t1=44, td=0.09, tg=0.75, rev=0.28, mech=1),
    "rat": dict(hp=2800, cr=0.35, lp=2000, bd=0.07, bg=0.45, t0=180, t1=70, td=0.05, tg=0.35, rev=0.15),
    "minigun": dict(hp=3000, cr=0.38, lp=2100, bd=0.06, bg=0.5, t0=180, t1=75, td=0.045, tg=0.38, rev=0.14),
    "autoshot": dict(hp=1900, cr=0.65, lp=1050, bd=0.22, bg=0.95, t0=115, t1=36, td=0.13, tg=0.85, rev=0.38),
    "amr": dict(hp=2800, cr=1.0, lp=850, bd=0.42, bg=1.25, t0=80, t1=22, td=0.28, tg=1.2, rev=0.95),
    "revolver": dict(hp=2500, cr=0.8, lp=1500, bd=0.2, bg=0.95, t0=140, t1=40, td=0.13, tg=0.85, rev=0.5),
    "gl": dict(hp=1200, cr=0.2, lp=600, bd=0.12, bg=0.8, t0=160, t1=60, td=0.1, tg=0.9, rev=0.2),
    "sentry": dict(hp=3200, cr=0.28, lp=2400, bd=0.05, bg=0.32, t0=210, t1=100, td=0.035, tg=0.22, rev=0.1),
    "dual": dict(hp=2800, cr=0.5, lp=2000, bd=0.08, bg=0.65, t0=180, t1=66, td=0.06, tg=0.5, rev=0.2),
}


def gun_shot(name, seed):
    p = GUN[name]
    s = Synth(seed)
    k = s.rng.uniform(0.93, 1.07)
    crack = s.filt(s.noise(0.05), "hp", p["hp"] * k) * s.env(0.05, 0.0005, 0.028) * p["cr"] * 1.6
    body = s.filt(s.noise(p["bd"] + 0.05), "lp", p["lp"] * k, order=3) * s.env(p["bd"] + 0.05, 0.002, p["bd"]) * p["bg"]
    thump = s.sweep(p["t0"] * k, p["t1"], p["td"]) * s.env(p["td"], 0.003, p["td"] * 0.9) * p["tg"]
    # 卡通加料：一点点方波“砰”，让枪声更有玩具感
    toy = s.filt(s.sweep(420 * k, 180, 0.05, "square"), "lp", 2500) * s.env(0.05, 0.001, 0.04) * 0.08
    parts = [crack, body, thump, toy]
    if p.get("mech"):
        parts.append(place(s.filt(s.noise(0.03), "bp", 2600, 6) * s.env(0.03, 0.001, 0.025) * 0.35, 0.03))
    x = mix(*parts)
    x = s.reverb(x, 1.2, p["rev"])
    return trim(x)


# ---------------------------------------------------------------------------
# 批次 2：特殊武器 / 道具 / 野怪（对应原型 GSFX 的 rocket、swish、ting、flame、spin、charge、rail、laser、bang、beep、bolt）
# ---------------------------------------------------------------------------

def rocket(seed):
    s = Synth(seed)
    whoosh = s.noise(0.55)
    f = np.geomspace(500, 2400, len(whoosh))
    # 扫频带通：分段近似
    out = np.zeros(len(whoosh))
    seg = len(whoosh) // 8
    for i in range(8):
        a, b = i * seg, (i + 1) * seg if i < 7 else len(whoosh)
        out[a:b] = s.filt(whoosh, "bp", float(f[(a + b) // 2]), 1.2)[a:b]
    out *= s.env(0.55, 0.02, 0.5) * 0.9
    thump = s.sweep(95, 38, 0.2) * s.env(0.2, 0.003, 0.18) * 0.75
    return trim(s.reverb(mix(out, thump), 1.2, 0.35))


def swish(seed):
    s = Synth(seed)
    n = s.noise(0.2)
    out = np.zeros(len(n))
    fs = np.geomspace(700, 3800, 6)
    seg = len(n) // 6
    for i in range(6):
        a, b = i * seg, (i + 1) * seg if i < 5 else len(n)
        out[a:b] = s.filt(n, "bp", float(fs[i]), 2)[a:b]
    return trim(out * s.env(0.2, 0.03, 0.17) * 0.75)


def ting(seed):
    s = Synth(seed)
    k = s.rng.uniform(0.95, 1.05)
    x = mix(s.sweep(2600 * k, 2500 * k, 0.3, "tri") * s.env(0.3, 0.001, 0.25) * 0.4, s.sweep(3900 * k, 3850 * k, 0.22) * s.env(0.22, 0.001, 0.18) * 0.25)
    return trim(s.reverb(x, 1.0, 0.3))


def flame_loop(seed):
    s = Synth(seed)
    roar = s.filt(s.noise(0.25), "lp", 1400) * s.env(0.25, 0.03, 0.22) * 0.5
    crackle = np.zeros(len(roar))
    for _ in range(6):
        at = int(s.rng.uniform(0, 0.2) * SR)
        c = s.filt(s.noise(0.01), "hp", 3000) * s.env(0.01, 0.0005, 0.008) * 0.4
        crackle[at:at + len(c)] += c[: max(0, len(crackle) - at)]
    return trim(mix(roar, crackle))


def spin(seed):
    s = Synth(seed)
    x = mix(s.sweep(180, 900, 0.6, "saw") * s.env(0.6, 0.05, 0.6, "lin") * 0.12, s.filt(s.noise(0.6), "bp", 1800, 3) * s.env(0.6, 0.3, 0.3, "lin") * 0.2)
    return trim(x)


def charge(seed):
    s = Synth(seed)
    x = mix(s.sweep(300, 2400, 1.0) * s.env(1.0, 0.05, 1.0, "lin") * 0.25, s.sweep(302, 2420, 1.0, "tri") * s.env(1.0, 0.05, 1.0, "lin") * 0.12)
    return trim(x)


def rail_shot(seed):
    s = Synth(seed)
    x = mix(s.sweep(3200, 180, 0.35, "saw") * s.env(0.35, 0.002, 0.3) * 0.35, s.filt(s.noise(0.06), "hp", 2000) * s.env(0.06, 0.0005, 0.05) * 1.2,
            s.filt(s.noise(0.5), "lp", 700) * s.env(0.5, 0.003, 0.45), s.sweep(90, 28, 0.4) * s.env(0.4, 0.003, 0.35))
    return trim(s.reverb(x, 1.4, 0.7))


def laser(seed):
    s = Synth(seed)
    k = s.rng.uniform(0.97, 1.03)
    x = mix(s.sweep(880 * k, 860 * k, 0.12, "saw") * s.env(0.12, 0.003, 0.11) * 0.25, s.sweep(1320 * k, 1300 * k, 0.12, "square") * s.env(0.12, 0.003, 0.11) * 0.1)
    return trim(s.filt(x, "lp", 5000))


def bang(seed):
    s = Synth(seed)
    x = mix(s.filt(s.noise(0.08), "hp", 1800) * s.env(0.08, 0.0005, 0.06) * 1.6, s.filt(s.noise(0.7), "lp", 600) * s.env(0.7, 0.003, 0.6) * 1.2,
            s.sweep(70, 25, 0.4) * s.env(0.4, 0.003, 0.35) * 1.1, place(s.sweep(3600, 3550, 1.6) * s.env(1.6, 0.01, 1.6, "lin") * 0.12, 0.05))
    return trim(s.reverb(x, 1.6, 0.6))


def beep(seed):
    s = Synth(seed)
    return trim(mix(s.sweep(1600, 1600, 0.08, "square") * s.env(0.08, 0.002, 0.07) * 0.2, place(s.sweep(2100, 2100, 0.08, "square") * s.env(0.08, 0.002, 0.07) * 0.2, 0.12)))


def bolt(seed):
    s = Synth(seed)
    return trim(mix(click(s, 2100, 7, 0.65, 0.03, 0.0), click(s, 2900, 7, 0.75, 0.025, 0.17)))


def hiss(seed, dur=1.2):
    """烟雾弹 / 照明弹 / 喷气背包的嘶嘶声"""
    s = Synth(seed)
    return trim(s.filt(s.noise(dur), "hp", 2500) * s.env(dur, 0.05, dur * 0.9, "lin") * 0.5)


def jet(seed):
    s = Synth(seed)
    x = mix(s.filt(s.noise(0.6), "lp", 900) * s.env(0.6, 0.02, 0.55) * 0.9, s.filt(s.noise(0.6), "hp", 3000) * s.env(0.6, 0.02, 0.4) * 0.3)
    return trim(x)


def freeze(seed):
    s = Synth(seed)
    parts = [s.filt(s.noise(0.4), "hp", 4000) * s.env(0.4, 0.002, 0.3) * 0.5]
    for i in range(7):
        f = s.rng.uniform(2500, 6000)
        parts.append(place(s.sweep(f, f * 0.96, 0.12, "tri") * s.env(0.12, 0.001, 0.1) * 0.22, i * 0.03))
    return trim(s.reverb(mix(*parts), 1.0, 0.3))


def zap(seed):
    s = Synth(seed)
    x = s.filt(s.noise(0.25), "bp", 3000, 2) * s.env(0.25, 0.001, 0.2) * 0.8
    buzz = s.sweep(120, 110, 0.25, "square") * s.env(0.25, 0.001, 0.2) * 0.25
    return trim(mix(x, buzz))


def teleport(seed):
    s = Synth(seed)
    return trim(s.reverb(mix(s.sweep(300, 2400, 0.35) * s.env(0.35, 0.01, 0.3) * 0.4, s.sweep(1200, 4800, 0.35, "tri") * s.env(0.35, 0.01, 0.3) * 0.15), 1.0, 0.4))


def shield_up(seed):
    s = Synth(seed)
    return trim(s.reverb(mix(s.sweep(400, 1200, 0.3, "tri") * s.env(0.3, 0.01, 0.28) * 0.35, s.sweep(800, 2400, 0.3) * s.env(0.3, 0.01, 0.25) * 0.15), 1.0, 0.35))


def heal(seed):
    s = Synth(seed)
    notes = [660, 880, 1100]
    return trim(mix(*[place(s.sweep(f, f, 0.18, "tri") * s.env(0.18, 0.005, 0.15) * 0.25, i * 0.07) for i, f in enumerate(notes)]))


def skitter(seed):
    """蟑螂爬：快速的细碎咔嗒"""
    s = Synth(seed)
    return trim(mix(*[click(s, s.rng.uniform(3000, 5000), 8, 0.4, 0.008, i * 0.035) for i in range(8)]))


def squeak(seed, low=False):
    """老鼠 / 鼠王叫"""
    s = Synth(seed)
    f0 = s.rng.uniform(1700, 2200) * (0.45 if low else 1.0)
    x = s.sweep(f0, f0 * 1.5, 0.12, "tri") * s.env(0.12, 0.005, 0.1) * 0.4
    y = place(s.sweep(f0 * 1.4, f0 * 0.9, 0.16, "tri") * s.env(0.16, 0.005, 0.14) * 0.35, 0.1)
    out = mix(x, y)
    if low:
        out = s.reverb(mix(out, s.filt(s.noise(0.5), "lp", 400) * s.env(0.5, 0.02, 0.45) * 0.6), 1.4, 0.5)
    return trim(out)


def boss_roar(seed):
    s = Synth(seed)
    growl = s.filt(s.sweep(90, 60, 1.2, "saw"), "lp", 900) * s.env(1.2, 0.08, 1.1, "lin") * 0.6
    sq = mix(*[place(squeak(seed + i, True), i * 0.25) for i in range(2)])
    return trim(s.reverb(mix(growl, sq), 1.8, 0.6))


def fanfare(seed):
    s = Synth(seed)
    notes = [523, 659, 784, 1047]
    return trim(s.reverb(mix(*[place(s.sweep(f, f, 0.26, "square") * s.env(0.26, 0.005, 0.22) * 0.18, i * 0.12) for i, f in enumerate(notes)]), 1.2, 0.3))


def peck(seed):
    s = Synth(seed)
    return trim(mix(click(s, 2600, 6, 0.5, 0.015, 0.0), click(s, 2400, 6, 0.4, 0.015, 0.07)))


def click(s, f, q, g, d, at=0.0):
    return place(s.filt(s.noise(d + 0.02), "bp", f, q) * s.env(d + 0.02, 0.001, d) * g, at)


def reload_seq(cls, seed):
    """换弹：卸弹匣 - 插弹匣 - 上膛（统一 1 秒，Godot 按实际换弹时间调整播放速度和触发点）"""
    s = Synth(seed)
    k = s.rng.uniform(0.95, 1.05)
    if cls == "shotgun":
        parts = []
        for i in range(3):
            at = 0.15 + i * 0.27
            parts.append(click(s, 1900 * k, 5, 0.6, 0.04, at))
            parts.append(click(s, 900 * k, 3, 0.4, 0.06, at + 0.02))
        parts.append(click(s, 1800 * k, 5, 0.75, 0.035, 0.92))
        parts.append(click(s, 2500 * k, 6, 0.85, 0.03, 1.02))
        return trim(s.reverb(mix(*parts), 0.4, 0.08))
    parts = [
        click(s, 1500 * k, 5, 0.6, 0.045, 0.03),
        place(s.filt(s.noise(0.12), "hp", 3000) * s.env(0.12, 0.01, 0.1) * 0.15, 0.08),
        click(s, 2100 * k, 6, 0.8, 0.035, 0.55),
        click(s, 900 * k, 3, 0.4, 0.05, 0.57),
        click(s, 3000 * k, 7, 0.75, 0.025, 0.88 if cls == "rifle" else 0.82),
    ]
    if cls == "rifle":
        parts.append(click(s, 2600 * k, 7, 0.7, 0.025, 0.95))
    return trim(s.reverb(mix(*parts), 0.4, 0.08))


def pump(seed):
    s = Synth(seed)
    return trim(mix(click(s, 1800, 5, 0.75, 0.035, 0.0), click(s, 2500, 6, 0.85, 0.03, 0.13), click(s, 700, 2, 0.35, 0.08, 0.01)))


def empty(seed):
    s = Synth(seed)
    return trim(mix(click(s, 4200, 9, 0.6, 0.015), click(s, 2200, 4, 0.25, 0.02, 0.005)))


def hitmark(seed):
    s = Synth(seed)
    f = s.rng.uniform(1700, 1900)
    return trim(s.sweep(f, f * 0.85, 0.045, "square") * s.env(0.045, 0.002, 0.04) * 0.4)


def hit_flesh(seed):
    s = Synth(seed)
    f = s.rng.uniform(850, 1000)
    x = mix(s.sweep(f, 420, 0.06, "tri") * s.env(0.06, 0.002, 0.05) * 0.5, s.filt(s.noise(0.05), "lp", 1800) * s.env(0.05, 0.001, 0.035) * 0.4)
    return trim(x)


def hurt_squeak(seed):
    s = Synth(seed)
    k = s.rng.uniform(0.9, 1.15)
    x = mix(s.sweep(1100 * k, 1700 * k, 0.07, "sine") * s.env(0.07, 0.004, 0.06) * 0.5,
            place(s.sweep(1500 * k, 900 * k, 0.1, "sine") * s.env(0.1, 0.003, 0.08) * 0.45, 0.05),
            s.sweep(380, 120, 0.18) * s.env(0.18, 0.003, 0.15) * 0.4)
    return trim(s.reverb(x, 0.5, 0.12))


def death(seed):
    s = Synth(seed)
    x = mix(s.sweep(1500, 2400, 0.07) * s.env(0.07, 0.003, 0.06) * 0.6,
            place(s.sweep(2200, 600, 0.22) * s.env(0.22, 0.003, 0.2) * 0.55, 0.07),
            s.filt(s.noise(0.15), "lp", 1800) * s.env(0.15, 0.002, 0.12) * 0.4,
            place(s.sweep(300, 70, 0.25) * s.env(0.25, 0.005, 0.22) * 0.6, 0.12))
    return trim(s.reverb(x, 0.8, 0.2))


def step(seed, surface):
    s = Synth(seed)
    if surface == "wood":
        x = mix(s.filt(s.noise(0.06), "bp", s.rng.uniform(700, 1000), 1.5) * s.env(0.06, 0.002, 0.04) * 0.6,
                s.sweep(160, 90, 0.04) * s.env(0.04, 0.002, 0.03) * 0.3)
    else:
        x = s.filt(s.noise(0.08), "lp", s.rng.uniform(900, 1300)) * s.env(0.08, 0.004, 0.05) * 0.5
    return trim(x * 0.7)


def roll(seed):
    s = Synth(seed)
    n = s.noise(0.25)
    b, a = signal.butter(2, [400 / (SR / 2), 1600 / (SR / 2)], "band")
    sweep = s.filt(n, "bp", 900, 1.2) * s.env(0.25, 0.04, 0.2)
    return trim(sweep * 0.7)


def boing(seed, up=True):
    s = Synth(seed)
    if up:
        x = mix(s.sweep(300, 900, 0.18) * s.env(0.18, 0.004, 0.16) * 0.6, place(s.sweep(600, 1300, 0.14, "tri") * s.env(0.14, 0.003, 0.12) * 0.25, 0.03))
        # 弹簧颤音
        t = s.t(0.3)
        x = mix(x, np.sin(2 * np.pi * 220 * t + 3 * np.sin(2 * np.pi * 18 * t)) * s.env(0.3, 0.01, 0.25) * 0.25)
    else:
        x = s.sweep(900, 400, 0.16) * s.env(0.16, 0.003, 0.14) * 0.5
    return trim(x)


def thud(seed):
    s = Synth(seed)
    return trim(s.reverb(mix(s.sweep(140, 45, 0.24) * s.env(0.24, 0.003, 0.2) * 0.9, s.filt(s.noise(0.14), "lp", 800) * s.env(0.14, 0.002, 0.1) * 0.45), 0.6, 0.15))


def boom(seed, big=False):
    s = Synth(seed)
    d = 1.3 if big else 0.9
    x = mix(s.filt(s.noise(d), "lp", 380 if big else 520, order=3) * s.env(d, 0.004, d * 0.85) * 1.3,
            s.filt(s.noise(0.06), "hp", 1500) * s.env(0.06, 0.001, 0.04) * 0.6,
            s.sweep(72, 24, 0.6 if big else 0.4) * s.env(0.6 if big else 0.4, 0.004, 0.5) * 1.1,
            place(s.filt(s.noise(0.5), "bp", 2500, 2) * s.env(0.5, 0.05, 0.4) * 0.12, 0.1))  # 碎屑
    return trim(s.reverb(x, 1.6, 0.6))


def glass(seed):
    s = Synth(seed)
    parts = [s.filt(s.noise(0.25), "hp", 3000) * s.env(0.25, 0.001, 0.2) * 0.7]
    for i in range(6):
        f = s.rng.uniform(3500, 7500)
        parts.append(place(s.sweep(f, f * 0.98, 0.09) * s.env(0.09, 0.001, 0.08) * 0.22, i * 0.025 + s.rng.uniform(0, 0.02)))
    parts.append(place(s.filt(s.noise(0.4), "lp", 500) * s.env(0.4, 0.04, 0.3) * 0.4, 0.02))
    return trim(s.reverb(mix(*parts), 0.8, 0.3))


def crate_open(seed):
    s = Synth(seed)
    x = mix(s.filt(s.noise(0.18), "bp", 600, 1.0) * s.env(0.18, 0.003, 0.15) * 0.7,
            s.sweep(500, 900, 0.08) * s.env(0.08, 0.003, 0.07) * 0.4,
            place(s.sweep(1320, 1320, 0.1, "tri") * s.env(0.1, 0.003, 0.09) * 0.25, 0.08),
            place(s.sweep(1760, 1760, 0.14, "tri") * s.env(0.14, 0.003, 0.12) * 0.25, 0.14))
    return trim(x)


def munch(seed):
    s = Synth(seed)
    f = s.rng.uniform(380, 700)
    x = mix(s.sweep(f, f * 1.6, 0.07) * s.env(0.07, 0.003, 0.06) * 0.5, place(s.filt(s.noise(0.05), "bp", 1500, 2) * s.env(0.05, 0.002, 0.04) * 0.25, 0.01))
    return trim(x)


def tink(seed):
    s = Synth(seed)
    f = s.rng.uniform(4200, 6800)
    return trim(mix(s.sweep(f, f * 0.97, 0.06) * s.env(0.06, 0.001, 0.05) * 0.35, place(s.sweep(f * 1.02, f, 0.04) * s.env(0.04, 0.001, 0.035) * 0.16, 0.07)))


def ricochet(seed):
    s = Synth(seed)
    return trim(s.reverb(s.sweep(2400 * s.rng.uniform(0.9, 1.1), 900, 0.25) * s.env(0.25, 0.002, 0.22) * 0.35, 0.6, 0.3))


def wall_hit(seed):
    s = Synth(seed)
    return trim(mix(s.filt(s.noise(0.05), "bp", 3000, 1.5) * s.env(0.05, 0.001, 0.035) * 0.5, s.filt(s.noise(0.08), "lp", 600) * s.env(0.08, 0.001, 0.05) * 0.3))


def throw(seed):
    s = Synth(seed)
    n = s.noise(0.22)
    x = s.filt(n, "bp", 900, 1.5) * s.env(0.22, 0.05, 0.18) * 0.6
    return trim(x)


def clank(seed):
    s = Synth(seed)
    return trim(mix(s.sweep(1400, 1300, 0.08, "tri") * s.env(0.08, 0.001, 0.07) * 0.4, s.filt(s.noise(0.04), "bp", 2600, 4) * s.env(0.04, 0.001, 0.03) * 0.3))


def levelup(seed):
    s = Synth(seed)
    notes = [523, 659, 784, 1047]
    parts = [place(s.sweep(f, f, 0.22, "tri") * s.env(0.22, 0.004, 0.2) * 0.3, i * 0.07) for i, f in enumerate(notes)]
    parts.append(place(s.sweep(2093, 2093, 0.3, "sine") * s.env(0.3, 0.004, 0.28) * 0.15, 0.28))
    return trim(s.reverb(mix(*parts), 1.0, 0.25))


def card_pick(seed):
    s = Synth(seed)
    return trim(mix(s.sweep(500, 900, 0.08) * s.env(0.08, 0.002, 0.07) * 0.5, place(s.sweep(1320, 1320, 0.1, "tri") * s.env(0.1, 0.002, 0.09) * 0.25, 0.07), place(s.sweep(1760, 1760, 0.15, "tri") * s.env(0.15, 0.002, 0.13) * 0.25, 0.13)))


def ui_click(seed):
    s = Synth(seed)
    return trim(s.sweep(700, 900, 0.05) * s.env(0.05, 0.002, 0.045) * 0.5)


def ui_hover(seed):
    s = Synth(seed)
    return trim(s.sweep(1500, 1700, 0.03, "tri") * s.env(0.03, 0.002, 0.025) * 0.25)


def card_appear(seed):
    s = Synth(seed)
    return trim(mix(s.filt(s.noise(0.2), "bp", 2000, 1.0) * s.env(0.2, 0.08, 0.12) * 0.3, place(s.sweep(880, 1320, 0.12, "tri") * s.env(0.12, 0.003, 0.1) * 0.25, 0.1)))


def respawn(seed):
    s = Synth(seed)
    return trim(s.reverb(mix(s.sweep(400, 1200, 0.25) * s.env(0.25, 0.01, 0.22) * 0.4, place(s.sweep(1600, 1600, 0.15, "tri") * s.env(0.15, 0.003, 0.12) * 0.2, 0.2)), 0.8, 0.3))


def alert(seed):
    s = Synth(seed)
    return trim(mix(s.sweep(880, 1320, 0.08, "square") * s.env(0.08, 0.002, 0.07) * 0.2, place(s.sweep(1320, 1760, 0.1, "square") * s.env(0.1, 0.002, 0.08) * 0.2, 0.1)))


def win(seed):
    s = Synth(seed)
    notes = [523, 659, 784, 1047, 1319]
    return trim(s.reverb(mix(*[place(s.sweep(f, f, 0.3, "tri") * s.env(0.3, 0.004, 0.28) * 0.3, i * 0.11) for i, f in enumerate(notes)]), 1.2, 0.3))


def lose(seed):
    s = Synth(seed)
    notes = [392, 330, 262, 196]
    return trim(s.reverb(mix(*[place(s.sweep(f, f * 0.98, 0.35, "tri") * s.env(0.35, 0.004, 0.32) * 0.3, i * 0.15) for i, f in enumerate(notes)]), 1.2, 0.3))


def ambience(seed):
    """夜里屋子的底噪：冰箱嗡嗡 + 很轻的空气声，可循环（8 秒）。"""
    s = Synth(seed)
    d = 8.0
    t = s.t(d)
    hum = (np.sin(2 * np.pi * 58 * t) * 0.5 + np.sin(2 * np.pi * 117 * t) * 0.25) * 0.06
    air = s.filt(s.noise(d), "lp", 500) * 0.05
    x = hum + air
    f = int(0.5 * SR)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    return x


SOUNDS = {
    "shot_pistol": (lambda sd: gun_shot("pistol", sd), 4),
    "shot_ak47": (lambda sd: gun_shot("ak47", sd), 4),
    "shot_shotgun": (lambda sd: gun_shot("shotgun", sd), 3),
    "shot_minion": (lambda sd: gun_shot("minion", sd), 3),
    "shot_turret": (lambda sd: gun_shot("turret", sd), 3),
    "reload_pistol": (lambda sd: reload_seq("pistol", sd), 3),
    "reload_rifle": (lambda sd: reload_seq("rifle", sd), 3),
    "reload_shotgun": (lambda sd: reload_seq("shotgun", sd), 3),
    "pump": (pump, 3),
    "empty": (empty, 3),
    "hitmark": (hitmark, 3),
    "hit": (hit_flesh, 4),
    "hurt": (hurt_squeak, 4),
    "death": (death, 3),
    "step_wood": (lambda sd: step(sd, "wood"), 6),
    "step_carpet": (lambda sd: step(sd, "carpet"), 6),
    "roll": (roll, 3),
    "boing": (lambda sd: boing(sd, True), 3),
    "thud": (thud, 3),
    "boom_small": (lambda sd: boom(sd, False), 3),
    "boom_big": (lambda sd: boom(sd, True), 3),
    "glass": (glass, 3),
    "crate_open": (crate_open, 3),
    "munch": (munch, 5),
    "tink": (tink, 5),
    "ricochet": (ricochet, 3),
    "wall_hit": (wall_hit, 4),
    "throw": (throw, 3),
    "clank": (clank, 3),
    "levelup": (levelup, 3),
    "card_pick": (card_pick, 3),
    "card_appear": (card_appear, 3),
    "ui_click": (ui_click, 3),
    "ui_hover": (ui_hover, 3),
    "respawn": (respawn, 3),
    "alert": (alert, 3),
    "win": (win, 1),
    "lose": (lose, 1),
    "ambience": (ambience, 1),
    # 批次 2
    "shot_deagle": (lambda sd: gun_shot("deagle", sd), 3),
    "shot_smg": (lambda sd: gun_shot("smg", sd), 4),
    "shot_sniper": (lambda sd: gun_shot("sniper", sd), 3),
    "shot_lmg": (lambda sd: gun_shot("lmg", sd), 4),
    "shot_rat": (lambda sd: gun_shot("rat", sd), 3),
    "shot_minigun": (lambda sd: gun_shot("minigun", sd), 4),
    "shot_autoshot": (lambda sd: gun_shot("autoshot", sd), 3),
    "shot_amr": (lambda sd: gun_shot("amr", sd), 3),
    "shot_revolver": (lambda sd: gun_shot("revolver", sd), 3),
    "shot_gl": (lambda sd: gun_shot("gl", sd), 3),
    "shot_sentry": (lambda sd: gun_shot("sentry", sd), 3),
    "shot_dual": (lambda sd: gun_shot("dual", sd), 4),
    "shot_rocket": (rocket, 3),
    "swish": (swish, 4),
    "ting": (ting, 3),
    "flame": (flame_loop, 4),
    "spin": (spin, 2),
    "charge": (charge, 2),
    "shot_rail": (rail_shot, 3),
    "shot_laser": (laser, 3),
    "bang": (bang, 2),
    "beep": (beep, 2),
    "bolt": (bolt, 3),
    "hiss": (hiss, 2),
    "jet": (jet, 2),
    "freeze": (freeze, 3),
    "zap": (zap, 4),
    "teleport": (teleport, 2),
    "shield_up": (shield_up, 2),
    "heal": (heal, 2),
    "skitter": (skitter, 3),
    "squeak": (squeak, 4),
    "boss_roar": (boss_roar, 2),
    "fanfare": (fanfare, 1),
    "peck": (peck, 3),
}


def write_ogg(path, x):
    x = normalize(x, -1.0 if "ambience" not in path else -12.0)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp = f.name
    wavfile.write(tmp, SR, (x * 32767).astype(np.int16))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", path], check=True)
    os.unlink(tmp)


def main():
    args = sys.argv[1:]
    only = None
    if "--only" in args:
        only = set(args[args.index("--only") + 1].split(","))
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for name, (fn, variants) in SOUNDS.items():
        if only and name not in only:
            continue
        for v in range(variants):
            seed = (abs(hash(name)) % 100000) * 10 + v if False else (sum(ord(c) for c in name) * 131 + v * 7919)
            x = fn(seed)
            write_ogg(os.path.join(OUT, f"{name}_{v}.ogg"), x)
            n += 1
    print(f"[audio] 生成 {n} 个音效到 {OUT}")


if __name__ == "__main__":
    main()
