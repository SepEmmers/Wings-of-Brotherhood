# Wings of the Brotherhood — Game Design Document

> **Genre:** 2D Top-Down Zelda-Like Action-Adventure RPG  
> **Engine:** Godot 4.3 (`GL Compatibility`, GDScript)  
> **Setting:** Original Dark-Medieval Dragon Fantasy across Flanders, Brabant & the Meuse Borderlands  
> **Perspective:** Classic Top-Down / Three-Quarter 2D (*A Link to the Past* / *CrossCode* / *Tunic* feel) with multi-altitude sky parallax, Y-sorted depth, and `PointLight2D` dynamic lighting

---

## 1. Story Premise & Dual-Campaign Arc

### 1.1 Book I — Prologue: "Smoke Over Flanders" *(Implemented)*
- **Protagonist:** A boy (named by the player, default **Bram**) born in **Louvain**. At age 8, his veteran Dragon Hunter parents were killed near **Old Heverlee**; told a dragon slew them, he grew up hating dragons.
- **Bruges & Sanctuary (Age 12 → 17):** Living with **Uncle Willem** and sister **Clara** (a **Bruges Ropewalk** cordage-maker), Clara is abducted during a night raid—leaving a snapped dragon-harness strap tied with her signature whipping-knot. Attempting to inform Church authorities, the boy is intercepted by the outlawed **Brotherhood of Dragon Riders** and spared execution by **Captain Anna** (secretly his mother's sister). Over five years aboard Anna's emerald dragon ***Virelai***, he heals a captive silver-slate courier dragon (**Kestrel**, `she/her`) and outgrows his hatred.
- **Obsidian Hollow & Midnight Heist (Age 17):** Ambush in a storm separates him from *Virelai* in the **Whispering Pines**, where he rescues a black-with-gold egg entrusted by a dying **Black-Scaled Dragon**. Returning to Bruges, he learns **Father Anselm** and the **Inquisitor** have placed a dawn bounty on any black-and-gold egg. Lying to the Brotherhood Council to prevent them locking the egg inside an iron Ghent vault, he steals the egg back at midnight and flees into the sky aboard **Kestrel**.

### 1.2 Book II+ — Main Story: "The Golden Heir" *(In Design / Next Milestone)*
- **The Church's Devildragon Plot:** Publicly preaching dragon extermination, the Church's Inquisitor cabal is secretly harvesting **live dragon blood and dragon hearts** to summon a catastrophic **Devildragon** and seize continental rule.
- **The Golden Dragon Prophecy:** Ancient lore states **only a true Golden Dragon** is wise and powerful enough to unite all dragons and defeat the Devildragon. The dying Black-Scaled Dragon was a camouflaged Shadow-Guardian hiding the last **Golden Heir**—whose dark outer scales flake off stage by stage as it grows.
- **The Parents' Betrayal & Clara's Double Discovery:** At Old Heverlee, the parents uncovered the Devildragon ritual inside an excavated dragon-shrine and hid its **Ritual Key**; the Church murdered them to bury the secret. Five years later, Church raiders abducted Clara as a **Conscripted Rig-Master** to weave iron-hemp captive harnesses at **Namur**, only later realizing she is the daughter of the hunters who hid their relic.
- **Dual-Perspective Structure:** Alternating chapters between **The Boy** (overland journey, cities, Golden Shrines, raising the Hatchling) and **Captain Anna** (stalling Hendrick and the Council elders, flying *Virelai* sorties to raid blood-wagons and free captive dragons, dispatching scouts and supplies ahead). **Kestrel** stays hidden with Anna's forward scouts outside city walls and serves as the **main winged courier linking Anna and the Boy**.

---

## 2. Core Gameplay Pillars & Dual-Perspective Loop

```text
  [ BOY PERSPECTIVE (Overland & Cities) ] <--- Kestrel Dispatches ---> [ ANNA PERSPECTIVE (Sky & Covert) ]
   • Foot travel across playable routes                                 • Stall Sanctuary Elders & Hendrick
   • Hatchling Companion (4 Growth Stages)                              • Virelai aerial raids on blood-wagons
   • Cloak-sling stealth & City Bounty Heat                             • Rescue wild dragons for finale army
   • Zelda melee/knot combat & Golden Shrines                           • Dispatch scout drops to Boy's route
```

### 2.1 Growing Dragon Companion Mechanics (`HatchlingCompanion`)
The Golden Dragon begins as a tiny soot-black hatchling pattering behind the Boy and grows through **4 distinct mechanical stages** (via Story Shrines + Campfire Bond):

1. **Stage 1 — Hatchling (Act I: Brabant Fens, Louvain, Old Heverlee):**
   - *Communication:* Mute chirps/purrs + faint emotional pulses; early **Navi-style telepathic impressions** into the Boy's mind.
   - *Active Command (`[R]`):* Crawl through tiny crypt/alley grates to open barred doors; **Ember Puff** to light dark sconces, unlit hearths & dry briars.
   - *Passive Cue:* **Gold-Sense** scale shimmer & soft chirp near prophetic carvings, hidden caches, and relic trails.
2. **Stage 2 — Fledgling (Act II: Hesbaye Uplands, Namur Cliff-Citadel):**
   - *Communication:* Clear telepathic voice (heard only by the Boy) giving tactile puzzle/weak-point observations (e.g., *"hmm, that iron catch looks weak if struck while braced"*) without breaking immersion with UI key spoilers.
   - *Active Command (`[R]`):* **Glide-Boost** across wider chasms; **Knot-Combo Lunge** (strikes armored Catchpoles snared by `[F]`); **Resonance Chirp** to crack brittle masonry walls and jam alarm bells.
3. **Stage 3 — Young Drake (Early Act III: Ardennes & Sunken Cairn):**
   - *Communication:* Seasoned tactical telepathy; senses distant captive dragons. Too large to conceal inside cities.
   - *Active Command (`[R]`):* **Fortress Wall-Vault** over palisades; **Golden Flame** melting iron grates and heavy siege-shields; **Wing-Shield** deflecting crossbow volleys.
4. **Stage 4 — Awakened Golden Dragon (Climax: Blood-Citadel):**
   - *Full Sky Mount & Golden Rally:* Unlocks full aerial flight and unites *Virelai*, *Kestrel*, and rescued wild dragons in the final sky-and-citadel battle.

**Companion Controls & AI Posture:**
- **Active Pet Command (`[R]`):** Context-sensitive action toward facing target/enemy/grate (vent crawl, ember puff, knot-combo strike, flame/resonance).
- **AI Posture Toggle (e.g., `[X]` or Quick Toggle):** Switch between **Assist** (follows closely, lights nearby torches, opportunistically flanks roped foes) vs **Stay / Tuck in Cloak-Sling** (silently conceals Hatchling inside hooded sling in towns or holds position during stealth).
- **Telepathic Hint (`[T]`):** Optional Navi-style mental nudge from the dragon reflecting on the current puzzle, enemy weak spot, or local atmosphere.

### 2.2 Making "The Journey" Half the Game (Overland Routes + Campfires)
Cities are separated by full playable **Route Regions** (building on `RegionBase` + `FrontierWildsRegion` design) rather than fast-travel menus:
- **Route Gameplay:** Broken bridges repaired via knots, hunter roadblocks, bandit/smuggler camps, **Golden Dragon Shrines** (mini Zelda dungeons unlocking dragon growth/abilities), and Anna's hidden scout supply caches unlocked by Kestrel dispatches.
- **Campfire Rest & Bond System (Rewarding Loop — No Punishing Timers):**
  - Sheltered roadside/ruin campfires serve as healing checkpoints and progression hubs without frustrating frost-death countdowns.
  - **Feed & Grow:** Prepare and feed town-bought provisions or hunted game (integrating `scripts/ui/ButcherMinigamePanel.gd` and market economies) to raise Dragon Bond and unlock passive/combat perks.
  - **Kestrel Courier Handoff:** Send/receive dispatches from Anna at key route campfires, cleanly transitioning into Anna's parallel chapters and receiving route bonuses from her aerial raids.

### 2.3 Fine-Tuned Combat, Stealth, Knots & City Bounty Heat
- **Healthy Stealth + Zelda Combat Blend:**
  - **Stealth First When Outnumbered:** Vision-cone patrols (`can_vision_cone_see`), distraction tools (e.g., Louvain's **Bronze Resonance Chime**, **Smoke-Pellets**), canal barges/rooftops, and concealing the Hatchling in the **Cloak-Sling** inside walled cities.
  - **City Bounty Heat:** Since the Church bounty is active from Act I onward, acting recklessly, triggering alarms, or letting golden glints show raises local **Bounty Heat**; tearing down **Wanted Posters**, laying low, or using guild/smuggler routes cools suspicion.
  - **Snappy Melee & Knot Combat (`PlayerBoy.gd`):**
    - **Dock Knife (`[V]` / LMB):** Upgrade from single slash to a **3-hit directional combo** + crisp **dodge-counter strike** right out of `[C]` roll.
    - **Distinct Combat & Puzzle Knots (`[F]` / RMB):**
      - *Clove Hitch:* Pull switches, mooring cleats, light chests/bells.
      - *Bruges Whipping-Knot:* **Yanks shields straight out of Catchpole hands** & hauls heavy crates/grates.
      - *Bowline:* Wide rescue lasso that snares multiple guards/hounds briefly.
      - *Harness Splice:* Winch-dash across chasms OR zip directly into stunned enemies for heavy knockback.
    - **Knot Board Minigame (`KnotMinigame.gd`):** Keep the tactile mouse-driven pegboard for **unlocking new knots, high-stakes mid-flight harness repairs, and cracking complex Church/siege winches**—while letting mastered knots fire smoothly in real-time combat and puzzles.

### 2.4 Distinct City Hubs & Side Stories
- **Louvain (Act I — City of Bells & Locked Archives):** Scholarly Dijle river city, Abbey Scriptorium heist, Hunters' Guild Tavern, Wanted Posters, and 3 rich side stories (*Deaf Bell-Founder*, *Dyers' Herbalist*, *One-Eyed Old Heverlee Survivor*).
- **Namur Cliff-Citadel (Act II — Iron Foundries & Dragon Rig-Works):** Limestone cliff fortress over the Meuse River—cable hoists, smelting foundries, river smugglers, captive-dragon harness yards where **Clara** is discovered alive, and forge-sabotage side stories.
- **Church Blood-Citadel (Act III — High Inquisitor Stronghold):** Heavily fortified highland chasm where the Devildragon summoning ritual, Clara's sabotage, Anna's dragon coalition, and the Golden Dragon's awakening collide.

---

## 3. Book I Reference Systems (Implemented Baseline Architecture)

### 3.1 Existing Chapters (`Book I: Opening Chapters`)
| Chapter | Title | Implemented Playable Regions & Key Beats |
| :--- | :--- | :--- |
| **Ch. 1** | **Port of Bruges & The Missing Night** | `PortOfBrugesRegion.gd`, `WillemHouseRegion.gd` — *De Zwaan* docking, harbor errands, Ropewalk, dawn Watchmen stealth, Brotherhood ambush. |
| **Ch. 2** | **Sanctuary & Wings of *Virelai*** | `SanctuaryRegion.gd`, `VirelaiFlightRegion.gd` — 5-year Sanctuary progression (`Age 12 -> 14 -> 17`), treating Kestrel, Coast Patrol & Storm Recon sorties. |
| **Ch. 3** | **Obsidian Hollow & The Living Egg** | `FrontierWildsRegion.gd`, `WatchtowerHearthRegion.gd` — Dying Black-Scaled Dragon, egg rescue & warmth trek across Whispering Pines. |
| **Ch. 4** | **Walled City of Bruges & Midnight Heist** | `BrugesOutskirtsRegion.gd`, `BrugesCityRegion.gd`, `SanctuaryAct4.gd` — Canal boats/winches, Catchpole skirmishes, Father Anselm tailing, stealing the egg back & escaping on Kestrel. |

### 3.2 Core Technical Structure (`scripts/`, `scenes/`)
- See [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) for the live file map, line-count guardrails (`<400` target, `<800` split required), `RegionBase` chunked ground/water rendering rules, and [`docs/HANDOFF_BOOK2_IMPLEMENTATION.md`](HANDOFF_BOOK2_IMPLEMENTATION.md) for the Book II+ engineering roadmap.
