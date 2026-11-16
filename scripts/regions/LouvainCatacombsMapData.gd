extends RefCounted

## Interior 3-Floor Dungeon beneath Louvain's Enclosed Abbey Cathedral:
##   Floor 0 (x:    0..960 ): Quiet Cathedral Nave -> light all 4 altar candles [R] to part High Altar
##   Floor 1 (x:  960..1920): Vaulted Catacombs Crypt -> read Tapestries, push Stag Tomb (traps on wrong graves!)
##   Floor 2 (x: 1920..2880): Hidden Scriptorium Library -> sort by Year (1422 Old Heverlee + 1426 Namur)

const WORLD_SIZE := Vector2(2880, 900)
const CHAMBER_W := 960.0

const NAVE_ENTRY_SPAWN := Vector2(480, 732)
const NAVE_RETURN_STAIRS_SPAWN := Vector2(480, 266)
const CRYPT_ENTRY_SPAWN := Vector2(1440, 712)
const CRYPT_RETURN_LADDER_SPAWN := Vector2(1680, 408)
const LIBRARY_ENTRY_SPAWN := Vector2(2400, 692)

const NAVE_EXIT_RECT := Rect2(444, 772, 72, 34)
const ALTAR_STAIRS_POS := Vector2(480, 206)
const CRYPT_STAIRS_UP_POS := Vector2(1440, 756)
const CRYPT_LADDER_DOWN_POS := Vector2(1680, 344)
const LIBRARY_LADDER_UP_POS := Vector2(2400, 742)

const ALTAR_POS := Vector2(480, 204)
const TAPESTRY_W_POS := Vector2(1076, 594)
const TAPESTRY_N_POS := Vector2(1440, 136)
const INDEX_DESK_POS := Vector2(2400, 594)


static func get_chamber_bounds() -> Array[Rect2]:
	return [
		Rect2(144, 132, 672, 668),    # Floor 0: Cathedral Nave walkable interior
		Rect2(1040, 144, 800, 636),   # Floor 1: Catacombs Crypt walkable interior
		Rect2(2004, 136, 792, 652),   # Floor 2: Hidden Library walkable interior
	]


static func get_nave_candles() -> Array[Vector2]:
	return [
		Vector2(304, 240),
		Vector2(656, 240),
		Vector2(304, 592),
		Vector2(656, 592),
	]


static func get_crypt_torches() -> Array[Vector2]:
	return [
		Vector2(1212, 168),
		Vector2(1668, 168),
		Vector2(1614, 346),
		Vector2(1746, 346),
	]


static func get_nave_pews() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for ry: float in [336.0, 424.0, 512.0, 600.0]:
		out.append(Rect2(216, ry, 144, 42))
		out.append(Rect2(600, ry, 144, 42))
	return out


static func get_crypt_pillars() -> Array[Vector2]:
	return [
		Vector2(1300, 286), Vector2(1580, 286),
		Vector2(1300, 560), Vector2(1580, 560),
	]


static func get_graves_data() -> Array[Dictionary]:
	# 12 Carved Sarcophagi across West, Center & East wings; ONLY "east_stag" hides the Library shaft!
	return [
		# West Wing
		{"id": "w_cross",   "crest": "cross",   "pos": Vector2(1152, 276), "solution": false},
		{"id": "w_crown",   "crest": "crown",   "pos": Vector2(1224, 276), "solution": false},
		{"id": "w_chalice", "crest": "chalice", "pos": Vector2(1152, 434), "solution": false},
		{"id": "w_crown2",  "crest": "crown",   "pos": Vector2(1224, 434), "solution": false},
		# Central Nave Crypt Bay (includes decoy central stag WITHOUT eastern flanking candles!)
		{"id": "c_chalice", "crest": "chalice", "pos": Vector2(1386, 344), "solution": false},
		{"id": "c_stag",    "crest": "stag",    "pos": Vector2(1494, 344), "solution": false},
		{"id": "c_cross",   "crest": "cross",   "pos": Vector2(1386, 516), "solution": false},
		{"id": "c_crown",   "crest": "crown",   "pos": Vector2(1494, 516), "solution": false},
		# East Wing (solution Stag sits flanked by twin tall brass candelabra at (1614, 346) & (1746, 346)!)
		{"id": "e_cross",   "crest": "cross",   "pos": Vector2(1680, 224), "solution": false},
		{"id": "e_stag",    "crest": "stag",    "pos": Vector2(1680, 344), "solution": true},
		{"id": "e_chalice", "crest": "chalice", "pos": Vector2(1680, 488), "solution": false},
		{"id": "e_crown",   "crest": "crown",   "pos": Vector2(1776, 488), "solution": false},
	]


static func get_library_shelves() -> Array[Dictionary]:
	return [
		{"year": "1416", "rect": Rect2(2044, 176, 160, 68), "wing": "West Alcove", "decree": ""},
		{"year": "1419", "rect": Rect2(2044, 360, 160, 68), "wing": "West Aisle",  "decree": ""},
		{"year": "1422", "rect": Rect2(2044, 540, 160, 68), "wing": "West Vault",  "decree": "old_heverlee"},
		{"year": "1425", "rect": Rect2(2320, 176, 160, 68), "wing": "North Choir", "decree": ""},
		{"year": "1426", "rect": Rect2(2596, 360, 160, 68), "wing": "East Vault",  "decree": "namur_clara"},
		{"year": "1428", "rect": Rect2(2596, 176, 160, 68), "wing": "East Alcove", "decree": ""},
		{"year": "1430", "rect": Rect2(2596, 540, 160, 68), "wing": "East Aisle",  "decree": ""},
	]


static func get_library_lecterns() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for sh: Dictionary in get_library_shelves():
		var sr: Rect2 = sh["rect"]
		out.append({
			"year": String(sh["year"]),
			"decree": String(sh["decree"]),
			"pos": Vector2(sr.get_center().x, sr.end.y + 32.0),
		})
	return out


static func get_dart_slits() -> Array[Dictionary]:
	return [
		{"pos": Vector2(1056, 276), "dir": Vector2.RIGHT},
		{"pos": Vector2(1056, 434), "dir": Vector2.RIGHT},
		{"pos": Vector2(1824, 488), "dir": Vector2.LEFT},
	]


static func get_static_colliders(altar_open: bool, grave_states: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	# Thick perimeter walls framing each of the 3 chambers
	for b: Rect2 in get_chamber_bounds():
		out.append(Rect2(b.position.x - 40.0, b.position.y - 40.0, b.size.x + 80.0, 40.0))
		out.append(Rect2(b.position.x - 40.0, b.end.y, b.size.x + 80.0, 40.0))
		out.append(Rect2(b.position.x - 40.0, b.position.y, 40.0, b.size.y))
		out.append(Rect2(b.end.x, b.position.y, 40.0, b.size.y))

	# Floor 0 Nave Props
	for pw: Rect2 in get_nave_pews():
		out.append(Rect2(pw.position.x + 6, pw.position.y + 10, pw.size.x - 12, pw.size.y - 12))
	var altar_x: float = ALTAR_POS.x - (112.0 if altar_open else 48.0)
	out.append(Rect2(altar_x, ALTAR_POS.y - 20.0, 96.0, 42.0))
	for cpos: Vector2 in get_nave_candles():
		out.append(Rect2(cpos - Vector2(12, 10), Vector2(24, 22)))

	# Floor 1 Catacombs Pillars & Sarcophagi (pushed grave shifts -42px north)
	for ppos: Vector2 in get_crypt_pillars():
		out.append(Rect2(ppos - Vector2(16, 12), Vector2(32, 28)))
	for tp: Vector2 in get_crypt_torches():
		out.append(Rect2(tp - Vector2(11, 10), Vector2(22, 20)))
	for g: Dictionary in get_graves_data():
		var gp := Vector2(g["pos"])
		var gid := String(g["id"])
		if bool(grave_states.get(gid, false)):
			gp.y -= 42.0
		out.append(Rect2(gp - Vector2(21, 22), Vector2(42, 44)))

	# Floor 2 Hidden Library Bookshelves, Index Desk & Lecterns
	for sh: Dictionary in get_library_shelves():
		var sr: Rect2 = sh["rect"]
		out.append(Rect2(sr.position.x + 4, sr.position.y + 16, sr.size.x - 8, sr.size.y - 16))
	out.append(Rect2(INDEX_DESK_POS - Vector2(24, 16), Vector2(48, 32)))
	for lc: Dictionary in get_library_lecterns():
		var lp := Vector2(lc["pos"])
		out.append(Rect2(lp - Vector2(16, 12), Vector2(32, 24)))
	return out
