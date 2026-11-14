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
