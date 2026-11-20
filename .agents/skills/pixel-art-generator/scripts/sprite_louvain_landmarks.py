"""
Historical 15th-Century Louvain Tiles, Monumental Landmarks, Circular Ring Gatehouses,
and Dijle Harbor / Scaffold / Dyers' Props for Wings of the Brotherhood.

Palette-locked to pixel_art_lib.PAL for crisp nearest-neighbor 3/4 top-down rendering:
  - tile_sandstone_flag.png / _2.png, tile_louvain_cobble.png / _2.png, tile_red_brick_path.png
  - bldg_louvain_stadhuis.png     (112x96)  Brabant Gothic Town Hall + pinnacle turrets
  - bldg_louvain_st_peters.png    (128x116) St. Peter's Church + unfinished stubby towers & scaffold crane
  - bldg_louvain_lakenhalle.png   (120x88)  Grand Cloth Hall stone arcade + 1425 University upper hall
  - prop_louvain_poort_h.png      (84x62)   Twin-turret horizontal city gatehouse (Naamsepoort / Mechelsepoort)
  - prop_louvain_poort_v.png      (58x78)   Side 3/4 fortified gatehouse (Brusselsepoort / Tiensepoort)
  - prop_louvain_wall_tower.png   (44x52)   Circular ring-wall stone bastion tower
  - prop_lime_tree.png            (36x46)   European urban courtyard linden tree
  - prop_dye_vat_red.png / _blue  (24x22)   Dijle Dyers' Quarter madder & woad dye vats
  - prop_wine_cask_cart.png       (44x30)   Vismarkt merchant wine-cask handcart
  - prop_mason_yard.png           (48x32)   Sint-Pieterskerk dressed quarry stones, poles & rope coils
"""

import os
import random
from pixel_art_lib import PAL, PixelCanvas
from sprite_world_buildings import _draw_brick_wall, _draw_shingles
from sprite_bruges_landmarks import _draw_lancet_window, _draw_slate_spire
from sprite_bruges_forts_water import _draw_stone_masonry_rect
from sprite_louvain_props import make_louvain_props_and_walls


def _draw_sandstone_wall(c: PixelCanvas, x: int, y: int, w: int, h: int, seed: int = 13):
    """Warm Gobertange Brabant sandy limestone ashlar courses (L1/L2/H2/C2/C3)."""
    rng = random.Random(seed)
    c.rect(x, y, w, h, "L2")
    for row, py in enumerate(range(y, y + h, 4)):
        off = 4 if (row % 2) else 0
        bh = min(3, y + h - py)
        for px in range(x + off, x + w, 8):
            bw = min(7, x + w - px)
            roll = rng.random()
            col = "L1" if roll < 0.58 else ("H2" if roll < 0.82 else "L0")
            c.rect(px, py, bw, bh, col)
        if py + 3 < y + h:
            c.line(x, py + 3, x + w - 1, py + 3, "C3")
    for qy in range(y + 1, y + h - 4, 6):
        qw = 3 if ((qy // 6) % 2 == 0) else 2
        c.rect(x, qy, qw, 4, "H2")
        c.rect(x + w - qw, qy, qw, 4, "H2")


def _draw_pinnacle_turret(c: PixelCanvas, cx: int, y_base: int, body_h: int, spire_h: int, w: int = 6):
    """Draw a slender Brabant Gothic sandstone turret crowned with golden finial."""
    hw = w // 2
    _draw_sandstone_wall(c, cx - hw, y_base - body_h, w, body_h, cx * 7)
    c.line(cx - hw, y_base - body_h, cx - hw, y_base - 1, "C1")
    c.line(cx + hw - 1, y_base - body_h, cx + hw - 1, y_base - 1, "L0")
    # Slit window & stone collar
    c.rect(cx - 1, y_base - body_h + 3, 2, max(3, body_h - 6), "Y1")
    c.rect(cx - hw - 1, y_base - body_h - 2, w + 2, 2, "L0")
    _draw_slate_spire(c, cx, y_base - body_h - 2 - spire_h, hw + 1, spire_h)
    c.line(cx, y_base - body_h - 4 - spire_h, cx, y_base - body_h - 2 - spire_h, "Y2")
    c.pset(cx - 1, y_base - body_h - 4 - spire_h, "Y1")


def make_louvain_tiles(sprites_dir: str) -> None:
    # 1. Warm Buff Brabant Sandstone Plaza Flagstones (soft serene Gobertange limestone, low contrast)
    for var in (0, 1):
        c = PixelCanvas(16, 16, PAL["C2"])
        stones = [
            (0, 0, 7, 7, "L2", "L1"), (8, 0, 8, 7, "L1", "L0"),
            (0, 8, 8, 8, "L1", "L0"), (9, 8, 7, 8, "L2", "L1"),
        ]
        if var == 1:
            stones = [
                (0, 0, 9, 6, "L2", "L1"), (10, 0, 6, 6, "L1", "L0"),
                (0, 7, 6, 9, "L1", "L0"), (7, 7, 9, 9, "L2", "L1"),
            ]
        for sx, sy, sw, sh, base, hi in stones:
            c.rect(sx, sy, sw, sh, base)
            c.line(sx, sy, sx + sw - 2, sy, hi)
            c.line(sx, sy, sx, sy + sh - 2, hi)
        c.pset(6, 6, "C3")
        c.pset(14 if var == 0 else 11, 13, "H2")
        fname = "tile_sandstone_flag.png" if var == 0 else "tile_sandstone_flag_2.png"
        c.save_png(os.path.join(sprites_dir, fname))

    # 2. Warm Earthy Flemish Town Cobbles (subdued warm slate-umber mortar, rounded stones)
    for var in (0, 1):
        c = PixelCanvas(16, 16, PAL["C0"])
        stones = [
            (0, 0, 7, 5, "C2", "C3"), (8, 0, 7, 4, "C2", "L2"),
            (1, 6, 5, 4, "C2", "L2"), (7, 5, 8, 5, "C1", "C3"),
            (0, 11, 8, 4, "C2", "C3"), (9, 11, 6, 4, "C1", "C2"),
        ]
        if var == 1:
            stones[1] = (8, 0, 7, 4, "C1", "C2")
            stones[3] = (7, 5, 8, 5, "C2", "L2")
        for sx, sy, sw, sh, base, hi in stones:
            for py in range(sy, sy + sh):
                for px in range(sx, sx + sw):
                    if (px in (sx, sx + sw - 1)) and (py in (sy, sy + sh - 1)):
                        continue
                    c.pset(px, py, base)
            c.line(sx + 1, sy, sx + sw - 2, sy, hi)
            c.line(sx, sy + 1, sx, sy + sh - 2, hi)
        c.pset(6 if var == 0 else 0, 5 if var == 0 else 10, "T1")
        c.pset(14 if var == 0 else 8, 10 if var == 0 else 4, "T1")
        fname = "tile_louvain_cobble.png" if var == 0 else "tile_louvain_cobble_2.png"
        c.save_png(os.path.join(sprites_dir, fname))

    # 3. Terracotta Herringbone Brick Path (soft muted warm brick & subtle mortar)
    b = PixelCanvas(16, 16, PAL["C1"])
    for y in range(16):
        for x in range(16):
            blk = ((x // 4) + (y // 4)) % 2
            bx = x % 4
            by = y % 4
            if (blk == 0 and by == 3) or (blk == 1 and bx == 3):
                b.pset(x, y, "T1")
            else:
                col = "R2" if ((x + y * 3) % 5 == 0) else ("R3" if (x % 3 == 0 and y % 2 == 0) else "R1")
                b.pset(x, y, col)
    b.save_png(os.path.join(sprites_dir, "tile_red_brick_path.png"))


def make_bldg_louvain_stadhuis(sprites_dir: str) -> None:
    """112x96 Het Stadhuis (Brabant Gothic Town Hall with carved niches & corner pinnacles)."""
    c = PixelCanvas(112, 96)
    c.ellipse(56, 91, 50, 4.5, (14, 12, 18, 120))

    # Steep Brabant slate roof & two tiers of dormer windows
    _draw_shingles(c, 16, 18, 80, 26, "N", "S", "CS")
    c.line(16, 18, 95, 18, "L1")
    for rx in range(24, 90, 14):
        c.rect(rx - 2, 23, 5, 5, "C1")
        c.rect(rx - 1, 24, 3, 3, "Y1")
        c.rect(rx + 2, 33, 5, 5, "C1")
        c.rect(rx + 3, 34, 3, 3, "Y2")

    # Ornate sandstone Gothic facade (3 tiers of blind traceries & gilded corbels)
    _draw_sandstone_wall(c, 14, 42, 84, 49, seed=1445)
    c.rect(14, 83, 84, 8, "C1")
    for bx in range(16, 96, 8):
        c.rect(bx, 84, 6, 5, "C2")
    # Roof balustrade gallery with stone pinnacles
    c.rect(13, 40, 86, 4, "L1")
    for px in range(16, 96, 7):
        c.rect(px, 37, 3, 4, "L0")
        c.pset(px + 1, 36, "Y2")

    # Tall pointed Gothic council windows & gold statue corbel piers
    for wx in range(20, 90, 10):
        c.rect(wx - 2, 46, 2, 34, "H2")
        c.pset(wx - 1, 52, "Y2")
        c.pset(wx - 1, 66, "Y2")
        _draw_lancet_window(c, wx + 1, 47, 5, 11, "Y1", True)
        _draw_lancet_window(c, wx + 1, 61, 5, 11, "Y2", True)

    # Grand Peron Council Stairs + Pointed Arched Doorway + Louvain Red-White-Red Banners
    c.rect(44, 73, 24, 18, "C2")
    c.rect(47, 74, 18, 17, "C0")
    c.rect(49, 76, 14, 15, "T1")
    c.line(56, 76, 56, 90, "T0")
    c.rect(42, 88, 28, 3, "L1")
    for bx in (38, 69):
        c.rect(bx, 73, 4, 13, "I1")
        c.rect(bx, 78, 4, 3, "L0")
        c.line(bx, 73, bx + 3, 73, "Y2")

    # 4 corner pinnacled turrets + central stepped rooftop gables flanking the slate roof!
    _draw_sandstone_wall(c, 14, 24, 14, 20, seed=19)
    _draw_sandstone_wall(c, 84, 24, 14, 20, seed=23)
    _draw_pinnacle_turret(c, 12, 90, 62, 16, 8)
    _draw_pinnacle_turret(c, 100, 90, 62, 16, 8)
    _draw_pinnacle_turret(c, 22, 42, 24, 14, 6)
    _draw_pinnacle_turret(c, 90, 42, 24, 14, 6)
    # Central ornate fleche spirelet
    _draw_slate_spire(c, 56, 4, 5, 14)
    c.line(56, 1, 56, 5, "Y2")
    c.pset(55, 2, "Y1")

    c.add_outline("K", selective_hue=True)
    c.refine_epx_architecture().save_png(os.path.join(sprites_dir, "bldg_louvain_stadhuis.png"))


def _paint_st_peters_base(c: PixelCanvas, y_off: int, with_scaffold_jib: bool = True) -> None:
    """Shared St. Peter's Choir, Brabant Ashlar Nave, Triple Westwork, and Scaffolding."""
    c.ellipse(64, 110 + y_off, 56, 5.0, (14, 12, 18, 125))
    _draw_shingles(c, 20, 42 + y_off, 88, 22, "N", "S", "CS")
    c.line(20, 42 + y_off, 107, 42 + y_off, "L1")
    _draw_sandstone_wall(c, 12, 62 + y_off, 104, 48, seed=1425)
    c.rect(12, 101 + y_off, 104, 9, "C1")

    towers = [(14, 32 + y_off, 28), (44, 24 + y_off, 40), (86, 32 + y_off, 28)]
    for idx, (tx, ty, tw) in enumerate(towers):
        _draw_sandstone_wall(c, tx, ty, tw, (108 + y_off) - ty, seed=400 + idx)
        c.rect(tx, ty, 3, (108 + y_off) - ty, "H2")
        c.rect(tx + tw - 3, ty, 3, (108 + y_off) - ty, "C2")
        if with_scaffold_jib or idx != 1:
            for rx in range(tx, tx + tw - 2, 4):
                rh = 2 + ((rx + idx * 3) % 4)
                c.rect(rx, ty - rh, 3, rh, "L2" if (rx % 8 == 0) else "H2")
        _draw_lancet_window(c, tx + tw // 2 - 4, ty + 10, 8, 16, "S", False)
        if idx == 1:
            c.ellipse(64, 58 + y_off, 8, 8, "C1")
            c.ellipse(64, 58 + y_off, 6, 6, "Y0")
            c.pset(64, 58 + y_off, "Y2")

    c.rect(52, 78 + y_off, 24, 32, "C1")
    c.rect(54, 80 + y_off, 20, 30, "C0")
    c.rect(56, 82 + y_off, 16, 28, "T0")
    c.rect(58, 84 + y_off, 12, 26, "T2")
    c.line(64, 84 + y_off, 64, 109 + y_off, "T0")
    for lx in (22, 31, 90, 99):
        _draw_lancet_window(c, lx, 74 + y_off, 5, 16, "Y1", True)

    if with_scaffold_jib:
        for sx in (15, 29, 43, 56, 72, 85, 100):
            c.line(sx, 20 + y_off, sx, 107 + y_off, "T2")
            c.line(sx + 1, 20 + y_off, sx + 1, 107 + y_off, "T3")
        for sy in (34 + y_off, 48 + y_off, 64 + y_off):
            if sy == 34 + y_off:
                c.rect(13, sy, 74, 3, "T1")
                c.line(13, sy, 86, sy, "T4")
            else:
                c.rect(42, sy, 46, 3, "T1")
                c.line(42, sy, 87, sy, "T4")
        c.line(16, 34 + y_off, 29, 48 + y_off, "T1")
        c.line(29, 34 + y_off, 16, 48 + y_off, "T1")
        c.line(57, 34 + y_off, 72, 48 + y_off, "T1")
        c.line(72, 34 + y_off, 57, 48 + y_off, "T1")
        c.line(64, 24 + y_off, 64, 8 + y_off, "T2")
        c.line(64, 10 + y_off, 96, 16 + y_off, "T3")
        c.line(64, 18 + y_off, 78, 13 + y_off, "T1")
        c.line(94, 16 + y_off, 94, 40 + y_off, "H1")
        c.rect(90, 40 + y_off, 8, 6, "L0")
        c.rect_outline(90, 40 + y_off, 8, 6, "C2")


def make_bldg_louvain_st_peters(sprites_dir: str) -> None:
    """128x116 Sint-Pieterskerk unfinished state + 128x152 Crowned Gobertange Spire state."""
    c = PixelCanvas(128, 116)
    _paint_st_peters_base(c, 0, with_scaffold_jib=True)
    c.add_outline("K", selective_hue=True)
    c.refine_epx_architecture().save_png(os.path.join(sprites_dir, "bldg_louvain_st_peters.png"))

    cr = PixelCanvas(128, 152)
    _paint_st_peters_base(cr, 36, with_scaffold_jib=False)
    # Raised pale Gobertange ashlar belfry tiers & flanking pinnacles crowning center tower!
    _draw_sandstone_wall(cr, 48, 34, 32, 26, seed=1432)
    cr.rect(46, 58, 36, 3, "L0")
    for wx in (54, 62, 70):
        _draw_lancet_window(cr, wx, 40, 4, 14, "Y1", True)
    _draw_pinnacle_turret(cr, 48, 36, 10, 8, w=4)
    _draw_pinnacle_turret(cr, 80, 36, 10, 8, w=4)
    # Soaring Louvain Gothic Slate Spire & Golden Weathercock Banner beating Brussels
    _draw_slate_spire(cr, 64, 7, 13, 27)
    cr.line(64, 1, 64, 7, "Y2")
    cr.rect(65, 2, 7, 4, "R2")
    cr.line(65, 3, 71, 3, "Y1")
    cr.add_outline("K", selective_hue=True)
    cr.refine_epx_architecture().save_png(os.path.join(sprites_dir, "bldg_louvain_st_peters_crowned.png"))


def make_ui_mason_crane_sky(sprites_dir: str) -> None:
    """270x140 crisp pixel-art Louvain twilight skyline backdrop for Mason Crane Minigame."""
    bg = PixelCanvas(270, 140, PAL["S"])
    # Dusk twilight gradient bands
    sky_bands = [(0, 28, "N"), (28, 34, "S"), (62, 34, "C0"), (96, 44, "C1")]
    for y0, h, col in sky_bands:
        bg.rect(0, y0, 270, h, col)
    # Subtle stars in high dusk
    for sx, sy in [(26, 12), (62, 18), (108, 9), (168, 15), (218, 10), (246, 22)]:
        bg.pset(sx, sy, "Y1")
    # Distant Louvain gabled guildhalls silhouette
    for bx, bw, bh in [(8, 28, 34), (40, 32, 26), (178, 30, 30), (212, 24, 24)]:
        bg.rect(bx, 140 - bh, bw, bh, "C0")
        bg.line(bx, 140 - bh, bx + bw // 2, 140 - bh - 10, "C0")
        bg.line(bx + bw // 2, 140 - bh - 10, bx + bw - 1, 140 - bh, "C0")
    # Far-right Brussels Belfry Benchmark Silhouette (marker height at y=46!)
    _draw_sandstone_wall(bg, 232, 74, 22, 66, seed=901)
    bg.rect(235, 58, 16, 16, "C1")
    _draw_slate_spire(bg, 243, 44, 7, 14)
    bg.line(243, 40, 243, 44, "Y2")
    # St. Peter's stone westwork plinth base at bottom center (x=88..182, y=114..140)
    _draw_sandstone_wall(bg, 86, 114, 98, 26, seed=1425)
    bg.rect(84, 112, 102, 3, "L0")
    bg.save_png(os.path.join(sprites_dir, "ui_mason_crane_sky.png"))


def make_bldg_louvain_lakenhalle(sprites_dir: str) -> None:
    """120x88 De Lakenhalle: Vaulted Flemish Cloth Hall downstairs + 1425 University lecture wing upstairs."""
    c = PixelCanvas(120, 88)
    c.ellipse(60, 83, 55, 4.5, (14, 12, 18, 120))

    # Steep terracotta-and-slate roof with central stepped academic gable
    _draw_shingles(c, 6, 16, 108, 22, "R0", "R1", "R2")
    c.line(6, 16, 113, 16, "R3")
    # Central Flemish *trapgevel* housing University arms & gilded bellcote
    for si, (gw, gy) in enumerate([(26, 16), (20, 12), (14, 8), (8, 5)]):
        _draw_brick_wall(c, 60 - gw // 2, gy, gw, 5, "R0", "R2", "R3")
        c.line(60 - gw // 2, gy, 60 + gw // 2 - 1, gy, "L1")
    c.line(60, 1, 60, 5, "Y2")

    # UPPER STORY (1425 University Lecture Gallery on warm corbels): leaded study windows + scholar bays
    _draw_sandstone_wall(c, 8, 36, 104, 20, seed=1426)
    c.rect(6, 55, 108, 3, "T0")
    c.line(6, 55, 113, 55, "T3")
    for wx in range(13, 104, 12):
        if abs(wx - 58) < 6:
            # Brass & Crimson Leuven University crest window
            _draw_lancet_window(c, wx, 39, 8, 12, "Y2", True)
        else:
            c.rect(wx, 40, 7, 10, "T0")
            c.rect(wx + 1, 41, 5, 8, "Y1")
            c.line(wx + 3, 41, wx + 3, 48, "T0")
            c.line(wx + 1, 45, wx + 5, 45, "T0")

    # LOWER STORY (1317 Stone Vaulted Cloth Hall Arcade): dark stone arches + wool bales & oak entry
    _draw_brick_wall(c, 8, 58, 104, 25, "R0", "R1", "R2")
    for ax in range(12, 102, 16):
        if ax == 60:
            # Grand arched Cloth Hall & University entrance doors
            c.rect(ax - 5, 61, 14, 22, "C2")
            c.rect(ax - 3, 63, 10, 20, "T1")
            c.line(ax + 2, 63, ax + 2, 82, "T0")
        else:
            # Open vaulted stone arcade stall filled with colored wool bolts!
            c.rect(ax - 2, 62, 12, 21, "C2")
            c.rect(ax - 1, 64, 10, 19, "N")
            bcol = ["I1", "U1", "E1", "H1", "I1", "U2"][(ax // 16) % 6]
            c.rect(ax, 74, 4, 8, bcol)
            c.rect(ax + 5, 75, 4, 7, "L1")
            c.rect(ax, 70, 9, 4, bcol)

    # Exterior covered timber scholar stairs ascending on right wing
    for step_i in range(5):
        sx = 104 - step_i * 2
        sy = 78 - step_i * 4
        c.rect(sx, sy, 10, 3, "T2")
        c.line(sx, sy, sx + 9, sy, "T4")

    c.add_outline("K", selective_hue=True)
    c.refine_epx_architecture().save_png(os.path.join(sprites_dir, "bldg_louvain_lakenhalle.png"))


def make_louvain_gates_and_props(sprites_dir: str) -> None:
    # 1. Horizontal Twin-Tower Brabant Poort (Naamsepoort / Mechelsepoort: 84x62)
    #    Wide transparent central archway (x=22..61, y=38..61 -> ~80px world opening matching 96px street!)
    ph = PixelCanvas(84, 62)
    ph.ellipse(12, 57, 11, 3.5, (14, 12, 18, 120))
    ph.ellipse(72, 57, 11, 3.5, (14, 12, 18, 120))
    # Flanking cylindrical Brabant banded towers straddling left/right street curbs
    for cx in (12, 72):
        _draw_sandstone_wall(ph, cx - 9, 22, 18, 35, seed=cx)
        ph.rect(cx - 9, 34, 18, 4, "R1")
        ph.rect(cx - 1, 28, 2, 6, "N")
        _draw_slate_spire(ph, cx, 4, 10, 18)
        ph.line(cx, 1, cx, 4, "Y2")
    # Overhead gatehouse bridge spanning the street (x=21..62, y=18..37) + Brabant shield
    _draw_sandstone_wall(ph, 21, 22, 42, 15, seed=99)
    ph.rect(21, 20, 42, 4, "L1")
    for px in range(22, 62, 6):
        ph.rect(px, 17, 4, 4, "L0")
    ph.rect(40, 25, 5, 7, "I1")
    ph.rect(40, 28, 5, 2, "L0")
    # Soft arched vault shadow + raised portcullis iron spikes framing open cobbles beneath
    ph.rect(21, 37, 42, 3, "C0")
    ph.rect(22, 40, 40, 4, (14, 12, 18, 105))
    for gx in range(24, 61, 5):
        ph.line(gx, 38, gx, 42, "C3")
    ph.add_outline("K", selective_hue=True)
    ph.refine_epx_architecture(False).save_png(os.path.join(sprites_dir, "prop_louvain_poort_h.png"))

    # 2. Vertical 3/4 Open-Road City Gatehouse (Brusselsepoort / Tiensepoort: 58x96)
    #    Wide transparent roadway passage (y=36..70 -> 70px clear cobble channel between flanking north/south towers!)
    pv = PixelCanvas(58, 96)
    # North flanking bastion tower + steep slate roof (sits strictly north of road curb)
    pv.ellipse(29, 31, 21, 3.0, (14, 12, 18, 95))
    _draw_sandstone_wall(pv, 10, 12, 38, 19, seed=11)
    pv.rect(10, 19, 38, 3, "R1")
    pv.rect(14, 14, 3, 4, "N")
    pv.rect(41, 14, 3, 4, "N")
    _draw_slate_spire(pv, 29, 1, 14, 11)
    pv.line(29, 0, 29, 1, "Y2")
    # Overhead gatehouse stone arch spanning across north curb & upper arch lip (y=29..39)
    _draw_sandstone_wall(pv, 16, 29, 26, 8, seed=77)
    pv.rect(16, 27, 26, 3, "L1")
    pv.rect(26, 30, 6, 6, "I1")
    pv.rect(26, 33, 6, 2, "L0")
    # Corbelled stone arch springers + raised portcullis teeth (full cobblestone road below y=40..70 is OPEN!)
    pv.rect(12, 37, 6, 4, "C2")
    pv.rect(40, 37, 6, 4, "C2")
    pv.rect(18, 37, 22, 3, "C0")
    pv.rect(16, 39, 26, 3, (14, 12, 18, 90))
    for gx in range(20, 39, 4):
        pv.line(gx, 37, gx, 40, "C3")
    # South flanking bastion tower (y=71..94 -> sits cleanly at south curb, clear of street!)
    pv.ellipse(29, 92, 22, 3.5, (14, 12, 18, 115))
    _draw_sandstone_wall(pv, 10, 73, 38, 19, seed=55)
    pv.rect(10, 80, 38, 3, "R1")
    pv.rect(14, 76, 3, 4, "N")
    pv.rect(41, 76, 3, 4, "N")
    for mx in (12, 21, 32, 41):
        pv.rect(mx, 70, 5, 4, "L1")
    pv.add_outline("K", selective_hue=True)
    pv.refine_epx_architecture(False).save_png(os.path.join(sprites_dir, "prop_louvain_poort_v.png"))

    # 3. Round Sint-Donatus Ring-Wall Bastion Tower (44x52)
    tw = PixelCanvas(44, 52)
    tw.ellipse(22, 47, 16, 4.0, (14, 12, 18, 120))
    _draw_sandstone_wall(tw, 10, 20, 24, 27, seed=505)
    tw.rect(10, 32, 24, 4, "R1")
    tw.line(10, 20, 10, 46, "C1")
    tw.line(33, 20, 33, 46, "H1")
    tw.rect(21, 25, 2, 6, "N")
    tw.rect(14, 37, 2, 5, "N")
    tw.rect(28, 37, 2, 5, "N")
    _draw_slate_spire(tw, 22, 4, 14, 16)
    tw.line(22, 1, 22, 4, "Y2")
    tw.add_outline("K", selective_hue=True)
    tw.save_png(os.path.join(sprites_dir, "prop_louvain_wall_tower.png"))

    # 4. Warm Broad-Leaf Courtyard Lime Tree (36x46)
    lt = PixelCanvas(36, 46)
    lt.ellipse(18, 41, 12, 3.5, (14, 12, 18, 110))
    lt.rect(15, 25, 6, 16, "T0")
    lt.rect(16, 25, 3, 16, "T2")
    lt.line(17, 26, 17, 39, "T3")
    for cx, cy, rx, ry, col in [
        (12, 21, 9, 7, "G0"), (24, 21, 9, 7, "G0"), (18, 16, 12, 10, "G1"),
        (13, 14, 8, 7, "G2"), (22, 15, 8, 6, "G2"), (16, 10, 7, 5, "G3"),
    ]:
        lt.ellipse(cx, cy, rx, ry, col)
    for lx, ly in ((10, 13), (15, 8), (20, 11), (13, 18), (22, 17)):
        lt.pset(lx, ly, "G3")
    lt.add_outline("DE", selective_hue=True)
    lt.save_png(os.path.join(sprites_dir, "prop_lime_tree.png"))

    # 5. Dyers' Island Madder Red & Woad Blue Steaming Dye Vats (24x22)
    for cname, l0, l1 in [("red", "I1", "I2"), ("blue", "U1", "U2")]:
        dv = PixelCanvas(24, 22)
        dv.ellipse(12, 18, 9, 3.0, (14, 12, 18, 105))
        dv.rect(4, 9, 16, 10, "T1")
        dv.rect(5, 10, 14, 8, "T2")
        dv.line(4, 12, 19, 12, "C2")
        dv.line(4, 16, 19, 16, "C2")
        dv.ellipse(12, 9, 8, 3.5, "T3")
        dv.ellipse(12, 9, 6, 2.5, l0)
        dv.pset(10, 8, l1)
        dv.pset(14, 9, l1)
        dv.line(15, 3, 13, 9, "T3")  # mixing paddle
        dv.add_outline("K", selective_hue=True)
        dv.save_png(os.path.join(sprites_dir, f"prop_dye_vat_{cname}.png"))

    # 6. Vismarkt Wine-Cask Dray Cart (44x30) — great stealth cover!
    wc = PixelCanvas(44, 30)
    wc.ellipse(22, 25, 19, 4.0, (14, 12, 18, 120))
    wc.rect(4, 16, 32, 7, "T1")
    wc.rect(5, 17, 30, 4, "T2")
    wc.line(35, 19, 42, 20, "T2")  # pull shafts
    wc.line(35, 22, 42, 23, "T2")
    for wx in (10, 27):
        wc.ellipse(wx, 23, 5, 5, "T0")
        wc.ellipse(wx, 23, 3, 3, "T3")
        wc.pset(wx, 23, "C2")
    for bx in (8, 20):
        wc.rect(bx, 7, 11, 10, "T2")
        wc.rect(bx + 1, 8, 9, 8, "T3")
        wc.line(bx, 10, bx + 10, 10, "C2")
        wc.line(bx, 14, bx + 10, 14, "C2")
        wc.rect(bx + 4, 8, 2, 8, "T4")
    wc.add_outline("K", selective_hue=True)
    wc.save_png(os.path.join(sprites_dir, "prop_wine_cask_cart.png"))

    # 7. Sint-Pieterskerk Mason Workyard Pile (48x32)
    my = PixelCanvas(48, 32)
    my.ellipse(24, 27, 21, 4.0, (14, 12, 18, 110))
    for bx, by in ((4, 18), (16, 17), (10, 11)):
        my.rect(bx, by, 13, 8, "L1")
        my.rect(bx + 1, by + 1, 11, 6, "L0")
        my.rect_outline(bx, by, 13, 8, "C2")
    # Stacked timber scaffold poles + hemp rope coils
    for py in (20, 23):
        my.rect(28, py, 16, 2, "T2")
        my.line(29, py, 42, py, "T4")
    my.ellipse(35, 14, 5, 3, "H1")
    my.ellipse(35, 14, 2, 1, "T1")
    my.add_outline("K", selective_hue=True)
    my.save_png(os.path.join(sprites_dir, "prop_mason_yard.png"))


def _mirror_canvas_h(src: PixelCanvas) -> PixelCanvas:
    out = PixelCanvas(src.w, src.h)
    for y in range(src.h):
        for x in range(src.w):
            out.px[y * out.w + (src.w - 1 - x)] = list(src.px[y * src.w + x])
    return out


def make_louvain_wall_corners(sprites_dir: str) -> None:
    """Generate 36x36 seamless L-bend stone wall corner tiles matching prop_wall_h & prop_wall_v."""
    # NW Corner (horizontal from right x=35 bending down to y=35)
    nw = PixelCanvas(36, 36)
    nw.rect(0, 2, 2, 34, (14, 15, 22, 110))
    nw.rect(25, 33, 11, 3, (14, 15, 22, 110))
    # Left outer vertical ashlar column wrapping up into horizontal top corner
    _draw_stone_masonry_rect(nw, 2, 10, 8, 26, seed=211, row_h=4, blk_w=6, moss=True)
    nw.line(2, 10, 2, 35, "S")
    # Inner bottom-right masonry corner turning from H face (y=15..32) into V right face (x=26..33)
    _draw_stone_masonry_rect(nw, 25, 15, 11, 17, seed=212, row_h=4, blk_w=6, moss=False)
    _draw_stone_masonry_rect(nw, 26, 20, 8, 16, seed=213, row_h=4, blk_w=6, moss=True)
    nw.rect(25, 31, 11, 3, "CS")
    nw.line(25, 31, 35, 31, "C1")
    nw.line(25, 33, 35, 33, "S")
    nw.line(33, 15, 33, 35, "S")
    nw.line(25, 15, 25, 35, "C0")
    for qy in (16, 22, 28):
        nw.rect(25, qy, 3, 4, "C2")
    # Bending chemin-de-ronde walkway: H band (x=11..35, y=9..14) + V band (x=11..24, y=9..35)
    nw.rect(11, 9, 25, 6, "C1")
    nw.rect(11, 9, 14, 27, "C1")
    nw.rect(12, 10, 24, 4, "CS2")
    nw.rect(12, 10, 12, 26, "CS2")
    for sx in (16, 24, 32):
        nw.line(sx, 10, sx, 13, "C0")
    for sy in (16, 24, 32):
        nw.line(12, sy, 23, sy, "C0")
    nw.line(12, 10, 35, 10, "C2")
    nw.line(12, 10, 12, 35, "C2")
    nw.line(10, 9, 35, 9, "C0")
    nw.line(10, 9, 10, 35, "C0")
    nw.line(24, 14, 35, 14, "S")
    nw.line(24, 14, 24, 35, "C0")
    # Continuous corner battlement merlons wrapping outer NW bend + inner post
    nw.rect(4, 1, 14, 8, "S")
    _draw_stone_masonry_rect(nw, 5, 2, 12, 6, seed=215, row_h=3, blk_w=5, moss=False)
    nw.line(5, 1, 16, 1, "C3")
    nw.rect(22, 1, 12, 8, "S")
    _draw_stone_masonry_rect(nw, 23, 2, 10, 6, seed=216, row_h=3, blk_w=5, moss=False)
    nw.line(23, 1, 32, 1, "C3")
    nw.rect(18, 5, 4, 5, "C0")
    nw.rect(18, 6, 4, 3, "CS2")
    nw.rect(7, 11, 5, 11, "S")
    nw.rect(8, 12, 3, 9, "C2")
    nw.line(8, 12, 10, 12, "C3")
    nw.rect(7, 26, 5, 9, "S")
    nw.rect(8, 27, 3, 7, "C2")
    nw.rect(24, 20, 5, 11, "S")
    nw.rect(25, 21, 3, 9, "C2")
    nw.save_png(os.path.join(sprites_dir, "prop_wall_corner_nw.png"))
    _mirror_canvas_h(nw).save_png(os.path.join(sprites_dir, "prop_wall_corner_ne.png"))

    # SW Corner (vertical from top y=0 bending right to x=35)
    sw = PixelCanvas(36, 36)
    sw.rect(0, 0, 2, 35, (14, 15, 22, 110))
    sw.rect(1, 33, 35, 3, (14, 15, 22, 110))
    # Continuous wrapping exterior stone wall face (left vertical x=2..9 curving cleanly along front y=15..32)
    _draw_stone_masonry_rect(sw, 2, 0, 8, 32, seed=221, row_h=4, blk_w=6, moss=True)
    _draw_stone_masonry_rect(sw, 9, 15, 27, 17, seed=222, row_h=4, blk_w=8, moss=True)
    # Quoin stone corner emphasis + base plinth wrap
    for qy in (16, 22, 28):
        sw.rect(3, qy, 5, 3, "C2")
    sw.rect(2, 31, 34, 3, "CS")
    sw.line(2, 31, 35, 31, "C1")
    sw.line(2, 33, 35, 33, "S")
    sw.line(2, 0, 2, 33, "S")
    # Bending chemin-de-ronde walkway: V band (x=11..24, y=0..14) turning 90 deg right into H band (x=11..35, y=9..14)
    sw.rect(11, 0, 14, 15, "C1")
    sw.rect(11, 9, 25, 6, "C1")
    sw.rect(12, 0, 12, 14, "CS2")
    sw.rect(12, 10, 24, 4, "CS2")
    for sy in (0, 8):
        sw.line(12, sy, 23, sy, "C0")
    for sx in (18, 26, 34):
        sw.line(sx, 10, sx, 13, "C0")
    sw.line(12, 0, 12, 13, "C2")
    sw.line(12, 13, 35, 13, "C2")
    sw.line(10, 0, 10, 14, "C0")
    sw.line(10, 14, 35, 14, "S")
    # Outer left vertical merlons + inner corner merlons turning continuously
    sw.rect(7, 2, 5, 11, "S")
    sw.rect(8, 3, 3, 9, "C2")
    sw.line(8, 3, 10, 3, "C3")
    sw.rect(24, 1, 11, 8, "S")
    _draw_stone_masonry_rect(sw, 25, 2, 9, 6, seed=225, row_h=3, blk_w=5, moss=False)
    sw.line(25, 1, 34, 1, "C3")
    sw.rect(24, 0, 5, 9, "S")
    sw.rect(25, 1, 3, 7, "C2")
    sw.line(25, 0, 25, 9, "C0")
    sw.save_png(os.path.join(sprites_dir, "prop_wall_corner_sw.png"))
    _mirror_canvas_h(sw).save_png(os.path.join(sprites_dir, "prop_wall_corner_se.png"))


def make_louvain_assets(sprites_dir: str) -> None:
    make_louvain_tiles(sprites_dir)
    make_bldg_louvain_stadhuis(sprites_dir)
    make_bldg_louvain_st_peters(sprites_dir)
    make_ui_mason_crane_sky(sprites_dir)
    make_bldg_louvain_lakenhalle(sprites_dir)
    make_louvain_gates_and_props(sprites_dir)
    make_louvain_wall_corners(sprites_dir)
    make_louvain_props_and_walls(sprites_dir)
