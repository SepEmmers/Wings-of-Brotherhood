extends PanelContainer
class_name MasonCraneMinigamePanel

## Interactive Sint-Pieterskerk Timber Crane Block-Stacking Minigame:
## Guide the quarry crane trolley left/right ([A]/[D], Arrows, or Mouse), balance the
## gentle rope plumb-sway, and drop 3 Gobertange ashlar stone courses + the Gothic Slate Spire
## ([Space] or Left-Click) to crown Louvain's skyline higher than Brussels.

signal crane_completed
signal crane_cancelled

const TIERS: Array[Dictionary] = [
	{"name": "Lower Ashlar Course",   "kind": "course",   "w": 128.0, "h": 30.0, "sway": 10.0, "spd": 2.0},
	{"name": "Belfry Lancet Tier",    "kind": "lancet",   "w": 104.0, "h": 32.0, "sway": 13.0, "spd": 2.3},
	{"name": "Pinnacle Cornice Tier", "kind": "pinnacle", "w": 84.0,  "h": 24.0, "sway": 15.0, "spd": 2.5},
	{"name": "Gothic Slate Spire",    "kind": "spire",    "w": 68.0,  "h": 72.0, "sway": 16.0, "spd": 2.7},
]

const STACK_BASE_X: float = 270.0
const STACK_BASE_Y: float = 224.0
const JIB_Y: float = 22.0
const BRUSSELS_MARK_Y: float = 80.0

var current_tier: int = 0
var placed_tiers: Array[Dictionary] = []
var trolley_x: float = 266.0
var sway_t: float = 0.0
var hook_x: float = 266.0
var hook_y: float = 76.0
var drop_state: String = "swinging" # swinging | falling | done
var drop_vy: float = 0.0
var finish_timer: float = 0.0
var miss_flash: float = 0.0
var dust_fx: Array[Dictionary] = []
var feedback_msg: String = ""

var title_lbl: Label
var desc_lbl: Label
var hint_lbl: Label
var feedback_lbl: Label
var board: Control
var cancel_btn: Button
var _sky_tex: Texture2D
var _assets = null


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(588, 464)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -294
	offset_top = -232
	offset_right = 294
	offset_bottom = 232

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
	title_lbl.text = "SINT-PIETERSKERK CRANE: RACE FOR THE HIGHEST SPIRE"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.52))
	header.add_child(title_lbl)

	cancel_btn = Button.new()
	cancel_btn.text = "Close [Esc]"
	cancel_btn.pressed.connect(close_minigame)
	header.add_child(cancel_btn)

	desc_lbl = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.text = "Steer the crane jib ([A]/[D], Arrows, or Mouse), line up the Gobertange stonework above St. Peter's tower, and press [Space] or Click to lower each course and crown the Gothic Spire!"
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	vbox.add_child(desc_lbl)

	board = Control.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board.custom_minimum_size = Vector2(540, 280)
	board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	board.draw.connect(_draw_board)
	board.gui_input.connect(_on_board_gui_input)
	vbox.add_child(board)

	feedback_lbl = Label.new()
	feedback_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	feedback_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_lbl.position = Vector2(12, 8)
	feedback_lbl.custom_minimum_size = Vector2(516, 22)
	feedback_lbl.add_theme_font_size_override("font_size", 13)
	feedback_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.46))
	board.add_child(feedback_lbl)

	hint_lbl = Label.new()
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.text = "Course 1 / 4  •  [A]/[D] or Mouse to steer  •  [Space] / Left-Click to drop"
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(0.78, 0.84, 0.90))
	vbox.add_child(hint_lbl)

	if _assets == null:
		_assets = get_tree().root.find_child("PixelAssets", true, false)
	if _assets != null and _assets.has_method("get_tex"):
		_sky_tex = _assets.get_tex("ui_mason_crane_sky.png")


func setup(assets_ref) -> void:
	_assets = assets_ref
	if _assets != null and _assets.has_method("get_tex"):
		_sky_tex = _assets.get_tex("ui_mason_crane_sky.png")


func apply_medieval_ui_theme(panel_sb: StyleBox, btn_norm: StyleBox, btn_hov: StyleBox, btn_prs: StyleBox) -> void:
	if panel_sb != null:
		add_theme_stylebox_override("panel", panel_sb)
	if cancel_btn != null:
		cancel_btn.add_theme_stylebox_override("normal", btn_norm)
		cancel_btn.add_theme_stylebox_override("hover", btn_hov)
		cancel_btn.add_theme_stylebox_override("pressed", btn_prs)


func start_crane_build() -> void:
	if _sky_tex == null and _assets != null and _assets.has_method("get_tex"):
		_sky_tex = _assets.get_tex("ui_mason_crane_sky.png")
	current_tier = 0
	placed_tiers.clear()
	trolley_x = STACK_BASE_X
	sway_t = 0.0
	drop_state = "swinging"
	drop_vy = 0.0
	finish_timer = 0.0
	miss_flash = 0.0
	dust_fx.clear()
	feedback_msg = "Steer the crane and set Course 1!"
	_sync_labels()
	visible = true


func close_minigame() -> void:
	visible = false
	emit_signal("crane_cancelled")


func _sync_labels() -> void:
	if feedback_lbl != null:
		feedback_lbl.text = feedback_msg
	if hint_lbl != null:
		if current_tier >= TIERS.size():
			hint_lbl.text = "St. Peter's Gothic Spire stands taller than Brussels' Belfry!"
		else:
			hint_lbl.text = "Tier %d / %d (%s)  •  [A]/[D] or Mouse to steer  •  [Space] / Click to lower" % [
				current_tier + 1, TIERS.size(), String(TIERS[current_tier]["name"])
			]


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.keycode
		if kc == KEY_ESCAPE:
			close_minigame()
			get_viewport().set_input_as_handled()
		elif (kc == KEY_SPACE or kc == KEY_ENTER or kc == KEY_E) and drop_state == "swinging":
			_release_block()
			get_viewport().set_input_as_handled()


func _on_board_gui_input(event: InputEvent) -> void:
	if not visible or drop_state != "swinging":
		return
	if event is InputEventMouseMotion:
		trolley_x = clampf(event.position.x, 108.0, 424.0)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trolley_x = clampf(event.position.x, 108.0, 424.0)
		_release_block()


func _release_block() -> void:
	if drop_state != "swinging" or current_tier >= TIERS.size():
		return
	drop_state = "falling"
	drop_vy = 60.0
	SoundManager.play_swing()


func _top_stack_center_and_y() -> Dictionary:
	var cy := STACK_BASE_Y
	var cx := STACK_BASE_X
	for pt: Dictionary in placed_tiers:
		cy -= float(pt["h"])
		cx = float(pt["x"])
	return {"x": cx, "y": cy}


func _process(delta: float) -> void:
	if not visible:
		return
	miss_flash = maxf(0.0, miss_flash - delta * 2.5)
	for i in range(dust_fx.size() - 1, -1, -1):
		var sp: Dictionary = dust_fx[i]
		sp["life"] = float(sp["life"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		sp["vel"] = Vector2(sp["vel"]) * 0.90 + Vector2(0, 75.0) * delta
		if float(sp["life"]) <= 0.0:
			dust_fx.remove_at(i)

	if drop_state == "done":
		finish_timer -= delta
		if finish_timer <= 0.0:
			visible = false
			emit_signal("crane_completed")
		board.queue_redraw()
		return

	if current_tier < TIERS.size():
		var tier: Dictionary = TIERS[current_tier]
		if drop_state == "swinging":
			var move_x := Input.get_axis("move_left", "move_right")
			if absf(move_x) > 0.05:
				trolley_x = clampf(trolley_x + move_x * 230.0 * delta, 108.0, 424.0)
			sway_t += delta * float(tier["spd"])
			hook_x = trolley_x + sin(sway_t) * float(tier["sway"])
			var rest_top := _top_stack_center_and_y()
			hook_y = clampf(minf(68.0, float(rest_top["y"]) - float(tier["h"]) - 28.0), 38.0, 78.0)
		elif drop_state == "falling":
			drop_vy += 760.0 * delta
			hook_y += drop_vy * delta
			var top_info := _top_stack_center_and_y()
			var th: float = float(tier["h"])
			if hook_y + th >= float(top_info["y"]):
				_resolve_landing(tier, top_info)

	_sync_labels()
	board.queue_redraw()


func _resolve_landing(tier: Dictionary, top_info: Dictionary) -> void:
	var target_x: float = float(top_info["x"])
	var prev_w: float = float(placed_tiers[-1]["w"]) if not placed_tiers.is_empty() else 166.0
	var tw: float = float(tier["w"])
	var th: float = float(tier["h"])
	var dx := absf(hook_x - target_x)
	var tol := minf(tw * 0.42, prev_w * 0.38) + 8.0
	if dx <= tol:
		var snap_x := target_x if dx <= 11.0 else lerpf(target_x, hook_x, 0.35)
		placed_tiers.append({"kind": tier["kind"], "w": tw, "h": th, "x": snap_x, "y": float(top_info["y"]) - th})
		_spawn_dust(Vector2(snap_x, float(top_info["y"])), 14, Color(0.96, 0.90, 0.72))
		SoundManager.play_cage_break()
		current_tier += 1
		if current_tier >= TIERS.size():
			drop_state = "done"
			finish_timer = 1.05
			feedback_msg = "Spire crowned! Louvain towers over Brussels' Belfry!"
			SoundManager.play_chime()
			_spawn_dust(Vector2(snap_x, float(top_info["y"]) - th * 0.6), 24, Color(1.0, 0.88, 0.38))
		else:
			drop_state = "swinging"
			feedback_msg = "Plumb & mortar-locked! Ready next tier."
	else:
		miss_flash = 1.0
		drop_state = "swinging"
		feedback_msg = "Off plumb! Reel back up and center cleanly over the stonework."
		SoundManager.play_hit()


func debug_complete_all_tiers() -> void:
	placed_tiers.clear()
	var y_acc := STACK_BASE_Y
	for t: Dictionary in TIERS:
		y_acc -= float(t["h"])
		placed_tiers.append({"kind": t["kind"], "w": float(t["w"]), "h": float(t["h"]), "x": STACK_BASE_X, "y": y_acc})
	current_tier = TIERS.size()
	drop_state = "done"
	visible = false
	emit_signal("crane_completed")


func _spawn_dust(origin: Vector2, count: int, col: Color) -> void:
	for _i in range(count):
		var a := randf_range(0.0, TAU)
		var s := randf_range(28.0, 110.0)
		dust_fx.append({"pos": origin, "vel": Vector2(cos(a), sin(a) - 0.5) * s, "life": 0.45, "col": col})


func _draw_masonry_block(cx: float, y: float, w: float, h: float, kind: String) -> void:
	var r := Rect2(cx - w * 0.5, y, w, h)
	if kind == "spire":
		# Tapered slate Gothic Spire + golden finial banner
		var pts := PackedVector2Array([
			Vector2(cx - w * 0.36, y + h),
			Vector2(cx + w * 0.36, y + h),
			Vector2(cx + 2.0, y + 14.0),
			Vector2(cx - 2.0, y + 14.0),
		])
		board.draw_colored_polygon(pts, Color(0.24, 0.28, 0.36))
		board.draw_polyline(PackedVector2Array([pts[0], pts[3], pts[2], pts[1], pts[0]]), Color(0.11, 0.12, 0.16), 2.0)
		board.draw_line(Vector2(cx - 1, y + h - 2), Vector2(cx - 1, y + 14), Color(0.42, 0.48, 0.56), 2.0)
		# Brass flagpole & Louvain red/gold pennant
		board.draw_line(Vector2(cx, y + 14), Vector2(cx, y - 4), Color(0.96, 0.80, 0.30), 2.0)
		board.draw_rect(Rect2(cx + 1, y - 2, 16, 8), Color(0.78, 0.18, 0.18))
		board.draw_rect(Rect2(cx + 1, y + 1, 16, 2), Color(0.95, 0.88, 0.72))
		return

	# Warm Brabant Gobertange limestone ashlar course
	board.draw_rect(r, Color(0.84, 0.78, 0.65))
	board.draw_rect(r, Color(0.20, 0.17, 0.14), false, 2.0)
	board.draw_line(r.position + Vector2(2, 2), Vector2(r.end.x - 2, r.position.y + 2), Color(0.94, 0.90, 0.80), 2.0)
	board.draw_line(r.position + Vector2(2, h * 0.5), Vector2(r.end.x - 2, h * 0.5 + r.position.y), Color(0.62, 0.57, 0.48), 1.5)
	if kind == "lancet":
		for lx in [-w * 0.24, 0.0, w * 0.24]:
			board.draw_rect(Rect2(cx + lx - 5.0, y + 7.0, 10.0, h - 13.0), Color(0.18, 0.18, 0.24))
			board.draw_rect(Rect2(cx + lx - 3.0, y + 9.0, 6.0, h - 17.0), Color(0.94, 0.76, 0.34, 0.82))
	elif kind == "pinnacle":
		for px in [-w * 0.44, w * 0.44]:
			board.draw_rect(Rect2(cx + px - 4.0, y - 10.0, 8.0, 12.0), Color(0.88, 0.82, 0.70))
			board.draw_colored_polygon(PackedVector2Array([Vector2(cx + px - 5, y - 10), Vector2(cx + px + 5, y - 10), Vector2(cx + px, y - 19)]), Color(0.28, 0.32, 0.40))


func _draw_board() -> void:
	var sz := board.size
	if _sky_tex != null:
		board.draw_texture_rect(_sky_tex, Rect2(Vector2.ZERO, sz), false)
	else:
		board.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.15, 0.16, 0.24))
		board.draw_rect(Rect2(STACK_BASE_X - 96.0, STACK_BASE_Y, 192.0, sz.y - STACK_BASE_Y), Color(0.76, 0.70, 0.58))
	if miss_flash > 0.05:
		board.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.86, 0.22, 0.18, miss_flash * 0.24))

	# Brussels Belfry benchmark line across skyline
	board.draw_line(Vector2(60, BRUSSELS_MARK_Y), Vector2(sz.x - 18, BRUSSELS_MARK_Y), Color(0.94, 0.78, 0.34, 0.52), 1.5)
	if _assets != null and _assets.has_method("get_ui_font"):
		var f: Font = _assets.get_ui_font()
		if f != null:
			board.draw_string(f, Vector2(364, BRUSSELS_MARK_Y - 5), "Brussels Belfry Mark", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.96, 0.84, 0.44, 0.90))

	# Overhead timber crane jib beam + movable pulley trolley
	board.draw_rect(Rect2(68, JIB_Y - 6, sz.x - 136, 10), Color(0.38, 0.24, 0.14))
	board.draw_line(Vector2(68, JIB_Y - 6), Vector2(sz.x - 68, JIB_Y - 6), Color(0.62, 0.44, 0.26), 2.0)
	board.draw_rect(Rect2(trolley_x - 12, JIB_Y - 8, 24, 14), Color(0.28, 0.22, 0.18))
	board.draw_circle(Vector2(trolley_x, JIB_Y + 4), 4.0, Color(0.86, 0.70, 0.32))

	# Already-placed masonry courses
	for pt: Dictionary in placed_tiers:
		_draw_masonry_block(float(pt["x"]), float(pt["y"]), float(pt["w"]), float(pt["h"]), String(pt["kind"]))

	# Faint vertical plumb guide down from hook to help align stonework cleanly
	if current_tier < TIERS.size() and drop_state != "done":
		var tier: Dictionary = TIERS[current_tier]
		var tw: float = float(tier["w"])
		var th: float = float(tier["h"])
		board.draw_line(Vector2(hook_x, hook_y + th), Vector2(hook_x, STACK_BASE_Y), Color(0.96, 0.88, 0.50, 0.22), 1.5)
		board.draw_line(Vector2(trolley_x, JIB_Y + 6), Vector2(hook_x, hook_y + 2), Color(0.76, 0.62, 0.40), 2.0)
		_draw_masonry_block(hook_x, hook_y, tw, th, String(tier["kind"]))

	for sp: Dictionary in dust_fx:
		var a := clampf(float(sp["life"]) / 0.45, 0.0, 1.0)
		var c: Color = sp["col"]
		board.draw_circle(Vector2(sp["pos"]), 3.2, Color(c.r, c.g, c.b, a))
