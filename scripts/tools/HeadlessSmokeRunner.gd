class_name HeadlessSmokeRunner
extends RefCounted

## Automated multi-preset & multi-region headless smoke verifier (--smoke-regions).
## Cycles every PlaytestPresets entry, steps live region ticks, checks [M] Realm
## Charter modes, Mind-Voice telepathy, and Journal formatting before quitting.

const PlaytestPresetsScript := preload("res://scripts/data/PlaytestPresets.gd")
const RealmChartDataScript := preload("res://scripts/data/WorldRealmChartData.gd")
const JournalLoreScript := preload("res://scripts/data/JournalLoreData.gd")
const PlayerCombatHelperScript := preload("res://scripts/systems/PlayerCombatHelper.gd")
const CityHeatHelperScript := preload("res://scripts/systems/CityHeatHelper.gd")

const EXPECTED_BOOK1_REGIONS := [
	"bruges",
	"house",
	"sanctuary",
	"flight",
	"wilds",
	"hearth",
	"bruges_city",
	"outskirts",
]
const EXPECTED_BOOK2_M2_REGIONS := [
	"brabant_fens",
	"louvain",
]

var main = null
var active: bool = false
var _preset_queue: Array[String] = []
var _current_preset_id: String = ""
var _frames_on_stage: int = 0
var _tested_presets: int = 0
var _visited_regions: Array[String] = []
var _portal_total: int = 0


static func should_run() -> bool:
	var all_args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	return all_args.has("--smoke-regions") or all_args.has("--smoke-all")


func start(main_node) -> void:
	main = main_node
	active = true
	_preset_queue.clear()
	_visited_regions.clear()
	_tested_presets = 0
	_portal_total = 0

	for p in PlaytestPresetsScript.get_all_presets():
		var pid := str(p.get("id", ""))
		if not pid.is_empty():
			_preset_queue.append(pid)

	if _preset_queue.is_empty():
		_fail("PlaytestPresets.get_all_presets() returned no presets.")
		return

	print("SMOKE_START queued_presets=%d" % _preset_queue.size())
	_advance_next_preset()


func step(_delta: float) -> void:
	if not active or main == null:
		return
	_frames_on_stage += 1
	if _frames_on_stage < 3:
		return

	if not _verify_current_stage():
		return
	_advance_next_preset()


func _advance_next_preset() -> void:
	if _preset_queue.is_empty():
		if _verify_book2_systems() and _verify_all_regions_covered():
			print("SMOKE_PASS presets=%d regions=%d portals=%d" % [_tested_presets, _visited_regions.size(), _portal_total])
			active = false
			main.get_tree().quit(0)
		return

	_current_preset_id = str(_preset_queue.pop_front())
	_frames_on_stage = 0
	main.ui.hide_all_overlays()
	main._playtest_jump_to(_current_preset_id)


func _verify_current_stage() -> bool:
	if main.active_region == null or not is_instance_valid(main.active_region):
		_fail("active_region is null/invalid on preset '%s'." % _current_preset_id)
		return false
	if main.player == null or not is_finite(main.player.position.x) or not is_finite(main.player.position.y):
		_fail("player position invalid on preset '%s'." % _current_preset_id)
		return false

	var rid := str(main.current_region_id)
	if not _visited_regions.has(rid):
		_visited_regions.append(rid)

	var portals_prop = main.active_region.get("walk_portals")
	if portals_prop is Array:
		_portal_total += portals_prop.size()

	# Exercise [M] panel location tracking & refresh without crashing
	if main.ui != null and main.ui.map_panel != null:
		main.ui.map_panel.set_player_location(rid, main.player.position)
		main.ui.map_panel.refresh()

	# Dismiss any modal/dialogue spawned by the preset before moving on
	if main.ui != null:
		main.ui.hide_all_overlays()

	_tested_presets += 1
	print("SMOKE_STAGE ok preset=%s region=%s pos=(%.0f,%.0f)" % [
		_current_preset_id, rid, main.player.position.x, main.player.position.y
	])
	return true


func _verify_book2_systems() -> bool:
	GameState.reset_book2_state(true)
	if int(GameState.current_step) != int(GameState.QuestStep.BOOK2_BRABANT_FENS):
		_fail("reset_book2_state(true) did not enter BOOK2_BRABANT_FENS.")
		return false

	# Cycle all 3 [M] views & inspect nodes
	var mp = main.ui.map_panel
	if mp == null:
		_fail("GameUI.map_panel missing.")
		return false
	mp.set_player_location("louvain", Vector2(400, 400))
	for mode_i in range(3):
		mp.set_view_mode(mode_i)
		mp.refresh()
	for node in RealmChartDataScript.REALM_NODES:
		var _nid := str(node.get("id", ""))
		var _disc := RealmChartDataScript.is_node_discovered(node)
	mp.visible = false

	# Verify Mind-Voice telepathy dialogue setup & cleanup
	main.ui.name_panel.visible = false
	main.ui.hide_all_overlays()
	main.ui.show_dialogue([
		{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Smoke check telepathy bond."}
	], Callable())
	main.ui.hide_all_overlays()

	# Verify Book II Journal & Bestiary formatters
	var diary := JournalLoreScript.get_diary_summary()
	var bestiary := JournalLoreScript.get_bestiary_bbcode()
	var controls := JournalLoreScript.get_controls_bbcode()
	if diary.is_empty() or bestiary.is_empty() or controls.is_empty():
		_fail("JournalLoreData returned empty output in Book II mode.")
		return false

	# Verify PlayerCombatHelper 3-hit combo, post-dodge counter, and Knot combat resolution
	var combat := PlayerCombatHelperScript.new()
	var hit0: Dictionary = combat.begin_slash()
	combat.step(0.18, false, false)
	var hit1: Dictionary = combat.begin_slash()
	combat.step(0.18, false, false)
	var hit2: Dictionary = combat.begin_slash()
	if int(hit0.get("combo_step", -1)) != 0 or int(hit1.get("combo_step", -1)) != 1 or int(hit2.get("combo_step", -1)) != 2 or int(hit2.get("damage", 0)) < 2:
		_fail("PlayerCombatHelper 3-hit combo sequence failed.")
		return false
	combat.on_dodge_finished()
	var counter_hit: Dictionary = combat.begin_slash()
	if not bool(counter_hit.get("is_counter", false)):
		_fail("PlayerCombatHelper post-dodge counter thrust failed.")
		return false
	var mock_foes := [
		{"pos": Vector2(100, 100), "has_shield": true, "alive": true},
		{"pos": Vector2(130, 110), "has_shield": false, "alive": true},
	]
	var yank_res: Dictionary = PlayerCombatHelperScript.resolve_knot_targets("bruges_whipping", Vector2(20, 100), Vector2(105, 100), mock_foes)
	if not bool(yank_res.get("hit", false)) or bool(mock_foes[0].get("has_shield", true)):
		_fail("PlayerCombatHelper bruges_whipping shield-yank failed.")
		return false
	var snare_res: Dictionary = PlayerCombatHelperScript.resolve_knot_targets("bowline", Vector2(20, 100), Vector2(115, 105), mock_foes)
	if (snare_res.get("snared", []) as Array).size() < 2:
		_fail("PlayerCombatHelper bowline AoE snare failed.")
		return false
	var zip_res: Dictionary = PlayerCombatHelperScript.resolve_knot_targets("dragon_splice", Vector2(20, 100), Vector2(110, 105), mock_foes)
	if zip_res.get("zipped_target", null) == null:
		_fail("PlayerCombatHelper dragon_splice combat zip failed.")
		return false

	# Verify CityHeatHelper wanted posters, chimes, and smoke pellets
	var heat := CityHeatHelperScript.new()
	heat.reset([{"id": "louvain_1", "pos": Vector2(100, 100)}])
	if not heat.drop_resonance_chime(Vector2(150, 150)):
		_fail("CityHeatHelper failed to drop initial resonance chime.")
		return false
	if heat.get_active_lure_near(Vector2(180, 150)) == Vector2.ZERO:
		_fail("CityHeatHelper did not report active chime lure.")
		return false
	if not heat.trigger_smoke_pellet(Vector2(200, 200)) or not heat.is_point_concealed_by_smoke(Vector2(220, 200)):
		_fail("CityHeatHelper smoke pellet concealment failed.")
		return false
	heat.step(1.0, true)
	if not heat.tear_poster("louvain_1") or GameState.bounty_posters_torn != 1 or heat.get_heat_tier().is_empty():
		_fail("CityHeatHelper poster tear-down or heat tier check failed.")
		return false

	# Verify HatchlingCompanion posture cycling, dragon command, and automatic stuck-time Mind-Voice hint
	if main.companion == null:
		_fail("Main.companion not instantiated.")
		return false
	GameState.active_companion_stage = 2
	GameState.cycle_companion_posture() # assist -> stay
	GameState.cycle_companion_posture() # stay -> sling
	if not main.companion.is_concealed_in_sling():
		_fail("HatchlingCompanion failed to conceal in cloak-sling posture.")
		return false
	main.companion.trigger_command()
	if GameState.companion_posture != "assist":
		_fail("HatchlingCompanion dragon command did not unfold out of sling.")
		return false
	main.companion.set_hint_context("smoke_stuck", ["Those dark scales on the reeds gleam like hammered bronze."], Vector2(300, 300), 8.0)
	for _tick in range(15):
		main.companion.step(1.0)
	if not main.ui.dialogue_active:
		_fail("HatchlingCompanion automatic stuck-time Mind-Voice hint did not fire after stall threshold.")
		return false
	main.companion.clear_hint_context()
	main.ui.hide_all_overlays()

	# Verify CampfirePanel roost opening, rest heal, and closing
	GameState.boy_hp = maxi(1, GameState.boy_max_hp - 2)
	main.ui.open_campfire_roost("brabant_fens", Vector2(240, 240), "Wayside Fen Fire", true)
	if main.ui.campfire_panel == null or not main.ui.campfire_panel.visible:
		_fail("CampfirePanel failed to open.")
		return false
	main.ui.campfire_panel._on_rest_pressed()
	if GameState.boy_hp != GameState.boy_max_hp or GameState.campfire_rests < 1:
		_fail("CampfirePanel rest did not restore health or record rest count.")
		return false
	main.ui.campfire_panel.close_panel()

	# Verify DragonNamePanel naming prompt
	main.ui.open_dragon_name_prompt(Callable())
	if main.ui.dragon_name_panel == null or not main.ui.dragon_name_panel.visible:
		_fail("DragonNamePanel failed to open.")
		return false
	main.ui.dragon_name_panel._name_input.text = "Aurelius"
	main.ui.dragon_name_panel._confirm()
	if GameState.gold_dragon_name != "Aurelius" or main.ui.dragon_name_panel.visible:
		_fail("DragonNamePanel confirmation did not persist gold_dragon_name.")
		return false

	# Verify Milestone 2 Brabant Fens & Louvain Dragon Assist puzzle triggers end-to-end
	main._playtest_jump_to("book2_brabant_hatchling")
	if not main.active_region.on_dragon_command(Vector2(1378, 565), Vector2(1378, 554), Vector2.UP, 1) or not GameState.brabant_vent_unlocked:
		_fail("BrabantFens Hatchling Vent Crawl did not unlock sluice gate.")
		return false
	if not main.active_region.on_dragon_command(Vector2(1078, 840), Vector2(1078, 860), Vector2.DOWN, 1) or not GameState.brabant_briar_burned:
		_fail("BrabantFens Hatchling Ember Puff did not burn fen briars.")
		return false
	main._playtest_jump_to("book2_louvain_abbey")
	if not main.active_region.on_dragon_command(Vector2(2044, 730), Vector2(2044, 714), Vector2.UP, 1) or not GameState.louvain_vent_opened:
		_fail("Louvain Abbey Vent Crawl did not open cloister gate.")
		return false
	if not main.active_region.on_dragon_command(Vector2(1788, 512), Vector2(1788, 496), Vector2.UP, 1) or not GameState.louvain_brazier_lit:
		_fail("Louvain Scriptorium Ember Puff did not light abbey braziers.")
		return false
	main.ui.hide_all_overlays()

	# Verify TitleScreenPanel, PauseMenuPanel, SettingsPanel, AudioServer buses & hints/controls wiring
	if AudioServer.get_bus_index("Ambience") < 0 or AudioServer.get_bus_index("SFX") < 0 or AudioServer.get_bus_index("Voices") < 0:
		_fail("SoundManager did not initialize Ambience/SFX/Voices audio buses.")
		return false
	main.ui.show_title_screen(false)
	if not main.ui.is_title_visible() or main.ui.title_panel.is_name_entry_visible():
		_fail("TitleScreenPanel failed to open in main menu view.")
		return false
	main.ui.title_panel.show_name_entry()
	if not main.ui.title_panel.is_name_entry_visible():
		_fail("TitleScreenPanel failed to switch to Boy name entry view.")
		return false
	main.ui.hide_all_overlays()
	main.ui.toggle_pause_menu("Port of Bruges")
	if main.ui.pause_panel == null or not main.ui.pause_panel.visible:
		_fail("PauseMenuPanel failed to open.")
		return false
	main.ui.open_settings(2)
	if main.ui.settings_panel == null or not main.ui.settings_panel.visible:
		_fail("SettingsPanel failed to open on Controls tab.")
		return false
	var prev_hints := GameState.hints_enabled
	var prev_speed := GameState.dialogue_speed_mode
	GameState.hints_enabled = false
	GameState.dialogue_speed_mode = "fast"
	if GameState.get_dialogue_speed_cps() <= 80.0:
		_fail("Fast dialogue speed multiplier did not update CPS.")
		return false
	main.ui.close_settings()
	main.ui.hide_all_overlays()
	GameState.hints_enabled = prev_hints
	GameState.dialogue_speed_mode = prev_speed
	return true


func _verify_all_regions_covered() -> bool:
	for req_id in EXPECTED_BOOK1_REGIONS + EXPECTED_BOOK2_M2_REGIONS:
		if not _visited_regions.has(req_id):
			_fail("Expected region '%s' was never loaded by PlaytestPresets." % req_id)
			return false
	return true


func _fail(msg: String) -> void:
	push_error("SMOKE_FAIL: " + msg)
	print("SMOKE_FAIL: " + msg)
	active = false
	if main != null and main.get_tree() != null:
		main.get_tree().quit(1)
