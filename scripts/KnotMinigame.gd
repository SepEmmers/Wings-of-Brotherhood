extends PanelContainer
class_name KnotMinigame

## Interactive 2-stage Mouse-Only Medieval Knotting Minigame:
##   1. Hold Left-Click or click pegs in order to weave the hemp strand—avoid RED iron snag nails!
##   2. Left-Click inside the board when the tension needle hits the GOLD zone before time expires!
##   Slipping, snags, or running out of time damages rope integrity and can FAIL the knot.

signal knot_completed(knot_id: String)
signal knot_failed(knot_id: String)
signal knot_cancelled

var active_knot_id: String = "clove_hitch"
var pegs: Array[Vector2] = []
var snags: Array[Vector2] = []
var threaded_count: int = 0
var stage: int = 0  # 0 = mouse threading, 1 = tension cinch, 2 = complete, 3 = failed

var integrity: int = 3
var max_integrity: int = 3
var time_left: float = 14.0
var time_max: float = 14.0
var sweet_width: float = 0.20
var snag_cooldown: float = 0.0

var mouse_pos: Vector2 = Vector2.ZERO
var mouse_inside: bool = false
var is_dragging: bool = false

var tension_cursor: float = 0.0
var tension_dir: float = 1.0
var tension_speed: float = 1.75
var complete_timer: float = 0.0
var feedback_msg: String = ""
var spark_particles: Array[Dictionary] = []

var title_lbl: Label
var desc_lbl: Label
var board: Control
var hint_lbl: Label
var cancel_btn: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(650, 460)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -325
	offset_top = -230
	offset_right = 325
	offset_bottom = 230

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
	title_lbl.add_theme_font_size_override("font_size", 19)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.52))
	header.add_child(title_lbl)

	cancel_btn = Button.new()
	cancel_btn.text = "Close [Esc]"
	cancel_btn.pressed.connect(close_minigame)
	header.add_child(cancel_btn)

	desc_lbl = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	vbox.add_child(desc_lbl)

	board = Control.new()
	board.custom_minimum_size = Vector2(610, 300)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.draw.connect(_draw_board)
	board.gui_input.connect(_on_board_gui_input)
	board.mouse_entered.connect(func(): mouse_inside = true)
	board.mouse_exited.connect(func():
		mouse_inside = false
		is_dragging = false
	)
	vbox.add_child(board)

	hint_lbl = Label.new()
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
		cancel_btn.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.06, 0.90))
		cancel_btn.add_theme_constant_override("shadow_offset_x", 1)
		cancel_btn.add_theme_constant_override("shadow_offset_y", 1)
	for lbl in [title_lbl, desc_lbl, hint_lbl]:
		if lbl != null:
			lbl.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.06, 0.92))
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 2)

func start_knot(knot_id: String) -> void:
	if not GameState.KNOT_DATA.has(knot_id):
		return
	offset_left = -325
	offset_right = 325
	active_knot_id = knot_id
	var data: Dictionary = GameState.KNOT_DATA[knot_id]
	pegs.clear()
	for p in data.get("pegs", []):
		pegs.append(p)
	snags.clear()
	for s in data.get("snags", []):
		snags.append(s)

	threaded_count = 1
	stage = 0
	max_integrity = 4 if GameState.clara_gift_received else 3
	integrity = max_integrity
	time_max = float(data.get("time_limit", 13.0)) + (2.0 if GameState.sanctuary_drill_mastered else 0.0)
	time_left = time_max
	var width_mult := (1.25 if GameState.clara_gift_received else 1.0) * (1.18 if GameState.sanctuary_drill_mastered else 1.0)
	sweet_width = float(data.get("sweet_width", 0.20)) * width_mult
	tension_speed = float(data.get("tension_speed", 1.85))
	snag_cooldown = 0.0
	is_dragging = false
	mouse_pos = pegs[0] if not pegs.is_empty() else Vector2.ZERO

	tension_cursor = 0.0
	tension_dir = 1.0
	complete_timer = 0.0
	feedback_msg = ""
	spark_particles.clear()

	title_lbl.text = "KNOTTING BOARD: %s" % data["name"]
	desc_lbl.text = "Ability: %s  |  Cast: %s" % [data.get("ability", data["desc"]), data["throw_style"]]
	hint_lbl.text = "MOUSE ONLY: Drag or Left-Click each glowing numbered peg in order — avoid RED iron snags!"
	visible = true
	board.queue_redraw()

func close_minigame() -> void:
	offset_left = -325
	offset_right = 325
	visible = false
	is_dragging = false
	emit_signal("knot_cancelled")

func _process(delta: float) -> void:
	if not visible:
		return

	if snag_cooldown > 0.0:
		snag_cooldown = maxf(0.0, snag_cooldown - delta)

	for i in range(spark_particles.size() - 1, -1, -1):
		var sp: Dictionary = spark_particles[i]
		sp["life"] = float(sp["life"]) - delta
		sp["pos"] = sp["pos"] + sp["vel"] * delta
		sp["vel"] = sp["vel"] * 0.92
		if sp["life"] <= 0.0:
			spark_particles.remove_at(i)

	if stage in [0, 1]:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			_trigger_failure("TIME EXPIRED — Hemp lost tension and unraveled!")
			board.queue_redraw()
			return

	if stage == 1:
		tension_cursor += tension_dir * tension_speed * delta
		if tension_cursor >= 1.0:
			tension_cursor = 1.0
			tension_dir = -1.0
		elif tension_cursor <= 0.0:
			tension_cursor = 0.0
			tension_dir = 1.0
	elif stage == 2:
		complete_timer -= delta
		if complete_timer <= 0.0:
			visible = false
			is_dragging = false
			GameState.unlock_knot(active_knot_id)
			emit_signal("knot_completed", active_knot_id)
	elif stage == 3:
		complete_timer -= delta
		var shake_amp := clampf(complete_timer / 1.05, 0.0, 1.0) * 10.0
		var shake_x := sin(Time.get_ticks_msec() * 0.09) * shake_amp
		offset_left = -325.0 + shake_x
		offset_right = 325.0 + shake_x
		if complete_timer <= 0.0:
			offset_left = -325.0
			offset_right = 325.0
			visible = false
			is_dragging = false
			emit_signal("knot_failed", active_knot_id)

	board.queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_minigame()

func _on_board_gui_input(event: InputEvent) -> void:
	if stage >= 2:
		return

	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if stage == 0 and is_dragging:
			_check_drag_targets(mouse_pos)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_pos = event.position
		if event.pressed:
			is_dragging = true
			if stage == 0:
				_handle_peg_click(mouse_pos)
			elif stage == 1:
				_attempt_cinch()
		else:
			is_dragging = false

func _handle_peg_click(pos: Vector2) -> void:
	if _check_snag_hit(pos):
		return
	if threaded_count < pegs.size():
		var next_peg := pegs[threaded_count]
		if pos.distance_to(next_peg) <= 23.0:
			_advance_peg()
		else:
			_damage_integrity("Mis-threaded! Click or drag onto peg #%d!" % (threaded_count + 1))

func _check_drag_targets(pos: Vector2) -> void:
	if _check_snag_hit(pos):
		return
	if threaded_count < pegs.size() and pos.distance_to(pegs[threaded_count]) <= 23.0:
		_advance_peg()

func _check_snag_hit(pos: Vector2) -> bool:
	if snag_cooldown > 0.0:
		return false
	for sp in snags:
		if pos.distance_to(sp) <= 17.0:
			snag_cooldown = 0.45
			_damage_integrity("Snagged on a rusty iron spike! (-1 Integrity)")
			return true
	return false

func _spawn_sparks(origin: Vector2, col: Color, count: int = 8) -> void:
	for i in range(count):
		var ang := (float(i) / float(count)) * TAU + randf_range(-0.25, 0.25)
		var spd := randf_range(35.0, 95.0)
		spark_particles.append({
			"pos": origin,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"life": randf_range(0.22, 0.42),
			"max_life": 0.42,
			"col": col
		})

func _damage_integrity(reason: String) -> void:
	integrity -= 1
	SoundManager.play_knot_snag()
	_spawn_sparks(mouse_pos, Color(0.96, 0.32, 0.24), 10)
	feedback_msg = reason
	if integrity <= 0:
		_trigger_failure("ROPE FRAYED & SNAPPED — Too many slips or snags!")

func _trigger_failure(reason: String) -> void:
	stage = 3
	is_dragging = false
	complete_timer = 1.05
	SoundManager.play_knot_snag()
	SoundManager.play_knot_fail()
	for i in range(mini(threaded_count, pegs.size())):
		_spawn_sparks(pegs[i], Color(0.96, 0.34, 0.24), 7)
		_spawn_sparks(pegs[i], Color(0.84, 0.68, 0.38), 5)
	if threaded_count >= 2:
		var snap_mid := (pegs[0] + pegs[threaded_count - 1]) * 0.5
		_spawn_sparks(snap_mid, Color(0.98, 0.44, 0.28), 14)
	feedback_msg = reason
	hint_lbl.text = "ROPE SNAPPED — Hemp unraveled!"

func _advance_peg() -> void:
	if threaded_count < pegs.size():
		var hit_pos := pegs[threaded_count]
		threaded_count += 1
		SoundManager.play_knot_peg(threaded_count)
		_spawn_sparks(hit_pos, Color(0.98, 0.84, 0.38), 9)
		feedback_msg = ""
		if threaded_count >= pegs.size():
			stage = 1
			is_dragging = false
			hint_lbl.text = "Strands woven! LEFT-CLICK inside the board when the needle hits the narrow GOLD band!"

func _attempt_cinch() -> void:
	var half_w := sweet_width * 0.5
	if tension_cursor >= (0.5 - half_w) and tension_cursor <= (0.5 + half_w):
		stage = 2
		complete_timer = 0.78
		SoundManager.play_knot_cinch()
		_spawn_sparks(Vector2(board.size.x * 0.5, 265.0), Color(0.55, 0.96, 0.62), 18)
		feedback_msg = "KNOT CINCHED TAUT!"
		hint_lbl.text = "Mastered %s! Press [F] / Right-Click to use its ability, [Q] to switch." % GameState.get_knot_display(active_knot_id)
	else:
		tension_speed += 0.25
		_damage_integrity("Slipped the cinch! Left-Click inside the GOLD zone!")

func _draw_board() -> void:
	var font := ThemeDB.fallback_font
	var sz := board.size

	# Oak plank rigging board background with staggered grain & iron corner brackets
	board.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.21, 0.14, 0.09))
	var plank_idx := 0
	for y in range(0, int(sz.y), 26):
		var plank_col := Color(0.24, 0.16, 0.10) if plank_idx % 2 == 0 else Color(0.22, 0.145, 0.095)
		board.draw_rect(Rect2(0, y, sz.x, 24), plank_col)
		board.draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0.30, 0.21, 0.13, 0.45), 1.5)
		board.draw_line(Vector2(0, y + 25), Vector2(sz.x, y + 25), Color(0.11, 0.07, 0.04, 0.85), 2.0)
		var seam_x := 170.0 + float((plank_idx * 137) % 290)
		board.draw_line(Vector2(seam_x, y), Vector2(seam_x, y + 25), Color(0.12, 0.08, 0.05, 0.7), 1.5)
		board.draw_circle(Vector2(seam_x - 6.0, y + 12.0), 1.8, Color(0.15, 0.13, 0.14))
		board.draw_circle(Vector2(seam_x + 6.0, y + 12.0), 1.8, Color(0.15, 0.13, 0.14))
		plank_idx += 1

	# Recessed dark parchment header bar
	board.draw_rect(Rect2(8, 6, sz.x - 16, 28), Color(0.10, 0.08, 0.10, 0.82))
	board.draw_rect(Rect2(8, 6, sz.x - 16, 28), Color(0.56, 0.44, 0.24, 0.65), false, 1.5)

	var border_col := Color(0.88, 0.25, 0.22) if stage == 3 else (Color(0.42, 0.84, 0.48) if stage == 2 else Color(0.62, 0.48, 0.26))
	board.draw_rect(Rect2(Vector2.ZERO, sz), border_col, false, 4.0)
	# Brass corner rivets
	for corner in [Vector2(10, 10), Vector2(sz.x - 10, 10), Vector2(10, sz.y - 10), Vector2(sz.x - 10, sz.y - 10)]:
		board.draw_circle(corner, 4.5, Color(0.18, 0.13, 0.08))
		board.draw_circle(corner, 3.0, Color(0.82, 0.66, 0.34))

	# Top HUD inside board: Woven Rope Medallions (Integrity) & Timer
	board.draw_string(font, Vector2(18, 25), "INTEGRITY:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.88, 0.72))
	for hi in range(max_integrity):
		var hx := 108.0 + hi * 24.0
		var active := hi < integrity
		board.draw_circle(Vector2(hx, 20), 8.5, Color(0.08, 0.06, 0.07))
		board.draw_circle(Vector2(hx, 20), 7.0, Color(0.36, 0.78, 0.48) if active else Color(0.28, 0.15, 0.15))
		if active:
			board.draw_circle(Vector2(hx - 2.0, 18.0), 2.2, Color(0.75, 0.96, 0.78))

	var frac := clampf(time_left / maxf(0.1, time_max), 0.0, 1.0)
	var t_rect := Rect2(Vector2(342, 13), Vector2(248, 14))
	board.draw_rect(t_rect, Color(0.10, 0.08, 0.09))
	var fill_col := Color(0.92, 0.28, 0.24) if frac < 0.30 else Color(0.88, 0.70, 0.28)
	board.draw_rect(Rect2(t_rect.position, Vector2(t_rect.size.x * frac, t_rect.size.y)), fill_col)
	board.draw_rect(Rect2(t_rect.position, Vector2(t_rect.size.x * frac, 4.0)), Color(1.0, 0.92, 0.68, 0.35))
	board.draw_rect(t_rect, Color(0.78, 0.65, 0.40), false, 1.5)
	board.draw_string(font, Vector2(288, 25), "%.1fs" % time_left, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, fill_col)

	# Chalk-drawn medieval blueprint weave guide on oak board
	if pegs.size() >= 2:
		for i in range(pegs.size() - 1):
			board.draw_line(pegs[i], pegs[i + 1], Color(0.92, 0.86, 0.72, 0.18), 4.0)

	# Rusty Iron Snag Spikes (Hazards!)
	for sp in snags:
		var pulse_haz := 14.5 + sin(Time.get_ticks_msec() * 0.008 + sp.x) * 2.0
		board.draw_circle(sp, pulse_haz, Color(0.88, 0.18, 0.16, 0.20))
		board.draw_circle(sp + Vector2(2, 3), 10.0, Color(0.06, 0.04, 0.04, 0.55))
		board.draw_circle(sp, 10.0, Color(0.14, 0.08, 0.08))
		board.draw_circle(sp, 8.0, Color(0.64, 0.20, 0.18))
		board.draw_circle(sp - Vector2(2, 2), 3.0, Color(0.88, 0.36, 0.30))
		board.draw_line(sp + Vector2(-4, -4), sp + Vector2(4, 4), Color(0.98, 0.85, 0.75), 1.8)
		board.draw_line(sp + Vector2(4, -4), sp + Vector2(-4, 4), Color(0.98, 0.85, 0.75), 1.8)

	# Woven braided hemp strand so far (or whipped/unraveling loose ends on snap failure)
	var rope_col := Color(0.28, 0.62, 0.46) if active_knot_id == "dragon_splice" else Color(0.74, 0.58, 0.30)
	var rope_hi := Color(0.56, 0.88, 0.68) if active_knot_id == "dragon_splice" else Color(0.92, 0.78, 0.46)
	if stage == 3:
		rope_col = Color(0.76, 0.26, 0.22)
		rope_hi = Color(0.98, 0.52, 0.36)
		var recoil := clampf(1.0 - complete_timer / 1.05, 0.0, 1.0)
		var snap_flash := clampf(complete_timer / 1.05, 0.0, 1.0)
		board.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.90, 0.20, 0.16, snap_flash * 0.24))
		if threaded_count >= 2:
			for i in range(threaded_count - 1):
				var a := pegs[i]
				var b := pegs[i + 1]
				var whip_dir := Vector2(-24.0, -18.0) if i % 2 == 0 else Vector2(24.0, 22.0)
				var mid := ((a + b) * 0.5).lerp((a + b) * 0.5 + whip_dir, recoil)
				var a_slack := a.lerp(a + whip_dir * 0.45, recoil * 0.75)
				var b_slack := b.lerp(a + whip_dir * 0.90, recoil * 0.85)
				var alpha_r := clampf(1.0 - recoil * 0.65, 0.25, 1.0)
				board.draw_line(a_slack, mid, Color(rope_col.r, rope_col.g, rope_col.b, alpha_r), 6.0)
				board.draw_line(mid, b_slack, Color(rope_hi.r, rope_hi.g, rope_hi.b, alpha_r), 3.0)
	elif threaded_count >= 2:
		for i in range(threaded_count - 1):
			var a := pegs[i]
			var b := pegs[i + 1]
			var mid := (a + b) * 0.5 + Vector2(0, -14.0 if i % 2 == 0 else 14.0)
			board.draw_line(a + Vector2(2, 4), mid + Vector2(2, 4), Color(0.05, 0.03, 0.02, 0.45), 11.0)
			board.draw_line(mid + Vector2(2, 4), b + Vector2(2, 4), Color(0.05, 0.03, 0.02, 0.45), 11.0)
			board.draw_line(a, mid, Color(0.11, 0.08, 0.05), 11.0)
			board.draw_line(mid, b, Color(0.11, 0.08, 0.05), 11.0)
			board.draw_line(a, mid, rope_col, 7.5)
			board.draw_line(mid, b, rope_col, 7.5)
			board.draw_line(a, mid, rope_hi, 2.2)
			board.draw_line(mid, b, rope_hi, 2.2)

	# Live trailing strand following mouse pointer during stage 0
	if stage == 0 and threaded_count >= 1 and threaded_count < pegs.size() and mouse_inside:
		var last_p := pegs[threaded_count - 1]
		board.draw_line(last_p, mouse_pos, Color(0.11, 0.08, 0.05, 0.88), 8.5)
		board.draw_line(last_p, mouse_pos, rope_hi, 4.2)

	# Carved Brass Rigging Pegs
	for i in range(pegs.size()):
		var p := pegs[i]
		var is_done := i < threaded_count
		var is_next := (stage == 0 and i == threaded_count)
		if is_next:
			var pulse := 23.0 + sin(Time.get_ticks_msec() * 0.012) * 4.0
			board.draw_circle(p, pulse, Color(0.98, 0.82, 0.36, 0.30))
			board.draw_arc(p, pulse - 2.0, 0.0, TAU, 24, Color(0.98, 0.86, 0.48, 0.65), 1.5)
		board.draw_circle(p + Vector2(2, 3), 15.0, Color(0.06, 0.04, 0.04, 0.50))
		board.draw_circle(p, 15.5, Color(0.12, 0.09, 0.08))
		var peg_col := Color(0.44, 0.76, 0.48) if is_done else (Color(0.94, 0.74, 0.28) if is_next else Color(0.52, 0.42, 0.28))
		board.draw_circle(p, 12.5, peg_col)
		board.draw_circle(p - Vector2(2.5, 2.5), 4.0, Color(1.0, 0.95, 0.76, 0.40))
		board.draw_string(font, p + Vector2(-4, 5), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.10, 0.08, 0.08))

	# Spark particle bursts
	for sp in spark_particles:
		var alpha := clampf(float(sp["life"]) / float(sp["max_life"]), 0.0, 1.0)
		var c: Color = sp["col"]
		c.a = alpha
		board.draw_circle(sp["pos"], 2.8 * alpha + 1.0, c)

	# Brass & Parchment Tension Cinch Meter (Stage 1, 2 & 3)
	if stage >= 1:
		var bar_rect := Rect2(Vector2(105, 252), Vector2(400, 26))
		board.draw_rect(Rect2(bar_rect.position - Vector2(4, 4), bar_rect.size + Vector2(8, 8)), Color(0.09, 0.07, 0.08, 0.90))
		board.draw_rect(bar_rect, Color(0.14, 0.11, 0.12))
		var half_w := sweet_width * 0.5
		var sweet_rect := Rect2(Vector2(105 + 400 * (0.5 - half_w), 252), Vector2(400 * sweet_width, 26))
		board.draw_rect(sweet_rect, Color(0.88, 0.68, 0.22))
		board.draw_rect(Rect2(sweet_rect.position, Vector2(sweet_rect.size.x, 6)), Color(0.98, 0.88, 0.48))
		for tick in range(1, 8):
			var tx := bar_rect.position.x + bar_rect.size.x * (float(tick) / 8.0)
			board.draw_line(Vector2(tx, 252), Vector2(tx, 258), Color(0.65, 0.58, 0.42, 0.45), 1.0)
		board.draw_rect(bar_rect, Color(0.84, 0.72, 0.46), false, 2.0)
		var cx := bar_rect.position.x + bar_rect.size.x * tension_cursor
		board.draw_rect(Rect2(Vector2(cx - 5, 245), Vector2(10, 40)), Color(0.10, 0.08, 0.08))
		board.draw_rect(Rect2(Vector2(cx - 3.5, 246), Vector2(7, 38)), Color(0.98, 0.94, 0.84))

	if not feedback_msg.is_empty():
		var msg_col := Color(0.58, 0.96, 0.62) if stage == 2 else Color(0.98, 0.42, 0.36)
		board.draw_string(font, Vector2(95, 52), feedback_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, msg_col)
