extends RefCounted

## Static forest chunk baker + Zoet Water Creek repeating layer + Y-sorted oaks, pines,
## Parents' Ambush Stump, Shrine Descent Archway, Bramble Thicket & Kestrel Cliffside Roost.

const MapData := preload("res://scripts/regions/OldHeverleeMapData.gd")


static func setup_layers(r) -> void:
	var created_water := r.get_node_or_null("EnvWaterLayer") == null
	r.setup_water_layer(MapData.get_water_rects(), 48.0, -3)
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
	var g1: Texture2D = assets.get_tex("tile_grass.png")
	var g2: Texture2D = assets.get_tex("tile_grass_2.png")
	var g3: Texture2D = assets.get_tex("tile_grass_3.png")
	var st1: Texture2D = assets.get_tex("tile_sandstone_flag.png")
	var st2: Texture2D = assets.get_tex("tile_sandstone_flag_2.png", "tile_sandstone_flag.png")

	# North & South forest grass chunks leaving water channel transparent for -3 WaterBackdropLayer
	assets.draw_varied_tiled_rect(canvas, Rect2(0, 0, MapData.WORLD_SIZE.x, 756), g1, g2, 48.0, 17, g3)
	assets.draw_varied_tiled_rect(canvas, Rect2(0, 840, MapData.WORLD_SIZE.x, MapData.WORLD_SIZE.y - 840.0), g1, g2, 48.0, 23, g3)
	assets.draw_dirt_trail_network(canvas, MapData.get_dirt_trails(), [], [Rect2(0, 744, MapData.WORLD_SIZE.x, 108)], 17)

	# Creek bank mud seams
	canvas.draw_rect(Rect2(0, 744, MapData.WORLD_SIZE.x, 14), Color(0.24, 0.20, 0.14))
	canvas.draw_rect(Rect2(0, 838, MapData.WORLD_SIZE.x, 14), Color(0.24, 0.20, 0.14))

	# West Stone Stepping Ford slabs cleanly spanning the creek
	for fs: Rect2 in MapData.get_ford_stones():
		assets.draw_varied_tiled_rect(canvas, fs, st1, st2, 24.0, 7)
		canvas.draw_rect(fs, Color(0.18, 0.16, 0.14), false, 2.0)

	# Overgrown golden sandstone ruin apron around Shrine entrance & cliffside overlook rock
	canvas.draw_circle(MapData.SHRINE_DOOR_RECT.get_center() + Vector2(0, 26), 92.0, Color(0.42, 0.39, 0.32, 0.48))
	assets.draw_varied_tiled_rect(canvas, Rect2(1078, 1020, 124, 96), st1, st2, 32.0, 5)
	canvas.draw_rect(Rect2(1790, 1110, 150, 118), Color(0.32, 0.34, 0.36, 0.56))
	canvas.draw_rect(Rect2(1856, 1106, 76, 48), Color(0.42, 0.44, 0.46))

	# Fallen autumn leaves & moss flecks across ambush glade
	var rng := RandomNumberGenerator.new()
	rng.seed = 1422
	for _i in range(44):
		var ap := Vector2(rng.randf_range(420, 680), rng.randf_range(380, 580))
		canvas.draw_circle(ap, rng.randf_range(2.2, 4.4), Color(0.56, 0.34, 0.16, 0.48))


static func draw_region_entities(r, t_now: float) -> void:
	var assets = r.assets
	var cam_rect: Rect2 = r.get_camera_rect(180.0)

	# Scorched ambush earth ring + glowing Gold-Sense aura once nearby
	var amb_p: Vector2 = MapData.AMBUSH_STUMP_POS
	if cam_rect.has_point(amb_p):
		r.draw_circle(amb_p, 46.0, Color(0.16, 0.12, 0.10, 0.42))
		if not GameState.heverlee_ambush_inspected:
			var pulse := 0.5 + 0.5 * sin(t_now * 3.8)
			r.draw_arc(amb_p, 26.0 + pulse * 4.0, 0.0, TAU, 24, Color(0.96, 0.80, 0.30, 0.36 + 0.25 * pulse), 2.0)

	for fp: Vector2 in MapData.get_cover_ferns():
		if cam_rect.has_point(fp):
			var ftex: Texture2D = assets.get_tex("prop_fern_cluster.png")
			if ftex != null:
				r.draw_texture_rect(ftex, Rect2(fp - Vector2(18, 14), Vector2(36, 28)), false)

	# Rope Grapple Posts flanking the East Creek Chasm + Rope Bridge Guide Line
	var ptex: Texture2D = assets.get_tex("prop_winch_post.png", "prop_rigging_post.png")
	for rp: Vector2 in [MapData.ROPE_POST_N, MapData.ROPE_POST_S]:
		if cam_rect.has_point(rp):
			if ptex != null:
				r.draw_texture_rect(ptex, Rect2(rp - Vector2(12, 18), Vector2(24, 30)), false)
			r.draw_circle(rp + Vector2(0, -10), 4.0, Color(0.96, 0.82, 0.36))

	var drawables: Array[Dictionary] = []
	for tr: Dictionary in MapData.get_tree_positions():
		var tp := Vector2(tr["pos"])
		if cam_rect.intersects(Rect2(tp - Vector2(40, 80), Vector2(80, 100))):
			drawables.append({"kind": "tree", "pos": tp, "pine": bool(tr["pine"]), "flip": bool(tr["flip"]), "y": tp.y + 10.0})

	drawables.append({"kind": "tex", "tex": "prop_parents_ambush_bow.png", "rect": Rect2(amb_p - Vector2(22, 18), Vector2(44, 34)), "y": amb_p.y + 12.0})
	for lpos: Vector2 in [Vector2(444, 412), Vector2(660, 578), Vector2(980, 224), Vector2(1260, 646), Vector2(1420, 940)]:
		drawables.append({"kind": "tex", "tex": "prop_fallen_log.png", "rect": Rect2(lpos - Vector2(28, 14), Vector2(56, 28)), "y": lpos.y + 10.0})
	drawables.append({"kind": "tex", "tex": "prop_shrine_entrance.png", "rect": Rect2(MapData.SHRINE_DOOR_RECT.get_center() - Vector2(42, 34), Vector2(84, 72)), "y": MapData.SHRINE_DOOR_RECT.end.y})
	drawables.append({"kind": "tex", "tex": "prop_map_table.png", "rect": Rect2(MapData.CIPHER_TABLE_POS - Vector2(24, 16), Vector2(48, 32)), "y": MapData.CIPHER_TABLE_POS.y + 12.0})
	if not GameState.heverlee_briar_burned:
		drawables.append({"kind": "tex", "tex": "prop_bramble_thicket.png", "rect": Rect2(MapData.BRIAR_POS - Vector2(44, 24), Vector2(88, 48)), "y": MapData.BRIAR_POS.y + 16.0})
	drawables.append({"kind": "fire", "pos": MapData.OVERLOOK_FIRE_POS, "y": MapData.OVERLOOK_FIRE_POS.y + 10.0})

	# Kestrel perches silently on cliff rock once Relic Key has been recovered!
	if GameState.boy_heverlee_relic_found and not GameState.heverlee_kestrel_sent:
		var kp: Vector2 = MapData.KESTREL_ROCK_POS
		drawables.append({"kind": "kestrel", "pos": kp, "y": kp.y + 14.0})

	for s: Dictionary in r.scouts:
		if int(s["hp"]) > 0 and cam_rect.has_point(Vector2(s["pos"])):
			drawables.append({"kind": "scout", "data": s, "y": Vector2(s["pos"]).y + 10.0})

	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))

	var tree_p: Texture2D = assets.get_tex("prop_pine_tree.png")
	var tree_o: Texture2D = assets.get_tex("prop_lime_tree.png")
	for d: Dictionary in drawables:
		var k := String(d["kind"])
		if k == "tree":
			var tp := Vector2(d["pos"])
			var tx := tree_p if bool(d["pine"]) else tree_o
			if tx != null:
				if bool(d["flip"]):
					tx = assets.get_tex_flipped("prop_pine_tree.png" if bool(d["pine"]) else "prop_lime_tree.png")
				r.draw_texture_rect(tx, Rect2(tp - Vector2(30, 62), Vector2(60, 76)), false)
		elif k == "tex":
			var dr: Rect2 = d["rect"]
			if cam_rect.intersects(dr.grow(24.0)):
				var tx: Texture2D = assets.get_tex(String(d["tex"]))
				if tx != null:
					r.draw_texture_rect(tx, dr, false)
		elif k == "fire":
			var fp := Vector2(d["pos"])
			var cf: Texture2D = assets.get_tex("prop_campfire_%d.png" % (int(t_now * 6.0) % 2), "prop_campfire_0.png")
			if cf != null:
				r.draw_texture_rect(cf, Rect2(fp - Vector2(18, 18), Vector2(36, 36)), false)
			r.draw_circle(fp + Vector2(0, -6), 24.0 + sin(t_now * 8.0) * 3.0, Color(1.0, 0.72, 0.24, 0.20))
		elif k == "kestrel":
			var kp := Vector2(d["pos"])
			var bob := sin(t_now * 3.0) * 2.0
			var ktex: Texture2D = assets.get_tex("dragon_greyling_%d.png" % (int(t_now * 4.0) % 2), "dragon_greyling.png")
			if ktex != null:
				r.draw_circle(kp + Vector2(0, 12), 16.0, Color(0.04, 0.05, 0.08, 0.36))
				r.draw_texture_rect(ktex, Rect2(kp + Vector2(-24, -22 + bob), Vector2(48, 40)), false)
		elif k == "scout":
			var s: Dictionary = d["data"]
			var sp := Vector2(s["pos"])
			var sdir := Vector2(s["dir"])
			var ntex: String = "npc_inquisitor.png" if String(s["kind"]) == "shield" else "npc_watchman.png"
			assets.draw_npc_sprite(r, sp, ntex, "", assets.get_ui_font(), Color.WHITE, sdir.x < -0.1)
			if bool(s.get("has_shield", false)):
				r.draw_rect(Rect2(sp + Vector2(-12, -16), Vector2(10, 18)), Color(0.56, 0.58, 0.64))
			if bool(s.get("permanently_bound", false)):
				r.draw_arc(sp + Vector2(0, -8), 14.0, 0.0, TAU, 16, Color(0.95, 0.72, 0.24, 0.95), 2.8)
			elif float(s.get("snared_t", 0.0)) > 0.0:
				r.draw_arc(sp, 14.0, 0.0, TAU, 16, Color(0.45, 0.90, 0.72, 0.85), 2.2)

	for b: Dictionary in r.enemy_bolts:
		var bp := Vector2(b["pos"])
		r.draw_line(bp - Vector2(b["dir"]) * 8.0, bp + Vector2(b["dir"]) * 8.0, Color(0.96, 0.36, 0.26), 2.5)
	for sp: Dictionary in r.fx_sparks:
		var c: Color = sp["col"]
		var a := clampf(float(sp["life"]) / float(sp["max_life"]), 0.0, 1.0)
		r.draw_circle(Vector2(sp["pos"]), float(sp["sz"]), Color(c.r, c.g, c.b, a))


static func _draw_foreground(r, fg: Node2D) -> void:
	if r.player != null and r.player.visible and not (r.ui != null and r.ui.is_blocking_gameplay()):
		r.draw_interact_bubble_if_active_on(fg, r.assets.get_ui_font())
	r._draw_portal_hints(fg)
