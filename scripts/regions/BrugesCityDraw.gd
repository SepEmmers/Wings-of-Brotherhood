extends RefCounted

## Rendering layer for Bruges City: paved medieval cobblestone & enclosed
## gardens, ashlar plazas, Reien canals, procedural battlements & gatehouses,
## moored canal barges, Grote Markt fountain, animated chimney smoke, and
## Y-sorted foreground walk-behind overlap.

const BrugesCityMapDataScript := preload("res://scripts/regions/BrugesCityMapData.gd")
const BrugesCityBoatsScript := preload("res://scripts/regions/BrugesCityBoats.gd")


static func setup_layers(r) -> void:
	r.setup_static_ground_chunks(
		Rect2(0, 0, BrugesCityMapDataScript.WORLD_SIZE.x, BrugesCityMapDataScript.WORLD_SIZE.y),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-3,
		false
	)
	r.setup_water_layer(BrugesCityMapDataScript.get_canal_rects(), 32.0, -2)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	var lawns: Array[Rect2] = BrugesCityMapDataScript.get_garden_lawns()
	var plazas: Array[Dictionary] = BrugesCityMapDataScript.get_plaza_placements()
	var roads: Array[Rect2] = BrugesCityMapDataScript.get_road_network()
	var canals: Array[Rect2] = BrugesCityMapDataScript.get_canal_rects()

	# 1. Outer glacis turf surrounding the moat ring
	var interior := Rect2(96, 84, 2688, 1944)
	assets.draw_grass_zone(canvas, Rect2(0, 0, 2880, 2160), false, 17, [interior.grow(16.0)])

	var cobble_a: Texture2D = assets.get_tex("tile_cobble.png")
	var cobble_b: Texture2D = assets.get_tex("tile_cobble_2.png")
	var slate_tex: Texture2D = assets.get_tex("tile_frost_slate.png")
	var wharf_tex: Texture2D = assets.get_tex("tile_wharf.png")

	# 2. Paved Medieval Cobblestone City Interior (grass only inside enclosed gardens)
	canvas.draw_rect(interior.grow(6.0), Color(0.18, 0.17, 0.19))
	assets.draw_varied_tiled_rect(canvas, interior, cobble_a, cobble_b, 32.0, 5, slate_tex)
	canvas.draw_rect(interior, Color(0.08, 0.07, 0.10, 0.10))

	# 3. Enclosed Garden Lawns (Beguinage Herb Lawn & North Cloister Garth)
	for idx in range(lawns.size()):
		var lawn: Rect2 = lawns[idx]
		canvas.draw_rect(lawn.grow(4.0), Color(0.24, 0.22, 0.21))
		assets.draw_grass_zone(canvas, lawn, true, 31 + idx * 7, [])

	# 4. Main Cobblestone Avenues & Streets
	for rd in roads:
		canvas.draw_rect(rd.grow(3.0), Color(0.16, 0.15, 0.17))
		assets.draw_varied_tiled_rect(canvas, rd, cobble_a, cobble_b, 32.0, 9)
		canvas.draw_rect(rd, Color(0.58, 0.52, 0.42, 0.40), false, 1.5)

	# 5. Distinct Plazas (Flagstone Castle Bailey, Quay Wharf, Cobble Squares)
	for pl in plazas:
		var pr: Rect2 = pl["rect"]
		var style: String = String(pl.get("style", "cobble"))
		canvas.draw_rect(pr.grow(5.0), Color(0.20, 0.19, 0.20))
		if style == "flagstone":
			assets.draw_varied_tiled_rect(canvas, pr, slate_tex if slate_tex != null else cobble_b, cobble_a, 32.0, 11)
			canvas.draw_rect(pr, Color(0.54, 0.52, 0.48, 0.62), false, 2.0)
			var fx: float = pr.position.x + 64.0
			while fx < pr.end.x - 16.0:
				canvas.draw_line(Vector2(fx, pr.position.y + 4.0), Vector2(fx, pr.end.y - 4.0), Color(0.18, 0.17, 0.19, 0.22), 1.0)
				fx += 64.0
		elif style == "quay":
			assets.draw_varied_tiled_rect(canvas, pr, cobble_a, cobble_b, 32.0, 15, slate_tex)
			var apron := Rect2(pr.end.x - 42.0, pr.position.y, 42.0, pr.size.y)
			if wharf_tex != null:
				assets.draw_tiled_rect(canvas, apron, wharf_tex, 32.0)
			assets.draw_wharf_curb_seam(canvas, pr.end.x - 42.0, pr.position.y, pr.end.y)
			canvas.draw_rect(pr, Color(0.50, 0.45, 0.36, 0.58), false, 2.0)
		else:
			assets.draw_varied_tiled_rect(canvas, pr, cobble_b if cobble_b != null else cobble_a, cobble_a, 32.0, 13, slate_tex)
			canvas.draw_rect(pr, Color(0.60, 0.54, 0.42, 0.68), false, 2.0)

	# 6. Embankment Stone Coping around Moat Ring & Reien Canals (sits around z=-2 water)
	for c in canals:
		canvas.draw_rect(c.grow(8.0), Color(0.25, 0.24, 0.26))
		canvas.draw_rect(c.grow(4.0), Color(0.39, 0.37, 0.39))

	# 7. Grote Markt Fountain Dry Stone Apron
	var fpos: Vector2 = BrugesCityMapDataScript.FOUNTAIN_POS
	canvas.draw_circle(fpos + Vector2(0, 3), 48.0, Color(0.18, 0.17, 0.19, 0.65))
	canvas.draw_circle(fpos, 44.0, Color(0.42, 0.40, 0.38))
	canvas.draw_arc(fpos, 44.0, 0.0, TAU, 32, Color(0.24, 0.22, 0.22), 2.0)


static func _draw_wooden_sign(canvas: Node2D, center_pos: Vector2, text: String, font: Font) -> void:
	var a = canvas.get("assets") if canvas != null else null
	var use_font: Font = a.get_ui_font() if a != null else font
	var tw: float = use_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var pad_w: float = maxf(66.0, tw + 16.0)
	var plaque := Rect2(center_pos.x - pad_w * 0.5, center_pos.y - 11.0, pad_w, 16.0)
	canvas.draw_rect(Rect2(plaque.position + Vector2(1, 2), plaque.size), Color(0.03, 0.03, 0.05, 0.50))
	canvas.draw_rect(plaque, Color(0.20, 0.13, 0.08, 0.95))
	canvas.draw_rect(plaque, Color(0.68, 0.52, 0.28, 0.92), false, 1.0)
	if a != null:
		a.draw_label_shadowed(canvas, center_pos, text, use_font, 10, Color(0.95, 0.88, 0.64), true)
	else:
		var tx: float = center_pos.x - tw * 0.5
		var ty: float = center_pos.y
		canvas.draw_string(use_font, Vector2(tx + 1.0, ty + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.06, 0.04, 0.03, 0.90))
		canvas.draw_string(use_font, Vector2(tx, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.88, 0.64))


static func _draw_fountain(r, t_now: float, cam_rect: Rect2) -> void:
	var fpos: Vector2 = BrugesCityMapDataScript.FOUNTAIN_POS
	if not cam_rect.intersects(Rect2(fpos - Vector2(44, 44), Vector2(88, 88))):
		return
	var f_tex: Texture2D = r.assets.get_tex("prop_stone_fountain.png")
	if f_tex != null:
		r.draw_texture_rect(f_tex, Rect2(fpos - Vector2(38, 38), Vector2(76, 76)), false)
	# Animated expanding ripples & 4 arched gothic spout jets inside basin
	var rip_a: float = 11.0 + fmod(t_now * 9.0, 11.0)
	var alpha_a: float = clampf(1.0 - (rip_a - 11.0) / 11.0, 0.0, 0.55)
	r.draw_arc(fpos, rip_a, 0.0, TAU, 24, Color(0.72, 0.92, 0.98, alpha_a), 1.4)
	for ji in range(4):
		var ang := float(ji) * (PI * 0.5)
		var jv := Vector2(cos(ang), sin(ang))
		var spout_o := fpos + jv * 7.5 + Vector2(0, -5)
		var jet_pt := fpos + jv * (15.0 + sin(t_now * 6.5 + float(ji)) * 2.0)
		r.draw_line(spout_o, jet_pt, Color(0.78, 0.94, 1.0, 0.85), 1.5)
		r.draw_circle(jet_pt, 1.8, Color(0.92, 0.98, 1.0, 0.90))
	var jet_h: float = 6.0 + sin(t_now * 6.5) * 2.2
	r.draw_line(fpos + Vector2(0, -14), fpos + Vector2(0, -14.0 - jet_h), Color(0.84, 0.96, 1.0, 0.92), 2.0)
	r.draw_circle(fpos + Vector2(0, -14.0 - jet_h), 2.2, Color(0.94, 0.99, 1.0, 0.94))


static func _draw_canal_boats(r, t_now: float, cam_rect: Rect2) -> void:
	# 1. Animated canal wake trails left behind moving barges
	var wakes: Array = r.get_meta("boat_wakes", []) if r.has_meta("boat_wakes") else []
	for wk in wakes:
		var wp: Vector2 = Vector2(wk.get("pos", Vector2.ZERO))
		if not cam_rect.has_point(wp):
			continue
		var frac: float = clampf(float(wk.get("age", 0.0)) / maxf(0.1, float(wk.get("max_age", 0.9))), 0.0, 1.0)
		var horiz_w: bool = bool(wk.get("horiz", false))
		var col := Color(0.84, 0.96, 1.0, (1.0 - frac) * 0.48)
		var rx: float = (9.0 + frac * 10.0) if not horiz_w else (4.0 + frac * 6.0)
		var ry: float = (4.0 + frac * 6.0) if not horiz_w else (9.0 + frac * 10.0)
		r.draw_line(wp - Vector2(rx, 0), wp + Vector2(rx, 0), col, 1.4)
		r.draw_arc(wp, maxf(rx, ry), 0.0, TAU, 14, col * Color(1, 1, 1, 0.55), 1.0)

	# 2. Flowing Flemish Praam Canal Barges
	var boats: Array = BrugesCityBoatsScript.get_boats(r)
	if boats.is_empty():
		boats = BrugesCityMapDataScript.get_canal_boats()
	var boarded_idx: int = BrugesCityBoatsScript.get_boarded_idx(r)
	for i in range(boats.size()):
		var bt: Dictionary = boats[i]
		var br: Rect2 = bt["rect"]
		if not cam_rect.intersects(br.grow(24.0)):
			continue
		var ph: float = float(bt.get("bob_phase", bt.get("phase", 0.0)))
		var horiz: bool = bool(bt.get("horiz", false))
		var has_cargo: bool = bool(bt.get("cargo", false))
		var bob: float = sin(t_now * 2.1 + ph) * 1.4
		var bpos: Vector2 = br.position + (Vector2(0.0, bob) if horiz else Vector2(bob * 0.5, sin(t_now * 1.6 + ph) * 1.2))
		var rect := Rect2(bpos, br.size)
		var rip_w: float = 2.0 + sin(t_now * 3.0 + ph) * 1.0
		r.draw_rect(rect.grow(rip_w), Color(0.76, 0.92, 0.98, 0.24), false, 1.4)
		var tname: String = ("prop_canal_barge_h_cargo.png" if has_cargo else "prop_canal_barge_h.png") if horiz else ("prop_canal_barge_v_cargo.png" if has_cargo else "prop_canal_barge_v.png")
		var btex: Texture2D = r.assets.get_tex(tname)
		if btex != null:
			var draw_r := rect.grow_individual(3.0, 4.0, 3.0, 4.0)
			r.draw_texture_rect(btex, draw_r, false)
		if i == boarded_idx:
			r.draw_rect(rect.grow(1.5), Color(0.95, 0.85, 0.42, 0.35), false, 1.5)

	# 3. Diegetic Hop Landing Target Ring
	var hop_cand: Dictionary = BrugesCityBoatsScript.find_hop_candidate(r)
	if bool(hop_cand.get("valid", false)):
		var tpos: Vector2 = Vector2(hop_cand["target_pos"])
		var pulse := 0.5 + 0.5 * sin(t_now * 6.0)
		var ring_col := Color(0.45, 0.96, 0.68, 0.55 + pulse * 0.35) if boarded_idx >= 0 else Color(0.98, 0.86, 0.38, 0.55 + pulse * 0.35)
		r.draw_circle(tpos, 10.0 + pulse * 2.5, ring_col * Color(1, 1, 1, 0.22))
		r.draw_arc(tpos, 10.0 + pulse * 2.5, 0.0, TAU, 18, ring_col, 1.8)
		r.draw_circle(tpos, 2.5, ring_col)


static func _draw_tile_clipped(canvas: Node2D, tex: Texture2D, wr: Rect2, horiz: bool) -> void:
	if tex == null:
		return
	var tw: float = float(tex.get_width())
	var th: float = float(tex.get_height())
	if horiz:
		var px: float = wr.position.x
		while px < wr.end.x - 0.5:
			var step_w: float = minf(tw, wr.end.x - px)
			canvas.draw_texture_rect_region(tex, Rect2(px, wr.position.y, step_w, wr.size.y), Rect2(0.0, 0.0, step_w, th))
			px += tw
	else:
		var py: float = wr.position.y
		while py < wr.end.y - 0.5:
			var step_h: float = minf(th, wr.end.y - py)
			canvas.draw_texture_rect_region(tex, Rect2(wr.position.x, py, wr.size.x, step_h), Rect2(0.0, 0.0, tw, step_h))
			py += th


static func _draw_wall_brazier(canvas: Node2D, assets, center_pos: Vector2, t_now: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t_now * 7.8 + center_pos.x * 0.13 + center_pos.y * 0.09)
	canvas.draw_circle(center_pos + Vector2(0, -4), 16.0 + pulse * 4.0, Color(1.0, 0.62, 0.18, 0.16 + pulse * 0.08))
	var bt: Texture2D = assets.get_tex("prop_wall_brazier.png")
	if bt != null:
		canvas.draw_texture_rect(bt, Rect2(center_pos - Vector2(9, 13), Vector2(18, 22)), false)


static func _draw_gate_arch_top(canvas: Node2D, assets, gr: Rect2, kind: String) -> void:
	if assets == null:
		return
	var is_horiz_span: bool = gr.size.x >= gr.size.y
	if kind == "watergate":
		if is_horiz_span:
			var wtex: Texture2D = assets.get_tex("prop_watergate_arch_h.png")
			if wtex != null:
				canvas.draw_texture_rect(wtex, Rect2(gr.position.x + 8.0, gr.position.y - 6.0, gr.size.x - 16.0, gr.size.y + 8.0), false)
		else:
			var wtex_v: Texture2D = assets.get_tex("prop_watergate_arch_v.png")
			if wtex_v != null:
				canvas.draw_texture_rect(wtex_v, Rect2(gr.position.x - 6.0, gr.position.y + 8.0, gr.size.x + 8.0, gr.size.y - 16.0), false)
		return
	if is_horiz_span:
		var gtex: Texture2D = assets.get_tex("prop_gatehouse_arch_h.png")
		if gtex != null:
			var pw: float = minf(48.0, gr.size.x * 0.28)
			canvas.draw_texture_rect(gtex, Rect2(gr.position.x + pw - 8.0, gr.position.y - 4.0, gr.size.x - pw * 2.0 + 16.0, minf(44.0, gr.size.y * 0.64)), false)
	else:
		var gtex_v: Texture2D = assets.get_tex("prop_gatehouse_arch_v.png")
		if gtex_v != null:
			var ph: float = minf(48.0, gr.size.y * 0.28)
			canvas.draw_texture_rect(gtex_v, Rect2(gr.position.x - 6.0, gr.position.y + ph - 8.0, gr.size.x + 12.0, gr.size.y - ph * 2.0 + 16.0), false)


static func _wall_spot_clear(walls: Array, probe: Rect2) -> bool:
	for fw in walls:
		if String(fw["kind"]) != "wall":
			var fr: Rect2 = fw["rect"]
			if fr.grow(10.0).intersects(probe):
				return false
	return true


static func _draw_castle_walls(r, font: Font, cam_rect: Rect2, t_now: float = 0.0) -> void:
	var assets = r.assets
	var wall_h_tex: Texture2D = assets.get_tex("prop_wall_h.png")
	var wall_v_tex: Texture2D = assets.get_tex("prop_wall_v.png")
	var gwall_h_tex: Texture2D = assets.get_tex("prop_garden_wall_h.png")
	var gwall_v_tex: Texture2D = assets.get_tex("prop_garden_wall_v.png")
	var round_tex: Texture2D = assets.get_tex("prop_bastion_round.png")
	var sq_tex: Texture2D = assets.get_tex("prop_bastion_square.png")
	var pier_h_tex: Texture2D = assets.get_tex("prop_gatehouse_pier_h.png")
	var pier_v_tex: Texture2D = assets.get_tex("prop_gatehouse_pier_v.png")
	var banner_tex: Texture2D = assets.get_tex("prop_wall_banner.png")

	var walls: Array[Dictionary] = BrugesCityMapDataScript.get_castle_walls()
	for w in walls:
		var wr: Rect2 = w["rect"]
		if not cam_rect.intersects(wr.grow(24.0)):
			continue
		var kind: String = String(w["kind"])
		var lbl: String = String(w.get("label", ""))
		if kind == "wall":
			var is_h: bool = wr.size.x >= wr.size.y
			var is_brick: bool = (wr.size.y if is_h else wr.size.x) < 28.0
			var wtex: Texture2D = (gwall_h_tex if is_brick else wall_h_tex) if is_h else (gwall_v_tex if is_brick else wall_v_tex)
			_draw_tile_clipped(r, wtex, wr, is_h)
			if not is_brick:
				if is_h and wr.size.x >= 200.0:
					if banner_tex != null:
						var bx: float = wr.position.x + 76.0
						while bx <= wr.end.x - 76.0:
							var b_probe := Rect2(bx - 10.0, wr.position.y, 20.0, 40.0)
							if cam_rect.has_point(Vector2(bx, wr.position.y + 18.0)) and _wall_spot_clear(walls, b_probe):
								r.draw_texture_rect(banner_tex, Rect2(bx - 8.0, wr.position.y + 12.0, 16.0, 28.0), false)
							bx += 170.0
					var fx: float = wr.position.x + 150.0
					while fx <= wr.end.x - 110.0:
						var f_probe := Rect2(fx - 10.0, wr.position.y - 4.0, 20.0, 32.0)
						if cam_rect.has_point(Vector2(fx, wr.position.y + 4.0)) and _wall_spot_clear(walls, f_probe):
							_draw_wall_brazier(r, assets, Vector2(fx, wr.position.y + 8.0), t_now)
						fx += 240.0
				elif not is_h and wr.size.y >= 220.0:
					var fy: float = wr.position.y + 130.0
					while fy <= wr.end.y - 110.0:
						var fy_probe := Rect2(wr.position.x, fy - 12.0, wr.size.x, 24.0)
						if cam_rect.has_point(Vector2(wr.position.x + wr.size.x * 0.5, fy)) and _wall_spot_clear(walls, fy_probe):
							_draw_wall_brazier(r, assets, Vector2(wr.position.x + wr.size.x * 0.5, fy), t_now)
						fy += 260.0
		elif kind == "tower_round":
			if round_tex != null:
				r.draw_texture_rect(round_tex, wr.grow(6.0), false)
			_draw_wall_brazier(r, assets, wr.get_center() + Vector2(0, 6), t_now)
			if lbl != "":
				_draw_wooden_sign(r, Vector2(wr.get_center().x, wr.end.y + 8.0), lbl, font)
		elif kind == "tower_square":
			if sq_tex != null:
				r.draw_texture_rect(sq_tex, wr.grow(6.0), false)
			if banner_tex != null:
				r.draw_texture_rect(banner_tex, Rect2(wr.get_center().x - 8.0, wr.position.y + wr.size.y * 0.42, 16.0, 26.0), false)
			if lbl != "":
				_draw_wooden_sign(r, Vector2(wr.get_center().x, wr.end.y + 8.0), lbl, font)
		elif kind == "gatehouse" or kind == "watergate":
			var is_hg: bool = wr.size.x >= wr.size.y
			if is_hg:
				var pw: float = minf(48.0, roundf(wr.size.x * 0.28)) if kind == "gatehouse" else 28.0
				var left_p := Rect2(wr.position.x - 4.0, wr.position.y - 8.0, pw, wr.size.y + 8.0)
				var right_p := Rect2(wr.end.x - pw + 4.0, wr.position.y - 8.0, pw, wr.size.y + 8.0)
				if pier_h_tex != null:
					r.draw_texture_rect(pier_h_tex, left_p, false)
					r.draw_texture_rect(pier_h_tex, right_p, false)
				if banner_tex != null and kind == "gatehouse":
					r.draw_texture_rect(banner_tex, Rect2(left_p.get_center().x - 8.0, left_p.position.y + left_p.size.y * 0.46, 16.0, 26.0), false)
					r.draw_texture_rect(banner_tex, Rect2(right_p.get_center().x - 8.0, right_p.position.y + right_p.size.y * 0.46, 16.0, 26.0), false)
				_draw_wall_brazier(r, assets, Vector2(left_p.get_center().x, left_p.end.y - 8.0), t_now)
				_draw_wall_brazier(r, assets, Vector2(right_p.get_center().x, right_p.end.y - 8.0), t_now)
			else:
				var ph: float = minf(48.0, roundf(wr.size.y * 0.28)) if kind == "gatehouse" else 28.0
				var top_p := Rect2(wr.position.x - 4.0, wr.position.y - 4.0, wr.size.x + 8.0, ph)
				var bot_p := Rect2(wr.position.x - 4.0, wr.end.y - ph + 4.0, wr.size.x + 8.0, ph)
				if pier_v_tex != null:
					r.draw_texture_rect(pier_v_tex, top_p, false)
					r.draw_texture_rect(pier_v_tex, bot_p, false)
				_draw_wall_brazier(r, assets, Vector2(top_p.get_center().x, top_p.end.y - 4.0), t_now)
				_draw_wall_brazier(r, assets, Vector2(bot_p.get_center().x, bot_p.position.y + 10.0), t_now)
			_draw_gate_arch_top(r, assets, wr, kind)
			if lbl != "":
				_draw_wooden_sign(r, Vector2(wr.get_center().x, wr.end.y + 8.0), lbl, font)


static func draw_city(r) -> void:
	var assets = r.assets
	var font := ThemeDB.fallback_font
	var t_now := float(Time.get_ticks_msec()) * 0.001
	var cam_rect: Rect2 = r.get_camera_rect(140.0)

	# 1. Stone Bridges, Moored Barges & Grapple Winch Posts
	for br in BrugesCityMapDataScript.get_bridge_placements():
		var br_rect: Rect2 = br["rect"]
		if not cam_rect.intersects(br_rect):
			continue
		var br_tex: Texture2D = assets.get_tex(String(br["tex"]), "prop_timber_bridge_h.png")
		if br_tex != null:
			r.draw_texture_rect(br_tex, br_rect, false)
		var wake: Texture2D = assets.get_tex("prop_pier_wake_%d.png" % (int(t_now * 4.0) % 2))
		if wake != null:
			r.draw_texture_rect(wake, Rect2(br_rect.position + Vector2(-10, br_rect.size.y * 0.4), Vector2(22, 22)), false)

	_draw_canal_boats(r, t_now, cam_rect)
	_draw_fountain(r, t_now, cam_rect)

	var winch_tex: Texture2D = assets.get_tex("prop_winch_post.png")
	var ret_tex: Texture2D = assets.get_tex("prop_pixel_reticle.png")
	for pair in BrugesCityMapDataScript.get_winch_pairs():
		for pt_raw in [pair["west"], pair["east"]]:
			var pt := Vector2(pt_raw)
			if not cam_rect.has_point(pt):
				continue
			if winch_tex != null:
				r.draw_texture_rect(winch_tex, Rect2(pt - Vector2(22, 40), Vector2(44, 58)), false)
			if ret_tex != null and r.player.position.distance_to(pt) < 280.0:
				var psz: float = 16.0 + sin(t_now * 4.5) * 2.5
				r.draw_texture_rect(ret_tex, Rect2(pt - Vector2(psz * 0.5, 16.0 + psz * 0.5), Vector2(psz, psz)), false, Color(0.66, 0.94, 0.78, 0.55))

	# 2. City & Citadel Fortifications
	_draw_castle_walls(r, font, cam_rect, t_now)
	var ep_tex: Texture2D = assets.get_tex("prop_gatehouse_pier_v.png")
	if ep_tex != null and cam_rect.intersects(Rect2(2710, 1210, 80, 190)):
		r.draw_texture_rect(ep_tex, Rect2(2734, 1226, 36, 36), false)
		r.draw_texture_rect(ep_tex, Rect2(2734, 1344, 36, 36), false)
	var ms_tex: Texture2D = assets.get_tex("prop_milestone.png")
	if ms_tex != null:
		if cam_rect.has_point(Vector2(1352, 1986)):
			r.draw_texture_rect(ms_tex, Rect2(1338, 1954, 28, 36), false)
		if cam_rect.has_point(Vector2(2644, 1236)):
			r.draw_texture_rect(ms_tex, Rect2(2630, 1204, 28, 36), false)

	# 3. Props, Lanterns & Buildings (Y-sorted against Player via _draw_foreground)
	for pr in BrugesCityMapDataScript.get_prop_placements():
		var pr_rect: Rect2 = pr["rect"]
		if not cam_rect.intersects(pr_rect.grow(28.0)):
			continue
		var pname: String = String(pr["tex"])
		r.draw_circle(Vector2(pr_rect.position.x + pr_rect.size.x * 0.5, pr_rect.end.y - 3.0), pr_rect.size.x * 0.42, Color(0.05, 0.06, 0.08, 0.24))
		if pname == "prop_brick_bread_oven.png":
			assets.draw_bakery_oven_fx(r, pr_rect, t_now)
			continue
		var ptex: Texture2D = assets.get_tex(pname)
		if ptex != null:
			r.draw_texture_rect(ptex, pr_rect, false)
		if pname == "prop_garrison_rack.png":
			var gp: float = sin(t_now * 2.8 + pr_rect.position.x * 0.11 + pr_rect.position.y * 0.07)
			if gp > 0.60:
				var ga := clampf((gp - 0.60) / 0.40, 0.0, 1.0)
				var glint := pr_rect.position + Vector2(14.0 + fmod(pr_rect.position.x, 18.0), 8.0)
				r.draw_line(glint - Vector2(3.5, 0), glint + Vector2(3.5, 0), Color(0.96, 0.98, 1.0, ga * 0.90), 1.4)
				r.draw_line(glint - Vector2(0, 3.5), glint + Vector2(0, 3.5), Color(0.96, 0.98, 1.0, ga * 0.90), 1.4)

	var l_tex: Texture2D = assets.get_tex("prop_lantern.png")
	for lpos_raw in r.lantern_positions:
		var lpos := Vector2(lpos_raw)
		if not cam_rect.has_point(lpos):
			continue
		r.draw_circle(lpos + Vector2(0, 2), 6.5, Color(0.04, 0.04, 0.06, 0.35))
		if l_tex != null:
			r.draw_texture_rect(l_tex, Rect2(lpos - Vector2(10, 26), Vector2(20, 28)), false)

	for b in BrugesCityMapDataScript.get_city_buildings():
		var br: Rect2 = b["rect"]
		if not cam_rect.intersects(br):
			continue
		var btex: Texture2D = assets.get_tex(String(b["tex"]))
		r.draw_circle(Vector2(br.position.x + br.size.x * 0.5, br.end.y - 4.0), br.size.x * 0.44, Color(0.05, 0.06, 0.08, 0.26))
		if btex != null:
			r.draw_texture_rect(btex, br, false)
		var stxt: String = String(b.get("sign", ""))
		if stxt != "":
			_draw_wooden_sign(r, Vector2(b["spos"]), stxt, font)

	# 5. Chimney Smoke Plumes
	var chimneys: Array[Vector2] = BrugesCityMapDataScript.get_chimney_positions()
	for ci in range(chimneys.size()):
		var cpos: Vector2 = chimneys[ci]
		if cam_rect.has_point(cpos):
			assets.draw_chimney_smoke(r, cpos, ci % 2)

	# 6. Living Townsfolk (with soft step-aside yield when player approaches)
	for tf in r.townsfolk_states:
		var bpos: Vector2 = Vector2(tf["pos"])
		if not cam_rect.has_point(bpos):
			continue
		var tpos: Vector2 = r.get_npc_yield_pos(String(tf["id"]), bpos, 34.0, 13.0)
		var moving: bool = bool(tf.get("moving", false))
		var phase: float = float(tf.get("phase", 0.0))
		var anim_f: int = (int(t_now * 6.5) % 2) if moving else (int(t_now * 2.1 + phase) % 2)
		var flip_h: bool = Vector2(tf.get("dir", Vector2.DOWN)).x < -0.1
		assets.draw_npc_sprite(r, tpos, "%s_%d.png" % [String(tf["tex"]), anim_f], "", font, Color(0.95, 0.92, 0.84), flip_h)

	# 7. Quest Actors, Priest Stealth & Combat
	_draw_quest_actors(r, t_now, font, cam_rect)
	_draw_enemies_and_bolts(r, t_now, font, cam_rect)

	if GameState.city_bounty_overheard and GameState.city_keep_escape_won and cam_rect.has_point(r.EAST_OUTSKIRTS_GATE_POS):
		var pulse: float = 0.5 + 0.5 * sin(t_now * 4.5)
		r.draw_arc(r.EAST_OUTSKIRTS_GATE_POS, 24.0 + pulse * 5.0, 0.0, TAU, 20, Color(0.45, 0.96, 0.68, 0.85), 2.5)

	r.queue_foreground_redraw()


static func _draw_quest_actors(r, t_now: float, font: Font, cam_rect: Rect2) -> void:
	var assets = r.assets
	var f2: int = int(t_now * 2.4) % 2
	if cam_rect.has_point(r.NPC_JORIS_POS):
		var jpos: Vector2 = r.get_npc_yield_pos("city_joris", r.NPC_JORIS_POS, 34.0, 12.0)
		assets.draw_npc_sprite(r, jpos, "npc_city_burgher_%d.png" % f2, "Factor Joris", font)
		if not GameState.city_clue_cloth_hall and not GameState.city_clue_counting_house:
			r.draw_arc(jpos, 18.0 + sin(t_now * 4.2) * 3.0, 0.0, TAU, 16, Color(0.98, 0.82, 0.38, 0.72), 1.8)

	if cam_rect.has_point(r.NPC_BEATRIJS_POS):
		var bpos: Vector2 = r.get_npc_yield_pos("city_beatrijs", r.NPC_BEATRIJS_POS, 34.0, 12.0)
		assets.draw_npc_sprite(r, bpos, "npc_city_apothecary_%d.png" % f2, "Sister Beatrijs", font)
		if not GameState.city_clue_beguinage and not GameState.city_clue_counting_house:
			r.draw_arc(bpos, 18.0 + sin(t_now * 4.2) * 3.0, 0.0, TAU, 16, Color(0.98, 0.82, 0.38, 0.72), 1.8)

	if not GameState.city_watergate_skirmish_won and not GameState.city_clue_counting_house and cam_rect.has_point(r.WAGON_CLUE_POS):
		r.draw_arc(r.WAGON_CLUE_POS, 22.0 + sin(t_now * 4.5) * 3.0, 0.0, TAU, 18, Color(0.98, 0.78, 0.34, 0.82), 2.2)

	if GameState.city_watergate_skirmish_won and not GameState.city_clue_counting_house and cam_rect.has_point(r.DROPPED_NOTE_POS):
		var ntex: Texture2D = assets.get_tex("prop_knot_clue.png")
		if ntex != null:
			r.draw_texture_rect(ntex, Rect2(r.DROPPED_NOTE_POS - Vector2(11.0, 11.0), Vector2(22.0, 22.0)), false)
		r.draw_arc(r.DROPPED_NOTE_POS, 16.0 + sin(t_now * 4.8) * 3.0, 0.0, TAU, 16, Color(0.98, 0.86, 0.36, 0.90), 2.2)

	if GameState.city_clue_counting_house and not bool(r.priest_tail_active) and not GameState.city_bounty_overheard and cam_rect.has_point(r.CHURCH_HIDING_POS):
		r.draw_arc(r.CHURCH_HIDING_POS, 18.0 + sin(t_now * 4.2) * 3.0, 0.0, TAU, 16, Color(0.98, 0.84, 0.38, 0.88), 2.2)

	var inq_pos: Vector2 = r.INQUISITOR_POS
	if (bool(r.priest_tail_active) or GameState.city_bounty_overheard) and cam_rect.has_point(inq_pos):
		assets.draw_npc_sprite(r, inq_pos, "npc_inquisitor.png", "Church Inquisitor", font, Color(0.96, 0.56, 0.52))

	var ppos: Vector2 = Vector2(r.priest_pos)
	if bool(r.priest_tail_active) and cam_rect.has_point(ppos):
		var st: String = String(r.priest_state)
		var eye_o := ppos + Vector2(0.0, -8.0)
		var half_fov := deg_to_rad(46.0)
		var face_dir: Vector2 = Vector2(r.priest_look_dir if st != "walk" else r.priest_dir).normalized()
		if st == "warn":
			r.draw_raycast_vision_cone(r, eye_o, Vector2(r.priest_base_look_dir).normalized(), 270.0, half_fov, r.sight_blockers, Color(0.98, 0.78, 0.24, 0.14), Color(0.98, 0.84, 0.34, 0.42), 32)
			var rem: float = clampf(float(r.priest_state_timer) / 1.15, 0.0, 1.0)
			r.draw_arc(ppos + Vector2(0, -34), 10.0, -PI * 0.5, -PI * 0.5 + TAU * rem, 16, Color(0.98, 0.82, 0.28), 2.6)
			assets.draw_label_shadowed(r, ppos + Vector2(0, -52), "?!", font, 12, Color(0.98, 0.84, 0.32), true)
		elif st == "glance":
			r.draw_raycast_vision_cone(r, eye_o, Vector2(r.priest_look_dir).normalized(), 270.0, half_fov, r.sight_blockers, Color(0.98, 0.24, 0.20, 0.30), Color(0.98, 0.42, 0.34, 0.72), 32)
		assets.draw_npc_sprite(r, ppos, "npc_city_monk_%d.png" % f2, "Father Anselm", font, Color(0.98, 0.90, 0.72), face_dir.x < -0.1)
		_draw_priest_stole(r, ppos)


static func _draw_priest_stole(canvas: Node2D, ppos: Vector2) -> void:
	canvas.draw_rect(Rect2(ppos + Vector2(-4.0, -14.0), Vector2(2.2, 11.0)), Color(0.76, 0.16, 0.18))
	canvas.draw_rect(Rect2(ppos + Vector2(1.8, -14.0), Vector2(2.2, 11.0)), Color(0.76, 0.16, 0.18))
	canvas.draw_rect(Rect2(ppos + Vector2(-4.0, -4.5), Vector2(2.2, 1.5)), Color(0.94, 0.78, 0.32))
	canvas.draw_rect(Rect2(ppos + Vector2(1.8, -4.5), Vector2(2.2, 1.5)), Color(0.94, 0.78, 0.32))


static func _draw_enemies_and_bolts(r, t_now: float, font: Font, cam_rect: Rect2) -> void:
	var assets = r.assets
	var anim_f: int = int(t_now * 4.0) % 2
	for e in r.enemies:
		if int(e["hp"]) <= 0:
			continue
		var ep: Vector2 = Vector2(e["pos"])
		if not cam_rect.has_point(ep):
			continue
		var edir: Vector2 = Vector2(e["dir"]).normalized()
		var kind: String = String(e["kind"])
		var state: String = String(e["state"])
		var stun_t: float = float(e["stun"])
		var hurt_t: float = float(e.get("hurt_flash", 0.0))

		if stun_t <= 0.0:
			if kind == "shield":
				var fa: float = edir.angle()
				r.draw_arc(ep + Vector2(0, -8), 16.0, fa - 1.15, fa + 1.15, 10, Color(0.76, 0.82, 0.90, 0.88), 3.2)
				if state == "windup":
					var p: float = 1.0 - clampf(float(e["timer"]) / 0.62, 0.0, 1.0)
					r.draw_arc(ep + Vector2(0, -8), 26.0 + p * 18.0, fa - 0.95, fa + 0.95, 12, Color(0.98, 0.26, 0.22, 0.55 + p * 0.35), 3.0)
			elif kind == "arbalester" and state == "aim":
				var p_a: float = 1.0 - clampf(float(e["timer"]) / 0.92, 0.0, 1.0)
				var target_pt: Vector2 = ep + Vector2(0, -10) + edir * (180.0 + 180.0 * p_a)
				r.draw_line(ep + Vector2(0, -10), target_pt, Color(0.98, 0.28, 0.22, 0.35 + p_a * 0.55), 1.6 + p_a * 1.4)

		var gtex := "npc_church_hunter_%d.png" % anim_f
		var tex: Texture2D = assets.get_tex_flipped(gtex, "npc_church_hunter.png") if edir.x < -0.1 else assets.get_tex(gtex, "npc_church_hunter.png")
		r.draw_circle(ep + Vector2(0, 8), 10.0, Color(0.05, 0.06, 0.08, 0.30))
		if tex != null:
			var col := Color(1.0, 0.45, 0.45) if hurt_t > 0.0 else (Color(0.84, 0.82, 0.96) if stun_t > 0.0 else Color.WHITE)
			r.draw_texture_rect(tex, Rect2(ep.x - 19.0, ep.y - 33.0, 38.0, 44.0), false, col)

		if stun_t > 0.0:
			r.draw_arc(ep + Vector2(0, -10), 14.0, 0.0, TAU, 14, Color(0.96, 0.80, 0.34, 0.88), 2.2)
			r.draw_arc(ep + Vector2(0, -30), 7.5, 0.0, TAU * clampf(stun_t / 2.8, 0.0, 1.0), 12, Color(0.98, 0.84, 0.40), 2.2)

		var max_hp := int(e["max_hp"])
		var cur_hp := int(e["hp"])
		var start_x: float = ep.x - (float(max_hp) * 9.0) * 0.5
		for hi in range(max_hp):
			var pip_r := Rect2(start_x + float(hi) * 9.0, ep.y - 38.0, 7.0, 4.0)
			r.draw_rect(pip_r, Color(0.92, 0.24, 0.22) if hi < cur_hp else Color(0.18, 0.14, 0.16, 0.75))

	var btex: Texture2D = assets.get_tex("prop_hunter_bolt.png")
	for b in r.enemy_bolts:
		var bp: Vector2 = Vector2(b["pos"])
		if not cam_rect.has_point(bp):
			continue
		var bd: Vector2 = Vector2(b["dir"]).normalized()
		if btex != null:
			r.draw_texture_rect(btex, Rect2(bp - Vector2(7, 7), Vector2(14, 14)), false)
		r.draw_line(bp - bd * 9.0, bp + bd * 7.0, Color(0.98, 0.42, 0.28), 2.4)

	for sp in r.combat_sparks:
		var a: float = clampf(float(sp["t"]) / float(sp["max_t"]), 0.0, 1.0)
		var scol: Color = sp["col"]
		r.draw_circle(Vector2(sp["pos"]), 2.8, Color(scol, a))

	var arrows: Array = []
	if bool(r.priest_tail_active):
		arrows.append([Vector2(r.priest_pos), 380.0, Color(0.98, 0.84, 0.36, 0.90), 2.2])
	if GameState.city_bounty_overheard and GameState.city_keep_escape_won and not r._has_living_enemies():
		arrows.append([Vector2(r.EAST_OUTSKIRTS_GATE_POS), 220.0, Color(0.45, 0.96, 0.68, 0.92), 2.4])
	for arr in arrows:
		var delta_v: Vector2 = Vector2(arr[0]) - r.player.position
		if delta_v.length() > float(arr[1]):
			var nd: Vector2 = delta_v.normalized()
			var tip: Vector2 = r.player.position + nd * 68.0
			var side := Vector2(-nd.y, nd.x)
			var col: Color = arr[2]
			var lw: float = float(arr[3])
			r.draw_line(tip - nd * 8.0 - side * 5.0, tip, col, lw)
			r.draw_line(tip - nd * 8.0 + side * 5.0, tip, col, lw)


static func _draw_foreground(r, fg: Node2D) -> void:
	var assets = r.assets
	var font := ThemeDB.fallback_font
	var t_now := float(Time.get_ticks_msec()) * 0.001
	var py: float = r.player.position.y
	var cam_rect: Rect2 = r.get_camera_rect(140.0)

	# 1. Walk-behind upper building gables & roofs when player is north of building base
	for b in BrugesCityMapDataScript.get_city_buildings():
		var br: Rect2 = b["rect"]
		if py < br.end.y - 6.0 and py > br.position.y - 24.0 and cam_rect.intersects(br):
			var btex: Texture2D = assets.get_tex(String(b["tex"]))
			r.draw_building_roof_overhang(fg, br, btex, 0.46)

	# 2. Gatehouse & Watergate overhead archways when player is north of or inside the arch, plus walk-behind bastion roofs
	var round_tex: Texture2D = assets.get_tex("prop_bastion_round.png")
	var sq_tex: Texture2D = assets.get_tex("prop_bastion_square.png")
	for w in BrugesCityMapDataScript.get_castle_walls():
		var kind: String = String(w["kind"])
		var wr: Rect2 = w["rect"]
		if (kind == "tower_round" or kind == "tower_square") and py < wr.end.y - 8.0 and py > wr.position.y - 26.0 and cam_rect.intersects(wr.grow(8.0)):
			var btex_t: Texture2D = round_tex if kind == "tower_round" else sq_tex
			if btex_t != null:
				r.draw_building_roof_overhang(fg, wr.grow(6.0), btex_t, 0.46)
			continue
		if kind != "gatehouse" and kind != "watergate":
			continue
		if py < wr.end.y - 2.0 and cam_rect.intersects(wr.grow(12.0)):
			_draw_gate_arch_top(fg, assets, wr, kind)

	# 3. Walk-behind garden pine tree upper canopies
	var pine_tex: Texture2D = assets.get_tex("prop_pine_tree.png")
	if pine_tex != null:
		for pr in BrugesCityMapDataScript.get_prop_placements():
			if String(pr["tex"]) != "prop_pine_tree.png":
				continue
			var pr_rect: Rect2 = pr["rect"]
			if py < pr_rect.end.y - 8.0 and cam_rect.intersects(pr_rect):
				r.draw_building_roof_overhang(fg, pr_rect, pine_tex, 0.62)

	# 4. NPCs standing south of the player render on foreground for crisp Y-sorting
	for tf in r.townsfolk_states:
		var tpos: Vector2 = r.get_npc_yield_pos(String(tf["id"]), Vector2(tf["pos"]), 34.0, 13.0)
		if tpos.y > py + 2.0 and cam_rect.has_point(tpos):
			var moving: bool = bool(tf.get("moving", false))
			var phase: float = float(tf.get("phase", 0.0))
			var anim_f: int = (int(t_now * 6.5) % 2) if moving else (int(t_now * 2.1 + phase) % 2)
			var flip_h: bool = Vector2(tf.get("dir", Vector2.DOWN)).x < -0.1
			assets.draw_npc_sprite(fg, tpos, "%s_%d.png" % [String(tf["tex"]), anim_f], "", font, Color(0.95, 0.92, 0.84), flip_h)

	var f2: int = int(t_now * 2.4) % 2
	var jpos: Vector2 = r.get_npc_yield_pos("city_joris", r.NPC_JORIS_POS, 34.0, 12.0)
	if jpos.y > py + 2.0 and cam_rect.has_point(jpos):
		assets.draw_npc_sprite(fg, jpos, "npc_city_burgher_%d.png" % f2, "Factor Joris", font)

	var bpos: Vector2 = r.get_npc_yield_pos("city_beatrijs", r.NPC_BEATRIJS_POS, 34.0, 12.0)
	if bpos.y > py + 2.0 and cam_rect.has_point(bpos):
		assets.draw_npc_sprite(fg, bpos, "npc_city_apothecary_%d.png" % f2, "Sister Beatrijs", font)

	if bool(r.priest_tail_active):
		var ppos: Vector2 = Vector2(r.priest_pos)
		if ppos.y > py + 2.0 and cam_rect.has_point(ppos):
			var face_dir: Vector2 = Vector2(r.priest_look_dir if String(r.priest_state) != "walk" else r.priest_dir).normalized()
			assets.draw_npc_sprite(fg, ppos, "npc_city_monk_%d.png" % f2, "Father Anselm", font, Color(0.98, 0.90, 0.72), face_dir.x < -0.1)
			_draw_priest_stole(fg, ppos)

	# 5. St. Donatian Cathedral Golden Acoustic Bell-Waves & Active [E] prompt
	for br in r.bell_wave_rings:
		var age: float = float(br.get("age", 0.0))
		if age < 0.0:
			continue
		var max_a: float = maxf(0.1, float(br.get("max_age", 2.4)))
		var frac: float = clampf(age / max_a, 0.0, 1.0)
		var bpos_w: Vector2 = Vector2(br.get("pos", Vector2.ZERO))
		if cam_rect.intersects(Rect2(bpos_w - Vector2(260, 260), Vector2(520, 520))):
			fg.draw_arc(bpos_w, 16.0 + frac * 220.0, 0.0, TAU, 40, Color(1.0, 0.88, 0.44, (1.0 - frac) * 0.72), 2.4)

	# 6. Active [E] prompt drawn cleanly on top so building gables never cover prompts
	r.draw_interact_bubble_if_active_on(fg, font)
