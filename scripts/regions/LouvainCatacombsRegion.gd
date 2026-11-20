extends "res://scripts/regions/RegionBase.gd"

## Interior 3-Floor Zelda Dungeon beneath Louvain's Enclosed Abbey Cathedral:
##   Floor 0: Quiet Cathedral Nave -> [R] light all 4 standing altar candles to slide High Altar
##   Floor 1: Vaulted Catacombs -> decode 2 Tapestries across uniform 4x4 grid, push graves ([F] or walk-push);
##            wrong graves uncover armed spike-pit traps underneath, while 2 secret tombs hold Ladder + Treasure!
##   Floor 2: Hidden Underground Library -> sort dated parish ledgers (1422 Old Heverlee + 1426 Namur)

const MapData := preload("res://scripts/regions/LouvainCatacombsMapData.gd")
const DrawHelper := preload("res://scripts/regions/LouvainCatacombsDraw.gd")
const CityMapData := preload("res://scripts/regions/LouvainCityMapData.gd")

var static_colliders: Array[Rect2] = []
var current_floor: int = 0
var floor_switch_cd: float = 0.0

var nave_candles: Array[bool] = [false, false, false, false]
var crypt_torches: Array[bool] = [false, false, false, false, false]
var altar_slide_k: float = 0.0

var grave_states: Dictionary = {}
var grave_anim_offsets: Dictionary = {}
var under_grave_traps: Dictionary = {}
var active_grave_push_id: String = ""
var grave_push_t: float = 0.0
var trap_cooldown: float = 0.0
var trap_bolts: Array[Dictionary] = []
var fx_sparks: Array[Dictionary] = []

var nave_lights: Array[PointLight2D] = []
var crypt_lights: Array[PointLight2D] = []
var lib_lights: Array[PointLight2D] = []


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)

	for cp: Vector2 in MapData.get_nave_candles():
		var cl: PointLight2D = assets.make_point_light(cp + Vector2(0, -18), 2.9, Color(1.0, 0.78, 0.38), 0.92)
		cl.visible = false
		add_child(cl)
		nave_lights.append(cl)
	for tp: Vector2 in MapData.get_crypt_torches():
		var tl: PointLight2D = assets.make_point_light(tp + Vector2(0, -18), 2.8, Color(1.0, 0.74, 0.34), 0.88)
		tl.visible = false
		add_child(tl)
		crypt_lights.append(tl)
	for lp: Vector2 in [
		Vector2(2124, 290), Vector2(2676, 290), Vector2(2400, 420),
		Vector2(2124, 590), Vector2(2676, 590), Vector2(2400, 720),
	]:
		var ll: PointLight2D = assets.make_point_light(lp, 2.8, Color(1.0, 0.80, 0.44), 0.76)
		add_child(ll)
		lib_lights.append(ll)

	DrawHelper.setup_layers(self)
	_build_interactables()


func _build_interactables() -> void:
	interactables = [
		{"id": "cat_tap_w", "name": "Examine Stag Tapestry", "pos": MapData.TAPESTRY_W_POS + Vector2(24, 18), "radius": 78.0, "callback": _on_read_tapestry_west},
		{"id": "cat_tap_n", "name": "Examine Reliquary Tapestry", "pos": MapData.TAPESTRY_N_POS + Vector2(0, 24), "radius": 78.0, "callback": _on_read_tapestry_north},
		{"id": "cat_treasure", "name": "Open Prior's Reliquary Chest", "pos": MapData.CRYPT_TREASURE_POS, "radius": 60.0, "callback": _on_interact_treasure_chest},
		{"id": "lib_index", "name": "Read 1431 Archivist Ledger Index", "pos": MapData.INDEX_DESK_POS, "radius": 72.0, "callback": _on_read_library_index},
	]
	for g: Dictionary in MapData.get_graves_data():
		var gd: Dictionary = g
		interactables.append({
			"id": "grave_%s" % String(gd["id"]),
			"name": "Inspect Carved Crest",
			"pos": Vector2(gd["pos"]),
			"radius": 64.0,
			"callback": func(): _on_inspect_grave(gd),
		})
	for lc: Dictionary in MapData.get_library_lecterns():
		var ld: Dictionary = lc
		interactables.append({
			"id": "lectern_%s" % String(ld["year"]),
			"name": "Sort Anno %s Parish Ledger" % String(ld["year"]),
			"pos": Vector2(ld["pos"]),
			"radius": 62.0,
			"callback": func(): _on_inspect_lectern(ld),
		})


func enter_region(opts: Dictionary = {}) -> void:
	fx_sparks.clear()
	trap_bolts.clear()
	under_grave_traps.clear()
	grave_states.clear()
	grave_anim_offsets.clear()
	active_grave_push_id = ""
	grave_push_t = 0.0
	trap_cooldown = 0.0
	floor_switch_cd = 0.65
	portal_cooldown = 0.65

	GameState.active_perspective = "boy"
	GameState.book2_started = true
	if GameState.active_companion_stage < 1:
		GameState.active_companion_stage = 1
		GameState.brabant_hatched = true
	if int(GameState.current_step) < int(GameState.QuestStep.BOOK2_LOUVAIN_HATCH):
		GameState.current_step = GameState.QuestStep.BOOK2_LOUVAIN_HATCH

	nave_candles.assign([
		GameState.louvain_brazier_lit, GameState.louvain_brazier_lit,
		GameState.louvain_brazier_lit, GameState.louvain_brazier_lit,
	])
	altar_slide_k = 1.0 if GameState.louvain_brazier_lit else 0.0
	crypt_torches.assign([false, false, false, false, false])

	if GameState.louvain_crypt_ladder_open:
		grave_states["r3c2"] = true
		grave_anim_offsets["r3c2"] = 44.0
	if GameState.louvain_crypt_treasure_open:
		grave_states["r3c4"] = true
		grave_anim_offsets["r3c4"] = 44.0

	_rebuild_colliders()

	var start_floor: int = int(opts.get("floor", 0))
	var start_spawn: Vector2 = opts.get("spawn", MapData.NAVE_ENTRY_SPAWN)
	var start_dir: Vector2 = opts.get("facing", Vector2.UP)
	_switch_floor(start_floor, start_spawn, start_dir, true)

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.update_world_map_state("louvain_catacombs", player.position)
	ui.refresh_hud()
	SoundManager.set_ambience(get_ambience_track())


func exit_region() -> void:
	if director != null and director.companion != null:
		director.companion.clear_hint_context()


func handle_region_input(event: InputEvent) -> bool:
	if current_floor != 1 or player == null or not player.visible or (ui != null and ui.is_blocking_gameplay()):
		return false
	if event.is_action_pressed("rope_action"):
		var g_near: Dictionary = find_pushable_grave_near(player.position)
		if not g_near.is_empty():
			_attempt_push_grave(g_near)
			return true
	return false


func find_pushable_grave_near(ppos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := 9999.0
	for g: Dictionary in MapData.get_graves_data():
		var gid := String(g["id"])
		if bool(grave_states.get(gid, false)):
			continue
		var gp := Vector2(g["pos"])
		var hit_box := Rect2(gp - Vector2(21, 22), Vector2(42, 44)).grow(28.0)
		if hit_box.has_point(ppos):
			var d := ppos.distance_to(gp)
			if d < best_d:
				best_d = d
				best = g
	return best


func _rebuild_colliders() -> void:
	for c in colliders.get_children():
		c.queue_free()
	static_colliders = MapData.get_static_colliders(GameState.louvain_brazier_lit, grave_states)
	for crect: Rect2 in static_colliders:
		add_box_collider(colliders, crect)


func _switch_floor(fl: int, spawn_pos: Vector2, face_dir: Vector2, immediate: bool = false) -> void:
	current_floor = clampi(fl, 0, 2)
	floor_switch_cd = 0.65
	portal_cooldown = 0.65
	trap_bolts.clear()
	active_grave_push_id = ""
	grave_push_t = 0.0
	if player != null:
		player.position = spawn_pos
		player.facing = face_dir
		player.visible = true
		player.cutscene_hidden = false
		player.can_move = true
		player.set_carry_prop("", "")
	if director != null and director.companion != null and GameState.companion_posture != "stay":
		director.companion.global_position = spawn_pos - face_dir * 26.0
	if director != null and director.camera != null:
		var x0: int = int(current_floor * MapData.CHAMBER_W)
		director.camera.limit_left = x0
		director.camera.limit_right = x0 + int(MapData.CHAMBER_W)
		director.camera.limit_top = 0
		director.camera.limit_bottom = int(MapData.WORLD_SIZE.y)
		director.camera.position = spawn_pos
		director.camera.reset_smoothing()
	if not immediate:
		SoundManager.play_door()
	_sync_hint_context()
	queue_redraw()
	queue_foreground_redraw()


func step_region(delta: float) -> void:
	floor_switch_cd = maxf(0.0, floor_switch_cd - delta)
	trap_cooldown = maxf(0.0, trap_cooldown - delta)
	_step_fx(delta)

	if GameState.louvain_brazier_lit and altar_slide_k < 1.0:
		altar_slide_k = move_toward(altar_slide_k, 1.0, delta * 0.9)

	for gid in grave_states.keys():
		if bool(grave_states[gid]):
			var cur := float(grave_anim_offsets.get(gid, 0.0))
			if cur < 44.0:
				grave_anim_offsets[gid] = move_toward(cur, 44.0, delta * 72.0)

	for gid in under_grave_traps.keys():
		var tv := float(under_grave_traps[gid])
		if tv > 0.0:
			under_grave_traps[gid] = maxf(0.0, tv - delta)

	_step_trap_bolts(delta)
	_step_grave_pushing(delta)
	_step_open_trap_beds()
	_step_floor_portals()

	if director != null and director.camera != null and player != null:
		director.camera.position = player.position
	if player != null and player.visible:
		update_nearest_interactable(player.position)
	queue_redraw()
	queue_foreground_redraw()


func _step_open_trap_beds() -> void:
	if current_floor != 1 or trap_cooldown > 0.0 or player == null or not player.visible:
		return
	for g: Dictionary in MapData.get_graves_data():
		var gid := String(g["id"])
		if not bool(grave_states.get(gid, false)) or String(g.get("secret", "")) != "":
			continue
		var gp := Vector2(g["pos"])
		if player.position.distance_to(gp) <= 20.0:
			trap_cooldown = 1.5
			under_grave_traps[gid] = 1.4
			_damage_player(1)
			break


func _step_floor_portals() -> void:
	if floor_switch_cd > 0.0 or player == null or not player.visible:
		return
	var ppos: Vector2 = player.position
	if current_floor == 0:
		if MapData.NAVE_EXIT_RECT.grow(6.0).has_point(ppos):
			floor_switch_cd = 1.0
			SoundManager.play_door()
			director.load_region("louvain", {"spawn": CityMapData.CATHEDRAL_EXIT_RETURN_POS, "facing": Vector2.DOWN})
			return
		if GameState.louvain_brazier_lit and altar_slide_k >= 0.9 and ppos.distance_to(MapData.ALTAR_STAIRS_POS) <= 26.0:
			_switch_floor(1, MapData.CRYPT_ENTRY_SPAWN, Vector2.UP)
	elif current_floor == 1:
		if ppos.distance_to(MapData.CRYPT_STAIRS_UP_POS) <= 26.0:
			_switch_floor(0, MapData.NAVE_RETURN_STAIRS_SPAWN, Vector2.DOWN)
			return
		if GameState.louvain_crypt_ladder_open and ppos.distance_to(MapData.CRYPT_LADDER_DOWN_POS) <= 24.0:
			_switch_floor(2, MapData.LIBRARY_ENTRY_SPAWN, Vector2.UP)
	else:
		if ppos.distance_to(MapData.LIBRARY_LADDER_UP_POS) <= 26.0:
			_switch_floor(1, MapData.CRYPT_RETURN_LADDER_SPAWN, Vector2.DOWN)


func _step_grave_pushing(delta: float) -> void:
	if current_floor != 1 or player == null or not player.can_move or (ui != null and ui.is_blocking_gameplay()):
		active_grave_push_id = ""
		grave_push_t = 0.0
		return
	var move_in := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_in.length() < 0.25:
		active_grave_push_id = ""
		grave_push_t = 0.0
		return

	var target_grave: Dictionary = {}
	for g: Dictionary in MapData.get_graves_data():
		var gid := String(g["id"])
		if bool(grave_states.get(gid, false)):
			continue
		var gp := Vector2(g["pos"])
		var push_zone := Rect2(gp - Vector2(21, 22), Vector2(42, 44)).grow(24.0)
		if push_zone.has_point(player.position):
			var diff := gp - player.position
			if diff.length() > 0.1 and diff.normalized().dot(move_in.normalized()) >= 0.35:
				target_grave = g
				break

	if target_grave.is_empty():
		active_grave_push_id = ""
		grave_push_t = 0.0
		return

	var t_id := String(target_grave["id"])
	if t_id != active_grave_push_id:
		active_grave_push_id = t_id
		grave_push_t = 0.0
	grave_push_t += delta
	if grave_push_t >= 0.18:
		grave_push_t = 0.0
		_attempt_push_grave(target_grave)


func _attempt_push_grave(g: Dictionary) -> void:
	var gid := String(g["id"])
	if bool(grave_states.get(gid, false)):
		return
	var gp := Vector2(g["pos"])
	var sec := String(g.get("secret", ""))
	grave_states[gid] = true
	_rebuild_colliders()

	if sec == "library":
		GameState.louvain_crypt_ladder_open = true
		SoundManager.play_cage_break()
		SoundManager.play_chime()
		director.trigger_camera_shake(4.5, 0.38)
		_spawn_sparks(gp, Color(0.96, 0.84, 0.36), 18)
		if director != null and director.companion != null:
			director.companion.notify_progress()
		_sync_hint_context()
		ui.refresh_hud()
		return

	if sec == "treasure":
		GameState.louvain_crypt_treasure_open = true
		SoundManager.play_cage_break()
		SoundManager.play_chime()
		director.trigger_camera_shake(3.8, 0.32)
		_spawn_sparks(gp, Color(1.0, 0.88, 0.38), 20)
		return

	# Wrong tomb slides off ONLY to reveal a live crypt spike pit underneath + wall darts!
	under_grave_traps[gid] = 1.8
	trap_cooldown = 1.65
	SoundManager.play_cage_break()
	SoundManager.play_hit()
	director.trigger_camera_shake(5.0, 0.30)
	_spawn_sparks(gp, Color(0.96, 0.32, 0.24), 16)
	for ds: Dictionary in MapData.get_dart_slits():
		var dp := Vector2(ds["pos"])
		if dp.distance_to(gp) <= 520.0:
			trap_bolts.append({"pos": dp + Vector2(ds["dir"]) * 14.0, "dir": Vector2(ds["dir"]), "life": 1.6})
	var push_back := player.position - gp
	var bdir := push_back.normalized() if push_back.length() > 1.0 else Vector2.DOWN
	player.position += bdir * 18.0
	_damage_player(1)


func _on_interact_treasure_chest() -> void:
	if not GameState.louvain_crypt_treasure_open or GameState.louvain_crypt_treasure_taken:
		return
	GameState.louvain_crypt_treasure_taken = true
	GameState.boy_max_hp += 1
	GameState.boy_hp = GameState.boy_max_hp
	GameState.smoke_pellets += 2
	GameState.add_item("Prior's Crimson Reliquary")
	GameState.add_dragon_bond(15)
	SoundManager.play_chime()
	_spawn_sparks(MapData.CRYPT_TREASURE_POS, Color(1.0, 0.88, 0.36), 24)
	ui.refresh_hud()
	ui.show_dialogue([
		{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "An ancient ruby-sealed Brotherhood vial and fresh ash pellets tucked under the Prior's Chalice slab!"},
		{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Your pulse just grew steadier—and those ash-flasks carry clean beeswax seals."}
	])


func _step_trap_bolts(delta: float) -> void:
	for i in range(trap_bolts.size() - 1, -1, -1):
		var b: Dictionary = trap_bolts[i]
		b["pos"] = Vector2(b["pos"]) + Vector2(b["dir"]) * 260.0 * delta
		b["life"] = float(b["life"]) - delta
		var bp := Vector2(b["pos"])
		var hit_wall := false
		for col: Rect2 in static_colliders:
			if col.has_point(bp):
				hit_wall = true
				break
		if hit_wall or float(b["life"]) <= 0.0:
			_spawn_sparks(bp, Color(0.76, 0.74, 0.72), 4)
			trap_bolts.remove_at(i)
		elif player != null and player.visible and bp.distance_to(player.position) <= 18.0:
			trap_bolts.remove_at(i)
			_damage_player(1)


func _damage_player(dmg: int) -> void:
	if player == null or player.is_invulnerable():
		return
	GameState.boy_hp = maxi(0, GameState.boy_hp - dmg)
	player.trigger_hurt_flash()
	SoundManager.play_hit()
	_spawn_sparks(player.position, Color(0.96, 0.28, 0.24), 10)
	ui.refresh_hud()
	if GameState.boy_hp <= 0:
		trap_bolts.clear()
		ui.show_death_screen("Claimed by an Abbey Catacombs crypt trap.", Callable(self, "_retry_catacombs_floor"))


func _retry_catacombs_floor() -> void:
	GameState.boy_hp = GameState.boy_max_hp
	_switch_floor(current_floor, MapData.CRYPT_ENTRY_SPAWN if current_floor == 1 else MapData.NAVE_ENTRY_SPAWN, Vector2.UP, true)
	ui.refresh_hud()


func nave_candles_lit_count() -> int:
	var n := 0
	for v: bool in nave_candles:
		if v:
			n += 1
	return n


func find_dragon_command_target(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> Dictionary:
	var ppos := player.position if player != null else origin
	var pts: Array = []
	var states: Array[bool] = []
	if current_floor == 0:
		pts = MapData.get_nave_candles()
		states = nave_candles
	elif current_floor == 1:
		pts = MapData.get_crypt_torches()
		states = crypt_torches
	var best: Dictionary = {}
	var best_d := 9999.0
	for i in range(pts.size()):
		if i < states.size() and states[i]:
			continue
		var gp := Vector2(pts[i])
		var d := minf(origin.distance_to(gp), minf(ppos.distance_to(gp), target_pos.distance_to(gp)))
		if d <= 125.0 and d < best_d:
			best_d = d
			var stand_dir := (ppos - gp).normalized() if ppos.distance_to(gp) > 1.0 else Vector2.DOWN
			best = {"kind": "ember_puff", "target_pos": gp + Vector2(0, -14), "stand_pos": gp + stand_dir * 26.0}
	return best


func on_dragon_command(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> bool:
	if current_floor == 0:
		var candles := MapData.get_nave_candles()
		var lit_any := false
		for i in range(candles.size()):
			if not nave_candles[i] and (origin.distance_to(candles[i]) <= 68.0 or target_pos.distance_to(candles[i]) <= 56.0):
				nave_candles[i] = true
				lit_any = true
				_spawn_sparks(candles[i] + Vector2(0, -18), Color(1.0, 0.80, 0.30), 14)
		if lit_any:
			SoundManager.play_campfire_warm()
			if nave_candles_lit_count() >= candles.size() and not GameState.louvain_brazier_lit:
				GameState.louvain_brazier_lit = true
				_rebuild_colliders()
				SoundManager.play_cage_break()
				SoundManager.play_chime()
				director.trigger_camera_shake(4.5, 0.35)
				_spawn_sparks(MapData.ALTAR_STAIRS_POS, Color(1.0, 0.86, 0.38), 22)
				if director != null and director.companion != null:
					director.companion.notify_progress()
			_sync_hint_context()
			ui.refresh_hud()
			return true
	elif current_floor == 1:
		var torches := MapData.get_crypt_torches()
		var lit_t := false
		for i in range(torches.size()):
			if not crypt_torches[i] and (origin.distance_to(torches[i]) <= 68.0 or target_pos.distance_to(torches[i]) <= 56.0):
				crypt_torches[i] = true
				lit_t = true
				_spawn_sparks(torches[i] + Vector2(0, -18), Color(1.0, 0.78, 0.30), 14)
		if lit_t:
			SoundManager.play_campfire_warm()
			return true
	return false


func get_last_dragon_command_kind() -> String:
	return "ember_puff"


func _on_read_tapestry_west() -> void:
	ui.show_dialogue([
		{"speaker": "West Tapestry — Of the Stag", "portrait": "portrait_inquisitor.png", "text": "\"Four Stags guard these cold rows, yet three keep only the outer walls. Seek the solitary Stag in the inner bays—born directly south of a Chalice and directly east of a Crown.\""}
	])


func _on_read_tapestry_north() -> void:
	ui.show_dialogue([
		{"speaker": "North Tapestry — The Prior's Coffer", "portrait": "portrait_inquisitor.png", "text": "\"Shun every corner stone. Along the third rank from the northern wall rests the Prior's Chalice—framed above by a Cross and below by a Crown, never beside a Stag.\""}
	])


func _on_inspect_grave(g: Dictionary) -> void:
	var desc := "A weathered limestone slab etched with an Abbey Cross."
	match String(g["crest"]):
		"crown":
			desc = "A heavy stone slab bearing a three-spiked Abbacy Crown."
		"chalice":
			desc = "A cracked granite lid engraved with a Sacramental Chalice."
		"stag":
			desc = "A cold stone sarcophagus chiseled with the Antlered Stag-of-Heverlee."
	ui.show_dialogue([{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": desc}])


func _on_read_library_index() -> void:
	ui.show_parchment_note(
		"Archivist Ledger Index (Anno 1431)",
		"[b]CHRONOLOGICAL FILING KEY — ANNO DOMINI 1431[/b]\n\n"
		+ "• Earlier Old Heverlee field inquiries sit [b]NINE YEARS BACK[/b] (West Vault — Anno 1422).\n"
		+ "• Conscripted Rig-Master requisitions were sealed [b]FIVE YEARS BACK[/b] (East Vault — Anno 1426).",
		"Chapter Scriptorium Archivist"
	)


func _on_inspect_lectern(ld: Dictionary) -> void:
	var yr := String(ld["year"])
	var dec := String(ld["decree"])
	if dec == "old_heverlee":
		if GameState.louvain_found_1422:
			ui.show_parchment_note(
				"Chained Ledger — Anno 1422",
				"\"Old Heverlee Shrine Key unrecovered; Louvain parish hunters neutralized by Inquisitor squad.\"",
				"Abbey Scriptorium Chain-Seal"
			)
			return
		GameState.louvain_found_1422 = true
		_grant_archive_if_both_found()
		SoundManager.play_chime()
		_spawn_sparks(Vector2(ld["pos"]), Color(0.98, 0.84, 0.36), 14)
		ui.show_parchment_note(
			"Chained Decree — Anno 1422 (9 Years Past)",
			"[b]SECRET MEMORANDUM:[/b]\n\nHunters of Louvain Parish intercepted at Old Heverlee Woods over the unrecovered Bronze Shrine Key.\n\n[i]Official parish tally falsified as dragon casualties.[/i]",
			"High Inquisitor Privy Seal",
			func(): _on_after_decree_read()
		)
	elif dec == "namur_clara":
		if GameState.louvain_found_1426:
			ui.show_parchment_note(
				"Requisition Warrant — Anno 1426",
				"\"Rig-master Clara of Bruges moved east to Namur Quarry Rig-Works—bloodline traced to Old Heverlee.\"",
				"Abbey Scriptorium Chain-Seal"
			)
			return
		GameState.louvain_found_1426 = true
		_grant_archive_if_both_found()
		SoundManager.play_chime()
		_spawn_sparks(Vector2(ld["pos"]), Color(0.98, 0.84, 0.36), 14)
		ui.show_parchment_note(
			"Namur Requisition Warrant — Anno 1426 (5 Years Past)",
			"[b]HIGH PRIORITY REQUISITION:[/b]\n\nAbduct Bruges Ropewalk rig-master [b]CLARA OF BRUGES[/b] to Namur Cliff-Citadel for heavy harness forging.\n\n[i]Further archive cross-check links her to the Louvain Old Heverlee pair.[/i]",
			"Inquisitor Transfer Warrant — Namur",
			func(): _on_after_decree_read()
		)
	else:
		var filler: String = str({
			"1416": "ANNO 1416 — Dijle Weir Wheat & Wool Tithe Rolls.\n\nNothing here mentions Old Heverlee or Clara.",
			"1419": "ANNO 1419 — Ghent Foundry Bronze Bell Contract.\n\nWrong year—keep checking the Archivist Index.",
			"1425": "ANNO 1425 — Papal Bull founding Louvain's Studium Generale University in De Lakenhalle.",
			"1428": "ANNO 1428 — St. Peter's Choir Timber Crane & Brussels Tower Height Comparison Ledger.",
			"1430": "ANNO 1430 — Coastal Bruges Patrol Stipends & Dawn Dragon-Bounty Notice Drafts.",
		}.get(yr, "ANNO %s — Routine Parish Tax Rolls." % yr))
		ui.show_parchment_note("Parish Folio — Anno %s" % yr, filler, "St. Peter's Chapter Library")


func _grant_archive_if_both_found() -> void:
	if GameState.louvain_found_1422 and GameState.louvain_found_1426 and not GameState.louvain_archive_read:
		GameState.louvain_archive_read = true
		GameState.add_item("Abbey Scriptorium Decree")
		GameState.add_dragon_bond(10)
		ui.pulse_hud_icon("journal")
		_sync_hint_context()
		ui.refresh_hud()


func _on_after_decree_read() -> void:
	_grant_archive_if_both_found()
	if GameState.louvain_archive_read:
		ui.show_dialogue([
			{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Your hands are trembling... They buried the truth about your parents AND stole Clara east to Namur! Wait—heavy boots echoing across the Cloister stones above! Climb back out now!"}
		])


func get_gold_sense_targets() -> Array:
	if current_floor == 0 and not GameState.louvain_brazier_lit:
		var out: Array = []
		var c := MapData.get_nave_candles()
		for i in range(c.size()):
			if not nave_candles[i]:
				out.append(c[i])
		return out
	if current_floor == 1:
		var gout: Array = []
		if not GameState.louvain_crypt_ladder_open:
			gout.append(MapData.TAPESTRY_W_POS)
		if GameState.louvain_crypt_treasure_open and not GameState.louvain_crypt_treasure_taken:
			gout.append(MapData.CRYPT_TREASURE_POS)
		return gout
	if current_floor == 2 and not GameState.louvain_archive_read:
		var lout: Array = []
		if not GameState.louvain_found_1422:
			lout.append(Vector2(2124, 640))
		if not GameState.louvain_found_1426:
			lout.append(Vector2(2676, 460))
		return lout
	return []


func _sync_hint_context() -> void:
	if director == null or director.companion == null:
		return
	if current_floor == 0 and not GameState.louvain_brazier_lit:
		director.companion.set_hint_context("cat_f0", ["Four brass candelabras line this nave—if we kindle all four, the high altar stone looks grooved to slide aside."], MapData.ALTAR_POS, 26.0)
	elif current_floor == 1 and not GameState.louvain_crypt_ladder_open:
		director.companion.set_hint_context("cat_f1", ["Sharp iron spikes sit beneath the wrong graves! Check both woven wall tapestries to cross-check rows and neighboring seals before shoving."], MapData.TAPESTRY_W_POS, 30.0)
	elif current_floor == 2 and not GameState.louvain_archive_read:
		director.companion.set_hint_context("cat_f2", ["Look at that 1431 Desk Index: nine years back puts Old Heverlee at 1422, and five years back puts Clara's warrant at 1426."], MapData.INDEX_DESK_POS, 26.0)
	else:
		director.companion.clear_hint_context()


func is_interactable_active(id: String) -> bool:
	if id == "cat_treasure":
		return current_floor == 1 and GameState.louvain_crypt_treasure_open and not GameState.louvain_crypt_treasure_taken
	if id.begins_with("cat_"):
		return current_floor == 1
	if id.begins_with("grave_"):
		var gid := id.substr("grave_".length())
		return current_floor == 1 and not bool(grave_states.get(gid, false))
	if id.begins_with("lib_") or id.begins_with("lectern_"):
		return current_floor == 2
	return true


func get_interact_bubble_offset(id: String) -> Vector2:
	if id.begins_with("grave_"):
		return Vector2(0, -66)
	return Vector2(0, -44)


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
	return "wood" if current_floor == 2 else "cobble"


func get_ambience_track() -> String:
	return "amb_hearth" if current_floor == 2 else "amb_catacombs"


func get_lighting_tint() -> Color:
	if current_floor == 0:
		var k := float(nave_candles_lit_count()) / 4.0
		return Color(0.56, 0.58, 0.68).lerp(Color(0.86, 0.82, 0.84), k)
	if current_floor == 1:
		return Color(0.48, 0.50, 0.60)
	return Color(0.76, 0.72, 0.78)


func update_region_lights(_time_val: float) -> void:
	var active: Array[PointLight2D] = []
	for i in range(nave_lights.size()):
		nave_lights[i].visible = (current_floor == 0 and nave_candles[i])
		if nave_lights[i].visible:
			active.append(nave_lights[i])
	for i in range(crypt_lights.size()):
		crypt_lights[i].visible = (current_floor == 1 and crypt_torches[i])
		if crypt_lights[i].visible:
			active.append(crypt_lights[i])
	for ll: PointLight2D in lib_lights:
		ll.visible = (current_floor == 2)
		if ll.visible:
			active.append(ll)
	sync_light_frustum(active, true)


func _draw() -> void:
	DrawHelper.draw_region_entities(self, Time.get_ticks_msec() * 0.001)
