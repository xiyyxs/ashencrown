extends CharacterBody3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var bot_name: String = "Игрок"
var guild: String = "<Орден Пепла>"
var class_id: String = "warrior"
var level: int = 5
var zone_id: String = "elwynn"
var is_party_bot: bool = false
var party_slot: int = 0

var hp: float = 400.0
var max_hp: float = 400.0
var move_target: Vector3 = Vector3.ZERO
var wait_timer: float = 1.0
var atk_timer: float = 0.0
var heal_timer: float = 0.0
var walk_t: float = 0.0
var rig: Dictionary = {}

func setup(main_node: Node, p_name: String, p_guild: String, p_cls: String, p_lv: int, p_zone: String, start_pos: Vector3, party_mode: bool = false, slot_idx: int = 0) -> void:
	main_ref = main_node
	bot_name = p_name
	guild = p_guild
	class_id = p_cls
	level = p_lv
	zone_id = p_zone
	is_party_bot = party_mode
	party_slot = slot_idx
	position = start_pos
	move_target = start_pos

	max_hp = 220.0 + float(level) * 35.0
	hp = max_hp

	var col: Color = GameData.CLASSES[class_id]["color"]
	var rlist: Array = ["human", "elf", "dwarf", "orc", "undead"]
	var rpick: String = str(rlist[abs(p_name.hash()) % rlist.size()])
	rig = MeshBuilder3D.build_character_rig(class_id, col, 1.0, 1, rpick)
	add_child(rig["root"])
	if is_party_bot:
		rig["aura_ring"].visible = true
		add_to_group("party_bots")
	else:
		add_to_group("bots")

func take_damage(amount: float) -> void:
	hp = maxf(1.0, hp - amount * 0.45)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(main_ref) or not is_instance_valid(main_ref.world_3d):
		return

	if not is_party_bot:
		var show_open: bool = not main_ref.world_3d.in_instance
		visible = show_open
		if not show_open:
			return
		# Не гоняем далеких открытых ботов
		if is_instance_valid(main_ref.player) and position.distance_to(main_ref.player.position) > 65.0:
			return

	atk_timer = maxf(0.0, atk_timer - delta)
	heal_timer = maxf(0.0, heal_timer - delta)
	wait_timer -= delta

	if is_party_bot:
		_process_party_bot(delta)
	else:
		_process_world_bot(delta)

func _process_party_bot(delta: float) -> void:
	var pl: Node3D = main_ref.player
	if not is_instance_valid(pl):
		return

	# Паладин/Маг хилит игрока!
	if class_id == "paladin" and heal_timer <= 0.0 and not pl.dead and pl.hp < pl.max_hp * 0.72:
		heal_timer = 5.5
		var heal_amt: float = round(pl.max_hp * 0.24)
		pl.hp = minf(pl.max_hp, pl.hp + heal_amt)
		main_ref.vfx.spawn_ring(pl.position, 2.0, Color(0.3, 1.0, 0.45), 0.4)
		main_ref.vfx.spawn_text(pl.position, "+%d [%s]" % [int(heal_amt), bot_name], Color(0.4, 1.0, 0.55), 14)

	# Ищем ближайшего живого врага в инстансе рядом с игроком или ботом
	var best_mob: Node3D = null
	var best_d: float = 16.0
	for e in main_ref.instance_enemies:
		if is_instance_valid(e) and not e.is_dead:
			var d: float = position.distance_to(e.position)
			if d < best_d:
				best_d = d
				best_mob = e

	if best_mob != null:
		var rng: float = 8.5 if GameData.CLASSES[class_id]["ranged"] else 2.4
		if best_d > rng:
			_move_toward(best_mob.position, 5.4, delta)
		else:
			_face(best_mob.position - position, delta)
			if atk_timer <= 0.0:
				atk_timer = 1.15
				var col: Color = GameData.CLASSES[class_id]["color"]
				if GameData.CLASSES[class_id]["ranged"]:
					main_ref.vfx.spawn_proj(position, best_mob.position, col, 0.22, 20.0)
				else:
					_swing_anim()
				var dmg: float = (14.0 + float(level) * 4.2) * randf_range(0.9, 1.15)
				best_mob.take_damage(dmg, false, true, self if class_id == "warrior" else pl)
	else:
		# Держим строй за игроком
		var angle: float = float(party_slot) * 1.4 - 2.0
		var follow_pos: Vector3 = pl.position + Vector3(cos(angle) * 2.8, 0.0, 2.2 + sin(angle) * 1.2)
		if position.distance_to(follow_pos) > 1.2:
			_move_toward(follow_pos, 5.8, delta)

func _process_world_bot(delta: float) -> void:
	var nearest_mob: Node3D = null
	var best_d: float = 11.0
	for e in main_ref.enemies:
		if is_instance_valid(e) and not e.is_dead and not e.is_boss:
			var d: float = position.distance_to(e.position)
			if d < best_d:
				best_d = d
				nearest_mob = e

	if nearest_mob != null:
		if best_d > 3.2:
			_move_toward(nearest_mob.position, 4.6, delta)
		elif atk_timer <= 0.0:
			atk_timer = 1.6
			var col: Color = GameData.CLASSES[class_id]["color"]
			main_ref.vfx.spawn_proj(position, nearest_mob.position, col, 0.20, 18.0)
			nearest_mob.take_damage(float(level) * 2.5, false, false)
	else:
		if position.distance_to(move_target) < 1.0:
			if wait_timer <= 0.0:
				wait_timer = randf_range(1.4, 3.8)
				var z: Dictionary = GameData.get_zone_by_id(zone_id)
				move_target = main_ref._pick_zone_land_spot(z, 12.0)
		else:
			_move_toward(move_target, 4.8, delta)

func _move_toward(dest: Vector3, spd: float, delta: float) -> void:
	var diff: Vector3 = dest - position
	diff.y = 0.0
	if diff.length() < 0.1:
		return
	var dir: Vector3 = diff.normalized()
	position += dir * spd * delta
	position.y = 0.0 if is_party_bot else maxf(GameData.WATER_Y, GameData.get_terrain_height(position.x, position.z))
	_face(dir, delta)
	walk_t += delta * spd * 2.4
	if rig.has("left_leg"):
		rig["left_leg"].rotation.x = sin(walk_t) * 0.55
		rig["right_leg"].rotation.x = -sin(walk_t) * 0.55
		rig["left_arm"].rotation.x = -sin(walk_t) * 0.35
		rig["right_arm"].rotation.x = sin(walk_t) * 0.35

func _face(dir: Vector3, delta: float) -> void:
	var flat: Vector3 = Vector3(dir.x, 0.0, dir.z)
	if flat.length() > 0.01 and rig.has("body_pivot"):
		var bp: Node3D = rig["body_pivot"]
		bp.rotation.y = lerp_angle(bp.rotation.y, atan2(flat.x, flat.z), minf(1.0, delta * 10.0))

func _swing_anim() -> void:
	if rig.has("right_arm"):
		rig["right_arm"].rotation.x = -1.2
