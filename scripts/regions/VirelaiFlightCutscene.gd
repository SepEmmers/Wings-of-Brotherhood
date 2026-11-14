class_name VirelaiFlightCutscene
extends RefCounted

## Sortie entity population and the Storm Black-Dragon Ambush cutscene for VirelaiFlightRegion.gd.


static func setup_sortie_entities(r) -> void:
	r.wagons.clear()
	r.wild_dragons.clear()
	r.clouds.clear()
	r.updraft_rings.clear()

	var wagon_defs := []
	if r.sortie_id == 1:
		wagon_defs = [
			[Vector2(860, 960), Vector2(1180, 960), 2],
			[Vector2(1380, 560), Vector2(1380, 820), 2]
		]
		r.wild_dragons.append(
			{"id": "reaper_coast", "breed": "Ochre Gale-Wing", "tex": "dragon_reaper", "pos": Vector2(1620, 480), "net_hp": 2, "freed": false, "sketched": GameState.flight_documented_breeds.has("Ochre Gale-Wing") or GameState.flight_documented_breeds.has("Yellow Reaper"), "orbit_phase": 0.4}
		)
		for rp in [Vector2(680, 1080), Vector2(960, 810), Vector2(1280, 680), Vector2(1520, 580), Vector2(1160, 440)]:
			r.updraft_rings.append({"pos": rp, "cd": 0.0})
	else:
		wagon_defs = [
			[Vector2(820, 1020), Vector2(1160, 1020), 2],
			[Vector2(1540, 840), Vector2(1540, 560), 3],
			[Vector2(1260, 440), Vector2(1660, 440), 3]
		]
		r.wild_dragons.append(
			{"id": "longwing_ridge", "breed": "Crimson Acid-Spitter", "tex": "dragon_longwing", "pos": Vector2(1460, 340), "net_hp": 2, "freed": false, "sketched": GameState.flight_documented_breeds.has("Crimson Acid-Spitter") or GameState.flight_documented_breeds.has("Longwing"), "orbit_phase": 1.1}
		)
		for rp in [Vector2(690, 1100), Vector2(1060, 860), Vector2(1360, 690), Vector2(1660, 560)]:
			r.updraft_rings.append({"pos": rp, "cd": 0.0})

	for wd in wagon_defs:
		r.wagons.append({
			"a": wd[0],
			"b": wd[1],
			"pos": wd[0],
			"phase": randf(),
			"hp": int(wd[2]),
			"max_hp": int(wd[2]),
			"alive": true,
			"reload_timer": randf_range(1.6, 2.5),
			"aim_timer": 0.0,
			"aim_target": Vector2.ZERO,
			"flash": 0.0
		})

	var cloud_count := 4 if r.sortie_id == 1 else 7
	for ci in range(cloud_count):
		r.clouds.append({
			"pos": Vector2(460 + (ci % 3) * 520 + randf_range(-50, 50), 360 + int(ci / 3.0) * 440 + randf_range(-50, 50)),
			"tex": "prop_cloud_1.png" if r.sortie_id == 2 else ("prop_cloud_0.png" if ci % 2 == 0 else "prop_cloud_1.png"),
			"speed": randf_range(12.0, 20.0),
			"scale": randf_range(2.3, 2.9)
		})


static func start_attack(r) -> void:
	r.ending_triggered = true
	r.attack_cutscene_active = true
	r.attack_stage = 0
	r.attack_t = 0.0
	r.attack_wait_dlg = false
	r.dragon_angle = -PI * 0.5
	r.blk_pos = r.dragon_pos + Vector2(360, -290)
	r.blk_vel = (r.dragon_pos - r.blk_pos).normalized() * 390.0
	r.blk_visible = false
	r.boy_fall_active = false
	r.boy_fall_pos = r.dragon_pos
	r.boy_fall_rot = 0.0
	r.ui.set_cinematic_mode(true, r._skip_attack_cutscene)
	SoundManager.play_wing_beat()


static func process_attack(r, delta: float) -> void:
	r.attack_t += delta
	match r.attack_stage:
		0:
			r.dragon_pos += Vector2(0, -45) * delta
			r.director.camera.position = r.dragon_pos + Vector2(35, -35)
			if r.attack_t >= 0.45 and int(r.attack_t * 10.0) == 5:
				r.storm_flash = 0.9
				SoundManager.play_dragon_cry()
			if r.attack_t >= 1.15:
				r.attack_wait_dlg = true
				r.ui.show_dialogue([
					{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Ridge convoy routed—wait! Eyes high over the black storm wall!!"}
				], func():
					r.attack_wait_dlg = false
					r.attack_stage = 1
					r.attack_t = 0.0
					r.blk_visible = true
					r.blk_pos = r.dragon_pos + Vector2(330, -270)
					r.blk_vel = (r.dragon_pos - r.blk_pos).normalized() * 380.0
					SoundManager.play_wing_beat()
					SoundManager.play_dragon_cry()
				)
		1:
			r.dragon_pos += Vector2(0, -36) * delta
			r.blk_pos += r.blk_vel * delta
			r.director.camera.position = r.dragon_pos.lerp(r.blk_pos, 0.35)
			r.wind_streaks.append({
				"pos": r.blk_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)),
				"vel": -r.blk_vel * 0.25,
				"life": 0.30,
			})
			if r.blk_pos.distance_to(r.dragon_pos) <= 44.0 or r.attack_t >= 1.25:
				r.storm_flash = 1.0
				r.hurt_timer = 0.9
				SoundManager.play_hit()
				SoundManager.play_knot_snag()
				r.director.trigger_camera_shake(13.0, 0.50)
				r.hit_puffs.append({"pos": r.dragon_pos, "t": 0.45})
				r.boy_fall_active = true
				r.boy_fall_pos = r.dragon_pos + Vector2(-12, 10)
				r.blk_vel = Vector2(-190, -240)
				r.attack_wait_dlg = true
				r.ui.show_dialogue([
					{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "My waist-strap!!"},
					{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "%s!! Grab the tail-line—HOLD ON!!" % GameState.player_name}
				], func():
					r.attack_wait_dlg = false
					r.attack_stage = 2
					r.attack_t = 0.0
				)
		2:
			r.blk_pos += r.blk_vel * delta
			r.dragon_pos += Vector2(-95, -90) * delta
			r.dragon_angle = move_toward(r.dragon_angle, -PI * 0.78, delta * 1.4)
			r.boy_fall_pos += Vector2(-38, 225) * delta
			r.boy_fall_rot += delta * 10.5
			r.wind_streaks.append({
				"pos": r.boy_fall_pos + Vector2(randf_range(-40, 40), 70),
				"vel": Vector2(0, -290),
				"life": 0.32,
			})
			r.director.camera.position = r.boy_fall_pos
			if r.attack_t >= 1.0:
				r.ui.set_fade(1.0)
			if r.attack_t >= 1.95:
				finish_attack(r)


static func finish_attack(r) -> void:
	r.attack_cutscene_active = false
	r.attack_wait_dlg = false
	r.ui.set_cinematic_mode(false)
	r.director.load_region("wilds", {"step": GameState.QuestStep.ACT3_WILDS_TRACKING, "crash_wakeup": true})
