extends RefCounted

## Dusk Meuse/Brabant Gorge Canvas Renderer for Anna Chapter 1 Blood-Barge Convoy Raid:
## Uses repeating WaterBackdropLayer (-3) + static stone gorge canyon banks (-2)
## + Y-sorted Church Blood-Barges, Acoustic Ward-Bell pulses, Chain-Booms, Wild Dragons & Virelai.

const SKY_BOUNDS := Rect2(80, 80, 2240, 1440)


static func setup_layers(r) -> void:
	var water_created := r.get_node_or_null("EnvWaterLayer") == null
	r.setup_water_layer([Rect2(720, 0, 960, 1600)], 48.0, -3)
	if water_created:
		r.step_water_layer()
	r.setup_static_ground_chunks(
		Rect2(0, 0, 2400, 1600),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-2,
		true
	)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	var g1: Texture2D = assets.get_tex("tile_grass.png")
	var g2: Texture2D = assets.get_tex("tile_grass_2.png")
	var cl: Texture2D = assets.get_tex("tile_lair_basalt.png", "tile_cobble.png")
	assets.draw_varied_tiled_rect(canvas, Rect2(0, 0, 720, 1600), g1, g2, 48.0, 11)
	assets.draw_varied_tiled_rect(canvas, Rect2(1680, 0, 720, 1600), g1, g2, 48.0, 13)
	assets.draw_varied_tiled_rect(canvas, Rect2(680, 0, 48, 1600), cl, cl, 32.0, 5)
	assets.draw_varied_tiled_rect(canvas, Rect2(1672, 0, 48, 1600), cl, cl, 32.0, 7)

	var pine: Texture2D = assets.get_tex("prop_pine_tree.png")
	if pine != null:
		for py: int in range(140, 1520, 220):
			canvas.draw_texture_rect(pine, Rect2(560, py, 52, 68), false)
			canvas.draw_texture_rect(pine, Rect2(1790, py, 52, 68), false)


static func draw_raid(r) -> void:
	var t_now: float = r.assets.time_elapsed
	var cam_rect: Rect2 = r.get_camera_rect(200.0)

	# River Chain-Boom anchors across channel
	var ch_tex: Texture2D = r.assets.get_tex("prop_river_chain_boom.png")
	for bm: Dictionary in r.chain_booms:
		var bp := Vector2(bm["pos"])
		if not cam_rect.has_point(bp):
			continue
		if bool(bm["alive"]):
			r.draw_line(Vector2(720, bp.y), Vector2(1680, bp.y), Color(0.28, 0.30, 0.36, 0.92), 5.0)
			if ch_tex != null:
				for cx: float in [940.0, 1200.0, 1460.0]:
					r.draw_texture_rect(ch_tex, Rect2(Vector2(cx, bp.y) - Vector2(56, 16), Vector2(112, 32)), false)
		else:
			r.draw_circle(bp, 14.0, Color(0.16, 0.14, 0.12, 0.6))

	# Blood-Harvest Ward-Bell Barges + expanding Acoustic Sonar Rings
	var bg_tex: Texture2D = r.assets.get_tex("prop_ward_bell_barge.png")
	for b: Dictionary in r.barges:
		var bp := Vector2(b["pos"])
		if not cam_rect.has_point(bp):
			continue
		if not bool(b["alive"]):
			r.draw_circle(bp, 28.0, Color(0.14, 0.10, 0.08, 0.72))
			r.draw_circle(bp + Vector2(6, -4), 8.0, Color(0.98, 0.46, 0.16, 0.55))
			continue
		var wave_r: float = float(b.get("bell_wave_r", 0.0))
		if wave_r > 4.0:
			var a := clampf(1.0 - wave_r / 240.0, 0.0, 1.0)
			r.draw_arc(bp + Vector2(14, -12), wave_r, 0.0, TAU, 36, Color(0.98, 0.78, 0.24, a * 0.78), 3.5)
		elif float(b.get("bell_charge", 0.0)) > 0.0:
			var p := clampf(float(b["bell_charge"]) / 1.4, 0.0, 1.0)
			r.draw_arc(bp + Vector2(14, -12), 26.0 * (1.2 - p), 0.0, TAU, 22, Color(0.98, 0.44, 0.22, 0.35 + 0.55 * p), 2.5)
		var bmod := Color(1.0, 0.45, 0.45) if float(b.get("flash", 0.0)) > 0.0 else Color.WHITE
		if bg_tex != null:
			r.draw_texture_rect(bg_tex, Rect2(bp - Vector2(54, 42), Vector2(108, 84)), false, bmod)
		var cur_hp := maxi(0, int(b["hp"]))
		for hi in range(int(b["max_hp"])):
			var hx := bp.x - 14.0 + float(hi) * 14.0
			r.draw_circle(Vector2(hx, bp.y - 48.0), 4.0, Color(0.96, 0.36, 0.26) if hi < cur_hp else Color(0.24, 0.20, 0.20))

	# Captive/Freed Wild Dragons flapping upward cleanly once liberated!
	var dframe := int(t_now * 4.5) % 2
	for wd: Dictionary in r.freed_dragons:
		var wp := Vector2(wd["pos"])
		var dtex: Texture2D = r.assets.get_tex("%s_%d.png" % [String(wd["tex"]), dframe], String(wd["tex"]) + ".png")
		if dtex != null:
			r.draw_texture_rect(dtex, Rect2(wp - Vector2(36, 30), Vector2(72, 60)), false)

	for pb: Dictionary in r.player_bolts:
		var pbp := Vector2(pb["pos"])
		var col := Color(0.45, 0.98, 0.64) if String(pb.get("kind", "bolt")) == "fire" else Color(0.96, 0.86, 0.42)
		r.draw_circle(pbp, 6.0 if String(pb.get("kind", "bolt")) == "fire" else 3.5, col)

	for eb: Dictionary in r.enemy_bolts:
		var ebp := Vector2(eb["pos"])
		r.draw_line(ebp - Vector2(eb["dir"]) * 9.0, ebp + Vector2(eb["dir"]) * 9.0, Color(0.98, 0.32, 0.24), 2.8)

	# Player Captain Anna atop Emerald Forest Wyrm Virelai
	var vf := int(t_now * 4.2) % 2
	var vtex: Texture2D = r.assets.get_tex("dragon_anna_%d.png" % vf, "dragon_anna.png")
	if vtex != null:
		var rot := float(r.dragon_angle) + PI * 0.5
		if float(r.barrel_timer) > 0.0:
			rot += float(r.barrel_timer) * 18.0
		r.draw_set_transform(r.dragon_pos + Vector2(22, 34), rot, Vector2.ONE)
		r.draw_texture_rect(vtex, Rect2(-52, -42, 104, 84), false, Color(0.02, 0.03, 0.06, 0.30))
		r.draw_set_transform(r.dragon_pos, rot, Vector2.ONE)
		var vmod := Color(1.0, 0.5, 0.5) if float(r.hurt_timer) > 0.0 else Color.WHITE
		r.draw_texture_rect(vtex, Rect2(-52, -42, 104, 84), false, vmod)
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for hp: Dictionary in r.hit_puffs:
		var c: Color = hp["col"]
		var a := clampf(float(hp["life"]) / 0.45, 0.0, 1.0)
		r.draw_circle(Vector2(hp["pos"]), float(hp["sz"]), Color(c.r, c.g, c.b, a))
