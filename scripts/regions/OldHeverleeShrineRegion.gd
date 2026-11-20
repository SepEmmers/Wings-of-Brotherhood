extends "res://scripts/regions/RegionBase.gd"

## Isolated Subterranean First Golden Dragon Shrine (1600x960):
## Room 1: Pushable Keystone Boulder onto Bronze Weight Plate unlatches Serpent Vent for Hatchling [R]
## Room 2: Rope Bowline [F] across Water Chasm + ignite West & East Golden Sconces [R]
## Room 3: Claim the Old Heverlee Shrine Key -> Golden Bond Pulse -> Escape Tunnel to Cliffside Fire.

const MapData := preload("res://scripts/regions/OldHeverleeShrineMapData.gd")
const DrawHelper := preload("res://scripts/regions/OldHeverleeShrineDraw.gd")

var static_colliders: Array[Rect2] = []
var boulder_body: StaticBody2D
var shrine_lights: Array[PointLight2D] = []
var boulder_pos: Vector2 = MapData.BOULDER_START_POS
var boulder_push_t: float = 0.0
var plate_pressed: bool = false
var sconce_w_lit: bool = false
var sconce_e_lit: bool = false
var fx_sparks: Array[Dictionary] = []
var _last_command_kind: String = ""


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	boulder_body = StaticBody2D.new()
	add_child(boulder_body)
	_rebuild_colliders()

	for lp: Vector2 in [MapData.RELIEF_POS, MapData.PLATE_POS, MapData.SCONCE_W_POS, MapData.SCONCE_E_POS, MapData.PEDESTAL_POS]:
		var pl: PointLight2D = assets.make_point_light(lp, 2.8, Color(1.0, 0.80, 0.38), 0.72)
		add_child(pl)
		shrine_lights.append(pl)

	DrawHelper.setup_layers(self)
	_build_interactables()
	clear_walk_portals()
	register_walk_portal("shrine_exit_south", MapData.EXIT_SOUTH_RECT, Vector2.DOWN, _on_exit_south, "v Return to Old Heverlee", "OLD HEVERLEE WOODS", "Zoet Water Creek")
	register_walk_portal("shrine_escape_east", MapData.BACK_STAIRS_RECT, Vector2.RIGHT, _on_exit_back_tunnel, "-> Ascend Cliffside Overlook", "OLD HEVERLEE LOOKOUT", "Cliffside Campfire & Kestrel")


func _rebuild_colliders() -> void:
	for c in colliders.get_children():
		c.queue_free()
	static_colliders = MapData.get_static_colliders(GameState.shrine_gate1_open, GameState.shrine_gate2_open)
	for crect: Rect2 in static_colliders:
		add_box_collider(colliders, crect)
	for bc in boulder_body.get_children():
		bc.queue_free()
	var brect := Rect2(boulder_pos - Vector2(16, 15), Vector2(32, 30))
	add_box_collider(boulder_body, brect)
	var nav_cols := static_colliders.duplicate()
	nav_cols.append(brect)
	setup_navigation_grid(Rect2(Vector2.ZERO, MapData.WORLD_SIZE), nav_cols, 10.0, 20.0)


func _build_interactables() -> void:
	interactables = [
		{"id": "shr_relief", "name": "Examine Devildragon Relief", "pos": MapData.RELIEF_POS + Vector2(0, 24), "radius": 68.0, "callback": _on_inspect_relief},
		{"id": "shr_key", "name": "Take Old Heverlee Shrine Key", "pos": MapData.PEDESTAL_POS, "radius": 66.0, "callback": _on_claim_relic_key},
	]


func enter_region(opts: Dictionary = {}) -> void:
	fx_sparks.clear()
	portal_cooldown = 0.85
	_last_command_kind = ""
	GameState.active_perspective = "boy"
	GameState.book2_started = true
	if GameState.active_companion_stage < 1:
		GameState.active_companion_stage = 1
		GameState.brabant_hatched = true
	if int(GameState.current_step) < int(GameState.QuestStep.BOOK2_OLD_HEVERLEE):
		GameState.current_step = GameState.QuestStep.BOOK2_OLD_HEVERLEE
	GameState.unlock_realm_node("old_heverlee")

	boulder_pos = MapData.PLATE_POS if GameState.shrine_gate1_open else MapData.BOULDER_START_POS
	plate_pressed = (boulder_pos.distance_to(MapData.PLATE_POS) <= 18.0) or GameState.shrine_gate1_open
	sconce_w_lit = GameState.shrine_gate2_open
	sconce_e_lit = GameState.shrine_gate2_open
	_rebuild_colliders()

	player.position = opts.get("spawn", MapData.ENTRY_SPAWN)
	player.facing = opts.get("facing", Vector2.UP)
	player.visible = true
	player.cutscene_hidden = false
	player.can_move = true
	player.set_carry_prop("", "")

	if director != null and director.camera != null:
		director.camera.limit_left = 0
		director.camera.limit_top = 0
		director.camera.limit_right = int(MapData.WORLD_SIZE.x)
		director.camera.limit_bottom = int(MapData.WORLD_SIZE.y)
		director.camera.position = player.position

	_sync_hint_context()
	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.update_world_map_state("old_heverlee", player.position)
	ui.refresh_hud()
	SoundManager.set_ambience(get_ambience_track())


func exit_region() -> void:
	if director != null and director.companion != null:
		director.companion.clear_hint_context()


func handle_region_input(event: InputEvent) -> bool:
	if player == null or not player.visible or (ui != null and ui.is_blocking_gameplay()):
		return false
	if event.is_action_pressed("rope_action") and not GameState.shrine_gate1_open and player.position.distance_to(boulder_pos) <= 46.0:
		var push_dir := (boulder_pos - player.position).normalized()
		if absf(push_dir.x) >= absf(push_dir.y):
			push_dir = Vector2(signf(push_dir.x), 0.0)
		else:
			push_dir = Vector2(0.0, signf(push_dir.y))
		_attempt_slide_boulder(push_dir)
		return true
	return false


func step_region(delta: float) -> void:
	step_water_layer()
	_step_boulder_push(delta)
	_step_fx(delta)
	if director != null and director.camera != null and player != null:
		director.camera.position = player.position
	if player != null and player.visible:
		update_nearest_interactable(player.position)
	queue_redraw()
	queue_foreground_redraw()


func _step_boulder_push(delta: float) -> void:
	if GameState.shrine_gate1_open or player == null or not player.can_move or (ui != null and ui.is_blocking_gameplay()):
		boulder_push_t = 0.0
		return
	var move_in := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_in.length() < 0.25 or player.position.distance_to(boulder_pos) > 42.0:
		boulder_push_t = 0.0
		return
	var to_b := (boulder_pos - player.position).normalized()
	if to_b.dot(move_in.normalized()) < 0.45:
		boulder_push_t = 0.0
		return
	boulder_push_t += delta
	if boulder_push_t >= 0.16:
		boulder_push_t = 0.0
		var axis := Vector2(signf(to_b.x), 0.0) if absf(to_b.x) >= absf(to_b.y) else Vector2(0.0, signf(to_b.y))
		_attempt_slide_boulder(axis)


func _attempt_slide_boulder(dir_v: Vector2) -> void:
	var nxt := boulder_pos + dir_v * 42.0
	if point_hits_colliders(nxt, static_colliders, 15.0):
		return
	boulder_pos = nxt
	SoundManager.play_cage_break()
	_spawn_sparks(boulder_pos, Color(0.86, 0.80, 0.62), 8)
	if boulder_pos.distance_to(MapData.PLATE_POS) <= 22.0 and not plate_pressed:
		boulder_pos = MapData.PLATE_POS
		plate_pressed = true
		SoundManager.play_chime()
		_spawn_sparks(MapData.SERPENT_VENT_POS, Color(0.98, 0.84, 0.34), 16)
		_sync_hint_context()
	_rebuild_colliders()


func get_rope_anchors() -> Array[Vector2]:
	return [MapData.CHASM_POST_W, MapData.CHASM_POST_E]


func on_rope_cast_hit(target_pos: Vector2, _knot_id: String) -> void:
	if target_pos.distance_to(MapData.CHASM_POST_E) <= 70.0 and player.position.x < MapData.CHASM_RECT.position.x:
		player.position = MapData.CHASM_POST_E + Vector2(28, 0)
		SoundManager.play_rope()
		_spawn_sparks(MapData.CHASM_POST_E, Color(0.96, 0.84, 0.36), 12)
	elif target_pos.distance_to(MapData.CHASM_POST_W) <= 70.0 and player.position.x > MapData.CHASM_RECT.end.x:
		player.position = MapData.CHASM_POST_W + Vector2(-28, 0)
		SoundManager.play_rope()
		_spawn_sparks(MapData.CHASM_POST_W, Color(0.96, 0.84, 0.36), 12)


func find_dragon_command_target(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> Dictionary:
	var ppos := player.position if player != null else origin
	if not GameState.shrine_gate1_open and (origin.distance_to(MapData.SERPENT_VENT_POS) <= 95.0 or ppos.distance_to(MapData.SERPENT_VENT_POS) <= 95.0 or target_pos.distance_to(MapData.SERPENT_VENT_POS) <= 88.0):
		return {"kind": "vent_crawl", "target_pos": MapData.SERPENT_VENT_POS, "stand_pos": MapData.SERPENT_VENT_POS + Vector2(0, 26)}
	if not sconce_w_lit and (origin.distance_to(MapData.SCONCE_W_POS) <= 95.0 or ppos.distance_to(MapData.SCONCE_W_POS) <= 95.0 or target_pos.distance_to(MapData.SCONCE_W_POS) <= 88.0):
		return {"kind": "ember_puff", "target_pos": MapData.SCONCE_W_POS, "stand_pos": MapData.SCONCE_W_POS + Vector2(0, 26)}
	if not sconce_e_lit and (origin.distance_to(MapData.SCONCE_E_POS) <= 95.0 or ppos.distance_to(MapData.SCONCE_E_POS) <= 95.0 or target_pos.distance_to(MapData.SCONCE_E_POS) <= 88.0):
		return {"kind": "ember_puff", "target_pos": MapData.SCONCE_E_POS, "stand_pos": MapData.SCONCE_E_POS + Vector2(0, 26)}
	return {}


func on_dragon_command(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> bool:
	_last_command_kind = ""
	if not GameState.shrine_gate1_open and (origin.distance_to(MapData.SERPENT_VENT_POS) <= 95.0 or target_pos.distance_to(MapData.SERPENT_VENT_POS) <= 88.0):
		if not plate_pressed:
			SoundManager.play_hit()
			_spawn_sparks(MapData.SERPENT_VENT_POS, Color(0.75, 0.42, 0.36), 8)
			return false
		_last_command_kind = "vent_crawl"
		GameState.shrine_gate1_open = true
		_rebuild_colliders()
		SoundManager.play_cage_break()
		SoundManager.play_chime()
		_spawn_sparks(MapData.GATE1_RECT.get_center(), Color(0.98, 0.84, 0.38), 18)
		_sync_hint_context()
		return true
	if not sconce_w_lit and (origin.distance_to(MapData.SCONCE_W_POS) <= 95.0 or target_pos.distance_to(MapData.SCONCE_W_POS) <= 88.0):
		_last_command_kind = "ember_puff"
		sconce_w_lit = true
		SoundManager.play_campfire_warm()
		_spawn_sparks(MapData.SCONCE_W_POS, Color(1.0, 0.78, 0.28), 16)
		_check_gate2()
		return true
	if not sconce_e_lit and (origin.distance_to(MapData.SCONCE_E_POS) <= 95.0 or target_pos.distance_to(MapData.SCONCE_E_POS) <= 88.0):
		_last_command_kind = "ember_puff"
		sconce_e_lit = true
		SoundManager.play_campfire_warm()
		_spawn_sparks(MapData.SCONCE_E_POS, Color(1.0, 0.78, 0.28), 16)
		_check_gate2()
		return true
	return false


func _check_gate2() -> void:
	if sconce_w_lit and sconce_e_lit and not GameState.shrine_gate2_open:
		GameState.shrine_gate2_open = true
		_rebuild_colliders()
		SoundManager.play_cage_break()
		SoundManager.play_chime()
		_spawn_sparks(MapData.GATE2_RECT.get_center(), Color(0.98, 0.84, 0.38), 20)
		_sync_hint_context()


func get_last_dragon_command_kind() -> String:
	return _last_command_kind


func _on_inspect_relief() -> void:
	GameState.shrine_ritual_seen = true
	SoundManager.play_chime()
	ui.show_dialogue([
		{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Look at that horned shadow above the chained dragons... crimson veins pouring into an iron vessel. That's why Church inquisitors harvest hearts alive."},
		{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "A Devildragon ritual... Mother and Father sealed the key inside this vault so nobody could awaken it."}
	])


func _on_claim_relic_key() -> void:
	if GameState.boy_heverlee_relic_found:
		return
	GameState.boy_heverlee_relic_found = true
	GameState.boy_hp = GameState.boy_max_hp
	GameState.add_item("Old Heverlee Shrine Key")
	GameState.add_dragon_bond(20)
	SoundManager.play_chime()
	director.trigger_camera_shake(4.0, 0.35)
	_spawn_sparks(MapData.PEDESTAL_POS, Color(1.0, 0.88, 0.36), 28)
	ui.refresh_hud()
	ui.show_dialogue([
		{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "The Old Heverlee Shrine Key... still warm beneath the dust! And look—eastern stairs opened beyond the plinth!"},
		{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Our bond just rang like sun-struck gold! Follow that breeze east—Kestrel will find us on the ridge above."}
	])
	_sync_hint_context()


func _on_exit_south() -> void:
	director.load_region("old_heverlee", {"spawn": preload("res://scripts/regions/OldHeverleeMapData.gd").SHRINE_EXIT_SPAWN, "facing": Vector2.DOWN})


func _on_exit_back_tunnel() -> void:
	director.load_region("old_heverlee", {"spawn": preload("res://scripts/regions/OldHeverleeMapData.gd").SHRINE_BACK_SPAWN, "facing": Vector2.RIGHT})


func is_portal_unlocked(id: String) -> bool:
	if id == "shrine_escape_east":
		return GameState.boy_heverlee_relic_found
	return true


func is_interactable_active(id: String) -> bool:
	if id == "shr_key":
		return not GameState.boy_heverlee_relic_found
	return true


func _sync_hint_context() -> void:
	if director == null or director.companion == null:
		return
	if not GameState.shrine_gate1_open:
		if not plate_pressed:
			director.companion.set_hint_context("shr_boulder", ["Notice that bronze floor plate east of the carved stone cube? Something heavy needs to anchor it down first."], MapData.BOULDER_START_POS, 28.0)
		else:
			director.companion.set_hint_context("shr_vent", ["The bronze counterweight dropped open the serpent grate! Let me slip through and unbolt the stone gate."], MapData.SERPENT_VENT_POS, 28.0)
	elif not GameState.shrine_gate2_open:
		director.companion.set_hint_context("shr_sconces", ["Two unlit serpent braziers guard each bank of the chasm—light one here, catch the iron post across with your rope, and kindle its twin."], MapData.SCONCE_W_POS, 28.0)
	elif not GameState.boy_heverlee_relic_found:
		director.companion.set_hint_context("shr_key", ["Gold light sings off that sanctum plinth ahead!"], MapData.PEDESTAL_POS, 28.0)
	else:
		director.companion.clear_hint_context()


func _step_fx(delta: float) -> void:
	for i in range(fx_sparks.size() - 1, -1, -1):
		var sp: Dictionary = fx_sparks[i]
		sp["life"] = float(sp["life"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		if float(sp["life"]) <= 0.0:
			fx_sparks.remove_at(i)


func _spawn_sparks(origin: Vector2, col: Color, count: int = 12) -> void:
	for _i in range(count):
		var a := randf() * TAU
		var s := randf_range(28.0, 92.0)
		fx_sparks.append({"pos": origin, "vel": Vector2(cos(a), sin(a)) * s, "life": randf_range(0.28, 0.55), "max_life": 0.55, "sz": randf_range(2.2, 3.8), "col": col})


func get_surface_at(_pos: Vector2) -> String:
	return "cobble"


func get_ambience_track() -> String:
	return "amb_catacombs" if AudioServer.get_bus_count() >= 0 else "amb_dawn_tension"


func get_lighting_tint() -> Color:
	return Color(0.68, 0.66, 0.72)


func update_region_lights(_time_val: float) -> void:
	sync_light_frustum(shrine_lights, true)


func _draw() -> void:
	DrawHelper.draw_region_entities(self, Time.get_ticks_msec() * 0.001)
