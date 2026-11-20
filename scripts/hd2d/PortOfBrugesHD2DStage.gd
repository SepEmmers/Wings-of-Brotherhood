extends "res://scripts/hd2d/HD2DRegionHost.gd"

## Runtime HD-2D controller for Port of Bruges (`bruges`).
## Extends HD2DRegionHost with De Zwaan Cog docking, harbor NPCs, watchman
## raycasted 3D vision cones, Brotherhood ambush / Virelai flight, time-of-day
## Flemish sky/lantern grading, and 6-slot pooled harbor lighting.

const DioramaBuilder := preload("res://scripts/hd2d/PortOfBrugesHD2DBuilder.gd")

var _npc_sprs: Dictionary = {}
var _amb_sprs: Dictionary = {}
var _watchman_slots: Array[Dictionary] = []


func _on_build_diorama() -> Dictionary:
	px_per_m = DioramaBuilder.PX_PER_M
	default_pitch_deg = 35.0
	default_dist = 15.8
	vista_pitch_deg = 39.0
	vista_dist = 29.0
	world_3d.name = "BrugesPortDiorama3D"
	return DioramaBuilder.build_diorama(world_3d, region, assets)


func _ground_y_at(p2d: Vector2) -> float:
	if region != null and bool(region.gangplank_deployed):
		if p2d.x >= 190.0 and p2d.x <= 268.0 and absf(p2d.y - 480.0) <= 36.0:
			var t: float = clampf((p2d.x - 200.0) / 56.0, 0.0, 1.0)
			return lerpf(DioramaBuilder.DECK_Y, 0.05, t)
	if region != null and p2d.x < 224.0 and p2d.distance_to(Vector2(region.ship_pos)) < 85.0:
		return DioramaBuilder.DECK_Y
	return DioramaBuilder.ground_y_at(p2d)


func _to_3d(p2d: Vector2, y_val: float = NAN) -> Vector3:
	var y: float = _ground_y_at(p2d) if is_nan(y_val) else y_val
	return DioramaBuilder.to_3d(p2d, y)


func _should_hide_stage() -> bool:
	return region != null and bool(region.title_bg_mode)


func _get_boy_carry_fallback_tex() -> String:
	return "prop_crate.png"


func _on_create_dynamic_actors() -> void:
	_npc_sprs.clear()
	var specs := {
		"shipmaster": "npc_shipmaster_0.png",
		"vos": "npc_quartermaster_0.png",
		"clara": "npc_clara_0.png",
		"jan": "npc_dockhand_0.png",
		"piet": "npc_piet_0.png",
		"inquisitor": "npc_inquisitor_0.png",
		"baker": "npc_baker_0.png",
		"maerten": "npc_city_guard_0.png",
		"dirk": "npc_city_guard_0.png",
	}
	for key: String in specs.keys():
		var tname: String = specs[key]
		var spr := HD2DLib.make_sprite3d(assets.get_tex(tname), tname, 0.056)
		world_3d.add_child(spr)
		_npc_sprs[key] = spr

	_amb_sprs.clear()
	var amb_specs := {
		"anchor": {"tex": "npc_brotherhood_guard_0.png", "ps": 0.056},
		"rider_l": {"tex": "npc_brotherhood_guard_0.png", "ps": 0.056},
		"rider_r": {"tex": "npc_brotherhood_guard_0.png", "ps": 0.056},
		"anna": {"tex": "npc_anna_0.png", "ps": 0.056},
		"virelai": {"tex": "dragon_anna_0.png", "ps": 0.068},
	}
	for akey: String in amb_specs.keys():
		var ad: Dictionary = amb_specs[akey]
		var aspr := HD2DLib.make_sprite3d(assets.get_tex(ad["tex"]), ad["tex"], float(ad["ps"]))
		aspr.visible = false
		world_3d.add_child(aspr)
		_amb_sprs[akey] = aspr

	_watchman_slots.clear()
	for wi in range(6):
		var wspr := HD2DLib.make_sprite3d(assets.get_tex("npc_watchman_down_0.png"), "npc_watchman_down_0.png", 0.056)
		wspr.visible = false
		world_3d.add_child(wspr)

		var cone_mesh := ArrayMesh.new()
		var cone_mi := MeshInstance3D.new()
		cone_mi.mesh = cone_mesh
		cone_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cone_mi.visible = false
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.albedo_color = Color.WHITE
		mat.render_priority = 4
		cone_mi.material_override = mat
		world_3d.add_child(cone_mi)

		_watchman_slots.append({"spr": wspr, "cone": cone_mi, "mesh": cone_mesh})


func _on_sync_stage(_delta: float, t_now: float) -> void:
	_sync_lighting_and_sky(t_now)
	_sync_world_handles(t_now)
	_sync_npcs(t_now)
	_sync_ambush(t_now)
	_sync_watchmen(t_now)


func _resolve_mood() -> String:
	var mode: String = str(region.ui.lighting_mode) if region.ui != null else "auto"
	if mode != "auto":
		return mode
	if float(region.dawn_peek_timer) > 0.0 or GameState.current_step >= GameState.QuestStep.SNITCH_TO_CHURCH:
		return "dawn"
	if GameState.current_step == GameState.QuestStep.EVENING_HOME or GameState.all_evening_errands_done():
		return "dusk"
	return "day"


func _sync_lighting_and_sky(t_now: float) -> void:
	var mood := _resolve_mood()
	var env_pack: Dictionary = _handles.get("env_pack", {})
	var sky_mat: ProceduralSkyMaterial = env_pack.get("sky_mat")
	var sun: DirectionalLight3D = env_pack.get("sun")
	var env: Environment = env_pack.get("env")

	var lantern_gain := 1.0
	if sky_mat != null and sun != null and env != null:
		match mood:
			"night":
				sky_mat.sky_top_color = Color(0.04, 0.07, 0.16)
				sky_mat.sky_horizon_color = Color(0.14, 0.19, 0.30)
				sun.light_energy = 0.52
				sun.light_color = Color(0.68, 0.80, 1.0)
				lantern_gain = 1.25
			"dawn":
				sky_mat.sky_top_color = Color(0.08, 0.13, 0.24)
				sky_mat.sky_horizon_color = Color(0.30, 0.34, 0.44)
				sun.light_energy = 0.68
				sun.light_color = Color(0.86, 0.84, 0.88)
				lantern_gain = 1.20
			"dusk":
				sky_mat.sky_top_color = Color(0.13, 0.14, 0.28)
				sky_mat.sky_horizon_color = Color(0.48, 0.30, 0.26)
				sun.light_energy = 0.78
				sun.light_color = Color(1.0, 0.78, 0.56)
				lantern_gain = 1.10
			_:
				sky_mat.sky_top_color = Color(0.20, 0.34, 0.56)
				sky_mat.sky_horizon_color = Color(0.56, 0.62, 0.70)
				sun.light_energy = 1.05
				sun.light_color = Color(1.0, 0.94, 0.84)
				lantern_gain = 0.42
		env.fog_light_color = sky_mat.sky_horizon_color.darkened(0.18)

	var candidates: Array = []
	var lspecs: Array = _handles.get("lantern_specs", [])
	for ld: Dictionary in lspecs:
		var bulb: MeshInstance3D = ld.get("bulb")
		if bulb != null:
			bulb.visible = lantern_gain > 0.35
		candidates.append({
			"pos": ld["pos"],
			"color": ld["color"],
			"energy": float(ld["energy"]) * lantern_gain,
			"range": float(ld["range"]),
			"attenuation": float(ld["attenuation"]),
			"flicker_phase": float(ld["flicker_phase"]),
			"flicker_amp": float(ld["flicker_amp"]),
		})

	if GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH and not bool(region.ambush_cutscene_active):
		for wpi in range(region.watchman_patrols.size()):
			var wp: Dictionary = region.watchman_patrols[wpi]
			var wpos: Vector2 = Vector2(wp.get("pos", Vector2.ZERO))
			var wdir: Vector2 = Vector2(wp.get("dir", Vector2.DOWN)).normalized()
			if wdir.length_squared() < 0.01:
				wdir = Vector2.DOWN
			candidates.append({
				"pos": _to_3d(wpos + wdir * 24.0, 1.05),
				"color": Color(1.0, 0.72, 0.34),
				"energy": 2.6,
				"range": 7.5,
				"attenuation": 1.45,
				"flicker_phase": 4.2 + float(wpi),
				"flicker_amp": 0.06,
				"priority_bias": 2.0,
			})

	if _handles.has("oven_glow_pos"):
		candidates.append({
			"pos": _handles["oven_glow_pos"],
			"color": Color(1.0, 0.48, 0.14),
			"energy": 3.1 * maxf(0.75, lantern_gain),
			"range": 8.6,
			"attenuation": 1.45,
			"flicker_phase": 0.9,
			"flicker_amp": 0.12,
			"priority_bias": 1.6,
		})
	if _handles.has("willem_door_pos"):
		candidates.append({
			"pos": _handles["willem_door_pos"],
			"color": Color(1.0, 0.78, 0.36),
			"energy": 2.4 * maxf(0.55, lantern_gain),
			"range": 7.6,
			"attenuation": 1.5,
			"flicker_phase": 2.4,
			"flicker_amp": 0.06,
			"priority_bias": 0.8,
		})
	var ship: Node3D = _handles.get("ship")
	if ship != null:
		candidates.append({
			"pos": ship.position + Vector3(0.55, 1.92, 1.72),
			"color": Color(1.0, 0.76, 0.34),
			"energy": 2.6 * maxf(0.60, lantern_gain),
			"range": 8.0,
			"attenuation": 1.5,
			"flicker_phase": 3.7,
			"flicker_amp": 0.07,
		})

	sync_pooled_lights(candidates, _cam_focus, t_now)


func _sync_world_handles(t_now: float) -> void:
	var ship: Node3D = _handles.get("ship")
	if ship != null:
		ship.position = DioramaBuilder.to_3d(Vector2(region.ship_pos), DioramaBuilder.WATER_Y + 0.08 + sin(t_now * 1.4) * 0.025)
		ship.rotation.z = sin(t_now * 1.1) * 0.02

	var sail: MeshInstance3D = _handles.get("ship_sail")
	if sail != null:
		if GameState.ship_docked:
			sail.scale = Vector3(0.95, 0.24, 1.0)
			sail.position.y = 4.22
		else:
			sail.scale = Vector3(1.0, 1.0, 1.0)
			sail.position.y = 3.25

	var ship_crate: MeshInstance3D = _handles.get("ship_crate")
	if ship_crate != null:
		ship_crate.visible = not GameState.carrying_crate and not GameState.cargo_delivered

	var moor_line: MeshInstance3D = _handles.get("ship_moor_line")
	if moor_line != null:
		moor_line.visible = GameState.ship_moored
		if moor_line.visible:
			var a3 := DioramaBuilder.to_3d(Vector2(region.ship_pos) + Vector2(30, -52), DioramaBuilder.DECK_Y + 0.14)
			var b3 := DioramaBuilder.to_3d(Vector2(240, 310), 0.38)
			var d3 := b3 - a3
			var dist3 := maxf(0.2, d3.length())
			moor_line.position = (a3 + b3) * 0.5
			moor_line.scale = Vector3(1.0, 1.0, dist3)
			moor_line.look_at(b3, Vector3.UP)

	var gp: MeshInstance3D = _handles.get("gangplank")
	if gp != null:
		gp.visible = bool(region.gangplank_deployed)

	var twine: Sprite3D = _handles.get("twine_cache")
	if twine != null:
		twine.visible = not GameState.bruges_twine_cache_cut

	var dcrate: Sprite3D = _handles.get("drifted_crate")
	if dcrate != null:
		dcrate.visible = not GameState.drifted_crate_recovered
		if dcrate.visible:
			dcrate.position = DioramaBuilder.to_3d(region.DRIFTED_CRATE_POS, DioramaBuilder.WATER_Y + 0.04 + sin(t_now * 2.1) * 0.03)

	var pouch: Sprite3D = _handles.get("bobbing_pouch")
	if pouch != null:
		pouch.visible = not GameState.shuttle_pouch_recovered
		if pouch.visible:
			pouch.position = DioramaBuilder.to_3d(region.BOBBING_POUCH_POS, DioramaBuilder.WATER_Y + 0.05 + sin(t_now * 2.6 + 1.1) * 0.035)


func _set_npc(key: String, vis: bool, pos2d: Vector2, tex_prefix: String, t_now: float, y_off: float = NAN) -> void:
	var spr: Sprite3D = _npc_sprs.get(key)
	if spr == null:
		return
	spr.visible = vis
	if not vis:
		return
	var frame := int(t_now * 1.6 + pos2d.x * 0.03) % 2
	var tname := "%s_%d.png" % [tex_prefix, frame]
	spr.position = _to_3d(pos2d, _ground_y_at(pos2d) if is_nan(y_off) else y_off)
	HD2DLib.apply_sprite3d_frame(spr, assets.get_tex(tname, "%s_0.png" % tex_prefix), tname)


func _sync_npcs(t_now: float) -> void:
	var is_cut: bool = bool(region.ambush_cutscene_active)
	var pre_dawn := GameState.current_step < GameState.QuestStep.DAWN_MISSING_CLARA
	var pre_act2 := GameState.current_step < GameState.QuestStep.ACT2_SANCTUARY

	_set_npc("shipmaster", not is_cut, Vector2(region.ship_pos) + Vector2(4, -22), "npc_shipmaster", t_now, DioramaBuilder.DECK_Y)
	_set_npc("vos", not is_cut, region.get_npc_yield_pos("pob_vos", Vector2(512, 262), 34.0, 12.0), "npc_quartermaster", t_now)
	_set_npc("inquisitor", not is_cut, Vector2(800, 372), "npc_inquisitor", t_now)
	_set_npc("baker", not is_cut, region.get_npc_yield_pos("pob_baker", Vector2(795, 635), 34.0, 12.0), "npc_baker", t_now)
	_set_npc("clara", (not is_cut) and pre_dawn, region.get_npc_yield_pos("pob_clara", Vector2(1185, 240), 34.0, 12.0), "npc_clara", t_now)
	_set_npc("jan", (not is_cut) and pre_dawn, region.get_npc_yield_pos("pob_jan", Vector2(308, 608), 34.0, 12.0), "npc_dockhand", t_now)
	_set_npc("piet", (not is_cut) and pre_dawn, region.get_npc_yield_pos("pob_piet", Vector2(575, 595), 34.0, 12.0), "npc_piet", t_now)
	_set_npc("maerten", (not is_cut) and pre_act2, Vector2(720, 92), "npc_city_guard", t_now)
	_set_npc("dirk", (not is_cut) and pre_act2, Vector2(1526, 98), "npc_city_guard", t_now)


func _sync_ambush(t_now: float) -> void:
	var cut: bool = bool(region.ambush_cutscene_active)
	var pre_snitch: bool = GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH and not cut

	var anchor: Sprite3D = _amb_sprs.get("anchor")
	var rider_l: Sprite3D = _amb_sprs.get("rider_l")
	var rider_r: Sprite3D = _amb_sprs.get("rider_r")
	var anna: Sprite3D = _amb_sprs.get("anna")
	var virelai: Sprite3D = _amb_sprs.get("virelai")

	var show_guards := cut or pre_snitch
	if anchor != null:
		anchor.visible = show_guards
		if show_guards:
			var ap: Vector2 = Vector2(region.amb_anchor) if cut else (Vector2(region.AMBUSH_CENTER) + Vector2(0, -45))
			anchor.position = _to_3d(ap)
	if rider_l != null:
		rider_l.visible = show_guards
		if show_guards:
			var lp: Vector2 = Vector2(region.amb_rider_l) if cut else (Vector2(region.AMBUSH_CENTER) + Vector2(-42, -20))
			rider_l.position = _to_3d(lp)
	if rider_r != null:
		rider_r.visible = show_guards
		if show_guards:
			var rp: Vector2 = Vector2(region.amb_rider_r) if cut else (Vector2(region.AMBUSH_CENTER) + Vector2(38, 18))
			rider_r.position = _to_3d(rp)
	if anna != null:
		anna.visible = cut
		if cut:
			anna.position = _to_3d(Vector2(region.amb_anna))
	if virelai != null:
		virelai.visible = cut and bool(region.amb_virelai_visible)
		if virelai.visible:
			var vf := int(t_now * 6.5) % 2
			var vtex := "dragon_anna_%d.png" % vf
			var valt := float(region.amb_virelai_alt)
			virelai.position = _to_3d(Vector2(region.amb_virelai), DioramaBuilder.ground_y_at(Vector2(region.amb_virelai)) + valt / DioramaBuilder.PX_PER_M)
			HD2DLib.apply_sprite3d_frame(virelai, assets.get_tex(vtex), vtex)


func _sync_watchmen(t_now: float) -> void:
	var patrols: Array = region.watchman_patrols if GameState.current_step == GameState.QuestStep.SNITCH_TO_CHURCH and not bool(region.ambush_cutscene_active) else []
	for si in range(_watchman_slots.size()):
		var slot: Dictionary = _watchman_slots[si]
		var spr: Sprite3D = slot["spr"]
		var cone_mi: MeshInstance3D = slot["cone"]
		if si >= patrols.size():
			spr.visible = false
			cone_mi.visible = false
			continue

		var wp: Dictionary = patrols[si]
		var wpos: Vector2 = Vector2(wp.get("pos", Vector2.ZERO))
		var facing: Vector2 = Vector2(wp.get("dir", wp.get("facing", Vector2.DOWN))).normalized()
		if facing.length_squared() < 0.01:
			facing = Vector2.DOWN
		var dkey := "side"
		var flip_x := false
		if absf(facing.x) > absf(facing.y) * 1.1:
			dkey = "side"
			flip_x = facing.x < 0.0
		elif facing.y < 0.0:
			dkey = "up"
		else:
			dkey = "down"
		var is_paused := float(wp.get("pause", 0.0)) > 0.0
		var step_i := 0 if is_paused else (int(t_now * 4.5 + float(si)) % 3)
		var tname := "npc_watchman_%s_%d.png" % [dkey, step_i]
		spr.visible = true
		spr.flip_h = flip_x
		spr.position = _to_3d(wpos)
		HD2DLib.apply_sprite3d_frame(spr, assets.get_tex(tname, "npc_watchman_0.png"), tname)

		# Raycasted 3D vision cone matching PortOfBrugesAmbush.gd (eye offset y-6)
		var cone_mesh: ArrayMesh = slot["mesh"]
		cone_mesh.clear_surfaces()
		cone_mi.visible = true
		var susp: float = float(wp.get("suspicion", 0.0))
		var alrt: float = float(wp.get("alert", 0.0))
		var alert_mix: float = clampf(maxf(susp, 1.0 if alrt > 0.0 else 0.0), 0.0, 1.0)
		var col := Color(1.0, 0.78, 0.24, 0.48).lerp(Color(1.0, 0.22, 0.14, 0.58), alert_mix)
		var edge_col := Color(col.r, col.g, col.b, col.a * 0.45)
		var base_ang := facing.angle()
		var half_fov := deg_to_rad(36.0)
		var segs := 18
		var w_eye := wpos + Vector2(0, -6)
		var origin3 := _to_3d(w_eye, 0.085)
		var verts := PackedVector3Array()
		var cols := PackedColorArray()
		var prev3 := origin3
		for k in range(segs + 1):
			var a := base_ang - half_fov + (half_fov * 2.0) * (float(k) / float(segs))
			var rdir := Vector2.from_angle(a)
			var hit2: Vector2 = region.cast_vision_ray(w_eye, rdir, 145.0, region.sight_blockers)
			var cur3 := _to_3d(hit2, 0.085)
			if k > 0:
				verts.append(origin3)
				verts.append(prev3)
				verts.append(cur3)
				cols.append(col)
				cols.append(edge_col)
				cols.append(edge_col)
			prev3 = cur3
		if verts.size() >= 3:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arrays[Mesh.ARRAY_COLOR] = cols
			cone_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _compute_camera_focus() -> Dictionary:
	var is_dlg: bool = region.ui != null and region.ui.dialogue_active and not region.ui.cutscene_active
	if bool(region.ship_intro_active):
		return {"pos2": Vector2(region.ship_pos) + Vector2(22, 0), "focus_y": 0.95, "is_dlg": false}
	if bool(region.ambush_cutscene_active):
		return {"pos2": Vector2(region.AMBUSH_CENTER), "focus_y": 0.95, "is_dlg": is_dlg}
	return super._compute_camera_focus()


func _on_draw_extra_prompts(canvas: Node2D, font: Font, _blocked: bool) -> void:
	if region.player == null:
		return
	var ppos: Vector2 = region.player.position
	for vp in region.walk_portals:
		if not (vp is Dictionary):
			continue
		var d: Dictionary = vp
		var r: Rect2 = Rect2(d.get("rect", Rect2()))
		var center := r.get_center()
		if ppos.distance_to(center) <= 82.0:
			var label := str(d.get("label", ""))
			if label != "":
				var sp = _project_world_pt(center, 1.95)
				if sp is Vector2:
					assets.draw_interact_bubble(canvas, sp, label, font)
