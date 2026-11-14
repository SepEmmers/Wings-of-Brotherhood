extends "res://scripts/regions/RegionBase.gd"

## Full Brotherhood Dragonback Crew Flight Loop aboard Captain Anna's dragon Virelai.
## Sortie 1: Thermal Updraft Rings, crisp Crossbow aiming, telegraphed Ballista Wagons, Yellow Reaper formation sketch.
## Sortie 2: Storm Cloud Stealth, Longwing fiery rescue aid, one fair cloud-sheltered Splice Climax -> Wilds Crash.

const VirelaiFlightCutsceneScript := preload("res://scripts/regions/VirelaiFlightCutscene.gd")
const VirelaiFlightDrawScript := preload("res://scripts/regions/VirelaiFlightDraw.gd")
const SKY_BOUNDS := Rect2(80, 80, 2240, 1440)

var sortie_id: int = 1
var dragon_pos: Vector2 = Vector2(520, 1240)
var dragon_vel: Vector2 = Vector2.ZERO
var dragon_angle: float = -PI * 0.5
var boost_sfx_cd: float = 0.0

var barrel_timer: float = 0.0
var barrel_cd: float = 0.0
var barrel_dir: Vector2 = Vector2.UP
var thermal_timer: float = 0.0
var hurt_timer: float = 0.0
var bolt_cd: float = 0.0
var storm_flash: float = 0.0
var ending_triggered: bool = false
var splice_triggered: bool = false

var in_cloud_cover: bool = false
var nearby_sketch_dragon: Dictionary = {}

var wagons: Array[Dictionary] = []
var wild_dragons: Array[Dictionary] = []
var updraft_rings: Array[Dictionary] = []
var player_bolts: Array[Dictionary] = []
var enemy_bolts: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var hit_puffs: Array[Dictionary] = []
var wind_streaks: Array[Dictionary] = []
var venom_beams: Array[Dictionary] = []
var sketch_fly_fx: Array[Dictionary] = []
var strap_slip_flash: float = 0.0
var intro_shadow_t: float = 0.0

var attack_cutscene_active: bool = false
var attack_stage: int = 0
var attack_t: float = 0.0
var attack_wait_dlg: bool = false
var blk_pos: Vector2 = Vector2.ZERO
var blk_vel: Vector2 = Vector2.ZERO
var blk_visible: bool = false
var boy_fall_active: bool = false
var boy_fall_pos: Vector2 = Vector2.ZERO
var boy_fall_rot: float = 0.0


func _ready() -> void:
	interactables = []
	VirelaiFlightDrawScript.setup_layers(self)


func uses_standard_player_movement() -> bool:
	return false


func enter_region(opts: Dictionary = {}) -> void:
	sortie_id = int(opts.get("sortie", 1))
	GameState.flight_sortie_id = sortie_id
	GameState.current_step = GameState.QuestStep.ACT2_VIRELAI_SORTIE_1 if sortie_id == 1 else GameState.QuestStep.ACT2_VIRELAI_SORTIE_2
	GameState.virelai_harness_hp = 100
	GameState.virelai_loose_straps = 0

	player.visible = false
	player.can_move = false
	ending_triggered = false
	splice_triggered = false
	hurt_timer = 0.0
	barrel_timer = 0.0
	barrel_cd = 0.0
	thermal_timer = 0.0
	bolt_cd = 0.0
	storm_flash = 0.0

	dragon_pos = Vector2(520, 1220)
	dragon_angle = -PI * 0.5
	dragon_vel = Vector2.ZERO
	player_bolts.clear()
	enemy_bolts.clear()
	hit_puffs.clear()
	wind_streaks.clear()
	venom_beams.clear()
	sketch_fly_fx.clear()
	strap_slip_flash = 0.0
	intro_shadow_t = 0.0
	attack_cutscene_active = false
	attack_stage = 0
	attack_t = 0.0
	attack_wait_dlg = false
	blk_visible = false
	boy_fall_active = false

	VirelaiFlightCutsceneScript.setup_sortie_entities(self)

	var cam: Camera2D = director.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 2400
	cam.limit_bottom = 1600
	if bool(opts.get("cutscene_attack", false)):
		sortie_id = 2
		GameState.flight_sortie_id = 2
		GameState.current_step = GameState.QuestStep.ACT2_VIRELAI_SORTIE_2
		dragon_pos = Vector2(1260, 720)
		cam.position = dragon_pos
		step_water_layer()
		ui.set_hud_visible(true)
		_sync_flight_hud()
		VirelaiFlightCutsceneScript.start_attack(self)
		return

	cam.position = dragon_pos
	step_water_layer()

	ui.set_hud_visible(true)
	_sync_flight_hud()
	SoundManager.play_wing_beat()

	if sortie_id == 1:
		ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Coast clear above the sea-cliffs! Thread those glowing wind-updrafts to build speed, keep your quarry bolts steady on those two ballista carts, and roll tight if a red sightline locks on!"}
		])
	else:
		storm_flash = 0.72
		intro_shadow_t = 1.65
		ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Storm clouds stacked thick over the border ridge! Dive inside dark cloud banks whenever a ballista locks on, knock loose that trapped Acid-Spitter's net, and keep your grip fast on the strap!"}
		])


func exit_region() -> void:
	if attack_cutscene_active and ui != null:
		ui.set_cinematic_mode(false)
	ui.set_flight_hud_mode(false)


func _skip_attack_cutscene() -> void:
	VirelaiFlightCutsceneScript.finish_attack(self)


func get_ambience_track() -> String:
	return "flight"


func get_lighting_tint() -> Color:
	if sortie_id == 2:
		return Color(0.56, 0.62, 0.76) if storm_flash <= 0.0 else Color(0.92, 0.96, 1.0)
	return Color(0.86, 0.90, 0.96)


func get_surface_at(_pos: Vector2) -> String:
	return "grass"


func handle_region_input(event: InputEvent) -> bool:
	if ui.is_blocking_gameplay() or ending_triggered:
		return false

	if event.is_action_pressed("dodge") and barrel_cd <= 0.0:
		_trigger_barrel_dodge()
		return true

	if event.is_action_pressed("rope_action") and GameState.virelai_loose_straps > 0:
		_trigger_midair_splice()
		return true

	var click_shoot := (event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed)
	if (event.is_action_pressed("knife_attack") or click_shoot) and bolt_cd <= 0.0:
		var fire_dir := Vector2.from_angle(dragon_angle)
		if click_shoot:
			var m_world := get_global_mouse_position()
			if m_world.distance_squared_to(dragon_pos) > 16.0:
				fire_dir = (m_world - dragon_pos).normalized()
		fire_dir = _assist_aim_dir(fire_dir)
		_fire_crew_bolt(fire_dir)
		return true

	if event.is_action_pressed("interact") and not nearby_sketch_dragon.is_empty():
		_sketch_wild_dragon(nearby_sketch_dragon)
		return true

	return false


func _assist_aim_dir(raw_dir: Vector2) -> Vector2:
	# Subtle 12-degree smart-lead snap toward active wagons/nets so aerial aiming feels snappy rather than finicky
	var best_dir := raw_dir
	var best_score := 0.978  # cos(~12 deg)
	for w in wagons:
		if not bool(w["alive"]):
			continue
		var dvec: Vector2 = Vector2(w["pos"]) - dragon_pos
		var dlen := dvec.length()
		if dlen > 20.0 and dlen < 720.0:
			var nd := dvec / dlen
			var dot := raw_dir.dot(nd)
			if dot > best_score:
				best_score = dot
				best_dir = nd
	for dr in wild_dragons:
		if bool(dr["freed"]):
			continue
		var dvec2: Vector2 = Vector2(dr["pos"]) - dragon_pos
		var dlen2 := dvec2.length()
		if dlen2 > 20.0 and dlen2 < 720.0:
			var nd2 := dvec2 / dlen2
			var dot2 := raw_dir.dot(nd2)
			if dot2 > best_score:
				best_score = dot2
				best_dir = nd2
	return best_dir


func _trigger_barrel_dodge() -> void:
	barrel_timer = 0.30
	barrel_cd = 0.65
	var iv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	barrel_dir = iv.normalized() if iv.length_squared() > 0.01 else Vector2.from_angle(dragon_angle)
	SoundManager.play_wing_beat()


func _fire_crew_bolt(dir: Vector2) -> void:
	bolt_cd = 0.22
	SoundManager.play_bolt()
	player_bolts.append({
		"pos": dragon_pos + dir * 28.0,
		"vel": dir * 740.0,
		"life": 1.15
	})


func _trigger_midair_splice() -> void:
	var knot_to_tie := "dragon_splice" if GameState.unlocked_knots.has("dragon_splice") else "bowline"
	ui.open_knot_minigame(knot_to_tie, func(_id):
		GameState.virelai_loose_straps = 0
		GameState.virelai_harness_hp = mini(100, GameState.virelai_harness_hp + 38)
		SoundManager.play_chime()
		_sync_flight_hud()
		ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Strap locked tight mid-gale! That's a true Brotherhood rigger, %s!" % GameState.player_name}
		])
	, func(_id):
		GameState.virelai_harness_hp = maxi(20, GameState.virelai_harness_hp - 10)
		strap_slip_flash = 0.95
		SoundManager.play_knot_snag()
		director.trigger_camera_shake(4.5, 0.22)
		_sync_flight_hud()
	)


func _sketch_wild_dragon(dr: Dictionary) -> void:
	dr["sketched"] = true
	var bname: String = dr["breed"]
	GameState.record_flight_breed(bname)
	SoundManager.play_dragon_purr()
	SoundManager.play_journal()
	sketch_fly_fx.append({"from": Vector2(dr["pos"]) + Vector2(0, -18), "t": 0.95, "max_t": 0.95})
	hit_puffs.append({"pos": Vector2(dr["pos"]), "t": 0.45})
	_sync_flight_hud()


func step_region(delta: float) -> void:
	storm_flash = maxf(0.0, storm_flash - delta)
	strap_slip_flash = maxf(0.0, strap_slip_flash - delta)
	intro_shadow_t = maxf(0.0, intro_shadow_t - delta)
	for i in range(sketch_fly_fx.size() - 1, -1, -1):
		sketch_fly_fx[i]["t"] = float(sketch_fly_fx[i]["t"]) - delta
		if float(sketch_fly_fx[i]["t"]) <= 0.0:
			sketch_fly_fx.remove_at(i)
	for i in range(venom_beams.size() - 1, -1, -1):
		venom_beams[i]["t"] = float(venom_beams[i]["t"]) - delta
		if float(venom_beams[i]["t"]) <= 0.0:
			venom_beams.remove_at(i)

	if attack_cutscene_active:
		hurt_timer = maxf(0.0, hurt_timer - delta)
		for i in range(wind_streaks.size() - 1, -1, -1):
			if wind_streaks[i].has("vel"):
				wind_streaks[i]["pos"] = Vector2(wind_streaks[i]["pos"]) + Vector2(wind_streaks[i]["vel"]) * delta
			wind_streaks[i]["life"] = float(wind_streaks[i]["life"]) - delta
			if float(wind_streaks[i]["life"]) <= 0.0:
				wind_streaks.remove_at(i)
		for i in range(hit_puffs.size() - 1, -1, -1):
			hit_puffs[i]["t"] = float(hit_puffs[i]["t"]) - delta
			if float(hit_puffs[i]["t"]) <= 0.0:
				hit_puffs.remove_at(i)
		if not attack_wait_dlg:
			VirelaiFlightCutsceneScript.process_attack(self, delta)
		_redraw_world()
		return

	if ui.is_blocking_gameplay():
		_redraw_world()
		return

	hurt_timer = maxf(0.0, hurt_timer - delta)
	bolt_cd = maxf(0.0, bolt_cd - delta)
	barrel_cd = maxf(0.0, barrel_cd - delta)
	thermal_timer = maxf(0.0, thermal_timer - delta)

	# Drift clouds & check thermal updraft rings
	for c in clouds:
		c["pos"] = Vector2(c["pos"].x + float(c["speed"]) * delta, c["pos"].y)
		if c["pos"].x > 2520.0:
			c["pos"].x = -120.0

	in_cloud_cover = false
	for c in clouds:
		if dragon_pos.distance_to(c["pos"]) < 102.0:
			in_cloud_cover = true
			break

	for ur in updraft_rings:
		ur["cd"] = maxf(0.0, float(ur["cd"]) - delta)
		if float(ur["cd"]) <= 0.0 and dragon_pos.distance_to(ur["pos"]) < 46.0:
			ur["cd"] = 6.5
			thermal_timer = 1.9
			GameState.virelai_harness_hp = mini(100, GameState.virelai_harness_hp + 10)
			SoundManager.play_wing_beat()
			SoundManager.play_chime()
			hit_puffs.append({"pos": dragon_pos, "t": 0.45})

	# Steer Virelai cleanly
	if barrel_timer > 0.0:
		barrel_timer = maxf(0.0, barrel_timer - delta)
		dragon_vel = barrel_dir * 630.0
	else:
		var move_in := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var boosting := (Input.is_action_pressed("sprint") or thermal_timer > 0.0) and move_in.length_squared() > 0.01
		if boosting:
			boost_sfx_cd -= delta
			if boost_sfx_cd <= 0.0:
				boost_sfx_cd = 0.42
				SoundManager.play_wing_beat()
		else:
			boost_sfx_cd = 0.0
		var spd := (485.0 if thermal_timer > 0.0 else (430.0 if boosting else 325.0)) * GameState.playtest_speed_mult
		if GameState.virelai_loose_straps > 0:
			spd *= 0.85
		if move_in.length_squared() > 0.01:
			var target_ang := move_in.angle()
			dragon_angle = lerp_angle(dragon_angle, target_ang, minf(1.0, delta * 9.5))
			dragon_vel = dragon_vel.lerp(move_in.normalized() * spd, minf(1.0, delta * 8.0))
			if randf() < 0.35:
				wind_streaks.append({"pos": dragon_pos - move_in.normalized() * 34.0 + Vector2(randf_range(-24, 24), randf_range(-18, 18)), "life": 0.32})
		else:
			dragon_vel = dragon_vel.lerp(Vector2.ZERO, minf(1.0, delta * 4.5))

	dragon_pos += dragon_vel * delta
	dragon_pos.x = clampf(dragon_pos.x, SKY_BOUNDS.position.x, SKY_BOUNDS.end.x)
	dragon_pos.y = clampf(dragon_pos.y, SKY_BOUNDS.position.y, SKY_BOUNDS.end.y)
	director.camera.position = dragon_pos

	for i in range(wind_streaks.size() - 1, -1, -1):
		wind_streaks[i]["life"] = float(wind_streaks[i]["life"]) - delta
		if float(wind_streaks[i]["life"]) <= 0.0:
			wind_streaks.remove_at(i)

	# Update Ballista Wagons (slow patrol + clear aim telegraph before firing)
	var pause_fire := (sortie_id == 2 and GameState.virelai_loose_straps > 0)
	for w in wagons:
		w["flash"] = maxf(0.0, float(w["flash"]) - delta)
		if not bool(w["alive"]):
			w["aim_timer"] = 0.0
			continue
		w["phase"] = fmod(float(w["phase"]) + delta * 0.09, 1.0)
		var wp: float = float(w["phase"])
		var wt := wp * 2.0 if wp < 0.5 else (1.0 - (wp - 0.5) * 2.0)
		w["pos"] = Vector2(w["a"]).lerp(w["b"], wt)

		if pause_fire or (sortie_id == 2 and in_cloud_cover):
			w["aim_timer"] = 0.0
			continue

		var dist_v := Vector2(w["pos"]).distance_to(dragon_pos)
		if float(w["aim_timer"]) > 0.0:
			w["aim_timer"] = float(w["aim_timer"]) - delta
			# Lock-on tracks sluggishly first half, then freezes last 0.45s so dodging feels fair & rewarding
			if float(w["aim_timer"]) > 0.45:
				w["aim_target"] = dragon_pos
			if float(w["aim_timer"]) <= 0.0:
				var aim_dir := (Vector2(w["aim_target"]) - Vector2(w["pos"])).normalized()
				if aim_dir.length_squared() < 0.1:
					aim_dir = Vector2.UP
				SoundManager.play_ballista()
				enemy_bolts.append({
					"pos": Vector2(w["pos"]) + Vector2(0, -10),
					"vel": aim_dir * (305.0 if sortie_id == 1 else 345.0),
					"life": 2.3
				})
				w["reload_timer"] = 2.4 if sortie_id == 1 else 1.85
		else:
			w["reload_timer"] = float(w["reload_timer"]) - delta
			if float(w["reload_timer"]) <= 0.0 and dist_v < 740.0:
				w["aim_timer"] = 1.35 if sortie_id == 1 else 1.15
				w["aim_target"] = dragon_pos

	# Update Freed Wild Dragons (Peaceful formation flight alongside Virelai)
	nearby_sketch_dragon = {}
	for dr in wild_dragons:
		if bool(dr["freed"]):
			dr["orbit_phase"] = float(dr["orbit_phase"]) + delta * 1.15
			var center := dragon_pos + Vector2(-95, -35)
			var op: float = float(dr["orbit_phase"])
			var tgt := center + Vector2(cos(op) * 130.0, sin(op) * 85.0)
			dr["pos"] = Vector2(dr["pos"]).lerp(tgt, minf(1.0, delta * 2.4))
			if not bool(dr["sketched"]) and Vector2(dr["pos"]).distance_to(dragon_pos) < 175.0:
				nearby_sketch_dragon = dr

	# Update Player Crossbow Bolts
	for i in range(player_bolts.size() - 1, -1, -1):
		var pb: Dictionary = player_bolts[i]
		pb["life"] = float(pb["life"]) - delta
		pb["pos"] = Vector2(pb["pos"]) + Vector2(pb["vel"]) * delta
		var hit := false

		for w in wagons:
			if bool(w["alive"]) and Vector2(pb["pos"]).distance_to(w["pos"]) < 42.0:
				w["hp"] = int(w["hp"]) - 1
				w["flash"] = 0.18
				SoundManager.play_hit()
				hit_puffs.append({"pos": Vector2(w["pos"]), "t": 0.45})
				if int(w["hp"]) <= 0:
					w["alive"] = false
					w["aim_timer"] = 0.0
					SoundManager.play_knot_cinch()
					_maybe_trigger_sortie2_climax_splice()
				hit = true
				break

		if not hit:
			for dr in wild_dragons:
				if not bool(dr["freed"]) and Vector2(pb["pos"]).distance_to(dr["pos"]) < 48.0:
					dr["net_hp"] = int(dr["net_hp"]) - 1
					SoundManager.play_hit()
					hit_puffs.append({"pos": Vector2(dr["pos"]), "t": 0.45})
					if int(dr["net_hp"]) <= 0:
						dr["freed"] = true
						GameState.flight_rescued_count += 1
						SoundManager.play_dragon_purr()
						if dr["breed"] in ["Crimson Acid-Spitter", "Longwing"]:
							_longwing_assist_scorch()
					hit = true
					break

		if hit or float(pb["life"]) <= 0.0:
			player_bolts.remove_at(i)

	# Update Enemy Quarrels
	for i in range(enemy_bolts.size() - 1, -1, -1):
		var eb: Dictionary = enemy_bolts[i]
		eb["life"] = float(eb["life"]) - delta
		eb["pos"] = Vector2(eb["pos"]) + Vector2(eb["vel"]) * delta
		if hurt_timer <= 0.0 and barrel_timer <= 0.0 and Vector2(eb["pos"]).distance_to(dragon_pos) < 32.0:
			enemy_bolts.remove_at(i)
			_on_virelai_hit_by_ballista()
			continue
		if float(eb["life"]) <= 0.0:
			enemy_bolts.remove_at(i)

	for i in range(hit_puffs.size() - 1, -1, -1):
		hit_puffs[i]["t"] = float(hit_puffs[i]["t"]) - delta
		if float(hit_puffs[i]["t"]) <= 0.0:
			hit_puffs.remove_at(i)

	_sync_flight_hud()
	_check_sortie_completion()
	_redraw_world()


func _redraw_world() -> void:
	step_water_layer()
	queue_redraw()


func _longwing_assist_scorch() -> void:
	for w in wagons:
		if bool(w["alive"]):
			w["alive"] = false
			w["hp"] = 0
			w["aim_timer"] = 0.0
			var src_pos := dragon_pos + Vector2(-40, -90)
			if not wild_dragons.is_empty():
				src_pos = Vector2(wild_dragons[0]["pos"])
			venom_beams.append({"from": src_pos, "to": Vector2(w["pos"]), "t": 0.65, "max_t": 0.65})
			hit_puffs.append({"pos": Vector2(w["pos"]), "t": 0.65})
			SoundManager.play_dragon_cry()
			ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Watch your eyes—that Crimson Acid-Spitter just washed a hunter cart clean off the ridge with her venom! Glide close enough to sketch her markings in your Bestiary!"}
			])
			return


func _maybe_trigger_sortie2_climax_splice() -> void:
	if sortie_id != 2 or splice_triggered:
		return
	var dead_count := 0
	for w in wagons:
		if not bool(w["alive"]):
			dead_count += 1
	if dead_count >= 2:
		splice_triggered = true
		GameState.virelai_loose_straps = 1
		SoundManager.play_knot_snag()
		ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Hold fast—the port saddle-buckle just parted in that crosswind! I'm climbing into high cover while you re-lash the ring!"}
		])


func _on_virelai_hit_by_ballista() -> void:
	hurt_timer = 1.05
	SoundManager.play_hit()
	GameState.virelai_harness_hp = maxi(20, GameState.virelai_harness_hp - 20)
	if sortie_id == 2 and not splice_triggered:
		splice_triggered = true
		GameState.virelai_loose_straps = 1
		SoundManager.play_knot_snag()
		ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Quarrel nicked our port ring! Climbing above the line while you splice it tight!"}
		])
	_sync_flight_hud()


func _sync_flight_hud() -> void:
	var w_left := 0
	for w in wagons:
		if bool(w["alive"]):
			w_left += 1
	var d_free := 0
	for dr in wild_dragons:
		if bool(dr["freed"]):
			d_free += 1
	var label := "Sortie %d (%s)  |  Ballistas: %d  |  Rescued: %d/%d" % [
		sortie_id,
		"Coast Updrafts" if sortie_id == 1 else "Storm Recon",
		w_left,
		d_free,
		wild_dragons.size()
	]
	if thermal_timer > 0.0:
		label += "  [UPDRAFT]"
	if in_cloud_cover:
		label += "  [CLOUD COVER]"
	ui.set_flight_hud_mode(true, label)


func _check_sortie_completion() -> void:
	if ending_triggered:
		return
	if GameState.virelai_loose_straps > 0:
		return
	for w in wagons:
		if bool(w["alive"]):
			return
	for dr in wild_dragons:
		if not bool(dr["freed"]):
			return

	ending_triggered = true
	SoundManager.play_chime()
	if sortie_id == 1:
		GameState.flight_sortie1_done = true
		ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Both carts in splinters and that Ochre Gale-Wing's climbing seaward with clear skies ahead! Ready to bank back to the Sanctuary perch?"},
			{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "...Didn't feel half as stiff in the rig that time. Lead back west, Anna."}
		], func():
			director.load_region("sanctuary", {"skip_intro": true, "return_sortie1": true, "spawn": Vector2(465, 440)})
		)
	else:
		GameState.flight_sortie2_done = true
		VirelaiFlightCutsceneScript.start_attack(self)


func _draw() -> void:
	VirelaiFlightDrawScript.draw_sky(self)
