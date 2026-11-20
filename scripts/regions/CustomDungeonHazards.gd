extends RefCounted

## Per-frame hazards, floor mechanics, pickups and interactions for CustomDungeonRegion:
## spikes, dart turrets, flame jets, patrol blades, collapsing floors, conveyors, teleporters,
## trigger zones, checkpoints, pickups, slash-breakables, chime bells, springs and NPCs.

const LogicScript := preload("res://scripts/regions/CustomDungeonLogic.gd")

const DIRS: Dictionary = {"right": Vector2.RIGHT, "left": Vector2.LEFT, "up": Vector2.UP, "down": Vector2.DOWN}


static func step(r, delta: float) -> void:
	if r.player == null or not r.player.visible:
		return
	var ppos: Vector2 = r.player.position
	r.tp_cd = maxf(0.0, r.tp_cd - delta)
	r.crystal_cd = maxf(0.0, r.crystal_cd - delta)
	var on_unsafe := false
	for n in r.nodes:
		var nid: String = String(n.get("id", ""))
		var t: String = String(n.get("type", ""))
		var done: bool = bool(r.node_states.get(nid, false))
		var rect: Rect2 = LogicScript.node_rect(r, n)
		var ctr: Vector2 = rect.get_center()
		match t:
			"spike_trap":
				if r.trap_cooldown <= 0.0 and r.is_spike_up(n) and LogicScript.hazard_armed(r, n) and ppos.distance_to(ctr) <= 20.0:
					r.trap_cooldown = 1.4
					r._damage_player(1)
			"dart_turret":
				var tt: float = float(r.turret_t.get(nid, float(n.get("offsetSec", 0.0)))) + delta
				if tt >= float(n.get("periodSec", 2.4)):
					tt = 0.0
					if LogicScript.hazard_armed(r, n):
						var dv: Vector2 = DIRS.get(String(n.get("dir", "right")), Vector2.RIGHT)
						r.dart_bolts.append({"pos": ctr + dv * 16.0, "dir": dv, "life": 1.8})
						r.play_turret_fx(ctr)
				r.turret_t[nid] = tt
			"flame_jet":
				var cyc: float = maxf(1.0, float(n.get("periodSec", 3.0)))
				var on: bool = fmod(r.trap_timer + float(n.get("offsetSec", 0.0)), cyc) > cyc * 0.55 and LogicScript.hazard_armed(r, n)
				r.flame_on[nid] = on
				if on and r.trap_cooldown <= 0.0 and ppos.distance_to(ctr + Vector2(0, -14)) <= 26.0:
					r.trap_cooldown = 1.2
					r._damage_player(1)
			"patrol_blade":
				if LogicScript.hazard_armed(r, n):
					var axis: Vector2 = Vector2.RIGHT if String(n.get("axis", "h")) == "h" else Vector2.DOWN
					var rng: float = maxf(16.0, float(n.get("rangePx", 160.0)))
					var ph: float = fmod(r.trap_timer * float(n.get("speed", 90.0)) / rng + float(n.get("offsetSec", 0.0)), 2.0)
					var tri: float = ph if ph <= 1.0 else 2.0 - ph
					r.node_positions[nid] = Vector2(float(n.get("x", 0)), float(n.get("y", 0))) + axis * rng * tri
				var bp: Vector2 = r.get_node_pos(n)
				if r.trap_cooldown <= 0.0 and LogicScript.hazard_armed(r, n) and ppos.distance_to(bp) <= 19.0:
					r.trap_cooldown = 1.0
					r._damage_player(1)
			"collapsing_floor":
				if done:
					continue
				if rect.grow(-4.0).has_point(ppos):
					on_unsafe = true
					var ct: float = float(r.collapse_t.get(nid, 0.0)) + delta
					r.collapse_t[nid] = ct
					if ct >= float(n.get("delaySec", 0.7)):
						r.node_states[nid] = true
						SoundManager.play_cage_break()
						r.spawn_sparks(ctr, Color(0.6, 0.55, 0.5), 14)
						r._rebuild_colliders()
						r.player.position = r.last_safe_pos
						r._damage_player(1)
				else:
					r.collapse_t[nid] = maxf(0.0, float(r.collapse_t.get(nid, 0.0)) - delta)
			"conveyor":
				if r.player.can_move and rect.has_point(ppos):
					var push: Vector2 = DIRS.get(String(n.get("dir", "right")), Vector2.RIGHT) * float(n.get("speed", 85.0)) * delta
					if not r.point_hits_colliders(ppos + push, r.static_colliders, 10.0):
						r.player.position = ppos + push
			"teleporter":
				if r.tp_cd <= 0.0 and rect.grow(-6.0).has_point(ppos):
					var dest: Dictionary = _find_pair(r, n)
					if not dest.is_empty():
						r.tp_cd = 1.2
						r.player.position = LogicScript.node_center(r, dest) + Vector2(0, 26)
						r.last_safe_pos = r.player.position
						SoundManager.play_chime()
						r.spawn_sparks(ctr, Color(0.55, 0.62, 1.0), 14)
						r.spawn_sparks(r.player.position, Color(0.55, 0.62, 1.0), 14)
			"trigger_zone":
				if not done and rect.has_point(ppos):
					r.node_states[nid] = true
					if bool(n.get("shake", false)) and r.director != null:
						r.director.trigger_camera_shake(5.0, 0.4)
					var zt: String = String(n.get("text", "")).strip_edges()
					if not zt.is_empty():
						r.ui.show_dialogue([{"speaker": String(n.get("speaker", GameState.gold_dragon_name)), "portrait": String(n.get("portrait", "portrait_hatchling_stage1.png")), "telepathic": bool(n.get("telepathic", true)), "text": zt}])
					if LogicScript.evaluate(r, nid):
						r._rebuild_colliders()
				elif done and bool(n.get("repeat", false)) and not rect.has_point(ppos):
					r.node_states[nid] = false
			"checkpoint":
				if not done and ppos.distance_to(ctr) <= 36.0:
					r.node_states[nid] = true
					r.checkpoint_pos = ctr + Vector2(0, 26)
					SoundManager.play_chime()
					r.spawn_sparks(ctr, Color(0.5, 0.95, 0.6), 14)
			"key_small", "key_boss", "heart_pickup", "heart_container", "coin":
				if not done and ppos.distance_to(ctr) <= 22.0:
					_collect(r, n, t, nid, ctr)
	if not on_unsafe and r.player.can_move:
		r.safe_t -= delta
		if r.safe_t <= 0.0:
			r.safe_t = 0.25
			if not r.point_hits_colliders(ppos, r.static_colliders, 8.0):
				r.last_safe_pos = ppos
	_step_bolts(r, delta)


static func _find_pair(r, n: Dictionary) -> Dictionary:
	var pid: String = String(n.get("pairId", ""))
	for o in r.nodes:
		if String(o.get("type", "")) == "teleporter" and String(o.get("id", "")) != String(n.get("id", "")) and String(o.get("pairId", "")) == pid:
			return o
	return {}


static func _collect(r, n: Dictionary, t: String, nid: String, ctr: Vector2) -> void:
	match t:
		"key_small":
			r.keys_small += 1
		"key_boss":
			r.keys_boss += 1
		"coin":
			r.florins += int(n.get("value", 1))
		"heart_pickup":
			if GameState.boy_hp >= GameState.boy_max_hp:
				return
			GameState.boy_hp = mini(GameState.boy_max_hp, GameState.boy_hp + 1)
			r.ui.refresh_hud()
		"heart_container":
			GameState.boy_max_hp += 1
			GameState.boy_hp = GameState.boy_max_hp
			r.ui.refresh_hud()
	r.node_states[nid] = true
	SoundManager.play_chime()
	r.spawn_sparks(ctr, Color(1.0, 0.88, 0.36), 12)


static func _step_bolts(r, delta: float) -> void:
	for i in range(r.dart_bolts.size() - 1, -1, -1):
		var b: Dictionary = r.dart_bolts[i]
		b["pos"] = Vector2(b["pos"]) + Vector2(b["dir"]) * 240.0 * delta
		b["life"] = float(b["life"]) - delta
		var bpos: Vector2 = b["pos"]
		var hit := float(b["life"]) <= 0.0
		if not hit:
			for c: Rect2 in r.static_colliders:
				if c.has_point(bpos):
					hit = true
					break
		if hit:
			r.dart_bolts.remove_at(i)
		elif r.player != null and r.player.visible and bpos.distance_to(r.player.position) <= 16.0:
			r.dart_bolts.remove_at(i)
			r._damage_player(1)


static func on_slash(r, tip: Vector2) -> void:
	for n in r.nodes.duplicate():
		var nid: String = String(n.get("id", ""))
		var t: String = String(n.get("type", ""))
		if bool(r.node_states.get(nid, false)) and t != "crystal_switch":
			continue
		var rect: Rect2 = LogicScript.node_rect(r, n)
		var ctr: Vector2 = rect.get_center()
		match t:
			"breakable_pot":
				if tip.distance_to(ctr) <= 34.0:
					r.node_states[nid] = true
					SoundManager.play_cage_break()
					r.spawn_sparks(ctr, Color(0.7, 0.4, 0.3), 10)
					_drop_loot(r, nid, ctr)
					r._rebuild_colliders()
			"cracked_wall":
				if rect.grow(30.0).has_point(tip):
					var hits: int = int(r.node_hits.get(nid, 0)) + 1
					r.node_hits[nid] = hits
					SoundManager.play_hit()
					r.spawn_sparks(tip, Color(0.7, 0.68, 0.64), 8)
					if hits >= int(n.get("hitsNeeded", 3)):
						r.node_states[nid] = true
						SoundManager.play_cage_break()
						r.spawn_sparks(ctr, Color(0.8, 0.78, 0.72), 22)
						LogicScript.evaluate(r, nid)
						r._rebuild_colliders()
			"crystal_switch":
				if r.crystal_cd <= 0.0 and tip.distance_to(ctr) <= 38.0:
					r.crystal_cd = 0.45
					r.crystal_phase = 1 - int(r.crystal_phase)
					r.node_states[nid] = int(r.crystal_phase) == 1
					SoundManager.play_chime()
					r.spawn_sparks(ctr, Color(0.7, 0.8, 1.0), 12)
					LogicScript.evaluate(r, nid)
					r._rebuild_colliders()
			"timer_switch":
				if tip.distance_to(ctr) <= 36.0:
					ring_timer(r, n)


static func _drop_loot(r, pot_id: String, ctr: Vector2) -> void:
	var roll: int = absi(pot_id.hash()) % 4
	if roll == 3:
		return
	var loot_type: String = "heart_pickup" if roll < 2 else "coin"
	var lid: String = pot_id + "_loot"
	var tex: String = "icon_heart_full.png" if roll < 2 else "dk_florin.png"
	r.nodes.append({"id": lid, "type": loot_type, "x": ctr.x, "y": ctr.y, "w": 16, "h": 16, "tex": tex, "label": "Loot"})
	r.node_positions[lid] = ctr
	r.node_states[lid] = false


static func ring_timer(r, n: Dictionary) -> void:
	var nid: String = String(n.get("id", ""))
	LogicScript.activate_timed(r, n)
	SoundManager.play_chime()
	r.spawn_sparks(LogicScript.node_center(r, n), Color(1.0, 0.84, 0.4), 12)
	if LogicScript.evaluate(r, nid):
		r._rebuild_colliders()


static func ring_bell(r, n: Dictionary) -> void:
	var ctr: Vector2 = LogicScript.node_center(r, n)
	var radius: float = float(n.get("radius", 260.0))
	SoundManager.play_chime()
	r.spawn_sparks(ctr, Color(1.0, 0.9, 0.5), 20)
	var rebuild := false
	for o in r.nodes:
		if String(o.get("type", "")) == "resonance_crystal" and r.get_node_pos(o).distance_to(ctr) <= radius:
			LogicScript.activate_timed(r, o)
			r.spawn_sparks(r.get_node_pos(o), Color(0.5, 1.0, 0.8), 14)
			if LogicScript.evaluate(r, String(o.get("id", ""))):
				rebuild = true
	if rebuild:
		r._rebuild_colliders()


static func use_spring(r, n: Dictionary) -> void:
	var nid: String = String(n.get("id", ""))
	var used: int = int(r.node_hits.get(nid, 0))
	if used >= int(n.get("uses", 3)) or GameState.boy_hp >= GameState.boy_max_hp:
		r.ui.show_dialogue([{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "The water is still and cold. Nothing more to mend."}])
		return
	r.node_hits[nid] = used + 1
	GameState.boy_hp = GameState.boy_max_hp
	SoundManager.play_chime()
	r.spawn_sparks(LogicScript.node_center(r, n), Color(0.5, 0.85, 1.0), 18)
	r.ui.refresh_hud()


static func talk_npc(r, n: Dictionary) -> void:
	var lines: Array = []
	for ln in String(n.get("text", "...")).split("\n", false):
		lines.append({"speaker": String(n.get("speaker", n.get("label", "Stranger"))), "portrait": String(n.get("portrait", "portrait_watchman.png")), "telepathic": bool(n.get("telepathic", false)), "text": ln})
	r.ui.show_dialogue(lines)


static func try_open_door(r, n: Dictionary) -> void:
	var nid: String = String(n.get("id", ""))
	var boss: bool = String(n.get("keyType", "small")) == "boss"
	var have: int = int(r.keys_boss) if boss else int(r.keys_small)
	if have <= 0:
		SoundManager.play_hit()
		r.ui.show_dialogue([{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "A heavy lock. Somewhere in these halls there is a %s that fits it." % ("crimson-sealed key" if boss else "small brass key")}])
		return
	if boss:
		r.keys_boss -= 1
	else:
		r.keys_small -= 1
	r.node_states[nid] = true
	SoundManager.play_cage_break()
	SoundManager.play_chime()
	r.spawn_sparks(LogicScript.node_center(r, n), Color(1.0, 0.86, 0.4), 20)
	LogicScript.evaluate(r, nid)
	r._rebuild_colliders()
