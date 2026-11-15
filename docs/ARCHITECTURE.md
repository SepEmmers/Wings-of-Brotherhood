# Wings of the Brotherhood — Project Architecture & File Map

> **Purpose:** Single source of truth for **where code, assets, narrative, and rules live**, who owns each area across parallel agents, and what architectural standards keep the Godot 4.3 project modular without context loss.
> **Last Audited:** 2026-11-15

---

## 1. "Where Do I Edit?" Quick Lookup

| Task                                                                   | Edit These File(s)                                                                                                                                                                                | Primary Lane           |
| :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------- |
| Add/modify story flags, `QuestStep`, inventory, knots, inputs          | `scripts/GameState.gd` + `scripts/data/KnotCatalog.gd` + `scripts/data/SettingsConfig.gd`                                                                                                         | Main Game Dev          |
| Add/swap a region or `[F1]` playtest jump preset                       | `scripts/Main.gd` + `scripts/data/PlaytestPresets.gd` + `scripts/regions/<Name>Region.gd`                                                                                                         | Main Game Dev          |
| Edit player movement, knife slash, dodge-roll, rope throw              | `scripts/PlayerBoy.gd`                                                                                                                                                                            | Main Game Dev          |
| Edit Title Screen, Pause Menu, Settings, HUD bar, or fade/letterbox    | `scripts/ui/TitleScreenPanel.gd`, `PauseMenuPanel.gd`, `SettingsPanel.gd`, `HudOverlay.gd`, `scripts/GameUI.gd`                                                                                   | Main Game Dev          |
| Edit dialogue box / portrait presentation                              | `scripts/ui/DialogueBox.gd`                                                                                                                                                                       | Main Game Dev          |
| Edit Character & 12-slot Oilskin Bag tab                               | `scripts/ui/CharacterInventoryPanel.gd`                                                                                                                                                           | Main Game Dev          |
| Edit 4-tab Journal modal container / Border Map / `[F1]` Menu          | `scripts/ui/JournalModal.gd`, `ForestMapPanel.gd`, `PlaytestMenuPanel.gd`                                                                                                                         | Main Game Dev          |
| Edit knot-tying board minigame                                         | `scripts/KnotMinigame.gd`                                                                                                                                                                         | Main Game Dev          |
| Edit region logic vs drawing/cutscenes/map layout                      | `scripts/regions/<Region>.gd` (logic) or `*Draw.gd` / `*Ambush.gd` / `*MapData.gd` / `*Cutscene.gd`                                                                                               | Main Game Dev          |
| Visually inspect, edit, or export any region map layout                | `bruges_map_builder.html` + `docs/WORLD_TOPOLOGY.md` _(7-region visual map builder & bidirectional portal registry; must stay synced 1:1 with GDScript map layouts)_                              | Main Game Dev          |
| Edit item descriptions, Diary prose, Bestiary entries, knot lore       | `scripts/data/ItemCatalog.gd`, `JournalLoreData.gd`, `KnotCatalog.gd`                                                                                                                             | Narrative Improvements |
| Edit region-specific dialogue lines                                    | Matching `scripts/regions/*.gd` _(coordinate with Main Game Dev)_                                                                                                                                 | Narrative Improvements |
| Edit canonical story & lore reference                                  | `docs/game story.txt`, `docs/LORE_COMPENDIUM.md`, `docs/GAME_DESIGN_DOCUMENT.md`                                                                                                                  | Narrative Improvements |
| Add/polish Boy walk, poses, or NPC pixel sprites                       | `.agents/skills/pixel-art-generator/scripts/sprite_boy_walk.py`, `sprite_boy_poses.py`, `sprite_npcs.py`, `kit_npcs.py`, `kit_boy_carry.py` / `sprite_placeholders.py` + `docs/SPRITE_TRACKER.md` | Assets & Animations    |
| Add/polish portraits, buildings/tiles, dragons, props/icons, UI frames | `kit_buildings.py`, `sprite_portraits.py`, `sprite_world_buildings.py`, `sprite_dragons.py`, `sprite_props.py`, `sprite_icons_combat.py`, `sprite_world.py` -> run `generate_pixel_assets.py`     | Assets & Animations    |
| Register a new carried object without duplicating Boy sprites          | Add 16x16 `prop_*.png` + entry in `PlayerBoy.CARRY_PROPS` (or `set_carry_prop(...)`) paired with `boy_carry_hands_*` / `boy_cradle_hands_*`                                                       | Gameplay + Assets      |
| Track & replace simple-box placeholder sprites                         | `docs/SPRITE_TRACKER.md` (`- [ ]` -> `- [x]`) + `sprite_placeholders.py` / `kit_*.py`                                                                                                             | Sprite-Making Agent    |
| Log/replace pure-text visual beats with animations                     | `docs/ENVIRONMENTAL_STORYTELLING.md` (`- [ ]` -> `- [x]`)                                                                                                                                         | Main Dev + Assets      |
| Add/polish `.wav` music loops or SFX                                   | `audio_synth.py` -> run `generate_pixel_assets.py` -> register filename in `scripts/SoundManager.gd`                                                                                              | Assets & Animations    |
| Check project health, conventions, doc sync, safe refactors            | `docs/ARCHITECTURE.md`, `.agents/rules/architecture-and-maintainability.md`, `.agents/skills/maintainability-audit/`                                                                              | Maintainability Agent  |

---

## 2. Current Workspace File Map & Line Counts

### 2.1 Root & Engine Config

- `project.godot` — Godot 4.3 (`GL Compatibility`), viewport `1280x720` (`canvas_items` / `expand`), `default_texture_filter=0` (Nearest), main scene `res://scenes/Main.tscn`, Autoloads `GameState` and `SoundManager`.
- `run_game.bat` — Windows launcher invoking `tools\godot\Godot_v4.3-stable_win64.exe --path "."`.
- `AGENTS.md` — Top-level project rules, canonical doc links, pixel-art & workflow guide.
- `bruges_map_builder.html` — Offline Canvas/HTML5 visual map viewer & editor for all 7 game regions (`bruges_city`, `port_of_bruges`, `outskirts`, `sanctuary`, `frontier_wilds`, `willem_house`, `watchtower_hearth`), kept synced 1:1 with GDScript region data.
- `docs/WORLD_TOPOLOGY.md` — Authoritative 1:1 bidirectional walk-portal, spawn, facing, and macro-world topology reference across all connected regions.
- `scenes/Main.tscn` — Minimal root `Node2D` scene attaching `scripts/Main.gd`.

### 2.2 Core GDScript Systems (`scripts/`)

| File                      | Lines | Responsibility                                                                                                                                                                                                                                       | Health                    |
| :------------------------ | ----: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------ |
| `scripts/GameState.gd`    |   502 | Autoload: `QuestStep` enum (`0..22`), inventory, Sanctuary flags, Book II Dual Perspective / Golden Dragon Bond & City Heat state, persistent settings, `[R]`/`[X]` `InputMap` bindings                                                       | Borderline (>500 warning) |
| `scripts/SoundManager.gd` |   454 | Autoload: direct `.wav` loader (54 tracks/SFX), `Ambience`/`SFX`/`Voices` audio buses, dual-player ambience crossfader, spatial Sanctuary quarter layers, footsteps, voice blips, clean `_exit_tree()` teardown                         | Healthy                   |
| `scripts/Main.gd`         |   401 | Scene Director: instantiates `PixelAssets`, `CanvasModulate`, `world_root`, `PlayerBoy`, `GameUI`, `HatchlingCompanion`, `Camera2D`; routes regions, `[F1]` presets, `[Esc]` pause/back stack & `--smoke-regions` CLI hook | Healthy                   |
| `scripts/tools/HeadlessSmokeRunner.gd` | 287 | Automated multi-preset & multi-region headless verification runner (`--smoke-regions`, invoked by `tools/smoke_test.ps1`; verifies all 29 presets + Book II combat/heat/companion/campfire & Title/Settings/Pause UI) | Healthy                   |
| `scripts/PixelAssets.gd`  |   657 | Auto-loads all PNGs in `assets/sprites/` via `DirAccess`, styles 9-slice medieval UI, draws tiles/seams/NPCs/bubbles & shared bakery oven hearth FX                                                                                      | Borderline (>500 warning) |
| `scripts/PlayerBoy.gd`    |   665 | `PlayerBoy` (`CharacterBody2D`): 8-way movement, modular `CARRY_PROPS` / `carry_prop_sprite` runtime overlay (`boy_carry_hands_*`, `boy_cradle_hands_*`), `boy14_*` / `boy17_*` swaps, dodge-roll `[C]`, 3-hit knife combo & counter via `PlayerCombatHelper` `[V/LMB]`, 4-knot rope cast `[F/RMB]` | Borderline (>500 warning) |
| `scripts/KnotMinigame.gd` |   481 | `KnotMinigame` (`PanelContainer`): mouse-driven 2-stage peg weave + tension cinch board, whip/shake failure recoil, scales with Clara's Gift & Topman Ring                                                                               | Healthy                   |
| `scripts/GameUI.gd`       |   668 | `CanvasLayer` coordinator: letterbox/fade, Book I Checkpoint overlay; composes `HudOverlay`, `TitleScreenPanel`, `PauseMenuPanel`, `SettingsPanel`, `CampfirePanel` & modular `scripts/ui/` panels                                       | Borderline (>500 warning) |

### 2.2b Book II Companion & Gameplay Systems (`scripts/companions/`, `scripts/systems/`)

| File                                        | Lines | Responsibility                                                                                                                          | Health  |
| :------------------------------------------ | ----: | :-------------------------------------------------------------------------------------------------------------------------------------- | :------ |
| `scripts/companions/HatchlingCompanion.gd`  |   319 | Stages 1–4 Golden Dragon companion follower physics, `[X]` Assist/Stay/Sling posture, `[R]` Dragon Command, Gold-Sense pulse, automatic stuck-time telepathic hints | Healthy |
| `scripts/systems/PlayerCombatHelper.gd`     |   128 | 3-hit directional knife combo timing, post-dodge counter thrusts, and Book II Knot tactical combat resolution (`clove_hitch`, `bruges_whipping`, `bowline`, `dragon_splice`) | Healthy |
| `scripts/systems/CityHeatHelper.gd`         |   130 | City Bounty Heat manager: wanted poster tear-downs, Bronze Resonance Chime lures, Smoke-Pellet evasion clouds, Cloak-Sling exposure rates | Healthy |

### 2.3 Modular Narrative & Data Tables (`scripts/data/`)

| File                                  | Lines | Responsibility                                                                                                                                         |
| :------------------------------------ | ----: | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/data/KnotCatalog.gd`         |    70 | Canonical `KNOT_ORDER` and `KNOT_DATA`                                                                                                                 |
| `scripts/data/ItemCatalog.gd`         |   123 | Item lore descriptions (`get_item_info`) & compact bag badges (`get_item_badge`)                                                                       |
| `scripts/data/JournalLoreData.gd`     |   238 | Chapter subtitles, Boy's Diary summary (Book I & Book II), Bestiary BBCode (evolving across Year 1–5 + Golden Lineage), Knots & Controls BBCode        |
| `scripts/data/PlaytestPresets.gd`     |   770 | Single source of truth for Book I & Book II `[F1]` Jump Menu entries and state presets (`I: Bruges`..`I: Bruges City`, `Cutscenes`, `II: Golden Heir`) |
| `scripts/data/WorldRealmChartData.gd` |   276 | Macro Flanders/Brabant/Meuse geography (provinces, rivers, 11 campaign realm nodes, overland/Virelai/Kestrel routes, discovery helpers)                |
| `scripts/data/SettingsConfig.gd`      |   289 | Persistent audio/display/gameplay/keybind configuration (`user://settings.cfg`) & default `InputMap` registration                                      |

### 2.4 Modular UI Panels (`scripts/ui/`)

| File                                    | Lines | Responsibility                                                                                                                                       |
| :-------------------------------------- | ----: | :--------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/ui/HudOverlay.gd`              |   322 | Top-left medieval parchment HUD bar, flight harness/heat/warmth meters, dynamic keybind labels, and quick Menu/Bag/Debug buttons                     |
| `scripts/ui/TitleScreenPanel.gd`        |   278 | Book I Title card with New Game, Boy Name Entry, Settings, Chapter Select, and Quit actions                                                          |
| `scripts/ui/PauseMenuPanel.gd`          |   149 | Escape/HUD Pause modal offering Resume, Settings, Diary/Controls, World Map, Chapters, Title, and Quit                                               |
| `scripts/ui/SettingsPanel.gd`           |   678 | 3-tab Settings modal (`Audio`, `Gameplay & Display`, interactive `Controls` key rebinding)                                                           |
| `scripts/ui/CampfirePanel.gd`           |   170 | Wayside campfire roost modal: full rest heal & respawn binding, Carve & Feed via `ButcherMinigamePanel`, and Kestrel Courier dispatch trigger       |
| `scripts/ui/DialogueBox.gd`             |   236 | Bottom parchment dialogue box, 48x48 portrait frame (Age 14/17, Kestrel Y1/Y3/Y5, Hatchling Stage 1–4) & sovereign-gold Mind-Voice telepathy styling |
| `scripts/ui/CharacterInventoryPanel.gd` |   470 | Character Stats, Age 12/14/17 paperdoll, Sanctuary Brotherhood Crest badge & 12-slot Oilskin Bag tab (`[I]` / Journal tab)                           |
| `scripts/ui/JournalModal.gd`            |   100 | 4-tab modal container switching Bag / Diary / Bestiary / Knots                                                                                       |
| `scripts/ui/ForestMapPanel.gd`          |   610 | 3-view Cartographic Modal (`[M]`): `0: Coastal Bruges`, `1: Wilds Survey`, `2: Kingdom Charter (Flanders → Meuse)` with click/hover pin inspection     |
| `scripts/ui/WorldRealmChartDraw.gd`     |   188 | Renders the Belgium/Kingdom of Flanders, Brabant & Meuse Realm Chart onto `ForestMapCanvas` (coast, rivers, fog, Dual-Perspective & Kestrel pins)    |
| `scripts/ui/PlaytestMenuPanel.gd`       |   613 | `[F1]` Chapter-split Jump Menu (`Ch. 1–4`, `Cutscenes`, `Book II`), beat inspector & quick debug tools                                               |
| `scripts/ui/TimeSkipPanel.gd`           |   126 | Legacy chronicle stamp panel (kept disabled in active cutscenes; era progression driven purely visually by seasonal montages & weather)              |
| `scripts/ui/BorderBannerPanel.gd`       |    93 | Non-blocking carved oak archway signboard + `0.18s` gate fade shown smoothly on seamless region border transitions                                   |
| `scripts/ui/ButcherMinigamePanel.gd`    |   460 | Physical mouse-drag meat-slicing chopping block minigame (4 angled tallow seams, ivory bone knuckles, live piece separation)                         |

### 2.5 Modular World Regions (`scripts/regions/`)

All regions extend `res://scripts/regions/RegionBase.gd` (660 lines) and implement its lifecycle/input/draw contract:

- `PortOfBrugesRegion.gd` (742 lines, `"bruges"`) — Skippable _De Zwaan_ harbor glide, errands, Ropewalk, dawn Watchman stealth (`PortOfBrugesAmbush.gd`, 216 lines; `PortOfBrugesDraw.gd`, 347 lines).
- `WillemHouseRegion.gd` (388 lines, `"house"`) — Uncle Willem & Clara's cottage interior, sleep cutscene, dawn knot clue & cold-draft door silhouette.
- `SanctuaryRegion.gd` (818 lines, `"sanctuary"`) — 5-phase Brotherhood cliffside Sanctuary (`Age 12 -> 14 -> 17`, Phase 4 Egg Council Debate & Phase 5 Midnight Heist via `SanctuaryAct4.gd`), lived-in covert village (`1800x1140`), spatial pasture/mess audio blending, chores, Virelai bow/feast animation, Kestrel rescue/escape, and cuttable alarm tripwires (`SanctuaryNarrative.gd` 438, `SanctuaryDraw.gd` 649, `SanctuaryMontageCutscene.gd` 411, `SanctuaryArrivalCutscene.gd` 153, `SanctuaryVillageData.gd` 144, `SanctuaryAct4.gd` 593).
- `VirelaiFlightRegion.gd` (582 lines, `"flight"`) — Dual-sortie top-down dragonback flight with visual ballista/net wear, buckle spark FX & flying Bestiary sketch cards (`VirelaiFlightCutscene.gd` 151; `VirelaiFlightDraw.gd` 263).
- `FrontierWildsRegion.gd` (896 lines, `"wilds"`) — Organic Whispering Pines woodland, frost-rime & warmth pulse cues, Obsidian Hollow dying Black-Scaled Dragon reveal, Egg rescue breath blast & trek (`FrontierWildsMapData.gd` 502; `FrontierWildsDraw.gd` 468; `FrontierWildsEnvDraw.gd` 656).
- `WatchtowerHearthRegion.gd` (349 lines, `"hearth"`) — Watchtower Hearth warming the magma-gold egg before mounting Virelai back to Bruges Sanctuary.
- `BrugesCityRegion.gd` (862 lines, `"bruges_city"`) — Chapter 4 Walled City of Bruges (`2880x2160`): South Port Gate, Grote Markt & Belfry Cloth Hall, Reien canals with 5 stone bridges, 2 winch crossings, and patrolling canal barges (`BrugesCityBoats.gd`, 354 lines, parabolic deck-hopping), Guildhall Counting-House & Watergate, Beguinage Herb Court, St. Donatian's Church 8 PM bell tolls & acoustic waves, Father Anselm stealth tailing, Main Keep eavesdrop & escape (`BrugesCityMapData.gd` 463, `BrugesCityDraw.gd` 663).

### 2.6 Assets & Procedural Generators (`.agents/skills/pixel-art-generator/scripts/` & `assets/`)

- `generate_pixel_assets.py` (71 lines) — Master runner outputting 577 `.png` sprites (`assets/sprites/`) and 54 `.wav` audio files (`assets/audio/`).
- `pixel_art_lib.py` (306 lines) — 32-color Medieval Flemish & Dragon palette (`PAL`) and `PixelCanvas`.
- `kit_buildings.py` (546 lines) — Modular `16px`-bay architectural composer (`width_blocks` `3..10`, wall/roof presets, gables, doors, windows, awnings, guild signs) generating `city_*` sample houses/shops/manors.
- `kit_interiors.py` (290 lines) — Modular `16px`-bay interior shopkit furniture & woven rug composer generating reusable `furn_*` church pews, altars, apothecary shelves, bakery/tavern counters, keg racks, weaver looms, merchant desks, and rugs.
- `kit_npcs.py` (606 lines) — Modular part-layered `24x28` NPC composer (9 body types, cloth/hair/skin ramps, faces/beards, hats, handheld props, resting + `_0`/`_1` frames) generating Sanctuary crew (`npc_hendrick*`, `npc_maren*`, `npc_matthijs*`), Sanctuary caretakers (`npc_villager_cook_0/1`, `npc_villager_herdsman_0/1`), & `npc_city_*` archetypes.
- `kit_boy_carry.py` (153 lines) — Emits 18 shared empty-hands `boy_carry_hands_*` & `boy_cradle_hands_*` frames (`3` cardinals × `3` walk steps × `2` postures) + `cloth_overrides` & `grid_transform` age-tier remapper for `PlayerBoy.CARRY_PROPS`.
- `sprite_placeholders.py` (389 lines) — Simple-box placeholder safety net syncing with `docs/SPRITE_TRACKER.md`.
- `sprite_characters.py` (27) + `sprite_char_common.py` (42), `sprite_boy_walk.py` (787), `sprite_boy_poses.py` (780), `sprite_boy_tiers.py` (140), `sprite_npcs.py` (813) — 24x28 8-directional Boy (`boy_*` Age 12 navy dockwool, `boy14_*` Age 14 tanned leather rig-apprentice, `boy17_*` Age 17 emerald & dark leather Flight-Jerkin) + Bruges/Church NPCs.
- `sprite_portraits.py` (1011) — 48x48 framed dialogue portraits (`portrait_boy*`, `portrait_boy14*`, `portrait_boy17*`, `portrait_clara`, `portrait_anna`, `portrait_hendrick`, `portrait_maren`, `portrait_matthijs`, `portrait_cook`, `portrait_herdsman`, `portrait_priest`, `portrait_virelai`, `portrait_greyling`, `portrait_dragon_black`, etc.).
- `sprite_world.py` (238 lines) + `sprite_sanctuary.py` (864), `sprite_world_buildings.py` (655), `sprite_dragons.py` (705), `sprite_props.py` (487), `sprite_icons_combat.py` (470), `sprite_wilds_env.py` (927), `sprite_bruges_landmarks.py` (706), `sprite_bruges_forts_water.py` (653) — World tiles, _De Zwaan_, Flemish buildings, Bruges landmarks/walls/bastions/gatehouses/watergates/patrol barges/fountain/loaves, Sanctuary housing/stalls/props/livestock/Signal Mast, Brotherhood Emblem & Wax Seal suite, animated dragons (`dragon_anna_eat_0/1` inclusive), held & nested egg (`prop_dragon_egg_held.png` / `prop_dragon_egg.png`), stylized wilds/map cartography sprites, icons & 9-slice UI skins.
- `audio_synth.py` (611 lines) — Procedural 44.1 kHz PCM `.wav` synthesizer (ambience tracks, Sanctuary spatial quarter layers, footsteps, voice blips, bronze church bell, bakery hearth crackle & gameplay SFX).

### 2.7 Governance & Design Docs (`docs/`, `.agents/`)

- `docs/game story.txt`, `docs/LORE_COMPENDIUM.md`, `docs/GAME_DESIGN_DOCUMENT.md`, `docs/HANDOFF_BOOK2_IMPLEMENTATION.md`, `docs/ENGINE_COMPARISON_PYGAME_VS_GODOT.md`, `docs/WORLD_TOPOLOGY.md`, `docs/SPRITE_TRACKER.md`, `docs/ENVIRONMENTAL_STORYTELLING.md`
- `.agents/rules/`: `pixel-art-and-visuals.md`, `story-and-lore-continuity.md`, `architecture-and-maintainability.md`
- `.agents/skills/`: `lore-research`, `pixel-art-generator`, `game-verifier`, `maintainability-audit`
- `.agents/workflows/feature-pipeline.md`

---

## 3. Canonical `GameState` & `InputMap` Reference

### 3.1 `GameState.QuestStep` Enum (`scripts/GameState.gd`)

1. `ON_THE_SHIP = 0`
2. `EXPLORE_BRUGES = 1`
3. `EVENING_HOME = 2`
4. `DAWN_MISSING_CLARA = 3`
5. `SNITCH_TO_CHURCH = 4`
6. `BROTHERHOOD_AMBUSH = 5`
7. `ACT2_SANCTUARY = 6`
8. `ACT2_VIRELAI_SORTIE_1 = 7`
9. `ACT2_VIRELAI_SORTIE_2 = 8`
10. `ACT3_WILDS_TRACKING = 9`
11. `ACT3_EGG_TREK = 10`
12. `BOOK1_WATCHTOWER_HEARTH = 11`
13. `ACT4_SANCTUARY_DEBATE = 12`
14. `ACT4_BRUGES_CITY = 13`
15. `ACT4_NIGHT_HEIST = 14`
16. `BOOK2_BRABANT_FENS = 15`
17. `BOOK2_LOUVAIN_HATCH = 16`
18. `BOOK2_OLD_HEVERLEE = 17`
19. `BOOK2_ANNA_SORTIE_1 = 18`
20. `BOOK2_NAMUR_CROSSING = 19`
21. `BOOK2_ANNA_SORTIE_2 = 20`
22. `BOOK2_ARDENNES_SHED = 21`
23. `BOOK2_BLOOD_CITADEL = 22`

### 3.2 Registered Input Actions (`GameState._ensure_input_actions()`)

- Movement: `move_up` (`W`/`Up`), `move_down` (`S`/`Down`), `move_left` (`A`/`Left`), `move_right` (`D`/`Right`), `sprint` (`Shift`)
- Interaction & Tools: `interact` (`E`/`Space`/`Enter`), `rope_action` (`F`/`Right-Click`), `knife_attack` (`V`, plus `Left-Click` in `PlayerBoy`/`VirelaiFlightRegion`), `dodge` (`C`)
- Golden Dragon Companion (Book II+): `dragon_command` (`R`), `dragon_posture` (`X`) — automatic stuck-time telepathic hints handled by `HatchlingCompanion` with no hint keybind
- Knot & UI Overlays: `cycle_knot` (`Q`), `practice_knot` (`K`), `inventory_screen` (`I`), `journal` (`Tab`/`J`), `toggle_map` (`M`), `playtest_menu` (`F1`/`~`)

---

## 4. Architecture Health Notes

- **Cross-File Compilation Rules (Godot 4.3):** Use explicit `const FooScript := preload("res://scripts/...")` instead of relying on global `class_name` cache resolution during headless runs, and ensure autoload (`GameState`) -> helper script dependencies remain acyclic (`GameState` uses `load(...)` on `JournalLoreData.gd`).
- **Typed Array Helper Assignments:** When helper modules (`*Ambush.gd`, `*MapData.gd`, `*Cutscene.gd`) populate typed `Array[...]` properties on an untyped `r` region reference, use `.assign([...])` or `.clear()` + `.append(...)`.
- **Verification Tooling (`tools/smoke_test.ps1`):** Runs headless Godot (`--smoke-regions`) across all 29 `[F1]` presets, all 8 Book I regions, `[M]` Kingdom Charter views, Mind-Voice telepathy, and Journal formatters, failing on any `SCRIPT ERROR` / `Parse Error`.
- **Remaining Low-Priority Notes:**
  - Local Git repository (`main` branch) tracks code, scenes, pixel/audio assets, docs, `.agents/`, and `tools/smoke_test.ps1`, while `.gitignore` excludes `.godot/`, `tools/godot/`, `books/`, and `*.log`/`*.tmp`.
  - `FrontierWildsRegion.gd` (896 lines), `BrugesCityRegion.gd` (862 lines), and `SanctuaryRegion.gd` (818 lines) have crossed the 800-line Split Watch mark (`GameUI.gd` was trimmed below 800 via `TitleScreenPanel.gd`, `SettingsPanel.gd`, `PauseMenuPanel.gd`, and `HudOverlay.gd`); any substantial Book II additions should extract dedicated sub-modules rather than growing those files (following `BrugesCityBoats.gd`, 354 lines).
