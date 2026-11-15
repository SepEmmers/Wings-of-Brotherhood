extends Control

signal resume_requested
signal settings_requested
signal journal_requested
signal map_requested
signal playtest_requested
signal title_requested
signal quit_requested

var _assets
var panel: PanelContainer
var subtitle_lbl: Label
var resume_btn: Button
var settings_btn: Button
var journal_btn: Button
var map_btn: Button
var playtest_btn: Button
var title_btn: Button
var quit_btn: Button


func setup_panel(assets_ref) -> void:
	_assets = assets_ref
	name = "PauseMenuPanel"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var scrim := ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.03, 0.04, 0.07, 0.62)
	add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 0)
	_assets.style_parchment_panel(panel)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "PAUSED"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.38))
	vbox.add_child(title_lbl)

	subtitle_lbl = Label.new()
	subtitle_lbl.text = "Harbor of Bruges"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.78, 0.75, 0.68))
	vbox.add_child(subtitle_lbl)

	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.62, 0.50, 0.30, 0.40)
	vbox.add_child(div)

	resume_btn = _make_btn("Resume Journey [Esc]", 38)
	resume_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("resume_requested")
	)
	vbox.add_child(resume_btn)

	settings_btn = _make_btn("Settings  (Audio, Hints & Controls)", 36)
	settings_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("settings_requested")
	)
	vbox.add_child(settings_btn)

	journal_btn = _make_btn("Brotherhood Diary & Controls", 34)
	journal_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("journal_requested")
	)
	vbox.add_child(journal_btn)

	map_btn = _make_btn("Parchment World Map", 34)
	map_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("map_requested")
	)
	vbox.add_child(map_btn)

	playtest_btn = _make_btn("Chapters & Playtest Jump [F1]", 34)
	playtest_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("playtest_requested")
	)
	vbox.add_child(playtest_btn)

	var div2 := ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 2)
	div2.color = Color(0.62, 0.50, 0.30, 0.30)
	vbox.add_child(div2)

	title_btn = _make_btn("Return to Title Screen", 34)
	title_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("title_requested")
	)
	vbox.add_child(title_btn)

	quit_btn = _make_btn("Quit to Desktop", 34)
	quit_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("quit_requested")
	)
	vbox.add_child(quit_btn)


func _make_btn(text_val: String, height_px: int) -> Button:
	var btn := Button.new()
	btn.text = text_val
	btn.custom_minimum_size = Vector2(0, height_px)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn


func apply_post_theme_fixes() -> void:
	if resume_btn != null:
		resume_btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.56))
		resume_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.72))


func open_pause(region_title: String = "") -> void:
	if subtitle_lbl != null:
		var fallback_region: Variant = GameState.get("current_region")
		var region_txt: String = region_title if region_title != "" else (str(fallback_region) if fallback_region != null else "In the Field")
		var j_key: String = GameState.get_action_key_label("journal")
		var m_key: String = GameState.get_action_key_label("toggle_map")
		if journal_btn != null:
			journal_btn.text = "Brotherhood Diary & Controls [%s]" % j_key
		if map_btn != null:
			map_btn.text = "Parchment World Map [%s]" % m_key
		subtitle_lbl.text = "%s  •  Traveling as %s" % [region_txt, GameState.player_name]
	visible = true
	if resume_btn != null and is_inside_tree():
		resume_btn.call_deferred("grab_focus")
