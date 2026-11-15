extends PanelContainer

const RealmChartData := preload("res://scripts/data/WorldRealmChartData.gd")
const RealmChartDraw := preload("res://scripts/ui/WorldRealmChartDraw.gd")

## Cartographic Connected World Map, Frontier Survey & Kingdom Realm Chart [M].
## Mode 0: Interconnected Coastal Bruges (Port, Walled City, Outskirts, Sanctuary, Pines).
## Mode 1: Anna's Border Survey Map of Whispering Pines.
## Mode 2: Full Realm Charter of Flanders, Brabant & the Meuse Borderlands (Belgium).

signal close_requested

var map_canvas: ForestMapCanvas
var m_title: Label
var map_zone_label: Label
var map_notes_label: Label
var view_btn: Button
var view_mode_btns: Array[Button] = []

var view_mode: int = 0
var current_region_id: String = "bruges"
var current_player_pos: Vector2 = Vector2.ZERO
var _last_region_mode_check: String = ""
var hovered_node_id: String = ""
var selected_node_id: String = ""


func setup(assets_ref) -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -410
	offset_top = -308
	offset_right = 410
	offset_bottom = 308
	visible = false
	assets_ref.style_parchment_panel(self)

	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 6)
	add_child(mv)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	mv.add_child(header)

	m_title = Label.new()
	m_title.text = "CONNECTED REALM CHART — BRUGES TO SANCTUARY"
	m_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_title.add_theme_font_size_override("font_size", 15)
	m_title.add_theme_color_override("font_color", Color(0.96, 0.84, 0.50))
	header.add_child(m_title)

	map_zone_label = Label.new()
	map_zone_label.text = "Region: Port of Bruges"
	map_zone_label.add_theme_font_size_override("font_size", 13)
	map_zone_label.add_theme_color_override("font_color", Color(0.75, 0.90, 0.78))
	header.add_child(map_zone_label)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	mv.add_child(tab_row)

	var mode_specs := [
		[0, "1. Coastal Bruges"],
		[1, "2. Wilds Survey"],
		[2, "3. Kingdom Charter (Flanders → Meuse)"],
	]
	view_mode_btns.clear()
	for ms in mode_specs:
		var m_idx: int = int(ms[0])
		var mb := Button.new()
		mb.text = str(ms[1])
		mb.custom_minimum_size = Vector2(0, 26)
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL if m_idx == 2 else 0
		mb.pressed.connect(func(): set_view_mode(m_idx))
		tab_row.add_child(mb)
		view_mode_btns.append(mb)

	view_btn = Button.new()
	view_btn.text = "Cycle Chart [Tab]"
	view_btn.custom_minimum_size = Vector2(138, 26)
	view_btn.pressed.connect(toggle_view_mode)
	tab_row.add_child(view_btn)

	map_canvas = ForestMapCanvas.new()
	map_canvas.assets = assets_ref
	map_canvas.panel_ref = self
	map_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	map_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	map_canvas.custom_minimum_size = Vector2(764, 384)
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_canvas.mouse_exited.connect(_on_canvas_mouse_exited)
	mv.add_child(map_canvas)

	map_notes_label = Label.new()
	map_notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_notes_label.custom_minimum_size = Vector2(740, 48)
	map_notes_label.add_theme_font_size_override("font_size", 13)
	map_notes_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.76))
	mv.add_child(map_notes_label)

	var m_close := Button.new()
	m_close.text = "Fold Chart [M / Esc]"
	m_close.custom_minimum_size = Vector2(0, 30)
	m_close.pressed.connect(func(): emit_signal("close_requested"))
	mv.add_child(m_close)


func set_player_location(region_id: String, player_pos: Vector2) -> void:
	current_region_id = region_id
	current_player_pos = player_pos
	var realm_node := RealmChartData.node_id_for_region(region_id)
	if realm_node != "":
		GameState.unlock_realm_node(realm_node)
	if _last_region_mode_check != region_id:
		_last_region_mode_check = region_id
		if int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_BRABANT_FENS) or region_id in [
			"brabant_fens", "louvain", "old_heverlee", "hesbaye_uplands", "namur_citadel", "ardennes_ridge", "blood_citadel"
		]:
			view_mode = 2
		elif region_id in ["wilds", "hearth"] and GameState.has_forest_map:
			view_mode = 1
		else:
			view_mode = 0
	if visible and map_canvas != null:
		map_canvas.queue_redraw()


func set_view_mode(new_mode: int) -> void:
	view_mode = posmod(new_mode, 3)
	if view_mode != 2:
		hovered_node_id = ""
	SoundManager.play_ui_click()
	refresh()


func toggle_view_mode() -> void:
	set_view_mode((view_mode + 1) % 3)


func _on_canvas_mouse_exited() -> void:
	if hovered_node_id != "":
		hovered_node_id = ""
		if visible and view_mode == 2:
			refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		toggle_view_mode()


func _region_display_name(rid: String) -> String:
	match rid:
		"bruges": return "Port of Bruges"
		"house": return "Uncle Willem's Cottage (Port Quarter)"
		"bruges_city": return "Walled City of Bruges"
		"outskirts": return "Bruges Coastal Outskirts"
		"sanctuary": return "Brotherhood Sanctuary"
		"wilds": return "Whispering Pines — %s" % GameState.active_wilds_zone
		"hearth": return "Frontier Watchtower Hearth"
		"flight": return "Aerial Sortie over Flanders"
		"brabant_fens": return "Brabant Reed-Fens"
		"louvain": return "Louvain — Dijle Cloth-Quarter"
		"old_heverlee": return "Old Heverlee Woods & Shrine"
		"hesbaye_uplands": return "Hesbaye Uplands"
		"namur_citadel": return "Namur Cliff-Citadel"
		"ardennes_ridge": return "Ardennes Mist-Gorges"
		"blood_citadel": return "Meuse Blood-Citadel"
		_: return "Kingdom of Flanders & Brabant"


func _format_realm_notes() -> String:
	var inspect_id := hovered_node_id if hovered_node_id != "" else selected_node_id
	if inspect_id != "":
		var node := RealmChartData.get_node_by_id(inspect_id)
		if not node.is_empty():
			if not RealmChartData.is_node_discovered(node):
				return "[ Uncharted Frontier ] — Advance further inland by foot or dragon-wing sorties to survey this province."
			var feat_str := ", ".join(node.get("features", []))
			return "%s (%s) — %s  [%s]" % [str(node["name"]), str(node["subtitle"]), str(node["lore"]), feat_str]
	var cur_node := RealmChartData.get_node_by_id(RealmChartData.node_id_for_region(current_region_id))
	var cur_name := str(cur_node.get("name", _region_display_name(current_region_id)))
	if GameState.book2_started or int(GameState.current_step) >= int(GameState.QuestStep.BOOK2_BRABANT_FENS):
		var anna_n := RealmChartData.get_node_by_id(RealmChartData.get_anna_anchor_node_id())
		return "Theater Overview: Boy & %s currently at %s; Captain Anna & Virelai operating near %s. Hover or click any province seal to read survey notes." % [
			GameState.gold_dragon_name, cur_name, str(anna_n.get("name", "Sanctuary Cliffs"))
		]
	return "Kingdom Realm Charter: Charted provinces from Flanders' North Sea coast inland through Brabant to the Meuse borderlands (currently at %s). Hover or click any seal to inspect." % cur_name


func refresh() -> void:
	if map_canvas == null:
		return
	map_zone_label.text = "Location: %s" % _region_display_name(current_region_id)
	for bi in range(view_mode_btns.size()):
		var b: Button = view_mode_btns[bi]
		b.modulate = Color(1.08, 0.94, 0.62) if bi == view_mode else Color(0.84, 0.80, 0.72)
	if view_mode == 0:
		m_title.text = "CONNECTED WORLD CHART — BRUGES TO BROTHERHOOD SANCTUARY"
		map_notes_label.text = (
			"Walk seamlessly between every gate and quay: Port of Bruges docks directly south of the Walled City's "
			+ "South Port Gate. Head east through Bruges's East Outskirts Gate across the Zwin canal to reach the Brotherhood Sanctuary cliffs."
		)
	elif view_mode == 1:
		m_title.text = "BROTHERHOOD BORDER SURVEY — WHISPERING PINES"
		if not GameState.has_forest_map:
			map_notes_label.text = "You have not yet recovered Anna's Border Survey Map. Switch tabs or press [Tab] for Coastal Bruges or the Kingdom Charter."
		elif GameState.carrying_egg:
			map_notes_label.text = (
				"Anna's Margin Note: \"North-central gorge past Cairn I ends in a sheer frost cliff. Trail skirts SOUTH past Split-Oak & Watch-Fire Alpha "
				+ "toward Two-Horn Boulder and Hemlock Bend, then follows the creek bend north past Cairn II toward the Watchtower Gate.\""
			)
		else:
			map_notes_label.text = "Tracks wind north through Fallen Hemlock Glade into the sunken western ravine—ridges lock the eastern Watchtower pass until you find Obsidian Hollow."
	else:
		m_title.text = "KINGDOM REALM CHARTER — FLANDERS, BRABANT & MEUSE"
		map_notes_label.text = _format_realm_notes()
	map_canvas.queue_redraw()


class _MapLabelOverlay extends Control:
	var commands: Array[Dictionary] = []

	func _draw() -> void:
		for cmd in commands:
			var f: Font = cmd["font"]
			var p: Vector2 = cmd["pos"]
			var txt: String = cmd["text"]
			var sz: int = cmd["sz"]
			var col: Color = cmd["col"]
			if bool(cmd.get("shadow", true)):
				draw_string(f, p + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0.86, 0.79, 0.62, 0.85))
			draw_string(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


class ForestMapCanvas extends Control:
	const WORLD_W := 2880.0
	const WORLD_H := 2160.0
	var assets = null
	var panel_ref = null
	var _label_overlay: _MapLabelOverlay = null
	var _pending_labels: Array[Dictionary] = []

	func _ensure_label_overlay() -> _MapLabelOverlay:
		if _label_overlay == null:
			_label_overlay = _MapLabelOverlay.new()
			_label_overlay.name = "MapLabelOverlay"
			_label_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_label_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_label_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_label_overlay)
		return _label_overlay

	func _ink_font(font: Font) -> Font:
		if assets != null:
			return assets.get_ui_font()
		return font

	func _draw_ink_text(font: Font, pos: Vector2, text: String, sz: int, ink: Color) -> void:
		_pending_labels.append({
			"font": _ink_font(font),
			"pos": pos,
			"text": text,
			"sz": sz,
			"col": ink,
			"shadow": true,
		})

	func _draw_ink_badge(font: Font, center: Vector2, label: String, fill_col: Color, border_col: Color, text_col: Color) -> void:
		var use_f := _ink_font(font)
		var tw := use_f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var rect := Rect2(center - Vector2(tw * 0.5 + 5.0, 8.0), Vector2(tw + 10.0, 15.0))
		draw_rect(Rect2(rect.position + Vector2(1, 1), rect.size), Color(0.18, 0.12, 0.08, 0.35))
		draw_rect(rect, fill_col)
		draw_rect(rect, border_col, false, 1.5)
		_pending_labels.append({
			"font": use_f,
			"pos": Vector2(rect.position.x + 5.0, rect.position.y + 11.5),
			"text": label,
			"sz": 10,
			"col": text_col,
			"shadow": false,
		})

	func _draw_dashed_curve(pts: PackedVector2Array, col: Color, width: float, dash_len: float, gap_len: float) -> void:
		if pts.size() < 2:
			return
		var total_step := dash_len + gap_len
		var accum := 0.0
		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			var seg_len := a.distance_to(b)
			if seg_len < 0.5:
				continue
			var dir := (b - a) / seg_len
			var t := 0.0
			while t < seg_len:
				var cycle := fmod(accum + t, total_step)
				if cycle < dash_len:
					var seg_end := minf(seg_len, t + (dash_len - cycle))
					draw_line(a + dir * t, a + dir * seg_end, col, width)
					t = seg_end
				else:
					t += total_step - cycle
			accum += seg_len

	func _draw_vellum_frame(font: Font, w: float, h: float) -> void:
		var vellum: Texture2D = assets.get_tex("ui_map_vellum.png") if assets != null else null
		if vellum != null:
			draw_texture_rect(vellum, Rect2(0, 0, w, h), true)
		else:
			draw_rect(Rect2(0, 0, w, h), Color(0.79, 0.71, 0.54))
		draw_rect(Rect2(0, 0, w, 12), Color(0.32, 0.22, 0.12, 0.16))
		draw_rect(Rect2(0, h - 12, w, 12), Color(0.32, 0.22, 0.12, 0.16))
		draw_rect(Rect2(0, 12, 12, h - 24), Color(0.32, 0.22, 0.12, 0.16))
		draw_rect(Rect2(w - 12, 12, 12, h - 24), Color(0.32, 0.22, 0.12, 0.16))
		draw_rect(Rect2(3, 3, w - 6, h - 6), Color(0.24, 0.17, 0.10), false, 2.0)
		draw_rect(Rect2(9, 9, w - 18, h - 18), Color(0.46, 0.34, 0.20), false, 1.0)
		var tick_w := 32.0
		var tx := 9.0
		var toggle := false
		while tx + tick_w <= w - 9.0:
			if toggle:
				draw_rect(Rect2(tx, 4, tick_w, 4), Color(0.30, 0.21, 0.12, 0.75))
				draw_rect(Rect2(tx, h - 8, tick_w, 4), Color(0.30, 0.21, 0.12, 0.75))
			toggle = not toggle
			tx += tick_w
		var ty := 9.0
		toggle = false
		while ty + tick_w <= h - 9.0:
			if toggle:
				draw_rect(Rect2(4, ty, 4, tick_w), Color(0.30, 0.21, 0.12, 0.75))
				draw_rect(Rect2(w - 8, ty, 4, tick_w), Color(0.30, 0.21, 0.12, 0.75))
			toggle = not toggle
			ty += tick_w
		var comp_tex: Texture2D = assets.get_tex("ui_map_compass.png") if assets != null else null
		if comp_tex != null:
			draw_texture_rect(comp_tex, Rect2(Vector2(18, 18), Vector2(36, 36)), false)
			_draw_ink_text(font, Vector2(32, 16), "N", 10, Color(0.55, 0.14, 0.10))
		var bh_emblem: Texture2D = assets.get_tex("ui_brotherhood_emblem.png") if assets != null else null
		if bh_emblem != null:
			draw_texture_rect(bh_emblem, Rect2(Vector2(18, h - 58), Vector2(40, 40)), false, Color(1.0, 1.0, 1.0, 0.88))

	func _draw() -> void:
		_pending_labels.clear()
		var font: Font = assets.get_ui_font() if assets != null else get_theme_default_font()
		var w := size.x
		var h := size.y
		_draw_vellum_frame(font, w, h)
		var vm: int = int(panel_ref.view_mode) if panel_ref != null else 0
		if vm == 0:
			_draw_world_map(font, w, h)
		elif vm == 1:
			_draw_wilds_survey(font, w, h)
		else:
			var rid: String = str(panel_ref.current_region_id) if panel_ref != null else "bruges"
			var hov: String = str(panel_ref.hovered_node_id) if panel_ref != null else ""
			var sel: String = str(panel_ref.selected_node_id) if panel_ref != null else ""
			RealmChartDraw.draw_realm_chart(self, font, w, h, rid, hov, sel)
		var ov := _ensure_label_overlay()
		ov.commands = _pending_labels.duplicate()
		ov.queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if panel_ref == null or int(panel_ref.view_mode) != 2:
			return
		if event is InputEventMouseMotion:
			var hit := RealmChartDraw.hit_test_node(event.position, size.x, size.y)
			var next_hov := str(hit.get("id", ""))
			if next_hov != panel_ref.hovered_node_id:
				panel_ref.hovered_node_id = next_hov
				panel_ref.refresh()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var hit := RealmChartDraw.hit_test_node(event.position, size.x, size.y)
			var cid := str(hit.get("id", ""))
			panel_ref.selected_node_id = "" if (cid == "" or cid == panel_ref.selected_node_id) else cid
			SoundManager.play_ui_click()
			panel_ref.refresh()

	func _player_pin_world_map() -> Vector2:
		var rid: String = str(panel_ref.current_region_id) if panel_ref != null else "bruges"
		var p: Vector2 = panel_ref.current_player_pos if panel_ref != null else Vector2.ZERO
		match rid:
			"bruges":
				return Vector2(212.0 + clampf(p.x / 1600.0, 0.0, 1.0) * 98.0, 212.0 + clampf(p.y / 1040.0, 0.0, 1.0) * 86.0)
			"house":
				return Vector2(292, 276)
			"bruges_city":
				return Vector2(185.0 + clampf(p.x / 2880.0, 0.0, 1.0) * 145.0, 76.0 + clampf(p.y / 2160.0, 0.0, 1.0) * 124.0)
			"outskirts":
				return Vector2(342.0 + clampf(p.x / 2400.0, 0.0, 1.0) * 134.0, 128.0 + clampf(p.y / 1140.0, 0.0, 1.0) * 86.0)
			"sanctuary":
				return Vector2(488.0 + clampf(p.x / 1800.0, 0.0, 1.0) * 90.0, 122.0 + clampf(p.y / 1140.0, 0.0, 1.0) * 78.0)
			"wilds":
				return Vector2(616.0 + clampf(p.x / 2880.0, 0.0, 1.0) * 116.0, 68.0 + clampf(p.y / 2160.0, 0.0, 1.0) * 166.0)
			"hearth":
				return Vector2(722, 96)
			"flight":
				return Vector2(544, 72)
			_:
				return Vector2(258, 252)

	func _draw_world_map(font: Font, w: float, h: float) -> void:
		# 1. North Sea & Zwin Harbor Estuary along the west flank
		var sea_poly := PackedVector2Array([
			Vector2(14, 14), Vector2(160, 14), Vector2(154, 118), Vector2(174, 214),
			Vector2(218, 232), Vector2(218, 302), Vector2(168, 344), Vector2(14, 344)
		])
		draw_colored_polygon(sea_poly, Color(0.24, 0.42, 0.56, 0.34))
		draw_polyline(sea_poly, Color(0.16, 0.30, 0.42, 0.72), 2.0)
		_draw_ink_text(font, Vector2(42, 112), "ZWIN", 12, Color(0.16, 0.30, 0.44))
		_draw_ink_text(font, Vector2(30, 128), "ESTUARY", 11, Color(0.16, 0.30, 0.44))

		# 2. Region parchment zones & architectural footprints
		var city_box := Rect2(185, 76, 145, 124)
		var port_box := Rect2(212, 212, 98, 86)
		var out_box := Rect2(342, 128, 134, 86)
		var sanc_box := Rect2(488, 122, 90, 78)
		var wilds_box := Rect2(616, 68, 118, 174)

		for box_info in [
			[city_box, Color(0.46, 0.40, 0.34, 0.28), Color(0.26, 0.19, 0.14)],
			[port_box, Color(0.52, 0.44, 0.32, 0.26), Color(0.30, 0.22, 0.14)],
			[out_box, Color(0.40, 0.52, 0.32, 0.24), Color(0.24, 0.32, 0.18)],
			[sanc_box, Color(0.32, 0.50, 0.34, 0.28), Color(0.18, 0.34, 0.20)],
			[wilds_box, Color(0.28, 0.42, 0.30, 0.28), Color(0.16, 0.28, 0.20)],
		]:
			draw_rect(box_info[0], box_info[1])
			draw_rect(box_info[0], box_info[2], false, 2.0)

		# Reien Canals inside Bruges + Zwin Feeder Canal in Outskirts
		draw_line(Vector2(185, 142), Vector2(330, 142), Color(0.22, 0.44, 0.62, 0.85), 3.0)
		draw_line(Vector2(246, 76), Vector2(246, 200), Color(0.22, 0.44, 0.62, 0.85), 3.0)
		draw_line(Vector2(408, 118), Vector2(408, 224), Color(0.22, 0.44, 0.62, 0.85), 4.0)

		# Pine stamps across Outskirts, Sanctuary Cliffs & Whispering Pines
		var pine_stamp: Texture2D = assets.get_tex("map_stamp_pines.png") if assets != null else null
		for pt in [Vector2(370, 146), Vector2(448, 196), Vector2(548, 142), Vector2(648, 112), Vector2(692, 168), Vector2(654, 212)]:
			if pine_stamp != null:
				draw_texture_rect(pine_stamp, Rect2(pt - Vector2(12, 10), Vector2(24, 20)), false, Color(0.86, 0.82, 0.72, 0.90))

		# 3. Interconnected Walkable Roads (solid dark ink) vs Sortie Air Corridor (dashed teal)
		var links := [
			PackedVector2Array([Vector2(256, 196), Vector2(256, 216)]),
			PackedVector2Array([Vector2(326, 152), Vector2(492, 160)]),
			PackedVector2Array([Vector2(304, 214), Vector2(304, 206), Vector2(363, 206), Vector2(363, 168)]),
		]
		for ln in links:
			draw_polyline(ln, Color(0.76, 0.66, 0.46, 0.65), 6.5, true)
			draw_polyline(ln, Color(0.32, 0.20, 0.10, 0.95), 2.5, true)

		_draw_dashed_curve(PackedVector2Array([Vector2(534, 122), Vector2(576, 70), Vector2(646, 110)]), Color(0.14, 0.44, 0.38, 0.90), 2.2, 6.0, 4.0)

		# 4. Crisp Landmark Dots & Inked Calligraphy Labels
		_draw_ink_text(font, Vector2(204, 68), "WALLED CITY OF BRUGES", 12, Color(0.18, 0.12, 0.08))
		_draw_ink_text(font, Vector2(202, 104), "Citadel", 9, Color(0.28, 0.18, 0.14))
		_draw_ink_text(font, Vector2(266, 102), "St. Donatian", 9, Color(0.28, 0.18, 0.14))
		_draw_ink_text(font, Vector2(254, 148), "Grote Markt", 9, Color(0.22, 0.14, 0.10))
		_draw_ink_text(font, Vector2(276, 178), "Beguinage", 9, Color(0.24, 0.22, 0.14))

		_draw_ink_badge(font, Vector2(256, 206), "South Gate", Color(0.86, 0.78, 0.56), Color(0.32, 0.22, 0.12), Color(0.18, 0.12, 0.08))
		_draw_ink_badge(font, Vector2(334, 206), "NE Towpath", Color(0.86, 0.78, 0.56), Color(0.32, 0.22, 0.12), Color(0.18, 0.12, 0.08))
		_draw_ink_badge(font, Vector2(334, 152), "East Gate", Color(0.86, 0.78, 0.56), Color(0.32, 0.22, 0.12), Color(0.18, 0.12, 0.08))
		_draw_ink_text(font, Vector2(218, 232), "PORT OF BRUGES", 11, Color(0.18, 0.12, 0.08))
		_draw_ink_text(font, Vector2(226, 250), "Quay & Ropewalk", 9, Color(0.28, 0.20, 0.14))
		_draw_ink_text(font, Vector2(246, 286), "Willem's Cottage", 9, Color(0.28, 0.20, 0.14))

		_draw_ink_text(font, Vector2(350, 120), "BRUGES OUTSKIRTS", 11, Color(0.18, 0.12, 0.08))
		_draw_ink_text(font, Vector2(352, 182), "Tollhouse", 9, Color(0.24, 0.18, 0.12))
		_draw_ink_badge(font, Vector2(408, 155), "Zwin Bridge", Color(0.76, 0.84, 0.88), Color(0.18, 0.34, 0.44), Color(0.12, 0.22, 0.30))

		_draw_ink_text(font, Vector2(490, 114), "SANCTUARY", 11, Color(0.14, 0.26, 0.16))
		_draw_ink_text(font, Vector2(498, 174), "Outpost Ridge", 9, Color(0.16, 0.28, 0.16))
		_draw_ink_text(font, Vector2(548, 62), "Aerial Wing Route", 9, Color(0.14, 0.40, 0.36))

		_draw_ink_text(font, Vector2(616, 60), "WHISPERING PINES", 11, Color(0.16, 0.22, 0.14))
		_draw_ink_text(font, Vector2(624, 156), "Obsidian Hollow", 9, Color(0.24, 0.16, 0.24))
		_draw_ink_text(font, Vector2(674, 92), "Watchtower", 9, Color(0.14, 0.34, 0.18))
		_draw_ink_text(font, Vector2(674, 104), "Hearth", 9, Color(0.14, 0.34, 0.18))

		# 5. Live Pulsing Player Pin
		var pin := _player_pin_world_map()
		var pulse := 0.5 + 0.5 * sin(float(assets.time_elapsed) * 5.0 if assets != null else 0.0)
		draw_circle(pin, 11.0 + pulse * 4.0, Color(0.96, 0.32, 0.22, 0.28))
		draw_arc(pin, 11.0 + pulse * 4.0, 0.0, TAU, 20, Color(0.82, 0.18, 0.14, 0.85), 1.8)
		draw_circle(pin, 5.2, Color(0.20, 0.08, 0.06))
		draw_circle(pin, 3.6, Color(0.98, 0.78, 0.24))
		_draw_ink_badge(font, pin + Vector2(0, -16), "YOU", Color(0.76, 0.18, 0.14), Color(0.26, 0.08, 0.06), Color(0.98, 0.94, 0.84))

		# 6. Bottom-Right Cartographer Legend
		_draw_ink_text(font, Vector2(w - 230, h - 34), "Solid Ink: Connected Roads & Gates", 10, Color(0.26, 0.18, 0.12))
		_draw_ink_text(font, Vector2(w - 230, h - 20), "Dashed Teal: Virelai Wing Sorties", 10, Color(0.14, 0.40, 0.36))

	func _draw_wilds_survey(font: Font, w: float, h: float) -> void:
		if not GameState.has_forest_map:
			var seal: Texture2D = assets.get_tex("ui_wax_seal.png") if assets != null else null
			if seal != null:
				draw_texture_rect(seal, Rect2(w * 0.5 - 24, h * 0.5 - 52, 48, 48), false)
			_draw_ink_text(font, Vector2(w * 0.5 - 140, h * 0.5 + 14), "[ No Border Survey Map Recovered Yet ]", 15, Color(0.26, 0.18, 0.12))
			return

		var pad_x := 36.0
		var pad_y := 24.0
		var map_w := w - pad_x * 2.0
		var map_h := h - pad_y * 2.0
		var to_m := func(wp: Vector2) -> Vector2:
			return Vector2(pad_x + (wp.x / WORLD_W) * map_w, pad_y + (wp.y / WORLD_H) * map_h)

		for wash in [
			[Vector2(1635, 240), 42.0, Color(0.34, 0.52, 0.62, 0.16), Color(0.26, 0.44, 0.56, 0.48)],
			[Vector2(2040, 1845), 40.0, Color(0.34, 0.52, 0.62, 0.16), Color(0.26, 0.44, 0.56, 0.48)],
			[Vector2(2565, 1790), 40.0, Color(0.34, 0.52, 0.62, 0.16), Color(0.26, 0.44, 0.56, 0.48)],
			[Vector2(265, 300), 36.0, Color(0.28, 0.22, 0.28, 0.15), Color(0.32, 0.22, 0.20, 0.50)],
			[Vector2(2620, 255), 36.0, Color(0.34, 0.52, 0.30, 0.16), Color(0.22, 0.44, 0.24, 0.52)]
		]:
			var wp_c: Vector2 = to_m.call(wash[0])
			var rad := float(wash[1])
			draw_circle(wp_c, rad, wash[2])
			draw_arc(wp_c, rad, 0.0, TAU, 24, wash[3], 1.2)
			draw_arc(wp_c, rad * 0.72, 0.0, TAU, 20, Color(wash[3].r, wash[3].g, wash[3].b, wash[3].a * 0.65), 1.0)

		var pine_stamp: Texture2D = assets.get_tex("map_stamp_pines.png") if assets != null else null
		for tree_cluster in [
			Vector2(620, 1680), Vector2(460, 1120), Vector2(960, 1520), Vector2(940, 560),
			Vector2(1420, 560), Vector2(1420, 1120), Vector2(1880, 740), Vector2(2460, 960),
			Vector2(2480, 1340), Vector2(1420, 1850)
		]:
			var tp: Vector2 = to_m.call(tree_cluster)
			if pine_stamp != null:
				draw_texture_rect(pine_stamp, Rect2(tp - Vector2(14, 11), Vector2(28, 22)), false, Color(0.86, 0.82, 0.72, 0.88))

		for river in [
			[
				Vector2(545, 0), Vector2(525, 110), Vector2(532, 310), Vector2(490, 500),
				Vector2(510, 825), Vector2(492, 995), Vector2(545, 1345),
				Vector2(515, 1560), Vector2(475, 1790), Vector2(510, 2160)
			],
			[
				Vector2(1870, 0), Vector2(1855, 135), Vector2(1832, 345), Vector2(1885, 512),
				Vector2(2155, 532), Vector2(2385, 502), Vector2(2620, 558), Vector2(2880, 530)
			]
		]:
			var rpts := PackedVector2Array()
			for wp2 in river:
				rpts.append(to_m.call(wp2))
			draw_polyline(rpts, Color(0.14, 0.28, 0.40, 0.90), 6.0, true)
			draw_polyline(rpts, Color(0.38, 0.58, 0.70, 0.92), 3.0, true)
			_draw_dashed_curve(rpts, Color(0.76, 0.88, 0.94, 0.72), 1.2, 4.0, 8.0)

		var routes := [
			[Vector2(270, 1890), Vector2(215, 1650), Vector2(305, 1410), "path"],
			[Vector2(305, 1410), Vector2(560, 1345), Vector2(845, 1285), "briar"],
			[Vector2(845, 1285), Vector2(810, 1560), Vector2(765, 1815), "path"],
			[Vector2(845, 1285), Vector2(745, 1070), Vector2(675, 845), "path"],
			[Vector2(675, 845), Vector2(500, 825), Vector2(335, 805), "winch"],
			[Vector2(335, 805), Vector2(290, 560), Vector2(265, 300), "path"],
			[Vector2(265, 300), Vector2(530, 312), Vector2(760, 275), "ridge"],
			[Vector2(760, 275), Vector2(935, 255), Vector2(1110, 305), "path"],
			[Vector2(1110, 305), Vector2(1380, 295), Vector2(1635, 240), "cold"],
			[Vector2(1110, 305), Vector2(1145, 580), Vector2(1185, 845), "path"],
			[Vector2(1185, 845), Vector2(1465, 825), Vector2(1720, 860), "briar"],
			[Vector2(1185, 845), Vector2(1145, 1110), Vector2(1195, 1365), "path"],
			[Vector2(1195, 1365), Vector2(1430, 1445), Vector2(1685, 1390), "path"],
			[Vector2(1720, 860), Vector2(1755, 1135), Vector2(1685, 1390), "path"],
			[Vector2(1685, 1390), Vector2(1875, 1630), Vector2(2040, 1845), "cold"],
			[Vector2(1685, 1390), Vector2(1895, 1320), Vector2(2110, 1315), "path"],
			[Vector2(2110, 1315), Vector2(2360, 1580), Vector2(2565, 1790), "cold"],
			[Vector2(2110, 1315), Vector2(2200, 1005), Vector2(2155, 700), "path"],
			[Vector2(2155, 700), Vector2(2150, 505), Vector2(2165, 315), "winch"],
			[Vector2(2165, 315), Vector2(2415, 235), Vector2(2620, 255), "path"]
		]
		for rt in routes:
			var a: Vector2 = to_m.call(rt[0])
			var c: Vector2 = to_m.call(rt[1])
			var b: Vector2 = to_m.call(rt[2])
			var kind: String = rt[3]
			var pts := PackedVector2Array()
			for si in range(13):
				var t := float(si) / 12.0
				var omt := 1.0 - t
				pts.append((omt * omt) * a + (2.0 * omt * t) * c + (t * t) * b)
			draw_polyline(pts, Color(0.56, 0.45, 0.30, 0.30), 6.0, true)
			if kind == "cold":
				_draw_dashed_curve(pts, Color(0.22, 0.44, 0.58), 2.5, 6.0, 4.0)
			elif kind == "briar":
				_draw_dashed_curve(pts, Color(0.58, 0.20, 0.14), 2.5, 5.0, 3.0)
			elif kind == "winch":
				draw_polyline(pts, Color(0.14, 0.44, 0.36), 2.8, true)
			else:
				_draw_dashed_curve(pts, Color(0.28, 0.20, 0.12), 2.5, 8.0, 3.0)

			var mid: Vector2 = to_m.call(rt[1])
			if kind == "briar":
				_draw_ink_badge(font, mid, "Cut", Color(0.62, 0.22, 0.14), Color(0.28, 0.10, 0.06), Color(0.98, 0.94, 0.80))
			elif kind == "winch":
				var badge_pos := mid + (Vector2(-26, -2) if rt[0].x > 2000.0 else Vector2(0, 0))
				_draw_ink_badge(font, badge_pos, "Rope", Color(0.16, 0.45, 0.38), Color(0.08, 0.24, 0.20), Color(0.96, 0.96, 0.86))

		var ridge_line := PackedVector2Array()
		for rp: Vector2 in [
			Vector2(540, 495), Vector2(770, 500), Vector2(1015, 480),
			Vector2(1018, 860), Vector2(1022, 1290), Vector2(1008, 1740), Vector2(1012, 2145)
		]:
			ridge_line.append(to_m.call(rp))
		draw_polyline(ridge_line, Color(0.30, 0.22, 0.16, 0.85), 2.5, true)
		for ri in range(ridge_line.size() - 1):
			var p0 := ridge_line[ri]
			var p1 := ridge_line[ri + 1]
			var slen := p0.distance_to(p1)
			var steps := maxi(2, int(slen / 16.0))
			for s in range(1, steps):
				var t := float(s) / float(steps)
				var q := p0.lerp(p1, t)
				draw_polyline(PackedVector2Array([q + Vector2(-4, 2), q + Vector2(0, -5), q + Vector2(4, 2)]), Color(0.28, 0.20, 0.14), 1.4)
				draw_line(q + Vector2(0, -4), q + Vector2(3, 2), Color(0.32, 0.24, 0.18, 0.65), 1.0)

		var nodes := [
			[Vector2(270, 1890), "crash", "Crash Ravine", Color(0.32, 0.24, 0.16), "", Vector2(-32, 16)],
			[Vector2(305, 1410), "hemlock", "Hemlock Clue", Color(0.32, 0.24, 0.16), "", Vector2(-36, 17)],
			[Vector2(845, 1285), "cart", "Shattered Cart", Color(0.45, 0.22, 0.16), "map_stamp_wreck.png", Vector2(-32, 20)],
			[Vector2(765, 1815), "fire0", "Fire 0", Color(0.76, 0.34, 0.12), "map_stamp_fire.png", Vector2(-14, 16)],
			[Vector2(265, 300), "hollow", "Obsidian Hollow", Color(0.22, 0.18, 0.28), "map_stamp_hollow.png", Vector2(-40, 19)],
			[Vector2(1110, 305), "cairn1", "Cairn I", Color(0.32, 0.28, 0.24), "", Vector2(-18, -12)],
			[Vector2(1635, 240), "frost_dead", "Frost Cliff\nDEAD END", Color(0.20, 0.42, 0.58), "map_stamp_crag.png", Vector2(-26, 17)],
			[Vector2(1185, 845), "fire1", "Split-Oak\nFire Alpha", Color(0.78, 0.34, 0.12), "map_stamp_fire.png", Vector2(-62, 6)],
			[Vector2(1720, 860), "boulder", "Two-Horn\nBoulder", Color(0.32, 0.28, 0.24), "", Vector2(8, 13)],
			[Vector2(1195, 1365), "patrol1", "Hunter\nBend", Color(0.68, 0.18, 0.18), "", Vector2(-22, 15)],
			[Vector2(1685, 1390), "cart_fork", "Old Cart\nFork", Color(0.55, 0.24, 0.18), "", Vector2(-42, 15)],
			[Vector2(2040, 1845), "cold_south", "Mist Brook\nDEAD END", Color(0.20, 0.42, 0.58), "map_stamp_crag.png", Vector2(-26, 16)],
			[Vector2(2110, 1315), "fire2", "Cairn II\nFire Beta", Color(0.78, 0.34, 0.12), "map_stamp_fire.png", Vector2(12, -4)],
			[Vector2(2565, 1790), "cold_east", "Briar Crag\nDEAD END", Color(0.20, 0.42, 0.58), "map_stamp_crag.png", Vector2(-26, 16)],
			[Vector2(2155, 700), "creek_winch", "Creek Winch", Color(0.16, 0.46, 0.38), "map_stamp_winch.png", Vector2(12, 4)],
			[Vector2(2165, 315), "causeway", "Ridge Watch", Color(0.68, 0.18, 0.18), "", Vector2(-34, -13)],
			[Vector2(2620, 255), "watchtower", "OUTPOST\nHEARTH", Color(0.16, 0.46, 0.26), "map_stamp_outpost.png", Vector2(-26, 19)]
		]
		for nd in nodes:
			var pt: Vector2 = to_m.call(nd[0])
			var nid: String = nd[1]
			var lbl: String = nd[2]
			var col: Color = nd[3]
			var stamp_name: String = nd[4]
			var loff: Vector2 = nd[5]
			if GameState.discovered_wilds_landmarks.has(nid):
				draw_circle(pt, 12.0, Color(0.92, 0.72, 0.24, 0.42))
				draw_arc(pt, 12.0, 0.0, TAU, 18, Color(0.56, 0.32, 0.08), 1.6)
			var stex: Texture2D = assets.get_tex(stamp_name) if (assets != null and stamp_name != "") else null
			if stex != null:
				var ssz := Vector2(stex.get_width(), stex.get_height())
				draw_texture_rect(stex, Rect2(pt - ssz * 0.5, ssz), false)
			else:
				draw_circle(pt, 5.2, Color(0.20, 0.14, 0.09))
				draw_circle(pt, 3.6, col)
			var llines := lbl.split("\n")
			for li in range(llines.size()):
				_draw_ink_text(font, pt + loff + Vector2(0, li * 10.5), llines[li], 10, Color(0.15, 0.10, 0.06))
