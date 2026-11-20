class_name LouvainCityMapData
extends RefCounted

## Historical 15th-Century Circular Louvain Layout ("De Kuip", 2100x2100):
## Concentric octagonal ring-wall & 4 Poorten gates, River Dijle inner harbor
## & Vismarkt quay, Grote Markt (Het Stadhuis, unfinished Sint-Pieterskerk &
## scaffolding, De Lakenhalle & 1425 University), Dyers' Island, Bell-Foundry,
## props, stealth cover, patrols, and ambient citizens.

const WORLD_SIZE := Vector2(2100, 2100)
const CENTER := Vector2(1050, 1050)

const WEST_ENTRY_SPAWN := Vector2(226, 1040)
const ABBEY_GATE_RECT := Rect2(1296, 736, 84, 36)
const ABBEY_VENT_POS := Vector2(1458, 754)
const ABBEY_LEVER_POS := Vector2(1386, 718)
const CATHEDRAL_DOOR_PORTAL_RECT := Rect2(1382, 462, 56, 32)
const CATHEDRAL_EXIT_RETURN_POS := Vector2(1410, 516)
const SOUTH_GATE_BARRICADE_RECT := Rect2(996, 1938, 108, 36)

const FOUNTAIN_POS := Vector2(1050, 945)
const CLAY_BANK_POS := Vector2(556, 562)
const BELL_MOULD_POS := Vector2(736, 480)
const FOUNDRY_WINCH_POS := Vector2(800, 488)
const MASON_STONE_POS := Vector2(592, 906)
const MASON_CRANE_POS := Vector2(1148, 764)
const HERBALIST_SLUICE_POS := Vector2(440, 1510)
const CONFISCATED_CHEST_POS := Vector2(1748, 976)
const SOUTH_SIGN_POS := Vector2(954, 1892)


static func get_water_rects() -> Array[Rect2]:
	return [
		Rect2(456, 0, 84, 700),        # Dijle North reach flowing cleanly under NW Waterpoort from map top
		Rect2(436, 784, 124, 202),     # Vismarkt widened inner harbor basin
		Rect2(456, 1094, 84, 166),     # Dijle Mid reach (south of Brusselsestraat bridge)
		Rect2(456, 1348, 84, 752),     # Dijle South reach flowing under SW Waterpoort out south edge
	]


static func get_watergates() -> Array[Vector2]:
	return [
		Vector2(498, 244),             # North Dijle Waterpoort spanning NW diagonal rampart gap
		Vector2(498, 1856),            # South Dijle Waterpoort spanning SW diagonal rampart gap
	]


static func get_river_barges() -> Array[Dictionary]:
	return [
		{"tex": "prop_canal_barge_v_cargo.png", "rect": Rect2(448, 816, 44, 72), "phase": 0.4},
		{"tex": "prop_canal_barge_v.png", "rect": Rect2(498, 900, 42, 66), "phase": 2.1},
		{"tex": "prop_canal_barge_v_cargo.png", "rect": Rect2(474, 1422, 42, 68), "phase": 1.3},
	]


static func get_bridges() -> Array[Dictionary]:
	return [
		{"tex": "prop_stone_bridge_h.png", "rect": Rect2(436, 700, 124, 84)},
		{"tex": "prop_stone_bridge_h.png", "rect": Rect2(430, 986, 140, 108)},
		{"tex": "prop_stone_bridge_h.png", "rect": Rect2(436, 1260, 124, 88)},
	]


static func get_roads() -> Array[Rect2]:
	return [
		Rect2(130, 996, 1824, 88),     # Brusselsestraat -> Grote Markt -> Tiensestraat
		Rect2(752, 468, 92, 540),      # Mechelsestraat south stretch west of St. Peter's
		Rect2(800, 430, 290, 76),      # St. Peter's Choir cross-lane
		Rect2(1004, 130, 92, 340),     # Mechelsepoort North gate road
		Rect2(1176, 1070, 88, 490),    # Naamsestraat North (east of Stadhuis)
		Rect2(1002, 1490, 260, 84),    # Naamsestraat elbow
		Rect2(1002, 1520, 96, 452),    # Naamsepoort South avenue
		Rect2(540, 456, 260, 80),      # Bell-Foundry Lane
		Rect2(540, 704, 232, 78),      # Vismarkt Bridge crossing
		Rect2(190, 1266, 260, 78),     # Dyers' Island Cross-Lane
		Rect2(548, 1266, 460, 78),     # Oude Markt -> Lakenhalle south approach
		Rect2(560, 1340, 92, 220),     # South Cloth Quarter loop
		Rect2(600, 1490, 440, 82),     # South University Way
		Rect2(1240, 742, 420, 76),     # Chapter Cloister south street
		Rect2(1600, 742, 84, 290),     # Tiensepoort north connector
	]


static func get_brick_paths() -> Array[Rect2]:
	return [
		Rect2(558, 680, 62, 316),      # Vismarkt inner harbor brick quay
		Rect2(620, 792, 124, 188),     # Vismarkt open fishmarket apron
		Rect2(236, 1146, 198, 122),    # Dyers' & Herbalist terrace
		Rect2(640, 1332, 292, 148),    # De Lakenhalle courtyard brick border
	]


static func get_plazas() -> Array[Dictionary]:
	return [
		{"rect": Rect2(846, 756, 470, 310), "style": "sandstone"},    # Grote Markt
		{"rect": Rect2(648, 1338, 276, 136), "style": "sandstone"},   # Lakenhalle & 1425 University Forecourt
		{"rect": Rect2(1264, 288, 292, 452), "style": "sandstone"},   # Enclosed Abbey Cathedral & Cloister Precinct
	]


static func get_garden_lawns() -> Array[Rect2]:
	return [
		Rect2(1284, 492, 92, 114),     # Cloister Herb Lawn NW
		Rect2(1446, 492, 92, 114),     # Cloister Herb Lawn NE
		Rect2(204, 1528, 224, 150),    # Katelijne Medicinal Garden
		Rect2(838, 536, 56, 156),      # St. Peter's Lime Yard West
	]


static func get_buildings() -> Array[Dictionary]:
	return [
		# Central Civic & Scholarly Heart (Grote Markt & Lakenhalle)
		{"tex": "bldg_louvain_st_peters.png", "rect": Rect2(854, 424, 368, 330)},
		{"tex": "bldg_louvain_stadhuis.png",  "rect": Rect2(920, 1066, 260, 212)},
		{"tex": "bldg_louvain_lakenhalle.png","rect": Rect2(600, 1096, 316, 232)},

		# NW Vismarkt Harbor, Bell-Foundry & North Mechelsestraat (Leuven Gobertange & Speklagen)
		{"tex": "bldg_louvain_foundry.png",   "rect": Rect2(576, 276, 168, 138)},
		{"tex": "city_leuven_bakery_5a.png",  "rect": Rect2(580, 540, 156, 134)},
		{"tex": "city_leuven_house_4a.png",   "rect": Rect2(1524, 1556, 152, 128)},
		{"tex": "city_louvain_mason_4a.png",  "rect": Rect2(836, 224, 148, 126)},
		{"tex": "city_leuven_manor_7a.png",   "rect": Rect2(582, 1732, 198, 150)},
		{"tex": "city_leuven_cottage_4c.png", "rect": Rect2(812, 1732, 148, 124)},

		# West Entry Row (inside Brusselsepoort west of Dijle)
		{"tex": "city_leuven_house_4b.png",   "rect": Rect2(262, 540, 150, 126)},
		{"tex": "city_leuven_bakery_5a.png",  "rect": Rect2(252, 822, 162, 138)},

		# SW Dyers' Island & Childhood Hunters' Tavern
		{"tex": "city_leuven_tavern_6a.png",  "rect": Rect2(248, 1104, 184, 148)},
		{"tex": "city_louvain_dyer_5b.png",   "rect": Rect2(228, 1384, 168, 138)},

		# NE Abbey Cathedral Enclosed Inside Four-Walled Cloister Precinct
		{"tex": "bldg_louvain_abbey.png",     "rect": Rect2(1284, 264, 252, 224)},
		{"tex": "city_leuven_begijnhof_5a.png","rect": Rect2(1618, 490, 188, 154)},

		# East Tiensestraat University & Catchpole Garrison Quarter
		{"tex": "city_louvain_scholar_5a.png","rect": Rect2(1390, 822, 166, 136)},
		{"tex": "city_leuven_garrison_7c.png","rect": Rect2(1648, 804, 198, 148)},
		{"tex": "city_leuven_weavers_6b.png", "rect": Rect2(1320, 1114, 178, 146)},
		{"tex": "city_louvain_scholar_5a.png","rect": Rect2(1524, 1126, 166, 136)},
		{"tex": "city_leuven_house_4a.png",   "rect": Rect2(1320, 1360, 152, 128)},
		{"tex": "city_leuven_manor_7a.png",   "rect": Rect2(1498, 1352, 198, 150)},

		# South Naamsestraat Gatehouse Residential Row
		{"tex": "city_leuven_cottage_4c.png", "rect": Rect2(640, 1584, 148, 124)},
		{"tex": "city_leuven_house_4b.png",   "rect": Rect2(812, 1584, 150, 126)},
		{"tex": "city_leuven_house_4a.png",   "rect": Rect2(1140, 1584, 152, 128)},
		{"tex": "city_louvain_mason_4a.png",  "rect": Rect2(1316, 1584, 150, 126)},
	]


static func get_prop_placements() -> Array[Dictionary]:
	return [
		# Grote Markt Civic Plaza: Bakers, Carts, Stalls, Shade Lime Trees
		{"tex": "prop_brick_bread_oven.png",  "rect": Rect2(624, 676, 48, 40),  "solid": true,  "cover": true},
		{"tex": "prop_flour_sack_stack.png",  "rect": Rect2(678, 690, 30, 26),  "solid": false, "cover": false},
		{"tex": "prop_wine_cask_cart.png",    "rect": Rect2(864, 910, 62, 42),  "solid": true,  "cover": true},
		{"tex": "prop_stall_food.png",        "rect": Rect2(878, 822, 68, 48),  "solid": true,  "cover": true},
		{"tex": "prop_stall_gear.png",        "rect": Rect2(1168, 824, 68, 48), "solid": true,  "cover": true},
		{"tex": "prop_noticeboard.png",       "rect": Rect2(1134, 922, 38, 46), "solid": true,  "cover": false},
		{"tex": "prop_lime_tree.png",         "rect": Rect2(848, 560, 56, 72),  "solid": true,  "cover": false},
		{"tex": "prop_lime_tree.png",         "rect": Rect2(1248, 864, 58, 74), "solid": true,  "cover": false},
		{"tex": "prop_lime_tree.png",         "rect": Rect2(806, 1004, 54, 70), "solid": true,  "cover": false},

		# Sint-Pieterskerk Scaffolding Yard & Mason Quarry
		{"tex": "prop_mason_yard.png",        "rect": Rect2(1176, 680, 62, 42), "solid": true,  "cover": true},
		{"tex": "prop_hay_bale.png",          "rect": Rect2(922, 746, 36, 30),  "solid": true,  "cover": false},

		# De Lakenhalle Cloth Yard & 1425 University Benches
		{"tex": "prop_cloth_bales.png",       "rect": Rect2(658, 1342, 44, 32), "solid": true,  "cover": false},
		{"tex": "prop_cloth_bales.png",       "rect": Rect2(708, 1342, 44, 32), "solid": true,  "cover": false},
		{"tex": "prop_lime_tree.png",         "rect": Rect2(938, 1352, 54, 70), "solid": true,  "cover": false},
		{"tex": "prop_crate.png",             "rect": Rect2(752, 1438, 34, 34), "solid": true,  "cover": true},
		{"tex": "prop_barrel.png",            "rect": Rect2(794, 1440, 32, 32), "solid": true,  "cover": true},

		# Vismarkt Harbor Quay: Herring Buckets, Wine Dray, Crates & Lanterns
		{"tex": "prop_herring_bucket.png",    "rect": Rect2(566, 804, 28, 28),  "solid": true,  "cover": false},
		{"tex": "prop_herring_bucket.png",    "rect": Rect2(566, 932, 28, 28),  "solid": true,  "cover": false},
		{"tex": "prop_wine_cask_cart.png",    "rect": Rect2(648, 906, 62, 42),  "solid": true,  "cover": true},
		{"tex": "prop_stall_food.png",        "rect": Rect2(660, 804, 68, 48),  "solid": true,  "cover": true},
		{"tex": "prop_barrel.png",            "rect": Rect2(692, 536, 32, 32),  "solid": true,  "cover": true},
		{"tex": "prop_crate.png",             "rect": Rect2(648, 536, 34, 34),  "solid": true,  "cover": true},

		# Dyers' & Herbalist Island + Childhood Hunters' Tavern
		{"tex": "prop_tavern_table.png",      "rect": Rect2(238, 1244, 48, 34), "solid": true,  "cover": false},
		{"tex": "prop_ale_barrel_rack.png",   "rect": Rect2(354, 1238, 42, 32), "solid": true,  "cover": false},
		{"tex": "prop_dye_vat_red.png",       "rect": Rect2(236, 1516, 36, 34), "solid": true,  "cover": false},
		{"tex": "prop_dye_vat_blue.png",      "rect": Rect2(280, 1516, 36, 34), "solid": true,  "cover": false},
		{"tex": "prop_drying_herbs.png",      "rect": Rect2(326, 1596, 52, 40), "solid": true,  "cover": false},
		{"tex": "prop_lime_tree.png",         "rect": Rect2(204, 1600, 56, 72), "solid": true,  "cover": false},

		# Chapter Cloister Herb Lawn, East Garrison & Approach Cover
		{"tex": "prop_lime_tree.png",         "rect": Rect2(1292, 514, 54, 70), "solid": true,  "cover": false},
		{"tex": "prop_lime_tree.png",         "rect": Rect2(1476, 514, 54, 70), "solid": true,  "cover": false},
		{"tex": "prop_garrison_rack.png",     "rect": Rect2(1704, 950, 44, 34), "solid": true,  "cover": false},
		{"tex": "prop_iron_chain_wagon.png",  "rect": Rect2(1690, 1084, 88, 56),"solid": true,  "cover": true},
		{"tex": "prop_wine_cask_cart.png",    "rect": Rect2(1440, 1088, 60, 40),"solid": true,  "cover": true},
		{"tex": "prop_hay_bale.png",          "rect": Rect2(1258, 976, 36, 30), "solid": true,  "cover": true},
		{"tex": "prop_hay_bale.png",          "rect": Rect2(310, 964, 36, 30),  "solid": true,  "cover": true},
		{"tex": "prop_hay_bale.png",          "rect": Rect2(1018, 1600, 36, 30),"solid": true,  "cover": true},
	]


static func get_lantern_positions() -> Array[Vector2]:
	return [
		Vector2(218, 988), Vector2(476, 988), Vector2(582, 790), Vector2(742, 748),
		Vector2(920, 756), Vector2(1148, 756), Vector2(936, 1080), Vector2(1170, 1080),
		Vector2(660, 1344), Vector2(906, 1344), Vector2(1278, 760), Vector2(1590, 760),
		Vector2(1372, 480), Vector2(1448, 480),
		Vector2(246, 1260), Vector2(1016, 1880), Vector2(1724, 990),
	]


static func get_octagonal_vertices() -> Array[Vector2]:
	return [
		Vector2(596, 146), Vector2(1504, 146), Vector2(1954, 596), Vector2(1954, 1504),
		Vector2(1504, 1954), Vector2(596, 1954), Vector2(146, 1504), Vector2(146, 596),
	]


static func get_wall_towers() -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.append_array(get_octagonal_vertices())
	out.append_array([
		Vector2(760, 146), Vector2(1340, 146), Vector2(1954, 760), Vector2(1954, 1340),
		Vector2(1340, 1954), Vector2(760, 1954), Vector2(146, 1340), Vector2(146, 760),
	])
	return out


static func get_poorts() -> Array[Dictionary]:
	return [
		{"tex": "prop_louvain_poort_v.png", "rect": Rect2(72, 868, 176, 300)},   # Brusselsepoort (West open road span)
		{"tex": "prop_louvain_poort_h.png", "rect": Rect2(920, 1830, 260, 186)}, # Naamsepoort (South)
		{"tex": "prop_louvain_poort_h.png", "rect": Rect2(920, 10, 260, 186)},   # Mechelsepoort (North)
		{"tex": "prop_louvain_poort_v.png", "rect": Rect2(1852, 868, 176, 300)}, # Tiensepoort (East open road span)
	]


static func get_cardinal_walls() -> Array[Rect2]:
	return [
		Rect2(596, 128, 384, 36), Rect2(1120, 128, 384, 36),
		Rect2(596, 1936, 384, 36), Rect2(1120, 1936, 384, 36),
		Rect2(128, 596, 36, 356), Rect2(128, 1120, 36, 384),
		Rect2(1936, 596, 36, 356), Rect2(1936, 1120, 36, 384),
	]


static func get_diagonal_wall_steps() -> Array[Rect2]:
	var steps: Array[Rect2] = []
	var corners: Array = [
		[Vector2(596, 146), Vector2(146, 596)],
		[Vector2(1504, 146), Vector2(1954, 596)],
		[Vector2(146, 1504), Vector2(596, 1954)],
		[Vector2(1954, 1504), Vector2(1504, 1954)],
	]
	for pair in corners:
		var a: Vector2 = pair[0]
		var b: Vector2 = pair[1]
		for si in range(11):
			var p: Vector2 = a.lerp(b, float(si) / 10.0)
			if p.x >= 452.0 and p.x <= 544.0:
				continue
			steps.append(Rect2(p - Vector2(26, 26), Vector2(52, 52)))
	return steps


static func get_abbey_walls() -> Array[Rect2]:
	return [
		Rect2(1240, 252, 340, 36),     # Full continuous North Cloister Wall behind Cathedral (seals top edge completely)
		Rect2(1240, 288, 36, 484),     # Cloister West Wall + SW corner
		Rect2(1544, 288, 36, 484),     # Cloister East Wall + SE corner
		Rect2(1276, 736, 20, 36),      # South Cloister Spur W (between SW corner & gate)
		Rect2(1380, 736, 164, 36),     # South Cloister Mid/East Wall (embedded Drain Grate at x=1458)
	]


static func get_static_colliders() -> Array[Rect2]:
	var out: Array[Rect2] = [
		Rect2(-24, 0, 24, WORLD_SIZE.y),
		Rect2(WORLD_SIZE.x, 0, 24, WORLD_SIZE.y),
		Rect2(0, -24, WORLD_SIZE.x, 24),
		Rect2(0, WORLD_SIZE.y, WORLD_SIZE.x, 24),
		# Brusselsepoort & Naamsepoort flanking bastion piers (keeping roadway open)
		Rect2(104, 932, 84, 58),
		Rect2(104, 1088, 84, 58),
		Rect2(966, 1924, 36, 60),
		Rect2(1098, 1924, 36, 60),
		# Sealed North Mechelsepoort & East Tiensepoort thresholds
		Rect2(980, 128, 140, 36),
		Rect2(1936, 980, 36, 120),
	]
	out.append_array(get_water_rects())
	out.append_array(get_cardinal_walls())
	out.append_array(get_diagonal_wall_steps())
	out.append_array(get_abbey_walls())
	for b: Dictionary in get_buildings():
		var br: Rect2 = b["rect"]
		out.append(Rect2(br.position.x + 10.0, br.position.y + br.size.y * 0.44, br.size.x - 20.0, br.size.y * 0.54))
	for pr: Dictionary in get_prop_placements():
		if bool(pr.get("solid", false)):
			var r: Rect2 = pr["rect"]
			out.append(Rect2(r.position.x + 4.0, r.position.y + r.size.y * 0.35, maxf(12.0, r.size.x - 8.0), maxf(10.0, r.size.y * 0.62)))
	return out


static func get_sight_blockers() -> Array[Rect2]:
	var sb: Array[Rect2] = []
	for b: Dictionary in get_buildings():
		sb.append(Rect2(b["rect"]))
	for pr: Dictionary in get_prop_placements():
		if bool(pr.get("cover", false)):
			sb.append(Rect2(pr["rect"]))
	sb.append_array(get_abbey_walls())
	return sb


static func get_wanted_posters() -> Array[Dictionary]:
	return [
		{"id": "louvain_p1", "pos": Vector2(424, 956)},    # Inside Brusselsepoort baker corner
		{"id": "louvain_p2", "pos": Vector2(888, 976)},    # Grote Markt west arcade
		{"id": "louvain_p3", "pos": Vector2(1270, 846)},   # Grote Markt east post
		{"id": "louvain_p4", "pos": Vector2(1654, 958)},   # Tiensestraat Watch-House
	]


static func get_ambient_citizens() -> Array[Dictionary]:
	return [
		{"tex": "npc_louvain_student", "pos": Vector2(812, 1416), "pts": [Vector2(686, 1416), Vector2(898, 1416)], "dir": Vector2.LEFT, "wp": 0, "spd": 34.0},
		{"tex": "npc_louvain_weaver",  "pos": Vector2(756, 1388), "pts": [Vector2(756, 1388), Vector2(818, 1450)], "dir": Vector2.RIGHT, "wp": 1, "spd": 26.0},
		{"tex": "npc_city_burgher",    "pos": Vector2(980, 910),  "pts": [Vector2(920, 900), Vector2(1160, 900)],  "dir": Vector2.RIGHT, "wp": 1, "spd": 30.0},
		{"tex": "npc_city_fishwife",   "pos": Vector2(612, 858),  "pts": [Vector2(612, 818), Vector2(612, 948)],   "dir": Vector2.DOWN, "wp": 1, "spd": 28.0},
		{"tex": "npc_city_sailor",     "pos": Vector2(576, 868),  "pts": [Vector2(576, 868)], "dir": Vector2.RIGHT, "wp": 0, "spd": 0.0},
		{"tex": "npc_city_apprentice", "pos": Vector2(1078, 774), "pts": [Vector2(1036, 774), Vector2(1110, 774)], "dir": Vector2.LEFT, "wp": 0, "spd": 24.0},
		{"tex": "npc_louvain_student", "pos": Vector2(1040, 1020),"pts": [Vector2(960, 1030), Vector2(1120, 1030)], "dir": Vector2.RIGHT, "wp": 1, "spd": 32.0},
		{"tex": "npc_city_monk",       "pos": Vector2(880, 768),  "pts": [Vector2(880, 768)], "dir": Vector2.DOWN, "wp": 0, "spd": 0.0},
		{"tex": "npc_city_cooper",     "pos": Vector2(320, 1298), "pts": [Vector2(260, 1298), Vector2(360, 1298)], "dir": Vector2.RIGHT, "wp": 1, "spd": 22.0},
	]


static func get_catchpole_patrols() -> Array[Dictionary]:
	return [
		{"id": "patrol_west", "pos": Vector2(360, 1040), "pts": [Vector2(250, 1040), Vector2(680, 1040)], "dir": Vector2.RIGHT, "wp": 1},
		{"id": "patrol_markt","pos": Vector2(1050, 820), "pts": [Vector2(900, 820), Vector2(1210, 820)], "dir": Vector2.RIGHT, "wp": 1},
		{"id": "patrol_abbey","pos": Vector2(1380, 808), "pts": [Vector2(1310, 808), Vector2(1560, 808)], "dir": Vector2.RIGHT, "wp": 1},
		{"id": "patrol_south","pos": Vector2(1050, 1524),"pts": [Vector2(860, 1524), Vector2(1220, 1524)], "dir": Vector2.RIGHT, "wp": 1},
	]
