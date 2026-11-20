extends Node

## Shared runtime host for Octopath-style HD-2D 3D dioramas.
## Manages the CanvasLayer 1 SubViewport + tilt-shift post-process, persistent &
## override 2D/HD-2D toggle state ([H] / Settings), rigid follow spherical orbit
## camera (RMB/MMB/Arrows with Arrow X/Y invert + Scroll zoom + [O] Vista/Reset),
## PlayerBoy 3D mirroring, projected prompt bubbles, and a 6-slot OmniLight3D pooler
## compliant with Godot 4.3 GL Compatibility per-surface light caps.

const HD2DLib := preload("res://scripts/hd2d/HD2DStageBuilder.gd")
const MAX_POOLED_LIGHTS := 6

var region = null
var assets = null
var wide_vista: bool = false
var _region_active: bool = false
var _force_mode: int = 0  # 0 = follow GameState.hd2d_mode_enabled, 1 = force HD-2D, -1 = force 2D

var default_yaw_deg: float = 0.0
var default_pitch_deg: float = 34.5
var default_dist: float = 15.2
var vista_pitch_deg: float = 38.0
var vista_dist: float = 27.5
var min_pitch_deg: float = 14.0
var max_pitch_deg: float = 68.0
var min_dist: float = 7.0
var max_dist: float = 32.0
var px_per_m: float = 48.0
var boy_base_pixel_size: float = 0.056

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
var _boy_held_spr: Sprite3D
var _slash_spr: Sprite3D
var _rope_mesh: MeshInstance3D
var _pooled_lights: Array[OmniLight3D] = []

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
	_cam_yaw = deg_to_rad(default_yaw_deg)
	_cam_yaw_cur = _cam_yaw
	_cam_pitch = deg_to_rad(default_pitch_deg)
	_cam_pitch_cur = _cam_pitch
	_cam_dist = default_dist
	_cam_dist_cur = _cam_dist
	if DisplayServer.get_name() == "headless":
		return

	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "HD2DLayer"
	canvas_layer.layer = 1
	canvas_layer.visible = false
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
	subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport_container.add_child(subviewport)

	world_3d = Node3D.new()
	world_3d.name = "DioramaWorld3D"
	subviewport.add_child(world_3d)

	cam_3d = Camera3D.new()
	cam_3d.fov = 34.0
	cam_3d.far = 160.0
	cam_3d.current = true
	world_3d.add_child(cam_3d)

	_handles = _on_build_diorama()
	_init_light_pool()
	_create_boy_3d_actors()
	_on_create_dynamic_actors()

	prompt_overlay = _PromptOverlay.new()
	prompt_overlay.stage = self
	canvas_layer.add_child(prompt_overlay)
	_sync_visibility()


func _exit_tree() -> void:
	_set_arrow_keys_captured(false)


func _on_build_diorama() -> Dictionary:
	return {}


func _on_create_dynamic_actors() -> void:
	pass


func _on_sync_stage(_delta: float, _t_now: float) -> void:
	pass


func _should_hide_stage() -> bool:
	return false


func _ground_y_at(_p2d: Vector2) -> float:
	return 0.0


func _to_3d(p2d: Vector2, y_val: float = NAN) -> Vector3:
	var y: float = _ground_y_at(p2d) if is_nan(y_val) else y_val
	return Vector3(p2d.x / px_per_m, y, p2d.y / px_per_m)


func _get_boy_carry_fallback_tex() -> String:
	return "prop_dragon_egg_held.png"


func _compute_camera_focus() -> Dictionary:
	var ppos: Vector2 = region.player.position if (region != null and region.player != null) else Vector2.ZERO
	var focus2: Vector2 = ppos
	var focus_y: float = _ground_y_at(ppos) + 0.85
	var is_dlg: bool = region != null and region.ui != null and region.ui.dialogue_active and not region.ui.cutscene_active
	if is_dlg and region.last_interacted_pos is Vector2:
		var ipos: Vector2 = region.last_interacted_pos
		if ipos.is_finite() and ipos.distance_to(ppos) <= 190.0:
			focus2 = ppos.lerp(ipos, 0.45)
	return {"pos2": focus2, "focus_y": focus_y, "is_dlg": is_dlg}


func _on_draw_extra_prompts(_canvas: Node2D, _font: Font, _blocked: bool) -> void:
	pass


func _init_light_pool() -> void:
	_pooled_lights.clear()
	if world_3d == null:
		return
	for i in range(MAX_POOLED_LIGHTS):
		var lgt := OmniLight3D.new()
		lgt.name = "PooledLight_%d" % i
		lgt.shadow_enabled = false
		lgt.omni_range = 8.0
		lgt.omni_attenuation = 1.55
		lgt.light_energy = 2.0
		lgt.visible = false
		world_3d.add_child(lgt)
		_pooled_lights.append(lgt)


func hide_pooled_lights() -> void:
	for lgt: OmniLight3D in _pooled_lights:
		if lgt != null:
			lgt.visible = false


func sync_pooled_lights(candidates: Array, focus_pos3: Vector3, t_now: float) -> void:
	if _pooled_lights.is_empty():
		return
	var scored: Array = []
	for c in candidates:
		if not (c is Dictionary):
			continue
		var d: Dictionary = c
		var lpos: Vector3 = Vector3(d.get("pos", Vector3.ZERO))
		var bias: float = float(d.get("priority_bias", 0.0))
		scored.append({"score": lpos.distance_squared_to(focus_pos3) - bias, "data": d})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) < float(b["score"]))
	for i in range(_pooled_lights.size()):
		var lgt: OmniLight3D = _pooled_lights[i]
		if lgt == null:
			continue
		if i < scored.size():
			var d: Dictionary = scored[i]["data"]
			var energy: float = float(d.get("energy", 2.0))
			var ph: float = float(d.get("flicker_phase", -1.0))
			if ph >= 0.0:
				var amp: float = float(d.get("flicker_amp", 0.08))
				energy *= 1.0 + amp * sin(t_now * 7.1 + ph) + (amp * 0.5) * cos(t_now * 13.4 + ph)
			lgt.position = Vector3(d.get("pos", Vector3.ZERO))
			lgt.light_color = Color(d.get("color", Color(1.0, 0.78, 0.42)))
			lgt.light_energy = energy
			lgt.omni_range = float(d.get("range", 8.0))
			lgt.omni_attenuation = float(d.get("attenuation", 1.55))
			lgt.visible = true
		else:
			lgt.visible = false


func _create_boy_3d_actors() -> void:
	var init_tex_name := "boy17_down_0.png" if GameState.boy_age >= 17 else "boy_down_0.png"
	_boy_spr = HD2DLib.make_sprite3d(assets.get_tex(init_tex_name, "boy_down_0.png"), init_tex_name, boy_base_pixel_size)
	world_3d.add_child(_boy_spr)

	var carry_fb := _get_boy_carry_fallback_tex()
	_boy_carry_spr = HD2DLib.make_sprite3d(assets.get_tex(carry_fb), carry_fb, 0.048, false)
	_boy_carry_spr.visible = false
	world_3d.add_child(_boy_carry_spr)

	_boy_sling_spr = HD2DLib.make_sprite3d(assets.get_tex("prop_hatchling_sling_down.png", carry_fb), "prop_hatchling_sling_down.png", 0.048, false)
	_boy_sling_spr.visible = false
	world_3d.add_child(_boy_sling_spr)

	_boy_held_spr = HD2DLib.make_sprite3d(assets.get_tex(carry_fb), carry_fb, 0.044, false, 0.25)
	_boy_held_spr.visible = false
	world_3d.add_child(_boy_held_spr)

	_slash_spr = HD2DLib.make_sprite3d(assets.get_tex("prop_slash_arc.png"), "prop_slash_arc.png", 0.052, false, 1.4, false)
	_slash_spr.rotation_degrees.x = -55.0
	_slash_spr.visible = false
	world_3d.add_child(_slash_spr)

	_rope_mesh = HD2DLib.make_color_box(Vector3(0.08, 0.08, 1.0), Color(0.84, 0.70, 0.40), 0.75)
	_rope_mesh.visible = false
	world_3d.add_child(_rope_mesh)


func is_hd2d_active() -> bool:
	if _force_mode > 0:
		return true
	if _force_mode < 0:
		return false
	return GameState.hd2d_mode_enabled


func is_stage_visible() -> bool:
	if not _region_active or not is_hd2d_active() or canvas_layer == null:
		return false
	if _should_hide_stage():
		return false
	return true


func on_region_enter(opts: Dictionary = {}) -> void:
	_region_active = true
	if bool(opts.get("force_2d", false)):
		_force_mode = -1
	elif bool(opts.get("force_hd2d", false)):
		_force_mode = 1
	else:
		_force_mode = 0
	_mouse_dragging = false
	set_wide_vista(bool(opts.get("wide_vista", false)))
	_sync_visibility()
	step(0.0, Time.get_ticks_msec() * 0.001)
	snap_camera()


func on_region_exit() -> void:
	_region_active = false
	_force_mode = 0
	_mouse_dragging = false
	_sync_visibility()


func set_hd2d_enabled(enabled: bool, persist: bool = false) -> void:
	_mouse_dragging = false
	if persist:
		_force_mode = 0
		GameState.hd2d_mode_enabled = enabled
		GameState.apply_and_save_settings()
	else:
		_force_mode = 1 if enabled else -1
	_sync_visibility()
	if is_stage_visible():
		step(0.0, Time.get_ticks_msec() * 0.001)


func clear_hd2d_override() -> void:
	_force_mode = 0
	_sync_visibility()


func set_wide_vista(wide: bool) -> void:
	wide_vista = wide
	_cam_yaw = deg_to_rad(default_yaw_deg)
	_cam_pitch = deg_to_rad(vista_pitch_deg if wide else default_pitch_deg)
	_cam_dist = vista_dist if wide else default_dist
	_cam_snapped = false


func set_orbit(yaw_deg: float, pitch_deg: float, dist: float) -> void:
	_cam_yaw = deg_to_rad(yaw_deg)
	_cam_pitch = clampf(deg_to_rad(pitch_deg), deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	_cam_dist = clampf(dist, min_dist, max_dist)
	wide_vista = _cam_dist >= (default_dist + vista_dist) * 0.65
	snap_camera()


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
	if not _ensure_setup_valid() or not _region_active:
		return false
	if region != null and region.ui != null and region.ui.is_blocking_gameplay():
		_mouse_dragging = false
		return false
	if _should_hide_stage():
		_mouse_dragging = false
		return false

	if event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_H:
			set_hd2d_enabled(not is_hd2d_active(), true)
			SoundManager.play_ui_click()
			if prompt_overlay != null:
				prompt_overlay.queue_redraw()
			return true
		if kev.keycode == KEY_O and is_hd2d_active():
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
			_cam_dist = clampf(_cam_dist - 1.35, min_dist, max_dist)
			wide_vista = _cam_dist >= (default_dist + vista_dist) * 0.65
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam_dist = clampf(_cam_dist + 1.35, min_dist, max_dist)
			wide_vista = _cam_dist >= (default_dist + vista_dist) * 0.65
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
		_cam_pitch = clampf(_cam_pitch + mm.relative.y * 0.0055, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
		return true

	return false


func step(delta: float, t_now: float) -> void:
	if not _ensure_setup_valid():
		return
	_sync_visibility()
	if not is_stage_visible():
		return

	_on_sync_stage(delta, t_now)
	sync_player_3d()
	_update_camera(delta)
	if prompt_overlay != null:
		prompt_overlay.queue_redraw()


func sync_player_3d() -> void:
	if region == null or region.player == null or _boy_spr == null:
		return
	var p: CharacterBody2D = region.player
	var show_p: bool = p.visible and not bool(p.get("cutscene_hidden"))
	_boy_spr.visible = show_p
	var gy: float = _ground_y_at(p.position)
	_boy_spr.position = _to_3d(p.position, gy)
	var p_spr: Sprite2D = p.get("sprite")
	if p_spr != null and p_spr.texture != null:
		var fname := HD2DLib.resolve_tex_name(assets, p_spr.texture)
		HD2DLib.apply_sprite3d_frame(_boy_spr, p_spr.texture, fname)
		_boy_spr.flip_h = p_spr.flip_h
		_boy_spr.modulate = p_spr.modulate
		_boy_spr.pixel_size = boy_base_pixel_size * (1.07 if GameState.boy_age >= 17 else 1.0)

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
		_boy_carry_spr.position = _boy_spr.position + right_xz * (off2.x / px_per_m) + Vector3(0.0, maxf(0.12, -off2.y / px_per_m - 0.08), 0.0) + fwd_xz * z_off
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
		_boy_sling_spr.position = _boy_spr.position + right_xz * (soff2.x / px_per_m) + Vector3(0.0, maxf(0.18, -soff2.y / px_per_m - 0.12), 0.0) + fwd_xz * sz_off
	else:
		_boy_sling_spr.visible = false

	var held_t: float = float(p.get("held_item_timer")) if p.get("held_item_timer") != null else 0.0
	var held_tex = p.get("held_item_tex")
	if show_p and held_t > 0.0 and held_tex is Texture2D:
		_boy_held_spr.visible = true
		var hname := HD2DLib.resolve_tex_name(assets, held_tex)
		HD2DLib.apply_sprite3d_frame(_boy_held_spr, held_tex, hname, 0.35)
		_boy_held_spr.position = _boy_spr.position + Vector3(0.0, 1.85, 0.0)
	else:
		_boy_held_spr.visible = false

	var k_timer: float = float(p.get("knife_timer"))
	if show_p and k_timer > 0.0:
		_slash_spr.visible = true
		var k_dur: float = maxf(0.01, float(p.get("knife_duration")))
		var kp: float = 1.0 - (k_timer / k_dur)
		var k_dir: Vector2 = Vector2(p.get("knife_dir"))
		var sl_pos2: Vector2 = p.position + k_dir * 26.0
		_slash_spr.position = _to_3d(sl_pos2, gy + 0.55)
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
		var rlen: float = maxf(0.15, (reach * r_max) / px_per_m)
		_rope_mesh.visible = rp >= 0.18
		if _rope_mesh.visible:
			var rdir3: Vector3 = Vector3(r_dir2.x, 0.0, r_dir2.y).normalized()
			_rope_mesh.position = _boy_spr.position + Vector3(0.0, 0.55, 0.0) + rdir3 * (rlen * 0.5)
			_rope_mesh.scale = Vector3(1.0, 1.0, rlen)
			_rope_mesh.look_at(_rope_mesh.position + rdir3, Vector3.UP)
	else:
		_rope_mesh.visible = false


func _update_camera(delta: float) -> void:
	if cam_3d == null or region == null or region.player == null:
		return
	var focus_pack: Dictionary = _compute_camera_focus()
	var focus2: Vector2 = Vector2(focus_pack.get("pos2", region.player.position))
	var focus_y: float = float(focus_pack.get("focus_y", _ground_y_at(focus2) + 0.85))
	var is_dlg: bool = bool(focus_pack.get("is_dlg", false))

	var blocked: bool = region.ui != null and region.ui.is_blocking_gameplay()
	if not blocked and (region.ui == null or not region.ui.cutscene_active) and delta < 0.95:
		var yaw_in := (1.0 if Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_LEFT) else 0.0)
		var pitch_in := (1.0 if Input.is_key_pressed(KEY_UP) else 0.0) - (1.0 if Input.is_key_pressed(KEY_DOWN) else 0.0)
		if GameState.invert_cam_x_arrows:
			yaw_in = -yaw_in
		if GameState.invert_cam_y_arrows:
			pitch_in = -pitch_in
		if absf(yaw_in) > 0.01:
			_cam_yaw += yaw_in * delta * 1.85
		if absf(pitch_in) > 0.01:
			_cam_pitch = clampf(_cam_pitch + pitch_in * delta * 1.15, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))

	var target_dist := (_cam_dist * 0.68) if is_dlg else _cam_dist
	var target_fov := 32.0 if is_dlg else (36.0 if wide_vista else 34.0)
	var look_pt := _to_3d(focus2, focus_y)

	var alpha := 1.0 if (not _cam_snapped or delta >= 0.95) else clampf(delta * 7.5, 0.0, 1.0)
	var ang_alpha := 1.0 if (not _cam_snapped or delta >= 0.95) else clampf(delta * 10.0, 0.0, 1.0)
	_cam_focus = look_pt if alpha >= 0.99 else _cam_focus.lerp(look_pt, alpha)
	_cam_yaw_cur = lerp_angle(_cam_yaw_cur, _cam_yaw, ang_alpha)
	_cam_pitch_cur = lerpf(_cam_pitch_cur, _cam_pitch, ang_alpha)
	_cam_dist_cur = lerpf(_cam_dist_cur, target_dist, alpha)
	cam_3d.fov = lerpf(cam_3d.fov, target_fov, alpha)

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
	var w3 := _to_3d(p2d, _ground_y_at(p2d) + extra_y)
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
		_on_draw_extra_prompts(canvas, font, blocked)

	if not blocked and (ui == null or not ui.cutscene_active):
		var vp_h := float(subviewport.size.y) if subviewport != null and subviewport.size.y > 0 else 720.0
		var pill_txt := "HD-2D  •  Drag RMB/MMB or Arrows: Orbit  •  Scroll: Zoom  •  [O] Reset/Vista  •  [H] 2D"
		var tsz := font.get_string_size(pill_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		var box := Rect2(14.0, vp_h - 38.0, tsz.x + 20.0, 24.0)
		canvas.draw_rect(Rect2(box.position + Vector2(1, 2), box.size), Color(0.02, 0.02, 0.04, 0.55))
		canvas.draw_rect(box, Color(0.09, 0.08, 0.12, 0.88))
		canvas.draw_rect(box, Color(0.76, 0.60, 0.30, 0.85), false, 1.4)
		assets.draw_label_shadowed(canvas, Vector2(box.position.x + 10.0, box.position.y + 16.0), pill_txt, font, 11, Color(0.95, 0.90, 0.74), false)
