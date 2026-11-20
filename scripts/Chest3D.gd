extends Node3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var zone_id: String = "elwynn"
var chest_lv: int = 1
var is_opened: bool = false
var respawn_timer: float = 0.0
var is_instance_chest: bool = false
var chest_mesh: Node3D = null

func setup(main_node: Node, pos: Vector3, lv: int, zid: String, inst_chest: bool = false) -> void:
	main_ref = main_node
	position = pos if inst_chest else Vector3(pos.x, maxf(GameData.WATER_Y + 0.1, GameData.get_terrain_height(pos.x, pos.z)), pos.z)
	chest_lv = lv
	zone_id = zid
	is_instance_chest = inst_chest

	var col: Color = Color(1.0, 0.78, 0.24)
	chest_mesh = MeshBuilder3D.build_chest_mesh(col)
	add_child(chest_mesh)

	var ol: OmniLight3D = OmniLight3D.new()
	ol.light_color = col
	ol.light_energy = 1.2
	ol.omni_range = 4.5
	ol.position = Vector3(0, 0.9, 0)
	add_child(ol)

	add_to_group("chests")

func _process(delta: float) -> void:
	if not is_instance_valid(main_ref) or not is_instance_valid(main_ref.world_3d):
		return
	var active_here: bool = (main_ref.world_3d.in_instance == is_instance_chest)
	visible = active_here and not is_opened
	if is_opened and not is_instance_chest:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			is_opened = false

func open_chest(pl: Node3D) -> void:
	if is_opened:
		return
	is_opened = true
	respawn_timer = 55.0
	SoundFX.play("chest")
	main_ref.vfx.spawn_burst(position, Color(1.0, 0.85, 0.25), 14)
	main_ref.vfx.spawn_ring(position, 2.2, Color(1.0, 0.85, 0.25), 0.45)

	var g_gain: int = 18 + chest_lv * 6 + randi() % 20
	var sh_gain: int = 1 + (chest_lv / 15)
	pl.gold += g_gain
	pl.shards += sh_gain
	pl.potions += 1
	pl.chests_opened += 1
	main_ref.vfx.spawn_text(position, "+%d зол. +%d оск." % [g_gain, sh_gain], Color(1.0, 0.90, 0.30), 15)
	main_ref.log_chat("[color=#ffdd55]Открыт сундук сокровищ: +%d зол., +%d оск., +1 зелье![/color]" % [g_gain, sh_gain])

	var r: int = 2 if randf() < 0.55 else 3
	if chest_lv >= 45 and randf() < 0.22:
		r = 4
	var item: Dictionary = GameData.generate_item(chest_lv, r)
	pl.add_item_to_inventory(item)
