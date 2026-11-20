extends "res://scripts/regions/RegionBase.gd"

## Book II Anna Chapter 1 Part 2 — Twilight River Blood-Barge Convoy Raid (2400x1600):
## Fly Captain Anna aboard Virelai down the misty Brabant/Meuse gorge, smash 2 Iron River
## Chain-Booms and 3 Armored Acoustic Ward-Bell Barges ([Space]/Click bolts or [F]/[E] fire dive),
## dodge ringing bell sonar bursts with [Shift] Barrel Roll, free captive wild dragons, and send Kestrel west!

const DrawHelper := preload("res://scripts/regions/VirelaiConvoyRaidDraw.gd")

var dragon_pos: Vector2 = Vector2(1200, 1340)
var dragon_vel: Vector2 = Vector2.ZERO
var dragon_angle: float = -PI * 0.5
var barrel_timer: float = 0.0
var barrel_cd: float = 0.0
var hurt_timer: float = 0.0
var bolt_cd: float = 0.0
var raid_ended: bool = false

var chain_booms: Array[Dictionary] = []
var barges: Array[Dictionary] = []
var freed_dragons: Array[Dictionary] = []
var player_bolts: Array[Dictionary] = []
var enemy_bolts: Array[Dictionary] = []
var hit_puffs: Array[Dictionary] = []


func _ready() -> void:
	interactables = []
	DrawHelper.setup_layers(self)


func uses_standard_player_movement() -> bool:
	return false


func enter_region(_opts: Dictionary = {}) -> void:
	GameState.active_perspective = "anna"
	GameState.book2_started = true
	if int(GameState.current_step) < int(GameState.QuestStep.BOOK2_ANNA_SORTIE_1):
		GameState.current_step = GameState.QuestStep.BOOK2_ANNA_SORTIE_1
	GameState.virelai_harness_hp = 100
	GameState.virelai_loose_straps = 0
	GameState.unlock_realm_node("brabant_fens")

	raid_ended = false
	hurt_timer = 0.0
	barrel_timer = 0.0
	barrel_cd = 0.0
	bolt_cd = 0.0
	dragon_pos = Vector2(1200, 1340)
	dragon_angle = -PI * 0.5
	dragon_vel = Vector2.ZERO
	player_bolts.clear()
	enemy_bolts.clear()
	freed_dragons.clear()
	hit_puffs.clear()

	chain_booms.assign([
		{"id": "boom_s", "pos": Vector2(1200, 1080), "hp": 2, "alive": true},
		{"id": "boom_n", "pos": Vector2(1200, 620),  "hp": 2, "alive": true},
	])
	barges.assign([
		{"id": "barge_1", "pos": Vector2(1060, 960), "hp": 3, "max_hp": 3, "alive": true, "bell_charge": 0.4, "bell_wave_r": 0.0, "bolt_cd": 1.4, "flash": 0.0, "tex": "dragon_reaper"},
		{"id": "barge_2", "pos": Vector2(1340, 740), "hp": 3, "max_hp": 3, "alive": true, "bell_charge": 0.0, "bell_wave_r": 0.0, "bolt_cd": 1.8, "flash": 0.0, "tex": "dragon_longwing"},
		{"id": "barge_3", "pos": Vector2(1200, 380), "hp": 4, "max_hp": 4, "alive": true, "bell_charge": 0.2, "bell_wave_r": 0.0, "bolt_cd": 1.5, "flash": 0.0, "tex": "dragon_reaper"},
	])

	if player != null:
		player.visible = false
		player.cutscene_hidden = true
		player.can_move = false
		player.position = dragon_pos

	if director != null and director.camera != null:
		director.camera.limit_left = 0
		director.camera.limit_top = 0
		director.camera.limit_right = 2400
		director.camera.limit_bottom = 1600
		director.camera.position = dragon_pos

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(true)
	ui.update_world_map_state("brabant_fens", dragon_pos)
	ui.refresh_hud()
	SoundManager.set_ambience("amb_combat")
	ui.show_dialogue([
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Three iron blood-harvest barges below the mist, Virelai! Snap their boom-chains, dodge those Ward-Bell rings, and tear the cages open!"}
	])


func handle_region_input(event: InputEvent) -> bool:
	if raid_ended or (ui != null and ui.is_blocking_gameplay()):
		return false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fire_bolt(get_global_mouse_position())
		return true
	if event.is_action_pressed("dodge") and barrel_cd <= 0.0:
		barrel_timer = 0.42
		barrel_cd = 1.05
		SoundManager.play_wing()
		return true
	if event.is_action_pressed("attack_knife") or event.is_action_pressed("interact") or event.is_action_pressed("rope_action"):
		var tgt := dragon_pos + Vector2(cos(dragon_angle), sin(dragon_angle)) * 180.0
		fire_bolt(tgt, "fire" if event.is_action_pressed("interact") else "bolt")
		return true
	return false


func fire_bolt(world_target: Vector2, kind: String = "bolt") -> void:
	if bolt_cd > 0.0:
		return
	bolt_cd = 0.24
	var d := (world_target - dragon_pos).normalized()
	if d.length() < 0.1:
		d = Vector2(cos(dragon_angle), sin(dragon_angle))
	dragon_angle = d.angle()
	player_bolts.append({"pos": dragon_pos + d * 24.0, "dir": d, "life": 0.95, "kind": kind})
	SoundManager.play_swing()


func step_region(delta: float) -> void:
	step_water_layer()
	hurt_timer = maxf(0.0, hurt_timer - delta)
	barrel_timer = maxf(0.0, barrel_timer - delta)
	barrel_cd = maxf(0.0, barrel_cd - delta)
	bolt_cd = maxf(0.0, bolt_cd - delta)

	for i in range(hit_puffs.size() - 1, -1, -1):
		var hp: Dictionary = hit_puffs[i]
		hp["life"] = float(hp["life"]) - delta
		hp["pos"] = Vector2(hp["pos"]) + Vector2(hp["vel"]) * delta
		if float(hp["life"]) <= 0.0:
			hit_puffs.remove_at(i)

	for wd: Dictionary in freed_dragons:
		wd["pos"] = Vector2(wd["pos"]) + Vector2(18, -110) * delta

	if not raid_ended and not (ui != null and ui.is_blocking_gameplay()):
		var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var spd := 335.0 if barrel_timer > 0.0 else 260.0
		dragon_vel = dragon_vel.lerp(mv * spd, clampf(delta * 8.0, 0.0, 1.0))
		dragon_pos = Vector2(
			clampf(dragon_pos.x + dragon_vel.x * delta, 120.0, 2280.0),
			clampf(dragon_pos.y + dragon_vel.y * delta, 120.0, 1500.0)
		)
		if mv.length() > 0.12:
			dragon_angle = lerp_angle(dragon_angle, mv.angle(), clampf(delta * 9.0, 0.0, 1.0))
		if player != null:
			player.position = dragon_pos
		_step_player_bolts(delta)
		_step_barges_and_enemy_bolts(delta)

	if director != null and director.camera != null:
		director.camera.position = dragon_pos
	queue_redraw()


func _step_player_bolts(delta: float) -> void:
	for i in range(player_bolts.size() - 1, -1, -1):
		var b: Dictionary = player_bolts[i]
		b["pos"] = Vector2(b["pos"]) + Vector2(b["dir"]) * 540.0 * delta
		b["life"] = float(b["life"]) - delta
		var bp := Vector2(b["pos"])
		var consumed := false
		for bm: Dictionary in chain_booms:
			if bool(bm["alive"]) and bp.distance_to(Vector2(bm["pos"])) <= 54.0:
				bm["hp"] = int(bm["hp"]) - 1
				consumed = true
				_spawn_puff(bp, Color(0.96, 0.80, 0.36), 8)
				if int(bm["hp"]) <= 0:
					bm["alive"] = false
					SoundManager.play_cage_break()
				break
		if not consumed:
			for bg: Dictionary in barges:
				if bool(bg["alive"]) and bp.distance_to(Vector2(bg["pos"])) <= 52.0:
					bg["hp"] = int(bg["hp"]) - (2 if String(b.get("kind", "bolt")) == "fire" else 1)
					bg["flash"] = 0.20
					consumed = true
					_spawn_puff(bp, Color(0.98, 0.56, 0.24), 10)
					SoundManager.play_cage_break()
					if int(bg["hp"]) <= 0:
						bg["alive"] = false
						freed_dragons.append({"pos": Vector2(bg["pos"]), "tex": String(bg["tex"])})
						SoundManager.play_dragon_roar()
						_spawn_puff(Vector2(bg["pos"]), Color(0.98, 0.86, 0.38), 22)
						_check_raid_victory()
					break
		if consumed or float(b["life"]) <= 0.0:
			player_bolts.remove_at(i)


func _step_barges_and_enemy_bolts(delta: float) -> void:
	for bg: Dictionary in barges:
		bg["flash"] = maxf(0.0, float(bg.get("flash", 0.0)) - delta)
		if not bool(bg["alive"]):
			continue
		var bp := Vector2(bg["pos"])
		if float(bg.get("bell_wave_r", 0.0)) > 0.0:
			var r_prev := float(bg["bell_wave_r"])
			var r_next := r_prev + 210.0 * delta
			bg["bell_wave_r"] = r_next
			var d_d := dragon_pos.distance_to(bp + Vector2(14, -12))
			if absf(d_d - r_next) <= 22.0 and barrel_timer <= 0.0 and hurt_timer <= 0.0:
				_damage_harness(14)
			if r_next >= 240.0:
				bg["bell_wave_r"] = 0.0
		elif bp.distance_to(dragon_pos) <= 420.0:
			bg["bell_charge"] = float(bg.get("bell_charge", 0.0)) + delta
			if float(bg["bell_charge"]) >= 1.45:
				bg["bell_charge"] = 0.0
				bg["bell_wave_r"] = 12.0
				SoundManager.play_chime()
			bg["bolt_cd"] = float(bg.get("bolt_cd", 1.2)) - delta
			if float(bg["bolt_cd"]) <= 0.0:
				bg["bolt_cd"] = 2.1
				var aim := (dragon_pos - bp).normalized()
				enemy_bolts.append({"pos": bp + aim * 20.0, "dir": aim, "life": 2.2})

	for i in range(enemy_bolts.size() - 1, -1, -1):
		var eb: Dictionary = enemy_bolts[i]
		eb["pos"] = Vector2(eb["pos"]) + Vector2(eb["dir"]) * 230.0 * delta
		eb["life"] = float(eb["life"]) - delta
		if Vector2(eb["pos"]).distance_to(dragon_pos) <= 26.0 and barrel_timer <= 0.0 and hurt_timer <= 0.0:
			enemy_bolts.remove_at(i)
			_damage_harness(12)
		elif float(eb["life"]) <= 0.0:
			enemy_bolts.remove_at(i)


func _damage_harness(amt: int) -> void:
	hurt_timer = 0.55
	GameState.virelai_harness_hp = maxi(0, GameState.virelai_harness_hp - amt)
	SoundManager.play_hit()
	ui.refresh_hud()
	if GameState.virelai_harness_hp <= 0:
		GameState.virelai_harness_hp = 100
		dragon_pos = Vector2(1200, 1340)
		ui.refresh_hud()


func _check_raid_victory() -> void:
	for bg: Dictionary in barges:
		if bool(bg["alive"]):
			return
	raid_ended = true
	GameState.anna_ch1_raid_done = true
	GameState.anna_sortie1_done = true
	GameState.kestrel_courier_ch1_delivered = true
	GameState.active_perspective = "boy"
	GameState.raw_rations += 2
	GameState.smoke_pellets += 2
	GameState.add_dragon_bond(15)
	SoundManager.play_chime()
	ui.show_dialogue([
		{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "Every river chain snapped and all three harvest cages smashed clean! Those captive drakes are clearing the southern mist!"},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Fly straight for Hesbaye, Kestrel—bring that supply satchel to my nephew and keep him alive till I break east!"}
	], func():
		ui.show_chapter_checkpoint(
			"ACT I COMPLETE — THE GOLDEN HEIR RIDES EAST",
			"Relic Key recovered under Old Heverlee, Church river blood-barges shattered, and Kestrel winging Hesbaye supplies to the Boy! Act II opens toward Namur Cliff-Citadel next.",
			"Return to Old Heverlee Overlook",
			func():
				GameState.active_perspective = "boy"
				director.load_region("old_heverlee", {"spawn": preload("res://scripts/regions/OldHeverleeMapData.gd").SHRINE_BACK_SPAWN, "facing": Vector2.DOWN})
		)
	)


func _spawn_puff(origin: Vector2, col: Color, count: int) -> void:
	for _i in range(count):
		var a := randf() * TAU
		var s := randf_range(30.0, 120.0)
		hit_puffs.append({"pos": origin, "vel": Vector2(cos(a), sin(a)) * s, "life": 0.45, "sz": randf_range(2.5, 4.5), "col": col})


func get_ambience_track() -> String:
	return "amb_combat"


func get_lighting_tint() -> Color:
	return Color(0.74, 0.78, 0.88)


func _draw() -> void:
	DrawHelper.draw_raid(self)
