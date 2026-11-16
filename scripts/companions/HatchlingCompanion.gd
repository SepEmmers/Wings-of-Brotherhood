class_name HatchlingCompanion
extends Node2D

## Growing Golden Dragon companion controller across Stages 1-4 (Book II+).
## Handles spring follower physics, Assist/Stay/Sling AI postures [X],
## active Dragon Command [R], Gold-Sense chimes, and automatic stuck-time
## Mind-Voice telepathic hints (no hint button).

signal posture_changed(new_posture: String)
signal command_triggered(action_kind: String, origin: Vector2, target_pos: Vector2, stage: int)

var assets = null
var player: CharacterBody2D = null
var ui: CanvasLayer = null
var region = null

var facing: Vector2 = Vector2.DOWN
var walk_phase: float = 0.0
var _idle_t: float = 0.0
var is_moving: bool = false
var stay_pos: Vector2 = Vector2.ZERO
var _active_pulse_t: float = 0.0
var _active_pulse_kind: String = ""
var _pulse_origin: Vector2 = Vector2.ZERO
var _pulse_target: Vector2 = Vector2.ZERO
var _pulse_aim: Vector2 = Vector2.DOWN
var _ember_motes: Array[Dictionary] = []
var _vent_crawl_t: float = 0.0
var _vent_return_pos: Vector2 = Vector2.ZERO
var _command_cooldown: float = 0.0
var _gold_sense_cd: float = 0.0
var _gold_sense_glow: float = 0.0

# Automatic stuck-time telepathic hint monitor
var _hint_context_id: String = ""
var _hint_lines: Array = []
var _hint_world_pos: Vector2 = Vector2.ZERO
var _hint_threshold: float = 28.0
var _hint_stall_t: float = 0.0
var _hint_tier_shown: int = 0
var _hint_cooldown: float = 0.0
var _nudge_marker_t: float = 0.0


func setup(assets_ref, player_ref: CharacterBody2D, ui_ref: CanvasLayer, region_ref = null) -> void:
	assets = assets_ref
	player = player_ref
	ui = ui_ref
	region = region_ref
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 9
	if player != null:
		global_position = player.global_position - player.facing * 32.0
		stay_pos = global_position
	if not GameState.state_updated.is_connected(notify_progress):
		GameState.state_updated.connect(notify_progress)


func is_companion_enabled() -> bool:
	return GameState.active_companion_stage >= 1 and GameState.active_perspective == "boy"


func is_concealed_in_sling() -> bool:
	return is_companion_enabled() and GameState.companion_posture == "sling"


func set_hint_context(context_id: String, lines: Array, focus_pos: Vector2 = Vector2.ZERO, threshold_sec: float = 28.0) -> void:
	if _hint_context_id == context_id:
		_hint_lines = lines
		_hint_world_pos = focus_pos
		_hint_threshold = maxf(8.0, threshold_sec)
		return
	_hint_context_id = context_id
	_hint_lines = lines
	_hint_world_pos = focus_pos
	_hint_threshold = maxf(8.0, threshold_sec)
	_hint_stall_t = 0.0
	_hint_tier_shown = 0
	_hint_cooldown = 4.0


func clear_hint_context() -> void:
	_hint_context_id = ""
	_hint_lines = []
	_hint_stall_t = 0.0
	_hint_tier_shown = 0
	_vent_crawl_t = 0.0
	_vent_return_pos = Vector2.ZERO
	_ember_motes.clear()


func notify_progress() -> void:
	_hint_stall_t = 0.0
	_hint_cooldown = maxf(_hint_cooldown, 6.0)


func handle_input(event: InputEvent) -> bool:
	if not is_companion_enabled() or player == null:
		return false
	if ui != null and ui.is_blocking_gameplay():
		return false
	if region != null and not region.uses_standard_player_movement():
		return false

	if event.is_action_pressed("dragon_posture"):
		var np := GameState.cycle_companion_posture()
		if np == "stay":
			stay_pos = global_position
		elif np == "assist" and GameState.companion_posture == "assist":
			if global_position.distance_to(player.global_position) > 420.0:
				global_position = player.global_position - player.facing * 28.0
		_gold_sense_glow = 0.65
		SoundManager.play_blip(1.45 if np != "sling" else 0.92)
		emit_signal("posture_changed", np)
		queue_redraw()
		return true

	if event.is_action_pressed("dragon_command") and _command_cooldown <= 0.0:
		trigger_command()
		return true
	return false


func trigger_command() -> void:
	if player == null or _vent_crawl_t > 0.0:
		return
	if GameState.companion_posture == "sling":
		GameState.set_companion_posture("assist")
		global_position = player.global_position + player.facing * 18.0
	var stage := GameState.active_companion_stage
	var pf: Vector2 = player.facing
	var aim: Vector2 = pf.normalized() if pf.length_squared() > 0.01 else Vector2.DOWN
	facing = aim
	var origin: Vector2 = global_position
	var reach: float = 72.0 + float(stage) * 16.0
	var target_pos: Vector2 = origin + aim * reach
	var kind := _command_kind_for_stage(stage)

	if region != null and region.has_method("on_dragon_command"):
		var handled: bool = bool(region.on_dragon_command(origin, target_pos, aim, stage))
		if region.has_method("get_last_dragon_command_kind"):
			var rkind := str(region.get_last_dragon_command_kind())
			if not rkind.is_empty():
				kind = rkind
		if handled:
			notify_progress()

	_pulse_origin = origin
	_pulse_target = target_pos
	_pulse_aim = aim
	_active_pulse_kind = kind

	if kind == "vent_crawl":
		_vent_crawl_t = float(region.get_vent_crawl_duration()) if (region != null and region.has_method("get_vent_crawl_duration")) else 1.25
		_vent_return_pos = Vector2(region.get_vent_return_pos()) if (region != null and region.has_method("get_vent_return_pos")) else Vector2.ZERO
		_active_pulse_t = 0.0
		_ember_motes.clear()
		_command_cooldown = _vent_crawl_t + 0.12
		SoundManager.play_hatch_chirp()
		emit_signal("command_triggered", kind, origin, target_pos, stage)
		queue_redraw()
		return

	_command_cooldown = 0.72 if stage == 1 else 0.60
	_active_pulse_t = 0.44
	_spawn_breath_motes(kind, aim)
	if kind == "dry_cough":
		SoundManager.play_blip(1.38)
	elif kind == "ember_puff":
		SoundManager.play_oven_crackle()
		SoundManager.play_hatch_chirp()
	else:
		SoundManager.play_chime()
	emit_signal("command_triggered", kind, origin, target_pos, stage)
	queue_redraw()


func _command_kind_for_stage(stage: int) -> String:
	if stage >= 3:
		return "golden_flame"
	if stage == 2:
		return "resonance_lunge"
	if GameState.brabant_hatched and GameState.hatchling_fed_count == 0 and GameState.current_step == GameState.QuestStep.BOOK2_BRABANT_FENS:
		return "dry_cough"
	return "ember_puff"


func _spawn_breath_motes(kind: String, aim: Vector2) -> void:
	_ember_motes.clear()
	if kind != "ember_puff" and kind != "dry_cough":
		return
	var snout := aim * 11.0 + Vector2(0.0, -10.0)
	var base_ang := aim.angle()
	if kind == "dry_cough":
		for i in range(4):
			var a := base_ang + randf_range(-0.48, 0.48)
			var spd := randf_range(18.0, 34.0)
			var ml := randf_range(0.28, 0.40)
			_ember_motes.append({"pos": snout, "vel": Vector2(cos(a), sin(a)) * spd, "life": ml, "max_life": ml, "sz": randf_range(2.2, 3.6), "col": Color(0.58, 0.60, 0.64, 0.52), "smoke": true})
		return
	for i in range(9):
		var a := base_ang + randf_range(-0.42, 0.42)
		var spd := randf_range(34.0, 78.0)
		var ml := randf_range(0.26, 0.44)
		var col := Color(0.98, 0.84, 0.34, 0.95) if (i % 2 == 0) else Color(0.92, 0.46, 0.16, 0.95)
		_ember_motes.append({"pos": snout, "vel": Vector2(cos(a), sin(a)) * spd, "life": ml, "max_life": ml, "sz": randf_range(1.6, 2.8), "col": col, "smoke": false})
	for i in range(3):
		var sa := base_ang + randf_range(-0.32, 0.32)
		var sspd := randf_range(22.0, 42.0)
		_ember_motes.append({"pos": snout, "vel": Vector2(cos(sa), sin(sa)) * sspd, "life": 0.42, "max_life": 0.42, "sz": randf_range(2.8, 4.2), "col": Color(0.46, 0.42, 0.40, 0.42), "smoke": true})


func step(delta: float) -> void:
	var enabled := is_companion_enabled()
	visible = enabled
	if not enabled or player == null:
		return

	_command_cooldown = maxf(0.0, _command_cooldown - delta)
	_active_pulse_t = maxf(0.0, _active_pulse_t - delta)
	_gold_sense_cd = maxf(0.0, _gold_sense_cd - delta)
	_gold_sense_glow = maxf(0.0, _gold_sense_glow - delta)
	_nudge_marker_t = maxf(0.0, _nudge_marker_t - delta)
	_hint_cooldown = maxf(0.0, _hint_cooldown - delta)

	for i in range(_ember_motes.size() - 1, -1, -1):
		var m: Dictionary = _ember_motes[i]
		m["life"] = float(m["life"]) - delta
		m["vel"] = Vector2(m["vel"]) * maxf(0.0, 1.0 - delta * 2.8) + Vector2(0.0, -22.0 * delta)
		m["pos"] = Vector2(m["pos"]) + Vector2(m["vel"]) * delta
		if float(m["life"]) <= 0.0:
			_ember_motes.remove_at(i)

	if _vent_crawl_t > 0.0:
		_vent_crawl_t = maxf(0.0, _vent_crawl_t - delta)
		if _vent_crawl_t <= 0.0:
			global_position = _vent_return_pos if _vent_return_pos != Vector2.ZERO else (player.global_position - player.facing * 26.0)
			_vent_return_pos = Vector2.ZERO
			_gold_sense_glow = 0.65
		queue_redraw()
		return

	_update_follow_movement(delta)
	_step_gold_sense()
	_step_automatic_hint(delta)
	queue_redraw()


func _update_follow_movement(delta: float) -> void:
	if GameState.companion_posture == "sling":
		global_position = player.global_position + Vector2(0.0, -4.0)
		is_moving = false
		return

	if GameState.companion_posture == "stay":
		if global_position.distance_to(player.global_position) > 640.0:
			global_position = player.global_position - player.facing * 32.0
			stay_pos = global_position
		else:
			global_position = stay_pos
		is_moving = false
		_idle_t += delta * 2.0
		return

	if player.winch_dash_active:
		global_position = player.global_position + Vector2(0.0, -18.0)
		facing = player.facing
		is_moving = false
		_idle_t += delta * 2.0
		return

	var pf: Vector2 = player.facing
	var side := Vector2(-pf.y, pf.x) * 14.0
	var desired: Vector2 = player.global_position - pf * 30.0 + side
	var diff: Vector2 = desired - global_position
	var dist: float = diff.length()
	if dist > 420.0:
		global_position = desired
		is_moving = false
		_idle_t += delta * 2.0
	elif dist > 10.0:
		var spd := clampf(dist * 5.2, 95.0, 265.0)
		global_position += diff.normalized() * minf(dist, spd * delta)
		facing = diff.normalized()
		is_moving = true
		walk_phase += delta * 11.5
	else:
		is_moving = false
		_idle_t += delta * 2.0


func _step_gold_sense() -> void:
	if region == null or not region.has_method("get_gold_sense_targets"):
		return
	var targets: Array = region.get_gold_sense_targets()
	for tp in targets:
		if tp is Vector2 and global_position.distance_to(tp) < 210.0:
			_gold_sense_glow = maxf(_gold_sense_glow, 0.55)
			if _gold_sense_cd <= 0.0:
				_gold_sense_cd = 4.5
				SoundManager.play_blip(1.65)
			break


func _step_automatic_hint(delta: float) -> void:
	if not GameState.hints_enabled:
		return
	if _hint_context_id.is_empty() or _hint_lines.is_empty():
		return
	if ui != null and ui.is_blocking_gameplay():
		return
	if _hint_cooldown > 0.0 or player.knife_timer > 0.0 or player.dodge_timer > 0.0:
		return

	_hint_stall_t += delta
	if _hint_stall_t < _hint_threshold:
		return

	_hint_stall_t = 0.0
	_hint_cooldown = 40.0

	# Pre-telepathy or mute early Act I: subtle golden visual flare + soft chirp instead of words
	var stage := GameState.active_companion_stage
	var can_speak := stage >= 2 or GameState.dragon_bond >= 15
	if not can_speak:
		_gold_sense_glow = 1.4
		_nudge_marker_t = 2.2
		SoundManager.play_blip(1.55)
		return

	if _hint_tier_shown < _hint_lines.size():
		var idx := mini(_hint_tier_shown, _hint_lines.size() - 1)
		_hint_tier_shown += 1
		var line_text := str(_hint_lines[idx])
		if ui != null and not line_text.is_empty():
			ui.show_dialogue([
				{
					"speaker": GameState.gold_dragon_name,
					"portrait": GameState.get_hatchling_portrait(),
					"telepathic": true,
					"text": line_text,
				}
			], Callable())


func _draw() -> void:
	if not is_companion_enabled() or _vent_crawl_t > 0.0:
		return

	if GameState.companion_posture == "sling":
		# Hooded leather & emerald sling satchel icon over Boy's shoulder with subtle golden scale glint
		var sling_tex: Texture2D = assets.get_tex("prop_hatchling_sling.png") if assets != null else null
		var bob := sin(float(assets.time_elapsed) * 3.5) * 1.2 if assets != null else 0.0
		if sling_tex != null:
			draw_texture_rect(sling_tex, Rect2(Vector2(2, -22 + bob), Vector2(18, 18)), false)
		else:
			var gl := 0.35 + 0.25 * sin(float(assets.time_elapsed) * 4.0 if assets != null else 0.0)
			draw_circle(Vector2(6, -12), 4.0, Color(0.96, 0.78, 0.26, gl))
		return

	var step_idx := 0
	var bob := 0.0
	if is_moving:
		step_idx = int(walk_phase) % 2
		bob = -2.2 * absf(sin(walk_phase * 0.6))
	else:
		bob = -1.2 + sin(_idle_t * 1.45) * 1.9
		step_idx = 1 if fmod(_idle_t * 0.48, 1.0) > 0.68 else 0

	# Shadow narrows subtly as dragonet hovers upward
	var shadow_s := clampf(1.0 + bob * 0.03, 0.84, 1.06)
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(shadow_s, 0.45 * shadow_s))
	draw_circle(Vector2.ZERO, 9.0 + float(GameState.active_companion_stage) * 2.0, Color(0.05, 0.06, 0.08, 0.42))
	draw_set_transform(Vector2.ZERO)

	if _gold_sense_glow > 0.0:
		var pulse_r := 14.0 + (1.0 - fmod(_gold_sense_glow, 1.0)) * 12.0
		draw_arc(Vector2(0, -8), pulse_r, 0.0, TAU, 20, Color(0.98, 0.82, 0.32, clampf(_gold_sense_glow, 0.0, 0.75)), 1.6)

	if _nudge_marker_t > 0.0 and _hint_world_pos != Vector2.ZERO:
		var nudge_dir := (_hint_world_pos - global_position).normalized()
		var p_dot := nudge_dir * (18.0 + 6.0 * sin(_nudge_marker_t * 6.0)) + Vector2(0, -10)
		draw_circle(p_dot, 4.5, Color(0.98, 0.84, 0.34, clampf(_nudge_marker_t, 0.0, 0.85)))

	var dir_key := "down"
	var flip_x := false
	if absf(facing.x) > 0.30 and absf(facing.y) > 0.30:
		dir_key = "diag_down" if facing.y >= 0.0 else "diag_up"
		flip_x = facing.x < 0.0
	elif absf(facing.x) > absf(facing.y) * 1.05:
		dir_key = "side"
		flip_x = facing.x < 0.0
	elif facing.y < 0.0:
		dir_key = "up"
	var tex_key := "dragon_gold_s1_%s_%d.png" % [dir_key, step_idx]
	var tex: Texture2D = assets.get_tex(tex_key) if assets != null else null
	if tex != null:
		var sz := Vector2(26.0 + float(GameState.active_companion_stage) * 5.0, 24.0 + float(GameState.active_companion_stage) * 4.5)
		var pos := Vector2(-sz.x * 0.5, -sz.y + 4.0 + bob)
		if flip_x:
			draw_texture_rect(tex, Rect2(Vector2(pos.x + sz.x, pos.y), Vector2(-sz.x, sz.y)), false)
		else:
			draw_texture_rect(tex, Rect2(pos, sz), false)
	else:
		draw_circle(Vector2(0, -8), 8.0, Color(0.24, 0.22, 0.24))
		draw_circle(Vector2(0, -10), 4.0, Color(0.94, 0.76, 0.26))

	for m: Dictionary in _ember_motes:
		var a := clampf(float(m["life"]) / float(m["max_life"]), 0.0, 1.0)
		var col: Color = Color(m["col"])
		col.a *= a
		var mp: Vector2 = Vector2(m["pos"])
		var sz: float = float(m["sz"]) * (1.2 - 0.3 * a if bool(m.get("smoke", false)) else 0.5 + 0.5 * a)
		if bool(m.get("smoke", false)):
			draw_circle(mp, sz, col)
		else:
			draw_rect(Rect2(mp - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), col)

	if _active_pulse_t > 0.0:
		var p := 1.0 - (_active_pulse_t / 0.44)
		if _active_pulse_kind == "ember_puff":
			if p < 0.35:
				var mpos := _pulse_aim * 11.0 + Vector2(0.0, -10.0)
				draw_circle(mpos, 3.2 * (1.0 - p / 0.35), Color(1.0, 0.80, 0.32, 0.85))
		elif _active_pulse_kind == "resonance_lunge":
			var world_loc := to_local(_pulse_origin).lerp(to_local(_pulse_target), minf(1.0, p * 1.4)) + Vector2(0, -8)
			draw_arc(world_loc, 8.0 + p * 18.0, 0.0, TAU, 18, Color(0.98, 0.86, 0.36, 0.85 * (1.0 - p)), 2.2)
		elif _active_pulse_kind == "golden_flame":
			var world_loc := to_local(_pulse_origin).lerp(to_local(_pulse_target), minf(1.0, p * 1.4)) + Vector2(0, -8)
			draw_circle(world_loc, 6.0 + p * 8.0, Color(1.0, 0.84, 0.34, 0.88 * (1.0 - p)))
			draw_arc(world_loc, 9.0 + p * 14.0, 0.0, TAU, 16, Color(1.0, 0.94, 0.62, 0.85 * (1.0 - p)), 2.0)
