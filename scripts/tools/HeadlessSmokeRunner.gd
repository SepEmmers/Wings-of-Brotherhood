class_name HeadlessSmokeRunner
extends RefCounted

## Automated multi-preset & multi-region headless smoke verifier (--smoke-regions).
## Cycles every PlaytestPresets entry, steps live region ticks, checks [M] Realm
## Charter modes, Mind-Voice telepathy, and Journal formatting before quitting.

const PlaytestPresetsScript := preload("res://scripts/data/PlaytestPresets.gd")
const RealmChartDataScript := preload("res://scripts/data/WorldRealmChartData.gd")
const JournalLoreScript := preload("res://scripts/data/JournalLoreData.gd")

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

	for p in PlaytestPresetsScript.PRESETS:
		var pid := str(p.get("id", ""))
		if not pid.is_empty():
			_preset_queue.append(pid)

	if _preset_queue.is_empty():
		_fail("PlaytestPresets.PRESETS returned no presets.")
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
	return true


func _verify_all_regions_covered() -> bool:
	for req_id in EXPECTED_BOOK1_REGIONS:
		if not _visited_regions.has(req_id):
			_fail("Expected Book I region '%s' was never loaded by PlaytestPresets." % req_id)
			return false
	return true


func _fail(msg: String) -> void:
	push_error("SMOKE_FAIL: " + msg)
	print("SMOKE_FAIL: " + msg)
	active = false
	if main != null and main.get_tree() != null:
		main.get_tree().quit(1)
