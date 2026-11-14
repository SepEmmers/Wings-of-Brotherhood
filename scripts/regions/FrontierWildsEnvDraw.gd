extends RefCounted

## Stylized Pixel-Art Environment Renderer for FrontierWildsRegion.
## Bakes the static 2880x2160 woodland floor (grass, scatters, moss, clearings, dirt trails,
## verges, hoarfrost, and cobble plaza) ONCE into a nearest-neighbor SubViewport displayed via
## 720x720 frustum- and light-culled Sprite2D chunks, and renders only camera-visible animated
## river segments, texture-grouped riverbank edges, and precomputed cliff escarpments per frame.

const CHUNK_SIZE := 720
const WHITE_COLS: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]


static func get_camera_rect(r, pad: float = 140.0) -> Rect2:
	return r.get_camera_rect(pad)


class WildsStaticGroundLayer extends Node2D:
	var region
	var _frost_clearings: Array[Dictionary] = []

	func _draw() -> void:
		if region == null or region.assets == null:
			return
		var a = region.assets
		_frost_clearings.clear()
		for c: Dictionary in region.clearings:
			if str(c.get("surface", "")) == "frost":
				_frost_clearings.append(c)

		var world_rect := Rect2(0, 0, region.WORLD_W, region.WORLD_H)
		a.draw_grass_zone(self, world_rect, false, 9, [Rect2(130, 180, 250, 210), Rect2(2510, 140, 230, 200)])
		_draw_moss_and_frost(a)
		_draw_clearings_and_trails(a)

	func _draw_moss_and_frost(a) -> void:
		if region.ridge_pts.size() >= 3:
			var basin := PackedVector2Array([Vector2(0, 495)])
			for rp: Vector2 in region.ridge_pts:
				basin.append(rp)
			basin.append(Vector2(0, region.WORLD_H))
			draw_colored_polygon(basin, Color(0.04, 0.07, 0.14, 0.14))

		var verges: Array[Texture2D] = []
		for vname in ["prop_trail_verge_0.png", "prop_trail_verge_1.png"]:
			var vt: Texture2D = a.get_tex(vname)
			if vt != null:
				verges.append(vt)
		for idx in range(region.moss_patches.size()):
			var mp: Dictionary = region.moss_patches[idx]
			var pos: Vector2 = _snap2(mp.get("pos", Vector2.ZERO))
			if _dirt_margin(pos) > 4.0 or _frost_factor(pos) > 0.35:
				continue
			var rx := float(mp.get("rx", 36.0))
			var ry := float(mp.get("ry", 24.0))
			var kind := int(mp.get("kind", 0))
			var mod := Color(0.82, 0.96, 0.84, 0.75) if kind == 0 else (Color(0.92, 0.84, 0.72, 0.70) if kind == 1 else Color(0.76, 0.84, 0.92, 0.55))
			if not verges.is_empty():
				for k in range(3):
					var sp := _snap2(pos + Vector2(((k - 1) * rx * 0.42), ((idx + k) % 3 - 1) * ry * 0.32))
					if _dirt_margin(sp) <= 4.0:
						draw_texture_rect(verges[(idx + k) % verges.size()], Rect2(sp - Vector2(18, 18), Vector2(36, 36)), false, mod)

	func _dirt_margin(pos: Vector2) -> float:
		var best := -9999.0
		for c: Dictionary in region.clearings:
			var surf := str(c.get("surface", "needle"))
			if surf == "cobble" or surf == "hollow":
				continue
			var cpos: Vector2 = c.get("pos", Vector2.ZERO)
			var r_draw := float(c.get("r", 92.0)) * 0.86
			if absf(pos.x - cpos.x) > r_draw + 16.0 or absf(pos.y - cpos.y) > r_draw + 16.0:
				continue
			var m := r_draw - pos.distance_to(cpos)
			if m > best:
				best = m
		for tr: Dictionary in region.trail_polylines:
			var bbox: Rect2 = tr.get("bbox", Rect2())
			if bbox.size.x > 0.0 and not bbox.has_point(pos):
				continue
			var pts: PackedVector2Array = tr.get("pts", PackedVector2Array())
			var hw := maxf(12.0, float(tr.get("hw", 24.0)) * 0.875)
			var reach := hw + 16.0
			for i in range(pts.size() - 1):
				var p0 := pts[i]
				var p1 := pts[i + 1]
				if pos.x < minf(p0.x, p1.x) - reach or pos.x > maxf(p0.x, p1.x) + reach or pos.y < minf(p0.y, p1.y) - reach or pos.y > maxf(p0.y, p1.y) + reach:
					continue
				var closest := Geometry2D.get_closest_point_to_segment(pos, p0, p1)
				var m := hw - pos.distance_to(closest)
				if m > best:
					best = m
		return best

	func _frost_factor(pos: Vector2) -> float:
		var best := 0.0
		for c: Dictionary in _frost_clearings:
			var cpos: Vector2 = c.get("pos", Vector2.ZERO)
			var rad := float(c.get("r", 92.0))
			var limit := rad * 1.48
			if absf(pos.x - cpos.x) > limit or absf(pos.y - cpos.y) > limit:
				continue
			var d := pos.distance_to(cpos)
			if d < limit:
				var f := clampf(1.0 - (d - rad * 0.62) / (rad * 0.86), 0.0, 1.0)
				if f > best:
					best = f
		return best

	func _snap2(v: Vector2) -> Vector2:
		return Vector2(roundf(v.x * 0.5) * 2.0, roundf(v.y * 0.5) * 2.0)

	func _draw_textured_strip(pts: PackedVector2Array, width: float, tex: Texture2D, tile_px: float) -> void:
		if pts.size() < 2 or tex == null:
			return
		var half_w := width * 0.5
		var n := pts.size()
		var normals: Array[Vector2] = []
		normals.resize(n)
		for i in range(n):
			var tangent := Vector2.ZERO
			if i > 0:
				tangent += (pts[i] - pts[i - 1]).normalized()
			if i < n - 1:
				tangent += (pts[i + 1] - pts[i]).normalized()
			tangent = Vector2.RIGHT if tangent.length_squared() < 0.001 else tangent.normalized()
			var nrm := Vector2(-tangent.y, tangent.x)
			if i > 0 and i < n - 1:
				var seg_n := (pts[i + 1] - pts[i]).normalized()
				var dot_m := maxf(0.55, absf(nrm.dot(Vector2(-seg_n.y, seg_n.x))))
				nrm *= minf(1.4, 1.0 / dot_m)
			normals[i] = nrm

		var white_cols := PackedColorArray(WHITE_COLS)
		for i in range(n - 1):
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var n0 := normals[i] * half_w
			var n1 := normals[i + 1] * half_w
			var quad := PackedVector2Array([p0 - n0, p0 + n0, p1 + n1, p1 - n1])
			var uvs := PackedVector2Array([quad[0] / tile_px, quad[1] / tile_px, quad[2] / tile_px, quad[3] / tile_px])
			draw_polygon(quad, white_cols, uvs, tex)

	func _draw_clearings_and_trails(a) -> void:
		var dirt_tex: Texture2D = a.get_tex("tile_forest_dirt.png", "tile_dirt_path.png")
		var lair_tex: Texture2D = a.get_tex("tile_lair_basalt.png", "tile_forest_dirt.png")
		var frost_tex: Texture2D = a.get_tex("tile_frost_slate.png", "tile_cobble.png")
		var verges: Array[Texture2D] = []
		for vname in ["prop_trail_verge_0.png", "prop_trail_verge_1.png"]:
			var vt: Texture2D = a.get_tex(vname)
			if vt != null:
				verges.append(vt)
		var frost_tufts: Array[Texture2D] = []
		for fname in ["prop_frost_feather_0.png", "prop_frost_feather_1.png"]:
			var ft: Texture2D = a.get_tex(fname)
			if ft != null:
				frost_tufts.append(ft)

		var cobble_clearings: Array[Dictionary] = []
		for c in region.clearings:
			var cpos: Vector2 = c.get("pos", Vector2.ZERO)
			var rad := float(c.get("r", 92.0))
			var surf := str(c.get("surface", "needle"))
			if surf == "cobble":
				cobble_clearings.append(c)
				continue
			if surf == "hollow":
				rad = minf(rad, 72.0)
			var use_tex := lair_tex if (surf == "hollow" and lair_tex != null) else dirt_tex
			if use_tex == null:
				continue
			var segs := 24
			var poly := PackedVector2Array()
			var uvs := PackedVector2Array()
			var cols := PackedColorArray()
			for s in range(segs):
				var ang := (float(s) / float(segs)) * TAU
				var jag := 1.0 + sin(ang * 5.0 + cpos.x * 0.01) * 0.05
				var p := cpos + Vector2(cos(ang), sin(ang)) * ((rad * 0.88) * jag)
				poly.append(p)
				uvs.append(p / 64.0)
				cols.append(Color.WHITE)
			draw_polygon(poly, cols, uvs, use_tex)

		for tr in region.trail_polylines:
			var pts: PackedVector2Array = tr.get("pts", PackedVector2Array())
			var hw := float(tr.get("hw", 24.0))
			_draw_textured_strip(pts, maxf(24.0, hw * 1.75), dirt_tex, 64.0)

		if not verges.is_empty():
			for idx in range(region.clearings.size()):
				var c: Dictionary = region.clearings[idx]
				var cpos: Vector2 = c.get("pos", Vector2.ZERO)
				var rad := float(c.get("r", 92.0))
				var surf := str(c.get("surface", "needle"))
				if surf == "hollow" or surf == "cobble" or surf == "frost":
					continue
				var count := maxi(12, int((TAU * rad) / 22.0))
				for k in range(count):
					var ang := (float(k) / float(count)) * TAU
					var h := (idx * 37 + k * 19) % 11
					var rr := rad * 0.88 + float(h - 5) * 1.4
					var sp := _snap2(cpos + Vector2(cos(ang), sin(ang)) * rr)
					if _dirt_margin(sp) < 9.5 and _frost_factor(sp) < 0.25 and sp.distance_to(region.OUTPOST_POS) > 112.0:
						draw_texture_rect(verges[k % verges.size()], Rect2(sp - Vector2(22, 22), Vector2(44, 44)), false)

			for tidx in range(region.trail_polylines.size()):
				var tr: Dictionary = region.trail_polylines[tidx]
				var pts: PackedVector2Array = tr.get("pts", PackedVector2Array())
				var hw := float(tr.get("hw", 24.0))
				var strip_hw := maxf(12.0, hw * 0.875)
				for i in range(pts.size() - 1):
					var p0 := pts[i]
					var p1 := pts[i + 1]
					var seg := p1 - p0
					var slen := seg.length()
					if slen < 2.0:
						continue
					var dir := seg / slen
					var perp := Vector2(-dir.y, dir.x)
					var steps := maxi(1, int(slen / 20.0))
					for s in range(steps):
						var frac := (float(s) + 0.5) / float(steps)
						var center := p0.lerp(p1, frac)
						for side in [-1.0, 1.0]:
							var h := absi(((i * 73 + s * 41 + int(side * 19) + 200 + tidx * 31) * 2654435761) % 997)
							var sp := _snap2(center + perp * (side * (strip_hw + float((h % 5) - 2) * 1.4)))
							if _dirt_margin(sp) < 9.5 and _frost_factor(sp) < 0.25 and sp.distance_to(region.OUTPOST_POS) > 112.0 and sp.distance_to(region.BLACK_DRAGON_POS) > 88.0:
								draw_texture_rect(verges[h % verges.size()], Rect2(sp - Vector2(20, 20), Vector2(40, 40)), false)

		if frost_tex != null:
			for c: Dictionary in _frost_clearings:
				var cpos: Vector2 = c.get("pos", Vector2.ZERO)
				var rad := float(c.get("r", 92.0))
				for tier in [
					{"s": 1.32, "a": 0.22, "freq": 6.0},
					{"s": 1.08, "a": 0.44, "freq": 7.0},
					{"s": 0.86, "a": 0.72, "freq": 5.0},
					{"s": 0.62, "a": 0.94, "freq": 5.0}
				]:
					var segs := 32
					var poly := PackedVector2Array()
					var uvs := PackedVector2Array()
					var cols := PackedColorArray()
					var tier_col := Color(0.92, 0.96, 1.0, float(tier["a"]))
					for s in range(segs):
						var ang := (float(s) / float(segs)) * TAU
						var jag := 1.0 + sin(ang * float(tier["freq"]) + cpos.x * 0.03) * 0.08 + cos(ang * 9.0 + cpos.y * 0.02) * 0.05
						var p := cpos + Vector2(cos(ang), sin(ang)) * (rad * float(tier["s"]) * jag)
						poly.append(p)
						uvs.append(p / 64.0)
						cols.append(tier_col)
					draw_polygon(poly, cols, uvs, frost_tex)

				for k in range(36):
					var ang := (float(k) / 36.0) * TAU + sin(float(k) * 1.7 + cpos.x) * 0.14
					var rr := rad * lerpf(0.72, 1.34, float((k * 13 + int(cpos.x)) % 17) / 16.0)
					var fp := _snap2(cpos + Vector2(cos(ang), sin(ang)) * rr)
					if not frost_tufts.is_empty():
						var fmod := Color(0.94, 0.98, 1.0, clampf(1.38 - rr / rad, 0.30, 0.88))
						draw_texture_rect(frost_tufts[k % frost_tufts.size()], Rect2(fp - Vector2(22, 22), Vector2(44, 44)), false, fmod)
					else:
						draw_rect(Rect2(fp, Vector2(4, 2)), Color(0.84, 0.96, 1.0, 0.60))

			for tidx in range(region.trail_polylines.size()):
				var tr: Dictionary = region.trail_polylines[tidx]
				var pts: PackedVector2Array = tr.get("pts", PackedVector2Array())
				var hw := maxf(12.0, float(tr.get("hw", 24.0)) * 0.875)
				for i in range(pts.size() - 1):
					var p0 := pts[i]
					var p1 := pts[i + 1]
					var mid := p0.lerp(p1, 0.5)
					var ff := _frost_factor(mid)
					if ff > 0.04:
						var dir := (p1 - p0).normalized()
						var perp := Vector2(-dir.y, dir.x) * (hw * 0.95)
						var quad := PackedVector2Array([p0 - perp, p0 + perp, p1 + perp, p1 - perp])
						var uvs := PackedVector2Array([quad[0] / 64.0, quad[1] / 64.0, quad[2] / 64.0, quad[3] / 64.0])
						var c0 := Color(0.92, 0.97, 1.0, clampf(_frost_factor(p0) * 0.78, 0.0, 0.85))
						var c1 := Color(0.92, 0.97, 1.0, clampf(_frost_factor(p1) * 0.78, 0.0, 0.85))
						draw_polygon(quad, PackedColorArray([c0, c0, c1, c1]), uvs, frost_tex)
						if not frost_tufts.is_empty():
							var sp_l := _snap2(mid - perp * 0.88)
							var sp_r := _snap2(mid + perp * 0.88)
							var tm := Color(0.94, 0.98, 1.0, clampf(ff * 0.95, 0.20, 0.85))
							draw_texture_rect(frost_tufts[i % frost_tufts.size()], Rect2(sp_l - Vector2(18, 18), Vector2(36, 36)), false, tm)
							draw_texture_rect(frost_tufts[(i + 1) % frost_tufts.size()], Rect2(sp_r - Vector2(18, 18), Vector2(36, 36)), false, tm)

		for c in cobble_clearings:
			var cpos: Vector2 = c.get("pos", Vector2.ZERO)
			a.draw_stone_clearing_in_grass(self, Rect2(cpos - Vector2(106, 86), Vector2(212, 172)), 3)
			if not verges.is_empty():
				for vy in range(-64, 72, 24):
					var vp := _snap2(cpos + Vector2(-106.0, float(vy)))
					draw_texture_rect(verges[absi(vy) % verges.size()], Rect2(vp - Vector2(18, 18), Vector2(36, 36)), false)


class WildsTerrainLayer extends Node2D:
	var region
	var t_now: float = 0.0
	var cam_rect: Rect2 = Rect2(0, 0, 2880, 2160)
	var water_segs: Array[Dictionary] = []
	var bank_rects_0: Array[Rect2] = []
	var bank_rects_1: Array[Rect2] = []
	var stone_rects_0: Array[Rect2] = []
	var stone_rects_1: Array[Rect2] = []
	var foam_segs: Array[Dictionary] = []
	var cliff_items: Array[Dictionary] = []
	var scree_items: Array[Rect2] = []
	var river_bounds: Rect2 = Rect2()
	var _caches_built: bool = false
	var _white_cols := PackedColorArray(WHITE_COLS)

	const BRIDGE_SKIPS: Array[Rect2] = [
		Rect2(456, 244, 152, 134),
		Rect2(468, 1276, 152, 134),
		Rect2(440, 456, 108, 96),
		Rect2(1800, 394, 108, 96),
	]

	func _snap2(v: Vector2) -> Vector2:
		return Vector2(roundf(v.x * 0.5) * 2.0, roundf(v.y * 0.5) * 2.0)

	func build_caches() -> void:
		if _caches_built or region == null:
			return
		_caches_built = true
		_build_river_cache()
		_build_cliff_cache()

	func _build_organic_river_pts(pts: PackedVector2Array, seed_val: int) -> PackedVector2Array:
		var out := PackedVector2Array()
		if pts.size() < 2:
			return pts
		for i in range(pts.size() - 1):
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var seg := p1 - p0
			var slen := seg.length()
			var sub_steps := maxi(1, int(floorf(slen / 14.0)))
			var perp := Vector2(-seg.y, seg.x).normalized() if slen > 0.1 else Vector2.RIGHT
			for s in range(sub_steps):
				var t := float(s) / float(sub_steps)
				var pt := p0.lerp(p1, t)
				var in_bridge := false
				for br in BRIDGE_SKIPS:
					if br.has_point(pt):
						in_bridge = true
						break
				if not in_bridge:
					var wobble := sin(float(i * 11 + s) * 1.15 + float(seed_val)) * 3.8
					pt += perp * wobble
				out.append(pt)
		out.append(pts[pts.size() - 1])
		return out

	func _collect_river_stamps(pts: PackedVector2Array, half_w: float, stamp_sz: Vector2, step_px: float, seed_base: int, alternating: bool, out_0: Array[Rect2], out_1: Array[Rect2]) -> void:
		var next_sample := step_px * 0.5
		var seg_start_d := 0.0
		var step_idx := 0
		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			var seg := b - a
			var slen := seg.length()
			if slen < 1.0:
				continue
			var dir := seg / slen
			var perp := Vector2(-dir.y, dir.x)
			while next_sample <= seg_start_d + slen:
				var t := (next_sample - seg_start_d) / slen
				var center := a.lerp(b, t)
				step_idx += 1
				var sides: Array = [-1.0, 1.0]
				if alternating:
					var pick_hash := absi(((step_idx * 89 + seed_base) * 2654435761) % 997)
					if pick_hash % 4 == 0:
						next_sample += step_px
						continue
					sides = [-1.0] if (pick_hash % 2 == 0) else [1.0]
				for side in sides:
					var h := absi(((i * 73 + step_idx * 41 + int(side * 19) + seed_base) * 2654435761) % 997)
					var jitter := float((h % 7) - 3) * 1.6
					var pos := _snap2(center + perp * (side * (half_w + jitter)))
					var skip := false
					for sr in BRIDGE_SKIPS:
						if sr.has_point(pos):
							skip = true
							break
					if skip:
						continue
					var scale_f := 1.0 if not alternating else lerpf(0.75, 1.05, float(h % 11) / 10.0)
					var sz := stamp_sz * scale_f
					var r_st := Rect2(pos - sz * 0.5, sz)
					if h % 2 == 0:
						out_0.append(r_st)
					else:
						out_1.append(r_st)
				next_sample += step_px
			seg_start_d += slen

	func _build_river_cache() -> void:
		water_segs.clear()
		bank_rects_0.clear()
		bank_rects_1.clear()
		stone_rects_0.clear()
		stone_rects_1.clear()
		foam_segs.clear()
		var has_bounds := false
		for r_idx in range(2):
			var raw_pts: PackedVector2Array = region.gorge_river_pts if r_idx == 0 else region.creek_river_pts
			var rw := 62.0 if r_idx == 0 else 54.0
			if raw_pts.size() < 2:
				continue
			var pts := _build_organic_river_pts(raw_pts, 13 + r_idx * 41)
			var half_w := (rw - 4.0) * 0.5
			var n := pts.size()
			var normals: Array[Vector2] = []
			normals.resize(n)
			for i in range(n):
				var tangent := Vector2.ZERO
				if i > 0:
					tangent += (pts[i] - pts[i - 1]).normalized()
				if i < n - 1:
					tangent += (pts[i + 1] - pts[i]).normalized()
				tangent = Vector2.RIGHT if tangent.length_squared() < 0.001 else tangent.normalized()
				var nrm := Vector2(-tangent.y, tangent.x)
				if i > 0 and i < n - 1:
					var seg_n := (pts[i + 1] - pts[i]).normalized()
					var dot_m := maxf(0.55, absf(nrm.dot(Vector2(-seg_n.y, seg_n.x))))
					nrm *= minf(1.4, 1.0 / dot_m)
				normals[i] = nrm
			for i in range(n - 1):
				var p0 := pts[i]
				var p1 := pts[i + 1]
				var n0 := normals[i] * half_w
				var n1 := normals[i + 1] * half_w
				var quad := PackedVector2Array([p0 - n0, p0 + n0, p1 + n1, p1 - n1])
				var uvs := PackedVector2Array([quad[0] / 32.0, quad[1] / 32.0, quad[2] / 32.0, quad[3] / 32.0])
				var qrect := Rect2(quad[0], Vector2.ZERO).expand(quad[1]).expand(quad[2]).expand(quad[3]).grow(24.0)
				water_segs.append({"quad": quad, "uvs": uvs, "rect": qrect})
				river_bounds = qrect if not has_bounds else river_bounds.merge(qrect)
				has_bounds = true
				if i % 3 == 0:
					foam_segs.append({"p0": p0, "p1": p1, "i": i, "rect": qrect})
			_collect_river_stamps(pts, rw * 0.46, Vector2(44, 44), 18.0, 400 + r_idx * 97, false, bank_rects_0, bank_rects_1)
			_collect_river_stamps(pts, rw * 0.36, Vector2(30, 30), 68.0, 720 + r_idx * 61, true, stone_rects_0, stone_rects_1)

	func _build_cliff_cache() -> void:
		cliff_items.clear()
		scree_items.clear()
		var corner_pt := Vector2(1015, 480)
		var gaps: Array[Rect2] = [
			Rect2(456, 244, 154, 134),
			Rect2(468, 1276, 154, 134),
			Rect2(458, 444, 62, 92),
			Rect2(1816, 384, 72, 90),
		]
		for i in range(region.ridge_pts.size() - 1):
			var p0: Vector2 = region.ridge_pts[i]
			var p1: Vector2 = region.ridge_pts[i + 1]
			var seg := p1 - p0
			var slen := seg.length()
			if slen < 4.0:
				continue
			var dir := seg / slen
			var horizontal := absf(dir.x) > absf(dir.y) * 0.9
			var step := 68.0 if horizontal else 62.0
			var count := maxi(1, int(ceilf(slen / step)))
			for s in range(count + 1):
				var frac := clampf(float(s) / float(count), 0.0, 1.0)
				var sp := _snap2(p0.lerp(p1, frac))
				if sp.distance_to(corner_pt) < 28.0:
					continue
				var in_gap := false
				for gr in gaps:
					if gr.has_point(sp):
						in_gap = true
						break
				if in_gap:
					continue
				if horizontal:
					cliff_items.append({"tex": "prop_cliff_face_h_%d.png" % ((i + s) % 2), "rect": Rect2(sp - Vector2(38, 28), Vector2(76, 92))})
				else:
					cliff_items.append({"tex": "prop_cliff_face_v_%d.png" % ((i + s) % 2), "rect": Rect2(sp - Vector2(56, 36), Vector2(84, 72))})

		cliff_items.append({"tex": "prop_cliff_corner.png", "rect": Rect2(corner_pt - Vector2(56, 28), Vector2(84, 88))})
		cliff_items.append({"tex": "prop_cliff_taper_l.png", "rect": Rect2(Vector2(436, 488) - Vector2(38, 28), Vector2(76, 92))})
		cliff_items.append({"tex": "prop_cliff_taper_l.png", "rect": Rect2(Vector2(1796, 412) - Vector2(38, 28), Vector2(76, 92))})
		cliff_items.append({"tex": "prop_cliff_taper_r.png", "rect": Rect2(Vector2(1912, 412) - Vector2(38, 28), Vector2(76, 92))})

		for r_idx in range(region.ridge_rocks.size()):
			if r_idx % 4 != 0:
				continue
			var rk: Dictionary = region.ridge_rocks[r_idx]
			var base_p: Vector2 = rk.get("pos", Vector2.ZERO)
			var toe_off := Vector2(0, 34.0) if base_p.y < 515.0 else Vector2(-24.0, 0.0)
			var rpos := base_p + toe_off
			if rpos.distance_to(corner_pt) < 42.0:
				continue
			var blocked := false
			for gr in gaps:
				if gr.has_point(rpos):
					blocked = true
					break
			if blocked:
				continue
			var sz := clampf(float(rk.get("size", 32.0)) * 0.48, 18.0, 25.0)
			var rw := -sz if bool(rk.get("flip", false)) else sz
			scree_items.append(Rect2(rpos - Vector2(sz * 0.5, sz * 0.58), Vector2(rw, sz)))

	func _draw() -> void:
		if region == null or region.assets == null:
			return
		var a = region.assets
		var water_tex: Texture2D = a.animated_water_tex()
		var uv_scroll := Vector2(0.0, -fmod(t_now * 0.28, 1.0))

		if water_tex != null:
			for seg: Dictionary in water_segs:
				if not cam_rect.intersects(seg["rect"]):
					continue
				var base_uvs: PackedVector2Array = seg["uvs"]
				var shifted := PackedVector2Array([
					base_uvs[0] + uv_scroll,
					base_uvs[1] + uv_scroll,
					base_uvs[2] + uv_scroll,
					base_uvs[3] + uv_scroll,
				])
				draw_polygon(seg["quad"], _white_cols, shifted, water_tex)

		var b0: Texture2D = a.get_tex("prop_riverbank_edge_0.png")
		var b1: Texture2D = a.get_tex("prop_riverbank_edge_1.png")
		if b0 != null:
			for br0: Rect2 in bank_rects_0:
				if cam_rect.intersects(br0):
					draw_texture_rect(b0, br0, false)
		if b1 != null:
			for br1: Rect2 in bank_rects_1:
				if cam_rect.intersects(br1):
					draw_texture_rect(b1, br1, false)

		var s0: Texture2D = a.get_tex("prop_river_stone_0.png")
		var s1: Texture2D = a.get_tex("prop_river_stone_1.png")
		if s0 != null:
			for sr0: Rect2 in stone_rects_0:
				if cam_rect.intersects(sr0):
					draw_texture_rect(s0, sr0, false)
		if s1 != null:
			for sr1: Rect2 in stone_rects_1:
				if cam_rect.intersects(sr1):
					draw_texture_rect(s1, sr1, false)

		var foam_frame := int(t_now * 4.5) % 2
		var foam_tex: Texture2D = a.get_tex("prop_river_foam_%d.png" % foam_frame)
		if foam_tex != null:
			for fs: Dictionary in foam_segs:
				if not cam_rect.intersects(fs["rect"]):
					continue
				var p0: Vector2 = fs["p0"]
				var p1: Vector2 = fs["p1"]
				var mid := _snap2(p0.lerp(p1, fmod(float(fs["i"]) * 0.37 + t_now * 0.35, 1.0)))
				var blocked := false
				for br in BRIDGE_SKIPS:
					if br.has_point(mid):
						blocked = true
						break
				if not blocked:
					draw_texture_rect(foam_tex, Rect2(mid - Vector2(16, 12), Vector2(32, 24)), false)

		var pool_tex: Texture2D = a.get_tex("prop_waterfall_pool_%d.png" % foam_frame)
		if pool_tex != null:
			for pool_pos in [Vector2(494, 526), Vector2(1854, 462)]:
				var pr := Rect2(pool_pos - Vector2(56, 28), Vector2(112, 56))
				if cam_rect.intersects(pr):
					draw_texture_rect(pool_tex, pr, false)


static func ensure_terrain_layer(r) -> WildsTerrainLayer:
	if r.get_node_or_null("StaticGroundSV") == null:
		var static_drawer := WildsStaticGroundLayer.new()
		static_drawer.region = r
		r.setup_static_ground_chunks(Rect2(0, 0, r.WORLD_W, r.WORLD_H), Callable(), CHUNK_SIZE, -3, false, "StaticGround", static_drawer)

	var layer := r.get_node_or_null("EnvTerrainLayer") as WildsTerrainLayer
	if layer == null:
		layer = WildsTerrainLayer.new()
		layer.name = "EnvTerrainLayer"
		layer.region = r
		layer.z_index = -1
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		layer.build_caches()
		r.add_child(layer)

	var cam_r := get_camera_rect(r, 140.0)
	layer.t_now = float(Time.get_ticks_msec()) * 0.001
	layer.cam_rect = cam_r
	var show_river := layer.river_bounds.intersects(cam_r)
	layer.visible = show_river
	if show_river:
		layer.queue_redraw()
	return layer


static func draw_cliff_escarpment(r, cam_rect: Rect2) -> void:
	var layer := r.get_node_or_null("EnvTerrainLayer") as WildsTerrainLayer
	if layer == null:
		return
	var a = r.assets
	for ci: Dictionary in layer.cliff_items:
		var cr: Rect2 = ci["rect"]
		if not cam_rect.intersects(cr):
			continue
		var tex: Texture2D = a.get_tex(ci["tex"], "prop_cliff_rock.png")
		if tex != null:
			r.draw_texture_rect(tex, cr, false)

	var rock_tex: Texture2D = a.get_tex("prop_cliff_rock.png")
	if rock_tex != null:
		for sr: Rect2 in layer.scree_items:
			var test_r := Rect2(sr.position, Vector2(absf(sr.size.x), sr.size.y))
			if cam_rect.intersects(test_r):
				r.draw_texture_rect(rock_tex, sr, false)


static func draw_waterfalls(r, t_now: float, cam_rect: Rect2) -> void:
	var wf_idx := int(t_now * 7.5) % 4
	var wf_tex: Texture2D = r.assets.get_tex("prop_waterfall_%d.png" % wf_idx, "prop_waterfall_0.png")
	if wf_tex == null:
		return
	for wf in [Vector2(494, 488), Vector2(1854, 424)]:
		var wr := Rect2(wf - Vector2(44, 40), Vector2(88, 92))
		if cam_rect.intersects(wr):
			r.draw_texture_rect(wf_tex, wr, false)


static func draw_bridges(r, t_now: float, cam_rect: Rect2) -> void:
	var a = r.assets
	var wake_tex: Texture2D = a.get_tex("prop_pier_wake_%d.png" % (int(t_now * 4.5) % 2))
	var stone_tex: Texture2D = a.get_tex("prop_stone_bridge_h.png")
	var timber_tex: Texture2D = a.get_tex("prop_timber_bridge_h.png")

	if wake_tex != null:
		for wp in [Vector2(514, 382), Vector2(546, 382), Vector2(526, 1412), Vector2(558, 1412)]:
			var wr := Rect2(wp - Vector2(14, 14), Vector2(28, 28))
			if cam_rect.intersects(wr):
				r.draw_texture_rect(wake_tex, wr, false, Color(1, 1, 1, 0.72))

	if stone_tex != null:
		var sr := Rect2(Vector2(468, 254), Vector2(128, 114))
		if cam_rect.intersects(sr):
			r.draw_texture_rect(stone_tex, sr, false)
	if timber_tex != null:
		var tr := Rect2(Vector2(480, 1286), Vector2(128, 114))
		if cam_rect.intersects(tr):
			r.draw_texture_rect(timber_tex, tr, false)
