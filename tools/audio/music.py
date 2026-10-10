"""音乐离线合成（批次 3）。全部乐器都是数学合成（FM 电钢、加法合成铜管 / 钢片琴 / 马林巴 / 贝斯、噪声鼓组），
没有任何外部采样或素材。和弦进行、旋律都是写死的乐谱，随机数只用来做人性化（力度、微小的时间偏差），种子固定，可复现。

    python3 tools/audio/music.py --all
    python3 tools/audio/music.py --only menu,match
    python3 tools/audio/music.py --analyze          # 只分析已生成的 OGG（峰值 / 响度 / 接缝 / 频谱）并出图

输出：game/assets/audio/music/<名称>.ogg（Vorbis q5，44.1 kHz 立体声）
自检图和数据：review/batch3/audio/<名称>.png、music_stats.json

循环曲的无缝做法：整首按“环形时间”渲染——跨过结尾的音符尾巴、混响尾巴绕回开头叠加；
滤波器先用曲尾预热（等于稳态），混响用循环卷积，限幅器的增益曲线也按环形平滑，所以首尾样本是连续的。
"""
import json
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile
from scipy.ndimage import minimum_filter1d, uniform_filter1d

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "game", "assets", "audio", "music")
REVIEW = os.path.join(ROOT, "review", "batch3", "audio")
TWO_PI = 2.0 * np.pi


# ---------------------------------------------------------------------------
# 乐理
# ---------------------------------------------------------------------------
PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
QUAL = {
    "": [0, 4, 7], "m": [0, 3, 7], "6": [0, 4, 7, 9], "m6": [0, 3, 7, 9], "maj7": [0, 4, 7, 11], "maj9": [0, 4, 7, 11, 14],
    "m7": [0, 3, 7, 10], "m9": [0, 3, 7, 10, 14], "7": [0, 4, 7, 10], "9": [0, 4, 7, 10, 14], "13": [0, 4, 7, 10, 14, 21],
    "7b9": [0, 4, 7, 10, 13], "m7b5": [0, 3, 6, 10], "dim7": [0, 3, 6, 9], "7sus4": [0, 5, 7, 10], "sus4": [0, 5, 7],
}


def midi(name):
    """'C#4' / 'Bb3' / 'Eb5' -> MIDI 音高。"""
    i, acc = 1, 0
    while i < len(name) and name[i] in "#b":
        acc += 1 if name[i] == "#" else -1
        i += 1
    return 12 * (int(name[i:]) + 1) + PC[name[0]] + acc


def hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def chord(sym):
    """'Fmaj9' / 'Em7b5' / 'Dm/C' -> {root, iv, bass}（音级 0..11）。"""
    bass = None
    if "/" in sym:
        sym, b = sym.split("/")
        bass = (PC[b[0]] + (1 if b[1:] == "#" else -1 if b[1:] == "b" else 0)) % 12
    i, acc = 1, 0
    while i < len(sym) and sym[i] in "#b" and sym[i:] not in QUAL:
        acc += 1 if sym[i] == "#" else -1
        i += 1
    root = (PC[sym[0]] + acc) % 12
    return {"root": root, "iv": QUAL[sym[i:]], "bass": root if bass is None else bass, "sym": sym}


def progression(bars):
    """每小节一个字符串，'A|B' 表示前后半小节各一个和弦 -> [(起始拍, 拍数, 和弦)]。"""
    out = []
    for b, s in enumerate(bars):
        parts = s.split("|")
        d = 4.0 / len(parts)
        for j, p in enumerate(parts):
            out.append((b * 4.0 + j * d, d, chord(p)))
    return out


def chord_at(prog, beat):
    for st, d, c in prog:
        if st <= beat + 1e-6 < st + d:
            return c
    return prog[-1][2]


def mel(text, start=0.0, bars=None):
    """'r:1 C5:.5 E5:.5 ...' -> [(拍, 时值, midi 或 None)]；给了 bars 就检查总时值。"""
    out, b = [], start
    for tok in text.split():
        p, d = tok.split(":")
        d = float(d)
        out.append((b, d, None if p == "r" else midi(p)))
        b += d
    if bars is not None:
        assert abs(b - start - bars * 4) < 1e-6, f"旋律时值不对：{b - start} 拍，应为 {bars * 4}（{text[:40]}…）"
    return out


def near(pc, lo):
    """音级 pc 在 [lo, lo+11] 里的那个音。"""
    return lo + (pc - lo) % 12


def voicing(c, lo, hi, prev=None, rootless=True, maxn=4):
    iv = list(c["iv"])
    if rootless and len(iv) >= 4:
        iv = [i for i in iv if i % 12 != 0]
    while len(iv) > maxn and 7 in iv:
        iv.remove(7)
    iv = iv[:maxn]
    pcs = sorted(set((c["root"] + i) % 12 for i in iv))
    best, bc = None, 1e9
    for first in pcs:
        for o in range(lo, lo + 12):
            if o % 12 != first:
                continue
            notes = [o]
            k = pcs.index(first)
            for j in range(1, len(pcs)):
                p = pcs[(k + j) % len(pcs)]
                notes.append(notes[-1] + ((p - notes[-1]) % 12 or 12))
            if notes[-1] > hi:
                continue
            if prev:
                if len(prev) == len(notes):
                    cost = sum(abs(a - b) for a, b in zip(sorted(prev), notes))
                else:
                    cost = abs(np.mean(prev) - np.mean(notes)) * len(notes)
            else:
                cost = abs(np.mean(notes) - (lo + hi) / 2)
            if cost < bc:
                best, bc = notes, cost
    return best


def chord_tone(c, kind):
    iv = c["iv"]
    if kind == "fifth":
        return 6 if 6 in iv else (8 if 8 in iv else 7)
    if kind == "third":
        return 3 if 3 in iv else (5 if 5 in iv and 4 not in iv else 4)
    if kind == "seventh":
        for x in (10, 11, 9):
            if x in iv:
                return x
        return 12
    return 0


# ---------------------------------------------------------------------------
# 基础 DSP
# ---------------------------------------------------------------------------

def tl(n):
    return np.arange(n, dtype=np.float64) / SR


def env_adsr(n_on, n, a, d, s, r):
    """ADSR：线性起音，指数衰减到 s，松开后指数释放（r 秒后约 -40 dB），最后 3 ms 归零。"""
    t = tl(n)
    a = max(a, 1e-4)
    e = np.where(t < a, t / a, s + (1 - s) * np.exp(-np.maximum(t - a, 0) / max(d, 1e-4)))
    if n_on < n:
        lvl = e[max(n_on - 1, 0)]
        tr = t[n_on:] - t[n_on]
        e[n_on:] = lvl * np.exp(-tr / max(r / 4.6, 1e-4))
    f = min(int(0.003 * SR), n)
    e[n - f:] *= np.linspace(1, 0, f)
    return e


def biquad(kind, f, q=0.707, db=0.0):
    w = TWO_PI * f / SR
    cw, sw = np.cos(w), np.sin(w)
    al = sw / (2 * q)
    A = 10 ** (db / 40)
    if kind == "peak":
        b = [1 + al * A, -2 * cw, 1 - al * A]
        a = [1 + al / A, -2 * cw, 1 - al / A]
    elif kind == "lowshelf":
        sa = 2 * np.sqrt(A) * al
        b = [A * ((A + 1) - (A - 1) * cw + sa), 2 * A * ((A - 1) - (A + 1) * cw), A * ((A + 1) - (A - 1) * cw - sa)]
        a = [(A + 1) + (A - 1) * cw + sa, -2 * ((A - 1) + (A + 1) * cw), (A + 1) + (A - 1) * cw - sa]
    elif kind == "highshelf":
        sa = 2 * np.sqrt(A) * al
        b = [A * ((A + 1) + (A - 1) * cw + sa), -2 * A * ((A - 1) + (A + 1) * cw), A * ((A + 1) + (A - 1) * cw - sa)]
        a = [(A + 1) - (A - 1) * cw + sa, 2 * ((A - 1) - (A + 1) * cw), (A + 1) - (A - 1) * cw - sa]
    elif kind == "hp":
        b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
        a = [1 + al, -2 * cw, 1 - al]
    elif kind == "lp":
        b = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2]
        a = [1 + al, -2 * cw, 1 - al]
    elif kind == "bp":
        b = [al, 0, -al]
        a = [1 + al, -2 * cw, 1 - al]
    else:
        raise ValueError(kind)
    return np.array(b) / a[0], np.array(a) / a[0]


def filt(x, kind, f, q=0.707, db=0.0, loop=False):
    """单个双二阶滤波；loop=True 时用曲尾预热（稳态），保证循环接缝连续。"""
    b, a = biquad(kind, f, q, db)
    if not loop:
        return signal.lfilter(b, a, x, axis=-1)
    pre = min(x.shape[-1], SR * 2)
    xx = np.concatenate([x[..., -pre:], x], axis=-1)
    return signal.lfilter(b, a, xx, axis=-1)[..., pre:]


def chain(x, eq, loop=False):
    for e in eq:
        k = e[0]
        if k in ("hp", "lp"):
            x = filt(x, k, e[1], e[2] if len(e) > 2 else 0.707, loop=loop)
            if len(e) > 3 and e[3] == 4:      # 4 阶
                x = filt(x, k, e[1], e[2], loop=loop)
        elif k == "bp":
            x = filt(x, "bp", e[1], e[2], loop=loop)
        else:
            x = filt(x, k, e[1], e[3] if len(e) > 3 else 0.8, e[2], loop=loop)
    return x


def noise(rng, n):
    return rng.uniform(-1, 1, n)


# ---------------------------------------------------------------------------
# 响度（ITU-R BS.1770 K 计权 + 门限）和限幅
# ---------------------------------------------------------------------------

def kweight(x):
    b1, a1 = biquad("highshelf", 1681.97, 0.7072, 4.0)
    b2, a2 = biquad("hp", 38.135, 0.5003)
    return signal.lfilter(b2, a2, signal.lfilter(b1, a1, x, axis=-1), axis=-1)


def lufs(x):
    x = np.atleast_2d(x)
    y = kweight(x)
    blk, hop = int(0.4 * SR), int(0.1 * SR)
    if y.shape[1] < blk:
        p = np.mean(y ** 2, axis=1).sum()
        return -0.691 + 10 * np.log10(p + 1e-12)
    cs = np.concatenate([np.zeros((y.shape[0], 1)), np.cumsum(y ** 2, axis=1)], axis=1)
    starts = np.arange(0, y.shape[1] - blk + 1, hop)
    pw = ((cs[:, starts + blk] - cs[:, starts]) / blk).sum(axis=0)
    ld = -0.691 + 10 * np.log10(pw + 1e-12)
    g = pw[ld > -70]
    if len(g) == 0:
        return -120.0
    rel = -0.691 + 10 * np.log10(np.mean(g)) - 10
    g2 = pw[(ld > -70) & (ld > rel)]
    return -0.691 + 10 * np.log10(np.mean(g2) + 1e-12)


def limiter(x, ceil_db, loop):
    """前瞻限幅：所需增益先取窗口最小值，再用同宽滑动平均平滑（结果仍不超过所需增益）。"""
    ceil = 10 ** (ceil_db / 20)
    a = np.max(np.abs(x), axis=0)
    g = np.minimum(1.0, ceil / np.maximum(a, 1e-9))
    w = int(0.003 * SR) * 2 + 1
    mode = "wrap" if loop else "nearest"
    g = minimum_filter1d(g, w, mode=mode)
    g = uniform_filter1d(g, w, mode=mode)
    # 释放：再做一次更长的最小值 + 平均，避免逐拍抽吸感太碎
    w2 = int(0.03 * SR) * 2 + 1
    g2 = uniform_filter1d(minimum_filter1d(g, w2, mode=mode), w2, mode=mode)
    g = 0.5 * g + 0.5 * g2
    return x * g


# ---------------------------------------------------------------------------
# 乐器（全部返回单声道数组，长度 = 按住时长 + 释放尾巴）
# ---------------------------------------------------------------------------

def rhodes(f, dur, vel, rng, rel=0.35):
    """FM 电钢：1:1 调制（起音亮、随后变圆）+ 14:1 的音叉“叮”。"""
    n_on = int(dur * SR)
    tau = 2.6 * (220.0 / f) ** 0.45
    n = n_on + int(rel * SR)
    t = tl(n)
    I = (1.0 + 2.6 * vel) * np.exp(-t / 0.4) + 1.1 * vel
    car = np.sin(TWO_PI * f * t + I * np.sin(TWO_PI * f * t + rng.uniform(0, 6.28)))
    body = 0.6 * np.sin(TWO_PI * f * t)
    x = (car + body) * np.exp(-t / tau)
    if f * 14 < 9000:
        x += 0.16 * vel * np.sin(TWO_PI * f * 14 * t) * np.exp(-t / 0.018)
    x = x + 0.12 * x ** 2      # 一点偶次谐波（拾音器的“咬”）
    e = env_adsr(n_on, n, 0.002, 10.0, 1.0, rel)
    return x * e * vel


def celesta(f, dur, vel, rng):
    n = int(min(dur + 0.9, 2.6) * SR)
    t = tl(n)
    d = 1.3 * (523.0 / f) ** 0.4
    x = (np.sin(TWO_PI * f * t) * np.exp(-t / d)
         + 0.22 * vel * np.sin(TWO_PI * 2.0 * f * t + 1.0) * np.exp(-t / (d * 0.3))
         + 0.06 * vel * np.sin(TWO_PI * 3.0 * f * t + 2.0) * np.exp(-t / (d * 0.12))
         + 0.10 * vel * np.sin(TWO_PI * 4.17 * f * t) * np.exp(-t / 0.05))
    x += 0.04 * filt(noise(rng, n), "bp", 3000, 2) * np.exp(-t / 0.004)
    a = int(0.002 * SR)
    x[:a] *= np.linspace(0, 1, a)
    x[-int(0.02 * SR):] *= np.linspace(1, 0, int(0.02 * SR))
    return x * vel


def marimba(f, dur, vel, rng):
    n = int(min(dur + 0.6, 1.6) * SR)
    t = tl(n)
    d = 0.5 * (440.0 / f) ** 0.35
    x = (np.sin(TWO_PI * f * t) * np.exp(-t / d)
         + 0.28 * vel * np.sin(TWO_PI * 3.93 * f * t) * np.exp(-t / 0.07)
         + 0.06 * vel * np.sin(TWO_PI * 9.2 * f * t) * np.exp(-t / 0.018))
    x += 0.10 * filt(noise(rng, n), "lp", 1800) * np.exp(-t / 0.006)
    a = int(0.0015 * SR)
    x[:a] *= np.linspace(0, 1, a)
    x[-int(0.02 * SR):] *= np.linspace(1, 0, int(0.02 * SR))
    return x * vel


def pluck(f, dur, vel, rng, decay=1.0, kdecay=2.0, tilt=1.0, pos=0.0, rel=0.04, nh=30, fmax=9000):
    """加法合成的拨弦：每个谐波各自衰减（高次衰减更快 = 滤波包络），pos 是拾音位置梳状。"""
    n_on = int(dur * SR)
    n = n_on + int(rel * SR)
    t = tl(n)
    x = np.zeros(n)
    for k in range(1, nh + 1):
        fk = f * k
        if fk > fmax:
            break
        amp = 1.0 / k ** tilt * (vel ** (0.15 * (k - 1)))
        if pos > 0:
            amp *= abs(np.sin(np.pi * k * pos)) + 0.05
        x += amp * np.sin(TWO_PI * fk * t + rng.uniform(0, 6.28)) * np.exp(-t * (1.0 / decay + kdecay * (k - 1)))
    e = env_adsr(n_on, n, 0.0015, 10.0, 1.0, rel)
    return x * e * vel


def upright(f, dur, vel, rng):
    """低音提琴：圆、短，带一点指头的“噗”。"""
    x = pluck(f, dur, vel, rng, decay=1.2, kdecay=1.6, tilt=1.4, pos=0.18, rel=0.08, nh=14, fmax=1800)
    n = len(x)
    t = tl(n)
    x += 0.5 * vel * np.sin(TWO_PI * f * t) * np.exp(-t / 0.9) * env_adsr(int(dur * SR), n, 0.004, 10, 1, 0.08)
    x += 0.15 * vel * filt(noise(rng, n), "lp", 400) * np.exp(-t / 0.01)
    return x


def funk_bass(f, dur, vel, rng):
    """电贝斯（指弹偏亮）：锯齿谐波 + 滤波包络 + 一点过载 + 正弦低频打底。"""
    x = pluck(f, dur, vel, rng, decay=0.9, kdecay=3.2, tilt=1.0, pos=0.12, rel=0.05, nh=24, fmax=3500)
    n = len(x)
    t = tl(n)
    x += 0.7 * vel * np.sin(TWO_PI * f * t) * env_adsr(int(dur * SR), n, 0.003, 0.6, 0.6, 0.05)
    return np.tanh(1.6 * x) / 1.6


def clav(f, dur, vel, rng):
    return pluck(f, dur, vel, rng, decay=0.35, kdecay=4.5, tilt=0.8, pos=0.11, rel=0.025, nh=24, fmax=6500)


def harp(f, dur, vel, rng):
    """弹拨琶音（介于竖琴和尼龙吉他之间）。"""
    return pluck(f, dur, vel, rng, decay=0.9, kdecay=1.6, tilt=1.3, pos=0.2, rel=0.12, nh=18, fmax=6000)


def pizz(f, dur, vel, rng):
    return pluck(f, dur, vel, rng, decay=0.35, kdecay=3.0, tilt=1.2, pos=0.15, rel=0.06, nh=20, fmax=5000)


def additive_lead(f, dur, vel, rng, amps, a=0.03, d=0.3, s=0.8, rel=0.09, vib=0.006, vib_rate=5.5, scoop=0.6):
    n_on = int(dur * SR)
    n = n_on + int(rel * SR)
    t = tl(n)
    vd = vib * np.clip((t - 0.16) / 0.25, 0, 1)
    ratio = (1 + vd * np.sin(TWO_PI * vib_rate * t + rng.uniform(0, 6.28))) * 2 ** (-scoop / 12 * np.exp(-t / 0.03))
    ph = TWO_PI * np.cumsum(f * ratio) / SR
    x = np.zeros(n)
    for k, A in enumerate(amps, 1):
        if f * k > 9000:
            break
        x += A * np.sin(k * ph + (k - 1) * 0.7)
    return x * env_adsr(n_on, n, a, d, s, rel) * vel


def ocarina(f, dur, vel, rng):
    x = additive_lead(f, dur, vel, rng, [1.0, 0.3, 0.16, 0.08, 0.04], a=0.025, d=0.4, s=0.82, rel=0.08)
    n = len(x)
    br = filt(noise(rng, n), "bp", min(f * 2.0, 4000), 1.5) * 0.035 * vel
    br *= env_adsr(int(dur * SR), n, 0.01, 0.08, 0.4, 0.06)
    return x + br


def pulse_lead(f, dur, vel, rng):
    """柔和的脉冲波主旋律（加速决战用，比陶笛更“紧”）。"""
    p = 0.3
    amps = [(abs(np.sin(np.pi * k * p)) / k) * np.exp(-(k - 1) / 5.0) for k in range(1, 14)]
    return additive_lead(f, dur, vel, rng, amps, a=0.012, d=0.25, s=0.7, rel=0.07, vib=0.004, scoop=0.3) * 1.4


def brass(f, dur, vel, rng, a=0.045, rel=0.12, vib=0.0045, bright=1.0, mute=None, bend=None, scoop=0.5, s=0.8):
    """加法合成铜管：越响越亮（第 k 谐波振幅 ∝ 包络^(1+0.25(k-1)/bright)），起音有一点“噗”的过冲。
    mute(t) -> 0..1 是弱音器开合（哇音）；bend(t) -> 频率倍数。"""
    n_on = int(dur * SR)
    n = n_on + int(rel * SR)
    t = tl(n)
    e = env_adsr(n_on, n, a, 0.2, s, rel)
    e = e * (1 + 0.18 * np.exp(-np.maximum(t - a, 0) / 0.06) * (t >= a))
    ev = np.clip(e * (0.55 + 0.45 * vel), 0, 1.2)
    vd = vib * np.clip((t - 0.2) / 0.3, 0, 1)
    ratio = (1 + vd * np.sin(TWO_PI * 5.2 * t + rng.uniform(0, 6.28))) * 2 ** (-scoop / 12 * np.exp(-t / 0.035))
    if bend is not None:
        ratio = ratio * bend(t)
    ph = TWO_PI * np.cumsum(f * ratio) / SR
    K = int(min(36, 8000 / f))
    m = None if mute is None else (0.1 + 0.9 * np.clip(mute(t), 0, 1))
    x = np.zeros(n)
    for k in range(1, K + 1):
        h = (1.0 / k) * ev ** (0.25 * (k - 1) / bright)
        if m is not None:
            h = h * m ** (0.55 * (k - 1))
        x += h * np.sin(k * ph + rng.uniform(0, 6.28))
    x *= e
    x += filt(noise(rng, n), "bp", min(f * 3, 3000), 1.0) * 0.04 * np.exp(-t / 0.03)
    return x * vel


def pad(f, dur, vel, rng, rel=0.7):
    """三声部失谐锯齿弦乐垫底，谐波滚降很快，只负责“暖”。"""
    n_on = int(dur * SR)
    n = n_on + int(rel * SR)
    t = tl(n)
    x = np.zeros(n)
    for det in (-0.006, 0.0, 0.0055):
        ff = f * (1 + det)
        for k in range(1, 20):
            if ff * k > 5000:
                break
            x += (1.0 / k) * np.exp(-(k - 1) / 3.5) * np.sin(TWO_PI * ff * k * t + rng.uniform(0, 6.28))
    return x * env_adsr(n_on, n, 0.35, 1.0, 1.0, rel) * vel / 3


def tuba(f, dur, vel, rng):
    return brass(f, dur, vel, rng, a=0.035, rel=0.1, vib=0.0, bright=0.55, scoop=0.3, s=0.75)


def sub(f, dur, vel, rng):
    n_on = int(dur * SR)
    n = n_on + int(0.06 * SR)
    t = tl(n)
    return np.sin(TWO_PI * f * t) * env_adsr(n_on, n, 0.006, 0.4, 0.7, 0.06) * vel


# --- 鼓 ---

def kick(vel, rng, soft=0.0):
    n = int(0.45 * SR)
    t = tl(n)
    fr = 52 + 80 * np.exp(-t / 0.032)
    x = np.sin(TWO_PI * np.cumsum(fr) / SR) * np.exp(-t / 0.17)
    x += (0.22 - 0.14 * soft) * filt(noise(rng, n), "hp", 1800) * np.exp(-t / 0.004)
    x[-200:] *= np.linspace(1, 0, 200)
    return np.tanh(1.3 * x) * vel


def snare(vel, rng, tone=190.0, dark=0.0):
    n = int(0.32 * SR)
    t = tl(n)
    body = (np.sin(TWO_PI * tone * t) + 0.5 * np.sin(TWO_PI * tone * 1.62 * t)) * np.exp(-t / 0.045) * 0.7
    nz = filt(filt(noise(rng, n), "hp", 1200), "lp", 8000 - 4500 * dark) * np.exp(-t / (0.085 + 0.03 * dark))
    x = body + nz
    a = int(0.001 * SR)
    x[:a] *= np.linspace(0, 1, a)
    x[-200:] *= np.linspace(1, 0, 200)
    return x * vel


def rim(vel, rng):
    n = int(0.08 * SR)
    t = tl(n)
    x = filt(noise(rng, n), "bp", 1700, 4) * np.exp(-t / 0.01) * 2.0 + 0.5 * np.sin(TWO_PI * 470 * t) * np.exp(-t / 0.018)
    x[-100:] *= np.linspace(1, 0, 100)
    return x * vel


HAT_F = np.array([205.3, 304.4, 369.6, 522.7, 540.0, 800.0]) * 1.7


def hat(vel, rng, open_=False):
    n = int((0.35 if open_ else 0.07) * SR)
    t = tl(n)
    met = sum(np.sign(np.sin(TWO_PI * fq * t + rng.uniform(0, 6.28))) for fq in HAT_F) / 6.0
    x = filt(0.6 * met + 0.6 * noise(rng, n), "hp", 7000)
    x = filt(x, "hp", 7000)
    x *= np.exp(-t / (0.11 if open_ else 0.018))
    x[-100:] *= np.linspace(1, 0, 100)
    return x * vel


def shaker(vel, rng):
    n = int(0.09 * SR)
    t = tl(n)
    x = filt(noise(rng, n), "bp", 6500, 1.2) * np.minimum(t / 0.012, 1) * np.exp(-t / 0.03)
    x[-100:] *= np.linspace(1, 0, 100)
    return x * vel


def clap(vel, rng):
    n = int(0.3 * SR)
    t = tl(n)
    e = np.zeros(n)
    for d in (0.0, 0.009, 0.018):
        e += np.exp(-np.maximum(t - d, 0) / 0.005) * (t >= d)
    e += 0.6 * np.exp(-np.maximum(t - 0.027, 0) / 0.07) * (t >= 0.027)
    x = filt(noise(rng, n), "bp", 1300, 1.3) * e
    x[-100:] *= np.linspace(1, 0, 100)
    return x * vel


def tom(vel, rng, f=160.0):
    n = int(0.5 * SR)
    t = tl(n)
    fr = f * (1 + 0.5 * np.exp(-t / 0.04))
    x = np.sin(TWO_PI * np.cumsum(fr) / SR) * np.exp(-t / 0.2) + 0.15 * filt(noise(rng, n), "lp", 3000) * np.exp(-t / 0.01)
    x[-100:] *= np.linspace(1, 0, 100)
    return x * vel


def timpani(vel, rng, f=65.0, length=2.2):
    n = int(length * SR)
    t = tl(n)
    glide = 1 + 0.025 * np.exp(-t / 0.06)
    ph = TWO_PI * np.cumsum(f * glide) / SR
    x = np.zeros(n)
    for r, A, d in ((1.0, 1.0, 1.4), (1.504, 0.5, 0.8), (1.742, 0.32, 0.55), (2.0, 0.22, 0.45), (2.245, 0.12, 0.3), (2.494, 0.08, 0.25)):
        x += A * np.sin(r * ph + r) * np.exp(-t / d)
    x += 0.35 * filt(noise(rng, n), "lp", 900) * np.exp(-t / 0.02)
    x[:30] *= np.linspace(0, 1, 30)
    x[-400:] *= np.linspace(1, 0, 400)
    return x * vel


def crash(vel, rng, length=2.4):
    n = int(length * SR)
    t = tl(n)
    met = sum(np.sign(np.sin(TWO_PI * fq * t + rng.uniform(0, 6.28))) for fq in HAT_F * 1.9) / 6.0
    x = filt(0.5 * met + noise(rng, n), "hp", 3500)
    x = filt(x, "lp", 11000) * np.exp(-t / 0.7) * np.minimum(t / 0.003, 1)
    x[-400:] *= np.linspace(1, 0, 400)
    return x * vel


def crackle(rng, n, rate=7.0):
    """黑胶噼啪声 + 很轻的底噪。"""
    x = np.zeros(n)
    k = int(rate * n / SR)
    pos = rng.integers(0, n - 64, k)
    amp = rng.lognormal(-1.0, 0.8, k) * rng.choice([-1, 1], k)
    for p, a in zip(pos, amp):
        L = int(rng.integers(8, 40))
        x[p:p + L] += a * np.exp(-np.arange(L) / (L / 4)) * rng.uniform(-1, 1, L)
    x += 0.012 * noise(rng, n)
    return x


def riser(rng, dur, vel):
    n = int(dur * SR)
    t = tl(n)
    x = noise(rng, n)
    out = np.zeros(n)
    seg = 16
    for i in range(seg):
        a, b = i * n // seg, (i + 1) * n // seg
        out[a:b] = filt(x, "bp", 600 * (12 ** (i / seg)), 2.0)[a:b]
    return out * (t / t[-1]) ** 2 * vel


# ---------------------------------------------------------------------------
# 曲子框架
# ---------------------------------------------------------------------------

class Stem:
    def __init__(self, n, pan=0.0, rev=0.15, eq=(), target=-24.0, trem=None):
        self.buf = np.zeros((2, n))
        self.pan, self.rev, self.eq, self.target, self.trem = pan, rev, list(eq), target, trem
        self.used = False


class Song:
    def __init__(self, name, bpm, bars, loop=True, swing8=0.0, swing16=0.0, seed=1, tail=4.0, beats_per_bar=4,
                 target=-16.0, ceil=-1.5, reverb=(1.6, 0.02, 4500), rev_gain=1.0, master_eq=(), wow=0.0, pre=0.0):
        self.name, self.bpm, self.loop = name, bpm, loop
        self.spb = 60.0 / bpm
        self.beats = bars * beats_per_bar
        self.pre = pre
        self.L = int(round((self.beats * self.spb + pre) * SR))
        self.N = self.L + int(tail * SR)
        self.sw8, self.sw16 = swing8, swing16
        self.rng = np.random.default_rng(seed)
        self.stems = {}
        self.target, self.ceil = target, ceil
        self.reverb, self.rev_gain, self.master_eq, self.wow = reverb, rev_gain, list(master_eq), wow

    def stem(self, name, **kw):
        self.stems[name] = Stem(self.N, **kw)
        return name

    def sec(self, beat):
        """拍 -> 秒（带八分 / 十六分摇摆）。"""
        b0 = np.floor(beat + 1e-9)
        f = beat - b0
        if self.sw8:
            s = self.sw8
            f = f * (0.5 + s) / 0.5 if f <= 0.5 else 0.5 + s + (f - 0.5) * (0.5 - s) / 0.5
        elif self.sw16:
            h = np.floor(f * 2 + 1e-9) / 2
            g = (f - h) * 2
            s = self.sw16
            g = g * (0.5 + s) / 0.5 if g <= 0.5 else 0.5 + s + (g - 0.5) * (0.5 - s) / 0.5
            f = h + g / 2
        return self.pre + (b0 + f) * self.spb

    def place(self, stem, x, beat, pan=None, gain=1.0, jitter=0.003):
        st = self.stems[stem]
        st.used = True
        p = st.pan if pan is None else pan
        start = int(round((self.sec(beat) + (self.rng.normal(0, jitter) if jitter else 0.0)) * SR))
        if self.loop:
            start %= self.L
        else:
            start = max(start, 0)
        end = min(start + len(x), self.N)
        x = x[: end - start]
        th = (np.clip(p, -1, 1) + 1) * np.pi / 4
        st.buf[0, start:end] += x * np.cos(th) * np.sqrt(2) * gain
        st.buf[1, start:end] += x * np.sin(th) * np.sqrt(2) * gain

    def note(self, stem, inst, beat, dur_beats, m, vel=0.8, pan=None, jitter=0.004, hum=0.07, **kw):
        if m is None:
            return
        v = float(np.clip(vel * (1 + self.rng.normal(0, hum)), 0.05, 1.0))
        dur = max(self.sec(beat + dur_beats) - self.sec(beat), 0.02)
        x = inst(hz(m), dur, v, self.rng, **kw)
        self.place(stem, x, beat, pan, jitter=jitter)

    def hit(self, stem, fn, beat, vel=0.8, pan=None, jitter=0.002, hum=0.06, **kw):
        v = float(np.clip(vel * (1 + self.rng.normal(0, hum)), 0.03, 1.0))
        self.place(stem, fn(v, self.rng, **kw), beat, pan, jitter=jitter)

    def melody(self, stem, inst, notes, vel=0.8, legato=0.92, accent=None, octave=0, **kw):
        for b, d, m in notes:
            if m is None:
                continue
            v = vel
            if accent:
                v *= accent(b)
            self.note(stem, inst, b, d * legato, m + 12 * octave, v, **kw)

    def chord(self, stem, inst, beat, dur, notes, vel=0.7, strum=0.008, spread=0.45, **kw):
        """和弦：低音在一侧、高音在另一侧展开（spread），加一点琶音式错开（strum 秒）。"""
        base = self.stems[stem].pan
        k = len(notes)
        for i, m in enumerate(notes):
            pan = base + (spread * (i / (k - 1) * 2 - 1) if k > 1 else 0.0)
            self.note(stem, inst, beat + strum * i / self.spb, dur, m, vel * (0.92 if i else 1.0), pan=pan, **kw)

    # --- 渲染 ---

    def _fold(self, x):
        if self.loop:
            y = x[:, : self.L].copy()
            ov = x[:, self.L:]
            y[:, : ov.shape[1]] += ov
            return y
        return x

    def _ir(self):
        rt, pre, damp = self.reverb
        rng = np.random.default_rng(777)
        n = int(rt * 1.2 * SR)
        t = tl(n)
        out = []
        for ch in range(2):
            nz = rng.normal(0, 1, n)
            lo = filt(nz, "lp", damp)
            hi = nz - lo
            ir = lo * np.exp(-6.9 * t / rt) + 0.5 * hi * np.exp(-6.9 * t / (rt * 0.35))
            for _ in range(6):    # 早期反射
                d = int(rng.uniform(0.005, 0.045) * SR)
                ir[d] += rng.uniform(0.6, 1.4) * rng.choice([-1, 1]) * 3
            ir *= np.minimum(t / 0.004, 1)
            ir = np.concatenate([np.zeros(int(pre * SR)), ir])
            out.append(ir / np.sqrt(np.sum(ir ** 2)))
        return np.array(out)

    def _conv(self, x, ir):
        n = x.shape[1]
        if self.loop:
            assert ir.shape[1] < n
            return np.fft.irfft(np.fft.rfft(x, n, axis=1) * np.fft.rfft(ir, n, axis=1), n, axis=1)
        return signal.fftconvolve(x, ir, axes=1)[:, :n]

    def render(self, report=None):
        loop = self.loop
        n = self.L if loop else self.N
        mix = np.zeros((2, n))
        rev_in = np.zeros((2, n))
        info = {}
        for name, st in self.stems.items():
            if not st.used:
                continue
            x = self._fold(st.buf)
            x = chain(x, [("hp", 25.0)] + st.eq, loop)
            if st.trem:
                rate, depth = st.trem
                cyc = max(1, round(rate * n / SR)) if loop else rate * n / SR
                ph = TWO_PI * cyc * np.arange(n) / n
                pan = depth * np.sin(ph)
                th = (pan + 1) * np.pi / 4
                mono = (x[0] + x[1]) * 0.5
                x = np.array([mono * np.cos(th), mono * np.sin(th)]) * np.sqrt(2)
            ld = lufs(x)
            g = 10 ** ((st.target - ld) / 20)
            x *= g
            info[name] = round(ld, 1)
            mix += x
            rev_in += x * st.rev
        rev = self._conv(rev_in, self._ir())
        rev = chain(rev, [("hp", 220.0), ("lp", 7000.0)], loop)
        mix += rev * self.rev_gain
        mix = chain(mix, [("hp", 28.0)] + self.master_eq, loop)
        if self.wow:
            # 磁带抖动（lo-fi）：整数个周期，循环接得上
            per = n / SR
            r = max(1, round(0.45 * per)) / per if loop else 0.45
            d = self.wow * (1 + np.sin(TWO_PI * r * np.arange(n) / SR)) / 2 * SR
            idx = np.arange(n) - d
            if loop:
                mix = np.array([np.interp(idx, np.arange(n), c, period=n) for c in mix])
            else:
                mix = np.array([np.interp(idx, np.arange(n), c) for c in mix])
        if not loop:
            # 去掉末尾无声部分，前 5 ms 淡入、最后 60 ms 淡出
            a = np.max(np.abs(mix), axis=0)
            idx = np.where(a > np.max(a) * 10 ** (-70 / 20))[0]
            end = min(n, idx[-1] + int(0.05 * SR))
            mix = mix[:, :end]
            f = int(0.06 * SR)
            mix[:, -f:] *= np.linspace(1, 0, f) ** 2
        # 响度归一 + 限幅（迭代两次）
        for _ in range(3):
            g = 10 ** ((self.target - lufs(mix)) / 20)
            mix = limiter(mix * g, self.ceil, loop)
        mix = np.clip(mix, -10 ** (self.ceil / 20), 10 ** (self.ceil / 20))
        if not loop:
            f = int(0.005 * SR)
            mix[:, :f] *= np.linspace(0, 1, f)
        if report is not None:
            report["stems"] = info
        return mix


# ---------------------------------------------------------------------------
# 1) 主菜单：F 大调，84 BPM，八分摇摆，lo-fi 爵士（电钢 + 钢片琴 + 低音提琴 + 轻鼓 + 黑胶噼啪）
#    结构 24 小节：A（8）- A'（8）- B（8），B 的最后一小节 Gm9-C13 回到开头的 Fmaj9。
# ---------------------------------------------------------------------------

def song_menu():
    S = Song("menu", 84, 24, swing8=0.11, seed=101, target=-16.0, reverb=(1.9, 0.025, 3800), rev_gain=1.0,
             master_eq=[("lp", 14000.0), ("highshelf", 9000.0, -1.5, 0.7), ("hp", 40.0)], wow=0.0009)
    A = ["Fmaj9", "Em7b5|A7b9", "Dm9", "Cm9|F13", "Bbmaj9", "Bbm6|Eb9", "Am7|D7b9", "Gm9|C13"]
    A2 = A[:7] + ["Cm7|F7"]
    B = ["Bbmaj9", "Bbm9|Eb13", "Am7", "Abdim7", "Gm9", "C7sus4|C7b9", "Fmaj9|D7b9", "Gm9|C13"]
    prog = progression(A + A2 + B)
    S.stem("rhodes", pan=0.0, rev=0.3, eq=[("hp", 120.0), ("peak", 300.0, -2.0, 0.8), ("lp", 9000.0)], target=-19.5, trem=(1.4 * 84 / 60 / 2, 0.3))
    S.stem("bass", pan=0.0, rev=0.03, eq=[("hp", 45.0), ("lp", 1400.0), ("peak", 700.0, 2.0, 1.0)], target=-22.0)
    S.stem("celesta", pan=0.22, rev=0.4, eq=[("hp", 280.0)], target=-22.0)
    S.stem("pad", pan=-0.1, rev=0.5, eq=[("hp", 220.0), ("lp", 3000.0)], target=-32.0)
    S.stem("kick", pan=0.0, rev=0.02, eq=[("hp", 45.0), ("lp", 4000.0)], target=-25.0)
    S.stem("snare", pan=0.06, rev=0.15, eq=[("lp", 8000.0), ("hp", 150.0)], target=-25.5)
    S.stem("hat", pan=-0.35, rev=0.08, eq=[("lp", 12000.0)], target=-29.5)
    S.stem("shaker", pan=0.35, rev=0.1, eq=[("lp", 10000.0)], target=-34.0)
    S.stem("vinyl", pan=0.0, rev=0.0, eq=[("hp", 900.0), ("lp", 7000.0)], target=-46.0)

    # 电钢伴奏（自动寻找最近的转位，和声进行平滑）
    prev = None
    pats4 = [[(0, 1.45, 1.0), (2.5, 1.4, 0.72)], [(0, 2.9, 1.0), (3.0, 0.9, 0.55)], [(0, 0.9, 1.0), (1.5, 0.4, 0.6), (2.0, 1.9, 0.85)]]
    pats2 = [[(0, 1.9, 1.0)], [(0, 0.9, 1.0), (1.5, 0.45, 0.6)]]
    for st, d, c in prog:
        v = voicing(c, 53, 74, prev)
        prev = v
        sec_ = int(st // 32)
        pats = pats4 if d >= 4 else pats2
        pat = pats[int(S.rng.integers(0, len(pats)))] if sec_ > 0 else pats[0]
        for o, ln, vv in pat:
            S.chord("rhodes", rhodes, st + o, ln, v, vel=0.62 * vv, strum=0.012)
    # 贝斯：根音 - 五音 - 三音 - 半音经过音
    for i, (st, d, c) in enumerate(prog):
        nxt = prog[(i + 1) % len(prog)][2]
        r = near(c["bass"], 34)
        nr = near(nxt["bass"], 34)
        appr = nr - 1 if (i % 3) else nr + 1
        if nxt["bass"] == c["bass"]:
            appr = r + chord_tone(c, "fifth")
        if d >= 4:
            seq = [(0, 1.4, r), (1.5, 0.9, r + chord_tone(c, "fifth")), (2.5, 0.85, r + chord_tone(c, "third") + (12 if chord_tone(c, "third") < 5 else 0)), (3.5, 0.45, appr)]
        else:
            seq = [(0, 1.4, r), (1.5, 0.45, appr)]
        for o, ln, m in seq:
            S.note("bass", upright, st + o, ln, m, 0.8 if o == 0 else 0.62)
    # 钢片琴旋律
    mA = mel("r:1 C5:.5 E5:.5 G5:1 A5:1  G5:1.5 F5:.5 E5:1 C#5:1  D5:1 r:.5 E5:.5 F5:.5 A5:1.5  G5:1 Eb5:1 D5:1.5 C5:.5 "
             "D5:1.5 C5:.5 D5:.5 F5:1.5  Db5:1 F5:1 G5:1 F5:1  E5:1 C5:1 F#5:1 Eb5:1  D5:1.5 Bb4:.5 A4:1 r:1", 0, 8)
    mA2 = mel("A5:1.5 G5:.5 E5:.5 C5:.5 r:1  D5:.5 E5:.5 G5:.5 Bb5:.5 A5:1 G5:1  F5:1 E5:.5 D5:.5 C5:1 A4:1  Bb4:.5 C5:.5 Eb5:1 D5:1 r:1 "
              "r:.5 F5:.5 A5:.5 C6:.5 A5:2  G5:1 F5:.5 Db5:.5 Bb4:1 Db5:1  C5:1.5 E5:.5 D5:1 C5:1  Bb4:1 G4:1 A4:2", 32, 8)
    mB = mel("F5:2 A5:1 C6:1  C6:1 Ab5:1 G5:1 F5:1  E5:3 r:1  F5:1 D5:1 B4:1 Ab4:1  Bb4:1 D5:1 F5:1 A5:1  G5:1.5 F5:.5 E5:1 Db5:1 "
             "C5:2 F#5:1 Eb5:1  D5:1 Bb4:1 A4:.5 G4:.5 r:1", 64, 8)
    acc = lambda b: 1.0 if abs(b - round(b)) < 1e-6 else 0.85
    S.melody("celesta", celesta, mA + mA2 + mB, vel=0.75, accent=acc)
    # 垫底弦乐：A' 和 B 段
    for st, d, c in prog:
        if st >= 32:
            S.chord("pad", pad, st, d * 0.98, voicing(c, 48, 67, None, rootless=False, maxn=3), vel=0.5, strum=0)
    # 鼓
    for bar in range(24):
        b = bar * 4
        S.hit("kick", kick, b, 0.9, soft=1.0)
        S.hit("kick", kick, b + 2.5, 0.72, soft=1.0)
        if bar % 2 == 1:
            S.hit("kick", kick, b + 1.5, 0.55, soft=1.0)
        S.hit("snare", snare, b + 1, 0.75, dark=0.5, tone=210)
        S.hit("snare", rim, b + 1, 0.35)
        S.hit("snare", snare, b + 3, 0.78, dark=0.5, tone=210)
        if bar % 4 == 2:
            S.hit("snare", snare, b + 3.75, 0.18, dark=1.0)
        hv = [0.7, 0.38, 0.6, 0.4, 0.7, 0.38, 0.62, 0.45]
        for i in range(8):
            if bar % 4 == 3 and i == 7:
                S.hit("hat", hat, b + 3.5, 0.5, open_=True)
            else:
                S.hit("hat", hat, b + i * 0.5, hv[i])
        if bar >= 16:
            for i in range(4):
                S.hit("shaker", shaker, b + i + 0.5, 0.6)
        if bar == 23:
            for k, o in enumerate((3.0, 3.333, 3.667)):
                S.hit("snare", snare, b + o, 0.2 + 0.08 * k, dark=1.0)
    S.place("vinyl", crackle(S.rng, S.L), 0, jitter=0)
    return S


# ---------------------------------------------------------------------------
# 2) 对局：D 多利亚 / F 大调，124 BPM，放克弹拨卡通动作曲。64 小节（约 124 秒）：
#    律动（8）- A 主题（16，陶笛）- B 段（16，F 大调，马林巴 + 开镲）- A'（16，陶笛 + 马林巴叠八度）- 间奏（8，抽掉底鼓、拨弦琶音、小鼓渐强）
# ---------------------------------------------------------------------------

MATCH_A = ["Dm9", "G13", "Dm9", "G13", "Bbmaj7", "C7", "Am7", "A7"]
MATCH_A2 = ["Dm9", "G13", "Dm9", "G13", "Bbmaj7", "C7", "Gm7", "A7"]
MATCH_B = ["Bbmaj7", "C6", "Am7", "Dm7", "Gm7", "C7", "Fmaj7", "F6", "Bbmaj7", "C7", "Am7", "D7", "Gm7", "C7", "Fmaj7|Em7b5", "A7"]
MATCH_G = ["Dm9", "Dm9", "G13", "G13", "Dm9", "Dm9", "Bbmaj7", "C7"]
MATCH_BRK = ["Dm9", "Dm9", "G13", "G13", "Bbmaj7", "Bbmaj7", "C7", "A7sus4|A7"]

MEL_A = ("r:.5 A4:.25 C5:.25 D5:.5 F5:.25 D5:.25 r:.5 A5:.5 G5:.5 F5:.5  E5:.75 D5:.25 B4:.5 D5:.5 r:1 F5:.25 E5:.25 D5:.5 "
         "r:.5 A4:.25 C5:.25 D5:.5 F5:.25 D5:.25 r:.5 C6:.5 A5:.5 G5:.5  A5:.75 G5:.25 E5:.5 D5:.5 B4:1 r:1 "
         "r:.5 D5:.5 F5:.5 A5:.5 G5:.75 F5:.25 D5:1  E5:.5 G5:.5 Bb5:.5 G5:.5 E5:.75 C5:.25 r:1 "
         "A4:.5 C5:.5 E5:.5 G5:.5 E5:1 C5:1  C#5:.5 E5:.5 G5:.5 Bb5:.5 A5:1.5 r:.5 ")
MEL_A2 = ("r:.5 A4:.25 C5:.25 D5:.5 F5:.25 D5:.25 r:.5 A5:.5 G5:.5 F5:.5  E5:.75 D5:.25 B4:.5 D5:.5 r:1 F5:.25 E5:.25 D5:.5 "
          "r:.5 A4:.25 C5:.25 D5:.5 F5:.25 D5:.25 r:.5 C6:.5 A5:.5 G5:.5  A5:.75 G5:.25 E5:.5 D5:.5 B4:.5 C5:.5 D5:1 "
          "F5:.5 A5:.5 C6:1 A5:.5 F5:.5 D5:1  E5:.5 G5:.5 C6:.5 Bb5:.5 G5:.5 E5:.5 C5:1 "
          "D5:.5 F5:.5 G5:.5 Bb5:.5 A5:.5 G5:.5 F5:.5 E5:.5  C#5:1.5 E5:.5 A4:1 r:1 ")
MEL_B = ("D5:1 F5:.5 A5:1 G5:.5 F5:1  E5:1.5 G5:.5 A5:1 G5:1  E5:.5 C5:.5 A4:1 r:.5 C5:.5 E5:.5 G5:.5  F5:1.5 E5:.5 D5:1 C5:1 "
         "Bb4:.5 D5:.5 G5:1 F5:.5 D5:.5 Bb4:1  C5:.5 E5:.5 G5:.5 Bb5:.5 A5:.5 G5:.5 E5:1  F5:2 A5:1 C6:1  D6:1.5 C6:.5 A5:1 r:1 "
         "D5:1 F5:.5 A5:1 Bb5:.5 A5:1  G5:1.5 E5:.5 C5:1 Bb4:1  A4:.5 C5:.5 E5:.5 A5:.5 G5:1 E5:1  F#5:1.5 A5:.5 C6:1 A5:1 "
         "Bb5:1 A5:.5 G5:.5 F5:1 D5:1  E5:1 G5:.5 Bb5:.5 A5:1 G5:1  A5:1 F5:1 G5:1 Bb5:1  A5:.5 G5:.5 E5:.5 C#5:.5 E5:2")


def funk_riff(S, stem, prog, start_bar, nbars, kind=1, vel=0.8):
    lo = 38
    for i, (st, d, c) in enumerate(prog):
        b0 = start_bar * 4 + st
        nxt = prog[(i + 1) % len(prog)][2]
        r = near(c["bass"], lo)
        nr = near(nxt["bass"], lo)
        appr = nr - 1 if (i % 2 == 0) else nr + 1
        if nxt["bass"] == c["bass"]:
            appr = r + 12 - 2
        fifth, sev = chord_tone(c, "fifth"), chord_tone(c, "seventh")
        if kind == 1:
            seq = [(0, .45, r, 1.0), (.75, .2, r + 12, .7), (1.5, .4, r, .8), (2.0, .2, r + fifth, .6), (2.5, .45, r + sev, .8),
                   (3.0, .2, r + 12, .65), (3.5, .2, r + fifth, .6), (3.75, .2, appr, .7)]
        elif kind == 2:
            seq = [(0, .7, r, 1.0), (1.0, .2, r + 12, .6), (1.5, .45, r + fifth, .75), (2.5, .45, r, .8), (3.0, .2, r + sev, .65), (3.5, .45, appr, .7)]
        elif kind == 3:
            seq = [(0, 1.8, r, .85), (2.5, .9, r + fifth, .6), (3.5, .45, appr, .6)]
        else:   # 加速决战：八分音符推进（根音 / 高八度交替）
            seq = [(k * 0.5, .3, r + (12 if k % 2 else 0), .9 if k % 2 == 0 else .65) for k in range(8)]
            seq[-1] = (3.5, .3, appr, .7)
        if d < 4:
            seq = [s for s in seq if s[0] < d - 0.01]
            if kind != 4:
                seq = seq[:-1] + [(d - 0.5, .3, appr, .65)] if len(seq) > 1 else seq
        for o, ln, m, v in seq:
            S.note(stem, funk_bass, b0 + o, ln, m, vel * v, jitter=0.002)


def song_match():
    S = Song("match", 124, 64, swing16=0.035, seed=202, target=-16.0, reverb=(1.3, 0.02, 4500), rev_gain=0.9,
             master_eq=[("hp", 38.0), ("lowshelf", 140.0, -2.0, 0.7), ("peak", 3000.0, -1.5, 0.8), ("highshelf", 9000.0, -1.0, 0.7)])
    S.stem("kick", rev=0.02, eq=[("hp", 45.0), ("lp", 5000.0)], target=-23.0)
    S.stem("snare", pan=0.05, rev=0.14, eq=[("peak", 3500.0, -3.0, 1.0)], target=-25.5)
    S.stem("clap", pan=-0.05, rev=0.2, eq=[], target=-29.0)
    S.stem("hat", pan=-0.4, rev=0.05, eq=[("lp", 12000.0)], target=-30.5)
    S.stem("shaker", pan=0.45, rev=0.05, eq=[], target=-34.0)
    S.stem("tom", pan=0.0, rev=0.15, eq=[], target=-29.0)
    S.stem("bass", rev=0.02, eq=[("hp", 45.0), ("lp", 2500.0), ("peak", 900.0, 1.5, 1.0)], target=-20.5)
    S.stem("clav", pan=-0.3, rev=0.12, eq=[("hp", 250.0), ("lp", 8000.0)], target=-24.5)
    S.stem("lead", pan=0.08, rev=0.25, eq=[("hp", 220.0)], target=-19.5)
    S.stem("marimba", pan=0.35, rev=0.22, eq=[("hp", 200.0)], target=-22.0)
    S.stem("harp", pan=-0.25, rev=0.3, eq=[("hp", 200.0)], target=-25.5)
    S.stem("pad", pan=0.0, rev=0.4, eq=[("hp", 180.0), ("lp", 2400.0)], target=-30.0)

    secs = [("G", 0, MATCH_G), ("A", 8, MATCH_A + MATCH_A2), ("B", 24, MATCH_B), ("A2", 40, MATCH_A + MATCH_A2), ("K", 56, MATCH_BRK)]
    full = []
    for nm, bar0, ch in secs:
        p = progression(ch)
        full += [(bar0 * 4 + st, d, c) for st, d, c in p]
        # 贝斯
        funk_riff(S, "bass", p, bar0, len(ch), {"G": 1, "A": 1, "B": 2, "A2": 1, "K": 3}[nm], vel=0.85)
        # 和声
        prev = None
        for st, d, c in p:
            b = bar0 * 4 + st
            v = voicing(c, 55, 72, prev)
            prev = v
            if nm in ("G", "A", "A2"):
                for o, ln in ((0.75, .18), (1.5, .14), (2.75, .18), (3.5, .14)):
                    if o < d:
                        S.chord("clav", clav, b + o, ln, v, vel=0.7 if o in (0.75, 2.75) else 0.55, strum=0.004)
            if nm in ("B", "A2", "K"):
                S.chord("pad", pad, b, d * 0.98, voicing(c, 50, 69, None, rootless=False, maxn=4), vel=0.5, strum=0)
            if nm == "B":
                for o in (0.5, 1.5, 2.5, 3.5):
                    if o < d:
                        S.chord("harp", harp, b + o, 0.3, v, vel=0.55, strum=0.006)
            if nm == "K":
                arp = (v + [m + 12 for m in v])[:5]
                for k in range(int(d * 2)):
                    S.note("harp", harp, b + k * 0.5, 0.45, arp[[0, 1, 2, 3, 4, 3, 2, 1][k % 8] % len(arp)], 0.6)
    # 旋律
    acc = lambda b: 1.0 if abs((b * 2) - round(b * 2)) < 1e-6 else 0.82
    ma = mel(MEL_A + MEL_A2, 8 * 4, 16)
    mb = mel(MEL_B, 24 * 4, 16)
    ma2 = mel(MEL_A + MEL_A2, 40 * 4, 16)
    S.melody("lead", ocarina, ma, vel=0.8, accent=acc, legato=0.9)
    S.melody("marimba", marimba, mb, vel=0.85, accent=acc)
    S.melody("lead", ocarina, ma2, vel=0.8, accent=acc, legato=0.9)
    S.melody("marimba", marimba, ma2, vel=0.55, accent=acc, octave=-1)
    # 鼓
    for bar in range(64):
        b = bar * 4
        sec = "G" if bar < 8 else "A" if bar < 24 else "B" if bar < 40 else "A2" if bar < 56 else "K"
        kick_on = not (sec == "K" and bar < 60)
        if kick_on:
            if sec == "K":
                for q in range(4):
                    S.hit("kick", kick, b + q, 0.6 + 0.08 * (bar - 60), soft=0.5)
            elif sec == "B":
                for o, v in ((0, 0.95), (1.5, 0.7), (2.5, 0.8), (3.25, 0.5)):
                    S.hit("kick", kick, b + o, v, soft=0.5)
            else:
                for o, v in ((0, 0.95), (1.75, 0.7), (2.5, 0.8)):
                    S.hit("kick", kick, b + o, v, soft=0.5)
        if sec == "K" and bar < 62:
            S.hit("snare", rim, b + 1, 0.5)
            S.hit("snare", rim, b + 3, 0.5)
        elif sec == "K":
            # 最后两小节：小鼓八分 -> 十六分渐强，最后半拍留空再回到开头
            step = 0.5 if bar == 62 else 0.25
            k = 0
            o = 0.0
            while o < 3.5 - 1e-6:
                S.hit("snare", snare, b + o, 0.25 + 0.35 * ((bar - 62) * 4 + o) / 8.0)
                o += step
                k += 1
        else:
            S.hit("snare", snare, b + 1, 0.8)
            S.hit("snare", snare, b + 3, 0.82)
            S.hit("snare", snare, b + 2.25, 0.16)
            S.hit("snare", snare, b + 3.75, 0.13)
            if sec in ("B", "A2"):
                S.hit("clap", clap, b + 1, 0.7)
                S.hit("clap", clap, b + 3, 0.75)
            if bar % 8 == 7 and sec != "K":
                for k, o in enumerate((3.25, 3.5, 3.75)):
                    S.hit("tom", tom, b + o, 0.55 + 0.1 * k, f=[220.0, 165.0, 120.0][k])
        # 镲
        if sec == "B":
            for q in range(4):
                S.hit("hat", hat, b + q, 0.45)
                S.hit("hat", hat, b + q + 0.5, 0.6, open_=True)
        elif sec == "K" and bar < 60:
            for i in range(8):
                S.hit("hat", hat, b + i * 0.5, 0.5 if i % 2 == 0 else 0.35)
        elif sec != "K":
            for i in range(16):
                S.hit("hat", hat, b + i * 0.25, [0.55, 0.22, 0.38, 0.22][i % 4])
        else:
            for i in range(8):
                S.hit("hat", hat, b + i * 0.5, 0.45)
        if sec in ("A", "A2"):
            for i in range(8):
                S.hit("shaker", shaker, b + i * 0.5 + 0.25, 0.55)
    return S


# ---------------------------------------------------------------------------
# 3) 加速决战：同为 D 小调，132 BPM，四踩底鼓 + 十六分踩镲 + 八分推进贝斯，40 小节（约 73 秒）：
#    律动（8）- 主旋律（16，脉冲波）- 紧张段（8，铜管齐奏 + 噪声上扬）- 马林巴十六分琶音（8）
# ---------------------------------------------------------------------------

RUSH_M = ["Dm", "Dm/C", "Bbmaj7", "A7", "Dm", "Dm/C", "Gm7", "A7"]
RUSH_T = ["Gm7", "A7", "Gm7", "A7", "Bbmaj7", "C7", "A7sus4", "A7"]
MEL_R = ("D5:.5 F5:.5 A5:.75 G5:.25 F5:.5 E5:.5 D5:1  C5:.5 D5:.5 F5:.5 A5:.5 C6:1 A5:1  Bb5:.75 A5:.25 F5:.5 D5:.5 F5:.5 A5:.5 G5:1 "
         "E5:.5 C#5:.5 E5:.5 G5:.5 A5:1 r:1  D6:.5 C6:.5 A5:.5 F5:.5 A5:.5 G5:.5 F5:1  E5:.5 F5:.5 G5:.5 A5:.5 C6:.75 A5:.25 F5:1 "
         "G5:.5 Bb5:.5 D6:1 C6:.5 Bb5:.5 A5:1  C#6:1 Bb5:.5 G5:.5 E5:.5 C#5:.5 A4:1 ")
MEL_R2 = ("D5:.5 F5:.5 A5:.75 G5:.25 F5:.5 E5:.5 D5:1  C5:.5 D5:.5 F5:.5 A5:.5 C6:1 A5:1  Bb5:.75 A5:.25 F5:.5 D5:.5 F5:.5 A5:.5 G5:1 "
          "E5:.5 C#5:.5 E5:.5 G5:.5 A5:1 r:1  D6:.5 C6:.5 A5:.5 F5:.5 A5:.5 G5:.5 F5:1  E5:.5 F5:.5 G5:.5 A5:.5 C6:.75 A5:.25 F5:1 "
          "Bb5:.5 A5:.5 G5:.5 F5:.5 E5:.5 F5:.5 G5:.5 A5:.5  A5:2 E5:.5 C#5:.5 A4:1 ")


def song_rush():
    S = Song("rush", 132, 40, swing16=0.02, seed=303, target=-16.0, reverb=(1.1, 0.015, 5000), rev_gain=0.8,
             master_eq=[("hp", 38.0), ("lowshelf", 140.0, -2.0, 0.7), ("peak", 3000.0, -1.5, 0.8), ("highshelf", 9000.0, -1.0, 0.7)])
    S.stem("kick", rev=0.02, eq=[("hp", 45.0), ("lp", 5000.0)], target=-22.5)
    S.stem("snare", pan=0.05, rev=0.14, eq=[("peak", 3500.0, -3.0, 1.0)], target=-25.0)
    S.stem("clap", pan=-0.05, rev=0.2, eq=[], target=-28.0)
    S.stem("hat", pan=-0.4, rev=0.05, eq=[("lp", 12000.0)], target=-30.0)
    S.stem("tom", rev=0.15, eq=[], target=-28.0)
    S.stem("bass", rev=0.02, eq=[("hp", 45.0), ("lp", 2500.0), ("peak", 900.0, 1.5, 1.0)], target=-20.0)
    S.stem("clav", pan=-0.3, rev=0.12, eq=[("hp", 250.0), ("lp", 8000.0)], target=-24.0)
    S.stem("lead", pan=0.08, rev=0.22, eq=[("hp", 220.0)], target=-19.5)
    S.stem("brass", pan=0.15, rev=0.25, eq=[("hp", 150.0)], target=-22.0)
    S.stem("marimba", pan=0.35, rev=0.2, eq=[("hp", 200.0)], target=-22.5)
    S.stem("pad", rev=0.4, eq=[("hp", 180.0), ("lp", 2600.0)], target=-30.0)
    S.stem("riser", pan=0.0, rev=0.3, eq=[("hp", 400.0), ("lp", 8000.0)], target=-31.0)
    secs = [("G", 0, RUSH_M), ("M", 8, RUSH_M + RUSH_M), ("T", 24, RUSH_T), ("R", 32, RUSH_M)]
    for nm, bar0, ch in secs:
        p = progression(ch)
        funk_riff(S, "bass", p, bar0, len(ch), 4, vel=0.85)
        prev = None
        for st, d, c in p:
            b = bar0 * 4 + st
            v = voicing(c, 55, 72, prev, rootless=False)
            prev = v
            if nm in ("G", "M", "R"):
                for o, ln in ((0.5, .15), (1.5, .15), (2.5, .15), (3.25, .12), (3.5, .15)):
                    S.chord("clav", clav, b + o, ln, v, vel=0.68 if o != 3.25 else 0.5, strum=0.003)
            if nm in ("M", "T", "R"):
                S.chord("pad", pad, b, d * 0.98, voicing(c, 50, 69, None, rootless=False, maxn=4), vel=0.5, strum=0)
            if nm == "T":
                vb = voicing(c, 53, 70, None, rootless=False, maxn=4)
                for o, ln, vv in ((0, 0.4, 0.9), (1.5, 0.3, 0.7), (2.5, 0.3, 0.75), (3.0, 0.8, 0.85)):
                    S.chord("brass", brass, b + o, ln, vb, vel=vv, strum=0.003, scoop=0.3)
            if nm == "R":
                arp = (v + [m + 12 for m in v])[:5]
                pat = [0, 1, 2, 3, 4, 3, 2, 1]
                for k in range(16):
                    S.note("marimba", marimba, b + k * 0.25, 0.24, arp[pat[k % 8] % len(arp)], 0.6 + 0.2 * (k % 4 == 0))
    acc = lambda b: 1.0 if abs((b * 2) - round(b * 2)) < 1e-6 else 0.8
    S.melody("lead", pulse_lead, mel(MEL_R + MEL_R2, 8 * 4, 16), vel=0.8, accent=acc, legato=0.85)
    S.place("riser", riser(S.rng, 4 * 2 * S.spb, 0.9), 30 * 4, jitter=0)
    for bar in range(40):
        b = bar * 4
        last = bar == 39
        for q in range(4):
            if last and q == 3:
                continue
            S.hit("kick", kick, b + q, 0.9 if q % 2 == 0 else 0.8, soft=0.5)
        S.hit("snare", snare, b + 1, 0.8)
        S.hit("snare", snare, b + 3, 0.85)
        S.hit("clap", clap, b + 1, 0.6)
        S.hit("clap", clap, b + 3, 0.65)
        for i in range(16):
            S.hit("hat", hat, b + i * 0.25, [0.5, 0.22, 0.6, 0.22][i % 4], open_=(i % 4 == 2 and bar >= 8))
        if 30 <= bar < 32:
            # 紧张段结尾：小鼓渐密
            step = 0.5 if bar == 30 else 0.25
            o = 0.0
            while o < 4 - 1e-6:
                S.hit("snare", snare, b + o, 0.25 + 0.4 * ((bar - 30) * 4 + o) / 8.0)
                o += step
        if bar % 8 == 7 and bar != 31:
            for k, o in enumerate((3.0, 3.25, 3.5, 3.75)):
                S.hit("tom", tom, b + o, 0.5 + 0.1 * k, f=[240.0, 200.0, 160.0, 120.0][k])
    return S


# ---------------------------------------------------------------------------
# 4) 鼠王：C 小调，104 BPM，滑稽反派进行曲（大号 oom-pah + 长号主题 + 定音鼓 + 弱音小号），20 小节（约 46 秒）：
#    前奏（4，定音鼓 + 拨弦“蹑手蹑脚”）- A 主题（8，长号）- B 段（8，弱音小号嘲讽）-> 回到前奏
# ---------------------------------------------------------------------------

BOSS_I = ["Cm", "Cm", "Ab", "G7"]
BOSS_A = ["Cm", "Cm", "Fm", "Fm", "Db", "Db", "G7", "G7"]
BOSS_B = ["Ab", "G7", "Ab", "G7", "Fm", "Db", "G7", "G7"]
MEL_BOSS_A = ("C4:.5 r:.5 Eb4:.5 r:.5 G4:.5 F#4:.5 G4:1  Ab4:.5 G4:.5 F#4:.5 G4:.5 C4:2 "
              "F4:.5 r:.5 Ab4:.5 r:.5 C5:.5 B4:.5 C5:1  Db5:.5 C5:.5 B4:.5 C5:.5 F4:2 "
              "Db4:.5 F4:.5 Ab4:.5 Db5:.5 C5:1 Ab4:1  F4:1 Ab4:.5 F4:.5 Db4:2 "
              "G4:.5 r:.5 B3:.5 r:.5 D4:.5 F4:.5 Ab4:1  G4:.5 F#4:.5 F4:.5 D4:.5 B3:1 r:1")
MEL_BOSS_B = ("Eb5:1 C5:.5 Ab4:.5 Eb5:1 C5:1  D5:.5 F5:.5 B4:1 D5:.5 B4:.5 G4:1  Eb5:.5 F5:.5 Eb5:.5 C5:.5 Ab4:1 C5:1  B4:1 D5:1 F5:1 Ab5:1 "
              "Ab5:1.5 G5:.5 F5:1 C5:1  Db5:1.5 F5:.5 Ab5:1 F5:1  G5:.5 F5:.5 D5:.5 B4:.5 G4:1 F4:1  G4:.5 r:.5 G4:.5 r:.5 G4:.5 r:1.5")


def song_boss():
    S = Song("boss", 104, 20, swing8=0.04, seed=404, target=-16.0, reverb=(2.2, 0.03, 3500), rev_gain=1.0,
             master_eq=[("peak", 3000.0, -2.0, 0.8), ("hp", 38.0)])
    S.stem("tuba", pan=-0.1, rev=0.15, eq=[("hp", 40.0), ("lp", 2000.0)], target=-21.5)
    S.stem("sub", rev=0.0, eq=[("hp", 40.0), ("lp", 200.0)], target=-31.0)
    S.stem("pah", pan=0.2, rev=0.25, eq=[("hp", 200.0)], target=-24.5)
    S.stem("trombone", pan=-0.05, rev=0.3, eq=[("hp", 110.0), ("peak", 1400.0, 2.0, 0.9)], target=-19.0)
    S.stem("trumpet", pan=0.15, rev=0.32, eq=[("hp", 250.0), ("peak", 1600.0, 2.0, 0.9)], target=-20.0)
    S.stem("pizz", pan=0.3, rev=0.25, eq=[("hp", 120.0)], target=-24.0)
    S.stem("timp", pan=-0.2, rev=0.3, eq=[("hp", 45.0), ("lp", 3000.0)], target=-23.5)
    S.stem("snare", pan=0.25, rev=0.2, eq=[("peak", 3500.0, -2.0, 1.0)], target=-27.0)
    S.stem("crash", pan=0.3, rev=0.2, eq=[], target=-32.0)
    S.stem("pad", rev=0.45, eq=[("hp", 200.0), ("lp", 2500.0)], target=-31.0)
    secs = [("I", 0, BOSS_I), ("A", 4, BOSS_A), ("B", 12, BOSS_B)]
    for nm, bar0, ch in secs:
        p = progression(ch)
        for st, d, c in p:
            b = bar0 * 4 + st
            r = near(c["bass"], 31)
            fifth = r + chord_tone(c, "fifth")
            if fifth > 43:
                fifth -= 12
            # oom-pah：大号 1、3 拍（根音 / 五音），铜管和弦 2、4 拍短促
            for o, m in ((0, r), (2, fifth)):
                S.note("tuba", tuba, b + o, 0.55, m, 0.85 if o == 0 else 0.75)
                S.note("sub", sub, b + o, 0.5, m, 0.8)
            if nm != "I":
                v = voicing(c, 55, 70, None, rootless=False, maxn=3)
                for o in (1, 3):
                    S.chord("pah", brass, b + o, 0.22, v, vel=0.55, strum=0.004, a=0.02, rel=0.08, scoop=0.2)
                S.chord("pad", pad, b, d * 0.98, voicing(c, 48, 64, None, rootless=False, maxn=3), vel=0.5, strum=0)
            # 定音鼓
            tp = 36 if c["root"] in (0, 8, 5, 1) else 43
            S.hit("timp", timpani, b, 0.85, f=hz(tp))
            if nm == "I":
                S.hit("timp", timpani, b + 2, 0.6, f=hz(43 if tp == 36 else 36))
                # 蹑手蹑脚的拨弦：半音上行
                line = [(0.5, 60), (1.5, 63), (2.5, 67), (3.0, 66), (3.5, 67)] if st % 8 == 0 else [(0.5, 68), (1.5, 67), (2.5, 66), (3.0, 67), (3.5, 71)]
                for o, m in line:
                    S.note("pizz", pizz, b + o, 0.25, m, 0.7)
    S.melody("trombone", brass, mel(MEL_BOSS_A, 16, 8), vel=0.85, legato=0.88, bright=0.85, a=0.04, vib=0.004)
    wah = lambda t: 0.5 + 0.5 * np.sin(TWO_PI * 3.0 * t - 1.5)
    S.melody("trumpet", brass, mel(MEL_BOSS_B, 48, 8), vel=0.8, legato=0.85, mute=wah, bright=1.1, a=0.03)
    S.melody("trombone", brass, [(b, d, m - 12 if m else None) for b, d, m in mel(MEL_BOSS_B, 48, 8)], vel=0.55, legato=0.85, bright=0.7)
    for bar in range(20):
        b = bar * 4
        # 军鼓：滑稽进行曲的 “哒-哒哒”
        S.hit("snare", snare, b + 1, 0.5, dark=0.5)
        S.hit("snare", snare, b + 3, 0.5, dark=0.5)
        S.hit("snare", snare, b + 3.5, 0.3, dark=0.5)
        if bar in (4, 12):
            S.hit("crash", crash, b, 0.8)
        if bar == 19:
            # 定音鼓滚奏 -> 回到前奏
            for k in range(12):
                S.hit("timp", timpani, b + 2 + k / 6, 0.3 + 0.04 * k, f=hz(43), length=0.6)
    return S


# ---------------------------------------------------------------------------
# 5) 胜利：F 大调，150 BPM，三连音上行 + 铜管齐奏 + 钢片琴闪光，约 6 秒
# 6) 失败：降 B 大调的悲伤长号“哇—哇—哇—哇～”（半音下行，最后一声摇晃），约 5 秒
# ---------------------------------------------------------------------------

def song_victory():
    S = Song("victory", 150, 4, loop=False, seed=505, tail=3.5, target=-14.0, reverb=(1.8, 0.02, 4500), rev_gain=0.9, pre=0.03)
    S.stem("brass", pan=0.0, rev=0.25, eq=[("hp", 150.0), ("peak", 2800.0, -2.0, 0.9)], target=-16.0)
    S.stem("chord", pan=-0.2, rev=0.3, eq=[("hp", 150.0), ("peak", 2800.0, -2.0, 0.9)], target=-21.0)
    S.stem("celesta", pan=0.3, rev=0.35, eq=[("hp", 300.0)], target=-22.0)
    S.stem("tuba", pan=-0.1, rev=0.1, eq=[("hp", 40.0), ("lp", 1500.0)], target=-24.0)
    S.stem("timp", pan=-0.2, rev=0.25, eq=[("hp", 45.0)], target=-25.0)
    S.stem("snare", pan=0.15, rev=0.2, eq=[], target=-26.0)
    S.stem("crash", pan=0.25, rev=0.2, eq=[], target=-27.0)
    S.stem("kick", rev=0.05, eq=[("hp", 40.0)], target=-25.0)
    t3 = 1.0 / 3
    lead = [(0, t3, "C5"), (t3, t3, "D5"), (2 * t3, t3, "E5"), (1, .5, "F5"), (1.5, .5, "A5"), (2, .5, "C6"), (2.5, .5, "A5"),
            (3, .5, "Bb5"), (3.5, .5, "D6"), (4, .5, "C6"), (4.5, .5, "Bb5"), (5, .5, "A5"), (5.5, .25, "Bb5"), (5.75, .25, "B5"), (6, 3.2, "C6")]
    lead2 = [(b, d, midi(m)) for b, d, m in lead]
    S.melody("brass", brass, lead2, vel=0.9, legato=0.92, bright=1.2, a=0.025, scoop=0.25)
    S.melody("celesta", celesta, [(b, d, m + 12) for b, d, m in lead2], vel=0.7)
    # 和弦：F（1 拍起）- Bb（3）- C7（5）- F（6，最后一拍收在 F 大三和弦，顶音 C6 → 主音 F 在下方）
    for b, d, ch in ((1, 2, "F"), (3, 2, "Bb"), (5, 1, "C7"), (6, 3.2, "F")):
        c = chord(ch)
        S.chord("chord", brass, b, d * 0.95, voicing(c, 57, 72, None, rootless=False, maxn=3), vel=0.75 if b < 6 else 0.9, strum=0.004, bright=1.0)
        S.note("tuba", tuba, b, min(d, 1.5) * 0.9, near(c["root"], 34), 0.85)
    for b, f in ((1, 41), (3, 46), (5, 36), (6, 41)):
        S.hit("timp", timpani, b, 0.8, f=hz(f), length=1.5 if b < 6 else 2.4)
    for k in range(6):
        S.hit("snare", snare, k / 6, 0.25 + 0.08 * k)
    S.hit("kick", kick, 1, 0.8)
    S.hit("kick", kick, 6, 0.95)
    S.hit("crash", crash, 6, 0.85, length=3.0)
    for k, m in enumerate(("F6", "A6", "C7", "F7")):
        S.note("celesta", celesta, 6.5 + k * 0.25, 0.6, midi(m), 0.5)
    return S


def song_defeat():
    S = Song("defeat", 76, 3, loop=False, seed=606, tail=3.0, target=-14.5, reverb=(1.5, 0.02, 3500), rev_gain=0.8, pre=0.03)
    S.stem("trombone", pan=0.0, rev=0.25, eq=[("hp", 90.0), ("peak", 1200.0, 3.0, 1.0)], target=-15.5)
    S.stem("tuba", pan=-0.15, rev=0.15, eq=[("hp", 40.0), ("lp", 1200.0)], target=-25.5)
    S.stem("timp", pan=0.15, rev=0.25, eq=[], target=-24.0)
    S.stem("snare", pan=0.1, rev=0.2, eq=[], target=-30.0)
    notes = [(0.0, 0.9, "D4"), (1.0, 0.9, "Db4"), (2.0, 0.9, "C4"), (3.0, 3.6, "B3")]
    for i, (b, d, n) in enumerate(notes):
        last = i == 3
        if last:
            # 最后一声：慢慢摇晃（±45 音分，6 Hz）并往下滑一点，弱音器跟着开合
            wob = lambda t: 2 ** ((0.75 * np.sin(TWO_PI * 6.0 * t) * np.clip(t / 0.4, 0, 1) - 0.6 * np.clip((t - 1.6) / 1.2, 0, 1)) / 12)
            mute = lambda t: 0.45 + 0.55 * (0.5 + 0.5 * np.sin(TWO_PI * 6.0 * t - 1.2)) * np.clip(t / 0.3, 0, 1)
        else:
            wob = lambda t: 2 ** (-0.35 * np.clip((t - 0.25) / 0.5, 0, 1) / 12)
            mute = lambda t: np.clip(t / 0.18, 0, 1) * (1 - 0.6 * np.clip((t - 0.3) / 0.4, 0, 1)) * 0.9 + 0.05
        S.note("trombone", brass, b, d, midi(n), 0.9, mute=mute, bend=wob, vib=0.0, bright=1.4, a=0.05, rel=0.25, scoop=0.6, jitter=0, hum=0)
        S.note("tuba", tuba, b, min(d, 1.8) * 0.9, midi(n) - 12, 0.6, jitter=0, hum=0)
    S.hit("timp", timpani, 3.0, 0.7, f=hz(35), length=2.4)
    S.hit("snare", snare, 3.0, 0.35, dark=1.0)
    return S


SONGS = {"menu": song_menu, "match": song_match, "rush": song_rush, "boss": song_boss, "victory": song_victory, "defeat": song_defeat}
LOOPS = {"menu", "match", "rush", "boss"}


# ---------------------------------------------------------------------------
# 输出 + 自检
# ---------------------------------------------------------------------------

def write_ogg(path, x):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp = f.name
    wavfile.write(tmp, SR, x.T.astype(np.float32))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", "-ar", str(SR), "-ac", "2", path], check=True)
    os.unlink(tmp)


def decode(path):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"], check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).T.astype(np.float64)


BANDS = [(20, 60), (60, 250), (250, 1000), (1000, 2000), (2000, 4000), (4000, 8000), (8000, 20000)]


def analyze(name, x, loop, bar_len=0):
    n = x.shape[1]
    peak = float(np.max(np.abs(x)))
    rms = float(np.sqrt(np.mean(x ** 2)))
    d = np.abs(np.diff(x, axis=1))
    st = {
        "seconds": round(n / SR, 3), "samples": int(n), "peak_dbfs": round(20 * np.log10(peak + 1e-12), 2),
        "rms_dbfs": round(20 * np.log10(rms + 1e-12), 2), "lufs": round(lufs(x), 2),
        "clipped_samples": int(np.sum(np.abs(x) >= 0.999)),
        "max_step": round(float(np.max(d)), 4), "step_p999": round(float(np.percentile(d, 99.9)), 4),
    }
    if loop:
        seam = np.concatenate([x[:, -2048:], x[:, :2048]], axis=1)
        st["seam_jump"] = round(float(np.max(np.abs(x[:, 0] - x[:, -1]))), 4)
        sd = np.abs(np.diff(seam, axis=1))
        st["seam_max_step_near"] = round(float(np.max(sd[:, 2048 - 64:2048 + 64])), 4)
        st["seam_jump_vs_p999"] = round(st["seam_jump"] / (st["step_p999"] + 1e-9), 3)
        # 循环点通常就是第一拍（有鼓），所以拿它和每个小节第一拍附近的最大步长比：落在同一分布里就说明没有额外的咔哒
        if bar_len:
            pts = np.arange(1, int(n / bar_len)) * bar_len
            db = [float(np.max(d[:, int(p) - 32:int(p) + 32])) for p in pts]
            st["downbeat_step_median"] = round(float(np.median(db)), 4)
            st["downbeat_step_max"] = round(float(np.max(db)), 4)
        a = 20 * np.log10(np.sqrt(np.mean(x[:, -SR // 2:] ** 2)) + 1e-12)
        b = 20 * np.log10(np.sqrt(np.mean(x[:, : SR // 2] ** 2)) + 1e-12)
        st["seam_rms_end_vs_start_db"] = [round(float(a), 1), round(float(b), 1)]
        # 接缝处 8 kHz 以上的能量（有咔哒声会冒尖）和全曲中位数相比
        hp = filt(np.concatenate([x[:, -SR:], x[:, :SR]], axis=1), "hp", 8000.0)
        e = uniform_filter1d(np.sum(hp ** 2, axis=0), 256)
        full = filt(x, "hp", 8000.0)
        ef = uniform_filter1d(np.sum(full ** 2, axis=0), 256)
        st["seam_hf_vs_p99_db"] = round(float(10 * np.log10((np.max(e[SR - 512:SR + 512]) + 1e-15) / (np.percentile(ef, 99) + 1e-15))), 1)
    else:
        st["start_abs"] = round(float(np.max(np.abs(x[:, :32]))), 5)
        st["end_abs"] = round(float(np.max(np.abs(x[:, -32:]))), 5)
    mono = x.mean(axis=0)
    f, p = signal.welch(mono, SR, nperseg=8192)
    tot = np.sum(p)
    st["bands"] = {f"{lo}-{hi}": round(float(np.sum(p[(f >= lo) & (f < hi)]) / tot * 100), 1) for lo, hi in BANDS}
    st["centroid_hz"] = int(np.sum(f * p) / tot)
    c = np.corrcoef(x[0], x[1])[0, 1]
    st["lr_corr"] = round(float(c), 3)
    return st


def _cmap(v):
    stops = np.array([[0, 0, 4], [40, 11, 84], [101, 21, 110], [159, 42, 99], [212, 72, 66], [245, 125, 21], [250, 193, 39], [252, 255, 164]], float)
    v = np.clip(v, 0, 1) * (len(stops) - 1)
    i = np.minimum(v.astype(int), len(stops) - 2)
    fr = (v - i)[..., None]
    return (stops[i] * (1 - fr) + stops[i + 1] * fr).astype(np.uint8)


def draw(name, x, st, path):
    from PIL import Image, ImageDraw
    W, H1, H2, H3 = 1400, 180, 360, 170
    img = Image.new("RGB", (W, H1 + H2 + H3 + 60), (18, 14, 26))
    dr = ImageDraw.Draw(img)
    n = x.shape[1]
    # 波形（左右声道上下各一半）
    cols = np.array_split(np.arange(n), W)
    for ch, (y0, col) in enumerate(((H1 // 4, (120, 200, 255)), (3 * H1 // 4, (255, 150, 120)))):
        for i, idx in enumerate(cols):
            seg = x[ch, idx]
            lo, hi = float(seg.min()), float(seg.max())
            dr.line([(i, y0 - hi * H1 / 4), (i, y0 - lo * H1 / 4)], fill=col)
        lim = 10 ** (-1 / 20) * H1 / 4
        dr.line([(0, y0 - lim), (W, y0 - lim)], fill=(90, 60, 60))
        dr.line([(0, y0 + lim), (W, y0 + lim)], fill=(90, 60, 60))
    # 频谱图（对数频率 30 Hz – 16 kHz）
    mono = x.mean(axis=0)
    hop = 1024 if n > 20 * SR else 256
    f, t, Z = signal.stft(mono, SR, nperseg=4096, noverlap=4096 - hop)
    P = 20 * np.log10(np.abs(Z) + 1e-9)
    fl = np.geomspace(30, 16000, H2)
    rows = np.searchsorted(f, fl)
    rows = np.clip(rows, 0, len(f) - 1)
    P = P[rows][::-1]
    if P.shape[1] >= W:
        tc = np.array_split(np.arange(P.shape[1]), W)
        Pc = np.stack([P[:, c].mean(axis=1) for c in tc], axis=1)
    else:
        Pc = P[:, np.linspace(0, P.shape[1] - 1, W).astype(int)]
    top = np.percentile(Pc, 99.5)
    img.paste(Image.fromarray(_cmap((Pc - (top - 80)) / 80)), (0, H1))
    for fq in (60, 250, 1000, 2000, 4000, 8000):
        y = H1 + H2 - 1 - int(np.log(fq / 30) / np.log(16000 / 30) * (H2 - 1))
        dr.line([(0, y), (14, y)], fill=(255, 255, 255))
        dr.text((18, y - 6), f"{fq}", fill=(220, 220, 220))
    # 频段能量条
    y0 = H1 + H2 + 10
    bx = 20
    for k, v in st["bands"].items():
        h = int(v / 60 * (H3 - 40))
        dr.rectangle([bx, y0 + H3 - 30 - h, bx + 90, y0 + H3 - 30], fill=(250, 170, 60))
        dr.text((bx, y0 + H3 - 25), f"{k}Hz {v}%", fill=(220, 220, 220))
        bx += 130
    # 接缝放大（循环曲：尾 30 ms + 头 30 ms）
    if "seam_jump" in st:
        m = int(0.03 * SR)
        seg = np.concatenate([x[:, -m:], x[:, :m]], axis=1)
        sx0, sw = W - 400, 380
        yc = y0 + 70
        dr.rectangle([sx0, y0, sx0 + sw, y0 + 140], outline=(80, 80, 100))
        pts = [(sx0 + i * sw / seg.shape[1], yc - seg[0, i] * 60) for i in range(seg.shape[1])]
        dr.line(pts, fill=(120, 200, 255))
        dr.line([(sx0 + sw / 2, y0), (sx0 + sw / 2, y0 + 140)], fill=(255, 80, 80))
        dr.text((sx0 + 4, y0 + 2), "seam: last 30ms | first 30ms", fill=(220, 220, 220))
    txt = (f"{name}  {st['seconds']}s  peak {st['peak_dbfs']} dBFS  RMS {st['rms_dbfs']} dBFS  {st['lufs']} LUFS  clip {st['clipped_samples']}  "
           f"centroid {st['centroid_hz']} Hz  L/R corr {st['lr_corr']}")
    if "seam_jump" in st:
        txt += f"  seam jump {st['seam_jump']} (p99.9 step {st['step_p999']})"
    dr.text((10, H1 + H2 + H3 + 20), txt, fill=(255, 230, 160))
    img.save(path)


def main():
    args = sys.argv[1:]
    names = list(SONGS)
    if "--only" in args:
        names = [s for s in args[args.index("--only") + 1].split(",") if s]
    elif "--all" not in args and "--analyze" not in args:
        print(__doc__)
        return
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(REVIEW, exist_ok=True)
    sp = os.path.join(REVIEW, "music_stats.json")
    stats = json.load(open(sp)) if os.path.exists(sp) else {}
    for nm in names:
        path = os.path.join(OUT, nm + ".ogg")
        rep = {}
        if "--analyze" not in args:
            S = SONGS[nm]()
            x = S.render(rep)
            write_ogg(path, x)
            rep["bpm"] = S.bpm
            rep["bars"] = S.beats // 4
        y = decode(path)
        bpm = rep.get("bpm", stats.get(nm, {}).get("bpm", 0))
        st = analyze(nm, y, nm in LOOPS, 4 * 60.0 / bpm * SR if bpm else 0)
        st.update({k: v for k, v in rep.items()})
        if "--analyze" in args and nm in stats:
            for k in ("bpm", "stems"):
                if k in stats[nm]:
                    st.setdefault(k, stats[nm][k])
        stats[nm] = st
        draw(nm, y, st, os.path.join(REVIEW, nm + ".png"))
        json.dump(stats, open(sp, "w"), ensure_ascii=False, indent=1)
        print(f"[music] {nm}: {st['seconds']}s peak {st['peak_dbfs']} dBFS, {st['lufs']} LUFS, RMS {st['rms_dbfs']} dBFS"
              + (f", 接缝跳变 {st['seam_jump']}（全曲 99.9% 分位步长 {st['step_p999']}）" if "seam_jump" in st else ""))
    json.dump(stats, open(sp, "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
