extends Control

var main_ref: Node = null

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.06, 0.08, 0.96), true)
	if not is_instance_valid(main_ref) or not is_instance_valid(main_ref.player) or not is_instance_valid(main_ref.world_3d):
		return

	var pl: Node3D = main_ref.player
	if main_ref.world_3d.in_instance:
		var sx: float = size.x / 28.0
		var sz: float = size.y / 68.0
		draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Color(0.18, 0.16, 0.20), true)
		draw_rect(Rect2(size.x * 0.42, 6, size.x * 0.16, size.y - 12), Color(0.45, 0.14, 0.14), true)
		draw_rect(Rect2((-7.5 + 14.0) * sx - 3, (5.0 + 58.0) * sz - 3, 6, 6), Color(0.3, 1.0, 0.5), true)
		for e in main_ref.instance_enemies:
			if is_instance_valid(e) and not e.is_dead:
				var ex: float = (e.position.x + 14.0) * sx
				var ez: float = (e.position.z + 58.0) * sz
				var col: Color = Color(1.0, 0.2, 0.2) if e.is_boss else Color(1.0, 0.55, 0.25)
				var r: float = 4.0 if e.is_boss else 2.0
				draw_rect(Rect2(ex - r, ez - r, r * 2.0, r * 2.0), col, true)
		for b in main_ref.party_bots:
			if is_instance_valid(b):
				var bx: float = (b.position.x + 14.0) * sx
				var bz: float = (b.position.z + 58.0) * sz
				draw_rect(Rect2(bx - 2, bz - 2, 4, 4), Color(0.35, 0.95, 0.55), true)
		var px: float = (pl.position.x + 14.0) * sx
		var pz: float = (pl.position.z + 58.0) * sz
		draw_rect(Rect2(px - 3, pz - 3, 6, 6), Color(1.0, 0.96, 0.4), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.60, 0.28), false, 2.0)
		return

	# Локальная миникарта вокруг игрока
	var view_w: float = 150.0
	var view_h: float = 92.0
	var min_x: float = clampf(pl.position.x - view_w * 0.5, 0.0, GameData.WORLD_W - view_w)
	var min_z: float = clampf(pl.position.z - view_h * 0.5, 0.0, GameData.WORLD_H - view_h)

	if PixelArt.world_map_tex != null:
		var tw: float = float(PixelArt.world_map_tex.get_width())
		var th: float = float(PixelArt.world_map_tex.get_height())
		var src: Rect2 = Rect2(
			(min_x / GameData.WORLD_W) * tw,
			(min_z / GameData.WORLD_H) * th,
			(view_w / GameData.WORLD_W) * tw,
			(view_h / GameData.WORLD_H) * th
		)
		draw_texture_rect_region(PixelArt.world_map_tex, Rect2(Vector2.ZERO, size), src)

	var sx_m: float = size.x / view_w
	var sz_m: float = size.y / view_h

	# Ориентиры и города
	for z in GameData.ZONES:
		var hub: Vector3 = z["hub"]
		if hub.x >= min_x and hub.x <= min_x + view_w and hub.z >= min_z and hub.z <= min_z + view_h:
			var hx: float = (hub.x - min_x) * sx_m
			var hz: float = (hub.z - min_z) * sz_m
			draw_rect(Rect2(hx - 4, hz - 4, 8, 8), Color(1.0, 0.88, 0.30), true)
		for lm in z["landmarks"]:
			var lp: Vector3 = lm["pos"]
			if lp.x >= min_x and lp.x <= min_x + view_w and lp.z >= min_z and lp.z <= min_z + view_h:
				var lx: float = (lp.x - min_x) * sx_m
				var lz: float = (lp.z - min_z) * sz_m
				draw_rect(Rect2(lx - 3, lz - 3, 6, 6), Color(0.85, 0.72, 0.98), false, 1.5)

	# NPC
	for n in main_ref.npcs:
		if is_instance_valid(n):
			var nx: float = (n.position.x - min_x) * sx_m
			var nz: float = (n.position.z - min_z) * sz_m
			if nx >= 0 and nx <= size.x and nz >= 0 and nz <= size.y:
				draw_rect(Rect2(nx - 2, nz - 2, 4, 4), n.body_col, true)

	# Сундуки и квестовые объекты
	for ch in get_tree().get_nodes_in_group("chests"):
		if is_instance_valid(ch) and not ch.is_opened and not ch.is_instance_chest:
			var cx: float = (ch.position.x - min_x) * sx_m
			var cz: float = (ch.position.z - min_z) * sz_m
			if cx >= 0 and cx <= size.x and cz >= 0 and cz <= size.y:
				draw_rect(Rect2(cx - 2, cz - 2, 4, 4), Color(1.0, 0.85, 0.15), true)

	# ИИ-игроки
	for b in main_ref.bots:
		if is_instance_valid(b):
			var bx: float = (b.position.x - min_x) * sx_m
			var bz: float = (b.position.z - min_z) * sz_m
			if bx >= 0 and bx <= size.x and bz >= 0 and bz <= size.y:
				draw_rect(Rect2(bx - 2, bz - 2, 4, 4), Color(0.3, 0.95, 0.55), true)

	# Враги
	for e in main_ref.enemies:
		if is_instance_valid(e) and not e.is_dead:
			var ex: float = (e.position.x - min_x) * sx_m
			var ez: float = (e.position.z - min_z) * sz_m
			if ex >= 0 and ex <= size.x and ez >= 0 and ez <= size.y:
				var ecol: Color = Color(1.0, 0.2, 0.2) if e.is_boss else Color(1.0, 0.55, 0.25)
				var r: float = 3.0 if e.is_boss else 1.5
				draw_rect(Rect2(ex - r, ez - r, r * 2.0, r * 2.0), ecol, true)

	# Игрок
	var plx: float = (pl.position.x - min_x) * sx_m
	var plz: float = (pl.position.z - min_z) * sz_m
	draw_rect(Rect2(plx - 3, plz - 3, 6, 6), Color.WHITE, true)
	draw_rect(Rect2(plx - 2, plz - 2, 4, 4), Color(0.25, 0.95, 1.0), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.60, 0.28), false, 2.0)
