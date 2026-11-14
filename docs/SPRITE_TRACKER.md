# Sprite Asset Tracker (Placeholder -> Final Pixel Art)

> **Purpose:** Single source of truth tracking every visual sprite added since **Expanded Chapter 2 — Brotherhood Cliff Sanctuary** (plus any new visual feature additions going forward).
> **Placeholder System:** Until crossed off here (`- [x]`), every listed sprite is generated as a clean **simple-box placeholder** by `.agents/skills/pixel-art-generator/scripts/sprite_placeholders.py` (invoked by `generate_pixel_assets.py`).

---

## Workflow Rules for Agents

### 1. For Feature / Gameplay Agents (Adding New Visuals)
1. **Never bypass with hand-sculpted art inline** unless explicitly asked to finalize art.
2. Add the visual item's entry to the active queue below as `- [ ]` with **exact filename**, **dimensions (`WxH`)**, **Godot callers**, and **visual/palette brief**.
3. Register a matching simple-box placeholder in `.agents/skills/pixel-art-generator/scripts/sprite_placeholders.py`.
4. Run `python .agents/skills/pixel-art-generator/scripts/generate_pixel_assets.py` so Godot loads valid crisp `TEXTURE_FILTER_NEAREST` box PNGs immediately.

### 2. For the Sprite-Making Agent (Replacing Placeholders with Final Art)
1. Pick any unchecked `- [ ]` entry (or batch) from the queues below.
2. Inspect its dimensions (`WxH`), palette notes (`.agents/rules/pixel-art-and-visuals.md` 32-color palette), and Godot call sites.
3. Paint the finished crisp pixel-art `.png` into `assets/sprites/<filename>` — **or prefer modular composers first** (`kit_buildings.py` for houses/shops, `kit_npcs.py` for villagers/crew, `kit_boy_carry.py` `cloth_overrides` for shared carry postures + a single `prop_*.png`) rather than duplicating bespoke full sheets — then remove its placeholder key from `sprite_placeholders.py`.
4. Flip `- [ ]` to `- [x]` in this document. **Protection rule:** `sprite_placeholders.py` automatically skips any entry marked `- [x]` in this file so re-running `generate_pixel_assets.py` will never overwrite finished art.
5. After editing portraits/props/sprites, update `docs/ARCHITECTURE.md` if sprite counts change and run Godot headless verification.

---

## Queue 1 — Sanctuary Expansion Props, Chores & Icons (Ch. 2) — Completed

- [x] `prop_dragon_egg_held.png` (`16x16`) — Clean hand-held Obsidian Dragon Egg silhouette without earth/grass nest circle for cradle carry & pickup lift (`PlayerBoy.gd` & `FrontierWildsRegion.gd`). Generated via `sprite_props.py`.
- [x] `prop_leather_rack.png` (`28x24`) — Saddler Hendrick's outdoor oak leather-curing rack draped with cured wyrm-hide straps, emerald harness strips, and brass rings. Used in `scripts/regions/SanctuaryDraw.gd`. (`sprite_sanctuary.py`)
- [x] `prop_leather_bale.png` (`16x16`) — Strapped roll of salt-cured wyrm-hide leather carried by the player in Year 1 chore. Used in `SanctuaryDraw.gd` & `PlayerBoy.gd`. (`sprite_sanctuary.py`)
- [x] `prop_herb_cauldron.png` (`24x24`) — Sister Maren's dark iron apothecary cauldron over brass legs simmering green cliffsage poultice with faint herb steam. Used in `SanctuaryDraw.gd`. (`sprite_sanctuary.py`)
- [x] `prop_spring_well.png` (`28x24`) — Mossy stone cliff spring basin with cool blue mountain water trickle pouring into a clear pool. Used in `SanctuaryDraw.gd`. (`sprite_sanctuary.py`)
- [x] `prop_water_bucket.png` (`16x16`) — Iron-hooped oak water pail filled with bright cliff spring water carried to Maren's cauldron. Used in `PlayerBoy.gd`. (`sprite_sanctuary.py`)
- [x] `prop_drying_herbs.png` (`24x20`) — Wooden camp rack hung with tied bundles of drying sage and camomile (Year 3+ Sanctuary expansion). Used in `SanctuaryDraw.gd`. (`sprite_sanctuary.py`)
- [x] `prop_map_table.png` (`36x24`) — Timber Brotherhood chart & navigation table with unrolled coastal vellum maps, plotted flight track, crimson marker, and brass compass (Year 3+ / Matthijs Year 5 station). Used in `SanctuaryDraw.gd`. (`sprite_sanctuary.py`)
- [x] `icon_jerkin.png` (`16x16`) — Seasoned Brotherhood Flight-Jerkin bag icon: oiled dark-tan wyrm-hide coat with forest-emerald shoulder tabs and central brass carabiner D-ring. Used in `ItemCatalog.gd` & `CharacterInventoryPanel.gd`. (`sprite_sanctuary.py`)
- [x] `icon_poultice.png` (`16x16`) — Cliffsage Wing-Poultice jar bag icon: stoneware apothecary jar with cork stopper, pale linen neck tie, and glowing sage ointment label. Used in `ItemCatalog.gd` & `SanctuaryRegion.gd`. (`sprite_sanctuary.py`)
- [x] `prop_herring_bucket.png` (`22x20`) — Ice-packed oak camp bucket beside the hearth with silvery herring tails peeking over the rim (Year 3 Kestrel feeding quest). Used in `SanctuaryDraw.gd`. (`sprite_sanctuary.py`)
- [x] `prop_herring_fish.png` (`16x12`) — Fresh silver herring held in the boy's hands and arced skyward into Kestrel's jaws during the mid-air catch animation. Used in `SanctuaryDraw.gd` & `PlayerBoy.gd`. (`sprite_sanctuary.py`)
- [x] `prop_knot_drill_board.png` (`26x26`) — Timber post & practice knot board beside Hendrick's rack featuring brass belaying pegs, strung emerald cordage, and a hanging brass sand/stopwatch plumb. Used in `SanctuaryDraw.gd`. (`sprite_sanctuary.py`)

---

## Queue 2 — Sanctuary Crew NPCs & Dialogue Portraits (Ch. 2) — Completed

- [x] `npc_hendrick.png` (`24x28`) — Master Saddler Hendrick resting stance: broad-shouldered veteran craftsman with full grey beard, heavy brown-leather saddler apron over slate tunic, brass belt buckle. Built via modular composer `kit_npcs.py`.
- [x] `npc_hendrick_0.png` (`24x28`) — Saddler Hendrick idle breath/work frame 0 (`kit_npcs.py`).
- [x] `npc_hendrick_1.png` (`24x28`) — Saddler Hendrick idle/hammer shift frame 1 (`kit_npcs.py`).
- [x] `npc_maren.png` (`24x28`) — Chirurgeon Sister Maren resting stance: blonde braided hair, forest-emerald Brotherhood gown, pale linen apothecary apron. Built via modular composer `kit_npcs.py`.
- [x] `npc_maren_0.png` (`24x28`) — Sister Maren idle frame 0 (`kit_npcs.py`).
- [x] `npc_maren_1.png` (`24x28`) — Sister Maren idle/stir shift frame 1 (`kit_npcs.py`).
- [x] `npc_matthijs.png` (`24x28`) — Bellman Matthijs resting stance: energetic young sandy-haired runner in forest-green windbreaker tunic with brass bell/whistle clasp. Built via modular composer `kit_npcs.py`.
- [x] `npc_matthijs_0.png` (`24x28`) — Bellman Matthijs idle frame 0 (`kit_npcs.py`).
- [x] `npc_matthijs_1.png` (`24x28`) — Bellman Matthijs idle weight-shift frame 1 (`kit_npcs.py`).
- [x] `portrait_hendrick.png` (`48x48`) — Saddler Hendrick framed dialogue bust: stern kindly gaze, full grey beard, creased brow, heavy leather strap & scarf collar. Used in `SanctuaryNarrative.gd` & `SanctuaryRegion.gd`. (`sprite_portraits.py`)
- [x] `portrait_maren.png` (`48x48`) — Sister Maren framed dialogue bust: warm gentle smile, golden-blonde braid, emerald tunic & crisp linen collar scarf. Used in `SanctuaryNarrative.gd`. (`sprite_portraits.py`)
- [x] `portrait_matthijs.png` (`48x48`) — Bellman Matthijs framed dialogue bust: sandy tousled hair, sharp wry grin, rosy windswept cheeks, emerald jacket & brass clasp. Used in `SanctuaryNarrative.gd`. (`sprite_portraits.py`)
- [x] `portrait_virelai.png` (`48x48`) — Speaking dialogue portrait of Anna's green Brotherhood dragon *Virelai*: swept stone-grey horns, emerald scales, heavy leather neck-harness & brass buckle, keen amber eye. Used in `SanctuaryNarrative.gd` & `SanctuaryRegion.gd`. (`sprite_portraits.py`)
- [x] `portrait_greyling.png` (`48x48`) — Speaking dialogue portrait of cured Silver Greyling *Kestrel*: swept silver-slate crests, cool slate-grey muzzle, pale linen cliffsage bandage around shoulder/neck, shy golden eye. Used in `SanctuaryNarrative.gd`, `SanctuaryRegion.gd` & `Bestiary`. (`sprite_portraits.py`)

---

## Queue 3 — Protagonist Wardrobe Evolution (Age 14 Apprentice & Age 17 Senior) — Completed

Each protagonist tier spans **51 `24x28` sprites** (`18` walk/idle + `15` action/roll poses + `18` `kit_boy_carry.py` carry/cradle frames) using `PlayerBoy.gd`'s modular carry architecture (`CARRY_PROPS` + `carry_prop_sprite` overlay): `idle`, `walk1`, `walk2`, `down_0..2`, `up_0..2`, `side_0..2`, `diag_down_0..2`, `diag_up_0..2`, `carry_hands_down_0..2`, `carry_hands_up_0..2`, `carry_hands_side_0..2`, `cradle_hands_down_0..2`, `cradle_hands_up_0..2`, `cradle_hands_side_0..2`, `throw`, `knife_0..1`, `roll`, `roll_down_0..2`, `roll_up_0..2`, `roll_side_0..2`, `kneel`, `blindfold`. (`53` files per tier including 2 portraits; generated via `sprite_boy_tiers.py` + `kit_boy_carry.py`.)

- [x] `boy14_*.png` (51 sprites, `24x28`) — **Age 14 Rig-Apprentice Variant** (Year 3 Sanctuary & Sortie 1): slightly taller (+1px torso) silhouette wearing warm tan cured leather tunic (`T2`/`T3`), slate breeches (`S`), leather apprentice strap, and emerald Brotherhood neck scarf (`E1`/`E2`). Used automatically when `boy_age >= 14` in `PlayerBoy.gd` & `CharacterInventoryPanel.gd`. (`sprite_boy_tiers.py`)
- [x] `portrait_boy14_neutral.png` (`48x48`) — **Age 14 Neutral Portrait**: determined young teen expression, messy chestnut hair, tan apprentice leather jacket over emerald scarf collar. Used via `GameState.get_boy_portrait(false)`. (`sprite_portraits.py`)
- [x] `portrait_boy14_angry.png` (`48x48`) — **Age 14 Angry Portrait**: furrowed brow & set jaw in tan apprentice leather & emerald collar against ember background. Used via `GameState.get_boy_portrait(true)`. (`sprite_portraits.py`)
- [x] `boy17_*.png` (51 sprites, `24x28`) — **Age 17 Senior Flight-Jerkin Variant** (Year 5 Sanctuary, Sortie 2, Act 3 Wilds & Watchtower Hearth): mature taller build (+1px leg, +1px torso) in weathered forest-emerald (`E0`/`E1`/`E2`) & oiled dark wyrm-hide (`T0`/`T1`) Brotherhood Flight-Jerkin with diagonal harness strap and brass chest rings (`Y3`). Used automatically when `boy_age >= 17` or `sanctuary_jerkin_earned`. (`sprite_boy_tiers.py`)
- [x] `portrait_boy17_neutral.png` (`48x48`) — **Age 17 Neutral Portrait**: older hardened features, faint brow nick/scar, confident half-smirk, emerald Brotherhood flight collar & oiled dark leather. Used via `GameState.get_boy_portrait(false)`. (`sprite_portraits.py`)
- [x] `portrait_boy17_angry.png` (`48x48`) — **Age 17 Angry Portrait**: fierce intense scowl with brow furrow & scar in emerald Brotherhood Flight-Jerkin against crimson alert background. Used via `GameState.get_boy_portrait(true)`. (`sprite_portraits.py`)

---

### Queue 4 — Sanctuary Lived-In Outpost Village, Housing, Stalls & Dragon Livestock — Completed

#### Outpost Houses, Tents & Shelters
- [x] `bldg_covert_lodge.png` (`96x80`) — **Covert Crew Bunkhouse Lodge**: heavy timber-framed & whitewashed-plaster Flemish bunkhouse with moss-covered shingle roof, arched oak door, and warm lamp-lit dormer windows (`SanctuaryRegion` NW ridge). (`sprite_sanctuary.py`)
- [x] `bldg_covert_cottage.png` (`88x72`) — **Captain's & Navigator's Stone Cottage**: stone-walled fieldstone & terracotta-slate cottage with smoking fieldstone chimney and shuttered chart windows (`SanctuaryRegion` north terrace). (`sprite_sanctuary.py`)
- [x] `bldg_feed_barn.png` (`88x72`) — **Stockman's Feed & Ration Barn**: broad planked barn with slate roof, open hayloft dormer, and double carriage doors (`SanctuaryRegion` SE pasture ridge). (`sprite_sanctuary.py`)
- [x] `prop_tent_green.png` (`52x44`) — **Brotherhood Emerald Pavilion Tent**: pitched forest-emerald canvas sleeping tent with hemp guy-ropes, wooden ridge pole, and rolled entrance flap. (`sprite_sanctuary.py`)
- [x] `prop_tent_tan.png` (`48x40`) — **Scout Hemp Field Tent**: compact weathered linen/tan A-frame scout tent anchored with wooden stakes. (`sprite_sanctuary.py`)
- [x] `prop_dragon_pavilion.png` (`72x48`) — **Open Dragon Weather Pavilion**: heavy timber-post covert shelter roofed with moss slate and bedded with fresh golden straw for sheltered dragons (`Kestrel`'s east roost). (`sprite_sanctuary.py`)

#### Human Stalls, Mess Tables & Feeding Equipment
- [x] `prop_stall_food.png` (`48x36`) — **Victualler Food & Ale Stall**: red-and-cream striped market awning over oak plank counter stocked with yellow Flemish cheese wheels, loaves, and stoneware jugs. (`sprite_sanctuary.py`)
- [x] `prop_stall_gear.png` (`48x36`) — **Chandlery & Rigging Stall**: emerald-and-linen striped awning over supply counter with coiled rigging rope, brass storm lantern, and tallow buckets. (`sprite_sanctuary.py`)
- [x] `prop_mess_table.png` (`56x28`) — **Communal Crew Mess Table & Benches**: long oak trestle table flanked by timber benches, laid with wooden trenchers, bowls, and ale flagons. (`sprite_sanctuary.py`)
- [x] `prop_stew_pot.png` (`24x24`) — **Stewing Kettle & Iron Tripod**: blackened cast-iron stew pot bubbling over warm hearth embers with projecting wooden ladle. (`sprite_sanctuary.py`)
- [x] `prop_dragon_feed_rack.png` (`36x32`) — **Dragon Meat Butcher Rack**: sturdy oak A-frame timber beam with hanging cuts of mutton/beef and brine tub for dragon rations. (`sprite_sanctuary.py`)
- [x] `prop_water_trough.png` (`32x20`) — **Banded Timber Watering Trough**: iron-strapped oak plank trough brimming with fresh clear spring water for mounts and herd stock. (`sprite_sanctuary.py`)
- [x] `prop_hay_bale.png` (`24x20`) — **Bound Straw Hay Bale**: golden threshed straw bale cinched with twin hemp twine cords. (`sprite_sanctuary.py`)
- [x] `prop_fence_h.png` (`32x16`) — **Horizontal Split-Rail Pasture Fence**: mortised oak posts with two weathered horizontal rails (tileable). (`sprite_sanctuary.py`)
- [x] `prop_fence_v.png` (`12x32`) — **Vertical Split-Rail Pasture Fence**: vertical mortised oak pasture rail segment for north-south paddock borders. (`sprite_sanctuary.py`)

#### Covert Outpost Livestock (2-Frame Grazing Idle)
- [x] `animal_sheep_0.png` (`20x16`) — **Flemish Ewe/Ram (Standing)**: fluffy cream wool body, dark charcoal muzzle & floppy ears, four tiny hooves. (`sprite_sanctuary.py`)
- [x] `animal_sheep_1.png` (`20x16`) — **Flemish Ewe/Ram (Grazing)**: matching sheep sprite with head lowered nudging pasture grass and slight hoof step. (`sprite_sanctuary.py`)
- [x] `animal_cow_0.png` (`28x22`) — **Brabant Ox / Dairy Cow (Standing)**: stout chestnut-and-cream pied cattle silhouette with short pale horns. (`sprite_sanctuary.py`)
- [x] `animal_cow_1.png` (`28x22`) — **Brabant Ox / Dairy Cow (Grazing)**: matching cow sprite with head dipped to nibble hay/clover. (`sprite_sanctuary.py`)
- [x] `animal_pig_0.png` (`18x14`) — **Covert Paddock Hog (Standing)**: plump rosy-pink swine with upturned snout, perked ears, and dark trotters. (`sprite_sanctuary.py`)
- [x] `animal_pig_1.png` (`18x14`) — **Covert Paddock Hog (Rooting)**: matching pig sprite rooting down in dirt/mud with forward trotter shift. (`sprite_sanctuary.py`)

#### Village Caretaker NPCs & Portraits
- [x] `npc_villager_cook_0.png` (`24x28`) — **Camp Cook Mieke (Idle 0)**: stout camp cook in rose-madder kirtle, clean linen apron, chestnut coiled hair, and wooden soup ladle. (`kit_npcs.py`)
- [x] `npc_villager_cook_1.png` (`24x28`) — **Camp Cook Mieke (Idle 1)**: stirring animation frame of Camp Cook Mieke. (`kit_npcs.py`)
- [x] `portrait_cook.png` (`48x48`) — **Camp Cook Mieke Portrait**: warm smiling middle-aged Flemish cook wearing white linen cap/coif, rose bodice, and apron strap against hearth background. (`sprite_portraits.py`)
- [x] `npc_villager_herdsman_0.png` (`24x28`) — **Stockman Bram (Idle 0)**: weathered herdsman in oiled leather jerkin, emerald wool scarf, sandy-grizzled beard, and brass herd-bell. (`kit_npcs.py`)
- [x] `npc_villager_herdsman_1.png` (`24x28`) — **Stockman Bram (Idle 1)**: breathing/whistling animation frame of Stockman Bram. (`kit_npcs.py`)
- [x] `portrait_herdsman.png` (`48x48`) — **Stockman Bram Portrait**: wind-burned covert stockman with thick sandy-grey beard, wool scarf collar, and sturdy leather vest against pasture background. (`sprite_portraits.py`)

---

### Queue 5 — Virelai Feeding Reaction & Butcher Ration Choreography — Completed

- [x] `prop_mutton_joint.png` (`22x18`) — **Butchered Mutton Quarter (Carry Prop & Butcher Rack Hanging Cut)**: rich marbled crimson mutton haunch with off-white femur tip carried in cradle posture and hung beside Virelai's perch. (`sprite_sanctuary.py`)
- [x] `icon_mutton.png` (`16x16`) — **Trimmed Mutton Joint Icon**: compact parchment-friendly mutton haunch icon displayed above the boy's head after Stockman Bram's butcher chop minigame. (`sprite_sanctuary.py`)
- [x] `dragon_anna_eat_0.png` (`88x72`) — **Virelai Feeding Reaction (Frame 0 — Head Dip & Tail Sweep Left)**: alternate emerald mount animation (`176x144` world rect) leaning forward with parted jaws toward her butcher rack and tail curled left. (`sprite_dragons.py`)
- [x] `dragon_anna_eat_1.png` (`88x72`) — **Virelai Feeding Reaction (Frame 1 — Happy Chomp & Tail Wag Right)**: companion eating frame with jaws snapped shut over rations, lifted horns/eyebrows, warm amber cheek/gleam sparks, and tail swung briskly right. (`sprite_dragons.py`)

---

### Queue 6 — Rescued Silver Greyling Church Net & Wing-Shackles — Completed

- [x] `prop_hunter_shackles.png` (`56x46`) — **Church Capture Netting & Forged Wing-Shackles**: dry golden straw rescue bed (`H1`/`H2`) draped with heavy tarred hemp capture netting and bolted forged iron wing-cuffs + salt-rusted Church padlock over the rescued Greyling's wings (leaving his head exposed below/center). (`sprite_sanctuary.py`, `SanctuaryDraw.gd`)
- [x] `prop_shackles_broken.png` (`56x46`) — **Severed Capture Net & Snapped Wing-Shackles**: rumpled straw rescue bedding (`H1`/`H2`) with slack cut hemp net coils pushed aside and an opened/broken forged iron shackle clasp resting in the moss beneath Kestrel. (`sprite_sanctuary.py`, `SanctuaryDraw.gd`)

---

### Queue 7 — Sanctuary Signal Mast & Brotherhood Emblem Suite — Completed

- [x] `prop_signal_mast_loose.png` (`44x56`) — **Unstrung Gorge Signal Mast**: timber watch-mast anchored in a mossy stone cairn with iron collar bands, climbing pegs, crosstree yardarm pulley sheaves, miniature emerald Brotherhood crest plaque, plus slack coiled hemp halyard and bundled sailcloth before rigging. (`sprite_sanctuary.py`, `SanctuaryDraw.gd`)
- [x] `prop_signal_mast_0.png` / `prop_signal_mast_1.png` (`44x56`) — **Strung Gorge Signal Mast (2-Frame Wind Billow)**: matching mast rigged with a taut white Bowline halyard locked through a brass cleat carabiner and a fluttering Forest-Emerald & Brass-Gold swallowtail pennant bearing the spread-wing Brotherhood crest across 2 animated wind waves. (`sprite_sanctuary.py`, `SanctuaryDraw.gd`)
- [x] `ui_brotherhood_emblem.png` (`48x48`) — **Official Secret Brotherhood of Dragon Riders Medallion**: circular braided hemp-and-brass rope border with cardinal rivets encircling an emerald field, Twin Swept Burnished-Gold Dragon Wings, beveled Brass Harness Carabiner diamond with crimson gem core, and twin swallowtail scroll ribbons. Used on Title Prompt card, Book I Checkpoint overlay, and `[M]` Border Survey Map stamp. (`sprite_world.py`)
- [x] `icon_brotherhood_emblem.png` (`16x16`) — **Compact Brotherhood Crest Icon**: matching 16px medallion emblem displayed alongside the protagonist's Character Sheet header once sworn into the Sanctuary (`ACT2_SANCTUARY+`). (`sprite_world.py`, `CharacterInventoryPanel.gd`)
- [x] `ui_wax_seal.png` (`24x24`), `prop_brotherhood_banner.png` (`24x38`), `building_outpost.png` (`96x68` banner detail) — Unified existing crimson wax seal embossing, sanctuary timber cross-bar banners, and the Outpost Watchtower turret banner onto the canonical Twin Spread-Wing & Carabiner Diamond Brotherhood insignia. (`sprite_world.py`, `sprite_props.py`, `sprite_world_buildings.py`)

---

### Queue 8 — Kestrel (Silver Greyling) Multi-Year Growth Sprites & Portraits — Completed

- [x] `dragon_greyling_hurt.png` (`48x40`), `dragon_greyling_0.png` / `dragon_greyling_1.png` / `dragon_greyling.png` (`48x40`) — Sculpted Year 1 fledgling Silver Greyling (`_draw_swept_wing` anatomy, spade tail fluke, `dragon_greyling_hurt` crouching injured sprite inside Church shackles, and Maren's green cliffsage bandage wrap once healed). (`sprite_dragons.py`, `SanctuaryDraw.gd`)
- [x] `dragon_greyling_y3_0.png` / `dragon_greyling_y3_1.png` (`64x52`) — Year 3 (Age 14) adolescent courier Silver Greyling: broader swept silver-slate wing membranes, elongated crown plumes, faint healed shoulder scar, and apprentice leather chest strap + brass courier tag. (`sprite_dragons.py`, `SanctuaryDraw.gd`)
- [x] `dragon_greyling_y5_0.png` / `dragon_greyling_y5_1.png` (`76x62`) — Year 5 (Age 17) adult Silver Greyling courier: dappled slate-silver wingspan, twin crown crests, crossed leather courier harness with brass carabiner buckle, and twin hemp saddle dispatch pouches. (`sprite_dragons.py`, `SanctuaryDraw.gd`)
- [x] `portrait_greyling_y3.png` (`48x48`), `portrait_greyling_y5.png` (`48x48`) — Adolescent & adult `48x48` Kestrel portraits paired with Year 1 `portrait_greyling.png`, auto-resolved by `GameState.get_greyling_portrait()` and voiced with maturing chirp pitch across Years 1–5. (`sprite_portraits.py`, `GameState.gd`, `DialogueBox.gd`)

---

### Queue 9 — Walled City of Bruges Landmarks, Church Catchpoles & Night Heist Props (Ch. 4)

- [x] `bldg_bruges_belfry.png` (`96x128`) — **Belfry & Cloth Hall (*Lakenhalle*)**: towering medieval stone-and-brick Flemish belfry spire rising above an arched wool & cloth hall with draped guild banners overlooking the Grote Markt (`sprite_bruges_landmarks.py`, `BrugesCityDraw.gd`).
- [x] `bldg_bruges_cathedral.png` (`112x112`) — **St. Donatian's Church**: vaulted Gothic limestone nave, buttresses, glowing stained-glass rose window, tall slate cross-steeple, and arched portal (`sprite_bruges_landmarks.py`, `BrugesCityDraw.gd`).
- [x] `bldg_bruges_keep.png` (`120x104`) — **Main Keep & Guard Bastion (*Prinsenhof* Gatehouse)**: battlemented ashlar gatehouse with twin turret spires, raised iron portcullis archway, torch sconces, and scarlet-gold Church pennants (`sprite_bruges_landmarks.py`, `BrugesCityDraw.gd`).
- [x] `bldg_beguinage_court.png` (`88x76`) — **Beguinage Herb Court & Apothecary (*Begijnhof*)**: whitewashed chalk-lime cottage with terracotta roof, twin dormers, hanging herb bundles, ivy, and glowing apothecary bottles (`sprite_bruges_landmarks.py`, `BrugesCityDraw.gd`).
- [x] `prop_stone_bridge_h.png` (`64x44`) — **Arched Flemish Stone Canal Bridge (Horizontal)**: weathered dressed-stone footbridge with balustrades & iron bollards spanning east-west across the Reien canals (`sprite_bruges_landmarks.py`, `BrugesCityDraw.gd`).
- [x] `prop_stone_bridge_v.png` (`44x64`) — **Arched Flemish Stone Canal Bridge (Vertical)**: matching north-south stone canal bridge (`sprite_bruges_landmarks.py`, `BrugesCityDraw.gd`).
- [x] `prop_iron_chain_wagon.png` (`56x38`) — **Church Dragon-Chain Supply Wagon**: heavy iron-shod oak dray loaded with forged capture chains, padlocked chest, and Church insignia (`sprite_bruges_landmarks.py`, `BrugesCityDraw.gd`).
- [x] `prop_egg_cradle_pedestal.png` (`36x36`) — **Brotherhood Egg Brazier Pedestal**: forged wrought-iron tripod cradle holding glowing hearth embers beneath hammered brass dragon-egg nest (`sprite_sanctuary.py`, `SanctuaryAct4.gd`).
- [x] `npc_church_hunter.png` / `npc_church_hunter_0.png` / `npc_church_hunter_1.png` (`24x28`) — **Church Hunter-At-Arms / Catchpole**: modular iron kettle-helmeted Church enforcer wearing scarlet-trimmed steel brigandine tabard with kite buckler & arbalest crossbow (`kit_npcs.py`, `BrugesCityDraw.gd`).
- [x] `portrait_priest.png` (`48x48`) — **Father Anselm (Cathedral Priest) Portrait**: stern silver-tonsured Church cleric in obsidian cassock, Roman collar, and gilded crimson stole (`sprite_portraits.py`, `BrugesCityRegion.gd`).

### Queue 10 — Bruges Diegetic Shop Exteriors & Modular Guildhall Variants (Replacing Text Name Cards)

- [x] `city_weavers_6b.png` (`104x78`), `city_garrison_7c.png` (`120x78`) — Modular guildhall & garrison variants from `kit_buildings.py` visually distinguishing Bruges's Weavers Guild (dyed cloth stalls & guild sign) and Garrison Hall (ashlar facade, Church kite-shield banners & armor crest) without floating labels.
- [x] `prop_brick_bread_oven.png` (`44x36`), `prop_flour_sack_stack.png` (`28x24`) — Domed Flemish outdoor brick bread oven with glowing firebox, loaves on kneading shelf, baker's peel, and flour sacks outside Ch. 1 & Ch. 4 bakeries (`sprite_bruges_landmarks.py`).
- [x] `prop_ale_barrel_rack.png` (`36x28`), `prop_tavern_table.png` (`44x30`) — Tapped oak ale keg rack with brass spigots & candlelit trestle table topped with frothy tankards outside taverns/alehouses (`sprite_bruges_landmarks.py`).
- [x] `prop_cloth_bales.png` (`40x30`), `prop_herb_planter.png` (`44x30`), `prop_garrison_rack.png` (`40x32`), `prop_rope_windlass.png` (`38x30`) — Diegetic street props identifying Cloth Hall/Weavers Guild, Apothecary herb beds, Keep/Garrison weapon & shield racks, and Ropewalker capstan windlasses (`sprite_bruges_landmarks.py`).

### Queue 11 — Bruges Fortifications, Gatehouses, Watergates, Canal Barges, Fountain & Bakery Loaf

- [x] `prop_wall_h.png` (`32x36`), `prop_wall_v.png` (`36x32`), `prop_garden_wall_h.png` (`32x24`), `prop_garden_wall_v.png` (`24x32`) — Tileable dressed-ashlar curtain walls & red-brick Beguinage cloister walls with limestone coping (`sprite_bruges_forts_water.py`, `BrugesCityDraw.gd`).
- [x] `prop_bastion_round.png` (`64x64`), `prop_bastion_square.png` (`64x64`), `prop_wall_banner.png` (`16x28`), `prop_wall_brazier.png` (`18x22`) — Battered stone corner drum/square flanking bastions with slate roofs, swallowtail Bruges/Church wall standards, and wrought-iron parapet braziers (`sprite_bruges_forts_water.py`, `BrugesCityDraw.gd`).
- [x] `prop_gatehouse_pier_h.png` (`48x64`), `prop_gatehouse_arch_h.png` (`80x36`), `prop_gatehouse_pier_v.png` (`64x48`), `prop_gatehouse_arch_v.png` (`64x64`), `prop_watergate_arch_h.png` (`64x40`), `prop_watergate_arch_v.png` (`40x64`) — Barbican gatehouse piers, overhead portcullis arches (Y-sorted above player), and vaulted canal *Waterpoort* arches (`sprite_bruges_forts_water.py`, `BrugesCityDraw.gd`).
- [x] `prop_canal_barge_v.png`, `prop_canal_barge_v_cargo.png` (`48x96`), `prop_canal_barge_h.png`, `prop_canal_barge_h_cargo.png` (`96x48`) — Clinker-oak Flemish *Praam* river barges (bare deck & loaded wool/cloth/cask variants) actively patrolling Bruges canals for river-hopping (`sprite_bruges_forts_water.py`, `BrugesCityBoats.gd`).
- [x] `prop_stone_fountain.png` (`72x72`), `prop_bread_loaf.png` (`16x16`) — Grote Markt octagonal limestone fountain with carved gothic rims & brass spouts + scored rye/wheat bread boules by warm bakery ovens (`sprite_bruges_forts_water.py`, `BrugesCityDraw.gd`, `PortOfBrugesDraw.gd`).

### Queue 12 — Modular Interior Furniture & Tapestry Shopkit (`kit_interiors.py`)

- [x] `furn_pew_oak_2b.png` (`36x24`), `furn_pew_oak_3b.png` (`52x24`), `furn_altar_cloth_3b.png` (`52x32`), `furn_shelf_apothecary_2b.png` (`36x34`), `furn_shelf_apothecary_3b.png` (`52x34`) — Reusable 16px-bay church pews, draped liturgical altar, and stocked apothecary herb/phial shelves (`kit_interiors.py`).
- [x] `furn_counter_bakery_3b.png` (`52x28`), `furn_counter_tavern_3b.png` (`52x28`), `furn_keg_rack_oak_2b.png` (`36x32`), `furn_weaver_loom_3b.png` (`52x34`), `furn_desk_merchant_2b.png` (`36x28`), `furn_rug_crimson_3b.png`, `furn_rug_emerald_3b.png` (`48x32`) — Composable bakery/tavern shop counters, keg rack, weaver broadloom, merchant ledger desk, and fringed tapestry rugs (`kit_interiors.py`).

---

## Completed Archive (`[x]`)

*(Crossed-off items move or flip `- [x]` here cleanly once polished pixel art is committed into `assets/sprites/`.)*
