extends RefCounted

## Static ground chunk baker, animated Dijle River water layer, Y-sorted buildings,
## foundry kiln glows, Scriptorium Archive puzzle visuals, Catchpole patrols,
## and combat overlays for Louvain City (2400x1800).

const MapData := preload("res://scripts/regions/LouvainCityMapData.gd")


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


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	var interior := Rect2(84, 84, 2232, 1632)
	assets.draw_grass_zone(canvas, Rect2(0, 0, MapData.WORLD_SIZE.x, MapData.WORLD_SIZE.y), false, 29, [interior.grow(16.0)])

	var cob_a: Texture2D = assets.get_tex("tile_cobble.png")
	var cob_b: Texture2D = assets.get_tex("tile_cobble_2.png")
	var slate_tex: Texture2D = assets.get_tex("tile_frost_slate.png")

	canvas.draw_rect(interior.grow(6.0), Color(0.18, 0.17, 0.19))
	assets.draw_varied_tiled_rect(canvas, interior, cob_a, cob_b, 32.0, 7, slate_tex)

	for lawn: Rect2 in MapData.get_garden_lawns():
		canvas.draw_rect(lawn.grow(3.0), Color(0.24, 0.22, 0.20))
		assets.draw_grass_zone(canvas, lawn, true, 17, [])

	for rd: Rect2 in MapData.get_roads():
		canvas.draw_rect(rd.grow(2.0), Color(0.16, 0.15, 0.17))
		assets.draw_varied_tiled_rect(canvas, rd, cob_a, cob_b, 32.0, 11)

	for pl: Dictionary in MapData.get_plazas():
		var pr: Rect2 = pl["rect"]
		if String(pl.get("style", "cobble")) == "flagstone":
			assets.draw_varied_tiled_rect(canvas, pr, slate_tex if slate_tex != null else cob_b, cob_a, 32.0, 5)
		else:
			assets.draw_varied_tiled_rect(canvas, pr, cob_b, cob_a, 32.0, 13, slate_tex)
		canvas.draw_rect(pr, Color(0.56, 0.50, 0.38, 0.55), false, 2.0)

	# Dijle stone embankment edges & river clay slip
	for wr: Rect2 in MapData.get_water_rects():
		canvas.draw_rect(wr.grow(7.0), Color(0.25, 0.24, 0.26))
		canvas.draw_rect(wr.grow(3.0), Color(0.39, 0.37, 0.38))
	canvas.draw_circle(MapData.CLAY_BANK_POS, 26.0, Color(0.32, 0.26, 0.21, 0.72))


static func draw_region_entities(r, t_now: float) -> void:
	var assets = r.assets
	var font: Font = assets.get_ui_font()
	var cam_rect: Rect2 = r.get_camera_rect(180.0)

	# Bridges
	for br: Dictionary in MapData.get_bridges():
		var br_r: Rect2 = br["rect"]
		if cam_rect.intersects(br_r.grow(24.0)):
			var btex: Texture2D = assets.get_tex(String(br["tex"]))
			if btex != null:
				r.draw_texture_rect(btex, br_r, false)

	# City Curtain Walls & Abbey Walls
	var wall_h: Texture2D = assets.get_tex("prop_wall_h.png")
	var wall_v: Texture2D = assets.get_tex("prop_wall_v.png")
	for w: Dictionary in MapData.get_outer_walls():
		if String(w["kind"]) != "wall":
			continue
		var wr: Rect2 = w["rect"]
		if cam_rect.intersects(wr.grow(24.0)):
			_draw_wall_tiled(r, wr, wall_h, wall_v)
	for aw: Rect2 in MapData.get_abbey_walls():
		if cam_rect.intersects(aw.grow(24.0)):
			_draw_wall_tiled(r, aw, wall_h, wall_v)

	# Abbey Iron Gatehouse Piers, Raising Bars, Inside Lever & Culvert Drain Grate
	var ag: Rect2 = MapData.ABBEY_GATE_RECT
	if cam_rect.intersects(ag.grow(72.0)):
		var pier_h: Texture2D = assets.get_tex("prop_gatehouse_pier_h.png")
		if pier_h != null:
			r.draw_texture_rect(pier_h, Rect2(ag.position.x - 36.0, ag.position.y - 6.0, 44.0, 48.0), false)
			r.draw_texture_rect(pier_h, Rect2(ag.end.x - 8.0, ag.position.y - 6.0, 44.0, 48.0), false)
		var open_k := clampf(float(r.abbey_gate_open_anim), 0.0, 1.0)
		var curr_w := lerpf(ag.size.x, 12.0, open_k)
		if open_k < 0.98:
			r.draw_rect(Rect2(ag.position.x, ag.position.y, curr_w, ag.size.y), Color(0.14, 0.14, 0.18, 0.88))
			for gx in range(int(ag.position.x + 10), int(ag.position.x + curr_w - 4), 14):
				r.draw_line(Vector2(gx, ag.position.y), Vector2(gx, ag.end.y), Color(0.48, 0.50, 0.56), 3.0)
		var lever_p: Vector2 = r.ABBEY_LEVER_POS
		var tripped: bool = open_k > 0.25 or bool(r.get("_abbey_lever_tripped"))
		r.draw_line(Vector2(ag.end.x - 4, ag.position.y + 8), lever_p, Color(0.38, 0.36, 0.34), 2.2)
		r.draw_rect(Rect2(lever_p - Vector2(6, 6), Vector2(12, 12)), Color(0.24, 0.23, 0.26))
		var tip := lever_p + (Vector2(12, -13) if tripped else Vector2(-12, -13))
		r.draw_line(lever_p, tip, Color(0.56, 0.54, 0.52), 3.0)
		r.draw_circle(tip, 4.0, Color(0.42, 0.78, 0.48) if tripped else Color(0.92, 0.36, 0.24))

	if cam_rect.intersects(Rect2(MapData.ABBEY_VENT_POS - Vector2(44, 44), Vector2(88, 88))):
		r.draw_rect(Rect2(MapData.ABBEY_VENT_POS.x - 20, 694, 40, 42), Color(0.26, 0.25, 0.28))
		r.draw_rect(Rect2(MapData.ABBEY_VENT_POS.x - 12, 696, 24, 38), Color(0.06, 0.08, 0.09, 0.94))
		var vtex: Texture2D = assets.get_tex("prop_dragon_vent_grate.png")
		if vtex != null:
			r.draw_texture_rect(vtex, Rect2(MapData.ABBEY_VENT_POS + Vector2(-12, 6), Vector2(24, 18)), false)
			r.draw_texture_rect(vtex, Rect2(MapData.ABBEY_VENT_POS + Vector2(-12, -22), Vector2(24, 16)), false, Color(0.76, 0.78, 0.80, 0.85))
		if not GameState.louvain_vent_opened:
			var sh := 0.5 + 0.5 * sin(t_now * 4.2)
			r.draw_arc(MapData.ABBEY_VENT_POS + Vector2(0, 14), 14.0 + sh * 3.0, 0.0, TAU, 18, Color(0.96, 0.80, 0.34, 0.50), 1.6)

	if float(r.get("abbey_vent_crawl_t")) > 0.0:
		var prog := 1.0 - clampf(float(r.get("abbey_vent_crawl_t")) / float(r.ABBEY_VENT_CRAWL_DUR), 0.0, 1.0)
		var step_i := int(t_now * 14.0) % 2
		var dp := MapData.ABBEY_VENT_POS
		var dkey := "up"
		var flip_d := false
		var in_t := false
		if prog < 0.22:
			dp = (MapData.ABBEY_VENT_POS + Vector2(0, 34)).lerp(MapData.ABBEY_VENT_POS + Vector2(0, 8), prog / 0.22)
		elif prog < 0.44:
			in_t = true
			dp = (MapData.ABBEY_VENT_POS + Vector2(0, 8)).lerp(MapData.ABBEY_VENT_POS + Vector2(0, -28), (prog - 0.22) / 0.22)
		elif prog < 0.72:
			dkey = "side"
			flip_d = true
			dp = (MapData.ABBEY_VENT_POS + Vector2(0, -28)).lerp(r.ABBEY_LEVER_POS, (prog - 0.44) / 0.28)
		else:
			dkey = "down"
			dp = r.ABBEY_LEVER_POS.lerp(Vector2(1844, 756), (prog - 0.72) / 0.28)
		if in_t:
			r.draw_circle(dp, 7.0, Color(0.10, 0.10, 0.12, 0.86))
			r.draw_circle(dp + Vector2(0, -2), 1.8, Color(0.98, 0.84, 0.34, 0.92))
		else:
			var fname := "dragon_gold_s1_%s_%d.png" % [dkey, step_i]
			var htex: Texture2D = assets.get_tex_flipped(fname) if flip_d else assets.get_tex(fname)
			if htex != null:
				var sz := Vector2(26, 24)
				var ppos := dp - Vector2(sz.x * 0.5, sz.y * 0.7)
				r.draw_texture_rect(htex, Rect2(ppos, sz), false)

	# South Old Heverlee Gate Barricade
	var sb: Rect2 = MapData.SOUTH_GATE_BARRICADE_RECT
	if cam_rect.intersects(sb.grow(24.0)) and not GameState.louvain_breakout_won:
		r.draw_rect(sb, Color(0.18, 0.14, 0.14, 0.92))
		for sx in range(int(sb.position.x + 12), int(sb.end.x - 8), 16):
			r.draw_line(Vector2(sx, sb.position.y), Vector2(sx, sb.end.y), Color(0.56, 0.44, 0.28), 3.5)

	# Buildings
	for b: Dictionary in MapData.get_buildings():
		var br_b: Rect2 = b["rect"]
		if cam_rect.intersects(br_b.grow(30.0)):
			assets.draw_sprite_building(r, br_b, String(b["tex"]), "", font)

	# District Props (Fountain, Bell Mould, Winches, Cauldron, Archive Desk, Braziers, Chest)
	if cam_rect.has_point(MapData.FOUNTAIN_POS):
		var ftex: Texture2D = assets.get_tex("prop_stone_fountain.png")
		if ftex != null:
			r.draw_texture_rect(ftex, Rect2(MapData.FOUNTAIN_POS - Vector2(36, 36), Vector2(72, 72)), false)
	if cam_rect.has_point(MapData.BELL_MOULD_POS):
		var mtex: Texture2D = assets.get_tex("prop_bell_mould.png")
		if mtex != null:
			r.draw_texture_rect(mtex, Rect2(MapData.BELL_MOULD_POS - Vector2(22, 20), Vector2(44, 40)), false)
	if cam_rect.has_point(MapData.FOUNDRY_WINCH_POS):
		var wtex: Texture2D = assets.get_tex("prop_winch_post.png", "prop_rigging_post.png")
		if wtex != null:
			r.draw_texture_rect(wtex, Rect2(MapData.FOUNDRY_WINCH_POS - Vector2(14, 24), Vector2(28, 34)), false)
	if cam_rect.has_point(MapData.HERBALIST_SLUICE_POS):
		var htex: Texture2D = assets.get_tex("prop_herb_cauldron.png")
		if htex != null:
			r.draw_texture_rect(htex, Rect2(MapData.HERBALIST_SLUICE_POS - Vector2(18, 18), Vector2(36, 36)), false)
	if cam_rect.has_point(MapData.CONFISCATED_CHEST_POS):
		var ctex: Texture2D = assets.get_tex("prop_crate.png")
		if ctex != null:
			r.draw_texture_rect(ctex, Rect2(MapData.CONFISCATED_CHEST_POS - Vector2(16, 14), Vector2(32, 28)), false)
	if cam_rect.has_point(MapData.ARCHIVE_DESK_POS):
		var atex: Texture2D = assets.get_tex("prop_archive_desk.png")
		if atex != null:
			r.draw_texture_rect(atex, Rect2(MapData.ARCHIVE_DESK_POS - Vector2(22, 16), Vector2(44, 32)), false)
	if cam_rect.has_point(MapData.SOUTH_SIGN_POS):
		var stex: Texture2D = assets.get_tex("prop_milestone.png", "prop_noticeboard.png")
		if stex != null:
			r.draw_texture_rect(stex, Rect2(MapData.SOUTH_SIGN_POS - Vector2(14, 20), Vector2(28, 30)), false)

	for bz: Vector2 in r.ABBEY_BRAZIERS:
		if not cam_rect.has_point(bz):
			continue
		var bt: Texture2D = assets.get_tex("prop_wall_brazier.png")
		if bt != null:
			r.draw_texture_rect(bt, Rect2(bz - Vector2(11, 15), Vector2(22, 26)), false)
		if GameState.louvain_brazier_lit:
			r.draw_circle(bz + Vector2(0, -10), 18.0 + sin(t_now * 8.0) * 3.0, Color(1.0, 0.70, 0.24, 0.28))
			r.draw_circle(bz + Vector2(0, -12), 5.5, Color(1.0, 0.90, 0.44, 0.88))

	# NPCs
	var npc_specs := [
		{"pos": r.NPC_PIETER_POS, "tex": "npc_city_cooper.png", "flip": false},
		{"pos": r.NPC_ALEIDIS_POS, "tex": "npc_city_fishwife.png", "flip": false},
		{"pos": r.NPC_MARTIJN_POS, "tex": "npc_city_sailor.png", "flip": true},
		{"pos": r.NPC_KATELIJNE_POS, "tex": "npc_city_apothecary.png", "flip": true},
	]
	for n: Dictionary in npc_specs:
		var np: Vector2 = n["pos"]
		if cam_rect.has_point(np):
			assets.draw_npc_sprite(r, np, String(n["tex"]), "", font, Color.WHITE, bool(n["flip"]))

	# Wanted Posters, Lure Chimes & Smoke Clouds via CityHeatHelper
	r.heat_helper.draw_overlays(r, assets)

	# Patrol Guards + Vision Cones (prior to breakout victory)
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
			var gtex: String = "npc_church_hunter_%d.png" % walk_f
			assets.draw_npc_sprite(r, gp, gtex, "", font, Color.WHITE, gdir.x < -0.1)
			if snared_p:
				r.draw_arc(gp + Vector2(0, -10), 11.0, 0.0, TAU, 16, Color(0.76, 0.62, 0.34), 2.4)
				r.draw_arc(gp + Vector2(0, -4), 9.0, 0.0, TAU, 14, Color(0.45, 0.86, 0.64), 1.8)

	# Breakout Ambush Catchpoles
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
			var a := clampf(float(sp["life"]) / float(sp["max_life"]), 0.0, 1.0)
			var col: Color = Color(sp["col"])
			col.a *= a
			r.draw_circle(sp_p, float(sp["sz"]), col)

	if r.resonance_wave_t > 0.0:
		var wp: float = 1.0 - (float(r.resonance_wave_t) / 1.1)
		r.draw_arc(Vector2(r.resonance_wave_origin), 24.0 + wp * 280.0, 0.0, TAU, 36, Color(1.0, 0.88, 0.38, 1.0 - wp), 4.0)

	r.draw_interact_bubble_if_active(font)


static func _draw_wall_tiled(canvas: Node2D, wr: Rect2, wall_h: Texture2D, wall_v: Texture2D) -> void:
	var is_h := wr.size.x >= wr.size.y
	var tex := wall_h if is_h else wall_v
	if tex == null:
		canvas.draw_rect(wr, Color(0.32, 0.31, 0.35))
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
