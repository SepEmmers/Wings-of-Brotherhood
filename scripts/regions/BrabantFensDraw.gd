extends RefCounted

## Static ground baking, animated reed-fen water batching, fog wisps, and Y-sorted
## draw passes for Book II Act I Leg 1: Brabant Reed-Fens (2160x1440).

const WORLD_SIZE := Vector2(2160, 1440)


static func get_water_rects() -> Array[Rect2]:
	return [
		Rect2(0, 0, 2160, 250),         # Northern Dijle reed-backwater marsh
		Rect2(0, 1080, 2160, 360),      # Southern flooded peat fens
		Rect2(0, 250, 132, 830),        # Western reed estuary margin
		Rect2(1740, 250, 128, 410),     # East weir channel north of dike bridge
		Rect2(1740, 774, 128, 306),     # East weir channel south of dike bridge
	]


static func get_road_segments() -> Array[Rect2]:
	return [
		Rect2(300, 668, 476, 84),     # West landing pier -> Mill apron
		Rect2(552, 410, 76, 266),     # Spur north to Gold-Sense cairn
		Rect2(1396, 668, 342, 84),    # Sluice gate -> Wooden weir bridge
		Rect2(1874, 668, 286, 84),    # Weir bridge -> East dike toward Louvain
	]


static func setup_layers(r) -> void:
	r.setup_static_ground_chunks(
		Rect2(0, 0, WORLD_SIZE.x, WORLD_SIZE.y),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-3,
		false
	)
	r.setup_water_layer(get_water_rects(), 32.0, -2)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	var marsh_zone := Rect2(0, 0, WORLD_SIZE.x, WORLD_SIZE.y)
	assets.draw_grass_zone(canvas, marsh_zone, false, 41, [])

	# Darker peat damp bands flanking the southern/northern fen pools
	canvas.draw_rect(Rect2(132, 232, 1608, 36), Color(0.14, 0.22, 0.14, 0.45))
	canvas.draw_rect(Rect2(132, 1044, 1608, 44), Color(0.14, 0.22, 0.14, 0.45))

	# Cobblestone ruin apron around the Sheltered Watermill & Courtyard
	var mill_apron := Rect2(760, 430, 598, 430)
	var cob_a: Texture2D = assets.get_tex("tile_cobble.png")
	var cob_b: Texture2D = assets.get_tex("tile_cobble_2.png")
	assets.draw_varied_tiled_rect(canvas, mill_apron, cob_a, cob_b, 32.0, 7)
	canvas.draw_rect(mill_apron, Color(0.24, 0.22, 0.20, 0.65), false, 2.0)

	# Dirt dikes & causeway trails
	var segs: Array = get_road_segments()
	assets.draw_dirt_trail_network(canvas, segs, [mill_apron], [], 19)

	# Western timber landing pier beside Kestrel touchdown point
	var wharf_tex: Texture2D = assets.get_tex("tile_wharf.png")
	var landing_pier := Rect2(140, 646, 172, 128)
	if wharf_tex != null:
		assets.draw_tiled_rect(canvas, landing_pier, wharf_tex, 32.0)
	canvas.draw_rect(landing_pier, Color(0.28, 0.20, 0.12, 0.85), false, 2.0)

	# Wooden weir bridge deck over East Canal (x=1726..1882, y=654..772)
	var bridge_deck := Rect2(1732, 656, 144, 114)
	if wharf_tex != null:
		assets.draw_tiled_rect(canvas, bridge_deck, wharf_tex, 32.0)
	var plank_col := Color(0.32, 0.22, 0.13)
	for py_i in range(4):
		var yline := bridge_deck.position.y + 8.0 + float(py_i) * 32.0
		canvas.draw_line(Vector2(bridge_deck.position.x, yline), Vector2(bridge_deck.end.x, yline), plank_col, 1.5)
	canvas.draw_rect(Rect2(bridge_deck.position + Vector2(0, -6), Vector2(bridge_deck.size.x, 8)), Color(0.36, 0.25, 0.15))
	canvas.draw_rect(Rect2(bridge_deck.position + Vector2(0, bridge_deck.size.y - 2), Vector2(bridge_deck.size.x, 8)), Color(0.36, 0.25, 0.15))

	# Shore stones along water edges
	for wr: Rect2 in get_water_rects():
		canvas.draw_rect(wr.grow(5.0), Color(0.20, 0.26, 0.18, 0.55), false, 4.0)


static func draw_region_entities(r, t_now: float) -> void:
	var assets = r.assets
	var font: Font = assets.get_ui_font()
	var cam_rect: Rect2 = r.get_camera_rect(170.0)

	# Ruined mill cottage & stone perimeter walls
	var cottage_rect: Rect2 = r.MILL_COTTAGE_RECT
	if cam_rect.intersects(cottage_rect.grow(30.0)):
		assets.draw_sprite_building(r, cottage_rect, "bldg_covert_cottage.png", "", font)

	var wall_v: Texture2D = assets.get_tex("prop_wall_v.png")
	for seg: Rect2 in r.SLUICE_WALL_SEGMENTS:
		if cam_rect.intersects(seg.grow(24.0)) and wall_v != null:
			var py := seg.position.y
			while py < seg.end.y - 2.0:
				var h_step := minf(32.0, seg.end.y - py)
				r.draw_texture_rect_region(wall_v, Rect2(seg.position.x, py, seg.size.x, h_step), Rect2(0, 0, float(wall_v.get_width()), h_step))
				py += 32.0

	# Iron sluice gate bars (open / retracted once unbolted)
	var gate_r: Rect2 = r.GATE_RECT
	if cam_rect.intersects(gate_r.grow(32.0)):
		if not GameState.brabant_vent_unlocked:
			r.draw_rect(gate_r, Color(0.14, 0.15, 0.18, 0.92))
			for bx in range(int(gate_r.position.x + 10), int(gate_r.end.x - 4), 14):
				r.draw_line(Vector2(bx, gate_r.position.y), Vector2(bx, gate_r.end.y), Color(0.46, 0.48, 0.54), 3.0)
			r.draw_rect(gate_r, Color(0.56, 0.52, 0.44), false, 2.0)
		else:
			# Rolled-open side bars
			r.draw_rect(Rect2(gate_r.position.x, gate_r.position.y - 12, gate_r.size.x, 14), Color(0.32, 0.34, 0.38))

	# Dragon vent grate in northern sluice stone pier
	var vent_pos: Vector2 = r.VENT_POS
	if cam_rect.has_point(vent_pos):
		var vtex: Texture2D = assets.get_tex("prop_dragon_vent_grate.png")
		if vtex != null:
			r.draw_texture_rect(vtex, Rect2(vent_pos - Vector2(18, 14), Vector2(36, 28)), false)
		if not GameState.brabant_vent_unlocked and GameState.brabant_hatched:
			var shimmer := 0.5 + 0.5 * sin(t_now * 4.4)
			r.draw_arc(vent_pos, 18.0 + shimmer * 3.0, 0.0, TAU, 18, Color(0.96, 0.80, 0.32, 0.45 + 0.30 * shimmer), 1.6)

	# Animated tiny soot-black hatchling zipping behind sluice gate during Vent Crawl
	if float(r.get("vent_dash_t")) > 0.0:
		var prog := 1.0 - clampf(float(r.get("vent_dash_t")) / 0.65, 0.0, 1.0)
		var dash_p := vent_pos.lerp(gate_r.get_center() + Vector2(20, -4), prog)
		r.draw_circle(dash_p, 8.0, Color(0.12, 0.12, 0.14, 0.90))
		r.draw_circle(dash_p, 11.0, Color(0.98, 0.80, 0.32, 0.48 * (1.0 - prog)))

	# Smuggler briar patch & hidden chest (static crisp dry bramble, no random hopping)
	var cache_pos: Vector2 = r.CACHE_POS
	if cam_rect.has_point(cache_pos):
		var ctex: Texture2D = assets.get_tex("prop_crate.png")
		if ctex != null:
			var mod_c := Color(0.65, 0.65, 0.65, 0.8) if GameState.brabant_cache_looted else Color.WHITE
			r.draw_texture_rect(ctex, Rect2(cache_pos - Vector2(16, 14), Vector2(32, 28)), false, mod_c)
	if not GameState.brabant_briar_burned and cam_rect.intersects(Rect2(r.BRIAR_POS - Vector2(44, 34), Vector2(88, 68))):
		var btex: Texture2D = assets.get_tex("prop_bramble_thicket_1.png", "prop_bramble_thicket.png")
		if btex != null:
			r.draw_texture_rect(btex, Rect2(r.BRIAR_POS - Vector2(34, 24), Vector2(68, 48)), false, Color(0.86, 0.78, 0.64))
		if GameState.brabant_hatched and GameState.hatchling_fed_count > 0:
			var glint := 0.5 + 0.5 * sin(t_now * 5.2)
			r.draw_circle(r.BRIAR_POS + Vector2(-10, -6), 2.5, Color(1.0, 0.72, 0.28, 0.45 + 0.35 * glint))
			r.draw_circle(r.BRIAR_POS + Vector2(12, 2), 2.2, Color(1.0, 0.66, 0.24, 0.40 + 0.35 * (1.0 - glint)))

	# Sheltered Wayside Campfire
	var fpos: Vector2 = r.CAMPFIRE_POS
	if cam_rect.has_point(fpos):
		var ff := int(t_now * 6.0) % 2
		var ftex: Texture2D = assets.get_tex("prop_campfire_%d.png" % ff, "prop_campfire_0.png")
		if ftex != null:
			r.draw_texture_rect(ftex, Rect2(fpos - Vector2(21, 18), Vector2(42, 36)), false)
		r.draw_circle(fpos + Vector2(0, -4), 28.0 + sin(t_now * 5.0) * 3.0, Color(1.0, 0.64, 0.22, 0.14))
		if r.hatch_anim_active:
			_draw_hatching_egg_seq(r, fpos + Vector2(38, 8), assets, t_now)
		elif not GameState.brabant_hatched:
			var pulse := 0.5 + 0.5 * sin(t_now * 3.6)
			r.draw_arc(fpos, 26.0 + pulse * 4.0, 0.0, TAU, 24, Color(0.96, 0.80, 0.34, 0.55), 1.8)
		elif GameState.hatchling_fed_count == 0 and r.director != null and r.director.companion != null:
			var cp_pos: Vector2 = Vector2(r.director.companion.global_position) + Vector2(0, -28)
			var h_bob := sin(t_now * 4.5) * 2.5
			r.draw_circle(cp_pos + Vector2(0, h_bob), 10.0, Color(0.14, 0.10, 0.08, 0.85))
			r.draw_arc(cp_pos + Vector2(0, h_bob), 10.5, 0.0, TAU, 16, Color(0.98, 0.78, 0.32, 0.85), 1.4)
			var rtex: Texture2D = assets.get_tex("prop_ration.png", "prop_crate.png")
			if rtex != null:
				r.draw_texture_rect(rtex, Rect2(cp_pos + Vector2(-7, -7 + h_bob), Vector2(14, 14)), false)

	# Distant Louvain West Dike Gate flank stonework & crimson Inquisition lanterns
	if cam_rect.intersects(Rect2(2040, 560, 130, 300)):
		var b_wall: Texture2D = assets.get_tex("prop_wall_v.png")
		for wy: float in [594.0, 774.0]:
			if b_wall != null:
				r.draw_texture_rect(b_wall, Rect2(2092, wy, 58, 72), false)
			r.draw_rect(Rect2(2096, wy + 12, 16, 26), Color(0.58, 0.14, 0.14, 0.92))
			r.draw_circle(Vector2(2092, wy + 34), 16.0, Color(1.0, 0.62, 0.22, 0.18 + 0.06 * sin(t_now * 6.0)))

	# Ancient Gold-Sense cairn NW
	var cairn_pos: Vector2 = r.GOLD_RELIC_POS
	if cam_rect.has_point(cairn_pos):
		var cairn_tex: Texture2D = assets.get_tex("prop_cairn_stone.png")
		if cairn_tex != null:
			r.draw_texture_rect(cairn_tex, Rect2(cairn_pos - Vector2(18, 22), Vector2(36, 36)), false)
		if not r.cairn_relic_claimed:
			var gp := 0.5 + 0.5 * sin(t_now * 4.8)
			r.draw_circle(cairn_pos + Vector2(0, -10), 6.0 + gp * 3.0, Color(0.98, 0.86, 0.36, 0.36 + 0.28 * gp))

	# Stone Way-Braziers
	for bi in range(r.brazier_states.size()):
		var b: Dictionary = r.brazier_states[bi]
		var bp: Vector2 = b["pos"]
		if not cam_rect.has_point(bp):
			continue
		var bt: Texture2D = assets.get_tex("prop_wall_brazier.png")
		if bt != null:
			r.draw_texture_rect(bt, Rect2(bp - Vector2(12, 16), Vector2(24, 28)), false)
		if bool(b.get("lit", false)):
			var flk := 0.5 + 0.5 * sin(t_now * 9.0 + float(bi))
			r.draw_circle(bp + Vector2(0, -12), 16.0 + flk * 4.0, Color(1.0, 0.66, 0.22, 0.26))
			r.draw_circle(bp + Vector2(0, -14), 5.0 + flk * 2.0, Color(1.0, 0.88, 0.42, 0.85))

	# East Milepost Decree Board
	var sign_pos: Vector2 = r.EAST_SIGN_POS
	if cam_rect.has_point(sign_pos):
		var ntex: Texture2D = assets.get_tex("prop_noticeboard.png", "prop_milestone.png")
		if ntex != null:
			r.draw_texture_rect(ntex, Rect2(sign_pos - Vector2(16, 22), Vector2(32, 34)), false)

	# Kestrel courier sprite during Book II intro descent & takeoff
	if r.kestrel_visible:
		var nuzzle_off := Vector2(4.0 * maxf(0.0, sin(t_now * 3.2)), 0.0) if (r.intro_active and r.intro_stage == 1) else Vector2.ZERO
		var kpos: Vector2 = r.kestrel_pos + nuzzle_off + Vector2(0, -r.kestrel_alt)
		if cam_rect.intersects(Rect2(kpos - Vector2(96, 96), Vector2(192, 192))):
			r.draw_circle(r.kestrel_pos + Vector2(0, 12), clampf(38.0 - r.kestrel_alt * 0.1, 14.0, 38.0), Color(0.03, 0.04, 0.06, 0.32))
			var kf := int(t_now * (10.0 if r.kestrel_alt > 6.0 else 3.2)) % 2
			var ktex: Texture2D = assets.get_tex("dragon_greyling_y5_%d.png" % kf, "dragon_greyling_%d.png" % kf)
			if ktex != null:
				r.draw_texture_rect(ktex, Rect2(kpos - Vector2(44, 38), Vector2(88, 72)), false)

	# Warm golden aura around cradled egg before hatching at midnight
	if not GameState.brabant_hatched and r.player != null and not r.player.cutscene_hidden:
		var ep: Vector2 = Vector2(r.player.position) + Vector2(0, -10)
		if cam_rect.has_point(ep):
			var ep_pulse := 0.5 + 0.5 * sin(t_now * 4.2)
			r.draw_circle(ep, 17.0 + ep_pulse * 3.0, Color(0.98, 0.80, 0.34, 0.14 + 0.08 * ep_pulse))

	# Reeds, river stones & fen trees (culled tightly to cam_rect)
	var stone_tex: Texture2D = assets.get_tex("prop_river_stone_0.png")
	var fern_tex: Texture2D = assets.get_tex("prop_fern_cluster.png")
	for pt: Vector2 in r.REED_CLUMPS:
		if not cam_rect.has_point(pt):
			continue
		if fern_tex != null:
			r.draw_texture_rect(fern_tex, Rect2(pt - Vector2(14, 14), Vector2(28, 22)), false, Color(0.76, 0.86, 0.72, 0.88))
		elif stone_tex != null:
			r.draw_texture_rect(stone_tex, Rect2(pt - Vector2(12, 10), Vector2(24, 20)), false)

	var pine_tex: Texture2D = assets.get_tex("prop_pine_dark.png", "prop_pine_tree.png")
	for tp: Vector2 in r.FEN_TREES:
		if not cam_rect.intersects(Rect2(tp - Vector2(56, 92), Vector2(112, 118))):
			continue
		if tp.y > r.player.position.y + 8.0:
			continue
		if pine_tex != null:
			r.draw_circle(tp + Vector2(0, 4), 22.0, Color(0.04, 0.06, 0.08, 0.30))
			r.draw_texture_rect(pine_tex, Rect2(tp.x - 38, tp.y - 82, 76, 92), false)

	# Particles (embers, smoke, shards)
	for ptc: Dictionary in r.fx_particles:
		var pp: Vector2 = Vector2(ptc["pos"])
		if not cam_rect.has_point(pp):
			continue
		var a := clampf(float(ptc["life"]) / float(ptc["max_life"]), 0.0, 1.0)
		var col: Color = Color(ptc["col"])
		col.a *= a
		r.draw_circle(pp, float(ptc["sz"]) * (0.5 + 0.5 * a), col)

	r.draw_interact_bubble_if_active(font)


static func _draw_hatching_egg_seq(r, pos: Vector2, assets, t_now: float) -> void:
	var st: int = r.hatch_anim_stage
	var wobble := Vector2(sin(t_now * 28.0) * 2.5, 0.0) if st < 3 else Vector2.ZERO
	var etex_name := "prop_dragon_egg.png"
	if st == 1:
		etex_name = "prop_dragon_egg_crack1.png"
	elif st == 2:
		etex_name = "prop_dragon_egg_crack2.png"
	elif st >= 3:
		etex_name = "prop_dragon_egg_shards.png"
	var etex: Texture2D = assets.get_tex(etex_name, "prop_dragon_egg.png")
	if etex != null:
		r.draw_texture_rect(etex, Rect2(pos + wobble - Vector2(16, 20), Vector2(32, 32)), false)
	if st >= 2:
		r.draw_circle(pos + Vector2(0, -6), 24.0 + sin(t_now * 10.0) * 4.0, Color(1.0, 0.84, 0.34, 0.36))
	if st >= 3:
		var htex: Texture2D = assets.get_tex("dragon_gold_s1_down_0.png")
		if htex != null:
			r.draw_texture_rect(htex, Rect2(pos + Vector2(-18, -32), Vector2(36, 33)), false)


static func _draw_foreground(r, fg: Node2D) -> void:
	var assets = r.assets
	var cam_rect: Rect2 = r.get_camera_rect(180.0)
	var pine_tex: Texture2D = assets.get_tex("prop_pine_dark.png", "prop_pine_tree.png")
	if pine_tex != null:
		for tp: Vector2 in r.FEN_TREES:
			if tp.y <= r.player.position.y + 8.0:
				continue
			if not cam_rect.intersects(Rect2(tp - Vector2(56, 92), Vector2(112, 118))):
				continue
			fg.draw_texture_rect(pine_tex, Rect2(tp.x - 38, tp.y - 82, 76, 92), false)
	# Foreground roof overhang on the ruined mill cottage
	var ctex: Texture2D = assets.get_tex("bldg_covert_cottage.png")
	if ctex != null and cam_rect.intersects(r.MILL_COTTAGE_RECT.grow(24.0)):
		r.draw_building_roof_overhang(fg, r.MILL_COTTAGE_RECT, ctex, 0.44)
	r._draw_portal_hints(fg)
	_draw_integrated_prompts(r, fg)


static func _draw_integrated_prompts(r, fg: Node2D) -> void:
	if r.player == null or not r.player.visible or (r.ui != null and r.ui.is_blocking_gameplay()):
		return
	if not GameState.brabant_hatched:
		return
	var ppos: Vector2 = r.player.position
	var font: Font = r.assets.get_ui_font()
	var cmd_k := GameState.get_action_key_label("dragon_command")
	var post_k := GameState.get_action_key_label("dragon_posture")

	if not GameState.brabant_briar_burned and GameState.hatchling_fed_count > 0 and ppos.distance_to(r.BRIAR_POS) <= 115.0:
		r.assets.draw_interact_bubble(fg, r.BRIAR_POS + Vector2(0, -34), "[%s] Kindle Dry Briar" % cmd_k, font)
	elif not GameState.brabant_vent_unlocked and (ppos.distance_to(r.VENT_POS) <= 130.0 or ppos.distance_to(r.GATE_RECT.get_center()) <= 115.0):
		r.assets.draw_interact_bubble(fg, r.VENT_POS + Vector2(0, -32), "[%s] Send Through Grate" % cmd_k, font)
	elif GameState.hatchling_fed_count > 0:
		for b: Dictionary in r.brazier_states:
			if not bool(b.get("lit", false)) and ppos.distance_to(Vector2(b["pos"])) <= 105.0:
				r.assets.draw_interact_bubble(fg, Vector2(b["pos"]) + Vector2(0, -32), "[%s] Kindle Brazier" % cmd_k, font)
				break

	if GameState.brabant_vent_unlocked and ppos.x >= 1915.0 and GameState.companion_posture != "sling" and not GameState.brabant_sling_practiced:
		r.assets.draw_interact_bubble(fg, ppos + Vector2(0, -48), "[%s] Tuck Into Cloak-Sling" % post_k, font)
