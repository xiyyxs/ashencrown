extends Node3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var open_world_root: Node3D
var instance_root: Node3D
var sun_light: DirectionalLight3D
var world_env: WorldEnvironment
var env_res: Environment
var camp_lights: Array = []
var portal_rings: Array = []

var current_zone_id: String = "elwynn"
var in_instance: bool = false
var current_instance: Dictionary = {}
var ambient_motes: Array = []
var ambient_mat: StandardMaterial3D

func _ready() -> void:
	_setup_environment()
	open_world_root = Node3D.new()
	add_child(open_world_root)

	instance_root = Node3D.new()
	instance_root.visible = false
	add_child(instance_root)

	_build_open_world()
	_setup_ambient_motes()

func _setup_environment() -> void:
	env_res = Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.08, 0.11, 0.16)
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.55, 0.62, 0.58)
	env_res.ambient_light_energy = 0.68
	env_res.fog_enabled = true
	env_res.fog_light_color = Color(0.16, 0.22, 0.28)
	env_res.fog_density = 0.0065

	world_env = WorldEnvironment.new()
	world_env.environment = env_res
	add_child(world_env)

	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-50.0, 32.0, 0.0)
	sun_light.light_energy = 0.85
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_max_distance = 75.0
	add_child(sun_light)

func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	for l in camp_lights:
		if is_instance_valid(l):
			l.light_energy = 2.2 + sin(t * 9.0 + l.global_position.x) * 0.35
	for r in portal_rings:
		if is_instance_valid(r):
			r.rotate_z(delta * 1.4)
	_update_ambient_motes(delta, t)

func _setup_ambient_motes() -> void:
	ambient_mat = StandardMaterial3D.new()
	ambient_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ambient_mat.albedo_color = Color(0.95, 0.92, 0.55)
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(0.14, 0.14, 0.14)
	for i in range(28):
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = bm
		mi.material_override = ambient_mat
		mi.position = Vector3(68.0 + randf_range(-16.0, 16.0), randf_range(0.6, 5.5), 238.0 + randf_range(-16.0, 16.0))
		add_child(mi)
		ambient_motes.append({"node": mi, "seed": randf() * 100.0, "off": Vector3(randf_range(-16.0, 16.0), randf_range(0.5, 5.5), randf_range(-16.0, 16.0))})

func _update_ambient_motes(delta: float, t: float) -> void:
	if ambient_motes.is_empty():
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(cam):
		return
	var anchor: Vector3 = cam.global_position + cam.global_transform.basis.z * -14.0
	anchor.y = maxf(0.0, anchor.y - 3.5)
	var fall_dir: float = -1.6 if current_zone_id == "frostpeak" else (1.1 if current_zone_id == "citadel" else 0.18)
	var target_col: Color = Color(0.92, 0.96, 1.0)
	match current_zone_id:
		"elwynn": target_col = Color(0.96, 0.92, 0.45)
		"duskwood": target_col = Color(0.52, 0.72, 1.0)
		"barrens": target_col = Color(0.98, 0.74, 0.38)
		"frostpeak": target_col = Color(0.92, 0.96, 1.0)
		"plaguelands": target_col = Color(0.55, 0.96, 0.25)
		"citadel": target_col = Color(1.0, 0.44, 0.12)
	if in_instance:
		target_col = Color(0.85, 0.78, 1.0)
		fall_dir = 0.35
	ambient_mat.albedo_color = ambient_mat.albedo_color.lerp(target_col, 0.08)

	for m in ambient_motes:
		var off: Vector3 = m["off"]
		var sd: float = float(m["seed"])
		off.y += fall_dir * delta
		off.x += sin(t * 1.4 + sd) * delta * 0.9
		off.z += cos(t * 1.2 + sd) * delta * 0.9
		if off.y < 0.2:
			off.y = 6.2
		elif off.y > 6.5:
			off.y = 0.3
		m["off"] = off
		var mi: MeshInstance3D = m["node"]
		mi.position = Vector3(anchor.x + off.x, GameData.WATER_Y + off.y + (0.8 if not in_instance else 0.0), anchor.z + off.z)

func update_biome_lighting(pos: Vector3) -> void:
	if in_instance:
		return
	var z: Dictionary = GameData.get_zone_at(pos)
	current_zone_id = str(z["id"])
	var amb: Color = z["ambient"]
	var sun: Color = z["sun"]
	env_res.ambient_light_color = env_res.ambient_light_color.lerp(amb, 0.05)
	sun_light.light_color = sun_light.light_color.lerp(sun, 0.05)
	env_res.fog_light_color = env_res.fog_light_color.lerp(amb.darkened(0.45), 0.05)

func _make_tex_mat(tex: Texture2D, uv_scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_scale = Vector3(uv_scale, uv_scale, 1.0)
	m.roughness = 1.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m

func _make_terrain_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _make_detail_noise_tex()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m

func _make_detail_noise_tex() -> ImageTexture:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var h: int = abs(((x * 73856093) ^ (y * 19349663)) % 100)
			var v: float = 0.94
			if h < 18:
				v = 0.82
			elif h < 30:
				v = 1.0
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)

func _hash2(x: int, y: int) -> int:
	var n: int = x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return abs(n ^ (n >> 16))

func _build_terrain_chunk(x0: float, z0: float, terrain_mat: StandardMaterial3D) -> void:
	var step: float = 5.0
	var cells: int = int(GameData.ZONE_W / step) # 44 x 44 = 1936 quads
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for gz in range(cells):
		for gx in range(cells):
			var px0: float = x0 + float(gx) * step
			var pz0: float = z0 + float(gz) * step
			var px1: float = px0 + step
			var pz1: float = pz0 + step

			var pts: Array = [
				Vector2(px0, pz0), Vector2(px1, pz0),
				Vector2(px1, pz1), Vector2(px0, pz1)
			]
			var verts: Array = []
			var cols: Array = []
			var uvs: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			for p in pts:
				var y: float = GameData.get_terrain_height(p.x, p.y)
				verts.append(Vector3(p.x, y, p.y))
				cols.append(_terrain_vertex_color(p.x, p.y, y))

			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(cols[idx])
				st.set_uv(uvs[idx])
				st.add_vertex(verts[idx])

	st.generate_normals()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = terrain_mat
	open_world_root.add_child(mi)

func _terrain_vertex_color(x: float, z: float, y: float) -> Color:
	var zb: Dictionary = GameData.get_zone_blended(x, z)
	var zid: String = str(zb["id"])
	var base: Color = zb["ground"]
	var acc: Color = zb["accent"]
	var n: float = sin(x * 0.14) * cos(z * 0.14)
	var col: Color = base.lerp(acc, clampf(n * 0.5 + 0.35, 0.0, 0.8))

	# Дороги (тёплая брусчатка/грунт)
	var rd: float = GameData.get_road_dist(x, z)
	if rd < 3.4 and y > GameData.WATER_Y + 0.1:
		var rf: float = clampf(1.0 - (rd - 1.4) / 2.0, 0.0, 1.0)
		var road_col: Color = Color(0.32, 0.24, 0.20) if zid == "citadel" else Color(0.50, 0.40, 0.28)
		col = col.lerp(road_col, rf)

	# Песчаные берега и морское дно
	if y < GameData.WATER_Y:
		col = Color(0.12, 0.22, 0.34)
	elif y < GameData.WATER_Y + 0.55:
		var sand_c: Color = Color(0.24, 0.17, 0.15) if zid == "citadel" else Color(0.74, 0.65, 0.46)
		col = col.lerp(sand_c, clampf((GameData.WATER_Y + 0.55 - y) / 0.55, 0.0, 0.88))

	# Скалистые горные хребты и заснеженные вершины
	if y > 2.6:
		var mf: float = clampf((y - 2.6) / 3.0, 0.0, 1.0)
		var rock_c: Color = Color(0.42, 0.40, 0.44)
		if zid == "frostpeak":
			rock_c = Color(0.90, 0.95, 1.0)
		elif zid == "citadel":
			rock_c = Color(0.18, 0.14, 0.16)
		elif zid == "barrens":
			rock_c = Color(0.62, 0.34, 0.20)
		col = col.lerp(rock_c, mf)

	return col

func _build_open_world() -> void:
	# 1. Скульптурный 3D-ландшафт с бухтами, перевалами, озером и вулканическим островом
	var t_mat: StandardMaterial3D = _make_terrain_mat()
	for gy in range(2):
		for gx in range(3):
			var x0: float = float(gx) * GameData.ZONE_W
			var z0: float = float(gy) * GameData.ZONE_H
			_build_terrain_chunk(x0, z0, t_mat)

	# 2. Анимированная пиксельная вода (океан, реки и озёра)
	var w_sh: Shader = Shader.new()
	w_sh.code = """
shader_type spatial;
render_mode unshaded;
void fragment() {
	vec2 uv = UV * vec2(120.0, 80.0);
	float w = sin(uv.x * 2.0 + TIME * 2.4) * cos(uv.y * 2.0 - TIME * 1.8);
	vec3 c = mix(vec3(0.08, 0.32, 0.62), vec3(0.24, 0.62, 0.92), step(0.35, w));
	ALBEDO = c;
	ALPHA = 0.88;
}
"""
	var w_mat: ShaderMaterial = ShaderMaterial.new()
	w_mat.shader = w_sh
	var water_plane: PlaneMesh = PlaneMesh.new()
	water_plane.size = Vector2(GameData.WORLD_W, GameData.WORLD_H)
	var w_mi: MeshInstance3D = MeshInstance3D.new()
	w_mi.mesh = water_plane
	w_mi.material_override = w_mat
	w_mi.position = Vector3(GameData.WORLD_W * 0.5, GameData.WATER_Y, GameData.WORLD_H * 0.5)
	open_world_root.add_child(w_mi)

	# 3. Мосты через Чёрную реку и Вулканический пролив
	var br1_a: Vector2 = Vector2(154.0, 224.0)
	var br1_b: Vector2 = Vector2(246.0, 272.0)
	var br1_pos: Vector3 = Vector3(200.0, GameData.WATER_Y + 0.38, 248.0)
	MeshBuilder3D.build_bridge(open_world_root, br1_pos, atan2(br1_b.x - br1_a.x, br1_b.y - br1_a.y), 20.0)

	var br2_a: Vector2 = Vector2(514.0, 286.0)
	var br2_b: Vector2 = Vector2(546.0, 344.0)
	var br2_pos: Vector3 = Vector3(530.0, GameData.WATER_Y + 0.42, 315.0)
	MeshBuilder3D.build_bridge(open_world_root, br2_pos, atan2(br2_b.x - br2_a.x, br2_b.y - br2_a.y), 22.0)

	# 4. Уникальные города, ориентиры и арены боссов + внешние постройки и лагеря!
	for z in GameData.ZONES:
		_build_camp_hub(z["hub"], str(z["id"]), str(z["town"]))
		_build_boss_arena(z["boss_pos"])
		for lm in z["landmarks"]:
			_build_landmark(lm["pos"], str(lm["id"]), str(z["decor"]))
	_build_world_outposts_and_roads()

	# 5. Насыщенная природа огромных биомов (рощи, валуны, кристаллы, руины!)
	var step: float = 8.4
	var cols: int = int(GameData.WORLD_W / step)
	var rows: int = int(GameData.WORLD_H / step)
	for gz in range(rows):
		for gx in range(cols):
			var h: int = _hash2(gx, gz)
			if h % 3 == 0:
				continue
			var px: float = (float(gx) + 0.5) * step + float((h % 5) - 2) * 0.9
			var pz: float = (float(gz) + 0.5) * step + float(((h >> 3) % 5) - 2) * 0.9
			if not GameData.is_land(px, pz):
				continue
			if GameData.get_road_dist(px, pz) < 5.0 or GameData.get_river_dist(px, pz) < 7.2:
				continue
			var py: float = GameData.get_terrain_height(px, pz)
			if py < GameData.WATER_Y + 0.45:
				continue
			var pos: Vector3 = Vector3(px, py, pz)
			var zone: Dictionary = GameData.get_zone_blended(px, pz)
			if pos.distance_to(zone["hub"]) < 17.0 or pos.distance_to(zone["boss_pos"]) < 13.0:
				continue
			var skip_lm: bool = false
			for lm in zone["landmarks"]:
				if Vector2(px - lm["pos"].x, pz - lm["pos"].z).length() < 11.5:
					skip_lm = true
					break
			if skip_lm:
				continue
			_build_biome_prop(pos, str(zone["decor"]), h)

	# 6. Горные границы мира
	var border_mat: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.24, 0.22, 0.26))
	var wall_n: BoxMesh = BoxMesh.new()
	wall_n.size = Vector3(GameData.WORLD_W + 6.0, 8.0, 4.0)
	_add_mesh(open_world_root, wall_n, border_mat, Vector3(GameData.WORLD_W * 0.5, 2.5, -2.0))
	_add_mesh(open_world_root, wall_n, border_mat, Vector3(GameData.WORLD_W * 0.5, 2.5, GameData.WORLD_H + 2.0))
	var wall_w: BoxMesh = BoxMesh.new()
	wall_w.size = Vector3(4.0, 8.0, GameData.WORLD_H + 6.0)
	_add_mesh(open_world_root, wall_w, border_mat, Vector3(-2.0, 2.5, GameData.WORLD_H * 0.5))
	_add_mesh(open_world_root, wall_w, border_mat, Vector3(GameData.WORLD_W + 2.0, 2.5, GameData.WORLD_H * 0.5))

func _add_mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func _build_camp_hub(hub_raw: Vector3, zid: String, _title: String) -> void:
	var hy: float = GameData.get_terrain_height(hub_raw.x, hub_raw.z)
	var hub: Vector3 = Vector3(hub_raw.x, hy, hub_raw.z)

	# Мощеная городская площадь
	var pad: CylinderMesh = CylinderMesh.new()
	pad.top_radius = 11.5
	pad.bottom_radius = 12.5
	pad.height = 0.14
	pad.radial_segments = 16
	_add_mesh(open_world_root, pad, _make_tex_mat(PixelArt.ground_textures["road"], 5.0), hub + Vector3(0, 0.05, 0))

	# Каменное кольцо вокруг костра
	var stone_m: CylinderMesh = CylinderMesh.new()
	stone_m.top_radius = 0.24
	stone_m.bottom_radius = 0.28
	stone_m.height = 0.22
	stone_m.radial_segments = 6
	var stone_mat: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.36, 0.35, 0.38))
	for si in range(8):
		var a: float = float(si) * TAU / 8.0
		_add_mesh(open_world_root, stone_m, stone_mat, hub + Vector3(cos(a) * 1.05, 0.11, sin(a) * 1.05))

	var fire_m: CylinderMesh = CylinderMesh.new()
	fire_m.top_radius = 0.04
	fire_m.bottom_radius = 0.42
	fire_m.height = 1.05
	fire_m.radial_segments = 6
	_add_mesh(open_world_root, fire_m, MeshBuilder3D.make_ink_mat(Color(1.0, 0.56, 0.12), null, Color(1.0, 0.52, 0.08), 2.8), hub + Vector3(0, 0.52, 0))

	var ol: OmniLight3D = OmniLight3D.new()
	ol.light_color = Color(1.0, 0.68, 0.30)
	ol.light_energy = 2.6
	ol.omni_range = 20.0
	ol.position = hub + Vector3(0, 1.8, 0)
	open_world_root.add_child(ol)
	camp_lights.append(ol)

	# Уникальная архитектура городов + стены, врата, лавки и таверна в каждом городе!
	var w_col: Color = Color(0.46, 0.45, 0.48)
	var b_col: Color = Color(0.22, 0.46, 0.85)
	match zid:
		"elwynn":
			w_col = Color(0.56, 0.54, 0.52); b_col = Color(0.22, 0.46, 0.85)
			MeshBuilder3D.build_abbey_keep(open_world_root, hub + Vector3(-5.8, 0.0, -7.2), Color(0.68, 0.66, 0.62), Color(0.24, 0.42, 0.72), Color(0.20, 0.45, 0.88))
			MeshBuilder3D.build_tavern(open_world_root, hub + Vector3(5.6, 0.0, -7.2))
			MeshBuilder3D.build_forge(open_world_root, hub + Vector3(-7.4, 0.0, 2.5))
			MeshBuilder3D.build_watchtower(open_world_root, hub + Vector3(9.2, 0.0, 6.2), Color(0.42, 0.26, 0.14), b_col)
		"duskwood":
			w_col = Color(0.28, 0.30, 0.36); b_col = Color(0.42, 0.28, 0.65)
			MeshBuilder3D.build_abbey_keep(open_world_root, hub + Vector3(-5.8, 0.0, -7.2), Color(0.32, 0.34, 0.40), Color(0.18, 0.16, 0.28), b_col)
			MeshBuilder3D.build_tavern(open_world_root, hub + Vector3(5.6, 0.0, -7.2))
			MeshBuilder3D.build_forge(open_world_root, hub + Vector3(-7.4, 0.0, 2.5))
			MeshBuilder3D.build_watchtower(open_world_root, hub + Vector3(9.2, 0.0, 6.2), Color(0.26, 0.24, 0.28), b_col)
		"barrens":
			w_col = Color(0.52, 0.34, 0.22); b_col = Color(0.76, 0.18, 0.14)
			MeshBuilder3D.build_orc_fort(open_world_root, hub + Vector3(-5.8, 0.0, -6.5))
			MeshBuilder3D.build_tavern(open_world_root, hub + Vector3(5.6, 0.0, -7.2))
			MeshBuilder3D.build_watchtower(open_world_root, hub + Vector3(9.2, 0.0, 6.2), Color(0.46, 0.26, 0.14), b_col)
			MeshBuilder3D.build_forge(open_world_root, hub + Vector3(-7.4, 0.0, 2.5))
		"frostpeak":
			w_col = Color(0.44, 0.50, 0.58); b_col = Color(0.30, 0.72, 0.95)
			MeshBuilder3D.build_abbey_keep(open_world_root, hub + Vector3(-5.8, 0.0, -7.2), Color(0.48, 0.52, 0.58), Color(0.28, 0.52, 0.76), b_col)
			MeshBuilder3D.build_tavern(open_world_root, hub + Vector3(5.6, 0.0, -7.2))
			MeshBuilder3D.build_forge(open_world_root, hub + Vector3(-7.4, 0.0, 2.5))
			MeshBuilder3D.build_watchtower(open_world_root, hub + Vector3(9.2, 0.0, 6.2), Color(0.38, 0.42, 0.48), b_col)
		"plaguelands":
			w_col = Color(0.34, 0.36, 0.30); b_col = Color(0.88, 0.72, 0.24)
			MeshBuilder3D.build_abbey_keep(open_world_root, hub + Vector3(-5.8, 0.0, -7.2), Color(0.38, 0.40, 0.34), Color(0.55, 0.46, 0.22), b_col)
			MeshBuilder3D.build_tavern(open_world_root, hub + Vector3(5.6, 0.0, -7.2))
			MeshBuilder3D.build_forge(open_world_root, hub + Vector3(-7.4, 0.0, 2.5))
		_:
			w_col = Color(0.22, 0.18, 0.22); b_col = Color(0.95, 0.32, 0.12)
			MeshBuilder3D.build_abbey_keep(open_world_root, hub + Vector3(-5.8, 0.0, -7.2), Color(0.20, 0.16, 0.22), Color(0.72, 0.22, 0.10), b_col)
			MeshBuilder3D.build_tavern(open_world_root, hub + Vector3(5.6, 0.0, -7.2))
			MeshBuilder3D.build_forge(open_world_root, hub + Vector3(-7.4, 0.0, 2.5))
	MeshBuilder3D.build_town_walls_and_gate(open_world_root, hub, w_col, b_col)
	MeshBuilder3D.build_lantern_post(open_world_root, hub + Vector3(-3.8, 0.0, 11.2), Color(1.0, 0.76, 0.30))
	MeshBuilder3D.build_lantern_post(open_world_root, hub + Vector3(3.8, 0.0, 11.2), Color(1.0, 0.76, 0.30))

	# Рунический круг и Каменные Врата Испытаний (вход в подземелья)
	var rune_disc: CylinderMesh = CylinderMesh.new()
	rune_disc.top_radius = 2.1
	rune_disc.bottom_radius = 2.2
	rune_disc.height = 0.05
	_add_mesh(open_world_root, rune_disc, MeshBuilder3D.make_toon_mat(Color(0.24, 0.56, 0.96), null, Color(0.24, 0.62, 1.0), 1.0, 0.6), hub + Vector3(8.6, 0.08, -1.6))
	_build_portal_arch(open_world_root, hub + Vector3(8.6, 0.0, -1.6), Color(0.32, 0.72, 1.0))

func _place_ground_pos(x: float, z: float) -> Vector3:
	return Vector3(x, GameData.get_terrain_height(x, z), z)

func _build_world_outposts_and_roads() -> void:
	# 1. Заставы и полевые лагеря с кострами и домиками по всему миру (там же дежурят полевые НПС!)
	var camps: Array = [
		[Vector2(106.0, 160.0), 0.4, Color(0.25, 0.50, 0.85)],
		[Vector2(124.0, 322.0), -0.6, Color(0.75, 0.25, 0.22)],
		[Vector2(282.0, 354.0), 0.2, Color(0.45, 0.30, 0.68)],
		[Vector2(236.0, 342.0), 1.1, Color(0.28, 0.55, 0.48)],
		[Vector2(444.0, 186.0), -0.4, Color(0.84, 0.42, 0.16)],
		[Vector2(496.0, 232.0), 0.8, Color(0.76, 0.20, 0.18)],
		[Vector2(284.0, 74.0), -0.3, Color(0.30, 0.72, 0.95)],
		[Vector2(272.0, 138.0), 0.5, Color(0.32, 0.62, 0.90)],
		[Vector2(482.0, 138.0), 0.1, Color(0.55, 0.88, 0.30)],
		[Vector2(556.0, 136.0), -0.7, Color(0.88, 0.72, 0.24)],
		[Vector2(596.0, 342.0), 0.9, Color(0.95, 0.32, 0.12)],
		[Vector2(542.0, 386.0), -0.5, Color(0.86, 0.20, 0.42)]
	]
	for cp in camps:
		var pt: Vector2 = cp[0]
		MeshBuilder3D.build_outpost_camp(open_world_root, _place_ground_pos(pt.x, pt.y), float(cp[1]), cp[2])

	# 2. Хутора, дозорные башни и фермы вдоль дорог
	var cottages: Array = [
		[Vector2(92.0, 212.0), 0.3, Color(0.66, 0.22, 0.18)],
		[Vector2(142.0, 238.0), -0.9, Color(0.55, 0.26, 0.16)],
		[Vector2(126.0, 286.0), 0.7, Color(0.62, 0.20, 0.18)],
		[Vector2(262.0, 288.0), -0.4, Color(0.28, 0.30, 0.38)],
		[Vector2(328.0, 266.0), 0.5, Color(0.30, 0.28, 0.36)],
		[Vector2(478.0, 152.0), 0.2, Color(0.34, 0.36, 0.26)],
		[Vector2(226.0, 114.0), -0.6, Color(0.32, 0.46, 0.64)]
	]
	for ct in cottages:
		var pt: Vector2 = ct[0]
		MeshBuilder3D.build_cottage(open_world_root, _place_ground_pos(pt.x, pt.y), float(ct[1]), ct[2])

	# 3. Придорожные сторожевые вышки и древние руины
	var ruins: Array = [
		[Vector2(174.0, 190.0), 0.5, Color(0.45, 0.44, 0.48)],
		[Vector2(322.0, 336.0), -0.4, Color(0.30, 0.32, 0.38)],
		[Vector2(438.0, 282.0), 0.9, Color(0.56, 0.36, 0.24)],
		[Vector2(246.0, 62.0), 0.2, Color(0.48, 0.56, 0.68)],
		[Vector2(522.0, 84.0), -0.8, Color(0.34, 0.38, 0.30)],
		[Vector2(574.0, 372.0), 0.4, Color(0.24, 0.16, 0.18)]
	]
	for rn in ruins:
		var pt: Vector2 = rn[0]
		MeshBuilder3D.build_ruin_arch(open_world_root, _place_ground_pos(pt.x, pt.y), float(rn[1]), rn[2])

	# 4. Причал и лодка в Бухте Корсаров + дозорные башни у переправ
	MeshBuilder3D.build_wooden_dock(open_world_root, Vector3(92.0, GameData.WATER_Y + 0.12, 344.0), -0.35)
	MeshBuilder3D.build_watchtower(open_world_root, _place_ground_pos(184.0, 240.0), Color(0.38, 0.24, 0.14), Color(0.24, 0.48, 0.85))
	MeshBuilder3D.build_watchtower(open_world_root, _place_ground_pos(512.0, 298.0), Color(0.40, 0.22, 0.14), Color(0.82, 0.22, 0.16))

	# 5. Фонари вдоль главных трактов
	for chain in GameData.ROAD_CHAINS:
		for i in range(chain.size()):
			if i % 2 == 0:
				var p: Vector2 = chain[i]
				if GameData.is_land(p.x, p.y):
					var offset_p: Vector2 = p + Vector2(3.6, 2.2)
					if GameData.is_land(offset_p.x, offset_p.y):
						MeshBuilder3D.build_lantern_post(open_world_root, _place_ground_pos(offset_p.x, offset_p.y), Color(1.0, 0.72, 0.25))

func _build_portal_arch(parent: Node3D, pos: Vector3, col: Color) -> void:
	var st_mat: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.32, 0.34, 0.38))
	var pil: CylinderMesh = CylinderMesh.new()
	pil.top_radius = 0.26
	pil.bottom_radius = 0.32
	pil.height = 3.2
	pil.radial_segments = 6
	_add_mesh(parent, pil, st_mat, pos + Vector3(-1.1, 1.6, 0))
	_add_mesh(parent, pil, st_mat, pos + Vector3(1.1, 1.6, 0))
	var top: BoxMesh = BoxMesh.new()
	top.size = Vector3(2.8, 0.45, 0.65)
	_add_mesh(parent, top, st_mat, pos + Vector3(0, 3.3, 0))

	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.85
	ring.outer_radius = 1.05
	var rmi: MeshInstance3D = _add_mesh(parent, ring, MeshBuilder3D.make_ink_mat(col, null, col, 2.0), pos + Vector3(0, 1.65, 0), Vector3(90, 0, 0))
	portal_rings.append(rmi)

	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.88
	disc.bottom_radius = 0.88
	disc.height = 0.06
	_add_mesh(parent, disc, MeshBuilder3D.make_toon_mat(col, null, col, 1.4, 0.55), pos + Vector3(0, 1.65, 0), Vector3(90, 0, 0))

func _build_boss_arena(bpos_raw: Vector3) -> void:
	var by: float = GameData.get_terrain_height(bpos_raw.x, bpos_raw.z)
	var bpos: Vector3 = Vector3(bpos_raw.x, by, bpos_raw.z)

	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 8.4
	ring.outer_radius = 8.9
	_add_mesh(open_world_root, ring, MeshBuilder3D.make_toon_mat(Color(0.88, 0.18, 0.14), null, Color(0.85, 0.15, 0.1), 1.0, 0.75), bpos + Vector3(0, 0.10, 0))

	var pil: CylinderMesh = CylinderMesh.new()
	pil.top_radius = 0.45
	pil.bottom_radius = 0.58
	pil.height = 4.2
	pil.radial_segments = 6
	var pmat: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.24, 0.22, 0.26))
	for i in range(6):
		var a: float = float(i) * TAU / 6.0
		var p: Vector3 = bpos + Vector3(cos(a) * 9.2, 2.1, sin(a) * 9.2)
		_add_mesh(open_world_root, pil, pmat, p)

func _build_landmark(pos_raw: Vector3, lid: String, decor: String) -> void:
	var ly: float = GameData.get_terrain_height(pos_raw.x, pos_raw.z)
	var pos: Vector3 = Vector3(pos_raw.x, ly, pos_raw.z)
	if lid == "lm_mine":
		MeshBuilder3D.build_mine_entrance(open_world_root, pos)
		return
	elif lid in ["lm_grave", "lm_crypt", "lm_cult"]:
		MeshBuilder3D.build_crypt(open_world_root, pos)
		return
	elif lid in ["lm_orcfort", "lm_defias", "lm_legion"]:
		MeshBuilder3D.build_orc_fort(open_world_root, pos)
		return

	var stone_m: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.34, 0.32, 0.36))
	var wood_m: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.42, 0.26, 0.14))
	var banner_c: Color = Color(0.75, 0.22, 0.18)
	if decor == "darkforest" or decor == "plague":
		banner_c = Color(0.45, 0.24, 0.68)
	elif decor == "snow":
		banner_c = Color(0.28, 0.72, 0.96)
	var ban_m: ShaderMaterial = MeshBuilder3D.make_ink_mat(banner_c)

	var col_m: CylinderMesh = CylinderMesh.new()
	col_m.top_radius = 0.32
	col_m.bottom_radius = 0.42
	col_m.height = 3.2
	col_m.radial_segments = 6
	for ox in [-3.5, 3.5]:
		_add_mesh(open_world_root, col_m, stone_m, pos + Vector3(ox, 1.6, -2.5))
	var flag_pole: BoxMesh = BoxMesh.new()
	flag_pole.size = Vector3(0.16, 3.6, 0.16)
	_add_mesh(open_world_root, flag_pole, wood_m, pos + Vector3(0, 1.8, -3.5))
	var flag: BoxMesh = BoxMesh.new()
	flag.size = Vector3(1.4, 0.9, 0.08)
	_add_mesh(open_world_root, flag, ban_m, pos + Vector3(0.7, 3.0, -3.5))

func _build_biome_prop(pos: Vector3, decor: String, h: int) -> void:
	match decor:
		"forest":
			var trunk: CylinderMesh = CylinderMesh.new()
			trunk.top_radius = 0.18
			trunk.bottom_radius = 0.34
			trunk.height = 2.2
			trunk.radial_segments = 6
			_add_mesh(open_world_root, trunk, MeshBuilder3D.make_ink_mat(Color(0.38, 0.24, 0.14)), pos + Vector3(0, 1.1, 0))
			var c_col: Color = Color(0.14, 0.48 + float(h % 3) * 0.06, 0.18)
			var crown1: PrismMesh = PrismMesh.new()
			crown1.size = Vector3(2.6, 2.2, 2.6)
			_add_mesh(open_world_root, crown1, MeshBuilder3D.make_ink_mat(c_col), pos + Vector3(0, 2.6, 0), Vector3(0, float(h % 90), 0))
			var crown2: PrismMesh = PrismMesh.new()
			crown2.size = Vector3(1.8, 1.8, 1.8)
			_add_mesh(open_world_root, crown2, MeshBuilder3D.make_ink_mat(c_col.lightened(0.14)), pos + Vector3(0, 3.6, 0), Vector3(0, float(h % 90) + 45.0, 0))
		"darkforest":
			if h % 3 == 0:
				var tomb: BoxMesh = BoxMesh.new()
				tomb.size = Vector3(0.75, 1.5, 0.28)
				_add_mesh(open_world_root, tomb, MeshBuilder3D.make_ink_mat(Color(0.28, 0.30, 0.34)), pos + Vector3(0, 0.75, 0), Vector3(0, float(h % 45), 6))
			else:
				var dt: CylinderMesh = CylinderMesh.new()
				dt.top_radius = 0.12
				dt.bottom_radius = 0.28
				dt.height = 2.6
				dt.radial_segments = 5
				_add_mesh(open_world_root, dt, MeshBuilder3D.make_ink_mat(Color(0.18, 0.16, 0.20)), pos + Vector3(0, 1.3, 0))
				var dc: PrismMesh = PrismMesh.new()
				dc.size = Vector3(2.2, 2.0, 2.2)
				_add_mesh(open_world_root, dc, MeshBuilder3D.make_ink_mat(Color(0.10, 0.24, 0.28)), pos + Vector3(0, 2.8, 0))
		"desert":
			if h % 2 == 0:
				var rock: PrismMesh = PrismMesh.new()
				rock.size = Vector3(2.4, 1.8, 2.0)
				_add_mesh(open_world_root, rock, MeshBuilder3D.make_ink_mat(Color(0.62, 0.34, 0.20)), pos + Vector3(0, 0.9, 0), Vector3(0, float(h % 180), 0))
			else:
				var cac: BoxMesh = BoxMesh.new()
				cac.size = Vector3(0.44, 2.1, 0.44)
				var cmat: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.24, 0.58, 0.24))
				_add_mesh(open_world_root, cac, cmat, pos + Vector3(0, 1.05, 0))
				var arm: BoxMesh = BoxMesh.new()
				arm.size = Vector3(0.32, 0.9, 0.32)
				_add_mesh(open_world_root, arm, cmat, pos + Vector3(0.34, 1.25, 0), Vector3(0, 0, -45))
		"snow":
			if h % 3 == 0:
				var crys: CylinderMesh = CylinderMesh.new()
				crys.top_radius = 0.05
				crys.bottom_radius = 0.45
				crys.height = 2.4
				crys.radial_segments = 5
				_add_mesh(open_world_root, crys, MeshBuilder3D.make_ink_mat(Color(0.45, 0.85, 1.0), null, Color(0.35, 0.82, 1.0), 1.2), pos + Vector3(0, 1.2, 0), Vector3(8, 0, -10))
			else:
				var pine: PrismMesh = PrismMesh.new()
				pine.size = Vector3(2.2, 2.9, 2.2)
				_add_mesh(open_world_root, pine, MeshBuilder3D.make_ink_mat(Color(0.18, 0.40, 0.38)), pos + Vector3(0, 1.45, 0))
				var cap: PrismMesh = PrismMesh.new()
				cap.size = Vector3(1.3, 1.4, 1.3)
				_add_mesh(open_world_root, cap, MeshBuilder3D.make_ink_mat(Color(0.92, 0.96, 1.0)), pos + Vector3(0, 2.35, 0))
		"plague":
			if h % 2 == 0:
				var pot: CylinderMesh = CylinderMesh.new()
				pot.top_radius = 0.62
				pot.bottom_radius = 0.48
				pot.height = 0.85
				pot.radial_segments = 6
				_add_mesh(open_world_root, pot, MeshBuilder3D.make_ink_mat(Color(0.22, 0.24, 0.22)), pos + Vector3(0, 0.42, 0))
				var ooze: CylinderMesh = CylinderMesh.new()
				ooze.top_radius = 0.52
				ooze.bottom_radius = 0.52
				ooze.height = 0.1
				ooze.radial_segments = 6
				_add_mesh(open_world_root, ooze, MeshBuilder3D.make_ink_mat(Color(0.48, 0.96, 0.2), null, Color(0.45, 0.95, 0.15), 1.8), pos + Vector3(0, 0.85, 0))
			else:
				var ob: CylinderMesh = CylinderMesh.new()
				ob.top_radius = 0.16
				ob.bottom_radius = 0.45
				ob.height = 2.8
				ob.radial_segments = 5
				_add_mesh(open_world_root, ob, MeshBuilder3D.make_ink_mat(Color(0.22, 0.26, 0.22), null, Color(0.32, 0.65, 0.12), 0.5), pos + Vector3(0, 1.4, 0))
		"volcano":
			if h % 2 == 0:
				var lava: CylinderMesh = CylinderMesh.new()
				lava.top_radius = 1.5
				lava.bottom_radius = 1.5
				lava.height = 0.08
				lava.radial_segments = 6
				_add_mesh(open_world_root, lava, MeshBuilder3D.make_ink_mat(Color(1.0, 0.38, 0.06), null, Color(1.0, 0.42, 0.05), 1.8), pos + Vector3(0, 0.04, 0))
			else:
				var sp: CylinderMesh = CylinderMesh.new()
				sp.top_radius = 0.06
				sp.bottom_radius = 0.68
				sp.height = 2.8
				sp.radial_segments = 5
				_add_mesh(open_world_root, sp, MeshBuilder3D.make_ink_mat(Color(0.14, 0.12, 0.16)), pos + Vector3(0, 1.4, 0))

func enter_instance(dng: Dictionary) -> void:
	in_instance = true
	current_instance = dng
	open_world_root.visible = false
	for c in instance_root.get_children():
		c.queue_free()
	instance_root.visible = true

	var floor_col: Color = dng["floor"]
	var wall_col: Color = dng["wall"]
	var light_col: Color = dng["light"]

	env_res.ambient_light_color = light_col.lerp(Color(0.25, 0.24, 0.28), 0.65)
	sun_light.light_color = light_col
	env_res.fog_light_color = wall_col

	var fp: PlaneMesh = PlaneMesh.new()
	fp.size = Vector2(28.0, 68.0)
	var fmat: StandardMaterial3D = _make_tex_mat(PixelArt.ground_textures["dungeon"], 14.0, floor_col * 1.9)
	_add_mesh(instance_root, fp, fmat, Vector3(0.0, 0.0, -24.0))

	var carpet: PlaneMesh = PlaneMesh.new()
	carpet.size = Vector2(3.6, 56.0)
	var ccol: Color = Color(0.65, 0.14, 0.14) if not bool(dng["is_raid"]) else Color(0.65, 0.38, 0.10)
	_add_mesh(instance_root, carpet, MeshBuilder3D.make_toon_mat(ccol), Vector3(0.0, 0.03, -24.0))

	var wmat: ShaderMaterial = MeshBuilder3D.make_ink_mat(wall_col)
	var side_w: BoxMesh = BoxMesh.new()
	side_w.size = Vector3(2.0, 5.2, 68.0)
	_add_mesh(instance_root, side_w, wmat, Vector3(-14.0, 2.6, -24.0))
	_add_mesh(instance_root, side_w, wmat, Vector3(14.0, 2.6, -24.0))
	var end_w: BoxMesh = BoxMesh.new()
	end_w.size = Vector3(30.0, 5.2, 2.0)
	_add_mesh(instance_root, end_w, wmat, Vector3(0.0, 2.6, 10.0))
	_add_mesh(instance_root, end_w, wmat, Vector3(0.0, 2.6, -58.0))

	var pil: CylinderMesh = CylinderMesh.new()
	pil.top_radius = 0.55
	pil.bottom_radius = 0.65
	pil.height = 4.6
	pil.radial_segments = 6
	for z_off in [0.0, -14.0, -28.0, -42.0]:
		for sx in [-8.5, 8.5]:
			_add_mesh(instance_root, pil, wmat, Vector3(sx, 2.3, z_off))
			var sconce: PrismMesh = PrismMesh.new()
			sconce.size = Vector3(0.45, 0.55, 0.45)
			_add_mesh(instance_root, sconce, MeshBuilder3D.make_ink_mat(light_col, null, light_col, 2.5), Vector3(sx * 0.88, 2.6, z_off))
		var tl: OmniLight3D = OmniLight3D.new()
		tl.light_color = light_col
		tl.light_energy = 2.6
		tl.omni_range = 18.0
		tl.position = Vector3(0.0, 4.2, z_off)
		instance_root.add_child(tl)

	var altar: CylinderMesh = CylinderMesh.new()
	altar.top_radius = 5.8
	altar.bottom_radius = 6.5
	altar.height = 0.28
	_add_mesh(instance_root, altar, MeshBuilder3D.make_ink_mat(light_col.darkened(0.4)), Vector3(0.0, 0.14, -48.0))

	var did: String = str(dng["id"])
	if did == "molten_core":
		var lava_p: PlaneMesh = PlaneMesh.new()
		lava_p.size = Vector2(4.2, 58.0)
		var lmat: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(1.0, 0.36, 0.05), null, Color(1.0, 0.38, 0.04), 2.0)
		_add_mesh(instance_root, lava_p, lmat, Vector3(-11.2, 0.06, -24.0))
		_add_mesh(instance_root, lava_p, lmat, Vector3(11.2, 0.06, -24.0))
	elif did == "icecrown":
		var spire: CylinderMesh = CylinderMesh.new()
		spire.top_radius = 0.06
		spire.bottom_radius = 0.72
		spire.height = 3.8
		spire.radial_segments = 5
		var imat: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.42, 0.85, 1.0), null, Color(0.35, 0.82, 1.0), 1.4)
		for iz in [-6.0, -20.0, -34.0, -48.0]:
			_add_mesh(instance_root, spire, imat, Vector3(-11.5, 1.9, iz), Vector3(0, 0, -12))
			_add_mesh(instance_root, spire, imat, Vector3(11.5, 1.9, iz), Vector3(0, 0, 12))
	elif did == "deadmines":
		var beam: BoxMesh = BoxMesh.new()
		beam.size = Vector3(18.0, 0.45, 0.55)
		var w_wood: ShaderMaterial = MeshBuilder3D.make_ink_mat(Color(0.38, 0.24, 0.14))
		for bz in [-14.0, -28.0, -42.0]:
			_add_mesh(instance_root, beam, w_wood, Vector3(0, 4.4, bz))

	_build_portal_arch(instance_root, Vector3(-7.5, 0.0, 5.0), Color(0.35, 0.95, 0.55))

func leave_instance() -> void:
	in_instance = false
	current_instance = {}
	instance_root.visible = false
	for c in instance_root.get_children():
		c.queue_free()
	open_world_root.visible = true
