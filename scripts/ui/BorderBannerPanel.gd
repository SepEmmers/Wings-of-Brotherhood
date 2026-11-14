extends Control

## Non-blocking carved oak & brass archway signboard shown briefly after crossing a region gate.

var title_text: String = ""
var sub_text: String = ""
var elapsed: float = 0.0
var duration: float = 2.05
var active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(460, 88)
	size = Vector2(360, 52)
	z_index = 25
	visible = false


func show_banner(title_txt: String, sub_txt: String = "", hold_duration: float = 2.05) -> void:
	title_text = title_txt.strip_edges()
	if title_text == "":
		return
	sub_text = sub_txt.strip_edges()
	duration = maxf(0.9, hold_duration)
	elapsed = 0.0
	active = true
	visible = true
	queue_redraw()


func hide_banner() -> void:
	active = false
	visible = false


func step(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if elapsed >= duration:
		hide_banner()
		return
	var enter_t := clampf(elapsed / 0.22, 0.0, 1.0)
	var exit_t := clampf((duration - elapsed) / 0.38, 0.0, 1.0)
	var alpha := minf(enter_t, exit_t)
	var slide := (1.0 - ease(enter_t, -1.8)) * -12.0
	position = Vector2(460.0, 90.0 + slide)
	modulate.a = alpha
	queue_redraw()


func _draw() -> void:
	if not active or title_text == "":
		return
	var font := ThemeDB.fallback_font
	var box := Rect2(Vector2.ZERO, size)
	var inner := box.grow(-3.0)

	# Drop shadow + dark aged oak signboard fill
	draw_rect(Rect2(box.position + Vector2(2, 4), box.size), Color(0.03, 0.02, 0.02, 0.62))
	draw_rect(box, Color(0.16, 0.11, 0.07, 0.94))
	draw_rect(inner, Color(0.22, 0.16, 0.10, 0.94))
	draw_rect(box, Color(0.76, 0.60, 0.30, 0.92), false, 2.0)
	draw_rect(inner, Color(0.50, 0.38, 0.20, 0.65), false, 1.0)

	# Four corner brass rivets
	for rp in [
		Vector2(6, 6), Vector2(size.x - 8, 6),
		Vector2(6, size.y - 8), Vector2(size.x - 8, size.y - 8),
	]:
		draw_rect(Rect2(rp, Vector2(3, 3)), Color(0.88, 0.72, 0.38, 0.95))

	# Small carved diamond crest either side of title
	var title_col := Color(0.97, 0.88, 0.62)
	var has_sub := sub_text != ""
	var title_y := 23.0 if has_sub else 31.0
	var ts := font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	var tx := (size.x - ts.x) * 0.5
	draw_string(font, Vector2(tx + 1.0, title_y + 1.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.05, 0.03, 0.02, 0.88))
	draw_string(font, Vector2(tx, title_y), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, title_col)

	for dx in [tx - 14.0, tx + ts.x + 14.0]:
		var cy := title_y - 5.0
		var dia := PackedVector2Array([Vector2(dx, cy - 3.5), Vector2(dx + 3.5, cy), Vector2(dx, cy + 3.5), Vector2(dx - 3.5, cy)])
		draw_colored_polygon(dia, Color(0.82, 0.66, 0.34, 0.88))

	if has_sub:
		var ss := font.get_string_size(sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		var sx := (size.x - ss.x) * 0.5
		draw_string(font, Vector2(sx + 1.0, 41.0), sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.05, 0.03, 0.02, 0.80))
		draw_string(font, Vector2(sx, 40.0), sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.82, 0.76, 0.62))
