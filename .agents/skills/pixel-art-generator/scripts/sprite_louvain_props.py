"""
Bespoke 15th-Century Louvain Gobertange Sandstone Ramparts, Diagonal Walls,
Dijle Waterpoort Arch, Movable Portcullis Gates, Medieval Ratchet Levers,
Dragon Drain Culvert Arches, Bell-Foundry Equipment, Clay Bank & Architecture.
"""

import math
import os
import random
from pixel_art_lib import PAL, PixelCanvas
from sprite_world_buildings import _draw_brick_wall, _draw_shingles
from sprite_bruges_landmarks import _draw_lancet_window, _draw_slate_spire


def _mirror_h(src: PixelCanvas) -> PixelCanvas:
    out = PixelCanvas(src.w, src.h)
    for y in range(src.h):
        for x in range(src.w):
            out.px[y * out.w + (src.w - 1 - x)] = list(src.px[y * src.w + x])
    return out


def _draw_gobertange_rect(c: PixelCanvas, x: int, y: int, w: int, h: int, seed: int = 13, moss: bool = False) -> None:
    """Warm beige-white Brabant Gobertange sandstone ashlar courses with mortar & subtle moss."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, "L2")
    for row, py in enumerate(range(y, y + h, 4)):
        off = 4 if (row % 2) else 0
        bh = min(3, y + h - py)
        for px in range(x + off, x + w, 8):
            bw = min(7, x + w - px)
            roll = rng.random()
            col = "L1" if roll < 0.56 else ("H2" if roll < 0.80 else "L0")
            c.rect(px, py, bw, bh, col)
        if py + 3 < y + h:
            c.line(x, py + 3, x + w - 1, py + 3, "C3")
        if off > 0 and x < x + off:
            c.rect(x, py, min(off - 1, w), bh, "L1")
    if moss:
        for _ in range(max(1, (w * h) // 90)):
            mx = x + rng.randint(1, max(1, w - 3))
            my = y + max(0, h - 5) + rng.randint(0, 3)
            if mx < x + w and my < y + h:
                c.pset(mx, my, "G0")


def _make_louvain_sandstone_walls(sprites_dir: str) -> None:
    # 1. prop_louvain_wall_h.png (32x36) — Beige-White Gobertange Curtain Wall + Red-Brick Belt Trim
    p = PixelCanvas(32, 36)
    p.rect(0, 33, 32, 3, (14, 15, 22, 105))
    for mx in (2, 18):
        p.rect(mx, 1, 12, 8, "C2")
        _draw_gobertange_rect(p, mx + 1, 2, 10, 6, seed=700 + mx, moss=False)
        p.line(mx + 1, 1, mx + 10, 1, "L0")
        p.line(mx, 9, mx + 11, 9, "C3")
    for gx in (0, 14, 30):
        gw = 2 if gx != 14 else 4
        p.rect(gx, 5, gw, 5, "C3")
        p.rect(gx, 6, gw, 3, "L2")
        p.line(gx, 6, gx + gw - 1, 6, "L0")
    # Sandstone wall-walk
    p.rect(0, 9, 32, 6, "C3")
    for sx in range(0, 32, 8):
        p.rect(sx, 10, 7, 4, "L1")
        p.line(sx, 10, sx + 6, 10, "L0")
    p.line(0, 9, 31, 9, "C2")
    p.line(0, 14, 31, 14, "C1")
    # Gobertange ashlar outer face + Leuven red-brick belt-course & arrow slits
    _draw_gobertange_rect(p, 0, 15, 32, 17, seed=411, moss=True)
    p.rect(0, 25, 32, 2, "R1")
    p.line(0, 27, 31, 27, "R0")
    for ax in (8, 24):
        p.rect(ax, 18, 2, 6, "K")
        p.line(ax - 1, 20, ax + 2, 20, "C2")
    p.rect(0, 31, 32, 3, "C2")
    p.line(0, 31, 31, 31, "H2")
    p.line(0, 33, 31, 33, "C0")
    p.save_png(os.path.join(sprites_dir, "prop_louvain_wall_h.png"))

    # 2. prop_louvain_wall_v.png (36x32) — Vertical Gobertange Curtain Wall
    v = PixelCanvas(36, 32)
    v.rect(0, 0, 2, 32, (14, 15, 22, 105))
    v.rect(34, 0, 2, 32, (14, 15, 22, 105))
    _draw_gobertange_rect(v, 2, 0, 8, 32, seed=422, moss=True)
    _draw_gobertange_rect(v, 26, 0, 8, 32, seed=423, moss=True)
    v.line(2, 0, 2, 31, "C1")
    v.line(33, 0, 33, 31, "C1")
    v.rect(11, 0, 14, 32, "C3")
    for sy in range(0, 32, 8):
        v.rect(12, sy, 12, 7, "L1")
        v.line(12, sy, 23, sy, "L0")
        v.line(12, sy + 6, 23, sy + 6, "L2")
    for my in (2, 18):
        v.rect(7, my, 5, 11, "C2")
        v.rect(8, my + 1, 3, 9, "L1")
        v.line(8, my + 1, 10, my + 1, "L0")
        v.rect(24, my, 5, 11, "C2")
        v.rect(25, my + 1, 3, 9, "L1")
        v.line(25, my + 1, 27, my + 1, "L0")
    v.line(10, 0, 10, 31, "C2")
    v.line(25, 0, 25, 31, "C2")
    v.save_png(os.path.join(sprites_dir, "prop_louvain_wall_v.png"))

    # 3. Seamless 36x36 Gobertange L-Corners (prop_louvain_wall_corner_nw/ne/sw/se.png)
    nw = PixelCanvas(36, 36)
    nw.rect(0, 2, 2, 34, (14, 15, 22, 105))
    nw.rect(25, 33, 11, 3, (14, 15, 22, 105))
    _draw_gobertange_rect(nw, 2, 10, 8, 26, seed=611, moss=True)
    nw.line(2, 10, 2, 35, "C1")
    _draw_gobertange_rect(nw, 25, 15, 11, 17, seed=612, moss=False)
    _draw_gobertange_rect(nw, 26, 20, 8, 16, seed=613, moss=True)
    nw.rect(25, 25, 11, 2, "R1")
    nw.rect(25, 31, 11, 3, "C2")
    nw.line(25, 33, 35, 33, "C0")
    nw.rect(11, 9, 25, 6, "C3")
    nw.rect(11, 9, 14, 27, "C3")
    nw.rect(12, 10, 24, 4, "L1")
    nw.rect(12, 10, 12, 26, "L1")
    for sx in (16, 24, 32):
        nw.line(sx, 10, sx, 13, "L2")
    for sy in (16, 24, 32):
        nw.line(12, sy, 23, sy, "L2")
    nw.line(12, 10, 35, 10, "L0")
    nw.line(12, 10, 12, 35, "L0")
    for mx, mw in ((4, 14), (22, 12)):
        nw.rect(mx, 1, mw, 8, "C2")
        _draw_gobertange_rect(nw, mx + 1, 2, mw - 2, 6, seed=620 + mx)
        nw.line(mx + 1, 1, mx + mw - 2, 1, "L0")
    nw.rect(7, 11, 5, 11, "C2")
    nw.rect(8, 12, 3, 9, "L1")
    nw.rect(7, 26, 5, 9, "C2")
    nw.rect(8, 27, 3, 7, "L1")
    nw.rect(24, 20, 5, 11, "C2")
    nw.rect(25, 21, 3, 9, "L1")
    nw.save_png(os.path.join(sprites_dir, "prop_louvain_wall_corner_nw.png"))
    _mirror_h(nw).save_png(os.path.join(sprites_dir, "prop_louvain_wall_corner_ne.png"))

    sw = PixelCanvas(36, 36)
    sw.rect(0, 0, 2, 35, (14, 15, 22, 105))
    sw.rect(1, 33, 35, 3, (14, 15, 22, 105))
    _draw_gobertange_rect(sw, 2, 0, 8, 32, seed=631, moss=True)
    _draw_gobertange_rect(sw, 9, 15, 27, 17, seed=632, moss=True)
    sw.rect(9, 25, 27, 2, "R1")
    sw.rect(2, 31, 34, 3, "C2")
    sw.line(2, 33, 35, 33, "C0")
    sw.line(2, 0, 2, 33, "C1")
    sw.rect(11, 0, 14, 15, "C3")
    sw.rect(11, 9, 25, 6, "C3")
    sw.rect(12, 0, 12, 14, "L1")
    sw.rect(12, 10, 24, 4, "L1")
    for sy in (0, 8):
        sw.line(12, sy, 23, sy, "L2")
    for sx in (18, 26, 34):
        sw.line(sx, 10, sx, 13, "L2")
    sw.line(12, 0, 12, 13, "L0")
    sw.line(12, 13, 35, 13, "L0")
    sw.rect(7, 2, 5, 11, "C2")
    sw.rect(8, 3, 3, 9, "L1")
    sw.rect(24, 1, 11, 8, "C2")
    _draw_gobertange_rect(sw, 25, 2, 9, 6, seed=635)
    sw.line(25, 1, 34, 1, "L0")
    sw.save_png(os.path.join(sprites_dir, "prop_louvain_wall_corner_sw.png"))
    _mirror_h(sw).save_png(os.path.join(sprites_dir, "prop_louvain_wall_corner_se.png"))

    # 4. Seamless 45-deg Diagonal Gobertange Sandstone Ramparts (48x48, tiled in (-16,+16) or (+16,+16) steps)
    #    Strict half-open along-axis mask (-16 <= (y - x) <= 15) + perpendicular band gives zero seams & zero overdraw!
    for is_south_wall, fname_left, fname_right in (
        (False, "prop_louvain_wall_diag_nw.png", "prop_louvain_wall_diag_ne.png"),
        (True,  "prop_louvain_wall_diag_sw.png", "prop_louvain_wall_diag_se.png"),
    ):
        diag = PixelCanvas(48, 48)
        for y in range(48):
            for x in range(48):
                # For NW (`/`): centerline x+y=47, step (-16,+16) leaves along=y-x in [-16, 15].
                # For SW (`\`): centerline y=x (y-x=0), step (+16,+16) leaves along=x+y-47 in [-16, 15].
                if not is_south_wall:
                    d_perp = (x + y) - 47    # <0 = outer meadow (NW), >0 = inner city (SE)
                    along = y - x
                else:
                    d_perp = y - x           # <0 = inner city (NE), >0 = outer meadow (SW)
                    along = (x + y) - 47
                if along < -16 or along > 15 or abs(d_perp) > 22:
                    continue

                a_mod = (along + 64) % 32
                block_idx = ((d_perp + 32) // 5 + (along + 64) // 10) % 5

                if not is_south_wall:
                    # NW (`/`): outer crenellation (-19..-11), walkway (-10..+2), inner Gobertange ashlar & shadow (+3..+20)
                    if d_perp < -19 or d_perp > 20:
                        continue
                    if d_perp in (-19, -18) and a_mod < 14:
                        col = "L0" if d_perp == -19 else "L1"
                    elif -17 <= d_perp <= -12:
                        if a_mod < 14:
                            col = "C2" if d_perp == -12 else ("H2" if block_idx == 0 else "L1")
                        else:
                            col = "C3" if d_perp <= -15 else "L2"
                    elif d_perp == -11:
                        col = "C2"
                    elif -10 <= d_perp <= 1:
                        if a_mod % 16 == 0:
                            col = "C3"
                        elif d_perp in (-10, 1):
                            col = "C2"
                        else:
                            col = "L1" if block_idx % 2 == 0 else "L2"
                    elif d_perp == 2:
                        col = "L0"
                    elif 3 <= d_perp <= 17:
                        if d_perp in (11, 12):
                            col = "R1" if a_mod % 6 != 0 else "R0"
                        elif 6 <= d_perp <= 10 and (a_mod in (15, 16)):
                            col = "K"
                        elif d_perp in (7, 15):
                            col = "C3"
                        else:
                            col = "H2" if block_idx == 1 else ("L0" if block_idx == 3 else "L1")
                        if d_perp == 17:
                            col = "C0"
                    else:
                        col = (14, 15, 22, 110)
                else:
                    # SW (`\`): inner walk curb (-19..-6), merlons (-5..+2), tall outer Gobertange wall & plinth (+3..+20)
                    if d_perp < -19 or d_perp > 21:
                        continue
                    if d_perp in (-19, -18):
                        col = "C2"
                    elif -17 <= d_perp <= -7:
                        col = "L1" if block_idx % 2 == 0 else "L2"
                        if a_mod % 16 == 0:
                            col = "C3"
                    elif -6 <= d_perp <= 2:
                        if a_mod < 15:
                            col = "L0" if d_perp == -6 else ("H2" if d_perp <= -2 else "L1")
                        else:
                            col = "C3" if d_perp <= -2 else "L2"
                    elif 3 <= d_perp <= 17:
                        if d_perp in (11, 12):
                            col = "R1" if a_mod % 6 != 0 else "R0"
                        elif 6 <= d_perp <= 10 and (a_mod in (15, 16)):
                            col = "K"
                        elif d_perp in (7, 15):
                            col = "C3"
                        else:
                            col = "H2" if block_idx == 1 else ("L0" if block_idx == 3 else "L1")
                        if d_perp == 17:
                            col = "C0"
                    else:
                        col = (14, 15, 22, 115)
                diag.pset(x, y, col)
        diag.save_png(os.path.join(sprites_dir, fname_left))
        _mirror_h(diag).save_png(os.path.join(sprites_dir, fname_right))


def _make_dijle_watergate_and_gates(sprites_dir: str) -> None:
    # 1. Vaulted Gobertange Dijle Waterpoort (112x68) — straddles Dijle 84px river channel cleanly
    wg = PixelCanvas(112, 68)
    for cx in (12, 100):
        wg.ellipse(cx, 62, 11, 3.0, (14, 16, 20, 105))
        _draw_gobertange_rect(wg, cx - 10, 20, 20, 42, seed=cx * 9, moss=True)
        wg.rect(cx - 10, 38, 20, 3, "R1")
        wg.rect(cx - 10, 56, 20, 6, "E0")
        wg.rect(cx - 1, 26, 2, 7, "K")
        _draw_slate_spire(wg, cx, 3, 11, 17)
        wg.line(cx, 1, cx, 4, "Y2")
    # Overhead vaulted limestone gallery spanning river (x=21..90)
    _draw_gobertange_rect(wg, 21, 18, 70, 19, seed=808, moss=False)
    wg.rect(21, 25, 70, 2, "R1")
    for mx in range(23, 88, 10):
        wg.rect(mx, 12, 7, 6, "L1")
        wg.line(mx, 12, mx + 6, 12, "L0")
    wg.line(21, 18, 90, 18, "L0")
    # Louvain Scarlet-White-Scarlet Keystone Heraldry centered above river arch
    wg.rect(52, 20, 8, 9, "I1")
    wg.rect(52, 23, 8, 3, "L0")
    wg.rect_outline(52, 20, 8, 9, "Y2")
    # Vaulted arch opening with water shadow & raised iron portcullis tines
    for px in range(22, 90):
        dx = (px - 56) / 34.0
        arch_y = int(48 - 13 * math.sqrt(max(0.0, 1.0 - dx * dx)))
        wg.rect(px, arch_y - 3, 1, 3, "L0" if px % 4 != 0 else "C3")
        wg.rect(px, arch_y, 1, 4, (14, 18, 26, 120))
    for ix in range(26, 87, 6):
        dx = (ix - 56) / 34.0
        arch_y = int(48 - 13 * math.sqrt(max(0.0, 1.0 - dx * dx)))
        wg.line(ix, arch_y, ix, arch_y + 7, "S")
        wg.pset(ix, arch_y + 7, "C3")
    wg.add_outline("K", selective_hue=True)
    wg.save_png(os.path.join(sprites_dir, "prop_louvain_watergate.png"))

    # 2. Louvain Gobertange Abbey Gate Piers (`prop_louvain_gate_pier_h.png` 48x64 & `_v.png` 64x48)
    ph = PixelCanvas(48, 64)
    ph.ellipse(24, 59, 20, 4, (14, 15, 22, 115))
    _draw_gobertange_rect(ph, 6, 18, 36, 42, seed=901, moss=True)
    ph.rect(6, 36, 36, 3, "R1")
    for qy in range(20, 58, 6):
        ph.rect(6, qy, 4, 4, "L0")
        ph.rect(38, qy, 4, 4, "H2")
    ph.rect(23, 28, 2, 7, "K")
    ph.rect(22, 43, 4, 4, "S")
    ph.rect(23, 40, 2, 4, "R2")
    ph.pset(23, 39, "Y3")
    ph.rect(4, 12, 40, 6, "L1")
    ph.line(4, 12, 43, 12, "L0")
    for mx in (4, 18, 32):
        ph.rect(mx, 7, 10, 6, "L1")
        ph.line(mx, 7, mx + 9, 7, "L0")
    _draw_slate_spire(ph, 24, 2, 14, 7)
    ph.add_outline("K", selective_hue=True)
    ph.save_png(os.path.join(sprites_dir, "prop_louvain_gate_pier_h.png"))

    pv = PixelCanvas(64, 48)
    pv.ellipse(32, 43, 28, 4, (14, 15, 22, 115))
    _draw_gobertange_rect(pv, 6, 12, 52, 32, seed=911, moss=True)
    pv.rect(6, 30, 52, 3, "R1")
    pv.rect(18, 20, 2, 8, "K")
    pv.rect(44, 20, 2, 8, "K")
    pv.rect(4, 8, 56, 5, "L1")
    pv.line(4, 8, 59, 8, "L0")
    for mx in range(6, 54, 12):
        pv.rect(mx, 3, 9, 5, "L1")
        pv.line(mx, 3, mx + 8, 3, "L0")
    pv.add_outline("K", selective_hue=True)
    pv.save_png(os.path.join(sprites_dir, "prop_louvain_gate_pier_v.png"))

    # 3. Movable Forged-Iron Portcullis Gates (`prop_portcullis_h.png` 84x36 & `_v.png` 52x64)
    gh = PixelCanvas(84, 36)
    gh.rect(2, 2, 80, 32, (16, 18, 22, 155))
    for rx in range(6, 80, 12):
        gh.rect(rx, 2, 4, 30, "S")
        gh.line(rx + 1, 2, rx + 1, 31, "C2")
        gh.pset(rx + 2, 32, "C3")
        gh.rect(rx + 1, 32, 2, 3, "C1")
    for cy in (8, 20, 28):
        gh.rect(2, cy, 80, 4, "C0")
        gh.line(2, cy, 81, cy, "C2")
        for rx in range(7, 80, 12):
            gh.pset(rx + 1, cy + 1, "Y1")
    gh.add_outline("K", selective_hue=True)
    gh.save_png(os.path.join(sprites_dir, "prop_portcullis_h.png"))

    gv = PixelCanvas(52, 64)
    gv.rect(3, 1, 46, 60, (16, 18, 22, 150))
    for bx in range(7, 46, 9):
        gv.rect(bx, 1, 4, 58, "S")
        gv.line(bx + 1, 1, bx + 1, 58, "C2")
        gv.rect(bx + 1, 59, 2, 4, "C3")
    for cy in (12, 30, 48):
        gv.rect(3, cy, 46, 5, "C0")
        gv.line(3, cy, 48, cy, "C3")
        for bx in range(8, 46, 9):
            gv.pset(bx + 1, cy + 2, "Y1")
    gv.add_outline("K", selective_hue=True)
    gv.save_png(os.path.join(sprites_dir, "prop_portcullis_v.png"))

    # 4. Medieval Stone-Bolted Ratchet Windlass Levers (28x28 — zero modern orbs!)
    for pulled, fname in ((False, "prop_medieval_lever_idle.png"), (True, "prop_medieval_lever_pulled.png")):
        lv = PixelCanvas(28, 28)
        lv.ellipse(14, 24, 9, 2.5, (14, 15, 22, 100))
        # Cut stone anchor plinth & iron bracket housing
        lv.rect(6, 16, 16, 8, "C1")
        lv.rect(7, 17, 14, 6, "L2")
        lv.line(7, 17, 20, 17, "L0")
        # Central toothed iron ratchet wheel + brass pawl pin
        lv.circle(14, 16, 5, "S")
        lv.circle(14, 16, 3, "C1")
        for px, py in ((9, 16), (19, 16), (14, 11), (14, 21)):
            lv.pset(px, py, "C3")
        lv.pset(17, 13, "Y2")
        # Heavy oak beam crank handle & forged iron ring grip
        tip_x = 5 if pulled else 23
        tip_y = 7
        lv.line(14, 16, tip_x, tip_y, "T0", 3)
        lv.line(14, 15, tip_x, tip_y, "T3")
        lv.circle(tip_x, tip_y, 2, "C2")
        lv.pset(tip_x, tip_y - 1, "Y1")
        lv.add_outline("K", selective_hue=True)
        lv.save_png(os.path.join(sprites_dir, fname))


def _make_culvert_and_foundry_props(sprites_dir: str) -> None:
    # 1. Queue 14 Completed: Vaulted Dragon Drain Grate (`prop_dragon_vent_grate.png` 22x18) & Stone Culvert Tunnels
    vg = PixelCanvas(22, 18)
    vg.rect(1, 2, 20, 14, "C1")
    vg.rect(2, 3, 18, 12, "L2")
    vg.rect(4, 5, 14, 9, "K")
    for bx in (6, 10, 14):
        vg.rect(bx, 5, 2, 9, "S")
        vg.line(bx, 5, bx, 13, "C2")
    vg.rect(3, 3, 16, 2, "L0")
    vg.rect(3, 14, 16, 2, "G0")
    vg.add_outline("K", selective_hue=True)
    vg.save_png(os.path.join(sprites_dir, "prop_dragon_vent_grate.png"))

    # Horizontal under-wall culvert stone portal (Brabant Fens weir culvert, 72x36)
    ch = PixelCanvas(72, 36)
    ch.ellipse(14, 30, 12, 3.0, (14, 22, 18, 95))
    ch.ellipse(58, 30, 12, 3.0, (14, 22, 18, 95))
    ch.rect(10, 8, 52, 20, "C0")
    ch.rect(12, 10, 48, 16, "CS")
    # Dark vaulted culvert channel across top under parapet arch stones
    ch.rect(12, 14, 48, 10, "K")
    for ax in (6, 54):
        ch.rect(ax, 6, 12, 24, "C1")
        ch.rect(ax + 1, 7, 10, 22, "C2")
        ch.line(ax + 1, 7, ax + 10, 7, "C3")
        ch.rect(ax + 2, 12, 8, 12, "K")
        for gx in range(ax + 3, ax + 10, 3):
            ch.line(gx, 12, gx, 23, "C2")
        ch.rect(ax + 1, 24, 10, 4, "E0")
    ch.rect(18, 9, 36, 4, "C2")
    ch.line(18, 9, 53, 9, "C3")
    ch.add_outline("K", selective_hue=True)
    ch.save_png(os.path.join(sprites_dir, "prop_culvert_tunnel_h.png"))

    # Vertical Gobertange stone Abbey drain culvert (Louvain Cloister south wall, 40x42)
    cv = PixelCanvas(40, 42)
    _draw_gobertange_rect(cv, 4, 2, 32, 38, seed=721, moss=True)
    cv.rect(11, 20, 18, 18, "K")
    cv.rect(11, 4, 18, 14, "K")
    for gx in (14, 19, 24):
        cv.rect(gx, 20, 2, 17, "S")
        cv.line(gx, 20, gx, 36, "C2")
        cv.rect(gx, 4, 2, 13, "S")
    cv.rect(9, 17, 22, 3, "L0")
    cv.rect(10, 37, 20, 4, "G0")
    cv.add_outline("K", selective_hue=True)
    cv.save_png(os.path.join(sprites_dir, "prop_culvert_tunnel_v.png"))

    # 2. Queue 14 Completed: Louvain Bell-Foundry Casting Pit (`prop_bell_mould.png` & `_fixed.png` 36x32)
    for is_fixed, fname in ((False, "prop_bell_mould.png"), (True, "prop_bell_mould_fixed.png")):
        bm = PixelCanvas(36, 32)
        bm.ellipse(18, 24, 15, 7, "C0")
        bm.ellipse(18, 23, 14, 6, "R1")
        bm.ellipse(18, 22, 11, 4.5, "K")
        # Fluted loam & terracotta bell cope silhouette rising from casting pit
        for py in range(8, 24):
            frac = (py - 8) / 16.0
            hw = int(4 + frac * 6.5)
            col = "H1" if py % 2 == 0 else ("T2" if is_fixed else "T1")
            bm.rect(18 - hw, py, hw * 2, 1, col)
            bm.line(18 - hw, py, 18 - hw + 2, py, "L1" if is_fixed else "T2")
        # Crown lifting lugs
        bm.rect(15, 5, 6, 3, "Y1" if is_fixed else "C2")
        bm.pset(18, 5, "Y3" if is_fixed else "C3")
        if is_fixed:
            # Wet grey Dijle clay seal band + bright bronze gleam
            bm.line(13, 14, 22, 18, "SG2", 2)
            bm.ellipse(30, 24, 4, 3, "Y1")
            bm.pset(30, 23, "Y3")
        else:
            # Jagged fracture crack across terracotta loam casing
            bm.line(15, 11, 19, 16, "K")
            bm.line(19, 16, 16, 21, "K")
            bm.pset(16, 12, "R3")
        bm.add_outline("K", selective_hue=True)
        bm.save_png(os.path.join(sprites_dir, fname))

    # 3. Foundry Timber Gantry Crane & Pulley Wheel (`prop_foundry_gantry.png` 38x42 — replaces Bruges grapple pole!)
    fg = PixelCanvas(38, 42)
    fg.ellipse(19, 38, 15, 3, (14, 15, 22, 100))
    # Heavy A-frame oak trestle posts & cross sill
    fg.line(7, 37, 13, 7, "T0", 3)
    fg.line(8, 37, 13, 8, "T2")
    fg.line(30, 37, 24, 7, "T0", 3)
    fg.line(29, 37, 24, 8, "T2")
    fg.rect(6, 5, 26, 4, "T1")
    fg.line(6, 5, 31, 5, "T3")
    # Spoked wooden capstan wheel on right post + iron lifting chain & pulley sheave center
    fg.circle(28, 22, 5, "T0")
    fg.circle(28, 22, 4, "T2")
    fg.circle(28, 22, 2, "Y1")
    fg.line(19, 9, 19, 25, "C2")
    fg.line(19, 9, 27, 19, "H1")
    fg.rect(16, 10, 6, 4, "Y0")
    fg.rect(17, 25, 4, 5, "C3")
    fg.pset(18, 29, "Y2")
    fg.add_outline("K", selective_hue=True)
    fg.save_png(os.path.join(sprites_dir, "prop_foundry_gantry.png"))

    # 4. Dijle River Clay Deposit Bank (`prop_clay_bank.png` 32x28) & Clay Inventory Icon (`icon_clay.png` 16x16)
    cb = PixelCanvas(32, 28)
    cb.ellipse(16, 20, 13, 6, (18, 28, 26, 120))
    cb.ellipse(15, 17, 11, 6, "SG0")
    cb.ellipse(14, 15, 9, 5, "SG1")
    cb.ellipse(12, 13, 5, 3, "SG2")
    cb.pset(10, 12, "SG3")
    # Wooden river spade leaning into wet clay + wicker basket
    cb.line(21, 5, 16, 15, "T2", 2)
    cb.rect(14, 14, 4, 3, "C2")
    cb.ellipse(24, 19, 4, 3, "H0")
    cb.ellipse(24, 18, 3, 2, "SG2")
    cb.add_outline("K", selective_hue=True)
    cb.save_png(os.path.join(sprites_dir, "prop_clay_bank.png"))

    ic = PixelCanvas(16, 16)
    ic.ellipse(8, 10, 5.5, 4.0, "SG0")
    ic.ellipse(8, 9, 4.5, 3.2, "SG1")
    ic.ellipse(7, 8, 2.5, 1.8, "SG2")
    ic.pset(6, 7, "SG3")
    ic.pset(11, 10, "W3")
    ic.add_outline("K", selective_hue=True)
    ic.save_png(os.path.join(sprites_dir, "icon_clay.png"))

    # 5. Queue 14 Completed: Chained Abbey Scriptorium Archive Desk (`prop_archive_desk.png` 42x30)
    ad = PixelCanvas(42, 30)
    ad.ellipse(21, 26, 18, 3, (14, 15, 22, 110))
    ad.rect(5, 13, 32, 14, "T0")
    ad.rect(6, 5, 30, 12, "T2")
    ad.line(6, 5, 35, 5, "T4")
    # Draped crimson Abbey runner + open illuminated parchment charter + wax seal + iron chain link
    ad.rect(17, 16, 8, 11, "I1")
    ad.rect(8, 6, 12, 9, "L0")
    ad.rect(22, 6, 12, 9, "L1")
    ad.line(20, 6, 20, 14, "T0")
    for ly in (8, 10, 12):
        ad.line(10, ly, 17, ly, "C0")
        ad.line(24, ly, 31, ly, "C0")
    ad.circle(29, 13, 2, "I2")
    ad.line(35, 10, 39, 16, "C2")
    ad.add_outline("K", selective_hue=True)
    ad.save_png(os.path.join(sprites_dir, "prop_archive_desk.png"))

    # 6. Vismarkt Gobertange Ashlar Stone Crate (`prop_gobertange_crate.png` 32x24) & Inventory Icons
    gc = PixelCanvas(32, 24)
    gc.ellipse(16, 20, 13, 3, (14, 15, 22, 110))
    gc.rect(4, 12, 24, 9, "T0")
    gc.rect(5, 13, 22, 7, "T2")
    gc.line(5, 13, 26, 13, "T4")
    _draw_gobertange_rect(gc, 6, 4, 20, 9, seed=1442)
    gc.rect(10, 4, 2, 16, "H1")
    gc.rect(20, 4, 2, 16, "H1")
    gc.line(6, 4, 25, 4, "L0")
    gc.add_outline("K", selective_hue=True)
    gc.save_png(os.path.join(sprites_dir, "prop_gobertange_crate.png"))

    im = PixelCanvas(16, 16)
    _draw_gobertange_rect(im, 3, 4, 10, 8, seed=71)
    im.line(6, 4, 6, 12, "H1")
    im.line(10, 4, 10, 12, "H1")
    im.add_outline("K", selective_hue=True)
    im.save_png(os.path.join(sprites_dir, "icon_mason_stone.png"))

    ip = PixelCanvas(16, 16)
    ip.rect(5, 3, 6, 3, "T2")
    ip.line(8, 6, 8, 11, "H1")
    ip.rect(6, 11, 5, 3, "Y2")
    ip.pset(8, 13, "Y1")
    ip.add_outline("K", selective_hue=True)
    ip.save_png(os.path.join(sprites_dir, "icon_plumb_signet.png"))


def _make_louvain_buildings(sprites_dir: str) -> None:
    # 1. bldg_louvain_abbey.png (112x112) — Brabant Gobertange & Speklagen Abbey Church
    ab = PixelCanvas(112, 112)
    ab.ellipse(56, 106, 50, 5.0, (14, 12, 18, 125))
    _draw_shingles(ab, 16, 30, 80, 26, "S", "CS", "C2")
    ab.line(16, 30, 95, 30, "L1")
    _draw_gobertange_rect(ab, 12, 52, 88, 54, seed=1401, moss=True)
    for sy in range(56, 102, 8):
        ab.rect(12, sy, 88, 2, "R1")
    # Tall central Gobertange stone gable + slender slate bellcote
    _draw_gobertange_rect(ab, 36, 26, 40, 28, seed=1402)
    _draw_slate_spire(ab, 56, 2, 10, 22)
    ab.line(56, 0, 56, 4, "Y2")
    ab.line(54, 2, 58, 2, "Y2")
    # Stepped buttresses + stained rose & gothic lancets + oak portals
    for bx in (12, 34, 74, 96):
        ab.rect(bx, 50, 4, 56, "H2")
    ab.ellipse(56, 48, 8, 8, "C2")
    ab.ellipse(56, 48, 6, 6, "U1")
    ab.pset(56, 48, "Y2")
    for lx in (20, 27, 80, 87):
        _draw_lancet_window(ab, lx, 62, 5, 16, "Y1", True)
    ab.rect(45, 76, 22, 30, "C2")
    ab.rect(47, 78, 18, 28, "T0")
    ab.rect(49, 80, 14, 26, "T2")
    ab.line(56, 80, 56, 105, "T0")
    ab.add_outline("K", selective_hue=True)
    ab.refine_epx_architecture().save_png(os.path.join(sprites_dir, "bldg_louvain_abbey.png"))

    # 2. bldg_louvain_foundry.png (88x76) — Historic Bell-Foundry Workshop behind Casting Pit
    fn = PixelCanvas(88, 76)
    fn.ellipse(44, 70, 39, 4.5, (14, 12, 18, 120))
    _draw_shingles(fn, 6, 16, 76, 22, "R0", "R1", "R2")
    fn.line(6, 16, 81, 16, "R3")
    # Speklagen brick & sandstone furnace workshop walls + wide louver chimney
    _draw_brick_wall(fn, 8, 34, 72, 36, "R0", "R1", "R2")
    for sy in (38, 46, 54, 62):
        fn.rect(8, sy, 72, 3, "L1")
    _draw_brick_wall(fn, 58, 4, 12, 16, "R0", "R1", "R2")
    fn.rect(57, 4, 14, 3, "L0")
    # Open glowing furnace bay & hanging bronze bell guild emblem
    fn.rect(32, 48, 22, 22, "T0")
    fn.rect(35, 51, 16, 19, "K")
    fn.ellipse(43, 63, 6, 5, "R2")
    fn.ellipse(43, 64, 4, 3, "Y2")
    fn.rect(15, 44, 11, 10, "T0")
    fn.rect(16, 45, 9, 8, "Y1")
    # Hanging gilded bell sign on left wall
    fn.rect(24, 38, 5, 5, "Y2")
    fn.rect(23, 42, 7, 2, "Y0")
    fn.add_outline("K", selective_hue=True)
    fn.save_png(os.path.join(sprites_dir, "bldg_louvain_foundry.png"))


def make_louvain_props_and_walls(sprites_dir: str) -> None:
    _make_louvain_sandstone_walls(sprites_dir)
    _make_dijle_watergate_and_gates(sprites_dir)
    _make_culvert_and_foundry_props(sprites_dir)
    _make_louvain_buildings(sprites_dir)
