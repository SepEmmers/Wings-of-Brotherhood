"""
HUD icons, projectiles, ballista wagons, wilds landmarks, and combat/egg sprites.
"""

import math
import os
import random
from pixel_art_lib import PAL, PixelCanvas, blend_color


def make_icons_and_combat_props(sprites_dir: str):
    # 16x16 Crisp HUD Icons
    ik = PixelCanvas(16, 16)
    ik.circle(8, 8, 6, "T0")
    ik.circle(8, 8, 5, "H1")
    ik.circle(8, 8, 3, "T1")
    ik.line(3, 8, 13, 8, "H2")
    ik.add_outline("K", selective_hue=True)
    ik.save_png(os.path.join(sprites_dir, "icon_knot.png"))

    ie = PixelCanvas(16, 16)
    ie.ellipse(8, 8, 4.5, 6, "O0")
    ie.ellipse(7.5, 7.5, 3.2, 4.5, "O2")
    ie.pset(6, 5, "O3")
    ie.pset(8, 9, "Y2")
    ie.add_outline("K", selective_hue=True)
    ie.save_png(os.path.join(sprites_dir, "icon_egg.png"))

    ic = PixelCanvas(16, 16)
    ic.circle(8, 8, 6, "Y0")
    ic.circle(8, 8, 5, "Y2")
    ic.circle(8, 8, 4, "L0")
    ic.line(8, 4, 8, 12, "I1")
    ic.pset(8, 4, "I2")
    ic.add_outline("K", selective_hue=True)
    ic.save_png(os.path.join(sprites_dir, "icon_compass.png"))

    ikn = PixelCanvas(16, 16)
    ikn.line(3, 12, 7, 8, "T2")
    ikn.line(4, 13, 8, 9, "T3")
    ikn.line(7, 8, 13, 2, "C3")
    ikn.line(8, 9, 13, 4, "C4")
    ikn.pset(6, 7, "Y2")
    ikn.pset(9, 10, "Y2")
    ikn.add_outline("K", selective_hue=True)
    ikn.save_png(os.path.join(sprites_dir, "icon_knife.png"))

    iwg = PixelCanvas(16, 16)
    iwg.line(2, 10, 6, 4, "E2")
    iwg.line(6, 4, 14, 7, "E3")
    iwg.rect(5, 6, 6, 5, "E1")
    iwg.line(4, 11, 12, 9, "E0")
    iwg.pset(6, 3, "Y2")
    iwg.add_outline("DE", selective_hue=True)
    iwg.save_png(os.path.join(sprites_dir, "icon_wing.png"))

    # Small item pickup popup icons (16x16): Rye Loaf & Dock Crate
    ibd = PixelCanvas(16, 16)
    ibd.ellipse(8, 9, 5.5, 4.0, "T2")
    ibd.ellipse(8, 8, 5.0, 3.2, "Y0")
    ibd.ellipse(8, 7, 3.6, 2.0, "Y2")
    ibd.line(6, 6, 7, 8, "T1")
    ibd.line(10, 6, 11, 8, "T1")
    ibd.add_outline("DK", selective_hue=True)
    ibd.save_png(os.path.join(sprites_dir, "icon_bread.png"))

    icr = PixelCanvas(16, 16)
    icr.rect(3, 3, 10, 10, "T1")
    icr.rect(4, 4, 8, 8, "T2")
    icr.line(4, 4, 11, 11, "T0")
    icr.line(11, 4, 4, 11, "T0")
    icr.rect(4, 3, 8, 2, "T3")
    icr.add_outline("DK", selective_hue=True)
    icr.save_png(os.path.join(sprites_dir, "icon_crate.png"))

    # Brass Hook & Whipping Line (16x16)
    ihw = PixelCanvas(16, 16)
    ihw.ellipse(6, 10, 3.2, 2.5, "H1")
    ihw.ellipse(6, 10, 1.5, 1.0, ".")
    ihw.line(5, 12, 9, 10, "H2")
    ihw.line(8, 8, 12, 4, "Y1")
    ihw.line(12, 4, 13, 6, "Y2")
    ihw.pset(13, 7, "Y0")
    ihw.add_outline("K", selective_hue=True)
    ihw.save_png(os.path.join(sprites_dir, "icon_hook_whip.png"))

    # Louvain Beeswax & Steel Thimble (16x16)
    ibt = PixelCanvas(16, 16)
    ibt.ellipse(6, 10, 3.5, 2.8, "Y1")
    ibt.ellipse(6, 9, 2.4, 1.8, "Y2")
    ibt.pset(5, 8, "Y3")
    ibt.rect(10, 6, 4, 5, "C3")
    ibt.rect(10, 6, 3, 2, "C4")
    ibt.pset(11, 8, "C1")
    ibt.pset(12, 9, "C1")
    ibt.add_outline("DK", selective_hue=True)
    ibt.save_png(os.path.join(sprites_dir, "icon_beeswax_thimble.png"))

    # Sea-Biscuit & Hemp Twine (16x16)
    ibs = PixelCanvas(16, 16)
    ibs.ellipse(6, 9, 3.8, 3.5, "L1")
    ibs.ellipse(6, 8, 2.8, 2.5, "L0")
    ibs.pset(5, 8, "T2")
    ibs.pset(7, 8, "T2")
    ibs.pset(6, 10, "T2")
    ibs.rect(10, 5, 4, 7, "H1")
    ibs.line(10, 7, 13, 7, "H2")
    ibs.line(10, 9, 13, 9, "H2")
    ibs.add_outline("DK", selective_hue=True)
    ibs.save_png(os.path.join(sprites_dir, "icon_biscuit_twine.png"))

    # Brotherhood Brass Harness Carabiner (16x16)
    icb = PixelCanvas(16, 16)
    icb.rect(4, 3, 8, 10, "C3")
    icb.rect(6, 5, 4, 6, ".")
    icb.line(4, 5, 4, 10, "C4")
    icb.line(11, 5, 11, 10, "Y2")
    icb.rect(10, 6, 2, 4, "Y1")
    icb.add_outline("K", selective_hue=True)
    icb.save_png(os.path.join(sprites_dir, "icon_carabiner.png"))

    # Salvaged Hemp Rope Bundle (16x16)
    ihb = PixelCanvas(16, 16)
    ihb.ellipse(8, 8, 4.5, 3.5, "H1")
    ihb.ellipse(8, 8, 2.0, 1.5, ".")
    ihb.line(5, 6, 11, 6, "H2")
    ihb.line(4, 9, 12, 9, "H0")
    ihb.rect(7, 5, 2, 6, "T1")
    ihb.add_outline("DK", selective_hue=True)
    ihb.save_png(os.path.join(sprites_dir, "icon_hemp_bundle.png"))

    # Clara's Ropewalk Brass Shuttle (16x16)
    ish = PixelCanvas(16, 16)
    ish.line(3, 11, 12, 4, "Y1")
    ish.line(4, 12, 13, 5, "Y2")
    ish.rect(7, 7, 3, 2, "I1")
    ish.line(9, 10, 12, 12, "H2")
    ish.add_outline("DK", selective_hue=True)
    ish.save_png(os.path.join(sprites_dir, "icon_shuttle.png"))

    # Dragon-Leather Harness Strap (16x16)
    ist = PixelCanvas(16, 16)
    ist.ellipse(8, 8, 5.0, 3.5, "T1")
    ist.ellipse(8, 8, 2.6, 1.6, ".")
    ist.line(4, 9, 12, 9, "T2")
    ist.rect(10, 6, 3, 4, "Y1")
    ist.pset(11, 7, "Y2")
    ist.add_outline("K", selective_hue=True)
    ist.save_png(os.path.join(sprites_dir, "icon_strap.png"))

    # Inventory Slot Frame (24x24 beveled Flemish leather & brass socket)
    usb = PixelCanvas(24, 24)
    usb.rect(0, 0, 24, 24, (20, 16, 22, 235))
    usb.rect(1, 1, 22, 22, (36, 30, 34, 240))
    usb.rect(2, 2, 20, 20, (24, 20, 26, 235))
    usb.line(1, 1, 22, 1, "Y0")
    usb.line(1, 1, 1, 22, "Y0")
    usb.pset(2, 2, "Y1")
    usb.pset(21, 2, "Y1")
    usb.pset(2, 21, "Y1")
    usb.pset(21, 21, "Y1")
    usb.save_png(os.path.join(sprites_dir, "ui_slot_bg.png"))

    # Harbor Noticeboard (28x32)
    nb = PixelCanvas(28, 32)
    nb.rect(5, 4, 18, 18, "T1")
    nb.rect(6, 5, 16, 16, "T2")
    nb.rect(7, 20, 3, 10, "T0")
    nb.rect(18, 20, 3, 10, "T0")
    nb.rect(8, 7, 6, 8, "L1")
    nb.rect(15, 8, 5, 9, "H2")
    nb.pset(11, 7, "I1")
    nb.pset(17, 8, "I1")
    nb.line(9, 10, 12, 10, "T0")
    nb.line(16, 12, 19, 12, "T0")
    nb.add_outline("K", selective_hue=True)
    nb.save_png(os.path.join(sprites_dir, "prop_noticeboard.png"))

    # Twine-Bound Harbor Supply Cache (24x24)
    tc = PixelCanvas(24, 24)
    tc.rect(4, 7, 16, 13, "T1")
    tc.rect(5, 8, 14, 11, "T2")
    tc.line(4, 11, 19, 11, "H2")
    tc.line(4, 15, 19, 15, "H1")
    tc.line(10, 7, 10, 19, "H2")
    tc.rect(9, 10, 4, 4, "H3")
    tc.add_outline("DK", selective_hue=True)
    tc.save_png(os.path.join(sprites_dir, "prop_twine_cache.png"))

    # Dockworker's Knife Slash Crescent Arc (24x24)
    sa = PixelCanvas(24, 24)
    for ang_deg in range(-58, 60, 4):
        rad = math.radians(ang_deg)
        for r in (7, 8, 9, 10):
            px = int(8 + math.cos(rad) * r)
            py = int(12 + math.sin(rad) * r)
            col = "W5" if r == 9 else ("C4" if r >= 8 else "C2")
            sa.pset(px, py, col)
    sa.save_png(os.path.join(sprites_dir, "prop_slash_arc.png"))

    # Church Hunter Heavy Iron Torsion Ballista Wagon (56x48)
    bw = PixelCanvas(56, 48)
    bw.ellipse(28, 34, 20.4, 8.6, (14, 14, 20, 110))
    # Four iron-rimmed spoked oak wheels
    for wx, wy in ((13, 24), (43, 24), (13, 36), (43, 36)):
        bw.ellipse(wx, wy, 4.2, 5.2, "C0")
        bw.ellipse(wx, wy, 3.2, 4.2, "T0")
        bw.ellipse(wx, wy, 2.0, 2.6, "T2")
        bw.line(wx - 2, wy, wx + 2, wy, "C2")
        bw.pset(wx, wy, "C4")
    # Heavy axle beams & oak gun chassis
    bw.rect(14, 23, 28, 3, "T0")
    bw.rect(14, 34, 28, 3, "T0")
    bw.rect(17, 17, 22, 22, "T1")
    bw.rect(19, 18, 18, 20, "T2")
    for py in range(20, 37, 3):
        bw.line(19, py, 36, py, "T1")
    # Crimson Inquisitor iron-studded side shields & brass trim
    bw.rect(17, 19, 3, 18, "I0")
    bw.rect(36, 19, 3, 18, "I0")
    bw.line(18, 20, 18, 35, "I1")
    bw.line(37, 20, 37, 35, "I1")
    bw.rect(17, 35, 22, 2, "Y0")
    bw.line(19, 35, 35, 35, "Y2")
    # Twin vertical torsion skeins & heavy curved composite bow arms (aimed UP/-Y)
    for sx in (16, 36):
        bw.rect(sx, 11, 5, 7, "H0")
        bw.rect(sx + 1, 12, 3, 5, "H1")
        bw.rect(sx, 10, 5, 2, "C3")
    # Flexed steel-reinforced prod arms arcing outward-back
    for i in range(13):
        u = i / 12.0
        ly = int(12 + u * u * 7)
        bw.rect(16 - i, ly, 2, 2, "C2" if i < 6 else "C3")
        bw.rect(39 + i, ly, 2, 2, "C2" if i < 6 else "C3")
        bw.pset(16 - i, ly, "CS2")
        bw.pset(39 + i, ly, "CS2")
    # Drawn hemp bowstring pulled back to windlass catch
    bw.line(4, 19, 28, 29, "H2")
    bw.line(51, 19, 28, 29, "H2")
    bw.pset(28, 29, "Y2")
    # Central grooved stock/trough, rear windlass crank, and loaded iron-tipped bolt
    bw.rect(25, 11, 6, 25, "T0")
    bw.rect(26, 11, 4, 24, "T3")
    bw.line(28, 6, 28, 29, "C3")  # bolt shaft
    bw.rect(27, 4, 3, 4, "C4")    # steel spearhead quarrel tip
    bw.pset(28, 3, "EW")
    bw.rect(25, 25, 2, 4, "I2")   # bolt fletching
    bw.rect(30, 25, 2, 4, "I2")
    # Windlass cross-bar & cog wheel at stern
    bw.rect(23, 33, 10, 3, "S")
    bw.rect(26, 32, 4, 4, "Y1")
    bw.line(21, 34, 34, 34, "C3")
    # Crimson Hunter stern pennant
    bw.line(41, 7, 41, 24, "T3")
    bw.rect(42, 7, 8, 5, "I0")
    bw.rect(42, 8, 6, 3, "I1")
    bw.pset(44, 9, "Y2")
    bw.add_outline("K", selective_hue=True)
    bw.save_png(os.path.join(sprites_dir, "prop_ballista_wagon.png"))

    # Barbed Hunter Capture Net (36x32)
    sn = PixelCanvas(36, 32)
    for x in range(4, 32, 4):
        sn.line(x, 4, x + 2, 28, "H1")
    for y in range(5, 28, 4):
        sn.line(4, y, 31, y, "H2")
    for cx, cy in ((5, 5), (30, 5), (5, 27), (30, 27)):
        sn.rect(cx - 1, cy - 1, 3, 3, "I1")
    sn.add_outline("K", selective_hue=True)
    sn.save_png(os.path.join(sprites_dir, "prop_sky_net.png"))

    # Brotherhood Crossbow Bolt & Hunter Ballista Quarrel (16x16, facing Up)
    cb = PixelCanvas(16, 16)
    cb.line(8, 2, 8, 13, "T2")
    cb.rect(7, 1, 3, 3, "Y2")
    cb.pset(8, 0, "C4")
    cb.rect(6, 11, 2, 3, "E2")
    cb.rect(9, 11, 2, 3, "E2")
    cb.add_outline("K", selective_hue=True)
    cb.save_png(os.path.join(sprites_dir, "prop_crossbow_bolt.png"))

    hb = PixelCanvas(16, 16)
    hb.line(8, 2, 8, 13, "T0")
    hb.rect(7, 1, 3, 3, "C4")
    hb.rect(6, 11, 2, 3, "I1")
    hb.rect(9, 11, 2, 3, "I1")
    hb.add_outline("K", selective_hue=True)
    hb.save_png(os.path.join(sprites_dir, "prop_hunter_bolt.png"))

    # Drifting High-Altitude Cloud Banks (64x40)
    for cidx, col_light, col_mid in ((0, "L0", "C4"), (1, "C3", "CS2")):
        cl = PixelCanvas(64, 40)
        for cx, cy, rx, ry in ((20, 22, 13, 9), (32, 17, 15, 11), (44, 23, 12, 8), (28, 26, 17, 7)):
            cl.ellipse(cx, cy, rx, ry, col_mid)
            cl.ellipse(cx - 1, cy - 2, rx - 3, ry - 2, col_light)
        cl.save_png(os.path.join(sprites_dir, f"prop_cloud_{cidx}.png"))

    # Wild Forest Briar/Hawthorn Hedgerows (3 asymmetric interlocking 40x32 sprites)
    briar_layouts = [
        {
            "canes": [(3, 25, 35, 9), (5, 13, 33, 24), (11, 28, 29, 7)],
            "foliage": [(9, 19, 6.2, 4.4, "G0"), (18, 14, 7.2, 5.0, "G1"), (29, 17, 6.4, 4.2, "G0"), (23, 22, 5.8, 3.8, "G1"), (14, 11, 4.8, 3.4, "G2"), (26, 12, 4.4, 3.0, "G2")],
            "hips": [(6, 16), (13, 8), (21, 10), (31, 13), (12, 24), (27, 25)],
            "thorns": [(4, 21), (10, 14), (22, 8), (35, 15), (17, 26), (33, 22)],
        },
        {
            "canes": [(2, 18, 36, 12), (8, 27, 30, 8), (6, 9, 28, 25)],
            "foliage": [(12, 15, 6.8, 4.8, "G0"), (22, 11, 5.8, 4.0, "G1"), (28, 19, 6.8, 4.6, "G0"), (18, 22, 5.6, 4.2, "G1"), (9, 11, 4.2, 3.2, "G2"), (30, 14, 4.6, 3.2, "G2")],
            "hips": [(9, 18), (19, 8), (27, 10), (34, 17), (15, 25), (24, 23)],
            "thorns": [(3, 15), (14, 9), (25, 14), (36, 20), (8, 24), (30, 26)],
        },
        {
            "canes": [(4, 22, 37, 15), (7, 11, 32, 26), (14, 7, 25, 27)],
            "foliage": [(11, 20, 6.0, 4.4, "G1"), (20, 17, 7.4, 5.2, "G0"), (30, 14, 5.8, 4.4, "G1"), (16, 11, 5.2, 3.6, "G2"), (27, 22, 5.4, 3.8, "G0"), (9, 14, 4.0, 3.0, "G1")],
            "hips": [(7, 12), (17, 9), (29, 11), (11, 23), (22, 25), (33, 21)],
            "thorns": [(5, 18), (15, 7), (26, 9), (35, 12), (19, 27), (31, 25)],
        },
    ]
    for b_var, cfg in enumerate(briar_layouts):
        br = PixelCanvas(40, 32)
        br.ellipse(20, 22, 16.5, 6.5, (14, 18, 14, 95))
        for x0, y0, x1, y1 in cfg["canes"]:
            br.line(x0, y0, x1, y1, "T0", thickness=2)
            br.line(x0, y0 - 1, x1, y1 - 1, "T1")
        for fx, fy, rx, ry, col in cfg["foliage"]:
            br.ellipse(fx, fy, rx, ry, col)
            br.ellipse(fx - 1, fy - 1, rx * 0.65, ry * 0.6, "G2" if col == "G1" else ("G3" if col == "G2" else "G1"))
        for hx, hy in cfg["hips"]:
            br.pset(hx, hy, "R3")
            br.pset(hx + 1, hy, "Y2")
        for tx, ty in cfg["thorns"]:
            br.pset(tx, ty, "H1")
            br.pset(tx + 1, ty + 1, "T2")
        br.add_outline("DE", selective_hue=True)
        br.save_png(os.path.join(sprites_dir, f"prop_bramble_thicket_{b_var}.png"))
        if b_var == 0:
            br.save_png(os.path.join(sprites_dir, "prop_bramble_thicket.png"))

    # Carved Mossy Forest Cairn Stone (24x32, Maze Navigation Landmark)
    cr = PixelCanvas(24, 32)
    cr.ellipse(12, 24, 8, 5, "C1")
    cr.ellipse(12, 23, 7, 4, "C2")
    cr.ellipse(12, 16, 6, 4, "C2")
    cr.ellipse(12, 15, 5, 3, "C3")
    cr.ellipse(12, 9, 4, 3.5, "C3")
    cr.ellipse(11, 8, 2.5, 2, "C4")
    cr.rect(9, 19, 3, 2, "G1")
    cr.rect(14, 14, 3, 2, "G2")
    cr.pset(12, 9, "Y2")
    cr.pset(12, 10, "Y1")
    cr.add_outline("K", selective_hue=True)
    cr.save_png(os.path.join(sprites_dir, "prop_cairn_stone.png"))

    # Swirling Coastal Updraft Thermal Ring (32x32, Flight Boost Ring)
    ur = PixelCanvas(32, 32)
    for deg in range(0, 360, 10):
        rad = math.radians(deg)
        ox = int(16 + math.cos(rad) * 12)
        oy = int(16 + math.sin(rad) * 10)
        ix = int(16 + math.cos(rad) * 10)
        iy = int(16 + math.sin(rad) * 8)
        col = "W5" if (deg % 60 < 20) else ("W4" if (deg % 40 < 20) else "Y2")
        ur.pset(ox, oy, col)
        ur.pset(ix, iy, "W3")
    ur.save_png(os.path.join(sprites_dir, "prop_updraft_ring.png"))

    # Parchment Survey Map HUD Icon (16x16)
    im = PixelCanvas(16, 16)
    im.rect(2, 3, 12, 10, "H2")
    im.rect(3, 4, 10, 8, "L1")
    im.line(6, 3, 6, 12, "T2")
    im.line(10, 3, 10, 12, "T2")
    im.line(4, 9, 8, 6, "I1")
    im.line(8, 6, 12, 8, "E2")
    im.pset(12, 6, "Y2")
    im.add_outline("DK", selective_hue=True)
    im.save_png(os.path.join(sprites_dir, "icon_map.png"))

    # Ancient Tall Dark Hemlock Pine Variant (40x56 -> 80x112) for organic woodland depth
    pd = PixelCanvas(40, 56)
    pd.ellipse(20, 52, 12, 3.5, (14, 18, 16, 110))
    pd.rect(17, 38, 6, 15, "T0")
    pd.rect(18, 38, 3, 14, "T1")
    pd.line(19, 39, 19, 51, "T2")
    for tier, (ty, tw, th) in enumerate([(26, 16, 15), (17, 13, 14), (9, 10, 12), (2, 7, 10)]):
        for y in range(ty, ty + th):
            frac = (y - ty) / max(1.0, float(th - 1))
            jitter = ((y * 5 + tier * 2) % 3) - 1
            hw = max(1, int(frac * tw) + jitter)
            shift_x = -1 if tier % 2 == 1 else 0
            for x in range(20 + shift_x - hw, 20 + shift_x + hw + 1):
                if y == ty + th - 1 and (x + tier) % 2 == 0:
                    continue
                col = "DE" if tier < 2 else "G0"
                if y < ty + th - 4 and x < 20:
                    col = "G1" if tier < 3 else "G2"
                elif (x + y + tier) % 6 == 0 and y < ty + th - 3:
                    col = "G2"
                pd.pset(x, y, col)
    pd.add_outline("K", selective_hue=True)
    pd.save_png(os.path.join(sprites_dir, "prop_pine_dark.png"))

    # Mossy Fallen Deadfall Log (48x24)
    fl = PixelCanvas(48, 24)
    fl.ellipse(24, 16, 20, 5.5, (14, 18, 16, 95))
    fl.rect(6, 9, 34, 9, "T0")
    fl.rect(7, 10, 32, 5, "T1")
    fl.line(8, 10, 38, 10, "T2")
    fl.ellipse(40, 13.5, 3, 4.5, "T2")
    fl.ellipse(40, 13.5, 1.8, 3.0, "T3")
    for mx, my, mw in ((11, 9, 7), (22, 8, 9), (30, 10, 5)):
        fl.rect(mx, my, mw, 3, "G1")
        fl.line(mx + 1, my, mx + mw - 2, my, "G2")
    fl.rect(17, 15, 3, 2, "H2")
    fl.rect(28, 16, 2, 2, "H2")
    fl.add_outline("DK", selective_hue=True)
    fl.save_png(os.path.join(sprites_dir, "prop_fallen_log.png"))

    # Woodland Fern & Wild Mushroom Clump (24x20)
    fn = PixelCanvas(24, 20)
    fn.ellipse(12, 16, 8, 2.5, (16, 20, 16, 75))
    for fx, fy, tx, ty, fc in (
        (12, 16, 4, 8, "G0"), (12, 16, 20, 9, "G0"),
        (12, 16, 6, 5, "G1"), (12, 16, 18, 6, "G1"),
        (12, 16, 10, 3, "G2"), (12, 16, 14, 4, "G2"),
    ):
        fn.line(fx, fy, tx, ty, fc)
        fn.pset((fx + tx) // 2 - 1, (fy + ty) // 2, "G2")
        fn.pset(tx, ty + 1, "G1")
    fn.pset(9, 15, "L0")
    fn.pset(9, 14, "H2")
    fn.pset(15, 15, "L0")
    fn.pset(15, 14, "R3")
    fn.add_outline("DE", selective_hue=True)
    fn.save_png(os.path.join(sprites_dir, "prop_fern_cluster.png"))

    # Soft Atmospheric Forest Twilight Vignette (256x256, centered on player)
    vsize = 256
    vg = PixelCanvas(vsize, vsize)
    vhalf = vsize / 2.0
    for y in range(vsize):
        for x in range(vsize):
            dx = (x + 0.5 - vhalf) / vhalf
            dy = (y + 0.5 - vhalf) / vhalf
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= 0.34:
                a = 0
            else:
                t = min(1.0, (dist - 0.34) / 0.62)
                a = int(172 * (t * t * (3.0 - 2.0 * t)))
            vg.px[y * vsize + x] = [10, 16, 24, a]
    vg.save_png(os.path.join(sprites_dir, "prop_canopy_vignette.png"))

    # Smooth 128x128 radial light
    size = 128
    lt = PixelCanvas(size, size)
    half = size / 2.0
    for y in range(size):
        for x in range(size):
            dx = (x + 0.5 - half) / half
            dy = (y + 0.5 - half) / half
            dist = math.sqrt(dx * dx + dy * dy)
            if dist < 1.0:
                val = (1.0 - dist) ** 2.1
                alpha = int(max(0, min(255, val * 255)))
                lt.px[y * size + x] = [255, 228, 174, alpha]
    lt.save_png(os.path.join(sprites_dir, "light_radial.png"))


