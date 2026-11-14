# Architecture & Maintainability Rules

These standards keep **Wings of the Brotherhood** modular, collision-free across parallel agents, and easy to navigate without losing context.

## 1. Multi-Agent File Ownership Lanes
When parallel agents operate in the workspace, respect file boundaries to avoid overwriting in-flight edits:
- **Main Game Dev:** `scenes/`, `scripts/*.gd`, `scripts/regions/*.gd`
- **Narrative Improvements:** `docs/game story.txt`, `docs/LORE_COMPENDIUM.md`, `docs/ENVIRONMENTAL_STORYTELLING.md` (`- [ ]` queue tracking any solo self-talk, visual narration, toast boxes, or non-sign labels awaiting real visual/animation replacement so only real-life words remain), and narrative/data tables in `scripts/data/` (`ItemCatalog.gd`, `JournalLoreData.gd`, `KnotCatalog.gd`). Coordinate before modifying live region logic or UI code. Keep dialogue non-hand-holding (no `[F]`/`[V]`/`[C]`/`[M]` key spoilers).
- **Assets & Animations:** `.agents/skills/pixel-art-generator/scripts/*.py` (including modular kits `kit_buildings.py`, `kit_npcs.py`, `kit_boy_carry.py`), `assets/sprites/*.png`, `assets/audio/*.wav`, and `docs/SPRITE_TRACKER.md`. Feature agents check modular kits first (`kit_*` / `PlayerBoy.CARRY_PROPS`), then register **simple-box placeholders** in `sprite_placeholders.py` + `docs/SPRITE_TRACKER.md` (`- [ ]`); the Sprite-Making Agent replaces placeholders with finished pixel art or modular recipes and flips `- [x]`. `PixelAssets.gd` auto-loads every `.png` in `assets/sprites/` via `DirAccess` at startup; whenever adding new `.wav` files, register them in `scripts/SoundManager.gd` (`AMBIENCE_FILES` / `SFX_FILES`).
- **Maintainability & Architecture:** `docs/ARCHITECTURE.md`, `.agents/rules/architecture-and-maintainability.md`, `.agents/skills/maintainability-audit/`, and approved structural refactors when active feature edits pause.

## 2. File Size & Single-Responsibility Guardrails
- **GDScript files:** Target `< 400` lines.
  - `> 500` lines = Refactor warning (extract sub-panels, data tables, or helper subsystems before adding features).
  - `> 800` lines = Split required; do not append another major system onto the same file.
- **UI modules:** Do not add new full-screen overlays or panels directly inside `scripts/GameUI.gd`. Place self-contained panels in `scripts/ui/` (following the pattern of `KnotMinigame.gd`).
- **Narrative & metadata tables:** Keep large dialogue blocks, diary/bestiary entries, and item descriptions out of gameplay/physics code whenever refactoring (`scripts/data/`).
- **Python asset generators:** Avoid growing monolithic `> 1,500`-line generator files; split new character/dragon/world groups into focused submodules imported by `generate_pixel_assets.py`.

## 3. Single Source of Truth Contracts
1. **State & Quest Progression (`scripts/GameState.gd`):**
   - Never guess or invent `GameState.QuestStep` members. Check `scripts/GameState.gd` directly (Book I uses `0..14`: `ON_THE_SHIP` through `ACT4_NIGHT_HEIST`; Book II+ steps append cleanly above `14`).
   - Always check `GameState.gd` for exact method names before calling helpers from UI or regions.
2. **Input Actions (`GameState._ensure_input_actions()`):**
   - Only use registered actions (`move_up`, `move_down`, `move_left`, `move_right`, `interact`, `sprint`, `journal`, `inventory_screen`, `rope_action`, `knife_attack`, `dodge`, `cycle_knot`, `practice_knot`, `toggle_map`, `playtest_menu`).
   - Keep HUD hints, Journal controls text, and `docs/GAME_DESIGN_DOCUMENT.md` aligned with `GameState.gd`.
3. **Regions (`scripts/regions/RegionBase.gd`):**
   - Every playable area/sortie MUST extend `res://scripts/regions/RegionBase.gd` and be registered in:
     1. `scripts/Main.gd` (`load_region`)
     2. `[F1]` Playtest Jump Menu (`scripts/data/PlaytestPresets.gd`: `PRESETS` + `apply_preset`)
     3. `docs/ARCHITECTURE.md` (and `docs/GAME_DESIGN_DOCUMENT.md` Section 5.1)
4. **Assets & Audio (`PixelAssets.gd`, `SoundManager.gd`):**
   - Do not duplicate `Image.load_from_file` calls in new gameplay or UI scripts; load textures through `PixelAssets` and play audio through `SoundManager`.
5. **Region Rendering & Frame-Budget Performance (`RegionBase.gd`, `PixelAssets.gd`):**
   - Never draw full-map grass zones, varied tile grids, dirt networks, or static forests directly inside per-frame `_draw()`. Bake static ground into `720x720` chunks via `RegionBase.setup_static_ground_chunks(...)` (`rebake_static_ground_chunks()` on static layout transitions only).
   - Render static water channels as single repeating GPU quads via `RegionBase.setup_water_layer(...)` + `step_water_layer()` (called before `queue_redraw()`, never inside `_draw()`), or `PixelAssets.draw_water_rect(...)` for culled sub-channels.
   - Cull dynamic entities, buildings, trees, props, and FX against `r.get_camera_rect(pad)`, use `Rect2` negative-width horizontal flips instead of per-entity `draw_set_transform(...)` to preserve batching, and call `RegionBase.sync_light_frustum(...)` inside `update_region_lights()` to disable off-screen/inactive `PointLight2D`s.

## 4. Verification & Context Continuity
- **Mandatory Godot Check:** After ANY `.gd` or `.tscn` edit, run awaited headless Godot 4.3 verification (`Start-Process ... --headless --verbose --path "." --quit-after 20 --log-file tools\godot_check.log -Wait`) and confirm `ExitCode=0` with **zero** `ERROR:`, `USER SCRIPT ERROR:`, `SCRIPT ERROR:`, or ObjectDB leak warnings before finishing.
- **Keep Docs Current:** Update `docs/ARCHITECTURE.md` whenever adding/moving/splitting files, new regions, new autoloads, or new input actions so every agent stays synchronized.
