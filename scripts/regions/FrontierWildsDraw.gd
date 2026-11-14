class_name FrontierWildsDraw
extends RefCounted

## Organic woodland canvas renderer for FrontierWildsRegion.gd:
## Coordinates cached terrain setup, camera-culled Y-sorted props/trees,
## batched sprite flips (zero draw_set_transform churn), and decoupled canopy vignette.

const FrontierWildsEnvDrawScript := preload("res://scripts/regions/FrontierWildsEnvDraw.gd")


class WildsVignetteLayer extends Node2D:
	var assets

	func _draw() -> void:
		if assets == null:
			return
		var vg_tex: Texture2D = assets.get_tex("prop_canopy_vignette.png")
		if vg_tex == null:
			return
		var vr := 420.0
		var box := Rect2(-vr, -vr, vr * 2.0, vr * 2.0)
		draw_texture_rect(vg_tex, box, false)
		var skirt_col := Color(0.039, 0.062, 0.094, 0.675)
		draw_rect(Rect2(box.position.x - 600.0, box.position.y - 600.0, box.size.x + 1200.0, 600.0), skirt_col)
		draw_rect(Rect2(box.position.x - 600.0, box.end.y, box.size.x + 1200.0, 600.0), skirt_col)
		draw_rect(Rect2(box.position.x - 600.0, box.position.y, 600.0, box.size.y), skirt_col)
		draw_rect(Rect2(box.end.x, box.position.y, 600.0, box.size.y), skirt_col)


static func get_camera_rect(r, pad: float = 150.0) -> Rect2:
	return FrontierWildsEnvDrawScript.get_camera_rect(r, pad)


static func setup_layers(r) -> void:
	FrontierWildsEnvDrawScript.ensure_terrain_layer(r)
	if r.get_node_or_null("WildsVignetteLayer") == null:
		var vg := WildsVignetteLayer.new()
		vg.name = "WildsVignetteLayer"
		vg.assets = r.assets
		vg.z_index = 23
		vg.light_mask = 0
		vg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vg.visible = false
		r.add_child(vg)


static func step_layers(r) -> void:
	FrontierWildsEnvDrawScript.ensure_terrain_layer(r)
	var vg := r.get_node_or_null("WildsVignetteLayer") as Node2D
	if vg != null:
		vg.visible = GameState.carrying_egg
		if vg.visible and r.player != null:
			vg.position = r.player.position


static func draw_world(r) -> void:
	var font := ThemeDB.fallback_font
	var t_now: float = r.assets.time_elapsed
	var cam_rect := FrontierWildsEnvDrawScript.get_camera_rect(r, 150.0)
	var cam_x0 := cam_rect.position.x
	var cam_y0 := cam_rect.position.y
	var cam_x1 := cam_rect.end.x
	var cam_y1 := cam_rect.end.y

	FrontierWildsEnvDrawScript.draw_cliff_escarpment(r, cam_rect)
	FrontierWildsEnvDrawScript.draw_waterfalls(r, t_now, cam_rect)
	FrontierWildsEnvDrawScript.draw_bridges(r, t_now, cam_rect)

	# Scorched Obsidian Hollow Crater beneath the fallen black dragon & ember nest
	var lair_rect := Rect2(Vector2(230, 275) - Vector2(160, 120), Vector2(320, 240))
	if cam_rect.intersects(lair_rect):
		var lair_tex: Texture2D = r.assets.get_tex("prop_dragon_lair.png")
		if lair_tex != null:
			r.draw_texture_rect(lair_tex, lair_rect, false)

	# Ground fern clumps & pebbles (Y-sorted + camera-culled + batched flips)
	var fern_tex: Texture2D = r.assets.get_tex("prop_fern_cluster.png")
	if fern_tex != null:
		for fn: Dictionary in r.forest_ferns:
			var fp: Vector2 = fn["pos"]
			if fp.y > cam_y1:
				break
			if fp.y < cam_y0 or fp.x < cam_x0 or fp.x > cam_x1:
				continue
			var sc: float = float(fn["scale"]) * 1.4
			var w := 24.0 * sc
			var h := 20.0 * sc
			var rw := -w if bool(fn["flip"]) else w
			r.draw_texture_rect(fern_tex, Rect2(fp.x - w * 0.5, fp.y - h * 0.6, rw, h), false)

	# Fallen deadfall logs & granite boulders (Y-sorted + camera-culled)
	var log_tex: Texture2D = r.assets.get_tex("prop_fallen_log.png")
	if log_tex != null:
		for lg: Dictionary in r.forest_logs:
			var lp: Vector2 = lg["pos"]
			if lp.y > cam_y1:
				break
			if lp.y < cam_y0 or lp.x < cam_x0 or lp.x > cam_x1:
				continue
			var rw := -56.0 if bool(lg["flip"]) else 56.0
			r.draw_texture_rect(log_tex, Rect2(lp.x - 28.0, lp.y - 14.0, rw, 28.0), false)

	var rock_tex: Texture2D = r.assets.get_tex("prop_cliff_rock.png")
	if rock_tex != null:
		for rk: Dictionary in r.forest_rocks:
			var rp: Vector2 = rk["pos"]
			if rp.y > cam_y1:
				break
			if rp.y < cam_y0 or rp.x < cam_x0 or rp.x > cam_x1:
				continue
			var rs: float = float(rk["scale"]) * 44.0
			r.draw_texture_rect(rock_tex, Rect2(rp - Vector2(rs * 0.5, rs * 0.56), Vector2(rs, rs)), false)

	# Upper Pines ONLY where trunk base is behind or level with player (foreground layer draws in-front crowns!)
	var p_y: float = r.player.position.y if r.player != null else 0.0
	var tree_y_limit := minf(p_y - 6.0, cam_y1)
	var pine_tex: Texture2D = r.assets.get_tex("prop_pine_tree.png")
	var dark_tex: Texture2D = r.assets.get_tex("prop_pine_dark.png", "prop_pine_tree.png")
	for tr: Dictionary in r.forest_trees:
		var tp: Vector2 = tr["pos"]
		if tp.y > tree_y_limit:
			break
		if tp.y < cam_y0 or tp.x < cam_x0 or tp.x > cam_x1:
			continue
		_draw_tree_prop(r, tr, pine_tex, dark_tex)

	# Dynamic Asymmetric Briar/Hawthorn Hedgerows (visual briars only; no permanent ground text!)
	var br_texs: Array[Texture2D] = []
	for b_info in [["bramble_west", r.BRAMBLE_WEST_POS], ["bramble_shortcut", r.BRAMBLE_SHORTCUT_POS]]:
		var bp: Vector2 = b_info[1]
		if GameState.cut_wilds_brambles.has(b_info[0]) or not cam_rect.has_point(bp):
			continue
		if br_texs.is_empty():
			for bi in range(3):
				var bt: Texture2D = r.assets.get_tex("prop_bramble_thicket_%d.png" % bi, "prop_bramble_thicket.png")
				if bt != null:
					br_texs.append(bt)
		if br_texs.is_empty():
			break
		var offsets: Array[Vector2] = [
			Vector2(-4, -33), Vector2(6, -11), Vector2(-5, 11), Vector2(5, 33)
		]
		for idx_b in range(offsets.size()):
			var sub_p: Vector2 = bp + offsets[idx_b]
			var btex := br_texs[(idx_b + (1 if b_info[0] == "bramble_shortcut" else 0)) % br_texs.size()]
			var rw := -64.0 if (idx_b % 2 == 1) else 64.0
			r.draw_texture_rect(btex, Rect2(sub_p.x - 32.0, sub_p.y - 25.0, rw, 50.0), false)

	# Obsidian Hollow Eastern Ridge Storm-Roots (confined cleanly between Stone Causeway parapets until blown off!)
	if not r.gate_blown_clear and cam_rect.has_point(Vector2(532, 306)):
		var roots_tex: Texture2D = r.assets.get_tex("prop_storm_roots.png", "prop_fallen_log.png")
		if roots_tex != null:
			var r_shake := sin(t_now * 52.0) * 3.5 * clampf(float(r.gate_rattle_timer), 0.0, 1.0)
			var r_col := Color(1.0, 0.88, 0.72) if float(r.gate_rattle_timer) > 0.0 else Color.WHITE
			r.draw_texture_rect(roots_tex, Rect2(Vector2(532 + r_shake, 306) - Vector2(32, 30), Vector2(64, 60)), false, r_col)

	# Clickable Riverbank & Gorge Capstan Winch Posts (with pixel reticle—never vector ring)
	var winch_tex: Texture2D = r.assets.get_tex("prop_winch_post.png")
	var ret_tex: Texture2D = r.assets.get_tex("prop_pixel_reticle.png")
	for wpost: Vector2 in [r.GORGE_WINCH_W, r.GORGE_WINCH_E, r.CREEK_WINCH_S, r.CREEK_WINCH_N]:
		if not cam_rect.has_point(wpost):
			continue
		if winch_tex != null:
			r.draw_texture_rect(winch_tex, Rect2(wpost - Vector2(24, 42), Vector2(48, 64)), false)
		var hovered := wpost.distance_to(r.hovered_winch_pos) < 8.0
		var hinted := float(r.winch_hint_timer) > 0.0 and wpost.distance_to(r.winch_hint_pos) < 8.0
		if ret_tex != null:
			var rsz := Vector2(48, 48) if (hovered or hinted) else Vector2(40, 40)
			var pulse_y := roundf(sin(t_now * 4.5) * 2.0) if (hovered or hinted) else 0.0
			var rcol := Color(1.0, 0.92, 0.48, 0.95) if (hovered or hinted) else Color(0.72, 0.95, 0.78, 0.50)
			r.draw_texture_rect(ret_tex, Rect2(wpost - Vector2(rsz.x * 0.5, 14.0 + rsz.y * 0.5 - pulse_y), rsz), false, rcol)
		if hovered:
			r.draw_arc(wpost + Vector2(0, -14), 17.0 + sin(t_now * 7.0) * 2.5, 0.0, TAU, 20, Color(0.98, 0.88, 0.46, 0.78), 1.6)
		if hinted:
			var ha := clampf(float(r.winch_hint_timer) / 1.15, 0.0, 1.0)
			var hrad := 14.0 + (1.0 - ha) * 24.0
			r.draw_arc(wpost + Vector2(0, -14), hrad, 0.0, TAU, 20, Color(1.0, 0.86, 0.36, 0.88 * ha), 2.2)

	# Visual Landmark Formations (Carved Cairns & Two-Horn Boulder — recognized visually vs Map [M], ZERO labels on ground!)
	var cairn_tex: Texture2D = r.assets.get_tex("prop_cairn_stone.png")
	if cairn_tex != null:
		for c_pt: Vector2 in [r.CAIRN_1_POS + Vector2(-58, -56), r.FIRE_BETA_POS + Vector2(68, -52), r.FROST_DEAD_POS + Vector2(-30, -48)]:
			if cam_rect.has_point(c_pt):
				r.draw_texture_rect(cairn_tex, Rect2(c_pt - Vector2(18, 24), Vector2(36, 48)), false)
	if rock_tex != null:
		var bh_pos: Vector2 = r.BOULDER_2HORN_POS + Vector2(56, -54)
		if cam_rect.has_point(bh_pos):
			r.draw_texture_rect(rock_tex, Rect2(bh_pos - Vector2(30, 34), Vector2(52, 52)), false)
			r.draw_texture_rect(rock_tex, Rect2(bh_pos - Vector2(4, 38), Vector2(40, 44)), false)

	# Clue Props (Hemlock Claw Gouges & Shattered Ballista Cart with spilled Survey Map)
	if cam_rect.has_point(r.CLUE_TRACKS_POS):
		var claw_tex: Texture2D = r.assets.get_tex("prop_claw_tracks.png", "prop_scorched_clue.png")
		if claw_tex != null:
			r.draw_texture_rect(claw_tex, Rect2(r.CLUE_TRACKS_POS - Vector2(40, 30), Vector2(80, 60)), false)
		if ret_tex != null and not GameState.wilds_clue_tracks:
			var pulse_sz := 44.0 + roundf(sin(t_now * 3.8) * 3.0) * 2.0
			var h_off := pulse_sz * 0.5
			r.draw_texture_rect(ret_tex, Rect2(r.CLUE_TRACKS_POS - Vector2(h_off, h_off), Vector2(pulse_sz, pulse_sz)), false, Color(0.98, 0.80, 0.40, 0.60))

	if cam_rect.has_point(r.CLUE_CART_POS):
		var wreck_name := "prop_ballista_wreck_looted.png" if GameState.has_forest_map else "prop_ballista_wreck.png"
		var wreck_tex: Texture2D = r.assets.get_tex(wreck_name, "prop_scorched_clue.png")
		if wreck_tex != null:
			r.draw_texture_rect(wreck_tex, Rect2(r.CLUE_CART_POS - Vector2(52, 40), Vector2(104, 80)), false)
		if ret_tex != null and not GameState.wilds_clue_scorched_pine:
			var pulse_sz2 := 44.0 + roundf(sin(t_now * 3.8) * 3.0) * 2.0
			var h_off2 := pulse_sz2 * 0.5
			r.draw_texture_rect(ret_tex, Rect2(r.CLUE_CART_POS - Vector2(h_off2, h_off2), Vector2(pulse_sz2, pulse_sz2)), false, Color(0.98, 0.86, 0.44, 0.72))

	# Dying / Breath-Clearing / Peaceful Slain Black-Scaled Dragon & Unhatched Egg
	if cam_rect.grow(100.0).has_point(r.BLACK_DRAGON_POS):
		var d_blk: Texture2D = null
		if r.dragon_visual_state == "reveal":
			d_blk = r.assets.get_tex("dragon_black_reveal.png", "dragon_black_dying_0.png")
		elif r.dragon_visual_state == "breath":
			var brframe := int(t_now * 6.0) % 2
			d_blk = r.assets.get_tex("dragon_black_breath_%d.png" % brframe, "dragon_black_reveal.png")
		elif r.dragon_visual_state == "dead":
			d_blk = r.assets.get_tex("dragon_black_dead.png", "dragon_black_dying_1.png")
		else:
			var bframe := int(t_now * 1.4) % 2
			d_blk = r.assets.get_tex("dragon_black_dying_%d.png" % bframe, "dragon_black_dying.png")
		if d_blk != null:
			r.draw_texture_rect(d_blk, Rect2(r.BLACK_DRAGON_POS - Vector2(112, 84), Vector2(224, 168)), false)

	# Dragon Gale Gust Streaks & Blown Bridge Debris
	for bs: Dictionary in r.breath_streaks:
		var b_alpha := clampf(float(bs["t"]) / float(bs["max_t"]), 0.0, 1.0)
		var b_p: Vector2 = bs["pos"]
		var b_len: float = float(bs["len"])
		var b_col: Color = bs["col"]
		b_col.a *= b_alpha
		r.draw_rect(Rect2(Vector2(roundf(b_p.x), roundf(b_p.y)), Vector2(b_len, float(bs["h"]))), b_col)
	for db_it: Dictionary in r.blown_debris:
		var d_alpha := clampf(float(db_it["t"]) / float(db_it["max_t"]), 0.0, 1.0)
		var dp: Vector2 = db_it["pos"]
		var sz := float(db_it["sz"])
		var col_d: Color = db_it["col"]
		col_d.a *= d_alpha
		r.draw_set_transform(dp, float(db_it["rot"]), Vector2.ONE)
		r.draw_rect(Rect2(-sz * 0.5, -sz * 0.35, sz, sz * 0.7), col_d)
		r.draw_set_transform(Vector2.ZERO)
	if not GameState.carrying_egg and cam_rect.has_point(r.EGG_NEST_POS):
		var egg_tex: Texture2D = r.assets.get_tex("prop_dragon_egg.png")
		var egg_p: Vector2 = r.EGG_NEST_POS + r.egg_reveal_offset
		if egg_tex != null:
			r.draw_texture_rect(egg_tex, Rect2(egg_p - Vector2(20, 24), Vector2(40, 48)), false)
		if ret_tex != null:
			var esz := 36.0 + roundf(sin(t_now * 3.5) * 2.0) * 2.0
			r.draw_texture_rect(ret_tex, Rect2(egg_p - Vector2(esz * 0.5, esz * 0.5), Vector2(esz, esz)), false, Color(0.98, 0.76, 0.32, 0.65))
	for sp: Dictionary in r.nest_sparks:
		var alpha := clampf(float(sp["t"]) / 0.8, 0.0, 1.0)
		var spos := Vector2(roundf(float(sp["pos"].x) * 0.5) * 2.0, roundf(float(sp["pos"].y) * 0.5) * 2.0)
		r.draw_rect(Rect2(spos - Vector2(2, 2), Vector2(4, 4)), Color(0.98, 0.78, 0.34, alpha))

	# Warm Campfires & Sparks (camera-culled!)
	var fframe := int(t_now * 5.0) % 2
	var fire_tex: Texture2D = r.assets.get_tex("prop_campfire_%d.png" % fframe)
	for cpos: Vector2 in [r.FIRE_0_POS, r.FIRE_ALPHA_POS, r.FIRE_BETA_POS]:
		if not cam_rect.has_point(cpos):
			continue
		r.draw_circle(cpos, 32.0, Color(0.95, 0.52, 0.18, 0.24))
		if fire_tex != null:
			r.draw_texture_rect(fire_tex, Rect2(cpos - Vector2(24, 28), Vector2(48, 48)), false)
		r.assets.draw_campfire_sparks(r, cpos + Vector2(0, -10), true)

	# Patrol Hunters
	if GameState.carrying_egg and GameState.current_step == GameState.QuestStep.ACT3_EGG_TREK:
		for hp: Dictionary in r.hunter_patrols:
			var hpos: Vector2 = hp["pos"]
			if not cam_rect.grow(90.0).has_point(hpos):
				continue
			var hdir: Vector2 = Vector2(hp["dir"]).normalized()
			var is_al := float(hp["alert"]) > 0.0
			var susp: float = float(hp.get("suspicion", 0.0))
			var c_col := Color(0.98, 0.32, 0.24, 0.28) if is_al else (Color(0.98, 0.58, 0.24, 0.24) if susp > 0.05 else Color(0.98, 0.80, 0.34, 0.16))
			r.draw_raycast_vision_cone(r, hpos + Vector2(0, -6), hdir, 136.0, deg_to_rad(32.0), r.sight_blockers, c_col, c_col.lightened(0.18))
			if susp > 0.05 and not is_al:
				r.draw_arc(hpos + Vector2(0, -48), 9.0, -PI * 0.5, -PI * 0.5 + TAU * susp, 14, Color(0.98, 0.62, 0.24), 2.5)
			var w_card := "side" if absf(hdir.x) > absf(hdir.y) else ("up" if hdir.y < 0.0 else "down")
			var is_p := float(hp.get("pause", 0.0)) > 0.0
			var w_step := 0 if is_p else (1 if int(floorf(float(hp.get("t", 0.0)) * 12.0)) % 2 == 0 else 2)
			r.assets.draw_npc_sprite(r, hpos, "npc_watchman_%s_%d.png" % [w_card, w_step], "! HUNTER !" if is_al else ("?" if susp > 0.05 else ""), font, Color(0.98, 0.56, 0.48) if is_al else Color(0.95, 0.84, 0.72), hdir.x < 0.0)

	# Brotherhood Watchtower Keep & Captain Anna
	if cam_rect.grow(100.0).has_point(r.OUTPOST_POS):
		var out_tex: Texture2D = r.assets.get_tex("building_outpost.png", "building_warehouse.png")
		if out_tex != null:
			r.draw_texture_rect(out_tex, Rect2(r.OUTPOST_POS - Vector2(96, 128), Vector2(192, 136)), false)
		if GameState.black_dragon_found:
			r.assets.draw_npc_sprite(r, r.OUTPOST_POS + Vector2(-42, 34), "npc_anna.png", "Anna", font)

	r.draw_interact_bubble_if_active(font)


static func draw_foreground(fg: Node2D, r) -> void:
	var t_now: float = r.assets.time_elapsed
	var p_pos: Vector2 = r.player.position if r.player != null else Vector2.ZERO
	var cam_rect := FrontierWildsEnvDrawScript.get_camera_rect(r, 150.0)
	var cam_x0 := cam_rect.position.x
	var cam_x1 := cam_rect.end.x
	var cam_y1 := cam_rect.end.y
	var pine_tex: Texture2D = r.assets.get_tex("prop_pine_tree.png")
	var dark_tex: Texture2D = r.assets.get_tex("prop_pine_dark.png", "prop_pine_tree.png")

	# Draw trees below player Y so player cleanly steps behind canopy crowns (Y-sorted + camera-culled!)
	var min_fg_y := maxf(p_pos.y - 6.0, cam_rect.position.y)
	for tr: Dictionary in r.forest_trees:
		var tp: Vector2 = tr["pos"]
		if tp.y > cam_y1:
			break
		if tp.y <= min_fg_y or tp.x < cam_x0 or tp.x > cam_x1:
			continue
		_draw_tree_prop(fg, tr, pine_tex, dark_tex)

	# Drifting pixel-art valley mist wisps (camera-culled!)
	var mist_rect := cam_rect.grow(160.0)
	for mr: Dictionary in r.mist_ribbons:
		var mp: Vector2 = mr["pos"]
		if not mist_rect.has_point(mp):
			continue
		var rx: float = float(mr["rx"])
		var ry: float = float(mr["ry"])
		var ph: float = float(mr["phase"])
		var pulse: float = 0.09 + 0.05 * sin(t_now * 0.9 + ph)
		var drift := sin(t_now * 0.45 + ph) * 14.0
		for row in range(-1, 2):
			var w := roundf(rx * (0.95 - absf(float(row)) * 0.25) * 0.5) * 2.0
			var y := roundf((mp.y + float(row) * ry * 0.36) * 0.5) * 2.0
			var x := roundf((mp.x + drift + float(row) * 10.0) * 0.5) * 2.0
			fg.draw_rect(Rect2(x - w * 0.5, y, w, 2.0), Color(0.74, 0.86, 0.92, pulse * (0.75 if row != 0 else 1.0)))

	# Floating golden & emerald woodland fireflies / dust motes (camera-culled!)
	for ff: Dictionary in r.fireflies:
		var b: Vector2 = ff["base"]
		if not cam_rect.has_point(b):
			continue
		var phase: float = float(ff["phase"])
		var spd: float = float(ff["speed"])
		var amp: float = float(ff["amp"])
		var fp := Vector2(b.x + sin(t_now * spd + phase) * amp, b.y + cos(t_now * (spd * 0.72) + phase * 1.3) * (amp * 0.65))
		var sp_fp := Vector2(roundf(fp.x * 0.5) * 2.0, roundf(fp.y * 0.5) * 2.0)
		var glow := 0.25 + 0.65 * maxf(0.0, sin(t_now * 2.6 + phase * 2.0))
		var col := Color(0.98, 0.86, 0.42, glow * 0.75) if bool(ff["warm"]) else Color(0.66, 0.95, 0.62, glow * 0.68)
		fg.draw_rect(Rect2(sp_fp - Vector2(2, 2), Vector2(4, 4)), Color(col.r, col.g, col.b, col.a * 0.30))
		fg.draw_rect(Rect2(sp_fp - Vector2(1, 1), Vector2(2, 2)), col)

	# Cold frost wind streaks inside chilling hollows
	if r._is_in_cold_zone(p_pos):
		for fi in range(14):
			var fx: float = p_pos.x + sin(t_now * 2.5 + float(fi) * 1.7) * 210.0
			var fy: float = p_pos.y + fmod(t_now * 72.0 + float(fi) * 39.0, 300.0) - 150.0
			fg.draw_line(Vector2(fx, fy), Vector2(fx - 26.0, fy + 8.0), Color(0.76, 0.92, 1.0, 0.52), 2.0)

	_draw_foreground_spray(fg, cam_rect, t_now)
	_draw_signal_flare(fg, r)
	_draw_wilds_fx_and_frost(fg, r, cam_rect, p_pos, t_now)


static func _draw_tree_prop(canvas: Node2D, tr: Dictionary, pine_tex: Texture2D, dark_tex: Texture2D) -> void:
	var tp: Vector2 = tr["pos"]
	var is_dark: bool = bool(tr.get("dark", false))
	var sc: float = float(tr.get("scale", 1.0))
	var tex: Texture2D = dark_tex if is_dark else pine_tex
	if tex == null:
		return
	var sz := Vector2(80.0 * sc, 112.0 * sc) if is_dark else Vector2(72.0 * sc, 96.0 * sc)
	var rw := -sz.x if bool(tr.get("flip", false)) else sz.x
	canvas.draw_texture_rect(tex, Rect2(tp.x - sz.x * 0.5, tp.y - sz.y * 0.84, rw, sz.y), false)


static func _draw_foreground_spray(fg: Node2D, cam_rect: Rect2, t_now: float) -> void:
	for sc in [
		[Vector2(496, 512), 24.0],
		[Vector2(1860, 466), 22.0],
		[Vector2(531, 360), 18.0],
		[Vector2(545, 1392), 18.0]
	]:
		var origin: Vector2 = sc[0]
		if not cam_rect.has_point(origin):
			continue
		var spread := float(sc[1])
		for k in range(5):
			var phase := fmod(t_now * 1.3 + float(k) * 0.21, 1.0)
			var mp := origin + Vector2((float(k) - 2.0) * (spread * 0.36) + sin(t_now * 2.8 + float(k)) * 5.0, -phase * 18.0)
			mp = Vector2(roundf(mp.x * 0.5) * 2.0, roundf(mp.y * 0.5) * 2.0)
			var alpha := sin(phase * PI) * 0.50
			var sz := 4.0 if phase < 0.6 else 2.0
			fg.draw_rect(Rect2(mp - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), Color(0.84, 0.95, 1.0, alpha))


static func _draw_signal_flare(fg: Node2D, r) -> void:
	if not r.flare_active:
		return
	var apex: Vector2 = r.flare_origin + r.FLARE_ASCENT_DELTA
	var orb_frame := int(r.assets.time_elapsed * 12.0) % 2
	var orb_tex: Texture2D = r.assets.get_tex("prop_flare_orb_%d.png" % orb_frame)
	var burst_tex: Texture2D = r.assets.get_tex("prop_flare_burst.png")
	if not r.flare_burst_done:
		var u := clampf(r.flare_t / 0.78, 0.0, 1.0)
		var ease_u := 1.0 - (1.0 - u) * (1.0 - u)
		var cur: Vector2 = r.flare_origin.lerp(apex, ease_u) + Vector2(-sin(u * PI) * 14.0, 0.0)
		for ti in range(5):
			var pu := maxf(0.0, u - float(ti + 1) * 0.06)
			var pe := 1.0 - (1.0 - pu) * (1.0 - pu)
			var prev: Vector2 = r.flare_origin.lerp(apex, pe) + Vector2(-sin(pu * PI) * 14.0, 0.0)
			prev = Vector2(roundf(prev.x * 0.5) * 2.0, roundf(prev.y * 0.5) * 2.0)
			var psz := 4.0 if ti < 2 else 2.0
			fg.draw_rect(Rect2(prev - Vector2(psz * 0.5, psz * 0.5), Vector2(psz, psz)), Color(0.42, 0.96, 0.62, 0.55 - float(ti) * 0.09))
		if orb_tex != null:
			var sc_cur := Vector2(roundf(cur.x * 0.5) * 2.0, roundf(cur.y * 0.5) * 2.0)
			fg.draw_texture_rect(orb_tex, Rect2(sc_cur - Vector2(18, 18), Vector2(36, 36)), false)
	else:
		var bt: float = maxf(0.0, r.flare_t - 0.78)
		var halo_a := clampf(1.0 - bt / 1.4, 0.0, 1.0)
		if halo_a > 0.02 and burst_tex != null:
			var bsz := 48.0 + roundf(bt * 36.0) * 2.0
			var sc_apex := Vector2(roundf(apex.x * 0.5) * 2.0, roundf(apex.y * 0.5) * 2.0)
			fg.draw_arc(sc_apex, 18.0 + bt * 68.0, 0.0, TAU, 24, Color(0.46, 1.0, 0.66, halo_a * 0.72), 2.6)
			fg.draw_texture_rect(burst_tex, Rect2(sc_apex - Vector2(bsz * 0.5, bsz * 0.5), Vector2(bsz, bsz)), false, Color(1.0, 1.0, 1.0, halo_a))
			if orb_tex != null and halo_a > 0.45:
				fg.draw_texture_rect(orb_tex, Rect2(sc_apex - Vector2(16, 16), Vector2(32, 32)), false, Color(1.0, 1.0, 1.0, halo_a))
	for sp: Dictionary in r.flare_sparks:
		var life := clampf(float(sp["t"]) / 2.2, 0.0, 1.0)
		var spos := Vector2(roundf(float(sp["pos"].x) * 0.5) * 2.0, roundf(float(sp["pos"].y) * 0.5) * 2.0)
		var col: Color = sp["col"]
		fg.draw_rect(Rect2(spos - Vector2(3, 3), Vector2(6, 6)), Color(col.r, col.g, col.b, life * 0.28))
		fg.draw_rect(Rect2(spos - Vector2(1, 1), Vector2(3, 3)), Color(col.r, col.g, col.b, life * 0.96))


static func _draw_wilds_fx_and_frost(fg: Node2D, r, cam_rect: Rect2, p_pos: Vector2, t_now: float) -> void:
	for fp: Dictionary in r.wilds_fx_particles:
		var fpos: Vector2 = Vector2(fp["pos"])
		if not cam_rect.has_point(fpos):
			continue
		var a: float = clampf(float(fp["t"]) / float(fp["max_t"]), 0.0, 1.0)
		var sz: float = float(fp["sz"])
		var col: Color = fp["col"]
		fg.draw_rect(Rect2(fpos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), Color(col.r, col.g, col.b, a))

	if float(r.winch_reach_timer) > 0.0:
		var wa := clampf(float(r.winch_reach_timer) / 1.15, 0.0, 1.0)
		fg.draw_arc(p_pos + Vector2(0, -10), 22.0 + (1.0 - wa) * 14.0, 0.0, TAU, 20, Color(0.96, 0.84, 0.44, 0.70 * wa), 2.0)

	var cold_ratio := 0.0
	if GameState.carrying_egg and GameState.current_step == GameState.QuestStep.ACT3_EGG_TREK and GameState.egg_warmth < 35.0:
		cold_ratio = clampf((35.0 - GameState.egg_warmth) / 35.0, 0.0, 1.0) * (0.45 + 0.35 * sin(t_now * 5.0))
	if cold_ratio > 0.02:
		var vr := FrontierWildsEnvDrawScript.get_camera_rect(r, 0.0)
		var rim_w := 14.0
		var frost_col := Color(0.68, 0.88, 1.0, cold_ratio * 0.42)
		fg.draw_rect(Rect2(vr.position.x, vr.position.y, vr.size.x, rim_w), frost_col)
		fg.draw_rect(Rect2(vr.position.x, vr.end.y - rim_w, vr.size.x, rim_w), frost_col)
		fg.draw_rect(Rect2(vr.position.x, vr.position.y, rim_w, vr.size.y), frost_col)
		fg.draw_rect(Rect2(vr.end.x - rim_w, vr.position.y, rim_w, vr.size.y), frost_col)

	if float(r.frost_reset_flash) > 0.0:
		var fa := clampf(float(r.frost_reset_flash) / 1.15, 0.0, 1.0)
		fg.draw_arc(p_pos + Vector2(0, -8), 18.0 + (1.0 - fa) * 44.0, 0.0, TAU, 22, Color(1.0, 0.72, 0.28, fa * 0.78), 2.6)
