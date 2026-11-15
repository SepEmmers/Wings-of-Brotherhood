class_name LouvainCityMapData
extends RefCounted

## Layout geometry, Dijle River & stone bridges, Abbey cloister walls,
## Bell-Foundry / Dyers' Quarter / Hunters' Tavern blocks, Catchpole patrols,
## Wanted Posters, and colliders for Book II Act I Hub 1: Louvain (2400x1800).

const WORLD_SIZE := Vector2(2400, 1800)
const DIJLE_WATER_RECT := Rect2(1380, 0, 92, 1800)
const NORTH_BRIDGE_RECT := Rect2(1366, 520, 120, 96)
const CENTER_BRIDGE_RECT := Rect2(1366, 980, 120, 96)

const ABBEY_GATE_RECT := Rect2(1800, 696, 88, 36)
const ABBEY_VENT_POS := Vector2(2044, 714)
const ARCHIVE_DESK_POS := Vector2(1884, 512)
const SOUTH_GATE_BARRICADE_RECT := Rect2(1136, 1696, 128, 36)

const FOUNTAIN_POS := Vector2(1012, 916)
const CLAY_BANK_POS := Vector2(1348, 1280)
const BELL_MOULD_POS := Vector2(494, 412)
const FOUNDRY_WINCH_POS := Vector2(560, 422)
const HERBALIST_SLUICE_POS := Vector2(1596, 1180)
const CONFISCATED_CHEST_POS := Vector2(1940, 1368)
const SOUTH_SIGN_POS := Vector2(1096, 1660)


static func get_water_rects() -> Array[Rect2]:
	return [DIJLE_WATER_RECT]


static func get_bridges() -> Array[Dictionary]:
	return [
		{"tex": "prop_stone_bridge_h.png", "rect": NORTH_BRIDGE_RECT},
		{"tex": "prop_stone_bridge_h.png", "rect": CENTER_BRIDGE_RECT},
	]


static func get_roads() -> Array[Rect2]:
	return [
		Rect2(0, 832, 1380, 96),       # West Gate -> Grote Markt
		Rect2(950, 480, 96, 1260),     # North-South Markt Axis -> South Old Heverlee Gate
		Rect2(950, 528, 430, 84),      # North Abbey Bridge Approach
		Rect2(1472, 528, 300, 84),     # East of North Bridge toward Abbey Front
		Rect2(1796, 528, 96, 480),     # Abbey Gatehouse Approach Street
		Rect2(1472, 988, 720, 84),     # Dyers' Quarter Avenue
		Rect2(340, 420, 96, 480),      # Foundry Plaza Lane
		Rect2(340, 880, 96, 480),      # Hunters' Tavern Street
		Rect2(340, 1272, 690, 84),     # Tavern -> Markt Cross-Street
		Rect2(1020, 1248, 360, 80),    # Dijle River Clay Slip
		Rect2(1800, 1072, 92, 340),    # Herbalist Back Alley
	]


static func get_plazas() -> Array[Dictionary]:
	return [
		{"rect": Rect2(860, 780, 320, 260), "style": "cobble"},   # Grote Markt
		{"rect": Rect2(204, 348, 440, 196), "style": "cobble"},   # Bell-Foundry Yard
		{"rect": Rect2(204, 1220, 420, 200), "style": "cobble"},  # Hunters' Tavern Court
		{"rect": Rect2(1612, 1100, 460, 230), "style": "cobble"}, # Dyers' Quarter Yard
		{"rect": Rect2(1628, 444, 520, 252), "style": "flagstone"}, # Abbey Scriptorium Cloister
	]


static func get_garden_lawns() -> Array[Rect2]:
	return [
		Rect2(1640, 1360, 460, 220),
		Rect2(180, 580, 220, 180),
	]


static func get_buildings() -> Array[Dictionary]:
	return [
		# NW Bell-Foundry Quarter
		{"tex": "city_garrison_7c.png", "rect": Rect2(224, 180, 220, 160)},
		{"tex": "city_house_4a.png", "rect": Rect2(474, 192, 168, 136)},
		{"tex": "city_house_4b.png", "rect": Rect2(662, 192, 168, 136)},
		# SW Childhood Parish & Old Hunters' Tavern
		{"tex": "city_tavern_6a.png", "rect": Rect2(216, 1034, 212, 164)},
		{"tex": "city_cottage_4c.png", "rect": Rect2(456, 1054, 164, 134)},
		{"tex": "city_house_4a.png", "rect": Rect2(224, 1432, 176, 140)},
		{"tex": "city_house_4b.png", "rect": Rect2(420, 1432, 176, 140)},
		# Center Grote Markt & Dijle Quayside
		{"tex": "city_guild_7b.png", "rect": Rect2(812, 228, 228, 168)},
		{"tex": "city_bakery_5a.png", "rect": Rect2(1078, 240, 196, 152)},
		{"tex": "city_manor_7a.png", "rect": Rect2(700, 614, 196, 146)},
		{"tex": "city_house_4b.png", "rect": Rect2(692, 1044, 172, 136)},
		{"tex": "city_cottage_4c.png", "rect": Rect2(1126, 668, 168, 134)},
		# NE Abbey Scriptorium Cloister
		{"tex": "bldg_bruges_cathedral.png", "rect": Rect2(1748, 194, 272, 238)},
		{"tex": "bldg_beguinage_court.png", "rect": Rect2(1510, 214, 214, 178)},
		# SE Dyers' Quarter & Herbalist
		{"tex": "city_weavers_6b.png", "rect": Rect2(1612, 816, 170, 158)},
		{"tex": "bldg_covert_lodge.png", "rect": Rect2(1960, 824, 196, 154)},
		{"tex": "city_cottage_4c.png", "rect": Rect2(2044, 1140, 170, 136)},
	]


static func get_abbey_walls() -> Array[Rect2]:
	return [
		Rect2(1572, 696, 228, 36),  # South-West Cloister Wall
		Rect2(1888, 696, 128, 36),  # South-East Cloister Wall (leaves vent gap right of 2016)
		Rect2(2072, 696, 128, 36),  # Far East Cloister Spur
		Rect2(1572, 412, 32, 320),  # West Cloister Wall
		Rect2(2168, 212, 32, 520),  # East Cloister Wall
	]


static func get_outer_walls() -> Array[Dictionary]:
	return [
		# North Wall
		{"kind": "wall", "rect": Rect2(64, 68, 2272, 36)},
		# South Wall (with South Old Heverlee Gatehouse opening x=1136..1264)
		{"kind": "wall", "rect": Rect2(64, 1696, 1072, 36)},
		{"kind": "gatehouse", "rect": Rect2(1110, 1678, 180, 74)},
		{"kind": "wall", "rect": Rect2(1264, 1696, 1072, 36)},
		# West Wall (with West Brabant Gatehouse opening y=816..944)
		{"kind": "wall", "rect": Rect2(64, 96, 36, 720)},
		{"kind": "gatehouse", "rect": Rect2(46, 800, 72, 160)},
		{"kind": "wall", "rect": Rect2(64, 944, 36, 788)},
		# East Wall
		{"kind": "wall", "rect": Rect2(2300, 96, 36, 1636)},
	]


static func get_static_colliders() -> Array[Rect2]:
	var out: Array[Rect2] = [
		Rect2(-24, 0, 24, WORLD_SIZE.y),
		Rect2(WORLD_SIZE.x, 0, 24, WORLD_SIZE.y),
		# Split Dijle water into segments leaving North (520..616) and Center (980..1076) Bridges passable
		Rect2(1380, 0, 92, 520),
		Rect2(1380, 616, 92, 364),
		Rect2(1380, 1076, 92, 724),
	]
	for w in get_outer_walls():
		if String(w["kind"]) == "wall":
			out.append(Rect2(w["rect"]))
	for aw: Rect2 in get_abbey_walls():
		out.append(aw)
	for b in get_buildings():
		var br: Rect2 = b["rect"]
		out.append(Rect2(br.position.x + 10.0, br.position.y + br.size.y * 0.42, br.size.x - 20.0, br.size.y * 0.56))
	return out


static func get_sight_blockers() -> Array[Rect2]:
	var sb: Array[Rect2] = []
	for b in get_buildings():
		sb.append(Rect2(b["rect"]))
	for aw: Rect2 in get_abbey_walls():
		sb.append(aw)
	return sb


static func get_wanted_posters() -> Array[Dictionary]:
	return [
		{"id": "louvain_p1", "pos": Vector2(442, 796)},
		{"id": "louvain_p2", "pos": Vector2(902, 760)},
		{"id": "louvain_p3", "pos": Vector2(1294, 496)},
		{"id": "louvain_p4", "pos": Vector2(1612, 966)},
	]


static func get_catchpole_patrols() -> Array[Dictionary]:
	return [
		{
			"id": "patrol_west",
			"pos": Vector2(560, 880),
			"pts": [Vector2(420, 880), Vector2(880, 880)],
			"dir": Vector2.RIGHT,
			"wp": 1,
		},
		{
			"id": "patrol_markt",
			"pos": Vector2(996, 620),
			"pts": [Vector2(996, 560), Vector2(996, 1220)],
			"dir": Vector2.DOWN,
			"wp": 1,
		},
		{
			"id": "patrol_bridge",
			"pos": Vector2(1300, 568),
			"pts": [Vector2(1120, 568), Vector2(1540, 568)],
			"dir": Vector2.RIGHT,
			"wp": 1,
		},
		{
			"id": "patrol_abbey_gate",
			"pos": Vector2(1844, 780),
			"pts": [Vector2(1660, 780), Vector2(1980, 780)],
			"dir": Vector2.RIGHT,
			"wp": 1,
		},
		{
			"id": "patrol_dyers",
			"pos": Vector2(1740, 1028),
			"pts": [Vector2(1540, 1028), Vector2(2040, 1028)],
			"dir": Vector2.RIGHT,
			"wp": 1,
		},
	]
