"""
Simple-box placeholder generator for uncompleted sprites listed in docs/SPRITE_TRACKER.md.

Feature-building agents register new visuals here AND in docs/SPRITE_TRACKER.md (`- [ ]`).
When the Sprite-Making Agent finishes a sprite and flips its line to `- [x]`,
this script automatically skips regenerating that file so real pixel art is preserved.
"""

import os
from pixel_art_lib import PixelCanvas
from sprite_boy_walk import BOY_WALK_FRAMES
from kit_boy_carry import build_modular_carry_frames
from sprite_boy_poses import BOY_POSE_FRAMES


def _load_completed_keys(sprites_dir: str):
    tracker = os.path.abspath(os.path.join(sprites_dir, "..", "..", "docs", "SPRITE_TRACKER.md"))
    done = set()
    if not os.path.exists(tracker):
        return done
    with open(tracker, "r", encoding="utf-8") as fh:
        for line in fh:
            s = line.strip()
            if s.startswith("- [x]") or s.startswith("- [X]"):
                parts = s.split("`")
                if len(parts) >= 2:
                    done.add(parts[1].strip())
    return done


def _box(c: PixelCanvas, x: int, y: int, w: int, h: int, fill, outline="K"):
    c.rect(x, y, w, h, fill)
    c.rect_outline(x, y, w, h, outline)


def _make_box_character(fname: str, torso_col: str, trim_col: str, hair_col: str, badge_col=None) -> PixelCanvas:
    """24x28 readable geometric box character keeping feet grounded around y=24."""
    c = PixelCanvas(24, 28)
    c.rect(7, 24, 10, 2, (16, 18, 22, 85))

    if "roll" in fname:
        _box(c, 5, 11, 14, 12, torso_col)
        c.rect(7, 13, 10, 4, trim_col)
        step = 0 if "_0" in fname else (1 if "_1" in fname else 2)
        c.rect(7 + step * 3, 17, 4, 4, hair_col)
        return c

    if "kneel" in fname:
        _box(c, 6, 15, 12, 7, torso_col)
        c.rect(7, 16, 10, 2, trim_col)
        _box(c, 6, 21, 5, 4, "T0")
        _box(c, 13, 21, 5, 4, "T0")
        _box(c, 7, 7, 10, 8, "P2")
        c.rect(7, 7, 10, 3, hair_col)
        c.rect(9, 11, 2, 2, "K")
        c.rect(13, 11, 2, 2, "K")
        return c

    l_shift = -2 if ("_1" in fname or "walk1" in fname) else 0
    r_shift = -2 if ("_2" in fname or "walk2" in fname) else 0
    _box(c, 7, 20 + l_shift, 4, 5, "T0")
    _box(c, 13, 20 + r_shift, 4, 5, "T0")

    _box(c, 6, 12, 12, 9, torso_col)
    c.rect(7, 13, 10, 2, trim_col)
    if badge_col:
        c.rect(10, 16, 4, 4, badge_col)

    _box(c, 7, 4, 10, 8, "P2")
    c.rect(7, 4, 10, 3, hair_col)
    if "up" in fname:
        c.rect(7, 5, 10, 6, hair_col)
    elif "blindfold" in fname:
        c.rect(7, 7, 10, 3, "L1")
    elif "side" in fname:
        c.rect(14, 8, 2, 2, "K")
    elif "diag_down" in fname:
        c.rect(11, 8, 2, 2, "K")
        c.rect(14, 8, 2, 2, "K")
    else:
        c.rect(9, 8, 2, 2, "K")
        c.rect(13, 8, 2, 2, "K")

    if "knife" in fname:
        _box(c, 17, 14, 6, 3, "C4")
    elif "throw" in fname:
        _box(c, 17, 12, 5, 3, trim_col)
    elif "carry_egg" in fname:
        _box(c, 8, 13, 8, 7, "O2")
        c.rect(11, 15, 2, 2, "Y2")
    elif "carry" in fname:
        _box(c, 7, 8, 10, 6, "T2")
    return c


def _make_box_portrait(bg, robe_col: str, trim_col: str, hair_col: str, is_dragon: bool = False, angry: bool = False, beard: bool = False) -> PixelCanvas:
    """48x48 simple box portrait placeholder with framed border."""
    c = PixelCanvas(48, 48)
    _box(c, 0, 0, 48, 48, bg, "K")
    c.rect_outline(2, 2, 44, 44, "I1" if angry else "Y1")

    if is_dragon:
        _box(c, 11, 30, 18, 15, robe_col)
        _box(c, 11, 33, 18, 5, trim_col)
        _box(c, 11, 15, 19, 16, robe_col)
        _box(c, 26, 20, 12, 9, robe_col)
        _box(c, 9, 9, 6, 6, trim_col)
        _box(c, 24, 9, 6, 6, trim_col)
        _box(c, 22, 18, 4, 4, "Y2")
        return c

    _box(c, 9, 31, 30, 15, robe_col)
    _box(c, 15, 31, 18, 6, trim_col)
    _box(c, 20, 27, 8, 5, "P2")
    _box(c, 14, 10, 20, 18, "P2")
    _box(c, 14, 9, 20, 6, hair_col)
    _box(c, 13, 12, 3, 7, hair_col)
    _box(c, 32, 12, 3, 7, hair_col)
    if beard:
        _box(c, 16, 23, 16, 7, hair_col)
    c.rect(18, 19, 3, 3, "K")
    c.rect(27, 19, 3, 3, "K")
    c.rect(17, 16 if not angry else 17, 5, 2, "I1" if angry else hair_col)
    c.rect(26, 16 if not angry else 17, 5, 2, "I1" if angry else hair_col)
    c.rect(21, 24, 6, 2, "K" if angry else "P0")
    return c


def _make_box_prop(w: int, h: int, boxes) -> PixelCanvas:
    """Create a WxH placeholder made strictly of bordered colored rectangles."""
    c = PixelCanvas(w, h)
    for x, y, bw, bh, col in boxes:
        _box(c, x, y, bw, bh, col)
    return c


_PROP_AND_ICON_BOXES = {
    "prop_leather_rack.png": (28, 24, [(4, 5, 4, 16, "T0"), (20, 5, 4, 16, "T0"), (2, 4, 24, 3, "T2"), (7, 7, 6, 10, "T2"), (14, 7, 6, 9, "E1")]),
    "prop_leather_bale.png": (16, 16, [(2, 4, 12, 9, "T2"), (5, 4, 2, 9, "H1"), (9, 4, 2, 9, "H1")]),
    "prop_herb_cauldron.png": (24, 24, [(6, 17, 12, 4, "Y1"), (4, 7, 16, 11, "C0"), (6, 8, 12, 3, "E2")]),
    "prop_spring_well.png": (28, 24, [(3, 7, 22, 14, "C2"), (10, 4, 8, 5, "C2"), (6, 10, 16, 8, "W3")]),
    "prop_water_bucket.png": (16, 16, [(5, 2, 6, 4, "C3"), (4, 6, 8, 8, "T2"), (5, 6, 6, 3, "W4")]),
    "prop_drying_herbs.png": (24, 20, [(2, 3, 20, 14, "T1"), (5, 6, 3, 9, "G2"), (10, 6, 4, 9, "E2"), (16, 6, 3, 9, "G3")]),
    "prop_map_table.png": (36, 24, [(5, 14, 4, 8, "T0"), (27, 14, 4, 8, "T0"), (3, 4, 30, 12, "T2"), (7, 6, 16, 8, "L1"), (25, 7, 5, 5, "Y1")]),
    "icon_jerkin.png": (16, 16, [(3, 3, 10, 10, "T2"), (3, 3, 3, 4, "E0"), (10, 3, 3, 4, "E0"), (6, 8, 4, 3, "Y2")]),
    "icon_poultice.png": (16, 16, [(6, 2, 4, 3, "H1"), (4, 5, 8, 9, "C2"), (5, 7, 6, 5, "E2")]),
    "prop_herring_bucket.png": (22, 20, [(5, 8, 12, 9, "T2"), (6, 5, 4, 4, "SG2"), (12, 5, 4, 4, "SG3")]),
    "prop_herring_fish.png": (16, 12, [(3, 4, 8, 4, "SG2"), (11, 3, 3, 6, "SG1")]),
    "prop_knot_drill_board.png": (26, 26, [(10, 13, 6, 11, "T0"), (3, 3, 20, 11, "T2"), (6, 6, 3, 3, "Y2"), (12, 6, 3, 3, "E2"), (19, 12, 3, 8, "Y1")]),
    # Sanctuary Covert Village: Housing, Tents, Stalls, Mess, Dragon Feeding & Pastures
    "bldg_covert_lodge.png": (96, 80, [(8, 28, 80, 46, "L1"), (10, 58, 76, 16, "C1"), (4, 8, 88, 28, "T1"), (8, 10, 80, 12, "G0"), (38, 46, 18, 28, "T0"), (16, 40, 14, 12, "Y2"), (66, 40, 14, 12, "Y2")]),
    "bldg_covert_cottage.png": (88, 72, [(8, 26, 72, 40, "C2"), (62, 4, 12, 22, "C3"), (4, 10, 80, 22, "R1"), (10, 12, 28, 10, "G1"), (34, 42, 16, 24, "T0"), (14, 36, 12, 11, "Y2"), (58, 36, 12, 11, "Y2")]),
    "bldg_feed_barn.png": (88, 72, [(8, 28, 72, 38, "T2"), (4, 10, 80, 24, "CS"), (34, 14, 20, 12, "H2"), (26, 40, 17, 26, "T0"), (45, 40, 17, 26, "T0"), (12, 38, 10, 10, "T1"), (66, 38, 10, 10, "T1")]),
    "prop_tent_green.png": (52, 44, [(6, 14, 40, 26, "E1"), (10, 8, 32, 12, "E2"), (22, 22, 8, 18, "T0"), (3, 32, 4, 8, "T1"), (45, 32, 4, 8, "T1")]),
    "prop_tent_tan.png": (48, 40, [(6, 12, 36, 24, "H1"), (10, 7, 28, 10, "L1"), (20, 20, 8, 16, "T0"), (3, 28, 4, 8, "T1"), (41, 28, 4, 8, "T1")]),
    "prop_stall_food.png": (48, 36, [(4, 6, 4, 26, "T1"), (40, 6, 4, 26, "T1"), (2, 3, 44, 11, "R2"), (12, 3, 10, 11, "L0"), (28, 3, 10, 11, "L0"), (4, 19, 40, 11, "T2"), (8, 14, 10, 6, "Y2"), (20, 15, 10, 5, "T3"), (33, 13, 6, 7, "C3")]),
    "prop_stall_gear.png": (48, 36, [(4, 6, 4, 26, "T1"), (40, 6, 4, 26, "T1"), (2, 3, 44, 11, "E1"), (14, 3, 8, 11, "L1"), (28, 3, 8, 11, "L1"), (4, 19, 40, 11, "T2"), (8, 14, 9, 6, "H2"), (20, 14, 8, 6, "T0"), (32, 13, 6, 7, "Y2")]),
    "prop_mess_table.png": (56, 28, [(4, 2, 48, 5, "T1"), (3, 9, 50, 10, "T2"), (4, 21, 48, 5, "T1"), (10, 11, 8, 6, "L0"), (24, 11, 8, 6, "C3"), (38, 11, 6, 6, "T3")]),
    "prop_stew_pot.png": (24, 24, [(6, 17, 12, 4, "Y1"), (9, 3, 6, 4, "T1"), (5, 7, 14, 11, "C0"), (7, 8, 10, 3, "H2"), (15, 5, 3, 7, "T3")]),
    "prop_dragon_pavilion.png": (72, 48, [(6, 14, 6, 30, "T1"), (60, 14, 6, 30, "T1"), (12, 26, 48, 16, "H2"), (3, 4, 66, 16, "G0"), (8, 6, 56, 7, "CS")]),
    "prop_dragon_feed_rack.png": (36, 32, [(4, 6, 4, 23, "T0"), (28, 6, 4, 23, "T0"), (2, 5, 32, 4, "T2"), (7, 9, 8, 13, "D1"), (17, 9, 9, 12, "R2"), (10, 10, 3, 4, "L0")]),
    "prop_water_trough.png": (32, 20, [(2, 5, 28, 12, "T2"), (6, 4, 4, 14, "C1"), (22, 4, 4, 14, "C1"), (5, 7, 22, 7, "W3"), (8, 8, 10, 3, "W4")]),
    "prop_hay_bale.png": (24, 20, [(3, 5, 18, 12, "H1"), (5, 6, 14, 5, "H2"), (8, 5, 2, 12, "T1"), (14, 5, 2, 12, "T1")]),
    "prop_fence_h.png": (32, 16, [(2, 3, 5, 11, "T1"), (25, 3, 5, 11, "T1"), (0, 6, 32, 3, "T2"), (0, 11, 32, 3, "T2")]),
    "prop_fence_v.png": (12, 32, [(3, 1, 6, 30, "T2"), (2, 2, 8, 5, "T1"), (2, 14, 8, 5, "T1"), (2, 25, 8, 5, "T1")]),
    # Trim & ration items use sprite_sanctuary.py; Queue 6 capture shackles use sprite_sanctuary.py too.
}


def _make_box_virelai_eat(frame: int) -> PixelCanvas:
    """88x72 simple-box Virelai eating reaction & tail-wag animation placeholder."""
    c = PixelCanvas(88, 72)
    tail_dx = -7 if frame == 0 else 7
    head_dy = 2 if frame == 0 else 4
    # Swept emerald wing boxes
    _box(c, 4, 24, 31, 18, "E1")
    _box(c, 53, 24, 31, 18, "E1")
    _box(c, 8, 38, 25, 5, "E2")
    _box(c, 55, 38, 25, 5, "E2")
    # Tail wagging left/right along top edge (y=4..21)
    _box(c, 41 + int(tail_dx * 0.5), 11, 6, 11, "E1")
    _box(c, 40 + tail_dx, 4, 8, 8, "E2")
    # Harnessed torso
    _box(c, 35, 19, 18, 25, "E1")
    _box(c, 35, 25, 18, 3, "T1")
    _box(c, 35, 34, 18, 3, "H1")
    _box(c, 42, 23, 4, 16, "T2")
    # Head leaning down to chomp with jaws open (_0) vs shut happy + spark (_1)
    _box(c, 37, 43 + head_dy, 14, 14, "E1")
    _box(c, 34, 42 + head_dy, 4, 5, "C3")
    _box(c, 50, 42 + head_dy, 4, 5, "C3")
    c.rect(39, 48 + head_dy, 2, 2, "Y2")
    c.rect(47, 48 + head_dy, 2, 2, "Y2")
    if frame == 0:
        _box(c, 39, 55 + head_dy, 10, 6, "R2")
        _box(c, 41, 56 + head_dy, 6, 3, "L0")
    else:
        _box(c, 39, 55 + head_dy, 10, 4, "E2")
        _box(c, 30, 50, 3, 3, "Y2")
        _box(c, 55, 50, 3, 3, "Y2")
    return c


def _make_box_animal(kind: str, frame: int) -> PixelCanvas:
    """Two-frame grazing/idle geometric box livestock placeholder."""
    shift = 1 if frame == 1 else 0
    if kind == "sheep":
        c = PixelCanvas(20, 16)
        _box(c, 5, 11 - shift, 3, 4, "T0")
        _box(c, 12, 11, 3, 4, "T0")
        _box(c, 4, 4, 11, 8, "L0")
        _box(c, 13, 5 + shift, 5, 5, "C0")
        c.rect(16, 7 + shift, 1, 1, "EW")
        return c
    if kind == "cow":
        c = PixelCanvas(28, 22)
        _box(c, 5, 15 - shift, 4, 6, "B0")
        _box(c, 16, 15, 4, 6, "B0")
        _box(c, 4, 6, 16, 10, "B1")
        _box(c, 9, 7, 6, 5, "L0")
        _box(c, 18, 7 + shift, 7, 7, "B1")
        _box(c, 19, 5 + shift, 2, 2, "H2")
        _box(c, 23, 5 + shift, 2, 2, "H2")
        return c
    # pig
    c = PixelCanvas(18, 14)
    _box(c, 4, 9 - shift, 3, 4, "T0")
    _box(c, 10, 9, 3, 4, "T0")
    _box(c, 3, 4, 10, 6, "PK")
    _box(c, 12, 5 + shift, 4, 4, "R3")
    return c


_NPC_BOXES = {}

_VILLAGE_NPC_BOXES = {
    "villager_cook": ("D1", "L0", "B1", "Y2"),
    "villager_herdsman": ("T1", "E1", "BL0", "Y1"),
}


_PORTRAIT_SPECS = {
    "portrait_boy14_neutral.png": ((42, 60, 58, 255), "T2", "E1", "B1", False, False, False),
    "portrait_boy14_angry.png": ((74, 38, 34, 255), "T2", "E1", "B1", False, True, False),
    "portrait_boy17_neutral.png": ((38, 62, 54, 255), "T1", "E0", "B1", False, False, False),
    "portrait_boy17_angry.png": ((76, 36, 32, 255), "T1", "E0", "B1", False, True, False),
    "portrait_hendrick.png": ((68, 54, 40, 255), "T1", "L1", "GR1", False, False, True),
    "portrait_maren.png": ((36, 62, 52, 255), "E1", "L1", "BL1", False, False, False),
    "portrait_matthijs.png": ((42, 66, 56, 255), "E2", "Y2", "BL1", False, False, False),
    "portrait_cook.png": ((72, 46, 38, 255), "D1", "L0", "B1", False, False, False),
    "portrait_herdsman.png": ((50, 62, 42, 255), "T1", "E1", "BL0", False, False, True),
    "portrait_virelai.png": ((26, 62, 54, 255), "E1", "T2", "E2", True, False, False),
    "portrait_greyling.png": ((42, 52, 66, 255), "SG1", "L1", "SG2", True, False, False),
}


def generate_placeholder_sprites(sprites_dir: str) -> int:
    done = _load_completed_keys(sprites_dir)
    written = 0

    for fname, (w, h, boxes) in _PROP_AND_ICON_BOXES.items():
        if fname in done:
            continue
        _make_box_prop(w, h, boxes).save_png(os.path.join(sprites_dir, fname))
        written += 1

    for kind in ("sheep", "cow", "pig"):
        for frame in (0, 1):
            fname = f"animal_{kind}_{frame}.png"
            if fname in done:
                continue
            _make_box_animal(kind, frame).save_png(os.path.join(sprites_dir, fname))
            written += 1

    for npc_id, (torso, trim, hair, badge) in _NPC_BOXES.items():
        for suffix in ("", "_0", "_1"):
            fname = f"npc_{npc_id}{suffix}.png"
            if fname in done:
                continue
            _make_box_character(fname, torso, trim, hair, badge).save_png(os.path.join(sprites_dir, fname))
            written += 1

    for npc_id, (torso, trim, hair, badge) in _VILLAGE_NPC_BOXES.items():
        for suffix in ("_0", "_1"):
            fname = f"npc_{npc_id}{suffix}.png"
            if fname in done:
                continue
            _make_box_character(fname, torso, trim, hair, badge).save_png(os.path.join(sprites_dir, fname))
            written += 1

    for frame in (0, 1):
        fname = f"dragon_anna_eat_{frame}.png"
        if fname in done:
            continue
        _make_box_virelai_eat(frame).save_png(os.path.join(sprites_dir, fname))
        written += 1

    for fname, spec in _PORTRAIT_SPECS.items():
        if fname in done:
            continue
        _make_box_portrait(*spec).save_png(os.path.join(sprites_dir, fname))
        written += 1

    # Exclude per-item carry duplicates (`boy_carry_*`) — future Boy wardrobe tiers use
    # reusable `carry_hands` + `cradle_hands` empty carrier poses paired with shared props!
    base_walk_keys = [k for k in BOY_WALK_FRAMES.keys() if not k.startswith("boy_carry")]
    carry_hand_keys = list(build_modular_carry_frames().keys())
    all_boy_keys = base_walk_keys + list(BOY_POSE_FRAMES.keys()) + carry_hand_keys
    for tier_prefix, pattern, (torso, trim, hair) in (
        ("boy14_", "boy14_*.png", ("T2", "E1", "B1")),
        ("boy17_", "boy17_*.png", ("E0", "T1", "B1")),
    ):
        if pattern in done:
            continue
        for base_fname in all_boy_keys:
            fname = base_fname.replace("boy_", tier_prefix, 1)
            if fname in done:
                continue
            _make_box_character(fname, torso, trim, hair).save_png(os.path.join(sprites_dir, fname))
            written += 1

    return written
