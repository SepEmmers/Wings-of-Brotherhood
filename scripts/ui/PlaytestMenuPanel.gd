extends PanelContainer

## [F1] Chapter-Split Playtest & Debug Menu driven by PlaytestPresets.

signal jump_requested(scene_id: String)
signal lighting_mode_changed(mode: String)
signal open_knot_requested(knot_id: String)
signal title_requested
signal close_requested

const PlaytestPresetsScript := preload("res://scripts/data/PlaytestPresets.gd")
const JournalLoreDataScript := preload("res://scripts/data/JournalLoreData.gd")

var assets
var lighting_mode: String = "auto"
var selected_tab: String = "ch1"
var previewed_preset_id: String = "boat_sailing"

var status_summary_lbl: Label
var top_close_btn: Button
var tab_buttons: Dictionary = {}
var chapter_title_lbl: Label
var chapter_desc_lbl: Label
var preset_scroll: ScrollContainer
var preset_list_vbox: VBoxContainer
var _preset_row_buttons: Array[Button] = []

var preview_tag_lbl: Label
var preview_kind_lbl: Label
var preview_now_lbl: Label
var preview_title_lbl: Label
var preview_location_lbl: Label
var preview_summary_lbl: Label
var preview_kit_lbl: Label
var preview_jump_btn: Button

var playtest_speed_btn: Button
var playtest_light_btn: Button
var unlock_knots_btn: Button
var cycle_knot_btn: Button
var knot_board_btn: Button
var heal_btn: Button
var map_toggle_btn: Button
var title_btn: Button
var resume_btn: Button

var _btn_normal_sb: StyleBox
var _btn_hover_sb: StyleBox
var _btn_pressed_sb: StyleBox
var _tab_active_sb: StyleBoxFlat
var _tab_idle_sb: StyleBoxFlat
var _tab_hover_sb: StyleBoxFlat
var _row_scene_sb: StyleBoxFlat
var _row_cutscene_sb: StyleBoxFlat
var _row_current_sb: StyleBoxFlat
var _row_hover_sb: StyleBoxFlat
var _row_pressed_sb: StyleBoxFlat
var _inset_sb: StyleBoxFlat


func setup(assets_ref) -> void:
	assets = assets_ref
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -445
	offset_top = -310
	offset_right = 445
	offset_bottom = 310
	visible = false
	assets.style_parchment_panel(self)
	_init_styles()

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 6)
	add_child(root_vbox)

	_build_header(root_vbox)
	_build_chapter_tabs(root_vbox)

	var top_rule := ColorRect.new()
	top_rule.custom_minimum_size = Vector2(0, 1)
	top_rule.color = Color(0.66, 0.52, 0.26, 0.55)
	root_vbox.add_child(top_rule)

	var body_split := HBoxContainer.new()
	body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_split.add_theme_constant_override("separation", 14)
	root_vbox.add_child(body_split)

	_build_left_chapter_list(body_split)
	_build_right_inspector_and_tools(body_split)
	_build_footer(root_vbox)

	refresh(true)


func _make_flat_sb(bg: Color, border: Color, bw: int, pad_h: int = -1, pad_v: int = -1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(3)
	if pad_h >= 0:
		sb.content_margin_left = pad_h
		sb.content_margin_right = pad_h
	if pad_v >= 0:
		sb.content_margin_top = pad_v
		sb.content_margin_bottom = pad_v
	return sb


func _make_lbl(parent: Node, txt: String, font_sz: int, col: Color, wrap: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", col)
	if wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)
	return lbl


func _init_styles() -> void:
	_btn_normal_sb = assets.make_ui_9slice_style("ui_btn_normal.png", 6.0, 10.0, 4.0)
	_btn_hover_sb = assets.make_ui_9slice_style("ui_btn_hover.png", 6.0, 10.0, 4.0)
	_btn_pressed_sb = assets.make_ui_9slice_style("ui_btn_pressed.png", 6.0, 10.0, 4.0)

	_inset_sb = _make_flat_sb(Color(0.08, 0.06, 0.10, 0.92), Color(0.58, 0.45, 0.24, 0.88), 2, 10, 8)
	_tab_active_sb = _make_flat_sb(Color(0.24, 0.19, 0.12, 0.98), Color(0.95, 0.80, 0.44, 1.0), 2, 6, 6)
	_tab_idle_sb = _make_flat_sb(Color(0.11, 0.10, 0.14, 0.92), Color(0.42, 0.34, 0.22, 0.85), 1, 6, 6)
	_tab_hover_sb = _make_flat_sb(Color(0.18, 0.15, 0.18, 0.96), Color(0.84, 0.68, 0.38, 0.95), 2, 6, 6)
	_row_scene_sb = _make_flat_sb(Color(0.11, 0.10, 0.14, 0.95), Color(0.46, 0.37, 0.22, 0.90), 1)
	_row_cutscene_sb = _make_flat_sb(Color(0.15, 0.10, 0.13, 0.95), Color(0.62, 0.40, 0.26, 0.92), 1)
	_row_current_sb = _make_flat_sb(Color(0.10, 0.17, 0.14, 0.96), Color(0.48, 0.80, 0.56, 0.98), 2)
	_row_hover_sb = _make_flat_sb(Color(0.20, 0.17, 0.22, 0.98), Color(0.95, 0.80, 0.44, 1.0), 2)
	_row_pressed_sb = _make_flat_sb(Color(0.26, 0.21, 0.15, 0.98), Color(1.0, 0.88, 0.54, 1.0), 2)


func _build_header(parent: VBoxContainer) -> void:
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	parent.add_child(hdr)

	var seal_tex: Texture2D = assets.get_tex("ui_wax_seal.png")
	if seal_tex != null:
		var seal := TextureRect.new()
		seal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		seal.custom_minimum_size = Vector2(24, 24)
		seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		seal.texture = seal_tex
		hdr.add_child(seal)

	_make_lbl(hdr, "PLAYTEST & CHAPTER JUMP MENU", 17, Color(0.96, 0.84, 0.50))

	status_summary_lbl = _make_lbl(hdr, "", 12, Color(0.76, 0.88, 0.78))
	status_summary_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_summary_lbl.clip_text = true

	top_close_btn = Button.new()
	top_close_btn.text = "X"
	top_close_btn.custom_minimum_size = Vector2(34, 28)
	top_close_btn.pressed.connect(func(): emit_signal("close_requested"))
	hdr.add_child(top_close_btn)


func _build_chapter_tabs(parent: VBoxContainer) -> void:
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 8)
	parent.add_child(tabs_row)

	tab_buttons.clear()
	for ch in PlaytestPresetsScript.CHAPTERS:
		var tab_id: String = ch["id"]
		var tb := Button.new()
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 32)
		tb.add_theme_font_size_override("font_size", 13)
		tb.pressed.connect(func():
			SoundManager.play_ui_click()
			selected_tab = tab_id
			refresh(false)
		)
		tabs_row.add_child(tb)
		tab_buttons[tab_id] = tb


func _build_left_chapter_list(parent: HBoxContainer) -> void:
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.custom_minimum_size = Vector2(465, 0)
	left_col.add_theme_constant_override("separation", 8)
	parent.add_child(left_col)

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", _inset_sb)
	left_col.add_child(banner)

	var banner_vbox := VBoxContainer.new()
	banner_vbox.add_theme_constant_override("separation", 2)
	banner.add_child(banner_vbox)

	chapter_title_lbl = _make_lbl(banner_vbox, "", 14, Color(0.96, 0.84, 0.50))
	chapter_desc_lbl = _make_lbl(banner_vbox, "", 11, Color(0.80, 0.78, 0.74), true)

	preset_scroll = ScrollContainer.new()
	preset_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preset_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(preset_scroll)

	preset_list_vbox = VBoxContainer.new()
	preset_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_list_vbox.add_theme_constant_override("separation", 5)
	preset_scroll.add_child(preset_list_vbox)


func _build_right_inspector_and_tools(parent: HBoxContainer) -> void:
	var right_col := VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(345, 0)
	right_col.add_theme_constant_override("separation", 8)
	parent.add_child(right_col)

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.add_theme_stylebox_override("panel", _inset_sb)
	right_col.add_child(preview_panel)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	preview_panel.add_child(pv)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	pv.add_child(badge_row)

	preview_tag_lbl = _make_lbl(badge_row, "", 12, Color(0.96, 0.84, 0.50))
	preview_kind_lbl = _make_lbl(badge_row, "", 11, Color(0.68, 0.84, 0.74))
	preview_now_lbl = _make_lbl(badge_row, "", 11, Color(0.58, 0.90, 0.64))
	preview_now_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_now_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	preview_title_lbl = _make_lbl(pv, "", 16, Color(0.98, 0.90, 0.66), true)
	preview_location_lbl = _make_lbl(pv, "", 12, Color(0.66, 0.84, 0.78), true)

	var pv_rule := ColorRect.new()
	pv_rule.custom_minimum_size = Vector2(0, 1)
	pv_rule.color = Color(0.56, 0.44, 0.24, 0.55)
	pv.add_child(pv_rule)

	preview_summary_lbl = _make_lbl(pv, "", 12, Color(0.92, 0.90, 0.84), true)
	preview_summary_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_kit_lbl = _make_lbl(pv, "", 12, Color(0.92, 0.78, 0.46), true)

	preview_jump_btn = Button.new()
	preview_jump_btn.text = "Jump to Selected Beat"
	preview_jump_btn.custom_minimum_size = Vector2(0, 30)
	preview_jump_btn.add_theme_font_size_override("font_size", 12)
	preview_jump_btn.pressed.connect(func(): _trigger_jump(previewed_preset_id))
	pv.add_child(preview_jump_btn)

	var tools_panel := PanelContainer.new()
	tools_panel.add_theme_stylebox_override("panel", _inset_sb)
	right_col.add_child(tools_panel)

	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 5)
	tools_panel.add_child(tv)

	_make_lbl(tv, "QUICK DEBUG TOOLS", 11, Color(0.88, 0.74, 0.42))

	var tools_grid := GridContainer.new()
	tools_grid.columns = 2
	tools_grid.add_theme_constant_override("h_separation", 6)
	tools_grid.add_theme_constant_override("v_separation", 4)
	tv.add_child(tools_grid)

	playtest_speed_btn = _make_tool_btn(tools_grid, func():
		SoundManager.play_ui_click()
		GameState.playtest_speed_mult = 2.2 if is_equal_approx(GameState.playtest_speed_mult, 1.0) else 1.0
		_refresh_tool_buttons()
	)
	playtest_light_btn = _make_tool_btn(tools_grid, func():
		SoundManager.play_ui_click()
		var modes := ["auto", "dusk", "night", "dawn"]
		lighting_mode = modes[(modes.find(lighting_mode) + 1) % modes.size()]
		emit_signal("lighting_mode_changed", lighting_mode)
		_refresh_tool_buttons()
	)
	unlock_knots_btn = _make_tool_btn(tools_grid, func():
		GameState.unlock_all_knots()
		SoundManager.play_chime()
		_refresh_status_header()
		_refresh_tool_buttons()
	)
	cycle_knot_btn = _make_tool_btn(tools_grid, func():
		GameState.cycle_knot()
		_refresh_status_header()
		_refresh_tool_buttons()
	)
	knot_board_btn = _make_tool_btn(tools_grid, func():
		SoundManager.play_ui_click()
		visible = false
		emit_signal("open_knot_requested", GameState.equipped_knot)
	)
	heal_btn = _make_tool_btn(tools_grid, func():
		GameState.boy_hp = GameState.boy_max_hp
		if GameState.carrying_egg:
			GameState.egg_warmth = 100.0
		GameState.emit_signal("state_updated")
		SoundManager.play_chime()
		_refresh_status_header()
		_refresh_tool_buttons()
	)
	map_toggle_btn = _make_tool_btn(tools_grid, func():
		SoundManager.play_ui_click()
		GameState.has_forest_map = not GameState.has_forest_map
		if GameState.has_forest_map:
			GameState.add_item("Brotherhood Border Survey Map")
		else:
			GameState.remove_item("Brotherhood Border Survey Map")
		_refresh_tool_buttons()
	)
	title_btn = _make_tool_btn(tools_grid, func():
		SoundManager.play_ui_click()
		emit_signal("title_requested")
	)


func _make_tool_btn(parent: GridContainer, cb: Callable) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 26)
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_footer(parent: VBoxContainer) -> void:
	var ftr := HBoxContainer.new()
	ftr.add_theme_constant_override("separation", 10)
	parent.add_child(ftr)

	var hint_lbl := _make_lbl(
		ftr,
		"Click any beat to jump immediately  •  Hover to inspect  •  [F1] / [~] / [Esc] to resume",
		12,
		Color(0.76, 0.74, 0.68)
	)
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	resume_btn = Button.new()
	resume_btn.text = "Resume [F1 / Esc]"
	resume_btn.custom_minimum_size = Vector2(165, 30)
	resume_btn.add_theme_font_size_override("font_size", 13)
	resume_btn.pressed.connect(func(): emit_signal("close_requested"))
	ftr.add_child(resume_btn)


func apply_post_theme_fixes() -> void:
	_refresh_tab_buttons()
	_style_preset_rows()
	_refresh_tool_buttons()
	for btn in [top_close_btn, preview_jump_btn, resume_btn]:
		if btn != null:
			_apply_button_9slice(btn)


func grab_initial_focus() -> void:
	var active_tab_btn: Button = tab_buttons.get(selected_tab)
	if active_tab_btn != null and is_instance_valid(active_tab_btn):
		active_tab_btn.grab_focus()


func refresh(auto_select_chapter: bool = false) -> void:
	if auto_select_chapter:
		selected_tab = PlaytestPresetsScript.get_active_chapter_id()

	_refresh_status_header()
	_refresh_tab_buttons()
	_rebuild_preset_list()
	_refresh_tool_buttons()


func _refresh_status_header() -> void:
	if status_summary_lbl == null:
		return
	status_summary_lbl.text = "Now: %s  |  %s (Age %d)  |  HP %d/%d  |  Knots %d/4" % [
		JournalLoreDataScript.get_chapter_subtitle(),
		GameState.player_name,
		GameState.boy_age,
		GameState.boy_hp,
		GameState.boy_max_hp,
		GameState.unlocked_knots.size(),
	]


func _refresh_tab_buttons() -> void:
	var active_ch := PlaytestPresetsScript.get_active_chapter_id()
	for ch in PlaytestPresetsScript.CHAPTERS:
		var tab_id: String = ch["id"]
		var tb: Button = tab_buttons.get(tab_id)
		if tb == null:
			continue
		var count := PlaytestPresetsScript.get_presets_for_tab(tab_id).size()
		var prefix := "• " if tab_id == active_ch and tab_id != selected_tab else ""
		tb.text = "%s%s (%d)" % [prefix, ch["tab_label"], count]
		var is_sel := (tab_id == selected_tab)
		tb.add_theme_stylebox_override("normal", _tab_active_sb if is_sel else _tab_idle_sb)
		tb.add_theme_stylebox_override("hover", _tab_active_sb if is_sel else _tab_hover_sb)
		tb.add_theme_stylebox_override("pressed", _tab_active_sb)
		tb.add_theme_stylebox_override("focus", _tab_active_sb if is_sel else _tab_hover_sb)
		var txt_col := Color(1.0, 0.92, 0.62) if is_sel else (Color(0.68, 0.90, 0.74) if tab_id == active_ch else Color(0.84, 0.80, 0.74))
		tb.add_theme_color_override("font_color", txt_col)
		tb.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78))


func _rebuild_preset_list() -> void:
	if preset_list_vbox == null:
		return
	for child in preset_list_vbox.get_children():
		preset_list_vbox.remove_child(child)
		child.queue_free()
	_preset_row_buttons.clear()

	var ch_info := PlaytestPresetsScript.get_chapter_info(selected_tab)
	chapter_title_lbl.text = ch_info.get("title", "")
	chapter_desc_lbl.text = ch_info.get("subtitle", "")

	var presets := PlaytestPresetsScript.get_presets_for_tab(selected_tab)
	var active_id := PlaytestPresetsScript.get_active_preset_id()
	var default_preview: Dictionary = {}

	for preset in presets:
		var pid: String = preset["id"]
		var is_current := (pid == active_id)
		if is_current or default_preview.is_empty():
			default_preview = preset

		var row_btn := Button.new()
		row_btn.text = ""
		row_btn.custom_minimum_size = Vector2(0, 35)
		row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_btn.set_meta("preset_kind", preset.get("kind", "scene"))
		row_btn.set_meta("is_current", is_current)
		row_btn.pressed.connect(func(): _trigger_jump(pid))
		row_btn.mouse_entered.connect(func(): _update_preview(preset))
		row_btn.focus_entered.connect(func(): _update_preview(preset))

		var pad := MarginContainer.new()
		pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pad.add_theme_constant_override("margin_left", 10)
		pad.add_theme_constant_override("margin_right", 10)
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_btn.add_child(pad)

		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 8)
		row_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.add_child(row_box)

		var is_cs: bool = (preset.get("kind", "scene") == "cutscene")
		var tag_lbl := _make_row_label(row_box, preset.get("tag", ""), 12, Color(0.96, 0.68, 0.42) if is_cs else Color(0.95, 0.82, 0.48))
		tag_lbl.custom_minimum_size = Vector2(46, 0)

		var name_lbl := _make_row_label(row_box, preset.get("title", preset.get("label", pid)), 13, Color(1.0, 0.94, 0.72) if is_current else Color(0.94, 0.91, 0.84))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_text = true

		var badge_txt := "PLAYABLE"
		var badge_col := Color(0.62, 0.76, 0.70)
		if is_current:
			badge_txt = "CURRENT"
			badge_col = Color(0.56, 0.90, 0.64)
		elif selected_tab == "cutscenes":
			badge_txt = "%s CUTSCENE" % String(preset.get("chapter", "ch1")).replace("ch", "CH. ")
			badge_col = Color(0.94, 0.68, 0.44)
		elif is_cs:
			badge_txt = "CUTSCENE"
			badge_col = Color(0.94, 0.68, 0.44)
		var badge_lbl := _make_row_label(row_box, badge_txt, 11, badge_col)
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		preset_list_vbox.add_child(row_btn)
		_preset_row_buttons.append(row_btn)

	_style_preset_rows()
	if not default_preview.is_empty():
		_update_preview(default_preview)
	else:
		_show_empty_tab_preview(ch_info)


func _show_empty_tab_preview(ch_info: Dictionary) -> void:
	previewed_preset_id = ""
	preview_tag_lbl.text = "[BOOK II]"
	preview_kind_lbl.text = "PLUMBING READY"
	preview_kind_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.42))
	preview_now_lbl.text = ""
	preview_title_lbl.text = ch_info.get("title", "Book II — The Golden Heir")
	preview_location_lbl.text = "Theater: Brabant • Louvain • Namur • Ardennes"
	preview_summary_lbl.text = "Shared Book II QuestSteps, Kingdom of Belgium [M] Chart, Golden Mind-Voice Telepathy & [R]/[X]/[T] Companion bindings are live. Region scenes unlock next!"
	preview_kit_lbl.text = "Tip: Open [M] and pick 'Kingdom Charter' to preview the eastern realm."
	if preview_jump_btn != null:
		preview_jump_btn.disabled = true
		preview_jump_btn.text = "Regions In Construction..."


func _make_row_label(parent: HBoxContainer, txt: String, font_sz: int, col: Color) -> Label:
	var lbl := _make_lbl(parent, txt, font_sz, col)
	lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _style_preset_rows() -> void:
	for b in _preset_row_buttons:
		if not is_instance_valid(b):
			continue
		var is_current := bool(b.get_meta("is_current", false))
		var is_cs := (String(b.get_meta("preset_kind", "scene")) == "cutscene")
		var normal_sb := _row_current_sb if is_current else (_row_cutscene_sb if is_cs else _row_scene_sb)
		b.add_theme_stylebox_override("normal", normal_sb)
		b.add_theme_stylebox_override("hover", _row_hover_sb)
		b.add_theme_stylebox_override("pressed", _row_pressed_sb)
		b.add_theme_stylebox_override("focus", _row_hover_sb)


func _update_preview(preset: Dictionary) -> void:
	if preset.is_empty():
		return
	previewed_preset_id = preset["id"]
	var is_cs: bool = (preset.get("kind", "scene") == "cutscene")
	var is_current := (previewed_preset_id == PlaytestPresetsScript.get_active_preset_id())

	preview_tag_lbl.text = "[%s]" % preset.get("tag", "")
	preview_kind_lbl.text = "STORY CUTSCENE" if is_cs else "PLAYABLE SCENE"
	preview_kind_lbl.add_theme_color_override("font_color", Color(0.95, 0.68, 0.42) if is_cs else Color(0.66, 0.84, 0.74))
	preview_now_lbl.text = "• ACTIVE NOW" if is_current else ""
	preview_title_lbl.text = preset.get("title", "")
	preview_location_lbl.text = "Location: %s" % preset.get("location", "")
	preview_summary_lbl.text = preset.get("summary", "")
	preview_kit_lbl.text = "Loads with: %s" % preset.get("kit", "")
	if preview_jump_btn != null:
		preview_jump_btn.disabled = false
		preview_jump_btn.text = "Jump to %s" % preset.get("tag", "Beat")


func _refresh_tool_buttons() -> void:
	var fast := not is_equal_approx(GameState.playtest_speed_mult, 1.0)
	if playtest_speed_btn != null:
		playtest_speed_btn.text = "Speed: 2.2x [ON]" if fast else "Speed: 1.0x"
		_apply_button_9slice(playtest_speed_btn, Color(0.86, 1.08, 0.86) if fast else Color.WHITE)

	if playtest_light_btn != null:
		var custom_light := (lighting_mode != "auto")
		playtest_light_btn.text = "Light: %s" % lighting_mode.capitalize()
		_apply_button_9slice(playtest_light_btn, Color(1.08, 0.96, 0.78) if custom_light else Color.WHITE)

	var k_cnt := GameState.unlocked_knots.size()
	if unlock_knots_btn != null:
		unlock_knots_btn.text = "Knots: 4/4 ✓" if k_cnt >= 4 else "Unlock Knots (%d/4)" % k_cnt
		_apply_button_9slice(unlock_knots_btn, Color(0.84, 1.02, 0.86) if k_cnt >= 4 else Color.WHITE)

	if cycle_knot_btn != null:
		cycle_knot_btn.text = "Knot: %s" % GameState.get_knot_display()
		cycle_knot_btn.disabled = (k_cnt <= 1)
		_apply_button_9slice(cycle_knot_btn, Color(0.75, 0.75, 0.75) if k_cnt <= 1 else Color.WHITE)

	if knot_board_btn != null:
		knot_board_btn.text = "Knot Board [K]"
		_apply_button_9slice(knot_board_btn)

	if heal_btn != null:
		var hp_full := (GameState.boy_hp >= GameState.boy_max_hp)
		var egg_ok := (not GameState.carrying_egg or GameState.egg_warmth >= 99.0)
		if GameState.carrying_egg:
			heal_btn.text = "HP & Egg Full ✓" if (hp_full and egg_ok) else "Heal & Warm Egg"
		else:
			heal_btn.text = "HP Full (%d/%d) ✓" % [GameState.boy_hp, GameState.boy_max_hp] if hp_full else "Heal Boy (%d/%d)" % [GameState.boy_hp, GameState.boy_max_hp]
		_apply_button_9slice(heal_btn)

	if map_toggle_btn != null:
		map_toggle_btn.text = "Border Map: ON ✓" if GameState.has_forest_map else "Border Map: OFF"
		_apply_button_9slice(map_toggle_btn, Color(0.86, 1.08, 0.86) if GameState.has_forest_map else Color.WHITE)

	if title_btn != null:
		title_btn.text = "Title Screen"
		_apply_button_9slice(title_btn)


func _apply_button_9slice(btn: Button, mod: Color = Color.WHITE) -> void:
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	btn.add_theme_stylebox_override("normal", _btn_normal_sb)
	btn.add_theme_stylebox_override("hover", _btn_hover_sb)
	btn.add_theme_stylebox_override("pressed", _btn_pressed_sb)
	btn.add_theme_stylebox_override("focus", _btn_hover_sb)
	btn.add_theme_color_override("font_color", Color(0.95, 0.89, 0.74))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82))
	btn.add_theme_color_override("font_pressed_color", Color(0.86, 0.76, 0.56))
	btn.add_theme_color_override("font_disabled_color", Color(0.62, 0.60, 0.56))
	btn.modulate = mod


func _trigger_jump(scene_id: String) -> void:
	if scene_id.is_empty():
		return
	SoundManager.play_ui_click()
	visible = false
	emit_signal("jump_requested", scene_id)
