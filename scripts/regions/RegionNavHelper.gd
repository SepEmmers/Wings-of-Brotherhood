class_name RegionNavHelper
extends RefCounted

## Obstacle-aware AStarGrid2D pathfinding, circular collider sliding, and
## raycast vision-cone helpers extracted from RegionBase.gd.

var nav_grid: AStarGrid2D = null
var nav_bounds: Rect2 = Rect2()
var nav_cell_size: float = 20.0


## Builds an AStarGrid2D obstacle map once from static Rect2 colliders for obstacle-aware actor pathing.
func setup_navigation_grid(bounds: Rect2, colliders_list: Array[Rect2], agent_radius: float = 10.0, cell_px: float = 20.0) -> void:
	nav_bounds = bounds
	nav_cell_size = maxf(8.0, cell_px)
	var cols: int = maxi(1, int(ceilf(bounds.size.x / nav_cell_size)))
	var rows: int = maxi(1, int(ceilf(bounds.size.y / nav_cell_size)))
	nav_grid = AStarGrid2D.new()
	nav_grid.region = Rect2i(0, 0, cols, rows)
	nav_grid.cell_size = Vector2(nav_cell_size, nav_cell_size)
	nav_grid.offset = bounds.position + Vector2(nav_cell_size * 0.5, nav_cell_size * 0.5)
	nav_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	nav_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	nav_grid.update()

	var pad: float = agent_radius * 0.75
	for cr: Rect2 in colliders_list:
		var exp_r: Rect2 = cr.grow(pad)
		var x0: int = clampi(int(floorf((exp_r.position.x - bounds.position.x) / nav_cell_size)), 0, cols - 1)
		var x1: int = clampi(int(floorf((exp_r.end.x - bounds.position.x) / nav_cell_size)), 0, cols - 1)
		var y0: int = clampi(int(floorf((exp_r.position.y - bounds.position.y) / nav_cell_size)), 0, rows - 1)
		var y1: int = clampi(int(floorf((exp_r.end.y - bounds.position.y) / nav_cell_size)), 0, rows - 1)
		for cy in range(y0, y1 + 1):
			for cx in range(x0, x1 + 1):
				var center: Vector2 = bounds.position + Vector2((float(cx) + 0.5) * nav_cell_size, (float(cy) + 0.5) * nav_cell_size)
				if exp_r.has_point(center):
					nav_grid.set_point_solid(Vector2i(cx, cy), true)


static func _segment_intersects_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b):
		return true
	var d: Vector2 = b - a
	var t0: float = 0.0
	var t1: float = 1.0
	for i in range(4):
		var p := 0.0
		var q := 0.0
		match i:
			0:
				p = -d.x
				q = a.x - r.position.x
			1:
				p = d.x
				q = r.end.x - a.x
			2:
				p = -d.y
				q = a.y - r.position.y
			3:
				p = d.y
				q = r.end.y - a.y
		if absf(p) < 0.0001:
			if q < 0.0:
				return false
		else:
			var t := q / p
			if p < 0.0:
				if t > t1:
					return false
				if t > t0:
					t0 = t
			else:
				if t < t0:
					return false
				if t < t1:
					t1 = t
	return t0 <= t1


## Returns true if a padded straight corridor between from_pos and to_pos avoids all solid colliders.
func has_clear_line(from_pos: Vector2, to_pos: Vector2, colliders_list: Array[Rect2], inflate: float = 9.0) -> bool:
	var seg_rect := Rect2(
		Vector2(minf(from_pos.x, to_pos.x), minf(from_pos.y, to_pos.y)),
		Vector2(absf(to_pos.x - from_pos.x), absf(to_pos.y - from_pos.y))
	).grow(inflate)
	for cr: Rect2 in colliders_list:
		if seg_rect.intersects(cr) and _segment_intersects_rect(from_pos, to_pos, cr.grow(inflate)):
			return false
	return true


func _find_nearest_walkable_cell(world_pos: Vector2) -> Vector2i:
	if nav_grid == null:
		return Vector2i.ZERO
	var reg := nav_grid.region
	var base := Vector2i(
		clampi(int(floorf((world_pos.x - nav_bounds.position.x) / nav_cell_size)), 0, reg.size.x - 1),
		clampi(int(floorf((world_pos.y - nav_bounds.position.y) / nav_cell_size)), 0, reg.size.y - 1)
	)
	if not nav_grid.is_point_solid(base):
		return base
	for rad in range(1, 6):
		var best_c := base
		var best_d := INF
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				if maxi(absi(dx), absi(dy)) != rad:
					continue
				var c := base + Vector2i(dx, dy)
				if reg.has_point(c) and not nav_grid.is_point_solid(c):
					var cpos := nav_bounds.position + Vector2((float(c.x) + 0.5) * nav_cell_size, (float(c.y) + 0.5) * nav_cell_size)
					var d := world_pos.distance_squared_to(cpos)
					if d < best_d:
						best_d = d
						best_c = c
		if best_d < INF:
			return best_c
	return base


## Computes an obstacle-avoiding normalized move direction from from_pos to target_pos via LOS + AStarGrid2D.
func compute_nav_move_dir(from_pos: Vector2, target_pos: Vector2, colliders_list: Array[Rect2], agent_radius: float = 10.0) -> Vector2:
	var direct: Vector2 = target_pos - from_pos
	var dlen: float = direct.length()
	if dlen <= 1.0:
		return Vector2.DOWN
	var nd: Vector2 = direct / dlen
	if dlen < 22.0 or has_clear_line(from_pos, target_pos, colliders_list, agent_radius):
		return nd
	if nav_grid == null:
		return nd
	var start_cell := _find_nearest_walkable_cell(from_pos)
	var goal_cell := _find_nearest_walkable_cell(target_pos)
	var path: PackedVector2Array = nav_grid.get_point_path(start_cell, goal_cell, true)
	if path.size() >= 2:
		var chosen: Vector2 = path[1]
		var max_look := mini(path.size() - 1, 7)
		for i in range(max_look, 0, -1):
			if from_pos.distance_to(path[i]) > 10.0 and has_clear_line(from_pos, path[i], colliders_list, agent_radius * 0.85):
				chosen = path[i]
				break
		if from_pos.distance_to(chosen) <= 8.0 and path.size() >= 3:
			chosen = path[2]
		var to_wp := chosen - from_pos
		if to_wp.length_squared() > 1.0:
			return to_wp.normalized()
	return nd


## Returns true when a circular actor footprint overlaps any static collider Rect2.
func point_hits_colliders(pt: Vector2, colliders_list: Array[Rect2], radius: float = 10.0) -> bool:
	var r_sq: float = radius * radius
	for cr: Rect2 in colliders_list:
		var cx: float = clampf(pt.x, cr.position.x, cr.end.x)
		var cy: float = clampf(pt.y, cr.position.y, cr.end.y)
		if pt.distance_squared_to(Vector2(cx, cy)) < r_sq:
			return true
	return false


## Moves an actor cleanly around corners and peers using axis sliding + angular whisker steering.
func steer_and_move_actor(pos: Vector2, desired_dir: Vector2, speed: float, delta: float, colliders_list: Array[Rect2], radius: float = 10.0, peers: Array = [], self_ref: Variant = null) -> Vector2:
	if desired_dir.length_squared() < 0.001:
		return pos
	var base_dir := desired_dir.normalized()
	var sep := Vector2.ZERO
	for peer in peers:
		if peer == self_ref or not (peer is Dictionary):
			continue
		if int(peer.get("hp", 1)) <= 0:
			continue
		var diff: Vector2 = pos - Vector2(peer["pos"])
		var pd: float = diff.length()
		if pd > 0.1 and pd < 30.0:
			sep += (diff / pd) * ((30.0 - pd) / 30.0) * 0.65
	var steer_dir: Vector2 = (base_dir + sep).normalized() if sep.length_squared() > 0.01 else base_dir
	var step: float = speed * delta
	var direct_pt := pos + steer_dir * step
	if not point_hits_colliders(direct_pt, colliders_list, radius):
		return direct_pt

	# Fallback angles & cardinal axis slides so actors glide smoothly past obstacle corners.
	var candidates: Array[Vector2] = []
	for deg_off in [28.0, -28.0, 56.0, -56.0, 84.0, -84.0, 112.0, -112.0]:
		candidates.append(base_dir.rotated(deg_to_rad(deg_off)))
	if absf(base_dir.x) > 0.15:
		candidates.append(Vector2(signf(base_dir.x), 0.0))
	if absf(base_dir.y) > 0.15:
		candidates.append(Vector2(0.0, signf(base_dir.y)))

	var best_pt := pos
	var best_score := -INF
	for cand in candidates:
		var cpt := pos + cand * step
		if not point_hits_colliders(cpt, colliders_list, radius):
			var sc := cand.dot(base_dir)
			if sc > best_score:
				best_score = sc
				best_pt = cpt
	return best_pt


func cast_vision_ray(origin: Vector2, dir: Vector2, max_dist: float, blockers: Array[Rect2]) -> Vector2:
	if max_dist <= 0.0 or dir.length_squared() < 0.0001:
		return origin
	var nd: Vector2 = dir.normalized()
	var best_t: float = max_dist
	for r: Rect2 in blockers:
		var tmin: float = 0.0
		var tmax: float = best_t
		if absf(nd.x) < 0.00001:
			if origin.x < r.position.x or origin.x > r.end.x:
				continue
		else:
			var inv_x: float = 1.0 / nd.x
			var tx1: float = (r.position.x - origin.x) * inv_x
			var tx2: float = (r.end.x - origin.x) * inv_x
			tmin = maxf(tmin, minf(tx1, tx2))
			tmax = minf(tmax, maxf(tx1, tx2))
		if absf(nd.y) < 0.00001:
			if origin.y < r.position.y or origin.y > r.end.y:
				continue
		else:
			var inv_y: float = 1.0 / nd.y
			var ty1: float = (r.position.y - origin.y) * inv_y
			var ty2: float = (r.end.y - origin.y) * inv_y
			tmin = maxf(tmin, minf(ty1, ty2))
			tmax = minf(tmax, maxf(ty1, ty2))
		if tmax >= tmin and tmin >= 0.0 and tmin < best_t:
			best_t = tmin
	return origin + nd * best_t


func can_vision_cone_see(eye_o: Vector2, look_dir: Vector2, target_o: Vector2, max_dist: float, half_fov: float, blockers: Array[Rect2], close_radius: float = 24.0) -> bool:
	var to_t: Vector2 = target_o - eye_o
	var dist: float = to_t.length()
	if dist > max_dist or dist < 0.5:
		return false
	var ray_d: Vector2 = to_t / dist
	if dist > close_radius and absf(look_dir.angle_to(ray_d)) > half_fov:
		return false
	var hit_pt: Vector2 = cast_vision_ray(eye_o, ray_d, dist, blockers)
	return hit_pt.distance_to(eye_o) >= dist - 8.0


func draw_raycast_vision_cone(canvas: Node2D, eye_o: Vector2, look_dir: Vector2, max_dist: float, half_fov: float, blockers: Array[Rect2], fill_col: Color, line_col: Color, steps: int = 28) -> void:
	var ang0: float = look_dir.angle()
	var hit_pts := PackedVector2Array()
	for i in range(steps + 1):
		var a: float = ang0 - half_fov + (2.0 * half_fov * float(i) / float(steps))
		hit_pts.append(cast_vision_ray(eye_o, Vector2(cos(a), sin(a)), max_dist, blockers))
	for i in range(steps):
		canvas.draw_colored_polygon(PackedVector2Array([eye_o, hit_pts[i], hit_pts[i + 1]]), fill_col)
	if line_col.a > 0.01:
		var outline := PackedVector2Array([eye_o])
		outline.append_array(hit_pts)
		outline.append(eye_o)
		canvas.draw_polyline(outline, line_col, 1.4)
