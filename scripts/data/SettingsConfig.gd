extends RefCounted

const CFG_PATH: String = "user://settings.cfg"

const DEFAULTS: Dictionary = {
	"master_volume": 0.90,
	"ambience_volume": 0.80,
	"sfx_volume": 0.85,
	"voices_volume": 0.85,
	"audio_muted": false,
	"hints_enabled": true,
	"control_prompts_enabled": true,
	"dialogue_speed_mode": "normal",
	"screen_shake_enabled": true,
	"display_mode": "windowed",
	"show_playtest_hud_btn": false,
	"hd2d_mode_enabled": true,
	"invert_cam_x_arrows": false,
	"invert_cam_y_arrows": false,
}

const DIALOGUE_SPEED_CPS: Dictionary = {
	"slow": 38.0,
	"normal": 62.0,
	"fast": 115.0,
	"instant": 10000.0,
}

const DIALOGUE_SPEED_ORDER: Array[String] = ["slow", "normal", "fast", "instant"]
const DIALOGUE_SPEED_LABELS: Dictionary = {
	"slow": "Slow",
	"normal": "Normal",
	"fast": "Fast",
	"instant": "Instant",
}

const DISPLAY_MODE_ORDER: Array[String] = ["windowed", "maximized", "fullscreen"]
const DISPLAY_MODE_LABELS: Dictionary = {
	"windowed": "Windowed",
	"maximized": "Maximized",
	"fullscreen": "Fullscreen",
}

const DEFAULT_ACTION_KEYS: Dictionary = {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"sprint": [KEY_SHIFT],
	"journal": [KEY_TAB, KEY_J],
	"inventory_screen": [KEY_I],
	"rope_action": [KEY_F],
	"knife_attack": [KEY_V],
	"dodge": [KEY_C],
	"cycle_knot": [KEY_Q],
	"practice_knot": [KEY_K],
	"toggle_map": [KEY_M],
	"playtest_menu": [KEY_F1, KEY_QUOTELEFT],
	"dragon_command": [KEY_R],
	"dragon_posture": [KEY_X],
}

const REBINDABLE_ACTIONS: Array[Dictionary] = [
	{"category": "Movement", "action": "move_up", "label": "Move Up / Climb Pitch", "extra": "Alt: Up Arrow"},
	{"category": "Movement", "action": "move_down", "label": "Move Down / Dive Pitch", "extra": "Alt: Down Arrow"},
	{"category": "Movement", "action": "move_left", "label": "Move Left / Steer Port", "extra": "Alt: Left Arrow"},
	{"category": "Movement", "action": "move_right", "label": "Move Right / Steer Starboard", "extra": "Alt: Right Arrow"},
	{"category": "Movement", "action": "sprint", "label": "Sprint / Wing-Boost", "extra": ""},
	{"category": "Combat & Tools", "action": "interact", "label": "Interact / Advance Dialogue", "extra": "Alt: Space / Enter"},
	{"category": "Combat & Tools", "action": "rope_action", "label": "Cast Knot / Mid-Air Splice", "extra": "Alt: Right-Click"},
	{"category": "Combat & Tools", "action": "knife_attack", "label": "Dock Knife / Crossbow Bolts", "extra": "Alt: Left-Click"},
	{"category": "Combat & Tools", "action": "dodge", "label": "Dodge-Roll / Barrel-Roll", "extra": ""},
	{"category": "Combat & Tools", "action": "cycle_knot", "label": "Switch Equipped Knot", "extra": ""},
	{"category": "Combat & Tools", "action": "practice_knot", "label": "Tie Board Knot Practice", "extra": ""},
	{"category": "Menus & Companion", "action": "inventory_screen", "label": "Character & Satchel Bag", "extra": ""},
	{"category": "Menus & Companion", "action": "journal", "label": "Brotherhood Diary & Lore", "extra": "Alt: J"},
	{"category": "Menus & Companion", "action": "toggle_map", "label": "Parchment World Map", "extra": ""},
	{"category": "Menus & Companion", "action": "dragon_command", "label": "Dragon Companion Assist", "extra": "Book II+"},
	{"category": "Menus & Companion", "action": "dragon_posture", "label": "Companion Posture Cycle", "extra": "Book II+"},
]


static func ensure_default_input_actions() -> void:
	for action_name in DEFAULT_ACTION_KEYS.keys():
		var keys: Array = DEFAULT_ACTION_KEYS[action_name]
		_bind_action_keys(action_name, keys)
	_ensure_rope_rmb()


static func reset_controls_to_defaults() -> void:
	for action_name in DEFAULT_ACTION_KEYS.keys():
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)
		var keys: Array = DEFAULT_ACTION_KEYS[action_name]
		_bind_action_keys(action_name, keys)
	_ensure_rope_rmb()


static func _bind_action_keys(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key_code in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = int(key_code) as Key
		if not InputMap.action_has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)


static func _ensure_rope_rmb() -> void:
	var rmb := InputEventMouseButton.new()
	rmb.button_index = MOUSE_BUTTON_RIGHT
	if not InputMap.action_has_event("rope_action", rmb):
		InputMap.action_add_event("rope_action", rmb)


static func get_action_primary_keycode(action_name: String) -> int:
	if InputMap.has_action(action_name):
		for ev in InputMap.action_get_events(action_name):
			if ev is InputEventKey:
				var kc := int(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode)
				if kc != KEY_NONE:
					return kc
	var fallback: Array = DEFAULT_ACTION_KEYS.get(action_name, [])
	if fallback.size() > 0:
		return int(fallback[0])
	return KEY_NONE


static func get_action_key_label(action_name: String) -> String:
	var kc := get_action_primary_keycode(action_name)
	return format_keycode(kc)


static func format_keycode(key_code: int) -> String:
	if key_code == KEY_NONE:
		return "?"
	var txt := OS.get_keycode_string(key_code as Key)
	match txt:
		"QuoteLeft", "AsciiTilde":
			return "`"
		"Control":
			return "Ctrl"
		"BracketLeft":
			return "["
		"BracketRight":
			return "]"
		"BackSlash":
			return "\\"
		"Semicolon":
			return ";"
		"Apostrophe":
			return "'"
		"Comma":
			return ","
		"Period":
			return "."
		"Slash":
			return "/"
	return txt if txt != "" else "Key %d" % key_code


static func is_key_forbidden(key_code: int) -> bool:
	return key_code in [KEY_NONE, KEY_ESCAPE, KEY_F1, KEY_QUOTELEFT]


static func rebind_action_primary_key(action_name: String, new_key_code: int) -> Dictionary:
	if not DEFAULT_ACTION_KEYS.has(action_name):
		return {"ok": false, "error": "Unknown control action."}
	if is_key_forbidden(new_key_code):
		return {"ok": false, "error": "Esc, F1, and ` are reserved for system menus."}

	var old_primary := get_action_primary_keycode(action_name)
	var swapped_label := ""
	for row in REBINDABLE_ACTIONS:
		var other_action: String = row["action"]
		if other_action == action_name:
			continue
		if get_action_primary_keycode(other_action) == new_key_code and old_primary != KEY_NONE:
			_replace_primary_key_on_action(other_action, old_primary)
			swapped_label = row["label"]
			break

	_replace_primary_key_on_action(action_name, new_key_code)
	return {"ok": true, "swapped_label": swapped_label}


static func _replace_primary_key_on_action(action_name: String, key_code: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var old_events := InputMap.action_get_events(action_name)
	var preserved_tail: Array[InputEvent] = []
	var skipped_first_key := false
	for ev in old_events:
		if ev is InputEventKey:
			var kc := int(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode)
			if not skipped_first_key:
				skipped_first_key = true
				continue
			if kc == key_code:
				continue
		preserved_tail.append(ev)

	InputMap.action_erase_events(action_name)
	var new_ev := InputEventKey.new()
	new_ev.physical_keycode = key_code as Key
	InputMap.action_add_event(action_name, new_ev)
	for ev in preserved_tail:
		InputMap.action_add_event(action_name, ev)


static func apply_display_mode(mode: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	match mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"maximized":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


static func get_dialogue_speed_cps(mode: String) -> float:
	return float(DIALOGUE_SPEED_CPS.get(mode, 62.0))


static func load_into_state(state) -> void:
	ensure_default_input_actions()
	state.master_volume = float(DEFAULTS["master_volume"])
	state.ambience_volume = float(DEFAULTS["ambience_volume"])
	state.sfx_volume = float(DEFAULTS["sfx_volume"])
	state.voices_volume = float(DEFAULTS["voices_volume"])
	state.audio_muted = bool(DEFAULTS["audio_muted"])
	state.hints_enabled = bool(DEFAULTS["hints_enabled"])
	state.control_prompts_enabled = bool(DEFAULTS["control_prompts_enabled"])
	state.dialogue_speed_mode = str(DEFAULTS["dialogue_speed_mode"])
	state.screen_shake_enabled = bool(DEFAULTS["screen_shake_enabled"])
	state.display_mode = str(DEFAULTS["display_mode"])
	state.show_playtest_hud_btn = bool(DEFAULTS["show_playtest_hud_btn"])
	state.hd2d_mode_enabled = bool(DEFAULTS["hd2d_mode_enabled"])
	state.invert_cam_x_arrows = bool(DEFAULTS["invert_cam_x_arrows"])
	state.invert_cam_y_arrows = bool(DEFAULTS["invert_cam_y_arrows"])

	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return

	state.master_volume = clampf(float(cfg.get_value("audio", "master_volume", state.master_volume)), 0.0, 1.0)
	state.ambience_volume = clampf(float(cfg.get_value("audio", "ambience_volume", state.ambience_volume)), 0.0, 1.0)
	state.sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", state.sfx_volume)), 0.0, 1.0)
	state.voices_volume = clampf(float(cfg.get_value("audio", "voices_volume", state.voices_volume)), 0.0, 1.0)
	state.audio_muted = bool(cfg.get_value("audio", "audio_muted", state.audio_muted))

	state.hints_enabled = bool(cfg.get_value("gameplay", "hints_enabled", state.hints_enabled))
	state.control_prompts_enabled = bool(cfg.get_value("gameplay", "control_prompts_enabled", state.control_prompts_enabled))
	var spd := str(cfg.get_value("gameplay", "dialogue_speed_mode", state.dialogue_speed_mode))
	if DIALOGUE_SPEED_CPS.has(spd):
		state.dialogue_speed_mode = spd
	state.screen_shake_enabled = bool(cfg.get_value("gameplay", "screen_shake_enabled", state.screen_shake_enabled))
	state.show_playtest_hud_btn = bool(cfg.get_value("gameplay", "show_playtest_hud_btn", state.show_playtest_hud_btn))
	state.hd2d_mode_enabled = bool(cfg.get_value("gameplay", "hd2d_mode_enabled", state.hd2d_mode_enabled))
	state.invert_cam_x_arrows = bool(cfg.get_value("gameplay", "invert_cam_x_arrows", state.invert_cam_x_arrows))
	state.invert_cam_y_arrows = bool(cfg.get_value("gameplay", "invert_cam_y_arrows", state.invert_cam_y_arrows))

	var disp := str(cfg.get_value("display", "display_mode", state.display_mode))
	if DISPLAY_MODE_LABELS.has(disp):
		state.display_mode = disp

	for row in REBINDABLE_ACTIONS:
		var act: String = row["action"]
		if cfg.has_section_key("controls", act):
			var kc := int(cfg.get_value("controls", act, KEY_NONE))
			if not is_key_forbidden(kc):
				_replace_primary_key_on_action(act, kc)


static func save_from_state(state) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", state.master_volume)
	cfg.set_value("audio", "ambience_volume", state.ambience_volume)
	cfg.set_value("audio", "sfx_volume", state.sfx_volume)
	cfg.set_value("audio", "voices_volume", state.voices_volume)
	cfg.set_value("audio", "audio_muted", state.audio_muted)

	cfg.set_value("gameplay", "hints_enabled", state.hints_enabled)
	cfg.set_value("gameplay", "control_prompts_enabled", state.control_prompts_enabled)
	cfg.set_value("gameplay", "dialogue_speed_mode", state.dialogue_speed_mode)
	cfg.set_value("gameplay", "screen_shake_enabled", state.screen_shake_enabled)
	cfg.set_value("gameplay", "show_playtest_hud_btn", state.show_playtest_hud_btn)
	cfg.set_value("gameplay", "hd2d_mode_enabled", state.hd2d_mode_enabled)
	cfg.set_value("gameplay", "invert_cam_x_arrows", state.invert_cam_x_arrows)
	cfg.set_value("gameplay", "invert_cam_y_arrows", state.invert_cam_y_arrows)

	cfg.set_value("display", "display_mode", state.display_mode)

	for row in REBINDABLE_ACTIONS:
		var act: String = row["action"]
		cfg.set_value("controls", act, get_action_primary_keycode(act))

	cfg.save(CFG_PATH)
