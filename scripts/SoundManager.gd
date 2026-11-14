extends Node

## Autoload audio manager that loads 44.1 kHz 16-bit PCM .wav files directly from disk,
## supports smooth crossfading across 5 contextual medieval music/ambience loops,
## surface-aware footsteps, expressive character dialogue voices, and pooled polyphonic SFX.

var sfx_streams: Dictionary = {}
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_idx: int = 0
var blip_player: AudioStreamPlayer

# Dual players for seamless crossfade between scene ambiences
var amb_players: Array[AudioStreamPlayer] = []
var layer_pasture_player: AudioStreamPlayer
var layer_mess_player: AudioStreamPlayer
var active_amb_idx: int = 0
var current_amb_name: String = ""
var crossfade_t: float = 1.0
var crossfade_dur: float = 1.4
const AMB_TARGET_DB: float = -12.0

var step_cooldown: float = 0.0
var current_surface: String = "cobble"

const AMBIENCE_FILES: Array[String] = [
	"amb_harbor.wav",
	"amb_hearth.wav",
	"amb_dawn_tension.wav",
	"amb_sanctuary.wav",
	"amb_wilds.wav",
	"amb_flight.wav",
	"amb_layer_pasture.wav",
	"amb_layer_mess.wav",
]

const SFX_FILES: Array[String] = [
	"sfx_step.wav",
	"sfx_step_cobble_1.wav", "sfx_step_cobble_2.wav", "sfx_step_cobble_3.wav",
	"sfx_step_wood_1.wav", "sfx_step_wood_2.wav", "sfx_step_wood_3.wav",
	"sfx_step_grass_1.wav", "sfx_step_grass_2.wav", "sfx_step_grass_3.wav",
	"sfx_blip.wav",
	"sfx_voice_boy.wav", "sfx_voice_female.wav", "sfx_voice_gruff.wav",
	"sfx_voice_stern.wav", "sfx_voice_dragon.wav",
	"sfx_rope.wav", "sfx_rope_winch.wav",
	"sfx_knot_peg.wav", "sfx_knot_snag.wav", "sfx_knot_fail.wav", "sfx_knot_cinch.wav",
	"sfx_chime.wav", "sfx_splash.wav",
	"sfx_crate_pickup.wav", "sfx_door.wav", "sfx_journal.wav", "sfx_ui_click.wav",
	"sfx_ship_bell.wav", "sfx_dragon_purr.wav", "sfx_dragon_cry.wav", "sfx_campfire_warm.wav",
	"sfx_slash.wav", "sfx_dodge.wav", "sfx_wing_beat.wav",
	"sfx_ballista.wav", "sfx_bolt.wav", "sfx_hit_thud.wav", "sfx_alert_horn.wav",
	"sfx_egg_crack.wav", "sfx_hatch_chirp.wav", "sfx_cage_break.wav",
	"sfx_butcher_chop.wav", "sfx_dragon_chomp.wav",
	"sfx_church_bell.wav", "sfx_oven_crackle.wav",
]


func _ready() -> void:
	for _i in range(5):
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		sfx_pool.append(p)

	blip_player = AudioStreamPlayer.new()
	blip_player.volume_db = -11.0
	add_child(blip_player)

	for _i in range(2):
		var ap := AudioStreamPlayer.new()
		ap.volume_db = -80.0
		add_child(ap)
		amb_players.append(ap)

	layer_pasture_player = AudioStreamPlayer.new()
	layer_pasture_player.volume_db = -80.0
	add_child(layer_pasture_player)

	layer_mess_player = AudioStreamPlayer.new()
	layer_mess_player.volume_db = -80.0
	add_child(layer_mess_player)

	_load_all_wavs()
	start_ambience()


func _exit_tree() -> void:
	for ap in amb_players:
		if is_instance_valid(ap):
			ap.stop()
			ap.stream = null
	for lp in [layer_pasture_player, layer_mess_player]:
		if is_instance_valid(lp):
			lp.stop()
			lp.stream = null
	for sp in sfx_pool:
		if is_instance_valid(sp):
			sp.stop()
			sp.stream = null
	if is_instance_valid(blip_player):
		blip_player.stop()
		blip_player.stream = null
	sfx_streams.clear()
	amb_players.clear()
	sfx_pool.clear()


func _process(delta: float) -> void:
	if step_cooldown > 0.0:
		step_cooldown -= delta

	if crossfade_t < 1.0 and amb_players.size() == 2:
		crossfade_t = minf(1.0, crossfade_t + delta / maxf(0.05, crossfade_dur))
		var incoming := amb_players[active_amb_idx]
		var outgoing := amb_players[1 - active_amb_idx]
		incoming.volume_db = lerpf(-50.0, AMB_TARGET_DB, crossfade_t)
		outgoing.volume_db = lerpf(AMB_TARGET_DB, -60.0, crossfade_t)
		if crossfade_t >= 1.0 and outgoing.playing:
			outgoing.stop()


func _load_all_wavs() -> void:
	for fname in AMBIENCE_FILES:
		var stream := _load_wav_direct("res://assets/audio/" + fname, true)
		if stream != null:
			sfx_streams[fname] = stream
	for fname in SFX_FILES:
		var stream := _load_wav_direct("res://assets/audio/" + fname, false)
		if stream != null:
			sfx_streams[fname] = stream


func _load_wav_direct(res_path: String, loop: bool) -> AudioStreamWAV:
	var abs_path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return null
	var bytes := FileAccess.get_file_as_bytes(abs_path)
	if bytes.size() < 44:
		return null

	var pos := 12
	var sample_rate := 44100
	var channels := 1
	var data_offset := 44
	var data_size := bytes.size() - 44

	while pos + 8 <= bytes.size():
		var chunk_id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var chunk_len := bytes.decode_u32(pos + 4)
		if chunk_id == "fmt ":
			channels = bytes.decode_u16(pos + 10)
			sample_rate = bytes.decode_u32(pos + 12)
		elif chunk_id == "data":
			data_offset = pos + 8
			data_size = mini(chunk_len, bytes.size() - data_offset)
			break
		pos += 8 + chunk_len
		if chunk_len % 2 == 1:
			pos += 1

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = (channels == 2)
	wav.data = bytes.slice(data_offset, data_offset + data_size)
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(data_size / (2 * channels))
	return wav


func start_ambience() -> void:
	set_ambience("amb_harbor.wav", 0.2)


func _is_headless() -> bool:
	return OS.has_feature("headless") or DisplayServer.get_name() == "headless"


func set_ambience(track_name: String, fade_sec: float = 1.4) -> void:
	var resolved := track_name
	if not resolved.ends_with(".wav"):
		resolved = "amb_" + resolved + ".wav"
	if _is_headless():
		current_amb_name = resolved
		return
	if resolved == current_amb_name and amb_players[active_amb_idx].playing:
		return
	var stream: AudioStreamWAV = sfx_streams.get(resolved)
	if stream == null:
		return
	current_amb_name = resolved
	active_amb_idx = 1 - active_amb_idx
	var incoming := amb_players[active_amb_idx]
	incoming.stream = stream
	incoming.volume_db = -50.0
	incoming.play()
	crossfade_dur = maxf(0.1, fade_sec)
	crossfade_t = 0.0


func set_surface(surface_name: String) -> void:
	current_surface = surface_name


func update_spatial_layers(pasture_weight: float, mess_weight: float) -> void:
	if _is_headless():
		return
	_apply_spatial_layer(layer_pasture_player, "amb_layer_pasture.wav", pasture_weight)
	_apply_spatial_layer(layer_mess_player, "amb_layer_mess.wav", mess_weight)


func stop_spatial_layers() -> void:
	for lp in [layer_pasture_player, layer_mess_player]:
		if is_instance_valid(lp):
			if lp.playing:
				lp.stop()
			lp.volume_db = -80.0


func _apply_spatial_layer(player_node: AudioStreamPlayer, wav_key: String, weight: float) -> void:
	if not is_instance_valid(player_node):
		return
	var w := clampf(weight, 0.0, 1.0)
	if w <= 0.02:
		if player_node.playing:
			player_node.stop()
		player_node.volume_db = -80.0
		return
	if player_node.stream == null:
		player_node.stream = sfx_streams.get(wav_key)
	if player_node.stream != null and not player_node.playing:
		player_node.play()
	player_node.volume_db = linear_to_db(clampf(w * 0.25, 0.0001, 1.0))


func _play_sfx(fname: String, volume_db: float = -4.0, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	if _is_headless():
		return
	var stream: AudioStreamWAV = sfx_streams.get(fname)
	if stream == null:
		return
	var p := sfx_pool[sfx_pool_idx]
	sfx_pool_idx = (sfx_pool_idx + 1) % sfx_pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(pitch_min, pitch_max) if not is_equal_approx(pitch_min, pitch_max) else pitch_min
	p.play()


func play_step(sprinting: bool = false, surface_override: String = "") -> void:
	if _is_headless() or step_cooldown > 0.0:
		return
	var surf := current_surface if surface_override.is_empty() else surface_override
	var variant := randi_range(1, 3)
	var fname := "sfx_step_%s_%d.wav" % [surf, variant]
	if not sfx_streams.has(fname):
		fname = "sfx_step.wav"
	var vol := -9.5 if sprinting else -12.0
	if surf == "grass":
		vol -= 1.5
	_play_sfx(fname, vol, 0.94, 1.09)
	step_cooldown = 0.23 if sprinting else 0.34


func play_voice_blip(voice_kind: String = "default", pitch: float = 1.0) -> void:
	if _is_headless():
		return
	var fname := "sfx_blip.wav"
	match voice_kind:
		"boy": fname = "sfx_voice_boy.wav"
		"female": fname = "sfx_voice_female.wav"
		"gruff": fname = "sfx_voice_gruff.wav"
		"stern": fname = "sfx_voice_stern.wav"
		"dragon": fname = "sfx_voice_dragon.wav"
	if not sfx_streams.has(fname):
		fname = "sfx_blip.wav"
	var stream: AudioStreamWAV = sfx_streams.get(fname)
	if stream != null:
		blip_player.stream = stream
		blip_player.pitch_scale = pitch * randf_range(0.95, 1.05)
		blip_player.volume_db = -8.0 if voice_kind == "dragon" else -11.0
		blip_player.play()


func play_blip(pitch: float = 1.0) -> void:
	play_voice_blip("default", pitch)


func play_rope() -> void:
	_play_sfx("sfx_rope.wav", -4.0, 0.96, 1.05)


func play_rope_winch() -> void:
	_play_sfx("sfx_rope_winch.wav", -3.5, 0.98, 1.04)


func play_knot_peg(step_idx: int = 1) -> void:
	var p := 0.92 + float(step_idx) * 0.06
	_play_sfx("sfx_knot_peg.wav", -5.0, p, p + 0.03)


func play_knot_snag() -> void:
	_play_sfx("sfx_knot_snag.wav", -3.0, 0.94, 1.04)


func play_knot_fail() -> void:
	_play_sfx("sfx_knot_fail.wav", -3.5, 0.98, 1.02)


func play_knot_cinch() -> void:
	_play_sfx("sfx_knot_cinch.wav", -3.0, 1.0, 1.0)


func play_chime() -> void:
	_play_sfx("sfx_chime.wav", -4.5, 1.0, 1.0)


func play_splash() -> void:
	_play_sfx("sfx_splash.wav", -5.5, 0.95, 1.07)


func play_crate_pickup() -> void:
	_play_sfx("sfx_crate_pickup.wav", -5.0, 0.95, 1.05)


func play_door() -> void:
	_play_sfx("sfx_door.wav", -4.5, 0.97, 1.03)


func play_journal() -> void:
	_play_sfx("sfx_journal.wav", -6.0, 0.96, 1.05)


func play_ui_click() -> void:
	_play_sfx("sfx_ui_click.wav", -8.0, 0.96, 1.05)


func play_ship_bell() -> void:
	_play_sfx("sfx_ship_bell.wav", -4.0, 1.0, 1.0)


func play_dragon_purr() -> void:
	_play_sfx("sfx_dragon_purr.wav", -3.0, 0.98, 1.03)


func play_dragon_cry() -> void:
	_play_sfx("sfx_dragon_cry.wav", -4.0, 0.98, 1.02)


func play_campfire_warm() -> void:
	_play_sfx("sfx_campfire_warm.wav", -5.0, 0.98, 1.02)


func play_slash() -> void:
	_play_sfx("sfx_slash.wav", -3.5, 0.94, 1.08)


func play_dodge() -> void:
	_play_sfx("sfx_dodge.wav", -4.5, 0.94, 1.06)


func play_wing_beat() -> void:
	_play_sfx("sfx_wing_beat.wav", -3.0, 0.92, 1.06)


func play_ballista() -> void:
	_play_sfx("sfx_ballista.wav", -2.5, 0.94, 1.06)


func play_bolt() -> void:
	_play_sfx("sfx_bolt.wav", -4.0, 0.95, 1.08)


func play_hit() -> void:
	_play_sfx("sfx_hit_thud.wav", -2.5, 0.92, 1.05)


func play_alert_horn() -> void:
	_play_sfx("sfx_alert_horn.wav", -3.5, 0.98, 1.02)


func play_egg_crack() -> void:
	_play_sfx("sfx_egg_crack.wav", -2.5, 0.95, 1.06)


func play_hatch_chirp() -> void:
	_play_sfx("sfx_hatch_chirp.wav", -2.0, 0.96, 1.06)


func play_cage_break() -> void:
	_play_sfx("sfx_cage_break.wav", -2.5, 0.95, 1.05)


func play_butcher_chop() -> void:
	_play_sfx("sfx_butcher_chop.wav", -2.5, 0.93, 1.07)


func play_dragon_chomp() -> void:
	_play_sfx("sfx_dragon_chomp.wav", -2.0, 0.96, 1.04)


func play_church_bell() -> void:
	_play_sfx("sfx_church_bell.wav", -1.5, 0.98, 1.02)


func play_oven_crackle() -> void:
	_play_sfx("sfx_oven_crackle.wav", -8.0, 0.92, 1.08)
