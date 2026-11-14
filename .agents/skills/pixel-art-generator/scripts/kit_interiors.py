"""
Modular Medieval Flemish Interior Furniture & Tapestry Kit ("Shopkit")
for Temeraire: Wings of the Brotherhood.

Composes churches, bakeries, taverns, apothecaries, weaver workshops, and merchant
offices from reusable 16px structural bays (`blocks`), wood grain presets, cloth
accent palettes, and modular tabletop prop overlays.
"""

import os
import random
from pixel_art_lib import PAL, PixelCanvas

BAY_W = 16

WOOD_PRESETS = {
    "oak": ("T0", "T1", "T2", "T3", "T4"),
    "walnut": ("S", "T0", "T1", "T2", "T3"),
    "pine": ("T1", "T2", "H0", "H1", "H2"),
}

CLOTH_PRESETS = {
    "crimson": ("I0", "I1", "I2", "Y2"),
    "emerald": ("E0", "E1", "E2", "Y2"),
    "navy": ("U0", "U1", "BL1", "Y2"),
    "linen": ("H1", "L1", "L0", "T2"),
}


def _plank_panel(
    c: PixelCanvas, x: int, y: int, w: int, h: int, wood_id: str, horiz: bool = True
) -> None:
    d, sh, md, hi, top = WOOD_PRESETS[wood_id]
    c.rect(x, y, w, h, md)
    c.line(x, y, x + w - 1, y, top)
    c.line(x, y + h - 1, x + w - 1, y + h - 1, d)
    if horiz:
        for py in range(y + 2, y + h - 1, 3):
            c.line(x + 1, py, x + w - 2, py, sh)
            if py + 1 < y + h - 1:
                c.line(x + 1, py + 1, x + w - 2, py + 1, hi)
    else:
        for px in range(x + 2, x + w - 1, 3):
            c.line(px, y + 1, px, y + h - 2, sh)
            if px + 1 < x + w - 1:
                c.line(px + 1, y + 1, px + 1, y + h - 2, hi)
    c.line(x, y, x, y + h - 1, sh)
    c.line(x + w - 1, y, x + w - 1, y + h - 1, d)


def make_pew(wood_id: str = "oak", blocks: int = 2) -> PixelCanvas:
    w = blocks * BAY_W + 4
    h = 24
    c = PixelCanvas(w, h)
    d, sh, md, hi, top = WOOD_PRESETS[wood_id]
    c.ellipse(w // 2, 20, w // 2 - 2, 3, (14, 15, 22, 105))
    # Rear molded bench backrest (y=3..9)
    _plank_panel(c, 3, 4, w - 6, 6, wood_id, horiz=True)
    # Upholstered seat plank + front kneeler rail
    _plank_panel(c, 3, 10, w - 6, 7, wood_id, horiz=True)
    c.rect(4, 16, w - 8, 3, sh)
    c.line(4, 17, w - 5, 17, md)
    # Carved end cheeks & divider bays
    for bx in range(2, w - 2, BAY_W):
        if bx in (2, w - 5):
            c.rect(bx, 3, 3, 17, d)
            c.line(bx + 1, 3, bx + 1, 18, hi)
            c.pset(bx + 1, 2, top)
        else:
            c.rect(bx, 5, 2, 12, sh)
            c.pset(bx, 5, top)
    c.add_outline("K", selective_hue=True)
    return c


def make_altar(wood_id: str = "walnut", cloth_id: str = "crimson", blocks: int = 3) -> PixelCanvas:
    w = blocks * BAY_W + 4
    h = 32
    c = PixelCanvas(w, h)
    c0, c1, c2, gold = CLOTH_PRESETS[cloth_id]
    c.ellipse(w // 2, 27, w // 2 - 2, 4, (14, 15, 22, 115))
    # Limestone dais step + dark timber altar chest
    c.rect(2, 22, w - 4, 6, "C0")
    c.rect(3, 23, w - 6, 3, "C2")
    _plank_panel(c, 4, 10, w - 8, 14, wood_id, horiz=True)
    # Crisp white linen altar cloth top + hanging crimson/gold frontal
    c.rect(4, 8, w - 8, 6, "L0")
    c.line(4, 13, w - 5, 13, "L2")
    fx0 = 10
    fw = w - 20
    c.rect(fx0, 12, fw, 11, c1)
    c.line(fx0, 12, fx0 + fw - 1, 12, gold)
    c.line(fx0, 22, fx0 + fw - 1, 22, gold)
    # Center embroidered gold Latin cross on frontal
    cx = w // 2
    c.line(cx, 14, cx, 20, gold)
    c.line(cx - 2, 16, cx + 2, 16, gold)
    # Brass altar candelabra left & right + gilded chalice center
    for lx in (8, w - 10):
        c.line(lx, 5, lx, 9, "Y2")
        c.line(lx, 3, lx, 5, "L0")
        c.pset(lx, 2, "Y3")
    c.rect(cx - 1, 6, 3, 3, "Y2")
    c.pset(cx, 5, "Y3")
    c.add_outline("K", selective_hue=True)
    return c


def make_apothecary_shelf(wood_id: str = "oak", blocks: int = 2, seed: int = 7) -> PixelCanvas:
    w = blocks * BAY_W + 4
    h = 34
    c = PixelCanvas(w, h)
    d, sh, md, hi, top = WOOD_PRESETS[wood_id]
    rng = random.Random(seed + blocks)
    c.ellipse(w // 2, 30, w // 2 - 2, 3, (14, 15, 22, 110))
    # Back cabinet shell & crowned cornice
    _plank_panel(c, 3, 2, w - 6, 28, wood_id, horiz=False)
    c.rect(2, 2, w - 4, 3, top)
    c.line(2, 2, w - 3, 2, hi)
    # Recessed dark shelf niches + glowing medicine bottles/herbs
    phial_cols = ("BL1", "E2", "I2", "Y2", "L1", "C3")
    for sy in (6, 14):
        c.rect(5, sy, w - 10, 6, "S")
        c.line(4, sy + 6, w - 5, sy + 6, hi)
        px = 6
        while px < w - 8:
            col = rng.choice(phial_cols)
            bw = 2 if rng.random() < 0.6 else 3
            bh = rng.randint(4, 5)
            c.rect(px, sy + (6 - bh), bw, bh, col)
            c.pset(px, sy + (6 - bh), "L0")
            px += bw + 1
    # Lower apothecary drawers with brass knob pulls
    for bx in range(4, w - 8, 8):
        _plank_panel(c, bx, 22, 7, 6, wood_id, horiz=True)
        c.pset(bx + 3, 24, "Y2")
    c.add_outline("K", selective_hue=True)
    return c


def make_shop_counter(
    mode: str = "bakery", wood_id: str = "pine", cloth_id: str = "linen", blocks: int = 3
) -> PixelCanvas:
    w = blocks * BAY_W + 4
    h = 28
    c = PixelCanvas(w, h)
    c.ellipse(w // 2, 24, w // 2 - 2, 3, (14, 15, 22, 110))
    # Front counter paneling + solid counter top slab
    _plank_panel(c, 3, 12, w - 6, 12, wood_id, horiz=False)
    _plank_panel(c, 2, 6, w - 4, 8, wood_id, horiz=True)
    if mode == "bakery":
        # Flour runner + warm crusty boules + brass scale
        c.rect(5, 7, w - 10, 5, "L1")
        for lx in range(8, w - 18, 9):
            c.ellipse(lx + 2, 9, 3, 2, "R2")
            c.line(lx + 1, 8, lx + 3, 8, "H2")
        # Brass flour scale at right bay
        c.line(w - 11, 4, w - 11, 10, "Y2")
        c.line(w - 14, 5, w - 8, 5, "Y3")
        c.pset(w - 14, 7, "Y1")
        c.pset(w - 8, 7, "Y1")
    elif mode == "tavern":
        c.line(3, 6, w - 4, 6, "T4")
        # Gleaming pewter tankards, tapped pitcher, & burning candle
        for tx in (8, 16, w - 14):
            c.rect(tx, 5, 3, 4, "C2")
            c.line(tx, 4, tx + 2, 4, "L0")
            c.pset(tx + 3, 6, "C1")
        # Ale jug & brass candlestick center
        cx = w // 2
        c.rect(cx - 2, 5, 4, 5, "R1")
        c.pset(cx - 1, 4, "L1")
        c.line(cx + 6, 4, cx + 6, 8, "L0")
        c.pset(cx + 6, 3, "Y3")
    else:
        c0, c1, _, gold = CLOTH_PRESETS[cloth_id]
        c.rect(6, 7, w - 12, 5, c1)
        c.line(6, 11, w - 7, 11, gold)
    c.add_outline("K", selective_hue=True)
    return c


def make_tavern_keg_rack(wood_id: str = "walnut", blocks: int = 2) -> PixelCanvas:
    w = blocks * BAY_W + 4
    h = 32
    c = PixelCanvas(w, h)
    c.ellipse(w // 2, 28, w // 2 - 2, 3, (14, 15, 22, 110))
    _plank_panel(c, 3, 3, w - 6, 25, wood_id, horiz=False)
    c.rect(2, 3, w - 4, 3, WOOD_PRESETS[wood_id][4])
    # Pewter shelf plates at top, twin iron-hooped ale tuns at bottom
    c.rect(5, 7, w - 10, 6, "S")
    for px in range(7, w - 9, 7):
        c.circle(px + 2, 10, 2, "C3")
    for kx in range(6, w - 11, 12):
        c.rect(kx, 16, 10, 10, "T1")
        c.rect(kx + 1, 17, 8, 8, "T3")
        c.line(kx + 2, 17, kx + 2, 24, "C1")
        c.line(kx + 7, 17, kx + 7, 24, "C1")
        c.pset(kx + 5, 22, "Y2")
    c.add_outline("K", selective_hue=True)
    return c


def make_weaver_loom(wood_id: str = "oak", cloth_id: str = "crimson") -> PixelCanvas:
    w, h = 52, 34
    c = PixelCanvas(w, h)
    d, sh, md, hi, top = WOOD_PRESETS[wood_id]
    c0, c1, c2, gold = CLOTH_PRESETS[cloth_id]
    c.ellipse(w // 2, 29, 23, 4, (14, 15, 22, 110))
    # Heavy 4-post oak Flemish loom frame
    for px in (5, w - 8):
        c.rect(px, 3, 4, 26, md)
        c.line(px + 1, 3, px + 1, 28, top)
    c.rect(4, 3, w - 8, 4, top)
    c.rect(5, 23, w - 10, 3, md)
    # Taut vertical linen warp threads + woven crimson tapestry cloth sheet
    for tx in range(11, w - 11, 2):
        c.line(tx, 7, tx, 23, "L1")
    c.rect(10, 13, w - 20, 10, c1)
    c.line(10, 13, w - 11, 13, c2)
    c.line(10, 17, w - 11, 17, gold)
    c.line(10, 22, w - 11, 22, c0)
    # Hardwood shuttle & beater bar
    c.rect(8, 11, w - 16, 2, hi)
    c.rect(22, 10, 8, 2, "T4")
    c.add_outline("K", selective_hue=True)
    return c


def make_merchant_desk(wood_id: str = "walnut") -> PixelCanvas:
    w, h = 36, 28
    c = PixelCanvas(w, h)
    c.ellipse(w // 2, 24, 15, 3, (14, 15, 22, 105))
    # Twin carved pedestals + recessed knee hole
    _plank_panel(c, 4, 12, 9, 12, wood_id, horiz=True)
    _plank_panel(c, w - 13, 12, 9, 12, wood_id, horiz=True)
    c.rect(13, 13, w - 26, 9, (18, 15, 16, 150))
    # Tabletop + open Bruges ledger book, quill inkwell & silver coins
    _plank_panel(c, 3, 5, w - 6, 8, wood_id, horiz=True)
    c.rect(8, 6, 11, 6, "T0")
    c.rect(9, 6, 4, 5, "L0")
    c.rect(14, 6, 4, 5, "L1")
    c.rect(24, 7, 3, 3, "S")
    c.line(25, 4, 27, 7, "L0")
    c.pset(22, 10, "C3")
    c.pset(24, 11, "Y2")
    c.add_outline("K", selective_hue=True)
    return c


def make_woven_rug(cloth_id: str = "crimson", blocks: int = 3) -> PixelCanvas:
    w = blocks * BAY_W
    h = 32
    c = PixelCanvas(w, h)
    c0, c1, c2, gold = CLOTH_PRESETS[cloth_id]
    # Cream tassel fringe left & right
    for py in range(3, h - 3, 2):
        c.line(0, py, 2, py, "L1")
        c.line(w - 3, py, w - 1, py, "L1")
    # Woven body & double gold geometric medallion border
    c.rect(3, 2, w - 6, h - 4, c0)
    c.rect(4, 3, w - 8, h - 6, c1)
    c.rect_outline(5, 4, w - 10, h - 8, gold)
    c.rect_outline(7, 6, w - 14, h - 12, c2)
    cx, cy = w // 2, h // 2
    for dy in range(-5, 6):
        hw = 7 - abs(dy) * 7 // 5
        c.rect(cx - hw, cy + dy, hw * 2 + 1, 1, gold if abs(dy) >= 4 else c0)
    c.ellipse(cx, cy, 3, 2, c2)
    c.pset(cx, cy, gold)
    return c


def generate_modular_interiors(sprites_dir: str) -> None:
    specs = {
        "furn_pew_oak_2b.png": make_pew("oak", 2),
        "furn_pew_oak_3b.png": make_pew("oak", 3),
        "furn_altar_cloth_3b.png": make_altar("walnut", "crimson", 3),
        "furn_shelf_apothecary_2b.png": make_apothecary_shelf("oak", 2, seed=11),
        "furn_shelf_apothecary_3b.png": make_apothecary_shelf("walnut", 3, seed=29),
        "furn_counter_bakery_3b.png": make_shop_counter("bakery", "pine", "linen", 3),
        "furn_counter_tavern_3b.png": make_shop_counter("tavern", "walnut", "crimson", 3),
        "furn_keg_rack_oak_2b.png": make_tavern_keg_rack("oak", 2),
        "furn_weaver_loom_3b.png": make_weaver_loom("oak", "crimson"),
        "furn_desk_merchant_2b.png": make_merchant_desk("walnut"),
        "furn_rug_crimson_3b.png": make_woven_rug("crimson", 3),
        "furn_rug_emerald_3b.png": make_woven_rug("emerald", 3),
    }
    for fname, canvas in specs.items():
        canvas.save_png(os.path.join(sprites_dir, fname))
