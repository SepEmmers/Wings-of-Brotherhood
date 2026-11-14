extends RefCounted

# Moving Canal Barges ("Praams") & River-Hopping Mechanic for Bruges City.
# Keeps patrol boats between bridges/watergates, moves the boarded player along
# with the timber deck, and supports parabolic hops onto boats, boat-to-boat, and
# ashore onto opposite stone quays.

const HOP_DURATION := 0.26
const HOP_ARC_HEIGHT := 18.0
const DECK_PAD_X := 11.0
const DECK_PAD_Y := 11.0
const BrugesCityMapDataScript := preload("res://scripts/regions/BrugesCityMapData.gd")


static func init_boats(r) -> void:
	var raw_boats: Array = BrugesCityMapDataScript.get_canal_boats()
	var list: Array[Dictionary] = []
	for i in range(raw_boats.size()):
		var b: Dictionary = raw_boats[i].duplicate(true)
		b["index"] = i
		var rect: Rect2 = b["rect"]
		b["base_rect"] = rect
		b["prev_pos"] = rect.position
		b["vel"] = Vector2.ZERO
		b["dir"] = 1.0 if int(i) % 2 == 0 else -1.0
		b["pause"] = float(i) * 0.25
		b["speed"] = float(b.get("speed", 46.0))
		b["bob_phase"] = float(b.get("phase", float(i) * 1.3))
		list.append(b)
	r.set_meta("canal_boats_dyn", list)
	r.set_meta("boarded_boat_idx", -1)
	r.set_meta("boat_hop_state", {})
	r.set_meta("boat_wakes", [])


static func get_boats(r) -> Array:
	if r.has_meta("canal_boats_dyn"):
		return r.get_meta("canal_boats_dyn")
	return []


static func get_boarded_idx(r) -> int:
	return int(r.get_meta("boarded_boat_idx", -1))


static func is_hopping(r) -> bool:
	var hs: Dictionary = r.get_meta("boat_hop_state", {})
	return bool(hs.get("active", false))


static func is_aboard_or_hopping(r) -> bool:
	return get_boarded_idx(r) >= 0 or is_hopping(r)


static func reset_player_boat_state(r) -> void:
	r.set_meta("boarded_boat_idx", -1)
	r.set_meta("boat_hop_state", {})
	var p = r.player
	if p:
		p.can_move = true
		p.collision_mask = 1
		p.z_index = 10
		if p.has_method("_base_sprite_y") and p.sprite:
			p.sprite.position.y = p._base_sprite_y()


static func step_boats(r, delta: float) -> void:
	var boats: Array = get_boats(r)
	if boats.is_empty():
		return

	var wakes: Array = r.get_meta("boat_wakes", [])
	for i in range(boats.size()):
		var b: Dictionary = boats[i]
		var rect: Rect2 = b["rect"]
		var old_pos: Vector2 = rect.position
		var horiz: bool = bool(b.get("horiz", false))
		var spd: float = float(b.get("speed", 46.0))
		var dir_sign: float = float(b.get("dir", 1.0))
		var min_a: float = float(b.get("axis_min", old_pos.x if horiz else old_pos.y))
		var max_a: float = float(b.get("axis_max", (old_pos.x if horiz else old_pos.y) + 120.0))

		var pause: float = float(b.get("pause", 0.0))
		var step_delta := Vector2.ZERO
		if pause > 0.0:
			pause = maxf(0.0, pause - delta)
			b["pause"] = pause
		elif max_a > min_a + 4.0:
			var cur_a: float = old_pos.x if horiz else old_pos.y
			var next_a: float = cur_a + dir_sign * spd * delta
			if next_a >= max_a:
				next_a = max_a
				b["dir"] = -1.0
				b["pause"] = 0.75
			elif next_a <= min_a:
				next_a = min_a
				b["dir"] = 1.0
				b["pause"] = 0.75
			if horiz:
				step_delta.x = next_a - old_pos.x
				rect.position.x = next_a
			else:
				step_delta.y = next_a - old_pos.y
				rect.position.y = next_a
			# Spawn trailing bow/stern wake ripple periodically
			var wake_acc: float = float(b.get("wake_acc", 0.0)) + delta
			if wake_acc >= 0.34 and step_delta.length_squared() > 0.01:
				wake_acc = 0.0
				var stern := rect.get_center() - Vector2(dir_sign * (rect.size.x * 0.44 if horiz else 0.0), dir_sign * (0.0 if horiz else rect.size.y * 0.44))
				wakes.append({"pos": stern, "age": 0.0, "max_age": 0.9, "horiz": horiz})
			b["wake_acc"] = wake_acc

		b["prev_pos"] = old_pos
		b["rect"] = rect
		b["vel"] = step_delta
		b["bob_phase"] = float(b.get("bob_phase", 0.0)) + delta * 2.4
		boats[i] = b

	# Age and prune wake ripples
	var kept_wakes: Array = []
	for w in wakes:
		w["age"] = float(w.get("age", 0.0)) + delta
		if float(w["age"]) < float(w.get("max_age", 0.9)):
			kept_wakes.append(w)
	r.set_meta("boat_wakes", kept_wakes)

	# Update hop arc or carry boarded player along moving deck
	var p = r.player
	if p == null:
		return

	var hs: Dictionary = r.get_meta("boat_hop_state", {})
	if bool(hs.get("active", false)):
		hs["elapsed"] = float(hs.get("elapsed", 0.0)) + delta
		var dur: float = float(hs.get("duration", HOP_DURATION))
		var t: float = clampf(float(hs["elapsed"]) / maxf(0.05, dur), 0.0, 1.0)
		var target_idx: int = int(hs.get("target_boat", -1))
		var dest_pos: Vector2 = hs.get("end_pos", p.position)
		if target_idx >= 0 and target_idx < boats.size():
			var tb_rect: Rect2 = boats[target_idx]["rect"]
			var local_off: Vector2 = hs.get("target_local", Vector2.ZERO)
			dest_pos = _clamp_to_deck(tb_rect, tb_rect.get_center() + local_off)
		var start_pos: Vector2 = hs.get("start_pos", p.position)
		var ease_t: float = 1.0 - pow(1.0 - t, 2.0)
		p.position = start_pos.lerp(dest_pos, ease_t)
		p.can_move = false
		p.collision_mask = 0
		p.z_index = 14
		if p.sprite and p.has_method("_base_sprite_y"):
			p.sprite.position.y = p._base_sprite_y() - sin(t * PI) * HOP_ARC_HEIGHT
		if t >= 1.0:
			hs["active"] = false
			r.set_meta("boat_hop_state", {})
			p.can_move = true
			if p.sprite and p.has_method("_base_sprite_y"):
				p.sprite.position.y = p._base_sprite_y()
			if target_idx >= 0 and target_idx < boats.size():
				r.set_meta("boarded_boat_idx", target_idx)
				p.collision_mask = 0
				p.z_index = 11
				var sm = r.get_node_or_null("/root/SoundManager")
				if sm != null:
					sm.step_cooldown = 0.0
					sm.play_step(true, "wood")
				if r.has_method("_spawn_sparks"):
					r._spawn_sparks(p.position + Vector2(0, 6), Color(0.82, 0.90, 0.95), 5)
			else:
				r.set_meta("boarded_boat_idx", -1)
				p.collision_mask = 1
				p.z_index = 10
				var sm2 = r.get_node_or_null("/root/SoundManager")
				if sm2 != null:
					sm2.step_cooldown = 0.0
					sm2.play_step(false, "cobble")
				if r.has_method("_spawn_sparks"):
					r._spawn_sparks(p.position + Vector2(0, 6), Color(0.76, 0.72, 0.64), 5)
		else:
			r.set_meta("boat_hop_state", hs)
		return

	var b_idx: int = get_boarded_idx(r)
	if b_idx >= 0 and b_idx < boats.size():
		var boarded: Dictionary = boats[b_idx]
		var step_v: Vector2 = boarded.get("vel", Vector2.ZERO)
		p.position += step_v
		p.position = _clamp_to_deck(boarded["rect"], p.position)
		p.collision_mask = 0
		p.z_index = 11


static func _clamp_to_deck(rect: Rect2, pos: Vector2) -> Vector2:
	var min_x := rect.position.x + DECK_PAD_X
	var max_x := rect.end.x - DECK_PAD_X
	var min_y := rect.position.y + DECK_PAD_Y
	var max_y := rect.end.y - DECK_PAD_Y
	return Vector2(clampf(pos.x, min_x, max_x), clampf(pos.y, min_y, max_y))


static func _closest_point_on_deck(rect: Rect2, pos: Vector2) -> Vector2:
	return _clamp_to_deck(rect, pos)


static func is_safe_land_pos(r, pt: Vector2) -> bool:
	var bounds := Rect2(72.0, 96.0, float(BrugesCityMapDataScript.WORLD_SIZE.x) - 144.0, float(BrugesCityMapDataScript.WORLD_SIZE.y) - 168.0)
	if not bounds.has_point(pt):
		return false
	var pad_pt := Rect2(pt - Vector2(10.0, 10.0), Vector2(20.0, 20.0))
	var cols: Array = r.static_colliders if ("static_colliders" in r and not r.static_colliders.is_empty()) else BrugesCityMapDataScript.get_static_colliders()
	for col: Rect2 in cols:
		if col.intersects(pad_pt):
			return false
	return true


static func find_hop_candidate(r) -> Dictionary:
	## Returns `{valid: bool, action: String, label: String, target_pos: Vector2, target_boat: int, boat_idx: int}`
	if is_hopping(r):
		return {}
	var p = r.player
	if p == null:
		return {}
	var boats: Array = get_boats(r)
	if boats.is_empty():
		return {}

	var boarded_idx: int = get_boarded_idx(r)
	if boarded_idx >= 0 and boarded_idx < boats.size():
		var cur_rect: Rect2 = boats[boarded_idx]["rect"]
		# 1. Check adjacent canal boat hop first if player is facing or near another boat
		var best_adj := -1
		var best_adj_d := 76.0
		for i in range(boats.size()):
			if i == boarded_idx:
				continue
			var other_r: Rect2 = boats[i]["rect"]
			var land_pt: Vector2 = _closest_point_on_deck(other_r, p.position)
			var d: float = p.position.distance_to(land_pt)
			if d <= best_adj_d:
				best_adj_d = d
				best_adj = i
		if best_adj >= 0:
			var tr: Rect2 = boats[best_adj]["rect"]
			var tp: Vector2 = _closest_point_on_deck(tr, p.position)
			return {
				"valid": true,
				"action": "boat_to_boat",
				"label": "[E] Hop Across",
				"target_pos": tp,
				"target_boat": best_adj,
				"boat_idx": best_adj,
			}

		# 2. Check bank / stone bridge landing sites around the boarded barge
		var horiz: bool = bool(boats[boarded_idx].get("horiz", false))
		var dirs: Array[Vector2] = []
		if p.facing.length_squared() > 0.05:
			dirs.append(p.facing.normalized())
		if not horiz:
			# Kraanrei N-S canal: left or right stone quay preferred (toward facing side first)
			if p.facing.x < 0.0:
				dirs.append(Vector2(-1, 0))
				dirs.append(Vector2(1, 0))
			else:
				dirs.append(Vector2(1, 0))
				dirs.append(Vector2(-1, 0))
			dirs.append(Vector2(0, -1))
			dirs.append(Vector2(0, 1))
		else:
			# Spiegelrei E-W canal: north or south stone quay preferred
			if p.facing.y < 0.0:
				dirs.append(Vector2(0, -1))
				dirs.append(Vector2(0, 1))
			else:
				dirs.append(Vector2(0, 1))
				dirs.append(Vector2(0, -1))
			dirs.append(Vector2(-1, 0))
			dirs.append(Vector2(1, 0))

		for d_vec in dirs:
			var perp := Vector2(-d_vec.y, d_vec.x)
			for lat in [0.0, 14.0, -14.0, 26.0, -26.0]:
				for dist in [36.0, 48.0, 62.0, 76.0, 90.0, 104.0]:
					var test_pt: Vector2 = p.position + d_vec * dist + perp * lat
					if cur_rect.has_point(test_pt):
						continue
					if is_safe_land_pos(r, test_pt):
						return {
							"valid": true,
							"action": "ashore",
							"label": "[E] Hop Ashore",
							"target_pos": test_pt,
							"target_boat": -1,
							"boat_idx": boarded_idx,
						}
		return {}

	# On dry land: check closest passing canal barge within reach
	var best_idx := -1
	var best_dist := 64.0
	var best_deck_pt := Vector2.ZERO
	for i in range(boats.size()):
		var b_rect: Rect2 = boats[i]["rect"]
		var deck_pt: Vector2 = _closest_point_on_deck(b_rect, p.position)
		var d: float = p.position.distance_to(deck_pt)
		if d <= best_dist:
			best_dist = d
			best_idx = i
			best_deck_pt = deck_pt
	if best_idx >= 0:
		return {
			"valid": true,
			"action": "board",
			"label": "[E] Hop Aboard",
			"target_pos": best_deck_pt,
			"target_boat": best_idx,
			"boat_idx": best_idx,
		}
	return {}


static func try_hop(r) -> bool:
	var cand: Dictionary = find_hop_candidate(r)
	if not bool(cand.get("valid", false)):
		return false
	var p = r.player
	if p == null:
		return false
	var target_boat: int = int(cand.get("target_boat", -1))
	var dest: Vector2 = cand["target_pos"]
	var target_local := Vector2.ZERO
	if target_boat >= 0:
		var boats: Array = get_boats(r)
		if target_boat < boats.size():
			target_local = dest - boats[target_boat]["rect"].get_center()
	var dir_to: Vector2 = dest - p.position
	if dir_to.length_squared() > 1.0:
		p.facing = dir_to.normalized()
	p.can_move = false
	p.collision_mask = 0
	p.z_index = 14
	r.set_meta("boat_hop_state", {
		"active": true,
		"elapsed": 0.0,
		"duration": HOP_DURATION,
		"start_pos": p.position,
		"end_pos": dest,
		"target_boat": target_boat,
		"target_local": target_local,
	})
	var sm_hop = r.get_node_or_null("/root/SoundManager")
	if sm_hop != null:
		sm_hop.step_cooldown = 0.0
		sm_hop.play_step(true, "wood")
	return true
