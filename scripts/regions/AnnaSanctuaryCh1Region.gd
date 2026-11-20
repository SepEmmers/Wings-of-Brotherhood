extends "res://scripts/regions/RegionBase.gd"

## Book II Anna Chapter 1 Part 1 — Sanctuary Council Deception (1280x820):
## Play directly as Captain Anna beside Kestrel, Saddler Matthijs, Elders Hendrick, and Virelai.
## Inspect Kestrel's leg-band dispatch, misdirect Hendrick toward coastal Ostend/Ghent traps,
## pack Hesbaye rations on Kestrel, and mount Virelai for the Twilight River Blood-Barge Raid.

const HALL_BOUNDS := Rect2(200, 140, 880, 520)
const KESTREL_POS := Vector2(360, 270)
const HENDRICK_POS := Vector2(610, 268)
const MATTHIJS_POS := Vector2(780, 310)
const VIRELAI_POS := Vector2(948, 390)

var static_colliders: Array[Rect2] = []
var anna_pos: Vector2 = Vector2(460, 460)
var anna_facing: Vector2 = Vector2.UP
var satchel_packed: bool = false
var _choice_panel: PanelContainer = null
var hall_lights: Array[PointLight2D] = []


func _ready() -> void:
	colliders = StaticBody2D.new()
	add_child(colliders)
	static_colliders = [
		Rect2(0, 0, 1280, 140),
		Rect2(0, 660, 1280, 160),
		Rect2(0, 0, 200, 820),
		Rect2(1080, 0, 200, 820),
		Rect2(520, 360, 176, 62), # Council hearth table
	]
	for crect: Rect2 in static_colliders:
		add_box_collider(colliders, crect)

	for lp: Vector2 in [Vector2(630, 390), Vector2(360, 280), Vector2(980, 420)]:
		var pl: PointLight2D = assets.make_point_light(lp, 3.0, Color(1.0, 0.78, 0.38), 0.78)
		add_child(pl)
		hall_lights.append(pl)

	setup_static_ground_chunks(
		Rect2(0, 0, 1280, 820),
		func(canvas: Node2D): _draw_static_ground(canvas),
		720,
		-2,
		false
	)
	ensure_foreground_layer(func(fg: Node2D): _draw_foreground(fg), 18)
	_build_interactables()


func uses_standard_player_movement() -> bool:
	return false


func get_active_npc_colliders() -> Array:
	return [KESTREL_POS, HENDRICK_POS, MATTHIJS_POS, VIRELAI_POS]


func _build_interactables() -> void:
	interactables = [
		{"id": "an_kestrel", "name": "Unroll Kestrel's Dispatch", "pos": KESTREL_POS, "radius": 68.0, "callback": _on_inspect_kestrel},
		{"id": "an_hendrick", "name": "Confront Saddler Hendrick", "pos": HENDRICK_POS, "radius": 72.0, "callback": _on_confront_hendrick},
		{"id": "an_matthijs", "name": "Pack Hesbaye Satchel with Matthijs", "pos": MATTHIJS_POS, "radius": 70.0, "callback": _on_pack_satchel},
		{"id": "an_virelai", "name": "Mount Virelai for River Raid", "pos": VIRELAI_POS, "radius": 82.0, "callback": _on_mount_virelai},
	]


func enter_region(_opts: Dictionary = {}) -> void:
	GameState.active_perspective = "anna"
	GameState.book2_started = true
	if int(GameState.current_step) < int(GameState.QuestStep.BOOK2_ANNA_SORTIE_1):
		GameState.current_step = GameState.QuestStep.BOOK2_ANNA_SORTIE_1
	GameState.unlock_realm_node("bruges_sanctuary")

	anna_pos = Vector2(460, 470)
	anna_facing = Vector2.UP
	satchel_packed = GameState.inventory.has("Anna's Hesbaye Supply Satchel")
	if player != null:
		player.visible = false
		player.cutscene_hidden = true
		player.can_move = false
		player.position = anna_pos

	if director != null and director.camera != null:
		director.camera.limit_left = 0
		director.camera.limit_top = 0
		director.camera.limit_right = 1280
		director.camera.limit_bottom = 820
		director.camera.position = Vector2(640, 410)

	ui.set_hud_visible(true)
	ui.set_flight_hud_mode(false)
	ui.update_world_map_state("sanctuary", anna_pos)
	ui.refresh_hud()
	SoundManager.set_ambience("amb_hearth")
	ui.show_dialogue([
		{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "Captain—Kestrel dropped in from Old Heverlee half-frozen with brass blood-scrolls strapped to her ankle."},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Read it twice and keep your voice low before Hendrick catches wind. We'll point the Council toward the sea and clear the river convoy ourselves."}
	])


func exit_region() -> void:
	_close_choice_panel()


func handle_region_input(event: InputEvent) -> bool:
	if _choice_panel != null and is_instance_valid(_choice_panel):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_choice_panel()
			return true
		return false
	if event.is_action_pressed("interact") and not (ui != null and ui.is_blocking_gameplay()):
		update_nearest_interactable(anna_pos)
		return interact_with_nearest()
	return false


func _hits_anna_blocker(pos: Vector2) -> bool:
	if point_hits_colliders(pos, static_colliders, 12.0):
		return true
	for npc_p in get_active_npc_colliders():
		if pos.distance_to(Vector2(npc_p) + Vector2(0.0, 4.0)) < 20.0:
			return true
	return false


func step_region(delta: float) -> void:
	if (ui != null and ui.is_blocking_gameplay()) or (_choice_panel != null and is_instance_valid(_choice_panel)):
		queue_redraw()
		queue_foreground_redraw()
		return
	var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if mv.length() > 0.1:
		anna_facing = mv.normalized()
		var nxt := anna_pos + anna_facing * 165.0 * delta
		if not _hits_anna_blocker(nxt):
			anna_pos = nxt
		elif not _hits_anna_blocker(Vector2(nxt.x, anna_pos.y)):
			anna_pos.x = nxt.x
		elif not _hits_anna_blocker(Vector2(anna_pos.x, nxt.y)):
			anna_pos.y = nxt.y
		if player != null:
			player.position = anna_pos
	if director != null and director.camera != null:
		director.camera.position = anna_pos
	update_nearest_interactable(anna_pos)
	queue_redraw()
	queue_foreground_redraw()


func _focus_anna_on(target_pos: Vector2) -> void:
	last_interacted_pos = target_pos
	if target_pos.distance_to(anna_pos) > 2.0:
		anna_facing = (target_pos - anna_pos).normalized()


func _on_inspect_kestrel() -> void:
	_focus_anna_on(KESTREL_POS)
	ui.show_dialogue([
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "\"Inquisitors murdered his parents at Old Heverlee... Clara captive at Namur Quarry... live dragon hearts drained for an iron ritual.\""},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Easy, Kestrel girl—catch your breath beside Matthijs's fire before we send supplies back west."}
	])


func _on_confront_hendrick() -> void:
	_focus_anna_on(HENDRICK_POS)
	if GameState.anna_ch1_council_done:
		ui.show_dialogue([{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Our cliff patrol rides north for the coast at once—no Church tracker will trace an egg down the inland canals while I hold Council seal!"}])
		return
	_open_deception_choice()


func _open_deception_choice() -> void:
	_close_choice_panel()
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(520, 230)
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.offset_left = -260
	pc.offset_top = -115
	pc.offset_right = 260
	pc.offset_bottom = 115
	assets.style_parchment_panel(pc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)

	var h := Label.new()
	h.text = "MISDIRECT SADDLER HENDRICK'S COUNCIL"
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(0.96, 0.84, 0.48))
	vb.add_child(h)

	var sub := Label.new()
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.text = "Hendrick demands where the boy carried the black-and-gold egg. Choose how Anna throws the cautious Council off the Brabant trail:"
	sub.add_theme_font_size_override("font_size", 13)
	vb.add_child(sub)

	for opt: Dictionary in [
		{"id": "ostend", "label": "Claim smugglers rowed north toward Ostend sea-caves"},
		{"id": "ghent",  "label": "Present forged Ghent barge-tallies heading west"},
	]:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 38)
		btn.text = String(opt["label"])
		var oid := String(opt["id"])
		btn.pressed.connect(func(): _choose_deception(oid))
		vb.add_child(btn)

	ui.add_child(pc)
	_choice_panel = pc
	assets.style_buttons_recursive(pc)
	ui.emit_signal("modal_state_changed")


func _choose_deception(choice_id: String) -> void:
	_close_choice_panel()
	GameState.anna_ch1_deception_choice = choice_id
	GameState.anna_ch1_council_done = true
	SoundManager.play_chime()
	var line := "Fine! Let coastal scouts sweep the Ostend reefs while Kestrel flies straight inland for Hesbaye!" if choice_id == "ostend" else "A forged Ghent manifest buys our lad an extra four days across Brabant!"
	ui.show_dialogue([
		{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "I'll dispatch three scout pairs westward before sunrise—nobody hides a loose egg on my cliffs!"},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": line}
	])


func _close_choice_panel() -> void:
	if _choice_panel != null and is_instance_valid(_choice_panel):
		_choice_panel.queue_free()
	_choice_panel = null
	if ui != null:
		ui.emit_signal("modal_state_changed")


func _on_pack_satchel() -> void:
	_focus_anna_on(MATTHIJS_POS)
	if not satchel_packed:
		satchel_packed = true
		GameState.add_item("Anna's Hesbaye Supply Satchel")
		SoundManager.play_chime()
		ui.pulse_hud_icon("bag")
	ui.show_dialogue([
		{"speaker": "Saddler Matthijs", "portrait": "portrait_matthijs.png", "text": "Double-oiled rations, hemp splices, and flint stowed neat on Kestrel's flank-pack—light enough for high gale winds."},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Mount up with me at the cliff edge once Hendrick walks clear—there's a Church blood-convoy chaining barges upriver tonight."}
	])


func _on_mount_virelai() -> void:
	_focus_anna_on(VIRELAI_POS)
	if not GameState.anna_ch1_council_done:
		ui.show_dialogue([{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Throw Hendrick off the scent first before we lift off—if he guesses Brabant, he'll send riders after my nephew."}])
		return
	if not satchel_packed:
		satchel_packed = true
		GameState.add_item("Anna's Hesbaye Supply Satchel")
	SoundManager.play_dragon_roar()
	director.load_region("anna_ch1_raid", {})


func is_interactable_active(id: String) -> bool:
	if id == "an_hendrick" and GameState.anna_ch1_council_done:
		return false
	return true


func _draw_static_ground(canvas: Node2D) -> void:
	var stone1: Texture2D = assets.get_tex("tile_sandstone_flag.png", "tile_cobble.png")
	var stone2: Texture2D = assets.get_tex("tile_sandstone_flag_2.png", "tile_sandstone_flag.png")
	var wood: Texture2D = assets.get_tex("tile_wood_floor.png")
	var cl1: Texture2D = assets.get_tex("tile_catacomb_stone.png", "tile_frost_slate.png")
	var cl2: Texture2D = assets.get_tex("tile_catacomb_stone_2.png", "tile_catacomb_stone.png")
	assets.draw_varied_tiled_rect(canvas, Rect2(0, 0, 1280, 820), cl1, cl2, 32.0, 3)
	assets.draw_varied_tiled_rect(canvas, HALL_BOUNDS, stone1, stone2, 32.0, 9)
	# Warm wooden oak council floor inlay around hearth + gold edge border
	assets.draw_varied_tiled_rect(canvas, Rect2(440, 260, 360, 260), wood, wood, 32.0, 5)
	canvas.draw_rect(Rect2(440, 260, 360, 260), Color(0.68, 0.52, 0.24, 0.72), false, 2.0)
	canvas.draw_rect(HALL_BOUNDS, Color(0.74, 0.60, 0.30, 0.80), false, 3.0)
	# Council Oak Hearth Table with chamfered rim
	canvas.draw_rect(Rect2(520, 360, 176, 62), Color(0.24, 0.14, 0.09))
	canvas.draw_rect(Rect2(524, 364, 168, 54), Color(0.42, 0.26, 0.16))
	canvas.draw_rect(Rect2(524, 364, 168, 54), Color(0.68, 0.50, 0.28, 0.5), false, 1.5)


func _draw() -> void:
	var t_now: float = assets.time_elapsed
	var cf: Texture2D = assets.get_tex("prop_campfire_%d.png" % (int(t_now * 6.0) % 2), "prop_campfire_0.png")
	if cf != null:
		draw_texture_rect(cf, Rect2(Vector2(608, 386) - Vector2(20, 20), Vector2(40, 40)), false)

	var drawables: Array[Dictionary] = [
		{"kind": "kestrel", "pos": KESTREL_POS, "y": KESTREL_POS.y + 10.0},
		{"kind": "npc", "pos": MATTHIJS_POS, "tex": "npc_matthijs.png", "dir": Vector2.LEFT, "y": MATTHIJS_POS.y + 10.0},
		{"kind": "anna", "pos": anna_pos, "y": anna_pos.y + 10.0},
		{"kind": "virelai", "pos": VIRELAI_POS, "y": VIRELAI_POS.y + 20.0},
	]
	if not GameState.anna_ch1_council_done:
		drawables.append({"kind": "npc", "pos": HENDRICK_POS, "tex": "npc_hendrick.png", "dir": Vector2.DOWN, "y": HENDRICK_POS.y + 10.0})
	drawables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))

	for d: Dictionary in drawables:
		var k := String(d["kind"])
		var dp := Vector2(d["pos"])
		if k == "anna":
			assets.draw_npc_sprite(self, dp, "npc_anna.png", "", assets.get_ui_font(), Color.WHITE, anna_facing.x < -0.1)
		elif k == "npc":
			assets.draw_npc_sprite(self, dp, String(d["tex"]), "", assets.get_ui_font(), Color.WHITE, Vector2(d["dir"]).x < -0.1)
		elif k == "kestrel":
			var kt: Texture2D = assets.get_tex("dragon_greyling_%d.png" % (int(t_now * 4.0) % 2), "dragon_greyling.png")
			if kt != null:
				draw_texture_rect(kt, Rect2(dp - Vector2(24, 22), Vector2(48, 40)), false)
		elif k == "virelai":
			var vt: Texture2D = assets.get_tex("dragon_anna_%d.png" % (int(t_now * 3.8) % 2), "dragon_anna.png")
			if vt != null:
				draw_texture_rect(vt, Rect2(dp - Vector2(46, 36), Vector2(92, 72)), false)


func _draw_foreground(fg: Node2D) -> void:
	if not (ui != null and ui.is_blocking_gameplay()) and (_choice_panel == null or not is_instance_valid(_choice_panel)):
		draw_interact_bubble_if_active_on(fg, assets.get_ui_font())


func get_surface_at(_pos: Vector2) -> String:
	return "wood"


func get_ambience_track() -> String:
	return "amb_hearth"


func get_lighting_tint() -> Color:
	return Color(0.84, 0.80, 0.88)


func update_region_lights(_time_val: float) -> void:
	sync_light_frustum(hall_lights, true)
