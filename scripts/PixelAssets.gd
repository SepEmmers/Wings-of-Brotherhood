extends RefCounted

const ItemCatalogScript := preload("res://scripts/data/ItemCatalog.gd")

## Shared palette-locked pixel-art texture cache, 9-slice medieval UI stylers,
## atmospheric particle pools, and top-down tile/seam/prop rendering helpers.

class _WorldTextOverlay extends Node2D:
	var commands: Array[Dictionary] = []

	func _draw() -> void:
		for cmd in commands:
			var font: Font = cmd["font"]
			var pos: Vector2 = cmd["pos"]
			var text_str: String = cmd["text"]
			var fsize: int = cmd["size"]
			var col: Color = cmd["col"]
			draw_string(font, pos + Vector2(1, 2), text_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.02, 0.02, 0.04, 0.88))
			draw_string(font, pos, text_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)


var tex: Dictionary = {}
var _scaled_tex_cache: Dictionary = {}
var _flipped_tex_cache: Dictionary = {}
var _npc_shadow_tex: Texture2D
var _ui_font: SystemFont
var _world_text_active: Dictionary = {}
var _world_text_pending: Dictionary = {}
var smoke_puffs: Array[Dictionary] = []
var spark_particles: Array[Dictionary] = []
var time_elapsed: float = 0.0


func _init() -> void:
	_init_ui_font()
	_load_pixel_textures()
	_build_npc_shadow_tex()
	_init_atmosphere_particles()


func _init_ui_font() -> void:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Noto Sans", "DejaVu Sans", "Liberation Sans", "Arial"])
	sf.multichannel_signed_distance_field = true
	sf.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	_ui_font = sf


func get_ui_font() -> Font:
	if _ui_font == null:
		_init_ui_font()
	return _ui_font


func _resolve_ui_font(font: Font) -> Font:
	if font != null and font != ThemeDB.fallback_font:
		return font
	return get_ui_font()


func _build_npc_shadow_tex() -> void:
	var img := Image.create(24, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		for x in range(24):
			var nx := (float(x) + 0.5 - 12.0) / 10.5
			var ny := (float(y) + 0.5 - 4.0) / 3.2
			var d2 := nx * nx + ny * ny
			if d2 <= 0.56:
				img.set_pixel(x, y, Color(0.03, 0.03, 0.06, 0.56))
			elif d2 <= 1.0:
				img.set_pixel(x, y, Color(0.04, 0.04, 0.07, 0.24))
	_npc_shadow_tex = ImageTexture.create_from_image(img)


func _load_pixel_textures() -> void:
	var dir_path := "res://assets/sprites"
	var files := DirAccess.get_files_at(dir_path)
	if files.is_empty():
		files = DirAccess.get_files_at(ProjectSettings.globalize_path(dir_path))
	for fname in files:
		if not fname.ends_with(".png"):
			continue
		var abs_path := ProjectSettings.globalize_path(dir_path + "/" + fname)
		var img := Image.load_from_file(abs_path)
		if img != null:
			tex[fname] = ImageTexture.create_from_image(img)


func get_tex(fname: String, fallback: String = "") -> Texture2D:
	var t: Texture2D = tex.get(fname)
	if t == null and fallback != "":
		t = tex.get(fallback)
	return t


func get_tex_flipped(fname: String, fallback: String = "") -> Texture2D:
	var key := fname if tex.has(fname) else fallback
	var cached: Texture2D = _flipped_tex_cache.get(key)
	if cached != null:
		return cached
	var base: Texture2D = get_tex(fname, fallback)
	if base == null:
		return null
	var img: Image = base.get_image()
	if img == null or img.is_empty():
		return base
	var copy_img: Image = img.duplicate()
	copy_img.flip_x()
	var ftex := ImageTexture.create_from_image(copy_img)
	_flipped_tex_cache[key] = ftex
	return ftex


func _init_atmosphere_particles() -> void:
	smoke_puffs.clear()
	spark_particles.clear()
	for i in range(18):
		smoke_puffs.append({
			"phase": float(i) / 18.0,
			"drift": randf_range(-10.0, 12.0),
			"size": randf_range(5.0, 11.0),
			"source": i % 2
		})
	for i in range(28):
		spark_particles.append({
			"phase": float(i) / 28.0,
			"dx": randf_range(-16.0, 16.0),
			"speed": randf_range(0.35, 0.75),
			"color_idx": i % 3
		})


func make_point_light(pos: Vector2, scale_val: float, col: Color, energy_val: float) -> PointLight2D:
	var pl := PointLight2D.new()
	pl.texture = tex.get("light_radial.png")
	pl.position = pos
	pl.texture_scale = scale_val
	pl.color = col
	pl.energy = energy_val
	return pl


func make_ui_9slice_style(tex_name: String, tex_margin: float, pad_h: float, pad_v: float) -> StyleBox:
	var ui_tex: Texture2D = tex.get(tex_name)
	if ui_tex != null:
		var sbt := StyleBoxTexture.new()
		sbt.texture = ui_tex
		sbt.texture_margin_left = tex_margin
		sbt.texture_margin_top = tex_margin
		sbt.texture_margin_right = tex_margin
		sbt.texture_margin_bottom = tex_margin
		sbt.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sbt.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sbt.content_margin_left = pad_h
		sbt.content_margin_right = pad_h
		sbt.content_margin_top = pad_v
		sbt.content_margin_bottom = pad_v
		return sbt
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.13, 0.96)
	sb.border_color = Color(0.76, 0.58, 0.30, 0.98)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


func style_parchment_panel(panel: PanelContainer, compact: bool = false) -> void:
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if compact:
		panel.add_theme_stylebox_override("panel", make_ui_9slice_style("ui_hud_9slice.png", 8.0, 14.0, 10.0))
	else:
		panel.add_theme_stylebox_override("panel", make_ui_9slice_style("ui_panel_9slice.png", 12.0, 20.0, 16.0))


func style_hslider(slider: HSlider) -> void:
	slider.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var grab: Texture2D = tex.get("ui_slider_grabber.png")
	var grab_hi: Texture2D = tex.get("ui_slider_grabber_hi.png")
	if grab != null:
		slider.add_theme_icon_override("grabber", grab)
		slider.add_theme_icon_override("grabber_disabled", grab)
	if grab_hi != null:
		slider.add_theme_icon_override("grabber_highlight", grab_hi)
	if tex.has("ui_slider_rail.png"):
		slider.add_theme_stylebox_override("slider", make_ui_9slice_style("ui_slider_rail.png", 4.0, 2.0, 5.0))
	if tex.has("ui_slider_fill.png"):
		var fill_sb := make_ui_9slice_style("ui_slider_fill.png", 4.0, 2.0, 5.0)
		slider.add_theme_stylebox_override("grabber_area", fill_sb)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill_sb)


func style_vscrollbar(scroll: ScrollContainer) -> void:
	var vsb := scroll.get_v_scroll_bar()
	if vsb == null:
		return
	vsb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vsb.custom_minimum_size = Vector2(14, 0)
	if tex.has("ui_scroll_rail_9slice.png"):
		vsb.add_theme_stylebox_override("scroll", make_ui_9slice_style("ui_scroll_rail_9slice.png", 5.0, 3.0, 3.0))
	if tex.has("ui_scroll_grabber_9slice.png"):
		var grab_sb := make_ui_9slice_style("ui_scroll_grabber_9slice.png", 5.0, 3.0, 3.0)
		vsb.add_theme_stylebox_override("grabber", grab_sb)
		vsb.add_theme_stylebox_override("grabber_highlight", grab_sb)
		vsb.add_theme_stylebox_override("grabber_pressed", grab_sb)


func style_buttons_recursive(root_node: Node) -> void:
	for child in root_node.get_children():
		if child is Button:
			var b := child as Button
			b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			var normal := make_ui_9slice_style("ui_btn_normal.png", 6.0, 14.0, 6.0)
			var hover := make_ui_9slice_style("ui_btn_hover.png", 6.0, 14.0, 6.0)
			var pressed := make_ui_9slice_style("ui_btn_pressed.png", 6.0, 14.0, 6.0)
			b.add_theme_stylebox_override("normal", normal)
			b.add_theme_stylebox_override("hover", hover)
			b.add_theme_stylebox_override("pressed", pressed)
			b.add_theme_stylebox_override("focus", hover)
			b.add_theme_color_override("font_color", Color(0.95, 0.89, 0.74))
			b.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82))
			b.add_theme_color_override("font_pressed_color", Color(0.86, 0.76, 0.56))
			b.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.04, 0.88))
			b.add_theme_constant_override("shadow_offset_x", 1)
			b.add_theme_constant_override("shadow_offset_y", 2)
		elif child is HSlider:
			style_hslider(child as HSlider)
		elif child is ScrollContainer:
			style_vscrollbar(child as ScrollContainer)
		elif child is LineEdit:
			var le := child as LineEdit
			le.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			var le_sb := StyleBoxFlat.new()
			le_sb.bg_color = Color(0.07, 0.06, 0.09, 0.96)
			le_sb.border_color = Color(0.72, 0.55, 0.28, 0.95)
			le_sb.set_border_width_all(2)
			le_sb.content_margin_left = 10
			le_sb.content_margin_right = 10
			le_sb.content_margin_top = 6
			le_sb.content_margin_bottom = 6
			var le_focus := le_sb.duplicate()
			le_focus.border_color = Color(0.96, 0.82, 0.48, 1.0)
			le.add_theme_stylebox_override("normal", le_sb)
			le.add_theme_stylebox_override("focus", le_focus)
			le.add_theme_color_override("font_color", Color(0.97, 0.92, 0.78))
		elif child is RichTextLabel:
			(child as RichTextLabel).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		elif child is Label:
			var lbl := child as Label
			lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, 0.85))
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 2)
		style_buttons_recursive(child)


func draw_tiled_rect(canvas: Node2D, region: Rect2, tile_tex: Texture2D, tile_px: float = 32.0) -> void:
	if tile_tex == null:
		return
	var y := region.position.y
	while y < region.end.y:
		var x := region.position.x
		while x < region.end.x:
			var w := minf(tile_px, region.end.x - x)
			var h := minf(tile_px, region.end.y - y)
			canvas.draw_texture_rect(tile_tex, Rect2(x, y, w, h), false)
			x += tile_px
		y += tile_px


func tile_hash(col: int, row: int, seed_val: int = 0) -> int:
	var n: int = ((col * 73856093) ^ (row * 19349663) ^ (seed_val * 83492791)) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1103515245) & 0x7fffffff
	return (n ^ (n >> 16)) & 0x7fffffff


func draw_varied_tiled_rect(canvas: Node2D, region: Rect2, tex_a: Texture2D, tex_b: Texture2D, tile_px: float = 32.0, mod_seed: int = 5, tex_c: Texture2D = null) -> void:
	if tex_a == null:
		return
	var row := int(floor(region.position.y / tile_px))
	var y := region.position.y
	while y < region.end.y:
		var col := int(floor(region.position.x / tile_px))
		var x := region.position.x
		while x < region.end.x:
			var w := minf(tile_px, region.end.x - x)
			var h := minf(tile_px, region.end.y - y)
			var hval := tile_hash(col, row, mod_seed) % 100
			var chosen: Texture2D = tex_a
			if tex_c != null:
				if hval >= 82:
					chosen = tex_c
				elif hval >= 54 and tex_b != null:
					chosen = tex_b
			elif hval >= 68 and tex_b != null:
				chosen = tex_b
			if w < tile_px or h < tile_px:
				var tw := float(chosen.get_width())
				var th := float(chosen.get_height())
				canvas.draw_texture_rect_region(chosen, Rect2(x, y, w, h), Rect2(0.0, 0.0, w * tw / tile_px, h * th / tile_px))
			else:
				canvas.draw_texture_rect(chosen, Rect2(x, y, w, h), false)
			x += tile_px
			col += 1
		y += tile_px
		row += 1


func point_in_rects(pt: Vector2, rects: Array) -> bool:
	for r: Rect2 in rects:
		if r.has_point(pt):
			return true
	return false


func draw_seam_run_h(canvas: Node2D, tex_name: String, x_start: float, x_end: float, y_border: float) -> void:
	var etex: Texture2D = tex.get(tex_name)
	if etex == null or x_end <= x_start:
		return
	var x: float = x_start
	while x < x_end:
		var w: float = minf(16.0, x_end - x)
		var src_x: float = float((int(floor(x / 16.0)) & 1) * 8)
		canvas.draw_texture_rect_region(etex, Rect2(x, y_border - 16.0, w, 32.0), Rect2(src_x, 0.0, w * 0.5, 16.0))
		x += 16.0


func draw_seam_run_v(canvas: Node2D, tex_name: String, y_start: float, y_end: float, x_border: float) -> void:
	var etex: Texture2D = tex.get(tex_name)
	if etex == null or y_end <= y_start:
		return
	var y: float = y_start
	while y < y_end:
		var h: float = minf(16.0, y_end - y)
		var src_y: float = float((int(floor(y / 16.0)) & 1) * 8)
		canvas.draw_texture_rect_region(etex, Rect2(x_border - 16.0, y, 32.0, h), Rect2(0.0, src_y, 16.0, h * 0.5))
		y += 16.0


func draw_grass_scatters(canvas: Node2D, region: Rect2, seed_val: int, exclude_zones: Array = []) -> void:
	var wf0: Texture2D = tex.get("decal_wildflower_0.png")
	var wf1: Texture2D = tex.get("decal_wildflower_1.png")
	var tuft: Texture2D = tex.get("decal_grass_tuft.png")
	var row := int(floor(region.position.y / 32.0))
	var y := region.position.y + 8.0
	while y < region.end.y - 24.0:
		var col := int(floor(region.position.x / 32.0))
		var x := region.position.x + 8.0
		while x < region.end.x - 24.0:
			var jx := float(tile_hash(col, row, seed_val + 17) % 13) - 6.0
			var jy := float(tile_hash(col, row, seed_val + 31) % 13) - 6.0
			var pos := Vector2(x + jx, y + jy)
			if not point_in_rects(pos, exclude_zones):
				var h := tile_hash(col, row, seed_val + 91) % 64
				if h == 3 and wf0 != null:
					canvas.draw_texture_rect(wf0, Rect2(pos, Vector2(24, 24)), false)
				elif h == 19 and wf1 != null:
					canvas.draw_texture_rect(wf1, Rect2(pos, Vector2(24, 24)), false)
				elif (h == 37 or h == 53) and tuft != null:
					canvas.draw_texture_rect(tuft, Rect2(pos, Vector2(24, 24)), false)
			x += 32.0
			col += 1
		y += 32.0
		row += 1


func draw_grass_zone(canvas: Node2D, region: Rect2, draw_stone_seam: bool, seed_val: int, exclude_scatters: Array = []) -> void:
	draw_varied_tiled_rect(canvas, region, tex.get("tile_grass.png"), tex.get("tile_grass_2.png"), 32.0, seed_val, tex.get("tile_grass_3.png"))
	draw_grass_scatters(canvas, region, seed_val, exclude_scatters)
	if not draw_stone_seam:
		return
	var x0 := region.position.x
	var y0 := region.position.y
	var x1 := region.end.x
	var y1 := region.end.y
	draw_seam_run_h(canvas, "edge_grass_stone_n.png", x0 + 16.0, x1 - 16.0, y0)
	draw_seam_run_h(canvas, "edge_grass_stone_s.png", x0 + 16.0, x1 - 16.0, y1)
	draw_seam_run_v(canvas, "edge_grass_stone_w.png", y0 + 16.0, y1 - 16.0, x0)
	draw_seam_run_v(canvas, "edge_grass_stone_e.png", y0 + 16.0, y1 - 16.0, x1)
	for c_info in [
		["edge_grass_stone_nw.png", Vector2(x0 - 16.0, y0 - 16.0)],
		["edge_grass_stone_ne.png", Vector2(x1 - 16.0, y0 - 16.0)],
		["edge_grass_stone_sw.png", Vector2(x0 - 16.0, y1 - 16.0)],
		["edge_grass_stone_se.png", Vector2(x1 - 16.0, y1 - 16.0)]
	]:
		var ctex: Texture2D = tex.get(c_info[0])
		if ctex != null:
			canvas.draw_texture_rect(ctex, Rect2(c_info[1], Vector2(32, 32)), false)


func draw_stone_clearing_in_grass(canvas: Node2D, region: Rect2, seed_val: int) -> void:
	draw_varied_tiled_rect(canvas, region, tex.get("tile_cobble.png"), tex.get("tile_cobble_2.png"), 32.0, seed_val)
	var x0 := region.position.x
	var y0 := region.position.y
	var x1 := region.end.x
	var y1 := region.end.y
	draw_seam_run_h(canvas, "edge_grass_stone_s.png", x0, x1, y0)
	draw_seam_run_h(canvas, "edge_grass_stone_n.png", x0, x1, y1)
	draw_seam_run_v(canvas, "edge_grass_stone_e.png", y0, y1, x0)
	draw_seam_run_v(canvas, "edge_grass_stone_w.png", y0, y1, x1)
	var tuft: Texture2D = tex.get("decal_grass_tuft.png")
	var peb: Texture2D = tex.get("decal_pebbles_0.png")
	for corner in [Vector2(x0, y0), Vector2(x1, y0), Vector2(x0, y1), Vector2(x1, y1)]:
		if tuft != null:
			canvas.draw_texture_rect(tuft, Rect2(corner - Vector2(12, 12), Vector2(24, 24)), false)
		if peb != null:
			canvas.draw_texture_rect(peb, Rect2(corner - Vector2(10, 10), Vector2(20, 20)), false)


func draw_dirt_trail_network(canvas: Node2D, segments: Array, stone_zones: Array = [], exclude_zones: Array = [], seed_val: int = 11) -> void:
	var dirt_tex: Texture2D = tex.get("tile_dirt_path.png")
	var peb0: Texture2D = tex.get("decal_pebbles_0.png")
	var peb1: Texture2D = tex.get("decal_pebbles_1.png")
	for seg: Rect2 in segments:
		draw_tiled_rect(canvas, seg, dirt_tex, 32.0)
		var sy := seg.position.y + 8.0
		while sy < seg.end.y - 20.0:
			var sx := seg.position.x + 8.0
			while sx < seg.end.x - 20.0:
				var h := tile_hash(int(sx / 24.0), int(sy / 24.0), seed_val) % 29
				if h == 5 and peb0 != null:
					canvas.draw_texture_rect(peb0, Rect2(sx, sy, 20, 20), false)
				elif h == 17 and peb1 != null:
					canvas.draw_texture_rect(peb1, Rect2(sx, sy, 20, 20), false)
				sx += 28.0
			sy += 28.0

	var blocked: Array = []
	blocked.append_array(segments)
	blocked.append_array(exclude_zones)

	for seg: Rect2 in segments:
		var x0 := seg.position.x
		var y0 := seg.position.y
		var x1 := seg.end.x
		var y1 := seg.end.y

		var x := x0
		while x < x1:
			var w := minf(16.0, x1 - x)
			var mid_x := x + w * 0.5
			var src_x := float((int(floor(x / 16.0)) & 1) * 8)
			var n_pt := Vector2(mid_x, y0 - 4.0)
			if not point_in_rects(n_pt, blocked):
				var npfx := "edge_dirt_stone" if point_in_rects(n_pt, stone_zones) else "edge_dirt_grass"
				var ntex: Texture2D = tex.get("%s_n.png" % npfx)
				if ntex != null:
					canvas.draw_texture_rect_region(ntex, Rect2(x, y0 - 16.0, w, 32.0), Rect2(src_x, 0.0, w * 0.5, 16.0))
			var s_pt := Vector2(mid_x, y1 + 4.0)
			if not point_in_rects(s_pt, blocked):
				var spfx := "edge_dirt_stone" if point_in_rects(s_pt, stone_zones) else "edge_dirt_grass"
				var stex: Texture2D = tex.get("%s_s.png" % spfx)
				if stex != null:
					canvas.draw_texture_rect_region(stex, Rect2(x, y1 - 16.0, w, 32.0), Rect2(src_x, 0.0, w * 0.5, 16.0))
			x += 16.0

		var y := y0
		while y < y1:
			var h := minf(16.0, y1 - y)
			var mid_y := y + h * 0.5
			var src_y := float((int(floor(y / 16.0)) & 1) * 8)
			var w_pt := Vector2(x0 - 4.0, mid_y)
			if not point_in_rects(w_pt, blocked):
				var wpfx := "edge_dirt_stone" if point_in_rects(w_pt, stone_zones) else "edge_dirt_grass"
				var wtex: Texture2D = tex.get("%s_w.png" % wpfx)
				if wtex != null:
					canvas.draw_texture_rect_region(wtex, Rect2(x0 - 16.0, y, 32.0, h), Rect2(0.0, src_y, 16.0, h * 0.5))
			var e_pt := Vector2(x1 + 4.0, mid_y)
			if not point_in_rects(e_pt, blocked):
				var epfx := "edge_dirt_stone" if point_in_rects(e_pt, stone_zones) else "edge_dirt_grass"
				var etex: Texture2D = tex.get("%s_e.png" % epfx)
				if etex != null:
					canvas.draw_texture_rect_region(etex, Rect2(x1 - 16.0, y, 32.0, h), Rect2(0.0, src_y, 16.0, h * 0.5))
			y += 16.0

		for c_def in [
			["nw", Vector2(x0, y0), Vector2(-6, -6), Vector2(-6, 6), Vector2(6, -6)],
			["ne", Vector2(x1, y0), Vector2(6, -6), Vector2(6, 6), Vector2(-6, -6)],
			["sw", Vector2(x0, y1), Vector2(-6, 6), Vector2(-6, -6), Vector2(6, 6)],
			["se", Vector2(x1, y1), Vector2(6, 6), Vector2(6, -6), Vector2(-6, 6)]
		]:
			var cp: Vector2 = c_def[1]
			var od: Vector2 = cp + c_def[2]
			var oa: Vector2 = cp + c_def[3]
			var ob: Vector2 = cp + c_def[4]
			if not point_in_rects(od, blocked) and not point_in_rects(oa, blocked) and not point_in_rects(ob, blocked):
				var cpfx := "edge_dirt_stone" if point_in_rects(od, stone_zones) else "edge_dirt_grass"
				var ctex: Texture2D = tex.get("%s_%s.png" % [cpfx, c_def[0]])
				if ctex != null:
					canvas.draw_texture_rect(ctex, Rect2(cp - Vector2(16, 16), Vector2(32, 32)), false)


func draw_wharf_curb_seam(canvas: Node2D, x_seam: float, y_start: float, y_end: float) -> void:
	canvas.draw_rect(Rect2(x_seam - 2.0, y_start, 3.0, y_end - y_start), Color(0.14, 0.10, 0.08, 0.85))
	canvas.draw_rect(Rect2(x_seam + 1.0, y_start, 4.0, y_end - y_start), Color(0.04, 0.04, 0.06, 0.34))
	canvas.draw_rect(Rect2(x_seam + 5.0, y_start, 4.0, y_end - y_start), Color(0.05, 0.05, 0.08, 0.14))


func begin_world_text_pass(canvas: Node2D) -> void:
	if canvas == null or not is_instance_valid(canvas):
		return
	var cid := canvas.get_instance_id()
	_world_text_active[cid] = true
	var arr: Array[Dictionary] = []
	_world_text_pending[cid] = arr


func flush_world_text_pass(canvas: Node2D) -> void:
	if canvas == null or not is_instance_valid(canvas):
		return
	var cid := canvas.get_instance_id()
	_world_text_active.erase(cid)
	var cmds: Array[Dictionary] = _world_text_pending.get(cid, [] as Array[Dictionary])
	_world_text_pending.erase(cid)
	var ov := canvas.get_node_or_null("_WorldTextOverlay") as _WorldTextOverlay
	if cmds.is_empty() and ov == null:
		return
	if ov == null:
		ov = _WorldTextOverlay.new()
		ov.name = "_WorldTextOverlay"
		ov.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		ov.z_as_relative = true
		ov.z_index = 1
		canvas.add_child(ov)
	if not _world_text_cmds_equal(ov.commands, cmds):
		ov.commands = cmds
		ov.queue_redraw()


func _world_text_cmds_equal(a: Array[Dictionary], b: Array[Dictionary]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		var ca := a[i]
		var cb := b[i]
		if int(ca["size"]) != int(cb["size"]) or ca["text"] != cb["text"] or ca["font"] != cb["font"] or ca["col"] != cb["col"]:
			return false
		if not (ca["pos"] as Vector2).is_equal_approx(cb["pos"] as Vector2):
			return false
	return true


func draw_label_shadowed(canvas: Node2D, pos: Vector2, text_str: String, font: Font, font_size: int, col: Color, centered: bool = false) -> void:
	var use_font := _resolve_ui_font(font)
	var draw_pos := pos
	if centered and use_font != null:
		var tsize := use_font.get_string_size(text_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_pos.x -= tsize.x * 0.5
	var cid := canvas.get_instance_id()
	if _world_text_active.has(cid):
		var pending: Array[Dictionary] = _world_text_pending[cid]
		pending.append({
			"pos": draw_pos,
			"text": text_str,
			"font": use_font,
			"size": font_size,
			"col": col,
		})
		return
	canvas.draw_string(use_font, draw_pos + Vector2(1, 2), text_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.02, 0.02, 0.04, 0.88))
	canvas.draw_string(use_font, draw_pos, text_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


func animated_water_tex() -> Texture2D:
	var frame := (int(time_elapsed * 3.6) % 4) + 1
	return tex.get("tile_water_%d.png" % frame, tex.get("tile_water_1.png"))


func get_scaled_tile_tex(fname: String, tile_px: int) -> Texture2D:
	var key := "%s@%d" % [fname, tile_px]
	var cached: Texture2D = _scaled_tex_cache.get(key)
	if cached != null:
		return cached
	var base_tex: Texture2D = tex.get(fname)
	if base_tex == null:
		return null
	if base_tex.get_width() == tile_px and base_tex.get_height() == tile_px:
		_scaled_tex_cache[key] = base_tex
		return base_tex
	var img: Image = base_tex.get_image().duplicate()
	img.resize(tile_px, tile_px, Image.INTERPOLATE_NEAREST)
	cached = ImageTexture.create_from_image(img)
	_scaled_tex_cache[key] = cached
	return cached


## Draws an animated water rectangle using a single hardware-repeated quad (1 draw call).
func draw_water_rect(canvas: Node2D, rect: Rect2, tile_px: float = 32.0, cam_rect: Rect2 = Rect2()) -> void:
	if cam_rect.size.x > 0.0 and not cam_rect.intersects(rect):
		return
	var frame := (int(time_elapsed * 3.6) % 4) + 1
	var fname := "tile_water_%d.png" % frame
	if not tex.has(fname):
		fname = "tile_water_1.png"
	var wtex: Texture2D = get_scaled_tile_tex(fname, int(roundf(tile_px)))
	if wtex == null:
		return
	if canvas.texture_repeat != CanvasItem.TEXTURE_REPEAT_ENABLED:
		canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	canvas.draw_texture_rect(wtex, rect, true)


func draw_campfire_sparks(canvas: Node2D, base_pos: Vector2, flame_tint: bool = true) -> void:
	for sp in spark_particles:
		var t := fmod(time_elapsed * float(sp["speed"]) + float(sp["phase"]), 1.0)
		var px := base_pos.x + float(sp["dx"]) * (0.4 + 0.6 * t) + sin(time_elapsed * 4.0 + float(sp["phase"]) * TAU) * 3.5
		var py := base_pos.y - 6.0 - t * 34.0
		var alpha := (1.0 - t) * 0.85
		var c := Color(1.0, 0.82, 0.36, alpha) if flame_tint else Color(0.95, 0.90, 0.65, alpha * 0.65)
		if int(sp["color_idx"]) == 2 and flame_tint:
			c = Color(0.96, 0.45, 0.16, alpha)
		canvas.draw_rect(Rect2(px, py, 2.0, 2.0), c)


func draw_chimney_smoke(canvas: Node2D, chimney_pos: Vector2, src_id: int) -> void:
	for puff in smoke_puffs:
		if int(puff["source"]) != src_id:
			continue
		var t := fmod(time_elapsed * 0.22 + float(puff["phase"]), 1.0)
		var px := chimney_pos.x + t * float(puff["drift"]) + sin(t * 5.0) * 3.0
		var py := chimney_pos.y - t * 42.0
		var r := float(puff["size"]) * (0.55 + t * 0.85)
		var alpha := (1.0 - t) * 0.36
		canvas.draw_circle(Vector2(px, py), r, Color(0.82, 0.84, 0.90, alpha))


func draw_sprite_building(canvas: Node2D, rect: Rect2, tex_name: String, label_txt: String, font: Font) -> void:
	canvas.draw_rect(Rect2(rect.position + Vector2(5, 7), rect.size), Color(0.05, 0.05, 0.08, 0.30))
	var btex: Texture2D = tex.get(tex_name)
	if btex != null:
		canvas.draw_texture_rect(btex, rect, false)
	if label_txt != "":
		draw_label_shadowed(canvas, Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y - 8), label_txt, font, 13, Color(0.96, 0.86, 0.58), true)


func draw_npc_sprite(canvas: Node2D, pos: Vector2, tex_name: String, npc_name: String, font: Font, label_col: Color = Color(0.95, 0.92, 0.84), flip_h: bool = false) -> void:
	if _npc_shadow_tex != null:
		canvas.draw_texture_rect(_npc_shadow_tex, Rect2(pos + Vector2(-10.0, 4.0), Vector2(20.0, 7.0)), false)

	var ntex: Texture2D = get_tex_flipped(tex_name) if flip_h else get_tex(tex_name)
	if ntex != null:
		canvas.draw_texture_rect(ntex, Rect2(pos + Vector2(-19.0, -33.0), Vector2(38.0, 44.0)), false)
	if npc_name != "":
		draw_label_shadowed(canvas, pos + Vector2(0, 22), npc_name, font, 11, label_col, true)


func draw_interact_bubble(canvas: Node2D, pos: Vector2, text_str: String, font: Font) -> void:
	var use_font := _resolve_ui_font(font)
	var float_y := sin(time_elapsed * 4.2) * 2.0
	var key_str := ""
	var body_str := text_str
	if text_str.begins_with("["):
		var br := text_str.find("]")
		if br > 1:
			key_str = text_str.substr(1, br - 1)
			body_str = text_str.substr(br + 1).strip_edges()

	var label_size := use_font.get_string_size(body_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var key_badge_w := 0.0
	if key_str != "":
		var ksize := use_font.get_string_size(key_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		key_badge_w = maxf(20.0, ksize.x + 10.0) + 8.0
	var w := maxf(104.0, label_size.x + key_badge_w + 22.0)
	var h := 26.0
	var box := Rect2(pos + Vector2(-w * 0.5, -h + float_y), Vector2(w, h))

	canvas.draw_rect(Rect2(box.position + Vector2(2, 3), box.size), Color(0.02, 0.02, 0.04, 0.60))
	canvas.draw_rect(box, Color(0.09, 0.07, 0.11, 0.95))
	canvas.draw_rect(box, Color(0.76, 0.58, 0.28), false, 2.0)
	canvas.draw_rect(Rect2(box.position + Vector2(2, 2), box.size - Vector2(4, 4)), Color(0.96, 0.84, 0.50, 0.32), false, 1.0)
	for rc in [
		box.position + Vector2(3, 3),
		box.position + Vector2(box.size.x - 5, 3),
		box.position + Vector2(3, box.size.y - 5),
		box.position + Vector2(box.size.x - 5, box.size.y - 5)
	]:
		canvas.draw_rect(Rect2(rc, Vector2(2, 2)), Color(0.98, 0.86, 0.52, 0.85))

	var tx := box.position.x + 9.0
	if key_str != "":
		var kb_w := key_badge_w - 8.0
		var kb_rect := Rect2(tx, box.position.y + 4.0, kb_w, h - 8.0)
		canvas.draw_rect(kb_rect, Color(0.24, 0.18, 0.12))
		canvas.draw_rect(kb_rect, Color(0.96, 0.82, 0.46), false, 1.0)
		draw_label_shadowed(canvas, Vector2(kb_rect.position.x + kb_w * 0.5, box.position.y + 16.5), key_str, use_font, 11, Color(1.0, 0.94, 0.72), true)
		tx += kb_w + 7.0
	draw_label_shadowed(canvas, Vector2(tx, box.position.y + 17.5), body_str, use_font, 12, Color(0.96, 0.92, 0.80), false)


## Metadata lookup (16x16 pixel icon, category badge, lore & effect text) — delegated to ItemCatalog.
func get_item_info(item_name: String) -> Dictionary:
	return ItemCatalogScript.get_item_info(item_name)


## Draws a glowing Flemish brick bread oven with hearth glow, rising flue smoke, ember sparks & fresh boules.
func draw_bakery_oven_fx(canvas: Node2D, oven_rect: Rect2, t_now: float) -> void:
	var oven_tex: Texture2D = get_tex("prop_brick_bread_oven.png")
	var loaf_tex: Texture2D = get_tex("prop_bread_loaf.png")
	var pulse := 0.5 + 0.5 * sin(t_now * 5.6 + oven_rect.position.x * 0.1)
	canvas.draw_circle(oven_rect.get_center() + Vector2(0, 8), 26.0 + pulse * 4.0, Color(1.0, 0.52, 0.14, 0.15 + pulse * 0.07))
	if oven_tex != null:
		canvas.draw_texture_rect(oven_tex, oven_rect, false)
	canvas.draw_circle(oven_rect.position + Vector2(oven_rect.size.x * 0.5, oven_rect.size.y * 0.70), 4.6 + pulse * 1.4, Color(1.0, 0.64, 0.18, 0.30 + pulse * 0.12))
	if loaf_tex != null:
		canvas.draw_texture_rect(loaf_tex, Rect2(oven_rect.position + Vector2(6, oven_rect.size.y - 20.0), Vector2(16, 16)), false)
		if fmod(t_now * 0.45 + oven_rect.position.x * 0.01, 3.0) > 0.7:
			canvas.draw_texture_rect(loaf_tex, Rect2(oven_rect.position + Vector2(oven_rect.size.x - 22.0, oven_rect.size.y - 20.0), Vector2(16, 16)), false)
	for ei in range(4):
		var ep_t := fmod(t_now * 0.65 + float(ei) * 0.25, 1.0)
		var flue := oven_rect.position + Vector2(oven_rect.size.x * 0.5 + sin(t_now * 2.2 + float(ei) * 1.9) * 5.0, 4.0 - ep_t * 28.0)
		canvas.draw_circle(flue, 4.5 + ep_t * 4.0, Color(0.84, 0.80, 0.76, (1.0 - ep_t) * 0.34))
		if ei < 3:
			var spark_y := oven_rect.position.y + oven_rect.size.y * 0.64 - fmod(t_now * 1.2 + float(ei) * 0.33, 1.0) * 18.0
			canvas.draw_rect(Rect2(oven_rect.position.x + oven_rect.size.x * 0.48 + sin(t_now * 7.0 + float(ei) * 2.1) * 4.0, spark_y, 2.0, 2.0), Color(1.0, 0.78, 0.22, 0.85))
