"""
Age-evolved Protagonist Tier Generator (`boy14_*` Age 14 Apprentice & `boy17_*` Age 17 Senior).
Reuses the canonical 24x28 8-directional walk + action pose + modular `kit_boy_carry`
grids while scaling physique proportionally (keeping feet strictly grounded at y=24)
and applying rich medieval Brotherhood wardrobe transformations.
"""

import os
from sprite_char_common import STD_LEGEND, _build_canvas_from_ascii, _assert_grounded
from sprite_boy_walk import BOY_WALK_FRAMES
from sprite_boy_poses import BOY_POSE_FRAMES
from kit_boy_carry import generate_modular_boy_carry


_STATIC_CROUCH_PREFIXES = ("boy_roll", "boy_kneel")


def _grow_grid_vertically(grid: list[str], extra_leg: int = 0, extra_torso: int = 0) -> list[str]:
    """
    Grow standing 24x28 grids upward while keeping boot soles anchored at y=24:
    - extra_leg: shifts rows 0..21 up 1px and duplicates trouser row 21.
    - extra_torso: shifts rows 0..15 up 1px and duplicates chest row 15.
    """
    g = list(grid)
    if extra_leg:
        out = list(g)
        for y in range(21):
            out[y] = g[y + 1]
        out[21] = g[21]
        g = out
    if extra_torso:
        out = list(g)
        for y in range(15):
            out[y] = g[y + 1]
        out[15] = g[15]
        g = out
    return g


def _paint_strap_on_row(row: str, strap_x: int, char: str, clasp_char: str | None = None) -> str:
    """Paint diagonal strap / clasp cleanly inside filled tunic pixels only (`d`, `m`, `l`)."""
    chars = list(row)
    if 0 <= strap_x < len(chars) and chars[strap_x] in ("d", "m", "l"):
        chars[strap_x] = clasp_char or char
    if 0 <= strap_x + 1 < len(chars) and chars[strap_x + 1] in ("m", "l"):
        chars[strap_x + 1] = char
    return "".join(chars)


def _evolve_boy_grid(fname: str, grid: list[str], tier: int) -> list[str]:
    """Apply proportional height growth + chest harness accents for `tier` in (14, 17)."""
    if fname.startswith(_STATIC_CROUCH_PREFIXES):
        return list(grid)

    if tier == 14:
        g = _grow_grid_vertically(grid, extra_leg=0, extra_torso=1)
        strap_start_y, buckle_y, strap_char, clasp = 13, 15, "T", "j"
    else:
        g = _grow_grid_vertically(grid, extra_leg=1, extra_torso=1)
        strap_start_y, buckle_y, strap_char, clasp = 12, 14, "j", "Y"

    is_front_or_back = (
        fname in ("boy_idle.png", "boy_kneel.png", "boy_blindfold.png", "boy_throw.png")
        or "_down_" in fname
        or "_up_" in fname
    )
    if is_front_or_back:
        # Subtle diagonal sling (Age 14) or oiled leather chest harness & brass D-ring (Age 17)
        span = 6 if "_up_" in fname else 4
        start_x = 8 if "_up_" in fname else 9
        for dy in range(span):
            ry = strap_start_y + dy
            if 0 <= ry < len(g):
                c_at = clasp if (ry == buckle_y and "_up_" not in fname) else strap_char
                g[ry] = _paint_strap_on_row(g[ry], start_x + dy, strap_char, c_at)
    return g


def _tier_legend(tier: int) -> dict[str, str | None]:
    base = {**STD_LEGEND, "c": "C2", "w": "C4", "L": "L1"}
    if tier == 14:
        # Age 14 Rig-Apprentice: warm tanned wyrm-hide leather + emerald Brotherhood scarf collar
        return {
            **base,
            "d": "T0",
            "m": "T2",
            "l": "T3",
            "a": "E0",
            "A": "E1",
            "q": "E2",
            "j": "E1",
            "k": "S",
            "t": "O1",
            "T": "T1",
            "u": "T3",
            "b": "O0",
            "B": "T0",
        }
    # Age 17 Senior Flight-Jerkin: weathered forest-emerald coat + oiled dark leather harness + brass rings
    return {
        **base,
        "d": "E0",
        "m": "E1",
        "l": "E2",
        "a": "C1",
        "A": "L1",
        "q": "L0",
        "j": "T0",
        "Y": "Y3",
        "k": "S",
        "t": "T0",
        "T": "T1",
        "u": "T2",
        "b": "O0",
        "B": "T0",
    }


def generate_boy_tiers(sprites_dir: str) -> int:
    """Generate all 51 Age-14 (`boy14_*`) and 51 Age-17 (`boy17_*`) sprites (102 total)."""
    total = 0
    base_walk = {k: v for k, v in BOY_WALK_FRAMES.items() if not k.startswith("boy_carry")}
    standing_and_poses = {**base_walk, **BOY_POSE_FRAMES}

    for tier, prefix in ((14, "boy14_"), (17, "boy17_")):
        legend = _tier_legend(tier)
        for fname, grid in standing_and_poses.items():
            out_name = fname.replace("boy_", prefix, 1)
            evolved = _evolve_boy_grid(fname, grid, tier)
            _assert_grounded(out_name, evolved)
            _build_canvas_from_ascii(evolved, legend).save_png(os.path.join(sprites_dir, out_name))
            total += 1

        total += generate_modular_boy_carry(
            sprites_dir,
            boy_prefix=prefix,
            cloth_overrides=legend,
            grid_transform=lambda fname, grid, t=tier: _evolve_boy_grid(fname, grid, t),
        )
    return total
