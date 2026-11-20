extends Node

var vp_container: SubViewportContainer
var sub_viewport: SubViewport
var world_3d: Node3D
var vfx: Node3D
var player: CharacterBody3D
var hud: CanvasLayer

var enemies: Array = []
var instance_enemies: Array = []
var npcs: Array = []
var bots: Array = []
var party_bots: Array = []

var game_started: bool = false
var autosave_timer: float = 60.0
var bot_chat_timer: float = 14.0
var return_world_pos: Vector3 = Vector3(20.0, 0.0, 24.0)

const BOT_CHAT_LINES: Array = [
	"Ищу танка и лекаря в Разлом Пепла на Игнисара!",
	"Кто знает, где бродит Костяной Мясник в Сумеречном лесу?",
	"Ура! Выбил эпический клинок с Капитана Красного Паруса!",
	"Отправляюсь в Кремнеград к кузнецу перековать латы.",
	"Фармим Архилича Мортиса в Чумных землях, присоединяйтесь!",
	"Воин через Вихрь и Вампиризм просто машина!",
	"Собираю отряд в Престол Вечной Зимы!"
]

func _enter_tree() -> void:
	_register_inputs()

func _ready() -> void:
	_setup_pixel_viewport()

	world_3d = Node3D.new()
	world_3d.set_script(load("res://scripts/World3D.gd"))
	sub_viewport.add_child(world_3d)

	vfx = Node3D.new()
	vfx.set_script(load("res://scripts/VFX3D.gd"))
	vfx.main_ref = self
	sub_viewport.add_child(vfx)

	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/Player3D.gd"))
	player.main_ref = self
	sub_viewport.add_child(player)

	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/HUD.gd"))
	add_child(hud)
	hud.build_ui(self)

	_spawn_world_entities()
	# Позиция камеры на стартовом экране (живой обзор лагеря!)
	player.position = GameData.ZONES[0]["hub"] + Vector3(0.0, 0.0, 4.5)
	player.position.y = GameData.get_terrain_height(player.position.x, player.position.z)
	player._update_camera(1.0)
	SoundFX.play_music("lobby")

func _setup_pixel_viewport() -> void:
	vp_container = SubViewportContainer.new()
	vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_container.stretch = true
	vp_container.stretch_shrink = 4 # 960x720 -> 240x180 сверх-пиксельный 3D рендер!
	vp_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vp_container)

	var sh: Shader = Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float px_scale = 4.0;
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 px = floor(FRAGCOORD.xy / px_scale);
	int x = int(mod(px.x, 4.0));
	int y = int(mod(px.y, 4.0));
	int idx = x + y * 4;
	float b = 0.0;
	if (idx == 0) b = 0.0; else if (idx == 1) b = 8.0; else if (idx == 2) b = 2.0; else if (idx == 3) b = 10.0;
	else if (idx == 4) b = 12.0; else if (idx == 5) b = 4.0; else if (idx == 6) b = 14.0; else if (idx == 7) b = 6.0;
	else if (idx == 8) b = 3.0; else if (idx == 9) b = 11.0; else if (idx == 10) b = 1.0; else if (idx == 11) b = 9.0;
	else if (idx == 12) b = 15.0; else if (idx == 13) b = 7.0; else if (idx == 14) b = 13.0; else b = 5.0;
	float dither = (b / 16.0 - 0.5) / 22.0;
	vec3 q = floor((col.rgb + dither) * 22.0 + 0.5) / 22.0;
	COLOR = vec4(clamp(q, 0.0, 1.0), col.a);
}
"""
	var smat: ShaderMaterial = ShaderMaterial.new()
	smat.shader = sh
	vp_container.material = smat

	sub_viewport = SubViewport.new()
	sub_viewport.msaa_3d = Viewport.MSAA_DISABLED
	sub_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	sub_viewport.use_occlusion_culling = false
	vp_container.add_child(sub_viewport)

func toggle_pixel_resolution() -> void:
	vp_container.stretch_shrink = 3 if vp_container.stretch_shrink == 4 else 4
	if vp_container.material is ShaderMaterial:
		vp_container.material.set_shader_parameter("px_scale", float(vp_container.stretch_shrink))
	SoundFX.play("ui")

func start_game(p_name: String, p_cls: String, p_race: String = "human") -> void:
	player.init_new(p_name, p_cls, p_race)
	GameData.save_character(player.export_to_dict())
	game_started = true
	SoundFX.play_music("elwynn")
	log_chat("[color=#ffdd55]Добро пожаловать в Пепельную Корону, %s![/color]" % player.char_name)

func load_character_from_dict(d: Dictionary) -> void:
	if d.is_empty():
		return
	player.load_from_dict(d)
	game_started = true
	var z: Dictionary = GameData.get_zone_at(player.position)
	SoundFX.play_music(str(z["id"]))
	log_chat("[color=#55ff88]%s (Ур. %d) возвращается в земли Короны.[/color]" % [player.char_name, player.level])

func return_to_char_select() -> void:
	if world_3d.in_instance:
		exit_dungeon_instance()
	if game_started and is_instance_valid(player):
		GameData.save_character(player.export_to_dict())
	game_started = false
	SoundFX.play_music("lobby")
	player.target = null
	player.click_move_active = false
	player.auto_attack_on = false
	player.position = GameData.ZONES[0]["hub"] + Vector3(0.0, 0.0, 4.5)
	player.position.y = GameData.get_terrain_height(player.position.x, player.position.z)
	player._update_camera(1.0)
	if is_instance_valid(hud):
		hud.close_modal()
		hud.show_char_select()

func save_now() -> void:
	if not game_started:
		return
	if GameData.save_character(player.export_to_dict()):
		log_chat("[color=#66ff88]Персонаж сохранён.[/color]")
		vfx.spawn_text(player.position, "СОХРАНЕНО!", Color(0.4, 1.0, 0.6), 16)

func _pick_zone_land_spot(z: Dictionary, min_hub_dist: float = 20.0) -> Vector3:
	var c: Vector2 = z["center"]
	var hub: Vector3 = z["hub"]
	var bpos: Vector3 = z["boss_pos"]
	var zid: String = str(z["id"])
	for _t in range(40):
		var px: float = clampf(c.x + randf_range(-115.0, 115.0), 12.0, GameData.WORLD_W - 12.0)
		var pz: float = clampf(c.y + randf_range(-105.0, 105.0), 12.0, GameData.WORLD_H - 12.0)
		if not GameData.is_land(px, pz):
			continue
		if GameData.get_terrain_height(px, pz) < GameData.WATER_Y + 0.45:
			continue
		var p: Vector3 = Vector3(px, 0.0, pz)
		if p.distance_to(hub) < min_hub_dist or p.distance_to(bpos) < 14.0:
			continue
		if str(GameData.get_zone_at(p)["id"]) != zid:
			continue
		return p
	return hub + Vector3(min_hub_dist + 4.0, 0.0, 4.0)

func _spawn_world_entities() -> void:
	var NPCScript: Script = load("res://scripts/NPC3D.gd")
	var EnemyScript: Script = load("res://scripts/Enemy3D.gd")
	var BotScript: Script = load("res://scripts/BotPlayer3D.gd")

	var q_names: Array = ["Командир Маркус", "Следопыт Вейн", "Сотник Гром", "Тан Бронзобород", "Инквизитор Тирион", "Верховный маг Кадгар"]
	var v_names: Array = ["Торговец Боб", "Лавочница Мара", "Купец Гриз", "Торговец Торн", "Алхимик Сильвия", "Интендант Аш"]
	var inn_names: Array = ["Трактирщик Ганс", "Хозяйка Грета", "Трактирщик Орк-Ок", "Пивовар Барни", "Хранительница Элен", "Трактирщик Мор"]
	var field_npcs: Dictionary = {
		"elwynn": [
			["Бригадир Харт", Vector3(107.6, 0.0, 161.6), "elwynn_f1", -0.8],
			["Дозорный Гарольд", Vector3(125.6, 0.0, 323.5), "elwynn_f2", 2.2]
		],
		"duskwood": [
			["Могильщик Эдгар", Vector3(283.6, 0.0, 355.6), "duskwood_f1", -1.1],
			["Охотник Торин", Vector3(237.6, 0.0, 343.6), "duskwood_f2", 0.5]
		],
		"barrens": [
			["Следопыт Зарк", Vector3(445.6, 0.0, 187.5), "barrens_f1", -0.4],
			["Гладиатор Кранг", Vector3(497.5, 0.0, 233.6), "barrens_f2", 1.8]
		],
		"frostpeak": [
			["Разведчик Свен", Vector3(285.5, 0.0, 75.5), "frostpeak_f1", -0.6],
			["Хранительница Фрейя", Vector3(273.5, 0.0, 139.6), "frostpeak_f2", 2.5]
		],
		"plaguelands": [
			["Алхимик Годрик", Vector3(483.5, 0.0, 139.6), "plaguelands_f1", -1.4],
			["Рыцарь Дарион", Vector3(557.6, 0.0, 137.5), "plaguelands_f2", 1.2]
		],
		"citadel": [
			["Кузнец Малгор", Vector3(597.5, 0.0, 343.5), "citadel_f1", -2.1],
			["Архимаг Северин", Vector3(543.5, 0.0, 387.5), "citadel_f2", 0.7]
		]
	}

	for i in range(GameData.ZONES.size()):
		var z: Dictionary = GameData.ZONES[i]
		var hub: Vector3 = z["hub"]
		var zid: String = str(z["id"])

		# Городские НПС расставлены у своих построек (Крепость, Таверна, Лавка, Кузница, Врата),
		# а полевые квестодатели дежурят в заставных лагерях по всему региону!
		var npc_defs: Array = [
			[str(q_names[i]), "quest", hub + Vector3(-2.6, 0.0, -3.6), zid + "_cmd", 0.3],
			[str(inn_names[i]), "innkeeper", hub + Vector3(5.6, 0.0, -4.3), "", 0.0],
			[str(v_names[i]), "vendor", hub + Vector3(3.8, 0.0, 3.3), "", -0.4],
			["Кузнец-мастер", "smith", hub + Vector3(-5.8, 0.0, 2.8), "", 1.2],
			["Вестник Походов", "dungeon", hub + Vector3(7.4, 0.0, -0.4), "", -1.3]
		]
		for fn in field_npcs.get(zid, []):
			npc_defs.append([fn[0], "quest", fn[1], fn[2], fn[3]])

		for nd in npc_defs:
			var n: Node3D = Node3D.new()
			n.set_script(NPCScript)
			n.setup(self, str(nd[0]), str(nd[1]), zid, Vector3(nd[2]), str(nd[3]), float(nd[4]))
			world_3d.open_world_root.add_child(n)
			npcs.append(n)

		# Стаи мобов вокруг ориентиров + бродячие мобы на суше региона
		var mob_pool: Array = z["mobs"]
		var bpos: Vector3 = z["boss_pos"]

		for lm in z["landmarks"]:
			var lpos: Vector3 = lm["pos"]
			var lmob: String = str(lm["mob"])
			for k in range(10):
				var mpos: Vector3 = lpos + Vector3(10.0, 0.0, 0.0)
				for _attempt in range(12):
					var ang: float = float(k) * TAU / 10.0 + randf_range(-0.3, 0.3)
					var rad: float = randf_range(5.0, 20.0)
					var cand: Vector3 = lpos + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
					if GameData.is_land(cand.x, cand.z) and GameData.get_terrain_height(cand.x, cand.z) > GameData.WATER_Y + 0.35:
						mpos = cand
						break
				var e: CharacterBody3D = CharacterBody3D.new()
				e.set_script(EnemyScript)
				e.setup(self, lmob, mpos, zid, false)
				sub_viewport.add_child(e)
				enemies.append(e)

		for m_idx in range(20):
			var pos: Vector3 = _pick_zone_land_spot(z, 22.0)
			var tid: String = str(mob_pool[m_idx % mob_pool.size()])
			var e: CharacterBody3D = CharacterBody3D.new()
			e.set_script(EnemyScript)
			e.setup(self, tid, pos, zid, false)
			sub_viewport.add_child(e)
			enemies.append(e)

		# Босс зоны
		var boss: CharacterBody3D = CharacterBody3D.new()
		boss.set_script(EnemyScript)
		boss.setup(self, str(z["boss"]), bpos, zid, false)
		sub_viewport.add_child(boss)
		enemies.append(boss)

		# 6 сундуков сокровищ + 10 квестовых объектов сбора в зоне
		var ChestScript: Script = load("res://scripts/Chest3D.gd")
		for ci in range(6):
			var cpos: Vector3 = _pick_zone_land_spot(z, 20.0)
			var ch: Node3D = Node3D.new()
			ch.set_script(ChestScript)
			ch.setup(self, cpos, int(z["min_lv"]) + 2 + ci * 2, zid, false)
			sub_viewport.add_child(ch)

		var QNodeScript: Script = load("res://scripts/QuestNode3D.gd")
		var q_labels: Dictionary = {
			"elwynn": ["Светлоцвет", Color(0.95, 0.92, 0.30)],
			"duskwood": ["Проклятый череп", Color(0.55, 0.92, 0.85)],
			"barrens": ["Багровый кристалл", Color(1.0, 0.38, 0.25)],
			"frostpeak": ["Ледяная руна", Color(0.45, 0.88, 1.0)],
			"plaguelands": ["Чумной гриб", Color(0.55, 0.96, 0.22)],
			"citadel": ["Слиток Скверны", Color(0.85, 0.35, 1.0)]
		}
		var qinfo: Array = q_labels.get(zid, ["Трофей", Color.WHITE])
		for qi in range(10):
			var qpos: Vector3 = _pick_zone_land_spot(z, 18.0)
			var qn: Node3D = Node3D.new()
			qn.set_script(QNodeScript)
			qn.setup(self, qpos, "node_" + zid, str(qinfo[0]), qinfo[1])
			sub_viewport.add_child(qn)

	# 12 живых ИИ-игроков в открытом мире
	var bot_defs: Array = [
		["Светлозар", "<Серебряная Длань>", "paladin", 5, "elwynn"],
		["Огнемаг", "<Орден Лазури>", "mage", 8, "elwynn"],
		["ТанкПро", "<Щит Севера>", "warrior", 15, "duskwood"],
		["НочнаяТень", "<Ночной Дозор>", "ranger", 18, "duskwood"],
		["КритМастер", "<Кровавый Клан>", "warrior", 24, "barrens"],
		["Светлая", "<Хранители>", "paladin", 28, "barrens"],
		["ФростДжек", "<Ледяная Корона>", "mage", 35, "frostpeak"],
		["Ледокол", "<Сыны Бури>", "warrior", 38, "frostpeak"],
		["Анубис", "<Алый Рассвет>", "ranger", 44, "plaguelands"],
		["Тирион_Хил", "<Паладины Света>", "paladin", 48, "plaguelands"],
		["ОгненныйЛорд", "<Инферно>", "mage", 54, "citadel"],
		["Бессмертный", "<Авангард>", "warrior", 58, "citadel"]
	]
	for bd in bot_defs:
		var z: Dictionary = GameData.get_zone_by_id(str(bd[4]))
		var bpos_w: Vector3 = _pick_zone_land_spot(z, 14.0)
		var bot: CharacterBody3D = CharacterBody3D.new()
		bot.set_script(BotScript)
		bot.setup(self, str(bd[0]), str(bd[1]), str(bd[2]), int(bd[3]), str(bd[4]), bpos_w, false)
		sub_viewport.add_child(bot)
		bots.append(bot)

func get_active_enemies() -> Array:
	return instance_enemies if world_3d.in_instance else enemies

func spawn_loot(pos: Vector3, item: Dictionary, gold_amt: int, inst_drop: bool = false) -> void:
	var ld: Node3D = Node3D.new()
	ld.set_script(load("res://scripts/LootDrop3D.gd"))
	ld.setup(self, pos + Vector3(randf_range(-0.9, 0.9), 0.0, randf_range(-0.9, 0.9)), item, gold_amt, inst_drop)
	sub_viewport.add_child(ld)

func enter_dungeon_instance(did: String) -> void:
	if world_3d.in_instance:
		return
	var dng: Dictionary = GameData.get_dungeon_by_id(did)
	return_world_pos = player.position
	player.target = null
	player.click_move_active = false
	if player.is_mounted:
		player.toggle_mount()

	world_3d.enter_instance(dng)
	SoundFX.play_music("raid" if bool(dng.get("is_raid", false)) else "dungeon")
	player.position = Vector3(0.0, 0.0, 4.0)
	player._update_camera(1.0)
	SoundFX.play("portal")

	var EnemyScript: Script = load("res://scripts/Enemy3D.gd")
	var mob_pool: Array = dng["mobs"]
	for i in range(6):
		var mz: float = -8.0 - float(i / 2) * 12.0
		var mx: float = -3.8 if (i % 2 == 0) else 3.8
		var e: CharacterBody3D = CharacterBody3D.new()
		e.set_script(EnemyScript)
		e.setup(self, str(mob_pool[i % mob_pool.size()]), Vector3(mx, 0.0, mz), did, true)
		sub_viewport.add_child(e)
		instance_enemies.append(e)

	# Главный босс данжа / рейда
	var boss: CharacterBody3D = CharacterBody3D.new()
	boss.set_script(EnemyScript)
	boss.setup(self, str(dng["boss"]), Vector3(0.0, 0.0, -48.0), did, true)
	sub_viewport.add_child(boss)
	instance_enemies.append(boss)

	# Сундук с сокровищами в данже
	var ch: Node3D = Node3D.new()
	ch.set_script(load("res://scripts/Chest3D.gd"))
	ch.setup(self, Vector3(-6.5, 0.0, -24.0), int(dng["min_lv"]) + 3, did, true)
	sub_viewport.add_child(ch)

	# Союзная группа ботов (Танк, Лекарь, ДД)
	var BotScript: Script = load("res://scripts/BotPlayer3D.gd")
	var party_defs: Array = [
		["Танк_Утер", "warrior"],
		["Лекарь_Андуин", "paladin"],
		["Маг_Джайна", "mage"],
		["Следопыт_Сильвана", "ranger"]
	]
	var count: int = mini(int(dng["party_size"]) - 1, party_defs.size())
	for i in range(count):
		var pd: Array = party_defs[i]
		var pb: CharacterBody3D = CharacterBody3D.new()
		pb.set_script(BotScript)
		pb.setup(self, str(pd[0]), "<Группа>", str(pd[1]), player.level, did, Vector3(-2.0 + float(i) * 1.5, 0.0, 6.0), true, i)
		sub_viewport.add_child(pb)
		party_bots.append(pb)

	log_chat("[color=#55ddff]Вы вошли в '%s' с группой героев![/color]" % str(dng["name"]))

func on_instance_boss_killed(boss: Node) -> void:
	SoundFX.play("levelup")
	if is_instance_valid(player):
		player.dungeons_cleared += 1
	log_chat("[color=#ffaa22]ПОБЕДА! Босс %s повержен! Покиньте подземелье или соберите награды.[/color]" % boss.mob_name)
	var bonus_rarity: int = 4 if bool(world_3d.current_instance.get("is_raid", false)) else 3
	var bonus_item: Dictionary = GameData.generate_item(maxi(player.level, boss.level), bonus_rarity)
	spawn_loot(boss.position + Vector3(1.2, 0.0, 1.2), bonus_item, 0, true)

func exit_dungeon_instance() -> void:
	if not world_3d.in_instance:
		return
	for e in instance_enemies:
		if is_instance_valid(e):
			e.queue_free()
	instance_enemies.clear()
	for b in party_bots:
		if is_instance_valid(b):
			b.queue_free()
	party_bots.clear()
	for l in get_tree().get_nodes_in_group("loot"):
		if is_instance_valid(l) and l.is_instance_drop:
			l.queue_free()
	for ch in get_tree().get_nodes_in_group("chests"):
		if is_instance_valid(ch) and ch.is_instance_chest:
			ch.queue_free()

	world_3d.leave_instance()
	var z_out: Dictionary = GameData.get_zone_at(return_world_pos)
	SoundFX.play_music(str(z_out["id"]))
	player.target = null
	player.position = return_world_pos
	player._update_camera(1.0)
	SoundFX.play("portal")
	log_chat("[color=#88ff99]Вы вернулись в открытый мир.[/color]")

func find_nearest_enemy(from_pos: Vector3, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d: float = max_dist
	for e in get_active_enemies():
		if is_instance_valid(e) and not e.is_dead:
			var d: float = from_pos.distance_to(e.position)
			if d < best_d:
				best_d = d
				best = e
	return best

func _process(delta: float) -> void:
	if not game_started:
		SoundFX.play_music("lobby")
		return
	world_3d.update_biome_lighting(player.position)
	if world_3d.in_instance:
		SoundFX.play_music("raid" if bool(world_3d.current_instance.get("is_raid", false)) else "dungeon")
	else:
		SoundFX.play_music(world_3d.current_zone_id)

	autosave_timer -= delta
	if autosave_timer <= 0.0:
		autosave_timer = 60.0
		GameData.save_character(player.export_to_dict())

	bot_chat_timer -= delta
	if bot_chat_timer <= 0.0:
		bot_chat_timer = randf_range(14.0, 24.0)
		var b: Node = bots[randi() % bots.size()] if not bots.is_empty() else null
		if is_instance_valid(b):
			log_chat("[color=#77ccff][Мир] %s:[/color] %s" % [b.bot_name, str(BOT_CHAT_LINES[randi() % BOT_CHAT_LINES.size()])])

func send_player_chat(txt: String) -> void:
	if txt.begins_with("/"):
		_handle_slash_cmd(txt)
		return
	log_chat("[color=#ffdd66][Мир] %s:[/color] %s" % [player.char_name, txt])

func _handle_slash_cmd(cmd: String) -> void:
	if cmd == "/stuck":
		if world_3d.in_instance:
			exit_dungeon_instance()
		else:
			player.position = GameData.ZONES[0]["hub"] + Vector3(0, 0, 3.8)
		log_chat("[color=#88ff88]Персонаж перемещён в безопасное место.[/color]")
	elif cmd == "/save":
		save_now()
	else:
		log_chat("[color=#aaaaaa]Команды: /save, /stuck[/color]")

func log_chat(msg: String) -> void:
	if is_instance_valid(hud):
		hud.log_chat(msg)

func _unhandled_input(event: InputEvent) -> void:
	if not game_started:
		return

	if event is InputEventMagnifyGesture:
		var mg: InputEventMagnifyGesture = event
		player.cam_dist = clampf(player.cam_dist / maxf(0.5, mg.factor), 10.5, 25.0)
		return

	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			player.cam_dist = maxf(10.5, player.cam_dist - 1.2)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			player.cam_dist = minf(25.0, player.cam_dist + 1.2)
		elif mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if not hud.is_touch_captured(mb.position):
				_handle_world_click(mb.position, mb.button_index == MOUSE_BUTTON_RIGHT)

	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if hud.chat_input.has_focus():
			if k == KEY_ESCAPE:
				hud.chat_input.release_focus()
			return
		match k:
			KEY_ENTER:
				hud.chat_input.grab_focus()
			KEY_ESCAPE:
				if hud.modal_panel.visible:
					hud.close_modal()
				else:
					hud.toggle_modal("game_menu")
			KEY_1: player.use_skill(0)
			KEY_2: player.use_skill(1)
			KEY_3: player.use_skill(2)
			KEY_4: player.use_skill(3)
			KEY_5: player.use_skill(4)
			KEY_R: player.drink_potion()
			KEY_H: player.start_hearthstone()
			KEY_M: player.toggle_mount()
			KEY_F: player.auto_attack_on = not player.auto_attack_on
			KEY_E: _interact_or_loot()
			KEY_TAB:
				var ne: Node3D = find_nearest_enemy(player.position, 22.0)
				if ne != null:
					player.target = ne
					player.auto_attack_on = true
			KEY_C: hud.toggle_modal("char")
			KEY_B: hud.toggle_modal("bag")
			KEY_T: hud.toggle_modal("talents")
			KEY_K: hud.toggle_modal("skills")
			KEY_J: hud.toggle_modal("quests")
			KEY_I: hud.toggle_modal("dungeons")
			KEY_N: hud.toggle_modal("map")
			KEY_F2: toggle_pixel_resolution()
			KEY_F5: save_now()

func _handle_world_click(screen_pos: Vector2, is_right: bool) -> void:
	if hud.modal_panel.visible:
		return
	var cam: Camera3D = player.camera
	if not is_instance_valid(cam):
		return
	var vp_size: Vector2 = vp_container.size
	if vp_size.x <= 0:
		return
	var sub_pos: Vector2 = screen_pos * (Vector2(sub_viewport.size) / vp_size)
	var ray_o: Vector3 = cam.project_ray_origin(sub_pos)
	var ray_d: Vector3 = cam.project_ray_normal(sub_pos)
	if absf(ray_d.y) < 0.001:
		return
	var ref_y: float = player.position.y
	var t: float = (ref_y - ray_o.y) / ray_d.y
	if t <= 0.0:
		return
	var hit_pt: Vector3 = ray_o + ray_d * t
	if not world_3d.in_instance:
		var gh: float = GameData.get_terrain_height(hit_pt.x, hit_pt.z)
		t = (gh - ray_o.y) / ray_d.y
		if t > 0.0:
			hit_pt = ray_o + ray_d * t

	# 1. Проверяем клик по врагу
	var best_e: Node3D = find_nearest_enemy(hit_pt, 2.2)
	if best_e != null:
		player.target = best_e
		player.auto_attack_on = true
		if is_right:
			player.use_skill(0)
		return

	# 2. Клик по NPC
	if not world_3d.in_instance:
		for n in npcs:
			if is_instance_valid(n) and n.position.distance_to(hit_pt) < 2.0:
				if n.position.distance_to(player.position) <= 5.0:
					hud.open_npc_dialog(n)
				else:
					player.click_move_pos = n.position
					player.click_move_active = true
				return

	# 3. Клик по сундуку
	for ch in get_tree().get_nodes_in_group("chests"):
		if is_instance_valid(ch) and not ch.is_opened and ch.is_instance_chest == world_3d.in_instance and ch.position.distance_to(hit_pt) < 1.8:
			if ch.position.distance_to(player.position) <= 4.5:
				ch.open_chest(player)
			else:
				player.click_move_pos = ch.position
				player.click_move_active = true
			return

	# 4. Клик по луту
	for l in get_tree().get_nodes_in_group("loot"):
		if is_instance_valid(l) and l.is_instance_drop == world_3d.in_instance and l.position.distance_to(hit_pt) < 1.8:
			if l.position.distance_to(player.position) <= 4.5:
				_pickup_loot(l)
			else:
				player.click_move_pos = l.position
				player.click_move_active = true
			return

	# 4. Движение по земле как в Diablo
	player.click_move_pos = Vector3(hit_pt.x, 0.0, hit_pt.z)
	player.click_move_active = true

func _interact_or_loot() -> void:
	var in_inst: bool = world_3d.in_instance
	for l in get_tree().get_nodes_in_group("loot"):
		if is_instance_valid(l) and l.is_instance_drop == in_inst and l.position.distance_to(player.position) <= 4.5:
			_pickup_loot(l)
			return

	for ch in get_tree().get_nodes_in_group("chests"):
		if is_instance_valid(ch) and not ch.is_opened and ch.is_instance_chest == in_inst and ch.position.distance_to(player.position) <= 4.5:
			ch.open_chest(player)
			return

	if not in_inst:
		for qn in get_tree().get_nodes_in_group("quest_nodes"):
			if is_instance_valid(qn) and not qn.is_collected and qn.position.distance_to(player.position) <= 4.5:
				qn.collect(player)
				return

	if in_inst:
		if player.position.distance_to(Vector3(-7.5, 0.0, 5.0)) <= 4.5:
			exit_dungeon_instance()
		return

	for n in npcs:
		if is_instance_valid(n) and n.position.distance_to(player.position) <= 5.0:
			hud.open_npc_dialog(n)
			return

func _pickup_loot(l: Node3D) -> void:
	if not l.item_data.is_empty():
		if player.add_item_to_inventory(l.item_data):
			l.queue_free()
	else:
		player.gold += l.gold_amount
		SoundFX.play("loot")
		l.queue_free()

func _register_inputs() -> void:
	var keys: Dictionary = {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT]
	}
	for act in keys.keys():
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for kc in keys[act]:
			var ev: InputEventKey = InputEventKey.new()
			ev.keycode = kc
			InputMap.action_add_event(act, ev)
