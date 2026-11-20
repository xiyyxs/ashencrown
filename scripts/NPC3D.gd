extends Node3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var npc_name: String = "Житель"
var npc_id: String = ""
var role: String = "quest" # quest, vendor, smith, innkeeper, dungeon
var zone_id: String = "elwynn"
var body_col: Color = Color(0.3, 0.65, 0.9)
var rig: Dictionary = {}

func setup(main_node: Node, p_name: String, p_role: String, p_zone: String, pos: Vector3, p_npc_id: String = "", rot_y: float = 0.0) -> void:
	main_ref = main_node
	npc_name = p_name
	role = p_role
	zone_id = p_zone
	npc_id = p_npc_id if p_npc_id != "" else (p_zone + "_cmd")
	position = Vector3(pos.x, GameData.get_terrain_height(pos.x, pos.z), pos.z)

	var cls_look: String = "warrior"
	match role:
		"quest":
			body_col = Color(0.95, 0.78, 0.24)
			cls_look = "paladin"
		"vendor":
			body_col = Color(0.28, 0.82, 0.44)
			cls_look = "ranger"
		"smith":
			body_col = Color(0.88, 0.42, 0.22)
			cls_look = "warrior"
		"innkeeper":
			body_col = Color(0.96, 0.70, 0.30)
			cls_look = "priest"
		"dungeon":
			body_col = Color(0.82, 0.34, 0.96)
			cls_look = "mage"

	var race_list: Array = ["human", "elf", "dwarf", "orc", "human"]
	var r_pick: String = str(race_list[abs(p_name.hash()) % race_list.size()])
	rig = MeshBuilder3D.build_character_rig(cls_look, body_col, 1.05, 1, r_pick)
	if rig.has("body_pivot") and is_instance_valid(rig["body_pivot"]):
		rig["body_pivot"].rotation.y = rot_y
	add_child(rig["root"])
	var ring: MeshInstance3D = rig["aura_ring"]
	ring.visible = true
	add_to_group("npcs")

func _process(_delta: float) -> void:
	if rig.has("body_pivot") and is_instance_valid(rig["body_pivot"]):
		var bp: Node3D = rig["body_pivot"]
		bp.position.y = sin(Time.get_ticks_msec() * 0.003 + position.x) * 0.04

func get_role_tag() -> String:
	match role:
		"quest": return "<Задания>"
		"vendor": return "<Торговец>"
		"smith": return "<Кузнец>"
		"innkeeper": return "<Трактирщик>"
		"dungeon": return "<Вестник Походов>"
	return ""

func get_quest_marker(pl: Node) -> String:
	if role != "quest" or not is_instance_valid(pl):
		return ""
	for q in GameData.QUESTS:
		if str(q["zone"]) != zone_id or str(q.get("npc_id", zone_id + "_cmd")) != npc_id:
			continue
		var qid: String = str(q["id"])
		if pl.active_quests.has(qid) and int(pl.active_quests[qid]) >= int(q["need"]):
			return "?"
	for q in GameData.QUESTS:
		if str(q["zone"]) != zone_id or str(q.get("npc_id", zone_id + "_cmd")) != npc_id:
			continue
		var qid: String = str(q["id"])
		var req: String = str(q.get("req", ""))
		var req_ok: bool = req == "" or pl.completed_quests.has(req)
		if req_ok and not pl.active_quests.has(qid) and not pl.completed_quests.has(qid):
			if pl.level >= int(q["min_lv"]) - 2:
				return "!"
	for q in GameData.QUESTS:
		if str(q["zone"]) == zone_id and str(q.get("npc_id", zone_id + "_cmd")) == npc_id and pl.active_quests.has(str(q["id"])):
			return "..."
	return ""
