class_name SanctuaryHeistCutscene
extends CanvasLayer

## Hand-Drawn 320x180 (4x = 1280x720) Dialogue-Free Sanctuary Midnight Heist & Kestrel Escape Diorama.
## Supports two seamless visual sequences:
##   1. mode = "pedestal": Vault brazier egg-lift & cloak bundle tuck under sweeping corridor shadows (~2.35s)
##   2. mode = "escape": Overworld saddle mount -> Guard discovery -> Cliff leap -> Moonlit sky flight to Brabant (~5.70s)

const SCALE := 4.0
const CANVAS_W := 320.0
const CANVAS_H := 180.0

var region = null
var assets = null
var canvas_node: Node2D = null

var active: bool = false
var mode: String = "escape"
var stage: int = 0
var stage_t: float = 0.0
var total_t: float = 0.0
var _on_finished: Callable = Callable()

var _shake_mag: float = 0.0
var _flash_alpha: float = 0.0
var _pedestal_lifted: bool = false
var _sentry_entered: bool = false
var _boy_mounted: bool = false
var _wing_sfx_t: float = 0.0

var particles: Array[Dictionary] = []
var wind_lines: Array[Dictionary] = []


func _ready() -> void:
	layer = 1
	visible = false
	canvas_node = _HeistDrawer.new()
	canvas_node.owner_cutscene = self
	canvas_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(canvas_node)


func _start_common(parent_region, seq_mode: String, on_done: Callable) -> void:
	region = parent_region
	assets = parent_region.assets
	mode = seq_mode
	_on_finished = on_done
	active = true
	stage = 0
	stage_t = 0.0
	total_t = 0.0
	_shake_mag = 0.0
	_flash_alpha = 0.0
	_pedestal_lifted = false
	_sentry_entered = false
	_boy_mounted = false
	_wing_sfx_t = 0.0
	particles.clear()
	_seed_wind()


func start_pedestal_theft(parent_region, on_done: Callable) -> void:
	_start_common(parent_region, "pedestal", on_done)
	visible = true
	stage = 0
	if region != null and region.ui != null:
		region.ui.set_hud_visible(false)
		region.ui.set_fade(0.0, false)
		region.ui.set_cinematic_mode(true, Callable(self, "finish_immediate"))
	SoundManager.play_campfire_warm()
	if canvas_node != null:
		canvas_node.queue_redraw()


func start_kestrel_escape(parent_region, on_done: Callable) -> void:
	_start_common(parent_region, "escape", on_done)
	visible = false
	if region != null:
		if region.ui != null:
			region.ui.set_hud_visible(false)
			region.ui.set_cinematic_mode(true, Callable(self, "finish_immediate"))
	if canvas_node != null:
		canvas_node.queue_redraw()


func finish_immediate() -> void:
	if not active:
		return
	_complete()


func step(delta: float) -> void:
	if not active:
		return
	total_t += delta
	stage_t += delta
	_shake_mag = maxf(0.0, _shake_mag - delta * 6.0)
	_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.4)
	_step_particles(delta)
	_step_wind(delta)

	if mode == "pedestal":
		_step_pedestal(delta)
	else:
		_step_escape(delta)

	if canvas_node != null:
		canvas_node.queue_redraw()


func _step_pedestal(_delta: float) -> void:
	match stage:
		0:
			# Reach into glowing coals -> lift Black-and-Gold Egg clear (`t = 0.28s`)
			if stage_t >= 0.28 and not _pedestal_lifted:
				_pedestal_lifted = true
				SoundManager.play_dragon_purr()
				SoundManager.play_chime()
				_spawn_sparks(Vector2(122, 114), 16, Color(1.0, 0.84, 0.36), 24.0, 74.0)
			if stage_t >= 1.10:
				stage = 1
				stage_t = 0.0
				_sentry_entered = true
				SoundManager.play_hatch_chirp()
				_spawn_sparks(Vector2(42, 98), 8, Color(1.0, 0.88, 0.50), 12.0, 36.0)
		1:
			# Wrap bundle -> Night-Watch lantern shadow glances arch -> fade back to Phase 5 courtyard
			if stage_t >= 0.85 and _flash_alpha <= 0.01:
				if region != null and region.ui != null:
					region.ui.set_fade(1.0, false)
			if stage_t >= 1.25:
				_complete()


func _step_escape(delta: float) -> void:
	match stage:
		0:
			# Stage 0 (0.0..0.80s): Brief overworld cliff push-in toward Kestrel's lowered wing-ramp
			var p0 := clampf(stage_t / 0.78, 0.0, 1.0)
			if region != null and region.director != null and region.director.camera != null:
				var cam: Camera2D = region.director.camera
				cam.zoom = Vector2.ONE * lerpf(1.5, 1.85, p0 * p0 * (3.0 - 2.0 * p0))
				cam.position = region.ACT2_CAGE_POS + region.greyling_offset + Vector2(-10, -4)
			if stage_t >= 0.45 and region != null and region.ui != null:
				region.ui.set_fade(1.0, false)
			if stage_t >= 0.80:
				_enter_escape_balcony()
		1:
			# Stage 1 (0.80..2.15s): Leaping aboard Kestrel as Night-Watchmen burst through arch!
			if stage_t >= 0.40 and not _boy_mounted:
				_boy_mounted = true
				_shake_mag = 2.0
				SoundManager.play_alert_horn()
				_spawn_sparks(Vector2(246, 86), 14, Color(0.84, 0.90, 0.96), 28.0, 82.0)
			if stage_t >= 1.35:
				_enter_escape_leap()
		2:
			# Stage 2 (2.15..3.50s): Chasm Launch off mossy cliff wall into storm night!
			if stage_t >= 0.95 and region != null and region.ui != null:
				region.ui.set_fade(0.65, false)
			if stage_t >= 1.35:
				_enter_escape_sky()
		3:
			# Stage 3 (3.50..5.70s): Eastward Flight over receding cliff lights & storm clouds -> Brabant
			_wing_sfx_t += delta
			if _wing_sfx_t >= 0.62:
				_wing_sfx_t -= 0.62
				SoundManager.play_wing_beat()
			if stage_t >= 1.72 and region != null and region.ui != null:
				region.ui.set_fade(1.0, false)
			if stage_t >= 2.20:
				_complete()


func _enter_escape_balcony() -> void:
	stage = 1
	stage_t = 0.0
	visible = true
	_boy_mounted = false
	_sentry_entered = true
	if region != null and region.ui != null:
		region.ui.set_fade(0.0, false)
	SoundManager.play_campfire_warm()


func _enter_escape_leap() -> void:
	stage = 2
	stage_t = 0.0
	_shake_mag = 3.4
	_flash_alpha = 0.25
	SoundManager.play_wing_beat()
	_spawn_sparks(Vector2(250, 114), 18, Color(0.76, 0.80, 0.84), 38.0, 118.0)


func _enter_escape_sky() -> void:
	stage = 3
	stage_t = 0.0
	_wing_sfx_t = 0.0
	_shake_mag = 1.6
	_flash_alpha = 0.18
	if region != null and region.ui != null:
		region.ui.set_fade(0.0, false)
	SoundManager.play_wing_beat()


func _complete() -> void:
	active = false
	visible = false
	particles.clear()
	if region != null and mode == "pedestal":
		if region.director != null and region.director.camera != null:
			region.director.camera.zoom = Vector2(1.5, 1.5)
			if region.player != null:
				region.director.camera.position = region.player.position
			region.director.camera.reset_smoothing()
		if region.ui != null:
			region.ui.set_cinematic_mode(false)
			region.ui.set_hud_visible(true)
			region.ui.set_fade(0.0, false)
	var cb := _on_finished
	_on_finished = Callable()
	if cb.is_valid():
		cb.call()


func _spawn_sparks(origin: Vector2, count: int, col: Color, spd_min: float, spd_max: float) -> void:
	for _i in range(count):
		var ang := randf() * TAU
		var spd := randf_range(spd_min, spd_max)
		particles.append({
			"pos": origin + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)),
			"vel": Vector2(cos(ang), sin(ang) - 0.35) * spd,
			"grav": -14.0 if mode == "pedestal" else 65.0,
			"sz": randf_range(1.4, 2.8),
			"col": col,
			"life": randf_range(0.35, 0.78),
			"max_life": 0.78,
		})


func _step_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["life"] = float(p["life"]) - delta
		var v: Vector2 = Vector2(p["vel"])
		v.y += float(p["grav"]) * delta
		p["vel"] = v
		p["pos"] = Vector2(p["pos"]) + v * delta
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)


func _seed_wind() -> void:
	wind_lines.clear()
	for _i in range(12):
		wind_lines.append({
			"pos": Vector2(randf_range(0.0, CANVAS_W), randf_range(16.0, CANVAS_H - 18.0)),
			"w": randf_range(14.0, 32.0),
			"spd": randf_range(115.0, 210.0),
			"alpha": randf_range(0.08, 0.22),
		})


func _step_wind(delta: float) -> void:
	var dir_mult: float = -1.0 if (mode == "escape" and stage == 3) else 1.0
	for wl: Dictionary in wind_lines:
		var p: Vector2 = Vector2(wl["pos"])
		p.x += float(wl["spd"]) * delta * dir_mult
		if p.x < -40.0:
			p.x = CANVAS_W + 24.0
		elif p.x > CANVAS_W + 40.0:
			p.x = -36.0
		wl["pos"] = p


class _HeistDrawer extends Node2D:
	var owner_cutscene = null

	func _draw() -> void:
		if owner_cutscene == null or not owner_cutscene.visible or owner_cutscene.assets == null:
			return
		var cs = owner_cutscene
		var assets = cs.assets
		var t_now: float = cs.total_t
		var shake := Vector2.ZERO
		if float(cs._shake_mag) > 0.05:
			shake = Vector2(roundf(sin(t_now * 58.0) * float(cs._shake_mag)), roundf(cos(t_now * 46.0) * float(cs._shake_mag) * 0.7)) * SCALE

		# 0. Opaque midnight sky/abyss backing behind shake offsets
		draw_rect(Rect2(Vector2(-32.0, -32.0), Vector2(CANVAS_W * SCALE + 64.0, CANVAS_H * SCALE + 64.0)), Color(0.043, 0.059, 0.114, 1.0))

		if String(cs.mode) == "escape" and int(cs.stage) == 3:
			_draw_sky_glide(cs, assets, t_now, shake)
		else:
			_draw_courtyard_stage(cs, assets, t_now, shake)

		# Particles (pixel-grid snapped sparks / pebble chips)
		for pt: Dictionary in cs.particles:
			var a := clampf(float(pt["life"]) / float(pt["max_life"]), 0.0, 1.0)
			var pp: Vector2 = Vector2(pt["pos"]) * SCALE + shake
			var psz := maxf(SCALE, roundf(float(pt["sz"])) * SCALE)
			var col: Color = pt["col"]
			col.a *= a
			draw_rect(Rect2(pp - Vector2(psz * 0.5, psz * 0.5), Vector2(psz, psz)), col)

		if float(cs._flash_alpha) > 0.01:
			draw_rect(Rect2(Vector2.ZERO, Vector2(CANVAS_W * SCALE, CANVAS_H * SCALE)), Color(0.98, 0.90, 0.68, float(cs._flash_alpha) * 0.40))

	func _draw_courtyard_stage(cs, assets, t_now: float, shake: Vector2) -> void:
		var off := shake

		var bg_tex: Texture2D = assets.get_tex("cs_heist_bg.png")
		if bg_tex != null:
			draw_texture_rect(bg_tex, Rect2(off, Vector2(CANVAS_W * SCALE, CANVAS_H * SCALE)), false)

		# Soft multi-step torch & brazier ambient pools
		var braz_p := Vector2(122.0, 128.0) * SCALE + off
		for si in range(8):
			var fr := float(8 - si) / 8.0
			draw_circle(braz_p, (8.0 + fr * 28.0) * SCALE, Color(1.0, 0.68, 0.24, 0.018))

		# Wind-whipped iron wall torches
		var tf0 := int(t_now * 9.0) % 4
		var tf1 := (tf0 + 2) % 4
		var ttex0: Texture2D = assets.get_tex("cs_heist_torch_%d.png" % tf0)
		var ttex1: Texture2D = assets.get_tex("cs_heist_torch_%d.png" % tf1)
		if ttex0 != null:
			draw_texture_rect(ttex0, Rect2(Vector2(74.0, 34.0) * SCALE + off, Vector2(28.0, 44.0) * SCALE), false)
		if ttex1 != null:
			draw_texture_rect(ttex1, Rect2(Vector2(168.0, 68.0) * SCALE + off, Vector2(28.0, 44.0) * SCALE), false)

		# Brazier Egg Pedestal (full egg before lift -> empty smoking brazier afterward)
		var ped_idx := 0 if (String(cs.mode) == "pedestal" and int(cs.stage) == 0 and not bool(cs._pedestal_lifted)) else 1
		var ptex: Texture2D = assets.get_tex("cs_heist_pedestal_%d.png" % ped_idx)
		if ptex != null:
			draw_texture_rect(ptex, Rect2(Vector2(94.0, 86.0) * SCALE + off, Vector2(56.0, 64.0) * SCALE), false)

		# Archway Night-Watchmen burst out swinging lantern glow once alert triggers!
		if bool(cs._sentry_entered):
			var sf := 0
			var s_x := 8.0
			if String(cs.mode) == "pedestal":
				s_x = lerpf(-12.0, 12.0, clampf(float(cs.stage_t) / 1.1, 0.0, 1.0))
			elif int(cs.stage) == 1:
				sf = 0 if float(cs.stage_t) < 0.55 else 1
				s_x = lerpf(8.0, 34.0, clampf(float(cs.stage_t) / 0.9, 0.0, 1.0))
			else:
				sf = 1
				s_x = 38.0
			var l_pos := Vector2(s_x + 48.0, 102.0) * SCALE + off
			for li in range(8):
				var lf := float(8 - li) / 8.0
				draw_circle(l_pos, (6.0 + lf * 24.0) * SCALE, Color(1.0, 0.72, 0.28, 0.024))
			var stex: Texture2D = assets.get_tex("cs_heist_sentry_%d.png" % sf)
			if stex != null:
				draw_texture_rect(stex, Rect2(Vector2(s_x, 62.0) * SCALE + off, Vector2(60.0, 80.0) * SCALE), false)

		# Separate Boy figure (when NOT already mounted astride Kestrel)
		if String(cs.mode) == "pedestal":
			var bf := 0 if int(cs.stage) == 0 else 1
			var bx := 106.0 if bf == 0 else lerpf(110.0, 124.0, clampf(float(cs.stage_t) / 1.1, 0.0, 1.0))
			var btex: Texture2D = assets.get_tex("cs_heist_boy_%d.png" % bf)
			if btex != null:
				draw_texture_rect(btex, Rect2(Vector2(bx, 56.0) * SCALE + off, Vector2(80.0, 96.0) * SCALE), false)
		elif int(cs.stage) == 1 and not bool(cs._boy_mounted):
			var p_leap := clampf(float(cs.stage_t) / 0.40, 0.0, 1.0)
			var bx := lerpf(132.0, 174.0, p_leap)
			var by := 56.0 - sin(p_leap * PI) * 14.0
			var btex2: Texture2D = assets.get_tex("cs_heist_boy_2.png")
			if btex2 != null:
				draw_texture_rect(btex2, Rect2(Vector2(bx, by) * SCALE + off, Vector2(80.0, 96.0) * SCALE), false)

		# Perched / Mounted / Launching Mute Silver Kestrel
		var kf := 0
		var kx := 176.0
		var ky := 26.0
		if String(cs.mode) == "escape":
			if int(cs.stage) == 1 and bool(cs._boy_mounted):
				kf = 1
			elif int(cs.stage) == 2:
				kf = 2
				var lp := clampf(float(cs.stage_t) / 1.35, 0.0, 1.0)
				kx = 166.0 + lp * lp * 28.0
				ky = 26.0 - sin(lp * PI * 0.68) * 14.0 + lp * 4.0
		var ktex: Texture2D = assets.get_tex("cs_heist_kestrel_%d.png" % kf)
		if ktex != null:
			draw_texture_rect(ktex, Rect2(Vector2(kx, ky) * SCALE + off, Vector2(140.0, 120.0) * SCALE), false)

	func _draw_sky_glide(cs, assets, t_now: float, shake: Vector2) -> void:
		var bg_tex: Texture2D = assets.get_tex("cs_heist_sky_bg.png")
		if bg_tex != null:
			draw_texture_rect(bg_tex, Rect2(shake, Vector2(CANVAS_W * SCALE, CANVAS_H * SCALE)), false)

		# Fast slipstream air lines whipping west across moonlight
		for wl: Dictionary in cs.wind_lines:
			var wp := Vector2(roundf(float(Vector2(wl["pos"]).x)) * SCALE, roundf(float(Vector2(wl["pos"]).y)) * SCALE)
			draw_rect(Rect2(wp, Vector2(roundf(float(wl["w"])) * SCALE, SCALE)), Color(0.76, 0.86, 0.96, float(wl["alpha"])))

		# Animated 4-frame Kestrel soaring eastward with Rider + faint warm egg gold shimmer inside satchel
		var p_sky := clampf(float(cs.stage_t) / 2.20, 0.0, 1.0)
		var fx := lerpf(54.0, 146.0, p_sky)
		var fy := lerpf(64.0, 28.0, p_sky) + roundf(sin(t_now * 4.5) * 3.0)
		var ff := int(t_now * 7.5) % 4
		var ftex: Texture2D = assets.get_tex("cs_heist_fly_%d.png" % ff)
		if ftex != null:
			draw_texture_rect(ftex, Rect2(Vector2(fx, fy) * SCALE + shake, Vector2(128.0, 88.0) * SCALE), false)
		# Soft warm golden glimmer pulsing through wrapped bundle inside rider's arms
		var gp := Vector2(fx + 72.0, fy + 44.0) * SCALE + shake
		var pulse := 0.55 + 0.45 * sin(t_now * 6.0)
		for gi in range(4):
			draw_circle(gp, (2.5 + float(4 - gi) * 1.4) * SCALE, Color(1.0, 0.84, 0.38, 0.055 * pulse))
