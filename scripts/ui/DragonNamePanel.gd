extends PanelContainer
class_name DragonNamePanel

## Compact parchment modal for naming the Golden Hatchling upon emergence
## in Brabant Fens. Preserves GameUI.gd modularity under scripts/ui/.

signal name_confirmed(chosen_name: String)

var _name_input: LineEdit
var _on_done: Callable = Callable()


func setup(assets_ref) -> void:
	visible = false
	custom_minimum_size = Vector2(460, 270)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -230
	offset_top = -135
	offset_right = 230
	offset_bottom = 135
	if assets_ref != null:
		assets_ref.style_parchment_panel(self)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	vb.add_child(hdr)

	var portrait := TextureRect.new()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if assets_ref != null:
		portrait.texture = assets_ref.get_tex("portrait_hatchling_stage1.png")
	hdr.add_child(portrait)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	hdr.add_child(title_box)

	var title_lbl := Label.new()
	title_lbl.text = "A GOLDEN HEIR AWAKENS"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.44))
	title_box.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.text = "Soot-black scales warm with living royal-gold seams press against your palm. Name the hatchling that will fly at your side:"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	title_box.add_child(sub_lbl)

	_name_input = LineEdit.new()
	_name_input.text = "Aurelius"
	_name_input.placeholder_text = "Enter hatchling name..."
	_name_input.max_length = 22
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.add_theme_font_size_override("font_size", 16)
	_name_input.text_submitted.connect(func(_txt: String): _confirm())
	vb.add_child(_name_input)

	var quick_row := HBoxContainer.new()
	quick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	quick_row.add_theme_constant_override("separation", 6)
	vb.add_child(quick_row)

	for preset_nm in ["Aurelius", "Orin", "Saffra", "Vesper"]:
		var qbtn := Button.new()
		qbtn.text = preset_nm
		qbtn.custom_minimum_size = Vector2(88, 26)
		var captured: String = preset_nm
		qbtn.pressed.connect(func():
			SoundManager.play_ui_click()
			if _name_input != null:
				_name_input.text = captured
		)
		quick_row.add_child(qbtn)

	var ok_btn := Button.new()
	ok_btn.text = "Bind Name & Rise"
	ok_btn.custom_minimum_size = Vector2(0, 36)
	ok_btn.pressed.connect(_confirm)
	vb.add_child(ok_btn)


func open_prompt(on_done: Callable = Callable()) -> void:
	_on_done = on_done
	if _name_input != null:
		if GameState.gold_dragon_name != "" and GameState.gold_dragon_name != "Golden Hatchling":
			_name_input.text = GameState.gold_dragon_name
		else:
			_name_input.text = "Aurelius"
	visible = true
	if _name_input != null:
		_name_input.grab_focus()
		_name_input.select_all()


func _confirm() -> void:
	SoundManager.play_chime()
	var chosen := _name_input.text.strip_edges() if _name_input != null else "Aurelius"
	if chosen.is_empty():
		chosen = "Aurelius"
	GameState.gold_dragon_name = chosen
	GameState.emit_signal("state_updated")
	visible = false
	var cb := _on_done
	_on_done = Callable()
	emit_signal("name_confirmed", chosen)
	if cb.is_valid():
		cb.call(chosen)
