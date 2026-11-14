"""
Stylized pixel-art terrain, rivers, waterfalls, cliffs, bridges, dragon lair,
signal flare, wreckage landmarks, and hand-inked cartography stamps
for Frontier Wilds & Border Survey Map.
"""

import math
import os
from pixel_art_lib import PAL, PixelCanvas, blend_color


def _make_terrain_and_verges(sprites_dir: str):
    # 1. Seamless 32x32 Packed Woodland Earth Road Tile (no horizontal row bands)
    dirt = PixelCanvas(32, 32, PAL["T1"])
    for y in range(32):
        for x in range(32):
            h = ((x * 31 + y * 57) ^ (x * 13 + y * 7)) % 37
            h2 = ((x * 17 + y * 43) ^ (x * 5 - y * 11)) % 19
            col = "T1"
            if h < 7:
                col = "T0"
            elif h == 34:
                col = "T2"
            elif h == 35:
                col = "R0"  # reddish pine-needle loam fleck
            elif h2 == 0 and (x + y * 2) % 3 == 0:
                col = "T0"
            dirt.pset(x, y, col)
    # Scattered natural gravel bits & fallen moss/pine flecks (diagonal & organic, zero horizontal stripes)
    for px, py, pc in (
        (4, 3, "C1"), (5, 4, "C2"), (17, 6, "C0"), (25, 14, "C1"),
        (11, 16, "C2"), (28, 27, "C1"), (7, 26, "H0"), (21, 3, "H0"),
        (14, 13, "T2"), (24, 18, "T2"), (3, 18, "G0"), (19, 28, "G0"),
        (9, 10, "T0"), (10, 11, "T0"), (22, 22, "T0"), (23, 21, "T0"),
    ):
        dirt.pset(px, py, pc)
    dirt.save_png(os.path.join(sprites_dir, "tile_forest_dirt.png"))

    # 2. Seamless 32x32 Obsidian Hollow Crater Basalt/Ash Tile
    ash = PixelCanvas(32, 32, PAL["N"])
    for y in range(32):
        for x in range(32):
            h = ((x * 23 + y * 41) ^ (x * 11 + y * 19)) % 31
            if h < 8:
                col = "K"
            elif h < 17:
                col = "O0"
            elif h < 26:
                col = "C0"
            elif h < 29:
                col = "C1"
            else:
                col = "O1"
            ash.pset(x, y, col)
    # Fractured stone cracks & fallen iridescent dragon scale glints
    ash.line(3, 6, 13, 14, "K")
    ash.line(18, 22, 28, 17, "K")
    ash.line(9, 25, 16, 20, "C1")
    for sx, sy in ((8, 8), (22, 11), (13, 27), (26, 25)):
        ash.pset(sx, sy, "O2")
        ash.pset(sx + 1, sy, "O3")
    for ex, ey in ((19, 13), (11, 18)):
        ash.pset(ex, ey, "R0")
        ash.pset(ex, ey - 1, "Y0")
    ash.save_png(os.path.join(sprites_dir, "tile_lair_basalt.png"))

    # 3. Seamless 32x32 Frost Cliff Slate Tile
    fr = PixelCanvas(32, 32, PAL["C1"])
    for y in range(32):
        for x in range(32):
            h = ((x * 19 + y * 37) ^ (x * 9 + y * 23)) % 23
            if h < 5:
                fr.pset(x, y, "CS")
            elif h < 13:
                fr.pset(x, y, "C2")
            elif h == 20:
                fr.pset(x, y, "CS2")
            elif h == 21:
                fr.pset(x, y, "W4")
    fr.line(4, 9, 14, 12, "C0")
    fr.line(17, 21, 29, 24, "C0")
    fr.save_png(os.path.join(sprites_dir, "tile_frost_slate.png"))

    # 4. Crisp Pixel Road & Clearing Verge Tufts (24x24 -> 48x48)
    for var in (0, 1):
        vt = PixelCanvas(24, 24)
        for py in range(4, 20):
            for px in range(4, 20):
                dx = (px - 11.5) / 8.0
                dy = (py - 11.5) / 8.0
                d = math.sqrt(dx * dx + dy * dy)
                h = ((px * 29 + py * 43 + var * 31) ^ (px * 7)) % 19
                if d + ((h % 5) - 2) * 0.08 < 0.72:
                    if h < 6:
                        vt.pset(px, py, "T1")
                    elif h < 11:
                        vt.pset(px, py, "T0")
                    elif h < 15:
                        vt.pset(px, py, "G0")
                    elif h < 18:
                        vt.pset(px, py, "G1")
                    else:
                        vt.pset(px, py, "H0")
        # Grass blade wisps & tiny pebbles protruding into verge
        vt.pset(7, 8 + var, "G2")
        vt.pset(15, 6 + var, "G2")
        vt.pset(12, 16 - var, "C1")
        vt.pset(13, 16 - var, "C2")
        vt.save_png(os.path.join(sprites_dir, f"prop_trail_verge_{var}.png"))

    # 5. Pixel-Art Riverbank Sedge & Wet Overhanging Turf Verge (24x24 -> 44x44)
    for var in (0, 1):
        rb = PixelCanvas(24, 24)
        for py in range(4, 20):
            for px in range(4, 20):
                d = math.hypot(px - 11.5, py - 11.5)
                h = ((px * 17 + py * 37 + var * 29) ^ (px + py * 5)) % 17
                if d + ((h % 4) - 1.5) * 0.72 < 6.8:
                    col = "T0" if h < 4 else ("G0" if h < 11 else ("G1" if h < 15 else "C0"))
                    rb.pset(px, py, col)
        # Mossy wet bank stone & reeds overhanging river edge
        rb.ellipse(9 + var, 13, 3.2, 2.3, "C0")
        rb.ellipse(9 + var, 12, 2.6, 1.8, "C2")
        rb.pset(8 + var, 11, "C3")
        rb.pset(15 - var, 14, "W3")
        rb.pset(16 - var, 14, "W4")
        rx = 12 + var * 2
        rb.line(rx, 11, rx - 1, 5, "G2")
        rb.line(rx + 2, 12, rx + 3, 6, "G1")
        rb.line(rx - 2, 13, rx - 3, 7, "G1")
        rb.pset(rx - 1, 5, "H1")
        rb.save_png(os.path.join(sprites_dir, f"prop_riverbank_edge_{var}.png"))

    # 5b. Angular Half-Submerged Mossy River Boulders (24x24 -> 32x32, NO outer halo ring!)
    for var in (0, 1):
        rs = PixelCanvas(24, 24)
        # Craggy multi-facet stone protruding smoothly out of water/shoreline
        if var == 0:
            rs.ellipse(12, 12, 5.4, 4.2, "K")
            rs.ellipse(12, 12, 4.5, 3.3, "C0")
            rs.ellipse(11, 11, 3.8, 2.5, "C1")
            rs.ellipse(10, 10, 2.5, 1.7, "C2")
            rs.pset(9, 9, "C3")
            rs.pset(10, 9, "C4")
            rs.ellipse(13, 10, 1.9, 1.3, "G1")
            rs.pset(13, 9, "G2")
        else:
            rs.ellipse(11, 13, 5.0, 3.8, "K")
            rs.ellipse(15, 11, 3.4, 2.8, "K")
            rs.ellipse(11, 12, 4.1, 3.0, "C1")
            rs.ellipse(15, 11, 2.6, 2.0, "C1")
            rs.ellipse(10, 11, 2.6, 1.8, "C2")
            rs.pset(9, 10, "C3")
            rs.pset(15, 10, "C3")
            rs.ellipse(12, 12, 1.8, 1.2, "G0")
            rs.pset(12, 11, "G2")
        # Delicate upstream foam ripple curling ONLY at the water-facing top/front crest
        for wx_r, wy_r, wc in ((8, 8, "W4"), (9, 7, "W5"), (11, 7, "W5"), (13, 7, "W4"), (15, 8, "W3"), (8, 16, "W3"), (13, 16, "W3")):
            rs.pset(wx_r, wy_r, wc)
        rs.save_png(os.path.join(sprites_dir, f"prop_river_stone_{var}.png"))

    # 5c. Feathered Frost Rime & Hoarfrost Grass Transition Clusters (24x24 -> 48x48)
    for var in (0, 1):
        ff = PixelCanvas(24, 24)
        for py in range(3, 21):
            for px in range(3, 21):
                d = math.hypot(px - 11.5, py - 11.5)
                h = ((px * 23 + py * 31 + var * 17) ^ (px * 11 - py * 7)) % 23
                if d + ((h % 5) - 2) * 0.75 < 7.2:
                    if h < 4:
                        col = "W4"
                    elif h < 9:
                        col = "CS2"
                    elif h < 14:
                        col = "CS"
                    elif h < 19:
                        col = "C2"
                    else:
                        col = "G1"
                    ff.pset(px, py, col)
        for ix, iy in ((8 + var, 8), (15, 10 - var), (10, 15), (14, 14)):
            ff.pset(ix, iy, "W5")
            ff.pset(ix + 1, iy, "CS2")
        ff.save_png(os.path.join(sprites_dir, f"prop_frost_feather_{var}.png"))

    # 6. Animated River Foam Crests & Bridge Pier Wakes
    for frame in (0, 1):
        rf = PixelCanvas(16, 12)
        sh = frame * 2
        rf.line(2 + sh, 4, 7 + sh, 4, "W4")
        rf.line(4 + sh, 5, 9 + sh, 5, "W5")
        rf.line(3, 8, 6, 8, "W3")
        rf.pset(11 - sh, 6, "W4")
        rf.save_png(os.path.join(sprites_dir, f"prop_river_foam_{frame}.png"))

        pw = PixelCanvas(16, 16)
        dy = frame * 2
        pw.line(8, 2 + dy, 4, 9 + dy, "W4")
        pw.line(8, 2 + dy, 12, 9 + dy, "W4")
        pw.pset(8, 1 + dy, "W5")
        pw.pset(5, 8 + dy, "W3")
        pw.pset(11, 8 + dy, "W3")
        pw.save_png(os.path.join(sprites_dir, f"prop_pier_wake_{frame}.png"))


def _make_cliffs_and_waterfalls(sprites_dir: str):
    import random

    # 1. Seamless Horizontal Escarpment Cliffs (38x46 -> 76x92, High North Plateau -> Sheer South Drop)
    for var in (0, 1):
        rng = random.Random(410 + var * 37)
        ch = PixelCanvas(38, 46)
        # Long dark drop shadow falling southward onto the sunken basin grass
        ch.rect(0, 35, 38, 8, (10, 12, 18, 120))
        ch.rect(0, 41, 38, 4, (10, 12, 18, 55))
        # Tall exposed granite cliff escarpment (y=8..37 so grass lip overlaps stone seamlessly with zero pinholes!)
        for y in range(8, 37):
            for x in range(38):
                roll = rng.random()
                strata = ((x // 5 + y // 6 + var) % 3 == 0)
                col = "C1"
                if y <= 14:
                    col = "C3" if (roll < 0.62 or y == 12) else "C2"  # crisp sun-struck upper plateau brink!
                elif y >= 33:
                    col = "C0"  # deep recessed cliff base overhang
                elif y in (19, 26) and roll < 0.58:
                    col = "C2" if y == 19 else "C0"
                elif strata and roll < 0.25:
                    col = "C2"
                elif roll < 0.20:
                    col = "C0"
                ch.pset(x, y, col)
        # Natural diagonal rock-step fissures (avoid vertical ladder symmetry)
        for fx in (8 + var * 5, 25 - var * 4):
            cx_f = fx
            for fy in range(13, 35):
                if rng.random() < 0.42:
                    cx_f += rng.choice((-1, 0, 1))
                px_c = max(1, min(36, cx_f))
                ch.pset(px_c, fy, "K")
                ch.pset(px_c + 1, fy, "C3" if fy < 22 else "C0")
        # Irregular overhanging turf & moss lip along TOP edge (north plateau grass blends seamlessly with alpha=0 above!)
        hang_depth = [4, 5, 6, 5, 4, 4, 6, 7, 5, 4, 4, 5, 6, 5, 4, 5, 6, 5, 4]
        for idx, x in enumerate(range(38)):
            top_y = 6 + ((x * 3 + var * 2) % 3)
            depth = hang_depth[(idx + var * 5) % len(hang_depth)] + (1 if idx % 5 == 0 else 0)
            for y in range(top_y, min(15, top_y + depth)):
                if y == top_y + depth - 1:
                    col = "G0"
                elif y <= top_y + 1:
                    col = "G2" if (x + idx) % 3 != 0 else "G3"
                else:
                    col = "G1"
                ch.pset(x, y, col)
            # Crisp dark lip shadow right under grass overhang so rim pops off the stone!
            ch.pset(x, min(15, top_y + depth), "K")
        # Clumps of base scree stones & damp moss tucked cleanly against bottom toe
        ch.rect(5, 34, 6, 2, "C0")
        ch.pset(7, 33, "C2")
        ch.rect(24, 34, 5, 2, "C0")
        ch.pset(26, 33, "G1")
        ch.line(0, 36, 37, 36, "K")
        ch.save_png(os.path.join(sprites_dir, f"prop_cliff_face_h_{var}.png"))

    # 2. Seamless Vertical Escarpment Cliffs (42x36 -> 84x72, High East Plateau -> Sheer West Drop, ZERO center crack!)
    for var in (0, 1):
        rng = random.Random(710 + var * 43)
        cv = PixelCanvas(42, 36)
        for y in range(36):
            # Subtle natural rock wobble along west foot and east crest (never ruler-straight, never zipper-split!)
            wob_w = int(math.sin(y * 0.35 + var * 1.7) * 1.4)
            wob_e = int(math.cos(y * 0.30 + var * 1.1) * 1.2)
            foot_x = 10 + wob_w      # west foot hitting sunken basin
            crest_x = 28 + wob_e     # bright rocky crest beneath east grassy rim
            turf_end = 35 + ((y * 5 + var) % 3)  # jagged east grass overhang blending seamlessly onto high eastern plateau
            # Long soft cliff shadow extending westward across sunken basin floor (x: foot_x-8 .. foot_x)
            for sx in range(max(0, foot_x - 8), foot_x):
                dist_f = foot_x - sx
                a_shad = 115 if dist_f <= 2 else (78 if dist_f <= 5 else 38)
                cv.pset(sx, y, (10, 12, 18, a_shad))
            # West foot dark base border
            cv.pset(foot_x, y, "K")
            # West-facing terraced granite slope (x: foot_x+1 .. crest_x+1)
            for x in range(foot_x + 1, crest_x + 2):
                frac_e = (x - foot_x) / max(1.0, float(crest_x + 1 - foot_x))
                roll = rng.random()
                col = "C1"
                if x >= crest_x - 2:
                    col = "C3" if roll < 0.72 else "C2"  # bright plateau rim catching light
                elif x <= foot_x + 3:
                    col = "C0"  # deep foot undercut
                elif frac_e > 0.65 and roll < 0.45:
                    col = "C2"
                elif roll < 0.16:
                    col = "C0"
                # Subtle stepped horizontal shelf strata descending westward
                if (y + (x // 4) + var) % 7 == 0 and foot_x + 2 < x < crest_x - 2:
                    col = "C0" if roll < 0.65 else "C2"
                cv.pset(x, y, col)
            # East grassy plateau rim overlapping the stone crest (dissolves cleanly into eastern grass!)
            cv.pset(crest_x + 1, y, "K" if y % 4 != 0 else "G0")
            for gx in range(crest_x + 2, min(42, turf_end)):
                col_g = "G1"
                if gx == crest_x + 2:
                    col_g = "G0"
                elif (gx + y) % 4 == 0:
                    col_g = "G2"
                elif gx > turf_end - 2:
                    col_g = "G1" if (y + var) % 2 == 0 else "G0"
                cv.pset(gx, y, col_g)
        # Asymmetric diagonal cliff step fissures & mossy crevices facing west
        for start_y, dx_len in ((5 + var * 4, 8), (19 - var * 3, 9), (28, 6)):
            for step_d in range(dx_len):
                fy = (start_y + step_d // 2) % 36
                fx = 25 - step_d * 2
                if 11 <= fx <= 27:
                    cv.pset(fx, fy, "K")
                    cv.pset(fx, min(35, fy + 1), "C2")
        cv.ellipse(21, 10 + var * 3, 2.2, 1.5, "G0")
        cv.pset(22, 10 + var * 3, "G2")
        cv.ellipse(15, 25 - var * 2, 2.4, 1.6, "G1")
        cv.pset(16, 24 - var * 2, "G2")
        cv.save_png(os.path.join(sprites_dir, f"prop_cliff_face_v_{var}.png"))

    # 3. Seamless Concave-Basin NE Plateau Corner (42x44 -> 84x88, crest L-corner at local (28, 14) matching h & v tiles!)
    cc = PixelCanvas(42, 44)
    rng_c = random.Random(905)
    for y in range(6, 44):
        for x in range(0, 42):
            if y < 14 or x > 28:
                # Upper L-shaped plateau turf (North y<14 and East x>28) meeting horizontal/vertical walls cleanly
                in_turf = (y >= 7 or x >= 27) and (x <= 39 or y <= 18)
                if in_turf:
                    hh = ((x * 23 + y * 41) ^ (x * 7 + y * 13)) % 23
                    col = "G2" if hh < 4 else ("G0" if hh > 18 else "G1")
                    cc.pset(x, y, col)
            else:
                # True signed distance from L-shaped cliff crest (y=14 left, x=28 down) with slight inner curve
                dx = 28.0 - float(x)
                dy = float(y) - 14.0
                ed = min(dx, dy) + (2.4 if (dx < 16.0 and dy < 16.0 and math.hypot(max(0.0, 16.0 - dx), max(0.0, 16.0 - dy)) < 12.0) else 0.0)
                if ed <= 2.0:
                    cc.pset(x, y, "K" if ed > 0.9 else "G0")
                elif ed <= 5.5:
                    cc.pset(x, y, "C3" if rng_c.random() < 0.72 else "C2")
                elif ed <= 18.0:
                    col = "C1"
                    if ed >= 15.5:
                        col = "C0"
                    elif rng_c.random() < 0.22:
                        col = "C0"
                    elif rng_c.random() > 0.82:
                        col = "C2"
                    cc.pset(x, y, col)
                elif ed <= 24.5:
                    a_s = 115 if ed <= 21.0 else 55
                    cc.pset(x, y, (10, 12, 18, a_s))
    # Fissures curving diagonally down the headland wall & moss tuft on crest
    cc.line(18, 22, 11, 29, "K")
    cc.line(19, 23, 12, 30, "C2")
    cc.ellipse(25, 16, 2.4, 1.6, "G0")
    cc.pset(26, 15, "G2")
    cc.save_png(os.path.join(sprites_dir, "prop_cliff_corner.png"))

    # 3b. Organic Rounded Cliff Shoulders (38x46 -> 76x92, grassy plateau brow + curved mossy slope into turf)
    for side in ("l", "r"):
        rng_t = random.Random(940 + (0 if side == "l" else 77))
        ct = PixelCanvas(38, 46)
        for x in range(38):
            # t_in = 1.0 abuts the cliff/waterfall; t_in = 0.0 melts softly into forest turf
            t_in = (float(x) / 37.0) if side == "l" else (float(37 - x) / 37.0)
            if t_in < 0.14:
                continue
            fade_t = min(1.0, (t_in - 0.14) / 0.86)
            # Keep upper grassy brow nearly level (gentle swell), curve only the lower cliff toe upward
            y_top = 12 + (1 if fade_t < 0.45 else 0)
            y_bot = int(round(13.0 + 23.0 * (fade_t ** 0.62)))
            if y_bot <= y_top:
                continue

            # Soft overhanging grassy plateau turf above the brow
            brow_depth = 4 if fade_t > 0.55 else max(1, int(round(4.0 * fade_t / 0.55)))
            for y in range(max(7, y_top - brow_depth), y_top):
                edge_fade = min(1.0, fade_t / 0.55)
                if fade_t < 0.50 and rng_t.random() > edge_fade * 1.15:
                    continue
                col_g = "G2" if (x + y) % 5 == 0 else ("G0" if y == y_top - 1 else "G1")
                ct.pset(x, y, col_g)

            # Upper brow rim fades from dark crevice K into soft shadow-moss G0
            if fade_t >= 0.48:
                ct.pset(x, y_top, "K" if fade_t >= 0.68 else "C0")
            elif rng_t.random() < fade_t * 1.6:
                ct.pset(x, y_top, "G0")

            # Cliff face strata transitioning naturally into mossy hillside
            height = max(1, y_bot - y_top)
            for y in range(y_top + 1, y_bot):
                rel = float(y - y_top) / float(height)
                if fade_t >= 0.52:
                    if rel < 0.22:
                        col_r = "C3" if (x + y) % 3 != 0 else "C2"
                    elif rel > 0.72:
                        col_r = "C0"
                    else:
                        col_r = "C2" if ((x * 5 + y * 3) % 7 == 0) else "C1"
                    # Scattered moss creeping in along the outer slope
                    if fade_t < 0.72 and rng_t.random() < (0.72 - fade_t) * 1.8:
                        col_r = "G0" if rel > 0.45 else "G1"
                    ct.pset(x, y, col_r)
                else:
                    # Mossy earthen bank melting into forest floor with soft alpha edge
                    if rng_t.random() > fade_t / 0.52 * 1.15:
                        continue
                    col_m = "C0" if (rel > 0.62 and rng_t.random() < 0.45) else ("G1" if rel < 0.4 else "G0")
                    alpha = int(max(65, min(255, fade_t / 0.52 * 255)))
                    rgb = PAL[col_m]
                    ct.pset(x, y, (rgb[0], rgb[1], rgb[2], alpha))

            # Rounded rocky toe outline ONLY along full-cliff section (no dark arrowhead tip!)
            if fade_t >= 0.52:
                ct.pset(x, y_bot, "K" if fade_t >= 0.72 else "C0")
            elif fade_t >= 0.28 and rng_t.random() < 0.65:
                ct.pset(x, y_bot, "G0")

            # Sunken-basin base ambient shadow tapering to 0 on grass
            if fade_t >= 0.35:
                shadow_w = int(round(105.0 * ((fade_t - 0.35) / 0.65)))
                for sy in range(y_bot + 1, min(45, y_bot + 4)):
                    s_fade = 1.0 - float(sy - y_bot - 1) / 3.0
                    ct.pset(x, sy, (10, 12, 18, int(shadow_w * s_fade)))
        ct.save_png(os.path.join(sprites_dir, f"prop_cliff_taper_{side}.png"))

    # 4. 4-Frame Animated Organic Waterfall Cataract (44x46 -> 88x92, seamless mossy shelves & soft splash!)
    for frame in range(4):
        wf = PixelCanvas(44, 46)
        # Sculpted irregular mossy granite shoulders on both flanks (soft natural edge fading out, zero sluice boxes!)
        for y in range(4, 38):
            w_l = 10 + int(math.sin(y * 0.42) * 1.8) + (1 if y > 26 else 0)
            w_r = 34 - int(math.cos(y * 0.38) * 1.8) - (1 if y > 26 else 0)
            sh_l = max(1, w_l - (6 if 8 <= y <= 34 else 3))
            sh_r = min(43, w_r + (6 if 8 <= y <= 34 else 3))
            for x in range(sh_l, w_l):
                if y < 11 and (x + y) % 2 == 0:
                    col = "G1" if x > sh_l else "G0"
                elif y >= 32 and x < sh_l + 3:
                    col = "C0"
                elif x >= w_l - 2:
                    col = "C3" if y < 18 else "C2"
                elif x <= sh_l + 1:
                    col = "G0" if y < 16 else "C0"
                else:
                    col = "C1" if (x + y) % 3 else "C2"
                wf.pset(x, y, col)
            for x in range(w_r, sh_r):
                if y < 11 and (x + y) % 2 == 0:
                    col = "G1" if x < sh_r - 1 else "G0"
                elif y >= 32 and x > sh_r - 4:
                    col = "C0"
                elif x <= w_r + 1:
                    col = "C3" if y < 18 else "C2"
                elif x >= sh_r - 2:
                    col = "G0" if y < 16 else "C0"
                else:
                    col = "C1" if (x + y) % 3 else "C2"
                wf.pset(x, y, col)
            if 9 <= y <= 35:
                wf.pset(w_l - 1, y, "K" if y > 13 else "C2")
                wf.pset(w_r, y, "K" if y > 13 else "C2")

        # Continuous flowing inflow river water rounding smoothly over curved wet mossy rocks (NO diagonal stripe grid!)
        phase = frame * 3
        col_speeds = [1, 2, 2, 1, 3, 2, 1, 2, 3, 1, 2, 2, 3, 1, 2, 1, 2, 3, 1, 2, 2, 1, 3, 2]
        col_offsets = [0, 5, 2, 8, 1, 7, 4, 9, 3, 6, 0, 8, 2, 5, 1, 9, 4, 7, 2, 6, 3, 8, 1, 5]
        for y in range(0, 38):
            w_l = 10 + int(math.sin(y * 0.42) * 1.8) + (1 if y > 26 else 0)
            w_r = 34 - int(math.cos(y * 0.38) * 1.8) - (1 if y > 26 else 0)
            # Soft curve lip around y=7..9 where water accelerates into vertical whitewater ribbons
            for x in range(w_l, w_r):
                lip_curve = 8 + int(math.sin((x - 10) * 0.25) * 1.5)
                if y < lip_curve - 1:
                    # Upper smooth river water scrolling gently down into crest
                    col = "W2" if (x + y + frame) % 4 == 0 else "W1"
                    if y == lip_curve - 2 and (x * 3 + frame) % 5 == 0:
                        col = "W3"
                elif y <= lip_curve + 2:
                    # Curving whitewater spillway arch
                    col = "W5" if (x + frame) % 3 != 0 else "W4"
                else:
                    spd = col_speeds[(x - 8) % len(col_speeds)]
                    off_c = col_offsets[(x - 8) % len(col_offsets)]
                    v = (y - phase * spd + off_c) % 11
                    if v < 2:
                        col = "W5"
                    elif v < 5:
                        col = "W4" if (x + y) % 2 else "W3"
                    elif v < 8:
                        col = "W3" if v == 5 else "W2"
                    else:
                        col = "W1"
                wf.pset(x, y, col)

        # Feathering soft spray clouds billowing across plunge basin without rectangular cutoff
        for cx_f, cy_f, rx_f, ry_f in (
            (13, 38, 5.2, 2.8), (19, 39, 5.8, 3.2), (25, 38, 5.8, 3.0), (31, 39, 5.0, 2.7), (22, 41, 7.5, 2.4)
        ):
            bob = ((frame + cx_f) % 2)
            wf.ellipse(cx_f, cy_f - bob, rx_f, ry_f, "W3")
            wf.ellipse(cx_f, cy_f - 1 - bob, rx_f * 0.72, ry_f * 0.65, "W4")
            wf.ellipse(cx_f, cy_f - 1 - bob, rx_f * 0.40, ry_f * 0.40, "W5")
        for mx, my in ((9, 36), (35, 36), (11, 42), (33, 42), (17, 44), (27, 44)):
            wf.pset(mx, my - (frame % 2), "W4")
        wf.save_png(os.path.join(sprites_dir, f"prop_waterfall_{frame}.png"))

    # 5. Animated Plunge Pool Foam Rings (56x28 -> 112x56)
    for frame in (0, 1):
        wp = PixelCanvas(56, 28)
        r_boost = frame * 2
        wp.ellipse(28, 14, 24.0 - r_boost * 0.4, 10.6, (28, 66, 92, 130))
        for deg in range(0, 360, 12):
            ang = math.radians(deg + frame * 18)
            ox = int(28 + math.cos(ang) * (19.6 + r_boost * 0.6))
            oy = int(14 + math.sin(ang) * (7.8 + frame * 0.5))
            ix = int(28 + math.cos(ang) * (12.0 - frame))
            iy = int(14 + math.sin(ang) * (4.8 + frame * 0.4))
            wp.rect(ox - 1, oy, 2, 1, "W4" if deg % 24 == 0 else "W3")
            wp.pset(ix, iy, "W5" if deg % 36 == 0 else "W4")
        wp.save_png(os.path.join(sprites_dir, f"prop_waterfall_pool_{frame}.png"))


def _make_bridges_and_wilds_landmarks(sprites_dir: str):
    # 1. Weathered Medieval Granite Arch Bridge (64x56 -> 128x112)
    sb = PixelCanvas(64, 56)
    sb.ellipse(32, 49, 24.4, 5.4, (12, 18, 28, 135))
    # Running-bond weathered ashlar flagstone roadway spanning y=10..42
    for y in range(10, 43):
        row_idx = (y - 10) // 6
        row_off = (row_idx % 2) * 5
        for x in range(2, 62):
            jx = (x + row_off) % 10
            jy = (y - 10) % 6
            tile_hash = (((x + row_off) // 10) * 17 + row_idx * 31) % 7
            if jx == 0 or jy == 0:
                col = "C0"
            else:
                col = "C1" if tile_hash < 3 else "C2"
                if jy == 1 and jx > 1:
                    col = "C3" if tile_hash >= 4 else "C2"
                elif 21 <= y <= 31 and tile_hash % 2 == 0 and (x + y) % 7 != 0:
                    col = "C3" if col == "C2" else "C2"
            sb.pset(x, y, col)
    # Creeping moss tufts between stone joints
    for mx, my in ((9, 16), (22, 22), (38, 15), (49, 28), (15, 34), (42, 34)):
        sb.rect(mx, my, 3, 2, "G1")
        sb.pset(mx + 1, my, "G2")
    # Stout Crenellated North & South Masonry Parapets
    for py_top, has_arch in ((4, False), (41, True)):
        sb.rect(1, py_top, 62, 6, "C0")
        sb.rect(2, py_top + 1, 60, 4, "C2")
        sb.line(2, py_top + 1, 61, py_top + 1, "C3")
        for cx in range(3, 59, 10):
            sb.rect(cx, py_top - 1, 6, 3, "C3")
            sb.line(cx, py_top - 1, cx + 5, py_top - 1, "C4")
        if has_arch:
            sb.rect(2, 47, 60, 6, "C0")
            for x in range(4, 60):
                dx = abs(x - 32)
                if dx < 16:
                    arch_h = int(math.sqrt(max(0.0, 16 * 16 - dx * dx)) * 0.42)
                    sb.line(x, 53 - arch_h, x, 53, "N")
                    sb.pset(x, 52 - arch_h, "C3")
                else:
                    sb.line(x, 47, x, 52, "C1")
                    if x in (11, 52):
                        sb.rect(x, 50, 3, 3, "G0")
    sb.add_outline("K", selective_hue=True)
    sb.save_png(os.path.join(sprites_dir, "prop_stone_bridge_h.png"))

    # 2. Hewn Oak Timber Footbridge with Rope Balustrades & River Pilings (64x56 -> 128x112)
    tb = PixelCanvas(64, 56)
    tb.ellipse(32, 49, 24.4, 5.2, (14, 20, 30, 125))
    for px in (8, 22, 40, 54):
        tb.rect(px, 43, 5, 10, "T0")
        tb.line(px + 1, 44, px + 1, 51, "T1")
        tb.rect(px, 50, 5, 2, "G0")
    tb.rect(2, 10, 60, 33, "T0")
    for idx_p, px in enumerate(range(3, 60, 4)):
        shade = "T2" if (idx_p * 7) % 3 else "T1"
        tb.rect(px, 11, 3, 31, shade)
        tb.line(px, 12, px, 40, "T3" if shade == "T2" else "T2")
        tb.pset(px + (idx_p % 2), 20 + (idx_p % 5) * 2, "T0")  # subtle knot grain
        tb.pset(px + 1, 13, "K")
        tb.pset(px + 1, 39, "K")
    for rail_y in (6, 40):
        tb.rect(2, rail_y + 1, 60, 2, "T2")
        tb.line(2, rail_y + 1, 61, rail_y + 1, "T3")
        for post_x in (3, 17, 31, 45, 57):
            tb.rect(post_x, rail_y - 2, 4, 6, "T0")
            tb.rect(post_x + 1, rail_y - 2, 2, 5, "T3")
            tb.line(post_x, rail_y, post_x + 3, rail_y, "H2")
    tb.add_outline("DK", selective_hue=True)
    tb.save_png(os.path.join(sprites_dir, "prop_timber_bridge_h.png"))

    # 3. Obsidian Hollow Scorch Crater & Nest Cradle (160x120 -> 320x240)
    lr = PixelCanvas(160, 120)
    cx, cy = 72, 56
    ash_dark = PAL["O0"]
    ash_soot = blend_color(PAL["N"], PAL["O0"], 0.55)
    ash_mid = blend_color(PAL["C0"], PAL["N"], 0.65)
    ash_earth = blend_color(PAL["T0"], PAL["C0"], 0.45)
    for y in range(120):
        for x in range(160):
            dx = (x - cx) / 68.0
            dy = (y - cy) / 48.0
            d_nest = math.hypot((x - 119) / 24.0, (y - 75) / 18.0)
            dist = min(math.hypot(dx, dy), d_nest * 0.92)
            ang = math.atan2(dy, dx)
            wobble = math.sin(ang * 5.0) * 0.08 + math.cos(ang * 9.0) * 0.05
            h = ((x * 29 + y * 47) ^ (x * 7 + y * 13)) % 29
            r = dist + wobble + ((h % 3) - 1) * 0.02
            if r > 0.96:
                continue
            if r > 0.80:
                if h < 12:
                    lr.pset(x, y, (PAL["DE"][0], PAL["DE"][1], PAL["DE"][2], 195))
                elif h < 21:
                    lr.pset(x, y, "G0")
                elif h < 25:
                    lr.pset(x, y, "T0")
                continue
            # Radial soot wash fading gently into scorched earth with fine organic dither (no polka dots)
            h_fine = ((x * 43 + y * 61) ^ (x * 17)) % 17
            if r < 0.38:
                col = "K" if h_fine < 6 else ash_dark
            elif r < 0.62:
                col = ash_soot if h_fine < 11 else (ash_mid if h_fine < 15 else ash_dark)
            else:
                col = ash_mid if h_fine < 10 else (ash_earth if h_fine < 14 else ash_soot)
            lr.pset(x, y, col)
    for fx0, fy0, fx1, fy1 in ((95, 28, 52, 48), (112, 45, 68, 60), (88, 86, 44, 70)):
        lr.line(fx0, fy0, fx1, fy1, "K", thickness=2)
        lr.line(fx0, fy0 - 1, fx1, fy1 - 1, "O1")
    for bx, by, ex, ey in ((32, 34, 43, 39), (105, 32, 118, 25), (42, 88, 55, 83)):
        lr.line(bx, by, ex, ey, "T1")
        lr.line(bx, by - 1, ex, ey - 1, "T2")
    for sx, sy in ((55, 76), (86, 62), (98, 52), (48, 42)):
        lr.pset(sx, sy, "O2")
        lr.pset(sx + 1, sy, "O3")
    # Woven darkened bramble & stone nest cradle with subtle warm ember bed
    for deg in range(0, 360, 20):
        rad = math.radians(deg)
        nx = int(119 + math.cos(rad) * 14)
        ny = int(75 + math.sin(rad) * 10)
        lr.circle(nx, ny, 2, "C0" if deg % 40 == 0 else "T0")
        lr.pset(nx, ny - 1, "G0" if deg % 60 == 0 else "C2")
    lr.ellipse(119, 75, 11.4, 7.4, "K")
    lr.ellipse(119, 75, 9.2, 5.4, "T0")
    for e_dx, e_dy in ((-4, -1), (2, -2), (-2, 2), (4, 1), (0, 0), (-5, 1)):
        lr.pset(119 + e_dx, 75 + e_dy, "R1")
        if (e_dx + e_dy) % 2 == 0:
            lr.pset(119 + e_dx + 1, 75 + e_dy, "Y0")
    lr.save_png(os.path.join(sprites_dir, "prop_dragon_lair.png"))

    # 4. Gnarled Storm-Root & Wind-Tumbled Bough Barricade (36x34 -> 64x60, wedges neatly inside Stone Causeway parapets)
    sr = PixelCanvas(36, 34)
    sr.ellipse(18, 28, 13.8, 3.6, (14, 16, 18, 120))
    # Dense compacted heartwood stump & wind-wedged cobble mound inside bridge roadway
    sr.ellipse(18, 19, 10.6, 8.8, "K")
    sr.ellipse(18, 18, 9.2, 7.6, "T0")
    root_curves = [
        (5, 25, 14, 14, 30, 8, 2.0),
        (6, 9, 17, 17, 31, 25, 2.0),
        (4, 17, 18, 13, 32, 19, 1.8),
        (11, 6, 17, 18, 12, 29, 1.9),
        (24, 7, 19, 19, 25, 29, 1.9),
    ]
    for x0, y0, mx, my, x1, y1, rad in root_curves:
        for s in range(20):
            t = s / 19.0
            mt = 1.0 - t
            px = int(mt * mt * x0 + 2 * mt * t * mx + t * t * x1)
            py = int(mt * mt * y0 + 2 * mt * t * my + t * t * y1)
            sr.ellipse(px, py, rad, rad * 0.85, "T0")
            sr.pset(px, py - 1, "T2" if s % 2 == 0 else "T1")
    for rx, ry, r in ((11, 23, 3.0), (24, 22, 3.0), (18, 14, 2.6)):
        sr.ellipse(rx, ry, r, r * 0.78, "C1")
        sr.line(rx - 1, ry - 1, rx + 1, ry - 1, "C3")
    for vx, vy in ((10, 12), (23, 16), (13, 21), (22, 11), (17, 25), (26, 20)):
        sr.ellipse(vx, vy, 3.0, 1.9, "G0")
        sr.pset(vx - 1, vy - 1, "G2")
        sr.pset(vx + 1, vy, "G1")
    sr.add_outline("DK", selective_hue=True)
    sr.save_png(os.path.join(sprites_dir, "prop_storm_roots.png"))

    # 5. Hemlock Snap & Dragon Claw Furrow Clue (40x30 -> 80x60 at CLUE_TRACKS_POS)
    ct = PixelCanvas(40, 30)
    # Brighter amber/sand trampled clearing loam so clue pops sharply against dark earth
    ct.ellipse(21, 16, 16.4, 8.4, (14, 16, 18, 120))
    ct.ellipse(23, 15, 13.4, 6.4, "T2")
    ct.ellipse(23, 15, 11.4, 5.2, "T1")
    # Three vivid dark dragon-talon trenches with pale cream-tan kicked-up ridges
    for off in (-4, 0, 4):
        ct.line(15 + off, 20 + off // 2, 33 + off, 11 + off // 2, "H2")
        ct.line(15 + off, 19 + off // 2, 33 + off, 10 + off // 2, "K", thickness=2)
    # Snapped hemlock log showing warm amber bark & crisp pale split heartwood
    ct.line(4, 21, 17, 13, "T0", thickness=3)
    ct.line(4, 20, 16, 12, "T3", thickness=2)
    ct.rect(15, 10, 4, 5, "Y1")
    ct.rect(16, 11, 2, 3, "H2")
    for bx, by in ((6, 17), (10, 15), (9, 22), (13, 21)):
        ct.ellipse(bx, by, 3.2, 2.6, "G1")
        ct.pset(bx - 1, by - 1, "G2")
    ct.rect(25, 18, 3, 2, "O2")
    ct.pset(26, 18, "O3")
    ct.rect(30, 14, 2, 2, "O2")
    ct.pset(30, 14, "CS2")
    ct.add_outline("K", selective_hue=True)
    ct.save_png(os.path.join(sprites_dir, "prop_claw_tracks.png"))

    # 6. Shattered Church Ballista Cart Wreck (52x40 -> 104x80 at CLUE_CART_POS)
    for looted in (False, True):
        bw = PixelCanvas(52, 40)
        bw.ellipse(26, 23, 21.4, 10.4, (16, 16, 20, 130))
        bw.ellipse(24, 22, 15.4, 6.4, "N")
        bw.ellipse(13, 24, 6.4, 4.4, "T0")
        bw.ellipse(13, 24, 4.4, 3.1, "T2")
        bw.line(9, 24, 17, 24, "C2")
        bw.line(13, 21, 13, 27, "C2")
        bw.pset(13, 24, "C3")
        for i in range(18):
            x0 = 18 + i
            y0 = 19 - i // 4
            bw.line(x0, y0, x0 - 2, y0 + 10, "T1" if i % 3 else "T0")
        bw.line(18, 19, 36, 14, "T3")
        bw.line(17, 24, 34, 19, "I0")
        bw.line(18, 25, 34, 20, "I1")
        bw.line(29, 14, 41, 7, "C2")
        bw.line(29, 13, 40, 6, "CS2")
        bw.line(41, 7, 45, 16, "H2")
        bw.line(22, 11, 31, 20, "T2")
        bw.rect(30, 19, 3, 2, "C4")
        bw.rect(20, 9, 3, 3, "I2")
        bw.rect(34, 23, 8, 6, "T0")
        bw.rect(35, 24, 6, 4, "T2")
        if not looted:
            bw.rect(39, 20, 10, 8, "L0")
            bw.rect(40, 21, 8, 6, "L1")
            bw.line(41, 23, 46, 23, "T1")
            bw.line(41, 25, 45, 25, "E1")
            bw.circle(47, 26, 2, "I1")
            bw.pset(47, 26, "Y3")
        else:
            bw.rect(36, 25, 5, 3, "K")
        bw.add_outline("K", selective_hue=True)
        fname = "prop_ballista_wreck_looted.png" if looted else "prop_ballista_wreck.png"
        bw.save_png(os.path.join(sprites_dir, fname))


def _make_fx_and_map_art(sprites_dir: str):
    # 1. Brotherhood Emerald Signal Flare Orbs (24x24 -> 48x48) & Starburst (48x48)
    for frame in (0, 1):
        fl = PixelCanvas(24, 24)
        fl.ellipse(12, 12, 8.4 + frame, 8.4 + frame, (52, 198, 132, 95))
        fl.ellipse(12, 12, 5.4, 5.4, (72, 224, 152, 185))
        ray = 9 + frame * 2
        fl.line(12, 12 - ray, 12, 12 + ray, "E3")
        fl.line(12 - ray, 12, 12 + ray, 12, "E3")
        fl.line(7, 7, 17, 17, "E2")
        fl.line(17, 7, 7, 17, "E2")
        # Bright hot incandescent core painted LAST over ray crossing
        fl.ellipse(12, 12, 3.6, 3.6, "E3")
        fl.ellipse(12, 12, 2.3, 2.3, "Y2")
        fl.pset(12, 12, "Y3")
        fl.save_png(os.path.join(sprites_dir, f"prop_flare_orb_{frame}.png"))

    fb = PixelCanvas(48, 48)
    fb.circle(24, 24, 18, (48, 192, 128, 72))
    fb.circle(24, 24, 11, (90, 232, 165, 130))
    for deg in range(0, 360, 15):
        rad = math.radians(deg)
        r_len = 20 if deg % 45 == 0 else 13
        x1 = int(24 + math.cos(rad) * r_len)
        y1 = int(24 + math.sin(rad) * r_len)
        fb.line(24, 24, x1, y1, "E3" if deg % 30 == 0 else "E2")
        if deg % 45 == 0:
            fb.pset(x1, y1, "Y3")
    fb.circle(24, 24, 5, "Y2")
    fb.circle(24, 24, 3, "Y3")
    fb.save_png(os.path.join(sprites_dir, "prop_flare_burst.png"))

    # 2. Crisp Pixel-Art Emerald Reticle Brackets (24x24)
    rt = PixelCanvas(24, 24)
    for cx, cy, sx, sy in ((2, 2, 1, 1), (21, 2, -1, 1), (2, 21, 1, -1), (21, 21, -1, -1)):
        rt.line(cx, cy, cx + sx * 5, cy, "E3")
        rt.line(cx, cy, cx, cy + sy * 5, "E3")
        rt.line(cx + sx, cy + sy, cx + sx * 4, cy + sy, "K")
        rt.pset(cx + sx * 5, cy + sy, "E2")
    rt.save_png(os.path.join(sprites_dir, "prop_pixel_reticle.png"))

    # 3. Seamless 64x64 Aged Sheepskin Vellum Tile for [M] Border Survey Map (soft organic linen weave)
    base = blend_color(PAL["H2"], PAL["L1"], 0.48)
    warm = blend_color(PAL["H1"], PAL["L1"], 0.42)
    light = blend_color(PAL["L0"], PAL["H2"], 0.45)
    speck = blend_color(PAL["T1"], PAL["H1"], 0.65)
    vel = PixelCanvas(64, 64, base)
    for y in range(64):
        for x in range(64):
            tx = x * (math.tau / 64.0)
            ty = y * (math.tau / 64.0)
            # Soft multi-octave sine wave gently dithered (zero sharp spotted cow-blotches)
            w = (math.sin(tx) * math.cos(ty) + 0.5 * math.cos(tx * 2.0 - ty)) * 0.5 + 0.5
            h = ((x * 37 + y * 59) ^ (x * 13 + y * 29)) % 97
            if h < 2:
                col = speck
            elif (x + y) % 8 == 0 and h % 3 == 0:
                col = warm
            elif (x % 4 == 0 and y % 4 == 0) and w > 0.58:
                col = light
            else:
                col = blend_color(warm, light, max(0.0, min(1.0, 0.25 + w * 0.5)))
            vel.pset(x, y, col)
    vel.save_png(os.path.join(sprites_dir, "ui_map_vellum.png"))

    # 4. Ornate Ink & Brass Cartographer's Compass Rose (36x36)
    cr = PixelCanvas(36, 36)
    cr.circle(18, 18, 15, "L0")
    cr.circle(18, 18, 14, "H2")
    # Inked degree ring
    for deg in range(0, 360, 15):
        rad = math.radians(deg)
        ox = int(18 + math.cos(rad) * 15)
        oy = int(18 + math.sin(rad) * 15)
        ix = int(18 + math.cos(rad) * 12)
        iy = int(18 + math.sin(rad) * 12)
        cr.line(ix, iy, ox, oy, "T0")
    # Intercardinal points (NE/NW/SE/SW)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cr.line(18, 18, 18 + sx * 9, 18 + sy * 9, "T0")
            cr.line(18, 18, 18 + sx * 7, 18 + sy * 7, "Y1")
    # Bold Cardinal Rose Spires (Crimson N pointer, Gold/Ink E/W/S)
    for d in range(1, 13):
        w = max(0, (13 - d) // 4)
        cr.rect(18 - w, 18 - d, w * 2 + 1, 1, "I1")  # North crimson blade
        cr.pset(18, 18 - d, "I2")
        cr.rect(18 - w, 18 + d, w * 2 + 1, 1, "T0")  # South dark sepia
        cr.rect(18 - d, 18 - w, 1, w * 2 + 1, "T0")  # West
        cr.rect(18 + d, 18 - w, 1, w * 2 + 1, "Y0")  # East brass
    cr.circle(18, 18, 3, "Y2")
    cr.pset(18, 18, "I2")
    cr.save_png(os.path.join(sprites_dir, "ui_map_compass.png"))

    # 5. Hand-Inked Cartography Map Stamps (sepia woodcut ink on parchment)
    # a) Woodcut Pine Cluster (28x22)
    mp = PixelCanvas(28, 22)
    for tx, ty, sc in ((7, 4, 0), (15, 2, 1), (21, 5, 0)):
        h = 11 + sc * 2
        for row in range(h):
            hw = 1 + (row // 2)
            col = "G1" if row < h - 3 else "G0"
            mp.line(tx - hw, ty + row, tx + hw, ty + row, col)
            mp.pset(tx - hw, ty + row, "T0")
            mp.pset(tx + hw, ty + row, "T0")
        mp.rect(tx - 1, ty + h, 2, 3, "T0")
    mp.save_png(os.path.join(sprites_dir, "map_stamp_pines.png"))

    # b) Dragon Hollow Crater Icon (22x18)
    mh = PixelCanvas(22, 18)
    mh.ellipse(11, 10, 8, 5, "T0")
    mh.ellipse(11, 10, 6, 3.5, "O1")
    mh.line(5, 7, 11, 11, "O3")
    mh.line(17, 7, 11, 11, "O3")
    mh.ellipse(11, 11, 2, 1.5, "Y2")
    mh.save_png(os.path.join(sprites_dir, "map_stamp_hollow.png"))

    # c) Brotherhood Outpost Tower Crest (20x20)
    mo = PixelCanvas(20, 20)
    mo.rect(5, 8, 10, 10, "T0")
    mo.rect(6, 9, 8, 8, "C2")
    for cx in (4, 8, 13):
        mo.rect(cx, 5, 3, 3, "C1")
    mo.line(10, 1, 10, 8, "T0")
    mo.rect(11, 2, 6, 4, "E1")
    mo.pset(13, 3, "Y2")
    mo.save_png(os.path.join(sprites_dir, "map_stamp_outpost.png"))

    # d) Shattered Wagon / Clue Icon (20x16)
    mw = PixelCanvas(20, 16)
    mw.circle(7, 10, 4, "T0")
    mw.circle(7, 10, 2, "H2")
    mw.line(11, 11, 17, 5, "I1")
    mw.rect(13, 8, 5, 5, "L0")
    mw.pset(15, 10, "I2")
    mw.save_png(os.path.join(sprites_dir, "map_stamp_wreck.png"))

    # e) Dead-End Crag / Frost Hazard Icon (22x16)
    mc = PixelCanvas(22, 16)
    for px, ph in ((6, 11), (11, 13), (16, 9)):
        for r in range(ph):
            hw = 1 + r // 3
            mc.line(px - hw, 14 - ph + r, px + hw, 14 - ph + r, "C2" if r > 3 else "L0")
            mc.pset(px - hw, 14 - ph + r, "T0")
            mc.pset(px + hw, 14 - ph + r, "C0")
    mc.save_png(os.path.join(sprites_dir, "map_stamp_crag.png"))

    # f) Beacon Fire Icon (16x16)
    mf = PixelCanvas(16, 16)
    mf.line(4, 13, 12, 10, "T0")
    mf.line(4, 10, 12, 13, "T0")
    mf.ellipse(8, 8, 3.2, 4.5, "R2")
    mf.ellipse(8, 8, 1.8, 2.8, "Y2")
    mf.pset(8, 5, "Y3")
    mf.save_png(os.path.join(sprites_dir, "map_stamp_fire.png"))

    # g) Winch Post / Hook Icon (18x16)
    mi = PixelCanvas(18, 16)
    mi.rect(7, 5, 4, 9, "T0")
    mi.rect(6, 8, 6, 3, "H1")
    mi.circle(9, 4, 2, "E2")
    mi.save_png(os.path.join(sprites_dir, "map_stamp_winch.png"))


def make_wilds_env(sprites_dir: str):
    _make_terrain_and_verges(sprites_dir)
    _make_cliffs_and_waterfalls(sprites_dir)
    _make_bridges_and_wilds_landmarks(sprites_dir)
    _make_fx_and_map_art(sprites_dir)
