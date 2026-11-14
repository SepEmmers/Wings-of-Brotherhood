extends Control

## Dedicated modal screen for Combat/Fatal Defeat ("YOU DIED") and Stealth/Objective
## Compromise ("MISSION FAILED"), letting the player retry cleanly from their checkpoint.

var assets
var is_death_mode: bool = true

var bg_rect: ColorRect
var card_panel: PanelContainer
var top_rule: ColorRect
var bot_rule: ColorRect
var badge_rect: TextureRect
var header_lbl: Label
var sub_lbl: Label
var reason_lbl: Label
var retry_btn: Button
var jump_btn: Button

var pending_retry_cb: Callable = Callable()
var on_open_playtest_cb: Callable = Callable()
var on_modal_changed_cb: Callable = Callable()


func setup(assets_ref, playtest_cb: Callable, modal_cb: Callable) -> void:
	assets = assets_ref
	on_open_playtest_cb = playtest_cb
	on_modal_changed_cb = modal_cb
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 60
	visible = false

	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.14, 0.02, 0.03, 0.88)
	add_child(bg_rect)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(660, 350)
	if assets != null:
		assets.style_parchment_panel(card_panel)
	center.add_child(card_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	card_panel.add_child(vbox)

	top_rule = ColorRect.new()
	top_rule.custom_minimum_size = Vector2(0, 3)
	top_rule.color = Color(0.84, 0.20, 0.20, 0.90)
	vbox.add_child(top_rule)

	badge_rect = TextureRect.new()
	badge_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	badge_rect.custom_minimum_size = Vector2(48, 48)
	badge_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(badge_rect)

	header_lbl = Label.new()
	header_lbl.text = "YOU DIED"
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.add_theme_font_size_override("font_size", 34)
	header_lbl.add_theme_color_override("font_color", Color(0.96, 0.24, 0.22))
	vbox.add_child(header_lbl)

	sub_lbl = Label.new()
	sub_lbl.text = "— YOUR JOURNEY FALTERS —"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(0.86, 0.64, 0.60))
	vbox.add_child(sub_lbl)

	reason_lbl = Label.new()
	reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason_lbl.custom_minimum_size = Vector2(560, 60)
	reason_lbl.add_theme_font_size_override("font_size", 16)
	reason_lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.84))
	vbox.add_child(reason_lbl)

	bot_rule = ColorRect.new()
	bot_rule.custom_minimum_size = Vector2(0, 2)
	bot_rule.color = Color(0.84, 0.20, 0.20, 0.70)
	vbox.add_child(bot_rule)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	retry_btn = Button.new()
	retry_btn.text = "Retry From Checkpoint [E / Space]"
	retry_btn.custom_minimum_size = Vector2(280, 44)
	retry_btn.pressed.connect(_on_retry_pressed)
	btn_row.add_child(retry_btn)

	jump_btn = Button.new()
	jump_btn.text = "Scene / Act Jump [F1]"
	jump_btn.custom_minimum_size = Vector2(210, 44)
	jump_btn.pressed.connect(_on_jump_pressed)
	btn_row.add_child(jump_btn)


func show_death(cause_text: String, on_retry: Callable = Callable()) -> void:
	is_death_mode = true
	pending_retry_cb = on_retry
	bg_rect.color = Color(0.14, 0.02, 0.03, 0.88)
	top_rule.color = Color(0.84, 0.18, 0.18, 0.92)
	bot_rule.color = Color(0.84, 0.18, 0.18, 0.72)
	header_lbl.text = "YOU DIED"
	header_lbl.add_theme_color_override("font_color", Color(0.96, 0.24, 0.22))
	sub_lbl.text = "— FALLEN IN FLANDERS —"
	sub_lbl.add_theme_color_override("font_color", Color(0.86, 0.64, 0.60))
	reason_lbl.text = cause_text if cause_text.strip_edges() != "" else "Your strength gave out before reaching safety."
	retry_btn.text = "Retry From Checkpoint [E / Space]"
	if assets != null:
		badge_rect.texture = assets.get_tex("ui_wax_seal.png")
	visible = true
	retry_btn.grab_focus()
	if on_modal_changed_cb.is_valid():
		on_modal_changed_cb.call()


func show_mission_failed(reason_text: String, on_retry: Callable = Callable()) -> void:
	is_death_mode = false
	pending_retry_cb = on_retry
	bg_rect.color = Color(0.08, 0.06, 0.04, 0.85)
	top_rule.color = Color(0.92, 0.62, 0.20, 0.92)
	bot_rule.color = Color(0.92, 0.62, 0.20, 0.72)
	header_lbl.text = "MISSION FAILED"
	header_lbl.add_theme_color_override("font_color", Color(0.98, 0.74, 0.26))
	sub_lbl.text = "— OBJECTIVE COMPROMISED —"
	sub_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.62))
	reason_lbl.text = reason_text if reason_text.strip_edges() != "" else "Your cover was blown before completing the objective."
	retry_btn.text = "Retry Objective [E / Space]"
	if assets != null:
		badge_rect.texture = assets.get_tex("icon_compass.png")
	visible = true
	retry_btn.grab_focus()
	if on_modal_changed_cb.is_valid():
		on_modal_changed_cb.call()


func trigger_retry() -> bool:
	if not visible:
		return false
	visible = false
	var cb := pending_retry_cb
	pending_retry_cb = Callable()
	if cb.is_valid():
		cb.call()
	if on_modal_changed_cb.is_valid():
		on_modal_changed_cb.call()
	return true


func _on_retry_pressed() -> void:
	SoundManager.play_ui_click()
	trigger_retry()


func _on_jump_pressed() -> void:
	SoundManager.play_ui_click()
	visible = false
	pending_retry_cb = Callable()
	if on_modal_changed_cb.is_valid():
		on_modal_changed_cb.call()
	if on_open_playtest_cb.is_valid():
		on_open_playtest_cb.call()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var ui_parent := get_parent()
	if ui_parent != null and "playtest_panel" in ui_parent and ui_parent.playtest_panel != null and ui_parent.playtest_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.physical_keycode
		if kc == KEY_E or kc == KEY_SPACE or kc == KEY_ENTER:
			get_viewport().set_input_as_handled()
			_on_retry_pressed()
