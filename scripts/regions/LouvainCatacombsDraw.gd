extends RefCounted

## Static chamber ground baker, gothic lighting effects, sliding High Altar,
## 4x4 crest-carved Sarcophagi with under-grave spike traps / ladder / reliquary chest,
## and dated Hidden Library visuals for Louvain Abbey Cathedral & Catacombs (2880x900).

const MapData := preload("res://scripts/regions/LouvainCatacombsMapData.gd")


static func setup_layers(r) -> void:
	r.setup_static_ground_chunks(
		Rect2(0, 0, MapData.WORLD_SIZE.x, MapData.WORLD_SIZE.y),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-3,
		false
	)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	canvas.draw_rect(Rect2(Vector2.ZERO, MapData.WORLD_SIZE), Color(0.05, 0.05, 0.08))

	var bounds := MapData.get_chamber_bounds()
	var wall_h: Texture2D = assets.get_tex("prop_wall_h.png")
	var wall_v: Texture2D = assets.get_tex("prop_wall_v.png")

	# Floor 0: Cathedral Nave checkered limestone paving & crimson sanctuary carpet
	var f0 := bounds[0]
	var nav_a: Texture2D = assets.get_tex("tile_cathedral_flag.png")
	var nav_b: Texture2D = assets.get_tex("tile_cathedral_flag_2.png")
	assets.draw_varied_tiled_rect(canvas, f0, nav_a, nav_b, 32.0, 7)
	canvas.draw_rect(Rect2(436, 224, 88, 576), Color(0.46, 0.14, 0.16, 0.90))
	canvas.draw_rect(Rect2(436, 224, 88, 576), Color(0.74, 0.58, 0.24, 0.65), false, 2.0)
	canvas.draw_rect(Rect2(256, 152, 448, 128), Color(0.84, 0.80, 0.72, 0.22))
	_draw_chamber_walls(canvas, f0, wall_h, wall_v, assets, true)

	# Floor 1: Vaulted Catacombs damp flagstones + recessed stone grave beds
	var f1 := bounds[1]
	var cry_a: Texture2D = assets.get_tex("tile_catacomb_stone.png")
	var cry_b: Texture2D = assets.get_tex("tile_catacomb_stone_2.png")
	assets.draw_varied_tiled_rect(canvas, f1, cry_a, cry_b, 32.0, 11)
	for g: Dictionary in MapData.get_graves_data():
		var gp := Vector2(g["pos"])
		canvas.draw_rect(Rect2(gp - Vector2(22, 23), Vector2(44, 46)), Color(0.09, 0.09, 0.12, 0.90))
		canvas.draw_rect(Rect2(gp - Vector2(20, 21), Vector2(40, 42)), Color(0.24, 0.23, 0.26), false, 1.5)
	_draw_chamber_walls(canvas, f1, wall_h, wall_v, assets, false)

	# Floor 2: Hidden Underground Library aged oak parquet & central carpet runner
	var f2 := bounds[2]
	var lib_a: Texture2D = assets.get_tex("tile_library_wood.png")
	var lib_b: Texture2D = assets.get_tex("tile_library_wood_2.png")
	assets.draw_varied_tiled_rect(canvas, f2, lib_a, lib_b, 32.0, 5)
	canvas.draw_rect(Rect2(2352, 168, 96, 588), Color(0.36, 0.16, 0.18, 0.88))
	canvas.draw_rect(Rect2(2352, 168, 96, 588), Color(0.76, 0.60, 0.26, 0.68), false, 2.0)
	_draw_chamber_walls(canvas, f2, wall_h, wall_v, assets, false)


static func _draw_chamber_walls(canvas: Node2D, b: Rect2, wall_h: Texture2D, wall_v: Texture2D, assets, has_windows: bool) -> void:
	_draw_wall_span_h(canvas, b.position.x, b.end.x, b.position.y - 36.0, wall_h)
	_draw_wall_span_h(canvas, b.position.x, b.end.x, b.end.y, wall_h)
	_draw_wall_span_v(canvas, b.position.x - 36.0, b.position.y, b.end.y, wall_v)
	_draw_wall_span_v(canvas, b.end.x, b.position.y, b.end.y, wall_v)
	for cspec: Dictionary in [
		{"tex": "prop_wall_corner_nw.png", "pos": Vector2(b.position.x - 36.0, b.position.y - 36.0)},
		{"tex": "prop_wall_corner_ne.png", "pos": Vector2(b.end.x, b.position.y - 36.0)},
		{"tex": "prop_wall_corner_sw.png", "pos": Vector2(b.position.x - 36.0, b.end.y)},
		{"tex": "prop_wall_corner_se.png", "pos": Vector2(b.end.x, b.end.y)},
	]:
		var ct: Texture2D = assets.get_tex(String(cspec["tex"]))
		if ct != null:
			canvas.draw_texture_rect(ct, Rect2(Vector2(cspec["pos"]), Vector2(36, 36)), false)

	if has_windows:
		for wx: float in [240.0, 360.0, 600.0, 720.0]:
			canvas.draw_rect(Rect2(wx - 14.0, b.position.y - 26.0, 28.0, 20.0), Color(0.28, 0.56, 0.88, 0.85))
			canvas.draw_rect(Rect2(wx - 8.0, b.position.y - 24.0, 16.0, 16.0), Color(0.92, 0.72, 0.28, 0.82))
		var dr: Rect2 = MapData.NAVE_EXIT_RECT
		canvas.draw_rect(dr.grow(4.0), Color(0.24, 0.22, 0.25))
		canvas.draw_rect(dr, Color(0.32, 0.19, 0.12))
		canvas.draw_rect(Rect2(dr.position.x + 4, dr.position.y + 3, dr.size.x * 0.5 - 5, dr.size.y - 6), Color(0.44, 0.27, 0.16))
		canvas.draw_rect(Rect2(dr.get_center().x + 1, dr.position.y + 3, dr.size.x * 0.5 - 5, dr.size.y - 6), Color(0.44, 0.27, 0.16))
		canvas.draw_line(Vector2(dr.get_center().x, dr.position.y), Vector2(dr.get_center().x, dr.end.y), Color(0.16, 0.10, 0.08), 2.0)
		canvas.draw_circle(Vector2(dr.get_center().x - 6, dr.get_center().y), 2.4, Color(0.88, 0.72, 0.28))
		canvas.draw_circle(Vector2(dr.get_center().x + 6, dr.get_center().y), 2.4, Color(0.88, 0.72, 0.28))


static func _draw_wall_span_h(canvas: Node2D, x0: float, x1: float, y: float, tex: Texture2D) -> void:
	if tex == null:
		return
	var px := x0
	while px < x1 - 1.0:
		var w := minf(32.0, x1 - px)
		canvas.draw_texture_rect_region(tex, Rect2(px, y, w, 36.0), Rect2(0, 0, w, float(tex.get_height())))
		px += 32.0


static func _draw_wall_span_v(canvas: Node2D, x: float, y0: float, y1: float, tex: Texture2D) -> void:
	if tex == null:
		return
	var py := y0
	while py < y1 - 1.0:
		var h := minf(32.0, y1 - py)
		canvas.draw_texture_rect_region(tex, Rect2(x, py, 36.0, h), Rect2(0, 0, float(tex.get_width()), h))
		py += 32.0


static func draw_region_entities(r, t_now: float) -> void:
	var assets = r.assets
	var font: Font = assets.get_ui_font()
	var cam_rect: Rect2 = r.get_camera_rect(180.0)
	var fl: int = int(r.current_floor)

	if fl == 0:
		_draw_floor0_nave(r, assets, font, t_now, cam_rect)
	elif fl == 1:
		_draw_floor1_catacombs(r, assets, font, t_now, cam_rect)
	else:
		_draw_floor2_library(r, assets, font, t_now, cam_rect)

	for sp: Dictionary in r.fx_sparks:
		var sp_p := Vector2(sp["pos"])
		if cam_rect.has_point(sp_p):
			var col := Color(sp["col"])
			col.a *= clampf(float(sp["life"]) / float(sp["max_life"]), 0.0, 1.0)
			r.draw_circle(sp_p, float(sp["sz"]), col)

	r.draw_interact_bubble_if_active(font)


static func _draw_floor0_nave(r, assets, _font: Font, t_now: float, _cam: Rect2) -> void:
	var lit_ratio: float = clampf(float(r.nave_candles_lit_count()) / 4.0, 0.25, 1.0)
	for wx: float in [240.0, 360.0, 600.0, 720.0]:
		var beam := PackedVector2Array([
			Vector2(wx - 10, 132), Vector2(wx + 10, 132),
			Vector2(wx + 24, 240), Vector2(wx - 24, 240),
		])
		r.draw_colored_polygon(beam, Color(0.56, 0.72, 0.96, 0.12 * lit_ratio))

	var st_tex: Texture2D = assets.get_tex("prop_crypt_stairs.png")
	if st_tex != null and float(r.altar_slide_k) > 0.05:
		r.draw_texture_rect(st_tex, Rect2(MapData.ALTAR_STAIRS_POS - Vector2(24, 26), Vector2(48, 52)), false)

	var altar_pos := MapData.ALTAR_POS - Vector2(float(r.altar_slide_k) * 64.0, 0.0)
	var drawables: Array[Dictionary] = [{"kind": "altar", "pos": altar_pos, "y": altar_pos.y + 20.0}]
	for pw: Rect2 in MapData.get_nave_pews():
		drawables.append({"kind": "pew", "rect": pw, "y": pw.end.y})
	var candles := MapData.get_nave_candles()
	for ci in range(candles.size()):
		drawables.append({"kind": "candle", "pos": candles[ci], "lit": bool(r.nave_candles[ci]), "y": candles[ci].y + 12.0})
	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))

	var pew_tex: Texture2D = assets.get_tex("prop_church_pew.png")
	var altar_tex: Texture2D = assets.get_tex("prop_stained_altar.png")
	for d: Dictionary in drawables:
		var k := String(d["kind"])
		if k == "pew" and pew_tex != null:
			r.draw_texture_rect(pew_tex, d["rect"], false)
		elif k == "altar" and altar_tex != null:
			r.draw_texture_rect(altar_tex, Rect2(Vector2(d["pos"]) - Vector2(48, 28), Vector2(96, 56)), false)
		elif k == "candle":
			_draw_candelabra(r, assets, Vector2(d["pos"]), bool(d["lit"]), t_now)


static func _draw_floor1_catacombs(r, assets, _font: Font, t_now: float, _cam: Rect2) -> void:
	var st_tex: Texture2D = assets.get_tex("prop_crypt_stairs.png")
	if st_tex != null:
		r.draw_texture_rect(st_tex, Rect2(MapData.CRYPT_STAIRS_UP_POS - Vector2(24, 24), Vector2(48, 48)), false)

	var tap_w: Texture2D = assets.get_tex("prop_crypt_tapestry.png")
	if tap_w != null:
		r.draw_texture_rect(tap_w, Rect2(MapData.TAPESTRY_W_POS - Vector2(28, 22), Vector2(56, 46)), false)
	var tap_n: Texture2D = assets.get_tex("prop_crypt_tapestry_treasure.png", "prop_crypt_tapestry.png")
	if tap_n != null:
		r.draw_texture_rect(tap_n, Rect2(MapData.TAPESTRY_N_POS - Vector2(28, 22), Vector2(56, 46)), false)

	var slit_tex: Texture2D = assets.get_tex("prop_dart_trap.png")
	if slit_tex != null:
		for ds: Dictionary in MapData.get_dart_slits():
			r.draw_texture_rect(slit_tex, Rect2(Vector2(ds["pos"]) - Vector2(12, 12), Vector2(24, 24)), false)

	# Draw what lies UNDER EVERY pushed grave directly inside its exposed grave pit!
	var sp_down: Texture2D = assets.get_tex("prop_floor_spikes_down.png")
	var sp_up: Texture2D = assets.get_tex("prop_floor_spikes_up.png")
	var lad_tex: Texture2D = assets.get_tex("prop_hidden_ladder.png")
	var ch_tex: Texture2D = assets.get_tex("prop_treasure_chest_open.png" if GameState.louvain_crypt_treasure_taken else "prop_treasure_chest_closed.png")
	for g: Dictionary in MapData.get_graves_data():
		var gid := String(g["id"])
		if not bool(r.grave_states.get(gid, false)):
			continue
		var gp := Vector2(g["pos"])
		var sec := String(g.get("secret", ""))
		if sec == "library" and lad_tex != null:
			r.draw_texture_rect(lad_tex, Rect2(gp - Vector2(18, 20), Vector2(36, 42)), false)
		elif sec == "treasure" and ch_tex != null:
			if not GameState.louvain_crypt_treasure_taken:
				var gp_glint := 0.5 + 0.5 * sin(t_now * 4.5)
				r.draw_circle(gp, 18.0 + gp_glint * 3.0, Color(1.0, 0.84, 0.32, 0.22 + 0.14 * gp_glint))
			r.draw_texture_rect(ch_tex, Rect2(gp - Vector2(16, 14), Vector2(32, 28)), false)
		else:
			var sprung: bool = float(r.under_grave_traps.get(gid, 0.0)) > 0.0
			var stx: Texture2D = sp_up if sprung else sp_down
			if stx != null:
				r.draw_texture_rect(stx, Rect2(gp - Vector2(17, 15), Vector2(34, 30)), false)

	# Y-sorted Pillars, Torches, and Uniform Sarcophagi
	var drawables: Array[Dictionary] = []
	for pp: Vector2 in MapData.get_crypt_pillars():
		drawables.append({"kind": "pillar", "pos": pp, "y": pp.y + 18.0})
	var torches := MapData.get_crypt_torches()
	for ti in range(torches.size()):
		drawables.append({"kind": "torch", "pos": torches[ti], "lit": bool(r.crypt_torches[ti]), "y": torches[ti].y + 12.0})
	for g: Dictionary in MapData.get_graves_data():
		var gid := String(g["id"])
		var off_y: float = float(r.grave_anim_offsets.get(gid, 0.0))
		var gp := Vector2(g["pos"]) + Vector2(0.0, -off_y)
		drawables.append({"kind": "grave", "crest": String(g["crest"]), "pos": gp, "y": gp.y + 22.0})
	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))

	var pil_tex: Texture2D = assets.get_tex("prop_crypt_pillar.png")
	for d: Dictionary in drawables:
		var k := String(d["kind"])
		if k == "pillar" and pil_tex != null:
			r.draw_texture_rect(pil_tex, Rect2(Vector2(d["pos"]) - Vector2(18, 34), Vector2(36, 54)), false)
		elif k == "torch":
			_draw_candelabra(r, assets, Vector2(d["pos"]), bool(d["lit"]), t_now)
		elif k == "grave":
			var gtex: Texture2D = assets.get_tex("prop_sarcophagus_%s.png" % String(d["crest"]))
			if gtex != null:
				r.draw_texture_rect(gtex, Rect2(Vector2(d["pos"]) - Vector2(21, 27), Vector2(42, 54)), false)

	for db: Dictionary in r.trap_bolts:
		var bp := Vector2(db["pos"])
		r.draw_line(bp - Vector2(db["dir"]) * 9.0, bp + Vector2(db["dir"]) * 9.0, Color(0.95, 0.36, 0.28), 2.8)


static func _draw_floor2_library(r, assets, font: Font, _t_now: float, _cam: Rect2) -> void:
	var lad_tex: Texture2D = assets.get_tex("prop_hidden_ladder.png")
	if lad_tex != null:
		r.draw_texture_rect(lad_tex, Rect2(MapData.LIBRARY_LADDER_UP_POS - Vector2(18, 22), Vector2(36, 44)), false)

	var sh_tex: Texture2D = assets.get_tex("prop_library_shelf.png")
	var lc_tex: Texture2D = assets.get_tex("prop_date_lectern.png")
	var desk_tex: Texture2D = assets.get_tex("prop_archive_desk.png", "prop_date_lectern.png")
	var drawables: Array[Dictionary] = [{"kind": "index", "pos": MapData.INDEX_DESK_POS, "y": MapData.INDEX_DESK_POS.y + 16.0}]
	for sh: Dictionary in MapData.get_library_shelves():
		drawables.append({"kind": "shelf", "rect": sh["rect"], "year": String(sh["year"]), "y": Rect2(sh["rect"]).end.y})
	for lc: Dictionary in MapData.get_library_lecterns():
		drawables.append({"kind": "lectern", "pos": lc["pos"], "year": String(lc["year"]), "decree": String(lc["decree"]), "y": Vector2(lc["pos"]).y + 14.0})
	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))

	for d: Dictionary in drawables:
		var k := String(d["kind"])
		if k == "shelf" and sh_tex != null:
			var sr: Rect2 = d["rect"]
			r.draw_texture_rect(sh_tex, sr, false)
			assets.draw_label_shadowed(r, Vector2(sr.get_center().x, sr.position.y - 6.0), "ANNO %s" % String(d["year"]), font, 10, Color(0.96, 0.84, 0.44), true)
		elif k == "index" and desk_tex != null:
			var ip := Vector2(d["pos"])
			r.draw_texture_rect(desk_tex, Rect2(ip - Vector2(21, 16), Vector2(42, 32)), false)
			assets.draw_label_shadowed(r, ip + Vector2(0, -24), "1431 INDEX", font, 10, Color(0.96, 0.86, 0.52), true)
		elif k == "lectern" and lc_tex != null:
			var lp := Vector2(d["pos"])
			var yr := String(d["year"])
			var claimed := (yr == "1422" and GameState.louvain_found_1422) or (yr == "1426" and GameState.louvain_found_1426)
			r.draw_texture_rect(lc_tex, Rect2(lp - Vector2(16, 17), Vector2(32, 34)), false, Color(1.0, 0.94, 0.72) if claimed else Color.WHITE)
			if claimed:
				r.draw_circle(lp + Vector2(0, -14), 10.0, Color(0.98, 0.82, 0.30, 0.32))


static func _draw_candelabra(r, assets, pos: Vector2, lit: bool, t_now: float) -> void:
	var ctex: Texture2D = assets.get_tex("prop_altar_candle.png")
	if ctex != null:
		r.draw_texture_rect(ctex, Rect2(pos - Vector2(11, 26), Vector2(22, 38)), false)
	if lit:
		var flk := 0.85 + 0.15 * sin(t_now * 9.0 + pos.x * 0.05)
		r.draw_circle(pos + Vector2(0, -20), 22.0 * flk, Color(1.0, 0.72, 0.24, 0.26))
		for dx: float in [-5.0, 0.0, 5.0]:
			r.draw_circle(pos + Vector2(dx, -22), 2.8, Color(1.0, 0.92, 0.48, 0.94))


static func _draw_foreground(r, fg: Node2D) -> void:
	if r.player == null or not r.player.visible or (r.ui != null and r.ui.is_blocking_gameplay()):
		return
	var font: Font = r.assets.get_ui_font()
	var cmd_k := GameState.get_action_key_label("dragon_command")
	var push_k := GameState.get_action_key_label("rope_action")
	var ppos: Vector2 = r.player.position
	if int(r.current_floor) == 0:
		var candles := MapData.get_nave_candles()
		for i in range(candles.size()):
			if not bool(r.nave_candles[i]) and ppos.distance_to(candles[i]) <= 86.0:
				r.assets.draw_interact_bubble(fg, candles[i] + Vector2(0, -34), "[%s] Light Altar Candle" % cmd_k, font)
				return
	elif int(r.current_floor) == 1:
		var torches := MapData.get_crypt_torches()
		for i in range(torches.size()):
			if not bool(r.crypt_torches[i]) and ppos.distance_to(torches[i]) <= 86.0:
				r.assets.draw_interact_bubble(fg, torches[i] + Vector2(0, -34), "[%s] Kindle Crypt Torch" % cmd_k, font)
				return
		var g_near: Dictionary = r.find_pushable_grave_near(ppos)
		if not g_near.is_empty():
			r.assets.draw_interact_bubble(fg, Vector2(g_near["pos"]) + Vector2(0, -28), "[%s] Push Tomb Slab" % push_k, font)
