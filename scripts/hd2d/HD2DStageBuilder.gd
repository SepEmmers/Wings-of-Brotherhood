extends RefCounted

## Reusable Octopath-style HD-2D 3D diorama toolkit for Godot 4.3 (GL Compatibility).
## Provides headless-safe texture/normal loading, material caching, normal-mapped Sprite3Ds,
## triplanar PBR world geometry, shader water planes, and atmospheric GPU particles.

static var _tex_cache: Dictionary = {}
static var _sprite_mat_cache: Dictionary = {}
static var _surface_mat_cache: Dictionary = {}
static var _assets_rev_cache: Dictionary = {}
static var _soft_radial_tex: Texture2D = null


static func load_png(res_path: String) -> Texture2D:
	if _tex_cache.has(res_path):
		return _tex_cache[res_path]
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return null
	var img := Image.load_from_file(abs_path)
	if img == null or img.is_empty():
		return null
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[res_path] = tex
	return tex


static func resolve_tex_name(assets_ref, tex: Texture2D) -> String:
	if assets_ref == null or tex == null:
		return ""
	var aid: int = assets_ref.get_instance_id()
	if not _assets_rev_cache.has(aid):
		var rev: Dictionary = {}
		var tex_dict = assets_ref.get("tex")
		if tex_dict is Dictionary:
			for k in tex_dict.keys():
				var v = tex_dict[k]
				if v != null:
					rev[v] = str(k)
		_assets_rev_cache[aid] = rev
	var rev_map: Dictionary = _assets_rev_cache[aid]
	return str(rev_map.get(tex, ""))


static func make_sprite_material(tex: Texture2D, tex_name: String, emissive_boost: float = 0.0, fixed_y_billboard: bool = true) -> StandardMaterial3D:
	var cache_key := "%s|%.2f|%d" % [tex_name if not tex_name.is_empty() else str(tex.get_rid().get_id() if tex != null else 0), emissive_boost, 1 if fixed_y_billboard else 0]
	if _sprite_mat_cache.has(cache_key):
		return _sprite_mat_cache[cache_key]

	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.roughness = 0.68
	mat.metallic = 0.06
	if fixed_y_billboard:
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		mat.billboard_keep_scale = true

	if not tex_name.is_empty():
		var norm_path := "res://assets/hd2d/normals/%s_n.png" % tex_name.get_basename()
		var norm_tex := load_png(norm_path)
		if norm_tex != null:
			mat.normal_enabled = true
			mat.normal_texture = norm_tex
			mat.normal_scale = 1.15

	if emissive_boost > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.78, 0.38)
		mat.emission_energy_multiplier = emissive_boost

	_sprite_mat_cache[cache_key] = mat
	return mat


static func apply_sprite3d_frame(spr: Sprite3D, tex: Texture2D, tex_name: String, emissive_boost: float = 0.0, fixed_y_billboard: bool = true) -> void:
	if spr == null or tex == null:
		return
	if spr.texture != tex or spr.material_override == null:
		spr.texture = tex
		spr.material_override = make_sprite_material(tex, tex_name, emissive_boost, fixed_y_billboard)
		spr.offset = Vector2(0.0, float(tex.get_height()) * 0.5)


static func make_sprite3d(
	tex: Texture2D,
	tex_name: String,
	pixel_size: float = 0.056,
	cast_shadow: bool = true,
	emissive_boost: float = 0.0,
	fixed_y_billboard: bool = true
) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.pixel_size = pixel_size
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tex != null:
		apply_sprite3d_frame(spr, tex, tex_name, emissive_boost, fixed_y_billboard)
	return spr


static func make_surface_material(tex_path: String, uv_density: float = 0.55, rough: float = 0.88) -> StandardMaterial3D:
	var cache_key := "%s|%.3f|%.2f" % [tex_path, uv_density, rough]
	if _surface_mat_cache.has(cache_key):
		return _surface_mat_cache[cache_key]

	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.albedo_texture = load_png(tex_path)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = false
	mat.uv1_scale = Vector3(uv_density, uv_density, uv_density)

	var norm_path := tex_path.get_basename() + "_n.png"
	var norm_tex := load_png(norm_path)
	if norm_tex != null:
		mat.normal_enabled = true
		mat.normal_texture = norm_tex
		mat.normal_scale = 1.12

	mat.roughness = rough
	mat.metallic = 0.04
	_surface_mat_cache[cache_key] = mat
	return mat


static func setup_diorama_environment(
	parent: Node3D,
	sky_top: Color,
	sky_horizon: Color,
	fog_color: Color,
	sun_energy: float = 1.15,
	sun_color: Color = Color(0.86, 0.90, 1.0),
	fog_density: float = 0.0065
) -> Dictionary:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = sky_horizon
	sky_mat.ground_bottom_color = fog_color.darkened(0.45)
	sky_mat.ground_horizon_color = sky_horizon.darkened(0.25)
	var sky := Sky.new()
	sky.sky_material = sky_mat

	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.22
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	env_node.environment = env
	parent.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.light_color = sun_color
	sun.light_energy = sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 58.0
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.50
	sun.shadow_blur = 1.4
	sun.rotation_degrees = Vector3(-44.0, -32.0, 0.0)
	parent.add_child(sun)

	return {"env_node": env_node, "env": env, "sky_mat": sky_mat, "sun": sun}


static func make_textured_box(size_vec: Vector3, tex_path: String, uv_density: float = 0.55, rough: float = 0.88) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size_vec
	mi.mesh = bm
	mi.material_override = make_surface_material(tex_path, uv_density, rough)
	return mi


static func make_textured_cylinder(radius_top: float, radius_bot: float, height: float, tex_path: String, uv_density: float = 0.60, rough: float = 0.88) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius_top
	cm.bottom_radius = radius_bot
	cm.height = height
	cm.radial_segments = 16
	mi.mesh = cm
	mi.material_override = make_surface_material(tex_path, uv_density, rough)
	return mi


static func make_color_box(size_vec: Vector3, albedo: Color, rough: float = 0.78, emissive: Color = Color.BLACK, emit_energy: float = 0.0, metallic: float = 0.08) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size_vec
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = rough
	mat.metallic = metallic
	if emit_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emissive
		mat.emission_energy_multiplier = emit_energy
	mi.material_override = mat
	return mi


static func make_water_plane(size_vec: Vector2, deep: Color, crest: Color, foam: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size_vec
	pm.subdivide_width = 48
	pm.subdivide_depth = 48
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/hd2d_fen_water.gdshader")
	mat.set_shader_parameter("deep_color", deep)
	mat.set_shader_parameter("crest_color", crest)
	mat.set_shader_parameter("foam_color", foam)
	mi.material_override = mat
	return mi


static func make_glow_bulb(pos: Vector3, radius: float = 0.14, col: Color = Color(1.0, 0.82, 0.42), energy: float = 2.6) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col.lightened(0.25)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	return mi


static func _get_soft_radial_tex() -> Texture2D:
	if _soft_radial_tex != null:
		return _soft_radial_tex
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var half := (float(s) - 1.0) * 0.5
	for y in range(s):
		for x in range(s):
			var dx := (float(x) - half) / half
			var dy := (float(y) - half) / half
			var r := sqrt(dx * dx + dy * dy)
			var a := pow(maxf(0.0, 1.0 - r), 2.2)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_soft_radial_tex = ImageTexture.create_from_image(img)
	return _soft_radial_tex


static func _make_particle_base(amount: int, lifetime: float, box_extents: Vector3, col: Color, qsize: Vector2, soft_circle: bool = false) -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.amount = amount
	gp.lifetime = lifetime
	gp.emitting = true
	gp.visibility_aabb = AABB(-box_extents * 2.5 - Vector3(2, 2, 2), box_extents * 5.0 + Vector3(4, 6, 4))

	var qm := QuadMesh.new()
	qm.size = qsize
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = col
	if soft_circle:
		mat.albedo_texture = _get_soft_radial_tex()
	qm.material = mat
	gp.draw_pass_1 = qm
	return gp


static func make_ember_particles(box_extents: Vector3, amount: int = 32) -> GPUParticles3D:
	var gp := _make_particle_base(amount, 2.2, box_extents, Color(1.0, 0.72, 0.28, 0.90), Vector2(0.07, 0.07))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box_extents
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 24.0
	pm.initial_velocity_min = 0.45
	pm.initial_velocity_max = 1.05
	pm.gravity = Vector3(0.08, 0.35, 0.0)
	gp.process_material = pm
	return gp


static func make_smoke_particles(box_extents: Vector3, amount: int = 24) -> GPUParticles3D:
	var gp := _make_particle_base(amount, 3.8, box_extents, Color(0.82, 0.86, 0.92, 0.34), Vector2(0.38, 0.38), true)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box_extents
	pm.direction = Vector3(0.18, 1.0, -0.08)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.35
	pm.initial_velocity_max = 0.72
	pm.gravity = Vector3(0.08, 0.20, 0.0)
	gp.process_material = pm
	return gp


static func make_firefly_particles(box_extents: Vector3, amount: int = 56) -> GPUParticles3D:
	var gp := _make_particle_base(amount, 4.4, box_extents, Color(0.95, 0.88, 0.45, 0.85), Vector2(0.11, 0.11), true)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box_extents
	pm.direction = Vector3(0.1, 0.25, 0.1)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3(0.0, 0.04, 0.0)
	gp.process_material = pm
	return gp


static func make_mist_particles(box_extents: Vector3, amount: int = 38) -> GPUParticles3D:
	var gp := _make_particle_base(amount, 6.0, box_extents, Color(0.76, 0.84, 0.94, 0.18), Vector2(3.2, 1.25), true)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box_extents
	pm.direction = Vector3(1.0, 0.04, 0.15)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.18
	pm.initial_velocity_max = 0.42
	pm.gravity = Vector3.ZERO
	gp.process_material = pm
	return gp
