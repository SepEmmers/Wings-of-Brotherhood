extends Node
extends "res://scripts/hd2d/HD2DRegionHost.gd"

## Runtime HD-2D controller for Brabant Reed-Fens (`brabant_fens`).
## Hosts an isolated 3D SubViewport + Octopath tilt-shift ShaderMaterial on CanvasLayer 1
## (strictly below GameUI Layer 2), mirrors all 2D Region/Player/Companion state to 3D,
## projects crisp screen-space interact prompts, and toggles live via [H] / [O].
## Extends HD2DRegionHost with Brabant companion/vent/kestrel/brazier/waterwheel sync
## and Brabant-specific world prompt projections.

const HD2DLib := preload("res://scripts/hd2d/HD2DStageBuilder.gd")
const DioramaBuilder := preload("res://scripts/hd2d/BrabantFensHD2DBuilder.gd")

var region = null
var assets = null
var hd2d_enabled: bool = true
var wide_vista: bool = false

var canvas_layer: CanvasLayer
var viewport_container: SubViewportContainer
var subviewport: SubViewport
var world_3d: Node3D
var cam_3d: Camera3D
var tilt_mat: ShaderMaterial
var prompt_overlay: _PromptOverlay

var _handles: Dictionary = {}
var _boy_spr: Sprite3D
var _boy_carry_spr: Sprite3D
var _boy_sling_spr: Sprite3D
var _slash_spr: Sprite3D
var _rope_mesh: MeshInstance3D
var _hatchling_spr: Sprite3D
var _vent_hatchling_spr: Sprite3D
var _kestrel_spr: Sprite3D
var _eat_morsel_spr: Sprite3D
var _gold_sense_bulb: MeshInstance3D
var _ember_orbs: Array[MeshInstance3D] = []
var _cam_snapped: bool = false
var _cam_focus: Vector3 = Vector3.ZERO
var _cam_yaw: float = 0.0
var _cam_yaw_cur: float = 0.0
var _cam_pitch: float = deg_to_rad(34.5)
var _cam_pitch_cur: float = deg_to_rad(34.5)
var _cam_dist: float = 15.2
var _cam_dist_cur: float = 15.2
var _mouse_dragging: bool = false
var _drag_button: int = 0
var _drag_total_px: float = 0.0
var _saved_arrow_events: Dictionary = {}
var _arrows_captured: bool = false


class _PromptOverlay extends Node2D:
	var stage = null

	func _draw() -> void:
		if stage == null or not stage.is_stage_visible():
			return
		stage.draw_projected_prompts(self)


func setup(region_ref, assets_ref) -> void:
	region = region_ref
	assets = assets_ref
	if DisplayServer.get_name() == "headless":
		return

	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "HD2DLayer"
	canvas_layer.layer = 1
	add_child(canvas_layer)

	viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tilt_mat = ShaderMaterial.new()
	tilt_mat.shader = load("res://assets/shaders/hd2d_tilt_shift.gdshader")
	viewport_container.material = tilt_mat
	canvas_layer.add_child(viewport_container)

	subviewport = SubViewport.new()
	subviewport.own_world_3d = true
	subviewport.size = Vector2i(1280, 720)
	subviewport.msaa_3d = Viewport.MSAA_2X
	subviewport.positional_shadow_atlas_size = 2048
	subviewport.handle_input_locally = false
	subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if DisplayServer.get_name() == "headless" else SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(subviewport)

	world_3d = Node3D.new()
func _on_build_diorama() -> Dictionary:
	px_per_m = DioramaBuilder.PX_PER_M
	world_3d.name = "BrabantDiorama3D"
	subviewport.add_child(world_3d)
	return DioramaBuilder.build_diorama(world_3d, region, assets)

	cam_3d = Camera3D.new()
	cam_3d.fov = 34.0
	cam_3d.far = 140.0
	cam_3d.current = true
	world_3d.add_child(cam_3d)

	_handles = DioramaBuilder.build_diorama(world_3d, region, assets)
	_create_dynamic_actors()
func _ground_y_at(p2d: Vector2) -> float:
	return DioramaBuilder.ground_y_at(p2d)

	prompt_overlay = _PromptOverlay.new()
	prompt_overlay.stage = self
	canvas_layer.add_child(prompt_overlay)

func _to_3d(p2d: Vector2, y_val: float = NAN) -> Vector3:
	var y: float = _ground_y_at(p2d) if is_nan(y_val) else y_val
	return DioramaBuilder.to_3d(p2d, y)

func _create_dynamic_actors() -> void:
	_boy_spr = HD2DLib.make_sprite3d(assets.get_tex("boy17_down_0.png"), "boy17_down_0.png", 0.056)
	world_3d.add_child(_boy_spr)

	_boy_carry_spr = HD2DLib.make_sprite3d(assets.get_tex("prop_dragon_egg_held.png"), "prop_dragon_egg_held.png", 0.048, false)
	_boy_carry_spr.visible = false
	world_3d.add_child(_boy_carry_spr)
func _should_hide_stage() -> bool:
	return region != null and region.hatching_cutscene != null and region.hatching_cutscene.active

	_boy_sling_spr = HD2DLib.make_sprite3d(assets.get_tex("prop_hatchling_sling_down.png"), "prop_hatchling_sling_down.png", 0.048, false)
	_boy_sling_spr.visible = false
	world_3d.add_child(_boy_sling_spr)

	_slash_spr = HD2DLib.make_sprite3d(assets.get_tex("prop_slash_arc.png"), "prop_slash_arc.png", 0.052, false, 1.4, false)
	_slash_spr.rotation_degrees.x = -55.0
	_slash_spr.visible = false
	world_3d.add_child(_slash_spr)

	_rope_mesh = HD2DLib.make_color_box(Vector3(0.08, 0.08, 1.0), Color(0.84, 0.70, 0.40), 0.75)
	_rope_mesh.visible = false
	world_3d.add_child(_rope_mesh)

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


func _exit_tree() -> void:
	_set_arrow_keys_captured(false)


func set_hd2d_enabled(enabled: bool) -> void:
	hd2d_enabled = enabled
	_mouse_dragging = false
	_sync_visibility()


func set_wide_vista(wide: bool) -> void:
	wide_vista = wide
	_cam_yaw = 0.0
	_cam_pitch = deg_to_rad(38.0 if wide else 34.5)
	_cam_dist = 27.5 if wide else 15.2
	_cam_snapped = false


func set_orbit(yaw_deg: float, pitch_deg: float, dist: float) -> void:
	_cam_yaw = deg_to_rad(yaw_deg)
	_cam_pitch = clampf(deg_to_rad(pitch_deg), deg_to_rad(14.0), deg_to_rad(68.0))
	_cam_dist = clampf(dist, 7.0, 32.0)
	wide_vista = _cam_dist >= 22.0
	snap_camera()


func is_stage_visible() -> bool:
	if not hd2d_enabled or canvas_layer == null:
		return false
	if region != null and region.hatching_cutscene != null and region.hatching_cutscene.active:
		return false
	return true


func _sync_visibility() -> void:
	var vis := is_stage_visible()
	if canvas_layer != null:
		canvas_layer.visible = vis
	if subviewport != null:
		subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if vis else SubViewport.UPDATE_DISABLED
	_set_arrow_keys_captured(vis)
	if not vis and region != null and region.player != null:
		region.player.set("camera_yaw_rad", 0.0)


func _set_arrow_keys_captured(capture: bool) -> void:
	if capture:
		if _arrows_captured or DisplayServer.get_name() == "headless":
			return
		_saved_arrow_events.clear()
		for action_name: String in ["move_up", "move_down", "move_left", "move_right"]:
			if not InputMap.has_action(action_name):
				continue
			var saved: Array[InputEvent] = []
			for ev: InputEvent in InputMap.action_get_events(action_name):
				if ev is InputEventKey:
					var kev := ev as InputEventKey
					var kc := kev.keycode if kev.keycode != KEY_NONE else kev.physical_keycode
					if kc in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
						saved.append(ev)
			for ev in saved:
				InputMap.action_erase_event(action_name, ev)
			if not saved.is_empty():
				_saved_arrow_events[action_name] = saved
		_arrows_captured = true
	else:
		if not _arrows_captured:
			return
		for action_name: String in _saved_arrow_events.keys():
			if not InputMap.has_action(action_name):
				continue
			var existing := InputMap.action_get_events(action_name)
			for ev: InputEvent in _saved_arrow_events[action_name]:
				if not existing.has(ev):
					InputMap.action_add_event(action_name, ev)
		_saved_arrow_events.clear()
		_arrows_captured = false


func _ensure_setup_valid() -> bool:
	return canvas_layer != null and cam_3d != null


func snap_camera() -> void:
	_cam_yaw_cur = _cam_yaw
	_cam_pitch_cur = _cam_pitch
	_cam_dist_cur = _cam_dist
	_cam_snapped = false
	_update_camera(1.0)


func handle_input(event: InputEvent) -> bool:
	if not _ensure_setup_valid():
		return false
	if region != null and region.ui != null and region.ui.is_blocking_gameplay():
		_mouse_dragging = false
		return false

	if event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_H:
			set_hd2d_enabled(not hd2d_enabled)
			SoundManager.play_ui_click()
			if prompt_overlay != null:
				prompt_overlay.queue_redraw()
			return true
		if kev.keycode == KEY_O and hd2d_enabled:
			set_wide_vista(not wide_vista)
			SoundManager.play_ui_click()
			if prompt_overlay != null:
				prompt_overlay.queue_redraw()
			return true

	if not is_stage_visible():
		return false

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam_dist = clampf(_cam_dist - 1.35, 7.0, 32.0)
			wide_vista = _cam_dist >= 22.0
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam_dist = clampf(_cam_dist + 1.35, 7.0, 32.0)
			wide_vista = _cam_dist >= 22.0
			return true
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_mouse_dragging = true
				_drag_button = mb.button_index
				_drag_total_px = 0.0
				return true
			elif _mouse_dragging and mb.button_index == _drag_button:
				_mouse_dragging = false
				if _drag_button == MOUSE_BUTTON_RIGHT and _drag_total_px <= 6.0 and region.player != null:
					var p = region.player
					if bool(p.get("can_move")) and bool(p.get("allow_tools")) and GameState.rope_unlocked and not GameState.carrying_crate and float(p.get("rope_timer")) <= 0.0 and float(p.get("dodge_timer")) <= 0.0:
						p.call("_trigger_rope_cast")
				return true

	if event is InputEventMouseMotion and _mouse_dragging:
		var mm := event as InputEventMouseMotion
		_drag_total_px += mm.relative.length()
		_cam_yaw -= mm.relative.x * 0.0065
		_cam_pitch = clampf(_cam_pitch + mm.relative.y * 0.0055, deg_to_rad(14.0), deg_to_rad(68.0))
		return true

	return false


func step(delta: float, t_now: float) -> void:
	if not _ensure_setup_valid():
		return
	_sync_visibility()
	if not is_stage_visible():
		return

func _on_sync_stage(delta: float, t_now: float) -> void:
	_sync_lighting_mood(t_now)
	_sync_world_handles(delta, t_now)
	_sync_player()
	_sync_companion(t_now)
	_sync_vent_crawl(t_now)
	_sync_kestrel(t_now)
	_update_camera(delta)
	if prompt_overlay != null:
		prompt_overlay.queue_redraw()


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


func _sync_player() -> void:
	var p: CharacterBody2D = region.player
	if p == null or _boy_spr == null:
		return
	var show_p: bool = p.visible and not bool(p.get("cutscene_hidden"))
	_boy_spr.visible = show_p
	var gy: float = DioramaBuilder.ground_y_at(p.position)
	_boy_spr.position = DioramaBuilder.to_3d(p.position, gy)
	var p_spr: Sprite2D = p.get("sprite")
	if p_spr != null and p_spr.texture != null:
		var fname := HD2DLib.resolve_tex_name(assets, p_spr.texture)
		HD2DLib.apply_sprite3d_frame(_boy_spr, p_spr.texture, fname)
		_boy_spr.flip_h = p_spr.flip_h
		_boy_spr.modulate = p_spr.modulate
		_boy_spr.pixel_size = 0.056 * (1.07 if GameState.boy_age >= 17 else 1.0)

	var right_xz := Vector3(cos(_cam_yaw_cur), 0.0, -sin(_cam_yaw_cur))
	var fwd_xz := Vector3(sin(_cam_yaw_cur), 0.0, cos(_cam_yaw_cur))

	var carry_spr: Sprite2D = p.get("carry_prop_sprite")
	if carry_spr != null and carry_spr.visible and carry_spr.texture != null and show_p:
		_boy_carry_spr.visible = true
		var cname := HD2DLib.resolve_tex_name(assets, carry_spr.texture)
		HD2DLib.apply_sprite3d_frame(_boy_carry_spr, carry_spr.texture, cname)
		_boy_carry_spr.flip_h = carry_spr.flip_h
		var off2: Vector2 = carry_spr.position
		var z_off: float = 0.12 if carry_spr.z_index >= 2 else -0.10
		_boy_carry_spr.position = _boy_spr.position + right_xz * (off2.x / DioramaBuilder.PX_PER_M) + Vector3(0.0, maxf(0.12, -off2.y / DioramaBuilder.PX_PER_M - 0.08), 0.0) + fwd_xz * z_off
	else:
		_boy_carry_spr.visible = false

	var sling_spr: Sprite2D = p.get("sling_sprite")
	if sling_spr != null and sling_spr.visible and sling_spr.texture != null and show_p:
		_boy_sling_spr.visible = true
		var sname := HD2DLib.resolve_tex_name(assets, sling_spr.texture)
		HD2DLib.apply_sprite3d_frame(_boy_sling_spr, sling_spr.texture, sname)
		_boy_sling_spr.flip_h = sling_spr.flip_h
		var soff2: Vector2 = sling_spr.position
		var sz_off: float = 0.08 if sling_spr.z_index >= 2 else -0.08
		_boy_sling_spr.position = _boy_spr.position + right_xz * (soff2.x / DioramaBuilder.PX_PER_M) + Vector3(0.0, maxf(0.18, -soff2.y / DioramaBuilder.PX_PER_M - 0.12), 0.0) + fwd_xz * sz_off
	else:
		_boy_sling_spr.visible = false

	var k_timer: float = float(p.get("knife_timer"))
	if show_p and k_timer > 0.0:
		_slash_spr.visible = true
		var k_dur: float = maxf(0.01, float(p.get("knife_duration")))
		var kp: float = 1.0 - (k_timer / k_dur)
		var k_dir: Vector2 = Vector2(p.get("knife_dir"))
		var sl_pos2: Vector2 = p.position + k_dir * 26.0
		_slash_spr.position = DioramaBuilder.to_3d(sl_pos2, gy + 0.55)
		_slash_spr.rotation.y = -k_dir.angle()
		_slash_spr.modulate = Color(1.0, 0.92, 0.60, 1.0 - kp * 0.5)
	else:
		_slash_spr.visible = false

	var r_timer: float = float(p.get("rope_timer"))
	if show_p and r_timer > 0.0:
		var r_dur: float = maxf(0.01, float(p.get("rope_duration")))
		var rp: float = 1.0 - (r_timer / r_dur)
		var flight_p: float = maxf(0.0, (rp - 0.18) / 0.82)
		var reach: float = sin(minf(1.0, flight_p * 1.35) * PI * 0.5) if flight_p < 0.38 else maxf(0.0, 1.0 - (flight_p - 0.38) / 0.62)
		var r_max: float = float(p.get("rope_max_dist"))
		var r_dir2: Vector2 = Vector2(p.get("rope_dir"))
		var rlen: float = maxf(0.15, (reach * r_max) / DioramaBuilder.PX_PER_M)
		_rope_mesh.visible = rp >= 0.18
		if _rope_mesh.visible:
			var rdir3: Vector3 = Vector3(r_dir2.x, 0.0, r_dir2.y).normalized()
			_rope_mesh.position = _boy_spr.position + Vector3(0.0, 0.55, 0.0) + rdir3 * (rlen * 0.5)
			_rope_mesh.scale = Vector3(1.0, 1.0, rlen)
			_rope_mesh.look_at(_rope_mesh.position + rdir3, Vector3.UP)
	else:
		_rope_mesh.visible = false


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


func _update_camera(delta: float) -> void:
	if cam_3d == null or region.player == null:
		return
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
	elif region.ui != null and region.ui.dialogue_active and not region.ui.cutscene_active:
	elif is_dlg:
		var ipos: Vector2 = region.last_interacted_pos
		if ipos.is_finite() and ipos.distance_to(ppos) <= 190.0:
			focus2 = ppos.lerp(ipos, 0.45)
	return {"pos2": focus2, "focus_y": focus_y, "is_dlg": is_dlg}

	var blocked: bool = region.ui != null and region.ui.is_blocking_gameplay()
	if not blocked and (region.ui == null or not region.ui.cutscene_active) and delta < 0.95:
		var yaw_in := (1.0 if Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_LEFT) else 0.0)
		var pitch_in := (1.0 if Input.is_key_pressed(KEY_UP) else 0.0) - (1.0 if Input.is_key_pressed(KEY_DOWN) else 0.0)
		if absf(yaw_in) > 0.01:
			_cam_yaw += yaw_in * delta * 1.85
		if absf(pitch_in) > 0.01:
			_cam_pitch = clampf(_cam_pitch + pitch_in * delta * 1.15, deg_to_rad(14.0), deg_to_rad(68.0))

	var is_dlg: bool = region.ui != null and region.ui.dialogue_active and not region.ui.cutscene_active
	var target_dist := (_cam_dist * 0.68) if is_dlg else _cam_dist
	var target_fov := 32.0 if is_dlg else (36.0 if wide_vista else 34.0)
	var look_pt := DioramaBuilder.to_3d(focus2, focus_y)
func _on_draw_extra_prompts(canvas: Node2D, font: Font, _blocked: bool) -> void:
	if GameState.brabant_hatched:
		var ppos: Vector2 = region.player.position
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

	var alpha := 1.0 if (not _cam_snapped or delta >= 0.95) else clampf(delta * 7.5, 0.0, 1.0)
	var ang_alpha := 1.0 if (not _cam_snapped or delta >= 0.95) else clampf(delta * 10.0, 0.0, 1.0)
	_cam_focus = look_pt if alpha >= 0.99 else _cam_focus.lerp(look_pt, alpha)
	_cam_yaw_cur = lerp_angle(_cam_yaw_cur, _cam_yaw, ang_alpha)
	_cam_pitch_cur = lerpf(_cam_pitch_cur, _cam_pitch, ang_alpha)
	_cam_dist_cur = lerpf(_cam_dist_cur, target_dist, alpha)
	cam_3d.fov = lerpf(cam_3d.fov, target_fov, alpha)
		if GameState.brabant_vent_unlocked and ppos.x >= 1915.0 and GameState.companion_posture != "sling" and not GameState.brabant_sling_practiced:
			var sp_s = _project_world_pt(ppos, 2.05)
			if sp_s is Vector2:
				assets.draw_interact_bubble(canvas, sp_s, "[%s] Tuck Into Cloak-Sling" % post_k, font)

	# Compute offset from smoothed focus & smoothed spherical angles so player movement NEVER tilts the camera!
	var horiz := cos(_cam_pitch_cur) * _cam_dist_cur
	var vert := sin(_cam_pitch_cur) * _cam_dist_cur
	var offset := Vector3(sin(_cam_yaw_cur) * horiz, vert, cos(_cam_yaw_cur) * horiz)
	cam_3d.position = _cam_focus + offset
	cam_3d.look_at(_cam_focus, Vector3.UP)
	_cam_snapped = true

	region.player.set("camera_yaw_rad", _cam_yaw_cur)

	if tilt_mat != null:
		tilt_mat.set_shader_parameter("blur_strength", 1.45 if wide_vista else (2.4 if is_dlg else 2.1))
		tilt_mat.set_shader_parameter("focus_band", 0.22 if wide_vista else (0.24 if is_dlg else 0.19))


func _project_world_pt(p2d: Vector2, extra_y: float = 1.65) -> Variant:
	if cam_3d == null or subviewport == null or not cam_3d.is_inside_tree():
		return null
	if subviewport.size.x < 4 or subviewport.size.y < 4:
		return null
	var w3 := DioramaBuilder.to_3d(p2d, DioramaBuilder.ground_y_at(p2d) + extra_y)
	if cam_3d.is_position_behind(w3):
		return null
	var sp: Vector2 = cam_3d.unproject_position(w3)
	if sp.x < -80.0 or sp.y < -80.0 or sp.x > float(subviewport.size.x) + 80.0 or sp.y > float(subviewport.size.y) + 80.0:
		return null
	return sp


func draw_projected_prompts(canvas: Node2D) -> void:
	if region == null or assets == null or region.player == null:
		return
	var ui = region.ui
	var font: Font = assets.get_ui_font()
	var blocked: bool = ui != null and ui.is_blocking_gameplay()

	if not blocked and region.player.visible:
		if not region.nearest_interactable.is_empty():
			var npos: Vector2 = region.nearest_interactable["pos"]
			var sp = _project_world_pt(npos, 1.85)
			if sp is Vector2:
				assets.draw_interact_bubble(canvas, sp, "[E] " + str(region.nearest_interactable["name"]), font)

		if GameState.brabant_hatched:
			var ppos: Vector2 = region.player.position
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

		if region.player.position.distance_to(Vector2(2110, 714)) <= 165.0:
			var sp_g = _project_world_pt(Vector2(2092, 690), 2.1)
			if sp_g is Vector2:
				assets.draw_interact_bubble(canvas, sp_g, "Louvain West Gate ->", font)

	# Compact bottom-left HD-2D camera/toggle indicator pill
	if not blocked and (ui == null or not ui.cutscene_active):
		var vp_h := float(subviewport.size.y) if subviewport != null and subviewport.size.y > 0 else 720.0
		var pill_txt := "HD-2D  •  Drag RMB/MMB or Arrows: Orbit  •  Scroll: Zoom  •  [O] Reset/Vista  •  [H] 2D"
		var tsz := font.get_string_size(pill_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		var box := Rect2(14.0, vp_h - 38.0, tsz.x + 20.0, 24.0)
		canvas.draw_rect(Rect2(box.position + Vector2(1, 2), box.size), Color(0.02, 0.02, 0.04, 0.55))
		canvas.draw_rect(box, Color(0.09, 0.08, 0.12, 0.88))
		canvas.draw_rect(box, Color(0.76, 0.60, 0.30, 0.85), false, 1.4)
		assets.draw_label_shadowed(canvas, Vector2(box.position.x + 10.0, box.position.y + 16.0), pill_txt, font, 11, Color(0.95, 0.90, 0.74), false)
	if region.player.position.distance_to(Vector2(2110, 714)) <= 165.0:
		var sp_g = _project_world_pt(Vector2(2092, 690), 2.1)
		if sp_g is Vector2:
			assets.draw_interact_bubble(canvas, sp_g, "Louvain West Gate ->", font)
