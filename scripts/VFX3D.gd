extends Node3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var projectiles: Array = []
var rings: Array = []
var pillars: Array = []
var particles: Array = []
var meteors: Array = []
var float_texts: Array = []

func spawn_text(pos3d: Vector3, txt: String, col: Color, size: int = 15) -> void:
	float_texts.append({
		"pos": pos3d + Vector3(randf_range(-0.4, 0.4), 2.1, randf_range(-0.4, 0.4)),
		"text": txt,
		"col": col,
		"life": 1.15,
		"max_life": 1.15,
		"size": size
	})

func spawn_burst(pos3d: Vector3, col: Color, count: int = 10) -> void:
	var sp: SphereMesh = SphereMesh.new()
	sp.radius = 0.11
	sp.height = 0.22
	var mat: StandardMaterial3D = MeshBuilder3D.make_mat(col, 0, 0.2, col, 2.4)
	for _i in range(count):
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = sp
		mi.material_override = mat
		mi.position = pos3d + Vector3(0, 0.9, 0)
		add_child(mi)
		var vel: Vector3 = Vector3(randf_range(-4.5, 4.5), randf_range(2.2, 6.2), randf_range(-4.5, 4.5))
		particles.append({"node": mi, "vel": vel, "life": 0.48, "max_life": 0.48})

func spawn_meteor(target_pos: Vector3) -> void:
	var sp: SphereMesh = SphereMesh.new()
	sp.radius = 0.85
	sp.height = 1.7
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = sp
	mi.material_override = MeshBuilder3D.make_mat(Color(1.0, 0.42, 0.08), 0, 0.2, Color(1.0, 0.45, 0.05), 3.0)
	mi.position = target_pos + Vector3(3.0, 14.0, 3.0)
	var ol: OmniLight3D = OmniLight3D.new()
	ol.light_color = Color(1.0, 0.45, 0.1)
	ol.light_energy = 3.0
	ol.omni_range = 8.0
	mi.add_child(ol)
	add_child(mi)
	meteors.append({"node": mi, "from": mi.position, "to": target_pos + Vector3(0, 0.4, 0), "t": 0.0})

func spawn_ring(pos3d: Vector3, max_radius: float, col: Color, dur: float = 0.45) -> void:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.78
	torus.outer_radius = 1.0
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = torus
	var mat: StandardMaterial3D = MeshBuilder3D.make_mat(col, 0.0, 0.3, col, 2.0, 0.85)
	mi.material_override = mat
	mi.position = Vector3(pos3d.x, pos3d.y + 0.14, pos3d.z)
	mi.scale = Vector3(0.3, 0.3, 0.3)
	add_child(mi)
	rings.append({"node": mi, "mat": mat, "max_r": max_radius, "life": dur, "max_life": dur})

func spawn_pillar(pos3d: Vector3, col: Color, dur: float = 0.85) -> void:
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 1.1
	cyl.height = 7.0
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = cyl
	var mat: StandardMaterial3D = MeshBuilder3D.make_mat(col, 0.0, 0.2, col, 2.2, 0.65)
	mi.material_override = mat
	mi.position = pos3d + Vector3(0, 3.5, 0)
	add_child(mi)
	pillars.append({"node": mi, "mat": mat, "life": dur, "max_life": dur})

func spawn_proj(from_pos: Vector3, to_pos: Vector3, col: Color, radius: float = 0.22, speed: float = 22.0) -> void:
	var sp: SphereMesh = SphereMesh.new()
	sp.radius = radius
	sp.height = radius * 2.0
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = sp
	mi.material_override = MeshBuilder3D.make_mat(col, 0.0, 0.2, col, 2.5)
	var start: Vector3 = from_pos + Vector3(0, 1.1, 0)
	var dest: Vector3 = to_pos + Vector3(0, 1.1, 0)
	mi.position = start
	var ol: OmniLight3D = OmniLight3D.new()
	ol.light_color = col
	ol.light_energy = 1.6
	ol.omni_range = 4.5
	mi.add_child(ol)
	add_child(mi)

	var dist: float = maxf(0.1, start.distance_to(dest))
	projectiles.append({
		"node": mi,
		"from": start,
		"to": dest,
		"t": 0.0,
		"dur": dist / maxf(1.0, speed)
	})

func _process(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var p: Dictionary = projectiles[i]
		p["t"] = float(p["t"]) + delta / maxf(0.02, float(p["dur"]))
		var frac: float = float(p["t"])
		var node: Node3D = p["node"]
		if frac >= 1.0:
			if is_instance_valid(node):
				node.queue_free()
			projectiles.remove_at(i)
		elif is_instance_valid(node):
			node.position = Vector3(p["from"]).lerp(Vector3(p["to"]), frac)

	for i in range(meteors.size() - 1, -1, -1):
		var m: Dictionary = meteors[i]
		m["t"] = float(m["t"]) + delta / 0.34
		var frac: float = float(m["t"])
		var node: Node3D = m["node"]
		if frac >= 1.0:
			var dest: Vector3 = Vector3(m["to"])
			if is_instance_valid(node):
				node.queue_free()
			meteors.remove_at(i)
			spawn_ring(dest, 4.8, Color(1.0, 0.42, 0.08), 0.55)
			spawn_burst(dest, Color(1.0, 0.55, 0.12), 16)
		elif is_instance_valid(node):
			node.position = Vector3(m["from"]).lerp(Vector3(m["to"]), frac)

	for i in range(particles.size() - 1, -1, -1):
		var pt: Dictionary = particles[i]
		pt["life"] = float(pt["life"]) - delta
		var node: Node3D = pt["node"]
		if float(pt["life"]) <= 0.0:
			if is_instance_valid(node):
				node.queue_free()
			particles.remove_at(i)
		elif is_instance_valid(node):
			var vel: Vector3 = pt["vel"]
			vel.y -= 14.0 * delta
			pt["vel"] = vel
			node.position += vel * delta
			var s: float = clampf(float(pt["life"]) / float(pt["max_life"]), 0.1, 1.0)
			node.scale = Vector3.ONE * s

	for i in range(rings.size() - 1, -1, -1):
		var r: Dictionary = rings[i]
		r["life"] = float(r["life"]) - delta
		var node: MeshInstance3D = r["node"]
		if float(r["life"]) <= 0.0:
			if is_instance_valid(node):
				node.queue_free()
			rings.remove_at(i)
		elif is_instance_valid(node):
			var frac: float = 1.0 - float(r["life"]) / float(r["max_life"])
			var s: float = lerpf(0.35, float(r["max_r"]), frac)
			node.scale = Vector3(s, 0.4, s)
			var mat: StandardMaterial3D = r["mat"]
			mat.albedo_color.a = (1.0 - frac) * 0.85

	for i in range(pillars.size() - 1, -1, -1):
		var pl: Dictionary = pillars[i]
		pl["life"] = float(pl["life"]) - delta
		var node: MeshInstance3D = pl["node"]
		if float(pl["life"]) <= 0.0:
			if is_instance_valid(node):
				node.queue_free()
			pillars.remove_at(i)
		elif is_instance_valid(node):
			var frac: float = 1.0 - float(pl["life"]) / float(pl["max_life"])
			var mat: StandardMaterial3D = pl["mat"]
			mat.albedo_color.a = (1.0 - frac) * 0.65

	for i in range(float_texts.size() - 1, -1, -1):
		var ft: Dictionary = float_texts[i]
		ft["life"] = float(ft["life"]) - delta
		ft["pos"] = Vector3(ft["pos"]) + Vector3(0.0, 1.3 * delta, 0.0)
		if float(ft["life"]) <= 0.0:
			float_texts.remove_at(i)
