# Wings of the Brotherhood — Agent Guide

Welcome to the **Wings of the Brotherhood** workspace. This repository contains an original dark-medieval 2D Top-Down Zelda-Like Action-Adventure RPG set across **Medieval Flanders, Brabant, and the Meuse Borderlands**.

---

## 1. Canonical Project Documents

Always consult these files before writing narrative, quests, characters, or lore:

- **Core Story Outline:** `docs/game story.txt` (authoritative plot, Book I Prologue & Book II+ Main Story)
- **Game Design Document:** `docs/GAME_DESIGN_DOCUMENT.md`
- **Lore Compendium:** `docs/LORE_COMPENDIUM.md` (original Golden Dragon prophecy, Devildragon ritual, dragon stages & factions)
- **Book II Engineering Handoff:** `docs/HANDOFF_BOOK2_IMPLEMENTATION.md` (phased implementation roadmap & architecture guide for Book II+)
- **Engine Comparison Reference:** `docs/ENGINE_COMPARISON_PYGAME_VS_GODOT.md`
- **Architecture & File Map:** `docs/ARCHITECTURE.md` and `.agents/rules/architecture-and-maintainability.md` (single source of truth for file ownership lanes, module layout, and size thresholds)
- **World Topology & Gate Reference:** `docs/WORLD_TOPOLOGY.md` (canonical macro map, 1:1 bidirectional portal/doorway registry, and spawn coordinates)
- **Sprite Asset Tracker:** `docs/SPRITE_TRACKER.md` (queue of `- [ ]` simple-box placeholder sprites awaiting bespoke pixel art -> crossed off `- [x]` by the Sprite-Making Agent)
- **Environmental Storytelling Queue:** `docs/ENVIRONMENTAL_STORYTELLING.md` (queue of `- [ ]` solo self-talk, visual narration, system toast boxes, mute dragon captions, and non-sign world labels awaiting real animations/visual cues so only spoken/telepathic dialogue & real writing use words -> crossed off `- [x]` once replaced)

---

## 2. Core Story & World Rules

1. **Time Period & Setting:** Original dark-medieval fantasy across **Port & Walled City of Bruges**, **Louvain** (birthplace), **Old Heverlee** (woods where the parents were killed), **Namur**, and the **Meuse/Ardennes** borderlands.
2. **Protagonist & Dual Perspective:** A boy (named by the player at start; 12 in Book I Ch. 1 -> 17 by Book I Ch. 4) born in Louvain and orphaned at 8 near Old Heverlee, initially hating dragons. Book II+ alternates between the **Boy** (traveling with his growing hatchling) and **Captain Anna** (flying *Virelai* and managing the Brotherhood), linked by **Kestrel** (`she/her`) as winged courier.
3. **The Conspiracy & Prophecy:** Publicly preaching dragon extermination, the Church's cabal harvests **live dragon blood and hearts** to summon a catastrophic **Devildragon**. Only the **Mythical Golden Dragon** can rally dragonkind to defeat it—which is why the Church hunted the Black Shadow-Guardian and put a dawn bounty on the black-and-gold egg.
4. **Parents & Clara:** At Old Heverlee, the parents uncovered the Devildragon ritual inside an excavated shrine and hid its key relic; Church Inquisitors murdered them to bury the secret. Five years before Book II, raiders abducted **Clara** as a skilled Bruges Ropewalk rig-master—only later discovering she is the Old Heverlee hunters' daughter.
5. **Turning Points:** Book I ends with the Boy lying to the Brotherhood Council to prevent the egg from being vaulted in Ghent, stealing it back at midnight, and fleeing into the sky aboard **Kestrel**. Book II opens in Brabant where the egg hatches into a soot-black dragonet that sheds dark scales across 4 growth stages to reveal gold beneath, speaking telepathically to the Boy like a Zelda companion.

---

## 3. Polished Pixel-Art Standards

- **Filter Mode:** Always enforce nearest-neighbor filtering (`CanvasItem.TEXTURE_FILTER_NEAREST`) on all pixel-art sprites, tiles, and UI icons. Never allow blurry bilinear filtering.
- **Cohesive Palette:** Use the 32-color Medieval Flemish & Dragon Palette defined in `.agents/rules/pixel-art-and-visuals.md`.
- **Sprite Construction:** Characters use shaded 16x24 / 24x32 pixel grids with dark-brown/slate outlines (never pure `#000000` flat boxes), 2–3 tone shading ramps, and soft elliptical drop shadows.
- **Depth & Sorting:** Use Y-sorting (`y_sort_enabled = true`) for ground props, buildings, NPCs, and the player; use multi-altitude `z_index` + dynamic downward shadow offset for flying dragons.
- **Region Rendering Performance (`RegionBase`):** Keep every region fast even at 1800x1600+ scales by building on `RegionBase` + `PixelAssets` batching instead of brute-force per-frame drawing:
  - **Bake Static Ground Once (`RegionBase.setup_static_ground_chunks`):** Never call `draw_grass_zone`, `draw_varied_tiled_rect`, `draw_dirt_trail_network`, or static scatter loops every frame inside `_draw()`. Bake static ground geometry once into `720x720`-chunked nearest-neighbor `SubViewport` `Sprite2D`s (`transparent_bg = false` for opaque grounds; call `rebake_static_ground_chunks()` only if state changes the static floor). Keep vector font labels and dynamic sprites out of the `SubViewport` so text stays sharp under `Camera2D` zoom.
  - **Batched Repeating Water (`setup_water_layer` / `step_water_layer` / `PixelAssets.draw_water_rect`):** Never tile water quad-by-quad every frame. Use `setup_water_layer` (which creates a repeating `WaterBackdropLayer` drawing 1 quad per channel via `TEXTURE_REPEAT_ENABLED`) and call `step_water_layer()` in `step_region()` / `enter_region()` before `queue_redraw()` (never inside `_draw()`).
  - **Camera Frustum Culling (`get_camera_rect`):** Cull dynamic buildings, trees, props, NPCs, particles, and projectiles against `r.get_camera_rect(pad)` before issuing draw calls. For Y-sorted prop lists sorted ascending by `y`, compute range bounds or `break` early past `cam_rect.end.y`.
  - **Transform-Free Flips & Light Frustum Culling (`sync_light_frustum`):** Flip sprites horizontally using negative width (`Rect2(pos, Vector2(-w, h))`) or `PixelAssets.draw_npc_sprite(...)` instead of calling `draw_set_transform(...)` per sprite (which breaks GL batching). Call `sync_light_frustum(lights, enabled)` inside `update_region_lights()` so off-screen or inactive `PointLight2D`s do not multiply render passes.
- **Modular Sprite Kits (Cities, Crowds & Carryables):** Always prefer composable kits over one-off bespoke sheets as the world scales: use `.agents/skills/pixel-art-generator/scripts/kit_buildings.py` (varying `blocks` width `3..10`, wall/roof presets, gables, doors, windows, awnings) for city architecture; `.agents/skills/pixel-art-generator/scripts/kit_npcs.py` (bodies, skin, faces/beards, hair, hats, props) for NPCs; and `.agents/skills/pixel-art-generator/scripts/kit_boy_carry.py` + `PlayerBoy.CARRY_PROPS` / `set_carry_prop(...)` runtime prop overlays for carried items.
- **Asset Generation & Placeholders:** When adding **any new non-kit visual asset** during feature work, generate a **simple-box placeholder** via `.agents/skills/pixel-art-generator/scripts/sprite_placeholders.py` and log it as `- [ ]` in `docs/SPRITE_TRACKER.md` so the dedicated Sprite-Making Agent can later craft the full pixel art and cross it off (`- [x]`). Keep `.agents/skills/pixel-art-generator/scripts/generate_pixel_assets.py` runnable at all times (`sprite_placeholders.py` skips any `- [x]` entry).

---

## 4. Agent Workflow & Verification

Follow `.agents/workflows/feature-pipeline.md` for every feature:
1. **Story/Lore Check:** Activate `.agents/skills/lore-research/SKILL.md` when adding breeds, dialogue, or locations.
2. **Modular Kit / Placeholder Sprite Pass:** Compose city buildings (`kit_buildings.py`), NPCs (`kit_npcs.py`), or carry props (`PlayerBoy.CARRY_PROPS`) via modular kits when applicable; otherwise add simple bordered-box placeholder specs to `.agents/skills/pixel-art-generator/scripts/sprite_placeholders.py`, log unchecked `- [ ]` items in `docs/SPRITE_TRACKER.md`, and run `generate_pixel_assets.py`. (Only replace `- [ ]` -> `- [x]` with polished art when acting as the Sprite-Making Agent.)
3. **Code Implementation:** Keep `scripts/GameState.gd` as the single source of truth for quest steps, inventory, and story flags. Load `.png` textures via `Image.load_from_file` + `ImageTexture.create_from_image` (or `.tres`/imported textures) so headless/direct runs always load immediately.
   - **Always Sync Maps with `bruges_map_builder.html` & `docs/WORLD_TOPOLOGY.md`:** Whenever any region's layout, buildings, props, canals, bridges, winches, lanterns, townsfolk, gates, or markers change in GDScript, update the matching region preset in `bruges_map_builder.html` (all 7 regions: `bruges_city`, `port_of_bruges`, `outskirts`, `sanctuary`, `frontier_wilds`, `willem_house`, `watchtower_hearth`) and update `docs/WORLD_TOPOLOGY.md` + `scripts/ui/ForestMapPanel.gd` so the visual builder, parchment world map, and bidirectional portals stay synced 1:1.
   - **Words Only Where Real-Life Words Exist (`docs/ENVIRONMENTAL_STORYTELLING.md`):** The target vision uses words **only** for spoken dialogue (humans & speaking dragons) and actually reading real-world text (decrees, maps, diaries, wooden signs). While building features now, temporary visual narration, solo self-talk, toast pop-ups (`Journal Note`), mute-dragon captions, or non-sign world labels are allowed for clarity, **provided every instance you add is logged as `- [ ]` in `docs/ENVIRONMENTAL_STORYTELLING.md`** so it can later be replaced by real animations/visuals and deleted.
   - **No Hand-Holding in Dialogue:** Never embed explicit key-spoilers (`[F]`, `[V]`, `[C]`, `[M]`, `[E]`) or blunt step-by-step puzzle commands inside character speech or inspect thoughts. Convey physical intuition naturally (*"looks brittle enough to snap if something heavy struck it with enough force"*), letting HUD labels and environmental cues teach controls.
4. **Verification:** Activate `.agents/skills/game-verifier/SKILL.md` and run the Godot 4.3 headless check (`--headless --path "." --quit-after 20 --log-file`) after every change.
5. **Playtesting Accessibility:** Every new scene, act, or major story beat added to the game MUST be registered in the `[F1]` Playtest Scene/Act Jump Menu so the developer can test any moment immediately without replaying earlier chapters.
6. **Playtesting Walkthrough in Final Replies:** Always include a dedicated **"What's New to Playtest"** section in your response after any feature, fix, or milestone—listing exact menus, `[F1]` presets, controls, and areas to test in `run_game.bat`, and clearly noting which backend/helper systems are verified headlessly while awaiting upcoming regions.

---

## 5. High-Craft Indie Polish Standard ("No Slop") & Proactive Ideas

1. **Commercial-Grade Craftsmanship:** Every milestone must meet polished indie-RPG quality—modular Godot scenes/autoloads (`GameState`, `SoundManager`), true 4-directional animated pixel sprites, 48x48 expressive character portraits in dialogue boxes, Y-sorted top-down depth, `CanvasModulate` + `PointLight2D` dynamic lighting, and crisp `.wav` sound effects/ambience.
2. **Proactive Creative Partner Rule:** Whenever you spot an opportunity to elevate gameplay feel, lore depth, environmental storytelling, or visual/audio polish, **proactively pitch concrete ideas to the user** alongside your updates so the game grows ambitiously and cohesively.

