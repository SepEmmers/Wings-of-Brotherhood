class_name SanctuaryMontageCutscene
extends RefCounted

## Multi-shot seasonal cutscene montages for Sanctuary time skips (Year 1 -> Year 3, Year 3 -> Year 5).
## Uses smooth fade-through-black transitions with opaque hold beats so shots never snap abruptly,
## plus focused visual props (rigging strap, Maren's poultice jar, Clara's strap vigil, storm beacon).

const KIND_YEAR3 := "year3"
const KIND_YEAR5 := "year5"

const FADE_IN_DUR := 0.56
const FADE_OUT_DUR := 0.56
const BLACK_HOLD_DUR := 0.22


static func start_montage(r, kind: String, from_gameplay: bool = true) -> void:
	r.montage_active = true
	r.montage_kind = kind
	r.montage_t = 0.0
	r.montage_tint_active = false if from_gameplay else true
	r.montage_hide_cage = false
	r.montage_hide_ground_kestrel = false
	r.montage_kestrel_fly_active = false
	r.montage_rope_active = false
	r.montage_strap_vigil_active = false
	r.montage_rig_strap_active = false
	r.montage_rig_pull = 0.0
	r.montage_maren_override = false
	r.montage_beacon_active = false
	r.montage_virelai_dip = 0.0
	r.montage_lightning = 0.0
	r.weather_flakes.clear()
	r.sage_vapor.clear()
	r.player.can_move = false
	r.player.set_cutscene_pose("")

	r.ui.set_cinematic_mode(true, func(): skip_montage(r))
	if from_gameplay:
		r.montage_stage = -1
		r.ui.set_fade(0.0, true)
	else:
		r.ui.set_fade(1.0, true)
		if kind == KIND_YEAR3:
			_enter_year3_stage(r, 0)
		else:
			_enter_year5_stage(r, 0)
	r.ui.refresh_hud()


static func process_montage(r, delta: float) -> void:
	if not r.montage_active:
		return
	r.montage_t += delta
	r.montage_lightning = maxf(0.0, float(r.montage_lightning) - delta * 2.2)
	_step_weather_particles(r, delta)

	if int(r.montage_stage) < 0:
		var lead_p := clampf(float(r.montage_t) / 0.55, 0.0, 1.0)
		r.ui.set_fade(_smooth(lead_p), true)
		if float(r.montage_t) >= 0.75:
			r.ui.set_fade(1.0, true)
			r.montage_tint_active = true
			if r.montage_kind == KIND_YEAR3:
				_enter_year3_stage(r, 0)
			else:
				_enter_year5_stage(r, 0)
		return

	if r.montage_kind == KIND_YEAR3:
		_process_year3(r, delta)
	else:
		_process_year5(r, delta)


static func _process_year3(r, delta: float) -> void:
	var t: float = float(r.montage_t)
	match int(r.montage_stage):
		0:
			# First Winter beside Hendrick's rack: taut leather strap pulled & knotted in snow
			var dur := 3.6
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			var kp := clampf(t / (dur - BLACK_HOLD_DUR), 0.0, 1.0)
			r.director.camera.position = Vector2(236, 650).lerp(Vector2(272, 628), kp)
			r.director.camera.zoom = Vector2(1.56, 1.56).lerp(Vector2(1.52, 1.52), kp)
			r.montage_rig_pull = sin(t * 5.2) * 3.5 if (t > 0.7 and t < 2.6) else 0.0
			if t >= 1.15 and t - delta < 1.15:
				SoundManager.play_rope()
			if t >= 1.95 and t - delta < 1.95:
				SoundManager.play_knot_cinch()
				r.virelai_splice_flash = 0.35
			if t >= dur:
				_enter_year3_stage(r, 1)
		1:
			# Second Winter on East Cliff: Maren's steaming cliffsage salve mends Kestrel uncaged
			var dur := 3.8
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			var kp := clampf(t / (dur - BLACK_HOLD_DUR), 0.0, 1.0)
			r.director.camera.position = Vector2(1134, 396).lerp(Vector2(1162, 386), kp)
			r.director.camera.zoom = Vector2(1.54, 1.54).lerp(Vector2(1.62, 1.62), kp)
			var flap := absf(sin(t * 5.6)) if t >= 0.8 else 0.0
			r.kestrel_leap_offset = Vector2(0.0, -18.0 * flap)
			_spawn_sage_wisp(r, Vector2(1148, 392))
			if t >= 1.05 and t - delta < 1.05:
				SoundManager.play_wing_beat()
			if t >= 1.65 and t - delta < 1.65:
				SoundManager.play_dragon_purr()
				SoundManager.play_chime()
			if t >= dur:
				_enter_year3_stage(r, 2)
		2:
			# Spring Thaw & Age 14 transformation at the Knot Drill Yard
			var dur := 3.8
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			r.director.camera.zoom = Vector2(1.5, 1.5)
			if t < 1.25:
				r.montage_rope_active = true
				var p := clampf((t - 0.35) / 0.72, 0.0, 1.0)
				r.montage_rope_tip = Vector2(r.montage_rope_origin).lerp(r.ACT2_DRILL_BOARD_POS, p)
				r.player.set_cutscene_pose("boy_throw.png")
			elif t < 2.25:
				r.montage_rope_active = false
				var rp := clampf((t - 1.25) / 0.90, 0.0, 1.0)
				r.player.position = Vector2(198, 626).lerp(Vector2(292, 592), rp)
				r.player.set_cutscene_pose("boy_roll.png")
				if t >= 1.28 and t - delta < 1.28:
					SoundManager.play_knot_cinch()
			else:
				r.player.set_cutscene_pose("")
				r.player.facing = Vector2.RIGHT
				r.player.position = Vector2(292, 592).lerp(Vector2(342, 540), clampf((t - 2.25) / 1.15, 0.0, 1.0))
			r.director.camera.position = r.player.position + Vector2(20, -22)
			if t >= dur:
				_enter_year3_stage(r, 3)
		3:
			# Final beat: step calmly beside Virelai's lowered emerald shoulder in morning sun
			var dur := 3.4
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			var p := clampf(t / 1.65, 0.0, 1.0)
			r.player.position = Vector2(342, 540).lerp(Vector2(360, 505), p)
			r.player.facing = Vector2.LEFT if t < 1.65 else Vector2.DOWN
			r.montage_virelai_dip = sin(clampf((t - 1.2) / 1.4, 0.0, 1.0) * PI) * 8.0
			r.director.camera.position = Vector2(354, 482)
			r.director.camera.zoom = Vector2(1.5, 1.5)
			if t >= 1.35 and t - delta < 1.35:
				r.virelai_eye_flare = 1.45
				SoundManager.play_dragon_purr()
			if t >= dur:
				finish_montage(r)


static func _process_year5(r, delta: float) -> void:
	var t: float = float(r.montage_t)
	match int(r.montage_stage):
		0:
			# Year 4: Coastal courier patrol — Kestrel banks high past East Signal Mast (ground sprite hidden)
			var dur := 3.6
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			var kp := clampf(t / (dur - BLACK_HOLD_DUR), 0.0, 1.0)
			r.montage_kestrel_fly_pos = Vector2(620, 278).lerp(Vector2(1500, 336), kp) + Vector2(0, sin(kp * PI) * -36.0)
			r.director.camera.position = Vector2(1010, 456).lerp(Vector2(1090, 435), kp)
			r.director.camera.zoom = Vector2(1.5, 1.5)
			if t >= 0.90 and t - delta < 0.90:
				SoundManager.play_wing_beat()
			if t >= 1.85 and t - delta < 1.85:
				SoundManager.play_chime()
			if t >= dur:
				_enter_year5_stage(r, 1)
		1:
			# Fourth Winter: Quiet moonlight cliff vigil holding Clara's frayed Bruges wrist-strap
			var dur := 3.8
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			var kp := clampf(t / (dur - BLACK_HOLD_DUR), 0.0, 1.0)
			r.director.camera.position = Vector2(1148, 355).lerp(Vector2(1182, 348), kp)
			r.director.camera.zoom = Vector2(1.52, 1.52).lerp(Vector2(1.78, 1.78), _smooth(kp))
			if t >= 1.65 and t - delta < 1.65:
				r.montage_lightning = 0.60
				SoundManager.play_hit()
			if t >= dur:
				_enter_year5_stage(r, 2)
		2:
			# Year 5 / Age 17: Tall senior rigman beside Virelai's brass breast-ring
			var dur := 3.8
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			var kp := clampf(t / (dur - BLACK_HOLD_DUR), 0.0, 1.0)
			r.director.camera.zoom = Vector2(1.62, 1.62).lerp(Vector2(1.5, 1.5), _smooth(kp))
			if t < 1.65:
				r.player.set_cutscene_pose("boy_kneel.png")
			else:
				r.player.set_cutscene_pose("")
				r.player.facing = Vector2.LEFT
			r.montage_virelai_dip = sin(clampf((t - 1.55) / 1.5, 0.0, 1.0) * PI) * 7.0
			if t >= 1.45 and t - delta < 1.45:
				SoundManager.play_knot_cinch()
				r.virelai_splice_flash = 0.95
				SoundManager.play_dragon_purr()
			r.director.camera.position = Vector2(368, 456).lerp(Vector2(408, 420), kp)
			if t >= dur:
				_enter_year5_stage(r, 3)
		3:
			# Storm Gathering: Matthijs raises border beacon lantern while twin lightning forks behind cliff
			var dur := 3.4
			r.ui.set_fade(_calc_shot_fade(t, dur), true)
			var sp := clampf(t / (dur - BLACK_HOLD_DUR), 0.0, 1.0)
			r.director.camera.position = Vector2(410, 420).lerp(Vector2(478, 342), sp)
			r.director.camera.zoom = Vector2(1.5, 1.5)
			if t >= 0.70 and t - delta < 0.70:
				r.montage_lightning = 1.0
				r.director.trigger_camera_shake(6.5, 0.30)
				SoundManager.play_cage_break()
			if t >= 1.65 and t - delta < 1.65:
				r.montage_lightning = 0.85
				SoundManager.play_hit()
			if t >= dur:
				finish_montage(r)


static func _enter_year3_stage(r, stage: int) -> void:
	_reset_shot_flags(r)
	r.montage_stage = stage
	match stage:
		0:
			GameState.boy_age = 12
			r.montage_tint = Color(0.68, 0.76, 0.90)
			r.montage_rig_strap_active = true
			r.player.position = r.ACT2_HENDRICK_POS + Vector2(-8, 12)
			r.player.facing = Vector2.RIGHT
			r.player.set_cutscene_pose("boy_kneel.png")
			_seed_weather(r, "snow")
		1:
			r.montage_hide_cage = true
			r.montage_maren_override = true
			r.montage_maren_pos = Vector2(1108, 398)
			r.montage_tint = Color(0.64, 0.78, 0.88)
			r.player.position = Vector2(1134, 412)
			r.player.facing = Vector2.RIGHT
			r.player.set_cutscene_pose("boy_kneel.png")
			_seed_weather(r, "sleet")
		2:
			GameState.boy_age = 14
			GameState.sanctuary_phase = 2
			r.montage_tint = Color(0.92, 0.94, 0.86)
			r.player.position = Vector2(198, 626)
			r.player.facing = Vector2.LEFT
			r.montage_rope_origin = r.player.position + Vector2(-6, -12)
			r.montage_rope_tip = r.montage_rope_origin
			_seed_weather(r, "petals")
		3:
			r.montage_tint = Color(0.88, 0.91, 0.87)
			r.player.set_cutscene_pose("")
			r.weather_flakes.clear()


static func _enter_year5_stage(r, stage: int) -> void:
	_reset_shot_flags(r)
	r.montage_stage = stage
	match stage:
		0:
			GameState.boy_age = 14
			r.montage_tint = Color(0.84, 0.92, 0.88)
			r.montage_hide_ground_kestrel = true
			r.montage_kestrel_fly_active = true
			r.montage_kestrel_fly_pos = Vector2(620, 278)
			r.player.position = r.ACT2_PENNANT_POST_POS + Vector2(-28, 18)
			r.player.facing = Vector2.UP
			r.player.set_cutscene_pose("")
			_seed_weather(r, "mist")
		1:
			r.montage_tint = Color(0.42, 0.48, 0.68)
			r.montage_hide_ground_kestrel = true
			r.montage_strap_vigil_active = true
			r.player.position = Vector2(1148, 355)
			r.player.facing = Vector2.RIGHT
			r.player.set_cutscene_pose("")
			_seed_weather(r, "snow")
		2:
			GameState.boy_age = 17
			GameState.sanctuary_phase = 3
			GameState.sanctuary_virelai_fed = false
			r.montage_tint = Color(0.80, 0.83, 0.90)
			r.player.position = Vector2(398, 468)
			r.player.facing = Vector2.LEFT
			r.player.set_cutscene_pose("boy_kneel.png")
			_seed_weather(r, "mist")
		3:
			r.montage_tint = Color(0.60, 0.66, 0.80)
			r.montage_beacon_active = true
			r.player.position = Vector2(360, 505)
			r.player.facing = Vector2.UP
			r.player.set_cutscene_pose("")
			_seed_weather(r, "rain")


static func _reset_shot_flags(r) -> void:
	r.montage_t = 0.0
	r.montage_hide_cage = false
	r.montage_hide_ground_kestrel = false
	r.montage_kestrel_fly_active = false
	r.montage_rope_active = false
	r.montage_strap_vigil_active = false
	r.montage_rig_strap_active = false
	r.montage_rig_pull = 0.0
	r.montage_maren_override = false
	r.montage_beacon_active = false
	r.montage_virelai_dip = 0.0
	r.kestrel_leap_offset = Vector2.ZERO


static func _calc_shot_fade(t: float, total_dur: float) -> float:
	if t < FADE_IN_DUR:
		return 1.0 - _smooth(clampf(t / FADE_IN_DUR, 0.0, 1.0))
	var fade_out_start := total_dur - BLACK_HOLD_DUR - FADE_OUT_DUR
	if t >= total_dur - BLACK_HOLD_DUR:
		return 1.0
	if t > fade_out_start:
		return _smooth(clampf((t - fade_out_start) / FADE_OUT_DUR, 0.0, 1.0))
	return 0.0


static func _smooth(x: float) -> float:
	var cx := clampf(x, 0.0, 1.0)
	return cx * cx * (3.0 - 2.0 * cx)


static func skip_montage(r) -> void:
	if r.montage_active:
		finish_montage(r, true)


static func finish_montage(r, was_skipped: bool = false) -> void:
	var kind: String = r.montage_kind
	r.montage_active = false
	r.montage_tint_active = false
	_reset_shot_flags(r)
	r.montage_lightning = 0.0
	r.weather_flakes.clear()
	r.sage_vapor.clear()
	r.player.set_cutscene_pose("")
	r.player.can_move = true
	r.director.camera.zoom = Vector2(1.5, 1.5)
	r.ui.hide_time_stamp()
	if was_skipped:
		r.ui.set_fade(0.0, true)
	else:
		r.ui.set_fade(1.0, true)
		r.ui.set_fade(0.0, false)
	r.ui.set_cinematic_mode(false)

	if kind == KIND_YEAR3:
		GameState.boy_age = 14
		GameState.sanctuary_phase = 2
		GameState.add_dragon_trust(10)
		r.player.position = Vector2(360, 505)
		r.player.facing = Vector2.DOWN
		r.director.camera.position = r.player.position
		r.ui.refresh_hud()
		r.queue_redraw()
		r.ui.show_dialogue([
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Fourteen fits you better than those Bruges rags did. Matthijs is squinting at the east wind-mast, Bram's sorting pasture mutton, and Virelai's restless for Coast Patrol."}
		])
	else:
		GameState.boy_age = 17
		GameState.sanctuary_phase = 3
		GameState.sanctuary_virelai_fed = false
		GameState.add_dragon_trust(10)
		r.player.position = Vector2(360, 505)
		r.player.facing = Vector2.UP
		r.director.camera.position = r.player.position
		r.npc_wave_target = "matthijs"
		r.npc_wave_timer = 5.0
		r.ui.refresh_hud()
		r.queue_redraw()
		SoundManager.play_chime()


static func _seed_weather(r, style: String) -> void:
	r.weather_flakes.clear()
	var count := 42 if style == "rain" else (34 if style == "snow" else 22)
	for i in range(count):
		r.weather_flakes.append({
			"offset": Vector2(randf_range(-520, 520), randf_range(-300, 300)),
			"vel": Vector2(-140.0 if style == "rain" else randf_range(-28, -8), 260.0 if style == "rain" else randf_range(34, 72)),
			"size": randf_range(1.6, 3.2),
			"style": style,
		})


static func _spawn_sage_wisp(r, origin: Vector2) -> void:
	if r.sage_vapor.size() > 14:
		return
	r.sage_vapor.append({
		"pos": origin + Vector2(randf_range(-16, 16), randf_range(-4, 8)),
		"vel": Vector2(randf_range(-10, 10), randf_range(-38, -22)),
		"t": 0.95,
		"max_t": 0.95,
	})


static func _step_weather_particles(r, delta: float) -> void:
	for fl in r.weather_flakes:
		var off := Vector2(fl["offset"]) + Vector2(fl["vel"]) * delta
		if off.y > 320.0:
			off.y -= 640.0
		if off.x < -540.0:
			off.x += 1080.0
		fl["offset"] = off
	for i in range(r.sage_vapor.size() - 1, -1, -1):
		var sp: Dictionary = r.sage_vapor[i]
		sp["t"] = float(sp["t"]) - delta
		sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
		if float(sp["t"]) <= 0.0:
			r.sage_vapor.remove_at(i)
