"""全局风格参数：调色板、材质命名、描边、比例常量。

改这里一处，重新运行 build.py --all 就能整批更新所有资产。

调色板贴图 palette.png：256×512，16 列 × 32 行，每格 16 像素、一个颜色（批次 3 从 256×256 扩大一倍）。
- 第 0～15 行：固有色（albedo）
- 第 16～31 行：对应格子的自发光色（同一列、行号 +16，即贴图下半张）；不发光的格子是黑色
- 皮肤色（第 0～2 行的第 0～3 列）：M_skin 材质在运行时按皮肤编号横向偏移 U
- 队伍色（第 6 行=蓝队，第 7 行=红队）：M_team 材质在运行时按队伍纵向偏移 V
"""

PALETTE_SIZE = 256          # 宽
PALETTE_H = 512             # 高（上半固有色、下半自发光）
CELLS = 16                  # 列数
ROWS = 16                   # 固有色行数
CELL_PX = PALETTE_SIZE // CELLS


def _hex(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0)


# ---------------------------------------------------------------------------
# 调色板：名字 -> (行, 列, 固有色, 自发光色或 None)
# ---------------------------------------------------------------------------
_P = {}


def _put(name, row, col, albedo, emissive=None):
    assert 0 <= row < ROWS and 0 <= col < CELLS, name
    for k, v in _P.items():
        assert (v[0], v[1]) != (row, col), f"palette cell clash {name} vs {k}"
    _P[name] = (row, col, albedo, emissive)


# 皮肤（列 = 皮肤编号：0 金丝熊、1 布丁、2 银狐、3 三线）
SKINS = ["gold", "pudding", "silver", "stripe"]
_SKIN_FUR = ["#f2a54a", "#f7d37c", "#e4e1ea", "#b2adbd"]
_SKIN_CREAM = ["#fff3e0", "#fff8e6", "#ffffff", "#f6f3f9"]
# 背部条纹：非三线皮肤用略深一点的毛色，三线用深色条纹
_SKIN_STRIPE = ["#e8963c", "#efc56a", "#d6d2df", "#5e5868"]
for i in range(4):
    _put(f"fur_{SKINS[i]}", 0, i, _SKIN_FUR[i])
    _put(f"cream_{SKINS[i]}", 1, i, _SKIN_CREAM[i])
    _put(f"stripe_{SKINS[i]}", 2, i, _SKIN_STRIPE[i])
# 资产脚本里统一用这三个名字，运行时按皮肤偏移
SKIN_FUR = "fur_gold"
SKIN_CREAM = "cream_gold"
SKIN_STRIPE = "stripe_gold"

# 仓鼠固定色
_put("nose_pink", 0, 4, "#ff7f96")
_put("ear_inner", 0, 5, "#ffb3c1")
_put("blush", 0, 6, "#ff8fa3")
_put("paw", 0, 7, "#f7b2a8")
_put("paw_light", 0, 8, "#ffd9c0")
_put("eye_black", 0, 9, "#2a1d24")
_put("eye_white", 0, 10, "#ffffff", "#ffffff")
_put("mouth", 0, 11, "#3a2730")
_put("whisker", 0, 12, "#7a4a3a")
_put("tongue", 0, 13, "#ff6f86")
_put("tooth", 0, 14, "#fffaf0")
_put("white", 0, 15, "#ffffff")

# 小兵（敌我共用身体，头盔走队伍色）
_put("minion_fur", 1, 4, "#d9a066")
_put("minion_cream", 1, 5, "#fff2df")
_put("gear_navy", 1, 6, "#2d3846")
_put("gear_navy_light", 1, 7, "#45536a")

# 武器材质
_put("gun_metal", 3, 0, "#3a3d45")
_put("gun_dark", 3, 1, "#2b2d33")
_put("gun_darker", 3, 2, "#24262b")
_put("gun_light", 3, 3, "#5a5d66")
_put("gun_steel", 3, 4, "#8f939b")
_put("gun_chrome", 3, 5, "#c9ced6")
_put("wood", 3, 6, "#8a5a32")
_put("wood_dark", 3, 7, "#5a3a22")
_put("wood_red", 3, 8, "#7a4a2a")
_put("polymer_olive", 3, 9, "#4b5530")
_put("brass", 3, 10, "#e8c45a")
_put("shell_red", 3, 11, "#d8423f")
_put("rubber", 3, 12, "#1d2229")
_put("sticker_yellow", 3, 13, "#ffcf3a")
_put("sticker_mint", 3, 14, "#7fe3c8")
_put("lens", 3, 15, "#7fe3ff", "#7fe3ff")

# 进化路线色（A 橙、B 蓝、C 紫）；自发光版用于第 9 级发光
_put("path_a", 4, 0, "#ff9a3c", "#ff9a3c")
_put("path_b", 4, 1, "#5fb0ff", "#5fb0ff")
_put("path_c", 4, 2, "#c77dff", "#c77dff")
_put("gold_ring", 4, 3, "#ffcf3a", "#7a5a10")
_put("ice", 4, 4, "#cfefff", "#204050")
_put("torch_glass", 4, 5, "#fff6c2", "#fff6c2")
_put("vest_olive", 4, 6, "#4b5530")
_put("vest_dark", 4, 7, "#3a4228")
_put("headband_red", 4, 8, "#e0443f")
_put("clover", 4, 9, "#4caf50")
_put("clover_dark", 4, 10, "#2e7d32")
_put("glasses", 4, 11, "#2b1d24")
_put("shoe_red", 4, 12, "#e0443f")
_put("magnet_red", 4, 13, "#e0443f")
_put("magnet_steel", 4, 14, "#c9ced6")
_put("regen_green", 4, 15, "#8de0a6", "#8de0a6")

# 场景：纸箱、书、台灯、喷漆罐、弹簧板、零食盒、地板
_put("cardboard", 5, 0, "#c89359")
_put("cardboard_light", 5, 1, "#e6c58a")
_put("cardboard_dark", 5, 2, "#9a6a3c")
_put("label_red", 5, 3, "#d84a3a")
_put("book_blue", 5, 4, "#3d6fb5")
_put("book_red", 5, 5, "#c0392b")
_put("book_green", 5, 6, "#2e8b57")
_put("book_yellow", 5, 7, "#d4a017")
_put("book_purple", 5, 8, "#7d3c98")
_put("book_orange", 5, 9, "#e67e22")
_put("paper", 5, 10, "#f4ead8")
_put("lamp_dark", 5, 11, "#3a3f48")
_put("lamp_pole", 5, 12, "#55585f")
_put("lamp_shade", 5, 13, "#f2e2c0", "#5a4a20")
_put("bulb", 5, 14, "#fff1c0", "#fff1c0")
_put("spray_red", 5, 15, "#d8423f")
_put("spray_yellow", 2, 4, "#ffd23f")
_put("spring_yellow", 2, 5, "#ffd23f")
_put("snack_orange", 2, 6, "#ff8a3d")
_put("snack_purple", 2, 7, "#8f5bd6")
_put("snack_green", 2, 8, "#7ccf5a")
_put("floor_wood", 2, 9, "#6b4e3a")
_put("floor_wood_dark", 2, 10, "#4d3829")
_put("floor_wood_light", 2, 11, "#82614a")
_put("carpet", 2, 12, "#76674a")
_put("carpet_light", 2, 13, "#8f7f5a")
_put("wall_plaster", 2, 14, "#3a3050")
_put("wall_trim", 2, 15, "#5a4c70")
_put("can_grey", 1, 8, "#8c8a99")
_put("can_grey_dark", 1, 9, "#6e6c7c")
_put("towel_cream", 1, 10, "#e9dcc3")
_put("towel_stripe", 1, 11, "#c9b18a")
_put("pencil_yellow", 1, 12, "#f2c230")
_put("eraser_pink", 1, 13, "#f59ab0")
_put("seed_shell", 1, 14, "#3a3236")
_put("seed_stripe", 1, 15, "#e8e0d0")

# 队伍色：第 6 行蓝、第 7 行红（列对应）
TEAM_ROWS = {"blue": 6, "red": 7}
_TEAM = [
    ("team_main", "#3d8bff", "#e0443f", None, None),
    ("team_dark", "#2a62c9", "#b8302c", None, None),
    ("team_light", "#9cc8ff", "#ffb0b0", None, None),
    ("team_glow", "#4fa3ff", "#ff5b5b", "#4fa3ff", "#ff5b5b"),
    ("team_knit", "#3577e0", "#cf3b37", None, None),
]
for i, (n, cb, cr, eb, er) in enumerate(_TEAM):
    _put(n, 6, i, cb, eb)
    _put(n + "__red", 7, i, cr, er)

# 队伍行（第 6、7 行）第 5 列以后没被队伍色占用：放批次 2 新增的普通颜色（不随队伍偏移，只要不用 M_team 材质）
_put("laser_pink", 6, 5, "#ff5fa8", "#ff5fa8")
_put("rail_cyan", 6, 6, "#5fe0ff", "#5fe0ff")
_put("blade_edge", 6, 7, "#d8f0ff", "#9fd8ff")
_put("pilot_blue", 6, 8, "#7fb6ff", "#7fb6ff")
_put("lens_orange", 6, 9, "#ff8a3d", "#ff8a3d")
_put("roach_brown", 6, 10, "#6b3a1e")
_put("roach_dark", 6, 11, "#3b2414")
_put("rat_grey", 6, 12, "#8a8796")
_put("rat_dark", 6, 13, "#5a5866")
_put("boss_fur", 6, 14, "#6d6070")
_put("boss_robe", 6, 15, "#6a2c8a")
_put("chick_yellow", 7, 5, "#ffe066")
_put("firefly_glow", 7, 6, "#c8ff6a", "#c8ff6a")
_put("hedgehog_brown", 7, 7, "#7a5a40")
_put("spike_dark", 7, 8, "#3a2c22")
_put("glass_green", 7, 9, "#5fae6a")
_put("flare_red", 7, 10, "#ff4a3a", "#ff4a3a")
_put("smoke_grey", 7, 11, "#b8b4c4")
_put("copper", 7, 12, "#d07a3a")
_put("poison_green", 7, 13, "#9be05a", "#6fbf3a")
_put("katana_wrap", 7, 14, "#2a2030")
_put("crown_gold", 7, 15, "#ffd166", "#7a5a10")

# ---------------------------------------------------------------------------
# 批次 3 新增（第 8～15 行）
# ---------------------------------------------------------------------------
# 第 8 行：武器贴纸、识别色
_put("sticker_pink", 8, 0, "#ff7fb0")
_put("sticker_orange", 8, 1, "#ff9a3c")
_put("sticker_blue", 8, 2, "#4f8dff")
_put("sticker_white", 8, 3, "#f4f1ea")
_put("sand_tan", 8, 4, "#b89a6a")
_put("sand_dark", 8, 5, "#8a7350")
_put("gun_blue", 8, 6, "#3e5f9e")
_put("gun_gold", 8, 7, "#d9a93a")
_put("gauge_red", 8, 8, "#e0443f", "#802020")
_put("led_green", 8, 9, "#7dff8a", "#7dff8a")
_put("led_red", 8, 10, "#ff4a4a", "#ff4a4a")
_put("led_amber", 8, 11, "#ffb02e", "#ffb02e")
_put("tassel_red", 8, 12, "#d8323a")
_put("grenade_yellow", 8, 13, "#e8c23a")
_put("hose_dark", 8, 14, "#2a2f38")
_put("screen_dark", 8, 15, "#15222a", "#0a2a30")
# 第 9 行：场景分区
_put("tile_cream", 9, 0, "#b9a07a")
_put("tile_terracotta", 9, 1, "#94523c")
_put("dust_grey", 9, 2, "#5e544e")
_put("tile_white_dim", 9, 3, "#a9a398")
_put("dress_sage", 9, 4, "#697e73")
_put("dress_clay", 9, 5, "#a87158")
_put("dress_ink", 9, 6, "#344354")
_put("dress_paper", 9, 7, "#d6cbb1")
_put("dress_felt", 9, 8, "#424955")
_put("dress_ochre", 9, 9, "#b29358")
_put("dress_coffee", 9, 10, "#473226")
_put("dress_biscuit", 9, 11, "#c6a477")


def color(name):
    """名字 -> 固有色 RGB（0..1 sRGB）。"""
    return _hex(_P[name][2])


def cell(name):
    r, c, _, _ = _P[name]
    return r, c


def uv(name):
    """名字 -> Blender UV（左下角原点）。glTF 导出时会翻转为左上角原点。"""
    r, c = cell(name)
    return ((c + 0.5) / CELLS, 1.0 - (r + 0.5) / (2 * ROWS))


def palette_names():
    return list(_P.keys())


def palette_pixels():
    """返回 256×512 RGBA（sRGB，0..1）像素列表，行从上到下。"""
    px = [[(0.0, 0.0, 0.0, 1.0)] * PALETTE_SIZE for _ in range(PALETTE_H)]
    grey = (0.5, 0.5, 0.5, 1.0)
    for row in range(ROWS):
        for col in range(CELLS):
            for y in range(CELL_PX):
                for x in range(CELL_PX):
                    px[row * CELL_PX + y][col * CELL_PX + x] = grey
    for name, (r, c, alb, emi) in _P.items():
        a = _hex(alb) + (1.0,)
        e = (_hex(emi) + (1.0,)) if emi else (0.0, 0.0, 0.0, 1.0)
        for y in range(CELL_PX):
            for x in range(CELL_PX):
                px[r * CELL_PX + y][c * CELL_PX + x] = a
                px[(r + ROWS) * CELL_PX + y][c * CELL_PX + x] = e
    return px


# ---------------------------------------------------------------------------
# 材质槽（Godot 运行时按名字前缀换成 toon 着色器，见 game/scripts/view/toon_materials.gd）
# ---------------------------------------------------------------------------
MAT_TOON = "M_toon_base"      # 普通平涂
MAT_SKIN = "M_skin"           # 仓鼠毛色，运行时按皮肤偏移
MAT_TEAM = "M_team"           # 队伍色，运行时按队伍偏移
MAT_METAL = "M_metal"         # 金属：卡通硬高光
MAT_GLASS = "M_glass"         # 玻璃/镜片：高光 + 少量自发光
MAT_EMISSIVE = "M_emissive"   # 发光件（灯泡、指示灯）
MAT_EYE = "M_eye"             # 眼睛：无描边、硬高光
MAT_FLAT = "M_flat"           # 贴在表面的小件（嘴、胡须、贴纸）：不描边

MATERIALS = [MAT_TOON, MAT_SKIN, MAT_TEAM, MAT_METAL, MAT_GLASS, MAT_EMISSIVE, MAT_EYE, MAT_FLAT]

# 描边（Godot 端读取同名常量的拷贝，见 toon_outline.gdshader）
OUTLINE_PX_CHARACTER = 2.0
OUTLINE_PX_PROP = 1.5
OUTLINE_LIGHTNESS = 0.35

# ---------------------------------------------------------------------------
# 比例（米）。数据里 1 单位 = 1 厘米。
# ---------------------------------------------------------------------------
HAMSTER_R = 0.16            # 碰撞半径
HAMSTER_UNIT = 0.15         # 原型 R=15 的造型基准
WEAPON_THICKEN = 1.3        # 玩具化加粗倍数

# 武器握把约定（武器局部坐标，原点 = 右手握把；+Y 为枪口方向，+Z 向上）
# 动作脚本按武器类别把手放到这些位置
GRIP = {
    "pistol": {"R": (0.0, 0.0, 0.0), "L": (-0.014, 0.004, -0.006)},
    "rifle": {"R": (0.0, 0.0, 0.0), "L": (0.0, 0.07, 0.0)},
    "shotgun": {"R": (0.0, 0.0, 0.0), "L": (0.0, 0.072, 0.0)},
    # 批次 2 新增的持握类别（左手相对右手握把的位置）
    "heavy": {"R": (0.0, 0.0, 0.0), "L": (-0.004, 0.11, -0.018)},
    "launcher": {"R": (0.0, 0.0, 0.0), "L": (0.0, 0.1, -0.012)},
    "melee": {"R": (0.0, 0.0, 0.0), "L": (0.0, -0.032, 0.0)},
    "flame": {"R": (0.0, 0.0, 0.0), "L": (0.0, 0.1, -0.006)},
    "dual": {"R": (0.0, 0.0, 0.0), "L": (-0.13, 0.0, 0.0)},
    "beam": {"R": (0.0, 0.0, 0.0), "L": (0.0, 0.085, -0.004)},
}


def write_palette_png(path):
    """用标准库写 PNG（不依赖 Blender 图像 API）。"""
    import os
    import struct
    import zlib

    rows = palette_pixels()
    raw = bytearray()
    for row in rows:
        raw.append(0)
        for (r, g, b, a) in row:
            raw.extend((int(round(r * 255)), int(round(g * 255)), int(round(b * 255)), int(round(a * 255))))

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", PALETTE_SIZE, PALETTE_H, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)
    # 颜色名 -> [行, 列]，给 Godot 端程序生成的网格上色用
    import json
    with open(os.path.splitext(path)[0] + ".json", "w", encoding="utf-8") as f:
        json.dump({k: [v[0], v[1]] for k, v in _P.items()}, f, ensure_ascii=False, indent=0)
    return path
