extends Control

signal close_requested

const SettingsConfigScript := preload("res://scripts/data/SettingsConfig.gd")

var _assets
var panel: PanelContainer
var tab_btns: Array[Button] = []
var tab_pages: Array[Control] = []
var active_tab: int = 0

var _tab_active_sb: StyleBox
var _tab_inactive_sb: StyleBox
var _on_sb: StyleBox
var _off_sb: StyleBox
var _capture_sb: StyleBox
var _key_sb: StyleBox
var _row_card_sb: StyleBox
var _val_pill_sb: StyleBox

var _syncing_ui: bool = false
var _capturing_action: String = ""

# Audio widgets
var mute_btn: Button
var mute_icon_rect: TextureRect
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
var hd2d_mode_btn: Button
var invert_cam_x_btn: Button
var invert_cam_y_btn: Button

# Controls widgets
var controls_status_lbl: Label
var keybind_buttons: Dictionary = {}


func setup_panel(assets_ref) -> void:
	_assets = assets_ref
	name = "SettingsPanel"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false

	_init_styleboxes()

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.06, 0.76)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 560)
	_assets.style_parchment_panel(panel)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	_build_header(root)
	_build_ornate_divider(root)
	_build_tab_bar(root)

	var ledger := PanelContainer.new()
	ledger.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var ledger_sb := StyleBoxFlat.new()
	ledger_sb.bg_color = Color(0.06, 0.05, 0.08, 0.56)
	ledger_sb.border_color = Color(0.60, 0.48, 0.28, 0.58)
	ledger_sb.set_border_width_all(1)
	ledger_sb.set_corner_radius_all(2)
	ledger_sb.set_content_margin_all(12)
	ledger.add_theme_stylebox_override("panel", ledger_sb)
	root.add_child(ledger)

	var page_wrap := VBoxContainer.new()
	page_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ledger.add_child(page_wrap)

	_build_audio_tab(page_wrap)
	_build_gameplay_tab(page_wrap)
	_build_controls_tab(page_wrap)
	_build_footer(root)

	_select_tab(0)
	sync_from_state()


func _init_styleboxes() -> void:
	_tab_active_sb = _style_or_flat("ui_tab_active_9slice.png", 6.0, 14.0, 7.0, Color(0.32, 0.25, 0.16), Color(0.85, 0.68, 0.32))
	_tab_inactive_sb = _style_or_flat("ui_tab_inactive_9slice.png", 6.0, 14.0, 6.0, Color(0.14, 0.12, 0.10), Color(0.40, 0.35, 0.28))
	_on_sb = _style_or_flat("ui_pill_on_9slice.png", 6.0, 12.0, 5.0, Color(0.18, 0.30, 0.20), Color(0.45, 0.72, 0.48))
	_off_sb = _style_or_flat("ui_pill_off_9slice.png", 6.0, 12.0, 5.0, Color(0.26, 0.17, 0.16), Color(0.62, 0.38, 0.35))
	_capture_sb = _style_or_flat("ui_keycap_capture_9slice.png", 6.0, 10.0, 4.0, Color(0.38, 0.29, 0.12), Color(0.95, 0.78, 0.30))
	_key_sb = _style_or_flat("ui_keycap_9slice.png", 6.0, 10.0, 4.0, Color(0.19, 0.16, 0.13), Color(0.56, 0.46, 0.32))
	_row_card_sb = _style_or_flat("ui_card_row_9slice.png", 6.0, 12.0, 7.0, Color(0.12, 0.10, 0.14, 0.88), Color(0.42, 0.34, 0.24, 0.75))
	_val_pill_sb = _style_or_flat("ui_keycap_9slice.png", 6.0, 6.0, 3.0, Color(0.10, 0.09, 0.12, 0.92), Color(0.52, 0.42, 0.28, 0.85))


func _style_or_flat(tex_name: String, m: float, ph: float, pv: float, fb_bg: Color, fb_bd: Color) -> StyleBox:
	if _assets != null and _assets.tex.has(tex_name):
		return _assets.make_ui_9slice_style(tex_name, m, ph, pv)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fb_bg
	sb.border_color = fb_bd
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = ph
	sb.content_margin_right = ph
	sb.content_margin_top = pv
	sb.content_margin_bottom = pv
	return sb


func _make_icon_rect(tex_name: String, px: float = 18.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.custom_minimum_size = Vector2(px, px)
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _assets != null:
		r.texture = _assets.get_tex(tex_name)
	return r


func _build_ornate_divider(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var left_line := ColorRect.new()
	left_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_line.custom_minimum_size = Vector2(0, 1)
	left_line.color = Color(0.68, 0.54, 0.30, 0.48)
	row.add_child(left_line)

	var orn := _make_icon_rect("ui_divider_ornate.png", 10.0)
	orn.custom_minimum_size = Vector2(128, 12)
	row.add_child(orn)

	var right_line := ColorRect.new()
	right_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_line.custom_minimum_size = Vector2(0, 1)
	right_line.color = Color(0.68, 0.54, 0.30, 0.48)
	row.add_child(right_line)


func _build_header(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	parent.add_child(hbox)

	var crest := _make_icon_rect("ui_brotherhood_emblem.png", 38.0)
	hbox.add_child(crest)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	hbox.add_child(title_col)

	var title_lbl := Label.new()
	title_lbl.text = "CHRONICLE SETTINGS"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.97, 0.83, 0.42))
	title_col.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Audio balance, field hints, dialogue pacing & key bindings"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.65))
	title_col.add_child(sub_lbl)

	var close_x := Button.new()
	close_x.text = "Close [Esc]"
	close_x.custom_minimum_size = Vector2(118, 34)
	close_x.pressed.connect(_on_close_pressed)
	hbox.add_child(close_x)


func _build_tab_bar(parent: VBoxContainer) -> void:
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	parent.add_child(tab_row)

	var specs := [
		["Audio & Volume", "ui_icon_audio.png"],
		["Gameplay & Display", "ui_icon_gameplay.png"],
		["Controls & Keys", "ui_icon_controls.png"],
	]
	for idx in range(specs.size()):
		var btn := Button.new()
		btn.text = specs[idx][0]
		btn.icon = _assets.get_tex(specs[idx][1]) if _assets != null else null
		btn.add_theme_constant_override("h_separation", 8)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 36)
		var captured_idx := idx
		btn.pressed.connect(func():
			SoundManager.play_ui_click()
			_cancel_capture()
			_select_tab(captured_idx)
		)
		tab_row.add_child(btn)
		tab_btns.append(btn)


func _wrap_card_row(parent: VBoxContainer) -> HBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _row_card_sb)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	return row


func _add_row_label_column(row: HBoxContainer, label_txt: String, desc_txt: String) -> void:
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 1)
	row.add_child(left)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.91, 0.80))
	left.add_child(lbl)

	var sub := Label.new()
	sub.text = desc_txt
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.73, 0.70, 0.62))
	left.add_child(sub)


func _add_toggle_row(parent: VBoxContainer, label_txt: String, desc_txt: String, icon_name: String, on_pressed: Callable) -> Dictionary:
	var row := _wrap_card_row(parent)
	var icon_rect := _make_icon_rect(icon_name, 20.0)
	row.add_child(icon_rect)
	_add_row_label_column(row, label_txt, desc_txt)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(142, 32)
	btn.pressed.connect(func():
		SoundManager.play_ui_click()
		on_pressed.call()
	)
	row.add_child(btn)
	return {"btn": btn, "icon": icon_rect}


func _add_slider_row(parent: VBoxContainer, label_txt: String, desc_txt: String, icon_name: String, on_changed: Callable) -> Dictionary:
	var row := _wrap_card_row(parent)
	row.add_child(_make_icon_rect(icon_name, 20.0))
	_add_row_label_column(row, label_txt, desc_txt)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(205, 26)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _assets != null:
		_assets.style_hslider(slider)
	slider.value_changed.connect(on_changed)
	row.add_child(slider)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(54, 28)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", _val_pill_sb)
	row.add_child(badge)

	var val_lbl := Label.new()
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48))
	badge.add_child(val_lbl)

	return {"slider": slider, "value": val_lbl}


func _build_audio_tab(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	tab_pages.append(box)

	var mute_pair := _add_toggle_row(
		box,
		"Master Audio Output",
		"Silences Master output while preserving individual slider balances.",
		"ui_icon_unmute.png",
		func():
			GameState.audio_muted = not GameState.audio_muted
			GameState.apply_and_save_settings()
	)
	mute_btn = mute_pair["btn"]
	mute_icon_rect = mute_pair["icon"]

	var m_row := _add_slider_row(box, "Master Volume", "Overall loudness across music, effects, and dialogue.", "ui_icon_audio.png", func(val: float):
		if _syncing_ui:
			return
		GameState.master_volume = val
		GameState.apply_and_save_settings()
	)
	master_slider = m_row["slider"]
	master_val_lbl = m_row["value"]

	var a_row := _add_slider_row(box, "Music & Ambience", "Harbor swells, hearth crackles, wilderness wind, and flight wind.", "ui_icon_unmute.png", func(val: float):
		if _syncing_ui:
			return
		GameState.ambience_volume = val
		GameState.apply_and_save_settings()
	)
	ambience_slider = a_row["slider"]
	ambience_val_lbl = a_row["value"]

	var s_row := _add_slider_row(box, "Sound Effects (SFX)", "Footsteps, rope casts, chimes, knife slashes, and UI clicks.", "prop_resonance_chime.png", func(val: float):
		if _syncing_ui:
			return
		GameState.sfx_volume = val
		GameState.apply_and_save_settings()
	)
	sfx_slider = s_row["slider"]
	sfx_val_lbl = s_row["value"]

	var v_row := _add_slider_row(box, "Dialogue Voices", "Expressive speech cadences for your hero, Clara, sailors, and dragons.", "ui_icon_quill.png", func(val: float):
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
	test_sfx_btn.icon = _assets.get_tex("ui_icon_audio.png") if _assets != null else null
	test_sfx_btn.add_theme_constant_override("h_separation", 6)
	test_sfx_btn.custom_minimum_size = Vector2(160, 32)
	test_sfx_btn.pressed.connect(func(): SoundManager.play_chime())
	btn_row.add_child(test_sfx_btn)

	var test_voice_btn := Button.new()
	test_voice_btn.text = "Test Voice Blip"
	test_voice_btn.icon = _assets.get_tex("ui_icon_quill.png") if _assets != null else null
	test_voice_btn.add_theme_constant_override("h_separation", 6)
	test_voice_btn.custom_minimum_size = Vector2(160, 32)
	test_voice_btn.pressed.connect(func(): SoundManager.play_voice_blip("boy", 1.0))
	btn_row.add_child(test_voice_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var reset_audio_btn := Button.new()
	reset_audio_btn.text = "Reset Audio"
	reset_audio_btn.custom_minimum_size = Vector2(138, 32)
	reset_audio_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		GameState.reset_audio_settings()
	)
	btn_row.add_child(reset_audio_btn)


func _build_gameplay_tab(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	box.visible = false
	parent.add_child(box)
	tab_pages.append(box)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if _assets != null:
		_assets.style_vscrollbar(scroll)
	box.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(list_vbox)

	hints_btn = _add_toggle_row(
		list_vbox,
		"Gameplay Hints",
		"Shows pulsing gate chevrons, HUD bag/map nudges, wharf clues, and minigame tips.",
		"ui_icon_gameplay.png",
		func():
			GameState.hints_enabled = not GameState.hints_enabled
			GameState.apply_and_save_settings()
	)["btn"]

	prompts_btn = _add_toggle_row(
		list_vbox,
		"HUD Control Prompts",
		"Shows keybind reminders along the bottom HUD bar, dialogue box, and cutscenes.",
		"ui_icon_controls.png",
		func():
			GameState.control_prompts_enabled = not GameState.control_prompts_enabled
			GameState.apply_and_save_settings()
	)["btn"]

	speed_btn = _add_toggle_row(
		list_vbox,
		"Dialogue Text Speed",
		"Controls how fast spoken and telepathic lines appear in the dialogue box.",
		"ui_icon_quill.png",
		func():
			var order: Array[String] = SettingsConfigScript.DIALOGUE_SPEED_ORDER
			var idx := order.find(GameState.dialogue_speed_mode)
			GameState.dialogue_speed_mode = order[(idx + 1) % order.size()]
			GameState.apply_and_save_settings()
	)["btn"]

	shake_btn = _add_toggle_row(
		list_vbox,
		"Screen Shake",
		"Camera tremor during cannon impacts, dragon roars, and storm gusts.",
		"ui_icon_display.png",
		func():
			GameState.screen_shake_enabled = not GameState.screen_shake_enabled
			GameState.apply_and_save_settings()
	)["btn"]

	display_btn = _add_toggle_row(
		list_vbox,
		"Window Mode",
		"Switch between Windowed, Maximized, and Borderless Fullscreen.",
		"ui_icon_display.png",
		func():
			var order: Array[String] = SettingsConfigScript.DISPLAY_MODE_ORDER
			var idx := order.find(GameState.display_mode)
			GameState.display_mode = order[(idx + 1) % order.size()]
			GameState.apply_and_save_settings()
	)["btn"]

	hd2d_mode_btn = _add_toggle_row(
		list_vbox,
		"HD-2D Diorama Mode",
		"Toggles Octopath-style 3D tilted diorama camera and lighting in supported regions ([H]).",
		"ui_icon_display.png",
		func():
			GameState.hd2d_mode_enabled = not GameState.hd2d_mode_enabled
			GameState.apply_and_save_settings()
	)["btn"]

	invert_cam_x_btn = _add_toggle_row(
		list_vbox,
		"Invert Camera X (Arrows)",
		"Reverses horizontal orbit direction for Left/Right Arrow keys in HD-2D mode.",
		"ui_icon_controls.png",
		func():
			GameState.invert_cam_x_arrows = not GameState.invert_cam_x_arrows
			GameState.apply_and_save_settings()
	)["btn"]

	invert_cam_y_btn = _add_toggle_row(
		list_vbox,
		"Invert Camera Y (Arrows)",
		"Reverses pitch tilt direction for Up/Down Arrow keys in HD-2D mode.",
		"ui_icon_controls.png",
		func():
			GameState.invert_cam_y_arrows = not GameState.invert_cam_y_arrows
			GameState.apply_and_save_settings()
	)["btn"]

	playtest_hud_btn = _add_toggle_row(
		list_vbox,
		"Show HUD [F1] Jump Button",
		"Shows or hides the top-right Chapters/Playtest corner badge (hotkey [F1] always works).",
		"icon_brotherhood_emblem.png",
		func():
			GameState.show_playtest_hud_btn = not GameState.show_playtest_hud_btn
			GameState.apply_and_save_settings()
	)["btn"]

	var reset_row := HBoxContainer.new()
	box.add_child(reset_row)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_row.add_child(sp)
	var reset_gp_btn := Button.new()
	reset_gp_btn.text = "Reset Gameplay & Display"
	reset_gp_btn.custom_minimum_size = Vector2(205, 32)
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

	var status_card := PanelContainer.new()
	status_card.add_theme_stylebox_override("panel", _row_card_sb)
	box.add_child(status_card)

	var st_row := HBoxContainer.new()
	st_row.add_theme_constant_override("separation", 8)
	status_card.add_child(st_row)
	st_row.add_child(_make_icon_rect("ui_icon_controls.png", 16.0))

	controls_status_lbl = Label.new()
	controls_status_lbl.text = "Select any key badge to rebind. Esc cancels; Arrow & mouse controls remain active."
	controls_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_status_lbl.add_theme_font_size_override("font_size", 12)
	controls_status_lbl.add_theme_color_override("font_color", Color(0.92, 0.87, 0.74))
	st_row.add_child(controls_status_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if _assets != null:
		_assets.style_vscrollbar(scroll)
	box.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(list_vbox)

	var last_cat := ""
	for row_data in SettingsConfigScript.REBINDABLE_ACTIONS:
		var cat: String = row_data["category"]
		if cat != last_cat:
			last_cat = cat
			var cat_row := HBoxContainer.new()
			cat_row.add_theme_constant_override("separation", 8)
			list_vbox.add_child(cat_row)

			cat_row.add_child(_make_icon_rect("icon_brotherhood_emblem.png", 14.0))
			var cat_lbl := Label.new()
			cat_lbl.text = cat.to_upper()
			cat_lbl.add_theme_font_size_override("font_size", 12)
			cat_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.38))
			cat_row.add_child(cat_lbl)

			var cat_line := ColorRect.new()
			cat_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cat_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cat_line.custom_minimum_size = Vector2(0, 1)
			cat_line.color = Color(0.70, 0.56, 0.30, 0.42)
			cat_row.add_child(cat_line)

		var row := _wrap_card_row(list_vbox)

		var act_lbl := Label.new()
		act_lbl.text = row_data["label"]
		act_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act_lbl.add_theme_font_size_override("font_size", 13)
		act_lbl.add_theme_color_override("font_color", Color(0.95, 0.91, 0.83))
		row.add_child(act_lbl)

		var extra_txt: String = row_data.get("extra", "")
		if extra_txt != "":
			var ext_lbl := Label.new()
			ext_lbl.text = extra_txt
			ext_lbl.add_theme_font_size_override("font_size", 11)
			ext_lbl.add_theme_color_override("font_color", Color(0.70, 0.67, 0.59))
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
	reserved_lbl.text = "System Keys: [Esc] Pause / Close   |   [F1] Chapters & Playtest"
	reserved_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reserved_lbl.add_theme_font_size_override("font_size", 12)
	reserved_lbl.add_theme_color_override("font_color", Color(0.74, 0.70, 0.62))
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
	_build_ornate_divider(parent)

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
	saved_lbl.text = "Saved automatically to user chronicle."
	saved_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saved_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	saved_lbl.add_theme_font_size_override("font_size", 12)
	saved_lbl.add_theme_color_override("font_color", Color(0.76, 0.73, 0.65))
	frow.add_child(saved_lbl)

	var done_btn := Button.new()
	done_btn.text = "Done [Esc]"
	done_btn.custom_minimum_size = Vector2(130, 34)
	done_btn.pressed.connect(_on_close_pressed)
	frow.add_child(done_btn)


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


func sync_from_state() -> void:
	_syncing_ui = true
	if master_slider != null:
		master_slider.value = GameState.master_volume
		master_val_lbl.text = "%d%%" % roundi(GameState.master_volume * 100.0)
	if ambience_slider != null:
		ambience_slider.value = GameState.ambience_volume
		ambience_val_lbl.text = "%d%%" % roundi(GameState.ambience_volume * 100.0)
	if sfx_slider != null:
		sfx_slider.value = GameState.sfx_volume
		sfx_val_lbl.text = "%d%%" % roundi(GameState.sfx_volume * 100.0)
	if voices_slider != null:
		voices_slider.value = GameState.voices_volume
		voices_val_lbl.text = "%d%%" % roundi(GameState.voices_volume * 100.0)
	if mute_btn != null:
		mute_btn.text = "MUTED" if GameState.audio_muted else "ACTIVE"
	if mute_icon_rect != null and _assets != null:
		mute_icon_rect.texture = _assets.get_tex("ui_icon_mute.png" if GameState.audio_muted else "ui_icon_unmute.png")
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
	if hd2d_mode_btn != null:
		hd2d_mode_btn.text = "ON" if GameState.hd2d_mode_enabled else "OFF"
	if invert_cam_x_btn != null:
		invert_cam_x_btn.text = "ON" if GameState.invert_cam_x_arrows else "OFF"
	if invert_cam_y_btn != null:
		invert_cam_y_btn.text = "ON" if GameState.invert_cam_y_arrows else "OFF"
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
		controls_status_lbl.text = "Press any key for '%s'... (Esc cancels; Esc / F1 / ` are reserved)" % friendly_label
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


func _style_btn(btn: Button, norm_sb: StyleBox, hov_sb: StyleBox, col: Color, hov_col: Color, press_sb: StyleBox = null) -> void:
	if btn == null:
		return
	btn.add_theme_stylebox_override("normal", norm_sb)
	btn.add_theme_stylebox_override("hover", hov_sb)
	btn.add_theme_stylebox_override("focus", hov_sb)
	if press_sb != null:
		btn.add_theme_stylebox_override("pressed", press_sb)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", hov_col)
	btn.add_theme_color_override("font_focus_color", col)


func apply_post_theme_fixes() -> void:
	_refresh_tab_styles()
	_apply_toggle_style(mute_btn, not GameState.audio_muted)
	_apply_toggle_style(hints_btn, GameState.hints_enabled)
	_apply_toggle_style(prompts_btn, GameState.control_prompts_enabled)
	_apply_toggle_style(shake_btn, GameState.screen_shake_enabled)
	_apply_toggle_style(hd2d_mode_btn, GameState.hd2d_mode_enabled)
	_apply_toggle_style(invert_cam_x_btn, GameState.invert_cam_x_arrows)
	_apply_toggle_style(invert_cam_y_btn, GameState.invert_cam_y_arrows)
	_apply_toggle_style(playtest_hud_btn, GameState.show_playtest_hud_btn)
	_apply_cycle_style(speed_btn)
	_apply_cycle_style(display_btn)
	if _assets != null:
		for s in [master_slider, ambience_slider, sfx_slider, voices_slider]:
			if s != null:
				_assets.style_hslider(s)
	for act_name in keybind_buttons.keys():
		var btn: Button = keybind_buttons[act_name]
		if _capturing_action == act_name:
			_style_btn(btn, _capture_sb, _capture_sb, Color(1.0, 0.94, 0.58), Color(1.0, 0.94, 0.58))
		else:
			_style_btn(btn, _key_sb, _tab_active_sb, Color(0.96, 0.88, 0.66), Color(1.0, 0.94, 0.62))


func _refresh_tab_styles() -> void:
	for i in range(tab_btns.size()):
		var active := (i == active_tab)
		var sb := _tab_active_sb if active else _tab_inactive_sb
		var col := Color(1.0, 0.90, 0.54) if active else Color(0.80, 0.77, 0.69)
		var hov_col := Color(1.0, 0.93, 0.62) if active else Color(0.92, 0.87, 0.74)
		_style_btn(tab_btns[i], sb, _tab_active_sb if active else sb, col, hov_col, sb)


func _apply_toggle_style(btn: Button, positive: bool) -> void:
	var sb := _on_sb if positive else _off_sb
	var col := Color(0.90, 0.99, 0.86) if positive else Color(0.98, 0.82, 0.78)
	_style_btn(btn, sb, sb, col, col)


func _apply_cycle_style(btn: Button) -> void:
	_style_btn(btn, _key_sb, _tab_active_sb, Color(0.98, 0.88, 0.62), Color(1.0, 0.94, 0.68))


func _on_close_pressed() -> void:
	SoundManager.play_ui_click()
	_cancel_capture()
	emit_signal("close_requested")
