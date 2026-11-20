extends "res://scripts/regions/RegionBase.gd"

## Book II Act I Part 2 — Haunted Old Heverlee Woods (2200x1500):
## Features Parents' 9-Year-Old Ambush Forensics (Show, Don't Tell + Gold-Sense reaction),
## Zoet Water Creek (stepping ford & Rope Grapple gap), Church Inquisitor Scout Camp,
## Ember Puff Bramble Clearing into the First Golden Dragon Shrine, and Kestrel Courier Campfire Handoff.

const MapData := preload("res://scripts/regions/OldHeverleeMapData.gd")
const DrawHelper := preload("res://scripts/regions/OldHeverleeDraw.gd")
const PlayerCombatHelperScript := preload("res://scripts/systems/PlayerCombatHelper.gd")

var static_colliders: Array[Rect2] = []
var scouts: Array[Dictionary] = []
var enemy_bolts: Array[Dictionary] = []
var fx_sparks: Array[Dictionary] = []
var wood_lights: Array[PointLight2D] = []
var _last_command_kind: String = ""


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	_rebuild_colliders()
	for lp: Vector2 in [MapData.CIPHER_TABLE_POS, MapData.SHRINE_DOOR_RECT.get_center(), MapData.OVERLOOK_FIRE_POS]:
		var pl: PointLight2D = assets.make_point_light(lp + Vector2(0, -10), 2.8, Color(1.0, 0.78, 0.36), 0.78)
		add_child(pl)
		wood_lights.append(pl)

	DrawHelper.setup_layers(self)
	_build_interactables()
	clear_walk_portals()
	register_walk_portal("hev_to_louvain", MapData.NORTH_PORTAL_RECT, Vector2.UP, _on_exit_north, "^ Louvain South Gate", "LOUVAIN — NAAMSEPOORT", "Walled University City")
	register_walk_portal("hev_to_shrine", MapData.SHRINE_DOOR_RECT, Vector2.UP, _on_enter_shrine, "^ Descend to Golden Shrine", "FIRST GOLDEN DRAGON SHRINE", "Subterranean Relic Vault")


func _rebuild_colliders() -> void:
	for c in colliders.get_children():
		c.queue_free()
	static_colliders = MapData.get_static_colliders(GameState.heverlee_briar_burned)
	for crect: Rect2 in static_colliders:
		add_box_collider(colliders, crect)
	setup_navigation_grid(Rect2(Vector2.ZERO, MapData.WORLD_SIZE), static_colliders, 10.0, 20.0)


func _build_interactables() -> void:
	interactables = [
		{"id": "hev_ambush", "name": "Examine Shattered Yew Bow", "pos": MapData.AMBUSH_STUMP_POS, "radius": 68.0, "callback": _on_inspect_ambush},
		{"id": "hev_cipher", "name": "Read Inquisitor Scout Dispatch", "pos": MapData.CIPHER_TABLE_POS, "radius": 66.0, "callback": _on_read_cipher},
		{"id": "hev_fire", "name": "Cliff Overlook Campfire", "pos": MapData.OVERLOOK_FIRE_POS, "radius": 72.0, "callback": _on_interact_campfire},
		{"id": "hev_kestrel", "name": "Tie Dispatch to Kestrel's Band", "pos": MapData.KESTREL_ROCK_POS, "radius": 72.0, "callback": _on_handoff_kestrel},
	]


func enter_region(opts: Dictionary = {}) -> void:
	fx_sparks.clear()
	enemy_bolts.clear()
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

	scouts.assign([] if GameState.heverlee_scouts_cleared else MapData.get_scouts())
	_rebuild_colliders()

	var spawn: Vector2 = opts.get("spawn", MapData.NORTH_ENTRY_SPAWN)
	player.position = spawn
	player.facing = opts.get("facing", Vector2.DOWN)
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


func step_region(delta: float) -> void:
	step_water_layer()
	_step_scouts(delta)
	_step_bolts(delta)
	_step_fx(delta)
	if director != null and director.camera != null and player != null:
		director.camera.position = player.position
	if player != null and player.visible:
		update_nearest_interactable(player.position)
	queue_redraw()
	queue_foreground_redraw()


func _step_scouts(delta: float) -> void:
	if scouts.is_empty():
		return
	var ppos: Vector2 = player.position if player != null else Vector2.ZERO
	var alive_count := 0
	for s: Dictionary in scouts:
		if int(s["hp"]) <= 0:
			continue
		alive_count += 1
		if bool(s.get("permanently_bound", false)):
			continue
		if float(s.get("snared_t", 0.0)) > 0.0:
			s["snared_t"] = maxf(0.0, float(s["snared_t"]) - delta)
			continue
		if float(s.get("stun", 0.0)) > 0.0:
			s["stun"] = maxf(0.0, float(s["stun"]) - delta)
			continue
		var sp := Vector2(s["pos"])
		var d_p := sp.distance_to(ppos)
		if d_p < 220.0 and player.visible:
			var to_p := (ppos - sp).normalized()
			s["dir"] = to_p
			s["timer"] = float(s.get("timer", 0.6)) - delta
			if String(s["kind"]) == "shield":
				var nxt := sp + to_p * 62.0 * delta
				if not point_hits_colliders(nxt, static_colliders, 10.0):
					s["pos"] = nxt
				if d_p < 24.0 and float(s["timer"]) <= 0.0:
					s["timer"] = 1.1
					_damage_boy(1)
			else:
				if float(s["timer"]) <= 0.0:
					s["timer"] = 1.85
					enemy_bolts.append({"pos": sp + to_p * 14.0, "dir": to_p, "life": 1.6})
					SoundManager.play_swing()
		else:
			var pts: Array = s["pts"]
			var wp := int(s["wp"])
			var tgt := Vector2(pts[wp])
			if sp.distance_to(tgt) < 8.0:
				s["wp"] = (wp + 1) % pts.size()
			else:
				var mv := (tgt - sp).normalized()
				s["dir"] = mv
				s["pos"] = sp + mv * 34.0 * delta
	if alive_count == 0 and not GameState.heverlee_scouts_cleared:
		GameState.heverlee_scouts_cleared = true
		SoundManager.play_chime()
		_sync_hint_context()


func _step_bolts(delta: float) -> void:
	for i in range(enemy_bolts.size() - 1, -1, -1):
		var b: Dictionary = enemy_bolts[i]
		b["pos"] = Vector2(b["pos"]) + Vector2(b["dir"]) * 240.0 * delta
		b["life"] = float(b["life"]) - delta
		var bp := Vector2(b["pos"])
		var hit_wall := false
		for cr: Rect2 in static_colliders:
			if cr.has_point(bp):
				hit_wall = true
				break
		if hit_wall or float(b["life"]) <= 0.0:
			enemy_bolts.remove_at(i)
		elif player != null and player.visible and bp.distance_to(player.position) <= 15.0:
			enemy_bolts.remove_at(i)
			_damage_boy(1)


func _damage_boy(amt: int) -> void:
	if player != null and player.is_invulnerable():
		return
	GameState.boy_hp = maxi(0, GameState.boy_hp - amt)
	if player != null:
		player.trigger_hurt_flash()
	SoundManager.play_hit()
	ui.refresh_hud()
	if GameState.boy_hp <= 0:
		GameState.boy_hp = GameState.boy_max_hp
		player.position = MapData.NORTH_ENTRY_SPAWN
		ui.refresh_hud()


func get_rope_anchors() -> Array[Vector2]:
	return [MapData.ROPE_POST_N, MapData.ROPE_POST_S]


func on_rope_cast_hit(target_pos: Vector2, knot_id: String) -> void:
	if target_pos.distance_to(MapData.ROPE_POST_S) <= 68.0 and player.position.y < 765.0:
		player.position = MapData.ROPE_POST_S + Vector2(0, 26)
		SoundManager.play_rope()
		_spawn_sparks(MapData.ROPE_POST_S, Color(0.96, 0.84, 0.40), 12)
		return
	if target_pos.distance_to(MapData.ROPE_POST_N) <= 68.0 and player.position.y > 830.0:
		player.position = MapData.ROPE_POST_N + Vector2(0, -26)
		SoundManager.play_rope()
		_spawn_sparks(MapData.ROPE_POST_N, Color(0.96, 0.84, 0.40), 12)
		return
	var res := PlayerCombatHelperScript.resolve_knot_targets(knot_id, player.position, target_pos, scouts)
	if bool(res.get("hit", false)):
		var zipped = res.get("zipped_target", null)
		if zipped is Dictionary and not zipped.is_empty():
			var zpos := Vector2(zipped["pos"])
			var pull_dir := (zpos - player.position).normalized()
			if pull_dir.length_squared() < 0.01:
				pull_dir = Vector2.RIGHT
			player.position = zpos - pull_dir * 26.0
			zipped["stun"] = maxf(float(zipped.get("stun", 0.0)), 0.7)
			_spawn_sparks(zpos, Color(1.0, 0.86, 0.36), 16)
		for b in res.get("bound", []):
			_spawn_sparks(Vector2(b["pos"]), Color(0.95, 0.72, 0.24), 14)
		for snared in res.get("snared", []):
			snared["snared_t"] = maxf(float(snared.get("snared_t", 0.0)), 3.2)
			_spawn_sparks(Vector2(snared["pos"]), Color(0.45, 0.90, 0.72), 12)
		for yanked in res.get("yanked", []):
			_spawn_sparks(Vector2(yanked["pos"]), Color(0.98, 0.56, 0.30), 14)
			SoundManager.play_cage_break()
		SoundManager.play_rope()


func on_knife_slash(tip_pos: Vector2, aim_dir: Vector2) -> void:
	var slash_meta: Dictionary = player.get_last_slash_meta() if player != null and player.has_method("get_last_slash_meta") else {}
	var dmg: int = maxi(1, int(slash_meta.get("damage", 1)))
	for s: Dictionary in scouts:
		if int(s["hp"]) <= 0:
			continue
		var sp := Vector2(s["pos"])
		var diff := sp - player.position
		if sp.distance_to(tip_pos) <= 36.0 or (diff.length() <= 46.0 and diff.normalized().dot(aim_dir.normalized()) >= 0.10):
			if bool(s.get("has_shield", false)) and float(s.get("snared_t", 0.0)) <= 0.0 and float(s.get("stun", 0.0)) <= 0.0:
				_spawn_sparks(Vector2(s["pos"]), Color(0.75, 0.82, 0.90), 8)
				SoundManager.play_hit()
			else:
				s["hp"] = int(s["hp"]) - dmg
				s["stun"] = 0.45
				_spawn_sparks(Vector2(s["pos"]), Color(0.96, 0.56, 0.32), 12)
				SoundManager.play_cage_break()


func find_dragon_command_target(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> Dictionary:
	var ppos := player.position if player != null else origin
	if not GameState.heverlee_briar_burned and (origin.distance_to(MapData.BRIAR_POS) <= 95.0 or ppos.distance_to(MapData.BRIAR_POS) <= 95.0 or target_pos.distance_to(MapData.BRIAR_POS) <= 85.0):
		return {"kind": "ember_puff", "target_pos": MapData.BRIAR_POS, "stand_pos": MapData.BRIAR_POS + Vector2(0, 32)}
	return {}


func on_dragon_command(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> bool:
	_last_command_kind = ""
	if not GameState.heverlee_briar_burned and (origin.distance_to(MapData.BRIAR_POS) <= 95.0 or target_pos.distance_to(MapData.BRIAR_POS) <= 85.0):
		_last_command_kind = "ember_puff"
		GameState.heverlee_briar_burned = true
		_rebuild_colliders()
		SoundManager.play_campfire_warm()
		SoundManager.play_cage_break()
		_spawn_sparks(MapData.BRIAR_POS, Color(1.0, 0.72, 0.24), 22)
		if director != null and director.companion != null:
			director.companion.notify_progress()
		_sync_hint_context()
		return true
	return false


func get_last_dragon_command_kind() -> String:
	return _last_command_kind


func _on_inspect_ambush() -> void:
	GameState.heverlee_ambush_inspected = true
	GameState.add_dragon_bond(8)
	SoundManager.play_chime()
	ui.refresh_hud()
	ui.show_dialogue([
		{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "Father's yew stave snapped in half... and crimson-fletched Inquisitor bolts buried deep inside the oak heartwood."},
		{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Old bronze hums south across the creek below thick brambles. Your folk buried something fierce down there."}
	])
	_sync_hint_context()


func _on_read_cipher() -> void:
	if not GameState.inventory.has("Inquisitor Field Cipher"):
		GameState.add_item("Inquisitor Field Cipher")
		SoundManager.play_chime()
		ui.pulse_hud_icon("bag")
	ui.show_parchment_note(
		"Inquisitor Field Dispatch",
		"\"SWEEP ZOET WATER SOUTH BANK FOR SUNKEN SHRINE ENTRANCE.\n\nBARGE CONVOY SHIPS CAPTURED DRAKES TO NAMUR UPON BELL SIGNAL.\"",
		"Inquisitor Scout Cipher — Old Heverlee"
	)


func _on_interact_campfire() -> void:
	ui.open_campfire_roost(
		"old_heverlee",
		MapData.OVERLOOK_FIRE_POS,
		"Old Heverlee Cliff Lookout Fire",
		GameState.boy_heverlee_relic_found and not GameState.heverlee_kestrel_sent,
		"Dispatch Kestrel East to Captain Anna"
	)
	if ui.campfire_panel != null and not ui.campfire_panel.kestrel_handoff_requested.is_connected(_on_handoff_kestrel):
		ui.campfire_panel.kestrel_handoff_requested.connect(_on_handoff_kestrel, CONNECT_ONE_SHOT)


func _on_handoff_kestrel() -> void:
	if not GameState.boy_heverlee_relic_found or GameState.heverlee_kestrel_sent:
		return
	GameState.heverlee_kestrel_sent = true
	SoundManager.play_chime()
	ui.show_dialogue([
		{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "Fly fast east to Anna, girl—tell her the Church bleeds live dragons at Namur, and they seized Clara five years back."},
		{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Grey wings climb above the beech ridge... Now let's see what Aunt Anna answers on the river winds."}
	], func():
		director.load_region("anna_ch1_sanctuary", {})
	)


func _on_enter_shrine() -> void:
	SoundManager.play_door()
	director.load_region("old_heverlee_shrine", {"spawn": Vector2(360, 740), "facing": Vector2.UP})


func _on_exit_north() -> void:
	director.load_region("louvain", {"spawn": Vector2(1050, 1924), "facing": Vector2.UP})


func is_portal_unlocked(id: String) -> bool:
	if id == "hev_to_shrine":
		return GameState.heverlee_briar_burned
	return true


func is_interactable_active(id: String) -> bool:
	if id == "hev_kestrel":
		return GameState.boy_heverlee_relic_found and not GameState.heverlee_kestrel_sent
	return true


func _sync_hint_context() -> void:
	if director == null or director.companion == null:
		return
	if not GameState.heverlee_ambush_inspected:
		director.companion.set_hint_context("hev_ambush", ["Smoke and iron cling to that western oak clearing ahead—something wooden lies half-buried in the moss."], MapData.AMBUSH_STUMP_POS, 26.0)
	elif not GameState.heverlee_briar_burned:
		director.companion.set_hint_context("hev_briar", ["Dry brambles choke old golden stairs south of Zoet Water creek—one spark ought to clear them cleanly."], MapData.BRIAR_POS, 26.0)
	elif GameState.boy_heverlee_relic_found and not GameState.heverlee_kestrel_sent:
		director.companion.set_hint_context("hev_kestrel", ["A grey courier dragon settled on the overlook rock by our southern campfire—she's carrying empty message bands."], MapData.KESTREL_ROCK_POS, 28.0)
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


func get_surface_at(pos: Vector2) -> String:
	for fs: Rect2 in MapData.get_ford_stones():
		if fs.has_point(pos):
			return "cobble"
	return "grass"


func get_active_npc_colliders() -> Array:
	var list: Array = []
	if GameState.boy_heverlee_relic_found and not GameState.heverlee_kestrel_sent:
		list.append({"pos": MapData.KESTREL_ROCK_POS, "radius": 24.0})
	for s: Dictionary in scouts:
		if int(s.get("hp", 0)) > 0:
			list.append(Vector2(s["pos"]))
	return list


func get_ambience_track() -> String:
	return "amb_dawn_tension"


func get_lighting_tint() -> Color:
	return Color(0.70, 0.72, 0.80) if GameState.boy_heverlee_relic_found else Color(0.76, 0.78, 0.70)


func update_region_lights(_time_val: float) -> void:
	sync_light_frustum(wood_lights, true)


func _draw() -> void:
	DrawHelper.draw_region_entities(self, Time.get_ticks_msec() * 0.001)
