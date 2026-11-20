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
	GameState.suppress_item_banner = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + SHOT_OUT_DIR))
	var defs: Array[Dictionary] = [
		{"id": "heist_cliff_leap", "preset": "cutscene_kestrel_escape", "setup": Callable(self, "_setup_heist_cliff_leap")},
		{"id": "heist_sky_glide", "preset": "cutscene_kestrel_escape", "setup": Callable(self, "_setup_heist_sky_glide")},
		{"id": "hatch_climax", "preset": "book2_egg_hatching", "setup": Callable(self, "_setup_hatch_climax")},
		{"id": "hatch_bond", "preset": "book2_egg_hatching", "setup": Callable(self, "_setup_hatch_bond")},
		{"id": "brabant_left", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_left")},
		{"id": "brabant_dragon_spew", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_dragon_spew")},
		{"id": "brabant_dragon_eat", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_dragon_eat")},
		{"id": "brabant_dialogue", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_dialogue")},
		{"id": "brabant_sluice", "preset": "book2_brabant_hatchling", "setup": Callable(self, "_setup_brabant_sluice")},
		{"id": "hd2d_brabant_camp_close", "preset": "book2_brabant_hd2d", "setup": Callable(self, "_setup_hd2d_brabant_camp_close")},
		{"id": "hd2d_brabant_camp_2d_compare", "preset": "book2_brabant_hd2d", "setup": Callable(self, "_setup_hd2d_brabant_camp_2d_compare")},
		{"id": "hd2d_brabant_vista", "preset": "book2_brabant_hd2d", "setup": Callable(self, "_setup_hd2d_brabant_vista")},
		{"id": "hd2d_brabant_sluice_bridge", "preset": "book2_brabant_hd2d", "setup": Callable(self, "_setup_hd2d_brabant_sluice_bridge")},
		{"id": "hd2d_brabant_dialogue", "preset": "book2_brabant_hd2d", "setup": Callable(self, "_setup_hd2d_brabant_dialogue")},
		{"id": "hd2d_brabant_orbit_angle", "preset": "book2_brabant_hd2d", "setup": Callable(self, "_setup_hd2d_brabant_orbit_angle")},
		{"id": "hd2d_bruges_ship_quay", "preset": "ship_docked", "setup": Callable(self, "_setup_hd2d_bruges_ship_quay")},
		{"id": "hd2d_bruges_bakery_square", "preset": "bruges_free", "setup": Callable(self, "_setup_hd2d_bruges_bakery_square")},
		{"id": "hd2d_bruges_cottage_2d_compare", "preset": "bruges_free", "setup": Callable(self, "_setup_hd2d_bruges_cottage_2d_compare")},
		{"id": "hd2d_bruges_dawn_stealth", "preset": "ambush", "setup": Callable(self, "_setup_hd2d_bruges_dawn_stealth")},
		{"id": "hd2d_settings_gameplay", "preset": "bruges_free", "setup": Callable(self, "_setup_hd2d_settings_gameplay")},
		{"id": "louvain_west_gate", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_west_gate")},
		{"id": "louvain_vismarkt", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_vismarkt")},
		{"id": "louvain_grote_markt", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_grote_markt")},
		{"id": "louvain_stpeters", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_stpeters")},
		{"id": "louvain_mason_crane", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_mason_crane")},
		{"id": "louvain_lakenhalle", "preset": "book2_louvain_city", "setup": Callable(self, "_setup_louvain_lakenhalle")},
		{"id": "louvain_cloister", "preset": "book2_louvain_abbey", "setup": Callable(self, "_setup_louvain_cloister")},
		{"id": "louvain_dungeon_nave", "preset": "book2_louvain_catacombs", "setup": Callable(self, "_setup_louvain_dungeon_nave")},
		{"id": "louvain_dungeon_catacombs", "preset": "book2_louvain_catacombs", "setup": Callable(self, "_setup_louvain_dungeon_catacombs")},
		{"id": "louvain_dungeon_library", "preset": "book2_louvain_catacombs", "setup": Callable(self, "_setup_louvain_dungeon_library")},
		{"id": "old_heverlee_woods", "preset": "book2_old_heverlee", "setup": Callable(self, "_setup_old_heverlee_woods")},
		{"id": "old_heverlee_shrine", "preset": "book2_old_heverlee_shrine", "setup": Callable(self, "_setup_old_heverlee_shrine")},
		{"id": "anna_sanctuary_ch1", "preset": "book2_anna_sanctuary", "setup": Callable(self, "_setup_anna_sanctuary_ch1")},
		{"id": "anna_barge_raid", "preset": "book2_anna_barge_raid", "setup": Callable(self, "_setup_anna_barge_raid")},
		{"id": "polish_title_screen", "preset": "boat_sailing", "setup": Callable(self, "_setup_polish_title_screen")},
		{"id": "polish_port_north_gate", "preset": "bruges_free", "setup": Callable(self, "_setup_polish_port_north_gate")},
		{"id": "polish_port_willem_cottage", "preset": "bruges_free", "setup": Callable(self, "_setup_polish_port_willem_cottage")},
		{"id": "polish_willem_house_4room", "preset": "house_evening", "setup": Callable(self, "_setup_polish_willem_house_4room")},
		{"id": "polish_outskirts_cover", "preset": "act4_outskirts", "setup": Callable(self, "_setup_polish_outskirts_cover")},
		{"id": "polish_bruges_south_gate", "preset": "act4_bruges_city", "setup": Callable(self, "_setup_polish_bruges_south_gate")},
		{"id": "polish_bruges_dropped_note", "preset": "act4_bruges_city", "setup": Callable(self, "_setup_polish_bruges_dropped_note")},
		{"id": "polish_sanctuary_scout", "preset": "act4_egg_debate", "setup": Callable(self, "_setup_polish_sanctuary_scout")},
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
		if _wait_frames == 3 and _shot_idx >= 0 and _shot_idx < _shots.size() and str(_shots[_shot_idx]["id"]) == "hd2d_settings_gameplay":
			var sp = main.ui.settings_panel if main.ui != null else null
			if sp != null and sp.tab_pages.size() > 1:
				for ch in sp.tab_pages[1].get_children():
					if ch is ScrollContainer:
						(ch as ScrollContainer).scroll_vertical = 600
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
	if not (str(spec["id"]).begins_with("hatch_") or str(spec["id"]).begins_with("heist_") or str(spec["id"]) == "polish_title_screen") and main.camera != null:
		main.camera.position = main.player.position
		main.camera.reset_smoothing()
	if main.companion != null:
		main.companion.queue_redraw()
	if main.active_region != null:
		main.active_region.queue_redraw()
		main.active_region.queue_foreground_redraw()
		if main.active_region.get("hd2d_stage") != null:
			main.active_region.hd2d_stage.step(0.016, Time.get_ticks_msec() * 0.001)
			main.active_region.hd2d_stage.snap_camera()
	_wait_frames = 5


func _setup_hatch_climax() -> void:
	var cs = main.active_region.hatching_cutscene
	if cs == null:
		return
	cs._enter_closeup_stage_1()
	cs.step(1.7)
	cs.step(1.8)
	cs.step(1.5)
	cs.step(1.85)
	if main.ui != null:
		main.ui.set_fade(0.0, true)
		main.ui.letterbox_amount = 1.0
		main.ui.process_ui(0.01)
	if cs.canvas_node != null:
		cs.canvas_node.queue_redraw()


func _setup_heist_cliff_leap() -> void:
	var cs = main.active_region.heist_cutscene
	if cs == null:
		return
	cs._enter_escape_balcony()
	cs.step(0.6)
	cs.step(0.9)
	cs.step(0.55)
	if main.ui != null:
		main.ui.set_fade(0.0, true)
		main.ui.letterbox_amount = 1.0
		main.ui.process_ui(0.01)
	if cs.canvas_node != null:
		cs.canvas_node.queue_redraw()


func _setup_heist_sky_glide() -> void:
	var cs = main.active_region.heist_cutscene
	if cs == null:
		return
	cs._enter_escape_balcony()
	cs.step(1.4)
	cs.step(1.4)
	cs.step(0.9)
	if main.ui != null:
		main.ui.set_fade(0.0, true)
		main.ui.letterbox_amount = 1.0
		main.ui.process_ui(0.01)
	if cs.canvas_node != null:
		cs.canvas_node.queue_redraw()


func _setup_hatch_bond() -> void:
	var cs = main.active_region.hatching_cutscene
	if cs == null:
		return
	_setup_hatch_climax()
	cs.step(1.1)
	cs.step(1.6)
	if main.ui != null:
		main.ui.set_fade(0.0, true)
		main.ui.letterbox_amount = 1.0
		main.ui.process_ui(0.01)
	if cs.canvas_node != null:
		cs.canvas_node.queue_redraw()


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


func _setup_brabant_dragon_spew() -> void:
	GameState.hatchling_fed_count = 1
	var bz0 := Vector2(main.active_region.brazier_states[0]["pos"])
	main.player.position = bz0 + Vector2(0, 48)
	main.player.facing = Vector2.UP
	main.companion.global_position = bz0 + Vector2(-36, 40)
	main.companion._command_cooldown = 0.0
	main.companion.trigger_command()
	for _i in range(6):
		main.companion.step(0.05)


func _setup_brabant_dragon_eat() -> void:
	GameState.hatchling_fed_count = 1
	main.player.position = Vector2(930, 700)
	main.player.facing = Vector2.RIGHT
	main.companion.global_position = Vector2(912, 712)
	main.companion.play_eat_animation(main.active_region.CAMPFIRE_POS)
	for _i in range(7):
		main.companion.step(0.06)
	main.companion.stay_pos = main.companion.global_position


func _setup_brabant_dialogue() -> void:
	GameState.hatchling_fed_count = 1
	GameState.dragon_bond = 22
	main.player.position = Vector2(930, 695)
	main.ui.show_dialogue([
		{
			"speaker": GameState.player_name,
			"portrait": "portrait_boy17_neutral.png",
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


func _setup_hd2d_brabant_camp_close() -> void:
	main.player.position = Vector2(920, 706)
	main.player.facing = Vector2.RIGHT
	main.player.is_moving = false
	main.companion.global_position = Vector2(886, 718)
	main.companion.facing = Vector2.RIGHT
	main.companion.is_moving = false
	main.active_region.update_nearest_interactable(main.player.position)


func _setup_hd2d_brabant_camp_2d_compare() -> void:
	_setup_hd2d_brabant_camp_close()
	if main.active_region.get("hd2d_stage") != null:
		main.active_region.hd2d_stage.set_hd2d_enabled(false)


func _setup_hd2d_brabant_vista() -> void:
	main.player.position = Vector2(1080, 690)
	main.player.facing = Vector2.RIGHT
	main.player.is_moving = false
	main.companion.global_position = Vector2(1044, 706)
	main.companion.facing = Vector2.RIGHT
	if main.active_region.get("hd2d_stage") != null:
		main.active_region.hd2d_stage.set_wide_vista(true)


func _setup_hd2d_brabant_sluice_bridge() -> void:
	GameState.brabant_vent_unlocked = true
	main.active_region._vent_lever_tripped = true
	main.active_region.gate_open_anim = 1.0
	main.active_region.brazier_states[1]["lit"] = true
	main.player.position = Vector2(1510, 708)
	main.player.facing = Vector2.RIGHT
	main.player.is_moving = false
	main.companion.global_position = Vector2(1472, 720)
	main.companion.facing = Vector2.RIGHT


func _setup_hd2d_brabant_dialogue() -> void:
	_setup_hd2d_brabant_camp_close()
	main.active_region.last_interacted_pos = main.active_region.CAMPFIRE_POS
	main.ui.show_dialogue([
		{
			"speaker": GameState.gold_dragon_name,
			"portrait": GameState.get_hatchling_portrait(),
			"telepathic": true,
			"text": "Warm snapping embers right in my chest—look at the fen mist rising around that old waterwheel! Press [H] anytime to flip between HD-2D and classic 2D."
		}
	])
	if main.ui.dialogue_panel != null:
		main.ui.dialogue_panel.dialogue_visible_chars = main.ui.dialogue_panel.dialogue_full_text.length()
		main.ui.dialogue_panel.dialogue_label.text = main.ui.dialogue_panel.dialogue_full_text


func _setup_hd2d_brabant_orbit_angle() -> void:
	_setup_hd2d_brabant_camp_close()
	if main.active_region.get("hd2d_stage") != null:
		main.active_region.hd2d_stage.set_orbit(42.0, 26.0, 14.0)


func _setup_hd2d_bruges_ship_quay() -> void:
	main.ui.hide_all_overlays()
	main.player.facing = Vector2.RIGHT
	main.player.is_moving = false
	main.active_region.update_nearest_interactable(main.player.position)
	if main.active_region.get("hd2d_stage") != null:
		main.active_region.hd2d_stage.set_orbit(-16.0, 34.0, 15.8)


func _setup_hd2d_bruges_bakery_square() -> void:
	main.ui.hide_all_overlays()
	main.player.position = Vector2(778, 654)
	main.player.facing = Vector2.UP
	main.player.is_moving = false
	main.active_region.update_nearest_interactable(main.player.position)
	if main.active_region.get("hd2d_stage") != null:
		main.active_region.hd2d_stage.set_orbit(10.0, 35.0, 16.5)


func _setup_hd2d_bruges_cottage_2d_compare() -> void:
	main.ui.hide_all_overlays()
	main.player.position = Vector2(1312, 874)
	main.player.facing = Vector2.UP
	main.player.is_moving = false
	main.active_region.update_nearest_interactable(main.player.position)
	if main.active_region.get("hd2d_stage") != null:
		main.active_region.hd2d_stage.set_hd2d_enabled(false)


func _setup_hd2d_bruges_dawn_stealth() -> void:
	main.ui.hide_all_overlays()
	main.active_region.dawn_peek_timer = 0.0
	main.player.position = Vector2(1062, 622)
	main.player.facing = Vector2.UP
	main.player.is_moving = false
	if main.active_region.watchman_patrols.size() > 0:
		main.active_region.watchman_patrols[0]["t"] = 0.25
		main.active_region.watchman_patrols[0]["dir_sign"] = 1.0
		main.active_region.watchman_patrols[0]["pos"] = Vector2(1129, 560)
		main.active_region.watchman_patrols[0]["dir"] = Vector2.LEFT
		main.active_region.watchman_patrols[0]["pause"] = 0.0
	if main.active_region.get("hd2d_stage") != null:
		main.active_region.hd2d_stage.set_orbit(-8.0, 37.0, 16.2)


func _setup_hd2d_settings_gameplay() -> void:
	main.ui.hide_all_overlays()
	main.ui.open_settings(1)


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
	GameState.louvain_mason_done = true
	main.player.position = Vector2(866, 650)
	main.companion.global_position = Vector2(842, 658)


func _setup_louvain_mason_crane() -> void:
	GameState.louvain_mason_stone_hauled = true
	main.player.position = Vector2(1148, 770)
	main.companion.global_position = Vector2(1122, 776)
	main.ui.open_mason_minigame()
	if main.ui.mason_minigame != null:
		main.ui.mason_minigame.placed_tiers.assign([
			{"kind": "course", "w": 128.0, "h": 30.0, "x": 270.0, "y": 194.0},
			{"kind": "lancet", "w": 104.0, "h": 32.0, "x": 270.0, "y": 162.0},
		])
		main.ui.mason_minigame.current_tier = 2
		main.ui.mason_minigame.feedback_msg = "Plumb & mortar-locked! Ready next tier."
		main.ui.mason_minigame._sync_labels()
		main.ui.mason_minigame.board.queue_redraw()


func _setup_louvain_lakenhalle() -> void:
	main.player.position = Vector2(780, 1388)
	main.companion.global_position = Vector2(752, 1396)


func _setup_louvain_cloister() -> void:
	main.player.position = Vector2(1410, 480)
	main.companion.global_position = Vector2(1382, 496)


func _setup_louvain_dungeon_nave() -> void:
	GameState.louvain_brazier_lit = true
	main.active_region.nave_candles.assign([true, true, true, true])
	main.active_region.altar_slide_k = 1.0
	main.active_region._rebuild_colliders()
	main.active_region._switch_floor(0, Vector2(480, 340), Vector2.UP, true)


func _setup_louvain_dungeon_catacombs() -> void:
	main.active_region.crypt_torches.assign([true, true, true, true, true])
	main.active_region.grave_states["r2c2"] = true
	main.active_region.grave_anim_offsets["r2c2"] = 44.0
	main.active_region.under_grave_traps["r2c2"] = 1.6
	GameState.louvain_crypt_treasure_open = true
	main.active_region.grave_states["r3c4"] = true
	main.active_region.grave_anim_offsets["r3c4"] = 44.0
	main.active_region._rebuild_colliders()
	main.active_region._switch_floor(1, Vector2(1340, 528), Vector2.UP, true)


func _setup_louvain_dungeon_library() -> void:
	main.active_region._switch_floor(2, Vector2(2360, 470), Vector2.UP, true)


func _setup_old_heverlee_woods() -> void:
	main.player.position = Vector2(540, 526)
	main.player.facing = Vector2.UP
	main.companion.global_position = Vector2(512, 534)


func _setup_old_heverlee_shrine() -> void:
	main.player.position = Vector2(328, 326)
	main.player.facing = Vector2.UP
	main.companion.global_position = Vector2(300, 336)


func _setup_anna_sanctuary_ch1() -> void:
	main.ui.hide_all_overlays()
	main.active_region.anna_pos = Vector2(640, 450)
	main.player.position = Vector2(640, 410)


func _setup_anna_barge_raid() -> void:
	main.ui.hide_all_overlays()
	main.active_region.dragon_pos = Vector2(1140, 1020)
	main.active_region.barges[0]["bell_wave_r"] = 108.0
	main.player.position = main.active_region.dragon_pos


func _setup_polish_title_screen() -> void:
	main.load_region("bruges", {"title_bg": true})
	main.ui.show_title_screen(false)
	if main.ui.title_panel != null:
		main.ui.title_panel._process(1.2)


func _setup_polish_port_north_gate() -> void:
	main.ui.hide_all_overlays()
	main.player.position = Vector2(720, 146)
	main.player.facing = Vector2.UP


func _setup_polish_port_willem_cottage() -> void:
	main.ui.hide_all_overlays()
	main.player.position = Vector2(1312, 874)
	main.player.facing = Vector2.UP


func _setup_polish_willem_house_4room() -> void:
	main.ui.hide_all_overlays()
	main.player.position = Vector2(836, 224)
	main.player.facing = Vector2.UP
	main.active_region.update_nearest_interactable(main.player.position)


func _setup_polish_outskirts_cover() -> void:
	main.ui.hide_all_overlays()
	main.player.position = Vector2(680, 560)
	main.player.facing = Vector2.RIGHT


func _setup_polish_bruges_south_gate() -> void:
	main.ui.hide_all_overlays()
	if main.active_region.get("city_cam_focus_t") != null:
		main.active_region.city_cam_focus_t = 0.0
	main.player.position = Vector2(1440, 1915)
	main.player.facing = Vector2.DOWN
	main.camera.position = main.player.position
	main.camera.reset_smoothing()


func _setup_polish_bruges_dropped_note() -> void:
	main.ui.hide_all_overlays()
	GameState.city_watergate_skirmish_won = true
	GameState.city_clue_counting_house = false
	main.player.position = Vector2(616, 1468)
	main.player.facing = Vector2.UP
	main.active_region.update_nearest_interactable(main.player.position)
	main.active_region._on_interact_dropped_note()


func _setup_polish_sanctuary_scout() -> void:
	main.ui.hide_all_overlays()
	main.player.position = Vector2(342, 504)
	main.ui.show_dialogue([
		{"speaker": "Outpost Scout", "portrait": "portrait_outpost_scout.png", "text": "Captain Anna! Urgent word off the western canal road—Armed Catchpoles are pouring through Bruges gates!"}
	])
	if main.ui.dialogue_panel != null:
		main.ui.dialogue_panel.dialogue_visible_chars = main.ui.dialogue_panel.dialogue_full_text.length()
		main.ui.dialogue_panel.dialogue_label.text = main.ui.dialogue_panel.dialogue_full_text
