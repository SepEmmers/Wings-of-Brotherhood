class_name WorldRealmChartDraw
extends RefCounted

const RealmData := preload("res://scripts/data/WorldRealmChartData.gd")

## Renders the interactive Kingdom of Flanders, Brabant & Meuse Realm Chart
## onto ForestMapCanvas (View Mode 2 inside [M]).


static func _chart_rect(w: float, h: float) -> Rect2:
	return Rect2(20.0, 18.0, w - 40.0, h - 36.0)


static func _to_canvas(norm: Vector2, rect: Rect2) -> Vector2:
	return rect.position + Vector2(norm.x * rect.size.x, norm.y * rect.size.y)


static func hit_test_node(local_pos: Vector2, w: float, h: float) -> Dictionary:
	var rect := _chart_rect(w, h)
	var best: Dictionary = {}
	var best_d := 22.0
	for n in RealmData.REALM_NODES:
		var pt := _to_canvas(n["pos"], rect)
		var d := local_pos.distance_to(pt)
		if d < best_d:
			best_d = d
			best = n
	return best


static func draw_realm_chart(canvas, font: Font, w: float, h: float, active_region_id: String, hovered_node_id: String, selected_node_id: String) -> void:
	var rect := _chart_rect(w, h)
	var assets = canvas.assets

	# 1. North Sea northwest wash & Kingdom parchment domain silhouette
	var sea_pts := PackedVector2Array()
	for p in RealmData.COASTLINE_POLY:
		sea_pts.append(_to_canvas(p, rect))
	if sea_pts.size() >= 3:
		canvas.draw_colored_polygon(sea_pts, Color(0.24, 0.42, 0.56, 0.32))
		canvas.draw_polyline(sea_pts, Color(0.16, 0.30, 0.42, 0.72), 2.0, true)
	canvas._draw_ink_text(font, _to_canvas(Vector2(0.035, 0.13), rect), "NORTH SEA", 11, Color(0.16, 0.30, 0.44))

	var border_pts := PackedVector2Array()
	for bp in RealmData.REALM_BORDER_POLY:
		border_pts.append(_to_canvas(bp, rect))
	if border_pts.size() >= 2:
		canvas._draw_dashed_curve(border_pts, Color(0.38, 0.28, 0.18, 0.46), 1.6, 8.0, 5.0)

	# Faint province titles across Flanders -> Brabant -> Meuse
	for pl in RealmData.PROVINCE_LABELS:
		canvas._draw_ink_text(font, _to_canvas(pl["pos"], rect), str(pl["text"]), int(pl["size"]), Color(0.32, 0.24, 0.16, 0.42))

	# 2. Uncharted eastern mist stipple behind undiscovered Book II nodes
	for n in RealmData.REALM_NODES:
		if not RealmData.is_node_discovered(n):
			var c_pt := _to_canvas(n["pos"], rect)
			canvas.draw_circle(c_pt, 30.0, Color(0.56, 0.48, 0.36, 0.20))

	# 3. Hand-inked Rivers (Zwin, Scheldt, Dijle, Sambre-Meuse)
	for rv in RealmData.RIVERS:
		var r_pts := PackedVector2Array()
		for rp in rv["pts"]:
			r_pts.append(_to_canvas(rp, rect))
		canvas.draw_polyline(r_pts, Color(0.20, 0.42, 0.60, 0.68), float(rv["width"]), true)
		canvas._draw_ink_text(font, _to_canvas(rv["label_pos"], rect), str(rv["name"]), 9, Color(0.16, 0.34, 0.50, 0.80))

	# 4. Overland Roads & Aerial Routes
	for rt in RealmData.REALM_ROUTES:
		var n_a := RealmData.get_node_by_id(str(rt["from"]))
		var n_b := RealmData.get_node_by_id(str(rt["to"]))
		if n_a.is_empty() or n_b.is_empty():
			continue
		var pa := _to_canvas(n_a["pos"], rect)
		var pb := _to_canvas(n_b["pos"], rect)
		var kind := str(rt["kind"])
		var status := RealmData.get_route_status(rt)
		if kind == "road":
			var road_pts := PackedVector2Array([pa, pb])
			if status == "charted":
				canvas.draw_polyline(road_pts, Color(0.76, 0.66, 0.46, 0.70), 5.0, true)
				canvas.draw_polyline(road_pts, Color(0.30, 0.19, 0.10, 0.92), 2.0, true)
			elif status == "rumored":
				canvas._draw_dashed_curve(road_pts, Color(0.36, 0.25, 0.14, 0.55), 1.8, 5.0, 5.0)
			else:
				canvas._draw_dashed_curve(road_pts, Color(0.42, 0.34, 0.24, 0.25), 1.2, 3.0, 6.0)
		elif kind == "virelai" and status != "uncharted":
			var mid := _to_canvas(rt["arc"], rect)
			var pts := _sample_quad_curve(pa, mid, pb, 14)
			canvas._draw_dashed_curve(pts, Color(0.14, 0.44, 0.38, 0.78 if status == "charted" else 0.38), 1.8, 6.0, 4.0)
		elif kind == "kestrel":
			var kestrel_pair := RealmData.get_kestrel_curve_nodes()
			var k_active: bool = kestrel_pair.size() == 2 and (
				(str(rt["from"]) == kestrel_pair[0] and str(rt["to"]) == kestrel_pair[1])
				or (str(rt["to"]) == kestrel_pair[0] and str(rt["from"]) == kestrel_pair[1])
			)
			if k_active or status == "charted":
				var mid_k := _to_canvas(rt["arc"], rect)
				var pts_k := _sample_quad_curve(pa, mid_k, pb, 14)
				var col_k := Color(0.56, 0.66, 0.80, 0.92) if k_active else Color(0.38, 0.46, 0.56, 0.35)
				canvas._draw_dashed_curve(pts_k, col_k, 2.2 if k_active else 1.3, 4.0, 4.0)

	# 5. Province Seal Nodes
	var active_node_id := RealmData.node_id_for_region(active_region_id)
	var anna_node_id := RealmData.get_anna_anchor_node_id()
	var t_elapsed := float(assets.time_elapsed) if assets != null else 0.0
	var pulse := 0.5 + 0.5 * sin(t_elapsed * 4.5)
	var pine_stamp: Texture2D = assets.get_tex("map_stamp_pines.png") if assets != null else null

	for n in RealmData.REALM_NODES:
		var nid: String = str(n["id"])
		var pt := _to_canvas(n["pos"], rect)
		var known := RealmData.is_node_discovered(n)
		var is_cur := nid == active_node_id
		var is_sel := nid == selected_node_id or nid == hovered_node_id
		var kind := str(n["kind"])

		if kind == "wilds" and pine_stamp != null and known:
			canvas.draw_texture_rect(pine_stamp, Rect2(pt + Vector2(-22, -22), Vector2(20, 16)), false, Color(0.86, 0.82, 0.72, 0.82))

		var fill := Color(0.68, 0.58, 0.40, 0.48) if not known else _node_fill_color(kind)
		var rim := Color(0.38, 0.30, 0.22, 0.55) if not known else Color(0.18, 0.12, 0.08, 0.95)
		var r_sz := 8.5 if known else 6.0
		if is_sel:
			canvas.draw_arc(pt, r_sz + 5.5, 0.0, TAU, 24, Color(0.95, 0.78, 0.28, 0.95), 2.2)

		canvas.draw_circle(pt + Vector2(1.5, 1.5), r_sz, Color(0.12, 0.08, 0.05, 0.35))
		canvas.draw_circle(pt, r_sz, fill)
		canvas.draw_arc(pt, r_sz, 0.0, TAU, 20, rim, 1.8)
		if known and kind in ["city", "sanctuary", "citadel", "shrine"]:
			canvas.draw_circle(pt, 3.0, Color(0.96, 0.88, 0.64) if kind != "citadel" else Color(0.92, 0.34, 0.26))

		# Node label with compact readability halo
		var label_txt: String = str(n["name"]) if known else "Uncharted"
		var l_col: Color = Color(0.18, 0.12, 0.08) if known else Color(0.38, 0.32, 0.26, 0.70)
		if kind == "citadel" and known:
			l_col = Color(0.56, 0.10, 0.10)
		var l_offset := Vector2(-26.0, 18.0)
		if nid == "bruges_port":
			l_offset = Vector2(-58.0, 17.0)
		elif nid == "bruges_city":
			l_offset = Vector2(-52.0, -14.0)
		elif nid == "bruges_sanctuary":
			l_offset = Vector2(-26.0, -14.0)
		elif nid == "louvain":
			l_offset = Vector2(-18.0, -14.0)
		elif nid == "blood_citadel":
			l_offset = Vector2(-64.0, -14.0)
		canvas._draw_ink_text(font, pt + l_offset, label_txt, 9 if not known else 10, l_col)

		# Live Active Character Pin (Boy/Hatchling or Anna in Sortie)
		if is_cur:
			var is_anna := GameState.active_perspective == "anna" or active_region_id == "flight"
			var badge_txt := "ANNA & VIRELAI" if is_anna else ("BOY & GOLD" if GameState.active_companion_stage >= 1 else "YOU")
			var badge_col := Color(0.14, 0.42, 0.34) if is_anna else Color(0.74, 0.18, 0.14)
			var glow_col := Color(0.28, 0.76, 0.56, 0.32) if is_anna else Color(0.96, 0.72, 0.22, 0.34)
			canvas.draw_circle(pt, 12.0 + pulse * 4.0, glow_col)
			canvas.draw_arc(pt, 12.0 + pulse * 4.0, 0.0, TAU, 22, badge_col, 1.8)
			canvas._draw_ink_badge(font, pt + Vector2(0, -18), badge_txt, badge_col, Color(0.18, 0.10, 0.06), Color(0.98, 0.94, 0.84))
		elif GameState.book2_started and nid == anna_node_id and GameState.active_perspective != "anna":
			canvas._draw_ink_badge(font, pt + Vector2(0, -17), "ANNA", Color(0.18, 0.42, 0.34), Color(0.10, 0.24, 0.18), Color(0.92, 0.98, 0.92))

	# 6. Bottom-Left & Bottom-Right Cartographer Legend & Charter Key (clear of emblem at x=18..58)
	var leg_x := rect.position.x + 56.0
	var leg_y := rect.end.y - 34.0
	canvas._draw_ink_text(font, Vector2(leg_x, leg_y), "Solid Ink: Overland Roads   |   Teal Dashed: Virelai Air Wing", 10, Color(0.24, 0.16, 0.10))
	canvas._draw_ink_text(font, Vector2(leg_x, leg_y + 15.0), "Silver Dotted: Kestrel Courier   |   Hover / Click any Seal to Inspect", 10, Color(0.26, 0.22, 0.18))


static func _node_fill_color(kind: String) -> Color:
	match kind:
		"port": return Color(0.68, 0.54, 0.34)
		"city": return Color(0.76, 0.62, 0.38)
		"sanctuary": return Color(0.24, 0.54, 0.38)
		"wilds": return Color(0.32, 0.48, 0.30)
		"camp": return Color(0.84, 0.54, 0.22)
		"shrine": return Color(0.88, 0.72, 0.26)
		"citadel": return Color(0.62, 0.16, 0.16)
		_: return Color(0.72, 0.60, 0.40)


static func _sample_quad_curve(a: Vector2, ctrl: Vector2, b: Vector2, steps: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var omt := 1.0 - t
		out.append(a * (omt * omt) + ctrl * (2.0 * omt * t) + b * (t * t))
	return out
