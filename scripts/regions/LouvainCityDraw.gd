extends RefCounted

## Static ground chunk baker, animated Dijle River water & cargo barges,
## octagonal 15th-century Louvain ring-wall & 4 Poorten, Y-sorted landmarks,
## ambient townsfolk, stealth patrols, and combat overlays for Louvain ("De Kuip", 2100x2100).

const MapData := preload("res://scripts/regions/LouvainCityMapData.gd")

const CITIZEN_STILL_RADIUS := 42.0
const ABBEY_VENT_CRAWL_DUR := 3.40


static func setup_layers(r) -> void:
	r.setup_static_ground_chunks(
		Rect2(0, 0, MapData.WORLD_SIZE.x, MapData.WORLD_SIZE.y),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-3,
		false
	)
	r.setup_water_layer(MapData.get_water_rects(), 32.0, -2)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func step_citizens(citizens: Array[Dictionary], player_pos: Vector2, delta: float) -> void:
	for c: Dictionary in citizens:
		var spd: float = float(c.get("spd", 0.0))
		var pts: Array = c.get("pts", [])
		if spd <= 0.5 or pts.size() < 2:
			continue
		var pos := Vector2(c["pos"])
		if pos.distance_to(player_pos) < CITIZEN_STILL_RADIUS:
			c["paused"] = true
			continue
		c["paused"] = false
		var wp_idx: int = int(c.get("wp", 0)) % pts.size()
		var target := Vector2(pts[wp_idx])
		var to_t := target - pos
		if to_t.length() <= maxf(4.0, spd * delta * 1.2):
			c["pos"] = target
			c["wp"] = (wp_idx + 1) % pts.size()
		else:
			var step_dir := to_t.normalized()
			c["dir"] = step_dir
			c["pos"] = pos + step_dir * spd * delta


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	var oct_pts := PackedVector2Array(MapData.get_octagonal_vertices())

	# 1. Outer Flemish meadow outside the circular-octagonal city ramparts
	assets.draw_grass_zone(canvas, Rect2(0, 0, MapData.WORLD_SIZE.x, MapData.WORLD_SIZE.y), false, 29, [])

	# 2. Concentric earthen ditch & rampart berm around Tweede Stadsomwalling
	var ditch_pts := _scale_poly(oct_pts, MapData.CENTER, 1.036)
	var berm_pts := _scale_poly(oct_pts, MapData.CENTER, 1.014)
	canvas.draw_colored_polygon(ditch_pts, Color(0.24, 0.34, 0.30, 0.58))
	canvas.draw_colored_polygon(berm_pts, Color(0.32, 0.28, 0.22, 0.92))
	canvas.draw_colored_polygon(oct_pts, Color(0.39, 0.35, 0.30))

	# 3. Warm circular interior Brabant cobble & earth quarters (zero frost tiles!)
	var cob_a: Texture2D = assets.get_tex("tile_louvain_cobble.png", "tile_cobble.png")
	var cob_b: Texture2D = assets.get_tex("tile_louvain_cobble_2.png", "tile_cobble_2.png")
	var brick_tex: Texture2D = assets.get_tex("tile_red_brick_path.png", "tile_louvain_cobble_2.png")
	var sand_a: Texture2D = assets.get_tex("tile_sandstone_flag.png", "tile_louvain_cobble.png")
	var sand_b: Texture2D = assets.get_tex("tile_sandstone_flag_2.png", "tile_sandstone_flag.png")

	for gy in range(128, 1972, 32):
		for gx in range(128, 1972, 32):
			var center := Vector2(float(gx) + 16.0, float(gy) + 16.0)
			if not Geometry2D.is_point_in_polygon(center, oct_pts):
				continue
			var h := int(assets.tile_hash(gx >> 5, gy >> 5, 7)) % 10
			var tex_pick := cob_b if h < 3 else cob_a
			if tex_pick != null:
				canvas.draw_texture_rect(tex_pick, Rect2(gx, gy, 32, 32), false)

	# 4. Outward approach roads leading cleanly through all 4 Poort gatehouses
	for out_rd: Rect2 in [
		Rect2(0, 996, 168, 88),
		Rect2(1932, 996, 168, 88),
		Rect2(1004, 0, 92, 168),
		Rect2(1002, 1932, 96, 168),
	]:
		canvas.draw_rect(out_rd.grow(3.0), Color(0.24, 0.21, 0.18))
		assets.draw_varied_tiled_rect(canvas, out_rd, cob_a, cob_b, 32.0, 9)

	# 5. Primary radial & quarter streets with warm mortar edge shadows
	for rd: Rect2 in MapData.get_roads():
		canvas.draw_rect(rd.grow(2.5), Color(0.25, 0.22, 0.19, 0.85))
		assets.draw_varied_tiled_rect(canvas, rd, cob_b, cob_a, 32.0, 11)

	# 6. Brick quays, Lakenhalle border, and Dyers' Island walks
	for br_path: Rect2 in MapData.get_brick_paths():
		canvas.draw_rect(br_path.grow(2.0), Color(0.30, 0.19, 0.16, 0.85))
		assets.draw_varied_tiled_rect(canvas, br_path, brick_tex, cob_b, 32.0, 5)

	# 7. Warm Brabant sandstone plazas (Grote Markt, Lakenhalle/University, Scriptorium Cloister)
	for pl: Dictionary in MapData.get_plazas():
		var pr: Rect2 = pl["rect"]
		canvas.draw_rect(pr.grow(3.0), Color(0.34, 0.28, 0.22))
		assets.draw_varied_tiled_rect(canvas, pr, sand_a, sand_b, 32.0, 13)
		canvas.draw_rect(pr, Color(0.68, 0.56, 0.38, 0.62), false, 2.0)

	# 8. Lush Cloister, Lime-Yard & Apothecary Herb Garden Lawns
	for lawn: Rect2 in MapData.get_garden_lawns():
		canvas.draw_rect(lawn.grow(3.0), Color(0.28, 0.24, 0.19))
		assets.draw_grass_zone(canvas, lawn, true, 17, [])

	# 9. Grote Markt Fountain stone apron & Dijle embankments + clay slip
	var fpos: Vector2 = MapData.FOUNTAIN_POS
	canvas.draw_circle(fpos + Vector2(0, 3), 48.0, Color(0.24, 0.20, 0.17, 0.68))
	canvas.draw_circle(fpos, 44.0, Color(0.56, 0.49, 0.39))
	canvas.draw_arc(fpos, 44.0, 0.0, TAU, 32, Color(0.30, 0.24, 0.19), 2.0)

	for wr: Rect2 in MapData.get_water_rects():
		canvas.draw_rect(wr.grow(7.0), Color(0.26, 0.22, 0.19))
		canvas.draw_rect(wr.grow(3.0), Color(0.46, 0.40, 0.33))
	canvas.draw_circle(MapData.CLAY_BANK_POS, 28.0, Color(0.38, 0.30, 0.22, 0.78))


static func draw_region_entities(r, t_now: float) -> void:
	var assets = r.assets
	var font: Font = assets.get_ui_font()
	var cam_rect: Rect2 = r.get_camera_rect(220.0)

	# 1. Moored Dijle cargo barges & water wakes + stone bridges
	for bg: Dictionary in MapData.get_river_barges():
		var b_rect := Rect2(bg["rect"])
		if not cam_rect.intersects(b_rect.grow(36.0)):
			continue
		var phase: float = float(bg.get("phase", 0.0))
		var bob_y := sin(t_now * 1.9 + phase) * 2.2
		var dr := Rect2(b_rect.position + Vector2(0.0, bob_y), b_rect.size)
		r.draw_rect(Rect2(dr.position + Vector2(-2, dr.size.y - 4), Vector2(dr.size.x + 4, 6)), Color(0.74, 0.88, 0.94, 0.26))
		var btex: Texture2D = assets.get_tex(String(bg["tex"]))
		if btex != null:
			r.draw_texture_rect(btex, dr, false)

	for br: Dictionary in MapData.get_bridges():
		var br_r: Rect2 = br["rect"]
		if cam_rect.intersects(br_r.grow(28.0)):
			var stex: Texture2D = assets.get_tex(String(br["tex"]))
			if stex != null:
				r.draw_texture_rect(stex, br_r, false)

	# 2. Concentric octagonal curtain walls & interior Abbey Cloister walls
	_draw_city_ramparts(r, assets, cam_rect)
	_draw_abbey_gate_and_vent(r, assets, t_now, cam_rect)

	var sb: Rect2 = MapData.SOUTH_GATE_BARRICADE_RECT
	if cam_rect.intersects(sb.grow(24.0)) and not GameState.louvain_breakout_won:
		r.draw_rect(sb, Color(0.22, 0.16, 0.14, 0.94))
		for sx in range(int(sb.position.x + 12), int(sb.end.x - 8), 16):
			r.draw_line(Vector2(sx, sb.position.y), Vector2(sx, sb.end.y), Color(0.62, 0.48, 0.28), 3.6)

	# 3. Unified Y-sorted drawables (buildings, Poorts, wall towers, props, lanterns, NPCs, citizens)
	var drawables: Array[Dictionary] = []
	_collect_architecture_and_props(r, assets, t_now, cam_rect, drawables)
	_collect_npcs_and_citizens(r, t_now, cam_rect, drawables)
	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))

	for item: Dictionary in drawables:
		var kind := String(item["kind"])
		if kind == "bldg":
			assets.draw_sprite_building(r, item["rect"], String(item["tex"]), "", font)
		elif kind == "tex":
			var tx: Texture2D = assets.get_tex(String(item["tex"]))
			if tx != null:
				var dr: Rect2 = item["rect"]
				r.draw_rect(Rect2(dr.position + Vector2(3, dr.size.y - 5), Vector2(dr.size.x - 6, 8)), Color(0.06, 0.05, 0.07, 0.28))
				r.draw_texture_rect(tx, dr, false)
		elif kind == "fountain":
			_draw_fountain(r, assets, t_now, item["pos"])
		elif kind == "oven":
			assets.draw_bakery_oven_fx(r, item["rect"], t_now)
		elif kind == "brazier":
			_draw_brazier(r, assets, t_now, item["pos"])
		elif kind == "lantern":
			_draw_lantern(r, assets, t_now, item["pos"])
		elif kind == "npc":
			assets.draw_npc_sprite(r, item["pos"], String(item["tex"]), "", font, Color.WHITE, bool(item["flip"]))

	# 4. Warm hearth smoke plumes on Bakery & Guild Tavern chimneys
	for ci in range(2):
		var spos := Vector2(692, 540) if ci == 0 else Vector2(310, 1110)
		if cam_rect.has_point(spos):
			assets.draw_chimney_smoke(r, spos, ci)

	# 5. Wanted Posters, Chimes, Smoke Clouds, Patrols & Breakout Encounter
	r.heat_helper.draw_overlays(r, assets)
	_draw_patrols_and_combat(r, assets, font, t_now, cam_rect)
	r.draw_interact_bubble_if_active(font)


static func _draw_city_ramparts(r, assets, cam_rect: Rect2) -> void:
	var wall_h: Texture2D = assets.get_tex("prop_wall_h.png")
	var wall_v: Texture2D = assets.get_tex("prop_wall_v.png")
	for wr: Rect2 in MapData.get_cardinal_walls():
		if cam_rect.intersects(wr.grow(28.0)):
			_draw_wall_tiled(r, wr, wall_h, wall_v)

	# Continuous bevelled stone ramparts across the 4 diagonal octagonal corners
	var oct := MapData.get_octagonal_vertices()
	for pair in [[0, 7], [1, 2], [6, 5], [3, 4]]:
		var a: Vector2 = oct[pair[0]]
		var b: Vector2 = oct[pair[1]]
		var seg_rect := Rect2(minf(a.x, b.x), minf(a.y, b.y), absf(b.x - a.x), absf(b.y - a.y)).grow(48.0)
		if not cam_rect.intersects(seg_rect):
			continue
		var dir := (b - a).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		r.draw_line(a + nrm * 3.0, b + nrm * 3.0, Color(0.18, 0.16, 0.18), 38.0)
		r.draw_line(a, b, Color(0.45, 0.41, 0.37), 32.0)
		r.draw_line(a - nrm * 6.0, b - nrm * 6.0, Color(0.58, 0.52, 0.44), 12.0)
		var seg_len := a.distance_to(b)
		for d in range(28, int(seg_len) - 20, 26):
			var mp := a + dir * float(d)
			var mrect := PackedVector2Array([
				mp + nrm * 11.0 - dir * 7.0, mp + nrm * 11.0 + dir * 7.0,
				mp + nrm * 17.0 + dir * 7.0, mp + nrm * 17.0 - dir * 7.0,
			])
			r.draw_colored_polygon(mrect, Color(0.32, 0.29, 0.28))

	_draw_cloister_enclosure(r, assets, wall_h, wall_v, cam_rect)


static func _draw_cloister_enclosure(r: Node2D, assets, wall_h: Texture2D, wall_v: Texture2D, cam_rect: Rect2) -> void:
	var cloister_bounds := Rect2(1240, 438, 376, 334).grow(32.0)
	if not cam_rect.intersects(cloister_bounds):
		return
	# Straight wall spans strictly between the four 36x36 mitered stone corners
	for hr: Rect2 in [
		Rect2(1276, 438, 304, 36),
		Rect2(1276, 736, 20, 36),
		Rect2(1380, 736, 200, 36),
	]:
		_draw_wall_tiled(r, hr, wall_h, wall_v)
	for vr: Rect2 in [
		Rect2(1240, 474, 36, 262),
		Rect2(1580, 474, 36, 262),
	]:
		_draw_wall_tiled(r, vr, wall_h, wall_v)
	# Continuous 90-degree bending ashlar & parapet corners
	for c_spec: Dictionary in [
		{"tex": "prop_wall_corner_nw.png", "pos": Vector2(1240, 438)},
		{"tex": "prop_wall_corner_ne.png", "pos": Vector2(1580, 438)},
		{"tex": "prop_wall_corner_sw.png", "pos": Vector2(1240, 736)},
		{"tex": "prop_wall_corner_se.png", "pos": Vector2(1580, 736)},
	]:
		var ctex: Texture2D = assets.get_tex(String(c_spec["tex"]))
		if ctex != null:
			r.draw_texture_rect(ctex, Rect2(Vector2(c_spec["pos"]), Vector2(36, 36)), false)


static func _draw_abbey_gate_and_vent(r, assets, t_now: float, cam_rect: Rect2) -> void:
	var ag: Rect2 = MapData.ABBEY_GATE_RECT
	if cam_rect.intersects(ag.grow(76.0)):
		var pier_h: Texture2D = assets.get_tex("prop_gatehouse_pier_h.png")
		if pier_h != null:
			r.draw_texture_rect(pier_h, Rect2(ag.position.x - 32.0, ag.position.y - 6.0, 42.0, 48.0), false)
			r.draw_texture_rect(pier_h, Rect2(ag.end.x - 10.0, ag.position.y - 6.0, 42.0, 48.0), false)
		var open_k := clampf(float(r.abbey_gate_open_anim), 0.0, 1.0)
		var curr_w := lerpf(ag.size.x, 10.0, open_k)
		if open_k < 0.98:
			r.draw_rect(Rect2(ag.position.x, ag.position.y, curr_w, ag.size.y), Color(0.14, 0.14, 0.18, 0.88))
			for gx in range(int(ag.position.x + 10), int(ag.position.x + curr_w - 4), 14):
				r.draw_line(Vector2(gx, ag.position.y), Vector2(gx, ag.end.y), Color(0.50, 0.52, 0.58), 3.0)
		var lever_p: Vector2 = MapData.ABBEY_LEVER_POS
		var tripped: bool = open_k > 0.25 or bool(r.get("_abbey_lever_tripped"))
		r.draw_line(Vector2(ag.end.x - 4.0, ag.position.y + 8.0), lever_p, Color(0.38, 0.36, 0.34), 2.2)
		r.draw_rect(Rect2(lever_p - Vector2(6, 6), Vector2(12, 12)), Color(0.24, 0.23, 0.26))
		var tip := lever_p + (Vector2(12, -13) if tripped else Vector2(-12, -13))
		r.draw_line(lever_p, tip, Color(0.56, 0.54, 0.52), 3.0)
		r.draw_circle(tip, 4.0, Color(0.42, 0.78, 0.48) if tripped else Color(0.92, 0.36, 0.24))

	if cam_rect.intersects(Rect2(MapData.ABBEY_VENT_POS - Vector2(48, 48), Vector2(96, 96))):
		var vp: Vector2 = MapData.ABBEY_VENT_POS
		r.draw_rect(Rect2(vp.x - 20.0, vp.y - 24.0, 40.0, 42.0), Color(0.26, 0.24, 0.26))
		r.draw_rect(Rect2(vp.x - 12.0, vp.y - 22.0, 24.0, 38.0), Color(0.06, 0.08, 0.09, 0.94))
		var vtex: Texture2D = assets.get_tex("prop_dragon_vent_grate.png")
		if vtex != null:
			r.draw_texture_rect(vtex, Rect2(vp + Vector2(-12, 4), Vector2(24, 18)), false)
			r.draw_texture_rect(vtex, Rect2(vp + Vector2(-12, -22), Vector2(24, 16)), false, Color(0.76, 0.78, 0.80, 0.85))
		if not GameState.louvain_vent_opened:
			var sh := 0.5 + 0.5 * sin(t_now * 4.2)
			r.draw_arc(vp + Vector2(0, 14), 14.0 + sh * 3.0, 0.0, TAU, 18, Color(0.96, 0.80, 0.34, 0.55), 1.6)

	if float(r.get("abbey_vent_crawl_t")) > 0.0:
		var prog := 1.0 - clampf(float(r.get("abbey_vent_crawl_t")) / ABBEY_VENT_CRAWL_DUR, 0.0, 1.0)
		var step_i := int(t_now * 7.5) % 2
		var vp: Vector2 = MapData.ABBEY_VENT_POS
		var lever_walk := MapData.ABBEY_LEVER_POS + Vector2(6, 4)
		var dp := vp
		var dkey := "up"
		var flip_d := false
		var in_t := false
		if prog < 0.16:
			dp = (vp + Vector2(0, 28)).lerp(vp + Vector2(0, 8), prog / 0.16)
		elif prog < 0.42:
			in_t = true
			dp = (vp + Vector2(0, 8)).lerp(vp + Vector2(0, -28), (prog - 0.16) / 0.26)
		elif prog < 0.70:
			dkey = "side"
			flip_d = true
			dp = (vp + Vector2(0, -28)).lerp(lever_walk, (prog - 0.42) / 0.28)
		elif prog < 0.78:
			dkey = "down"
			step_i = 0
			dp = lever_walk
		else:
			dkey = "down"
			dp = lever_walk.lerp(Vector2(1338, 792), (prog - 0.78) / 0.22)
		if in_t:
			r.draw_circle(dp, 7.0, Color(0.10, 0.10, 0.12, 0.86))
			r.draw_circle(dp + Vector2(0, -2), 1.8, Color(0.98, 0.84, 0.34, 0.92))
		else:
			var fname := "dragon_gold_s1_%s_%d.png" % [dkey, step_i]
			var htex: Texture2D = assets.get_tex_flipped(fname) if flip_d else assets.get_tex(fname)
			if htex != null:
				r.draw_texture_rect(htex, Rect2(dp - Vector2(13, 17), Vector2(26, 24)), false)


static func _collect_architecture_and_props(_r, _assets, _t_now: float, cam_rect: Rect2, out: Array[Dictionary]) -> void:
	for tp: Vector2 in MapData.get_wall_towers():
		var trect := Rect2(tp.x - 44.0, tp.y - 68.0, 88.0, 104.0)
		if cam_rect.intersects(trect.grow(16.0)):
			out.append({"kind": "tex", "tex": "prop_louvain_wall_tower.png", "rect": trect, "y": trect.end.y})

	for po: Dictionary in MapData.get_poorts():
		var pr: Rect2 = po["rect"]
		var tex_s := String(po["tex"])
		var dr := Rect2(pr.position.x, pr.end.y - 124.0, 168.0, 124.0) if tex_s == "prop_louvain_poort_h.png" else pr
		if cam_rect.intersects(dr.grow(20.0)):
			out.append({"kind": "tex", "tex": tex_s, "rect": dr, "y": dr.end.y})

	for b: Dictionary in MapData.get_buildings():
		var br: Rect2 = b["rect"]
		if cam_rect.intersects(br.grow(32.0)):
			out.append({"kind": "bldg", "tex": String(b["tex"]), "rect": br, "y": br.end.y})

	for pr_d: Dictionary in MapData.get_prop_placements():
		var rr: Rect2 = pr_d["rect"]
		if not cam_rect.intersects(rr.grow(16.0)):
			continue
		var tname := String(pr_d["tex"])
		out.append({"kind": "oven" if tname == "prop_brick_bread_oven.png" else "tex", "tex": tname, "rect": rr, "y": rr.end.y})

	var special_props := [
		{"tex": "prop_bell_mould.png", "rect": Rect2(MapData.BELL_MOULD_POS - Vector2(22, 20), Vector2(44, 40))},
		{"tex": "prop_winch_post.png", "rect": Rect2(MapData.FOUNDRY_WINCH_POS - Vector2(14, 24), Vector2(28, 34))},
		{"tex": "prop_herb_cauldron.png", "rect": Rect2(MapData.HERBALIST_SLUICE_POS - Vector2(18, 18), Vector2(36, 36))},
		{"tex": "prop_crate.png", "rect": Rect2(MapData.CONFISCATED_CHEST_POS - Vector2(16, 14), Vector2(32, 28))},
		{"tex": "prop_archive_desk.png", "rect": Rect2(MapData.ARCHIVE_DESK_POS - Vector2(22, 16), Vector2(44, 32))},
		{"tex": "prop_milestone.png", "rect": Rect2(MapData.SOUTH_SIGN_POS - Vector2(14, 20), Vector2(28, 30))},
	]
	for sp_d: Dictionary in special_props:
		var sr: Rect2 = sp_d["rect"]
		if cam_rect.intersects(sr.grow(16.0)):
			out.append({"kind": "tex", "tex": String(sp_d["tex"]), "rect": sr, "y": sr.end.y})

	if cam_rect.has_point(MapData.FOUNTAIN_POS):
		out.append({"kind": "fountain", "pos": MapData.FOUNTAIN_POS, "y": MapData.FOUNTAIN_POS.y + 34.0})
	for bz: Vector2 in _r.ABBEY_BRAZIERS:
		if cam_rect.has_point(bz):
			out.append({"kind": "brazier", "pos": bz, "y": bz.y + 10.0})
	for lp: Vector2 in MapData.get_lantern_positions():
		if cam_rect.has_point(lp):
			out.append({"kind": "lantern", "pos": lp, "y": lp.y + 6.0})


static func _collect_npcs_and_citizens(r, t_now: float, cam_rect: Rect2, out: Array[Dictionary]) -> void:
	for n: Dictionary in [
		{"pos": r.NPC_PIETER_POS, "tex": "npc_city_cooper.png", "flip": false},
		{"pos": r.NPC_MASON_POS, "tex": "npc_louvain_mason.png", "flip": false},
		{"pos": r.NPC_SCHOLAR_POS, "tex": "npc_louvain_scholar.png", "flip": false},
		{"pos": r.NPC_ALEIDIS_POS, "tex": "npc_city_fishwife.png", "flip": false},
		{"pos": r.NPC_MARTIJN_POS, "tex": "npc_city_sailor.png", "flip": true},
		{"pos": r.NPC_KATELIJNE_POS, "tex": "npc_city_apothecary.png", "flip": true},
	]:
		var np: Vector2 = n["pos"]
		if cam_rect.has_point(np):
			out.append({"kind": "npc", "pos": np, "tex": String(n["tex"]), "flip": bool(n["flip"]), "y": np.y + 11.0})

	var walk_f := int(t_now * 4.2) % 2
	for c: Dictionary in r.ambient_citizens:
		var cp: Vector2 = Vector2(c["pos"])
		if not cam_rect.has_point(cp):
			continue
		var paused: bool = bool(c.get("paused", false)) or float(c.get("spd", 0.0)) <= 0.5
		var tbase := String(c["tex"])
		var ctex := "%s.png" % tbase if paused else "%s_%d.png" % [tbase, walk_f]
		out.append({"kind": "npc", "pos": cp, "tex": ctex, "flip": Vector2(c["dir"]).x < -0.1, "y": cp.y + 11.0})


static func _draw_fountain(r, assets, t_now: float, fpos: Vector2) -> void:
	var ftex: Texture2D = assets.get_tex("prop_stone_fountain.png")
	if ftex != null:
		r.draw_texture_rect(ftex, Rect2(fpos - Vector2(36, 36), Vector2(72, 72)), false)
	for i in range(2):
		var rp := fmod(t_now * 0.7 + float(i) * 0.5, 1.0)
		r.draw_arc(fpos + Vector2(0, 6), 8.0 + rp * 18.0, 0.0, TAU, 20, Color(0.80, 0.92, 0.98, (1.0 - rp) * 0.45), 1.4)


static func _draw_brazier(r, assets, t_now: float, bz: Vector2) -> void:
	var bt: Texture2D = assets.get_tex("prop_wall_brazier.png")
	if bt != null:
		r.draw_texture_rect(bt, Rect2(bz - Vector2(11, 15), Vector2(22, 26)), false)
	if GameState.louvain_brazier_lit:
		r.draw_circle(bz + Vector2(0, -10), 18.0 + sin(t_now * 8.0) * 3.0, Color(1.0, 0.70, 0.24, 0.28))
		r.draw_circle(bz + Vector2(0, -12), 5.5, Color(1.0, 0.90, 0.44, 0.88))


static func _draw_lantern(r, assets, t_now: float, lp: Vector2) -> void:
	var lt: Texture2D = assets.get_tex("prop_lantern.png")
	if lt != null:
		r.draw_texture_rect(lt, Rect2(lp - Vector2(10, 22), Vector2(20, 28)), false)
	var pulse := 0.85 + 0.15 * sin(t_now * 5.2 + lp.x * 0.05)
	r.draw_circle(lp + Vector2(0, -14), 12.0 * pulse, Color(1.0, 0.74, 0.30, 0.20))
	r.draw_circle(lp + Vector2(0, -14), 3.0, Color(1.0, 0.90, 0.52, 0.82))


static func _draw_patrols_and_combat(r, assets, font: Font, t_now: float, cam_rect: Rect2) -> void:
	var walk_f := int(t_now * 4.5) % 2
	if not GameState.louvain_breakout_won and r.breakout_enemies.is_empty():
		for pat: Dictionary in r.patrols:
			var gp: Vector2 = Vector2(pat["pos"])
			if not cam_rect.intersects(Rect2(gp - Vector2(220, 220), Vector2(440, 440))):
				continue
			var gdir: Vector2 = Vector2(pat["dir"])
			var snared_p := float(pat.get("stun", 0.0)) > 0.0
			var alert_col := Color(0.95, 0.36, 0.24, 0.16) if float(pat.get("lure_timer", 0.0)) <= 0.0 else Color(0.96, 0.80, 0.32, 0.14)
			if not snared_p:
				r.draw_raycast_vision_cone(r, gp, gdir, 185.0, 0.48, r.sight_blockers, alert_col, Color(0.96, 0.72, 0.36, 0.35), 18)
			assets.draw_npc_sprite(r, gp, "npc_church_hunter_%d.png" % walk_f, "", font, Color.WHITE, gdir.x < -0.1)
			if snared_p:
				r.draw_arc(gp + Vector2(0, -10), 11.0, 0.0, TAU, 16, Color(0.76, 0.62, 0.34), 2.4)
				r.draw_arc(gp + Vector2(0, -4), 9.0, 0.0, TAU, 14, Color(0.45, 0.86, 0.64), 1.8)

	for e: Dictionary in r.breakout_enemies:
		if int(e["hp"]) <= 0:
			continue
		var ep: Vector2 = Vector2(e["pos"])
		if not cam_rect.has_point(ep):
			continue
		var etex := ("npc_city_guard_%d.png" if String(e["kind"]) == "shield" else "npc_church_hunter_%d.png") % walk_f
		assets.draw_npc_sprite(r, ep, etex, "", font, Color.WHITE, Vector2(e["dir"]).x < -0.1)
		if bool(e.get("has_shield", false)):
			var sh_p := ep + Vector2(e["dir"]).normalized() * 11.0 + Vector2(0, -6)
			r.draw_rect(Rect2(sh_p - Vector2(5, 7), Vector2(10, 14)), Color(0.56, 0.48, 0.34))
			r.draw_rect(Rect2(sh_p - Vector2(5, 7), Vector2(10, 14)), Color(0.86, 0.74, 0.42), false, 1.4)
		if float(e.get("snared_t", 0.0)) > 0.0:
			r.draw_arc(ep + Vector2(0, -10), 12.0, 0.0, TAU, 16, Color(0.82, 0.68, 0.36), 2.8)
			r.draw_arc(ep + Vector2(0, -4), 10.0, 0.0, TAU, 14, Color(0.45, 0.88, 0.66), 2.0)
		if float(e.get("stun", 0.0)) > 0.0:
			r.draw_arc(ep + Vector2(0, -24), 7.0, 0.0, TAU, 10, Color(0.98, 0.88, 0.36), 1.6)

	for blt: Dictionary in r.enemy_bolts:
		var bp: Vector2 = Vector2(blt["pos"])
		if cam_rect.has_point(bp):
			r.draw_line(bp - Vector2(blt["dir"]) * 8.0, bp + Vector2(blt["dir"]) * 8.0, Color(0.98, 0.78, 0.36), 2.5)
	for sp: Dictionary in r.fx_sparks:
		var sp_p: Vector2 = Vector2(sp["pos"])
		if cam_rect.has_point(sp_p):
			var col: Color = Color(sp["col"])
			col.a *= clampf(float(sp["life"]) / float(sp["max_life"]), 0.0, 1.0)
			r.draw_circle(sp_p, float(sp["sz"]), col)
	if r.resonance_wave_t > 0.0:
		var wp: float = 1.0 - (float(r.resonance_wave_t) / 1.1)
		r.draw_arc(Vector2(r.resonance_wave_origin), 24.0 + wp * 280.0, 0.0, TAU, 36, Color(1.0, 0.88, 0.38, 1.0 - wp), 4.0)


static func _draw_wall_tiled(canvas: Node2D, wr: Rect2, wall_h: Texture2D, wall_v: Texture2D) -> void:
	var is_h := wr.size.x >= wr.size.y
	var tex := wall_h if is_h else wall_v
	if tex == null:
		canvas.draw_rect(wr, Color(0.36, 0.33, 0.32))
		return
	if is_h:
		var px := wr.position.x
		while px < wr.end.x - 1.0:
			var step_w := minf(32.0, wr.end.x - px)
			canvas.draw_texture_rect_region(tex, Rect2(px, wr.position.y, step_w, wr.size.y), Rect2(0, 0, step_w, float(tex.get_height())))
			px += 32.0
	else:
		var py := wr.position.y
		while py < wr.end.y - 1.0:
			var step_h := minf(32.0, wr.end.y - py)
			canvas.draw_texture_rect_region(tex, Rect2(wr.position.x, py, wr.size.x, step_h), Rect2(0, 0, float(tex.get_width()), step_h))
			py += 32.0


static func _draw_foreground(r, fg: Node2D) -> void:
	var assets = r.assets
	var cam_rect: Rect2 = r.get_camera_rect(180.0)
	for b: Dictionary in MapData.get_buildings():
		var br_b: Rect2 = b["rect"]
		if cam_rect.intersects(br_b.grow(24.0)):
			var btex: Texture2D = assets.get_tex(String(b["tex"]))
			if btex != null:
				r.draw_building_roof_overhang(fg, br_b, btex, 0.44)
	for po: Dictionary in MapData.get_poorts():
		var pr: Rect2 = po["rect"]
		var tex_s := String(po["tex"])
		var ptex: Texture2D = assets.get_tex(tex_s)
		if ptex == null:
			continue
		if tex_s == "prop_louvain_poort_h.png":
			var dr := Rect2(pr.position.x, pr.end.y - 124.0, 168.0, 124.0)
			if cam_rect.intersects(dr.grow(20.0)):
				r.draw_building_roof_overhang(fg, dr, ptex, 0.56)
		elif cam_rect.intersects(pr.grow(20.0)):
			r.draw_building_roof_overhang(fg, pr, ptex, 0.42)
			# South flanking bastion crest when player walks just behind south turret
			if r.player != null and r.player.visible and r.player.position.x >= pr.position.x - 16.0 and r.player.position.x <= pr.end.x + 16.0 and r.player.position.y >= pr.position.y + pr.size.y * 0.56 and r.player.position.y <= pr.end.y - 6.0:
				var tw := float(ptex.get_width())
				var th := float(ptex.get_height())
				fg.draw_texture_rect_region(ptex, Rect2(pr.position.x, pr.position.y + pr.size.y * 0.72, pr.size.x, pr.size.y * 0.28), Rect2(0.0, th * 0.72, tw, th * 0.28))
	for tp: Vector2 in MapData.get_wall_towers():
		var trect := Rect2(tp.x - 44.0, tp.y - 68.0, 88.0, 104.0)
		if cam_rect.intersects(trect.grow(16.0)):
			var ttex: Texture2D = assets.get_tex("prop_louvain_wall_tower.png")
			if ttex != null:
				r.draw_building_roof_overhang(fg, trect, ttex, 0.50)
	r._draw_portal_hints(fg)
	_draw_integrated_prompts(r, fg)


static func _draw_integrated_prompts(r, fg: Node2D) -> void:
	if r.player == null or not r.player.visible or (r.ui != null and r.ui.is_blocking_gameplay()):
		return
	var ppos: Vector2 = r.player.position
	var font: Font = r.assets.get_ui_font()
	var cmd_k := GameState.get_action_key_label("dragon_command")
	if not GameState.louvain_vent_opened and float(r.get("abbey_vent_crawl_t")) <= 0.0:
		if ppos.distance_to(MapData.ABBEY_VENT_POS) <= 84.0:
			r.assets.draw_interact_bubble(fg, MapData.ABBEY_VENT_POS + Vector2(0, -28), "[%s] Send Through Drain" % cmd_k, font)
	elif GameState.louvain_vent_opened and not GameState.louvain_brazier_lit:
		for bz: Vector2 in r.ABBEY_BRAZIERS:
			if ppos.distance_to(bz) <= 105.0:
				r.assets.draw_interact_bubble(fg, bz + Vector2(0, -32), "[%s] Kindle Abbey Sconces" % cmd_k, font)
				break


static func _scale_poly(poly: PackedVector2Array, origin: Vector2, k: float) -> PackedVector2Array:
	var res := PackedVector2Array()
	for pt in poly:
		res.append(origin + (pt - origin) * k)
	return res
