"""
Modular Empty-Hands Protagonist Carry Poses + Wardrobe Helper for Temeraire.

Replaces N x M bespoke full-body carry sprite explosion with ONLY 2 reusable empty-hands
carrier postures across 3 cardinal directions x 3 walk frames (18 sprites total):
  1. Overhead Carry (`boy_carry_hands_{down,up,side}_{0,1,2}.png`) — crates, leather bales, barrels
  2. Chest Cradle (`boy_cradle_hands_{down,up,side}_{0,1,2}.png`) — Dragon Egg, water pail, fish, parcels

Godot's PlayerBoy overlays ANY item (`prop_*.png` / `icon_*.png`) dynamically in
Bram's hands via `carry_prop_sprite` with automatic directional z-ordering and walk bob.
"""

import os
from sprite_char_common import STD_LEGEND, _build_canvas_from_ascii, _assert_grounded
from sprite_boy_walk import (
    BOY_DOWN_0, BOY_DOWN_1, BOY_DOWN_2,
    BOY_UP_0, BOY_UP_1, BOY_UP_2,
    BOY_SIDE_0, BOY_SIDE_1, BOY_SIDE_2,
)

# Empty-hands torso replacements (rows 13..19; legs 20..27 & head 0..12 stay intact from walk frames)
_TORSO_OVERHEAD = {
    "down": {
        7:  "....sS...........Ss.....",
        8:  "....sS...........Ss.....",
        9:  "....dm...........md.....",
        10: "....dm...........md.....",
        11: "....dm...........md.....",
        12: "....dl...........ld.....",
        13: ".....dmmddqqqddmmd......",
        14: ".....ddmlqqqqqlmdd......",
        15: "......dmlmmmmmlmd.......",
        16: "......dmlmmmmmlmd.......",
        17: "......ddmmmmmmmdd.......",
        18: "......dttttGttttd.......",
        19: ".......dtttGtttd........",
    },
    "up": {
        6:  "....sS............Ss....",
        7:  "....sS............Ss....",
        8:  "....dm............md....",
        9:  "....dm............md....",
        10: "....dm............md....",
        11: "....dl............ld....",
        12: ".....dm..........md.....",
        13: ".....dmmddqqqqddmmmd....",
        14: "......ddmmmmmmmmdd......",
        15: "......dmlmmmmmmlmd......",
        16: "......dmmmmmmmmmmd......",
        17: ".......dmmmmmmmmd.......",
        18: ".......dmmmmmmmmd.......",
        19: ".......dtttttttd........",
    },
    "side": {
        9:  "................dlsS....",
        10: "...............dmlsS....",
        11: "..............dmlmd.....",
        12: "..............dmlmd.....",
        13: "........dmllqmddmd......",
        14: ".......dmmmmmmmmd.......",
        15: ".......dmlmmmmmd........",
        16: ".......dmmmmmmmd........",
        17: ".......dmmmmmmmd........",
        18: ".......dtttttttd........",
        19: "........tttttttd........",
    },
}

_TORSO_CRADLE = {
    "down": {
        13: "........ddqqqdd.........",
        14: "......ddmlqqqlmdd.......",
        15: ".....dmllmmmmmlmmd......",
        16: ".....ddmsSS.SSsmdd......",
        17: ".....ddmsSS.SSsmdd......",
        18: "......ddtmmGmmtdd.......",
        19: ".......dtttGtttd........",
    },
    "up": {
        13: "........ddqqqdd.........",
        14: "......ddmmmmmmmdd.......",
        15: ".....dmllmmmmmmlmd......",
        16: ".....dmmmmmmmmmmmd......",
        17: "......ddmmmmmmmdd.......",
        18: ".......dmmmmmmmmd.......",
        19: ".......dtttttttd........",
    },
    "side": {
        13: "........dmllqmd.........",
        14: ".......dmmmmmmmd........",
        15: ".......dmmlmssSd........",
        16: ".......dmmttssSS........",
        17: ".......dmtttsSS.........",
        18: "........tttttttd........",
        19: "........dmmmmmd.........",
    },
}

_WALK_BASES = {
    "down": (BOY_DOWN_0, BOY_DOWN_1, BOY_DOWN_2),
    "up": (BOY_UP_0, BOY_UP_1, BOY_UP_2),
    "side": (BOY_SIDE_0, BOY_SIDE_1, BOY_SIDE_2),
}


def _apply_arm_pose(base_grid: list[str], arm_rows: dict[int, str], bob_arms: bool = False) -> list[str]:
    grid = list(base_grid)
    for r_idx, row_str in arm_rows.items():
        assert len(row_str) == 24, f"Carry pose row {r_idx} length {len(row_str)} != 24"
        ty = r_idx + (1 if (bob_arms and r_idx <= 12) else 0)
        if 0 <= ty < 20:
            if r_idx < 13:
                # Merge arms subtly around existing hair/face without erasing head interior
                cur = list(grid[ty])
                for x, ch in enumerate(row_str):
                    if ch != ".":
                        cur[x] = ch
                grid[ty] = "".join(cur)
            else:
                grid[ty] = row_str
    return grid


def build_modular_carry_frames(grid_transform=None) -> dict[str, list[str]]:
    frames: dict[str, list[str]] = {}
    for posture_name, table in (("carry_hands", _TORSO_OVERHEAD), ("cradle_hands", _TORSO_CRADLE)):
        for dname in ("down", "up", "side"):
            bases = _WALK_BASES[dname]
            arm_rows = table[dname]
            for step in (0, 1, 2):
                grid = _apply_arm_pose(bases[step], arm_rows, bob_arms=False)
                fname = f"boy_{posture_name}_{dname}_{step}.png"
                if grid_transform is not None:
                    grid = grid_transform(fname, grid)
                frames[fname] = grid
    return frames


def generate_modular_boy_carry(
    sprites_dir: str,
    boy_prefix: str = "boy_",
    cloth_overrides: dict | None = None,
    grid_transform=None,
) -> int:
    legend = {**STD_LEGEND, "c": "C2", "w": "C4", "L": "L1"}
    if cloth_overrides:
        legend.update(cloth_overrides)
    frames = build_modular_carry_frames(grid_transform=grid_transform)
    for fname, grid in frames.items():
        out_name = fname.replace("boy_", boy_prefix, 1)
        _assert_grounded(out_name, grid)
        _build_canvas_from_ascii(grid, legend).save_png(os.path.join(sprites_dir, out_name))
    return len(frames)
