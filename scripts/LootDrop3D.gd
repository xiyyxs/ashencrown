extends Node3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var item_data: Dictionary = {}
var gold_amount: int = 0
var life_timer: float = 90.0
var is_instance_drop: bool = false

var mesh_pivot: Node3D = null
var rarity_col: Color = Color.WHITE

func setup(main_node: Node, pos: Vector3, p_item: Dictionary, p_gold: int = 0, inst_drop: bool = false) -> void:
	main_ref = main_node
	item_data = p_item
	gold_amount = p_gold
	is_instance_drop = inst_drop
	position = pos if inst_drop else Vector3(pos.x, maxf(GameData.WATER_Y, GameData.get_terrain_height(pos.x, pos.z)), pos.z)

	var r: int = int(p_item.get("rarity", 0)) if not p_item.is_empty() else 1
	rarity_col = GameData.RARITIES[clampi(r, 0, 4)]["color"] if not p_item.is_empty() else Color(1.0, 0.85, 0.25)

	mesh_pivot = Node3D.new()
	add_child(mesh_pivot)

	# Сундучок / самоцвет
	if not p_item.is_empty() and r >= 2:
		var cm: Node3D = MeshBuilder3D.build_chest_mesh(rarity_col)
		cm.scale = Vector3.ONE * 0.65
		mesh_pivot.add_child(cm)
	else:
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.46, 0.34, 0.36) if not p_item.is_empty() else Vector3(0.32, 0.22, 0.28)
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = MeshBuilder3D.make_mat(rarity_col, 0.4, 0.3, rarity_col, 0.8)
		mi.position = Vector3(0, 0.35, 0)
		mesh_pivot.add_child(mi)

	# Столб света как в Diablo!
	if not p_item.is_empty():
		var beam: CylinderMesh = CylinderMesh.new()
		beam.top_radius = 0.08
		beam.bottom_radius = 0.24
		beam.height = 4.2 if r >= 2 else 2.2
		var bmi: MeshInstance3D = MeshInstance3D.new()
		bmi.mesh = beam
		bmi.material_override = MeshBuilder3D.make_mat(rarity_col, 0, 0.2, rarity_col, 1.8, 0.42)
		bmi.position = Vector3(0, beam.height * 0.5, 0)
		add_child(bmi)

	add_to_group("loot")

func _process(delta: float) -> void:
	life_timer -= delta
	if life_timer <= 0.0:
		queue_free()
		return
	if is_instance_valid(mesh_pivot):
		mesh_pivot.rotate_y(delta * 2.2)
		mesh_pivot.position.y = sin(Time.get_ticks_msec() * 0.005) * 0.12

func get_label() -> String:
	if not item_data.is_empty():
		return GameData.item_display_name(item_data)
	return "%d зол." % gold_amount
