extends CharacterBody2D
class_name PlayerBoy

## 2D Top-Down Zelda-like protagonist controller with 4-directional sprites,
## shipboard deck movement support, and 4 unique Knot-driven Rope Throw animations.

signal rope_cast_hit(target_pos: Vector2, knot_id: String)
signal knife_slash(tip_pos: Vector2, dir: Vector2)
signal dodged

const CombatHelperScript := preload("res://scripts/systems/PlayerCombatHelper.gd")

@export var walk_speed: float = 175.0
@export var sprint_speed: float = 245.0

var can_move: bool = false
var allow_tools: bool = true
var facing: Vector2 = Vector2.DOWN
var walk_phase: float = 0.0
var is_moving: bool = false
var on_ship: bool = false
var camera_yaw_rad: float = 0.0

# Multi-phase Rope Throw Animation state
var rope_timer: float = 0.0
var rope_duration: float = 0.56
var rope_dir: Vector2 = Vector2.DOWN
var rope_max_dist: float = 175.0
var rope_hit_sent: bool = false
var active_throw_knot: String = "clove_hitch"
var pulled_crate_active: bool = false
var winch_dash_active: bool = false
var winch_dash_start: Vector2 = Vector2.ZERO
var winch_dash_target: Vector2 = Vector2.ZERO
var winch_dash_post: Vector2 = Vector2.ZERO
var winch_dash_timer: float = 0.0
var winch_dash_duration: float = 0.44

# Dockworker's Knife Slash & Quick Dodge-Roll state
var combat_helper = CombatHelperScript.new()
var knife_timer: float = 0.0
var knife_duration: float = 0.22
var knife_cooldown: float = 0.0
var knife_dir: Vector2 = Vector2.DOWN
var knife_hit_sent: bool = false
var _slash_reach: float = 38.0
var _slash_lunge: float = 70.0
var _slash_step: int = 0

var dodge_timer: float = 0.0
var dodge_duration: float = 0.26
var dodge_cooldown: float = 0.0
var dodge_dir: Vector2 = Vector2.DOWN

var hurt_flash_timer: float = 0.0

var cutscene_pose: String = ""
var cutscene_walking: bool = false
var cutscene_hidden: bool = false
var cutscene_blindfolded: bool = false
var held_item_tex: Texture2D = null
var held_item_timer: float = 0.0
var held_item_dur: float = 1.15

# Modular Carryable Prop Table: any item pairs a single 16px-scale prop texture
# with one reusable empty-hands body posture ("overhead" | "cradle") — no full-body duplicates needed.
const CARRY_PROPS := {
	"crate": {"tex": "prop_crate.png", "posture": "overhead", "scale": 1.65},
	"egg": {"tex": "prop_dragon_egg_held.png", "posture": "cradle", "scale": 1.38},
	"leather": {"tex": "prop_leather_bale.png", "posture": "overhead", "scale": 1.50},
	"water": {"tex": "prop_water_bucket.png", "posture": "cradle", "scale": 1.35},
	"fish": {"tex": "prop_herring_fish.png", "posture": "cradle", "scale": 1.40},
	"mutton": {"tex": "prop_mutton_joint.png", "posture": "cradle", "scale": 1.38},
}

var sprite: Sprite2D
var sling_sprite: Sprite2D
var carry_prop_sprite: Sprite2D
var custom_carry_tex: String = ""
var custom_carry_posture: String = "cradle"
var custom_carry_scale: float = 1.4
var anim_textures: Dictionary = {}


func set_assets(assets_ref) -> void:
	if assets_ref != null:
		anim_textures = assets_ref.tex


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	z_index = 10

	if anim_textures.is_empty():
		_load_fallback_textures()

	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.55, 1.55)
	sprite.position = Vector2(0, -10.0)
	sprite.z_index = 1
	sprite.texture = anim_textures.get("boy_down_0.png")
	add_child(sprite)

	sling_sprite = Sprite2D.new()
	sling_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sling_sprite.visible = false
	sling_sprite.z_index = 2
	add_child(sling_sprite)

	carry_prop_sprite = Sprite2D.new()
	carry_prop_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	carry_prop_sprite.visible = false
	carry_prop_sprite.z_index = 3
	add_child(carry_prop_sprite)


func _load_fallback_textures() -> void:
	var dir_path := "res://assets/sprites"
	for fname in DirAccess.get_files_at(dir_path):
		if fname.ends_with(".png") and (fname.begins_with("boy_") or fname.begins_with("boy14_") or fname.begins_with("boy17_") or fname.begins_with("prop_") or fname.begins_with("icon_")):
			var img := Image.load_from_file(ProjectSettings.globalize_path(dir_path + "/" + fname))
			if img != null:
				anim_textures[fname] = ImageTexture.create_from_image(img)


func _boy_tex(fname: String) -> Texture2D:
	if fname.begins_with("boy_"):
		if GameState.sanctuary_jerkin_earned or GameState.boy_age >= 17:
			var f17 := fname.replace("boy_", "boy17_")
			if anim_textures.has(f17):
				return anim_textures[f17]
		elif GameState.boy_age >= 14 or GameState.sanctuary_phase >= 2:
			var f14 := fname.replace("boy_", "boy14_")
			if anim_textures.has(f14):
				return anim_textures[f14]
	return anim_textures.get(fname)


func _base_sprite_y() -> float:
	if GameState.boy_age >= 17:
		return -11.5
	if GameState.boy_age >= 14:
		return -10.8
	return -10.0

func is_invulnerable() -> bool:
	return dodge_timer > 0.0 or hurt_flash_timer > 0.0

func trigger_hurt_flash() -> void:
	hurt_flash_timer = 0.75

func show_held_item(tex: Texture2D, dur: float = 1.15) -> void:
	held_item_tex = tex
	held_item_dur = maxf(0.1, dur)
	held_item_timer = held_item_dur

func set_cutscene_pose(pose: String = "", walk: bool = false, blindfold: bool = false, hidden: bool = false) -> void:
	cutscene_pose = pose
	cutscene_walking = walk
	cutscene_blindfolded = blindfold
	cutscene_hidden = hidden
	if sprite != null:
		sprite.visible = not hidden
	_update_sprite()
	queue_redraw()

func handle_tool_input(event: InputEvent) -> bool:
	if not can_move or not allow_tools or rope_timer > 0.0:
		return false
	if dodge_timer > 0.0 or winch_dash_active:
		return false
	if event.is_action_pressed("dodge") and dodge_cooldown <= 0.0 and not GameState.carrying_crate and not GameState.carrying_egg:
		_trigger_dodge_roll()
		return true
	var click_knife := (event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed)
	if (event.is_action_pressed("knife_attack") or click_knife) and knife_timer <= 0.0 and knife_cooldown <= 0.0 and GameState.has_dock_knife and not GameState.carrying_crate:
		if click_knife:
			var to_mouse := get_global_mouse_position() - global_position
			if to_mouse.length_squared() > 4.0:
				facing = to_mouse.normalized()
		_trigger_knife_slash()
		return true
	if GameState.rope_unlocked and not GameState.carrying_crate and event.is_action_pressed("rope_action"):
		_trigger_rope_cast()
		return true
	return false

func _trigger_knife_slash() -> void:
	var meta: Dictionary = combat_helper.begin_slash()
	knife_duration = float(meta.get("duration", 0.22))
	knife_timer = knife_duration
	knife_cooldown = float(meta.get("cooldown", 0.24))
	_slash_reach = float(meta.get("reach", 38.0))
	_slash_lunge = float(meta.get("lunge", 70.0))
	_slash_step = int(meta.get("combo_step", 0))
	knife_dir = facing.normalized()
	knife_hit_sent = false
	SoundManager.play_slash(float(meta.get("pitch", 1.0)))


func get_last_slash_meta() -> Dictionary:
	return combat_helper.last_slash_meta

func _trigger_dodge_roll() -> void:
	dodge_timer = dodge_duration
	dodge_cooldown = 0.52
	var iv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dodge_dir = iv.normalized() if iv.length_squared() > 0.01 else facing.normalized()
	facing = dodge_dir
	SoundManager.play_dodge()
	emit_signal("dodged")

func _trigger_rope_cast() -> void:
	rope_timer = rope_duration
	rope_dir = facing.normalized()
	rope_hit_sent = false
	pulled_crate_active = false
	winch_dash_active = false
	active_throw_knot = GameState.equipped_knot
	var kdata: Dictionary = GameState.KNOT_DATA.get(active_throw_knot, {})
	rope_max_dist = float(kdata.get("range", 175.0)) * (1.20 if GameState.clara_gift_received else 1.0)
	SoundManager.play_rope()

func start_winch_dash(target_pos: Vector2, anchor_post: Vector2 = Vector2.ZERO) -> void:
	winch_dash_active = true
	winch_dash_start = global_position
	winch_dash_target = target_pos
	winch_dash_post = anchor_post if anchor_post != Vector2.ZERO else target_pos
	winch_dash_timer = winch_dash_duration
	var delta_v := target_pos - global_position
	if delta_v.length_squared() > 4.0:
		facing = delta_v.normalized()
	rope_timer = 0.0
	rope_hit_sent = true
	collision_mask = 0
	z_index = 20
	SoundManager.play_rope_winch()

func _physics_process(delta: float) -> void:
	knife_cooldown = maxf(0.0, knife_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	hurt_flash_timer = maxf(0.0, hurt_flash_timer - delta)
	combat_helper.step(delta, knife_timer > 0.0, dodge_timer > 0.0)
	if held_item_timer > 0.0:
		held_item_timer = maxf(0.0, held_item_timer - delta)
	if sprite != null:
		sprite.modulate = Color(1.0, 0.55, 0.55, 0.72) if (hurt_flash_timer > 0.0 and int(hurt_flash_timer * 18.0) % 2 == 0) else Color.WHITE

	if cutscene_hidden:
		velocity = Vector2.ZERO
		is_moving = false
		if winch_dash_active:
			winch_dash_active = false
			collision_mask = 1
			z_index = 10
		_update_sprite()
		queue_redraw()
		return

	if winch_dash_active:
		winch_dash_timer = maxf(0.0, winch_dash_timer - delta)
		var dp := 1.0 - (winch_dash_timer / winch_dash_duration)
		var eased := dp * dp * (3.0 - 2.0 * dp)
		global_position = winch_dash_start.lerp(winch_dash_target, eased)
		velocity = Vector2.ZERO
		is_moving = false
		_update_sprite()
		if sprite != null:
			sprite.position.y = _base_sprite_y() - sin(dp * PI) * 26.0
		if winch_dash_timer <= 0.0:
			global_position = winch_dash_target
			winch_dash_active = false
			collision_mask = 1
			z_index = 10
			if sprite != null:
				sprite.position.y = _base_sprite_y()
			SoundManager.play_step(true)
		queue_redraw()
		return

	if dodge_timer > 0.0:
		dodge_timer = maxf(0.0, dodge_timer - delta)
		if dodge_timer <= 0.0:
			combat_helper.on_dodge_finished()
		var rp := 1.0 - (dodge_timer / maxf(0.01, dodge_duration))
		var roll_spd := (335.0 - 85.0 * rp) * GameState.playtest_speed_mult
		velocity = dodge_dir * roll_spd
		is_moving = true
		move_and_slide()
		_update_sprite()
		queue_redraw()
		return

	if knife_timer > 0.0:
		knife_timer = maxf(0.0, knife_timer - delta)
		var kp := 1.0 - (knife_timer / knife_duration)
		if kp >= 0.35 and not knife_hit_sent:
			knife_hit_sent = true
			emit_signal("knife_slash", global_position + knife_dir * _slash_reach, knife_dir)
		velocity = knife_dir * (_slash_lunge * (1.0 - kp))
		move_and_slide()
		is_moving = false
		_update_sprite()
		queue_redraw()
		return

	if rope_timer > 0.0:
		rope_timer = maxf(0.0, rope_timer - delta)
		var p := 1.0 - (rope_timer / rope_duration)
		if p >= 0.45 and not rope_hit_sent:
			rope_hit_sent = true
			emit_signal("rope_cast_hit", global_position + rope_dir * rope_max_dist, active_throw_knot)
		velocity = Vector2.ZERO
		is_moving = false
		_update_sprite()
		queue_redraw()
		return

	if not can_move:
		velocity = Vector2.ZERO
		if cutscene_walking:
			is_moving = true
			walk_phase += delta * 9.0
			SoundManager.play_step(false)
		else:
			is_moving = false
			walk_phase = 0.0
		_update_sprite()
		queue_redraw()
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if absf(camera_yaw_rad) > 0.001 and input_vec.length_squared() > 0.01:
		input_vec = input_vec.rotated(-camera_yaw_rad)
	if input_vec.length_squared() > 0.01:
		facing = input_vec.normalized()
		is_moving = true
		var sprinting := Input.is_action_pressed("sprint") and not GameState.carrying_crate
		var base_speed := sprint_speed if sprinting else walk_speed
		var speed := base_speed * GameState.playtest_speed_mult
		velocity = facing * speed
		walk_phase += delta * (13.0 if sprinting else 9.5)
		SoundManager.play_step(sprinting)
	else:
		velocity = Vector2.ZERO
		is_moving = false
		walk_phase = 0.0

	move_and_slide()
	_update_sprite()
	queue_redraw()

func set_carry_prop(tex_name: String = "", posture: String = "cradle", prop_scale: float = 1.4) -> void:
	custom_carry_tex = tex_name
	custom_carry_posture = posture
	custom_carry_scale = prop_scale
	_update_sprite()


func _resolve_active_carry() -> Dictionary:
	if GameState.carrying_crate:
		return CARRY_PROPS["crate"]
	if GameState.carrying_egg:
		return CARRY_PROPS["egg"]
	if GameState.sanctuary_carrying_item != "" and CARRY_PROPS.has(GameState.sanctuary_carrying_item):
		return CARRY_PROPS[GameState.sanctuary_carrying_item]
	if not custom_carry_tex.is_empty():
		return {"tex": custom_carry_tex, "posture": custom_carry_posture, "scale": custom_carry_scale}
	return {}


func _hide_carry_prop() -> void:
	if carry_prop_sprite != null:
		carry_prop_sprite.visible = false


func _hide_sling_prop() -> void:
	if sling_sprite != null:
		sling_sprite.visible = false


func _sync_sling_overlay(dir_key: String, dir_flip: bool, step_idx: int, base_y: float) -> void:
	if sling_sprite == null:
		return
	var show_sling := GameState.active_companion_stage >= 1 and GameState.active_perspective == "boy" and GameState.companion_posture == "sling"
	if not show_sling:
		sling_sprite.visible = false
		return
	var stex: Texture2D = anim_textures.get("prop_hatchling_sling_%s.png" % dir_key, anim_textures.get("prop_hatchling_sling_down.png"))
	if stex == null:
		sling_sprite.visible = false
		return
	var walk_dy := -1.2 if (is_moving and step_idx > 0) else 0.0
	sling_sprite.texture = stex
	sling_sprite.flip_h = dir_flip
	sling_sprite.scale = sprite.scale
	sling_sprite.position = Vector2(0, base_y + walk_dy)
	sling_sprite.modulate = sprite.modulate
	sling_sprite.visible = true


func _apply_carry_visual(carry: Dictionary, dir_key: String, dir_flip: bool, step_idx: int, base_y: float) -> void:
	var posture := String(carry.get("posture", "cradle"))
	var hands_prefix := "boy_carry_hands" if posture == "overhead" else "boy_cradle_hands"
	var card_dir := "up" if dir_key in ["up", "diag_up"] else ("side" if dir_key == "side" else "down")
	var body_key := "%s_%s_%d.png" % [hands_prefix, dir_key, step_idx]
	if not anim_textures.has(body_key):
		var card_hands := "%s_%s_%d.png" % [hands_prefix, card_dir, step_idx]
		if anim_textures.has(card_hands):
			body_key = card_hands
		else:
			var legacy_pfx := "boy_carry" if posture == "overhead" else "boy_carry_egg"
			var legacy_key := "%s_%s_%d.png" % [legacy_pfx, card_dir, step_idx]
			body_key = legacy_key if anim_textures.has(legacy_key) else ("boy_%s_%d.png" % [dir_key, step_idx])
	sprite.flip_h = dir_flip
	sprite.texture = _boy_tex(body_key)
	sprite.position = Vector2(0, base_y)

	if carry_prop_sprite == null:
		return
	var prop_tex: Texture2D = anim_textures.get(String(carry.get("tex", "")))
	if prop_tex == null:
		carry_prop_sprite.visible = false
		return

	var walk_bob := -1.5 if (is_moving and step_idx > 0) else 0.0
	var age_y := 1.07 if GameState.boy_age >= 17 else (1.03 if GameState.boy_age >= 14 else 1.0)
	var pscale := float(carry.get("scale", 1.4)) * 0.80 * age_y
	carry_prop_sprite.scale = Vector2(pscale, pscale)
	carry_prop_sprite.texture = prop_tex
	carry_prop_sprite.modulate = sprite.modulate

	if posture == "overhead":
		carry_prop_sprite.z_index = 2
		if dir_key == "side":
			carry_prop_sprite.flip_h = dir_flip
			carry_prop_sprite.position = Vector2(-7.0 if dir_flip else 7.0, (-27.0 + walk_bob) * age_y)
		elif dir_key in ["diag_down", "diag_up"]:
			carry_prop_sprite.flip_h = dir_flip
			carry_prop_sprite.position = Vector2(-3.5 if dir_flip else 3.5, (-27.0 + walk_bob) * age_y)
		else:
			carry_prop_sprite.flip_h = false
			carry_prop_sprite.position = Vector2(0.0, (-27.0 + walk_bob) * age_y)
	else:
		if dir_key == "up":
			carry_prop_sprite.z_index = 0
			carry_prop_sprite.flip_h = false
			carry_prop_sprite.position = Vector2(0.0, (-10.0 + walk_bob) * age_y)
		elif dir_key == "diag_up":
			carry_prop_sprite.z_index = 0
			carry_prop_sprite.flip_h = dir_flip
			carry_prop_sprite.position = Vector2(-4.5 if dir_flip else 4.5, (-10.0 + walk_bob) * age_y)
		elif dir_key == "side":
			carry_prop_sprite.z_index = 2
			carry_prop_sprite.flip_h = dir_flip
			carry_prop_sprite.position = Vector2(-6.5 if dir_flip else 6.5, (-9.5 + walk_bob) * age_y)
		elif dir_key == "diag_down":
			carry_prop_sprite.z_index = 2
			carry_prop_sprite.flip_h = dir_flip
			carry_prop_sprite.position = Vector2(-4.2 if dir_flip else 4.2, (-9.0 + walk_bob) * age_y)
		else:
			carry_prop_sprite.z_index = 2
			carry_prop_sprite.flip_h = false
			carry_prop_sprite.position = Vector2(0.0, (-9.0 + walk_bob) * age_y)
	carry_prop_sprite.visible = true


func _update_sprite() -> void:
	if sprite == null:
		return

	if cutscene_hidden:
		sprite.visible = false
		_hide_carry_prop()
		_hide_sling_prop()
		return
	sprite.visible = true

	if GameState.boy_age >= 17:
		sprite.scale = Vector2(1.64, 1.72)
	elif GameState.boy_age >= 14:
		sprite.scale = Vector2(1.60, 1.64)
	else:
		sprite.scale = Vector2(1.55, 1.55)

	var base_y := _base_sprite_y()

	if not cutscene_pose.is_empty() and anim_textures.has(cutscene_pose):
		_hide_carry_prop()
		_hide_sling_prop()
		sprite.flip_h = (cutscene_pose in ["boy_kneel.png", "boy_roll.png", "boy_knife_0.png", "boy_knife_1.png"]) and facing.x < -0.1
		sprite.texture = _boy_tex(cutscene_pose)
		sprite.position = Vector2(0, base_y)
		return

	if cutscene_blindfolded and anim_textures.has("boy_blindfold.png"):
		_hide_carry_prop()
		_hide_sling_prop()
		sprite.flip_h = facing.x < -0.1
		sprite.texture = _boy_tex("boy_blindfold.png")
		sprite.position = Vector2(0, base_y)
		return

	if dodge_timer > 0.0:
		var rp := 1.0 - (dodge_timer / maxf(0.01, dodge_duration))
		var roll_phase := 0 if rp < 0.28 else (1 if rp < 0.74 else 2)
		var rdir := "down"
		var rflip := false
		if absf(dodge_dir.x) > absf(dodge_dir.y) * 1.05:
			rdir = "side"
			rflip = dodge_dir.x < 0.0
		elif dodge_dir.y < 0.0:
			rdir = "up"
		var rkey := "boy_roll_%s_%d.png" % [rdir, roll_phase]
		if anim_textures.has(rkey):
			_hide_carry_prop()
			_hide_sling_prop()
			sprite.flip_h = rflip
			sprite.texture = _boy_tex(rkey)
			sprite.position = Vector2(0, base_y)
			return

	if knife_timer > 0.0 and anim_textures.has("boy_knife_0.png"):
		_hide_carry_prop()
		_hide_sling_prop()
		var kp := 1.0 - (knife_timer / knife_duration)
		sprite.flip_h = knife_dir.x < -0.1
		sprite.texture = _boy_tex("boy_knife_1.png" if kp >= 0.38 else "boy_knife_0.png")
		sprite.position = Vector2(knife_dir.x * 4.0, base_y + knife_dir.y * 2.0)
		return

	if rope_timer > 0.0 and anim_textures.has("boy_throw.png"):
		_hide_carry_prop()
		_hide_sling_prop()
		sprite.flip_h = rope_dir.x < -0.1
		sprite.texture = _boy_tex("boy_throw.png")
		sprite.position = Vector2(0, base_y)
		return

	var dir_key := "down"
	var dir_flip := false
	if absf(facing.x) > 0.30 and absf(facing.y) > 0.30:
		dir_key = "diag_down" if facing.y >= 0.0 else "diag_up"
		dir_flip = facing.x < 0.0
	elif absf(facing.x) > absf(facing.y) * 1.05:
		dir_key = "side"
		dir_flip = facing.x < 0.0
	elif facing.y < 0.0:
		dir_key = "up"

	var step_idx := (1 if int(walk_phase * 1.3) % 2 == 0 else 2) if is_moving else 0
	var carry := _resolve_active_carry()
	if not carry.is_empty():
		_hide_sling_prop()
		_apply_carry_visual(carry, dir_key, dir_flip, step_idx, base_y)
		return
	_hide_carry_prop()
	_sync_sling_overlay(dir_key, dir_flip, step_idx, base_y)

	sprite.flip_h = dir_flip

	var frame_idx := 0
	if is_moving:
		frame_idx = 1 if int(walk_phase * 1.3) % 2 == 0 else 2

	var tex_key := "boy_%s_%d.png" % [dir_key, frame_idx]
	if anim_textures.has(tex_key):
		sprite.texture = _boy_tex(tex_key)
	sprite.position = Vector2(0, base_y)

func _draw() -> void:
	if cutscene_hidden:
		return
	# Grounded sole-contact shadow (boots rest directly inside shadow oval so boy never floats)
	draw_set_transform(Vector2(0, 9.0), 0.0, Vector2(1.05, 0.32))
	draw_circle(Vector2.ZERO, 9.6, Color(0.05, 0.04, 0.07, 0.24))
	draw_set_transform(Vector2(0, 8.6), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 7.2, Color(0.04, 0.03, 0.06, 0.44))
	draw_set_transform(Vector2.ZERO)

	if held_item_timer > 0.0 and held_item_tex != null:
		var prog := 1.0 - (held_item_timer / maxf(0.1, held_item_dur))
		var fade := 1.0 if prog < 0.72 else clampf(1.0 - (prog - 0.72) / 0.28, 0.0, 1.0)
		var lift := -46.0 - sin(minf(1.0, prog * 2.2) * PI * 0.5) * 10.0
		var item_pos := Vector2(0, lift)
		draw_circle(item_pos, 15.0, Color(0.98, 0.80, 0.34, 0.26 * fade))
		draw_circle(item_pos, 9.0, Color(1.0, 0.92, 0.58, 0.34 * fade))
		var sz := held_item_tex.get_size() * 1.4
		draw_texture_rect(held_item_tex, Rect2(item_pos - sz * 0.5, sz), false, Color(1, 1, 1, fade))

	# Subtle animated footstep dust puffs kicking right from heels
	if dodge_timer > 0.0 and not on_ship:
		var rp := 1.0 - (dodge_timer / maxf(0.01, dodge_duration))
		var back := -dodge_dir.normalized()
		for k in range(3):
			var d_pos := back * (6.0 + k * 6.5 + rp * 6.0) + Vector2(0, 7.5 + sin(float(k) * 2.1) * 1.5)
			var sz := Vector2(5.0 - k, 3.5 - k * 0.5)
			draw_rect(Rect2(d_pos - sz * 0.5, sz), Color(0.76, 0.72, 0.62, 0.40 * (1.0 - rp * 0.7)))
	elif is_moving and not on_ship:
		var step_wave := absf(sin(walk_phase))
		if step_wave > 0.72:
			var back := -facing.normalized()
			var puff_pos := Vector2(back.x * 8.0, 8.5 + back.y * 3.5)
			var puff_col := Color(0.72, 0.68, 0.58, 0.30) if SoundManager.current_surface != "grass" else Color(0.54, 0.66, 0.42, 0.28)
			draw_rect(Rect2(puff_pos - Vector2(2, 1.5), Vector2(4, 3)), puff_col)

	# Warm golden aura pulse when cradling the rare black-scaled egg
	if GameState.carrying_egg:
		var warmth_pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
		var aura_pos := Vector2(0, -8)
		draw_circle(aura_pos, 18.0 + warmth_pulse * 4.0, Color(0.95, 0.62, 0.22, 0.14 + 0.08 * warmth_pulse))
		draw_circle(aura_pos, 10.0 + warmth_pulse * 2.0, Color(1.0, 0.80, 0.38, 0.18))

	if knife_timer > 0.0:
		var slash_tex: Texture2D = anim_textures.get("prop_slash_arc.png")
		if slash_tex != null:
			var kp := 1.0 - (knife_timer / knife_duration)
			var ang := knife_dir.angle()
			var s_scale := 1.75 if _slash_step == 2 else 1.40
			var flip_y := -s_scale if _slash_step == 1 else s_scale
			var tint := Color(1.0, 0.90, 0.56, 1.0 - kp * 0.45) if _slash_step == 2 else Color(1.0, 0.96, 0.84, 1.0 - kp * 0.55)
			draw_set_transform(Vector2(0, -10) + knife_dir * (20.0 + float(_slash_step) * 3.0), ang, Vector2(s_scale, flip_y))
			draw_texture(slash_tex, Vector2(-12, -12), tint)
			draw_set_transform(Vector2.ZERO)

	if winch_dash_active:
		var dp := 1.0 - (winch_dash_timer / winch_dash_duration)
		var lift_y := sin(dp * PI) * 26.0
		var hand_loc := Vector2(facing.x * 8.0, -12.0 - lift_y)
		var post_loc := to_local(winch_dash_post + Vector2(0, -18))
		draw_line(hand_loc, post_loc, Color(0.11, 0.09, 0.11), 5.0)
		draw_line(hand_loc, post_loc, Color(0.36, 0.74, 0.54), 3.0)
		draw_circle(post_loc, 5.5, Color(0.98, 0.84, 0.44))
		draw_arc(post_loc, 8.0, 0.0, TAU, 16, Color(0.98, 0.90, 0.56, 0.72), 1.5)
		return

	if rope_timer <= 0.0:
		return

	var p := 1.0 - (rope_timer / rope_duration)
	var hand := Vector2(rope_dir.x * 10.0, -10.0 + rope_dir.y * 4.0)
	var perp := Vector2(-rope_dir.y, rope_dir.x)

	# Phase 1: Wind-up Coil Spin
	if p < 0.18:
		var spin_ang := (p / 0.18) * TAU * 1.5
		var coil_pos := hand + Vector2(cos(spin_ang), sin(spin_ang) * 0.55) * 18.0
		draw_circle(hand + Vector2(0, -6), 11.0, Color(0.76, 0.62, 0.34, 0.65))
		draw_line(hand, coil_pos, Color(0.84, 0.70, 0.42), 3.0)
		draw_circle(coil_pos, 4.0, Color(0.95, 0.82, 0.48))
		return

	# Phase 2 & 3: Whip Flight -> Taut Reel-In
	var flight_p := (p - 0.18) / 0.82
	var reach_frac := sin(minf(1.0, flight_p * 1.35) * PI * 0.5) if flight_p < 0.38 else maxf(0.0, 1.0 - (flight_p - 0.38) / 0.62)
	var cur_len := reach_frac * rope_max_dist
	var tip := hand + rope_dir * cur_len

	# Build 18-segment multi-wave rope geometry
	var segments := 18
	var pts := PackedVector2Array()
	var wave_amp := (1.0 - flight_p) * 16.0 if flight_p < 0.36 else 2.5
	for i in range(segments + 1):
		var s := float(i) / float(segments)
		var base_pt := hand.lerp(tip, s)
		var wave := sin(s * PI * 2.5 - p * 18.0) * wave_amp * sin(s * PI)
		if active_throw_knot == "dragon_splice":
			wave *= 0.6
		pts.append(base_pt + perp * wave)

	# Ink outline + hemp body
	draw_polyline(pts, Color(0.11, 0.09, 0.11), 5.0)
	var main_col := Color(0.32, 0.68, 0.50) if active_throw_knot == "dragon_splice" else Color(0.78, 0.64, 0.34)
	draw_polyline(pts, main_col, 3.0)

	# Unique Tip & Secondary Strands per Unlocked Knot!
	match active_throw_knot:
		"clove_hitch":
			# Figure-Eight Twin-Loop Cast
			draw_arc(tip - rope_dir * 8.0, 9.0, 0.0, TAU, 14, Color(0.88, 0.74, 0.44), 2.5)
			draw_arc(tip + rope_dir * 4.0, 7.0, 0.0, TAU, 14, Color(0.76, 0.62, 0.34), 2.5)
		"bruges_whipping":
			# Spinning 3-Prong Brass Grappling Hook
			var spin := p * 20.0
			for prong in range(3):
				var a := spin + prong * (TAU / 3.0)
				var hook_tip := tip + Vector2(cos(a), sin(a)) * 11.0
				draw_line(tip, hook_tip, Color(0.92, 0.78, 0.42), 2.5)
			draw_circle(tip, 4.0, Color(0.75, 0.78, 0.82))
		"bowline":
			# Wide Sweeping Rescue Lasso Ring
			var lasso_r := 10.0 + sin(minf(1.0, flight_p * 1.5) * PI) * 16.0
			draw_arc(tip, lasso_r, 0.0, TAU, 20, Color(0.11, 0.09, 0.11), 5.0)
			draw_arc(tip, lasso_r, 0.0, TAU, 20, Color(0.88, 0.75, 0.45), 2.5)
		"dragon_splice":
			# Twin-Strand Crisscrossing Brotherhood Rigging + Carabiner Sparks
			var pts2 := PackedVector2Array()
			for i in range(segments + 1):
				var s := float(i) / float(segments)
				var base_pt := hand.lerp(tip, s)
				var wave2 := -sin(s * PI * 3.0 - p * 20.0) * 14.0 * sin(s * PI)
				pts2.append(base_pt + perp * wave2)
			draw_polyline(pts2, Color(0.11, 0.09, 0.11), 4.0)
			draw_polyline(pts2, Color(0.88, 0.72, 0.38), 2.2)
			draw_circle(tip, 6.0, Color(0.98, 0.85, 0.44))
			draw_circle(tip + perp * 7.0, 3.0, Color(0.45, 0.86, 0.66))
			draw_circle(tip - perp * 7.0, 3.0, Color(0.45, 0.86, 0.66))

	# Dragged crate visual when reeling in
	if pulled_crate_active:
		draw_rect(Rect2(tip + Vector2(-12, -12), Vector2(24, 24)), Color(0.58, 0.40, 0.22))
		draw_rect(Rect2(tip + Vector2(-12, -12), Vector2(24, 24)), Color(0.18, 0.12, 0.08), false, 2.0)
