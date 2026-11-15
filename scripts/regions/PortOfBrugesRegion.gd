extends "res://scripts/regions/RegionBase.gd"

const PortOfBrugesDrawScript := preload("res://scripts/regions/PortOfBrugesDraw.gd")
const PortOfBrugesAmbushScript := preload("res://scripts/regions/PortOfBrugesAmbush.gd")

## Port of Bruges & Merchant Cog 'De Zwaan' (Book I — Chapter 1).
## Features sailing arrival, Clove Hitch mooring, canal knot-grapple salvage,
## harbor noticeboard & twine supply cache, ambient dockhands, and Misty Dawn Watchman patrols.

const DRIFTED_CRATE_POS := Vector2(175, 650)
const BOBBING_POUCH_POS := Vector2(165, 285)
const HARBOUR_RIGGING_POST := Vector2(360, 480)
const WHARF_BOLLARDS: Array[Vector2] = [Vector2(240, 310), Vector2(240, 620), Vector2(360, 480)]
const TWINE_CACHE_POS := Vector2(1075, 535)
const NOTICEBOARD_POS := Vector2(604, 276)
const AMBUSH_CENTER := Vector2(960, 485)

var ship_pos: Vector2 = Vector2(150, -90)
var ship_target_pos: Vector2 = Vector2(150, 460)
var gangplank_deployed: bool = false
var gangplank_gate: StaticBody2D
var ship_intro_active: bool = false
var ambush_triggered_auto: bool = false

var port_lights: Array[PointLight2D] = []
var watchman_patrols: Array[Dictionary] = []
var watchman_lights: Array[PointLight2D] = []
var sight_blockers: Array[Rect2] = []
var alert_cooldown: float = 0.0
var title_bg_mode: bool = false

var ambush_cutscene_active: bool = false
var ambush_stage: int = 0
var ambush_t: float = 0.0
var ambush_wait_dlg: bool = false
var amb_anchor: Vector2 = AMBUSH_CENTER
var amb_rider_l: Vector2 = AMBUSH_CENTER + Vector2(-90, -20)
var amb_rider_r: Vector2 = AMBUSH_CENTER + Vector2(90, 12)
var amb_anna: Vector2 = AMBUSH_CENTER + Vector2(0, -140)
var amb_virelai: Vector2 = AMBUSH_CENTER + Vector2(180, -320)
var amb_virelai_visible: bool = false
var amb_virelai_alt: float = 120.0
var amb_dust_puffs: Array[Dictionary] = []
var fx_particles: Array[Dictionary] = []
var twine_glint_timer: float = 0.0
var rigging_ripple_timer: float = 0.0
var errand_hint_timer: float = 0.0
var dawn_peek_timer: float = 0.0
var oven_crackle_cooldown: float = 0.0


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	_setup_collisions()

	gangplank_gate = StaticBody2D.new()
	add_child(gangplank_gate)
	add_box_collider(gangplank_gate, Rect2(200, 444, 56, 68))

	_setup_lights()
	PortOfBrugesAmbushScript.setup_watchmen(self)
	PortOfBrugesDrawScript.setup_layers(self)
	_register_interactables()


func _setup_collisions() -> void:
	add_box_collider(colliders, Rect2(204, -140, 50, 588))
	add_box_collider(colliders, Rect2(204, 510, 50, 530))
	add_box_collider(colliders, Rect2(0, 0, 656, 28))
	add_box_collider(colliders, Rect2(784, 0, 700, 28))
	add_box_collider(colliders, Rect2(0, 1012, 1600, 28))
	add_box_collider(colliders, Rect2(1572, 0, 28, 1040))
	add_box_collider(colliders, Rect2(360, 104, 312, 142))
	add_box_collider(colliders, Rect2(948, 92, 524, 124))
	add_box_collider(colliders, Rect2(952, 218, 42, 26))
	add_box_collider(colliders, Rect2(1384, 218, 42, 26))
	add_box_collider(colliders, Rect2(745, 295, 110, 55))
	add_box_collider(colliders, Rect2(722, 524, 146, 88))
	add_box_collider(colliders, Rect2(878, 562, 50, 32))
	add_box_collider(colliders, Rect2(1162, 696, 296, 160))
	add_box_collider(colliders, Rect2(1124, 782, 32, 64))
	add_box_collider(colliders, Rect2(335, 620, 75, 115))
	sight_blockers = [
		Rect2(360, 104, 312, 136), Rect2(948, 92, 524, 120),
		Rect2(952, 218, 42, 22), Rect2(1384, 218, 42, 22),
		Rect2(745, 295, 110, 50), Rect2(722, 524, 146, 84),
		Rect2(878, 562, 50, 28), Rect2(1162, 696, 296, 152),
		Rect2(1124, 782, 32, 60), Rect2(335, 620, 75, 110),
		Rect2(586, 250, 36, 36),
	]


func _setup_lights() -> void:
	for lpos in [
		Vector2(290, 360), Vector2(680, 230), Vector2(930, 235),
		Vector2(705, 580), Vector2(1260, 896), Vector2(1360, 896),
		Vector2(1310, 840)
	]:
		var pl: PointLight2D = assets.make_point_light(lpos, 2.4, Color(1.0, 0.78, 0.42), 0.85)
		add_child(pl)
		port_lights.append(pl)



func enter_region(opts: Dictionary = {}) -> void:
	title_bg_mode = bool(opts.get("title_bg", false))
	ambush_triggered_auto = false
	ambush_cutscene_active = false
	ship_intro_active = false
	amb_virelai_visible = false
	amb_dust_puffs.clear()
	fx_particles.clear()
	twine_glint_timer = 0.0
	rigging_ripple_timer = 0.0
	errand_hint_timer = 0.0
	dawn_peek_timer = 0.95 if bool(opts.get("dawn_exit", false)) else 0.0
	oven_crackle_cooldown = 0.0
	alert_cooldown = 0.0

	var mode: String = opts.get("mode", "free")
	var cam: Camera2D = director.camera

	if title_bg_mode or mode == "sailing":
		ship_pos = Vector2(150, -90)
		GameState.ship_docked = false
		GameState.ship_moored = false
		gangplank_deployed = false
		set_body_collision_enabled(gangplank_gate, true)
		cam.limit_left = 0
		cam.limit_top = -140
		cam.limit_right = 1600
		cam.limit_bottom = 1040
		if title_bg_mode:
			ship_pos = Vector2(210, 145)
			player.visible = false
			player.can_move = false
			player.on_ship = false
			cam.position = Vector2(500, 210)
			step_water_layer()
			return
		GameState.current_step = GameState.QuestStep.ON_THE_SHIP
		player.position = ship_pos + Vector2(0, 26)
		player.facing = Vector2.DOWN
		player.visible = true
		player.can_move = false
		player.on_ship = true
		ship_intro_active = true
		cam.position = ship_pos + Vector2(120, 60)
		step_water_layer()
		ui.set_flight_hud_mode(false)
		ui.set_cinematic_mode(true, _skip_ship_intro)
		ui.show_time_stamp("PORT OF BRUGES", "De Zwaan Coming Alongside", 2.1)
		return

	if mode == "docked":
		ship_pos = ship_target_pos
		GameState.ship_docked = true
		GameState.ship_moored = false
		gangplank_deployed = false
		set_body_collision_enabled(gangplank_gate, true)
		GameState.current_step = GameState.QuestStep.ON_THE_SHIP
		player.position = ship_pos + Vector2(0, 26)
		player.facing = Vector2.DOWN
		player.on_ship = true
	else:
		ship_pos = ship_target_pos
		GameState.ship_docked = true
		GameState.ship_moored = true
		gangplank_deployed = true
		set_body_collision_enabled(gangplank_gate, false)
		player.position = opts.get("spawn", Vector2(300, 480))
		player.facing = opts.get("facing", Vector2.DOWN)
		player.on_ship = false

	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1600
	cam.limit_bottom = 1040
	cam.position = Vector2(960, 620) if dawn_peek_timer > 0.0 else player.position
	step_water_layer()
	player.visible = true
	player.can_move = not ui.is_blocking_gameplay()
	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.refresh_hud()
	if bool(opts.get("cutscene_abduction", false)):
		ambush_triggered_auto = true
		_trigger_brotherhood_ambush()


func exit_region() -> void:
	if (ship_intro_active or ambush_cutscene_active) and ui != null:
		ui.hide_time_stamp()
		ui.set_cinematic_mode(false)
	ship_intro_active = false
	ambush_cutscene_active = false
	player.on_ship = false
	player.set_cutscene_pose("")


func _skip_ship_intro() -> void:
	if not ship_intro_active:
		return
	ship_intro_active = false
	ship_pos = ship_target_pos
	player.position = ship_pos + Vector2(0, 26)
	player.can_move = true
	GameState.ship_docked = true
	director.camera.limit_top = 0
	director.camera.position = player.position
	ui.hide_time_stamp()
	ui.set_cinematic_mode(false)
	SoundManager.play_ship_bell()
	ui.show_dialogue([
		{"speaker": "Shipmaster Hendrik", "portrait": "portrait_shipmaster.png", "text": "Way enough! Tie the bow line at the forward cleat so I can drop the plank, then heave that salt-herring crate up to Vos."}
	])


func get_ambience_track() -> String:
	return "dawn_tension" if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA else "harbor"


func get_lighting_tint() -> Color:
	return Color(0.66, 0.75, 0.86) if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA else Color(0.84, 0.76, 0.88)


func get_surface_at(pos: Vector2) -> String:
	if pos.x < 258.0:
		return "wood"
	if (pos.x >= 928.0 and pos.y <= 352.0) or (pos.x >= 1088.0 and pos.y >= 608.0):
		return "grass"
	return "cobble"


func update_region_lights(time_val: float) -> void:
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	sync_light_frustum(port_lights, true, 24.0)
	for pl in port_lights:
		if pl.visible:
			pl.energy = (0.45 if is_dawn else 0.85) + sin(time_val * 4.2 + pl.position.x) * 0.06
	sync_light_frustum(watchman_lights, GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH, 24.0)


func _redraw_world() -> void:
	step_water_layer()
	queue_redraw()


func spawn_fx_burst(origin: Vector2, count: int, col: Color, min_spd: float = 34.0, max_spd: float = 95.0, life: float = 0.55, sz: float = 3.0) -> void:
	for _i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(min_spd, max_spd)
		fx_particles.append({
			"pos": origin,
			"vel": Vector2(cos(ang), sin(ang) - 0.2) * spd,
			"t": life,
			"max_t": life,
			"col": col,
			"sz": sz,
		})


func step_region(delta: float) -> void:
	if title_bg_mode:
		_redraw_world()
		return

	twine_glint_timer = maxf(0.0, twine_glint_timer - delta)
	rigging_ripple_timer = maxf(0.0, rigging_ripple_timer - delta)
	errand_hint_timer = maxf(0.0, errand_hint_timer - delta)
	oven_crackle_cooldown = maxf(0.0, oven_crackle_cooldown - delta)
	if oven_crackle_cooldown <= 0.0 and player != null and player.position.distance_to(Vector2(904, 573)) <= 135.0 and not ui.is_blocking_gameplay():
		SoundManager.play_oven_crackle()
		oven_crackle_cooldown = randf_range(2.6, 4.0)
	for i in range(fx_particles.size() - 1, -1, -1):
		var fp: Dictionary = fx_particles[i]
		fp["t"] = float(fp["t"]) - delta
		fp["pos"] = Vector2(fp["pos"]) + Vector2(fp["vel"]) * delta
		fp["vel"] = Vector2(fp["vel"]) * 0.91
		if float(fp["t"]) <= 0.0:
			fx_particles.remove_at(i)

	if ambush_cutscene_active:
		for i in range(amb_dust_puffs.size() - 1, -1, -1):
			var dp: Dictionary = amb_dust_puffs[i]
			dp["t"] = float(dp["t"]) - delta
			dp["pos"] = Vector2(dp["pos"]) + Vector2(dp["vel"]) * delta
			if float(dp["t"]) <= 0.0:
				amb_dust_puffs.remove_at(i)
		if not ambush_wait_dlg:
			PortOfBrugesAmbushScript.process_abduction(self, delta)
		director.camera.position = amb_anchor
		_redraw_world()
		return

	_process_ship_arrival(delta)
	_constrain_on_ship_if_needed()
	PortOfBrugesAmbushScript.update_watchmen(self, delta)
	if ship_intro_active:
		var prog := clampf((ship_pos.y + 90.0) / 550.0, 0.0, 1.0)
		director.camera.position = (ship_pos + Vector2(130, 60)).lerp(player.position, prog)
	elif dawn_peek_timer > 0.0:
		dawn_peek_timer = maxf(0.0, dawn_peek_timer - delta)
		var dp_t := 1.0 - clampf(dawn_peek_timer / 0.95, 0.0, 1.0)
		var smooth_p := dp_t * dp_t * (3.0 - 2.0 * dp_t)
		director.camera.position = Vector2(960, 620).lerp(player.position, smooth_p)
	else:
		director.camera.position = player.position

	if (
		GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH
		and not ambush_triggered_auto
		and not ui.is_blocking_gameplay()
		and player.position.distance_to(AMBUSH_CENTER) < 130.0
	):
		ambush_triggered_auto = true
		_trigger_brotherhood_ambush()

	_redraw_world()


func _process_ship_arrival(delta: float) -> void:
	if GameState.ship_docked:
		return
	var prev_y := ship_pos.y
	var spd := 205.0 if ship_intro_active else 92.0
	ship_pos = ship_pos.move_toward(ship_target_pos, delta * spd)
	var dy := ship_pos.y - prev_y
	if player.position.x < 224.0:
		player.position.y += dy
	if ship_pos.distance_to(ship_target_pos) < 1.5:
		ship_pos = ship_target_pos
		GameState.ship_docked = true
		SoundManager.play_ship_bell()
		director.camera.limit_top = 0
		if ship_intro_active:
			ship_intro_active = false
			player.can_move = true
			ui.hide_time_stamp()
			ui.set_cinematic_mode(false)
		ui.show_dialogue([
			{"speaker": "Shipmaster Hendrik", "portrait": "portrait_shipmaster.png", "text": "Way enough! Tie the bow line at the forward cleat so I can drop the plank, then heave that salt-herring crate up to Vos."}
		])


func _constrain_on_ship_if_needed() -> void:
	if player.position.x < 214.0:
		player.on_ship = true
		var in_gangplank_y := player.position.y >= 452.0 and player.position.y <= 504.0 and gangplank_deployed
		if not in_gangplank_y:
			player.position.x = clampf(player.position.x, ship_pos.x - 42.0, ship_pos.x + 42.0)
		player.position.y = clampf(player.position.y, ship_pos.y - 68.0, ship_pos.y + 72.0)
	else:
		player.on_ship = false
		if GameState.current_step == GameState.QuestStep.ON_THE_SHIP and player.position.x >= 245.0:
			GameState.current_step = GameState.QuestStep.EXPLORE_BRUGES
			GameState.emit_signal("state_updated")




func on_knife_slash(tip_pos: Vector2, _dir: Vector2) -> void:
	if not GameState.bruges_twine_cache_cut and tip_pos.distance_to(TWINE_CACHE_POS) <= 68.0:
		_open_twine_cache(true)
		return

	if GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH:
		for wp in watchman_patrols:
			if tip_pos.distance_to(wp["pos"]) <= 58.0:
				wp["pause"] = 1.4
				wp["suspicion"] = 0.0
				SoundManager.play_hit()


func on_rope_cast_hit(tip_pos: Vector2, knot_id: String) -> void:
	if not GameState.drifted_crate_recovered and tip_pos.distance_to(DRIFTED_CRATE_POS) <= 95.0:
		if knot_id in ["bruges_whipping", "dragon_splice"]:
			GameState.drifted_crate_recovered = true
			player.pulled_crate_active = true
			SoundManager.play_splash()
			GameState.add_item("Salvaged Hemp Bundle")
			player.show_held_item(assets.get_tex("icon_crate.png"), 0.85)
			spawn_fx_burst(DRIFTED_CRATE_POS, 12, Color(0.46, 0.84, 0.98), 42.0, 96.0, 0.55, 2.8)
			spawn_fx_burst(DRIFTED_CRATE_POS + Vector2(0, -6), 6, Color(0.96, 0.84, 0.44), 26.0, 62.0, 0.48, 2.4)
			ui.refresh_hud()
		else:
			SoundManager.play_knot_snag()
			spawn_fx_burst(DRIFTED_CRATE_POS, 9, Color(0.96, 0.68, 0.28), 38.0, 92.0, 0.44, 2.5)
			spawn_fx_burst(DRIFTED_CRATE_POS, 6, Color(0.68, 0.90, 0.98), 26.0, 64.0, 0.42, 2.4)
		return

	if not GameState.shuttle_pouch_recovered and tip_pos.distance_to(BOBBING_POUCH_POS) <= 135.0:
		if knot_id == "bowline":
			GameState.shuttle_pouch_recovered = true
			SoundManager.play_splash()
			GameState.add_item("Clara's Brass Shuttle")
			player.show_held_item(assets.get_tex("prop_shuttle_pouch.png"), 1.0)
			spawn_fx_burst(BOBBING_POUCH_POS, 12, Color(0.48, 0.86, 0.98), 40.0, 92.0, 0.55, 2.8)
			ui.refresh_hud()
		else:
			SoundManager.play_knot_snag()
			rigging_ripple_timer = 0.85
			spawn_fx_burst(BOBBING_POUCH_POS, 10, Color(0.62, 0.88, 0.98), 46.0, 108.0, 0.48, 2.5)
		return

	if knot_id == "dragon_splice":
		for bpos in WHARF_BOLLARDS:
			if tip_pos.distance_to(bpos) <= 95.0:
				player.start_winch_dash(bpos + Vector2(24, 0))
				SoundManager.play_knot_cinch()
				return


func _register_interactables() -> void:
	interactables = [
		{"id": "ship_bollard", "name": "Bow Mooring Cleat (Tie Clove Hitch)", "pos": Vector2.ZERO, "radius": 52.0, "callback": _on_interact_ship_bollard},
		{"id": "ship_crate", "name": "Salt-Herring Cargo Crate", "pos": Vector2.ZERO, "radius": 54.0, "callback": _on_pickup_ship_crate},
		{"id": "shipmaster", "name": "Shipmaster Hendrik", "pos": Vector2.ZERO, "radius": 56.0, "callback": _on_talk_shipmaster},
		{"id": "quartermaster", "name": "Quartermaster Vos (Warehouse)", "pos": Vector2(512, 262), "radius": 74.0, "callback": _on_interact_warehouse},
		{"id": "noticeboard", "name": "Harbor Noticeboard", "pos": NOTICEBOARD_POS, "radius": 62.0, "callback": _on_read_noticeboard},
		{"id": "dockhand_jan", "name": "Dockhand Jan", "pos": Vector2(308, 608), "radius": 60.0, "callback": _on_talk_dockhand_jan},
		{"id": "dockhand_piet", "name": "Old Wharf Loafer Piet", "pos": Vector2(575, 595), "radius": 60.0, "callback": _on_talk_dockhand_piet},
		{"id": "twine_cache", "name": "Twine-Bound Cache ([V] Cut)", "pos": TWINE_CACHE_POS, "radius": 58.0, "callback": func(): _open_twine_cache(false)},
		{"id": "sister_ropewalk", "name": "Clara (Bruges Ropewalk)", "pos": Vector2(1185, 240), "radius": 74.0, "callback": _on_interact_sister_ropewalk},
		{"id": "rigging_post", "name": "Harbour Rigging Post (Learn Bowline)", "pos": HARBOUR_RIGGING_POST, "radius": 62.0, "callback": _on_interact_rigging_post},
		{"id": "church_herald", "name": "Church Inquisitor", "pos": Vector2(800, 385), "radius": 74.0, "callback": _on_interact_herald},
		{"id": "baker", "name": "Baker Pieter", "pos": Vector2(795, 635), "radius": 68.0, "callback": _on_interact_baker},
		{"id": "north_gate_sign", "name": "Read Gatehouse Sign", "pos": Vector2(648, 76), "radius": 58.0, "callback": _on_read_north_gate_sign},
		{"id": "ne_outskirts_sign", "name": "Read Towpath Signpost", "pos": Vector2(1463, 258), "radius": 58.0, "callback": _on_read_ne_outskirts_sign},
		{"id": "ch1_gate_city", "name": "Gatewarden Maerten", "pos": Vector2(692, 62), "radius": 60.0, "callback": func(): PortOfBrugesAmbushScript.talk_gatekeeper(self, "city")},
		{"id": "ch1_gate_outskirts", "name": "Customsman Dirk", "pos": Vector2(1504, 62), "radius": 60.0, "callback": func(): PortOfBrugesAmbushScript.talk_gatekeeper(self, "outskirts")},
		{"id": "brotherhood_ambush", "name": "Hooded Riders", "pos": AMBUSH_CENTER, "radius": 85.0, "callback": _trigger_brotherhood_ambush}
	]
	clear_walk_portals()
	register_walk_portal("house_door", Rect2(1280, 846, 60, 40), Vector2.UP, _on_enter_house_door, "^ Uncle Willem's Cottage", "WILLEM'S COTTAGE", "Portside Hearth")
	register_walk_portal("north_city_gate", Rect2(676, 0, 88, 38), Vector2.UP, _on_enter_north_city_gate, "^ Walled City of Bruges", "WALLED CITY OF BRUGES", "South Gate — Steenstraat")
	register_walk_portal("ne_outskirts_gate", Rect2(1484, 0, 88, 38), Vector2.UP, _on_enter_ne_outskirts_gate, "^ Coastal Outskirts", "BRUGES OUTSKIRTS", "Southern Port Towpath")


func get_interactable_pos(item: Dictionary) -> Vector2:
	match String(item.get("id", "")):
		"ship_bollard": return ship_pos + Vector2(30, -52)
		"ship_crate": return ship_pos + Vector2(-20, 44)
		"shipmaster": return ship_pos + Vector2(4, -22)
		"quartermaster": return get_npc_yield_pos("pob_vos", Vector2(512, 262), 34.0, 12.0)
		"sister_ropewalk": return get_npc_yield_pos("pob_clara", Vector2(1185, 240), 34.0, 12.0)
		"dockhand_jan": return get_npc_yield_pos("pob_jan", Vector2(308, 608), 34.0, 12.0)
		"dockhand_piet": return get_npc_yield_pos("pob_piet", Vector2(575, 595), 34.0, 12.0)
		"church_herald": return get_npc_yield_pos("pob_inquisitor", Vector2(800, 385), 34.0, 12.0)
		"baker": return get_npc_yield_pos("pob_baker", Vector2(795, 635), 34.0, 12.0)
		_: return Vector2(item.get("pos", Vector2.ZERO))


func is_interactable_active(id: String) -> bool:
	var is_dawn := GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA
	match id:
		"ship_bollard": return not GameState.ship_moored
		"ship_crate": return not GameState.carrying_crate and not GameState.cargo_delivered
		"rigging_post": return not GameState.unlocked_knots.has("bowline") and not is_dawn
		"sister_ropewalk", "dockhand_jan", "dockhand_piet", "noticeboard": return not is_dawn
		"twine_cache": return not GameState.bruges_twine_cache_cut
		"brotherhood_ambush": return GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH
		"ch1_gate_city", "ch1_gate_outskirts": return GameState.current_step < GameState.QuestStep.ACT2_SANCTUARY
		_: return true


func is_portal_unlocked(id: String) -> bool:
	if id in ["north_city_gate", "ne_outskirts_gate"]:
		return GameState.current_step >= GameState.QuestStep.ACT2_SANCTUARY
	return true


func _on_interact_ship_bollard() -> void:
	if not GameState.ship_docked:
		SoundManager.play_knot_snag()
		spawn_fx_burst(ship_pos + Vector2(30, -52), 7, Color(0.84, 0.72, 0.42), 28.0, 68.0, 0.42, 2.4)
		return
	if GameState.ship_moored:
		return
	ui.open_knot_minigame("clove_hitch", func(_id):
		GameState.ship_moored = true
		gangplank_deployed = true
		set_body_collision_enabled(gangplank_gate, false)
		ui.show_dialogue([
			{"speaker": "Shipmaster Hendrik", "portrait": "portrait_shipmaster.png", "text": "Clean Clove Hitch, lad. Plank's down. Grab that salt-herring crate off the deck before you run off to your sister."}
		])
	)


func _on_pickup_ship_crate() -> void:
	if GameState.carrying_crate or GameState.cargo_delivered:
		return
	GameState.carrying_crate = true
	player.show_held_item(assets.get_tex("icon_crate.png"), 0.85)
	ui.refresh_hud()
	SoundManager.play_crate_pickup()


func _on_talk_shipmaster() -> void:
	if not GameState.ship_docked:
		ui.show_dialogue([{"speaker": "Shipmaster Hendrik", "portrait": "portrait_shipmaster.png", "text": "Almost at the quay, %s. Stand ready by the bow cleat." % GameState.player_name}])
	elif not GameState.ship_moored:
		ui.show_dialogue([{"speaker": "Shipmaster Hendrik", "portrait": "portrait_shipmaster.png", "text": "Tie the bow line to that forward cleat with a Clove Hitch so the crew can lower the gangplank."}])
	elif GameState.carrying_crate:
		ui.show_dialogue([{"speaker": "Shipmaster Hendrik", "portrait": "portrait_shipmaster.png", "text": "Quartermaster Vos is waiting by the Warehouse north of the wharf. Tell Clara I said good evening."}])
	else:
		ui.show_dialogue([{"speaker": "Shipmaster Hendrik", "portrait": "portrait_shipmaster.png", "text": "Good work today, %s. Keep that rigging knife dry—same tide tomorrow at dawn." % GameState.player_name}])


func _on_interact_warehouse() -> void:
	if GameState.carrying_crate:
		GameState.carrying_crate = false
		GameState.cargo_delivered = true
		SoundManager.play_chime()
		ui.refresh_hud()
		var lines: Array[Dictionary] = [
			{"speaker": "Quartermaster Vos", "portrait": "portrait_quartermaster.png", "text": "Ah, %s—set the herring crate inside the bay. Here's three copper groats for your hauling." % GameState.player_name}
		]
		if GameState.drifted_crate_recovered and not GameState.has_mariner_compass:
			GameState.has_mariner_compass = true
			GameState.remove_item("Salvaged Hemp Bundle")
			GameState.add_item("Mariner's Brass Compass")
			player.show_held_item(assets.get_tex("icon_compass.png"), 1.35)
			lines.append({"speaker": "Quartermaster Vos", "portrait": "portrait_quartermaster.png", "text": "Wait—dry hemp wrapped inside that tide-drift crate? Good weight to it. Trade you an old pocket compass I've no use for; needle still holds true north."})
		else:
			lines.append({"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Obliged, Master Vos."})
		ui.show_dialogue(lines)
	elif GameState.drifted_crate_recovered and not GameState.has_mariner_compass:
		GameState.has_mariner_compass = true
		GameState.remove_item("Salvaged Hemp Bundle")
		GameState.add_item("Mariner's Brass Compass")
		player.show_held_item(assets.get_tex("icon_compass.png"), 1.35)
		SoundManager.play_chime()
		ui.refresh_hud()
		ui.show_dialogue([
			{"speaker": "Quartermaster Vos", "portrait": "portrait_quartermaster.png", "text": "Dry hemp salvaged from the Zwin? Good haul, %s—take this spare pocket compass in exchange. Needle still holds true north." % GameState.player_name}
		])
	elif GameState.cargo_delivered:
		ui.show_dialogue([{"speaker": "Quartermaster Vos", "portrait": "portrait_quartermaster.png", "text": "Warehouse is tallied for the night. Safe walk home to Willem's, boy."}])
	else:
		ui.show_dialogue([{"speaker": "Quartermaster Vos", "portrait": "portrait_quartermaster.png", "text": "Still waiting on that last salt-herring crate from De Zwaan's deck, lad."}])


func _on_read_noticeboard() -> void:
	GameState.bruges_noticeboard_read = true
	SoundManager.play_journal()
	ui.show_dialogue([
		{"speaker": "Harbor Decree", "portrait": "portrait_watchman.png", "text": "'BY ORDER OF THE HOLY INQUISITION: Five silver groats for a slain wyrm-hide; TWENTY gold florins for any dragon delivered ALIVE in iron chains! Severe penalties for Ropewalk spinners supplying greased hemp to outlawed riders.'"},
		{"speaker": "Faded Brabant Notice", "portrait": "portrait_watchman.png", "text": "'Missing near Old Heverlee, four winters past — two Hunter Guilders of Louvain.'"}
	])


func _on_talk_dockhand_jan() -> void:
	GameState.bruges_roll_practiced = true
	ui.show_dialogue([
		{"speaker": "Dockhand Jan", "portrait": "portrait_quartermaster.png", "text": "Watch your boot-strings along the canal edge, %s! Current sucked a whole coil of Clara's brass shuttles off the north piling earlier today." % GameState.player_name},
		{"speaker": "Dockhand Jan", "portrait": "portrait_quartermaster.png", "text": "And keep limber near the cranes—tuck your shoulder into a quick roll under any swinging yardarm before it knocks you in the Zwin. Quick tumbling gets you clear of harbor patrols too!"}
	])


func _on_talk_dockhand_piet() -> void:
	ui.show_dialogue([
		{"speaker": "Dockhand Piet", "portrait": "portrait_uncle.png", "text": "Seen iron-helmeted Church Watchmen unloading fresh ballista bolts down on the east pier, lad. Something's flying inland past the dunes at night."}
	])


func _open_twine_cache(cut_with_blade: bool) -> void:
	if GameState.bruges_twine_cache_cut:
		return
	if not cut_with_blade:
		twine_glint_timer = 1.25
		SoundManager.play_knot_snag()
		spawn_fx_burst(TWINE_CACHE_POS, 7, Color(0.84, 0.70, 0.36), 28.0, 68.0, 0.42, 2.4)
		return
	GameState.bruges_twine_cache_cut = true
	GameState.boy_hp = GameState.boy_max_hp
	GameState.add_item("Sea-Biscuit & Hemp Twine")
	player.show_held_item(assets.get_tex("prop_twine_cache.png"), 1.2)
	SoundManager.play_slash()
	SoundManager.play_chime()
	spawn_fx_burst(TWINE_CACHE_POS, 12, Color(0.92, 0.78, 0.42), 45.0, 115.0, 0.52, 2.6)
	ui.refresh_hud()


func _give_clara_pouch_reward(on_done: Callable = Callable()) -> void:
	GameState.clara_gift_received = true
	GameState.remove_item("Clara's Brass Shuttle")
	GameState.add_item("Louvain Beeswax & Thimble")
	player.show_held_item(assets.get_tex("prop_shuttle_pouch.png"), 1.25)
	SoundManager.play_chime()
	ui.refresh_hud()
	ui.pulse_hud_icon("bag")
	ui.show_dialogue([
		{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Here—fished this out of the eddy by the north pilings. Yours?"},
		{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "My oilskin pouch! Thought the Zwin tide took it clear past the sea-gate. Look—Mother's Louvain brass thimble was still wrapped inside."},
		{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "Keep it, %s. You pulled it back. Take this cake of our beeswax too—rub it into your hemp so the salt doesn't rot it." % GameState.player_name}
	], on_done)


func _on_interact_sister_ropewalk() -> void:
	if not GameState.visited_clara:
		GameState.visited_clara = true
		ui.show_dialogue([
			{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "There you are, %s. Smell like low tide again." % GameState.player_name},
			{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "Church-hired wagon-wrights came sniffing round the Ropewalk at noon asking who braids our gale-tension hemp, so I kept my head down and rigged a three-prong brass hook for you instead. Show me your Bruges Whipping-Knot."}
		], func():
			ui.open_knot_minigame("bruges_whipping", func(_id):
				GameState.add_item("Brass Hook & Whipping Line")
				ui.show_dialogue([
					{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "Not bad, little brother—weighted like that, you could haul drifted timber straight out of the canal. Oh, Uncle Willem's out of bread. Stop by Pieter's stall in the square on your way home, yeah?"}
				], func():
					if GameState.shuttle_pouch_recovered and not GameState.clara_gift_received:
						_give_clara_pouch_reward()
				)
			)
		)
	elif GameState.shuttle_pouch_recovered and not GameState.clara_gift_received:
		_give_clara_pouch_reward()
	else:
		ui.show_dialogue([
			{"speaker": "Clara", "portrait": "portrait_clara.png", "text": "Grab that rye loaf before Pieter shuts his stall. I'll meet you back at Uncle Willem's once I bank the hemp fires."}
		])


func _on_interact_rigging_post() -> void:
	ui.open_knot_minigame("bowline", func(_id):
		rigging_ripple_timer = 1.4
		SoundManager.play_chime()
		spawn_fx_burst(HARBOUR_RIGGING_POST, 10, Color(0.56, 0.90, 0.98), 40.0, 96.0, 0.55, 2.8)
	)


func _on_interact_herald() -> void:
	if GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH:
		_trigger_brotherhood_ambush()
		return
	GameState.heard_herald = true
	ui.show_dialogue([
		{"speaker": "Church Inquisitor", "portrait": "portrait_inquisitor.png", "text": "Hear the decree of the Holy See! Every wyrm is a plague upon field and flock! Honor the Dragon Hunters who bleed to keep Flanders clear!"},
		{"speaker": "Church Inquisitor", "portrait": "portrait_inquisitor.png", "text": "And keep watch over your neighbors—rumors speak of traitors in the borderlands, riders in leather harness who shelter the beasts in secret! Any soul who turns them in earns the magistrate's silver!"}
	], func():
		SoundManager.play_hit()
		spawn_fx_burst(player.position + Vector2(0, -14), 8, Color(0.96, 0.36, 0.24), 24.0, 58.0, 0.42, 2.4)
	)


func _on_interact_baker() -> void:
	if GameState.bought_bread:
		ui.show_dialogue([{"speaker": "Baker Pieter", "portrait": "portrait_baker.png", "text": "Run along home, %s—don't let that rye loaf go cold!" % GameState.player_name}])
		return
	GameState.bought_bread = true
	GameState.add_item("Evening Rye Bread")
	player.show_held_item(assets.get_tex("icon_bread.png"), 1.1)
	SoundManager.play_chime()
	var lines: Array[Dictionary] = [
		{"speaker": "Baker Pieter", "portrait": "portrait_baker.png", "text": "One crusty rye loaf for Willem's table—that'll be one copper, lad."},
		{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Thanks, Master Pieter."}
	]
	if not GameState.heard_herald:
		lines.append({"speaker": "Church Inquisitor", "portrait": "portrait_inquisitor.png", "text": "Hear the decree! Honor the Dragon Hunters—and report any secret riders in leather harness to the magistrate!"})
		lines.append({"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Good. Hang the riders with them."})
	ui.show_dialogue(lines)


func _on_enter_house_door() -> void:
	if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA:
		director.load_region("house", {"spawn": Vector2(640, 455), "step": GameState.current_step})
		return
	if not GameState.all_evening_errands_done():
		SoundManager.play_door()
		portal_cooldown = 1.0
		player.position.y = maxf(player.position.y, 892.0)
		if GameState.hints_enabled:
			errand_hint_timer = 2.6
			ui.pulse_hud_icon("bag")
		spawn_fx_burst(Vector2(1310, 868), 6, Color(0.92, 0.80, 0.44), 22.0, 52.0, 0.40, 2.2)
		return
	GameState.remove_item("Evening Rye Bread")
	director.load_region("house", {"spawn": Vector2(640, 455), "step": GameState.QuestStep.EVENING_HOME, "first_entry": true})


func _on_read_north_gate_sign() -> void:
	ui.show_dialogue([{"speaker": "Harbor Gatehouse Post", "text": "NORTH: Steenstraat & Walled City of Bruges  |  EAST PAST ROPEWALK: Coastal Outskirts Towpath", "portrait": ""}])


func _on_enter_north_city_gate() -> void:
	if not is_portal_unlocked("north_city_gate"):
		PortOfBrugesAmbushScript.attempt_gated_exit(self, "city")
		return
	SoundManager.play_door()
	director.load_region("bruges_city", {"spawn": Vector2(1440, 1960), "facing": Vector2.UP, "skip_intro": true})


func _on_read_ne_outskirts_sign() -> void:
	ui.show_dialogue([{"speaker": "Towpath Milestone", "text": "NORTH: Coastal Outskirts, Zwin Bridge & Sanctuary Dunes  |  WEST: Harbour Quay & City Gate", "portrait": ""}])


func _on_enter_ne_outskirts_gate() -> void:
	if not is_portal_unlocked("ne_outskirts_gate"):
		PortOfBrugesAmbushScript.attempt_gated_exit(self, "outskirts")
		return
	SoundManager.play_door()
	director.load_region("outskirts", {"spawn": Vector2(380, 1018), "facing": Vector2.UP})


func _trigger_brotherhood_ambush() -> void:
	PortOfBrugesAmbushScript.trigger_ambush(self)


func _skip_abduction_cutscene() -> void:
	ui.set_fade(1.0, true)
	PortOfBrugesAmbushScript.finish_abduction(self)


func get_active_npc_colliders() -> Array:
	if title_bg_mode or ambush_cutscene_active:
		return []
	var list: Array = [
		ship_pos + Vector2(4, -22),
		{"pos": Vector2(512, 262), "yield_key": "pob_vos"},
		{"pos": Vector2(800, 372), "yield_key": "pob_inquisitor"},
		{"pos": Vector2(795, 628), "yield_key": "pob_baker"},
	]
	if GameState.current_step < GameState.QuestStep.DAWN_MISSING_CLARA:
		list.append({"pos": Vector2(1185, 240), "yield_key": "pob_clara"})
		list.append({"pos": Vector2(308, 608), "yield_key": "pob_jan"})
		list.append({"pos": Vector2(575, 595), "yield_key": "pob_piet"})
	if GameState.current_step < GameState.QuestStep.ACT2_SANCTUARY:
		list.append({"pos": Vector2(692, 62), "radius": 13.0})
		list.append({"pos": Vector2(1504, 62), "radius": 13.0})
	if GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH:
		for wp: Dictionary in watchman_patrols:
			list.append(Vector2(wp["pos"]))
		list.append(AMBUSH_CENTER + Vector2(-42, -20))
		list.append(AMBUSH_CENTER + Vector2(38, 18))
		list.append(AMBUSH_CENTER + Vector2(0, -45))
	return list


func _draw() -> void:
	PortOfBrugesDrawScript.draw_world(self)
