class_name WorldRealmChartData
extends RefCounted

## Canonical Macro Geography & Campaign Charter for Medieval Flanders,
## Brabant, and the Meuse Borderlands (Belgium realm chart for [M]).
## Keeps Book I coastal regions & Book II+ inland provinces synchronized.

const COASTLINE_POLY := [
	Vector2(0.03, 0.05), Vector2(0.18, 0.05), Vector2(0.16, 0.14),
	Vector2(0.20, 0.19), Vector2(0.24, 0.16), Vector2(0.32, 0.10),
	Vector2(0.42, 0.08), Vector2(0.46, 0.15), Vector2(0.38, 0.22),
	Vector2(0.28, 0.24), Vector2(0.18, 0.24), Vector2(0.12, 0.30),
	Vector2(0.07, 0.39), Vector2(0.03, 0.44)
]

const REALM_BORDER_POLY := [
	Vector2(0.06, 0.44), Vector2(0.11, 0.56), Vector2(0.24, 0.66),
	Vector2(0.40, 0.74), Vector2(0.56, 0.79), Vector2(0.72, 0.87),
	Vector2(0.88, 0.90), Vector2(0.95, 0.78), Vector2(0.96, 0.54),
	Vector2(0.90, 0.32), Vector2(0.78, 0.18), Vector2(0.58, 0.12),
	Vector2(0.44, 0.10)
]

const RIVERS := [
	{
		"name": "Zwin Estuary",
		"width": 3.0,
		"label_pos": Vector2(0.21, 0.16),
		"pts": [Vector2(0.19, 0.22), Vector2(0.22, 0.19), Vector2(0.27, 0.13), Vector2(0.31, 0.09)],
	},
	{
		"name": "Scheldt",
		"width": 3.0,
		"label_pos": Vector2(0.36, 0.32),
		"pts": [
			Vector2(0.17, 0.60), Vector2(0.27, 0.46), Vector2(0.34, 0.37),
			Vector2(0.41, 0.26), Vector2(0.40, 0.14)
		],
	},
	{
		"name": "Dijle",
		"width": 2.4,
		"label_pos": Vector2(0.55, 0.48),
		"pts": [
			Vector2(0.44, 0.29), Vector2(0.50, 0.37), Vector2(0.55, 0.44),
			Vector2(0.58, 0.52), Vector2(0.57, 0.61)
		],
	},
	{
		"name": "Sambre & Meuse",
		"width": 3.4,
		"label_pos": Vector2(0.73, 0.58),
		"pts": [
			Vector2(0.48, 0.73), Vector2(0.60, 0.68), Vector2(0.69, 0.64),
			Vector2(0.76, 0.55), Vector2(0.84, 0.43), Vector2(0.92, 0.34)
		],
	},
]

const PROVINCE_LABELS := [
	{"text": "COUNTY OF FLANDERS", "pos": Vector2(0.14, 0.36), "size": 11},
	{"text": "DUCHY OF BRABANT", "pos": Vector2(0.44, 0.36), "size": 11},
	{"text": "HESBAYE & NAMUR MARCH", "pos": Vector2(0.58, 0.73), "size": 10},
	{"text": "ARDENNES BORDERLANDS", "pos": Vector2(0.77, 0.82), "size": 10},
]

const REALM_NODES := [
	{
		"id": "bruges_port",
		"name": "Port of Bruges",
		"subtitle": "Zwin Quays & Ropewalk Guild",
		"pos": Vector2(0.155, 0.285),
		"region_ids": ["bruges", "house"],
		"book": 1,
		"unlock_step": 0,
		"kind": "port",
		"features": ["Harbor Quays", "Uncle Willem's Cottage"],
		"lore": "Busy Flemish tidal harbor where Clara honed her gale-rigging craft and Church decrees first offered twenty gold florins for live-chained wyrms.",
	},
	{
		"id": "bruges_city",
		"name": "Walled City of Bruges",
		"subtitle": "Grote Markt & St. Donatian",
		"pos": Vector2(0.195, 0.235),
		"region_ids": ["bruges_city"],
		"book": 1,
		"unlock_step": 6,
		"kind": "city",
		"features": ["Church Garrison", "Beguinage", "Town Gates"],
		"lore": "Reien canals and Belfry stone hide the Cabal's couriers; here Father Anselm cried the dawn bounty on a gold-veined black egg.",
	},
	{
		"id": "bruges_sanctuary",
		"name": "Sanctuary Cliffs",
		"subtitle": "Brotherhood Cliff Refuge",
		"pos": Vector2(0.285, 0.215),
		"region_ids": ["outskirts", "sanctuary"],
		"book": 1,
		"unlock_step": 1,
		"kind": "sanctuary",
		"features": ["Dragon Aviary", "Wind-Winch Loft", "Anna's Wing"],
		"lore": "Sea-fogged limestone refuge east of the Zwin causeway where Captain Anna's Brotherhood shelters untamed coastal dragons in secret.",
	},
	{
		"id": "whispering_pines",
		"name": "Whispering Pines",
		"subtitle": "Frost Gorge & Watchtower Hearth",
		"pos": Vector2(0.365, 0.265),
		"region_ids": ["wilds", "hearth", "flight"],
		"book": 1,
		"unlock_step": 3,
		"kind": "wilds",
		"features": ["Obsidian Hollow", "Virelai Airfield"],
		"lore": "Pine ravines where the Shadow-Guardian perished shielding her black-and-gold egg from Church bolt-crews before dawn.",
	},
	{
		"id": "brabant_fens",
		"name": "Brabant Reed-Fens",
		"subtitle": "Dikes, Toll Causeways & Fen Camps",
		"pos": Vector2(0.455, 0.415),
		"region_ids": ["brabant_fens"],
		"book": 2,
		"unlock_step": 15,
		"kind": "camp",
		"features": ["Campfire Roost", "Smuggler Weir"],
		"lore": "Reed-choked dikes between Flanders and Brabant where the Boy sets down beside Kestrel under night stars, hunted across parish roads.",
	},
	{
		"id": "louvain",
		"name": "Louvain",
		"subtitle": "Birthplace on the Dijle • Cloth-Halls",
		"pos": Vector2(0.555, 0.455),
		"region_ids": ["louvain", "louvain_catacombs"],
		"book": 2,
		"unlock_step": 16,
		"kind": "city",
		"features": ["Hatching Loft", "Bounty Heat", "Kestrel Courier"],
		"lore": "City of the Boy's earliest childhood memories before the slaughter at Old Heverlee; in a soot-dark loft the gold-flecked egg breaks open.",
	},
	{
		"id": "old_heverlee",
		"name": "Old Heverlee Woods",
		"subtitle": "Ruined Shrine & Hunters' Hollow",
		"pos": Vector2(0.575, 0.555),
		"region_ids": ["old_heverlee"],
		"book": 2,
		"unlock_step": 17,
		"kind": "shrine",
		"features": ["Excavated Shrine", "Campfire Roost", "Dragon Growth Stage 2"],
		"lore": "Ancient Brabant oakwoods where the Boy's parents uncovered a forbidden Devildragon ritual and hid its bronze key before Inquisitors struck.",
	},
	{
		"id": "hesbaye_uplands",
		"name": "Hesbaye Uplands",
		"subtitle": "Open Downs & Watch-Signal Cairns",
		"pos": Vector2(0.645, 0.585),
		"region_ids": ["hesbaye_uplands"],
		"book": 2,
		"unlock_step": 18,
		"kind": "wilds",
		"features": ["Anna Aerial Liaison", "Campfire Roost"],
		"lore": "Wind-swept chalk hills overlooking the road from Brabant toward the Meuse; Anna's sky-scouts track Cabal supply trains below.",
	},
	{
		"id": "namur_citadel",
		"name": "Namur Cliff-Citadel",
		"subtitle": "Confluence of Sambre & Meuse",
		"pos": Vector2(0.695, 0.645),
		"region_ids": ["namur_citadel"],
		"book": 2,
		"unlock_step": 19,
		"kind": "city",
		"features": ["River Gates", "Bounty Heat", "Dragon Growth Stage 3"],
		"lore": "Steep fortress rock pinning the Meuse ferries; Church inquisitors funnel chained wyrms and Bruges hemp rigs through its river-locks.",
	},
	{
		"id": "ardennes_ridge",
		"name": "Ardennes Mist-Gorges",
		"subtitle": "Pine Crags & Molting Sanctuary",
		"pos": Vector2(0.805, 0.695),
		"region_ids": ["ardennes_ridge"],
		"book": 2,
		"unlock_step": 21,
		"kind": "wilds",
		"features": ["Dragon Growth Stage 4", "Dragon-Rally Roost"],
		"lore": "Craggy slate ridges above the eastern Meuse where soot-black scales flake clean away to reveal sovereign gold beneath.",
	},
	{
		"id": "blood_citadel",
		"name": "Meuse Blood-Citadel",
		"subtitle": "Cathedral Crypt of the Devildragon",
		"pos": Vector2(0.895, 0.515),
		"region_ids": ["blood_citadel"],
		"book": 2,
		"unlock_step": 22,
		"kind": "citadel",
		"features": ["Ritual Altar", "Clara Rescue", "Prophecy Climax"],
		"lore": "Forbidden fortress-abbey in the deep Meuse borderlands where captured dragons bleed to wake an unholy Devildragon.",
	},
]

const REALM_ROUTES := [
	# Solid overland roads
	{"from": "bruges_port", "to": "bruges_city", "kind": "road"},
	{"from": "bruges_city", "to": "bruges_sanctuary", "kind": "road"},
	{"from": "bruges_sanctuary", "to": "whispering_pines", "kind": "road"},
	{"from": "whispering_pines", "to": "brabant_fens", "kind": "road"},
	{"from": "brabant_fens", "to": "louvain", "kind": "road"},
	{"from": "louvain", "to": "old_heverlee", "kind": "road"},
	{"from": "old_heverlee", "to": "hesbaye_uplands", "kind": "road"},
	{"from": "hesbaye_uplands", "to": "namur_citadel", "kind": "road"},
	{"from": "namur_citadel", "to": "ardennes_ridge", "kind": "road"},
	{"from": "ardennes_ridge", "to": "blood_citadel", "kind": "road"},
	# Aerial corridors: Virelai Brotherhood patrol & Kestrel courier link
	{"from": "bruges_sanctuary", "to": "whispering_pines", "kind": "virelai", "arc": Vector2(0.32, 0.14)},
	{"from": "bruges_sanctuary", "to": "hesbaye_uplands", "kind": "virelai", "arc": Vector2(0.51, 0.24)},
	{"from": "whispering_pines", "to": "brabant_fens", "kind": "kestrel", "arc": Vector2(0.43, 0.29)},
	{"from": "bruges_sanctuary", "to": "louvain", "kind": "kestrel", "arc": Vector2(0.45, 0.27)},
	{"from": "louvain", "to": "namur_citadel", "kind": "kestrel", "arc": Vector2(0.68, 0.50)},
]


static func get_node_by_id(node_id: String) -> Dictionary:
	for n in REALM_NODES:
		if str(n["id"]) == node_id:
			return n
	return {}


static func node_id_for_region(region_id: String) -> String:
	for n in REALM_NODES:
		if region_id in n["region_ids"]:
			return str(n["id"])
	return "bruges_port"


static func is_node_discovered(node: Dictionary) -> bool:
	var nid: String = str(node["id"])
	if GameState.discovered_realm_nodes.has(nid):
		return true
	var step_req: int = int(node.get("unlock_step", 99))
	if int(GameState.current_step) >= step_req:
		return true
	return false


static func get_route_status(route: Dictionary) -> String:
	var n_from: Dictionary = get_node_by_id(str(route["from"]))
	var n_to: Dictionary = get_node_by_id(str(route["to"]))
	var a_ok := is_node_discovered(n_from)
	var b_ok := is_node_discovered(n_to)
	if a_ok and b_ok:
		return "charted"
	if a_ok or b_ok:
		return "rumored"
	return "uncharted"


static func get_anna_anchor_node_id() -> String:
	if int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_BLOOD_CITADEL):
		return "ardennes_ridge"
	if GameState.anna_sortie2_done or int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_ANNA_SORTIE_2):
		return "hesbaye_uplands"
	if GameState.anna_sortie1_done or int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_ANNA_SORTIE_1):
		return "brabant_fens"
	return "bruges_sanctuary"


static func get_kestrel_curve_nodes() -> Array[String]:
	if int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_NAMUR_CROSSING):
		return ["hesbaye_uplands", "namur_citadel"]
	if int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_LOUVAIN_HATCH):
		return ["bruges_sanctuary", "louvain"]
	if int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_BRABANT_FENS):
		return ["whispering_pines", "brabant_fens"]
	return []
