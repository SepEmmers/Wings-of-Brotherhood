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
const BrabantFensScript := preload("res://scripts/regions/BrabantFensRegion.gd")
const LouvainCityScript := preload("res://scripts/regions/LouvainCityRegion.gd")
const LouvainCatacombsScript := preload("res://scripts/regions/LouvainCatacombsRegion.gd")
const OldHeverleeScript := preload("res://scripts/regions/OldHeverleeRegion.gd")
const OldHeverleeShrineScript := preload("res://scripts/regions/OldHeverleeShrineRegion.gd")
const AnnaSanctuaryCh1Script := preload("res://scripts/regions/AnnaSanctuaryCh1Region.gd")
const VirelaiConvoyRaidScript := preload("res://scripts/regions/VirelaiConvoyRaidRegion.gd")
const CustomDungeonScript := preload("res://scripts/regions/CustomDungeonRegion.gd")
const SmokeRunnerScript := preload("res://scripts/tools/HeadlessSmokeRunner.gd")
const VisualAuditRunnerScript := preload("res://scripts/tools/VisualAuditRunner.gd")
const HatchlingCompanionScript := preload("res://scripts/companions/HatchlingCompanion.gd")

var assets
var current_region_id: String = "bruges"
var world_modulate: CanvasModulate
var world_root: Node2D
var active_region: Node2D
var player: CharacterBody2D
var companion: Node2D
var camera: Camera2D
var ui: CanvasLayer

var _current_ambience_key: String = ""
var _shake_timer: float = 0.0
var _shake_strength: float = 0.0
var _smoke_runner = null
var _visual_audit = null
var _default_cam_zoom: Vector2 = Vector2(1.5, 1.5)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	assets = PixelAssetsScript.new()
	var app_theme := Theme.new()
	app_theme.default_font = assets.get_ui_font()
	get_tree().root.theme = app_theme

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
	ui.quit_requested.connect(_on_quit_requested)
	ui.modal_state_changed.connect(_sync_player_can_move)
	ui.companion_eat_requested.connect(_on_companion_eat_requested)

	companion = HatchlingCompanionScript.new()
	companion.setup(assets, player, ui, null)
	companion.visible = false
	world_root.add_child(companion)

	load_region("bruges", {"title_bg": true})
	ui.show_title_screen()
	_sync_player_can_move()

	if SmokeRunnerScript.should_run():
		_smoke_runner = SmokeRunnerScript.new()
		_smoke_runner.start(self)
	elif VisualAuditRunnerScript.should_run():
		_visual_audit = VisualAuditRunnerScript.new()
		_visual_audit.start(self)


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
		player.hurt_flash_timer = 0.0
		player.dodge_timer = 0.0
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
		"brabant_fens":
			active_region = BrabantFensScript.new()
		"louvain":
			active_region = LouvainCityScript.new()
		"louvain_catacombs":
			active_region = LouvainCatacombsScript.new()
		"old_heverlee":
			active_region = OldHeverleeScript.new()
		"old_heverlee_shrine":
			active_region = OldHeverleeShrineScript.new()
		"anna_ch1_sanctuary":
			active_region = AnnaSanctuaryCh1Script.new()
		"anna_ch1_raid":
			active_region = VirelaiConvoyRaidScript.new()
		"custom_dungeon":
			active_region = CustomDungeonScript.new()
		_:
			push_warning("Unknown region_id '%s', defaulting to Port of Bruges." % region_id)
			active_region = PortOfBrugesScript.new()

	active_region.initialize_region(self, assets, player, ui)
	world_root.add_child(active_region)
	world_root.move_child(active_region, 0)
	current_region_id = region_id
	active_region.portal_cooldown = 0.85
	active_region.enter_region(opts)
	if companion != null:
		companion.region = active_region
		companion.clear_hint_context()
		companion.step(0.0)
	ui.update_world_map_state(current_region_id, player.position)
	camera.reset_smoothing()

	_sync_ambience_and_lighting(true)
	_sync_player_can_move()


func trigger_camera_shake(strength: float, duration: float = 0.25) -> void:
	if not GameState.screen_shake_enabled:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_timer = maxf(_shake_timer, duration)


func _process(delta: float) -> void:
	assets.time_elapsed += delta
	ui.process_ui(delta)
	_sync_player_can_move()

	if _smoke_runner != null and _smoke_runner.active:
		_smoke_runner.step(delta)
	elif _visual_audit != null and _visual_audit.active:
		_visual_audit.step(delta)

	if not GameState.screen_shake_enabled and _shake_timer > 0.0:
		_shake_timer = 0.0
		_shake_strength = 0.0
		camera.offset = Vector2.ZERO
	elif _shake_timer > 0.0:
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
		if companion != null:
			if ui.is_title_visible():
				companion.visible = false
			else:
				companion.step(delta)
		ui.update_world_map_state(current_region_id, player.position)
		active_region.update_region_lights(assets.time_elapsed)
		_sync_ambience_and_lighting(false, delta)

	var target_zoom: Vector2 = active_region.get_default_camera_zoom() if (active_region != null and active_region.has_method("get_default_camera_zoom")) else _default_cam_zoom
	if ui.is_item_banner_visible():
		target_zoom = Vector2(2.15, 2.15)
		if player != null and active_region != null and active_region.uses_standard_player_movement():
			camera.position = camera.position.lerp(player.position + Vector2(0, -10), minf(1.0, delta * 6.0))
	elif ui.dialogue_active and not ui.cutscene_active and current_region_id != "flight" and current_region_id != "anna_ch1_raid":
		target_zoom = Vector2(2.05, 2.05)
		var anna_pos_v: Variant = active_region.get("anna_pos") if active_region != null else null
		var std_move: bool = active_region != null and active_region.uses_standard_player_movement()
		if active_region != null and (std_move or anna_pos_v is Vector2):
			var focus_origin: Vector2 = player.position if std_move else Vector2(anna_pos_v)
			var focus_pos: Vector2 = focus_origin
			var ipos_v: Variant = active_region.get("roadblock_speaker_pos")
			if not (ipos_v is Vector2 and ipos_v.is_finite()):
				ipos_v = active_region.get("last_interacted_pos")
			if ipos_v is Vector2 and ipos_v.is_finite() and ipos_v.distance_to(focus_origin) <= 190.0:
				focus_pos = focus_origin.lerp(ipos_v, 0.45) + Vector2(0, 14)
				assets.active_dialogue_speaker_pos = ipos_v
				assets.active_dialogue_player_pos = focus_origin
			else:
				focus_pos = focus_origin + Vector2(0, 14)
				assets.active_dialogue_speaker_pos = Vector2.INF
			camera.position = camera.position.lerp(focus_pos, minf(1.0, delta * 5.2))
	else:
		assets.active_dialogue_speaker_pos = Vector2.INF
		if active_region != null and active_region.has_method("clear_dialogue_focus"):
			active_region.clear_dialogue_focus()
	camera.zoom = camera.zoom.lerp(target_zoom, minf(1.0, delta * 5.2))


func _unhandled_input(event: InputEvent) -> void:
	if ui.is_rebind_active():
		return

	if event.is_action_pressed("playtest_menu"):
		if ui.settings_panel != null and ui.settings_panel.visible:
			pass
		elif ui.playtest_panel.visible or not ui.is_title_visible() or (event is InputEventKey and event.physical_keycode == KEY_F1):
			if ui.pause_panel != null and ui.pause_panel.visible:
				ui.pause_panel.visible = false
			ui.toggle_playtest_menu()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_cancel"):
		if ui.settings_panel != null and ui.settings_panel.visible:
			ui.close_settings()
			get_viewport().set_input_as_handled()
			return
		if ui.playtest_panel.visible:
			ui.toggle_playtest_menu()
			get_viewport().set_input_as_handled()
			return
		if ui.campfire_panel != null and ui.campfire_panel.visible:
			ui.campfire_panel.close_panel()
			get_viewport().set_input_as_handled()
			return
		if ui.is_parchment_open():
			ui.dismiss_parchment_note()
			get_viewport().set_input_as_handled()
			return
		if ui.is_item_banner_visible():
			ui.item_acquire_banner.dismiss()
			get_viewport().set_input_as_handled()
			return
		if ui.map_panel != null and ui.map_panel.visible:
			ui.toggle_map()
			get_viewport().set_input_as_handled()
			return
		if ui.journal_panel != null and ui.journal_panel.visible:
			ui.toggle_journal()
			get_viewport().set_input_as_handled()
			return
		if ui.pause_panel != null and ui.pause_panel.visible:
			ui.toggle_pause_menu()
			get_viewport().set_input_as_handled()
			return
		if ui.is_title_visible():
			if ui.title_panel != null and ui.title_panel.is_name_entry_visible():
				SoundManager.play_ui_click()
				ui.title_panel.show_main_menu()
				get_viewport().set_input_as_handled()
			return
		if not ui.is_blocking_gameplay():
			ui.toggle_pause_menu(_get_current_region_label())
			get_viewport().set_input_as_handled()
			return

	if ui.checkpoint_panel.visible:
		return

	if ui.is_item_banner_visible():
		if event.is_action_pressed("inventory_screen"):
			ui.item_acquire_banner.open_in_bag()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]):
			ui.item_acquire_banner.dismiss()
			get_viewport().set_input_as_handled()
		return

	if ui.is_parchment_open():
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]):
			ui.dismiss_parchment_note()
			get_viewport().set_input_as_handled()
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

	var menus_locked: bool = (
		ui.is_title_visible()
		or ui.knot_minigame.visible
		or (ui.butcher_minigame != null and ui.butcher_minigame.visible)
		or (ui.mason_minigame != null and ui.mason_minigame.visible)
		or ui.playtest_panel.visible
		or (ui.settings_panel != null and ui.settings_panel.visible)
		or (ui.pause_panel != null and ui.pause_panel.visible)
	)
	if event.is_action_pressed("inventory_screen") and not menus_locked:
		ui.toggle_character_inventory()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("journal") and not menus_locked:
		ui.toggle_journal()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_map") and not menus_locked and not ui.dialogue_active:
		ui.toggle_map()
		get_viewport().set_input_as_handled()
		return

	if ui.is_blocking_gameplay():
		return

	if companion != null and companion.handle_input(event):
		get_viewport().set_input_as_handled()
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
		var combat_swap := want_amb.ends_with("combat") or _current_ambience_key.ends_with("combat")
		_current_ambience_key = want_amb
		SoundManager.set_ambience(want_amb, 0.38 if combat_swap else 1.4)

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


func _on_companion_eat_requested(fire_pos: Vector2, on_done: Callable) -> void:
	if companion != null and companion.has_method("play_eat_animation") and companion.is_companion_enabled():
		companion.play_eat_animation(fire_pos, on_done)
	elif on_done.is_valid():
		on_done.call()


func _on_start_game_requested(chosen_name: String) -> void:
	GameState.reset_prologue(chosen_name)
	ui.hide_all_overlays()
	load_region("bruges", {"mode": "sailing"})


func _on_replay_requested() -> void:
	ui.hide_all_overlays()
	load_region("bruges", {"title_bg": true})
	ui.show_title_screen()
	_sync_player_can_move()

	if SmokeRunnerScript.should_run():
		_smoke_runner = SmokeRunnerScript.new()
		_smoke_runner.start(self)
	elif VisualAuditRunnerScript.should_run():
		_visual_audit = VisualAuditRunnerScript.new()
		_visual_audit.start(self)


func _on_quit_requested() -> void:
	GameState.apply_and_save_settings()
	get_tree().quit()


func _get_current_region_label() -> String:
	match current_region_id:
		"bruges":
			return "Port of Bruges"
		"willem_house":
			return "Uncle Willem's Cottage"
		"outskirts":
			return "Bruges Outskirts"
		"sanctuary":
			return "Brotherhood Sanctuary"
		"frontier_wilds":
			return "Flemish Frontier Wilds"
		"watchtower_hearth":
			return "Coastal Watchtower"
		"bruges_city":
			return "Walled City of Bruges"
		"brabant_fens":
			return "Brabant Reed-Fens"
		"louvain":
			return "Louvain (Dijle City)"
		"louvain_catacombs":
			return "Abbey Cathedral & Catacombs"
		"custom_dungeon":
			return "Custom Studio Dungeon"
	return "Flanders"


func _playtest_jump_to(scene_id: String) -> void:
	var saved_name := GameState.player_name if not GameState.player_name.is_empty() else "Bram"
	GameState.reset_prologue(saved_name)
	ui.hide_all_overlays()
	SoundManager.play_chime()
	var target := PlaytestPresetsScript.apply_preset(scene_id)
	if not target.is_empty():
		load_region(target["region"], target["params"])
