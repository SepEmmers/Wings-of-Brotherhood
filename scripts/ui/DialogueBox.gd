extends PanelContainer

## Compact stylized medieval portrait dialogue box with ethereal Mind-Voice dream overlay.

signal dialogue_completed

const DialogueOverridesScript := preload("res://scripts/data/DialogueOverrides.gd")

const MIND_MOTES := [
	{"x": 0.14, "y": 0.84, "ph": 0.07, "sp": 0.16, "col": 0},
	{"x": 0.22, "y": 0.72, "ph": 0.31, "sp": 0.14, "col": 1},
	{"x": 0.34, "y": 0.88, "ph": 0.56, "sp": 0.19, "col": 0},
	{"x": 0.48, "y": 0.78, "ph": 0.18, "sp": 0.13, "col": 2},
	{"x": 0.61, "y": 0.86, "ph": 0.74, "sp": 0.17, "col": 0},
	{"x": 0.72, "y": 0.74, "ph": 0.42, "sp": 0.15, "col": 1},
	{"x": 0.84, "y": 0.84, "ph": 0.88, "sp": 0.18, "col": 0},
	{"x": 0.91, "y": 0.68, "ph": 0.62, "sp": 0.14, "col": 2},
	{"x": 0.28, "y": 0.62, "ph": 0.93, "sp": 0.12, "col": 1},
	{"x": 0.54, "y": 0.65, "ph": 0.49, "sp": 0.16, "col": 0},
	{"x": 0.78, "y": 0.60, "ph": 0.23, "sp": 0.13, "col": 2},
]

var assets
var portrait_frame: PanelContainer
var portrait_rect: TextureRect
var speaker_label: Label
var dialogue_label: Label
var continue_hint: Label
var _header_rule: ColorRect
var _fx_layer: Control

var _default_panel_sb: StyleBox
var _telepathic_panel_sb: StyleBox
var _default_portrait_sb: StyleBox
var _telepathic_portrait_sb: StyleBox
var _line_telepathic: bool = false
var _telepathy_pulse_t: float = 0.0
var _portrait_open_tex: Texture2D = null
var _portrait_blink_tex: Texture2D = null
var _portrait_bounce_t: float = 0.0
var _blink_wait_t: float = 0.0
var _blink_active_t: float = 0.0
var _blink_cycle: int = 0

var dialogue_active: bool = false
var dialogue_queue: Array = []
var dialogue_index: int = 0
var dialogue_full_text: String = ""
var dialogue_visible_chars: float = 0.0
var current_voice_pitch: float = 1.0
var current_voice_kind: String = "boy"
var dialogue_on_complete: Callable


func setup(assets_ref) -> void:
	assets = assets_ref
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_apply_box_bounds(false)
	visible = false

	_default_panel_sb = _make_chrome_style("ui_dialogue_9slice.png", 10.0, 18.0, 14.0, Color(0.09, 0.08, 0.11, 0.95), Color(0.76, 0.58, 0.28, 0.96))
	_telepathic_panel_sb = _make_chrome_style("ui_mind_dialogue_9slice.png", 10.0, 18.0, 14.0, Color(0.10, 0.09, 0.20, 0.92), Color(0.95, 0.80, 0.42, 0.96))
	add_theme_stylebox_override("panel", _default_panel_sb)

	_fx_layer = Control.new()
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.clip_contents = true
	_fx_layer.draw.connect(_draw_fx_layer)
	add_child(_fx_layer)

	var dlg_hbox := HBoxContainer.new()
	dlg_hbox.add_theme_constant_override("separation", 16)
	add_child(dlg_hbox)

	portrait_frame = PanelContainer.new()
	portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_default_portrait_sb = _make_chrome_style("ui_dialogue_portrait_9slice.png", 6.0, 7.0, 7.0, Color(0.08, 0.07, 0.10, 0.98), Color(0.72, 0.54, 0.26, 0.98))
	_telepathic_portrait_sb = _make_chrome_style("ui_mind_portrait_9slice.png", 6.0, 7.0, 7.0, Color(0.12, 0.10, 0.24, 0.96), Color(0.96, 0.84, 0.46, 0.98))
	portrait_frame.add_theme_stylebox_override("panel", _default_portrait_sb)
	dlg_hbox.add_child(portrait_frame)

	var portrait_slot := Control.new()
	portrait_slot.custom_minimum_size = Vector2(88, 88)
	portrait_slot.clip_contents = true
	portrait_frame.add_child(portrait_slot)

	portrait_rect = TextureRect.new()
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.custom_minimum_size = Vector2(88, 88)
	portrait_rect.size = Vector2(88, 88)
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_slot.add_child(portrait_rect)

	var dlg_box := VBoxContainer.new()
	dlg_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_box.add_theme_constant_override("separation", 5)
	dlg_hbox.add_child(dlg_box)

	speaker_label = Label.new()
	speaker_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	speaker_label.add_theme_font_size_override("font_size", 16)
	speaker_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.46))
	speaker_label.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.05, 0.92))
	speaker_label.add_theme_constant_override("shadow_offset_x", 1)
	speaker_label.add_theme_constant_override("shadow_offset_y", 2)
	dlg_box.add_child(speaker_label)

	_header_rule = ColorRect.new()
	_header_rule.custom_minimum_size = Vector2(0, 1)
	_header_rule.color = Color(0.76, 0.62, 0.34, 0.45)
	dlg_box.add_child(_header_rule)

	dialogue_label = Label.new()
	dialogue_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(0, 54)
	dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.add_theme_font_size_override("font_size", 15)
	dialogue_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
	dialogue_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, 0.88))
	dialogue_label.add_theme_constant_override("shadow_offset_x", 1)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 2)
	dlg_box.add_child(dialogue_label)

	continue_hint = Label.new()
	continue_hint.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	continue_hint.text = "[E / Space] Continue"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.add_theme_font_size_override("font_size", 11)
	continue_hint.add_theme_color_override("font_color", Color(0.76, 0.72, 0.64))
	continue_hint.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, 0.85))
	continue_hint.add_theme_constant_override("shadow_offset_x", 1)
	continue_hint.add_theme_constant_override("shadow_offset_y", 2)
	dlg_box.add_child(continue_hint)


func _make_chrome_style(tex_name: String, m: float, ph: float, pv: float, fb_bg: Color, fb_bd: Color) -> StyleBox:
	if assets != null and assets.tex.has(tex_name):
		return assets.make_ui_9slice_style(tex_name, m, ph, pv)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fb_bg
	sb.border_color = fb_bd
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = ph
	sb.content_margin_right = ph
	sb.content_margin_top = pv
	sb.content_margin_bottom = pv
	return sb


func _apply_box_bounds(telepathic: bool, text_str: String = "") -> void:
	var half_w := 335.0 if telepathic else 350.0
	var bot_pad := -28.0 if telepathic else -26.0
	var min_h := 146.0 if telepathic else 140.0
	var needed_text_h := 58.0
	if not text_str.is_empty() and dialogue_label != null:
		var ui_font: Font = dialogue_label.get_theme_font("font")
		if ui_font != null:
			var avail_w := (half_w * 2.0) - 166.0
			var sz := ui_font.get_multiline_string_size(text_str, HORIZONTAL_ALIGNMENT_LEFT, avail_w, 15)
			needed_text_h = maxf(58.0, ceilf(sz.y) + 8.0)
	var box_h := clampf(88.0 + needed_text_h, min_h, 240.0)
	offset_left = -half_w
	offset_right = half_w
	offset_top = bot_pad - box_h
	offset_bottom = bot_pad


func show_dialogue(lines: Array, on_done: Callable = Callable()) -> void:
	if lines.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	dialogue_queue = lines.duplicate()
	dialogue_index = 0
	dialogue_on_complete = on_done
	dialogue_active = true
	visible = true
	_load_current_line()


func hide_box() -> void:
	visible = false
	dialogue_active = false
	dialogue_on_complete = Callable()
	_portrait_blink_tex = null
	_portrait_bounce_t = 0.0
	_blink_active_t = 0.0
	if portrait_rect != null:
		portrait_rect.position = Vector2.ZERO


func advance() -> void:
	if not dialogue_active:
		return
	if dialogue_visible_chars < dialogue_full_text.length():
		dialogue_visible_chars = dialogue_full_text.length()
		dialogue_label.text = dialogue_full_text
		continue_hint.visible = true
		return
	dialogue_index += 1
	if dialogue_index < dialogue_queue.size():
		_load_current_line()
	else:
		dialogue_active = false
		visible = false
		_portrait_blink_tex = null
		if portrait_rect != null:
			portrait_rect.position = Vector2.ZERO
		emit_signal("dialogue_completed")
		if dialogue_on_complete.is_valid():
			var cb := dialogue_on_complete
			dialogue_on_complete = Callable()
			cb.call()


func process_typewriter(delta: float) -> void:
	if not dialogue_active:
		return
	if _line_telepathic:
		_telepathy_pulse_t += delta
		queue_redraw()
		if _fx_layer != null:
			_fx_layer.queue_redraw()
		if _telepathic_panel_sb is StyleBoxFlat:
			var g := 0.5 + 0.5 * sin(_telepathy_pulse_t * 2.8)
			(_telepathic_panel_sb as StyleBoxFlat).border_color = Color(0.92 + 0.08 * g, 0.78 + 0.14 * g, 0.36 + 0.22 * g, 0.96)
	_step_portrait_reaction(delta)
	if dialogue_visible_chars < dialogue_full_text.length():
		var prev_chars := int(dialogue_visible_chars)
		var speed_cps := GameState.get_dialogue_speed_cps()
		dialogue_visible_chars = minf(dialogue_full_text.length(), dialogue_visible_chars + delta * speed_cps)
		var cur_chars := int(dialogue_visible_chars)
		dialogue_label.text = dialogue_full_text.substr(0, cur_chars)
		var cadence := 5 if _line_telepathic else 3
		if cur_chars > prev_chars and cur_chars % cadence == 0:
			SoundManager.play_voice_blip(current_voice_kind, current_voice_pitch)
	continue_hint.visible = (int(dialogue_visible_chars) >= dialogue_full_text.length()) and GameState.control_prompts_enabled
	if continue_hint.visible:
		continue_hint.modulate.a = 0.72 + 0.28 * sin(_telepathy_pulse_t * 3.2) if _line_telepathic else 1.0


func _draw() -> void:
	if not visible:
		return
	if _line_telepathic:
		# Soft exterior feathered dream aura gently framing the Mind-Voice charter
		var breath := 0.5 + 0.5 * sin(_telepathy_pulse_t * 2.0)
		for g_i in range(8):
			var pad := float(g_i + 1) * 2.5
			var falloff := 1.0 - float(g_i) / 8.0
			var a := falloff * falloff * (0.08 + 0.03 * breath)
			var col := Color(0.62, 0.54, 0.98, a) if g_i % 2 == 1 else Color(0.98, 0.86, 0.48, a * 0.85)
			draw_rect(Rect2(Vector2(-pad, -pad), size + Vector2(pad * 2.0, pad * 2.0)), col, false, 3.0)


func _draw_soft_mist(canvas: Control, center: Vector2, rad: float, base_col: Color) -> void:
	const LAYERS := 10
	for li in range(LAYERS):
		var frac := 1.0 - float(li) / float(LAYERS)
		var col := Color(base_col.r, base_col.g, base_col.b, base_col.a * (0.14 + 0.04 * float(li)))
		canvas.draw_circle(center, rad * frac, col)


func _draw_fx_layer() -> void:
	if _fx_layer == null:
		return
	var sz: Vector2 = _fx_layer.size
	if sz.x <= 4.0 or sz.y <= 4.0:
		return

	if not _line_telepathic:
		# Subtle dark inner bevel tint + tiny brass diamond flourish near header end
		_fx_layer.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.02, 0.04, 0.16))
		_fx_layer.draw_rect(Rect2(Vector2(2, 2), sz - Vector2(4, 4)), Color(0.74, 0.58, 0.28, 0.16), false, 1.0)
		return

	var t: float = _telepathy_pulse_t
	var breath: float = 0.5 + 0.5 * sin(t * 2.2)

	# 1. Feathered drifting dream-mist wisps (clipped cleanly inside panel interior, zero hard disc seams)
	var mists := [
		[0.24 + 0.05 * sin(t * 0.7), 0.48 + 0.06 * cos(t * 0.9), 64.0, Color(0.58, 0.48, 0.94, 0.065 + 0.025 * breath)],
		[0.60 + 0.08 * cos(t * 0.6), 0.44 + 0.05 * sin(t * 0.8), 78.0, Color(0.98, 0.84, 0.44, 0.050 + 0.025 * breath)],
		[0.84 - 0.05 * sin(t * 0.5), 0.56 + 0.04 * cos(t * 0.7), 56.0, Color(0.72, 0.64, 0.98, 0.060)],
	]
	for m in mists:
		_draw_soft_mist(_fx_layer, Vector2(sz.x * float(m[0]), sz.y * float(m[1])), float(m[2]), m[3])

	# 2. Concentric softly pulsing Mind-Voice resonance rings radiating behind the dragonet portrait
	var pc := Vector2(48.0, sz.y * 0.5)
	for r_i in range(3):
		var cyc := fmod(t * 0.36 + float(r_i) * 0.33, 1.0)
		var rad := 30.0 + cyc * 30.0
		var ra := sin(cyc * PI) * 0.24
		_fx_layer.draw_arc(pc, rad, 0.0, TAU, 28, Color(0.98, 0.88, 0.52, ra), 1.3)

	# 3. Flowing layered aurora ribbons gliding smoothly across velvet backdrop
	var pts_gold := PackedVector2Array()
	var pts_lav := PackedVector2Array()
	for seg in range(25):
		var u := float(seg) / 24.0
		var px := sz.x * u
		var py1 := sz.y * 0.54 + sin(u * TAU * 1.4 - t * 1.25) * 12.0
		var py2 := sz.y * 0.46 + cos(u * TAU * 1.1 + t * 0.85) * 10.0
		pts_gold.append(Vector2(px, py1))
		pts_lav.append(Vector2(px, py2))
	_fx_layer.draw_polyline(pts_gold, Color(0.98, 0.86, 0.52, 0.07), 7.0)
	_fx_layer.draw_polyline(pts_gold, Color(0.98, 0.90, 0.60, 0.16), 1.8)
	_fx_layer.draw_polyline(pts_lav, Color(0.76, 0.72, 0.98, 0.07), 6.0)
	_fx_layer.draw_polyline(pts_lav, Color(0.84, 0.80, 1.0, 0.14), 1.6)

	# 4. Gentle rising golden & pearl stardust motes + four-point twinkling flares
	for md in MIND_MOTES:
		var life := fmod(t * float(md["sp"]) + float(md["ph"]), 1.0)
		var mx := sz.x * float(md["x"]) + sin(t * 1.3 + float(md["ph"]) * 5.0) * 6.0
		var my := sz.y * float(md["y"]) - life * (sz.y * 0.66)
		var ma := sin(life * PI) * 0.84
		var c_idx := int(md["col"])
		var mcol := Color(1.0, 0.92, 0.56, ma) if c_idx == 0 else (Color(0.86, 0.82, 1.0, ma) if c_idx == 1 else Color(1.0, 0.98, 0.90, ma))
		var r := 1.6 if c_idx == 2 else 1.2
		_fx_layer.draw_circle(Vector2(mx, my), r, mcol)
		if c_idx == 2 and ma > 0.45:
			_fx_layer.draw_line(Vector2(mx - 3.5, my), Vector2(mx + 3.5, my), Color(1.0, 0.96, 0.82, ma * 0.7), 1.0)
			_fx_layer.draw_line(Vector2(mx, my - 3.5), Vector2(mx, my + 3.5), Color(1.0, 0.96, 0.82, ma * 0.7), 1.0)

	# 5. Soft inner auric dream hairline
	_fx_layer.draw_rect(Rect2(Vector2(1, 1), sz - Vector2(2, 2)), Color(0.98, 0.88, 0.58, 0.16 + 0.10 * breath), false, 1.0)


func _load_current_line() -> void:
	var entry: Dictionary = DialogueOverridesScript.apply_line_override(dialogue_queue[dialogue_index])
	var spk: String = entry.get("speaker", "")
	_line_telepathic = bool(entry.get("telepathic", false)) or ("Hatchling" in spk) or ("Golden Dragon" in spk)
	speaker_label.text = ("%s  ✦  Mind-Voice" % spk) if _line_telepathic else spk
	var p_key: String = entry.get("portrait", "portrait_boy_neutral.png")
	if p_key == "portrait_boy_neutral.png":
		p_key = GameState.get_boy_portrait(false)
	elif p_key == "portrait_boy_angry.png":
		p_key = GameState.get_boy_portrait(true)
	elif p_key == "portrait_greyling.png":
		p_key = GameState.get_greyling_portrait()
	elif p_key == "portrait_hatchling.png":
		p_key = GameState.get_hatchling_portrait()
	portrait_rect.texture = assets.get_tex(p_key, "portrait_boy_neutral.png")
	_portrait_open_tex = portrait_rect.texture
	var blink_key := p_key.replace(".png", "_blink.png")
	_portrait_blink_tex = assets.tex.get(blink_key, null) if (assets != null and p_key.ends_with(".png")) else null
	_blink_active_t = 0.0
	_blink_wait_t = 0.34 if _portrait_blink_tex != null else 0.0
	_portrait_bounce_t = 0.26 if (_line_telepathic or _portrait_blink_tex != null) else 0.0
	portrait_rect.position = Vector2.ZERO
	_apply_line_visual_mode()
	current_voice_pitch = 1.16 if _line_telepathic else _voice_pitch_for(spk)
	current_voice_kind = "dragon" if _line_telepathic else _voice_kind_for(spk)
	if _line_telepathic:
		SoundManager.play_chime()
	dialogue_full_text = entry.get("text", "")
	_apply_box_bounds(_line_telepathic, dialogue_full_text)
	dialogue_visible_chars = 0.0
	dialogue_label.text = ""
	continue_hint.visible = false


func _step_portrait_reaction(delta: float) -> void:
	if portrait_rect == null:
		return
	var offset_y := 0.0
	if _portrait_bounce_t > 0.0:
		_portrait_bounce_t = maxf(0.0, _portrait_bounce_t - delta)
		var u := 1.0 - (_portrait_bounce_t / 0.26)
		offset_y -= sin(u * PI) * 4.5
	if _line_telepathic:
		var is_typing := int(dialogue_visible_chars) < dialogue_full_text.length()
		var amp := 0.85 if is_typing else 0.45
		offset_y += sin(_telepathy_pulse_t * 3.8) * amp
	portrait_rect.position = Vector2(0.0, offset_y)

	if _portrait_blink_tex == null or _portrait_open_tex == null:
		return
	if _blink_active_t > 0.0:
		_blink_active_t = maxf(0.0, _blink_active_t - delta)
		if _blink_active_t <= 0.0:
			portrait_rect.texture = _portrait_open_tex
	else:
		_blink_wait_t -= delta
		if _blink_wait_t <= 0.0:
			_blink_active_t = 0.13
			_blink_cycle += 1
			_blink_wait_t = 2.6 + float((_blink_cycle * 7) % 5) * 0.35
			portrait_rect.texture = _portrait_blink_tex


func _apply_line_visual_mode() -> void:
	_apply_box_bounds(_line_telepathic)
	if _line_telepathic:
		if _telepathic_panel_sb != null:
			add_theme_stylebox_override("panel", _telepathic_panel_sb)
		if portrait_frame != null and _telepathic_portrait_sb != null:
			portrait_frame.add_theme_stylebox_override("panel", _telepathic_portrait_sb)
		if _header_rule != null:
			_header_rule.color = Color(0.98, 0.86, 0.52, 0.58)
		speaker_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.56))
		dialogue_label.add_theme_color_override("font_color", Color(0.99, 0.95, 0.86))
		continue_hint.text = "✦ [E / Space] Continue"
		continue_hint.add_theme_color_override("font_color", Color(0.92, 0.84, 0.62))
	else:
		if _default_panel_sb != null:
			add_theme_stylebox_override("panel", _default_panel_sb)
		if portrait_frame != null and _default_portrait_sb != null:
			portrait_frame.add_theme_stylebox_override("panel", _default_portrait_sb)
		if _header_rule != null:
			_header_rule.color = Color(0.76, 0.62, 0.34, 0.45)
		speaker_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.46))
		dialogue_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
		continue_hint.text = "[E / Space] Continue"
		continue_hint.add_theme_color_override("font_color", Color(0.76, 0.72, 0.64))
	if _fx_layer != null:
		_fx_layer.queue_redraw()


func _voice_pitch_for(spk: String) -> float:
	if spk == GameState.player_name:
		if GameState.boy_age >= 17:
			return 1.02
		elif GameState.boy_age >= 14:
			return 1.08
		return 1.15
	if "Clara" in spk: return 1.18
	if "Anna" in spk: return 1.05
	if "Maren" in spk: return 1.08
	if "Matthijs" in spk: return 1.04
	if "Kestrel" in spk or "Greyling" in spk:
		if GameState.boy_age >= 17 or GameState.sanctuary_phase >= 3:
			return 1.04
		if GameState.boy_age >= 14 or GameState.sanctuary_phase >= 2:
			return 1.14
		return 1.24
	if "Inquisitor" in spk or "Rider" in spk or "Watchman" in spk: return 0.92
	if "Uncle" in spk or "Shipmaster" in spk or "Vos" in spk or "Dockhand" in spk or "Hendrick" in spk: return 0.90
	if "Dragon" in spk or "Virelai" in spk: return 0.88
	return 1.0


func _voice_kind_for(spk: String) -> String:
	if spk == GameState.player_name or "Matthijs" in spk: return "boy"
	if "Clara" in spk or "Anna" in spk or "Maren" in spk: return "female"
	if "Inquisitor" in spk or "Rider" in spk or "Watchman" in spk: return "stern"
	if "Uncle" in spk or "Shipmaster" in spk or "Vos" in spk or "Baker" in spk or "Dockhand" in spk or "Hendrick" in spk: return "gruff"
	if "Dragon" in spk or "Virelai" in spk or "Kestrel" in spk or "Greyling" in spk: return "dragon"
	return "boy"
