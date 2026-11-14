extends "res://scripts/regions/RegionBase.gd"

## Secret Brotherhood Cliffside Sanctuary (Book I — Chapter 2, 5-Year Arc: Age 12 -> 17).
## Modular hub coordinating camp chores with Hendrick, Maren, & Matthijs,
## bonding with Kestrel & Virelai, 5-year winter progressions, and Sortie launches.

const SanctuaryDrawScript := preload("res://scripts/regions/SanctuaryDraw.gd")
const SanctuaryNarrativeScript := preload("res://scripts/regions/SanctuaryNarrative.gd")
const SanctuaryVillageDataScript := preload("res://scripts/regions/SanctuaryVillageData.gd")
const SanctuaryMontageCutsceneScript := preload("res://scripts/regions/SanctuaryMontageCutscene.gd")
const SanctuaryArrivalCutsceneScript := preload("res://scripts/regions/SanctuaryArrivalCutscene.gd")
const SanctuaryAct4Script := preload("res://scripts/regions/SanctuaryAct4.gd")

const ACT2_ANNA_POS := Vector2(310, 495)
const ACT2_VIRELAI_RING_POS := Vector2(365, 455)
const ACT2_VIRELAI_RACK_POS := Vector2(238, 456)
const ACT2_FLIGHT_BOARD_POS := Vector2(445, 420)
const ACT2_VIRELAI_CARE_POS := Vector2(420, 435)
const ACT2_HENDRICK_POS := Vector2(220, 650)
const ACT2_LEATHER_PILE_POS := Vector2(475, 745)
const ACT2_MAREN_POS := Vector2(180, 232)
const ACT2_SPRING_POS := Vector2(515, 222)
const ACT2_MATTHIJS_EAST_POS := Vector2(980, 470)
const ACT2_MATTHIJS_WEST_POS := Vector2(500, 295)
const ACT2_PENNANT_POST_POS := Vector2(1110, 495)
const ACT2_CAMPFIRE_POS := Vector2(416, 608)
const ACT2_FISH_BUCKET_POS := Vector2(458, 614)
const ACT2_DRILL_BOARD_POS := Vector2(128, 622)
const ACT2_COOK_POS := Vector2(528, 822)
const ACT2_HERDSMAN_POS := Vector2(1134, 816)
const ACT2_WEST_WATCHER_POS := Vector2(650, 788)
const ACT2_VICTUAL_STALL_POS := Vector2(623, 660)
const ACT2_GORGE_POSTS: Array[Vector2] = [Vector2(680, 380), Vector2(860, 380)]
const ACT2_CAGE_POS := Vector2(1180, 390)

var sanctuary_lights: Array[PointLight2D] = []
var virelai_splice_flash: float = 0.0
var virelai_eat_timer: float = 0.0
var greyling_offset: Vector2 = Vector2.ZERO
var cage_shards: Array[Dictionary] = []
var kestrel_feed_timer: float = 0.0
var kestrel_fish_start: Vector2 = Vector2.ZERO
var kestrel_leap_offset: Vector2 = Vector2.ZERO
var virelai_eye_flare: float = 0.0
var virelai_bow_timer: float = 0.0
var virelai_bow_dip: float = 0.0
var salve_anim_timer: float = 0.0
var salve_shiver_amp: float = 0.0
var kestrel_greet_timer: float = 0.0
var kestrel_greet_kind: String = ""
var npc_wave_target: String = ""
var npc_wave_timer: float = 0.0
var victual_flash: float = 0.0
var livestock_bounce_kind: String = ""
var livestock_bounce_timer: float = 0.0
var fx_particles: Array[Dictionary] = []
var virelai_tail_nudged: bool = false
var montage_active: bool = false
var montage_kind: String = ""
var montage_stage: int = 0
var montage_t: float = 0.0
var montage_tint_active: bool = false
var montage_tint: Color = Color(0.84, 0.88, 0.86)
var montage_hide_cage: bool = false
var montage_hide_ground_kestrel: bool = false
var montage_kestrel_fly_active: bool = false
var montage_kestrel_fly_pos: Vector2 = Vector2.ZERO
var montage_rope_active: bool = false
var montage_rope_origin: Vector2 = Vector2.ZERO
var montage_rope_tip: Vector2 = Vector2.ZERO
var montage_strap_vigil_active: bool = false
var montage_rig_strap_active: bool = false
var montage_rig_pull: float = 0.0
var montage_maren_override: bool = false
var montage_maren_pos: Vector2 = Vector2.ZERO
var montage_beacon_active: bool = false
var montage_virelai_dip: float = 0.0
var montage_lightning: float = 0.0
var weather_flakes: Array[Dictionary] = []
var sage_vapor: Array[Dictionary] = []
var arrival_active: bool = false
var arrival_stage: int = 0
var arrival_t: float = 0.0
var arrival_hide_ground_duo: bool = false
var arrival_virelai_pos: Vector2 = Vector2.ZERO
var arrival_virelai_alt: float = 0.0
var arrival_virelai_dip: float = 0.0
var arrival_anna_pos: Vector2 = Vector2.ZERO
var arrival_cloth_pos: Vector2 = Vector2.ZERO
var arrival_cloth_timer: float = 0.0
var arrival_puffs: Array[Dictionary] = []
var act4_guards: Array[Dictionary] = []
var act4_guard_lights: Array[PointLight2D] = []
var act4_tripwires: Array[Dictionary] = []
var sight_blockers: Array[Rect2] = []
var act4_alert_cooldown: float = 0.0
var act4_intro_active: bool = false
var act4_intro_stage: int = 0
var act4_intro_t: float = 0.0
var act4_intro_wait_dlg: bool = false
var act4_messenger_present: bool = false
var act4_messenger_pos: Vector2 = Vector2(96, 518)
var act4_escape_active: bool = false
var act4_escape_stage: int = 0
var act4_escape_t: float = 0.0
var act4_escape_wait_dlg: bool = false


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	add_box_collider(colliders, Rect2(0, 0, 1800, 30))
	add_box_collider(colliders, Rect2(0, 1110, 1800, 30))
	add_box_collider(colliders, Rect2(0, 0, 30, 1140))
	add_box_collider(colliders, Rect2(1770, 0, 30, 1140))
	add_box_collider(colliders, Rect2(720, 30, 100, 665))
	add_box_collider(colliders, Rect2(720, 785, 100, 325))
	add_box_collider(colliders, Rect2(315, 360, 105, 80))
	add_box_collider(colliders, Rect2(194, 608, 52, 32))
	add_box_collider(colliders, Rect2(130, 204, 38, 32))
	add_box_collider(colliders, Rect2(492, 202, 46, 30))
	add_box_collider(colliders, Rect2(400, 596, 32, 24))
	for vrect in SanctuaryVillageDataScript.get_village_colliders():
		add_box_collider(colliders, vrect)
	sight_blockers = SanctuaryVillageDataScript.get_sight_blockers()
	sight_blockers.append_array([Rect2(315, 360, 105, 76), Rect2(194, 608, 52, 28), Rect2(130, 204, 38, 28), Rect2(492, 202, 46, 26)])

	for s_info in [
		[Vector2(360, 410), 2.8, Color(0.55, 0.92, 0.68), 0.72],
		[Vector2(170, 232), 2.1, Color(0.68, 0.96, 0.74), 0.58],
		[ACT2_CAMPFIRE_POS, 2.3, Color(1.0, 0.68, 0.34), 0.72],
		[Vector2(770, 725), 2.2, Color(1.0, 0.80, 0.44), 0.65],
		[ACT2_CAGE_POS, 2.4, Color(0.85, 0.90, 1.0), 0.62],
		[Vector2(184, 150), 2.1, Color(1.0, 0.78, 0.44), 0.56],
		[Vector2(416, 148), 2.1, Color(1.0, 0.76, 0.40), 0.56],
		[Vector2(491, 814), 2.3, Color(1.0, 0.66, 0.32), 0.66],
		[Vector2(1309, 268), 2.2, Color(0.95, 0.82, 0.52), 0.52],
		[Vector2(980, 882), 2.1, Color(1.0, 0.76, 0.42), 0.50],
	]:
		var sl: PointLight2D = assets.make_point_light(s_info[0], s_info[1], s_info[2], s_info[3])
		add_child(sl)
		sanctuary_lights.append(sl)

	SanctuaryDrawScript.setup_layers(self)
	SanctuaryAct4Script.init_state(self)

	interactables = [
		{"id": "act2_hendrick", "name": "Master Saddler Hendrick", "pos": ACT2_HENDRICK_POS + Vector2(20, 12), "radius": 72.0, "callback": func(): SanctuaryNarrativeScript.interact_hendrick(self)},
		{"id": "act2_drill_board", "name": "Topman Knot-Speed Drill Board", "pos": ACT2_DRILL_BOARD_POS, "radius": 68.0, "callback": func(): SanctuaryNarrativeScript.interact_drill_board(self)},
		{"id": "act2_fish_bucket", "name": "Grab Fresh Herring for Kestrel", "pos": ACT2_FISH_BUCKET_POS, "radius": 62.0, "callback": _on_pickup_herring},
		{"id": "act2_leather_bale", "name": "Haul Cured Wyrm-Hide Bale", "pos": ACT2_LEATHER_PILE_POS, "radius": 64.0, "callback": _on_pickup_leather_bale},
		{"id": "act2_maren", "name": "Chirurgeon Sister Maren", "pos": ACT2_MAREN_POS + Vector2(10, 10), "radius": 72.0, "callback": func(): SanctuaryNarrativeScript.interact_maren(self)},
		{"id": "act2_spring_well", "name": "Draw Cliff-Spring Water", "pos": ACT2_SPRING_POS, "radius": 68.0, "callback": _on_draw_spring_water},
		{"id": "act2_virelai_ring", "name": "Virelai's Harness Ring (Tie Dragon Splice)", "pos": ACT2_VIRELAI_RING_POS, "radius": 74.0, "callback": _on_interact_virelai_ring},
		{"id": "act2_virelai_rack", "name": "Hang Mutton Ration on Butcher Rack", "pos": ACT2_VIRELAI_RACK_POS, "radius": 72.0, "callback": func(): SanctuaryNarrativeScript.interact_virelai_butcher_rack(self)},
		{"id": "act2_virelai_care", "name": "Clean Virelai's Wing & Speak", "pos": ACT2_VIRELAI_CARE_POS, "radius": 78.0, "callback": func(): SanctuaryNarrativeScript.interact_virelai_talk_y3(self)},
		{"id": "act2_matthijs", "name": "Bellman Matthijs", "pos": ACT2_MATTHIJS_EAST_POS, "radius": 72.0, "callback": func(): SanctuaryNarrativeScript.interact_matthijs(self)},
		{"id": "act2_pennant_post", "name": "String Gorge Signal-Pennant [Bowline]", "pos": ACT2_PENNANT_POST_POS, "radius": 70.0, "callback": _on_interact_pennant_post},
		{"id": "act2_anna", "name": "Captain Anna", "pos": ACT2_ANNA_POS, "radius": 72.0, "callback": func(): SanctuaryNarrativeScript.interact_anna(self)},
		{"id": "act2_flight_launch", "name": "Board Virelai (Fly Brotherhood Sortie)", "pos": ACT2_FLIGHT_BOARD_POS, "radius": 78.0, "callback": _on_board_virelai_sortie},
		{"id": "act2_winch_w", "name": "Gorge Winch Post ([Click / E / F] Grapple East)", "pos": ACT2_GORGE_POSTS[0], "radius": 68.0, "callback": func(): _try_sanctuary_winch()},
		{"id": "act2_winch_e", "name": "Gorge Winch Post ([Click / E / F] Grapple West)", "pos": ACT2_GORGE_POSTS[1], "radius": 68.0, "callback": func(): _try_sanctuary_winch()},
		{"id": "act2_greyling", "name": "Silver-Slate Courier", "pos": ACT2_CAGE_POS, "radius": 84.0, "callback": _on_interact_greyling},
		{"id": "act2_cook_mieke", "name": "Camp Cook Mieke", "pos": ACT2_COOK_POS, "radius": 70.0, "callback": func(): SanctuaryNarrativeScript.interact_cook_mieke(self)},
		{"id": "act2_herdsman_bram", "name": "Stockman Joost", "pos": ACT2_HERDSMAN_POS, "radius": 72.0, "callback": func(): SanctuaryNarrativeScript.interact_herdsman_bram(self)},
		{"id": "act2_victual_stall", "name": "Inspect Victualler Market Stall", "pos": ACT2_VICTUAL_STALL_POS, "radius": 62.0, "callback": func(): SanctuaryNarrativeScript.interact_victual_stall(self)},
		{"id": "act2_west_scout", "name": "Brotherhood Bridge Scout", "pos": ACT2_WEST_WATCHER_POS, "radius": 56.0, "callback": func(): SanctuaryNarrativeScript.interact_covert_watch(self)},
		{"id": "act2_sheep_pen", "name": "Inspect Sheep Paddock", "pos": Vector2(1278, 622), "radius": 64.0, "callback": func(): SanctuaryNarrativeScript.interact_livestock_pen(self, "sheep")},
		{"id": "act2_cattle_pen", "name": "Inspect Cattle Pasture", "pos": Vector2(1308, 822), "radius": 64.0, "callback": func(): SanctuaryNarrativeScript.interact_livestock_pen(self, "cow")},
		{"id": "act2_hog_pen", "name": "Inspect Hog Yard", "pos": Vector2(1144, 1020), "radius": 58.0, "callback": func(): SanctuaryNarrativeScript.interact_livestock_pen(self, "pig")},
		{"id": "act4_pedestal", "name": "Brazier Egg Stand", "pos": SanctuaryAct4Script.PEDESTAL_POS, "radius": 68.0, "callback": func(): SanctuaryAct4Script.interact_pedestal(self)},
	]
	clear_walk_portals()
	register_walk_portal("act4_west_gate", Rect2(0, 416, 108, 208), Vector2.LEFT, func(): SanctuaryAct4Script.interact_to_bruges_city(self), "<- Toward Bruges Outskirts", "BRUGES OUTSKIRTS", "Eastern Coastal Trail")


func enter_region(opts: Dictionary = {}) -> void:
	if not opts.get("preserve_step", false):
		GameState.current_step = GameState.QuestStep.ACT2_SANCTUARY
	GameState.boy_hp = GameState.boy_max_hp
	GameState.sanctuary_carrying_item = ""
	player.position = opts.get("spawn", Vector2(215, 515))
	player.facing = Vector2.RIGHT
	player.visible = true
	player.can_move = not ui.is_blocking_gameplay()

	var cam: Camera2D = director.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1800
	cam.limit_bottom = 1140
	cam.zoom = Vector2(1.5, 1.5)
	cam.position = player.position

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	SoundManager.play_chime()
	ui.refresh_hud()
	virelai_splice_flash = 0.0
	virelai_eat_timer = 0.0
	kestrel_feed_timer = 0.0
	kestrel_leap_offset = Vector2.ZERO
	virelai_eye_flare = 0.0
	virelai_bow_timer = 0.0
	virelai_bow_dip = 0.0
	salve_anim_timer = 0.0
	salve_shiver_amp = 0.0
	kestrel_greet_timer = 0.0
	kestrel_greet_kind = ""
	npc_wave_target = ""
	npc_wave_timer = 0.0
	victual_flash = 0.0
	livestock_bounce_kind = ""
	livestock_bounce_timer = 0.0
	fx_particles.clear()
	virelai_tail_nudged = false
	montage_active = false
	montage_tint_active = false
	montage_hide_cage = false
	montage_hide_ground_kestrel = false
	montage_kestrel_fly_active = false
	montage_rope_active = false
	montage_strap_vigil_active = false
	montage_rig_strap_active = false
	montage_rig_pull = 0.0
	montage_maren_override = false
	montage_beacon_active = false
	montage_virelai_dip = 0.0
	montage_lightning = 0.0
	arrival_active = false
	arrival_hide_ground_duo = false
	arrival_virelai_dip = 0.0
	arrival_cloth_timer = 0.0
	arrival_puffs.clear()
	weather_flakes.clear()
	sage_vapor.clear()
	cage_shards.clear()
	greyling_offset = Vector2(26, -12) if GameState.greyling_cage_broken else Vector2.ZERO

	SanctuaryAct4Script.init_state(self)
	if bool(opts.get("cutscene_year3", false)):
		SanctuaryMontageCutsceneScript.start_montage(self, SanctuaryMontageCutsceneScript.KIND_YEAR3, false)
	elif bool(opts.get("cutscene_year5", false)):
		SanctuaryMontageCutsceneScript.start_montage(self, SanctuaryMontageCutsceneScript.KIND_YEAR5, false)
	elif bool(opts.get("arrival_cutscene", false)):
		SanctuaryArrivalCutsceneScript.start_arrival(self)
	elif bool(opts.get("return_sortie1", false)):
		SanctuaryNarrativeScript.handle_return_sortie1(self)
	elif bool(opts.get("act4_debate_intro", false)) or GameState.sanctuary_phase == 4 or GameState.current_step == GameState.QuestStep.ACT4_SANCTUARY_DEBATE:
		SanctuaryAct4Script.enter_phase4_debate(self, opts)
	elif bool(opts.get("cutscene_kestrel_escape", false)) or GameState.sanctuary_phase == 5 or GameState.current_step == GameState.QuestStep.ACT4_NIGHT_HEIST:
		SanctuaryAct4Script.enter_phase5_heist(self, opts)
	elif not bool(opts.get("skip_intro", false)):
		SanctuaryNarrativeScript.intro_after_abduction(self)
	if not arrival_active and not act4_intro_active and not montage_active and not act4_escape_active:
		cam.position = player.position
	ui.refresh_hud()


func get_ambience_track() -> String: return "sanctuary"

func get_lighting_tint() -> Color:
	if montage_tint_active: return montage_tint
	match GameState.sanctuary_phase:
		2: return Color(0.88, 0.91, 0.87)
		3: return Color(0.76, 0.78, 0.86)
		4: return Color(0.84, 0.78, 0.72)
		5: return Color(0.32, 0.38, 0.56)
		_: return Color(0.84, 0.88, 0.86)

func get_surface_at(pos: Vector2) -> String:
	if Rect2(704, 696, 136, 92).has_point(pos): return "wood"
	return "cobble" if Rect2(120, 320, 440, 260).has_point(pos) else "grass"


func update_region_lights(time_val: float) -> void:
	sync_light_frustum(sanctuary_lights, true, 24.0)
	for i in range(sanctuary_lights.size()):
		var sl: PointLight2D = sanctuary_lights[i]
		if sl.visible:
			sl.energy = 0.68 + sin(time_val * 3.8 + float(i) * 1.9) * 0.08


func spawn_fx_burst(origin: Vector2, count: int, col: Color, min_spd: float = 36.0, max_spd: float = 95.0, life: float = 0.55, sz: float = 3.0) -> void:
	for _i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(min_spd, max_spd)
		fx_particles.append({
			"pos": origin,
			"vel": Vector2(cos(ang), sin(ang) - 0.25) * spd,
			"t": life,
			"max_t": life,
			"col": col,
			"sz": sz,
		})


func step_region(delta: float) -> void:
	virelai_splice_flash = maxf(0.0, virelai_splice_flash - delta)
	virelai_eye_flare = maxf(0.0, virelai_eye_flare - delta)
	npc_wave_timer = maxf(0.0, npc_wave_timer - delta)
	if npc_wave_timer <= 0.0:
		npc_wave_target = ""
	victual_flash = maxf(0.0, victual_flash - delta)
	livestock_bounce_timer = maxf(0.0, livestock_bounce_timer - delta)
	if livestock_bounce_timer <= 0.0:
		livestock_bounce_kind = ""
	for i in range(fx_particles.size() - 1, -1, -1):
		var fp: Dictionary = fx_particles[i]
		fp["t"] = float(fp["t"]) - delta
		fp["pos"] = Vector2(fp["pos"]) + Vector2(fp["vel"]) * delta
		fp["vel"] = Vector2(fp["vel"]) * 0.92 + Vector2(0, 18.0) * delta
		if float(fp["t"]) <= 0.0:
			fx_particles.remove_at(i)
	if act4_intro_active:
		SanctuaryAct4Script.process_phase4_intro(self, delta)
		_update_spatial_audio()
		queue_redraw()
		return
	if montage_active:
		SanctuaryMontageCutsceneScript.process_montage(self, delta)
		_update_spatial_audio()
		queue_redraw()
		return
	if arrival_active:
		SanctuaryArrivalCutsceneScript.process_arrival(self, delta)
		_update_spatial_audio()
		queue_redraw()
		return
	if virelai_bow_timer > 0.0:
		virelai_bow_timer = maxf(0.0, virelai_bow_timer - delta)
		var bp := clampf(1.0 - virelai_bow_timer / 1.15, 0.0, 1.0)
		virelai_bow_dip = sin(minf(bp * 1.15, 1.0) * PI * 0.5) * 11.0
		if virelai_bow_timer <= 0.0:
			virelai_bow_dip = 11.0
			_open_virelai_splice_minigame()
	elif not ui.is_blocking_gameplay() and virelai_bow_dip > 0.0:
		virelai_bow_dip = maxf(0.0, virelai_bow_dip - delta * 24.0)
	if salve_anim_timer > 0.0:
		var prev_st := salve_anim_timer
		salve_anim_timer = maxf(0.0, salve_anim_timer - delta)
		var sp := clampf(1.0 - salve_anim_timer / 2.25, 0.0, 1.0)
		if sp < 0.35:
			salve_shiver_amp = 2.6
			greyling_offset = greyling_offset.lerp(Vector2(38, -14), minf(1.0, delta * 5.0))
		elif sp < 0.72:
			salve_shiver_amp = lerpf(2.6, 0.4, (sp - 0.35) / 0.37)
			player.position.x = minf(player.position.x + delta * 18.0, ACT2_CAGE_POS.x - 42.0)
			if int(prev_st * 4.5) > int(salve_anim_timer * 4.5):
				sage_vapor.append({
					"pos": Vector2(player.position.x + 18.0, ACT2_CAGE_POS.y - 12.0 + randf_range(-8, 6)),
					"vel": Vector2(randf_range(12, 26), randf_range(-28, -14)),
					"t": 0.95,
					"max_t": 0.95,
				})
		else:
			if salve_shiver_amp > 0.35:
				SoundManager.play_dragon_purr()
				SoundManager.play_chime()
			salve_shiver_amp = maxf(0.0, salve_shiver_amp - delta * 2.5)
			greyling_offset = greyling_offset.lerp(Vector2(10, -4), minf(1.0, delta * 3.8))
		if salve_anim_timer <= 0.0:
			salve_shiver_amp = 0.0
			player.can_move = true
			player.set_cutscene_pose("")
			ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Meet back by Virelai's perch when you've finished drying your boots, %s." % GameState.player_name}
			])
	if kestrel_greet_timer > 0.0:
		kestrel_greet_timer = maxf(0.0, kestrel_greet_timer - delta)
		var gp := clampf(1.0 - kestrel_greet_timer / 1.0, 0.0, 1.0)
		match kestrel_greet_kind:
			"fish_hint":
				kestrel_leap_offset = Vector2(-6.0 * sin(gp * PI * 2.0), -absf(sin(gp * PI * 2.0)) * 14.0)
			"nuzzle":
				kestrel_leap_offset = Vector2(-14.0 * sin(gp * PI), -4.0 * sin(gp * PI))
			"recoil":
				kestrel_leap_offset = Vector2(18.0 * sin(gp * PI), -16.0 * sin(gp * PI))
			_:
				kestrel_leap_offset = Vector2(0.0, -4.0 * sin(gp * PI * 2.0))
		if kestrel_greet_timer <= 0.0:
			kestrel_leap_offset = Vector2.ZERO
			kestrel_greet_kind = ""
	if GameState.sanctuary_phase == 5:
		SanctuaryAct4Script.step_phase5(self, delta)
	if not act4_escape_active:
		director.camera.position = player.position
	for i in range(sage_vapor.size() - 1, -1, -1):
		var sv: Dictionary = sage_vapor[i]
		sv["t"] = float(sv["t"]) - delta
		sv["pos"] = Vector2(sv["pos"]) + Vector2(sv["vel"]) * delta
		if float(sv["t"]) <= 0.0:
			sage_vapor.remove_at(i)
	if virelai_eat_timer > 0.0:
		virelai_eat_timer = maxf(0.0, virelai_eat_timer - delta)
		if not virelai_tail_nudged and virelai_eat_timer <= 0.95:
			virelai_tail_nudged = true
			spawn_fx_burst(Vector2(442, 416), 8, Color(0.76, 0.74, 0.68), 32.0, 78.0, 0.45, 3.2)
			if player.position.distance_to(Vector2(430, 425)) < 165.0:
				player.position.x = maxf(player.position.x - 10.0, 140.0)
				spawn_fx_burst(player.position + Vector2(0, 4), 5, Color(0.78, 0.76, 0.70), 20.0, 48.0, 0.35, 2.4)
		if virelai_eat_timer <= 0.0:
			virelai_tail_nudged = false
			player.can_move = true
			SanctuaryNarrativeScript.virelai_fed_dialogue(self)
	if kestrel_feed_timer > 0.0:
		kestrel_feed_timer = maxf(0.0, kestrel_feed_timer - delta)
		var p := 1.0 - kestrel_feed_timer / 1.45
		var leap_arc := sin(clampf((p - 0.14) / 0.80, 0.0, 1.0) * PI)
		kestrel_leap_offset = Vector2(-12.0 * leap_arc, -62.0 * leap_arc)
		if kestrel_feed_timer <= 0.0:
			kestrel_leap_offset = Vector2.ZERO
			player.can_move = true
			SanctuaryNarrativeScript.kestrel_fed_dialogue(self)
	if GameState.greyling_cage_broken:
		greyling_offset = greyling_offset.lerp(Vector2(28, -14), minf(1.0, delta * 3.8))
	for i in range(cage_shards.size() - 1, -1, -1):
		var sh: Dictionary = cage_shards[i]
		sh["t"] = float(sh["t"]) - delta
		sh["pos"] = Vector2(sh["pos"]) + Vector2(sh["vel"]) * delta
		if float(sh["t"]) <= 0.0:
			cage_shards.remove_at(i)
	_update_spatial_audio()
	queue_redraw()


func _exit_tree() -> void:
	SoundManager.stop_spatial_layers()
	SanctuaryAct4Script._clear_guard_lights(self)
	if player != null:
		player.cutscene_hidden = false
	if director != null and director.camera != null:
		director.camera.zoom = Vector2(1.5, 1.5)
	if (montage_active or arrival_active or act4_intro_active or act4_escape_active) and ui != null:
		ui.hide_time_stamp()
		ui.set_fade(0.0, true)
		ui.set_cinematic_mode(false)


func _update_spatial_audio() -> void:
	if player == null:
		return
	var pasture_dist := 9999.0
	for p_center in [Vector2(1478, 610), Vector2(1460, 930), Vector2(1040, 1005)]:
		pasture_dist = minf(pasture_dist, player.position.distance_to(p_center))
	var pasture_w := clampf(1.0 - (pasture_dist - 150.0) / 360.0, 0.0, 1.0)
	var mess_dist := player.position.distance_to(Vector2(505, 860))
	var mess_w := clampf(1.0 - (mess_dist - 120.0) / 310.0, 0.0, 1.0)
	if ui != null and ui.is_blocking_gameplay():
		pasture_w *= 0.45
		mess_w *= 0.45
	SoundManager.update_spatial_layers(pasture_w, mess_w)


func handle_region_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not player.winch_dash_active:
			var mouse_world: Vector2 = get_global_mouse_position()
			var click_canvas: Vector2 = get_canvas_transform().affine_inverse() * mb.position
			for gpost in ACT2_GORGE_POSTS:
				var target_pt: Vector2 = gpost + Vector2(0, -12)
				if (mouse_world.distance_to(target_pt) <= 68.0 or click_canvas.distance_to(target_pt) <= 68.0) and (player.position.distance_to(ACT2_GORGE_POSTS[0]) <= 340.0 or player.position.distance_to(ACT2_GORGE_POSTS[1]) <= 340.0):
					_try_sanctuary_winch(true)
					return true
	return false


func is_interactable_active(id: String) -> bool:
	if montage_active or arrival_active or act4_intro_active or act4_escape_active:
		return false
	var ph := GameState.sanctuary_phase
	if ph == 5:
		match id:
			"act4_pedestal":
				return not GameState.act4_egg_stolen_back
			"act2_greyling", "act2_winch_w", "act2_winch_e":
				return true
			_:
				return false
	match id:
		"act2_leather_bale":
			return ph == 1 and not GameState.sanctuary_leather_chore_done and GameState.sanctuary_carrying_item != "leather"
		"act2_spring_well":
			return ph == 1 and not GameState.sanctuary_poultice_brewed and not GameState.sanctuary_water_drawn and GameState.sanctuary_carrying_item != "water"
		"act2_virelai_ring":
			return ph == 1 and not GameState.virelai_harness_spliced
		"act2_virelai_rack":
			return GameState.sanctuary_carrying_item == "mutton" and virelai_eat_timer <= 0.0
		"act2_virelai_care":
			return (ph == 2 and not GameState.sanctuary_virelai_talk_done) or ph == 3 or ph == 4
		"act2_matthijs":
			return ph >= 2 and ph <= 4
		"act2_pennant_post":
			return ph == 2 and not GameState.sanctuary_pennants_strung
		"act2_fish_bucket":
			return ph == 2 and not GameState.sanctuary_kestrel_fed and GameState.sanctuary_carrying_item != "fish"
		"act2_drill_board":
			return ph == 2 or ph == 3
		"act2_flight_launch":
			if ph == 2:
				return GameState.sanctuary_virelai_talk_done and not GameState.flight_sortie1_done
			if ph == 3:
				return GameState.sanctuary_jerkin_earned
			return false
		"act2_greyling":
			return kestrel_feed_timer <= 0.0
		"act4_pedestal":
			return ph == 4
		_:
			return true


func get_interact_bubble_offset(id: String) -> Vector2:
	if id == "act2_greyling":
		return Vector2(0, -88 if GameState.sanctuary_phase >= 3 else (-78 if GameState.sanctuary_phase == 2 else -68))
	return Vector2(0, -48)


func _on_pickup_leather_bale() -> void:
	if GameState.sanctuary_carrying_item == "water":
		SoundManager.play_splash()
		spawn_fx_burst(player.position + Vector2(0, -14), 7, Color(0.48, 0.84, 0.98), 28.0, 62.0, 0.42, 2.6)
		npc_wave_target = "maren"
		npc_wave_timer = 1.6
		return
	GameState.sanctuary_carrying_item = "leather"
	SoundManager.play_crate_pickup()
	player.show_held_item(assets.get_tex("prop_leather_bale.png"), 0.85)
	npc_wave_target = "hendrick"
	npc_wave_timer = 2.0
	ui.refresh_hud()


func _on_draw_spring_water() -> void:
	if GameState.sanctuary_carrying_item == "leather":
		SoundManager.play_crate_pickup()
		spawn_fx_burst(player.position + Vector2(0, -14), 6, Color(0.68, 0.48, 0.28), 24.0, 52.0, 0.40, 2.4)
		npc_wave_target = "hendrick"
		npc_wave_timer = 1.6
		return
	GameState.sanctuary_water_drawn = true
	GameState.sanctuary_carrying_item = "water"
	SoundManager.play_splash()
	spawn_fx_burst(ACT2_SPRING_POS + Vector2(0, -8), 9, Color(0.46, 0.84, 0.98), 32.0, 74.0, 0.48, 2.8)
	player.show_held_item(assets.get_tex("prop_water_bucket.png"), 0.85)
	npc_wave_target = "maren"
	npc_wave_timer = 2.0
	ui.refresh_hud()


func _on_pickup_herring() -> void:
	if GameState.sanctuary_kestrel_fed or GameState.sanctuary_phase != 2:
		return
	GameState.sanctuary_carrying_item = "fish"
	SoundManager.play_crate_pickup()
	spawn_fx_burst(ACT2_FISH_BUCKET_POS + Vector2(0, -10), 7, Color(0.76, 0.92, 0.98), 24.0, 58.0, 0.42, 2.4)
	player.show_held_item(assets.get_tex("prop_herring_fish.png"), 0.85)
	npc_wave_target = "kestrel"
	npc_wave_timer = 2.0
	ui.refresh_hud()
	queue_redraw()


func _on_interact_virelai_ring() -> void:
	if GameState.virelai_harness_spliced or virelai_bow_timer > 0.0:
		return
	if not GameState.sanctuary_leather_chore_done:
		ui.show_dialogue([{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Not so fast—without cured wyrm-hide on my bench I've got no waxed straps to rebuild that ring with."}])
		return
	player.facing = Vector2.UP
	player.can_move = false
	player.set_cutscene_pose("boy_kneel.png")
	virelai_bow_timer = 1.15
	virelai_eye_flare = 1.4
	SoundManager.play_wing_beat()
	SoundManager.play_dragon_purr()
	spawn_fx_burst(Vector2(342, 428), 8, Color(0.72, 0.74, 0.78), 28.0, 68.0, 0.55, 3.0)


func _open_virelai_splice_minigame() -> void:
	ui.open_knot_minigame("dragon_splice", func(_id):
		GameState.virelai_harness_spliced = true
		GameState.add_item("Brotherhood Harness Carabiner")
		GameState.add_dragon_trust(10)
		virelai_splice_flash = 1.0
		SoundManager.play_dragon_purr()
		SoundManager.play_chime()
		player.can_move = true
		player.set_cutscene_pose("")
		player.show_held_item(assets.get_tex("icon_carabiner.png"), 1.2)
		ui.refresh_hud()
		virelai_eye_flare = 1.5
		var done_lines: Array[Dictionary] = []
		if GameState.clara_gift_received:
			done_lines.append({"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Clean dressing—even waxed the turn like a guild rigger. Sister Maren's over by the north kettle if you've a mind to help."})
		else:
			done_lines.append({"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Good work. Sister Maren's tending something hot by the north rocks—might see if she needs a hand."})
		ui.show_dialogue(done_lines)
	, func(_id):
		player.can_move = true
		player.set_cutscene_pose("")
	)


func _on_interact_pennant_post() -> void:
	if GameState.sanctuary_pennants_strung:
		return
	ui.open_knot_minigame("bowline", func(_id):
		GameState.sanctuary_pennants_strung = true
		GameState.add_dragon_trust(10)
		SoundManager.play_knot_cinch()
		SoundManager.play_chime()
		ui.refresh_hud()
		queue_redraw()
		ui.show_dialogue([
			{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Look at that green Brotherhood swallowtail stream out! East gusts twenty knots—clean flying weather."},
			{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Hear Anna's checking salt crust on Virelai's left wing-hinge back west before patrol lifts."}
		])
	)


func _on_board_virelai_sortie() -> void:
	if GameState.sanctuary_phase >= 2 and not GameState.sanctuary_virelai_fed:
		ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Hold up—Virelai won't haul two men through a sea-gale on an empty stomach. Check with Stockman Joost out by the sheepfold before we strap in."}
		])
		return
	var next_sortie := 2 if GameState.sanctuary_phase >= 3 else 1
	director.load_region("flight", {"sortie": next_sortie})


func _try_sanctuary_winch(auto_equip: bool = true) -> void:
	if not GameState.unlocked_knots.has("dragon_splice"):
		SoundManager.play_knot_snag()
		var nearest_post: Vector2 = ACT2_GORGE_POSTS[0] if player.position.distance_to(ACT2_GORGE_POSTS[0]) <= player.position.distance_to(ACT2_GORGE_POSTS[1]) else ACT2_GORGE_POSTS[1]
		spawn_fx_burst(nearest_post + Vector2(0, -14), 10, Color(0.98, 0.70, 0.28), 44.0, 108.0, 0.45, 2.8)
		return
	if auto_equip and GameState.equipped_knot != "dragon_splice":
		GameState.equipped_knot = "dragon_splice"
		GameState.emit_signal("state_updated")
	var go_east := player.position.x < 770.0
	var dest := Vector2(905, 386) if go_east else Vector2(635, 386)
	var anchor := ACT2_GORGE_POSTS[1] if go_east else ACT2_GORGE_POSTS[0]
	player.start_winch_dash(dest, anchor)
	SoundManager.play_knot_cinch()


func on_rope_cast_hit(tip_pos: Vector2, knot_id: String) -> void:
	if SanctuaryAct4Script.handle_rope_cast(self, tip_pos):
		return
	if not GameState.greyling_cage_broken and tip_pos.distance_to(ACT2_CAGE_POS) <= 105.0:
		if knot_id in ["bruges_whipping", "dragon_splice"]:
			GameState.greyling_cage_broken = true
			SoundManager.play_cage_break()
			SoundManager.play_wing_beat()
			director.trigger_camera_shake(6.0, 0.28)
			for _i in range(14):
				var ang := randf_range(0.0, TAU)
				var spd := randf_range(65.0, 175.0)
				cage_shards.append({"pos": ACT2_CAGE_POS, "vel": Vector2(cos(ang), sin(ang) - 0.25) * spd, "t": 0.65, "max_t": 0.65})
			spawn_fx_burst(ACT2_CAGE_POS + Vector2(8, -10), 10, Color(0.84, 0.90, 0.96), 34.0, 82.0, 0.62, 2.6)
			ui.refresh_hud()
		else:
			SoundManager.play_knot_snag()
			SoundManager.play_hit()
			spawn_fx_burst(ACT2_CAGE_POS + Vector2(18, 6), 12, Color(0.98, 0.72, 0.28), 50.0, 120.0, 0.44, 2.6)
		return
	if knot_id == "dragon_splice" or GameState.unlocked_knots.has("dragon_splice"):
		for gpost in ACT2_GORGE_POSTS:
			if tip_pos.distance_to(gpost) <= 120.0 or player.position.distance_to(gpost) <= 95.0:
				_try_sanctuary_winch(true)
				return


func on_knife_slash(tip_pos: Vector2, _dir: Vector2) -> void:
	SanctuaryAct4Script.handle_knife_slash(self, tip_pos)


func _on_interact_greyling() -> void:
	if kestrel_feed_timer > 0.0 or salve_anim_timer > 0.0:
		return
	if SanctuaryAct4Script.interact_kestrel_escape(self):
		return
	if GameState.sanctuary_phase == 2 and GameState.sanctuary_carrying_item == "fish" and not GameState.sanctuary_kestrel_fed:
		GameState.sanctuary_carrying_item = ""
		kestrel_fish_start = player.position + Vector2(6, -16)
		kestrel_feed_timer = 1.45
		kestrel_leap_offset = Vector2.ZERO
		player.facing = (ACT2_CAGE_POS - player.position).normalized()
		player.can_move = false
		SoundManager.play_wing_beat()
		spawn_fx_burst(ACT2_CAGE_POS + greyling_offset + Vector2(-8, -12), 8, Color(0.84, 0.92, 0.98), 28.0, 74.0, 0.55, 2.5)
		ui.refresh_hud()
		queue_redraw()
		return
	if GameState.sanctuary_phase >= 2:
		kestrel_greet_timer = 1.0
		if GameState.sanctuary_phase == 2:
			if GameState.sanctuary_kestrel_fed:
				kestrel_greet_kind = "nuzzle"
				SoundManager.play_hatch_chirp()
				SoundManager.play_dragon_purr()
				spawn_fx_burst(ACT2_CAGE_POS + greyling_offset + Vector2(-14, -14), 9, Color(0.84, 0.92, 0.98), 26.0, 62.0, 0.58, 2.6)
			else:
				kestrel_greet_kind = "fish_hint"
				SoundManager.play_hatch_chirp()
				SoundManager.play_wing_beat()
				spawn_fx_burst(ACT2_CAGE_POS + greyling_offset + Vector2(-12, -10), 6, Color(0.76, 0.90, 0.98), 24.0, 56.0, 0.45, 2.2)
		else:
			kestrel_greet_kind = "crest"
			SoundManager.play_hatch_chirp()
			SoundManager.play_dragon_purr()
			spawn_fx_burst(ACT2_CAGE_POS + greyling_offset + Vector2(-8, -22), 10, Color(0.62, 0.94, 0.74), 28.0, 68.0, 0.62, 2.6)
		queue_redraw()
		return
	if not GameState.greyling_cage_broken:
		kestrel_greet_timer = 0.95
		kestrel_greet_kind = "clasp_hint"
		SoundManager.play_knot_snag()
		spawn_fx_burst(ACT2_CAGE_POS + Vector2(18, 6), 10, Color(0.92, 0.56, 0.24), 34.0, 86.0, 0.48, 2.5)
		queue_redraw()
		return
	if not GameState.sanctuary_poultice_brewed:
		kestrel_greet_timer = 1.0
		kestrel_greet_kind = "recoil"
		SoundManager.play_dragon_cry()
		SoundManager.play_wing_beat()
		spawn_fx_burst(ACT2_CAGE_POS + greyling_offset + Vector2(0, -10), 9, Color(0.86, 0.90, 0.96), 34.0, 88.0, 0.52, 2.6)
		queue_redraw()
		return
	if not GameState.sanctuary_greyling_treated:
		GameState.sanctuary_greyling_treated = true
		GameState.greyling_documented = true
		GameState.record_flight_breed("Greyling")
		GameState.add_dragon_trust(15)
		player.facing = Vector2.RIGHT
		player.can_move = false
		player.set_cutscene_pose("boy_kneel.png")
		player.show_held_item(assets.get_tex("icon_poultice.png"), 1.8)
		SoundManager.play_dragon_cry()
		ui.refresh_hud()
		salve_anim_timer = 2.25
		salve_shiver_amp = 2.6
		greyling_offset = Vector2(28, -14)
		for _i in range(6):
			sage_vapor.append({"pos": ACT2_CAGE_POS + Vector2(randf_range(-16, 16), randf_range(-8, 6)), "vel": Vector2(randf_range(-12, 12), randf_range(-34, -20)), "t": 1.1, "max_t": 1.1})

func get_interactable_pos(item: Dictionary) -> Vector2:
	if montage_active or arrival_active or act4_intro_active: return Vector2(item.get("pos", Vector2.ZERO))
	match String(item.get("id", "")):
		"act2_hendrick": return get_npc_yield_pos("sanct_hendrick", ACT2_HENDRICK_POS + Vector2(20, 12), 34.0, 12.0)
		"act2_maren": return get_npc_yield_pos("sanct_maren", ACT2_MAREN_POS + Vector2(10, 10), 34.0, 12.0)
		"act2_matthijs": return get_npc_yield_pos("sanct_matthijs", ACT2_MATTHIJS_EAST_POS if GameState.sanctuary_phase == 2 else ACT2_MATTHIJS_WEST_POS, 34.0, 12.0)
		"act2_anna": return get_npc_yield_pos("sanct_anna", ACT2_ANNA_POS, 34.0, 12.0)
		"act2_cook_mieke": return get_npc_yield_pos("sanct_cook", ACT2_COOK_POS, 34.0, 12.0)
		"act2_herdsman_bram": return get_npc_yield_pos("sanct_bram", ACT2_HERDSMAN_POS, 34.0, 12.0)
		"act2_west_scout": return get_npc_yield_pos("sanct_west_watch", ACT2_WEST_WATCHER_POS, 34.0, 12.0)
		_: return Vector2(item.get("pos", Vector2.ZERO))

func get_active_npc_colliders() -> Array:
	var list: Array = []
	var phase: int = GameState.sanctuary_phase
	var scripted: bool = montage_active or arrival_active or act4_intro_active
	if phase != 5:
		var h_base: Vector2 = Vector2(336, 550) if act4_intro_active else (ACT2_HENDRICK_POS + Vector2(24, 14))
		var maren_base: Vector2 = Vector2(278, 536) if act4_intro_active else (ACT2_MAREN_POS + Vector2(14, 10))
		list.append(h_base if scripted else {"pos": h_base, "yield_key": "sanct_hendrick"})
		list.append(maren_base if scripted else {"pos": maren_base, "yield_key": "sanct_maren"})
		if not arrival_active and not arrival_hide_ground_duo: list.append(ACT2_ANNA_POS if scripted else {"pos": ACT2_ANNA_POS, "yield_key": "sanct_anna"})
		list.append(ACT2_COOK_POS if scripted else {"pos": ACT2_COOK_POS, "yield_key": "sanct_cook"})
		list.append(ACT2_HERDSMAN_POS if scripted else {"pos": ACT2_HERDSMAN_POS, "yield_key": "sanct_bram"})
		list.append(ACT2_WEST_WATCHER_POS if scripted else {"pos": ACT2_WEST_WATCHER_POS, "yield_key": "sanct_west_watch"})
		list.append(Vector2(1542, 226) if scripted else {"pos": Vector2(1542, 226), "yield_key": "sanct_cliff_watch"})
		if phase >= 2:
			var m_pos: Vector2 = Vector2(412, 538) if act4_intro_active else (ACT2_MATTHIJS_EAST_POS if phase == 2 else ACT2_MATTHIJS_WEST_POS)
			list.append(m_pos if scripted else {"pos": m_pos, "yield_key": "sanct_matthijs"})
		if act4_messenger_present and phase == 4: list.append(act4_messenger_pos)
	else:
		for g: Dictionary in act4_guards: list.append(Vector2(g["pos"]))
	if not montage_hide_ground_kestrel and not montage_kestrel_fly_active:
		list.append({"pos": ACT2_CAGE_POS + greyling_offset, "offset": Vector2.ZERO, "radius": 28.0})
	for ani: Dictionary in SanctuaryVillageDataScript.get_livestock_entries():
		list.append({"pos": Vector2(ani["pos"]), "offset": Vector2.ZERO, "radius": 14.0})
	return list

func _draw() -> void: SanctuaryDrawScript.draw_sanctuary(self)
