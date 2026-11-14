class_name SanctuaryAct4
extends RefCounted

## Chapter 4 Sanctuary sub-controller owning Phase 4 (Return Egg Debate & Lie to Council)
## and Phase 5 (Midnight Stealth Egg Heist, Cuttable Tripwires, Knot Snares & Kestrel Escape).

const PEDESTAL_POS := Vector2(388, 468)
const WEST_GATE_POS := Vector2(78, 520)


static func init_state(r) -> void:
	r.act4_guards.clear()
	r.act4_guard_lights.clear()
	r.act4_tripwires.assign([
		{"a": Vector2(288, 326), "b": Vector2(358, 326), "cut": false},
		{"a": Vector2(692, 712), "b": Vector2(692, 776), "cut": false},
	])
	r.act4_alert_cooldown = 0.0
	r.act4_intro_active = false
	r.act4_intro_stage = 0
	r.act4_intro_t = 0.0
	r.act4_intro_wait_dlg = false
	r.act4_messenger_present = false
	r.act4_messenger_pos = Vector2(96, 518)
	r.act4_escape_active = false
	r.act4_escape_stage = 0
	r.act4_escape_t = 0.0
	r.act4_escape_wait_dlg = false


static func setup_guards(r) -> void:
	_clear_guard_lights(r)
	r.act4_guards.assign([
		{
			"a": Vector2(215, 290), "b": Vector2(465, 290),
			"pos": Vector2(440, 290), "dir": Vector2.LEFT,
			"t": 0.9, "sign": -1.0, "speed": 0.24, "pause": 0.4,
			"suspicion": 0.0, "stun": 0.0
		},
		{
			"a": Vector2(265, 555), "b": Vector2(535, 555),
			"pos": Vector2(265, 555), "dir": Vector2.RIGHT,
			"t": 0.0, "sign": 1.0, "speed": 0.27, "pause": 0.3,
			"suspicion": 0.0, "stun": 0.0
		},
		{
			"a": Vector2(635, 650), "b": Vector2(635, 815),
			"pos": Vector2(635, 815), "dir": Vector2.UP,
			"t": 1.0, "sign": -1.0, "speed": 0.25, "pause": 0.5,
			"suspicion": 0.0, "stun": 0.0
		},
		{
			"a": Vector2(935, 360), "b": Vector2(1075, 515),
			"pos": Vector2(935, 360), "dir": Vector2.DOWN,
			"t": 0.15, "sign": 1.0, "speed": 0.23, "pause": 0.4,
			"suspicion": 0.0, "stun": 0.0
		},
	])
	for g: Dictionary in r.act4_guards:
		var gl: PointLight2D = r.assets.make_point_light(Vector2(g["pos"]), 2.3, Color(1.0, 0.72, 0.36), 0.0)
		r.add_child(gl)
		r.act4_guard_lights.append(gl)


static func _clear_guard_lights(r) -> void:
	for gl in r.act4_guard_lights:
		if is_instance_valid(gl):
			gl.queue_free()
	r.act4_guard_lights.clear()


static func enter_phase4_debate(r, opts: Dictionary) -> void:
	GameState.current_step = GameState.QuestStep.ACT4_SANCTUARY_DEBATE
	GameState.sanctuary_phase = 4
	GameState.act4_egg_stolen_back = false
	GameState.boy_hp = GameState.boy_max_hp
	if GameState.city_bounty_overheard and not GameState.act4_lied_to_council:
		GameState.carrying_egg = false
		r.act4_messenger_present = true
		r.act4_messenger_pos = Vector2(248, 514)
		r.player.position = opts.get("spawn", Vector2(145, 515))
		r.player.facing = Vector2.RIGHT
		_run_return_lie_dialogue(r)
	elif bool(opts.get("act4_debate_intro", false)) or not GameState.act4_egg_debate_done:
		start_phase4_intro(r)
	else:
		GameState.carrying_egg = false
		r.act4_messenger_present = true
		r.act4_messenger_pos = Vector2(248, 514)


static func enter_phase5_heist(r, opts: Dictionary) -> void:
	GameState.current_step = GameState.QuestStep.ACT4_NIGHT_HEIST
	GameState.sanctuary_phase = 5
	GameState.boy_hp = GameState.boy_max_hp
	GameState.carrying_egg = GameState.act4_egg_stolen_back
	setup_guards(r)
	for tw: Dictionary in r.act4_tripwires:
		tw["cut"] = false
	r.player.position = opts.get("spawn", Vector2(184, 212))
	r.player.facing = Vector2.DOWN
	if bool(opts.get("cutscene_kestrel_escape", false)):
		GameState.act4_egg_stolen_back = true
		GameState.carrying_egg = true
		r.player.position = r.ACT2_CAGE_POS + Vector2(-48, 12)
		start_kestrel_escape(r)
		return
	if not GameState.act4_egg_stolen_back:
		r.spawn_fx_burst(PEDESTAL_POS + Vector2(0, -10), 14, Color(0.98, 0.80, 0.32), 20.0, 56.0, 0.80, 2.8)
		for tw: Dictionary in r.act4_tripwires:
			var mid: Vector2 = (Vector2(tw["a"]) + Vector2(tw["b"])) * 0.5
			r.spawn_fx_burst(mid, 6, Color(0.98, 0.76, 0.34), 12.0, 34.0, 0.65, 2.2)
		SoundManager.play_dragon_purr()


static func start_phase4_intro(r) -> void:
	r.act4_intro_active = true
	r.act4_intro_stage = 0
	r.act4_intro_t = 0.0
	r.act4_intro_wait_dlg = false
	r.act4_messenger_present = false
	r.act4_messenger_pos = Vector2(96, 518)
	r.arrival_hide_ground_duo = true
	r.arrival_virelai_pos = Vector2(580, 130)
	r.arrival_virelai_alt = 175.0
	r.arrival_puffs.clear()

	GameState.carrying_egg = true
	GameState.black_dragon_found = true
	r.player.position = Vector2(342, 504)
	r.player.facing = Vector2.DOWN
	r.player.cutscene_hidden = true
	r.player.can_move = false
	r.director.camera.zoom = Vector2(1.5, 1.5)
	r.director.camera.position = Vector2(440, 290)

	r.ui.set_fade(1.0, true)
	r.ui.set_fade(0.0, false)
	r.ui.set_cinematic_mode(true, func(): skip_phase4_intro(r))
	SoundManager.play_wing_beat()


static func process_phase4_intro(r, delta: float) -> void:
	if not r.act4_intro_active:
		return
	for i in range(r.arrival_puffs.size() - 1, -1, -1):
		var pf: Dictionary = r.arrival_puffs[i]
		pf["t"] = float(pf["t"]) - delta
		pf["pos"] = Vector2(pf["pos"]) + Vector2(pf["vel"]) * delta
		if float(pf["t"]) <= 0.0:
			r.arrival_puffs.remove_at(i)
	if r.act4_intro_wait_dlg:
		return
	r.act4_intro_t += delta
	match r.act4_intro_stage:
		0:
			var p: float = clampf(r.act4_intro_t / 1.45, 0.0, 1.0)
			var ep: float = p * p * (3.0 - 2.0 * p)
			r.arrival_virelai_pos = Vector2(580, 130).lerp(Vector2(368, 384), ep)
			r.arrival_virelai_alt = lerpf(175.0, 0.0, ep)
			r.director.camera.position = Vector2(440, 290).lerp(Vector2(345, 505), ep)
			if r.act4_intro_t >= 0.72 and r.act4_intro_t - delta < 0.72:
				SoundManager.play_wing_beat()
			if p >= 1.0:
				r.arrival_hide_ground_duo = false
				r.player.cutscene_hidden = false
				r.player.position = Vector2(342, 504)
				r.player.facing = Vector2.DOWN
				r.director.trigger_camera_shake(4.0, 0.22)
				SoundManager.play_step(true)
				r.ui.hide_time_stamp()
				for k in range(10):
					var ang: float = TAU * float(k) / 10.0
					r.arrival_puffs.append({
						"pos": Vector2(368, 412) + Vector2(cos(ang) * 26.0, sin(ang) * 14.0),
						"vel": Vector2(cos(ang) * 58.0, sin(ang) * 28.0),
						"t": 0.55,
						"max_t": 0.55,
					})
				r.act4_intro_stage = 1
				r.act4_intro_t = 0.0
				r.act4_intro_wait_dlg = true
				SoundManager.play_dragon_purr()
				r.ui.show_dialogue([
					{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Merciful heavens... look at that shell in your arms. Obsidian black threaded with gold veins—no Bestiary in our chests records a breed like that! Hand it over to me right now, %s." % GameState.player_name},
					{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Hendrick's right. The senior Brotherhood Council elders will want that egg taken into custody tonight—crated under iron lock and hidden beneath Ghent before rumor slips out."},
					{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(true), "text": "Get back—nobody is taking my egg! Its mother tore her wing open shielding it in that burning hollow, and I carried it through freezing sleet to keep it warm! Seal it in a cold Ghent vault and it'll die!"},
					{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "And keep it clinging to a seventeen-year-old's hip?! If word of an unknown black egg reaches Church ears, every bolt-cart in Flanders will climb this ridge before frost! Give the egg up, lad!"},
					{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(true), "text": "I won't hand it over to anyone—it stays with me!"},
					{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Quiet down, both of you! Step back from %s's coat, Hendrick—" % GameState.player_name}
				], func():
					r.act4_intro_wait_dlg = false
					r.act4_intro_stage = 2
					r.act4_intro_t = 0.0
					r.act4_messenger_present = true
					r.act4_messenger_pos = Vector2(96, 518)
					SoundManager.play_alert_horn()
				)
		2:
			var p: float = clampf(r.act4_intro_t / 0.95, 0.0, 1.0)
			var ep: float = p * p * (3.0 - 2.0 * p)
			r.act4_messenger_pos = Vector2(96, 518).lerp(Vector2(248, 514), ep)
			r.director.camera.position = Vector2(345, 505).lerp(Vector2(305, 502), ep)
			r.player.facing = Vector2.LEFT
			if p >= 1.0:
				r.act4_intro_stage = 3
				r.act4_intro_wait_dlg = true
				r.ui.show_dialogue([
					{"speaker": "Outpost Scout", "portrait": "portrait_watchman.png", "text": "Captain Anna! Urgent word off the western canal road—the Church is setting up for a huge action inside the Walled City of Bruges! Armed Catchpoles, Inquisitors, and search teams are pouring through the city gates right now!"},
					{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "A full Church muster inside Bruges's walls?! They're stopping every barge and cart at the gates—what stirred the Bishop's hounds into such a frenzy?"},
					{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Then the Council debate waits until we know what they're searching for! Settle down, Hendrick—nobody takes %s's egg tonight." % GameState.player_name},
					{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Set the black egg on the warm brazier cradle beside Virelai right here—Sister Maren and I will guard its heat personally. %s, you know Bruges's alleys and canal bridges better than any border rider. Take the West Cliff Trail into the Walled City and find out what the Church's big action is all about!" % GameState.player_name},
					{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "Keep the coals glowing beneath it, Anna—don't let Hendrick near that cradle. I'll sneak into the Walled City of Bruges and uncover what they're planning."}
				], func(): finish_phase4_intro(r, false))


static func skip_phase4_intro(r) -> void:
	if r.act4_intro_active:
		finish_phase4_intro(r, true)


static func finish_phase4_intro(r, was_skipped: bool = false) -> void:
	r.act4_intro_active = false
	r.act4_intro_wait_dlg = false
	r.arrival_hide_ground_duo = false
	r.arrival_puffs.clear()
	r.act4_messenger_present = true
	r.act4_messenger_pos = Vector2(248, 514)
	r.player.cutscene_hidden = false
	r.player.position = Vector2(342, 504)
	r.player.facing = Vector2.LEFT
	r.player.can_move = true
	r.director.camera.zoom = Vector2(1.5, 1.5)
	r.director.camera.position = r.player.position
	GameState.act4_egg_debate_done = true
	GameState.carrying_egg = false
	GameState.black_dragon_found = true
	r.ui.hide_time_stamp()
	r.ui.set_fade(0.0, was_skipped)
	r.ui.set_cinematic_mode(false)
	r.ui.refresh_hud()
	r.queue_redraw()


static func _run_return_lie_dialogue(r) -> void:
	r.ui.show_dialogue([
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "You're back past curfew—look half-winded. What were the Catchpoles hauling across Bruges square?"},
		{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "...Nothing out of the ordinary. Only Church tithe iron and noise at the Cloth Hall to frighten the weavers."},
		{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Hmph. All the same, the senior Council arrives at first bell. Keep Night-Watch double-lit around the egg brazier till dawn, boys."}
	], func():
		GameState.act4_lied_to_council = true
		SoundManager.play_dragon_purr()
		r.ui.set_fade(1.0, true)
		r.ui.set_fade(0.0, false)
		enter_phase5_heist(r, {"spawn": Vector2(184, 212)})
	)


static func step_phase5(r, delta: float) -> void:
	if r.act4_escape_active:
		_process_kestrel_escape(r, delta)
		return
	if GameState.sanctuary_phase != 5:
		return

	r.act4_alert_cooldown = maxf(0.0, float(r.act4_alert_cooldown) - delta)

	# Alarm tripwire check
	if not r.ui.is_blocking_gameplay() and r.act4_alert_cooldown <= 0.0:
		for tw: Dictionary in r.act4_tripwires:
			if bool(tw["cut"]):
				continue
			var p: Vector2 = Geometry2D.get_closest_point_to_segment(r.player.position, Vector2(tw["a"]), Vector2(tw["b"]))
			if r.player.position.distance_to(p) <= 13.0 and not r.player.winch_dash_active:
				tw["cut"] = true
				SoundManager.play_alert_horn()
				r.director.trigger_camera_shake(5.5, 0.25)
				for g: Dictionary in r.act4_guards:
					if Vector2(g["pos"]).distance_to(p) <= 380.0 and float(g["stun"]) <= 0.0:
						g["suspicion"] = 0.85
						g["dir"] = (r.player.position - Vector2(g["pos"])).normalized()

	for i in range(r.act4_guards.size()):
		var g: Dictionary = r.act4_guards[i]
		var gl: PointLight2D = r.act4_guard_lights[i] if i < r.act4_guard_lights.size() else null
		if float(g["stun"]) > 0.0:
			g["stun"] = maxf(0.0, float(g["stun"]) - delta)
			if gl != null:
				gl.visible = false
				gl.energy = 0.0
			continue

		if not r.ui.is_blocking_gameplay():
			var a: Vector2 = Vector2(g["a"])
			var b: Vector2 = Vector2(g["b"])
			if float(g["pause"]) > 0.0:
				g["pause"] = maxf(0.0, float(g["pause"]) - delta)
			else:
				var nt: float = float(g["t"]) + delta * float(g["speed"]) * float(g["sign"])
				if nt >= 1.0:
					nt = 1.0
					g["sign"] = -1.0
					g["pause"] = 0.9
				elif nt <= 0.0:
					nt = 0.0
					g["sign"] = 1.0
					g["pause"] = 0.9
				g["t"] = nt
			g["pos"] = a.lerp(b, float(g["t"]))
			g["dir"] = (b - a).normalized() * float(g["sign"])

		var gpos: Vector2 = Vector2(g["pos"])
		var gdir: Vector2 = Vector2(g["dir"]).normalized()
		if gl != null:
			gl.visible = true
			gl.energy = 0.95
			gl.position = gpos + gdir * 26.0

		var seen := false
		if r.act4_alert_cooldown <= 0.0 and not r.ui.is_blocking_gameplay() and not r.player.is_invulnerable() and not r.player.winch_dash_active:
			var g_eye: Vector2 = gpos + Vector2(0, -6)
			var p_eye: Vector2 = r.player.position + Vector2(0, -6)
			if r.can_vision_cone_see(g_eye, gdir, p_eye, 166.0, deg_to_rad(35.0), r.sight_blockers, 26.0):
				var dist: float = g_eye.distance_to(p_eye)
				seen = true
				var rate: float = 4.2 if dist < 56.0 else 2.2
				g["suspicion"] = minf(1.0, float(g["suspicion"]) + delta * rate)
				if float(g["suspicion"]) >= 1.0:
					_trigger_heist_catch(r)
					return
		if not seen:
			g["suspicion"] = maxf(0.0, float(g["suspicion"]) - delta * 1.9)


static func _trigger_heist_catch(r) -> void:
	for g: Dictionary in r.act4_guards:
		g["suspicion"] = 0.0
	r.act4_alert_cooldown = 2.4
	SoundManager.play_alert_horn()
	r.director.trigger_camera_shake(6.5, 0.28)
	r.player.trigger_hurt_flash()
	GameState.boy_hp = maxi(0, GameState.boy_hp - 1)
	r.ui.refresh_hud()
	if GameState.boy_hp <= 0:
		r.ui.show_death_screen("Apprehended by the Brotherhood Night-Watch before reaching Kestrel's harness rack.", func():
			GameState.boy_hp = GameState.boy_max_hp
			GameState.act4_egg_stolen_back = false
			GameState.carrying_egg = false
			r.player.position = Vector2(184, 212)
			r.player.facing = Vector2.DOWN
			r.ui.refresh_hud()
		)
		return
	r.ui.show_mission_failed_screen("Spotted in a Night-Watch sentry's lantern cone! Stay behind cottages and timber stacks. (%d/%d HP left)" % [GameState.boy_hp, GameState.boy_max_hp], func():
		r.player.position = Vector2(238, 535) if GameState.act4_egg_stolen_back else Vector2(184, 212)
		r.player.facing = Vector2.DOWN
		r.ui.refresh_hud()
	)


static func handle_knife_slash(r, tip_pos: Vector2) -> bool:
	if GameState.sanctuary_phase != 5:
		return false
	for tw: Dictionary in r.act4_tripwires:
		if bool(tw["cut"]):
			continue
		var mid: Vector2 = (Vector2(tw["a"]) + Vector2(tw["b"])) * 0.5
		if tip_pos.distance_to(mid) <= 58.0 or r.player.position.distance_to(mid) <= 58.0:
			tw["cut"] = true
			SoundManager.play_cage_break()
			r.queue_redraw()
			return true
	return false


static func handle_rope_cast(r, tip_pos: Vector2) -> bool:
	if GameState.sanctuary_phase != 5:
		return false
	for g: Dictionary in r.act4_guards:
		var gp: Vector2 = Vector2(g["pos"])
		if float(g["stun"]) <= 0.0 and tip_pos.distance_to(gp) <= 95.0:
			g["stun"] = 4.2
			g["suspicion"] = 0.0
			SoundManager.play_knot_cinch()
			r.queue_redraw()
			return true
	return false


static func interact_pedestal(r) -> void:
	if GameState.sanctuary_phase == 4:
		SoundManager.play_dragon_purr()
		SoundManager.play_campfire_warm()
		r.spawn_fx_burst(PEDESTAL_POS + Vector2(0, -10), 14, Color(0.98, 0.78, 0.28), 22.0, 64.0, 0.72, 2.8)
	elif GameState.sanctuary_phase == 5 and not GameState.act4_egg_stolen_back:
		GameState.act4_egg_stolen_back = true
		GameState.carrying_egg = true
		GameState.egg_warmth = 100.0
		r.player.show_held_item(r.assets.get_tex("prop_dragon_egg_held.png"), 1.25)
		SoundManager.play_dragon_purr()
		SoundManager.play_chime()
		r.spawn_fx_burst(PEDESTAL_POS + Vector2(0, -10), 16, Color(0.98, 0.84, 0.34), 28.0, 82.0, 0.75, 3.0)
		r.kestrel_greet_kind = "wing_ramp"
		r.kestrel_greet_timer = 1.60
		r.ui.pulse_hud_icon("bag")
		r.ui.refresh_hud()


static func interact_to_bruges_city(r) -> void:
	if GameState.sanctuary_phase != 4:
		return
	if GameState.city_bounty_overheard:
		r.ui.show_dialogue([{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "No time to wander back into town—come tell me what the Church is doing beside Virelai."}])
		return
	r.director.load_region("outskirts", {"spawn": Vector2(2272, 520), "facing": Vector2.LEFT})


static func interact_kestrel_escape(r) -> bool:
	if GameState.sanctuary_phase != 5:
		return false
	if not GameState.act4_egg_stolen_back:
		r.kestrel_greet_kind = "egg_hint"
		r.kestrel_greet_timer = 1.45
		r.spawn_fx_burst(PEDESTAL_POS + Vector2(0, -10), 10, Color(0.98, 0.82, 0.34), 20.0, 56.0, 0.70, 2.5)
		SoundManager.play_hatch_chirp()
		SoundManager.play_dragon_purr()
		return true
	start_kestrel_escape(r)
	return true


static func start_kestrel_escape(r) -> void:
	GameState.act4_kestrel_escaped = true
	r.act4_escape_active = true
	r.act4_escape_stage = 0
	r.act4_escape_t = 0.0
	r.act4_escape_wait_dlg = false
	_clear_guard_lights(r)
	r.ui.set_cinematic_mode(true)
	r.player.can_move = false
	r.player.facing = Vector2.RIGHT
	r.player.set_cutscene_pose("boy_kneel.png")
	r.kestrel_greet_kind = "wing_ramp"
	r.kestrel_greet_timer = 1.25
	r.spawn_fx_burst(r.ACT2_CAGE_POS + r.greyling_offset, 10, Color(0.84, 0.92, 0.98), 28.0, 68.0, 0.55, 2.5)
	SoundManager.play_hatch_chirp()
	SoundManager.play_dragon_purr()


static func _process_kestrel_escape(r, delta: float) -> void:
	if r.act4_escape_wait_dlg:
		return
	r.act4_escape_t += delta
	if r.act4_escape_stage == 0:
		var p0: float = clampf(r.act4_escape_t / 1.15, 0.0, 1.0)
		r.kestrel_leap_offset = Vector2(-8.0 * sin(p0 * PI), 5.0 * sin(p0 * PI))
		r.player.position = r.player.position.lerp(r.ACT2_CAGE_POS + Vector2(-12, 4), minf(1.0, delta * 5.0))
		if p0 >= 1.0:
			r.kestrel_leap_offset = Vector2.ZERO
			r.kestrel_greet_kind = ""
			r.kestrel_greet_timer = 0.0
			r.player.cutscene_hidden = true
			r.player.set_cutscene_pose("")
			r.montage_hide_ground_kestrel = true
			r.montage_kestrel_fly_active = true
			r.montage_kestrel_fly_pos = r.ACT2_CAGE_POS
			SoundManager.play_wing_beat()
			r.act4_escape_stage = 1
			r.act4_escape_t = 0.0
	elif r.act4_escape_stage == 1:
		var p: float = clampf(r.act4_escape_t / 2.6, 0.0, 1.0)
		var start_p: Vector2 = r.ACT2_CAGE_POS
		var end_p: Vector2 = r.ACT2_CAGE_POS + Vector2(360, -290)
		r.montage_kestrel_fly_pos = start_p.lerp(end_p, p * p)
		r.director.camera.position = r.montage_kestrel_fly_pos
		if int(r.act4_escape_t * 2.5) > int((r.act4_escape_t - delta) * 2.5):
			SoundManager.play_wing_beat()
		if p >= 1.0:
			r.act4_escape_stage = 2
			r.ui.set_cinematic_mode(false)
			r.ui.show_chapter_checkpoint(
				"INTO THE NIGHT SKY — WINGS OF FREEDOM",
				"Escaped the Bruges Sanctuary atop Kestrel with the Black-and-Gold Egg while the Church bounty looms at dawn."
			)


static func draw_act4_overlays(r, t_now: float, cam_rect: Rect2) -> void:
	var ph: int = GameState.sanctuary_phase
	if ph < 4:
		return
	var assets = r.assets
	var font := ThemeDB.fallback_font

	# Phase 4 Virelai return landing FX
	if r.act4_intro_active:
		for pf in r.arrival_puffs:
			var a: float = clampf(float(pf["t"]) / float(pf["max_t"]), 0.0, 1.0)
			r.draw_circle(Vector2(pf["pos"]), 5.0 + (1.0 - a) * 8.0, Color(0.84, 0.88, 0.92, a * 0.48))
		if bool(r.arrival_hide_ground_duo):
			var alt: float = float(r.arrival_virelai_alt)
			var vpos: Vector2 = Vector2(r.arrival_virelai_pos)
			var shadow_sc: float = clampf(1.2 - alt / 260.0, 0.35, 1.0)
			r.draw_circle(vpos + Vector2(0, 28), 58.0 * shadow_sc, Color(0.04, 0.06, 0.08, 0.34 * shadow_sc))
			var wf: int = int(t_now * 8.0) % 2
			var vtex: Texture2D = assets.get_tex("dragon_fly_%d.png" % wf, "dragon_anna_%d.png" % wf)
			if vtex != null:
				var draw_p: Vector2 = vpos - Vector2(0, alt)
				r.draw_texture_rect(vtex, Rect2(draw_p - Vector2(88, 72), Vector2(176, 144)), false)

	# Outpost Scout who brought urgent news from the Walled City of Bruges
	if ph == 4 and r.act4_messenger_present and cam_rect.has_point(r.act4_messenger_pos):
		var mf: int = int(t_now * (5.0 if r.act4_intro_active and r.act4_intro_stage == 2 else 1.8)) % 2
		assets.draw_npc_sprite(r, r.act4_messenger_pos, "npc_brotherhood_guard_%d.png" % mf, "Outpost Scout", font)

	# Egg Brazier Pedestal + glowing Intact Black-and-Gold Egg (once set down after debate)
	if cam_rect.has_point(PEDESTAL_POS):
		var ped_tex: Texture2D = assets.get_tex("prop_egg_cradle_pedestal.png")
		if ped_tex != null:
			r.draw_texture_rect(ped_tex, Rect2(PEDESTAL_POS - Vector2(18, 18), Vector2(36, 36)), false)
		var egg_on_stand: bool = (ph == 4 and not bool(r.act4_intro_active) and not GameState.carrying_egg) or (ph == 5 and not GameState.act4_egg_stolen_back)
		if egg_on_stand:
			var egg_tex: Texture2D = assets.get_tex("prop_dragon_egg.png")
			var aura_a: float = 0.25 + 0.12 * sin(t_now * 4.5)
			r.draw_circle(PEDESTAL_POS + Vector2(0, -10), 16.0, Color(0.98, 0.78, 0.28, aura_a))
			if egg_tex != null:
				r.draw_texture_rect(egg_tex, Rect2(PEDESTAL_POS - Vector2(12, 20), Vector2(24, 24)), false)

	# West Exit Spur & Wooden Signpost during Phase 4
	if ph == 4 and not r.act4_intro_active and not GameState.city_bounty_overheard and cam_rect.has_point(WEST_GATE_POS):
		var g_pulse: float = 0.5 + 0.5 * sin(t_now * 4.0)
		r.draw_arc(WEST_GATE_POS, 20.0 + g_pulse * 4.0, 0.0, TAU, 18, Color(0.96, 0.84, 0.42, 0.80), 2.0)
		var sp := WEST_GATE_POS + Vector2(6, -34)
		var sign_txt := "<- Walled City of Bruges"
		var tsz: Vector2 = font.get_string_size(sign_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var plaque := Rect2(sp.x - (tsz.x + 14.0) * 0.5, sp.y - 11.0, tsz.x + 14.0, 15.0)
		r.draw_rect(Rect2(plaque.position.x + tsz.x * 0.5 + 4.0, plaque.end.y, 4.0, 14.0), Color(0.32, 0.20, 0.12))
		r.draw_rect(plaque, Color(0.20, 0.13, 0.08, 0.95))
		r.draw_rect(plaque, Color(0.66, 0.50, 0.26, 0.90), false, 1.0)
		assets.draw_label_shadowed(r, sp, sign_txt, font, 10, Color(0.95, 0.86, 0.62), true)

	# Phase 5 Midnight Guards & Tripwires
	if ph == 5 and not r.act4_escape_active:
		for tw: Dictionary in r.act4_tripwires:
			if bool(tw["cut"]):
				continue
			var a: Vector2 = Vector2(tw["a"])
			var b: Vector2 = Vector2(tw["b"])
			r.draw_line(a, b, Color(0.98, 0.76, 0.34, 0.75 + 0.2 * sin(t_now * 8.0)), 2.0)
			r.draw_circle(a, 3.0, Color(0.88, 0.68, 0.28))
			r.draw_circle(b, 3.0, Color(0.88, 0.68, 0.28))

		var idle_f: int = int(t_now * 2.0) % 2
		for g: Dictionary in r.act4_guards:
			var gp: Vector2 = Vector2(g["pos"])
			if not cam_rect.has_point(gp):
				continue
			var gdir: Vector2 = Vector2(g["dir"]).normalized()
			var stun_t: float = float(g["stun"])
			if stun_t <= 0.0:
				var susp: float = float(g["suspicion"])
				var cone_col := Color(0.98, 0.32, 0.24, 0.28) if susp > 0.35 else Color(0.98, 0.84, 0.44, 0.16)
				r.draw_raycast_vision_cone(r, gp + Vector2(0, -6), gdir, 166.0, deg_to_rad(35.0), r.sight_blockers, cone_col, cone_col.lightened(0.18))
			var gtex := "npc_brotherhood_guard_%d.png" % idle_f
			assets.draw_npc_sprite(r, gp, gtex, "", ThemeDB.fallback_font, Color.WHITE, gdir.x < -0.1)
			if stun_t > 0.0:
				r.draw_arc(gp + Vector2(0, -28), 8.0, 0.0, TAU * clampf(stun_t / 4.2, 0.0, 1.0), 14, Color(0.96, 0.82, 0.38), 2.2)
			elif float(g["suspicion"]) > 0.05:
				r.draw_arc(gp + Vector2(0, -34), 8.0, -PI * 0.5, -PI * 0.5 + TAU * float(g["suspicion"]), 14, Color(1.0, 0.32, 0.26), 2.5)

		if GameState.act4_egg_stolen_back:
			var kpos: Vector2 = Vector2(r.ACT2_CAGE_POS) + Vector2(r.greyling_offset)
			var rp: float = 0.5 + 0.5 * sin(t_now * 5.0)
			if cam_rect.has_point(kpos):
				r.draw_arc(kpos, 26.0 + rp * 6.0, 0.0, TAU, 22, Color(0.45, 0.96, 0.68, 0.85), 2.4)
			var to_k: Vector2 = kpos - r.player.position
			if to_k.length() > 210.0:
				var kd: Vector2 = to_k.normalized()
				var ktip: Vector2 = r.player.position + kd * 66.0
				var kside := Vector2(-kd.y, kd.x)
				r.draw_line(ktip - kd * 8.0 - kside * 5.0, ktip, Color(0.45, 0.96, 0.68, 0.92), 2.4)
				r.draw_line(ktip - kd * 8.0 + kside * 5.0, ktip, Color(0.45, 0.96, 0.68, 0.92), 2.4)
