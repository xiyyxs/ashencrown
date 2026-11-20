extends Control

var main_ref: Node = null

func _process(_delta: float) -> void:
	queue_redraw()

func _proj(pos3d: Vector3) -> Variant:
	if not is_instance_valid(main_ref) or not is_instance_valid(main_ref.player):
		return null
	var cam: Camera3D = main_ref.player.camera
	if not is_instance_valid(cam) or cam.is_position_behind(pos3d):
		return null
	var sv: SubViewport = main_ref.sub_viewport
	if not is_instance_valid(sv) or sv.size.x <= 0:
		return null
	var p2d: Vector2 = cam.unproject_position(pos3d)
	var scale_v: Vector2 = size / Vector2(sv.size)
	return p2d * scale_v

func _draw() -> void:
	if not is_instance_valid(main_ref) or not main_ref.game_started:
		return
	var pl: Node3D = main_ref.player
	if not is_instance_valid(pl):
		return
	var font: Font = PixelArt.retro_font
	var in_inst: bool = main_ref.world_3d.in_instance

	# 1. NPC в открытом мире
	if not in_inst:
		for n in main_ref.npcs:
			if not is_instance_valid(n) or n.position.distance_to(pl.position) > 30.0:
				continue
			var sp: Variant = _proj(n.position + Vector3(0, 2.25, 0))
			if sp == null:
				continue
			var p: Vector2 = sp
			draw_string(font, p + Vector2(-69, -13), n.npc_name, HORIZONTAL_ALIGNMENT_CENTER, 140, 12, Color(0, 0, 0, 0.9))
			draw_string(font, p + Vector2(-70, -14), n.npc_name, HORIZONTAL_ALIGNMENT_CENTER, 140, 12, Color(1.0, 0.96, 0.76))
			draw_string(font, p + Vector2(-69, -1), n.get_role_tag(), HORIZONTAL_ALIGNMENT_CENTER, 140, 11, Color(0, 0, 0, 0.9))
			draw_string(font, p + Vector2(-70, -2), n.get_role_tag(), HORIZONTAL_ALIGNMENT_CENTER, 140, 11, n.body_col)
			var m: String = n.get_quest_marker(pl)
			if m != "":
				var bob: float = sin(Time.get_ticks_msec() * 0.007) * 4.0
				var mcol: Color = Color(1.0, 0.88, 0.15) if m != "..." else Color(0.75, 0.75, 0.75)
				draw_string(font, p + Vector2(-19, -27 + bob), m, HORIZONTAL_ALIGNMENT_CENTER, 40, 22, Color(0, 0, 0, 0.95))
				draw_string(font, p + Vector2(-20, -28 + bob), m, HORIZONTAL_ALIGNMENT_CENTER, 40, 22, mcol)

	# 2. Боты / Группа рейда
	var bot_list: Array = main_ref.party_bots if in_inst else main_ref.bots
	for b in bot_list:
		if not is_instance_valid(b) or b.position.distance_to(pl.position) > 32.0:
			continue
		var spb: Variant = _proj(b.position + Vector3(0, 2.15, 0))
		if spb == null:
			continue
		var pb: Vector2 = spb
		var tag_col: Color = Color(0.45, 0.96, 1.0) if b.is_party_bot else Color(0.45, 0.95, 0.58)
		draw_string(font, pb + Vector2(-80, -8), "[%d] %s" % [b.level, b.bot_name], HORIZONTAL_ALIGNMENT_CENTER, 160, 11, tag_col)

	# 3. Враги и Боссы
	for e in main_ref.get_active_enemies():
		if not is_instance_valid(e) or e.is_dead or e.position.distance_to(pl.position) > 34.0:
			continue
		var h_off: float = 3.2 if e.is_boss else 2.05
		var spe: Variant = _proj(e.position + Vector3(0, h_off, 0))
		if spe == null:
			continue
		var pe: Vector2 = spe
		var bw: float = 78.0 if e.is_boss else 46.0
		var bh: float = 6.0 if e.is_boss else 5.0
		var ratio: float = clampf(e.hp / maxf(1.0, e.max_hp), 0.0, 1.0)
		draw_rect(Rect2(pe.x - bw * 0.5 - 1, pe.y - 1, bw + 2, bh + 2), Color(0.05, 0.04, 0.06, 0.95), true)
		var bar_c: Color = Color(0.95, 0.25, 0.18) if e.is_boss else Color(0.86, 0.28, 0.22)
		draw_rect(Rect2(pe.x - bw * 0.5, pe.y, bw * ratio, bh), bar_c, true)
		if pl.target == e:
			draw_rect(Rect2(pe.x - bw * 0.5 - 2, pe.y - 2, bw + 4, bh + 4), Color(1.0, 0.9, 0.25), false, 1.5)
		if e.is_boss or pl.target == e or e.hp < e.max_hp:
			var ncol: Color = Color(1.0, 0.55, 0.25) if e.is_boss else Color(0.96, 0.88, 0.78)
			draw_string(font, pe + Vector2(-95, -6), "[%d] %s" % [e.level, e.mob_name], HORIZONTAL_ALIGNMENT_CENTER, 190, 11, ncol)

	# 4. Лут на земле
	for l in get_tree().get_nodes_in_group("loot"):
		if not is_instance_valid(l) or l.is_instance_drop != in_inst:
			continue
		if l.position.distance_to(pl.position) > 26.0:
			continue
		var spl: Variant = _proj(l.position + Vector3(0, 1.0, 0))
		if spl == null:
			continue
		var pl_pos: Vector2 = spl
		var txt: String = l.get_label()
		draw_rect(Rect2(pl_pos.x - 62, pl_pos.y - 14, 124, 15), Color(0.06, 0.05, 0.08, 0.82), true)
		draw_rect(Rect2(pl_pos.x - 62, pl_pos.y - 14, 124, 15), l.rarity_col, false, 1.0)
		draw_string(font, pl_pos + Vector2(-60, -2), txt, HORIZONTAL_ALIGNMENT_CENTER, 120, 11, l.rarity_col)

	# 4.5 Сундуки сокровищ и квестовые объекты
	for ch in get_tree().get_nodes_in_group("chests"):
		if not is_instance_valid(ch) or ch.is_opened or ch.is_instance_chest != in_inst:
			continue
		if ch.position.distance_to(pl.position) > 26.0:
			continue
		var spc: Variant = _proj(ch.position + Vector3(0, 1.1, 0))
		if spc == null:
			continue
		var pc: Vector2 = spc
		draw_string(font, pc + Vector2(-50, -4), "[E] Сундук", HORIZONTAL_ALIGNMENT_CENTER, 100, 11, Color(1.0, 0.88, 0.30))

	if not in_inst:
		for qn in get_tree().get_nodes_in_group("quest_nodes"):
			if not is_instance_valid(qn) or qn.is_collected or qn.position.distance_to(pl.position) > 26.0:
				continue
			var spq: Variant = _proj(qn.position + Vector3(0, 1.0, 0))
			if spq == null:
				continue
			var pq: Vector2 = spq
			draw_string(font, pq + Vector2(-60, -4), "[E] " + qn.node_label, HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color(0.55, 0.98, 0.65))

	# 5. Всплывающий урон / лечение / опыт
	for ft in main_ref.vfx.float_texts:
		var spf: Variant = _proj(ft["pos"])
		if spf == null:
			continue
		var pf: Vector2 = spf
		var alpha: float = clampf(float(ft["life"]) / float(ft["max_life"]), 0.0, 1.0)
		var c: Color = ft["col"]
		c.a = alpha
		draw_string(font, pf + Vector2(-70, 1), str(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, 140, int(ft["size"]), Color(0, 0, 0, alpha))
		draw_string(font, pf + Vector2(-71, 0), str(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, 140, int(ft["size"]), c)
