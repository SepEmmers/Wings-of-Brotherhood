"""
Handcrafted 24x28 3/4 Top-Down Pixel-Art Characters
(8-directional animated Boy + 8 distinct Bruges/Brotherhood NPCs).
Facade delegating sprite grids to sprite_boy_walk, sprite_boy_poses, and sprite_npcs.
"""

import os
from sprite_char_common import STD_LEGEND, _build_canvas_from_ascii, _assert_grounded
from sprite_boy_walk import BOY_WALK_FRAMES
from sprite_boy_poses import BOY_POSE_FRAMES, BOY_EGG_CARRY_FRAMES, _make_boy_carry_egg
from sprite_npcs import ALL_NPCS


def generate_all_characters(sprites_dir: str):
    boy_legend = {**STD_LEGEND, "c": "C2", "w": "C4", "L": "L1"}

    for fname, grid in {**BOY_WALK_FRAMES, **BOY_POSE_FRAMES}.items():
        _assert_grounded(fname, grid)
        _build_canvas_from_ascii(grid, boy_legend).save_png(os.path.join(sprites_dir, fname))

    for fname, grid in BOY_EGG_CARRY_FRAMES.items():
        _assert_grounded(fname, grid)
        _make_boy_carry_egg(grid).save_png(os.path.join(sprites_dir, fname))

    for fname, (grid, legend) in ALL_NPCS.items():
        _assert_grounded(fname, grid)
        _build_canvas_from_ascii(grid, legend).save_png(os.path.join(sprites_dir, fname))
        if "_" not in os.path.splitext(fname)[0].split("npc_", 1)[-1]:
            stem = fname[:-4]
            f0_name = f"{stem}_0.png"
            f1_name = f"{stem}_1.png"
            if f0_name not in ALL_NPCS:
                _build_canvas_from_ascii(grid, legend).save_png(os.path.join(sprites_dir, f0_name))
            if f1_name not in ALL_NPCS:
                # Subtle 1px breathing frame keeping lower legs & grounded boots anchored at row 24!
                breath_grid = ["." * 24] + list(grid[:18]) + [grid[18]] + list(grid[20:])
                _assert_grounded(f1_name, breath_grid)
                _build_canvas_from_ascii(breath_grid, legend).save_png(os.path.join(sprites_dir, f1_name))
