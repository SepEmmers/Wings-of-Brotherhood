extends HBoxContainer

## Character sheet & 12-slot oilskin satchel grid tab inside JournalModal.

const ItemCatalogScript := preload("res://scripts/data/ItemCatalog.gd")
const JournalLoreDataScript := preload("res://scripts/data/JournalLoreData.gd")

var assets
var inv_emblem_icon: TextureRect
var inv_char_title_lbl: Label
var inv_char_chapter_lbl: Label
var inv_portrait_rect: TextureRect
var inv_paperdoll_rect: TextureRect
var inv_vitals_lbl: Label
var inv_warmth_wrap: HBoxContainer
var inv_warmth_fill: ColorRect
var inv_warmth_pct_lbl: Label
var inv_equip_rows: Array = []
var inv_bag_header_lbl: Label
var inv_slot_entries: Array = []
var inv_detail_icon: TextureRect
var inv_detail_title: Label
var inv_detail_cat: Label
var inv_detail_desc: Label
var selected_inv_index: int = 0


func setup(assets_ref) -> void:
	assets = assets_ref
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)

	var char_panel := _build_char_column()
	add_child(char_panel)

	var bag_vbox := _build_bag_column()
	add_child(bag_vbox)


func _build_char_column() -> PanelContainer:
	var char_panel := PanelContainer.new()
	char_panel.custom_minimum_size = Vector2(268, 0)
	var char_sb := StyleBoxFlat.new()
	char_sb.bg_color = Color(0.08, 0.06, 0.09, 0.90)
	char_sb.border_color = Color(0.64, 0.49, 0.24, 0.85)
	char_sb.set_border_width_all(2)
	char_sb.set_content_margin_all(10)
	char_panel.add_theme_stylebox_override("panel", char_sb)

	var c_vbox := VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 8)
	char_panel.add_child(c_vbox)

	var c_title_row := HBoxContainer.new()
	c_title_row.add_theme_constant_override("separation", 6)
	c_vbox.add_child(c_title_row)

	inv_emblem_icon = TextureRect.new()
	inv_emblem_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inv_emblem_icon.custom_minimum_size = Vector2(20, 20)
	inv_emblem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inv_emblem_icon.texture = assets.get_tex("icon_brotherhood_emblem.png") if assets != null else null
	inv_emblem_icon.tooltip_text = "Secret Brotherhood of Dragon Riders"
	inv_emblem_icon.visible = false
	c_title_row.add_child(inv_emblem_icon)

	inv_char_title_lbl = Label.new()
	inv_char_title_lbl.text = "Bram (Age 12)"
	inv_char_title_lbl.add_theme_font_size_override("font_size", 16)
	inv_char_title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.50))
	c_title_row.add_child(inv_char_title_lbl)

	inv_char_chapter_lbl = Label.new()
	inv_char_chapter_lbl.text = "De Zwaan — Apprentice Deckhand"
	inv_char_chapter_lbl.add_theme_font_size_override("font_size", 11)
	inv_char_chapter_lbl.add_theme_color_override("font_color", Color(0.75, 0.84, 0.74))
	c_vbox.add_child(inv_char_chapter_lbl)

	var showcase_panel := PanelContainer.new()
	showcase_panel.custom_minimum_size = Vector2(0, 102)
	var show_sb := StyleBoxFlat.new()
	show_sb.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	show_sb.border_color = Color(0.42, 0.34, 0.22, 0.9)
	show_sb.set_border_width_all(1)
	show_sb.set_content_margin_all(8)
	showcase_panel.add_theme_stylebox_override("panel", show_sb)
	c_vbox.add_child(showcase_panel)

	var show_hbox := HBoxContainer.new()
	show_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	show_hbox.add_theme_constant_override("separation", 18)
	showcase_panel.add_child(show_hbox)

	var p_wrap := PanelContainer.new()
	p_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p_wrap.add_theme_stylebox_override("panel", assets.make_ui_9slice_style("ui_frame_portrait.png", 4.0, 6.0, 6.0))
	show_hbox.add_child(p_wrap)

	inv_portrait_rect = TextureRect.new()
	inv_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inv_portrait_rect.custom_minimum_size = Vector2(64, 64)
	inv_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inv_portrait_rect.texture = assets.get_tex("portrait_boy_neutral.png")
	p_wrap.add_child(inv_portrait_rect)

	var doll_box := Control.new()
	doll_box.custom_minimum_size = Vector2(72, 84)
	doll_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	show_hbox.add_child(doll_box)

	var doll_shadow := ColorRect.new()
	doll_shadow.color = Color(0.0, 0.0, 0.0, 0.45)
	doll_shadow.position = Vector2(12, 68)
	doll_shadow.size = Vector2(48, 8)
	doll_box.add_child(doll_shadow)

	inv_paperdoll_rect = TextureRect.new()
	inv_paperdoll_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inv_paperdoll_rect.position = Vector2(0, -2)
	inv_paperdoll_rect.size = Vector2(72, 84)
	inv_paperdoll_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inv_paperdoll_rect.texture = assets.get_tex("boy_down_0.png")
	doll_box.add_child(inv_paperdoll_rect)

	inv_vitals_lbl = Label.new()
	inv_vitals_lbl.add_theme_font_size_override("font_size", 12)
	inv_vitals_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
	c_vbox.add_child(inv_vitals_lbl)

	inv_warmth_wrap = HBoxContainer.new()
	inv_warmth_wrap.add_theme_constant_override("separation", 6)
	inv_warmth_wrap.visible = false
	c_vbox.add_child(inv_warmth_wrap)

	var w_lbl := Label.new()
	w_lbl.text = "Egg Heat:"
	w_lbl.add_theme_font_size_override("font_size", 11)
	w_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.44))
	inv_warmth_wrap.add_child(w_lbl)

	var w_track := Control.new()
	w_track.custom_minimum_size = Vector2(104, 12)
	w_track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inv_warmth_wrap.add_child(w_track)

	var w_bg := ColorRect.new()
	w_bg.color = Color(0.14, 0.10, 0.12)
	w_bg.size = Vector2(104, 10)
	w_track.add_child(w_bg)

	inv_warmth_fill = ColorRect.new()
	inv_warmth_fill.color = Color(0.95, 0.68, 0.24)
	inv_warmth_fill.position = Vector2(1, 1)
	inv_warmth_fill.size = Vector2(102, 8)
	w_track.add_child(inv_warmth_fill)

	inv_warmth_pct_lbl = Label.new()
	inv_warmth_pct_lbl.text = "100%"
	inv_warmth_pct_lbl.add_theme_font_size_override("font_size", 11)
	inv_warmth_pct_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.62))
	inv_warmth_wrap.add_child(inv_warmth_pct_lbl)

	var eq_hdr := Label.new()
	eq_hdr.text = "EQUIPPED GEAR & BOONS"
	eq_hdr.add_theme_font_size_override("font_size", 11)
	eq_hdr.add_theme_color_override("font_color", Color(0.84, 0.70, 0.38))
	c_vbox.add_child(eq_hdr)

	inv_equip_rows.clear()
	for _ei in range(3):
		var erow_panel := PanelContainer.new()
		var esb := StyleBoxFlat.new()
		esb.bg_color = Color(0.12, 0.10, 0.14, 0.92)
		esb.border_color = Color(0.45, 0.36, 0.22, 0.8)
		esb.set_border_width_all(1)
		esb.set_content_margin_all(5)
		erow_panel.add_theme_stylebox_override("panel", esb)
		c_vbox.add_child(erow_panel)

		var eh := HBoxContainer.new()
		eh.add_theme_constant_override("separation", 8)
		erow_panel.add_child(eh)

		var eicon := TextureRect.new()
		eicon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		eicon.custom_minimum_size = Vector2(28, 28)
		eicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		eh.add_child(eicon)

		var ev := VBoxContainer.new()
		ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ev.add_theme_constant_override("separation", 0)
		eh.add_child(ev)

		var etitle := Label.new()
		etitle.clip_text = true
		etitle.add_theme_font_size_override("font_size", 12)
		etitle.add_theme_color_override("font_color", Color(0.96, 0.88, 0.64))
		ev.add_child(etitle)

		var esub := Label.new()
		esub.clip_text = true
		esub.add_theme_font_size_override("font_size", 10)
		esub.add_theme_color_override("font_color", Color(0.74, 0.78, 0.72))
		ev.add_child(esub)

		inv_equip_rows.append({"icon": eicon, "title": etitle, "sub": esub})

	return char_panel


func _build_bag_column() -> VBoxContainer:
	var bag_vbox := VBoxContainer.new()
	bag_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_vbox.add_theme_constant_override("separation", 8)

	inv_bag_header_lbl = Label.new()
	inv_bag_header_lbl.text = "CARRIED SATCHEL & EVIDENCE (0 / 12 SLOTS)"
	inv_bag_header_lbl.add_theme_font_size_override("font_size", 12)
	inv_bag_header_lbl.add_theme_color_override("font_color", Color(0.92, 0.78, 0.44))
	bag_vbox.add_child(inv_bag_header_lbl)

	var slot_grid := GridContainer.new()
	slot_grid.columns = 4
	slot_grid.add_theme_constant_override("h_separation", 10)
	slot_grid.add_theme_constant_override("v_separation", 10)
	bag_vbox.add_child(slot_grid)

	inv_slot_entries.clear()
	var slot_tex: Texture2D = assets.get_tex("ui_slot_bg.png")
	for s_idx in range(12):
		var slot_root := Control.new()
		slot_root.custom_minimum_size = Vector2(96, 66)
		slot_grid.add_child(slot_root)

		var slot_bg := TextureRect.new()
		slot_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_bg.stretch_mode = TextureRect.STRETCH_SCALE
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_bg.texture = slot_tex
		slot_root.add_child(slot_bg)

		var slot_icon := TextureRect.new()
		slot_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot_icon.position = Vector2(28, 10)
		slot_icon.size = Vector2(40, 40)
		slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_root.add_child(slot_icon)

		var slot_badge := Label.new()
		slot_badge.position = Vector2(4, 48)
		slot_badge.size = Vector2(88, 15)
		slot_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_badge.clip_text = true
		slot_badge.add_theme_font_size_override("font_size", 10)
		slot_badge.add_theme_color_override("font_color", Color(0.88, 0.84, 0.72))
		slot_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_root.add_child(slot_badge)

		var sel_border := ReferenceRect.new()
		sel_border.set_anchors_preset(Control.PRESET_FULL_RECT)
		sel_border.editor_only = false
		sel_border.border_color = Color(0.98, 0.82, 0.34)
		sel_border.border_width = 2.0
		sel_border.visible = false
		sel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_root.add_child(sel_border)

		var slot_btn := Button.new()
		slot_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_btn.flat = true
		var cap_idx := s_idx
		slot_btn.pressed.connect(func():
			SoundManager.play_ui_click()
			selected_inv_index = cap_idx
			refresh()
		)
		slot_root.add_child(slot_btn)

		inv_slot_entries.append({
			"btn": slot_btn,
			"bg": slot_bg,
			"icon": slot_icon,
			"badge": slot_badge,
			"sel": sel_border,
		})

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var det_sb := StyleBoxFlat.new()
	det_sb.bg_color = Color(0.08, 0.06, 0.09, 0.90)
	det_sb.border_color = Color(0.64, 0.49, 0.24, 0.85)
	det_sb.set_border_width_all(2)
	det_sb.set_content_margin_all(10)
	detail_panel.add_theme_stylebox_override("panel", det_sb)
	bag_vbox.add_child(detail_panel)

	var det_h := HBoxContainer.new()
	det_h.add_theme_constant_override("separation", 12)
	detail_panel.add_child(det_h)

	var det_icon_box := PanelContainer.new()
	det_icon_box.custom_minimum_size = Vector2(64, 64)
	det_icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var di_sb := StyleBoxFlat.new()
	di_sb.bg_color = Color(0.14, 0.11, 0.16)
	di_sb.border_color = Color(0.70, 0.56, 0.28)
	di_sb.set_border_width_all(1)
	di_sb.set_content_margin_all(6)
	det_icon_box.add_theme_stylebox_override("panel", di_sb)
	det_h.add_child(det_icon_box)

	inv_detail_icon = TextureRect.new()
	inv_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inv_detail_icon.custom_minimum_size = Vector2(48, 48)
	inv_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	det_icon_box.add_child(inv_detail_icon)

	var det_v := VBoxContainer.new()
	det_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	det_v.add_theme_constant_override("separation", 4)
	det_h.add_child(det_v)

	inv_detail_title = Label.new()
	inv_detail_title.add_theme_font_size_override("font_size", 15)
	inv_detail_title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.52))
	det_v.add_child(inv_detail_title)

	inv_detail_cat = Label.new()
	inv_detail_cat.add_theme_font_size_override("font_size", 11)
	inv_detail_cat.add_theme_color_override("font_color", Color(0.68, 0.88, 0.72))
	det_v.add_child(inv_detail_cat)

	inv_detail_desc = Label.new()
	inv_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_detail_desc.add_theme_font_size_override("font_size", 12)
	inv_detail_desc.add_theme_color_override("font_color", Color(0.90, 0.88, 0.82))
	det_v.add_child(inv_detail_desc)

	return bag_vbox


func apply_slot_button_styles() -> void:
	var empty_sb := StyleBoxEmpty.new()
	for entry in inv_slot_entries:
		var b: Button = entry["btn"]
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(state, empty_sb)


func _get_carried_slot_list() -> Array:
	var out: Array = []
	if GameState.carrying_crate:
		out.append({"name": "Salt-Herring Crate", "badge": "HANDS"})
	for item_name in GameState.inventory:
		var sname := str(item_name)
		out.append({"name": sname, "badge": ItemCatalogScript.get_item_badge(sname)})
	return out


func select_item_by_name(item_name: String) -> void:
	var carried := _get_carried_slot_list()
	for i in range(carried.size()):
		if str(carried[i].get("name", "")) == item_name:
			selected_inv_index = i
			break
	refresh()


func refresh() -> void:
	if inv_char_title_lbl == null:
		return
	if inv_emblem_icon != null:
		if inv_emblem_icon.texture == null and assets != null:
			inv_emblem_icon.texture = assets.get_tex("icon_brotherhood_emblem.png")
		inv_emblem_icon.visible = GameState.current_step >= GameState.QuestStep.ACT2_SANCTUARY
	inv_char_title_lbl.text = "%s (Age %d)" % [GameState.player_name, GameState.boy_age]
	inv_char_chapter_lbl.text = JournalLoreDataScript.get_chapter_subtitle()

	var angry_phase := (GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA and GameState.current_step <= GameState.QuestStep.ACT2_SANCTUARY and GameState.sanctuary_phase == 1 and not GameState.virelai_harness_spliced)
	inv_portrait_rect.texture = assets.get_tex(GameState.get_boy_portrait(angry_phase))

	var doll_tex_name := "boy_down_0.png"
	if GameState.carrying_egg or GameState.sanctuary_carrying_item in ["water", "fish"]:
		doll_tex_name = "boy_cradle_hands_down_0.png"
	elif GameState.carrying_crate or GameState.sanctuary_carrying_item == "leather":
		doll_tex_name = "boy_carry_hands_down_0.png"
	if GameState.boy_age >= 17 or GameState.sanctuary_jerkin_earned:
		doll_tex_name = doll_tex_name.replace("boy_", "boy17_")
	elif GameState.boy_age >= 14 or GameState.sanctuary_phase >= 2:
		doll_tex_name = doll_tex_name.replace("boy_", "boy14_")
	inv_paperdoll_rect.texture = assets.get_tex(doll_tex_name, "boy_down_0.png")

	var hearts := ""
	for i in range(GameState.boy_max_hp):
		hearts += "♥" if i < GameState.boy_hp else "♡"
	var max_loops: int = 4 if GameState.clara_gift_received else 3
	var buffs: Array[String] = []
	if GameState.clara_gift_received:
		buffs.append("Beeswax")
	if GameState.sanctuary_drill_mastered:
		buffs.append("Topman Ring")
	var buff_str := " + ".join(buffs) if not buffs.is_empty() else "Apprentice Rig"
	inv_vitals_lbl.text = "Vigor: %s (%d/%d)  |  Loops: %d (%s)" % [hearts, GameState.boy_hp, GameState.boy_max_hp, max_loops, buff_str]

	inv_warmth_wrap.visible = GameState.carrying_egg
	if GameState.carrying_egg:
		var wpct := clampf(GameState.egg_warmth, 0.0, 100.0)
		inv_warmth_fill.size = Vector2(maxf(2.0, 102.0 * (wpct / 100.0)), 8.0)
		inv_warmth_fill.color = Color(0.95, 0.68, 0.24) if wpct >= 55.0 else Color(0.90, 0.28, 0.22)
		inv_warmth_pct_lbl.text = "%d%%" % int(round(wpct))

	var kd: Dictionary = GameState.KNOT_DATA[GameState.equipped_knot]
	inv_equip_rows[0]["icon"].texture = assets.get_tex("icon_knot.png")
	inv_equip_rows[0]["title"].text = kd["name"]
	inv_equip_rows[0]["sub"].text = "[Q] " + kd.get("ability_short", kd["throw_style"])

	inv_equip_rows[1]["icon"].texture = assets.get_tex("icon_knife.png" if not GameState.has_mariner_compass or GameState.current_step >= GameState.QuestStep.ACT2_SANCTUARY else "icon_compass.png")
	if GameState.has_mariner_compass:
		inv_equip_rows[1]["icon"].texture = assets.get_tex("icon_compass.png")
		inv_equip_rows[1]["title"].text = "Mariner's Brass Compass"
		inv_equip_rows[1]["sub"].text = "Dock Knife [V] + True Bearing Needle"
	else:
		inv_equip_rows[1]["title"].text = "Flemish Dock Knife [V]"
		inv_equip_rows[1]["sub"].text = "Quick slash for ropes, briars & crossbows"

	if GameState.has_forest_map:
		inv_equip_rows[2]["icon"].texture = assets.get_tex("icon_map.png")
		inv_equip_rows[2]["title"].text = "Outpost Field Chart [M]"
		inv_equip_rows[2]["sub"].text = "%d Frontier landmarks plotted" % GameState.discovered_wilds_landmarks.size()
	elif GameState.clara_gift_received:
		inv_equip_rows[2]["icon"].texture = assets.get_tex("icon_beeswax_thimble.png")
		inv_equip_rows[2]["title"].text = "Louvain Beeswax & Thimble"
		inv_equip_rows[2]["sub"].text = "+1 Loop, +25% Gold Zone, +20% Range"
	else:
		inv_equip_rows[2]["icon"].texture = assets.get_tex("icon_hemp_bundle.png")
		inv_equip_rows[2]["title"].text = "Oilskin Dock Satchel"
		inv_equip_rows[2]["sub"].text = "%d / 4 knots unlocked" % GameState.unlocked_knots.size()

	var carried := _get_carried_slot_list()
	inv_bag_header_lbl.text = "CARRIED SATCHEL & EVIDENCE (%d / 12 SLOTS)" % carried.size()
	if selected_inv_index >= carried.size() and carried.size() > 0:
		selected_inv_index = 0
	selected_inv_index = clampi(selected_inv_index, 0, 11)

	for i in range(12):
		var slot: Dictionary = inv_slot_entries[i]
		slot["sel"].visible = (i == selected_inv_index)
		if i < carried.size():
			var item_entry: Dictionary = carried[i]
			var iname: String = item_entry["name"]
			var meta: Dictionary = ItemCatalogScript.get_item_info(iname)
			slot["bg"].modulate = Color(1.0, 1.0, 1.0, 1.0)
			slot["icon"].texture = assets.get_tex(meta["icon"], "icon_knot.png")
			slot["icon"].visible = true
			slot["badge"].text = item_entry["badge"]
		else:
			slot["bg"].modulate = Color(0.76, 0.72, 0.68, 0.55)
			slot["icon"].texture = null
			slot["icon"].visible = false
			slot["badge"].text = ""

	if selected_inv_index < carried.size():
		var sel_name: String = carried[selected_inv_index]["name"]
		var smeta: Dictionary = ItemCatalogScript.get_item_info(sel_name)
		inv_detail_icon.texture = assets.get_tex(smeta["icon"], "icon_knot.png")
		inv_detail_icon.modulate = Color(1, 1, 1, 1)
		inv_detail_title.text = sel_name
		inv_detail_cat.text = smeta["category"]
		inv_detail_desc.text = smeta["desc"]
	else:
		inv_detail_icon.texture = assets.get_tex("icon_knot.png")
		inv_detail_icon.modulate = Color(1, 1, 1, 0.45)
		inv_detail_title.text = "Empty Satchel Pocket"
		inv_detail_cat.text = "Available Storage"
		inv_detail_desc.text = "Pick up tools, dock supplies, Ropewalk clues, or Brotherhood gear during your journey to inspect them here."
