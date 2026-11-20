"""
Old Heverlee Woods, First Golden Dragon Shrine, and Anna Chapter 1 Blood-Barge Convoy Sprites
for Wings of the Brotherhood (Book II Act I Part 2).

Palette-locked to pixel_art_lib.PAL for crisp nearest-neighbor rendering:
  - prop_shrine_entrance.png      (64x56) Moss-grown sandstone stairway arch descending underground
  - prop_parents_ambush_bow.png   (36x28) Snapped hunter yew longbow & bolt-scarred stump relic
  - prop_devildragon_relief.png   (64x48) Carved obsidian Devildragon blood-ritual bas-relief
  - prop_shrine_pedestal.png      (36x40) Golden Dragon sun-serpent dais plinth
  - prop_shrine_key_relic.png     (20x20) Floating Old Heverlee Bronze & Gold Shrine Key
  - icon_heverlee_key.png         (16x16) Inventory badge for Old Heverlee Shrine Key
  - prop_shrine_serpent_vent.png  (28x24) Narrow gilded serpent crawlway vent
  - prop_weight_plate_up/down.png (28x24) Sunken bronze counterweight floor trigger plate
  - prop_shrine_boulder.png       (32x32) Pushable mossy engraved sandstone keystone block
  - prop_shrine_sconce_off/on.png (24x34) Serpent gold-trimmed Ember brazier pedestal
  - prop_shrine_door_shut/open.png(52x44) Carved golden monolith vault gate
  - prop_ward_bell_barge.png      (68x52) Armored Church river blood-barge with Acoustic Ward-Bell
  - prop_river_chain_boom.png     (56x20) Iron chain-boom barrier & timber barge mooring dolphin
"""

import os
from pixel_art_lib import PAL, PixelCanvas


def _draw_gold_stone_block(c: PixelCanvas, x: int, y: int, w: int, h: int, dark: bool = False) -> None:
    base = "C1" if dark else "H1"
    hi = "C2" if dark else "H2"
    sh = "C0" if dark else "H0"
    c.rect(x, y, w, h, base)
    c.line(x, y, x + w - 1, y, hi)
    c.line(x, y, x, y + h - 1, hi)
    c.line(x, y + h - 1, x + w - 1, y + h - 1, sh)
    c.line(x + w - 1, y, x + w - 1, y + h - 1, sh)


def make_old_heverlee_assets(sprites_dir: str) -> None:
    # 1. Sunken Shrine Stairway Entrance (`prop_shrine_entrance.png` 64x56)
    en = PixelCanvas(64, 56)
    en.ellipse(32, 51, 29, 4.0, (14, 15, 22, 120))
    _draw_gold_stone_block(en, 6, 10, 52, 42, dark=True)
    # Recessed weathered limestone arch + mossy keystone trim + dark stair descent
    _draw_gold_stone_block(en, 10, 6, 44, 10, dark=False)
    en.rect(16, 16, 32, 36, "N")
    for sy in range(20, 50, 6):
        w_step = 30 - (sy - 20) // 4
        x_step = 32 - w_step // 2
        en.rect(x_step, sy, w_step, 4, "C1")
        en.line(x_step, sy, x_step + w_step - 1, sy, "C3")
    # Carved Golden Serpent Eye insignia centered in arch lintel
    en.ellipse(32, 11, 5, 3, "Y1")
    en.ellipse(32, 11, 3, 2, "Y2")
    en.pset(32, 11, "Y3")
    # Moss creeping over stone corners
    for mx, my in [(8, 12), (10, 18), (52, 12), (49, 26), (11, 44), (50, 44)]:
        en.rect(mx, my, 4, 4, "G1")
        en.pset(mx + 1, my, "G2")
    en.add_outline("K", selective_hue=True)
    en.save_png(os.path.join(sprites_dir, "prop_shrine_entrance.png"))

    # 2. Parents' 9-Year-Old Ambush Forensics (`prop_parents_ambush_bow.png` 36x28)
    ab = PixelCanvas(36, 28)
    ab.ellipse(18, 24, 15, 3.5, (14, 15, 22, 110))
    # Mossy scarred oak stump with two black-fletched Church crossbow bolts buried deep!
    ab.rect(10, 12, 14, 12, "T1")
    ab.ellipse(17, 12, 7, 3, "T3")
    ab.ellipse(17, 12, 5, 2, "T2")
    ab.rect(11, 21, 5, 3, "G1")
    ab.rect(20, 20, 4, 4, "G1")
    # Snapped curved hunter yew longbow & torn strap across moss
    ab.line(4, 22, 11, 16, "T3", 2)
    ab.line(21, 18, 30, 22, "T3", 2)
    ab.line(5, 21, 10, 17, "H2")
    # Two Inquisitor bolts with crimson fletching stuck into the stump
    ab.line(14, 4, 16, 12, "C3")
    ab.rect(13, 3, 2, 3, "I2")
    ab.line(21, 5, 19, 12, "C3")
    ab.rect(21, 4, 2, 3, "I2")
    ab.add_outline("K", selective_hue=True)
    ab.save_png(os.path.join(sprites_dir, "prop_parents_ambush_bow.png"))

    # 3. Devildragon Blood-Harvest Ritual Bas-Relief (`prop_devildragon_relief.png` 64x48)
    dr = PixelCanvas(64, 48)
    _draw_gold_stone_block(dr, 2, 2, 60, 44, dark=True)
    dr.rect(6, 6, 52, 36, "O1")
    dr.rect_outline(6, 6, 52, 36, "Y0")
    # Left & Right engraved chained dragon silhouettes shedding crimson drops
    for sx in (11, 45):
        dr.rect(sx, 14, 8, 12, "CS2")
        dr.line(sx - 2, 16, sx + 9, 16, "C3")
        dr.pset(sx + 4, 28, "BLD2")
        dr.pset(sx + 4, 31, "BLD")
    # Center Horned Devildragon shadow rising above a crimson blood cauldron
    dr.ellipse(32, 33, 8, 5, "C2")
    dr.ellipse(32, 31, 6, 3, "BLD2")
    dr.rect(28, 17, 8, 11, "O0")
    dr.line(24, 12, 29, 18, "C3", 2)
    dr.line(40, 12, 35, 18, "C3", 2)
    dr.line(20, 21, 28, 22, "O2")
    dr.line(44, 21, 36, 22, "O2")
    dr.pset(30, 19, "BLD2")
    dr.pset(34, 19, "BLD2")
    dr.add_outline("K", selective_hue=True)
    dr.save_png(os.path.join(sprites_dir, "prop_devildragon_relief.png"))

    # 4. Stepped Golden Pedestal + Relic Key (`prop_shrine_pedestal.png`, `prop_shrine_key_relic.png`, `icon_heverlee_key.png`)
    pd = PixelCanvas(36, 40)
    pd.ellipse(18, 36, 15, 3.5, (14, 15, 22, 120))
    _draw_gold_stone_block(pd, 4, 26, 28, 10, dark=True)
    _draw_gold_stone_block(pd, 7, 15, 22, 12, dark=False)
    pd.rect(6, 12, 24, 4, "L1")
    pd.rect(11, 18, 14, 6, "Y0")
    pd.rect(13, 19, 10, 4, "Y2")
    pd.add_outline("K", selective_hue=True)
    pd.save_png(os.path.join(sprites_dir, "prop_shrine_pedestal.png"))

    rk = PixelCanvas(20, 20)
    rk.circle(10, 6, 4, "Y1")
    rk.circle(10, 6, 2, "O1")
    rk.pset(10, 4, "Y3")
    rk.rect(9, 10, 2, 8, "Y2")
    rk.rect(11, 14, 4, 2, "Y1")
    rk.rect(11, 17, 3, 1, "Y0")
    rk.add_outline("K", selective_hue=True)
    rk.save_png(os.path.join(sprites_dir, "prop_shrine_key_relic.png"))

    ik = PixelCanvas(16, 16)
    ik.circle(8, 5, 3, "Y1")
    ik.circle(8, 5, 1, "O1")
    ik.rect(7, 8, 2, 6, "Y2")
    ik.rect(9, 11, 3, 2, "Y1")
    ik.add_outline("K", selective_hue=True)
    ik.save_png(os.path.join(sprites_dir, "icon_heverlee_key.png"))

    # 5. Gilded Serpent Vent (`prop_shrine_serpent_vent.png` 28x24) & Weight Plates (`prop_weight_plate_up/down.png`)
    sv = PixelCanvas(28, 24)
    _draw_gold_stone_block(sv, 2, 2, 24, 20, dark=False)
    sv.rect(6, 5, 16, 14, "N")
    for vx in (9, 13, 17):
        sv.line(vx, 5, vx, 18, "Y1")
    sv.line(6, 11, 21, 11, "Y0")
    sv.add_outline("K", selective_hue=True)
    sv.save_png(os.path.join(sprites_dir, "prop_shrine_serpent_vent.png"))

    for down in (False, True):
        wp = PixelCanvas(28, 24)
        _draw_gold_stone_block(wp, 3, 3, 22, 18, dark=True)
        py = 6 if down else 4
        col_fill = "Y2" if down else "Y0"
        col_top = "Y3" if down else "Y1"
        wp.rect(6, py, 16, 12, col_fill)
        wp.line(6, py, 21, py, col_top)
        wp.circle(14, py + 6, 3, "O1" if down else "Y2")
        wp.add_outline("K", selective_hue=True)
        wp.save_png(os.path.join(sprites_dir, "prop_weight_plate_%s.png" % ("down" if down else "up")))

    # 6. Pushable Keystone Cube (`prop_shrine_boulder.png` 32x32)
    sb = PixelCanvas(32, 32)
    sb.ellipse(16, 29, 13, 3.0, (14, 15, 22, 110))
    _draw_gold_stone_block(sb, 4, 4, 24, 24, dark=False)
    sb.rect(8, 8, 16, 16, "C2")
    sb.ellipse(16, 16, 5, 5, "Y1")
    sb.ellipse(16, 16, 2, 2, "O1")
    sb.rect(5, 22, 4, 4, "G1")
    sb.add_outline("K", selective_hue=True)
    sb.save_png(os.path.join(sprites_dir, "prop_shrine_boulder.png"))

    # 7. Golden Shrine Ember Sconce (`prop_shrine_sconce_off/on.png` 24x34)
    for lit in (False, True):
        sc = PixelCanvas(24, 34)
        sc.ellipse(12, 30, 9, 2.5, (14, 15, 22, 110))
        _draw_gold_stone_block(sc, 6, 16, 12, 14, dark=True)
        sc.rect(4, 12, 16, 5, "Y0")
        sc.rect(5, 13, 14, 3, "Y1")
        if lit:
            sc.ellipse(12, 9, 5, 5, "Y1")
            sc.ellipse(12, 8, 3, 4, "Y2")
            sc.pset(12, 6, "Y3")
        else:
            sc.rect(8, 11, 8, 2, "C0")
        sc.add_outline("K", selective_hue=True)
        sc.save_png(os.path.join(sprites_dir, "prop_shrine_sconce_%s.png" % ("on" if lit else "off")))

    # 8. Vault Gate Doors (`prop_shrine_door_shut/open.png` 52x44)
    for opened in (False, True):
        sd = PixelCanvas(52, 44)
        _draw_gold_stone_block(sd, 2, 2, 48, 40, dark=True)
        if not opened:
            _draw_gold_stone_block(sd, 8, 8, 17, 34, dark=False)
            _draw_gold_stone_block(sd, 27, 8, 17, 34, dark=False)
            sd.line(25, 8, 25, 41, "K", 2)
            sd.ellipse(25, 24, 6, 6, "Y1")
            sd.ellipse(25, 24, 3, 3, "Y3")
        else:
            sd.rect(8, 8, 36, 34, "N")
            sd.rect(8, 36, 36, 6, "C1")
        sd.add_outline("K", selective_hue=True)
        sd.save_png(os.path.join(sprites_dir, "prop_shrine_door_%s.png" % ("open" if opened else "shut")))

    # 9. Anna Chapter 1 Church River Blood-Barge (`prop_ward_bell_barge.png` 68x52) & Chain Boom (`prop_river_chain_boom.png` 56x20)
    bg = PixelCanvas(68, 52)
    bg.ellipse(34, 44, 30, 6.0, (14, 24, 36, 120))
    # Heavy oak armored river barge hull + Church crimson pennant band
    bg.rect(6, 22, 56, 20, "T0")
    bg.rect(8, 24, 52, 16, "T2")
    bg.line(8, 24, 59, 24, "T4")
    bg.rect(6, 34, 56, 4, "I1")
    # Caged captive-dragon hold + blood-harvest cask rows on fore-deck
    bg.rect(12, 16, 18, 14, "C1")
    for cx in (14, 18, 22, 26):
        bg.line(cx, 16, cx, 29, "C3")
    bg.rect(34, 20, 8, 8, "R1")
    bg.rect(35, 22, 6, 3, "BLD2")
    # Brass Acoustic Ward-Bell Belfry tower astern
    bg.rect(45, 8, 14, 22, "T1")
    bg.line(47, 8, 47, 29, "T3")
    bg.ellipse(52, 14, 4, 5, "Y1")
    bg.ellipse(52, 13, 3, 3, "Y2")
    bg.pset(52, 18, "Y0")
    bg.add_outline("K", selective_hue=True)
    bg.save_png(os.path.join(sprites_dir, "prop_ward_bell_barge.png"))

    cb = PixelCanvas(56, 20)
    cb.rect(2, 4, 8, 12, "T1")
    cb.rect(46, 4, 8, 12, "T1")
    for lx in range(10, 46, 5):
        cb.ellipse(lx + 2, 10, 3, 2, "C2")
        cb.pset(lx + 2, 10, "C4")
    cb.add_outline("K", selective_hue=True)
    cb.save_png(os.path.join(sprites_dir, "prop_river_chain_boom.png"))
