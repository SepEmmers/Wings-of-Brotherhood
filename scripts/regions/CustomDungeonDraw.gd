extends RefCounted

## Static ground & live puzzle entity renderer for CustomDungeonRegion.gd.
## Renders rooms, water chasms, masonry walls, gates, drawbridges, color blocks,
## switches, hazards, conveyors, teleporters, pickups, NPCs, and decor.

const LogicScript := preload("res://scripts/regions/CustomDungeonLogic.gd")

const FLOOR_TYPES: Array[String] = [
	"exit_portal", "weight_plate", "pressure_pad", "heat_plate", "serpent_vent", "spike_trap",
	"conveyor", "collapsing_floor", "teleporter", "drawbridge", "rune_tile",
]


static func load_dungeon_dict(opts: Dictionary) -> Dictionary:
	var raw_data = opts.get("dungeon_data", {})
	if raw_data is Dictionary and not raw_data.is_empty():
		return raw_data.duplicate(true)
	for path: String in ["user://custom_dungeon.json", "res://data/custom_dungeon.json"]:
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary and not parsed.is_empty():
				return parsed
	return {}


static func compute_wall_borders(room_rects: Array[Rect2], explicit_walls: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var thick := 36.0
	for r: Rect2 in room_rects:
		var strips := [
			Rect2(r.position.x - thick, r.position.y - thick, r.size.x + thick * 2.0, thick),
			Rect2(r.position.x - thick, r.end.y, r.size.x + thick * 2.0, thick),
			Rect2(r.position.x - thick, r.position.y, thick, r.size.y),
			Rect2(r.end.x, r.position.y, thick, r.size.y),
		]
		for s: Rect2 in strips:
			for piece: Rect2 in _subtract_rects(s, room_rects):
				if piece.size.x >= 4.0 and piece.size.y >= 4.0:
					out.append(piece)
	for ew in explicit_walls:
		out.append(Rect2(float(ew.get("x", 0)), float(ew.get("y", 0)), float(ew.get("w", 32)), float(ew.get("h", 32))))
	return out


static func setup_layers(r) -> void:
	var created_water := r.get_node_or_null("EnvWaterLayer") == null
	var chasms: Array[Rect2] = r.get_chasm_rects()
	r.setup_water_layer(chasms, 48.0, -3)
	if created_water:
		r.step_water_layer()
	var wsz: Vector2 = r.world_size
	r.setup_static_ground_chunks(
		Rect2(0, 0, wsz.x, wsz.y),
		func(canvas: Node2D): _draw_static_ground(r, canvas),
		720,
		-2,
		not chasms.is_empty()
	)
	r.ensure_foreground_layer(func(fg: Node2D): _draw_foreground(r, fg), 18)


static func _get_floor_textures(assets, style: String) -> Array:
	match style:
		"cathedral_flag":
			return [assets.get_tex("tile_cathedral_flag.png", "tile_catacomb_stone.png"), assets.get_tex("tile_cathedral_flag_2.png", "tile_cathedral_flag.png")]
		"library_wood":
			return [assets.get_tex("tile_library_wood.png", "tile_wood_plank.png"), assets.get_tex("tile_library_wood_2.png", "tile_library_wood.png")]
		"obsidian_shrine":
			return [assets.get_tex("tile_lair_basalt.png", "tile_catacomb_stone.png"), assets.get_tex("tile_catacomb_stone_2.png", "tile_lair_basalt.png")]
		_:
			return [assets.get_tex("tile_catacomb_stone.png", "tile_lair_basalt.png"), assets.get_tex("tile_catacomb_stone_2.png", "tile_catacomb_stone.png")]


static func _subtract_rects(target: Rect2, cutters: Array[Rect2]) -> Array[Rect2]:
	var pieces: Array[Rect2] = [target]
	for cut: Rect2 in cutters:
		var nxt: Array[Rect2] = []
		for p: Rect2 in pieces:
			if not p.intersects(cut):
				nxt.append(p)
				continue
			var ix := p.intersection(cut)
			if ix.position.y > p.position.y + 1.0:
				nxt.append(Rect2(p.position.x, p.position.y, p.size.x, ix.position.y - p.position.y))
			if ix.end.y < p.end.y - 1.0:
				nxt.append(Rect2(p.position.x, ix.end.y, p.size.x, p.end.y - ix.end.y))
			if ix.position.x > p.position.x + 1.0:
				nxt.append(Rect2(p.position.x, ix.position.y, ix.position.x - p.position.x, ix.size.y))
			if ix.end.x < p.end.x - 1.0:
				nxt.append(Rect2(ix.end.x, ix.position.y, p.end.x - ix.end.x, ix.size.y))
		pieces = nxt
	return pieces


static func _draw_static_ground(r, canvas: Node2D) -> void:
	var assets = r.assets
	var wsz: Vector2 = r.world_size
	var chasms: Array[Rect2] = r.get_chasm_rects()
	for bg_piece: Rect2 in _subtract_rects(Rect2(Vector2.ZERO, wsz), chasms):
		canvas.draw_rect(bg_piece, Color(0.04, 0.04, 0.06))

	var pair := _get_floor_textures(assets, r.floor_style)
	var t1: Texture2D = pair[0]
	var t2: Texture2D = pair[1]
	var room_rects: Array[Rect2] = r.get_room_rects()
	var is_shrine: bool = r.floor_style == "obsidian_shrine"
	var trim_col := Color(0.84, 0.68, 0.28, 0.55) if is_shrine else Color(0.42, 0.44, 0.52, 0.65)

	for fl: Rect2 in room_rects:
		for piece: Rect2 in _subtract_rects(fl, chasms):
			if t1 != null:
				assets.draw_varied_tiled_rect(canvas, piece, t1, t2, 32.0, 9)
			else:
				canvas.draw_rect(piece, Color(0.24, 0.23, 0.27))
		canvas.draw_rect(fl, trim_col, false, 2.0)

	for ch: Rect2 in chasms:
		canvas.draw_line(ch.position, Vector2(ch.position.x, ch.end.y), trim_col, 3.0)
		canvas.draw_line(Vector2(ch.end.x, ch.position.y), ch.end, trim_col, 3.0)

	for wc: Rect2 in r.wall_border_rects:
		canvas.draw_rect(wc, Color(0.14, 0.13, 0.17))
		canvas.draw_rect(wc, Color(0.32, 0.31, 0.38), false, 1.5)


static func _draw_floor_node(r, node: Dictionary, rect: Rect2, t_now: float) -> void:
	var assets = r.assets
	var nid: String = String(node.get("id", ""))
	var t: String = String(node.get("type", ""))
	var active: bool = bool(r.node_states.get(nid, false))
	match t:
		"exit_portal":
			var st: Texture2D = assets.get_tex(String(node.get("tex", "prop_crypt_stairs.png")), "prop_crypt_stairs.png")
			if st != null:
				r.draw_texture_rect(st, rect, false)
		"weight_plate":
			var pt: Texture2D = assets.get_tex("prop_weight_plate_down.png" if active else "prop_weight_plate_up.png")
			if pt != null:
				r.draw_texture_rect(pt, rect, false)
		"pressure_pad":
			var ppt: Texture2D = assets.get_tex("dk_pressure_pad_down.png" if active else "dk_pressure_pad.png")
			if ppt != null:
				r.draw_texture_rect(ppt, rect, false)
		"heat_plate":
			var hpt: Texture2D = assets.get_tex("dk_heat_plate_lit.png" if active else "dk_heat_plate.png")
			if hpt != null:
				r.draw_texture_rect(hpt, rect, false)
		"rune_tile":
			var rt: Texture2D = assets.get_tex("dk_rune_tile_lit.png" if active else "dk_rune_tile.png")
			if rt != null:
				r.draw_texture_rect(rt, rect, false)
		"serpent_vent":
			var en: bool = r.is_node_enabled(nid)
			var vt: Texture2D = assets.get_tex(String(node.get("tex", "prop_shrine_serpent_vent.png")), "prop_shrine_serpent_vent.png")
			var col := Color(1.0, 0.92, 0.65) if active else (Color.WHITE if en else Color(0.55, 0.55, 0.62))
			if vt != null:
				r.draw_texture_rect(vt, rect, false, col)
		"spike_trap":
			var up: bool = r.is_spike_up(node) and LogicScript.hazard_armed(r, node)
			var skt: Texture2D = assets.get_tex("prop_floor_spikes_up.png" if up else "prop_floor_spikes_down.png")
			if skt != null:
				r.draw_texture_rect(skt, rect, false)
		"conveyor":
			var d: String = String(node.get("dir", "right"))
			var ct: Texture2D = assets.get_tex("dk_conveyor_%s.png" % d, "dk_conveyor_right.png")
			if ct != null:
				r.draw_texture_rect(ct, rect, false)
		"collapsing_floor":
			var ft: Texture2D = assets.get_tex("dk_floor_pit.png" if active else "dk_cracked_floor.png")
			var wobble: float = sin(t_now * 28.0) * 1.5 if (not active and float(r.collapse_t.get(nid, 0.0)) > 0.05) else 0.0
			if ft != null:
				r.draw_texture_rect(ft, Rect2(rect.position + Vector2(wobble, 0), rect.size), false)
		"teleporter":
			var tpt: Texture2D = assets.get_tex("dk_teleporter.png")
			if tpt != null:
				r.draw_texture_rect(tpt, rect, false)
			r.draw_circle(rect.get_center(), 10.0 + sin(t_now * 4.0) * 3.0, Color(0.55, 0.68, 1.0, 0.25))
		"drawbridge":
			if active:
				var bt: Texture2D = assets.get_tex("tile_wharf.png", "prop_timber_bridge_h.png")
				if bt != null:
					r.draw_texture_rect(bt, rect, false)
				r.draw_rect(rect, Color(0.42, 0.28, 0.16), false, 2.0)
			else:
				r.draw_rect(rect, Color(0.75, 0.60, 0.32, 0.22), false, 1.5)


static func _tex_for_y_node(r, node: Dictionary, active: bool) -> String:
	var nid: String = String(node.get("id", ""))
	var t: String = String(node.get("type", ""))
	var tex_name: String = String(node.get("tex", "prop_crate.png"))
	match t:
		"ember_brazier":
			return "prop_altar_candle.png" if "candle" in tex_name else ("prop_shrine_sconce_on.png" if active else "prop_shrine_sconce_off.png")
		"lever":
			return "prop_medieval_lever_pulled.png" if active else "prop_medieval_lever_idle.png"
		"treasure":
			return "prop_treasure_chest_open.png" if (active and "chest" in tex_name) else tex_name
		"crystal_switch":
			return "dk_crystal_switch_1.png" if int(r.crystal_phase) == 1 else "dk_crystal_switch_0.png"
		"color_block":
			var is_red: bool = String(node.get("color", "red")) == "red"
			var solid: bool = LogicScript.color_block_solid(r, node)
			return ("dk_block_red.png" if solid else "dk_block_red_low.png") if is_red else ("dk_block_blue.png" if solid else "dk_block_blue_low.png")
		"resonance_crystal":
			return "dk_resonance_crystal_lit.png" if active else "dk_resonance_crystal.png"
		"timer_switch":
			return "dk_timer_switch_on.png" if active else "dk_timer_switch.png"
		"checkpoint":
			return "dk_checkpoint_on.png" if active else "dk_checkpoint.png"
		"flame_jet":
			return "dk_flame_jet_on.png" if bool(r.flame_on.get(nid, false)) else "dk_flame_jet.png"
		"breakable_pot":
			return "dk_pot_broken.png" if active else "dk_pot.png"
	return tex_name


static func draw_region_entities(r, t_now: float) -> void:
	var assets = r.assets
	var cam: Rect2 = r.get_camera_rect(140.0)
	var y_drawables: Array[Dictionary] = []

	for node: Dictionary in r.nodes:
		var t: String = String(node.get("type", ""))
		if t == "trigger_zone" or t == "relay":
			continue
		var nid: String = String(node.get("id", ""))
		var active: bool = bool(r.node_states.get(nid, false))
		if active and t in ["briar_barrier", "secret_wall", "cracked_wall", "key_small", "key_boss", "heart_pickup", "heart_container", "coin"]:
			continue
		var rect: Rect2 = LogicScript.node_rect(r, node)
		if not cam.intersects(rect.grow(36.0)):
			continue
		if FLOOR_TYPES.has(t):
			_draw_floor_node(r, node, rect, t_now)
		else:
			y_drawables.append({"node": node, "rect": rect, "pos": rect.get_center(), "y": rect.end.y})

	y_drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))
	for d: Dictionary in y_drawables:
		var node: Dictionary = d["node"]
		var nid: String = String(node.get("id", ""))
		var t: String = String(node.get("type", ""))
		var rect: Rect2 = d["rect"]
		var pos: Vector2 = d["pos"]
		var active: bool = bool(r.node_states.get(nid, false))

		if t == "gate" or t == "locked_door":
			var gt: Texture2D = assets.get_tex("prop_shrine_door_open.png" if active else String(node.get("tex", "dk_door_locked.png")), "prop_shrine_door_shut.png")
			var draw_r: Rect2 = Rect2(rect.position - Vector2(0, rect.size.y * 0.45), Vector2(rect.size.x, rect.size.y * 0.55)) if active else rect
			if gt != null:
				r.draw_texture_rect(gt, draw_r, false, Color(1, 1, 1, 0.5 if active else 1.0))
			continue

		var tex: Texture2D = assets.get_tex(_tex_for_y_node(r, node, active), "prop_crate.png")
		if tex != null:
			r.draw_texture_rect(tex, rect, false)
		if t == "ember_brazier" and active:
			r.draw_circle(pos + Vector2(0, -10), 20.0 + sin(t_now * 8.0) * 3.0, Color(1.0, 0.80, 0.28, 0.28))
		elif t == "grapple_post":
			r.draw_circle(pos + Vector2(0, -10), 4.0, Color(0.98, 0.84, 0.34))
		elif t == "treasure" and not active:
			var bob: float = sin(t_now * 3.8) * 3.0
			if r.is_node_enabled(nid):
				r.draw_circle(pos + Vector2(0, -18 + bob), 14.0, Color(1.0, 0.86, 0.34, 0.30))
			else:
				r.draw_circle(pos + Vector2(0, -14), 8.0, Color(0.85, 0.32, 0.28, 0.45))

	for b: Dictionary in r.dart_bolts:
		var bp := Vector2(b["pos"])
		r.draw_line(bp - Vector2(b["dir"]) * 10.0, bp, Color(0.92, 0.88, 0.72), 2.5)
	for sp: Dictionary in r.fx_sparks:
		var c: Color = sp["col"]
		var a: float = clampf(float(sp["life"]) / float(sp["max_life"]), 0.0, 1.0)
		r.draw_circle(Vector2(sp["pos"]), float(sp["sz"]), Color(c.r, c.g, c.b, a))


static func _draw_foreground(r, fg: Node2D) -> void:
	if r.player != null and r.player.visible and not (r.ui != null and r.ui.is_blocking_gameplay()):
		r.draw_interact_bubble_if_active_on(fg, r.assets.get_ui_font())
