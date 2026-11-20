class_name BrugesCityMapData
extends RefCounted

## Static layout, canals, outer moat ring, stone bridges, castle fortifications,
## dense medieval Flemish gable blocks, moored barges, colliders, stealth cover zones,
## living townsfolk & patrols, and Priest tailing waypoints for the Walled City of Bruges (2880x2160).

const WORLD_SIZE := Vector2(2880, 2160)
const FOUNTAIN_POS := Vector2(1356, 1244)


static func get_canal_rects() -> Array[Rect2]:
	return [
		# Outer Medieval Moat Ring
		Rect2(0, 0, 2880, 72),     # North Moat
		Rect2(0, 2048, 2880, 112), # South Moat
		Rect2(0, 72, 72, 1976),    # West Moat
		Rect2(2808, 72, 72, 1976), # East Moat
		# Inner Reien Canals
		Rect2(920, 72, 96, 1976),  # Main N-S Kraanrei / Reien Canal
		Rect2(1016, 820, 1792, 96),# E-W Spiegelrei / Dijver Cross-Canal
	]


static func get_bridge_placements() -> Array[Dictionary]:
	return [
		{"tex": "prop_stone_bridge_v.png", "rect": Rect2(1392, 2032, 96, 136), "walk": Rect2(1398, 2032, 84, 136)},  # South Port Gate Moat Bridge
		{"tex": "prop_stone_bridge_h.png", "rect": Rect2(900, 460, 136, 92),  "walk": Rect2(900, 466, 136, 80)},    # North Keep Stone Bridge
		{"tex": "prop_stone_bridge_h.png", "rect": Rect2(900, 1258, 136, 92), "walk": Rect2(900, 1264, 136, 80)},   # West Guildhall Stone Bridge
		{"tex": "prop_stone_bridge_v.png", "rect": Rect2(1620, 800, 96, 136), "walk": Rect2(1626, 800, 84, 136)},   # East Cloister Stone Bridge
		{"tex": "prop_stone_bridge_v.png", "rect": Rect2(2224, 800, 96, 136), "walk": Rect2(2230, 800, 84, 136)},   # Beguinage Garden Stone Bridge
		{"tex": "prop_stone_bridge_h.png", "rect": Rect2(2788, 1258, 100, 92), "walk": Rect2(2788, 1264, 100, 80)},  # East Outskirts Moat Bridge
	]


static func get_winch_pairs() -> Array[Dictionary]:
	return [
		{"west": Vector2(886, 1680), "east": Vector2(1050, 1680)},  # Smuggler Watergate Zip-Crossing
		{"west": Vector2(1380, 788), "east": Vector2(1380, 952)},   # Spiegelrei Zip-Crossing (N/S)
	]


static func get_garden_lawns() -> Array[Rect2]:
	return [
		Rect2(2072, 1120, 608, 640), # Walled Beguinage Herb Lawn (SE)
		Rect2(2432, 176, 240, 200),  # St. Donatian's Cloister Garth (NE)
	]


static func get_plaza_placements() -> Array[Dictionary]:
	return [
		{"rect": Rect2(160, 144, 688, 640),  "style": "flagstone"}, # De Burg Castle & Prinsenhof Bailey (NW)
		{"rect": Rect2(1184, 1040, 544, 368),"style": "cobble"},    # Grote Markt & Belfry Cloth Plaza (Center)
		{"rect": Rect2(1968, 368, 528, 240), "style": "cobble"},    # St. Donatian's Cathedral Forecourt (NE)
		{"rect": Rect2(352, 1200, 528, 640), "style": "quay"},      # West Kraanrei Guildhall & Wharf Quay (W)
		{"rect": Rect2(1296, 1792, 288, 160),"style": "cobble"},    # South Port Gate Apron
	]


static func get_cobble_plazas() -> Array[Rect2]:
	var list: Array[Rect2] = []
	for p: Dictionary in get_plaza_placements():
		list.append(p["rect"])
	return list


static func get_road_network() -> Array[Rect2]:
	return [
		Rect2(1392, 1408, 96, 560),  # Steenstraat: South Port Gate -> Grote Markt
		Rect2(864, 1264, 2016, 80),  # Main E-W Avenue: Kraanrei -> Grote Markt -> Beguinage -> East Outskirts Gate
		Rect2(1624, 480, 88, 576),   # Cloister Boulevard (Grote Markt -> Cloister Bridge -> Church Way)
		Rect2(864, 472, 1120, 80),   # North Church Way (Keep East Gate -> Cathedral Forecourt)
		Rect2(544, 784, 88, 448),    # West Quayside Avenue (Citadel South Gate -> Counting-House)
		Rect2(2224, 560, 96, 576),   # Beguinage Approach N-S
		Rect2(368, 464, 480, 80),    # Inner De Burg Citadel Cross-Walk
		Rect2(1040, 728, 1660, 88),  # Spiegelrei Canal North Quay Promenade
		Rect2(1640, 124, 80, 356),   # North Gate Boulevard
	]


static func get_castle_walls() -> Array[Dictionary]:
	return [
		# Outer City Curtain Walls & Gates
		{"kind": "wall",         "rect": Rect2(112, 1968, 792, 36),  "label": ""},
		{"kind": "watergate",    "rect": Rect2(904, 1958, 128, 56),  "label": ""},
		{"kind": "wall",         "rect": Rect2(1032, 1968, 316, 36), "label": ""},
		{"kind": "gatehouse",    "rect": Rect2(1348, 1948, 184, 76), "label": ""},
		{"kind": "wall",         "rect": Rect2(1532, 1968, 1208, 36),"label": ""},
		{"kind": "wall",         "rect": Rect2(112, 88, 792, 36),    "label": ""},
		{"kind": "watergate",    "rect": Rect2(904, 78, 128, 56),    "label": ""},
		{"kind": "wall",         "rect": Rect2(1032, 88, 568, 36),   "label": ""},
		{"kind": "gatehouse",    "rect": Rect2(1600, 68, 160, 76),   "label": ""},
		{"kind": "wall",         "rect": Rect2(1760, 88, 980, 36),   "label": ""},
		{"kind": "wall",         "rect": Rect2(88, 112, 36, 1120),   "label": ""},
		{"kind": "gatehouse",    "rect": Rect2(72, 1232, 72, 160),   "label": ""},
		{"kind": "wall",         "rect": Rect2(88, 1392, 36, 576),   "label": ""},
		{"kind": "wall",         "rect": Rect2(2740, 112, 36, 692),  "label": ""},
		{"kind": "watergate",    "rect": Rect2(2730, 804, 56, 128),  "label": ""},
		{"kind": "wall",         "rect": Rect2(2740, 932, 36, 326),  "label": ""},
		{"kind": "wall",         "rect": Rect2(2740, 1350, 36, 618), "label": ""},
		# Outer Corner & Flank Bastions
		{"kind": "tower_round",  "rect": Rect2(68, 68, 76, 76),      "label": ""},
		{"kind": "tower_round",  "rect": Rect2(2720, 68, 76, 76),    "label": ""},
		{"kind": "tower_round",  "rect": Rect2(68, 1948, 76, 76),    "label": ""},
		{"kind": "tower_round",  "rect": Rect2(2720, 1948, 76, 76),  "label": ""},
		{"kind": "tower_round",  "rect": Rect2(480, 1952, 68, 68),   "label": ""},
		{"kind": "tower_round",  "rect": Rect2(2144, 1952, 68, 68),  "label": ""},
		{"kind": "tower_square", "rect": Rect2(2452, 72, 68, 68),    "label": ""},

		# Inner Castle Citadel ("De Burg" & Main Keep Bailey, NW)
		{"kind": "wall",         "rect": Rect2(152, 136, 696, 32),   "label": ""},
		{"kind": "wall",         "rect": Rect2(152, 136, 32, 648),   "label": ""},
		{"kind": "wall",         "rect": Rect2(152, 768, 356, 32),   "label": ""},
		{"kind": "gatehouse",    "rect": Rect2(508, 752, 160, 64),   "label": ""},
		{"kind": "wall",         "rect": Rect2(668, 768, 180, 32),   "label": ""},
		{"kind": "wall",         "rect": Rect2(832, 136, 32, 300),   "label": ""},
		{"kind": "gatehouse",    "rect": Rect2(816, 436, 64, 148),   "label": ""},
		{"kind": "wall",         "rect": Rect2(832, 584, 32, 200),   "label": ""},
		{"kind": "tower_round",  "rect": Rect2(132, 116, 72, 72),    "label": ""},
		{"kind": "tower_round",  "rect": Rect2(812, 116, 72, 72),    "label": ""},
		{"kind": "tower_round",  "rect": Rect2(132, 748, 72, 72),    "label": ""},
		{"kind": "tower_round",  "rect": Rect2(812, 748, 72, 72),    "label": ""},
		{"kind": "tower_square", "rect": Rect2(472, 116, 64, 64),    "label": ""},
		{"kind": "tower_square", "rect": Rect2(132, 448, 64, 64),    "label": ""},

		# Walled Beguinage Herb Enclosure (SE)
		{"kind": "wall",         "rect": Rect2(2048, 1088, 144, 24), "label": ""},
		{"kind": "gatehouse",    "rect": Rect2(2192, 1072, 160, 56), "label": ""},
		{"kind": "wall",         "rect": Rect2(2352, 1088, 352, 24), "label": ""},
		{"kind": "wall",         "rect": Rect2(2048, 1088, 24, 688), "label": ""},
		{"kind": "wall",         "rect": Rect2(2680, 1088, 24, 170), "label": ""},
		{"kind": "wall",         "rect": Rect2(2680, 1350, 24, 426), "label": ""},
		{"kind": "wall",         "rect": Rect2(2048, 1752, 656, 24), "label": ""},
	]


static func get_city_buildings() -> Array[Dictionary]:
	return [
		# 1. De Burg Castle Citadel (NW)
		{"tex": "bldg_bruges_keep.png",      "rect": Rect2(196, 152, 304, 260),  "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_manor_7a.png",         "rect": Rect2(506, 192, 274, 194),  "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_garrison_7c.png",      "rect": Rect2(204, 550, 240, 174),  "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4b.png",         "rect": Rect2(648, 572, 164, 136),  "sign": "", "spos": Vector2.ZERO},

		# 2. Grote Markt & Dense Flemish Gable Blocks (Center)
		{"tex": "bldg_bruges_belfry.png",    "rect": Rect2(1292, 918, 304, 296), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_bakery_5a.png",        "rect": Rect2(1076, 1004, 204, 156),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_tavern_6a.png",        "rect": Rect2(1724, 1004, 160, 164),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_weavers_6b.png",       "rect": Rect2(1892, 996, 150, 172), "sign": "", "spos": Vector2.ZERO},
		# Contiguous Flemish Street Rows flanking Steenstraat
		{"tex": "city_house_4a.png",         "rect": Rect2(1040, 1372, 168, 138),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4b.png",         "rect": Rect2(1210, 1372, 168, 138),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4b.png",         "rect": Rect2(1504, 1372, 168, 138),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(1674, 1372, 168, 138),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_manor_7a.png",         "rect": Rect2(1844, 1360, 196, 150),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_cottage_4c.png",       "rect": Rect2(1040, 1560, 168, 134),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(1210, 1560, 168, 138),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(1504, 1560, 168, 138),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_cottage_4c.png",       "rect": Rect2(1674, 1560, 168, 134),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4b.png",         "rect": Rect2(1844, 1560, 176, 140),"sign": "", "spos": Vector2.ZERO},
		# South Port Gate Barbican Keeps & Tavern
		{"tex": "bldg_bruges_keep.png",      "rect": Rect2(1140, 1776, 196, 176),"sign": "", "spos": Vector2.ZERO},
		{"tex": "bldg_bruges_keep.png",      "rect": Rect2(1544, 1776, 196, 176),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_tavern_6a.png",        "rect": Rect2(1780, 1796, 210, 154),"sign": "", "spos": Vector2.ZERO},

		# 3. St. Donatian's Cathedral & North Canon Quarter (NE)
		{"tex": "bldg_bruges_cathedral.png", "rect": Rect2(2074, 128, 364, 340),  "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_manor_7a.png",         "rect": Rect2(1076, 172, 248, 184), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(1332, 196, 168, 138), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4b.png",         "rect": Rect2(1720, 196, 168, 138), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_cottage_4c.png",       "rect": Rect2(1892, 200, 164, 134), "sign": "", "spos": Vector2.ZERO},
		# Spiegelrei North Canal Gable Row
		{"tex": "city_house_4b.png",         "rect": Rect2(1060, 580, 172, 140), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_cottage_4c.png",       "rect": Rect2(1236, 584, 168, 136), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(1408, 580, 168, 140), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4b.png",         "rect": Rect2(1800, 588, 172, 140), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(1976, 588, 172, 140), "sign": "", "spos": Vector2.ZERO},

		# 4. West Kraanrei Guildhall & Ropewalk Wharf (W)
		{"tex": "city_guild_7b.png",         "rect": Rect2(304, 1084, 232, 168), "sign": "", "spos": Vector2.ZERO},
		{"tex": "building_warehouse.png",    "rect": Rect2(160, 908, 248, 168),  "sign": "", "spos": Vector2.ZERO},
		{"tex": "building_ropewalk.png",     "rect": Rect2(176, 1708, 448, 144), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_tavern_6a.png",        "rect": Rect2(176, 1384, 212, 160), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(684, 1084, 176, 144), "sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4b.png",         "rect": Rect2(648, 1692, 176, 144), "sign": "", "spos": Vector2.ZERO},

		# 5. Walled Beguinage Herb Enclosure (SE)
		{"tex": "bldg_beguinage_court.png",  "rect": Rect2(2368, 1140, 240, 198),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_cottage_4c.png",       "rect": Rect2(2104, 1412, 168, 134),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_cottage_4c.png",       "rect": Rect2(2484, 1404, 168, 134),"sign": "", "spos": Vector2.ZERO},
		{"tex": "city_house_4a.png",         "rect": Rect2(2292, 1580, 172, 138),"sign": "", "spos": Vector2.ZERO},
	]


static func get_prop_placements() -> Array[Dictionary]:
	return [
		# Castle Siege Ballistas, Keep & Garrison Arms Racks & Crates
		{"tex": "prop_ballista_wagon.png",   "rect": Rect2(720, 392, 74, 48),   "solid": true, "cover": true},
		{"tex": "prop_ballista_wagon.png",   "rect": Rect2(460, 588, 74, 48),   "solid": true, "cover": true},
		{"tex": "prop_garrison_rack.png",    "rect": Rect2(218, 418, 48, 36),   "solid": true, "cover": false},
		{"tex": "prop_garrison_rack.png",    "rect": Rect2(416, 418, 48, 36),   "solid": true, "cover": false},
		{"tex": "prop_garrison_rack.png",    "rect": Rect2(340, 728, 48, 36),   "solid": true, "cover": false},
		{"tex": "prop_garrison_rack.png",    "rect": Rect2(226, 730, 48, 34),   "solid": true, "cover": false},
		{"tex": "prop_herb_planter.png",     "rect": Rect2(524, 392, 50, 32),   "solid": true, "cover": false},
		{"tex": "prop_crate.png",            "rect": Rect2(448, 656, 36, 36),   "solid": true, "cover": true},
		{"tex": "prop_barrel.png",           "rect": Rect2(488, 656, 34, 34),   "solid": true, "cover": true},
		# Grote Markt Stalls, Bread Oven, Ale Kegs, Cloth Bales & Noticeboard
		{"tex": "prop_brick_bread_oven.png", "rect": Rect2(1022, 1110, 52, 44), "solid": true, "cover": true},
		{"tex": "prop_flour_sack_stack.png", "rect": Rect2(1082, 1162, 34, 28), "solid": true, "cover": false},
		{"tex": "prop_cloth_bales.png",      "rect": Rect2(1562, 1176, 48, 34), "solid": true, "cover": false},
		{"tex": "prop_ale_barrel_rack.png",  "rect": Rect2(1748, 1172, 44, 34), "solid": true, "cover": false},
		{"tex": "prop_tavern_table.png",     "rect": Rect2(1824, 1172, 52, 36), "solid": true, "cover": false},
		{"tex": "prop_cloth_bales.png",      "rect": Rect2(1896, 1170, 48, 36), "solid": true, "cover": false},
		{"tex": "prop_cloth_bales.png",      "rect": Rect2(1990, 1170, 48, 36), "solid": true, "cover": false},
		{"tex": "prop_stall_gear.png",       "rect": Rect2(1224, 1218, 78, 56), "solid": true, "cover": true},
		{"tex": "prop_stall_food.png",       "rect": Rect2(1556, 1218, 78, 56), "solid": true, "cover": true},
		{"tex": "prop_noticeboard.png",      "rect": Rect2(1504, 1178, 44, 52), "solid": true, "cover": false},
		# Street Wagons, Gatehouse Alehouse, Counting-House, Warehouse & Ropewalk Props
		{"tex": "prop_crate.png",            "rect": Rect2(1716, 948, 36, 36),  "solid": true, "cover": true},
		{"tex": "prop_crate.png",            "rect": Rect2(1028, 1220, 36, 36), "solid": true, "cover": true},
		{"tex": "prop_crate.png",            "rect": Rect2(636, 940, 36, 36),   "solid": true, "cover": true},
		{"tex": "prop_iron_chain_wagon.png", "rect": Rect2(544, 1360, 96, 62),  "solid": true, "cover": true},
		{"tex": "prop_ballista_wagon.png",   "rect": Rect2(1512, 1720, 74, 48), "solid": true, "cover": true},
		{"tex": "prop_ballista_wagon.png",   "rect": Rect2(1744, 536, 74, 48),  "solid": true, "cover": true},
		{"tex": "prop_ballista_wagon.png",   "rect": Rect2(1136, 512, 74, 48),  "solid": true, "cover": true},
		{"tex": "prop_iron_chain_wagon.png", "rect": Rect2(1936, 520, 96, 62),  "solid": true, "cover": true},
		{"tex": "prop_ale_barrel_rack.png",  "rect": Rect2(1736, 1906, 44, 34), "solid": true, "cover": false},
		{"tex": "prop_tavern_table.png",     "rect": Rect2(1996, 1904, 52, 36), "solid": true, "cover": false},
		{"tex": "prop_herb_planter.png",     "rect": Rect2(1086, 358, 48, 32),  "solid": true, "cover": false},
		{"tex": "prop_herb_planter.png",     "rect": Rect2(1264, 358, 48, 32),  "solid": true, "cover": false},
		{"tex": "prop_cloth_bales.png",      "rect": Rect2(372, 1254, 48, 34),  "solid": true, "cover": false},
		{"tex": "prop_crate.png",            "rect": Rect2(496, 1254, 36, 36),  "solid": true, "cover": false},
		{"tex": "prop_crate.png",            "rect": Rect2(174, 1076, 36, 36),  "solid": true, "cover": false},
		{"tex": "prop_barrel.png",           "rect": Rect2(214, 1078, 34, 34),  "solid": true, "cover": false},
		{"tex": "prop_barrel.png",           "rect": Rect2(256, 1078, 34, 34),  "solid": true, "cover": false},
		{"tex": "prop_ale_barrel_rack.png",  "rect": Rect2(184, 1546, 44, 34),  "solid": true, "cover": false},
		{"tex": "prop_tavern_table.png",     "rect": Rect2(328, 1546, 52, 36),  "solid": true, "cover": false},
		{"tex": "prop_rope_windlass.png",    "rect": Rect2(212, 1664, 48, 38),  "solid": true, "cover": false},
		{"tex": "prop_rope_windlass.png",    "rect": Rect2(560, 1664, 48, 38),  "solid": true, "cover": false},
		{"tex": "prop_rope_coil.png",        "rect": Rect2(268, 1672, 32, 32),  "solid": true, "cover": false},
		{"tex": "prop_rope_coil.png",        "rect": Rect2(320, 1672, 32, 32),  "solid": true, "cover": false},
		{"tex": "prop_crate.png",            "rect": Rect2(746, 1584, 36, 36),  "solid": true, "cover": true},
		{"tex": "prop_barrel.png",           "rect": Rect2(786, 1584, 34, 34),  "solid": true, "cover": true},
		{"tex": "prop_crate.png",            "rect": Rect2(842, 1408, 36, 36),  "solid": true, "cover": false},
		{"tex": "prop_barrel.png",           "rect": Rect2(842, 1448, 34, 34),  "solid": true, "cover": false},
		{"tex": "prop_hay_bale.png",         "rect": Rect2(1110, 1744, 36, 30), "solid": true, "cover": false},
		{"tex": "prop_hay_bale.png",         "rect": Rect2(1960, 1744, 36, 30), "solid": true, "cover": false},
		# Cathedral Pulpit & Beguinage Herb Planters / Trees
		{"tex": "prop_church_pulpit.png",    "rect": Rect2(2044, 408, 98, 58),  "solid": true, "cover": true},
		{"tex": "prop_drying_herbs.png",     "rect": Rect2(2116, 1300, 56, 44), "solid": true, "cover": true},
		{"tex": "prop_drying_herbs.png",     "rect": Rect2(2396, 1356, 56, 44), "solid": true, "cover": true},
		{"tex": "prop_herb_planter.png",     "rect": Rect2(2312, 1300, 50, 34), "solid": true, "cover": false},
		{"tex": "prop_herb_planter.png",     "rect": Rect2(2548, 1344, 50, 34), "solid": true, "cover": false},
		{"tex": "prop_pine_tree.png",        "rect": Rect2(2112, 1592, 72, 96), "solid": true, "cover": false},
		{"tex": "prop_pine_tree.png",        "rect": Rect2(2568, 1584, 72, 96), "solid": true, "cover": false},
		{"tex": "prop_pine_tree.png",        "rect": Rect2(2512, 224, 72, 96),  "solid": true, "cover": false},
	]


static func get_canal_boats() -> Array[Dictionary]:
	# 74px wide barges inside 96px canals (~11px quay step gap) patrolling cleanly between bridges & watergates.
	return [
		{"rect": Rect2(931, 210, 74, 124),  "horiz": false, "axis_min": 182.0,  "axis_max": 318.0,  "speed": 42.0, "phase": 0.0, "cargo": false},
		{"rect": Rect2(931, 580, 74, 124),  "horiz": false, "axis_min": 566.0,  "axis_max": 680.0,  "speed": 40.0, "phase": 1.1, "cargo": true},
		{"rect": Rect2(931, 1000, 74, 124), "horiz": false, "axis_min": 934.0,  "axis_max": 1118.0, "speed": 48.0, "phase": 2.2, "cargo": true},
		{"rect": Rect2(931, 1480, 74, 124), "horiz": false, "axis_min": 1370.0, "axis_max": 1796.0, "speed": 52.0, "phase": 3.0, "cargo": false},
		{"rect": Rect2(1140, 831, 124, 74), "horiz": true,  "axis_min": 1044.0, "axis_max": 1480.0, "speed": 50.0, "phase": 2.9, "cargo": true},
		{"rect": Rect2(1820, 831, 124, 74), "horiz": true,  "axis_min": 1736.0, "axis_max": 2082.0, "speed": 46.0, "phase": 4.1, "cargo": false},
	]


static func get_chimney_positions() -> Array[Vector2]:
	return [
		Vector2(1196, 1004), Vector2(1044, 1112), Vector2(1748, 1006), Vector2(1892, 1362),
		Vector2(692, 186),   Vector2(304, 1384),  Vector2(2540, 1142),
		Vector2(1240, 174),  Vector2(1590, 582),  Vector2(1916, 1798),
		Vector2(1148, 1374),
	]


static func _compute_canal_colliders() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var bridges: Array[Dictionary] = get_bridge_placements()
	for c: Rect2 in get_canal_rects():
		var horiz: bool = c.size.x > c.size.y
		var intervals: Array[Vector2] = []
		for br: Dictionary in bridges:
			var wr: Rect2 = br["walk"]
			if horiz:
				if wr.position.y < c.end.y and wr.end.y > c.position.y:
					var x0: float = maxf(c.position.x, wr.position.x)
					var x1: float = minf(c.end.x, wr.end.x)
					if x1 > x0:
						intervals.append(Vector2(x0, x1))
			else:
				if wr.position.x < c.end.x and wr.end.x > c.position.x:
					var y0: float = maxf(c.position.y, wr.position.y)
					var y1: float = minf(c.end.y, wr.end.y)
					if y1 > y0:
						intervals.append(Vector2(y0, y1))
		intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var merged: Array[Vector2] = []
		for iv: Vector2 in intervals:
			if merged.is_empty() or iv.x > merged[merged.size() - 1].y:
				merged.append(iv)
			else:
				merged[merged.size() - 1].y = maxf(merged[merged.size() - 1].y, iv.y)
		var cursor: float = c.position.x if horiz else c.position.y
		var end_v: float = c.end.x if horiz else c.end.y
		for iv: Vector2 in merged:
			if iv.x > cursor + 2.0:
				out.append(Rect2(cursor, c.position.y, iv.x - cursor, c.size.y) if horiz else Rect2(c.position.x, cursor, c.size.x, iv.x - cursor))
			cursor = maxf(cursor, iv.y)
		if end_v > cursor + 2.0:
			out.append(Rect2(cursor, c.position.y, end_v - cursor, c.size.y) if horiz else Rect2(c.position.x, cursor, c.size.x, end_v - cursor))
	return out


static func _compute_wall_colliders() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for w: Dictionary in get_castle_walls():
		var kind: String = String(w["kind"])
		if kind == "watergate":
			continue
		var r: Rect2 = w["rect"]
		if kind == "gatehouse":
			if r.size.x >= r.size.y:
				var pier_w: float = maxf(16.0, roundf(r.size.x * 0.28))
				out.append(Rect2(r.position.x, r.position.y, pier_w, r.size.y))
				out.append(Rect2(r.end.x - pier_w, r.position.y, pier_w, r.size.y))
			else:
				var pier_h: float = maxf(16.0, roundf(r.size.y * 0.28))
				out.append(Rect2(r.position.x, r.position.y, r.size.x, pier_h))
				out.append(Rect2(r.position.x, r.end.y - pier_h, r.size.x, pier_h))
		else:
			out.append(r)
	return out


static func get_static_colliders() -> Array[Rect2]:
	var list: Array[Rect2] = [
		Rect2(0, 0, 2880, 48),
		Rect2(0, 2112, 2880, 48),
		Rect2(0, 0, 48, 2160),
		Rect2(2832, 0, 48, 1258),
		Rect2(2832, 1350, 48, 810),
	]
	list.append_array(_compute_canal_colliders())
	list.append_array(_compute_wall_colliders())
	# Solid Market Fountain Basin in Grote Markt
	list.append(Rect2(FOUNTAIN_POS.x - 32.0, FOUNTAIN_POS.y - 24.0, 64.0, 50.0))
	for b: Dictionary in get_city_buildings():
		var r: Rect2 = b["rect"]
		list.append(Rect2(r.position.x + 10.0, r.position.y + r.size.y * 0.34, r.size.x - 20.0, r.size.y * 0.62))
	for p: Dictionary in get_prop_placements():
		if bool(p.get("solid", false)):
			var pr: Rect2 = p["rect"]
			if String(p.get("tex", "")) == "prop_pine_tree.png":
				list.append(Rect2(pr.position.x + 22.0, pr.end.y - 22.0, pr.size.x - 44.0, 18.0))
			else:
				list.append(Rect2(pr.position.x + 4.0, pr.position.y + 10.0, pr.size.x - 8.0, pr.size.y - 12.0))
	return list


static func get_sight_blockers() -> Array[Rect2]:
	var list: Array[Rect2] = []
	list.append_array(_compute_wall_colliders())
	list.append(Rect2(FOUNTAIN_POS.x - 32.0, FOUNTAIN_POS.y - 24.0, 64.0, 50.0))
	for b: Dictionary in get_city_buildings():
		var r: Rect2 = b["rect"]
		list.append(Rect2(r.position.x + 8.0, r.position.y + r.size.y * 0.34, r.size.x - 16.0, r.size.y * 0.58))
	for p: Dictionary in get_prop_placements():
		if not bool(p.get("solid", false)):
			continue
		var t: String = String(p.get("tex", ""))
		if t in ["prop_rope_coil.png", "prop_herb_planter.png", "prop_flour_sack_stack.png"]:
			continue
		var pr: Rect2 = p["rect"]
		if t == "prop_pine_tree.png":
			list.append(Rect2(pr.position.x + 22.0, pr.end.y - 22.0, pr.size.x - 44.0, 18.0))
		else:
			list.append(Rect2(pr.position.x + 4.0, pr.position.y + 10.0, pr.size.x - 8.0, pr.size.y - 14.0))
	return list


static func get_ambient_townsfolk() -> Array[Dictionary]:
	return [
		# 8 Walking Townsfolk & Gate Patrols (keep streets, squares & quays alive)
		{
			"id": "tf_steens_burgher", "tex": "npc_city_burgher", "name": "Master Draper",
			"pos": Vector2(1432, 1460), "speed": 42.0,
			"waypoints": [Vector2(1432, 1460), Vector2(1432, 1740), Vector2(1432, 1460), Vector2(1386, 1292), Vector2(1264, 1292), Vector2(1386, 1292)],
			"bark": "Church riders stopped two wool scows before noon. Cloth-Factor Joris up by Grote Markt Cloth Hall saw their coin-purses up close."
		},
		{
			"id": "tf_market_fishwife", "tex": "npc_city_fishwife", "name": "Goodwife Trude",
			"pos": Vector2(1260, 1302), "speed": 38.0,
			"waypoints": [Vector2(1120, 1302), Vector2(1680, 1302), Vector2(1940, 1302), Vector2(1680, 1302)],
			"bark": "Fresh Zwin plaice, half-salt! Sister Beatrijs in the Beguinage east was brewing sleep-draughts for Church men, and a black wagon rolled west toward the Counting-House Wharf."
		},
		{
			"id": "tf_beguine_walker", "tex": "npc_city_apothecary", "name": "Beguine Sister",
			"pos": Vector2(2264, 1186), "speed": 34.0,
			"waypoints": [Vector2(2264, 1186), Vector2(2146, 1186), Vector2(2146, 1262), Vector2(2252, 1344), Vector2(2338, 1480), Vector2(2252, 1344)],
			"bark": "Quiet footsteps inside the garden close, child. Sister Beatrijs by the Apothecary knows what those hooded riders loaded onto their wagon."
		},
		{
			"id": "tf_cloister_monk", "tex": "npc_city_monk", "name": "Cloister Brother",
			"pos": Vector2(1840, 502), "speed": 36.0,
			"waypoints": [Vector2(1740, 502), Vector2(2040, 502), Vector2(2360, 502), Vector2(2040, 502)],
			"bark": "Cathedral porch stands locked and empty until evening vespers at the eighth hour. Not a priest stirs before dusk falls."
		},
		{
			"id": "tf_wharf_porter", "tex": "npc_city_cooper", "name": "Wharf Porter",
			"pos": Vector2(468, 1300), "speed": 40.0,
			"waypoints": [Vector2(452, 1300), Vector2(740, 1300), Vector2(740, 1530), Vector2(452, 1530)],
			"bark": "Keep wide of that iron-chain wagon parked below the Counting-House! Armed Catchpoles in black cloaks have been hovering round its tailgate all afternoon."
		},
		{
			"id": "tf_citadel_guard", "tex": "npc_city_guard", "name": "Citadel Patrol",
			"pos": Vector2(410, 502), "speed": 46.0,
			"waypoints": [Vector2(380, 502), Vector2(760, 502), Vector2(760, 534), Vector2(380, 534)],
			"bark": "Move along, boy—princely business inside the bailey. Only clergy and Inquisitor's escorts stay past curfew."
		},
		{
			"id": "tf_south_gate_guard", "tex": "npc_city_guard", "name": "South Gate Watch",
			"pos": Vector2(1372, 1892), "speed": 38.0,
			"waypoints": [Vector2(1348, 1892), Vector2(1532, 1892)],
			"bark": "Portcullis drops at third dusk horn! Keep your business inside Steenstraat or clear the moat bridge now."
		},
		{
			"id": "tf_spiegelrei_weaver", "tex": "npc_city_apprentice", "name": "Loom Apprentice",
			"pos": Vector2(1380, 764), "speed": 44.0,
			"waypoints": [Vector2(1180, 764), Vector2(1666, 764), Vector2(1940, 764), Vector2(1666, 764)],
			"bark": "My master says the bishop's clerk bought out every bolt of heavy canvas along the Spiegelrei!"
		},
		# 10 Stationed Living Townsfolk & Guards
		{"id": "tf_gate_left",     "tex": "npc_city_guard",      "pos": Vector2(1368, 1938), "name": "Gate Pikeman",    "bark": "Keep hands visible past the South Barbican, lad."},
		{"id": "tf_citadel_south", "tex": "npc_city_guard",      "pos": Vector2(548, 738),   "name": "Bailiff Guard",   "bark": "No rabble loitering under the Citadel South Gate!"},
		{"id": "tf_baker_wife",    "tex": "npc_city_fishwife",   "pos": Vector2(1248, 1188), "name": "Baker's Wife",    "bark": "Last rye batch just cooled—if those hooded priests leave us a copper worth of flour."},
		{"id": "tf_cloth_boy",     "tex": "npc_city_apprentice", "pos": Vector2(1666, 1218), "name": "Cloth Runner",    "bark": "Factor Joris has been swearing over Church cloth orders since noon—says Sister Beatrijs in the Beguinage knows where the riders hauled it!"},
		{"id": "tf_cooper_quay",   "tex": "npc_city_cooper",     "pos": Vector2(780, 1656),  "name": "Barrelmaker",     "bark": "Tarred casks for brine and tallow—don't touch that iron-chain church wagon by the Counting-House unless you want Catchpoles on your back."},
		{"id": "tf_sailor_barge",  "tex": "npc_city_sailor",     "pos": Vector2(884, 1204),  "name": "Barge Skipper",   "bark": "Watergate chains rattle all evening. Something heavy is sitting on that wagon below the Counting-House."},
		{"id": "tf_tavern_patron", "tex": "npc_city_burgher",    "pos": Vector2(1850, 1236), "name": "Swan Patron",     "bark": "Swan's tap is cold but tongues are hotter—ask Factor Joris or the Beguine sisters what Church carts rolled across Guildhall Bridge."},
		{"id": "tf_cathedral_novice","tex": "npc_city_monk",     "pos": Vector2(2360, 444),  "name": "Novice Clerk",    "bark": "St. Donatian's steps stand empty till the eighth evening bell—none of the priests cross the courtyard before curfew."},
		{"id": "tf_ropewalk_hand", "tex": "npc_city_sailor",     "pos": Vector2(506, 1662),  "name": "Ropewalk Braider", "bark": "Clara used to whip better bowlines than half the masters here... pray she's safe."},
		{"id": "tf_beguine_herb",  "tex": "npc_city_apothecary", "pos": Vector2(2486, 1372), "name": "Herb Gatherer",   "bark": "Valerian and poppy-sap gone before supper—Sister Beatrijs looks grim as winter."},
	]


static func get_priest_route() -> Array[Vector2]:
	return [
		Vector2(2240, 492),  # Start outside St. Donatian's Church
		Vector2(1880, 492),  # Walk west along North Church Way
		Vector2(1668, 504),  # Pause at Cloister Boulevard junction
		Vector2(1668, 864),  # Cross East Cloister Stone Bridge south
		Vector2(1668, 1308), # Enter Grote Markt East Arcade
		Vector2(1392, 1308), # Cross Grote Markt below Cloth Hall
		Vector2(1136, 1308), # Head west to Guildhall Stone Bridge
		Vector2(968, 1304),  # Cross West Guildhall Stone Bridge
		Vector2(704, 1304),  # Turn onto West Kraanrei Quay
		Vector2(588, 1304),  # Reach West Quayside Avenue junction
		Vector2(588, 1160),  # Skirt Counting-House east avenue north
		Vector2(588, 784),   # Pass through CITADEL SOUTH GATE archway
		Vector2(588, 504),   # Cross De Burg Castle Bailey
		Vector2(534, 504),   # Rendezvous with Church Inquisitor
	]
