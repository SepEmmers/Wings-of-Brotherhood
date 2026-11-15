---
name: pixel-art-generator
description: >-
  Generate and update crisp, palette-locked 2D pixel-art PNG sprites, buildings,
  props, and tilesets for the Wings of the Brotherhood Medieval Fantasy RPG. Use whenever new
  characters, dragons, buildings, UI icons, or map tiles are added or visually
  polished.
---

# Pixel Art Generator Skill

Generates cohesive, outlined, 3/4 top-down Zelda-style pixel-art PNGs using the
32-color Medieval Flemish & Dragon Palette defined in
`.agents/rules/pixel-art-and-visuals.md`.

## Workflow Modes

### A. Sprite-Making Agent Mode (Polishing `- [ ]` Placeholders)
1. Read `docs/SPRITE_TRACKER.md` and pick unchecked `- [ ]` items.
2. Check each entry's exact dimensions (`WxH`), Godot callers, and palette brief against `.agents/rules/pixel-art-and-visuals.md`.
3. Write the finished crisp pixel-art `.png` into `assets/sprites/<filename>` (or add its modular recipe in `kit_buildings.py` / `kit_npcs.py` / `kit_boy_carry.py` or a script under `scripts/` and remove its key from `sprite_placeholders.py`).
4. Cross the entry off (`- [x]`) in `docs/SPRITE_TRACKER.md` so future runs of `generate_pixel_assets.py` preserve the finished art.

### B. Feature Agent Mode (Adding New Placeholder Visuals)
1. **First check if an existing Modular Kit covers it (Mode C):** Before requesting bespoke character poses or carry sprites, verify whether `kit_buildings.py`, `kit_npcs.py`, or `PlayerBoy.CARRY_PROPS` already supports the asset via a recipe or a single `16x16` prop texture.
2. Otherwise register a simple bordered-box placeholder in [sprite_placeholders.py](./scripts/sprite_placeholders.py) at the target dimensions.
3. Add an unchecked `- [ ]` line with dimensions, callers, and art brief in `docs/SPRITE_TRACKER.md`.
4. Run the generator from the repository root:
   `python .agents/skills/pixel-art-generator/scripts/generate_pixel_assets.py`
5. Verify every output `.png` exists inside `assets/sprites/` with non-zero size and loads with `TEXTURE_FILTER_NEAREST` (`default_texture_filter=0`).

### C. Modular Kit Composition (Cities, Crowd NPCs & Carryables — Default for Scale)
Instead of hand-authoring full sprites for every new house, townsfolk NPC, or carried object:
1. **Buildings (`scripts/kit_buildings.py`):** Add a 3-5 line recipe dict specifying `blocks` width (`3..10` × `16px` bays), `wall` (`WALL_PRESETS`), `roof` (`ROOF_PRESETS`), `gable` (`pitched`, `stepped_left`, `stepped_center`, `twin_gable`, `dormer`), `ground` / `upper` bay lists, `chimneys`, `awning`, `sign`, `lantern`, or `ivy`. Never copy-paste bespoke per-house coordinates when the block composer can express it.
2. **Townsfolk & Crew NPCs (`scripts/kit_npcs.py`):** Add a 1-entry recipe specifying `body`, `cloth`/`trim`/`apron` (`OUTFIT_RAMPS`), `skin`, `face`, `hair` + `hair_color`, `hat`, and `prop` — outputs resting + `_0` + `_1` grounded `24x28` sprites automatically.
3. **Protagonist Carryables (`scripts/kit_boy_carry.py` + `PlayerBoy.gd`):** Never author new full-body `24x28` walk cycles per carried item. Add a single `16x16` `prop_*.png` (or reuse `icon_*.png`) and register it in `PlayerBoy.CARRY_PROPS` (using `"overhead"` or `"cradle"`) or call `player.set_carry_prop(tex_name, posture, scale)`. When creating Age-14/Age-17 wardrobe tiers (`boy14_*`, `boy17_*`), pass `cloth_overrides` into `generate_modular_boy_carry(...)` to emit shared `carry_hands_*` and `cradle_hands_*` sets automatically.

### D. Visual Verification Gate (Portraits, 8-Way Sprites & UI Chrome)
1. For new or reworked portraits, 8-way character/companion sheets, or UI chrome textures, generate a magnified nearest-neighbor contact sheet (`Image.Resampling.NEAREST` over a dark neutral backdrop) and inspect silhouettes, outlines, and likeness directly via `read_file` before wiring or finishing.
2. When modifying UI dialogue boxes, `9-slice` styling, clipped layered FX, or portrait motion/framing, also capture a windowed live Godot screenshot (running `.\tools\godot\Godot_v4.3-stable_win64.exe` without `--headless` and saving `get_tree().root.get_texture().get_image()`) and inspect the rendered output via `read_file`.
