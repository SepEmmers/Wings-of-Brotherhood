extends PanelContainer
class_name CampfirePanel

## Overland Campfire Rest, Hatchling Feed (via ButcherMinigamePanel) & Kestrel Courier
## Dispatch Hub for Book II+ Route Regions. Lives cleanly outside GameUI.gd.

signal closed
signal rested_at_fire
signal fed_hatchling(new_bond: int)
signal kestrel_handoff_requested

var assets = null
var ui = null
var _site_title: String = "Wayside Campfire"
var _kestrel_ready: bool = false
var _kestrel_label: String = "Await Kestrel Dispatch"
var _region_id: String = "brabant_fens"
var _fire_pos: Vector2 = Vector2.ZERO

var title_lbl: Label
var stats_lbl: Label
var status_lbl: Label
var rest_btn: Button
var feed_btn: Button
var kestrel_btn: Button


func setup(assets_ref, ui_ref) -> void:
	assets = assets_ref
	ui = ui_ref
	visible = false
	custom_minimum_size = Vector2(520, 320)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -260
	offset_top = -160
	offset_right = 260
	offset_bottom = 160
	if assets != null:
		assets.style_parchment_panel(self)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	var header := HBoxContainer.new()
	vb.add_child(header)

	title_lbl = Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = "WAYSIDE CAMPFIRE ROOST"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.82, 0.44))
	header.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "Leave Fire [Esc]"
	close_btn.pressed.connect(close_panel)
	header.add_child(close_btn)

	stats_lbl = Label.new()
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	vb.add_child(stats_lbl)

	rest_btn = Button.new()
	rest_btn.custom_minimum_size = Vector2(0, 36)
	rest_btn.text = "Rest & Mend Gear (Restore Full Health)"
	rest_btn.pressed.connect(_on_rest_pressed)
	vb.add_child(rest_btn)

	feed_btn = Button.new()
	feed_btn.custom_minimum_size = Vector2(0, 36)
	feed_btn.text = "Carve & Feed Companion (+Bond)"
	feed_btn.pressed.connect(_on_feed_pressed)
	vb.add_child(feed_btn)

	kestrel_btn = Button.new()
	kestrel_btn.custom_minimum_size = Vector2(0, 36)
	kestrel_btn.text = "Send Kestrel Courier to Captain Anna"
	kestrel_btn.pressed.connect(_on_kestrel_pressed)
	vb.add_child(kestrel_btn)

	status_lbl = Label.new()
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.custom_minimum_size = Vector2(0, 36)
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 0.78))
	vb.add_child(status_lbl)


func open_roost(region_id: String, fire_pos: Vector2, site_title: String = "Wayside Campfire", kestrel_ready: bool = false, kestrel_label: String = "Meet Kestrel Courier") -> void:
	_region_id = region_id
	_fire_pos = fire_pos
	_site_title = site_title
	_kestrel_ready = kestrel_ready
	_kestrel_label = kestrel_label
	status_lbl.text = ""
	visible = true
	refresh()
	if ui != null:
		ui.emit_signal("modal_state_changed")


func close_panel() -> void:
	if not visible:
		return
	visible = false
	SoundManager.play_ui_click()
	emit_signal("closed")
	if ui != null:
		ui.emit_signal("modal_state_changed")


func refresh() -> void:
	title_lbl.text = _site_title.to_upper()
	var comp_status := "Dragon Egg" if GameState.active_companion_stage == 0 else "%s (Stage %d)" % [GameState.gold_dragon_name, GameState.active_companion_stage]
	stats_lbl.text = "Health: %d / %d   |   %s   |   Bond: %d%%   |   Rations: %d" % [
		GameState.boy_hp, GameState.boy_max_hp, comp_status, GameState.dragon_bond, GameState.raw_rations
	]
	feed_btn.disabled = GameState.active_companion_stage < 1 or GameState.raw_rations <= 0
	if GameState.active_companion_stage < 1:
		feed_btn.text = "Carve & Feed Companion (Wait Until Egg Hatches)"
	elif GameState.raw_rations <= 0:
		feed_btn.text = "Carve & Feed Companion (No Raw Rations in Pack)"
	else:
		feed_btn.text = "Carve & Feed %s (%d Rations Ready)" % [GameState.gold_dragon_name, GameState.raw_rations]

	kestrel_btn.visible = _kestrel_ready
	kestrel_btn.text = _kestrel_label


func _on_rest_pressed() -> void:
	GameState.boy_hp = GameState.boy_max_hp
	GameState.campfire_rests += 1
	GameState.last_campfire_region = _region_id
	GameState.last_campfire_pos = _fire_pos
	GameState.emit_signal("state_updated")
	SoundManager.play_campfire_warm()
	status_lbl.text = "Warm embers settle across your boots. Strength restored and camp hearth charted."
	refresh()
	emit_signal("rested_at_fire")


func _on_feed_pressed() -> void:
	if GameState.raw_rations <= 0 or GameState.active_companion_stage < 1:
		return
	visible = false
	if ui != null and ui.has_method("open_butcher_minigame"):
		ui.open_butcher_minigame(func():
			GameState.raw_rations = maxi(0, GameState.raw_rations - 1)
			GameState.hatchling_fed_count += 1
			GameState.add_dragon_bond(12)
			visible = false
			if ui != null:
				ui.emit_signal("modal_state_changed")
			emit_signal("fed_hatchling", GameState.dragon_bond)
			if ui != null and ui.has_method("trigger_companion_eat"):
				ui.trigger_companion_eat(_fire_pos, func(): emit_signal("closed"))
			else:
				SoundManager.play_dragon_purr()
				emit_signal("closed")
		, func():
			visible = true
			refresh()
		)


func _on_kestrel_pressed() -> void:
	visible = false
	SoundManager.play_ui_click()
	emit_signal("kestrel_handoff_requested")
	if ui != null:
		ui.emit_signal("modal_state_changed")
