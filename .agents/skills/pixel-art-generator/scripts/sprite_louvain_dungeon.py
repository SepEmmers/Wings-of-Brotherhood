"""
Cathedral Nave, Vaulted Catacombs Crypt, and Hidden Scriptorium Library Sprites
for Louvain's 3-Floor Zelda-style Interior Dungeon.

Palette-locked to pixel_art_lib.PAL for crisp nearest-neighbor 3/4 rendering:
  - tile_cathedral_flag.png / _2.png, tile_catacomb_stone.png / _2.png, tile_library_wood.png / _2.png
  - prop_church_pew.png (48x24), prop_stained_altar.png (56x34), prop_altar_candle.png (16x28)
  - prop_crypt_stairs.png (40x44), prop_hidden_ladder.png (28x34), prop_crypt_pillar.png (28x44)
  - prop_sarcophagus_cross/crown/chalice/stag.png (34x44)
  - prop_crypt_tapestry.png (48x40), prop_library_shelf.png (48x44), prop_date_lectern.png (28x30)
  - prop_floor_spikes_down.png / _up.png (28x24), prop_dart_trap.png (22x22)
"""

import os
import random
from pixel_art_lib import PAL, PixelCanvas


def _make_dungeon_tiles(sprites_dir: str) -> None:
    # 1. Cathedral Nave Checkered Ivory & Slate Limestone Flags (16x16)
    for var_i, fname in enumerate(("tile_cathedral_flag.png", "tile_cathedral_flag_2.png")):
        c = PixelCanvas(16, 16, "C0")
        for ty in (0, 8):
            for tx in (0, 8):
                light_sq = ((tx // 8 + ty // 8 + var_i) % 2) == 0
                base = "L1" if light_sq else "C2"
                hi = "L2" if light_sq else "C3"
                sh = "H2" if light_sq else "C1"
                c.rect(tx, ty, 7, 7, base)
                c.line(tx, ty, tx + 6, ty, hi)
                c.line(tx, ty + 6, tx + 6, ty + 6, sh)
        if var_i == 1:
            c.pset(3, 4, "H2")
            c.pset(12, 11, "C1")
        c.save_png(os.path.join(sprites_dir, fname))

    # 2. Catacombs Damp Crypt Flagstones (16x16)
    for var_i, fname in enumerate(("tile_catacomb_stone.png", "tile_catacomb_stone_2.png")):
        rng = random.Random(300 + var_i * 19)
        c = PixelCanvas(16, 16, "S")
        for ry, rh in ((0, 7), (8, 7)):
            x0 = 0 if ry == 0 else -4
            for col_i in range(3):
                sx = x0 + col_i * 8
                col = "CS" if rng.random() < 0.6 else "C0"
                c.rect(max(0, sx), ry, 7, rh, col)
                c.line(max(0, sx), ry, min(15, sx + 6), ry, "C1")
        if var_i == 1:
            c.pset(5, 3, "G0")
            c.pset(11, 12, "G1")
        c.save_png(os.path.join(sprites_dir, fname))

    # 3. Hidden Library Aged Oak Parquet Planks (16x16)
    for var_i, fname in enumerate(("tile_library_wood.png", "tile_library_wood_2.png")):
        c = PixelCanvas(16, 16, "T0")
        for row_i, py in enumerate(range(0, 16, 4)):
            col = "T2" if (row_i + var_i) % 2 == 0 else "T1"
            c.rect(0, py, 16, 3, col)
            c.line(0, py, 15, py, "T3")
            seam = 4 + (row_i * 5 + var_i * 3) % 10
            c.line(seam, py, seam, py + 2, "T0")
        c.save_png(os.path.join(sprites_dir, fname))


def _make_cathedral_and_crypt_props(sprites_dir: str) -> None:
    # 1. Carved Oak Church Pew with Burgundy Kneeler Cushion (48x24)
    pw = PixelCanvas(48, 24)
    pw.ellipse(24, 21, 22, 2.5, (14, 12, 18, 110))
    pw.rect(3, 5, 42, 14, "T1")
    pw.rect(4, 6, 40, 5, "T3")
    pw.line(4, 6, 43, 6, "T4")
    # Carved finial posts
    for ex in (2, 42):
        pw.rect(ex, 3, 4, 17, "T2")
        pw.line(ex, 3, ex + 3, 3, "Y2")
    # Velvet seat cushion + hymnal rail
    pw.rect(5, 11, 38, 5, "I1")
    pw.line(5, 11, 42, 11, "I2")
    pw.rect(5, 16, 38, 3, "T0")
    pw.add_outline("K", selective_hue=True)
    pw.save_png(os.path.join(sprites_dir, "prop_church_pew.png"))

    # 2. Stained-Marble High Altar & Gold Chalice (56x34)
    al = PixelCanvas(56, 34)
    al.ellipse(28, 30, 26, 3.5, (14, 12, 18, 120))
    al.rect(5, 12, 46, 17, "C2")
    al.rect(6, 13, 44, 15, "L1")
    # Crimson & gold altar cloth runner centered
    al.rect(18, 12, 20, 17, "I0")
    al.rect(20, 13, 16, 15, "I1")
    al.line(28, 15, 28, 25, "Y2")
    al.line(25, 19, 31, 19, "Y2")
    # Marble mensa tabletop & brass candlesticks + central gold reliquary chalice
    al.rect(3, 8, 50, 5, "L2")
    al.line(3, 8, 52, 8, "L1")
    al.rect(26, 2, 4, 6, "Y2")
    al.line(25, 2, 30, 2, "Y3")
    al.rect(11, 4, 2, 5, "Y1")
    al.rect(43, 4, 2, 5, "Y1")
    al.add_outline("K", selective_hue=True)
    al.save_png(os.path.join(sprites_dir, "prop_stained_altar.png"))

    # 3. Brass Floor Candelabra (16x28) - flame added dynamically when lit!
    cn = PixelCanvas(16, 28)
    cn.ellipse(8, 25, 5, 2.0, (14, 12, 18, 100))
    cn.rect(6, 22, 4, 3, "Y1")
    cn.line(5, 24, 10, 24, "Y0")
    cn.rect(7, 10, 2, 12, "Y2")
    cn.line(4, 12, 11, 12, "Y1")
    for wx in (4, 7, 11):
        cn.rect(wx, 7, 2, 5, "L2")
        cn.pset(wx, 6, "T2")
    cn.add_outline("K", selective_hue=True)
    cn.save_png(os.path.join(sprites_dir, "prop_altar_candle.png"))

    # 4. Descending Stone Crypt Stairwell (40x44)
    st = PixelCanvas(40, 44)
    st.rect(2, 2, 36, 40, "S")
    st.rect(4, 4, 32, 36, "K")
    for step_i in range(6):
        sy = 5 + step_i * 5
        shade = "C3" if step_i < 2 else ("C2" if step_i < 4 else "C0")
        st.rect(6, sy, 28, 4, shade)
        st.line(6, sy, 33, sy, "L1" if step_i < 2 else "C1")
    st.rect(2, 2, 4, 40, "C1")
    st.rect(34, 2, 4, 40, "C1")
    st.rect(2, 2, 36, 4, "C2")
    st.save_png(os.path.join(sprites_dir, "prop_crypt_stairs.png"))

    # 5. Revealed Under-Tomb Hidden Shaft Ladder (28x34)
    ld = PixelCanvas(28, 34)
    ld.rect(2, 2, 24, 30, "C0")
    ld.rect(4, 4, 20, 26, "K")
    ld.line(8, 5, 8, 29, "T3")
    ld.line(19, 5, 19, 29, "T3")
    for ry in range(7, 28, 5):
        ld.line(8, ry, 19, ry, "T4")
        ld.line(8, ry + 1, 19, ry + 1, "T1")
    ld.rect(2, 2, 24, 3, "C2")
    ld.save_png(os.path.join(sprites_dir, "prop_hidden_ladder.png"))

    # 6. Fluted Catacomb Gothic Stone Column (28x44)
    pl = PixelCanvas(28, 44)
    pl.ellipse(14, 40, 11, 3.0, (14, 12, 18, 115))
    pl.rect(5, 34, 18, 6, "C1")
    pl.rect(7, 8, 14, 26, "C2")
    pl.line(9, 8, 9, 33, "C3")
    pl.line(13, 8, 13, 33, "C1")
    pl.line(18, 8, 18, 33, "CS")
    pl.rect(4, 3, 20, 6, "C3")
    pl.line(4, 3, 23, 3, "L1")
    pl.add_outline("K", selective_hue=True)
    pl.save_png(os.path.join(sprites_dir, "prop_crypt_pillar.png"))

    # 7. Four Pushable Carved Stone Sarcophagi with Distinct Crest Seals (34x44)
    for crest in ("cross", "crown", "chalice", "stag"):
        sg = PixelCanvas(34, 44)
        sg.ellipse(17, 40, 14, 3.5, (14, 12, 18, 125))
        sg.rect(4, 10, 26, 30, "CS")
        sg.rect(5, 11, 24, 28, "C1")
        # Beveled lid plinth
        sg.rect(6, 5, 22, 29, "C2")
        sg.rect(8, 7, 18, 25, "C3")
        sg.rect_outline(6, 5, 22, 29, "C0")
        # Front vertical lip face
        sg.rect(5, 34, 24, 5, "C0")
        sg.line(5, 34, 28, 34, "C1")
        # Distinct bas-relief seal carved neatly centered on top lid!
        cx, cy = 17, 18
        if crest == "cross":
            sg.line(cx, cy - 6, cx, cy + 7, "CS2")
            sg.line(cx - 4, cy - 2, cx + 4, cy - 2, "CS2")
            sg.pset(cx, cy - 2, "Y1")
        elif crest == "crown":
            sg.rect(cx - 5, cy, 11, 4, "Y1")
            for kx in (cx - 5, cx, cx + 5):
                sg.line(kx, cy - 4, kx, cy, "Y2")
            sg.pset(cx, cy - 4, "I2")
        elif crest == "chalice":
            sg.rect(cx - 4, cy - 5, 9, 5, "Y1")
            sg.line(cx, cy, cx, cy + 4, "Y2")
            sg.line(cx - 3, cy + 5, cx + 3, cy + 5, "Y1")
            sg.rect(cx - 2, cy - 4, 5, 2, "Y3")
        elif crest == "stag":
            # Gold-antlered Stag-of-Heverlee crest matching the Crypt Tapestry!
            sg.rect(cx - 3, cy - 1, 7, 5, "Y2")
            sg.line(cx - 3, cy - 1, cx - 5, cy - 6, "Y3")
            sg.line(cx + 3, cy - 1, cx + 5, cy - 6, "Y3")
            sg.pset(cx - 2, cy - 4, "Y3")
            sg.pset(cx + 2, cy - 4, "Y3")
            sg.line(cx, cy + 4, cx, cy + 6, "Y1")
        sg.add_outline("K", selective_hue=True)
        sg.save_png(os.path.join(sprites_dir, f"prop_sarcophagus_{crest}.png"))

    # 8. Woven Abbey Crypt Tapestry showing Stag Emblem + East Pair Clue (48x40)
    tp = PixelCanvas(48, 40)
    tp.rect(3, 2, 42, 3, "Y1")  # brass hanging rod
    tp.line(4, 2, 43, 2, "Y3")
    tp.rect(5, 5, 38, 33, "I0")
    tp.rect(7, 7, 34, 29, "I1")
    tp.rect_outline(8, 8, 32, 27, "Y2")
    # Night-blue sky panel + golden horned stag woven in center + twin torches flanking
    tp.rect(11, 10, 26, 20, "U0")
    # Twin golden tapers at left & right of stag
    for tx in (14, 32):
        tp.rect(tx, 19, 2, 8, "L2")
        tp.rect(tx, 16, 2, 3, "Y3")
    # Golden stag motif in center facing east (right)
    tp.rect(20, 19, 8, 5, "Y2")
    tp.line(26, 19, 27, 15, "Y3")
    tp.line(25, 14, 29, 12, "Y3")
    tp.line(21, 24, 21, 28, "Y1")
    tp.line(26, 24, 26, 28, "Y1")
    # Downward stepped arrow woven at hem
    tp.line(21, 31, 26, 31, "Y2")
    tp.pset(23, 33, "Y3")
    tp.pset(24, 33, "Y3")
    tp.add_outline("K", selective_hue=True)
    tp.save_png(os.path.join(sprites_dir, "prop_crypt_tapestry.png"))

    # 9. Hidden Library Tall Oak Bookshelf (48x44) & Dated Reading Lectern (28x30)
    sh = PixelCanvas(48, 44)
    sh.ellipse(24, 41, 22, 2.5, (14, 12, 18, 110))
    sh.rect(3, 3, 42, 38, "T0")
    sh.rect(5, 5, 38, 34, "T2")
    sh.line(3, 3, 44, 3, "T4")
    # Crown brass folio plaque strip
    sh.rect(15, 2, 18, 5, "Y1")
    sh.rect(16, 3, 16, 3, "Y2")
    # Three crowded shelves of colored medieval codices
    cols = ("I1", "U1", "E1", "T3", "I2", "R2", "U2")
    for s_y in (9, 19, 29):
        sh.rect(6, s_y + 7, 36, 2, "T3")
        bx = 7
        bi = s_y
        while bx < 39:
            bw = 3 if (bi % 3) != 0 else 4
            bh = 6 + (bi % 2)
            sh.rect(bx, s_y + (7 - bh), bw, bh, cols[bi % len(cols)])
            sh.pset(bx + 1, s_y + 2, "Y2")
            bx += bw + 1
            bi += 1
    sh.add_outline("K", selective_hue=True)
    sh.save_png(os.path.join(sprites_dir, "prop_library_shelf.png"))

    lc = PixelCanvas(28, 30)
    lc.ellipse(14, 26, 10, 2.5, (14, 12, 18, 105))
    lc.rect(10, 14, 8, 12, "T1")
    lc.rect(4, 6, 20, 10, "T2")
    lc.line(4, 6, 23, 6, "T4")
    lc.rect(7, 7, 14, 7, "L2")
    lc.line(14, 7, 14, 13, "T1")
    lc.line(9, 9, 12, 9, "C0")
    lc.line(16, 10, 19, 10, "I1")
    lc.add_outline("K", selective_hue=True)
    lc.save_png(os.path.join(sprites_dir, "prop_date_lectern.png"))

    # 10. Crypt Trap Floor Spikes (down armed / up triggered: 28x24) & Wall Dart Slit (22x22)
    for armed_up, fname in ((False, "prop_floor_spikes_down.png"), (True, "prop_floor_spikes_up.png")):
        sp = PixelCanvas(28, 24)
        sp.rect(2, 2, 24, 20, "C0")
        sp.rect(3, 3, 22, 18, "CS")
        for gx in (7, 14, 21):
            for gy in (7, 15):
                sp.circle(gx, gy, 2.0, "K")
                if armed_up:
                    sp.line(gx, gy - 6, gx, gy, "C3")
                    sp.pset(gx, gy - 6, "L2")
                    sp.pset(gx - 1, gy - 3, "I2")
        sp.add_outline("K", selective_hue=True)
        sp.save_png(os.path.join(sprites_dir, fname))

    dt = PixelCanvas(22, 22)
    dt.rect(2, 2, 18, 18, "C1")
    dt.rect(4, 4, 14, 14, "C2")
    dt.rect(8, 8, 6, 6, "K")
    dt.line(6, 6, 15, 6, "C3")
    dt.add_outline("K", selective_hue=True)
    dt.save_png(os.path.join(sprites_dir, "prop_dart_trap.png"))


def make_louvain_dungeon_assets(sprites_dir: str) -> None:
    _make_dungeon_tiles(sprites_dir)
    _make_cathedral_and_crypt_props(sprites_dir)
