extends "res://scripts/regions/RegionBase.gd"

## Book II Act I Hub 1 — Circular Louvain (City of Bells & Cathedral Catacombs, 2100x2100):
## Cloak-Sling concealment & Bounty Heat (CityHeatHelper), 3 city side stories,
## Abbey Scriptorium Vent Crawl + Ember Puff infiltration, and Forecourt Breakout
## featuring 3-hit Knife combo, Dodge-Counter, Whipping Shield-Yank & Golden Burst.

const MapData := preload("res://scripts/regions/LouvainCityMapData.gd")
const DrawHelper := preload("res://scripts/regions/LouvainCityDraw.gd")
const QuestsHelper := preload("res://scripts/regions/LouvainCityQuests.gd")
const CityHeatHelperScript := preload("res://scripts/systems/CityHeatHelper.gd")
const PlayerCombatHelperScript := preload("res://scripts/systems/PlayerCombatHelper.gd")

const NPC_PIETER_POS := Vector2(676, 492)
const NPC_MASON_POS := Vector2(1196, 748)
const NPC_SCHOLAR_POS := Vector2(862, 1372)
const NPC_ALEIDIS_POS := Vector2(280, 1296)
const NPC_MARTIJN_POS := Vector2(394, 1296)
const NPC_KATELIJNE_POS := Vector2(360, 1554)
const ABBEY_LEVER_POS := MapData.ABBEY_LEVER_POS
const ABBEY_VENT_CRAWL_DUR := 3.40

var static_colliders: Array[Rect2] = []
var sight_blockers: Array[Rect2] = []
var abbey_gate_body: StaticBody2D
var south_gate_body: StaticBody2D
var city_lights: Array[PointLight2D] = []

var heat_helper = CityHeatHelperScript.new()
var patrols: Array[Dictionary] = []
var ambient_citizens: Array[Dictionary] = []
var breakout_enemies: Array[Dictionary] = []
var enemy_bolts: Array[Dictionary] = []
var fx_sparks: Array[Dictionary] = []
var resonance_wave_t: float = 0.0
var resonance_wave_origin: Vector2 = Vector2.ZERO
var abbey_vent_crawl_t: float = 0.0
var abbey_gate_open_anim: float = 0.0
var _abbey_lever_tripped: bool = false
var _last_command_kind: String = ""
var _ambush_triggered: bool = false
var _torn_posters: Dictionary = {}
var _checkpoint_state: Dictionary = {}


func _ready() -> void:
	static_colliders = MapData.get_static_colliders()
	sight_blockers = MapData.get_sight_blockers()
	colliders = StaticBody2D.new()
	add_child(colliders)
	for crect: Rect2 in static_colliders:
		add_box_collider(colliders, crect)
	setup_navigation_grid(Rect2(Vector2.ZERO, MapData.WORLD_SIZE), static_colliders, 10.0, 20.0)

	abbey_gate_body = StaticBody2D.new()
	add_child(abbey_gate_body)
	add_box_collider(abbey_gate_body, MapData.ABBEY_GATE_RECT)

	south_gate_body = StaticBody2D.new()
	add_child(south_gate_body)
	add_box_collider(south_gate_body, MapData.SOUTH_GATE_BARRICADE_RECT)

	for lp: Vector2 in MapData.get_lantern_positions():
		var pl: PointLight2D = assets.make_point_light(lp + Vector2(0, -14), 2.3, Color(1.0, 0.78, 0.44), 0.72)
		add_child(pl)
		city_lights.append(pl)

	DrawHelper.setup_layers(self)
	_build_interactables()
	clear_walk_portals()
	register_walk_portal("louvain_west_fens", Rect2(60, 976, 52, 128), Vector2.LEFT, _on_exit_west, "<- Brabant Fens", "BRABANT REED-FENS", "Mill Ruins & Dikes")
	register_walk_portal("louvain_to_catacombs", MapData.CATHEDRAL_DOOR_PORTAL_RECT, Vector2.UP, _on_enter_catacombs, "^ Enter Abbey Cathedral", "ABBEY CATHEDRAL & CATACOMBS", "Nave, Crypt & Hidden Library")
	register_walk_portal("louvain_south_heverlee", Rect2(986, 1986, 128, 70), Vector2.DOWN, _on_exit_south, "v Old Heverlee Woods", "OLD HEVERLEE TRAIL", "Hunters' Woods South")


func _build_interactables() -> void:
	interactables = [
		{"id": "lv_pieter", "name": "Deaf Bell-Founder Pieter", "pos": NPC_PIETER_POS, "radius": 72.0, "callback": func(): QuestsHelper.on_interact_pieter(self)},
		{"id": "lv_mason", "name": "Master Mason Matthijs", "pos": NPC_MASON_POS, "radius": 68.0, "callback": func(): QuestsHelper.on_interact_mason(self)},
		{"id": "lv_mason_stone", "name": "Gobertange Ashlar Crate", "pos": MapData.MASON_STONE_POS, "radius": 68.0, "callback": func(): QuestsHelper.on_interact_mason_stone(self, MapData)},
		{"id": "lv_mason_crane", "name": "Sint-Pieterskerk Hoist Crane", "pos": MapData.MASON_CRANE_POS, "radius": 70.0, "callback": func(): QuestsHelper.open_crane_builder(self)},
		{"id": "lv_scholar", "name": "University Beadle Hendrik", "pos": NPC_SCHOLAR_POS, "radius": 68.0, "callback": func(): QuestsHelper.on_interact_scholar(self)},
		{"id": "lv_winch", "name": "Foundry Bell Hoist", "pos": MapData.FOUNDRY_WINCH_POS, "radius": 70.0, "callback": func(): QuestsHelper.repair_foundry_hoist(self, MapData)},
		{"id": "lv_clay", "name": "Dijle River Clay Bank", "pos": MapData.CLAY_BANK_POS, "radius": 68.0, "callback": func(): QuestsHelper.on_interact_clay(self)},
		{"id": "lv_aleidis", "name": "Guildmistress Aleidis", "pos": NPC_ALEIDIS_POS, "radius": 72.0, "callback": func(): QuestsHelper.on_interact_aleidis(self)},
		{"id": "lv_martijn", "name": "One-Eyed Veteran Martijn", "pos": NPC_MARTIJN_POS, "radius": 72.0, "callback": func(): QuestsHelper.on_interact_martijn(self)},
		{"id": "lv_katelijne", "name": "Herbalist Sister Katelijne", "pos": NPC_KATELIJNE_POS, "radius": 72.0, "callback": func(): QuestsHelper.on_interact_katelijne(self)},
		{"id": "lv_sluice", "name": "Herbalist Dye-Sluice ([F] / [R])", "pos": MapData.HERBALIST_SLUICE_POS, "radius": 72.0, "callback": func(): QuestsHelper.clear_herbalist_sluice(self, MapData)},
		{"id": "lv_ring_chest", "name": "Confiscated Watch Chest", "pos": MapData.CONFISCATED_CHEST_POS, "radius": 68.0, "callback": func(): QuestsHelper.on_interact_ring_chest(self)},
		{"id": "lv_south_sign", "name": "Read South Gate Milestone", "pos": MapData.SOUTH_SIGN_POS, "radius": 64.0, "callback": _on_read_south_sign},
	]
	for p: Dictionary in MapData.get_wanted_posters():
		var pid := String(p["id"])
		interactables.append({"id": pid, "name": "Tear Church Wanted Poster", "pos": Vector2(p["pos"]), "radius": 62.0, "callback": func(): _tear_poster(pid)})


func enter_region(opts: Dictionary = {}) -> void:
	fx_sparks.clear()
	enemy_bolts.clear()
	breakout_enemies.clear()
	portal_cooldown = 0.85
	_ambush_triggered = false
	_torn_posters.clear()
	resonance_wave_t = 0.0
	abbey_vent_crawl_t = 0.0
	_abbey_lever_tripped = GameState.louvain_vent_opened
	abbey_gate_open_anim = 1.0 if GameState.louvain_vent_opened else 0.0
	_last_command_kind = ""
	GameState.active_perspective = "boy"
	GameState.book2_started = true
	if GameState.active_companion_stage < 1:
		GameState.active_companion_stage = 1
		GameState.brabant_hatched = true
	if int(GameState.current_step) < int(GameState.QuestStep.BOOK2_LOUVAIN_HATCH):
		GameState.current_step = GameState.QuestStep.BOOK2_LOUVAIN_HATCH
	GameState.unlock_realm_node("louvain")

	heat_helper.reset(MapData.get_wanted_posters())
	patrols.assign(MapData.get_catchpole_patrols())
	ambient_citizens.assign(MapData.get_ambient_citizens())

	var spawn: Vector2 = opts.get("spawn", MapData.WEST_ENTRY_SPAWN)
	player.position = spawn
	player.facing = opts.get("facing", Vector2.RIGHT)
	if not bool(opts.get("_retry_restore", false)):
		_snapshot_checkpoint(spawn, player.facing)
	player.visible = true
	player.cutscene_hidden = false
	player.can_move = true
	player.set_carry_prop("", "")

	set_body_collision_enabled(abbey_gate_body, not GameState.louvain_vent_opened)
	set_body_collision_enabled(south_gate_body, not GameState.louvain_breakout_won)

	if director != null and director.camera != null:
		director.camera.limit_left = 0
		director.camera.limit_top = 0
		director.camera.limit_right = int(MapData.WORLD_SIZE.x)
		director.camera.limit_bottom = int(MapData.WORLD_SIZE.y)
		director.camera.position = player.position

	_sync_hint_context()
	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.update_world_map_state("louvain", player.position)
	ui.refresh_hud()
	SoundManager.set_ambience(get_ambience_track())
	step_water_layer()
	queue_redraw()
	queue_foreground_redraw()


func exit_region() -> void:
	if director != null and director.companion != null:
		director.companion.clear_hint_context()


func handle_region_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 and heat_helper.drop_resonance_chime(player.position):
			_spawn_sparks(player.position, Color(0.96, 0.84, 0.40), 16)
			SoundManager.play_chime()
			ui.refresh_hud()
			return true
		if event.keycode == KEY_2 and heat_helper.trigger_smoke_pellet(player.position):
			_spawn_sparks(player.position, Color(0.70, 0.72, 0.78), 22)
			SoundManager.play_dodge()
			ui.refresh_hud()
			return true
	return false


func step_region(delta: float) -> void:
	step_water_layer()
	DrawHelper.step_citizens(ambient_citizens, player.position if player != null else Vector2.ZERO, delta)
	_step_fx(delta)
	if abbey_vent_crawl_t > 0.0:
		abbey_vent_crawl_t = maxf(0.0, abbey_vent_crawl_t - delta)
		var vprog := 1.0 - (abbey_vent_crawl_t / ABBEY_VENT_CRAWL_DUR)
		if vprog >= 0.72 and not _abbey_lever_tripped:
			_abbey_lever_tripped = true
			SoundManager.play_cage_break()
			SoundManager.play_door()
			_spawn_sparks(ABBEY_LEVER_POS, Color(0.98, 0.84, 0.36), 14)
			_spawn_sparks(MapData.ABBEY_GATE_RECT.get_center(), Color(0.76, 0.92, 0.64), 14)
	abbey_gate_open_anim = move_toward(abbey_gate_open_anim, 1.0 if _abbey_lever_tripped else 0.0, delta * 1.5)

	if not GameState.louvain_breakout_won and breakout_enemies.is_empty():
		var spotted := _step_patrols(delta)
		heat_helper.step(delta, spotted)
		if spotted and heat_helper.is_dragon_exposed_in_town() and GameState.city_heat < 98.0:
			GameState.add_city_heat(24.0 * delta)
		if GameState.city_heat >= 100.0 and not _ambush_triggered:
			_trigger_heat_ambush()
	elif not breakout_enemies.is_empty():
		_step_breakout_enemies(delta)
		_step_bolts(delta)

	if GameState.louvain_archive_read and not GameState.louvain_breakout_won and breakout_enemies.is_empty() and player.position.y > 748.0 and player.position.x > 1248.0 and player.position.x < 1560.0:
		_spawn_abbey_breakout()

	if director != null and director.camera != null and player != null:
		if abbey_vent_crawl_t > 0.0:
			director.camera.position = player.position.lerp((MapData.ABBEY_VENT_POS + MapData.ABBEY_GATE_RECT.get_center()) * 0.5, 0.5)
		else:
			director.camera.position = player.position

	if player != null and player.visible:
		update_nearest_interactable(player.position)
		if ui != null:
			ui.update_world_map_state("louvain", player.position)
	queue_redraw()
	queue_foreground_redraw()


func _step_patrols(delta: float) -> bool:
	var any_spotted := false
	var smoke_hidden := heat_helper.is_point_concealed_by_smoke(player.position)
	var sling_hidden := not heat_helper.is_dragon_exposed_in_town()
	for pat: Dictionary in patrols:
		if float(pat.get("stun", 0.0)) > 0.0:
			pat["stun"] = maxf(0.0, float(pat.get("stun", 0.0)) - delta)
			continue
		var gp: Vector2 = Vector2(pat["pos"])
		var lure: Vector2 = heat_helper.get_active_lure_near(gp, 240.0)
		if lure != Vector2.ZERO:
			pat["lure_timer"] = 0.25
			var ldir := compute_nav_move_dir(gp, lure, static_colliders, 10.0)
			if gp.distance_to(lure) > 22.0:
				pat["pos"] = steer_and_move_actor(gp, ldir, 72.0, delta, static_colliders, 10.0)
				pat["dir"] = (lure - gp).normalized()
		else:
			pat["lure_timer"] = maxf(0.0, float(pat.get("lure_timer", 0.0)) - delta)
			var pts: Array = pat["pts"]
			var wi: int = int(pat["wp"])
			var goal: Vector2 = Vector2(pts[wi])
			var to_g := goal - gp
			if to_g.length() < 12.0:
				wi = (wi + 1) % pts.size()
				pat["wp"] = wi
				goal = Vector2(pts[wi])
				to_g = goal - gp
			var dir := to_g.normalized() if to_g.length() > 1.0 else Vector2.RIGHT
			pat["dir"] = dir
			pat["pos"] = steer_and_move_actor(gp, dir, 64.0, delta, static_colliders, 10.0)

		if not smoke_hidden and can_vision_cone_see(Vector2(pat["pos"]), Vector2(pat["dir"]), player.position, 185.0, 0.48, sight_blockers, 26.0):
			if not sling_hidden or player.position.y < 690.0:
				any_spotted = true
	return any_spotted


func _trigger_heat_ambush() -> void:
	_ambush_triggered = true
	SoundManager.play_alert_horn()
	breakout_enemies.assign([
		_make_foe("shield", player.position + Vector2(-96, -42), Vector2.RIGHT),
		_make_foe("arbalester", player.position + Vector2(110, 48), Vector2.LEFT),
	])


func _spawn_abbey_breakout() -> void:
	if _ambush_triggered:
		return
	_ambush_triggered = true
	breakout_enemies.assign([
		_make_foe("shield", Vector2(1276, 782), Vector2.RIGHT),
		_make_foe("shield", Vector2(1414, 782), Vector2.LEFT),
		_make_foe("arbalester", Vector2(1306, 846), Vector2.UP),
		_make_foe("arbalester", Vector2(1394, 846), Vector2.UP),
	])
	SoundManager.play_alert_horn()
	ui.show_dialogue([
		{"speaker": "Catchpole Sergeant", "portrait": "portrait_watchman.png", "text": "Seal the Abbey steps! That apprentice just lifted the Old Heverlee writs—catch that wyrmling alive for twenty florins!"}
	])


func _snapshot_checkpoint(spawn_pos: Vector2, dir_v: Vector2) -> void:
	_checkpoint_state = {
		"spawn": spawn_pos,
		"facing": dir_v,
		"louvain_vent_opened": GameState.louvain_vent_opened,
		"louvain_brazier_lit": GameState.louvain_brazier_lit,
		"louvain_crypt_ladder_open": GameState.louvain_crypt_ladder_open,
		"louvain_crypt_treasure_open": GameState.louvain_crypt_treasure_open,
		"louvain_crypt_treasure_taken": GameState.louvain_crypt_treasure_taken,
		"louvain_found_1422": GameState.louvain_found_1422,
		"louvain_found_1426": GameState.louvain_found_1426,
		"louvain_archive_read": GameState.louvain_archive_read,
		"louvain_breakout_won": GameState.louvain_breakout_won,
		"louvain_bell_mould_fixed": GameState.louvain_bell_mould_fixed,
		"louvain_clay_collected": GameState.louvain_clay_collected,
		"louvain_herbalist_done": GameState.louvain_herbalist_done,
		"louvain_guild_visited": GameState.louvain_guild_visited,
		"louvain_ring_found": GameState.louvain_ring_found,
		"louvain_survivor_done": GameState.louvain_survivor_done,
		"louvain_mason_started": GameState.louvain_mason_started,
		"louvain_mason_stone_hauled": GameState.louvain_mason_stone_hauled,
		"louvain_mason_done": GameState.louvain_mason_done,
		"resonance_chimes": GameState.resonance_chimes,
		"smoke_pellets": GameState.smoke_pellets,
	}


func _restore_checkpoint() -> void:
	GameState.boy_hp = GameState.boy_max_hp
	GameState.city_heat = 0.0
	_ambush_triggered = false
	if not _checkpoint_state.is_empty():
		GameState.louvain_vent_opened = bool(_checkpoint_state.get("louvain_vent_opened", false))
		GameState.louvain_brazier_lit = bool(_checkpoint_state.get("louvain_brazier_lit", false))
		GameState.louvain_crypt_ladder_open = bool(_checkpoint_state.get("louvain_crypt_ladder_open", false))
		GameState.louvain_crypt_treasure_open = bool(_checkpoint_state.get("louvain_crypt_treasure_open", false))
		GameState.louvain_crypt_treasure_taken = bool(_checkpoint_state.get("louvain_crypt_treasure_taken", false))
		GameState.louvain_found_1422 = bool(_checkpoint_state.get("louvain_found_1422", false))
		GameState.louvain_found_1426 = bool(_checkpoint_state.get("louvain_found_1426", false))
		GameState.louvain_archive_read = bool(_checkpoint_state.get("louvain_archive_read", false))
		GameState.louvain_breakout_won = bool(_checkpoint_state.get("louvain_breakout_won", false))
		GameState.louvain_bell_mould_fixed = bool(_checkpoint_state.get("louvain_bell_mould_fixed", false))
		GameState.louvain_clay_collected = bool(_checkpoint_state.get("louvain_clay_collected", false))
		GameState.louvain_herbalist_done = bool(_checkpoint_state.get("louvain_herbalist_done", false))
		GameState.louvain_guild_visited = bool(_checkpoint_state.get("louvain_guild_visited", false))
		GameState.louvain_ring_found = bool(_checkpoint_state.get("louvain_ring_found", false))
		GameState.louvain_survivor_done = bool(_checkpoint_state.get("louvain_survivor_done", false))
		GameState.louvain_mason_started = bool(_checkpoint_state.get("louvain_mason_started", false))
		GameState.louvain_mason_stone_hauled = bool(_checkpoint_state.get("louvain_mason_stone_hauled", false))
		GameState.louvain_mason_done = bool(_checkpoint_state.get("louvain_mason_done", false))
		GameState.resonance_chimes = int(_checkpoint_state.get("resonance_chimes", 0))
		GameState.smoke_pellets = int(_checkpoint_state.get("smoke_pellets", 0))
	var cp_spawn: Vector2 = _checkpoint_state.get("spawn", MapData.WEST_ENTRY_SPAWN)
	var cp_dir: Vector2 = _checkpoint_state.get("facing", Vector2.RIGHT)
	enter_region({"spawn": cp_spawn, "facing": cp_dir, "_retry_restore": true})


func _make_foe(kind: String, pos: Vector2, dir: Vector2) -> Dictionary:
	return {"kind": kind, "pos": pos, "dir": dir, "hp": 3 if kind == "shield" else 2, "has_shield": kind == "shield", "shield_yanked": false, "alive": true, "stun": 0.0, "stunned_t": 0.0, "snared_t": 0.0, "timer": 0.6, "state": "chase" if kind == "shield" else "reload"}


func _step_breakout_enemies(delta: float) -> void:
	for e: Dictionary in breakout_enemies:
		if int(e["hp"]) <= 0:
			continue
		if bool(e.get("permanently_bound", false)):
			continue
		if float(e.get("snared_t", 0.0)) > 0.0:
			e["snared_t"] = maxf(0.0, float(e.get("snared_t", 0.0)) - delta)
		if float(e["stun"]) > 0.0:
			e["stun"] = maxf(0.0, float(e["stun"]) - delta)
		if float(e["stun"]) > 0.0 or float(e.get("snared_t", 0.0)) > 0.0:
			continue
		var ep: Vector2 = Vector2(e["pos"])
		var to_p := player.position - ep
		var dist := to_p.length()
		var nd := to_p.normalized() if dist > 1.0 else Vector2.DOWN
		if String(e["kind"]) == "shield":
			var mv := compute_nav_move_dir(ep, player.position, static_colliders, 10.0)
			e["dir"] = nd if dist < 90.0 else mv
			if dist > 48.0:
				e["pos"] = steer_and_move_actor(ep, mv, 96.0, delta, static_colliders, 10.0, breakout_enemies, e)
			e["timer"] = float(e["timer"]) - delta
			if dist <= 52.0 and float(e["timer"]) <= 0.0:
				e["timer"] = 1.05
				if not player.is_invulnerable():
					_damage_player(1)
		else:
			var los := has_clear_line(ep, player.position, static_colliders, 5.0)
			e["dir"] = nd
			if dist > 260.0 or not los:
				var amv := compute_nav_move_dir(ep, player.position, static_colliders, 10.0)
				e["pos"] = steer_and_move_actor(ep, amv, 82.0, delta, static_colliders, 10.0, breakout_enemies, e)
			e["timer"] = float(e["timer"]) - delta
			if los and float(e["timer"]) <= 0.0:
				e["timer"] = 1.65
				enemy_bolts.append({"pos": ep + Vector2(0, -10) + nd * 16.0, "dir": nd, "life": 1.6})
				SoundManager.play_bolt()


func _step_bolts(delta: float) -> void:
	for i in range(enemy_bolts.size() - 1, -1, -1):
		var b: Dictionary = enemy_bolts[i]
		b["pos"] = Vector2(b["pos"]) + Vector2(b["dir"]) * 320.0 * delta
		b["life"] = float(b["life"]) - delta
		var bp := Vector2(b["pos"])
		if point_hits_colliders(bp, static_colliders, 4.0) or float(b["life"]) <= 0.0:
			enemy_bolts.remove_at(i)
		elif bp.distance_to(player.position) <= 18.0 and not player.is_invulnerable():
			enemy_bolts.remove_at(i)
			_damage_player(1)


func _damage_player(dmg: int) -> void:
	GameState.boy_hp = maxi(0, GameState.boy_hp - dmg)
	player.hurt_flash_timer = 0.35
	SoundManager.play_hit()
	director.trigger_camera_shake(6.0, 0.22)
	ui.refresh_hud()
	if GameState.boy_hp <= 0:
		breakout_enemies.clear()
		enemy_bolts.clear()
		ui.show_death_screen("Cornered by Church Catchpoles on the Louvain cobbles.", Callable(self, "_restore_checkpoint"))


func on_knife_slash(tip_pos: Vector2, _dir: Vector2) -> void:
	for i in range(enemy_bolts.size() - 1, -1, -1):
		if Vector2(enemy_bolts[i]["pos"]).distance_to(tip_pos) <= 34.0:
			enemy_bolts.remove_at(i)
			SoundManager.play_chime()
	var meta: Dictionary = player.get_last_slash_meta()
	var dmg: int = int(meta.get("damage", 1))
	var any_down := false
	for e: Dictionary in breakout_enemies:
		if int(e["hp"]) <= 0:
			continue
		var ep := Vector2(e["pos"])
		if ep.distance_to(tip_pos) > 48.0:
			continue
		var is_snared := float(e.get("snared_t", 0.0)) > 0.0
		var is_stunned := float(e.get("stun", 0.0)) > 0.0
		if bool(e.get("has_shield", false)) and not bool(meta.get("is_counter", false)) and not is_snared and not is_stunned:
			_spawn_sparks(ep + Vector2(0, -8), Color(0.86, 0.88, 0.94), 8)
			SoundManager.play_knot_snag()
			continue
		e["hp"] = int(e["hp"]) - (dmg + (1 if is_snared else 0))
		e["stun"] = maxf(float(e.get("stun", 0.0)), 0.35)
		_spawn_sparks(ep + Vector2(0, -10), Color(0.98, 0.38, 0.28), 10)
		SoundManager.play_hit()
		if int(e["hp"]) <= 0:
			e["alive"] = false
			any_down = true
	if any_down:
		_check_breakout_clear()


func on_rope_cast_hit(target_pos: Vector2, knot_id: String) -> void:
	if target_pos.distance_to(MapData.FOUNDRY_WINCH_POS) <= 72.0:
		QuestsHelper.repair_foundry_hoist(self, MapData, knot_id)
		return
	if target_pos.distance_to(MapData.MASON_CRANE_POS) <= 72.0:
		QuestsHelper.open_crane_builder(self)
		return
	if target_pos.distance_to(MapData.HERBALIST_SLUICE_POS) <= 72.0:
		QuestsHelper.clear_herbalist_sluice(self, MapData)
		return
	var res := PlayerCombatHelperScript.resolve_knot_targets(knot_id, player.position, target_pos, breakout_enemies)
	if bool(res.get("hit", false)):
		for e: Dictionary in breakout_enemies:
			if bool(e.get("permanently_bound", false)):
				e["stun"] = 9999.0
			elif float(e.get("snared_t", 0.0)) > 0.0 or float(e.get("stunned_t", 0.0)) > 0.0:
				e["stun"] = maxf(float(e.get("stun", 0.0)) if float(e.get("stun", 0.0)) < 100.0 else 0.0, maxf(float(e.get("stunned_t", 0.0)), float(e.get("snared_t", 0.0))))
			elif float(e.get("stun", 0.0)) > 100.0:
				e["stun"] = 0.0
			e["stunned_t"] = 0.0
		for b in res.get("bound", []):
			_spawn_sparks(Vector2(b["pos"]), Color(0.95, 0.72, 0.24), 14)
		for yanked in res.get("yanked", []):
			_spawn_sparks(Vector2(yanked["pos"]), Color(0.98, 0.56, 0.30), 16)
			SoundManager.play_cage_break()
		for snared in res.get("snared", []):
			snared["snared_t"] = maxf(float(snared.get("snared_t", 0.0)), 3.2)
			snared["stun"] = maxf(float(snared.get("stun", 0.0)), 3.2)
			_spawn_sparks(Vector2(snared["pos"]), Color(0.45, 0.90, 0.72), 14)
		var zipped = res.get("zipped_target", null)
		if zipped != null:
			player.position = Vector2(zipped["pos"]) + (player.position - Vector2(zipped["pos"])).normalized() * 24.0
			var z_dmg := 3 if float(zipped.get("snared_t", 0.0)) > 0.0 else 2
			zipped["hp"] = int(zipped["hp"]) - z_dmg
			zipped["alive"] = int(zipped["hp"]) > 0
			_spawn_sparks(Vector2(zipped["pos"]), Color(1.0, 0.84, 0.32), 18)
		SoundManager.play_rope()
		_check_breakout_clear()
		return

	# Allow rope casts to ensnare / startle patrolling city guards along the cast line!
	if breakout_enemies.is_empty():
		var hit_r := 76.0 if knot_id == "bowline" else 48.0
		var snared_any := false
		for pat: Dictionary in patrols:
			var gp: Vector2 = Vector2(pat["pos"])
			var cp := Geometry2D.get_closest_point_to_segment(gp, player.position, target_pos)
			if gp.distance_to(cp) <= hit_r:
				pat["stun"] = 3.2
				snared_any = true
				_spawn_sparks(gp + Vector2(0, -10), Color(0.45, 0.90, 0.72), 12)
		if snared_any:
			SoundManager.play_rope()


func _check_breakout_clear() -> void:
	for e: Dictionary in breakout_enemies:
		if int(e["hp"]) > 0:
			return
	breakout_enemies.clear()
	enemy_bolts.clear()
	if GameState.louvain_archive_read and not GameState.louvain_breakout_won:
		GameState.louvain_breakout_won = true
		GameState.city_heat = 0.0
		GameState.add_dragon_bond(15)
		set_body_collision_enabled(south_gate_body, false)
		resonance_wave_origin = player.position
		resonance_wave_t = 1.1
		SoundManager.play_dragon_cry()
		SoundManager.play_chime()
		director.trigger_camera_shake(6.5, 0.32)
		_spawn_sparks(player.position, Color(1.0, 0.88, 0.38), 32)
		if director != null and director.companion != null:
			director.companion.notify_progress()
		_sync_hint_context()
		ui.show_dialogue([
			{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "The road south is jarred wide open. Iron chains tremble when our fire sings through them—Old Heverlee awaits beyond the wall."}
		])
	ui.refresh_hud()


func get_gold_sense_targets() -> Array:
	var t: Array = []
	if not GameState.louvain_vent_opened:
		t.append(MapData.ABBEY_VENT_POS)
	elif not GameState.louvain_archive_read:
		t.append(MapData.CATHEDRAL_DOOR_PORTAL_RECT.get_center())
	if not GameState.louvain_ring_found:
		t.append(MapData.CONFISCATED_CHEST_POS)
	return t


func get_last_dragon_command_kind() -> String:
	return _last_command_kind


func get_vent_crawl_duration() -> float:
	return ABBEY_VENT_CRAWL_DUR


func get_vent_return_pos() -> Vector2:
	return Vector2(1338, 792)


func find_dragon_command_target(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> Dictionary:
	var ppos := player.position if player != null else origin
	if not GameState.louvain_vent_opened and (origin.distance_to(MapData.ABBEY_VENT_POS) <= 92.0 or ppos.distance_to(MapData.ABBEY_VENT_POS) <= 92.0 or target_pos.distance_to(MapData.ABBEY_VENT_POS) <= 84.0):
		return {"kind": "vent_crawl", "target_pos": MapData.ABBEY_VENT_POS, "stand_pos": MapData.ABBEY_VENT_POS + Vector2(0, 22)}
	if not GameState.louvain_herbalist_done and (origin.distance_to(MapData.HERBALIST_SLUICE_POS) <= 105.0 or ppos.distance_to(MapData.HERBALIST_SLUICE_POS) <= 105.0 or target_pos.distance_to(MapData.HERBALIST_SLUICE_POS) <= 96.0):
		var sdir := (ppos - MapData.HERBALIST_SLUICE_POS).normalized() if ppos.distance_to(MapData.HERBALIST_SLUICE_POS) > 1.0 else Vector2.DOWN
		return {"kind": "ember_puff", "target_pos": MapData.HERBALIST_SLUICE_POS, "stand_pos": MapData.HERBALIST_SLUICE_POS + sdir * 26.0}
	return {}


func on_dragon_command(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> bool:
	_last_command_kind = ""
	if not GameState.louvain_vent_opened and (origin.distance_to(MapData.ABBEY_VENT_POS) <= 78.0 or target_pos.distance_to(MapData.ABBEY_VENT_POS) <= 68.0):
		_last_command_kind = "vent_crawl"
		GameState.louvain_vent_opened = true
		abbey_vent_crawl_t = ABBEY_VENT_CRAWL_DUR
		_abbey_lever_tripped = false
		abbey_gate_open_anim = 0.0
		set_body_collision_enabled(abbey_gate_body, false)
		_spawn_sparks(MapData.ABBEY_VENT_POS + Vector2(0, 12), Color(0.56, 0.58, 0.62), 8)
		if director != null and director.companion != null:
			director.companion.notify_progress()
		_sync_hint_context()
		return true
	if not GameState.louvain_herbalist_done and (origin.distance_to(MapData.HERBALIST_SLUICE_POS) <= 86.0 or target_pos.distance_to(MapData.HERBALIST_SLUICE_POS) <= 82.0):
		_last_command_kind = "ember_puff"
		QuestsHelper.clear_herbalist_sluice(self, MapData)
		return true
	return false


func _tear_poster(pid: String) -> void:
	if heat_helper.tear_poster(pid):
		_torn_posters[pid] = true
		_spawn_sparks(player.position + Vector2(0, -10), Color(0.94, 0.84, 0.56), 10)
		ui.refresh_hud()


func _on_enter_catacombs() -> void:
	SoundManager.play_door()
	director.load_region("louvain_catacombs", {"from_cloister": true})


func _on_read_south_sign() -> void:
	ui.show_parchment_note("Naamsepoort South Post", "\"OLD HEVERLEE WOODS & ABBEY FOREST TRAIL — 3 LEAGUES SOUTH.\"", "Louvain City Roadhouse")


func _on_exit_west() -> void:
	director.load_region("brabant_fens", {"spawn": Vector2(2040, 710), "facing": Vector2.LEFT, "hatched_state": true})


func _on_exit_south() -> void:
	if not is_portal_unlocked("louvain_south_heverlee"):
		trigger_story_roadblock(
			Vector2(1030, 1945),
			"Naamsepoort Sentinel",
			"portrait_watchman.png",
			"Curfew bars stay bolted on Naamsepoort while Catchpoles sweep the Cloister!",
			Vector2(0, -40)
		)
		return
	director.load_region("old_heverlee", {"spawn": Vector2(1100, 128), "facing": Vector2.DOWN})


func is_portal_unlocked(id: String) -> bool:
	if id == "louvain_south_heverlee":
		return GameState.louvain_breakout_won
	return true


func is_interactable_active(id: String) -> bool:
	if id == "lv_clay":
		return not GameState.louvain_clay_collected and not GameState.louvain_bell_mould_fixed
	if id == "lv_mason_stone":
		return not GameState.louvain_mason_stone_hauled and not GameState.louvain_mason_done
	if id == "lv_mason_crane":
		return not GameState.louvain_mason_done
	if id == "lv_ring_chest":
		return not GameState.louvain_ring_found and not GameState.louvain_survivor_done
	for p: Dictionary in MapData.get_wanted_posters():
		if String(p["id"]) == id:
			return not _torn_posters.has(id)
	return true


func _sync_hint_context() -> void:
	if director == null or director.companion == null:
		return
	if not GameState.louvain_vent_opened:
		director.companion.set_hint_context(
			"lv_vent",
			["Too many halberds out front of the Abbey gate... tucked behind the eastern stone wall sits a low iron drain grate."],
			MapData.ABBEY_VENT_POS,
			30.0
		)
	elif not GameState.louvain_archive_read:
		director.companion.set_hint_context(
			"lv_cathedral",
			["Now we're inside the walled precinct! Those tall Cathedral oak doors ahead should lead down into their vaults."],
			MapData.CATHEDRAL_DOOR_PORTAL_RECT.get_center(),
			24.0
		)
	elif GameState.louvain_archive_read and not GameState.louvain_breakout_won:
		director.companion.set_hint_context(
			"lv_shields",
			["Tower shields shrug off short dock knives straight on—heavy tarred hemp snatches oak shields right off their wrists!"],
			Vector2(1344, 800),
			24.0
		)
	else:
		director.companion.clear_hint_context()


func _step_fx(delta: float) -> void:
	if resonance_wave_t > 0.0:
		resonance_wave_t = maxf(0.0, resonance_wave_t - delta)
	for i in range(fx_sparks.size() - 1, -1, -1):
		var sp: Dictionary = fx_sparks[i]
		sp["life"] = float(sp["life"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		if float(sp["life"]) <= 0.0:
			fx_sparks.remove_at(i)


func _spawn_sparks(origin: Vector2, col: Color, count: int = 12) -> void:
	for _i in range(count):
		var a := randf() * TAU
		var s := randf_range(28.0, 96.0)
		fx_sparks.append({"pos": origin, "vel": Vector2(cos(a), sin(a)) * s, "life": randf_range(0.28, 0.55), "max_life": 0.55, "sz": randf_range(2.2, 4.0), "col": col})


func get_surface_at(pos: Vector2) -> String:
	for br: Dictionary in MapData.get_bridges():
		if Rect2(br["rect"]).has_point(pos):
			return "cobble"
	return "cobble"


func get_active_npc_colliders() -> Array:
	var list: Array = [
		{"pos": NPC_PIETER_POS, "yield_key": "lv_pieter"},
		{"pos": NPC_MASON_POS, "yield_key": "lv_mason"},
		{"pos": NPC_SCHOLAR_POS, "yield_key": "lv_scholar"},
		{"pos": NPC_ALEIDIS_POS, "yield_key": "lv_aleidis"},
		{"pos": NPC_MARTIJN_POS, "yield_key": "lv_martijn"},
		{"pos": NPC_KATELIJNE_POS, "yield_key": "lv_katelijne"},
	]
	for ct: Dictionary in ambient_citizens:
		list.append({"pos": Vector2(ct["pos"]), "yield_key": "lv_cit_%s" % str(ct.get("name", ""))})
	if not GameState.louvain_breakout_won and breakout_enemies.is_empty():
		for pat: Dictionary in patrols:
			list.append(Vector2(pat["pos"]))
	for e: Dictionary in breakout_enemies:
		if int(e.get("hp", 0)) > 0:
			list.append(Vector2(e["pos"]))
	return list


func get_ambience_track() -> String:
	for e: Dictionary in breakout_enemies:
		if int(e.get("hp", 0)) > 0:
			return "amb_combat"
	if GameState.city_heat >= 0.40:
		return "amb_stealth"
	return "amb_dawn_tension"


func get_lighting_tint() -> Color:
	return Color(0.84, 0.80, 0.86)


func update_region_lights(_time_val: float) -> void:
	sync_light_frustum(city_lights, true)


func _draw() -> void:
	DrawHelper.draw_region_entities(self, Time.get_ticks_msec() * 0.001)
