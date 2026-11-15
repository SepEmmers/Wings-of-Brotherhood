# Book II Implementation Handoff — *Wings of the Brotherhood*

> **Audience:** Feature / Engineering Agent taking over Godot 4.3 implementation while narrative & gameplay design continues separately.  
> **Canonical Context (Read First):**
> 1. [`docs/game story.txt`](game%20story.txt) — Full Prologue + Main Story (Acts I–III, Dual Perspectives, Prophecy & Conspiracy)
> 2. [`docs/LORE_COMPENDIUM.md`](LORE_COMPENDIUM.md) — Original dark-medieval dragon lore, 4 Hatchling Growth Stages, Devildragon & Factions
> 3. [`docs/GAME_DESIGN_DOCUMENT.md`](GAME_DESIGN_DOCUMENT.md) — Full gameplay design, controls, companion, campfire & city heat specs
> 4. [`.agents/rules/story-and-lore-continuity.md`](../.agents/rules/story-and-lore-continuity.md) and [`.agents/rules/architecture-and-maintainability.md`](../.agents/rules/architecture-and-maintainability.md)

---

## 1. Creative Pivot Summary (Why Everything Changed)

The project has **fully pivoted away from the *Temeraire* universe** and is now an original dark-medieval dragon fantasy titled ***Wings of the Brotherhood***.
- **Book I (`PortOfBruges` → `SanctuaryAct4` Kestrel Escape)** remains intact as the **Prologue**. Do not break Book I quest steps (`0..14`) or Prologue regions while building Book II.
- **Book II+ ("The Golden Heir")** picks up immediately after the Boy flies away from the Bruges Sanctuary at midnight aboard **Kestrel** (`she/her`) carrying the black-and-gold egg.
- **Place Names:** Keep Englishized spellings (`Port of Bruges`, `Louvain`, `Old Heverlee`) alongside new hubs (`Brabant Fens`, `Hesbaye Uplands`, `Namur`, `Ardennes`, `Blood-Citadel`) to stay consistent with Book I dialogue.

---

## 2. Core New Gameplay Systems & Existing Mechanic Upgrades

Before authoring new regions, build these **reusable core systems** cleanly outside the oversized `GameUI.gd` (`>800` lines) and `PlayerBoy.gd` (`644` lines):

### 2.1 `HatchlingCompanion` System (`scripts/companions/HatchlingCompanion.gd`)
The Golden Dragon hatches in Act I and physically **follows the player** throughout the Boy's chapters across **4 growth stages**:
- **State (`GameState.gd`):** Track `dragon_stage: int` (`0 = egg`, `1 = hatchling`, `2 = fledgling`, `3 = drake`, `4 = golden`), `dragon_bond: int`, `dragon_posture: String` (`"assist" | "stay" | "sling"`), and `unlocked_dragon_abilities: Array[String]`.
- **Stage Visuals & Follow Physics:** Smooth spring/trail follow behind `PlayerBoy`, obstacle steering, jumping onto Boy's pack during `winch_dash_active`, and hiding completely inside a hooded sling sprite/badge when `dragon_posture == "sling"` (required in Stage 1 inside walled towns like Louvain!).
- **Active Command (`[R]` / new `InputMap` action `dragon_command`):** Context-sensitive action aimed along `player.facing`:
  - *Stage 1 (Hatchling):* **Vent Crawl** (slips through `dragon_vent` interactables/grates to unlock doors from inside) & **Ember Puff** (lights braziers/torches, burns dry briars, brief guard startle). Also passive **Gold-Sense** scale shimmer + soft chirp near prophetic relics/secrets.
  - *Stage 2 (Fledgling):* **Glide-Boost** across wider chasms (`winch`-style glide arc), **Knot-Combo Lunge** (strikes armored Catchpoles currently snared by `[F]`), **Resonance Chirp** (cracks brittle walls & jams Church alarm bells).
  - *Stage 3 (Young Drake):* **Fortress Wall-Vault**, **Golden Flame** (melts iron grates/shields), **Wing-Shield** (blocks crossbow volleys).
- **AI Posture Toggle (e.g., `[X]` / `dragon_posture`):** Cycles **Assist** (follows, auto-lights unlit braziers, flanks roped foes) vs **Stay / Cloak-Sling** (silent stealth inside cities / wait behind cover).
- **Automatic Stuck-Time Telepathic Hints (No Manual Button):**
  - The hatchling starts mute (chirps/purrs) in early Act I, then **awakens telepathic speech stage-by-stage** heard *only* in the Boy's mind.
  - Instead of a manual hint button, `HatchlingCompanion` tracks inactivity / lack of objective progress (`stall_timer`) and automatically surfaces a brief non-intrusive Mind-Voice observation if the player stays stuck on a puzzle, stealth choke-point, or armored foe for a long stretch (resetting whenever progress advances; never embedding raw button keys inside the speech text!).
  - **Rule Note:** Telepathic speech is real dialogue inside the Boy-Dragon bond (see `.agents/rules/story-and-lore-continuity.md` & `docs/ENVIRONMENTAL_STORYTELLING.md`). Style its dialogue frame subtly differently from spoken human/Virelai speech (e.g., warm gold-rimmed border, no physical lip-voice blip—use gentle golden chime/hum!).

### 2.2 Combat & Knot Fine-Tuning (`PlayerBoy.gd` + combat helpers)
The target feel is a **healthy blend of stealth-first tension and snappy tactical Zelda combat**:
- **Dock Knife (`[V]` / LMB):** Upgrade from a single swipe into a **3-hit directional slash combo** (`combo_step` timer window) + a crisp **dodge-counter thrust** immediately after `[C]` Dodge-Roll.
- **Distinct Combat & Puzzle Knot Roles (`KnotCatalog.gd` + regions):**
  - *Clove Hitch:* Pulls light switches, levers, mooring rings.
  - *Bruges Whipping-Knot:* **Yanks shields directly out of Catchpole hands** (converting shielded foes to vulnerable!) and hauls heavy grates/crates.
  - *Bowline:* Wide rescue lasso that snares/roots multiple nearby guards/hounds.
  - *Brotherhood Harness Splice:* Winch-dashes across chasms **or** zips straight into stunned/snared foes for heavy impact knockback.
- **Pacing Rule for `KnotMinigame.gd`:** Keep the tactile oak-board minigame for **learning new knots, pressurized flight/rig repairs, and cracking complex Church locks/siege winches**—do NOT interrupt fast on-foot combat with the minigame every cast.

### 2.3 Overland Journey & Campfire Bond Loop (`scripts/ui/CampfirePanel.gd` + Route Regions)
Replace punishing frost/hunger countdown timers with a **rewarding Campfire Rest & Bond system** placed along playable overland Route Regions:
- **Rest & Heal:** Restores HP and resets local safety state.
- **Feed & Grow (`ButcherMinigamePanel.gd` integration):** Slice/prepare town-bought or hunted provisions (fish, mutton, river game) to feed the hatchling, raising `dragon_bond` and unlocking growth/passive combat perks.
- **Kestrel Courier Dispatch (`Perspective Handoff`):** At story-milestone campfires outside cities, **Kestrel (`she/her`)** arrives from Anna's forward scouts to deliver supply caches/intel—and serves as the **narrative handoff trigger into Anna's perspective chapters** (and back!).

### 2.4 City Bounty Heat & Cloak-Sling Stealth (`scripts/systems/CityHeatHelper.gd`)
Because the Church's **black-and-gold egg bounty** goes live right after Book I:
- **Hatchling Concealment:** Inside walled cities during Stage 1–2, keeping the hatchling tucked in the **Cloak-Sling** prevents instant bounty alarms; letting it out in sight of Catchpoles or failing stealth spikes **Bounty Heat**.
- **Cool Down & Traversal:** Tearing down **Wanted Posters** on city walls, using back-alleys/rooftops/canal boats (`BrugesCityBoats.gd` pattern), distracting guards with throwable **Bronze Resonance Chimes** / **Smoke-Pellets**, or laying low cools Heat back down.

### 2.5 Dual-Perspective Support (`GameState.gd` + `Main.gd`)
Support switching `active_protagonist: String` (`"boy"` vs `"anna"`):
- **Boy Chapters:** Ground controller (`PlayerBoy.gd` + `HatchlingCompanion`).
- **Anna Chapters:** Reuse `SanctuaryRegion.gd` (Council standoff / Elder deception) and an expanded **`VirelaiFlightRegion.gd`** (free-aiming sky raids on Church **Blood-Harvest Wagons & River Barges**, rescuing captive wild dragons, dispatching scout caches via Kestrel).
- **Cross-Perspective World State:** Flags set during Anna's chapters (e.g., `anna_raided_hesbaye_convoy`, `anna_dropped_scout_cache`) tangibly alter patrol density or spawn supply crates inside the Boy's subsequent route regions!

---

## 3. Phased Build Roadmap

### Milestone 0 — Pre-Flight & Shared Plumbing (Small, Safe Foundation)
- Fix Kestrel's pronouns in existing Book I diary/dialogue (`JournalLoreData.gd`, `SanctuaryNarrative.gd`) from `he/his` -> `she/her` if updating Book I consistency (optional small cleanup).
- Register new `InputMap` actions in `GameState._ensure_input_actions()`:
  - `dragon_command` (`R`)
  - `dragon_posture` (`X`)
  - *(No manual hint hotkey — `HatchlingCompanion` triggers automatic stuck-time telepathic hints.)*
- Add new `QuestStep` entries for Book II Act I (`BOOK2_BRABANT_FENS`, `BOOK2_LOUVAIN`, `BOOK2_OLD_HEVERLEE`, `BOOK2_ANNA_RAID_1`, etc.) without altering indices `0..14`.
- Update `GameUI.gd` checkpoint overlay (`SanctuaryAct4.gd` finale `"INTO THE NIGHT SKY — WINGS OF FREEDOM"`) so pressing Continue can transition cleanly into Book II once Brabant Fens is ready (and register every new beat in `PlaytestPresets.gd` `[F1]`).

### Milestone 1 — Core Companions & Combat Upgrades
- Implement `HatchlingCompanion.gd` + `CampfirePanel.gd` (in `scripts/ui/`).
- Add 3-hit Knife combo + dodge-counter + distinct Whipping Shield-Yank / Bowline snare / Splice zip behavior in `PlayerBoy.gd` (extract combat helper module if `PlayerBoy.gd` approaches `>800` lines!).
- Queue placeholder sprites via `.agents/skills/pixel-art-generator/scripts/sprite_placeholders.py` + `docs/SPRITE_TRACKER.md` (`- [ ]`) for:
  - Hatchling 4-direction walk/idle/ember/shimmer sprites (Stage 1)
  - Boy Cloak-Sling carry/badge variant
  - Wanted Poster, Bronze Chime, Blood-Harvest Wagon, Golden Shrine monoliths

### Milestone 2 — Act I Part 1: `BrabantFensRegion` + `LouvainCityRegion`
- **`BrabantFensRegion.gd` (Overland Route Leg 1):**
  - Opening cutscene: Kestrel sets the Boy down in misty river ruins west of Louvain and flies east to join Anna's scouts.
  - First Campfire: **Egg Hatching Cutscene**; tutorializes Vent Crawl, Ember Puff, Gold-Sense, and `[T]` Navi telepathic nudge inside a small ruined mill.
- **`LouvainCityRegion.gd` (Hub 1 — City of Bells & Locked Archives):**
  - Distinct Dijle river city (`kit_buildings.py` + `kit_npcs.py`): **Abbey Scriptorium**, **Old Hunters' Guild Tavern**, **Bell-Foundry**, **Dyers' Alley**, Wanted Posters & Catchpole stealth.
  - **Main Beat:** Parents' guild trail → Abbey Scriptorium infiltration (hatchling crawls crypt vent & lights vault sconces) → uncover Church Decree on *"Old Heverlee Shrine Key"* + 5-year warrant moving *"Clara of Bruges"* to **Namur** → courtyard ambush & **Golden Resonance shriek** breakout toward Old Heverlee.
  - **3 Side Stories:** Deaf Bell-Founder (`Bronze Resonance Chime`), Dyers' Herbalist (`Smoke-Pellets`), One-Eyed Old Heverlee Survivor (`Parents' Compass / Inquisitor confession`).

### Milestone 3 — Act I Part 2: `OldHeverleeRegion` & Anna Perspective Chapter 1
- **`OldHeverleeRegion.gd` (Overland Route + First Golden Shrine):**
  - Haunted woods & parents' ambush site → **First Golden Dragon Shrine** (puzzle dungeon using Knife + Knots + Hatchling Stage 1 abilities) → recover the **Old Heverlee Relic Key** and learn the Church harvests **dragon blood & hearts for the Devildragon ritual**.
  - Campsite handoff: **Kestrel arrives** → Boy sends dispatch to Anna → transitions to Anna Chapter 1!
- **Anna Chapter 1 (Sanctuary Standoff + *Virelai* Blood-Barge Raid):**
  - Short playable Sanctuary beat deceiving Hendrick's elders → launch *Virelai* raid destroying a Church river blood-wagon and freeing captive dragons → send Kestrel back with supply drop for Act II Hesbaye route.

### Milestone 4 — Act II & III (Future Milestones — Outline Ready)
- **Act II:** `HesbayeUplandsRegion.gd` (Fledgling Stage 2 growth + glide-boost/combo combat) → `NamurCitadelRegion.gd` (iron foundries, river smugglers, seeing **Clara** alive at the rig-works before High Inquisitor moves east) → **Anna Chapter 2** (Council break & multi-dragon rescue).
- **Act III:** `ArdennesHighlandsRegion.gd` (Young Drake Stage 3) → `BloodCitadelRegion.gd` (Stage 4 Awakened Golden Dragon, Devildragon boss, Clara sabotage + Anna/*Virelai*/Kestrel convergence).

---

## 4. Technical Rules & Verification Guardrails (Must Follow)

1. **Line-Count Limits (`.agents/rules/architecture-and-maintainability.md`):**
   - `GameUI.gd` (`926`), `FrontierWildsRegion.gd` (`896`), `BrugesCityRegion.gd` (`862`), `SanctuaryRegion.gd` (`818`) are **over 800 lines** — **do NOT bloat them**. Put all new UI panels in `scripts/ui/` and split every new region into `<Region>Region.gd` + `<Region>MapData.gd` + `<Region>Draw.gd` (plus cutscene/encounter helpers).
   - If editing `PlayerBoy.gd` (`644` lines), extract combat/companion-command helpers into a separate script so `PlayerBoy.gd` stays under `800` lines.
2. **Region Performance (`RegionBase.gd`):**
   - Bake static ground into `720x720` chunks (`setup_static_ground_chunks`), render water with `setup_water_layer` / `step_water_layer`, cull entities via `get_camera_rect()`, flip with negative width `Rect2` (no per-sprite `draw_set_transform`), and call `sync_light_frustum()`.
3. **Triple Map Sync & Trackers:**
   - Register every new region in `Main.gd`, `PlaytestPresets.gd` (`[F1]`), `docs/ARCHITECTURE.md`, `docs/WORLD_TOPOLOGY.md`, `ForestMapPanel.gd`, and `bruges_map_builder.html`.
   - Use `kit_buildings.py` / `kit_npcs.py` / `PlayerBoy.CARRY_PROPS` before making custom sprites; log non-kit visuals in `sprite_placeholders.py` + `docs/SPRITE_TRACKER.md` (`- [ ]`).
   - Log any temporary non-diegetic text in `docs/ENVIRONMENTAL_STORYTELLING.md` (`- [ ]`).
4. **Headless Verification After Every `.gd` / `.tscn` Edit:**
   - Run Godot 4.3 headless check (`.agents/skills/game-verifier/SKILL.md`) and verify `ExitCode=0` with zero errors or ObjectDB leaks.
