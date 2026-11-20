extends CharacterBody3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var camera: Camera3D = null
var cam_dist: float = 16.5

var char_id: String = ""
var char_name: String = "Странник"
var race_id: String = "human"
var class_id: String = "warrior"
var level: int = 1
var xp: int = 0
var gold: int = 75
var shards: int = 3
var potions: int = 5
var skill_points: int = 0
var skill_ranks: Array = [1, 1, 1, 1, 1]
var discovered_landmarks: Array = []

var hp: float = 160.0
var max_hp: float = 160.0
var resource: float = 100.0
var max_resource: float = 100.0
var atk_power: float = 18.0
var armor_val: float = 9.0
var crit_chance: float = 8.0
var cdr_mult: float = 1.0
var vamp_pct: float = 0.0
var xp_gold_mult: float = 1.0
var base_speed: float = 7.6

var is_mounted: bool = false
var dead: bool = false
var combat_timer: float = 0.0
var auto_attack_on: bool = false
var auto_atk_cd: float = 0.0
var buff_shield: float = 0.0
var buff_invuln: float = 0.0
var swing_anim: float = 0.0
var spin_anim: float = 0.0
var walk_t: float = 0.0
var step_timer: float = 0.0

var hearth_zone: String = "elwynn"
var hearth_pos: Vector3 = Vector3(73.6, 0.0, 234.0)
var hearth_cd: float = 0.0
var hearth_cast: float = 0.0

var target: Node3D = null
var click_move_active: bool = false
var click_move_pos: Vector3 = Vector3.ZERO
var skill_cds: Array = [0.0, 0.0, 0.0, 0.0, 0.0]

var equipment: Dictionary = {
	"weapon": {}, "armor": {}, "helm": {}, "shoulders": {}, "amulet": {}, "ring": {}
}
var inventory: Array = []
var talents: Dictionary = {
	"might": 0, "vitality": 0, "precision": 0, "haste": 0, "vamp": 0, "greed": 0
}
var active_quests: Dictionary = {}
var completed_quests: Array = []
var unlocked_zones: Array = ["elwynn"]
var playtime_sec: float = 0.0
var kills_count: int = 0
var bosses_killed: int = 0
var chests_opened: int = 0
var dungeons_cleared: int = 0

var rig: Dictionary = {}
var facing_dir: Vector3 = Vector3(0, 0, 1)

var pet_rig: Dictionary = {}
var pet_pos: Vector3 = Vector3.ZERO
var pet_atk_cd: float = 0.0

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 34.0
	camera.near = 0.5
	camera.far = 160.0
	camera.current = true
	add_child(camera)

	var cs: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.6
	cs.shape = cap
	cs.position = Vector3(0, 0.8, 0)
	add_child(cs)

	add_to_group("player")
	_rebuild_rig()
	_update_camera(1.0)

func preview_class(cid: String, rid: String = "") -> void:
	if rid != "" and GameData.RACES.has(rid):
		race_id = rid
	if GameData.CLASSES.has(cid):
		class_id = cid
	for s in GameData.SLOTS:
		equipment[s] = {}
	_rebuild_rig()
	_update_camera(1.0)

func preview_saved_character(d: Dictionary) -> void:
	race_id = str(d.get("race_id", "human"))
	if not GameData.RACES.has(race_id):
		race_id = "human"
	class_id = str(d.get("class_id", "warrior"))
	if not GameData.CLASSES.has(class_id):
		class_id = "warrior"
	var eq: Variant = d.get("equipment", {})
	for s in GameData.SLOTS:
		equipment[s] = eq.get(s, {}) if typeof(eq) == TYPE_DICTIONARY else {}
	_rebuild_rig()
	_update_camera(1.0)

func _rebuild_rig() -> void:
	if rig.has("root") and is_instance_valid(rig["root"]):
		rig["root"].queue_free()
	var cdata: Dictionary = GameData.CLASSES[class_id]
	var armor_col: Color = cdata["color"]
	var gear_tier: int = 0
	if not equipment.get("armor", {}).is_empty():
		var ar_r: int = int(equipment["armor"].get("rarity", 0))
		gear_tier = maxi(gear_tier, ar_r)
		if ar_r >= 2:
			armor_col = armor_col.lerp(GameData.RARITIES[ar_r]["color"], 0.35)
	rig = MeshBuilder3D.build_character_rig(class_id, armor_col, 1.0, gear_tier, race_id)
	add_child(rig["root"])

	# Питомец Охотника (волк) или Чернокнижника (бес)
	if pet_rig.has("root") and is_instance_valid(pet_rig["root"]):
		pet_rig["root"].queue_free()
		pet_rig.clear()
	if class_id == "ranger" or class_id == "warlock":
		pet_rig = MeshBuilder3D.build_pet_wolf(class_id == "warlock")
		if is_instance_valid(main_ref) and is_instance_valid(main_ref.sub_viewport):
			main_ref.sub_viewport.add_child(pet_rig["root"])
			pet_pos = position + Vector3(-1.6, 0.0, 1.4)
			pet_rig["root"].position = pet_pos

	# Свечение оружия от заточки/редкости
	if rig.has("weapon") and is_instance_valid(rig["weapon"]) and not equipment.get("weapon", {}).is_empty():
		var w_item: Dictionary = equipment["weapon"]
		var wr: int = int(w_item.get("rarity", 0))
		var wu: int = int(w_item.get("upgrade", 0))
		if wr >= 2 or wu > 0:
			var wmi: MeshInstance3D = rig["weapon"]
			var wcol: Color = GameData.RARITIES[clampi(wr, 0, 4)]["color"]
			wmi.material_override = MeshBuilder3D.make_mat(wcol, 0.7, 0.25, wcol, 0.5 + float(wu) * 0.22)

	if rig.has("mount") and is_instance_valid(rig["mount"]):
		rig["mount"].visible = is_mounted
		rig["body_pivot"].position.y = 0.52 if is_mounted else 0.0

func init_new(p_name: String, p_cls: String, p_race: String = "human") -> void:
	char_id = "char_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 9999)
	var clean_n: String = p_name.strip_edges()
	char_name = clean_n if clean_n != "" else str(GameData.RANDOM_NAMES[randi() % GameData.RANDOM_NAMES.size()])
	race_id = p_race if GameData.RACES.has(p_race) else "human"
	class_id = p_cls if GameData.CLASSES.has(p_cls) else "warrior"
	level = 1
	xp = 0
	gold = 75
	shards = 3
	potions = 5
	skill_points = 0
	skill_ranks = [1, 1, 1, 1, 1]
	discovered_landmarks.clear()
	inventory.clear()
	active_quests.clear()
	completed_quests.clear()
	unlocked_zones = ["elwynn"]
	for k in talents.keys():
		talents[k] = 0
	for s in GameData.SLOTS:
		equipment[s] = {}
	equipment["weapon"] = GameData.generate_item(1, 1, "weapon")
	equipment["armor"] = GameData.generate_item(1, 0, "armor")
	hearth_zone = "elwynn"
	hearth_pos = Vector3(73.6, 0.0, 234.0)
	hearth_cd = 0.0
	hearth_cast = 0.0
	position = GameData.ZONES[0]["hub"] + Vector3(0.0, 0.0, 4.5)
	position.y = GameData.get_terrain_height(position.x, position.z)
	click_move_active = false
	is_mounted = false
	_rebuild_rig()
	recalc_stats()
	hp = max_hp
	resource = max_resource
	dead = false
	_update_camera(1.0)

func export_to_dict() -> Dictionary:
	var save_pos: Vector3 = main_ref.return_world_pos if (is_instance_valid(main_ref) and main_ref.world_3d.in_instance) else position
	return {
		"char_id": char_id,
		"char_name": char_name,
		"race_id": race_id,
		"class_id": class_id,
		"level": level,
		"xp": xp,
		"gold": gold,
		"shards": shards,
		"potions": potions,
		"skill_points": skill_points,
		"skill_ranks": skill_ranks,
		"discovered_landmarks": discovered_landmarks,
		"pos_x": save_pos.x,
		"pos_z": save_pos.z,
		"equipment": equipment,
		"inventory": inventory,
		"talents": talents,
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"unlocked_zones": unlocked_zones,
		"playtime_sec": playtime_sec,
		"kills_count": kills_count,
		"bosses_killed": bosses_killed,
		"chests_opened": chests_opened,
		"dungeons_cleared": dungeons_cleared,
		"hearth_zone": hearth_zone,
		"hearth_x": hearth_pos.x,
		"hearth_z": hearth_pos.z
	}

func load_from_dict(d: Dictionary) -> void:
	char_id = str(d.get("char_id", "char_" + str(Time.get_ticks_msec())))
	char_name = str(d.get("char_name", "Странник"))
	race_id = str(d.get("race_id", "human"))
	if not GameData.RACES.has(race_id):
		race_id = "human"
	class_id = str(d.get("class_id", "warrior"))
	if not GameData.CLASSES.has(class_id):
		class_id = "warrior"
	level = clampi(int(d.get("level", 1)), 1, GameData.MAX_LEVEL)
	xp = int(d.get("xp", 0))
	gold = int(d.get("gold", 50))
	shards = int(d.get("shards", 0))
	potions = int(d.get("potions", 3))
	skill_points = int(d.get("skill_points", 0))
	var sr: Variant = d.get("skill_ranks", [1, 1, 1, 1, 1])
	if typeof(sr) == TYPE_ARRAY and sr.size() == 5:
		skill_ranks = sr
	else:
		skill_ranks = [1, 1, 1, 1, 1]
	discovered_landmarks = d.get("discovered_landmarks", []) if typeof(d.get("discovered_landmarks", [])) == TYPE_ARRAY else []
	position = Vector3(float(d.get("pos_x", 36.0)), 0.0, float(d.get("pos_z", 48.5)))
	position.y = GameData.get_terrain_height(position.x, position.z)
	var eq: Variant = d.get("equipment", {})
	if typeof(eq) == TYPE_DICTIONARY:
		for s in GameData.SLOTS:
			equipment[s] = eq.get(s, {})
	inventory = d.get("inventory", []) if typeof(d.get("inventory", [])) == TYPE_ARRAY else []
	var tl: Variant = d.get("talents", {})
	if typeof(tl) == TYPE_DICTIONARY:
		for k in talents.keys():
			talents[k] = int(tl.get(k, 0))
	active_quests = d.get("active_quests", {}) if typeof(d.get("active_quests", {})) == TYPE_DICTIONARY else {}
	completed_quests = d.get("completed_quests", []) if typeof(d.get("completed_quests", [])) == TYPE_ARRAY else []
	unlocked_zones = d.get("unlocked_zones", ["elwynn"]) if typeof(d.get("unlocked_zones", [])) == TYPE_ARRAY else ["elwynn"]
	playtime_sec = float(d.get("playtime_sec", 0.0))
	kills_count = int(d.get("kills_count", 0))
	bosses_killed = int(d.get("bosses_killed", 0))
	chests_opened = int(d.get("chests_opened", 0))
	dungeons_cleared = int(d.get("dungeons_cleared", 0))
	hearth_zone = str(d.get("hearth_zone", "elwynn"))
	hearth_pos = Vector3(float(d.get("hearth_x", 73.6)), 0.0, float(d.get("hearth_z", 234.0)))
	hearth_cd = 0.0
	hearth_cast = 0.0
	is_mounted = false
	_rebuild_rig()
	recalc_stats()
	hp = max_hp
	resource = max_resource
	dead = false
	_update_camera(1.0)

func spent_talent_points() -> int:
	var sum: int = 0
	for v in talents.values():
		sum += int(v)
	return sum

func available_talent_points() -> int:
	return maxi(0, level - spent_talent_points())

func recalc_stats() -> void:
	var cdata: Dictionary = GameData.CLASSES[class_id]
	var lv_m: float = float(level - 1)
	var eq_hp: float = 0.0
	var eq_atk: float = 0.0
	var eq_arm: float = 0.0
	var eq_crit: float = 0.0

	for s in GameData.SLOTS:
		var item: Dictionary = equipment.get(s, {})
		if not item.is_empty():
			eq_hp += GameData.item_effective_stat(item, "hp")
			eq_atk += GameData.item_effective_stat(item, "atk")
			eq_arm += GameData.item_effective_stat(item, "arm")
			eq_crit += float(item.get("crit", 0.0))

	var rdata: Dictionary = GameData.RACES.get(race_id, GameData.RACES["human"])
	var vit_mult: float = (1.0 + float(talents.get("vitality", 0)) * 0.10) * float(rdata["hp_mult"])
	var might_mult: float = (1.0 + float(talents.get("might", 0)) * 0.08) * float(rdata["atk_mult"])

	max_hp = round((float(cdata["base_hp"]) + lv_m * float(cdata["hp_lv"]) + eq_hp) * vit_mult)
	max_resource = round((float(cdata["base_res"]) + lv_m * float(cdata["res_lv"])) * float(rdata["res_mult"]))
	atk_power = round((float(cdata["base_atk"]) + lv_m * float(cdata["atk_lv"]) + eq_atk) * might_mult)
	armor_val = round(float(cdata["base_arm"]) + lv_m * float(cdata["arm_lv"]) + eq_arm)
	crit_chance = clampf(8.0 + float(talents.get("precision", 0)) * 4.0 + eq_crit, 5.0, 68.0)
	cdr_mult = maxf(0.55, 1.0 - float(talents.get("haste", 0)) * 0.06)
	vamp_pct = float(talents.get("vamp", 0)) * 0.03 + float(rdata["vamp"])
	xp_gold_mult = (1.0 + float(talents.get("greed", 0)) * 0.15) * float(rdata["xp_mult"])

	hp = clampf(hp, 0.0, max_hp)
	resource = clampf(resource, 0.0, max_resource)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(main_ref):
		return
	if not main_ref.game_started:
		if rig.has("body_pivot") and is_instance_valid(rig["body_pivot"]):
			rig["body_pivot"].rotate_y(delta * 0.85)
		_animate_orbiters(delta)
		return

	playtime_sec += delta
	combat_timer = maxf(0.0, combat_timer - delta)
	auto_atk_cd = maxf(0.0, auto_atk_cd - delta)
	buff_shield = maxf(0.0, buff_shield - delta)
	buff_invuln = maxf(0.0, buff_invuln - delta)
	swing_anim = maxf(0.0, swing_anim - delta * 4.5)
	spin_anim = maxf(0.0, spin_anim - delta * 2.6)
	hearth_cd = maxf(0.0, hearth_cd - delta)
	for i in range(5):
		skill_cds[i] = maxf(0.0, float(skill_cds[i]) - delta)

	if dead:
		hearth_cast = 0.0
		_update_camera(delta)
		return

	if hearth_cast > 0.0:
		hearth_cast = maxf(0.0, hearth_cast - delta)
		if hearth_cast <= 0.0:
			_finish_hearthstone()
			return

	# Регенерация
	if combat_timer <= 0.0:
		hp = minf(max_hp, hp + max_hp * 0.045 * delta)
	if class_id == "warrior":
		if combat_timer <= 0.0:
			resource = maxf(0.0, resource - 5.0 * delta)
	elif class_id == "ranger" or class_id == "rogue":
		resource = minf(max_resource, resource + 14.0 * delta)
	else:
		resource = minf(max_resource, resource + (max_resource * 0.075) * delta)

	# Движение WASD + виртуальный джойстик телефона
	var ix: float = Input.get_axis("move_left", "move_right")
	var iy: float = Input.get_axis("move_up", "move_down")
	if is_instance_valid(main_ref.hud) and main_ref.hud.joy_vec.length() > 0.08:
		ix = clampf(ix + main_ref.hud.joy_vec.x, -1.0, 1.0)
		iy = clampf(iy + main_ref.hud.joy_vec.y, -1.0, 1.0)
	var cam_fwd: Vector3 = Vector3(-0.7071, 0.0, -0.7071)
	var cam_right: Vector3 = Vector3(0.7071, 0.0, -0.7071)
	var move_dir: Vector3 = cam_right * ix - cam_fwd * iy

	if move_dir.length() > 0.05:
		click_move_active = false
		move_dir = move_dir.normalized()
	elif click_move_active:
		var diff: Vector3 = click_move_pos - position
		diff.y = 0.0
		if diff.length() < 0.45:
			click_move_active = false
			move_dir = Vector3.ZERO
		else:
			move_dir = diff.normalized()

	if move_dir.length() > 0.05:
		if hearth_cast > 0.0:
			hearth_cast = 0.0
			main_ref.vfx.spawn_text(position, "ПРЕРВАНО", Color(1.0, 0.55, 0.35), 13)
		var spd: float = base_speed * (1.60 if is_mounted else 1.0)
		position += move_dir * spd * delta
		facing_dir = move_dir
		walk_t += delta * spd * 2.2
		step_timer -= delta
		if step_timer <= 0.0:
			if is_mounted:
				step_timer = 0.28
				SoundFX.play("horse_step")
			else:
				step_timer = 0.35
				SoundFX.play(_get_surface_step_sfx())
	else:
		walk_t = 0.0
		step_timer = 0.05
		if is_mounted:
			SoundFX.stop_horse()

	# Ограничение мира или инстанса + высота рельефа!
	if main_ref.world_3d.in_instance:
		position.x = clampf(position.x, -11.8, 11.8)
		position.z = clampf(position.z, -55.8, 8.2)
		position.y = 0.0
	else:
		position.x = clampf(position.x, 2.5, GameData.WORLD_W - 2.5)
		position.z = clampf(position.z, 2.5, GameData.WORLD_H - 2.5)
		position.y = maxf(GameData.WATER_Y - 0.15, GameData.get_terrain_height(position.x, position.z))

	_animate_rig(delta, move_dir.length() > 0.05)
	_animate_orbiters(delta)
	_update_pet(delta)

	# Разблокировка зоны и ориентиров (explore квесты!)
	if not main_ref.world_3d.in_instance:
		var z: Dictionary = GameData.get_zone_at(position)
		var zid: String = str(z["id"])
		if not unlocked_zones.has(zid):
			unlocked_zones.append(zid)
			main_ref.log_chat("[color=#ffdd55]Открыта новая область: %s![/color]" % str(z["name"]))
			main_ref.vfx.spawn_text(position, "НОВАЯ ЗОНА!", Color(1.0, 0.9, 0.3), 18)
		for lm in z.get("landmarks", []):
			if position.distance_to(lm["pos"]) < 10.0:
				var lid: String = str(lm["id"])
				if not discovered_landmarks.has(lid):
					discovered_landmarks.append(lid)
					main_ref.log_chat("[color=#88eeff]Открыт ориентир: %s![/color]" % str(lm["name"]))
					main_ref.vfx.spawn_text(position, str(lm["name"]), Color(0.55, 0.92, 1.0), 16)
				on_quest_progress(lid)

	# Автоатака
	if auto_attack_on and is_instance_valid(target) and not target.is_dead:
		var cdata: Dictionary = GameData.CLASSES[class_id]
		var rng: float = float(cdata["range"])
		if position.distance_to(target.position) <= rng + 0.6 and auto_atk_cd <= 0.0:
			auto_atk_cd = 0.92
			_do_basic_attack(target)
	elif auto_attack_on and (not is_instance_valid(target) or target.is_dead):
		auto_attack_on = false

	_update_camera(delta)

func _get_surface_step_sfx() -> String:
	if is_instance_valid(main_ref) and main_ref.world_3d.in_instance:
		return "step_stone"
	if GameData.get_road_dist(position.x, position.z) < 3.4:
		return "step_stone"
	var z: Dictionary = GameData.get_zone_at(position)
	match str(z["id"]):
		"frostpeak": return "step_snow"
		"barrens", "citadel": return "step_sand"
		_: return "step_grass"

func _animate_rig(delta: float, is_moving: bool) -> void:
	if not rig.has("body_pivot") or not is_instance_valid(rig["body_pivot"]):
		return
	var bp: Node3D = rig["body_pivot"]
	var target_yaw: float = atan2(facing_dir.x, facing_dir.z)
	if spin_anim > 0.01:
		bp.rotation.y += delta * 18.0
	else:
		bp.rotation.y = lerp_angle(bp.rotation.y, target_yaw, minf(1.0, delta * 14.0))

	if rig.has("mount_pivot") and is_instance_valid(rig["mount_pivot"]):
		var mp: Node3D = rig["mount_pivot"]
		mp.rotation.y = lerp_angle(mp.rotation.y, target_yaw, minf(1.0, delta * 14.0))

	if is_mounted:
		rig["left_leg"].rotation.x = -0.35
		rig["right_leg"].rotation.x = -0.35
		rig["left_leg"].rotation.z = -0.22
		rig["right_leg"].rotation.z = 0.22
		rig["left_arm"].rotation.x = -0.32 if not is_moving else -0.38 + sin(walk_t) * 0.14
		rig["right_arm"].rotation.x = -swing_anim * 1.6 if swing_anim > 0.01 else (-0.28 + cos(walk_t) * 0.12 if is_moving else -0.22)
	elif is_moving:
		rig["left_leg"].rotation.z = 0.0
		rig["right_leg"].rotation.z = 0.0
		rig["left_leg"].rotation.x = sin(walk_t) * 0.58
		rig["right_leg"].rotation.x = -sin(walk_t) * 0.58
		rig["left_arm"].rotation.x = -sin(walk_t) * 0.40
		rig["right_arm"].rotation.x = sin(walk_t) * 0.40 if swing_anim <= 0.01 else -swing_anim * 1.6
	else:
		rig["left_leg"].rotation.z = 0.0
		rig["right_leg"].rotation.z = 0.0
		rig["left_leg"].rotation.x = lerpf(rig["left_leg"].rotation.x, 0.0, delta * 10.0)
		rig["right_leg"].rotation.x = lerpf(rig["right_leg"].rotation.x, 0.0, delta * 10.0)
		rig["left_arm"].rotation.x = lerpf(rig["left_arm"].rotation.x, 0.0, delta * 10.0)
		if swing_anim > 0.01:
			rig["right_arm"].rotation.x = -swing_anim * 1.6
		else:
			rig["right_arm"].rotation.x = lerpf(rig["right_arm"].rotation.x, 0.0, delta * 10.0)

	if is_mounted and rig.has("mount_legs"):
		var mlegs: Array = rig["mount_legs"]
		for idx in range(mlegs.size()):
			var hl: Node3D = mlegs[idx]
			if is_instance_valid(hl):
				var phase: float = 0.0 if (idx == 0 or idx == 3) else PI
				hl.rotation.x = sin(walk_t * 1.15 + phase) * 0.68 if is_moving else 0.0

func _animate_orbiters(delta: float) -> void:
	if rig.has("orbiters"):
		for i in range(rig["orbiters"].size()):
			var o: Node3D = rig["orbiters"][i]
			if is_instance_valid(o):
				o.rotate_y(delta * (2.4 + float(i) * 0.6))

func _update_pet(delta: float) -> void:
	if not pet_rig.has("root") or not is_instance_valid(pet_rig["root"]):
		return
	var pnode: Node3D = pet_rig["root"]
	pnode.visible = not dead
	if dead:
		return
	pet_atk_cd = maxf(0.0, pet_atk_cd - delta)
	var dest: Vector3 = position + Vector3(-1.5, 0.0, 1.3)
	var attacking: bool = false
	if is_instance_valid(target) and not target.is_dead and position.distance_to(target.position) < 15.0:
		dest = target.position + Vector3(-1.1, 0.0, 0.8)
		attacking = true

	var diff: Vector3 = dest - pet_pos
	diff.y = 0.0
	if diff.length() > 0.45:
		var dir: Vector3 = diff.normalized()
		pet_pos += dir * 8.6 * delta
		pet_rig["body_pivot"].rotation.y = lerp_angle(pet_rig["body_pivot"].rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 12.0))
	elif attacking and pet_atk_cd <= 0.0:
		pet_atk_cd = 2.0
		_deal_damage(target, atk_power * 0.55)
	pet_pos.y = 0.0 if (is_instance_valid(main_ref) and main_ref.world_3d.in_instance) else maxf(GameData.WATER_Y, GameData.get_terrain_height(pet_pos.x, pet_pos.z))
	pnode.position = pet_pos

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	var offset: Vector3 = Vector3(cam_dist * 0.707, cam_dist * 0.92, cam_dist * 0.707)
	var look_target: Vector3 = position + Vector3(0, 0.8, 0)
	if is_instance_valid(main_ref) and not main_ref.game_started:
		offset = Vector3(4.8, 3.6, 4.8)
		look_target = position + Vector3(-1.35, 1.05, 1.35)
	var desired: Vector3 = position + offset
	camera.global_position = camera.global_position.lerp(desired, minf(1.0, delta * 10.0)) if delta < 0.5 else desired
	camera.look_at(look_target, Vector3.UP)

func mobile_attack_action() -> void:
	if dead or not is_instance_valid(main_ref):
		return
	if not is_instance_valid(target) or target.is_dead:
		var ne: Node3D = main_ref.find_nearest_enemy(position, 22.0)
		if ne != null:
			target = ne
		else:
			swing_anim = 0.7
			SoundFX.play("hit")
			return
	auto_attack_on = true
	var cdata: Dictionary = GameData.CLASSES[class_id]
	var rng: float = float(cdata["range"])
	if position.distance_to(target.position) <= rng + 0.6:
		if auto_atk_cd <= 0.0:
			auto_atk_cd = 0.92
			_do_basic_attack(target)
	else:
		click_move_pos = target.position
		click_move_active = true

func _do_basic_attack(t_mob: Node3D) -> void:
	if is_mounted:
		toggle_mount()
	combat_timer = 5.0
	swing_anim = 1.0
	facing_dir = (t_mob.position - position).normalized()
	var cdata: Dictionary = GameData.CLASSES[class_id]
	if bool(cdata["ranged"]):
		main_ref.vfx.spawn_proj(position, t_mob.position, cdata["color"], 0.20, 24.0)
		SoundFX.play("spell")
	else:
		SoundFX.play("hit")
	if class_id == "warrior":
		resource = minf(max_resource, resource + 12.0)
	_deal_damage(t_mob, atk_power)

func _deal_damage(mob: Node3D, raw: float) -> void:
	if not is_instance_valid(mob) or mob.is_dead:
		return
	var is_crit: bool = randf() * 100.0 < crit_chance
	var final_dmg: float = raw * randf_range(0.92, 1.08) * (1.85 if is_crit else 1.0)
	if is_crit:
		SoundFX.play("crit")
	mob.take_damage(final_dmg, is_crit, true, self)
	if vamp_pct > 0.0:
		hp = minf(max_hp, hp + final_dmg * vamp_pct)

func use_skill(idx: int) -> void:
	if dead or idx < 0 or idx >= 5:
		return
	var skills: Array = GameData.CLASSES[class_id]["skills"]
	var sk: Dictionary = skills[idx]
	var req_lv: int = int(sk.get("unlock_lv", 1))
	if level < req_lv:
		main_ref.vfx.spawn_text(position, "Откроется на %d ур.!" % req_lv, Color(0.85, 0.55, 0.35), 13)
		return

	if float(skill_cds[idx]) > 0.0:
		main_ref.vfx.spawn_text(position, "Перезарядка...", Color(0.85, 0.75, 0.45), 13)
		return

	var cost: float = float(sk["cost"])
	if resource < cost:
		main_ref.vfx.spawn_text(position, "Недостаточно %s!" % str(GameData.CLASSES[class_id]["res_name"]), Color(0.45, 0.72, 1.0), 13)
		return

	var rank: int = clampi(int(skill_ranks[idx]), 1, 5)
	var rank_mult: float = 1.0 + float(rank - 1) * 0.18
	var rank_cd: float = maxf(0.75, 1.0 - float(rank - 1) * 0.05)

	var stype: String = str(sk["type"])
	var rng: float = float(sk["range"])
	var mult: float = float(sk["mult"]) * rank_mult
	var col: Color = GameData.CLASSES[class_id]["color"]

	if stype in ["melee", "charge", "execute", "proj_burn", "proj_stun", "aoe_target"]:
		if not is_instance_valid(target) or target.is_dead:
			target = main_ref.find_nearest_enemy(position, 16.0)
		if not is_instance_valid(target) or target.is_dead:
			main_ref.vfx.spawn_text(position, "Нет цели!", Color(1.0, 0.45, 0.35), 13)
			return
		var dist: float = position.distance_to(target.position)
		if dist > rng:
			main_ref.vfx.spawn_text(position, "Далеко!", Color(1.0, 0.65, 0.3), 13)
			return

	if is_mounted and stype != "blink":
		toggle_mount()

	resource -= cost
	skill_cds[idx] = float(sk["cd"]) * cdr_mult * rank_cd
	combat_timer = 5.5
	swing_anim = 1.0

	var tgt: Node3D = target
	match stype:
		"melee":
			if not is_instance_valid(tgt):
				return
			facing_dir = (tgt.position - position).normalized()
			SoundFX.play("hit")
			main_ref.vfx.spawn_ring(tgt.position, 1.6, col, 0.28)
			_deal_damage(tgt, atk_power * mult)
		"aoe_self":
			spin_anim = 1.0
			SoundFX.play("crit")
			main_ref.vfx.spawn_ring(position, rng, col, 0.45)
			for e in main_ref.get_active_enemies():
				if is_instance_valid(e) and not e.is_dead and position.distance_to(e.position) <= rng:
					_deal_damage(e, atk_power * mult)
		"charge":
			if not is_instance_valid(tgt):
				return
			var dir: Vector3 = (tgt.position - position).normalized()
			facing_dir = dir
			position = tgt.position - dir * 1.4
			resource = minf(max_resource, resource + 25.0)
			SoundFX.play("crit")
			main_ref.vfx.spawn_ring(tgt.position, 2.2, col, 0.35)
			_deal_damage(tgt, atk_power * mult)
			if is_instance_valid(tgt) and not tgt.is_dead:
				tgt.apply_stun(float(sk.get("stun", 1.8)))
		"execute":
			if not is_instance_valid(tgt):
				return
			facing_dir = (tgt.position - position).normalized()
			var ex_mult: float = 4.6 if (tgt.hp / maxf(1.0, tgt.max_hp)) < 0.35 else mult
			SoundFX.play("crit")
			main_ref.vfx.spawn_ring(tgt.position, 2.1, Color(1.0, 0.25, 0.15), 0.38)
			_deal_damage(tgt, atk_power * ex_mult)
		"proj_burn":
			if not is_instance_valid(tgt):
				return
			facing_dir = (tgt.position - position).normalized()
			SoundFX.play("spell")
			main_ref.vfx.spawn_proj(position, tgt.position, Color(1.0, 0.45, 0.12), 0.28, 22.0)
			_deal_damage(tgt, atk_power * mult)
			if is_instance_valid(tgt) and not tgt.is_dead:
				tgt.apply_burn(atk_power * 0.38 * rank_mult, 4.0)
		"proj_stun":
			if not is_instance_valid(tgt):
				return
			facing_dir = (tgt.position - position).normalized()
			SoundFX.play("spell")
			main_ref.vfx.spawn_proj(position, tgt.position, col, 0.30, 22.0)
			_deal_damage(tgt, atk_power * mult)
			if is_instance_valid(tgt) and not tgt.is_dead:
				tgt.apply_stun(float(sk.get("stun", 2.4)))
		"frost_nova":
			SoundFX.play("spell")
			main_ref.vfx.spawn_ring(position, rng, Color(0.45, 0.88, 1.0), 0.48)
			for e in main_ref.get_active_enemies():
				if is_instance_valid(e) and not e.is_dead and position.distance_to(e.position) <= rng:
					_deal_damage(e, atk_power * mult)
					if is_instance_valid(e) and not e.is_dead:
						e.apply_stun(float(sk.get("stun", 2.4)))
		"blink":
			SoundFX.play("portal")
			main_ref.vfx.spawn_ring(position, 1.6, Color(0.55, 0.78, 1.0), 0.35)
			position += facing_dir.normalized() * 8.0
			main_ref.vfx.spawn_ring(position, 1.6, Color(0.55, 0.78, 1.0), 0.35)
		"aoe_target":
			if not is_instance_valid(tgt):
				return
			facing_dir = (tgt.position - position).normalized()
			SoundFX.play("boss")
			var center: Vector3 = tgt.position
			if class_id == "mage" or class_id == "warlock":
				main_ref.vfx.spawn_meteor(center)
			else:
				main_ref.vfx.spawn_ring(center, 4.6, col, 0.6)
				main_ref.vfx.spawn_burst(center, col, 14)
			for e in main_ref.get_active_enemies():
				if is_instance_valid(e) and not e.is_dead and center.distance_to(e.position) <= 4.7:
					_deal_damage(e, atk_power * mult)
		"shield":
			SoundFX.play("heal")
			buff_shield = float(sk.get("dur", 6.0))
			if class_id == "mage":
				resource = minf(max_resource, resource + max_resource * 0.28)
			else:
				var h_amt: float = round(max_hp * 0.20)
				hp = minf(max_hp, hp + h_amt)
				main_ref.vfx.spawn_text(position, "+%d HP" % int(h_amt), Color(0.4, 1.0, 0.5), 15)
			main_ref.vfx.spawn_ring(position, 2.2, col, 0.5)
		"heal":
			SoundFX.play("heal")
			var heal_v: float = round(max_hp * mult)
			hp = minf(max_hp, hp + heal_v)
			main_ref.vfx.spawn_ring(position, 2.2, Color(0.35, 1.0, 0.45), 0.5)
			main_ref.vfx.spawn_text(position, "+%d HP" % int(heal_v), Color(0.35, 1.0, 0.45), 16)
		"invuln":
			SoundFX.play("heal")
			buff_invuln = float(sk.get("dur", 5.0))
			main_ref.vfx.spawn_ring(position, 5.2, Color(1.0, 0.92, 0.4), 0.6)
			main_ref.vfx.spawn_text(position, "НЕУЯЗВИМОСТЬ!", Color(1.0, 0.92, 0.35), 16)
			for e in main_ref.get_active_enemies():
				if is_instance_valid(e) and not e.is_dead and position.distance_to(e.position) <= 5.2:
					_deal_damage(e, atk_power * 1.9)

func drink_potion() -> void:
	if dead or potions <= 0 or hp >= max_hp:
		return
	potions -= 1
	var h: float = round(max_hp * 0.45)
	hp = minf(max_hp, hp + h)
	resource = minf(max_resource, resource + max_resource * 0.25)
	SoundFX.play("potion")
	main_ref.vfx.spawn_ring(position, 1.8, Color(0.25, 1.0, 0.45), 0.4)
	main_ref.vfx.spawn_text(position, "+%d ЗЕЛЬЕ" % int(h), Color(0.35, 1.0, 0.45), 15)

func toggle_mount() -> void:
	if dead:
		return
	if level < 20:
		SoundFX.play("ui")
		main_ref.vfx.spawn_text(position, "Скакун с 20 уровня!", Color(1.0, 0.68, 0.25), 14)
		main_ref.log_chat("[color=#ffaa55]Верховая езда открывается на 20 уровне.[/color]")
		return
	if main_ref.world_3d.in_instance:
		main_ref.vfx.spawn_text(position, "Нельзя в подземелье!", Color(1.0, 0.5, 0.3), 13)
		return
	is_mounted = not is_mounted
	if not is_mounted:
		SoundFX.stop_horse()
	if rig.has("mount") and is_instance_valid(rig["mount"]):
		rig["mount"].visible = is_mounted
		rig["body_pivot"].position.y = 0.68 if is_mounted else 0.0
	SoundFX.play("cloth")
	main_ref.vfx.spawn_ring(position, 2.0, Color(0.85, 0.72, 0.35), 0.35)

func bind_hearthstone(zid: String, tavern_spot: Vector3) -> void:
	hearth_zone = zid
	hearth_pos = tavern_spot
	SoundFX.play("quest")
	var z: Dictionary = GameData.get_zone_by_id(zid)
	main_ref.vfx.spawn_pillar(position, Color(0.35, 0.85, 1.0), 0.8)
	main_ref.log_chat("[color=#66ddff]Камень возвращения привязан к таверне: %s![/color]" % str(z["town"]))

func start_hearthstone() -> void:
	if dead or hearth_cast > 0.0:
		return
	if hearth_cd > 0.05:
		SoundFX.play("ui")
		main_ref.vfx.spawn_text(position, "Перезарядка: %dс" % int(ceil(hearth_cd)), Color(0.8, 0.8, 0.9), 13)
		return
	hearth_cast = 2.5
	click_move_active = false
	auto_attack_on = false
	SoundFX.play("hearth")
	main_ref.vfx.spawn_ring(position, 2.6, Color(0.30, 0.78, 1.0), 2.4)

func _finish_hearthstone() -> void:
	hearth_cd = 60.0
	if main_ref.world_3d.in_instance:
		main_ref.exit_dungeon_instance()
	if is_mounted:
		toggle_mount()
	target = null
	position = Vector3(hearth_pos.x, GameData.get_terrain_height(hearth_pos.x, hearth_pos.z), hearth_pos.z)
	_update_camera(1.0)
	SoundFX.play("portal")
	main_ref.vfx.spawn_pillar(position, Color(0.35, 0.86, 1.0), 1.0)
	var z: Dictionary = GameData.get_zone_by_id(hearth_zone)
	main_ref.log_chat("[color=#66eeff]Камень возвращения перенёс вас в таверну (%s).[/color]" % str(z["town"]))

func take_damage(amount: float, _attacker: Node3D = null) -> void:
	if dead:
		return
	if buff_invuln > 0.0:
		main_ref.vfx.spawn_text(position, "БЛОК!", Color(1.0, 0.92, 0.4), 13)
		return
	hearth_cast = 0.0
	combat_timer = 5.5
	var mit: float = armor_val / (armor_val + 40.0 + float(level) * 5.0)
	var dmg: float = amount * (1.0 - mit)
	if buff_shield > 0.0:
		dmg *= 0.45
	dmg = maxf(1.0, round(dmg))
	hp -= dmg
	if class_id == "warrior":
		resource = minf(max_resource, resource + 7.0)
	main_ref.vfx.spawn_text(position, "-%d" % int(dmg), Color(1.0, 0.28, 0.24), 15)

	if hp <= 0.0:
		hp = 0.0
		dead = true
		auto_attack_on = false
		SoundFX.play("death")
		main_ref.log_chat("[color=#ff4444]Вы погибли! Нажмите 'Воскреснуть' или [R] у лагеря.[/color]")
		main_ref.hud.show_death_popup()

func respawn_at_camp() -> void:
	dead = false
	hp = max_hp
	resource = max_resource
	if main_ref.world_3d.in_instance:
		position = Vector3(0.0, 0.0, 5.2)
	else:
		var z: Dictionary = GameData.get_zone_at(position)
		position = z["hub"] + Vector3(0.0, 0.0, 3.8)
	click_move_active = false
	SoundFX.play("heal")
	main_ref.vfx.spawn_pillar(position, Color(0.95, 0.88, 0.4), 0.7)

func on_enemy_killed(tid: String, base_xp: int, base_gold: int, was_boss: bool) -> void:
	kills_count += 1
	if was_boss:
		bosses_killed += 1
	var g_gain: int = int(round(float(base_gold) * xp_gold_mult))
	var x_gain: int = int(round(float(base_xp) * xp_gold_mult))
	gold += g_gain
	gain_xp(x_gain)
	if was_boss:
		main_ref.log_chat("[color=#ffaa33]БОСС ПОВЕРЖЕН: %s! (+%d XP, +%d зол.)[/color]" % [str(GameData.MOBS[tid]["name"]), x_gain, g_gain])
	on_quest_progress(tid)

func on_quest_progress(tid: String) -> void:
	for qid in active_quests.keys():
		var q: Dictionary = GameData.get_quest_by_id(str(qid))
		if not q.is_empty() and str(q["target"]) == tid:
			var cur: int = int(active_quests[qid])
			var need: int = int(q["need"])
			if cur < need:
				active_quests[qid] = cur + 1
				main_ref.log_chat("[color=#88ddff]Задание '%s': %d / %d[/color]" % [str(q["title"]), cur + 1, need])
				if cur + 1 == need:
					SoundFX.play("quest")
					main_ref.vfx.spawn_text(position, "ЗАДАНИЕ ВЫПОЛНЕНО!", Color(1.0, 0.9, 0.25), 16)

func gain_xp(amount: int) -> void:
	if level >= GameData.MAX_LEVEL:
		return
	xp += amount
	main_ref.vfx.spawn_text(position + Vector3(0, 0.4, 0), "+%d XP" % amount, Color(0.85, 0.55, 1.0), 13)
	while level < GameData.MAX_LEVEL and xp >= GameData.xp_for_level(level):
		xp -= GameData.xp_for_level(level)
		level += 1
		skill_points += 1
		recalc_stats()
		hp = max_hp
		resource = max_resource
		SoundFX.play("levelup")
		main_ref.vfx.spawn_pillar(position, Color(1.0, 0.85, 0.22), 1.1)
		main_ref.vfx.spawn_text(position + Vector3(0, 0.8, 0), "УРОВЕНЬ %d!" % level, Color(1.0, 0.92, 0.25), 20)
		main_ref.log_chat("[color=#ffdd44]ПОЗДРАВЛЯЕМ! Вы достигли %d уровня! (+1 очко талантов, +1 очко умений [K])[/color]" % level)
		for sk in GameData.CLASSES[class_id]["skills"]:
			if int(sk.get("unlock_lv", 1)) == level:
				main_ref.log_chat("[color=#55ffcc]ОТКРЫТО НОВОЕ УМЕНИЕ: %s (клавиша %s)![/color]" % [str(sk["name"]), str(sk["key"])])

func add_item_to_inventory(item: Dictionary) -> bool:
	if inventory.size() >= 30:
		main_ref.log_chat("[color=#ff7755]Рюкзак полон (макс. 30)! Разберите или продайте лишнее.[/color]")
		return false
	inventory.append(item)
	SoundFX.play("loot")
	var r: int = int(item.get("rarity", 0))
	var hex: String = str(GameData.RARITIES[r]["hex"])
	main_ref.log_chat("Получен предмет: [color=%s][%s][/color]" % [hex, GameData.item_display_name(item)])
	return true

func equip_from_inventory(idx: int) -> void:
	if idx < 0 or idx >= inventory.size():
		return
	var item: Dictionary = inventory[idx]
	var slot: String = str(item["slot"])
	var prev: Dictionary = equipment.get(slot, {})
	equipment[slot] = item
	inventory.remove_at(idx)
	if not prev.is_empty():
		inventory.append(prev)
	recalc_stats()
	_rebuild_rig()
	SoundFX.play("equip")

func salvage_inventory_item(idx: int) -> void:
	if idx < 0 or idx >= inventory.size():
		return
	var item: Dictionary = inventory[idx]
	var r: int = int(item.get("rarity", 0))
	var gain_sh: int = 1 + r * 2
	shards += gain_sh
	inventory.remove_at(idx)
	SoundFX.play("loot")
	main_ref.log_chat("[color=#66ddff]Разобрано '%s' -> +%d Осколков.[/color]" % [GameData.item_display_name(item), gain_sh])
