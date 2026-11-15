extends RefCounted

## Book II+ ("The Golden Heir") presets and state setup delegated by PlaytestPresets.

const PRESETS: Array = [
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
		"title": "Abbey Scriptorium & Courtyard Breakout",
		"label": "Act I: Abbey Vault & Resonance Breakout",
		"region": "louvain",
		"location": "Louvain Abbey Cloister",
		"summary": "Slip through the cloister drain [R], light dark vault sconces to read the Old Heverlee Decrees, and shatter the Catchpole ambush.",
		"kit": "3-Hit Knife • Whipping Shield-Yank",
	},
]


static func get_active_preset_id() -> String:
	match GameState.current_step:
		GameState.QuestStep.BOOK2_BRABANT_FENS:
			return "book2_brabant_hatchling" if GameState.brabant_hatched else "book2_brabant_arrival"
		GameState.QuestStep.BOOK2_LOUVAIN_HATCH:
			return "book2_louvain_abbey" if GameState.louvain_vent_opened else "book2_louvain_city"
	return ""


static func apply_preset(scene_id: String, unlock_post_sanctuary: Callable) -> Dictionary:
	match scene_id:
		"book2_brabant_arrival":
			unlock_post_sanctuary.call(true, true)
			GameState.reset_book2_state(true)
			GameState.carrying_egg = true
			GameState.add_item("Black-and-Gold Dragon Egg")
			GameState.add_item("Raw River Ration")
			return {"region": "brabant_fens", "params": {"book2_intro": true, "spawn": Vector2(276, 708)}}
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
			return {"region": "louvain", "params": {"spawn": Vector2(160, 880), "facing": Vector2.RIGHT}}
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
			return {"region": "louvain", "params": {"spawn": Vector2(2044, 764), "facing": Vector2.UP}}
	return {}
