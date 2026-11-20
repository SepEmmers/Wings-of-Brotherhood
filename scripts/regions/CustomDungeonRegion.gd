extends "res://scripts/regions/RegionBase.gd"

## Data-driven Dungeon & Puzzle runtime loaded from data/custom_dungeon.json
## (or user://custom_dungeon.json / opts["dungeon_data"]). Logic lives in CustomDungeonLogic.gd,
## hazards/interactions in CustomDungeonHazards.gd and rendering in CustomDungeonDraw.gd.

const DrawHelper := preload("res://scripts/regions/CustomDungeonDraw.gd")
const LogicScript := preload("res://scripts/regions/CustomDungeonLogic.gd")
const HazardScript := preload("res://scripts/regions/CustomDungeonHazards.gd")

const SOLID_TYPES: Array[String] = [
	"boulder", "sarcophagus", "treasure", "grapple_post", "ember_brazier", "lever", "breakable_pot",
	"crystal_switch", "resonance_crystal", "chime_bell", "healing_spring", "dart_turret", "flame_jet",
	"timer_switch", "npc",
]

var dungeon_data: Dictionary = {}
var world_size: Vector2 = Vector2(1600, 960)
var floor_style: String = "catacomb_stone"
var ambience_track: String = "amb_catacombs"
var lighting_tint: Color = Color(0.68, 0.66, 0.74)
var darkness: float = 0.0

var rooms: Array = []
var chasms: Array = []
var explicit_walls: Array = []
var nodes: Array = []
var wires: Array = []

var wall_border_rects: Array[Rect2] = []
var static_colliders: Array[Rect2] = []
var region_lights: Array[PointLight2D] = []
var light_ids: Array[String] = []
var player_light: PointLight2D

var node_states: Dictionary = {}
var node_positions: Dictionary = {}
var node_hits: Dictionary = {}
var wire_sequence_progress: Dictionary = {}
var hold_timers: Dictionary = {}
var relay_want: Dictionary = {}
var relay_timers: Dictionary = {}
var turret_t: Dictionary = {}
var flame_on: Dictionary = {}
var collapse_t: Dictionary = {}
var crystal_phase: int = 0
var crystal_cd: float = 0.0
var push_hold_t: float = 0.0
var push_target_id: String = ""
var trap_timer: float = 0.0
var trap_cooldown: float = 0.0
var tp_cd: float = 0.0
var safe_t: float = 0.0
var last_safe_pos: Vector2 = Vector2.ZERO
var checkpoint_pos: Vector2 = Vector2.ZERO
var keys_small: int = 0
var keys_boss: int = 0
var florins: int = 0
var dart_bolts: Array[Dictionary] = []
var fx_sparks: Array[Dictionary] = []
var _last_command_kind: String = ""


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)


func _load_dungeon_data(opts: Dictionary) -> void:
	dungeon_data = DrawHelper.load_dungeon_dict(opts)
	var ws: Dictionary = dungeon_data.get("worldSize", {"w": 1600, "h": 960})
	world_size = Vector2(maxf(640.0, float(ws.get("w", 1600))), maxf(480.0, float(ws.get("h", 960))))
	floor_style = String(dungeon_data.get("floorStyle", "catacomb_stone"))
	ambience_track = String(dungeon_data.get("ambience", "amb_catacombs"))
	darkness = clampf(float(dungeon_data.get("darkness", 0.0)), 0.0, 0.95)
	var lt: Array = dungeon_data.get("lightingTint", [0.68, 0.66, 0.74])
	if lt.size() >= 3:
		lighting_tint = Color(float(lt[0]), float(lt[1]), float(lt[2]))
	rooms = dungeon_data.get("rooms", []).duplicate(true)
	chasms = dungeon_data.get("chasms", []).duplicate(true)
	explicit_walls = dungeon_data.get("walls", []).duplicate(true)
	nodes = dungeon_data.get("nodes", []).duplicate(true)
	wires = dungeon_data.get("wires", []).duplicate(true)
	for d: Dictionary in [node_states, node_positions, node_hits, wire_sequence_progress, hold_timers, relay_want, relay_timers, turret_t, flame_on, collapse_t]:
		d.clear()
	crystal_phase = 0
	keys_small = 0
	keys_boss = 0
	florins = 0
	for n in nodes:
		var nid: String = String(n.get("id", ""))
		node_positions[nid] = Vector2(float(n.get("x", 0)), float(n.get("y", 0)))
		node_states[nid] = false


func get_room_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in rooms:
		out.append(Rect2(float(r.get("x", 0)), float(r.get("y", 0)), float(r.get("w", 120)), float(r.get("h", 120))))
	return out


func get_chasm_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for c in chasms:
		out.append(Rect2(float(c.get("x", 0)), float(c.get("y", 0)), float(c.get("w", 64)), float(c.get("h", 64))))
	return out


func get_node_pos(n: Dictionary) -> Vector2:
	var nid: String = String(n.get("id", ""))
	if node_positions.has(nid):
		return Vector2(node_positions[nid])
	return Vector2(float(n.get("x", 0)), float(n.get("y", 0)))


func _find_node(nid: String) -> Dictionary:
	for n in nodes:
		if String(n.get("id", "")) == nid:
			return n
	return {}


func _compute_wall_borders() -> void:
	wall_border_rects = DrawHelper.compute_wall_borders(get_room_rects(), explicit_walls)


func _open_bridge_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for n in nodes:
		if String(n.get("type", "")) == "drawbridge" and bool(node_states.get(String(n.get("id", "")), false)):
			out.append(LogicScript.node_rect(self, n))
	return out


func _node_blocks(n: Dictionary) -> bool:
	var nid: String = String(n.get("id", ""))
	var t: String = String(n.get("type", ""))
	var st: bool = bool(node_states.get(nid, false))
	match t:
		"gate", "locked_door", "secret_wall", "cracked_wall", "briar_barrier", "breakable_pot":
			return not st
		"color_block":
			return LogicScript.color_block_solid(self, n)
		"collapsing_floor":
			return st
		"decor":
			return bool(n.get("solid", true))
	return SOLID_TYPES.has(t)


func _rebuild_colliders() -> void:
	for c in colliders.get_children():
		c.queue_free()
	static_colliders.clear()
	for wb: Rect2 in wall_border_rects:
		static_colliders.append(wb)
	var bridges: Array[Rect2] = _open_bridge_rects()
	for ch: Rect2 in get_chasm_rects():
		for piece: Rect2 in DrawHelper._subtract_rects(ch, bridges):
			static_colliders.append(piece)
	for n in nodes:
		if not _node_blocks(n):
			continue
		var t: String = String(n.get("type", ""))
		var rect: Rect2 = LogicScript.node_rect(self, n)
		if LogicScript.is_corner(t):
			static_colliders.append(rect)
		else:
			static_colliders.append(Rect2(rect.position + rect.size * 0.12, rect.size * 0.76))
	for crect: Rect2 in static_colliders:
		add_box_collider(colliders, crect)
	setup_navigation_grid(Rect2(Vector2.ZERO, world_size), static_colliders, 10.0, 20.0)


func _add_light(pos: Vector2, scale_v: float, col: Color, energy: float, nid: String) -> void:
	var pt: PointLight2D = assets.make_point_light(pos, scale_v, col, energy)
	add_child(pt)
	region_lights.append(pt)
	light_ids.append(nid)


func _build_interactables_and_portals() -> void:
	interactables.clear()
	clear_walk_portals()
	for pl: PointLight2D in region_lights:
		if is_instance_valid(pl):
			pl.queue_free()
	region_lights.clear()
	light_ids.clear()

	for n in nodes:
		var nid: String = String(n.get("id", ""))
		var t: String = String(n.get("type", ""))
		var lbl: String = String(n.get("label", t.capitalize()))
		var pos: Vector2 = LogicScript.node_center(self, n)
		match t:
			"plaque":
				interactables.append({"id": "nd_" + nid, "name": lbl, "pos": pos, "radius": 68.0, "callback": func(): _on_read_plaque(n)})
			"npc":
				interactables.append({"id": "nd_" + nid, "name": "Talk to " + lbl, "pos": pos, "radius": 64.0, "callback": func(): HazardScript.talk_npc(self, n)})
			"lever":
				interactables.append({"id": "nd_" + nid, "name": "Pull " + lbl, "pos": pos, "radius": 58.0, "callback": func(): _on_toggle_lever(nid)})
			"timer_switch":
				interactables.append({"id": "nd_" + nid, "name": "Strike " + lbl, "pos": pos, "radius": 58.0, "callback": func(): HazardScript.ring_timer(self, n)})
			"chime_bell":
				interactables.append({"id": "nd_" + nid, "name": "Ring " + lbl, "pos": pos, "radius": 62.0, "callback": func(): HazardScript.ring_bell(self, n)})
			"healing_spring":
				interactables.append({"id": "nd_" + nid, "name": "Drink from " + lbl, "pos": pos, "radius": 64.0, "callback": func(): HazardScript.use_spring(self, n)})
			"locked_door":
				interactables.append({"id": "nd_" + nid, "name": "Unlock " + lbl, "pos": pos, "radius": 62.0, "callback": func(): HazardScript.try_open_door(self, n)})
			"treasure":
				interactables.append({"id": "nd_" + nid, "name": "Claim " + lbl, "pos": pos, "radius": 60.0, "callback": func(): _on_claim_treasure(n)})
				_add_light(pos, 2.0, Color(1.0, 0.80, 0.38), 0.55, nid)
			"exit_portal":
				var tgt: String = String(n.get("targetRegion", "old_heverlee"))
				register_walk_portal("exit_" + nid, LogicScript.node_rect(self, n), Vector2.DOWN, func(): _on_exit_portal(tgt), lbl, "WORLD OVERLAND", lbl)
			"ember_brazier":
				_add_light(pos, 2.6, Color(1.0, 0.76, 0.34), 0.8, nid)
			"decor":
				if bool(n.get("light", false)):
					_add_light(pos, 2.4, Color(1.0, 0.78, 0.40), 0.7, nid)
	player_light = assets.make_point_light(Vector2.ZERO, 3.2, Color(1.0, 0.92, 0.78), 0.55 + darkness * 0.55)
	add_child(player_light)
	region_lights.append(player_light)
	light_ids.append("__player")


func enter_region(opts: Dictionary = {}) -> void:
	fx_sparks.clear()
	dart_bolts.clear()
	trap_timer = 0.0
	trap_cooldown = 0.0
	tp_cd = 0.0
	portal_cooldown = 0.85
	_last_command_kind = ""
	_load_dungeon_data(opts)
	_compute_wall_borders()
	_rebuild_colliders()
	DrawHelper.setup_layers(self)
	_build_interactables_and_portals()
	_evaluate_wires()

	GameState.active_perspective = "boy"
	GameState.book2_started = true
	if GameState.active_companion_stage < 1:
		GameState.active_companion_stage = 1
		GameState.brabant_hatched = true

	var sp_dict: Dictionary = dungeon_data.get("spawn", {"x": 320, "y": 730})
	var default_sp := Vector2(float(sp_dict.get("x", 320)), float(sp_dict.get("y", 730)))
	player.position = opts.get("spawn", default_sp)
	last_safe_pos = player.position
	checkpoint_pos = player.position
	player.facing = opts.get("facing", Vector2.UP)
	player.visible = true
	player.cutscene_hidden = false
	player.can_move = true
	player.set_carry_prop("", "")

	if director != null and director.camera != null:
		director.camera.limit_left = 0
		director.camera.limit_top = 0
		director.camera.limit_right = int(world_size.x)
		director.camera.limit_bottom = int(world_size.y)
		director.camera.position = player.position

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.update_world_map_state("custom_dungeon", player.position)
	ui.refresh_hud()
	SoundManager.set_ambience(get_ambience_track())


func is_node_enabled(target_id: String) -> bool:
	return LogicScript.is_enabled(self, target_id)


func _evaluate_wires(trigger_id: String = "") -> void:
	if LogicScript.evaluate(self, trigger_id):
		_rebuild_colliders()


func play_gate_fx(n: Dictionary, opened: bool) -> void:
	SoundManager.play_cage_break()
	if opened:
		SoundManager.play_chime()
	var rect: Rect2 = LogicScript.node_rect(self, n)
	spawn_sparks(rect.get_center(), Color(0.98, 0.84, 0.36), 20)


func play_pad_fx(n: Dictionary, down: bool) -> void:
	if down:
		SoundManager.play_cage_break()
	spawn_sparks(LogicScript.node_center(self, n), Color(0.9, 0.8, 0.5), 6)


func play_turret_fx(pos: Vector2) -> void:
	SoundManager.play_hit()
	spawn_sparks(pos, Color(0.85, 0.85, 0.8), 3)


func is_spike_up(n: Dictionary) -> bool:
	var nid: String = String(n.get("id", ""))
	if bool(node_states.get(nid, false)):
		return true
	if bool(n.get("periodic", false)):
		var period: float = maxf(0.8, float(n.get("periodSec", 2.4)))
		return fmod(trap_timer, period) >= period * 0.55
	return false


func handle_region_input(event: InputEvent) -> bool:
	if player == null or not player.visible or (ui != null and ui.is_blocking_gameplay()):
		return false
	if event.is_action_pressed("rope_action"):
		for n in nodes:
			var nid: String = String(n.get("id", ""))
			var ntype: String = String(n.get("type", ""))
			var np: Vector2 = get_node_pos(n)
			if ntype == "boulder" and player.position.distance_to(np) <= 46.0:
				var d: Vector2 = (np - player.position).normalized()
				var axis := Vector2(signf(d.x), 0.0) if absf(d.x) >= absf(d.y) else Vector2(0.0, signf(d.y))
				_slide_boulder(n, axis)
				return true
			if ntype == "sarcophagus" and not bool(node_states.get(nid, false)) and player.position.distance_to(np) <= 50.0:
				_push_sarcophagus(n)
				return true
	return false


func on_knife_slash(tip_pos: Vector2, _dir: Vector2) -> void:
	HazardScript.on_slash(self, tip_pos)


func step_region(delta: float) -> void:
	step_water_layer()
	trap_timer += delta
	if trap_cooldown > 0.0:
		trap_cooldown = maxf(0.0, trap_cooldown - delta)
	_step_push_blocks(delta)
	if LogicScript.step_sources(self, delta):
		_rebuild_colliders()
	HazardScript.step(self, delta)
	_step_fx(delta)
	if player_light != null and player != null:
		player_light.position = player.position
	if director != null and director.camera != null and player != null:
		director.camera.position = player.position
	if player != null and player.visible:
		update_nearest_interactable(player.position)
	queue_redraw()
	queue_foreground_redraw()


func _step_push_blocks(delta: float) -> void:
	if player == null or not player.can_move or (ui != null and ui.is_blocking_gameplay()):
		push_hold_t = 0.0
		push_target_id = ""
		return
	var move_in: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_in.length() < 0.25:
		push_hold_t = 0.0
		push_target_id = ""
		return
	for n in nodes:
		var nid: String = String(n.get("id", ""))
		var ntype: String = String(n.get("type", ""))
		if not (ntype == "boulder" or (ntype == "sarcophagus" and not bool(node_states.get(nid, false)))):
			continue
		var np: Vector2 = get_node_pos(n)
		if player.position.distance_to(np) > 42.0:
			continue
		var to_b: Vector2 = (np - player.position).normalized()
		if to_b.dot(move_in.normalized()) >= 0.45:
			if push_target_id != nid:
				push_target_id = nid
				push_hold_t = 0.0
			push_hold_t += delta
			if push_hold_t >= 0.16:
				push_hold_t = 0.0
				if ntype == "boulder":
					var axis := Vector2(signf(to_b.x), 0.0) if absf(to_b.x) >= absf(to_b.y) else Vector2(0.0, signf(to_b.y))
					_slide_boulder(n, axis)
				else:
					_push_sarcophagus(n)
			return
	push_hold_t = 0.0
	push_target_id = ""


func _slide_boulder(n: Dictionary, axis: Vector2) -> void:
	var nid: String = String(n.get("id", ""))
	var cur: Vector2 = get_node_pos(n)
	var nxt: Vector2 = cur + axis * 42.0
	var test_cols: Array[Rect2] = []
	for c: Rect2 in static_colliders:
		if not c.has_point(cur):
			test_cols.append(c)
	if point_hits_colliders(nxt, test_cols, 14.0):
		return
	node_positions[nid] = nxt
	SoundManager.play_cage_break()
	spawn_sparks(nxt, Color(0.86, 0.80, 0.62), 8)
	for pn in nodes:
		if String(pn.get("type", "")) == "weight_plate":
			var pid: String = String(pn.get("id", ""))
			var pp: Vector2 = get_node_pos(pn)
			if nxt.distance_to(pp) <= 26.0 and not bool(node_states.get(pid, false)):
				node_positions[nid] = pp
				node_states[pid] = true
				SoundManager.play_chime()
				spawn_sparks(pp, Color(0.98, 0.84, 0.34), 16)
				_evaluate_wires(pid)
	_rebuild_colliders()


func _push_sarcophagus(n: Dictionary) -> void:
	var nid: String = String(n.get("id", ""))
	if bool(node_states.get(nid, false)):
		return
	var gp: Vector2 = get_node_pos(n)
	node_states[nid] = true
	node_positions[nid] = gp + Vector2(0, -42)
	SoundManager.play_cage_break()
	_rebuild_colliders()
	if bool(n.get("isTrap", false)):
		SoundManager.play_hit()
		spawn_sparks(gp, Color(0.96, 0.32, 0.24), 16)
		_damage_player(1)
	else:
		SoundManager.play_chime()
		spawn_sparks(gp, Color(0.98, 0.86, 0.38), 18)
		_evaluate_wires(nid)


func get_rope_anchors() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for n in nodes:
		if String(n.get("type", "")) == "grapple_post":
			out.append(get_node_pos(n))
	return out


func on_rope_cast_hit(target_pos: Vector2, _knot_id: String) -> void:
	for n in nodes:
		if String(n.get("type", "")) == "grapple_post":
			var np: Vector2 = get_node_pos(n)
			if target_pos.distance_to(np) <= 70.0 and player.position.distance_to(np) > 56.0:
				var jump_dir: Vector2 = (np - player.position).normalized()
				player.position = np + jump_dir * 28.0
				SoundManager.play_rope()
				spawn_sparks(np, Color(0.96, 0.84, 0.36), 12)
				return


func _dragon_target_in_range(origin: Vector2, target_pos: Vector2, np: Vector2) -> bool:
	var ppos: Vector2 = player.position if player != null else origin
	return origin.distance_to(np) <= 95.0 or ppos.distance_to(np) <= 95.0 or target_pos.distance_to(np) <= 88.0


func find_dragon_command_target(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> Dictionary:
	for n in nodes:
		var nid: String = String(n.get("id", ""))
		var ntype: String = String(n.get("type", ""))
		if bool(node_states.get(nid, false)):
			continue
		var np: Vector2 = LogicScript.node_center(self, n)
		if not _dragon_target_in_range(origin, target_pos, np):
			continue
		if ntype == "serpent_vent":
			return {"kind": "vent_crawl", "target_pos": np, "stand_pos": np + Vector2(0, 26)}
		if ntype in ["ember_brazier", "briar_barrier", "secret_wall"]:
			return {"kind": "ember_puff", "target_pos": np, "stand_pos": np + Vector2(0, 26)}
	return {}


func on_dragon_command(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> bool:
	_last_command_kind = ""
	for n in nodes:
		var nid: String = String(n.get("id", ""))
		var ntype: String = String(n.get("type", ""))
		if bool(node_states.get(nid, false)):
			continue
		var np: Vector2 = LogicScript.node_center(self, n)
		if origin.distance_to(np) > 95.0 and target_pos.distance_to(np) > 88.0:
			continue
		if ntype == "serpent_vent":
			if not is_node_enabled(nid):
				SoundManager.play_hit()
				spawn_sparks(np, Color(0.75, 0.42, 0.36), 8)
				return false
			_last_command_kind = "vent_crawl"
			node_states[nid] = true
			_evaluate_wires(nid)
			return true
		if ntype in ["ember_brazier", "briar_barrier", "secret_wall"]:
			_last_command_kind = "ember_puff"
			node_states[nid] = true
			SoundManager.play_campfire_warm()
			spawn_sparks(np, Color(1.0, 0.78, 0.28), 16)
			if ntype != "ember_brazier":
				_rebuild_colliders()
			_evaluate_wires(nid)
			return true
	return false


func get_last_dragon_command_kind() -> String:
	return _last_command_kind


func _on_toggle_lever(nid: String) -> void:
	var n: Dictionary = _find_node(nid)
	if bool(node_states.get(nid, false)):
		node_states[nid] = false
		hold_timers.erase(nid)
	else:
		LogicScript.activate_timed(self, n)
	SoundManager.play_cage_break()
	spawn_sparks(get_node_pos(n), Color(0.96, 0.84, 0.36), 10)
	_evaluate_wires(nid)


func _on_read_plaque(n: Dictionary) -> void:
	SoundManager.play_chime()
	ui.show_dialogue([{
		"speaker": String(n.get("speaker", n.get("label", "Carved Plaque"))),
		"portrait": String(n.get("portrait", "portrait_hatchling_stage1.png")),
		"telepathic": bool(n.get("telepathic", false)),
		"text": String(n.get("text", "An ancient stone riddle.")),
	}])


func _on_claim_treasure(n: Dictionary) -> void:
	var nid: String = String(n.get("id", ""))
	if bool(node_states.get(nid, false)):
		return
	if not is_node_enabled(nid):
		SoundManager.play_hit()
		ui.show_dialogue([{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "An iron ward still seals this reliquary lock—something in the chamber must unlatch it first."}])
		return
	node_states[nid] = true
	var item_name: String = String(n.get("itemReward", "Studio Relic"))
	var bond_pts: int = int(n.get("bondReward", 15))
	GameState.boy_hp = GameState.boy_max_hp
	if not item_name.is_empty():
		GameState.add_item(item_name)
	if bond_pts > 0:
		GameState.add_dragon_bond(bond_pts)
	SoundManager.play_chime()
	spawn_sparks(get_node_pos(n), Color(1.0, 0.88, 0.36), 24)
	ui.refresh_hud()
	ui.show_dialogue([{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "Claimed %s from the chamber reliquary!" % item_name}])


func _on_exit_portal(target_region: String) -> void:
	director.load_region(target_region, {})


func is_interactable_active(id: String) -> bool:
	if id.begins_with("nd_"):
		var nid: String = id.substr(3)
		var n: Dictionary = _find_node(nid)
		var t: String = String(n.get("type", ""))
		if t == "treasure" or t == "locked_door":
			return not bool(node_states.get(nid, false))
	return true


func _damage_player(dmg: int) -> void:
	if player == null or player.is_invulnerable():
		return
	GameState.boy_hp = maxi(0, GameState.boy_hp - dmg)
	player.trigger_hurt_flash()
	SoundManager.play_hit()
	spawn_sparks(player.position, Color(0.96, 0.28, 0.24), 10)
	ui.refresh_hud()
	if GameState.boy_hp <= 0:
		ui.show_death_screen("Claimed by a dungeon trap.", func(): _retry_from_checkpoint())


func _retry_from_checkpoint() -> void:
	GameState.boy_hp = GameState.boy_max_hp
	dart_bolts.clear()
	player.position = checkpoint_pos
	last_safe_pos = checkpoint_pos
	ui.refresh_hud()


func _step_fx(delta: float) -> void:
	for i in range(fx_sparks.size() - 1, -1, -1):
		var sp: Dictionary = fx_sparks[i]
		sp["life"] = float(sp["life"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		if float(sp["life"]) <= 0.0:
			fx_sparks.remove_at(i)


func spawn_sparks(origin: Vector2, col: Color, count: int = 12) -> void:
	for _i in range(count):
		var a: float = randf() * TAU
		var s: float = randf_range(28.0, 92.0)
		fx_sparks.append({"pos": origin, "vel": Vector2(cos(a), sin(a)) * s, "life": randf_range(0.28, 0.55), "max_life": 0.55, "sz": randf_range(2.2, 3.8), "col": col})


func get_surface_at(_pos: Vector2) -> String:
	return "wood" if floor_style == "library_wood" else "cobble"


func get_ambience_track() -> String:
	return ambience_track


func get_lighting_tint() -> Color:
	return lighting_tint.lerp(Color(0.10, 0.10, 0.17), darkness)


func update_region_lights(_time_val: float) -> void:
	for i in range(region_lights.size()):
		var lid: String = light_ids[i]
		if lid == "__player":
			continue
		var n: Dictionary = _find_node(lid)
		if String(n.get("type", "")) == "ember_brazier" and not bool(node_states.get(lid, false)):
			region_lights[i].visible = false
		else:
			region_lights[i].visible = true
	sync_light_frustum(region_lights, true)


func _draw() -> void:
	DrawHelper.draw_region_entities(self, Time.get_ticks_msec() * 0.001)
