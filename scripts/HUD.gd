extends CanvasLayer

var main_ref: Node = null
var hud_root: Control
var world_overlay: Control

# Фрейм игрока и баффы
var p_portrait: TextureRect
var lbl_p_name: Label
var bar_p_hp: ProgressBar
var lbl_p_hp: Label
var bar_p_res: ProgressBar
var lbl_p_res: Label
var lbl_p_gold: Label
var lbl_buffs: Label

# Фреймы группы / рейда
var party_panel: PanelContainer
var party_vbox: VBoxContainer

# Фрейм цели
var target_panel: PanelContainer
var t_portrait: TextureRect
var lbl_t_name: Label
var bar_t_hp: ProgressBar
var lbl_t_hp: Label

# Миникарта и трекер
var minimap_ctrl: Control
var lbl_zone: Label
var quest_tracker_lbl: RichTextLabel
var btn_leave_inst: Button

# Сферы и панель умений
var orb_hp: TextureRect
var lbl_orb_hp: Label
var orb_res: TextureRect
var lbl_orb_res: Label
var bar_xp: ProgressBar
var lbl_xp: Label
var skill_btns: Array = []
var skill_cd_lbls: Array = []
var skill_rank_lbls: Array = []
var btn_potion: Button
var lbl_potion_cnt: Label
var btn_mount: Button
var lbl_mount_lock: Label
var btn_hearth: Button
var lbl_hearth_cd: Label
var cast_panel: PanelContainer
var cast_bar: ProgressBar
var cast_lbl: Label

# Мобильное сенсорное управление
var touch_controls_root: Control
var touch_joy: Control
var joy_vec: Vector2 = Vector2.ZERO
var touch_ui_enabled: bool = false
var btn_touch_atk: Button
var btn_touch_use: Button

# Чат
var chat_log: RichTextLabel
var chat_input: LineEdit

# Стартовый экран (Выбор персонажа + Создание)
var start_overlay: Control
var char_select_panel: PanelContainer
var char_create_panel: PanelContainer
var roster_vbox: VBoxContainer
var roster_list: Array = []
var selected_roster_idx: int = -1
var roster_card_btns: Array = []
var btn_enter_world: Button
var btn_delete_char: Button
var delete_confirm_armed: bool = false
var inp_name: LineEdit
var selected_race: String = "human"
var selected_class: String = "warrior"
var class_desc_lbl: Label
var race_btns: Dictionary = {}
var class_btns: Dictionary = {}

# Модальные окна
var modal_panel: PanelContainer
var modal_title: Label
var modal_body: VBoxContainer
var current_modal: String = ""
var current_npc: Node = null

func build_ui(main_node: Node) -> void:
	main_ref = main_node

	world_overlay = Control.new()
	world_overlay.set_script(load("res://scripts/WorldOverlay.gd"))
	world_overlay.main_ref = main_ref
	world_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_overlay)

	hud_root = Control.new()
	hud_root.theme = PixelArt.retro_theme
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.visible = false
	add_child(hud_root)

	_build_player_frame()
	_build_party_frame()
	_build_target_frame()
	_build_minimap_and_tracker()
	_build_action_bar()
	_build_chat_panel()
	_build_mobile_controls()
	_build_modal_window()
	_build_start_screen()

func _bar_fill(col: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = col.lightened(0.28)
	sb.border_width_top = 1
	return sb

func _bar_bg() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.07, 0.95)
	sb.border_color = Color(0.24, 0.20, 0.16)
	sb.set_border_width_all(1)
	return sb

func _build_player_frame() -> void:
	var left_vb: VBoxContainer = VBoxContainer.new()
	left_vb.position = Vector2(10, 10)
	left_vb.add_theme_constant_override("separation", 4)
	hud_root.add_child(left_vb)

	var p: PanelContainer = PanelContainer.new()
	p.custom_minimum_size = Vector2(258, 94)
	p.add_theme_stylebox_override("panel", PixelArt.box_stone)
	left_vb.add_child(p)

	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	p.add_child(hb)

	var port_box: PanelContainer = PanelContainer.new()
	port_box.custom_minimum_size = Vector2(56, 56)
	port_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	port_box.add_theme_stylebox_override("panel", PixelArt.box_gold)
	hb.add_child(port_box)

	p_portrait = TextureRect.new()
	p_portrait.custom_minimum_size = Vector2(44, 44)
	p_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_portrait.texture = PixelArt.portraits["warrior"]
	port_box.add_child(p_portrait)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	hb.add_child(vb)

	lbl_p_name = Label.new()
	lbl_p_name.add_theme_font_size_override("font_size", 13)
	lbl_p_name.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	vb.add_child(lbl_p_name)

	bar_p_hp = ProgressBar.new()
	bar_p_hp.show_percentage = false
	bar_p_hp.custom_minimum_size = Vector2(170, 17)
	bar_p_hp.add_theme_stylebox_override("background", _bar_bg())
	bar_p_hp.add_theme_stylebox_override("fill", _bar_fill(Color(0.18, 0.72, 0.24)))
	vb.add_child(bar_p_hp)
	lbl_p_hp = Label.new()
	lbl_p_hp.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_p_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_p_hp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_p_hp.add_theme_font_size_override("font_size", 11)
	bar_p_hp.add_child(lbl_p_hp)

	bar_p_res = ProgressBar.new()
	bar_p_res.show_percentage = false
	bar_p_res.custom_minimum_size = Vector2(170, 15)
	bar_p_res.add_theme_stylebox_override("background", _bar_bg())
	bar_p_res.add_theme_stylebox_override("fill", _bar_fill(Color(0.20, 0.48, 0.95)))
	vb.add_child(bar_p_res)
	lbl_p_res = Label.new()
	lbl_p_res.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_p_res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_p_res.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_p_res.add_theme_font_size_override("font_size", 10)
	bar_p_res.add_child(lbl_p_res)

	lbl_p_gold = Label.new()
	lbl_p_gold.add_theme_font_size_override("font_size", 11)
	lbl_p_gold.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vb.add_child(lbl_p_gold)

	lbl_buffs = Label.new()
	lbl_buffs.add_theme_font_size_override("font_size", 11)
	lbl_buffs.add_theme_color_override("font_color", Color(0.48, 0.96, 1.0))
	left_vb.add_child(lbl_buffs)

func _build_party_frame() -> void:
	party_panel = PanelContainer.new()
	party_panel.position = Vector2(10, 128)
	party_panel.custom_minimum_size = Vector2(180, 40)
	party_panel.add_theme_stylebox_override("panel", PixelArt.box_dark)
	party_panel.visible = false
	hud_root.add_child(party_panel)

	party_vbox = VBoxContainer.new()
	party_vbox.add_theme_constant_override("separation", 4)
	party_panel.add_child(party_vbox)

func _build_target_frame() -> void:
	target_panel = PanelContainer.new()
	target_panel.position = Vector2(345, 10)
	target_panel.custom_minimum_size = Vector2(270, 66)
	target_panel.add_theme_stylebox_override("panel", PixelArt.box_dark)
	target_panel.visible = false
	hud_root.add_child(target_panel)

	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	target_panel.add_child(hb)

	t_portrait = TextureRect.new()
	t_portrait.custom_minimum_size = Vector2(44, 44)
	t_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t_portrait.texture = PixelArt.portraits["mob"]
	hb.add_child(t_portrait)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)

	lbl_t_name = Label.new()
	lbl_t_name.add_theme_font_size_override("font_size", 13)
	lbl_t_name.add_theme_color_override("font_color", Color(1.0, 0.50, 0.40))
	vb.add_child(lbl_t_name)

	bar_t_hp = ProgressBar.new()
	bar_t_hp.show_percentage = false
	bar_t_hp.custom_minimum_size = Vector2(195, 19)
	bar_t_hp.add_theme_stylebox_override("background", _bar_bg())
	bar_t_hp.add_theme_stylebox_override("fill", _bar_fill(Color(0.84, 0.18, 0.16)))
	vb.add_child(bar_t_hp)

	lbl_t_hp = Label.new()
	lbl_t_hp.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_t_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t_hp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_t_hp.add_theme_font_size_override("font_size", 11)
	bar_t_hp.add_child(lbl_t_hp)

func _build_minimap_and_tracker() -> void:
	var right_col: VBoxContainer = VBoxContainer.new()
	right_col.position = Vector2(754, 10)
	right_col.add_theme_constant_override("separation", 6)
	hud_root.add_child(right_col)

	var p: PanelContainer = PanelContainer.new()
	p.custom_minimum_size = Vector2(196, 146)
	p.add_theme_stylebox_override("panel", PixelArt.box_stone)
	right_col.add_child(p)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)

	lbl_zone = Label.new()
	lbl_zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_zone.add_theme_font_size_override("font_size", 12)
	lbl_zone.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	vb.add_child(lbl_zone)

	minimap_ctrl = Control.new()
	minimap_ctrl.set_script(load("res://scripts/Minimap.gd"))
	minimap_ctrl.main_ref = main_ref
	minimap_ctrl.custom_minimum_size = Vector2(176, 108)
	vb.add_child(minimap_ctrl)

	btn_leave_inst = Button.new()
	btn_leave_inst.text = "Покинуть подземелье"
	btn_leave_inst.visible = false
	btn_leave_inst.pressed.connect(func() -> void: main_ref.exit_dungeon_instance())
	vb.add_child(btn_leave_inst)

	var qp: PanelContainer = PanelContainer.new()
	qp.custom_minimum_size = Vector2(196, 138)
	qp.add_theme_stylebox_override("panel", PixelArt.box_dark)
	right_col.add_child(qp)

	var qvb: VBoxContainer = VBoxContainer.new()
	qp.add_child(qvb)
	var qt: Label = Label.new()
	qt.text = "ЗАДАНИЯ [J]"
	qt.add_theme_font_size_override("font_size", 12)
	qt.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	qvb.add_child(qt)

	quest_tracker_lbl = RichTextLabel.new()
	quest_tracker_lbl.bbcode_enabled = true
	quest_tracker_lbl.fit_content = true
	quest_tracker_lbl.custom_minimum_size = Vector2(178, 102)
	quest_tracker_lbl.add_theme_font_size_override("normal_font_size", 11)
	qvb.add_child(quest_tracker_lbl)

func _build_action_bar() -> void:
	var p: PanelContainer = PanelContainer.new()
	p.position = Vector2(162, 602)
	p.custom_minimum_size = Vector2(628, 110)
	p.add_theme_stylebox_override("panel", PixelArt.box_stone)
	hud_root.add_child(p)

	var root_hb: HBoxContainer = HBoxContainer.new()
	root_hb.add_theme_constant_override("separation", 10)
	p.add_child(root_hb)

	# Левая Сфера Здоровья
	orb_hp = TextureRect.new()
	orb_hp.texture = PixelArt.make_orb_texture(Color(0.82, 0.12, 0.14))
	orb_hp.custom_minimum_size = Vector2(58, 58)
	orb_hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	orb_hp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root_hb.add_child(orb_hp)
	lbl_orb_hp = Label.new()
	lbl_orb_hp.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_orb_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_orb_hp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_orb_hp.add_theme_font_size_override("font_size", 11)
	orb_hp.add_child(lbl_orb_hp)

	# Центр
	var center_vb: VBoxContainer = VBoxContainer.new()
	center_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_vb.add_theme_constant_override("separation", 4)
	root_hb.add_child(center_vb)

	var skill_row: HBoxContainer = HBoxContainer.new()
	skill_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skill_row.add_theme_constant_override("separation", 5)
	center_vb.add_child(skill_row)

	skill_btns.clear()
	skill_cd_lbls.clear()
	skill_rank_lbls.clear()
	for i in range(5):
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.expand_icon = true
		var idx: int = i
		b.pressed.connect(func() -> void: main_ref.player.use_skill(idx))
		skill_row.add_child(b)
		skill_btns.append(b)

		var kl: Label = Label.new()
		kl.text = str(i + 1)
		kl.position = Vector2(3, 1)
		kl.add_theme_font_size_override("font_size", 10)
		kl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		b.add_child(kl)

		var rl: Label = Label.new()
		rl.text = "Р1"
		rl.position = Vector2(26, 28)
		rl.add_theme_font_size_override("font_size", 9)
		rl.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0))
		b.add_child(rl)
		skill_rank_lbls.append(rl)

		var cdl: Label = Label.new()
		cdl.set_anchors_preset(Control.PRESET_FULL_RECT)
		cdl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cdl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cdl.add_theme_font_size_override("font_size", 11)
		cdl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
		cdl.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06))
		cdl.add_theme_constant_override("outline_size", 3)
		b.add_child(cdl)
		skill_cd_lbls.append(cdl)

	btn_potion = Button.new()
	btn_potion.custom_minimum_size = Vector2(44, 44)
	btn_potion.icon = PixelArt.icons["potion"]
	btn_potion.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_potion.expand_icon = true
	btn_potion.tooltip_text = "Зелье лечения [R]"
	btn_potion.pressed.connect(func() -> void: main_ref.player.drink_potion())
	skill_row.add_child(btn_potion)

	var p_key: Label = Label.new()
	p_key.text = "R"
	p_key.position = Vector2(3, 1)
	p_key.add_theme_font_size_override("font_size", 10)
	p_key.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	btn_potion.add_child(p_key)

	lbl_potion_cnt = Label.new()
	lbl_potion_cnt.text = "5"
	lbl_potion_cnt.position = Vector2(28, 26)
	lbl_potion_cnt.add_theme_font_size_override("font_size", 11)
	lbl_potion_cnt.add_theme_color_override("font_color", Color(0.55, 1.0, 0.60))
	btn_potion.add_child(lbl_potion_cnt)

	btn_mount = Button.new()
	btn_mount.custom_minimum_size = Vector2(44, 44)
	btn_mount.icon = PixelArt.icons["mount"]
	btn_mount.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_mount.expand_icon = true
	btn_mount.tooltip_text = "Призвать скакуна [M]"
	btn_mount.pressed.connect(func() -> void: main_ref.player.toggle_mount())
	skill_row.add_child(btn_mount)

	var m_key: Label = Label.new()
	m_key.text = "M"
	m_key.position = Vector2(3, 1)
	m_key.add_theme_font_size_override("font_size", 10)
	m_key.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	btn_mount.add_child(m_key)

	lbl_mount_lock = Label.new()
	lbl_mount_lock.text = "Ур.20"
	lbl_mount_lock.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_mount_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mount_lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_mount_lock.add_theme_font_size_override("font_size", 10)
	lbl_mount_lock.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	lbl_mount_lock.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06))
	lbl_mount_lock.add_theme_constant_override("outline_size", 3)
	btn_mount.add_child(lbl_mount_lock)

	btn_hearth = Button.new()
	btn_hearth.custom_minimum_size = Vector2(44, 44)
	btn_hearth.icon = PixelArt.icons["hearth"]
	btn_hearth.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_hearth.expand_icon = true
	btn_hearth.tooltip_text = "Камень возвращения [H]"
	btn_hearth.pressed.connect(func() -> void: main_ref.player.start_hearthstone())
	skill_row.add_child(btn_hearth)

	var h_key: Label = Label.new()
	h_key.text = "H"
	h_key.position = Vector2(3, 1)
	h_key.add_theme_font_size_override("font_size", 10)
	h_key.add_theme_color_override("font_color", Color(0.55, 0.92, 1.0))
	btn_hearth.add_child(h_key)

	lbl_hearth_cd = Label.new()
	lbl_hearth_cd.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_hearth_cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_hearth_cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_hearth_cd.add_theme_font_size_override("font_size", 11)
	lbl_hearth_cd.add_theme_color_override("font_color", Color(1.0, 0.42, 0.32))
	lbl_hearth_cd.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06))
	lbl_hearth_cd.add_theme_constant_override("outline_size", 3)
	btn_hearth.add_child(lbl_hearth_cd)

	# Полоса произнесения Камня возвращения
	cast_panel = PanelContainer.new()
	cast_panel.position = Vector2(360, 560)
	cast_panel.custom_minimum_size = Vector2(240, 26)
	cast_panel.add_theme_stylebox_override("panel", PixelArt.box_gold)
	cast_panel.visible = false
	hud_root.add_child(cast_panel)

	cast_bar = ProgressBar.new()
	cast_bar.show_percentage = false
	cast_bar.custom_minimum_size = Vector2(220, 16)
	cast_bar.add_theme_stylebox_override("background", _bar_bg())
	cast_bar.add_theme_stylebox_override("fill", _bar_fill(Color(0.24, 0.68, 1.0)))
	cast_panel.add_child(cast_bar)

	cast_lbl = Label.new()
	cast_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cast_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cast_lbl.add_theme_font_size_override("font_size", 11)
	cast_bar.add_child(cast_lbl)

	var menu_row: HBoxContainer = HBoxContainer.new()
	menu_row.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_row.add_theme_constant_override("separation", 4)
	center_vb.add_child(menu_row)

	var mdefs: Array = [
		["[C] Перс", func() -> void: toggle_modal("char")],
		["[B] Сумка", func() -> void: toggle_modal("bag")],
		["[K] Умения", func() -> void: toggle_modal("skills")],
		["[T] Талант", func() -> void: toggle_modal("talents")],
		["[J] Квест", func() -> void: toggle_modal("quests")],
		["[N] Карта", func() -> void: toggle_modal("map")],
		["[I] Данж", func() -> void: toggle_modal("dungeons")],
		["[Esc] Меню", func() -> void: toggle_modal("game_menu")]
	]
	for md in mdefs:
		var mb: Button = Button.new()
		mb.text = str(md[0])
		mb.add_theme_font_size_override("font_size", 11)
		mb.pressed.connect(md[1])
		menu_row.add_child(mb)

	bar_xp = ProgressBar.new()
	bar_xp.show_percentage = false
	bar_xp.custom_minimum_size = Vector2(450, 14)
	bar_xp.add_theme_stylebox_override("background", _bar_bg())
	bar_xp.add_theme_stylebox_override("fill", _bar_fill(Color(0.68, 0.24, 0.88)))
	center_vb.add_child(bar_xp)
	lbl_xp = Label.new()
	lbl_xp.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_xp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_xp.add_theme_font_size_override("font_size", 10)
	bar_xp.add_child(lbl_xp)

	# Правая Сфера Ресурса
	orb_res = TextureRect.new()
	orb_res.texture = PixelArt.make_orb_texture(Color(0.16, 0.44, 0.92))
	orb_res.custom_minimum_size = Vector2(58, 58)
	orb_res.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	orb_res.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root_hb.add_child(orb_res)
	lbl_orb_res = Label.new()
	lbl_orb_res.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_orb_res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_orb_res.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_orb_res.add_theme_font_size_override("font_size", 11)
	orb_res.add_child(lbl_orb_res)

func _build_chat_panel() -> void:
	var p: PanelContainer = PanelContainer.new()
	p.position = Vector2(10, 414)
	p.custom_minimum_size = Vector2(246, 124)
	p.add_theme_stylebox_override("panel", PixelArt.box_dark)
	hud_root.add_child(p)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)

	chat_log = RichTextLabel.new()
	chat_log.bbcode_enabled = true
	chat_log.scroll_following = true
	chat_log.custom_minimum_size = Vector2(228, 86)
	chat_log.add_theme_font_size_override("normal_font_size", 11)
	vb.add_child(chat_log)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Написать в чат..."
	chat_input.add_theme_font_size_override("font_size", 11)
	chat_input.text_submitted.connect(_on_chat_submit)
	vb.add_child(chat_input)

func _build_mobile_controls() -> void:
	touch_ui_enabled = OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	touch_controls_root = Control.new()
	touch_controls_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_controls_root.visible = touch_ui_enabled
	hud_root.add_child(touch_controls_root)

	touch_joy = Control.new()
	touch_joy.set_script(load("res://scripts/TouchJoystick.gd"))
	touch_joy.position = Vector2(14, 558)
	touch_controls_root.add_child(touch_joy)

	btn_touch_atk = Button.new()
	btn_touch_atk.text = "АТАКА"
	btn_touch_atk.position = Vector2(872, 618)
	btn_touch_atk.custom_minimum_size = Vector2(76, 84)
	btn_touch_atk.add_theme_font_size_override("font_size", 13)
	btn_touch_atk.pressed.connect(func() -> void: main_ref.player.mobile_attack_action())
	touch_controls_root.add_child(btn_touch_atk)

	btn_touch_use = Button.new()
	btn_touch_use.text = "ДЕЙСТВ."
	btn_touch_use.position = Vector2(874, 558)
	btn_touch_use.custom_minimum_size = Vector2(74, 52)
	btn_touch_use.add_theme_font_size_override("font_size", 11)
	btn_touch_use.pressed.connect(func() -> void: main_ref._interact_or_loot())
	touch_controls_root.add_child(btn_touch_use)

	var btn_touch_tab: Button = Button.new()
	btn_touch_tab.text = "ЦЕЛЬ"
	btn_touch_tab.position = Vector2(874, 508)
	btn_touch_tab.custom_minimum_size = Vector2(74, 42)
	btn_touch_tab.add_theme_font_size_override("font_size", 12)
	btn_touch_tab.pressed.connect(func() -> void:
		var ne: Node3D = main_ref.find_nearest_enemy(main_ref.player.position, 22.0)
		if ne != null:
			main_ref.player.target = ne
	)
	touch_controls_root.add_child(btn_touch_tab)

	var btn_zin: Button = Button.new()
	btn_zin.text = "+"
	btn_zin.position = Vector2(874, 466)
	btn_zin.custom_minimum_size = Vector2(34, 34)
	btn_zin.add_theme_font_size_override("font_size", 14)
	btn_zin.pressed.connect(func() -> void:
		main_ref.player.cam_dist = maxf(10.5, main_ref.player.cam_dist - 2.0)
	)
	touch_controls_root.add_child(btn_zin)

	var btn_zout: Button = Button.new()
	btn_zout.text = "-"
	btn_zout.position = Vector2(914, 466)
	btn_zout.custom_minimum_size = Vector2(34, 34)
	btn_zout.add_theme_font_size_override("font_size", 14)
	btn_zout.pressed.connect(func() -> void:
		main_ref.player.cam_dist = minf(25.0, main_ref.player.cam_dist + 2.0)
	)
	touch_controls_root.add_child(btn_zout)

func set_touch_ui(en: bool) -> void:
	touch_ui_enabled = en
	if is_instance_valid(touch_controls_root):
		touch_controls_root.visible = en

func is_touch_captured(pos: Vector2) -> bool:
	if not is_instance_valid(touch_controls_root) or not touch_controls_root.visible:
		return false
	if Rect2(10, 548, 152, 162).has_point(pos):
		return true
	if Rect2(866, 460, 90, 250).has_point(pos):
		return true
	return false

func _on_chat_submit(txt: String) -> void:
	var clean: String = txt.strip_edges()
	chat_input.clear()
	chat_input.release_focus()
	if clean == "":
		return
	main_ref.send_player_chat(clean)

func log_chat(msg: String) -> void:
	if is_instance_valid(chat_log):
		chat_log.append_text(msg + "\n")

func _build_modal_window() -> void:
	modal_panel = PanelContainer.new()
	modal_panel.position = Vector2(205, 84)
	modal_panel.custom_minimum_size = Vector2(540, 500)
	modal_panel.add_theme_stylebox_override("panel", PixelArt.box_stone)
	modal_panel.visible = false
	hud_root.add_child(modal_panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	modal_panel.add_child(vb)

	var hdr: HBoxContainer = HBoxContainer.new()
	vb.add_child(hdr)
	modal_title = Label.new()
	modal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_title.add_theme_font_size_override("font_size", 16)
	modal_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	hdr.add_child(modal_title)

	var close_btn: Button = Button.new()
	close_btn.text = " [X] "
	close_btn.pressed.connect(close_modal)
	hdr.add_child(close_btn)

	vb.add_child(HSeparator.new())

	var sc: ScrollContainer = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(516, 430)
	vb.add_child(sc)

	modal_body = VBoxContainer.new()
	modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation", 6)
	sc.add_child(modal_body)

func _build_start_screen() -> void:
	start_overlay = Control.new()
	start_overlay.theme = PixelArt.retro_theme
	start_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(start_overlay)

	# Верхний герб-заголовок (без системных надписей!)
	var hdr: PanelContainer = PanelContainer.new()
	hdr.position = Vector2(30, 16)
	hdr.custom_minimum_size = Vector2(900, 70)
	hdr.add_theme_stylebox_override("panel", PixelArt.box_gold)
	start_overlay.add_child(hdr)

	var hvb: VBoxContainer = VBoxContainer.new()
	hdr.add_child(hvb)
	var title: Label = Label.new()
	title.text = "ПЕПЕЛЬНАЯ КОРОНА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.30))
	hvb.add_child(title)

	var sub: Label = Label.new()
	sub.text = "Клинок, магия и древние руны"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96))
	hvb.add_child(sub)

	_build_char_select_panel()
	_build_char_create_panel()
	show_char_select()

func _build_char_select_panel() -> void:
	# Левая панель выбора персонажа — центр и правая часть открывают живую 3D-сцену героя!
	char_select_panel = PanelContainer.new()
	char_select_panel.position = Vector2(28, 98)
	char_select_panel.custom_minimum_size = Vector2(344, 594)
	char_select_panel.add_theme_stylebox_override("panel", PixelArt.box_stone)
	start_overlay.add_child(char_select_panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	char_select_panel.add_child(vb)

	var hdr_lbl: Label = Label.new()
	hdr_lbl.text = "ВЫБОР ПЕРСОНАЖА"
	hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_lbl.add_theme_font_size_override("font_size", 15)
	hdr_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	vb.add_child(hdr_lbl)

	var sc: ScrollContainer = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(316, 420)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sc)

	roster_vbox = VBoxContainer.new()
	roster_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_vbox.add_theme_constant_override("separation", 6)
	sc.add_child(roster_vbox)

	btn_enter_world = Button.new()
	btn_enter_world.text = " ВОЙТИ В МИР "
	btn_enter_world.custom_minimum_size = Vector2(312, 38)
	btn_enter_world.add_theme_font_size_override("font_size", 14)
	btn_enter_world.pressed.connect(func() -> void:
		if selected_roster_idx < 0 or selected_roster_idx >= roster_list.size():
			return
		var d: Dictionary = roster_list[selected_roster_idx]
		start_overlay.visible = false
		hud_root.visible = true
		main_ref.load_character_from_dict(d)
	)
	vb.add_child(btn_enter_world)

	var bot_hb: HBoxContainer = HBoxContainer.new()
	bot_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_hb.add_theme_constant_override("separation", 8)
	vb.add_child(bot_hb)

	var btn_new_hero: Button = Button.new()
	btn_new_hero.text = "Создать героя"
	btn_new_hero.custom_minimum_size = Vector2(182, 34)
	btn_new_hero.pressed.connect(func() -> void: show_char_create())
	bot_hb.add_child(btn_new_hero)

	btn_delete_char = Button.new()
	btn_delete_char.text = "Удалить"
	btn_delete_char.custom_minimum_size = Vector2(122, 34)
	btn_delete_char.pressed.connect(func() -> void:
		if selected_roster_idx < 0 or selected_roster_idx >= roster_list.size():
			return
		if not delete_confirm_armed:
			delete_confirm_armed = true
			btn_delete_char.text = "Удалить?"
			return
		var cid: String = str(roster_list[selected_roster_idx].get("char_id", ""))
		GameData.delete_character(cid)
		delete_confirm_armed = false
		btn_delete_char.text = "Удалить"
		refresh_roster()
	)
	bot_hb.add_child(btn_delete_char)

func _build_char_create_panel() -> void:
	char_create_panel = PanelContainer.new()
	char_create_panel.position = Vector2(24, 98)
	char_create_panel.custom_minimum_size = Vector2(540, 594)
	char_create_panel.add_theme_stylebox_override("panel", PixelArt.box_stone)
	char_create_panel.visible = false
	start_overlay.add_child(char_create_panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	char_create_panel.add_child(vb)

	var chdr: Label = Label.new()
	chdr.text = "СОЗДАНИЕ ПЕРСОНАЖА"
	chdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chdr.add_theme_font_size_override("font_size", 15)
	chdr.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	vb.add_child(chdr)

	var name_hb: HBoxContainer = HBoxContainer.new()
	name_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	name_hb.add_theme_constant_override("separation", 6)
	vb.add_child(name_hb)
	var nl: Label = Label.new()
	nl.text = "Имя: "
	nl.add_theme_font_size_override("font_size", 13)
	name_hb.add_child(nl)
	inp_name = LineEdit.new()
	inp_name.text = ""
	inp_name.placeholder_text = "Имя героя..."
	inp_name.custom_minimum_size = Vector2(220, 28)
	name_hb.add_child(inp_name)
	var btn_rand: Button = Button.new()
	btn_rand.text = "Случайное"
	btn_rand.add_theme_font_size_override("font_size", 11)
	btn_rand.pressed.connect(func() -> void:
		inp_name.text = str(GameData.RANDOM_NAMES[randi() % GameData.RANDOM_NAMES.size()])
	)
	name_hb.add_child(btn_rand)

	# 5 рас
	var race_row: HBoxContainer = HBoxContainer.new()
	race_row.alignment = BoxContainer.ALIGNMENT_CENTER
	race_row.add_theme_constant_override("separation", 4)
	vb.add_child(race_row)
	race_btns.clear()
	for rid in ["human", "elf", "dwarf", "orc", "undead"]:
		var rdata: Dictionary = GameData.RACES[rid]
		var rb: Button = Button.new()
		rb.text = str(rdata["name"])
		rb.tooltip_text = str(rdata["bonus"])
		rb.add_theme_font_size_override("font_size", 11)
		var r_id: String = rid
		rb.pressed.connect(func() -> void: _select_race(r_id))
		race_row.add_child(rb)
		race_btns[rid] = rb

	# 8 классов (сетка 2x4)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)

	class_btns.clear()
	for cid in ["warrior", "mage", "paladin", "ranger", "rogue", "priest", "warlock", "shaman"]:
		var cdata: Dictionary = GameData.CLASSES[cid]
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(256, 84)
		card.add_theme_stylebox_override("panel", PixelArt.box_dark)
		grid.add_child(card)

		var chb: HBoxContainer = HBoxContainer.new()
		chb.add_theme_constant_override("separation", 6)
		card.add_child(chb)

		var pt: TextureRect = TextureRect.new()
		pt.texture = PixelArt.portraits[cid]
		pt.custom_minimum_size = Vector2(44, 44)
		pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chb.add_child(pt)

		var cvb: VBoxContainer = VBoxContainer.new()
		cvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cvb.alignment = BoxContainer.ALIGNMENT_CENTER
		chb.add_child(cvb)

		var cn: Label = Label.new()
		cn.text = "%s (%s)" % [str(cdata["name"]), str(cdata["res_name"])]
		cn.add_theme_font_size_override("font_size", 12)
		cn.add_theme_color_override("font_color", cdata["color"])
		cvb.add_child(cn)

		var cb: Button = Button.new()
		cb.text = "Выбрать"
		cb.add_theme_font_size_override("font_size", 11)
		var c_id: String = cid
		cb.pressed.connect(func() -> void: _select_class(c_id))
		cvb.add_child(cb)
		class_btns[cid] = cb

	class_desc_lbl = Label.new()
	class_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	class_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_desc_lbl.custom_minimum_size = Vector2(500, 42)
	class_desc_lbl.add_theme_font_size_override("font_size", 11)
	vb.add_child(class_desc_lbl)
	_select_race("human")
	_select_class("warrior")

	var play_hb: HBoxContainer = HBoxContainer.new()
	play_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	play_hb.add_theme_constant_override("separation", 10)
	vb.add_child(play_hb)

	var btn_new: Button = Button.new()
	btn_new.text = " СОЗДАТЬ И ВОЙТИ "
	btn_new.custom_minimum_size = Vector2(220, 38)
	btn_new.pressed.connect(func() -> void:
		start_overlay.visible = false
		hud_root.visible = true
		main_ref.start_game(inp_name.text, selected_class, selected_race)
	)
	play_hb.add_child(btn_new)

	var btn_back: Button = Button.new()
	btn_back.text = " НАЗАД "
	btn_back.custom_minimum_size = Vector2(140, 38)
	btn_back.pressed.connect(func() -> void: show_char_select())
	play_hb.add_child(btn_back)

func show_char_select() -> void:
	start_overlay.visible = true
	hud_root.visible = false
	char_select_panel.visible = true
	char_create_panel.visible = false
	delete_confirm_armed = false
	if is_instance_valid(btn_delete_char):
		btn_delete_char.text = "Удалить"
	refresh_roster()

func show_char_create() -> void:
	start_overlay.visible = true
	hud_root.visible = false
	char_select_panel.visible = false
	char_create_panel.visible = true
	inp_name.text = ""
	_select_race(selected_race)
	_select_class(selected_class)

func refresh_roster() -> void:
	for c in roster_vbox.get_children():
		c.queue_free()
	roster_card_btns.clear()
	roster_list = GameData.load_roster()
	if roster_list.is_empty():
		selected_roster_idx = -1
		var empty_l: Label = Label.new()
		empty_l.text = "\nСписок героев пуст.\nНажмите «Создать героя»,\nчтобы начать странствие."
		empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_l.add_theme_color_override("font_color", Color(0.78, 0.82, 0.88))
		roster_vbox.add_child(empty_l)
		btn_enter_world.disabled = true
		btn_delete_char.disabled = true
		if is_instance_valid(main_ref) and is_instance_valid(main_ref.player):
			main_ref.player.preview_class("warrior", "human")
		return

	btn_enter_world.disabled = false
	btn_delete_char.disabled = false
	for i in range(roster_list.size()):
		var d: Dictionary = roster_list[i]
		var cid: String = str(d.get("class_id", "warrior"))
		var rid: String = str(d.get("race_id", "human"))
		var rname: String = str(GameData.RACES.get(rid, GameData.RACES["human"])["name"])
		var cname: String = str(GameData.CLASSES.get(cid, GameData.CLASSES["warrior"])["name"])
		var ccol: Color = GameData.CLASSES.get(cid, GameData.CLASSES["warrior"])["color"]
		var lv: int = int(d.get("level", 1))
		var hname: String = str(d.get("char_name", "Герой"))
		var pos_a: Array = d.get("pos", [68.0, 2.0, 242.0])
		var zinfo: Dictionary = GameData.get_zone_at(Vector3(float(pos_a[0]), float(pos_a[1]), float(pos_a[2])))

		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", PixelArt.box_dark)
		roster_vbox.add_child(card)

		var chb: HBoxContainer = HBoxContainer.new()
		chb.add_theme_constant_override("separation", 8)
		card.add_child(chb)

		var pt: TextureRect = TextureRect.new()
		pt.texture = PixelArt.portraits.get(cid, PixelArt.portraits["warrior"])
		pt.custom_minimum_size = Vector2(40, 40)
		pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chb.add_child(pt)

		var info_vb: VBoxContainer = VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chb.add_child(info_vb)

		var n_lbl: Label = Label.new()
		n_lbl.text = "%s [Ур.%d]" % [hname, lv]
		n_lbl.add_theme_font_size_override("font_size", 13)
		n_lbl.add_theme_color_override("font_color", ccol)
		info_vb.add_child(n_lbl)

		var sub_lbl: Label = Label.new()
		sub_lbl.text = "%s %s • %s" % [rname, cname, str(zinfo["name"])]
		sub_lbl.add_theme_font_size_override("font_size", 10)
		sub_lbl.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88))
		info_vb.add_child(sub_lbl)

		var sel_b: Button = Button.new()
		sel_b.text = "Выбрать"
		sel_b.add_theme_font_size_override("font_size", 11)
		var idx: int = i
		sel_b.pressed.connect(func() -> void: _select_roster_char(idx))
		chb.add_child(sel_b)
		roster_card_btns.append({"panel": card, "btn": sel_b})

	_select_roster_char(0)

func _select_roster_char(idx: int) -> void:
	if idx < 0 or idx >= roster_list.size():
		return
	selected_roster_idx = idx
	delete_confirm_armed = false
	btn_delete_char.text = "Удалить"
	for i in range(roster_card_btns.size()):
		var is_sel: bool = (i == idx)
		roster_card_btns[i]["panel"].add_theme_stylebox_override("panel", PixelArt.box_gold if is_sel else PixelArt.box_dark)
		roster_card_btns[i]["btn"].text = "★" if is_sel else "Выбрать"
	if is_instance_valid(main_ref) and is_instance_valid(main_ref.player):
		main_ref.player.preview_saved_character(roster_list[idx])

func _select_race(rid: String) -> void:
	selected_race = rid
	for k in race_btns.keys():
		var rn: String = str(GameData.RACES[k]["name"])
		race_btns[k].text = ("★ " + rn) if k == rid else rn
	_update_start_desc()
	if is_instance_valid(main_ref) and is_instance_valid(main_ref.player):
		main_ref.player.preview_class(selected_class, selected_race)

func _select_class(cid: String) -> void:
	selected_class = cid
	for k in class_btns.keys():
		class_btns[k].text = "★ Выбран" if k == cid else "Выбрать"
	_update_start_desc()
	if is_instance_valid(main_ref) and is_instance_valid(main_ref.player):
		main_ref.player.preview_class(selected_class, selected_race)

func _update_start_desc() -> void:
	if not is_instance_valid(class_desc_lbl):
		return
	var rdata: Dictionary = GameData.RACES[selected_race]
	var cdata: Dictionary = GameData.CLASSES[selected_class]
	class_desc_lbl.text = "%s (%s): %s | %s" % [str(rdata["name"]), str(rdata["bonus"]), str(cdata["name"]), str(cdata["desc"])]

func _process(_delta: float) -> void:
	if not is_instance_valid(main_ref) or not main_ref.game_started or not hud_root.visible:
		joy_vec = Vector2.ZERO
		return
	var pl: Node3D = main_ref.player
	if not is_instance_valid(pl):
		joy_vec = Vector2.ZERO
		return
	if is_instance_valid(touch_controls_root):
		touch_controls_root.visible = touch_ui_enabled and not modal_panel.visible
	if is_instance_valid(touch_controls_root) and touch_controls_root.visible and is_instance_valid(touch_joy):
		joy_vec = touch_joy.joy_vec
	else:
		joy_vec = Vector2.ZERO

	var cdata: Dictionary = GameData.CLASSES[pl.class_id]
	p_portrait.texture = PixelArt.portraits.get(pl.class_id, PixelArt.portraits["warrior"])
	lbl_p_name.text = "[%d] %s (%s)" % [pl.level, pl.char_name, str(cdata["name"])]

	bar_p_hp.max_value = pl.max_hp
	bar_p_hp.value = pl.hp
	lbl_p_hp.text = "%d / %d" % [int(pl.hp), int(pl.max_hp)]
	lbl_orb_hp.text = "%d" % int(pl.hp)

	bar_p_res.max_value = maxf(1.0, pl.max_resource)
	bar_p_res.value = pl.resource
	lbl_p_res.text = "%s: %d/%d" % [str(cdata["res_name"]), int(pl.resource), int(pl.max_resource)]
	lbl_orb_res.text = "%d" % int(pl.resource)

	lbl_p_gold.text = "Зол: %d | Оск: %d | Зелья: %d" % [pl.gold, pl.shards, pl.potions]

	# Баффы
	var buffs: Array = []
	if pl.buff_shield > 0.0:
		buffs.append("[Щит %.1fс]" % pl.buff_shield)
	if pl.buff_invuln > 0.0:
		buffs.append("[Неуязвим %.1fс]" % pl.buff_invuln)
	if pl.is_mounted:
		buffs.append("[Верхом +60%]")
	if pl.class_id == "ranger":
		buffs.append("[Волк-питомец]")
	elif pl.class_id == "warlock":
		buffs.append("[Бес-питомец]")
	if pl.skill_points > 0:
		buffs.append("[Очки умений [K]: %d]" % pl.skill_points)
	lbl_buffs.text = " ".join(buffs)

	# Фреймы союзной группы в данже/рейде
	if main_ref.world_3d.in_instance and not main_ref.party_bots.is_empty():
		party_panel.visible = true
		for c in party_vbox.get_children():
			c.queue_free()
		var hdr_p: Label = Label.new()
		hdr_p.text = "ГРУППА:"
		hdr_p.add_theme_font_size_override("font_size", 11)
		hdr_p.add_theme_color_override("font_color", Color(0.5, 0.95, 1.0))
		party_vbox.add_child(hdr_p)
		for b in main_ref.party_bots:
			if is_instance_valid(b):
				var bl: Label = Label.new()
				bl.text = "%s (%d%%)" % [b.bot_name, int(round(b.hp / maxf(1.0, b.max_hp) * 100.0))]
				bl.add_theme_font_size_override("font_size", 11)
				bl.add_theme_color_override("font_color", Color(0.45, 0.98, 0.58))
				party_vbox.add_child(bl)
	else:
		party_panel.visible = false

	# Цель
	if is_instance_valid(pl.target) and not pl.target.is_dead:
		target_panel.visible = true
		t_portrait.texture = PixelArt.portraits["boss"] if pl.target.is_boss else PixelArt.portraits["mob"]
		lbl_t_name.text = "[%d] %s" % [pl.target.level, pl.target.mob_name]
		bar_t_hp.max_value = pl.target.max_hp
		bar_t_hp.value = pl.target.hp
		lbl_t_hp.text = "%d / %d" % [int(pl.target.hp), int(pl.target.max_hp)]
	else:
		target_panel.visible = false

	# Зона и данж
	if main_ref.world_3d.in_instance:
		lbl_zone.text = str(main_ref.world_3d.current_instance.get("name", "Подземелье"))
		btn_leave_inst.visible = true
	else:
		var z: Dictionary = GameData.get_zone_at(pl.position)
		lbl_zone.text = "%s (%d-%d)" % [str(z["name"]), int(z["min_lv"]), int(z["max_lv"])]
		btn_leave_inst.visible = false

	# Трекер квестов
	var qt_txt: String = ""
	for qid in pl.active_quests.keys():
		var q: Dictionary = GameData.get_quest_by_id(str(qid))
		if not q.is_empty():
			var cur: int = int(pl.active_quests[qid])
			var need: int = int(q["need"])
			var col_h: String = "#55ff66" if cur >= need else "#ffee77"
			qt_txt += "[color=%s]• %s: %d/%d[/color]\n" % [col_h, str(q["title"]), cur, need]
	if qt_txt == "":
		qt_txt = "[color=#99aabb]Нет активных заданий.[/color]"
	quest_tracker_lbl.text = qt_txt

	# Панель умений (открытие по уровню и ранги!)
	var skills: Array = cdata["skills"]
	for i in range(5):
		var sk: Dictionary = skills[i]
		var req_lv: int = int(sk.get("unlock_lv", 1))
		var unlocked: bool = pl.level >= req_lv
		var rank: int = clampi(int(pl.skill_ranks[i]), 1, 5)
		if unlocked:
			skill_btns[i].icon = PixelArt.get_skill_icon(str(sk["id"]))
			skill_rank_lbls[i].text = "Р" + str(rank)
			skill_btns[i].tooltip_text = "%s [Ранг %d/5] (%s)\n%s\nСтоимость: %d | КД: %.1fс" % [str(sk["name"]), rank, str(sk["key"]), str(sk["desc"]), int(sk["cost"]), float(sk["cd"])]
			var cd: float = float(pl.skill_cds[i])
			skill_cd_lbls[i].text = ("%.1f" % cd) if cd > 0.05 else ""
			skill_cd_lbls[i].add_theme_color_override("font_color", Color(1.0, 0.38, 0.28))
			skill_btns[i].modulate = Color(0.55, 0.55, 0.6) if cd > 0.05 else Color.WHITE
		else:
			skill_btns[i].icon = PixelArt.icons["lock"]
			skill_rank_lbls[i].text = ""
			skill_cd_lbls[i].text = "Ур.%d" % req_lv
			skill_cd_lbls[i].add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
			skill_btns[i].tooltip_text = "%s\nОткроется на %d уровне!" % [str(sk["name"]), req_lv]
			skill_btns[i].modulate = Color(0.68, 0.68, 0.75)

	lbl_potion_cnt.text = str(pl.potions)
	if pl.level < 20:
		btn_mount.modulate = Color(0.45, 0.45, 0.52)
		lbl_mount_lock.visible = true
		btn_mount.tooltip_text = "Боевой скакун\nОткрывается на 20 уровне"
	else:
		lbl_mount_lock.visible = false
		btn_mount.modulate = Color(0.5, 1.0, 0.6) if pl.is_mounted else Color.WHITE
		btn_mount.tooltip_text = "Боевой скакун [M]\nСкорость +60%"

	var hz: Dictionary = GameData.get_zone_by_id(pl.hearth_zone)
	btn_hearth.tooltip_text = "Камень возвращения [H]\nДом: таверна (%s)" % str(hz["town"])
	lbl_hearth_cd.text = ("%dс" % int(ceil(pl.hearth_cd))) if pl.hearth_cd > 0.05 else ""
	btn_hearth.modulate = Color(0.55, 0.55, 0.62) if pl.hearth_cd > 0.05 else Color.WHITE

	if pl.hearth_cast > 0.0:
		cast_panel.visible = true
		cast_bar.max_value = 2.5
		cast_bar.value = 2.5 - pl.hearth_cast
		cast_lbl.text = "Камень возвращения... %.1fс" % pl.hearth_cast
	else:
		cast_panel.visible = false

	var need_xp: int = GameData.xp_for_level(pl.level)
	bar_xp.max_value = need_xp
	bar_xp.value = pl.xp
	lbl_xp.text = "Опыт: %d / %d (Ур. %d)" % [pl.xp, need_xp, pl.level]

func _item_compare_tooltip(item: Dictionary, pl: Node3D) -> String:
	var r: int = int(item.get("rarity", 0))
	var sl: String = str(item["slot"])
	var eq: Dictionary = pl.equipment.get(sl, {})
	var atk_v: int = int(round(GameData.item_effective_stat(item, "atk")))
	var arm_v: int = int(round(GameData.item_effective_stat(item, "arm")))
	var hp_v: int = int(round(GameData.item_effective_stat(item, "hp")))
	var crit_v: float = float(item.get("crit", 0.0))

	var txt: String = "%s [%s]\nКачество: %s | Ур.пред: %d\nАТК: +%d | БРН: +%d | HP: +%d | Крит: +%.1f%%" % [
		GameData.item_display_name(item), str(GameData.SLOT_NAMES[sl]),
		str(GameData.RARITIES[r]["name"]), int(item["ilvl"]),
		atk_v, arm_v, hp_v, crit_v
	]
	if not eq.is_empty():
		var datk: int = atk_v - int(round(GameData.item_effective_stat(eq, "atk")))
		var darm: int = arm_v - int(round(GameData.item_effective_stat(eq, "arm")))
		var dhp: int = hp_v - int(round(GameData.item_effective_stat(eq, "hp")))
		txt += "\n--- Сравнение с надетым (%s) ---\nΔ АТК: %+d | Δ БРН: %+d | Δ HP: %+d" % [
			GameData.item_display_name(eq), datk, darm, dhp
		]
	return txt

func toggle_modal(kind: String) -> void:
	if modal_panel.visible and current_modal == kind:
		close_modal()
		return
	current_modal = kind
	modal_panel.visible = true
	SoundFX.play("ui")
	_refresh_modal()

func close_modal() -> void:
	modal_panel.visible = false
	current_modal = ""
	current_npc = null

func open_npc_dialog(npc: Node) -> void:
	current_npc = npc
	current_modal = "npc"
	modal_panel.visible = true
	SoundFX.play("ui")
	_refresh_modal()

func show_death_popup() -> void:
	current_modal = "death"
	modal_panel.visible = true
	_refresh_modal()

func _clear_modal_body() -> void:
	for c in modal_body.get_children():
		c.queue_free()

func _refresh_modal() -> void:
	_clear_modal_body()
	var pl: Node3D = main_ref.player
	if not is_instance_valid(pl):
		return

	match current_modal:
		"char":
			modal_title.text = "ГЕРОЙ, СНАРЯЖЕНИЕ И СТАТИСТИКА"
			var st: Label = Label.new()
			st.text = "%s • Ур. %d %s | HP: %d | АТК: %d | БРН: %d | Крит: %.1f%% | Оск: %d" % [
				pl.char_name, pl.level, str(GameData.CLASSES[pl.class_id]["name"]),
				int(pl.max_hp), int(pl.atk_power), int(pl.armor_val), pl.crit_chance, pl.shards
			]
			st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			modal_body.add_child(st)

			var stats_l: Label = Label.new()
			stats_l.text = "Убито врагов: %d | Боссов: %d | Сундуков: %d | Данжей/Рейдов: %d" % [
				pl.kills_count, pl.bosses_killed, pl.chests_opened, pl.dungeons_cleared
			]
			stats_l.add_theme_color_override("font_color", Color(0.65, 0.90, 1.0))
			modal_body.add_child(stats_l)

			for s in GameData.SLOTS:
				var item: Dictionary = pl.equipment.get(s, {})
				var row: HBoxContainer = HBoxContainer.new()
				modal_body.add_child(row)
				var ic: TextureRect = TextureRect.new()
				ic.texture = PixelArt.get_item_icon(s)
				ic.custom_minimum_size = Vector2(28, 28)
				ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				row.add_child(ic)

				var lbl: Label = Label.new()
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if item.is_empty():
					lbl.text = "%s: [Пусто]" % str(GameData.SLOT_NAMES[s])
					lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
				else:
					var r: int = int(item.get("rarity", 0))
					lbl.text = "%s: %s (Ур.%d | АТК+%d БРН+%d HP+%d)" % [
						str(GameData.SLOT_NAMES[s]), GameData.item_display_name(item), int(item["ilvl"]),
						int(GameData.item_effective_stat(item, "atk")),
						int(GameData.item_effective_stat(item, "arm")),
						int(GameData.item_effective_stat(item, "hp"))
					]
					lbl.add_theme_color_override("font_color", GameData.RARITIES[r]["color"])
					lbl.mouse_filter = Control.MOUSE_FILTER_STOP
					lbl.tooltip_text = _item_compare_tooltip(item, pl)
				row.add_child(lbl)

		"bag":
			modal_title.text = "РЮКЗАК (%d/30) • Золото: %d | Осколки: %d" % [pl.inventory.size(), pl.gold, pl.shards]
			if pl.inventory.is_empty():
				var e_lbl: Label = Label.new()
				e_lbl.text = "Рюкзак пуст. Выбивайте трофеи с врагов или открывайте сундуки [E]!"
				modal_body.add_child(e_lbl)
			for i in range(pl.inventory.size()):
				var item: Dictionary = pl.inventory[i]
				var r: int = int(item.get("rarity", 0))
				var row: HBoxContainer = HBoxContainer.new()
				modal_body.add_child(row)

				var ic: TextureRect = TextureRect.new()
				ic.texture = PixelArt.get_item_icon(str(item["slot"]))
				ic.custom_minimum_size = Vector2(28, 28)
				row.add_child(ic)

				var lbl: Label = Label.new()
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.text = "%s [%s Ур.%d] (АТК+%d БРН+%d HP+%d)" % [
					GameData.item_display_name(item), str(GameData.SLOT_NAMES[item["slot"]]), int(item["ilvl"]),
					int(GameData.item_effective_stat(item, "atk")),
					int(GameData.item_effective_stat(item, "arm")),
					int(GameData.item_effective_stat(item, "hp"))
				]
				lbl.add_theme_color_override("font_color", GameData.RARITIES[r]["color"])
				lbl.mouse_filter = Control.MOUSE_FILTER_STOP
				lbl.tooltip_text = _item_compare_tooltip(item, pl)
				row.add_child(lbl)

				var idx: int = i
				var b_eq: Button = Button.new()
				b_eq.text = "Надеть"
				b_eq.tooltip_text = _item_compare_tooltip(item, pl)
				b_eq.pressed.connect(func() -> void: pl.equip_from_inventory(idx); _refresh_modal())
				row.add_child(b_eq)

				var b_sal: Button = Button.new()
				b_sal.text = "Разобрать"
				b_sal.pressed.connect(func() -> void: pl.salvage_inventory_item(idx); _refresh_modal())
				row.add_child(b_sal)

		"skills":
			modal_title.text = "КНИГА УМЕНИЙ [K] (Свободно очков: %d)" % pl.skill_points
			var sk_info: Label = Label.new()
			sk_info.text = "Умения открываются с ростом уровня (1, 3, 6, 10, 15). Каждый ранг даёт +18% силы и -5% перезарядки!"
			sk_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sk_info.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
			modal_body.add_child(sk_info)

			var sks: Array = GameData.CLASSES[pl.class_id]["skills"]
			for i in range(5):
				var sk: Dictionary = sks[i]
				var req_lv: int = int(sk.get("unlock_lv", 1))
				var unlocked: bool = pl.level >= req_lv
				var rank: int = clampi(int(pl.skill_ranks[i]), 1, 5)
				var pan: PanelContainer = PanelContainer.new()
				pan.add_theme_stylebox_override("panel", PixelArt.box_dark)
				modal_body.add_child(pan)
				var hb: HBoxContainer = HBoxContainer.new()
				hb.add_theme_constant_override("separation", 8)
				pan.add_child(hb)

				var ic: TextureRect = TextureRect.new()
				ic.texture = PixelArt.get_skill_icon(str(sk["id"])) if unlocked else PixelArt.icons["lock"]
				ic.custom_minimum_size = Vector2(36, 36)
				ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hb.add_child(ic)

				var lvb: VBoxContainer = VBoxContainer.new()
				lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(lvb)

				var sl: Label = Label.new()
				sl.text = "%s [%s] — %s" % [str(sk["name"]), str(sk["key"]), ("Ранг %d/5" % rank) if unlocked else ("Откроется на %d ур." % req_lv)]
				sl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45) if unlocked else Color(0.65, 0.65, 0.72))
				lvb.add_child(sl)

				var dl: Label = Label.new()
				dl.text = str(sk["desc"])
				dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				dl.add_theme_font_size_override("font_size", 11)
				lvb.add_child(dl)

				var idx: int = i
				var b_up: Button = Button.new()
				b_up.text = "Улучшить" if rank < 5 else "МАКС"
				b_up.disabled = (not unlocked) or pl.skill_points <= 0 or rank >= 5
				b_up.pressed.connect(func() -> void:
					pl.skill_points -= 1
					pl.skill_ranks[idx] = rank + 1
					SoundFX.play("quest")
					_refresh_modal()
				)
				hb.add_child(b_up)

		"talents":
			modal_title.text = "ДРЕВО ТАЛАНТОВ (Свободно очков: %d)" % pl.available_talent_points()
			for t in GameData.TALENTS:
				var tid: String = str(t["id"])
				var cur_r: int = int(pl.talents.get(tid, 0))
				var max_r: int = int(t["max"])
				var row: HBoxContainer = HBoxContainer.new()
				modal_body.add_child(row)

				var lbl: Label = Label.new()
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.text = "%s [%d/%d] — %s" % [str(t["name"]), cur_r, max_r, str(t["desc"])]
				row.add_child(lbl)

				var b_up: Button = Button.new()
				b_up.text = "+1"
				b_up.disabled = pl.available_talent_points() <= 0 or cur_r >= max_r
				b_up.pressed.connect(func() -> void:
					pl.talents[tid] = cur_r + 1
					pl.recalc_stats()
					SoundFX.play("quest")
					_refresh_modal()
				)
				row.add_child(b_up)

		"quests":
			modal_title.text = "ЖУРНАЛ ЗАДАНИЙ"
			if pl.active_quests.is_empty():
				var l: Label = Label.new()
				l.text = "Нет активных заданий. Подойдите к NPC со знаком [!] в лагере."
				modal_body.add_child(l)
			for qid in pl.active_quests.keys():
				var q: Dictionary = GameData.get_quest_by_id(str(qid))
				if q.is_empty():
					continue
				var cur: int = int(pl.active_quests[qid])
				var need: int = int(q["need"])
				var ql: Label = Label.new()
				ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ql.text = "• %s [%d/%d]\n  %s (Награда: %d XP, %d зол.)" % [str(q["title"]), cur, need, str(q["desc"]), int(q["xp"]), int(q["gold"])]
				ql.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55) if cur >= need else Color(0.95, 0.90, 0.65))
				modal_body.add_child(ql)

		"map":
			modal_title.text = "КАРТА КОНТИНЕНТА [N]"
			var minfo: Label = Label.new()
			minfo.text = "Исследуйте регионы, заставы и находите таверны для Камня возвращения:"
			modal_body.add_child(minfo)

			# Большая иллюстрированная карта континента (495x330)
			var map_wrap: PanelContainer = PanelContainer.new()
			map_wrap.custom_minimum_size = Vector2(503, 338)
			map_wrap.add_theme_stylebox_override("panel", PixelArt.box_gold)
			modal_body.add_child(map_wrap)

			var map_canvas: Control = Control.new()
			map_canvas.custom_minimum_size = Vector2(495, 330)
			map_wrap.add_child(map_canvas)

			var map_tex_rect: TextureRect = TextureRect.new()
			map_tex_rect.texture = PixelArt.world_map_tex
			map_tex_rect.custom_minimum_size = Vector2(495, 330)
			map_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
			map_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			map_canvas.add_child(map_tex_rect)

			var sx_a: float = 495.0 / GameData.WORLD_W
			var sz_a: float = 330.0 / GameData.WORLD_H

			# Метки регионов, ориентиров и городов (без телепортации!)
			for z in GameData.ZONES:
				var zid: String = str(z["id"])
				var unlocked: bool = pl.unlocked_zones.has(zid)
				var hub: Vector3 = z["hub"]
				var zc: Vector2 = z["center"]
				var zlbl: Label = Label.new()
				zlbl.text = "%s (%d–%d)" % [str(z["name"]), int(z["min_lv"]), int(z["max_lv"])]
				zlbl.position = Vector2(clampf(zc.x * sx_a - 50.0, 8.0, 355.0), clampf(zc.y * sz_a - 42.0, 6.0, 308.0))
				zlbl.add_theme_font_size_override("font_size", 10)
				zlbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.65))
				zlbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
				zlbl.add_theme_constant_override("outline_size", 2)
				map_canvas.add_child(zlbl)

				var town_lbl: Label = Label.new()
				town_lbl.text = str(z["town"]) if unlocked else ("? " + str(z["town"]))
				town_lbl.position = Vector2(clampf(hub.x * sx_a - 28.0, 6.0, 376.0), clampf(hub.z * sz_a + 10.0, 24.0, 304.0))
				town_lbl.add_theme_font_size_override("font_size", 10)
				town_lbl.add_theme_color_override("font_color", Color(0.55, 0.98, 0.68) if unlocked else Color(0.75, 0.75, 0.80))
				town_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
				town_lbl.add_theme_constant_override("outline_size", 2)
				map_canvas.add_child(town_lbl)

				var dot_t: Label = Label.new()
				dot_t.text = "🏰"
				dot_t.position = Vector2(hub.x * sx_a - 6.0, hub.z * sz_a - 8.0)
				dot_t.add_theme_font_size_override("font_size", 11)
				map_canvas.add_child(dot_t)

				var bpos: Vector3 = z["boss_pos"]
				var blbl: Label = Label.new()
				blbl.text = "☠"
				blbl.position = Vector2(bpos.x * sx_a - 5.0, bpos.z * sz_a - 7.0)
				blbl.add_theme_font_size_override("font_size", 12)
				blbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.20))
				blbl.mouse_filter = Control.MOUSE_FILTER_STOP
				blbl.tooltip_text = str(GameData.MOBS[z["boss"]]["name"])
				map_canvas.add_child(blbl)

			# Маркер игрока на карте
			var p_mark: Label = Label.new()
			p_mark.text = "★"
			p_mark.position = Vector2(pl.position.x * sx_a - 6.0, pl.position.z * sz_a - 8.0)
			p_mark.add_theme_font_size_override("font_size", 14)
			p_mark.add_theme_color_override("font_color", Color(0.25, 0.96, 1.0))
			p_mark.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
			p_mark.add_theme_constant_override("outline_size", 3)
			map_canvas.add_child(p_mark)

			var leg: Label = Label.new()
			leg.text = "★ Вы здесь   |   ☠ Главарь земли   |   🏰 Город и таверна"
			leg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			leg.add_theme_font_size_override("font_size", 11)
			leg.add_theme_color_override("font_color", Color(0.84, 0.88, 0.95))
			modal_body.add_child(leg)

		"dungeons":
			modal_title.text = "ПОИСК ПОДЗЕМЕЛИЙ И РЕЙДОВ"
			var info: Label = Label.new()
			info.text = "С вами в бой отправятся союзные боты-герои (Танк, Лекарь и Бойцы)!"
			info.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
			modal_body.add_child(info)

			for d in GameData.DUNGEONS:
				var pan: PanelContainer = PanelContainer.new()
				pan.add_theme_stylebox_override("panel", PixelArt.box_dark)
				modal_body.add_child(pan)

				var hb: HBoxContainer = HBoxContainer.new()
				pan.add_child(hb)
				var lvb: VBoxContainer = VBoxContainer.new()
				lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(lvb)

				var dtitle: Label = Label.new()
				dtitle.text = "%s — %s (Мин. ур. %d)" % [str(d["name"]), str(d["kind"]), int(d["min_lv"])]
				dtitle.add_theme_color_override("font_color", Color(1.0, 0.58, 0.20) if bool(d["is_raid"]) else Color(0.45, 0.85, 1.0))
				lvb.add_child(dtitle)

				var ddesc: Label = Label.new()
				ddesc.text = str(d["desc"])
				ddesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ddesc.add_theme_font_size_override("font_size", 11)
				lvb.add_child(ddesc)

				var b_go: Button = Button.new()
				b_go.text = "Войти" if pl.level >= int(d["min_lv"]) else ("Ур.%d+" % int(d["min_lv"]))
				b_go.disabled = pl.level < int(d["min_lv"]) or main_ref.world_3d.in_instance
				var did: String = str(d["id"])
				b_go.pressed.connect(func() -> void:
					close_modal()
					main_ref.enter_dungeon_instance(did)
				)
				hb.add_child(b_go)

		"npc":
			if is_instance_valid(current_npc):
				_build_npc_modal(current_npc)

		"death":
			modal_title.text = "ВЫ ПОГИБЛИ"
			var dl: Label = Label.new()
			dl.text = "Дух вашего героя пал в бою. Воскресните у костра в безопасном лагере!"
			modal_body.add_child(dl)
			var rb: Button = Button.new()
			rb.text = "Воскреснуть с полным здоровьем"
			rb.pressed.connect(func() -> void:
				pl.respawn_at_camp()
				close_modal()
			)
			modal_body.add_child(rb)

		"game_menu":
			modal_title.text = "МЕНЮ ИГРЫ"
			var gm_vb: VBoxContainer = VBoxContainer.new()
			gm_vb.add_theme_constant_override("separation", 8)
			modal_body.add_child(gm_vb)

			var b_cont: Button = Button.new()
			b_cont.text = "Продолжить игру"
			b_cont.custom_minimum_size = Vector2(260, 34)
			b_cont.pressed.connect(func() -> void: close_modal())
			gm_vb.add_child(b_cont)

			var b_save: Button = Button.new()
			b_save.text = "Сохранить персонажа"
			b_save.custom_minimum_size = Vector2(260, 34)
			b_save.pressed.connect(func() -> void:
				main_ref.save_now()
				close_modal()
			)
			gm_vb.add_child(b_save)

			var b_chars: Button = Button.new()
			b_chars.text = "Выбор персонажа"
			b_chars.custom_minimum_size = Vector2(260, 34)
			b_chars.pressed.connect(func() -> void: main_ref.return_to_char_select())
			gm_vb.add_child(b_chars)

			var b_quit: Button = Button.new()
			b_quit.text = "Выйти на рабочий стол"
			b_quit.custom_minimum_size = Vector2(260, 34)
			b_quit.pressed.connect(func() -> void:
				main_ref.save_now()
				get_tree().quit()
			)
			gm_vb.add_child(b_quit)

func _build_npc_modal(npc: Node) -> void:
	var pl: Node3D = main_ref.player
	modal_title.text = "%s %s" % [npc.npc_name, npc.get_role_tag()]
	match npc.role:
		"quest":
			var found: bool = false
			for q in GameData.QUESTS:
				if str(q["zone"]) != npc.zone_id or str(q.get("npc_id", npc.zone_id + "_cmd")) != npc.npc_id:
					continue
				var qid: String = str(q["id"])
				if pl.active_quests.has(qid):
					found = true
					var cur: int = int(pl.active_quests[qid])
					var need: int = int(q["need"])
					var row: HBoxContainer = HBoxContainer.new()
					modal_body.add_child(row)
					var l: Label = Label.new()
					l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					l.text = "%s (%d/%d)" % [str(q["title"]), cur, need]
					row.add_child(l)
					if cur >= need:
						var q_ref: Dictionary = q
						var b: Button = Button.new()
						b.text = "Сдать (%d XP, %d з)" % [int(q["xp"]), int(q["gold"])]
						b.pressed.connect(func() -> void: _turn_in_quest(q_ref); _refresh_modal())
						row.add_child(b)
				elif not pl.completed_quests.has(qid) and pl.level >= int(q["min_lv"]) - 2:
					var req: String = str(q.get("req", ""))
					if req != "" and not pl.completed_quests.has(req):
						continue
					found = true
					var pan: PanelContainer = PanelContainer.new()
					pan.add_theme_stylebox_override("panel", PixelArt.box_dark)
					modal_body.add_child(pan)
					var vb: VBoxContainer = VBoxContainer.new()
					pan.add_child(vb)
					var ql: Label = Label.new()
					ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					ql.text = "[!] %s (Ур.%d)\n%s\nНаграда: %d XP, %d зол. + Экипировка" % [str(q["title"]), int(q["min_lv"]), str(q["desc"]), int(q["xp"]), int(q["gold"])]
					vb.add_child(ql)
					var b_acc: Button = Button.new()
					b_acc.text = "Принять задание"
					b_acc.pressed.connect(func() -> void:
						pl.active_quests[qid] = 0
						SoundFX.play("quest")
						_refresh_modal()
					)
					vb.add_child(b_acc)
			if not found:
				var nl: Label = Label.new()
				nl.text = "Новых поручений у меня пока нет, путник. Расспросите других жителей земель!"
				modal_body.add_child(nl)

		"vendor":
			var p_cost: int = 12 + pl.level * 2
			var b1: Button = Button.new()
			b1.text = "Купить Зелье лечения (%d зол.)" % p_cost
			b1.pressed.connect(func() -> void:
				if pl.gold >= p_cost:
					pl.gold -= p_cost
					pl.potions += 1
					SoundFX.play("loot")
					_refresh_modal()
			)
			modal_body.add_child(b1)

			var g_cost: int = 45 + pl.level * 12
			var b2: Button = Button.new()
			b2.text = "Сундук удачи (случайная вещь ур.%d за %d зол.)" % [pl.level, g_cost]
			b2.pressed.connect(func() -> void:
				if pl.gold >= g_cost and pl.inventory.size() < 30:
					pl.gold -= g_cost
					pl.add_item_to_inventory(GameData.generate_item(pl.level))
					_refresh_modal()
			)
			modal_body.add_child(b2)

			var b3: Button = Button.new()
			b3.text = "Продать все Обычные и Необычные вещи из рюкзака"
			b3.pressed.connect(func() -> void:
				var total: int = 0
				for i in range(pl.inventory.size() - 1, -1, -1):
					if int(pl.inventory[i]["rarity"]) <= 1:
						total += int(pl.inventory[i]["value"])
						pl.inventory.remove_at(i)
				pl.gold += total
				SoundFX.play("loot")
				main_ref.log_chat("[color=#ffdd55]Продано хлама на %d золота.[/color]" % total)
				_refresh_modal()
			)
			modal_body.add_child(b3)

		"smith":
			var info: Label = Label.new()
			info.text = "Осколков: %d | Золото: %d. Заточка усиливает вещь на +14%% за уровень!" % [pl.shards, pl.gold]
			modal_body.add_child(info)
			for s in GameData.SLOTS:
				var item: Dictionary = pl.equipment.get(s, {})
				if item.is_empty():
					continue
				var upg: int = int(item.get("upgrade", 0))
				var need_sh: int = 2 + upg * 2
				var need_g: int = 25 + upg * 35
				var row: HBoxContainer = HBoxContainer.new()
				modal_body.add_child(row)
				var l: Label = Label.new()
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				l.text = "%s (%s)" % [GameData.item_display_name(item), str(GameData.SLOT_NAMES[s])]
				row.add_child(l)
				var b: Button = Button.new()
				b.text = "Заточить +%d (%d оск, %d з)" % [upg + 1, need_sh, need_g] if upg < 10 else "МАКС (+10)"
				b.disabled = upg >= 10 or pl.shards < need_sh or pl.gold < need_g
				var sl: String = s
				b.pressed.connect(func() -> void:
					pl.shards -= need_sh
					pl.gold -= need_g
					pl.equipment[sl]["upgrade"] = upg + 1
					pl.recalc_stats()
					pl._rebuild_rig()
					SoundFX.play("crit")
					_refresh_modal()
				)
				row.add_child(b)

		"innkeeper":
			var z: Dictionary = GameData.get_zone_by_id(npc.zone_id)
			var ilbl: Label = Label.new()
			ilbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ilbl.text = "У нас тепло и безопасно, путник! Здесь вы можете сделать таверну %s своим домом для Камня возвращения." % str(z["town"])
			modal_body.add_child(ilbl)

			var b_bind: Button = Button.new()
			var already_home: bool = (pl.hearth_zone == npc.zone_id)
			b_bind.text = "Камень возвращения привязан сюда" if already_home else ("Сделать %s своим домом (Камень возвращения)" % str(z["town"]))
			b_bind.disabled = already_home
			b_bind.pressed.connect(func() -> void:
				pl.bind_hearthstone(npc.zone_id, npc.position + Vector3(0.0, 0.0, 2.2))
				_refresh_modal()
			)
			modal_body.add_child(b_bind)

			var b_rest: Button = Button.new()
			b_rest.text = "Отдохнуть у очага (Восстановить здоровье и ману)"
			b_rest.pressed.connect(func() -> void:
				pl.hp = pl.max_hp
				pl.resource = pl.max_resource
				SoundFX.play("heal")
				main_ref.vfx.spawn_ring(pl.position, 2.2, Color(0.4, 1.0, 0.55), 0.5)
				close_modal()
			)
			modal_body.add_child(b_rest)

			var ale_cost: int = 10 + pl.level * 2
			var b_ale: Button = Button.new()
			b_ale.text = "Купить дорожный провиант (+1 зелье за %d зол.)" % ale_cost
			b_ale.disabled = pl.gold < ale_cost
			b_ale.pressed.connect(func() -> void:
				if pl.gold >= ale_cost:
					pl.gold -= ale_cost
					pl.potions += 1
					SoundFX.play("loot")
					_refresh_modal()
			)
			modal_body.add_child(b_ale)

		"dungeon":
			toggle_modal("dungeons")

func _turn_in_quest(q: Dictionary) -> void:
	var pl: Node3D = main_ref.player
	var qid: String = str(q["id"])
	pl.active_quests.erase(qid)
	if not pl.completed_quests.has(qid):
		pl.completed_quests.append(qid)
	pl.gold += int(q["gold"])
	pl.gain_xp(int(q["xp"]))
	var rew: Dictionary = GameData.generate_item(int(q["reward_lv"]), int(q["reward_rarity"]))
	pl.add_item_to_inventory(rew)
	SoundFX.play("quest")
	main_ref.log_chat("[color=#ffdd44]Задание '%s' сдано![/color]" % str(q["title"]))
