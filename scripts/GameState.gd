extends Node

## Global story, non-linear quest flags, knot progression, and bestiary state.

enum QuestStep {
	ON_THE_SHIP = 0,
	EXPLORE_BRUGES = 1,
	EVENING_HOME = 2,
	DAWN_MISSING_CLARA = 3,
	SNITCH_TO_CHURCH = 4,
	BROTHERHOOD_AMBUSH = 5,
	ACT2_SANCTUARY = 6,
	ACT2_VIRELAI_SORTIE_1 = 7,
	ACT2_VIRELAI_SORTIE_2 = 8,
	ACT3_WILDS_TRACKING = 9,
	ACT3_EGG_TREK = 10,
	BOOK1_WATCHTOWER_HEARTH = 11,
	ACT4_SANCTUARY_DEBATE = 12,
	ACT4_BRUGES_CITY = 13,
	ACT4_NIGHT_HEIST = 14,
	# Book II ("The Golden Heir")
	BOOK2_BRABANT_FENS = 15,
	BOOK2_LOUVAIN_HATCH = 16,
	BOOK2_OLD_HEVERLEE = 17,
	BOOK2_ANNA_SORTIE_1 = 18,
	BOOK2_NAMUR_CROSSING = 19,
	BOOK2_ANNA_SORTIE_2 = 20,
	BOOK2_ARDENNES_SHED = 21,
	BOOK2_BLOOD_CITADEL = 22
}

const KnotCatalogScript := preload("res://scripts/data/KnotCatalog.gd")
const SettingsConfigScript := preload("res://scripts/data/SettingsConfig.gd")

const KNOT_ORDER: Array[String] = KnotCatalogScript.KNOT_ORDER
const KNOT_DATA: Dictionary = KnotCatalogScript.KNOT_DATA

signal state_updated
signal knot_changed(knot_id: String)
signal settings_changed

var player_name: String = "Bram"
var sister_name: String = "Clara"
var uncle_name: String = "Uncle Willem"

var current_step: int = QuestStep.ON_THE_SHIP
var inventory: Array[String] = []
var boy_hp: int = 4
var boy_max_hp: int = 4
var has_dock_knife: bool = true

# Organic Bruges flags (no rigid hand-holding)
var ship_docked: bool = false
var ship_moored: bool = false
var carrying_crate: bool = false
var cargo_delivered: bool = false
var visited_clara: bool = false
var drifted_crate_recovered: bool = false
var shuttle_pouch_recovered: bool = false
var clara_gift_received: bool = false
var bought_bread: bool = false
var heard_herald: bool = false
var inspected_knot_clue: bool = false
var talked_to_uncle_home: bool = false
var talked_to_sister_home: bool = false
var has_mariner_compass: bool = false
var bruges_noticeboard_read: bool = false
var bruges_twine_cache_cut: bool = false
var bruges_roll_practiced: bool = false
var bruges_stealth_alerts: int = 0

# Book I Ch. 2-3: 5-Year Sanctuary Brotherhood Arc (Age 12 -> 17), Sorties & Wilds
var boy_age: int = 12
var sanctuary_phase: int = 1 # 1 = Year 1 (Age 12), 2 = Year 3 (Age 14), 3 = Year 5 (Age 17)
var dragon_trust: int = 0
var sanctuary_carrying_item: String = "" # "" | "leather" | "water"
var sanctuary_leather_chore_done: bool = false
var sanctuary_water_drawn: bool = false
var sanctuary_poultice_brewed: bool = false
var sanctuary_greyling_treated: bool = false
var sanctuary_pennants_strung: bool = false
var sanctuary_virelai_oiled: bool = false
var sanctuary_virelai_talk_done: bool = false
var sanctuary_hendrick_y3_done: bool = false
var sanctuary_kestrel_fed: bool = false
var sanctuary_virelai_fed: bool = false
var sanctuary_drill_mastered: bool = false
var sanctuary_jerkin_earned: bool = false
var sanctuary_final_brief_done: bool = false
var virelai_harness_spliced: bool = false
var greyling_cage_broken: bool = false
var greyling_documented: bool = false
var flight_sortie_id: int = 1
var flight_sortie1_done: bool = false
var flight_sortie2_done: bool = false
var flight_rescued_count: int = 0
var flight_documented_breeds: Array[String] = []
var virelai_harness_hp: int = 100
var virelai_loose_straps: int = 0
var has_forest_map: bool = false
var wilds_clue_tracks: bool = false
var wilds_clue_scorched_pine: bool = false
var discovered_wilds_landmarks: Array[String] = []
var cut_wilds_brambles: Array[String] = []
var active_wilds_zone: String = "Crash Ravine"
var last_safe_fire_pos: Vector2 = Vector2(240, 1890)
var black_dragon_found: bool = false
var carrying_egg: bool = false
var wilds_signal_flare_seen: bool = false
var egg_warmth: float = 100.0

# Book I Ch. 4: Return Debate, Walled City of Bruges, Priest Tailing & Midnight Heist
var act4_egg_debate_done: bool = false
var city_clue_cloth_hall: bool = false
var city_clue_counting_house: bool = false
var city_clue_beguinage: bool = false
var city_watergate_skirmish_won: bool = false
var city_priest_tailed: bool = false
var city_bounty_overheard: bool = false
var city_keep_escape_won: bool = false
var act4_lied_to_council: bool = false
var act4_egg_stolen_back: bool = false
var act4_kestrel_escaped: bool = false

# Book II ("The Golden Heir") Companion, Heat, Campfire & Dual-Perspective State
var active_perspective: String = "boy" # "boy" | "anna"
var active_companion_stage: int = 0 # 0=Egg, 1=Hatchling, 2=Fledgling, 3=Young Drake, 4=Awakened Golden
var companion_posture: String = "assist" # "assist" | "stay" | "sling"
var dragon_bond: int = 0
var hatchling_fed_count: int = 0
var gold_dragon_name: String = "Golden Hatchling"
var city_heat: float = 0.0
var bounty_posters_torn: int = 0
var resonance_chimes: int = 0
var smoke_pellets: int = 0
var raw_rations: int = 0
var campfire_rests: int = 0
var last_campfire_region: String = "brabant_fens"
var last_campfire_pos: Vector2 = Vector2.ZERO
var discovered_realm_nodes: Array[String] = ["bruges_port"]
var book2_started: bool = false
var anna_sortie1_done: bool = false
var anna_sortie2_done: bool = false
var kestrel_courier_ch1_delivered: bool = false
var heverlee_shrine_unlocked: bool = false
var boy_heverlee_relic_found: bool = false

# Book II Act I Milestone 2 flags (Brabant Fens & Louvain)
var brabant_hatched: bool = false
var brabant_feed_intro_done: bool = false
var brabant_sling_practiced: bool = false
var brabant_vent_unlocked: bool = false
var brabant_briar_burned: bool = false
var brabant_cache_looted: bool = false
var brabant_camp_rested: bool = false
var louvain_guild_visited: bool = false
var louvain_bell_mould_fixed: bool = false
var louvain_clay_collected: bool = false
var louvain_herbalist_done: bool = false
var louvain_survivor_done: bool = false
var louvain_ring_found: bool = false
var louvain_vent_opened: bool = false
var louvain_brazier_lit: bool = false
var louvain_crypt_ladder_open: bool = false
var louvain_found_1422: bool = false
var louvain_found_1426: bool = false
var louvain_archive_read: bool = false
var louvain_breakout_won: bool = false

# Knot progression
var rope_unlocked: bool = true
var unlocked_knots: Array[String] = ["clove_hitch"]
var equipped_knot: String = "clove_hitch"
var playtest_speed_mult: float = 1.0

# Persistent player settings (preserved across New Game resets)
var master_volume: float = 0.90
var ambience_volume: float = 0.80
var sfx_volume: float = 0.85
var voices_volume: float = 0.85
var audio_muted: bool = false
var hints_enabled: bool = true
var control_prompts_enabled: bool = true
var dialogue_speed_mode: String = "normal"
var screen_shake_enabled: bool = true
var display_mode: String = "windowed"
var show_playtest_hud_btn: bool = false


func _ready() -> void:
	SettingsConfigScript.load_into_state(self)
	apply_audio_and_display()

func reset_prologue(chosen_name: String) -> void:
	var trimmed := chosen_name.strip_edges()
	player_name = trimmed if not trimmed.is_empty() else "Bram"
	current_step = QuestStep.ON_THE_SHIP
	inventory.clear()
	boy_hp = boy_max_hp
	has_dock_knife = true
	ship_docked = false
	ship_moored = false
	carrying_crate = false
	cargo_delivered = false
	visited_clara = false
	drifted_crate_recovered = false
	shuttle_pouch_recovered = false
	clara_gift_received = false
	bought_bread = false
	heard_herald = false
	inspected_knot_clue = false
	talked_to_uncle_home = false
	talked_to_sister_home = false
	has_mariner_compass = false
	bruges_noticeboard_read = false
	bruges_twine_cache_cut = false
	bruges_roll_practiced = false
	bruges_stealth_alerts = 0
	boy_age = 12
	sanctuary_phase = 1
	dragon_trust = 0
	sanctuary_carrying_item = ""
	sanctuary_leather_chore_done = false
	sanctuary_water_drawn = false
	sanctuary_poultice_brewed = false
	sanctuary_greyling_treated = false
	sanctuary_pennants_strung = false
	sanctuary_virelai_oiled = false
	sanctuary_virelai_talk_done = false
	sanctuary_hendrick_y3_done = false
	sanctuary_kestrel_fed = false
	sanctuary_virelai_fed = false
	sanctuary_drill_mastered = false
	sanctuary_jerkin_earned = false
	sanctuary_final_brief_done = false
	virelai_harness_spliced = false
	greyling_cage_broken = false
	greyling_documented = false
	flight_sortie_id = 1
	flight_sortie1_done = false
	flight_sortie2_done = false
	flight_rescued_count = 0
	flight_documented_breeds.clear()
	virelai_harness_hp = 100
	virelai_loose_straps = 0
	has_forest_map = false
	wilds_clue_tracks = false
	wilds_clue_scorched_pine = false
	discovered_wilds_landmarks.clear()
	cut_wilds_brambles.clear()
	active_wilds_zone = "Crash Ravine"
	last_safe_fire_pos = Vector2(240, 1890)
	black_dragon_found = false
	carrying_egg = false
	wilds_signal_flare_seen = false
	egg_warmth = 100.0
	act4_egg_debate_done = false
	city_clue_cloth_hall = false
	city_clue_counting_house = false
	city_clue_beguinage = false
	city_watergate_skirmish_won = false
	city_priest_tailed = false
	city_bounty_overheard = false
	city_keep_escape_won = false
	act4_lied_to_council = false
	act4_egg_stolen_back = false
	act4_kestrel_escaped = false
	reset_book2_state(false)
	rope_unlocked = true
	unlocked_knots = ["clove_hitch"]
	equipped_knot = "clove_hitch"
	emit_signal("knot_changed", equipped_knot)
	emit_signal("state_updated")


func reset_book2_state(from_book1_finale: bool = false) -> void:
	active_perspective = "boy"
	active_companion_stage = 1 if from_book1_finale else 0
	companion_posture = "assist"
	dragon_bond = 10 if from_book1_finale else 0
	hatchling_fed_count = 0
	gold_dragon_name = "Golden Hatchling"
	city_heat = 0.0
	bounty_posters_torn = 0
	resonance_chimes = 1 if from_book1_finale else 0
	smoke_pellets = 1 if from_book1_finale else 0
	raw_rations = 1 if from_book1_finale else 0
	campfire_rests = 0
	last_campfire_region = "brabant_fens"
	last_campfire_pos = Vector2.ZERO
	if from_book1_finale:
		discovered_realm_nodes.assign(["bruges_port", "bruges_city", "bruges_sanctuary", "whispering_pines", "brabant_fens"])
	else:
		discovered_realm_nodes.assign(["bruges_port"])
	book2_started = from_book1_finale
	anna_sortie1_done = false
	anna_sortie2_done = false
	kestrel_courier_ch1_delivered = false
	heverlee_shrine_unlocked = false
	boy_heverlee_relic_found = false
	brabant_hatched = false
	brabant_feed_intro_done = false
	brabant_sling_practiced = false
	brabant_vent_unlocked = false
	brabant_briar_burned = false
	brabant_cache_looted = false
	brabant_camp_rested = false
	louvain_guild_visited = false
	louvain_bell_mould_fixed = false
	louvain_clay_collected = false
	louvain_herbalist_done = false
	louvain_survivor_done = false
	louvain_ring_found = false
	louvain_vent_opened = false
	louvain_brazier_lit = false
	louvain_crypt_ladder_open = false
	louvain_found_1422 = false
	louvain_found_1426 = false
	louvain_archive_read = false
	louvain_breakout_won = false
	if from_book1_finale:
		boy_age = 17
		boy_hp = boy_max_hp
		sanctuary_phase = 4
		sanctuary_jerkin_earned = true
		active_companion_stage = 0
		unlock_all_knots()
		current_step = QuestStep.BOOK2_BRABANT_FENS
	emit_signal("state_updated")


func unlock_realm_node(node_id: String) -> bool:
	if node_id.is_empty() or discovered_realm_nodes.has(node_id):
		return false
	discovered_realm_nodes.append(node_id)
	emit_signal("state_updated")
	return true


func add_dragon_bond(amount: int) -> void:
	dragon_bond = clampi(dragon_bond + amount, 0, 100)
	emit_signal("state_updated")


func set_companion_posture(new_posture: String) -> void:
	if new_posture in ["assist", "stay", "sling"] and companion_posture != new_posture:
		companion_posture = new_posture
		emit_signal("state_updated")


func cycle_companion_posture() -> String:
	var order: Array[String] = ["assist", "stay", "sling"]
	var idx := order.find(companion_posture)
	companion_posture = order[(idx + 1) % order.size()]
	emit_signal("state_updated")
	return companion_posture


func add_city_heat(delta_heat: float) -> void:
	city_heat = clampf(city_heat + delta_heat, 0.0, 100.0)
	emit_signal("state_updated")


func get_hatchling_portrait() -> String:
	match active_companion_stage:
		1: return "portrait_hatchling_stage1.png"
		2: return "portrait_hatchling_stage2.png"
		3: return "portrait_hatchling_stage3.png"
		4: return "portrait_hatchling_stage4.png"
		_: return "portrait_dragon_black.png"

func get_boy_portrait(angry: bool = false) -> String:
	if boy_age >= 17 or sanctuary_jerkin_earned:
		return "portrait_boy17_angry.png" if angry else "portrait_boy17_neutral.png"
	if boy_age >= 14 or sanctuary_phase >= 2:
		return "portrait_boy14_angry.png" if angry else "portrait_boy14_neutral.png"
	return "portrait_boy_angry.png" if angry else "portrait_boy_neutral.png"


func get_greyling_portrait() -> String:
	if boy_age >= 17 or sanctuary_phase >= 3:
		return "portrait_greyling_y5.png"
	if boy_age >= 14 or sanctuary_phase >= 2:
		return "portrait_greyling_y3.png"
	return "portrait_greyling.png"


func add_dragon_trust(amount: int) -> void:
	dragon_trust = clampi(dragon_trust + amount, 0, 100)
	emit_signal("state_updated")


func record_landmark(lid: String, zone_title: String = "") -> bool:
	if zone_title != "":
		active_wilds_zone = zone_title
	if discovered_wilds_landmarks.has(lid):
		return false
	discovered_wilds_landmarks.append(lid)
	emit_signal("state_updated")
	return true

func record_flight_breed(breed_name: String) -> bool:
	if flight_documented_breeds.has(breed_name):
		return false
	flight_documented_breeds.append(breed_name)
	emit_signal("state_updated")
	return true

func all_evening_errands_done() -> bool:
	return cargo_delivered and visited_clara and bought_bread


func all_city_clues_found() -> bool:
	return city_watergate_skirmish_won and city_clue_counting_house

func unlock_knot(knot_id: String) -> bool:
	var is_new := not unlocked_knots.has(knot_id)
	if is_new and KNOT_DATA.has(knot_id):
		unlocked_knots.append(knot_id)
	equipped_knot = knot_id
	emit_signal("knot_changed", equipped_knot)
	emit_signal("state_updated")
	return is_new

func unlock_all_knots() -> void:
	for k in KNOT_ORDER:
		if not unlocked_knots.has(k):
			unlocked_knots.append(k)
	emit_signal("knot_changed", equipped_knot)
	emit_signal("state_updated")

func cycle_knot() -> void:
	if unlocked_knots.size() <= 1:
		return
	var idx := unlocked_knots.find(equipped_knot)
	equipped_knot = unlocked_knots[(idx + 1) % unlocked_knots.size()]
	SoundManager.play_blip(1.35)
	emit_signal("knot_changed", equipped_knot)
	emit_signal("state_updated")

func get_knot_display(knot_id: String = "") -> String:
	var kid := equipped_knot if knot_id.is_empty() else knot_id
	if KNOT_DATA.has(kid):
		return KNOT_DATA[kid]["name"]
	return kid

func add_item(item_name: String) -> void:
	if not inventory.has(item_name):
		inventory.append(item_name)
		emit_signal("state_updated")

func remove_item(item_name: String) -> void:
	if inventory.has(item_name):
		inventory.erase(item_name)
		emit_signal("state_updated")

func get_diary_summary() -> String:
	var lore_script := load("res://scripts/data/JournalLoreData.gd")
	return lore_script.get_diary_summary()


func get_bestiary_bbcode() -> String:
	var lore_script := load("res://scripts/data/JournalLoreData.gd")
	return lore_script.get_bestiary_bbcode()

func _ensure_input_actions() -> void:
	SettingsConfigScript.ensure_default_input_actions()


func apply_audio_and_display() -> void:
	if SoundManager != null:
		SoundManager.apply_audio_settings(
			master_volume,
			ambience_volume,
			sfx_volume,
			voices_volume,
			audio_muted
		)
	SettingsConfigScript.apply_display_mode(display_mode)


func apply_and_save_settings() -> void:
	apply_audio_and_display()
	SettingsConfigScript.save_from_state(self)
	emit_signal("settings_changed")


func _apply_audio_defaults() -> void:
	var defs: Dictionary = SettingsConfigScript.DEFAULTS
	master_volume = float(defs["master_volume"])
	ambience_volume = float(defs["ambience_volume"])
	sfx_volume = float(defs["sfx_volume"])
	voices_volume = float(defs["voices_volume"])
	audio_muted = bool(defs["audio_muted"])


func _apply_gameplay_defaults() -> void:
	var defs: Dictionary = SettingsConfigScript.DEFAULTS
	hints_enabled = bool(defs["hints_enabled"])
	control_prompts_enabled = bool(defs["control_prompts_enabled"])
	dialogue_speed_mode = str(defs["dialogue_speed_mode"])
	screen_shake_enabled = bool(defs["screen_shake_enabled"])
	display_mode = str(defs["display_mode"])
	show_playtest_hud_btn = bool(defs["show_playtest_hud_btn"])


func reset_audio_settings() -> void:
	_apply_audio_defaults()
	apply_and_save_settings()


func reset_gameplay_settings() -> void:
	_apply_gameplay_defaults()
	apply_and_save_settings()


func reset_all_settings() -> void:
	_apply_audio_defaults()
	_apply_gameplay_defaults()
	SettingsConfigScript.reset_controls_to_defaults()
	apply_and_save_settings()


func reset_controls() -> void:
	SettingsConfigScript.reset_controls_to_defaults()
	SettingsConfigScript.save_from_state(self)
	emit_signal("settings_changed")


func rebind_action(action_name: String, key_code: int) -> Dictionary:
	var res := SettingsConfigScript.rebind_action_primary_key(action_name, key_code)
	if bool(res.get("ok", false)):
		SettingsConfigScript.save_from_state(self)
		emit_signal("settings_changed")
	return res


func get_action_key_label(action_name: String) -> String:
	return SettingsConfigScript.get_action_key_label(action_name)


func get_dialogue_speed_cps() -> float:
	return SettingsConfigScript.get_dialogue_speed_cps(dialogue_speed_mode)
