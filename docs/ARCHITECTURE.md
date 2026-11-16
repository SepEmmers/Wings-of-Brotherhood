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
- `.vscode/settings.json` — Workspace editor safeguard disabling `editor.formatOnSave`/`editor.formatOnPaste` (Prettier) and `files.autoSave` during multi-agent edits, and excluding `.godot/`, `tools/godot/`, and `__pycache__/` from watchers/search.

### 2.2 Core GDScript Systems (`scripts/`)

| File                                   | Lines | Responsibility                                                                                                                                                                                                                                              | Health                    |
| :------------------------------------- | ----: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------ |
| `scripts/GameState.gd`                 |   537 | Autoload: `QuestStep` enum (`0..22`), inventory, Sanctuary & Book II Act I progression flags, Dual Perspective / Golden Dragon Bond & City Heat state, persistent settings, delegated `SettingsConfig` bindings | Borderline (>500 warning) |
| `scripts/SoundManager.gd`              |   454 | Autoload: direct `.wav` loader (54 tracks/SFX), `Ambience`/`SFX`/`Voices` audio buses, dual-player ambience crossfader, spatial Sanctuary quarter layers, footsteps, voice blips, clean `_exit_tree()` teardown                                                | Healthy                   |
| `scripts/Main.gd`                      |   424 | Scene Director: instantiates `PixelAssets`, `CanvasModulate`, `world_root`, `PlayerBoy`, `GameUI`, `HatchlingCompanion`, `Camera2D`; sets global root `Theme` with crisp MSDF `SystemFont`, routes Book I & Book II regions, `[F1]` presets, `[Esc]` pause/back stack, `--smoke-regions` & `--visual-audit` CLI hooks | Healthy                   |
| `scripts/tools/HeadlessSmokeRunner.gd` |   396 | Automated multi-preset & multi-region headless verification runner (`--smoke-regions`, invoked by `tools/smoke_test.ps1`; verifies all 33 presets across 10 regions, Book I->II seamless Kestrel escape, midnight->dawn tint, farewell dialogue, camera follow, DragonNamePanel, `[F1]` tab ordering, Stage 1 non-fireball Vent/Ember checks, Cloister top enclosure colliders, segment rope ensnare, checkpoint restore & auto-expanding `DialogueBox`) | Healthy                   |
| `scripts/tools/VisualAuditRunner.gd`   |   175 | GL Compatibility viewport screenshot audit runner (`--visual-audit`, invoked by `tools/capture_audit.ps1`; captures 6 Louvain districts + Brabant frames into `tools/audit_shots/` for visual inspection) | Healthy                   |
| `scripts/PixelAssets.gd`               |   717 | Auto-loads all PNGs in `assets/sprites/` via `DirAccess`, provides shared MSDF `SystemFont` (`get_ui_font()`), styles 9-slice medieval UI + crisp `TEXTURE_FILTER_LINEAR` text controls, manages `_WorldTextOverlay` world-label pass, draws tiles/seams/NPCs/bubbles & shared bakery oven hearth FX; delegates `get_item_info` to `ItemCatalog` | Borderline (>500 warning) |
| `scripts/PlayerBoy.gd`                 |   675 | `PlayerBoy` (`CharacterBody2D`): 8-way movement, 8-way modular `CARRY_PROPS` / `carry_prop_sprite` runtime overlay (`boy_carry_hands_*`, `boy_cradle_hands_*`), `boy14_*` / `boy17_*` swaps, dodge-roll `[C]`, 3-hit knife combo & counter via `PlayerCombatHelper` `[V/LMB]`, 4-knot rope cast `[F/RMB]` | Borderline (>500 warning) |
| `scripts/KnotMinigame.gd`              |   482 | `KnotMinigame` (`PanelContainer`): mouse-driven 2-stage peg weave + tension cinch board, whip/shake failure recoil, scales with Clara's Gift & Topman Ring                                                                                                  | Healthy                   |
| `scripts/GameUI.gd`                    |   709 | `CanvasLayer` coordinator: viewport-adaptive fullscreen letterbox/fade, Book I Checkpoint overlay; composes `HudOverlay`, `TitleScreenPanel`, `PauseMenuPanel`, `SettingsPanel`, `CampfirePanel`, `DragonNamePanel` & modular `scripts/ui/` panels     | Borderline (>500 warning) |

### 2.2b Book II Companion & Gameplay Systems (`scripts/companions/`, `scripts/systems/`)

| File                                        | Lines | Responsibility                                                                                                                          | Health  |
| :------------------------------------------ | ----: | :-------------------------------------------------------------------------------------------------------------------------------------- | :------ |
| `scripts/companions/HatchlingCompanion.gd`  |   430 | Stages 1–4 Golden Dragon companion follower physics, 8-way sprite facing via `PixelAssets.get_tex_flipped` (`side`/`up`/`down`/`diag_up`/`diag_down` centered over shadow), calm idle hover-bob + slow wing-flutter vs brisk movement wingbeats, `[X]` Assist/Stay/Sling posture, `[R]` Dragon Command (Stage 1 unfed dry ash-cough -> fed tiny ember sparks + drain vent-crawl concealment; Stage 2 resonance; Stage 3+ golden flame), Gold-Sense pulse, automatic stuck-time telepathic hints | Healthy |
| `scripts/systems/PlayerCombatHelper.gd`     |   129 | 3-hit directional knife combo timing, post-dodge counter thrusts, and Book II segment-based Knot tactical combat resolution (`clove_hitch`, `bruges_whipping`, `bowline`, `dragon_splice`) | Healthy |
| `scripts/systems/CityHeatHelper.gd`         |   137 | City Bounty Heat manager & overlays: wanted poster tear-downs, Bronze Resonance Chime lures, Smoke-Pellet evasion clouds, Cloak-Sling exposure rates | Healthy |

### 2.3 Modular Narrative & Data Tables (`scripts/data/`)

| File                                  | Lines | Responsibility                                                                                                                                         |
| :------------------------------------ | ----: | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/data/KnotCatalog.gd`         |    70 | Canonical `KNOT_ORDER` and `KNOT_DATA`                                                                                                                 |
| `scripts/data/ItemCatalog.gd`         |   155 | Item lore descriptions (`get_item_info`) & compact bag badges (`get_item_badge`) including Book II Act I relics & stealth tools                        |
| `scripts/data/JournalLoreData.gd`     |   262 | Chapter subtitles, Boy's Diary summary (Book I & Book II Act I), Bestiary BBCode (Year 1–5 + obsidian-and-gold Golden Lineage), Knots & Controls BBCode |
| `scripts/data/PlaytestPresets.gd`     |   779 | `[F1]` Jump Menu coordinator (`CHAPTERS`, Book I presets `ch1`–`ch4`, and delegation to `PlaytestPresetsBook2.gd`)                                      |
| `scripts/data/PlaytestPresetsBook2.gd`|   118 | Book II+ (`II: Golden Heir`) `[F1]` chapter presets and state presets (`book2_brabant_arrival` .. `book2_louvain_abbey`)                               |
| `scripts/data/WorldRealmChartData.gd` |   276 | Macro Flanders/Brabant/Meuse geography (provinces, rivers, 11 campaign realm nodes, overland/Virelai/Kestrel routes, discovery helpers)                |
| `scripts/data/SettingsConfig.gd`      |   289 | Persistent audio/display/gameplay/keybind configuration (`user://settings.cfg`) & default `InputMap` registration                                      |

### 2.4 Modular UI Panels (`scripts/ui/`)

| File                                    | Lines | Responsibility                                                                                                                                       |
| :-------------------------------------- | ----: | :--------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/ui/HudOverlay.gd`              |   438 | Minimal Zelda-like HUD: top-left scarlet pixel hearts (`icon_heart_full`/`empty`) & contextual egg/heat/flight gauges; non-overlapping top-right `HBoxContainer` with `[X]` companion posture, `[F]` knot slot, timed pulse badge, optional `Acts [F1]` toggle, and `Menu [Esc]` |
| `scripts/ui/TitleScreenPanel.gd`        |   484 | Animated Zelda-inspired Flanders/Bruges twilight-to-dawn diorama with floating Brotherhood crest, wing-cursor main menu, Traveler's Charter Name Entry, Settings, Playtest, and Quit actions                                                          |
| `scripts/ui/PauseMenuPanel.gd`          |   149 | Escape/HUD Pause modal offering Resume, Settings, Diary/Controls, World Map, Chapters, Title, and Quit                                               |
| `scripts/ui/SettingsPanel.gd`           |   795 | Stylized 3-tab Chronicle Settings modal (`Audio`, `Gameplay & Display`, `Controls`) with 9-slice cards/tabs/pills/keycaps, pixel icons, custom HSlider/VScrollBar & interactive key rebinding                                                           |
| `scripts/ui/CampfirePanel.gd`           |   170 | Wayside campfire roost modal: full rest heal & respawn binding, Carve & Feed via `ButcherMinigamePanel`, and Kestrel Courier dispatch trigger       |
| `scripts/ui/DragonNamePanel.gd`         |   116 | Parchment hatchling naming modal (`portrait_hatchling_stage1.png`, custom name field, quick-pick names) persisting `GameState.gold_dragon_name`       |
| `scripts/ui/DialogueBox.gd`             |   453 | Dynamically auto-sizing bottom portrait dialogue box (`700px` wide, `138–240px` height to prevent line clipping), `670px` dreamy Mind-Voice telepathic velvet charter, Hatchling eye-blink + micro-bounce reaction, MSDF labels, and 48x48 portrait frame |
| `scripts/ui/CharacterInventoryPanel.gd` |   470 | Character Stats, Age 12/14/17 paperdoll, Sanctuary Brotherhood Crest badge & 12-slot Oilskin Bag tab (`[I]` / Journal tab)                           |
| `scripts/ui/JournalModal.gd`            |   100 | 4-tab modal container switching Bag / Diary / Bestiary / Knots                                                                                       |
| `scripts/ui/ForestMapPanel.gd`          |   660 | 3-view Cartographic Modal (`[M]`): `0: Coastal Bruges`, `1: Wilds Survey`, `2: Kingdom Charter (Flanders → Meuse)` with click/hover pin inspection and linear `_MapLabelOverlay` for razor-sharp ink labels |
| `scripts/ui/WorldRealmChartDraw.gd`     |   188 | Renders the Belgium/Kingdom of Flanders, Brabant & Meuse Realm Chart onto `ForestMapCanvas` (coast, rivers, fog, Dual-Perspective & Kestrel pins)    |
| `scripts/ui/PlaytestMenuPanel.gd`       |   614 | `[F1]` Chapter-split Jump Menu (`Ch. 1–4`, `Cutscenes`, `Book II`), beat inspector & quick debug tools                                               |
| `scripts/ui/TimeSkipPanel.gd`           |   126 | Legacy chronicle stamp panel (kept disabled in active cutscenes; era progression driven purely visually by seasonal montages & weather)              |
| `scripts/ui/BorderBannerPanel.gd`       |   100 | Non-blocking centered carved oak archway signboard + `0.18s` gate fade shown smoothly on seamless region border transitions                           |
| `scripts/ui/ButcherMinigamePanel.gd`    |   463 | Physical mouse-drag meat-slicing chopping block minigame (4 angled tallow seams, ivory bone knuckles, live piece separation)                         |

### 2.5 Modular World Regions (`scripts/regions/`)

All regions extend `res://scripts/regions/RegionBase.gd` (606 lines, delegating A* grid pathfinding and raycast vision cones to `RegionNavHelper.gd`, 259 lines) and implement its lifecycle/input/draw contract:

- `PortOfBrugesRegion.gd` (742 lines, `"bruges"`) — Skippable _De Zwaan_ harbor glide, errands, Ropewalk, dawn Watchman stealth (`PortOfBrugesAmbush.gd`, 247 lines; `PortOfBrugesDraw.gd`, 375 lines).
- `WillemHouseRegion.gd` (389 lines, `"house"`) — Uncle Willem & Clara's cottage interior, sleep cutscene, dawn knot clue & cold-draft door silhouette.
- `SanctuaryRegion.gd` (787 lines, `"sanctuary"`) — 5-phase Brotherhood cliffside Sanctuary (`Age 12 -> 14 -> 17`, Phase 4 Egg Council Debate & Phase 5 Midnight Heist via `SanctuaryAct4.gd`), lived-in covert village (`1800x1140`), spatial pasture/mess audio blending, chores, Virelai bow/feast animation, Kestrel rescue/escape, and cuttable alarm tripwires (`SanctuaryNarrative.gd` 438, `SanctuaryDraw.gd` 649, `SanctuaryMontageCutscene.gd` 411, `SanctuaryArrivalCutscene.gd` 153, `SanctuaryVillageData.gd` 161, `SanctuaryAct4.gd` 595).
- `VirelaiFlightRegion.gd` (582 lines, `"flight"`) — Dual-sortie top-down dragonback flight with visual ballista/net wear, buckle spark FX & flying Bestiary sketch cards (`VirelaiFlightCutscene.gd` 151; `VirelaiFlightDraw.gd` 263).
- `FrontierWildsRegion.gd` (771 lines, `"wilds"`) — Organic Whispering Pines woodland, frost-rime & warmth pulse cues, Obsidian Hollow dying Black-Scaled Dragon reveal, Egg rescue breath blast & trek (`FrontierWildsMapData.gd` 516; `FrontierWildsDraw.gd` 460; `FrontierWildsEnvDraw.gd` 656).
- `WatchtowerHearthRegion.gd` (350 lines, `"hearth"`) — Watchtower Hearth warming the magma-gold egg before mounting Virelai back to Bruges Sanctuary.
- `BrugesCityRegion.gd` (786 lines, `"bruges_city"`) — Chapter 4 Walled City of Bruges (`2880x2160`): South Port Gate, Grote Markt & Belfry Cloth Hall, Reien canals with 5 stone bridges, 2 winch crossings, and patrolling canal barges (`BrugesCityBoats.gd`, 354 lines, parabolic deck-hopping), Guildhall Counting-House & Watergate, Beguinage Herb Court, St. Donatian's Church 8 PM bell tolls & acoustic waves, Father Anselm stealth tailing, Main Keep eavesdrop & escape (`BrugesCityMapData.gd` 467, `BrugesCityDraw.gd` 663).
- `BrugesOutskirtsRegion.gd` (419 lines, `"outskirts"`) — Coastal causeway, tollhouse & dune bridge connecting Bruges East Gate, Port NE Towpath, and Sanctuary West Gate during Chapter 4 (`AStarGrid2D` + vision-cone sentry patrol).
- `BrabantFensRegion.gd` (779 lines, `"brabant_fens"`, `BrabantFensDraw.gd` 389) — Book II Act I (`2160x1440`) Brabant reed-fens & ruined water-mill: midnight Kestrel touchdown & farewell -> campfire glimpse, cold-egg warming & hatching (lifting to dawn light) & `DragonNamePanel`, newborn feeding bonding beat & Mind-Voice awakening, continuous weir masonry + iron portcullis + visible east inside lever + drainage culvert, animated `[R]` Vent Crawl (`vent_crawl_t`) & fed tiny Ember Puff sparks (`dry_cough` when hungry), `[X]` Cloak-Sling threshold at Louvain Gate, Gold-Sense cairn, and East Dike portal to Louvain.
- `LouvainCityRegion.gd` (787 lines, `"louvain"`, `LouvainCityMapData.gd` 335, `LouvainCityDraw.gd` 550) — Book II Act I (`2100x2100`) Circular-Octagonal Historical City of Louvain (*De Kuip*): *Tweede Stadsomwalling* ring-wall with 16 rampart towers & 4 *Poorten*, widened Dijle River *Vismarkt* harbor quay with moored cargo barges & 3 stone bridges, *Grote Markt* (*Het Stadhuis*, unfinished *Sint-Pieterskerk* scaffolding & Master Mason Matthijs, *De Lakenhalle* & 1425 University Beadle Hendrik), Dyers' Island & Childhood Hunters' Tavern, Bell-Foundry, 4-walled Abbey Scriptorium Cloister with 90-degree bending corners, walking ambient citizens, `[X]` Cloak-Sling stealth + Catchpole cones + Chime `[1]` / Smoke `[2]`, animated Abbey Drain Vent Crawl -> inside lever -> portcullis raise, Abbey Brazier Ember discovery, segment-based rope ensnare/shield-yank combat, and full checkpoint state/gate restore on retry.

### 2.6 Assets & Procedural Generators (`.agents/skills/pixel-art-generator/scripts/` & `assets/`)

- `generate_pixel_assets.py` (71 lines) — Master runner outputting 696 `.png` sprites (`assets/sprites/`) and 54 `.wav` audio files (`assets/audio/`).
- `pixel_art_lib.py` (306 lines) — 32-color Medieval Flemish & Dragon palette (`PAL`) and `PixelCanvas`.
- `kit_buildings.py` (567 lines) — Modular `16px`-bay architectural composer (`width_blocks` `3..10`, wall/roof presets, gables, doors, windows, awnings, guild signs) generating `city_*` Bruges & Louvain houses/shops/manors.
- `kit_interiors.py` (290 lines) — Modular `16px`-bay interior shopkit furniture & woven rug composer generating reusable `furn_*` church pews, altars, apothecary shelves, bakery/tavern counters, keg racks, weaver looms, merchant desks, and rugs.
- `kit_npcs.py` (627 lines) — Modular part-layered `24x28` NPC composer (9 body types, cloth/hair/skin ramps, faces/beards, hats, handheld props, resting + `_0`/`_1` frames) generating Sanctuary crew (`npc_hendrick*`, `npc_maren*`, `npc_matthijs*`), Sanctuary caretakers, `npc_city_*`, & `npc_louvain_*` citizens (Master Mason, Scholar, Student, Cloth Weaver).
- `kit_boy_carry.py` (206 lines) — Emits 30 shared empty-hands `boy_carry_hands_*` & `boy_cradle_hands_*` frames (`5` 8-way dirs × `3` walk steps × `2` postures) + `cloth_overrides` & `grid_transform` age-tier remapper for `PlayerBoy.CARRY_PROPS`.
- `sprite_placeholders.py` (370 lines) — Simple-box placeholder safety net syncing with `docs/SPRITE_TRACKER.md` (`3` open Queue 14 placeholders: `prop_dragon_vent_grate`, `prop_bell_mould`, `prop_archive_desk`; `102` completed).
- `sprite_characters.py` (27) + `sprite_char_common.py` (42), `sprite_boy_walk.py` (787), `sprite_boy_poses.py` (780), `sprite_boy_tiers.py` (140), `sprite_npcs.py` (813) — 24x28 8-directional Boy (`boy_*` Age 12 navy dockwool, `boy14_*` Age 14 tanned leather rig-apprentice, `boy17_*` Age 17 emerald & dark leather Flight-Jerkin) + Bruges/Church NPCs.
- `sprite_portraits.py` (1192) — 48x48 framed dialogue portraits (`portrait_boy*`, `portrait_boy14*`, `portrait_boy17*`, `portrait_clara`, `portrait_anna`, `portrait_hendrick`, `portrait_maren`, `portrait_matthijs`, `portrait_cook`, `portrait_herdsman`, `portrait_priest`, `portrait_virelai`, `portrait_greyling`, `portrait_dragon_black`, camera-facing zoomed black-and-gold `portrait_hatchling_stage1..4` + `_blink`, etc.).
- `sprite_world.py` (243 lines) + `sprite_sanctuary.py` (864), `sprite_world_buildings.py` (655), `sprite_dragons.py` (912), `sprite_props.py` (585), `sprite_icons_combat.py` (470), `sprite_ui_art.py` (701), `sprite_wilds_env.py` (927), `sprite_bruges_landmarks.py` (706), `sprite_bruges_forts_water.py` (653), `sprite_louvain_landmarks.py` (563) — World tiles (`tile_sandstone_flag*`, `tile_louvain_cobble*`, `tile_red_brick_path`), _De Zwaan_, Flemish buildings, Bruges landmarks/walls/bastions/gatehouses/watergates/patrol barges/fountain/loaves, historic circular Louvain monuments (`bldg_louvain_stadhuis`, `bldg_louvain_st_peters`, `bldg_louvain_lakenhalle`, open-road `prop_louvain_poort_h/v`, `prop_louvain_wall_tower`, `prop_wall_corner_nw/ne/sw/se`, `prop_lime_tree`, `prop_wine_cask_cart`, `prop_mason_yard`, `prop_dye_vat_*`), Sanctuary housing/stalls/props/livestock/Signal Mast, Brotherhood Emblem & Wax Seal suite, animated dragons (`dragon_anna_eat_0/1`, 8-way `dragon_gold_s1_*`), held & nested egg (`prop_dragon_egg_held.png` / `prop_dragon_egg.png`), Book II props (`prop_wanted_poster.png`, `prop_resonance_chime.png`, `prop_smoke_pellet.png`, `prop_hatchling_sling.png`), title/Settings/Dialogue/Zelda HUD 9-slice UI skins & hearts (`title_*`, `ui_*`, `icon_heart_full`/`empty`), stylized wilds/map cartography sprites & icons.
- `audio_synth.py` (611 lines) — Procedural 44.1 kHz PCM `.wav` synthesizer (ambience tracks, Sanctuary spatial quarter layers, footsteps, voice blips, bronze church bell, bakery hearth crackle & gameplay SFX).

### 2.7 Governance & Design Docs (`docs/`, `.agents/`)

- `docs/game story.txt`, `docs/LORE_COMPENDIUM.md`, `docs/GAME_DESIGN_DOCUMENT.md`, `docs/HANDOFF_BOOK2_IMPLEMENTATION.md`, `docs/LOUVAIN_OVERHAUL_PLAN.md`, `docs/WORLD_TOPOLOGY.md`, `docs/SPRITE_TRACKER.md`, `docs/ENVIRONMENTAL_STORYTELLING.md`
- `.agents/rules/`: `pixel-art-and-visuals.md`, `story-and-lore-continuity.md`, `architecture-and-maintainability.md`
- `.agents/skills/`: `lore-research`, `pixel-art-generator`, `environmental-storytelling`, `performance-audit`, `maintainability-audit`, `game-verifier`
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

### 3.2 Registered Input Actions (`SettingsConfig.ensure_default_input_actions()` via `GameState`)

- Movement: `move_up` (`W`/`Up`), `move_down` (`S`/`Down`), `move_left` (`A`/`Left`), `move_right` (`D`/`Right`), `sprint` (`Shift`)
- Interaction & Tools: `interact` (`E`/`Space`/`Enter`), `rope_action` (`F`/`Right-Click`), `knife_attack` (`V`, plus `Left-Click` in `PlayerBoy`/`VirelaiFlightRegion`), `dodge` (`C`)
- Golden Dragon Companion (Book II+): `dragon_command` (`R`), `dragon_posture` (`X`) — automatic stuck-time telepathic hints handled by `HatchlingCompanion` with no hint keybind
- Knot & UI Overlays: `cycle_knot` (`Q`), `practice_knot` (`K`), `inventory_screen` (`I`), `journal` (`Tab`/`J`), `toggle_map` (`M`), `playtest_menu` (`F1`/`~`)

---

## 4. Architecture Health Notes

- **Cross-File Compilation Rules (Godot 4.3):** Use explicit `const FooScript := preload("res://scripts/...")` instead of relying on global `class_name` cache resolution during headless runs, and ensure autoload (`GameState`) -> helper script dependencies remain acyclic (`GameState` uses `load(...)` on `JournalLoreData.gd`; `PixelAssets` delegates `get_item_info` to `ItemCatalog.gd`).
- **Typed Array Helper Assignments:** When helper modules (`*Ambush.gd`, `*MapData.gd`, `*Cutscene.gd`) populate typed `Array[...]` properties on an untyped `r` region reference, use `.assign([...])` or `.clear()` + `.append(...)`.
- **Verification Tooling (`tools/smoke_test.ps1`):** Runs headless Godot (`--smoke-regions`) across all 33 `[F1]` presets, all 10 regions (Book I + Book II Act I), `[M]` Kingdom Charter views, Mind-Voice telepathy, `DragonNamePanel`, Vent/Ember puzzles, and Journal formatters, failing on any `SCRIPT ERROR` / `Parse Error`.
- **Remaining Low-Priority Notes:**
  - Local Git repository (`main` branch) tracks code, scenes, pixel/audio assets, docs, `.agents/`, `.vscode/settings.json`, and `tools/smoke_test.ps1`, while `.gitignore` excludes `.godot/`, `tools/godot/`, `books/`, and `*.log`/`*.tmp`.
  - **Zero GDScript files exceed 800 lines** after extracting `RegionNavHelper.gd` (259 lines) from `RegionBase.gd` (606 lines) and `PlaytestPresetsBook2.gd` (118 lines) from `PlaytestPresets.gd` (now 779 lines); `SettingsPanel.gd` (795), `LouvainCityRegion.gd` (787), `SanctuaryRegion.gd` (787), `BrugesCityRegion.gd` (786), `BrabantFensRegion.gd` (779), `PlaytestPresets.gd` (779), `FrontierWildsRegion.gd` (771), and `PortOfBrugesRegion.gd` (742) remain near the 800-line Split Watch mark and should extract dedicated sub-modules before appending major features (`sprite_portraits.py` sits at 1,192 lines under the 1,500-line Python watch).
