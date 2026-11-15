extends Control

## Minimal Zelda-like HUD overlay: top-left crimson pixel hearts (+ contextual egg/heat/flight bars),
## and non-overlapping top-right utility slots (companion posture, equipped knot [F], [F1] acts toggle, Menu [Esc]).

signal bag_pressed
signal menu_pressed
signal playtest_pressed

const HEART_ICON_SIZE := Vector2(26, 26)
const SLOT_SIZE := Vector2(38, 38)
const BAR_SIZE := Vector2(118, 10)

var assets
var _hud_wanted: bool = true
var _flight_mode: bool = false
var _flight_status: String = ""
var _hud_t: float = 0.0
var _pulse_timers: Dictionary = {} # { "kind": float }

# Top-left vitals
var _top_left_vbox: VBoxContainer
var _hearts_row: HBoxContainer
var _heart_nodes: Array[TextureRect] = []
var _flight_row: VBoxContainer
var _flight_bar_fill: ColorRect
var _flight_status_lbl: Label
var _egg_row: HBoxContainer
var _egg_bar_fill: ColorRect
var _heat_row: HBoxContainer
var _heat_bar_fill: ColorRect

# Top-right compact Zelda slots & utility buttons (inside HBoxContainer -> zero overlap)
var _top_right_row: HBoxContainer
var _pulse_slot: PanelContainer
var _pulse_icon_rect: TextureRect
var _companion_slot: PanelContainer
var _companion_portrait: TextureRect
var _companion_pip: ColorRect
var _knot_slot: PanelContainer
var _knot_icon_rect: TextureRect
var hud_playtest_btn: Button
var hud_menu_btn: Button

var _full_heart_tex: Texture2D
var _empty_heart_tex: Texture2D
var _slot_style: StyleBoxTexture


func setup(assets_ref) -> void:
	assets = assets_ref
	name = "HudOverlay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_heart_tex = assets.get_tex("icon_heart_full.png")
	_empty_heart_tex = assets.get_tex("icon_heart_empty.png")
	_slot_style = assets.make_ui_9slice_style("ui_zelda_slot_9slice.png", 6.0, 5.0, 5.0)
	_build_top_left_vitals()
	_build_top_right_slots()
	apply_post_theme_fixes()
	refresh_current()


func _build_top_left_vitals() -> void:
	_top_left_vbox = VBoxContainer.new()
	_top_left_vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_left_vbox.offset_left = 18
	_top_left_vbox.offset_top = 14
	_top_left_vbox.offset_right = 280
	_top_left_vbox.offset_bottom = 110
	_top_left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_left_vbox.add_theme_constant_override("separation", 6)
	add_child(_top_left_vbox)

	_hearts_row = HBoxContainer.new()
	_hearts_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hearts_row.add_theme_constant_override("separation", 4)
	_top_left_vbox.add_child(_hearts_row)

	var egg_pack := _make_contextual_bar("icon_egg.png", Color(0.95, 0.62, 0.20), "Dragon Egg Warmth")
	_egg_row = egg_pack["row"]
	_egg_bar_fill = egg_pack["fill"]
	_egg_row.visible = false
	_top_left_vbox.add_child(_egg_row)

	var heat_pack := _make_contextual_bar("icon_brotherhood_emblem.png", Color(0.86, 0.24, 0.22), "Bruges City Alert")
	_heat_row = heat_pack["row"]
	_heat_bar_fill = heat_pack["fill"]
	_heat_row.visible = false
	_top_left_vbox.add_child(_heat_row)

	_flight_row = VBoxContainer.new()
	_flight_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flight_row.add_theme_constant_override("separation", 4)
	_flight_row.visible = false
	_top_left_vbox.add_child(_flight_row)

	var harness_pack := _make_contextual_bar("icon_wing.png", Color(0.92, 0.72, 0.28), "Virelai Saddle Harness")
	_flight_bar_fill = harness_pack["fill"]
	_flight_row.add_child(harness_pack["row"])

	_flight_status_lbl = _make_hud_label("", 12, Color(0.95, 0.90, 0.76))
	_flight_row.add_child(_flight_status_lbl)


func _make_contextual_bar(icon_name: String, fill_col: Color, hint_tip: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	row.tooltip_text = hint_tip

	var icon := TextureRect.new()
	icon.texture = assets.get_tex(icon_name)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var frame := Control.new()
	frame.custom_minimum_size = Vector2(BAR_SIZE.x + 4.0, BAR_SIZE.y + 4.0)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.09, 0.90)
	bg.position = Vector2.ZERO
	bg.size = frame.custom_minimum_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(bg)

	var fill := ColorRect.new()
	fill.color = fill_col
	fill.position = Vector2(2, 2)
	fill.size = BAR_SIZE
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(fill)

	return {"row": row, "fill": fill}


func _build_top_right_slots() -> void:
	_top_right_row = HBoxContainer.new()
	_top_right_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_top_right_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_top_right_row.offset_left = -18
	_top_right_row.offset_top = 14
	_top_right_row.offset_right = -18
	_top_right_row.offset_bottom = 54
	_top_right_row.alignment = BoxContainer.ALIGNMENT_END
	_top_right_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_right_row.add_theme_constant_override("separation", 8)
	add_child(_top_right_row)

	# 1. Timed item/map notification slot (hidden except briefly after pulse_icon())
	var pulse_pack := _make_zelda_slot("Satchel / Map [I / M]", "")
	_pulse_slot = pulse_pack["slot"]
	_pulse_icon_rect = pulse_pack["icon"]
	_pulse_slot.visible = false
	_pulse_slot.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			bag_pressed.emit()
	)
	_top_right_row.add_child(_pulse_slot)

	# 2. Book II companion posture slot (hidden in Book I)
	var comp_pack := _make_zelda_slot("Companion Posture [X]", "X")
	_companion_slot = comp_pack["slot"]
	_companion_portrait = comp_pack["icon"]
	_companion_slot.visible = false
	_companion_pip = ColorRect.new()
	_companion_pip.color = Color(0.32, 0.88, 0.48)
	_companion_pip.custom_minimum_size = Vector2(5, 5)
	_companion_pip.size = Vector2(5, 5)
	_companion_pip.position = Vector2(4, SLOT_SIZE.y - 9)
	_companion_pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	comp_pack["overlay"].add_child(_companion_pip)
	_companion_slot.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			SoundManager.play_ui_click()
			GameState.cycle_companion_posture()
			refresh_current()
	)
	_top_right_row.add_child(_companion_slot)

	# 3. Equipped Zelda tool/knot slot [F] (click cycles unlocked knots)
	var knot_pack := _make_zelda_slot("Rope & Knot [F] (Click or [Q] to Switch)", "F")
	_knot_slot = knot_pack["slot"]
	_knot_icon_rect = knot_pack["icon"]
	_knot_icon_rect.texture = assets.get_tex("icon_knot.png")
	_knot_slot.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if GameState.unlocked_knots.size() > 1:
				SoundManager.play_ui_click()
				GameState.cycle_knot()
	)
	_top_right_row.add_child(_knot_slot)

	# 4. Optional compact Playtest / Acts jump button (default OFF; sits cleanly inside HBox)
	hud_playtest_btn = Button.new()
	hud_playtest_btn.text = "Acts [F1]"
	hud_playtest_btn.tooltip_text = "Jump to any Chapter or Cutscene [F1]"
	hud_playtest_btn.custom_minimum_size = Vector2(82, 38)
	hud_playtest_btn.focus_mode = Control.FOCUS_NONE
	hud_playtest_btn.pressed.connect(func(): playtest_pressed.emit())
	_top_right_row.add_child(hud_playtest_btn)

	# 5. Compact Pause Menu button
	hud_menu_btn = Button.new()
	hud_menu_btn.text = "Menu [Esc]"
	hud_menu_btn.tooltip_text = "Pause Menu, Diary, Bag & Controls [Esc]"
	hud_menu_btn.custom_minimum_size = Vector2(96, 38)
	hud_menu_btn.focus_mode = Control.FOCUS_NONE
	hud_menu_btn.pressed.connect(func(): menu_pressed.emit())
	_top_right_row.add_child(hud_menu_btn)


func _make_zelda_slot(tip: String, key_tag: String) -> Dictionary:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.tooltip_text = tip
	if _slot_style != null:
		slot.add_theme_stylebox_override("panel", _slot_style)

	var overlay := Control.new()
	overlay.custom_minimum_size = SLOT_SIZE - Vector2(10, 10)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)

	if key_tag != "":
		var tag := _make_hud_label(key_tag, 9, Color(0.98, 0.88, 0.56))
		tag.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tag.offset_left = -16
		tag.offset_top = -12
		tag.offset_right = 1
		tag.offset_bottom = 3
		overlay.add_child(tag)

	return {"slot": slot, "overlay": overlay, "icon": icon}


func _make_hud_label(txt: String, font_sz: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, 0.92))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl


func apply_post_theme_fixes() -> void:
	for b: Button in [hud_playtest_btn, hud_menu_btn]:
		if b == null:
			continue
		b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var sb_norm: StyleBoxTexture = assets.make_ui_9slice_style("ui_btn_normal.png", 6.0, 10.0, 6.0)
		var sb_hov: StyleBoxTexture = assets.make_ui_9slice_style("ui_btn_hover.png", 6.0, 10.0, 6.0)
		var sb_prs: StyleBoxTexture = assets.make_ui_9slice_style("ui_btn_pressed.png", 6.0, 10.0, 6.0)
		b.add_theme_stylebox_override("normal", sb_norm)
		b.add_theme_stylebox_override("hover", sb_hov)
		b.add_theme_stylebox_override("pressed", sb_prs)
		b.add_theme_stylebox_override("focus", sb_hov)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Color(0.96, 0.90, 0.74))
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.84))
		b.add_theme_color_override("font_pressed_color", Color(0.86, 0.76, 0.56))
		b.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, 0.90))
		b.add_theme_constant_override("shadow_offset_x", 1)
		b.add_theme_constant_override("shadow_offset_y", 2)
	if hud_playtest_btn != null:
		hud_playtest_btn.modulate = Color(1.04, 0.92, 0.86)


func step(delta: float) -> void:
	_hud_t += delta
	if _pulse_timers.is_empty():
		return
	var expired: Array[String] = []
	var best_kind := ""
	var best_t := 0.0
	for k: String in _pulse_timers.keys():
		var rem: float = float(_pulse_timers[k]) - delta
		if rem <= 0.0:
			expired.append(k)
		else:
			_pulse_timers[k] = rem
			if rem > best_t:
				best_t = rem
				best_kind = k
	for k in expired:
		_pulse_timers.erase(k)
	if _pulse_slot != null:
		if best_kind == "":
			_pulse_slot.visible = false
		else:
			var glow := 0.5 + 0.5 * sin(_hud_t * 7.5)
			var fade := clampf(best_t / 0.45, 0.0, 1.0)
			_pulse_slot.visible = true
			_pulse_slot.modulate = Color(1.0 + 0.16 * glow, 1.0 + 0.12 * glow, 0.92, fade)


func pulse_icon(kind: String, duration: float = 2.6) -> void:
	if not GameState.hints_enabled:
		return
	var k := kind if kind != "" else "bag"
	_pulse_timers[k] = maxf(float(_pulse_timers.get(k, 0.0)), duration)
	if _pulse_icon_rect != null:
		var icon_file := "icon_map.png" if (k == "map" or k == "wilds") else "icon_crate.png"
		_pulse_icon_rect.texture = assets.get_tex(icon_file)
	if _pulse_slot != null:
		_pulse_slot.visible = true
		_pulse_slot.modulate = Color(1.12, 1.08, 0.92, 1.0)


func clear_pulses() -> void:
	_pulse_timers.clear()
	if _pulse_slot != null:
		_pulse_slot.visible = false


func set_hud_visible(show_hud: bool) -> void:
	_hud_wanted = show_hud
	visible = show_hud


func sync_playtest_btn_visibility() -> void:
	if hud_playtest_btn != null:
		hud_playtest_btn.visible = GameState.show_playtest_hud_btn


func set_flight_mode(active: bool, mission_status: String = "") -> void:
	_flight_mode = active
	_flight_status = mission_status
	refresh(active, mission_status)


func refresh_current() -> void:
	refresh(_flight_mode, _flight_status)


func refresh(flight_mode: bool = false, flight_status: String = "") -> void:
	_flight_mode = flight_mode
	_flight_status = flight_status
	if _hearts_row == null:
		return

	_hearts_row.visible = not flight_mode
	_flight_row.visible = flight_mode
	if flight_mode:
		var h_pct := clampf(float(GameState.virelai_harness_hp) / 100.0, 0.0, 1.0)
		_flight_bar_fill.size.x = BAR_SIZE.x * h_pct
		_flight_bar_fill.color = Color(0.92, 0.72, 0.28) if h_pct > 0.35 else Color(0.92, 0.28, 0.22)
		_flight_status_lbl.text = flight_status
		_flight_status_lbl.visible = not flight_status.is_empty()
		_egg_row.visible = false
		_heat_row.visible = false
	else:
		_sync_hearts()
		_egg_row.visible = GameState.carrying_egg
		if _egg_row.visible:
			var w_pct := clampf(GameState.egg_warmth / 100.0, 0.0, 1.0)
			_egg_bar_fill.size.x = BAR_SIZE.x * w_pct
			_egg_bar_fill.color = Color(0.96, 0.62, 0.20) if GameState.egg_warmth >= 35.0 else Color(0.92, 0.24, 0.20)
		_heat_row.visible = GameState.city_heat >= 2.0
		if _heat_row.visible:
			var c_pct := clampf(GameState.city_heat / 100.0, 0.0, 1.0)
			_heat_bar_fill.size.x = BAR_SIZE.x * c_pct

	if _knot_slot != null:
		_knot_slot.visible = GameState.rope_unlocked and not flight_mode
		if _knot_slot.visible and _knot_icon_rect != null:
			_knot_icon_rect.modulate = _knot_tint(GameState.equipped_knot)
			_knot_slot.tooltip_text = "%s [F]  —  Click or press [Q] to cycle knots" % GameState.get_knot_display(GameState.equipped_knot)

	if _companion_slot != null:
		var has_comp := (GameState.active_companion_stage >= 1 or GameState.book2_started) and not flight_mode
		_companion_slot.visible = has_comp
		if has_comp and _companion_portrait != null:
			_companion_portrait.texture = assets.get_tex(GameState.get_hatchling_portrait())
			match GameState.companion_posture:
				"stay": _companion_pip.color = Color(0.95, 0.68, 0.24)
				"sling": _companion_pip.color = Color(0.36, 0.78, 0.96)
				_: _companion_pip.color = Color(0.36, 0.88, 0.50)
			_companion_slot.tooltip_text = "%s (%s) — Click or press [X] to switch posture" % [GameState.gold_dragon_name, GameState.companion_posture.capitalize()]

	sync_playtest_btn_visibility()
	visible = _hud_wanted


func _sync_hearts() -> void:
	var max_hp: int = maxi(1, GameState.boy_max_hp)
	var cur_hp: int = clampi(GameState.boy_hp, 0, max_hp)
	while _heart_nodes.size() < max_hp:
		var hr := TextureRect.new()
		hr.custom_minimum_size = HEART_ICON_SIZE
		hr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hearts_row.add_child(hr)
		_heart_nodes.append(hr)
	for i in range(_heart_nodes.size()):
		var hr := _heart_nodes[i]
		hr.visible = i < max_hp
		if hr.visible:
			hr.texture = _full_heart_tex if i < cur_hp else _empty_heart_tex
			hr.modulate = Color.WHITE if i < cur_hp else Color(0.88, 0.86, 0.90, 0.85)


func _knot_tint(kid: String) -> Color:
	match kid:
		"bruges_whipping": return Color(1.0, 0.84, 0.44)
		"bowline": return Color(0.56, 0.92, 0.96)
		"dragon_splice": return Color(1.0, 0.64, 0.36)
		_: return Color(0.96, 0.90, 0.76)
