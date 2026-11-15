extends Control

signal start_game_requested(boy_name: String)
signal settings_requested
signal playtest_requested
signal quit_requested

var _assets
var card_panel: PanelContainer
var menu_box: VBoxContainer
var name_box: VBoxContainer

var begin_btn: Button
var settings_btn: Button
var playtest_btn: Button
var quit_btn: Button
var status_lbl: Label

var name_input: LineEdit
var sail_btn: Button
var back_btn: Button


func setup_panel(assets_ref) -> void:
	_assets = assets_ref
	name = "TitleScreenPanel"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var scrim := ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.03, 0.04, 0.07, 0.44)
	add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(560, 0)
	_assets.style_parchment_panel(card_panel)
	center.add_child(card_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	card_panel.add_child(root_vbox)

	_build_header(root_vbox)
	_build_divider(root_vbox)
	_build_menu_view(root_vbox)
	_build_name_view(root_vbox)

	show_main_menu()
	refresh_status()


func _build_header(parent: VBoxContainer) -> void:
	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 14)
	parent.add_child(header_row)

	var emblem_tex: Texture2D = _assets.get_tex("ui_brotherhood_emblem.png")
	if emblem_tex != null:
		var emblem := TextureRect.new()
		emblem.texture = emblem_tex
		emblem.custom_minimum_size = Vector2(44, 44)
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		header_row.add_child(emblem)

	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 2)
	header_row.add_child(title_col)

	var title_lbl := Label.new()
	title_lbl.text = "WINGS OF THE BROTHERHOOD"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.97, 0.82, 0.42))
	title_col.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Book I: The Harbor Ledger of Bruges  •  Medieval Flanders, 1347"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.84, 0.79, 0.68))
	title_col.add_child(sub_lbl)


func _build_divider(parent: VBoxContainer) -> void:
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.68, 0.54, 0.30, 0.45)
	parent.add_child(div)


func _build_menu_view(parent: VBoxContainer) -> void:
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 10)
	parent.add_child(menu_box)

	var lore_lbl := Label.new()
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_lbl.text = "Steer rigging knots, brave storm-swept skies, and uncover a cabal hidden beneath Flanders' timbered gables."
	lore_lbl.add_theme_font_size_override("font_size", 14)
	lore_lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	menu_box.add_child(lore_lbl)

	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	menu_box.add_child(btn_box)

	begin_btn = _make_menu_button("Begin New Journey", 42)
	begin_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		show_name_entry()
	)
	btn_box.add_child(begin_btn)

	settings_btn = _make_menu_button("Settings  (Audio, Hints & Controls)", 38)
	settings_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("settings_requested")
	)
	btn_box.add_child(settings_btn)

	playtest_btn = _make_menu_button("Chapters & Playtest Jump [F1]", 36)
	playtest_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("playtest_requested")
	)
	btn_box.add_child(playtest_btn)

	quit_btn = _make_menu_button("Quit to Desktop", 34)
	quit_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		emit_signal("quit_requested")
	)
	btn_box.add_child(quit_btn)

	status_lbl = Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", Color(0.74, 0.72, 0.64))
	menu_box.add_child(status_lbl)


func _build_name_view(parent: VBoxContainer) -> void:
	name_box = VBoxContainer.new()
	name_box.add_theme_constant_override("separation", 10)
	name_box.visible = false
	parent.add_child(name_box)

	var chapter_row := HBoxContainer.new()
	chapter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chapter_row.add_theme_constant_override("separation", 8)
	name_box.add_child(chapter_row)

	var seal_tex: Texture2D = _assets.get_tex("ui_wax_seal.png")
	if seal_tex != null:
		var seal := TextureRect.new()
		seal.texture = seal_tex
		seal.custom_minimum_size = Vector2(26, 26)
		seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		seal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		chapter_row.add_child(seal)

	var ch_lbl := Label.new()
	ch_lbl.text = "Chapter I — Midnight Tide on the Zwijn"
	ch_lbl.add_theme_font_size_override("font_size", 16)
	ch_lbl.add_theme_color_override("font_color", Color(0.94, 0.80, 0.45))
	chapter_row.add_child(ch_lbl)

	var intro_lbl := Label.new()
	intro_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_lbl.text = "Dusk settles over the Zwin canal. At twelve years old, your palms are raw from hauling lines aboard the merchant cog 'De Zwaan'.\n\nAhead lie the timber wharves of the Port of Bruges, where your sister Clara twists cordage at the Ropewalk and Uncle Willem keeps a warm hearth—all the home you two have left since your parents failed to return from Old Heverlee four years ago.\n\nWhat is the boy's name?"
	intro_lbl.add_theme_font_size_override("font_size", 13)
	intro_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	name_box.add_child(intro_lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	name_box.add_child(row)

	var n_lbl := Label.new()
	n_lbl.text = "Boy's Name:"
	n_lbl.add_theme_font_size_override("font_size", 14)
	n_lbl.add_theme_color_override("font_color", Color(0.92, 0.84, 0.66))
	row.add_child(n_lbl)

	name_input = LineEdit.new()
	name_input.text = GameState.player_name
	name_input.placeholder_text = "e.g. Bram"
	name_input.max_length = 18
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.text_submitted.connect(func(_t): _emit_start())
	row.add_child(name_input)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	name_box.add_child(action_row)

	back_btn = _make_menu_button("Back", 40)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.size_flags_stretch_ratio = 0.42
	back_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		show_main_menu()
	)
	action_row.add_child(back_btn)

	sail_btn = _make_menu_button("Set Sail on 'De Zwaan'", 40)
	sail_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sail_btn.size_flags_stretch_ratio = 1.0
	sail_btn.pressed.connect(_emit_start)
	action_row.add_child(sail_btn)


func _make_menu_button(label_text: String, height_px: int) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, height_px)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn


func apply_post_theme_fixes() -> void:
	for b in [begin_btn, sail_btn]:
		if b != null:
			b.add_theme_color_override("font_color", Color(1.0, 0.90, 0.56))
			b.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.72))


func show_main_menu() -> void:
	if menu_box != null:
		menu_box.visible = true
	if name_box != null:
		name_box.visible = false
	refresh_status()
	if begin_btn != null and is_inside_tree():
		begin_btn.call_deferred("grab_focus")


func show_name_entry() -> void:
	if menu_box != null:
		menu_box.visible = false
	if name_box != null:
		name_box.visible = true
	if name_input != null:
		name_input.text = GameState.player_name
		if is_inside_tree():
			name_input.call_deferred("grab_focus")
			name_input.call_deferred("select_all")


func is_name_entry_visible() -> bool:
	return visible and name_box != null and name_box.visible


func refresh_status() -> void:
	if status_lbl == null:
		return
	var audio_txt := "MUTED" if GameState.audio_muted else "%d%%" % int(round(GameState.master_volume * 100.0))
	var hints_txt := "ON" if GameState.hints_enabled else "OFF"
	var prompts_txt := "ON" if GameState.control_prompts_enabled else "OFF"
	var speed_txt := GameState.dialogue_speed_mode.capitalize()
	status_lbl.text = "Audio: %s   |   Hints: %s   |   Prompts: %s   |   Text: %s" % [audio_txt, hints_txt, prompts_txt, speed_txt]


func _emit_start() -> void:
	SoundManager.play_ui_click()
	var nm := name_input.text.strip_edges() if name_input != null else ""
	if nm == "":
		nm = "Bram"
	emit_signal("start_game_requested", nm)
