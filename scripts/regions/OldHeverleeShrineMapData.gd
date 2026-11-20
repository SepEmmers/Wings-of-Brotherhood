extends RefCounted

## Isolated 3-Chamber Subterranean First Golden Dragon Shrine (1600x960):
##   Room 1 (West, x=112..544):   Devildragon Ritual Relief + Pushable Keystone Boulder -> Weight Plate + Serpent Vent -> Gate 1
##   Room 2 (Mid,  x=564..1076):  Water Chasm ([F] Rope Grapple Posts) + Twin Golden Ember Braziers -> Gate 2
##   Room 3 (East, x=1096..1492): Golden Sanctum Pedestal (Old Heverlee Shrine Key) -> East Escape Stairs to Overlook Camp

const WORLD_SIZE := Vector2(1600, 960)

const ENTRY_SPAWN := Vector2(328, 742)
const EXIT_SOUTH_RECT := Rect2(288, 768, 80, 44)
const BACK_STAIRS_RECT := Rect2(1416, 444, 68, 72)

const RELIEF_POS := Vector2(328, 184)
const BOULDER_START_POS := Vector2(228, 480)
const PLATE_POS := Vector2(396, 480)
const SERPENT_VENT_POS := Vector2(492, 344)
const GATE1_RECT := Rect2(534, 434, 38, 92)

const CHASM_RECT := Rect2(764, 152, 116, 656)
const CHASM_POST_W := Vector2(732, 480)
const CHASM_POST_E := Vector2(912, 480)
const SCONCE_W_POS := Vector2(708, 340)
const SCONCE_E_POS := Vector2(936, 340)
const GATE2_RECT := Rect2(1068, 434, 38, 92)

const PEDESTAL_POS := Vector2(1284, 476)


static func get_room_floors() -> Array[Rect2]:
	return [
		Rect2(112, 152, 422, 656),   # Room 1: Vestibule of the Ritual Relief
		Rect2(572, 152, 496, 656),   # Room 2: Chasm of the Twin Braziers
		Rect2(1106, 152, 386, 656),  # Room 3: Golden Sanctum Vault
		Rect2(534, 434, 38, 92),     # Threshold 1->2
		Rect2(1068, 434, 38, 92),    # Threshold 2->3
	]


static func get_static_colliders(gate1_open: bool, gate2_open: bool) -> Array[Rect2]:
	var out: Array[Rect2] = [
		# Outer chamber boundaries
		Rect2(60, 100, 1480, 52),
		Rect2(60, 808, 1480, 52),
		Rect2(60, 100, 52, 760),
		Rect2(1492, 100, 52, 760),
		# Inner dividing walls around Thresholds 1 (x=534..572) & 2 (x=1068..1106)
		Rect2(534, 152, 38, 282),
		Rect2(534, 526, 38, 282),
		Rect2(1068, 152, 38, 282),
		Rect2(1068, 526, 38, 282),
		# Chasm water gap (passable only via Rope Anchor posts)
		CHASM_RECT,
		# Pedestal & sconces
		Rect2(PEDESTAL_POS - Vector2(18, 14), Vector2(36, 28)),
		Rect2(SCONCE_W_POS - Vector2(12, 10), Vector2(24, 22)),
		Rect2(SCONCE_E_POS - Vector2(12, 10), Vector2(24, 22)),
		Rect2(CHASM_POST_W - Vector2(10, 10), Vector2(20, 20)),
		Rect2(CHASM_POST_E - Vector2(10, 10), Vector2(20, 20)),
	]
	if not gate1_open:
		out.append(GATE1_RECT)
	if not gate2_open:
		out.append(GATE2_RECT)
	return out
