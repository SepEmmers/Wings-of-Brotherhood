"""
World props, harbor timber, furniture, pine trees, rocks, and Brotherhood banner.
"""

import math
import os
import random
from pixel_art_lib import PAL, PixelCanvas, blend_color
from sprite_world_buildings import _draw_brick_wall


def make_props(sprites_dir: str):
    # Crate (16x16)
    cr = PixelCanvas(16, 16)
    cr.rect(2, 2, 12, 12, "T2")
    cr.rect(3, 3, 10, 10, "T3")
    cr.line(3, 3, 12, 12, "T1")
    cr.rect_outline(2, 2, 12, 12, "T0")
    cr.rect_outline(4, 4, 8, 8, "T1")
    for rx, ry in ((3, 3), (12, 3), (3, 12), (12, 12)):
        cr.pset(rx, ry, "C3")
    cr.add_outline("K", selective_hue=True)
    cr.save_png(os.path.join(sprites_dir, "prop_crate.png"))

    # Salt-herring barrel (16x16)
    br = PixelCanvas(16, 16)
    br.ellipse(8, 8, 5, 6, "T2")
    br.ellipse(8, 5, 4, 2, "T3")
    br.line(4, 7, 12, 7, "C1")
    br.line(4, 11, 12, 11, "C1")
    br.pset(8, 9, "T0")
    br.add_outline("K", selective_hue=True)
    br.save_png(os.path.join(sprites_dir, "prop_barrel.png"))

    # Coiled Hemp Rope (16x16)
    rc = PixelCanvas(16, 16)
    rc.ellipse(8, 8, 6, 5, "H0")
    rc.ellipse(8, 8, 5, 4, "H2")
    rc.ellipse(8, 8, 3, 2, "H1")
    rc.ellipse(8, 8, 1.5, 1.2, "T0")
    rc.line(11, 11, 14, 13, "H2")
    rc.add_outline("K", selective_hue=True)
    rc.save_png(os.path.join(sprites_dir, "prop_rope_coil.png"))

    # Iron Street Lantern Post (16x24)
    lp = PixelCanvas(16, 24)
    lp.rect(6, 20, 4, 3, "S")
    lp.rect(7, 10, 2, 11, "S")
    lp.line(7, 10, 7, 21, "C2")
    lp.rect(4, 3, 8, 7, "S")
    lp.rect(5, 4, 6, 5, "Y1")
    lp.rect(6, 5, 4, 3, "Y3")
    lp.line(3, 3, 12, 3, "K")
    lp.line(5, 1, 10, 1, "S")
    lp.add_outline("K", selective_hue=True)
    lp.save_png(os.path.join(sprites_dir, "prop_lantern.png"))

    # Torn Dragon-Leather Strap & Bruges Whipping-Knot Clue (16x16)
    kn = PixelCanvas(16, 16)
    kn.line(2, 11, 13, 5, "T0")
    kn.line(2, 10, 13, 4, "T2")
    kn.line(3, 9, 12, 4, "T3")
    kn.rect(6, 5, 4, 6, "H1")
    kn.line(6, 6, 9, 6, "H2")
    kn.line(6, 8, 9, 8, "H2")
    kn.rect(11, 4, 3, 3, "Y1")  # Brass buckle
    kn.pset(12, 5, "Y3")
    kn.add_outline("K", selective_hue=True)
    kn.save_png(os.path.join(sprites_dir, "prop_knot_clue.png"))

    # Wharf Mooring Bollard (16x16)
    bl = PixelCanvas(16, 16)
    bl.ellipse(8, 12, 5, 2.5, "C1")
    bl.rect(5, 5, 6, 7, "T1")
    bl.rect(6, 5, 3, 6, "T2")
    bl.ellipse(8, 5, 4, 2, "C2")
    bl.line(5, 8, 10, 9, "H2")
    bl.line(5, 10, 10, 11, "H1")
    bl.add_outline("K", selective_hue=True)
    bl.save_png(os.path.join(sprites_dir, "prop_bollard.png"))

    # Harbour Rigging Practice Post (20x28)
    rp = PixelCanvas(20, 28)
    rp.rect(8, 6, 4, 20, "T1")
    rp.line(9, 6, 9, 25, "T3")
    rp.rect(3, 4, 14, 9, "T2")
    rp.rect_outline(3, 4, 14, 9, "T0")
    # Chalk bowline diagram on board
    rp.circle(10, 8, 2, "L0")
    rp.line(6, 8, 14, 8, "L1")
    rp.ellipse(10, 22, 4, 2.5, "H2")
    rp.add_outline("K", selective_hue=True)
    rp.save_png(os.path.join(sprites_dir, "prop_rigging_post.png"))

    # Bobbing Oilskin Pouch & Clara's Brass Shuttle (16x16)
    sp = PixelCanvas(16, 16)
    sp.ellipse(8, 12, 6, 2, "W4")
    sp.ellipse(8, 8, 4.5, 4.0, "T1")
    sp.ellipse(7, 7, 3.0, 2.5, "T2")
    sp.line(5, 6, 10, 6, "H2")
    sp.line(9, 3, 12, 7, "Y2")  # gleaming brass weaving shuttle
    sp.pset(10, 4, "Y3")
    sp.add_outline("K", selective_hue=True)
    sp.save_png(os.path.join(sprites_dir, "prop_shuttle_pouch.png"))

    # Church Inquisitor Stone Herald Pulpit & Dragon-Hunter Banner (56x32)
    cp = PixelCanvas(56, 32)
    cp.rect(4, 10, 48, 18, "C1")
    cp.rect(6, 12, 44, 14, "C2")
    cp.rect_outline(4, 10, 48, 18, "C0")
    cp.rect(3, 7, 50, 4, "C3")
    # Crimson Church banner with crossed spears & dragon-slayer emblem
    cp.rect(18, 12, 20, 16, "I0")
    cp.rect(20, 13, 16, 13, "I1")
    cp.line(23, 16, 32, 23, "Y2")
    cp.line(32, 16, 23, 23, "Y2")
    cp.pset(28, 19, "L0")
    # Iron brazier posts flanking pulpit
    for bx in (6, 48):
        cp.rect(bx, 3, 2, 10, "S")
        cp.circle(bx + 1, 3, 2, "Y1")
        cp.pset(bx + 1, 2, "Y3")
    cp.add_outline("K", selective_hue=True)
    cp.save_png(os.path.join(sprites_dir, "prop_church_pulpit.png"))

    # Black-Scaled Dragon Egg in Mossy Nest (20x24)
    eg = PixelCanvas(20, 24)
    eg.ellipse(10, 17, 7.5, 4.5, "T1")
    eg.ellipse(10, 16, 6.2, 3.6, "G1")
    eg.ellipse(10, 15, 4.8, 2.5, "G2")
    # Egg ovoid
    eg.ellipse(10, 11, 4.2, 5.8, "O0")
    eg.ellipse(9.5, 10.5, 3.2, 4.6, "O1")
    eg.ellipse(8.8, 9.2, 2.0, 2.8, "O2")
    eg.pset(8, 8, "O3")
    # Warm inner amber crackle glints
    eg.pset(10, 11, "Y1")
    eg.pset(11, 13, "Y0")
    eg.pset(9, 13, "Y2")
    eg.add_outline("K", selective_hue=True)
    eg.save_png(os.path.join(sprites_dir, "prop_dragon_egg.png"))

    # Held Black-Scaled Dragon Egg (clean ovoid with zero earth/grass nest ring, 16x16)
    egh = PixelCanvas(16, 16)
    egh.ellipse(8, 8, 4.2, 5.8, "O0")
    egh.ellipse(7.5, 7.5, 3.2, 4.6, "O1")
    egh.ellipse(6.8, 6.2, 2.0, 2.8, "O2")
    egh.pset(6, 5, "O3")
    egh.pset(8, 8, "Y1")
    egh.pset(9, 10, "Y0")
    egh.pset(7, 10, "Y2")
    egh.add_outline("K", selective_hue=True)
    egh.save_png(os.path.join(sprites_dir, "prop_dragon_egg_held.png"))

    # Hatching Egg Crack Stages & Broken Shell Shards (20x24)
    for stage in (1, 2):
        ec = PixelCanvas(20, 24)
        ec.ellipse(10, 17, 7.5, 4.5, "T1")
        ec.ellipse(10, 16, 6.2, 3.6, "G1")
        ec.ellipse(10, 15, 4.8, 2.5, "G2")
        ec.ellipse(10, 11, 4.2, 5.8, "O0")
        ec.ellipse(9.5, 10.5, 3.2, 4.6, "O1")
        ec.ellipse(8.8, 9.2, 2.0, 2.8, "O2")
        ec.pset(8, 8, "O3")
        # Glowing fissures across upper shell
        ec.line(8, 7, 11, 10, "Y2")
        ec.line(11, 10, 9, 13, "Y1")
        ec.pset(10, 10, "Y3")
        if stage == 2:
            ec.line(11, 10, 13, 8, "Y3")
            ec.line(9, 13, 12, 15, "Y2")
            ec.line(7, 10, 10, 11, "Y3")
            ec.rect(9, 10, 3, 2, "Y3")
        ec.add_outline("K", selective_hue=True)
        ec.save_png(os.path.join(sprites_dir, f"prop_dragon_egg_crack{stage}.png"))

    esh = PixelCanvas(20, 24)
    esh.ellipse(10, 17, 7.5, 4.5, "T1")
    esh.ellipse(10, 16, 6.2, 3.6, "G1")
    esh.ellipse(10, 15, 4.8, 2.5, "G2")
    # Cracked lower bowl & fallen obsidian shell shards
    esh.ellipse(10, 14, 4.0, 2.8, "O0")
    esh.ellipse(10, 14, 3.0, 1.8, "K")
    esh.rect(7, 12, 2, 2, "O2")
    esh.rect(11, 12, 2, 2, "O3")
    esh.rect(4, 17, 3, 2, "O1")
    esh.pset(5, 17, "O3")
    esh.rect(14, 16, 3, 2, "O1")
    esh.pset(15, 16, "O3")
    esh.add_outline("K", selective_hue=True)
    esh.save_png(os.path.join(sprites_dir, "prop_dragon_egg_shards.png"))

    # Church Hunter Iron Net-Cage (56x46 -> 112x92)
    cg = PixelCanvas(56, 46)
    cg.rect(3, 3, 50, 40, "T0")
    cg.rect(5, 5, 46, 36, (20, 22, 28, 85))
    for bx in range(8, 50, 7):
        cg.rect(bx, 4, 2, 38, "C2")
        cg.line(bx, 4, bx, 41, "C3")
    for by in range(9, 40, 10):
        cg.rect(4, by, 48, 2, "C1")
    # Heavy crimson-sealed Church iron padlock in center
    cg.rect(22, 16, 12, 12, "S")
    cg.rect(23, 17, 10, 10, "I1")
    cg.rect(26, 20, 4, 4, "Y2")
    cg.add_outline("K", selective_hue=True)
    cg.save_png(os.path.join(sprites_dir, "prop_hunter_cage.png"))

    # Shattered Iron Cage Debris (56x46)
    cgb = PixelCanvas(56, 46)
    cgb.rect(3, 33, 50, 10, "T0")
    cgb.rect(3, 3, 5, 34, "T1")
    cgb.rect(48, 3, 5, 34, "T1")
    cgb.line(5, 8, 15, 16, "C3")
    cgb.line(15, 16, 11, 36, "C2")
    cgb.line(50, 9, 41, 18, "C3")
    cgb.line(41, 18, 44, 36, "C2")
    cgb.line(14, 38, 25, 32, "C1")
    # Busted Church padlock lying in moss
    cgb.rect(25, 36, 8, 7, "I1")
    cgb.rect(27, 38, 3, 3, "Y2")
    cgb.add_outline("K", selective_hue=True)
    cgb.save_png(os.path.join(sprites_dir, "prop_cage_broken.png"))

    # Cottage Interior Props: Stone Hearth (32x48), Supper Table (56x32), Straw Pallet Bed (40x28)
    ht = PixelCanvas(32, 48)
    _draw_brick_wall(ht, 3, 2, 26, 44, "C0", "C1", "C2")
    ht.rect(2, 28, 28, 4, "T2")  # oak mantelpiece
    ht.rect(8, 32, 16, 14, "N")
    ht.rect(10, 41, 12, 4, "T0")
    ht.circle(16, 39, 5, "Y1")
    ht.circle(16, 38, 3, "Y2")
    ht.pset(16, 37, "Y3")
    ht.add_outline("K", selective_hue=True)
    ht.save_png(os.path.join(sprites_dir, "prop_hearth.png"))

    tb = PixelCanvas(56, 32)
    tb.rect(4, 20, 5, 10, "T0")
    tb.rect(47, 20, 5, 10, "T0")
    tb.rect(2, 5, 52, 19, "T2")
    tb.rect(4, 7, 48, 15, "T3")
    tb.rect(22, 5, 12, 19, "L0")  # linen table runner
    tb.rect(23, 6, 10, 17, "L1")
    # Crusty rye loaf + wooden trencher + candle
    tb.ellipse(28, 14, 5, 3, "Y0")
    tb.ellipse(28, 13, 4, 2, "Y1")
    tb.rect(42, 9, 4, 6, "L0")
    tb.pset(44, 7, "Y2")
    tb.pset(44, 6, "Y3")
    tb.circle(14, 14, 3, "C2")
    tb.add_outline("K", selective_hue=True)
    tb.save_png(os.path.join(sprites_dir, "prop_table_supper.png"))

    bd = PixelCanvas(40, 28)
    # Four-post oak frame & carved headboard
    bd.rect(2, 2, 36, 24, "T0")
    bd.rect(3, 3, 34, 22, "T2")
    bd.rect(1, 1, 4, 26, "T1")
    bd.rect(2, 1, 2, 5, "T3")  # turned oak post top highlights
    bd.rect(35, 1, 4, 26, "T1")
    bd.rect(36, 1, 2, 5, "T3")
    # Straw ticking mattress edge & plump feather pillow
    bd.rect(5, 5, 30, 18, "H1")
    bd.rect(27, 6, 8, 16, "L1")
    bd.rect(28, 7, 6, 14, "L0")
    # Homespun checkered indigo & oatmeal wool quilt + fold
    for qy in range(5, 23):
        for qx in range(5, 26):
            check = ((qx // 3) + (qy // 3)) % 2 == 0
            col = "U1" if check else "U2"
            if qy >= 20:
                col = "U0"
            bd.pset(qx, qy, col)
    bd.rect(24, 5, 3, 18, "L1")  # folded cream sheet cuff
    bd.line(24, 5, 24, 22, "L2")
    bd.add_outline("K", selective_hue=True)
    bd.save_png(os.path.join(sprites_dir, "prop_bed.png"))

    # Boy Tucked Asleep Under Bed Quilt (40x28)
    bds = PixelCanvas(40, 28)
    bds.rect(2, 2, 36, 24, "T0")
    bds.rect(3, 3, 34, 22, "T2")
    bds.rect(1, 1, 4, 26, "T1")
    bds.rect(2, 1, 2, 5, "T3")
    bds.rect(35, 1, 4, 26, "T1")
    bds.rect(36, 1, 2, 5, "T3")
    bds.rect(5, 5, 30, 18, "H1")
    bds.rect(27, 6, 8, 16, "L1")
    bds.rect(28, 7, 6, 14, "L0")
    # Pulled-up checkered wool quilt & mounded shoulder bulge
    for qy in range(5, 23):
        for qx in range(5, 27):
            check = ((qx // 3) + (qy // 3)) % 2 == 0
            col = "U2" if (8 <= qy <= 18 and 11 <= qx <= 24 and not check) else ("U1" if check else "U2")
            if qy >= 20:
                col = "U0"
            bds.pset(qx, qy, col)
    bds.rect(25, 5, 3, 18, "L1")
    bds.line(25, 5, 25, 22, "L2")
    # Boy's chestnut hair & sleeping profile on the pillow
    bds.ellipse(30, 13, 4.2, 4.5, "B0")
    bds.ellipse(30, 12, 3.6, 3.5, "B1")
    bds.ellipse(29, 14, 2.8, 3.0, "P2")
    bds.rect(29, 9, 4, 2, "B2")
    bds.line(27, 13, 29, 13, "K")  # closed eye lash
    bds.line(28, 15, 30, 15, "P1")
    bds.add_outline("K", selective_hue=True)
    bds.save_png(os.path.join(sprites_dir, "prop_bed_sleeping.png"))

    # Winch-Dash Capstan Post & Brass Hook Crown (24x32 -> 44x58)
    wp = PixelCanvas(24, 32)
    # Ground shadow & mortared cobblestone collar so post sits flush on bank
    wp.ellipse(12, 28, 7.6, 2.6, (14, 16, 20, 115))
    wp.ellipse(12, 26, 6.2, 2.8, "C0")
    wp.ellipse(12, 25, 5.0, 2.0, "C2")
    wp.pset(10, 24, "C3")
    # Heavy octagonal chamfered oak capstan shaft with woodgrain
    wp.rect(8, 10, 8, 16, "T0")
    wp.rect(9, 10, 5, 16, "T1")
    wp.rect(10, 10, 2, 16, "T2")
    wp.line(10, 11, 10, 24, "T3")
    # Iron binding hoops at base & collar
    wp.rect(7, 21, 10, 2, "S")
    wp.line(8, 21, 15, 21, "C3")
    wp.rect(7, 11, 10, 2, "S")
    wp.line(8, 11, 15, 11, "C3")
    # Coiled golden hemp rope drum around waist of winch
    for ry, col_r in ((14, "H0"), (15, "H2"), (16, "H1"), (17, "H2"), (18, "H0")):
        wp.rect(7, ry, 10, 1, col_r)
        wp.pset(9, ry, "H3")
    # Side iron crank handle & brass ratchet wheel
    wp.rect(4, 14, 3, 2, "C2")
    wp.rect(3, 12, 2, 5, "T2")
    wp.pset(3, 12, "C4")
    wp.rect(17, 13, 2, 4, "Y0")
    wp.pset(18, 14, "Y2")
    # Brotherhood emerald badge plate + brass grappling ring crown
    wp.rect(6, 7, 12, 4, "E0")
    wp.rect(7, 8, 10, 2, "E2")
    wp.line(8, 8, 13, 8, "E3")
    wp.circle(12, 5, 3, "Y0")
    wp.circle(12, 5, 2, "Y2")
    wp.pset(12, 5, "S")
    wp.pset(11, 3, "Y3")
    wp.add_outline("K", selective_hue=True)
    wp.save_png(os.path.join(sprites_dir, "prop_winch_post.png"))

    # Roman Stone Milestone (16x24)
    ms = PixelCanvas(16, 24)
    ms.rect(4, 6, 8, 15, "C1")
    ms.ellipse(8, 6, 4, 2.5, "C2")
    ms.rect(5, 6, 5, 13, "C2")
    ms.line(6, 10, 10, 10, "C0")
    ms.line(6, 13, 9, 13, "C0")
    ms.pset(5, 18, "G1")
    ms.pset(10, 19, "G0")
    ms.add_outline("K", selective_hue=True)
    ms.save_png(os.path.join(sprites_dir, "prop_milestone.png"))

    # Scorched Pine & Broken Church Ballista Bolt Clue (32x24)
    sc = PixelCanvas(32, 24)
    sc.ellipse(16, 14, 13, 7, "N")
    sc.ellipse(16, 14, 10, 5, "C0")
    sc.line(5, 17, 25, 8, "T1")
    sc.line(6, 18, 26, 9, "T0")
    sc.line(18, 12, 28, 6, "I1")  # crimson ballista feathers
    sc.pset(10, 12, "O2")          # fallen obsidian dragon scale
    sc.pset(11, 12, "O3")
    sc.pset(20, 16, "O2")
    sc.save_png(os.path.join(sprites_dir, "prop_scorched_clue.png"))

    # Animated Wilderness Campfire (28x24, 2 frames) — Creek-stone hearth ring, glowing oak logs & vivid 2-frame flame
    for frame in (0, 1):
        cf = PixelCanvas(28, 24)
        # Warm hearth soot & glow halo beneath logs
        cf.ellipse(14, 16, 12.0, 6.0, (24, 18, 16, 125))
        cf.ellipse(14, 15, 8.5, 4.0, (42, 24, 14, 130))
        # Wide faceted creek-stone ring (back stones first, front stones below logs)
        back_stones = ((6, 13), (11, 11), (17, 11), (22, 13))
        front_stones = ((4, 16), (8, 19), (14, 20), (20, 19), (24, 16))
        for rx, ry in back_stones:
            cf.ellipse(rx, ry, 2.8, 2.0, "C0")
            cf.ellipse(rx, ry, 2.0, 1.4, "C2")
            cf.pset(rx, ry - 1, "C3")
        # Crossed charred firewood logs with glowing red ember seams
        cf.line(6, 17, 21, 12, "T0")
        cf.line(6, 16, 21, 11, "T2")
        cf.line(7, 12, 22, 17, "T0")
        cf.line(7, 11, 21, 16, "T1")
        cf.rect(11, 13, 6, 3, "I1")
        cf.rect(12, 14, 4, 2, "R2")
        cf.pset(13 + frame, 14, "Y2")
        # Lively multi-tone flickering campfire flame tongue
        sway = -1 if frame == 1 else 1
        h_tip = 2 if frame == 1 else 3
        cf.ellipse(14, 12, 5.0, 4.0, "R2")
        cf.ellipse(14 + sway // 2, 10, 4.0, 4.5, "R3")
        cf.ellipse(14, 9, 3.0, 4.2, "Y1")
        cf.ellipse(14 - sway, 10, 2.0, 2.8, "Y2")
        cf.line(14, 7, 14 + sway, h_tip, "Y2")
        cf.pset(14, 9, "Y3")
        cf.pset(14 - sway, 11, "L0")
        # Rising amber embers
        cf.pset(10 + frame * 7, 4, "Y2")
        cf.pset(17 - frame * 5, 2, "Y3")
        for rx, ry in front_stones:
            cf.ellipse(rx, ry, 2.8, 2.1, "K")
            cf.ellipse(rx, ry, 2.2, 1.6, "C1")
            cf.ellipse(rx - 0.3, ry - 0.3, 1.4, 1.0, "C2")
            cf.pset(rx - 1, ry - 1, "C3")
        cf.save_png(os.path.join(sprites_dir, f"prop_campfire_{frame}.png"))

    # Queue 13 Book II Companion & City Stealth Props
    # 1. Hooded Leather Hatchling Travel-Sling (16x16 inventory/tooltip badge + 5 directional 24x28 worn Boy overlays)
    sl = PixelCanvas(16, 16)
    sl.ellipse(8, 10, 6.0, 4.5, "T0")
    sl.ellipse(8, 9, 5.2, 3.8, "E0")
    sl.ellipse(8, 8, 4.2, 3.0, "E1")
    sl.line(2, 4, 13, 12, "T1")
    sl.line(3, 3, 14, 11, "T2")
    sl.rect(10, 5, 3, 3, "Y0")
    sl.pset(11, 6, "Y3")
    # Snug tucked obsidian hatchling face peeking out of emerald hood fold
    sl.ellipse(8, 9, 2.8, 2.2, "O1")
    sl.pset(6, 7, "Y2")
    sl.pset(10, 7, "Y2")
    sl.pset(7, 9, "Y2")
    sl.pset(9, 9, "Y2")
    sl.line(5, 11, 11, 11, "E2")
    sl.add_outline("K", selective_hue=True)
    sl.save_png(os.path.join(sprites_dir, "prop_hatchling_sling.png"))

    def _draw_sling_dragon_head(c: PixelCanvas, hx: int, hy: int, side_look: bool = False) -> None:
        # Cozy soot-black dragonet head with gold horn tips & warm ember eye
        c.ellipse(hx, hy, 2.3, 1.9, "O0")
        c.ellipse(hx, hy, 1.6, 1.3, "O1")
        c.pset(hx - 1, hy - 2, "O2")
        c.pset(hx + 1, hy - 2, "Y2")
        c.pset(hx - 2 if not side_look else hx - 1, hy - 2, "Y1")
        if side_look:
            c.pset(hx + 1, hy, "Y3")
            c.pset(hx, hy, "Y1")
        else:
            c.pset(hx - 1, hy, "Y2")
            c.pset(hx + 1, hy, "Y3")

    # (a) Down (front): snug diagonal emerald sling & bright tucked soot dragonet head + tiny gold wing-edge across left chest
    sd = PixelCanvas(24, 28)
    sd.line(15, 11, 7, 19, "T0", 2)
    sd.line(15, 11, 8, 18, "T2")
    sd.pset(14, 12, "Y2")
    sd.ellipse(10, 17, 4.2, 3.0, "E0")
    sd.ellipse(10, 17, 3.4, 2.3, "E1")
    sd.line(7, 17, 13, 17, "E2")
    sd.line(8, 18, 12, 18, "E2")
    _draw_sling_dragon_head(sd, 10, 15, False)
    sd.pset(12, 16, "Y1")
    sd.add_outline("K", selective_hue=True)
    sd.save_png(os.path.join(sprites_dir, "prop_hatchling_sling_down.png"))

    # (b) Diag-Down (3/4 front-right): strap across chest, pocket shifted slightly right toward viewer
    sdd = PixelCanvas(24, 28)
    sdd.line(9, 12, 16, 18, "T0", 2)
    sdd.line(9, 12, 15, 17, "T2")
    sdd.pset(10, 13, "Y2")
    sdd.ellipse(13, 16, 3.5, 2.7, "E0")
    sdd.ellipse(13, 16, 2.8, 2.0, "E1")
    sdd.line(10, 16, 16, 16, "E2")
    _draw_sling_dragon_head(sdd, 14, 14, True)
    sdd.add_outline("K", selective_hue=True)
    sdd.save_png(os.path.join(sprites_dir, "prop_hatchling_sling_diag_down.png"))

    # (c) Side (facing right; flipped horizontally by PlayerBoy when facing left)
    ss = PixelCanvas(24, 28)
    ss.line(9, 12, 14, 18, "T0", 2)
    ss.line(9, 12, 13, 17, "T2")
    ss.pset(10, 14, "Y2")
    ss.ellipse(14, 16, 3.3, 2.7, "E0")
    ss.ellipse(14, 16, 2.6, 2.0, "E1")
    ss.line(12, 16, 16, 16, "E2")
    _draw_sling_dragon_head(ss, 15, 14, True)
    ss.add_outline("K", selective_hue=True)
    ss.save_png(os.path.join(sprites_dir, "prop_hatchling_sling_side.png"))

    # (d) Up (back): snug leather shoulder sling & wrapped emerald wool hood across upper back (never floats detached)
    su = PixelCanvas(24, 28)
    su.line(8, 12, 16, 18, "T0", 2)
    su.line(8, 12, 15, 17, "T2")
    su.pset(9, 13, "Y2")
    su.ellipse(12, 16, 3.8, 2.9, "E0")
    su.ellipse(12, 15, 3.0, 2.1, "E1")
    su.line(9, 14, 15, 14, "E2")
    # Tiny curled soot tail-tip & golden ear-crest peeking from back hood fold
    su.ellipse(13, 14, 1.8, 1.3, "O1")
    su.pset(14, 13, "Y2")
    su.pset(12, 13, "O2")
    su.add_outline("K", selective_hue=True)
    su.save_png(os.path.join(sprites_dir, "prop_hatchling_sling_up.png"))

    # (e) Diag-Up (3/4 back-right)
    sdu = PixelCanvas(24, 28)
    sdu.line(9, 12, 16, 17, "T0", 2)
    sdu.line(9, 12, 15, 16, "T2")
    sdu.pset(10, 13, "Y2")
    sdu.ellipse(13, 16, 3.5, 2.7, "E0")
    sdu.ellipse(13, 15, 2.8, 2.0, "E1")
    sdu.line(10, 14, 16, 14, "E2")
    sdu.ellipse(14, 14, 1.9, 1.4, "O1")
    sdu.pset(15, 13, "Y2")
    sdu.add_outline("K", selective_hue=True)
    sdu.save_png(os.path.join(sprites_dir, "prop_hatchling_sling_diag_up.png"))

    # 2. Church Inquisitor Wanted Bounty Poster (14x18)
    wp = PixelCanvas(14, 18)
    wp.rect(1, 2, 12, 15, "T0")
    wp.rect(2, 2, 10, 14, "L1")
    wp.rect(3, 3, 8, 12, "L0")
    # Carved notched lower parchment tear + brass nail/crimson seal header
    wp.pset(11, 15, ".")
    wp.pset(7, 2, "C3")
    wp.rect(4, 3, 6, 1, "I1")
    # Charcoal woodcut silhouette of black-and-gold dragon / boy
    wp.rect(5, 5, 4, 5, "O0")
    wp.rect(4, 6, 6, 3, "O1")
    wp.pset(6, 7, "Y2")
    wp.pset(8, 7, "Y2")
    # Calligraphy bounty lines & crimson Inquisition wax dot
    wp.line(4, 11, 9, 11, "T1")
    wp.line(4, 13, 8, 13, "T1")
    wp.circle(10, 13, 1.5, "I1")
    wp.pset(10, 13, "I2")
    wp.add_outline("K", selective_hue=True)
    wp.save_png(os.path.join(sprites_dir, "prop_wanted_poster.png"))

    # 3. Acoustic Resonance Chime Decoy Bell (16x16)
    rc_ch = PixelCanvas(16, 16)
    # Small forked oak stand & hanging brass bell
    rc_ch.line(4, 14, 6, 4, "T0")
    rc_ch.line(11, 14, 9, 4, "T0")
    rc_ch.rect(4, 3, 8, 2, "T2")
    rc_ch.line(4, 3, 11, 3, "T3")
    # Hammered bronze chime bell in center + glowing clapper
    rc_ch.rect(6, 6, 4, 5, "Y1")
    rc_ch.rect(5, 10, 6, 2, "Y0")
    rc_ch.line(6, 6, 9, 6, "Y3")
    rc_ch.line(6, 8, 6, 10, "Y2")
    rc_ch.pset(8, 12, "Y3")
    # Faint shimmer ripple pixels beside bell
    rc_ch.pset(3, 8, "Y2")
    rc_ch.pset(2, 7, "Y3")
    rc_ch.pset(12, 8, "Y2")
    rc_ch.pset(13, 7, "Y3")
    rc_ch.add_outline("K", selective_hue=True)
    rc_ch.save_png(os.path.join(sprites_dir, "prop_resonance_chime.png"))

    # 4. Alchemical Ash & Pitch Smoke Pellet (16x16)
    sm = PixelCanvas(16, 16)
    sm.ellipse(8, 10, 5.0, 4.5, "SG0")
    sm.ellipse(8, 10, 4.2, 3.8, "SG1")
    sm.ellipse(7, 9, 2.5, 2.0, "SG2")
    # Tied hemp cord collar & parchment/beeswax twist + sparkling ember wick
    sm.rect(6, 5, 4, 2, "H1")
    sm.line(6, 5, 9, 5, "H2")
    sm.rect(7, 3, 2, 2, "L1")
    sm.pset(9, 2, "R2")
    sm.pset(10, 2, "Y3")
    sm.pset(6, 11, "C4")
    sm.add_outline("K", selective_hue=True)
    sm.save_png(os.path.join(sprites_dir, "prop_smoke_pellet.png"))

    # Frontier Pine Tree (36x48 -> 72x96) with organic jagged boughs & bark texture
    pt = PixelCanvas(36, 48)
    pt.ellipse(18, 44, 11, 3, (18, 22, 18, 100))
    pt.rect(15, 33, 6, 12, "T0")
    pt.rect(16, 33, 3, 11, "T1")
    pt.line(17, 34, 17, 44, "T2")
    for tier, (ty, tw, th) in enumerate([(21, 14, 15), (12, 11, 13), (4, 8, 11)]):
        for y in range(ty, ty + th):
            frac = (y - ty) / max(1.0, float(th - 1))
            # Jagged bough notches on lower edge & clusters
            jitter = ((y * 3 + tier) % 3) - 1
            hw = max(1, int(frac * tw) + jitter)
            for x in range(18 - hw, 18 + hw + 1):
                # Irregular tufted hem at tier bottom
                if y == ty + th - 1 and (x + tier) % 3 == 0:
                    continue
                col = "G1"
                if y >= ty + th - 3:
                    col = "G0"
                elif x < 17 and y < ty + th - 3:
                    col = "G2"
                if x < 16 and (x + y) % 5 == 0 and y < ty + th - 4:
                    col = "G3"
                pt.pset(x, y, col)
    pt.add_outline("K", selective_hue=True)
    pt.save_png(os.path.join(sprites_dir, "prop_pine_tree.png"))

    # Craggy Faceted Cliff Outcrop (32x32)
    rk = PixelCanvas(32, 32)
    # Angular faceted stone polyhedron rather than smooth circle
    for y in range(5, 29):
        row_noise = ((y * 5) % 3) - 1
        x0 = max(3, int(6 + abs(y - 18) * 0.45) + row_noise)
        x1 = min(29, int(28 - max(0, 12 - y) * 0.7 - max(0, y - 22) * 0.6))
        for x in range(x0, x1):
            col = "C1"
            if y < 12 or x < x0 + 5:
                col = "C2"
            if y < 9 and x < 18:
                col = "C3"
            if y >= 22 or x >= x1 - 4:
                col = "C0"
            rk.pset(x, y, col)
    # Sharp diagonal rock fracture planes & moss tufts
    rk.line(8, 12, 22, 10, "C3")
    rk.line(9, 13, 23, 11, "C0")
    rk.line(18, 11, 21, 25, "C0")
    rk.line(11, 18, 17, 25, "C0")
    rk.rect(19, 22, 3, 2, "G1")
    rk.pset(20, 21, "G2")
    rk.pset(7, 16, "G1")
    rk.add_outline("K", selective_hue=True)
    rk.save_png(os.path.join(sprites_dir, "prop_cliff_rock.png"))

    # Brotherhood Pennant Banner (24x38) — Framed Hanging Standard with Twin-Wing Crest
    bn = PixelCanvas(24, 38)
    # Corded hanging loop & iron-tipped oak crossbar
    bn.line(11, 1, 7, 5, "H2")
    bn.line(12, 1, 16, 5, "H2")
    bn.rect(11, 2, 2, 34, "T1")
    bn.rect(3, 5, 18, 2, "T3")
    bn.line(3, 6, 20, 6, "T0")
    bn.rect(2, 4, 2, 3, "Y2")
    bn.rect(20, 4, 2, 3, "Y2")
    # Swallowtail emerald heraldic cloth with gold piping & fold shading
    for y in range(7, 30):
        # Swallowtail bottom cutout at y=24..29
        for x in range(5, 19):
            if y >= 24 and abs(x - 11.5) < (y - 23) * 1.1:
                continue
            col = "E1"
            if x in (5, 18) or y == 7:
                col = "Y1"
            elif x in (6, 17):
                col = "E0"
            elif 9 <= x <= 14:
                col = "E2"
            bn.pset(x, y, col)
    # Bottom gold fringe tassels on swallowtail tips
    for tx in (5, 7, 16, 18):
        bn.pset(tx, 30, "Y2")
    # Woven Golden Twin Dragon Wings & Carabiner Diamond Brotherhood Emblem
    for sign in (-1, 1):
        cx = 11 if sign < 0 else 12
        bn.line(cx + sign * 2, 16, cx + sign * 5, 12, "Y3")
        bn.line(cx + sign * 2, 17, cx + sign * 5, 14, "Y2")
        bn.line(cx + sign * 2, 18, cx + sign * 4, 17, "Y1")
    for dy in range(-3, 4):
        hw = max(0, 2 - abs(dy) // 2)
        bn.rect(11 - hw, 16 + dy, hw * 2 + 2, 1, "Y2")
    bn.rect(11, 15, 2, 2, "I1")
    bn.pset(11, 15, "Y3")
    bn.add_outline("K", selective_hue=True)
    bn.save_png(os.path.join(sprites_dir, "prop_brotherhood_banner.png"))

    # Folded Dropped Parchment Writ / Note with Ink Script & Crimson Wax Seal (24x24)
    dn = PixelCanvas(24, 24)
    dn.ellipse(12, 18, 9, 3, (14, 15, 22, 105))
    # Slightly diamond-angled parchment folio resting on cobbles
    for y in range(6, 19):
        x0 = 4 + max(0, (10 - y) // 2)
        x1 = 19 - max(0, (y - 14) // 2)
        for x in range(x0, x1 + 1):
            col = "L1" if (x >= x1 - 1 or y >= 17) else "L0"
            dn.pset(x, y, col)
    dn.rect_outline(5, 7, 13, 10, "T2")
    # Dark ink calligraphy lines + creased fold
    dn.line(6, 9, 15, 9, "C0")
    dn.line(6, 11, 16, 11, "T0")
    dn.line(6, 13, 13, 13, "C0")
    dn.line(5, 12, 17, 12, "L2")
    # Bright crimson Inquisition wax seal stamped on lower-right corner
    dn.circle(15, 15, 2.4, "I0")
    dn.circle(15, 15, 1.5, "I2")
    dn.pset(15, 14, "Y2")
    dn.add_outline("K", selective_hue=True)
    dn.save_png(os.path.join(sprites_dir, "prop_dropped_note.png"))

    # Pokemon Emerald-style NPC Exclamation Alert Badge (16x18)
    eb = PixelCanvas(16, 18)
    eb.rect(2, 2, 12, 11, "L0")
    eb.rect(3, 3, 10, 9, "L1")
    eb.rect_outline(2, 2, 12, 11, "K")
    # Speech tail
    eb.rect(6, 13, 4, 2, "L0")
    eb.rect(7, 15, 2, 2, "K")
    eb.pset(7, 14, "L1")
    # Bold crimson exclamation mark with warm highlight
    eb.rect(7, 4, 2, 5, "I1")
    eb.pset(7, 4, "I2")
    eb.rect(7, 10, 2, 2, "I1")
    eb.add_outline("K", selective_hue=True)
    eb.save_png(os.path.join(sprites_dir, "ui_exclamation_badge.png"))

