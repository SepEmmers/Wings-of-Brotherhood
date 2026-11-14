extends "res://scripts/regions/RegionBase.gd"

const FrontierWildsMapDataScript := preload("res://scripts/regions/FrontierWildsMapData.gd")
const FrontierWildsDrawScript := preload("res://scripts/regions/FrontierWildsDraw.gd")

## Organic Frontier Woodland, Dragon Tracking, Clickable Gorge/Creek Winch Crossings,
## Map-Guided Whispering Pines Maze, Atmospheric Canopy Layer, and Egg Warmth Survival (Book I — Ch. 3).

const WORLD_W := 2880.0
const WORLD_H := 2160.0

# Key Organic Clearing & Landmark World Coordinates
const SPAWN_CRASH := Vector2(270, 1890)
const CLUE_TRACKS_POS := Vector2(305, 1410)
const BRAMBLE_WEST_POS := Vector2(545, 1345)
const CLUE_CART_POS := Vector2(845, 1285)
const FIRE_0_POS := Vector2(765, 1815)
const GORGE_WINCH_E := Vector2(605, 840)
const GORGE_WINCH_W := Vector2(405, 820)
const BLACK_DRAGON_POS := Vector2(215, 255)
const EGG_NEST_POS := Vector2(308, 305)
const HOLLOW_GATE_POS := Vector2(530, 315)

const CAIRN_1_POS := Vector2(1110, 305)
const FROST_DEAD_POS := Vector2(1635, 240)
const FIRE_ALPHA_POS := Vector2(1185, 845)
const BRAMBLE_SHORTCUT_POS := Vector2(1465, 825)
const BOULDER_2HORN_POS := Vector2(1720, 860)
const CART_FORK_POS := Vector2(1685, 1390)
const FIRE_BETA_POS := Vector2(2110, 1315)
const CREEK_WINCH_S := Vector2(2155, 615)
const CREEK_WINCH_N := Vector2(2145, 465)
const OUTPOST_POS := Vector2(2620, 255)

var bramble_bodies: Dictionary = {}
var hollow_gate_body: StaticBody2D
var wilds_lights: Array[PointLight2D] = []
var hunter_patrols: Array[Dictionary] = []
var hunter_lights: Array[PointLight2D] = []
var sight_blockers: Array[Rect2] = []
var alert_cooldown: float = 0.0

var clearings: Array[Dictionary] = []
var trails: Array[Dictionary] = []
var trail_polylines: Array[Dictionary] = []
var gorge_river_pts: PackedVector2Array = PackedVector2Array()
var creek_river_pts: PackedVector2Array = PackedVector2Array()
var forest_trees: Array[Dictionary] = []
var forest_rocks: Array[Dictionary] = []
var forest_logs: Array[Dictionary] = []
var forest_ferns: Array[Dictionary] = []
var moss_patches: Array[Dictionary] = []
var ridge_pts: PackedVector2Array = PackedVector2Array()
var ridge_rocks: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var cold_zones: Array[Rect2] = []
var fireflies: Array[Dictionary] = []
var mist_ribbons: Array[Dictionary] = []

var fg_canopy_node: ForestForegroundLayer
var hovered_winch_pos: Vector2 = Vector2(-9999, -9999)

var dragon_cutscene_active: bool = false
var dragon_stage: int = 0
var dragon_t: float = 0.0
var dragon_wait_dlg: bool = false
var dragon_visual_state: String = "dying"
var dragon_wing_revealed: bool = false
var egg_reveal_offset: Vector2 = Vector2.ZERO
var nest_sparks: Array[Dictionary] = []
var gate_blown_clear: bool = false
var breath_cutscene_active: bool = false
var breath_t: float = 0.0
var breath_gust_done: bool = false
var breath_streaks: Array[Dictionary] = []
var blown_debris: Array[Dictionary] = []
var crash_wakeup_timer: float = 0.0
var _outpost_fading: bool = false
const FLARE_ASCENT_DELTA := Vector2(84.0, -118.0)

var flare_active: bool = false
var flare_t: float = 0.0
var flare_origin: Vector2 = Vector2.ZERO
var flare_burst_done: bool = false
var flare_sparks: Array[Dictionary] = []
var wilds_fx_particles: Array[Dictionary] = []
var winch_hint_pos: Vector2 = Vector2(-9999, -9999)
var winch_hint_timer: float = 0.0
var winch_reach_timer: float = 0.0
var gate_rattle_timer: float = 0.0
var flare_peek_timer: float = 0.0
var frost_reset_flash: float = 0.0


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)

	FrontierWildsMapDataScript.setup_world(self)
	FrontierWildsDrawScript.setup_layers(self)
	fg_canopy_node = ForestForegroundLayer.new()
	fg_canopy_node.region = self
	fg_canopy_node.z_index = 22
	add_child(fg_canopy_node)
	_register_interactables()


func _register_interactables() -> void:
	interactables = [
		{"id": "wilds_tracks", "name": "Broken Hemlocks & Claw Tracks", "pos": CLUE_TRACKS_POS, "radius": 84.0, "callback": _on_interact_tracks},
		{"id": "wilds_clue", "name": "Shattered Ballista & Courier Map", "pos": CLUE_CART_POS, "radius": 88.0, "callback": _on_interact_wilds_clue},
		{"id": "wilds_black_dragon", "name": "Wounded Black-Scaled Dragon", "pos": BLACK_DRAGON_POS, "radius": 98.0, "callback": _on_interact_black_dragon},
		{"id": "wilds_egg_nest", "name": "Claim Black-Scaled Dragon Egg", "pos": EGG_NEST_POS, "radius": 78.0, "callback": _on_pickup_dragon_egg},
		{"id": "hollow_gate", "name": "Overgrown Ridge Roots", "pos": HOLLOW_GATE_POS, "radius": 74.0, "callback": _on_inspect_hollow_gate},
		{"id": "gorge_winch_e", "name": "Grapple Across Gorge ([E] / Click Post)", "pos": GORGE_WINCH_E, "radius": 82.0, "callback": func(): _cross_winch("gorge")},
		{"id": "gorge_winch_w", "name": "Grapple Back Across Gorge ([E] / Click Post)", "pos": GORGE_WINCH_W, "radius": 82.0, "callback": func(): _cross_winch("gorge")},
		{"id": "creek_winch_s", "name": "Grapple North Across Creek ([E] / Click Post)", "pos": CREEK_WINCH_S, "radius": 82.0, "callback": func(): _cross_winch("creek")},
		{"id": "creek_winch_n", "name": "Grapple South Across Creek ([E] / Click Post)", "pos": CREEK_WINCH_N, "radius": 82.0, "callback": func(): _cross_winch("creek")},
		{"id": "wilds_outpost", "name": "Brotherhood Watchtower Hearth", "pos": OUTPOST_POS, "radius": 98.0, "callback": _on_reach_frontier_outpost}
	]
	register_walk_portal("wilds_outpost", Rect2(OUTPOST_POS.x - 42.0, OUTPOST_POS.y - 24.0, 84.0, 52.0), Vector2.UP, _on_reach_frontier_outpost, "^ Watchtower Hearth", "WATCHTOWER HEARTH", "Brotherhood Outpost")


func enter_region(opts: Dictionary = {}) -> void:
	var step := int(opts.get("step", GameState.QuestStep.ACT3_WILDS_TRACKING))
	GameState.current_step = step
	player.position = opts.get("spawn", SPAWN_CRASH)
	player.facing = Vector2.UP
	player.visible = true
	player.set_cutscene_pose("")
	for flag in ["dragon_cutscene_active", "dragon_wait_dlg", "dragon_wing_revealed", "_outpost_fading", "flare_active", "flare_burst_done", "breath_cutscene_active", "breath_gust_done"]:
		set(flag, false)
	for zf in ["dragon_stage", "dragon_t", "flare_t", "winch_hint_timer", "winch_reach_timer", "gate_rattle_timer", "flare_peek_timer", "frost_reset_flash", "breath_t", "crash_wakeup_timer"]:
		set(zf, 0.0)
	dragon_stage = 0
	winch_hint_pos = Vector2(-9999, -9999)
	egg_reveal_offset = Vector2.ZERO
	flare_sparks.clear(); wilds_fx_particles.clear(); nest_sparks.clear(); breath_streaks.clear(); blown_debris.clear()
	gate_blown_clear = GameState.carrying_egg or step >= GameState.QuestStep.ACT3_EGG_TREK
	dragon_visual_state = "dead" if gate_blown_clear else "dying"
	_sync_dynamic_gates()
	GameState.last_safe_fire_pos = FIRE_0_POS if not GameState.carrying_egg else FIRE_ALPHA_POS
	var cam: Camera2D = director.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(WORLD_W)
	cam.limit_bottom = int(WORLD_H)
	cam.zoom = Vector2(1.5, 1.5)
	cam.position = player.position
	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.set_cinematic_mode(false)
	ui.refresh_hud()
	_redraw_world()
	if bool(opts.get("cutscene_reveal", false)):
		ui.set_fade(1.0, true)
		ui.set_fade(0.0, false)
		_start_dragon_reveal_cutscene()
	elif step == GameState.QuestStep.ACT3_WILDS_TRACKING:
		GameState.record_landmark("crash", "Crash Ravine")
		if bool(opts.get("crash_wakeup", true)):
			ui.set_fade(1.0, true)
			ui.set_fade(0.0, false)
		player.set_cutscene_pose("boy_kneel.png")
		crash_wakeup_timer = 1.15
		director.trigger_camera_shake(2.6, 0.28)
		_spawn_wilds_burst(player.position + Vector2(0, 6), 14, Color(0.32, 0.48, 0.24), 22.0, 74.0, 0.85, 25.0)
		_spawn_wilds_burst(player.position + Vector2(0, -18), 6, Color(0.96, 0.84, 0.42), 16.0, 48.0, 0.90, -14.0)
		SoundManager.play_chime()
	elif step == GameState.QuestStep.ACT3_EGG_TREK:
		GameState.has_forest_map = true
		GameState.record_landmark("hollow", "Obsidian Hollow")
		GameState.record_landmark("cairn1", "Roman Cairn I")
		ui.refresh_hud()
		SoundManager.play_chime()

func exit_region() -> void:
	dragon_cutscene_active = false
	breath_cutscene_active = false
	dragon_wait_dlg = false
	_outpost_fading = false
	player.set_cutscene_pose("")
	ui.set_cinematic_mode(false)
	if director != null and director.camera != null:
		director.camera.zoom = Vector2(1.5, 1.5)

func _sync_dynamic_gates() -> void:
	for bid in bramble_bodies.keys():
		set_body_collision_enabled(bramble_bodies[bid] as StaticBody2D, not GameState.cut_wilds_brambles.has(bid))
	if hollow_gate_body != null:
		set_body_collision_enabled(hollow_gate_body, not (gate_blown_clear or GameState.carrying_egg))

func get_ambience_track() -> String: return "wilds"
func get_lighting_tint() -> Color: return Color(0.50, 0.57, 0.69) if GameState.carrying_egg else Color(0.62, 0.68, 0.76)
func get_surface_at(pos: Vector2) -> String: return "cobble" if pos.distance_to(OUTPOST_POS) < 120.0 else "grass"

func update_region_lights(time_val: float) -> void:
	sync_light_frustum(wilds_lights, true, 24.0)
	for i in range(wilds_lights.size()):
		var wl: PointLight2D = wilds_lights[i]
		if wl.visible:
			wl.energy = (1.2 if i < 3 else (0.9 if i < 5 else 0.56)) + sin(time_val * 7.5 + float(i) * 2.1) * 0.12
	sync_light_frustum(hunter_lights, GameState.carrying_egg and GameState.current_step == GameState.QuestStep.ACT3_EGG_TREK, 24.0)

func _is_in_cold_zone(pos: Vector2) -> bool:
	for cz: Rect2 in cold_zones:
		if cz.has_point(pos): return true
	return false

func handle_region_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not player.winch_dash_active:
			var mouse_world: Vector2 = get_global_mouse_position()
			var click_canvas: Vector2 = get_canvas_transform().affine_inverse() * mb.position
			for post_info in [[GORGE_WINCH_E, "gorge"], [GORGE_WINCH_W, "gorge"], [CREEK_WINCH_S, "creek"], [CREEK_WINCH_N, "creek"]]:
				var wp: Vector2 = post_info[0]
				var wid: String = post_info[1]
				var target_pt: Vector2 = wp + Vector2(0, -12)
				if hovered_winch_pos == wp or mouse_world.distance_to(target_pt) <= 68.0 or click_canvas.distance_to(target_pt) <= 68.0:
					var near_e := GORGE_WINCH_E if wid == "gorge" else CREEK_WINCH_S
					var near_w := GORGE_WINCH_W if wid == "gorge" else CREEK_WINCH_N
					if player.position.distance_to(near_e) <= 360.0 or player.position.distance_to(near_w) <= 360.0:
						_cross_winch(wid)
						return true
					SoundManager.play_knot_snag()
					winch_hint_pos = wp
					winch_hint_timer = 1.15
					winch_reach_timer = 1.15
					_spawn_wilds_burst(wp + Vector2(0, -14), 8, Color(0.98, 0.86, 0.44), 18.0, 56.0, 0.55, 10.0)
					return true
	return false

func _cross_winch(crossing_id: String) -> void:
	var has_grapple := GameState.unlocked_knots.has("dragon_splice") or GameState.unlocked_knots.has("bruges_whipping") or GameState.unlocked_knots.has("bowline")
	if not has_grapple:
		SoundManager.play_knot_snag()
		winch_hint_pos = GORGE_WINCH_E if crossing_id == "gorge" else CREEK_WINCH_S
		winch_hint_timer = 0.95
		_spawn_wilds_burst(player.position + Vector2(0, -12), 10, Color(0.86, 0.66, 0.38), 28.0, 78.0, 0.50, 30.0)
		return
	if GameState.equipped_knot == "clove_hitch" and GameState.unlocked_knots.has("dragon_splice"):
		GameState.equipped_knot = "dragon_splice"
		GameState.emit_signal("state_updated")
	if crossing_id == "gorge":
		var go_west := player.position.x >= 490.0
		player.start_winch_dash(Vector2(342, 815) if go_west else Vector2(665, 845), GORGE_WINCH_W if go_west else GORGE_WINCH_E)
	else:
		if not GameState.black_dragon_found:
			SoundManager.play_knot_snag()
			winch_hint_pos = CREEK_WINCH_N
			winch_hint_timer = 1.10
			_spawn_wilds_burst(CREEK_WINCH_N + Vector2(0, -14), 10, Color(0.72, 0.78, 0.86), 22.0, 64.0, 0.55, 45.0)
			return
		var go_north := player.position.y >= 540.0
		player.start_winch_dash(Vector2(2145, 395) if go_north else Vector2(2155, 680), CREEK_WINCH_N if go_north else CREEK_WINCH_S)
	SoundManager.play_knot_cinch()


func step_region(delta: float) -> void:
	_step_nest_sparks(delta)
	_step_breath_fx(delta)
	_step_wilds_fx(delta)
	if crash_wakeup_timer > 0.0:
		crash_wakeup_timer = maxf(0.0, crash_wakeup_timer - delta)
		if crash_wakeup_timer == 0.0 and not dragon_cutscene_active and not breath_cutscene_active and player.cutscene_pose == "boy_kneel.png":
			player.set_cutscene_pose("")

	# Highlight clickable Winch Post on mouse hover
	var mouse_world := get_global_mouse_position()
	hovered_winch_pos = Vector2(-9999, -9999)
	for wp: Vector2 in [GORGE_WINCH_E, GORGE_WINCH_W, CREEK_WINCH_S, CREEK_WINCH_N]:
		if mouse_world.distance_to(wp + Vector2(0, -12)) <= 64.0:
			hovered_winch_pos = wp
			break

	if breath_cutscene_active:
		director.camera.position = director.camera.position.lerp(Vector2(382, 288), minf(1.0, delta * 4.2))
		director.camera.zoom = director.camera.zoom.lerp(Vector2(1.36, 1.36), minf(1.0, delta * 3.5))
		_process_dragon_breath_cutscene(delta)
		_redraw_world()
		return

	if dragon_cutscene_active:
		director.camera.position = director.camera.position.lerp(Vector2(262, 280), minf(1.0, delta * 3.8))
		director.camera.zoom = director.camera.zoom.lerp(Vector2(1.68, 1.68), minf(1.0, delta * 3.2))
		if not dragon_wait_dlg:
			_process_dragon_reveal_cutscene(delta)
		_redraw_world()
		return

	director.camera.zoom = director.camera.zoom.lerp(Vector2(1.5, 1.5), minf(1.0, delta * 4.5))
	var cam_target: Vector2 = player.position
	if flare_peek_timer > 0.0:
		var apex: Vector2 = flare_origin + FLARE_ASCENT_DELTA
		var peek_w: float = sin(clampf(flare_peek_timer / 2.05, 0.0, 1.0) * PI) * 0.42
		cam_target = player.position.lerp(apex, peek_w)
	director.camera.position = cam_target

	# Discover landmarks organically upon walking into each forest clearing
	for lm: Dictionary in landmarks:
		if player.position.distance_to(lm["pos"]) < 145.0:
			GameState.record_landmark(lm["id"], lm["title"])

	# Step ambient mist drift
	for mr: Dictionary in mist_ribbons:
		var p: Vector2 = mr["pos"]
		p.x += float(mr["drift"]) * delta
		if p.x > WORLD_W + 140.0:
			p.x = -140.0
		mr["pos"] = p

	# Patrol Hunters inside the Whispering Pines
	_process_hunter_patrols(delta)
	_step_signal_flare(delta)

	# Egg Warmth Survival & Watch-Fires
	if GameState.carrying_egg and GameState.current_step == GameState.QuestStep.ACT3_EGG_TREK and not ui.is_blocking_gameplay():
		var near_fire := false
		for fpos: Vector2 in [FIRE_0_POS, FIRE_ALPHA_POS, FIRE_BETA_POS]:
			if player.position.distance_to(fpos) < 82.0:
				near_fire = true
				GameState.last_safe_fire_pos = fpos
				if GameState.boy_hp < GameState.boy_max_hp:
					GameState.boy_hp = GameState.boy_max_hp
				if GameState.egg_warmth < 100.0:
					var was_cool := GameState.egg_warmth < 96.0
					GameState.egg_warmth = minf(100.0, GameState.egg_warmth + delta * 42.0)
					if was_cool:
						SoundManager.play_campfire_warm()
					ui.refresh_hud()
				break

		if not near_fire:
			var base_cool := 0.80 if (GameState.clara_gift_received or GameState.has_mariner_compass) else 1.20
			if _is_in_cold_zone(player.position):
				base_cool *= 2.85
			var prev_w := int(GameState.egg_warmth)
			GameState.egg_warmth = maxf(0.0, GameState.egg_warmth - delta * base_cool)
			if int(GameState.egg_warmth) != prev_w:
				ui.refresh_hud()
			if GameState.egg_warmth <= 0.0:
				GameState.egg_warmth = 80.0
				frost_reset_flash = 1.15
				SoundManager.play_dragon_cry()
				director.trigger_camera_shake(3.4, 0.25)
				ui.refresh_hud()
				ui.show_mission_failed_screen("The Black-Scaled Dragon Egg grew fatally cold in the frost! Hurry between sheltered watch-fires.", func():
					GameState.egg_warmth = 80.0
					player.position = GameState.last_safe_fire_pos + Vector2(0, 56)
					SoundManager.play_campfire_warm()
					_spawn_wilds_burst(player.position + Vector2(0, -8), 18, Color(1.0, 0.72, 0.28), 32.0, 105.0, 0.75, -18.0)
					ui.refresh_hud()
				)

	_redraw_world()


func _redraw_world() -> void:
	FrontierWildsDrawScript.step_layers(self)
	queue_redraw()
	if fg_canopy_node != null:
		fg_canopy_node.queue_redraw()


func _process_hunter_patrols(delta: float) -> void:
	var active := (GameState.carrying_egg and GameState.current_step == GameState.QuestStep.ACT3_EGG_TREK)
	alert_cooldown = maxf(0.0, alert_cooldown - delta)

	for i in range(hunter_patrols.size()):
		var hp: Dictionary = hunter_patrols[i]
		var hl: PointLight2D = hunter_lights[i]
		if not active:
			hl.energy = 0.0
			continue
		hl.energy = 0.85
		hp["alert"] = maxf(0.0, float(hp["alert"]) - delta)

		if not ui.is_blocking_gameplay():
			var a: Vector2 = hp["a"]
			var b: Vector2 = hp["b"]
			var base_dir := (b - a).normalized()
			if float(hp["pause"]) > 0.0:
				hp["pause"] = maxf(0.0, float(hp["pause"]) - delta)
			else:
				var nt := float(hp["t"]) + delta * float(hp["speed"]) * float(hp["dir_sign"])
				if nt >= 1.0:
					nt = 1.0
					hp["dir_sign"] = -1.0
					hp["pause"] = 1.25
				elif nt <= 0.0:
					nt = 0.0
					hp["dir_sign"] = 1.0
					hp["pause"] = 1.25
				hp["t"] = nt
			hp["pos"] = a.lerp(b, float(hp["t"]))
			hp["dir"] = base_dir * float(hp["dir_sign"])
		hl.position = hp["pos"] + Vector2(hp["dir"]).normalized() * 24.0

		var in_beam := false
		if alert_cooldown <= 0.0 and not ui.is_blocking_gameplay() and not player.is_invulnerable() and not player.winch_dash_active:
			var h_eye: Vector2 = Vector2(hp["pos"]) + Vector2(0, -6)
			var p_eye: Vector2 = player.position + Vector2(0, -6)
			var h_dir: Vector2 = Vector2(hp["dir"]).normalized()
			if can_vision_cone_see(h_eye, h_dir, p_eye, 136.0, deg_to_rad(32.0), sight_blockers, 24.0):
				var dist: float = h_eye.distance_to(p_eye)
				in_beam = true
				var rate := 3.4 if dist < 44.0 else 1.75
				hp["suspicion"] = minf(1.0, float(hp["suspicion"]) + delta * rate)
				if float(hp["suspicion"]) >= 1.0:
					for h_rst: Dictionary in hunter_patrols:
						h_rst["suspicion"] = 0.0
						h_rst["pause"] = 1.0
					alert_cooldown = 2.6
					hp["alert"] = 1.8
					SoundManager.play_alert_horn()
					director.trigger_camera_shake(6.0, 0.28)
					player.trigger_hurt_flash()
					GameState.boy_hp = maxi(0, GameState.boy_hp - 1)
					GameState.egg_warmth = maxf(24.0, GameState.egg_warmth - 18.0)
					GameState.emit_signal("state_updated")
					frost_reset_flash = 0.85
					ui.refresh_hud()
					if GameState.boy_hp <= 0:
						ui.show_death_screen("Cornered and taken down by Church Hunter Scouts in the Whispering Pines.", func():
							GameState.boy_hp = GameState.boy_max_hp
							GameState.egg_warmth = 80.0
							player.position = GameState.last_safe_fire_pos + Vector2(0, 52)
							GameState.emit_signal("state_updated")
							ui.refresh_hud()
						)
						return
					ui.show_mission_failed_screen("Spotted by a Church Hunter Scout's vision cone! Stay out of their sightlines in the pines. (%d/%d HP left)" % [GameState.boy_hp, GameState.boy_max_hp], func():
						GameState.egg_warmth = maxf(GameState.egg_warmth, 62.0)
						player.position = GameState.last_safe_fire_pos + Vector2(0, 52)
						_spawn_wilds_burst(player.position, 14, Color(0.88, 0.34, 0.28), 35.0, 110.0, 0.65, 35.0)
						ui.refresh_hud()
					)
					return
		if not in_beam:
			hp["suspicion"] = maxf(0.0, float(hp["suspicion"]) - delta * 2.1)


func on_knife_slash(tip_pos: Vector2, _dir: Vector2) -> void:
	for b_info in [["bramble_west", BRAMBLE_WEST_POS], ["bramble_shortcut", BRAMBLE_SHORTCUT_POS]]:
		var bid: String = b_info[0]
		var bpos: Vector2 = b_info[1]
		if not GameState.cut_wilds_brambles.has(bid) and tip_pos.distance_to(bpos) <= 84.0:
			GameState.cut_wilds_brambles.append(bid)
			_sync_dynamic_gates()
			SoundManager.play_hit()
			SoundManager.play_knot_cinch()
			director.trigger_camera_shake(2.2, 0.14)
			_spawn_wilds_burst(bpos, 16, Color(0.32, 0.48, 0.22), 40.0, 128.0, 0.72, 95.0)
			_spawn_wilds_burst(bpos + Vector2(0, 10), 10, Color(0.42, 0.26, 0.14), 30.0, 96.0, 0.62, 110.0)
			return


func on_rope_cast_hit(tip_pos: Vector2, _knot_id: String) -> void:
	for gp: Vector2 in [GORGE_WINCH_W, GORGE_WINCH_E]:
		var seg_cp: Vector2 = Geometry2D.get_closest_point_to_segment(gp, player.position, tip_pos)
		if tip_pos.distance_to(gp) <= 115.0 or seg_cp.distance_to(gp) <= 58.0:
			_cross_winch("gorge")
			return
	for cp_post: Vector2 in [CREEK_WINCH_N, CREEK_WINCH_S]:
		var seg_cp2: Vector2 = Geometry2D.get_closest_point_to_segment(cp_post, player.position, tip_pos)
		if tip_pos.distance_to(cp_post) <= 115.0 or seg_cp2.distance_to(cp_post) <= 58.0:
			_cross_winch("creek")
			return


func is_interactable_active(id: String) -> bool:
	if dragon_cutscene_active or breath_cutscene_active or _outpost_fading:
		return false
	match id:
		"wilds_tracks": return not GameState.wilds_clue_tracks
		"wilds_clue": return not GameState.wilds_clue_scorched_pine
		"wilds_black_dragon": return not GameState.black_dragon_found
		"wilds_egg_nest": return GameState.black_dragon_found and not GameState.carrying_egg
		"hollow_gate": return not GameState.carrying_egg
		"wilds_outpost": return GameState.carrying_egg
		_: return true


func get_interact_bubble_offset(id: String) -> Vector2:
	return Vector2(0, -130) if id == "wilds_outpost" else (Vector2(0, -84) if id == "wilds_black_dragon" else Vector2(0, -48))

func _on_inspect_hollow_gate() -> void:
	gate_rattle_timer = 0.85
	SoundManager.play_knot_snag()
	director.trigger_camera_shake(2.0, 0.16)
	_spawn_wilds_burst(HOLLOW_GATE_POS + Vector2(0, -10), 10, Color(0.36, 0.24, 0.14), 24.0, 76.0, 0.65, 85.0)
	if GameState.black_dragon_found and not GameState.carrying_egg:
		SoundManager.play_dragon_purr()
		_spawn_nest_sparks(EGG_NEST_POS + Vector2(0, -8), 12)

func _on_interact_tracks() -> void:
	GameState.wilds_clue_tracks = true
	player.set_cutscene_pose("boy_kneel.png")
	crash_wakeup_timer = 0.85
	SoundManager.play_journal()
	_spawn_wilds_burst(CLUE_TRACKS_POS + Vector2(18, -12), 14, Color(0.24, 0.22, 0.28), 28.0, 82.0, 0.75, 10.0)
	_spawn_wilds_burst(CLUE_TRACKS_POS + Vector2(0, -8), 6, Color(0.96, 0.84, 0.42), 16.0, 52.0, 0.85, -12.0)

func _on_interact_wilds_clue() -> void:
	GameState.wilds_clue_scorched_pine = true
	GameState.has_forest_map = true
	GameState.add_item("Brotherhood Border Survey Map")
	player.set_cutscene_pose("boy_kneel.png")
	crash_wakeup_timer = 1.15
	player.show_held_item(assets.get_tex("icon_map.png"), 1.35)
	SoundManager.play_chime()
	_spawn_wilds_burst(CLUE_CART_POS + Vector2(0, -12), 12, Color(0.96, 0.84, 0.42), 24.0, 72.0, 0.72, -10.0)
	ui.refresh_hud()
	ui.pulse_hud_icon("map")

func _on_interact_black_dragon() -> void:
	if not dragon_cutscene_active and not GameState.black_dragon_found: _start_dragon_reveal_cutscene()

func _start_dragon_reveal_cutscene() -> void:
	dragon_cutscene_active = true
	dragon_stage = 0
	dragon_t = 0.0
	dragon_wait_dlg = false
	dragon_wing_revealed = false
	dragon_visual_state = "dying"
	egg_reveal_offset = Vector2(-34, -18)
	GameState.black_dragon_found = false
	player.facing = Vector2.LEFT
	player.set_cutscene_pose("boy_knife_0.png")
	ui.set_cinematic_mode(true, _skip_dragon_reveal_cutscene)
	SoundManager.play_dragon_cry()

func _spawn_nest_sparks(origin: Vector2, count: int) -> void:
	for _i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(18.0, 56.0)
		nest_sparks.append({"pos": origin, "vel": Vector2(cos(ang), sin(ang) - 0.4) * spd, "t": randf_range(0.45, 0.8)})

func _step_nest_sparks(delta: float) -> void:
	for i in range(nest_sparks.size() - 1, -1, -1):
		var sp: Dictionary = nest_sparks[i]
		sp["t"] = float(sp["t"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		if float(sp["t"]) <= 0.0: nest_sparks.remove_at(i)

func _step_signal_flare(delta: float) -> void:
	if not flare_active:
		if GameState.black_dragon_found and GameState.carrying_egg and not GameState.wilds_signal_flare_seen and not ui.is_blocking_gameplay() and player.position.x >= 625.0 and player.position.x <= 1220.0 and player.position.y <= 520.0:
			GameState.wilds_signal_flare_seen = true
			flare_active = true
			flare_t = 0.0
			flare_burst_done = false
			flare_sparks.clear()
			flare_origin = player.position + Vector2(215.0, -48.0)
			flare_peek_timer = 2.05
			SoundManager.play_rope()
		return
	flare_t += delta
	if flare_t >= 0.78 and not flare_burst_done:
		flare_burst_done = true
		var apex: Vector2 = flare_origin + FLARE_ASCENT_DELTA
		for i in range(22):
			var ang := (TAU / 22.0) * float(i) + randf_range(-0.14, 0.14)
			var spd := randf_range(34.0, 96.0)
			var spark_col := Color(0.94, 0.90, 0.44) if (i % 4 == 0) else Color(0.46, 1.0, 0.66)
			flare_sparks.append({"pos": apex, "vel": Vector2(cos(ang), sin(ang) * 0.85) * spd, "t": randf_range(1.5, 2.2), "col": spark_col})
		SoundManager.play_chime()
		_spawn_wilds_burst(apex, 10, Color(0.54, 1.0, 0.72), 45.0, 120.0, 0.85, 8.0)
	for i in range(flare_sparks.size() - 1, -1, -1):
		var sp: Dictionary = flare_sparks[i]
		sp["t"] = float(sp["t"]) - delta
		var v: Vector2 = Vector2(sp["vel"])
		v.y += 26.0 * delta
		v *= (1.0 - minf(0.5, delta * 0.9))
		sp["vel"] = v
		sp["pos"] = Vector2(sp["pos"]) + v * delta
		if float(sp["t"]) <= 0.0: flare_sparks.remove_at(i)
	if flare_t >= 3.35 and flare_sparks.is_empty(): flare_active = false


func _process_dragon_reveal_cutscene(delta: float) -> void:
	dragon_t += delta
	match dragon_stage:
		0:
			player.facing = Vector2.LEFT
			player.position = player.position.move_toward(Vector2(304, 290), delta * 62.0)
			if dragon_t >= 1.45:
				dragon_stage = 1
				dragon_t = 0.0
				SoundManager.play_dragon_purr()
		1:
			if dragon_t >= 0.25 and not dragon_wing_revealed:
				dragon_wing_revealed = true
				dragon_visual_state = "reveal"
				player.set_cutscene_pose("")
				SoundManager.play_campfire_warm()
				_spawn_nest_sparks(EGG_NEST_POS + Vector2(-12, -6), 14)
			egg_reveal_offset = egg_reveal_offset.lerp(Vector2.ZERO, minf(1.0, delta * 3.0))
			player.position = player.position.move_toward(Vector2(298, 296), delta * 20.0)
			if dragon_t >= 2.25:
				dragon_stage = 2
				dragon_t = 0.0
				dragon_visual_state = "dying"
				egg_reveal_offset = Vector2.ZERO
				player.set_cutscene_pose("boy_kneel.png")
				SoundManager.play_dragon_cry()
				director.trigger_camera_shake(2.6, 0.24)
		2:
			if int(dragon_t * 3.0) > int((dragon_t - delta) * 3.0):
				_spawn_nest_sparks(EGG_NEST_POS + Vector2(-4, -4), 3)
			if dragon_t >= 1.65:
				_finish_dragon_reveal_cutscene()


func _finish_dragon_reveal_cutscene() -> void:
	dragon_cutscene_active = false
	dragon_wait_dlg = false
	dragon_visual_state = "dead" if gate_blown_clear else "dying"
	egg_reveal_offset = Vector2.ZERO
	GameState.black_dragon_found = true
	player.position = Vector2(304, 294)
	player.facing = Vector2.LEFT
	player.set_cutscene_pose("")
	ui.set_cinematic_mode(false)
	ui.refresh_hud()


func _skip_dragon_reveal_cutscene() -> void:
	_finish_dragon_reveal_cutscene()


func _on_pickup_dragon_egg() -> void:
	if GameState.carrying_egg:
		return
	GameState.carrying_egg = true
	GameState.has_forest_map = true
	GameState.current_step = GameState.QuestStep.ACT3_EGG_TREK
	GameState.egg_warmth = 100.0
	GameState.add_item("Black-Scaled Dragon Egg")
	gate_blown_clear = false
	_sync_dynamic_gates()
	player.facing = Vector2.RIGHT
	player.set_cutscene_pose("boy_kneel.png")
	player.show_held_item(assets.get_tex("prop_dragon_egg_held.png"), 2.0)
	SoundManager.play_knot_cinch()
	SoundManager.play_dragon_purr()
	ui.refresh_hud()
	breath_cutscene_active = true
	breath_t = 0.0
	breath_gust_done = false
	dragon_visual_state = "breath"
	ui.set_cinematic_mode(true, _skip_dragon_breath_cutscene)


func _process_dragon_breath_cutscene(delta: float) -> void:
	breath_t += delta
	if breath_t < 0.42 and randf() < delta * 26.0:
		_spawn_nest_sparks(BLACK_DRAGON_POS + Vector2(68, 12) + Vector2(randf_range(-10.0, 12.0), randf_range(-10.0, 10.0)), 1)
	if breath_t >= 0.42 and not breath_gust_done:
		_trigger_dragon_breath_blast()
	if breath_t >= 1.55 and dragon_visual_state != "dead":
		dragon_visual_state = "dead"
	if breath_t >= 1.95:
		_finish_dragon_breath_cutscene()


func _trigger_dragon_breath_blast() -> void:
	breath_gust_done = true
	gate_blown_clear = true
	_sync_dynamic_gates()
	SoundManager.play_dragon_cry()
	SoundManager.play_cage_break()
	director.trigger_camera_shake(4.4, 0.46)
	var mouth := BLACK_DRAGON_POS + Vector2(62, 6)
	for i in range(28):
		var spread := randf_range(-0.14, 0.24)
		var spd := randf_range(520.0, 820.0)
		var is_ember := (i % 3 == 0)
		breath_streaks.append({"pos": mouth + Vector2(randf_range(0.0, 42.0), randf_range(-10.0, 14.0)), "vel": Vector2(cos(spread), sin(spread)) * spd, "len": randf_range(8.0, 18.0) if is_ember else randf_range(26.0, 56.0), "h": 4.0 if is_ember else 3.0, "col": Color(0.98, 0.72, 0.26, 0.92) if is_ember else Color(0.84, 0.92, 0.96, 0.78), "t": 0.65, "max_t": 0.65})
	var gate_c := Vector2(532, 306)
	for j in range(18):
		var col_d := Color(0.32, 0.20, 0.10) if j % 3 != 0 else (Color(0.24, 0.42, 0.18) if j % 2 == 0 else Color(0.46, 0.48, 0.52))
		blown_debris.append({"pos": gate_c + Vector2(randf_range(-16.0, 16.0), randf_range(-20.0, 20.0)), "vel": Vector2(randf_range(160.0, 340.0), randf_range(-125.0, 95.0)), "rot": randf_range(0.0, TAU), "vrot": randf_range(-11.0, 11.0), "sz": randf_range(6.0, 12.0), "col": col_d, "t": 1.15, "max_t": 1.15})

func _step_breath_fx(delta: float) -> void:
	for i in range(breath_streaks.size() - 1, -1, -1):
		var bs: Dictionary = breath_streaks[i]
		bs["pos"] = Vector2(bs["pos"]) + Vector2(bs["vel"]) * delta
		bs["t"] = float(bs["t"]) - delta
		if float(bs["t"]) <= 0.0: breath_streaks.remove_at(i)
	for i in range(blown_debris.size() - 1, -1, -1):
		var db: Dictionary = blown_debris[i]
		var vel := Vector2(db["vel"])
		vel.x *= maxf(0.0, 1.0 - delta * 1.4)
		vel.y += 185.0 * delta
		db["vel"] = vel
		db["pos"] = Vector2(db["pos"]) + vel * delta
		db["rot"] = float(db["rot"]) + float(db["vrot"]) * delta
		db["t"] = float(db["t"]) - delta
		if float(db["t"]) <= 0.0: blown_debris.remove_at(i)

func _finish_dragon_breath_cutscene() -> void:
	if not breath_cutscene_active: return
	breath_cutscene_active = false
	if not breath_gust_done: _trigger_dragon_breath_blast()
	gate_blown_clear = true
	dragon_visual_state = "dead"
	_sync_dynamic_gates()
	player.set_cutscene_pose("")
	ui.set_cinematic_mode(false)
	ui.refresh_hud()
	ui.pulse_hud_icon("map")
	_spawn_wilds_burst(player.position + Vector2(0, -10), 12, Color(0.98, 0.80, 0.34), 22.0, 68.0, 0.72, -14.0)

func _skip_dragon_breath_cutscene() -> void:
	_finish_dragon_breath_cutscene()

func _on_reach_frontier_outpost() -> void:
	if not GameState.carrying_egg or _outpost_fading: return
	GameState.current_step = GameState.QuestStep.BOOK1_WATCHTOWER_HEARTH
	SoundManager.play_chime()
	ui.show_dialogue([
		{"speaker": "Anna", "portrait": "portrait_anna.png", "text": "%s? We swept three ridges searching every fern brake for your coat—wait. What are you cradling inside your sling?" % GameState.player_name},
		{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Don't look at me like I turned soft on beasts. Church bolts crippled the black one out in the hollow—I just wasn't leaving a live thing in the dirt to freeze."},
		{"speaker": "Anna", "portrait": "portrait_anna.png", "text": "Black-scaled...? Bring it inside by the stone hearth before the chill settles through the shell. Tomorrow we talk."}
	], func():
		_outpost_fading = true
		ui.set_fade(1.0, false)
		get_tree().create_timer(0.55).timeout.connect(func():
			if is_inside_tree(): director.load_region("hearth", {})
		)
	)

func get_active_npc_colliders() -> Array:
	var list: Array = [{"pos": BLACK_DRAGON_POS, "offset": Vector2.ZERO, "radius": 42.0}]
	if GameState.black_dragon_found: list.append(OUTPOST_POS + Vector2(-42, 34))
	if GameState.carrying_egg and GameState.current_step == GameState.QuestStep.ACT3_EGG_TREK:
		for hp: Dictionary in hunter_patrols: list.append(Vector2(hp["pos"]))
	return list

func _spawn_wilds_burst(origin: Vector2, count: int, col: Color, spd_min: float = 24.0, spd_max: float = 84.0, life: float = 0.65, grav: float = 40.0) -> void:
	for _i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(spd_min, spd_max)
		wilds_fx_particles.append({"pos": origin + Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0)), "vel": Vector2(cos(ang), sin(ang) * 0.85) * spd, "col": col, "t": life * randf_range(0.65, 1.05), "max_t": life, "grav": grav, "sz": randf_range(2.5, 4.5)})

func _step_wilds_fx(delta: float) -> void:
	winch_hint_timer = maxf(0.0, winch_hint_timer - delta)
	winch_reach_timer = maxf(0.0, winch_reach_timer - delta)
	gate_rattle_timer = maxf(0.0, gate_rattle_timer - delta)
	flare_peek_timer = maxf(0.0, flare_peek_timer - delta)
	frost_reset_flash = maxf(0.0, frost_reset_flash - delta)
	for i in range(wilds_fx_particles.size() - 1, -1, -1):
		var fp: Dictionary = wilds_fx_particles[i]
		fp["t"] = float(fp["t"]) - delta
		var v: Vector2 = Vector2(fp["vel"])
		v.y += float(fp["grav"]) * delta
		fp["vel"] = v
		fp["pos"] = Vector2(fp["pos"]) + v * delta
		if float(fp["t"]) <= 0.0: wilds_fx_particles.remove_at(i)

func _draw() -> void: FrontierWildsDrawScript.draw_world(self)

class ForestForegroundLayer extends Node2D:
	var region
	func _draw() -> void:
		if region != null: FrontierWildsDrawScript.draw_foreground(self, region)
