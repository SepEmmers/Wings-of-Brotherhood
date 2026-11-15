extends Control

signal start_game_requested(boy_name: String)
signal settings_requested
signal playtest_requested
signal quit_requested

const SCENE_SIZE := Vector2(320.0, 180.0)
const STAR_SPOTS := [
	Vector2(28, 16), Vector2(68, 24), Vector2(114, 12),
	Vector2(154, 19), Vector2(218, 13), Vector2(266, 25), Vector2(294, 15),
]
const EMBER_SEEDS := [
	{"x": 43.0, "y": 103.0, "spd": 5.2, "ph": 0.1},
	{"x": 76.0, "y": 116.0, "spd": 4.4, "ph": 1.4},
	{"x": 92.0, "y": 113.0, "spd": 6.0, "ph": 2.7},
	{"x": 85.0, "y": 118.0, "spd": 4.8, "ph": 3.9},
	{"x": 45.0, "y": 107.0, "spd": 5.6, "ph": 5.1},
	{"x": 97.0, "y": 111.0, "spd": 4.1, "ph": 0.8},
]

var _assets
var _backdrop: Control
var _title_block: VBoxContainer
var _crest_rect: TextureRect
var _menu_box: VBoxContainer
var _name_wrap: CenterContainer
var _name_panel: PanelContainer
var _menu_btns: Array[Button] = []
var _menu_cursors: Array[Dictionary] = []
var _selected_idx: int = 0
var _anim_t: float = 0.0
var _reveal_t: float = 0.0

var name_input: LineEdit
var _start_btn: Button
var _settings_btn: Button
var _playtest_btn: Button
var _quit_btn: Button
var _back_btn: Button
var _embark_btn: Button

var _sky_tex: Texture2D
var _cloud_tex: Texture2D
var _fg_tex: Texture2D
var _roost_0_tex: Texture2D
var _roost_1_tex: Texture2D
var _virelai_0_tex: Texture2D
var _virelai_1_tex: Texture2D
var _cursor_tex: Texture2D


class _BackdropCanvas extends Control:
	var owner_panel: Control

	func _draw() -> void:
		if owner_panel != null:
			owner_panel._draw_diorama(self)


func setup_panel(assets_ref) -> void:
	_assets = assets_ref
	name = "TitleScreenPanel"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false

	_sky_tex = _assets.get_tex("title_bg_sky.png")
	_cloud_tex = _assets.get_tex("title_clouds_ribbon.png")
	_fg_tex = _assets.get_tex("title_fg_cliff.png")
	_roost_0_tex = _assets.get_tex("title_hatchling_roost_0.png")
	_roost_1_tex = _assets.get_tex("title_hatchling_roost_1.png")
	_virelai_0_tex = _assets.get_tex("title_virelai_sky_0.png")
	_virelai_1_tex = _assets.get_tex("title_virelai_sky_1.png")
	_cursor_tex = _assets.get_tex("title_menu_cursor.png")

	_backdrop = _BackdropCanvas.new()
	_backdrop.owner_panel = self
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_backdrop)

	_build_title_crest()
	_build_main_menu()
	_build_name_charter()

	show_main_menu()
	refresh_status()


func _build_title_crest() -> void:
	var crest_anchor := Control.new()
	crest_anchor.set_anchors_preset(Control.PRESET_TOP_WIDE)
	crest_anchor.offset_top = 26
	crest_anchor.offset_bottom = 250
	crest_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crest_anchor)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest_anchor.add_child(center)

	_title_block = VBoxContainer.new()
	_title_block.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_block.add_theme_constant_override("separation", 4)
	_title_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_title_block)

	_crest_rect = TextureRect.new()
	_crest_rect.texture = _assets.get_tex("title_crest_emblem.png")
	_crest_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_crest_rect.custom_minimum_size = Vector2(240, 100)
	_crest_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crest_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_block.add_child(_crest_rect)

	var title_lbl := Label.new()
	title_lbl.text = "WINGS OF THE BROTHERHOOD"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", Color(0.99, 0.89, 0.56))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.07, 0.96))
	title_lbl.add_theme_constant_override("outline_size", 7)
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.06, 0.92))
	title_lbl.add_theme_constant_override("shadow_offset_x", 2)
	title_lbl.add_theme_constant_override("shadow_offset_y", 3)
	_title_block.add_child(title_lbl)

	var divider := TextureRect.new()
	divider.texture = _assets.get_tex("ui_divider_ornate.png")
	divider.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	divider.custom_minimum_size = Vector2(220, 14)
	divider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_block.add_child(divider)

	var sub_lbl := Label.new()
	sub_lbl.text = "FLANDERS   ·   BRABANT   ·   THE GOLDEN PROPHECY"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.86, 0.84, 0.76, 0.90))
	sub_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.90))
	sub_lbl.add_theme_constant_override("outline_size", 3)
	_title_block.add_child(sub_lbl)


func _build_main_menu() -> void:
	var menu_anchor := Control.new()
	menu_anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	menu_anchor.offset_top = -220
	menu_anchor.offset_bottom = -28
	add_child(menu_anchor)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_anchor.add_child(center)

	_menu_box = VBoxContainer.new()
	_menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu_box.add_theme_constant_override("separation", 6)
	center.add_child(_menu_box)

	_start_btn = _add_zelda_menu_row("Begin Journey", 21, func(): show_name_entry())
	_settings_btn = _add_zelda_menu_row("Settings", 16, func(): emit_signal("settings_requested"))
	_playtest_btn = _add_zelda_menu_row("Chapters & Playtest [F1]", 15, func(): emit_signal("playtest_requested"))
	_quit_btn = _add_zelda_menu_row("Quit to Desktop", 15, func(): emit_signal("quit_requested"))


func _add_zelda_menu_row(txt: String, fsize: int, on_pressed: Callable) -> Button:
	var idx := _menu_btns.size()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_menu_box.add_child(row)

	var l_cur := TextureRect.new()
	l_cur.texture = _cursor_tex
	l_cur.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l_cur.custom_minimum_size = Vector2(20, 14)
	l_cur.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	l_cur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l_cur)

	var btn := Button.new()
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	btn.text = txt
	btn.custom_minimum_size = Vector2(270, 34 if fsize >= 20 else 30)
	btn.add_theme_font_size_override("font_size", fsize)
	btn.pressed.connect(func():
		SoundManager.play_ui_click()
		on_pressed.call()
	)
	btn.mouse_entered.connect(func(): _set_selected_index(idx))
	btn.focus_entered.connect(func(): _set_selected_index(idx))
	row.add_child(btn)

	var r_cur := TextureRect.new()
	r_cur.texture = _cursor_tex
	r_cur.flip_h = true
	r_cur.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r_cur.custom_minimum_size = Vector2(20, 14)
	r_cur.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_cur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(r_cur)

	_menu_btns.append(btn)
	_menu_cursors.append({"l": l_cur, "r": r_cur})
	return btn


func _build_name_charter() -> void:
	var charter_anchor := Control.new()
	charter_anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	charter_anchor.offset_top = -238
	charter_anchor.offset_bottom = -26
	add_child(charter_anchor)

	_name_wrap = CenterContainer.new()
	_name_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_name_wrap.visible = false
	charter_anchor.add_child(_name_wrap)

	_name_panel = PanelContainer.new()
	_name_panel.custom_minimum_size = Vector2(468, 0)
	_assets.style_parchment_panel(_name_panel)
	_name_wrap.add_child(_name_panel)

	var name_box := VBoxContainer.new()
	name_box.add_theme_constant_override("separation", 10)
	_name_panel.add_child(name_box)

	var hdr := HBoxContainer.new()
	hdr.alignment = BoxContainer.ALIGNMENT_CENTER
	hdr.add_theme_constant_override("separation", 10)
	name_box.add_child(hdr)

	var seal := TextureRect.new()
	seal.texture = _assets.get_tex("ui_icon_quill.png")
	seal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	seal.custom_minimum_size = Vector2(22, 22)
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hdr.add_child(seal)

	var prompt_lbl := Label.new()
	prompt_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	prompt_lbl.text = "Inscribe the Boy's Name"
	prompt_lbl.add_theme_font_size_override("font_size", 18)
	prompt_lbl.add_theme_color_override("font_color", Color(0.97, 0.85, 0.46))
	hdr.add_child(prompt_lbl)

	name_input = LineEdit.new()
	name_input.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	name_input.text = "Bram"
	name_input.max_length = 14
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.custom_minimum_size = Vector2(280, 42)
	name_input.add_theme_font_size_override("font_size", 19)
	name_input.text_submitted.connect(_submit_name)
	name_box.add_child(name_input)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_box.add_child(btn_row)

	_back_btn = Button.new()
	_back_btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_back_btn.text = "Back"
	_back_btn.custom_minimum_size = Vector2(118, 36)
	_back_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		show_main_menu()
	)
	btn_row.add_child(_back_btn)

	_embark_btn = Button.new()
	_embark_btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_embark_btn.text = "Set Sail on 'De Zwaan'"
	_embark_btn.custom_minimum_size = Vector2(226, 36)
	_embark_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		_submit_name(name_input.text)
	)
	btn_row.add_child(_embark_btn)


func _set_selected_index(idx: int) -> void:
	_selected_idx = clampi(idx, 0, _menu_btns.size() - 1)
	_sync_cursor_visuals()
	if visible and _menu_box != null and _menu_box.visible and is_inside_tree():
		var target_btn := _menu_btns[_selected_idx]
		if target_btn != null and not target_btn.has_focus():
			target_btn.grab_focus()


func _sync_cursor_visuals() -> void:
	for i in range(_menu_btns.size()):
		var active := (i == _selected_idx)
		var b := _menu_btns[i]
		var col := Color(1.0, 0.93, 0.56) if active else Color(0.84, 0.80, 0.72, 0.86)
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_focus_color", col)
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.64))
		b.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.64))
		if i < _menu_cursors.size():
			_menu_cursors[i]["l"].modulate.a = 1.0 if active else 0.0
			_menu_cursors[i]["r"].modulate.a = 1.0 if active else 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_anim_t += delta
	_reveal_t = minf(1.0, _reveal_t + delta / 0.65)
	if _title_block != null:
		_title_block.modulate.a = ease(_reveal_t, -1.6)
	if _crest_rect != null:
		_crest_rect.position.y = sin(_anim_t * 1.4) * 2.0
	if _menu_box != null and _menu_box.visible:
		_menu_box.modulate.a = ease(clampf((_reveal_t - 0.25) / 0.75, 0.0, 1.0), -1.4)
		var pulse := 0.82 + 0.18 * sin(_anim_t * 4.5)
		if _selected_idx >= 0 and _selected_idx < _menu_cursors.size():
			_menu_cursors[_selected_idx]["l"].modulate = Color(1, 1, 1, pulse)
			_menu_cursors[_selected_idx]["r"].modulate = Color(1, 1, 1, pulse)
	if _backdrop != null:
		_backdrop.queue_redraw()


func _draw_diorama(canvas: Control) -> void:
	var sz: Vector2 = canvas.size
	if sz.x <= 1.0 or sz.y <= 1.0:
		return
	var sc: float = maxf(sz.x / SCENE_SIZE.x, sz.y / SCENE_SIZE.y)
	var dest_sz: Vector2 = SCENE_SIZE * sc
	var org: Vector2 = (sz - dest_sz) * 0.5
	var full_rect := Rect2(org, dest_sz)

	if _sky_tex != null:
		canvas.draw_texture_rect(_sky_tex, full_rect, false)

	# Twinkling distant twilight stars
	for i in range(STAR_SPOTS.size()):
		var tw: float = 0.45 + 0.55 * sin(_anim_t * (1.2 + float(i % 3) * 0.4) + float(i) * 1.7)
		var sp: Vector2 = org + STAR_SPOTS[i] * sc
		canvas.draw_rect(Rect2(sp, Vector2(sc, sc)), Color(0.96, 0.90, 0.72, tw * 0.65))

	# Slow seamless drifting clouds
	if _cloud_tex != null:
		var cloud_w: float = SCENE_SIZE.x * sc
		var cloud_h: float = 72.0 * sc
		var shift: float = fmod(_anim_t * 3.8, SCENE_SIZE.x) * sc
		var cy: float = org.y + 14.0 * sc
		canvas.draw_texture_rect(_cloud_tex, Rect2(org.x + shift, cy, cloud_w, cloud_h), false)
		canvas.draw_texture_rect(_cloud_tex, Rect2(org.x + shift - cloud_w, cy, cloud_w, cloud_h), false)

	# Occasional distant emerald dragon glide high across dusk horizon
	var sky_cycle: float = fmod(_anim_t, 18.0)
	if sky_cycle < 11.0:
		var u: float = sky_cycle / 11.0
		var vtex := _virelai_1_tex if (int(_anim_t * 3.4) % 2 == 1) else _virelai_0_tex
		if vtex != null:
			var vx: float = lerpf(325.0, -40.0, u)
			var vy: float = 42.0 - sin(u * PI) * 8.0
			var vr := Rect2(org + Vector2(vx, vy) * sc, Vector2(36.0 * sc, 18.0 * sc))
			var vcol := Color(1, 1, 1, sin(u * PI) * 0.85)
			canvas.draw_texture_rect(vtex, Rect2(Vector2(vr.position.x + vr.size.x, vr.position.y), Vector2(-vr.size.x, vr.size.y)), false, vcol)

	# Gentle animated golden ripples over still estuary water
	for row_i in range(9):
		var wy: float = 116.0 + float(row_i) * 5.2
		var half_w: float = 7.0 + float(row_i) * 1.9
		var drift: float = sin(_anim_t * 1.15 + float(row_i) * 1.3) * 2.2
		var rx: float = (198.0 - half_w * 0.5 + drift) * sc + org.x
		var ry: float = wy * sc + org.y
		var a: float = (0.48 - float(row_i) * 0.045) * (0.7 + 0.3 * cos(_anim_t * 1.8 + float(row_i)))
		canvas.draw_rect(Rect2(rx, ry, half_w * sc, maxf(1.0, sc * 0.75)), Color(0.96, 0.78, 0.42, maxf(0.0, a)))

	# Quiet foreground moss headland, hooded Boy, cracked Prophecy Egg & lantern
	if _fg_tex != null:
		canvas.draw_texture_rect(_fg_tex, full_rect, false)

	# Soft warm hearth lantern halo beside Boy
	var lan_flicker: float = 0.85 + 0.15 * sin(_anim_t * 4.2) + 0.08 * cos(_anim_t * 9.5)
	var lan_c: Vector2 = org + Vector2(43.0, 107.0) * sc
	canvas.draw_circle(lan_c, 11.0 * sc * lan_flicker, Color(0.98, 0.72, 0.30, 0.14))
	canvas.draw_circle(lan_c, 5.5 * sc * lan_flicker, Color(1.0, 0.88, 0.54, 0.24))

	# Perched Stage-1 Hatchling gently breathing / fluttering in dawn backlight
	var roost_tex := _roost_1_tex if fmod(_anim_t, 3.2) > 2.2 else _roost_0_tex
	if roost_tex != null:
		canvas.draw_texture_rect(roost_tex, Rect2(org + Vector2(82.0, 102.0) * sc, Vector2(28.0, 24.0) * sc), false)

	# Sparse drifting golden ember / scale motes rising toward twilight sky
	for em in EMBER_SEEDS:
		var life: float = fmod(_anim_t * 0.22 + float(em["ph"]), 1.0)
		var ex: float = float(em["x"]) + sin(_anim_t * 1.5 + float(em["ph"]) * 4.0) * 3.5
		var ey: float = float(em["y"]) - life * (float(em["spd"]) * 4.0)
		var ea: float = sin(life * PI) * 0.72
		canvas.draw_rect(Rect2(org + Vector2(ex, ey) * sc, Vector2(sc, sc)), Color(0.98, 0.84, 0.42, ea))

	# Smooth multi-step bottom vignette keeping lower menu text legible without hard seams
	const V_STEPS := 18
	var band_top: float = sz.y * 0.54
	var band_h: float = sz.y - band_top
	var step_h: float = band_h / float(V_STEPS) + 1.0
	for s_i in range(V_STEPS):
		var u: float = float(s_i + 1) / float(V_STEPS)
		var sy: float = band_top + float(s_i) * (band_h / float(V_STEPS))
		var alpha: float = u * u * 0.56
		canvas.draw_rect(Rect2(0.0, sy, sz.x, step_h), Color(0.025, 0.032, 0.058, alpha))


func apply_post_theme_fixes() -> void:
	# Strip box buttons on the open Zelda main menu so choices float serenely with wing cursors
	var empty_sb := StyleBoxEmpty.new()
	empty_sb.content_margin_left = 10
	empty_sb.content_margin_right = 10

	for btn in _menu_btns:
		if btn == null:
			continue
		btn.add_theme_stylebox_override("normal", empty_sb)
		btn.add_theme_stylebox_override("hover", empty_sb)
		btn.add_theme_stylebox_override("focus", empty_sb)
		btn.add_theme_stylebox_override("pressed", empty_sb)
		btn.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 0.96))
		btn.add_theme_constant_override("outline_size", 5)
	_sync_cursor_visuals()

	if name_input != null:
		var inp_sb := StyleBoxFlat.new()
		inp_sb.bg_color = Color(0.08, 0.07, 0.11, 0.94)
		inp_sb.border_color = Color(0.74, 0.58, 0.26, 0.92)
		inp_sb.set_border_width_all(2)
		inp_sb.set_corner_radius_all(3)
		inp_sb.content_margin_left = 10
		inp_sb.content_margin_right = 10
		name_input.add_theme_stylebox_override("normal", inp_sb)
		name_input.add_theme_stylebox_override("focus", inp_sb)
		name_input.add_theme_color_override("font_color", Color(0.98, 0.93, 0.80))
		name_input.add_theme_color_override("font_selected_color", Color(1.0, 0.96, 0.78))
		name_input.add_theme_color_override("selection_color", Color(0.76, 0.56, 0.18, 0.45))
		name_input.add_theme_color_override("caret_color", Color(1.0, 0.90, 0.52))


func show_main_menu() -> void:
	if _menu_box != null:
		_menu_box.visible = true
	if _name_wrap != null:
		_name_wrap.visible = false
	_reveal_t = 0.0
	_selected_idx = 0
	_sync_cursor_visuals()
	if _start_btn != null and is_inside_tree():
		_start_btn.call_deferred("grab_focus")


func show_name_entry() -> void:
	if _menu_box != null:
		_menu_box.visible = false
	if _name_wrap != null:
		_name_wrap.visible = true
	if name_input != null and is_inside_tree():
		name_input.call_deferred("grab_focus")
		name_input.call_deferred("select_all")


func is_name_entry_visible() -> bool:
	return _name_wrap != null and _name_wrap.visible


func refresh_status() -> void:
	# Intentionally serene without clutter text; playtest & settings retain their own buttons/hotkeys.
	pass


func _submit_name(raw_name: String) -> void:
	var chosen := raw_name.strip_edges()
	if chosen == "":
		chosen = "Bram"
	emit_signal("start_game_requested", chosen)
