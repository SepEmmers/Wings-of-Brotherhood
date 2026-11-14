class_name VirelaiFlightDraw
extends RefCounted

## Custom 2D canvas drawing helper for VirelaiFlightRegion.gd.


static func setup_layers(r) -> void:
	var water_created := r.get_node_or_null("EnvWaterLayer") == null
	r.setup_water_layer([Rect2(0, 0, 420, 1600)], 48.0, -3)
	if water_created:
		r.step_water_layer()
	r.setup_static_ground_chunks(
		Rect2(420, 0, 1980, 1600),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-2,
		false
	)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	r.assets.draw_varied_tiled_rect(canvas, Rect2(420, 0, 1980, 1600), r.assets.get_tex("tile_grass.png"), r.assets.get_tex("tile_grass_2.png"), 48.0, 17, r.assets.get_tex("tile_grass_3.png"))
	r.assets.draw_varied_tiled_rect(canvas, Rect2(1060, 0, 160, 1600), r.assets.get_tex("tile_cobble.png"), r.assets.get_tex("tile_cobble_2.png"), 48.0, 29)
	r.assets.draw_seam_run_v(canvas, "edge_grass_stone_w.png", 0.0, 1600.0, 1060.0)
	r.assets.draw_seam_run_v(canvas, "edge_grass_stone_e.png", 0.0, 1600.0, 1220.0)
	var pine_tex: Texture2D = r.assets.get_tex("prop_pine_tree.png")
	if pine_tex != null:
		for px in range(540, 2240, 240):
			for py in range(180, 1500, 280):
				if absf(px - 1140) < 110:
					continue
				canvas.draw_texture_rect(pine_tex, Rect2(Vector2(px, py) - Vector2(22, 42), Vector2(44, 58)), false)


static func draw_sky(r) -> void:
	setup_layers(r)
	var font := ThemeDB.fallback_font
	var t_now: float = r.assets.time_elapsed
	var cam_rect: Rect2 = r.get_camera_rect(180.0)

	var w_tex: Texture2D = r.assets.get_tex("prop_ballista_wagon.png")
	for w in r.wagons:
		var wp: Vector2 = w["pos"]
		if not cam_rect.has_point(wp) and float(w["aim_timer"]) <= 0.0:
			continue
		if not bool(w["alive"]):
			if cam_rect.has_point(wp):
				r.draw_circle(wp, 20.0, Color(0.14, 0.12, 0.12, 0.72))
				r.draw_line(wp + Vector2(-18, -8), wp + Vector2(18, 9), Color(0.24, 0.16, 0.10), 4.0)
				r.draw_line(wp + Vector2(-14, 12), wp + Vector2(16, -11), Color(0.20, 0.13, 0.09), 3.5)
				r.draw_arc(wp + Vector2(-10, 4), 10.0, 0.3, PI * 1.45, 10, Color(0.36, 0.24, 0.14), 2.5)
				r.draw_line(wp + Vector2(-10, 4), wp + Vector2(-3, -3), Color(0.36, 0.24, 0.14), 1.6)
				r.draw_line(wp + Vector2(-10, 4), wp + Vector2(-18, 8), Color(0.36, 0.24, 0.14), 1.6)
				var em_a := 0.55 + sin(t_now * 7.5 + wp.x) * 0.35
				r.draw_circle(wp + Vector2(4, -2), 4.2, Color(0.98, 0.44, 0.14, em_a))
				r.draw_circle(wp + Vector2(-4, 3), 2.8, Color(1.0, 0.68, 0.24, em_a))
				var sm_t := fmod(t_now * 0.75 + wp.y * 0.01, 1.0)
				r.draw_circle(wp + Vector2(sin(sm_t * 5.0) * 6.0, -8.0 - sm_t * 28.0), 5.0 + sm_t * 6.0, Color(0.46, 0.46, 0.48, (1.0 - sm_t) * 0.45))
			continue
		if float(w["aim_timer"]) > 0.0:
			var aim_p: float = 1.0 - clampf(float(w["aim_timer"]) / 1.35, 0.0, 1.0)
			var lock_col := Color(0.98, 0.25, 0.20, 0.35 + aim_p * 0.55)
			r.draw_line(wp + Vector2(0, -8), Vector2(w["aim_target"]), lock_col, 2.5 if aim_p > 0.65 else 1.5)
		if cam_rect.has_point(wp):
			var mod := Color(1.0, 0.45, 0.45) if float(w["flash"]) > 0.0 else Color.WHITE
			if w_tex != null:
				r.draw_texture_rect(w_tex, Rect2(wp - Vector2(42, 36), Vector2(84, 72)), false, mod)
			var max_hp: int = maxi(1, int(w["max_hp"]))
			var cur_hp: int = clampi(int(w["hp"]), 0, max_hp)
			var slot_span := float(max_hp - 1) * 12.0
			for bi in range(max_hp):
				var bx: float = wp.x - slot_span * 0.5 + float(bi) * 12.0
				var by: float = wp.y - 42.0
				if bi < cur_hp:
					r.draw_line(Vector2(bx, by + 6.0), Vector2(bx, by - 5.0), Color(0.24, 0.16, 0.10), 4.0)
					r.draw_line(Vector2(bx, by + 6.0), Vector2(bx, by - 5.0), Color(0.92, 0.36, 0.28), 2.2)
					r.draw_circle(Vector2(bx, by - 6.0), 2.2, Color(0.96, 0.86, 0.48))
				else:
					r.draw_line(Vector2(bx - 3.0, by - 3.0), Vector2(bx + 3.0, by + 4.0), Color(0.28, 0.18, 0.14, 0.85), 2.0)
			if cur_hp < max_hp:
				r.draw_line(wp + Vector2(-12, -10), wp + Vector2(-2, 4), Color(0.18, 0.10, 0.08, 0.90), 2.2)
				r.draw_line(wp + Vector2(-2, 4), wp + Vector2(8, -4), Color(0.98, 0.48, 0.20, 0.72), 1.6)
				var dmg_sm := fmod(t_now * 1.1 + wp.x * 0.02, 1.0)
				r.draw_circle(wp + Vector2(4.0, -24.0 - dmg_sm * 20.0), 3.5 + dmg_sm * 4.5, Color(0.38, 0.36, 0.38, (1.0 - dmg_sm) * 0.52))

	var net_tex: Texture2D = r.assets.get_tex("prop_sky_net.png")
	var dframe := int(t_now * 4.5) % 2
	for dr in r.wild_dragons:
		var dp: Vector2 = dr["pos"]
		if not cam_rect.has_point(dp):
			continue
		var dtex: Texture2D = r.assets.get_tex("%s_%d.png" % [dr["tex"], dframe], dr["tex"] + ".png")
		if dtex != null:
			r.draw_set_transform(dp + Vector2(20, 34), 0.0, Vector2(1.05, 1.05))
			r.draw_texture(dtex, -Vector2(dtex.get_width(), dtex.get_height()) * 0.5, Color(0.02, 0.03, 0.05, 0.30))
			r.draw_set_transform(dp, sin(t_now * 3.0 + dp.x * 0.01) * 0.12 if bool(dr["freed"]) else 0.0, Vector2(1.45, 1.45))
			r.draw_texture(dtex, -Vector2(dtex.get_width(), dtex.get_height()) * 0.5)
			r.draw_set_transform(Vector2.ZERO)
		if not bool(dr["freed"]):
			var net_vib := sin(t_now * 16.0 + dp.x * 0.05) * 1.8
			if net_tex != null:
				r.draw_texture_rect(net_tex, Rect2(dp + Vector2(net_vib, 0.0) - Vector2(46, 40), Vector2(92, 80)), false, Color(1.0, 1.0, 1.0, 0.88))
			var rope_strain := 0.55 + 0.45 * sin(t_now * 8.0)
			for c_off: Vector2 in [Vector2(-38, -28), Vector2(38, -28), Vector2(-36, 30), Vector2(36, 30)]:
				var edge_pt: Vector2 = dp + c_off + Vector2(net_vib, 0.0)
				r.draw_line(dp, edge_pt, Color(0.86, 0.72, 0.36, 0.55 + rope_strain * 0.35), 2.0)
				r.draw_circle(edge_pt, 2.8 + rope_strain * 1.6, Color(0.98, 0.86, 0.44, 0.75 + rope_strain * 0.25))
			r.draw_arc(dp, 46.0 + sin(t_now * 5.0) * 3.0, 0.0, TAU, 20, Color(0.98, 0.78, 0.36, 0.58), 1.8)
		elif not bool(dr["sketched"]):
			r.draw_arc(dp, 54.0 + sin(t_now * 4.0) * 4.0, 0.0, TAU, 24, Color(0.45, 0.96, 0.68, 0.72), 2.0)
			if not r.nearby_sketch_dragon.is_empty() and r.nearby_sketch_dragon.get("id", "") == dr["id"]:
				r.assets.draw_interact_bubble(r, dp + Vector2(0, -54), "[E] Sketch " + str(dr["breed"]), font)

	var ur_tex: Texture2D = r.assets.get_tex("prop_updraft_ring.png")
	for ur in r.updraft_rings:
		if float(ur["cd"]) > 0.0:
			continue
		var up: Vector2 = ur["pos"]
		if not cam_rect.has_point(up):
			continue
		var scl := 1.7 + sin(t_now * 4.5 + up.x) * 0.15
		if ur_tex != null:
			r.draw_set_transform(up, t_now * 1.4, Vector2(scl, scl))
			r.draw_texture(ur_tex, Vector2(-16, -16))
			r.draw_set_transform(Vector2.ZERO)
		else:
			r.draw_arc(up, 26.0, 0.0, TAU, 18, Color(0.55, 0.92, 0.98), 2.5)

	for ws in r.wind_streaks:
		if cam_rect.has_point(ws["pos"]):
			var a := clampf(float(ws["life"]) / 0.32, 0.0, 1.0)
			r.draw_circle(ws["pos"], 2.5, Color(0.90, 0.96, 1.0, a * 0.55))

	var pbolt_tex: Texture2D = r.assets.get_tex("prop_crossbow_bolt.png")
	for pb in r.player_bolts:
		if not cam_rect.has_point(pb["pos"]):
			continue
		var ang := Vector2(pb["vel"]).angle() + PI * 0.5
		if pbolt_tex != null:
			r.draw_set_transform(pb["pos"], ang, Vector2(1.6, 1.6))
			r.draw_texture(pbolt_tex, Vector2(-8, -8))
			r.draw_set_transform(Vector2.ZERO)
		else:
			r.draw_circle(pb["pos"], 4.0, Color(0.95, 0.85, 0.35))

	var ebolt_tex: Texture2D = r.assets.get_tex("prop_hunter_bolt.png")
	for eb in r.enemy_bolts:
		if not cam_rect.has_point(eb["pos"]):
			continue
		var ang := Vector2(eb["vel"]).angle() + PI * 0.5
		if ebolt_tex != null:
			r.draw_set_transform(eb["pos"], ang, Vector2(1.7, 1.7))
			r.draw_texture(ebolt_tex, Vector2(-8, -8))
			r.draw_set_transform(Vector2.ZERO)
		else:
			r.draw_circle(eb["pos"], 5.0, Color(0.95, 0.25, 0.25))

	for hp_fx in r.hit_puffs:
		if cam_rect.has_point(hp_fx["pos"]):
			var alpha: float = clampf(float(hp_fx["t"]) / 0.45, 0.0, 1.0)
			r.draw_circle(hp_fx["pos"], (1.0 - alpha) * 32.0 + 8.0, Color(0.98, 0.72, 0.32, alpha * 0.6))

	for vb in r.venom_beams:
		var va := clampf(float(vb["t"]) / float(vb["max_t"]), 0.0, 1.0)
		var from_pt := Vector2(vb["from"])
		var to_pt := Vector2(vb["to"])
		if cam_rect.has_point(from_pt) or cam_rect.has_point(to_pt):
			r.draw_line(from_pt, to_pt, Color(0.46, 0.96, 0.42, va * 0.78), 5.0 * va + 1.5)
			r.draw_circle(to_pt, (1.0 - va) * 28.0 + 10.0, Color(0.36, 0.92, 0.34, va * 0.55))

	if not r.attack_cutscene_active:
		var forward_ret: Vector2 = r.dragon_pos + Vector2.from_angle(r.dragon_angle) * 115.0
		r.draw_arc(forward_ret, 8.0, 0.0, TAU, 12, Color(0.96, 0.84, 0.46, 0.38), 1.5)

	var vframe := int(t_now * (9.0 if (Input.is_action_pressed("sprint") or r.thermal_timer > 0.0) else 4.5)) % 2
	var vtex: Texture2D = r.assets.get_tex("dragon_anna_%d.png" % vframe, "dragon_anna.png")
	var rot: float = r.dragon_angle - PI * 0.5
	var bank_tilt: float = sin(t_now * 28.0) * 0.35 if r.barrel_timer > 0.0 else 0.0
	var vmod := Color(1.0, 0.55, 0.55, 0.80) if (r.hurt_timer > 0.0 and int(r.hurt_timer * 18.0) % 2 == 0) else (Color(0.78, 0.86, 0.94, 0.72) if r.in_cloud_cover else Color.WHITE)

	if vtex != null:
		r.draw_set_transform(r.dragon_pos + Vector2(30, 56), rot + bank_tilt, Vector2(0.86, 0.86))
		r.draw_texture(vtex, -Vector2(vtex.get_width(), vtex.get_height()) * 0.5, Color(0.02, 0.03, 0.05, 0.34))
		r.draw_set_transform(r.dragon_pos, rot + bank_tilt, Vector2(1.18, 1.18))
		r.draw_texture(vtex, -Vector2(vtex.get_width(), vtex.get_height()) * 0.5, vmod)
		r.draw_set_transform(Vector2.ZERO)

	if not r.boy_fall_active:
		var saddle_boy: Texture2D = r.assets.get_tex("boy_saddle_%d.png" % vframe, "boy_down_0.png")
		if saddle_boy != null:
			var saddle_off := -Vector2.from_angle(r.dragon_angle) * 4.5
			r.draw_set_transform(r.dragon_pos + saddle_off, rot + bank_tilt, Vector2(1.18, 1.18))
			r.draw_texture(saddle_boy, -Vector2(saddle_boy.get_width(), saddle_boy.get_height()) * 0.5)
			r.draw_set_transform(Vector2.ZERO)
	else:
		var fall_tex: Texture2D = r.assets.get_tex("boy_roll.png")
		if fall_tex != null:
			r.draw_set_transform(r.boy_fall_pos, r.boy_fall_rot, Vector2(1.45, 1.45))
			r.draw_texture(fall_tex, -Vector2(fall_tex.get_width(), fall_tex.get_height()) * 0.5)
			r.draw_set_transform(Vector2.ZERO)

	if r.blk_visible:
		var bframe := int(t_now * 9.5) % 2
		var btex: Texture2D = r.assets.get_tex("dragon_black_fly_%d.png" % bframe, "dragon_black_fly_0.png")
		if btex != null:
			var brot: float = r.blk_vel.angle() - PI * 0.5
			r.draw_set_transform(r.blk_pos + Vector2(34, 62), brot, Vector2(1.0, 1.0))
			r.draw_texture(btex, -Vector2(btex.get_width(), btex.get_height()) * 0.5, Color(0.02, 0.02, 0.04, 0.36))
			r.draw_set_transform(r.blk_pos, brot, Vector2(1.32, 1.32))
			r.draw_texture(btex, -Vector2(btex.get_width(), btex.get_height()) * 0.5)
			r.draw_set_transform(Vector2.ZERO)

	if GameState.virelai_loose_straps > 0 and not r.attack_cutscene_active:
		var left_flank: Vector2 = Vector2(r.dragon_pos) + Vector2.from_angle(float(r.dragon_angle) - PI * 0.6) * 20.0
		var flap_tip: Vector2 = left_flank + Vector2(sin(t_now * 19.0) * 11.0 - 15.0, cos(t_now * 15.0) * 8.0 + 15.0)
		r.draw_line(left_flank, flap_tip, Color(0.56, 0.34, 0.18), 3.4)
		r.draw_circle(flap_tip, 3.8, Color(0.98, 0.78, 0.28))
		var pulse := 36.0 + sin(t_now * 8.0) * 5.0
		var warn_a := 0.94 if r.strap_slip_flash > 0.0 else 0.78
		r.draw_arc(r.dragon_pos, pulse, 0.0, TAU, 24, Color(0.98, 0.32, 0.24, warn_a), 2.8)
		r.draw_arc(flap_tip, 9.0 + sin(t_now * 14.0) * 3.0, PI * 0.2, PI * 1.4, 10, Color(1.0, 0.64, 0.28, warn_a), 2.2)
		for si in range(4):
			var st := fmod(t_now * 5.0 + float(si) * 0.25, 1.0)
			var spos := flap_tip + Vector2(cos(float(si) * 1.6 + t_now * 4.0) * (6.0 + st * 14.0), sin(float(si) * 1.6) * (4.0 + st * 12.0))
			r.draw_circle(spos, 2.4 * (1.0 - st * 0.5), Color(1.0, 0.42 + (si % 2) * 0.4, 0.24, 1.0 - st))

	for sk in r.sketch_fly_fx:
		var sp: float = 1.0 - clampf(float(sk["t"]) / maxf(0.01, float(sk["max_t"])), 0.0, 1.0)
		var start_p := Vector2(sk["from"])
		var end_p := Vector2(cam_rect.end.x - 190.0, cam_rect.position.y + 195.0)
		var mid_p := start_p.lerp(end_p, 0.5) + Vector2(-45.0, -75.0)
		var q1 := start_p.lerp(mid_p, sp)
		var q2 := mid_p.lerp(end_p, sp)
		var p_now := q1.lerp(q2, sp)
		var flutter := sin(sp * TAU * 2.0) * 4.0
		r.draw_rect(Rect2(p_now - Vector2(9, 7) + Vector2(0, flutter), Vector2(18, 14)), Color(0.96, 0.90, 0.72, 1.0 - sp * 0.2))
		r.draw_rect(Rect2(p_now - Vector2(9, 7) + Vector2(0, flutter), Vector2(18, 14)), Color(0.42, 0.30, 0.16, 1.0 - sp * 0.2), false, 1.4)
		r.draw_line(p_now + Vector2(-5, -2 + flutter), p_now + Vector2(5, 2 + flutter), Color(0.22, 0.18, 0.16), 1.4)
		r.draw_circle(p_now, 12.0 * (1.0 - sp * 0.5), Color(0.98, 0.88, 0.48, (1.0 - sp) * 0.45))

	for c in r.clouds:
		var cpos := Vector2(c["pos"])
		var sc: float = float(c["scale"])
		var sz := Vector2(64.0 * sc, 40.0 * sc)
		var crect := Rect2(cpos - sz * 0.5, sz)
		if not cam_rect.intersects(crect):
			continue
		var ctex: Texture2D = r.assets.get_tex(c["tex"])
		if ctex != null:
			r.draw_texture_rect(ctex, crect, false, Color(1.0, 1.0, 1.0, 0.62 if r.sortie_id == 1 else 0.78))

	if r.intro_shadow_t > 0.0 and not r.attack_cutscene_active:
		var sp := 1.0 - clampf(r.intro_shadow_t / 1.65, 0.0, 1.0)
		var sh_pos := Vector2(360.0 + sp * 780.0, 860.0 + sin(sp * PI) * -90.0)
		if cam_rect.has_point(sh_pos):
			var sh_tex: Texture2D = r.assets.get_tex("dragon_black_fly_%d.png" % (int(t_now * 8.0) % 2), "dragon_black_fly_0.png")
			if sh_tex != null:
				r.draw_set_transform(sh_pos, -0.35, Vector2(1.15, 1.15))
				r.draw_texture(sh_tex, -Vector2(sh_tex.get_width(), sh_tex.get_height()) * 0.5, Color(0.02, 0.02, 0.04, 0.42 * (1.0 - sp)))
				r.draw_set_transform(Vector2.ZERO)

	if r.storm_flash > 0.01:
		r.draw_rect(cam_rect, Color(0.92, 0.96, 1.0, clampf(r.storm_flash * 0.42, 0.0, 0.5)))
