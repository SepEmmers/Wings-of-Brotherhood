extends "res://scripts/regions/RegionBase.gd"

## Bruges Coastal Outskirts: interconnecting countryside linking
## Bruges City East Gate (west), Port of Bruges North Gate (southwest),
## and the Brotherhood Sanctuary West Gate (east) across the Zwin feeder canal.

const WORLD_SIZE := Vector2(2400, 1140)
const CANAL_RECT := Rect2(1152, 0, 96, 1140)
const BRIDGE_RECT := Rect2(1120, 496, 160, 96)

const TOLLHOUSE_RECT := Rect2(560, 260, 148, 124)
const SHRINE_RECT := Rect2(1540, 290, 96, 86)

const ROAD_RECTS: Array[Rect2] = [
	Rect2(0, 504, 1152, 112),
	Rect2(1248, 496, 620, 96),
	Rect2(1820, 464, 580, 112),
	Rect2(320, 560, 120, 580),
]

const COVER_SPECS: Array[Dictionary] = [
	{"rect": Rect2(490, 624, 56, 44), "tex": "prop_crate.png"},
	{"rect": Rect2(548, 628, 48, 40), "tex": "prop_cloth_bales.png"},
	{"rect": Rect2(268, 424, 62, 42), "tex": "prop_wine_cask_cart.png"},
	{"rect": Rect2(258, 728, 56, 42), "tex": "prop_hay_bale.png"},
	{"rect": Rect2(246, 904, 48, 40), "tex": "prop_cloth_bales.png"},
	{"rect": Rect2(468, 864, 52, 42), "tex": "prop_crate.png"},
	{"rect": Rect2(742, 626, 62, 42), "tex": "prop_hay_bale.png"},
	{"rect": Rect2(812, 632, 38, 36), "tex": "prop_barrel.png"},
	{"rect": Rect2(880, 412, 64, 44), "tex": "prop_hay_bale.png"},
	{"rect": Rect2(948, 418, 36, 36), "tex": "prop_barrel.png"},
	{"rect": Rect2(1018, 624, 52, 42), "tex": "prop_cloth_bales.png"},
	{"rect": Rect2(1292, 426, 56, 42), "tex": "prop_hay_bale.png"},
	{"rect": Rect2(1380, 616, 56, 44), "tex": "prop_crate.png"},
	{"rect": Rect2(1438, 620, 48, 40), "tex": "prop_cloth_bales.png"},
	{"rect": Rect2(1596, 608, 62, 42), "tex": "prop_wine_cask_cart.png"},
	{"rect": Rect2(1664, 616, 38, 36), "tex": "prop_barrel.png"},
	{"rect": Rect2(1790, 398, 64, 44), "tex": "prop_hay_bale.png"},
	{"rect": Rect2(1858, 404, 48, 40), "tex": "prop_crate.png"},
	{"rect": Rect2(1972, 594, 56, 42), "tex": "prop_hay_bale.png"},
	{"rect": Rect2(2042, 378, 52, 42), "tex": "prop_cloth_bales.png"},
	{"rect": Rect2(2116, 588, 52, 42), "tex": "prop_crate.png"},
	{"rect": Rect2(2172, 592, 38, 36), "tex": "prop_barrel.png"},
]

const PINE_POSITIONS: Array[Vector2] = [
	Vector2(185, 220), Vector2(310, 185), Vector2(445, 240), Vector2(780, 175),
	Vector2(960, 210), Vector2(1070, 320), Vector2(1340, 210), Vector2(1485, 165),
	Vector2(1745, 225), Vector2(1940, 195), Vector2(2110, 255), Vector2(2260, 310),
	Vector2(165, 815), Vector2(250, 945), Vector2(560, 860), Vector2(740, 935),
	Vector2(935, 800), Vector2(1065, 920), Vector2(1340, 845), Vector2(1530, 910),
	Vector2(1740, 815), Vector2(1960, 865), Vector2(2140, 745), Vector2(2255, 665),
	Vector2(215, 340), Vector2(490, 760), Vector2(685, 740), Vector2(855, 755),
	Vector2(1045, 710), Vector2(1290, 310), Vector2(1425, 325), Vector2(1675, 715),
	Vector2(1890, 715), Vector2(2030, 695), Vector2(615, 160), Vector2(1245, 720),
	Vector2(165, 650), Vector2(525, 420), Vector2(1705, 405), Vector2(2190, 200),
]

var solid_rects: Array[Rect2] = []
var sight_blockers: Array[Rect2] = []
var lantern_lights: Array[PointLight2D] = []
var lanterns: Array[Vector2] = [
	Vector2(136, 492),
	Vector2(714, 370),
	Vector2(1118, 488),
	Vector2(1282, 598),
	Vector2(1588, 378),
	Vector2(2220, 456),
]

var wardens: Array[Dictionary] = []
var last_entry_opts: Dictionary = {}
var alert_cooldown: float = 0.0
var fail_triggered: bool = false


func enter_region(opts: Dictionary = {}) -> void:
	last_entry_opts = opts.duplicate(true)
	fail_triggered = false
	alert_cooldown = 0.0
	_setup_collisions()
	_setup_interactables()
	_setup_walk_portals()
	_setup_wardens()
	_setup_lights()
	setup_static_ground_chunks(
		Rect2(0, 0, WORLD_SIZE.x, WORLD_SIZE.y),
		func(canvas: Node2D): _draw_static_ground(canvas),
		720,
		-3,
		false
	)
	setup_water_layer([CANAL_RECT], 32.0, -2)
	ensure_foreground_layer(func(fg: Node2D): _draw_foreground(fg), 18)

	var spawn: Vector2 = opts.get("spawn", Vector2(108, 560))
	player.position = spawn
	player.visible = true
	player.cutscene_hidden = false
	player.can_move = true
	if opts.has("facing"):
		player.facing = opts["facing"]
	else:
		player.facing = Vector2.RIGHT if spawn.x < 1200.0 else Vector2.LEFT

	director.camera.limit_left = 0
	director.camera.limit_top = 0
	director.camera.limit_right = int(WORLD_SIZE.x)
	director.camera.limit_bottom = int(WORLD_SIZE.y)
	director.camera.position = player.position

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.refresh_hud()
	SoundManager.set_ambience(get_ambience_track())
	step_water_layer()
	queue_redraw()
	queue_foreground_redraw()


func _setup_collisions() -> void:
	for c in get_children():
		if c is StaticBody2D and c.name != "NpcColliderBody":
			c.queue_free()
	solid_rects.clear()
	sight_blockers.clear()

	var static_body := StaticBody2D.new()
	static_body.name = "OutskirtsBounds"
	add_child(static_body)

	var bounds_rects: Array[Rect2] = [
		Rect2(0, -16, 2400, 34),
		# West boundary (opening at y=502..618 for Bruges East Gate)
		Rect2(-16, 0, 34, 502),
		Rect2(-16, 618, 34, 522),
		# South boundary (opening at x=318..442 for Port Towpath)
		Rect2(0, 1122, 318, 34),
		Rect2(442, 1122, 1958, 34),
		# East boundary (opening at y=462..578 for Sanctuary West Trail)
		Rect2(2382, 0, 34, 462),
		Rect2(2382, 578, 34, 562),
		# Zwin Feeder Canal (open across bridge y=496..592)
		Rect2(1152, 0, 96, 496),
		Rect2(1152, 592, 96, 548),
		# Landmarks
		Rect2(TOLLHOUSE_RECT.position.x + 10.0, TOLLHOUSE_RECT.position.y + 62.0, TOLLHOUSE_RECT.size.x - 20.0, TOLLHOUSE_RECT.size.y - 62.0),
		Rect2(SHRINE_RECT.position.x + 12.0, SHRINE_RECT.position.y + 44.0, SHRINE_RECT.size.x - 24.0, SHRINE_RECT.size.y - 44.0),
	]
	for br in bounds_rects:
		solid_rects.append(br)
		add_box_collider(static_body, br)

	sight_blockers.append(Rect2(TOLLHOUSE_RECT.position.x + 10.0, TOLLHOUSE_RECT.position.y + 52.0, TOLLHOUSE_RECT.size.x - 20.0, TOLLHOUSE_RECT.size.y - 52.0))
	sight_blockers.append(Rect2(SHRINE_RECT.position.x + 12.0, SHRINE_RECT.position.y + 36.0, SHRINE_RECT.size.x - 24.0, SHRINE_RECT.size.y - 36.0))

	for cs in COVER_SPECS:
		var cr: Rect2 = cs["rect"]
		solid_rects.append(cr)
		sight_blockers.append(cr)
		add_box_collider(static_body, cr)

	for p in PINE_POSITIONS:
		var tr := Rect2(p.x - 16.0, p.y - 12.0, 32.0, 26.0)
		solid_rects.append(tr)
		sight_blockers.append(Rect2(p.x - 20.0, p.y - 24.0, 40.0, 38.0))
		add_box_collider(static_body, tr)

	setup_navigation_grid(Rect2(0, 0, WORLD_SIZE.x, WORLD_SIZE.y), solid_rects, 12.0, 24.0)


func _setup_interactables() -> void:
	interactables = [
		{"id": "milestone_west", "name": "Read Causeway Milestone", "pos": Vector2(152, 492), "radius": 62.0, "callback": func(): _read_sign("Bruges East Causeway", "WEST: Bruges City East Gate (100 paces)  |  SOUTH FORK: Port Wharf")},
		{"id": "milestone_cross", "name": "Read Crossroads Signpost", "pos": Vector2(458, 636), "radius": 62.0, "callback": func(): _read_sign("Crossroads Signpost", "WEST: Bruges East Gate  |  SOUTH: Port of Bruges Wharf  |  EAST: Sanctuary Dunes")},
		{"id": "milestone_east", "name": "Read Dune Marker", "pos": Vector2(2180, 456), "radius": 64.0, "callback": func(): _read_sign("Weathered Dune Post", "East Cliff Trail — Watchmen sweep these dunes after the curfew bell.")},
		{"id": "outskirts_toll", "name": "Talk to Tollhouse Keeper", "pos": Vector2(634, 404), "radius": 64.0, "callback": _talk_tollkeeper},
	]


func _setup_walk_portals() -> void:
	clear_walk_portals()
	register_walk_portal("outskirts_west_city", Rect2(0, 504, 84, 112), Vector2.LEFT, _go_to_bruges_city, "<- Walled City of Bruges", "WALLED CITY OF BRUGES", "East Gate Bastion")
	register_walk_portal("outskirts_south_port", Rect2(320, 1056, 120, 84), Vector2.DOWN, _go_to_port, "v Port (NE Towpath)", "PORT OF BRUGES", "North-East Towpath Gate")
	register_walk_portal("outskirts_east_sanctuary", Rect2(2308, 444, 92, 148), Vector2.RIGHT, _go_to_sanctuary, "Sanctuary Ridge ->", "BROTHERHOOD SANCTUARY", "Western Cliff Trail")


func _setup_wardens() -> void:
	wardens = [
		{
			"name": "South Fork Watcher",
			"pos": Vector2(382, 780),
			"waypoints": [Vector2(382, 700), Vector2(382, 955), Vector2(490, 955), Vector2(382, 820)],
			"wp_idx": 1,
			"dir": Vector2.DOWN,
			"pause": 0.2,
			"alert": 0.0,
		},
		{
			"name": "Causeway Warden",
			"pos": Vector2(740, 558),
			"waypoints": [Vector2(690, 558), Vector2(1070, 558), Vector2(1070, 470), Vector2(690, 470)],
			"wp_idx": 1,
			"dir": Vector2.RIGHT,
			"pause": 0.0,
			"alert": 0.0,
		},
		{
			"name": "Tollhouse Outrider",
			"pos": Vector2(900, 628),
			"waypoints": [Vector2(730, 625), Vector2(1040, 625), Vector2(1040, 540), Vector2(730, 540)],
			"wp_idx": 1,
			"dir": Vector2.RIGHT,
			"pause": 0.5,
			"alert": 0.0,
		},
		{
			"name": "Canal Bridge Sentinel",
			"pos": Vector2(1380, 548),
			"waypoints": [Vector2(1290, 548), Vector2(1590, 548), Vector2(1590, 456), Vector2(1290, 456)],
			"wp_idx": 1,
			"dir": Vector2.RIGHT,
			"pause": 0.1,
			"alert": 0.0,
		},
		{
			"name": "Ridge Searcher",
			"pos": Vector2(1820, 520),
			"waypoints": [Vector2(1620, 540), Vector2(2090, 510), Vector2(1860, 625), Vector2(1620, 605)],
			"wp_idx": 1,
			"dir": Vector2.LEFT,
			"pause": 0.4,
			"alert": 0.0,
		},
	]


func _setup_lights() -> void:
	for lt in lantern_lights:
		if is_instance_valid(lt):
			lt.queue_free()
	lantern_lights.clear()
	for lp in lanterns:
		var lt: PointLight2D = assets.make_point_light(lp + Vector2(0, -10), 1.85, Color(1.0, 0.80, 0.50), 0.72)
		add_child(lt)
		lantern_lights.append(lt)


func _read_sign(title_str: String, body_str: String) -> void:
	ui.show_parchment_note(title_str, body_str, "Bruges Outskirts Post")


func _talk_tollkeeper() -> void:
	var msg := "Canal barges are held inside the watergates until dusk. Stay on the cobbles if you're heading toward town."
	if _is_hostile_patrol():
		msg = "Church riders have sealed the Zwin bridge looking for stolen dragon contraband. Keep your head down behind those wool bales!"
	ui.show_dialogue([{"speaker": "Tollkeeper", "text": msg, "portrait": "portrait_quartermaster.png"}])


func _go_to_bruges_city() -> void:
	director.load_region("bruges_city", {"spawn": Vector2(2716, 1304), "facing": Vector2.LEFT, "skip_intro": true})


func _go_to_port() -> void:
	director.load_region("bruges", {"spawn": Vector2(1528, 68), "facing": Vector2.DOWN})


func _go_to_sanctuary() -> void:
	director.load_region("sanctuary", {"spawn": Vector2(132, 515), "facing": Vector2.RIGHT, "skip_intro": true, "preserve_step": true})


func _is_hostile_patrol() -> bool:
	return GameState.current_step >= GameState.QuestStep.ACT4_BRUGES_CITY or (GameState.current_step == GameState.QuestStep.ACT4_SANCTUARY_DEBATE and GameState.act4_egg_debate_done)


func step_region(delta: float) -> void:
	director.camera.position = player.position
	step_water_layer()
	alert_cooldown = maxf(0.0, alert_cooldown - delta)
	var hostile_patrol := _is_hostile_patrol()
	if not ui.is_blocking_gameplay() and not fail_triggered:
		_step_wardens(delta, hostile_patrol)
	queue_redraw()
	queue_foreground_redraw()


func _step_wardens(delta: float, hostile: bool) -> void:
	var any_seen := false
	for w in wardens:
		var pos := Vector2(w["pos"])
		var pause_t := float(w["pause"])
		if pause_t > 0.0:
			w["pause"] = pause_t - delta
			var sweep := sin(assets.time_elapsed * 2.2) * 0.35
			w["dir"] = Vector2(w["dir"]).rotated(sweep * delta)
		else:
			var wps: Array = w["waypoints"]
			var idx := int(w["wp_idx"])
			var tgt := Vector2(wps[idx])
			if pos.distance_to(tgt) < 16.0:
				w["wp_idx"] = (idx + 1) % wps.size()
				w["pause"] = 0.85
			else:
				var move_d := compute_nav_move_dir(pos, tgt, solid_rects, 12.0)
				if move_d.length_squared() > 0.01:
					w["dir"] = move_d.normalized()
					w["pos"] = steer_and_move_actor(pos, move_d, 72.0, delta, solid_rects, 12.0)

		if not hostile:
			w["alert"] = 0.0
			continue
		var eye := Vector2(w["pos"]) + Vector2(0.0, -8.0)
		var see_player := can_vision_cone_see(eye, Vector2(w["dir"]), player.position, 215.0, 0.56, sight_blockers, 22.0)
		if see_player:
			any_seen = true
			w["alert"] = minf(1.0, float(w["alert"]) + delta * 1.95)
			if float(w["alert"]) >= 1.0:
				_trigger_warden_fail()
				return
		else:
			w["alert"] = maxf(0.0, float(w["alert"]) - delta * 1.1)
	if any_seen and alert_cooldown <= 0.0:
		alert_cooldown = 0.65
		SoundManager.play_ui_click()


func _trigger_warden_fail() -> void:
	fail_triggered = true
	player.can_move = false
	SoundManager.play_alert_horn()
	var retry_cb := func():
		GameState.boy_hp = GameState.boy_max_hp
		director.load_region("outskirts", last_entry_opts)
	if GameState.boy_hp <= 1:
		GameState.boy_hp = 0
		ui.refresh_hud()
		ui.show_death_screen("Cornered on the Zwin causeway by Church Road-Wardens.", retry_cb)
	else:
		ui.show_mission_failed_screen("A Church Road-Warden spotted you crossing the Bruges outskirts!", retry_cb)


func get_active_npc_colliders() -> Array:
	var out: Array = [{"pos": Vector2(634, 396), "radius": 13.0}]
	for w in wardens:
		out.append({"pos": Vector2(w["pos"]), "radius": 14.0})
	return out


func _draw_static_ground(canvas: Node2D) -> void:
	assets.draw_grass_zone(canvas, Rect2(0, 0, WORLD_SIZE.x, WORLD_SIZE.y), false, 41, ROAD_RECTS)
	var cobble_a: Texture2D = assets.get_tex("tile_cobble.png")
	var cobble_b: Texture2D = assets.get_tex("tile_cobble_2.png")
	assets.draw_dirt_trail_network(canvas, ROAD_RECTS, [], [TOLLHOUSE_RECT, SHRINE_RECT], 19)
	# Paved western causeway approach from Bruges East Gate
	assets.draw_varied_tiled_rect(canvas, Rect2(0, 504, 380, 112), cobble_a, cobble_b, 32.0, 5)
	assets.draw_varied_tiled_rect(canvas, Rect2(TOLLHOUSE_RECT.position.x - 16, TOLLHOUSE_RECT.end.y - 4, TOLLHOUSE_RECT.size.x + 32, 46), cobble_a, cobble_b, 32.0, 7)
	# Bridge apron on both sides of the Zwin canal
	assets.draw_varied_tiled_rect(canvas, Rect2(1072, 496, 256, 96), cobble_a, cobble_b, 32.0, 11)
	assets.draw_stone_clearing_in_grass(canvas, SHRINE_RECT.grow(18.0), 23)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var cam := get_camera_rect(140.0)
	var bridge_tex: Texture2D = assets.get_tex("prop_stone_bridge_h.png")
	if bridge_tex != null and cam.intersects(BRIDGE_RECT):
		draw_texture_rect(bridge_tex, BRIDGE_RECT, false)

	var y_items: Array[Dictionary] = []
	y_items.append({"y": TOLLHOUSE_RECT.end.y, "kind": "bldg", "rect": TOLLHOUSE_RECT, "tex": "city_cottage_4c.png", "label": "Tollhouse"})
	y_items.append({"y": SHRINE_RECT.end.y, "kind": "shrine"})
	for cs in COVER_SPECS:
		var r_cov: Rect2 = cs["rect"]
		if cam.intersects(r_cov.grow(24.0)):
			y_items.append({"y": r_cov.end.y, "kind": "prop", "rect": r_cov, "tex": cs["tex"]})
	for p in PINE_POSITIONS:
		if cam.intersects(Rect2(p.x - 48.0, p.y - 84.0, 96.0, 96.0)):
			y_items.append({"y": p.y, "kind": "pine", "pos": p})
	for ms in [Vector2(152, 492), Vector2(458, 636), Vector2(2180, 456)]:
		y_items.append({"y": ms.y, "kind": "milestone", "pos": ms})
	y_items.append({"y": 396.0, "kind": "npc", "pos": Vector2(634, 396), "tex": "npc_quartermaster.png", "label": "Tollkeeper"})

	var hostile := _is_hostile_patrol()
	for w in wardens:
		var wp := Vector2(w["pos"])
		var fill_c := Color(0.95, 0.24, 0.18, 0.20) if hostile else Color(0.86, 0.72, 0.34, 0.11)
		var line_c := Color(1.0, 0.36, 0.26, 0.55) if hostile else Color(0.92, 0.80, 0.44, 0.30)
		draw_raycast_vision_cone(self, wp + Vector2(0, -8), Vector2(w["dir"]), 215.0, 0.56, sight_blockers, fill_c, line_c, 24)
		y_items.append({"y": wp.y, "kind": "warden", "data": w})

	y_items.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	var tree_tex: Texture2D = assets.get_tex("prop_pine_tree.png", "prop_pine_dark.png")
	var sign_tex: Texture2D = assets.get_tex("prop_milestone.png")
	for it in y_items:
		match it["kind"]:
			"bldg":
				assets.draw_sprite_building(self, it["rect"], it["tex"], it["label"], font)
			"shrine":
				var cairn: Texture2D = assets.get_tex("prop_cairn_stone.png")
				if cairn != null:
					draw_texture_rect(cairn, Rect2(SHRINE_RECT.position + Vector2(24, 24), Vector2(48, 48)), false)
			"prop":
				var pt: Texture2D = assets.get_tex(it["tex"])
				if pt != null:
					draw_texture_rect(pt, it["rect"], false)
			"pine":
				var tp := Vector2(it["pos"])
				if tree_tex != null:
					draw_texture_rect(tree_tex, Rect2(tp.x - 32.0, tp.y - 76.0, 64.0, 82.0), false)
			"milestone":
				var mp := Vector2(it["pos"])
				if sign_tex != null:
					draw_texture_rect(sign_tex, Rect2(mp.x - 16.0, mp.y - 36.0, 32.0, 40.0), false)
			"npc":
				assets.draw_npc_sprite(self, it["pos"], it["tex"], it["label"], font)
			"warden":
				var wd: Dictionary = it["data"]
				var wpos := Vector2(wd["pos"])
				var wd_dir := Vector2(wd["dir"])
				var tex_n := "npc_watchman_down_0.png"
				var flip := false
				if absf(wd_dir.x) > absf(wd_dir.y):
					tex_n = "npc_watchman_side_%d.png" % (int(assets.time_elapsed * 4.0) % 3)
					flip = wd_dir.x < 0.0
				elif wd_dir.y < -0.2:
					tex_n = "npc_watchman_up_%d.png" % (int(assets.time_elapsed * 4.0) % 3)
				assets.draw_npc_sprite(self, wpos, tex_n, wd["name"], font, Color(0.98, 0.72, 0.56), flip)
				if float(wd["alert"]) > 0.05:
					draw_rect(Rect2(wpos.x - 16.0, wpos.y - 42.0, 32.0, 4.0), Color(0.12, 0.10, 0.12, 0.85))
					draw_rect(Rect2(wpos.x - 16.0, wpos.y - 42.0, 32.0 * float(wd["alert"]), 4.0), Color(0.95, 0.24, 0.20))

	var pier_tex: Texture2D = assets.get_tex("prop_gatehouse_pier_v.png")
	if pier_tex != null:
		draw_texture_rect(pier_tex, Rect2(8, 480, 28, 36), false)
		draw_texture_rect(pier_tex, Rect2(8, 600, 28, 36), false)

	for lp in lanterns:
		if cam.intersects(Rect2(lp - Vector2(32, 48), Vector2(64, 64))):
			var ltex: Texture2D = assets.get_tex("prop_lantern.png")
			if ltex != null:
				draw_texture_rect(ltex, Rect2(lp.x - 10.0, lp.y - 32.0, 20.0, 32.0), false)

	draw_interact_bubble_if_active(font)


func _draw_foreground(fg: Node2D) -> void:
	draw_building_roof_overhang(fg, TOLLHOUSE_RECT, assets.get_tex("city_cottage_4c.png"), 0.44)


func get_surface_at(pos: Vector2) -> String:
	if BRIDGE_RECT.has_point(pos) or pos.x < 380.0:
		return "stone"
	for rd in ROAD_RECTS:
		if rd.has_point(pos):
			return "dirt"
	return "grass"


func get_ambience_track() -> String:
	return "stealth"


func update_region_lights(_time_val: float) -> void:
	sync_light_frustum(lantern_lights, true)
