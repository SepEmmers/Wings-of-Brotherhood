class_name PortOfBrugesAmbush
extends RefCounted

## Dawn watchman patrol AI and the Brotherhood ambush/abduction cutscene for PortOfBrugesRegion.gd.


static func setup_watchmen(r) -> void:
	r.watchman_patrols.assign([
		{
			"a": Vector2(1185, 560),
			"b": Vector2(960, 560),
			"pos": Vector2(1185, 560),
			"dir": Vector2.LEFT,
			"t": 0.0,
			"dir_sign": 1.0,
			"speed": 0.19,
			"pause": 0.4,
			"suspicion": 0.0,
			"alert": 0.0
		},
		{
			"a": Vector2(885, 420),
			"b": Vector2(885, 635),
			"pos": Vector2(885, 420),
			"dir": Vector2.DOWN,
			"t": 0.5,
			"dir_sign": 1.0,
			"speed": 0.18,
			"pause": 0.0,
			"suspicion": 0.0,
			"alert": 0.0
		}
	])
	for wp in r.watchman_patrols:
		var wl: PointLight2D = r.assets.make_point_light(wp["pos"], 2.1, Color(1.0, 0.72, 0.34), 0.0)
		r.add_child(wl)
		r.watchman_lights.append(wl)


static func update_watchmen(r, delta: float) -> void:
	var patrol_active := (GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH)
	r.alert_cooldown = maxf(0.0, r.alert_cooldown - delta)

	for i in range(r.watchman_patrols.size()):
		var wp: Dictionary = r.watchman_patrols[i]
		var wl: PointLight2D = r.watchman_lights[i]
		if not patrol_active:
			wl.energy = 0.0
			continue

		wl.energy = 0.85
		wp["alert"] = maxf(0.0, float(wp["alert"]) - delta)

		if not r.ui.is_blocking_gameplay():
			var a: Vector2 = wp["a"]
			var b: Vector2 = wp["b"]
			var base_dir := (b - a).normalized()
			if float(wp["pause"]) > 0.0:
				wp["pause"] = maxf(0.0, float(wp["pause"]) - delta)
			else:
				var nt := float(wp["t"]) + delta * float(wp["speed"]) * float(wp["dir_sign"])
				if nt >= 1.0:
					nt = 1.0
					wp["dir_sign"] = -1.0
					wp["pause"] = 1.15
				elif nt <= 0.0:
					nt = 0.0
					wp["dir_sign"] = 1.0
					wp["pause"] = 1.15
				wp["t"] = nt
			wp["pos"] = a.lerp(b, float(wp["t"]))
			wp["dir"] = base_dir * float(wp["dir_sign"])
		wl.position = wp["pos"] + Vector2(wp["dir"]).normalized() * 24.0

		var in_beam := false
		if r.alert_cooldown <= 0.0 and not r.ui.is_blocking_gameplay() and not r.player.is_invulnerable():
			var w_eye: Vector2 = Vector2(wp["pos"]) + Vector2(0, -6)
			var p_eye: Vector2 = r.player.position + Vector2(0, -6)
			var w_dir: Vector2 = Vector2(wp["dir"]).normalized()
			if r.can_vision_cone_see(w_eye, w_dir, p_eye, 145.0, deg_to_rad(36.0), r.sight_blockers, 24.0):
				var dist: float = w_eye.distance_to(p_eye)
				in_beam = true
				var fill_rate := 3.8 if dist < 44.0 else 1.85
				wp["suspicion"] = minf(1.0, float(wp["suspicion"]) + delta * fill_rate)
				if float(wp["suspicion"]) >= 1.0:
					for w_rst in r.watchman_patrols:
						w_rst["suspicion"] = 0.0
						w_rst["alert"] = 0.0
						w_rst["pause"] = 0.9
					r.watchman_patrols[0]["t"] = 0.0
					r.watchman_patrols[0]["dir_sign"] = 1.0
					if r.watchman_patrols.size() > 1:
						r.watchman_patrols[1]["t"] = 0.5
						r.watchman_patrols[1]["dir_sign"] = 1.0
					r.alert_cooldown = 2.6
					wp["alert"] = 1.6
					SoundManager.play_alert_horn()
					r.director.trigger_camera_shake(6.5, 0.30)
					r.player.trigger_hurt_flash()
					GameState.bruges_stealth_alerts += 1
					GameState.boy_hp = maxi(0, GameState.boy_hp - 1)
					GameState.emit_signal("state_updated")
					if GameState.boy_hp <= 0:
						r.ui.show_death_screen("Cornered and seized by the Dawn Church Watchmen before reaching the Harbor Square.", func():
							GameState.boy_hp = GameState.boy_max_hp
							GameState.emit_signal("state_updated")
							r.director.load_region("house", {"spawn": Vector2(640, 445), "step": GameState.QuestStep.SNITCH_TO_CHURCH, "caught_return": true})
						)
						return
					r.ui.show_mission_failed_screen("Spotted by a Church Watchman's lantern beam! Stay behind buildings and cargo stacks. (%d/%d HP left)" % [GameState.boy_hp, GameState.boy_max_hp], func():
						r.player.position = Vector2(1310, 902)
						r.player.facing = Vector2.DOWN
						r.ui.refresh_hud()
					)
					return
		if not in_beam:
			wp["suspicion"] = maxf(0.0, float(wp["suspicion"]) - delta * 2.1)


static func trigger_ambush(r) -> void:
	GameState.current_step = GameState.QuestStep.BROTHERHOOD_AMBUSH
	r.ambush_cutscene_active = true
	r.ambush_stage = 0
	r.ambush_t = 0.0
	r.ambush_wait_dlg = false
	r.amb_anchor = r.player.position
	r.amb_rider_l = r.AMBUSH_CENTER + Vector2(-42, -20)
	r.amb_rider_r = r.AMBUSH_CENTER + Vector2(38, 18)
	r.amb_anna = r.AMBUSH_CENTER + Vector2(0, -45)
	r.amb_virelai = r.amb_anchor + Vector2(200, -320)
	r.amb_virelai_visible = false
	r.amb_virelai_alt = 130.0
	r.amb_dust_puffs.clear()
	r.player.facing = Vector2.UP
	r.player.set_cutscene_pose("boy_knife_0.png")
	r.ui.set_cinematic_mode(true, r._skip_abduction_cutscene)
	r.ui.refresh_hud()


static func process_abduction(r, delta: float) -> void:
	r.ambush_t += delta
	match r.ambush_stage:
		0:
			r.director.camera.zoom = r.director.camera.zoom.lerp(Vector2(1.70, 1.70), minf(1.0, delta * 3.5))
			r.amb_rider_l = r.amb_rider_l.move_toward(r.amb_anchor + Vector2(-46, -12), delta * 82.0)
			r.amb_rider_r = r.amb_rider_r.move_toward(r.amb_anchor + Vector2(46, 4), delta * 82.0)
			if r.ambush_t >= 0.85:
				r.ambush_wait_dlg = true
				r.ui.show_dialogue([
					{"speaker": "Hooded Brotherhood Rider", "portrait": "portrait_brotherhood.png", "text": "Hold it, boy. Turn around and walk away from the square."},
					{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Let go of me! You took Clara—I found your strap! GUARDS!!"},
					{"speaker": "Hooded Brotherhood Rider", "portrait": "portrait_brotherhood.png", "text": "Shut his mouth! Look what's in his fist—finish it before the watch turns."}
				], func():
					r.ambush_wait_dlg = false
					r.ambush_stage = 1
					r.ambush_t = 0.0
					SoundManager.play_door()
				)
		1:
			r.amb_anna = r.amb_anna.move_toward(r.amb_anchor + Vector2(0, -48), delta * 115.0)
			if r.ambush_t >= 0.90:
				r.ambush_wait_dlg = true
				r.player.set_cutscene_pose("")
				r.ui.show_dialogue([
					{"speaker": "Hooded Captain", "portrait": "portrait_anna.png", "text": "Put the blade away."},
					{"speaker": "Hooded Brotherhood Rider", "portrait": "portrait_brotherhood.png", "text": "Captain—he's fifty paces from the pulpit!"},
					{"speaker": "Hooded Captain", "portrait": "portrait_anna.png", "text": "I'm not slitting a twelve-year-old's throat over a scrap of leather. Blindfold him and clip him into Virelai's belly-net."}
				], func():
					r.ambush_wait_dlg = false
					r.ambush_stage = 2
					r.ambush_t = 0.0
					r.amb_virelai_visible = true
					SoundManager.play_wing_beat()
				)
		2:
			r.amb_virelai = r.amb_virelai.move_toward(r.amb_anchor + Vector2(18, -110), delta * 240.0)
			r.amb_virelai_alt = move_toward(r.amb_virelai_alt, 18.0, delta * 110.0)
			if int(r.ambush_t * 10.0) > int((r.ambush_t - delta) * 10.0):
				r.amb_dust_puffs.append({
					"pos": r.amb_anchor + Vector2(randf_range(-56, 56), randf_range(-34, 18)),
					"vel": Vector2(randf_range(-70, 70), randf_range(-30, 30)),
					"t": 0.55,
					"max_t": 0.55,
				})
			if r.ambush_t >= 0.72 and int(r.ambush_t * 10.0) == 7:
				SoundManager.play_wing_beat()
				r.director.trigger_camera_shake(5.5, 0.30)
			if r.ambush_t >= 1.40:
				SoundManager.play_knot_cinch()
				r.player.set_cutscene_pose("", false, true)
				r.ambush_stage = 3
				r.ambush_t = 0.0
		3:
			r.amb_rider_r = r.amb_rider_r.move_toward(r.amb_anchor + Vector2(26, 2), delta * 60.0)
			if r.ambush_t >= 0.90:
				r.ambush_stage = 4
				r.ambush_t = 0.0
				SoundManager.play_wing_beat()
				r.ui.set_fade(1.0)
		4:
			r.amb_virelai.y -= delta * 250.0
			r.amb_virelai_alt += delta * 140.0
			r.player.position.y -= delta * 250.0
			r.amb_anna.y -= delta * 220.0
			if r.ambush_t >= 1.10:
				finish_abduction(r)


static func finish_abduction(r) -> void:
	r.ambush_cutscene_active = false
	r.ambush_wait_dlg = false
	r.director.camera.zoom = Vector2(1.5, 1.5)
	r.player.set_cutscene_pose("")
	r.ui.set_cinematic_mode(false)
	r.director.load_region("sanctuary", {"skip_intro": false, "arrival_cutscene": true})


static func talk_gatekeeper(r, gate_id: String) -> void:
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	if gate_id == "city":
		var msg := ""
		if not GameState.cargo_delivered:
			msg = "Halt, ship-boy. Steenstraat's under harbor customs lock while vessels unload—square your salt-herring tally with Quartermaster Vos at the warehouse first."
		elif is_dawn:
			msg = "Curfew iron's pinned down across Steenstraat all morning! No dock-boy leaves the wharf quarter while the Church Inquisitor's tribunal stands in Harbor Square."
		elif not GameState.bought_bread:
			msg = "City gates shut to dock-hands at first vespers, lad—orders of the Bailiff. Finish your sister's Ropewalk errands and grab Baker Pieter's loaf before dusk."
		else:
			msg = "Curfew bells are ringing up, boy—no harbor apprentice passes into Upper Bruges tonight. Take that warm rye loaf straight to your uncle's cottage."
		r.ui.show_dialogue([{"speaker": "Gatewarden Maerten", "portrait": "portrait_watchman.png", "text": msg}])
	else:
		var msg_e := (
			"Dike road's sealed by Church curfew! You're not slipping out past the Ropewalk—if you've got sworn word on dragon-traitors, the Church Inquisitor waits down by the square pulpit."
			if is_dawn else
			"Toll bar's down on the Zwin coast dike, young 'un. Bailiff's horsemen sweep those dunes after dusk—keep inside the Harbor Ward with your family."
		)
		r.ui.show_dialogue([{"speaker": "Customsman Dirk", "portrait": "portrait_watchman.png", "text": msg_e}])


static func attempt_gated_exit(r, gate_id: String) -> void:
	var npc_pos := Vector2(720, 92) if gate_id == "city" else Vector2(1526, 98)
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	var spk := "Gatewarden Maerten" if gate_id == "city" else "Customsman Dirk"
	var msg := ""
	if gate_id == "city":
		if not GameState.cargo_delivered:
			msg = "Halt, ship-boy. Finish unloading your herring crate with Quartermaster Vos before passing Steenstraat."
		elif is_dawn:
			msg = "Curfew iron is down across Steenstraat! No dockhand leaves the wharf while the Inquisitor holds Harbor Square."
		elif not GameState.bought_bread:
			msg = "Curfew gates shut soon, lad. Finish your errands with Clara and Baker Pieter first."
		else:
			msg = "Curfew bells are ringing, boy—take that warm rye loaf home to Uncle Willem's cottage."
	else:
		msg = (
			"Dike road is sealed under curfew! Bring your word straight to the Church Inquisitor in Harbor Square."
			if is_dawn else
			"Toll bar is down on the Zwin coast dike, young 'un—stay inside the Harbor Ward with your family."
		)
	r.player.velocity = Vector2.ZERO
	r.trigger_story_roadblock(npc_pos, spk, "portrait_watchman.png", msg, Vector2(0, 42))
