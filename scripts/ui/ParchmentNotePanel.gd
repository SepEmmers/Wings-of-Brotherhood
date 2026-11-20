class_name ParchmentNotePanel
extends Control

## Aged-vellum diegetic document modal for physical notes, harbor boards, writs,
## abbey decrees, and letters (words appear on real in-world written artifacts).

var assets = null
var _panel: PanelContainer
var _title_lbl: Label
var _body_lbl: RichTextLabel
var _sig_lbl: Label
var _close_hint_lbl: Label
var _wax_seal: TextureRect
var _on_close_cb: Callable = Callable()


func setup(p_assets) -> void:
	assets = p_assets
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.02, 0.04, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 340)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb: StyleBox = assets.make_ui_9slice_style("ui_parchment_note_9slice.png", 18.0, 26.0, 24.0) if assets != null else null
	if sb != null:
		_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vb)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 10)
	head_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(head_row)

	var quill_icon := TextureRect.new()
	quill_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	quill_icon.custom_minimum_size = Vector2(28, 28)
	quill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if assets != null:
		quill_icon.texture = assets.get_tex("prop_dropped_note.png", "icon_strap.png")
	head_row.add_child(quill_icon)

	_title_lbl = Label.new()
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_title_lbl.add_theme_font_size_override("font_size", 20)
	_title_lbl.add_theme_color_override("font_color", Color(0.32, 0.14, 0.08))
	head_row.add_child(_title_lbl)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(0.48, 0.34, 0.20, 0.65)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(rule)

	_body_lbl = RichTextLabel.new()
	_body_lbl.bbcode_enabled = true
	_body_lbl.fit_content = false
	_body_lbl.scroll_following = false
	_body_lbl.custom_minimum_size = Vector2(492, 188)
	_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_body_lbl.add_theme_font_size_override("normal_font_size", 15)
	_body_lbl.add_theme_font_size_override("bold_font_size", 16)
	_body_lbl.add_theme_font_size_override("italics_font_size", 15)
	_body_lbl.add_theme_color_override("default_color", Color(0.18, 0.12, 0.08))
	vb.add_child(_body_lbl)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(foot)

	_wax_seal = TextureRect.new()
	_wax_seal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wax_seal.custom_minimum_size = Vector2(36, 36)
	_wax_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if assets != null:
		_wax_seal.texture = assets.get_tex("ui_wax_seal.png")
	foot.add_child(_wax_seal)

	_sig_lbl = Label.new()
	_sig_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sig_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sig_lbl.add_theme_font_size_override("font_size", 13)
	_sig_lbl.add_theme_color_override("font_color", Color(0.46, 0.15, 0.11))
	foot.add_child(_sig_lbl)

	var close_btn := Button.new()
	close_btn.text = "Put Away [E]"
	close_btn.custom_minimum_size = Vector2(138, 34)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(dismiss)
	foot.add_child(close_btn)


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dismiss()


func show_note(title: String, body_text: String, signature: String = "", on_close: Callable = Callable()) -> void:
	_title_lbl.text = title
	_body_lbl.text = body_text
	_sig_lbl.text = signature
	_sig_lbl.visible = not signature.is_empty()
	_wax_seal.visible = not signature.is_empty()
	_on_close_cb = on_close
	visible = true
	SoundManager.play_blip(0.92)


func dismiss() -> void:
	if not visible:
		return
	visible = false
	SoundManager.play_ui_click()
	var cb := _on_close_cb
	_on_close_cb = Callable()
	if cb.is_valid():
		cb.call()
