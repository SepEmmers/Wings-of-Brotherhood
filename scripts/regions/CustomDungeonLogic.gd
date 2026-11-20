extends RefCounted

## Wire/logic evaluation, derived node states, live pads/plates and timed sources
## for CustomDungeonRegion (Creator Studio Dungeon Kit).

const CORNER_TYPES: Array[String] = [
	"gate", "locked_door", "secret_wall", "cracked_wall", "drawbridge", "exit_portal", "trigger_zone",
	"color_block", "conveyor", "collapsing_floor", "rune_tile", "pressure_pad", "heat_plate", "teleporter",
]
const DERIVED_TYPES: Array[String] = ["gate", "drawbridge", "relay"]
const HOLD_DEFAULTS: Dictionary = {"lever": 0.0, "timer_switch": 8.0, "resonance_crystal": 6.0}


static func is_corner(t: String) -> bool:
	return CORNER_TYPES.has(t)


static func node_size(n: Dictionary) -> Vector2:
	return Vector2(float(n.get("w", 32)), float(n.get("h", 32)))


static func node_rect(r, n: Dictionary) -> Rect2:
	var p: Vector2 = r.get_node_pos(n)
	var sz: Vector2 = node_size(n)
	if is_corner(String(n.get("type", ""))):
		return Rect2(p, sz)
	return Rect2(p - sz * 0.5, sz)


static func node_center(r, n: Dictionary) -> Vector2:
	var rc: Rect2 = node_rect(r, n)
	return rc.get_center()


static func incoming(r, target_id: String) -> Array:
	var out: Array = []
	for w in r.wires:
		if String(w.get("to", "")) == target_id:
			out.append(w)
	return out


static func is_enabled(r, target_id: String) -> bool:
	var inc: Array = incoming(r, target_id)
	if inc.is_empty():
		return true
	var tgt: Dictionary = r._find_node(target_id)
	var mode: String = String(tgt.get("logicMode", "ALL"))
	var active := 0
	for w in inc:
		if bool(r.node_states.get(String(w.get("from", "")), false)):
			active += 1
	match mode:
		"ANY":
			return active > 0
		"NOT":
			return active == 0
		"SEQUENCE":
			return int(r.wire_sequence_progress.get(target_id, 0)) >= inc.size()
	return active == inc.size()


static func hazard_armed(r, n: Dictionary) -> bool:
	var nid: String = String(n.get("id", ""))
	if incoming(r, nid).is_empty():
		return true
	return not is_enabled(r, nid)


static func color_block_solid(r, n: Dictionary) -> bool:
	return (String(n.get("color", "red")) == "red") == (int(r.crystal_phase) == 0)


static func set_state(r, nid: String, value: bool) -> bool:
	if bool(r.node_states.get(nid, false)) == value:
		return false
	r.node_states[nid] = value
	return true


## Re-derives gates/bridges/relays. Returns true when colliders must be rebuilt.
static func evaluate(r, trigger_id: String = "") -> bool:
	if not trigger_id.is_empty():
		for w in r.wires:
			if String(w.get("from", "")) != trigger_id:
				continue
			var tid: String = String(w.get("to", ""))
			var tgt: Dictionary = r._find_node(tid)
			if String(tgt.get("logicMode", "ALL")) != "SEQUENCE":
				continue
			var ordered: Array = incoming(r, tid)
			ordered.sort_custom(func(a, b): return int(a.get("order", 1)) < int(b.get("order", 1)))
			var step: int = int(r.wire_sequence_progress.get(tid, 0))
			if step < ordered.size() and String(ordered[step].get("from", "")) == trigger_id:
				r.wire_sequence_progress[tid] = step + 1
			else:
				r.wire_sequence_progress[tid] = 0
				for ow in ordered:
					r.node_states[String(ow.get("from", ""))] = false
	var changed := false
	for _pass in range(3):
		var pass_changed := false
		for n in r.nodes:
			var t: String = String(n.get("type", ""))
			if not DERIVED_TYPES.has(t):
				continue
			var nid: String = String(n.get("id", ""))
			var has_inputs: bool = not incoming(r, nid).is_empty()
			var want: bool = has_inputs and is_enabled(r, nid)
			var cur: bool = bool(r.node_states.get(nid, false))
			if t == "relay" and float(n.get("delaySec", 0.0)) > 0.0:
				r.relay_want[nid] = want
				continue
			var latch: bool = bool(n.get("latch", t != "relay"))
			var nxt: bool = (cur or want) if latch else want
			if nxt != cur:
				r.node_states[nid] = nxt
				pass_changed = true
				changed = true
				if t != "relay":
					r.play_gate_fx(n, nxt)
		if not pass_changed:
			break
	return changed


## Activates a timed source (lever hold, timer switch, resonance crystal).
static func activate_timed(r, n: Dictionary) -> void:
	var nid: String = String(n.get("id", ""))
	var t: String = String(n.get("type", ""))
	r.node_states[nid] = true
	var hold: float = float(n.get("holdSec", HOLD_DEFAULTS.get(t, 0.0)))
	if hold > 0.0:
		r.hold_timers[nid] = hold


static func step_sources(r, delta: float) -> bool:
	var rebuild := false
	# Expire timed sources
	for nid in r.hold_timers.keys():
		var left: float = float(r.hold_timers[nid]) - delta
		if left <= 0.0:
			r.hold_timers.erase(nid)
			r.node_states[nid] = false
			if evaluate(r, ""):
				rebuild = true
		else:
			r.hold_timers[nid] = left
	var ppos: Vector2 = r.player.position if r.player != null else Vector2(-9999, -9999)
	for n in r.nodes:
		var t: String = String(n.get("type", ""))
		var nid: String = String(n.get("id", ""))
		if t == "pressure_pad":
			var rect: Rect2 = node_rect(r, n)
			var occ: bool = rect.grow(-3.0).has_point(ppos)
			if not occ:
				for o in r.nodes:
					var ot: String = String(o.get("type", ""))
					if ot == "boulder" or ot == "sarcophagus":
						if rect.has_point(r.get_node_pos(o)):
							occ = true
							break
			if set_state(r, nid, occ):
				r.play_pad_fx(n, occ)
				if evaluate(r, nid if occ else ""):
					rebuild = true
		elif t == "heat_plate":
			var center: Vector2 = node_center(r, n)
			var radius: float = float(n.get("radius", 110.0))
			var hot := false
			for o in r.nodes:
				if String(o.get("type", "")) == "ember_brazier" and bool(r.node_states.get(String(o.get("id", "")), false)):
					if r.get_node_pos(o).distance_to(center) <= radius:
						hot = true
						break
			if set_state(r, nid, hot):
				if evaluate(r, nid if hot else ""):
					rebuild = true
		elif t == "relay" and float(n.get("delaySec", 0.0)) > 0.0:
			var want: bool = bool(r.relay_want.get(nid, false))
			var tm: float = float(r.relay_timers.get(nid, 0.0))
			if want:
				tm += delta
				r.relay_timers[nid] = tm
				if tm >= float(n.get("delaySec", 0.0)) and set_state(r, nid, true):
					if evaluate(r, nid):
						rebuild = true
			else:
				r.relay_timers[nid] = 0.0
				if not bool(n.get("latch", false)) and set_state(r, nid, false):
					if evaluate(r, ""):
						rebuild = true
	return rebuild
