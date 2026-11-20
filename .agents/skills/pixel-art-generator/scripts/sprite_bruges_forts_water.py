"""
Bruges Fortifications, Gatehouses, Watergates, Wall Details, Canal Barges,
Grote Markt Fountain & Bakery Bread Loaf sprites for Temeraire: Wings of the Brotherhood.
"""

import os
import math
import random
from pixel_art_lib import PAL, PixelCanvas


def _draw_stone_masonry_rect(
    c: PixelCanvas,
    x: int,
    y: int,
    w: int,
    h: int,
    seed: int = 11,
    row_h: int = 4,
    blk_w: int = 8,
    moss: bool = True,
) -> None:
    """Coursed ashlar limestone blocks with highlights, dark joints & subtle moss."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, "C0")
    for r_i, py in enumerate(range(y, y + h, row_h)):
        bh = min(row_h - 1, y + h - py)
        if bh <= 0:
            break
        off = (blk_w // 2) if (r_i % 2 == 1) else 0
        px = x - off
        while px < x + w:
            sx = max(x, px)
            ex = min(x + w, px + blk_w - 1)
            bw = ex - sx
            if bw > 0:
                tint = rng.random()
                face = "C2" if tint < 0.34 else ("CS2" if tint < 0.56 else "C1")
                c.rect(sx, py, bw, bh, face)
                c.line(sx, py, ex - 1, py, "C3" if tint < 0.65 else "C2")
                if bh >= 2:
                    c.line(sx, py + bh - 1, ex - 1, py + bh - 1, "C0")
            px += blk_w
    if moss:
        for _ in range(max(1, (w * h) // 75)):
            mx = rng.randint(x, max(x, x + w - 2))
            my = rng.randint(y + max(0, h // 2), max(y, y + h - 1))
            c.pset(mx, my, "E0")
            if mx + 1 < x + w and rng.random() < 0.5:
                c.pset(mx + 1, my, "E1")


def _draw_brick_masonry_rect(
    c: PixelCanvas, x: int, y: int, w: int, h: int, seed: int = 23
) -> None:
    rng = random.Random(seed)
    c.rect(x, y, w, h, "R0")
    for r_i, py in enumerate(range(y, y + h, 3)):
        bh = min(2, y + h - py)
        off = 3 if (r_i % 2 == 1) else 0
        for px in range(x - off, x + w, 6):
            sx = max(x, px)
            ex = min(x + w, px + 5)
            if ex > sx:
                col = "R2" if rng.random() < 0.32 else ("D1" if rng.random() < 0.2 else "R1")
                c.rect(sx, py, ex - sx, bh, col)


def _make_walls(sprites_dir: str) -> None:
    # 1) prop_wall_h.png (32x36) - Tileable Horizontal Curtain Wall with Merlons & Walk
    p = PixelCanvas(32, 36)
    # Soft bottom shadow lip
    p.rect(0, 33, 32, 3, (14, 15, 22, 110))
    # Battlement merlons (2 spaced merlons seamless across x=0..31)
    for mx in (2, 18):
        p.rect(mx, 1, 12, 8, "S")
        _draw_stone_masonry_rect(p, mx + 1, 2, 10, 6, seed=100 + mx, row_h=3, blk_w=5, moss=False)
        p.line(mx + 1, 1, mx + 10, 1, "C3")
        p.line(mx + 1, 2, mx + 10, 2, "C3")
        p.line(mx, 9, mx + 11, 9, "C0")
    # Embrasure gaps between merlons show parapet walk
    for gx in (0, 14, 30):
        gw = 2 if gx != 14 else 4
        p.rect(gx, 5, gw, 5, "C0")
        p.rect(gx, 6, gw, 3, "CS2")
        p.line(gx, 6, gx + gw - 1, 6, "C2")
    # Parapet wall-walk ledge (y=9..14)
    p.rect(0, 9, 32, 6, "C1")
    for sx in range(0, 32, 8):
        p.rect(sx, 10, 7, 4, "CS2")
        p.line(sx, 10, sx + 6, 10, "C2")
    p.line(0, 9, 31, 9, "C0")
    p.line(0, 14, 31, 14, "S")
    # Outer vertical ashlar curtain face (y=15..31)
    _draw_stone_masonry_rect(p, 0, 15, 32, 17, seed=41, row_h=4, blk_w=8, moss=True)
    # Arrow-slit loophole centered per segment
    for ax in (8, 24):
        p.rect(ax, 18, 2, 7, "K")
        p.line(ax - 1, 20, ax + 2, 20, "C0")
        p.pset(ax, 21, "C0")
    # Plinth base course
    p.rect(0, 31, 32, 3, "CS")
    p.line(0, 31, 31, 31, "C1")
    p.line(0, 33, 31, 33, "S")
    p.save_png(os.path.join(sprites_dir, "prop_wall_h.png"))

    # 2) prop_wall_v.png (36x32) - Tileable Vertical Curtain Wall with Double Parapet
    v = PixelCanvas(36, 32)
    # Left & Right side drop shadows
    v.rect(0, 0, 2, 32, (14, 15, 22, 110))
    v.rect(34, 0, 2, 32, (14, 15, 22, 110))
    # Outer & Inner stone side faces
    _draw_stone_masonry_rect(v, 2, 0, 8, 32, seed=52, row_h=4, blk_w=6, moss=True)
    _draw_stone_masonry_rect(v, 26, 0, 8, 32, seed=53, row_h=4, blk_w=6, moss=True)
    v.line(2, 0, 2, 31, "S")
    v.line(33, 0, 33, 31, "S")
    # Center stone chemin-de-ronde walkway (x=12..23)
    v.rect(11, 0, 14, 32, "C1")
    for sy in range(0, 32, 8):
        v.rect(12, sy, 12, 7, "CS2")
        v.line(12, sy, 23, sy, "C2")
        v.line(12, sy + 6, 23, sy + 6, "C0")
    # Left & right crenellated merlons (every 16px, seamless)
    for my in (2, 18):
        v.rect(7, my, 5, 11, "S")
        v.rect(8, my + 1, 3, 9, "C2")
        v.line(8, my + 1, 10, my + 1, "C3")
        v.rect(24, my, 5, 11, "S")
        v.rect(25, my + 1, 3, 9, "C2")
        v.line(25, my + 1, 27, my + 1, "C3")
    v.line(10, 0, 10, 31, "C0")
    v.line(25, 0, 25, 31, "C0")
    v.save_png(os.path.join(sprites_dir, "prop_wall_v.png"))

    # 3) prop_garden_wall_h.png (32x24) - Brick Beguinage/Cloister Garden Wall H
    gh = PixelCanvas(32, 24)
    gh.rect(0, 21, 32, 3, (14, 15, 22, 100))
    # Chamfered limestone coping top (y=1..6)
    gh.rect(0, 1, 32, 6, "S")
    gh.rect(0, 2, 32, 4, "C2")
    gh.line(0, 2, 31, 2, "C3")
    for sx in range(0, 32, 8):
        gh.line(sx, 2, sx, 5, "C0")
    # Red brick face (y=7..20)
    _draw_brick_masonry_rect(gh, 0, 7, 32, 14, seed=77)
    gh.line(0, 7, 31, 7, "C0")
    gh.line(0, 20, 31, 20, "T0")
    # Ivy & moss clusters
    for mx, my in ((5, 10), (6, 11), (19, 14), (20, 15), (27, 9)):
        gh.rect(mx, my, 2, 2, "E0")
        gh.pset(mx, my, "E2")
    gh.save_png(os.path.join(sprites_dir, "prop_garden_wall_h.png"))

    # 4) prop_garden_wall_v.png (24x32) - Brick Cloister Wall V
    gv = PixelCanvas(24, 32)
    gv.rect(1, 0, 2, 32, (14, 15, 22, 95))
    gv.rect(21, 0, 2, 32, (14, 15, 22, 95))
    _draw_brick_masonry_rect(gv, 3, 0, 18, 32, seed=88)
    gv.line(3, 0, 3, 31, "S")
    gv.line(20, 0, 20, 31, "S")
    # Centered limestone coping strip running down middle
    gv.rect(6, 0, 12, 32, "C0")
    gv.rect(7, 0, 10, 32, "C2")
    gv.line(8, 0, 8, 31, "C3")
    for sy in range(0, 32, 8):
        gv.line(7, sy, 16, sy, "C0")
    gv.save_png(os.path.join(sprites_dir, "prop_garden_wall_v.png"))


def _make_bastions(sprites_dir: str) -> None:
    # 5) prop_bastion_round.png (64x64) - Cylindrical Stone Drum Tower & Conical Slate Turret
    r = PixelCanvas(64, 64)
    r.ellipse(32, 40, 28, 20, (14, 15, 22, 115))
    # Main battered cylindrical ashlar drum
    for py in range(20, 56):
        y_frac = (py - 20) / 36.0
        half_w = int(20 + 6.0 * math.sin(min(1.0, y_frac * 1.1) * math.pi * 0.5))
        for px in range(32 - half_w, 32 + half_w + 1):
            nx = (px - 32) / max(1.0, float(half_w))
            if py >= 51 and abs(nx) > 0.72:
                continue
            blk = ((py // 4) + (px // 7)) % 3
            if nx < -0.35:
                col = "C3" if blk == 0 else "C2"
            elif nx < 0.25:
                col = "C2" if blk == 0 else "C1"
            else:
                col = "C1" if blk == 0 else "CS"
            if py % 4 == 0:
                col = "C0"
            r.pset(px, py, col)
    # Arrow-slit loopholes on lower drum
    for sx in (21, 32, 43):
        r.rect(sx, 38, 2, 8, "K")
        r.line(sx - 1, 41, sx + 2, 41, "S")
    # Corbelled stone overhang ring (y=19..24)
    r.ellipse(32, 23, 24, 12, "S")
    r.ellipse(32, 21, 24, 12, "C1")
    for bx in range(11, 54, 5):
        r.rect(bx, 25, 2, 4, "C0")
        r.pset(bx, 25, "C3")
    # Crenellated radial parapet collar
    for ang_deg in range(0, 360, 45):
        rad = math.radians(ang_deg)
        mx = int(round(32 + math.cos(rad) * 21))
        my = int(round(20 + math.sin(rad) * 10))
        r.rect(mx - 3, my - 3, 6, 5, "C2")
        r.line(mx - 3, my - 3, mx + 2, my - 3, "C3")
    # Recessed conical dark slate spire rising cleanly from center (y=3..22)
    for py in range(4, 22):
        frac = (py - 4) / 18.0
        hw = max(1, int(frac * 17))
        for px in range(32 - hw, 32 + hw + 1):
            nx = (px - 32) / max(1.0, float(hw))
            if (py - 4) % 3 == 0:
                col = "S"
            elif nx < -0.25:
                col = "C2"
            elif nx < 0.25:
                col = "C1"
            else:
                col = "CS"
            r.pset(px, py, col)
    # Brass finial mast at apex
    r.line(32, 1, 32, 4, "Y2")
    r.pset(32, 1, "Y3")
    r.pset(33, 2, "Y1")
    r.add_outline("S", selective_hue=True)
    r.save_png(os.path.join(sprites_dir, "prop_bastion_round.png"))

    # 6) prop_bastion_square.png (64x64) - Square Ashlar Flanking Tower + Timber/Slate Cap
    sq = PixelCanvas(64, 64)
    sq.ellipse(32, 56, 26, 6, (14, 15, 22, 120))
    # Lower ashlar tower body (x=8..55, y=24..58)
    _draw_stone_masonry_rect(sq, 8, 24, 48, 34, seed=131, row_h=4, blk_w=8, moss=True)
    # Corner stone quoins (left & right)
    for qy in range(25, 56, 6):
        sq.rect(8, qy, 4, 4, "C3")
        sq.rect(52, qy, 4, 4, "CS2")
    # Embrasure arrow-slits + glowing guard watch-slit window
    sq.rect(20, 38, 2, 9, "K")
    sq.rect(42, 38, 2, 9, "K")
    sq.rect(29, 34, 6, 9, "T0")
    sq.rect(30, 35, 4, 7, "Y2")
    sq.line(30, 35, 30, 41, "Y3")
    # Corbelled parapet ledge (y=19..24)
    sq.rect(6, 20, 52, 5, "C2")
    sq.line(6, 20, 57, 20, "C3")
    for cx in range(8, 56, 6):
        sq.rect(cx, 24, 3, 2, "C0")
    # Hipped pyramidal slate roof rising inside battlement merlons (y=5..19)
    for py in range(5, 19):
        frac = (py - 5) / 14.0
        hw = int(3 + frac * 20)
        col_l = "C2" if py % 3 != 0 else "CS2"
        col_r = "CS" if py % 3 != 0 else "S"
        sq.rect(32 - hw, py, hw, 1, col_l)
        sq.rect(32, py, hw, 1, col_r)
    sq.line(31, 4, 33, 4, "Y2")
    sq.line(32, 2, 32, 5, "Y3")
    # 4 Prominent front stone merlons silhouette-overlapping roof eave
    for mx in (7, 20, 35, 48):
        _draw_stone_masonry_rect(sq, mx, 15, 9, 6, seed=200 + mx, row_h=3, blk_w=4, moss=False)
        sq.line(mx, 15, mx + 8, 15, "C3")
    sq.add_outline("S", selective_hue=True)
    sq.save_png(os.path.join(sprites_dir, "prop_bastion_square.png"))


def _make_gatehouses_and_watergates(sprites_dir: str) -> None:
    # 7) prop_gatehouse_pier_h.png (56x96) - Monumental Tall Flanking Stone Gatehouse Bastion Pier (H gate)
    ph = PixelCanvas(56, 96)
    ph.ellipse(28, 90, 22, 4.5, (14, 15, 22, 120))
    _draw_stone_masonry_rect(ph, 7, 28, 42, 62, seed=301, row_h=4, blk_w=8, moss=True)
    # Battered stone plinth & rusticated corner quoins
    ph.rect(6, 82, 44, 8, "C0")
    for qy in range(30, 82, 6):
        ph.rect(7, qy, 4, 4, "C3")
        ph.rect(45, qy, 4, 4, "CS2")
    # Upper and lower arrow-slit loopholes + wrought-iron torch sconce on lower cheek
    for ay in (40, 58):
        ph.rect(27, ay, 2, 10, "K")
        ph.line(25, ay + 4, 30, ay + 4, "S")
    ph.rect(26, 72, 4, 5, "S")
    ph.rect(27, 68, 2, 4, "R2")
    ph.pset(27, 67, "Y3")
    ph.pset(28, 68, "Y2")
    # Corbelled stone parapet collar & merlons (y=19..28)
    ph.rect(4, 21, 48, 7, "C2")
    ph.line(4, 21, 51, 21, "C3")
    for cx in range(6, 50, 7):
        ph.rect(cx, 27, 3, 3, "C0")
    for mx in (5, 22, 39):
        ph.rect(mx, 15, 11, 7, "C2")
        ph.line(mx, 15, mx + 10, 15, "C3")
    # Tall conical slate turret cap rising cleanly behind battlements (y=3..18)
    for py in range(3, 19):
        frac = (py - 3) / 16.0
        hw = int(2 + frac * 19.0)
        for px in range(28 - hw, 28 + hw + 1):
            col = "C2" if px < 26 else ("C1" if px < 31 else "CS")
            if py % 3 == 0:
                col = "S"
            ph.pset(px, py, col)
    ph.line(28, 0, 28, 4, "Y2")
    ph.pset(28, 0, "Y3")
    ph.add_outline("S", selective_hue=True)
    ph.save_png(os.path.join(sprites_dir, "prop_gatehouse_pier_h.png"))

    # 8) prop_gatehouse_arch_h.png (96x46) - Grand Gatehouse Portcullis Vault Bridge H
    ah = PixelCanvas(96, 46)
    _draw_stone_masonry_rect(ah, 2, 10, 92, 22, seed=312, row_h=4, blk_w=8, moss=False)
    for mx in range(4, 90, 13):
        ah.rect(mx, 3, 10, 7, "C2")
        ah.line(mx, 3, mx + 9, 3, "C3")
    ah.line(2, 10, 93, 10, "C3")
    # Deep arched stone voussoir underside + shadowed vault opening
    for px in range(8, 88):
        dx = (px - 48) / 40.0
        arch_y = int(35 - 12 * math.sqrt(max(0.0, 1.0 - dx * dx)))
        ah.rect(px, arch_y, 1, 45 - arch_y, (16, 18, 26, 135))
        ah.rect(px, arch_y - 3, 1, 3, "C3" if px % 4 != 0 else "C0")
    for ix in range(14, 83, 7):
        dx = (ix - 48) / 40.0
        arch_y = int(35 - 12 * math.sqrt(max(0.0, 1.0 - dx * dx)))
        ah.line(ix, arch_y + 1, ix, arch_y + 7, "S")
        ah.pset(ix, arch_y + 7, "C3")
    ah.line(12, 28, 83, 28, "C2")
    # Flemish City Escutcheon Crest Shield centered over keystone
    ah.rect(43, 12, 10, 11, "Y2")
    ah.rect(44, 13, 8, 9, "I1")
    ah.line(48, 13, 48, 20, "Y3")
    ah.line(45, 16, 50, 16, "Y3")
    ah.add_outline("S", selective_hue=True)
    ah.save_png(os.path.join(sprites_dir, "prop_gatehouse_arch_h.png"))

    # 8b) prop_port_gatehouse.png (144x96) - Harbor Stone Gatehouse Barbican with Twin Turrets & Open Roadway
    pg = PixelCanvas(144, 96)
    for tx in (4, 102):
        pg.ellipse(tx + 19, 90, 18, 4.0, (14, 15, 22, 115))
        _draw_stone_masonry_rect(pg, tx, 28, 38, 62, seed=500 + tx, row_h=4, blk_w=8, moss=True)
        pg.rect(tx - 1, 82, 40, 8, "C0")
        for qy in range(30, 82, 6):
            pg.rect(tx, qy, 3, 4, "C3")
            pg.rect(tx + 35, qy, 3, 4, "CS2")
        pg.rect(tx + 18, 42, 2, 10, "K")
        pg.rect(tx - 2, 21, 42, 6, "C2")
        pg.line(tx - 2, 21, tx + 39, 21, "C3")
        for mx in range(tx, tx + 36, 12):
            pg.rect(mx, 15, 9, 6, "C2")
            pg.line(mx, 15, mx + 8, 15, "C3")
        for py in range(3, 18):
            frac = (py - 3) / 15.0
            hw = int(2 + frac * 17.0)
            for px in range(tx + 19 - hw, tx + 19 + hw + 1):
                col = "C2" if px < tx + 17 else ("C1" if px < tx + 22 else "CS")
                if py % 3 == 0:
                    col = "S"
                pg.pset(px, py, col)
        pg.line(tx + 19, 0, tx + 19, 4, "Y2")
        # Lantern sconce facing the inner roadway cheek
        lx = tx + 32 if tx < 50 else tx + 3
        pg.rect(lx, 62, 3, 6, "S")
        pg.rect(lx, 58, 3, 4, "Y2")
        pg.pset(lx + 1, 59, "Y3")
    # Overhead vaulted bridge spanning clear central archway (x=42..101)
    _draw_stone_masonry_rect(pg, 41, 22, 62, 20, seed=577, row_h=4, blk_w=8, moss=False)
    for mx in range(44, 98, 11):
        pg.rect(mx, 15, 8, 7, "C2")
        pg.line(mx, 15, mx + 7, 15, "C3")
    pg.line(41, 22, 102, 22, "C3")
    for px in range(43, 101):
        dx = (px - 72) / 29.0
        arch_y = int(46 - 10 * math.sqrt(max(0.0, 1.0 - dx * dx)))
        pg.rect(px, arch_y, 1, 5, (16, 18, 26, 125))
        pg.rect(px, arch_y - 3, 1, 3, "C3" if px % 4 != 0 else "C0")
    for ix in range(48, 97, 6):
        dx = (ix - 72) / 29.0
        arch_y = int(46 - 10 * math.sqrt(max(0.0, 1.0 - dx * dx)))
        pg.line(ix, arch_y + 1, ix, arch_y + 5, "S")
        pg.pset(ix, arch_y + 5, "C3")
    # Central Flemish Shield Emblem
    pg.rect(68, 24, 8, 9, "Y2")
    pg.rect(69, 25, 6, 7, "I1")
    pg.line(72, 25, 72, 30, "Y3")
    pg.line(70, 28, 74, 28, "Y3")
    pg.add_outline("S", selective_hue=True)
    pg.save_png(os.path.join(sprites_dir, "prop_port_gatehouse.png"))

    # 9) prop_gatehouse_pier_v.png (64x48) - Flanking Stone Tower Pier (top/bottom of V gate)
    pv = PixelCanvas(64, 48)
    pv.ellipse(32, 43, 28, 4, (14, 15, 22, 115))
    _draw_stone_masonry_rect(pv, 6, 12, 52, 32, seed=321, row_h=4, blk_w=8, moss=True)
    for qy in range(14, 42, 6):
        pv.rect(6, qy, 4, 4, "C3")
        pv.rect(54, qy, 4, 4, "CS2")
    pv.rect(18, 22, 2, 8, "K")
    pv.rect(44, 22, 2, 8, "K")
    # Upper crenellated parapet across top edge
    pv.rect(4, 8, 56, 5, "C2")
    pv.line(4, 8, 59, 8, "C3")
    for mx in range(6, 54, 12):
        pv.rect(mx, 3, 9, 5, "C2")
        pv.line(mx, 3, mx + 8, 3, "C3")
    pv.add_outline("S", selective_hue=True)
    pv.save_png(os.path.join(sprites_dir, "prop_gatehouse_pier_v.png"))

    # 10) prop_gatehouse_arch_v.png (64x64) - Overhead Arch Bridge Spanning N-S Across E-W Road
    av = PixelCanvas(64, 64)
    # Stone bridge gallery spanning vertically (x=12..51, y=2..61)
    _draw_stone_masonry_rect(av, 12, 2, 40, 60, seed=335, row_h=5, blk_w=8, moss=False)
    # Left/right parapet stone rails + merlons
    for my in range(4, 58, 13):
        av.rect(9, my, 4, 9, "C2")
        av.line(9, my, 12, my, "C3")
        av.rect(51, my, 4, 9, "CS2")
        av.line(51, my, 54, my, "C2")
    # Flagstone wall-walk down middle
    av.rect(20, 2, 24, 60, "C1")
    for sy in range(4, 60, 8):
        av.rect(21, sy, 22, 6, "CS2")
        av.line(21, sy, 42, sy, "C2")
    # Portcullis winch housing box + raised iron spikes protruding along outer arch lip
    av.rect(25, 24, 14, 14, "T1")
    av.rect(27, 26, 10, 10, "T3")
    av.line(25, 24, 38, 24, "T4")
    for iy in range(10, 56, 9):
        av.line(8, iy, 12, iy, "C1")
        av.pset(7, iy, "C3")
        av.line(52, iy, 56, iy, "C1")
        av.pset(57, iy, "C3")
    av.add_outline("S", selective_hue=True)
    av.save_png(os.path.join(sprites_dir, "prop_gatehouse_arch_v.png"))

    # 11) prop_watergate_arch_h.png (64x40) - Vaulted Stone Canal Waterpoort Arch H
    wh = PixelCanvas(64, 40)
    # Left & Right moss-streaked water piers dipping to y=38
    _draw_stone_masonry_rect(wh, 2, 4, 14, 34, seed=401, row_h=4, blk_w=7, moss=True)
    _draw_stone_masonry_rect(wh, 48, 4, 14, 34, seed=402, row_h=4, blk_w=7, moss=True)
    # Green algae waterline stains on piers
    wh.rect(2, 31, 14, 7, "E0")
    wh.rect(48, 31, 14, 7, "E0")
    # Overhead stone arch span & battlements
    _draw_stone_masonry_rect(wh, 2, 4, 60, 14, seed=403, row_h=4, blk_w=8, moss=False)
    for mx in range(4, 58, 11):
        wh.rect(mx, 0, 8, 4, "C2")
        wh.line(mx, 0, mx + 7, 0, "C3")
    for px in range(14, 50):
        dx = (px - 32) / 18.0
        arch_y = int(24 - 10 * math.sqrt(max(0.0, 1.0 - dx * dx)))
        wh.rect(px, arch_y - 2, 1, 3, "C3" if px % 4 != 0 else "C0")
        wh.rect(px, arch_y + 1, 1, 3, (15, 20, 28, 125))
    # Iron water-boom teeth raised well above water passage
    for ix in range(18, 48, 5):
        wh.line(ix, 14, ix, 20, "S")
        wh.pset(ix, 20, "C3")
    wh.add_outline("S", selective_hue=True)
    wh.save_png(os.path.join(sprites_dir, "prop_watergate_arch_h.png"))

    # 12) prop_watergate_arch_v.png (40x64) - Vaulted Stone Canal Waterpoort Arch V
    wv = PixelCanvas(40, 64)
    _draw_stone_masonry_rect(wv, 2, 2, 36, 13, seed=411, row_h=4, blk_w=7, moss=True)
    _draw_stone_masonry_rect(wv, 2, 49, 36, 13, seed=412, row_h=4, blk_w=7, moss=True)
    wv.rect(2, 11, 36, 4, "E0")
    wv.rect(2, 49, 36, 4, "E0")
    _draw_stone_masonry_rect(wv, 8, 2, 24, 60, seed=413, row_h=5, blk_w=8, moss=False)
    wv.rect(13, 2, 14, 60, "C1")
    for sy in range(4, 58, 8):
        wv.rect(14, sy, 12, 6, "CS2")
        wv.line(14, sy, 25, sy, "C2")
    for my in range(4, 58, 12):
        wv.rect(6, my, 4, 8, "C2")
        wv.rect(30, my, 4, 8, "CS2")
    for iy in range(16, 49, 6):
        wv.line(4, iy, 8, iy, "C1")
        wv.line(32, iy, 36, iy, "C1")
    wv.add_outline("S", selective_hue=True)
    wv.save_png(os.path.join(sprites_dir, "prop_watergate_arch_v.png"))


def _make_wall_details(sprites_dir: str) -> None:
    # 13) prop_wall_banner.png (16x28) - Bruges / Church Scarlet-Gold Heraldic Wall Banner
    b = PixelCanvas(16, 28)
    # Crossbar rod + brass finials
    b.line(1, 3, 14, 3, "T2")
    b.line(2, 2, 13, 2, "T3")
    b.rect(0, 2, 2, 3, "Y2")
    b.rect(14, 2, 2, 3, "Y2")
    b.pset(0, 2, "Y3")
    b.pset(15, 2, "Y3")
    # Hanging scarlet wool banner with swallowtail split
    for py in range(4, 25):
        swallow = max(0, py - 19)
        for px in range(3, 13):
            if py >= 20 and abs(px - 7.5) < swallow * 0.85:
                continue
            shade = "I2" if (px == 4 or px == 11) else ("I0" if px >= 10 else "I1")
            b.pset(px, py, shade)
        # Gold trim border
        if py < 21:
            b.pset(3, py, "Y2")
            b.pset(12, py, "Y2")
    # Gold Heraldic Cross/Fleur emblem in center
    b.rect(7, 8, 2, 8, "Y2")
    b.rect(5, 11, 6, 2, "Y2")
    b.pset(7, 8, "Y3")
    b.pset(6, 11, "Y3")
    b.add_outline("K", selective_hue=True)
    b.save_png(os.path.join(sprites_dir, "prop_wall_banner.png"))

    # 14) prop_wall_brazier.png (18x22) - Wrought-Iron Wall Brazier with Glowing Coals & Flame
    br = PixelCanvas(18, 22)
    # Stand & iron basket
    br.rect(5, 17, 8, 3, "S")
    br.line(6, 17, 11, 17, "C1")
    br.line(7, 14, 6, 18, "C0")
    br.line(10, 14, 11, 18, "C0")
    br.rect(4, 10, 10, 5, "S")
    br.rect(5, 11, 8, 3, "C0")
    for ix in (5, 8, 11):
        br.line(ix, 9, ix, 14, "C2")
    # Glowing coal bed & sculpted flame
    br.rect(5, 8, 8, 3, "R1")
    br.rect(6, 8, 6, 2, "Y1")
    br.rect(7, 5, 4, 4, "Y2")
    br.rect(8, 3, 2, 3, "Y3")
    br.pset(9, 2, "L0")
    br.add_outline("S", selective_hue=True)
    br.save_png(os.path.join(sprites_dir, "prop_wall_brazier.png"))


def _paint_barge_cargo_v(c: PixelCanvas, ox: int, oy: int) -> None:
    # Covered grain/wool bales + wine cask + scarlet Flemish cloth bolt
    # Twin strapped wool bales
    c.rect(ox + 2, oy + 4, 18, 14, "T1")
    c.rect(ox + 3, oy + 5, 16, 11, "H2")
    c.line(ox + 3, oy + 5, ox + 18, oy + 5, "H3")
    for bx in (ox + 7, ox + 14):
        c.line(bx, oy + 4, bx, oy + 16, "T0")
    # Emerald & crimson rolled cloth bolts
    c.rect(ox + 2, oy + 22, 16, 8, "I1")
    c.line(ox + 3, oy + 23, ox + 16, oy + 23, "I2")
    c.rect(ox + 4, oy + 31, 15, 7, "E1")
    c.line(ox + 5, oy + 32, ox + 17, oy + 32, "E2")
    # Oak barrel
    c.rect(ox + 5, oy + 41, 12, 10, "T2")
    c.line(ox + 5, oy + 43, ox + 16, oy + 43, "C1")
    c.line(ox + 5, oy + 48, ox + 16, oy + 48, "C1")
    c.line(ox + 7, oy + 42, ox + 13, oy + 42, "T4")


def _paint_barge_cargo_h(c: PixelCanvas, ox: int, oy: int) -> None:
    c.rect(ox + 4, oy + 2, 15, 18, "T1")
    c.rect(ox + 5, oy + 3, 13, 15, "H2")
    c.line(ox + 5, oy + 3, ox + 17, oy + 3, "H3")
    for by in (oy + 8, oy + 14):
        c.line(ox + 4, by, ox + 18, by, "T0")
    c.rect(ox + 22, oy + 3, 12, 16, "I1")
    c.line(ox + 23, oy + 4, ox + 32, oy + 4, "I2")
    c.rect(ox + 35, oy + 4, 12, 15, "E1")
    c.line(ox + 36, oy + 5, ox + 45, oy + 5, "E2")
    c.rect(ox + 49, oy + 4, 10, 14, "T2")
    c.line(ox + 51, oy + 4, ox + 51, oy + 17, "C1")
    c.line(ox + 56, oy + 4, ox + 56, oy + 17, "C1")


def _make_canal_barges(sprites_dir: str) -> None:
    # 15 & 16) prop_canal_barge_v.png & _cargo.png (48x96)
    for with_cargo in (False, True):
        bv = PixelCanvas(48, 96)
        # Waterline foam collar
        for py in range(4, 92):
            taper = 0.0
            if py < 16:
                taper = ((16 - py) / 12.0) ** 1.4
            elif py > 79:
                taper = ((py - 79) / 12.0) ** 1.4
            hw = max(5, int(19 - taper * 12))
            bv.rect(24 - hw - 1, py, hw * 2 + 3, 1, (195, 225, 232, 110))
            bv.rect(24 - hw, py, hw * 2 + 1, 1, "T0")
            # Gunwale rim & interior slatted plank deck
            if hw >= 8:
                bv.rect(24 - hw + 2, py, hw * 2 - 3, 1, "T3")
                bv.rect(24 - hw + 4, py, hw * 2 - 7, 1, "T2" if py % 4 != 0 else "T1")
                # Vertical seam grain
                bv.pset(18, py, "T1")
                bv.pset(24, py, "T1")
                bv.pset(30, py, "T1")
        # Bow & Stern deck triangles + coiled hemp mooring line + brass cleats
        bv.rect(17, 10, 14, 7, "T3")
        bv.rect(17, 79, 14, 7, "T3")
        bv.circle(24, 14, 3, "H2")
        bv.circle(24, 14, 1, "T1")
        bv.line(24, 83, 24, 91, "T1")
        bv.pset(24, 83, "Y2")
        # Punting pole along port gunwale
        bv.line(10, 18, 10, 78, "H1")
        bv.line(10, 18, 10, 22, "C2")
        if with_cargo:
            _paint_barge_cargo_v(bv, 13, 21)
        bv.add_outline("K", selective_hue=True)
        fname = "prop_canal_barge_v_cargo.png" if with_cargo else "prop_canal_barge_v.png"
        bv.save_png(os.path.join(sprites_dir, fname))

    # 17 & 18) prop_canal_barge_h.png & _cargo.png (96x48)
    for with_cargo in (False, True):
        bh = PixelCanvas(96, 48)
        for px in range(4, 92):
            taper = 0.0
            if px < 16:
                taper = ((16 - px) / 12.0) ** 1.4
            elif px > 79:
                taper = ((px - 79) / 12.0) ** 1.4
            hh = max(5, int(19 - taper * 12))
            bh.rect(px, 24 - hh - 1, 1, hh * 2 + 3, (195, 225, 232, 110))
            bh.rect(px, 24 - hh, 1, hh * 2 + 1, "T0")
            if hh >= 8:
                bh.rect(px, 24 - hh + 2, 1, hh * 2 - 3, "T3")
                bh.rect(px, 24 - hh + 4, 1, hh * 2 - 7, "T2" if px % 5 != 0 else "T1")
                bh.pset(px, 18, "T1")
                bh.pset(px, 24, "T1")
                bh.pset(px, 30, "T1")
        bh.rect(10, 17, 7, 14, "T3")
        bh.rect(79, 17, 7, 14, "T3")
        bh.circle(14, 24, 3, "H2")
        bh.circle(14, 24, 1, "T1")
        bh.line(83, 24, 91, 24, "T1")
        bh.pset(83, 24, "Y2")
        bh.line(18, 10, 78, 10, "H1")
        bh.line(18, 10, 22, 10, "C2")
        if with_cargo:
            _paint_barge_cargo_h(bh, 18, 13)
        bh.add_outline("K", selective_hue=True)
        fname = "prop_canal_barge_h_cargo.png" if with_cargo else "prop_canal_barge_h.png"
        bh.save_png(os.path.join(sprites_dir, fname))


def _make_fountain_and_loaf(sprites_dir: str) -> None:
    # 19) prop_stone_fountain.png (72x72) - Grote Markt Octagonal Limestone Fountain
    f = PixelCanvas(72, 72)
    cx, cy = 36, 36
    # Wet shadow halo & stepped stone plinth ring
    f.ellipse(cx, cy + 2, 34, 33, (16, 20, 28, 120))
    f.ellipse(cx, cy + 1, 32, 31, "S")
    f.ellipse(cx, cy, 31, 30, "C0")
    f.ellipse(cx, cy - 1, 30, 29, "C2")
    # Gothic carved stone outer rim segments
    for py in range(6, 66):
        for px in range(6, 66):
            dx = px - cx
            dy = py - cy
            d_oct = max(abs(dx) * 0.92 + abs(dy) * 0.38, abs(dy) * 0.92 + abs(dx) * 0.38, math.hypot(dx, dy))
            if 24.0 <= d_oct <= 30.0:
                if dy < -10:
                    col = "C3" if ((px + py) % 5 != 0) else "C2"
                elif dy < 12:
                    col = "C2" if ((px // 6) % 2 == 0) else "CS2"
                else:
                    col = "C1" if ((px // 6) % 2 == 0) else "CS"
                if abs(d_oct - 24.5) < 0.8:
                    col = "C3" if dy > 0 else "C0"
                f.pset(px, py, col)
    # Deep shimmering Flemish canal-teal fountain water basin
    f.ellipse(cx, cy, 24, 23, "U0")
    f.ellipse(cx, cy - 1, 22, 21, "U1")
    f.ellipse(cx - 2, cy - 2, 16, 14, "U2")
    # Shimmering ripple crescents & scattered brass wish coins
    for rx, ry, rw in ((22, 26, 7), (43, 29, 6), (25, 46, 8), (44, 44, 6)):
        f.line(rx, ry, rx + rw, ry, "L0")
    for wx, wy in ((26, 39), (44, 41), (31, 47)):
        f.pset(wx, wy, "Y2")
    # Central Carved Gothic Pillar Pedestal + 4 Brass Spouts & Bronze Finial
    f.ellipse(cx, cy + 4, 8, 7, "U0")
    f.rect(cx - 5, cy - 10, 10, 16, "C1")
    f.rect(cx - 4, cy - 10, 5, 15, "C2")
    f.line(cx - 4, cy - 10, cx - 4, cy + 4, "C3")
    # Brass lion spouts at 4 sides
    for sx, sy in ((cx - 6, cy - 4), (cx + 5, cy - 4), (cx - 1, cy - 10), (cx - 1, cy + 3)):
        f.rect(sx, sy, 2, 2, "Y2")
        f.pset(sx, sy, "Y3")
    # Crowning upper stone basin & brass finial
    f.ellipse(cx, cy - 11, 7, 5, "C0")
    f.ellipse(cx, cy - 12, 7, 4, "C3")
    f.ellipse(cx, cy - 12, 4, 2, "U2")
    f.line(cx, cy - 17, cx, cy - 12, "Y2")
    f.pset(cx, cy - 18, "Y3")
    f.add_outline("S", selective_hue=True)
    f.save_png(os.path.join(sprites_dir, "prop_stone_fountain.png"))

    # 20) prop_bread_loaf.png (16x16) - Warm Golden Scored Flemish Rye/Wheat Boule
    bl = PixelCanvas(16, 16)
    bl.ellipse(8, 11, 6, 3, (18, 12, 10, 110))
    bl.ellipse(8, 9, 6, 4, "T0")
    bl.ellipse(8, 8, 5, 3, "R2")
    bl.ellipse(8, 7, 4, 2, "H1")
    # Baker's crust slashes & warm flour dusting
    bl.line(6, 6, 7, 8, "H3")
    bl.line(9, 6, 10, 8, "H3")
    bl.pset(7, 6, "L1")
    bl.pset(10, 6, "L1")
    bl.add_outline("K", selective_hue=True)
    bl.save_png(os.path.join(sprites_dir, "prop_bread_loaf.png"))


def make_bruges_forts_water(sprites_dir: str) -> None:
    _make_walls(sprites_dir)
    _make_bastions(sprites_dir)
    _make_gatehouses_and_watergates(sprites_dir)
    _make_wall_details(sprites_dir)
    _make_canal_barges(sprites_dir)
    _make_fountain_and_loaf(sprites_dir)
