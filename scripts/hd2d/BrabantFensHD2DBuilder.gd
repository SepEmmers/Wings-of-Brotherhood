extends RefCounted

## Builds the 67.5m x 45.0m Octopath-style 3D diorama for Brabant Reed-Fens (`brabant_fens`).
## Maps 1:1 from 2D world coordinates (`PX_PER_M = 32.0`) with strict non-Z-fighting height
## separation, Flemish stepped-gable watermill, animated portcullis, culvert & dynamic lights.

const HD2DLib := preload("res://scripts/hd2d/HD2DStageBuilder.gd")
const BrabantFensDrawScript := preload("res://scripts/regions/BrabantFensDraw.gd")

const PX_PER_M := 32.0
const TEX_DIR := "res://assets/hd2d/textures/"


static func to_3d(p2d: Vector2, y_h: float = 0.0) -> Vector3:
	return Vector3(p2d.x / PX_PER_M, y_h, p2d.y / PX_PER_M)


static func ground_y_at(p2d: Vector2) -> float:
	if Rect2(140, 646, 172, 128).has_point(p2d) or Rect2(1732, 656, 144, 114).has_point(p2d):
		return 0.16
	if Rect2(760, 430, 598, 430).has_point(p2d):
		return 0.065
	for seg: Rect2 in BrabantFensDrawScript.get_road_segments():
		if seg.has_point(p2d):
			return 0.035
	return 0.0


static func build_diorama(root: Node3D, region, assets) -> Dictionary:
	var flicker_lights: Array[Dictionary] = []

	var env_pack: Dictionary = HD2DLib.setup_diorama_environment(
		root,
		Color(0.11, 0.15, 0.27),
		Color(0.28, 0.34, 0.48),
		Color(0.14, 0.19, 0.30),
		1.15,
		Color(0.84, 0.90, 1.0),
		0.0065
	)

	_build_terrain_and_water(root)
	var mill_handles := _build_watermill_cottage(root, region, flicker_lights)
	var sluice_handles := _build_sluice_weir(root, region, assets, flicker_lights)
	_build_bridges_and_gates(root, assets, flicker_lights)
	var prop_handles := _build_props_and_flora(root, region, assets, flicker_lights)
	_build_horizon_and_weather(root, assets)

	var out := {
		"env_pack": env_pack,
		"flicker_lights": flicker_lights,
	}
	out.merge(mill_handles)
	out.merge(sluice_handles)
	out.merge(prop_handles)
	return out


static func _place_rect_box(root: Node3D, rect2d: Rect2, y_top: float, height: float, tex_name: String, uv_density: float = 0.50, rough: float = 0.90) -> MeshInstance3D:
	var w: float = rect2d.size.x / PX_PER_M
	var d: float = rect2d.size.y / PX_PER_M
	var cx: float = (rect2d.position.x + rect2d.size.x * 0.5) / PX_PER_M
	var cz: float = (rect2d.position.y + rect2d.size.y * 0.5) / PX_PER_M
	var mi: MeshInstance3D = HD2DLib.make_textured_box(Vector3(w, height, d), TEX_DIR + tex_name, uv_density, rough)
	mi.position = Vector3(cx, y_top - height * 0.5, cz)
	root.add_child(mi)
	return mi


static func _build_terrain_and_water(root: Node3D) -> void:
	# Layer 0 (y = -0.34): Shimmering quantized fen marsh & canal water
	var water := HD2DLib.make_water_plane(
		Vector2(130.0, 100.0),
		Color(0.05, 0.13, 0.21),
		Color(0.11, 0.25, 0.34),
		Color(0.58, 0.72, 0.80)
	)
	water.position = Vector3(34.0, -0.34, 22.5)
	root.add_child(water)

	# Layer 1 (y_top = -0.08): Dark wet peat riverbank borders around both islands
	_place_rect_box(root, Rect2(114, 232, 1644, 866), -0.08, 0.34, "tex_fen_peat.png", 0.45, 0.94)
	_place_rect_box(root, Rect2(1852, 232, 820, 866), -0.08, 0.34, "tex_fen_peat.png", 0.45, 0.94)

	# Layer 2 (y_top = 0.00): Main West fenland island & East Louvain bank
	_place_rect_box(root, Rect2(132, 250, 1608, 830), 0.00, 0.40, "tex_fen_moss.png", 0.42, 0.94)
	_place_rect_box(root, Rect2(1868, 250, 780, 830), 0.00, 0.40, "tex_fen_moss.png", 0.42, 0.94)

	# Layer 3 (y_top = 0.035): Dirt dike trails from BrabantFensDraw
	for seg: Rect2 in BrabantFensDrawScript.get_road_segments():
		_place_rect_box(root, seg, 0.035, 0.07, "tex_fen_dirt.png", 0.52, 0.92)

	# Layer 4 (y_top = 0.065): Mill cobblestone courtyard + low stone curb borders
	var apron := Rect2(760, 430, 598, 430)
	_place_rect_box(root, apron, 0.065, 0.07, "tex_flemish_cobble.png", 0.58, 0.88)
	for curb: Rect2 in [
		Rect2(756, 426, 606, 10),
		Rect2(756, 854, 606, 10),
		Rect2(756, 436, 10, 418),
	]:
		_place_rect_box(root, curb, 0.11, 0.12, "tex_weir_stone.png", 0.70, 0.90)


static func _build_watermill_cottage(root: Node3D, region, flicker_lights: Array[Dictionary]) -> Dictionary:
	var mr: Rect2 = region.MILL_COTTAGE_RECT
	var cx: float = (mr.position.x + mr.size.x * 0.5) / PX_PER_M
	var cz: float = (mr.position.y + mr.size.y * 0.5) / PX_PER_M
	var mill := Node3D.new()
	mill.position = Vector3(cx, 0.065, cz)
	root.add_child(mill)

	# Stone foundation plinth & half-timbered wattle-and-daub body
	var plinth := HD2DLib.make_textured_box(Vector3(4.55, 0.65, 3.65), TEX_DIR + "tex_weir_stone.png", 0.65, 0.90)
	plinth.position = Vector3(0.0, 0.325, 0.0)
	mill.add_child(plinth)

	var body := HD2DLib.make_textured_box(Vector3(4.35, 1.95, 3.45), TEX_DIR + "tex_plaster_timber.png", 0.55, 0.88)
	body.position = Vector3(0.0, 1.625, 0.0)
	mill.add_child(body)

	# Flemish stepped brick/stone trapgevel gable facing South (+Z) & North (-Z)
	for g_dir in [-1.0, 1.0]:
		var gz: float = g_dir * 1.72
		for tier in [[3.8, 0.45, 2.82], [2.7, 0.45, 3.27], [1.6, 0.45, 3.72], [0.7, 0.40, 4.14]]:
			var step_b := HD2DLib.make_textured_box(Vector3(tier[0], tier[1], 0.24), TEX_DIR + "tex_weir_stone.png", 0.70, 0.90)
			step_b.position = Vector3(0.0, tier[2], gz)
			mill.add_child(step_b)

	# Twin pitched red-clay tile roof slopes + dark oak ridge beam
	for side in [-1.0, 1.0]:
		var slope := HD2DLib.make_textured_box(Vector3(2.85, 0.22, 4.10), TEX_DIR + "tex_clay_roof.png", 0.65, 0.86)
		slope.position = Vector3(side * 1.24, 3.32, 0.0)
		slope.rotation_degrees.z = -side * 38.0
		mill.add_child(slope)

	var ridge := HD2DLib.make_textured_box(Vector3(0.28, 0.26, 4.20), TEX_DIR + "tex_dark_timber.png", 0.70, 0.86)
	ridge.position = Vector3(0.0, 4.20, 0.0)
	mill.add_child(ridge)

	# Oak door, threshold step & glowing amber mullioned windows
	var step_stone := HD2DLib.make_textured_box(Vector3(1.35, 0.18, 0.65), TEX_DIR + "tex_weir_stone.png", 0.75, 0.90)
	step_stone.position = Vector3(0.0, 0.09, 1.98)
	mill.add_child(step_stone)
	var door := HD2DLib.make_textured_box(Vector3(0.95, 1.65, 0.14), TEX_DIR + "tex_dark_timber.png", 0.75, 0.86)
	door.position = Vector3(0.0, 0.92, 1.76)
	mill.add_child(door)

	for wx in [-1.25, 1.25]:
		var frame := HD2DLib.make_textured_box(Vector3(0.92, 0.88, 0.16), TEX_DIR + "tex_dark_timber.png", 0.8, 0.86)
		frame.position = Vector3(wx, 1.50, 1.75)
		mill.add_child(frame)
		var pane := HD2DLib.make_color_box(Vector3(0.72, 0.68, 0.14), Color(0.96, 0.72, 0.30), 0.30, Color(1.0, 0.72, 0.28), 1.05)
		pane.position = Vector3(wx, 1.50, 1.80)
		mill.add_child(pane)
		var mull_v := HD2DLib.make_textured_box(Vector3(0.09, 0.72, 0.08), TEX_DIR + "tex_dark_timber.png", 0.8)
		mull_v.position = Vector3(wx, 1.50, 1.85)
		mill.add_child(mull_v)
		var mull_h := HD2DLib.make_textured_box(Vector3(0.76, 0.09, 0.08), TEX_DIR + "tex_dark_timber.png", 0.8)
		mull_h.position = Vector3(wx, 1.50, 1.85)
		mill.add_child(mull_h)

	# Porch warm OmniLight3D (#2 of 7)
	var porch_lgt := OmniLight3D.new()
	porch_lgt.position = Vector3(0.0, 1.65, 2.55)
	porch_lgt.light_color = Color(1.0, 0.76, 0.40)
	porch_lgt.light_energy = 1.05
	porch_lgt.omni_range = 6.5
	mill.add_child(porch_lgt)
	flicker_lights.append({"light": porch_lgt, "base": 1.05, "phase": 2.4})

	# Chimney stack & slow smoke drift
	var chimney := HD2DLib.make_textured_box(Vector3(0.72, 1.60, 0.72), TEX_DIR + "tex_weir_stone.png", 0.75, 0.90)
	chimney.position = Vector3(1.35, 4.10, -0.75)
	mill.add_child(chimney)
	var smoke := HD2DLib.make_smoke_particles(Vector3(0.20, 0.14, 0.20), 22)
	smoke.position = Vector3(1.35, 5.00, -0.75)
	mill.add_child(smoke)

	# Rotating 3D Spoked Waterwheel on West wall
	var wheel := Node3D.new()
	wheel.position = Vector3(-2.38, 1.05, 0.10)
	mill.add_child(wheel)
	var axle := HD2DLib.make_textured_cylinder(0.14, 0.14, 0.90, TEX_DIR + "tex_dark_timber.png", 0.8)
	axle.rotation_degrees.z = 90.0
	wheel.add_child(axle)
	for si in range(4):
		var spoke := HD2DLib.make_textured_box(Vector3(0.32, 2.15, 0.16), TEX_DIR + "tex_dark_timber.png", 0.75)
		spoke.rotation_degrees.x = float(si) * 45.0
		wheel.add_child(spoke)
	for ri in range(8):
		var ang := float(ri) * TAU / 8.0
		var rim := HD2DLib.make_textured_box(Vector3(0.40, 0.16, 0.88), TEX_DIR + "tex_oak_planks.png", 0.75)
		rim.position = Vector3(0.0, cos(ang) * 1.02, sin(ang) * 1.02)
		rim.rotation.x = ang
		wheel.add_child(rim)

	return {"waterwheel": wheel}


static func _build_sluice_weir(root: Node3D, region, assets, flicker_lights: Array[Dictionary]) -> Dictionary:
	# North wall split around the vaulted culvert at VENT_POS (y = 554 -> 534..574)
	_place_rect_box(root, Rect2(1352, 240, 52, 294), 2.55, 2.55, "tex_weir_stone.png", 0.55)
	_place_rect_box(root, Rect2(1352, 574, 52, 72), 2.55, 2.55, "tex_weir_stone.png", 0.55)
	_place_rect_box(root, Rect2(1352, 774, 52, 316), 2.55, 2.55, "tex_weir_stone.png", 0.55)
	# Lintel stone above the drainage culvert void (y: 534..574)
	_place_rect_box(root, Rect2(1352, 534, 52, 40), 2.55, 1.55, "tex_weir_stone.png", 0.65)
	# Coping capstones
	_place_rect_box(root, Rect2(1346, 238, 64, 410), 2.73, 0.18, "tex_weir_stone.png", 0.65)
	_place_rect_box(root, Rect2(1346, 772, 64, 320), 2.73, 0.18, "tex_weir_stone.png", 0.65)

	# Recessed dark vaulted culvert tunnel + 3 iron grate bars + subtle gold glint
	var vent_pos: Vector3 = to_3d(region.VENT_POS, 0.0)
	var tunnel := HD2DLib.make_color_box(Vector3(1.66, 0.92, 1.15), Color(0.06, 0.06, 0.08), 0.95)
	tunnel.position = Vector3(vent_pos.x, 0.46, vent_pos.z)
	root.add_child(tunnel)
	for bz in [-0.30, 0.0, 0.30]:
		var bar := HD2DLib.make_color_box(Vector3(0.08, 0.90, 0.08), Color(0.24, 0.26, 0.30), 0.55, Color.BLACK, 0.0, 0.45)
		bar.position = Vector3(vent_pos.x - 0.82, 0.46, vent_pos.z + bz)
		root.add_child(bar)
	var vent_glint := HD2DLib.make_ember_particles(Vector3(0.18, 0.18, 0.25), 14)
	vent_glint.position = Vector3(vent_pos.x - 1.05, 0.45, vent_pos.z)
	root.add_child(vent_glint)

	# Gatehouse piers & overhead archway lintel spanning GATE_RECT
	var gr: Rect2 = region.GATE_RECT
	var gx: float = (gr.position.x + gr.size.x * 0.5) / PX_PER_M
	var gz: float = (gr.position.y + gr.size.y * 0.5) / PX_PER_M
	for pz in [gr.position.y / PX_PER_M - 0.55, gr.end.y / PX_PER_M + 0.55]:
		var pier := HD2DLib.make_textured_box(Vector3(2.10, 3.60, 1.30), TEX_DIR + "tex_weir_stone.png", 0.58)
		pier.position = Vector3(gx, 1.80, pz)
		root.add_child(pier)
		var cap := HD2DLib.make_textured_box(Vector3(2.35, 0.32, 1.55), TEX_DIR + "tex_slate_roof.png", 0.65)
		cap.position = Vector3(gx, 3.76, pz)
		root.add_child(cap)
	var arch_lintel := HD2DLib.make_textured_box(Vector3(1.90, 0.85, 4.40), TEX_DIR + "tex_weir_stone.png", 0.60)
	arch_lintel.position = Vector3(gx, 2.95, gz)
	root.add_child(arch_lintel)
	# Barbican masonry housing & slate parapet above gatehouse so raised portcullis nestles cleanly inside
	var barbican := HD2DLib.make_textured_box(Vector3(1.70, 1.45, 4.20), TEX_DIR + "tex_weir_stone.png", 0.60)
	barbican.position = Vector3(gx, 4.10, gz)
	root.add_child(barbican)
	var barbican_cap := HD2DLib.make_textured_box(Vector3(1.92, 0.28, 4.42), TEX_DIR + "tex_slate_roof.png", 0.65)
	barbican_cap.position = Vector3(gx, 4.96, gz)
	root.add_child(barbican_cap)

	# Hanging warm archway lantern (#3 of 7)
	root.add_child(HD2DLib.make_glow_bulb(Vector3(gx - 0.85, 2.38, gz), 0.13))
	var gate_lgt := OmniLight3D.new()
	gate_lgt.position = Vector3(gx - 1.15, 2.30, gz)
	gate_lgt.light_color = Color(1.0, 0.78, 0.44)
	gate_lgt.light_energy = 2.4
	gate_lgt.omni_range = 8.5
	root.add_child(gate_lgt)
	flicker_lights.append({"light": gate_lgt, "base": 2.4, "phase": 0.9})

	# Animated 3D Forged-Iron Portcullis inside GATE_RECT
	var portcullis := Node3D.new()
	portcullis.position = Vector3(gx, 0.035, gz)
	root.add_child(portcullis)
	for bz in [-1.50, -0.75, 0.0, 0.75, 1.50]:
		var spear := HD2DLib.make_color_box(Vector3(0.14, 2.50, 0.14), Color(0.24, 0.26, 0.30), 0.50, Color.BLACK, 0.0, 0.55)
		spear.position = Vector3(0.0, 1.25, bz)
		portcullis.add_child(spear)
	for by in [0.45, 1.25, 2.05]:
		var crossbar := HD2DLib.make_color_box(Vector3(0.16, 0.12, 3.75), Color(0.20, 0.22, 0.26), 0.52, Color.BLACK, 0.0, 0.50)
		crossbar.position = Vector3(0.0, by, 0.0)
		portcullis.add_child(crossbar)

	# Medieval Iron Ratchet Lever on East masonry face
	var lp: Vector3 = to_3d(region.LEVER_POS, 0.035)
	var base_blk := HD2DLib.make_textured_box(Vector3(0.55, 0.48, 0.55), TEX_DIR + "tex_weir_stone.png", 0.8)
	base_blk.position = lp + Vector3(0.0, 0.24, 0.0)
	root.add_child(base_blk)
	var lever_arm := Node3D.new()
	lever_arm.position = lp + Vector3(0.0, 0.48, 0.0)
	root.add_child(lever_arm)
	var shaft := HD2DLib.make_color_box(Vector3(0.10, 0.85, 0.10), Color(0.44, 0.46, 0.52), 0.45, Color.BLACK, 0.0, 0.65)
	shaft.position = Vector3(0.0, 0.42, 0.0)
	lever_arm.add_child(shaft)
	var knob := HD2DLib.make_color_box(Vector3(0.22, 0.16, 0.22), Color(0.84, 0.68, 0.30), 0.40, Color.BLACK, 0.0, 0.70)
	knob.position = Vector3(0.0, 0.86, 0.0)
	lever_arm.add_child(knob)

	var chain := HD2DLib.make_color_box(Vector3(0.07, 0.07, 1.35), Color(0.32, 0.34, 0.38), 0.50, Color.BLACK, 0.0, 0.60)
	chain.position = lp + Vector3(-0.35, 0.75, 0.45)
	chain.rotation_degrees = Vector3(25.0, -24.0, 0.0)
	root.add_child(chain)

	return {"portcullis": portcullis, "lever_arm": lever_arm, "vent_glint": vent_glint}


static func _build_bridges_and_gates(root: Node3D, assets, flicker_lights: Array[Dictionary]) -> void:
	# West timber landing pier & East wooden weir bridge (y_top = 0.16)
	var pier_r := Rect2(140, 646, 172, 128)
	var bridge_r := Rect2(1732, 656, 144, 114)
	for dr: Rect2 in [pier_r, bridge_r]:
		_place_rect_box(root, dr, 0.16, 0.18, "tex_oak_planks.png", 0.58, 0.84)
		for cx in [dr.position.x + 12.0, dr.end.x - 12.0]:
			for cz in [dr.position.y + 12.0, dr.end.y - 12.0]:
				var pile := HD2DLib.make_textured_cylinder(0.16, 0.18, 0.90, TEX_DIR + "tex_dark_timber.png", 0.75)
				pile.position = to_3d(Vector2(cx, cz), -0.32)
				root.add_child(pile)

	# Oak guard rails on North & South edges of East Weir Bridge
	for rz in [bridge_r.position.y + 6.0, bridge_r.end.y - 6.0]:
		var rail := HD2DLib.make_textured_box(Vector3(bridge_r.size.x / PX_PER_M, 0.12, 0.14), TEX_DIR + "tex_dark_timber.png", 0.75)
		rail.position = to_3d(Vector2(bridge_r.get_center().x, rz), 0.62)
		root.add_child(rail)
		for rx in [bridge_r.position.x + 14.0, bridge_r.get_center().x, bridge_r.end.x - 14.0]:
			var post := HD2DLib.make_textured_box(Vector3(0.16, 0.55, 0.16), TEX_DIR + "tex_dark_timber.png", 0.75)
			post.position = to_3d(Vector2(rx, rz), 0.42)
			root.add_child(post)

	# Pier bollards, rope coil & bridge lantern (#4 of 7)
	for bp in [Vector2(162, 668), Vector2(162, 752), Vector2(288, 668)]:
		var bol := HD2DLib.make_sprite3d(assets.get_tex("prop_bollard.png"), "prop_bollard.png", 0.054)
		bol.position = to_3d(bp, 0.16)
		root.add_child(bol)
	var coil := HD2DLib.make_sprite3d(assets.get_tex("prop_rope_coil.png"), "prop_rope_coil.png", 0.050)
	coil.position = to_3d(Vector2(280, 744), 0.16)
	root.add_child(coil)

	var bl_pos := to_3d(Vector2(1752, 664), 0.16)
	var lan := HD2DLib.make_sprite3d(assets.get_tex("prop_lantern.png"), "prop_lantern.png", 0.058)
	lan.position = bl_pos
	root.add_child(lan)
	root.add_child(HD2DLib.make_glow_bulb(bl_pos + Vector3(0.0, 1.05, 0.06), 0.12))
	var bridge_lgt := OmniLight3D.new()
	bridge_lgt.position = bl_pos + Vector3(0.0, 1.25, 0.30)
	bridge_lgt.light_color = Color(1.0, 0.80, 0.46)
	bridge_lgt.light_energy = 2.2
	bridge_lgt.omni_range = 8.0
	root.add_child(bridge_lgt)
	flicker_lights.append({"light": bridge_lgt, "base": 2.2, "phase": 3.7})

	# Distant East Louvain Gatehouse Bastion Towers & Crimson Banners (#5 of 7)
	for wy in [594.0, 774.0]:
		var tp := to_3d(Vector2(2116, wy + 34), 0.0)
		var twr := HD2DLib.make_textured_cylinder(1.15, 1.28, 4.4, TEX_DIR + "tex_weir_stone.png", 0.58)
		twr.position = tp + Vector3(0.0, 2.2, 0.0)
		root.add_child(twr)
		var roof := HD2DLib.make_textured_cylinder(0.14, 1.48, 1.85, TEX_DIR + "tex_slate_roof.png", 0.65)
		roof.position = tp + Vector3(0.0, 5.3, 0.0)
		root.add_child(roof)
		var banner := HD2DLib.make_color_box(Vector3(0.14, 1.35, 0.65), Color(0.62, 0.12, 0.14), 0.82)
		banner.position = tp + Vector3(-1.26, 2.15, 0.0)
		root.add_child(banner)
		root.add_child(HD2DLib.make_glow_bulb(tp + Vector3(-1.35, 1.65, 0.0), 0.12, Color(1.0, 0.56, 0.26), 2.5))

	var east_arch := HD2DLib.make_textured_box(Vector3(1.6, 0.95, 4.8), TEX_DIR + "tex_weir_stone.png", 0.58)
	east_arch.position = to_3d(Vector2(2116, 718), 3.75)
	root.add_child(east_arch)
	var east_lgt := OmniLight3D.new()
	east_lgt.position = to_3d(Vector2(2056, 718), 1.85)
	east_lgt.light_color = Color(1.0, 0.60, 0.30)
	east_lgt.light_energy = 2.5
	east_lgt.omni_range = 9.0
	root.add_child(east_lgt)
	flicker_lights.append({"light": east_lgt, "base": 2.5, "phase": 5.1})


static func _build_props_and_flora(root: Node3D, region, assets, flicker_lights: Array[Dictionary]) -> Dictionary:
	# Mill Campfire (Shadow-free warm fill #1 of 7) + stones + embers + egg/shards
	var camp_pos: Vector3 = to_3d(region.CAMPFIRE_POS, 0.065)
	for si in range(8):
		var a := float(si) * TAU / 8.0
		var st := HD2DLib.make_textured_box(Vector3(0.24, 0.16, 0.20), TEX_DIR + "tex_weir_stone.png", 0.85)
		st.position = camp_pos + Vector3(cos(a) * 0.52, 0.07, sin(a) * 0.44)
		st.rotation.y = a
		root.add_child(st)
	var campfire_spr := HD2DLib.make_sprite3d(assets.get_tex("prop_campfire_0.png"), "prop_campfire_0.png", 0.056, false, 0.50)
	campfire_spr.position = camp_pos
	root.add_child(campfire_spr)
	var camp_lgt := OmniLight3D.new()
	camp_lgt.position = camp_pos + Vector3(0.0, 1.25, 0.25)
	camp_lgt.light_color = Color(1.0, 0.56, 0.18)
	camp_lgt.light_energy = 2.65
	camp_lgt.omni_range = 12.5
	root.add_child(camp_lgt)
	flicker_lights.append({"light": camp_lgt, "base": 2.65, "phase": 1.3})
	var camp_embers := HD2DLib.make_ember_particles(Vector3(0.28, 0.18, 0.24), 32)
	camp_embers.position = camp_pos + Vector3(0.0, 0.42, 0.0)
	root.add_child(camp_embers)

	var nest_pos := to_3d(region.CAMPFIRE_POS + Vector2(38, 8), 0.065)
	var egg_spr := HD2DLib.make_sprite3d(assets.get_tex("prop_dragon_egg.png"), "prop_dragon_egg.png", 0.050, true, 0.45)
	egg_spr.position = nest_pos
	egg_spr.visible = false
	root.add_child(egg_spr)
	var shards_spr := HD2DLib.make_sprite3d(assets.get_tex("prop_dragon_egg_shards.png"), "prop_dragon_egg_shards.png", 0.050, false)
	shards_spr.position = nest_pos
	shards_spr.visible = false
	root.add_child(shards_spr)

	# Twin Stone Way-Braziers (#6 and #7 of 7; hidden until lit)
	var brazier_nodes: Array[Dictionary] = []
	for bi in range(region.brazier_states.size()):
		var bp2d: Vector2 = region.brazier_states[bi]["pos"]
		var bp := to_3d(bp2d, ground_y_at(bp2d))
		var b_spr := HD2DLib.make_sprite3d(assets.get_tex("prop_wall_brazier.png"), "prop_wall_brazier.png", 0.056)
		b_spr.position = bp
		root.add_child(b_spr)
		var bulb := HD2DLib.make_glow_bulb(bp + Vector3(0.0, 1.05, 0.06), 0.14, Color(1.0, 0.72, 0.24), 2.8)
		bulb.visible = false
		root.add_child(bulb)
		var blgt := OmniLight3D.new()
		blgt.position = bp + Vector3(0.0, 1.25, 0.20)
		blgt.light_color = Color(1.0, 0.68, 0.26)
		blgt.light_energy = 2.8
		blgt.omni_range = 9.5
		blgt.visible = false
		root.add_child(blgt)
		flicker_lights.append({"light": blgt, "base": 2.8, "phase": 4.2 + float(bi) * 2.1, "brazier_idx": bi})
		var b_embers := HD2DLib.make_ember_particles(Vector3(0.20, 0.14, 0.20), 20)
		b_embers.position = bp + Vector3(0.0, 1.05, 0.0)
		b_embers.emitting = false
		root.add_child(b_embers)
		brazier_nodes.append({"bulb": bulb, "light": blgt, "embers": b_embers})

	# Dry Briar Thicket (BRIAR_POS) & Smuggler Crate (CACHE_POS)
	var briar_group := Node3D.new()
	briar_group.position = to_3d(region.BRIAR_POS, 0.0)
	root.add_child(briar_group)
	for b_off in [Vector3(-0.42, 0.0, 0.12), Vector3(0.0, 0.0, -0.08), Vector3(0.44, 0.0, 0.16)]:
		var bs := HD2DLib.make_sprite3d(assets.get_tex("prop_bramble_thicket_1.png"), "prop_bramble_thicket_1.png", 0.052)
		bs.position = b_off
		briar_group.add_child(bs)

	var crate_mesh := HD2DLib.make_textured_box(Vector3(0.88, 0.64, 0.72), TEX_DIR + "tex_oak_planks.png", 0.85, 0.84)
	crate_mesh.position = to_3d(region.CACHE_POS, 0.32)
	root.add_child(crate_mesh)
	var band := HD2DLib.make_color_box(Vector3(0.92, 0.10, 0.76), Color(0.22, 0.24, 0.28), 0.50, Color.BLACK, 0.0, 0.55)
	band.position = Vector3(0.0, 0.14, 0.0)
	crate_mesh.add_child(band)

	# Gold-Sunken Cairn NW + Noticeboard East
	var cairn_pos := to_3d(region.GOLD_RELIC_POS, 0.0)
	var cairn_spr := HD2DLib.make_sprite3d(assets.get_tex("prop_cairn_stone.png"), "prop_cairn_stone.png", 0.056)
	cairn_spr.position = cairn_pos
	root.add_child(cairn_spr)
	var cairn_glow := HD2DLib.make_glow_bulb(cairn_pos + Vector3(0.0, 0.95, 0.12), 0.15, Color(0.98, 0.84, 0.34), 2.2)
	root.add_child(cairn_glow)

	var sign_spr := HD2DLib.make_sprite3d(assets.get_tex("prop_noticeboard.png"), "prop_noticeboard.png", 0.056)
	sign_spr.position = to_3d(region.EAST_SIGN_POS, 0.035)
	root.add_child(sign_spr)

	# 13 Canon Fen Trees + Scenic Framing Pines + Reed Clusters
	var pine_tex: Texture2D = assets.get_tex("prop_pine_dark.png", "prop_pine_tree.png")
	for i in range(region.FEN_TREES.size()):
		var tp2d: Vector2 = region.FEN_TREES[i]
		var pine := HD2DLib.make_sprite3d(pine_tex, "prop_pine_dark.png", 0.068)
		pine.position = to_3d(tp2d, 0.0)
		var sc := 0.94 + float((i * 7) % 5) * 0.045
		pine.scale = Vector3(sc, sc, sc)
		pine.flip_h = (i % 2) == 1
		root.add_child(pine)

	for extra in [Vector2(240, 270), Vector2(600, 265), Vector2(980, 265), Vector2(1260, 268), Vector2(1580, 270), Vector2(1980, 270), Vector2(2280, 420), Vector2(2320, 880)]:
		var ep := HD2DLib.make_sprite3d(pine_tex, "prop_pine_dark.png", 0.072)
		ep.position = to_3d(extra, 0.0)
		root.add_child(ep)

	var fern_tex: Texture2D = assets.get_tex("prop_fern_cluster.png")
	var stone_tex: Texture2D = assets.get_tex("prop_river_stone_0.png")
	for ri in range(region.REED_CLUMPS.size()):
		var rp2d: Vector2 = region.REED_CLUMPS[ri]
		var fern := HD2DLib.make_sprite3d(fern_tex, "prop_fern_cluster.png", 0.054, false)
		fern.position = to_3d(rp2d, 0.0)
		root.add_child(fern)
		if ri % 2 == 0 and stone_tex != null:
			var rstone := HD2DLib.make_sprite3d(stone_tex, "prop_river_stone_0.png", 0.048, false)
			rstone.position = to_3d(rp2d + Vector2(18, 6), 0.0)
			root.add_child(rstone)

	return {
		"campfire_spr": campfire_spr,
		"egg_spr": egg_spr,
		"shards_spr": shards_spr,
		"briar_group": briar_group,
		"crate_mesh": crate_mesh,
		"cairn_glow": cairn_glow,
		"brazier_nodes": brazier_nodes,
	}


static func _build_horizon_and_weather(root: Node3D, _assets) -> void:
	var hor_tex := HD2DLib.load_png(TEX_DIR + "tex_horizon_treeline.png")
	if hor_tex != null:
		for hx in [12.0, 30.0, 48.0, 66.0]:
			var card := HD2DLib.make_sprite3d(hor_tex, "tex_horizon_treeline", 0.11, false, 0.0, false)
			card.position = Vector3(hx, -0.35, -6.5)
			card.modulate = Color(0.68, 0.76, 0.88)
			root.add_child(card)
		var east_card := HD2DLib.make_sprite3d(hor_tex, "tex_horizon_treeline", 0.11, false, 0.0, false)
		east_card.position = Vector3(78.0, -0.35, 22.0)
		east_card.rotation_degrees.y = -90.0
		east_card.modulate = Color(0.68, 0.76, 0.88)
		root.add_child(east_card)

	var fireflies := HD2DLib.make_firefly_particles(Vector3(28.0, 1.4, 15.0), 64)
	fireflies.position = Vector3(33.0, 1.6, 21.0)
	root.add_child(fireflies)

	var mist := HD2DLib.make_mist_particles(Vector3(30.0, 0.45, 16.0), 34)
	mist.position = Vector3(33.0, 0.55, 21.0)
	root.add_child(mist)
