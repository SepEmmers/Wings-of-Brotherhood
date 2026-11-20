"""
Hand-Pixelled Dramatic Hatching Cutscene Diorama & Animation Frames
for Book II Act I — Brabant Fens Sheltered Mill Campfire.

Outputs crisp nearest-neighbor 320x180 diorama & layered sprite animations:
  - cs_hatch_bg.png (320x180): Weather-worn Brabant mill arch, misty alder silhouettes, dithered wet stones & mossy nest
  - cs_hatch_fire_0..3.png (64x72): 4-frame crackling left foreground campfire tongues
  - cs_hatch_boy_watch_0..2.png (96x104): 3-frame organic kneeling 17yo Boy watching -> recoiling -> extending open palm
  - cs_hatch_egg_0..4.png (104x116): 5-frame curved-scale Black-and-Gold Egg pulsing -> cracking -> furnace burst -> bowl
  - cs_hatch_dragon_0..7.png (128x112): 8-frame sleek soot-black & royal gold dragonet emerging -> shaking -> heroic wing unfurl
                                      -> skyward ember-flame cry -> tilting -> stepping forward -> imprinting palm nuzzle
"""

import math
import os
from pixel_art_lib import PAL, PixelCanvas, blend_color


def _qbezier(p0, p1, p2, steps: int = 24):
    pts = []
    for i in range(steps + 1):
        t = i / float(steps)
        mt = 1.0 - t
        x = mt * mt * p0[0] + 2.0 * mt * t * p1[0] + t * t * p2[0]
        y = mt * mt * p0[1] + 2.0 * mt * t * p1[1] + t * t * p2[1]
        pts.append((int(round(x)), int(round(y))))
    return pts


def _draw_poly_curve(c: PixelCanvas, pts, col, thickness: int = 1) -> None:
    for i in range(len(pts) - 1):
        c.line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], col, thickness=thickness)


def _fill_thick_band(c: PixelCanvas, top_pts, bot_pts, col_fn) -> None:
    n = min(len(top_pts), len(bot_pts))
    x_cols = {}
    for i in range(n):
        tx, ty = top_pts[i]
        bx, by = bot_pts[i]
        x0, x1 = min(tx, bx), max(tx, bx)
        for px in range(x0, x1 + 1):
            cur = x_cols.get(px)
            if cur is None:
                x_cols[px] = [min(ty, by), max(ty, by)]
            else:
                cur[0] = min(cur[0], min(ty, by))
                cur[1] = max(cur[1], max(ty, by))
    for px, (y0, y1) in x_cols.items():
        span = max(1, y1 - y0)
        for py in range(y0, y1 + 1):
            v = (py - y0) / float(span)
            c.pset(px, py, col_fn(px, py, v))


def _bayer4(x: int, y: int) -> float:
    m = (
        (0, 8, 2, 10),
        (12, 4, 14, 6),
        (3, 11, 1, 9),
        (15, 7, 13, 5),
    )
    return (m[y & 3][x & 3] + 0.5) / 16.0


def _make_hatch_bg(sprites_dir: str) -> None:
    bg = PixelCanvas(320, 180)
    fire_cx, fire_cy = 38.0, 136.0
    egg_cx, egg_cy = 212.0, 136.0

    # 1. Atmospheric Brabant Midnight Sky & Distant Moonlit Mist (horizon y ~ 92)
    c_zen = (10, 14, 28, 255)
    c_mid = (21, 31, 52, 255)
    c_mist = (44, 58, 78, 255)
    for y in range(106):
        if y < 56:
            col = blend_color(c_zen, c_mid, y / 55.0)
        else:
            col = blend_color(c_mid, c_mist, (y - 56) / 49.0)
        for x in range(320):
            bg.pset(x, y, col)

    # Sparse stars + soft upper moonbeam halo on upper-right reeds
    for sx, sy, b in (
        (24, 22, 1), (78, 28, 0), (144, 21, 0), (196, 25, 1),
        (248, 20, 0), (288, 28, 1), (306, 40, 0), (262, 46, 0),
    ):
        bg.pset(sx, sy, (238, 230, 198, 200 if b else 120))
        if b:
            bg.pset(sx - 1, sy, (176, 190, 216, 90))
            bg.pset(sx + 1, sy, (176, 190, 216, 90))

    # Distant rolling marsh ridge, fen alders & faint Louvain watchtower lantern far east
    for x in range(320):
        sil_y = 85 + int(3.0 * math.sin(x * 0.036) + 2.0 * math.cos(x * 0.095))
        if 252 <= x <= 292:
            sil_y -= 2
        for y in range(sil_y, 108):
            bg.pset(x, y, (20, 28, 36, 255) if y == sil_y else (14, 20, 27, 255))
    # Louvain distant gatehouse silhouette + pinprick crimson lantern far east
    bg.rect(286, 67, 7, 21, (16, 21, 30, 255))
    bg.rect(288, 60, 3, 7, (16, 21, 30, 255))
    bg.pset(289, 73, (224, 88, 62, 225))
    # Calm moonlit marsh channel tucked behind east reeds (`x=246..318, y=98..105`)
    for y in range(98, 106):
        for x in range(246, 318):
            bg.pset(x, y, (18, 29, 44, 255) if y < 103 else (15, 24, 36, 255))
    for rx, ry, rw in ((252, 99, 6), (271, 101, 5), (288, 100, 7), (304, 103, 5), (260, 104, 4)):
        bg.line(rx, ry, rx + rw, ry, (58, 86, 112, 180))

    # Misty swaying cattails & tall marsh reeds flanking camp cleanly
    for rx, rtop, lean in ((12, 58, 1), (20, 50, 0), (268, 62, -1), (279, 51, 1), (295, 56, 0), (309, 64, -1)):
        bg.line(rx, 126, rx + lean * 2, rtop, "G0")
        bg.rect(rx + lean - 1, rtop + 4, 2, 6, "T1")
        bg.pset(rx + lean, rtop + 1, "G2")

    # 2. Weathered Ruined Millstone Arch (organic rounded irregular masonry, NO boxy brick outlines!)
    # Base arch mask spanning `x=82..244, y=38..116` leaving sheltered open vault `x=134..220`
    for y in range(36, 116):
        for x in range(82, 246):
            # Crumbled top silhouette tapering gently at outer shoulders
            top_edge = 44 + (8 if x < 104 else (12 if x > 224 else 0)) + int(math.sin(x * 0.14) * 2.5)
            if y < top_edge:
                continue
            # Semi-circular arch hollow centered at `(177, 114)`, rx=44, ry=58
            arch_u = ((x - 177.0) / 44.0) ** 2 + ((max(0.0, 114.0 - y)) / 58.0) ** 2
            if y > 54 and arch_u < 1.0:
                # Deep hollow interior behind arch
                bg.pset(x, y, (12, 15, 22, 225))
                continue
            # Stone strata variation with soft mortar seams (NO pure black outlines!)
            band_y = y // 11
            seam_y = (y % 11 == 0)
            seam_x = ((x + (band_y % 2) * 14) % 28 == 0)
            tone = (band_y * 3 + (x + (band_y % 2) * 14) // 28) % 4
            if seam_y or seam_x:
                col = (30, 31, 36, 255)
            elif y <= top_edge + 2 and (x + y) % 5 < 3:
                col = PAL["G1"] if (x % 2 == 0) else PAL["G0"]
            elif tone == 0:
                col = PAL["C0"]
            elif tone == 1:
                col = PAL["CS"]
            elif tone == 2:
                col = PAL["C1"]
            else:
                col = (60, 62, 70, 255)
            # Cracked stone edge bevel & warm campfire bounce on arch
            if abs(arch_u - 1.0) < 0.10 and y > 54:
                col = PAL["C2"] if x < 177 else PAL["C0"]
            d_arch = math.hypot((x - fire_cx) * 0.78, (y - fire_cy) * 0.85)
            if d_arch < 140.0 and not (seam_y or seam_x):
                ag = ((140.0 - d_arch) / 140.0) ** 2.1 * 0.44
                col = blend_color(col, PAL["Y1"], ag)
            bg.pset(x, y, col)

    # Ivy vines hanging softly over weathered arch lip
    for vx, vlen in ((142, 13), (160, 9), (198, 12), (214, 15)):
        for dy in range(vlen):
            bg.pset(vx + (dy // 4) % 2, 50 + dy, "G1" if dy % 2 == 0 else "G2")

    # 3. Organic Marsh Meadow, Natural Rounded Ruin Apron & Smooth Dithered Firelight (`y=106..180`)
    for y in range(106, 180):
        for x in range(320):
            # Irregular organic stone slab contour around arch/camp (zero straight rectangular x/y cutoff!)
            apron_d = ((x - 156.0) / 104.0) ** 2 + ((y - 128.0) / 36.0) ** 2
            n_val = math.sin(x * 0.11) * math.cos(y * 0.17) + math.sin((x + y) * 0.08) * 0.5
            in_stone_slab = (apron_d + n_val * 0.14) < 1.0
            if in_stone_slab and n_val > -0.38:
                if abs(n_val + 0.38) < 0.08 or abs(math.sin(x * 0.09 + y * 0.05)) < 0.04:
                    base = (24, 24, 28, 255)
                elif n_val > 0.32:
                    base = PAL["CS"]
                else:
                    base = PAL["C0"]
            else:
                base = (26, 38, 24, 255) if (x * 3 + y * 5) % 11 < 4 else (20, 30, 21, 255)
            if y > 150:
                base = blend_color(base, (10, 12, 16, 255), min(1.0, (y - 150) / 28.0))

            df = math.hypot((x - fire_cx) * 0.68, (y - fire_cy) * 1.15)
            if df < 190.0:
                t_glow = max(0.0, (190.0 - df) / 190.0) ** 2.3
                if t_glow * 1.15 > _bayer4(x, y) * 0.24:
                    warm_c = (246, 152, 54, 255) if df < 44.0 else (208, 108, 40, 255)
                    base = blend_color(base, warm_c, min(0.76, t_glow * 0.78))

            # Smooth warm bounce under egg nest (`(212, 136)`)
            de = math.hypot((x - egg_cx) * 0.78, (y - egg_cy) * 1.45)
            if de < 62.0:
                eg = ((62.0 - de) / 62.0) ** 2.0
                base = blend_color(base, (222, 144, 52, 255), eg * 0.32)

            bg.pset(x, y, base)

    # Foreground grass tufts & wet pebbles for crisp depth
    for tx, ty in ((20, 150), (30, 156), (92, 152), (168, 154), (254, 148), (274, 154)):
        bg.line(tx, ty, tx - 2, ty - 5, "G1")
        bg.line(tx + 2, ty, tx + 3, ty - 6, "G2")

    # 4. Left Foreground Creek-Stone Campfire Pit (`cx=38, cy=136`)
    ring_stones = [
        (22, 138, 6, 4), (29, 143, 7, 4), (38, 145, 7, 4), (48, 143, 7, 4),
        (54, 138, 6, 4), (24, 132, 6, 4), (52, 132, 6, 4),
    ]
    for sx, sy, rx, ry in ring_stones:
        bg.ellipse(sx, sy, rx, ry, "K")
        bg.ellipse(sx, sy, rx - 1, ry - 1, "C1")
        bg.ellipse(sx - 1, sy - 1, max(1, rx - 3), max(1, ry - 2), "C3")
    bg.ellipse(38, 137, 12, 5.5, "T0")
    bg.ellipse(38, 137, 9, 4.0, "R1")
    bg.ellipse(38, 136, 5, 2.2, "Y1")
    bg.line(28, 138, 49, 133, "T1", thickness=3)
    bg.line(30, 133, 48, 139, "T2", thickness=3)
    bg.line(33, 136, 44, 136, "Y2", thickness=2)

    # 5. Sheltered Emerald Cloak Pad & Woven Straw Cradle (`cx=212, cy=136`)
    bg.ellipse(212, 139, 39, 12, (12, 13, 18, 145))
    bg.ellipse(212, 137, 34, 10, "T0")
    bg.ellipse(212, 136, 30, 8, "H0")
    bg.ellipse(212, 135, 23, 5.5, "E0")
    bg.ellipse(210, 134, 18, 4.0, "E1")
    for sx, sy, ex, ey in (
        (178, 135, 168, 140), (184, 140, 175, 145), (239, 135, 250, 139),
        (242, 139, 252, 143), (218, 143, 224, 148), (195, 143, 189, 148),
    ):
        bg.line(sx, sy, ex, ey, "H1")
        bg.pset(ex, ey, "H2")

    bg.save_png(os.path.join(sprites_dir, "cs_hatch_bg.png"))


def _make_hatch_fire_frames(sprites_dir: str) -> None:
    """64x72 flickering campfire flame sprite placed at `(6, 74)` -> fire base `(38, 136)`."""
    for f in range(4):
        c = PixelCanvas(64, 72)
        cx, base_y = 32, 62
        sway = (-3, 1, 3, -1)[f]
        sway2 = (2, -2, 1, -3)[f]
        for dy in range(36):
            u = dy / 35.0
            hw = int(round((1.0 - u ** 0.78) * 13.0 + math.sin(u * math.pi * 2.0 + f * 1.4) * 2.0))
            if hw <= 0:
                continue
            off_x = int(round(sway * u + math.sin(u * 4.5 + f * 1.6) * 2.3))
            py = base_y - dy
            for dx in range(-hw, hw + 1):
                dist = abs(dx) / max(1.0, float(hw))
                col = "Y3" if (dist < 0.35 and u < 0.52) else ("Y2" if (dist < 0.68 and u < 0.76) else ("Y1" if u < 0.88 else "R2"))
                c.pset(cx + off_x + dx, py, col)
        for dy in range(18):
            u = dy / 17.0
            px = cx + sway2 - int(u * 5 * (1 if f % 2 == 0 else -1))
            c.pset(px, base_y - 16 - dy, "Y2" if u < 0.5 else "Y1")
        for sx, sy, col in ((25, 20 - f * 3, "Y2"), (38, 14 - f * 2, "Y3"), (31, 8 - f * 2, "Y1")):
            c.rect(sx, sy, 2, 2, col)
        c.save_png(os.path.join(sprites_dir, f"cs_hatch_fire_{f}.png"))


def _make_hatch_egg_frames(sprites_dir: str) -> None:
    """
    104x116 canvas at `(160, 42)` -> egg center `(212, 110)` resting in nest `(212, 136)`.
    Curved hexagonal/teardrop reptilian obsidian scales (NO rectangular bricks) and
    smooth quadratic-feathered base glow (ZERO rectangular clipping box!).
    """
    cx, cy = 52.0, 70.0
    rx_base, ry_base = 25.0, 32.0

    for stage in range(5):
        c = PixelCanvas(104, 116)
        tilt_x = (-1 if stage == 1 else (1 if stage == 2 else 0))

        # 1. Soft oval glow well inside 104x116 bounds (r < 42 -> x in 10..94, never clips edge!)
        for gy in range(82, 112):
            for gx in range(10, 95):
                d = math.hypot((gx - cx) * 0.90, (gy - 98.0) * 2.1)
                if d < 36.0:
                    a = int(min(135, ((36.0 - d) / 36.0) ** 1.8 * (65 + stage * 22)))
                    if a > 4:
                        c.pset(gx, gy, (248, 174, 62, a))

        crack_split = (stage >= 3)
        bowl_only = (stage == 4)

        for y in range(30, 104):
            for x in range(22, 83):
                ny = (y - cy) / ry_base
                taper = 1.0 - max(0.0, -ny) * 0.25 + max(0.0, ny) * 0.06
                nx = (x - (cx + tilt_x)) / (rx_base * taper)
                r2 = nx * nx + ny * ny
                if r2 > 1.0:
                    continue

                jagged = int(math.sin((x - 24) * 0.48) * 3.5 + math.cos((x - 18) * 0.92) * 2.0)
                crack_y = 67 + jagged if bowl_only else (54 + jagged if stage == 3 else 0)
                if crack_split and y < crack_y:
                    continue

                # Sculpted CURVED overlapping reptilian dragon scales following ovoid curvature!
                curve_y = float(y) - 4.5 * (1.0 - nx * nx)
                row_band = int(curve_y // 6)
                scale_u = ((x + (row_band % 2) * 4.5) % 9.0) / 9.0 - 0.5
                scale_v = (curve_y % 6.0) / 6.0
                # Curved shield bottom boundary per scale cell
                in_scale_seam = (abs(scale_u) > 0.43 and scale_v < 0.72) or (scale_v > 0.80 - abs(scale_u) * 0.45)

                light_fire = max(0.0, (-nx * 0.65 + ny * 0.45 + 0.35))
                light_moon = max(0.0, (-nx * 0.45 - ny * 0.65 + 0.15))

                if r2 > 0.88:
                    col = PAL["DO"]
                elif in_scale_seam:
                    col = (24, 26, 36, 255)
                elif light_moon > 0.55 and y < 74:
                    col = PAL["O3"]
                elif light_fire > 0.60 and x < 54:
                    col = blend_color(PAL["O2"], PAL["Y0"], min(0.75, (light_fire - 0.56) * 1.4))
                elif light_moon > 0.28 or r2 < 0.44:
                    col = PAL["O2"]
                else:
                    col = PAL["O1"]

                # Battle scuff scar from Whispering Pines flight
                if 62 <= x <= 68 and 72 <= y <= 76 and abs((x - 62) - (y - 72)) <= 1:
                    col = PAL["CS2"] if y == 72 else PAL["O0"]

                c.pset(x, y, col)

        # Inlaid Royal Gold Filigree Veins curving organically along shell plates
        vein_paths = [
            _qbezier((36, 76), (48, 80), (58, 92)),
            _qbezier((54, 62), (62, 74), (66, 88)),
            _qbezier((48, 52), (44, 66), (41, 82)),
        ]
        for vp in vein_paths:
            vcol = "Y1" if stage == 0 else ("Y2" if stage <= 2 else "Y1")
            for px, py in vp:
                if (not crack_split or py >= 69):
                    c.pset(px, py, vcol)
                    if stage >= 1 and py % 2 == 0:
                        c.pset(px + 1, py, "Y2")

        if stage == 1:
            f1 = [(56, 40), (50, 48), (54, 56), (47, 65), (52, 74)]
            _draw_poly_curve(c, f1, "Y3", 2)
            _draw_poly_curve(c, [(x - 1, y) for x, y in f1], "Y1", 1)
            c.circle(51, 56, 2, "Y3")
        elif stage == 2:
            cracks = [
                [(56, 39), (49, 49), (55, 58), (46, 68), (52, 79)],
                [(49, 49), (38, 56), (34, 67)],
                [(55, 58), (67, 54), (72, 64)],
                [(46, 68), (39, 77)],
                [(55, 58), (65, 70), (68, 82)],
            ]
            for cr in cracks:
                _draw_poly_curve(c, cr, "Y1", 3)
                _draw_poly_curve(c, cr, "Y3", 1)
            c.circle(52, 57, 4, "Y3")
            for bx0, by0, bx1, by1 in ((42, 46, 28, 30), (60, 46, 76, 30), (52, 40, 52, 22), (38, 60, 22, 56), (68, 58, 84, 52)):
                c.line(bx0, by0, bx1, by1, (255, 228, 128, 185))
        elif stage == 3:
            # Smooth glowing radial amber light halo inside split hollow (no chunky rectangle!)
            for gy in range(42, 60):
                for gx in range(36, 69):
                    d = math.hypot((gx - 52.0) * 0.82, gy - 54.0)
                    if d < 14.0:
                        col = "Y3" if d < 8.5 else "Y2"
                        c.pset(gx, gy, col)
            # Peeking soot snout & bright amber eyes blinking out through the furnace cleft
            c.ellipse(52, 52, 7.0, 4.2, "O0")
            c.ellipse(52, 51, 5.2, 3.0, "O1")
            c.rect(47, 50, 2, 2, "Y3")
            c.rect(55, 50, 2, 2, "Y3")
            c.pset(52, 48, "Y3")
            # Curved hinged top obsidian shell fragments arcing open!
            _fill_thick_band(c, _qbezier((28, 38), (37, 26), (48, 31)), _qbezier((30, 44), (39, 34), (49, 39)),
                             lambda _x, _y, v: PAL["Y3"] if v > 0.85 else (PAL["O3"] if v < 0.25 else PAL["O1"]))
            _fill_thick_band(c, _qbezier((58, 30), (68, 28), (76, 40)), _qbezier((58, 38), (66, 36), (74, 46)),
                             lambda _x, _y, v: PAL["Y2"] if v > 0.85 else (PAL["O2"] if v < 0.3 else PAL["O1"]))
            for x in range(28, 76):
                jagged = int(math.sin((x - 24) * 0.48) * 3.5 + math.cos((x - 18) * 0.92) * 2.0)
                c.pset(x, 54 + jagged, "Y2")
                c.pset(x, 55 + jagged, "Y1")
        elif stage == 4:
            # Dark interior bowl hollow & jagged obsidian rim + tumbled shell shards in moss
            for y in range(62, 74):
                for x in range(32, 72):
                    if ((x - 52) / 18.0) ** 2 + ((y - 68) / 5.2) ** 2 <= 1.0:
                        c.pset(x, y, (14, 15, 22, 235))
            for x in range(28, 76):
                jagged = int(math.sin((x - 24) * 0.48) * 3.5 + math.cos((x - 18) * 0.92) * 2.0)
                c.pset(x, 67 + jagged, "O3")
                c.pset(x, 68 + jagged, "Y1")
            for sx, sy, w, h in ((14, 96, 9, 4), (22, 90, 7, 4), (78, 95, 10, 4), (84, 88, 6, 4), (48, 102, 8, 4)):
                c.ellipse(sx + w * 0.5, sy + h * 0.5, w * 0.5, h * 0.5, "O2")
                c.pset(sx + w // 2, sy + 1, "Y2")

        c.add_outline("DO", selective_hue=True)
        c.save_png(os.path.join(sprites_dir, f"cs_hatch_egg_{stage}.png"))


def _draw_cutscene_wing(c: PixelCanvas, shx: int, shy: int, tip_x: int, tip_y: int, mid_x: int, mid_y: int,
                        bot_drop: int, gold_bright: str = "Y2") -> None:
    top1 = _qbezier((shx, shy), (mid_x, mid_y), (tip_x, tip_y), 28)
    bot_pts = []
    for i, (px, py) in enumerate(top1):
        u = i / float(max(1, len(top1) - 1))
        scallop = abs(math.sin(u * math.pi * 2.5)) * (bot_drop * 0.34)
        depth = int(round((1.0 - u * 0.62) * bot_drop - scallop))
        bot_pts.append((px, py + max(3, depth)))

    def wing_col(px, py, v):
        if v < 0.08 or v > 0.92:
            return PAL["DO"]
        if v < 0.28:
            return PAL["O3"] if gold_bright == "Y3" else PAL["O2"]
        if (px + py) % 7 == 0:
            return PAL["O2"]
        return PAL["O1"] if v < 0.70 else PAL["O0"]

    _fill_thick_band(c, top1, bot_pts, wing_col)
    # Prominent finger webbing spars & subtle golden trailing edge rim so dark wings pop cleanly!
    for u_rib in (0.35, 0.68):
        idx = int(u_rib * (len(bot_pts) - 1))
        c.line(mid_x, mid_y, bot_pts[idx][0], bot_pts[idx][1], "O3")
        c.pset(bot_pts[idx][0], bot_pts[idx][1], "Y2")
    _draw_poly_curve(c, top1, gold_bright, 2)
    c.line(shx, shy + 1, mid_x, mid_y + 1, "Y1")
    c.rect(mid_x - 1, mid_y - 2, 2, 2, "C4")
    c.pset(tip_x, tip_y, "Y3")


def _draw_dragonet_chest_filigree(c: PixelCanvas, cx: int, cy: int, bright: bool = False) -> None:
    """Organic curved ventral gold-seamed belly scales & sternum line wrapping chest contour."""
    main_c = "Y3" if bright else "Y2"
    edge_c = "Y2" if bright else "Y1"
    _draw_poly_curve(c, _qbezier((cx - 2, cy - 7), (cx - 4, cy), (cx - 1, cy + 7)), main_c, 1)
    for dy in (-4, 1, 5):
        _draw_poly_curve(c, _qbezier((cx - 5, cy + dy - 1), (cx - 1, cy + dy + 2), (cx + 3, cy + dy)), edge_c, 1)
        c.pset(cx - 2, cy + dy + 1, main_c)


def _draw_cutscene_neck(c: PixelCanvas, shx: int, shy: int, hx: int, hy: int, bright_gold: bool = False) -> None:
    """Smooth curved obsidian neck bridging torso `(shx, shy)` cleanly up into cranium `(hx, hy)`."""
    cx = (shx + hx) * 0.5 + 3.0
    cy = (shy + hy) * 0.5 + 1.0
    spine = _qbezier((shx, shy), (cx, cy), (hx + 2, hy + 4), 18)
    _draw_poly_curve(c, spine, "O0", 9)
    _draw_poly_curve(c, [(px - 1, py) for px, py in spine], "O1", 6)
    _draw_poly_curve(c, [(px - 2, py) for px, py in spine], "O2", 2)
    # Warm golden throat seam running along front curve
    _draw_poly_curve(c, [(px - 4, py + 1) for px, py in spine], "Y2" if bright_gold else "Y1", 1)


def _draw_cutscene_dragon_head(c: PixelCanvas, hx: int, hy: int, look_dx: int = -1, look_dy: int = 0,
                               mouth_open: bool = False, blink: bool = False, flame_cry: bool = False) -> None:
    c.ellipse(hx, hy, 12.0, 10.0, "O0")
    c.ellipse(hx, hy, 10.2, 8.4, "O1")
    c.ellipse(hx - 1, hy - 2, 7.2, 5.2, "O2")
    c.ellipse(hx - 2, hy - 3, 4.0, 2.4, "O3")

    # Sculpted swept stubby steel-pale horns angling upward-right
    c.line(hx + 2, hy - 8, hx + 11, hy - 18, "O0", thickness=3)
    c.line(hx + 2, hy - 8, hx + 10, hy - 17, "C3", thickness=2)
    c.pset(hx + 11, hy - 18, "Y3")
    c.line(hx - 4, hy - 7, hx + 2, hy - 15, "C2", thickness=2)
    c.pset(hx + 2, hy - 16, "Y2")
    # Swept ear-crest plumes with golden rim
    c.line(hx + 7, hy - 1, hx + 15, hy - 5, "O2", thickness=2)
    c.line(hx + 7, hy, hx + 14, hy - 2, "Y1")

    # Tapered expressive snout facing left (slight upward tilt on roar, clear of forehead crest & eyes)
    mx = hx + look_dx * 10
    my = hy + 2 + look_dy
    c.ellipse(mx, my, 7.0, 4.0 if not mouth_open else 2.8, "O0")
    c.ellipse(mx, my, 5.5, 2.8 if not mouth_open else 1.9, "O1")
    c.line(mx - 4, my - 2, mx + 2, my - 2, "Y2")
    c.pset(mx - 4, my, "Y3")
    if mouth_open:
        c.ellipse(mx - 1, my + 2, 4.8, 2.2, "Y1")
        c.ellipse(mx - 2, my + 2, 3.2, 1.4, "Y3")
        c.line(mx - 5, my + 4, mx + 4, my + 3, "O1", thickness=3)
        c.line(mx - 4, my + 4, mx + 3, my + 4, "Y2")
        if flame_cry:
            # Flame plume shooting cleanly upward-left from open jaws clear of snout & wingtip!
            for i in range(1, 22):
                px = mx - 4 - int(i * 0.42)
                py = my - 2 - int(i * 1.18)
                spread = max(1, i // 5)
                for sx in range(-spread, spread + 1):
                    col = "Y3" if (i < 11 and abs(sx) <= max(1, spread // 2)) else ("Y2" if i < 16 else "Y1")
                    c.pset(px + sx, py, col)

    # Forehead Golden Diamond Prophecy Crest!
    fx, fy = hx - 4, hy - 5 + look_dy // 2
    for dy, hw in ((-2, 0), (-1, 1), (0, 2), (1, 1), (2, 0)):
        c.rect(fx - hw, fy + dy, hw * 2 + 1, 1, "Y3" if abs(dy) < 2 else "Y1")

    # Bright luminous golden-amber eyes
    ex, ey = hx - 4, hy - 1 + look_dy // 2
    if blink:
        c.line(ex - 3, ey + 1, ex + 2, ey + 1, "Y1")
        c.pset(ex - 1, ey, "Y2")
    else:
        c.ellipse(ex, ey, 3.6, 3.2, "DO")
        c.ellipse(ex, ey, 2.8, 2.5, "Y1")
        c.ellipse(ex, ey, 2.0, 2.0, "Y2")
        c.rect(ex, ey - 1, 1, 3, "DO")
        c.pset(ex - 1, ey - 1, "EW")
        c.pset(ex - 2, ey - 1, "Y3")
    c.ellipse(hx - 11, hy - 2 + look_dy // 2, 2.0, 2.2, "Y2")
    c.pset(hx - 11, hy - 2 + look_dy // 2, "EW")


def _make_hatch_dragon_frames(sprites_dir: str) -> None:
    """
    8-frame close-up Dragonet emergence (`128x112`) centered at `(146, 44)` -> nest bowl `(66, 94)`:
      0: clamber_rim    - gripping OVER cs_hatch_egg_4's real shell rim cleanly (no duplicate box bowl!)
      1: hop_out_straw  - scrambling clear onto mossy wool
      2: wet_shake      - vigorous wet shake tossing droplets & dust
      3: wing_unfurl    - heroic wide spread of BOTH swept obsidian wings laced with gold!
      4: ember_cry      - skyward tilted ember-flame cry arching clearly into night mist
      5: settle_tilt    - wings folding softly, curious head-tilt left toward Boy
      6: step_to_palm   - stepping left toward Boy's open palm
      7: imprint_nuzzle - pressing forehead gold crest warmly against Boy's outstretched palm
    """
    for f in range(8):
        c = PixelCanvas(128, 112)

        if f == 0:
            # Frame 0: Seated INSIDE cs_hatch_egg_4 bowl while forepaws grip OVER its jagged rim (`y=75..82`)!
            c.ellipse(66, 70, 12.0, 9.5, "O0")
            c.ellipse(65, 69, 9.5, 7.5, "O1")
            _draw_cutscene_neck(c, 65, 65, 63, 52, False)
            _draw_cutscene_wing(c, 73, 64, 92, 58, 83, 60, 12, "Y1")
            _draw_dragonet_chest_filigree(c, 63, 70, False)
            # Jagged shell rim strip crossing belly cleanly behind hooking forepaws
            for sx in range(44, 88):
                j = int(math.sin((sx - 44) * 0.48) * 3.5 + math.cos((sx - 38) * 0.92) * 2.0)
                c.line(sx, 75 + j, sx, 81, "O1")
                c.pset(sx, 75 + j, "Y1")
            for px in (54, 76):
                c.ellipse(px, 78, 4.2, 3.0, "O2")
                c.pset(px - 2, 80, "C4")
                c.pset(px + 1, 80, "C4")
            _draw_cutscene_dragon_head(c, 63, 52, look_dx=-1, look_dy=-1)

        elif f == 1:
            c.ellipse(60, 96, 22.0, 5.0, (12, 13, 18, 120))
            _draw_poly_curve(c, _qbezier((68, 86), (88, 92), (96, 76)), "O1", 4)
            _draw_poly_curve(c, _qbezier((70, 85), (88, 90), (96, 76)), "Y1", 1)
            c.pset(96, 75, "Y3")
            _draw_cutscene_wing(c, 58, 72, 46, 56, 52, 62, 14, "Y1")
            c.ellipse(61, 81, 15.0, 11.5, "O0")
            c.ellipse(60, 80, 12.0, 9.0, "O1")
            c.ellipse(57, 78, 7.0, 5.5, "O2")
            _draw_cutscene_neck(c, 58, 74, 52, 62, False)
            _draw_dragonet_chest_filigree(c, 58, 81, False)
            c.ellipse(49, 92, 4.0, 2.8, "O2")
            c.ellipse(67, 93, 4.2, 2.8, "O2")
            _draw_cutscene_wing(c, 66, 76, 88, 66, 78, 68, 15, "Y2")
            _draw_cutscene_dragon_head(c, 52, 62, look_dx=-1, look_dy=1, mouth_open=True)

        elif f == 2:
            c.ellipse(58, 96, 22.0, 5.0, (12, 13, 18, 120))
            _draw_poly_curve(c, _qbezier((66, 86), (86, 82), (98, 68)), "O2", 4)
            c.pset(98, 68, "Y2")
            _draw_cutscene_wing(c, 60, 74, 96, 58, 78, 60, 18, "Y2")
            _draw_cutscene_wing(c, 56, 72, 24, 58, 38, 60, 16, "Y1")
            c.ellipse(58, 82, 15.0, 11.0, "O0")
            c.ellipse(57, 81, 12.0, 8.5, "O1")
            _draw_cutscene_neck(c, 55, 74, 48, 66, True)
            _draw_dragonet_chest_filigree(c, 54, 81, True)
            c.ellipse(49, 92, 4.0, 2.8, "O2")
            c.ellipse(66, 92, 4.0, 2.8, "O2")
            _draw_cutscene_dragon_head(c, 48, 66, look_dx=-1, look_dy=2, blink=True)
            for ax, ay in ((32, 54), (30, 62), (62, 52), (66, 58), (82, 48), (22, 72), (92, 78)):
                c.pset(ax, ay, "Y3" if ax % 2 == 0 else "W4")
                c.pset(ax + 1, ay + 1, "Y1")

        elif f == 3:
            c.ellipse(64, 98, 28.0, 5.5, (14, 15, 20, 135))
            tail_pts = _qbezier((70, 88), (94, 98), (112, 78))
            _draw_poly_curve(c, tail_pts, "O0", 5)
            _draw_poly_curve(c, tail_pts, "O2", 2)
            c.ellipse(113, 76, 3.0, 2.0, "Y2")
            c.pset(114, 76, "Y3")
            _draw_cutscene_wing(c, 56, 72, 10, 42, 34, 48, 28, "Y3")
            _draw_cutscene_wing(c, 70, 72, 118, 40, 94, 48, 28, "Y3")
            c.ellipse(62, 80, 14.0, 13.5, "O0")
            c.ellipse(61, 79, 11.2, 11.0, "O1")
            c.ellipse(58, 77, 6.5, 7.0, "O2")
            _draw_cutscene_neck(c, 60, 70, 57, 56, True)
            _draw_dragonet_chest_filigree(c, 58, 79, True)
            c.ellipse(52, 93, 4.5, 3.0, "O2")
            c.ellipse(70, 93, 4.5, 3.0, "O2")
            _draw_cutscene_dragon_head(c, 57, 56, look_dx=-1, look_dy=-1)

        elif f == 4:
            c.ellipse(62, 98, 28.0, 5.5, (14, 15, 20, 135))
            _draw_poly_curve(c, _qbezier((70, 88), (96, 94), (114, 70)), "O1", 4)
            c.ellipse(115, 68, 3.0, 2.0, "Y3")
            _draw_cutscene_wing(c, 56, 70, 14, 34, 34, 38, 28, "Y3")
            _draw_cutscene_wing(c, 70, 70, 116, 28, 92, 34, 29, "Y3")
            c.ellipse(61, 78, 14.0, 13.5, "O0")
            c.ellipse(60, 77, 11.2, 11.0, "O1")
            _draw_cutscene_neck(c, 60, 68, 58, 48, True)
            _draw_dragonet_chest_filigree(c, 58, 78, True)
            c.ellipse(52, 93, 4.5, 3.0, "O2")
            c.ellipse(70, 93, 4.5, 3.0, "O2")
            _draw_cutscene_dragon_head(c, 58, 47, look_dx=-1, look_dy=-2, mouth_open=True, flame_cry=True)

        elif f == 5:
            c.ellipse(54, 96, 22.0, 5.0, (12, 13, 18, 120))
            _draw_poly_curve(c, _qbezier((62, 86), (82, 90), (94, 82)), "O1", 4)
            c.pset(94, 82, "Y2")
            _draw_cutscene_wing(c, 58, 72, 84, 56, 74, 58, 17, "Y2")
            c.ellipse(53, 82, 14.5, 11.0, "O0")
            c.ellipse(52, 81, 11.5, 8.5, "O1")
            _draw_cutscene_neck(c, 49, 75, 42, 64, False)
            _draw_dragonet_chest_filigree(c, 48, 82, False)
            c.ellipse(42, 92, 4.2, 2.8, "O2")
            c.ellipse(60, 92, 4.2, 2.8, "O2")
            _draw_cutscene_dragon_head(c, 42, 64, look_dx=-1, look_dy=1)

        elif f == 6:
            c.ellipse(38, 96, 22.0, 5.0, (12, 13, 18, 120))
            _draw_poly_curve(c, _qbezier((48, 86), (68, 92), (82, 80)), "O1", 4)
            c.pset(82, 80, "Y2")
            _draw_cutscene_wing(c, 42, 74, 70, 58, 58, 62, 16, "Y2")
            c.ellipse(39, 82, 14.5, 10.5, "O0")
            c.ellipse(38, 81, 11.5, 8.2, "O1")
            _draw_cutscene_neck(c, 34, 75, 26, 64, False)
            _draw_dragonet_chest_filigree(c, 33, 82, False)
            c.ellipse(24, 88, 3.8, 2.6, "O2")
            c.ellipse(46, 92, 4.2, 2.8, "O2")
            _draw_cutscene_dragon_head(c, 26, 64, look_dx=-1, look_dy=0)

        elif f == 7:
            c.ellipse(32, 96, 22.0, 5.0, (12, 13, 18, 120))
            _draw_poly_curve(c, _qbezier((42, 86), (62, 94), (76, 86)), "O1", 4)
            c.pset(76, 86, "Y3")
            # Gently tucked resting shoulder wing curved down along back so egg rim stays crisp behind
            _draw_cutscene_wing(c, 36, 77, 56, 82, 48, 73, 10, "Y1")
            c.ellipse(34, 84, 14.5, 10.5, "O0")
            c.ellipse(33, 83, 11.5, 8.2, "O1")
            _draw_cutscene_neck(c, 28, 76, 18, 65, True)
            _draw_dragonet_chest_filigree(c, 28, 83, True)
            c.ellipse(22, 93, 4.0, 2.8, "O2")
            c.ellipse(41, 93, 4.2, 2.8, "O2")
            # Forehead diamond touching right against Boy's outstretched palm at local `x~4..14, y~64`!
            _draw_cutscene_dragon_head(c, 18, 65, look_dx=-1, look_dy=1)

        c.add_outline("DO", selective_hue=True)
        c.save_png(os.path.join(sprites_dir, f"cs_hatch_dragon_{f}.png"))


def _make_hatch_boy_frames(sprites_dir: str) -> None:
    """
    96x104 close-up organic kneeling 17-year-old Boy at `(58, 52)` -> knees resting naturally on flagstones,
    cloak flowing softly backward-left so foreground campfire at `(38, 136)` stays bright & unobstructed!
      0: tense_watch     - hands clasped tensely before knees, alert guarded profile
      1: recoil_gasp     - leaning back lit by bright molten-gold burst, shielding eyes
      2: palm_out_wonder - reaching calm bare right palm forward (`x~90, y~62` -> screen `(148, 114)`)
    """
    for f in range(3):
        c = PixelCanvas(96, 104)
        lean = 2 if f == 0 else (-4 if f == 1 else 3)
        head_y = 24 + (1 if f == 0 else (-2 if f == 1 else 2))

        # 1. Grounded Dark Slate Trousers & Kneeling Worn Leather Boot (`x=28..62, y=72..98`)
        c.ellipse(44 + lean // 2, 97, 22.0, 4.5, (12, 13, 18, 130))  # contact shadow
        c.ellipse(46 + lean, 84, 13.0, 10.0, "S")
        c.ellipse(48 + lean, 82, 10.0, 7.5, "C1")
        # Kneeling front boot resting forward-right & rear heel folded cleanly left
        c.ellipse(54 + lean, 92, 7.5, 4.5, "T0")
        c.ellipse(55 + lean, 91, 5.5, 3.2, "T2")
        c.ellipse(30 + lean // 2, 92, 6.5, 4.5, "T0")
        c.ellipse(31 + lean // 2, 91, 4.5, 3.0, "T1")

        # 2. Natural Draped Forest-Emerald Jerkin & Sleek Cape Tail (`x=18..56, y=38..88`, no chunky bulge!)
        for y in range(38, 88):
            u = (y - 38) / 49.0
            x0 = int(26 + lean * 0.4 - math.sin(min(1.0, u * 1.15) * math.pi * 0.7) * 9 - max(0.0, u - 0.5) * 4)
            x1 = int(49 + lean + math.sin(min(1.0, u * 1.45) * math.pi * 0.5) * 8 - max(0.0, u - 0.65) * 16)
            for x in range(max(12, x0), min(68, x1)):
                col = PAL["E1"]
                if x >= x1 - 3 and y < 78:
                    rim_t = 0.56 if f == 1 else 0.32
                    col = blend_color(PAL["E3"], PAL["Y2"], rim_t)
                elif x <= x0 + 3:
                    col = PAL["DE"] if x == x0 else PAL["E0"]
                elif x == x0 + 6 and y > 48:
                    col = PAL["E0"]
                c.pset(x, y, col)

        # Crossed worn saddle-leather harness strap & brass carabiner on jerkin chest
        _draw_poly_curve(c, _qbezier((26 + lean // 2, 41), (39 + lean, 56), (48 + lean, 72)), "T0", 5)
        _draw_poly_curve(c, _qbezier((27 + lean // 2, 41), (40 + lean, 56), (49 + lean, 72)), "T2", 2)
        c.rect(40 + lean, 56, 4, 4, "Y1")
        c.pset(41 + lean, 57, "Y3")

        # Draped emerald cloak collar cowl
        c.ellipse(35 + lean, 40, 12.0, 5.0, "E0")
        c.ellipse(38 + lean, 39, 9.5, 3.4, "E2")

        # 3. Expressive Right-Facing Close-Up Head (`B0..B2` hair + `P2/P3` warm firelit profile)
        hx = 40 + lean
        hy = head_y
        c.rect(hx - 4, hy + 8, 8, 8, "P0")
        c.ellipse(hx + 4, hy + 1, 9.0, 10.0, "P1")
        c.ellipse(hx + 5, hy, 7.6, 8.4, "P2")
        c.rect(hx + 11, hy - 2, 3, 5, "P2")
        c.pset(hx + 13, hy, "P3")
        c.line(hx + 10, hy + 6, hx + 12, hy + 6, "PK")
        if f == 1:
            c.rect(hx + 10, hy + 5, 2, 2, "P0")
        hl_col = PAL["Y3"] if f == 1 else blend_color(PAL["P3"], PAL["Y2"], 0.34)
        c.ellipse(hx + 9, hy + 2, 2.5, 2.5, hl_col)

        brow_dy = -1 if f == 1 else (0 if f == 2 else 1)
        c.line(hx + 7, hy - 4 + brow_dy, hx + 12, hy - 3 + brow_dy, "B0", 2)
        c.rect(hx + 8, hy - 2, 3, 2, "EW")
        c.pset(hx + 10, hy - 1, "S" if f != 2 else "B1")
        if f == 1:
            c.pset(hx + 10, hy - 2, "Y3")

        c.ellipse(hx - 2, hy - 3, 10.0, 10.5, "B0")
        c.ellipse(hx - 1, hy - 5, 8.2, 8.2, "B1")
        c.line(hx - 2, hy - 11, hx + 11, hy - 6, "B2", 2)
        c.line(hx + 3, hy - 9, hx + 13, hy - 5, "B1", 2)
        c.line(hx - 10, hy - 1, hx - 7, hy + 8, "B0", 2)

        # 4. Forearm & Hand Expression per Beat
        if f == 0:
            c.line(38 + lean, 53, 57 + lean, 64, "E2", 5)
            c.line(39 + lean, 52, 57 + lean, 63, "T2", 2)
            c.ellipse(61 + lean, 64, 5.2, 4.2, "P2")
            c.ellipse(62 + lean, 63, 3.2, 2.4, "P3")
        elif f == 1:
            c.line(41 + lean, 51, 61 + lean, 43, "E2", 5)
            c.ellipse(65 + lean, 41, 4.8, 3.8, "P2")
            c.ellipse(66 + lean, 40, 2.8, 2.4, "Y3")
        else:
            c.line(42 + lean, 53, 79, 63, "E2", 6)
            c.line(44 + lean, 51, 79, 61, "E3", 2)
            c.rect(77, 59, 4, 6, "T2")
            c.ellipse(85, 62, 5.5, 4.0, "P2")
            c.ellipse(86, 61, 4.0, 2.5, "P3")
            c.line(87, 60, 91, 61, "P3")

        c.add_outline("K", selective_hue=True)
        c.save_png(os.path.join(sprites_dir, f"cs_hatch_boy_watch_{f}.png"))


def generate_hatching_cutscene_art(sprites_dir: str) -> None:
    os.makedirs(sprites_dir, exist_ok=True)
    _make_hatch_bg(sprites_dir)
    _make_hatch_fire_frames(sprites_dir)
    _make_hatch_egg_frames(sprites_dir)
    _make_hatch_dragon_frames(sprites_dir)
    _make_hatch_boy_frames(sprites_dir)
