extends CanvasLayer

## Centralized medieval parchment UI coordinator owning HUD, Title Prompt, Letterbox/Fade,
## Checkpoint Screen, Knot Minigame bridge, and modular subpanels under scripts/ui/.

signal start_game_requested(player_name: String)
signal playtest_jump_requested(scene_id: String)
signal lighting_mode_changed(mode: String)
signal replay_requested
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

var assets
var lighting_mode: String = "auto"

var name_panel: PanelContainer
var name_input: LineEdit

var hud_panel: PanelContainer
var hud_knot_icon: TextureRect
var hud_egg_icon: TextureRect
var hud_compass_icon: TextureRect
var hud_map_icon: TextureRect
var hud_wing_icon: TextureRect
var status_label: Label
var hud_hp_label: Label
var hud_bag_btn: Button
var hud_warmth_wrap: HBoxContainer
var hud_warmth_title_lbl: Label
var hud_warmth_fill: ColorRect
var hud_warmth_pct_lbl: Label
var knot_hud_label: Label
var hud_playtest_btn: Button

var dialogue_panel: PanelContainer
var journal_panel: PanelContainer
var knot_minigame: Control
var butcher_minigame: Control
var map_panel: PanelContainer
var playtest_panel: PanelContainer
var failure_panel: Control

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
var is_flight_hud_mode: bool = false
var custom_flight_status: String = ""
var hud_bag_pulse_t: float = 0.0
var hud_map_pulse_t: float = 0.0


func setup_ui(assets_ref) -> void:
	assets = assets_ref
	_build_ui()
	GameState.state_updated.connect(func(): refresh_hud(is_flight_hud_mode, custom_flight_status))
	GameState.knot_changed.connect(func(_id): refresh_hud(is_flight_hud_mode, custom_flight_status))


func is_blocking_gameplay() -> bool:
	for p in [name_panel, journal_panel, map_panel, playtest_panel, knot_minigame, butcher_minigame, checkpoint_panel, failure_panel]:
		if p != null and p.visible:
			return true
	return dialogue_active or cutscene_active


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

	hud_bag_pulse_t = maxf(0.0, hud_bag_pulse_t - delta)
	hud_map_pulse_t = maxf(0.0, hud_map_pulse_t - delta)
	if hud_bag_btn != null:
		var bw := (0.5 + 0.5 * sin(hud_bag_pulse_t * 11.0)) if hud_bag_pulse_t > 0.0 else 0.0
		hud_bag_btn.modulate = Color(1.0 + 0.35 * bw, 1.0 + 0.18 * bw, 1.0 - 0.25 * bw) if bw > 0.0 else Color.WHITE
	if hud_map_icon != null:
		var mw := (0.5 + 0.5 * sin(hud_map_pulse_t * 11.0)) if hud_map_pulse_t > 0.0 else 0.0
		hud_map_icon.modulate = Color(1.0 + 0.45 * mw, 1.0 + 0.25 * mw, 1.0 - 0.20 * mw) if mw > 0.0 else Color.WHITE
		if knot_hud_label != null:
			knot_hud_label.modulate = Color(1.0 + 0.18 * mw, 1.0 + 0.10 * mw, 1.0 - 0.10 * mw) if mw > 0.0 else Color.WHITE


func pulse_hud_icon(kind: String, duration: float = 2.6) -> void:
	if kind == "bag":
		hud_bag_pulse_t = maxf(hud_bag_pulse_t, duration)
	elif kind == "map":
		hud_map_pulse_t = maxf(hud_map_pulse_t, duration)
		hud_bag_pulse_t = maxf(hud_bag_pulse_t, duration)


func show_name_prompt() -> void:
	hide_all_overlays()
	set_hud_visible(false)
	name_panel.visible = true
	name_input.grab_focus()


func hide_all_overlays() -> void:
	if dialogue_panel != null:
		dialogue_panel.hide_box()
	if time_skip_panel != null:
		time_skip_panel.hide_stamp()
	if border_banner != null:
		border_banner.hide_banner()
	for node in [name_panel, journal_panel, map_panel, playtest_panel, knot_minigame, butcher_minigame, checkpoint_panel, failure_panel, letterbox_top, letterbox_bot, fade_overlay, cutscene_skip_hint]:
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
		cutscene_skip_hint.visible = active and on_skip.is_valid()
	if hud_panel != null and not name_panel.visible and not checkpoint_panel.visible:
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
	hud_panel.visible = show_hud
	hud_playtest_btn.visible = show_hud


func set_flight_hud_mode(active: bool, mission_status: String = "") -> void:
	is_flight_hud_mode = active
	custom_flight_status = mission_status
	refresh_hud(active, mission_status)


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


func open_butcher_minigame(on_done: Callable = Callable()) -> void:
	pending_butcher_callback = on_done
	if butcher_minigame != null:
		butcher_minigame.start_butchering()
	emit_signal("modal_state_changed")


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


const _CARRY_TAGS := {
	"leather": "  |  Hands: Harness-Leather Bale",
	"water": "  |  Hands: Cliff-Spring Bucket",
	"fish": "  |  Hands: Fresh Silver Herring",
	"mutton": "  |  Hands: Butchered Mutton Quarter",
}


func _set_bar(pct_raw: float, title_txt: String, col: Color) -> void:
	var pct := clampf(pct_raw, 0.0, 100.0)
	hud_warmth_wrap.visible = true
	hud_warmth_title_lbl.text = title_txt
	hud_warmth_fill.size = Vector2(maxf(2.0, 80.0 * (pct / 100.0)), 8.0)
	hud_warmth_fill.color = col
	hud_warmth_pct_lbl.text = "%d%%" % int(round(pct))


func refresh_hud(flight_mode: bool = false, flight_status: String = "") -> void:
	if hud_panel == null:
		return
	is_flight_hud_mode = flight_mode
	custom_flight_status = flight_status
	if journal_panel != null and journal_panel.visible:
		journal_panel.refresh()

	if flight_mode:
		for ic in [hud_compass_icon, hud_egg_icon, hud_map_icon, hud_bag_btn, hud_hp_label]:
			if ic != null:
				ic.visible = false
		hud_wing_icon.visible = true
		status_label.text = flight_status if flight_status != "" else "Crewing Virelai"
		var hp_pct := float(GameState.virelai_harness_hp)
		var bar_col := Color(0.92, 0.24, 0.22) if GameState.virelai_loose_straps > 0 else (Color(0.38, 0.84, 0.56) if hp_pct >= 55.0 else Color(0.95, 0.62, 0.22))
		_set_bar(hp_pct, "Harness", bar_col)
		if GameState.virelai_loose_straps > 0:
			knot_hud_label.text = "[!] SHEARED BUCKLE — PRESS [F] TO SPLICE RIGGING!"
			knot_hud_label.add_theme_color_override("font_color", Color(1.0, 0.56, 0.48))
		else:
			knot_hud_label.text = "[WASD] Fly  [Click/V] Crossbow Bolts  [C] Barrel-Roll  [E] Sketch" if GameState.flight_sortie_id == 1 else "[WASD] Fly  [Click/V] Bolts  [C] Barrel-Roll  [Clouds] Hide  [E] Sketch  [F] Splice"
			knot_hud_label.add_theme_color_override("font_color", Color(0.75, 0.90, 0.80))
		return

	hud_wing_icon.visible = false
	hud_compass_icon.visible = GameState.has_mariner_compass
	hud_egg_icon.visible = GameState.carrying_egg
	if hud_map_icon != null:
		hud_map_icon.visible = GameState.has_forest_map

	var carry_tag := "  |  Hands: Herring Crate" if GameState.carrying_crate else ("  |  Cradling Dragon Egg" if GameState.carrying_egg else str(_CARRY_TAGS.get(GameState.sanctuary_carrying_item, "")))
	var era_tag := ""
	if GameState.current_step == GameState.QuestStep.ACT2_SANCTUARY:
		era_tag = "  •  Yr %d (Trust %d%%)" % [1 if GameState.sanctuary_phase == 1 else (3 if GameState.sanctuary_phase == 2 else 5), GameState.dragon_trust]
	elif GameState.current_step == GameState.QuestStep.ACT4_SANCTUARY_DEBATE:
		era_tag = "  •  Council Debate"
	elif GameState.current_step == GameState.QuestStep.ACT4_BRUGES_CITY:
		era_tag = "  •  Walled Bruges"
	elif GameState.current_step == GameState.QuestStep.ACT4_NIGHT_HEIST:
		era_tag = "  •  Midnight Heist"
	status_label.text = "%s (Age %d)%s%s" % [GameState.player_name, GameState.boy_age, era_tag, carry_tag]

	var bag_count := GameState.inventory.size() + (1 if GameState.carrying_crate else 0)
	if hud_bag_btn != null:
		hud_bag_btn.visible = true
		hud_bag_btn.text = "Bag [I]: %d" % bag_count if bag_count > 0 else "Bag [I]"

	var show_hp := GameState.current_step in [GameState.QuestStep.SNITCH_TO_CHURCH, GameState.QuestStep.ACT4_BRUGES_CITY, GameState.QuestStep.ACT4_NIGHT_HEIST] or GameState.boy_hp < GameState.boy_max_hp
	hud_hp_label.visible = show_hp
	if show_hp:
		var hearts := ""
		for i in range(GameState.boy_max_hp):
			hearts += "♥" if i < GameState.boy_hp else "♡"
		hud_hp_label.text = "Health: " + hearts

	hud_warmth_wrap.visible = GameState.carrying_egg
	if GameState.carrying_egg:
		var pct := GameState.egg_warmth
		var w_col := Color(0.95, 0.68, 0.24) if pct >= 55.0 else (Color(0.92, 0.45, 0.18) if pct >= 30.0 else Color(0.90, 0.24, 0.22))
		_set_bar(pct, "Warmth", w_col)

	var kdata: Dictionary = GameState.KNOT_DATA[GameState.equipped_knot]
	knot_hud_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.78))
	knot_hud_label.text = "Knot [Q]: %s (%s)  |  [F] Cast  [V] Knife  [I] Bag  [Tab] Diary  |  [M] World Map" % [kdata["name"], kdata.get("ability_short", kdata["throw_style"])]


func _build_ui() -> void:
	var seal_tex: Texture2D = assets.get_tex("ui_wax_seal.png")
	_build_name_prompt(seal_tex)
	_build_hud()
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
	butcher_minigame.chop_cancelled.connect(func(): pending_butcher_callback = Callable(); emit_signal("modal_state_changed"))
	add_child(butcher_minigame)

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
		if name_panel.visible:
			if playtest_panel.visible:
				toggle_playtest_menu()
		else:
			playtest_panel.visible = false
			emit_signal("replay_requested")
	)
	playtest_panel.close_requested.connect(toggle_playtest_menu)
	add_child(playtest_panel)

	_build_checkpoint_panel(seal_tex)

	assets.style_buttons_recursive(self)
	journal_panel.apply_post_theme_fixes()
	if playtest_panel.has_method("apply_post_theme_fixes"):
		playtest_panel.apply_post_theme_fixes()
	if hud_bag_btn != null:
		hud_bag_btn.add_theme_font_size_override("font_size", 12)
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


func _build_name_prompt(seal_tex: Texture2D) -> void:
	name_panel = PanelContainer.new()
	name_panel.set_anchors_preset(Control.PRESET_CENTER)
	name_panel.offset_left = -335
	name_panel.offset_top = -255
	name_panel.offset_right = 335
	name_panel.offset_bottom = 255
	assets.style_parchment_panel(name_panel)
	add_child(name_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	name_panel.add_child(vbox)

	var crest_tex: Texture2D = assets.get_tex("ui_brotherhood_emblem.png")
	if crest_tex != null:
		vbox.add_child(_make_icon_rect(crest_tex, Vector2(56, 56)))

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 12)
	vbox.add_child(title_row)
	if seal_tex != null:
		title_row.add_child(_make_icon_rect(seal_tex, Vector2(32, 32)))
	title_row.add_child(_make_lbl("WINGS OF THE BROTHERHOOD", 22, Color(0.96, 0.84, 0.50), HORIZONTAL_ALIGNMENT_CENTER))
	if seal_tex != null:
		title_row.add_child(_make_icon_rect(seal_tex, Vector2(32, 32)))

	vbox.add_child(_make_lbl("Book I: Opening Chapters — Aboard 'De Zwaan' & The Port of Bruges", 15, Color(0.78, 0.75, 0.68), HORIZONTAL_ALIGNMENT_CENTER))
	var title_rule := _make_c_rect(Color(0.66, 0.52, 0.26, 0.55), Vector2.ZERO, Vector2.ZERO, vbox)
	title_rule.custom_minimum_size = Vector2(0, 1)

	var lore_blurb := _make_lbl(
		"Dusk settles over the Zwin canal. At twelve years old, your palms are raw from hauling lines aboard the merchant cog 'De Zwaan'.\n\n"
		+ "Ahead lie the timber wharves of the Port of Bruges, where your sister Clara twists cordage at the Ropewalk and Uncle Willem keeps a warm hearth—all the home you two have left since your parents failed to return from Old Heverlee four years ago.",
		14, Color(0.92, 0.90, 0.85)
	)
	lore_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lore_blurb)
	vbox.add_child(_make_lbl("What is the boy's name?", 16, Color(0.95, 0.82, 0.48)))

	name_input = LineEdit.new()
	name_input.placeholder_text = "Enter name (e.g. Bram, Hendrik, Pieter...)"
	name_input.text = "Bram"
	name_input.max_length = 24
	name_input.text_submitted.connect(func(_t): _emit_start())
	vbox.add_child(name_input)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)
	var start_btn := Button.new()
	start_btn.text = "Begin on Deck of 'De Zwaan'"
	start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_btn.custom_minimum_size = Vector2(0, 42)
	start_btn.pressed.connect(_emit_start)
	btn_row.add_child(start_btn)
	var title_pt_btn := Button.new()
	title_pt_btn.text = "Chapters / Debug [F1]"
	title_pt_btn.custom_minimum_size = Vector2(215, 42)
	title_pt_btn.pressed.connect(toggle_playtest_menu)
	btn_row.add_child(title_pt_btn)


func _build_hud() -> void:
	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(16, 14)
	hud_panel.custom_minimum_size = Vector2(560, 0)
	hud_panel.visible = false
	assets.style_parchment_panel(hud_panel, true)
	add_child(hud_panel)

	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 5)
	hud_panel.add_child(hud_box)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	hud_box.add_child(status_row)
	hud_compass_icon = _make_hud_icon("icon_compass.png")
	hud_egg_icon = _make_hud_icon("icon_egg.png")
	hud_map_icon = _make_hud_icon("icon_map.png")
	hud_wing_icon = _make_hud_icon("icon_wing.png")
	for ic in [hud_compass_icon, hud_egg_icon, hud_map_icon, hud_wing_icon]:
		status_row.add_child(ic)

	status_label = _make_lbl("", 14, Color(0.96, 0.86, 0.56))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.clip_text = true
	status_row.add_child(status_label)

	hud_hp_label = _make_lbl("", 13, Color(0.95, 0.52, 0.48))
	hud_hp_label.visible = false
	status_row.add_child(hud_hp_label)

	hud_warmth_wrap = HBoxContainer.new()
	hud_warmth_wrap.add_theme_constant_override("separation", 6)
	hud_warmth_wrap.visible = false
	status_row.add_child(hud_warmth_wrap)

	hud_bag_btn = Button.new()
	hud_bag_btn.text = "Bag [I]"
	hud_bag_btn.custom_minimum_size = Vector2(88, 24)
	hud_bag_btn.add_theme_font_size_override("font_size", 12)
	hud_bag_btn.pressed.connect(func(): SoundManager.play_ui_click(); toggle_character_inventory())
	status_row.add_child(hud_bag_btn)

	hud_warmth_title_lbl = _make_lbl("Warmth", 12, Color(0.92, 0.78, 0.50))
	hud_warmth_wrap.add_child(hud_warmth_title_lbl)

	var warmth_track_wrap := Control.new()
	warmth_track_wrap.custom_minimum_size = Vector2(84, 14)
	warmth_track_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hud_warmth_wrap.add_child(warmth_track_wrap)
	_make_c_rect(Color(0.64, 0.50, 0.25), Vector2(0, 1), Vector2(84, 12), warmth_track_wrap)
	_make_c_rect(Color(0.08, 0.06, 0.08), Vector2(2, 3), Vector2(80, 8), warmth_track_wrap)
	hud_warmth_fill = _make_c_rect(Color(0.95, 0.68, 0.24), Vector2(2, 3), Vector2(80, 8), warmth_track_wrap)
	hud_warmth_pct_lbl = _make_lbl("100%", 12, Color(0.98, 0.88, 0.62))
	hud_warmth_wrap.add_child(hud_warmth_pct_lbl)

	var hud_rule := _make_c_rect(Color(0.62, 0.48, 0.24, 0.48), Vector2.ZERO, Vector2.ZERO, hud_box)
	hud_rule.custom_minimum_size = Vector2(0, 1)

	var knot_row := HBoxContainer.new()
	knot_row.add_theme_constant_override("separation", 8)
	hud_box.add_child(knot_row)
	hud_knot_icon = _make_hud_icon("icon_knot.png")
	hud_knot_icon.visible = true
	knot_row.add_child(hud_knot_icon)
	knot_hud_label = _make_lbl("", 13, Color(0.75, 0.88, 0.78))
	knot_row.add_child(knot_hud_label)

	hud_playtest_btn = Button.new()
	hud_playtest_btn.text = "Chapters / Debug [F1]"
	hud_playtest_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud_playtest_btn.offset_left = -188
	hud_playtest_btn.offset_top = 14
	hud_playtest_btn.offset_right = -16
	hud_playtest_btn.offset_bottom = 48
	hud_playtest_btn.visible = false
	hud_playtest_btn.pressed.connect(toggle_playtest_menu)
	add_child(hud_playtest_btn)


func _make_hud_icon(fname: String) -> TextureRect:
	var icon := _make_icon_rect(assets.get_tex(fname), Vector2(20, 20))
	icon.visible = false
	return icon


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


func _emit_start() -> void:
	SoundManager.play_ui_click()
	name_panel.visible = false
	emit_signal("start_game_requested", name_input.text)


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
	emit_signal("modal_state_changed")
	if pending_butcher_callback.is_valid():
		var cb := pending_butcher_callback
		pending_butcher_callback = Callable()
		cb.call()


func _on_knot_minigame_failed(knot_id: String) -> void:
	pending_knot_callback = Callable()
	var fail_cb := pending_knot_fail_callback
	pending_knot_fail_callback = Callable()
	emit_signal("modal_state_changed")
	if fail_cb.is_valid():
		fail_cb.call(knot_id)
