extends CharacterBody3D

const MeshBuilder3D = preload("res://scripts/MeshBuilder3D.gd")

var main_ref: Node = null
var template_id: String = "wolf"
var zone_id: String = "elwynn"
var home_pos: Vector3 = Vector3.ZERO
var is_instance_mob: bool = false

var mob_name: String = "Враг"
var level: int = 1
var max_hp: float = 60.0
var hp: float = 60.0
var atk: float = 8.0
var xp_reward: int = 35
var gold_reward: int = 5
var move_speed: float = 4.0
var body_col: Color = Color.RED
var shape_type: String = "beast"
var is_boss: bool = false
var is_ranged: bool = false

var is_dead: bool = false
var respawn_timer: float = 0.0
var aggro_target: Node3D = null
var returning_home: bool = false
var atk_cd: float = 0.0
var special_cd: float = 4.5
var telegraph_timer: float = 0.0
var telegraph_pos: Vector3 = Vector3.ZERO
var telegraph_ring: MeshInstance3D = null

var stun_timer: float = 0.0
var slow_timer: float = 0.0
var burn_timer: float = 0.0
var burn_dps: float = 0.0
var burn_tick: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var wander_wait: float = 1.5
var anim_t: float = 0.0
var hit_flash: float = 0.0

var rig: Dictionary = {}

func setup(main_node: Node, p_tid: String, p_home: Vector3, p_zone: String, inst_mob: bool = false) -> void:
	main_ref = main_node
	template_id = p_tid
	home_pos = p_home if inst_mob else Vector3(p_home.x, maxf(GameData.WATER_Y, GameData.get_terrain_height(p_home.x, p_home.z)), p_home.z)
	zone_id = p_zone
	is_instance_mob = inst_mob
	position = home_pos
	wander_target = home_pos

	var tpl: Dictionary = GameData.MOBS[p_tid]
	mob_name = str(tpl["name"])
	level = int(tpl["lv"])
	max_hp = float(tpl["hp"])
	hp = max_hp
	atk = float(tpl["atk"])
	xp_reward = int(tpl["xp"])
	gold_reward = int(tpl["gold"])
	move_speed = float(tpl["speed"])
	body_col = tpl["col"]
	shape_type = str(tpl["shape"])
	is_boss = bool(tpl["boss"])
	is_ranged = bool(tpl["ranged"])

	rig = MeshBuilder3D.build_mob_rig(shape_type, body_col, is_boss)
	add_child(rig["root"])

	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = 0.9 if is_boss else 0.5
	cap.height = 2.4 if is_boss else 1.5
	col_shape.shape = cap
	col_shape.position = Vector3(0, cap.height * 0.5, 0)
	add_child(col_shape)

	if is_boss:
		var tr: TorusMesh = TorusMesh.new()
		tr.inner_radius = 4.4
		tr.outer_radius = 4.9
		telegraph_ring = MeshInstance3D.new()
		telegraph_ring.mesh = tr
		telegraph_ring.material_override = MeshBuilder3D.make_mat(Color(1.0, 0.2, 0.1), 0, 0.3, Color(1.0, 0.15, 0.05), 2.2, 0.85)
		telegraph_ring.visible = false
		add_child(telegraph_ring)

	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(main_ref) or not is_instance_valid(main_ref.world_3d) or not is_instance_valid(main_ref.player):
		return

	var pl: Node3D = main_ref.player
	var dist_pl: float = position.distance_to(pl.position)
	var active_here: bool = (main_ref.world_3d.in_instance == is_instance_mob)
	visible = active_here and not is_dead and (is_instance_mob or dist_pl < 72.0)
	if not active_here:
		return

	if is_dead:
		if not is_instance_mob:
			respawn_timer -= delta
			if respawn_timer <= 0.0:
				_respawn()
		return

	if not is_instance_valid(main_ref.player):
		return

	_animate_special_parts(delta)
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - delta * 6.0)
		if rig.has("body_pivot") and is_instance_valid(rig["body_pivot"]):
			var s: float = (1.95 if is_boss else 1.0) * (1.0 + hit_flash * 0.14)
			rig["body_pivot"].scale = Vector3.ONE * s

	if not is_instance_mob and dist_pl > 52.0 and aggro_target == null:
		return

	_update_statuses(delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	special_cd = maxf(0.0, special_cd - delta)

	if returning_home:
		hp = minf(max_hp, hp + max_hp * 0.45 * delta)
		var dir_home: Vector3 = home_pos - position
		dir_home.y = 0.0
		if dir_home.length() < 1.2:
			returning_home = false
			hp = max_hp
		else:
			_move_step(dir_home.normalized(), move_speed * 1.6, delta)
		return

	if stun_timer > 0.0:
		if is_instance_valid(telegraph_ring):
			telegraph_ring.visible = false
			telegraph_timer = 0.0
		return

	# Телеграфируемая AoE атака босса!
	if telegraph_timer > 0.0:
		telegraph_timer -= delta
		if is_instance_valid(telegraph_ring):
			telegraph_ring.global_position = Vector3(telegraph_pos.x, 0.12, telegraph_pos.z)
			telegraph_ring.visible = true
			var pulse: float = 0.85 + sin(Time.get_ticks_msec() * 0.025) * 0.15
			telegraph_ring.scale = Vector3(pulse, 1.0, pulse)
		if telegraph_timer <= 0.0:
			if is_instance_valid(telegraph_ring):
				telegraph_ring.visible = false
			_detonate_boss_aoe()
		return

	# Проверка агра
	if aggro_target == null and not pl.dead:
		var aggro_range: float = 11.5 if is_boss else (7.8 if level >= pl.level - 4 else 4.0)
		if is_instance_mob:
			aggro_range = 13.0
		if dist_pl < aggro_range:
			aggro_target = pl

	if is_instance_valid(aggro_target):
		if aggro_target == pl and pl.dead:
			aggro_target = null
			returning_home = true
			return

		var leash: float = 28.0 if is_instance_mob else (22.0 if not is_boss else 28.0)
		if position.distance_to(home_pos) > leash:
			aggro_target = null
			returning_home = true
			return

		var d_tgt: float = position.distance_to(aggro_target.position)
		var atk_range: float = 9.0 if is_ranged else (2.9 if is_boss else 2.2)

		# Способность босса
		if is_boss and special_cd <= 0.0 and d_tgt < 11.0:
			special_cd = 6.2
			telegraph_pos = aggro_target.position
			telegraph_timer = 1.35
			main_ref.vfx.spawn_text(position, "МОЩНЫЙ УДАР!", Color(1.0, 0.3, 0.2), 16)
			SoundFX.play("boss")
			return

		if d_tgt > atk_range:
			var spd_m: float = 0.55 if slow_timer > 0.0 else 1.0
			var dir: Vector3 = aggro_target.position - position
			dir.y = 0.0
			_move_step(dir.normalized(), move_speed * spd_m, delta)
		else:
			_face_dir(aggro_target.position - position, delta)
			if atk_cd <= 0.0:
				atk_cd = 1.35 if is_boss else 1.5
				_perform_attack(aggro_target)
	else:
		# Патруль
		if position.distance_to(wander_target) < 0.8:
			wander_wait -= delta
			if wander_wait <= 0.0:
				wander_wait = randf_range(1.5, 4.0)
				var ang: float = randf() * TAU
				var r: float = randf_range(2.0, 6.0)
				wander_target = home_pos + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		else:
			var dir_w: Vector3 = wander_target - position
			dir_w.y = 0.0
			_move_step(dir_w.normalized(), move_speed * 0.45, delta)

func _animate_special_parts(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	if rig.has("orbiters"):
		for i in range(rig["orbiters"].size()):
			var orb: Node3D = rig["orbiters"][i]
			if is_instance_valid(orb):
				orb.rotate_y(delta * (2.2 + float(i) * 0.4))
	if rig.has("wings") and rig["wings"].size() == 2:
		var wl: Node3D = rig["wings"][0]
		var wr: Node3D = rig["wings"][1]
		var flap: float = sin(t * 5.2) * 0.35
		if is_instance_valid(wl):
			wl.rotation.z = flap
		if is_instance_valid(wr):
			wr.rotation.z = -flap

func _move_step(dir: Vector3, spd: float, delta: float) -> void:
	position += dir * spd * delta
	position.y = 0.0 if is_instance_mob else maxf(GameData.WATER_Y, GameData.get_terrain_height(position.x, position.z))
	_face_dir(dir, delta)
	anim_t += delta * spd * 2.2
	if rig.has("body_pivot") and is_instance_valid(rig["body_pivot"]):
		var bp: Node3D = rig["body_pivot"]
		bp.position.y = abs(sin(anim_t)) * 0.14

func _face_dir(dir: Vector3, delta: float) -> void:
	var flat: Vector3 = Vector3(dir.x, 0.0, dir.z)
	if flat.length() > 0.01 and rig.has("body_pivot") and is_instance_valid(rig["body_pivot"]):
		var target_yaw: float = atan2(flat.x, flat.z)
		var bp: Node3D = rig["body_pivot"]
		bp.rotation.y = lerp_angle(bp.rotation.y, target_yaw, minf(1.0, delta * 10.0))

func _perform_attack(tgt: Node3D) -> void:
	if is_ranged:
		main_ref.vfx.spawn_proj(position, tgt.position, body_col.lightened(0.25), 0.22, 16.0)
	if tgt.has_method("take_damage"):
		tgt.take_damage(atk, self)

func _detonate_boss_aoe() -> void:
	main_ref.vfx.spawn_ring(telegraph_pos, 4.8, body_col, 0.55)
	var pl: Node3D = main_ref.player
	if is_instance_valid(pl) and not pl.dead and pl.position.distance_to(telegraph_pos) <= 4.9:
		pl.take_damage(atk * 2.1, self)
	for b in main_ref.party_bots:
		if is_instance_valid(b) and b.position.distance_to(telegraph_pos) <= 4.9:
			b.take_damage(atk * 1.6)

func _update_statuses(delta: float) -> void:
	stun_timer = maxf(0.0, stun_timer - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick -= delta
		if burn_tick <= 0.0:
			burn_tick = 0.75
			take_damage(burn_dps, false, false)

func take_damage(amount: float, is_crit: bool = false, trigger_aggro: bool = true, attacker: Node3D = null) -> void:
	if is_dead:
		return
	var dmg: float = maxf(1.0, round(amount))
	hp -= dmg
	hit_flash = 1.0
	if is_crit:
		main_ref.vfx.spawn_burst(position, Color(1.0, 0.8, 0.2), 7)
	if trigger_aggro and aggro_target == null:
		aggro_target = attacker if is_instance_valid(attacker) else main_ref.player
	var col: Color = Color(1.0, 0.85, 0.2) if is_crit else Color(1.0, 0.95, 0.85)
	var txt: String = ("КРИТ %d!" % int(dmg)) if is_crit else str(int(dmg))
	main_ref.vfx.spawn_text(position, txt, col, 17 if is_crit else 14)

	if hp <= 0.0:
		_die()

func apply_stun(dur: float) -> void:
	stun_timer = maxf(stun_timer, dur)
	main_ref.vfx.spawn_text(position, "ОГЛУШЕН", Color(0.7, 0.9, 1.0), 13)

func apply_slow(dur: float) -> void:
	slow_timer = maxf(slow_timer, dur)

func apply_burn(dps: float, dur: float) -> void:
	burn_dps = maxf(burn_dps, dps)
	burn_timer = maxf(burn_timer, dur)

func _die() -> void:
	is_dead = true
	visible = false
	main_ref.vfx.spawn_burst(position, body_col.lightened(0.2), 14 if is_boss else 8)
	if is_instance_valid(telegraph_ring):
		telegraph_ring.visible = false
	telegraph_timer = 0.0
	aggro_target = null
	returning_home = false
	respawn_timer = 40.0 if is_boss else 20.0

	if is_instance_valid(main_ref.player):
		var pl: Node3D = main_ref.player
		if pl.target == self:
			pl.target = null
		pl.on_enemy_killed(template_id, xp_reward, gold_reward, is_boss)

	# Дроп на землю
	var drop_chance: float = 1.0 if is_boss else 0.48
	if randf() <= drop_chance:
		var forced_r: int = -1
		if is_boss:
			forced_r = 3 if is_instance_mob else (2 if level < 30 else 3)
			if level >= 52:
				forced_r = 4 if randf() < 0.42 else 3
		var item: Dictionary = GameData.generate_item(level, forced_r)
		main_ref.spawn_loot(position, item, 0, is_instance_mob)

	if is_instance_mob and is_boss:
		main_ref.on_instance_boss_killed(self)

func _respawn() -> void:
	is_dead = false
	visible = true
	hp = max_hp
	stun_timer = 0.0
	slow_timer = 0.0
	burn_timer = 0.0
	position = home_pos
	wander_target = home_pos
