extends "res://scripts/hd2d/HD2DRegionHost.gd"

## Runtime HD-2D controller for Brabant Reed-Fens (`brabant_fens`).
## Extends HD2DRegionHost with Brabant companion/vent/kestrel/brazier/waterwheel sync
## and Brabant-specific world prompt projections.

const DioramaBuilder := preload("res://scripts/hd2d/BrabantFensHD2DBuilder.gd")

var _hatchling_spr: Sprite3D
var _vent_hatchling_spr: Sprite3D
var _kestrel_spr: Sprite3D
var _eat_morsel_spr: Sprite3D
var _gold_sense_bulb: MeshInstance3D
var _ember_orbs: Array[MeshInstance3D] = []


func _on_build_diorama() -> Dictionary:
	px_per_m = DioramaBuilder.PX_PER_M
	world_3d.name = "BrabantDiorama3D"
	return DioramaBuilder.build_diorama(world_3d, region, assets)


func _ground_y_at(p2d: Vector2) -> float:
	return DioramaBuilder.ground_y_at(p2d)


func _to_3d(p2d: Vector2, y_val: float = NAN) -> Vector3:
	var y: float = _ground_y_at(p2d) if is_nan(y_val) else y_val
	return DioramaBuilder.to_3d(p2d, y)


func _should_hide_stage() -> bool:
	return region != null and region.hatching_cutscene != null and region.hatching_cutscene.active


func _on_create_dynamic_actors() -> void:
	_hatchling_spr = HD2DLib.make_sprite3d(assets.get_tex("dragon_gold_s1_down_0.png"), "dragon_gold_s1_down_0.png", 0.050)
	_hatchling_spr.visible = false
	world_3d.add_child(_hatchling_spr)

	_vent_hatchling_spr = HD2DLib.make_sprite3d(assets.get_tex("dragon_gold_s1_side_0.png"), "dragon_gold_s1_side_0.png", 0.050)
	_vent_hatchling_spr.visible = false
	world_3d.add_child(_vent_hatchling_spr)

	_kestrel_spr = HD2DLib.make_sprite3d(assets.get_tex("dragon_greyling_y5_0.png"), "dragon_greyling_y5_0.png", 0.068)
	_kestrel_spr.visible = false
	world_3d.add_child(_kestrel_spr)

	_eat_morsel_spr = HD2DLib.make_sprite3d(assets.get_tex("prop_meat_cut.png"), "prop_meat_cut.png", 0.044, false)
	_eat_morsel_spr.visible = false
	world_3d.add_child(_eat_morsel_spr)

	_gold_sense_bulb = HD2DLib.make_glow_bulb(Vector3.ZERO, 0.08, Color(0.98, 0.84, 0.34), 1.4)
	_gold_sense_bulb.visible = false
	world_3d.add_child(_gold_sense_bulb)

	_ember_orbs.clear()
	for _i in range(12):
		var orb := HD2DLib.make_glow_bulb(Vector3.ZERO, 0.11, Color(1.0, 0.68, 0.24), 2.8)
		orb.visible = false
		world_3d.add_child(orb)
		_ember_orbs.append(orb)


func _on_sync_stage(delta: float, t_now: float) -> void:
	_sync_lighting_mood(t_now)
	_sync_world_handles(delta, t_now)
	_sync_companion(t_now)
	_sync_vent_crawl(t_now)
	_sync_kestrel(t_now)


func _sync_lighting_mood(t_now: float) -> void:
	var env_pack: Dictionary = _handles.get("env_pack", {})
	var sky_mat: ProceduralSkyMaterial = env_pack.get("sky_mat")
	var sun: DirectionalLight3D = env_pack.get("sun")
	var env: Environment = env_pack.get("env")
	if sky_mat != null and sun != null and env != null:
		var mode: String = str(region.ui.lighting_mode) if region.ui != null else "auto"
		var is_dawn := GameState.brabant_hatched and mode == "auto"
		if mode == "dawn":
			is_dawn = true
		elif mode == "night":
			is_dawn = false
		var top_col := Color(0.08, 0.13, 0.26) if is_dawn else (Color(0.14, 0.12, 0.24) if mode == "dusk" else Color(0.04, 0.07, 0.16))
		var hor_col := Color(0.24, 0.31, 0.45) if is_dawn else (Color(0.32, 0.24, 0.34) if mode == "dusk" else Color(0.14, 0.19, 0.32))
		sky_mat.sky_top_color = top_col
		sky_mat.sky_horizon_color = hor_col
		env.fog_light_color = hor_col.darkened(0.22)
		sun.light_energy = 0.78 if is_dawn else (0.72 if mode == "dusk" else 0.56)
		sun.light_color = Color(0.82, 0.86, 1.0) if is_dawn else (Color(0.95, 0.78, 0.66) if mode == "dusk" else Color(0.66, 0.78, 1.0))

	var flicks: Array = _handles.get("flicker_lights", [])
	for fd: Dictionary in flicks:
		var lgt: OmniLight3D = fd.get("light")
		if lgt == null or not lgt.visible:
			continue
		var ph := float(fd.get("phase", 0.0))
		var base := float(fd.get("base", 2.2))
		lgt.light_energy = base * (1.0 + 0.08 * sin(t_now * 7.2 + ph) + 0.04 * cos(t_now * 13.5 + ph))


func _sync_world_handles(delta: float, t_now: float) -> void:
	var wheel: Node3D = _handles.get("waterwheel")
	if wheel != null:
		wheel.rotation.x += delta * 1.25

	var portcullis: Node3D = _handles.get("portcullis")
	if portcullis != null:
		portcullis.position.y = lerpf(0.035, 2.38, clampf(float(region.gate_open_anim), 0.0, 1.0))

	var lever: Node3D = _handles.get("lever_arm")
	if lever != null:
		var tripped: bool = float(region.gate_open_anim) > 0.25 or bool(region.get("_vent_lever_tripped"))
		lever.rotation_degrees.z = -38.0 if tripped else 32.0

	var vglint: GPUParticles3D = _handles.get("vent_glint")
	if vglint != null:
		vglint.emitting = GameState.brabant_hatched and not GameState.brabant_vent_unlocked

	var cf: Sprite3D = _handles.get("campfire_spr")
	if cf != null:
		var ff := int(t_now * 6.0) % 2
		var fn := "prop_campfire_%d.png" % ff
		HD2DLib.apply_sprite3d_frame(cf, assets.get_tex(fn, "prop_campfire_0.png"), fn, 0.50)

	var egg_spr: Sprite3D = _handles.get("egg_spr")
	if egg_spr != null:
		egg_spr.visible = bool(region.hatch_anim_active)
		if egg_spr.visible:
			var ename := "prop_dragon_egg_crack1.png" if float(region.hatch_anim_t) >= 0.45 else "prop_dragon_egg.png"
			HD2DLib.apply_sprite3d_frame(egg_spr, assets.get_tex(ename, "prop_dragon_egg.png"), ename, 0.65)

	var shards_spr: Sprite3D = _handles.get("shards_spr")
	if shards_spr != null:
		shards_spr.visible = (not bool(region.hatch_anim_active)) and GameState.brabant_hatched

	var briar: Node3D = _handles.get("briar_group")
	if briar != null:
		briar.visible = not GameState.brabant_briar_burned

	var crate: MeshInstance3D = _handles.get("crate_mesh")
	if crate != null:
		crate.scale = Vector3(0.95, 0.78, 0.95) if GameState.brabant_cache_looted else Vector3.ONE

	var cairn_glow: MeshInstance3D = _handles.get("cairn_glow")
	if cairn_glow != null:
		cairn_glow.visible = not bool(region.cairn_relic_claimed)

	var bnodes: Array = _handles.get("brazier_nodes", [])
	for bi in range(mini(bnodes.size(), region.brazier_states.size())):
		var lit := bool(region.brazier_states[bi].get("lit", false))
		var bn: Dictionary = bnodes[bi]
		bn["bulb"].visible = lit
		bn["light"].visible = lit
		bn["embers"].emitting = lit


func _sync_companion(t_now: float) -> void:
	var comp = region.director.companion if (region.director != null) else null
	if comp == null or not comp.is_companion_enabled():
		_hatchling_spr.visible = false
		_eat_morsel_spr.visible = false
		_gold_sense_bulb.visible = false
		for orb: MeshInstance3D in _ember_orbs:
			orb.visible = false
		return

	var show_dragon: bool = GameState.companion_posture != "sling" and float(region.vent_crawl_t) <= 0.0
	_hatchling_spr.visible = show_dragon
	if show_dragon:
		var step_idx := int(comp.walk_phase) % 2 if comp.is_moving else (1 if fmod(comp._idle_t * 0.48, 1.0) > 0.68 else 0)
		var bob := (-2.2 * absf(sin(comp.walk_phase * 0.6))) if comp.is_moving else (-1.2 + sin(comp._idle_t * 1.45) * 1.9)
		var dir_key := "down"
		var flip_x := false
		if absf(comp.facing.x) > 0.30 and absf(comp.facing.y) > 0.30:
			dir_key = "diag_down" if comp.facing.y >= 0.0 else "diag_up"
			flip_x = comp.facing.x < 0.0
		elif absf(comp.facing.x) > absf(comp.facing.y) * 1.05:
			dir_key = "side"
			flip_x = comp.facing.x < 0.0
		elif comp.facing.y < 0.0:
			dir_key = "up"
		var tex_key := "dragon_gold_s1_%s_%d.png" % [dir_key, step_idx]
		var lunge := Vector2.ZERO
		if comp._eat_active and comp._eat_t >= 0.32:
			flip_x = comp.facing.x < 0.0
			var is_open: bool = (comp._eat_t < 1.38) and (fmod(comp._eat_t - 0.32, 0.36) < 0.17)
			tex_key = "dragon_gold_s1_eat_%d.png" % (0 if is_open else 1)
			if is_open:
				lunge = comp.facing * 3.0
		elif comp._cmd_phase == "spew" and (absf(comp._cmd_aim.x) >= 0.25 or comp._cmd_aim.y >= 0.0):
			flip_x = comp._cmd_aim.x < 0.0
			tex_key = "dragon_gold_s1_eat_0.png"
			lunge = comp._cmd_aim * 4.0

		var cpos2d: Vector2 = comp.global_position + lunge
		var cgy := DioramaBuilder.ground_y_at(cpos2d)
		_hatchling_spr.position = DioramaBuilder.to_3d(cpos2d, cgy + maxf(0.0, -bob * 0.045))
		_hatchling_spr.flip_h = flip_x
		_hatchling_spr.pixel_size = 0.050 + float(GameState.active_companion_stage - 1) * 0.008
		HD2DLib.apply_sprite3d_frame(_hatchling_spr, assets.get_tex(tex_key), tex_key)

	if comp._gold_sense_glow > 0.0:
		_gold_sense_bulb.visible = true
		var anchor := _hatchling_spr.position if show_dragon else (_boy_spr.position + Vector3(0, 0.65, 0))
		_gold_sense_bulb.position = anchor + Vector3(0.0, 1.15, 0.0)
		var sc := 0.85 + 0.30 * sin(t_now * 6.5)
		_gold_sense_bulb.scale = Vector3(sc, sc, sc)
	else:
		_gold_sense_bulb.visible = false

	if comp._eat_active and comp._eat_t < 1.24:
		_eat_morsel_spr.visible = true
		var mp: Vector2 = comp._eat_morsel_pos
		var arc_h := 0.0
		if comp._eat_t < 0.34:
			var pu := clampf(comp._eat_t / 0.34, 0.0, 1.0)
			mp = comp._eat_morsel_start.lerp(comp._eat_morsel_pos, pu)
			arc_h = sin(pu * PI) * 0.65
		_eat_morsel_spr.position = DioramaBuilder.to_3d(mp, DioramaBuilder.ground_y_at(mp) + arc_h)
	else:
		_eat_morsel_spr.visible = false

	var motes: Array = comp._ember_motes
	for oi in range(_ember_orbs.size()):
		if oi < motes.size():
			var m: Dictionary = motes[oi]
			var w2: Vector2 = comp.global_position + Vector2(m["pos"])
			var orb := _ember_orbs[oi]
			orb.visible = true
			orb.position = DioramaBuilder.to_3d(w2, DioramaBuilder.ground_y_at(w2) + 0.45)
			var os := clampf(float(m["life"]) / maxf(0.01, float(m["max_life"])), 0.25, 1.0)
			orb.scale = Vector3(os, os, os)
		else:
			_ember_orbs[oi].visible = false


func _sync_vent_crawl(t_now: float) -> void:
	var vt := float(region.vent_crawl_t)
	if vt <= 0.0:
		_vent_hatchling_spr.visible = false
		return
	var prog := 1.0 - clampf(vt / float(region.VENT_CRAWL_DUR), 0.0, 1.0)
	var step_i := int(t_now * 7.5) % 2
	var dpos := Vector2(region.VENT_POS)
	var dkey := "side"
	var flip_d := false
	if prog < 0.16:
		dpos = Vector2(1322, 558).lerp(Vector2(1354, 554), prog / 0.16)
	elif prog < 0.42:
		dpos = Vector2(1354, 554).lerp(Vector2(1414, 554), (prog - 0.16) / 0.26)
	elif prog < 0.66:
		dkey = "down"
		dpos = Vector2(1416, 554).lerp(region.LEVER_POS + Vector2(2, 0), (prog - 0.42) / 0.24)
	elif prog < 0.74:
		dkey = "down"
		step_i = 0
		dpos = region.LEVER_POS + Vector2(2, 0)
	elif prog < 0.88:
		dkey = "down"
		dpos = (region.LEVER_POS + Vector2(2, 0)).lerp(Vector2(1414, 702), (prog - 0.74) / 0.14)
	else:
		flip_d = true
		dpos = Vector2(1414, 702).lerp(Vector2(1332, 704), (prog - 0.88) / 0.12)
	var fname := "dragon_gold_s1_%s_%d.png" % [dkey, step_i]
	_vent_hatchling_spr.visible = true
	_vent_hatchling_spr.flip_h = flip_d
	_vent_hatchling_spr.position = DioramaBuilder.to_3d(dpos, DioramaBuilder.ground_y_at(dpos))
	HD2DLib.apply_sprite3d_frame(_vent_hatchling_spr, assets.get_tex(fname), fname)


func _sync_kestrel(t_now: float) -> void:
	_kestrel_spr.visible = bool(region.kestrel_visible)
	if not _kestrel_spr.visible:
		return
	var alt := float(region.kestrel_alt)
	var kf := int(t_now * (10.0 if alt > 6.0 else 3.2)) % 2
	var kname := "dragon_greyling_y5_%d.png" % kf
	var kpos2: Vector2 = region.kestrel_pos
	_kestrel_spr.position = DioramaBuilder.to_3d(kpos2, DioramaBuilder.ground_y_at(kpos2) + alt / DioramaBuilder.PX_PER_M)
	HD2DLib.apply_sprite3d_frame(_kestrel_spr, assets.get_tex(kname, "dragon_greyling_0.png"), kname)


func _compute_camera_focus() -> Dictionary:
	var ppos: Vector2 = region.player.position
	var focus2: Vector2 = ppos
	var focus_y := DioramaBuilder.ground_y_at(ppos) + 0.85
	var is_dlg: bool = region.ui != null and region.ui.dialogue_active and not region.ui.cutscene_active

	if region.intro_active and region.kestrel_visible:
		focus2 = Vector2(region.kestrel_pos).lerp(ppos, 0.5)
		focus_y += float(region.kestrel_alt) * 0.25 / DioramaBuilder.PX_PER_M
	elif float(region.vent_crawl_t) > 0.0:
		focus2 = ppos.lerp(region.GATE_RECT.get_center(), 0.45)
	elif is_dlg:
		var ipos: Vector2 = region.last_interacted_pos
		if ipos.is_finite() and ipos.distance_to(ppos) <= 190.0:
			focus2 = ppos.lerp(ipos, 0.45)
	return {"pos2": focus2, "focus_y": focus_y, "is_dlg": is_dlg}


func _on_draw_extra_prompts(canvas: Node2D, font: Font, _blocked: bool) -> void:
	var ppos: Vector2 = region.player.position
	if GameState.brabant_hatched:
		var cmd_k := GameState.get_action_key_label("dragon_command")
		var post_k := GameState.get_action_key_label("dragon_posture")
		if not GameState.brabant_briar_burned and GameState.hatchling_fed_count > 0 and ppos.distance_to(region.BRIAR_POS) <= 115.0:
			var sp_b = _project_world_pt(region.BRIAR_POS, 1.70)
			if sp_b is Vector2:
				assets.draw_interact_bubble(canvas, sp_b, "[%s] Kindle Dry Briar" % cmd_k, font)
		elif not GameState.brabant_vent_unlocked and float(region.vent_crawl_t) <= 0.0 and ppos.distance_to(region.VENT_POS) <= 84.0:
			var sp_v = _project_world_pt(region.VENT_POS, 1.65)
			if sp_v is Vector2:
				assets.draw_interact_bubble(canvas, sp_v, "[%s] Send Through Drain" % cmd_k, font)
		elif GameState.hatchling_fed_count > 0:
			for b: Dictionary in region.brazier_states:
				if not bool(b.get("lit", false)) and ppos.distance_to(Vector2(b["pos"])) <= 105.0:
					var sp_z = _project_world_pt(Vector2(b["pos"]), 1.75)
					if sp_z is Vector2:
						assets.draw_interact_bubble(canvas, sp_z, "[%s] Kindle Brazier" % cmd_k, font)
					break

		if GameState.brabant_vent_unlocked and ppos.x >= 1915.0 and GameState.companion_posture != "sling" and not GameState.brabant_sling_practiced:
			var sp_s = _project_world_pt(ppos, 2.05)
			if sp_s is Vector2:
				assets.draw_interact_bubble(canvas, sp_s, "[%s] Tuck Into Cloak-Sling" % post_k, font)

	if ppos.distance_to(Vector2(2110, 714)) <= 165.0:
		var sp_g = _project_world_pt(Vector2(2092, 690), 2.1)
		if sp_g is Vector2:
			assets.draw_interact_bubble(canvas, sp_g, "Louvain West Gate ->", font)
