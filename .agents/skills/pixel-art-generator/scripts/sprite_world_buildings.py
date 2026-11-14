"""
Seamless 16x16 world tiles, merchant cog 'De Zwaan', and Flemish buildings.
"""

import math
import os
import random
from pixel_art_lib import PAL, PixelCanvas, blend_color

# ============================================================================
# 1. SEAMLESS 16x16 WORLD TILES
# ============================================================================

def make_tiles(sprites_dir: str):
    # Cobblestone variants (seamless interlocking rounded Flemish pavers)
    for variant in (0, 1):
        c = PixelCanvas(16, 16, PAL["C0"])
        stones = [
            (0, 0, 7, 5, "C1", "C2"),
            (8, 0, 7, 4, "C2", "C3"),
            (1, 6, 5, 4, "C2", "C3"),
            (7, 5, 8, 5, "C1", "C2"),
            (0, 11, 8, 4, "C1", "C2"),
            (9, 11, 6, 4, "C2", "C3"),
        ]
        if variant == 1:
            stones[1] = (8, 0, 7, 4, "C1", "C2")
            stones[3] = (7, 5, 8, 5, "C2", "C3")
        for sx, sy, sw, sh, base, hi in stones:
            # Rounded corners (skip outer 4 corner pixels)
            for py in range(sy, sy + sh):
                for px in range(sx, sx + sw):
                    if (px in (sx, sx + sw - 1)) and (py in (sy, sy + sh - 1)):
                        continue
                    c.pset(px, py, base)
            c.line(sx + 1, sy, sx + sw - 2, sy, hi)
            c.line(sx, sy + 1, sx, sy + sh - 2, hi)
            c.pset(sx + 1, sy + 1, "C3" if hi == "C2" else "C4")
        # Subtle moss flecks in cobblestone joints
        if variant == 0:
            c.pset(6, 5, "G0")
            c.pset(15, 10, "G1")
        else:
            c.pset(0, 10, "G0")
            c.pset(8, 4, "G1")
            c.pset(13, 15, "G0")
        name = "tile_cobble.png" if variant == 0 else "tile_cobble_2.png"
        c.save_png(os.path.join(sprites_dir, name))

    # 4-frame animated Zwin Canal water
    for frame in range(4):
        w = PixelCanvas(16, 16, PAL["W0"])
        phase = frame * 4
        for y in range(16):
            for x in range(16):
                wave_val = math.sin((x + phase) * math.pi / 4.0 + y * 0.45)
                if wave_val > 0.35:
                    w.pset(x, y, "W2")
                elif wave_val > -0.15:
                    w.pset(x, y, "W1")
        # Crisp interlocking shimmer crests
        rx1 = (2 + frame * 4) % 16
        rx2 = (10 + frame * 4) % 16
        for dx, col in ((0, "W3"), (1, "W4"), (2, "W4"), (3, "W3")):
            w.pset((rx1 + dx) % 16, 3, col)
            w.pset((rx2 + dx) % 16, 11, col)
        w.pset((rx1 + 1) % 16, 3, "W5")
        w.save_png(os.path.join(sprites_dir, f"tile_water_{frame + 1}.png"))

    # Weathered harbor oak wharf planks
    p = PixelCanvas(16, 16, PAL["T0"])
    for idx, py in enumerate((0, 4, 8, 12)):
        p.rect(0, py, 16, 3, "T1")
        p.line(0, py, 15, py, "T2")
        p.line(2, py + 1, 13, py + 1, "T2" if idx % 2 == 0 else "T1")
        # Staggered plank seam & iron nails
        seam_x = 5 if idx % 2 == 0 else 11
        p.rect(seam_x, py, 1, 3, "T0")
        p.pset((seam_x + 2) % 16, py + 1, "K")
        p.pset((seam_x - 2) % 16, py + 1, "K")
    p.save_png(os.path.join(sprites_dir, "tile_wharf.png"))

    # Lush layered meadow grass (3 organic variants — no grid-like bright flower dots)
    for variant in (0, 1, 2):
        g = PixelCanvas(16, 16, PAL["G1"])
        for y in range(16):
            for x in range(16):
                h = ((x * 37 + y * 53 + variant * 97) ^ (x * y + variant * 19)) % 17
                if h < 3:
                    g.pset(x, y, "G0")
                elif h == 15:
                    g.pset(x, y, "G2")
        if variant == 0:
            tufts = [(2, 4), (11, 7), (6, 13)]
        elif variant == 1:
            tufts = [(4, 3), (13, 10), (3, 12)]
        else:
            tufts = [(8, 4), (2, 9), (12, 14)]
        for tx, ty in tufts:
            g.pset(tx, ty, "G0")
            g.pset((tx - 1) % 16, (ty - 1) % 16, "G2")
            g.pset((tx + 1) % 16, (ty - 1) % 16, "G2")
            if (tx + variant) % 2 == 0:
                g.pset(tx, (ty - 2) % 16, "G3")
        names = ("tile_grass.png", "tile_grass_2.png", "tile_grass_3.png")
        g.save_png(os.path.join(sprites_dir, names[variant]))

    # Warm cottage oak floorboards
    f = PixelCanvas(16, 16, PAL["T1"])
    for idx, py in enumerate((0, 4, 8, 12)):
        f.rect(0, py, 16, 3, "T2")
        f.line(0, py, 15, py, "T3")
        f.line(0, py + 3, 15, py + 3, "T0")
        seam_x = 4 if idx % 2 == 0 else 12
        f.rect(seam_x, py, 1, 3, "T0")
        f.pset((seam_x + 5) % 16, py + 1, "T1")
    f.save_png(os.path.join(sprites_dir, "tile_wood_floor.png"))

    # Packed wilderness dirt trail
    d = PixelCanvas(16, 16, PAL["T1"])
    for y in range(16):
        for x in range(16):
            v = ((x * 7 + y * 13) ^ (x + y * 3)) % 19
            if v < 3:
                d.pset(x, y, "T0")
            elif v > 15:
                d.pset(x, y, "T2")
    for px, py in ((3, 4), (11, 2), (8, 10), (14, 13)):
        d.pset(px, py, "C1")
        d.pset((px + 1) % 16, (py + 1) % 16, "T0")
    d.save_png(os.path.join(sprites_dir, "tile_dirt_path.png"))

    # Gradual 16x16 Straddling Terrain Seam Tiles (drawn at 2x = 32x32 centered on boundary)
    # 1) Grass <-> Cobble Stone seams (n/s/e/w + corners)
    def _save_seam_variants(prefix: str, eval_fn):
        dirs = ("n", "s", "e", "w", "nw", "ne", "sw", "se")
        for dname in dirs:
            sc = PixelCanvas(16, 16)
            for y in range(16):
                for x in range(16):
                    # Signed distance from inside terrain into outer adjacent terrain:
                    # dv < 0 means INSIDE the zone (e.g. on grass), dv >= 0 means OUTSIDE (over stone/grass)
                    if dname == "n":
                        dv = 7.5 - y
                    elif dname == "s":
                        dv = y - 7.5
                    elif dname == "w":
                        dv = 7.5 - x
                    elif dname == "e":
                        dv = x - 7.5
                    elif dname == "nw":
                        dv = max(7.5 - x, 7.5 - y)
                    elif dname == "ne":
                        dv = max(x - 7.5, 7.5 - y)
                    elif dname == "sw":
                        dv = max(7.5 - x, y - 7.5)
                    else:  # se
                        dv = max(x - 7.5, y - 7.5)
                    col = eval_fn(x, y, dv, dname)
                    if col is not None:
                        sc.pset(x, y, col)
            sc.save_png(os.path.join(sprites_dir, f"{prefix}_{dname}.png"))

    def _grass_stone_pixel(x: int, y: int, dv: float, dname: str):
        h = ((x * 29 + y * 47 + len(dname) * 17) ^ (x * 7 + y * 13)) % 100
        jitter = ((h % 5) - 2) * 0.85
        d = dv + jitter
        # Outer zone (cobble side): grass blades & mossy earth tapering gently
        if d > 5.8:
            return None
        if 3.2 < d <= 5.8:
            if h < 22:
                return (PAL["G0"][0], PAL["G0"][1], PAL["G0"][2], 140)
            if 55 <= h < 66:
                return (PAL["T0"][0], PAL["T0"][1], PAL["T0"][2], 125)
            return None
        if 0.0 <= d <= 3.2:
            if h < 34:
                return "G1"
            if h < 54:
                return "G0"
            if h < 68:
                return "G2"
            if h < 82:
                return (PAL["T0"][0], PAL["T0"][1], PAL["T0"][2], 195)
            return None
        # Inner zone (grass side): sunken grey cobbles & earth peeking out along border
        if -4.2 <= d < 0.0:
            if 18 <= h < 42:
                return "C1" if h < 30 else "C2"
            if 42 <= h < 56:
                return "T0"
            if 78 <= h < 92:
                return "G0"
        return None

    def _dirt_grass_pixel(x: int, y: int, dv: float, dname: str):
        h = ((x * 41 + y * 61 + len(dname) * 23) ^ (x * 11 + y * 5)) % 100
        jitter = ((h % 5) - 2) * 0.90
        d = dv + jitter
        # Outer side (grass/stone around trail): warm dirt crumbs & tiny gravel gradually fading
        if d > 5.6:
            return None
        if 2.6 < d <= 5.6:
            if h < 26:
                return (PAL["T1"][0], PAL["T1"][1], PAL["T1"][2], 150)
            if 68 <= h < 76:
                return (PAL["C2"][0], PAL["C2"][1], PAL["C2"][2], 145)
            return None
        if 0.0 <= d <= 2.6:
            if h < 36:
                return "T1"
            if h < 56:
                return "T0"
            if h < 72:
                return (PAL["T2"][0], PAL["T2"][1], PAL["T2"][2], 210)
            if h < 82:
                return "C1"
            return None
        # Inner side (trail margin): jagged grass blades & gravel stones breaking up straight dirt edge
        if -4.5 <= d < 0.0:
            if h < 28:
                return "G1" if h > 12 else "G0"
            if 60 <= h < 72:
                return "G2"
            if 82 <= h < 90:
                return "C2"
        return None

    def _dirt_stone_pixel(x: int, y: int, dv: float, dname: str):
        h = ((x * 31 + y * 59 + len(dname) * 13) ^ (x * 5 + y * 19)) % 100
        jitter = ((h % 5) - 2) * 0.85
        d = dv + jitter
        if d > 5.6:
            return None
        if 2.4 < d <= 5.6:
            if h < 28:
                return (PAL["T1"][0], PAL["T1"][1], PAL["T1"][2], 145)
            if 64 <= h < 76:
                return (PAL["T2"][0], PAL["T2"][1], PAL["T2"][2], 125)
            return None
        if 0.0 <= d <= 2.4:
            if h < 42:
                return "T1"
            if h < 66:
                return "T0"
            if h < 78:
                return "C2"
            return None
        if -4.2 <= d < 0.0:
            if h < 34:
                return "C1" if h < 18 else "C2"
            if 78 <= h < 88:
                return "C3"
        return None

    _save_seam_variants("edge_grass_stone", _grass_stone_pixel)
    _save_seam_variants("edge_dirt_grass", _dirt_grass_pixel)
    _save_seam_variants("edge_dirt_stone", _dirt_stone_pixel)

    # Ground scatter decals (16x16 transparent) to break monotony on meadows & stone joints
    for idx in (0, 1):
        wf = PixelCanvas(16, 16)
        spots = ((4, 5, "L1"), (11, 9, "Y2"), (7, 13, "L0")) if idx == 0 else ((3, 10, "Y1"), (12, 4, "L1"), (8, 8, "Y2"))
        for sx, sy, col in spots:
            wf.pset(sx, sy + 1, "G0")
            wf.pset(sx, sy, col)
            wf.pset(sx - 1, sy, "G2")
            wf.pset(sx + 1, sy, "G2")
        wf.save_png(os.path.join(sprites_dir, f"decal_wildflower_{idx}.png"))

        pb = PixelCanvas(16, 16)
        stones = ((3, 4, 3, 2), (10, 6, 4, 3), (6, 12, 3, 2)) if idx == 0 else ((4, 9, 4, 2), (11, 3, 3, 3), (9, 12, 3, 2))
        for px, py, pw, ph in stones:
            pb.rect(px, py, pw, ph, "C1")
            pb.line(px, py, px + pw - 1, py, "C2")
            pb.pset(px, py, "C3")
        pb.save_png(os.path.join(sprites_dir, f"decal_pebbles_{idx}.png"))

    gt = PixelCanvas(16, 16)
    for tx, ty in ((4, 6), (10, 4), (7, 11), (12, 12)):
        gt.pset(tx, ty, "G0")
        gt.line(tx - 1, ty - 1, tx + 1, ty - 1, "G2")
        gt.pset(tx, ty - 2, "G3")
    gt.save_png(os.path.join(sprites_dir, "decal_grass_tuft.png"))


# ============================================================================
# 2. MERCHANT COG 'DE ZWAAN' (72x108 -> 144x216 at 2x)
# ============================================================================

def make_merchant_cog(sprites_dir: str):
    c = PixelCanvas(72, 108)

    # Subtle water wake foam around hull
    for y in range(8, 102):
        if y < 26:
            hw = 6 + (y - 8) * 1.15
        elif y > 82:
            hw = max(6.0, 26.0 - (y - 82) * 0.9)
        else:
            hw = 26.5 + math.sin((y - 26) * 0.08) * 1.5
        if y % 3 == 0:
            c.pset(int(36 - hw - 2), y, "W4")
            c.pset(int(36 + hw + 1), y, "W4")
        if y > 88 and y % 2 == 0:
            c.line(int(36 - hw), y, int(36 + hw), y, "W3")

    # Clinker-planked medieval cog hull
    for y in range(10, 96):
        if y < 28:
            hw = int(4 + (y - 10) * 1.15)
        elif y > 80:
            hw = max(5, int(24 - (y - 80) * 1.0))
        else:
            hw = 25
        # Gunwale rim
        c.rect(36 - hw, y, hw * 2, 1, "T0")
        if hw > 3:
            c.rect(36 - hw + 2, y, hw * 2 - 4, 1, "T1")
        if hw > 6:
            c.rect(36 - hw + 4, y, hw * 2 - 8, 1, "T2")
            # Deck plank joints every 4px + staggered seams
            if y % 4 == 0:
                c.line(36 - hw + 4, y, 36 + hw - 5, y, "T1")
            if (y // 4) % 2 == 0 and hw > 10:
                c.pset(28, y + 2, "T1")
                c.pset(44, y + 2, "T1")

    # Raised Sterncastle (top of cog, y=14..32) & Crenellated Rail
    c.rect(18, 14, 36, 18, "T2")
    c.rect(20, 16, 32, 14, "T3")
    c.rect_outline(18, 14, 36, 18, "T0")
    for rx in range(20, 52, 4):
        c.rect(rx, 13, 2, 2, "T3")
    c.rect(33, 18, 6, 8, "T1")  # Tiller / helm box

    # Forecastle deck & white Swan figurehead at bow (bottom, y=82..98)
    c.rect(24, 78, 24, 12, "T2")
    c.rect(26, 80, 20, 8, "T3")
    c.rect_outline(24, 78, 24, 12, "T0")
    # Bowsprit & carved white swan neck ('De Zwaan')
    c.line(36, 90, 36, 102, "T2")
    c.line(35, 92, 35, 101, "T3")
    c.rect(34, 98, 4, 4, "L0")
    c.pset(36, 102, "L0")

    # Cargo Hatch & stowed barrels/crates
    c.rect(28, 36, 16, 10, "T0")
    c.rect(29, 37, 14, 8, "T1")
    c.line(29, 41, 42, 41, "T0")

    # Central Mast & Furled Canvas Yardarm with rigging lines
    c.line(12, 54, 36, 46, "H1")
    c.line(60, 54, 36, 46, "H1")
    c.line(12, 55, 36, 60, "H0")
    c.line(60, 55, 36, 60, "H0")
    # Yardarm & furled linen sail
    c.rect(10, 51, 52, 3, "T1")
    c.rect(12, 53, 48, 6, "L0")
    c.rect(12, 57, 48, 2, "L1")
    for sx in range(16, 58, 6):
        c.line(sx, 52, sx, 58, "H0")  # sail gaskets
    c.circle(36, 54, 4, "T0")
    c.circle(36, 54, 3, "T2")
    c.pset(35, 53, "T4")

    # Coiled anchor rope & brass ship's bell
    c.circle(47, 72, 4, "H1")
    c.circle(47, 72, 2, "H2")
    c.pset(36, 33, "Y2")

    c.add_outline("K", selective_hue=True)
    c.save_png(os.path.join(sprites_dir, "merchant_cog.png"))


# ============================================================================
# 3. MEDIEVAL FLEMISH BUILDINGS (EXACT 2x INTEGER SCALE)
# ============================================================================

def _draw_shingles(c: PixelCanvas, x0, y0, w, h, dark, mid, hi):
    c.rect(x0, y0, w, h, dark)
    for y in range(y0, y0 + h):
        row_i = (y - y0) // 3
        for x in range(x0, x0 + w):
            in_row = (y - y0) % 3
            tile_x = (x + (row_i % 2) * 3) % 6
            if in_row == 2 or tile_x == 0:
                c.pset(x, y, dark)
            elif in_row == 0 and tile_x in (1, 2):
                c.pset(x, y, hi)
            else:
                c.pset(x, y, mid)


def _draw_brick_wall(c: PixelCanvas, x0, y0, w, h, c_dark, c_mid, c_hi):
    c.rect(x0, y0, w, h, c_mid)
    for y in range(y0, y0 + h):
        row = (y - y0) // 3
        for x in range(x0, x0 + w):
            if (y - y0) % 3 == 2:
                c.pset(x, y, c_dark)
            elif (x + (row % 2) * 3) % 6 == 0:
                c.pset(x, y, c_dark)
            elif (x * 7 + y * 11) % 13 == 0:
                c.pset(x, y, c_hi)


def make_buildings(sprites_dir: str):
    # 1. Harbour Warehouse (144x88 -> 288x176)
    w = PixelCanvas(144, 88)
    # Stone plinth + stepped Flemish brick walls
    _draw_brick_wall(w, 6, 30, 132, 54, "R0", "R1", "R2")
    w.rect(6, 70, 132, 14, "C1")
    for sx in range(8, 136, 8):
        w.rect(sx, 71, 6, 5, "C2")
        w.rect(sx + 3, 77, 6, 5, "C2")
    # Dark slate tiled roof + stepped center gable
    _draw_shingles(w, 8, 10, 128, 28, "N", "S", "C1")
    w.line(8, 10, 135, 10, "C2")
    w.line(6, 38, 137, 38, "T0")
    # Central Flemish stepped gable (*trapgevel*)
    for step, (gx, gw, gy, gh) in enumerate([
        (52, 40, 22, 18), (56, 32, 14, 8), (60, 24, 8, 6), (65, 14, 3, 5)
    ]):
        _draw_brick_wall(w, gx, gy, gw, gh, "R0", "R2", "R3")
        w.line(gx, gy, gx + gw - 1, gy, "C3")  # stone step coping
    # Hoist beam & hanging pulley hook
    w.rect(69, 6, 6, 12, "T2")
    w.rect(70, 6, 4, 3, "T3")
    w.line(72, 18, 72, 26, "H1")
    w.rect(70, 26, 4, 3, "C3")
    # Loft shutter windows
    for wx in (22, 108):
        w.rect(wx, 44, 14, 14, "T0")
        w.rect(wx + 2, 46, 10, 10, "T2")
        w.line(wx + 7, 46, wx + 7, 55, "T0")
    # Heavy arched double cargo doors
    w.rect(52, 48, 40, 36, "C0")
    w.rect(54, 50, 36, 34, "T1")
    w.rect(56, 52, 15, 32, "T2")
    w.rect(73, 52, 15, 32, "T2")
    w.rect(71, 50, 2, 34, "T0")
    for hy in (58, 72):
        w.rect(55, hy, 10, 2, "C3")
        w.rect(79, hy, 10, 2, "C3")
    # Stacked barrels beside doorway
    w.rect(36, 70, 10, 14, "T2")
    w.rect_outline(36, 70, 10, 14, "T0")
    w.line(36, 74, 45, 74, "C2")
    w.line(36, 80, 45, 80, "C2")
    w.add_outline("K", selective_hue=True)
    w.save_png(os.path.join(sprites_dir, "building_warehouse.png"))

    # 2. Bruges Ropewalk (260x72 -> 520x144) — Open-sided medieval rope-spinning gallery
    r = PixelCanvas(260, 72)
    # Recessed shadowy interior bay
    r.rect(6, 26, 248, 42, "T0")
    r.rect(8, 28, 244, 38, (40, 26, 18, 255))
    # Stretched taut hemp strands spanning the entire ropewalk interior!
    for hy in (40, 44, 48):
        r.line(18, hy, 242, hy, "H1")
        r.line(18, hy - 1, 242, hy - 1, "H2")
    # Spinning windlass wheels at both ends + mid-supports
    for wx in (24, 130, 236):
        r.circle(wx, 45, 7, "T2")
        r.circle(wx, 45, 5, "T3")
        r.circle(wx, 45, 2, "H2")
    # Open arcade oak posts & coiled rope stacks
    for px in range(12, 250, 32):
        r.rect(px, 28, 6, 40, "T1")
        r.line(px + 1, 28, px + 1, 67, "T2")
        r.line(px + 5, 28, px + 5, 67, "T0")
        if px < 228:
            # Hanging hemp skein & ground rope coils
            r.rect(px + 12, 54, 14, 12, "H0")
            r.rect(px + 13, 55, 12, 9, "H1")
            r.rect(px + 15, 56, 8, 5, "H2")
    # Shingled long clay/slate pitched roof + ridge caps + 2 small ventilation dormers
    _draw_shingles(r, 4, 6, 252, 22, "S", "C1", "C2")
    r.line(6, 6, 253, 6, "R2")
    r.line(6, 7, 253, 7, "R1")
    r.rect(4, 27, 252, 3, "T2")
    for dx in (76, 176):
        r.rect(dx, 2, 16, 12, "T1")
        _draw_shingles(r, dx - 2, 2, 20, 6, "R0", "R1", "R2")
        r.rect(dx + 4, 8, 8, 5, "T0")
    r.add_outline("K", selective_hue=True)
    r.save_png(os.path.join(sprites_dir, "building_ropewalk.png"))

    # 3. Market Baker Stall (80x48 -> 160x96)
    b = PixelCanvas(80, 48)
    # Brick oven chimney on right
    _draw_brick_wall(b, 60, 2, 12, 22, "R0", "R1", "R2")
    b.rect(59, 2, 14, 2, "C2")
    # Timber-framed plaster stall body & wooden counter
    b.rect(6, 18, 66, 26, "L1")
    b.rect(6, 29, 66, 15, "T1")
    b.rect(5, 27, 68, 3, "T3")
    for tx in (6, 38, 68):
        b.rect(tx, 18, 4, 26, "T0")
    # Striped red-and-cream scalloped awning + cast shadow
    b.rect(4, 19, 70, 2, (24, 18, 20, 120))
    for ax in range(4, 74, 7):
        stripe_hi = "I2" if ((ax - 4) // 7) % 2 == 0 else "L0"
        stripe_lo = "I0" if ((ax - 4) // 7) % 2 == 0 else "L2"
        b.rect(ax, 6, 7, 11, stripe_hi)
        b.rect(ax, 15, 7, 3, stripe_lo)
        b.rect(ax + 1, 18, 5, 1, stripe_lo)  # scalloped hem
    b.line(4, 6, 73, 6, "T0")
    # Display trays of golden crusty rye loaves & braided bread
    for lx in (13, 28, 44, 57):
        b.ellipse(lx + 4, 25, 4.5, 2.5, "Y0")
        b.ellipse(lx + 4, 24, 3.8, 2.0, "Y1")
        b.pset(lx + 3, 23, "Y2")
        b.pset(lx + 5, 24, "T2")  # bread score mark
    b.add_outline("K", selective_hue=True)
    b.save_png(os.path.join(sprites_dir, "building_baker.png"))

    # 4. Uncle Willem's House (130x96 -> 260x192)
    h = PixelCanvas(130, 96)
    # Half-timbered cream plaster facade + stone foundation
    h.rect(8, 36, 114, 56, "L1")
    h.rect(10, 38, 110, 50, "L0")
    h.rect(8, 84, 114, 8, "C1")
    for sx in range(10, 118, 8):
        h.rect(sx, 85, 6, 6, "C2")
    # Half-timber beams
    h.rect(8, 36, 5, 50, "T0")
    h.rect(117, 36, 5, 50, "T0")
    h.rect(8, 44, 114, 3, "T1")
    h.rect(45, 44, 3, 42, "T1")
    h.rect(82, 44, 3, 42, "T1")
    # Pitched terracotta clay-shingle roof + chimney
    _draw_brick_wall(h, 94, 3, 14, 18, "R0", "R1", "R2")
    h.rect(93, 2, 16, 3, "C2")
    _draw_shingles(h, 4, 14, 122, 28, "R0", "R1", "R2")
    h.line(10, 14, 119, 14, "R3")
    h.line(4, 41, 125, 41, "T0")
    # Stepped Flemish left gable accent
    for gx, gw, gy, gh in ((12, 24, 10, 8), (16, 16, 6, 5)):
        _draw_brick_wall(h, gx, gy, gw, gh, "R0", "R2", "R3")
        h.line(gx, gy, gx + gw - 1, gy, "C3")
    # Arched studded oak door + stone doorstep
    h.rect(52, 88, 26, 6, "C2")
    h.line(52, 88, 77, 88, "C3")
    h.rect(54, 54, 22, 34, "T0")
    h.rect(56, 56, 18, 31, "T2")
    h.line(65, 56, 65, 86, "T1")
    h.pset(70, 72, "Y2")  # Brass doorknob
    # Warm leaded-glass mullioned windows + green shutters + flowerbox
    for wx in (17, 93):
        h.rect(wx - 4, 54, 4, 18, "E1")
        h.rect(wx + 20, 54, 4, 18, "E1")
        h.rect(wx, 54, 20, 18, "T0")
        h.rect(wx + 2, 56, 16, 14, "Y1")
        h.rect(wx + 4, 58, 12, 10, "Y2")
        h.rect(wx + 9, 56, 2, 14, "T0")
        h.rect(wx + 2, 62, 16, 2, "T0")
        # Flowerbox
        h.rect(wx, 72, 20, 4, "T1")
        for fx in range(wx + 2, wx + 18, 4):
            h.pset(fx, 70, "G2")
            h.pset(fx + 1, 70, "R3")
    h.add_outline("K", selective_hue=True)
    h.save_png(os.path.join(sprites_dir, "building_house.png"))

    # 5. Brotherhood Frontier Outpost Watchtower Keep (96x68 -> 192x136)
    o = PixelCanvas(96, 68)
    # Soft grounded shadow cast under foundation & porch step
    o.ellipse(48, 63, 41.0, 4.5, (14, 16, 18, 120))
    # Left Timber-Framed Guardhouse Wing (x: 10..56, y: 26..63)
    o.rect(10, 56, 46, 8, "C0")
    _draw_brick_wall(o, 11, 34, 44, 29, "C1", "C2", "C3")
    # Half-timbered warm plaster upper story & pitched slate wing roof
    o.rect(11, 28, 44, 14, "L1")
    o.rect(12, 29, 42, 11, "L0")
    for tx in (11, 24, 38, 51):
        o.rect(tx, 28, 3, 14, "T0")
        o.line(tx + 1, 29, tx + 1, 40, "T1")
    o.rect(10, 41, 46, 3, "T0")
    o.line(10, 41, 55, 41, "T2")
    _draw_shingles(o, 8, 15, 48, 15, "CS", "C1", "C2")
    o.line(12, 15, 53, 15, "C3")
    o.line(8, 29, 55, 29, "T0")
    # Stone chimney rising cleanly from left wing roof
    _draw_brick_wall(o, 14, 5, 9, 12, "C0", "C1", "C2")
    o.rect(13, 4, 11, 2, "C3")
    # Right Tall Circular/Octagonal Ashlar Signal Turret (x: 53..86, y: 18..64)
    _draw_brick_wall(o, 53, 21, 33, 43, "C0", "C1", "C2")
    for qy in range(22, 62, 6):
        o.rect(53, qy, 4, 4, "C3")
        o.rect(82, qy, 4, 4, "C2")
    # Corbeled timber hoarding & notched turret gallery
    o.rect(50, 18, 39, 5, "T0")
    o.rect(51, 19, 37, 3, "T2")
    for cx in range(52, 87, 7):
        o.rect(cx, 15, 4, 4, "C2")
        o.line(cx, 15, cx + 3, 15, "C3")
    # Steep Conical Dark-Slate Turret Roof (y: 3..16) + Iron Weathervane
    for ry in range(4, 17):
        frac = (ry - 4) / 12.0
        hw = int(2 + frac * 19.5)
        cx_t = 69
        for rx in range(cx_t - hw, cx_t + hw + 1):
            col = "C1" if rx < cx_t + 3 else "C0"
            if rx < cx_t - hw // 3 and (rx + ry) % 4 != 0:
                col = "CS2"
            elif (ry % 3 == 0) and (rx + ry) % 2 == 0:
                col = "C2"
            o.pset(rx, ry, col)
    o.line(69, 0, 69, 4, "C3")
    o.rect(70, 1, 5, 2, "Y2")
    o.pset(74, 1, "E2")
    # Recessed Pointed Gothic Sandstone Archway & Iron-Bound Keep Doors + Threshold Step
    o.rect(24, 62, 22, 4, "C2")
    o.line(24, 62, 45, 62, "C3")
    o.rect(25, 42, 20, 21, "C2")
    o.line(25, 42, 44, 42, "C3")
    o.rect(27, 44, 16, 18, "T0")
    o.rect(28, 45, 14, 17, "T2")
    o.line(35, 45, 35, 61, "T0")
    o.rect(28, 50, 14, 2, "C0")
    o.rect(28, 56, 14, 2, "C0")
    o.pset(33, 53, "Y2")
    o.pset(37, 53, "Y2")
    # Warm Leaded-Glass Windows & Lancet Slits
    for wx, wy, ww, wh in ((15, 32, 6, 7), (43, 32, 6, 7), (66, 28, 6, 10), (66, 44, 6, 9)):
        o.rect(wx - 1, wy - 1, ww + 2, wh + 2, "C2")
        o.rect(wx, wy, ww, wh, "T0")
        o.rect(wx + 1, wy + 1, ww - 2, wh - 2, "Y1")
        o.rect(wx + 2, wy + 2, max(1, ww - 4), max(1, wh - 5), "Y3")
        o.line(wx + ww // 2, wy + 1, wx + ww // 2, wy + wh - 2, "T0")
    # Brotherhood Emerald-and-Gold Winged Pennant Banner Mounted on Turret
    o.rect(57, 22, 10, 2, "T2")
    o.rect(58, 24, 8, 13, "E0")
    o.rect(59, 24, 6, 11, "E2")
    o.line(59, 27, 61, 29, "Y3")
    o.line(64, 27, 62, 29, "Y3")
    o.rect(61, 28, 2, 3, "Y2")
    o.pset(61, 29, "Y3")
    # Hanging Iron Signal Beacon Brazier at Corbel Bracket (left of turret)
    o.line(48, 20, 53, 20, "C3")
    o.rect(47, 21, 5, 4, "S")
    o.circle(49, 20, 2, "Y1")
    o.pset(49, 19, "Y3")
    # Creeping Dark-Green Ivy & Moss Clinging to Lower Left & Right Masonry
    for vx, vy, vw, vh in ((11, 51, 5, 9), (14, 57, 6, 5), (78, 53, 6, 9), (74, 58, 5, 4)):
        o.ellipse(vx + vw // 2, vy + vh // 2, vw * 0.55, vh * 0.55, "G0")
        o.pset(vx + 1, vy + 1, "G2")
        o.pset(vx + vw - 2, vy + 2, "G1")
    o.add_outline("K", selective_hue=True)
    o.save_png(os.path.join(sprites_dir, "building_outpost.png"))


