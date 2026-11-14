class_name SanctuaryVillageData
extends RefCounted

## Static layout, pathing, fence segments, livestock placements, and colliders
## for the lived-in Brotherhood Cliffside Sanctuary village & covert pastures.


static func get_extra_dirt_trails() -> Array[Rect2]:
	return [
		Rect2(142, 174, 340, 56),   # NW Bunkhouse & Captain Cottage terrace path
		Rect2(552, 470, 126, 210),  # West Market Stalls lane
		Rect2(138, 774, 184, 60),   # SW Tent Camp spur
		Rect2(360, 774, 300, 198),  # SW Mess Commons & Stew Hearth plaza
		Rect2(1010, 198, 72, 260),  # East Cliff Watch Tents ridge path
		Rect2(1212, 294, 180, 96),  # East Dragon Pavilion & Ration Yard
		Rect2(950, 774, 240, 82),   # SE Feed Barn & Stockman yard
		Rect2(1156, 600, 108, 224), # Lane linking East Road to Sheep & Cattle gates
	]


static func get_building_placements() -> Array[Dictionary]:
	return [
		{"tex": "bldg_covert_lodge.png", "rect": Rect2(76, 16, 224, 174), "label": "", "lpos": Vector2(188, 196), "lcol": Color(0.95, 0.88, 0.68)},
		{"tex": "bldg_covert_cottage.png", "rect": Rect2(326, 22, 208, 164), "label": "", "lpos": Vector2(430, 192), "lcol": Color(0.95, 0.88, 0.68)},
		{"tex": "bldg_feed_barn.png", "rect": Rect2(876, 774, 216, 172), "label": "", "lpos": Vector2(984, 954), "lcol": Color(0.94, 0.84, 0.62)},
		{"tex": "prop_dragon_pavilion.png", "rect": Rect2(1216, 176, 188, 128), "label": "", "lpos": Vector2(1310, 166), "lcol": Color(0.76, 0.94, 0.80)},
	]


static func get_tent_and_stall_placements() -> Array[Dictionary]:
	return [
		{"tex": "prop_tent_green.png", "rect": Rect2(76, 806, 124, 104)},
		{"tex": "prop_tent_tan.png", "rect": Rect2(212, 818, 114, 94)},
		{"tex": "prop_tent_green.png", "rect": Rect2(122, 948, 124, 104)},
		{"tex": "prop_tent_green.png", "rect": Rect2(904, 98, 124, 104)},
		{"tex": "prop_tent_tan.png", "rect": Rect2(1038, 110, 114, 94)},
		{"tex": "prop_tent_green.png", "rect": Rect2(1480, 104, 124, 104)},
		{"tex": "prop_stall_gear.png", "rect": Rect2(568, 474, 106, 76), "label": "Rigging Stall", "lpos": Vector2(621, 464)},
		{"tex": "prop_stall_food.png", "rect": Rect2(568, 578, 106, 76), "label": "Victualler Stall", "lpos": Vector2(621, 568)},
		{"tex": "prop_mess_table.png", "rect": Rect2(408, 882, 92, 46)},
		{"tex": "prop_mess_table.png", "rect": Rect2(552, 882, 92, 46)},
		{"tex": "prop_stew_pot.png", "rect": Rect2(474, 802, 34, 34)},
		{"tex": "prop_water_trough.png", "rect": Rect2(216, 362, 44, 28)},
		{"tex": "prop_dragon_feed_rack.png", "rect": Rect2(214, 412, 48, 42)},
		{"tex": "prop_dragon_feed_rack.png", "rect": Rect2(1414, 272, 48, 42)},
		{"tex": "prop_water_trough.png", "rect": Rect2(1324, 344, 44, 28)},
		{"tex": "prop_water_trough.png", "rect": Rect2(1310, 614, 44, 28)},
		{"tex": "prop_water_trough.png", "rect": Rect2(1270, 978, 44, 28)},
		{"tex": "prop_water_trough.png", "rect": Rect2(1088, 1014, 44, 28)},
	]


static func get_hay_positions() -> Array[Vector2]:
	return [
		Vector2(852, 888), Vector2(1108, 888),
		Vector2(1380, 560), Vector2(1590, 565),
		Vector2(1365, 868), Vector2(1575, 920), Vector2(1490, 1012),
	]


static func get_fence_segments() -> Array[Dictionary]:
	var segs: Array[Dictionary] = []
	# Sheep Pasture (x=1260..1696, y=520..700; gate y=584..656 on west side)
	segs.append({"kind": "h", "p1": Vector2(1260, 520), "p2": Vector2(1696, 520)})
	segs.append({"kind": "h", "p1": Vector2(1260, 692), "p2": Vector2(1696, 692)})
	segs.append({"kind": "v", "p1": Vector2(1688, 520), "p2": Vector2(1688, 700)})
	segs.append({"kind": "v", "p1": Vector2(1260, 520), "p2": Vector2(1260, 584)})
	segs.append({"kind": "v", "p1": Vector2(1260, 656), "p2": Vector2(1260, 700)})
	# Brabant Cattle Pasture (x=1230..1696, y=810..1060; gate x=1274..1346 on north side)
	segs.append({"kind": "h", "p1": Vector2(1230, 810), "p2": Vector2(1274, 810)})
	segs.append({"kind": "h", "p1": Vector2(1346, 810), "p2": Vector2(1696, 810)})
	segs.append({"kind": "h", "p1": Vector2(1230, 1052), "p2": Vector2(1696, 1052)})
	segs.append({"kind": "v", "p1": Vector2(1230, 810), "p2": Vector2(1230, 1060)})
	segs.append({"kind": "v", "p1": Vector2(1688, 810), "p2": Vector2(1688, 1060)})
	# Hog Yard (x=925..1160, y=965..1075; gate y=992..1048 on east side)
	segs.append({"kind": "h", "p1": Vector2(925, 965), "p2": Vector2(1160, 965)})
	segs.append({"kind": "h", "p1": Vector2(925, 1067), "p2": Vector2(1160, 1067)})
	segs.append({"kind": "v", "p1": Vector2(925, 965), "p2": Vector2(925, 1075)})
	segs.append({"kind": "v", "p1": Vector2(1152, 965), "p2": Vector2(1152, 992)})
	segs.append({"kind": "v", "p1": Vector2(1152, 1048), "p2": Vector2(1152, 1075)})
	return segs


static func get_livestock_entries() -> Array[Dictionary]:
	return [
		{"kind": "sheep", "pos": Vector2(1425, 598), "size": Vector2(30, 24), "phase": 0.2},
		{"kind": "sheep", "pos": Vector2(1495, 640), "size": Vector2(30, 24), "phase": 1.1},
		{"kind": "sheep", "pos": Vector2(1572, 606), "size": Vector2(30, 24), "phase": 2.4},
		{"kind": "sheep", "pos": Vector2(1624, 650), "size": Vector2(30, 24), "phase": 0.7},
		{"kind": "cow", "pos": Vector2(1420, 916), "size": Vector2(44, 34), "phase": 0.5},
		{"kind": "cow", "pos": Vector2(1542, 974), "size": Vector2(44, 34), "phase": 1.8},
		{"kind": "cow", "pos": Vector2(1610, 886), "size": Vector2(44, 34), "phase": 2.9},
		{"kind": "pig", "pos": Vector2(982, 1022), "size": Vector2(26, 20), "phase": 0.9},
		{"kind": "pig", "pos": Vector2(1034, 1036), "size": Vector2(26, 20), "phase": 2.1},
		{"kind": "pig", "pos": Vector2(1042, 998), "size": Vector2(26, 20), "phase": 3.3},
	]


static func get_village_colliders() -> Array[Rect2]:
	return [
		# Dwellings & Barn
		Rect2(88, 72, 200, 112),
		Rect2(338, 74, 184, 106),
		Rect2(888, 830, 192, 110),
		Rect2(1228, 218, 164, 80),
		# Sleeping Tents & Stalls
		Rect2(86, 836, 104, 68),
		Rect2(222, 846, 94, 60),
		Rect2(132, 978, 104, 68),
		Rect2(914, 128, 104, 68),
		Rect2(1048, 138, 94, 60),
		Rect2(1490, 134, 104, 68),
		Rect2(576, 496, 90, 48),
		Rect2(576, 600, 90, 48),
		# Mess Tables, Stew Kettle & Dragon/Stock Troughs
		Rect2(480, 812, 22, 22),
		Rect2(414, 890, 80, 30),
		Rect2(558, 890, 80, 30),
		Rect2(220, 368, 36, 18),
		Rect2(218, 422, 40, 26),
		Rect2(1418, 282, 40, 26),
		Rect2(1328, 350, 36, 18),
		Rect2(1314, 620, 36, 18),
		Rect2(1274, 984, 36, 18),
		Rect2(1092, 1020, 36, 18),
		# Sheep Pasture Rails
		Rect2(1260, 520, 436, 12),
		Rect2(1260, 692, 436, 12),
		Rect2(1688, 520, 12, 184),
		Rect2(1260, 520, 12, 64),
		Rect2(1260, 656, 12, 48),
		# Cattle Pasture Rails
		Rect2(1230, 810, 44, 12),
		Rect2(1346, 810, 350, 12),
		Rect2(1230, 1052, 466, 12),
		Rect2(1230, 810, 12, 250),
		Rect2(1688, 810, 12, 250),
		# Hog Yard Rails
		Rect2(925, 965, 235, 12),
		Rect2(925, 1067, 235, 12),
		Rect2(925, 965, 12, 112),
		Rect2(1152, 965, 12, 27),
		Rect2(1152, 1048, 12, 31),
	]


static func get_sight_blockers() -> Array[Rect2]:
	var b: Array[Rect2] = [
		Rect2(88, 72, 200, 112), Rect2(338, 74, 184, 106),
		Rect2(888, 830, 192, 110), Rect2(1228, 218, 164, 80),
		Rect2(86, 836, 104, 68), Rect2(222, 846, 94, 60),
		Rect2(132, 978, 104, 68), Rect2(914, 128, 104, 68),
		Rect2(1048, 138, 94, 60), Rect2(1490, 134, 104, 68),
		Rect2(576, 496, 90, 48), Rect2(576, 600, 90, 48),
		Rect2(480, 812, 22, 22), Rect2(414, 890, 80, 30),
		Rect2(558, 890, 80, 30), Rect2(218, 422, 40, 26),
		Rect2(1418, 282, 40, 26),
	]
	for hp: Vector2 in get_hay_positions():
		b.append(Rect2(hp - Vector2(16, 12), Vector2(32, 24)))
	return b
