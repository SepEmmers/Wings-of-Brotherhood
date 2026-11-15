class_name PlaytestPresets
extends RefCounted

## Single source of truth for the [F1] Playtest Chapter/Cutscene Jump Menu
## chapter grouping, UI metadata, and state presets.

const Book2PresetsScript := preload("res://scripts/data/PlaytestPresetsBook2.gd")

const CHAPTERS: Array = [
	{
		"id": "ch1",
		"tab_label": "I: Bruges",
		"title": "Book I Ch. 1 — Port of Bruges & The Missing Night",
		"subtitle": "Arrival aboard 'De Zwaan', harbor errands, Willem's cottage, and dawn stealth.",
	},
	{
		"id": "ch2",
		"tab_label": "I: Sanctuary",
		"title": "Book I Ch. 2 — Brotherhood Sanctuary & Skies",
		"subtitle": "Cliffside sanctuary, Virelai's harness splice, Kestrel rescue, and dragonback sorties.",
	},
	{
		"id": "ch3",
		"tab_label": "I: Wilds",
		"title": "Book I Ch. 3 — Frontier Wilds & Watchtower Hearth",
		"subtitle": "Whispering Pines tracking, Obsidian Hollow, living egg trek, and hearth warming.",
	},
	{
		"id": "ch4",
		"tab_label": "I: Bruges City",
		"title": "Book I Ch. 4 — Walled Bruges, Priest Tailing & Midnight Heist",
		"subtitle": "Council egg debate, 7-district Bruges recon, Catchpole shield combat, Anselm stealth tail & Kestrel escape.",
	},
	{
		"id": "book2",
		"tab_label": "II: Golden Heir",
		"title": "Book II — The Golden Heir (Brabant, Louvain & Meuse)",
		"subtitle": "Eastward escape atop Kestrel, Golden Hatchling bonding, stealth heat & dual-perspective campaigns.",
	},
	{
		"id": "cutscenes",
		"tab_label": "Cutscenes",
		"title": "All Story Cutscenes — Campaign Cinematics",
		"subtitle": "Jump directly to any scripted story cutscene across the campaign.",
	},
]

const PRESETS: Array = [
	{
		"id": "boat_sailing",
		"chapter": "ch1",
		"kind": "scene",
		"tag": "1.1",
		"title": "Sailing In 'De Zwaan'",
		"label": "Ch 1.1: Sailing In 'De Zwaan'",
		"region": "bruges",
		"location": "Zwin Canal (Aboard 'De Zwaan')",
		"summary": "Opens on deck as Shipmaster Hendrik steers into port. Moor the bow line and haul the last herring crate ashore.",
		"kit": "Clove Hitch • Dock Knife",
	},
	{
		"id": "ship_docked",
		"chapter": "ch1",
		"kind": "scene",
		"tag": "1.2",
		"title": "Docked Ship & Mooring",
		"label": "Ch 1.2: Docked Ship & Mooring",
		"region": "bruges",
		"location": "Bruges Wharf ('De Zwaan' Dockside)",
		"summary": "Ship alongside the timber quay before mooring. Cast a Clove Hitch onto the bollard to lower the gangplank.",
		"kit": "Clove Hitch • Dock Knife",
	},
	{
		"id": "bruges_free",
		"chapter": "ch1",
		"kind": "scene",
		"tag": "1.3",
		"title": "Port of Bruges — Quay & Caches",
		"label": "Ch 1.3: Port of Bruges (Quay & Caches)",
		"region": "bruges",
		"location": "Port of Bruges (Harbor Quay)",
		"summary": "Free-roam harbor errands: deliver Vos's crate, buy Pieter's rye loaf, cut twine caches, and read the noticeboard.",
		"kit": "Clove Hitch • Dock Knife",
	},
	{
		"id": "ropewalk",
		"chapter": "ch1",
		"kind": "scene",
		"tag": "1.4",
		"title": "Ropewalk — Clara & Knots",
		"label": "Ch 1.4: Ropewalk (Clara & Knots)",
		"region": "bruges",
		"location": "Bruges Ropewalk",
		"summary": "Spawns outside the Ropewalk carrying Clara's recovered Shuttle Pouch to test returning it and unlocking knots.",
		"kit": "Clove Hitch • Clara's Shuttle Pouch",
	},
	{
		"id": "house_evening",
		"chapter": "ch1",
		"kind": "scene",
		"tag": "1.5",
		"title": "Uncle Willem's Cottage & Bed",
		"label": "Ch 1.5: Uncle Willem's Cottage & Bed",
		"region": "house",
		"location": "Uncle Willem's Cottage (Evening)",
		"summary": "Evening arrival home with supper bread. Speak with Uncle Willem and Clara before resting for the night.",
		"kit": "Whipping Knot • Evening Errands Done",
	},
	{
		"id": "cutscene_sleep",
		"chapter": "ch1",
		"kind": "cutscene",
		"tag": "CS 1",
		"title": "Sleep & Midnight Door",
		"label": "Cutscene 1: Sleep & Midnight Door",
		"region": "house",
		"location": "Uncle Willem's Cottage (Midnight)",
		"summary": "Plays the midnight bedside cutscene—a stir outside the door and Clara's disappearance before dawn.",
		"kit": "Whipping Knot • Cutscene Start",
	},
	{
		"id": "dawn_clue",
		"chapter": "ch1",
		"kind": "scene",
		"tag": "1.6",
		"title": "Dawn Missing Clara Clue",
		"label": "Ch 1.6: Dawn Missing Clara Clue",
		"region": "house",
		"location": "Uncle Willem's Cottage (Dawn)",
		"summary": "Morning after Clara vanishes. Inspect the threshold for the torn wyrm-hide strap tied with her whipping-knot.",
		"kit": "Whipping Knot • Dawn Investigation",
	},
	{
		"id": "ambush",
		"chapter": "ch1",
		"kind": "scene",
		"tag": "1.7",
		"title": "Dawn Stealth & Watchman Patrols",
		"label": "Ch 1.7: Dawn Stealth & Watchman Patrols",
		"region": "bruges",
		"location": "Port of Bruges (Misty Dawn)",
		"summary": "Sneak past Church Watchman lantern cones across dawn Bruges toward Market Square to report the Brotherhood.",
		"kit": "Whipping Knot • Torn Dragon-Leather Strap",
	},
	{
		"id": "cutscene_abduction",
		"chapter": "ch1",
		"kind": "cutscene",
		"tag": "CS 2",
		"title": "Alley Abduction of the Boy",
		"label": "Cutscene 2: Alley Abduction of the Boy",
		"region": "bruges",
		"location": "Bruges Market Alley",
		"summary": "Plays the Brotherhood ambush sequence as riders intercept the boy and fly him toward the cliffside sanctuary.",
		"kit": "Whipping Knot • Torn Strap • Cutscene Start",
	},
	{
		"id": "cutscene_arrival",
		"chapter": "ch2",
		"kind": "cutscene",
		"tag": "CS 2b",
		"title": "Sanctuary Landing & Blindfold Drop",
		"label": "Cutscene 2b: Sanctuary Arrival Landing",
		"region": "sanctuary",
		"location": "Brotherhood Cliff Perch",
		"summary": "Virelai glides out of the western fog, dips her shoulder so the blindfolded boy dismounts, and Anna removes the cloth.",
		"kit": "Cutscene Start • Sanctuary Arrival",
	},
	{
		"id": "act2_sanctuary",
		"chapter": "ch2",
		"kind": "scene",
		"tag": "2.1",
		"title": "Sanctuary Year 1 (Age 12 Chores)",
		"label": "Ch 2.1: Sanctuary Year 1 (Age 12 Chores)",
		"region": "sanctuary",
		"location": "Brotherhood Cliff Sanctuary",
		"summary": "First days above the clouds (Age 12). Haul wyrm-hide leather for Saddler Hendrick and splice Virelai's shoulder-ring.",
		"kit": "3 Knots (up to Dragon Splice)",
	},
	{
		"id": "act2_greyling",
		"chapter": "ch2",
		"kind": "scene",
		"tag": "2.2",
		"title": "Sanctuary Gorge & Kestrel (Age 12)",
		"label": "Ch 2.2: Sanctuary Gorge & Kestrel (Age 12)",
		"region": "sanctuary",
		"location": "Sanctuary Gorge Crossing",
		"summary": "Brew Sister Maren's cliffsage poultice, cross the gorge winch, cut Kestrel free, and tend the Silver-Slate courier's wings.",
		"kit": "All 4 Knots • Harness Carabiner",
	},
	{
		"id": "cutscene_year3_montage",
		"chapter": "ch2",
		"kind": "cutscene",
		"tag": "CS 3",
		"title": "Two Winters Montage (Age 12 -> 14)",
		"label": "Cutscene 3: Two Winters Montage (Age 12 -> 14)",
		"region": "sanctuary",
		"location": "Sanctuary Gorge Cliffs",
		"summary": "Multi-shot winter-to-spring montage: rigging practice in snow, Kestrel healing uncaged, and Age 14 drill leap.",
		"kit": "All 4 Knots • Seasonal Montage",
	},
	{
		"id": "act2_year3",
		"chapter": "ch2",
		"kind": "scene",
		"tag": "2.3",
		"title": "Two Winters Later — Year 3 (Age 14)",
		"label": "Ch 2.3: Two Winters Later — Year 3 (Age 14)",
		"region": "sanctuary",
		"location": "Expanded Gorge Outpost",
		"summary": "Age 14 crew life: string gorge signal pennants with Matthijs and wash/oil Virelai's wing-hinge before first patrol.",
		"kit": "All 4 Knots • Cliffsage Salve",
	},
	{
		"id": "virelai_sortie1",
		"chapter": "ch2",
		"kind": "scene",
		"tag": "2.4",
		"title": "Virelai Sortie 1 — Coast Patrol (Age 14)",
		"label": "Ch 2.4: Virelai Sortie 1 — Coast Patrol (Age 14)",
		"region": "flight",
		"location": "Flemish Coast Skies",
		"summary": "First live flight crew sortie (Age 14): ride updrafts, barrel-roll ballista locks, free & sketch the Ochre Gale-Wing.",
		"kit": "All 4 Knots • Kestrel Sketched",
	},
	{
		"id": "cutscene_year5_montage",
		"chapter": "ch2",
		"kind": "cutscene",
		"tag": "CS 4",
		"title": "Cliff Watch Montage (Age 14 -> 17)",
		"label": "Cutscene 4: Cliff Watch Montage (Age 14 -> 17)",
		"region": "sanctuary",
		"location": "Sanctuary & Eastern Cliffs",
		"summary": "Multi-shot montage: coastal flybys, midnight vigil holding Clara's torn strap, Age 17 senior rigging, storm lightning.",
		"kit": "All 4 Knots • Seasonal Montage",
	},
	{
		"id": "act2_year5",
		"chapter": "ch2",
		"kind": "scene",
		"tag": "2.5",
		"title": "Five Winters — Senior Crew (Age 17)",
		"label": "Ch 2.5: Five Winters — Senior Crew (Age 17)",
		"region": "sanctuary",
		"location": "Brotherhood Cliff Watch (Year 5)",
		"summary": "Age 17 senior forward rigman. Claim your fitted Brotherhood Flight-Jerkin and prepare to launch Storm Recon.",
		"kit": "Brotherhood Flight-Jerkin • All 4 Knots",
	},
	{
		"id": "virelai_sortie2",
		"chapter": "ch2",
		"kind": "scene",
		"tag": "2.6",
		"title": "Virelai Sortie 2 — Storm Recon (Age 17)",
		"label": "Ch 2.6: Virelai Sortie 2 — Storm Recon (Age 17)",
		"region": "flight",
		"location": "Eastern Ridge Thunderheads",
		"summary": "Senior storm sortie (Age 17): hide in clouds to break ballista aim, splice sheared rigging, and free the Crimson Acid-Spitter.",
		"kit": "Flight-Jerkin • Ochre Gale-Wing Sketched",
	},
	{
		"id": "cutscene_sky_attack",
		"chapter": "ch2",
		"kind": "cutscene",
		"tag": "CS 5",
		"title": "Black Dragon Storm Ambush",
		"label": "Cutscene 5: Black Dragon Storm Ambush",
		"region": "flight",
		"location": "Eastern Ridge Stormfront",
		"summary": "Plays the storm ambush as an unrecorded black-scaled dragon strikes Virelai and throws the boy into the wilds.",
		"kit": "All 4 Knots • Sortie 2 Cutscene",
	},
	{
		"id": "act3_wilds",
		"chapter": "ch3",
		"kind": "scene",
		"tag": "3.1",
		"title": "Wilds & Black Dragon Hollow",
		"label": "Ch 3.1: Wilds & Black Dragon Hollow",
		"region": "wilds",
		"location": "Whispering Pines (Crash Ravine)",
		"summary": "Alone in the border woods. Recover Anna's Border Survey Map and follow ash tracks north to Obsidian Hollow.",
		"kit": "All 4 Knots • 3 Breeds Sketched",
	},
	{
		"id": "cutscene_dragon_reveal",
		"chapter": "ch3",
		"kind": "cutscene",
		"tag": "CS 6",
		"title": "Dying Dragon Wing-Lift",
		"label": "Cutscene 6: Dying Dragon Wing-Lift",
		"region": "wilds",
		"location": "Obsidian Hollow",
		"summary": "Plays the encounter with the mortally wounded Black-Scaled Dragon lifting her wing to reveal her warm egg.",
		"kit": "All 4 Knots • Survey Map • Hollow Cutscene",
	},
	{
		"id": "act3_outpost_trek",
		"chapter": "ch3",
		"kind": "scene",
		"tag": "3.2",
		"title": "Carrying Egg -> Watchtower",
		"label": "Ch 3.2: Carrying Egg -> Watchtower",
		"region": "wilds",
		"location": "Whispering Pines (Hollow Exit)",
		"summary": "Survival trek carrying the egg (92% warmth). Warm by campfires, cut briars, cross the winch, and evade patrols.",
		"kit": "Egg (92%) • Border Map • Brass Compass",
	},
	{
		"id": "cutscene_hatching",
		"chapter": "ch3",
		"kind": "cutscene",
		"tag": "CS 7",
		"title": "Forest Watchtower — Warm Egg & Anna Rescue",
		"label": "Cutscene 7: Forest Outpost & Return Flight",
		"region": "hearth",
		"location": "Frontier Watchtower Hearth",
		"summary": "Warms the intact black-and-gold egg by the outpost stove before Anna & Virelai take you back to the Bruges Sanctuary.",
		"kit": "All 4 Knots • Intact Obsidian Egg",
	},
	{
		"id": "act4_egg_debate",
		"chapter": "ch4",
		"kind": "scene",
		"tag": "4.1",
		"title": "Bruges Outpost — Egg Argument & Church News",
		"label": "Ch 4.1: Return to Bruges Outpost — Egg Argument & Church News",
		"region": "sanctuary",
		"location": "Brotherhood Sanctuary (Phase 4)",
		"summary": "Virelai lands back at Bruges Sanctuary. Crew tries to take the egg; scout brings urgent news of a Church action in Bruges.",
		"kit": "All 4 Knots • Intact Obsidian Egg",
	},
	{
		"id": "act4_outskirts",
		"chapter": "ch4",
		"kind": "scene",
		"tag": "4.1b",
		"title": "Bruges Coastal Outskirts — Connected Road",
		"label": "Ch 4.1b: Bruges Coastal Outskirts (Connected Road)",
		"region": "outskirts",
		"location": "Zwin Causeway & Tollhouse (Between Sanctuary & Bruges)",
		"summary": "Walk seamlessly between Sanctuary West Trail, Port of Bruges North Gate, and Walled Bruges East Gate while evading Church Road-Wardens.",
		"kit": "World Map [M] • Walk-In Gates • Raycast Stealth",
	},
	{
		"id": "act4_bruges_city",
		"chapter": "ch4",
		"kind": "scene",
		"tag": "4.2",
		"title": "Walled Bruges — 7 Districts & Ambush",
		"label": "Ch 4.2: Walled City of Bruges",
		"region": "bruges_city",
		"location": "Bruges (South Port Gate)",
		"summary": "Explore Grote Markt, Beguinage, Canals, Guildhall, Keep & Cathedral. Fight Shield-Catchpoles & Crossbow Arbalesters.",
		"kit": "Rope Snare [F] • Dodge Roll [C] • Knife [V]",
	},
	{
		"id": "act4_priest_tail",
		"chapter": "ch4",
		"kind": "scene",
		"tag": "4.3",
		"title": "St. Donatian's — Tail Father Anselm",
		"label": "Ch 4.3: Tail Father Anselm to Keep",
		"region": "bruges_city",
		"location": "St. Donatian's Church Forecourt",
		"summary": "Shadow Father Anselm across Bruges's bridges into the Keep, ducking into stealth cover during backward glances.",
		"kit": "Stealth Cover Zones • Requisition Writ",
	},
	{
		"id": "act4_night_heist",
		"chapter": "ch4",
		"kind": "scene",
		"tag": "4.4",
		"title": "Sanctuary — Midnight Egg Heist",
		"label": "Ch 4.4: Midnight Sanctuary Egg Heist",
		"region": "sanctuary",
		"location": "Bruges Sanctuary (Midnight)",
		"summary": "Cut brass alarm wires [V], rope-snare Night-Watch guards [F], steal back the egg, and flee to Kestrel.",
		"kit": "Tripwire Knife • Rope Snare",
	},
	{
		"id": "cutscene_kestrel_escape",
		"chapter": "ch4",
		"kind": "cutscene",
		"tag": "CS 8",
		"title": "Midnight Escape Atop Kestrel",
		"label": "Cutscene 8: Kestrel Midnight Escape",
		"region": "sanctuary",
		"location": "Sanctuary East Ridge",
		"summary": "Mount Kestrel with the glowing black-and-gold egg and lift into the night mist before first bell.",
		"kit": "Silver-Slate Courier • Obsidian Egg",
	},
]


static func get_all_presets() -> Array:
	var all_presets: Array = PRESETS.duplicate()
	all_presets.append_array(Book2PresetsScript.PRESETS)
	return all_presets


static func get_chapter_info(tab_id: String) -> Dictionary:
	for ch in CHAPTERS:
		if ch["id"] == tab_id:
			return ch
	return CHAPTERS[0]


static func get_presets_for_tab(tab_id: String) -> Array:
	var out: Array = []
	for preset in get_all_presets():
		if tab_id == "cutscenes":
			if preset.get("kind", "scene") == "cutscene":
				out.append(preset)
		elif preset.get("chapter", "ch1") == tab_id:
			out.append(preset)
	return out


static func get_preset_by_id(scene_id: String) -> Dictionary:
	for preset in get_all_presets():
		if preset["id"] == scene_id:
			return preset
	return PRESETS[0] if not PRESETS.is_empty() else {}


static func get_active_chapter_id() -> String:
	var step := GameState.current_step
	if step <= GameState.QuestStep.BROTHERHOOD_AMBUSH:
		return "ch1"
	if step <= GameState.QuestStep.ACT2_VIRELAI_SORTIE_2:
		return "ch2"
	if step <= GameState.QuestStep.BOOK1_WATCHTOWER_HEARTH:
		return "ch3"
	if step <= GameState.QuestStep.ACT4_NIGHT_HEIST:
		return "ch4"
	return "book2"


static func get_active_preset_id() -> String:
	match GameState.current_step:
		GameState.QuestStep.ON_THE_SHIP:
			return "ship_docked" if GameState.ship_docked else "boat_sailing"
		GameState.QuestStep.EXPLORE_BRUGES:
			return "ropewalk" if GameState.shuttle_pouch_recovered else "bruges_free"
		GameState.QuestStep.EVENING_HOME:
			return "house_evening"
		GameState.QuestStep.DAWN_MISSING_CLARA:
			return "dawn_clue"
		GameState.QuestStep.SNITCH_TO_CHURCH:
			return "ambush"
		GameState.QuestStep.BROTHERHOOD_AMBUSH:
			return "cutscene_abduction"
		GameState.QuestStep.ACT2_SANCTUARY:
			if GameState.sanctuary_phase >= 3:
				return "act2_year5"
			if GameState.sanctuary_phase == 2:
				return "act2_year3"
			return "act2_greyling" if GameState.virelai_harness_spliced else "act2_sanctuary"
		GameState.QuestStep.ACT2_VIRELAI_SORTIE_1:
			return "virelai_sortie1"
		GameState.QuestStep.ACT2_VIRELAI_SORTIE_2:
			return "virelai_sortie2"
		GameState.QuestStep.ACT3_WILDS_TRACKING:
			return "cutscene_dragon_reveal" if GameState.has_forest_map else "act3_wilds"
		GameState.QuestStep.ACT3_EGG_TREK:
			return "act3_outpost_trek"
		GameState.QuestStep.BOOK1_WATCHTOWER_HEARTH:
			return "cutscene_hatching"
		GameState.QuestStep.ACT4_SANCTUARY_DEBATE:
			return "act4_egg_debate"
		GameState.QuestStep.ACT4_BRUGES_CITY:
			return "act4_priest_tail" if GameState.all_city_clues_found() else "act4_bruges_city"
		GameState.QuestStep.ACT4_NIGHT_HEIST:
			return "act4_night_heist"
	var book2_id := Book2PresetsScript.get_active_preset_id()
	return book2_id if not book2_id.is_empty() else "boat_sailing"


static func _unlock_post_sanctuary(include_reaper: bool, include_longwing: bool) -> void:
	GameState.unlock_all_knots()
	GameState.sanctuary_leather_chore_done = true
	GameState.sanctuary_water_drawn = true
	GameState.sanctuary_poultice_brewed = true
	GameState.sanctuary_greyling_treated = true
	GameState.virelai_harness_spliced = true
	GameState.greyling_cage_broken = true
	GameState.greyling_documented = true
	GameState.sanctuary_pennants_strung = true
	GameState.sanctuary_virelai_oiled = true
	GameState.sanctuary_virelai_talk_done = true
	GameState.sanctuary_virelai_fed = true
	GameState.boy_age = 14
	GameState.sanctuary_phase = 2
	GameState.dragon_trust = 55
	GameState.record_flight_breed("Silver-Slate Courier")
	if include_reaper:
		GameState.record_flight_breed("Ochre Gale-Wing")
		GameState.flight_sortie1_done = true
		GameState.boy_age = 17
		GameState.sanctuary_phase = 3
		GameState.sanctuary_kestrel_fed = true
		GameState.sanctuary_drill_mastered = true
		GameState.add_item("Brotherhood Topman's Timing Ring")
		GameState.sanctuary_hendrick_y3_done = true
		GameState.sanctuary_jerkin_earned = true
		GameState.sanctuary_final_brief_done = true
		GameState.dragon_trust = 85
		GameState.add_item("Brotherhood Flight-Jerkin")
	if include_longwing:
		GameState.record_flight_breed("Crimson Acid-Spitter")
		GameState.flight_sortie2_done = true
		GameState.dragon_trust = 95


static func apply_preset(scene_id: String) -> Dictionary:
	match scene_id:
		"boat_sailing":
			return {"region": "bruges", "params": {"mode": "sailing"}}
		"ship_docked":
			return {"region": "bruges", "params": {"mode": "docked"}}
		"bruges_free":
			GameState.current_step = GameState.QuestStep.EXPLORE_BRUGES
			return {"region": "bruges", "params": {"mode": "free", "spawn": Vector2(315, 480)}}
		"ropewalk":
			GameState.current_step = GameState.QuestStep.EXPLORE_BRUGES
			GameState.cargo_delivered = true
			GameState.shuttle_pouch_recovered = true
			GameState.add_item("Clara's Shuttle Pouch")
			return {"region": "bruges", "params": {"mode": "free", "spawn": Vector2(1185, 295), "facing": Vector2.UP}}
		"house_evening":
			GameState.current_step = GameState.QuestStep.EVENING_HOME
			GameState.cargo_delivered = true
			GameState.visited_clara = true
			GameState.bought_bread = true
			GameState.unlock_knot("bruges_whipping")
			return {"region": "house", "params": {"step": GameState.QuestStep.EVENING_HOME, "spawn": Vector2(640, 455), "first_entry": true}}
		"cutscene_sleep":
			GameState.current_step = GameState.QuestStep.EVENING_HOME
			GameState.cargo_delivered = true
			GameState.visited_clara = true
			GameState.bought_bread = true
			GameState.unlock_knot("bruges_whipping")
			return {"region": "house", "params": {"step": GameState.QuestStep.EVENING_HOME, "spawn": Vector2(732, 315), "cutscene_sleep": true}}
		"dawn_clue":
			GameState.current_step = GameState.QuestStep.DAWN_MISSING_CLARA
			GameState.cargo_delivered = true
			GameState.visited_clara = true
			GameState.bought_bread = true
			GameState.unlock_knot("bruges_whipping")
			return {"region": "house", "params": {"step": GameState.QuestStep.DAWN_MISSING_CLARA, "spawn": Vector2(640, 410), "facing": Vector2.DOWN}}
		"ambush":
			GameState.current_step = GameState.QuestStep.SNITCH_TO_CHURCH
			GameState.cargo_delivered = true
			GameState.visited_clara = true
			GameState.bought_bread = true
			GameState.inspected_knot_clue = true
			GameState.unlock_knot("bruges_whipping")
			GameState.add_item("Torn Dragon-Leather Strap")
			return {"region": "bruges", "params": {"mode": "free", "spawn": Vector2(1310, 885), "facing": Vector2.UP}}
		"cutscene_abduction":
			GameState.current_step = GameState.QuestStep.SNITCH_TO_CHURCH
			GameState.cargo_delivered = true
			GameState.visited_clara = true
			GameState.bought_bread = true
			GameState.inspected_knot_clue = true
			GameState.unlock_knot("bruges_whipping")
			GameState.add_item("Torn Dragon-Leather Strap")
			return {"region": "bruges", "params": {"mode": "free", "spawn": Vector2(960, 520), "facing": Vector2.UP, "cutscene_abduction": true}}
		"cutscene_arrival":
			GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
			GameState.boy_age = 12
			GameState.sanctuary_phase = 1
			GameState.dragon_trust = 0
			GameState.cargo_delivered = true
			GameState.visited_clara = true
			GameState.bought_bread = true
			GameState.inspected_knot_clue = true
			GameState.unlock_knot("bruges_whipping")
			GameState.add_item("Torn Dragon-Leather Strap")
			return {"region": "sanctuary", "params": {"skip_intro": false, "arrival_cutscene": true}}
		"act2_sanctuary":
			GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
			GameState.boy_age = 12
			GameState.sanctuary_phase = 1
			GameState.dragon_trust = 5
			GameState.unlock_knot("bruges_whipping")
			GameState.unlock_knot("bowline")
			GameState.unlock_knot("dragon_splice")
			return {"region": "sanctuary", "params": {"skip_intro": true, "spawn": Vector2(235, 515)}}
		"act2_greyling":
			GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
			GameState.boy_age = 12
			GameState.sanctuary_phase = 1
			GameState.dragon_trust = 20
			GameState.sanctuary_leather_chore_done = true
			GameState.unlock_all_knots()
			GameState.virelai_harness_spliced = true
			GameState.add_item("Brotherhood Harness Carabiner")
			return {"region": "sanctuary", "params": {"skip_intro": true, "spawn": Vector2(655, 735)}}
		"cutscene_year3_montage":
			GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
			GameState.boy_age = 12
			GameState.sanctuary_phase = 1
			GameState.dragon_trust = 25
			GameState.sanctuary_leather_chore_done = true
			GameState.sanctuary_water_drawn = true
			GameState.sanctuary_poultice_brewed = true
			GameState.sanctuary_greyling_treated = true
			GameState.virelai_harness_spliced = true
			GameState.greyling_cage_broken = true
			GameState.greyling_documented = true
			GameState.record_flight_breed("Silver-Slate Courier")
			GameState.unlock_all_knots()
			GameState.add_item("Brotherhood Harness Carabiner")
			return {"region": "sanctuary", "params": {"skip_intro": true, "cutscene_year3": true, "spawn": Vector2(215, 650)}}
		"act2_year3":
			GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
			GameState.boy_age = 14
			GameState.sanctuary_phase = 2
			GameState.dragon_trust = 40
			GameState.sanctuary_leather_chore_done = true
			GameState.sanctuary_water_drawn = true
			GameState.sanctuary_poultice_brewed = true
			GameState.sanctuary_greyling_treated = true
			GameState.virelai_harness_spliced = true
			GameState.greyling_cage_broken = true
			GameState.greyling_documented = true
			GameState.record_flight_breed("Silver-Slate Courier")
			GameState.unlock_all_knots()
			GameState.add_item("Brotherhood Harness Carabiner")
			return {"region": "sanctuary", "params": {"skip_intro": true, "spawn": Vector2(360, 505)}}
		"cutscene_year5_montage":
			GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
			GameState.boy_age = 14
			GameState.sanctuary_phase = 2
			GameState.dragon_trust = 60
			GameState.sanctuary_leather_chore_done = true
			GameState.sanctuary_water_drawn = true
			GameState.sanctuary_poultice_brewed = true
			GameState.sanctuary_greyling_treated = true
			GameState.virelai_harness_spliced = true
			GameState.greyling_cage_broken = true
			GameState.greyling_documented = true
			GameState.sanctuary_pennants_strung = true
			GameState.sanctuary_kestrel_fed = true
			GameState.sanctuary_virelai_talk_done = true
			GameState.sanctuary_virelai_fed = true
			GameState.flight_sortie1_done = true
			GameState.record_flight_breed("Silver-Slate Courier")
			GameState.record_flight_breed("Ochre Gale-Wing")
			GameState.unlock_all_knots()
			GameState.add_item("Brotherhood Harness Carabiner")
			return {"region": "sanctuary", "params": {"skip_intro": true, "cutscene_year5": true, "spawn": Vector2(1082, 513)}}
		"act2_year5":
			GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
			GameState.boy_age = 17
			GameState.sanctuary_phase = 3
			GameState.dragon_trust = 75
			GameState.sanctuary_leather_chore_done = true
			GameState.sanctuary_water_drawn = true
			GameState.sanctuary_poultice_brewed = true
			GameState.sanctuary_greyling_treated = true
			GameState.virelai_harness_spliced = true
			GameState.greyling_cage_broken = true
			GameState.greyling_documented = true
			GameState.sanctuary_pennants_strung = true
			GameState.sanctuary_virelai_oiled = true
			GameState.sanctuary_virelai_talk_done = true
			GameState.sanctuary_kestrel_fed = true
			GameState.sanctuary_drill_mastered = true
			GameState.flight_sortie1_done = true
			GameState.record_flight_breed("Silver-Slate Courier")
			GameState.record_flight_breed("Ochre Gale-Wing")
			GameState.unlock_all_knots()
			GameState.add_item("Brotherhood Harness Carabiner")
			GameState.add_item("Brotherhood Topman's Timing Ring")
			return {"region": "sanctuary", "params": {"skip_intro": true, "spawn": Vector2(360, 505)}}
		"virelai_sortie1":
			_unlock_post_sanctuary(false, false)
			return {"region": "flight", "params": {"sortie": 1}}
		"virelai_sortie2":
			_unlock_post_sanctuary(true, false)
			return {"region": "flight", "params": {"sortie": 2}}
		"cutscene_sky_attack":
			_unlock_post_sanctuary(true, false)
			return {"region": "flight", "params": {"sortie": 2, "cutscene_attack": true}}
		"act3_wilds":
			_unlock_post_sanctuary(true, true)
			return {"region": "wilds", "params": {"step": GameState.QuestStep.ACT3_WILDS_TRACKING, "spawn": Vector2(270, 1890)}}
		"cutscene_dragon_reveal":
			_unlock_post_sanctuary(true, true)
			GameState.wilds_clue_scorched_pine = true
			GameState.has_forest_map = true
			GameState.black_dragon_found = false
			GameState.carrying_egg = false
			return {"region": "wilds", "params": {"step": GameState.QuestStep.ACT3_WILDS_TRACKING, "spawn": Vector2(304, 294), "cutscene_reveal": true}}
		"act3_outpost_trek":
			_unlock_post_sanctuary(true, true)
			GameState.wilds_clue_tracks = true
			GameState.wilds_clue_scorched_pine = true
			GameState.has_forest_map = true
			GameState.black_dragon_found = true
			GameState.carrying_egg = true
			GameState.egg_warmth = 92.0
			GameState.has_mariner_compass = true
			GameState.add_item("Black-Scaled Dragon Egg")
			GameState.add_item("Brotherhood Border Survey Map")
			GameState.add_item("Boy's Brass Pocket Compass")
			return {"region": "wilds", "params": {"step": GameState.QuestStep.ACT3_EGG_TREK, "spawn": Vector2(760, 270)}}
		"cutscene_hatching":
			_unlock_post_sanctuary(true, true)
			GameState.wilds_clue_scorched_pine = true
			GameState.black_dragon_found = true
			return {"region": "hearth", "params": {}}
		"act4_egg_debate":
			_unlock_post_sanctuary(true, true)
			GameState.wilds_clue_scorched_pine = true
			GameState.black_dragon_found = true
			GameState.act4_egg_debate_done = false
			GameState.carrying_egg = true
			GameState.current_step = GameState.QuestStep.ACT4_SANCTUARY_DEBATE
			GameState.sanctuary_phase = 4
			return {"region": "sanctuary", "params": {"skip_intro": true, "preserve_step": true, "act4_debate_intro": true, "spawn": Vector2(342, 504)}}
		"act4_outskirts":
			_unlock_post_sanctuary(true, true)
			GameState.act4_egg_debate_done = true
			GameState.current_step = GameState.QuestStep.ACT4_BRUGES_CITY
			GameState.sanctuary_phase = 4
			return {"region": "outskirts", "params": {"spawn": Vector2(2220, 520), "facing": Vector2.LEFT}}
		"act4_bruges_city":
			_unlock_post_sanctuary(true, true)
			GameState.act4_egg_debate_done = true
			GameState.current_step = GameState.QuestStep.ACT4_BRUGES_CITY
			GameState.sanctuary_phase = 4
			return {"region": "bruges_city", "params": {"spawn": Vector2(1440, 1960), "facing": Vector2.UP}}
		"act4_priest_tail":
			_unlock_post_sanctuary(true, true)
			GameState.act4_egg_debate_done = true
			GameState.city_clue_cloth_hall = true
			GameState.city_clue_beguinage = true
			GameState.city_clue_counting_house = true
			GameState.city_watergate_skirmish_won = true
			GameState.add_item("Church Requisition Writ")
			GameState.current_step = GameState.QuestStep.ACT4_BRUGES_CITY
			GameState.sanctuary_phase = 4
			return {"region": "bruges_city", "params": {"spawn": Vector2(2084, 404), "facing": Vector2.DOWN, "start_priest_tail": true, "skip_intro": true}}
		"act4_night_heist":
			_unlock_post_sanctuary(true, true)
			GameState.act4_egg_debate_done = true
			GameState.city_clue_cloth_hall = true
			GameState.city_clue_beguinage = true
			GameState.city_clue_counting_house = true
			GameState.city_watergate_skirmish_won = true
			GameState.city_priest_tailed = true
			GameState.city_bounty_overheard = true
			GameState.city_keep_escape_won = true
			GameState.act4_lied_to_council = true
			GameState.add_item("Church Requisition Writ")
			GameState.current_step = GameState.QuestStep.ACT4_NIGHT_HEIST
			GameState.sanctuary_phase = 5
			return {"region": "sanctuary", "params": {"skip_intro": true, "preserve_step": true, "spawn": Vector2(184, 212)}}
		"cutscene_kestrel_escape":
			_unlock_post_sanctuary(true, true)
			GameState.act4_egg_debate_done = true
			GameState.city_bounty_overheard = true
			GameState.city_keep_escape_won = true
			GameState.act4_lied_to_council = true
			GameState.act4_egg_stolen_back = true
			GameState.carrying_egg = true
			GameState.add_item("Church Requisition Writ")
			GameState.current_step = GameState.QuestStep.ACT4_NIGHT_HEIST
			GameState.sanctuary_phase = 5
			return {"region": "sanctuary", "params": {"skip_intro": true, "preserve_step": true, "cutscene_kestrel_escape": true}}
	return Book2PresetsScript.apply_preset(scene_id, Callable(PlaytestPresets, "_unlock_post_sanctuary"))
