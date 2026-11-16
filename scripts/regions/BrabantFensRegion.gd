extends "res://scripts/regions/RegionBase.gd"

## Book II Act I Leg 1 — Brabant Reed-Fens (2160x1440):
## Kestrel touchdown west of walled Louvain, sheltered mill campfire Egg Hatching
## & naming ceremony, Hatchling Stage 1 Vent Crawl + Ember Puff + Gold-Sense,
## and east dike portal to Louvain's West Gate.

const BrabantFensDrawScript := preload("res://scripts/regions/BrabantFensDraw.gd")

const WORLD_SIZE := Vector2(2160, 1440)
const KESTREL_LANDING_POS := Vector2(228, 708)
const MILL_COTTAGE_RECT := Rect2(812, 430, 152, 128)
const CAMPFIRE_POS := Vector2(960, 680)
const VENT_POS := Vector2(1378, 554)
const GATE_RECT := Rect2(1352, 646, 52, 128)
const LEVER_POS := Vector2(1414, 622)
const VENT_CRAWL_DUR := 1.35
const BRIAR_POS := Vector2(1078, 860)
const CACHE_POS := Vector2(1078, 924)
const GOLD_RELIC_POS := Vector2(590, 392)
const EAST_SIGN_POS := Vector2(2016, 616)

const SLUICE_WALL_SEGMENTS: Array[Rect2] = [
	Rect2(1352, 240, 52, 406),
	Rect2(1352, 774, 52, 316),
]

const REED_CLUMPS: Array[Vector2] = [
	Vector2(180, 340), Vector2(310, 292), Vector2(460, 980), Vector2(680, 990),
	Vector2(1180, 320), Vector2(1290, 995), Vector2(1540, 310), Vector2(1660, 960),
	Vector2(1920, 340), Vector2(2040, 940),
]

const FEN_TREES: Array[Vector2] = [
	Vector2(290, 360), Vector2(450, 310), Vector2(710, 300), Vector2(1120, 310),
	Vector2(1490, 340), Vector2(1670, 410), Vector2(1960, 370),
	Vector2(280, 985), Vector2(510, 975), Vector2(880, 1005), Vector2(1470, 975),
	Vector2(1680, 985), Vector2(1960, 965),
]

var solid_colliders: Array[Rect2] = []
var gate_body: StaticBody2D
var briar_body: StaticBody2D
var region_lights: Array[PointLight2D] = []
var brazier_lights: Array[PointLight2D] = []
var egg_light: PointLight2D

var brazier_states: Array[Dictionary] = [
	{"pos": Vector2(680, 628), "lit": false},
	{"pos": Vector2(1660, 628), "lit": false},
]

var intro_active: bool = false
var intro_stage: int = 0
var intro_t: float = 0.0
var intro_wait_dlg: bool = false
var intro_dlg_done: bool = false
var kestrel_visible: bool = false
var kestrel_pos: Vector2 = KESTREL_LANDING_POS
var kestrel_alt: float = 0.0

var hatch_anim_active: bool = false
var hatch_anim_stage: int = 0
var hatch_anim_t: float = 0.0

var vent_crawl_t: float = 0.0
var gate_open_anim: float = 0.0
var _vent_lever_tripped: bool = false
var _last_command_kind: String = ""
var _unfed_briar_warned: bool = false
var _frost_emit_t: float = 0.0
var _sling_gate_warned: bool = false
var cairn_relic_claimed: bool = false
var fx_particles: Array[Dictionary] = []


func _ready() -> void:
	_setup_collisions()
	_setup_lights()
	BrabantFensDrawScript.setup_layers(self)

	interactables = [
		{"id": "bf_campfire", "name": "Sheltered Mill Campfire", "pos": CAMPFIRE_POS, "radius": 78.0, "callback": _on_interact_campfire},
		{"id": "bf_cache", "name": "Smuggler Fen Cache", "pos": CACHE_POS, "radius": 68.0, "callback": _on_interact_cache},
		{"id": "bf_cairn", "name": "Gold-Sunken Boundary Cairn", "pos": GOLD_RELIC_POS, "radius": 70.0, "callback": _on_interact_cairn},
		{"id": "bf_east_sign", "name": "Read Louvain Milepost & Decree", "pos": EAST_SIGN_POS, "radius": 74.0, "callback": _on_read_east_sign},
	]
	clear_walk_portals()
	register_walk_portal(
		"brabant_to_louvain",
		Rect2(2092, 650, 68, 128),
		Vector2.RIGHT,
		_on_enter_louvain,
		"Louvain West Gate ->",
		"LOUVAIN — DIJLE CITY",
		"Birthplace & Locked Archives"
	)


func _setup_collisions() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	solid_colliders.clear()

	# Perimeter world bounds & water pools
	var base_solids: Array[Rect2] = [
		Rect2(-24, 0, 24, WORLD_SIZE.y),
		Rect2(WORLD_SIZE.x, 0, 24, WORLD_SIZE.y),
		Rect2(MILL_COTTAGE_RECT.position.x + 12, MILL_COTTAGE_RECT.position.y + 52, MILL_COTTAGE_RECT.size.x - 24, MILL_COTTAGE_RECT.size.y - 54),
	]
	for wr: Rect2 in BrabantFensDrawScript.get_water_rects():
		base_solids.append(wr)
	for ws: Rect2 in SLUICE_WALL_SEGMENTS:
		base_solids.append(ws)
	for sr: Rect2 in base_solids:
		add_box_collider(colliders, sr)
		solid_colliders.append(sr)

	gate_body = StaticBody2D.new()
	add_child(gate_body)
	add_box_collider(gate_body, GATE_RECT)

	briar_body = StaticBody2D.new()
	add_child(briar_body)
	add_box_collider(briar_body, Rect2(BRIAR_POS - Vector2(30, 18), Vector2(60, 36)))


func _setup_lights() -> void:
	region_lights.clear()
	brazier_lights.clear()
	var camp_pl: PointLight2D = assets.make_point_light(CAMPFIRE_POS + Vector2(0, -10), 3.4, Color(1.0, 0.72, 0.32), 0.96)
	add_child(camp_pl)
	region_lights.append(camp_pl)

	egg_light = assets.make_point_light(KESTREL_LANDING_POS, 2.1, Color(0.98, 0.80, 0.36), 0.72)
	add_child(egg_light)
	region_lights.append(egg_light)

	for b: Dictionary in brazier_states:
		var bl: PointLight2D = assets.make_point_light(Vector2(b["pos"]) + Vector2(0, -10), 2.4, Color(1.0, 0.72, 0.34), 0.78)
		bl.visible = false
		add_child(bl)
		brazier_lights.append(bl)
		region_lights.append(bl)


func enter_region(opts: Dictionary = {}) -> void:
	fx_particles.clear()
	portal_cooldown = 0.85
	GameState.active_perspective = "boy"
	GameState.book2_started = true
	if int(GameState.current_step) < int(GameState.QuestStep.BOOK2_BRABANT_FENS):
		GameState.current_step = GameState.QuestStep.BOOK2_BRABANT_FENS
	GameState.unlock_realm_node("brabant_fens")

	if bool(opts.get("hatched_state", false)):
		GameState.brabant_hatched = true
		GameState.active_companion_stage = maxi(1, GameState.active_companion_stage)
		if GameState.dragon_bond < 10:
			GameState.dragon_bond = 10

	var spawn: Vector2 = opts.get("spawn", Vector2(276, 708))
	player.position = spawn
	player.facing = opts.get("facing", Vector2.RIGHT)
	player.visible = true
	player.cutscene_hidden = false
	player.can_move = true
	player.set_carry_prop("" if GameState.brabant_hatched else "egg", "" if GameState.brabant_hatched else "cradle")

	set_body_collision_enabled(gate_body, not GameState.brabant_vent_unlocked)
	set_body_collision_enabled(briar_body, not GameState.brabant_briar_burned)

	if director != null and director.camera != null:
		director.camera.limit_left = 0
		director.camera.limit_top = 0
		director.camera.limit_right = int(WORLD_SIZE.x)
		director.camera.limit_bottom = int(WORLD_SIZE.y)
		director.camera.position = player.position

	_connect_campfire_signals()
	_sync_campfire_label()

	kestrel_visible = false
	intro_active = false
	hatch_anim_active = false
	vent_crawl_t = 0.0
	gate_open_anim = 1.0 if GameState.brabant_vent_unlocked else 0.0
	_vent_lever_tripped = GameState.brabant_vent_unlocked
	_last_command_kind = ""
	_unfed_briar_warned = false
	_frost_emit_t = 0.0
	_sling_gate_warned = false

	if bool(opts.get("book2_intro", false)) and not GameState.brabant_hatched:
		GameState.carrying_egg = true
		GameState.egg_warmth = 38.0
		_start_kestrel_arrival()
	else:
		_sync_hint_context()

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.update_world_map_state("brabant_fens", player.position)
	ui.refresh_hud()
	SoundManager.set_ambience(get_ambience_track())
	step_water_layer()
	queue_redraw()
	queue_foreground_redraw()


func exit_region() -> void:
	if director != null and director.companion != null:
		director.companion.clear_hint_context()


func _connect_campfire_signals() -> void:
	if ui == null or ui.campfire_panel == null:
		return
	var cp = ui.campfire_panel
	if not cp.rested_at_fire.is_connected(_on_camp_rested):
		cp.rested_at_fire.connect(_on_camp_rested)
	if not cp.fed_hatchling.is_connected(_on_camp_fed):
		cp.fed_hatchling.connect(_on_camp_fed)
	if not cp.closed.is_connected(_on_camp_closed):
		cp.closed.connect(_on_camp_closed)


func _on_camp_rested() -> void:
	GameState.brabant_camp_rested = true
	_spawn_fx(CAMPFIRE_POS, Color(1.0, 0.84, 0.42), 14)


func _on_camp_fed(_new_bond: int) -> void:
	_spawn_fx(CAMPFIRE_POS + Vector2(28, 4), Color(1.0, 0.64, 0.24), 18)
	_sync_campfire_label()
	_sync_hint_context()


func _on_camp_closed() -> void:
	if GameState.brabant_hatched and GameState.hatchling_fed_count >= 1 and not GameState.brabant_feed_intro_done:
		GameState.brabant_feed_intro_done = true
		_sync_campfire_label()
		SoundManager.play_campfire_warm()
		SoundManager.play_dragon_purr()
		_spawn_fx(CAMPFIRE_POS + Vector2(34, 4), Color(1.0, 0.60, 0.20), 22)
		ui.show_dialogue([
			{
				"speaker": GameState.gold_dragon_name,
				"portrait": GameState.get_hatchling_portrait(),
				"telepathic": true,
				"text": "Warm... snapping embers right down in my throat! Look—orange soot sparks!"
			},
			{
				"speaker": GameState.player_name,
				"portrait": "portrait_boy17.png",
				"text": "Wait—did you just throw your voice straight inside my head? Quietly then, little one... My mother and father walked Louvain's Hunters' Guild before Old Heverlee killed them. If Church vaults or old guild-ledgers still record what they died hiding—and where Clara was dragged—we'll find the trail behind that city gate."
			},
			{
				"speaker": GameState.gold_dragon_name,
				"portrait": GameState.get_hatchling_portrait(),
				"telepathic": true,
				"text": "Heavy iron sluice bars seal the bridge road ahead... though that low drain grate beside them looks plenty wide for soot-black claws. And dry dead brambles south smell ready for one hot spark."
			}
		], func():
			_sync_hint_context()
			ui.refresh_hud()
		)


func _sync_campfire_label() -> void:
	var lbl := "Sheltered Mill Campfire — Warm Egg"
	if GameState.brabant_hatched:
		lbl = ("Feed %s at Fire" % GameState.gold_dragon_name) if GameState.hatchling_fed_count == 0 else "Old Mill Campfire"
	for item: Dictionary in interactables:
		if str(item.get("id", "")) == "bf_campfire":
			item["name"] = lbl
			break


func step_region(delta: float) -> void:
	step_water_layer()
	step_walk_portals(delta)
	_step_particles(delta)
	if vent_crawl_t > 0.0:
		vent_crawl_t = maxf(0.0, vent_crawl_t - delta)
		var vprog := 1.0 - (vent_crawl_t / VENT_CRAWL_DUR)
		if vprog >= 0.72 and not _vent_lever_tripped:
			_vent_lever_tripped = true
			SoundManager.play_cage_break()
			SoundManager.play_door()
			_spawn_fx(LEVER_POS, Color(0.98, 0.84, 0.36), 14)
			_spawn_fx(GATE_RECT.get_center(), Color(0.76, 0.92, 0.64), 14)
	gate_open_anim = move_toward(gate_open_anim, 1.0 if _vent_lever_tripped else 0.0, delta * 2.6)
	if GameState.brabant_hatched and GameState.companion_posture == "sling" and not GameState.brabant_sling_practiced:
		GameState.brabant_sling_practiced = true
		_sync_hint_context()
		ui.refresh_hud()
	if intro_active:
		_step_kestrel_arrival(delta)
	elif hatch_anim_active:
		_step_hatching_sequence(delta)
		if director != null and director.camera != null:
			director.camera.position = CAMPFIRE_POS + Vector2(14, 4)
	elif player != null and player.visible:
		if director != null and director.camera != null:
			director.camera.position = player.position.lerp(GATE_RECT.get_center(), 0.38) if vent_crawl_t > 0.0 else player.position
		if not GameState.brabant_hatched:
			GameState.egg_warmth = maxf(16.0, GameState.egg_warmth - delta * 0.42)
			_frost_emit_t -= delta
			if _frost_emit_t <= 0.0:
				_frost_emit_t = 0.55
				_spawn_fx(player.position + Vector2(0, -10), Color(0.66, 0.84, 0.98, 0.72), 3)
		elif GameState.brabant_vent_unlocked and not GameState.brabant_sling_practiced and not _sling_gate_warned and player.position.x >= 1975.0 and not ui.is_blocking_gameplay():
			_trigger_louvain_sling_threshold()
		update_nearest_interactable(player.position)
		if ui != null:
			ui.update_world_map_state("brabant_fens", player.position)
	queue_redraw()
	queue_foreground_redraw()


func _step_particles(delta: float) -> void:
	for i in range(fx_particles.size() - 1, -1, -1):
		var p: Dictionary = fx_particles[i]
		p["life"] = float(p["life"]) - delta
		p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
		if float(p["life"]) <= 0.0:
			fx_particles.remove_at(i)


func _spawn_fx(origin: Vector2, col: Color, count: int = 12) -> void:
	for _i in range(count):
		var ang := randf() * TAU
		var spd := randf_range(24.0, 78.0)
		fx_particles.append({
			"pos": origin + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"life": randf_range(0.35, 0.72),
			"max_life": 0.72,
			"sz": randf_range(2.2, 4.2),
			"col": col,
		})


func _start_kestrel_arrival() -> void:
	intro_active = true
	intro_stage = 0
	intro_t = 0.0
	intro_wait_dlg = false
	intro_dlg_done = false
	kestrel_visible = true
	kestrel_pos = KESTREL_LANDING_POS
	kestrel_alt = 190.0
	player.position = KESTREL_LANDING_POS + Vector2(24, 18)
	player.cutscene_hidden = true
	player.can_move = false
	ui.set_cinematic_mode(true, _skip_kestrel_arrival)
	SoundManager.play_wing_beat()


func _skip_kestrel_arrival() -> void:
	intro_active = false
	intro_wait_dlg = false
	intro_dlg_done = true
	kestrel_visible = false
	player.cutscene_hidden = false
	player.position = KESTREL_LANDING_POS + Vector2(48, 4)
	player.facing = Vector2.RIGHT
	player.set_carry_prop("egg", "cradle")
	if director != null and director.camera != null:
		director.camera.position = player.position
		director.camera.reset_smoothing()
	if ui != null:
		if ui.dialogue_panel != null:
			ui.dialogue_panel.hide_box()
		ui.set_cinematic_mode(false)
	_sync_hint_context()


func _step_kestrel_arrival(delta: float) -> void:
	if intro_wait_dlg:
		if director != null and director.camera != null:
			director.camera.position = kestrel_pos.lerp(player.position, 0.5)
		return
	intro_t += delta
	if intro_stage == 0:
		var p := clampf(intro_t / 1.6, 0.0, 1.0)
		kestrel_alt = lerpf(190.0, 0.0, p * (2.0 - p))
		if director != null and director.camera != null:
			director.camera.position = kestrel_pos + Vector2(0, -kestrel_alt * 0.45)
		if int(intro_t * 2.4) > int((intro_t - delta) * 2.4):
			SoundManager.play_wing_beat()
		if p >= 1.0:
			intro_stage = 1
			intro_t = 0.0
			player.cutscene_hidden = false
			player.position = kestrel_pos + Vector2(44, 10)
			player.facing = Vector2.LEFT
			player.set_carry_prop("egg", "cradle")
			SoundManager.play_hatch_chirp()
			SoundManager.play_dragon_purr()
			_spawn_fx(kestrel_pos + Vector2(18, 0), Color(0.84, 0.90, 0.96), 12)
	elif intro_stage == 1:
		if director != null and director.camera != null:
			director.camera.position = kestrel_pos.lerp(player.position, 0.5)
		if not intro_dlg_done and intro_t >= 0.75:
			intro_wait_dlg = true
			ui.show_dialogue([
				{
					"speaker": GameState.player_name,
					"portrait": "portrait_boy17.png",
					"text": "Easy now, Kestrel... you carried us miles south of Bruges before first watch even changed. Those old millstones out in the mist—we've reached the fens west of Louvain."
				},
				{
					"speaker": GameState.player_name,
					"portrait": "portrait_boy17.png",
					"text": "You can't stay hunkered in these reeds till sunrise. If Captain Anna finds your perch empty at dawn, Saddler Hendrick will turn every parish road in Brabant upside down looking for us."
				},
				{
					"speaker": GameState.player_name,
					"portrait": "portrait_boy17.png",
					"text": "Get back above the clouds while the dark still covers your wings. I have to find what my parents died hiding near Old Heverlee, and keep this black-and-gold egg out of any iron vault. I'll hail Anna's forward scouts from quiet campfires once it's safe."
				}
			], func():
				intro_wait_dlg = false
				intro_dlg_done = true
				intro_stage = 2
				intro_t = 0.0
				SoundManager.play_hatch_chirp()
				SoundManager.play_wing_beat()
				_spawn_fx(kestrel_pos, Color(0.86, 0.92, 0.98), 18)
			)
	elif intro_stage == 2:
		var p2 := clampf(intro_t / 1.75, 0.0, 1.0)
		kestrel_pos = KESTREL_LANDING_POS.lerp(KESTREL_LANDING_POS + Vector2(380, -260), p2 * p2)
		kestrel_alt = 240.0 * p2
		if int(intro_t * 2.5) > int((intro_t - delta) * 2.5):
			SoundManager.play_wing_beat()
		if director != null and director.camera != null:
			director.camera.position = player.position
		if p2 >= 1.0:
			intro_stage = 3
			intro_t = 0.0
			kestrel_visible = false
	else:
		# Brief seamless BotW-style camera glimpse down the causeway toward the glowing Mill Hearth
		var g_prog := clampf(intro_t / 0.90, 0.0, 1.0)
		var g_arc := sin(g_prog * PI)
		if director != null and director.camera != null:
			director.camera.position = player.position.lerp(CAMPFIRE_POS, g_arc * 0.85)
		if g_prog >= 1.0:
			intro_active = false
			player.facing = Vector2.RIGHT
			if director != null and director.camera != null:
				director.camera.position = player.position
				director.camera.reset_smoothing()
			ui.set_cinematic_mode(false)
			_sync_hint_context()


func _on_interact_campfire() -> void:
	if hatch_anim_active or intro_active:
		return
	if not GameState.brabant_hatched:
		_start_hatching_sequence()
		return
	ui.open_campfire_roost("brabant_fens", CAMPFIRE_POS, "Old Mill Campfire", false, "Kestrel Scouted North")


func _start_hatching_sequence() -> void:
	hatch_anim_active = true
	hatch_anim_stage = 0
	hatch_anim_t = 0.0
	player.can_move = false
	player.position = CAMPFIRE_POS + Vector2(-18, 12)
	player.facing = Vector2.RIGHT
	player.set_carry_prop("", "")
	player.set_cutscene_pose("boy_kneel.png")
	ui.set_cinematic_mode(true)
	SoundManager.play_campfire_warm()


func _step_hatching_sequence(delta: float) -> void:
	hatch_anim_t += delta
	if hatch_anim_stage == 0 and hatch_anim_t >= 0.85:
		hatch_anim_stage = 1
		hatch_anim_t = 0.0
		SoundManager.play_egg_crack()
		_spawn_fx(CAMPFIRE_POS + Vector2(38, 6), Color(0.96, 0.82, 0.34), 10)
	elif hatch_anim_stage == 1 and hatch_anim_t >= 0.90:
		hatch_anim_stage = 2
		hatch_anim_t = 0.0
		SoundManager.play_egg_crack()
		director.trigger_camera_shake(4.0, 0.18)
		_spawn_fx(CAMPFIRE_POS + Vector2(38, 6), Color(1.0, 0.88, 0.44), 18)
	elif hatch_anim_stage == 2 and hatch_anim_t >= 0.85:
		hatch_anim_stage = 3
		hatch_anim_t = 0.0
		SoundManager.play_hatch_chirp()
		SoundManager.play_dragon_purr()
		_spawn_fx(CAMPFIRE_POS + Vector2(38, 4), Color(1.0, 0.86, 0.38), 24)
	elif hatch_anim_stage == 3 and hatch_anim_t >= 1.1:
		hatch_anim_active = false
		player.set_cutscene_pose("")
		GameState.brabant_hatched = true
		GameState.carrying_egg = false
		GameState.egg_warmth = 100.0
		GameState.remove_item("Black-and-Gold Dragon Egg")
		GameState.active_companion_stage = 1
		if GameState.dragon_bond < 10:
			GameState.dragon_bond = 10
		if director != null and director.companion != null:
			director.companion.position = CAMPFIRE_POS + Vector2(38, 8)
		_sync_campfire_label()
		ui.set_cinematic_mode(false)
		ui.refresh_hud()
		ui.open_dragon_name_prompt(func(_chosen: String):
			SoundManager.play_dragon_purr()
			_sync_campfire_label()
			ui.show_dialogue([
				{
					"speaker": GameState.player_name,
					"portrait": "portrait_boy17.png",
					"text": "Look at those scales... dark as bog iron, yet traced all down your crest in living royal gold. No ordinary marsh beast."
				},
				{
					"speaker": GameState.player_name,
					"portrait": "portrait_boy17.png",
					"text": "Easy now, %s... that cold flight drained the heat right out of you. Good thing I packed dried smoked ration—let's carve a warm share by these coals first before even thinking of Louvain." % GameState.gold_dragon_name
				}
			], func():
				_sync_hint_context()
				ui.refresh_hud()
			)
		)


func _on_interact_cache() -> void:
	if not GameState.brabant_briar_burned or GameState.brabant_cache_looted:
		return
	GameState.brabant_cache_looted = true
	GameState.raw_rations += 1
	GameState.smoke_pellets += 1
	GameState.add_item("Raw River Ration")
	SoundManager.play_chime()
	player.show_held_item(assets.get_tex("prop_smoke_pellet.png"), 1.1)
	_spawn_fx(CACHE_POS, Color(0.98, 0.86, 0.42), 14)
	ui.pulse_hud_icon("bag")
	ui.refresh_hud()


func _on_interact_cairn() -> void:
	if cairn_relic_claimed:
		return
	cairn_relic_claimed = true
	GameState.raw_rations += 1
	GameState.add_dragon_bond(5)
	SoundManager.play_chime()
	_spawn_fx(GOLD_RELIC_POS, Color(1.0, 0.88, 0.38), 16)
	if director != null and director.companion != null:
		director.companion.notify_progress()
	ui.refresh_hud()


func _on_read_east_sign() -> void:
	ui.show_dialogue([
		{
			"speaker": "Milepost & Church Notice",
			"portrait": "portrait_inquisitor.png",
			"text": "\"WALL OF LOUVAIN — WEST DIKE GATE. BY ORDER OF THE INQUISITION: Twenty golden florins for any black-and-gold wyrmling or carrier seized inside Brabant parish walls. All riders inspect harnesses at the tollhouse.\""
		}
	])


func _trigger_louvain_sling_threshold() -> void:
	_sling_gate_warned = true
	player.velocity = Vector2.ZERO
	ui.show_dialogue([
		{
			"speaker": GameState.player_name,
			"portrait": "portrait_boy17.png",
			"text": "Hold up—see those crimson Church lanterns and halberd silhouettes beyond the gate arch? Twenty golden florins on a black-and-gold wyrmling means Watchmen will slam the portcullis before we reach the first bridge."
		},
		{
			"speaker": GameState.gold_dragon_name,
			"portrait": GameState.get_hatchling_portrait(),
			"telepathic": true,
			"text": "Then pull up your oiled hood and tuck me tight inside your cloak-sling across your ribs. Claws curled quiet until we clear their watch-torches!"
		}
	], func():
		_sync_hint_context()
	)


func _on_enter_louvain() -> void:
	if not is_portal_unlocked("brabant_to_louvain"):
		if GameState.brabant_vent_unlocked and not _sling_gate_warned:
			_trigger_louvain_sling_threshold()
		return
	director.load_region("louvain", {"spawn": Vector2(118, 880), "facing": Vector2.RIGHT})


func is_portal_unlocked(id: String) -> bool:
	if id == "brabant_to_louvain":
		return GameState.brabant_vent_unlocked and (GameState.brabant_sling_practiced or GameState.companion_posture == "sling")
	return true


func is_interactable_active(id: String) -> bool:
	if id == "bf_cache":
		return GameState.brabant_briar_burned and not GameState.brabant_cache_looted
	if id == "bf_cairn":
		return not cairn_relic_claimed
	return true


func get_gold_sense_targets() -> Array:
	var targets: Array = []
	if not cairn_relic_claimed:
		targets.append(GOLD_RELIC_POS)
	if not GameState.brabant_vent_unlocked:
		targets.append(VENT_POS)
	if not GameState.brabant_briar_burned:
		targets.append(BRIAR_POS)
	return targets


func get_last_dragon_command_kind() -> String:
	return _last_command_kind


func get_vent_crawl_duration() -> float:
	return VENT_CRAWL_DUR


func get_vent_return_pos() -> Vector2:
	return Vector2(1332, 704)


func _near_unlit_brazier(origin: Vector2, target_pos: Vector2) -> bool:
	for b: Dictionary in brazier_states:
		if not bool(b.get("lit", false)):
			var bp := Vector2(b["pos"])
			if origin.distance_to(bp) <= 96.0 or target_pos.distance_to(bp) <= 84.0:
				return true
	return false


func on_dragon_command(origin: Vector2, target_pos: Vector2, _aim: Vector2, _stage: int) -> bool:
	_last_command_kind = ""
	# 1. Mill Sluice Drain Crawl -> pulls east inside lever to raise gate
	if not GameState.brabant_vent_unlocked and (origin.distance_to(VENT_POS) <= 78.0 or target_pos.distance_to(VENT_POS) <= 64.0):
		_last_command_kind = "vent_crawl"
		GameState.brabant_vent_unlocked = true
		vent_crawl_t = VENT_CRAWL_DUR
		_vent_lever_tripped = false
		gate_open_anim = 0.0
		GameState.add_dragon_bond(5)
		set_body_collision_enabled(gate_body, false)
		_spawn_fx(VENT_POS + Vector2(-14, 0), Color(0.56, 0.58, 0.62), 8)
		if director != null and director.companion != null:
			director.companion.notify_progress()
		_sync_hint_context()
		ui.refresh_hud()
		return true

	# Hungry newborn coughs ash wisps before tasting warm ration at camp
	if GameState.hatchling_fed_count <= 0:
		if origin.distance_to(BRIAR_POS) <= 105.0 or target_pos.distance_to(BRIAR_POS) <= 95.0 or _near_unlit_brazier(origin, target_pos):
			_last_command_kind = "dry_cough"
			if not _unfed_briar_warned:
				_unfed_briar_warned = true
				ui.show_dialogue([{"speaker": GameState.player_name, "portrait": "portrait_boy17.png", "text": "Only cold soot-dust... your belly's still empty after that freezing flight. Let's carve warm ration by the fire first."}])
		return false

	# 2. Small Cinder Embers on Dry Fen Briars
	if not GameState.brabant_briar_burned and (origin.distance_to(BRIAR_POS) <= 105.0 or target_pos.distance_to(BRIAR_POS) <= 95.0):
		_last_command_kind = "ember_puff"
		GameState.brabant_briar_burned = true
		set_body_collision_enabled(briar_body, false)
		SoundManager.play_campfire_warm()
		_spawn_fx(BRIAR_POS, Color(0.98, 0.58, 0.18), 16)
		if director != null and director.companion != null:
			director.companion.notify_progress()
		_sync_hint_context()
		return true

	# 3. Small Cinder Embers on Stone Way-Braziers
	for bi in range(brazier_states.size()):
		var b: Dictionary = brazier_states[bi]
		if bool(b.get("lit", false)):
			continue
		var bp := Vector2(b["pos"])
		if origin.distance_to(bp) <= 96.0 or target_pos.distance_to(bp) <= 84.0:
			_last_command_kind = "ember_puff"
			b["lit"] = true
			SoundManager.play_campfire_warm()
			_spawn_fx(bp + Vector2(0, -10), Color(1.0, 0.72, 0.24), 12)
			return true
	return false


func _sync_hint_context() -> void:
	if director == null or director.companion == null:
		return
	if not GameState.brabant_hatched:
		director.companion.clear_hint_context()
		return
	if GameState.hatchling_fed_count == 0:
		director.companion.set_hint_context(
			"bf_feed",
			["Cold wet ribs against empty scales..."],
			CAMPFIRE_POS,
			24.0
		)
	elif not GameState.brabant_briar_burned:
		director.companion.set_hint_context(
			"bf_briar",
			["Those dry dead thorns south of the fire smell dusty enough to catch a warm hearth-spark."],
			BRIAR_POS,
			30.0
		)
	elif not GameState.brabant_vent_unlocked:
		director.companion.set_hint_context(
			"bf_vent",
			["A warm golden tug brushes your ribs—low iron bars by the mill sluice look wide enough for small soot-black claws to squeeze beneath."],
			VENT_POS,
			28.0
		)
	elif not GameState.brabant_sling_practiced:
		director.companion.set_hint_context(
			"bf_sling",
			["Keep scales hidden in folds of dark wool before stepping beneath Louvain's watch lanterns."],
			EAST_SIGN_POS,
			32.0
		)
	else:
		director.companion.clear_hint_context()


func get_surface_at(pos: Vector2) -> String:
	if Rect2(140, 646, 172, 128).has_point(pos) or Rect2(1732, 656, 144, 114).has_point(pos):
		return "wood"
	if Rect2(760, 430, 598, 430).has_point(pos):
		return "cobble"
	return "grass"


func get_ambience_track() -> String:
	return "amb_wilds"


func get_lighting_tint() -> Color:
	return Color(0.68, 0.76, 0.88) if GameState.brabant_hatched else Color(0.38, 0.45, 0.62)


func update_region_lights(_time_val: float) -> void:
	if egg_light != null and player != null:
		egg_light.visible = not GameState.brabant_hatched and not player.cutscene_hidden
		egg_light.position = player.position + Vector2(0, -8)
	var lit_only: Array[PointLight2D] = [region_lights[0]]
	if egg_light != null and egg_light.visible:
		lit_only.append(egg_light)
	for bi in range(brazier_lights.size()):
		if bi < brazier_states.size() and bool(brazier_states[bi].get("lit", false)):
			brazier_lights[bi].visible = true
			lit_only.append(brazier_lights[bi])
		else:
			brazier_lights[bi].visible = false
	sync_light_frustum(lit_only, true)


func _draw() -> void:
	BrabantFensDrawScript.draw_region_entities(self, Time.get_ticks_msec() * 0.001)
