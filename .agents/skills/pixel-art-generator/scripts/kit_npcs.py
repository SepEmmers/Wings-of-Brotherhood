"""
Modular Part-Layered 24x28 NPC Composer for Temeraire: Wings of the Brotherhood.

Builds unique villagers, sailors, craftsmen, guards, clerics, and brotherhood crew
from reusable symbolic layers:
  - Body / Outfit Bases (tunic, apron, gown, merchant_coat, sailor_jerkin,
    guard_tabard, cloak_traveller, cleric_robe, runner_jacket)
  - 8 Cloth / Uniform Color Ramps (U navy, E emerald, I crimson, D rose, R brick,
    T leather, C slate, H ochre, L linen)
  - 4 Skin Tones (fair, warm_tan, pale, ruddy)
  - 8 Faces & Beards (youth, kind, stern, freckled, weathered, mustache,
    beard_short, beard_full)
  - 7 Hair Styles x 7 Hair Colors + 6 Headgears + 8 Handheld Props
  - Automatic 3-frame output (resting, _0 idle, _1 subtle breath/prop shift)
  - Grounded row-24 assertions & selective-hue 1px ink outline.
"""

import os
from pixel_art_lib import PAL, PixelCanvas
from sprite_char_common import _assert_grounded

OUTFIT_RAMPS = {
    "navy": ("U0", "U1", "U2"),
    "emerald": ("E0", "E1", "E2"),
    "crimson": ("I0", "I1", "I2"),
    "rose": ("D0", "D1", "D2"),
    "brick": ("R0", "R1", "R2"),
    "saddle_hide": ("T1", "T2", "T3"),
    "leather": ("T0", "T1", "T2"),
    "slate": ("C0", "C1", "C2"),
    "ochre": ("H0", "H1", "H2"),
    "linen": ("L2", "L1", "L0"),
    "brass": ("Y0", "Y1", "Y2"),
}

HAIR_RAMPS = {
    "chestnut": ("B0", "B1", "B2"),
    "blonde": ("BL0", "BL1", "BL2"),
    "sandy": ("H0", "BL1", "H2"),
    "sandy_grizzled": ("H0", "H1", "GR2"),
    "auburn": ("R0", "R1", "B2"),
    "grey": ("GR0", "GR1", "GR2"),
    "dark": ("K", "C0", "C1"),
    "silver": ("CS", "GR1", "L0"),
}

SKIN_RAMPS = {
    "fair": ("P0", "P1", "P2", "P3", "PK"),
    "warm_tan": ("T1", "P0", "P1", "P2", "PK"),
    "pale": ("P0", "P1", "P2", "L0", "PK"),
    "ruddy": ("P0", "P1", "P2", "P3", "D2"),
}

HAT_RAMPS = {
    "dark_felt": ("C0", "S", "C1"),
    "saddle_hide": ("T1", "T2", "T3"),
    "leather": ("T0", "T1", "T2"),
    "linen": ("L2", "L1", "L0"),
    "navy": ("U0", "U1", "U2"),
    "emerald": ("E0", "E1", "E2"),
    "crimson": ("I0", "I1", "I2"),
    "iron": ("C0", "CS", "CS2"),
    "straw": ("H0", "H1", "H2"),
}

# Reusable Body Masks (24x28, boots cleanly grounded at row 24!)
# Channels: d/m/l = primary outfit, t/T/u = secondary trim/apron/vest,
#           q/A/a = white/cream shirt, g/G = brass buckle/clasp,
#           k = dark trousers, b/B = boots, s/S = hands
BODY_MASKS = {
    "tunic_belt": [
        "........................",  # 0..12 left transparent for head
        "........................", "........................", "........................",
        "........................", "........................", "........................",
        "........................", "........................", "........................",
        "........................", "........................", "........................",
        "........ddqqqdd.........",  # 13 neck/collar
        "......ddmmqqqmmdd.......",  # 14 shoulders
        ".....dmmmmlllmmmmd......",  # 15 chest
        "....dmmmmmmgmmmmmmmd....",  # 16 arms + belt clasp (24?) wait: len check below!
    ],
}

# Rebuild clean fixed-width 24-char grids explicitly verified per section!
def _pad_body(body_rows_13_to_24: list[str]) -> list[str]:
    assert len(body_rows_13_to_24) == 12, f"Expected 12 body rows (13..24), got {len(body_rows_13_to_24)}"
    out = ["." * 24 for _ in range(13)] + list(body_rows_13_to_24) + ["." * 24 for _ in range(3)]
    assert len(out) == 28
    for idx, row in enumerate(out):
        assert len(row) == 24, f"Body row {idx} length {len(row)} != 24: '{row}'"
    return out


BODIES = {
    "tunic_belt": _pad_body([
        "........ddqqqdd.........",  # 13
        "......ddmmqqqmmdd.......",  # 14
        ".....dmllmmmmmlmmd......",  # 15
        "....dmmmmmmgmmmmmmd.....",  # 16
        "....sSdmtttGtttdmSs.....",  # 17 hands & buckled belt
        ".....dmmmmmmmmmmmd......",  # 18
        "......ddmmmmmmmdd.......",  # 19 tunic hem
        ".......dkk...kkd........",  # 20 legs
        ".......dkk...kkd........",  # 21
        ".......dkk...kkd........",  # 22
        ".......bBb...bBb........",  # 23 boots
        ".......bbb...bbb........",  # 24 grounded!
    ]),
    "apron_craft": _pad_body([
        "........ddqAqdd.........",  # 13 broad craftsman shoulders
        ".....ddmmttAttmmdd......",  # 14
        "....dmllmtTTTtmllmd.....",  # 15 leather apron bib
        "....dmmmdtTTTtdmmmd.....",  # 16
        "....sSdmttTGTGGtdSs.....",  # 17 belt & brass buckle
        ".....ddmtTTTTTtmdd......",  # 18 apron skirt
        "......ddtTTTTTtdd.......",  # 19
        ".......dtTTTTTtd........",  # 20
        ".......dkk...kkd........",  # 21
        ".......dkk...kkd........",  # 22
        ".......bBb...bBb........",  # 23
        ".......bbb...bbb........",  # 24
    ]),
    "gown_apron": _pad_body([
        "........ddqqqdd.........",  # 13
        "......ddmqqAqqmdd.......",  # 14
        ".....dmmllAAAllmmd......",  # 15 fitted bodice + kerchief
        "....sSdmAAAAAAAmdSs.....",  # 16 hands + apron waist
        "....sSdAAAAAAAAAdSs.....",  # 17
        ".....ddmAAqqqAAmdd......",  # 18
        ".....dmmAAAAAAAmmd......",  # 19 flared gown hem
        ".....ddmAAAAAAAmdd......",  # 20
        "......ddmmmmmmmdd.......",  # 21
        ".......dddmmmddd........",  # 22
        "........bBb..bBb........",  # 23
        "........bbb..bbb........",  # 24
    ]),
    "merchant_coat": _pad_body([
        ".......uudqqqduu........",  # 13 fur/contrast collar lapels
        ".....ddmduqqqudmdd......",  # 14
        "....dmllmdqgqdmmlmd.....",  # 15 buttoned surcoat + gold chain
        "....dmmmmdtttddmmmd.....",  # 16
        "....sSdmmtTGttmmdSs.....",  # 17
        ".....dmmmttGttmmmd......",  # 18 long burgher coat
        ".....ddmmtmmmttmdd......",  # 19
        "......dmmtmmmtmmd.......",  # 20
        "......dkkk...kkkd.......",  # 21
        ".......dkk...kkd........",  # 22
        ".......bBb...bBb........",  # 23
        ".......bbb...bbb........",  # 24
    ]),
    "sailor_jerkin": _pad_body([
        "........aaqqqaa.........",  # 13 open shirt collar
        "......aaddqqqddaa.......",  # 14 striped shirt + jerkin straps
        ".....aaqdmmmmmmdqaa.....",  # 15
        "....aAAdmllGllmmdAAa....",  # 16 rolled sleeves
        "....sSddmmmmmmmddSs.....",  # 17
        ".....dtttttttttttd......",  # 18 rope/leather waist sash
        "......ddmmmmmmmdd.......",  # 19
        ".......kkk...kkk........",  # 20
        ".......kkk...kkk........",  # 21
        ".......bBb...bBb........",  # 22 high seaboots
        ".......bBb...bBb........",  # 23
        ".......bbb...bbb........",  # 24
    ]),
    "guard_tabard": _pad_body([
        ".......CCdqqqdCC........",  # 13 metal shoulder pauldrons
        ".....CCmmdmmmdmmCC......",  # 14
        "....CCmmmlGgGlmmmCC.....",  # 15 crested tabard
        "....kCdmtttttttdCk......",  # 16
        "....sSdmtttGtttdmSs.....",  # 17 gauntlets & belt
        ".....ddmmmmmmmmdd.......",  # 18
        "......dmmmGGGmmd........",  # 19 tabard tail
        "......dkCk...kCkd.......",  # 20 armored greaves
        ".......kCk...kCk........",  # 21
        ".......kCk...kCk........",  # 22
        ".......bBb...bBb........",  # 23
        ".......bbb...bbb........",  # 24
    ]),
    "cloak_traveller": _pad_body([
        ".......ttdqqqdtt........",  # 13 draped cape clasps
        ".....ttmmgmmmggmtt......",  # 14
        "....ttmllmmmmmmlmtt.....",  # 15 sweeping traveler cloak
        "....tdmmmmdmdmmmmdt.....",  # 16
        "...tsSdmtttttttdmSst....",  # 17
        "....tddmmmmmmmmmddt.....",  # 18
        ".....tdmmmmmmmmmmdt.....",  # 19
        "......ddmmmmmmmdd.......",  # 20
        ".......dkk...kkd........",  # 21
        ".......dkk...kkd........",  # 22
        ".......bBb...bBb........",  # 23
        ".......bbb...bbb........",  # 24
    ]),
    "cleric_robe": _pad_body([
        "........ddtqtdd.........",  # 13 draped stole & collar
        "......ddmmtqtmmdd.......",  # 14
        ".....dmmlltqtllmmd......",  # 15
        "....dmmmmmtqtmmmmmd.....",  # 16
        "....sSdmmtGTGtmdmSs.....",  # 17 wide sleeves + corded sash
        ".....ddmmmqqqmmmdd......",  # 18
        ".....ddmmmmqmmmmdd......",  # 19 floor-length robe
        ".....ddmmmmqmmmmdd......",  # 20
        "......dmmmmqmmmmd.......",  # 21
        "......ddddmqmdddd.......",  # 22
        ".......bBb...bBb........",  # 23
        ".......bbb...bbb........",  # 24
    ]),
    "runner_jacket": _pad_body([
        "........ddtuqdd.........",  # 13 cross-strap collar (Bellman/Courier)
        "......ddmmtGmmdd........",  # 14 whistle/brass clasp on chest!
        ".....dmllmmtmmmmd.......",  # 15
        "....dmmmmmmgmmtmd.......",  # 16 diagonal courier strap
        "....sSdmtttGttttmSs.....",  # 17
        ".....ddmmmmmmmmdd.......",  # 18
        "......ddmm...mmdd.......",  # 19 short active tail
        ".......dkk...kkd........",  # 20
        ".......dkk...kkd........",  # 21
        ".......kkk...kkk........",  # 22
        ".......bBb...bBb........",  # 23
        ".......bbb...bbb........",  # 24
    ]),
}

# Bare oval head template (rows 6..12) aligned centered around x=11.5 (cols 6..17)
HEAD_BASE = {
    6: ".......ffSSSSSSff.......",
    7: "......ffSSSSSSSSff......",
    8: "......SSSSSSSSSSSS......",
    9: "......SSSeSSSSSeSS......",
    10: "......SSSwSSSSSwSS......",
    11: "......SpSSSSSSSSpS......",
    12: ".......zzsSSSSszz.......",
}

# Face & Beard Overlays (painted on top of HEAD_BASE; '.' = keep head pixel)
FACE_OVERLAYS = {
    "youth": {},
    "kind": {
        11: "......SpSSpSSpSSpS......",
    },
    "stern": {
        8: "......SShhSSSShhSS......",
        11: "......SsSSSSSSSSsS......",
    },
    "freckled": {
        10: "......SSpwSSSSwpSS......",
        11: "......SpSSpSSpSSpS......",
    },
    "weathered": {
        7: "......fsSSssssSSsf......",
        8: "......sszzSSSSzzss......",
        11: "......ssSSSSSSSSss......",
    },
    "mustache": {
        8: "......SShhSSSShhSS......",
        11: ".......hHHHHHHHHh.......",
    },
    "beard_short": {
        11: "......shSSSSSSSShs......",
        12: ".......hHHHHHHHHh.......",
        13: "........hhhhhhhh........",
    },
    "beard_full": {
        8: "......SShhSSSShhSS......",
        11: "......hHHHhhhhHHHh......",
        12: "......hHHrHHHHHrHh......",
        13: ".......hHHHHHHHHh.......",
        14: "........hhhhhhhh........",
    },
}

# Hair Overlays (rows 3..13 framing face cleanly)
HAIR_OVERLAYS = {
    "short_tousled": {
        3: "........rHHHHrr.........",
        4: ".......HHHHHHHHh........",
        5: "......HhHHHHHHHhh.......",
        6: "......hHrrHHHHrrHh......",
        7: "......hH........Hh......",
        8: "......h..........h......",
    },
    "parted_neat": {
        3: "........HHHHHHr.........",
        4: ".......rHHHHHHHHh.......",
        5: "......hHHHHHHHHHHh......",
        6: "......hHh......hHh......",
        7: "......h..........h......",
    },
    "bob_wavy": {
        3: "........rHHHHr..........",
        4: ".......HHHHHHHH.........",
        5: "......hHHHHHHHHh........",
        6: "......hHh......hHh......",
        7: ".....Hh..........hH.....",
        8: ".....h............h.....",
        9: ".....h............h.....",
        10: ".....h............h.....",
        11: "......h..........h......",
    },
    "braided": {
        3: ".........HHHHr..........",
        4: ".......HHrrrHHHH........",
        5: "......HhHHHHHHHhh.......",
        6: "......Hh........h.......",
        7: ".....Hh..........hH.....",
        8: ".....H............H.....",
        9: ".....r............H.....",
        10: ".....H............H.....",
        11: ".....r............h.....",
        12: ".....H............h.....",
        13: ".....h..................",
        14: ".....r..................",
    },
    "bun_tied": {
        2: ".........rHHr...........",
        3: "........hHHHHh..........",
        4: ".......HHHHHHHH.........",
        5: "......hHHHHHHHHh........",
        6: "......hH........Hh......",
        7: "......h..........h......",
    },
    "receding": {
        4: ".......hhh....hhh.......",
        5: "......hH........Hh......",
        6: "......h..........h......",
        7: "......H..........H......",
        8: "......h..........h......",
    },
    "curly_mop": {
        2: "........rHHrHHr.........",
        3: ".......HHHHHHHHr........",
        4: "......rHHHHHHHHHh.......",
        5: ".....hHHHHHHHHHHHh......",
        6: ".....hHh.......hHh......",
        7: ".....H............H.....",
    },
}

# Headgear Overlays (drawn over hair at crown)
HEADGEAR_OVERLAYS = {
    "none": {},
    "sailor_cap": {
        2: "........ccCCCc..........",
        3: ".......cCCCCCCc.........",
        4: "......cCCCCCCCCc........",
        5: "......ccccCCCCCC........",
    },
    "cloth_coif": {
        3: "........cCCCCc..........",
        4: ".......cCCCCCCc.........",
        5: "......cCCCCCCCCc........",
        6: "......CC......CC........",
        7: ".....cC........Cc.......",
        8: ".....c..........c.......",
    },
    "hood_up": {
        2: "........cCCCCCCc........",
        3: ".......cCCCCCCCCc.......",
        4: "......cCC......CCc......",
        5: "......cC........Cc......",
        6: ".....cC..........Cc.....",
        7: ".....c............c.....",
        8: ".....c............c.....",
        9: "......c..........c......",
    },
    "burgher_hat": {
        2: "........cCCCCCCc........",
        3: ".......cCCCCCCCCc.......",
        4: ".....ccCCCCCCCCCCcc.....",
        5: "......cccccccccccc......",
    },
    "kettle_helm": {
        2: "........ccCCCCcc........",
        3: ".......cCCCCCCCCc.......",
        4: ".....ccCCCCCCCCCCcc.....",
        5: "....ccCCCCCCCCCCCCcc....",
        6: ".....cccccccccccccc.....",
    },
}

# Compact coordinate pixels per frame for optional handheld accessories: (dx, dy, color_key)
# Applied on the character's right (viewer's right, x=18..22) or back strap!
def _draw_handheld_prop(c: PixelCanvas, prop: str, y_bob: int, is_shift: bool) -> None:
    if not prop or prop == "none":
        return
    dy = 1 if is_shift else 0
    if prop == "lantern":
        c.line(19, 15 + y_bob, 19, 17 + y_bob + dy, "S")
        c.rect(18, 17 + y_bob + dy, 3, 4, "S")
        c.rect(19, 18 + y_bob + dy, 1, 2, "Y2")
        c.pset(19, 18 + y_bob + dy, "Y3")
    elif prop == "hammer":
        hy = 13 + y_bob - dy
        c.line(19, hy + 2, 19, hy + 6, "T1")
        c.rect(17, hy, 5, 2, "C2")
        c.line(17, hy, 21, hy, "C3")
    elif prop == "basket":
        c.rect(17, 16 + y_bob + dy, 5, 4, "H1")
        c.line(17, 17 + y_bob + dy, 21, 17 + y_bob + dy, "H0")
        c.line(18, 14 + y_bob + dy, 20, 14 + y_bob + dy, "T2")
        c.pset(18, 15 + y_bob + dy, "G2")
        c.pset(20, 15 + y_bob + dy, "E2")
    elif prop == "satchel":
        c.line(9, 14 + y_bob, 16, 19 + y_bob, "T0")
        c.rect(16, 18 + y_bob, 3, 3, "T2")
        c.pset(17, 19 + y_bob, "Y2")
    elif prop == "halberd":
        c.line(20, 4 - dy, 20, 24, "T1")
        c.rect(19, 3 - dy, 3, 4, "CS2")
        c.pset(21, 2 - dy, "C4")
    elif prop == "scroll":
        c.rect(17, 15 + y_bob + dy, 3, 4, "L0")
        c.pset(18, 16 + y_bob + dy, "I1")
    elif prop == "mug":
        c.rect(17, 15 + y_bob - dy, 3, 4, "T2")
        c.line(17, 15 + y_bob - dy, 19, 15 + y_bob - dy, "L0")
    elif prop == "ladle":
        sway = 1 if is_shift else 0
        c.line(18, 17 + y_bob, 20 + sway, 10 + y_bob, "T2")
        c.line(18, 17 + y_bob, 19 + sway, 11 + y_bob, "T3")
        c.ellipse(18, 18 + y_bob, 2.0, 1.5, "T1")
        c.pset(18, 18 + y_bob, "H2")
    elif prop == "herd_crook":
        c.line(20, 6 + y_bob, 20, 24, "T1")
        c.line(19, 5 + y_bob, 21, 5 + y_bob, "T3")
        c.pset(18, 6 + y_bob, "T2")
        c.pset(18, 13 + y_bob - dy, "Y2")  # Brass herd bell clasp
    elif prop == "arbalest_buckler":
        # Left arm crimson-and-steel kite buckler
        c.rect(3, 14 + y_bob, 4, 6, "CS")
        c.rect(4, 15 + y_bob, 2, 4, "I1")
        c.pset(4, 16 + y_bob, "Y1")
        # Right hand steel-prodded hunting arbalest crossbow
        c.line(18, 13 + y_bob - dy, 18, 19 + y_bob - dy, "T2")
        c.line(16, 14 + y_bob - dy, 21, 14 + y_bob - dy, "CS2")
        c.pset(18, 12 + y_bob - dy, "L0")  # White bolt fletch nocked


def _build_legend(spec: dict) -> dict:
    o_dark, o_mid, o_hi = OUTFIT_RAMPS[spec.get("outfit", "navy")]
    t_dark, t_mid, t_hi = OUTFIT_RAMPS[spec.get("trim", "leather")]
    h_dark, h_mid, h_hi = HAIR_RAMPS[spec.get("hair_color", "chestnut")]
    s_z, s_s, s_base, s_f, s_p = SKIN_RAMPS[spec.get("skin", "fair")]
    hat_c0, hat_c1, hat_c2 = HAT_RAMPS[spec.get("hat_color", "dark_felt")]
    return {
        ".": None,
        "d": o_dark, "m": o_mid, "l": o_hi,
        "t": t_dark, "T": t_mid, "u": t_hi,
        "h": h_dark, "H": h_mid, "r": h_hi,
        "z": s_z, "s": s_s, "S": s_base, "f": s_f, "p": s_p,
        "e": "K", "w": "EW",
        "q": "L0", "A": "L1", "a": "L2",
        "g": "Y0", "G": "Y2",
        "b": "T0", "B": "T1",
        "k": "S", "K": "K",
        "C": "CS2",
        "c": hat_c0, "Q": hat_c1,
    }


def _blit_overlay(grid: list[str], overlay: dict, y_off: int = 0) -> None:
    for row_idx, mask in overlay.items():
        ty = row_idx + y_off
        if 0 <= ty < 28:
            assert len(mask) == 24, f"Overlay row {row_idx} len {len(mask)} != 24"
            base = list(grid[ty])
            for x, ch in enumerate(mask):
                if ch != ".":
                    base[x] = ch
            grid[ty] = "".join(base)


def compose_npc(spec: dict, frame_mode: str = "") -> PixelCanvas:
    """
    Assemble one 24x28 NPC sprite frame (`""`, `"_0"`, or `"_1"`) from modular layers.
      spec keys: body, outfit, trim, skin, face, hair, hair_color, hat, hat_color, prop
    """
    body_id = spec.get("body", "tunic_belt")
    grid = list(BODIES[body_id])
    is_shift = frame_mode == "_1"
    # Upper body + head settles 1px down on _1 breath while keeping rows 21..24 anchored!
    y_bob = 1 if is_shift else 0
    if y_bob != 0:
        # Preserve lower legs & grounded boots (rows 20..27), gently breathe rows 13..18 down onto 14..19
        grid = ["." * 24] * 14 + grid[13:19] + grid[20:28]

    _blit_overlay(grid, HEAD_BASE, y_bob)
    face_id = spec.get("face", "youth")
    if face_id in FACE_OVERLAYS:
        # Handle beard rows extending smoothly onto collar
        _blit_overlay(grid, FACE_OVERLAYS[face_id], y_bob)

    hair_id = spec.get("hair", "short_tousled")
    if hair_id in HAIR_OVERLAYS:
        _blit_overlay(grid, HAIR_OVERLAYS[hair_id], y_bob)

    hat_id = spec.get("hat", "none")
    if hat_id in HEADGEAR_OVERLAYS:
        hat_ov = HEADGEAR_OVERLAYS[hat_id]
        # Remap "C" in hat mask to c/hat_c1 so cloth hats don't turn metallic blue-grey!
        mapped_ov = {}
        for r_i, m_str in hat_ov.items():
            mapped_ov[r_i] = m_str.replace("C", "Q")
        _blit_overlay(grid, mapped_ov, y_bob)

    # Assert grounded at row 24 before painting handheld props (like long halberds)
    _assert_grounded(spec.get("id", "modular_npc"), grid, expected_row=24)

    legend = _build_legend(spec)
    c = PixelCanvas(24, 28)
    for y, line in enumerate(grid):
        for x, ch in enumerate(line):
            key = legend.get(ch)
            if key is not None:
                c.pset(x, y, key)

    _draw_handheld_prop(c, spec.get("prop", "none"), y_bob, is_shift)
    c.add_outline("K", selective_hue=True)
    return c


# Named Ch. 2 Sanctuary NPCs + Reusable Medieval City Crowd Recipes
MODULAR_NPC_RECIPES = {
    # Sanctuary Brotherhood Crew (Replaces Queue 2 Box Placeholders)
    "npc_hendrick": {
        "body": "apron_craft", "outfit": "slate", "trim": "saddle_hide",
        "skin": "warm_tan", "face": "beard_full", "hair": "receding",
        "hair_color": "grey", "hat": "none", "prop": "hammer",
    },
    "npc_maren": {
        "body": "gown_apron", "outfit": "emerald", "trim": "linen",
        "skin": "fair", "face": "kind", "hair": "braided",
        "hair_color": "blonde", "hat": "none", "prop": "basket",
    },
    "npc_matthijs": {
        "body": "runner_jacket", "outfit": "emerald", "trim": "leather",
        "skin": "fair", "face": "freckled", "hair": "short_tousled",
        "hair_color": "sandy", "hat": "none", "prop": "none",
    },
    "npc_villager_cook": {
        "body": "gown_apron", "outfit": "rose", "trim": "linen",
        "skin": "fair", "face": "kind", "hair": "bun_tied",
        "hair_color": "chestnut", "hat": "cloth_coif", "hat_color": "linen", "prop": "ladle",
    },
    "npc_villager_herdsman": {
        "body": "tunic_belt", "outfit": "leather", "trim": "emerald",
        "skin": "fair", "face": "beard_full", "hair": "short_tousled",
        "hair_color": "sandy_grizzled", "hat": "none", "prop": "herd_crook",
    },
    # Diverse Medieval City Citizens (Burghers, Artisans, Sailors, Guards, Clerics)
    "npc_city_burgher": {
        "body": "merchant_coat", "outfit": "brick", "trim": "navy",
        "skin": "ruddy", "face": "mustache", "hair": "parted_neat",
        "hair_color": "chestnut", "hat": "burgher_hat", "hat_color": "dark_felt", "prop": "scroll",
    },
    "npc_city_fishwife": {
        "body": "gown_apron", "outfit": "navy", "trim": "linen",
        "skin": "warm_tan", "face": "kind", "hair": "bun_tied",
        "hair_color": "auburn", "hat": "cloth_coif", "hat_color": "linen", "prop": "basket",
    },
    "npc_city_sailor": {
        "body": "sailor_jerkin", "outfit": "navy", "trim": "ochre",
        "skin": "warm_tan", "face": "beard_short", "hair": "curly_mop",
        "hair_color": "dark", "hat": "sailor_cap", "hat_color": "crimson", "prop": "lantern",
    },
    "npc_city_guard": {
        "body": "guard_tabard", "outfit": "crimson", "trim": "slate",
        "skin": "fair", "face": "stern", "hair": "parted_neat",
        "hair_color": "dark", "hat": "kettle_helm", "hat_color": "iron", "prop": "halberd",
    },
    "npc_city_monk": {
        "body": "cleric_robe", "outfit": "leather", "trim": "linen",
        "skin": "pale", "face": "weathered", "hair": "receding",
        "hair_color": "grey", "hat": "none", "prop": "scroll",
    },
    "npc_city_apprentice": {
        "body": "tunic_belt", "outfit": "ochre", "trim": "leather",
        "skin": "fair", "face": "youth", "hair": "bob_wavy",
        "hair_color": "chestnut", "hat": "none", "prop": "satchel",
    },
    "npc_city_apothecary": {
        "body": "cloak_traveller", "outfit": "slate", "trim": "emerald",
        "skin": "fair", "face": "stern", "hair": "bun_tied",
        "hair_color": "silver", "hat": "hood_up", "hat_color": "emerald", "prop": "lantern",
    },
    "npc_city_cooper": {
        "body": "apron_craft", "outfit": "navy", "trim": "leather",
        "skin": "ruddy", "face": "beard_short", "hair": "curly_mop",
        "hair_color": "auburn", "hat": "none", "prop": "mug",
    },
    "npc_church_hunter": {
        "body": "guard_tabard", "outfit": "slate", "trim": "crimson",
        "skin": "ruddy", "face": "stern", "hair": "parted_neat",
        "hair_color": "dark", "hat": "kettle_helm", "hat_color": "iron",
        "prop": "arbalest_buckler",
    },
    # Historic Louvain Cast & Citizens (Master Mason, 1425 University Scholars, Cloth Inspector)
    "npc_louvain_mason": {
        "body": "apron_craft", "outfit": "ochre", "trim": "slate",
        "skin": "warm_tan", "face": "beard_short", "hair": "parted_neat",
        "hair_color": "sandy_grizzled", "hat": "sailor_cap", "hat_color": "dark_felt", "prop": "hammer",
    },
    "npc_louvain_scholar": {
        "body": "cleric_robe", "outfit": "crimson", "trim": "slate",
        "skin": "pale", "face": "mustache", "hair": "parted_neat",
        "hair_color": "grey", "hat": "burgher_hat", "hat_color": "crimson", "prop": "scroll",
    },
    "npc_louvain_student": {
        "body": "cloak_traveller", "outfit": "navy", "trim": "ochre",
        "skin": "fair", "face": "youth", "hair": "curly_mop",
        "hair_color": "chestnut", "hat": "none", "prop": "satchel",
    },
    "npc_louvain_weaver": {
        "body": "merchant_coat", "outfit": "emerald", "trim": "brass",
        "skin": "ruddy", "face": "kind", "hair": "parted_neat",
        "hair_color": "auburn", "hat": "burgher_hat", "hat_color": "emerald", "prop": "scroll",
    },
}


def generate_modular_npcs(sprites_dir: str) -> int:
    count = 0
    for npc_id, spec in MODULAR_NPC_RECIPES.items():
        spec_with_id = {**spec, "id": npc_id}
        for suffix in ("", "_0", "_1"):
            compose_npc(spec_with_id, suffix).save_png(os.path.join(sprites_dir, f"{npc_id}{suffix}.png"))
            count += 1
    return count
