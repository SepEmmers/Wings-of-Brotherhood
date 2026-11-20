class_name DialogueOverrides
extends RefCounted

## Runtime dialogue override loader for edits made in the In-Browser Dialogue Studio.
## Loads data/dialogue_overrides.json (and user://dialogue_overrides.json if present)
## and matches entries by id, "speaker|text" composite key, or exact original text.

static var _loaded: bool = false
static var _overrides: Dictionary = {}
static var _custom_sequences: Dictionary = {}


static func reload_overrides() -> void:
	_loaded = true
	_overrides.clear()
	_custom_sequences.clear()
	for path: String in ["res://data/dialogue_overrides.json", "user://dialogue_overrides.json"]:
		if not FileAccess.file_exists(path):
			continue
		var txt := FileAccess.get_file_as_string(path)
		if txt.is_empty():
			continue
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary:
			var ov = parsed.get("overrides", {})
			if ov is Dictionary:
				for k in ov.keys():
					_overrides[String(k)] = ov[k]
			var seqs = parsed.get("custom_sequences", {})
			if seqs is Dictionary:
				for sk in seqs.keys():
					_custom_sequences[String(sk)] = seqs[sk]


static func _ensure_loaded() -> void:
	if not _loaded:
		reload_overrides()


static func _substitute_tokens(txt: String) -> String:
	var out := txt.replace("%PLAYER%", GameState.player_name)
	return out.replace("%DRAGON%", GameState.gold_dragon_name)


static func apply_line_override(entry: Dictionary) -> Dictionary:
	_ensure_loaded()
	if entry.is_empty():
		return entry
	var res: Dictionary = entry.duplicate(true)
	var eid := String(entry.get("id", ""))
	var spk := String(entry.get("speaker", ""))
	var raw_txt := String(entry.get("text", ""))

	var match_ov: Dictionary = {}
	if not eid.is_empty() and _overrides.has(eid) and _overrides[eid] is Dictionary:
		match_ov = _overrides[eid]
	else:
		var comp := "%s|%s" % [spk, raw_txt]
		if _overrides.has(comp) and _overrides[comp] is Dictionary:
			match_ov = _overrides[comp]
		elif _overrides.has(raw_txt) and _overrides[raw_txt] is Dictionary:
			match_ov = _overrides[raw_txt]

	if not match_ov.is_empty():
		if match_ov.has("speaker") and not String(match_ov["speaker"]).is_empty():
			res["speaker"] = _substitute_tokens(String(match_ov["speaker"]))
		if match_ov.has("portrait") and not String(match_ov["portrait"]).is_empty():
			res["portrait"] = String(match_ov["portrait"])
		if match_ov.has("telepathic"):
			res["telepathic"] = bool(match_ov["telepathic"])
		if match_ov.has("text"):
			res["text"] = _substitute_tokens(String(match_ov["text"]))
	elif "%PLAYER%" in raw_txt or "%DRAGON%" in raw_txt:
		res["text"] = _substitute_tokens(raw_txt)
		res["speaker"] = _substitute_tokens(spk)
	return res


static func get_custom_sequence(seq_id: String) -> Array:
	_ensure_loaded()
	if not _custom_sequences.has(seq_id):
		return []
	var seq = _custom_sequences[seq_id]
	if not (seq is Array):
		return []
	var out: Array = []
	for item in seq:
		if item is Dictionary:
			out.append(apply_line_override(item))
	return out
