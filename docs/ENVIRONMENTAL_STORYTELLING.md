# Environmental Storytelling & Diegetic Presentation Queue

> **Core Vision — "Only Real-Life Words Use Words":**
> In the finished vision for *Wings of the Brotherhood*, written or displayed words should exist **only where words exist in real life**:
> 1. **Spoken & Telepathic Dialogue** between humans, speaking elder dragons (*Virelai*), and the **Golden Dragon's telepathic bond thoughts** (unlocked stage-by-stage into the Boy's mind, heard by no one else).
> 2. **Actually Reading Real-World Writing** (harbor decrees, parchment maps, noticeboard postings, wanted posters, wooden town/market signs, written diaries/letters).
>
> Everything else — silent thoughts/solo self-talk, narrator captions, system toast boxes, mute dragon body-language prose, and floating text labels over rocks, animals, beds, or combat targets — is **strictly transitional**.
>
> **Working Rule Right Now:** Keep using temporary text narration while rapidly building features so gameplay stays clear, **provided every single such visual narration, solo inspect line, toast box, or non-sign world label is logged here as `- [ ]`** so an animation/polish pass can replace it with real in-world visuals and strip the words.

---

## Workflow Rules for Agents

1. **Always Log Any Non-Diegetic Text (`- [ ]`):** Whenever you add or touch any line where a character talks to empty air about what they see, a UI box describes an animation/item gain, a non-speaking creature has a text caption, or `draw_label_shadowed` renders words over something that isn't a real-life sign:
   - Log an unchecked `- [ ]` item below with **File / Function**, **Current Temporary Text**, and **Target Animation / Visual / SFX Replacement**.
   - Keep working as usual for gameplay clarity until that replacement pass is executed.
2. **Delete Words Once Visualized (`- [ ]` -> `- [x]`):** When implementing an entry below with sprites, animations, lighting, SFX, or world props, **delete the replaced text** (unless someone genuinely speaks aloud or reads an in-world document) and flip `- [ ]` to `- [x]`.
3. **Never Pair Temporary Text With Hand-Holding:** Keep button spoilers (`[F]`, `[V]`, `[C]`, `[M]`, `[E]`) and blunt puzzle solutions out of spoken dialogue and inspect prose; convey physical affordances visually first.

---

## Active Queue — Text Awaiting Visual / Environmental Replacement (`- [ ]`)

### Queue 1 — Silent Self-Narration & Solo Inspect Monologues (`GameState.player_name` talking alone)

#### Chapter 1: Port of Bruges & Willem's House
- [x] **Bruges Noticeboard Personal Reflection** (`scripts/regions/PortOfBrugesRegion.gd` -> `_on_read_noticeboard`): Kept the actual written Harbor Decree & Faded Brabant Roll ink text; stripped the appended unspoken personal thought.
- [x] **Harbor Rope, Hook & Knife Failure/Inspect Thoughts** (`scripts/regions/PortOfBrugesRegion.gd`, `PortOfBrugesDraw.gd`): Replaced solo rope/hook/slice/chime/door thoughts with canal splash & hemp-skid spark bursts, snapping blade gleams (`twine_glint_timer`), piling eddy rings (`rigging_ripple_timer`), rattle cue + pulsing overhead errand hints (`errand_hint_timer`), and quiet tension thuds beside the Herald.
- [x] **Willem's Cottage Dawn Clues & Watchmen Warning** (`scripts/regions/WillemHouseRegion.gd`): Replaced dawn wake-up, bed refuse, leather strap inspect, and threshold thoughts with cold door drafts (`draft_wisps`), fluttering strapped jams (`prop_knot_clue.png`), smooth camera pan to the unbarred threshold (`dawn_clue_pan_timer`), kneeling mute recognition (`clue_hold_timer`), latch rattle + lantern aura pulse, and dawn Watchmen exit pan (`dawn_peek_timer`).

#### Chapter 2: Brotherhood Sanctuary (Age 12 -> 17)
- [x] **Carry-State & Gorge Tool Self-Talk** (`scripts/regions/SanctuaryRegion.gd`, `SanctuaryDraw.gd`, `SanctuaryNarrative.gd`): Replaced carry-prop, winch bounce, metallic clink, wing-clasp, and grease/poultice self-talk with `npc_wave_target` beckoning arm waves + target icon cues, `fx_particles` sparks/splashes, and physical tail-nudge knockback instead of `"nearly bumped me off the flagstones"`.
- [x] **Virelai Shoulder Bow & First Carabiner Monologue** (`scripts/regions/SanctuaryRegion.gd`, `SanctuaryDraw.gd`): Animated Virelai's `1.15s` shoulder wing-dip (`virelai_bow_dip`), slate dust puffs, and amber `virelai_eye_flare` blink before opening `dragon_splice`, keeping only Anna's spoken praise afterward.
- [x] **Kestrel Wing Salving Solo Empathy Lines** (`scripts/regions/SanctuaryRegion.gd`, `SanctuaryDraw.gd`): Replaced solo empathy narration with shivering recoil damping into calm leaning (`salve_shiver_amp`, `salve_anim_timer`) inside glowing green `sage_vapor` particles before Anna's spoken remark.
- [x] **Crew Props Inspect & Montage Wake-Up Thought** (`scripts/regions/SanctuaryNarrative.gd`, `SanctuaryMontageCutscene.gd`): Replaced solo victual/livestock prop thoughts and Matthijs wake-up callout with `victual_flash`, `livestock_bounce_timer`, `npc_wave_target = "matthijs"` arm/icon cues, and chimes.

#### Chapter 2: Aerial Sorties (`VirelaiFlightRegion.gd`)
- [x] **Loose Buckle & Bestiary Sketch Self-Talk** (`scripts/regions/VirelaiFlightRegion.gd`, `VirelaiFlightDraw.gd`): Replaced mid-air buckle slip failure text and Bestiary sketch confirmation boxes with `strap_slip_flash` sparks + snag SFX + camera shake and an animated flying charcoal sketch sheet (`sketch_fly_fx`) arcing cleanly into the HUD Diary corner icon.

#### Chapter 3: Frontier Wilds & Watchtower Hearth
- [x] **Frontier Wilds Tracks, Obstacles & Warmth Self-Talk** (`scripts/regions/FrontierWildsRegion.gd`, `FrontierWildsDraw.gd`): Replaced crash recovery, winch range/tool/tackle failure, cold egg reset, hunter scout boy-recap, briar slash, hollow gate, fern tracks, ballista map, and signal flare solo text boxes with pine-needle wakeup puffs + camera jolt, pulsing winch hint & player reach rings, viewport frost-rime & orange warmth reset flash (`frost_reset_flash`), hollow root rattle (`gate_rattle_timer`), silent map/track kneels, and skyward emerald flare camera peek (`flare_peek_timer`) + shockwave ring (preserving the Hunter Scout's spoken shout).
- [x] **Obsidian Hollow Dying Mother Reveal & Causeway Blast Recap** (`scripts/regions/FrontierWildsRegion.gd`): Replaced the dying black dragon's wing-lift pause thoughts and post-blast egg monologue with silent multi-stage wing-lift, warm nest embers, kneeling mourning beat, and HUD Map pulse.
- [x] **Watchtower Hearth Warmed-Egg Transition Thoughts** (`scripts/regions/WatchtowerHearthRegion.gd`): Replaced `_on_inspect_hatchling` solo text with warm golden ember showers, `egg_wobble` magma pulse, and `flash_ring_t` glow.

#### Chapter 4: Bruges City, Priest Tailing & Midnight Sanctuary Heist
- [x] **Walled Bruges Intro, Tactical Hint & Solo Victory Lines** (`scripts/regions/BrugesCityRegion.gd`, `BrugesCityDraw.gd`): Replaced dusk arrival, shield-defeat, dropped scrap alert, post-note deduction, Keep exit, wagon reflection, and bracketed eavesdrop thoughts (`"(No—he knows about the egg!...)"`) with evening city-bell pan (`city_cam_focus_t`), iron shield clang sparks, camera focus glide + glint over `DROPPED_NOTE_POS`, emerald South Gate chevron arrow, and tactile cobblestone boot-scrape sparks + step SFX (`eavesdrop_scrape_t`) triggering the Inquisitor's shout (keeping `Dropped Ambush Note` ink text and all spoken lines).
- [x] **Father Anselm Stealth Tailing Warning & Return Lie Monologue** (`scripts/regions/BrugesCityRegion.gd`, `scripts/regions/SanctuaryAct4.gd`, `SanctuaryDraw.gd`): Replaced the 8 PM time banner & stealth tip, Return-lie inner monologue, midnight heist intro, pedestal inspect/pickup thoughts, and pre-egg Kestrel whisper with twin St. Donatian's bell tolls + priest camera pan, midnight tripwire/brazier shimmer, emerald Kestrel ridge beacon (`act4_egg_stolen_back`), and speechless Kestrel `egg_hint` thought icon + chirp SFX.

---

### Queue 2 — System / Toast Boxes (`Journal Note` & Failure Dialogues)
- [x] **Item & Map Pickup Toast Boxes** (`scripts/regions/PortOfBrugesRegion.gd:506`, `scripts/regions/WillemHouseRegion.gd:146`, `scripts/regions/FrontierWildsRegion.gd:531`): Replaced toast dialogues with overhead item/scroll holds, chime SFX, and golden `pulse_hud_icon()` corner glow.
- [x] **Knot Slip Failure Text Box** (`scripts/GameUI.gd`, `scripts/KnotMinigame.gd`): Removed fallback failure dialogue in `_on_knot_minigame_failed` and replaced it with board shake, red snap flash, slack rope recoil whip, peg spark bursts, and rope-snag SFX.

---

### Queue 3 — Mute / Non-Speaking Creature Captions (`Kestrel (Silver Greyling)`)
- [x] **Kestrel Phase 2 & 3 Inspect Dialogue Box** (`scripts/regions/SanctuaryRegion.gd`, `SanctuaryDraw.gd`): Replaced mute Kestrel captions with beak-snaps, sleeve nose-bumps (`nuzzle`), feather-crest plumes (`crest`), speechless herring/poultice/egg thought bubbles, and trill SFX.
- [x] **Kestrel Midnight Escape Stage-Direction Caption** (`scripts/regions/SanctuaryAct4.gd`): Replaced prose stage direction with `1.15s` crouching `wing_ramp` bow, slate feather bursts, silver trill SFX, and wingbeat takeoff.
- [x] **Virelai Chopped Mutton Feast Polish** (`scripts/regions/SanctuaryDraw.gd`, `scripts/regions/SanctuaryRegion.gd`): Added scattered two-tone mutton crumbs, ear-crest flutter, and tail-sweep dust puffs (plus physical tail nudge on interaction).

---

### Queue 4 — Floating Non-Sign World Text Labels & Transitional Era Banners
*(Keep written text ONLY where an actual physical sign, poster, book, or parchment exists in the world.)*
- [x] **Willem's Cottage & Bruges Non-Sign Labels** (`scripts/regions/WillemHouseRegion.gd`, `scripts/regions/PortOfBrugesDraw.gd`): Removed bed and Herald labels, leaving `"Noticeboard"` strictly on the painted board.
- [x] **Sanctuary & Wilds Scenery/Prop Floating Labels** (`scripts/regions/SanctuaryDraw.gd`, `scripts/regions/SanctuaryVillageData.gd`, `scripts/regions/FrontierWildsDraw.gd`): Replaced world text labels with silhouettes, flapping cord, pulsing glints, and carved oak stall plaques strictly on actual stalls.
- [x] **Flight Combat & Net Labels** (`scripts/regions/VirelaiFlightDraw.gd`): Replaced `"WRECKED"`, `"Ballista (%d/%d)"`, `"Shoot Net (%s)"`, and `"[F] SPLICE LOOSE BUCKLE!"` with smoldering broken wagon wheels & embers, physical bolt-rack slots & hull damage cracks/smoke, vibrating strained corner anchor cables, and flashing left-flank harness buckle sparks.
- [x] **Transitional Time-Skip Montage Stamps** (`scripts/regions/PortOfBrugesRegion.gd`, `scripts/regions/BrugesCityRegion.gd`, `scripts/regions/SanctuaryMontageCutscene.gd`, `scripts/regions/SanctuaryAct4.gd`): Stripped all remaining `show_time_stamp` banners (`"De Zwaan Coming Alongside"`, `"WALLED CITY OF BRUGES"`, `"8:00 PM — Evening"`, `"SANCTUARY NEAR BRUGES"`, and all 8 `Year 1 -> Year 5` montage cards), relying on weather progression, character growth, bell tolls, lighting shifts, and live dragon approaches.

---

## Completed Environmental Upgrades (`- [x]`)

- [x] **Sanctuary Living Quarters & Livestock Pastures** (`scripts/regions/SanctuaryVillageData.gd`, `scripts/regions/SanctuaryDraw.gd`): Built cozy covert cottages, victualer stalls, mess tables, dragon pavilions, fenced sheep/cow/hog pastures, water troughs, and proximity pasture/mess ambience mixing.
- [x] **Boy Cradling Obsidian Egg Posture** (`scripts/PlayerBoy.gd` + `kit_boy_carry.py`): Added physical two-armed cradling sprite overlay (`boy_cradle_hands_*` + `prop_dragon_egg_held.png`) throughout Whispering Pines.
- [x] **Seasonal Time-Skip Montage Cutscenes (`Year 1 -> 3 -> 5`)** (`scripts/regions/SanctuaryMontageCutscene.gd`, `scripts/ui/TimeSkipPanel.gd`): Replaced black chronicle walls-of-text with live animated multi-season montages (winter lofts, uncaged Kestrel healing in rising sage vapor, spring drill leap, coastal flight, moonlight strap vigil, storm ridge).
- [x] **Virelai Storm Ambush, Longwing Venom Arcs, Eye Flare & Loose Strap** (`scripts/regions/VirelaiFlightCutscene.gd`, `VirelaiFlightDraw.gd`, `SanctuaryRegion.gd`, `SanctuaryDraw.gd`): Replaced Sortie 2 Narrator storm ambush box with live black-dragon dive cutscene, added Longwing venom arcs, Virelai post-splice `virelai_eye_flare` highlight, flapping severed saddle strap particles, and Kestrel `sage_vapor` wisps (plus stripped `(Rumbles...)`, `(Shivers...)`, and `"*Chomp!*"` stage-direction strings).
- [x] **Harbor Approach Glide, Noticeboard Curl & Hearth Banner** (`scripts/regions/PortOfBrugesRegion.gd`, `PortOfBrugesDraw.gd`, `scripts/regions/WatchtowerHearthRegion.gd`, `scripts/GameUI.gd`): Added live *De Zwaan* harbor approach glide, physical curled Brabant corner slip on the Noticeboard, and compact non-blocking hearth ribbon keeping the sleeping black hatchling live onscreen.
- [x] **Silent Overhead Item/Map Holds & HUD Pulse (`Journal Note` Toast Swap)** (`scripts/GameUI.gd`, `scripts/regions/PortOfBrugesRegion.gd`, `scripts/regions/WillemHouseRegion.gd`, `scripts/regions/FrontierWildsRegion.gd`): Removed `Journal Note` popup dialogues for Louvain Beeswax & Thimble and Anna's Border Survey Map, replacing them with overhead item/scroll holds, chime SFX, and golden `pulse_hud_icon()` glow on the Bag/Map HUD buttons.
- [x] **Non-Sign World Label Batch-Strip & Diegetic Stall Signboards** (`scripts/regions/WillemHouseRegion.gd`, `scripts/regions/PortOfBrugesDraw.gd`, `scripts/regions/FrontierWildsDraw.gd`, `scripts/regions/SanctuaryVillageData.gd`, `scripts/regions/SanctuaryDraw.gd`): Stripped floating labels over beds, scenery, livestock pens, winches, prop buckets, and dragons; replaced them with drowsy pillow shimmer, concentric Cliff Spring water ripples & droplets, whipping loose halyard cord, silvery herring gleam, bobbing golden butcher-rack indicator, iron shackle spark on bound Kestrel, hover ring on winch posts, and painted wooden oak plaques strictly on actual stalls (`Rigging Stall`, `Victualler Stall`) and `Noticeboard`.
- [x] **Bruges Named Buildings & Landmarks — Diegetic Exterior Cues Instead of Name Cards** (`scripts/PixelAssets.gd`, `PortOfBrugesDraw.gd`, `PortOfBrugesRegion.gd`, `BrugesCityMapData.gd`, `BrugesCityDraw.gd`, `bruges_map_builder.html`, `kit_buildings.py`, `sprite_bruges_landmarks.py`): Removed all floating building, gate, and bastion name cards across Ch. 1 Port of Bruges and Ch. 4 Walled Bruges while preserving `Noticeboard`; made every civic and craft structure self-evident via exterior props and bespoke modular shopfronts—brick bread oven with rising hearth smoke and flour sacks beside bakeries (`PortOfBrugesDraw.gd`, Grote Markt Bakery), twin windlasses and rope coils at ropewalks, stacked oak crates/barrels beside warehouses and wharves, cloth-bolt stalls and bales outside Weavers Guild (`city_weavers_6b.png`) and Cloth Hall, crimson Church banners and halberd/shield racks outside the Keep & Garrison (`city_garrison_7c.png`), ale barrel racks outside taverns, and herb planters/drying racks in the Beguinage.
- [x] **Bruges Atmospheric Polish, Bell Waves, Fortifications & Canal Barge Hopping** (`scripts/PixelAssets.gd`, `PortOfBrugesDraw.gd`, `PortOfBrugesRegion.gd`, `BrugesCityBoats.gd`, `BrugesCityRegion.gd`, `BrugesCityDraw.gd`, `SoundManager.gd`, `sprite_bruges_forts_water.py`, `audio_synth.py`): Replaced remaining fortification, watergate, boat, and fountain vector shapes with pixel-art sprites; added shared warm bakery oven firelight, bread boules (`prop_bread_loaf.png`), embers, chimney smoke, and proximity `sfx_oven_crackle.wav`; added St. Donatian's 8 PM bronze `sfx_church_bell.wav` + expanding golden acoustic `bell_wave_rings`; added Garrison weapon-rack metallic glints; and enabled patrolling Reien canal barges with diegetic target ring reticle and `wood` deck footsteps so Bram can hop across rivers without explanatory text boxes.
