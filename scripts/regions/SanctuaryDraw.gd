class_name SanctuaryDraw
extends RefCounted

## Top-down visual renderer for the 5-year evolving Brotherhood Cliffside Sanctuary
## (Phase 1 Year 1 -> Phase 2 Year 3 expanded camp -> Phase 3 Year 5 storm dusk outpost).

const SanctuaryVillageDataScript := preload("res://scripts/regions/SanctuaryVillageData.gd")
const SanctuaryArrivalCutsceneScript := preload("res://scripts/regions/SanctuaryArrivalCutscene.gd")
const SanctuaryAct4Script := preload("res://scripts/regions/SanctuaryAct4.gd")


static func _draw_wooden_stall_sign(r, center_pos: Vector2, text: String, font: Font) -> void:
	var tsz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var w: float = maxf(64.0, tsz.x + 14.0)
	var plaque := Rect2(center_pos.x - w * 0.5, center_pos.y - 11.0, w, 15.0)
	r.draw_rect(Rect2(plaque.position + Vector2(1, 2), plaque.size), Color(0.03, 0.03, 0.05, 0.48))
	r.draw_rect(plaque, Color(0.20, 0.13, 0.08, 0.95))
	r.draw_rect(plaque, Color(0.66, 0.50, 0.26, 0.90), false, 1.0)
	r.draw_rect(Rect2(plaque.position + Vector2(3, 2), Vector2(2, 2)), Color(0.84, 0.70, 0.36))
	r.draw_rect(Rect2(Vector2(plaque.end.x - 5.0, plaque.position.y + 2.0), Vector2(2, 2)), Color(0.84, 0.70, 0.36))
	r.assets.draw_label_shadowed(r, center_pos, text, font, 10, Color(0.95, 0.86, 0.62), true)


static func setup_layers(r) -> void:
	r.setup_static_ground_chunks(
		Rect2(0, 0, 1800, 1140),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-3,
		false
	)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	assets.draw_grass_zone(canvas, Rect2(0, 0, 1800, 1140), false, 4, [
		Rect2(120, 320, 440, 260),
		Rect2(720, 0, 100, 1140),
		Rect2(1108, 330, 144, 120),
	])
	assets.draw_stone_clearing_in_grass(canvas, Rect2(120, 320, 440, 260), 3)
	var dirt_rects: Array[Rect2] = [
		Rect2(175, 230, 345, 95),
		Rect2(205, 575, 165, 195),
		Rect2(308, 580, 64, 194),
		Rect2(372, 710, 332, 64),
		Rect2(836, 710, 376, 64),
		Rect2(960, 440, 190, 90),
		Rect2(1148, 450, 64, 260),
		Rect2(1108, 330, 144, 120),
	]
	dirt_rects.append_array(SanctuaryVillageDataScript.get_extra_dirt_trails())
	assets.draw_dirt_trail_network(
		canvas,
		dirt_rects,
		[Rect2(120, 320, 440, 260)],
		[Rect2(704, 700, 132, 84)],
		19
	)
	# Soft dirt/straw bed inside Hog Yard & static pasture fences
	canvas.draw_rect(Rect2(932, 972, 220, 96), Color(0.32, 0.23, 0.16, 0.45))
	_draw_pasture_fences(canvas, assets)


static func draw_sanctuary(r) -> void:
	setup_layers(r)
	var font := ThemeDB.fallback_font
	var t_now: float = r.assets.time_elapsed
	var assets = r.assets
	var phase: int = GameState.sanctuary_phase
	var cam_rect: Rect2 = r.get_camera_rect(180.0)

	# Gorge Chasm & Timber Bridge (1 repeating quad when visible)
	var gorge_rect := Rect2(720, 0, 100, 1140)
	if cam_rect.intersects(gorge_rect):
		assets.draw_water_rect(r, gorge_rect, 32.0, cam_rect)
		var s_wake: Texture2D = assets.get_tex("prop_pier_wake_%d.png" % (int(t_now * 4.5) % 2))
		if s_wake != null:
			r.draw_texture_rect(s_wake, Rect2(Vector2(738, 796) - Vector2(14, 14), Vector2(28, 28)), false)
			r.draw_texture_rect(s_wake, Rect2(Vector2(802, 796) - Vector2(14, 14), Vector2(28, 28)), false)
		var bridge_rect := Rect2(698, 688, 144, 108)
		if cam_rect.intersects(bridge_rect):
			var s_bridge: Texture2D = assets.get_tex("prop_timber_bridge_h.png")
			if s_bridge != null:
				r.draw_texture_rect(s_bridge, bridge_rect, false)
			else:
				assets.draw_tiled_rect(r, Rect2(704, 700, 132, 84), assets.get_tex("tile_wharf.png"), 32.0)

	# Winch Grapple Posts
	var winch_tex: Texture2D = assets.get_tex("prop_winch_post.png")
	var ret_tex: Texture2D = assets.get_tex("prop_pixel_reticle.png")
	for gpost in r.ACT2_GORGE_POSTS:
		if not cam_rect.has_point(gpost):
			continue
		if winch_tex != null:
			r.draw_texture_rect(winch_tex, Rect2(gpost - Vector2(24, 42), Vector2(48, 64)), false)
		if ret_tex != null:
			var pulse_sz := 40.0 + roundf(sin(t_now * 4.0) * 2.0) * 2.0
			r.draw_texture_rect(ret_tex, Rect2(gpost - Vector2(pulse_sz * 0.5, 16.0 + pulse_sz * 0.5), Vector2(pulse_sz, pulse_sz)), false, Color(0.70, 0.94, 0.78, 0.55))
		var g_pulse: float = 0.5 + 0.5 * sin(t_now * 4.6)
		r.draw_arc(gpost + Vector2(0, -16), 9.0 + g_pulse * 3.0, 0.0, TAU, 14, Color(0.96, 0.84, 0.44, 0.35 + g_pulse * 0.25), 1.3)

	_draw_environment_props(r, phase, t_now, font, cam_rect)
	_draw_crew_stations(r, phase, t_now, font, cam_rect)
	_draw_dragons_and_cage(r, phase, t_now, font, cam_rect)
	_draw_montage_fx(r, t_now)
	if r.arrival_active or r.arrival_cloth_timer > 0.0:
		SanctuaryArrivalCutsceneScript.draw_arrival_fx(r, t_now)
	SanctuaryAct4Script.draw_act4_overlays(r, t_now, cam_rect)
	r.queue_foreground_redraw()


static func _draw_environment_props(r, phase: int, t_now: float, font: Font, cam_rect: Rect2) -> void:
	var assets = r.assets
	var banner_tex: Texture2D = assets.get_tex("prop_brotherhood_banner.png")
	if banner_tex != null:
		var banner_pts := [Vector2(140, 315), Vector2(540, 315), Vector2(690, 690), Vector2(850, 690)]
		if phase >= 2:
			banner_pts.append(Vector2(1070, 320))
			banner_pts.append(Vector2(290, 290))
		for bp in banner_pts:
			if cam_rect.has_point(bp):
				r.draw_texture_rect(banner_tex, Rect2(bp - Vector2(24, 66), Vector2(48, 76)), false)

	var pine_tex: Texture2D = assets.get_tex("prop_pine_tree.png")
	if pine_tex != null:
		for tp in [
			Vector2(56, 110), Vector2(640, 124), Vector2(880, 110), Vector2(1380, 110),
			Vector2(1742, 190), Vector2(1746, 480), Vector2(1744, 770), Vector2(1736, 1060),
			Vector2(64, 760), Vector2(62, 1065), Vector2(640, 1075), Vector2(870, 1065),
		]:
			if cam_rect.has_point(tp):
				r.draw_texture_rect(pine_tex, Rect2(tp - Vector2(36, 78), Vector2(72, 96)), false)

	_draw_village_structures_and_pastures(r, t_now, font, cam_rect)

	# Year 3+ sanctuary infrastructure expansion: herb drying rack, navigation map table & signal pennant
	if phase >= 2:
		if cam_rect.has_point(Vector2(252, 218)):
			var herbs_tex: Texture2D = assets.get_tex("prop_drying_herbs.png")
			if herbs_tex != null:
				r.draw_texture_rect(herbs_tex, Rect2(Vector2(228, 198), Vector2(48, 40)), false)
		if cam_rect.has_point(Vector2(506, 250)):
			var map_tex: Texture2D = assets.get_tex("prop_map_table.png")
			if map_tex != null:
				r.draw_texture_rect(map_tex, Rect2(Vector2(474, 232), Vector2(64, 42)), false)
			var pin_pulse: float = 0.5 + 0.5 * sin(t_now * 4.0)
			r.draw_circle(Vector2(512, 246), 2.5 + pin_pulse * 0.9, Color(0.98, 0.86, 0.48, 0.45 + pin_pulse * 0.35))
		var ppost: Vector2 = r.ACT2_PENNANT_POST_POS
		if cam_rect.has_point(ppost):
			var mast_is_strung := GameState.sanctuary_pennants_strung or phase >= 3
			var mast_fname := ("prop_signal_mast_%d.png" % (int(t_now * 5.0) % 2)) if mast_is_strung else "prop_signal_mast_loose.png"
			var mast_tex: Texture2D = assets.get_tex(mast_fname, "prop_brotherhood_banner.png")
			if mast_tex != null:
				r.draw_texture_rect(mast_tex, Rect2(ppost - Vector2(18, 76), Vector2(66, 84)), false)
			if not mast_is_strung:
				r.draw_arc(ppost, 16.0 + sin(t_now * 4.0) * 3.0, 0.0, TAU, 16, Color(0.98, 0.80, 0.38, 0.85), 2.0)
				var whip: float = sin(t_now * 6.5) * 7.0
				r.draw_line(ppost + Vector2(4, -52), ppost + Vector2(10.0 + whip, -20.0), Color(0.86, 0.72, 0.44), 2.2)
				r.draw_circle(ppost + Vector2(4, -18), 3.0, Color(0.96, 0.82, 0.42, 0.88))

	# Campfire Hearth & Herring Bucket (Year 3)
	if cam_rect.has_point(r.ACT2_CAMPFIRE_POS):
		var fire_tex: Texture2D = assets.get_tex("prop_campfire_%d.png" % (int(t_now * 6.0) % 2))
		if fire_tex != null:
			r.draw_texture_rect(fire_tex, Rect2(r.ACT2_CAMPFIRE_POS - Vector2(15, 16), Vector2(30, 30)), false)
		var spark_y := fmod(t_now * 24.0, 18.0)
		r.draw_rect(Rect2(r.ACT2_CAMPFIRE_POS + Vector2(sin(t_now * 4.5) * 4.0, -14.0 - spark_y), Vector2(2, 2)), Color(1.0, 0.78, 0.34, 1.0 - spark_y / 18.0))
	if phase == 2 and not GameState.sanctuary_kestrel_fed and GameState.sanctuary_carrying_item != "fish" and cam_rect.has_point(r.ACT2_FISH_BUCKET_POS):
		var buck_tex: Texture2D = assets.get_tex("prop_herring_bucket.png")
		if buck_tex != null:
			r.draw_texture_rect(buck_tex, Rect2(r.ACT2_FISH_BUCKET_POS - Vector2(12, 11), Vector2(24, 22)), false)
		r.draw_arc(r.ACT2_FISH_BUCKET_POS, 16.0 + sin(t_now * 4.2) * 2.5, 0.0, TAU, 16, Color(0.98, 0.80, 0.38, 0.85), 2.0)
		var fish_gleam: float = 0.5 + 0.5 * sin(t_now * 5.8)
		r.draw_circle(r.ACT2_FISH_BUCKET_POS + Vector2(3, -8), 2.5 + fish_gleam * 1.4, Color(0.84, 0.96, 1.0, 0.45 + fish_gleam * 0.45))

	# Topman's Knot-Speed Drill Board (Year 3 & Year 5 optional mastery)
	if phase >= 2 and cam_rect.has_point(r.ACT2_DRILL_BOARD_POS):
		var drill_tex: Texture2D = assets.get_tex("prop_knot_drill_board.png")
		if drill_tex != null:
			r.draw_texture_rect(drill_tex, Rect2(r.ACT2_DRILL_BOARD_POS - Vector2(15, 15), Vector2(30, 30)), false)
		if (phase == 2 or phase == 3) and not GameState.sanctuary_drill_mastered:
			r.draw_arc(r.ACT2_DRILL_BOARD_POS, 18.0 + sin(t_now * 4.0) * 2.5, 0.0, TAU, 16, Color(0.96, 0.82, 0.38, 0.82), 2.0)
			var cord_sway: float = sin(t_now * 3.6) * 3.0
			r.draw_line(r.ACT2_DRILL_BOARD_POS + Vector2(-4, -10), r.ACT2_DRILL_BOARD_POS + Vector2(-4 + cord_sway, 4), Color(0.86, 0.72, 0.42, 0.85), 1.6)
		else:
			r.draw_circle(r.ACT2_DRILL_BOARD_POS + Vector2(0, -10), 4.0, Color(0.92, 0.78, 0.34, 0.88))


static func _draw_crew_stations(r, phase: int, t_now: float, font: Font, cam_rect: Rect2) -> void:
	var assets = r.assets
	var council_gather: bool = bool(r.act4_intro_active)
	if cam_rect.has_point(r.ACT2_HENDRICK_POS):
		var rack_tex: Texture2D = assets.get_tex("prop_leather_rack.png")
		if rack_tex != null:
			r.draw_texture_rect(rack_tex, Rect2(r.ACT2_HENDRICK_POS + Vector2(-28, -42), Vector2(56, 48)), false)
	var scripted: bool = bool(r.montage_active) or bool(r.arrival_active) or council_gather
	var h_base: Vector2 = Vector2(336, 550) if council_gather else (r.ACT2_HENDRICK_POS + Vector2(24, 14))
	var h_pos: Vector2 = h_base if scripted else r.get_npc_yield_pos("sanct_hendrick", h_base, 34.0, 12.0)
	if phase != 5 and cam_rect.has_point(h_pos):
		var hendrick_tex := "npc_hendrick_%d.png" % (int(t_now * 1.6) % 2)
		assets.draw_npc_sprite(r, h_pos, hendrick_tex, "Saddler Hendrick", font)

	if phase == 1 and not GameState.sanctuary_leather_chore_done and GameState.sanctuary_carrying_item != "leather" and cam_rect.has_point(r.ACT2_LEATHER_PILE_POS):
		var bale_tex: Texture2D = assets.get_tex("prop_leather_bale.png")
		if bale_tex != null:
			r.draw_texture_rect(bale_tex, Rect2(r.ACT2_LEATHER_PILE_POS - Vector2(18, 18), Vector2(36, 36)), false)
		r.draw_arc(r.ACT2_LEATHER_PILE_POS, 18.0 + sin(t_now * 4.0) * 2.5, 0.0, TAU, 16, Color(0.98, 0.80, 0.36, 0.82), 2.0)
		var buckle_glint: float = 0.5 + 0.5 * sin(t_now * 5.2)
		r.draw_circle(r.ACT2_LEATHER_PILE_POS + Vector2(2, -4), 2.4 + buckle_glint * 1.2, Color(0.98, 0.86, 0.44, 0.55 + buckle_glint * 0.40))

	if cam_rect.has_point(r.ACT2_MAREN_POS):
		var cauld_tex: Texture2D = assets.get_tex("prop_herb_cauldron.png")
		if cauld_tex != null:
			r.draw_texture_rect(cauld_tex, Rect2(r.ACT2_MAREN_POS + Vector2(-46, -24), Vector2(44, 44)), false)
	var maren_base: Vector2 = Vector2(278, 536) if council_gather else (r.ACT2_MAREN_POS + Vector2(14, 10))
	var maren_pos: Vector2 = maren_base if scripted else r.get_npc_yield_pos("sanct_maren", maren_base, 34.0, 12.0)
	if not bool(r.montage_maren_override) and phase != 5 and cam_rect.has_point(maren_pos):
		var maren_tex := "npc_maren_%d.png" % (int(t_now * 1.4) % 2)
		assets.draw_npc_sprite(r, maren_pos, maren_tex, "Sister Maren" if not r.montage_active else "", font)
	if bool(r.montage_maren_override):
		var maren_ov_tex := "npc_maren_%d.png" % (int(t_now * 1.4) % 2)
		var m_over := Vector2(r.montage_maren_pos)
		assets.draw_npc_sprite(r, m_over, maren_ov_tex, "", font)
		var poult_tex: Texture2D = assets.get_tex("icon_poultice.png")
		r.draw_circle(m_over + Vector2(18, -8), 10.0, Color(0.46, 0.90, 0.58, 0.30))
		if poult_tex != null:
			r.draw_texture_rect(poult_tex, Rect2(m_over + Vector2(10, -16), Vector2(16, 16)), false)

	if cam_rect.has_point(r.ACT2_SPRING_POS):
		var spring_tex: Texture2D = assets.get_tex("prop_spring_well.png")
		if spring_tex != null:
			r.draw_texture_rect(spring_tex, Rect2(r.ACT2_SPRING_POS - Vector2(28, 22), Vector2(56, 44)), false)
		for ri in range(2):
			var rp: float = fmod(t_now * 0.85 + float(ri) * 0.5, 1.0)
			r.draw_arc(r.ACT2_SPRING_POS + Vector2(-2, 2), 6.0 + rp * 15.0, 0.0, TAU, 18, Color(0.62, 0.90, 1.0, (1.0 - rp) * 0.52), 1.4)
		var drop_y: float = abs(sin(t_now * 4.2)) * 8.0
		r.draw_circle(r.ACT2_SPRING_POS + Vector2(4, -2.0 - drop_y), 2.2, Color(0.78, 0.96, 1.0, 0.82))
		if phase == 1 and not GameState.sanctuary_poultice_brewed and not GameState.sanctuary_water_drawn and GameState.sanctuary_carrying_item != "water":
			r.draw_arc(r.ACT2_SPRING_POS, 20.0 + sin(t_now * 3.8) * 2.5, 0.0, TAU, 16, Color(0.55, 0.86, 0.98, 0.82), 2.0)

	if phase >= 2 and phase != 5:
		var m_base: Vector2 = Vector2(412, 538) if council_gather else (r.ACT2_MATTHIJS_EAST_POS if phase == 2 else r.ACT2_MATTHIJS_WEST_POS)
		var m_pos: Vector2 = m_base if scripted else r.get_npc_yield_pos("sanct_matthijs", m_base, 34.0, 12.0)
		if cam_rect.has_point(m_pos):
			var m_tex := "npc_matthijs_%d.png" % (int(t_now * 1.9) % 2)
			assets.draw_npc_sprite(r, m_pos, m_tex, "Matthijs", font)

	if phase != 5:
		var cook_pos: Vector2 = r.ACT2_COOK_POS if scripted else r.get_npc_yield_pos("sanct_cook", r.ACT2_COOK_POS, 34.0, 12.0)
		if cam_rect.has_point(cook_pos):
			var cook_tex := "npc_villager_cook_%d.png" % (int(t_now * 1.7) % 2)
			assets.draw_npc_sprite(r, cook_pos, cook_tex, "Cook Mieke", font)
		var bram_pos: Vector2 = r.ACT2_HERDSMAN_POS if scripted else r.get_npc_yield_pos("sanct_bram", r.ACT2_HERDSMAN_POS, 34.0, 12.0)
		if cam_rect.has_point(bram_pos):
			var herd_tex := "npc_villager_herdsman_%d.png" % (int(t_now * 1.5) % 2)
			assets.draw_npc_sprite(r, bram_pos, herd_tex, "Stockman Joost", font)
			if (phase == 2 or phase == 3) and not GameState.sanctuary_virelai_fed and GameState.sanctuary_carrying_item != "mutton":
				r.draw_arc(bram_pos + Vector2(0, 6), 20.0 + sin(t_now * 4.2) * 3.0, 0.0, TAU, 16, Color(0.98, 0.80, 0.36, 0.82), 2.0)
		var guard_tex := "npc_brotherhood_guard_%d.png" % (int(t_now * 1.3) % 2)
		var wwatch_pos: Vector2 = r.ACT2_WEST_WATCHER_POS if scripted else r.get_npc_yield_pos("sanct_west_watch", r.ACT2_WEST_WATCHER_POS, 34.0, 12.0)
		if cam_rect.has_point(wwatch_pos):
			assets.draw_npc_sprite(r, wwatch_pos, guard_tex, "Bridge Scout", font)
		var cwatch_pos: Vector2 = Vector2(1542, 226) if scripted else r.get_npc_yield_pos("sanct_cliff_watch", Vector2(1542, 226), 34.0, 12.0)
		if cam_rect.has_point(cwatch_pos):
			assets.draw_npc_sprite(r, cwatch_pos, guard_tex, "Cliff Lookout", font)


static func _draw_village_structures_and_pastures(r, t_now: float, font: Font, cam_rect: Rect2) -> void:
	var assets = r.assets

	for b in SanctuaryVillageDataScript.get_building_placements():
		var rect: Rect2 = b["rect"]
		if not cam_rect.intersects(rect.grow(36.0)):
			continue
		var btex: Texture2D = assets.get_tex(b["tex"])
		if btex != null:
			r.draw_circle(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 4.0), rect.size.x * 0.44, Color(0.05, 0.06, 0.08, 0.22))
			r.draw_texture_rect(btex, rect, false)
		var blbl: String = String(b.get("label", ""))
		if blbl != "":
			assets.draw_label_shadowed(r, b["lpos"], blbl, font, 10, b["lcol"], true)

	for item in SanctuaryVillageDataScript.get_tent_and_stall_placements():
		var ir: Rect2 = item["rect"]
		if not cam_rect.intersects(ir.grow(24.0)):
			continue
		var itex: Texture2D = assets.get_tex(item["tex"])
		if itex != null:
			r.draw_texture_rect(itex, ir, false)
		if item.has("label") and String(item["label"]) != "":
			_draw_wooden_stall_sign(r, item["lpos"], item["label"], font)

	if cam_rect.has_point(Vector2(491.0, 798.0)):
		var steam_y := fmod(t_now * 18.0, 16.0)
		r.draw_circle(Vector2(491.0 + sin(t_now * 3.0) * 3.0, 798.0 - steam_y), 3.0, Color(0.92, 0.94, 0.90, (1.0 - steam_y / 16.0) * 0.55))

	var hay_tex: Texture2D = assets.get_tex("prop_hay_bale.png")
	if hay_tex != null:
		for hp in SanctuaryVillageDataScript.get_hay_positions():
			if cam_rect.has_point(hp):
				r.draw_texture_rect(hay_tex, Rect2(hp - Vector2(16, 13), Vector2(32, 26)), false)

	for ani in SanctuaryVillageDataScript.get_livestock_entries():
		var pos: Vector2 = ani["pos"]
		if not cam_rect.has_point(pos):
			continue
		var phase_off := float(ani["phase"])
		var frame := int(t_now * 1.4 + phase_off) % 2
		var atex: Texture2D = assets.get_tex("animal_%s_%d.png" % [ani["kind"], frame])
		var sz: Vector2 = ani["size"]
		var sway_x := roundf(sin(t_now * 0.8 + phase_off) * 3.0)
		var draw_pos := pos + Vector2(sway_x, 0)
		r.draw_circle(draw_pos + Vector2(0, sz.y * 0.38), sz.x * 0.36, Color(0.05, 0.06, 0.08, 0.25))
		if atex != null:
			r.draw_texture_rect(atex, Rect2(draw_pos - sz * 0.5, sz), false)


static func _draw_pasture_fences(canvas: Node2D, assets) -> void:
	var fh_tex: Texture2D = assets.get_tex("prop_fence_h.png")
	var fv_tex: Texture2D = assets.get_tex("prop_fence_v.png")
	for seg in SanctuaryVillageDataScript.get_fence_segments():
		var p1: Vector2 = seg["p1"]
		var p2: Vector2 = seg["p2"]
		if seg["kind"] == "h" and fh_tex != null:
			var x := p1.x
			while x < p2.x:
				var w := minf(32.0, p2.x - x)
				canvas.draw_texture_rect_region(fh_tex, Rect2(x, p1.y, w, 16.0), Rect2(0, 0, w, 16.0))
				x += 32.0
		elif seg["kind"] == "v" and fv_tex != null:
			var y := p1.y
			while y < p2.y:
				var h := minf(32.0, p2.y - y)
				canvas.draw_texture_rect_region(fv_tex, Rect2(p1.x, y, 12.0, h), Rect2(0, 0, 12.0, h))
				y += 32.0


static func _draw_dragons_and_cage(r, phase: int, t_now: float, font: Font, cam_rect: Rect2) -> void:
	var assets = r.assets
	var dframe := int(t_now * 2.0) % 2
	if cam_rect.intersects(Rect2(200, 290, 290, 240)):
		var d_anna_key := "dragon_anna_eat_%d.png" % (int(t_now * 7.0) % 2) if r.virelai_eat_timer > 0.0 else ("dragon_anna_%d.png" % dframe)
		var d_anna: Texture2D = assets.get_tex(d_anna_key, "dragon_anna.png")
		if d_anna != null and not bool(r.arrival_hide_ground_duo):
			var dip: float = float(r.montage_virelai_dip) + float(r.arrival_virelai_dip) + float(r.virelai_bow_dip)
			var v_bob: float = (sin(t_now * 16.0) * 3.0 if r.virelai_splice_flash > 0.0 else (sin(t_now * 22.0) * 2.0 if r.virelai_eat_timer > 0.0 else 0.0)) + dip
			r.draw_texture_rect(d_anna, Rect2(Vector2(280, 312 + v_bob), Vector2(176, 144)), false)
		if r.virelai_eat_timer > 0.0:
			var pulse := sin(t_now * 14.0) * 4.0
			r.draw_arc(Vector2(368, 326), 14.0 + pulse, PI * 0.15, PI * 0.85, 10, Color(0.98, 0.88, 0.44, 0.78), 2.0)
			for ci in range(7):
				var ct := fmod(t_now * 4.5 + float(ci) * 0.16, 1.0)
				var cpos := Vector2(326.0 + float(ci - 3) * 6.5, 392.0 + ct * 36.0 - sin(ct * PI) * 16.0)
				r.draw_circle(cpos, 2.4, Color(0.76, 0.30, 0.22, 1.0 - ct) if ci % 2 == 0 else Color(0.56, 0.38, 0.24, 1.0 - ct))
			var crest_wag := sin(t_now * 18.0) * 5.0
			r.draw_arc(Vector2(316, 336 + crest_wag * 0.4), 13.0, -PI * 0.85, -PI * 0.25, 8, Color(0.52, 0.92, 0.68, 0.85), 2.2)
			r.draw_arc(Vector2(322, 332 - crest_wag * 0.3), 16.0, -PI * 0.78, -PI * 0.18, 8, Color(0.88, 0.96, 0.64, 0.75), 1.8)
			var tail_sw := sin(t_now * 12.0) * 16.0
			r.draw_arc(Vector2(440 + tail_sw, 418), 18.0, -0.4, 1.4, 10, Color(0.84, 0.86, 0.80, 0.48), 3.0)
			r.draw_circle(Vector2(448 + tail_sw * 0.8, 424), 4.5, Color(0.76, 0.78, 0.72, 0.36))
		if r.virelai_eye_flare > 0.0:
			var ea := clampf(r.virelai_eye_flare / 1.5, 0.0, 1.0)
			var eye_pt := Vector2(318, 344)
			r.draw_circle(eye_pt, 8.0 * ea, Color(0.98, 0.86, 0.42, 0.42 * ea))
			r.draw_line(eye_pt - Vector2(7, 0), eye_pt + Vector2(7, 0), Color(1.0, 0.96, 0.72, 0.85 * ea), 1.5)
			r.draw_line(eye_pt - Vector2(0, 7), eye_pt + Vector2(0, 7), Color(1.0, 0.96, 0.72, 0.85 * ea), 1.5)
			r.draw_arc(Vector2(342, 376), 18.0 + (1.0 - ea) * 24.0, PI * 0.2, PI * 0.8, 12, Color(0.54, 0.94, 0.72, 0.55 * ea), 2.0)
		if not r.montage_active and GameState.sanctuary_carrying_item == "mutton":
			r.draw_arc(r.ACT2_VIRELAI_RACK_POS + Vector2(0, -14), 22.0 + sin(t_now * 4.2) * 3.0, 0.0, TAU, 16, Color(0.98, 0.80, 0.36, 0.85), 2.5)
			var bob_y: float = sin(t_now * 6.5) * 4.5
			var tip_pt: Vector2 = Vector2(r.ACT2_VIRELAI_RACK_POS) + Vector2(0, -34.0 + bob_y)
			r.draw_line(tip_pt + Vector2(-6, -7), tip_pt, Color(0.98, 0.88, 0.44), 2.2)
			r.draw_line(tip_pt + Vector2(6, -7), tip_pt, Color(0.98, 0.88, 0.44), 2.2)
			r.draw_circle(tip_pt + Vector2(0, -10), 2.4, Color(1.0, 0.94, 0.62))
		elif GameState.sanctuary_virelai_fed:
			var mut_tex: Texture2D = assets.get_tex("prop_mutton_joint.png")
			if mut_tex != null:
				r.draw_texture_rect(mut_tex, Rect2(226, 422, 22, 18), false)
		if r.virelai_splice_flash > 0.0:
			r.draw_arc(Vector2(368, 392), (1.0 - r.virelai_splice_flash) * 85.0 + 30.0, 0.0, TAU, 24, Color(0.42, 0.96, 0.68, r.virelai_splice_flash * 0.85), 3.0)

		if not r.montage_active and phase >= 2 and GameState.sanctuary_carrying_item == "mutton" and not GameState.sanctuary_virelai_fed:
			var perk_a: float = 0.45 + 0.45 * sin(t_now * 6.0)
			r.draw_circle(Vector2(318, 344), 4.5, Color(0.98, 0.84, 0.38, perk_a))
		if not r.montage_active and phase == 1 and not GameState.virelai_harness_spliced and GameState.sanctuary_leather_chore_done:
			r.draw_arc(r.ACT2_VIRELAI_RING_POS, 16.0 + sin(t_now * 4.0) * 3.0, 0.0, TAU, 18, Color(0.98, 0.80, 0.36), 2.5)
		elif r.is_interactable_active("act2_flight_launch"):
			r.draw_arc(r.ACT2_FLIGHT_BOARD_POS, 20.0 + sin(t_now * 4.2) * 3.0, 0.0, TAU, 18, Color(0.45, 0.94, 0.68, 0.78), 2.0)
			var st_glint: float = 0.5 + 0.5 * sin(t_now * 5.0)
			r.draw_circle(Vector2(362, 368), 3.0 + st_glint * 1.5, Color(0.96, 0.86, 0.42, 0.50 + st_glint * 0.40))

		if not bool(r.arrival_active) and not bool(r.arrival_hide_ground_duo) and phase != 5:
			var anna_scripted: bool = bool(r.montage_active) or bool(r.act4_intro_active)
			var anna_pos: Vector2 = r.ACT2_ANNA_POS if anna_scripted else r.get_npc_yield_pos("sanct_anna", r.ACT2_ANNA_POS, 34.0, 12.0)
			assets.draw_npc_sprite(r, anna_pos, "npc_anna.png", "Captain Anna" if not r.montage_active else "", font)

	# Rescued Silver Greyling ('Kestrel') — bound Year 1 -> growing Year 3 courier -> adult Year 5
	var k_size := Vector2(152, 124) if phase >= 3 else (Vector2(128, 104) if phase == 2 else Vector2(96, 80))
	if not bool(r.montage_kestrel_fly_active) and not bool(r.montage_hide_ground_kestrel) and cam_rect.intersects(Rect2(r.ACT2_CAGE_POS - Vector2(110, 110), Vector2(240, 220))):
		var is_y1_wounded: bool = (phase <= 1 and not GameState.sanctuary_greyling_treated and not bool(r.montage_hide_cage))
		var s_amp: float = float(r.salve_shiver_amp) if float(r.salve_anim_timer) > 0.0 else (1.4 if (GameState.greyling_cage_broken and is_y1_wounded) else 0.0)
		var shiver_x := sin(t_now * 28.0) * s_amp
		var kframe := (int(t_now * 12.0) % 2) if (r.kestrel_feed_timer > 0.0 or float(r.kestrel_greet_timer) > 0.0 or bool(r.montage_hide_cage)) else dframe
		var d_grey_name := "dragon_greyling_hurt.png" if is_y1_wounded else ("dragon_greyling_y5_%d.png" % kframe if phase >= 3 else ("dragon_greyling_y3_%d.png" % kframe if (phase == 2 or bool(r.montage_hide_cage)) else "dragon_greyling_%d.png" % kframe))
		var d_grey: Texture2D = assets.get_tex(d_grey_name, "dragon_greyling.png")
		if phase == 1 and GameState.greyling_cage_broken and not r.montage_hide_cage:
			var broken_tex: Texture2D = assets.get_tex("prop_shackles_broken.png")
			if broken_tex != null:
				r.draw_texture_rect(broken_tex, Rect2(r.ACT2_CAGE_POS - Vector2(56, 46), Vector2(112, 92)), false)
		var k_center: Vector2 = Vector2(r.ACT2_CAGE_POS) + Vector2(r.greyling_offset) + Vector2(r.kestrel_leap_offset)
		var k_timer: float = float(r.kestrel_feed_timer)
		var leap_sh: Vector2 = Vector2(r.ACT2_CAGE_POS) + Vector2(r.greyling_offset) + Vector2(Vector2(r.kestrel_leap_offset).x * 0.75, k_size.y * 0.24)
		r.draw_circle(leap_sh, k_size.x * (0.20 if k_timer > 0.0 else 0.24), Color(0.05, 0.06, 0.08, 0.28))
		if d_grey != null:
			r.draw_texture_rect(d_grey, Rect2(k_center + Vector2(shiver_x, 0.0) - k_size * 0.5, k_size), false)
		if k_timer > 0.0:
			var p: float = 1.0 - k_timer / 1.45
			var catch_pt: Vector2 = Vector2(r.ACT2_CAGE_POS) + Vector2(r.greyling_offset) + Vector2(-10, -56)
			if p < 0.70:
				var fp: float = clampf(p / 0.70, 0.0, 1.0)
				var fish_pos: Vector2 = Vector2(r.kestrel_fish_start).lerp(catch_pt, fp) + Vector2(0, -sin(fp * PI) * 86.0)
				var fish_tex: Texture2D = assets.get_tex("prop_herring_fish.png")
				if fish_tex != null:
					r.draw_texture_rect(fish_tex, Rect2(fish_pos - Vector2(9, 7), Vector2(18, 14)), false)
			elif p < 0.86:
				var sp: float = (p - 0.70) / 0.16
				r.draw_arc(catch_pt, 10.0 + sp * 28.0, 0.0, TAU, 18, Color(0.98, 0.90, 0.50, 1.0 - sp), 2.5)
		if phase == 1 and not GameState.greyling_cage_broken and not r.montage_hide_cage:
			var net_tex: Texture2D = assets.get_tex("prop_hunter_shackles.png")
			if net_tex != null:
				r.draw_texture_rect(net_tex, Rect2(r.ACT2_CAGE_POS - Vector2(56, 46), Vector2(112, 92)), false)
		for sh in r.cage_shards:
			var sa := clampf(float(sh["t"]) / float(sh["max_t"]), 0.0, 1.0)
			r.draw_rect(Rect2(Vector2(sh["pos"]) - Vector2(3, 3), Vector2(6, 6)), Color(0.75, 0.78, 0.84, sa))

		if not r.montage_active:
			if phase == 1 and not GameState.greyling_cage_broken:
				var lock_glint: float = 0.5 + 0.5 * sin(t_now * 5.6)
				var lock_pt: Vector2 = Vector2(r.ACT2_CAGE_POS) + Vector2(18, 6)
				r.draw_circle(lock_pt, 3.0 + lock_glint * 2.0, Color(0.98, 0.86, 0.44, 0.45 + lock_glint * 0.45))
				r.draw_line(lock_pt - Vector2(5, 0), lock_pt + Vector2(5, 0), Color(1.0, 0.96, 0.78, 0.65 * lock_glint), 1.4)
			elif phase == 2 and GameState.sanctuary_carrying_item == "fish" and not GameState.sanctuary_kestrel_fed:
				var f_bob: float = sin(t_now * 6.0) * 4.0
				var target_pt := k_center + Vector2(0, -k_size.y * 0.42 + f_bob)
				r.draw_arc(target_pt, 12.0 + sin(t_now * 4.5) * 2.5, 0.0, TAU, 16, Color(0.62, 0.96, 0.74, 0.82), 1.8)
				r.draw_circle(target_pt, 2.5, Color(0.88, 1.0, 0.86, 0.90))


static func _draw_montage_fx(r, t_now: float) -> void:
	var assets = r.assets
	var cam_rect: Rect2 = r.get_camera_rect(120.0)
	for sv in r.sage_vapor:
		var alpha := clampf(float(sv["t"]) / float(sv["max_t"]), 0.0, 1.0)
		r.draw_circle(Vector2(sv["pos"]), 5.5 + (1.0 - alpha) * 4.0, Color(0.56, 0.92, 0.68, alpha * 0.65))

	for fp in r.fx_particles:
		var f_pos := Vector2(fp["pos"])
		if not cam_rect.has_point(f_pos):
			continue
		var fa := clampf(float(fp["t"]) / maxf(0.01, float(fp["max_t"])), 0.0, 1.0)
		var fc: Color = fp["col"]
		fc.a = fa * 0.92
		r.draw_circle(f_pos, float(fp["sz"]) * (0.55 + fa * 0.45), fc)

	var kg_t: float = float(r.kestrel_greet_timer)
	if kg_t > 0.0:
		var kg_kind: String = String(r.kestrel_greet_kind)
		var kp: Vector2 = Vector2(r.ACT2_CAGE_POS) + Vector2(r.greyling_offset) + Vector2(r.kestrel_leap_offset)
		var ka: float = clampf(kg_t * 1.6, 0.0, 1.0)
		if kg_kind == "recoil" or (GameState.hints_enabled and kg_kind in ["fish_hint", "egg_hint"]):
			var icon_k: String = "prop_herring_fish.png" if kg_kind == "fish_hint" else ("prop_dragon_egg.png" if kg_kind == "egg_hint" else "icon_poultice.png")
			var bpos: Vector2 = kp + Vector2(-4.0, -78.0 - sin(t_now * 6.0) * 3.0)
			r.draw_circle(bpos + Vector2(6, 16), 3.0, Color(0.95, 0.92, 0.82, 0.85 * ka))
			r.draw_rect(Rect2(bpos - Vector2(14, 12), Vector2(28, 24)), Color(0.96, 0.92, 0.82, 0.94 * ka))
			r.draw_rect(Rect2(bpos - Vector2(14, 12), Vector2(28, 24)), Color(0.38, 0.28, 0.18, 0.90 * ka), false, 1.5)
			var itex: Texture2D = assets.get_tex(icon_k)
			if itex != null:
				r.draw_texture_rect(itex, Rect2(bpos - Vector2(9, 9), Vector2(18, 18)), false)
		elif kg_kind == "crest":
			var sp_c := 1.0 - kg_t
			for s_side in [-1.0, 1.0]:
				r.draw_arc(kp + Vector2(-6.0 + s_side * 10.0, -48.0), 14.0 + sp_c * 8.0, -PI * 0.85, -PI * 0.15, 10, Color(0.84, 0.94, 1.0, 0.88 * ka), 2.2)
		elif kg_kind == "nuzzle":
			var np_c := 1.0 - kg_t
			r.draw_arc(kp + Vector2(-22.0, -18.0), 10.0 + np_c * 16.0, 0.0, TAU, 16, Color(0.98, 0.88, 0.56, 0.78 * ka), 2.0)
		elif kg_kind == "clasp_hint" and GameState.hints_enabled:
			var cp: Vector2 = Vector2(r.ACT2_CAGE_POS) + Vector2(18, 6)
			r.draw_line(cp + Vector2(-7, -7), cp + Vector2(2, 0), Color(1.0, 0.62, 0.24, ka), 2.2)
			r.draw_line(cp + Vector2(2, 0), cp + Vector2(8, 7), Color(1.0, 0.88, 0.42, ka), 2.2)
			r.draw_arc(cp, 14.0 + (1.0 - kg_t) * 14.0, 0.0, TAU, 14, Color(1.0, 0.54, 0.24, 0.75 * ka), 2.0)
		elif kg_kind == "wing_ramp":
			var wp_c := sin(t_now * 10.0) * 3.0
			r.draw_arc(kp + Vector2(-18.0, -6.0), 34.0, PI * 0.65, PI * 1.15, 12, Color(0.80, 0.90, 0.98, 0.78 * ka), 3.0)
			r.draw_arc(kp + Vector2(-6.0, -18.0 + wp_c * 0.3), 16.0, -PI * 0.8, -PI * 0.2, 10, Color(0.98, 0.84, 0.42, 0.82 * ka), 2.2)

	if float(r.npc_wave_timer) > 0.0 and GameState.hints_enabled and not r.npc_wave_target.is_empty():
		var w_base := Vector2.ZERO
		var w_icon := ""
		match String(r.npc_wave_target):
			"hendrick":
				w_base = r.ACT2_HENDRICK_POS + Vector2(24, -22)
				w_icon = "prop_leather_bale.png"
			"maren":
				w_base = r.ACT2_MAREN_POS + Vector2(14, -24)
				w_icon = "prop_water_bucket.png"
			"matthijs":
				w_base = r.ACT2_MATTHIJS_WEST_POS + Vector2(0, -34)
				w_icon = "icon_jerkin.png"
			"kestrel":
				w_base = Vector2(r.ACT2_CAGE_POS) + Vector2(r.greyling_offset) + Vector2(0, -62)
				w_icon = "prop_herring_fish.png"
		if w_base != Vector2.ZERO and cam_rect.has_point(w_base):
			var w_a := clampf(float(r.npc_wave_timer), 0.0, 1.0)
			var arm_sw := sin(t_now * 14.0) * 6.0
			r.draw_line(w_base + Vector2(8, 22), w_base + Vector2(12 + arm_sw, 8), Color(0.96, 0.84, 0.62, w_a), 2.5)
			r.draw_arc(w_base, 14.0 + sin(t_now * 8.0) * 3.0, -PI * 0.85, -PI * 0.15, 12, Color(0.98, 0.84, 0.42, 0.85 * w_a), 2.0)
			var w_tex: Texture2D = assets.get_tex(w_icon)
			if w_tex != null:
				r.draw_texture_rect(w_tex, Rect2(w_base - Vector2(9, 11), Vector2(18, 18)), false)

	if float(r.victual_flash) > 0.0:
		var va := clampf(float(r.victual_flash), 0.0, 1.0)
		r.draw_circle(Vector2(302, 582), 18.0 * (1.2 - va * 0.3), Color(0.98, 0.86, 0.44, 0.35 * va))

	if r.montage_rope_active:
		r.draw_line(r.montage_rope_origin, r.montage_rope_tip, Color(0.84, 0.68, 0.42), 2.5)
		r.draw_circle(r.montage_rope_tip, 3.5, Color(0.76, 0.80, 0.88))

	if r.montage_kestrel_fly_active:
		var kf: int = int(t_now * 9.0) % 2
		var kt: Texture2D = assets.get_tex("dragon_greyling_y3_%d.png" % kf, "dragon_greyling.png")
		var kp: Vector2 = r.montage_kestrel_fly_pos
		r.draw_circle(kp + Vector2(0, 78), 24.0, Color(0.05, 0.07, 0.10, 0.28))
		if kt != null:
			r.draw_texture_rect(kt, Rect2(kp - Vector2(64, 52), Vector2(128, 104)), false)

	if bool(r.montage_rig_strap_active):
		var p_hands: Vector2 = r.player.position + Vector2(6, -12 + float(r.montage_rig_pull))
		var rack_pt: Vector2 = r.ACT2_HENDRICK_POS + Vector2(2, -16)
		r.draw_line(p_hands, rack_pt, Color(0.56, 0.34, 0.18), 4.0)
		r.draw_line(p_hands, rack_pt, Color(0.78, 0.56, 0.30), 1.6)
		var ring_mid := p_hands.lerp(rack_pt, 0.52)
		r.draw_circle(ring_mid, 3.8, Color(0.92, 0.78, 0.34))

	if bool(r.montage_strap_vigil_active):
		var strap_pt: Vector2 = r.player.position + Vector2(18, -10)
		var pulse_a := 0.36 + sin(t_now * 3.0) * 0.10
		r.draw_circle(strap_pt, 22.0, Color(0.62, 0.78, 1.0, pulse_a * 0.55))
		r.draw_arc(strap_pt, 17.0, 0.0, TAU, 20, Color(0.84, 0.90, 1.0, 0.55), 1.4)
		var sway := sin(t_now * 4.2) * 3.5
		r.draw_line(strap_pt + Vector2(-9, 3), strap_pt + Vector2(6, -6), Color(0.52, 0.24, 0.16), 4.0)
		r.draw_line(strap_pt + Vector2(-8, 3), strap_pt + Vector2(12, 2 + sway), Color(0.76, 0.34, 0.22), 2.5)
		var stex: Texture2D = assets.get_tex("prop_knot_clue.png")
		if stex != null:
			r.draw_texture_rect(stex, Rect2(strap_pt - Vector2(13, 13), Vector2(26, 26)), false)

	if bool(r.montage_beacon_active):
		var b_pt: Vector2 = r.ACT2_MATTHIJS_WEST_POS + Vector2(-14, -12)
		var flk := 0.85 + sin(t_now * 14.0) * 0.15
		r.draw_circle(b_pt, 32.0 * flk, Color(1.0, 0.68, 0.26, 0.22))
		r.draw_circle(b_pt, 14.0 * flk, Color(1.0, 0.82, 0.38, 0.45))
		r.draw_rect(Rect2(b_pt - Vector2(5, 6), Vector2(10, 12)), Color(0.24, 0.18, 0.14))
		r.draw_circle(b_pt, 4.0, Color(1.0, 0.90, 0.52))

	if r.weather_flakes.size() > 0:
		var cam_pt: Vector2 = r.director.camera.position
		for fl in r.weather_flakes:
			var pt := cam_pt + Vector2(fl["offset"])
			var style := String(fl["style"])
			var sz := float(fl["size"])
			match style:
				"rain":
					r.draw_line(pt, pt + Vector2(-7, 14), Color(0.72, 0.82, 0.96, 0.55), 1.4)
				"petals":
					r.draw_circle(pt, sz * 0.9, Color(0.95, 0.88, 0.58, 0.72))
				"mist":
					r.draw_circle(pt, sz * 2.2, Color(0.84, 0.90, 0.95, 0.22))
				_:
					r.draw_circle(pt, sz, Color(0.94, 0.96, 1.0, 0.78))

	if r.montage_lightning > 0.0:
		var cam_pt: Vector2 = r.director.camera.position
		if r.montage_lightning > 0.35:
			var la := clampf(r.montage_lightning, 0.0, 1.0)
			var bx := cam_pt.x + 170.0
			var by := cam_pt.y - 230.0
			r.draw_line(Vector2(bx, by), Vector2(bx - 24, by + 68), Color(0.92, 0.96, 1.0, la), 3.0)
			r.draw_line(Vector2(bx - 24, by + 68), Vector2(bx + 14, by + 132), Color(0.92, 0.96, 1.0, la), 2.5)
			r.draw_line(Vector2(bx + 14, by + 132), Vector2(bx - 16, by + 210), Color(0.86, 0.92, 1.0, la * 0.85), 2.0)
		r.draw_rect(r.get_camera_rect(48.0), Color(0.86, 0.92, 1.0, r.montage_lightning * 0.30))


static func _draw_foreground(r, fg: Node2D) -> void:
	var assets = r.assets
	var font := ThemeDB.fallback_font
	var t_now: float = assets.time_elapsed
	var phase: int = GameState.sanctuary_phase
	var py: float = r.player.position.y
	var cam_rect: Rect2 = r.get_camera_rect(180.0)

	for b in SanctuaryVillageDataScript.get_building_placements():
		var rect: Rect2 = b["rect"]
		if py < rect.end.y - 6.0 and py > rect.position.y - 24.0 and cam_rect.intersects(rect):
			r.draw_building_roof_overhang(fg, rect, assets.get_tex(String(b["tex"])), 0.44)

	for item in SanctuaryVillageDataScript.get_tent_and_stall_placements():
		var itex_name: String = String(item["tex"])
		if not itex_name.begins_with("prop_tent_"):
			continue
		var ir: Rect2 = item["rect"]
		if py < ir.end.y - 6.0 and py > ir.position.y - 20.0 and cam_rect.intersects(ir):
			r.draw_building_roof_overhang(fg, ir, assets.get_tex(itex_name), 0.42)

	var pine_tex: Texture2D = assets.get_tex("prop_pine_tree.png")
	if pine_tex != null:
		for tp in [
			Vector2(56, 110), Vector2(640, 124), Vector2(880, 110), Vector2(1380, 110),
			Vector2(1742, 190), Vector2(1746, 480), Vector2(1744, 770), Vector2(1736, 1060),
			Vector2(64, 760), Vector2(62, 1065), Vector2(640, 1075), Vector2(870, 1065),
		]:
			var p_rect := Rect2(tp - Vector2(36, 78), Vector2(72, 96))
			if py < p_rect.end.y - 8.0 and cam_rect.intersects(p_rect):
				r.draw_building_roof_overhang(fg, p_rect, pine_tex, 0.62)

	if phase != 5 and not bool(r.montage_active) and not bool(r.arrival_active):
		var council_gather: bool = bool(r.act4_intro_active)
		var fg_npcs: Array = [
			{"pos": Vector2(336, 550) if council_gather else r.get_npc_yield_pos("sanct_hendrick", r.ACT2_HENDRICK_POS + Vector2(24, 14), 34.0, 12.0), "tex": "npc_hendrick_%d.png" % (int(t_now * 1.6) % 2), "name": "Saddler Hendrick"},
			{"pos": r.get_npc_yield_pos("sanct_cook", r.ACT2_COOK_POS, 34.0, 12.0), "tex": "npc_villager_cook_%d.png" % (int(t_now * 1.7) % 2), "name": "Cook Mieke"},
			{"pos": r.get_npc_yield_pos("sanct_bram", r.ACT2_HERDSMAN_POS, 34.0, 12.0), "tex": "npc_villager_herdsman_%d.png" % (int(t_now * 1.5) % 2), "name": "Stockman Joost"},
			{"pos": r.get_npc_yield_pos("sanct_west_watch", r.ACT2_WEST_WATCHER_POS, 34.0, 12.0), "tex": "npc_brotherhood_guard_%d.png" % (int(t_now * 1.3) % 2), "name": "Bridge Scout"},
			{"pos": r.get_npc_yield_pos("sanct_cliff_watch", Vector2(1542, 226), 34.0, 12.0), "tex": "npc_brotherhood_guard_%d.png" % (int(t_now * 1.3) % 2), "name": "Cliff Lookout"},
		]
		if not bool(r.montage_maren_override):
			fg_npcs.append({"pos": Vector2(278, 536) if council_gather else r.get_npc_yield_pos("sanct_maren", r.ACT2_MAREN_POS + Vector2(14, 10), 34.0, 12.0), "tex": "npc_maren_%d.png" % (int(t_now * 1.4) % 2), "name": "Sister Maren"})
		if phase >= 2:
			var m_base: Vector2 = Vector2(412, 538) if council_gather else (r.ACT2_MATTHIJS_EAST_POS if phase == 2 else r.ACT2_MATTHIJS_WEST_POS)
			fg_npcs.append({"pos": m_base if council_gather else r.get_npc_yield_pos("sanct_matthijs", m_base, 34.0, 12.0), "tex": "npc_matthijs_%d.png" % (int(t_now * 1.9) % 2), "name": "Matthijs"})
		if not bool(r.arrival_hide_ground_duo):
			fg_npcs.append({"pos": r.ACT2_ANNA_POS if council_gather else r.get_npc_yield_pos("sanct_anna", r.ACT2_ANNA_POS, 34.0, 12.0), "tex": "npc_anna.png", "name": "Captain Anna"})
		for n in fg_npcs:
			var np_pos := Vector2(n["pos"])
			if np_pos.y > py + 2.0 and cam_rect.has_point(np_pos):
				assets.draw_npc_sprite(fg, np_pos, String(n["tex"]), String(n["name"]), font)

	if not r.montage_active and not r.arrival_active and not r.act4_escape_active:
		r.draw_interact_bubble_if_active_on(fg, font)
