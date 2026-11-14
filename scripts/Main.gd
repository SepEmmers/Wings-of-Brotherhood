extends Node2D

## Modular Scene Director for Wings of the Brotherhood (Book I — Opening Chapters & Book II+ Campaign).
## Owns the persistent PixelAssets cache, World Lighting (CanvasModulate), PlayerBoy, Camera2D,
## GameUI CanvasLayer, and swaps modular RegionBase scenes cleanly as the campaign expands.

const PixelAssetsScript := preload("res://scripts/PixelAssets.gd")
const PlayerBoyScript := preload("res://scripts/PlayerBoy.gd")
const GameUIScript := preload("res://scripts/GameUI.gd")
const PlaytestPresetsScript := preload("res://scripts/data/PlaytestPresets.gd")
const PortOfBrugesScript := preload("res://scripts/regions/PortOfBrugesRegion.gd")
const WillemHouseScript := preload("res://scripts/regions/WillemHouseRegion.gd")
const SanctuaryScript := preload("res://scripts/regions/SanctuaryRegion.gd")
const VirelaiFlightScript := preload("res://scripts/regions/VirelaiFlightRegion.gd")
const FrontierWildsScript := preload("res://scripts/regions/FrontierWildsRegion.gd")
const WatchtowerHearthScript := preload("res://scripts/regions/WatchtowerHearthRegion.gd")
const BrugesCityScript := preload("res://scripts/regions/BrugesCityRegion.gd")
const BrugesOutskirtsScript := preload("res://scripts/regions/BrugesOutskirtsRegion.gd")
const SmokeRunnerScript := preload("res://scripts/tools/HeadlessSmokeRunner.gd")

var assets
var current_region_id: String = "bruges"
var world_modulate: CanvasModulate
var world_root: Node2D
var active_region: Node2D
var player: CharacterBody2D
var camera: Camera2D
var ui: CanvasLayer

var _current_ambience_key: String = ""
var _shake_timer: float = 0.0
var _shake_strength: float = 0.0
var _smoke_runner = null


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	assets = PixelAssetsScript.new()

	world_modulate = CanvasModulate.new()
	world_modulate.color = Color(0.84, 0.76, 0.88)
	add_child(world_modulate)

	world_root = Node2D.new()
	world_root.y_sort_enabled = true
	world_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world_root)

	player = PlayerBoyScript.new()
	player.set_assets(assets)
	player.visible = false
	player.can_move = false
	player.rope_cast_hit.connect(_on_player_rope_cast_hit)
	player.knife_slash.connect(_on_player_knife_slash)
	world_root.add_child(player)

	camera = Camera2D.new()
	camera.zoom = Vector2(1.5, 1.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

	ui = GameUIScript.new()
	add_child(ui)
	ui.setup_ui(assets)
	ui.start_game_requested.connect(_on_start_game_requested)
	ui.playtest_jump_requested.connect(_playtest_jump_to)
	ui.lighting_mode_changed.connect(_on_lighting_mode_changed)
	ui.replay_requested.connect(_on_replay_requested)
	ui.modal_state_changed.connect(_sync_player_can_move)

	load_region("bruges", {"title_bg": true})
	ui.show_name_prompt()
	_sync_player_can_move()

	if SmokeRunnerScript.should_run():
		_smoke_runner = SmokeRunnerScript.new()
		_smoke_runner.start(self)


func load_region(region_id: String, opts: Dictionary = {}) -> void:
	if active_region != null:
		active_region.exit_region()
		world_root.remove_child(active_region)
		active_region.queue_free()
		active_region = null

	if player != null:
		player.set_cutscene_pose("")
		player.cutscene_hidden = false
		player.winch_dash_active = false
		player.collision_mask = 1
		player.z_index = 10
	ui.set_cinematic_mode(false)
	camera.zoom = Vector2(1.5, 1.5)

	match region_id:
		"bruges":
			active_region = PortOfBrugesScript.new()
		"house":
			active_region = WillemHouseScript.new()
		"sanctuary":
			active_region = SanctuaryScript.new()
		"flight":
			active_region = VirelaiFlightScript.new()
		"wilds":
			active_region = FrontierWildsScript.new()
		"hearth":
			active_region = WatchtowerHearthScript.new()
		"bruges_city":
			active_region = BrugesCityScript.new()
		"outskirts":
			active_region = BrugesOutskirtsScript.new()
		_:
			push_warning("Unknown region_id '%s', defaulting to Port of Bruges." % region_id)
			active_region = PortOfBrugesScript.new()

	active_region.initialize_region(self, assets, player, ui)
	world_root.add_child(active_region)
	world_root.move_child(active_region, 0)
	current_region_id = region_id
	active_region.portal_cooldown = 0.85
	active_region.enter_region(opts)
	ui.update_world_map_state(current_region_id, player.position)
	camera.reset_smoothing()

	_sync_ambience_and_lighting(true)
	_sync_player_can_move()


func trigger_camera_shake(strength: float, duration: float = 0.25) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_timer = maxf(_shake_timer, duration)


func _process(delta: float) -> void:
	assets.time_elapsed += delta
	ui.process_ui(delta)
	_sync_player_can_move()

	if _smoke_runner != null and _smoke_runner.active:
		_smoke_runner.step(delta)

	if _shake_timer > 0.0:
		_shake_timer = maxf(0.0, _shake_timer - delta)
		camera.offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
		if _shake_timer <= 0.0:
			_shake_strength = 0.0
			camera.offset = Vector2.ZERO

	if active_region != null:
		active_region.step_region(delta)
		if active_region.uses_standard_player_movement():
			active_region.sync_npc_colliders()
			SoundManager.current_surface = active_region.get_surface_at(player.position)
			active_region.update_nearest_interactable(player.position)
			active_region.step_walk_portals(delta)
		ui.update_world_map_state(current_region_id, player.position)
		active_region.update_region_lights(assets.time_elapsed)
		_sync_ambience_and_lighting(false, delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("playtest_menu"):
		if ui.playtest_panel.visible or not ui.name_panel.visible or (event is InputEventKey and event.physical_keycode == KEY_F1):
			ui.toggle_playtest_menu()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_cancel") and ui.playtest_panel.visible:
		ui.toggle_playtest_menu()
		get_viewport().set_input_as_handled()
		return

	if ui.checkpoint_panel.visible:
		return

	if ui.dialogue_active:
		if event.is_action_pressed("interact"):
			ui.advance_dialogue()
			get_viewport().set_input_as_handled()
		return

	if ui.cutscene_active and not ui.playtest_panel.visible:
		if event.is_action_pressed("interact") and ui.trigger_cutscene_skip():
			get_viewport().set_input_as_handled()
		return

	if (
		event.is_action_pressed("inventory_screen")
		and not ui.name_panel.visible
		and not ui.knot_minigame.visible
		and (ui.butcher_minigame == null or not ui.butcher_minigame.visible)
		and not ui.playtest_panel.visible
	):
		ui.toggle_character_inventory()
		get_viewport().set_input_as_handled()
		return

	if (
		event.is_action_pressed("journal")
		and not ui.name_panel.visible
		and not ui.knot_minigame.visible
		and (ui.butcher_minigame == null or not ui.butcher_minigame.visible)
		and not ui.playtest_panel.visible
	):
		ui.toggle_journal()
		get_viewport().set_input_as_handled()
		return
	if (
		event.is_action_pressed("toggle_map")
		and not ui.name_panel.visible
		and not ui.knot_minigame.visible
		and (ui.butcher_minigame == null or not ui.butcher_minigame.visible)
		and not ui.playtest_panel.visible
		and not ui.dialogue_active
	):
		ui.toggle_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and ui.map_panel != null and ui.map_panel.visible:
		ui.toggle_map()
		get_viewport().set_input_as_handled()
		return

	if ui.is_blocking_gameplay():
		return

	if active_region != null and active_region.handle_region_input(event):
		get_viewport().set_input_as_handled()
		return

	if active_region != null and active_region.uses_standard_player_movement() and player != null and player.handle_tool_input(event):
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact") and active_region != null:
		if active_region.interact_with_nearest():
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("cycle_knot"):
		GameState.cycle_knot()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("practice_knot"):
		ui.open_knot_minigame(GameState.equipped_knot)
		get_viewport().set_input_as_handled()


func _sync_player_can_move() -> void:
	if player == null:
		return
	var blocked: bool = ui.is_blocking_gameplay()
	var uses_foot: bool = active_region != null and active_region.uses_standard_player_movement()
	player.can_move = uses_foot and not blocked
	player.allow_tools = uses_foot and not blocked and GameState.current_step > GameState.QuestStep.ON_THE_SHIP or (uses_foot and not blocked and GameState.ship_docked)
	if uses_foot and not blocked and not ui.cutscene_active and player.cutscene_pose == "boy_kneel.png":
		player.set_cutscene_pose("")


func _sync_ambience_and_lighting(immediate: bool, delta: float = 0.016) -> void:
	if active_region == null:
		return
	var want_amb: String = active_region.get_ambience_track()
	if want_amb != _current_ambience_key:
		_current_ambience_key = want_amb
		SoundManager.set_ambience(want_amb)

	var target_tint: Color = active_region.get_lighting_tint()
	match ui.lighting_mode:
		"dusk":
			target_tint = Color(0.84, 0.76, 0.88)
		"night":
			target_tint = Color(0.45, 0.48, 0.64)
		"dawn":
			target_tint = Color(0.66, 0.75, 0.86)

	if immediate:
		world_modulate.color = target_tint
	else:
		world_modulate.color = world_modulate.color.lerp(target_tint, minf(1.0, delta * 3.5))


func _on_player_rope_cast_hit(target_pos: Vector2, knot_id: String) -> void:
	if active_region != null:
		active_region.on_rope_cast_hit(target_pos, knot_id)


func _on_player_knife_slash(tip_pos: Vector2, dir: Vector2) -> void:
	if active_region != null:
		active_region.on_knife_slash(tip_pos, dir)


func _on_lighting_mode_changed(_mode: String) -> void:
	_sync_ambience_and_lighting(true)


func _on_start_game_requested(chosen_name: String) -> void:
	GameState.reset_prologue(chosen_name)
	ui.hide_all_overlays()
	load_region("bruges", {"mode": "sailing"})


func _on_replay_requested() -> void:
	ui.hide_all_overlays()
	load_region("bruges", {"title_bg": true})
	ui.show_name_prompt()
	_sync_player_can_move()

	if SmokeRunnerScript.should_run():
		_smoke_runner = SmokeRunnerScript.new()
		_smoke_runner.start(self)


func _playtest_jump_to(scene_id: String) -> void:
	var saved_name := GameState.player_name if not GameState.player_name.is_empty() else "Bram"
	GameState.reset_prologue(saved_name)
	ui.hide_all_overlays()
	SoundManager.play_chime()
	var target := PlaytestPresetsScript.apply_preset(scene_id)
	if not target.is_empty():
		load_region(target["region"], target["params"])
