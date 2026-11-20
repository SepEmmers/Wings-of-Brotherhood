extends RefCounted

## Subterranean basalt & golden sandstone chamber drawer for OldHeverleeShrineRegion:
## Static baked floor chunks + repeating subterranean water chasm + Devil-Ritual Bas-Relief,
## pushable Keystone Boulder, Bronze Weight Plate, Serpent Vent, Twin Braziers, and Shrine Key.

const MapData := preload("res://scripts/regions/OldHeverleeShrineMapData.gd")


static func setup_layers(r) -> void:
	var created_water := r.get_node_or_null("EnvWaterLayer") == null
	r.setup_water_layer([MapData.CHASM_RECT], 48.0, -3)
	if created_water:
		r.step_water_layer()
	r.setup_static_ground_chunks(
		Rect2(0, 0, MapData.WORLD_SIZE.x, MapData.WORLD_SIZE.y),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-2,
		true
	)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	# Opaque obsidian void everywhere EXCEPT Room 2 Water Chasm (so -3 WaterBackdropLayer shines cleanly!)
	canvas.draw_rect(Rect2(0, 0, MapData.CHASM_RECT.position.x, MapData.WORLD_SIZE.y), Color(0.04, 0.04, 0.06))
	canvas.draw_rect(Rect2(MapData.CHASM_RECT.end.x, 0, MapData.WORLD_SIZE.x - MapData.CHASM_RECT.end.x, MapData.WORLD_SIZE.y), Color(0.04, 0.04, 0.06))
	canvas.draw_rect(Rect2(MapData.CHASM_RECT.position.x, 0, MapData.CHASM_RECT.size.x, MapData.CHASM_RECT.position.y), Color(0.04, 0.04, 0.06))
	canvas.draw_rect(Rect2(MapData.CHASM_RECT.position.x, MapData.CHASM_RECT.end.y, MapData.CHASM_RECT.size.x, MapData.WORLD_SIZE.y - MapData.CHASM_RECT.end.y), Color(0.04, 0.04, 0.06))

	var bas1: Texture2D = assets.get_tex("tile_catacomb_stone.png", "tile_lair_basalt.png")
	var bas2: Texture2D = assets.get_tex("tile_catacomb_stone_2.png", "tile_catacomb_stone.png")
	var wall_h: Texture2D = assets.get_tex("prop_wall_h.png")
	var wall_v: Texture2D = assets.get_tex("prop_wall_v.png")

	for fl: Rect2 in MapData.get_room_floors():
		if fl.intersects(MapData.CHASM_RECT):
			# Draw Room 2 left and right of chasm cleanly so water chasm remains transparent!
			var r_l := Rect2(fl.position.x, fl.position.y, MapData.CHASM_RECT.position.x - fl.position.x, fl.size.y)
			var r_r := Rect2(MapData.CHASM_RECT.end.x, fl.position.y, fl.end.x - MapData.CHASM_RECT.end.x, fl.size.y)
			assets.draw_varied_tiled_rect(canvas, r_l, bas1, bas2, 32.0, 9)
			assets.draw_varied_tiled_rect(canvas, r_r, bas1, bas2, 32.0, 11)
		else:
			assets.draw_varied_tiled_rect(canvas, fl, bas1, bas2, 32.0, 9)
		# Golden inlaid trim strip around chamber edge
		canvas.draw_rect(fl, Color(0.84, 0.68, 0.28, 0.55), false, 2.0)

	# Perimeter stone masonry rim + interior room dividers
	for wall_x: Array in [[112.0, 534.0], [572.0, 1068.0], [1106.0, 1492.0]]:
		_span_h(canvas, float(wall_x[0]), float(wall_x[1]), 116.0, wall_h)
		_span_h(canvas, float(wall_x[0]), float(wall_x[1]), 808.0, wall_h)
	_span_v(canvas, 76.0, 152.0, 808.0, wall_v)
	_span_v(canvas, 1492.0, 152.0, 808.0, wall_v)
	_span_v(canvas, 534.0, 152.0, 434.0, wall_v)
	_span_v(canvas, 534.0, 526.0, 808.0, wall_v)
	_span_v(canvas, 1068.0, 152.0, 434.0, wall_v)
	_span_v(canvas, 1068.0, 526.0, 808.0, wall_v)

	# Golden chasm bank rims
	canvas.draw_line(MapData.CHASM_RECT.position, MapData.CHASM_RECT.position + Vector2(0, MapData.CHASM_RECT.size.y), Color(0.84, 0.68, 0.30), 3.0)
	canvas.draw_line(Vector2(MapData.CHASM_RECT.end.x, MapData.CHASM_RECT.position.y), MapData.CHASM_RECT.end, Color(0.84, 0.68, 0.30), 3.0)

	# Sun-serpent floor mosaic in Sanctum Room 3
	canvas.draw_circle(MapData.PEDESTAL_POS, 72.0, Color(0.84, 0.68, 0.26, 0.18))
	canvas.draw_arc(MapData.PEDESTAL_POS, 64.0, 0.0, TAU, 36, Color(0.92, 0.76, 0.34, 0.55), 2.5)


static func _span_h(canvas: Node2D, x0: float, x1: float, y: float, tex: Texture2D) -> void:
	if tex == null:
		return
	var px := x0
	while px < x1 - 1.0:
		var w := minf(32.0, x1 - px)
		canvas.draw_texture_rect_region(tex, Rect2(px, y, w, 36.0), Rect2(0, 0, w, float(tex.get_height())))
		px += 32.0


static func _span_v(canvas: Node2D, x: float, y0: float, y1: float, tex: Texture2D) -> void:
	if tex == null:
		return
	var py := y0
	while py < y1 - 1.0:
		var h := minf(32.0, y1 - py)
		canvas.draw_texture_rect_region(tex, Rect2(x, py, 36.0, h), Rect2(0, 0, float(tex.get_width()), h))
		py += 32.0


static func draw_region_entities(r, t_now: float) -> void:
	var assets = r.assets

	# South Exit Stairs & Secret East Exit Stairs
	var st_tex: Texture2D = assets.get_tex("prop_crypt_stairs.png")
	if st_tex != null:
		r.draw_texture_rect(st_tex, Rect2(MapData.EXIT_SOUTH_RECT.get_center() - Vector2(24, 22), Vector2(48, 44)), false)
		if GameState.boy_heverlee_relic_found:
			r.draw_texture_rect(st_tex, Rect2(MapData.BACK_STAIRS_RECT.get_center() - Vector2(24, 22), Vector2(48, 44)), false)

	# Devildragon Ritual Relief (Room 1 North Wall) + Bronze Plate + Serpent Vent
	var rel_tex: Texture2D = assets.get_tex("prop_devildragon_relief.png")
	if rel_tex != null:
		r.draw_texture_rect(rel_tex, Rect2(MapData.RELIEF_POS - Vector2(44, 34), Vector2(88, 68)), false)

	var pl_tex: Texture2D = assets.get_tex("prop_weight_plate_down.png" if r.plate_pressed else "prop_weight_plate_up.png")
	if pl_tex != null:
		r.draw_texture_rect(pl_tex, Rect2(MapData.PLATE_POS - Vector2(18, 15), Vector2(36, 30)), false)

	var sv_tex: Texture2D = assets.get_tex("prop_shrine_serpent_vent.png")
	if sv_tex != null:
		var vcol := Color.WHITE if r.plate_pressed or GameState.shrine_gate1_open else Color(0.62, 0.62, 0.68)
		r.draw_texture_rect(sv_tex, Rect2(MapData.SERPENT_VENT_POS - Vector2(18, 15), Vector2(36, 30)), false, vcol)

	# Gate 1 & Gate 2 Vault Doors
	var g1_tex: Texture2D = assets.get_tex("prop_shrine_door_open.png" if GameState.shrine_gate1_open else "prop_shrine_door_shut.png")
	if g1_tex != null:
		r.draw_texture_rect(g1_tex, Rect2(MapData.GATE1_RECT.get_center() - Vector2(26, 38), Vector2(52, 76)), false)
	var g2_tex: Texture2D = assets.get_tex("prop_shrine_door_open.png" if GameState.shrine_gate2_open else "prop_shrine_door_shut.png")
	if g2_tex != null:
		r.draw_texture_rect(g2_tex, Rect2(MapData.GATE2_RECT.get_center() - Vector2(26, 38), Vector2(52, 76)), false)

	# Chasm Grapple Posts
	var post_tex: Texture2D = assets.get_tex("prop_winch_post.png", "prop_rigging_post.png")
	for cp: Vector2 in [MapData.CHASM_POST_W, MapData.CHASM_POST_E]:
		if post_tex != null:
			r.draw_texture_rect(post_tex, Rect2(cp - Vector2(12, 18), Vector2(24, 30)), false)
		r.draw_circle(cp + Vector2(0, -10), 4.0, Color(0.98, 0.84, 0.34))

	# Y-sorted Keystone Boulder, Twin Sconces, and Sanctum Pedestal + Key
	var drawables: Array[Dictionary] = [
		{"kind": "boulder", "pos": r.boulder_pos, "y": r.boulder_pos.y + 14.0},
		{"kind": "sconce", "pos": MapData.SCONCE_W_POS, "lit": r.sconce_w_lit, "y": MapData.SCONCE_W_POS.y + 14.0},
		{"kind": "sconce", "pos": MapData.SCONCE_E_POS, "lit": r.sconce_e_lit, "y": MapData.SCONCE_E_POS.y + 14.0},
		{"kind": "pedestal", "pos": MapData.PEDESTAL_POS, "y": MapData.PEDESTAL_POS.y + 16.0},
	]
	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))

	for d: Dictionary in drawables:
		var k := String(d["kind"])
		var dp := Vector2(d["pos"])
		if k == "boulder":
			var bt: Texture2D = assets.get_tex("prop_shrine_boulder.png")
			if bt != null:
				r.draw_texture_rect(bt, Rect2(dp - Vector2(18, 20), Vector2(36, 36)), false)
		elif k == "sconce":
			var lit := bool(d["lit"])
			var st: Texture2D = assets.get_tex("prop_shrine_sconce_on.png" if lit else "prop_shrine_sconce_off.png")
			if st != null:
				r.draw_texture_rect(st, Rect2(dp - Vector2(14, 24), Vector2(28, 38)), false)
			if lit:
				r.draw_circle(dp + Vector2(0, -14), 22.0 + sin(t_now * 8.0) * 3.0, Color(1.0, 0.80, 0.28, 0.26))
		elif k == "pedestal":
			var pt: Texture2D = assets.get_tex("prop_shrine_pedestal.png")
			if pt != null:
				r.draw_texture_rect(pt, Rect2(dp - Vector2(20, 26), Vector2(40, 44)), false)
			if not GameState.boy_heverlee_relic_found:
				var kt: Texture2D = assets.get_tex("prop_shrine_key_relic.png")
				var bob := sin(t_now * 3.8) * 3.0
				r.draw_circle(dp + Vector2(0, -22 + bob), 14.0, Color(1.0, 0.86, 0.34, 0.28))
				if kt != null:
					r.draw_texture_rect(kt, Rect2(dp + Vector2(-11, -33 + bob), Vector2(22, 22)), false)

	for sp: Dictionary in r.fx_sparks:
		var c: Color = sp["col"]
		var a := clampf(float(sp["life"]) / float(sp["max_life"]), 0.0, 1.0)
		r.draw_circle(Vector2(sp["pos"]), float(sp["sz"]), Color(c.r, c.g, c.b, a))


static func _draw_foreground(r, fg: Node2D) -> void:
	if r.player != null and r.player.visible and not (r.ui != null and r.ui.is_blocking_gameplay()):
		r.draw_interact_bubble_if_active_on(fg, r.assets.get_ui_font())
		if not GameState.shrine_gate1_open and r.player.position.distance_to(r.boulder_pos) <= 46.0:
			var push_k := GameState.get_action_key_label("rope_action")
			r.assets.draw_interact_bubble(fg, r.boulder_pos + Vector2(0, -34), "[%s] Push Stone Cube" % push_k, r.assets.get_ui_font())
	r._draw_portal_hints(fg)
