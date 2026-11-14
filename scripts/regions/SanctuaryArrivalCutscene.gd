class_name SanctuaryArrivalCutscene
extends RefCounted

## Arrival cutscene in Sanctuary after the Bruges night rescue:
## Virelai glides down from the western mist, dips her shoulder so the blindfolded boy can dismount,
## and Anna unties his blindfold before their first conversation on the cliff perch.


static func start_arrival(r) -> void:
	r.arrival_active = true
	r.arrival_stage = 0
	r.arrival_t = 0.0
	r.arrival_hide_ground_duo = true
	r.arrival_virelai_pos = Vector2(140, 125)
	r.arrival_virelai_alt = 185.0
	r.arrival_virelai_dip = 0.0
	r.arrival_anna_pos = Vector2(326, 424)
	r.arrival_cloth_pos = Vector2.ZERO
	r.arrival_cloth_timer = 0.0
	r.arrival_puffs.clear()

	r.player.position = Vector2(342, 438)
	r.player.facing = Vector2.RIGHT
	r.player.set_cutscene_pose("", false, true, true)
	r.player.can_move = false
	r.director.camera.zoom = Vector2(1.5, 1.5)
	r.director.camera.position = Vector2(290, 360)

	r.ui.set_fade(1.0, true)
	r.ui.set_cinematic_mode(true, func(): skip_arrival(r))
	SoundManager.play_wing_beat()


static func process_arrival(r, delta: float) -> void:
	if not r.arrival_active:
		return
	r.arrival_t += delta
	r.arrival_cloth_timer = maxf(0.0, r.arrival_cloth_timer - delta)
	for i in range(r.arrival_puffs.size() - 1, -1, -1):
		var pf: Dictionary = r.arrival_puffs[i]
		pf["t"] = float(pf["t"]) - delta
		pf["pos"] = Vector2(pf["pos"]) + Vector2(pf["vel"]) * delta
		if float(pf["t"]) <= 0.0:
			r.arrival_puffs.remove_at(i)

	match r.arrival_stage:
		0:
			# Virelai glides down through mist toward the stone landing clearing
			var p := clampf(r.arrival_t / 1.45, 0.0, 1.0)
			var ep := p * p * (3.0 - 2.0 * p)
			r.ui.set_fade(1.0 - clampf(r.arrival_t / 0.45, 0.0, 1.0), true)
			r.arrival_virelai_pos = Vector2(140, 125).lerp(Vector2(368, 384), ep)
			r.arrival_virelai_alt = lerpf(185.0, 0.0, ep)
			r.director.camera.position = Vector2(290, 360).lerp(Vector2(335, 435), ep)
			if r.arrival_t >= 0.72 and r.arrival_t - delta < 0.72:
				SoundManager.play_wing_beat()
			if r.arrival_t >= 1.45:
				r.arrival_stage = 1
				r.arrival_t = 0.0
				r.arrival_hide_ground_duo = false
				r.arrival_anna_pos = Vector2(326, 424)
				r.player.position = Vector2(342, 438)
				r.player.set_cutscene_pose("", false, true, false)
				r.director.trigger_camera_shake(4.5, 0.25)
				SoundManager.play_step(true)
				for k in range(10):
					var ang := TAU * float(k) / 10.0
					r.arrival_puffs.append({
						"pos": Vector2(368, 412) + Vector2(cos(ang) * 26.0, sin(ang) * 14.0),
						"vel": Vector2(cos(ang) * 58.0, sin(ang) * 28.0),
						"t": 0.55,
						"max_t": 0.55,
					})
		1:
			# Virelai lowers her shoulder as blindfolded Boy dismounts and Anna steps down beside him
			var p := clampf(r.arrival_t / 1.05, 0.0, 1.0)
			var ep := p * p * (3.0 - 2.0 * p)
			r.arrival_virelai_dip = sin(p * PI) * 12.0
			r.player.position = Vector2(342, 438).lerp(Vector2(265, 504), ep)
			r.player.facing = Vector2.RIGHT
			r.arrival_anna_pos = Vector2(326, 424).lerp(Vector2(288, 502), ep)
			r.director.camera.position = Vector2(335, 435).lerp(Vector2(305, 475), ep)
			if r.arrival_t >= 1.05:
				r.arrival_stage = 2
				r.arrival_t = 0.0
				r.arrival_virelai_dip = 0.0
				r.arrival_cloth_pos = Vector2(272, 492)
				r.arrival_cloth_timer = 0.85
				r.player.set_cutscene_pose("")
				SoundManager.play_knot_snag()
		2:
			# Cloth drops cleanly to the cobbles while Anna steps back onto her mark
			var p := clampf(r.arrival_t / 0.85, 0.0, 1.0)
			r.arrival_anna_pos = Vector2(288, 502).lerp(r.ACT2_ANNA_POS, p)
			r.director.camera.position = Vector2(305, 475).lerp(r.player.position + Vector2(38, -22), p)
			if r.arrival_t >= 0.85:
				finish_arrival(r)


static func skip_arrival(r) -> void:
	if r.arrival_active:
		finish_arrival(r, true)


static func finish_arrival(r, was_skipped: bool = false) -> void:
	r.arrival_active = false
	r.arrival_hide_ground_duo = false
	r.arrival_virelai_dip = 0.0
	r.arrival_cloth_timer = 0.0
	r.arrival_puffs.clear()
	r.player.position = Vector2(265, 504)
	r.player.facing = Vector2.RIGHT
	r.player.set_cutscene_pose("")
	r.player.can_move = true
	r.director.camera.zoom = Vector2(1.5, 1.5)
	r.director.camera.position = r.player.position
	r.ui.set_fade(0.0, was_skipped)
	r.ui.set_cinematic_mode(false)
	r.queue_redraw()
	if was_skipped:
		return
	r.ui.show_dialogue([
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Keep your boots clear of the cliff drop, boy."},
		{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Keep that thing back! What did you do with my sister?!"},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "We don't snatch ropewalk girls in the dark. Half the Church's scouts fly stolen dragon-gear when they raid the harbor."},
		{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Liar! Then why knock me out on the cobbles?!"},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Because three steps more would have brought an Inquisitor's torch down on everyone here. You want bread and answers? Start under Saddler Hendrick by the south rack."}
	])


static func draw_arrival_fx(r, _t_now: float) -> void:
	var assets = r.assets
	for pf in r.arrival_puffs:
		var a := clampf(float(pf["t"]) / float(pf["max_t"]), 0.0, 1.0)
		r.draw_circle(Vector2(pf["pos"]), 5.0 + (1.0 - a) * 8.0, Color(0.84, 0.88, 0.92, a * 0.48))

	if r.arrival_hide_ground_duo:
		var alt := float(r.arrival_virelai_alt)
		var vpos := Vector2(r.arrival_virelai_pos)
		var shadow_sc := clampf(1.2 - alt / 260.0, 0.35, 1.0)
		r.draw_circle(vpos + Vector2(0, 28), 58.0 * shadow_sc, Color(0.04, 0.06, 0.08, 0.34 * shadow_sc))
		var wf := int(r.assets.time_elapsed * 8.0) % 2
		var vtex: Texture2D = assets.get_tex("dragon_fly_%d.png" % wf, "dragon_anna_%d.png" % wf)
		if vtex != null:
			var draw_p := vpos - Vector2(0, alt)
			r.draw_texture_rect(vtex, Rect2(draw_p - Vector2(88, 72), Vector2(176, 144)), false)
	elif r.arrival_active:
		assets.draw_npc_sprite(r, r.arrival_anna_pos, "npc_anna.png", "Captain Anna", ThemeDB.fallback_font)

	if r.arrival_cloth_timer > 0.0:
		var cp := 1.0 - clampf(r.arrival_cloth_timer / 0.85, 0.0, 1.0)
		var fall_pos := Vector2(r.arrival_cloth_pos) + Vector2(-8.0 * cp, 16.0 * cp * cp)
		r.draw_line(fall_pos + Vector2(-6, -2), fall_pos + Vector2(6, 2), Color(0.76, 0.68, 0.56, 1.0 - cp * 0.6), 3.0)
