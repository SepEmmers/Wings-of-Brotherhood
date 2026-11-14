class_name FrontierWildsMapData
extends RefCounted

## Organic woodland clearings, curved trails, winding rivers, circular pine/boulder colliders,
## atmospheric particle seeds, lantern lighting, and hunter patrols for FrontierWildsRegion.


static func setup_world(r) -> void:
	_define_organic_geography(r)
	_populate_organic_woodland(r)
	_build_collisions(r)
	_build_lights(r)
	_init_atmosphere_pools(r)
	_setup_hunter_patrols(r)


static func _define_organic_geography(r) -> void:
	var clearings: Array[Dictionary] = [
		{"id": "crash", "pos": r.SPAWN_CRASH, "r": 148.0, "title": "Crash Ravine", "surface": "needle"},
		{"id": "hemlock", "pos": r.CLUE_TRACKS_POS, "r": 136.0, "title": "Fallen Hemlock Glade", "surface": "needle"},
		{"id": "cart", "pos": r.CLUE_CART_POS, "r": 124.0, "title": "Shattered Ballista Cart", "surface": "needle"},
		{"id": "fire0", "pos": r.FIRE_0_POS, "r": 124.0, "title": "Scout Ash-Fire", "surface": "ash"},
		{"id": "gorge_e", "pos": Vector2(675, 845), "r": 115.0, "title": "East Gorge Bluff", "surface": "moss"},
		{"id": "gorge_w", "pos": Vector2(335, 805), "r": 118.0, "title": "West Gorge Bank", "surface": "moss"},
		{"id": "hollow", "pos": Vector2(265, 300), "r": 188.0, "title": "Obsidian Hollow", "surface": "hollow"},
		{"id": "arch", "pos": Vector2(760, 275), "r": 116.0, "title": "Moss Arch Trail", "surface": "needle"},
		{"id": "cairn1", "pos": r.CAIRN_1_POS, "r": 134.0, "title": "Roman Cairn I", "surface": "moss"},
		{"id": "frost_dead", "pos": r.FROST_DEAD_POS, "r": 128.0, "title": "Frost Gorge (Dead End)", "surface": "frost"},
		{"id": "fire1", "pos": r.FIRE_ALPHA_POS, "r": 144.0, "title": "Split-Oak & Fire Alpha", "surface": "needle"},
		{"id": "boulder", "pos": r.BOULDER_2HORN_POS, "r": 136.0, "title": "Two-Horn Boulder", "surface": "moss"},
		{"id": "patrol1", "pos": Vector2(1195, 1365), "r": 124.0, "title": "Hemlock Patrol Bend", "surface": "needle"},
		{"id": "cart_fork", "pos": r.CART_FORK_POS, "r": 134.0, "title": "Old Cart Fork", "surface": "needle"},
		{"id": "cold_south", "pos": Vector2(2040, 1845), "r": 122.0, "title": "Mist Brook (Dead End)", "surface": "frost"},
		{"id": "fire2", "pos": r.FIRE_BETA_POS, "r": 144.0, "title": "Cairn II & Fire Beta", "surface": "needle"},
		{"id": "cold_east", "pos": Vector2(2565, 1790), "r": 120.0, "title": "Briar Crag (Dead End)", "surface": "frost"},
		{"id": "creek_winch", "pos": Vector2(2155, 700), "r": 122.0, "title": "Misty Ravine Creek", "surface": "moss"},
		{"id": "causeway", "pos": Vector2(2165, 315), "r": 134.0, "title": "Watchtower Causeway Ridge", "surface": "moss"},
		{"id": "watchtower", "pos": r.OUTPOST_POS, "r": 168.0, "title": "Brotherhood Watchtower", "surface": "cobble"}
	]
	r.clearings.assign(clearings)

	# Curved winding trails (a -> b deflected through ctrl midpoint, width_half)
	var trails: Array[Dictionary] = [
		{"a": r.SPAWN_CRASH, "ctrl": Vector2(215, 1650), "b": r.CLUE_TRACKS_POS, "hw": 62.0},
		{"a": r.CLUE_TRACKS_POS, "ctrl": Vector2(560, 1345), "b": r.CLUE_CART_POS, "hw": 58.0},
		{"a": r.CLUE_CART_POS, "ctrl": Vector2(810, 1560), "b": r.FIRE_0_POS, "hw": 58.0},
		{"a": r.CLUE_CART_POS, "ctrl": Vector2(745, 1070), "b": Vector2(675, 845), "hw": 60.0},
		{"a": Vector2(335, 805), "ctrl": Vector2(290, 560), "b": Vector2(265, 300), "hw": 64.0},
		{"a": Vector2(265, 300), "ctrl": Vector2(530, 312), "b": Vector2(760, 275), "hw": 62.0},
		{"a": Vector2(760, 275), "ctrl": Vector2(935, 255), "b": r.CAIRN_1_POS, "hw": 62.0},
		{"a": r.CAIRN_1_POS, "ctrl": Vector2(1380, 295), "b": r.FROST_DEAD_POS, "hw": 56.0},
		{"a": r.CAIRN_1_POS, "ctrl": Vector2(1145, 580), "b": r.FIRE_ALPHA_POS, "hw": 62.0},
		{"a": r.FIRE_ALPHA_POS, "ctrl": Vector2(1465, 825), "b": r.BOULDER_2HORN_POS, "hw": 58.0},
		{"a": r.FIRE_ALPHA_POS, "ctrl": Vector2(1145, 1110), "b": Vector2(1195, 1365), "hw": 60.0},
		{"a": Vector2(1195, 1365), "ctrl": Vector2(1430, 1445), "b": r.CART_FORK_POS, "hw": 62.0},
		{"a": r.BOULDER_2HORN_POS, "ctrl": Vector2(1755, 1135), "b": r.CART_FORK_POS, "hw": 58.0},
		{"a": r.CART_FORK_POS, "ctrl": Vector2(1875, 1630), "b": Vector2(2040, 1845), "hw": 56.0},
		{"a": r.CART_FORK_POS, "ctrl": Vector2(1895, 1320), "b": r.FIRE_BETA_POS, "hw": 62.0},
		{"a": r.FIRE_BETA_POS, "ctrl": Vector2(2360, 1580), "b": Vector2(2565, 1790), "hw": 56.0},
		{"a": r.FIRE_BETA_POS, "ctrl": Vector2(2200, 1005), "b": Vector2(2155, 700), "hw": 60.0},
		{"a": Vector2(2165, 315), "ctrl": Vector2(2415, 235), "b": r.OUTPOST_POS, "hw": 66.0}
	]
	r.trails.assign(trails)

	# Build dense polyline sample arrays + bounding boxes for fast distance queries & smooth drawing
	r.trail_polylines.clear()
	for tr: Dictionary in r.trails:
		var pts := PackedVector2Array()
		var a: Vector2 = tr["a"]
		var ctrl: Vector2 = tr["ctrl"]
		var b: Vector2 = tr["b"]
		var min_p := a
		var max_p := a
		for si in range(17):
			var t: float = float(si) / 16.0
			var omt: float = 1.0 - t
			var pt: Vector2 = (omt * omt) * a + (2.0 * omt * t) * ctrl + (t * t) * b
			pts.append(pt)
			min_p.x = minf(min_p.x, pt.x)
			min_p.y = minf(min_p.y, pt.y)
			max_p.x = maxf(max_p.x, pt.x)
			max_p.y = maxf(max_p.y, pt.y)
		var hw := float(tr["hw"])
		var pad_v := Vector2(hw + 32.0, hw + 32.0)
		var bbox := Rect2(min_p - pad_v, (max_p - min_p) + pad_v * 2.0)
		r.trail_polylines.append({"pts": pts, "hw": hw, "bbox": bbox})

	# Continuous edge-to-edge meandering river splines (centered straight under Stone & Timber bridge arches!)
	var gorge_ctrl := PackedVector2Array([
		Vector2(545, -80), Vector2(525, 110), Vector2(532, 268), Vector2(532, 310),
		Vector2(528, 378), Vector2(494, 492), Vector2(502, 665), Vector2(510, 825),
		Vector2(492, 995), Vector2(520, 1165), Vector2(545, 1345),
		Vector2(538, 1418), Vector2(515, 1560), Vector2(475, 1790), Vector2(490, 1995),
		Vector2(510, 2240)
	])
	var creek_ctrl := PackedVector2Array([
		Vector2(1870, -80), Vector2(1855, 135), Vector2(1832, 345),
		Vector2(1885, 512), Vector2(2020, 504), Vector2(2155, 532),
		Vector2(2385, 502), Vector2(2620, 558), Vector2(2960, 530)
	])
	r.gorge_river_pts = _smooth_spline(gorge_ctrl, 4)
	r.creek_river_pts = _smooth_spline(creek_ctrl, 4)

	# Continuous Granite Escarpment Cliff Spine locking the Eastern Maze unless Obsidian Hollow Gate opens
	r.ridge_pts = PackedVector2Array([
		Vector2(500, 495), Vector2(770, 500), Vector2(1015, 480),
		Vector2(1018, 860), Vector2(1022, 1290), Vector2(1008, 1740),
		Vector2(1012, 2240)
	])

	var cold_arr: Array[Rect2] = [
		Rect2(1380, 75, 470, 340),
		Rect2(1840, 1595, 460, 490),
		Rect2(2360, 1545, 490, 540)
	]
	r.cold_zones.assign(cold_arr)

	var lm_arr: Array[Dictionary] = []
	for cl: Dictionary in r.clearings:
		lm_arr.append({"id": cl["id"], "pos": cl["pos"], "title": cl["title"]})
	r.landmarks.assign(lm_arr)


static func _point_walkable_clearance(r, pos: Vector2) -> float:
	var best_inside := -9999.0
	for cl: Dictionary in r.clearings:
		var cpos: Vector2 = cl["pos"]
		var rad := float(cl["r"])
		if absf(pos.x - cpos.x) > rad + 32.0 or absf(pos.y - cpos.y) > rad + 32.0:
			continue
		var margin: float = rad - pos.distance_to(cpos)
		if margin > best_inside:
			best_inside = margin
	for tp: Dictionary in r.trail_polylines:
		var bbox: Rect2 = tp.get("bbox", Rect2())
		if bbox.size.x > 0.0 and not bbox.has_point(pos):
			continue
		var pts: PackedVector2Array = tp["pts"]
		var hw: float = float(tp["hw"])
		var reach := hw + 32.0
		for i in range(pts.size() - 1):
			var p0 := pts[i]
			var p1 := pts[i + 1]
			if pos.x < minf(p0.x, p1.x) - reach or pos.x > maxf(p0.x, p1.x) + reach or pos.y < minf(p0.y, p1.y) - reach or pos.y > maxf(p0.y, p1.y) + reach:
				continue
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(pos, p0, p1)
			var margin: float = hw - pos.distance_to(closest)
			if margin > best_inside:
				best_inside = margin
	return best_inside


static func _smooth_spline(ctrl: PackedVector2Array, steps: int = 4) -> PackedVector2Array:
	var out := PackedVector2Array()
	if ctrl.size() < 2:
		return ctrl
	for i in range(ctrl.size() - 1):
		var p1: Vector2 = ctrl[i]
		var p2: Vector2 = ctrl[i + 1]
		var p0: Vector2 = (2.0 * ctrl[0] - ctrl[1]) if i == 0 else ctrl[i - 1]
		var p3: Vector2 = (2.0 * ctrl[ctrl.size() - 1] - ctrl[ctrl.size() - 2]) if (i + 2 >= ctrl.size()) else ctrl[i + 2]
		for s in range(steps):
			var t := float(s) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			var pt := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			out.append(pt)
	out.append(ctrl[ctrl.size() - 1])
	return out


static func _near_polyline(pts: PackedVector2Array, pos: Vector2, min_dist: float) -> bool:
	for i in range(pts.size() - 1):
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(pos, pts[i], pts[i + 1])
		if pos.distance_to(cp) < min_dist:
			return true
	return false


static func _near_river(r, pos: Vector2, min_dist: float) -> bool:
	return _near_polyline(r.gorge_river_pts, pos, min_dist) or _near_polyline(r.creek_river_pts, pos, min_dist)


static func _populate_organic_woodland(r) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 134709

	r.forest_trees.clear()
	r.forest_rocks.clear()
	r.forest_logs.clear()
	r.forest_ferns.clear()
	r.moss_patches.clear()
	r.ridge_rocks.clear()

	# Layered granite boulders framing the continuous escarpment cliff spine
	for i in range(r.ridge_pts.size() - 1):
		var ra: Vector2 = r.ridge_pts[i]
		var rb: Vector2 = r.ridge_pts[i + 1]
		var seg_len := ra.distance_to(rb)
		var count := maxi(1, int(ceilf(seg_len / 42.0)))
		for k in range(count):
			var bp := ra.lerp(rb, float(k) / float(count)) + Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-6.0, 6.0))
			if _near_river(r, bp, 26.0):
				continue
			r.ridge_rocks.append({
				"pos": bp,
				"size": rng.randf_range(38.0, 50.0),
				"flip": rng.randf() < 0.5
			})

	# Organic mossy/needle floor stains across clearings and glades
	for _m in range(88):
		var mp := Vector2(rng.randf_range(90.0, r.WORLD_W - 90.0), rng.randf_range(90.0, r.WORLD_H - 90.0))
		var rx := rng.randf_range(34.0, 78.0)
		var ry := rng.randf_range(22.0, 52.0)
		var kind := rng.randi_range(0, 2) # 0 moss, 1 pine needles, 2 damp hollow earth
		r.moss_patches.append({"pos": mp, "rx": rx, "ry": ry, "kind": kind})

	# Objective/winch no-spawn zones
	var keep_clear: Array[Vector2] = [
		r.SPAWN_CRASH, r.CLUE_TRACKS_POS, r.BRAMBLE_WEST_POS, r.CLUE_CART_POS,
		r.FIRE_0_POS, r.GORGE_WINCH_E, r.GORGE_WINCH_W, r.BLACK_DRAGON_POS,
		r.EGG_NEST_POS, r.HOLLOW_GATE_POS, r.CAIRN_1_POS, r.FROST_DEAD_POS,
		r.FIRE_ALPHA_POS, r.BRAMBLE_SHORTCUT_POS, r.BOULDER_2HORN_POS,
		r.CART_FORK_POS, r.FIRE_BETA_POS, r.CREEK_WINCH_S, r.CREEK_WINCH_N,
		r.OUTPOST_POS, Vector2(760, 275), Vector2(345, 815), Vector2(665, 842),
		Vector2(2145, 395), Vector2(2155, 675), Vector2(1380, 225)
	]

	var placed_solid: Array[Vector2] = []
	var gy := 56.0
	while gy < r.WORLD_H - 48.0:
		var gx := 56.0
		while gx < r.WORLD_W - 48.0:
			var jitter := Vector2(rng.randf_range(-26.0, 26.0), rng.randf_range(-26.0, 26.0))
			var pos := Vector2(gx, gy) + jitter
			gx += 74.0

			if _near_river(r, pos, 54.0) or _near_polyline(r.ridge_pts, pos, 36.0):
				continue
			var clear_margin: float = _point_walkable_clearance(r, pos)
			if clear_margin > -8.0:
				# Inside walkable clearing/trail -> place occasional decorative fern/moss at margins only
				if clear_margin < 24.0 and rng.randf() < 0.45:
					var skip_obj := false
					for kp in keep_clear:
						if pos.distance_to(kp) < 76.0:
							skip_obj = true
							break
					if not skip_obj:
						r.forest_ferns.append({"pos": pos, "flip": rng.randf() < 0.5, "scale": rng.randf_range(0.95, 1.35)})
				continue

			var too_close_obj := false
			for kp in keep_clear:
				if pos.distance_to(kp) < 74.0:
					too_close_obj = true
					break
			if too_close_obj:
				continue

			var crowd := false
			for prev in placed_solid:
				if pos.distance_to(prev) < 52.0:
					crowd = true
					break
			if crowd:
				continue

			# Edge band of forest: mix tall dark pines, standard pines, boulders, and logs
			placed_solid.append(pos)
			var roll := rng.randf()
			if roll < 0.24:
				r.forest_rocks.append({
					"pos": pos,
					"scale": rng.randf_range(1.0, 1.38),
					"col_r": rng.randf_range(18.0, 23.0)
				})
			elif roll < 0.34 and clear_margin > -75.0:
				r.forest_logs.append({
					"pos": pos,
					"flip": rng.randf() < 0.5,
					"col_r": 18.0
				})
			else:
				r.forest_trees.append({
					"pos": pos,
					"dark": rng.randf() < 0.52,
					"scale": rng.randf_range(0.94, 1.18),
					"flip": rng.randf() < 0.5,
					"col_r": 18.0
				})
		gy += 72.0

	# Extra flanking pines & ferns along clearing edges for rich layered silhouette
	for _f in range(110):
		var fp := Vector2(rng.randf_range(95.0, r.WORLD_W - 95.0), rng.randf_range(95.0, r.WORLD_H - 95.0))
		var cm := _point_walkable_clearance(r, fp)
		if cm >= -28.0 and cm <= 26.0 and not _near_river(r, fp, 36.0) and not _near_polyline(r.ridge_pts, fp, 28.0):
			r.forest_ferns.append({"pos": fp, "flip": rng.randf() < 0.5, "scale": rng.randf_range(0.9, 1.3)})

	var sort_by_y := func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["pos"].y) < float(b["pos"].y)
	r.forest_trees.sort_custom(sort_by_y)
	r.forest_rocks.sort_custom(sort_by_y)
	r.forest_logs.sort_custom(sort_by_y)
	r.forest_ferns.sort_custom(sort_by_y)


static func _build_collisions(r) -> void:
	r.sight_blockers.clear()
	# Outer world bounds
	r.add_box_collider(r.colliders, Rect2(0, 0, r.WORLD_W, 32))
	r.add_box_collider(r.colliders, Rect2(0, r.WORLD_H - 32, r.WORLD_W, 32))
	r.add_box_collider(r.colliders, Rect2(0, 0, 32, r.WORLD_H))
	r.add_box_collider(r.colliders, Rect2(r.WORLD_W - 32, 0, 32, r.WORLD_H))

	# Circular colliders for organic pines, boulders, and deadfall logs so PlayerBoy glides smoothly!
	for t: Dictionary in r.forest_trees:
		var tp: Vector2 = t["pos"] + Vector2(0, -4)
		var col_r: float = float(t["col_r"])
		_add_circle_collider(r.colliders, tp, col_r)
		var tr_r: float = col_r * 0.85
		r.sight_blockers.append(Rect2(tp - Vector2(tr_r, tr_r), Vector2(tr_r * 2.0, tr_r * 2.0)))
	for rk: Dictionary in r.forest_rocks:
		var rp: Vector2 = rk["pos"]
		var col_r: float = float(rk["col_r"])
		_add_circle_collider(r.colliders, rp, col_r)
		var rr: float = col_r * 0.88
		r.sight_blockers.append(Rect2(rp - Vector2(rr, rr), Vector2(rr * 2.0, rr * 2.0)))
	for lg: Dictionary in r.forest_logs:
		r.add_box_collider(r.colliders, Rect2(Vector2(lg["pos"]) - Vector2(22, 10), Vector2(44, 20)))
		r.sight_blockers.append(Rect2(Vector2(lg["pos"]) - Vector2(20, 8), Vector2(40, 16)))

	# Continuous Edge-to-Edge Rivers & Gorge Bridge Openings
	_add_capsule_chain(r.colliders, r.gorge_river_pts, 52.0, [Vector2(270.0, 354.0), Vector2(1302.0, 1388.0)])
	_add_capsule_chain(r.colliders, r.creek_river_pts, 50.0, [])

	# Continuous Granite Escarpment Cliff Spine locking Eastern Maze unless Hollow Gate opens
	_add_capsule_chain(r.colliders, r.ridge_pts, 46.0, [])

	# Bridge Parapets sealing both north/south lips of the Stone Causeway (HOLLOW_GATE) & Timber Footbridge (BRAMBLE_WEST)
	r.add_box_collider(r.colliders, Rect2(476, 254, 114, 18))
	r.add_box_collider(r.colliders, Rect2(476, 352, 114, 18))
	r.add_box_collider(r.colliders, Rect2(486, 1286, 118, 18))
	r.add_box_collider(r.colliders, Rect2(486, 1386, 118, 18))

	# Landmarks & Buildings solid cores
	_add_circle_collider(r.colliders, r.BLACK_DRAGON_POS, 52.0)
	r.add_box_collider(r.colliders, Rect2(r.OUTPOST_POS - Vector2(84, 96), Vector2(168, 86)))
	_add_circle_collider(r.colliders, r.CAIRN_1_POS + Vector2(-58, -56), 16.0)
	_add_circle_collider(r.colliders, r.BOULDER_2HORN_POS + Vector2(56, -54), 22.0)
	_add_circle_collider(r.colliders, r.FIRE_BETA_POS + Vector2(68, -52), 16.0)
	r.sight_blockers.append(Rect2(r.OUTPOST_POS - Vector2(84, 96), Vector2(168, 86)))
	r.sight_blockers.append(Rect2(r.CAIRN_1_POS + Vector2(-58, -56) - Vector2(14, 14), Vector2(28, 28)))
	r.sight_blockers.append(Rect2(r.BOULDER_2HORN_POS + Vector2(56, -54) - Vector2(20, 20), Vector2(40, 40)))
	r.sight_blockers.append(Rect2(r.FIRE_BETA_POS + Vector2(68, -52) - Vector2(14, 14), Vector2(28, 28)))

	# Dynamic Knife-Cuttable Briar Hedges
	for bs in [
		["bramble_west", Rect2(r.BRAMBLE_WEST_POS - Vector2(28, 49), Vector2(56, 98))],
		["bramble_shortcut", Rect2(r.BRAMBLE_SHORTCUT_POS - Vector2(28, 74), Vector2(56, 148))]
	]:
		var bid: String = bs[0]
		var brect: Rect2 = bs[1]
		var sb := StaticBody2D.new()
		r.add_child(sb)
		r.add_box_collider(sb, brect)
		r.bramble_bodies[bid] = sb

	# Obsidian Hollow Stone-Arch Storm-Roots Gate (fits strictly inside Stone Causeway parapets!)
	r.hollow_gate_body = StaticBody2D.new()
	r.add_child(r.hollow_gate_body)
	r.add_box_collider(r.hollow_gate_body, Rect2(r.HOLLOW_GATE_POS - Vector2(28, 42), Vector2(56, 84)))


static func _add_circle_collider(parent: StaticBody2D, center: Vector2, rad: float) -> void:
	var col := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = rad
	col.shape = sh
	col.position = center
	parent.add_child(col)


static func _add_capsule_chain(parent: StaticBody2D, pts: PackedVector2Array, width: float, gap_y_bands: Array = []) -> void:
	var rad := width * 0.5
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var orig_a := a
		var orig_b := b
		var skip := false
		for band: Vector2 in gap_y_bands:
			var y0: float = band.x - rad
			var y1: float = band.y + rad
			var min_y := minf(orig_a.y, orig_b.y)
			var max_y := maxf(orig_a.y, orig_b.y)
			if min_y >= y0 and max_y <= y1:
				skip = true
				break
			if min_y < y0 and max_y > y0 and orig_b.y > orig_a.y:
				b = orig_a.lerp(orig_b, (y0 - orig_a.y) / (orig_b.y - orig_a.y))
			elif min_y < y1 and max_y > y1 and orig_b.y > orig_a.y:
				a = orig_a.lerp(orig_b, (y1 - orig_a.y) / (orig_b.y - orig_a.y))
		if skip:
			continue
		var delta := b - a
		var length := delta.length()
		if length < 1.0:
			continue
		var col := CollisionShape2D.new()
		var sh := CapsuleShape2D.new()
		sh.radius = rad
		sh.height = length + width
		col.shape = sh
		col.position = (a + b) * 0.5
		col.rotation = delta.angle() + PI * 0.5
		parent.add_child(col)


static func _build_lights(r) -> void:
	r.wilds_lights.clear()
	for w_info in [
		[r.FIRE_0_POS, 3.3, Color(1.0, 0.66, 0.28), 1.25],
		[r.FIRE_ALPHA_POS, 3.5, Color(1.0, 0.66, 0.28), 1.3],
		[r.FIRE_BETA_POS, 3.5, Color(1.0, 0.66, 0.28), 1.3],
		[r.EGG_NEST_POS, 2.6, Color(0.98, 0.72, 0.34), 0.88],
		[r.OUTPOST_POS + Vector2(0, 24), 4.0, Color(0.76, 0.96, 0.78), 1.15],
		[r.SPAWN_CRASH, 2.7, Color(0.74, 0.88, 0.76), 0.58],
		[r.CAIRN_1_POS, 2.4, Color(0.74, 0.84, 0.96), 0.52]
	]:
		var wl: PointLight2D = r.assets.make_point_light(w_info[0], w_info[1], w_info[2], w_info[3])
		r.add_child(wl)
		r.wilds_lights.append(wl)


static func _init_atmosphere_pools(r) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4099
	r.fireflies.clear()
	for _i in range(42):
		r.fireflies.append({
			"base": Vector2(rng.randf_range(100.0, r.WORLD_W - 100.0), rng.randf_range(100.0, r.WORLD_H - 100.0)),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.8, 1.9),
			"amp": rng.randf_range(16.0, 38.0),
			"warm": rng.randf() < 0.65
		})
	r.mist_ribbons.clear()
	for _j in range(18):
		r.mist_ribbons.append({
			"pos": Vector2(rng.randf_range(140.0, r.WORLD_W - 140.0), rng.randf_range(140.0, r.WORLD_H - 140.0)),
			"rx": rng.randf_range(75.0, 155.0),
			"ry": rng.randf_range(22.0, 42.0),
			"drift": rng.randf_range(10.0, 24.0),
			"phase": rng.randf_range(0.0, TAU)
		})


static func _setup_hunter_patrols(r) -> void:
	var patrols: Array[Dictionary] = [
		{
			"a": Vector2(1245, 1375),
			"b": Vector2(1615, 1410),
			"pos": Vector2(1245, 1375),
			"dir": Vector2.RIGHT,
			"t": 0.0,
			"dir_sign": 1.0,
			"speed": 0.11,
			"pause": 0.8,
			"suspicion": 0.0,
			"alert": 0.0
		},
		{
			"a": Vector2(2140, 295),
			"b": Vector2(2435, 255),
			"pos": Vector2(2435, 255),
			"dir": Vector2.LEFT,
			"t": 1.0,
			"dir_sign": -1.0,
			"speed": 0.14,
			"pause": 1.15,
			"suspicion": 0.0,
			"alert": 0.0
		}
	]
	r.hunter_patrols.assign(patrols)
	r.hunter_lights.clear()
	for hp: Dictionary in r.hunter_patrols:
		var hl: PointLight2D = r.assets.make_point_light(hp["pos"], 2.2, Color(1.0, 0.70, 0.34), 0.0)
		r.add_child(hl)
		r.hunter_lights.append(hl)


static func has_line_of_sight(r, from_pos: Vector2, to_pos: Vector2) -> bool:
	var min_x := minf(from_pos.x, to_pos.x) - 26.0
	var max_x := maxf(from_pos.x, to_pos.x) + 26.0
	var min_y := minf(from_pos.y, to_pos.y) - 26.0
	var max_y := maxf(from_pos.y, to_pos.y) + 26.0
	for rk: Dictionary in r.forest_rocks:
		var c: Vector2 = rk["pos"]
		if c.x < min_x or c.x > max_x or c.y < min_y or c.y > max_y:
			continue
		var cr: float = float(rk["col_r"]) * 0.92
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(c, from_pos, to_pos)
		if c.distance_to(cp) < cr:
			return false
	for tr: Dictionary in r.forest_trees:
		var tc: Vector2 = Vector2(tr["pos"]) + Vector2(0, -6)
		if tc.x < min_x or tc.x > max_x or tc.y < min_y or tc.y > max_y:
			continue
		var cp2: Vector2 = Geometry2D.get_closest_point_to_segment(tc, from_pos, to_pos)
		if tc.distance_to(cp2) < 15.0:
			return false
	return true
