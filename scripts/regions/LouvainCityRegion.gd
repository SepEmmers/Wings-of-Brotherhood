extends "res://scripts/regions/RegionBase.gd"

## Book II Act I Hub 1 — Louvain (City of Bells & Locked Archives, 2400x1800):
## Cloak-Sling concealment & Bounty Heat (CityHeatHelper), 3 city side stories,
## Abbey Scriptorium Vent Crawl + Ember Puff infiltration, and Forecourt Breakout
## featuring 3-hit Knife combo, Dodge-Counter, Whipping Shield-Yank & Golden Burst.

const MapData := preload("res://scripts/regions/LouvainCityMapData.gd")
const DrawHelper := preload("res://scripts/regions/LouvainCityDraw.gd")
const CityHeatHelperScript := preload("res://scripts/systems/CityHeatHelper.gd")
const PlayerCombatHelperScript := preload("res://scripts/systems/PlayerCombatHelper.gd")

const NPC_PIETER_POS := Vector2(380, 412)
const NPC_ALEIDIS_POS := Vector2(332, 1296)
const NPC_MARTIJN_POS := Vector2(536, 1296)
const NPC_KATELIJNE_POS := Vector2(1788, 1184)
const ABBEY_BRAZIERS: Array[Vector2] = [Vector2(1788, 496), Vector2(1980, 496)]

var static_colliders: Array[Rect2] = []
var sight_blockers: Array[Rect2] = []
var abbey_gate_body: StaticBody2D
var south_gate_body: StaticBody2D
var city_lights: Array[PointLight2D] = []
var abbey_lights: Array[PointLight2D] = []

var heat_helper = CityHeatHelperScript.new()
var patrols: Array[Dictionary] = []
var breakout_enemies: Array[Dictionary] = []
var enemy_bolts: Array[Dictionary] = []
var fx_sparks: Array[Dictionary] = []
var resonance_wave_t: float = 0.0
var resonance_wave_origin: Vector2 = Vector2.ZERO
var _ambush_triggered: bool = false
var _torn_posters: Dictionary = {}


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

	for lp: Vector2 in [
		Vector2(380, 380), Vector2(980, 860), Vector2(1340, 560),
		Vector2(360, 1240), Vector2(1780, 1140), Vector2(1844, 660),
	]:
		var pl: PointLight2D = assets.make_point_light(lp, 2.5, Color(1.0, 0.78, 0.44), 0.72)
		add_child(pl)
		city_lights.append(pl)
	for bz: Vector2 in ABBEY_BRAZIERS:
		var abl: PointLight2D = assets.make_point_light(bz + Vector2(0, -10), 2.8, Color(1.0, 0.80, 0.36), 0.85)
		abl.visible = false
		add_child(abl)
		abbey_lights.append(abl)
		city_lights.append(abl)

	DrawHelper.setup_layers(self)
	_build_interactables()
	clear_walk_portals()
	register_walk_portal("louvain_west_fens", Rect2(64, 816, 48, 128), Vector2.LEFT, _on_exit_west, "<- Brabant Fens", "BRABANT REED-FENS", "Mill Ruins & Dikes")
	register_walk_portal("louvain_south_heverlee", Rect2(1136, 1734, 128, 66), Vector2.DOWN, _on_exit_south, "v Old Heverlee Woods", "OLD HEVERLEE TRAIL", "Hunters' Woods South")


func _build_interactables() -> void:
	interactables = [
		{"id": "lv_pieter", "name": "Deaf Bell-Founder Pieter", "pos": NPC_PIETER_POS, "radius": 72.0, "callback": _on_interact_pieter},
		{"id": "lv_winch", "name": "Foundry Bell Hoist ([F])", "pos": MapData.FOUNDRY_WINCH_POS, "radius": 70.0, "callback": func(): _repair_foundry_hoist()},
		{"id": "lv_clay", "name": "Dijle River Clay Bank", "pos": MapData.CLAY_BANK_POS, "radius": 68.0, "callback": _on_interact_clay},
		{"id": "lv_aleidis", "name": "Guildmistress Aleidis", "pos": NPC_ALEIDIS_POS, "radius": 72.0, "callback": _on_interact_aleidis},
		{"id": "lv_martijn", "name": "One-Eyed Veteran Martijn", "pos": NPC_MARTIJN_POS, "radius": 72.0, "callback": _on_interact_martijn},
		{"id": "lv_katelijne", "name": "Herbalist Sister Katelijne", "pos": NPC_KATELIJNE_POS, "radius": 72.0, "callback": _on_interact_katelijne},
		{"id": "lv_sluice", "name": "Herbalist Dye-Sluice ([F] / [R])", "pos": MapData.HERBALIST_SLUICE_POS, "radius": 72.0, "callback": func(): _clear_herbalist_sluice()},
		{"id": "lv_ring_chest", "name": "Confiscated Watch Chest", "pos": MapData.CONFISCATED_CHEST_POS, "radius": 68.0, "callback": _on_interact_ring_chest},
		{"id": "lv_archive", "name": "Chained Scriptorium Decrees", "pos": MapData.ARCHIVE_DESK_POS, "radius": 76.0, "callback": _on_interact_archive},
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

	var spawn: Vector2 = opts.get("spawn", Vector2(150, 880))
	player.position = spawn
	player.facing = opts.get("facing", Vector2.RIGHT)
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
	step_walk_portals(delta)
	_step_fx(delta)

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

	if GameState.louvain_archive_read and not GameState.louvain_breakout_won and breakout_enemies.is_empty() and player.position.y > 708.0 and player.position.x > 1640.0:
		_spawn_abbey_breakout()

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
		_make_foe("shield", Vector2(1748, 764), Vector2.RIGHT),
		_make_foe("shield", Vector2(1930, 764), Vector2.LEFT),
		_make_foe("arbalester", Vector2(1788, 860), Vector2.UP),
		_make_foe("arbalester", Vector2(1912, 860), Vector2.UP),
	])
	SoundManager.play_alert_horn()
	ui.show_dialogue([
		{"speaker": "Catchpole Sergeant", "portrait": "portrait_watchman.png", "text": "Seal the Abbey steps! That apprentice just lifted the Old Heverlee writs—catch that wyrmling alive for twenty florins!"}
	])


func _make_foe(kind: String, pos: Vector2, dir: Vector2) -> Dictionary:
	return {"kind": kind, "pos": pos, "dir": dir, "hp": 3 if kind == "shield" else 2, "has_shield": kind == "shield", "alive": true, "stun": 0.0, "timer": 0.6, "state": "chase" if kind == "shield" else "reload"}


func _step_breakout_enemies(delta: float) -> void:
	for e: Dictionary in breakout_enemies:
		if int(e["hp"]) <= 0:
			continue
		if float(e["stun"]) > 0.0:
			e["stun"] = maxf(0.0, float(e["stun"]) - delta)
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
		ui.show_death_screen("Cornered by Church Catchpoles on the Louvain cobbles.", func():
			GameState.boy_hp = GameState.boy_max_hp
			GameState.city_heat = 0.0
			_ambush_triggered = false
			enter_region({"spawn": Vector2(150, 880), "facing": Vector2.RIGHT})
		)


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
		if bool(e.get("has_shield", false)) and not bool(meta.get("is_counter", false)):
			_spawn_sparks(ep + Vector2(0, -8), Color(0.86, 0.88, 0.94), 8)
			SoundManager.play_knot_snag()
			continue
		e["hp"] = int(e["hp"]) - dmg
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
		_repair_foundry_hoist(knot_id)
		return
	if target_pos.distance_to(MapData.HERBALIST_SLUICE_POS) <= 72.0:
		_clear_herbalist_sluice()
		return
	var res := PlayerCombatHelperScript.resolve_knot_targets(knot_id, player.position, target_pos, breakout_enemies)
	if bool(res.get("hit", false)):
		for yanked in res.get("yanked", []):
			_spawn_sparks(Vector2(yanked["pos"]), Color(0.98, 0.84, 0.38), 14)
		for snared in res.get("snared", []):
			snared["stun"] = 2.6
			_spawn_sparks(Vector2(snared["pos"]), Color(0.45, 0.90, 0.72), 10)
		var zipped = res.get("zipped_target", null)
		if zipped != null:
			player.position = Vector2(zipped["pos"]) + (player.position - Vector2(zipped["pos"])).normalized() * 24.0
			zipped["hp"] = int(zipped["hp"]) - 2
			zipped["alive"] = int(zipped["hp"]) > 0
			_spawn_sparks(Vector2(zipped["pos"]), Color(1.0, 0.84, 0.32), 18)
		SoundManager.play_rope()
		_check_breakout_clear()


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
	elif not GameState.louvain_brazier_lit:
		t.append(ABBEY_BRAZIERS[0])
	elif not GameState.louvain_archive_read:
		t.append(MapData.ARCHIVE_DESK_POS)
	if not GameState.louvain_ring_found:
		t.append(MapData.CONFISCATED_CHEST_POS)
	return t


func on_dragon_command(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> bool:
	if not GameState.louvain_vent_opened and (origin.distance_to(MapData.ABBEY_VENT_POS) <= 95.0 or target_pos.distance_to(MapData.ABBEY_VENT_POS) <= 90.0):
		GameState.louvain_vent_opened = true
		set_body_collision_enabled(abbey_gate_body, false)
		SoundManager.play_cage_break()
		SoundManager.play_door()
		_spawn_sparks(MapData.ABBEY_VENT_POS, Color(1.0, 0.86, 0.36), 18)
		if director != null and director.companion != null:
			director.companion.notify_progress()
		_sync_hint_context()
		return true
	if GameState.louvain_vent_opened and not GameState.louvain_brazier_lit:
		for bz: Vector2 in ABBEY_BRAZIERS:
			if origin.distance_to(bz) <= 130.0 or target_pos.distance_to(bz) <= 115.0:
				GameState.louvain_brazier_lit = true
				SoundManager.play_campfire_warm()
				for bz2: Vector2 in ABBEY_BRAZIERS:
					_spawn_sparks(bz2 + Vector2(0, -10), Color(1.0, 0.78, 0.28), 16)
				if director != null and director.companion != null:
					director.companion.notify_progress()
				_sync_hint_context()
				return true
	return false


func _tear_poster(pid: String) -> void:
	if heat_helper.tear_poster(pid):
		_torn_posters[pid] = true
		_spawn_sparks(player.position + Vector2(0, -10), Color(0.94, 0.84, 0.56), 10)
		ui.refresh_hud()


func _on_interact_clay() -> void:
	if GameState.louvain_clay_collected or GameState.louvain_bell_mould_fixed:
		return
	GameState.louvain_clay_collected = true
	GameState.add_item("Dijle River Clay")
	SoundManager.play_chime()
	ui.pulse_hud_icon("bag")


func _on_interact_pieter() -> void:
	if GameState.louvain_bell_mould_fixed:
		ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Listen to that bronze timbre ring cleanly across the Dijle! Carry those Resonance Chimes safely—ring one down an alley and Catchpoles chase echoes all day."}])
		return
	if GameState.louvain_clay_collected:
		ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Aye—fine blue Dijle clay! Now lay a tight rope hitch onto the foundry gantry wheel beside the mould so I can draw the jacket true."}])
		return
	ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "The Church Catchpoles ordered six alarm-bells overnight and cracked my master mould! Dig wet clay down by the Dijle river bank and haul my gantry pulley taut if you want proper bronze Resonance Chimes."}])


func _repair_foundry_hoist(_knot_id: String = "") -> void:
	if GameState.louvain_bell_mould_fixed:
		return
	if not GameState.louvain_clay_collected:
		ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Hold up lad—pack wet alluvial clay from the Dijle River Slip first before hoisting the casing!"}])
		return
	ui.open_knot_minigame("clove_hitch", func(_id: String):
		GameState.louvain_bell_mould_fixed = true
		GameState.remove_item("Dijle River Clay")
		GameState.resonance_chimes += 2
		GameState.add_item("Bronze Resonance Chime")
		GameState.add_dragon_bond(5)
		SoundManager.play_chime()
		ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Seated tight as Flemish oak! Take two tuned Bronze Resonance Chimes—and slip into your hood whenever Catchpoles pace the bridge."}])
		ui.refresh_hud()
	)


func _on_interact_aleidis() -> void:
	GameState.louvain_guild_visited = true
	ui.refresh_hud()
	ui.show_dialogue([
		{"speaker": "Guildmistress Aleidis", "portrait": "portrait_clara.png", "text": "Bless me—you have your mother's eyes, %s! Years back after your parents rode out to Old Heverlee, they marched straight into this tavern and burned their Church hunting seals in the hearth." % GameState.player_name},
		{"speaker": "Guildmistress Aleidis", "portrait": "portrait_clara.png", "text": "Swore someone above St. Donatian's altar was excavating something older than Flanders. Two nights later, men in black tabards seized every deed from the Abbey Scriptorium northeast across the bridge."}
	])


func _on_interact_martijn() -> void:
	if GameState.louvain_survivor_done:
		ui.show_dialogue([{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "The High Inquisitor never told the parish a dragon killed your folks—he paid crossbowmen to ambush us by an ancient gold-carved stone vault in Old Heverlee."}])
		return
	if GameState.louvain_ring_found:
		GameState.louvain_survivor_done = true
		GameState.remove_item("Old Hunters' Brass Signet")
		GameState.add_dragon_bond(10)
		SoundManager.play_chime()
		ui.show_dialogue([
			{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "My old Oak-and-Hound signet! You pulled it back from those Abbey thieves..."},
			{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "Hear the truth then, boy: no beast slaughtered your mother and father at Old Heverlee. Church Inquisitors rode down our camp when your father refused to hand over a bronze shrine key they dug out beneath the oaks!"}
		])
		return
	ui.show_dialogue([{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "Leave an old one-eyed hunter to his ale, lad... unless you pry my Oak-and-Hound signet ring back from the watch chest Catchpoles locked away over in Dyers' Quarter."}])


func _on_interact_katelijne() -> void:
	if GameState.louvain_herbalist_done:
		ui.show_dialogue([{"speaker": "Sister Katelijne", "portrait": "portrait_maren.png", "text": "Keep those Smoke-Pellets beside your belt—cast one under foot if Catchpole crossbows lock the square, and search our rear watch-crate for confiscated guild trinkets."}])
		return
	ui.show_dialogue([{"speaker": "Sister Katelijne", "portrait": "portrait_maren.png", "text": "Rust wedged my dye-vat sluice shut while Catchpoles camp at the gate! Snap the jammed lever free with a strong rope or warm ember and I'll pack fresh Smoke-Pellets for you."}])


func _clear_herbalist_sluice() -> void:
	if GameState.louvain_herbalist_done:
		return
	GameState.louvain_herbalist_done = true
	GameState.smoke_pellets += 2
	GameState.add_item("Smoke-Pellet")
	GameState.add_dragon_bond(5)
	SoundManager.play_chime()
	_spawn_sparks(MapData.HERBALIST_SLUICE_POS, Color(0.55, 0.90, 0.68), 16)
	ui.show_dialogue([{"speaker": "Sister Katelijne", "portrait": "portrait_maren.png", "text": "Clean water at last! Here—two ash-and-wax Smoke-Pellets. Oh, and Catchpoles dumped an old hunter's brass signet inside the wooden watch-chest south down our lane."}])
	ui.refresh_hud()


func _on_interact_ring_chest() -> void:
	if GameState.louvain_ring_found or GameState.louvain_survivor_done:
		return
	GameState.louvain_ring_found = true
	GameState.add_item("Old Hunters' Brass Signet")
	SoundManager.play_chime()
	ui.pulse_hud_icon("bag")


func _on_interact_archive() -> void:
	if not GameState.louvain_brazier_lit:
		ui.show_dialogue([{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "The stone vault swallows all light here—how can you read ink in the dark? Those two unlit brass sconces flanking the desk look dry enough for a spark."}])
		return
	if GameState.louvain_archive_read:
		ui.show_dialogue([{"speaker": "Abbey Decree & Warrant", "portrait": "portrait_inquisitor.png", "text": "\"Old Heverlee Shrine Key missing; hunters silenced. Prisoner Clara of Bruges moved east to Namur Quarry Rig-Works pending Devildragon chain trials.\""}])
		return
	GameState.louvain_archive_read = true
	GameState.add_item("Abbey Scriptorium Decree")
	GameState.add_dragon_bond(10)
	SoundManager.play_chime()
	ui.pulse_hud_icon("journal")
	ui.show_dialogue([
		{"speaker": "Chained Abbey Decree", "portrait": "portrait_inquisitor.png", "text": "\"MEMORANDUM — NINE YEARS PAST: Hunters of Louvain Parish intercepted at Old Heverlee Woods over the unrecovered Bronze Shrine Key. Official parish tally recorded as dragon casualties.\""},
		{"speaker": "Namur Requisition Warrant", "portrait": "portrait_inquisitor.png", "text": "\"FIVE YEARS PAST — HIGH PRIORITY: Abduct Ropewalk rig-master CLARA OF BRUGES for forced heavy harness fabrication at Namur Cliff-Citadel. Further inquiry connects her bloodline to the Old Heverlee pair.\""},
		{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Your hands are shaking... They stole her too, and she's still alive east along the river! Wait—boots clattering across the Abbey flagstones outside!"}
	], func():
		_sync_hint_context()
		ui.refresh_hud()
	)


func _on_read_south_sign() -> void:
	ui.show_dialogue([{"speaker": "South Post Sign", "portrait": "portrait_baker.png", "text": "\"OLD HEVERLEE WOODS & ABBEY FOREST TRAIL — 3 LEAGUES SOUTH.\""}])


func _on_exit_west() -> void:
	director.load_region("brabant_fens", {"spawn": Vector2(2040, 710), "facing": Vector2.LEFT, "hatched_state": true})


func _on_exit_south() -> void:
	ui.show_chapter_checkpoint(
		"ACT I PART 1 COMPLETE — SOUTH GATE BREACHED",
		"Uncovered the Church Decrees inside Louvain and blasted clear toward Old Heverlee Woods! Milestone 3 continues straight down this southern forest road.",
		"Continue Exploring Louvain"
	)


func is_portal_unlocked(id: String) -> bool:
	if id == "louvain_south_heverlee":
		return GameState.louvain_breakout_won
	return true


func is_interactable_active(id: String) -> bool:
	if id == "lv_clay":
		return not GameState.louvain_clay_collected and not GameState.louvain_bell_mould_fixed
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
	elif not GameState.louvain_brazier_lit:
		director.companion.set_hint_context(
			"lv_brazier",
			["Ink stays blind in vault dark—unlit brass sconces flank the chained Scriptorium desk waiting for a warm spark."],
			ABBEY_BRAZIERS[0],
			24.0
		)
	elif GameState.louvain_archive_read and not GameState.louvain_breakout_won:
		director.companion.set_hint_context(
			"lv_shields",
			["Tower shields shrug off short dock knives straight on—heavy tarred hemp snatches oak shields right off their wrists!"],
			Vector2(1830, 780),
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


func get_ambience_track() -> String:
	return "amb_dawn_tension"


func get_lighting_tint() -> Color:
	return Color(0.84, 0.80, 0.86)


func update_region_lights(_time_val: float) -> void:
	for al: PointLight2D in abbey_lights:
		al.visible = GameState.louvain_brazier_lit
	var active_lights: Array[PointLight2D] = []
	for i in range(city_lights.size()):
		var pl := city_lights[i]
		if pl in abbey_lights and not GameState.louvain_brazier_lit:
			continue
		active_lights.append(pl)
	sync_light_frustum(active_lights, true)


func _draw() -> void:
	DrawHelper.draw_region_entities(self, Time.get_ticks_msec() * 0.001)
