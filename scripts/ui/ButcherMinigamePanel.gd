extends PanelContainer
class_name ButcherMinigamePanel

## Physical Mouse Meat-Slicing Butcher Minigame (Phase 2/3 Sanctuary feeding chore):
## Hold Left Mouse Button and drag the steel butcher knife cleanly edge-to-edge along all 4
## pale tallow cut-seams (avoiding ivory bone knuckles) to carve 4 dragon-sized mutton quarters.

signal chop_completed
signal chop_cancelled

const SEAMS: Array[Dictionary] = [
	{"a": Vector2(0.275, 0.25), "b": Vector2(0.245, 0.87)},
	{"a": Vector2(0.418, 0.23), "b": Vector2(0.442, 0.88)},
	{"a": Vector2(0.585, 0.23), "b": Vector2(0.556, 0.88)},
	{"a": Vector2(0.735, 0.26), "b": Vector2(0.762, 0.86)},
]

# Exposed ivory bone knuckles between seams — striking bone jars the knife!
const BONE_KNUCKLES: Array[Dictionary] = [
	{"piece": 1, "uv": Vector2(0.352, 0.355), "r": 12.0},
	{"piece": 3, "uv": Vector2(0.652, 0.760), "r": 12.0},
	{"piece": 4, "uv": Vector2(0.860, 0.560), "r": 16.0},
]

const SEAM_CORRIDOR_PX: float = 21.0
const SEAM_EDGE_MARGIN: float = 0.145

var cuts_done: int = 0
var cut_flags: Array[bool] = [false, false, false, false]
var furrow_min_t: Array[float] = [1.0, 1.0, 1.0, 1.0]
var furrow_max_t: Array[float] = [0.0, 0.0, 0.0, 0.0]
var seam_sep: Array[float] = [0.0, 0.0, 0.0, 0.0]

var is_slicing: bool = false
var active_seam: int = -1
var knife_pos: Vector2 = Vector2(270, 56)
var prev_knife_pos: Vector2 = Vector2(270, 56)
var knife_angle: float = -0.35
var bone_cooldown: float = 0.0
var slash_sfx_cooldown: float = 0.0
var completed: bool = false
var finish_timer: float = 0.0
var miss_flash: float = 0.0
var chop_flash: float = 0.0
var feedback_msg: String = ""
var particles: Array[Dictionary] = []
var slash_trail: Array[Dictionary] = []

var title_lbl: Label
var desc_lbl: Label
var hint_lbl: Label
var board: Control
var cancel_btn: Button


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(580, 400)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -290
	offset_top = -200
	offset_right = 290
	offset_bottom = 200

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.09, 0.12, 0.97)
	sb.border_color = Color(0.78, 0.62, 0.34, 0.98)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	title_lbl = Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = "STOCKMAN'S BUTCHER BLOCK: CARVE MUTTON"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.52))
	header.add_child(title_lbl)

	cancel_btn = Button.new()
	cancel_btn.text = "Close [Esc]"
	cancel_btn.pressed.connect(close_minigame)
	header.add_child(cancel_btn)

	desc_lbl = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.text = "Hold Left Mouse Button and drag the blade cleanly all the way across all 4 tallow cut-seams!"
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	vbox.add_child(desc_lbl)

	board = Control.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	board.custom_minimum_size = Vector2(540, 250)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.mouse_default_cursor_shape = Control.CURSOR_CROSS
	board.draw.connect(_draw_board)
	board.gui_input.connect(_on_board_gui_input)
	vbox.add_child(board)

	hint_lbl = Label.new()
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.text = "Steer around hard white bone knuckles so Virelai eats clean un-splintered meat!"
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 0.75))
	vbox.add_child(hint_lbl)


func apply_medieval_ui_theme(panel_style: StyleBox, btn_normal: StyleBox, btn_hover: StyleBox, btn_pressed: StyleBox) -> void:
	if panel_style != null:
		add_theme_stylebox_override("panel", panel_style)
	if cancel_btn != null and btn_normal != null:
		cancel_btn.add_theme_stylebox_override("normal", btn_normal)
		cancel_btn.add_theme_stylebox_override("hover", btn_hover if btn_hover != null else btn_normal)
		cancel_btn.add_theme_stylebox_override("pressed", btn_pressed if btn_pressed != null else btn_normal)
		cancel_btn.add_theme_color_override("font_color", Color(0.97, 0.92, 0.78))
	for lbl in [title_lbl, desc_lbl, hint_lbl]:
		if lbl != null:
			lbl.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.06, 0.92))
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 2)


func start_butchering() -> void:
	cuts_done = 0
	cut_flags = [false, false, false, false]
	furrow_min_t = [1.0, 1.0, 1.0, 1.0]
	furrow_max_t = [0.0, 0.0, 0.0, 0.0]
	seam_sep = [0.0, 0.0, 0.0, 0.0]
	is_slicing = false
	active_seam = -1
	knife_pos = Vector2(140.0, 52.0)
	prev_knife_pos = knife_pos
	knife_angle = -0.35
	bone_cooldown = 0.0
	slash_sfx_cooldown = 0.0
	completed = false
	finish_timer = 0.0
	miss_flash = 0.0
	chop_flash = 0.0
	feedback_msg = "0 / 4 Quarters Carved — Hold & Drag Blade Through Each Seam"
	particles.clear()
	slash_trail.clear()
	if hint_lbl != null:
		hint_lbl.visible = GameState.hints_enabled
	visible = true
	board.queue_redraw()


func close_minigame() -> void:
	is_slicing = false
	visible = false
	emit_signal("chop_cancelled")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_minigame()
		get_viewport().set_input_as_handled()


func _on_board_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos := (event as InputEventMouseButton).position
		knife_pos = mpos
		prev_knife_pos = mpos
		if event.pressed and not completed:
			is_slicing = true
			active_seam = -1
			_process_slice_segment(mpos, mpos, true)
		else:
			is_slicing = false
			active_seam = -1
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		prev_knife_pos = knife_pos
		knife_pos = mm.position
		var dv := knife_pos - prev_knife_pos
		if dv.length() > 1.5:
			var target_ang := clampf(atan2(dv.y, dv.x) - PI * 0.5, -1.1, 1.1)
			knife_angle = lerp_angle(knife_angle, target_ang, 0.35)
		if is_slicing and not completed:
			_process_slice_segment(prev_knife_pos, knife_pos, false)


func _piece_offset_x(piece_idx: int) -> float:
	match piece_idx:
		0: return -(seam_sep[0] * 14.0 + seam_sep[1] * 8.0)
		1: return -(seam_sep[1] * 8.0)
		2: return 0.0
		3: return seam_sep[2] * 9.0
		_: return seam_sep[2] * 9.0 + seam_sep[3] * 14.0


func _seam_world_pts(idx: int, sz: Vector2) -> Array[Vector2]:
	var sdef: Dictionary = SEAMS[idx]
	var shift_x := 0.0
	if idx == 0:
		shift_x = -(seam_sep[1] * 8.0)
	elif idx == 3:
		shift_x = seam_sep[2] * 9.0
	var p1 := Vector2(Vector2(sdef["a"]).x * sz.x + shift_x, Vector2(sdef["a"]).y * sz.y)
	var p2 := Vector2(Vector2(sdef["b"]).x * sz.x + shift_x, Vector2(sdef["b"]).y * sz.y)
	return [p1, p2]


func _closest_on_segment(pt: Vector2, a: Vector2, b: Vector2) -> Dictionary:
	var ab := b - a
	var len_sq := maxf(1.0, ab.length_squared())
	var t := (pt - a).dot(ab) / len_sq
	var tc := clampf(t, 0.0, 1.0)
	var proj := a + ab * tc
	return {"t": t, "tc": tc, "dist": pt.distance_to(proj), "pt": proj}


func _process_slice_segment(from_pos: Vector2, to_pos: Vector2, is_press: bool) -> void:
	var sz := board.size
	var seg_len := from_pos.distance_to(to_pos)
	if not is_press and seg_len > 2.0:
		slash_trail.append({"a": from_pos, "b": to_pos, "life": 0.20})
	var sub_steps := clampi(int(ceil(seg_len / 5.5)), 1, 16)
	for step in range(sub_steps + 1):
		var alpha := float(step) / float(sub_steps)
		var pt := from_pos.lerp(to_pos, alpha)

		# Check exposed ivory bone knuckles first
		if bone_cooldown <= 0.0:
			for bk in BONE_KNUCKLES:
				var p_idx: int = int(bk["piece"])
				var bpos := Vector2(Vector2(bk["uv"]).x * sz.x + _piece_offset_x(p_idx), Vector2(bk["uv"]).y * sz.y)
				if pt.distance_to(bpos) <= float(bk["r"]):
					bone_cooldown = 0.36
					miss_flash = 0.85
					SoundManager.play_knot_snag()
					_spawn_sparks(pt, Color(0.96, 0.92, 0.80), 10)
					feedback_msg = "Clacked off bone! Steer along the golden tallow seam."
					return

		# Check active or nearest uncut tallow seam
		var cand_idx := active_seam
		if cand_idx < 0 or cut_flags[cand_idx]:
			var best_d := SEAM_CORRIDOR_PX
			cand_idx = -1
			for i in range(SEAMS.size()):
				if cut_flags[i]:
					continue
				var pts := _seam_world_pts(i, sz)
				var res := _closest_on_segment(pt, pts[0], pts[1])
				if float(res["t"]) >= -0.06 and float(res["t"]) <= 1.06 and float(res["dist"]) <= best_d:
					best_d = float(res["dist"])
					cand_idx = i
		else:
			var pts_a := _seam_world_pts(cand_idx, sz)
			var res_a := _closest_on_segment(pt, pts_a[0], pts_a[1])
			if float(res_a["dist"]) > SEAM_CORRIDOR_PX * 1.45:
				cand_idx = -1

		if cand_idx < 0:
			active_seam = -1
			continue

		var pts_c := _seam_world_pts(cand_idx, sz)
		var hit := _closest_on_segment(pt, pts_c[0], pts_c[1])
		var tc := float(hit["tc"])
		active_seam = cand_idx

		var empty_cut := furrow_min_t[cand_idx] > furrow_max_t[cand_idx]
		if empty_cut:
			furrow_min_t[cand_idx] = tc
			furrow_max_t[cand_idx] = tc
		else:
			var connected := tc >= furrow_min_t[cand_idx] - 0.24 and tc <= furrow_max_t[cand_idx] + 0.24
			if is_press and not connected:
				furrow_min_t[cand_idx] = tc
				furrow_max_t[cand_idx] = tc
			elif connected:
				furrow_min_t[cand_idx] = minf(furrow_min_t[cand_idx], tc)
				furrow_max_t[cand_idx] = maxf(furrow_max_t[cand_idx], tc)

		if not is_press and seg_len > 2.5 and step % 2 == 0:
			if slash_sfx_cooldown <= 0.0 and tc > 0.14 and tc < 0.86:
				slash_sfx_cooldown = 0.15
				SoundManager.play_slash()
			_spawn_sparks(Vector2(hit["pt"]), Color(0.86, 0.26, 0.24), 2)

		if furrow_min_t[cand_idx] <= SEAM_EDGE_MARGIN and furrow_max_t[cand_idx] >= 1.0 - SEAM_EDGE_MARGIN:
			_complete_seam_cut(cand_idx, pts_c)
			break


func _complete_seam_cut(idx: int, pts: Array[Vector2]) -> void:
	cut_flags[idx] = true
	cuts_done += 1
	active_seam = -1
	chop_flash = 1.0
	SoundManager.play_butcher_chop()
	for k in range(5):
		var frac := float(k) / 4.0
		_spawn_sparks(pts[0].lerp(pts[1], frac), Color(0.98, 0.82, 0.36), 4)
	if cuts_done >= SEAMS.size():
		completed = true
		finish_timer = 0.86
		feedback_msg = "MUTTON QUARTERED CLEANLY! (4 / 4)"
		SoundManager.play_chime()
	else:
		feedback_msg = "Clean Draw-Slice! (%d / 4 Quarters Severed)" % cuts_done


func _process(delta: float) -> void:
	if not visible:
		return
	miss_flash = maxf(0.0, miss_flash - delta * 2.8)
	chop_flash = maxf(0.0, chop_flash - delta * 4.0)
	bone_cooldown = maxf(0.0, bone_cooldown - delta)
	slash_sfx_cooldown = maxf(0.0, slash_sfx_cooldown - delta)

	for i in range(SEAMS.size()):
		if cut_flags[i] and seam_sep[i] < 1.0:
			seam_sep[i] = minf(1.0, seam_sep[i] + delta * 5.2)

	for i in range(slash_trail.size() - 1, -1, -1):
		var st: Dictionary = slash_trail[i]
		st["life"] = float(st["life"]) - delta
		if float(st["life"]) <= 0.0:
			slash_trail.remove_at(i)

	for i in range(particles.size() - 1, -1, -1):
		var sp: Dictionary = particles[i]
		sp["life"] = float(sp["life"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		sp["vel"] = Vector2(sp["vel"]) * 0.90 + Vector2(0, 140.0) * delta
		if float(sp["life"]) <= 0.0:
			particles.remove_at(i)

	if completed:
		finish_timer -= delta
		if finish_timer <= 0.0:
			is_slicing = false
			visible = false
			emit_signal("chop_completed")
	board.queue_redraw()


func _spawn_sparks(origin: Vector2, col: Color, count: int) -> void:
	for _i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(35.0, 130.0)
		particles.append({"pos": origin, "vel": Vector2(cos(ang), sin(ang) - 0.45) * spd, "col": col, "life": 0.42})


func _seam_x_at_y(seam_idx: int, y_norm: float) -> float:
	var a := Vector2(SEAMS[seam_idx]["a"])
	var b := Vector2(SEAMS[seam_idx]["b"])
	var t := clampf((y_norm - a.y) / maxf(0.01, b.y - a.y), 0.0, 1.0)
	return lerpf(a.x, b.x, t)


func _draw_board() -> void:
	var font := board.get_theme_default_font()
	var sz := board.size
	# Heavy Oak Butcher Block surface with wood grain & old chopping scars
	board.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.18, 0.12, 0.08))
	board.draw_rect(Rect2(Vector2(12, 16), sz - Vector2(24, 32)), Color(0.32, 0.21, 0.14))
	for row_y in [62.0, 118.0, 174.0, 218.0]:
		board.draw_line(Vector2(14, row_y), Vector2(sz.x - 14, row_y), Color(0.22, 0.14, 0.09), 2.0)
	if miss_flash > 0.05:
		board.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.88, 0.22, 0.20, miss_flash * 0.24))

	# Draw 5 anatomical roast segments that physically slide apart once each seam separates
	for p in range(5):
		var ox := _piece_offset_x(p)
		var top_pad := 0.34 if p == 0 else (0.31 if p <= 2 else (0.35 if p == 3 else 0.44))
		var bot_pad := 0.77 if p == 0 else (0.81 if p <= 2 else (0.77 if p == 3 else 0.67))
		var tl_x := (_seam_x_at_y(p - 1, top_pad) if p > 0 else 0.135) * sz.x + ox
		var tr_x := (_seam_x_at_y(p, top_pad) if p < 4 else 0.875) * sz.x + ox
		var br_x := (_seam_x_at_y(p, bot_pad) if p < 4 else 0.875) * sz.x + ox
		var bl_x := (_seam_x_at_y(p - 1, bot_pad) if p > 0 else 0.135) * sz.x + ox
		var poly := PackedVector2Array([
			Vector2(tl_x, top_pad * sz.y),
			Vector2(tr_x, top_pad * sz.y),
			Vector2(br_x, bot_pad * sz.y),
			Vector2(bl_x, bot_pad * sz.y),
		])
		var shadow_poly := PackedVector2Array()
		for pt in poly:
			shadow_poly.append(pt + Vector2(3, 4))
		board.draw_colored_polygon(shadow_poly, Color(0.08, 0.05, 0.05, 0.45))

		var fill := Color(0.84, 0.78, 0.70) if p == 4 else (Color(0.75, 0.32, 0.28) if p > 0 and cut_flags[p - 1] else Color(0.66, 0.24, 0.22))
		board.draw_colored_polygon(poly, fill)
		# Dark roasted outer skin rim along top and bottom + rich crimson marbling
		board.draw_line(poly[0], poly[1], Color(0.36, 0.16, 0.12), 5.0)
		board.draw_line(poly[3], poly[2], Color(0.36, 0.16, 0.12), 5.0)
		if p < 4:
			var center_p := (poly[0] + poly[1] + poly[2] + poly[3]) * 0.25
			board.draw_circle(center_p + Vector2(-4, -5), 11.0, Color(0.82, 0.38, 0.34, 0.60))
			board.draw_circle(center_p + Vector2(6, 7), 8.0, Color(0.90, 0.76, 0.56, 0.42))

	# Draw Exposed Ivory Bone Knuckles between seams
	for bk in BONE_KNUCKLES:
		var ox := _piece_offset_x(int(bk["piece"]))
		var bpos := Vector2(Vector2(bk["uv"]).x * sz.x + ox, Vector2(bk["uv"]).y * sz.y)
		var r_bone := float(bk["r"])
		board.draw_circle(bpos + Vector2(1, 2), r_bone * 0.85, Color(0.14, 0.09, 0.08, 0.55))
		board.draw_circle(bpos, r_bone * 0.78, Color(0.88, 0.84, 0.74))
		board.draw_circle(bpos + Vector2(-2, -2), r_bone * 0.38, Color(0.96, 0.94, 0.88))

	# Draw 4 Anatomical Tallow Cut-Seams + Live Carved Furrow
	for i in range(SEAMS.size()):
		var pts := _seam_world_pts(i, sz)
		var a := pts[0]
		var b := pts[1]
		if cut_flags[i]:
			var sep_shift := seam_sep[i] * 5.0
			board.draw_line(a + Vector2(-sep_shift, 0), b + Vector2(-sep_shift, 0), Color(0.45, 0.94, 0.62, 0.72), 2.5)
		else:
			board.draw_line(a, b, Color(0.98, 0.85, 0.42, 0.42), 10.0)
			board.draw_line(a, b, Color(0.98, 0.88, 0.46), 3.0)
			# Start/end rim notch circles to subtly invite edge-to-edge drag
			board.draw_circle(a, 5.5, Color(0.98, 0.86, 0.38, 0.85))
			board.draw_circle(b, 5.5, Color(0.98, 0.86, 0.38, 0.85))
			if furrow_min_t[i] <= furrow_max_t[i]:
				var g0 := a.lerp(b, furrow_min_t[i])
				var g1 := a.lerp(b, furrow_max_t[i])
				board.draw_line(g0, g1, Color(0.24, 0.06, 0.06), 7.5)
				board.draw_line(g0, g1, Color(0.88, 0.22, 0.22), 3.0)

	# Motion Slash Trail
	for st in slash_trail:
		var a_tr := clampf(float(st["life"]) / 0.20, 0.0, 1.0)
		board.draw_line(Vector2(st["a"]), Vector2(st["b"]), Color(0.96, 0.98, 1.0, a_tr * 0.72), 3.5)

	# Physical Steel Butcher Cleaver Following Cursor inside Board Local Space
	if Rect2(Vector2.ZERO, sz).has_point(board.get_local_mouse_position()) or is_slicing:
		board.draw_set_transform(knife_pos, knife_angle, Vector2.ONE)
		board.draw_rect(Rect2(-4, -34, 8, 18), Color(0.42, 0.24, 0.12)) # hardwood grip
		board.draw_circle(Vector2(0, -28), 1.6, Color(0.86, 0.74, 0.38)) # brass rivet
		board.draw_rect(Rect2(-9, -16, 18, 28), Color(0.76, 0.82, 0.88)) # broad cleaver steel
		board.draw_rect(Rect2(-9, 8, 18, 4), Color(0.96, 0.98, 1.0))    # honed edge
		board.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for sp in particles:
		var a := clampf(float(sp["life"]) / 0.42, 0.0, 1.0)
		var c: Color = sp["col"]
		board.draw_circle(Vector2(sp["pos"]), 3.5, Color(c.r, c.g, c.b, a))

	board.draw_string(font, Vector2(18, 30), feedback_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.98, 0.88, 0.56))
	board.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.65, 0.50, 0.28), false, 2.0)
