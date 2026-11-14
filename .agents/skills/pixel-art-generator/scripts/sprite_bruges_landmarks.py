"""
Queue 9 Bruges Landmark Buildings, Stone Canal Bridges, Chain Wagon,
and Queue 10 Diegetic Exterior Props (replacing building name cards).
"""

import os
from pixel_art_lib import PAL, PixelCanvas
from sprite_world_buildings import _draw_brick_wall, _draw_shingles


def _draw_slate_spire(c: PixelCanvas, cx: int, y_top: int, half_w: int, h: int):
    """Draw a steep Flemish slate spire with central highlight ridge."""
    for dy in range(h):
        t = dy / max(1, h - 1)
        hw = max(1, int(round(1 + (half_w - 1) * t)))
        y = y_top + dy
        for dx in range(-hw, hw + 1):
            if dx < -hw // 2:
                col = "N"
            elif dx < hw // 4:
                col = "S"
            elif dx < (hw * 3) // 4:
                col = "CS"
            else:
                col = "C1"
            if dy % 4 == 3:
                col = "N"
            c.pset(cx + dx, y, col)
    c.line(cx, y_top + 2, cx, y_top + h - 1, "CS2")


def _draw_lancet_window(c: PixelCanvas, x: int, y: int, w: int, h: int, glass="Y1", lit=True):
    """Draw a pointed stone-framed gothic window."""
    c.rect(x, y + 1, w, h - 1, "C0")
    if w >= 3:
        c.line(x + 1, y, x + w - 2, y, "C2")
    fill = glass if lit else "CS"
    c.rect(x + 1, y + 2, max(1, w - 2), max(1, h - 3), fill)
    if lit and w >= 4 and h >= 5:
        c.pset(x + 1, y + 2, "Y2")


def make_bldg_bruges_belfry(sprites_dir: str):
    """96x128 Belfry & Cloth Hall (Lakenhalle) with draped wool banners."""
    c = PixelCanvas(96, 128)

    # Subtle ground drop shadow
    c.ellipse(48, 122, 43, 5, (14, 12, 18, 110))

    # --- Flanking Hall Wings (left/right, y=68..122) ---
    _draw_brick_wall(c, 6, 74, 84, 48, "R0", "R1", "R2")
    # Granite ashlar plinth
    c.rect(6, 110, 84, 12, "C1")
    for sx in range(8, 86, 8):
        c.rect(sx, 111, 6, 4, "C2")
        c.rect(sx + 3, 116, 6, 5, "C2")
    # Slate wing roofs + dormer vents
    _draw_shingles(c, 5, 58, 28, 20, "N", "S", "CS")
    _draw_shingles(c, 63, 58, 28, 20, "N", "S", "CS")
    c.line(5, 58, 32, 58, "C2")
    c.line(63, 58, 90, 58, "C2")
    # Corner stepped gables on wings (*trapgevel*)
    for step, (gx, gw, gy, gh) in enumerate([
        (6, 18, 56, 8), (8, 14, 51, 5), (11, 8, 47, 4),
    ]):
        _draw_brick_wall(c, gx, gy, gw, gh, "R0", "R2", "R3")
        c.line(gx, gy, gx + gw - 1, gy, "C3")
        rx = 96 - gx - gw
        _draw_brick_wall(c, rx, gy, gw, gh, "R0", "R2", "R3")
        c.line(rx, gy, rx + gw - 1, gy, "C3")

    # Gothic cloth-market arcades & draped wool cloth banners under wings
    banners = [(11, "I1", "I2"), (21, "U1", "U2"), (67, "E1", "E2"), (77, "Y0", "Y1")]
    for bx, bc1, bc2 in banners:
        # Pointed stone arcade niche
        c.rect(bx - 1, 84, 9, 18, "C0")
        c.rect(bx, 85, 7, 16, "S")
        c.line(bx, 83, bx + 6, 83, "C3")
        # Draped guild bolt / sample banner hanging outside arcade
        c.rect(bx + 1, 88, 5, 11, bc1)
        c.line(bx + 2, 88, bx + 2, 97, bc2)
        c.line(bx + 1, 98, bx + 5, 98, "Y1")

    # --- Central Belfry Tower (x=31..64, y=22..122) ---
    # Ashlar lower tower stage + brick middle belfry + octagonal crown
    c.rect(31, 66, 34, 56, "C1")
    c.rect(33, 66, 30, 44, "C2")
    for row in range(66, 118, 5):
        c.line(31, row, 64, row, "C0")
        for col in range(33 + ((row // 5) % 2) * 4, 63, 8):
            c.line(col, row, col, min(121, row + 4), "C0")
        # Subtle highlight bevel on upper stone edges
        if row + 1 < 118:
            c.line(34, row + 1, 61, row + 1, "C3")
    _draw_brick_wall(c, 33, 36, 30, 32, "R0", "R2", "R3")

    # Vertical stone corner piers & machicolated gallery parapet at y=33..37
    for px in (31, 61):
        c.rect(px, 34, 4, 88, "C2")
        c.line(px + 1, 34, px + 1, 121, "C3")
    c.rect(30, 32, 36, 5, "C3")
    for cx in range(31, 65, 5):
        c.rect(cx, 29, 3, 4, "C3")
        c.pset(cx + 1, 29, "C4")

    # Upper octagonal lantern crown (y=16..31) & tall Bruges spire (y=5..17)
    c.rect(37, 17, 22, 13, "C2")
    c.rect(40, 17, 16, 13, "C3")
    for cx in (38, 43, 51, 56):
        c.rect(cx, 19, 3, 9, "N")
        c.pset(cx + 1, 22, "Y0")
    _draw_slate_spire(c, 48, 5, 11, 13)
    # Gilded Flemish lion/dragon finial atop spire
    c.line(48, 2, 48, 5, "Y1")
    c.rect(46, 2, 4, 2, "Y2")

    # Belfry bell louvres & bronze carillon bell + clock dial
    c.rect(39, 41, 18, 12, "C0")
    c.rect(41, 42, 14, 10, "N")
    # Slatted bell louvers & golden bell glint
    for ly in range(43, 52, 2):
        c.line(41, ly, 54, ly, "S")
    c.rect(45, 44, 6, 5, "Y1")
    c.line(46, 44, 49, 44, "Y2")
    # Gilded town clock dial
    c.circle(48, 62, 5, "C0")
    c.circle(48, 62, 4, "L1")
    c.line(48, 62, 48, 59, "K")
    c.line(48, 62, 50, 62, "K")
    c.pset(48, 58, "Y1")

    # Grand vaulted stone Cloth Hall portal
    c.rect(38, 92, 20, 30, "C0")
    c.rect(40, 95, 16, 27, "T1")
    c.rect(42, 97, 5, 25, "T2")
    c.rect(49, 97, 5, 25, "T2")
    c.line(48, 95, 48, 121, "T0")
    c.rect(40, 92, 16, 3, "C3")
    # Stone stair treads & brass portal lanterns
    c.rect(36, 120, 24, 3, "C3")
    for lx in (35, 59):
        c.rect(lx, 99, 2, 4, "Y1")
        c.pset(lx, 100, "Y3")

    # Wing lancet windows & cloth-merchant eaves awning in center
    for wx in (13, 23, 68, 78):
        _draw_lancet_window(c, wx, 64, 5, 9, glass="Y1", lit=True)

    c.add_outline("K", selective_hue=True)
    c.save_png(os.path.join(sprites_dir, "bldg_bruges_belfry.png"))


def make_bldg_bruges_cathedral(sprites_dir: str):
    """112x112 St. Donatian's Church with buttresses, rose window & slate spire."""
    c = PixelCanvas(112, 112)
    c.ellipse(56, 106, 50, 5, (14, 12, 18, 115))

    # --- Transept / Side Aisles (x=10..101, y=54..105) ---
    c.rect(10, 62, 92, 43, "C1")
    c.rect(12, 62, 88, 36, "C2")
    for y in range(62, 105, 5):
        c.line(10, y, 101, y, "C0")
        for col in range(14 + ((y // 5) % 2) * 5, 98, 10):
            c.line(col, y, col, min(104, y + 4), "C0")
    # Slate aisle roofs + leaded leadlight ridges
    _draw_shingles(c, 8, 46, 96, 20, "N", "S", "CS")
    c.line(8, 46, 103, 46, "CS2")

    # Stone flying/stepped buttresses along facade & aisles
    for bx in (12, 26, 38, 70, 82, 96):
        c.rect(bx, 58, 4, 47, "C3")
        c.line(bx, 58, bx, 104, "C4")
        c.line(bx + 3, 58, bx + 3, 104, "C1")
        c.rect(bx, 56, 4, 2, "C4")

    # Stained-glass lancet windows in side aisles
    for wx, col in ((18, "I1"), (31, "U2"), (75, "U2"), (88, "I1")):
        _draw_lancet_window(c, wx, 72, 6, 15, glass=col, lit=True)
        c.pset(wx + 2, 76, "Y2")
        c.pset(wx + 3, 80, "Y1")

    # --- Central Nave Gable & Steeple Tower (x=36..75, y=4..105) ---
    c.rect(36, 30, 40, 75, "C2")
    for y in range(32, 105, 5):
        c.line(36, y, 75, y, "C1")
        for col in range(38 + ((y // 5) % 2) * 4, 73, 8):
            c.line(col, y, col, min(104, y + 4), "C1")
    # Nave steep triangular stone gable rising above aisle roof
    for dy in range(18):
        hw = 10 + dy
        c.line(56 - hw, 28 + dy, 56 + hw, 28 + dy, "C3")
        c.pset(56 - hw, 28 + dy, "C4")
        c.pset(56 + hw, 28 + dy, "C1")
    # Tall crossing steeple behind gable
    c.rect(45, 22, 22, 16, "C2")
    c.rect(47, 22, 18, 14, "C3")
    _draw_slate_spire(c, 56, 5, 12, 18)
    # Gilded Latin Cross above spire
    c.line(56, 1, 56, 6, "Y2")
    c.line(54, 3, 58, 3, "Y2")

    # Grand Circular Rose Window (center cx=56, cy=52)
    c.circle(56, 52, 10, "C0")
    c.circle(56, 52, 9, "C3")
    c.circle(56, 52, 7, "N")
    # Rose petal stained glass wedges
    c.circle(56, 52, 6, "U2")
    c.circle(56, 52, 4, "I1")
    c.circle(56, 52, 2, "Y2")
    for dx, dy in ((0, -5), (0, 5), (-5, 0), (5, 0), (-3, -3), (3, -3), (-3, 3), (3, 3)):
        c.pset(56 + dx, 52 + dy, "Y1")

    # Deeply recessed Gothic Portal & Stone Steps
    c.rect(42, 74, 28, 31, "C0")
    c.rect(44, 75, 24, 30, "C3")
    c.rect(46, 78, 20, 27, "C1")
    c.rect(48, 81, 16, 24, "T1")
    c.rect(49, 82, 6, 23, "T2")
    c.rect(57, 82, 6, 23, "T2")
    c.line(56, 81, 56, 104, "T0")
    # Brass hinges + carved arch tympanum
    for hy in (87, 96):
        c.rect(50, hy, 4, 2, "Y1")
        c.rect(58, hy, 4, 2, "Y1")
    c.circle(56, 79, 3, "Y1")
    # Stone stair apron + flanking church braziers
    c.rect(40, 104, 32, 3, "C3")
    for lx in (38, 72):
        c.rect(lx, 88, 3, 6, "S")
        c.rect(lx, 85, 3, 3, "Y1")
        c.pset(lx + 1, 84, "Y3")

    c.add_outline("K", selective_hue=True)
    c.save_png(os.path.join(sprites_dir, "bldg_bruges_cathedral.png"))


def make_bldg_bruges_keep(sprites_dir: str):
    """120x104 Main Keep & Guard Bastion (Prinsenhof Gatehouse) with twin towers & portcullis."""
    c = PixelCanvas(120, 104)
    c.ellipse(60, 98, 54, 5, (14, 12, 18, 120))

    # --- Central Slate-Roofed Donjon behind curtain wall ---
    c.rect(34, 26, 52, 46, "C1")
    c.rect(36, 28, 48, 42, "C2")
    _draw_shingles(c, 32, 14, 56, 18, "N", "S", "CS")
    c.line(32, 14, 87, 14, "C2")
    # Donjon battlements & upper arrow slits
    for cx in range(34, 86, 6):
        c.rect(cx, 23, 4, 4, "C3")
    for wx in (46, 58, 70):
        _draw_lancet_window(c, wx, 34, 4, 9, glass="Y1", lit=True)

    # --- Curtain Wall & Raised Iron Portcullis Gatehouse ---
    c.rect(22, 54, 76, 44, "C1")
    c.rect(24, 56, 72, 40, "C2")
    for y in range(54, 98, 5):
        c.line(22, y, 97, y, "C0")
        for col in range(26 + ((y // 5) % 2) * 5, 95, 10):
            c.line(col, y, col, min(97, y + 4), "C0")
    # Crenellated wall-walk parapet + machicolation corbels
    c.rect(22, 50, 76, 5, "C3")
    for cx in range(23, 95, 6):
        c.rect(cx, 46, 4, 5, "C3")
        c.pset(cx + 1, 46, "C4")
        c.rect(cx + 1, 55, 2, 3, "C0")

    # Twin Circular/Octagonal Flanking Gatehouse Towers (left x=6..28, right x=92..114)
    for tx, is_left in ((6, True), (90, False)):
        c.rect(tx, 34, 24, 64, "C1")
        c.rect(tx + 3, 34, 14 if is_left else 16, 62, "C2")
        c.rect(tx + 5, 34, 6, 62, "C3")
        for row in range(36, 98, 5):
            c.line(tx, row, tx + 23, row, "C0")
            for col in range(tx + 3 + ((row // 5) % 2) * 4, tx + 22, 8):
                c.line(col, row, col, min(97, row + 4), "C0")
        # Tower corbelled battlement collar
        c.rect(tx - 1, 31, 26, 4, "C3")
        for cx in range(tx, tx + 24, 5):
            c.rect(cx, 28, 3, 3, "C4")
        # Conical slate turret roof
        _draw_slate_spire(c, tx + 12, 10, 14, 19)
        # Church-Inquisitor scarlet pennant flying from turret top
        c.line(tx + 12, 3, tx + 12, 10, "C3")
        c.rect(tx + 13, 4, 8, 4, "I1")
        c.line(tx + 13, 5, tx + 18, 5, "I2")
        # Barred arrow loops on drum tower
        for ay in (46, 66):
            c.rect(tx + 10, ay, 3, 9, "N")
            c.pset(tx + 11, ay + 4, "Y1")

    # Grand Arched Gatehouse Sally-Port & Iron Portcullis
    c.rect(45, 62, 30, 36, "C0")
    c.rect(47, 64, 26, 34, "C3")
    c.rect(50, 68, 20, 30, "N")
    # Raised iron portcullis spikes in upper half of arch
    for px in range(52, 69, 3):
        c.line(px, 68, px, 79, "CS2")
        c.pset(px, 80, "C4")
    for py in (71, 75, 78):
        c.line(50, py, 69, py, "CS")
    # Inner timber guardroom passage visible beneath raised grate
    c.rect(51, 80, 18, 18, "T0")
    c.rect(54, 83, 12, 15, "S")
    # Glowing iron torch sconces flanking gate
    for lx in (42, 76):
        c.rect(lx, 74, 2, 7, "C0")
        c.rect(lx - 1, 71, 4, 4, "Y1")
        c.pset(lx, 72, "Y3")
    # Scarlet & gold Church Inquisition escutcheon shield above arch
    c.rect(57, 56, 6, 7, "I1")
    c.line(58, 57, 61, 57, "Y2")
    c.line(60, 56, 60, 62, "Y2")

    c.add_outline("K", selective_hue=True)
    c.save_png(os.path.join(sprites_dir, "bldg_bruges_keep.png"))


def make_bldg_beguinage_court(sprites_dir: str):
    """88x76 Beguinage Herb Court & Apothecary (Begijnhof whitewashed cottage)."""
    c = PixelCanvas(88, 76)
    c.ellipse(44, 72, 40, 4, (14, 12, 18, 105))

    # Whitewashed lime walls over low brick & moss plinth
    c.rect(6, 36, 76, 36, "L1")
    c.rect(8, 38, 66, 30, "L0")
    # Gentle plaster aging mottling
    for px in range(10, 78, 9):
        for py in range(42, 64, 7):
            c.rect(px, py, 3, 2, "L2")
    _draw_brick_wall(c, 6, 63, 76, 9, "R0", "R1", "R2")

    # Warm terracotta tiled roof + twin dormer gables
    _draw_shingles(c, 4, 16, 80, 24, "R0", "R2", "R3")
    c.line(4, 16, 83, 16, "R4")
    c.line(4, 39, 83, 39, "T0")
    # Brick chimney with soft curl top
    c.rect(64, 6, 9, 14, "R1")
    c.rect(63, 5, 11, 2, "C3")

    # Twin small Beguinage dormers on roof
    for dx in (20, 52):
        c.rect(dx, 19, 12, 10, "L1")
        _draw_shingles(c, dx - 1, 14, 14, 6, "R0", "R2", "R3")
        c.rect(dx + 4, 21, 4, 6, "T0")
        c.rect(dx + 5, 22, 2, 4, "Y2")

    # Sage-green shutters & mullioned apothecary windows showing amber vials
    for wx in (13, 62):
        c.rect(wx, 43, 13, 13, "T0")
        c.rect(wx - 2, 44, 2, 11, "E1")
        c.rect(wx + 13, 44, 2, 11, "E1")
        c.rect(wx + 2, 45, 9, 9, "Y1")
        # Bottle silhouettes on windowsill
        c.rect(wx + 3, 49, 2, 4, "E2")
        c.rect(wx + 6, 48, 2, 5, "U2")
        c.rect(wx + 9, 50, 2, 3, "I1")

    # Arched garden court entrance + cascading ivy vines & dried herb bundles
    c.rect(35, 44, 18, 28, "C2")
    c.rect(37, 46, 14, 26, "T1")
    c.rect(39, 48, 10, 24, "T2")
    c.rect(43, 48, 2, 24, "T0")
    c.rect(37, 43, 14, 3, "C3")
    # Hanging dried herb bundles under eaves
    for hx in (30, 55):
        c.rect(hx, 39, 3, 7, "G2")
        c.pset(hx + 1, 44, "Y1")
        c.pset(hx + 1, 40, "T2")
    # Climbing garden ivy around door & base
    for ix, iy in ((33, 52), (34, 57), (53, 50), (54, 56), (11, 66), (72, 65)):
        c.rect(ix, iy, 3, 4, "G1")
        c.pset(ix + 1, iy + 1, "G3")

    c.add_outline("K", selective_hue=True)
    c.save_png(os.path.join(sprites_dir, "bldg_beguinage_court.png"))


def make_stone_bridges(sprites_dir: str):
    """64x44 horizontal & 44x64 vertical arched Flemish stone canal bridges."""
    # Horizontal Bridge (64x44)
    bh = PixelCanvas(64, 44)
    # Shadowed water reflection/arch soffit at lower edge
    bh.rect(4, 38, 56, 4, (14, 24, 34, 150))
    # Stone approach ramps + cambered cobblestone road (y=10..33)
    bh.rect(2, 10, 60, 24, "C1")
    bh.rect(6, 11, 52, 22, "C2")
    # Crowned center highlight across bridge arch
    bh.rect(22, 11, 20, 22, "C3")
    for sy in range(12, 32, 4):
        for sx in range(4 + ((sy // 4) % 2) * 3, 58, 7):
            bh.rect(sx, sy, 5, 3, "C3" if 18 <= sx <= 44 else "C2")
            bh.line(sx, sy + 2, sx + 4, sy + 2, "C1")
    # Top & Bottom Cut-Stone Parapet Balustrades
    for py, hi, mid in ((4, "C4", "C2"), (33, "C3", "C1")):
        bh.rect(2, py, 60, 6, mid)
        bh.line(2, py, 61, py, hi)
        bh.line(2, py + 5, 61, py + 5, "C0")
        for sx in range(6, 58, 8):
            bh.line(sx, py + 1, sx, py + 4, "C0")
    # Voussoir masonry face on south elevation
    bh.rect(14, 39, 36, 3, "C0")
    for ax in range(18, 46, 5):
        bh.rect(ax, 38, 3, 2, "C2")
    # Corner stone piers & iron bollards
    for bx in (2, 57):
        for by in (3, 32):
            bh.rect(bx, by, 5, 7, "C3")
            bh.rect(bx + 1, by, 3, 2, "C4")
            bh.pset(bx + 2, by + 3, "CS")
    # Moss flecks along damp parapets
    for mx, my in ((12, 8), (48, 34), (28, 33)):
        bh.rect(mx, my, 2, 2, "G1")
    bh.add_outline("K", selective_hue=True)
    bh.save_png(os.path.join(sprites_dir, "prop_stone_bridge_h.png"))

    # Vertical Bridge (44x64)
    bv = PixelCanvas(44, 64)
    bv.rect(38, 6, 4, 52, (14, 24, 34, 140))
    bv.rect(10, 2, 24, 60, "C1")
    bv.rect(11, 6, 22, 52, "C2")
    bv.rect(11, 22, 22, 20, "C3")
    for sy in range(4, 58, 5):
        for sx in range(12 + ((sy // 5) % 2) * 3, 31, 6):
            bv.rect(sx, sy, 4, 3, "C3" if 18 <= sy <= 44 else "C2")
            bv.line(sx, sy + 2, sx + 3, sy + 2, "C1")
    # Left & Right Stone Parapets
    for px, hi, mid in ((4, "C4", "C2"), (33, "C3", "C1")):
        bv.rect(px, 2, 6, 60, mid)
        bv.line(px, 2, px, 61, hi)
        bv.line(px + 5, 2, px + 5, 61, "C0")
        for sy in range(6, 58, 8):
            bv.line(px + 1, sy, px + 4, sy, "C0")
    for bx in (3, 32):
        for by in (2, 57):
            bv.rect(bx, by, 7, 5, "C3")
            bv.rect(bx + 1, by + 1, 5, 2, "C4")
    for mx, my in ((8, 16), (34, 42)):
        bv.rect(mx, my, 2, 2, "G1")
    bv.add_outline("K", selective_hue=True)
    bv.save_png(os.path.join(sprites_dir, "prop_stone_bridge_v.png"))


def make_prop_iron_chain_wagon(sprites_dir: str):
    """56x38 Church Dragon-Chain Supply Wagon loaded with forged iron chains."""
    c = PixelCanvas(56, 38)
    c.ellipse(29, 34, 23, 3, (14, 12, 18, 115))

    # Hitch tongue & yoke shafts extending left
    c.line(2, 21, 14, 21, "T2", 2)
    c.line(2, 25, 14, 25, "T2", 2)
    c.rect(3, 19, 2, 8, "C3")

    # Heavy spoked iron-rimmed wagon wheels
    for wx in (19, 41):
        c.circle(wx, 29, 6, "CS")
        c.circle(wx, 29, 5, "T0")
        c.circle(wx, 29, 4, "T2")
        c.circle(wx, 29, 2, "T1")
        c.pset(wx, 29, "C3")
        for dx, dy in ((-3, 0), (3, 0), (0, -3), (0, 3)):
            c.pset(wx + dx, 29 + dy, "T3")

    # Oak slatted wagon bed & iron corner strapping
    c.rect(12, 13, 38, 15, "T0")
    c.rect(13, 14, 36, 13, "T1")
    c.rect(14, 15, 34, 9, "T2")
    for sx in range(18, 48, 6):
        c.line(sx, 14, sx, 26, "T0")
        c.pset(sx, 16, "C3")
    # Iron corner plates + scarlet Inquisition badge on side plank
    c.rect(13, 14, 3, 13, "CS")
    c.rect(46, 14, 3, 13, "CS")
    c.rect(28, 19, 6, 5, "I1")
    c.line(29, 20, 32, 20, "Y1")

    # Cargo: Heavy coiled dragon-restraint chains, iron manacles & locked chest
    c.rect(16, 7, 13, 9, "T1")
    c.rect(17, 8, 11, 7, "T3")
    c.rect(17, 11, 11, 1, "C3")
    c.rect(21, 10, 3, 3, "Y1")
    # Coiled chain links spilling over rails
    for cx, cy in ((32, 10), (35, 9), (38, 10), (41, 11), (34, 13), (37, 12), (40, 14), (44, 12)):
        c.circle(cx, cy, 2, "CS")
        c.pset(cx, cy - 1, "C4")
        c.pset(cx, cy, "N")
    # Hanging chain end dangling down side
    for dy in range(15, 25, 2):
        c.rect(42 + (dy % 2), dy, 2, 2, "C3")
        c.pset(42 + (dy % 2), dy, "C4")

    c.add_outline("K", selective_hue=True)
    c.save_png(os.path.join(sprites_dir, "prop_iron_chain_wagon.png"))


def make_bruges_exterior_props(sprites_dir: str):
    """Queue 10 diegetic exterior props identifying Bruges shops & guilds."""
    # 1. Outdoor Flemish Domed Brick Bread Oven (44x36)
    o = PixelCanvas(44, 36)
    o.ellipse(22, 32, 19, 3, (14, 12, 18, 115))
    # Stone hearth plinth
    o.rect(4, 20, 26, 13, "C1")
    o.rect(5, 21, 24, 11, "C2")
    for sx in range(6, 28, 6):
        o.line(sx, 21, sx, 31, "C0")
    # Domed red-brick oven vault
    o.ellipse(17, 17, 12, 9, "R1")
    o.ellipse(17, 16, 10, 7, "R2")
    o.ellipse(15, 13, 6, 4, "R3")
    # Brick courses
    for y in range(10, 22, 3):
        o.line(7, y, 27, y, "R0")
    # Chimney flue atop rear of dome
    o.rect(14, 3, 6, 8, "R1")
    o.rect(13, 2, 8, 2, "C3")
    # Arched firebox mouth glowing warm hearth fire
    o.rect(11, 17, 12, 9, "C0")
    o.rect(12, 18, 10, 8, "R0")
    o.rect(13, 20, 8, 5, "Y1")
    o.rect(15, 21, 4, 4, "Y2")
    o.pset(16, 23, "Y3")
    # Stone ash apron & wooden baker's table holding golden crusty bread loaves
    o.rect(10, 26, 14, 3, "C3")
    o.rect(29, 21, 12, 10, "T1")
    o.rect(28, 19, 14, 3, "T2")
    o.line(28, 19, 41, 19, "T3")
    # Crusty loaves + flour dusting
    for lx, ly in ((30, 16), (36, 16), (33, 14)):
        o.ellipse(lx + 2, ly + 1, 2.6, 1.8, "H1")
        o.pset(lx + 2, ly, "H2")
        o.pset(lx + 1, ly, "L0")
    # Long baker's peel leaning on right corner
    o.line(25, 29, 31, 9, "T3")
    o.rect(29, 6, 4, 4, "T2")
    o.add_outline("K", selective_hue=True)
    o.save_png(os.path.join(sprites_dir, "prop_brick_bread_oven.png"))

    # 2. Plump Linen Flour Sack Stack (28x24)
    f = PixelCanvas(28, 24)
    f.ellipse(14, 21, 11, 2.5, (14, 12, 18, 100))
    f.rect(4, 18, 20, 3, "T1")
    for sx, sy, w, h in ((5, 11, 9, 8), (13, 12, 9, 8), (9, 6, 9, 8)):
        f.ellipse(sx + w // 2, sy + h // 2, w / 2.0, h / 2.0, "L2")
        f.ellipse(sx + w // 2 - 1, sy + h // 2 - 1, w / 2.3, h / 2.3, "L1")
        f.pset(sx + w // 2 - 1, sy + 2, "L0")
        # Tied neck & hemp cord
        f.rect(sx + w // 2 - 2, sy - 1, 4, 2, "L1")
        f.line(sx + w // 2 - 2, sy + 1, sx + w // 2 + 1, sy + 1, "H0")
    # Spilled white flour dusting
    f.rect(19, 19, 4, 2, "L0")
    f.add_outline("K", selective_hue=True)
    f.save_png(os.path.join(sprites_dir, "prop_flour_sack_stack.png"))

    # 3. Tapped Oak Ale Barrel Rack (36x28)
    a = PixelCanvas(36, 28)
    a.ellipse(18, 25, 15, 2.5, (14, 12, 18, 105))
    # Timber chock stand
    a.rect(4, 19, 28, 6, "T0")
    a.rect(5, 20, 26, 4, "T1")
    # Two horizontal oak barrels facing front with brass spigots
    for bx in (5, 19):
        a.ellipse(bx + 6, 12, 6.2, 8.2, "T1")
        a.ellipse(bx + 6, 11, 5.2, 7.2, "T2")
        a.ellipse(bx + 6, 9, 4.0, 4.5, "T3")
        # Iron hoops
        a.rect(bx + 1, 10, 10, 2, "CS")
        a.rect(bx + 1, 15, 10, 2, "CS")
        # Brass spigot & bung
        a.rect(bx + 5, 16, 2, 3, "Y1")
        a.pset(bx + 6, 18, "H3")
    # Catch bucket / overflowing ale tankard beneath left spigot
    a.rect(9, 20, 5, 5, "T2")
    a.line(9, 20, 13, 20, "L0")
    a.add_outline("K", selective_hue=True)
    c_path = os.path.join(sprites_dir, "prop_ale_barrel_rack.png")
    a.save_png(c_path)

    # 4. Outdoor Tavern Table with Tankards & Lantern (44x30)
    t = PixelCanvas(44, 30)
    t.ellipse(22, 26, 19, 3, (14, 12, 18, 100))
    # Rear bench + front bench
    t.rect(7, 8, 30, 4, "T1")
    t.line(8, 8, 35, 8, "T3")
    t.rect(7, 22, 30, 4, "T1")
    t.line(8, 22, 35, 22, "T3")
    # Main trestle table top
    t.rect(5, 12, 34, 10, "T0")
    t.rect(6, 12, 32, 8, "T2")
    t.line(6, 12, 37, 12, "T3")
    t.line(6, 15, 37, 15, "T1")
    # Foam-topped ceramic tankards, crusty bread & glowing candle
    for mx in (11, 29):
        t.rect(mx, 10, 4, 5, "C3")
        t.line(mx, 10, mx + 3, 10, "L0")
        t.pset(mx + 4, 12, "C2")
    # Glowing tallow candle in center
    t.rect(21, 11, 3, 5, "L1")
    t.pset(22, 9, "Y2")
    t.pset(22, 10, "Y1")
    t.add_outline("K", selective_hue=True)
    t.save_png(os.path.join(sprites_dir, "prop_tavern_table.png"))

    # 5. Dyed Flemish Cloth Bales Display (40x30)
    cb = PixelCanvas(40, 30)
    cb.ellipse(20, 26, 17, 3, (14, 12, 18, 105))
    # Timber market trestle stand
    cb.rect(4, 18, 32, 8, "T1")
    cb.rect(5, 16, 30, 4, "T2")
    # Stacked rolled cloth bolts (Crimson, Woad Blue, Brotherhood Emerald, Gold Trim)
    bolts = [
        (6, 10, 12, 6, "I0", "I1", "I2"),
        (19, 10, 14, 6, "U0", "U1", "U2"),
        (12, 5, 14, 6, "E0", "E1", "E2"),
    ]
    for bx, by, bw, bh, c0, c1, c2 in bolts:
        cb.rect(bx, by, bw, bh, c0)
        cb.rect(bx + 1, by + 1, bw - 2, bh - 2, c1)
        cb.line(bx + 2, by + 1, bx + bw - 3, by + 1, c2)
        # Rolled spiral endcap
        cb.rect(bx + bw - 3, by + 1, 2, bh - 2, "Y1")
    # Unrolled red silk swatch cascading over table edge
    cb.rect(8, 17, 8, 9, "I1")
    cb.line(9, 17, 9, 25, "I2")
    cb.line(8, 25, 15, 25, "Y1")
    cb.add_outline("K", selective_hue=True)
    cb.save_png(os.path.join(sprites_dir, "prop_cloth_bales.png"))

    # 6. Apothecary Medicinal Herb Planter Bed (44x30)
    hp = PixelCanvas(44, 30)
    hp.ellipse(22, 26, 19, 3, (14, 12, 18, 100))
    # Raised oak frame box filled with rich dark soil
    hp.rect(4, 12, 36, 14, "T0")
    hp.rect(5, 13, 34, 11, "T2")
    hp.rect(7, 14, 30, 8, "DK")
    # Lush medicinal herbs: emerald sage, silver-green leaves & chamomile blossoms
    for hx, col_leaf, blossom in (
        (10, "E2", "Y2"), (16, "G2", "L0"), (23, "E3", "D2"), (30, "G3", "Y2"),
    ):
        hp.ellipse(hx + 1, 13, 4.2, 4.0, "G1")
        hp.ellipse(hx + 1, 11, 3.2, 3.2, col_leaf)
        hp.pset(hx, 9, blossom)
        hp.pset(hx + 2, 10, blossom)
    # Clay terracotta watering pitcher on right edge
    hp.rect(35, 18, 5, 7, "R2")
    hp.line(36, 18, 38, 18, "R3")
    hp.add_outline("K", selective_hue=True)
    hp.save_png(os.path.join(sprites_dir, "prop_herb_planter.png"))

    # 7. Garrison Weapons & Kite-Shield Rack (40x32)
    gr = PixelCanvas(40, 32)
    gr.ellipse(20, 28, 16, 3, (14, 12, 18, 105))
    # Vertical oak rack frame & crossbar
    gr.rect(6, 8, 3, 20, "T1")
    gr.rect(31, 8, 3, 20, "T1")
    gr.rect(5, 10, 30, 3, "T2")
    gr.rect(6, 24, 28, 4, "T2")
    # Upright halberds & spears with steel heads
    for sx in (11, 17, 23, 29):
        gr.line(sx, 7, sx, 25, "T3")
        gr.rect(sx - 1, 2, 3, 6, "C3")
        gr.pset(sx, 2, "C4")
        if sx in (11, 23):
            gr.rect(sx - 3, 4, 2, 3, "CS2")  # halberd axe blade
    # Lean-to steel-rimmed Inquisition scarlet kite shields
    for shx in (10, 24):
        gr.rect(shx, 15, 7, 11, "CS2")
        gr.rect(shx + 1, 16, 5, 9, "I1")
        gr.line(shx + 3, 17, shx + 3, 23, "Y1")
        gr.line(shx + 2, 19, shx + 4, 19, "Y1")
    gr.add_outline("K", selective_hue=True)
    gr.save_png(os.path.join(sprites_dir, "prop_garrison_rack.png"))

    # 8. Ropewalker's Capstan Windlass & Braided Hawser Coils (38x30)
    rw = PixelCanvas(38, 30)
    rw.ellipse(19, 26, 16, 3, (14, 12, 18, 105))
    # Oak trestle reel frame
    rw.rect(5, 10, 3, 16, "T1")
    rw.rect(20, 10, 3, 16, "T1")
    rw.rect(4, 22, 20, 4, "T2")
    # Heavy horizontal wooden spool wound thick with golden hemp rope
    rw.rect(8, 11, 12, 9, "H1")
    for rx in range(9, 20, 2):
        rw.line(rx, 11, rx, 19, "H2")
        rw.line(rx + 1, 12, rx + 1, 19, "H0")
    # Turning hand crank on right side
    rw.line(23, 15, 26, 15, "C3")
    rw.line(26, 12, 26, 16, "T3")
    # Stacked coiled ship hawser ropes on the cobbles beside frame
    rw.ellipse(30, 21, 5.5, 4.0, "H0")
    rw.ellipse(30, 19, 4.8, 3.2, "H1")
    rw.ellipse(30, 18, 3.2, 2.0, "H2")
    rw.ellipse(30, 18, 1.2, 0.8, "DK")
    # Trailing rope end linking windlass to coil
    rw.line(18, 19, 27, 23, "H2")
    rw.add_outline("K", selective_hue=True)
    rw.save_png(os.path.join(sprites_dir, "prop_rope_windlass.png"))


def make_bruges_landmarks(sprites_dir: str):
    """Generate all Bruges landmarks, stone canal bridges, chain wagon & diegetic props."""
    make_bldg_bruges_belfry(sprites_dir)
    make_bldg_bruges_cathedral(sprites_dir)
    make_bldg_bruges_keep(sprites_dir)
    make_bldg_beguinage_court(sprites_dir)
    make_stone_bridges(sprites_dir)
    make_prop_iron_chain_wagon(sprites_dir)
    make_bruges_exterior_props(sprites_dir)
