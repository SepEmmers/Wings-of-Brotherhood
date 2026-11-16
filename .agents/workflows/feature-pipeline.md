# Feature Development Pipeline

Follow this 4-stage pipeline for every new quest, scene, dragon, or visual upgrade:

1. **Stage 1 — Story & Lore Alignment (`lore-research`):**
   - Confirm place names (`Port of Bruges`, `Louvain`, `Old Heverlee`), character voices, and timeline consistency against `docs/game story.txt` and `docs/LORE_COMPENDIUM.md`.
   - Enforce **Diegetic Words & Environmental Storytelling**: in the target vision only real-world words (spoken dialogue + genuinely readable documents/signs) remain. While narrating visuals/inspects temporarily for clarity during feature work, **always log every solo self-talk, visual-action narration, toast box, or non-sign world label as `- [ ]` in `docs/ENVIRONMENTAL_STORYTELLING.md`**, and avoid keybinding spoilers (`[F]`/`[V]`/`[C]`/`[M]`) or explicit puzzle solutions in dialogue.
2. **Stage 2 — Modular Kit Reuse / Placeholder Visuals & Sprite Tracker:**
   - First check if an existing **Modular Kit** covers the need: add a compact recipe in `kit_buildings.py` (`3..10` bay buildings) or `kit_npcs.py` (layered `24x28` NPCs), or register a single `16x16` prop in `PlayerBoy.CARRY_PROPS` / `set_carry_prop(...)` for carried objects instead of creating bespoke full-body sprites.
   - For unique sprites (portraits, dragon breeds, custom props/icons), define a **simple-box placeholder** in `.agents/skills/pixel-art-generator/scripts/sprite_placeholders.py` and add `- [ ]` to `docs/SPRITE_TRACKER.md`.
   - Run `python .agents/skills/pixel-art-generator/scripts/generate_pixel_assets.py` and verify crisp nearest-neighbor rendering.
3. **Stage 3 — Godot 4 Implementation:**
   - Wire quest/state flags in `scripts/GameState.gd`.
   - Implement scene logic, collisions, Y-sorting, carry-prop overlays (`PlayerBoy.set_carry_prop`), and UI in `scripts/` and `scenes/`.
   - For new or expanded regions, reuse `RegionBase` performance helpers from the start: bake static terrain/roads via `setup_static_ground_chunks`, batch repeating water via `setup_water_layer` + `step_water_layer`, cull entities/props via `get_camera_rect`, flip sprites via `PixelAssets.get_tex_flipped(...)` (avoiding per-sprite `draw_set_transform` and broken negative-width `Rect2`s), and cull off-screen `PointLight2D`s with `sync_light_frustum`.
4. **Stage 4 — Headless & Visual Screenshot Verification (`game-verifier`):**
   - Run Godot 4.3 headless smoke check (`tools\smoke_test.ps1`), render real screenshots via `tools\capture_audit.ps1`, and inspect every PNG via `read_file` before reporting completion.
