extends RefCounted

static var _face_cache: Dictionary = {}
static var _armor_cache: Dictionary = {}
static var _ink_shader: Shader = null
static var _white_tex: ImageTexture = null

static func _get_ink_shader() -> Shader:
	if _ink_shader == null:
		_ink_shader = Shader.new()
		_ink_shader.code = """
shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_back;
uniform vec4 albedo_col : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform bool has_tex = false;
uniform vec4 emit_col : source_color = vec4(0.0);
uniform float emit_energy = 0.0;
uniform float rim_ink = 0.26;
void fragment() {
	vec4 c = albedo_col;
	if (has_tex) {
		c *= texture(albedo_tex, UV);
	}
	float ndv = abs(dot(NORMAL, VIEW));
	if (ndv < rim_ink) {
		c.rgb *= 0.24;
	}
	ALBEDO = c.rgb;
	ALPHA = c.a;
	EMISSION = emit_col.rgb * emit_energy;
}
"""
	return _ink_shader

static func make_ink_mat(col: Color, tex: Texture2D = null, emit_col: Color = Color.BLACK, emit_energy: float = 0.0, rim: float = 0.25) -> ShaderMaterial:
	var sm: ShaderMaterial = ShaderMaterial.new()
	sm.shader = _get_ink_shader()
	sm.set_shader_parameter("albedo_col", col)
	if tex != null:
		sm.set_shader_parameter("albedo_tex", tex)
		sm.set_shader_parameter("has_tex", true)
	else:
		sm.set_shader_parameter("has_tex", false)
	sm.set_shader_parameter("emit_col", emit_col)
	sm.set_shader_parameter("emit_energy", emit_energy)
	sm.set_shader_parameter("rim_ink", rim)
	return sm

static func make_toon_mat(col: Color, tex: Texture2D = null, emission_col: Color = Color.BLACK, emission_energy: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.0
	m.roughness = 1.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if tex != null:
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission_col
		m.emission_energy_multiplier = emission_energy
	if alpha < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = alpha
	return m

static func make_mat(col: Color, _metallic: float = 0.0, _roughness: float = 1.0, emission_col: Color = Color.BLACK, emission_energy: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	return make_toon_mat(col, null, emission_col, emission_energy, alpha)

static func _get_face_tex(race_id: String, skin: Color, hair: Color) -> ImageTexture:
	var key: String = race_id + "_" + skin.to_html(false)
	if _face_cache.has(key):
		return _face_cache[key]
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(skin)
	var shade: Color = skin.darkened(0.20)
	var hi: Color = skin.lightened(0.12)
	var eye_c: Color = Color(0.12, 0.16, 0.26)
	if race_id == "elf":
		eye_c = Color(0.32, 0.94, 1.0)
	elif race_id == "undead":
		eye_c = Color(0.35, 1.0, 0.45)
	elif race_id == "orc":
		eye_c = Color(0.98, 0.26, 0.12)

	# Затенение скул и контур волос
	for y in range(16):
		img.set_pixel(0, y, shade)
		img.set_pixel(15, y, shade)
	for y in range(4):
		for x in range(16):
			img.set_pixel(x, y, hair if (y < 3 or x < 3 or x > 12) else hair.lightened(0.12))
	# Нос
	img.set_pixel(7, 8, hi)
	img.set_pixel(8, 8, shade)
	img.set_pixel(7, 9, shade)
	img.set_pixel(8, 9, shade)
	# Брови и глаза
	for x in [3, 4, 5, 10, 11, 12]:
		img.set_pixel(x, 5, hair.darkened(0.25))
		img.set_pixel(x, 6, Color.WHITE if race_id in ["human", "dwarf"] else eye_c)
	img.set_pixel(4, 6, eye_c)
	img.set_pixel(11, 6, eye_c)
	# Борода / клыки / шрамы
	if race_id == "dwarf":
		for y in range(10, 16):
			for x in range(2, 14):
				img.set_pixel(x, y, hair if (x + y) % 3 != 0 else hair.darkened(0.2))
	elif race_id == "orc":
		for x in range(4, 12):
			img.set_pixel(x, 12, skin.darkened(0.42))
		for fy in [10, 11]:
			img.set_pixel(4, fy, Color(0.96, 0.94, 0.82))
			img.set_pixel(11, fy, Color(0.96, 0.94, 0.82))
	elif race_id == "undead":
		for x in range(4, 12):
			img.set_pixel(x, 12, Color(0.10, 0.12, 0.12))
			if x % 2 == 0:
				img.set_pixel(x, 12, Color(0.86, 0.84, 0.74))
	else:
		for x in range(5, 11):
			img.set_pixel(x, 12, skin.darkened(0.32))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_face_cache[key] = tex
	return tex

static func _get_armor_tex(col: Color) -> ImageTexture:
	var key: String = col.to_html(false)
	if _armor_cache.has(key):
		return _armor_cache[key]
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var c: Color = col
			if x == 0 or x == 15 or y == 0 or y == 15:
				c = col.darkened(0.48)
			elif y == 1 or x == 1:
				c = col.lightened(0.24)
			elif (x == 7 or x == 8) and y > 2 and y < 13:
				c = col.lightened(0.36)
			elif y == 11 or y == 12:
				c = col.darkened(0.32)
			elif (x + y * 2) % 5 == 0:
				c = col.darkened(0.12)
			img.set_pixel(x, y, c)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_armor_cache[key] = tex
	return tex

# ==============================================================================
# СКУЛЬПТИНГ ARRAYMESH (АНАТОМИЧЕСКИЕ КОНУСЫ, ТОРС, ГОЛОВА, КРЫЛЬЯ, КЛИНКИ!)
# ==============================================================================
static func _sculpt_tapered(r_bot: float, r_mid: float, r_top: float, h: float, segs: int = 8) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = [
		[-h * 0.5, r_bot, 1.0],
		[0.0, r_mid, 0.5],
		[h * 0.5, r_top, 0.0]
	]
	for ri in range(rings.size() - 1):
		var y0: float = float(rings[ri][0])
		var rad0: float = float(rings[ri][1])
		var v0: float = float(rings[ri][2])
		var y1: float = float(rings[ri + 1][0])
		var rad1: float = float(rings[ri + 1][1])
		var v1: float = float(rings[ri + 1][2])
		for s in range(segs):
			var a0: float = float(s) * TAU / float(segs)
			var a1: float = float(s + 1) * TAU / float(segs)
			var u0: float = float(s) / float(segs)
			var u1: float = float(s + 1) / float(segs)
			var p00 := Vector3(cos(a0) * rad0, y0, sin(a0) * rad0)
			var p10 := Vector3(cos(a1) * rad0, y0, sin(a1) * rad0)
			var p01 := Vector3(cos(a0) * rad1, y1, sin(a0) * rad1)
			var p11 := Vector3(cos(a1) * rad1, y1, sin(a1) * rad1)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(p01)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(p10)
	# Крышки сверху и снизу
	for s in range(segs):
		var a0: float = float(s) * TAU / float(segs)
		var a1: float = float(s + 1) * TAU / float(segs)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(0, h * 0.5, 0))
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(cos(a1) * r_top, h * 0.5, sin(a1) * r_top))
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(cos(a0) * r_top, h * 0.5, sin(a0) * r_top))
		st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(Vector3(0, -h * 0.5, 0))
		st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(Vector3(cos(a0) * r_bot, -h * 0.5, sin(a0) * r_bot))
		st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(Vector3(cos(a1) * r_bot, -h * 0.5, sin(a1) * r_bot))
	st.generate_normals()
	return st.commit()

static func _sculpt_torso(w_waist: float, w_chest: float, d_waist: float, d_chest: float, h: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 8
	var y0: float = -h * 0.5
	var y1: float = h * 0.5
	for s in range(segs):
		var a0: float = float(s) * TAU / float(segs)
		var a1: float = float(s + 1) * TAU / float(segs)
		var u0: float = float(s) / float(segs)
		var u1: float = float(s + 1) / float(segs)
		var p00 := Vector3(cos(a0) * w_waist, y0, sin(a0) * d_waist)
		var p10 := Vector3(cos(a1) * w_waist, y0, sin(a1) * d_waist)
		var p01 := Vector3(cos(a0) * w_chest, y1, sin(a0) * d_chest)
		var p11 := Vector3(cos(a1) * w_chest, y1, sin(a1) * d_chest)
		st.set_uv(Vector2(u0, 1.0)); st.add_vertex(p00)
		st.set_uv(Vector2(u0, 0.0)); st.add_vertex(p01)
		st.set_uv(Vector2(u1, 0.0)); st.add_vertex(p11)
		st.set_uv(Vector2(u0, 1.0)); st.add_vertex(p00)
		st.set_uv(Vector2(u1, 0.0)); st.add_vertex(p11)
		st.set_uv(Vector2(u1, 1.0)); st.add_vertex(p10)
	for s in range(segs):
		var a0: float = float(s) * TAU / float(segs)
		var a1: float = float(s + 1) * TAU / float(segs)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(0, y1, 0))
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(cos(a1) * w_chest, y1, sin(a1) * d_chest))
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(cos(a0) * w_chest, y1, sin(a0) * d_chest))
	st.generate_normals()
	return st.commit()

static func _sculpt_head(w_jaw: float, w_brow: float, h: float) -> ArrayMesh:
	# Скульптурная голова со скулами и скошенным подбородком
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 8
	var y0: float = -h * 0.5
	var y_m: float = 0.05
	var y1: float = h * 0.5
	var levels: Array = [[y0, w_jaw], [y_m, w_brow], [y1, w_brow * 0.86]]
	for li in range(2):
		var ya: float = float(levels[li][0]); var ra: float = float(levels[li][1])
		var yb: float = float(levels[li + 1][0]); var rb: float = float(levels[li + 1][1])
		for s in range(segs):
			var a0: float = float(s) * TAU / float(segs)
			var a1: float = float(s + 1) * TAU / float(segs)
			var p00 := Vector3(cos(a0) * ra, ya, sin(a0) * ra * 0.95)
			var p10 := Vector3(cos(a1) * ra, ya, sin(a1) * ra * 0.95)
			var p01 := Vector3(cos(a0) * rb, yb, sin(a0) * rb * 0.95)
			var p11 := Vector3(cos(a1) * rb, yb, sin(a1) * rb * 0.95)
			st.add_vertex(p00); st.add_vertex(p01); st.add_vertex(p11)
			st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p10)
	for s in range(segs):
		var a0: float = float(s) * TAU / float(segs)
		var a1: float = float(s + 1) * TAU / float(segs)
		var rt: float = w_brow * 0.86
		st.add_vertex(Vector3(0, y1, 0))
		st.add_vertex(Vector3(cos(a1) * rt, y1, sin(a1) * rt * 0.95))
		st.add_vertex(Vector3(cos(a0) * rt, y1, sin(a0) * rt * 0.95))
	st.generate_normals()
	return st.commit()

static func _sculpt_sword_blade(w: float, h: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var b_l := Vector3(-w * 0.5, 0, 0)
	var b_r := Vector3(w * 0.5, 0, 0)
	var b_f := Vector3(0, 0, w * 0.35)
	var b_b := Vector3(0, 0, -w * 0.35)
	var m_l := Vector3(-w * 0.38, h * 0.72, 0)
	var m_r := Vector3(w * 0.38, h * 0.72, 0)
	var m_f := Vector3(0, h * 0.72, w * 0.28)
	var m_b := Vector3(0, h * 0.72, -w * 0.28)
	var tip := Vector3(0, h, 0)
	var tris: Array = [
		[b_l, m_l, m_f], [b_l, m_f, b_f],
		[b_f, m_f, m_r], [b_f, m_r, b_r],
		[b_r, m_r, m_b], [b_r, m_b, b_b],
		[b_b, m_b, m_l], [b_b, m_l, b_l],
		[m_l, tip, m_f], [m_f, tip, m_r],
		[m_r, tip, m_b], [m_b, tip, m_l]
	]
	for t in tris:
		st.add_vertex(t[0]); st.add_vertex(t[1]); st.add_vertex(t[2])
	st.generate_normals()
	return st.commit()

static func _sculpt_wing(span: float, height: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var root := Vector3(0, 0, 0)
	var top1 := Vector3(span * 0.45, height * 0.65, 0.08)
	var tip := Vector3(span, height * 0.25, -0.10)
	var mid := Vector3(span * 0.65, -height * 0.45, -0.06)
	var bot := Vector3(span * 0.22, -height * 0.55, 0.0)
	for t in [[root, top1, mid], [top1, tip, mid], [root, mid, bot]]:
		st.add_vertex(t[0]); st.add_vertex(t[1]); st.add_vertex(t[2])
		st.add_vertex(t[0]); st.add_vertex(t[2]); st.add_vertex(t[1])
	st.generate_normals()
	return st.commit()

static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi

static func _cyl(rt: float, rb: float, h: float, seg: int = 6) -> CylinderMesh:
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = seg
	return m

static func _box(sx: float, sy: float, sz: float) -> BoxMesh:
	var m: BoxMesh = BoxMesh.new()
	m.size = Vector3(sx, sy, sz)
	return m

static func _prism(sx: float, sy: float, sz: float) -> PrismMesh:
	var m: PrismMesh = PrismMesh.new()
	m.size = Vector3(sx, sy, sz)
	return m

static func _torus(ri: float, ro: float) -> TorusMesh:
	var m: TorusMesh = TorusMesh.new()
	m.inner_radius = ri
	m.outer_radius = ro
	m.rings = 10
	m.ring_segments = 4
	return m

# ==============================================================================
# 5 УНИКАЛЬНЫХ РАС x 8 КЛАССОВ (СКУЛЬПТУРНЫЙ 2.5D PIXEL-INK СТИЛЬ!)
# ==============================================================================
static func build_character_rig(cls_id: String, cls_col: Color, scale_mult: float = 1.0, gear_tier: int = 0, race_id: String = "human") -> Dictionary:
	var rdata: Dictionary = GameData.RACES.get(race_id, GameData.RACES["human"])
	var root: Node3D = Node3D.new()
	root.scale = Vector3.ONE * scale_mult

	var body_pivot: Node3D = Node3D.new()
	body_pivot.scale = rdata["scale"]
	root.add_child(body_pivot)

	var skin_col: Color = rdata["skin"]
	var hair_col: Color = rdata["hair"]
	var face_tex: ImageTexture = _get_face_tex(race_id, skin_col, hair_col)
	var armor_tex: ImageTexture = _get_armor_tex(cls_col)

	var skin_mat: ShaderMaterial = make_ink_mat(skin_col)
	var face_mat: ShaderMaterial = make_ink_mat(Color.WHITE, face_tex, Color.BLACK, 0.0, 0.0)
	var hair_mat: ShaderMaterial = make_ink_mat(hair_col)
	var armor_mat: ShaderMaterial = make_ink_mat(Color.WHITE, armor_tex)
	var cloth_mat: ShaderMaterial = make_ink_mat(cls_col.darkened(0.36))
	var leather_mat: ShaderMaterial = make_ink_mat(Color(0.34, 0.21, 0.12))
	var dark_mat: ShaderMaterial = make_ink_mat(Color(0.16, 0.15, 0.19))
	var metal_mat: ShaderMaterial = make_ink_mat(Color(0.72, 0.77, 0.85))
	var gold_mat: ShaderMaterial = make_ink_mat(Color(0.94, 0.74, 0.22))
	var glow_col: Color = cls_col.lightened(0.25)
	var rune_mat: ShaderMaterial = make_ink_mat(glow_col, null, glow_col, 1.3 + float(gear_tier) * 0.3)

	_add(root, _cyl(0.58, 0.58, 0.03, 10), make_toon_mat(Color(0.02, 0.02, 0.03), null, Color.BLACK, 0.0, 0.52), Vector3(0, 0.02, 0))

	# Скульптурные ноги (бедро -> наколенник -> раструб сапога + подошва!)
	var thigh_m: ArrayMesh = _sculpt_tapered(0.10, 0.13, 0.14, 0.34, 7)
	var boot_m: ArrayMesh = _sculpt_tapered(0.13, 0.10, 0.15, 0.28, 7)
	var left_leg: Node3D = Node3D.new()
	left_leg.position = Vector3(-0.17, 0.62, 0)
	body_pivot.add_child(left_leg)
	_add(left_leg, thigh_m, dark_mat, Vector3(0, -0.17, 0))
	_add(left_leg, _box(0.16, 0.10, 0.16), metal_mat, Vector3(0, -0.28, 0.04))
	_add(left_leg, boot_m, leather_mat, Vector3(0, -0.45, 0.03))

	var right_leg: Node3D = Node3D.new()
	right_leg.position = Vector3(0.17, 0.62, 0)
	body_pivot.add_child(right_leg)
	_add(right_leg, thigh_m, dark_mat, Vector3(0, -0.17, 0))
	_add(right_leg, _box(0.16, 0.10, 0.16), metal_mat, Vector3(0, -0.28, 0.04))
	_add(right_leg, boot_m, leather_mat, Vector3(0, -0.45, 0.03))

	# Табард / расклешенная туника + ворот-горжет
	_add(body_pivot, _sculpt_tapered(0.37, 0.31, 0.26, 0.30, 8), cloth_mat, Vector3(0, 0.62, 0))
	_add(body_pivot, _box(0.22, 0.36, 0.06), gold_mat if cls_id in ["paladin", "priest"] else cloth_mat, Vector3(0, 0.56, 0.26))
	_add(body_pivot, _cyl(0.20, 0.26, 0.08, 8), metal_mat, Vector3(0, 1.35, 0))

	# Героический V-образный торс + пояс с пряжкой и сумкой
	var torso_mi: MeshInstance3D = _add(body_pivot, _sculpt_torso(0.25, 0.39, 0.19, 0.27, 0.66), armor_mat, Vector3(0, 1.02, 0))
	_add(body_pivot, _sculpt_tapered(0.27, 0.26, 0.27, 0.12, 8), leather_mat, Vector3(0, 0.72, 0))
	_add(body_pivot, _box(0.18, 0.15, 0.07), gold_mat, Vector3(0, 0.72, 0.23))
	_add(body_pivot, _box(0.11, 0.14, 0.12), leather_mat, Vector3(-0.27, 0.70, 0.06))

	if race_id == "undead":
		var bone_m: ShaderMaterial = make_ink_mat(Color(0.86, 0.84, 0.74))
		for ry in [0.92, 1.04, 1.16]:
			_add(body_pivot, _sculpt_tapered(0.28, 0.29, 0.28, 0.04, 8), bone_m, Vector3(0, ry, 0.04))

	# Плащ
	var cape_mi: MeshInstance3D = _add(body_pivot, _prism(0.68, 1.06, 0.05), cloth_mat, Vector3(0, 0.86, -0.27), Vector3(14, 0, 0))
	_add(cape_mi, _box(0.66, 0.07, 0.06), gold_mat, Vector3(0, -0.46, 0))

	# Скульптурная голова со скулами + лицевая пиксель-текстура
	var head_mi: MeshInstance3D = _add(body_pivot, _sculpt_head(0.17, 0.24, 0.44), skin_mat, Vector3(0, 1.57, 0))
	var face_quad: QuadMesh = QuadMesh.new()
	face_quad.size = Vector2(0.36, 0.36)
	_add(head_mi, face_quad, face_mat, Vector3(0, 0.01, 0.23))

	if race_id == "elf":
		_add(head_mi, _prism(0.07, 0.34, 0.07), skin_mat, Vector3(-0.28, 0.05, 0.0), Vector3(-15, 0, 72))
		_add(head_mi, _prism(0.07, 0.34, 0.07), skin_mat, Vector3(0.28, 0.05, 0.0), Vector3(-15, 0, -72))
		_add(head_mi, _sculpt_tapered(0.25, 0.23, 0.16, 0.22, 8), hair_mat, Vector3(0, 0.16, -0.02))
	elif race_id == "orc":
		var tusk_m: ShaderMaterial = make_ink_mat(Color(0.96, 0.94, 0.82))
		_add(head_mi, _sculpt_tapered(0.22, 0.24, 0.20, 0.16, 8), skin_mat, Vector3(0, -0.14, 0.04))
		_add(head_mi, _prism(0.06, 0.18, 0.06), tusk_m, Vector3(-0.13, -0.05, 0.24), Vector3(18, 0, 0))
		_add(head_mi, _prism(0.06, 0.18, 0.06), tusk_m, Vector3(0.13, -0.05, 0.24), Vector3(18, 0, 0))
	elif race_id == "dwarf":
		_add(head_mi, _prism(0.42, 0.48, 0.22), hair_mat, Vector3(0, -0.26, 0.20), Vector3(180, 0, 0))
		_add(head_mi, _box(0.14, 0.12, 0.12), skin_mat, Vector3(0, -0.02, 0.23))

	var helm_mi: MeshInstance3D
	if cls_id in ["mage", "warlock"]:
		helm_mi = _add(body_pivot, _sculpt_tapered(0.35, 0.18, 0.04, 0.56, 8), armor_mat, Vector3(0, 1.92, -0.02), Vector3(-10, 0, 0))
		_add(helm_mi, _cyl(0.40, 0.42, 0.05, 10), gold_mat, Vector3(0, -0.24, 0))
	elif cls_id in ["ranger", "rogue"]:
		helm_mi = _add(body_pivot, _sculpt_tapered(0.26, 0.22, 0.06, 0.38, 8), cloth_mat, Vector3(0, 1.76, -0.02))
		if cls_id == "ranger":
			_add(helm_mi, _prism(0.06, 0.28, 0.04), gold_mat, Vector3(0.20, 0.14, -0.08), Vector3(-20, 0, -25))
			var quiv: MeshInstance3D = _add(body_pivot, _sculpt_tapered(0.07, 0.09, 0.10, 0.58, 6), leather_mat, Vector3(-0.18, 1.12, -0.28), Vector3(12, 0, -24))
			for ax in [-0.03, 0.0, 0.03]:
				_add(quiv, _cyl(0.015, 0.015, 0.22, 4), gold_mat, Vector3(ax, 0.36, ax))
	elif cls_id in ["paladin", "priest"]:
		helm_mi = _add(body_pivot, _sculpt_tapered(0.24, 0.25, 0.27, 0.18, 8), gold_mat, Vector3(0, 1.80, 0))
		_add(body_pivot, _torus(0.26, 0.31), rune_mat, Vector3(0, 1.82, -0.10), Vector3(72, 0, 0))
	else:
		helm_mi = _add(body_pivot, _sculpt_tapered(0.27, 0.26, 0.20, 0.28, 8), metal_mat, Vector3(0, 1.74, 0))
		_add(helm_mi, _prism(0.08, 0.32, 0.08), gold_mat, Vector3(-0.26, 0.12, 0), Vector3(0, 0, 38))
		_add(helm_mi, _prism(0.08, 0.32, 0.08), gold_mat, Vector3(0.26, 0.12, 0), Vector3(0, 0, -38))

	# Скульптурные изогнутые наплечники
	var sh_m: Material = gold_mat if cls_id in ["paladin", "priest"] else (metal_mat if cls_id in ["warrior", "shaman"] else cloth_mat)
	var pauld: ArrayMesh = _sculpt_tapered(0.22, 0.20, 0.10, 0.24, 7)
	var sh_l: MeshInstance3D = _add(body_pivot, pauld, sh_m, Vector3(-0.42, 1.32, 0), Vector3(0, 0, 24))
	var sh_r: MeshInstance3D = _add(body_pivot, pauld, sh_m, Vector3(0.42, 1.32, 0), Vector3(0, 0, -24))
	if cls_id in ["warrior", "warlock"] or race_id == "orc":
		_add(sh_l, _prism(0.08, 0.26, 0.08), gold_mat, Vector3(-0.08, 0.14, 0), Vector3(0, 0, 22))
		_add(sh_r, _prism(0.08, 0.26, 0.08), gold_mat, Vector3(0.08, 0.14, 0), Vector3(0, 0, -22))

	# Конические руки с наручами и латными перчатками
	var arm_m: ArrayMesh = _sculpt_tapered(0.09, 0.11, 0.10, 0.46, 7)
	var left_arm: Node3D = Node3D.new()
	left_arm.position = Vector3(-0.40, 1.20, 0)
	body_pivot.add_child(left_arm)
	_add(left_arm, arm_m, armor_mat, Vector3(0, -0.20, 0))
	_add(left_arm, _cyl(0.10, 0.09, 0.14, 6), metal_mat, Vector3(0, -0.38, 0.02))

	var right_arm: Node3D = Node3D.new()
	right_arm.position = Vector3(0.40, 1.20, 0)
	body_pivot.add_child(right_arm)
	_add(right_arm, arm_m, armor_mat, Vector3(0, -0.20, 0))
	_add(right_arm, _cyl(0.10, 0.09, 0.14, 6), metal_mat, Vector3(0, -0.38, 0.02))

	var weapon_mi: MeshInstance3D = null
	var shield_mi: MeshInstance3D = null
	var orbiters: Array = []

	match cls_id:
		"mage", "priest", "warlock":
			weapon_mi = _add(right_arm, _sculpt_tapered(0.03, 0.04, 0.05, 1.72, 6), leather_mat, Vector3(0, -0.18, 0.30), Vector3(70, 0, 0))
			_add(weapon_mi, _torus(0.15, 0.20), gold_mat, Vector3(0, 0.86, 0), Vector3(0, 0, 90))
			var orb: MeshInstance3D = _add(weapon_mi, _prism(0.20, 0.28, 0.20), rune_mat, Vector3(0, 0.86, 0))
			orbiters.append(orb)
			var orb_f: MeshInstance3D = _add(body_pivot, _prism(0.14, 0.28, 0.14), rune_mat, Vector3(-0.56, 1.62, -0.1))
			orbiters.append(orb_f)
		"ranger":
			weapon_mi = _add(left_arm, _torus(0.42, 0.48), leather_mat, Vector3(0, -0.26, 0.34), Vector3(0, 0, 90))
			_add(weapon_mi, _cyl(0.015, 0.015, 0.88, 4), gold_mat, Vector3(0, 0, 0))
		"rogue":
			weapon_mi = _add(right_arm, _sculpt_sword_blade(0.12, 0.72), metal_mat, Vector3(0, -0.28, 0.32), Vector3(78, 0, 0))
			_add(weapon_mi, _box(0.20, 0.05, 0.07), rune_mat, Vector3(0, 0.02, 0))
			var off_d: MeshInstance3D = _add(left_arm, _sculpt_sword_blade(0.12, 0.66), metal_mat, Vector3(0, -0.28, 0.30), Vector3(78, 0, 0))
			_add(off_d, _box(0.20, 0.05, 0.07), rune_mat, Vector3(0, 0.02, 0))
		"shaman":
			weapon_mi = _add(right_arm, _sculpt_tapered(0.04, 0.05, 0.05, 1.15, 6), leather_mat, Vector3(0, -0.24, 0.34), Vector3(72, 0, 0))
			_add(weapon_mi, _prism(0.34, 0.44, 0.12), rune_mat, Vector3(0, 0.46, 0.10), Vector3(0, 90, 0))
			shield_mi = _add(left_arm, _box(0.48, 0.56, 0.08), leather_mat, Vector3(-0.10, -0.24, 0.22), Vector3(80, 18, 0))
			_add(shield_mi, _box(0.22, 0.36, 0.10), rune_mat, Vector3(0, 0, 0.02))
		"paladin":
			weapon_mi = _add(right_arm, _sculpt_tapered(0.04, 0.05, 0.05, 1.25, 6), gold_mat, Vector3(0, -0.26, 0.36), Vector3(72, 0, 0))
			_add(weapon_mi, _box(0.48, 0.30, 0.30), gold_mat, Vector3(0, 0.56, 0))
			_add(weapon_mi, _prism(0.18, 0.26, 0.18), rune_mat, Vector3(0, 0.80, 0))
			shield_mi = _add(left_arm, _box(0.54, 0.70, 0.08), gold_mat, Vector3(-0.10, -0.26, 0.24), Vector3(78, 20, 0))
			_add(shield_mi, _box(0.40, 0.54, 0.09), metal_mat, Vector3(0, 0, 0.01))
			_add(shield_mi, _box(0.12, 0.42, 0.11), rune_mat, Vector3(0, 0, 0.02))
		_:
			weapon_mi = _add(right_arm, _sculpt_sword_blade(0.20, 1.38), metal_mat, Vector3(0, -0.28, 0.32), Vector3(76, 0, 0))
			_add(weapon_mi, _box(0.42, 0.08, 0.12), gold_mat, Vector3(0, 0.04, 0))
			shield_mi = _add(left_arm, _cyl(0.36, 0.32, 0.08, 8), metal_mat, Vector3(-0.10, -0.26, 0.22), Vector3(85, 0, 15))
			_add(shield_mi, _cyl(0.20, 0.20, 0.10, 8), gold_mat, Vector3(0, 0, 0))

	# Скульптурный Боевой Скакун (отдельный поворотный узел mount_pivot, синхронный с игроком!)
	var mount_pivot: Node3D = Node3D.new()
	root.add_child(mount_pivot)
	var mount_node: Node3D = Node3D.new()
	mount_node.visible = false
	mount_pivot.add_child(mount_node)
	var horse_mat: ShaderMaterial = make_ink_mat(Color(0.38, 0.22, 0.14))
	var hoof_mat: ShaderMaterial = make_ink_mat(Color(0.12, 0.10, 0.12))
	# Тело, попона и бронированный нагрудник
	_add(mount_node, _sculpt_torso(0.32, 0.36, 0.72, 0.80, 0.58), horse_mat, Vector3(0, 0.78, 0))
	_add(mount_node, _box(0.76, 0.42, 0.76), cloth_mat, Vector3(0, 0.82, -0.02))
	_add(mount_node, _box(0.78, 0.08, 0.78), gold_mat, Vector3(0, 0.63, -0.02))
	_add(mount_node, _box(0.42, 0.16, 0.48), leather_mat, Vector3(0, 1.08, 0.02))
	_add(mount_node, _box(0.44, 0.18, 0.10), gold_mat, Vector3(0, 1.16, 0.24))
	# Нагрудная броня и шея с гривой
	_add(mount_node, _sculpt_tapered(0.30, 0.34, 0.24, 0.32, 8), metal_mat, Vector3(0, 0.82, 0.76), Vector3(45, 0, 0))
	_add(mount_node, _sculpt_tapered(0.24, 0.20, 0.15, 0.74, 7), horse_mat, Vector3(0, 1.18, 0.68), Vector3(26, 0, 0))
	for mi in range(4):
		_add(mount_node, _prism(0.10, 0.20, 0.18), dark_mat, Vector3(0, 1.08 + float(mi) * 0.12, 0.48 + float(mi) * 0.08), Vector3(-20, 0, 0))
	# Голова, морда, уши и золотая уздечка
	_add(mount_node, _sculpt_tapered(0.17, 0.15, 0.09, 0.56, 6), horse_mat, Vector3(0, 1.42, 0.96), Vector3(72, 0, 0))
	_add(mount_node, _box(0.24, 0.16, 0.14), metal_mat, Vector3(0, 1.48, 0.90), Vector3(22, 0, 0))
	_add(mount_node, _prism(0.06, 0.14, 0.06), horse_mat, Vector3(-0.09, 1.60, 0.84))
	_add(mount_node, _prism(0.06, 0.14, 0.06), horse_mat, Vector3(0.09, 1.60, 0.84))
	_add(mount_node, _box(0.05, 0.05, 0.05), rune_mat, Vector3(-0.12, 1.47, 1.00))
	_add(mount_node, _box(0.05, 0.05, 0.05), rune_mat, Vector3(0.12, 1.47, 1.00))
	# Пышный хвост
	_add(mount_node, _sculpt_tapered(0.08, 0.13, 0.04, 0.68, 6), dark_mat, Vector3(0, 0.74, -0.84), Vector3(-28, 0, 0))

	var mount_legs: Array = []
	var hleg_m: ArrayMesh = _sculpt_tapered(0.08, 0.10, 0.11, 0.64, 6)
	for lx in [-0.23, 0.23]:
		for lz in [-0.52, 0.50]:
			var hlp: Node3D = Node3D.new()
			hlp.position = Vector3(lx, 0.64, lz)
			mount_node.add_child(hlp)
			_add(hlp, hleg_m, horse_mat, Vector3(0, -0.32, 0))
			_add(hlp, _cyl(0.09, 0.10, 0.10, 6), hoof_mat, Vector3(0, -0.60, 0))
			mount_legs.append(hlp)

	var ring_mi: MeshInstance3D = _add(root, _torus(0.66, 0.76), make_toon_mat(cls_col, null, cls_col, 1.4, 0.85), Vector3(0, 0.05, 0))
	ring_mi.visible = false

	return {
		"root": root, "body_pivot": body_pivot, "mount_pivot": mount_pivot, "torso": torso_mi, "cape": cape_mi,
		"helm": helm_mi, "sh_l": sh_l, "sh_r": sh_r,
		"left_arm": left_arm, "right_arm": right_arm, "left_leg": left_leg, "right_leg": right_leg,
		"weapon": weapon_mi, "shield": shield_mi, "mount": mount_node, "mount_legs": mount_legs,
		"aura_ring": ring_mi, "orbiters": orbiters
	}

static func build_pet_wolf(is_imp: bool = false) -> Dictionary:
	var root: Node3D = Node3D.new()
	var body_pivot: Node3D = Node3D.new()
	root.add_child(body_pivot)
	_add(root, _cyl(0.40, 0.40, 0.03, 8), make_toon_mat(Color(0, 0, 0), null, Color.BLACK, 0, 0.42), Vector3(0, 0.02, 0))

	if is_imp:
		var imp_m: ShaderMaterial = make_ink_mat(Color(0.88, 0.22, 0.18))
		var horn_m: ShaderMaterial = make_ink_mat(Color(0.95, 0.85, 0.35))
		var fire_m: ShaderMaterial = make_ink_mat(Color(1.0, 0.52, 0.10), null, Color(1.0, 0.45, 0.05), 2.0)
		_add(body_pivot, _sculpt_torso(0.14, 0.22, 0.12, 0.18, 0.48), imp_m, Vector3(0, 0.68, 0))
		_add(body_pivot, _sculpt_head(0.14, 0.18, 0.32), imp_m, Vector3(0, 1.08, 0.04))
		_add(body_pivot, _prism(0.08, 0.24, 0.08), horn_m, Vector3(-0.14, 1.32, 0), Vector3(0, 0, 22))
		_add(body_pivot, _prism(0.08, 0.24, 0.08), horn_m, Vector3(0.14, 1.32, 0), Vector3(0, 0, -22))
		_add(body_pivot, _prism(0.18, 0.24, 0.18), fire_m, Vector3(0.28, 0.85, 0.22))
		return {"root": root, "body_pivot": body_pivot}

	var fur_mat: ShaderMaterial = make_ink_mat(Color(0.42, 0.46, 0.54))
	var mane_mat: ShaderMaterial = make_ink_mat(Color(0.22, 0.25, 0.32))
	var eye_mat: ShaderMaterial = make_ink_mat(Color(0.4, 1.0, 0.5), null, Color(0.4, 1.0, 0.5), 2.0)
	_add(body_pivot, _sculpt_tapered(0.20, 0.24, 0.22, 0.86, 7), fur_mat, Vector3(0, 0.48, 0), Vector3(90, 0, 0))
	_add(body_pivot, _sculpt_tapered(0.26, 0.28, 0.20, 0.40, 7), mane_mat, Vector3(0, 0.54, 0.24), Vector3(70, 0, 0))
	_add(body_pivot, _sculpt_head(0.16, 0.19, 0.32), fur_mat, Vector3(0, 0.64, 0.46))
	_add(body_pivot, _sculpt_tapered(0.12, 0.10, 0.07, 0.26, 6), mane_mat, Vector3(0, 0.58, 0.68), Vector3(90, 0, 0))
	_add(body_pivot, _prism(0.08, 0.16, 0.06), mane_mat, Vector3(-0.11, 0.84, 0.42))
	_add(body_pivot, _prism(0.08, 0.16, 0.06), mane_mat, Vector3(0.11, 0.84, 0.42))
	_add(body_pivot, _box(0.06, 0.06, 0.04), eye_mat, Vector3(-0.08, 0.68, 0.64))
	_add(body_pivot, _box(0.06, 0.06, 0.04), eye_mat, Vector3(0.08, 0.68, 0.64))
	var wleg: ArrayMesh = _sculpt_tapered(0.05, 0.07, 0.08, 0.42, 6)
	for lx in [-0.15, 0.15]:
		for lz in [-0.30, 0.28]:
			_add(body_pivot, wleg, mane_mat, Vector3(lx, 0.21, lz))
	return {"root": root, "body_pivot": body_pivot}

# ==============================================================================
# СКУЛЬПТУРНЫЕ 3D МОДЕЛИ МОНСТРОВ И РЕЙД-БОССОВ
# ==============================================================================
static func build_mob_rig(shape_type: String, col: Color, is_boss: bool) -> Dictionary:
	var root: Node3D = Node3D.new()
	var body_pivot: Node3D = Node3D.new()
	root.add_child(body_pivot)

	var scale_mult: float = 2.0 if is_boss else 1.0
	body_pivot.scale = Vector3.ONE * scale_mult

	var main_mat: ShaderMaterial = make_ink_mat(col)
	var dark_mat: ShaderMaterial = make_ink_mat(col.darkened(0.45))
	var light_mat: ShaderMaterial = make_ink_mat(col.lightened(0.28))
	var eye_mat: ShaderMaterial = make_ink_mat(Color(1.0, 0.28, 0.15), null, Color(1.0, 0.25, 0.1), 2.2)
	var bone_mat: ShaderMaterial = make_ink_mat(Color(0.88, 0.85, 0.76))
	var metal_mat: ShaderMaterial = make_ink_mat(Color(0.70, 0.74, 0.82))
	var gold_mat: ShaderMaterial = make_ink_mat(Color(0.96, 0.76, 0.22))

	var orbiters: Array = []
	var wings: Array = []

	_add(root, _cyl(0.64 * scale_mult, 0.64 * scale_mult, 0.04, 10), make_toon_mat(Color(0, 0, 0), null, Color.BLACK, 0.0, 0.46), Vector3(0, 0.02, 0))

	match shape_type:
		"beast":
			_add(body_pivot, _sculpt_tapered(0.24, 0.30, 0.26, 1.08, 8), main_mat, Vector3(0, 0.56, 0), Vector3(90, 0, 0))
			_add(body_pivot, _sculpt_tapered(0.32, 0.34, 0.24, 0.46, 8), dark_mat, Vector3(0, 0.64, 0.28), Vector3(72, 0, 0))
			_add(body_pivot, _sculpt_head(0.18, 0.22, 0.38), main_mat, Vector3(0, 0.74, 0.56))
			_add(body_pivot, _sculpt_tapered(0.14, 0.12, 0.08, 0.28, 6), dark_mat, Vector3(0, 0.70, 0.78), Vector3(90, 0, 0))
			_add(body_pivot, _prism(0.10, 0.22, 0.08), dark_mat, Vector3(-0.14, 0.98, 0.52))
			_add(body_pivot, _prism(0.10, 0.22, 0.08), dark_mat, Vector3(0.14, 0.98, 0.52))
			_add(body_pivot, _box(0.07, 0.07, 0.04), eye_mat, Vector3(-0.10, 0.80, 0.76))
			_add(body_pivot, _box(0.07, 0.07, 0.04), eye_mat, Vector3(0.10, 0.80, 0.76))
			var bleg: ArrayMesh = _sculpt_tapered(0.06, 0.08, 0.10, 0.50, 6)
			for lx in [-0.18, 0.18]:
				for lz in [-0.36, 0.36]:
					_add(body_pivot, bleg, dark_mat, Vector3(lx, 0.25, lz))
		"kobold":
			_add(body_pivot, _sculpt_torso(0.20, 0.26, 0.16, 0.20, 0.62), main_mat, Vector3(0, 0.58, 0), Vector3(18, 0, 0))
			_add(body_pivot, _box(0.36, 0.40, 0.24), dark_mat, Vector3(0, 0.70, -0.24))
			_add(body_pivot, _sculpt_head(0.15, 0.20, 0.36), main_mat, Vector3(0, 1.06, 0.12))
			_add(body_pivot, _prism(0.08, 0.22, 0.08), main_mat, Vector3(-0.24, 1.12, 0.10), Vector3(0, 0, 62))
			_add(body_pivot, _prism(0.08, 0.22, 0.08), main_mat, Vector3(0.24, 1.12, 0.10), Vector3(0, 0, -62))
			_add(body_pivot, _box(0.06, 0.06, 0.04), eye_mat, Vector3(-0.08, 1.08, 0.30))
			_add(body_pivot, _box(0.06, 0.06, 0.04), eye_mat, Vector3(0.08, 1.08, 0.30))
			_add(body_pivot, _cyl(0.03, 0.03, 0.95, 5), dark_mat, Vector3(0.32, 0.75, 0.25), Vector3(62, 0, 0))
			_add(body_pivot, _box(0.45, 0.07, 0.07), metal_mat, Vector3(0.32, 0.98, 0.62), Vector3(0, 20, 0))
			_add(body_pivot, _cyl(0.06, 0.07, 0.26, 6), make_ink_mat(Color(0.96, 0.92, 0.78)), Vector3(0, 1.36, 0.12))
			_add(body_pivot, _prism(0.14, 0.20, 0.14), make_ink_mat(Color(1.0, 0.76, 0.2), null, Color(1.0, 0.65, 0.1), 2.8), Vector3(0, 1.54, 0.12))
		"scorpid":
			_add(body_pivot, _sculpt_torso(0.34, 0.28, 0.42, 0.36, 0.32), main_mat, Vector3(0, 0.36, 0))
			for sx in [-1.0, 1.0]:
				_add(body_pivot, _sculpt_tapered(0.07, 0.09, 0.08, 0.44, 6), main_mat, Vector3(sx * 0.38, 0.36, 0.38), Vector3(90, sx * -22, 0))
				_add(body_pivot, _prism(0.22, 0.26, 0.22), dark_mat, Vector3(sx * 0.48, 0.36, 0.62), Vector3(90, 0, 0))
			for i in range(5):
				var t_ang: float = float(i) * 0.38
				_add(body_pivot, _sculpt_tapered(0.11 - float(i) * 0.01, 0.12, 0.10, 0.18, 6), dark_mat if i % 2 == 0 else main_mat, Vector3(0, 0.48 + sin(t_ang) * 0.65, -0.38 + float(i) * 0.12))
			_add(body_pivot, _prism(0.10, 0.28, 0.10), make_ink_mat(Color(0.35, 1.0, 0.2), null, Color(0.3, 1.0, 0.2), 1.8), Vector3(0, 1.24, 0.18), Vector3(58, 0, 0))
		"undead":
			_add(body_pivot, _cyl(0.05, 0.05, 0.72, 6), bone_mat, Vector3(0, 0.88, 0))
			for ry in [0.76, 0.90, 1.04]:
				_add(body_pivot, _sculpt_torso(0.22, 0.24, 0.14, 0.16, 0.06), bone_mat, Vector3(0, ry, 0))
			_add(body_pivot, _sculpt_tapered(0.18, 0.20, 0.16, 0.16, 6), bone_mat, Vector3(0, 0.62, 0))
			var bleg2: ArrayMesh = _sculpt_tapered(0.05, 0.05, 0.06, 0.56, 6)
			_add(body_pivot, bleg2, bone_mat, Vector3(-0.14, 0.32, 0))
			_add(body_pivot, bleg2, bone_mat, Vector3(0.14, 0.32, 0))
			_add(body_pivot, _sculpt_head(0.15, 0.21, 0.38), bone_mat, Vector3(0, 1.42, 0))
			var ue: ShaderMaterial = make_ink_mat(Color(0.3, 1.0, 0.45), null, Color(0.3, 1.0, 0.4), 2.4)
			_add(body_pivot, _box(0.08, 0.08, 0.04), ue, Vector3(-0.09, 1.44, 0.19))
			_add(body_pivot, _box(0.08, 0.08, 0.04), ue, Vector3(0.09, 1.44, 0.19))
			_add(body_pivot, _sculpt_sword_blade(0.14, 1.05), metal_mat, Vector3(0.36, 0.95, 0.30), Vector3(68, 0, 0))
			_add(body_pivot, _cyl(0.30, 0.28, 0.06, 8), dark_mat, Vector3(-0.34, 0.92, 0.14), Vector3(85, 0, 15))
		"elemental":
			var emat: ShaderMaterial = make_ink_mat(col, null, col, 1.5)
			var core: MeshInstance3D = _add(body_pivot, _prism(0.55, 0.92, 0.55), emat, Vector3(0, 1.15, 0))
			orbiters.append(core)
			var r1: MeshInstance3D = _add(body_pivot, _torus(0.46, 0.56), emat, Vector3(0, 1.10, 0), Vector3(28, 0, 18))
			var r2: MeshInstance3D = _add(body_pivot, _torus(0.46, 0.56), emat, Vector3(0, 1.10, 0), Vector3(-35, 0, -25))
			orbiters.append(r1)
			orbiters.append(r2)
			for i in range(4):
				var a: float = float(i) * TAU / 4.0
				var shard: MeshInstance3D = _add(body_pivot, _prism(0.18, 0.44, 0.18), light_mat, Vector3(cos(a) * 0.65, 1.15, sin(a) * 0.65))
				orbiters.append(shard)
		"dragon":
			_add(body_pivot, _sculpt_tapered(0.32, 0.44, 0.36, 1.50, 8), main_mat, Vector3(0, 1.05, 0), Vector3(72, 0, 0))
			_add(body_pivot, _sculpt_tapered(0.24, 0.20, 0.16, 0.85, 8), main_mat, Vector3(0, 1.48, 0.62), Vector3(48, 0, 0))
			_add(body_pivot, _sculpt_head(0.18, 0.26, 0.46), dark_mat, Vector3(0, 1.72, 1.05), Vector3(72, 0, 0))
			_add(body_pivot, _prism(0.10, 0.46, 0.10), bone_mat, Vector3(-0.16, 1.98, 0.88), Vector3(-35, 0, 18))
			_add(body_pivot, _prism(0.10, 0.46, 0.10), bone_mat, Vector3(0.16, 1.98, 0.88), Vector3(-35, 0, -18))
			_add(body_pivot, _sculpt_tapered(0.04, 0.12, 0.20, 1.15, 6), dark_mat, Vector3(0, 0.68, -0.95), Vector3(-62, 0, 0))
			var wmesh: ArrayMesh = _sculpt_wing(1.65, 0.95)
			for sx in [-1.0, 1.0]:
				var wp: Node3D = Node3D.new()
				wp.position = Vector3(sx * 0.34, 1.38, 0.08)
				body_pivot.add_child(wp)
				_add(wp, wmesh, dark_mat, Vector3.ZERO, Vector3.ZERO, Vector3(sx, 1.0, 1.0))
				wings.append(wp)
			var de: ShaderMaterial = make_ink_mat(Color(0.4, 0.92, 1.0), null, Color(0.4, 0.92, 1.0), 2.8)
			_add(body_pivot, _box(0.08, 0.08, 0.04), de, Vector3(-0.11, 1.78, 1.38))
			_add(body_pivot, _box(0.08, 0.08, 0.04), de, Vector3(0.11, 1.78, 1.38))
		"ragnaros":
			var lava_mat: ShaderMaterial = make_ink_mat(Color(1.0, 0.38, 0.06), null, Color(1.0, 0.45, 0.05), 2.2)
			var obs_mat: ShaderMaterial = make_ink_mat(Color(0.20, 0.12, 0.14))
			var vx: MeshInstance3D = _add(body_pivot, _sculpt_tapered(0.24, 0.48, 0.66, 1.32, 8), lava_mat, Vector3(0, 0.68, 0))
			orbiters.append(vx)
			_add(body_pivot, _sculpt_torso(0.38, 0.54, 0.28, 0.36, 1.05), obs_mat, Vector3(0, 1.54, 0))
			_add(body_pivot, _sculpt_tapered(0.28, 0.24, 0.14, 0.42, 7), lava_mat, Vector3(-0.56, 1.78, 0))
			_add(body_pivot, _sculpt_tapered(0.28, 0.24, 0.14, 0.42, 7), lava_mat, Vector3(0.56, 1.78, 0))
			_add(body_pivot, _sculpt_head(0.22, 0.32, 0.48), lava_mat, Vector3(0, 2.20, 0))
			_add(body_pivot, _prism(0.16, 0.58, 0.16), lava_mat, Vector3(-0.28, 2.52, 0), Vector3(0, 0, 22))
			_add(body_pivot, _prism(0.16, 0.58, 0.16), lava_mat, Vector3(0.28, 2.52, 0), Vector3(0, 0, -22))
			var ham: MeshInstance3D = _add(body_pivot, _cyl(0.07, 0.07, 2.15, 6), obs_mat, Vector3(0.64, 1.48, 0.42), Vector3(58, 0, 0))
			_add(ham, _box(0.62, 0.56, 0.72), lava_mat, Vector3(0, 0.96, 0))
		"lichking":
			var armor_lk: ShaderMaterial = make_ink_mat(Color(0.18, 0.22, 0.32))
			var ice_lk: ShaderMaterial = make_ink_mat(Color(0.35, 0.86, 1.0), null, Color(0.35, 0.86, 1.0), 2.4)
			_add(body_pivot, _sculpt_torso(0.30, 0.44, 0.22, 0.30, 1.12), armor_lk, Vector3(0, 1.06, 0))
			_add(body_pivot, _prism(0.78, 1.25, 0.08), make_ink_mat(Color(0.10, 0.12, 0.20)), Vector3(0, 0.98, -0.34), Vector3(14, 0, 0))
			_add(body_pivot, _sculpt_head(0.18, 0.24, 0.44), armor_lk, Vector3(0, 1.80, 0))
			_add(body_pivot, _sculpt_tapered(0.24, 0.22, 0.12, 0.32, 7), armor_lk, Vector3(-0.48, 1.42, 0))
			_add(body_pivot, _sculpt_tapered(0.24, 0.22, 0.12, 0.32, 7), armor_lk, Vector3(0.48, 1.42, 0))
			_add(body_pivot, _prism(0.14, 0.54, 0.14), ice_lk, Vector3(-0.24, 2.12, 0), Vector3(0, 0, 24))
			_add(body_pivot, _prism(0.14, 0.54, 0.14), ice_lk, Vector3(0.24, 2.12, 0), Vector3(0, 0, -24))
			_add(body_pivot, _sculpt_sword_blade(0.22, 1.65), ice_lk, Vector3(0.54, 1.18, 0.30), Vector3(68, 0, 0))
		_:
			_add(body_pivot, _sculpt_torso(0.24, 0.36, 0.18, 0.25, 0.84), main_mat, Vector3(0, 0.94, 0))
			_add(body_pivot, _sculpt_tapered(0.26, 0.25, 0.26, 0.14, 8), dark_mat, Vector3(0, 0.72, 0))
			_add(body_pivot, _sculpt_head(0.17, 0.23, 0.42), dark_mat, Vector3(0, 1.56, 0))
			_add(body_pivot, _sculpt_tapered(0.20, 0.18, 0.10, 0.24, 7), metal_mat, Vector3(-0.40, 1.28, 0))
			_add(body_pivot, _sculpt_tapered(0.20, 0.18, 0.10, 0.24, 7), metal_mat, Vector3(0.40, 1.28, 0))
			_add(body_pivot, _box(0.07, 0.07, 0.04), eye_mat, Vector3(-0.08, 1.58, 0.22))
			_add(body_pivot, _box(0.07, 0.07, 0.04), eye_mat, Vector3(0.08, 1.58, 0.22))
			var wpn: MeshInstance3D = _add(body_pivot, _sculpt_sword_blade(0.20, 1.15), metal_mat, Vector3(0.40, 1.05, 0.26), Vector3(66, 0, 0))
			_add(wpn, _box(0.36, 0.06, 0.10), gold_mat, Vector3(0, 0.04, 0))
			if is_boss:
				_add(body_pivot, _prism(0.10, 0.36, 0.10), gold_mat, Vector3(-0.22, 1.78, 0), Vector3(0, 0, 32))
				_add(body_pivot, _prism(0.10, 0.36, 0.10), gold_mat, Vector3(0.22, 1.78, 0), Vector3(0, 0, -32))

	if is_boss:
		_add(root, _torus(1.30, 1.48), make_toon_mat(Color(1.0, 0.22, 0.16), null, Color(1.0, 0.22, 0.15), 1.6, 0.85), Vector3(0, 0.06, 0))

	return {"root": root, "body_pivot": body_pivot, "orbiters": orbiters, "wings": wings}

# ==============================================================================
# ЭПИЧЕСКАЯ АРХИТЕКТУРА ГОРОДОВ, МОСТОВ И ОРИЕНТИРОВ
# ==============================================================================
static func build_abbey_keep(parent: Node3D, pos: Vector3, wall_col: Color, roof_col: Color, banner_col: Color) -> void:
	var stone_m: ShaderMaterial = make_ink_mat(wall_col)
	var trim_m: ShaderMaterial = make_ink_mat(wall_col.darkened(0.25))
	var roof_m: ShaderMaterial = make_ink_mat(roof_col)
	var wood_m: ShaderMaterial = make_ink_mat(Color(0.36, 0.22, 0.12))
	var win_m: ShaderMaterial = make_ink_mat(Color(1.0, 0.85, 0.35), null, Color(1.0, 0.78, 0.28), 2.2)
	var ban_m: ShaderMaterial = make_ink_mat(banner_col)

	# Главный зал крепости/аббатства
	_add(parent, _box(6.2, 3.2, 4.8), stone_m, pos + Vector3(0, 1.6, 0))
	_add(parent, _prism(6.8, 2.4, 5.4), roof_m, pos + Vector3(0, 4.4, 0))
	# Башня со шпилем сбоку
	_add(parent, _box(2.4, 6.2, 2.4), trim_m, pos + Vector3(-2.6, 3.1, 1.6))
	_add(parent, _prism(2.8, 2.8, 2.8), roof_m, pos + Vector3(-2.6, 7.6, 1.6))
	# Ворота, окна и знамена
	_add(parent, _box(1.4, 2.0, 0.25), wood_m, pos + Vector3(0.6, 1.0, 2.42))
	_add(parent, _box(0.8, 1.1, 0.16), win_m, pos + Vector3(-2.6, 4.4, 2.82))
	_add(parent, _box(0.9, 1.1, 0.16), win_m, pos + Vector3(1.8, 2.1, 2.42))
	_add(parent, _box(0.8, 1.8, 0.08), ban_m, pos + Vector3(-0.8, 2.1, 2.46))
	_add(parent, _box(0.8, 1.8, 0.08), ban_m, pos + Vector3(2.0, 2.1, 2.46))

static func build_tavern(parent: Node3D, pos: Vector3) -> void:
	var stone_mat: ShaderMaterial = make_ink_mat(Color(0.36, 0.35, 0.38))
	var wood_mat: ShaderMaterial = make_ink_mat(Color(0.38, 0.23, 0.14))
	var plaster_mat: ShaderMaterial = make_ink_mat(Color(0.54, 0.44, 0.34))
	var roof_mat: ShaderMaterial = make_ink_mat(Color(0.66, 0.20, 0.16))
	var win_mat: ShaderMaterial = make_ink_mat(Color(1.0, 0.84, 0.35), null, Color(1.0, 0.78, 0.28), 2.2)

	_add(parent, _box(4.6, 1.1, 4.4), stone_mat, pos + Vector3(0, 0.55, 0))
	_add(parent, _box(4.2, 2.0, 4.0), plaster_mat, pos + Vector3(0, 2.1, 0))
	for cx in [-2.05, 2.05]:
		for cz in [-1.95, 1.95]:
			_add(parent, _box(0.24, 2.2, 0.24), wood_mat, pos + Vector3(cx, 2.1, cz))
	_add(parent, _prism(5.0, 2.2, 4.8), roof_mat, pos + Vector3(0, 4.15, 0))
	_add(parent, _box(0.72, 2.0, 0.72), stone_mat, pos + Vector3(-1.1, 4.6, -0.8))
	_add(parent, _box(0.92, 1.50, 0.15), wood_mat, pos + Vector3(0, 0.85, 2.08))
	_add(parent, _box(0.75, 0.75, 0.12), win_mat, pos + Vector3(-1.1, 2.1, 2.02))
	_add(parent, _box(0.75, 0.75, 0.12), win_mat, pos + Vector3(1.1, 2.1, 2.02))
	_add(parent, _box(0.75, 0.75, 0.12), win_mat, pos + Vector3(2.12, 2.1, 0))
	# Бочки у входа в таверну + вывеска трактира
	_add(parent, _cyl(0.32, 0.30, 0.72, 8), wood_mat, pos + Vector3(1.5, 0.36, 2.4))
	_add(parent, _cyl(0.32, 0.30, 0.72, 8), wood_mat, pos + Vector3(-1.4, 0.36, 2.4))
	_add(parent, _box(0.14, 0.14, 0.95), wood_mat, pos + Vector3(0.0, 2.35, 2.45))
	_add(parent, _box(0.68, 0.48, 0.08), win_mat, pos + Vector3(0.0, 1.98, 2.82))

static func build_town_walls_and_gate(parent: Node3D, pos: Vector3, wall_col: Color, banner_col: Color) -> void:
	var wm: ShaderMaterial = make_ink_mat(wall_col)
	var bm: ShaderMaterial = make_ink_mat(banner_col)
	var wood_m: ShaderMaterial = make_ink_mat(Color(0.38, 0.24, 0.14))
	var glow_m: ShaderMaterial = make_ink_mat(Color(1.0, 0.62, 0.14), null, Color(1.0, 0.55, 0.10), 2.2)

	# Угловые каменные бастионы и стены города (открытые проезды по дорогам)
	for sx in [-12.5, 12.5]:
		for sz in [-12.5, 12.5]:
			_add(parent, _cyl(0.95, 1.15, 3.8, 8), wm, pos + Vector3(sx, 1.9, sz))
			_add(parent, _prism(2.1, 1.2, 2.1), bm, pos + Vector3(sx, 4.4, sz))
			_add(parent, _prism(0.45, 0.55, 0.45), glow_m, pos + Vector3(sx, 3.9, sz))
	# Боковые и задние стены с проёмами
	_add(parent, _box(8.5, 2.2, 0.8), wm, pos + Vector3(-7.6, 1.1, 12.5))
	_add(parent, _box(8.5, 2.2, 0.8), wm, pos + Vector3(7.6, 1.1, 12.5))
	_add(parent, _box(8.5, 2.2, 0.8), wm, pos + Vector3(-7.6, 1.1, -12.5))
	_add(parent, _box(8.5, 2.2, 0.8), wm, pos + Vector3(7.6, 1.1, -12.5))
	# Арка южных ворот
	_add(parent, _box(1.1, 3.6, 1.1), wm, pos + Vector3(-3.0, 1.8, 12.5))
	_add(parent, _box(1.1, 3.6, 1.1), wm, pos + Vector3(3.0, 1.8, 12.5))
	_add(parent, _box(7.2, 0.9, 1.2), wm, pos + Vector3(0.0, 3.7, 12.5))
	_add(parent, _box(1.4, 1.8, 0.1), bm, pos + Vector3(0.0, 2.8, 13.15))

	# Торговая лавка с прилавком, навесом и ящиками (рядом с Торговцем!)
	var stall_p: Vector3 = pos + Vector3(3.8, 0.0, 4.5)
	_add(parent, _box(3.2, 1.0, 1.2), wood_m, stall_p + Vector3(0, 0.5, 0))
	_add(parent, _box(0.20, 2.5, 0.20), wood_m, stall_p + Vector3(-1.4, 1.25, -0.45))
	_add(parent, _box(0.20, 2.5, 0.20), wood_m, stall_p + Vector3(1.4, 1.25, -0.45))
	_add(parent, _box(3.5, 0.16, 1.8), bm, stall_p + Vector3(0, 2.45, 0.1), Vector3(16, 0, 0))
	_add(parent, _box(0.75, 0.75, 0.75), wood_m, stall_p + Vector3(-2.1, 0.38, 0.4), Vector3(0, 22, 0))
	_add(parent, _cyl(0.30, 0.30, 0.68, 7), wood_m, stall_p + Vector3(2.0, 0.34, 0.2))

static func build_cottage(parent: Node3D, pos: Vector3, rot_y: float, roof_col: Color) -> void:
	var n: Node3D = Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	var stone_m: ShaderMaterial = make_ink_mat(Color(0.36, 0.34, 0.37))
	var wall_m: ShaderMaterial = make_ink_mat(Color(0.60, 0.52, 0.42))
	var wood_m: ShaderMaterial = make_ink_mat(Color(0.36, 0.22, 0.12))
	var roof_m: ShaderMaterial = make_ink_mat(roof_col)
	var win_m: ShaderMaterial = make_ink_mat(Color(1.0, 0.84, 0.35), null, Color(1.0, 0.76, 0.24), 2.0)
	_add(n, _box(3.4, 0.7, 3.0), stone_m, Vector3(0, 0.35, 0))
	_add(n, _box(3.2, 1.7, 2.8), wall_m, Vector3(0, 1.55, 0))
	_add(n, _prism(3.8, 1.7, 3.4), roof_m, Vector3(0, 3.25, 0))
	_add(n, _box(0.55, 1.5, 0.55), stone_m, Vector3(-0.9, 3.5, -0.6))
	_add(n, _box(0.78, 1.30, 0.14), wood_m, Vector3(0, 0.82, 1.42))
	_add(n, _box(0.62, 0.62, 0.12), win_m, Vector3(-0.88, 1.65, 1.42))
	_add(n, _box(0.62, 0.62, 0.12), win_m, Vector3(0.88, 1.65, 1.42))
	_add(n, _box(0.70, 0.60, 0.70), wood_m, Vector3(1.9, 0.30, 1.0))

static func build_outpost_camp(parent: Node3D, pos: Vector3, rot_y: float, banner_col: Color) -> void:
	var n: Node3D = Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	var tent_m: ShaderMaterial = make_ink_mat(banner_col.darkened(0.20))
	var wood_m: ShaderMaterial = make_ink_mat(Color(0.38, 0.24, 0.14))
	var stone_m: ShaderMaterial = make_ink_mat(Color(0.34, 0.33, 0.36))
	var fire_m: ShaderMaterial = make_ink_mat(Color(1.0, 0.54, 0.12), null, Color(1.0, 0.48, 0.08), 2.5)
	var bm: ShaderMaterial = make_ink_mat(banner_col)
	_add(n, _prism(3.2, 2.1, 3.0), tent_m, Vector3(-1.8, 1.05, -1.6))
	_add(n, _cyl(0.65, 0.72, 0.22, 8), stone_m, Vector3(0.4, 0.11, 0.6))
	_add(n, _cyl(0.05, 0.34, 0.85, 6), fire_m, Vector3(0.4, 0.45, 0.6))
	_add(n, _box(0.8, 0.7, 0.8), wood_m, Vector3(2.0, 0.35, -0.6), Vector3(0, 18, 0))
	_add(n, _box(0.14, 3.4, 0.14), wood_m, Vector3(1.8, 1.7, -1.8))
	_add(n, _box(1.1, 0.75, 0.06), bm, Vector3(2.35, 2.8, -1.8))

static func build_ruin_arch(parent: Node3D, pos: Vector3, rot_y: float, stone_col: Color) -> void:
	var n: Node3D = Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	var sm: ShaderMaterial = make_ink_mat(stone_col)
	var glow_m: ShaderMaterial = make_ink_mat(Color(0.38, 0.85, 0.96), null, Color(0.32, 0.78, 0.96), 1.8)
	_add(n, _box(3.8, 0.30, 2.6), sm, Vector3(0, 0.15, 0))
	_add(n, _cyl(0.38, 0.46, 3.2, 7), sm, Vector3(-1.4, 1.6, 0))
	_add(n, _cyl(0.38, 0.46, 3.2, 7), sm, Vector3(1.4, 1.6, 0))
	_add(n, _box(3.7, 0.62, 0.85), sm, Vector3(0, 3.4, 0))
	_add(n, _prism(0.48, 0.80, 0.48), glow_m, Vector3(0, 0.68, 0.2))

static func build_wooden_dock(parent: Node3D, pos: Vector3, rot_y: float) -> void:
	var n: Node3D = Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	var wm: ShaderMaterial = make_ink_mat(Color(0.42, 0.26, 0.14))
	_add(n, _box(3.2, 0.28, 7.5), wm, Vector3(0, 0.32, 0))
	for px in [-1.3, 1.3]:
		for pz in [-2.8, 0.0, 2.8]:
			_add(n, _cyl(0.18, 0.20, 1.4, 6), wm, Vector3(px, -0.2, pz))
	# Лодка у причала
	_add(n, _box(1.5, 0.55, 2.8), wm, Vector3(2.4, 0.0, 2.0), Vector3(0, 14, 0))

static func build_lantern_post(parent: Node3D, pos: Vector3, glow_col: Color) -> void:
	var wm: ShaderMaterial = make_ink_mat(Color(0.30, 0.20, 0.14))
	var gm: ShaderMaterial = make_ink_mat(glow_col, null, glow_col, 2.4)
	_add(parent, _cyl(0.10, 0.14, 3.1, 6), wm, pos + Vector3(0, 1.55, 0))
	_add(parent, _box(0.75, 0.12, 0.12), wm, pos + Vector3(0.32, 3.02, 0))
	_add(parent, _prism(0.38, 0.46, 0.38), gm, pos + Vector3(0.62, 2.75, 0))

static func build_forge(parent: Node3D, pos: Vector3) -> void:
	var stone_mat: ShaderMaterial = make_ink_mat(Color(0.28, 0.27, 0.30))
	var wood_mat: ShaderMaterial = make_ink_mat(Color(0.36, 0.22, 0.12))
	var iron_mat: ShaderMaterial = make_ink_mat(Color(0.22, 0.24, 0.28))
	var ember_mat: ShaderMaterial = make_ink_mat(Color(1.0, 0.42, 0.08), null, Color(1.0, 0.4, 0.05), 2.5)
	_add(parent, _box(1.8, 1.4, 1.5), stone_mat, pos + Vector3(0, 0.7, 0))
	_add(parent, _box(0.9, 1.5, 0.9), stone_mat, pos + Vector3(-0.3, 2.0, -0.2))
	_add(parent, _prism(0.85, 0.4, 0.85), ember_mat, pos + Vector3(0.2, 1.45, 0.1))
	_add(parent, _box(0.7, 0.48, 0.38), iron_mat, pos + Vector3(1.5, 0.24, 0.6))
	_add(parent, _box(0.95, 0.20, 0.42), iron_mat, pos + Vector3(1.5, 0.56, 0.6))
	_add(parent, _prism(3.2, 1.0, 2.8), wood_mat, pos + Vector3(0.6, 2.7, 0.2))

static func build_watchtower(parent: Node3D, pos: Vector3, wood_col: Color, banner_col: Color) -> void:
	var wm: ShaderMaterial = make_ink_mat(wood_col)
	var bm: ShaderMaterial = make_ink_mat(banner_col)
	for lx in [-0.9, 0.9]:
		for lz in [-0.9, 0.9]:
			_add(parent, _box(0.24, 4.4, 0.24), wm, pos + Vector3(lx, 2.2, lz))
	_add(parent, _box(2.4, 0.35, 2.4), wm, pos + Vector3(0, 3.6, 0))
	_add(parent, _prism(2.8, 1.6, 2.8), bm, pos + Vector3(0, 5.2, 0))

static func build_bridge(parent: Node3D, pos: Vector3, rot_y: float, length: float = 16.0) -> void:
	var b_node: Node3D = Node3D.new()
	b_node.position = pos
	b_node.rotation.y = rot_y
	parent.add_child(b_node)
	var wm: ShaderMaterial = make_ink_mat(Color(0.42, 0.26, 0.14))
	var sm: ShaderMaterial = make_ink_mat(Color(0.32, 0.31, 0.35))
	_add(b_node, _box(4.6, 0.45, length), wm, Vector3(0, 0.18, 0))
	for sx in [-2.15, 2.15]:
		_add(b_node, _box(0.24, 0.85, length), sm, Vector3(sx, 0.65, 0))

static func build_mine_entrance(parent: Node3D, pos: Vector3) -> void:
	var rock_m: ShaderMaterial = make_ink_mat(Color(0.34, 0.30, 0.26))
	var wood_m: ShaderMaterial = make_ink_mat(Color(0.42, 0.26, 0.14))
	var dark_m: ShaderMaterial = make_ink_mat(Color(0.05, 0.04, 0.06))
	var crys_m: ShaderMaterial = make_ink_mat(Color(0.98, 0.78, 0.22), null, Color(1.0, 0.72, 0.18), 1.8)
	_add(parent, _prism(6.5, 4.2, 4.6), rock_m, pos + Vector3(0, 2.1, -2.0))
	_add(parent, _box(2.6, 2.4, 0.6), dark_m, pos + Vector3(0, 1.2, 0.1))
	_add(parent, _box(0.32, 2.6, 0.32), wood_m, pos + Vector3(-1.4, 1.3, 0.3))
	_add(parent, _box(0.32, 2.6, 0.32), wood_m, pos + Vector3(1.4, 1.3, 0.3))
	_add(parent, _box(3.4, 0.36, 0.42), wood_m, pos + Vector3(0, 2.6, 0.3))
	# Вагонетка с золотом
	_add(parent, _box(1.1, 0.75, 1.5), wood_m, pos + Vector3(2.4, 0.45, 2.0), Vector3(0, 28, 0))
	_add(parent, _prism(0.7, 0.5, 0.7), crys_m, pos + Vector3(2.4, 0.9, 2.0))

static func build_orc_fort(parent: Node3D, pos: Vector3) -> void:
	var wood_m: ShaderMaterial = make_ink_mat(Color(0.38, 0.22, 0.12))
	var tent_m: ShaderMaterial = make_ink_mat(Color(0.66, 0.16, 0.12))
	var spike_m: ShaderMaterial = make_ink_mat(Color(0.84, 0.80, 0.70))
	_add(parent, _prism(4.2, 2.8, 3.8), tent_m, pos + Vector3(-2.6, 1.4, -2.0))
	for px in [-4.5, -3.2, 3.2, 4.5]:
		_add(parent, _sculpt_tapered(0.24, 0.20, 0.04, 3.4, 6), wood_m, pos + Vector3(px, 1.7, 1.6))
		_add(parent, _prism(0.18, 0.5, 0.18), spike_m, pos + Vector3(px, 3.4, 1.6))

static func build_crypt(parent: Node3D, pos: Vector3) -> void:
	var stone_m: ShaderMaterial = make_ink_mat(Color(0.24, 0.25, 0.30))
	var rune_m: ShaderMaterial = make_ink_mat(Color(0.45, 0.95, 0.82), null, Color(0.35, 0.95, 0.78), 1.8)
	_add(parent, _box(4.2, 2.6, 4.4), stone_m, pos + Vector3(0, 1.3, -1.5))
	_add(parent, _prism(4.6, 1.8, 4.8), stone_m, pos + Vector3(0, 3.5, -1.5))
	_add(parent, _box(1.4, 1.9, 0.2), rune_m, pos + Vector3(0, 1.0, 0.75))

static func build_chest_mesh(rarity_col: Color) -> Node3D:
	var n: Node3D = Node3D.new()
	var wood_mat: ShaderMaterial = make_ink_mat(Color(0.42, 0.24, 0.12))
	var gold_mat: ShaderMaterial = make_ink_mat(rarity_col, null, rarity_col, 0.8)
	_add(n, _box(0.92, 0.52, 0.62), wood_mat, Vector3(0, 0.26, 0))
	_add(n, _box(0.90, 0.24, 0.58), wood_mat, Vector3(0, 0.62, 0))
	_add(n, _box(0.96, 0.10, 0.66), gold_mat, Vector3(0, 0.50, 0))
	_add(n, _box(0.18, 0.22, 0.12), gold_mat, Vector3(0, 0.44, 0.33))
	return n

static func build_quest_node_mesh(col: Color) -> Node3D:
	var n: Node3D = Node3D.new()
	var m: ShaderMaterial = make_ink_mat(col, null, col, 1.6)
	_add(n, _prism(0.45, 0.85, 0.45), m, Vector3(0, 0.42, 0))
	_add(n, _prism(0.32, 0.55, 0.32), m, Vector3(0.24, 0.28, 0.16), Vector3(18, 25, -22))
	_add(n, _prism(0.30, 0.50, 0.30), m, Vector3(-0.22, 0.25, -0.18), Vector3(-16, -20, 20))
	return n
