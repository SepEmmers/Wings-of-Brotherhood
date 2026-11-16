"""
Modular Medieval Flemish Building Kit ("Block" Composer) for Temeraire: Wings of the Brotherhood.

Composes varied city houses, guildhalls, shops, and manors from reusable 16px-wide
architectural bay blocks (`width_blocks` = 3..10), swappable wall/roof palettes,
gable styles, doors, shuttered windows, shop awnings, chimneys, and guild signs.

Adding a new city building takes a single 3-5 line recipe dict rather than hand-coding
hundreds of rectangle/shingle coordinates.
"""

import os
import random
from pixel_art_lib import PAL, PixelCanvas

BLOCK_W = 16
SIDE_PAD = 4  # Overhang margin on left/right eaves (total PNG width = blocks * 16 + 8)

# Wall material palettes: (base, mid, hi, dark_mortar_or_beam, quoin, plinth_base, plinth_hi)
WALL_PRESETS = {
    "plaster_timber": ("L1", "L1", "L0", "T0", "T1", "C1", "C2"),
    "ochre_timber": ("H1", "H2", "H3", "T0", "T1", "C1", "C2"),
    "brick_warm": ("R0", "R1", "R2", "R0", "C2", "C0", "C2"),
    "brick_rose": ("D0", "D1", "R2", "R0", "L1", "C0", "C1"),
    "ashlar_stone": ("C0", "C1", "C2", "C0", "C3", "C0", "C1"),
    "wharf_oak": ("T0", "T1", "T2", "T0", "T3", "C0", "C1"),
}

# Roof shingle / thatch palettes: (dark, mid, hi, ridge_hi)
ROOF_PRESETS = {
    "terracotta": ("R0", "R1", "R2", "R3"),
    "slate": ("CS", "C1", "C2", "CS2"),
    "moss_slate": ("E0", "CS", "C1", "E2"),
    "thatch": ("T1", "H0", "H1", "H2"),
    "charcoal": ("S", "C0", "C1", "C2"),
}

AWNING_PRESETS = {
    "crimson": ("I2", "I0", "L0", "L2"),
    "emerald": ("E2", "E0", "L0", "L2"),
    "navy": ("U1", "U0", "L1", "L2"),
    "ochre": ("Y1", "Y0", "L0", "L2"),
}


def _shingle_band(c: PixelCanvas, x: int, y: int, w: int, h: int, rcols: tuple) -> None:
    d_c, m_c, l_c, _ = rcols
    for py in range(y, y + h):
        row_idx = py - y
        for px in range(x, x + w):
            if row_idx % 4 == 0:
                c.pset(px, py, d_c)
            elif (px + (row_idx // 4) * 3) % 6 == 0:
                c.pset(px, py, l_c)
            elif row_idx % 4 == 1:
                c.pset(px, py, l_c if (px + row_idx) % 3 == 0 else m_c)
            else:
                c.pset(px, py, m_c)


def _paint_wall_region(
    c: PixelCanvas, x: int, y: int, w: int, h: int, wall_id: str, seed: int
) -> None:
    base, mid, hi, beam, quoin, _, _ = WALL_PRESETS[wall_id]
    rng = random.Random(seed)
    if wall_id in ("brick_warm", "brick_rose", "ashlar_stone"):
        c.rect(x, y, w, h, base)
        step_x = 7 if wall_id == "ashlar_stone" else 5
        step_y = 4 if wall_id == "ashlar_stone" else 3
        for row, py in enumerate(range(y, y + h - 1, step_y)):
            off = 3 if (row % 2) else 0
            for px in range(x + off, x + w - 1, step_x):
                bw = min(step_x - 1, x + w - px)
                bh = min(step_y - 1, y + h - py)
                col = hi if rng.random() < 0.24 else mid
                c.rect(px, py, bw, bh, col)
        # Rusticated stone corner quoins
        for qy in range(y + 2, y + h - 4, 6):
            qw = 3 if ((qy // 6) % 2 == 0) else 2
            c.rect(x, qy, qw, 4, quoin)
            c.rect(x + w - qw, qy, qw, 4, quoin)
    elif wall_id == "wharf_oak":
        c.rect(x, y, w, h, base)
        for idx, py in enumerate(range(y, y + h, 4)):
            bh = min(3, y + h - py)
            c.rect(x, py, w, bh, mid if idx % 2 == 0 else hi)
            c.rect(x + ((idx * 5) % max(4, w - 4)), py, 1, bh, base)
        c.rect(x, y, 2, h, quoin)
        c.rect(x + w - 2, y, 2, h, quoin)
    else:
        # Half-timbered limewash / ochre plaster
        c.rect(x, y, w, h, hi)
        for py in range(y, y + h):
            for px in range(x, x + w):
                if rng.random() < 0.14:
                    c.pset(px, py, mid)
        c.rect(x, y, 2, h, beam)
        c.rect(x + w - 2, y, 2, h, beam)


def _draw_stepped_gable(
    c: PixelCanvas, cx: int, y_base: int, width_px: int, height_px: int, wall_id: str, roof_id: str
) -> None:
    """Draw a stepped Flemish brick/stone gable triangle rising above the eave line."""
    steps = max(3, height_px // 4)
    _, mid, hi, _, quoin, _, _ = WALL_PRESETS[wall_id]
    cap_c = ROOF_PRESETS[roof_id][3]
    for si in range(steps):
        frac = 1.0 - (si / float(steps))
        sw = max(8, int(round(width_px * frac)) // 2 * 2)
        sy = y_base - (si + 1) * 4
        sx = cx - sw // 2
        c.rect(sx, sy, sw, 4, mid if si % 2 == 0 else hi)
        c.line(sx, sy, sx + sw - 1, sy, quoin)
        c.pset(sx, sy, cap_c)
        c.pset(sx + sw - 1, sy, cap_c)
    # Small diamond attic louver near gable apex
    if height_px >= 14:
        c.rect(cx - 2, y_base - height_px // 2 - 2, 4, 5, "T0")
        c.rect(cx - 1, y_base - height_px // 2 - 1, 2, 3, "Y1")


def _draw_chimney(c: PixelCanvas, x: int, y_top: int, y_roof: int, brick_id: str) -> None:
    bcols = WALL_PRESETS[brick_id]
    ch_h = max(6, y_roof - y_top + 4)
    c.rect(x, y_top, 7, ch_h, bcols[0])
    for py in range(y_top + 2, y_top + ch_h, 3):
        c.rect(x + 1, py, 2, 2, bcols[2])
        c.rect(x + 4, py, 2, 2, bcols[1])
    c.rect(x - 1, y_top, 9, 2, "C2")
    c.line(x - 1, y_top, x + 7, y_top, "C3")


def _draw_sign(c: PixelCanvas, x: int, y: int, kind: str) -> None:
    """Hanging wrought-iron street/guild sign plaque."""
    c.line(x - 1, y, x + 7, y, "S")
    c.pset(x + 2, y + 1, "C2")
    c.pset(x + 6, y + 1, "C2")
    c.rect(x + 1, y + 2, 7, 7, "T0")
    c.rect(x + 2, y + 3, 5, 5, "T2")
    if kind == "bread":
        c.rect(x + 3, y + 4, 3, 2, "Y2")
    elif kind == "tankard":
        c.rect(x + 3, y + 4, 3, 3, "Y1")
        c.line(x + 3, y + 4, x + 5, y + 4, "L0")
    elif kind == "herb":
        c.rect(x + 3, y + 4, 3, 3, "E2")
        c.pset(x + 4, y + 5, "E3")
    elif kind == "anchor":
        c.line(x + 4, y + 4, x + 4, y + 6, "CS2")
        c.line(x + 3, y + 6, x + 5, y + 6, "CS2")
    elif kind == "anvil":
        c.rect(x + 3, y + 5, 3, 2, "C3")
    elif kind == "scroll":
        c.rect(x + 3, y + 4, 3, 3, "L0")
        c.pset(x + 4, y + 5, "I1")
    elif kind == "cloth":
        c.rect(x + 2, y + 4, 2, 3, "I1")
        c.rect(x + 4, y + 4, 2, 3, "U2")
    elif kind == "shield":
        c.rect(x + 3, y + 4, 3, 3, "I1")
        c.pset(x + 4, y + 5, "Y2")


def _draw_bay_ground(
    c: PixelCanvas,
    bx: int,
    by: int,
    bh: int,
    kind: str,
    spec: dict,
    rng: random.Random,
) -> None:
    shutter = spec.get("shutter", "E1")
    flower_col = spec.get("flower", "R3")
    awning_key = spec.get("awning", "crimson")
    floor_y = by + bh

    if kind == "door_oak":
        c.rect(bx + 2, floor_y - 2, 12, 3, "C2")
        c.line(bx + 2, floor_y - 2, bx + 13, floor_y - 2, "C3")
        c.rect(bx + 3, by + 6, 10, bh - 7, "T0")
        c.rect(bx + 4, by + 7, 8, bh - 8, "T2")
        c.line(bx + 8, by + 7, bx + 8, floor_y - 2, "T1")
        c.pset(bx + 10, by + 14, "Y2")
    elif kind == "door_gothic":
        c.rect(bx + 2, floor_y - 2, 12, 3, "C2")
        c.rect(bx + 2, by + 4, 12, bh - 5, "C2")
        c.line(bx + 3, by + 4, bx + 12, by + 4, "C3")
        c.rect(bx + 4, by + 6, 8, bh - 7, "T0")
        c.rect(bx + 5, by + 7, 6, bh - 8, "T2")
        c.line(bx + 5, by + 11, bx + 10, by + 11, "C0")
        c.pset(bx + 9, by + 14, "Y2")
    elif kind in ("double_door_l", "double_door_r", "double_door"):
        if kind == "double_door_l":
            c.rect(bx + 3, floor_y - 2, 13, 3, "C2")
            c.rect(bx + 3, by + 5, 13, bh - 6, "T0")
            c.rect(bx + 5, by + 7, 11, bh - 8, "T2")
            c.line(bx + 5, by + 12, bx + 15, by + 12, "C0")
            c.pset(bx + 14, by + 15, "Y2")
        elif kind == "double_door_r":
            c.rect(bx, floor_y - 2, 13, 3, "C2")
            c.rect(bx, by + 5, 13, bh - 6, "T0")
            c.rect(bx, by + 7, 11, bh - 8, "T2")
            c.line(bx, by + 12, bx + 10, by + 12, "C0")
            c.pset(bx + 1, by + 15, "Y2")
        else:
            c.rect(bx + 1, floor_y - 2, 14, 3, "C2")
            c.rect(bx + 1, by + 6, 14, bh - 7, "T0")
            c.rect(bx + 2, by + 7, 12, bh - 8, "T2")
            c.line(bx + 8, by + 7, bx + 8, floor_y - 2, "T0")
            c.pset(bx + 6, by + 14, "Y2")
            c.pset(bx + 9, by + 14, "Y2")
    elif kind in ("win_shutter", "win_flower", "win_tall"):
        win_h = 13 if kind == "win_tall" else 10
        wy = by + (5 if kind == "win_tall" else 6)
        # Shutters on flanks
        c.rect(bx + 1, wy, 2, win_h, shutter)
        c.rect(bx + 13, wy, 2, win_h, shutter)
        # Mullioned glass casing
        c.rect(bx + 3, wy, 10, win_h, "T0")
        c.rect(bx + 4, wy + 1, 8, win_h - 2, "Y1")
        c.rect(bx + 5, wy + 2, 6, win_h - 4, "Y2")
        c.pset(bx + 5, wy + 2, "Y3")
        c.line(bx + 8, wy + 1, bx + 8, wy + win_h - 2, "T0")
        c.line(bx + 4, wy + win_h // 2, bx + 11, wy + win_h // 2, "T0")
        if kind == "win_flower":
            fy = wy + win_h
            c.rect(bx + 2, fy, 12, 3, "T1")
            for fx in range(bx + 3, bx + 13, 3):
                c.pset(fx, fy - 1, "G2")
                c.pset(fx + 1, fy - 1, flower_col)
    elif kind == "win_lancet":
        c.rect(bx + 5, by + 5, 6, 12, "C2")
        c.rect(bx + 6, by + 6, 4, 10, "T0")
        c.rect(bx + 7, by + 7, 2, 8, "Y1")
        c.pset(bx + 7, by + 8, "Y3")
    elif kind.startswith("stall"):
        hi_a, lo_a, hi_b, lo_b = AWNING_PRESETS.get(awning_key, AWNING_PRESETS["crimson"])
        c.rect(bx, by + 11, 16, 2, (20, 16, 18, 125))
        for si in range(4):
            sx = bx + si * 4
            hi_c = hi_a if (si % 2 == 0) else hi_b
            lo_c = lo_a if (si % 2 == 0) else lo_b
            c.rect(sx, by + 3, 4, 6, hi_c)
            c.rect(sx, by + 9, 4, 2, lo_c)
        # Wooden counter & market goods
        c.rect(bx + 1, floor_y - 8, 14, 7, "T1")
        c.rect(bx, floor_y - 9, 16, 2, "T3")
        if "herb" in kind:
            for hx in (3, 8, 12):
                c.rect(bx + hx, floor_y - 11, 2, 2, "E2")
                c.pset(bx + hx + 1, floor_y - 12, "E3")
        elif "fish" in kind:
            for fx in (3, 9):
                c.rect(bx + fx, floor_y - 11, 4, 2, "SG2")
                c.pset(bx + fx + 3, floor_y - 11, "SG1")
        elif "cloth" in kind:
            for cx, col in ((2, "I1"), (7, "U2"), (12, "E2")):
                c.rect(bx + cx, floor_y - 12, 3, 3, col)
                c.pset(bx + cx + 1, floor_y - 12, "Y1")
        else:
            for lx in (3, 9):
                c.ellipse(bx + lx + 2, floor_y - 10, 2.5, 1.5, "Y1")
                c.pset(bx + lx + 1, floor_y - 11, "Y2")
    elif kind == "banner_guard":
        # Scarlet Inquisition wall banner & kite shield crest
        c.rect(bx + 2, by + 6, 4, 11, "I1")
        c.line(bx + 3, by + 7, bx + 4, by + 7, "Y2")
        c.rect(bx + 9, by + 7, 5, 9, "CS2")
        c.rect(bx + 10, by + 8, 3, 7, "I1")
        c.pset(bx + 11, by + 11, "Y2")
    elif kind == "ivy":
        # Connected climbing leafy tendrils hugging the plinth and lower masonry
        bx_mid = bx + 8 + ((seed_x := (bx // BLOCK_W) % 3) - 1) * 2
        c.line(bx_mid, floor_y - 4, bx_mid - 2, floor_y - 16, "G0")
        c.line(bx_mid + 1, floor_y - 5, bx_mid + 4, floor_y - 13, "G0")
        for dx, dy, rx, ry in ((-2, -6, 3.0, 2.2), (2, -8, 2.8, 2.2), (-1, -12, 2.6, 2.4), (3, -13, 2.0, 1.8), (0, -17, 2.0, 1.8)):
            c.ellipse(bx_mid + dx, floor_y + dy, rx, ry, "G1")
            c.pset(bx_mid + dx - 1, floor_y + dy - 1, "G2")
            c.pset(bx_mid + dx, floor_y + dy + 1, "G0")
    elif kind == "woodstack":
        for row in range(3):
            for lx in range(2 + row, 13 - row, 3):
                c.rect(bx + lx, floor_y - 3 - row * 3, 3, 2, "T1")
                c.pset(bx + lx + 1, floor_y - 3 - row * 3, "T3")


def _draw_bay_upper(c: PixelCanvas, bx: int, by: int, uh: int, kind: str, spec: dict) -> None:
    shutter = spec.get("shutter", "E1")
    flower_col = spec.get("flower", "R3")
    if kind in ("u_win", "u_flower"):
        wy = by + 4
        c.rect(bx + 2, wy, 2, 9, shutter)
        c.rect(bx + 12, wy, 2, 9, shutter)
        c.rect(bx + 4, wy, 8, 9, "T0")
        c.rect(bx + 5, wy + 1, 6, 7, "Y1")
        c.rect(bx + 6, wy + 2, 4, 5, "Y2")
        c.line(bx + 8, wy + 1, bx + 8, wy + 7, "T0")
        if kind == "u_flower":
            c.rect(bx + 3, wy + 9, 10, 2, "T1")
            for fx in range(bx + 4, bx + 12, 3):
                c.pset(fx, wy + 8, "G2")
                c.pset(fx + 1, wy + 8, flower_col)
    elif kind == "u_double":
        wy = by + 4
        for wx in (bx + 2, bx + 9):
            c.rect(wx, wy, 5, 9, "T0")
            c.rect(wx + 1, wy + 1, 3, 7, "Y1")
            c.rect(wx + 1, wy + 2, 2, 4, "Y2")
    elif kind == "u_timber":
        c.rect(bx, by, 2, uh, "T0")
        c.rect(bx + 14, by, 2, uh, "T0")
        c.line(bx + 2, by + 2, bx + 13, by + uh - 3, "T1")
        c.line(bx + 13, by + 2, bx + 2, by + uh - 3, "T1")
    elif kind == "u_hoist":
        c.rect(bx + 4, by + 3, 8, 12, "T0")
        c.rect(bx + 5, by + 4, 6, 10, "T2")
        c.line(bx + 8, by + 4, bx + 8, by + 13, "T0")
        c.rect(bx + 7, by, 2, 3, "T0")
        c.line(bx + 8, by, bx + 8, by + 6, "H1")


def compose_building(spec: dict) -> PixelCanvas:
    """
    Assemble a complete variable-width Medieval Flemish building from a declarative spec:
      blocks (int): 3..10 (16px wide per block)
      stories (int): 1 or 2
      wall (str): key in WALL_PRESETS
      roof (str): key in ROOF_PRESETS
      roof_style (str): pitched | stepped_left | stepped_center | twin_gable | dormer
      ground (list[str]): bay keys matching len == blocks
      upper (list[str]): optional upper-story bay keys (when stories == 2)
      shutter, flower, awning: palette accents
      chimneys (list[int]): column indices carrying brick/stone chimneys
      lanterns (list[int]): column indices mounting warm iron wall lanterns
      sign (tuple[int, str] | None): (col_idx, kind) hanging guild sign
    """
    blocks = max(2, int(spec.get("blocks", 4)))
    stories = max(1, min(2, int(spec.get("stories", 2))))
    wall_id = spec.get("wall", "plaster_timber")
    roof_id = spec.get("roof", "terracotta")
    roof_style = spec.get("roof_style", "pitched")
    seed = int(spec.get("seed", sum(ord(ch) for ch in str(spec))))

    facade_w = blocks * BLOCK_W
    w = facade_w + SIDE_PAD * 2
    roof_h = 22
    top_head = 12  # Room for chimneys / gable steps above ridge
    upper_h = 18 if stories >= 2 else 0
    ground_h = 26
    bot_pad = 5

    y_ridge = top_head
    y_eave = y_ridge + roof_h
    y_upper = y_eave
    y_ground = y_upper + upper_h
    y_floor = y_ground + ground_h
    h = y_floor + bot_pad

    c = PixelCanvas(w, h)
    rng = random.Random(seed)
    fx0 = SIDE_PAD

    # 1. Soft grounded shadow under plinth
    c.ellipse(w * 0.5, y_floor + 1.5, facade_w * 0.5 + 2.0, 3.5, (14, 15, 20, 120))

    # 2. Facade Masonry / Plaster Walls + Half-Timber Framing
    total_wall_h = upper_h + ground_h
    upper_wall = spec.get("upper_wall", "plaster_timber" if (stories == 2 and wall_id == "ashlar_stone") else wall_id)
    if stories == 2:
        _paint_wall_region(c, fx0, y_upper, facade_w, upper_h, upper_wall, seed + 31)
    _paint_wall_region(c, fx0, y_ground, facade_w, ground_h, wall_id, seed + 7)

    # Stone foundation plinth at base
    _, _, _, _, _, pl_b, pl_hi = WALL_PRESETS[wall_id]
    c.rect(fx0, y_floor - 5, facade_w, 5, pl_b)
    for sx in range(fx0 + 1, fx0 + facade_w - 5, 7):
        c.rect(sx, y_floor - 4, 5, 3, pl_hi)

    # Horizontal timber / stone stringcourse between stories
    if stories == 2:
        c.rect(fx0 - 1, y_ground - 2, facade_w + 2, 3, "T0")
        c.line(fx0 - 1, y_ground - 2, fx0 + facade_w, y_ground - 2, "T2")

    # 3. Ground & Upper Architectural Bay Blocks + Seamless Vertical Half-Timbering
    ground_bays = list(spec.get("ground", ["win_shutter", "door_oak"] + ["win_shutter"] * max(0, blocks - 2)))
    upper_bays = list(spec.get("upper", ["u_win"] * blocks))
    for i in range(blocks):
        bx = fx0 + i * BLOCK_W
        gkind = ground_bays[i % len(ground_bays)]
        _draw_bay_ground(c, bx, y_ground, ground_h, gkind, spec, rng)
        if wall_id in ("plaster_timber", "ochre_timber") and i > 0:
            prev_g = ground_bays[(i - 1) % len(ground_bays)]
            skip_seam = (prev_g == "double_door_l" and gkind == "double_door_r") or (prev_g.startswith("stall") and gkind.startswith("stall"))
            if not skip_seam:
                c.rect(bx - 1, y_ground + 1, 2, ground_h - 6, "T0")
                c.line(bx, y_ground + 1, bx, y_ground + ground_h - 6, "T1")
        if stories == 2:
            ukind = upper_bays[i % len(upper_bays)]
            _draw_bay_upper(c, bx, y_upper, upper_h, ukind, spec)
            if upper_wall in ("plaster_timber", "ochre_timber") and i > 0:
                c.rect(bx - 1, y_upper, 2, upper_h - 2, "T0")
                c.line(bx, y_upper, bx, y_upper + upper_h - 2, "T1")

    # 4. Chimneys rising behind roof ridge
    chimney_wall = spec.get("chimney_wall", "brick_warm" if "brick" in wall_id or "plaster" in wall_id else "ashlar_stone")
    for ch_col in spec.get("chimneys", []):
        cx_ch = fx0 + max(0, min(blocks - 1, int(ch_col))) * BLOCK_W + 4
        _draw_chimney(c, cx_ch, max(2, y_ridge - 8), y_ridge + 6, chimney_wall)

    # 5. Roof Body, Eaves Shadow, Dormers & Flemish Gables
    rcols = ROOF_PRESETS[roof_id]
    # Eave shadow onto wall top
    c.rect(fx0, y_eave, facade_w, 2, (20, 16, 20, 115))
    # Shingle roof trapezoid
    for ry in range(y_ridge, y_eave):
        frac = (ry - y_ridge) / float(max(1, roof_h - 1))
        inset = int(round((1.0 - frac) * 3.0))
        rx = 1 + inset
        rw = w - 2 - inset * 2
        row_idx = ry - y_ridge
        for px in range(rx, rx + rw):
            if row_idx % 4 == 0:
                c.pset(px, ry, rcols[0])
            elif (px + (row_idx // 4) * 3) % 6 == 0:
                c.pset(px, ry, rcols[2])
            elif row_idx % 4 == 1:
                c.pset(px, ry, rcols[2] if (px + row_idx) % 3 == 0 else rcols[1])
            else:
                c.pset(px, ry, rcols[1])
    c.line(5, y_ridge, w - 6, y_ridge, rcols[3])
    c.line(1, y_eave - 1, w - 2, y_eave - 1, "T0")

    gable_wall = spec.get("gable_wall", wall_id if wall_id != "plaster_timber" else "brick_warm")
    if roof_style == "stepped_left":
        _draw_stepped_gable(c, fx0 + 18, y_eave - 4, 28, 22, gable_wall, roof_id)
    elif roof_style == "stepped_center":
        _draw_stepped_gable(c, w // 2, y_eave - 2, min(40, facade_w // 2), 26, gable_wall, roof_id)
    elif roof_style == "twin_gable":
        _draw_stepped_gable(c, fx0 + facade_w // 4, y_eave - 2, 28, 22, gable_wall, roof_id)
        _draw_stepped_gable(c, fx0 + (facade_w * 3) // 4, y_eave - 2, 28, 22, gable_wall, roof_id)
    elif roof_style == "dormer":
        cols = [blocks // 2] if blocks <= 4 else [1, blocks - 2]
        for dc in cols:
            dx = fx0 + dc * BLOCK_W + 3
            c.rect(dx, y_eave - 12, 10, 11, "T1")
            _shingle_band(c, dx - 1, y_eave - 16, 12, 5, rcols)
            c.rect(dx + 2, y_eave - 10, 6, 7, "T0")
            c.rect(dx + 3, y_eave - 9, 4, 5, "Y1")
            c.pset(dx + 3, y_eave - 9, "Y3")

    # 6. Wall Lanterns & Hanging Signs
    for lc in spec.get("lanterns", []):
        lx = fx0 + max(0, min(blocks - 1, int(lc))) * BLOCK_W + 1
        ly = y_ground + 9
        c.rect(lx, ly, 3, 4, "S")
        c.rect(lx + 1, ly + 1, 1, 2, "Y2")
        c.pset(lx + 1, ly + 1, "Y3")
    if spec.get("sign"):
        scol, skind = spec["sign"]
        # Anchor guild sign onto pillar/bay boundary so it never blocks glowing windows
        sx = fx0 + max(0, min(blocks, int(scol))) * BLOCK_W - 4
        sx = max(fx0 + 1, min(fx0 + facade_w - 9, sx))
        _draw_sign(c, sx, y_ground + 3, skind)

    c.add_outline("K", selective_hue=True)
    return c


# Starter Modular City Building Set demonstrating 4, 5, 6 & 7-block variations
CITY_BUILDING_RECIPES = {
    # 4-Block Narrow Flemish Canal Houses
    "city_house_4a.png": {
        "blocks": 4, "stories": 2, "wall": "plaster_timber", "roof": "terracotta",
        "roof_style": "stepped_left", "shutter": "E1", "flower": "R3",
        "ground": ["win_flower", "door_oak", "win_shutter", "ivy"],
        "upper": ["u_win", "u_timber", "u_flower", "u_win"],
        "chimneys": [3], "lanterns": [1],
    },
    "city_house_4b.png": {
        "blocks": 4, "stories": 2, "wall": "brick_warm", "roof": "slate",
        "roof_style": "dormer", "shutter": "U1", "flower": "Y2",
        "ground": ["door_gothic", "win_flower", "win_shutter", "woodstack"],
        "upper": ["u_double", "u_flower", "u_win", "u_timber"],
        "chimneys": [0], "lanterns": [0],
    },
    "city_cottage_4c.png": {
        "blocks": 4, "stories": 1, "wall": "ochre_timber", "roof": "thatch",
        "roof_style": "pitched", "shutter": "R1", "flower": "R3",
        "ground": ["win_flower", "door_oak", "win_flower", "woodstack"],
        "chimneys": [2], "lanterns": [1],
    },
    # 5-Block Artisan Shop & Apothecary
    "city_bakery_5a.png": {
        "blocks": 5, "stories": 2, "wall": "brick_rose", "roof": "terracotta",
        "roof_style": "stepped_center", "shutter": "E1", "awning": "crimson",
        "ground": ["stall_bread", "stall_bread", "door_oak", "win_flower", "win_shutter"],
        "upper": ["u_win", "u_flower", "u_hoist", "u_flower", "u_win"],
        "chimneys": [0], "lanterns": [2], "sign": (2, "bread"),
    },
    # 6-Block Canal Tavern
    "city_tavern_6a.png": {
        "blocks": 6, "stories": 2, "wall": "plaster_timber", "roof": "moss_slate",
        "roof_style": "dormer", "shutter": "R1", "flower": "Y2", "awning": "ochre",
        "ground": ["win_tall", "double_door_l", "double_door_r", "stall_herb", "win_tall", "ivy"],
        "upper": ["u_double", "u_timber", "u_flower", "u_flower", "u_double", "u_timber"],
        "chimneys": [1, 5], "lanterns": [1, 3], "sign": (3, "tankard"),
    },
    # 7-Block Grand Burgher Manor & Brotherhood Guildhall
    "city_manor_7a.png": {
        "blocks": 7, "stories": 2, "wall": "brick_warm", "roof": "slate",
        "roof_style": "twin_gable", "shutter": "U1", "flower": "L0", "awning": "navy",
        "ground": ["win_tall", "win_flower", "double_door_l", "double_door_r", "win_flower", "win_tall", "ivy"],
        "upper": ["u_win", "u_double", "u_flower", "u_hoist", "u_flower", "u_double", "u_win"],
        "chimneys": [0, 6], "lanterns": [2, 4], "sign": (6, "scroll"),
    },
    "city_guild_7b.png": {
        "blocks": 7, "stories": 2, "wall": "ashlar_stone", "roof": "moss_slate",
        "roof_style": "stepped_center", "shutter": "E1", "awning": "emerald",
        "ground": ["win_lancet", "stall_herb", "door_gothic", "ivy", "stall_fish", "win_flower", "win_lancet"],
        "upper": ["u_timber", "u_win", "u_double", "u_hoist", "u_double", "u_win", "u_timber"],
        "chimneys": [1, 5], "lanterns": [2], "sign": (3, "anchor"),
    },
    # 6-Block Weavers Guild & 7-Block Garrison Hall (Queue 10 Diegetic Distinction)
    "city_weavers_6b.png": {
        "blocks": 6, "stories": 2, "wall": "brick_warm", "roof": "terracotta",
        "roof_style": "stepped_center", "shutter": "U1", "flower": "Y2", "awning": "navy",
        "ground": ["stall_cloth", "win_tall", "double_door_l", "double_door_r", "stall_cloth", "win_flower"],
        "upper": ["u_win", "u_flower", "u_hoist", "u_hoist", "u_flower", "u_win"],
        "chimneys": [0, 5], "lanterns": [2, 3], "sign": (1, "cloth"),
    },
    "city_garrison_7c.png": {
        "blocks": 7, "stories": 2, "wall": "ashlar_stone", "roof": "slate",
        "roof_style": "dormer", "shutter": "I0", "awning": "crimson",
        "ground": ["banner_guard", "win_lancet", "double_door_l", "double_door_r", "win_lancet", "banner_guard", "win_lancet"],
        "upper": ["u_timber", "u_double", "u_win", "u_double", "u_win", "u_double", "u_timber"],
        "chimneys": [1, 5], "lanterns": [2, 4], "sign": (1, "shield"),
    },
    # Historic Louvain Districts (1425 University, Dyers' Island, Mason Workyard)
    "city_louvain_scholar_5a.png": {
        "blocks": 5, "stories": 2, "wall": "brick_rose", "roof": "slate",
        "roof_style": "dormer", "shutter": "U1", "flower": "Y2", "awning": "navy",
        "ground": ["win_lancet", "door_gothic", "win_tall", "win_flower", "ivy"],
        "upper": ["u_double", "u_win", "u_flower", "u_double", "u_timber"],
        "chimneys": [1], "lanterns": [1, 3], "sign": (3, "scroll"),
    },
    "city_louvain_dyer_5b.png": {
        "blocks": 5, "stories": 2, "wall": "ochre_timber", "roof": "terracotta",
        "roof_style": "stepped_left", "shutter": "E1", "flower": "R3", "awning": "crimson",
        "ground": ["stall_cloth", "door_oak", "stall_cloth", "win_flower", "woodstack"],
        "upper": ["u_win", "u_hoist", "u_flower", "u_win", "u_timber"],
        "chimneys": [4], "lanterns": [1], "sign": (2, "cloth"),
    },
    "city_louvain_mason_4a.png": {
        "blocks": 4, "stories": 1, "wall": "ashlar_stone", "roof": "slate",
        "roof_style": "stepped_center", "shutter": "T2", "flower": "Y2",
        "ground": ["win_shutter", "door_oak", "woodstack", "ivy"],
        "chimneys": [0], "lanterns": [1],
    },
}


def generate_modular_buildings(sprites_dir: str) -> int:
    for fname, spec in CITY_BUILDING_RECIPES.items():
        compose_building(spec).save_png(os.path.join(sprites_dir, fname))
    return len(CITY_BUILDING_RECIPES)
