extends RefCounted

## Haunted Old Heverlee Woods & Zoet Water Creek Overland Map (2200x1500):
##   North Trailhead  (1100, 118) <-> Louvain South Naamsepoort
##   NW Ambush Glade  ( 540, 480) : Parents' 9-year-old ambush stump + Inquisitor bolts
##   NE Scout Ridge   (1260, 440) : Church Inquisitor Scout camp guarding cipher table
##   Zoet Water Creek ( y=756..840): West stepping ford (x=500..620) & East Rope Grapple Gap (x=1540)
##   Central-S Ruin   (1140, 1085): Dry bramble barrier -> Golden Dragon Shrine stairs
##   SE Overlook Camp (1820, 1180): Kestrel Courier roost & transition to Captain Anna Chapter 1

const WORLD_SIZE := Vector2(2200, 1500)

const NORTH_ENTRY_SPAWN := Vector2(1100, 128)
const NORTH_PORTAL_RECT := Rect2(1036, 12, 128, 66)

const AMBUSH_STUMP_POS := Vector2(540, 476)
const CIPHER_TABLE_POS := Vector2(1310, 424)
const ROPE_POST_N := Vector2(1540, 722)
const ROPE_POST_S := Vector2(1540, 868)
const BRIAR_POS := Vector2(1140, 1118)
const SHRINE_DOOR_RECT := Rect2(1100, 1044, 80, 56)
const SHRINE_EXIT_SPAWN := Vector2(1140, 1166)
const SHRINE_BACK_SPAWN := Vector2(1690, 1110)

const OVERLOOK_FIRE_POS := Vector2(1820, 1188)
const KESTREL_ROCK_POS := Vector2(1894, 1132)


static func get_water_rects() -> Array[Rect2]:
	return [Rect2(0, 756, 2200, 84)]


static func get_dirt_trails() -> Array[Rect2]:
	return [
		Rect2(1062, 16, 76, 460),    # North trailhead down from Louvain
		Rect2(520, 444, 620, 68),    # West spur to Parents' Ambush Glade
		Rect2(524, 480, 72, 276),    # South approach down to West Stepping Ford
		Rect2(524, 838, 72, 310),    # South ford road curving to Shrine clearings
		Rect2(540, 1094, 640, 72),   # Trail east from ford to Shrine Apron
		Rect2(1140, 396, 440, 68),   # Upper trail east to Inquisitor Scout Ridge & Grapple Gap
		Rect2(1504, 420, 72, 336),   # North bank approach to Rope Grapple Post
		Rect2(1504, 838, 72, 340),   # South bank continuation from Rope Post
		Rect2(1160, 1110, 700, 76),  # Main woodland trail east to Overlook Campfire
	]


static func get_ford_stones() -> Array[Rect2]:
	return [
		Rect2(512, 748, 96, 24),
		Rect2(520, 778, 80, 24),
		Rect2(516, 808, 88, 36),
	]


static func get_tree_positions() -> Array[Dictionary]:
	var raw: Array[Vector2] = [
		Vector2(180, 180), Vector2(340, 160), Vector2(520, 190), Vector2(700, 150), Vector2(880, 180),
		Vector2(1300, 160), Vector2(1500, 175), Vector2(1720, 160), Vector2(1960, 190),
		Vector2(160, 360), Vector2(320, 340), Vector2(740, 320), Vector2(1680, 340), Vector2(1940, 380),
		Vector2(180, 560), Vector2(360, 580), Vector2(780, 560), Vector2(1040, 580), Vector2(1800, 560), Vector2(2020, 580),
		Vector2(180, 940), Vector2(360, 960), Vector2(740, 960), Vector2(940, 940), Vector2(1340, 950), Vector2(1980, 960),
		Vector2(200, 1180), Vector2(440, 1240), Vector2(680, 1280), Vector2(920, 1290), Vector2(1360, 1290), Vector2(1580, 1340), Vector2(2040, 1280),
	]
	var out: Array[Dictionary] = []
	for i in range(raw.size()):
		out.append({"pos": raw[i], "pine": (i % 3 != 0), "flip": (i % 2 == 1)})
	return out


static func get_cover_ferns() -> Array[Vector2]:
	return [
		Vector2(980, 390), Vector2(1140, 480), Vector2(1390, 520), Vector2(1420, 350),
		Vector2(470, 520), Vector2(640, 530), Vector2(1060, 1080), Vector2(1220, 1090),
		Vector2(420, 430), Vector2(650, 415), Vector2(960, 260), Vector2(1220, 270),
		Vector2(700, 660), Vector2(940, 680), Vector2(1380, 670), Vector2(1680, 690),
		Vector2(440, 960), Vector2(660, 980), Vector2(1020, 960), Vector2(1660, 1020),
	]


static func get_static_colliders(briar_burned: bool) -> Array[Rect2]:
	var out: Array[Rect2] = [
		Rect2(-24, 0, 24, WORLD_SIZE.y),
		Rect2(WORLD_SIZE.x, 0, 24, WORLD_SIZE.y),
		Rect2(0, -24, 1020, 48),
		Rect2(1180, -24, 1020, 48),
		Rect2(0, WORLD_SIZE.y, WORLD_SIZE.x, 24),
		# Zoet Water Creek left/middle/right spans leaving ONLY West Stepping Ford (504..616) passable on foot
		Rect2(0, 756, 504, 84),
		Rect2(616, 756, 884, 84),
		Rect2(1500, 756, 700, 84),
		# Key solid landmarks
		Rect2(AMBUSH_STUMP_POS - Vector2(18, 12), Vector2(36, 22)),
		Rect2(CIPHER_TABLE_POS - Vector2(22, 14), Vector2(44, 28)),
		Rect2(ROPE_POST_N - Vector2(10, 10), Vector2(20, 20)),
		Rect2(ROPE_POST_S - Vector2(10, 10), Vector2(20, 20)),
		Rect2(OVERLOOK_FIRE_POS - Vector2(14, 10), Vector2(28, 22)),
		Rect2(SHRINE_DOOR_RECT.position.x - 16, SHRINE_DOOR_RECT.position.y - 12, 24, 48),
		Rect2(SHRINE_DOOR_RECT.end.x - 8, SHRINE_DOOR_RECT.position.y - 12, 24, 48),
	]
	if not briar_burned:
		out.append(Rect2(BRIAR_POS - Vector2(48, 22), Vector2(96, 42)))
	for tr: Dictionary in get_tree_positions():
		var tp := Vector2(tr["pos"])
		out.append(Rect2(tp - Vector2(14, 8), Vector2(28, 20)))
	return out


static func get_scouts() -> Array[Dictionary]:
	return [
		{"id": "hev_shield", "kind": "shield", "pos": Vector2(1240, 470), "dir": Vector2.LEFT, "pts": [Vector2(1180, 470), Vector2(1380, 470)], "wp": 1, "hp": 3, "has_shield": true, "stun": 0.0, "snared_t": 0.0, "timer": 0.7, "alive": true},
		{"id": "hev_archer", "kind": "arbalester", "pos": Vector2(1380, 396), "dir": Vector2.DOWN, "pts": [Vector2(1340, 396), Vector2(1440, 430)], "wp": 0, "hp": 2, "has_shield": false, "stun": 0.0, "snared_t": 0.0, "timer": 0.9, "alive": true},
	]
