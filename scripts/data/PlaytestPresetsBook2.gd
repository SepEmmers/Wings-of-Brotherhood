extends RefCounted

## Book II+ ("The Golden Heir") presets and state setup delegated by PlaytestPresets.

const PRESETS: Array = [
	{
		"id": "book2_brabant_hd2d",
		"chapter": "book2",
		"kind": "scene",
		"tag": "HD-2D",
		"title": "HD-2D Prototype — Brabant Reed-Fens (Octopath Style)",
		"label": "Showcase: Brabant Reed-Fens (Octopath HD-2D)",
		"region": "brabant_fens",
		"location": "Brabant Mill Courtyard (HD-2D Diorama)",
		"summary": "Full 3D Octopath-style diorama of Brabant Reed-Fens with normal-mapped pixel sprites, dynamic firelight, tilt-shift DoF, and quantized canal water. Press [H] to compare 2D vs HD-2D and [O] for Scenic Vista.",
		"kit": "Stage 1 Hatchling • [H] 2D/HD-2D • [O] Camera Vista",
	},
	{
		"id": "book2_brabant_arrival",
		"chapter": "book2",
		"kind": "cutscene",
		"tag": "II-1A",
		"title": "Brabant Fens — Kestrel Landing & Egg Hatching",
		"label": "Act I: Brabant Arrival & Egg Hatching",
		"region": "brabant_fens",
		"location": "Brabant Reed-Fens (West Marsh)",
		"summary": "Land beside Kestrel in misty Brabant fens, warm the black-and-gold egg at the old mill fire, and name your hatchling.",
		"kit": "Black-and-Gold Egg • Mill Campfire",
	},
	{
		"id": "book2_egg_hatching",
		"chapter": "book2",
		"kind": "cutscene",
		"tag": "II-1H",
		"title": "Egg Hatching at Old Mill Campfire",
		"label": "Cutscene: Dramatic Egg Hatching & Imprinting",
		"region": "brabant_fens",
		"location": "Brabant Mill Campfire",
		"summary": "Watch the hand-animated close-up sequence as the obsidian-and-gold egg cracks open beside the fire and imprints on your palm.",
		"kit": "Black-and-Gold Egg • Dramatic Close-Up Cutscene",
	},
	{
		"id": "book2_brabant_hatchling",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-1B",
		"title": "Mill Sluice Vent & Ember Puzzle",
		"label": "Act I: Brabant Hatchling Trail",
		"region": "brabant_fens",
		"location": "Brabant Old Mill Ruins",
		"summary": "Feed your soot-black Hatchling at camp, send him through the iron sluice grate [R], and char fen briars.",
		"kit": "Hatchling Stage 1 • Venture Vent & Ember",
	},
	{
		"id": "book2_louvain_city",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-2A",
		"title": "Louvain — Dijle Quarter & Cloak-Sling",
		"label": "Act I: Louvain Streets & Side Stories",
		"region": "louvain",
		"location": "Louvain West Gate",
		"summary": "Hide your hatchling in the Cloak-Sling [X], aid the Bell-Founder & Herbalist, tear Bounty Posters, and probe your parents' guild.",
		"kit": "Cloak-Sling Stealth • Chimes & Smoke",
	},
	{
		"id": "book2_louvain_abbey",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-2B",
		"title": "Abbey Cloister & Drain Gate",
		"label": "Act I: Enclosed Cloister & Cathedral Approach",
		"region": "louvain",
		"location": "Louvain Abbey Cloister",
		"summary": "Send your hatchling through the Cloister drain [R] to unbar the iron gate and step inside the Cathedral.",
		"kit": "Drain Vent Crawl • Cloister Gate",
	},
	{
		"id": "book2_louvain_catacombs",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-2C",
		"title": "Cathedral, Catacombs & Hidden Library",
		"label": "Act I: 3-Floor Cathedral Dungeon",
		"region": "louvain_catacombs",
		"location": "Abbey Cathedral Nave",
		"summary": "Light the Nave altar candles [R], decode Tapestry clues to push the right Catacombs tomb, and sort 1422/1426 ledgers in the Hidden Library.",
		"kit": "Altar Candles • Pushable Graves & Traps • Date Archive",
	},
	{
		"id": "book2_old_heverlee",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-3A",
		"title": "Old Heverlee — Ambush Glade & Woods",
		"label": "Act I: Old Heverlee Woods & Zoet Water",
		"region": "old_heverlee",
		"location": "Old Heverlee Trail",
		"summary": "Investigate your parents' 9-year-old ambush glade, cross Zoet Water creek, clear Inquisitor scouts, and burn shrine brambles.",
		"kit": "Ember Puff • Creek Rope Grapple • Forensics",
	},
	{
		"id": "book2_old_heverlee_shrine",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-3B",
		"title": "First Golden Dragon Shrine — Relic Key",
		"label": "Act I: Subterranean Golden Shrine",
		"region": "old_heverlee_shrine",
		"location": "Old Heverlee Shrine Vault",
		"summary": "Read the Devildragon ritual relief, push keystone boulder onto the bronze plate + Serpent Vent [R], bridge the chasm [F], and claim the Relic Key.",
		"kit": "Weight Plate • Serpent Vent • Twin Ember Braziers",
	},
	{
		"id": "book2_anna_sanctuary",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-4A",
		"title": "Anna Ch. 1 — Sanctuary Council Deception",
		"label": "Act I: Anna's Council Bluff",
		"region": "anna_ch1_sanctuary",
		"location": "Brotherhood Sanctuary Hall",
		"summary": "Play Captain Anna: read Kestrel's Old Heverlee dispatch, misdirect Saddler Hendrick toward the coast, pack Hesbaye rations, and mount Virelai.",
		"kit": "Perspective Swap: Anna • Council Choice • Kestrel",
	},
	{
		"id": "book2_anna_barge_raid",
		"chapter": "book2",
		"kind": "scene",
		"tag": "II-4B",
		"title": "Anna Ch. 1 — Virelai Blood-Barge Raid",
		"label": "Act I: Twilight River Convoy Raid",
		"region": "anna_ch1_raid",
		"location": "Brabant / Meuse River Gorge",
		"summary": "Fly Virelai over the twilight gorge, shatter iron chain-booms & 3 Acoustic Ward-Bell Blood Barges, and liberate captive dragons.",
		"kit": "Virelai Flight Combat • Ward-Bell Dodge • Convoy Rescue",
	},
	{
		"id": "book2_custom_dungeon",
		"chapter": "book2",
		"kind": "scene",
		"tag": "STUDIO",
		"title": "Custom Studio Dungeon — Puzzle Maker",
		"label": "Studio: Custom Dungeon & Puzzles",
		"region": "custom_dungeon",
		"location": "In-Browser Studio Dungeon (data/custom_dungeon.json)",
		"summary": "Playtest the custom multi-room dungeon, logic wires, and dragon puzzles built in the In-Browser Creator Studio.",
		"kit": "Stage 1 Hatchling • Custom Puzzles & Reliquary",
	},
]


static func get_active_preset_id() -> String:
	match GameState.current_step:
		GameState.QuestStep.BOOK2_BRABANT_FENS:
			return "book2_brabant_hatchling" if GameState.brabant_hatched else "book2_brabant_arrival"
		GameState.QuestStep.BOOK2_LOUVAIN_HATCH:
			return "book2_louvain_abbey" if GameState.louvain_vent_opened else "book2_louvain_city"
		GameState.QuestStep.BOOK2_OLD_HEVERLEE:
			return "book2_old_heverlee"
		GameState.QuestStep.BOOK2_ANNA_SORTIE_1:
			return "book2_anna_barge_raid" if GameState.anna_ch1_council_done else "book2_anna_sanctuary"
	return ""


static func apply_preset(scene_id: String, unlock_post_sanctuary: Callable) -> Dictionary:
	match scene_id:
		"book2_brabant_hd2d":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.brabant_feed_intro_done = true
			GameState.hatchling_fed_count = 1
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 20
			GameState.add_item("Raw River Ration")
			return {"region": "brabant_fens", "params": {"hatched_state": true, "spawn": Vector2(924, 706), "facing": Vector2.RIGHT}}
		"book2_brabant_arrival":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.carrying_egg = true
			GameState.add_item("Black-and-Gold Dragon Egg")
			GameState.add_item("Raw River Ration")
			return {"region": "brabant_fens", "params": {"book2_intro": true, "spawn": Vector2(276, 708)}}
		"book2_egg_hatching":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.carrying_egg = true
			GameState.add_item("Black-and-Gold Dragon Egg")
			GameState.add_item("Raw River Ration")
			return {"region": "brabant_fens", "params": {"cutscene_hatch": true, "spawn": Vector2(942, 692)}}
		"book2_brabant_hatchling":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 15
			GameState.add_item("Raw River Ration")
			return {"region": "brabant_fens", "params": {"hatched_state": true, "spawn": Vector2(930, 700)}}
		"book2_louvain_city":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.brabant_feed_intro_done = true
			GameState.brabant_sling_practiced = true
			GameState.hatchling_fed_count = 1
			GameState.brabant_vent_unlocked = true
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 22
			GameState.current_step = GameState.QuestStep.BOOK2_LOUVAIN_HATCH
			GameState.add_item("Bronze Resonance Chime")
			GameState.add_item("Smoke-Pellet")
			return {"region": "louvain", "params": {"spawn": Vector2(226, 1040), "facing": Vector2.RIGHT}}
		"book2_louvain_abbey":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.brabant_feed_intro_done = true
			GameState.brabant_sling_practiced = true
			GameState.hatchling_fed_count = 1
			GameState.brabant_vent_unlocked = true
			GameState.louvain_bell_mould_fixed = true
			GameState.louvain_herbalist_done = true
			GameState.resonance_chimes = 2
			GameState.smoke_pellets = 2
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 30
			GameState.current_step = GameState.QuestStep.BOOK2_LOUVAIN_HATCH
			GameState.add_item("Bronze Resonance Chime")
			GameState.add_item("Smoke-Pellet")
			return {"region": "louvain", "params": {"spawn": Vector2(1458, 794), "facing": Vector2.UP}}
		"book2_louvain_catacombs":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.brabant_feed_intro_done = true
			GameState.brabant_sling_practiced = true
			GameState.hatchling_fed_count = 1
			GameState.brabant_vent_unlocked = true
			GameState.louvain_bell_mould_fixed = true
			GameState.louvain_herbalist_done = true
			GameState.louvain_vent_opened = true
			GameState.resonance_chimes = 2
			GameState.smoke_pellets = 2
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 32
			GameState.current_step = GameState.QuestStep.BOOK2_LOUVAIN_HATCH
			GameState.add_item("Bronze Resonance Chime")
			GameState.add_item("Smoke-Pellet")
			return {"region": "louvain_catacombs", "params": {"floor": 0, "spawn": Vector2(480, 732), "facing": Vector2.UP}}
		"book2_old_heverlee":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.brabant_vent_unlocked = true
			GameState.louvain_archive_read = true
			GameState.louvain_breakout_won = true
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 40
			GameState.current_step = GameState.QuestStep.BOOK2_OLD_HEVERLEE
			GameState.add_item("Abbey Scriptorium Decree")
			return {"region": "old_heverlee", "params": {"spawn": Vector2(1100, 128), "facing": Vector2.DOWN}}
		"book2_old_heverlee_shrine":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.brabant_vent_unlocked = true
			GameState.louvain_archive_read = true
			GameState.louvain_breakout_won = true
			GameState.heverlee_ambush_inspected = true
			GameState.heverlee_briar_burned = true
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 48
			GameState.current_step = GameState.QuestStep.BOOK2_OLD_HEVERLEE
			GameState.add_item("Abbey Scriptorium Decree")
			return {"region": "old_heverlee_shrine", "params": {"spawn": Vector2(328, 742), "facing": Vector2.UP}}
		"book2_anna_sanctuary":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.boy_heverlee_relic_found = true
			GameState.heverlee_kestrel_sent = true
			GameState.active_perspective = "anna"
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 65
			GameState.current_step = GameState.QuestStep.BOOK2_ANNA_SORTIE_1
			return {"region": "anna_ch1_sanctuary", "params": {}}
		"book2_anna_barge_raid":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.boy_heverlee_relic_found = true
			GameState.heverlee_kestrel_sent = true
			GameState.anna_ch1_council_done = true
			GameState.anna_ch1_deception_choice = "ostend"
			GameState.active_perspective = "anna"
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 68
			GameState.current_step = GameState.QuestStep.BOOK2_ANNA_SORTIE_1
			GameState.add_item("Anna's Hesbaye Supply Satchel")
			return {"region": "anna_ch1_raid", "params": {}}
		"book2_custom_dungeon":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.brabant_hatched = true
			GameState.active_companion_stage = 1
			GameState.gold_dragon_name = "Aurelius"
			GameState.dragon_bond = 50
			GameState.current_step = GameState.QuestStep.BOOK2_OLD_HEVERLEE
			return {"region": "custom_dungeon", "params": {}}
	return {}
