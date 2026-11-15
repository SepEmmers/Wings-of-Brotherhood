class_name CityHeatHelper
extends RefCounted

## City Bounty Heat & Concealment Manager (Book II walled towns).
## Coordinates Cloak-Sling dragon exposure penalties, Wanted Poster tear-downs,
## Bronze Resonance Chime lures, and Smoke-Pellet evasion clouds.

var posters: Array[Dictionary] = [] # {"id": String, "pos": Vector2, "torn": bool}
var chimes: Array[Dictionary] = [] # {"pos": Vector2, "t": float}
var smoke_clouds: Array[Dictionary] = [] # {"pos": Vector2, "t": float, "radius": float}
var exposed_grace_t: float = 0.0


func reset(poster_specs: Array = []) -> void:
	posters.clear()
	for sp in poster_specs:
		posters.append({
			"id": str(sp.get("id", "")),
			"pos": sp.get("pos", Vector2.ZERO),
			"torn": false,
		})
	chimes.clear()
	smoke_clouds.clear()
	exposed_grace_t = 0.0


func is_dragon_exposed_in_town() -> bool:
	return GameState.active_companion_stage >= 1 and GameState.companion_posture != "sling"


func is_point_concealed_by_smoke(world_pos: Vector2) -> bool:
	for sc in smoke_clouds:
		if world_pos.distance_to(sc["pos"]) <= float(sc["radius"]):
			return true
	return false


func get_active_lure_near(guard_pos: Vector2, hear_radius: float = 280.0) -> Vector2:
	for ch in chimes:
		if guard_pos.distance_to(ch["pos"]) <= hear_radius:
			return ch["pos"]
	return Vector2.INF


func step(delta: float, guard_spotted_player: bool) -> void:
	for i in range(chimes.size() - 1, -1, -1):
		chimes[i]["t"] = float(chimes[i]["t"]) - delta
		if float(chimes[i]["t"]) <= 0.0:
			chimes.remove_at(i)

	for i in range(smoke_clouds.size() - 1, -1, -1):
		smoke_clouds[i]["t"] = float(smoke_clouds[i]["t"]) - delta
		if float(smoke_clouds[i]["t"]) <= 0.0:
			smoke_clouds.remove_at(i)

	if guard_spotted_player:
		var rate := 22.0 if is_dragon_exposed_in_town() else 12.0
		GameState.add_city_heat(rate * delta)
		exposed_grace_t = 2.4
	else:
		exposed_grace_t = maxf(0.0, exposed_grace_t - delta)
		if exposed_grace_t <= 0.0 and GameState.city_heat > 0.0:
			var cool := 3.0 if not is_dragon_exposed_in_town() else 1.2
			GameState.add_city_heat(-cool * delta)


func tear_poster(poster_id: String) -> bool:
	for p in posters:
		if str(p["id"]) == poster_id and not bool(p["torn"]):
			p["torn"] = true
			GameState.bounty_posters_torn += 1
			GameState.add_city_heat(-18.0)
			SoundManager.play_slash(1.22)
			return true
	return false


func drop_resonance_chime(pos: Vector2) -> bool:
	if GameState.resonance_chimes <= 0:
		return false
	GameState.resonance_chimes -= 1
	chimes.append({"pos": pos, "t": 5.0})
	SoundManager.play_chime()
	GameState.emit_signal("state_updated")
	return true


func trigger_smoke_pellet(pos: Vector2) -> bool:
	if GameState.smoke_pellets <= 0:
		return false
	GameState.smoke_pellets -= 1
	smoke_clouds.append({"pos": pos, "t": 4.2, "radius": 92.0})
	GameState.add_city_heat(-15.0)
	SoundManager.play_dodge()
	GameState.emit_signal("state_updated")
	return true


func get_heat_tier() -> String:
	if GameState.city_heat >= 85.0:
		return "RAID"
	if GameState.city_heat >= 55.0:
		return "ALARM"
	if GameState.city_heat >= 22.0:
		return "WATCHED"
	return "CALM"


func draw_overlays(canvas: CanvasItem, assets) -> void:
	var poster_tex: Texture2D = assets.get_tex("prop_wanted_poster.png") if assets != null else null
	for p in posters:
		if bool(p["torn"]):
			continue
		var pos: Vector2 = p["pos"]
		if poster_tex != null:
			canvas.draw_texture_rect(poster_tex, Rect2(pos - Vector2(9, 12), Vector2(18, 24)), false)
		else:
			canvas.draw_rect(Rect2(pos - Vector2(7, 10), Vector2(14, 20)), Color(0.88, 0.80, 0.62))
			canvas.draw_rect(Rect2(pos - Vector2(7, 10), Vector2(14, 20)), Color(0.28, 0.16, 0.10), false, 1.4)

	for ch in chimes:
		var pulse := 0.5 + 0.5 * sin(float(ch["t"]) * 12.0)
		canvas.draw_arc(ch["pos"], 14.0 + pulse * 18.0, 0.0, TAU, 20, Color(0.96, 0.78, 0.30, 0.55), 1.8)
		canvas.draw_circle(ch["pos"], 5.0, Color(0.86, 0.68, 0.24))

	for sc in smoke_clouds:
		var a := clampf(float(sc["t"]) / 1.5, 0.0, 0.62)
		var r := float(sc["radius"])
		canvas.draw_circle(sc["pos"], r, Color(0.24, 0.25, 0.30, a))
		canvas.draw_arc(sc["pos"], r, 0.0, TAU, 24, Color(0.55, 0.56, 0.62, a * 0.8), 2.0)
