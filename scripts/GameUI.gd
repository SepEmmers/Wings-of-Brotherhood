extends CanvasLayer

## Centralized medieval parchment UI coordinator owning HUD, Title Prompt, Letterbox/Fade,
## Checkpoint Screen, Knot Minigame bridge, and modular subpanels under scripts/ui/.

signal start_game_requested(player_name: String)
signal playtest_jump_requested(scene_id: String)
signal lighting_mode_changed(mode: String)
signal replay_requested
signal quit_requested
signal modal_state_changed

const KnotMinigameScript := preload("res://scripts/KnotMinigame.gd")
const ButcherMinigameScript := preload("res://scripts/ui/ButcherMinigamePanel.gd")
const DialogueBoxScript := preload("res://scripts/ui/DialogueBox.gd")
const JournalModalScript := preload("res://scripts/ui/JournalModal.gd")
const ForestMapPanelScript := preload("res://scripts/ui/ForestMapPanel.gd")
const PlaytestMenuPanelScript := preload("res://scripts/ui/PlaytestMenuPanel.gd")
const TimeSkipPanelScript := preload("res://scripts/ui/TimeSkipPanel.gd")
const FailureScreenPanelScript := preload("res://scripts/ui/FailureScreenPanel.gd")
const BorderBannerPanelScript := preload("res://scripts/ui/BorderBannerPanel.gd")
const CampfirePanelScript := preload("res://scripts/ui/CampfirePanel.gd")
const TitleScreenPanelScript := preload("res://scripts/ui/TitleScreenPanel.gd")
const SettingsPanelScript := preload("res://scripts/ui/SettingsPanel.gd")
const PauseMenuPanelScript := preload("res://scripts/ui/PauseMenuPanel.gd")
const HudOverlayScript := preload("res://scripts/ui/HudOverlay.gd")

var assets
var lighting_mode: String = "auto"

var title_panel: Control
var name_panel: Control
var name_input: LineEdit
var settings_panel: Control
var pause_panel: Control
var hud_overlay: Control

var dialogue_panel: PanelContainer
var journal_panel: PanelContainer
var knot_minigame: Control
var butcher_minigame: Control
var map_panel: PanelContainer
var playtest_panel: PanelContainer
var failure_panel: Control
var campfire_panel: PanelContainer

var checkpoint_panel: ColorRect
var checkpoint_label: Label
var checkpoint_sub_label: Label

var time_skip_panel: ColorRect
var border_banner: Control

var letterbox_top: ColorRect
var letterbox_bot: ColorRect
var cutscene_skip_hint: Label
var fade_overlay: ColorRect

var cutscene_active: bool = false
var letterbox_target: float = 0.0
var letterbox_amount: float = 0.0
var fade_target: float = 0.0
var fade_alpha: float = 0.0
var skip_cutscene_cb: Callable

var dialogue_active: bool:
	get:
		return dialogue_panel != null and dialogue_panel.dialogue_active

var pending_knot_callback: Callable
var pending_knot_fail_callback: Callable
var pending_butcher_callback: Callable
var pending_butcher_cancel_callback: Callable


func setup_ui(assets_ref) -> void:
	assets = assets_ref
	_build_ui()
	GameState.state_updated.connect(func(): refresh_current_hud())
	GameState.knot_changed.connect(func(_id): refresh_current_hud())
	GameState.settings_changed.connect(_on_settings_changed)


func is_blocking_gameplay() -> bool:
	for p in [title_panel, settings_panel, pause_panel, journal_panel, map_panel, playtest_panel, knot_minigame, butcher_minigame, campfire_panel, checkpoint_panel, failure_panel]:
		if p != null and p.visible:
			return true
	return dialogue_active or cutscene_active


func is_title_visible() -> bool:
	return title_panel != null and title_panel.visible


func is_rebind_active() -> bool:
	return settings_panel != null and settings_panel.visible and settings_panel.is_rebind_active()


func process_ui(delta: float) -> void:
	if letterbox_top != null and letterbox_bot != null:
		letterbox_amount = move_toward(letterbox_amount, letterbox_target, delta * 3.2)
		var bar_h := 68.0 * letterbox_amount
		letterbox_top.size = Vector2(1280, bar_h)
		letterbox_bot.position = Vector2(0, 720.0 - bar_h)
		letterbox_bot.size = Vector2(1280, bar_h)
		letterbox_top.visible = bar_h > 0.5
		letterbox_bot.visible = bar_h > 0.5

	if fade_overlay != null:
		var fade_speed := 3.6 if (fade_target == 0.0 and fade_alpha <= 0.72) else 2.2
		fade_alpha = move_toward(fade_alpha, fade_target, delta * fade_speed)
		fade_overlay.color.a = fade_alpha
		fade_overlay.visible = fade_alpha > 0.01

	if time_skip_panel != null:
		time_skip_panel.process_stamp(delta)
	if border_banner != null:
		border_banner.step(delta)
	if dialogue_panel != null:
		dialogue_panel.process_typewriter(delta)
	if hud_overlay != null:
		hud_overlay.step(delta)


func pulse_hud_icon(kind: String, duration: float = 2.6) -> void:
	if hud_overlay != null:
		hud_overlay.pulse_icon(kind, duration)


func show_title_screen(open_name_step: bool = false) -> void:
	hide_all_overlays()
	set_hud_visible(false)
	if title_panel != null:
		title_panel.visible = true
		if open_name_step:
			title_panel.show_name_entry()
		else:
			title_panel.show_main_menu()
	emit_signal("modal_state_changed")


func show_name_prompt() -> void:
	show_title_screen(false)


func open_settings(initial_tab: int = -1) -> void:
	if settings_panel != null:
		SoundManager.play_ui_click()
		settings_panel.open_settings(initial_tab)
		emit_signal("modal_state_changed")


func close_settings() -> void:
	if settings_panel != null and settings_panel.visible:
		settings_panel.close_settings()
		emit_signal("modal_state_changed")


func toggle_pause_menu(region_title: String = "") -> void:
	if pause_panel == null:
		return
	SoundManager.play_ui_click()
	if pause_panel.visible:
		pause_panel.visible = false
	else:
		pause_panel.open_pause(region_title)
	emit_signal("modal_state_changed")


func _on_settings_changed() -> void:
	if not GameState.hints_enabled and hud_overlay != null:
		hud_overlay.clear_pulses()
	if settings_panel != null:
		settings_panel.sync_from_state()
	if title_panel != null:
		title_panel.refresh_status()
	if journal_panel != null and journal_panel.visible:
		journal_panel.refresh()
	if hud_overlay != null:
		hud_overlay.sync_playtest_btn_visibility()
	if cutscene_skip_hint != null:
		cutscene_skip_hint.visible = cutscene_active and skip_cutscene_cb.is_valid() and GameState.control_prompts_enabled
	refresh_current_hud()


func hide_all_overlays() -> void:
	if dialogue_panel != null:
		dialogue_panel.hide_box()
	if time_skip_panel != null:
		time_skip_panel.hide_stamp()
	if border_banner != null:
		border_banner.hide_banner()
	if settings_panel != null and settings_panel.has_method("close_settings"):
		settings_panel.close_settings()
	for node in [title_panel, settings_panel, pause_panel, journal_panel, map_panel, playtest_panel, knot_minigame, butcher_minigame, campfire_panel, checkpoint_panel, failure_panel, letterbox_top, letterbox_bot, fade_overlay, cutscene_skip_hint]:
		if node != null:
			node.visible = false
	cutscene_active = false
	letterbox_target = 0.0
	letterbox_amount = 0.0
	fade_target = 0.0
	fade_alpha = 0.0
	skip_cutscene_cb = Callable()
	pending_knot_callback = Callable()
	pending_knot_fail_callback = Callable()
	pending_butcher_callback = Callable()


func update_world_map_state(region_id: String, player_pos: Vector2) -> void:
	if map_panel != null and map_panel.has_method("set_player_location"):
		map_panel.set_player_location(region_id, player_pos)


func set_cinematic_mode(active: bool, on_skip: Callable = Callable()) -> void:
	cutscene_active = active
	letterbox_target = 1.0 if active else 0.0
	skip_cutscene_cb = on_skip if active else Callable()
	if cutscene_skip_hint != null:
		var interact_k := GameState.get_action_key_label("interact")
		cutscene_skip_hint.text = "[%s] Skip Cutscene" % interact_k
		cutscene_skip_hint.visible = active and on_skip.is_valid() and GameState.control_prompts_enabled
	if hud_overlay != null and not is_title_visible() and not checkpoint_panel.visible:
		set_hud_visible(not active)
	emit_signal("modal_state_changed")


func set_fade(alpha_val: float, immediate: bool = false) -> void:
	fade_target = clampf(alpha_val, 0.0, 1.0)
	if immediate:
		fade_alpha = fade_target
		if fade_overlay != null:
			fade_overlay.color.a = fade_alpha
			fade_overlay.visible = fade_alpha > 0.01


func play_border_transition(title_txt: String, sub_txt: String = "") -> void:
	set_fade(0.64, true)
	set_fade(0.0, false)
	if border_banner != null and title_txt != "":
		border_banner.show_banner(title_txt, sub_txt)


func trigger_cutscene_skip() -> bool:
	if cutscene_active and skip_cutscene_cb.is_valid():
		var cb := skip_cutscene_cb
		skip_cutscene_cb = Callable()
		if cutscene_skip_hint != null:
			cutscene_skip_hint.visible = false
		cb.call()
		return true
	return false


func set_hud_visible(show_hud: bool) -> void:
	if hud_overlay != null:
		hud_overlay.set_hud_visible(show_hud)


func set_flight_hud_mode(active: bool, mission_status: String = "") -> void:
	if hud_overlay != null:
		hud_overlay.set_flight_mode(active, mission_status)


func toggle_character_inventory() -> void:
	if map_panel != null and map_panel.visible:
		map_panel.visible = false
	SoundManager.play_journal()
	if journal_panel.visible and journal_panel.tab_idx == 0:
		journal_panel.visible = false
	else:
		journal_panel.tab_idx = 0
		journal_panel.visible = true
		journal_panel.refresh()
	emit_signal("modal_state_changed")


func toggle_journal() -> void:
	if map_panel != null and map_panel.visible:
		map_panel.visible = false
	SoundManager.play_journal()
	if journal_panel.visible:
		journal_panel.visible = false
	else:
		if journal_panel.tab_idx == 0:
			journal_panel.tab_idx = 1
		journal_panel.visible = true
		journal_panel.refresh()
	emit_signal("modal_state_changed")


func toggle_map() -> void:
	if map_panel == null:
		return
	if journal_panel.visible:
		journal_panel.visible = false
	map_panel.visible = not map_panel.visible
	SoundManager.play_journal()
	if map_panel.visible:
		map_panel.refresh()
	emit_signal("modal_state_changed")


func toggle_playtest_menu() -> void:
	SoundManager.play_ui_click()
	playtest_panel.visible = not playtest_panel.visible
	if playtest_panel.visible:
		if playtest_panel.has_method("refresh"):
			playtest_panel.refresh(true)
		if playtest_panel.has_method("grab_initial_focus"):
			playtest_panel.grab_initial_focus()
	emit_signal("modal_state_changed")


func show_dialogue(lines: Array, on_done: Callable = Callable()) -> void:
	if dialogue_panel != null:
		dialogue_panel.show_dialogue(lines, on_done)
		if not lines.is_empty():
			emit_signal("modal_state_changed")


func advance_dialogue() -> void:
	if dialogue_panel != null:
		dialogue_panel.advance()


func open_knot_minigame(knot_id: String, on_done: Callable = Callable(), on_fail: Callable = Callable()) -> void:
	pending_knot_callback = on_done
	pending_knot_fail_callback = on_fail
	knot_minigame.start_knot(knot_id)
	emit_signal("modal_state_changed")


func open_butcher_minigame(on_done: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	pending_butcher_callback = on_done
	pending_butcher_cancel_callback = on_cancel
	if butcher_minigame != null:
		butcher_minigame.start_butchering()
	emit_signal("modal_state_changed")


func open_campfire_roost(region_id: String, fire_pos: Vector2, site_title: String = "Wayside Campfire", kestrel_ready: bool = false, kestrel_label: String = "Meet Kestrel Courier") -> void:
	if campfire_panel != null:
		campfire_panel.open_roost(region_id, fire_pos, site_title, kestrel_ready, kestrel_label)


func show_chapter_checkpoint(title_txt: String, body_txt: String = "") -> void:
	set_hud_visible(false)
	checkpoint_label.text = title_txt
	checkpoint_sub_label.text = body_txt
	checkpoint_sub_label.visible = body_txt.strip_edges() != ""
	checkpoint_panel.visible = true
	emit_signal("modal_state_changed")


func show_death_screen(cause_text: String, on_retry: Callable = Callable()) -> void:
	if dialogue_panel != null:
		dialogue_panel.hide_box()
	if failure_panel != null:
		SoundManager.play_hit()
		failure_panel.show_death(cause_text, on_retry)


func show_mission_failed_screen(reason_text: String, on_retry: Callable = Callable()) -> void:
	if dialogue_panel != null:
		dialogue_panel.hide_box()
	if failure_panel != null:
		SoundManager.play_alert_horn()
		failure_panel.show_mission_failed(reason_text, on_retry)


func refresh_current_hud() -> void:
	if journal_panel != null and journal_panel.visible:
		journal_panel.refresh()
	if hud_overlay != null:
		hud_overlay.refresh_current()


func refresh_hud(flight_mode: bool = false, flight_status: String = "") -> void:
	if journal_panel != null and journal_panel.visible:
		journal_panel.refresh()
	if hud_overlay != null:
		hud_overlay.refresh(flight_mode, flight_status)


func _build_ui() -> void:
	var seal_tex: Texture2D = assets.get_tex("ui_wax_seal.png")
	title_panel = TitleScreenPanelScript.new()
	title_panel.z_index = 60
	title_panel.setup_panel(assets)
	title_panel.start_game_requested.connect(func(nm: String): _emit_start(nm))
	title_panel.settings_requested.connect(func(): open_settings())
	title_panel.playtest_requested.connect(toggle_playtest_menu)
	title_panel.quit_requested.connect(func(): emit_signal("quit_requested"))
	add_child(title_panel)
	name_panel = title_panel
	name_input = title_panel.name_input

	hud_overlay = HudOverlayScript.new()
	hud_overlay.setup(assets)
	hud_overlay.bag_pressed.connect(func(): SoundManager.play_ui_click(); toggle_character_inventory())
	hud_overlay.menu_pressed.connect(func(): toggle_pause_menu())
	hud_overlay.playtest_pressed.connect(toggle_playtest_menu)
	add_child(hud_overlay)
	_build_cinematic_curtains()

	dialogue_panel = DialogueBoxScript.new()
	dialogue_panel.setup(assets)
	dialogue_panel.dialogue_completed.connect(func(): emit_signal("modal_state_changed"))
	add_child(dialogue_panel)

	journal_panel = JournalModalScript.new()
	journal_panel.setup(assets)
	journal_panel.close_requested.connect(func(): emit_signal("modal_state_changed"))
	add_child(journal_panel)

	knot_minigame = KnotMinigameScript.new()
	knot_minigame.knot_completed.connect(_on_knot_minigame_completed)
	knot_minigame.knot_failed.connect(_on_knot_minigame_failed)
	knot_minigame.knot_cancelled.connect(_on_knot_minigame_cancelled)
	add_child(knot_minigame)

	butcher_minigame = ButcherMinigameScript.new()
	butcher_minigame.chop_completed.connect(_on_butcher_minigame_completed)
	butcher_minigame.chop_cancelled.connect(_on_butcher_minigame_cancelled)
	add_child(butcher_minigame)

	campfire_panel = CampfirePanelScript.new()
	campfire_panel.setup(assets, self)
	add_child(campfire_panel)

	map_panel = ForestMapPanelScript.new()
	map_panel.setup(assets)
	map_panel.close_requested.connect(toggle_map)
	add_child(map_panel)

	failure_panel = FailureScreenPanelScript.new()
	failure_panel.setup(assets, toggle_playtest_menu, func(): emit_signal("modal_state_changed"))
	add_child(failure_panel)

	playtest_panel = PlaytestMenuPanelScript.new()
	playtest_panel.z_index = 75
	playtest_panel.setup(assets)
	playtest_panel.jump_requested.connect(func(scene_id: String): emit_signal("playtest_jump_requested", scene_id))
	playtest_panel.lighting_mode_changed.connect(func(mode: String): lighting_mode = mode; emit_signal("lighting_mode_changed", mode))
	playtest_panel.open_knot_requested.connect(func(knot_id: String): open_knot_minigame(knot_id))
	playtest_panel.title_requested.connect(func():
		if is_title_visible():
			if playtest_panel.visible:
				toggle_playtest_menu()
		else:
			playtest_panel.visible = false
			emit_signal("replay_requested")
	)
	playtest_panel.close_requested.connect(toggle_playtest_menu)
	add_child(playtest_panel)

	pause_panel = PauseMenuPanelScript.new()
	pause_panel.z_index = 72
	pause_panel.setup_panel(assets)
	pause_panel.resume_requested.connect(func(): toggle_pause_menu())
	pause_panel.settings_requested.connect(func(): open_settings())
	pause_panel.journal_requested.connect(func(): pause_panel.visible = false; toggle_journal())
	pause_panel.map_requested.connect(func(): pause_panel.visible = false; toggle_map())
	pause_panel.playtest_requested.connect(func(): pause_panel.visible = false; toggle_playtest_menu())
	pause_panel.title_requested.connect(func(): pause_panel.visible = false; emit_signal("replay_requested"))
	pause_panel.quit_requested.connect(func(): emit_signal("quit_requested"))
	add_child(pause_panel)

	settings_panel = SettingsPanelScript.new()
	settings_panel.z_index = 80
	settings_panel.setup_panel(assets)
	settings_panel.close_requested.connect(close_settings)
	add_child(settings_panel)

	_build_checkpoint_panel(seal_tex)

	assets.style_buttons_recursive(self)
	journal_panel.apply_post_theme_fixes()
	for themed in [title_panel, pause_panel, settings_panel, playtest_panel, hud_overlay]:
		if themed != null and themed.has_method("apply_post_theme_fixes"):
			themed.apply_post_theme_fixes()
	var p_sb: StyleBox = assets.make_ui_9slice_style("ui_panel_9slice.png", 12.0, 20.0, 16.0)
	var b_norm: StyleBox = assets.make_ui_9slice_style("ui_btn_normal.png", 6.0, 14.0, 6.0)
	var b_hov: StyleBox = assets.make_ui_9slice_style("ui_btn_hover.png", 6.0, 14.0, 6.0)
	var b_prs: StyleBox = assets.make_ui_9slice_style("ui_btn_pressed.png", 6.0, 14.0, 6.0)
	if knot_minigame != null and knot_minigame.has_method("apply_medieval_ui_theme"):
		knot_minigame.apply_medieval_ui_theme(p_sb, b_norm, b_hov, b_prs)
	if butcher_minigame != null and butcher_minigame.has_method("apply_medieval_ui_theme"):
		butcher_minigame.apply_medieval_ui_theme(p_sb, b_norm, b_hov, b_prs)


func _make_lbl(txt: String, fsize: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	return l


func _make_icon_rect(tex: Texture2D, sz: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.custom_minimum_size = sz
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture = tex
	return r


func _make_c_rect(col: Color, pos: Vector2, sz: Vector2, parent: Node = null) -> ColorRect:
	var c := ColorRect.new()
	c.color = col
	c.position = pos
	c.size = sz
	if parent != null:
		parent.add_child(c)
	return c


func _build_cinematic_curtains() -> void:
	letterbox_top = _make_c_rect(Color(0.03, 0.03, 0.05, 0.96), Vector2.ZERO, Vector2.ZERO, self)
	letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letterbox_top.visible = false
	letterbox_bot = _make_c_rect(Color(0.03, 0.03, 0.05, 0.96), Vector2.ZERO, Vector2.ZERO, self)
	letterbox_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letterbox_bot.visible = false

	cutscene_skip_hint = _make_lbl("[Space / E] Skip Cutscene", 13, Color(0.84, 0.80, 0.72, 0.78), HORIZONTAL_ALIGNMENT_RIGHT)
	cutscene_skip_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	cutscene_skip_hint.offset_left = -220
	cutscene_skip_hint.offset_top = 20
	cutscene_skip_hint.offset_right = -24
	cutscene_skip_hint.offset_bottom = 44
	cutscene_skip_hint.visible = false
	add_child(cutscene_skip_hint)

	border_banner = BorderBannerPanelScript.new()
	add_child(border_banner)

	fade_overlay = _make_c_rect(Color(0.02, 0.02, 0.04, 0.0), Vector2.ZERO, Vector2.ZERO, self)
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.visible = false

	time_skip_panel = TimeSkipPanelScript.new()
	time_skip_panel.setup(assets)
	time_skip_panel.dismissed.connect(func(): emit_signal("modal_state_changed"))
	add_child(time_skip_panel)


func show_time_stamp(era_title: String, sub_title: String = "", duration: float = 2.4) -> void:
	if time_skip_panel != null:
		time_skip_panel.show_stamp(era_title, sub_title, duration)


func hide_time_stamp() -> void:
	if time_skip_panel != null:
		time_skip_panel.hide_stamp()


func show_time_skip(era_title: String, sub_title: String, chronicle_text: String, on_continue: Callable = Callable()) -> void:
	time_skip_panel.show_card(era_title, sub_title, chronicle_text, on_continue)
	emit_signal("modal_state_changed")


func dismiss_time_skip() -> void:
	if time_skip_panel != null:
		time_skip_panel.dismiss()


func _build_checkpoint_panel(seal_tex: Texture2D) -> void:
	checkpoint_panel = _make_c_rect(Color(0, 0, 0, 0), Vector2.ZERO, Vector2.ZERO, self)
	checkpoint_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	checkpoint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	checkpoint_panel.visible = false
	var cp_banner := PanelContainer.new()
	cp_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	cp_banner.offset_left = -380; cp_banner.offset_right = 380; cp_banner.offset_top = 18; cp_banner.offset_bottom = 148
	cp_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	var cp_sb := StyleBoxFlat.new()
	cp_sb.bg_color = Color(0.05, 0.06, 0.11, 0.88); cp_sb.border_color = Color(0.86, 0.70, 0.36, 0.94)
	cp_sb.set_border_width_all(2); cp_sb.set_corner_radius_all(6)
	cp_sb.content_margin_left = 18; cp_sb.content_margin_right = 18; cp_sb.content_margin_top = 10; cp_sb.content_margin_bottom = 12
	cp_banner.add_theme_stylebox_override("panel", cp_sb)
	checkpoint_panel.add_child(cp_banner)
	var cp_box := VBoxContainer.new()
	cp_box.add_theme_constant_override("separation", 8)
	cp_banner.add_child(cp_box)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 10)
	cp_box.add_child(title_row)
	var cp_crest: Texture2D = assets.get_tex("ui_brotherhood_emblem.png") if assets != null else null
	if cp_crest == null: cp_crest = seal_tex
	if cp_crest != null: title_row.add_child(_make_icon_rect(cp_crest, Vector2(44, 44)))
	checkpoint_label = _make_lbl("", 19, Color(0.96, 0.84, 0.48), HORIZONTAL_ALIGNMENT_CENTER)
	title_row.add_child(checkpoint_label)

	checkpoint_sub_label = _make_lbl("", 13, Color(0.86, 0.86, 0.90), HORIZONTAL_ALIGNMENT_CENTER)
	checkpoint_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	checkpoint_sub_label.visible = false
	cp_box.add_child(checkpoint_sub_label)

	var cp_btns := HBoxContainer.new()
	cp_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	cp_btns.add_theme_constant_override("separation", 12)
	cp_box.add_child(cp_btns)
	for bd in [
		["Continue Free Roam", 180, func(): checkpoint_panel.visible = false; set_hud_visible(true); emit_signal("modal_state_changed")],
		["Scene Jump [F1]", 150, func(): checkpoint_panel.visible = false; toggle_playtest_menu()],
		["Replay from Title", 150, func(): emit_signal("replay_requested")]
	]:
		var btn := Button.new()
		btn.text = bd[0]
		btn.custom_minimum_size = Vector2(int(bd[1]), 34)
		btn.pressed.connect(bd[2])
		cp_btns.add_child(btn)


func _emit_start(boy_name: String = "") -> void:
	SoundManager.play_ui_click()
	if title_panel != null:
		title_panel.visible = false
	var chosen := boy_name.strip_edges()
	if chosen == "" and name_input != null:
		chosen = name_input.text.strip_edges()
	emit_signal("start_game_requested", chosen if chosen != "" else "Bram")


func _on_knot_minigame_completed(knot_id: String) -> void:
	emit_signal("modal_state_changed")
	if pending_knot_callback.is_valid():
		var cb := pending_knot_callback
		pending_knot_callback = Callable()
		pending_knot_fail_callback = Callable()
		cb.call(knot_id)


func _on_knot_minigame_cancelled() -> void:
	pending_knot_callback = Callable()
	pending_knot_fail_callback = Callable()
	emit_signal("modal_state_changed")


func _on_butcher_minigame_completed() -> void:
	pending_butcher_cancel_callback = Callable()
	emit_signal("modal_state_changed")
	if pending_butcher_callback.is_valid():
		var cb := pending_butcher_callback
		pending_butcher_callback = Callable()
		cb.call()

func _on_butcher_minigame_cancelled() -> void:
	pending_butcher_callback = Callable()
	emit_signal("modal_state_changed")
	if pending_butcher_cancel_callback.is_valid():
		var cb := pending_butcher_cancel_callback
		pending_butcher_cancel_callback = Callable()
		cb.call()


func _on_knot_minigame_failed(knot_id: String) -> void:
	pending_knot_callback = Callable()
	var fail_cb := pending_knot_fail_callback
	pending_knot_fail_callback = Callable()
	emit_signal("modal_state_changed")
	if fail_cb.is_valid():
		fail_cb.call(knot_id)
