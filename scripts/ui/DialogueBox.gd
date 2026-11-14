extends PanelContainer

## Bottom portrait dialogue box with character-specific voice blips and typewriter reveal.

signal dialogue_completed

var assets
var portrait_frame: PanelContainer
var portrait_rect: TextureRect
var speaker_label: Label
var dialogue_label: Label
var continue_hint: Label

var _default_panel_sb: StyleBox
var _telepathic_panel_sb: StyleBoxFlat
var _default_portrait_sb: StyleBox
var _telepathic_portrait_sb: StyleBoxFlat
var _line_telepathic: bool = false
var _telepathy_pulse_t: float = 0.0

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
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 100
	offset_right = -100
	offset_top = -178
	offset_bottom = -20
	visible = false
	assets.style_parchment_panel(self)
	_default_panel_sb = get_theme_stylebox("panel")

	_telepathic_panel_sb = StyleBoxFlat.new()
	_telepathic_panel_sb.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	_telepathic_panel_sb.border_color = Color(0.95, 0.78, 0.28, 0.98)
	_telepathic_panel_sb.set_border_width_all(3)
	_telepathic_panel_sb.set_corner_radius_all(5)
	_telepathic_panel_sb.content_margin_left = 14
	_telepathic_panel_sb.content_margin_right = 14
	_telepathic_panel_sb.content_margin_top = 12
	_telepathic_panel_sb.content_margin_bottom = 12

	var dlg_hbox := HBoxContainer.new()
	dlg_hbox.add_theme_constant_override("separation", 16)
	add_child(dlg_hbox)

	portrait_frame = PanelContainer.new()
	portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_default_portrait_sb = assets.make_ui_9slice_style("ui_frame_portrait.png", 6.0, 8.0, 8.0)
	_telepathic_portrait_sb = StyleBoxFlat.new()
	_telepathic_portrait_sb.bg_color = Color(0.11, 0.09, 0.06, 0.98)
	_telepathic_portrait_sb.border_color = Color(0.98, 0.84, 0.36, 1.0)
	_telepathic_portrait_sb.set_border_width_all(2)
	_telepathic_portrait_sb.set_corner_radius_all(3)
	_telepathic_portrait_sb.content_margin_left = 8
	_telepathic_portrait_sb.content_margin_right = 8
	_telepathic_portrait_sb.content_margin_top = 8
	_telepathic_portrait_sb.content_margin_bottom = 8
	portrait_frame.add_theme_stylebox_override("panel", _default_portrait_sb)
	dlg_hbox.add_child(portrait_frame)

	portrait_rect = TextureRect.new()
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.custom_minimum_size = Vector2(96, 96)
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait_rect)

	var dlg_box := VBoxContainer.new()
	dlg_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_box.add_theme_constant_override("separation", 6)
	dlg_hbox.add_child(dlg_box)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 16)
	speaker_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.45))
	dlg_box.add_child(speaker_label)

	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(0, 74)
	dialogue_label.add_theme_font_size_override("font_size", 15)
	dialogue_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
	dlg_box.add_child(dialogue_label)

	continue_hint = Label.new()
	continue_hint.text = "[E / Space / Enter] Continue"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.add_theme_font_size_override("font_size", 12)
	continue_hint.add_theme_color_override("font_color", Color(0.74, 0.72, 0.65))
	dlg_box.add_child(continue_hint)


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
		emit_signal("dialogue_completed")
		if dialogue_on_complete.is_valid():
			var cb := dialogue_on_complete
			dialogue_on_complete = Callable()
			cb.call()


func process_typewriter(delta: float) -> void:
	if not dialogue_active:
		return
	if _line_telepathic and _telepathic_panel_sb != null:
		_telepathy_pulse_t += delta
		var g := 0.5 + 0.5 * sin(_telepathy_pulse_t * 4.2)
		_telepathic_panel_sb.border_color = Color(0.92 + 0.08 * g, 0.74 + 0.14 * g, 0.24 + 0.16 * g, 0.98)
	if dialogue_visible_chars < dialogue_full_text.length():
		var prev_chars := int(dialogue_visible_chars)
		dialogue_visible_chars = minf(dialogue_full_text.length(), dialogue_visible_chars + delta * 62.0)
		var cur_chars := int(dialogue_visible_chars)
		dialogue_label.text = dialogue_full_text.substr(0, cur_chars)
		var cadence := 5 if _line_telepathic else 3
		if cur_chars > prev_chars and cur_chars % cadence == 0:
			SoundManager.play_voice_blip(current_voice_kind, current_voice_pitch)
	continue_hint.visible = int(dialogue_visible_chars) >= dialogue_full_text.length()


func _load_current_line() -> void:
	var entry: Dictionary = dialogue_queue[dialogue_index]
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
	_apply_line_visual_mode()
	current_voice_pitch = 1.16 if _line_telepathic else _voice_pitch_for(spk)
	current_voice_kind = "dragon" if _line_telepathic else _voice_kind_for(spk)
	if _line_telepathic:
		SoundManager.play_chime()
	dialogue_full_text = entry.get("text", "")
	dialogue_visible_chars = 0.0
	dialogue_label.text = ""
	continue_hint.visible = false


func _apply_line_visual_mode() -> void:
	if _line_telepathic:
		if _telepathic_panel_sb != null:
			add_theme_stylebox_override("panel", _telepathic_panel_sb)
		if portrait_frame != null and _telepathic_portrait_sb != null:
			portrait_frame.add_theme_stylebox_override("panel", _telepathic_portrait_sb)
		speaker_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
		dialogue_label.add_theme_color_override("font_color", Color(0.99, 0.94, 0.78))
		continue_hint.add_theme_color_override("font_color", Color(0.86, 0.76, 0.48))
	else:
		if _default_panel_sb != null:
			add_theme_stylebox_override("panel", _default_panel_sb)
		if portrait_frame != null and _default_portrait_sb != null:
			portrait_frame.add_theme_stylebox_override("panel", _default_portrait_sb)
		speaker_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.45))
		dialogue_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
		continue_hint.add_theme_color_override("font_color", Color(0.74, 0.72, 0.65))


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
