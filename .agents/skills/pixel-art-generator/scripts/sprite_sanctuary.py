"""
Crafted medieval pixel-art props, outpost structures, tents, stalls,
livestock animations, and Brotherhood chore icons for Chapter 2 Sanctuary.
"""

import math
import os
from pixel_art_lib import PAL, PixelCanvas
from sprite_world_buildings import _draw_brick_wall, _draw_shingles


def _save(canvas: PixelCanvas, sprites_dir: str, fname: str, outline_col: str = "K") -> None:
    if outline_col:
        canvas.add_outline(outline_col, selective_hue=True)
    canvas.save_png(os.path.join(sprites_dir, fname))


def _make_chore_props_and_icons(sprites_dir: str) -> None:
    # 1. Saddler Hendrick's Leather Curing Rack (28x24)
    c = PixelCanvas(28, 24)
    c.ellipse(14, 21, 11.5, 2.2, (14, 16, 18, 95))
    c.rect(4, 5, 3, 16, "T0")
    c.line(5, 5, 5, 20, "T2")
    c.rect(21, 5, 3, 16, "T0")
    c.line(22, 5, 22, 20, "T2")
    c.rect(2, 4, 24, 3, "T1")
    c.line(2, 4, 25, 4, "T3")
    # Draped wyrm-hide leather panel + emerald harness strap + hanging brass rings
    c.rect(7, 7, 7, 11, "T2")
    c.rect(8, 8, 5, 8, "T3")
    c.line(8, 17, 13, 17, "T1")
    c.rect(15, 7, 5, 9, "E1")
    c.line(16, 8, 16, 14, "E2")
    c.pset(18, 9, "Y2")
    c.rect(19, 10, 2, 3, "Y1")
    c.pset(15, 5, "Y2")
    c.pset(20, 5, "Y2")
    _save(c, sprites_dir, "prop_leather_rack.png")

    # 2. Carried Strapped Wyrm-Hide Leather Bale (16x16)
    c = PixelCanvas(16, 16)
    c.ellipse(8, 8, 5.8, 4.4, "T1")
    c.ellipse(7.5, 7.5, 4.8, 3.6, "T2")
    c.ellipse(7.0, 6.5, 3.5, 2.0, "T3")
    # Spiral leather end-grain + twin hemp straps & brass D-buckle
    c.ellipse(12.2, 8, 1.6, 3.2, "T0")
    c.pset(12, 8, "T3")
    c.rect(5, 4, 2, 8, "H1")
    c.line(5, 4, 5, 11, "H2")
    c.rect(9, 4, 2, 8, "H1")
    c.pset(6, 7, "Y2")
    c.pset(10, 7, "Y2")
    _save(c, sprites_dir, "prop_leather_bale.png")

    # 3. Sister Maren's Cliffsage Apothecary Cauldron (24x24)
    c = PixelCanvas(24, 24)
    c.ellipse(12, 20, 8.5, 2.5, (14, 16, 18, 105))
    # Glowing firelogs & tripod feet
    c.rect(6, 18, 12, 3, "T0")
    c.rect(8, 17, 8, 3, "R2")
    c.rect(10, 17, 4, 2, "Y2")
    c.line(6, 15, 5, 20, "C2")
    c.line(18, 15, 19, 20, "C2")
    # Rounded iron kettle + brass handles
    c.ellipse(12, 13, 7.2, 5.5, "C0")
    c.ellipse(11.2, 12.2, 5.8, 4.2, "C1")
    c.line(7, 11, 8, 15, "C3")
    c.rect(4, 10, 2, 3, "Y1")
    c.rect(18, 10, 2, 3, "Y1")
    # Simmering bright emerald sage poultice & steam wisps
    c.ellipse(12, 8.2, 6.2, 2.2, "C2")
    c.ellipse(12, 8.2, 4.8, 1.6, "E2")
    c.pset(10, 8, "E3")
    c.pset(13, 8, "Y3")
    c.pset(11, 5, "L0")
    c.pset(14, 3, "E3")
    c.pset(9, 4, "E3")
    _save(c, sprites_dir, "prop_herb_cauldron.png")

    # 4. Mossy Cliff Spring Stone Basin (28x24)
    c = PixelCanvas(28, 24)
    c.ellipse(14, 14, 12.2, 7.8, "C0")
    c.ellipse(14, 13, 11.0, 6.8, "C2")
    c.ellipse(14, 13, 8.6, 4.8, "W1")
    c.ellipse(14, 13, 7.0, 3.8, "W3")
    # Rippling crystal highlights + tumbling waterfall lip
    c.rect(9, 4, 10, 6, "C1")
    c.rect(10, 3, 8, 4, "C3")
    c.rect(12, 6, 4, 7, "W4")
    c.line(13, 6, 13, 13, "W5")
    c.ellipse(14, 13, 2.8, 1.4, "W5")
    # Moss patches & wet fern tufts
    for mx, my in ((4, 11), (6, 16), (22, 12), (20, 17)):
        c.ellipse(mx, my, 2.2, 1.4, "G1")
        c.pset(mx, my - 1, "G3")
    _save(c, sprites_dir, "prop_spring_well.png")

    # 5. Iron-Hooped Cliffwater Oak Bucket (16x16)
    c = PixelCanvas(16, 16)
    # Bail handle
    c.line(5, 6, 6, 3, "C2")
    c.line(6, 3, 10, 3, "C3")
    c.line(10, 3, 11, 6, "C2")
    # Coopered stave body
    c.rect(4, 6, 8, 8, "T1")
    c.rect(5, 6, 6, 8, "T2")
    c.line(7, 8, 7, 13, "T3")
    c.line(4, 8, 11, 8, "C2")
    c.line(4, 12, 11, 12, "C1")
    # Clear mountain spring water surface
    c.ellipse(8, 6.2, 3.8, 1.5, "W3")
    c.line(6, 6, 9, 6, "W5")
    _save(c, sprites_dir, "prop_water_bucket.png")

    # 6. Herbs Drying Camp Rack (24x20)
    c = PixelCanvas(24, 20)
    c.ellipse(12, 17, 9.5, 2.0, (14, 16, 18, 90))
    c.line(3, 16, 5, 4, "T0")
    c.line(4, 16, 6, 4, "T2")
    c.line(20, 16, 18, 4, "T0")
    c.line(19, 16, 17, 4, "T2")
    c.rect(2, 3, 20, 2, "T1")
    c.line(2, 3, 21, 3, "T3")
    # Hung sage & camomile herb bundles with cream twine ties
    for bx, col_d, col_l in ((7, "G1", "G3"), (12, "E1", "E3"), (17, "H1", "Y2")):
        c.line(bx, 5, bx, 13, col_d)
        c.line(bx - 1, 7, bx + 1, 12, col_d)
        c.pset(bx, 8, col_l)
        c.pset(bx - 1, 11, col_l)
        c.pset(bx + 1, 10, col_l)
        c.line(bx - 1, 6, bx + 1, 6, "L0")
    _save(c, sprites_dir, "prop_drying_herbs.png")

    # 7. Brotherhood Coastal Flight Charts & Compass Table (36x24)
    c = PixelCanvas(36, 24)
    c.ellipse(18, 21, 15.0, 2.2, (14, 16, 18, 100))
    c.rect(5, 13, 3, 8, "T0")
    c.rect(28, 13, 3, 8, "T0")
    c.rect(3, 4, 30, 11, "T1")
    c.rect(4, 5, 28, 9, "T2")
    c.line(4, 5, 31, 5, "T3")
    # Unrolled vellum map with crimson course pin + brass dividers/compass
    c.rect(7, 6, 16, 8, "L1")
    c.rect(8, 7, 14, 6, "L0")
    c.rect(7, 6, 2, 8, "H2")
    c.line(10, 11, 18, 8, "U1")
    c.line(13, 10, 19, 9, "I1")
    c.pset(19, 9, "I2")
    c.circle(27, 9, 2.5, "Y1")
    c.pset(27, 9, "Y3")
    c.pset(28, 8, "I1")
    _save(c, sprites_dir, "prop_map_table.png")

    # 8. Brotherhood Flight-Jerkin Bag Icon (16x16)
    c = PixelCanvas(16, 16)
    c.rect(3, 4, 10, 9, "T1")
    c.rect(4, 5, 8, 7, "T2")
    c.rect(3, 4, 3, 3, "E1")
    c.rect(10, 4, 3, 3, "E1")
    c.line(4, 4, 5, 4, "E2")
    c.line(10, 4, 11, 4, "E2")
    # Oiled collar + brass sternum D-ring
    c.rect(6, 4, 4, 2, "T0")
    c.line(7, 6, 7, 11, "T0")
    c.rect(6, 7, 4, 3, "Y1")
    c.pset(7, 8, "Y3")
    _save(c, sprites_dir, "icon_jerkin.png")

    # 9. Cliffsage Wing-Poultice Stoneware Jar Icon (16x16)
    c = PixelCanvas(16, 16)
    c.rect(6, 2, 4, 3, "T2")
    c.line(6, 2, 9, 2, "T3")
    c.rect(5, 5, 6, 2, "L1")
    c.rect(4, 6, 8, 8, "C2")
    c.rect(5, 7, 6, 6, "C3")
    # Vibrant glowing green herb salve label
    c.rect(5, 8, 6, 4, "E1")
    c.rect(6, 9, 4, 2, "E3")
    c.pset(7, 9, "Y3")
    _save(c, sprites_dir, "icon_poultice.png")

    # 10. Ice-Packed Herring Camp Bucket (22x20)
    c = PixelCanvas(22, 20)
    c.ellipse(11, 17, 7.5, 2.0, (14, 16, 18, 95))
    c.rect(5, 8, 12, 9, "T1")
    c.rect(6, 9, 10, 7, "T2")
    c.line(5, 10, 16, 10, "C2")
    c.line(5, 14, 16, 14, "C1")
    # Sparkling crushed ice rim & 2 plump silver herring dipping out at natural angles
    c.ellipse(11, 8, 5.5, 2.0, "W4")
    c.pset(7, 8, "W5")
    c.pset(13, 8, "W5")
    # Left herring tail tilted left
    c.line(9, 8, 6, 4, "SG1")
    c.line(10, 8, 7, 4, "SG3")
    c.pset(5, 3, "SG2")
    c.pset(7, 2, "SG2")
    # Right herring tail tilted right
    c.line(13, 8, 16, 5, "SG1")
    c.line(14, 8, 16, 4, "SG3")
    c.pset(17, 4, "SG2")
    c.pset(16, 6, "SG2")
    _save(c, sprites_dir, "prop_herring_bucket.png")

    # 11. Silver Herring Toss Fish (16x12)
    c = PixelCanvas(16, 12)
    c.ellipse(7.5, 6, 5.0, 2.4, "SG1")
    c.ellipse(7.5, 5.5, 4.2, 1.6, "SG2")
    c.line(4, 5, 10, 5, "SG3")
    c.line(5, 7, 9, 7, "L0")
    # Tail fin + gill highlight
    c.line(12, 6, 14, 3, "SG1")
    c.line(12, 6, 14, 8, "SG1")
    c.pset(4, 5, "K")
    c.pset(3, 5, "EW")
    _save(c, sprites_dir, "prop_herring_fish.png")

    # 12. Topman's Practice Knot Drill Board (26x26)
    c = PixelCanvas(26, 26)
    c.ellipse(13, 23, 8.0, 2.0, (14, 16, 18, 95))
    c.rect(11, 14, 4, 10, "T0")
    c.line(12, 14, 12, 23, "T2")
    c.rect(3, 3, 20, 12, "T1")
    c.rect(4, 4, 18, 10, "T2")
    c.line(4, 4, 21, 4, "T3")
    # Emerald knot cord strung between brass belaying pegs + brass timer plumb
    for px, py in ((7, 7), (13, 6), (18, 7), (9, 11), (16, 11)):
        c.pset(px, py, "Y2")
    c.line(7, 7, 13, 6, "E2")
    c.line(13, 6, 18, 7, "E2")
    c.line(7, 7, 9, 11, "E3")
    c.line(18, 7, 16, 11, "E3")
    c.circle(13, 9, 1.5, "H2")
    # Hanging brass hourglass/timer off right side
    c.line(20, 9, 22, 12, "Y0")
    c.rect(20, 12, 3, 6, "Y1")
    c.pset(21, 13, "L0")
    c.pset(21, 16, "H2")
    _save(c, sprites_dir, "prop_knot_drill_board.png")


def _make_village_buildings_and_tents(sprites_dir: str) -> None:
    # 13. Covert Crew Bunkhouse Lodge (96x80)
    b = PixelCanvas(96, 80)
    # Stone plinth + cream-plaster half-timber facade
    b.rect(6, 58, 84, 16, "C0")
    _draw_brick_wall(b, 8, 60, 80, 14, "C0", "C1", "C2")
    b.rect(7, 30, 82, 30, "L1")
    b.rect(8, 31, 80, 27, "L0")
    # Heavy oak framing + diagonal cross-braces
    for tx in (7, 29, 64, 86):
        b.rect(tx, 30, 3, 30, "T0")
        b.line(tx + 1, 31, tx + 1, 58, "T2")
    b.rect(7, 42, 82, 3, "T0")
    b.line(10, 33, 28, 41, "T1")
    b.line(67, 41, 85, 33, "T1")
    # Pitched mossy slate shingle roof + chimney + twin dormers
    _draw_brick_wall(b, 71, 2, 10, 14, "C0", "C1", "C2")
    b.rect(70, 2, 12, 2, "C3")
    _draw_shingles(b, 4, 11, 88, 22, "E0", "CS", "C1")
    b.line(8, 11, 87, 11, "C2")
    b.line(4, 32, 91, 32, "T0")
    for dx in (20, 62):
        b.rect(dx, 14, 12, 12, "T0")
        b.rect(dx + 2, 16, 8, 8, "Y1")
        b.rect(dx + 3, 17, 6, 5, "Y2")
        b.line(dx + 6, 16, dx + 6, 23, "T0")
    # Arched studded oak doorway + stone step + stacked logs + warm windows
    b.rect(40, 72, 16, 4, "C2")
    b.rect(41, 47, 14, 25, "T0")
    b.rect(43, 49, 10, 22, "T2")
    b.line(48, 49, 48, 70, "T0")
    b.pset(51, 61, "Y2")
    for wx in (14, 70):
        b.rect(wx - 2, 47, 2, 11, "E1")
        b.rect(wx + 12, 47, 2, 11, "E1")
        b.rect(wx, 47, 12, 11, "T0")
        b.rect(wx + 2, 49, 8, 7, "Y1")
        b.rect(wx + 3, 50, 6, 4, "Y3")
    # Lantern & stacked split firewood
    b.rect(57, 49, 4, 5, "S")
    b.rect(58, 50, 2, 3, "Y3")
    for lx in (10, 14, 18):
        b.circle(lx, 71, 2, "T2")
        b.pset(lx, 70, "H1")
    _save(b, sprites_dir, "bldg_covert_lodge.png")

    # 14. Captain's & Navigator's Fieldstone Cottage (88x72)
    b = PixelCanvas(88, 72)
    _draw_brick_wall(b, 8, 28, 72, 38, "C0", "C1", "C2")
    for qy in range(30, 65, 6):
        b.rect(8, qy, 4, 4, "C3")
        b.rect(76, qy, 4, 4, "C2")
    # Smoking chimney + terracotta roof
    _draw_brick_wall(b, 60, 4, 11, 14, "C0", "C1", "C2")
    b.rect(59, 3, 13, 2, "C3")
    b.circle(65, 1, 2, (210, 214, 218, 125))
    _draw_shingles(b, 4, 11, 80, 20, "R0", "R1", "R2")
    b.line(8, 11, 79, 11, "R3")
    b.line(4, 30, 83, 30, "T0")
    # Studded timber door & emerald chart shutters
    b.rect(36, 64, 16, 4, "C2")
    b.rect(37, 42, 14, 23, "T0")
    b.rect(39, 44, 10, 20, "T2")
    b.line(44, 44, 44, 63, "T0")
    b.pset(47, 54, "Y2")
    for wx in (15, 59):
        b.rect(wx - 2, 39, 2, 11, "E1")
        b.rect(wx + 12, 39, 2, 11, "E1")
        b.rect(wx, 39, 12, 11, "T0")
        b.rect(wx + 2, 41, 8, 7, "Y2")
        b.rect(wx + 3, 42, 5, 4, "Y3")
        b.rect(wx, 50, 12, 3, "T1")
    # Creeping mountain ivy along corner masonry
    for vx, vy in ((9, 54), (12, 59), (72, 55), (75, 59)):
        b.ellipse(vx, vy, 3.2, 3.5, "G1")
        b.pset(vx - 1, vy - 1, "G2")
    _save(b, sprites_dir, "bldg_covert_cottage.png")

    # 15. Stockman's Broad Feed & Ration Barn (88x72)
    b = PixelCanvas(88, 72)
    # Planks vertically textured
    b.rect(7, 29, 74, 38, "T1")
    for px in range(9, 80, 4):
        b.rect(px, 30, 3, 36, "T2")
        b.line(px + 3, 30, px + 3, 66, "T0")
    b.rect(7, 29, 74, 3, "T0")
    # Slate barn roof + gambrel hayloft window & hoist beam
    _draw_shingles(b, 4, 10, 80, 22, "S", "CS", "C1")
    b.line(8, 10, 79, 10, "C2")
    b.rect(36, 13, 16, 13, "T0")
    b.rect(38, 15, 12, 9, "H2")
    b.rect(40, 17, 8, 7, "H1")
    b.rect(42, 7, 4, 7, "T2")
    # Wide double barn carriage doors + cross-bracing & straw wisps
    b.rect(28, 41, 32, 26, "T0")
    b.rect(30, 43, 13, 24, "T2")
    b.rect(45, 43, 13, 24, "T2")
    b.line(30, 43, 42, 66, "T1")
    b.line(42, 43, 30, 66, "T1")
    b.line(45, 43, 57, 66, "T1")
    b.line(57, 43, 45, 66, "T1")
    for sx in range(11, 24, 3):
        b.pset(sx, 65, "H2")
        b.pset(sx + 52, 65, "H2")
    _save(b, sprites_dir, "bldg_feed_barn.png")

    # 16. Brotherhood Emerald Pavilion Tent (52x44)
    t = PixelCanvas(52, 44)
    t.ellipse(26, 39, 22.5, 3.5, (14, 16, 18, 95))
    # Back pitch & sloped emerald canvas wings
    for y in range(10, 38):
        frac = (y - 10) / 27.0
        hw = int(9 + frac * 14)
        for x in range(26 - hw, 26 + hw + 1):
            col = "E1" if (x - 26) < hw // 2 else "E0"
            if abs(x - 26) > hw - 3:
                col = "E2"
            if y == 10:
                col = "E3"
            t.pset(x, y, col)
    # Timber ridge poles + finials + hemp guy-ropes
    t.line(8, 11, 43, 11, "T2")
    t.rect(7, 7, 2, 5, "T1")
    t.rect(43, 7, 2, 5, "T1")
    t.pset(8, 7, "Y2")
    t.pset(44, 7, "Y2")
    t.line(8, 14, 3, 37, "H1")
    t.line(43, 14, 48, 37, "H1")
    t.rect(2, 36, 2, 4, "T0")
    t.rect(48, 36, 2, 4, "T0")
    # Rolled open tent entrance & warm lantern glow inside
    t.rect(21, 21, 10, 17, "N")
    t.rect(23, 27, 6, 10, "T0")
    t.circle(26, 28, 2, "Y2")
    t.rect(18, 20, 3, 17, "E2")
    t.rect(31, 20, 3, 17, "E2")
    _save(t, sprites_dir, "prop_tent_green.png")

    # 17. Scout Hemp A-Frame Field Tent (48x40)
    t = PixelCanvas(48, 40)
    t.ellipse(24, 35, 19.5, 3.0, (14, 16, 18, 95))
    for y in range(9, 34):
        frac = (y - 9) / 24.0
        hw = int(7 + frac * 13)
        for x in range(24 - hw, 24 + hw + 1):
            col = "H1" if x < 24 else "H0"
            if y < 12 or abs(x - 24) > hw - 2:
                col = "L1"
            t.pset(x, y, col)
    t.line(23, 6, 23, 33, "T1")
    t.line(6, 15, 2, 34, "T2")
    t.line(41, 15, 45, 34, "T2")
    t.rect(19, 19, 10, 15, "T0")
    t.rect(21, 21, 6, 12, "N")
    t.rect(17, 19, 2, 15, "L0")
    t.rect(29, 19, 2, 15, "L0")
    _save(t, sprites_dir, "prop_tent_tan.png")

    # 18. Open Dragon Timber Weather Pavilion (72x48)
    p = PixelCanvas(72, 48)
    p.ellipse(36, 43, 30.0, 3.5, (14, 16, 18, 95))
    # Stone pillar pads & deep golden straw bedding
    for px in (8, 59):
        p.rect(px, 38, 6, 5, "C2")
        p.rect(px + 1, 16, 4, 24, "T1")
        p.line(px + 2, 16, px + 2, 38, "T2")
    p.ellipse(36, 36, 21.0, 6.5, "H0")
    p.ellipse(36, 35, 18.0, 5.0, "H2")
    for sx, sy in ((22, 35), (30, 37), (41, 34), (48, 36), (35, 33)):
        p.line(sx, sy, sx + 4, sy - 1, "H3")
    # Heavy oak beam eaves + moss-slate pitched roof
    p.rect(5, 15, 62, 4, "T0")
    p.line(5, 15, 66, 15, "T3")
    _draw_shingles(p, 3, 4, 66, 13, "E0", "CS", "G1")
    p.line(6, 4, 65, 4, "C2")
    _save(p, sprites_dir, "prop_dragon_pavilion.png")


def _make_stalls_props_and_livestock(sprites_dir: str) -> None:
    # 19. Victualler Food & Ale Market Stall (48x36)
    f = PixelCanvas(48, 36)
    f.ellipse(24, 33, 21.0, 2.5, (14, 16, 18, 95))
    f.rect(4, 9, 3, 23, "T0")
    f.rect(41, 9, 3, 23, "T0")
    # Oak plank counter & wheels of Flemish cheese + rye loaves + stoneware jugs
    f.rect(4, 21, 40, 11, "T1")
    f.rect(5, 22, 38, 4, "T2")
    f.line(5, 22, 42, 22, "T3")
    f.ellipse(12, 19, 4.5, 3.0, "Y1")
    f.ellipse(12, 18, 3.5, 2.0, "Y2")
    f.ellipse(23, 19, 4.5, 2.5, "T2")
    f.ellipse(23, 18, 3.2, 1.8, "Y0")
    f.rect(32, 15, 5, 7, "C3")
    f.rect(33, 14, 3, 2, "T2")
    # Crimson & linen striped awning canopy
    for y in range(4, 13):
        for x in range(2, 46):
            stripe = ((x - 2) // 6) % 2 == 0
            col = ("I1" if y < 11 else "I0") if stripe else ("L0" if y < 11 else "L2")
            if y == 4:
                col = "I2" if stripe else "L0"
            f.pset(x, y, col)
    _save(f, sprites_dir, "prop_stall_food.png")

    # 20. Chandlery & Rigging Market Stall (48x36)
    g = PixelCanvas(48, 36)
    g.ellipse(24, 33, 21.0, 2.5, (14, 16, 18, 95))
    g.rect(4, 9, 3, 23, "T0")
    g.rect(41, 9, 3, 23, "T0")
    g.rect(4, 21, 40, 11, "T1")
    g.rect(5, 22, 38, 4, "T2")
    g.ellipse(12, 19, 4.5, 2.8, "H1")
    g.ellipse(12, 18, 2.5, 1.5, "H2")
    g.rect(21, 16, 6, 6, "T0")
    g.rect(22, 17, 4, 4, "T3")
    g.rect(33, 14, 5, 7, "S")
    g.rect(34, 16, 3, 3, "Y2")
    for y in range(4, 13):
        for x in range(2, 46):
            stripe = ((x - 2) // 6) % 2 == 0
            col = ("E1" if y < 11 else "E0") if stripe else ("L1" if y < 11 else "L2")
            g.pset(x, y, col)
    _save(g, sprites_dir, "prop_stall_gear.png")

    # 21. Communal Crew Mess Table & Twin Benches (56x28)
    m = PixelCanvas(56, 28)
    # Top & bottom benches
    m.rect(5, 3, 46, 4, "T1")
    m.line(5, 3, 50, 3, "T2")
    m.rect(5, 21, 46, 4, "T1")
    m.line(5, 21, 50, 21, "T2")
    # Trestle oak table surface
    m.rect(4, 8, 48, 12, "T0")
    m.rect(5, 9, 46, 9, "T2")
    m.line(5, 9, 50, 9, "T3")
    # Trenchers, stew bowls, bread, and ale mugs
    for bx in (12, 26, 40):
        m.circle(bx, 13, 2.5, "C2")
        m.pset(bx, 13, "R2")
    m.ellipse(20, 14, 3.0, 2.0, "H1")
    m.rect(33, 11, 3, 4, "C3")
    m.pset(34, 11, "L0")
    m.rect(46, 11, 3, 4, "T3")
    _save(m, sprites_dir, "prop_mess_table.png")

    # 22. Stewing Kettle on Cast-Iron Tripod (24x24)
    st = PixelCanvas(24, 24)
    st.ellipse(12, 20, 8.0, 2.2, (14, 16, 18, 100))
    st.rect(7, 17, 10, 3, "R1")
    st.rect(9, 17, 6, 2, "Y2")
    st.line(12, 2, 4, 20, "C1")
    st.line(12, 2, 20, 20, "C1")
    st.line(12, 2, 12, 10, "C2")
    st.ellipse(12, 13, 6.2, 4.8, "C0")
    st.ellipse(11.5, 12.2, 5.0, 3.8, "S")
    st.ellipse(12, 9, 4.5, 1.5, "H1")
    st.line(14, 9, 20, 5, "T3")
    st.pset(20, 5, "T2")
    _save(st, sprites_dir, "prop_stew_pot.png")

    # 23. Dragon Meat Butcher Rack & Brine Tub (36x32)
    dr = PixelCanvas(36, 32)
    dr.ellipse(18, 29, 14.0, 2.5, (14, 16, 18, 95))
    dr.rect(4, 6, 3, 22, "T0")
    dr.rect(29, 6, 3, 22, "T0")
    dr.rect(2, 5, 32, 3, "T1")
    dr.line(2, 5, 33, 5, "T3")
    # Two hanging butcher cuts + salted brine tub
    dr.pset(12, 8, "C3")
    dr.ellipse(12, 14, 3.6, 5.2, "D1")
    dr.ellipse(12, 13, 2.2, 3.5, "R2")
    dr.rect(11, 18, 2, 3, "L0")
    dr.pset(24, 8, "C3")
    dr.ellipse(24, 13, 3.2, 4.5, "D0")
    dr.ellipse(24, 13, 2.0, 2.8, "D2")
    dr.rect(14, 23, 8, 5, "T2")
    dr.line(14, 25, 21, 25, "C1")
    _save(dr, sprites_dir, "prop_dragon_feed_rack.png")

    # 24. Iron-Banded Timber Watering Trough (32x20)
    wt = PixelCanvas(32, 20)
    wt.ellipse(16, 17, 13.5, 2.2, (14, 16, 18, 90))
    wt.rect(3, 5, 26, 11, "T0")
    wt.rect(4, 6, 24, 9, "T2")
    wt.rect(6, 5, 2, 12, "C1")
    wt.rect(24, 5, 2, 12, "C1")
    wt.rect(5, 7, 22, 6, "W2")
    wt.rect(6, 8, 20, 4, "W3")
    wt.line(8, 9, 17, 9, "W5")
    _save(wt, sprites_dir, "prop_water_trough.png")

    # 25. Bound Golden Hay Bale (24x20)
    hb = PixelCanvas(24, 20)
    hb.ellipse(12, 16, 9.5, 2.5, (14, 16, 18, 90))
    hb.rect(4, 5, 16, 11, "H0")
    hb.rect(5, 5, 14, 8, "H2")
    hb.line(6, 6, 17, 6, "H3")
    hb.rect(8, 5, 2, 11, "T1")
    hb.rect(14, 5, 2, 11, "T1")
    for sx, sy in ((4, 8), (19, 10), (7, 15)):
        hb.pset(sx, sy, "H3")
    _save(hb, sprites_dir, "prop_hay_bale.png")

    # 26. Horizontal Split-Rail Pasture Fence (32x16, seamless tileable)
    fh = PixelCanvas(32, 16)
    fh.rect(0, 6, 32, 3, "T1")
    fh.line(0, 6, 31, 6, "T3")
    fh.rect(0, 11, 32, 3, "T1")
    fh.line(0, 11, 31, 11, "T2")
    for px in (2, 25):
        fh.rect(px, 2, 5, 12, "T0")
        fh.rect(px + 1, 2, 3, 11, "T2")
        fh.line(px + 1, 2, px + 3, 2, "T3")
        fh.pset(px + 1, 13, "G1")
    _save(fh, sprites_dir, "prop_fence_h.png", outline_col="")

    # 27. Vertical Split-Rail Pasture Fence (12x32, seamless tileable)
    fv = PixelCanvas(12, 32)
    fv.rect(4, 0, 4, 32, "T0")
    fv.rect(5, 0, 2, 32, "T2")
    for py in (1, 14, 26):
        fv.rect(3, py, 6, 5, "T0")
        fv.rect(4, py + 1, 4, 3, "T3")
    _save(fv, sprites_dir, "prop_fence_v.png", outline_col="")

    # 28-30. Grazing Livestock 2-Frame Animations
    for frame in (0, 1):
        # Flemish Sheep (20x16)
        sh = PixelCanvas(20, 16)
        dy = 1 if frame == 1 else 0
        sh.rect(5, 11, 2, 3, "S")
        sh.rect(12 - frame, 11, 2, 3, "S")
        sh.ellipse(8.5, 7.5, 5.5, 4.2, "L1")
        sh.ellipse(8.0, 6.5, 4.8, 3.2, "L0")
        sh.ellipse(10.5, 8.5, 3.2, 2.2, "L2")
        sh.ellipse(14.5, 6.5 + dy * 2, 3.0, 2.4, "C0")
        sh.rect(13, 5 + dy * 2, 2, 2, "S")
        sh.pset(16, 6 + dy * 2, "EW")
        _save(sh, sprites_dir, f"animal_sheep_{frame}.png")

        # Brabant Dairy Cow (28x22)
        cw = PixelCanvas(28, 22)
        dy = 2 if frame == 1 else 0
        cw.rect(6, 15, 2, 5, "B0")
        cw.rect(10 + frame, 15, 2, 5, "B0")
        cw.rect(16, 15, 2, 5, "B0")
        cw.ellipse(12, 10.5, 7.8, 5.2, "B1")
        cw.ellipse(11, 9.5, 4.0, 3.2, "L0")
        cw.ellipse(15, 11.5, 2.5, 2.2, "L1")
        cw.line(4, 10, 2 + frame, 15, "B0")
        # Head + pale horns + rosy snout
        cw.ellipse(21, 9.5 + dy, 4.0, 3.6, "B1")
        cw.ellipse(22.5, 10.8 + dy, 2.2, 1.5, "PK")
        cw.line(18, 6 + dy, 17, 4 + dy, "H2")
        cw.line(23, 6 + dy, 24, 4 + dy, "H2")
        cw.pset(22, 8 + dy, "EW")
        _save(cw, sprites_dir, f"animal_cow_{frame}.png")

        # Covert Hog (18x14)
        pg = PixelCanvas(18, 14)
        dy = 1 if frame == 1 else 0
        pg.rect(4, 9, 2, 3, "T0")
        pg.rect(11 - frame, 9, 2, 3, "T0")
        pg.ellipse(8.0, 7.0, 5.2, 3.5, "PK")
        pg.ellipse(7.5, 6.0, 4.0, 2.2, "P3")
        pg.ellipse(13.2, 7.0 + dy, 2.6, 2.2, "PK")
        pg.rect(15, 6 + dy, 2, 2, "R3")
        pg.pset(13, 6 + dy, "K")
        pg.pset(2, 6, "PK")
        _save(pg, sprites_dir, f"animal_pig_{frame}.png")

    # 31. Butchered Mutton Quarter Carry & Rack Prop (22x18)
    mj = PixelCanvas(22, 18)
    mj.ellipse(8.5, 9.0, 6.2, 4.8, "D0")
    mj.ellipse(8.0, 8.5, 5.2, 4.0, "D1")
    mj.ellipse(7.0, 7.2, 3.2, 2.2, "R2")
    mj.pset(6, 9, "L1")
    mj.pset(9, 10, "L1")
    # Femur bone shank + butcher twine wrap
    mj.rect(13, 7, 5, 3, "L1")
    mj.line(14, 7, 17, 7, "L0")
    mj.circle(18, 8, 1.6, "L0")
    mj.line(12, 6, 12, 12, "H2")
    _save(mj, sprites_dir, "prop_mutton_joint.png")

    # 32. Compact Mutton Bag/Popup Icon (16x16)
    mi = PixelCanvas(16, 16)
    mi.ellipse(6.5, 8.5, 4.5, 3.8, "D0")
    mi.ellipse(6.0, 8.0, 3.6, 3.0, "D1")
    mi.ellipse(5.5, 7.0, 2.2, 1.5, "R2")
    mi.rect(10, 7, 4, 2, "L0")
    mi.pset(14, 7, "L1")
    mi.pset(14, 9, "L1")
    mi.line(9, 6, 9, 10, "H2")
    _save(mi, sprites_dir, "icon_mutton.png")


def _make_signal_mast_sprites(sprites_dir: str) -> None:
    """
    East Gorge Signal Pennant Mast (44x56):
      - `prop_signal_mast_loose.png`: stone cairn socket, oak spar, crosstree yardarm,
        Brotherhood plaque, waist belaying cleat, and coiled unstrung halyard + bundled banner.
      - `prop_signal_mast_0.png` & `_1.png`: tautly belted Bowline halyard with brass carabiner
        and billowing Forest-Emerald & Gold Brotherhood Gale-Pennant (2-frame wind ripple).
    """
    for mode in ("loose", "0", "1"):
        sm = PixelCanvas(44, 56)
        # Ground drop shadow & stone cairn collar (centered under mast at x=12, y=50)
        sm.ellipse(12.5, 51.0, 9.5, 2.5, (14, 16, 18, 105))
        sm.ellipse(12.0, 49.0, 7.5, 3.5, "C0")
        sm.ellipse(11.5, 48.0, 6.5, 2.8, "C1")
        for cx, cy in ((7, 48), (11, 46), (15, 48), (9, 50), (14, 50)):
            sm.rect(cx, cy, 3, 2, "C2")
            sm.pset(cx, cy, "C3")
        sm.rect(6, 49, 2, 2, "G1")
        sm.pset(17, 49, "G2")

        # Main seasoned oak mast trunk (x=10..13, y=5..49) + diagonal timber brace
        sm.rect(10, 5, 4, 44, "T1")
        sm.line(10, 6, 10, 48, "T0")
        sm.line(11, 6, 11, 48, "T2")
        sm.line(12, 8, 12, 46, "T3")
        sm.line(13, 6, 13, 48, "T0")
        # Diagonal brace strut anchoring mast into stone socket
        sm.line(13, 39, 17, 47, "T0")
        sm.line(14, 39, 18, 47, "T2")
        # Brass finial orb + iron binding bands + climbing cleats
        sm.circle(12, 4, 2.0, "Y2")
        sm.pset(11, 3, "Y3")
        for by in (10, 26, 42):
            sm.rect(9, by, 6, 2, "C1")
            sm.line(10, by, 13, by, "C3")
        for cy_peg in (19, 31):
            sm.rect(7, cy_peg, 3, 2, "T2")
            sm.rect(14, cy_peg + 4, 3, 2, "T2")

        # Crosstree yardarm at y=13 + brass pulley sheaves + mini Brotherhood crest plaque
        sm.rect(4, 13, 18, 2, "T2")
        sm.line(4, 13, 21, 13, "T3")
        sm.line(5, 15, 20, 15, "T0")
        sm.rect(5, 15, 2, 2, "Y1")
        sm.rect(19, 15, 2, 2, "Y1")
        # Small emerald-and-gold Brotherhood plaque below crosstree
        sm.rect(10, 16, 4, 5, "E0")
        sm.rect(11, 17, 2, 3, "E2")
        sm.pset(11, 18, "Y3")
        sm.pset(12, 18, "Y2")

        if mode == "loose":
            # Slack drooping hemp halyard + unhoisted green cloth bundle lashed at cleat
            sm.line(6, 17, 8, 29, "H1")
            sm.line(19, 17, 17, 31, "H2")
            sm.line(14, 35, 18, 41, "H1")
            sm.ellipse(16.0, 42.5, 4.0, 3.0, "E0")
            sm.ellipse(15.5, 42.0, 3.0, 2.0, "E2")
            sm.line(14, 41, 18, 43, "H2")
        else:
            # Taut Belayed Bowline Halyard + Brass Carabiner Clasp at waist cleat
            sm.line(15, 15, 14, 35, "H2")
            sm.line(14, 35, 11, 39, "H3")
            sm.rect(13, 34, 3, 2, "Y2")
            sm.pset(13, 34, "Y3")
            # Billowing Swallowtail Forest-Emerald & Gold Gale-Pennant snapping east!
            phase_off = 0 if mode == "0" else 1
            for px in range(14, 41):
                frac = (px - 14) / 26.0
                wave = round(math.sin(frac * 5.2 + phase_off * 2.6) * 2.0)
                top_y = int(round(9 + frac * 3.0 + wave))
                bot_y = int(round(23 - frac * 4.5 + wave))
                # Swallowtail notch at the outer fly tip (x=35..40)
                for py in range(top_y, bot_y + 1):
                    mid_y = (top_y + bot_y) * 0.5
                    if px >= 35 and abs(py - mid_y) < (px - 34) * 0.65:
                        continue
                    col = "E1"
                    if py == top_y or py == bot_y:
                        col = "Y1" if px % 2 == 0 else "E0"
                    elif (px + py + phase_off) % 5 == 0 and px < 33:
                        col = "E2"
                    elif wave < 0 and py <= top_y + 2:
                        col = "E2"
                    elif py >= bot_y - 1:
                        col = "E0"
                    sm.pset(px, py, col)
            # Woven Golden Twin-Wing Emblem near the pennant hoist (x=17..25)
            h_wave = round(math.sin(0.9 + phase_off * 2.6) * 1.5)
            cy_flag = 16 + h_wave
            sm.line(20, cy_flag, 17, cy_flag - 3, "Y3")
            sm.line(20, cy_flag + 1, 17, cy_flag - 1, "Y2")
            sm.line(22, cy_flag, 25, cy_flag - 3, "Y3")
            sm.line(22, cy_flag + 1, 25, cy_flag - 1, "Y2")
            sm.rect(20, cy_flag - 1, 3, 3, "Y2")
            sm.pset(21, cy_flag, "Y3")

        _save(sm, sprites_dir, f"prop_signal_mast_{mode}.png")


def _make_hunter_shackle_sprites(sprites_dir: str) -> None:
    """
    Queue 6 Church Hunter Capture Netting & Forged Wing-Shackles (56x46):
      - `prop_hunter_shackles.png`: drawn OVER bound Year 1 Kestrel — perimeter straw nest,
        diamond-mesh tarred hemp netting across his back/wings (leaving face/eyes visible),
        dual forged iron wing-cuffs, chain links & salt-rusted Church padlock at center.
      - `prop_shackles_broken.png`: drawn BENEATH wounded Kestrel — full golden straw rescue bed
        with severed rope coils and a snapped forged iron wing-clasp in the moss.
    """
    # 1. Bound Church Capture Netting & Iron Wing-Shackles (56x46)
    sh = PixelCanvas(56, 46)
    # Outer dry golden straw bedding framing the edges without burying Kestrel's head
    for sx, sy, dx, dy in (
        (6, 32, 8, -2), (9, 36, 9, 1), (42, 32, -8, -2), (46, 35, -7, 1),
        (5, 22, 5, -4), (49, 22, -5, -4), (14, 39, 8, 0), (34, 39, 8, 0),
    ):
        sh.line(sx, sy, sx + dx, sy + dy, "H1")
        sh.line(sx, sy - 1, sx + dx, sy + dy - 1, "H2")
    # Diamond-mesh tarred hemp net pinned over Kestrel's folded wings & back (y=10..27)
    for ox in range(10, 46, 7):
        sh.line(ox, 11, min(48, ox + 12), 26, "T0")
        sh.line(ox + 1, 11, min(48, ox + 13), 26, "T1")
    for ox in range(14, 48, 7):
        sh.line(ox, 11, max(8, ox - 12), 26, "T0")
        sh.line(ox - 1, 11, max(8, ox - 11), 26, "T1")
    # Heavy perimeter rope border + wooden stakes driven into stone
    sh.line(10, 12, 46, 12, "T2")
    sh.line(10, 26, 21, 26, "T2")
    sh.line(35, 26, 46, 26, "T2")
    for st_x, st_y in ((7, 25), (47, 25), (12, 10), (42, 10)):
        sh.rect(st_x, st_y, 3, 6, "T1")
        sh.pset(st_x + 1, st_y, "T3")
    # Forged iron wing-cuffs gripping left/right wrists + central rusted Church padlock
    for cx_c in (14, 38):
        sh.rect(cx_c, 18, 5, 8, "C0")
        sh.rect(cx_c + 1, 19, 3, 6, "C2")
        sh.pset(cx_c + 2, 20, "C4")
        sh.pset(cx_c + 1, 23, "Y0")  # Salt-rust speck
    sh.line(18, 22, 38, 22, "C1")
    for lk in range(20, 38, 4):
        sh.rect(lk, 21, 2, 2, "C3")
    # Central iron-and-rust padlock clasp over center back
    sh.rect(25, 18, 6, 7, "C0")
    sh.rect(26, 19, 4, 5, "Y0")
    sh.rect(27, 20, 2, 3, "I0")
    sh.line(26, 17, 29, 17, "C3")
    sh.pset(28, 21, "Y2")
    _save(sh, sprites_dir, "prop_hunter_shackles.png")

    # 2. Severed Capture Net & Snapped Wing-Shackle Clasp on Straw Bed (56x46)
    sb = PixelCanvas(56, 46)
    sb.ellipse(28, 30, 22, 11, (14, 16, 18, 85))
    sb.ellipse(28, 29, 21, 10, "H0")
    sb.ellipse(28, 28, 19, 8.5, "H1")
    sb.ellipse(27, 27, 14, 5.5, "H2")
    for st_x, st_y, ddx in ((10, 24, 7), (16, 31, 9), (24, 23, 8), (33, 29, 9), (19, 27, 6), (37, 24, 7)):
        sb.line(st_x, st_y, st_x + ddx, st_y + 2, "H3")
    # Cut & cast-aside tarred hemp net coils left & right
    sb.line(6, 26, 15, 34, "T1")
    sb.line(9, 23, 13, 35, "T0")
    sb.line(41, 27, 49, 34, "T1")
    sb.line(43, 24, 47, 35, "T0")
    # Snapped forged iron wing-cuff + split rusty Church padlock resting in lower straw
    sb.rect(19, 35, 5, 4, "C0")
    sb.rect(20, 36, 3, 2, "C3")
    sb.rect(31, 35, 5, 4, "C0")
    sb.rect(32, 36, 3, 2, "C3")
    sb.rect(25, 36, 4, 4, "Y0")
    sb.line(25, 36, 29, 39, "K")  # Fracture crack across lock body
    sb.pset(26, 37, "C4")
    _save(sb, sprites_dir, "prop_shackles_broken.png")


def _make_egg_cradle_pedestal(sprites_dir: str):
    """Queue 9: Forged Wrought-Iron & Brass Dragon-Egg Hearth Pedestal (36x36)."""
    c = PixelCanvas(36, 36)
    # Soft circular ground shadow
    c.ellipse(18, 32, 12, 3, (14, 16, 18, 110))

    # Stepped circular granite plinth (y=26..33)
    c.ellipse(18, 30, 11, 4, "C0")
    c.ellipse(18, 29, 10, 3.5, "C2")
    c.ellipse(18, 27, 8, 2.5, "C3")

    # Three wrought-iron splayed tripod legs rising to cradle bowl
    c.line(10, 29, 14, 19, "CS", 2)
    c.line(26, 29, 22, 19, "CS", 2)
    c.line(18, 30, 18, 20, "C1", 2)
    c.pset(12, 24, "CS2")
    c.pset(24, 24, "CS2")

    # Hammered bronze fire-brazier pan beneath cradle (y=16..22)
    c.ellipse(18, 19, 10, 4.5, "CS")
    c.ellipse(18, 18, 9, 3.8, "C1")
    # Glowing hearth coals inside brazier bowl
    c.ellipse(18, 17, 7, 2.5, "R1")
    c.ellipse(18, 17, 5, 1.8, "Y1")
    for ex in (15, 18, 21):
        c.pset(ex, 16, "Y2")
    c.pset(17, 17, "Y3")

    # Riveted brass-and-iron Brotherhood dragon-egg cradle ring + straw cushions (y=8..16)
    c.ellipse(18, 13, 11, 5.2, "CS")
    c.ellipse(18, 12, 10, 4.4, "Y0")
    c.ellipse(18, 12, 8.2, 3.2, "H0")
    c.ellipse(18, 12, 6.5, 2.2, "H2")
    # Brass corner rivets + carved Brotherhood wing-prongs cradling egg
    for rx, ry in ((9, 12), (27, 12), (18, 16), (18, 8)):
        c.rect(rx - 1, ry - 1, 2, 2, "Y2")
    c.line(9, 12, 12, 7, "Y1", 2)
    c.line(27, 12, 24, 7, "Y1", 2)
    c.pset(12, 7, "Y2")
    c.pset(24, 7, "Y2")

    c.add_outline("K", selective_hue=True)
    _save(c, sprites_dir, "prop_egg_cradle_pedestal.png")


def make_sanctuary_assets(sprites_dir: str) -> int:
    _make_chore_props_and_icons(sprites_dir)
    _make_village_buildings_and_tents(sprites_dir)
    _make_stalls_props_and_livestock(sprites_dir)
    _make_signal_mast_sprites(sprites_dir)
    _make_hunter_shackle_sprites(sprites_dir)
    _make_egg_cradle_pedestal(sprites_dir)
    return 41
