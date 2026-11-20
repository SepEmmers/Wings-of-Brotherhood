extends "res://scripts/regions/RegionBase.gd"

## Watchtower Hearth Interior — Nearest Brotherhood Outpost in the Frontier Borderlands.
## Plays a multi-beat sequence warming the intact black-and-gold egg by the stove until
## Captain Anna & Virelai arrive at the watchtower to take the boy back to the Bruges Sanctuary.

const BOY_CROUCH_POS := Vector2(560, 368)
const EGG_NEST_POS := Vector2(628, 354)
const LOOKOUT_POS := Vector2(548, 338)
const ANNA_STAND_POS := Vector2(736, 336)
const HEARTH_POS := Vector2(628, 250)

var hearth_light: PointLight2D
var egg_glow_light: PointLight2D

var cutscene_active: bool = false
var cutscene_stage: int = 0
var stage_timer: float = 0.0
var egg_wobble: float = 0.0
var crack_stage: int = 0       # Kept at 0: egg stays completely intact here
var egg_warmed_glow: bool = false
var anna_arrived: bool = false
var anna_walk_pos: Vector2 = Vector2(640, 480)
var flash_ring_t: float = 0.0
var hearth_sparks: Array[Dictionary] = []
var waiting_for_dialogue: bool = false
var checkpoint_shown: bool = false


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	add_box_collider(colliders, Rect2(0, 0, 1280, 212))
	add_box_collider(colliders, Rect2(0, 500, 1280, 220))
	add_box_collider(colliders, Rect2(0, 0, 440, 720))
	add_box_collider(colliders, Rect2(840, 0, 440, 720))
	add_box_collider(colliders, Rect2(575, 220, 110, 62))   # Stone hearth
	add_box_collider(colliders, Rect2(465, 255, 86, 52))    # Oak supply bench

	hearth_light = assets.make_point_light(HEARTH_POS + Vector2(0, 48), 4.0, Color(1.0, 0.62, 0.24), 1.35)
	add_child(hearth_light)
	egg_glow_light = assets.make_point_light(EGG_NEST_POS, 2.0, Color(1.0, 0.78, 0.34), 0.35)
	add_child(egg_glow_light)

	interactables = [
		{"id": "hearth_anna", "name": "Ride Back to Bruges Sanctuary", "pos": ANNA_STAND_POS, "radius": 68.0, "callback": _on_talk_anna},
		{"id": "hearth_hatchling", "name": "Inspect Obsidian-Gold Egg", "pos": EGG_NEST_POS, "radius": 66.0, "callback": _on_inspect_hatchling},
	]
	register_walk_portal("hearth_door", Rect2(610, 470, 60, 38), Vector2.DOWN, _on_exit_to_wilds, "v Whispering Pines", "WHISPERING PINES", "Watchtower Trail")


func enter_region(opts: Dictionary = {}) -> void:
	GameState.current_step = GameState.QuestStep.BOOK1_WATCHTOWER_HEARTH
	GameState.carrying_egg = false
	GameState.black_dragon_found = true

	var skip_cutscene := bool(opts.get("skip_cutscene", false))
	player.position = BOY_CROUCH_POS
	player.facing = Vector2.RIGHT
	player.visible = true

	var cam: Camera2D = director.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1280
	cam.limit_bottom = 720
	cam.position = Vector2(640, 360)

	ui.set_flight_hud_mode(false)
	ui.refresh_hud()
	ui.set_fade(1.0, true)
	ui.set_fade(0.0, false)

	if skip_cutscene:
		cutscene_active = false
		crack_stage = 0
		egg_warmed_glow = true
		anna_arrived = true
		anna_walk_pos = ANNA_STAND_POS
		player.set_cutscene_pose("")
		ui.set_cinematic_mode(false)
	else:
		_start_hatching_cutscene()


func exit_region() -> void:
	player.set_cutscene_pose("")
	ui.set_cinematic_mode(false)


func _start_hatching_cutscene() -> void:
	cutscene_active = true
	cutscene_stage = 0
	stage_timer = 0.0
	crack_stage = 0
	egg_warmed_glow = false
	anna_arrived = false
	anna_walk_pos = Vector2(640, 480)
	egg_wobble = 0.0
	waiting_for_dialogue = true
	checkpoint_shown = false
	player.position = BOY_CROUCH_POS
	player.facing = Vector2.RIGHT
	player.set_cutscene_pose("boy_kneel.png")
	ui.set_cinematic_mode(true, _skip_to_finale)
	SoundManager.play_campfire_warm()
	ui.show_dialogue([
		{"speaker": "Watchtower Lookout", "portrait": "portrait_outpost_scout.png", "text": "By the Saints—is that Captain Anna's forward rigman? We fired pine-pitch flares two nights running after Virelai came in torn up!"},
		{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "Wait—Anna made it back from the storm? Quick, make room beside the stove—this black egg's mother died shielding it in the hollow, and it went cold in the frost!"},
		{"speaker": "Watchtower Lookout", "portrait": "portrait_outpost_scout.png", "text": "Down onto the wool blanket, right against the iron grate! I'll rake fresh spruce coals underneath."}
	], func():
		waiting_for_dialogue = false
		stage_timer = 0.0
	)


func get_ambience_track() -> String:
	return "hearth"


func get_lighting_tint() -> Color:
	return Color(0.68, 0.56, 0.50)


func get_surface_at(_pos: Vector2) -> String:
	return "wood"


func update_region_lights(time_val: float) -> void:
	if hearth_light != null:
		hearth_light.energy = 1.28 + sin(time_val * 8.5) * 0.14
	if egg_glow_light != null:
		var base := 0.72 if egg_warmed_glow else 0.35
		egg_glow_light.energy = base + sin(time_val * 6.0) * 0.12
		egg_glow_light.position = EGG_NEST_POS


func step_region(delta: float) -> void:
	flash_ring_t = maxf(0.0, flash_ring_t - delta)
	egg_wobble = maxf(0.0, egg_wobble - delta * 1.4)

	for i in range(hearth_sparks.size() - 1, -1, -1):
		var sp: Dictionary = hearth_sparks[i]
		sp["t"] = float(sp["t"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		if float(sp["t"]) <= 0.0:
			hearth_sparks.remove_at(i)

	if cutscene_active:
		director.camera.position = Vector2(640, 355)
		if not waiting_for_dialogue:
			_process_cutscene(delta)
	else:
		director.camera.position = player.position.lerp(Vector2(640, 360), 0.35)

	queue_redraw()


func _spawn_ember_burst(origin: Vector2, count: int, warm_gold: bool = true) -> void:
	for _i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(28.0, 96.0)
		hearth_sparks.append({
			"pos": origin,
			"vel": Vector2(cos(ang), sin(ang) - 0.35) * spd,
			"t": randf_range(0.45, 0.85),
			"max_t": 0.85,
			"gold": warm_gold,
		})


func _process_cutscene(delta: float) -> void:
	stage_timer += delta
	match cutscene_stage:
		0:
			# Beat 0: Warm hearth embers swirl gently into the cold black shell
			if int(stage_timer * 6.0) > int((stage_timer - delta) * 6.0):
				var swirl_src := EGG_NEST_POS + Vector2(randf_range(-18, 18), randf_range(-12, 10))
				hearth_sparks.append({"pos": swirl_src, "vel": (EGG_NEST_POS - swirl_src) * 1.4, "t": 0.55, "max_t": 0.55, "gold": true})
			if stage_timer >= 1.65:
				cutscene_stage = 1
				stage_timer = 0.0
				SoundManager.play_campfire_warm()
		1:
			# Beat 1: Intact black shell absorbs hearth heat—faint gold shimmer pulses inside without cracking
			egg_wobble = 0.45
			if stage_timer >= 1.15:
				egg_warmed_glow = true
				flash_ring_t = 0.85
				SoundManager.play_dragon_purr()
				_spawn_ember_burst(EGG_NEST_POS, 16, true)
				player.set_cutscene_pose("")
				player.position = BOY_CROUCH_POS + Vector2(-12, 4)
				player.facing = Vector2.RIGHT
				cutscene_stage = 2
				stage_timer = 0.0
		2:
			# Beat 2: Wingbeats rattle the rafters outside and Captain Anna steps through the watchtower door
			if not anna_arrived:
				anna_arrived = true
				anna_walk_pos = Vector2(640, 476)
				SoundManager.play_wing_beat()
				director.trigger_camera_shake(3.8, 0.22)
			var walk_p: float = clampf(stage_timer / 1.15, 0.0, 1.0)
			anna_walk_pos = Vector2(640, 476).lerp(ANNA_STAND_POS, walk_p * walk_p * (3.0 - 2.0 * walk_p))
			player.facing = Vector2(anna_walk_pos - player.position).normalized()
			if stage_timer >= 1.20:
				anna_walk_pos = ANNA_STAND_POS
				cutscene_stage = 3
				stage_timer = 0.0
				waiting_for_dialogue = true
				ui.show_dialogue([
					{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "There you are, %s! Virelai and I have been sweeping the pine ridges since the storm broke—thought that black dragon dragged you into the ravine!" % GameState.player_name},
					{"speaker": GameState.player_name, "portrait": GameState.get_boy_portrait(false), "text": "Wait—she wasn't hunting us! Hunter ballista bolts had torn her flank open. She died shielding this egg beneath her wing, and I followed your Border Chart straight here to the fire."},
					{"speaker": "Watchtower Lookout", "portrait": "portrait_outpost_scout.png", "text": "Look at the heat coming off it now, Captain—pitch-black shell with gold seams warming right through, completely unbroken."},
					{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "An unrecorded black breed... And Church hounds are already combing the border woods below us. Wrap it in my wool cloak and climb onto Virelai's shoulder-rig—we're flying you straight back to the main Sanctuary outpost near Bruges!"}
				], _finish_hatching_cutscene)


func _skip_to_finale() -> void:
	waiting_for_dialogue = false
	crack_stage = 0
	egg_warmed_glow = true
	anna_arrived = true
	anna_walk_pos = ANNA_STAND_POS
	_finish_hatching_cutscene()


func _finish_hatching_cutscene() -> void:
	cutscene_active = false
	waiting_for_dialogue = false
	player.set_cutscene_pose("")
	ui.set_cinematic_mode(false)
	GameState.record_flight_breed("Black-Scaled")
	_transition_to_bruges_sanctuary()


func _transition_to_bruges_sanctuary() -> void:
	GameState.current_step = GameState.QuestStep.ACT4_SANCTUARY_DEBATE
	GameState.sanctuary_phase = 4
	GameState.carrying_egg = true
	GameState.black_dragon_found = true
	GameState.act4_egg_debate_done = false
	SoundManager.play_wing_beat()
	director.load_region("sanctuary", {"preserve_step": true, "act4_debate_intro": true, "spawn": Vector2(342, 504)})


func get_interactable_pos(item: Dictionary) -> Vector2:
	return item["pos"]


func is_interactable_active(id: String) -> bool:
	if cutscene_active:
		return false
	if id == "hearth_anna":
		return anna_arrived
	return true


func _on_talk_anna() -> void:
	ui.show_dialogue([
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Virelai's wings are strapped and ready on the terrace—wind's fair back to the Bruges Sanctuary. Hold tight to that black-and-gold egg."}
	], _transition_to_bruges_sanctuary)


func _on_inspect_hatchling() -> void:
	SoundManager.play_dragon_purr()
	SoundManager.play_campfire_warm()
	egg_wobble = maxf(egg_wobble, 0.55)
	flash_ring_t = 0.90
	_spawn_ember_burst(EGG_NEST_POS, 16, true)


func _on_exit_to_wilds() -> void:
	director.load_region("wilds", {"step": GameState.QuestStep.ACT3_EGG_TREK, "spawn": Vector2(1380, 225)})


func get_active_npc_colliders() -> Array:
	if cutscene_active:
		return []
	var list: Array = [
		LOOKOUT_POS,
		{"pos": EGG_NEST_POS, "offset": Vector2.ZERO, "radius": 16.0},
	]
	if anna_arrived:
		list.append(anna_walk_pos)
	return list


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var t_now: float = assets.time_elapsed

	# Outer dark stone night backdrop
	draw_rect(get_camera_rect(80.0), Color(0.05, 0.05, 0.08))
	draw_rect(Rect2(432, 206, 416, 302), Color(0.22, 0.21, 0.25))
	assets.draw_tiled_rect(self, Rect2(440, 220, 400, 280), assets.get_tex("tile_wood_floor.png"), 32.0)
	draw_rect(Rect2(440, 220, 400, 280), Color(0.24, 0.22, 0.26), false, 8.0)

	# Woven Brotherhood hearth rug
	draw_rect(Rect2(552, 316, 176, 98), Color(0.18, 0.30, 0.24, 0.88))
	draw_rect(Rect2(556, 320, 168, 90), Color(0.84, 0.68, 0.34, 0.68), false, 2.0)

	# Stone Watchtower Hearth + blazing embers
	var htex: Texture2D = assets.get_tex("prop_hearth.png")
	if htex != null:
		draw_texture_rect(htex, Rect2(HEARTH_POS + Vector2(-34, -26), Vector2(68, 102)), false)
	var fflk := 12.0 + sin(t_now * 9.5) * 3.0
	draw_circle(HEARTH_POS + Vector2(0, 56), fflk + 12.0, Color(0.98, 0.56, 0.18, 0.28))
	assets.draw_campfire_sparks(self, HEARTH_POS + Vector2(0, 50), true)

	# Banners flanking hearth + oak bench
	var btex: Texture2D = assets.get_tex("prop_brotherhood_banner.png")
	if btex != null:
		draw_texture_rect(btex, Rect2(Vector2(509, 224), Vector2(42, 66)), false)
		draw_texture_rect(btex, Rect2(Vector2(729, 224), Vector2(42, 66)), false)
	var ctex: Texture2D = assets.get_tex("prop_twine_cache.png")
	if ctex != null:
		draw_texture_rect(ctex, Rect2(Vector2(476, 258), Vector2(44, 44)), false)

	# South timber doorway
	draw_rect(Rect2(616, 486, 48, 14), Color(0.55, 0.42, 0.24))
	draw_rect(Rect2(616, 486, 48, 14), Color(0.28, 0.20, 0.12), false, 2.0)

	# Intact Black-and-Gold Dragon Egg on blanket (never cracks in the forest outpost)
	var etex: Texture2D = assets.get_tex("prop_dragon_egg.png")
	if etex != null:
		var tilt := sin(t_now * 16.0) * 0.08 * egg_wobble
		if egg_warmed_glow:
			draw_circle(EGG_NEST_POS, 22.0 + sin(t_now * 5.0) * 3.5, Color(0.98, 0.72, 0.26, 0.26))
		draw_set_transform(EGG_NEST_POS, tilt, Vector2(2.1, 2.1))
		draw_texture(etex, -Vector2(etex.get_width(), etex.get_height()) * 0.5)
		draw_set_transform(Vector2.ZERO)

	if flash_ring_t > 0.0:
		var ring_r := (1.0 - flash_ring_t) * 66.0 + 14.0
		draw_arc(EGG_NEST_POS, ring_r, 0.0, TAU, 24, Color(1.0, 0.88, 0.46, flash_ring_t * 0.9), 3.0)

	assets.draw_npc_sprite(self, LOOKOUT_POS, "npc_brotherhood_guard_0.png", "Outpost Lookout", font)
	if anna_arrived:
		assets.draw_npc_sprite(self, anna_walk_pos, "npc_anna.png", "Captain Anna", font)

	for sp in hearth_sparks:
		var a := clampf(float(sp["t"]) / float(sp["max_t"]), 0.0, 1.0)
		var col := Color(1.0, 0.86, 0.38, a) if bool(sp["gold"]) else Color(0.92, 0.42, 0.20, a)
		draw_circle(sp["pos"], 2.8 * a + 1.0, col)

	if not cutscene_active:
		draw_interact_bubble_if_active(font)
