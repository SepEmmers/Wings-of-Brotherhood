extends "res://scripts/regions/RegionBase.gd"

## Uncle Willem & Clara's Cottage Interior (Book I — Chapter 1).
## Evening supper conversation, bedtime cliffhanger, and Misty Dawn missing-Clara threshold clue.

var hearth_light: PointLight2D

var sleep_cutscene_active: bool = false
var sleep_stage: int = 0
var sleep_t: float = 0.0
var boy_sleeping_in_bed: bool = false
var door_creak_open: float = 0.0
var willem_pos: Vector2 = Vector2(550, 360)
var clara_visible_in_room: bool = true
var sleep_tint_override: Color = Color(0.76, 0.70, 0.78)
var draft_wisps: Array[Dictionary] = []
var clue_hold_timer: float = 0.0
var dawn_clue_pan_timer: float = 0.0
var clue_pulse_boost: float = 0.0


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	add_box_collider(colliders, Rect2(400, 180, 480, 45))
	add_box_collider(colliders, Rect2(400, 500, 480, 45))
	add_box_collider(colliders, Rect2(400, 220, 45, 280))
	add_box_collider(colliders, Rect2(835, 220, 45, 280))
	add_box_collider(colliders, Rect2(585, 330, 110, 62))
	add_box_collider(colliders, Rect2(745, 240, 78, 52))
	add_box_collider(colliders, Rect2(452, 240, 48, 86))

	hearth_light = assets.make_point_light(Vector2(490, 285), 3.2, Color(1.0, 0.70, 0.35), 1.05)
	add_child(hearth_light)

	interactables = [
		{"id": "uncle_willem", "name": "Uncle Willem", "pos": Vector2(550, 365), "radius": 68.0, "callback": _on_talk_uncle},
		{"id": "sister_home", "name": "Clara", "pos": Vector2(710, 370), "radius": 68.0, "callback": _on_talk_sister_home},
		{"id": "bed", "name": "Your Straw Pallet Bed", "pos": Vector2(775, 308), "radius": 66.0, "callback": _on_interact_bed},
		{"id": "knot_clue", "name": "Torn Dragon-Leather Strap", "pos": Vector2(640, 462), "radius": 62.0, "callback": _on_inspect_knot_clue},
		{"id": "house_exit", "name": "Front Door (To Port)", "pos": Vector2(640, 492), "radius": 52.0, "callback": _on_exit_house_door}
	]
	register_walk_portal("house_exit", Rect2(610, 474, 60, 36), Vector2.DOWN, _on_exit_house_door, "v Port of Bruges Wharf", "PORT OF BRUGES", "Harbor Cottage Step")


func enter_region(opts: Dictionary = {}) -> void:
	if opts.has("step"):
		GameState.current_step = int(opts["step"])
	SoundManager.play_door()
	player.position = opts.get("spawn", Vector2(640, 455))
	player.facing = opts.get("facing", Vector2.UP)
	player.visible = true
	player.set_cutscene_pose("")

	sleep_cutscene_active = false
	boy_sleeping_in_bed = false
	door_creak_open = 0.0
	willem_pos = Vector2(550, 360)
	clara_visible_in_room = GameState.current_step < GameState.QuestStep.DAWN_MISSING_CLARA
	sleep_tint_override = get_lighting_tint()
	draft_wisps.clear()
	clue_hold_timer = 0.0
	dawn_clue_pan_timer = 0.0
	clue_pulse_boost = 0.0

	var cam: Camera2D = director.camera
	cam.limit_left = 340
	cam.limit_top = 140
	cam.limit_right = 940
	cam.limit_bottom = 580
	cam.position = Vector2(640, 360)

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.refresh_hud()

	if bool(opts.get("caught_return", false)):
		ui.set_fade(1.0, true)
		ui.set_fade(0.0, false)
		ui.show_dialogue([
			{"speaker": "Uncle Willem", "portrait": "portrait_uncle.png", "text": "Hold on, officer—he's half out of his wits looking for his sister! I'll keep him by the hearth... Now stay low behind the barrels if you slip back out, lad (%d/%d HP)." % [GameState.boy_hp, GameState.boy_max_hp]}
		])
	elif bool(opts.get("cutscene_sleep", false)):
		_start_sleep_cutscene()
	elif bool(opts.get("first_entry", false)):
		player.show_held_item(assets.get_tex("icon_bread.png"), 1.0)
		ui.show_dialogue([
			{"speaker": "Uncle Willem", "portrait": "portrait_uncle.png", "text": "Evening, %s. Set the loaf by the hearth and scrub the salt off your hands before supper." % GameState.player_name},
			{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "Sit a spell if your legs aren't giving out—pottage is still hot."}
		])


func get_ambience_track() -> String:
	return "dawn_tension" if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA else "hearth"


func get_lighting_tint() -> Color:
	if sleep_cutscene_active:
		return sleep_tint_override
	return Color(0.62, 0.66, 0.78) if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA else Color(0.76, 0.70, 0.78)


func get_surface_at(_pos: Vector2) -> String:
	return "wood"


func update_region_lights(time_val: float) -> void:
	if hearth_light != null:
		var base_energy := 0.24 if (sleep_cutscene_active and sleep_stage in [1, 2]) else 1.0
		hearth_light.energy = base_energy + sin(time_val * 8.5) * 0.10


func step_region(delta: float) -> void:
	clue_pulse_boost = maxf(0.0, clue_pulse_boost - delta)
	if dawn_clue_pan_timer > 0.0:
		var prev_p := dawn_clue_pan_timer
		dawn_clue_pan_timer = maxf(0.0, dawn_clue_pan_timer - delta)
		var pan_arc := sin(clampf(1.0 - dawn_clue_pan_timer / 1.65, 0.0, 1.0) * PI)
		director.camera.position = Vector2(640, 360.0 + pan_arc * 52.0)
		if int(prev_p * 10.0) > int(dawn_clue_pan_timer * 10.0):
			draft_wisps.append({
				"pos": Vector2(640 + randf_range(-14, 14), 488),
				"vel": Vector2(randf_range(-14, 14), randf_range(-92, -62)),
				"t": 0.75,
				"max_t": 0.75,
			})
	else:
		director.camera.position = Vector2(640, 360)
	if clue_hold_timer > 0.0:
		clue_hold_timer = maxf(0.0, clue_hold_timer - delta)
		if clue_hold_timer <= 0.0:
			player.can_move = true
			player.set_cutscene_pose("")
	for i in range(draft_wisps.size() - 1, -1, -1):
		var dw: Dictionary = draft_wisps[i]
		dw["t"] = float(dw["t"]) - delta
		dw["pos"] = Vector2(dw["pos"]) + Vector2(dw["vel"]) * delta
		if float(dw["t"]) <= 0.0:
			draft_wisps.remove_at(i)
	if sleep_cutscene_active:
		_process_sleep_cutscene(delta)
	queue_redraw()


func get_interactable_pos(item: Dictionary) -> Vector2:
	if item["id"] == "uncle_willem":
		return willem_pos
	return item["pos"]


func is_interactable_active(id: String) -> bool:
	if sleep_cutscene_active:
		return false
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	match id:
		"sister_home": return not is_dawn
		"knot_clue": return is_dawn and not GameState.inspected_knot_clue
		_: return true


func _on_talk_uncle() -> void:
	if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA:
		ui.show_dialogue([{"speaker": "Uncle Willem", "portrait": "portrait_uncle.png", "text": "Check by the threshold—something caught on the sill when the door swung open!"}])
		return
	GameState.talked_to_uncle_home = true
	ui.show_dialogue([
		{"speaker": "Uncle Willem", "portrait": "portrait_uncle.png", "text": "Saw the Church herald whipping up a crowd by the square again. Keep clear of his pulpit, %s." % GameState.player_name},
		{"speaker": "Uncle Willem", "portrait": "portrait_uncle.png", "text": "Folks in Louvain swore a wild dragon caught your parents in Old Heverlee woods, yet your father's iron quiver came home sheared by forged steel—no scorch marks anywhere. Let buried ashes rest, %s, and look after your sister." % GameState.player_name}
	])


func _on_talk_sister_home() -> void:
	if GameState.shuttle_pouch_recovered and not GameState.clara_gift_received:
		GameState.clara_gift_received = true
		GameState.remove_item("Clara's Brass Shuttle")
		GameState.add_item("Louvain Beeswax & Thimble")
		player.show_held_item(assets.get_tex("prop_shuttle_pouch.png"), 1.25)
		SoundManager.play_chime()
		ui.refresh_hud()
		ui.pulse_hud_icon("bag")
		ui.show_dialogue([
			{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Here—fished this out of the eddy by the north pilings. Yours?"},
			{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "My oilskin pouch! Look—Mother's Louvain brass thimble was still wrapped inside. Keep it, %s, and rub this beeswax into your hemp lines." % GameState.player_name}
		], func(): GameState.talked_to_sister_home = true)
		return
	GameState.talked_to_sister_home = true
	ui.show_dialogue([
		{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "Heard the shouting in the square from halfway down the lane, didn't you? You always go dead quiet when the Hunters come up."},
		{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "Climb into the straw, %s. Dawn tide doesn't wait for sore shoulders." % GameState.player_name}
	])


func _on_interact_bed() -> void:
	if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA:
		SoundManager.play_knot_snag()
		clue_pulse_boost = 1.4
		dawn_clue_pan_timer = 0.85
		return
	_start_sleep_cutscene()


func _start_sleep_cutscene() -> void:
	sleep_cutscene_active = true
	sleep_stage = 0
	sleep_t = 0.0
	boy_sleeping_in_bed = false
	door_creak_open = 0.0
	willem_pos = Vector2(550, 360)
	clara_visible_in_room = true
	sleep_tint_override = Color(0.76, 0.70, 0.78)
	ui.set_cinematic_mode(true, _skip_sleep_cutscene)
	player.facing = Vector2.RIGHT
	player.set_cutscene_pose("", true)


func _process_sleep_cutscene(delta: float) -> void:
	sleep_t += delta
	match sleep_stage:
		0:
			player.position = player.position.move_toward(Vector2(760, 315), delta * 120.0)
			if player.position.distance_to(Vector2(760, 315)) < 4.0 or sleep_t >= 0.85:
				boy_sleeping_in_bed = true
				player.set_cutscene_pose("", false, false, true)
				sleep_stage = 1
				sleep_t = 0.0
		1:
			sleep_tint_override = Color(0.76, 0.70, 0.78).lerp(Color(0.24, 0.26, 0.40), minf(1.0, sleep_t / 1.15))
			if sleep_t >= 1.35:
				clara_visible_in_room = false
				SoundManager.play_door()
				sleep_stage = 2
				sleep_t = 0.0
		2:
			door_creak_open = sin(clampf(sleep_t / 1.85, 0.0, 1.0) * PI)
			if door_creak_open > 0.25 and int(sleep_t * 14.0) > int((sleep_t - delta) * 14.0):
				draft_wisps.append({
					"pos": Vector2(640 + randf_range(-16, 16), 492),
					"vel": Vector2(randf_range(-18, 18), randf_range(-115, -75)),
					"t": 0.75,
					"max_t": 0.75,
				})
			if sleep_t >= 0.9:
				GameState.current_step = GameState.QuestStep.DAWN_MISSING_CLARA
			if sleep_t >= 1.9:
				door_creak_open = 0.0
				SoundManager.play_door()
				sleep_stage = 3
				sleep_t = 0.0
		3:
			sleep_tint_override = Color(0.24, 0.26, 0.40).lerp(Color(0.62, 0.66, 0.78), minf(1.0, sleep_t / 1.1))
			willem_pos = willem_pos.move_toward(Vector2(716, 322), delta * 155.0)
			if sleep_t >= 1.35:
				_wake_at_misty_dawn()


func _skip_sleep_cutscene() -> void:
	GameState.current_step = GameState.QuestStep.DAWN_MISSING_CLARA
	clara_visible_in_room = false
	door_creak_open = 0.0
	willem_pos = Vector2(716, 322)
	_wake_at_misty_dawn()


func _wake_at_misty_dawn() -> void:
	sleep_cutscene_active = false
	boy_sleeping_in_bed = false
	clara_visible_in_room = false
	door_creak_open = 0.0
	GameState.current_step = GameState.QuestStep.DAWN_MISSING_CLARA
	player.position = Vector2(755, 322)
	player.facing = Vector2.LEFT
	player.set_cutscene_pose("")
	ui.set_cinematic_mode(false)
	SoundManager.play_chime()
	ui.refresh_hud()
	ui.show_dialogue([
		{"speaker": "Uncle Willem", "portrait": "portrait_uncle.png", "text": "%s! Up—get up now! Clara's pallet hasn't been touched, and the front latch is unbarred!" % GameState.player_name}
	], func():
		player.facing = Vector2.DOWN
		dawn_clue_pan_timer = 1.65
		clue_pulse_boost = 1.8
	)


func _on_inspect_knot_clue() -> void:
	GameState.inspected_knot_clue = true
	GameState.add_item("Dragon-Leather Strap (Ropewalk Knot)")
	GameState.current_step = GameState.QuestStep.SNITCH_TO_CHURCH
	SoundManager.play_chime()
	player.facing = Vector2.DOWN
	player.can_move = false
	player.set_cutscene_pose("boy_kneel.png")
	player.show_held_item(assets.get_tex("prop_knot_clue.png"), 1.5)
	clue_hold_timer = 1.35
	ui.refresh_hud()


func _on_exit_house_door() -> void:
	if GameState.current_step == GameState.QuestStep.DAWN_MISSING_CLARA and not GameState.inspected_knot_clue:
		SoundManager.play_knot_snag()
		clue_pulse_boost = 1.8
		for _i in range(6):
			draft_wisps.append({
				"pos": Vector2(640 + randf_range(-16, 16), 488),
				"vel": Vector2(randf_range(-16, 16), randf_range(-95, -62)),
				"t": 0.72,
				"max_t": 0.72,
			})
		return
	if GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH:
		director.load_region("bruges", {"mode": "free", "spawn": Vector2(1310, 902), "facing": Vector2.DOWN, "dawn_exit": true})
		return
	director.load_region("bruges", {"mode": "free", "spawn": Vector2(1310, 902), "facing": Vector2.DOWN})


func get_active_npc_colliders() -> Array:
	if sleep_cutscene_active:
		return []
	var list: Array = [willem_pos]
	if clara_visible_in_room and GameState.current_step < GameState.QuestStep.DAWN_MISSING_CLARA:
		list.append(Vector2(715, 365))
	return list


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	var t_now: float = assets.time_elapsed

	draw_rect(get_camera_rect(80.0), Color(0.05, 0.04, 0.07))
	draw_rect(Rect2(432, 206, 416, 302), Color(0.18, 0.14, 0.12))
	assets.draw_tiled_rect(self, Rect2(440, 220, 400, 280), assets.get_tex("tile_wood_floor.png"), 32.0)
	draw_rect(Rect2(440, 220, 400, 280), Color(0.24, 0.16, 0.10), false, 8.0)

	draw_rect(Rect2(552, 316, 176, 98), Color(0.42, 0.18, 0.18, 0.85))
	draw_rect(Rect2(556, 320, 168, 90), Color(0.76, 0.60, 0.34, 0.65), false, 2.0)

	var hearth_tex: Texture2D = assets.get_tex("prop_hearth.png")
	if hearth_tex != null:
		draw_texture_rect(hearth_tex, Rect2(444, 232, 64, 96), false)
	var dim_mul := 0.35 if (sleep_cutscene_active and sleep_stage in [1, 2]) else 1.0
	var flicker := (10.0 + sin(t_now * 9.0) * 2.5) * dim_mul
	draw_circle(Vector2(476, 308), flicker + 8.0, Color(0.98, 0.56, 0.18, 0.25 * dim_mul))
	if dim_mul > 0.5:
		assets.draw_campfire_sparks(self, Vector2(476, 305), true)

	var tbl_tex: Texture2D = assets.get_tex("prop_table_supper.png")
	if tbl_tex != null:
		draw_texture_rect(tbl_tex, Rect2(584, 329, 112, 64), false)

	var bed_tex: Texture2D = assets.get_tex("prop_bed_sleeping.png" if boy_sleeping_in_bed else "prop_bed.png", "prop_bed.png")
	if bed_tex != null:
		draw_texture_rect(bed_tex, Rect2(744, 238, 80, 56), false)
	if not is_dawn and not boy_sleeping_in_bed:
		var bed_pulse: float = 0.5 + 0.5 * sin(t_now * 3.2)
		var pillow_pos := Vector2(768, 254.0 + sin(t_now * 2.4) * 2.0)
		draw_circle(pillow_pos, 9.0 + bed_pulse * 3.5, Color(0.98, 0.86, 0.48, 0.14 + bed_pulse * 0.12))
		draw_arc(pillow_pos + Vector2(0, -10), 6.0 + bed_pulse * 2.5, PI * 0.15, PI * 0.85, 12, Color(0.98, 0.90, 0.62, 0.48 + bed_pulse * 0.28), 1.5)

	if door_creak_open > 0.05:
		var crack_w := 28.0 * door_creak_open
		draw_colored_polygon(
			PackedVector2Array([Vector2(630, 492), Vector2(650, 492), Vector2(675, 420), Vector2(605, 420)]),
			Color(0.55, 0.68, 0.92, 0.28 * door_creak_open)
		)
		draw_rect(Rect2(616, 486, 48.0 - crack_w, 14), Color(0.55, 0.42, 0.24))
		draw_rect(Rect2(616, 486, 48.0 - crack_w, 14), Color(0.28, 0.20, 0.12), false, 2.0)
	else:
		draw_rect(Rect2(616, 486, 48, 14), Color(0.55, 0.42, 0.24))
		draw_rect(Rect2(616, 486, 48, 14), Color(0.28, 0.20, 0.12), false, 2.0)

	for dw in draft_wisps:
		var a := clampf(float(dw["t"]) / float(dw["max_t"]), 0.0, 1.0)
		draw_circle(dw["pos"], 4.0 * a, Color(0.70, 0.82, 0.98, 0.42 * a))

	assets.draw_npc_sprite(self, willem_pos, "npc_uncle.png", "Uncle Willem", font)
	if clara_visible_in_room and not is_dawn:
		assets.draw_npc_sprite(self, Vector2(715, 365), "npc_clara.png", "Clara", font)
	elif is_dawn and not GameState.inspected_knot_clue:
		var ktex: Texture2D = assets.get_tex("prop_knot_clue.png")
		if ktex != null:
			var flutter := sin(t_now * 14.0) * (3.2 if clue_pulse_boost > 0.0 or dawn_clue_pan_timer > 0.0 else 1.2)
			draw_texture_rect(ktex, Rect2(Vector2(624 + flutter * 0.4, 446 + absf(flutter) * 0.25), Vector2(32, 32)), false)
			var boost_r := 6.0 if clue_pulse_boost > 0.0 else 0.0
			var clue_pulse := 18.0 + boost_r + sin(t_now * 4.5) * 3.0
			draw_arc(Vector2(640, 462), clue_pulse, 0.0, TAU, 16, Color(0.98, 0.80, 0.36, 0.82 if clue_pulse_boost > 0.0 else 0.55), 2.0 if clue_pulse_boost > 0.0 else 1.5)

	if not sleep_cutscene_active:
		draw_interact_bubble_if_active(font)
