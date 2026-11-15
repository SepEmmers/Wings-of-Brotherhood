extends Control

signal close_requested

const SettingsConfigScript := preload("res://scripts/data/SettingsConfig.gd")

var _assets
var panel: PanelContainer
var tab_btns: Array[Button] = []
var tab_pages: Array[Control] = []
var active_tab: int = 0

var _tab_active_sb: StyleBoxFlat
var _tab_inactive_sb: StyleBoxFlat
var _on_sb: StyleBoxFlat
var _off_sb: StyleBoxFlat
var _capture_sb: StyleBoxFlat
var _key_sb: StyleBoxFlat

var _syncing_ui: bool = false
var _capturing_action: String = ""

# Audio widgets
var mute_btn: Button
var master_slider: HSlider
var master_val_lbl: Label
var ambience_slider: HSlider
var ambience_val_lbl: Label
var sfx_slider: HSlider
var sfx_val_lbl: Label
var voices_slider: HSlider
var voices_val_lbl: Label

# Gameplay & Display widgets
var hints_btn: Button
var prompts_btn: Button
var speed_btn: Button
var shake_btn: Button
var display_btn: Button
var playtest_hud_btn: Button

# Controls widgets
var controls_status_lbl: Label
var keybind_buttons: Dictionary = {}


func setup_panel(assets_ref) -> void:
	_assets = assets_ref
	name = "SettingsPanel"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_tab_active_sb = _make_flat_sb(Color(0.32, 0.25, 0.16), Color(0.85, 0.68, 0.32), 2, 4)
	_tab_inactive_sb = _make_flat_sb(Color(0.14, 0.12, 0.10), Color(0.40, 0.35, 0.28), 1, 4)
	_on_sb = _make_flat_sb(Color(0.18, 0.30, 0.20), Color(0.45, 0.72, 0.48), 1, 4)
	_off_sb = _make_flat_sb(Color(0.26, 0.17, 0.16), Color(0.62, 0.38, 0.35), 1, 4)
	_capture_sb = _make_flat_sb(Color(0.38, 0.29, 0.12), Color(0.95, 0.78, 0.30), 2, 4)
	_key_sb = _make_flat_sb(Color(0.19, 0.16, 0.13), Color(0.56, 0.46, 0.32), 1, 4)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.06, 0.72)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 520)
	_assets.style_parchment_panel(panel)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	_build_header(root)
	_build_tab_bar(root)

	var page_wrap := VBoxContainer.new()
	page_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(page_wrap)

	_build_audio_tab(page_wrap)
	_build_gameplay_tab(page_wrap)
	_build_controls_tab(page_wrap)
	_build_footer(root)

	_select_tab(0)
	sync_from_state()


func _build_header(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	hbox.add_child(title_col)

	var title_lbl := Label.new()
	title_lbl.text = "SETTINGS & PREFERENCES"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.38))
	title_col.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Audio mix, field hints, text pacing, and key bindings (saved to user://settings.cfg)"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.76, 0.73, 0.65))
	title_col.add_child(sub_lbl)

	var close_x := Button.new()
	close_x.text = "Close [Esc]"
	close_x.custom_minimum_size = Vector2(115, 32)
	close_x.pressed.connect(_on_close_pressed)
	hbox.add_child(close_x)


func _build_tab_bar(parent: VBoxContainer) -> void:
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	parent.add_child(tab_row)

	var names := ["1. Audio & Volume", "2. Gameplay & Display", "3. Controls & Keys"]
	for idx in range(names.size()):
		var btn := Button.new()
		btn.text = names[idx]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 34)
		var captured_idx := idx
		btn.pressed.connect(func():
			SoundManager.play_ui_click()
			_cancel_capture()
			_select_tab(captured_idx)
		)
		tab_row.add_child(btn)
		tab_btns.append(btn)


func _build_audio_tab(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	tab_pages.append(box)

	mute_btn = _add_toggle_row(
		box,
		"Mute All Audio",
		"Silences Master output while preserving your individual slider balances.",
		func():
			GameState.audio_muted = not GameState.audio_muted
			GameState.apply_and_save_settings()
	)

	var m_row := _add_slider_row(box, "Master Volume", "Overall loudness across music, effects, and dialogue.", func(val: float):
		if _syncing_ui:
			return
		GameState.master_volume = val
		GameState.apply_and_save_settings()
	)
	master_slider = m_row["slider"]
	master_val_lbl = m_row["value"]

	var a_row := _add_slider_row(box, "Music & Ambience", "Harbor swells, hearth crackles, wilderness wind, and flight wind.", func(val: float):
		if _syncing_ui:
			return
		GameState.ambience_volume = val
		GameState.apply_and_save_settings()
	)
	ambience_slider = a_row["slider"]
	ambience_val_lbl = a_row["value"]

	var s_row := _add_slider_row(box, "Sound Effects (SFX)", "Footsteps, rope casts, chimes, knife slashes, and UI clicks.", func(val: float):
		if _syncing_ui:
			return
		GameState.sfx_volume = val
		GameState.apply_and_save_settings()
	)
	sfx_slider = s_row["slider"]
	sfx_val_lbl = s_row["value"]

	var v_row := _add_slider_row(box, "Dialogue Voices", "Expressive speech cadences for Bram, Clara, sailors, and dragons.", func(val: float):
		if _syncing_ui:
			return
		GameState.voices_volume = val
		GameState.apply_and_save_settings()
	)
	voices_slider = v_row["slider"]
	voices_val_lbl = v_row["value"]

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	box.add_child(btn_row)

	var test_sfx_btn := Button.new()
	test_sfx_btn.text = "Test Chime SFX"
	test_sfx_btn.custom_minimum_size = Vector2(160, 32)
	test_sfx_btn.pressed.connect(func(): SoundManager.play_chime())
	btn_row.add_child(test_sfx_btn)

	var test_voice_btn := Button.new()
	test_voice_btn.text = "Test Voice Blip"
	test_voice_btn.custom_minimum_size = Vector2(160, 32)
	test_voice_btn.pressed.connect(func(): SoundManager.play_voice_blip("boy", 1.0))
	btn_row.add_child(test_voice_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var reset_audio_btn := Button.new()
	reset_audio_btn.text = "Reset Audio"
	reset_audio_btn.custom_minimum_size = Vector2(140, 32)
	reset_audio_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		GameState.reset_audio_settings()
	)
	btn_row.add_child(reset_audio_btn)


func _build_gameplay_tab(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	box.visible = false
	parent.add_child(box)
	tab_pages.append(box)

	hints_btn = _add_toggle_row(
		box,
		"Gameplay Hints",
		"Shows pulsing gate chevrons, HUD bag/map nudges, wharf clues, and minigame tips.",
		func():
			GameState.hints_enabled = not GameState.hints_enabled
			GameState.apply_and_save_settings()
	)

	prompts_btn = _add_toggle_row(
		box,
		"HUD Control Prompts",
		"Shows keybind reminders along the bottom HUD bar, dialogue box, and cutscenes.",
		func():
			GameState.control_prompts_enabled = not GameState.control_prompts_enabled
			GameState.apply_and_save_settings()
	)

	speed_btn = _add_toggle_row(
		box,
		"Dialogue Text Speed",
		"Controls how fast spoken and telepathic lines appear in the dialogue box.",
		func():
			var order: Array[String] = SettingsConfigScript.DIALOGUE_SPEED_ORDER
			var idx := order.find(GameState.dialogue_speed_mode)
			GameState.dialogue_speed_mode = order[(idx + 1) % order.size()]
			GameState.apply_and_save_settings()
	)

	shake_btn = _add_toggle_row(
		box,
		"Screen Shake",
		"Camera tremor during cannon impacts, dragon roars, and storm gusts.",
		func():
			GameState.screen_shake_enabled = not GameState.screen_shake_enabled
			GameState.apply_and_save_settings()
	)

	display_btn = _add_toggle_row(
		box,
		"Window Mode",
		"Switch between Windowed, Maximized, and Borderless Fullscreen.",
		func():
			var order: Array[String] = SettingsConfigScript.DISPLAY_MODE_ORDER
			var idx := order.find(GameState.display_mode)
			GameState.display_mode = order[(idx + 1) % order.size()]
			GameState.apply_and_save_settings()
	)

	playtest_hud_btn = _add_toggle_row(
		box,
		"Show HUD [F1] Jump Button",
		"Shows or hides the top-right Chapters/Playtest corner badge (hotkey [F1] always works).",
		func():
			GameState.show_playtest_hud_btn = not GameState.show_playtest_hud_btn
			GameState.apply_and_save_settings()
	)

	var reset_row := HBoxContainer.new()
	box.add_child(reset_row)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_row.add_child(sp)
	var reset_gp_btn := Button.new()
	reset_gp_btn.text = "Reset Gameplay & Display"
	reset_gp_btn.custom_minimum_size = Vector2(200, 32)
	reset_gp_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		GameState.reset_gameplay_settings()
	)
	reset_row.add_child(reset_gp_btn)


func _build_controls_tab(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	box.visible = false
	parent.add_child(box)
	tab_pages.append(box)

	controls_status_lbl = Label.new()
	controls_status_lbl.text = "Click a key button to rebind. Press Esc while binding to cancel. Arrow & mouse alternatives remain active."
	controls_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_status_lbl.add_theme_font_size_override("font_size", 12)
	controls_status_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.72))
	box.add_child(controls_status_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(list_vbox)

	var last_cat := ""
	for row_data in SettingsConfigScript.REBINDABLE_ACTIONS:
		var cat: String = row_data["category"]
		if cat != last_cat:
			last_cat = cat
			var cat_lbl := Label.new()
			cat_lbl.text = cat.to_upper()
			cat_lbl.add_theme_font_size_override("font_size", 12)
			cat_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.36))
			list_vbox.add_child(cat_lbl)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list_vbox.add_child(row)

		var act_lbl := Label.new()
		act_lbl.text = row_data["label"]
		act_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act_lbl.add_theme_font_size_override("font_size", 13)
		act_lbl.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84))
		row.add_child(act_lbl)

		var extra_txt: String = row_data.get("extra", "")
		if extra_txt != "":
			var ext_lbl := Label.new()
			ext_lbl.text = extra_txt
			ext_lbl.add_theme_font_size_override("font_size", 11)
			ext_lbl.add_theme_color_override("font_color", Color(0.68, 0.66, 0.60))
			row.add_child(ext_lbl)

		var act_name: String = row_data["action"]
		var bind_btn := Button.new()
		bind_btn.custom_minimum_size = Vector2(126, 28)
		bind_btn.pressed.connect(func():
			SoundManager.play_ui_click()
			_begin_capture(act_name, row_data["label"])
		)
		row.add_child(bind_btn)
		keybind_buttons[act_name] = bind_btn

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	box.add_child(foot)

	var reserved_lbl := Label.new()
	reserved_lbl.text = "System Keys: [Esc] Pause / Close Menu   |   [F1] Chapters & Playtest"
	reserved_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reserved_lbl.add_theme_font_size_override("font_size", 12)
	reserved_lbl.add_theme_color_override("font_color", Color(0.70, 0.68, 0.62))
	foot.add_child(reserved_lbl)

	var reset_keys_btn := Button.new()
	reset_keys_btn.text = "Reset Default Keys"
	reset_keys_btn.custom_minimum_size = Vector2(165, 30)
	reset_keys_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		_cancel_capture()
		GameState.reset_controls()
		if controls_status_lbl != null:
			controls_status_lbl.text = "All key bindings restored to Medieval Flanders defaults."
			controls_status_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 0.72))
	)
	foot.add_child(reset_keys_btn)


func _build_footer(parent: VBoxContainer) -> void:
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.55, 0.45, 0.28, 0.40)
	parent.add_child(div)

	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 12)
	parent.add_child(frow)

	var reset_all_btn := Button.new()
	reset_all_btn.text = "Reset All Settings"
	reset_all_btn.custom_minimum_size = Vector2(165, 34)
	reset_all_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		_cancel_capture()
		GameState.reset_all_settings()
	)
	frow.add_child(reset_all_btn)

	var saved_lbl := Label.new()
	saved_lbl.text = "Changes apply immediately and save automatically."
	saved_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saved_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	saved_lbl.add_theme_font_size_override("font_size", 12)
	saved_lbl.add_theme_color_override("font_color", Color(0.74, 0.72, 0.65))
	frow.add_child(saved_lbl)

	var done_btn := Button.new()
	done_btn.text = "Done [Esc]"
	done_btn.custom_minimum_size = Vector2(130, 34)
	done_btn.pressed.connect(_on_close_pressed)
	frow.add_child(done_btn)


func _add_toggle_row(parent: VBoxContainer, label_txt: String, desc_txt: String, on_pressed: Callable) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 1)
	row.add_child(left)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.91, 0.80))
	left.add_child(lbl)

	var sub := Label.new()
	sub.text = desc_txt
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.72, 0.69, 0.62))
	left.add_child(sub)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(135, 32)
	btn.pressed.connect(func():
		SoundManager.play_ui_click()
		on_pressed.call()
	)
	row.add_child(btn)
	return btn


func _add_slider_row(parent: VBoxContainer, label_txt: String, desc_txt: String, on_changed: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 1)
	row.add_child(left)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.91, 0.80))
	left.add_child(lbl)

	var sub := Label.new()
	sub.text = desc_txt
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.72, 0.69, 0.62))
	left.add_child(sub)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(210, 26)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_changed)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(48, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	row.add_child(val_lbl)

	return {"slider": slider, "value": val_lbl}


func _select_tab(tab_idx: int) -> void:
	active_tab = clampi(tab_idx, 0, tab_pages.size() - 1)
	for i in range(tab_pages.size()):
		tab_pages[i].visible = (i == active_tab)
	_refresh_tab_styles()


func open_settings(initial_tab: int = -1) -> void:
	_cancel_capture()
	if initial_tab >= 0:
		_select_tab(initial_tab)
	sync_from_state()
	visible = true
	if tab_btns.size() > active_tab and is_inside_tree():
		tab_btns[active_tab].call_deferred("grab_focus")


func close_settings() -> void:
	_cancel_capture()
	visible = false


func is_rebind_active() -> bool:
	return visible and _capturing_action != ""


func sync_from_state() -> void:
	_syncing_ui = true
	if master_slider != null:
		master_slider.value = GameState.master_volume
		master_val_lbl.text = "%d%%" % int(round(GameState.master_volume * 100.0))
	if ambience_slider != null:
		ambience_slider.value = GameState.ambience_volume
		ambience_val_lbl.text = "%d%%" % int(round(GameState.ambience_volume * 100.0))
	if sfx_slider != null:
		sfx_slider.value = GameState.sfx_volume
		sfx_val_lbl.text = "%d%%" % int(round(GameState.sfx_volume * 100.0))
	if voices_slider != null:
		voices_slider.value = GameState.voices_volume
		voices_val_lbl.text = "%d%%" % int(round(GameState.voices_volume * 100.0))

	if mute_btn != null:
		mute_btn.text = "MUTED" if GameState.audio_muted else "Active"
	if hints_btn != null:
		hints_btn.text = "ON" if GameState.hints_enabled else "OFF"
	if prompts_btn != null:
		prompts_btn.text = "ON" if GameState.control_prompts_enabled else "OFF"
	if speed_btn != null:
		speed_btn.text = SettingsConfigScript.DIALOGUE_SPEED_LABELS.get(GameState.dialogue_speed_mode, "Normal")
	if shake_btn != null:
		shake_btn.text = "ON" if GameState.screen_shake_enabled else "OFF"
	if display_btn != null:
		display_btn.text = SettingsConfigScript.DISPLAY_MODE_LABELS.get(GameState.display_mode, "Windowed")
	if playtest_hud_btn != null:
		playtest_hud_btn.text = "Shown" if GameState.show_playtest_hud_btn else "Hidden"

	_refresh_keybind_labels()
	_syncing_ui = false
	apply_post_theme_fixes()


func _refresh_keybind_labels() -> void:
	for act_name in keybind_buttons.keys():
		var btn: Button = keybind_buttons[act_name]
		if _capturing_action == act_name:
			btn.text = "Press key..."
		else:
			btn.text = "[%s]" % GameState.get_action_key_label(act_name)


func _begin_capture(action_name: String, friendly_label: String) -> void:
	_capturing_action = action_name
	_refresh_keybind_labels()
	if controls_status_lbl != null:
		controls_status_lbl.text = "Press any key for '%s'... (Esc to cancel; Esc/F1/` are reserved)" % friendly_label
		controls_status_lbl.add_theme_color_override("font_color", Color(0.98, 0.84, 0.42))
	apply_post_theme_fixes()


func _cancel_capture() -> void:
	if _capturing_action == "":
		return
	_capturing_action = ""
	_refresh_keybind_labels()
	apply_post_theme_fixes()


func _input(event: InputEvent) -> void:
	if not visible or _capturing_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc := int(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
		get_viewport().set_input_as_handled()
		if kc == KEY_ESCAPE:
			_cancel_capture()
			if controls_status_lbl != null:
				controls_status_lbl.text = "Key rebinding cancelled."
				controls_status_lbl.add_theme_color_override("font_color", Color(0.84, 0.80, 0.68))
			return
		var res := GameState.rebind_action(_capturing_action, kc)
		if bool(res.get("ok", false)):
			var swapped: String = res.get("swapped_label", "")
			var bound_act := _capturing_action
			_capturing_action = ""
			SoundManager.play_ui_click()
			sync_from_state()
			if controls_status_lbl != null:
				if swapped != "":
					controls_status_lbl.text = "Bound [%s] and swapped previous owner '%s'." % [GameState.get_action_key_label(bound_act), swapped]
				else:
					controls_status_lbl.text = "Saved binding: [%s]." % GameState.get_action_key_label(bound_act)
				controls_status_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 0.72))
		else:
			SoundManager.play_knot_snag()
			if controls_status_lbl != null:
				controls_status_lbl.text = str(res.get("error", "Cannot bind that key."))
				controls_status_lbl.add_theme_color_override("font_color", Color(0.96, 0.56, 0.52))


func apply_post_theme_fixes() -> void:
	_refresh_tab_styles()
	_apply_toggle_style(mute_btn, not GameState.audio_muted)
	_apply_toggle_style(hints_btn, GameState.hints_enabled)
	_apply_toggle_style(prompts_btn, GameState.control_prompts_enabled)
	_apply_toggle_style(shake_btn, GameState.screen_shake_enabled)
	_apply_toggle_style(playtest_hud_btn, GameState.show_playtest_hud_btn)
	for act_name in keybind_buttons.keys():
		var btn: Button = keybind_buttons[act_name]
		if _capturing_action == act_name:
			btn.add_theme_stylebox_override("normal", _capture_sb)
			btn.add_theme_stylebox_override("hover", _capture_sb)
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
		else:
			btn.add_theme_stylebox_override("normal", _key_sb)
			btn.add_theme_stylebox_override("hover", _tab_active_sb)
			btn.add_theme_color_override("font_color", Color(0.94, 0.86, 0.64))


func _refresh_tab_styles() -> void:
	for i in range(tab_btns.size()):
		var btn := tab_btns[i]
		var sb := _tab_active_sb if i == active_tab else _tab_inactive_sb
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", _tab_active_sb if i == active_tab else sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50) if i == active_tab else Color(0.80, 0.78, 0.72))


func _apply_toggle_style(btn: Button, positive: bool) -> void:
	if btn == null:
		return
	var sb := _on_sb if positive else _off_sb
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_color_override("font_color", Color(0.86, 0.98, 0.84) if positive else Color(0.96, 0.78, 0.76))


func _on_close_pressed() -> void:
	SoundManager.play_ui_click()
	_cancel_capture()
	emit_signal("close_requested")


func _make_flat_sb(bg_col: Color, border_col: Color, bw: int = 1, rad: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(rad)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb
