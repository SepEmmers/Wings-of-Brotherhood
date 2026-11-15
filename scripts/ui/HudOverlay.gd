extends Control

## Top-left medieval parchment status HUD, flight bar, warmth/heat meter, and corner action buttons.

signal bag_pressed
signal menu_pressed
signal playtest_pressed

const _CARRY_TAGS := {
	"leather": "  |  Hands: Harness-Leather Bale",
	"water": "  |  Hands: Cliff-Spring Bucket",
	"fish": "  |  Hands: Fresh Silver Herring",
	"mutton": "  |  Hands: Butchered Mutton Quarter",
}

var assets
var hud_panel: PanelContainer
var hud_knot_icon: TextureRect
var hud_egg_icon: TextureRect
var hud_compass_icon: TextureRect
var hud_map_icon: TextureRect
var hud_wing_icon: TextureRect
var status_label: Label
var hud_hp_label: Label
var hud_bag_btn: Button
var hud_warmth_wrap: HBoxContainer
var hud_warmth_title_lbl: Label
var hud_warmth_fill: ColorRect
var hud_warmth_pct_lbl: Label
var knot_hud_label: Label
var hud_menu_btn: Button
var hud_playtest_btn: Button

var is_flight_hud_mode: bool = false
var custom_flight_status: String = ""
var hud_bag_pulse_t: float = 0.0
var hud_map_pulse_t: float = 0.0


func setup(assets_ref) -> void:
	assets = assets_ref
	name = "HudOverlay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(16, 14)
	hud_panel.custom_minimum_size = Vector2(560, 0)
	hud_panel.visible = false
	assets.style_parchment_panel(hud_panel, true)
	add_child(hud_panel)

	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 5)
	hud_panel.add_child(hud_box)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	hud_box.add_child(status_row)
	hud_compass_icon = _make_hud_icon("icon_compass.png")
	hud_egg_icon = _make_hud_icon("icon_egg.png")
	hud_map_icon = _make_hud_icon("icon_map.png")
	hud_wing_icon = _make_hud_icon("icon_wing.png")
	for ic in [hud_compass_icon, hud_egg_icon, hud_map_icon, hud_wing_icon]:
		status_row.add_child(ic)

	status_label = _make_lbl("", 14, Color(0.96, 0.86, 0.56))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.clip_text = true
	status_row.add_child(status_label)

	hud_hp_label = _make_lbl("", 13, Color(0.95, 0.52, 0.48))
	hud_hp_label.visible = false
	status_row.add_child(hud_hp_label)

	hud_warmth_wrap = HBoxContainer.new()
	hud_warmth_wrap.add_theme_constant_override("separation", 6)
	hud_warmth_wrap.visible = false
	status_row.add_child(hud_warmth_wrap)

	hud_bag_btn = Button.new()
	hud_bag_btn.text = "Bag [I]"
	hud_bag_btn.custom_minimum_size = Vector2(88, 24)
	hud_bag_btn.add_theme_font_size_override("font_size", 12)
	hud_bag_btn.pressed.connect(func(): emit_signal("bag_pressed"))
	status_row.add_child(hud_bag_btn)

	hud_warmth_title_lbl = _make_lbl("Warmth", 12, Color(0.92, 0.78, 0.50))
	hud_warmth_wrap.add_child(hud_warmth_title_lbl)

	var warmth_track_wrap := Control.new()
	warmth_track_wrap.custom_minimum_size = Vector2(84, 14)
	warmth_track_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hud_warmth_wrap.add_child(warmth_track_wrap)
	_make_c_rect(Color(0.64, 0.50, 0.25), Vector2(0, 1), Vector2(84, 12), warmth_track_wrap)
	_make_c_rect(Color(0.08, 0.06, 0.08), Vector2(2, 3), Vector2(80, 8), warmth_track_wrap)
	hud_warmth_fill = _make_c_rect(Color(0.95, 0.68, 0.24), Vector2(2, 3), Vector2(80, 8), warmth_track_wrap)
	hud_warmth_pct_lbl = _make_lbl("100%", 12, Color(0.98, 0.88, 0.62))
	hud_warmth_wrap.add_child(hud_warmth_pct_lbl)

	var hud_rule := _make_c_rect(Color(0.62, 0.48, 0.24, 0.48), Vector2.ZERO, Vector2.ZERO, hud_box)
	hud_rule.custom_minimum_size = Vector2(0, 1)

	var knot_row := HBoxContainer.new()
	knot_row.add_theme_constant_override("separation", 8)
	hud_box.add_child(knot_row)
	hud_knot_icon = _make_hud_icon("icon_knot.png")
	hud_knot_icon.visible = true
	knot_row.add_child(hud_knot_icon)
	knot_hud_label = _make_lbl("", 13, Color(0.75, 0.88, 0.78))
	knot_row.add_child(knot_hud_label)

	hud_menu_btn = Button.new()
	hud_menu_btn.text = "Menu [Esc]"
	hud_menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud_menu_btn.offset_left = -126
	hud_menu_btn.offset_top = 14
	hud_menu_btn.offset_right = -16
	hud_menu_btn.offset_bottom = 48
	hud_menu_btn.visible = false
	hud_menu_btn.pressed.connect(func(): emit_signal("menu_pressed"))
	add_child(hud_menu_btn)

	hud_playtest_btn = Button.new()
	hud_playtest_btn.text = "Chapters / Debug [F1]"
	hud_playtest_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud_playtest_btn.offset_left = -304
	hud_playtest_btn.offset_top = 14
	hud_playtest_btn.offset_right = -134
	hud_playtest_btn.offset_bottom = 48
	hud_playtest_btn.visible = false
	hud_playtest_btn.pressed.connect(func(): emit_signal("playtest_pressed"))
	add_child(hud_playtest_btn)


func apply_post_theme_fixes() -> void:
	if hud_bag_btn != null:
		hud_bag_btn.add_theme_font_size_override("font_size", 12)


func step(delta: float) -> void:
	hud_bag_pulse_t = maxf(0.0, hud_bag_pulse_t - delta)
	hud_map_pulse_t = maxf(0.0, hud_map_pulse_t - delta)
	if hud_bag_btn != null:
		var bw := (0.5 + 0.5 * sin(hud_bag_pulse_t * 11.0)) if hud_bag_pulse_t > 0.0 else 0.0
		hud_bag_btn.modulate = Color(1.0 + 0.35 * bw, 1.0 + 0.18 * bw, 1.0 - 0.25 * bw) if bw > 0.0 else Color.WHITE
	if hud_map_icon != null:
		var mw := (0.5 + 0.5 * sin(hud_map_pulse_t * 11.0)) if hud_map_pulse_t > 0.0 else 0.0
		hud_map_icon.modulate = Color(1.0 + 0.45 * mw, 1.0 + 0.25 * mw, 1.0 - 0.20 * mw) if mw > 0.0 else Color.WHITE
		if knot_hud_label != null:
			knot_hud_label.modulate = Color(1.0 + 0.18 * mw, 1.0 + 0.10 * mw, 1.0 - 0.10 * mw) if mw > 0.0 else Color.WHITE


func pulse_icon(kind: String, duration: float = 2.6) -> void:
	if not GameState.hints_enabled:
		return
	if kind == "bag":
		hud_bag_pulse_t = maxf(hud_bag_pulse_t, duration)
	elif kind == "map":
		hud_map_pulse_t = maxf(hud_map_pulse_t, duration)
		hud_bag_pulse_t = maxf(hud_bag_pulse_t, duration)


func clear_pulses() -> void:
	hud_bag_pulse_t = 0.0
	hud_map_pulse_t = 0.0


func set_hud_visible(show_hud: bool) -> void:
	if hud_panel != null:
		hud_panel.visible = show_hud
	if hud_menu_btn != null:
		hud_menu_btn.visible = show_hud
	if hud_playtest_btn != null:
		hud_playtest_btn.visible = show_hud and GameState.show_playtest_hud_btn


func sync_playtest_btn_visibility() -> void:
	if hud_playtest_btn != null and hud_panel != null:
		hud_playtest_btn.visible = hud_panel.visible and GameState.show_playtest_hud_btn


func set_flight_mode(active: bool, mission_status: String = "") -> void:
	is_flight_hud_mode = active
	custom_flight_status = mission_status
	refresh(active, mission_status)


func refresh_current() -> void:
	refresh(is_flight_hud_mode, custom_flight_status)


func refresh(flight_mode: bool = false, flight_status: String = "") -> void:
	if hud_panel == null:
		return
	is_flight_hud_mode = flight_mode
	custom_flight_status = flight_status

	var f_k := GameState.get_action_key_label("rope_action")
	var v_k := GameState.get_action_key_label("knife_attack")
	var c_k := GameState.get_action_key_label("dodge")
	var e_k := GameState.get_action_key_label("interact")

	if flight_mode:
		for ic in [hud_compass_icon, hud_egg_icon, hud_map_icon, hud_bag_btn, hud_hp_label]:
			if ic != null:
				ic.visible = false
		hud_wing_icon.visible = true
		status_label.text = flight_status if flight_status != "" else "Crewing Virelai"
		var hp_pct := float(GameState.virelai_harness_hp)
		var bar_col := Color(0.92, 0.24, 0.22) if GameState.virelai_loose_straps > 0 else (Color(0.38, 0.84, 0.56) if hp_pct >= 55.0 else Color(0.95, 0.62, 0.22))
		_set_bar(hp_pct, "Harness", bar_col)
		if GameState.virelai_loose_straps > 0:
			knot_hud_label.text = "[!] SHEARED BUCKLE — PRESS [%s] TO SPLICE RIGGING!" % f_k if GameState.control_prompts_enabled else "[!] SHEARED BUCKLE — SPLICE RIGGING!"
			knot_hud_label.add_theme_color_override("font_color", Color(1.0, 0.56, 0.48))
		else:
			if GameState.control_prompts_enabled:
				var fly_k := "%s%s%s%s" % [GameState.get_action_key_label("move_up"), GameState.get_action_key_label("move_left"), GameState.get_action_key_label("move_down"), GameState.get_action_key_label("move_right")]
				knot_hud_label.text = "[%s] Fly  [Click/%s] Crossbow Bolts  [%s] Barrel-Roll  [%s] Sketch" % [fly_k, v_k, c_k, e_k] if GameState.flight_sortie_id == 1 else "[%s] Fly  [Click/%s] Bolts  [%s] Barrel-Roll  [Clouds] Hide  [%s] Sketch  [%s] Splice" % [fly_k, v_k, c_k, e_k, f_k]
			else:
				knot_hud_label.text = "Aerial Patrol — Crewing Virelai" if GameState.flight_sortie_id == 1 else "Storm Formation — Cloud Cover Available"
			knot_hud_label.add_theme_color_override("font_color", Color(0.75, 0.90, 0.80))
		return

	hud_wing_icon.visible = false
	hud_compass_icon.visible = GameState.has_mariner_compass
	hud_egg_icon.visible = GameState.carrying_egg
	if hud_map_icon != null:
		hud_map_icon.visible = GameState.has_forest_map

	var carry_tag := "  |  Hands: Herring Crate" if GameState.carrying_crate else ("  |  Cradling Dragon Egg" if GameState.carrying_egg else str(_CARRY_TAGS.get(GameState.sanctuary_carrying_item, "")))
	var era_tag := ""
	if GameState.current_step == GameState.QuestStep.ACT2_SANCTUARY:
		era_tag = "  •  Yr %d (Trust %d%%)" % [1 if GameState.sanctuary_phase == 1 else (3 if GameState.sanctuary_phase == 2 else 5), GameState.dragon_trust]
	elif GameState.current_step == GameState.QuestStep.ACT4_SANCTUARY_DEBATE:
		era_tag = "  •  Council Debate"
	elif GameState.current_step == GameState.QuestStep.ACT4_BRUGES_CITY:
		era_tag = "  •  Walled Bruges"
	elif GameState.current_step == GameState.QuestStep.ACT4_NIGHT_HEIST:
		era_tag = "  •  Midnight Heist"
	status_label.text = "%s (Age %d)%s%s" % [GameState.player_name, GameState.boy_age, era_tag, carry_tag]

	var i_k := GameState.get_action_key_label("inventory_screen")
	var bag_count := GameState.inventory.size() + (1 if GameState.carrying_crate else 0)
	if hud_bag_btn != null:
		hud_bag_btn.visible = true
		var bag_prefix := "Bag [%s]" % i_k if GameState.control_prompts_enabled else "Bag"
		hud_bag_btn.text = "%s: %d" % [bag_prefix, bag_count] if bag_count > 0 else bag_prefix

	var show_hp := GameState.current_step in [GameState.QuestStep.SNITCH_TO_CHURCH, GameState.QuestStep.ACT4_BRUGES_CITY, GameState.QuestStep.ACT4_NIGHT_HEIST] or GameState.boy_hp < GameState.boy_max_hp
	hud_hp_label.visible = show_hp
	if show_hp:
		var hearts := ""
		for i in range(GameState.boy_max_hp):
			hearts += "♥" if i < GameState.boy_hp else "♡"
		hud_hp_label.text = "Health: " + hearts

	hud_warmth_wrap.visible = GameState.carrying_egg or GameState.city_heat > 0.5
	if GameState.carrying_egg:
		var pct := GameState.egg_warmth
		var w_col := Color(0.95, 0.68, 0.24) if pct >= 55.0 else (Color(0.92, 0.45, 0.18) if pct >= 30.0 else Color(0.90, 0.24, 0.22))
		_set_bar(pct, "Warmth", w_col)
	elif GameState.city_heat > 0.5:
		var h_pct := GameState.city_heat
		var h_col := Color(0.92, 0.24, 0.22) if h_pct >= 55.0 else (Color(0.95, 0.60, 0.22) if h_pct >= 22.0 else Color(0.75, 0.82, 0.54))
		_set_bar(h_pct, "Bounty Heat", h_col)

	var kdata: Dictionary = GameState.KNOT_DATA[GameState.equipped_knot]
	knot_hud_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.78))
	if GameState.control_prompts_enabled:
		var q_k := GameState.get_action_key_label("cycle_knot")
		var m_k := GameState.get_action_key_label("toggle_map")
		var comp_hud := ""
		if GameState.active_companion_stage >= 1 and GameState.active_perspective == "boy":
			var p_txt := "Cloak-Sling" if GameState.companion_posture == "sling" else ("Stay" if GameState.companion_posture == "stay" else "Assist")
			comp_hud = "  |  [%s] Dragon  [%s] %s" % [GameState.get_action_key_label("dragon_command"), GameState.get_action_key_label("dragon_posture"), p_txt]
		knot_hud_label.text = "Knot [%s]: %s (%s)  |  [%s] Cast  [%s] Knife%s  |  [%s] Bag  [%s] Map" % [q_k, kdata["name"], kdata.get("ability_short", kdata["throw_style"]), f_k, v_k, comp_hud, i_k, m_k]
	else:
		var comp_plain := ""
		if GameState.active_companion_stage >= 1 and GameState.active_perspective == "boy":
			var p_txt := "Cloak-Sling" if GameState.companion_posture == "sling" else ("Stay" if GameState.companion_posture == "stay" else "Assist")
			comp_plain = "  |  Companion: %s" % p_txt
		knot_hud_label.text = "Equipped Knot: %s (%s)%s" % [kdata["name"], kdata.get("ability_short", kdata["throw_style"]), comp_plain]


func _set_bar(pct_raw: float, title_txt: String, col: Color) -> void:
	var pct := clampf(pct_raw, 0.0, 100.0)
	hud_warmth_wrap.visible = true
	hud_warmth_title_lbl.text = title_txt
	hud_warmth_fill.size = Vector2(maxf(2.0, 80.0 * (pct / 100.0)), 8.0)
	hud_warmth_fill.color = col
	hud_warmth_pct_lbl.text = "%d%%" % int(round(pct))


func _make_hud_icon(fname: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.custom_minimum_size = Vector2(20, 20)
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture = assets.get_tex(fname)
	r.visible = false
	return r


func _make_lbl(txt: String, fsize: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	return l


func _make_c_rect(col: Color, pos: Vector2, sz: Vector2, parent: Node) -> ColorRect:
	var c := ColorRect.new()
	c.color = col
	c.position = pos
	c.size = sz
	parent.add_child(c)
	return c
