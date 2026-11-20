class_name ItemAcquireBanner
extends Control

## Zelda Ocarina of Time-style item acquisition fanfare banner with rotating golden
## sunburst, item icon + title + short caption, and [I] shortcut to inspect in Bag.

const ItemCatalogScript := preload("res://scripts/data/ItemCatalog.gd")

signal open_inventory_requested(item_name: String)
signal dismissed

var assets = null
var _sunburst: TextureRect
var _icon: TextureRect
var _title_lbl: Label
var _cat_lbl: Label
var _desc_lbl: Label
var _hint_lbl: Label
var _current_item: String = ""
var _spin_t: float = 0.0
var _pop_t: float = 0.0


func setup(p_assets) -> void:
	assets = p_assets
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.04, 0.42)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_backdrop_input)
	add_child(backdrop)

	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor.offset_left = -290
	anchor.offset_right = 290
	anchor.offset_top = -310
	anchor.offset_bottom = -36
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)

	var sunburst_wrap := Control.new()
	sunburst_wrap.position = Vector2(218, -14)
	sunburst_wrap.custom_minimum_size = Vector2(144, 144)
	sunburst_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(sunburst_wrap)

	_sunburst = TextureRect.new()
	_sunburst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sunburst.custom_minimum_size = Vector2(144, 144)
	_sunburst.size = Vector2(144, 144)
	_sunburst.pivot_offset = Vector2(72, 72)
	_sunburst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sunburst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if assets != null:
		_sunburst.texture = assets.get_tex("ui_oot_sunburst.png")
	sunburst_wrap.add_child(_sunburst)

	_icon = TextureRect.new()
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.position = Vector2(44, 44)
	_icon.custom_minimum_size = Vector2(56, 56)
	_icon.size = Vector2(56, 56)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sunburst_wrap.add_child(_icon)

	var card := PanelContainer.new()
	card.position = Vector2(0, 118)
	card.custom_minimum_size = Vector2(580, 148)
	card.size = Vector2(580, 148)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb: StyleBox = assets.make_ui_9slice_style("ui_panel_9slice.png", 14.0, 20.0, 16.0) if assets != null else null
	if sb != null:
		card.add_theme_stylebox_override("panel", sb)
	anchor.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vb)

	var got_lbl := Label.new()
	got_lbl.text = "ITEM OBTAINED"
	got_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	got_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	got_lbl.add_theme_font_size_override("font_size", 11)
	got_lbl.add_theme_color_override("font_color", Color(0.76, 0.86, 0.72))
	vb.add_child(got_lbl)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_title_lbl.add_theme_font_size_override("font_size", 19)
	_title_lbl.add_theme_color_override("font_color", Color(0.98, 0.84, 0.44))
	vb.add_child(_title_lbl)

	_cat_lbl = Label.new()
	_cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cat_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_cat_lbl.add_theme_font_size_override("font_size", 11)
	_cat_lbl.add_theme_color_override("font_color", Color(0.70, 0.86, 0.90))
	vb.add_child(_cat_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_desc_lbl.add_theme_font_size_override("font_size", 12)
	_desc_lbl.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84))
	vb.add_child(_desc_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.text = "Press [I] to inspect in Bag  •  [E / Space / Click] Continue"
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_hint_lbl.add_theme_font_size_override("font_size", 11)
	_hint_lbl.add_theme_color_override("font_color", Color(0.84, 0.78, 0.62))
	vb.add_child(_hint_lbl)


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dismiss()


func show_item(item_name: String) -> void:
	_current_item = item_name
	_spin_t = 0.0
	_pop_t = 0.0
	var meta: Dictionary = ItemCatalogScript.get_item_info(item_name)
	if assets != null:
		_icon.texture = assets.get_tex(meta.get("icon", "icon_knot.png"), "icon_knot.png")
	_title_lbl.text = item_name
	_cat_lbl.text = str(meta.get("category", "Satchel Item"))
	_desc_lbl.text = str(meta.get("desc", ""))
	visible = true
	SoundManager.play_blip(1.42)


func step_banner(delta: float) -> void:
	if not visible:
		return
	_spin_t += delta
	_pop_t = minf(1.0, _pop_t + delta * 4.5)
	if _sunburst != null:
		_sunburst.rotation = _spin_t * 0.85
		var pulse := 0.92 + 0.08 * sin(_spin_t * 4.0)
		_sunburst.scale = Vector2(pulse, pulse) * (0.75 + 0.25 * _pop_t)


func open_in_bag() -> void:
	if not visible:
		return
	var target := _current_item
	visible = false
	SoundManager.play_ui_click()
	emit_signal("open_inventory_requested", target)


func dismiss() -> void:
	if not visible:
		return
	visible = false
	SoundManager.play_ui_click()
	emit_signal("dismissed")
