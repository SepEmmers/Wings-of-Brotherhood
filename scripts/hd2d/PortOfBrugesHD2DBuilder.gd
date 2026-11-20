extends RefCounted

## Procedural 3D diorama builder for Port of Bruges (`bruges`).
## Converts the 1600x1040 Flemish harbor into a multi-level Octopath-style HD-2D
## miniature with stepped-gable brick guildhalls, Zwin sea water, dockside wharf,
## merchant cog *De Zwaan*, outdoor bakery oven, and Flemish harbor ramparts.

const HD2DLib := preload("res://scripts/hd2d/HD2DStageBuilder.gd")

const PX_PER_M := 48.0
const ORIGIN_2D := Vector2(800.0, 520.0)
const WATER_Y := -0.78
const DECK_Y := WATER_Y + 1.04

const TEX_COBBLES := "res://assets/hd2d/textures/tex_harbor_cobble.png"
const TEX_FLEMISH_COBBLE := "res://assets/hd2d/textures/tex_flemish_cobble.png"
const TEX_MOSS := "res://assets/hd2d/textures/tex_fen_moss.png"
const TEX_DIRT := "res://assets/hd2d/textures/tex_fen_dirt.png"
const TEX_PEAT := "res://assets/hd2d/textures/tex_fen_peat.png"
const TEX_OAK := "res://assets/hd2d/textures/tex_oak_planks.png"
const TEX_TIMBER := "res://assets/hd2d/textures/tex_dark_timber.png"
const TEX_STONE := "res://assets/hd2d/textures/tex_weir_stone.png"
const TEX_BRICK := "res://assets/hd2d/textures/tex_flemish_brick.png"
const TEX_PLASTER := "res://assets/hd2d/textures/tex_plaster_timber.png"
const TEX_CLAY_ROOF := "res://assets/hd2d/textures/tex_clay_roof.png"
const TEX_SLATE_ROOF := "res://assets/hd2d/textures/tex_slate_roof.png"
const TEX_SAIL := "res://assets/hd2d/textures/tex_sail_canvas.png"
const TEX_HORIZON := "res://assets/hd2d/textures/tex_horizon_treeline.png"


static func ground_y_at(p2d: Vector2) -> float:
	if p2d.x < 224.0:
		return WATER_Y
	if p2d.x < 256.0:
		return 0.04
	return 0.0


static func to_3d(p2d: Vector2, y: float = 0.0) -> Vector3:
	return Vector3((p2d.x - ORIGIN_2D.x) / PX_PER_M, y, (p2d.y - ORIGIN_2D.y) / PX_PER_M)


static func build_diorama(root: Node3D, region_ref, assets_ref) -> Dictionary:
	var handles: Dictionary = {}
	handles["env_pack"] = HD2DLib.setup_diorama_environment(
		root,
		Color(0.14, 0.22, 0.36),
		Color(0.46, 0.42, 0.44),
		Color(0.28, 0.28, 0.34),
		0.95,
		Color(1.0, 0.90, 0.76),
		0.0048
	)

	_build_ground_and_water(root, handles)
	_build_harbor_architecture(root, assets_ref, handles)
	_build_merchant_cog(root, region_ref, handles)
	_build_harbor_props_and_foliage(root, region_ref, assets_ref, handles)
	return handles


static func _add_ground_slab(parent: Node3D, rect: Rect2, y_top: float, thickness: float, tex_path: String, uv_dens: float = 0.55, tint: Color = Color.WHITE) -> MeshInstance3D:
	var w: float = rect.size.x / PX_PER_M
	var d: float = rect.size.y / PX_PER_M
	var m := HD2DLib.make_textured_box(Vector3(w, thickness, d), tex_path, uv_dens, 0.90)
	if tint != Color.WHITE and m.material_override is StandardMaterial3D:
		(m.material_override as StandardMaterial3D).albedo_color = tint
	m.position = to_3d(rect.get_center(), y_top - thickness * 0.5)
	parent.add_child(m)
	return m


static func _build_ground_and_water(root: Node3D, _handles: Dictionary) -> void:
	# Deep Zwin seabed + animated sea channel (west & north-west waterfront)
	_add_ground_slab(root, Rect2(-320, -220, 580, 1440), -1.62, 0.40, TEX_PEAT, 0.45, Color(0.32, 0.40, 0.46))
	var water := HD2DLib.make_water_plane(Vector2(580.0 / PX_PER_M, 1440.0 / PX_PER_M), Color(0.04, 0.14, 0.22), Color(0.11, 0.28, 0.40), Color(0.36, 0.62, 0.72))
	water.position = to_3d(Vector2(-30.0, 500.0), WATER_Y)
	root.add_child(water)

	# Heavy Flemish cobble harbor plaza + sculpted museum diorama skirt
	_add_ground_slab(root, Rect2(256, -40, 1420, 1140), 0.0, 1.85, TEX_COBBLES, 0.58)
	_add_ground_slab(root, Rect2(228, -40, 32, 1140), 0.01, 1.80, TEX_STONE, 0.62, Color(0.84, 0.84, 0.88))

	# Weathered oak wharf deck along the quay edge + sunken oak pilings
	_add_ground_slab(root, Rect2(222, 0, 34, 1040), 0.045, 0.22, TEX_OAK, 0.65)
	for py in range(28, 1020, 72):
		var piling := HD2DLib.make_textured_cylinder(0.13, 0.15, 1.85, TEX_TIMBER, 0.75, 0.90)
		piling.position = to_3d(Vector2(223.0, float(py)), -0.68)
		root.add_child(piling)

	# Royal stone gatehouse avenue & meadow lawns matching PortOfBrugesDraw.gd
	_add_ground_slab(root, Rect2(660, 0, 120, 276), 0.025, 0.05, TEX_FLEMISH_COBBLE, 0.62, Color(1.06, 1.02, 0.96))
	_add_ground_slab(root, Rect2(928, 24, 640, 328), 0.02, 0.05, TEX_MOSS, 0.52, Color(0.92, 0.96, 0.86))
	_add_ground_slab(root, Rect2(1088, 608, 480, 384), 0.02, 0.05, TEX_MOSS, 0.52, Color(0.94, 0.98, 0.88))

	# Warm compacted earth garden & square paths
	_add_ground_slab(root, Rect2(880, 215, 620, 78), 0.015, 0.03, TEX_DIRT, 0.58)
	_add_ground_slab(root, Rect2(1068, 535, 360, 88), 0.015, 0.03, TEX_DIRT, 0.58)
	_add_ground_slab(root, Rect2(1262, 836, 98, 130), 0.015, 0.03, TEX_DIRT, 0.58)

	# Distant skyline silhouettes beyond Bruges ramparts & estuary
	for seg in [-12.0, 0.0, 12.0]:
		var card := Sprite3D.new()
		card.texture = HD2DLib.load_png(TEX_HORIZON)
		card.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		card.pixel_size = 0.068
		card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.modulate = Color(0.76, 0.80, 0.88, 0.86)
		card.position = Vector3(seg, 1.85, -14.8)
		root.add_child(card)


static func _build_stepped_gable_building(
	parent: Node3D,
	rect: Rect2,
	wall_h: float,
	roof_h: float,
	wall_tex: String,
	roof_tex: String,
	is_half_timber_upper: bool = false,
	add_chimney: bool = true,
	window_emissive: Color = Color(1.0, 0.72, 0.30)
) -> Node3D:
	var b := Node3D.new()
	b.position = to_3d(rect.get_center(), 0.0)
	parent.add_child(b)

	var w: float = rect.size.x / PX_PER_M
	var d: float = rect.size.y / PX_PER_M

	if is_half_timber_upper and wall_h >= 2.2:
		var low_h := wall_h * 0.52
		var up_h := wall_h * 0.48
		var lower := HD2DLib.make_textured_box(Vector3(w, low_h, d), TEX_BRICK, 0.65, 0.88)
		lower.position = Vector3(0.0, low_h * 0.5, 0.0)
		b.add_child(lower)
		var upper := HD2DLib.make_textured_box(Vector3(w + 0.14, up_h, d + 0.14), TEX_PLASTER, 0.62, 0.85)
		upper.position = Vector3(0.0, low_h + up_h * 0.5, 0.0)
		b.add_child(upper)
	else:
		var walls := HD2DLib.make_textured_box(Vector3(w, wall_h, d), wall_tex, 0.62, 0.88)
		walls.position = Vector3(0.0, wall_h * 0.5, 0.0)
		b.add_child(walls)

	# Dark stone plinth trim around foundation
	var plinth := HD2DLib.make_textured_box(Vector3(w + 0.14, 0.30, d + 0.14), TEX_STONE, 0.75, 0.92)
	plinth.position = Vector3(0.0, 0.15, 0.0)
	b.add_child(plinth)

	# Multi-tier pitched Flemish roof
	var tiers := 6
	var tier_h := roof_h / float(tiers)
	for ti in range(tiers):
		var frac := float(ti) / float(tiers)
		var span_z := (d + 0.44) * (1.0 - frac * 0.84)
		var slab := HD2DLib.make_textured_box(Vector3(w + 0.28, tier_h + 0.03, maxf(0.28, span_z)), roof_tex, 0.68, 0.84)
		slab.position = Vector3(0.0, wall_h + (float(ti) + 0.5) * tier_h, 0.0)
		b.add_child(slab)

	# Flemish crow-stepped brick gables (trapgevels) at West & East ends
	for gx in [-w * 0.5 - 0.08, w * 0.5 + 0.08]:
		for si in range(4):
			var sw := d * (0.82 - float(si) * 0.19)
			var sh := roof_h * 0.27
			var step_m := HD2DLib.make_textured_box(Vector3(0.22, sh, maxf(0.32, sw)), TEX_BRICK, 0.75, 0.88)
			step_m.position = Vector3(gx, wall_h + (float(si) + 0.45) * sh * 0.92, 0.0)
			b.add_child(step_m)

	# Front recessed oak door & protruding warm mullioned windows (pane proud of frame!)
	var door_f := HD2DLib.make_textured_box(Vector3(0.92, 1.62, 0.10), TEX_TIMBER, 0.85, 0.86)
	door_f.position = Vector3(0.0, 0.81, d * 0.5 + 0.02)
	b.add_child(door_f)

	var win_count := clampi(int(round(w / 1.95)), 2, 5)
	for wi in range(win_count):
		var wx := -w * 0.36 + (w * 0.72) * (float(wi) / maxf(1.0, float(win_count - 1)))
		if absf(wx) < 0.75 and win_count > 2:
			continue
		_add_glowing_window(b, Vector3(wx, wall_h * 0.56, d * 0.5), Vector2(0.56, 0.74), window_emissive)

	if add_chimney:
		var ch_x := -w * 0.28
		var ch_y := wall_h + roof_h * 0.65
		var chim := HD2DLib.make_textured_box(Vector3(0.52, roof_h * 0.85, 0.52), TEX_BRICK, 0.80, 0.90)
		chim.position = Vector3(ch_x, ch_y, -d * 0.16)
		b.add_child(chim)
		var smk := HD2DLib.make_smoke_particles(Vector3(0.22, 0.14, 0.22), 16)
		smk.position = Vector3(ch_x, ch_y + roof_h * 0.48, -d * 0.16)
		b.add_child(smk)

	return b


static func _add_glowing_window(parent: Node3D, wall_pos: Vector3, win_sz: Vector2, emit_col: Color) -> void:
	# Dark timber frame -> Glowing glass pane (+0.04m proud) -> Cross mullions (+0.07m proud)
	var frame := HD2DLib.make_color_box(Vector3(win_sz.x + 0.14, win_sz.y + 0.14, 0.05), Color(0.18, 0.12, 0.08), 0.86)
	frame.position = wall_pos + Vector3(0.0, 0.0, 0.025)
	parent.add_child(frame)

	var glass := HD2DLib.make_color_box(Vector3(win_sz.x, win_sz.y, 0.04), emit_col.darkened(0.25), 0.28, emit_col, 1.9, 0.05)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glass.position = wall_pos + Vector3(0.0, 0.0, 0.065)
	parent.add_child(glass)

	var v_bar := HD2DLib.make_color_box(Vector3(0.05, win_sz.y + 0.04, 0.04), Color(0.16, 0.10, 0.07), 0.86)
	v_bar.position = wall_pos + Vector3(0.0, 0.0, 0.095)
	parent.add_child(v_bar)
	var h_bar := HD2DLib.make_color_box(Vector3(win_sz.x + 0.04, 0.05, 0.04), Color(0.16, 0.10, 0.07), 0.86)
	h_bar.position = wall_pos + Vector3(0.0, 0.0, 0.095)
	parent.add_child(h_bar)


static func _build_harbor_architecture(root: Node3D, assets_ref, handles: Dictionary) -> void:
	# 1. Port Warehouse (364, 54, 288, 180)
	var wh := _build_stepped_gable_building(root, Rect2(364, 54, 288, 180), 3.1, 1.85, TEX_BRICK, TEX_CLAY_ROOF, false, true)
	var hoist_beam := HD2DLib.make_textured_box(Vector3(0.24, 0.24, 1.15), TEX_TIMBER, 0.90, 0.88)
	hoist_beam.position = Vector3(0.0, 3.05, (180.0 / PX_PER_M) * 0.5 + 0.42)
	wh.add_child(hoist_beam)

	# 2. Clara's Ropewalk (950, 44, 456, 154) with south rope-braiding awning
	var rw := _build_stepped_gable_building(root, Rect2(950, 44, 456, 154), 2.75, 1.70, TEX_BRICK, TEX_SLATE_ROOF, true, true)
	var rw_awning := HD2DLib.make_textured_box(Vector3(7.4, 0.12, 1.25), TEX_OAK, 0.72, 0.86)
	rw_awning.position = Vector3(0.0, 1.65, (154.0 / PX_PER_M) * 0.5 + 0.58)
	rw_awning.rotation_degrees.x = 12.0
	rw.add_child(rw_awning)

	# 3. Baker Pieter's Shop (718, 504, 156, 104) + Outdoor Domed Bread Oven (876, 550, 56, 46)
	var bk := _build_stepped_gable_building(root, Rect2(718, 504, 156, 104), 2.35, 1.55, TEX_PLASTER, TEX_CLAY_ROOF, true, true, Color(1.0, 0.64, 0.22))
	var bk_stall := HD2DLib.make_textured_box(Vector3(2.8, 0.10, 0.95), TEX_OAK, 0.75, 0.86)
	bk_stall.position = Vector3(0.0, 1.48, (104.0 / PX_PER_M) * 0.5 + 0.42)
	bk_stall.rotation_degrees.x = 14.0
	bk.add_child(bk_stall)

	var oven_rect := Rect2(876, 550, 56, 46)
	var oven_base := HD2DLib.make_textured_box(Vector3(1.15, 0.78, 0.96), TEX_STONE, 0.85, 0.90)
	oven_base.position = to_3d(oven_rect.get_center(), 0.39)
	root.add_child(oven_base)
	var oven_dome := HD2DLib.make_textured_cylinder(0.36, 0.52, 0.68, TEX_BRICK, 0.85, 0.88)
	oven_dome.position = to_3d(oven_rect.get_center(), 1.05)
	root.add_child(oven_dome)
	var oven_glow := HD2DLib.make_glow_bulb(to_3d(oven_rect.get_center() + Vector2(0, 18), 0.56), 0.16, Color(1.0, 0.46, 0.12), 3.4)
	root.add_child(oven_glow)
	handles["oven_glow_pos"] = oven_glow.position
	var oven_embers := HD2DLib.make_ember_particles(Vector3(0.24, 0.14, 0.24), 18)
	oven_embers.position = to_3d(oven_rect.get_center(), 1.45)
	root.add_child(oven_embers)

	# 4. Uncle Willem's Cottage (1214, 704, 196, 144)
	_build_stepped_gable_building(root, Rect2(1214, 704, 196, 144), 2.75, 1.75, TEX_BRICK, TEX_CLAY_ROOF, false, true, Color(1.0, 0.78, 0.36))
	handles["willem_door_pos"] = to_3d(Vector2(1312, 856), 1.45)

	# 5. Northern Flemish Harbor Ramparts & Gatehouses (North Gate x=720, NE Towpath x=1526)
	var wall_spans: Array = [
		Rect2(256, 0, 412, 34),
		Rect2(772, 0, 178, 34),
		Rect2(1406, 0, 74, 34),
		Rect2(1570, 0, 62, 34),
	]
	for wr: Rect2 in wall_spans:
		var wm := HD2DLib.make_textured_box(Vector3(wr.size.x / PX_PER_M, 2.25, wr.size.y / PX_PER_M), TEX_BRICK, 0.65, 0.88)
		wm.position = to_3d(wr.get_center(), 1.125)
		root.add_child(wm)

	for gx: float in [720.0, 1526.0]:
		for side: float in [-1.25, 1.25]:
			var tower := HD2DLib.make_textured_box(Vector3(0.86, 2.85, 0.86), TEX_BRICK, 0.72, 0.88)
			tower.position = to_3d(Vector2(gx, 28.0), 1.425) + Vector3(side, 0.0, 0.0)
			root.add_child(tower)
			var cap := HD2DLib.make_textured_box(Vector3(0.96, 0.55, 0.96), TEX_SLATE_ROOF, 0.75, 0.85)
			cap.position = tower.position + Vector3(0.0, 1.68, 0.0)
			root.add_child(cap)
		var arch_bridge := HD2DLib.make_textured_box(Vector3(2.35, 0.85, 0.84), TEX_BRICK, 0.72, 0.88)
		arch_bridge.position = to_3d(Vector2(gx, 28.0), 2.42)
		root.add_child(arch_bridge)
		var arch_cap := HD2DLib.make_textured_box(Vector3(2.55, 0.42, 0.96), TEX_SLATE_ROOF, 0.75, 0.85)
		arch_cap.position = to_3d(Vector2(gx, 28.0), 3.00)
		root.add_child(arch_cap)
		var keystone := HD2DLib.make_textured_box(Vector3(0.42, 0.34, 0.92), TEX_STONE, 0.80, 0.90)
		keystone.position = to_3d(Vector2(gx, 28.0), 2.08)
		root.add_child(keystone)
		for bi in [-0.46, 0.0, 0.46]:
			var bar := HD2DLib.make_color_box(Vector3(0.06, 0.36, 0.06), Color(0.18, 0.19, 0.22), 0.55, Color.BLACK, 0.0, 0.55)
			bar.position = to_3d(Vector2(gx, 28.0), 1.84) + Vector3(bi, 0.0, 0.0)
			root.add_child(bar)


static func _build_merchant_cog(root: Node3D, region_ref, handles: Dictionary) -> void:
	var ship := Node3D.new()
	ship.name = "MerchantCogDeZwaan"
	var spos: Vector2 = region_ref.ship_pos if region_ref != null else Vector2(140, 480)
	ship.position = to_3d(spos, WATER_Y + 0.08)
	root.add_child(ship)

	# Oak hull tiers + raised stern quarterdeck & forecastle
	var keel := HD2DLib.make_textured_box(Vector3(2.45, 0.95, 4.10), TEX_TIMBER, 0.60, 0.86)
	keel.position = Vector3(0.0, 0.35, 0.0)
	ship.add_child(keel)
	var deck := HD2DLib.make_textured_box(Vector3(2.25, 0.16, 3.85), TEX_OAK, 0.65, 0.84)
	deck.position = Vector3(0.0, 0.88, 0.0)
	ship.add_child(deck)
	var stern := HD2DLib.make_textured_box(Vector3(2.35, 0.72, 1.25), TEX_TIMBER, 0.65, 0.86)
	stern.position = Vector3(0.0, 1.24, 1.35)
	ship.add_child(stern)
	var bow := HD2DLib.make_textured_box(Vector3(1.55, 0.52, 0.95), TEX_TIMBER, 0.65, 0.86)
	bow.position = Vector3(0.0, 1.10, -2.15)
	ship.add_child(bow)

	# Tall mast, crow's nest & square stitched sailcloth
	var mast := HD2DLib.make_textured_cylinder(0.11, 0.15, 5.2, TEX_OAK, 0.75, 0.88)
	mast.position = Vector3(0.0, 3.2, -0.15)
	ship.add_child(mast)
	var yard := HD2DLib.make_textured_box(Vector3(3.35, 0.14, 0.14), TEX_OAK, 0.80, 0.86)
	yard.position = Vector3(0.0, 4.55, -0.15)
	ship.add_child(yard)

	var sail := HD2DLib.make_textured_box(Vector3(2.95, 2.55, 0.08), TEX_SAIL, 0.45, 0.92)
	sail.position = Vector3(0.0, 3.25, -0.02)
	ship.add_child(sail)

	var ship_crate := HD2DLib.make_textured_box(Vector3(0.58, 0.54, 0.58), TEX_OAK, 0.85, 0.88)
	ship_crate.position = Vector3(-20.0 / PX_PER_M, 1.23, 44.0 / PX_PER_M)
	ship.add_child(ship_crate)

	var stern_post := HD2DLib.make_color_box(Vector3(0.08, 0.36, 0.08), Color(0.16, 0.14, 0.14), 0.75)
	stern_post.position = Vector3(0.55, 1.74, 1.72)
	ship.add_child(stern_post)
	var stern_cap := HD2DLib.make_color_box(Vector3(0.22, 0.06, 0.22), Color(0.18, 0.16, 0.16), 0.65)
	stern_cap.position = Vector3(0.55, 2.02, 1.72)
	ship.add_child(stern_cap)
	var stern_bulb := HD2DLib.make_glow_bulb(Vector3(0.55, 1.92, 1.72), 0.085, Color(1.0, 0.78, 0.36), 2.4)
	ship.add_child(stern_bulb)

	var gangplank := HD2DLib.make_textured_box(Vector3(1.55, 0.12, 0.78), TEX_OAK, 0.78, 0.88)
	gangplank.position = to_3d(Vector2(236, 480), 0.16)
	gangplank.visible = bool(region_ref.gangplank_deployed) if region_ref != null else false
	root.add_child(gangplank)

	var moor_line := HD2DLib.make_color_box(Vector3(0.06, 0.06, 1.0), Color(0.76, 0.62, 0.36), 0.86)
	moor_line.visible = GameState.ship_moored
	root.add_child(moor_line)

	handles["ship"] = ship
	handles["ship_sail"] = sail
	handles["ship_crate"] = ship_crate
	handles["ship_moor_line"] = moor_line
	handles["gangplank"] = gangplank


static func _build_harbor_props_and_foliage(root: Node3D, region_ref, assets_ref, handles: Dictionary) -> void:
	# Church Inquisitor's Wooden Pulpit (744, 290, 112, 64)
	var pulpit_base := HD2DLib.make_textured_box(Vector3(2.30, 0.64, 1.32), TEX_TIMBER, 0.75, 0.86)
	pulpit_base.position = to_3d(Vector2(800, 322), 0.32)
	root.add_child(pulpit_base)
	var pulpit_spr := HD2DLib.make_sprite3d(assets_ref.get_tex("prop_church_pulpit.png"), "prop_church_pulpit.png", 0.050)
	pulpit_spr.position = to_3d(Vector2(800, 318), 0.64)
	root.add_child(pulpit_spr)

	# Fixed Bruges landmarks (Rigging post, Noticeboard, Milestone, Flour sacks, Barrels)
	var fixed_props: Array = [
		{"tex": "prop_rigging_post.png", "pos": region_ref.HARBOUR_RIGGING_POST if region_ref != null else Vector2(1018, 286), "ps": 0.052},
		{"tex": "prop_noticeboard.png", "pos": region_ref.NOTICEBOARD_POS if region_ref != null else Vector2(462, 312), "ps": 0.050},
		{"tex": "prop_milestone.png", "pos": Vector2(1463, 258), "ps": 0.052},
		{"tex": "prop_rope_windlass.png", "pos": Vector2(1110, 224), "ps": 0.050},
		{"tex": "prop_flour_sack_stack.png", "pos": Vector2(746, 616), "ps": 0.046},
		{"tex": "prop_flour_sack_stack.png", "pos": Vector2(852, 616), "ps": 0.046},
		{"tex": "prop_barrel.png", "pos": Vector2(396, 250), "ps": 0.048},
		{"tex": "prop_barrel.png", "pos": Vector2(422, 260), "ps": 0.048},
		{"tex": "prop_crate.png", "pos": Vector2(612, 248), "ps": 0.048},
		{"tex": "prop_stall_food.png", "pos": Vector2(656, 608), "ps": 0.052},
		{"tex": "prop_stall_gear.png", "pos": Vector2(968, 262), "ps": 0.052},
	]
	for fp: Dictionary in fixed_props:
		var pspr := HD2DLib.make_sprite3d(assets_ref.get_tex(fp["tex"]), fp["tex"], float(fp["ps"]))
		var p2: Vector2 = fp["pos"]
		pspr.position = to_3d(p2, ground_y_at(p2))
		root.add_child(pspr)

	# Wharf iron bollards
	var bollards: Array = region_ref.WHARF_BOLLARDS if region_ref != null else [Vector2(246, 300), Vector2(246, 510), Vector2(246, 720)]
	for bp in bollards:
		var b_post := HD2DLib.make_textured_cylinder(0.11, 0.14, 0.56, TEX_TIMBER, 0.85, 0.88)
		b_post.position = to_3d(Vector2(bp), 0.30)
		root.add_child(b_post)

	# Toggleable quest props: Twine cache, Drifted harbor crate, Bobbing shuttle pouch
	var twine_p: Vector2 = region_ref.TWINE_CACHE_POS if region_ref != null else Vector2(624, 654)
	var twine_spr := HD2DLib.make_sprite3d(assets_ref.get_tex("prop_twine_cache.png"), "prop_twine_cache.png", 0.050)
	twine_spr.position = to_3d(twine_p, 0.02)
	root.add_child(twine_spr)
	handles["twine_cache"] = twine_spr

	var crate_p: Vector2 = region_ref.DRIFTED_CRATE_POS if region_ref != null else Vector2(142, 742)
	var drifted_crate := HD2DLib.make_sprite3d(assets_ref.get_tex("prop_crate.png"), "prop_crate.png", 0.050)
	drifted_crate.position = to_3d(crate_p, WATER_Y + 0.05)
	root.add_child(drifted_crate)
	handles["drifted_crate"] = drifted_crate

	var pouch_p: Vector2 = region_ref.BOBBING_POUCH_POS if region_ref != null else Vector2(168, 224)
	var pouch_spr := HD2DLib.make_sprite3d(assets_ref.get_tex("prop_shuttle_pouch.png"), "prop_shuttle_pouch.png", 0.048)
	pouch_spr.position = to_3d(pouch_p, WATER_Y + 0.06)
	root.add_child(pouch_spr)
	handles["bobbing_pouch"] = pouch_spr

	# Lime & oak trees around Ropewalk lawn & Uncle Willem's cottage garden
	var tree_spots: Array[Vector2] = [
		Vector2(986, 206), Vector2(1438, 188), Vector2(1514, 294),
		Vector2(1178, 728), Vector2(1468, 694), Vector2(1506, 876), Vector2(1148, 922),
	]
	for tp: Vector2 in tree_spots:
		var ts := HD2DLib.make_sprite3d(assets_ref.get_tex("prop_lime_tree.png"), "prop_lime_tree.png", 0.064)
		ts.position = to_3d(tp, ground_y_at(tp))
		root.add_child(ts)

	# Bruges iron lantern posts -> bulb visuals + candidate specs for 6-slot light pooler
	var lantern_pts: Array[Vector2] = [
		Vector2(278, 286), Vector2(278, 520), Vector2(278, 760),
		Vector2(548, 266), Vector2(686, 128), Vector2(772, 128),
		Vector2(972, 224), Vector2(1248, 224), Vector2(736, 560),
		Vector2(868, 560), Vector2(1264, 868), Vector2(1476, 136),
	]
	var lspecs: Array = []
	for li in range(lantern_pts.size()):
		var lp: Vector2 = lantern_pts[li]
		var lspr := HD2DLib.make_sprite3d(assets_ref.get_tex("prop_lantern.png"), "prop_lantern.png", 0.046)
		lspr.position = to_3d(lp, ground_y_at(lp))
		root.add_child(lspr)
		var bpos := to_3d(lp, 1.38)
		var bulb := HD2DLib.make_glow_bulb(bpos, 0.10, Color(1.0, 0.80, 0.40), 2.5)
		root.add_child(bulb)
		lspecs.append({
			"pos": bpos,
			"bulb": bulb,
			"color": Color(1.0, 0.78, 0.38),
			"energy": 2.45,
			"range": 7.8,
			"attenuation": 1.55,
			"flicker_phase": float(li) * 1.15,
			"flicker_amp": 0.07,
		})
	handles["lantern_specs"] = lspecs
