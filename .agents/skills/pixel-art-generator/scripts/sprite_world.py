"""
World Tiles, Ships, Medieval Flemish Buildings, Animated Dragons, Props, and UI Sprites
for Temeraire: Wings of the Brotherhood.

Facade re-exporting modular generators so generate_pixel_assets.py stays stable.
"""

import math
import os
from pixel_art_lib import PixelCanvas
from sprite_world_buildings import make_tiles, make_merchant_cog, make_buildings
from sprite_dragons import make_dragons
from sprite_props import make_props
from sprite_icons_combat import make_icons_and_combat_props
from sprite_wilds_env import make_wilds_env
from sprite_sanctuary import make_sanctuary_assets
from sprite_bruges_landmarks import make_bruges_landmarks
from sprite_bruges_forts_water import make_bruges_forts_water
from sprite_louvain_landmarks import make_louvain_assets
from sprite_louvain_dungeon import make_louvain_dungeon_assets
from sprite_ui_art import make_extra_ui_and_title_art


def make_props_and_icons(sprites_dir: str):
    make_props(sprites_dir)
    make_icons_and_combat_props(sprites_dir)
    make_wilds_env(sprites_dir)
    make_sanctuary_assets(sprites_dir)
    make_bruges_landmarks(sprites_dir)
    make_bruges_forts_water(sprites_dir)
    make_louvain_assets(sprites_dir)
    make_louvain_dungeon_assets(sprites_dir)


# ============================================================================
# 6. STYLIZED MEDIEVAL 9-SLICE UI FRAMES, BUTTONS & BROTHERHOOD WAX SEALS
# ============================================================================

def make_ui_sprites(sprites_dir: str):
    # 1) Ornate Large Modal 9-Slice Frame (48x48, margins=12px)
    p = PixelCanvas(48, 48)
    # Interior subtle textured charcoal-slate backing
    for y in range(2, 46):
        for x in range(2, 46):
            bg = (22, 19, 28, 244)
            if y % 4 == 0:
                bg = (25, 22, 32, 244)
            if x == 3 or y == 3:
                bg = (16, 14, 20, 244)
            p.pset(x, y, bg)
    # Stepped chamfered oak & antique hammered brass border
    p.rect_outline(0, 0, 48, 48, "K")
    p.rect_outline(1, 1, 46, 46, "T0")
    p.rect_outline(2, 2, 44, 44, "Y0")
    p.rect_outline(3, 3, 42, 42, "Y1")
    p.line(3, 3, 44, 3, "Y2")
    p.line(3, 3, 3, 44, "Y2")
    p.rect_outline(4, 4, 40, 40, "K")
    # Chamfered outer pixels for crafted silhouette (leave corners carved)
    for cx, cy in ((0, 0), (47, 0), (0, 47), (47, 47)):
        p.pset(cx, cy, ".")
    # Hammered Brass Corner Clasps & Rivets
    corners = ((1, 1, 1, 1), (41, 1, -1, 1), (1, 41, 1, -1), (41, 41, -1, -1))
    for bx, by, sx, sy in corners:
        p.rect(bx, by, 6, 6, "Y0")
        p.rect(bx + 1, by + 1, 4, 4, "Y1")
        p.pset(bx + 2, by + 2, "Y3")
        # Arm extensions along frame edge
        if sx > 0:
            p.rect(bx + 6, by + 1, 4, 2, "Y2")
            p.rect(bx + 1, by + 6, 2, 4, "Y2")
        else:
            p.rect(bx - 4, by + 1, 4, 2, "Y1")
            p.rect(bx + 3, by + 6, 2, 4, "Y1")
    # Cardinal midpoint tiny brass studs
    for mx, my in ((23, 2), (24, 2), (23, 45), (24, 45), (2, 23), (2, 24), (45, 23), (45, 24)):
        p.pset(mx, my, "Y3")
    p.save_png(os.path.join(sprites_dir, "ui_panel_9slice.png"))

    # 2) Sleek Compact HUD / Dialogue 9-Slice Frame (36x36, margins=8px)
    h = PixelCanvas(36, 36)
    for y in range(2, 34):
        for x in range(2, 34):
            bg = (21, 18, 27, 236) if (y % 3) else (25, 21, 31, 236)
            h.pset(x, y, bg)
    h.rect_outline(0, 0, 36, 36, "K")
    h.rect_outline(1, 1, 34, 34, "Y0")
    h.rect_outline(2, 2, 32, 32, "Y1")
    h.line(2, 2, 33, 2, "Y2")
    h.line(2, 2, 2, 33, "Y2")
    h.rect_outline(3, 3, 30, 30, "S")
    for cx, cy in ((0, 0), (35, 0), (0, 35), (35, 35)):
        h.pset(cx, cy, ".")
    for rx, ry in ((1, 1), (31, 1), (1, 31), (31, 31)):
        h.rect(rx, ry, 4, 4, "Y0")
        h.rect(rx + 1, ry + 1, 2, 2, "Y2")
        h.pset(rx + 1, ry + 1, "Y3")
    h.save_png(os.path.join(sprites_dir, "ui_hud_9slice.png"))

    # 3) Tactile Beveled Leather & Brass 9-Slice Buttons (24x24, margins=6px)
    for state in ("normal", "hover", "pressed"):
        b = PixelCanvas(24, 24)
        fill = "T0" if state == "pressed" else ("R1" if state == "hover" else "T1")
        fill_hi = "T1" if state == "pressed" else ("R2" if state == "hover" else "T2")
        rim = "Y2" if state == "hover" else ("Y0" if state == "pressed" else "Y1")
        rim_lo = "Y0" if state == "normal" else ("K" if state == "pressed" else "Y1")
        b.rect(1, 1, 22, 22, fill)
        b.rect(3, 3, 18, 18, fill_hi if state != "pressed" else fill)
        b.rect_outline(0, 0, 24, 24, "K")
        b.rect_outline(1, 1, 22, 22, rim_lo)
        b.line(2, 2, 21, 2, "Y3" if state == "hover" else rim)
        b.line(2, 2, 2, 21, rim)
        for cx, cy in ((0, 0), (23, 0), (0, 23), (23, 23)):
            b.pset(cx, cy, ".")
        for rx, ry in ((2, 2), (20, 2), (2, 20), (20, 20)):
            b.rect(rx, ry, 2, 2, "Y2" if state == "hover" else "Y1")
        b.save_png(os.path.join(sprites_dir, f"ui_btn_{state}.png"))

    # 4) Recessed Dark Brass Portrait Frame (52x52, margins=6px)
    pf = PixelCanvas(52, 52)
    pf.rect(0, 0, 52, 52, "K")
    pf.rect(1, 1, 50, 50, "T0")
    pf.rect(2, 2, 48, 48, "Y0")
    pf.rect(3, 3, 46, 46, "N")
    pf.line(2, 2, 49, 2, "Y2")
    pf.line(2, 2, 2, 49, "Y2")
    for rx, ry in ((1, 1), (48, 1), (1, 48), (48, 48)):
        pf.rect(rx, ry, 3, 3, "Y1")
        pf.pset(rx + 1, ry + 1, "Y3")
    pf.save_png(os.path.join(sprites_dir, "ui_frame_portrait.png"))

    # 5) Crimson & Gold Brotherhood Wax Seal (24x24) — Twin Dragon Wings & Carabiner Diamond
    ws = PixelCanvas(24, 24)
    ws.ellipse(12, 12, 9.5, 9.0, "I0")
    ws.ellipse(11.5, 11.5, 8.2, 7.8, "I1")
    ws.ellipse(11.0, 11.0, 6.2, 5.8, "I0")
    ws.ellipse(11.5, 11.5, 5.0, 4.6, "I2")
    for dx, dy in ((4, 15), (19, 14), (9, 20), (15, 20), (6, 6)):
        ws.circle(dx, dy, 1.5, "I0")
    # Embossed twin spread wings + central diamond motif matching official emblem
    for sign in (-1, 1):
        ws.line(12 + sign * 2, 12, 12 + sign * 6, 8, "Y3")
        ws.line(12 + sign * 2, 13, 12 + sign * 6, 10, "Y2")
        ws.line(12 + sign * 2, 14, 12 + sign * 5, 13, "Y1")
    for py in range(9, 16):
        hw = 2 - abs(py - 12) // 2
        ws.rect(12 - hw, py, hw * 2 + 1, 1, "Y2")
    ws.pset(12, 12, "Y3")
    ws.pset(12, 10, "Y3")
    ws.add_outline("K", selective_hue=True)
    ws.save_png(os.path.join(sprites_dir, "ui_wax_seal.png"))

    # 6) Official Secret Brotherhood of Dragon Riders Emblem Medallion (48x48)
    # "Twin Harnessed Dragon Wings & Braided Rope Carabiner Crest"
    em = PixelCanvas(48, 48)
    cx_em, cy_em = 24, 23
    # Soft drop shadow + outer brass-bound circular braided cord ring
    em.circle(cx_em, cy_em + 2, 20.5, (10, 12, 14, 120))
    em.circle(cx_em, cy_em, 20.0, "Y0")
    em.circle(cx_em, cy_em, 18.8, "Y1")
    em.circle(cx_em, cy_em, 17.2, "H2")
    em.circle(cx_em, cy_em, 16.0, "T0")
    # Diagonal braided rope notches around brass ring
    for angle_i in range(24):
        ang = (angle_i / 24.0) * math.tau
        rx = int(round(cx_em + math.cos(ang) * 18.0))
        ry = int(round(cy_em + math.sin(ang) * 18.0))
        em.pset(rx, ry, "Y3" if angle_i % 2 == 0 else "Y0")
    # Inner Forest-Emerald Heraldic Field with concentric heraldic sheen
    em.circle(cx_em, cy_em, 15.0, "E0")
    em.circle(cx_em, cy_em - 1, 13.0, "E1")
    em.ellipse(cx_em, cy_em - 2, 9.0, 8.0, "E2")
    # Twin Swept Burnished-Gold Dragon Wings (solid scalloped membrane + bright leading spar)
    for sign in (-1, 1):
        for step in range(1, 14):
            wx = cx_em + sign * (2 + step)
            # Top leading bone sweeps cleanly upward & outward
            y_top = cy_em - int((step ** 1.08) * 0.52)
            # Scalloped trailing membrane arches into 3 sharp dragon wing pinions
            if step <= 5:
                y_bot = cy_em + 3
            elif step <= 9:
                y_bot = cy_em + 2 + ((step - 5) // 2)
            elif step <= 12:
                y_bot = cy_em - 1 + (step - 9)
            else:
                y_bot = y_top + 2
            # Dark bronze outline shadow below each wing edge for pop against emerald field
            em.line(wx, y_top, wx, y_bot + 1, "Y0")
            em.line(wx, y_top, wx, y_bot, "Y1" if step % 3 == 0 else "Y2")
            # Bright sunlit leading spar
            em.pset(wx, y_top, "Y3" if step < 12 else "L0")
            if step in (4, 8, 12):
                em.line(cx_em + sign * 3, cy_em + 1, wx, y_top + 1, "Y3")
        # Three crisp pinion tips
        em.pset(cx_em + sign * 15, cy_em - 8, "L0")
        em.pset(cx_em + sign * 11, cy_em + 4, "Y3")
        em.pset(cx_em + sign * 7, cy_em + 5, "Y2")
    # Central Beveled Brass Harness Carabiner Diamond & Crimson Brotherhood Core
    for dy in range(-7, 8):
        hw = max(0, 5 - abs(dy) * 5 // 7)
        em.rect(cx_em - hw, cy_em + dy, hw * 2 + 1, 1, "T0")
    for dy in range(-6, 7):
        hw = max(0, 4 - abs(dy) * 4 // 6)
        em.rect(cx_em - hw, cy_em + dy, hw * 2 + 1, 1, "Y2")
        if dy <= 0:
            em.pset(cx_em - hw, cy_em + dy, "Y3")
    em.rect(cx_em - 2, cy_em - 2, 5, 5, "I0")
    em.rect(cx_em - 1, cy_em - 1, 3, 3, "I1")
    em.pset(cx_em - 1, cy_em - 1, "I2")
    em.pset(cx_em, cy_em - 5, "Y3")
    # 4 Centered Cardinal Brass Ring Clasp Studs + Symmetric Swallowtail Ribbon Scroll at Base
    for sx, sy in ((cx_em, 5), (cx_em, 41), (6, cy_em), (42, cy_em)):
        em.rect(sx - 1, sy - 1, 3, 3, "Y0")
        em.pset(sx, sy, "Y2")
        em.pset(sx, sy - 1, "Y3")
    for sign in (-1, 1):
        em.line(cx_em + sign * 3, 38, cx_em + sign * 11, 43, "E0")
        em.line(cx_em + sign * 3, 39, cx_em + sign * 10, 44, "E2")
        em.line(cx_em + sign * 3, 40, cx_em + sign * 9, 44, "Y2")
    em.add_outline("K", selective_hue=True)
    em.save_png(os.path.join(sprites_dir, "ui_brotherhood_emblem.png"))

    # 7) Compact 16x16 Brotherhood Crest Icon (HUD / Cards / Stamped Badges)
    # Centered at (7, 7) so a full 1px outline wraps cleanly inside 0..14 on all 4 sides
    ic = PixelCanvas(16, 16)
    cx_ic, cy_ic = 7, 7
    ic.circle(cx_ic, cy_ic, 5.8, "Y1")
    ic.circle(cx_ic, cy_ic, 4.6, "E0")
    ic.circle(cx_ic, cy_ic, 3.6, "E2")
    # Twin spread golden dragon wings contained crisply within emerald medallion
    for sign in (-1, 1):
        ic.line(cx_ic + sign * 2, cy_ic, cx_ic + sign * 4, cy_ic - 2, "Y3")
        ic.line(cx_ic + sign * 2, cy_ic + 1, cx_ic + sign * 4, cy_ic, "Y2")
        ic.pset(cx_ic + sign * 3, cy_ic + 2, "Y1")
    # Central brass diamond + crimson jewel
    for dy in range(-2, 3):
        hw = max(0, 2 - abs(dy))
        ic.rect(cx_ic - hw, cy_ic + dy, hw * 2 + 1, 1, "Y2")
    ic.pset(cx_ic, cy_ic, "I2")
    ic.pset(cx_ic, cy_ic - 2, "Y3")
    ic.add_outline("K", selective_hue=True)
    ic.save_png(os.path.join(sprites_dir, "icon_brotherhood_emblem.png"))

    make_extra_ui_and_title_art(sprites_dir)
