extends RefCounted

## Offscreen / quick-windowed PNG viewport capture runner (--visual-audit).
## Renders real OpenGL frames (with SubViewports, shadows, lights, UI & dialogue boxes)
## to tools/audit_shots/*.png so agents inspect real rendered frames before reporting done.

const SHOT_OUT_DIR := "tools/audit_shots"

var main = null
var active: bool = false
var _shots: Array[Dictionary] = []
var _shot_idx: int = -1
var _wait_frames: int = 0


static func should_run() -> bool:
	var all_args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in all_args:
		if str(arg) == "--visual-audit" or str(arg).begins_with("--audit-filter"):
			return true
	return false


static func _get_filter() -> Array[String]:
	var out: Array[String] = []
	for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		var s := str(arg)
		if s.begins_with("--audit-filter="):
			for part in s.substr("--audit-filter=".length()).split(",", false):
				out.append(part.strip_edges())
	return out


func start(main_node) -> void:
	main = main_node
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + SHOT_OUT_DIR))
	var defs: Array[Dictionary] = [
		{"id": "brabant_left", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_left")},
		{"id": "brabant_dialogue", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_dialogue")},
		{"id": "brabant_sluice", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_sluice")},
		{"id": "louvain_west_gate", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_west_gate")},
		{"id": "louvain_vismarkt", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_vismarkt")},
		{"id": "louvain_grote_markt", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_grote_markt")},
		{"id": "louvain_stpeters", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_stpeters")},
		{"id": "louvain_lakenhalle", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_lakenhalle")},
		{"id": "louvain_cloister", "preset": "book2_louvain_abbey", "setup": Callable(self, "_setup_louvain_cloister")},
	]
	var flt := _get_filter()
	_shots.clear()
	for d in defs:
		if flt.is_empty() or flt.has(str(d["id"])) or flt.has(str(d["preset"])):
			_shots.append(d)
	if _shots.is_empty():
		print("AUDIT_SKIP no matching shots")
		main.get_tree().quit(0)
		return
	active = true
	_shot_idx = -1
	_advance_shot()


func step(_delta: float) -> void:
	if not active or main == null:
		return
	if _wait_frames > 0:
		_wait_frames -= 1
		if _wait_frames == 0:
			_capture_current()
			_advance_shot()


func _advance_shot() -> void:
	_shot_idx += 1
	if _shot_idx >= _shots.size():
		active = false
		print("AUDIT_DONE count=%d" % _shots.size())
		main.get_tree().quit(0)
		return
	var spec: Dictionary = _shots[_shot_idx]
	main._playtest_jump_to(str(spec["preset"]))
	var cb: Callable = spec.get("setup", Callable())
	if cb.is_valid():
		cb.call()
	if main.camera != null:
		main.camera.position = main.player.position
		main.camera.reset_smoothing()
	if main.companion != null:
		main.companion.queue_redraw()
	if main.active_region != null:
		main.active_region.queue_redraw()
		main.active_region.queue_foreground_redraw()
	_wait_frames = 5


func _capture_current() -> void:
	var spec: Dictionary = _shots[_shot_idx]
	var tex: ViewportTexture = main.get_viewport().get_texture()
	if tex == null:
		push_error("AUDIT_FAIL null viewport texture on " + str(spec["id"]))
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		push_error("AUDIT_FAIL empty image on " + str(spec["id"]))
		return
	var save_path := ProjectSettings.globalize_path("res://%s/%s.png" % [SHOT_OUT_DIR, str(spec["id"])])
	var err := img.save_png(save_path)
	print("AUDIT_SHOT id=%s err=%d path=%s" % [str(spec["id"]), err, save_path])


func _setup_brabant_left() -> void:
	GameState.hatchling_fed_count = 0
	main.player.position = Vector2(930, 700)
	main.player.facing = Vector2.LEFT
	main.player.is_moving = false
	main.companion.facing = Vector2.LEFT
	main.companion.global_position = Vector2(972, 704)
	main.companion.is_moving = false
	main.companion.stay_pos = main.companion.global_position


func _setup_brabant_dialogue() -> void:
	GameState.hatchling_fed_count = 1
	GameState.dragon_bond = 22
	main.player.position = Vector2(930, 695)
	main.ui.show_dialogue([
		{
			"speaker": GameState.player_name,
			"portrait": "portrait_boy17.png",
			"text": "Hold up—see those crimson Church lanterns and halberd silhouettes beyond the gate arch? Let us make sure four full wrapped lines fit cleanly without clipping near the taskbar!"
		}
	])
	if main.ui.dialogue_panel != null:
		main.ui.dialogue_panel.dialogue_visible_chars = main.ui.dialogue_panel.dialogue_full_text.length()
		main.ui.dialogue_panel.dialogue_label.text = main.ui.dialogue_panel.dialogue_full_text


func _setup_brabant_sluice() -> void:
	GameState.hatchling_fed_count = 1
	GameState.dragon_bond = 22
	GameState.brabant_vent_unlocked = false
	main.active_region.set_body_collision_enabled(main.active_region.gate_body, true)
	main.active_region.gate_open_anim = 0.0
	main.player.position = Vector2(1312, 608)
	main.player.facing = Vector2.RIGHT
	main.companion.global_position = Vector2(1284, 616)


func _setup_louvain_west_gate() -> void:
	main.player.position = Vector2(226, 1040)
	main.companion.global_position = Vector2(246, 1054)


func _setup_louvain_vismarkt() -> void:
	main.player.position = Vector2(624, 886)
	main.companion.global_position = Vector2(598, 898)


func _setup_louvain_grote_markt() -> void:
	main.player.position = Vector2(1048, 998)
	main.companion.global_position = Vector2(1018, 1006)


func _setup_louvain_stpeters() -> void:
	main.player.position = Vector2(1040, 742)
	main.companion.global_position = Vector2(1012, 750)


func _setup_louvain_lakenhalle() -> void:
	main.player.position = Vector2(780, 1388)
	main.companion.global_position = Vector2(752, 1396)


func _setup_louvain_cloister() -> void:
	main.player.position = Vector2(1424, 684)
	main.companion.global_position = Vector2(1396, 694)
