extends Node3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var node_id: String = "node_elwynn"
var node_label: String = "Светлоцвет"
var respawn_timer: float = 0.0
var is_collected: bool = false

func setup(main_node: Node, pos: Vector3, nid: String, label: String, col: Color) -> void:
	main_ref = main_node
	position = Vector3(pos.x, maxf(GameData.WATER_Y + 0.1, GameData.get_terrain_height(pos.x, pos.z)), pos.z)
	node_id = nid
	node_label = label

	var m: Node3D = MeshBuilder3D.build_quest_node_mesh(col)
	add_child(m)
	add_to_group("quest_nodes")

func _process(delta: float) -> void:
	if not is_instance_valid(main_ref) or not is_instance_valid(main_ref.world_3d):
		return
	var show_here: bool = not main_ref.world_3d.in_instance
	visible = show_here and not is_collected
	if is_collected:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			is_collected = false

func collect(pl: Node3D) -> void:
	if is_collected:
		return
	is_collected = true
	respawn_timer = 28.0
	SoundFX.play("potion")
	main_ref.vfx.spawn_burst(position, Color(0.45, 1.0, 0.6), 10)
	pl.on_quest_progress(node_id)
	pl.gain_xp(25)
