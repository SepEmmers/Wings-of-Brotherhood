class_name BrabantHatchingCutscene
extends CanvasLayer

## Hand-drawn & multi-frame animated dramatic Egg Hatching Cutscene layer
## for Book II Act I — Brabant Reed-Fens Mill Campfire.
## Renders on CanvasLayer 0 (below GameUI layer 1 letterbox bars, skip hint,
## fade curtain, and naming modal) with crisp 4x nearest-neighbor integer scaling.

const CANVAS_W := 320.0
const CANVAS_H := 180.0
const SCALE := 4.0

var region = null
var assets = null
var active: bool = false
var stage: int = 0
var stage_t: float = 0.0
var total_t: float = 0.0

var canvas_node: Node2D
var sparks: Array[Dictionary] = []
var shell_shards: Array[Dictionary] = []
var mist_wisps: Array[Dictionary] = []
var _shake_mag: float = 0.0
var _flash_alpha: float = 0.0
var _bond_pulse: float = 0.0
var _s1_throb_idx: int = 0
var _s2_sub_cracked: bool = false
var _s3_clamber_shown: bool = false
var _s4_sub_stage: int = 0
var _s5_sub_stage: int = 0
var _on_finished: Callable = Callable()


func setup(region_ref, assets_ref) -> void:
	region = region_ref
	assets = assets_ref
	layer = 1
	visible = false
	canvas_node = _HatchDrawer.new()
	canvas_node.owner_cutscene = self
	canvas_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(canvas_node)


func start(on_finished: Callable = Callable()) -> void:
	_on_finished = on_finished
	active = true
	stage = 0
	stage_t = 0.0
	total_t = 0.0
	sparks.clear()
	shell_shards.clear()
	_seed_mist()
	_shake_mag = 0.0
	_flash_alpha = 0.0
	_bond_pulse = 0.0
	_s1_throb_idx = 0
	_s2_sub_cracked = false
	_s3_clamber_shown = false
	_s4_sub_stage = 0
	_s5_sub_stage = 0
	visible = false


func finish_immediate() -> void:
	if not active:
		return
	SoundManager.stop_cutscene_motif(0.35)
	_complete()


func step(delta: float) -> void:
	if not active:
		return
	total_t += delta
	stage_t += delta
	_shake_mag = maxf(0.0, _shake_mag - delta * 6.5)
	_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.2)
	_step_particles(delta)
	_step_mist(delta)

	match stage:
		0:
			# World push-in toward campfire before dissolving into close-up diorama
			var p0 := clampf(stage_t / 1.05, 0.0, 1.0)
			if region != null and region.director != null and region.director.camera != null:
				var cam: Camera2D = region.director.camera
				var ease0 := p0 * p0 * (3.0 - 2.0 * p0)
				cam.zoom = Vector2.ONE * lerpf(1.5, 2.05, ease0)
				cam.position = region.CAMPFIRE_POS + Vector2(18, 4)
			if stage_t >= 0.45 and _s1_throb_idx == 0:
				_s1_throb_idx = 1
				SoundManager.play_egg_crack()
				if region != null:
					region._spawn_fx(region.CAMPFIRE_POS + Vector2(38, 6), Color(1.0, 0.84, 0.34), 12)
					if region.director != null:
						region.director.trigger_camera_shake(2.6, 0.16)
			if stage_t >= 0.72 and _s1_throb_idx == 1:
				_s1_throb_idx = 2
				if region != null and region.ui != null:
					region.ui.set_fade(1.0, false)
			if stage_t >= 1.08:
				_enter_closeup_stage_1()
		1:
			# Close-up stillness: internal shell thumps & gold vein shimmer
			if stage_t >= 0.42 and _s1_throb_idx == 0:
				_s1_throb_idx = 1
				SoundManager.play_hatch_rumble()
				_shake_mag = 1.4
				_spawn_sparks(Vector2(212, 114), 8, Color(0.98, 0.80, 0.32), 18.0, 52.0)
			elif stage_t >= 1.15 and _s1_throb_idx == 1:
				_s1_throb_idx = 2
				SoundManager.play_hatch_rumble()
				_shake_mag = 1.8
				_spawn_sparks(Vector2(212, 110), 10, Color(1.0, 0.86, 0.38), 22.0, 60.0)
			if stage_t >= 1.65:
				stage = 2
				stage_t = 0.0
				_s2_sub_cracked = false
				_shake_mag = 2.6
				_flash_alpha = 0.25
				SoundManager.play_egg_crack()
				_spawn_sparks(Vector2(210, 96), 16, Color(1.0, 0.88, 0.44), 32.0, 96.0)
		2:
			# Jagged initial crack -> furious web-fissure flare & boy recoil
			if stage_t >= 0.72 and not _s2_sub_cracked:
				_s2_sub_cracked = true
				_shake_mag = 3.5
				_flash_alpha = 0.42
				SoundManager.play_egg_crack()
				SoundManager.play_hatch_rumble()
				_spawn_sparks(Vector2(212, 96), 24, Color(1.0, 0.90, 0.48), 40.0, 128.0)
			if int(stage_t * 10.0) > int((stage_t - delta) * 10.0) and _s2_sub_cracked:
				_spawn_sparks(Vector2(212, 92) + Vector2(randf_range(-10, 10), randf_range(-10, 8)), 3, Color(1.0, 0.86, 0.38), 24.0, 74.0)
			if stage_t >= 1.75:
				_enter_stage_3_shatter()
		3:
			# Upper dome shatters -> tiny claws & snout haul over rim
			if stage_t >= 0.46 and not _s3_clamber_shown:
				_s3_clamber_shown = true
				SoundManager.play_hatch_chirp()
				_spawn_sparks(Vector2(212, 96), 14, Color(1.0, 0.86, 0.42), 24.0, 76.0)
			if stage_t >= 1.45:
				stage = 4
				stage_t = 0.0
				_s4_sub_stage = 0
				_spawn_sparks(Vector2(204, 122), 10, Color(0.96, 0.84, 0.46), 18.0, 56.0)
		4:
			# Scramble -> Wet shake -> Hero Wide Wing Unfurl -> First Golden Ember Breath!
			if stage_t >= 0.45 and _s4_sub_stage == 0:
				_s4_sub_stage = 1 # wet shake
				SoundManager.play_wing_beat()
				_spawn_sparks(Vector2(198, 106), 16, Color(0.84, 0.92, 0.98), 38.0, 110.0)
				_spawn_sparks(Vector2(198, 106), 10, Color(1.0, 0.84, 0.38), 34.0, 92.0)
			elif stage_t >= 1.05 and _s4_sub_stage == 1:
				_s4_sub_stage = 2 # WIDE WING UNFURL APEX!
				_shake_mag = 2.8
				_flash_alpha = 0.50
				SoundManager.play_hatch_awakening()
				SoundManager.play_wing_beat()
				_spawn_sparks(Vector2(208, 106), 28, Color(1.0, 0.88, 0.42), 48.0, 145.0)
			elif stage_t >= 1.75 and _s4_sub_stage == 2:
				_s4_sub_stage = 3 # SKYWARD GOLDEN EMBER CRY!
				_shake_mag = 2.2
				SoundManager.play_hatch_chirp()
				SoundManager.play_campfire_warm()
				_spawn_flame_cone(Vector2(174, 84), Vector2(-1.0, -0.78), 26)
			elif _s4_sub_stage == 3 and int(stage_t * 16.0) > int((stage_t - delta) * 16.0):
				_spawn_flame_cone(Vector2(174, 84), Vector2(-1.0, -0.75), 3)
			if stage_t >= 2.80:
				stage = 5
				stage_t = 0.0
				_s5_sub_stage = 0
				SoundManager.play_cutscene_motif("mus_hatch_awakening.wav")
		5:
			# Settle wings -> cautious steps toward Boy's open palm -> Imprint Nuzzle
			if stage_t >= 0.72 and _s5_sub_stage == 0:
				_s5_sub_stage = 1
			elif stage_t >= 1.48 and _s5_sub_stage == 1:
				_s5_sub_stage = 2
				_bond_pulse = 1.0
				SoundManager.play_dragon_purr()
				_spawn_sparks(Vector2(146, 118), 16, Color(1.0, 0.88, 0.44), 16.0, 52.0)
			if _s5_sub_stage >= 2:
				_bond_pulse = 0.65 + 0.35 * sin(total_t * 4.5)
			if stage_t >= 2.20 and _s5_sub_stage < 3:
				_s5_sub_stage = 3
				if region != null and region.ui != null:
					region.ui.set_fade(1.0, false)
			if stage_t >= 2.60:
				_complete()

	if canvas_node != null:
		canvas_node.queue_redraw()


func _enter_closeup_stage_1() -> void:
	stage = 1
	stage_t = 0.0
	_s1_throb_idx = 0
	visible = true
	if region != null and region.director != null and region.director.camera != null:
		region.director.camera.zoom = Vector2(1.5, 1.5)
		region.director.camera.position = region.CAMPFIRE_POS + Vector2(14, 4)
		region.director.camera.reset_smoothing()
	if region != null and region.ui != null:
		region.ui.set_fade(0.0, false)
	SoundManager.play_campfire_warm()


func _enter_stage_3_shatter() -> void:
	stage = 3
	stage_t = 0.0
	_s3_clamber_shown = false
	_shake_mag = 4.2
	_flash_alpha = 0.65
	SoundManager.play_cage_break()
	SoundManager.play_egg_crack()
	_spawn_sparks(Vector2(212, 92), 30, Color(1.0, 0.90, 0.46), 44.0, 150.0)
	for i in range(18):
		var ang := randf_range(-PI * 0.95, -PI * 0.05) + randf_range(-0.18, 0.18)
		var spd := randf_range(58.0, 165.0)
		shell_shards.append({
			"pos": Vector2(212.0 + randf_range(-14.0, 14.0), 94.0 + randf_range(-6.0, 6.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"grav": 210.0,
			"sz": randf_range(2.0, 4.5),
			"gold": (i % 4 == 0),
			"life": randf_range(0.75, 1.35),
			"max_life": 1.35,
		})


func _complete() -> void:
	active = false
	visible = false
	sparks.clear()
	shell_shards.clear()
	if region != null:
		if region.director != null and region.director.camera != null:
			region.director.camera.zoom = Vector2(1.5, 1.5)
			region.director.camera.position = region.CAMPFIRE_POS + Vector2(14, 4)
			region.director.camera.reset_smoothing()
		if region.ui != null:
			region.ui.set_fade(0.0, false)
	var cb := _on_finished
	_on_finished = Callable()
	if cb.is_valid():
		cb.call()


func _spawn_sparks(origin: Vector2, count: int, col: Color, spd_min: float, spd_max: float) -> void:
	for _i in range(count):
		var ang := randf() * TAU
		var spd := randf_range(spd_min, spd_max)
		sparks.append({
			"pos": origin + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)),
			"vel": Vector2(cos(ang), sin(ang) - 0.35) * spd,
			"grav": -12.0,
			"sz": randf_range(1.2, 2.6),
			"col": col,
			"life": randf_range(0.45, 0.95),
			"max_life": 0.95,
		})


func _spawn_flame_cone(origin: Vector2, dir: Vector2, count: int) -> void:
	var base_ang := dir.angle()
	for i in range(count):
		var ang := base_ang + randf_range(-0.34, 0.34)
		var spd := randf_range(68.0, 148.0)
		var col := Color(1.0, 0.94, 0.62) if (i % 3 == 0) else Color(0.98, 0.66, 0.20)
		sparks.append({
			"pos": origin + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"grav": -18.0,
			"sz": randf_range(1.8, 3.2),
			"col": col,
			"life": randf_range(0.35, 0.72),
			"max_life": 0.72,
		})


func _seed_mist() -> void:
	mist_wisps.clear()
	for i in range(5):
		mist_wisps.append({
			"pos": Vector2(randf_range(0.0, CANVAS_W), randf_range(128.0, 152.0)),
			"w": randf_range(30.0, 56.0),
			"spd": randf_range(4.0, 9.0),
			"alpha": randf_range(0.030, 0.055),
		})


func _step_mist(delta: float) -> void:
	for mw: Dictionary in mist_wisps:
		var p: Vector2 = Vector2(mw["pos"])
		p.x += float(mw["spd"]) * delta
		if p.x > CANVAS_W + 40.0:
			p.x = -float(mw["w"])
		mw["pos"] = p


func _step_particles(delta: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var s: Dictionary = sparks[i]
		s["life"] = float(s["life"]) - delta
		var v: Vector2 = Vector2(s["vel"])
		v.y += float(s["grav"]) * delta
		s["vel"] = v
		s["pos"] = Vector2(s["pos"]) + v * delta
		if float(s["life"]) <= 0.0:
			sparks.remove_at(i)
	for j in range(shell_shards.size() - 1, -1, -1):
		var sh: Dictionary = shell_shards[j]
		sh["life"] = float(sh["life"]) - delta
		var sv: Vector2 = Vector2(sh["vel"])
		sv.y += float(sh["grav"]) * delta
		sh["vel"] = sv
		sh["pos"] = Vector2(sh["pos"]) + sv * delta
		if float(sh["life"]) <= 0.0:
			shell_shards.remove_at(j)

	# Ambient rising fire sparks from campfire pit at (38, 126)
	if visible and randf() < delta * 10.0:
		sparks.append({
			"pos": Vector2(38.0 + randf_range(-10.0, 10.0), 126.0),
			"vel": Vector2(randf_range(-6.0, 8.0), randf_range(-26.0, -14.0)),
			"grav": -4.0,
			"sz": 1.5,
			"col": Color(1.0, 0.78, 0.30),
			"life": randf_range(0.6, 1.2),
			"max_life": 1.2,
		})


func _resolve_visual_frames() -> Dictionary:
	var egg_f := 0
	var dragon_f := -1
	var boy_f := 0
	match stage:
		1:
			egg_f = 0
			boy_f = 0
		2:
			egg_f = 2 if _s2_sub_cracked else 1
			boy_f = 1 if _s2_sub_cracked else 0
		3:
			if not _s3_clamber_shown:
				egg_f = 3
				dragon_f = -1
			else:
				egg_f = 4
				dragon_f = 0
			boy_f = 1
		4:
			egg_f = 4
			boy_f = 1
			dragon_f = mini(4, _s4_sub_stage + 1)
		5:
			egg_f = 4
			boy_f = 2
			dragon_f = mini(7, 5 + _s5_sub_stage)
	return {"egg": egg_f, "dragon": dragon_f, "boy": boy_f}


class _HatchDrawer extends Node2D:
	var owner_cutscene = null

	func _draw() -> void:
		if owner_cutscene == null or not owner_cutscene.visible or owner_cutscene.assets == null:
			return
		var cs = owner_cutscene
		var assets = cs.assets
		var t_now: float = cs.total_t
		var frames: Dictionary = cs._resolve_visual_frames()

		var shake := Vector2.ZERO
		if cs._shake_mag > 0.05:
			shake = Vector2(roundf(sin(t_now * 62.0) * cs._shake_mag), roundf(cos(t_now * 48.0) * cs._shake_mag * 0.7)) * SCALE

		# 0. Opaque sky/peat backing so camera shake never reveals framebuffer margin
		draw_rect(Rect2(Vector2(-32.0, -32.0), Vector2(CANVAS_W * SCALE + 64.0, 108.0 * SCALE + 32.0)), Color(0.055, 0.082, 0.137, 1.0))
		draw_rect(Rect2(Vector2(-32.0, 106.0 * SCALE), Vector2(CANVAS_W * SCALE + 64.0, CANVAS_H * SCALE - 104.0 * SCALE + 32.0)), Color(0.075, 0.110, 0.078, 1.0))

		# 1. Backdrop 320x180 scaled crisp 4x -> 1280x720
		var bg_tex: Texture2D = assets.get_tex("cs_hatch_bg.png")
		if bg_tex != null:
			draw_texture_rect(bg_tex, Rect2(shake, Vector2(CANVAS_W * SCALE, CANVAS_H * SCALE)), false)

		# 2. Smooth low-opacity multi-step hearth & hatching glow (no sharp concentric steps)
		var fire_pulse := 0.85 + 0.15 * sin(t_now * 10.5)
		var fire_center := Vector2(38.0, 124.0) * SCALE + shake
		for s_i in range(10):
			var frac := float(10 - s_i) / 10.0
			draw_circle(fire_center, (10.0 + frac * 34.0) * fire_pulse * SCALE, Color(1.0, 0.58, 0.20, 0.016))
		if int(frames["egg"]) >= 2:
			var core_r: float = 34.0 if int(cs.stage) == 2 else (44.0 if int(cs.stage) == 3 else 50.0)
			var core_peak: float = 0.20 if int(cs.stage) < 4 else (0.28 if int(cs._s4_sub_stage) >= 2 else 0.14)
			if int(cs.stage) == 5:
				core_peak = 0.08
			var egg_center := Vector2(212.0, 104.0) * SCALE + shake
			for c_i in range(12):
				var cfrac := float(12 - c_i) / 12.0
				draw_circle(egg_center, (8.0 + cfrac * core_r) * SCALE, Color(1.0, 0.80, 0.34, core_peak * 0.075))

		# 3. Animated 4-frame Campfire Flames (`64x72` at `(6, 74)`)
		var ff := int(t_now * 8.0) % 4
		var fire_tex: Texture2D = assets.get_tex("cs_hatch_fire_%d.png" % ff)
		if fire_tex != null:
			draw_texture_rect(fire_tex, Rect2(Vector2(6.0, 74.0) * SCALE + shake, Vector2(64.0, 72.0) * SCALE), false)

		# 4. Hero Egg (`104x116` at `(160, 42)`)
		var egg_f := int(frames["egg"])
		var egg_jitter := Vector2.ZERO
		if cs.stage == 1 and cs._s1_throb_idx > 0:
			egg_jitter = Vector2(roundf(sin(t_now * 38.0)), 0.0) * SCALE
		var egg_tex: Texture2D = assets.get_tex("cs_hatch_egg_%d.png" % egg_f)
		if egg_tex != null:
			draw_texture_rect(egg_tex, Rect2(Vector2(160.0, 42.0) * SCALE + shake + egg_jitter, Vector2(104.0, 116.0) * SCALE), false)

		# 5. Hero Dragonet Emergence (`128x112` at `(146, 44)`)
		var df := int(frames["dragon"])
		if df >= 0:
			var d_bob := Vector2.ZERO
			if df == 2:
				d_bob = Vector2(roundf(sin(t_now * 44.0) * 2.0), 0.0) * SCALE
			elif df == 7:
				d_bob = Vector2(0.0, roundf(sin(t_now * 3.0) * 1.0)) * SCALE
			var dtex: Texture2D = assets.get_tex("cs_hatch_dragon_%d.png" % df)
			if dtex != null:
				draw_texture_rect(dtex, Rect2(Vector2(146.0, 44.0) * SCALE + shake + d_bob, Vector2(128.0, 112.0) * SCALE), false)

		# 6. Flying Shell Shards & Embers (snapped to 4px integer grid!)
		for sh: Dictionary in cs.shell_shards:
			var a := clampf(float(sh["life"]) / float(sh["max_life"]), 0.0, 1.0)
			var sp: Vector2 = Vector2(sh["pos"]) * SCALE + shake
			var sz := roundf(float(sh["sz"])) * SCALE
			var sc := Color(0.98, 0.80, 0.34, a) if bool(sh["gold"]) else Color(0.14, 0.16, 0.22, a)
			draw_rect(Rect2(sp - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), sc)

		for pt: Dictionary in cs.sparks:
			var a := clampf(float(pt["life"]) / float(pt["max_life"]), 0.0, 1.0)
			var pp: Vector2 = Vector2(pt["pos"]) * SCALE + shake
			var psz := maxf(SCALE, roundf(float(pt["sz"])) * SCALE)
			var col: Color = pt["col"]
			col.a *= a
			draw_rect(Rect2(pp - Vector2(psz * 0.5, psz * 0.5), Vector2(psz, psz)), col)

		# 7. Foreground Kneeling 17yo Boy (`96x104` at `(58, 52)`)
		var bf := int(frames["boy"])
		var btex: Texture2D = assets.get_tex("cs_hatch_boy_watch_%d.png" % bf)
		if btex != null:
			draw_texture_rect(btex, Rect2(Vector2(58.0, 52.0) * SCALE + shake, Vector2(96.0, 104.0) * SCALE), false)

		# 8. Soft Pixel-Art Golden Bond Warmth where Boy's open palm meets Hatchling crest (`(150, 113)`)
		if float(cs._bond_pulse) > 0.05:
			var bond_p: float = float(cs._bond_pulse)
			var bp := Vector2(150.0, 113.0) * SCALE + shake
			for b_i in range(8):
				var bf_r: float = 4.0 + float(8 - b_i) * 2.4 + bond_p * 1.5
				draw_circle(bp, bf_r * SCALE, Color(1.0, 0.86, 0.42, 0.024 * bond_p))
			for sp_i in range(6):
				var ang: float = float(sp_i) * (TAU / 6.0) + t_now * 1.6
				var rad: float = (7.0 + sin(t_now * 3.5 + float(sp_i)) * 3.5) * SCALE
				var px := roundf((bp.x + cos(ang) * rad) / SCALE) * SCALE
				var py := roundf((bp.y + sin(ang) * rad * 0.75) / SCALE) * SCALE
				draw_rect(Rect2(Vector2(px, py), Vector2(SCALE, SCALE)), Color(1.0, 0.94, 0.62, 0.72 * bond_p))

		# 9. Subtle Low Ground-Hugging Brabant Fen Mist Wisps (strictly near ground reeds, feathered)
		for mw: Dictionary in cs.mist_wisps:
			var mp: Vector2 = Vector2(roundf(float(Vector2(mw["pos"]).x)) * SCALE, roundf(float(Vector2(mw["pos"]).y)) * SCALE)
			var w: float = roundf(float(mw["w"])) * SCALE
			var ma: float = float(mw["alpha"])
			draw_rect(Rect2(mp, Vector2(w, SCALE)), Color(0.70, 0.80, 0.88, ma * 0.6))
			draw_rect(Rect2(mp + Vector2(w * 0.15, -SCALE), Vector2(w * 0.70, SCALE)), Color(0.74, 0.84, 0.92, ma))

		# 10. Momentary Blinding Gold/Amber Burst Flash on Shatter & Wing Unfurl
		if cs._flash_alpha > 0.01:
			draw_rect(Rect2(Vector2.ZERO, Vector2(CANVAS_W * SCALE, CANVAS_H * SCALE)), Color(1.0, 0.88, 0.54, cs._flash_alpha * 0.48))
