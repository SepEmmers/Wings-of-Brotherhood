class_name PortOfBrugesDraw
extends RefCounted

## Custom 2D canvas drawing helper for PortOfBrugesRegion.gd.


static func setup_layers(r) -> void:
	var water_created := r.get_node_or_null("EnvWaterLayer") == null
	r.setup_water_layer([Rect2(0, -140, 256, 1180)], 32.0, -3)
	if water_created:
		r.step_water_layer()
	r.setup_static_ground_chunks(
		Rect2(224, 0, 1376, 1040),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-2,
		false
	)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	r.assets.draw_varied_tiled_rect(canvas, Rect2(256, 0, 1344, 1040), r.assets.get_tex("tile_cobble.png"), r.assets.get_tex("tile_cobble_2.png"), 32.0, 4)
	r.assets.draw_grass_zone(canvas, Rect2(928, 24, 640, 328), true, 5, [Rect2(936, 28, 548, 192), Rect2(928, 220, 544, 52), Rect2(1154, 270, 64, 82), Rect2(1484, 0, 88, 356)])
	r.assets.draw_grass_zone(canvas, Rect2(1088, 608, 480, 384), true, 9, [Rect2(1148, 616, 324, 244), Rect2(1278, 860, 64, 132)])
	r.assets.draw_dirt_trail_network(
		canvas,
		[Rect2(928, 220, 544, 52), Rect2(1154, 270, 64, 82), Rect2(1278, 860, 64, 132)],
		[Rect2(256, 0, 672, 1040), Rect2(256, 352, 1344, 256), Rect2(256, 992, 1344, 48)],
		[Rect2(936, 28, 548, 192), Rect2(1148, 616, 324, 244)],
		13
	)
	r.assets.draw_tiled_rect(canvas, Rect2(224, 0, 32, 1040), r.assets.get_tex("tile_wharf.png"), 32.0)
	r.assets.draw_wharf_curb_seam(canvas, 256.0, 0.0, 1040.0)
	r.assets.draw_varied_tiled_rect(canvas, Rect2(660, 0, 120, 276), r.assets.get_tex("tile_cobble_2.png"), r.assets.get_tex("tile_cobble.png"), 32.0, 7)
	canvas.draw_rect(Rect2(660, 0, 120, 276), Color(0.56, 0.50, 0.42, 0.35), false, 1.5)
	r.assets.draw_dirt_trail_network(canvas, [Rect2(1484, 0, 88, 356)], [], [], 13)
	r.assets.draw_varied_tiled_rect(canvas, Rect2(1484, 0, 88, 36), r.assets.get_tex("tile_cobble_2.png"), r.assets.get_tex("tile_cobble.png"), 32.0, 17)


static func draw_world(r) -> void:
	setup_layers(r)
	var font := ThemeDB.fallback_font
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	var t_now: float = r.assets.time_elapsed
	var cam_rect: Rect2 = r.get_camera_rect(180.0)

	if cam_rect.position.x <= 240.0:
		for wy in range(-120, 1040, 48):
			if float(wy) < cam_rect.position.y - 24.0 or float(wy) > cam_rect.end.y + 24.0:
				continue
			var shift := sin(t_now * 2.5 + float(wy) * 0.05) * 4.0
			r.draw_line(Vector2(218 + shift, wy), Vector2(218 + shift, wy + 18), Color(0.75, 0.90, 0.96, 0.35), 2.0)

	var cog_tex: Texture2D = r.assets.get_tex("merchant_cog.png")
	var bol_tex: Texture2D = r.assets.get_tex("prop_bollard.png")
	if cam_rect.intersects(Rect2(r.ship_pos - Vector2(90, 160), Vector2(180, 300))):
		if not GameState.ship_docked:
			for wi in range(1, 5):
				var spread := float(wi) * 9.0
				r.draw_arc(r.ship_pos + Vector2(0, -82 - float(wi) * 14.0), 22.0 + spread, 0.2, PI - 0.2, 10, Color(0.84, 0.94, 0.98, 0.42 - float(wi) * 0.08), 2.0)
		if cog_tex != null:
			r.draw_texture_rect(cog_tex, Rect2(r.ship_pos - Vector2(72, 108), Vector2(144, 216)), false)

		var cleat_pos: Vector2 = r.ship_pos + Vector2(34, -52)
		if bol_tex != null:
			r.draw_texture_rect(bol_tex, Rect2(cleat_pos - Vector2(12, 16), Vector2(24, 24)), false)
		if GameState.ship_moored:
			r.draw_line(cleat_pos, Vector2(238, 410), Color(0.76, 0.62, 0.34), 3.0)
		if not GameState.carrying_crate and not GameState.cargo_delivered:
			var ct: Texture2D = r.assets.get_tex("prop_crate.png")
			if ct != null:
				r.draw_texture_rect(ct, Rect2(r.ship_pos + Vector2(-34, 28), Vector2(32, 32)), false)
		r.assets.draw_npc_sprite(r, r.ship_pos + Vector2(4, -22), "npc_shipmaster.png", "Shipmaster Hendrik", font)

	if r.gangplank_deployed and cam_rect.intersects(Rect2(204, 464, 64, 32)):
		r.assets.draw_tiled_rect(r, Rect2(204, 464, 64, 32), r.assets.get_tex("tile_wharf.png"), 32.0)
		r.draw_rect(Rect2(204, 464, 64, 32), Color(0.11, 0.09, 0.11), false, 2.0)

	if bol_tex != null:
		for bpos in r.WHARF_BOLLARDS:
			if cam_rect.has_point(bpos):
				r.draw_texture_rect(bol_tex, Rect2(bpos - Vector2(16, 18), Vector2(32, 32)), false)

	if not GameState.drifted_crate_recovered and cam_rect.has_point(r.DRIFTED_CRATE_POS):
		var bob := sin(t_now * 3.0) * 4.0
		var crate_tex: Texture2D = r.assets.get_tex("prop_crate.png")
		if crate_tex != null:
			r.draw_texture_rect(crate_tex, Rect2(r.DRIFTED_CRATE_POS + Vector2(-16, -16 + bob), Vector2(32, 32)), false)
		r.draw_arc(r.DRIFTED_CRATE_POS + Vector2(0, bob), 22.0 + sin(t_now * 4.0) * 2.0, 0.0, TAU, 18, Color(0.95, 0.72, 0.38, 0.55), 1.5)

	if not GameState.shuttle_pouch_recovered and cam_rect.has_point(r.BOBBING_POUCH_POS):
		var pbob := cos(t_now * 3.6) * 4.5
		r.draw_arc(r.BOBBING_POUCH_POS + Vector2(0, pbob), 19.0 + cos(t_now * 3.8) * 2.5, 0.0, TAU, 16, Color(0.55, 0.85, 0.95, 0.58), 1.5)
		var pouch_tex: Texture2D = r.assets.get_tex("prop_shuttle_pouch.png")
		if pouch_tex != null:
			r.draw_texture_rect(pouch_tex, Rect2(r.BOBBING_POUCH_POS + Vector2(-16, -16 + pbob), Vector2(32, 32)), false)

	if cam_rect.has_point(r.HARBOUR_RIGGING_POST):
		var rig_tex: Texture2D = r.assets.get_tex("prop_rigging_post.png")
		if rig_tex != null:
			r.draw_texture_rect(rig_tex, Rect2(r.HARBOUR_RIGGING_POST + Vector2(-20, -40), Vector2(40, 56)), false)
	var coil_tex: Texture2D = r.assets.get_tex("prop_rope_coil.png")
	if coil_tex != null and cam_rect.has_point(r.HARBOUR_RIGGING_POST):
		r.draw_texture_rect(coil_tex, Rect2(r.HARBOUR_RIGGING_POST + Vector2(-16, 4), Vector2(32, 32)), false)

	if cam_rect.intersects(Rect2(348, 36, 336, 216)):
		r.assets.draw_sprite_building(r, Rect2(348, 36, 336, 216), "building_warehouse.png", "", font)
	if cam_rect.intersects(Rect2(936, 28, 548, 192)):
		r.assets.draw_sprite_building(r, Rect2(936, 28, 548, 192), "building_ropewalk.png", "", font)

	if cam_rect.has_point(r.NOTICEBOARD_POS):
		var nb_tex: Texture2D = r.assets.get_tex("prop_noticeboard.png")
		if nb_tex != null:
			r.draw_texture_rect(nb_tex, Rect2(r.NOTICEBOARD_POS - Vector2(22, 36), Vector2(44, 52)), false)
		r.draw_rect(Rect2(r.NOTICEBOARD_POS + Vector2(-11, -14), Vector2(10, 12)), Color(0.76, 0.68, 0.48))
		r.draw_circle(r.NOTICEBOARD_POS + Vector2(-6, -15), 2.0, Color(0.68, 0.18, 0.16))
		var nb_plaque := Rect2(r.NOTICEBOARD_POS + Vector2(-36, 11), Vector2(72, 15))
		r.draw_rect(nb_plaque, Color(0.20, 0.13, 0.08, 0.94))
		r.draw_rect(nb_plaque, Color(0.66, 0.50, 0.26, 0.90), false, 1.0)
		r.draw_rect(Rect2(nb_plaque.position + Vector2(3, 2), Vector2(2, 2)), Color(0.84, 0.70, 0.36))
		r.draw_rect(Rect2(Vector2(nb_plaque.end.x - 5, nb_plaque.position.y + 2), Vector2(2, 2)), Color(0.84, 0.70, 0.36))
		r.assets.draw_label_shadowed(r, r.NOTICEBOARD_POS + Vector2(0, 22), "Noticeboard", font, 10, Color(0.95, 0.86, 0.62), true)

	if not GameState.bruges_twine_cache_cut and cam_rect.has_point(r.TWINE_CACHE_POS):
		var tc_tex: Texture2D = r.assets.get_tex("prop_twine_cache.png")
		if tc_tex != null:
			r.draw_texture_rect(tc_tex, Rect2(r.TWINE_CACHE_POS - Vector2(20, 22), Vector2(40, 40)), false)
		r.draw_arc(r.TWINE_CACHE_POS, 21.0 + sin(t_now * 3.8) * 2.0, 0.0, TAU, 16, Color(0.95, 0.78, 0.42, 0.50), 1.5)

	if cam_rect.intersects(Rect2(944, 206, 488, 60)):
		r.draw_line(Vector2(970, 224), Vector2(1410, 224), Color(0.76, 0.62, 0.36), 3.0)
		var windlass_tex: Texture2D = r.assets.get_tex("prop_rope_windlass.png")
		if windlass_tex != null:
			r.draw_texture_rect(windlass_tex, Rect2(950, 212, 46, 36), false)
			r.draw_texture_rect(windlass_tex, Rect2(1382, 212, 46, 36), false)
		if coil_tex != null:
			for rx in range(1018, 1380, 92):
				if float(rx) >= cam_rect.position.x and float(rx) <= cam_rect.end.x:
					r.draw_texture_rect(coil_tex, Rect2(rx - 16, 232, 32, 32), false)

	var prop_crate: Texture2D = r.assets.get_tex("prop_crate.png")
	var prop_barrel: Texture2D = r.assets.get_tex("prop_barrel.png")
	if prop_crate != null:
		for cp in [Vector2(336, 620), Vector2(372, 634), Vector2(338, 668), Vector2(372, 216), Vector2(602, 214), Vector2(1124, 782)]:
			if cam_rect.has_point(cp):
				r.draw_texture_rect(prop_crate, Rect2(cp, Vector2(32, 32)), false)
	if prop_barrel != null:
		for bp in [Vector2(374, 672), Vector2(344, 700), Vector2(636, 198), Vector2(406, 218), Vector2(1124, 816)]:
			if cam_rect.has_point(bp):
				r.draw_texture_rect(prop_barrel, Rect2(bp, Vector2(32, 32)), false)

	if cam_rect.intersects(Rect2(744, 270, 112, 86)):
		var pulpit_tex: Texture2D = r.assets.get_tex("prop_church_pulpit.png")
		if pulpit_tex != null:
			r.draw_texture_rect(pulpit_tex, Rect2(744, 290, 112, 64), false)

	if cam_rect.intersects(Rect2(714, 480, 162, 136)):
		r.assets.draw_sprite_building(r, Rect2(714, 480, 162, 136), "building_baker.png", "", font)
	var oven_rect := Rect2(876, 550, 56, 46)
	if cam_rect.intersects(oven_rect.grow(36.0)):
		r.assets.draw_bakery_oven_fx(r, oven_rect, t_now)
	var sack_tex: Texture2D = r.assets.get_tex("prop_flour_sack_stack.png")
	if sack_tex != null and cam_rect.intersects(Rect2(838, 598, 34, 28)):
		r.draw_texture_rect(sack_tex, Rect2(838, 598, 34, 28), false)
	if cam_rect.intersects(Rect2(1148, 616, 324, 244)):
		r.assets.draw_sprite_building(r, Rect2(1148, 616, 324, 244), "building_house.png", "", font)

	var pine_tex: Texture2D = r.assets.get_tex("prop_pine_tree.png")
	if pine_tex != null:
		for tp in [Vector2(876, 68), Vector2(898, 174), Vector2(1105, 895), Vector2(1502, 740), Vector2(1510, 912)]:
			if cam_rect.has_point(tp):
				r.draw_texture_rect(pine_tex, Rect2(tp - Vector2(36, 78), Vector2(72, 96)), false)

	if cam_rect.has_point(Vector2(842, 482)):
		r.assets.draw_chimney_smoke(r, Vector2(842, 482), 0)
	if cam_rect.has_point(Vector2(898, 554)):
		r.assets.draw_chimney_smoke(r, Vector2(898, 554), 1)
	if cam_rect.has_point(Vector2(1398, 620)):
		r.assets.draw_chimney_smoke(r, Vector2(1398, 620), 1)

	var ltex: Texture2D = r.assets.get_tex("prop_lantern.png")
	for lpos in [Vector2(290, 380), Vector2(680, 250), Vector2(930, 255), Vector2(705, 600), Vector2(1260, 916), Vector2(1360, 916)]:
		if not cam_rect.has_point(lpos):
			continue
		if ltex != null:
			r.draw_texture_rect(ltex, Rect2(lpos + Vector2(-16, -42), Vector2(32, 48)), false)
		if not is_dawn or r.ui.lighting_mode != "auto":
			r.assets.draw_campfire_sparks(r, lpos + Vector2(0, -28), false)

	if cam_rect.has_point(Vector2(512, 262)):
		r.assets.draw_npc_sprite(r, r.get_npc_yield_pos("pob_vos", Vector2(512, 262), 34.0, 12.0), "npc_quartermaster.png", "Quartermaster Vos", font)
	var idle_idx := int(floorf(r.assets.time_elapsed * 1.8)) % 2
	if not is_dawn:
		if cam_rect.has_point(Vector2(1185, 240)):
			r.assets.draw_npc_sprite(r, r.get_npc_yield_pos("pob_clara", Vector2(1185, 240), 34.0, 12.0), "npc_clara.png", "Sister Clara", font)
		if cam_rect.has_point(Vector2(308, 608)):
			r.assets.draw_npc_sprite(r, r.get_npc_yield_pos("pob_jan", Vector2(308, 608), 34.0, 12.0), "npc_dockhand_%d.png" % idle_idx, "Dockhand Jan", font)
		if cam_rect.has_point(Vector2(575, 595)):
			var piet_idx := int(floorf(r.assets.time_elapsed * 1.5 + 0.5)) % 2
			r.assets.draw_npc_sprite(r, r.get_npc_yield_pos("pob_piet", Vector2(575, 595), 34.0, 12.0), "npc_piet_%d.png" % piet_idx, "Old Piet", font)
	if cam_rect.has_point(Vector2(800, 372)):
		r.assets.draw_npc_sprite(r, r.get_npc_yield_pos("pob_inquisitor", Vector2(800, 372), 34.0, 12.0), "npc_inquisitor.png", "Church Inquisitor", font)
	if cam_rect.has_point(Vector2(795, 628)):
		r.assets.draw_npc_sprite(r, r.get_npc_yield_pos("pob_baker", Vector2(795, 628), 34.0, 12.0), "npc_baker.png", "Baker Pieter", font)

	var pier_tex: Texture2D = r.assets.get_tex("prop_gatehouse_pier_v.png")
	var sign_tex: Texture2D = r.assets.get_tex("prop_milestone.png")
	var is_ch1_gated := GameState.current_step < GameState.QuestStep.ACT2_SANCTUARY
	if pier_tex != null and cam_rect.intersects(Rect2(624, 0, 192, 110)):
		r.draw_texture_rect(pier_tex, Rect2(648, 0, 28, 36), false)
		r.draw_texture_rect(pier_tex, Rect2(764, 0, 28, 36), false)
		if is_ch1_gated:
			r.draw_rect(Rect2(674, 22, 92, 7), Color(0.36, 0.22, 0.12))
			r.draw_rect(Rect2(674, 22, 92, 7), Color(0.14, 0.08, 0.05), false, 1.2)
			for bx in [686, 712, 738]:
				r.draw_rect(Rect2(bx, 22, 10, 7), Color(0.68, 0.22, 0.16, 0.85))
		if sign_tex != null:
			r.draw_texture_rect(sign_tex, Rect2(632, 48, 30, 38), false)
	if is_ch1_gated and cam_rect.has_point(Vector2(692, 62)):
		r.assets.draw_npc_sprite(r, Vector2(692, 62), "npc_city_guard_%d.png" % idle_idx, "Gatewarden Maerten", font)
	if cam_rect.intersects(Rect2(1420, 0, 180, 300)):
		if pier_tex != null:
			r.draw_texture_rect(pier_tex, Rect2(1468, 0, 28, 36), false)
			r.draw_texture_rect(pier_tex, Rect2(1556, 0, 28, 36), false)
		if is_ch1_gated:
			r.draw_rect(Rect2(1494, 22, 64, 7), Color(0.36, 0.22, 0.12))
			r.draw_rect(Rect2(1494, 22, 64, 7), Color(0.14, 0.08, 0.05), false, 1.2)
			for bx in [1502, 1528]:
				r.draw_rect(Rect2(bx, 22, 10, 7), Color(0.68, 0.22, 0.16, 0.85))
		if sign_tex != null:
			r.draw_texture_rect(sign_tex, Rect2(1448, 250, 30, 38), false)
	if is_ch1_gated and cam_rect.has_point(Vector2(1504, 62)):
		r.assets.draw_npc_sprite(r, Vector2(1504, 62), "npc_city_guard_%d.png" % (1 - idle_idx), "Customsman Dirk", font)

	_draw_watchmen(r, font, cam_rect)
	_draw_ambush_cast(r, font, idle_idx, t_now, cam_rect)

	for fp in r.fx_particles:
		var fpos := Vector2(fp["pos"])
		if not cam_rect.has_point(fpos):
			continue
		var fa := clampf(float(fp["t"]) / maxf(0.01, float(fp["max_t"])), 0.0, 1.0)
		var fc: Color = fp["col"]
		fc.a = fa * 0.92
		r.draw_circle(fpos, float(fp["sz"]) * (0.55 + fa * 0.45), fc)

	if float(r.twine_glint_timer) > 0.0:
		var tg: float = clampf(float(r.twine_glint_timer), 0.0, 1.0)
		var glint_off := sin((1.25 - float(r.twine_glint_timer)) * 11.0) * 10.0
		r.draw_arc(r.TWINE_CACHE_POS + Vector2(0, -8), 18.0, -PI * 0.8 + glint_off * 0.04, -PI * 0.2 + glint_off * 0.04, 12, Color(0.88, 0.95, 1.0, tg), 2.5)
		r.draw_line(r.TWINE_CACHE_POS + Vector2(-8, -14), r.TWINE_CACHE_POS + Vector2(8, -2), Color(1.0, 0.98, 0.86, tg), 1.8)

	if float(r.rigging_ripple_timer) > 0.0:
		var rp_p := 1.0 - clampf(float(r.rigging_ripple_timer) / 1.4, 0.0, 1.0)
		r.draw_arc(r.BOBBING_POUCH_POS, 16.0 + rp_p * 34.0, 0.0, TAU, 20, Color(0.56, 0.90, 0.98, 1.0 - rp_p), 2.0)

	if float(r.errand_hint_timer) > 0.0:
		var ea := clampf(float(r.errand_hint_timer), 0.0, 1.0)
		var bob := sin(t_now * 7.0) * 3.0
		var hints: Array = []
		if not GameState.cargo_delivered:
			hints.append({"pos": Vector2(512, 206 + bob), "tex": "icon_crate.png"})
		if not GameState.visited_clara:
			hints.append({"pos": Vector2(1185, 184 + bob), "tex": "prop_rope_coil.png"})
		if not GameState.bought_bread:
			hints.append({"pos": Vector2(795, 572 + bob), "tex": "icon_bread.png"})
		for h in hints:
			var hp: Vector2 = h["pos"]
			if cam_rect.has_point(hp):
				r.draw_rect(Rect2(hp - Vector2(13, 12), Vector2(26, 24)), Color(0.96, 0.92, 0.82, 0.94 * ea))
				r.draw_rect(Rect2(hp - Vector2(13, 12), Vector2(26, 24)), Color(0.40, 0.28, 0.16, 0.90 * ea), false, 1.5)
				var htex: Texture2D = r.assets.get_tex(String(h["tex"]))
				if htex != null:
					r.draw_texture_rect(htex, Rect2(hp - Vector2(9, 9), Vector2(18, 18)), false)

	r.queue_foreground_redraw()


static func _draw_foreground(r, fg: Node2D) -> void:
	var font := ThemeDB.fallback_font
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	var cam_rect: Rect2 = r.get_camera_rect(180.0)
	var py: float = r.player.position.y

	for b in [
		{"rect": Rect2(348, 36, 336, 216), "tex": "building_warehouse.png"},
		{"rect": Rect2(936, 28, 548, 192), "tex": "building_ropewalk.png"},
		{"rect": Rect2(714, 480, 162, 136), "tex": "building_baker.png"},
		{"rect": Rect2(1148, 616, 324, 244), "tex": "building_house.png"},
	]:
		var br: Rect2 = b["rect"]
		if py < br.end.y - 6.0 and py > br.position.y - 24.0 and cam_rect.intersects(br):
			r.draw_building_roof_overhang(fg, br, r.assets.get_tex(String(b["tex"])), 0.44)

	var pine_tex: Texture2D = r.assets.get_tex("prop_pine_tree.png")
	if pine_tex != null:
		for tp in [Vector2(876, 68), Vector2(898, 174), Vector2(1105, 895), Vector2(1502, 740), Vector2(1510, 912)]:
			var p_rect := Rect2(tp - Vector2(36, 78), Vector2(72, 96))
			if py < p_rect.end.y - 8.0 and cam_rect.intersects(p_rect):
				r.draw_building_roof_overhang(fg, p_rect, pine_tex, 0.62)

	if not r.title_bg_mode and not r.ambush_cutscene_active:
		var idle_idx := int(floorf(r.assets.time_elapsed * 1.8)) % 2
		var npcs: Array = [
			{"pos": r.get_npc_yield_pos("pob_vos", Vector2(512, 262), 34.0, 12.0), "tex": "npc_quartermaster.png", "name": "Quartermaster Vos"},
			{"pos": r.get_npc_yield_pos("pob_inquisitor", Vector2(800, 372), 34.0, 12.0), "tex": "npc_inquisitor.png", "name": "Church Inquisitor"},
			{"pos": r.get_npc_yield_pos("pob_baker", Vector2(795, 628), 34.0, 12.0), "tex": "npc_baker.png", "name": "Baker Pieter"},
		]
		if GameState.ship_docked:
			npcs.append({"pos": r.ship_pos + Vector2(4, -22), "tex": "npc_shipmaster.png", "name": "Shipmaster Hendrik"})
		if not is_dawn:
			var piet_idx := int(floorf(r.assets.time_elapsed * 1.5 + 0.5)) % 2
			npcs.append({"pos": r.get_npc_yield_pos("pob_clara", Vector2(1185, 240), 34.0, 12.0), "tex": "npc_clara.png", "name": "Sister Clara"})
			npcs.append({"pos": r.get_npc_yield_pos("pob_jan", Vector2(308, 608), 34.0, 12.0), "tex": "npc_dockhand_%d.png" % idle_idx, "name": "Dockhand Jan"})
			npcs.append({"pos": r.get_npc_yield_pos("pob_piet", Vector2(575, 595), 34.0, 12.0), "tex": "npc_piet_%d.png" % piet_idx, "name": "Old Piet"})
		if GameState.current_step < GameState.QuestStep.ACT2_SANCTUARY:
			npcs.append({"pos": Vector2(692, 62), "tex": "npc_city_guard_%d.png" % idle_idx, "name": "Gatewarden Maerten"})
			npcs.append({"pos": Vector2(1504, 62), "tex": "npc_city_guard_%d.png" % (1 - idle_idx), "name": "Customsman Dirk"})
		for n in npcs:
			var np_pos := Vector2(n["pos"])
			if np_pos.y > py + 2.0 and cam_rect.has_point(np_pos):
				r.assets.draw_npc_sprite(fg, np_pos, String(n["tex"]), String(n["name"]), font)
		r.draw_interact_bubble_if_active_on(fg, font)


static func _draw_watchmen(r, font: Font, cam_rect: Rect2) -> void:
	if GameState.current_step != GameState.QuestStep.SNITCH_TO_CHURCH:
		return
	for wp in r.watchman_patrols:
		var wpos: Vector2 = wp["pos"]
		if not cam_rect.has_point(wpos):
			continue
		var wdir: Vector2 = Vector2(wp["dir"]).normalized()
		var is_al := float(wp["alert"]) > 0.0
		var susp: float = float(wp.get("suspicion", 0.0))
		var cone_col := Color(0.98, 0.34, 0.26, 0.28) if is_al else (Color(0.98, 0.58, 0.24, 0.24) if susp > 0.05 else Color(0.98, 0.80, 0.34, 0.16))
		r.draw_raycast_vision_cone(r, wpos + Vector2(0, -6), wdir, 145.0, deg_to_rad(36.0), r.sight_blockers, cone_col, cone_col.lightened(0.18))
		if susp > 0.05 and not is_al:
			r.draw_arc(wpos + Vector2(0, -48), 9.0, -PI * 0.5, -PI * 0.5 + TAU * susp, 14, Color(0.98, 0.62, 0.24), 2.5)
		var w_card := "down"
		var w_flip := false
		if absf(wdir.x) > absf(wdir.y) * 1.05:
			w_card = "side"
			w_flip = wdir.x < 0.0
		elif wdir.y < 0.0:
			w_card = "up"
		var is_paused := float(wp.get("pause", 0.0)) > 0.0
		var w_step := 0 if is_paused else (1 if int(floorf(float(wp.get("t", 0.0)) * 14.0)) % 2 == 0 else 2)
		var w_tex := "npc_watchman_%s_%d.png" % [w_card, w_step]
		r.assets.draw_npc_sprite(r, wpos, w_tex, "! WATCHMAN !" if is_al else ("? WATCHMAN" if susp > 0.05 else "Church Watchman"), font, Color(0.98, 0.56, 0.48) if is_al else Color(0.95, 0.84, 0.72), w_flip)


static func _draw_ambush_cast(r, font: Font, idle_idx: int, t_now: float, cam_rect: Rect2) -> void:
	if r.ambush_cutscene_active:
		r.assets.draw_npc_sprite(r, r.amb_rider_l, "npc_brotherhood_guard_%d.png" % idle_idx, "Brotherhood Rider", font)
		r.assets.draw_npc_sprite(r, r.amb_rider_r, "npc_brotherhood_guard_%d.png" % (1 - idle_idx), "Brotherhood Rider", font, Color(0.95, 0.92, 0.84), true)
		if r.ambush_stage >= 1:
			r.assets.draw_npc_sprite(r, r.amb_anna, "npc_anna.png", "Anna", font)
		for dp in r.amb_dust_puffs:
			var a := clampf(float(dp["t"]) / float(dp["max_t"]), 0.0, 1.0)
			r.draw_circle(dp["pos"], 5.0 * a + 2.0, Color(0.76, 0.72, 0.62, 0.45 * a))
		if r.amb_virelai_visible:
			var vframe := int(t_now * 7.0) % 2
			var vtex: Texture2D = r.assets.get_tex("dragon_anna_%d.png" % vframe, "dragon_anna.png")
			var shadow_sc := clampf(1.3 - r.amb_virelai_alt / 220.0, 0.35, 1.25)
			r.draw_set_transform(r.amb_anchor + Vector2(12, -20), 0.0, Vector2(1.4 * shadow_sc, 0.55 * shadow_sc))
			r.draw_circle(Vector2.ZERO, 44.0, Color(0.03, 0.03, 0.06, 0.42 * shadow_sc))
			r.draw_set_transform(Vector2.ZERO)
			if vtex != null:
				r.draw_texture_rect(vtex, Rect2(r.amb_virelai - Vector2(88, 72), Vector2(176, 144)), false)
	elif (GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH or GameState.current_step == GameState.QuestStep.BROTHERHOOD_AMBUSH) and cam_rect.has_point(r.AMBUSH_CENTER):
		r.assets.draw_npc_sprite(r, r.AMBUSH_CENTER + Vector2(-42, -20), "npc_brotherhood_guard_%d.png" % idle_idx, "Brotherhood Rider", font)
		r.assets.draw_npc_sprite(r, r.AMBUSH_CENTER + Vector2(38, 18), "npc_brotherhood_guard_%d.png" % (1 - idle_idx), "Brotherhood Rider", font, Color(0.95, 0.92, 0.84), true)
		r.assets.draw_npc_sprite(r, r.AMBUSH_CENTER + Vector2(0, -45), "npc_anna.png", "Captain Anna", font)
