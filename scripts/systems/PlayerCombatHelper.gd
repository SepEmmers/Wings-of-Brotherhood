class_name PlayerCombatHelper
extends RefCounted

## Modular combat state & tactical knot effect resolver for PlayerBoy (Book II+).
## Handles 3-hit directional knife combo timing, post-dodge counter thrusts,
## and distinct tactical Knot effects (Shield-Yank, Wide Snare, Combat Splice Zip).

const KNOT_DATA_REF := preload("res://scripts/data/KnotCatalog.gd")

var combo_step: int = 0 # 0, 1, 2
var combo_window_timer: float = 0.0
var post_dodge_window: float = 0.0
var last_slash_meta: Dictionary = {
	"combo_step": 0,
	"damage": 1,
	"is_counter": false,
	"reach": 38.0,
	"knockback": 75.0,
}

const COMBO_RESET_WINDOW: float = 0.44
const POST_DODGE_COUNTER_WINDOW: float = 0.30


func step(delta: float, knife_active: bool, dodge_active: bool) -> void:
	if not knife_active:
		combo_window_timer = maxf(0.0, combo_window_timer - delta)
		if combo_window_timer <= 0.0:
			combo_step = 0
	if not dodge_active:
		post_dodge_window = maxf(0.0, post_dodge_window - delta)


func on_dodge_finished() -> void:
	post_dodge_window = POST_DODGE_COUNTER_WINDOW


func begin_slash() -> Dictionary:
	var is_counter := post_dodge_window > 0.0
	post_dodge_window = 0.0

	var step_idx := 0
	var dmg := 1
	var dur := 0.21
	var cd := 0.24
	var reach := 38.0
	var lunge := 70.0
	var knockback := 80.0
	var pitch := 1.0

	if is_counter:
		step_idx = 2
		dmg = 2
		dur = 0.20
		cd = 0.22
		reach = 48.0
		lunge = 170.0
		knockback = 135.0
		pitch = 1.24
		combo_step = 0
		combo_window_timer = 0.0
	else:
		step_idx = combo_step
		match step_idx:
			0:
				dmg = 1; dur = 0.20; cd = 0.16; reach = 38.0; lunge = 72.0; knockback = 75.0; pitch = 1.00
			1:
				dmg = 1; dur = 0.19; cd = 0.15; reach = 41.0; lunge = 92.0; knockback = 85.0; pitch = 1.14
			_:
				dmg = 2; dur = 0.26; cd = 0.32; reach = 47.0; lunge = 140.0; knockback = 150.0; pitch = 0.84
		combo_step = (step_idx + 1) % 3
		combo_window_timer = COMBO_RESET_WINDOW

	last_slash_meta = {
		"combo_step": step_idx,
		"damage": dmg,
		"is_counter": is_counter,
		"duration": dur,
		"cooldown": cd,
		"reach": reach,
		"lunge": lunge,
		"knockback": knockback,
		"pitch": pitch,
	}
	return last_slash_meta


static func resolve_knot_targets(knot_id: String, caster_pos: Vector2, tip_pos: Vector2, enemies: Array) -> Dictionary:
	## Applies Book II tactical Knot interactions against enemy dictionaries ({pos, has_shield, stunned_t, snared_t, hp}).
	## Returns summary dictionary: {"hit": bool, "yanked": Array, "snared": Array, "zipped_target": Variant}.
	var out := {"hit": false, "yanked": [], "snared": [], "zipped_target": null}
	var radius := 46.0
	if knot_id == "bowline":
		radius = 92.0
	elif knot_id == "bruges_whipping":
		radius = 52.0
	elif knot_id == "dragon_splice":
		radius = 60.0

	for en in enemies:
		if not (en is Dictionary) or not bool(en.get("alive", true)):
			continue
		var epos: Vector2 = en.get("pos", Vector2.ZERO)
		var closest_pt := Geometry2D.get_closest_point_to_segment(epos, caster_pos, tip_pos)
		if epos.distance_to(closest_pt) > radius:
			continue
		out["hit"] = true
		match knot_id:
			"clove_hitch":
				en["stunned_t"] = maxf(float(en.get("stunned_t", 0.0)), 0.85)
			"bruges_whipping":
				# Yank shields right out of Catchpole hands & drag toward Boy
				if bool(en.get("has_shield", false)):
					en["has_shield"] = false
					en["shield_yanked"] = true
				var pull_dir := (caster_pos - epos).normalized()
				en["pos"] = epos + pull_dir * minf(42.0, epos.distance_to(caster_pos) * 0.45)
				en["stunned_t"] = maxf(float(en.get("stunned_t", 0.0)), 1.25)
				out["yanked"].append(en)
			"bowline":
				# Wide rescue lasso snares multiple foes in place
				en["snared_t"] = maxf(float(en.get("snared_t", 0.0)), 2.40)
				out["snared"].append(en)
			"dragon_splice":
				# Dash target: zips into stunned/snared targets for heavy impact
				if out["zipped_target"] == null:
					out["zipped_target"] = en
				en["stunned_t"] = maxf(float(en.get("stunned_t", 0.0)), 1.50)
	return out
