"""
Master Pixel-Art & Procedural Audio Asset Generator
for Temeraire: Wings of the Brotherhood.

Invokes modular generators in this directory:
  - sprite_characters.py : 24x28 8-directional Boy + 8 Bruges/Brotherhood NPCs
  - sprite_portraits.py  : 48x48 expressive framed dialogue portraits
  - sprite_world.py      : 16x16 seamless tiles, cog, Flemish buildings, animated dragons & props
  - kit_buildings.py     : Modular variable-width (3-10 block) Flemish city buildings
  - kit_npcs.py          : Modular part-layered NPCs (body/skin/face/hair/hat/prop)
  - kit_boy_carry.py     : Modular empty-hands carrier poses (`carry_hands`, `cradle_hands`)
  - audio_synth.py       : 44.1 kHz looping music/ambiences, footsteps, voices & tactile SFX
"""

import os
import sys

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from sprite_characters import generate_all_characters
from sprite_boy_tiers import generate_boy_tiers
from sprite_portraits import generate_all_portraits
from sprite_hatching_cutscene import generate_hatching_cutscene_art
from sprite_heist_cutscene import generate_heist_cutscene_art
from sprite_old_heverlee_shrine import make_old_heverlee_assets
from sprite_placeholders import generate_placeholder_sprites
from kit_buildings import generate_modular_buildings
from kit_interiors import generate_modular_interiors
from kit_npcs import generate_modular_npcs
from kit_boy_carry import generate_modular_boy_carry
from sprite_world import (
    make_tiles,
    make_merchant_cog,
    make_buildings,
    make_dragons,
    make_props_and_icons,
    make_ui_sprites,
)
from audio_synth import generate_all_audio

ROOT_DIR = os.path.abspath(os.path.join(SCRIPTS_DIR, "..", "..", "..", ".."))
SPRITES_DIR = os.path.join(ROOT_DIR, "assets", "sprites")
AUDIO_DIR = os.path.join(ROOT_DIR, "assets", "audio")


def main():
    os.makedirs(SPRITES_DIR, exist_ok=True)
    os.makedirs(AUDIO_DIR, exist_ok=True)

    generate_all_characters(SPRITES_DIR)
    generate_modular_boy_carry(SPRITES_DIR)
    generate_boy_tiers(SPRITES_DIR)
    generate_modular_npcs(SPRITES_DIR)
    generate_all_portraits(SPRITES_DIR)
    make_tiles(SPRITES_DIR)
    make_merchant_cog(SPRITES_DIR)
    make_buildings(SPRITES_DIR)
    generate_modular_buildings(SPRITES_DIR)
    generate_modular_interiors(SPRITES_DIR)
    make_dragons(SPRITES_DIR)
    make_props_and_icons(SPRITES_DIR)
    make_ui_sprites(SPRITES_DIR)
    generate_hatching_cutscene_art(SPRITES_DIR)
    generate_heist_cutscene_art(SPRITES_DIR)
    make_old_heverlee_assets(SPRITES_DIR)
    n_placeholders = generate_placeholder_sprites(SPRITES_DIR)
    generate_all_audio(AUDIO_DIR)

    n_sprites = len([f for f in os.listdir(SPRITES_DIR) if f.endswith(".png")])
    n_audio = len([f for f in os.listdir(AUDIO_DIR) if f.endswith(".wav")])
    print(f"Generated {n_sprites} pixel-art sprites ({n_placeholders} box placeholders) and {n_audio} WAV audio assets.")


if __name__ == "__main__":
    main()
