"""
Stylized Settings UI Chrome, Icons, Sliders, Pills & Handcrafted Zelda-Inspired Title Screen Diorama Art
for Wings of the Brotherhood.

All textures obey nearest-neighbor crisp pixel standards & the 32-color Medieval Flemish palette.
"""

import math
import os
from pixel_art_lib import PAL, PixelCanvas, blend_color


def _make_9slice_box(
    path: str,
    size: int,
    fill_top: tuple,
    fill_bot: tuple,
    border_outer: tuple,
    border_inner: tuple,
    hi_edge: tuple,
    corner_stud: tuple,
    chamfer: bool = True,
    bottom_open: bool = False,
) -> None:
    p = PixelCanvas(size, size)
    for y in range(1, size - (0 if bottom_open else 1)):
        t = y / max(1.0, float(size - 1))
        col = blend_color(fill_top, fill_bot, t)
        for x in range(1, size - 1):
            p.pset(x, y, col)
    p.rect_outline(0, 0, size, size, border_outer)
    p.rect_outline(1, 1, size - 2, size - 2, border_inner)
    p.line(2, 2, size - 3, 2, hi_edge)
    p.line(2, 2, 2, size - 3, hi_edge)
    if bottom_open:
        p.line(1, size - 1, size - 2, size - 1, fill_bot)
        p.line(2, size - 2, size - 3, size - 2, fill_bot)
    if chamfer:
        for cx, cy in ((0, 0), (size - 1, 0)):
            p.pset(cx, cy, ".")
        if not bottom_open:
            for cx, cy in ((0, size - 1), (size - 1, size - 1)):
                p.pset(cx, cy, ".")
    for rx, ry in ((2, 2), (size - 3, 2)):
        p.pset(rx, ry, corner_stud)
    if not bottom_open:
        for rx, ry in ((2, size - 3), (size - 3, size - 3)):
            p.pset(rx, ry, corner_stud)
    p.save_png(path)


def _make_settings_icons(sprites_dir: str) -> None:
    # 1. Audio Horn & Bell (16x16)
    ia = PixelCanvas(16, 16)
    ia.rect(3, 6, 4, 5, "Y1")
    ia.line(3, 6, 6, 6, "Y3")
    ia.line(7, 5, 10, 3, "Y2")
    ia.line(7, 11, 10, 13, "Y0")
    for yy in range(3, 14):
        ia.pset(10, yy, "Y2" if yy < 8 else "Y1")
        if 4 <= yy <= 12:
            ia.pset(9, yy, "Y1")
    ia.line(8, 5, 8, 11, "Y0")
    # Sound arc waves
    ia.pset(12, 6, "Y3")
    ia.pset(13, 8, "Y3")
    ia.pset(12, 10, "Y3")
    ia.pset(14, 5, "L0")
    ia.pset(14, 11, "L0")
    ia.add_outline("K", selective_hue=True)
    ia.save_png(os.path.join(sprites_dir, "ui_icon_audio.png"))

    # 2. Gameplay Mariner Compass (16x16)
    ig = PixelCanvas(16, 16)
    ig.circle(8, 8, 5.5, "Y0")
    ig.circle(8, 8, 4.5, "Y1")
    ig.circle(8, 8, 3.2, "L1")
    ig.line(8, 4, 8, 12, "I1")
    ig.line(4, 8, 12, 8, "S")
    ig.pset(8, 4, "I2")
    ig.pset(8, 8, "Y3")
    ig.add_outline("K", selective_hue=True)
    ig.save_png(os.path.join(sprites_dir, "ui_icon_gameplay.png"))

    # 3. Controls Iron Key & Blade (16x16)
    ic = PixelCanvas(16, 16)
    ic.circle(5, 8, 3.0, "Y1")
    ic.circle(5, 8, 1.3, ".")
    ic.pset(4, 6, "Y3")
    ic.rect(8, 7, 6, 2, "Y2")
    ic.line(8, 7, 13, 7, "Y3")
    ic.rect(11, 9, 1, 3, "Y1")
    ic.rect(13, 9, 1, 2, "Y1")
    ic.add_outline("K", selective_hue=True)
    ic.save_png(os.path.join(sprites_dir, "ui_icon_controls.png"))

    # 4. Display Gothic Windowpane (16x16)
    idisp = PixelCanvas(16, 16)
    idisp.rect(3, 3, 10, 10, "T0")
    idisp.rect(4, 4, 8, 8, "U2")
    idisp.line(4, 4, 7, 7, "W5")
    idisp.line(8, 3, 8, 12, "T1")
    idisp.line(3, 8, 12, 8, "T1")
    idisp.rect_outline(3, 3, 10, 10, "Y1")
    idisp.pset(4, 4, "Y3")
    idisp.add_outline("K", selective_hue=True)
    idisp.save_png(os.path.join(sprites_dir, "ui_icon_display.png"))

    # 5. Dialogue Feather Quill (16x16)
    iq = PixelCanvas(16, 16)
    iq.line(3, 13, 12, 3, "L1")
    iq.line(4, 12, 13, 4, "L0")
    iq.line(5, 9, 11, 3, "Y2")
    iq.rect(3, 12, 2, 2, "Y3")
    iq.line(6, 13, 13, 13, "T2")
    iq.add_outline("K", selective_hue=True)
    iq.save_png(os.path.join(sprites_dir, "ui_icon_quill.png"))

    # 6. Mute / Unmute Bells (16x16)
    for muted, fname in ((False, "ui_icon_unmute.png"), (True, "ui_icon_mute.png")):
        im = PixelCanvas(16, 16)
        col_hi, col_mid, col_lo = (("C2", "C1", "C0") if muted else ("Y3", "Y2", "Y0"))
        im.ellipse(8, 8, 3.6, 4.2, col_mid)
        im.rect(4, 10, 8, 2, col_lo)
        im.line(6, 5, 9, 5, col_hi)
        im.pset(8, 13, col_hi)
        im.pset(8, 3, col_lo)
        if muted:
            im.line(3, 12, 12, 3, "I1")
            im.line(4, 12, 12, 4, "I2")
        im.add_outline("K", selective_hue=True)
        im.save_png(os.path.join(sprites_dir, fname))


def _make_settings_widgets(sprites_dir: str) -> None:
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_card_row_9slice.png"), 24,
        (32, 27, 36, 232), (24, 20, 28, 232),
        (18, 15, 22, 255), (86, 70, 48, 210), (118, 96, 66, 180), PAL["Y1"],
    )
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_tab_active_9slice.png"), 24,
        (68, 52, 34, 250), (46, 36, 26, 250),
        PAL["K"], PAL["Y2"], PAL["Y3"], PAL["Y3"], chamfer=True, bottom_open=True,
    )
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_tab_inactive_9slice.png"), 24,
        (28, 25, 32, 235), (20, 18, 24, 235),
        PAL["K"], (78, 66, 52, 210), (96, 84, 66, 180), PAL["Y0"], chamfer=True, bottom_open=False,
    )
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_pill_on_9slice.png"), 24,
        (38, 78, 52, 248), (24, 52, 36, 248),
        PAL["K"], PAL["E2"], PAL["E3"], PAL["Y3"],
    )
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_pill_off_9slice.png"), 24,
        (76, 36, 34, 248), (52, 24, 24, 248),
        PAL["K"], PAL["R2"], PAL["I2"], PAL["Y1"],
    )
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_keycap_9slice.png"), 24,
        (56, 46, 34, 248), (38, 30, 24, 248),
        PAL["K"], PAL["Y1"], PAL["Y2"], PAL["Y3"],
    )
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_keycap_capture_9slice.png"), 24,
        (110, 78, 30, 255), (76, 52, 18, 255),
        PAL["K"], PAL["Y3"], PAL["L0"], PAL["L0"],
    )

    # Ornate Horizontal Filigree Divider (64x10)
    dv = PixelCanvas(64, 10)
    dv.line(3, 5, 60, 5, "T0")
    dv.line(4, 4, 59, 4, "Y0")
    dv.line(12, 4, 51, 4, "Y1")
    for dy in range(-3, 4):
        hw = 3 - abs(dy)
        dv.rect(32 - hw, 4 + dy, hw * 2 + 1, 1, "Y1" if abs(dy) > 1 else "Y2")
    dv.rect(31, 3, 3, 3, "E1")
    dv.pset(32, 4, "Y3")
    dv.pset(6, 4, "Y2")
    dv.pset(57, 4, "Y2")
    dv.save_png(os.path.join(sprites_dir, "ui_divider_ornate.png"))

    # Custom HSlider Rail (24x12, 9-slice margin 4)
    sr = PixelCanvas(24, 12)
    sr.rect(1, 3, 22, 6, "K")
    sr.rect(2, 4, 20, 4, "N")
    sr.line(2, 4, 21, 4, "T0")
    sr.rect_outline(0, 2, 24, 8, "T0")
    sr.rect(1, 3, 2, 6, "Y0")
    sr.rect(21, 3, 2, 6, "Y0")
    sr.pset(1, 4, "Y2")
    sr.pset(22, 4, "Y2")
    sr.save_png(os.path.join(sprites_dir, "ui_slider_rail.png"))

    # Custom HSlider Illuminated Gold Fill (24x12, 9-slice margin 4)
    sf = PixelCanvas(24, 12)
    sf.rect(1, 4, 22, 4, "Y1")
    sf.line(2, 4, 21, 4, "Y3")
    sf.line(2, 7, 21, 7, "Y0")
    sf.save_png(os.path.join(sprites_dir, "ui_slider_fill.png"))

    # Custom Brass & Emerald Diamond Grabber (14x18)
    for hi, fname in ((False, "ui_slider_grabber.png"), (True, "ui_slider_grabber_hi.png")):
        sg = PixelCanvas(14, 18)
        cx, cy = 7, 9
        for dy in range(-6, 7):
            hw = max(0, 5 - abs(dy) * 5 // 6)
            sg.rect(cx - hw, cy + dy, hw * 2 + 1, 1, "Y2" if hi else "Y1")
            if dy < 0:
                sg.pset(cx - hw, cy + dy, "L0" if hi else "Y3")
        sg.rect(cx - 2, cy - 2, 5, 5, "E2" if hi else "E1")
        sg.pset(cx, cy, "Y3" if hi else "E3")
        sg.pset(cx - 1, cy - 1, "L0")
        sg.add_outline("K", selective_hue=True)
        sg.save_png(os.path.join(sprites_dir, fname))

    # Stylized Scrollbar Rail & Brass Grabber (14x24)
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_scroll_rail_9slice.png"), 16,
        (16, 15, 20, 230), (16, 15, 20, 230),
        PAL["K"], (52, 44, 34, 200), (62, 52, 40, 160), PAL["Y0"], chamfer=False,
    )
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_scroll_grabber_9slice.png"), 16,
        (132, 102, 52, 245), (96, 72, 36, 245),
        PAL["K"], PAL["Y2"], PAL["Y3"], PAL["L0"], chamfer=True,
    )


def _make_title_diorama_art(sprites_dir: str) -> None:
    """
    Handcrafted Zelda-inspired Title Screen layered diorama sprites:
      - title_bg_sky.png (320x180): twilight-to-dawn horizon, still Zwin estuary reflection & muted Bruges Belfry
      - title_clouds_ribbon.png (320x72): slow-drifting translucent cirrus mist wisps (tileable across X)
      - title_fg_cliff.png (320x180): tranquil left mossy headland with hooded Boy + glowing Egg/lantern silhouette
      - title_hatchling_roost_0/1.png (28x24): gently breathing soot-and-gold Dragonet perched beside the Boy
      - title_crest_emblem.png (96x40): Brotherhood Twin-Wing Prophecy Crest above title typography
      - title_virelai_sky_0/1.png (36x18): tiny distant soaring emerald dragon silhouette for rare sky passes
      - title_menu_cursor.png (16x12): pointed luminous gold wing-tip menu selector
    """
    # 1. Atmospheric Flanders Twilight-Dawn Vista (320x180)
    sky = PixelCanvas(320, 180)
    c_zenith = (13, 19, 34, 255)
    c_mid_sky = (31, 45, 72, 255)
    c_rose = (108, 72, 74, 255)
    c_dawn = (212, 154, 92, 255)
    c_water_top = (36, 48, 66, 255)
    c_water_bot = (14, 20, 32, 255)

    for y in range(180):
        if y < 62:
            col = blend_color(c_zenith, c_mid_sky, y / 61.0)
        elif y < 94:
            col = blend_color(c_mid_sky, c_rose, (y - 62) / 31.0)
        elif y <= 112:
            col = blend_color(c_rose, c_dawn, (y - 94) / 18.0)
        else:
            col = blend_color(c_water_top, c_water_bot, (y - 112) / 67.0)
        for x in range(320):
            # Soft warm solar glow centered slightly right of center (x~198, y~108)
            glow_d = math.hypot((x - 198) * 0.65, y - 106)
            c_out = col
            if glow_d < 68.0 and y <= 112:
                g_t = ((68.0 - glow_d) / 68.0) ** 2.0 * 0.48
                c_out = blend_color(col, (244, 208, 128, 255), g_t)
            sky.pset(x, y, c_out)

    # Sparse calm pinpoint stars in upper twilight third (minimalist, never noisy)
    stars = (
        (26, 14, 1), (68, 22, 0), (112, 11, 0), (154, 19, 1), (218, 12, 0),
        (266, 24, 1), (296, 15, 0), (48, 36, 0), (242, 34, 0), (288, 38, 0),
    )
    for sx, sy, bright in stars:
        sky.pset(sx, sy, (238, 226, 188, 210 if bright else 135))
        if bright:
            sky.pset(sx + 1, sy, (186, 194, 214, 110))
            sky.pset(sx - 1, sy, (186, 194, 214, 110))

    # Rising sunlit dawn halo peeking above far horizon ridge (x=198, y=108)
    for y in range(96, 113):
        for x in range(184, 213):
            if math.hypot(x - 198, y - 109) <= 9.5:
                sky.pset(x, y, blend_color((242, 196, 116, 255), (255, 236, 174, 255), (112 - y) / 16.0))

    # Distant muted Flanders pine-hills along horizon (y=102..113)
    for x in range(320):
        hill_h = 3 + int(3.0 * math.sin(x * 0.025) + 2.0 * math.cos(x * 0.068))
        if 175 <= x <= 268:
            hill_h += 1
        ridge_y = 111 - max(1, hill_h)
        h_col = (24, 30, 44, 255)
        for y in range(ridge_y, 113):
            sky.pset(x, y, h_col if y > ridge_y else (38, 46, 64, 255))

    # Distant sculpted Bruges Belfry & Gothic Stepped-Gable Hall across right water (x=218..268)
    sil_dark = (21, 25, 38, 255)
    sil_mid = (28, 34, 52, 255)
    sil_rim = (84, 74, 82, 255)
    # Side stepped gables flanking central Belfry Hall (y=99..112)
    sky.rect(222, 102, 38, 10, sil_dark)
    # Left & Right Flemish stepped gable wings + corner pinnacle spirelets
    for gx, dir_s in ((222, 1), (259, -1)):
        for st in range(5):
            sky.rect(gx if dir_s > 0 else gx - 6 + st, 102 - st, 7 - st, 1, sil_dark)
        sky.line(gx, 96, gx, 103, sil_dark)
        sky.pset(gx, 95, sil_rim)
    # Rooftop ridge glint along main hall
    sky.line(224, 102, 257, 102, sil_rim)
    # Belfry base tower (x=236..246) & octagonal lantern crown (y=75..88) + needle spire (y=67..75)
    sky.rect(236, 86, 10, 17, sil_dark)
    sky.line(236, 86, 236, 101, sil_rim)
    sky.rect(237, 81, 8, 6, sil_mid)
    sky.rect(238, 76, 6, 6, sil_dark)
    sky.line(238, 76, 238, 84, sil_rim)
    for sy in range(67, 77):
        hw = max(0, (sy - 68) // 3)
        sky.rect(240 - hw, sy, hw * 2 + 1, 1, sil_dark)
    sky.pset(240, 66, sil_rim)
    sky.pset(241, 89, "Y2")
    sky.pset(241, 95, "Y1")
    sky.pset(230, 106, "Y0")
    sky.pset(251, 106, "Y0")

    # Subtle mirrored reflection of the dark Belfry & water horizon shimmer
    for y in range(114, 168):
        spread = 8 + (y - 114) * 0.35
        if y % 3 != 0:
            for x in range(int(198 - spread), int(198 + spread)):
                wave = math.sin(x * 0.28 + y * 0.9)
                if wave > 0.25:
                    fade = 1.0 - (y - 114) / 60.0
                    alpha = int(175 * max(0.0, fade) * (wave - 0.15))
                    sky.pset(x, y, (240, 188, 102, alpha))

    sky.save_png(os.path.join(sprites_dir, "title_bg_sky.png"))

    # 2. Stepped Pixel-Art Translucent Cirrus & Dusk Mist Clouds (320x72)
    cl = PixelCanvas(320, 72)
    puff_banks = [
        [(36, 24, 14, 4), (48, 22, 16, 5), (62, 24, 12, 3)],
        [(136, 18, 16, 4), (150, 16, 18, 5), (165, 18, 14, 3)],
        [(244, 28, 12, 3), (256, 26, 16, 4), (270, 28, 10, 3)],
        [(84, 46, 14, 3), (98, 45, 16, 3), (200, 42, 18, 3), (214, 43, 12, 2)],
    ]
    for bank in puff_banks:
        for cx, cy, rx, ry in bank:
            for dx in range(-rx, rx + 1):
                wx = (cx + dx) % 320
                u = abs(dx) / max(1.0, float(rx))
                h = max(1, int(round((1.0 - u * u) * ry)))
                for dy in range(-h, h // 2 + 1):
                    py = cy + dy
                    if 2 <= py < 68:
                        if dy <= -h + 1:
                            col = (218, 174, 134, 72)
                        elif dy <= 0:
                            col = (168, 132, 126, 58)
                        else:
                            col = (94, 80, 102, 46)
                        cl.pset(wx, py, col)
    cl.save_png(os.path.join(sprites_dir, "title_clouds_ribbon.png"))

    # 3. Calm Foreground Moss Headland + Sculpted Cloaked Boy + Prophecy Egg + Warm Lantern (320x180)
    fg = PixelCanvas(320, 180)
    # Plateau stretches to x=112 cleanly for Boy/Egg/Hatchling perch, then curves gently to water!
    for x in range(0, 158):
        slope = 0 if x < 112 else int(((x - 112) / 46.0) ** 1.35 * 60)
        wave_y = int(math.sin(x * 0.09) * 1.2) if x < 42 else (0 if x < 112 else int(math.cos(x * 0.12)))
        top_y = 122 + slope + wave_y
        for y in range(top_y, 180):
            if y <= top_y + 2:
                col = "G2" if y == top_y and x < 116 else "G1"
            elif y == top_y + 3 or (y <= top_y + 6 and (x + y) % 5 == 0):
                col = "G0"
            elif y <= top_y + 18:
                # Natural diagonal sedimentary cliff strata with organic crack crevices
                strata = (x // 4 + y * 2) % 9
                if strata == 0 and (x + y) % 5 != 0:
                    col = "C0"
                elif y <= top_y + 8 and ((x + y) % 6 != 0):
                    col = "C1"
                else:
                    col = "S"
            else:
                # Quiet shadowed granite depth fading seamlessly downward without grid blocks
                seam = ((x * 2 + y * 5) % 19 == 0)
                col = (14, 16, 23, 255) if y > 152 else ((25, 27, 36, 255) if seam else (18, 20, 28, 255))
            if y == top_y and 26 <= x <= 122:
                col = blend_color(PAL.get(col, (72, 102, 49, 255)), (236, 194, 112, 255), 0.34 if x % 3 != 0 else 0.14)
            fg.pset(x, y, col)

    # Gentle swaying grass blades & tiny clover highlights on ledge
    for gx, gh in ((18, 5), (28, 4), (37, 6), (80, 4), (108, 5), (116, 4)):
        fg.line(gx, 122 - gh, gx - 1, 122, "G1")
        fg.pset(gx, 122 - gh, "Y1" if gx >= 78 else "G2")

    # Soft misty reed bank at far lower-right corner
    for x in range(264, 320):
        top_y = 179 - int(((x - 264) / 56.0) ** 1.25 * 34)
        for y in range(top_y, 180):
            fg.pset(x, y, (14, 17, 24, 255))
    for rx, rtop in ((285, 134), (294, 126), (304, 136), (313, 124)):
        fg.line(rx, 158, rx + 1, rtop, "G0")
        fg.rect(rx, rtop + 1, 2, 4, "T1")
        fg.pset(rx + 1, rtop + 1, "Y1")

    # Small warm wrought-iron road lantern perched at (42, 104..122)
    fg.rect(42, 111, 2, 11, "K")
    fg.rect(40, 104, 6, 7, "O0")
    fg.line(39, 104, 46, 104, "C1")
    fg.rect(41, 105, 4, 5, "Y1")
    fg.rect(42, 106, 2, 3, "Y3")
    for dx in range(-8, 9):
        for dy in range(-2, 3):
            if dx * dx * 0.22 + dy * dy <= 9:
                a = max(0, int(92 - math.hypot(dx, dy * 2) * 10))
                fg.pset(43 + dx, 122 + dy, (244, 188, 94, a))

    # Organic Sculpted Hooded Traveler Boy Silhouette (aged ~17) seated calmly at (50..69, y=97..122)
    # Softly draped cloak shoulder, trailing back hem over moss, folded seated knees forward right!
    for y in range(103, 123):
        frac = (y - 103) / 19.0
        # Back curves gracefully leftward; chest tapers cleanly from neck down to knee fold (x=68..70)
        x0 = int(53 - (frac ** 0.85) * 6)
        x1 = int(63 + math.sin(min(1.0, frac * 1.45) * math.pi * 0.5) * 6)
        if y >= 117:
            x1 += 1  # tucked boot / hem resting forward on grass
        for x in range(x0, x1):
            col = "E1"
            if x >= x1 - 2 and y < 118:
                col = blend_color(PAL["E2"], (236, 184, 104, 255), 0.36)  # warm dawn chest rim
            elif x <= x0 + 2:
                col = "DE" if x == x0 else "E0"
            elif y >= 112 and x == x0 + 6:
                col = "E0"  # natural vertical cloak fold crease
            elif y == 104 and x <= 62:
                col = "E0"  # draped hood collar fold
            fg.pset(x, y, col)
    # Thrown-back hood collar around nape + wind-ruffled chestnut head + warm profile face
    fg.ellipse(57, 103, 4.0, 2.2, "E0")
    fg.ellipse(60, 99, 3.8, 3.8, "B0")
    fg.ellipse(59, 98, 3.0, 2.8, "B1")
    fg.line(58, 96, 62, 96, "B2")     # sunlit chestnut hair lock
    fg.rect(62, 98, 2, 3, "P2")       # warm profile nose/cheek toward dawn & dragon
    fg.pset(63, 99, "P3")
    fg.line(61, 101, 63, 102, "P0")   # chin neck shadow

    # Resting hand & Cracked Black-and-Gold Eggshell Fragment between Boy and Dragon (x=72..78, y=117..122)
    fg.line(64, 111, 69, 115, "E2")
    fg.rect(68, 115, 2, 2, "P1")
    fg.ellipse(76, 119, 3.2, 2.6, "O0")
    fg.ellipse(76, 119, 2.3, 1.8, "O1")
    fg.line(74, 118, 78, 119, "Y2")
    fg.pset(77, 117, "Y3")

    fg.save_png(os.path.join(sprites_dir, "title_fg_cliff.png"))

    # 4. Perched Animated Stage-1 Golden Hatchling Silhouette on Cliff Plateau (28x24, 2 breathing/wing frames)
    for frame in (0, 1):
        hr = PixelCanvas(28, 24)
        lift = -1 if frame == 1 else 0
        # Soft flush contact shadow right under paws (y=20)
        hr.ellipse(13, 20, 5.2, 1.5, (14, 18, 16, 110))
        tail_tip_y = 14 if frame == 1 else 16
        hr.line(16, 17, 21, 18, "O0")
        hr.line(21, 18, 24, tail_tip_y, "O2")
        hr.pset(24, tail_tip_y, "Y2")
        # Raised silhouette wing catching dawn backlight (wing edge rimmed bright gold)
        for i in range(9):
            wx = 13 + i
            top_y = 7 + lift - (i // 3)
            bot_y = 15 + lift - (i // 4)
            for wy in range(top_y, bot_y + 1):
                hr.pset(wx, wy, "Y1" if wy == top_y else ("O2" if wy == top_y + 1 else "O0"))
        hr.line(13, 7 + lift, 21, 5 + lift, "Y3")
        hr.ellipse(13, 16, 4.0, 3.8, "O0")
        hr.ellipse(13, 16, 3.0, 2.8, "O1")
        hr.pset(11, 15, "Y2")
        hr.pset(12, 16, "Y3")
        hr.pset(13, 17, "Y2")
        # Crisp seated little claws
        hr.rect(10, 19, 2, 2, "O2")
        hr.rect(14, 19, 2, 2, "O2")
        # Raised attentive dragonet head facing LEFT
        hr.ellipse(10, 10, 3.5, 3.1, "O0")
        hr.ellipse(10, 10, 2.7, 2.3, "O1")
        hr.rect(5, 9, 4, 3, "O1")
        hr.line(6, 9, 9, 9, "Y2")
        hr.line(11, 7, 14, 4, "C3")
        hr.pset(14, 4, "Y2")
        hr.rect(8, 9, 2, 2, "Y2")
        hr.pset(8, 9, "Y3")
        hr.add_outline("DO", selective_hue=True)
        hr.save_png(os.path.join(sprites_dir, f"title_hatchling_roost_{frame}.png"))

    # 5. Ornamental Brotherhood Wing Prophecy Crest Banner Topper (96x40)
    cr = PixelCanvas(96, 40)
    cx_cr, cy_cr = 48, 20
    # Swept symmetrical gold filigree dragon wings flaring cleanly left & right
    for sign in (-1, 1):
        for s in range(4, 44):
            u = (s - 4) / 39.0
            wx = cx_cr + sign * s
            top_y = int(round(cy_cr - math.sin(u * 1.15) * 14 - u * 4))
            scallop = math.sin(u * math.pi * 3.0) * 3.2
            bot_y = int(round(cy_cr + 5 - u * 9 + scallop))
            for wy in range(top_y, bot_y + 1):
                if wy == top_y:
                    col = "L0" if s < 32 else "Y3"
                elif wy == top_y + 1:
                    col = "Y3"
                elif wy >= bot_y:
                    col = "Y0"
                else:
                    col = "Y2" if (s + wy) % 4 else "Y1"
                cr.pset(wx, wy, col)
        # Wing finger spar lines
        cr.line(cx_cr + sign * 8, cy_cr + 1, cx_cr + sign * 24, cy_cr - 7, "L0")
        cr.line(cx_cr + sign * 8, cy_cr + 3, cx_cr + sign * 33, cy_cr - 3, "Y3")
    # Central Emerald Heraldic Medallion cradling the Black-and-Gold Prophecy Egg
    cr.ellipse(cx_cr, cy_cr + 1, 10.5, 11.5, "Y0")
    cr.ellipse(cx_cr, cy_cr + 1, 9.2, 10.2, "Y2")
    cr.ellipse(cx_cr, cy_cr + 1, 7.6, 8.6, "E0")
    cr.ellipse(cx_cr, cy_cr, 6.4, 7.2, "E1")
    # Miniature Black-and-Gold Cracked Egg silhouette inside emerald crest!
    cr.ellipse(cx_cr, cy_cr + 1, 4.2, 5.4, "O0")
    cr.ellipse(cx_cr, cy_cr + 1, 3.2, 4.4, "O1")
    cr.line(cx_cr - 2, cy_cr, cx_cr, cy_cr + 2, "Y3")
    cr.line(cx_cr, cy_cr + 2, cx_cr + 2, cy_cr - 1, "Y2")
    cr.pset(cx_cr + 1, cy_cr - 2, "L0")
    cr.pset(cx_cr, cy_cr - 9, "Y3")
    cr.pset(cx_cr, cy_cr + 11, "Y3")
    cr.add_outline("K", selective_hue=True)
    cr.save_png(os.path.join(sprites_dir, "title_crest_emblem.png"))

    # 6. Distant Soaring Dragon Silhouette for Rare High Sky Pass (36x18, 2 glide frames)
    for frame in (0, 1):
        vd = PixelCanvas(36, 18)
        col_sil = (28, 44, 42, 225)
        col_rim = (196, 162, 104, 190)
        flap = -3 if frame == 1 else 2
        # Graceful swept-back wings + slender dragon body facing right
        vd.line(6, 9, 25, 9, col_sil)
        vd.line(12, 8, 23, 8, col_sil)
        vd.line(24, 9, 29, 8, col_sil)  # head & neck
        vd.line(6, 9, 2, 10 + (1 if frame == 0 else -1), col_sil)  # long whip tail
        for i in range(1, 9):
            wy = 8 + int((i / 8.0) * (flap - 5))
            vd.line(16 - i // 2, 8, 13 - i // 2, wy, col_sil)
            vd.line(17 - i // 2, 9, 15 - i // 2, 10 + abs(flap) // 2 + i // 3, (18, 30, 32, 210))
        vd.pset(28, 8, col_rim)
        vd.save_png(os.path.join(sprites_dir, f"title_virelai_sky_{frame}.png"))

    # 7. Crisp Golden Wing-Tip Menu Selection Cursor (16x12)
    mc = PixelCanvas(16, 12)
    for x in range(2, 14):
        frac = (x - 2) / 11.0
        half = max(0, int((1.0 - frac) * 4.2))
        for y in range(6 - half, 6 + half + 1):
            col = "L0" if y == 6 - half else ("Y3" if y <= 6 else "Y1")
            mc.pset(x, y, col)
    mc.line(3, 5, 11, 5, "L0")
    mc.add_outline("K", selective_hue=True)
    mc.save_png(os.path.join(sprites_dir, "title_menu_cursor.png"))


def _make_dialogue_chrome(sprites_dir: str) -> None:
    """
    Handcrafted Medieval Dialogue & Ethereal Dreamy Mind-Voice 9-slice Chrome:
      - ui_dialogue_9slice.png (32x32): Warm aged walnut & brass-edged vellum dialogue scroll
      - ui_dialogue_portrait_9slice.png (24x24): Carved oak & antique brass cameo portrait bezel
      - ui_mind_dialogue_9slice.png (32x32): Dreamy twilight-indigo & luminous gold-pearl aura frame
      - ui_mind_portrait_9slice.png (24x24): Ethereal radiant gold-and-starlight cameo frame
    """
    # 1. Standard Stylized Medieval Dialogue Box (32x32, margin 10)
    db = PixelCanvas(32, 32)
    for y in range(2, 30):
        t = (y - 2) / 27.0
        col = blend_color((32, 26, 36, 240), (19, 16, 23, 246), t)
        for x in range(2, 30):
            db.pset(x, y, col)
    db.rect_outline(0, 0, 32, 32, (16, 13, 20, 255))
    db.rect_outline(1, 1, 30, 30, PAL["Y0"])
    db.rect_outline(2, 2, 28, 28, PAL["Y1"])
    db.line(3, 2, 28, 2, PAL["Y2"])
    db.line(2, 3, 2, 28, PAL["Y2"])
    db.rect_outline(4, 4, 24, 24, (72, 58, 42, 160))
    for cx, cy in ((0, 0), (31, 0), (0, 31), (31, 31)):
        db.pset(cx, cy, ".")
    for sx, sy in ((3, 3), (28, 3), (3, 28), (28, 28)):
        db.rect(sx - 1, sy - 1, 3, 3, PAL["Y2"])
        db.pset(sx, sy, PAL["L0"])
    db.pset(16, 2, PAL["Y3"])
    db.pset(16, 29, PAL["Y3"])
    db.save_png(os.path.join(sprites_dir, "ui_dialogue_9slice.png"))

    # 2. Standard Portrait Bezel (24x24)
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_dialogue_portrait_9slice.png"), 24,
        (24, 20, 28, 250), (16, 14, 20, 252),
        PAL["K"], PAL["Y1"], PAL["Y3"], PAL["L0"],
    )

    # 3. Dreamy Dragonet Mind-Voice 9-slice Frame (32x32, margin 10)
    mb = PixelCanvas(32, 32)
    for y in range(2, 30):
        t = (y - 2) / 27.0
        col = blend_color((36, 30, 68, 224), (20, 21, 46, 234), t)
        for x in range(2, 30):
            dx = abs(x - 15.5) / 14.0
            dy = abs(y - 15.5) / 14.0
            halo = max(0.0, 1.0 - (dx * dx + dy * dy)) * 0.20
            mb.pset(x, y, blend_color(col, (148, 128, 212, 228), halo))
    # Soft outer twilight veil + iridescent gold-and-starlight filigree border
    mb.rect_outline(0, 0, 32, 32, (28, 24, 52, 215))
    mb.rect_outline(1, 1, 30, 30, (222, 186, 98, 240))
    mb.rect_outline(2, 2, 28, 28, (248, 224, 148, 225))
    mb.rect_outline(4, 4, 24, 24, (170, 162, 228, 130))
    for cx, cy in ((0, 0), (1, 0), (0, 1), (31, 0), (30, 0), (31, 1), (0, 31), (1, 31), (0, 30), (31, 31), (30, 31), (31, 30)):
        mb.pset(cx, cy, ".")
    for sx, sy in ((3, 3), (28, 3), (3, 28), (28, 28)):
        mb.pset(sx, sy, PAL["L0"])
        mb.pset(sx - 1 if sx < 16 else sx + 1, sy, (206, 198, 248, 210))
        mb.pset(sx, sy - 1 if sy < 16 else sy + 1, (206, 198, 248, 210))
    mb.pset(15, 2, PAL["L0"])
    mb.pset(16, 2, PAL["L0"])
    mb.pset(15, 29, PAL["L0"])
    mb.pset(16, 29, PAL["L0"])
    mb.save_png(os.path.join(sprites_dir, "ui_mind_dialogue_9slice.png"))

    # 4. Dreamy Mind-Voice Portrait Bezel (24x24)
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_mind_portrait_9slice.png"), 24,
        (36, 32, 66, 245), (22, 20, 44, 248),
        (46, 38, 86, 235), (242, 210, 118, 250), PAL["L0"], (208, 198, 248, 240),
    )


def _make_zelda_hud_art(sprites_dir: str) -> None:
    # 1. Zelda-style Crimson Heart Full (16x16) & Hollow Socket Empty (16x16)
    heart_mask = [
        "....KKKK.KKKK...",
        "...KRRRKKRRRK...",
        "..KRRRRRKRRRRK..",
        ".KRRLLRRRRRRRRK.",
        ".KRLRRRRRRRRRRK.",
        ".KRRRRRRRRRRRRK.",
        ".KRRRRRRRRRRRRK.",
        "..KRRRRRRRRRRK..",
        "...KRRRRRRRRK...",
        "....KRRRRRRK....",
        ".....KRRRRK.....",
        "......KRRK......",
        ".......KK.......",
    ]
    hf = PixelCanvas(16, 16)
    he = PixelCanvas(16, 16)
    for row_i, row in enumerate(heart_mask):
        y = row_i + 1
        for x, ch in enumerate(row):
            if ch == "K":
                hf.pset(x, y, "K")
                he.pset(x, y, (28, 24, 30, 235))
            elif ch == "L":
                hf.pset(x, y, "L0")
                he.pset(x, y, (68, 60, 66, 185))
            elif ch == "R":
                if y >= 9 or x >= 11:
                    hf.pset(x, y, "I1")
                elif y >= 6 or x >= 9:
                    hf.pset(x, y, "I2")
                else:
                    hf.pset(x, y, (224, 48, 58, 255))
                he.pset(x, y, (34, 30, 38, 170) if y < 8 else (24, 20, 28, 180))
    # Bright Zelda crimson sheen & soft bottom shadow rim on full heart
    for sx, sy in [(6, 10), (7, 11), (8, 11), (9, 10), (10, 9), (11, 8)]:
        hf.pset(sx, sy, "I0")
    hf.pset(4, 4, (255, 224, 224, 255))
    hf.pset(3, 5, (248, 130, 136, 255))
    hf.pset(10, 4, (238, 86, 94, 255))
    he.pset(4, 4, (86, 76, 82, 160))
    hf.save_png(os.path.join(sprites_dir, "icon_heart_full.png"))
    he.save_png(os.path.join(sprites_dir, "icon_heart_empty.png"))

    # 2. Compact Zelda Action Slot 9-slice Frame (24x24, margin 6)
    _make_9slice_box(
        os.path.join(sprites_dir, "ui_zelda_slot_9slice.png"), 24,
        (24, 20, 27, 232), (14, 12, 17, 240),
        (16, 13, 18, 255), PAL["Y0"], PAL["Y2"], PAL["L0"],
    )


def make_extra_ui_and_title_art(sprites_dir: str) -> None:
    _make_settings_icons(sprites_dir)
    _make_settings_widgets(sprites_dir)
    _make_title_diorama_art(sprites_dir)
    _make_dialogue_chrome(sprites_dir)
    _make_zelda_hud_art(sprites_dir)
