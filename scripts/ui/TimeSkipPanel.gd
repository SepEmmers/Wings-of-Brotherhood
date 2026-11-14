extends ColorRect

## Non-blocking floating era stamp overlay for animated time-skip montage shots (Age 12 -> 14 -> 17).

signal dismissed

var stamp_box: PanelContainer
var era_lbl: Label
var sub_lbl: Label
var stamp_timer: float = 0.0
var stamp_duration: float = 0.0
var stamp_active: bool = false
var continue_cb: Callable


func setup(assets_ref) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = Color(0.0, 0.0, 0.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	stamp_box = PanelContainer.new()
	stamp_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	stamp_box.offset_left = -310
	stamp_box.offset_right = 310
	stamp_box.offset_top = 64
	stamp_box.offset_bottom = 148
	stamp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.06, 0.08, 0.13, 0.86)
	panel_sb.border_color = Color(0.84, 0.68, 0.34, 0.94)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(5)
	panel_sb.content_margin_left = 20
	panel_sb.content_margin_right = 20
	panel_sb.content_margin_top = 10
	panel_sb.content_margin_bottom = 10
	stamp_box.add_theme_stylebox_override("panel", panel_sb)
	add_child(stamp_box)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_box.add_child(hbox)

	var seal_tex: Texture2D = assets_ref.get_tex("icon_compass.png")
	if seal_tex != null:
		var seal := TextureRect.new()
		seal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		seal.custom_minimum_size = Vector2(36, 36)
		seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		seal.texture = seal_tex
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(seal)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	era_lbl = Label.new()
	era_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	era_lbl.add_theme_font_size_override("font_size", 20)
	era_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.48))
	era_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(era_lbl)

	sub_lbl = Label.new()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.68, 0.86, 0.78))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_lbl)


func show_stamp(era_title: String, sub_title: String, duration: float = 2.4) -> void:
	era_lbl.text = era_title
	sub_lbl.text = sub_title
	sub_lbl.visible = sub_title != ""
	stamp_timer = 0.0
	stamp_duration = maxf(0.4, duration)
	stamp_active = true
	continue_cb = Callable()
	visible = true
	if stamp_box != null:
		stamp_box.modulate.a = 0.0


func hide_stamp() -> void:
	stamp_active = false
	visible = false


func process_stamp(delta: float) -> void:
	if not stamp_active or not visible:
		return
	stamp_timer += delta
	var alpha := 1.0
	if stamp_timer < 0.42:
		var t_in := clampf(stamp_timer / 0.42, 0.0, 1.0)
		alpha = t_in * t_in * (3.0 - 2.0 * t_in)
	elif stamp_duration > 0.55 and stamp_timer > stamp_duration - 0.50:
		var t_out := clampf((stamp_duration - stamp_timer) / 0.50, 0.0, 1.0)
		alpha = t_out * t_out * (3.0 - 2.0 * t_out)
	if stamp_box != null:
		stamp_box.modulate.a = alpha
	if stamp_timer >= stamp_duration:
		hide_stamp()


func show_card(era_title: String, sub_title: String, _chronicle_text: String, on_continue: Callable = Callable()) -> void:
	show_stamp(era_title, sub_title, 2.2)
	continue_cb = on_continue


func dismiss() -> void:
	if not visible:
		return
	hide_stamp()
	var cb := continue_cb
	continue_cb = Callable()
	emit_signal("dismissed")
	if cb.is_valid():
		cb.call()
