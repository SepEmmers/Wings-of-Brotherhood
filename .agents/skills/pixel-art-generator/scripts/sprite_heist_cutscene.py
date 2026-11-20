"""
Hand-Pixelled Dialogue-Free Midnight Sanctuary Heist & Kestrel Escape Diorama
for Book I Chapter 4 -> Book II Transition.

Outputs crisp nearest-neighbor 320x180 diorama & layered sprite animations:
  - cs_heist_bg.png (320x180): Sanctuary cliffside vault arch, brazier apron & abyss parapet at midnight
  - cs_heist_pedestal_0..1.png (56x64): Brass tripod brazier holding the glowing obsidian egg -> smoking empty coals
  - cs_heist_torch_0..3.png (28x44): Wind-whipped midnight iron wall torch flames
  - cs_heist_sentry_0..1.png (60x80): Two Brotherhood Night-Watchmen lunging from arch with storm-lanterns & spears
  - cs_heist_boy_0..2.png (80x96): 17yo Boy lifting the egg -> tucking into cloak bundle -> vaulting aboard
  - cs_heist_kestrel_0..2.png (140x120): Mute Silver-Slate Kestrel wing-ramp -> mounted brace -> chasm launch
  - cs_heist_sky_bg.png (320x180): High-altitude midnight storm clouds & receding Sanctuary headland fires
  - cs_heist_fly_0..3.png (128x88): Kestrel 4-frame full-profile flight carrying Boy & hidden glowing egg east
"""

import math
import os
from pixel_art_lib import PAL, PixelCanvas, blend_color


def _qbezier(p0, p1, p2, steps: int = 36):
    pts = []
    for i in range(steps + 1):
        t = i / float(steps)
        mt = 1.0 - t
        x = mt * mt * p0[0] + 2.0 * mt * t * p1[0] + t * t * p2[0]
        y = mt * mt * p0[1] + 2.0 * mt * t * p1[1] + t * t * p2[1]
        pts.append((int(round(x)), int(round(y))))
    return pts


def _draw_poly(c: PixelCanvas, pts, col, thickness: int = 1) -> None:
    for i in range(len(pts) - 1):
        c.line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], col, thickness=thickness)


def _bayer4(x: int, y: int) -> float:
    m = (
        (0, 8, 2, 10),
        (12, 4, 14, 6),
        (3, 11, 1, 9),
        (15, 7, 13, 5),
    )
    return (m[y & 3][x & 3] + 0.5) / 16.0


def _paint_billowy_cloud(canvas: PixelCanvas, cx: int, cy: int, scale: float, rim_alpha: int = 175) -> None:
    """Organic multi-lobe nocturnal storm cloud painted into a unified silhouette mask (zero internal ellipse seams)."""
    lobes = (
        (-int(22 * scale), 3, 14.0 * scale, 6.5 * scale),
        (-int(7 * scale), -2, 17.0 * scale, 9.0 * scale),
        (int(10 * scale), -1, 16.0 * scale, 8.0 * scale),
        (int(24 * scale), 4, 12.0 * scale, 5.5 * scale),
    )
    half_w = int(38 * scale) + 2
    half_h = int(14 * scale) + 2
    for dy in range(-half_h, half_h + 1):
        for dx in range(-half_w, half_w + 1):
            inside = False
            for lx, ly, rx, ry in lobes:
                u = ((dx - lx) / max(1.0, rx)) ** 2 + ((dy - ly) / max(1.0, ry)) ** 2
                if u <= 1.0:
                    inside = True
                    break
            if not inside:
                continue
            px, py = cx + dx, cy + dy
            if 0 <= px < canvas.w and 0 <= py < canvas.h:
                if dy < -int(3.5 * scale):
                    col = (64, 82, 118, rim_alpha)
                elif dy < int(2.5 * scale):
                    col = (42, 56, 86, rim_alpha)
                else:
                    col = (25, 35, 56, rim_alpha)
                canvas.pset(px, py, col)


def _draw_obsidian_egg_oval(c: PixelCanvas, cx: int, cy: int, rx: int = 11, ry: int = 14) -> None:
    """Crisp miniature Black-and-Gold Egg matching Book I prop continuity."""
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            ny = (y - cy) / float(ry)
            taper = 1.0 - max(0.0, -ny) * 0.24
            nx = (x - cx) / max(1.0, float(rx) * taper)
            r2 = nx * nx + ny * ny
            if r2 > 1.0:
                continue
            if r2 > 0.84:
                col = PAL["DO"]
            elif (-nx * 0.5 - ny * 0.6) > 0.35:
                col = PAL["O3"]
            elif (x + y * 2) % 7 == 0:
                col = PAL["O2"]
            else:
                col = PAL["O1"]
            c.pset(x, y, col)
    for px, py in _qbezier((cx - 5, cy + 2), (cx, cy - 2), (cx + 6, cy + 5), 16):
        c.pset(px, py, "Y2")
    for px, py in _qbezier((cx - 2, cy - 8), (cx - 1, cy), (cx + 2, cy + 9), 16):
        c.pset(px, py, "Y1" if py % 2 == 0 else "Y3")


def _make_heist_bg(sprites_dir: str) -> None:
    bg = PixelCanvas(320, 180)
    braz_x, braz_y = 122.0, 136.0
    torch_x, torch_y = 86.0, 56.0

    # 1. Midnight Cliff-Coast Sky & Bruges Bay Far Below Right
    c_zen = (11, 15, 29, 255)
    c_mid = (20, 29, 48, 255)
    c_hor = (32, 46, 72, 255)
    for y in range(180):
        for x in range(320):
            if y < 60:
                col = blend_color(c_zen, c_mid, y / 59.0)
            elif y < 126:
                col = blend_color(c_mid, c_hor, (y - 60) / 65.0)
            else:
                col = (13, 21, 33, 255)
            bg.pset(x, y, col)

    for sx, sy, br in ((204, 18, 1), (242, 26, 0), (278, 16, 1), (304, 34, 0), (222, 42, 0), (156, 22, 0)):
        bg.pset(sx, sy, (238, 232, 206, 200 if br else 120))
    _paint_billowy_cloud(bg, 224, 36, 0.85, 145)
    _paint_billowy_cloud(bg, 286, 50, 0.90, 135)

    # Distant dark sea-cliff headlands & calm moonlit bay waves in lower-right chasm
    for x in range(180, 320):
        hill_y = 92 + int(math.sin(x * 0.04) * 4 + math.cos(x * 0.09) * 3)
        for y in range(hill_y, 126):
            bg.pset(x, y, (18, 26, 36, 255))
    for y in range(126, 180):
        for x in range(210, 320):
            bg.pset(x, y, PAL["W0"] if y < 146 else (12, 22, 34, 255))
    for rx, ry, rw in ((264, 132, 6), (292, 136, 8), (274, 144, 5), (300, 152, 7), (268, 164, 6), (288, 171, 5)):
        bg.line(rx, ry, rx + rw, ry, PAL["W2"] if ry > 155 else PAL["W3"])

    # 2. Massive Cliffside Vault Masonry & Left Sentinel Archway (`x=0..186, y=24..128`)
    for y in range(22, 130):
        for x in range(0, 188):
            top_line = 26 if x < 110 else (34 + int((x - 110) * 0.42))
            if y < top_line:
                continue
            arch_u = ((x - 46.0) / 34.0) ** 2 + ((max(0.0, 124.0 - y)) / 56.0) ** 2
            if y > 64 and arch_u < 1.0:
                col = (14, 15, 22, 255)
                if arch_u > 0.72:
                    col = blend_color(col, (56, 36, 22, 255), 0.35)
                bg.pset(x, y, col)
                continue
            band = y // 12
            seam = (y % 12 == 0) or ((x + (band % 2) * 16) % 32 == 0)
            tone = (band * 3 + (x + (band % 2) * 16) // 32) % 4
            if seam:
                col = (28, 30, 36, 255)
            elif y <= top_line + 3 and (x + y) % 5 < 3:
                col = PAL["G1"]
            elif tone == 0:
                col = PAL["CS"]
            elif tone == 1:
                col = PAL["C0"]
            elif tone == 2:
                col = PAL["C1"]
            else:
                col = (64, 68, 78, 255)
            if abs(arch_u - 1.0) < 0.08 and y > 64:
                col = PAL["C3"]
            dt = math.hypot((x - torch_x) * 0.85, (y - torch_y) * 1.05)
            if dt < 82.0 and not seam:
                tg = ((82.0 - dt) / 82.0) ** 2.0 * 0.56
                col = blend_color(col, PAL["Y1"], tg)
            bg.pset(x, y, col)

    bg.rect(84, 60, 5, 11, "C2")
    bg.rect(82, 57, 9, 4, "S")
    bg.rect(178, 94, 5, 11, "C2")
    bg.rect(176, 91, 9, 4, "S")

    # 3. Courtyard Flagstones & Crumbling Cliff-Edge Parapet Coping (`x=0..280, y=114..180`)
    for y in range(114, 180):
        cliff_cut = int(286 - max(0, y - 122) * 0.32 + math.sin(y * 0.25) * 2.0)
        for x in range(0, min(320, cliff_cut)):
            if y < 124 and x >= 186:
                seam_p = (y % 6 == 0) or ((x + y) % 18 == 0)
                if seam_p:
                    col = PAL["DO"]
                elif y <= 116 and (x % 4 != 0):
                    col = PAL["G1"]
                else:
                    col = PAL["CS2"] if y < 119 else PAL["C1"]
                if x >= cliff_cut - 3:
                    col = PAL["K"]
                bg.pset(x, y, col)
                continue
            if y < 124:
                continue
            sl_row = y // 10
            sl_seam = (y % 10 == 0) or ((x + (sl_row % 2) * 14) % 28 == 0)
            col = (28, 30, 38, 255) if sl_seam else (PAL["C0"] if (x // 28 + sl_row) % 2 == 0 else PAL["CS"])
            if x >= cliff_cut - 4:
                col = PAL["C2"] if x == cliff_cut - 3 else PAL["K"]
            db = math.hypot((x - braz_x) * 0.65, (y - braz_y) * 1.35)
            if db < 130.0 and not sl_seam:
                tg = max(0.0, (130.0 - db) / 130.0) ** 2.2
                if tg * 1.15 > _bayer4(x, y) * 0.26:
                    col = blend_color(col, PAL["Y1"], min(0.68, tg * 0.72))
            if y > 158:
                col = blend_color(col, (10, 12, 18, 255), min(1.0, (y - 158) / 22.0))
            bg.pset(x, y, col)

    for ix, ilen in ((198, 14), (236, 18), (268, 12)):
        for dy in range(ilen):
            bg.pset(ix + (dy // 3) % 2, 122 + dy, "G1" if dy % 2 == 0 else "G2")

    bg.save_png(os.path.join(sprites_dir, "cs_heist_bg.png"))


def _make_heist_pedestal(sprites_dir: str) -> None:
    """56x64 Sanctuary Egg Brazier Tripod at `(94, 86)` -> resting ground center `(122, 142)`."""
    for st in range(2):
        c = PixelCanvas(56, 64)
        cx = 28
        c.ellipse(cx, 57, 17.0, 4.5, (10, 11, 16, 135))
        c.rect(cx - 12, 48, 24, 9, "C1")
        c.rect(cx - 14, 52, 28, 5, "C0")
        c.rect(cx - 9, 34, 18, 16, "CS")
        c.rect(cx - 6, 36, 6, 12, "C2")
        c.ellipse(cx, 32, 16.0, 6.0, "Y0")
        c.ellipse(cx, 30, 14.0, 4.5, "Y1")
        c.ellipse(cx, 29, 11.0, 3.0, "R1" if st == 0 else "T0")
        for ex, ey in ((-5, 29), (-1, 30), (3, 28), (6, 30), (-3, 28)):
            c.pset(cx + ex, ey, "Y2" if st == 0 else "R2")
        for px in (cx - 13, cx - 5, cx + 5, cx + 13):
            c.line(px, 31, px + (1 if px < cx else -1), 22, "Y2", 2)
        if st == 0:
            _draw_obsidian_egg_oval(c, cx, 18, 10, 13)
        else:
            for sx, sy in ((cx - 3, 22), (cx - 4, 16), (cx + 3, 20), (cx + 4, 13)):
                c.pset(sx, sy, "C3")
                c.pset(sx + 1, sy - 3, "C2")
        c.add_outline("K", selective_hue=True)
        c.save_png(os.path.join(sprites_dir, f"cs_heist_pedestal_{st}.png"))


def _make_heist_torch_frames(sprites_dir: str) -> None:
    """28x44 wind-lashed wall torch flames."""
    for f in range(4):
        c = PixelCanvas(28, 44)
        bx, by = 10, 36
        gust = 4 + (f % 2) * 2
        for dy in range(26):
            u = dy / 25.0
            hw = max(0, int(round((1.0 - u ** 0.72) * 5.0 + math.sin(u * 4.0 + f * 1.5))))
            ox = int(round(u * gust + math.sin(u * 5.0 + f * 1.9) * 1.5))
            for dx in range(-hw, hw + 1):
                col = "Y3" if (u < 0.35 and abs(dx) <= 1) else ("Y2" if u < 0.65 else ("Y1" if u < 0.85 else "R2"))
                c.pset(bx + ox + dx, by - dy, col)
        for spx, spy in ((bx + gust + 2, 10 - f * 2), (bx + gust + 5, 16 - f)):
            c.pset(spx, spy, "Y2")
        c.save_png(os.path.join(sprites_dir, f"cs_heist_torch_{f}.png"))


def _make_heist_sentry_frames(sprites_dir: str) -> None:
    """60x80 Brotherhood Night-Watchmen bursting through corridor arch with lanterns & spears (no egg-blob silhouette)."""
    for f in range(2):
        c = PixelCanvas(60, 80)
        lean = 4 if f == 0 else 1
        # Rear Watchman striding slightly deeper inside doorway (`x=14`)
        rx = 15
        c.rect(rx - 5, 34, 10, 22, "U0")
        c.ellipse(rx, 27, 6.0, 6.0, "C1")
        c.ellipse(rx + 1, 24, 7.5, 3.0, "C2")
        c.line(rx - 3, 56, rx - 5, 70, "T0", 3)
        c.line(rx + 3, 56, rx + 6, 70, "T0", 3)
        c.line(rx + 2, 40, 38, 16 - f * 4, "C3", 2)

        # Lead Watchman lunging forward right (`cx=29+lean`) in dark slate-navy tabard
        lx = 27 + lean
        c.ellipse(lx, 73, 12.0, 3.5, (10, 11, 16, 130))
        c.line(lx - 4, 56, lx - 9, 71, "T0", 4)
        c.line(lx + 4, 56, lx + 12, 71, "T1", 4)
        c.ellipse(lx - 5, 72, 4.5, 2.5, "T0")
        c.ellipse(lx + 12, 72, 4.5, 2.5, "T1")
        for y in range(34, 60):
            u = (y - 34) / 25.0
            hw = int(8 + u * 3)
            for x in range(lx - hw, lx + hw + 1):
                c.pset(x, y, "U1" if x > lx else "U0")
        c.rect(lx - 8, 49, 17, 3, "T0")
        c.rect(lx - 1, 49, 3, 3, "Y1")
        c.ellipse(lx + 2, 26, 6.5, 6.5, "P1")
        c.ellipse(lx + 2, 21, 9.5, 3.8, "C2")
        c.ellipse(lx + 2, 18, 6.0, 4.2, "C3")
        c.pset(lx + 7, 20, "Y2")
        # Arm extended holding swinging brass storm lantern
        arm_x = lx + 18 + (2 if f == 0 else 4)
        arm_y = 37 - (2 if f == 1 else 0)
        c.line(lx + 6, 38, arm_x, arm_y, "U2", 4)
        c.line(arm_x, arm_y, arm_x, arm_y + 5, "C3")
        c.rect(arm_x - 3, arm_y + 4, 7, 9, "Y0")
        c.rect(arm_x - 2, arm_y + 6, 5, 5, "Y3")
        c.add_outline("K", selective_hue=True)
        c.save_png(os.path.join(sprites_dir, f"cs_heist_sentry_{f}.png"))


def _draw_sculpted_heist_boy_torso(c: PixelCanvas, cx: int, top_y: int, bot_y: int, lean_x: int = 0) -> None:
    """Organic draped Flight-Jerkin silhouette with harness cross-strap & brass carabiner (zero round potato body!)."""
    span = max(1, bot_y - top_y)
    for y in range(top_y, bot_y + 1):
        u = (y - top_y) / float(span)
        x0 = int(cx - 10 - math.sin(min(1.0, u * 1.1) * math.pi * 0.7) * 5 + lean_x * u)
        x1 = int(cx + 9 + math.sin(min(1.0, u * 1.4) * math.pi * 0.5) * 4 - max(0.0, u - 0.75) * 6 + lean_x * u)
        for x in range(x0, x1 + 1):
            col = PAL["E1"]
            if x >= x1 - 2 and y < bot_y - 4:
                col = PAL["E2"]
            elif x <= x0 + 2:
                col = PAL["DE"] if x == x0 else PAL["E0"]
            elif u > 0.78:
                col = PAL["E0"]
            c.pset(x, y, col)
    _draw_poly(c, _qbezier((cx - 8, top_y + 3), (cx + 1, top_y + 14), (cx + 6, bot_y - 10)), "T0", 4)
    _draw_poly(c, _qbezier((cx - 7, top_y + 3), (cx + 2, top_y + 14), (cx + 7, bot_y - 10)), "T2", 2)
    c.rect(cx + 1, top_y + 14, 3, 3, "Y1")
    c.pset(cx + 2, top_y + 15, "Y3")
    c.ellipse(cx - 1, top_y + 2, 10.0, 4.0, "E0")
    c.ellipse(cx, top_y + 1, 8.0, 2.5, "E2")


def _make_heist_boy_frames(sprites_dir: str) -> None:
    """
    80x96 expressive 17yo Boy frames (tapered Flight-Jerkin silhouette consistent with Hatching cutscene):
      0: Egg-lift crouch beside brazier (gloved hands lifting obsidian egg cleanly above coals)
      1: Pivoting right tucking egg into wrapped cloak satchel, glancing alertly left
      2: Mid-stride leap right onto Kestrel's lowered wing-ramp
    """
    for f in range(3):
        c = PixelCanvas(80, 96)
        c.ellipse(38, 89, 16.0, 4.0, (12, 12, 18, 130))
        if f == 0:
            # Grounded kneeling boots & bent knees leaning gently left toward brazier (`cx=44`)
            c.ellipse(45, 76, 11.0, 9.0, "S")
            c.ellipse(33, 86, 6.0, 3.4, "T1")
            c.ellipse(54, 86, 6.0, 3.4, "T2")
            _draw_sculpted_heist_boy_torso(c, 45, 45, 78, lean_x=-3)
            hx, hy = 39, 36
            c.ellipse(hx - 2, hy + 1, 8.0, 8.2, "P1")
            c.ellipse(hx - 3, hy, 6.2, 6.6, "P2")
            c.ellipse(hx + 2, hy - 3, 8.8, 8.8, "B0")
            c.ellipse(hx + 1, hy - 5, 7.0, 7.0, "B1")
            c.line(hx - 6, hy - 7, hx + 4, hy - 9, "B2", 2)
            c.rect(hx - 8, hy - 1, 2, 2, "EW")
            c.pset(hx - 8, hy, "S")
            # Left arm extended gently forward cradling lifted obsidian egg (`cx=20, cy=46`)
            c.line(40, 52, 25, 51, "E2", 5)
            _draw_obsidian_egg_oval(c, 19, 46, 8, 11)
            c.ellipse(24, 51, 3.5, 3.0, "T2")
        elif f == 1:
            # Dynamic turn-right stance with tucked wool egg-bundle, crisp left-glancing profile!
            c.line(30, 70, 24, 86, "S", 5)
            c.line(42, 70, 50, 86, "S", 5)
            c.ellipse(23, 86, 5.5, 3.2, "T1")
            c.ellipse(51, 86, 5.5, 3.2, "T2")
            _draw_sculpted_heist_boy_torso(c, 37, 39, 74, lean_x=2)
            # Wrapped leather/wool bundle held under right forearm showing a faint golden spark seam
            c.ellipse(47, 56, 7.5, 9.0, "T1")
            c.ellipse(46, 55, 5.5, 7.0, "T2")
            c.pset(47, 53, "Y3")
            c.pset(48, 55, "Y2")
            c.line(36, 51, 45, 57, "E2", 5)
            c.ellipse(45, 58, 3.6, 2.8, "P2")
            # Left-turned alert profile checking the arch behind him
            hx, hy = 38, 29
            c.ellipse(hx - 3, hy + 1, 8.0, 8.2, "P1")
            c.ellipse(hx - 4, hy, 6.2, 6.6, "P2")
            c.rect(hx - 11, hy - 1, 3, 4, "P2")
            c.ellipse(hx + 1, hy - 3, 8.8, 8.8, "B0")
            c.ellipse(hx + 1, hy - 5, 7.0, 6.8, "B1")
            c.line(hx - 7, hy - 7, hx + 4, hy - 9, "B2", 2)
            c.rect(hx - 8, hy - 2, 3, 2, "EW")
            c.pset(hx - 8, hy - 1, "S")
        else:
            # Sprinting bound forward right onto Kestrel's lowered silver wing-ramp
            c.line(23, 66, 12, 82, "S", 5)
            c.line(39, 66, 54, 78, "S", 5)
            c.ellipse(12, 82, 5.0, 3.0, "T1")
            c.ellipse(55, 79, 5.0, 3.0, "T2")
            _draw_sculpted_heist_boy_torso(c, 36, 38, 70, lean_x=5)
            # Trailing cloak fold & egg satchel hip
            c.ellipse(22, 48, 8.0, 6.0, "E0")
            c.ellipse(45, 54, 6.8, 7.5, "T2")
            c.pset(46, 53, "Y2")
            c.line(40, 44, 62, 41, "E2", 5)
            c.ellipse(65, 41, 3.8, 3.0, "P2")
            hx, hy = 41, 28
            c.ellipse(hx + 2, hy, 7.5, 8.0, "P2")
            c.ellipse(hx, hy - 4, 8.5, 8.5, "B0")
            c.ellipse(hx + 1, hy - 5, 6.8, 6.8, "B1")
            c.rect(hx + 5, hy - 1, 3, 2, "EW")
            c.pset(hx + 7, hy, "S")
        c.add_outline("K", selective_hue=True)
        c.save_png(os.path.join(sprites_dir, f"cs_heist_boy_{f}.png"))


def _draw_silver_wing(c: PixelCanvas, shx: int, shy: int, tip_x: int, tip_y: int, mid_x: int, mid_y: int, mem_drop: int) -> None:
    """Smooth tapered silver-slate dragon wing painted via dense parametric spans (zero vertical cuts or loose spokes!)."""
    steps = 90
    top_pts = _qbezier((shx, shy), (mid_x, mid_y), (tip_x, tip_y), steps)
    bot_pts = []
    # Keep wing membrane tapering cleanly down to 0 thickness at the pointed wingtip `(tip_x, tip_y)`
    dir_in = -1 if tip_x > shx else 1
    for k in range(len(top_pts)):
        u = k / float(steps)
        px, py = top_pts[k]
        taper = max(0.0, 1.0 - (u ** 1.35))
        scallop = int(abs(math.sin(u * math.pi * 3.0)) * 3.5 * taper)
        drop = int(round(mem_drop * (0.45 + 0.55 * math.sin(u * math.pi * 0.85)) * taper)) + scallop
        bot_pts.append((px + int(round(u * 2.5 * taper * dir_in)), py + drop))

    for k in range(len(top_pts)):
        tx, ty = top_pts[k]
        bx, by = bot_pts[k]
        # Paint column strip from leading bone `top_pts[k]` to scalloped trailing edge `bot_pts[k]`
        dist = max(1, int(math.hypot(bx - tx, by - ty)))
        for s in range(dist + 1):
            v = s / float(dist)
            px = int(round(tx + (bx - tx) * v))
            py = int(round(ty + (by - ty) * v))
            col = PAL["SG2"] if v < 0.28 else (PAL["SG1"] if v < 0.72 else PAL["SG0"])
            c.pset(px, py, col)
            c.pset(px + 1, py, col)
    # Soft internal feather finger creases strictly inside membrane span
    for rib_u in (0.38, 0.68):
        idx = min(len(bot_pts) - 1, int(rib_u * (len(bot_pts) - 1)))
        tx_r, ty_r = top_pts[idx]
        bx_r, by_r = bot_pts[idx]
        if by_r - ty_r >= 4:
            c.line(tx_r, ty_r + 2, bx_r, by_r - 1, "SG2")
    _draw_poly(c, top_pts, "SG3", 2)
    c.line(shx, shy + 1, mid_x, mid_y + 1, "SG1")


def _draw_kestrel_head(c: PixelCanvas, hx: int, hy: int, facing_right: bool = True) -> None:
    d = 1 if facing_right else -1
    c.ellipse(hx, hy, 12.0, 8.5, "SG0")
    c.ellipse(hx, hy - 1, 10.0, 6.5, "SG1")
    c.ellipse(hx + d, hy - 2, 7.0, 4.2, "SG2")
    c.ellipse(hx + d * 11, hy + 1, 7.5, 3.6, "SG1")
    c.line(hx + d * 6, hy - 1, hx + d * 16, hy + 1, "SG3")
    c.line(hx - d * 3, hy - 7, hx - d * 14, hy - 16, "SG2", 3)
    c.line(hx - d * 2, hy - 8, hx - d * 12, hy - 15, "SG3", 1)
    c.line(hx - d * 5, hy - 3, hx - d * 15, hy - 7, "SG2", 2)
    ex = hx + d * 5
    c.ellipse(ex, hy - 1, 2.8, 2.5, "K")
    c.ellipse(ex, hy - 1, 2.0, 1.8, "Y2")
    c.pset(ex + d, hy - 1, "EW")


def _make_heist_kestrel_perch(sprites_dir: str) -> None:
    """
    140x120 Kestrel perched at parapet edge `(176, 26)`:
      0: boarding ramp wing dropped toward Boy left (`looks left`)
      1: Boy mounted tightly on leather courier saddle; Kestrel raises giant silver wings overhead
      2: leaping forward off parapet stones into midnight chasm
    """
    for f in range(3):
        c = PixelCanvas(140, 120)
        dy_body = 0 if f == 0 else (-4 if f == 1 else -12)
        dx_body = 0 if f < 2 else 14
        bx, by = 72 + dx_body, 72 + dy_body

        c.ellipse(bx, 98, 24.0, 5.0, (10, 12, 18, 120 if f < 2 else 45))
        _draw_poly(c, _qbezier((bx - 14, by + 6), (bx - 42, by + 22), (bx - 58, by + 16)), "SG0", 5)
        _draw_poly(c, _qbezier((bx - 14, by + 5), (bx - 42, by + 21), (bx - 58, by + 15)), "SG2", 2)

        if f == 0:
            _draw_silver_wing(c, bx + 2, by - 4, bx + 44, by - 36, bx + 22, by - 26, 20)
            c.ellipse(bx, by, 22.0, 14.0, "SG0")
            c.ellipse(bx + 1, by - 2, 18.0, 11.0, "SG1")
            c.ellipse(bx - 1, by - 5, 11.0, 7.0, "SG2")
            c.ellipse(bx - 2, by - 9, 10.0, 4.5, "T1")
            c.line(bx - 4, by - 7, bx + 2, by + 7, "T2", 2)
            c.line(bx - 6, by + 10, bx - 10, 94, "SG1", 4)
            c.line(bx + 10, by + 10, bx + 14, 94, "SG2", 4)
            _draw_silver_wing(c, bx - 4, by - 2, 14, 88, 36, 76, 15)
            _draw_poly(c, _qbezier((bx + 14, by - 6), (bx + 26, by - 24), (bx + 12, by - 38)), "SG1", 9)
            _draw_kestrel_head(c, bx + 10, by - 40, facing_right=False)

        elif f == 1:
            _draw_silver_wing(c, bx + 8, by - 8, bx + 54, by - 56, bx + 32, by - 44, 24)
            _draw_silver_wing(c, bx - 4, by - 8, 16, by - 54, 42, by - 42, 24)
            c.ellipse(bx, by, 23.0, 14.0, "SG0")
            c.ellipse(bx + 1, by - 2, 19.0, 11.0, "SG1")
            c.line(bx - 10, by + 10, bx - 14, 94, "SG1", 4)
            c.line(bx + 10, by + 10, bx + 12, 94, "SG2", 4)
            c.ellipse(bx - 2, by - 14, 9.0, 10.5, "E1")
            c.ellipse(bx - 8, by - 11, 8.0, 6.5, "E0")
            c.ellipse(bx + 5, by - 13, 5.5, 6.5, "T2")
            c.pset(bx + 5, by - 14, "Y2")
            c.ellipse(bx + 3, by - 26, 6.2, 6.2, "B1")
            c.ellipse(bx + 6, by - 25, 4.2, 4.8, "P2")
            _draw_poly(c, _qbezier((bx + 14, by - 6), (bx + 28, by - 20), (bx + 36, by - 34)), "SG1", 9)
            _draw_poly(c, _qbezier((bx + 13, by - 8), (bx + 27, by - 22), (bx + 35, by - 36)), "SG2", 4)
            _draw_kestrel_head(c, bx + 37, by - 36, facing_right=True)

        else:
            _draw_silver_wing(c, bx + 6, by - 8, bx + 48, by - 26, bx + 28, by - 22, 24)
            _draw_silver_wing(c, bx - 4, by - 6, bx - 44, by - 18, bx - 22, by - 18, 22)
            c.ellipse(bx, by, 22.0, 13.0, "SG0")
            c.ellipse(bx + 1, by - 2, 18.0, 10.0, "SG1")
            c.line(bx - 10, by + 10, bx - 24, by + 24, "SG1", 4)
            c.line(bx + 8, by + 10, bx - 6, by + 26, "SG2", 4)
            c.ellipse(bx + 1, by - 13, 9.0, 10.0, "E1")
            c.ellipse(bx - 9, by - 10, 8.5, 6.0, "E0")
            c.ellipse(bx + 6, by - 23, 6.0, 6.0, "B1")
            c.ellipse(bx + 9, by - 22, 4.2, 4.5, "P2")
            _draw_poly(c, _qbezier((bx + 14, by - 6), (bx + 30, by - 16), (bx + 42, by - 24)), "SG1", 9)
            _draw_kestrel_head(c, bx + 44, by - 25, facing_right=True)

        c.add_outline("DN", selective_hue=True)
        c.save_png(os.path.join(sprites_dir, f"cs_heist_kestrel_{f}.png"))


def _make_heist_sky_escape(sprites_dir: str) -> None:
    """
    Stage 3 High-Altitude Moonlit Escape Vista (`cs_heist_sky_bg.png` + `cs_heist_fly_0..3.png`):
    Organic fading headland low-left (zero vertical cut drop), billowy moonlit clouds, smooth wing sweeps.
    """
    sky = PixelCanvas(320, 180)
    for y in range(180):
        u = y / 179.0
        col = blend_color((10, 14, 28, 255), (26, 38, 64, 255), u ** 0.85)
        for x in range(320):
            sky.pset(x, y, col)
    for y in range(18, 58):
        for x in range(242, 282):
            d = math.hypot(x - 262.0, y - 38.0)
            if d < 10.5:
                sky.pset(x, y, (242, 240, 224, 255) if d < 8.5 else (188, 198, 218, 220))
            elif d < 20.0 and (x + y) % 3 == 0:
                sky.pset(x, y, (98, 120, 158, 90))
    for sx, sy in ((22, 18), (68, 30), (118, 16), (178, 28), (214, 22), (304, 48), (144, 44)):
        sky.pset(sx, sy, (238, 232, 208, 180))

    # Tapered distant cape vanishing naturally all the way down to `y=180` around `x=162` (zero vertical cutoff!)
    for x in range(165):
        cliff_y = 132 + int((x / 165.0) * 48 + math.sin(x * 0.08) * 3)
        for y in range(cliff_y, 180):
            sky.pset(x, y, (15, 21, 33, 255))
    for bx, by in ((34, 142), (48, 147)):
        sky.rect(bx, by, 2, 2, "Y2")
        sky.pset(bx + 1, by - 1, "R2")

    _paint_billowy_cloud(sky, 68, 96, 1.35, 175)
    _paint_billowy_cloud(sky, 192, 120, 1.55, 165)
    _paint_billowy_cloud(sky, 276, 88, 1.25, 165)
    sky.save_png(os.path.join(sprites_dir, "cs_heist_sky_bg.png"))

    # 4-frame wingbeat loop with sweeping upper-back / down-back wings & unobstructed body!
    # `(tip_dx, tip_dy, mid_dx, mid_dy, drop_px, far_tip_dx, far_tip_dy)`
    wing_specs = [
        (-42, -36, -14, -34, 18, 34, -38),  # 0: high swept upstroke peak
        (-40, -14, -14, -22, 18, 30, -24),  # 1: sweeping mid-downstroke
        (-30, 32, -8, 18, 16, 26, -12),     # 2: deep dramatic downstroke beneath chest
        (-46, -22, -18, -24, 16, 32, -30),  # 3: sleek forward up-glide
    ]
    for f, (tdx, tdy, mdx, mdy, drop_px, ftdx, ftdy) in enumerate(wing_specs):
        fc = PixelCanvas(128, 88)
        cx, cy = 62, 50
        _draw_silver_wing(fc, cx + 6, cy - 4, cx + ftdx, cy + ftdy, cx + (ftdx // 2), cy + (ftdy // 2) - 4, drop_px)
        _draw_poly(fc, _qbezier((cx - 16, cy), (cx - 40, cy + (4 if f == 2 else -2)), (cx - 56, cy + 2)), "SG0", 5)
        _draw_poly(fc, _qbezier((cx - 16, cy - 1), (cx - 40, cy + (3 if f == 2 else -3)), (cx - 56, cy + 1)), "SG2", 2)
        fc.ellipse(cx, cy, 22.0, 9.5, "SG0")
        fc.ellipse(cx + 2, cy - 1, 18.0, 7.2, "SG1")
        fc.ellipse(cx + 2, cy - 3, 12.0, 4.2, "SG2")
        fc.line(cx - 12, cy + 5, cx - 26, cy + 10, "SG1", 3)
        _draw_poly(fc, _qbezier((cx + 16, cy - 2), (cx + 28, cy - 6), (cx + 38, cy - 10)), "SG1", 7)
        _draw_kestrel_head(fc, cx + 40, cy - 11, facing_right=True)
        # Rider: 17yo Boy tucked flat over Kestrel's neck clutching dark bundle w/ tiny gold spark
        fc.ellipse(cx + 2, cy - 11, 10.5, 6.0, "E1")
        fc.ellipse(cx - 12, cy - 12, 9.0, 4.5, "E0")
        fc.ellipse(cx + 10, cy - 12, 5.0, 5.5, "B1")
        fc.ellipse(cx + 13, cy - 11, 3.5, 4.0, "P2")
        fc.ellipse(cx + 10, cy - 6, 4.5, 4.0, "T2")
        fc.pset(cx + 10, cy - 6, "Y3")
        _draw_silver_wing(fc, cx + 2, cy - 2, cx + tdx, cy + tdy, cx + mdx, cy + mdy, drop_px)
        fc.add_outline("DN", selective_hue=True)
        fc.save_png(os.path.join(sprites_dir, f"cs_heist_fly_{f}.png"))


def generate_heist_cutscene_art(sprites_dir: str) -> None:
    os.makedirs(sprites_dir, exist_ok=True)
    _make_heist_bg(sprites_dir)
    _make_heist_pedestal(sprites_dir)
    _make_heist_torch_frames(sprites_dir)
    _make_heist_sentry_frames(sprites_dir)
    _make_heist_boy_frames(sprites_dir)
    _make_heist_kestrel_perch(sprites_dir)
    _make_heist_sky_escape(sprites_dir)
