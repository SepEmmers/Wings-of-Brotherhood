"""
Expressive 48x48 Pixel-Art Dialogue Portraits
for Temeraire: Wings of the Brotherhood.

Replaces blocky rectangle heads with sculpted medieval RPG bust portraits:
- Ornate beveled brass-and-oak portrait frames with corner rivets
- Atmospheric character-specific backdrop vignettes
- Tapered jawlines, shaded cheekbones, expressive eyes with catchlights
- Hand-sculpted 48x48 Black-Scaled Dragon & Narrator Chronicle portraits
"""

import os
from pixel_art_lib import PAL, PixelCanvas, blend_color


def _paint_portrait_frame(c: PixelCanvas, bg_top, bg_bot):
    """Paint atmospheric gradient backdrop + ornate beveled medieval brass/oak frame."""
    for y in range(2, 46):
        t = (y - 2) / 43.0
        col = blend_color(bg_top, bg_bot, t)
        for x in range(2, 46):
            # Subtle vignette darkening near edges
            dx = abs(x - 23.5) / 22.0
            dy = abs(y - 23.5) / 22.0
            vig = max(0.0, (dx * dx + dy * dy) * 0.25)
            c.pset(x, y, blend_color(col, (14, 12, 18, 255), vig))

    # Outer warm ink & double-bevel tarnished brass frame with corner studs
    c.rect_outline(0, 0, 48, 48, "K")
    c.rect_outline(1, 1, 46, 46, "Y0")
    # Top/left brass highlight, bottom/right deep brass shadow
    c.line(1, 1, 45, 1, "Y2")
    c.line(1, 1, 1, 45, "Y2")
    c.line(2, 46, 46, 46, "T0")
    c.line(46, 2, 46, 46, "T0")
    c.rect_outline(2, 2, 44, 44, "DK")
    # Corner rivets
    for cx, cy in ((2, 2), (45, 2), (2, 45), (45, 45)):
        c.pset(cx, cy, "Y3")


def _paint_human_bust(
    filename: str,
    sprites_dir: str,
    *,
    bg_top=(46, 40, 56, 255),
    bg_bot=(24, 21, 30, 255),
    tunic_dark="U0",
    tunic_mid="U1",
    tunic_light="U2",
    hair_dark="B0",
    hair_mid="B1",
    hair_light="B2",
    eye_col="U2",
    is_female=False,
    angry=False,
    smirk=False,
    smile=False,
    stern=False,
    beard_style=None,      # None | "full_grey" | "trimmed_dark" | "sandy_grizzled"
    hat_style=None,        # None | "mariner" | "inquisitor" | "baker" | "knit_cap" | "coif"
    cloak_col=None,        # None | "E0" | "E1" | "I0"
    hood=False,
    hood_down=False,
    braid=False,
    braid_ribbon="D2",
    collar_scarf=False,
    scarf_col=None,        # Optional colored scarf: e.g. "E1" (emerald), "L1" (linen)
    whistle_clasp=False,
    shoulder_strap=False,
    closed_collar=False,
    apron_bib=False,
    tousled_hair=False,
    older_teen=False,
    rosy_cheeks=False,
    freckles=False,
    age_lines=False,
    flour_dust=False,
    scar=False,
    tonsure=False,
    clerical_stole=False,
):
    c = PixelCanvas(48, 48)
    _paint_portrait_frame(c, bg_top, bg_bot)

    # 1. Back hair / Cloak behind shoulders
    if hood and cloak_col:
        c.ellipse(23.5, 24.0, 14.5, 17.5, "K")
        c.ellipse(23.5, 24.0, 13.5, 16.5, cloak_col)
        c.ellipse(23.5, 25.0, 11.2, 13.8, (18, 22, 24, 255))
    elif is_female:
        c.ellipse(23.5, 24.0, 12.2, 13.0, hair_dark)
        c.ellipse(23.5, 22.0, 11.5, 11.0, hair_mid)

    # 2. Shoulders & Medieval Tunic / Coat / Cloak
    # Rounded natural shoulders from y=33..45
    for y in range(33, 46):
        half_w = min(17, 10 + (y - 33) * 2)
        for x in range(24 - half_w, 24 + half_w):
            col = tunic_mid
            if x < 20 or x > 28 and y > 38:
                col = tunic_dark
            elif x < 23 and y < 40:
                col = tunic_light
            c.pset(x, y, col)
    # Shoulder silhouette outline
    for x in range(11, 37):
        if x < 14 or x > 33:
            c.pset(x, 34, "K")
    c.line(14, 33, 33, 33, "K")

    # Tunic neckline / collar / apron / stole
    if scarf_col:
        s_dark = "E0" if scarf_col == "E1" else "L2"
        s_light = "E2" if scarf_col == "E1" else "L0"
        c.rect(16, 33, 16, 6, s_dark)
        c.rect(17, 34, 14, 4, scarf_col)
        c.line(18, 35, 29, 35, s_light)
        c.rect(22, 37, 4, 4, scarf_col)
    elif collar_scarf:
        c.rect(17, 33, 14, 5, "L1")
        c.rect(18, 34, 12, 3, "L0")
    elif closed_collar:
        c.rect(19, 33, 10, 4, tunic_dark)
        c.line(20, 34, 27, 34, tunic_mid)
    else:
        # Open medieval laced shirt collar
        c.line(19, 33, 23, 39, "L1")
        c.line(28, 33, 24, 39, "L1")
        c.rect(22, 34, 4, 5, "L0")

    if apron_bib:
        c.rect(17, 35, 3, 11, "L0")
        c.rect(28, 35, 3, 11, "L0")
        c.rect(19, 38, 10, 8, "L1")
        c.rect(20, 39, 8, 6, "L0")

    if cloak_col:
        # Drape cloak lapels over shoulders
        for y in range(32, 46):
            w = 5 + (y - 32) // 3
            c.rect(10, y, w, 1, cloak_col)
            c.rect(38 - w, y, w, 1, cloak_col)
        if hood_down:
            c.rect(12, 31, 6, 4, "E0")
            c.rect(30, 31, 6, 4, "E0")
            c.line(13, 32, 17, 34, "E2")
            c.line(34, 32, 30, 34, "E2")
        # Leather flight strap across chest (Brotherhood / Anna / Senior Bram)
        if cloak_col in ("E0", "E1"):
            for i in range(13):
                c.pset(15 + i, 33 + i, "T0")
                c.pset(16 + i, 33 + i, "T2")
            c.rect(21, 38, 3, 3, "Y1")  # Brass carabiner clasp
            c.pset(22, 39, "Y3")
    elif hat_style == "inquisitor":
        # Crimson & gold stole with cross sigil
        c.rect(21, 34, 6, 12, "I0")
        c.rect(22, 34, 4, 12, "I1")
        c.line(23, 37, 23, 43, "Y2")
        c.line(21, 39, 25, 39, "Y2")
    elif clerical_stole:
        # St. Donatian Cathedral white Roman collar + crimson/gold priest stole
        c.rect(19, 32, 10, 3, "L0")
        c.rect(17, 35, 4, 11, "I0")
        c.rect(27, 35, 4, 11, "I0")
        c.rect(18, 35, 2, 11, "I1")
        c.rect(28, 35, 2, 11, "I1")
        c.line(18, 38, 19, 38, "Y2")
        c.line(28, 38, 29, 38, "Y2")
        c.line(19, 41, 19, 43, "Y1")
        c.line(28, 41, 28, 43, "Y1")
    elif hat_style == "baker":
        # White flour-dusted apron straps
        c.rect(16, 34, 3, 12, "L0")
        c.rect(29, 34, 3, 12, "L0")
        c.rect(18, 38, 12, 8, "L1")

    if shoulder_strap and not cloak_col:
        for i in range(13):
            c.pset(15 + i, 33 + i, "T0")
            c.pset(16 + i, 33 + i, "T2")
        c.rect(21, 38, 3, 3, "Y1")
        c.pset(22, 39, "Y3")

    if whistle_clasp:
        c.line(20, 34, 24, 38, "Y1")
        c.rect(24, 37, 3, 2, "Y2")
        c.pset(24, 37, "Y3")

    if is_female and not cloak_col and not apron_bib:
        # Clara's cream ropewalk apron straps over rose dress
        c.rect(17, 35, 3, 11, "L0")
        c.rect(28, 35, 3, 11, "L0")
        c.rect(19, 39, 10, 7, "L1")

    # 3. Shaded Neck & Chin Cast Shadow
    c.rect(20, 29, 8, 6, "P1")
    c.rect(21, 30, 6, 5, "P2")
    c.rect(20, 29, 8, 2, "P0")  # Cast shadow from jawline

    # 4. Sculpted Cranium & Tapered Jawline (NOT a rectangle!)
    # Rows y=11..30 with smooth jaw taper
    head_rows = {
        11: (17, 30),
        12: (16, 31),
        13: (15, 32),
        14: (15, 32),
        15: (14, 33),
        16: (14, 33),
        17: (14, 33),
        18: (14, 33),
        19: (14, 33),
        20: (14, 33),
        21: (15, 32),
        22: (15, 32),
        23: (15, 32),
        24: (16, 31),
        25: (16, 31),
        26: (17, 30),
        27: (18, 29),
        28: (19, 28),
        29: (20, 27),
    }
    for y, (x0, x1) in head_rows.items():
        for x in range(x0, x1 + 1):
            col = "P2"
            if x >= x1 - 1 or y >= 27:
                col = "P1"
            if y == 29 or (x == x1 and y >= 24):
                col = "P0"
            elif y <= 16 and 17 <= x <= 26:
                col = "P3"  # Forehead top-left key highlight
            elif 20 <= y <= 23 and 16 <= x <= 21:
                col = "P3"  # Cheekbone highlight
            c.pset(x, y, col)
        # Warm umber jawline curve (softer than flat black box)
        if y >= 24:
            c.pset(x0 - 1, y, "DK")
            c.pset(x1 + 1, y, "DK")
    for x in range(21, 27):
        c.pset(x, 30, "DK")

    # Ears
    c.rect(13, 19, 2, 4, "P1")
    c.pset(13, 20, "P2")
    c.rect(33, 19, 2, 4, "P0")

    # 5. Facial Features: Brows, Eyes, Nose, Cheeks, Mouth
    if rosy_cheeks:
        c.rect(16, 22, 3, 2, "PK")
        c.rect(29, 22, 3, 2, "PK")
    if freckles:
        for fx, fy in ((17, 22), (19, 23), (29, 22), (31, 23)):
            c.pset(fx, fy, "P1")
    if age_lines:
        c.pset(17, 23, "P1")
        c.pset(30, 23, "P1")
        c.line(18, 14, 28, 14, "P1")
    if scar:
        c.line(16, 17, 19, 20, "P0")
        c.pset(17, 17, "P3")

    # Eyes at y=19..20 (Left: x=17..20, Right: x=27..30)
    # Upper eyelid line
    c.rect(17, 18, 4, 1, "P0")
    c.rect(27, 18, 4, 1, "P0")
    # Sclera + Iris + Pupil + Catchlight
    c.rect(17, 19, 4, 2, "EW")
    c.rect(27, 19, 4, 2, "EW")
    c.rect(18, 19, 2, 2, eye_col)
    c.rect(28, 19, 2, 2, eye_col)
    c.pset(19, 20, "K")
    c.pset(29, 20, "K")
    c.pset(18, 19, "Y3")  # Crisp eye catchlight
    c.pset(28, 19, "Y3")

    # Eyebrows (expressive angles!)
    if angry:
        c.line(16, 16, 21, 18, "K")
        c.line(26, 18, 31, 16, "K")
        c.pset(23, 17, "P0")  # brow furrow crease
    elif stern:
        c.rect(16, 17, 5, 1, hair_dark)
        c.rect(27, 17, 5, 1, hair_dark)
    else:
        c.line(16, 17, 20, 16, hair_dark)
        c.line(27, 16, 31, 17, hair_dark)

    # Sculpted Nose (bridge highlight + tip shadow)
    c.line(23, 19, 23, 22, "P3")
    c.rect(23, 23, 2, 1, "P1")
    c.pset(24, 23, "P0")

    # Mouth
    if angry:
        c.line(21, 26, 26, 26, "P0")
        c.pset(20, 27, "K")
        c.pset(27, 27, "K")
        c.rect(22, 26, 4, 1, "K")
    elif smile:
        c.pset(20, 25, "P0")
        c.pset(27, 25, "P0")
        c.rect(21, 26, 5, 1, "PK")
        c.line(22, 26, 25, 26, "R1")
    elif smirk:
        c.line(21, 26, 25, 26, "P0")
        c.pset(26, 25, "P0")
    else:
        c.rect(21, 26, 5, 1, "PK")
        c.rect(22, 26, 3, 1, "R1")
        c.rect(22, 27, 3, 1, "P1")

    # 6. Beard (if applicable)
    if beard_style == "full_grey":
        c.ellipse(23.5, 28.0, 9.0, 6.2, "GR0")
        c.ellipse(23.5, 27.5, 8.0, 5.2, "GR1")
        c.ellipse(22.5, 27.0, 5.5, 3.8, "GR2")
        # Keep mouth visible inside moustache
        c.rect(20, 24, 8, 2, "GR2")
        c.rect(22, 26, 4, 1, "P0")
    elif beard_style == "trimmed_dark":
        c.ellipse(23.5, 28.2, 7.8, 4.5, hair_dark)
        c.ellipse(23.5, 27.6, 6.6, 3.5, hair_mid)
        c.rect(21, 25, 6, 2, "P2")
        c.rect(22, 26, 4, 1, "P0")
    elif beard_style == "sandy_grizzled":
        c.ellipse(23.5, 28.5, 8.8, 5.8, "H0")
        c.ellipse(23.5, 27.8, 7.8, 4.8, "H1")
        c.ellipse(22.5, 27.2, 5.5, 3.4, "H2")
        c.line(18, 28, 20, 31, "GR2")
        c.line(25, 28, 27, 30, "GR2")
        c.rect(20, 24, 8, 2, "H2")
        c.rect(22, 26, 4, 1, "P0")

    # 7. Hair Crown, Locks & Bangs
    if tonsure:
        # Shaved medieval tonsure crown continuous with warm forehead, framed by silver-grey side halo
        c.ellipse(23.5, 10.6, 8.8, 3.4, "P1")
        # Trace only the upper scalp outline so the forehead seamlessly blends down into head_rows
        for x in range(14, 34):
            dx = (x - 23.5) / 9.2
            if dx * dx <= 1.0:
                import math
                y_top = int(round(10.8 - 3.6 * math.sqrt(max(0.0, 1.0 - dx * dx))))
                c.pset(x, y_top, "K")
                c.pset(x, y_top + 1, "P1")
        c.ellipse(22.8, 10.5, 6.9, 2.6, "P2")
        c.line(19, 9, 21, 9, "P3")
        # Temple hair wreath curving inward along brow edges without cutting across center scalp
        for y in range(10, 14):
            c.rect(13, y, 4 if y >= 12 else 3, 1, hair_dark)
            c.rect(14, y, 3 if y >= 12 else 2, 1, hair_mid)
            c.rect(31 if y >= 12 else 32, y, 4 if y >= 12 else 3, 1, hair_dark)
            c.rect(31, y, 3 if y >= 12 else 2, 1, hair_mid)
        c.rect(13, 14, 2, 5, hair_dark)
        c.pset(14, 14, hair_mid)
        c.rect(33, 14, 2, 5, hair_dark)
        c.pset(32, 14, hair_mid)
        for bx in (15, 17, 29, 31):
            c.pset(bx, 11, hair_light)
            c.pset(bx, 12, hair_mid)
    else:
        # Top hair mass sculpted with highlights & fringe strands
        c.ellipse(23.5, 11.5, 10.2, 5.0, hair_dark)
        c.ellipse(23.0, 10.5, 9.2, 4.0, hair_mid)
        c.ellipse(21.5, 9.5, 6.0, 2.2, hair_light)
        if tousled_hair:
            c.line(18, 6, 20, 8, hair_mid)
            c.line(22, 5, 24, 8, hair_light)
            c.line(26, 6, 27, 8, hair_mid)
            c.pset(29, 7, hair_light)
        # Sideburns / temple locks
        c.rect(13, 12, 3, 7, hair_dark)
        c.rect(14, 12, 2, 6, hair_mid)
        c.rect(32, 12, 3, 7, hair_dark)
        c.rect(32, 12, 2, 6, hair_mid)

        # Organic front fringe / bangs
        for bx, by, bh in ((16, 13, 3), (19, 12, 3), (22, 13, 2), (25, 12, 3), (28, 12, 3), (30, 13, 2)):
            c.rect(bx, by, 2, bh, hair_mid)
            c.pset(bx, by, hair_light)

    if is_female:
        # Soft side framing locks
        c.rect(13, 16, 3, 13, hair_dark)
        c.rect(14, 16, 2, 11, hair_mid)
        c.rect(32, 16, 3, 13, hair_dark)
        c.rect(32, 16, 2, 11, hair_mid)
        if braid:
            # Braided hair draped over left shoulder with colored ribbon
            for by in range(25, 42, 3):
                c.rect(14, by, 3, 3, hair_dark)
                c.rect(14, by, 2, 2, hair_mid)
                c.pset(15, by, hair_light)
            c.rect(14, 39, 3, 2, braid_ribbon)

    # 8. Hats & Hoods (drawn cleanly over hair with cast brow shadow)
    if hood and cloak_col:
        # Cowl arch framing face
        c.ellipse(23.5, 10.5, 12.2, 6.0, "K")
        c.ellipse(23.5, 10.5, 11.2, 5.0, cloak_col)
        c.line(14, 9, 32, 9, "E3" if cloak_col in ("E0", "E1") else "E2")
        for y in range(11, 32):
            c.rect(11, y, 3, 1, cloak_col)
            c.rect(34, y, 3, 1, cloak_col)
            c.pset(11, y, "K")
            c.pset(36, y, "K")
        if cloak_col == "E0":
            # Brotherhood rider shadow over upper brow
            c.rect(15, 13, 18, 4, (20, 22, 24, 155))

    if hat_style == "mariner":
        # Shipmaster's tricorn / wide-brimmed sea captain hat
        c.ellipse(23.5, 7.5, 10.5, 4.2, "K")
        c.ellipse(23.5, 7.5, 9.5, 3.4, "U0")
        c.ellipse(22.5, 6.5, 6.5, 2.0, "U1")
        # Brim
        c.ellipse(23.5, 11.2, 14.5, 2.5, "K")
        c.ellipse(23.5, 11.0, 13.5, 1.8, "S")
        c.line(13, 10, 34, 10, "Y1")  # Brass trim band
    elif hat_style == "inquisitor":
        # Severe crimson-and-black ecclesiastical cap
        c.rect(14, 5, 20, 8, "I0")
        c.rect(15, 6, 18, 6, "I1")
        c.rect(16, 6, 12, 2, "I2")
        c.rect(13, 11, 22, 3, "K")
        c.rect(14, 12, 20, 1, "Y1")  # Gold ecclesiastical band
        c.rect(15, 14, 18, 3, (14, 12, 18, 140))  # Shadow over brow
    elif hat_style == "baker":
        # Soft pleated white linen toque
        c.ellipse(23.0, 7.5, 10.5, 4.5, "L1")
        c.ellipse(22.0, 6.5, 9.0, 3.5, "L0")
        c.rect(14, 10, 19, 3, "L2")
        c.rect(15, 10, 17, 2, "L0")
        if flour_dust:
            # Subtle flour dust smudge on apron bib instead of floating dots on cheeks
            c.rect(18, 37, 3, 2, "L0")
            c.pset(29, 39, "L0")
            c.pset(19, 8, "L1")
    elif hat_style == "knit_cap":
        # Uncle Willem's ribbed wool dockworker cap
        c.ellipse(23.5, 8.5, 10.0, 4.5, "C0")
        c.ellipse(22.5, 7.5, 8.5, 3.2, "C1")
        c.rect(14, 10, 19, 3, "C0")
        for rx in range(15, 33, 3):
            c.line(rx, 10, rx, 12, "C2")
    elif hat_style == "coif":
        # Camp Cook Mieke's starched Flemish linen coif framing cheeks & coiled hair
        c.ellipse(23.5, 9.5, 11.5, 5.2, "L2")
        c.ellipse(23.0, 8.5, 10.5, 4.2, "L0")
        c.ellipse(21.5, 7.5, 7.0, 2.2, "EW")
        c.rect(12, 11, 4, 15, "L1")
        c.rect(12, 12, 2, 13, "L0")
        c.rect(32, 11, 4, 15, "L2")
        c.rect(33, 12, 2, 13, "L1")
        c.line(15, 10, 32, 10, "L2")
        # Side linen lappets tied neatly under chin
        c.line(13, 25, 17, 30, "L1")
        c.line(34, 25, 30, 30, "L2")

    c.save_png(os.path.join(sprites_dir, filename))


def _make_black_dragon_portrait(sprites_dir: str):
    """
    Hand-sculpted 48x48 portrait of the dying Unseen Black-Scaled Dragon:
    dramatic 3/4 profile, obsidian armored snout, sweeping slate horns,
    soulful amber slit-pupil eye, moonlight scale highlights, and hunter wound.
    """
    c = PixelCanvas(48, 48)
    _paint_portrait_frame(c, (24, 30, 48, 255), (14, 14, 22, 255))

    # Faint nocturnal mist stars/embers in background
    for sx, sy, col in ((7, 8, "O3"), (40, 7, "O3"), (39, 14, "Y0"), (8, 17, "O2")):
        c.pset(sx, sy, col)

    # Folded wing ridge silhouette rising behind left shoulder
    for y in range(15, 36):
        wx0 = max(5, 8 - (y - 15) // 4)
        wx1 = 15 - (y - 15) // 5
        for x in range(wx0, wx1):
            c.pset(x, y, "O0" if x < wx1 - 1 else "O2")
    c.line(6, 15, 13, 21, "O3")

    # Sweeping back ear-horns & neck dorsal crests
    c.line(18, 14, 7, 5, "O3")
    c.line(18, 15, 7, 6, "O2")
    c.line(18, 16, 8, 7, "O0")
    c.line(22, 12, 14, 4, "C3")
    c.line(22, 13, 15, 5, "C1")
    c.line(21, 14, 15, 6, "O0")

    # Neck & chest curved mass (y=24..45)
    for y in range(24, 46):
        x0 = max(7, 13 - (y - 24) // 3)
        x1 = min(35, 29 + (y - 24) // 3)
        for x in range(x0, x1):
            col = "O1"
            if x < x0 + 2 or x > x1 - 3:
                col = "O0"
            elif (x + y) % 4 == 0 and x < 24:
                col = "O2"
            c.pset(x, y, col)

    # Chest pale-slate armored plate scales
    for row_i, py in enumerate(range(32, 45, 3)):
        w = 8 - row_i // 2
        c.rect(25, py, w, 2, "CS")
        c.line(25, py, 25 + w - 1, py, "CS2")

    # Sculpted Cranium & Tapered 3/4 Dragon Snout
    c.ellipse(20.5, 18.5, 9.0, 6.8, "O1")
    c.ellipse(19.5, 17.5, 7.5, 5.2, "O2")
    c.ellipse(19.0, 16.0, 5.0, 2.8, "O3")
    # Tapered muzzle curving out toward nostril tip (x=24..41)
    for x in range(24, 42):
        frac = (x - 24) / 17.0
        top_y = int(16 + frac * 3.8 + (1 if x > 36 else 0))
        bot_y = int(24 - frac * 2.5)
        for y in range(top_y, bot_y + 1):
            col = "O1"
            if y == top_y:
                col = "O3"
            elif y <= top_y + 2:
                col = "O2"
            elif y >= bot_y:
                col = "O0"
            c.pset(x, y, col)
    # Slightly parted lower jaw with pale fangs & chin plates
    c.line(23, 25, 39, 23, "O2")
    c.line(23, 26, 38, 24, "O1")
    c.line(24, 27, 36, 25, "O0")
    c.line(25, 24, 38, 22, "K")
    c.pset(36, 22, "L0")  # front fang
    c.pset(32, 23, "L1")  # mid fang
    c.pset(28, 24, "L1")
    # Nasal horn & glowing nostril ember
    c.line(37, 18, 40, 14, "C3")
    c.line(38, 19, 41, 15, "C1")
    c.pset(39, 19, "Y1")

    # Brow ridge & Soulful Luminous Amber Eye
    c.line(21, 16, 28, 15, "O3")
    c.rect(22, 17, 6, 4, "O0")
    c.rect(23, 18, 4, 2, "Y1")
    c.pset(23, 18, "Y2")
    c.pset(26, 19, "Y0")
    c.rect(25, 18, 1, 2, "K")   # Vertical dragon pupil
    c.pset(24, 18, "Y3")        # Tender catchlight

    # Prominent Crimson Hunter Ballista Wound & Snapped Quarrel at Shoulder
    c.ellipse(14.5, 36.5, 4.5, 2.8, "BLD")
    c.ellipse(14.0, 36.0, 2.5, 1.5, "BLD2")
    c.line(14, 35, 5, 25, "T2")
    c.line(15, 36, 6, 26, "T0")
    c.line(13, 35, 5, 27, "T3")
    # Torn crimson fletching on broken bolt
    c.rect(4, 23, 5, 4, "I1")
    c.line(5, 24, 8, 25, "I2")
    c.pset(13, 37, "BLD2")

    # Outer outline polish around dragon silhouette
    c.rect_outline(0, 0, 48, 48, "K")
    c.rect_outline(1, 1, 46, 46, "Y0")
    c.line(1, 1, 45, 1, "Y2")
    c.line(1, 1, 1, 45, "Y2")
    c.save_png(os.path.join(sprites_dir, "portrait_dragon_black.png"))


def _make_golden_hatchling_portraits(sprites_dir: str):
    """
    Hand-sculpted 48x48 Golden Prophecy Dragonet portraits (Stages 1-4, open + _blink):
    High-res (~2.2x) camera-facing zoom matching the overworld Hatchling sprite
    (`dragon_gold_s1_down`). Preserves the signature obsidian-black and luminous
    gold trim aesthetic across all hatchling stages, gradually refining gold chest
    filigree, wing spars, forehead crest, and slightly taller horns.
    """
    def _soot_coat_col(dist_norm: float, stage: int, top_lit: bool) -> str:
        edge = dist_norm > 0.72
        if edge:
            return "O0"
        if stage >= 4 and top_lit and dist_norm < 0.22:
            return "O3"
        return "O2" if top_lit else "O1"

    stages = [
        ("portrait_hatchling_stage1", 1, (32, 29, 60, 255), (15, 14, 30, 255)),
        ("portrait_hatchling_stage2", 2, (36, 30, 58, 255), (17, 14, 28, 255)),
        ("portrait_hatchling_stage3", 3, (42, 32, 54, 255), (19, 15, 25, 255)),
        ("portrait_hatchling_stage4", 4, (50, 36, 46, 255), (22, 16, 22, 255)),
    ]
    for stem, stage, bg_top, bg_bot in stages:
        for blink in (False, True):
            c = PixelCanvas(48, 48)
            _paint_portrait_frame(c, bg_top, bg_bot)

            # Subtle far-corner starlight motes
            if stage >= 2:
                c.pset(6, 8, "Y1" if stage == 2 else ("Y2" if stage == 3 else "Y3"))
                c.pset(41, 9, "Y1" if stage < 4 else "Y2")
            if stage >= 3:
                c.pset(7, 40, "Y1")
                c.pset(41, 39, "Y2")

            d = PixelCanvas(48, 48)

            # 1. Gracefully Arched Scalloped Dragonet Wings (deep soot membrane + gold wing-bone & trim)
            w_lift = 1 if stage == 1 else (0 if stage <= 3 else -1)
            for side in (-1, 1):
                apex_dx = 12
                tip_dx = 17
                apex_y = 21 + w_lift
                tip_y = 25 + w_lift
                for dx in range(7, tip_dx + 1):
                    wx = 24 + side * dx
                    if dx <= apex_dx:
                        t_arm = (dx - 7) / float(apex_dx - 7)
                        top_y = int(round(29 + w_lift - t_arm * (29 + w_lift - apex_y)))
                    else:
                        t_out = (dx - apex_dx) / float(tip_dx - apex_dx)
                        top_y = int(round(apex_y + t_out * (tip_y - apex_y)))
                    if dx <= 10:
                        bot_y = 36 + w_lift - ((dx - 7) // 2)
                    elif dx <= 14:
                        bot_y = 33 + w_lift - (dx - 10)
                    else:
                        bot_y = 29 + w_lift - (dx - 14) * 2
                    if dx in (9, 12, 13, 15):
                        bot_y -= 1
                    for wy in range(top_y, bot_y + 1):
                        is_rib = (dx == 10 and wy > top_y + 2) or (dx == 14 and wy > top_y + 1)
                        if wy == bot_y:
                            col = "Y1" if stage >= 4 and dx in (10, 14, 17) else "O0"
                        elif is_rib:
                            col = "Y1" if stage >= 3 else "O2"
                        else:
                            col = "O0"
                        d.pset(wx, wy, col)
                spar_col = "Y1" if stage == 1 else ("Y2" if stage <= 3 else "Y3")
                rim_col = "O3" if stage == 1 else ("Y1" if stage == 2 else "Y2")
                d.line(24 + side * 7, 29 + w_lift, 24 + side * apex_dx, apex_y, spar_col)
                d.line(24 + side * apex_dx, apex_y, 24 + side * tip_dx, tip_y, spar_col)
                d.line(24 + side * 7, 30 + w_lift, 24 + side * apex_dx, apex_y + 1, rim_col)
                d.line(24 + side * apex_dx, apex_y + 1, 24 + side * tip_dx, tip_y + 1, rim_col)
                d.pset(24 + side * apex_dx, apex_y - 1, "C4" if stage <= 2 else "L0")
                d.pset(24 + side * tip_dx, tip_y, "Y2" if stage <= 2 else "Y3")

            # 2. Plump Obsidian Body & Chest with progressive Gold Seam Filigree
            bx, by = 24.0, 35.5
            brx, bry = 9.4, 10.6
            for y in range(25, 46):
                for x in range(13, 36):
                    norm = ((x - bx) / brx) ** 2 + ((y - by) / bry) ** 2
                    if norm <= 1.0:
                        d.pset(x, y, _soot_coat_col(norm, stage, norm < 0.36))
            # Signature black-and-gold chest pattern (organic ember seams in S1 -> refined royal filigree by S4)
            d.pset(21, 33, "Y1" if stage <= 2 else "Y2")
            d.rect(22, 34, 2, 1, "Y2" if stage <= 2 else "Y3")
            d.pset(25, 33, "Y1" if stage <= 2 else "Y2")
            d.line(20, 36, 21, 38, "Y1" if stage == 1 else "Y2")
            d.rect(23, 37, 2, 2, "Y3" if stage < 4 else "L0")
            d.line(26, 36, 27, 38, "Y1" if stage == 1 else "Y2")
            d.pset(22, 41, "Y2" if stage <= 2 else "Y3")
            d.pset(25, 42, "Y1" if stage <= 2 else "Y2")
            if stage >= 2:
                d.line(21, 31, 26, 31, "Y1" if stage == 2 else "Y2")
            if stage >= 3:
                d.line(19, 39, 21, 42, "Y2")
                d.line(28, 39, 26, 42, "Y2")
            if stage >= 4:
                d.line(22, 35, 25, 35, "Y3")
                d.line(21, 43, 26, 43, "Y2")

            # 3. Symmetrical Diverging Black-and-Gold Horns & Cheek Tufts (gradual growth across Stages 1-4)
            h_h = 4 + (stage - 1)
            for side in (-1, 1):
                for s in range(h_h + 1):
                    hx_p = 24 + side * (6 + (s * 3) // max(1, h_h))
                    hy_p = 13 - s
                    w = 2 if s <= h_h // 2 else 1
                    if stage == 1:
                        h_col = "C3" if s >= h_h - 1 else "Y1"
                    elif stage == 2:
                        h_col = "Y3" if s >= h_h - 1 else "Y1"
                    else:
                        h_col = "L0" if s >= h_h else ("Y3" if s >= h_h // 2 else "Y2")
                    d.rect(hx_p - (1 if w == 2 and side < 0 else 0), hy_p, w, 1, h_col)
                d.rect(24 + side * 10 - (1 if side < 0 else 0), 21, 2, 2, "O3" if stage == 1 else ("Y1" if stage <= 3 else "Y2"))

            # 4. Plump Centered Facing-Camera Obsidian Dragonet Head
            hx, hy = 24.0, 20.2
            hrx, hry = 10.6, 8.6
            for y in range(11, 30):
                for x in range(13, 36):
                    norm = ((x - hx) / hrx) ** 2 + ((y - hy) / hry) ** 2
                    if norm <= 1.0:
                        d.pset(x, y, _soot_coat_col(norm, stage, norm < 0.38 and y < hy + 1))

            # Forehead golden diamond crest (intensifies gently Stages 1->4 while staying obsidian-headed)
            d.rect(23, 13, 2, 2, "Y2" if stage < 4 else "Y3")
            d.pset(23, 15, "Y1" if stage <= 2 else "Y2")
            d.pset(24, 15, "Y1" if stage <= 2 else "Y2")
            d.pset(23, 12, "Y2" if stage <= 2 else "L0")
            d.pset(24, 12, "Y2" if stage <= 2 else "L0")
            if stage >= 3:
                d.pset(21, 14, "Y1" if stage == 3 else "Y2")
                d.pset(26, 14, "Y1" if stage == 3 else "Y2")

            # 5. BIG Luminous Expressive Camera-Facing Baby-Dragon Eyes (Open or Happy-Blink!)
            for side in (-1, 1):
                ex0 = 16 if side < 0 else 28
                ey0 = 17
                # Soft golden brow filigree hint (slightly brighter at Stage 3-4)
                d.line(ex0, ey0 - 1, ex0 + 3, ey0 - 1, "O3" if stage == 1 else ("Y1" if stage <= 3 else "Y2"))
                if blink:
                    # Peaceful curved crescent closed eyes + soft golden lash highlight
                    iris_x = ex0 if side < 0 else ex0 + 1
                    d.line(iris_x, ey0 + 2, iris_x + 3, ey0 + 2, "O0")
                    d.line(iris_x + 1, ey0 + 2, iris_x + 2, ey0 + 2, "K")
                    d.line(iris_x, ey0 + 3, iris_x + 3, ey0 + 3, "K")
                    d.line(iris_x, ey0 + 4, iris_x + 3, ey0 + 4, "Y1" if stage <= 2 else "Y2")
                    d.pset(iris_x + (0 if side < 0 else 3), ey0 + 2, "Y2")
                else:
                    d.rect(ex0, ey0, 4, 6, "O0")
                    d.rect(ex0 - 1 if side < 0 else ex0 + 1, ey0 + 1, 5, 4, "O0")
                    iris_x = ex0 if side < 0 else ex0 + 1
                    d.rect(iris_x, ey0 + 1, 4, 4, "Y2" if stage <= 3 else "Y3")
                    d.line(iris_x, ey0 + 4, iris_x + 3, ey0 + 4, "Y1" if stage <= 2 else "Y2")
                    pup_x = iris_x + 1
                    d.rect(pup_x, ey0 + 1, 2, 3, "K")
                    d.pset(iris_x + (3 if side < 0 else 0), ey0 + 2, "K")
                    d.pset(iris_x + 1, ey0 + 1, "L0")
                    d.pset(iris_x, ey0 + 2, "L0")
                    d.pset(iris_x + (2 if side < 0 else 1), ey0 + 4, "Y3")

            # 6. Soft Centered Baby Snout Button + Twin Nostrils + Gentle Warm Smile
            d.rect(22, 23, 4, 2, "O3" if stage <= 2 else "Y1")
            d.pset(22, 25, "O0" if stage <= 2 else "Y0")
            d.pset(25, 25, "O0" if stage <= 2 else "Y0")
            d.line(21, 26, 26, 26, "O0")
            d.line(22, 27, 25, 27, "O2" if stage == 1 else ("Y1" if stage <= 3 else "Y2"))

            d.add_outline("DO", selective_hue=True)
            c.blit(d, 0, 0)
            _finish_dragon_portrait_border(c)
            suffix = "_blink.png" if blink else ".png"
            c.save_png(os.path.join(sprites_dir, stem + suffix))


def _make_narrator_portrait(sprites_dir: str):
    """Illuminated medieval parchment scroll & quill emblem for Narrator lines."""
    c = PixelCanvas(48, 48)
    _paint_portrait_frame(c, (44, 36, 32, 255), (24, 20, 22, 255))

    # Rolled medieval parchment scroll
    c.rect(11, 10, 24, 28, "L1")
    c.rect(12, 11, 22, 26, "L0")
    c.rect(10, 8, 26, 4, "H2")
    c.rect(10, 36, 26, 4, "H1")
    c.line(10, 8, 35, 8, "H3")
    # Ink script lines on parchment
    for sy in range(15, 32, 4):
        c.line(15, sy, 28 if sy != 27 else 23, sy, "T1")
    # Crimson Brotherhood wax seal
    c.circle(28, 30, 4, "I0")
    c.circle(28, 30, 3, "I1")
    c.pset(27, 29, "I2")
    # Diagonal feather quill
    c.line(23, 27, 36, 12, "L0")
    c.line(24, 27, 37, 13, "Y2")
    c.line(22, 28, 24, 26, "Y1")

    c.rect_outline(0, 0, 48, 48, "K")
    c.rect_outline(1, 1, 46, 46, "Y0")
    c.save_png(os.path.join(sprites_dir, "portrait_narrator.png"))


def _finish_dragon_portrait_border(c: PixelCanvas):
    c.rect_outline(0, 0, 48, 48, "K")
    c.rect_outline(1, 1, 46, 46, "Y0")
    c.line(1, 1, 45, 1, "Y2")
    c.line(1, 1, 1, 45, "Y2")


def _make_virelai_portrait(sprites_dir: str):
    """
    Hand-sculpted 48x48 dialogue portrait of Anna's courier dragon Virelai:
    emerald scales, swept stone-grey horns, keen amber eye, and leather neck-harness.
    """
    c = PixelCanvas(48, 48)
    _paint_portrait_frame(c, (24, 54, 46, 255), (12, 22, 22, 255))

    # Crisp wind streaks & high-altitude sparkle
    for sx, sy, col in ((8, 9, "G2"), (38, 8, "E3"), (41, 15, "Y1"), (6, 20, "E2")):
        c.pset(sx, sy, col)

    # Folded left emerald wing edge rising behind neck
    for y in range(16, 36):
        wx0 = max(5, 8 - (y - 16) // 4)
        wx1 = 14 - (y - 16) // 5
        for x in range(wx0, wx1):
            c.pset(x, y, "E0" if x < wx1 - 1 else "E2")
    c.line(6, 16, 12, 22, "E3")

    # Swept stone-grey courier horns & emerald dorsal frill
    c.line(18, 13, 6, 5, "C3")
    c.line(18, 14, 7, 6, "C2")
    c.line(18, 15, 8, 7, "C0")
    c.line(22, 11, 13, 3, "C3")
    c.line(22, 12, 14, 4, "C1")
    c.line(15, 22, 10, 18, "E3")
    c.line(14, 27, 9, 24, "E2")

    # Proud emerald neck & pale-sage throat armor (y=22..45)
    for y in range(22, 46):
        x0 = max(7, 13 - (y - 22) // 3)
        x1 = min(34, 28 + (y - 22) // 3)
        for x in range(x0, x1):
            col = "E1"
            if x < x0 + 2 or x > x1 - 3:
                col = "E0"
            elif (x + y) % 4 == 0 and x < 24:
                col = "E2"
            c.pset(x, y, col)
    for row_i, py in enumerate(range(30, 45, 3)):
        w = 8 - row_i // 2
        c.rect(24, py, w, 2, "G2")
        c.line(24, py, 24 + w - 1, py, "G3")

    # Sculpted courier cranium & proud tapered emerald snout
    c.ellipse(20.0, 18.0, 8.8, 6.4, "E1")
    c.ellipse(19.0, 17.0, 7.2, 4.8, "E2")
    c.ellipse(18.5, 15.5, 4.6, 2.5, "E3")
    for x in range(24, 42):
        frac = (x - 24) / 17.0
        top_y = int(15 + frac * 3.8 + (1 if x > 36 else 0))
        bot_y = int(23 - frac * 2.2)
        for y in range(top_y, bot_y + 1):
            col = "E1"
            if y == top_y:
                col = "E3"
            elif y <= top_y + 2:
                col = "E2"
            elif y >= bot_y:
                col = "E0"
            c.pset(x, y, col)

    # Jaw with agile confident half-grin & clean tip fang
    c.line(23, 24, 39, 22, "E2")
    c.line(23, 25, 38, 23, "E1")
    c.line(24, 26, 36, 24, "E0")
    c.line(26, 23, 38, 21, "K")
    c.pset(39, 20, "K")
    c.pset(35, 22, "L0")
    # Nose spur & puff of steam
    c.line(37, 17, 40, 13, "C3")
    c.pset(39, 18, "L0")

    # Keen bright amber eye
    c.line(21, 15, 28, 14, "E3")
    c.rect(22, 16, 6, 4, "E0")
    c.rect(23, 17, 4, 2, "Y2")
    c.pset(26, 18, "Y1")
    c.rect(25, 17, 1, 2, "K")
    c.pset(24, 17, "Y3")

    # Heavy Leather Courier Neck-Harness & Chest Strap + Brass Buckle
    c.line(12, 29, 30, 33, "T0")
    c.line(12, 30, 30, 34, "T2")
    c.line(11, 31, 30, 35, "T1")
    for i in range(13):
        c.pset(13 + i, 33 + i, "T0")
        c.pset(14 + i, 33 + i, "T2")
    # Brass D-ring harness buckle at throat/chest
    c.rect(25, 31, 5, 5, "Y0")
    c.rect(26, 32, 3, 3, "Y2")
    c.pset(26, 32, "Y3")
    c.pset(27, 33, "T1")

    _finish_dragon_portrait_border(c)
    c.save_png(os.path.join(sprites_dir, "portrait_virelai.png"))


def _make_greyling_portraits(sprites_dir: str):
    """
    Hand-sculpted 48x48 Silver Greyling ('Kestrel') growth portraits:
      - `portrait_greyling.png` (Year 1): shorter downy tufts, wide shy golden eye, cliffsage linen bandage
      - `portrait_greyling_y3.png` (Year 3): sleeker angular muzzle, longer swept ear plumes, healed pale scar, apprentice leather strap
      - `portrait_greyling_y5.png` (Year 5): proud adult silver cranium, twin long crown plumes, fierce amber eye & courier dispatch harness
    """
    for stage, fname in (("y1", "portrait_greyling.png"), ("y3", "portrait_greyling_y3.png"), ("y5", "portrait_greyling_y5.png")):
        c = PixelCanvas(48, 48)
        bg_top = (36, 48, 66, 255) if stage == "y1" else ((34, 54, 70, 255) if stage == "y3" else (28, 44, 64, 255))
        _paint_portrait_frame(c, bg_top, (16, 22, 34, 255))

        for sx, sy, col in ((8, 8, "SG3"), (39, 9, "W5"), (40, 17, "SG2"), (7, 16, "SG2")):
            c.pset(sx, sy, col)

        # Tucked delicate silver wing shoulder (broader shoulder armor by Year 5)
        w_off = 0 if stage == "y1" else (1 if stage == "y3" else 2)
        for y in range(18 - w_off, 38):
            wx0 = max(6, 9 - (y - 18) // 4 - w_off)
            wx1 = 14 - (y - 18) // 6 + w_off
            for x in range(wx0, wx1):
                c.pset(x, y, "SG0" if x < wx1 - 1 else "SG2")
        c.line(7, 18 - w_off, 12 + w_off, 23, "W5" if stage == "y5" else "SG3")

        # Swept Greyling silver ear-crest plumes (growing distinctly fuller & longer from Y1 -> Y3 -> Y5)
        if stage == "y1":
            c.line(18, 15, 9, 10, "SG3")
            c.line(18, 16, 10, 11, "SG2")
            c.line(19, 14, 13, 8, "W5")
            c.line(16, 17, 10, 14, "SG1")
        elif stage == "y3":
            c.line(18, 14, 6, 7, "SG3")
            c.line(18, 15, 7, 8, "SG2")
            c.line(19, 13, 10, 4, "W5")
            c.line(20, 13, 12, 5, "SG2")
            c.line(16, 16, 8, 12, "SG1")
        else:
            # Majestic double adult crown plumes & cheek crest
            c.line(17, 14, 4, 5, "W5")
            c.line(18, 15, 5, 6, "SG3")
            c.line(18, 16, 7, 8, "SG2")
            c.line(20, 13, 8, 3, "W5")
            c.line(21, 13, 10, 4, "SG3")
            c.line(15, 17, 5, 11, "SG3")
            c.line(16, 18, 7, 13, "SG1")

        # Agile neck & pale belly scutes (broader chest from Y3 -> Y5)
        neck_grow = 0 if stage == "y1" else (1 if stage == "y3" else 3)
        for y in range(22, 46):
            x0 = max(8, 14 - neck_grow - (y - 23) // 4)
            x1 = min(34, 27 + neck_grow + (y - 23) // 4)
            for x in range(x0, x1):
                col = "SG1"
                if x < x0 + 2 or x > x1 - 3:
                    col = "SG0"
                elif (x + y) % 4 == 0 and x < 23:
                    col = "SG2"
                c.pset(x, y, col)
        for py in range(30, 45, 3):
            c.rect(24 + neck_grow // 2, py, 6, 2, "SG3")
            c.line(24 + neck_grow // 2, py, 29 + neck_grow // 2, py, "W5")

        # Cranium & sleek tapering courier snout (longer & sharper in Y3/Y5)
        snout_reach = 38 if stage == "y1" else (41 if stage == "y3" else 43)
        c.ellipse(20.0, 18.5, 7.6 + neck_grow * 0.35, 5.6 + neck_grow * 0.2, "SG1")
        c.ellipse(19.2, 17.5, 6.2 + neck_grow * 0.3, 4.2 + neck_grow * 0.15, "SG2")
        c.ellipse(18.5, 16.0, 3.8, 2.2, "W5" if stage == "y5" else "SG3")
        for x in range(24, snout_reach):
            frac = (x - 24) / float(snout_reach - 24)
            top_y = int(16 + frac * (3.8 if stage == "y1" else 3.2))
            bot_y = int(22 - frac * 1.8)
            for y in range(top_y, bot_y + 1):
                col = "SG1"
                if y == top_y:
                    col = "W5" if stage == "y5" else "SG3"
                elif y <= top_y + 1:
                    col = "SG2"
                elif y >= bot_y:
                    col = "SG0"
                c.pset(x, y, col)
        c.line(24, 23, snout_reach - 2, 21, "K")
        c.line(24, 24, snout_reach - 3, 22, "SG2")
        c.line(25, 25, snout_reach - 5, 23, "SG0")
        c.pset(snout_reach - 3, 19, "K")

        # Expressive Golden-Amber Eye (soft/wide in Y1, razor-keen courier gaze by Y5)
        c.line(21, 15, 27, 15, "W5" if stage == "y5" else "SG3")
        c.rect(22, 16, 5, 4 if stage == "y1" else 3, "SG0")
        c.rect(23, 17, 3, 2, "Y2")
        c.pset(25, 18, "Y1")
        c.rect(24, 17, 1, 2, "K")
        c.pset(23, 17, "Y3")
        if stage == "y5":
            c.line(20, 15, 28, 16, "SG0")  # Sterner proud adult brow ridge
            c.line(21, 14, 27, 15, "W5")

        if stage == "y1":
            # Cream linen Cliffsage Poultice Bandage wrapped over shoulder & lower neck
            for by in range(32, 43):
                bx0 = max(9, 13 - (by - 32) // 3)
                bx1 = min(29, 25 + (by - 32) // 3)
                c.line(bx0, by, bx1, by, "L1" if (by % 2 == 0) else "L0")
                c.pset(bx0, by, "L2")
                c.pset(bx1, by, "L2")
            c.line(12, 33, 25, 41, "L2")
            c.line(13, 32, 26, 40, "L0")
            c.rect(15, 36, 5, 3, "E2")
            c.rect(16, 37, 3, 1, "E3")
            c.rect(11, 35, 3, 3, "L0")
            c.line(10, 38, 12, 41, "L2")
        elif stage == "y3":
            # Faint pale healed wing-scar + Brotherhood apprentice chest strap & brass tag
            c.line(10, 31, 14, 34, "W5")
            c.line(10, 35, 29, 44, "T0")
            c.line(11, 34, 30, 43, "T1")
            c.line(12, 33, 31, 42, "T2")
            c.rect(20, 38, 3, 3, "Y1")
            c.pset(21, 39, "Y3")
        else:
            # Full Adult Light Brotherhood Courier Rigging: double harness strap, carabiner clasp & hemp dispatch roll
            c.line(8, 34, 29, 45, "T0")
            c.line(9, 33, 31, 44, "T1")
            c.line(10, 32, 32, 43, "T2")
            c.line(11, 31, 33, 42, "T3")
            # Hemp courier satchel / dispatch tube tucked at lower left shoulder
            c.rect(8, 35, 7, 8, "H1")
            c.line(9, 36, 13, 36, "H3")
            c.line(8, 40, 14, 40, "T1")
            # Brass Brotherhood chest medallion buckle
            c.rect(20, 36, 5, 5, "Y0")
            c.rect(21, 37, 3, 3, "Y2")
            c.pset(22, 38, "I2")
            c.pset(21, 37, "Y3")

        _finish_dragon_portrait_border(c)
        c.save_png(os.path.join(sprites_dir, fname))


def generate_all_portraits(sprites_dir: str):
    _paint_human_bust(
        "portrait_boy_neutral.png", sprites_dir,
        bg_top=(46, 56, 76, 255), bg_bot=(24, 26, 38, 255),
        tunic_dark="U0", tunic_mid="U1", tunic_light="U2",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="U2", freckles=True,
    )
    _paint_human_bust(
        "portrait_boy_angry.png", sprites_dir,
        bg_top=(78, 34, 34, 255), bg_bot=(32, 18, 22, 255),
        tunic_dark="U0", tunic_mid="U1", tunic_light="U2",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="U2", angry=True, freckles=True,
    )
    _paint_human_bust(
        "portrait_clara.png", sprites_dir,
        bg_top=(72, 46, 56, 255), bg_bot=(32, 22, 28, 255),
        tunic_dark="D0", tunic_mid="D1", tunic_light="D2",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="G2", is_female=True, braid=True, smile=True, rosy_cheeks=True,
    )
    _paint_human_bust(
        "portrait_uncle.png", sprites_dir,
        bg_top=(56, 50, 48, 255), bg_bot=(26, 24, 26, 255),
        tunic_dark="C0", tunic_mid="C1", tunic_light="C2",
        hair_dark="GR0", hair_mid="GR1", hair_light="GR2",
        eye_col="C2", beard_style="full_grey", hat_style="knit_cap", age_lines=True,
    )
    _paint_human_bust(
        "portrait_shipmaster.png", sprites_dir,
        bg_top=(38, 60, 82, 255), bg_bot=(18, 30, 44, 255),
        tunic_dark="U0", tunic_mid="U1", tunic_light="U2",
        hair_dark="GR0", hair_mid="GR1", hair_light="GR2",
        eye_col="W3", beard_style="full_grey", hat_style="mariner", age_lines=True, stern=True,
    )
    _paint_human_bust(
        "portrait_quartermaster.png", sprites_dir,
        bg_top=(66, 52, 38, 255), bg_bot=(30, 24, 20, 255),
        tunic_dark="T0", tunic_mid="T1", tunic_light="T2",
        hair_dark="B0", hair_mid="B0", hair_light="B1",
        eye_col="T2", beard_style="trimmed_dark", collar_scarf=True, stern=True,
    )
    _paint_human_bust(
        "portrait_inquisitor.png", sprites_dir,
        bg_top=(84, 22, 26, 255), bg_bot=(26, 14, 18, 255),
        tunic_dark="I0", tunic_mid="I1", tunic_light="I2",
        hair_dark="S", hair_mid="C0", hair_light="C1",
        eye_col="R2", hat_style="inquisitor", angry=True, age_lines=True,
    )
    _paint_human_bust(
        "portrait_watchman.png", sprites_dir,
        bg_top=(68, 32, 34, 255), bg_bot=(20, 18, 24, 255),
        tunic_dark="I0", tunic_mid="I1", tunic_light="CS2",
        hair_dark="B0", hair_mid="B1", hair_light="C3",
        eye_col="R2", beard_style="trimmed_dark", stern=True, angry=True,
    )
    _paint_human_bust(
        "portrait_baker.png", sprites_dir,
        bg_top=(82, 62, 42, 255), bg_bot=(38, 26, 20, 255),
        tunic_dark="T1", tunic_mid="T2", tunic_light="T3",
        hair_dark="BL0", hair_mid="BL1", hair_light="BL2",
        eye_col="U2", hat_style="baker", smile=True, rosy_cheeks=True, flour_dust=True,
    )
    _paint_human_bust(
        "portrait_anna.png", sprites_dir,
        bg_top=(34, 68, 56, 255), bg_bot=(18, 32, 28, 255),
        tunic_dark="T0", tunic_mid="T1", tunic_light="T2",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="G2", is_female=True, cloak_col="E1", hood=True, smirk=True,
    )
    _paint_human_bust(
        "portrait_brotherhood.png", sprites_dir,
        bg_top=(28, 48, 42, 255), bg_bot=(14, 20, 22, 255),
        tunic_dark="S", tunic_mid="T0", tunic_light="T1",
        hair_dark="S", hair_mid="C0", hair_light="C1",
        eye_col="Y1", cloak_col="E0", hood=True, angry=True,
    )

    # Queue 2 & Queue 4 Sanctuary / Village Portraits
    _paint_human_bust(
        "portrait_hendrick.png", sprites_dir,
        bg_top=(68, 54, 40, 255), bg_bot=(30, 22, 18, 255),
        tunic_dark="T0", tunic_mid="T1", tunic_light="T2",
        hair_dark="GR0", hair_mid="GR1", hair_light="GR2",
        eye_col="C2", beard_style="full_grey", collar_scarf=True,
        shoulder_strap=True, age_lines=True, stern=True,
    )
    _paint_human_bust(
        "portrait_maren.png", sprites_dir,
        bg_top=(34, 62, 52, 255), bg_bot=(16, 30, 26, 255),
        tunic_dark="E0", tunic_mid="E1", tunic_light="E2",
        hair_dark="BL0", hair_mid="BL1", hair_light="BL2",
        eye_col="G2", is_female=True, braid=True, braid_ribbon="E2",
        smile=True, rosy_cheeks=True, collar_scarf=True, apron_bib=True,
    )
    _paint_human_bust(
        "portrait_matthijs.png", sprites_dir,
        bg_top=(40, 68, 58, 255), bg_bot=(18, 32, 30, 255),
        tunic_dark="E0", tunic_mid="E1", tunic_light="E2",
        hair_dark="H0", hair_mid="H1", hair_light="H3",
        eye_col="U2", smirk=True, rosy_cheeks=True, tousled_hair=True,
        closed_collar=True, whistle_clasp=True,
    )
    _paint_human_bust(
        "portrait_cook.png", sprites_dir,
        bg_top=(74, 44, 34, 255), bg_bot=(32, 18, 16, 255),
        tunic_dark="D0", tunic_mid="D1", tunic_light="D2",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="B1", is_female=True, smile=True, rosy_cheeks=True,
        age_lines=True, hat_style="coif", apron_bib=True,
    )
    _paint_human_bust(
        "portrait_herdsman.png", sprites_dir,
        bg_top=(46, 62, 40, 255), bg_bot=(22, 30, 20, 255),
        tunic_dark="T0", tunic_mid="T1", tunic_light="T2",
        hair_dark="H0", hair_mid="H1", hair_light="GR2",
        eye_col="G2", beard_style="sandy_grizzled", scarf_col="E1",
        age_lines=True, rosy_cheeks=True, stern=True,
    )

    # Queue 3 Protagonist Age 14 & Age 17 Portraits
    _paint_human_bust(
        "portrait_boy14_neutral.png", sprites_dir,
        bg_top=(42, 60, 58, 255), bg_bot=(20, 28, 30, 255),
        tunic_dark="T1", tunic_mid="T2", tunic_light="T3",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="U2", freckles=True, scarf_col="E1", shoulder_strap=True,
        tousled_hair=True,
    )
    _paint_human_bust(
        "portrait_boy14_angry.png", sprites_dir,
        bg_top=(74, 36, 32, 255), bg_bot=(30, 16, 18, 255),
        tunic_dark="T1", tunic_mid="T2", tunic_light="T3",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="U2", angry=True, freckles=True, scarf_col="E1",
        shoulder_strap=True, tousled_hair=True,
    )
    _paint_human_bust(
        "portrait_boy17_neutral.png", sprites_dir,
        bg_top=(32, 58, 50, 255), bg_bot=(16, 26, 26, 255),
        tunic_dark="T0", tunic_mid="T1", tunic_light="T2",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="U2", cloak_col="E0", hood_down=True, closed_collar=True,
        smirk=True, scar=True, tousled_hair=True,
    )
    _paint_human_bust(
        "portrait_boy17_angry.png", sprites_dir,
        bg_top=(78, 30, 30, 255), bg_bot=(32, 14, 16, 255),
        tunic_dark="T0", tunic_mid="T1", tunic_light="T2",
        hair_dark="B0", hair_mid="B1", hair_light="B2",
        eye_col="U2", cloak_col="E0", hood_down=True, closed_collar=True,
        angry=True, scar=True, tousled_hair=True,
    )

    _make_black_dragon_portrait(sprites_dir)
    _make_golden_hatchling_portraits(sprites_dir)
    _make_virelai_portrait(sprites_dir)
    _make_greyling_portraits(sprites_dir)
    _make_narrator_portrait(sprites_dir)

    # Queue 9 Father Anselm (Cathedral Priest of St. Donatian)
    _paint_human_bust(
        "portrait_priest.png", sprites_dir,
        bg_top=(52, 42, 64, 255), bg_bot=(24, 20, 32, 255),
        tunic_dark="O0", tunic_mid="O1", tunic_light="O2",
        hair_dark="GR0", hair_mid="GR1", hair_light="GR2",
        eye_col="U1", stern=True, age_lines=True,
        tonsure=True, clerical_stole=True,
    )
