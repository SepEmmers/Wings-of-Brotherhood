extends "res://scripts/regions/RegionBase.gd"

## Chapter 4 Walled City of Bruges (2880x2160):
## 7 districts, stone canal bridges, winch crossings, townsfolk intelligence gathering,
## tactical real-time Catchpole & Arbalester combat (shield blocking + rope-snare + dodge counters),
## Father Anselm shadow-tailing mission with backward glances & cover zones,
## and the Keep Courtyard Inquisitor bounty revelation.

const BrugesCityMapDataScript := preload("res://scripts/regions/BrugesCityMapData.gd")
const BrugesCityDrawScript := preload("res://scripts/regions/BrugesCityDraw.gd")
const PlayerCombatHelperScript := preload("res://scripts/systems/PlayerCombatHelper.gd")

const NPC_JORIS_POS := Vector2(1448, 1210)
const NPC_BEATRIJS_POS := Vector2(2288, 1360)
const WAGON_CLUE_POS := Vector2(592, 1392)
const DROPPED_NOTE_POS := Vector2(616, 1446)
const CHURCH_HIDING_POS := Vector2(2084, 404)
const PRIEST_START_POS := Vector2(2240, 492)
const INQUISITOR_POS := Vector2(496, 496)
const SOUTH_GATE_EXIT_POS := Vector2(1440, 2016)
const EAST_OUTSKIRTS_GATE_POS := Vector2(2736, 1304)

var static_colliders: Array[Rect2] = []
var sight_blockers: Array[Rect2] = []
var city_evening_time: bool = false
var city_lights: Array[PointLight2D] = []
const BrugesCityBoatsScript := preload("res://scripts/regions/BrugesCityBoats.gd")
const GROTE_MARKT_OVEN_POS := Vector2(1048, 1132)
const CATHEDRAL_BELL_POS := Vector2(2256, 186)
var bell_wave_rings: Array[Dictionary] = []
var oven_crackle_cooldown: float = 0.0
var boat_interactable_item: Dictionary = {}

var lantern_positions: Array[Vector2] = [
	Vector2(1372, 1924), Vector2(1508, 1924), Vector2(1440, 1740), Vector2(1296, 1340), Vector2(1584, 1340), Vector2(1152, 1216),
	Vector2(1744, 1216), Vector2(1936, 1296), Vector2(1072, 1280), Vector2(864, 1280), Vector2(544, 1312), Vector2(744, 1616),
	Vector2(1664, 960), Vector2(1664, 528), Vector2(1120, 496), Vector2(896, 496), Vector2(544, 496), Vector2(356, 444),
	Vector2(2144, 504), Vector2(2368, 504), Vector2(2256, 944), Vector2(2236, 1304),
]

var townsfolk_states: Array[Dictionary] = []

var enemies: Array[Dictionary] = []
var enemy_bolts: Array[Dictionary] = []
var combat_sparks: Array[Dictionary] = []
var current_encounter: String = ""

var priest_route: Array[Vector2] = []
var priest_wp_idx: int = 1
var priest_pos: Vector2 = PRIEST_START_POS
var priest_dir: Vector2 = Vector2.LEFT
var priest_look_dir: Vector2 = Vector2.LEFT
var priest_base_look_dir: Vector2 = Vector2.LEFT
var priest_tail_active: bool = false
var priest_state: String = "walk"
var priest_state_timer: float = 3.8
var city_cam_focus_pos: Vector2 = Vector2.ZERO
var city_cam_focus_t: float = 0.0
var eavesdrop_scrape_t: float = 0.0

func _ready() -> void:
	static_colliders = BrugesCityMapDataScript.get_static_colliders()
	sight_blockers = BrugesCityMapDataScript.get_sight_blockers()
	colliders = StaticBody2D.new()
	add_child(colliders)
	for crect: Rect2 in static_colliders:
		add_box_collider(colliders, crect)
	setup_navigation_grid(Rect2(Vector2.ZERO, BrugesCityMapDataScript.WORLD_SIZE), static_colliders, 10.0, 20.0)

	for lp: Vector2 in lantern_positions:
		var pl: PointLight2D = assets.make_point_light(lp + Vector2(0, -10), 2.5, Color(1.0, 0.78, 0.42), 0.72)
		add_child(pl)
		city_lights.append(pl)

	BrugesCityDrawScript.setup_layers(self)
	priest_route = BrugesCityMapDataScript.get_priest_route()
	_init_townsfolk_states()
	BrugesCityBoatsScript.init_boats(self)
	bell_wave_rings.clear()
	oven_crackle_cooldown = 0.0

	interactables = [
		{"id": "city_joris", "name": "Cloth-Factor Joris", "pos": NPC_JORIS_POS, "radius": 74.0, "callback": _on_interact_joris},
		{"id": "city_beatrijs", "name": "Sister Beatrijs (Apothecary)", "pos": NPC_BEATRIJS_POS, "radius": 74.0, "callback": _on_interact_beatrijs},
		{"id": "city_wagon_recon", "name": "Inspect Church Iron-Chain Wagon", "pos": WAGON_CLUE_POS, "radius": 84.0, "callback": _on_interact_wagon},
		{"id": "city_dropped_note", "name": "Dropped Note", "pos": DROPPED_NOTE_POS, "radius": 72.0, "callback": _on_interact_dropped_note},
		{"id": "city_church_wait", "name": "Sit Behind Pulpit & Wait Until Eighth Bell", "pos": CHURCH_HIDING_POS, "radius": 86.0, "callback": _on_interact_church_wait},
		{"id": "city_south_sign", "name": "Read South Gate Sign", "pos": Vector2(1352, 1986), "radius": 62.0, "callback": _on_read_south_gate_sign},
		{"id": "city_east_sign", "name": "Read East Gate Sign", "pos": Vector2(2644, 1236), "radius": 62.0, "callback": _on_read_east_gate_sign},
	]
	clear_walk_portals()
	register_walk_portal("city_south_exit", Rect2(1386, 1996, 108, 72), Vector2.DOWN, _on_interact_south_exit, "v Port of Bruges", "PORT OF BRUGES", "North City Gate")
	register_walk_portal("city_east_exit", Rect2(2768, 1258, 96, 92), Vector2.RIGHT, _on_enter_east_outskirts, "Toward Bruges Outskirts ->", "BRUGES OUTSKIRTS", "East Causeway")
	for ti in range(townsfolk_states.size()):
		var tf: Dictionary = townsfolk_states[ti]
		var idx: int = ti
		interactables.append({"id": String(tf["id"]), "name": String(tf["name"]), "pos": Vector2(tf["pos"]), "radius": 62.0, "tf_state_idx": idx, "callback": func(): _on_interact_townsfolk(idx)})
	var pairs := BrugesCityMapDataScript.get_winch_pairs()
	for pi in range(pairs.size()):
		var pr: Dictionary = pairs[pi]
		interactables.append({"id": "city_winch_%dw" % pi, "name": "Canal Winch Post ([Click / E / F])", "pos": Vector2(pr["west"]), "radius": 68.0, "callback": func(): _try_winch_pair(pi, true)})
		interactables.append({"id": "city_winch_%de" % pi, "name": "Canal Winch Post ([Click / E / F])", "pos": Vector2(pr["east"]), "radius": 68.0, "callback": func(): _try_winch_pair(pi, false)})
	BrugesCityBoatsScript.init_boats(self)
	boat_interactable_item = {"id": "city_boat_hop", "name": "Hop Aboard", "pos": Vector2(-9999, -9999), "radius": 68.0, "callback": func(): BrugesCityBoatsScript.try_hop(self)}
	interactables.append(boat_interactable_item)


func enter_region(opts: Dictionary = {}) -> void:
	GameState.current_step = GameState.QuestStep.ACT4_BRUGES_CITY
	GameState.carrying_egg = false
	GameState.boy_hp = GameState.boy_max_hp

	enemies.clear()
	enemy_bolts.clear()
	combat_sparks.clear()
	current_encounter = ""
	city_evening_time = bool(opts.get("start_priest_tail", false))
	priest_tail_active = false
	priest_pos = PRIEST_START_POS
	priest_dir = Vector2.LEFT
	priest_look_dir = Vector2.LEFT
	priest_base_look_dir = Vector2.LEFT
	priest_wp_idx = 1
	priest_state = "walk"
	priest_state_timer = 3.8
	_init_townsfolk_states()
	BrugesCityBoatsScript.init_boats(self)
	bell_wave_rings.clear()
	oven_crackle_cooldown = 0.0

	player.position = opts.get("spawn", SOUTH_GATE_EXIT_POS + Vector2(0, -56))
	player.facing = opts.get("facing", Vector2.UP)
	player.visible = true
	player.can_move = true

	var cam: Camera2D = director.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(BrugesCityMapDataScript.WORLD_SIZE.x)
	cam.limit_bottom = int(BrugesCityMapDataScript.WORLD_SIZE.y)
	cam.zoom = Vector2(1.4, 1.4)
	cam.position = player.position

	step_water_layer()
	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.refresh_hud()

	city_cam_focus_t = 0.0
	eavesdrop_scrape_t = 0.0
	if bool(opts.get("start_priest_tail", false)):
		_begin_priest_tail()
	elif not bool(opts.get("skip_intro", false)):
		city_cam_focus_pos = NPC_JORIS_POS
		city_cam_focus_t = 0.85
		SoundManager.play_ship_bell()


func exit_region() -> void:
	BrugesCityBoatsScript.reset_player_boat_state(self)
	city_cam_focus_t = 0.0
	eavesdrop_scrape_t = 0.0
	if director != null and director.camera != null: director.camera.zoom = Vector2(1.5, 1.5)


func get_default_camera_zoom() -> Vector2:
	return Vector2(1.4, 1.4)

func get_ambience_track() -> String:
	if _has_living_enemies():
		return "combat"
	if priest_tail_active:
		return "stealth"
	return "harbor"
func get_surface_at(_pos: Vector2) -> String: return "wood" if BrugesCityBoatsScript.get_boarded_idx(self) >= 0 else "cobble"
func get_lighting_tint() -> Color: return Color(0.68, 0.70, 0.84) if (city_evening_time or priest_tail_active or GameState.city_bounty_overheard) else Color(0.84, 0.80, 0.78)

func update_region_lights(time_val: float) -> void:
	sync_light_frustum(city_lights, true, 24.0)
	for i in range(city_lights.size()):
		var pl: PointLight2D = city_lights[i]
		if pl.visible: pl.energy = 0.72 + sin(time_val * 3.4 + float(i) * 1.5) * 0.08


func get_interactable_pos(item: Dictionary) -> Vector2:
	var iid: String = String(item.get("id", ""))
	if iid == "city_boat_hop":
		var cand: Dictionary = BrugesCityBoatsScript.find_hop_candidate(self)
		if bool(cand.get("valid", false)):
			boat_interactable_item["name"] = String(cand.get("label", "Hop Aboard")).replace("[E] ", "")
			return Vector2(cand["target_pos"])
		return Vector2(-9999, -9999)
	if iid == "city_joris": return get_npc_yield_pos("city_joris", NPC_JORIS_POS, 34.0, 12.0)
	if iid == "city_beatrijs": return get_npc_yield_pos("city_beatrijs", NPC_BEATRIJS_POS, 34.0, 12.0)
	var tf_idx: int = int(item.get("tf_state_idx", -1))
	if tf_idx >= 0 and tf_idx < townsfolk_states.size():
		var tf: Dictionary = townsfolk_states[tf_idx]
		return get_npc_yield_pos(String(tf["id"]), Vector2(tf["pos"]), 34.0, 13.0)
	return Vector2(item.get("pos", Vector2.ZERO))

func get_interact_bubble_offset(id: String) -> Vector2:
	return Vector2(0, -32) if id == "city_boat_hop" else Vector2(0, -44)

func is_interactable_active(id: String) -> bool:
	if id == "city_boat_hop":
		return not ui.is_blocking_gameplay() and bool(BrugesCityBoatsScript.find_hop_candidate(self).get("valid", false))
	if _has_living_enemies(): return false
	if id.begins_with("tf_") and priest_tail_active: return false
	if id in ["city_south_exit", "city_east_exit"]: return not priest_tail_active
	match id:
		"city_wagon_recon": return not GameState.city_watergate_skirmish_won and not GameState.city_clue_counting_house
		"city_dropped_note": return GameState.city_watergate_skirmish_won and not GameState.city_clue_counting_house
		"city_church_wait": return GameState.city_clue_counting_house and not priest_tail_active and not GameState.city_bounty_overheard
		_: return true

func step_region(delta: float) -> void:
	city_cam_focus_t = maxf(0.0, city_cam_focus_t - delta)
	var cam_target: Vector2 = player.position
	if city_cam_focus_t > 0.0:
		var pan_w := sin(clampf(city_cam_focus_t / 1.35, 0.0, 1.0) * PI) * 0.62
		cam_target = player.position.lerp(city_cam_focus_pos, pan_w)
	director.camera.position = cam_target
	step_water_layer()
	_step_sparks(delta)
	_step_bolts(delta)

	if eavesdrop_scrape_t > 0.0:
		eavesdrop_scrape_t = maxf(0.0, eavesdrop_scrape_t - delta)
		if eavesdrop_scrape_t <= 0.0:
			_finish_bounty_eavesdrop()

	if not ui.is_blocking_gameplay():
		BrugesCityBoatsScript.step_boats(self, delta)
		_step_townsfolk(delta)
	var hop_cand: Dictionary = BrugesCityBoatsScript.find_hop_candidate(self)
	if bool(hop_cand.get("valid", false)):
		boat_interactable_item["name"] = String(hop_cand.get("label", "Hop Aboard")).replace("[E] ", "")
		boat_interactable_item["pos"] = Vector2(hop_cand.get("target_pos", Vector2.ZERO))
	# Age acoustic bell wave rings radiating from St. Donatian's bell-gable
	for bi in range(bell_wave_rings.size() - 1, -1, -1):
		var br: Dictionary = bell_wave_rings[bi]
		br["age"] = float(br.get("age", 0.0)) + delta
		if float(br["age"]) >= float(br.get("max_age", 2.2)):
			bell_wave_rings.remove_at(bi)
	# Warm oven crackle near Grote Markt Bakery Brick Oven
	oven_crackle_cooldown = maxf(0.0, oven_crackle_cooldown - delta)
	if oven_crackle_cooldown <= 0.0 and player != null and player.position.distance_to(GROTE_MARKT_OVEN_POS) <= 135.0 and not ui.is_blocking_gameplay():
		SoundManager.play_oven_crackle()
		oven_crackle_cooldown = randf_range(2.6, 4.0)
	if priest_tail_active and not ui.is_blocking_gameplay():
		_step_priest_tail(delta)
	if _has_living_enemies() and not ui.is_blocking_gameplay():
		_step_enemies(delta)

	queue_redraw()
	queue_foreground_redraw()


func _has_living_enemies() -> bool:
	for e: Dictionary in enemies:
		if int(e["hp"]) > 0: return true
	return false

func handle_region_input(event: InputEvent) -> bool:
	if BrugesCityBoatsScript.is_hopping(self): return true
	if ui.is_blocking_gameplay(): return false
	if event.is_action_pressed("dodge") and (BrugesCityBoatsScript.is_aboard_or_hopping(self) or not _has_living_enemies()):
		if BrugesCityBoatsScript.try_hop(self): return true
	if _has_living_enemies(): return false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not player.winch_dash_active:
			var mouse_world: Vector2 = get_global_mouse_position()
			var pairs := BrugesCityMapDataScript.get_winch_pairs()
			for pi in range(pairs.size()):
				var pr: Dictionary = pairs[pi]
				var wpt: Vector2 = Vector2(pr["west"])
				var ept: Vector2 = Vector2(pr["east"])
				if (mouse_world.distance_to(wpt) <= 58.0 or mouse_world.distance_to(ept) <= 58.0) and (player.position.distance_to(wpt) <= 220.0 or player.position.distance_to(ept) <= 220.0):
					_try_winch_pair(pi, player.position.distance_to(wpt) < player.position.distance_to(ept))
					return true
	return false


func _try_winch_pair(idx: int, from_west: bool) -> void:
	if _has_living_enemies():
		return
	var pairs := BrugesCityMapDataScript.get_winch_pairs()
	if idx < 0 or idx >= pairs.size():
		return
	var pr: Dictionary = pairs[idx]
	var wpt: Vector2 = Vector2(pr["west"])
	var ept: Vector2 = Vector2(pr["east"])
	var dest: Vector2 = ept + Vector2(36, 0) if idx == 0 else ept + Vector2(0, 36)
	if not from_west:
		dest = wpt - Vector2(36, 0) if idx == 0 else wpt - Vector2(0, 36)
	var anchor: Vector2 = ept if from_west else wpt
	if GameState.equipped_knot != "dragon_splice" and GameState.unlocked_knots.has("dragon_splice"):
		GameState.equipped_knot = "dragon_splice"
		GameState.emit_signal("state_updated")
	player.start_winch_dash(dest, anchor)
	SoundManager.play_knot_cinch()


func on_rope_cast_hit(tip_pos: Vector2, knot_id: String) -> void:
	# 1. Tactical Rope Abilities against Church Catchpoles & Arbalesters
	var res := PlayerCombatHelperScript.resolve_knot_targets(knot_id, player.position, tip_pos, enemies)
	if bool(res.get("hit", false)):
		for e: Dictionary in enemies:
			if not bool(e.get("permanently_bound", false)) and float(e.get("snared_t", 0.0)) <= 0.0 and float(e.get("stun", 0.0)) > 10.0:
				e["stun"] = 0.0
				e["state"] = "chase" if String(e["kind"]) == "shield" else "reload"
		for b: Dictionary in res.get("bound", []):
			b["stun"] = 9999.0
			b["state"] = "bound"
			b["timer"] = 0.0
			b["hurt_flash"] = 0.14
			_spawn_sparks(Vector2(b["pos"]) + Vector2(0, -10), Color(0.96, 0.76, 0.28), 12)
		for y: Dictionary in res.get("yanked", []):
			y["state"] = "snared"
			y["timer"] = 0.0
			y["hurt_flash"] = 0.24
			_spawn_sparks(Vector2(y["pos"]) + Vector2(0, -10), Color(0.98, 0.44, 0.30), 12)
			SoundManager.play_cage_break()
		for sn: Dictionary in res.get("snared", []):
			sn["state"] = "snared"
			sn["timer"] = 0.0
			sn["hurt_flash"] = 0.16
			_spawn_sparks(Vector2(sn["pos"]) + Vector2(0, -10), Color(0.45, 0.90, 0.72), 10)
		var zipped = res.get("zipped_target", null)
		if zipped != null:
			player.position = Vector2(zipped["pos"]) + (player.position - Vector2(zipped["pos"])).normalized() * 24.0
			zipped["hp"] = maxi(0, int(zipped["hp"]) - 2)
			zipped["alive"] = int(zipped["hp"]) > 0
			zipped["hurt_flash"] = 0.25
			_spawn_sparks(Vector2(zipped["pos"]) + Vector2(0, -10), Color(1.0, 0.84, 0.32), 16)
		SoundManager.play_knot_cinch()
		if not _has_living_enemies():
			_on_encounter_victory()
		queue_redraw()
		return

	# 2. Canal Winch Grapple
	if not _has_living_enemies():
		var pairs := BrugesCityMapDataScript.get_winch_pairs()
		for pi in range(pairs.size()):
			var pr: Dictionary = pairs[pi]
			var wpt: Vector2 = Vector2(pr["west"])
			var ept: Vector2 = Vector2(pr["east"])
			if tip_pos.distance_to(wpt) <= 95.0 or tip_pos.distance_to(ept) <= 95.0 or player.position.distance_to(wpt) <= 85.0 or player.position.distance_to(ept) <= 85.0:
				_try_winch_pair(pi, player.position.distance_to(wpt) < player.position.distance_to(ept))
				return


func on_knife_slash(tip_pos: Vector2, _dir: Vector2) -> void:
	if enemies.is_empty():
		return
	var landed := false
	for e: Dictionary in enemies:
		if int(e["hp"]) <= 0:
			continue
		var ep: Vector2 = Vector2(e["pos"])
		var closest := Geometry2D.get_closest_point_to_segment(ep, player.position, tip_pos)
		if ep.distance_to(closest) > 46.0 and ep.distance_to(tip_pos) > 42.0:
			continue
		var edir: Vector2 = Vector2(e["dir"]).normalized()
		var atk_from: Vector2 = (player.position - ep).normalized()
		var blocked_front: bool = String(e["kind"]) == "shield" and float(e["stun"]) <= 0.0 and String(e["state"]) != "recover" and atk_from.dot(edir) > 0.20
		if blocked_front:
			SoundManager.play_knot_snag()
			_spawn_sparks(ep + edir * 14.0, Color(0.96, 0.90, 0.62), 7)
			var push_s: Vector2 = ep + (ep - player.position).normalized() * 8.0
			if not point_hits_colliders(push_s, static_colliders, 10.0):
				e["pos"] = push_s
			continue
		e["hp"] = int(e["hp"]) - 1
		e["hurt_flash"] = 0.20
		var knock_p: Vector2 = ep + (ep - player.position).normalized() * 14.0
		if not point_hits_colliders(knock_p, static_colliders, 10.0):
			e["pos"] = knock_p
		_spawn_sparks(ep + Vector2(0, -10), Color(0.98, 0.34, 0.28), 9)
		SoundManager.play_hit()
		landed = true
		if int(e["hp"]) <= 0:
			_spawn_sparks(ep, Color(0.98, 0.78, 0.36), 14)
	if landed and not _has_living_enemies():
		_on_encounter_victory()

func _make_enemy(kind: String, pos: Vector2, dir: Vector2, timer: float) -> Dictionary:
	var hp := 3 if kind == "shield" else 2
	return {"kind": kind, "pos": pos, "dir": dir, "hp": hp, "max_hp": hp, "state": "chase" if kind == "shield" else "reload", "timer": timer, "stun": 0.0, "hurt_flash": 0.0, "vel": Vector2.ZERO}

func _spawn_watergate_ambush() -> void:
	current_encounter = "watergate"
	enemy_bolts.clear()
	enemies.assign([_make_enemy("shield", Vector2(455, 1316), Vector2.RIGHT, 0.4), _make_enemy("shield", Vector2(705, 1465), Vector2.LEFT, 0.8), _make_enemy("arbalester", Vector2(730, 1620), Vector2.UP, 0.9)])
	SoundManager.play_alert_horn()

func _spawn_keep_ambush() -> void:
	current_encounter = "keep"
	enemy_bolts.clear()
	enemies.assign([_make_enemy("shield", Vector2(430, 515), Vector2.RIGHT, 0.3), _make_enemy("shield", Vector2(745, 515), Vector2.LEFT, 0.7), _make_enemy("shield", Vector2(592, 690), Vector2.UP, 1.0), _make_enemy("arbalester", Vector2(475, 425), Vector2.DOWN, 0.75)])
	SoundManager.play_alert_horn()

func _step_enemies(delta: float) -> void:
	for e: Dictionary in enemies:
		if int(e["hp"]) <= 0:
			continue
		e["hurt_flash"] = maxf(0.0, float(e["hurt_flash"]) - delta)
		if bool(e.get("permanently_bound", false)):
			continue
		if float(e["stun"]) > 0.0:
			e["stun"] = maxf(0.0, float(e["stun"]) - delta)
			if float(e["stun"]) <= 0.0:
				e["state"] = "chase" if String(e["kind"]) == "shield" else "reload"
				e["timer"] = 0.55
			continue

		var ep: Vector2 = Vector2(e["pos"])
		var to_p: Vector2 = player.position - ep
		var dist: float = to_p.length()
		var nd: Vector2 = to_p.normalized() if dist > 1.0 else Vector2.DOWN
		var kind: String = String(e["kind"])
		var state: String = String(e["state"])

		if kind == "shield":
			var los_p: bool = has_clear_line(ep, player.position, static_colliders, 8.0)
			match state:
				"chase":
					var move_d: Vector2 = compute_nav_move_dir(ep, player.position, static_colliders, 10.0)
					e["dir"] = nd if (los_p and dist <= 88.0) else move_d
					if dist <= 62.0 and los_p:
						e["state"] = "windup"
						e["timer"] = 0.62
						SoundManager.play_knot_snag()
					else:
						e["pos"] = steer_and_move_actor(ep, move_d, 100.0, delta, static_colliders, 10.0, enemies, e)
				"windup":
					e["timer"] = float(e["timer"]) - delta
					if float(e["timer"]) <= 0.0:
						e["state"] = "lunge"
						e["timer"] = 0.24
						e["vel"] = Vector2(e["dir"]).normalized() * 255.0
				"lunge":
					e["timer"] = float(e["timer"]) - delta
					var next_p: Vector2 = ep + Vector2(e["vel"]) * delta
					if not point_hits_colliders(next_p, static_colliders, 10.0):
						e["pos"] = next_p
					if Vector2(e["pos"]).distance_to(player.position) <= 28.0 and not player.is_invulnerable():
						_damage_player(1)
					if float(e["timer"]) <= 0.0:
						e["state"] = "recover"
						e["timer"] = 0.85
				"recover":
					e["timer"] = float(e["timer"]) - delta
					if float(e["timer"]) <= 0.0:
						e["state"] = "chase"
		else:
			# Crossbow Arbalester: routes around cover when LOS blocked and keeps distance cleanly
			var los_a: bool = has_clear_line(ep, player.position, static_colliders, 5.0)
			match state:
				"reload":
					var adv_d: Vector2 = compute_nav_move_dir(ep, player.position, static_colliders, 10.0)
					e["dir"] = nd if los_a else adv_d
					if not los_a or dist > 265.0:
						e["pos"] = steer_and_move_actor(ep, adv_d, 86.0, delta, static_colliders, 10.0, enemies, e)
					elif dist < 140.0:
						e["pos"] = steer_and_move_actor(ep, -nd, 86.0, delta, static_colliders, 10.0, enemies, e)
					e["timer"] = float(e["timer"]) - delta
					if float(e["timer"]) <= 0.0:
						if los_a or dist <= 85.0:
							e["state"] = "aim"
							e["timer"] = 0.92
						else:
							e["timer"] = 0.15
				"aim":
					e["dir"] = Vector2(e["dir"]).lerp(nd, minf(1.0, delta * 3.8)).normalized()
					e["timer"] = float(e["timer"]) - delta
					if float(e["timer"]) <= 0.0:
						enemy_bolts.append({"pos": ep + Vector2(0, -10) + Vector2(e["dir"]) * 18.0, "dir": Vector2(e["dir"]), "life": 1.6})
						SoundManager.play_bolt()
						e["state"] = "reload"
						e["timer"] = 1.45


func _step_bolts(delta: float) -> void:
	for i in range(enemy_bolts.size() - 1, -1, -1):
		var bt: Dictionary = enemy_bolts[i]
		bt["life"] = float(bt["life"]) - delta
		var npos: Vector2 = Vector2(bt["pos"]) + Vector2(bt["dir"]) * 370.0 * delta
		bt["pos"] = npos
		if float(bt["life"]) <= 0.0 or _point_hits_solid(npos):
			_spawn_sparks(npos, Color(0.86, 0.78, 0.64), 4)
			enemy_bolts.remove_at(i)
			continue
		if npos.distance_to(player.position) <= 16.0 and not player.is_invulnerable():
			enemy_bolts.remove_at(i)
			_damage_player(1)


func _point_hits_solid(pt: Vector2) -> bool:
	for cr: Rect2 in static_colliders:
		if cr.has_point(pt): return true
	return false

func _damage_player(amt: int) -> void:
	if player.is_invulnerable(): return
	GameState.boy_hp = maxi(0, GameState.boy_hp - amt)
	player.trigger_hurt_flash()
	SoundManager.play_hit()
	director.trigger_camera_shake(6.5, 0.25)
	ui.refresh_hud()
	if GameState.boy_hp <= 0: _handle_player_defeat()

func _handle_player_defeat() -> void:
	BrugesCityBoatsScript.reset_player_boat_state(self)
	var lost_enc := current_encounter
	current_encounter = ""
	enemies.clear()
	enemy_bolts.clear()
	ui.refresh_hud()
	var cause := "Cut down by the Church Catchpole Garrison at the Keep Gatehouse." if lost_enc == "keep" else "Overwhelmed by the Inquisitor's Catchpoles beside the Old Watergate."
	ui.show_death_screen(cause, func():
		GameState.boy_hp = GameState.boy_max_hp
		ui.refresh_hud()
		if lost_enc == "watergate":
			player.position = Vector2(704, 1304)
			_spawn_watergate_ambush()
		elif lost_enc == "keep":
			player.position = Vector2(592, 520)
			_spawn_keep_ambush()
		else:
			player.position = SOUTH_GATE_EXIT_POS + Vector2(0, -45)
	)


func _on_encounter_victory() -> void:
	enemies.clear()
	enemy_bolts.clear()
	SoundManager.play_chime()
	if current_encounter == "watergate":
		GameState.city_watergate_skirmish_won = true
		ui.refresh_hud()
		city_cam_focus_pos = DROPPED_NOTE_POS
		city_cam_focus_t = 1.35
		_spawn_sparks(DROPPED_NOTE_POS, Color(0.98, 0.88, 0.44), 18)
	elif current_encounter == "keep":
		GameState.city_keep_escape_won = true
		ui.refresh_hud()
		SoundManager.play_alert_horn()
		SoundManager.play_ship_bell()
		_spawn_sparks(player.position + Vector2(0, -10), Color(0.45, 0.96, 0.68), 14)
		_spawn_sparks(EAST_OUTSKIRTS_GATE_POS, Color(0.45, 0.96, 0.68), 18)
	current_encounter = ""


func _on_interact_dropped_note() -> void:
	if GameState.city_clue_counting_house: return
	GameState.city_clue_counting_house = true
	GameState.add_item("Church Requisition Writ")
	SoundManager.play_chime()
	player.show_held_item(assets.get_tex("prop_dropped_note.png"), 1.2)
	ui.pulse_hud_icon("bag")
	ui.refresh_hud()
	ui.show_parchment_note(
		"Crumpled Field Order",
		"\"...the hollow nest was cold and the egg already taken. Meet Father Anselm at St. Donatian's by the eighth evening bell. Carry iron gaffs in case the outlaw rider still guards it...\"",
		"Church Catchpole Seal — Bruges Watergate"
	)

func _on_interact_joris() -> void:
	if GameState.city_clue_cloth_hall:
		ui.show_dialogue([{"speaker": "Factor Joris", "portrait": "portrait_baker.png", "text": "West across Guildhall Bridge by the Counting-House Wharf—that's where the Catchpoles' mud-spattered iron wagon rolled to. Ask Sister Beatrijs east in the Beguinage too if you want her herbal tally."}])
		return
	GameState.city_clue_cloth_hall = true
	SoundManager.play_chime()
	ui.refresh_hud()
	ui.show_dialogue([
		{"speaker": "Factor Joris", "portrait": "portrait_baker.png", "text": "Linen wagons halted at the Cloth Hall gate since noon! Black-cloak Catchpoles rode in from the eastern border woods, paying bishop's gold coin for oilcloth wraps and tallow search-lanterns."},
		{"speaker": "Factor Joris", "portrait": "portrait_baker.png", "text": "They're shutting every gate to search cellars and canal barges for something stolen from the wilds—picked up sleeping-draughts from Sister Beatrijs in the Beguinage, then rolled their iron-chain wagon west over Guildhall Bridge to the Counting-House Wharf."}
	])

func _on_interact_beatrijs() -> void:
	if GameState.city_clue_beguinage:
		ui.show_dialogue([{"speaker": "Sister Beatrijs", "portrait": "portrait_maren.png", "text": "West across the canal bridges, beside the Counting-House Wharf—that guarded Catchpole wagon holds what you're looking for. Mind their bolts."}])
		return
	GameState.city_clue_beguinage = true
	SoundManager.play_chime()
	ui.refresh_hud()
	ui.show_dialogue([
		{"speaker": "Sister Beatrijs", "portrait": "portrait_maren.png", "text": "Church Catchpoles back from the border woods bought half the Beguinage's sleeping-draughts and search-torches! Muttered of an empty nest in a scorched hollow and locking Bruges down till what was taken is found."},
		{"speaker": "Sister Beatrijs", "portrait": "portrait_maren.png", "text": "Cloth-Factor Joris at Grote Markt saw their gold coin, and the guarded iron-chain wagon itself is parked west across the canal outside the Counting-House Wharf."}
	])

func _on_interact_wagon() -> void:
	if GameState.city_watergate_skirmish_won or GameState.city_clue_counting_house: return
	ui.show_dialogue([{"speaker": "Catchpole Sergeant", "portrait": "portrait_watchman.png", "text": "Hey! Hands off the Inquisitor's search-wain, gutter-rat! Shields up—pin him against the wharf!"}], func(): _spawn_watergate_ambush())


func _on_interact_church_wait() -> void:
	if priest_tail_active or GameState.city_bounty_overheard or not GameState.city_clue_counting_house:
		return
	player.can_move = false
	player.position = CHURCH_HIDING_POS
	player.facing = Vector2.RIGHT
	player.set_cutscene_pose("boy_kneel.png")
	ui.set_cinematic_mode(true)
	ui.set_fade(1.0, false)
	SoundManager.play_church_bell()
	_spawn_bell_waves()
	await get_tree().create_timer(0.50).timeout
	if not is_inside_tree():
		return
	SoundManager.play_ship_bell()
	await get_tree().create_timer(0.50).timeout
	if not is_inside_tree():
		return
	city_evening_time = true
	ui.set_fade(0.0, false)
	player.set_cutscene_pose("")
	ui.set_cinematic_mode(false)
	player.can_move = true
	_begin_priest_tail()


func _spawn_bell_waves() -> void:
	for k in range(3):
		bell_wave_rings.append({"pos": CATHEDRAL_BELL_POS, "age": -float(k) * 0.48, "max_age": 2.4})


func _begin_priest_tail() -> void:
	SoundManager.play_church_bell()
	_spawn_bell_waves()
	city_evening_time = true
	priest_tail_active = true
	priest_pos = priest_route[0]
	priest_wp_idx = 1
	priest_dir = Vector2.LEFT
	priest_look_dir = Vector2.LEFT
	priest_base_look_dir = Vector2.LEFT
	priest_state = "walk"
	priest_state_timer = 3.8
	player.position = CHURCH_HIDING_POS
	player.facing = Vector2.DOWN
	city_cam_focus_pos = priest_pos
	city_cam_focus_t = 1.35
	_spawn_sparks(priest_pos + Vector2(0, -14), Color(0.98, 0.84, 0.36), 12)
	SoundManager.play_chime()

func _step_priest_tail(delta: float) -> void:
	var dist := player.position.distance_to(priest_pos)
	if dist < 30.0 and has_clear_line(priest_pos, player.position, sight_blockers, 2.0):
		_fail_priest_tail("Bumped right into Father Anselm's cassock!")
		return
	if dist > 560.0:
		_fail_priest_tail("Lost Father Anselm in the winding canal alleys!")
		return
	match priest_state:
		"walk":
			if priest_wp_idx < priest_route.size():
				var target: Vector2 = priest_route[priest_wp_idx]
				if priest_pos.distance_to(target) <= 8.0:
					priest_pos = target
					priest_wp_idx += 1
					if priest_wp_idx >= priest_route.size():
						_trigger_bounty_eavesdrop()
						return
				else:
					var move_d: Vector2 = compute_nav_move_dir(priest_pos, target, static_colliders, 10.0)
					priest_dir = move_d
					priest_pos = steer_and_move_actor(priest_pos, move_d, 76.0, delta, static_colliders, 10.0)
			priest_state_timer -= delta
			if priest_state_timer <= 0.0:
				priest_state = "warn"
				priest_state_timer = 1.15
				priest_base_look_dir = (player.position - priest_pos).normalized()
				priest_look_dir = priest_base_look_dir
		"warn":
			priest_state_timer -= delta
			if priest_state_timer <= 0.0:
				priest_state = "glance"
				priest_state_timer = 1.75
		"glance":
			priest_state_timer -= delta
			var sweep_t: float = clampf(1.75 - priest_state_timer, 0.0, 1.75)
			priest_look_dir = priest_base_look_dir.rotated(sin(sweep_t * 3.6) * deg_to_rad(34.0))
			if not player.is_invulnerable() and can_vision_cone_see(priest_pos + Vector2(0, -8), priest_look_dir, player.position + Vector2(0, -8), 270.0, deg_to_rad(46.0), sight_blockers, 0.0):
				_fail_priest_tail("Father Anselm caught sight of you creeping across the cobbles!")
				return
			if priest_state_timer <= 0.0:
				priest_state = "walk"
				priest_state_timer = 3.8

func _fail_priest_tail(reason: String) -> void:
	BrugesCityBoatsScript.reset_player_boat_state(self)
	priest_tail_active = false
	SoundManager.play_alert_horn()
	director.trigger_camera_shake(5.5, 0.25)
	player.trigger_hurt_flash()
	ui.refresh_hud()
	ui.show_mission_failed_screen(reason, func():
		GameState.boy_hp = GameState.boy_max_hp
		ui.refresh_hud()
		_begin_priest_tail()
	)

func _trigger_bounty_eavesdrop() -> void:
	priest_tail_active = false
	GameState.city_priest_tailed = true
	GameState.city_bounty_overheard = true
	SoundManager.play_alert_horn()
	ui.set_cinematic_mode(true)
	ui.show_dialogue([
		{"speaker": "Church Inquisitor", "portrait": "portrait_inquisitor.png", "text": "Our hunters reached the border hollow where our bolts brought the black dragon down. Did they destroy its nest?"},
		{"speaker": "Father Anselm", "portrait": "portrait_priest.png", "text": "The beast was lying dead in the ash, Inquisitor—but its nest was cold and empty. Someone carried the egg away before our men arrived."},
		{"speaker": "Church Inquisitor", "portrait": "portrait_inquisitor.png", "text": "That egg was never meant to see the light of day! Seal every canal gate in Bruges before dawn."},
		{"speaker": "Father Anselm", "portrait": "portrait_priest.png", "text": "At first light, cry a silver bounty on anyone seen carrying a pitch-black egg veined with gold. Coin will make every burgher in Flanders our eyes."}
	], func():
		_spawn_sparks(player.position + Vector2(0, 8), Color(0.84, 0.80, 0.72), 14)
		SoundManager.play_step(true)
		SoundManager.play_knot_snag()
		director.trigger_camera_shake(2.4, 0.18)
		player.position += Vector2(6, 3)
		eavesdrop_scrape_t = 0.44
	)

func _finish_bounty_eavesdrop() -> void:
	ui.show_dialogue([{"speaker": "Church Inquisitor", "portrait": "portrait_inquisitor.png", "text": "There—behind the keep pillar! Catchpoles, shut the yard and bring me that spy alive!"}], func():
		ui.set_cinematic_mode(false)
		player.position = Vector2(592, 520)
		_spawn_keep_ambush())

func _on_interact_south_exit() -> void:
	SoundManager.play_door()
	director.load_region("bruges", {"spawn": Vector2(720, 68), "facing": Vector2.DOWN})


func _on_enter_east_outskirts() -> void:
	if GameState.city_bounty_overheard and GameState.city_keep_escape_won:
		GameState.sanctuary_phase = 4
	SoundManager.play_door()
	director.load_region("outskirts", {"spawn": Vector2(96, 560), "facing": Vector2.RIGHT})


func _on_read_south_gate_sign() -> void:
	ui.show_parchment_note("South Gatehouse Post", "SOUTH: Port of Bruges — Outer Docks, Warehouse & Ropewalk Quarter.", "Bruges City Bailiff Seal")


func _on_read_east_gate_sign() -> void:
	ui.show_parchment_note("East Gatehouse Post", "EAST ACROSS THE MOAT: Coastal Outskirts, Zwin Bridge & Sanctuary Dunes.", "Bruges City Bailiff Seal")

func _spawn_sparks(pos: Vector2, col: Color, count: int) -> void:
	for _i in range(count):
		var a := randf_range(0.0, TAU)
		combat_sparks.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(40.0, 120.0), "t": 0.35, "max_t": 0.35, "col": col})

func _step_sparks(delta: float) -> void:
	for i in range(combat_sparks.size() - 1, -1, -1):
		var sp: Dictionary = combat_sparks[i]
		sp["t"] = float(sp["t"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		if float(sp["t"]) <= 0.0: combat_sparks.remove_at(i)

func _init_townsfolk_states() -> void:
	townsfolk_states.clear()
	var base_list: Array[Dictionary] = BrugesCityMapDataScript.get_ambient_townsfolk()
	for i in range(base_list.size()):
		var src: Dictionary = base_list[i]
		var wps: Array = src.get("waypoints", [])
		var start_pos: Vector2 = Vector2(wps[0]) if not wps.is_empty() else Vector2(src["pos"])
		var init_dir: Vector2 = Vector2.DOWN
		if wps.size() >= 2 and (Vector2(wps[1]) - start_pos).length_squared() > 1.0:
			init_dir = (Vector2(wps[1]) - start_pos).normalized()
		townsfolk_states.append({"id": String(src["id"]), "tex": String(src["tex"]), "name": String(src["name"]), "bark": String(src.get("bark", "")), "pos": start_pos, "waypoints": wps.duplicate(), "wp_idx": 1 if wps.size() >= 2 else 0, "dir": init_dir, "moving": false, "phase": float(i) * 0.85})

func _step_townsfolk(delta: float) -> void:
	for tf in townsfolk_states:
		var wps: Array = tf["waypoints"]
		if wps.size() < 2:
			tf["moving"] = false
			continue
		var cur_pos: Vector2 = Vector2(tf["pos"])
		if player != null and player.position.distance_to(cur_pos) < 38.0:
			tf["moving"] = false
			var to_p: Vector2 = player.position - cur_pos
			if to_p.length_squared() > 1.0: tf["dir"] = to_p.normalized()
			continue
		var idx: int = int(tf["wp_idx"])
		var diff: Vector2 = Vector2(wps[idx]) - cur_pos
		if diff.length() <= 6.0:
			tf["pos"] = Vector2(wps[idx])
			tf["wp_idx"] = (idx + 1) % wps.size()
			tf["moving"] = false
		else:
			var dir: Vector2 = diff.normalized()
			tf["dir"] = dir
			tf["pos"] = cur_pos + dir * 34.0 * delta
			tf["moving"] = true

const TOWNSFOLK_PORTRAITS: Dictionary = {"npc_city_guard": "portrait_watchman.png", "npc_city_fishwife": "portrait_maren.png", "npc_city_apothecary": "portrait_maren.png", "npc_city_monk": "portrait_priest.png", "npc_city_sailor": "portrait_shipmaster.png", "npc_city_cooper": "portrait_quartermaster.png", "npc_city_apprentice": "portrait_hendrick.png"}

func _on_interact_townsfolk(idx: int) -> void:
	if idx < 0 or idx >= townsfolk_states.size(): return
	var tf: Dictionary = townsfolk_states[idx]
	var bark: String = String(tf.get("bark", ""))
	if bark == "": return
	if player != null and (player.position - Vector2(tf["pos"])).length_squared() > 1.0:
		tf["dir"] = (player.position - Vector2(tf["pos"])).normalized()
	ui.show_dialogue([{"speaker": String(tf["name"]), "portrait": String(TOWNSFOLK_PORTRAITS.get(String(tf["tex"]), "portrait_baker.png")), "text": bark}])

func get_active_npc_colliders() -> Array:
	var list: Array = [{"pos": NPC_JORIS_POS, "yield_key": "city_joris"}, {"pos": NPC_BEATRIJS_POS, "yield_key": "city_beatrijs"}]
	if priest_tail_active: list.append(priest_pos)
	if priest_tail_active or GameState.city_bounty_overheard: list.append(INQUISITOR_POS)
	for tf: Dictionary in townsfolk_states: list.append({"pos": Vector2(tf["pos"]), "yield_key": String(tf["id"])})
	for e: Dictionary in enemies:
		if int(e["hp"]) > 0: list.append(Vector2(e["pos"]))
	return list

func _draw() -> void: BrugesCityDrawScript.draw_city(self)
