extends Node2D

## Shared base class for all modular world regions and flight sorties.
## Provides static chunk baking (SubViewport + frustum/light-culled Sprite2D grid),
## camera-rect frustum culling, batched water layers, and PointLight2D culling so every
## region renders efficiently by default.

const RegionNavHelperScript := preload("res://scripts/regions/RegionNavHelper.gd")

var director: Node
var assets
var player: CharacterBody2D
var ui: CanvasLayer

var colliders: StaticBody2D
var npc_collider_body: StaticBody2D
var _npc_col_shapes: Array[CollisionShape2D] = []
var _npc_yield_offsets: Dictionary = {}
var _fg_layer: RegionForegroundLayer
var _portal_hint_layer: RegionForegroundLayer
var _portal_hint_was_near: bool = false
var lights: Array[PointLight2D] = []
var interactables: Array[Dictionary] = []
var nearest_interactable: Dictionary = {}
var walk_portals: Array[Dictionary] = []
var portal_cooldown: float = 0.85

var _nav := RegionNavHelperScript.new()


class RegionForegroundLayer extends Node2D:
	## Foreground overlay drawn above PlayerBoy (z_index = 18) for Y-sorted walk-behind roofs, arches, canopies, and foreground NPCs.
	var draw_cb: Callable
	var assets

	func _draw() -> void:
		if not draw_cb.is_valid():
			return
		if assets != null:
			assets.begin_world_text_pass(self)
		draw_cb.call(self)
		if assets != null:
			assets.flush_world_text_pass(self)


class StaticGroundCanvas extends Node2D:
	## One-shot canvas helper positioned inside a SubViewport so draw_cb uses world coords.
	var draw_cb: Callable

	func _draw() -> void:
		if draw_cb.is_valid():
			draw_cb.call(self)


class WaterBackdropLayer extends Node2D:
	## Batched repeating animated-water layer positioned below bridges/wharves.
	var assets
	var water_rects: Array[Rect2] = []
	var tile_px: float = 32.0
	var cam_rect: Rect2 = Rect2()

	func _draw() -> void:
		if assets == null:
			return
		for wr: Rect2 in water_rects:
			assets.draw_water_rect(self, wr, tile_px, cam_rect)


func initialize_region(dir_node: Node, assets_ref, player_ref: CharacterBody2D, ui_ref: CanvasLayer) -> void:
	director = dir_node
	assets = assets_ref
	player = player_ref
	ui = ui_ref
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not draw.is_connected(_on_region_draw_finished):
		draw.connect(_on_region_draw_finished)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW and assets != null:
		assets.begin_world_text_pass(self)


func _on_region_draw_finished() -> void:
	if assets != null:
		assets.flush_world_text_pass(self)


func enter_region(_opts: Dictionary = {}) -> void:
	pass


func exit_region() -> void:
	pass


func step_region(_delta: float) -> void:
	pass


func handle_region_input(_event: InputEvent) -> bool:
	return false


func on_rope_cast_hit(_tip_pos: Vector2, _knot_id: String) -> void:
	pass


func on_knife_slash(_tip_pos: Vector2, _dir: Vector2) -> void:
	pass


func interact_with_nearest() -> bool:
	if player != null:
		update_nearest_interactable(player.position)
	if nearest_interactable.is_empty():
		return false
	var cb: Callable = nearest_interactable["callback"]
	if cb.is_valid():
		cb.call()
		return true
	return false


func get_surface_at(_pos: Vector2) -> String:
	return "cobble"


func get_ambience_track() -> String:
	return "harbor"


func get_lighting_tint() -> Color:
	return Color(0.84, 0.76, 0.88)


func update_region_lights(_time_val: float) -> void:
	pass


func uses_standard_player_movement() -> bool:
	return true


func add_box_collider(parent: StaticBody2D, rect: Rect2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	col.position = rect.position + rect.size * 0.5
	parent.add_child(col)


func set_body_collision_enabled(body: StaticBody2D, enabled: bool) -> void:
	if body == null:
		return
	var layer_val := 1 if enabled else 0
	body.collision_layer = layer_val
	body.collision_mask = layer_val


func get_active_npc_colliders() -> Array:
	return []


## Smoothly yields a friendly or ambient NPC slightly aside when the player brushes near them
## so they never pin the player in narrow streets or doorways.
func get_npc_yield_pos(key: String, base_pos: Vector2, yield_radius: float = 34.0, max_shift: float = 13.0) -> Vector2:
	var frame_now: int = Engine.get_process_frames()
	var entry: Dictionary = _npc_yield_offsets.get(key, {"offset": Vector2.ZERO, "frame": -1})
	var cur: Vector2 = entry.get("offset", Vector2.ZERO)
	if int(entry.get("frame", -1)) != frame_now:
		if player != null and player.visible:
			var delta_p: Vector2 = base_pos - player.position
			var d: float = delta_p.length()
			if d < yield_radius:
				var away: Vector2 = (delta_p / d) if d > 0.01 else Vector2.RIGHT
				var side_sign: float = 1.0 if (key.hash() % 2 == 0) else -1.0
				var side: Vector2 = Vector2(-away.y, away.x) * side_sign
				var weight: float = clampf(1.0 - d / yield_radius, 0.28, 1.0)
				var target: Vector2 = (away * 0.68 + side * 0.56).normalized() * max_shift * weight
				cur = cur.lerp(target, 0.22)
			else:
				cur = cur.lerp(Vector2.ZERO, 0.14)
		else:
			cur = Vector2.ZERO
		_npc_yield_offsets[key] = {"offset": cur, "frame": frame_now}
	return base_pos + cur


## Ensures a foreground draw layer above PlayerBoy (z_index = 18) for walk-behind roof gables & NPC depth.
func ensure_foreground_layer(draw_cb: Callable, z_ord: int = 18) -> RegionForegroundLayer:
	if _fg_layer != null and is_instance_valid(_fg_layer):
		_fg_layer.draw_cb = draw_cb
		return _fg_layer
	var existing := get_node_or_null("RegionForegroundLayer") as RegionForegroundLayer
	if existing != null:
		_fg_layer = existing
		_fg_layer.assets = assets
		_fg_layer.draw_cb = draw_cb
		return _fg_layer
	var fg := RegionForegroundLayer.new()
	fg.name = "RegionForegroundLayer"
	fg.z_as_relative = false
	fg.z_index = z_ord
	fg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg.assets = assets
	fg.draw_cb = draw_cb
	add_child(fg)
	_fg_layer = fg
	return fg


func queue_foreground_redraw() -> void:
	if _fg_layer != null and is_instance_valid(_fg_layer):
		_fg_layer.queue_redraw()


## Draws only the upper roof/gable strip of a building on the foreground layer when PlayerBoy stands behind its eaves.
func draw_building_roof_overhang(fg: Node2D, rect: Rect2, tex: Texture2D, roof_ratio: float = 0.46) -> void:
	if player == null or not player.visible or tex == null:
		return
	if player.position.x < rect.position.x - 18.0 or player.position.x > rect.end.x + 18.0:
		return
	if player.position.y >= rect.end.y - 8.0 or player.position.y < rect.position.y - 26.0:
		return
	var tw: float = float(tex.get_width())
	var th: float = float(tex.get_height())
	var src_rect := Rect2(0.0, 0.0, tw, th * roof_ratio)
	var dst_rect := Rect2(rect.position, Vector2(rect.size.x, rect.size.y * roof_ratio))
	fg.draw_texture_rect_region(tex, dst_rect, src_rect)


func sync_npc_colliders() -> void:
	if npc_collider_body == null:
		npc_collider_body = StaticBody2D.new()
		npc_collider_body.name = "NpcColliderBody"
		add_child(npc_collider_body)

	var cut_active: bool = ui != null and bool(ui.get("cutscene_active"))
	var dash_active: bool = player != null and bool(player.get("winch_dash_active"))
	var move_ok: bool = player != null and player.visible and bool(player.get("can_move"))
	var enabled: bool = move_ok and not dash_active and not cut_active
	set_body_collision_enabled(npc_collider_body, enabled)
	if not enabled:
		return

	var specs: Array = get_active_npc_colliders()
	while _npc_col_shapes.size() < specs.size():
		var col := CollisionShape2D.new()
		var shp := CircleShape2D.new()
		shp.radius = 14.0
		col.shape = shp
		col.disabled = true
		npc_collider_body.add_child(col)
		_npc_col_shapes.append(col)

	for i in range(_npc_col_shapes.size()):
		var col: CollisionShape2D = _npc_col_shapes[i]
		if i >= specs.size():
			col.disabled = true
			continue
		var item: Variant = specs[i]
		var center := Vector2.ZERO
		var rad := 14.0
		if item is Vector2:
			center = (item as Vector2) + Vector2(0.0, 4.0)
		elif item is Dictionary:
			var d: Dictionary = item as Dictionary
			var raw_pos := Vector2(d.get("pos", Vector2.ZERO))
			var yk := str(d.get("yield_key", ""))
			if yk != "":
				raw_pos = get_npc_yield_pos(yk, raw_pos)
			var off := Vector2(d.get("offset", Vector2(0.0, 4.0)))
			center = raw_pos + off
			rad = float(d.get("radius", 14.0))
		col.disabled = false
		col.position = center
		var shp := col.shape as CircleShape2D
		if shp != null and not is_equal_approx(shp.radius, rad):
			shp.radius = rad

		var delta_p: Vector2 = player.position - center
		var min_dist := rad + 6.0
		var dlen := delta_p.length()
		if dlen < min_dist:
			var push_dir := (delta_p / dlen) if dlen > 0.01 else Vector2.DOWN
			player.position = center + push_dir * min_dist


func get_interactable_pos(item: Dictionary) -> Vector2:
	return item["pos"]


func is_interactable_active(_id: String) -> bool:
	return true


func update_nearest_interactable(pos: Vector2) -> void:
	nearest_interactable = {}
	var best_dist := INF
	for item in interactables:
		if not is_interactable_active(item["id"]):
			continue
		var ipos := get_interactable_pos(item)
		var d := pos.distance_to(ipos)
		if d <= float(item["radius"]) and d < best_dist:
			best_dist = d
			nearest_interactable = item.duplicate()
			nearest_interactable["pos"] = ipos


func clear_walk_portals() -> void:
	walk_portals.clear()
	portal_cooldown = 0.75


func register_walk_portal(id: String, rect: Rect2, move_dir_hint: Vector2, callback: Callable, sign_label: String = "", banner_title: String = "", banner_sub: String = "") -> void:
	walk_portals.append({
		"id": id,
		"rect": rect,
		"dir": move_dir_hint,
		"callback": callback,
		"sign_label": sign_label,
		"banner_title": banner_title,
		"banner_sub": banner_sub,
	})
	if _portal_hint_layer == null:
		_portal_hint_layer = RegionForegroundLayer.new()
		_portal_hint_layer.z_index = 22
		_portal_hint_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_portal_hint_layer.draw_cb = _draw_portal_hints
		add_child(_portal_hint_layer)


func is_portal_unlocked(_id: String) -> bool:
	return true


func _draw_portal_hints(canvas: Node2D) -> void:
	if player == null or not player.visible or (ui != null and ui.is_blocking_gameplay()):
		return
	var font: Font = assets.get_ui_font() if assets != null else ThemeDB.fallback_font
	var t_now: float = float(assets.time_elapsed) if assets != null else 0.0
	var pulse := 0.5 + 0.5 * sin(t_now * 4.4)
	for wp: Dictionary in walk_portals:
		var pid := str(wp.get("id", ""))
		if pid != "" and not is_interactable_active(pid):
			continue
		var r: Rect2 = wp["rect"]
		var ctr := r.get_center()
		if player.position.distance_to(ctr) > 120.0:
			continue
		var unlocked := is_portal_unlocked(pid)
		var dhint: Vector2 = wp.get("dir", Vector2.ZERO)
		var dn := dhint.normalized() if dhint.length_squared() > 0.01 else Vector2.UP
		var perp := Vector2(-dn.y, dn.x)
		var col := Color(0.98, 0.84, 0.42, 0.55 + 0.35 * pulse) if unlocked else Color(0.88, 0.36, 0.28, 0.65 + 0.25 * pulse)
		var c_base := ctr - dn * (4.0 - pulse * 3.0)
		if unlocked and GameState.hints_enabled:
			var tip := c_base + dn * 7.0
			canvas.draw_colored_polygon(PackedVector2Array([tip, c_base - dn * 3.0 + perp * 6.0, c_base - dn * 3.0 - perp * 6.0]), col)
		var lbl := str(wp.get("sign_label", ""))
		if lbl != "":
			var show_lbl := lbl if unlocked else ("Toll Lock  |  " + lbl)
			var tw := maxf(font.get_string_size(show_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 14.0, 74.0)
			var py := r.end.y + 8.0 if dn.y < -0.5 else (r.position.y - 26.0 if dn.y > 0.5 else ctr.y - 38.0)
			var px := clampf(ctr.x - tw * 0.5, 8.0, maxf(8.0, ctr.x + 200.0))
			if dn.x > 0.5:
				px = r.position.x - tw - 6.0
			elif dn.x < -0.5:
				px = r.end.x + 6.0
			var box := Rect2(px, py, tw, 19.0)
			canvas.draw_rect(Rect2(box.position + Vector2(1, 2), box.size), Color(0.04, 0.03, 0.02, 0.55))
			canvas.draw_rect(box, Color(0.18, 0.13, 0.08, 0.90))
			canvas.draw_rect(box, Color(0.76, 0.60, 0.30, 0.85) if unlocked else Color(0.76, 0.34, 0.26, 0.85), false, 1.2)
			canvas.draw_string(font, Vector2(px + 7.0, py + 13.0), show_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.96, 0.88, 0.64) if unlocked else Color(0.98, 0.72, 0.62))


func step_walk_portals(delta: float) -> void:
	if _portal_hint_layer != null and player != null:
		var near_any := false
		for wp: Dictionary in walk_portals:
			if player.position.distance_to(wp["rect"].get_center()) <= 125.0:
				near_any = true
				break
		if near_any or _portal_hint_was_near:
			_portal_hint_layer.queue_redraw()
		_portal_hint_was_near = near_any
	if portal_cooldown > 0.0:
		portal_cooldown = maxf(0.0, portal_cooldown - delta)
		return
	if player == null or not player.visible or ui == null or ui.is_blocking_gameplay():
		return
	var ppos: Vector2 = player.position
	var pvel: Vector2 = player.velocity
	for wp: Dictionary in walk_portals:
		var pid: String = str(wp.get("id", ""))
		if pid != "" and not is_interactable_active(pid):
			continue
		var r: Rect2 = wp["rect"]
		if not r.has_point(ppos):
			continue
		var dhint: Vector2 = wp.get("dir", Vector2.ZERO)
		if dhint.length_squared() > 0.01 and pvel.length_squared() > 4.0 and pvel.normalized().dot(dhint.normalized()) < -0.15:
			continue
		var cb: Callable = wp["callback"]
		if cb.is_valid():
			var dir_ref := director
			var ui_ref := ui
			var old_rid: String = dir_ref.current_region_id if dir_ref != null else ""
			var b_title := str(wp.get("banner_title", ""))
			var b_sub := str(wp.get("banner_sub", ""))
			portal_cooldown = 0.90
			cb.call()
			if dir_ref != null and dir_ref.current_region_id != old_rid and ui_ref != null and ui_ref.has_method("play_border_transition") and b_title != "":
				ui_ref.play_border_transition(b_title, b_sub)
			return


func get_interact_bubble_offset(_id: String) -> Vector2:
	return Vector2(0, -44)


## Draws the `[E]` prompt above the nearest active interactable onto the given canvas.
func draw_interact_bubble_if_active_on(canvas: Node2D, font: Font) -> void:
	if ui.is_blocking_gameplay() or nearest_interactable.is_empty():
		return
	var nid := str(nearest_interactable.get("id", ""))
	var off := get_interact_bubble_offset(nid)
	assets.draw_interact_bubble(canvas, nearest_interactable["pos"] + off, "[E] " + str(nearest_interactable["name"]), font)


func draw_interact_bubble_if_active(font: Font) -> void:
	draw_interact_bubble_if_active_on(self, font)


## Returns the live camera world rectangle expanded by pad pixels for frustum culling.
func get_camera_rect(pad: float = 160.0) -> Rect2:
	var vp_size := Vector2(1280.0, 720.0)
	var center := Vector2(vp_size * 0.5)
	if player != null:
		center = player.position
	var zoom := Vector2(1.5, 1.5)
	if director != null and director.get("camera") != null:
		var cam: Camera2D = director.camera
		if cam.zoom.x > 0.01:
			zoom = cam.zoom
		center = cam.get_screen_center_position() if cam.is_inside_tree() else cam.position
	var vp: Viewport = get_viewport()
	if vp != null:
		var vr := vp.get_visible_rect().size
		if vr.x > 0.0 and vr.y > 0.0:
			vp_size = vr
	var half := (vp_size / zoom) * 0.5 + Vector2(pad, pad)
	return Rect2(center - half, half * 2.0)


## Bakes static world ground/geometry once into a nearest-neighbor SubViewport sliced
## into chunk_size x chunk_size Sprite2Ds for per-chunk GPU and PointLight2D culling.
func setup_static_ground_chunks(bounds: Rect2, draw_cb: Callable = Callable(), chunk_size: int = 720, z_ord: int = -3, transparent_bg: bool = false, node_prefix: String = "StaticGround", custom_drawer: Node2D = null) -> SubViewport:
	var sv_name := node_prefix + "SV"
	var existing := get_node_or_null(sv_name) as SubViewport
	if existing != null:
		return existing

	var w := int(ceilf(maxf(1.0, bounds.size.x)))
	var h := int(ceilf(maxf(1.0, bounds.size.y)))
	var sv := SubViewport.new()
	sv.name = sv_name
	sv.size = Vector2i(w, h)
	sv.transparent_bg = transparent_bg
	sv.disable_3d = true
	sv.gui_disable_input = true
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE

	var drawer: Node2D = custom_drawer
	if drawer == null:
		var sc := StaticGroundCanvas.new()
		sc.draw_cb = draw_cb
		drawer = sc
	drawer.name = node_prefix + "Drawer"
	drawer.position = -bounds.position
	drawer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	drawer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sv.add_child(drawer)
	add_child(sv)

	var chunks_root := Node2D.new()
	chunks_root.name = node_prefix + "Chunks"
	chunks_root.z_index = z_ord
	chunks_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(chunks_root)

	var sv_tex := sv.get_texture()
	var cols := int(ceilf(float(w) / float(chunk_size)))
	var rows := int(ceilf(float(h) / float(chunk_size)))
	for cy in range(rows):
		for cx in range(cols):
			var cw := mini(chunk_size, w - cx * chunk_size)
			var ch := mini(chunk_size, h - cy * chunk_size)
			var sp := Sprite2D.new()
			sp.centered = false
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.texture = sv_tex
			sp.region_enabled = true
			sp.region_rect = Rect2(cx * chunk_size, cy * chunk_size, cw, ch)
			sp.position = bounds.position + Vector2(float(cx * chunk_size), float(cy * chunk_size))
			chunks_root.add_child(sp)
	return sv


## Re-triggers a one-shot bake on an existing static ground SubViewport (e.g. phase transitions).
func rebake_static_ground_chunks(node_prefix: String = "StaticGround") -> void:
	var sv := get_node_or_null(node_prefix + "SV") as SubViewport
	if sv == null:
		return
	var drawer := sv.get_node_or_null(node_prefix + "Drawer") as CanvasItem
	if drawer != null:
		drawer.queue_redraw()
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE


## Creates or fetches a batched animated-water backdrop layer for static water channels.
func setup_water_layer(rects: Array, tile_px: float = 32.0, z_ord: int = -3, node_name: String = "EnvWaterLayer") -> WaterBackdropLayer:
	var existing := get_node_or_null(node_name) as WaterBackdropLayer
	if existing != null:
		return existing
	var wl := WaterBackdropLayer.new()
	wl.name = node_name
	wl.assets = assets
	wl.water_rects.assign(rects)
	wl.tile_px = tile_px
	wl.z_index = z_ord
	wl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wl.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(wl)
	return wl


## Updates water layer visibility against the current camera frustum and queues redraw only when visible.
func step_water_layer(node_name: String = "EnvWaterLayer", pad: float = 120.0) -> void:
	var wl := get_node_or_null(node_name) as WaterBackdropLayer
	if wl == null:
		return
	var cam := get_camera_rect(pad)
	wl.cam_rect = cam
	var any_vis := false
	for wr: Rect2 in wl.water_rects:
		if cam.intersects(wr):
			any_vis = true
			break
	wl.visible = any_vis
	if any_vis:
		wl.queue_redraw()


## Culls off-screen or disabled PointLight2Ds using each light's actual radius (texture_scale * 64px).
func sync_light_frustum(light_list: Array[PointLight2D], enabled: bool = true, extra_pad: float = 24.0) -> void:
	if not enabled:
		for pl: PointLight2D in light_list:
			pl.visible = false
		return
	var cam := get_camera_rect(0.0)
	for pl: PointLight2D in light_list:
		var rad := pl.texture_scale * 64.0 + extra_pad
		pl.visible = cam.grow(rad).has_point(pl.position)


## Builds an AStarGrid2D obstacle map once from static Rect2 colliders for obstacle-aware actor pathing.
func setup_navigation_grid(bounds: Rect2, colliders_list: Array[Rect2], agent_radius: float = 10.0, cell_px: float = 20.0) -> void:
	_nav.setup_navigation_grid(bounds, colliders_list, agent_radius, cell_px)


## Returns true if a padded straight corridor between from_pos and to_pos avoids all solid colliders.
func has_clear_line(from_pos: Vector2, to_pos: Vector2, colliders_list: Array[Rect2], inflate: float = 9.0) -> bool:
	return _nav.has_clear_line(from_pos, to_pos, colliders_list, inflate)


## Computes an obstacle-avoiding normalized move direction from from_pos to target_pos via LOS + AStarGrid2D.
func compute_nav_move_dir(from_pos: Vector2, target_pos: Vector2, colliders_list: Array[Rect2], agent_radius: float = 10.0) -> Vector2:
	return _nav.compute_nav_move_dir(from_pos, target_pos, colliders_list, agent_radius)


## Returns true when a circular actor footprint overlaps any static collider Rect2.
func point_hits_colliders(pt: Vector2, colliders_list: Array[Rect2], radius: float = 10.0) -> bool:
	return _nav.point_hits_colliders(pt, colliders_list, radius)


## Moves an actor cleanly around corners and peers using axis sliding + angular whisker steering.
func steer_and_move_actor(pos: Vector2, desired_dir: Vector2, speed: float, delta: float, colliders_list: Array[Rect2], radius: float = 10.0, peers: Array = [], self_ref: Variant = null) -> Vector2:
	return _nav.steer_and_move_actor(pos, desired_dir, speed, delta, colliders_list, radius, peers, self_ref)


func cast_vision_ray(origin: Vector2, dir: Vector2, max_dist: float, blockers: Array[Rect2]) -> Vector2:
	return _nav.cast_vision_ray(origin, dir, max_dist, blockers)


func can_vision_cone_see(eye_o: Vector2, look_dir: Vector2, target_o: Vector2, max_dist: float, half_fov: float, blockers: Array[Rect2], close_radius: float = 24.0) -> bool:
	return _nav.can_vision_cone_see(eye_o, look_dir, target_o, max_dist, half_fov, blockers, close_radius)


func draw_raycast_vision_cone(canvas: Node2D, eye_o: Vector2, look_dir: Vector2, max_dist: float, half_fov: float, blockers: Array[Rect2], fill_col: Color, line_col: Color, steps: int = 28) -> void:
	_nav.draw_raycast_vision_cone(canvas, eye_o, look_dir, max_dist, half_fov, blockers, fill_col, line_col, steps)
