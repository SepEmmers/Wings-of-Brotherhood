extends RefCounted

## Interior 3-Floor Dungeon beneath Louvain's Enclosed Abbey Cathedral:
##   Floor 0 (x:    0..960 ): Quiet Cathedral Nave -> light all 4 altar candles [R] to part High Altar
##   Floor 1 (x:  960..1920): Vaulted Catacombs Crypt -> decode 2 Tapestry riddles across a uniform 4x4 tomb grid
##                            (wrong tombs slide open to reveal live spike-pit traps underneath; 2 secret graves
##                            hide the Library Ladder & Prior's Treasure Reliquary!)
##   Floor 2 (x: 1920..2880): Hidden Scriptorium Library -> sort by Year (1422 Old Heverlee + 1426 Namur)

const WORLD_SIZE := Vector2(2880, 900)
const CHAMBER_W := 960.0

const NAVE_ENTRY_SPAWN := Vector2(480, 732)
const NAVE_RETURN_STAIRS_SPAWN := Vector2(480, 266)
const CRYPT_ENTRY_SPAWN := Vector2(1440, 712)
const CRYPT_RETURN_LADDER_SPAWN := Vector2(1340, 548)
const LIBRARY_ENTRY_SPAWN := Vector2(2400, 692)

const NAVE_EXIT_RECT := Rect2(444, 772, 72, 34)
const ALTAR_STAIRS_POS := Vector2(480, 206)
const CRYPT_STAIRS_UP_POS := Vector2(1440, 756)
const CRYPT_LADDER_DOWN_POS := Vector2(1340, 496)
const CRYPT_TREASURE_POS := Vector2(1740, 496)
const LIBRARY_LADDER_UP_POS := Vector2(2400, 742)

const ALTAR_POS := Vector2(480, 204)
const TAPESTRY_W_POS := Vector2(1048, 568)
const TAPESTRY_N_POS := Vector2(1440, 132)
const INDEX_DESK_POS := Vector2(2400, 594)


static func get_chamber_bounds() -> Array[Rect2]:
	return [
		Rect2(144, 132, 672, 668),    # Floor 0: Cathedral Nave walkable interior
		Rect2(1036, 144, 808, 636),   # Floor 1: Catacombs Crypt walkable interior
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
	# Symmetrical brackets across all bays (zero illumination giveaway on any single grave)
	return [
		Vector2(1240, 168),
		Vector2(1640, 168),
		Vector2(1140, 716),
		Vector2(1440, 566),
		Vector2(1740, 716),
	]


static func get_nave_pews() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for ry: float in [336.0, 424.0, 512.0, 600.0]:
		out.append(Rect2(216, ry, 144, 42))
		out.append(Rect2(600, ry, 144, 42))
	return out


static func get_crypt_pillars() -> Array[Vector2]:
	return [
		Vector2(1240, 286), Vector2(1640, 286),
		Vector2(1240, 566), Vector2(1640, 566),
	]


static func get_graves_data() -> Array[Dictionary]:
	# Uniform 4x4 matrix (Rows 1..4 north->south at y=216,356,496,636; Cols 1..4 at x=1140,1340,1540,1740):
	#   Row 1: cross   | crown   | stag    | chalice
	#   Row 2: stag    | chalice | crown   | cross
	#   Row 3: crown   | STAG*   | cross   | CHALICE*   (* = unique Library [r3c2] & Treasure [r3c4] graves!)
	#   Row 4: chalice | cross   | stag    | crown
	return [
		{"id": "r1c1", "crest": "cross",   "pos": Vector2(1140, 216), "secret": ""},
		{"id": "r1c2", "crest": "crown",   "pos": Vector2(1340, 216), "secret": ""},
		{"id": "r1c3", "crest": "stag",    "pos": Vector2(1540, 216), "secret": ""},
		{"id": "r1c4", "crest": "chalice", "pos": Vector2(1740, 216), "secret": ""},

		{"id": "r2c1", "crest": "stag",    "pos": Vector2(1140, 356), "secret": ""},
		{"id": "r2c2", "crest": "chalice", "pos": Vector2(1340, 356), "secret": ""},
		{"id": "r2c3", "crest": "crown",   "pos": Vector2(1540, 356), "secret": ""},
		{"id": "r2c4", "crest": "cross",   "pos": Vector2(1740, 356), "secret": ""},

		{"id": "r3c1", "crest": "crown",   "pos": Vector2(1140, 496), "secret": ""},
		{"id": "r3c2", "crest": "stag",    "pos": Vector2(1340, 496), "secret": "library"},
		{"id": "r3c3", "crest": "cross",   "pos": Vector2(1540, 496), "secret": ""},
		{"id": "r3c4", "crest": "chalice", "pos": Vector2(1740, 496), "secret": "treasure"},

		{"id": "r4c1", "crest": "chalice", "pos": Vector2(1140, 636), "secret": ""},
		{"id": "r4c2", "crest": "cross",   "pos": Vector2(1340, 636), "secret": ""},
		{"id": "r4c3", "crest": "stag",    "pos": Vector2(1540, 636), "secret": ""},
		{"id": "r4c4", "crest": "crown",   "pos": Vector2(1740, 636), "secret": ""},
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
		{"pos": Vector2(1054, 216), "dir": Vector2.RIGHT},
		{"pos": Vector2(1054, 356), "dir": Vector2.RIGHT},
		{"pos": Vector2(1826, 356), "dir": Vector2.LEFT},
		{"pos": Vector2(1826, 636), "dir": Vector2.LEFT},
	]


static func get_static_colliders(altar_open: bool, grave_states: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for b: Rect2 in get_chamber_bounds():
		out.append(Rect2(b.position.x - 40.0, b.position.y - 40.0, b.size.x + 80.0, 40.0))
		out.append(Rect2(b.position.x - 40.0, b.end.y, b.size.x + 80.0, 40.0))
		out.append(Rect2(b.position.x - 40.0, b.position.y, 40.0, b.size.y))
		out.append(Rect2(b.end.x, b.position.y, 40.0, b.size.y))

	for pw: Rect2 in get_nave_pews():
		out.append(Rect2(pw.position.x + 6, pw.position.y + 10, pw.size.x - 12, pw.size.y - 12))
	var altar_x: float = ALTAR_POS.x - (112.0 if altar_open else 48.0)
	out.append(Rect2(altar_x, ALTAR_POS.y - 20.0, 96.0, 42.0))
	for cpos: Vector2 in get_nave_candles():
		out.append(Rect2(cpos - Vector2(12, 10), Vector2(24, 22)))

	for ppos: Vector2 in get_crypt_pillars():
		out.append(Rect2(ppos - Vector2(16, 12), Vector2(32, 28)))
	for tp: Vector2 in get_crypt_torches():
		out.append(Rect2(tp - Vector2(11, 10), Vector2(22, 20)))
	for g: Dictionary in get_graves_data():
		var gp := Vector2(g["pos"])
		var gid := String(g["id"])
		if bool(grave_states.get(gid, false)):
			gp.y -= 44.0
		out.append(Rect2(gp - Vector2(21, 22), Vector2(42, 44)))

	for sh: Dictionary in get_library_shelves():
		var sr: Rect2 = sh["rect"]
		out.append(Rect2(sr.position.x + 4, sr.position.y + 16, sr.size.x - 8, sr.size.y - 16))
	out.append(Rect2(INDEX_DESK_POS - Vector2(24, 16), Vector2(48, 32)))
	for lc: Dictionary in get_library_lecterns():
		var lp := Vector2(lc["pos"])
		out.append(Rect2(lp - Vector2(16, 12), Vector2(32, 24)))
	return out
