extends Node

const ZONE_W: float = 220.0
const ZONE_H: float = 220.0
const WORLD_W: float = 660.0
const WORLD_H: float = 440.0
const WATER_Y: float = -0.45
const MAX_LEVEL: int = 60
const ROSTER_PATH: String = "user://eternia_roster_v4.json"
const LEGACY_SAVE_PATH: String = "user://eternia_3d_v3_save.json"

const RANDOM_NAMES: Array = [
	"Элдрин", "Торин", "Мира", "Вальд", "Лира", "Каэль", "Бран", "Селена", "Гром", "Велан"
]

var RACES: Dictionary = {
	"human": {
		"name": "Человек", "skin": Color(0.92, 0.76, 0.62), "hair": Color(0.32, 0.20, 0.12),
		"scale": Vector3(1.0, 1.0, 1.0),
		"hp_mult": 1.0, "atk_mult": 1.0, "res_mult": 1.0, "xp_mult": 1.10, "vamp": 0.0,
		"bonus": "+10% к опыту"
	},
	"elf": {
		"name": "Эльф", "skin": Color(0.84, 0.80, 0.90), "hair": Color(0.85, 0.90, 0.98),
		"scale": Vector3(0.92, 1.12, 0.92),
		"hp_mult": 0.95, "atk_mult": 1.02, "res_mult": 1.15, "xp_mult": 1.0, "vamp": 0.0,
		"bonus": "+15% Маны/Энергии"
	},
	"dwarf": {
		"name": "Дворф", "skin": Color(0.88, 0.70, 0.56), "hair": Color(0.68, 0.30, 0.14),
		"scale": Vector3(1.18, 0.84, 1.14),
		"hp_mult": 1.14, "atk_mult": 1.0, "res_mult": 1.0, "xp_mult": 1.0, "vamp": 0.0,
		"bonus": "+14% к здоровью"
	},
	"orc": {
		"name": "Орк", "skin": Color(0.38, 0.62, 0.30), "hair": Color(0.14, 0.12, 0.14),
		"scale": Vector3(1.18, 1.10, 1.14),
		"hp_mult": 1.06, "atk_mult": 1.12, "res_mult": 1.0, "xp_mult": 1.0, "vamp": 0.0,
		"bonus": "+12% к силе атаки"
	},
	"undead": {
		"name": "Нежить", "skin": Color(0.56, 0.64, 0.60), "hair": Color(0.20, 0.22, 0.26),
		"scale": Vector3(0.94, 1.02, 0.92),
		"hp_mult": 1.0, "atk_mult": 1.04, "res_mult": 1.05, "xp_mult": 1.0, "vamp": 0.05,
		"bonus": "+5% вампиризма"
	}
}

# 6 органичных непохожих друг на друга локаций континента Этернии
var ZONES: Array = [
	{
		"id": "elwynn", "name": "Земли Рассвета", "town": "Яснодол", "min_lv": 1, "max_lv": 12,
		"center": Vector2(115.0, 240.0), "elev": 0.9,
		"ground": Color(0.20, 0.45, 0.19), "accent": Color(0.13, 0.34, 0.14),
		"ambient": Color(0.56, 0.64, 0.58), "sun": Color(1.0, 0.94, 0.80),
		"hub": Vector3(68.0, 0.0, 238.0), "boss_pos": Vector3(166.0, 0.0, 352.0),
		"landmarks": [
			{"id": "lm_mine", "name": "Копи Тёмного Ручья", "pos": Vector3(114.0, 0.0, 152.0), "mob": "kobold"},
			{"id": "lm_woods", "name": "Волчья Чаща", "pos": Vector3(154.0, 0.0, 224.0), "mob": "wolf"},
			{"id": "lm_defias", "name": "Бухта Корсаров", "pos": Vector3(106.0, 0.0, 342.0), "mob": "bandit"}
		],
		"mobs": ["wolf", "kobold", "bandit"], "boss": "boss_drog", "decor": "forest"
	},
	{
		"id": "duskwood", "name": "Сумеречный Лес", "town": "Тёмный Дозор", "min_lv": 12, "max_lv": 22,
		"center": Vector2(288.0, 320.0), "elev": 0.5,
		"ground": Color(0.13, 0.21, 0.23), "accent": Color(0.08, 0.14, 0.17),
		"ambient": Color(0.32, 0.38, 0.52), "sun": Color(0.62, 0.72, 0.96),
		"hub": Vector3(246.0, 0.0, 272.0), "boss_pos": Vector3(334.0, 0.0, 384.0),
		"landmarks": [
			{"id": "lm_grave", "name": "Воронье Кладбище", "pos": Vector3(294.0, 0.0, 366.0), "mob": "skeleton"},
			{"id": "lm_worgen", "name": "Логово Оборотней", "pos": Vector3(228.0, 0.0, 358.0), "mob": "worgen"},
			{"id": "lm_crypt", "name": "Проклятый Склеп", "pos": Vector3(346.0, 0.0, 312.0), "mob": "ghost"}
		],
		"mobs": ["skeleton", "worgen", "ghost"], "boss": "boss_stitches", "decor": "darkforest"
	},
	{
		"id": "barrens", "name": "Багровые Пустоши", "town": "Перекрёсток Ветров", "min_lv": 22, "max_lv": 32,
		"center": Vector2(445.0, 232.0), "elev": 1.1,
		"ground": Color(0.55, 0.32, 0.17), "accent": Color(0.42, 0.21, 0.11),
		"ambient": Color(0.65, 0.48, 0.36), "sun": Color(1.0, 0.84, 0.62),
		"hub": Vector3(418.0, 0.0, 242.0), "boss_pos": Vector3(514.0, 0.0, 286.0),
		"landmarks": [
			{"id": "lm_canyon", "name": "Каньон Скорпидов", "pos": Vector3(452.0, 0.0, 174.0), "mob": "scorpid"},
			{"id": "lm_orcfort", "name": "Орочий Форт", "pos": Vector3(416.0, 0.0, 316.0), "mob": "orc"},
			{"id": "lm_mound", "name": "Курганы Огров", "pos": Vector3(512.0, 0.0, 224.0), "mob": "ogre"}
		],
		"mobs": ["scorpid", "orc", "ogre"], "boss": "boss_warlord", "decor": "desert"
	},
	{
		"id": "frostpeak", "name": "Замёрзшие Пики", "town": "Кремнеград", "min_lv": 32, "max_lv": 42,
		"center": Vector2(256.0, 96.0), "elev": 2.9,
		"ground": Color(0.64, 0.76, 0.88), "accent": Color(0.46, 0.60, 0.76),
		"ambient": Color(0.56, 0.66, 0.80), "sun": Color(0.86, 0.94, 1.0),
		"hub": Vector3(204.0, 0.0, 108.0), "boss_pos": Vector3(336.0, 0.0, 118.0),
		"landmarks": [
			{"id": "lm_yeti", "name": "Пещера Йети", "pos": Vector3(176.0, 0.0, 56.0), "mob": "yeti"},
			{"id": "lm_troll", "name": "Стойбище Троллей", "pos": Vector3(294.0, 0.0, 62.0), "mob": "frost_troll"},
			{"id": "lm_glacier", "name": "Хрустальный Ледник", "pos": Vector3(262.0, 0.0, 146.0), "mob": "ice_elem"}
		],
		"mobs": ["yeti", "frost_troll", "ice_elem"], "boss": "boss_frostwyrm", "decor": "snow"
	},
	{
		"id": "plaguelands", "name": "Чумные Земли", "town": "Часовня Надежды", "min_lv": 42, "max_lv": 52,
		"center": Vector2(520.0, 102.0), "elev": 1.3,
		"ground": Color(0.25, 0.30, 0.14), "accent": Color(0.18, 0.23, 0.10),
		"ambient": Color(0.42, 0.50, 0.34), "sun": Color(0.76, 0.90, 0.62),
		"hub": Vector3(458.0, 0.0, 92.0), "boss_pos": Vector3(592.0, 0.0, 96.0),
		"landmarks": [
			{"id": "lm_farm", "name": "Заражённая Ферма", "pos": Vector3(488.0, 0.0, 146.0), "mob": "ghoul"},
			{"id": "lm_cult", "name": "Склеп Культа", "pos": Vector3(552.0, 0.0, 64.0), "mob": "necro"},
			{"id": "lm_mire", "name": "Топь Поганищ", "pos": Vector3(568.0, 0.0, 142.0), "mob": "abomination"}
		],
		"mobs": ["ghoul", "necro", "abomination"], "boss": "boss_lich", "decor": "plague"
	},
	{
		"id": "citadel", "name": "Тлеющие Врата", "town": "Бастион Авангарда", "min_lv": 52, "max_lv": 60,
		"center": Vector2(566.0, 366.0), "elev": 1.5,
		"ground": Color(0.21, 0.11, 0.11), "accent": Color(0.36, 0.12, 0.07),
		"ambient": Color(0.52, 0.30, 0.25), "sun": Color(1.0, 0.62, 0.38),
		"hub": Vector3(546.0, 0.0, 344.0), "boss_pos": Vector3(596.0, 0.0, 386.0),
		"landmarks": [
			{"id": "lm_inferno", "name": "Поля Инферно", "pos": Vector3(608.0, 0.0, 336.0), "mob": "imp_elite"},
			{"id": "lm_legion", "name": "Кузня Легиона", "pos": Vector3(532.0, 0.0, 396.0), "mob": "felguard"},
			{"id": "lm_caldera", "name": "Кальдера Колоссов", "pos": Vector3(578.0, 0.0, 404.0), "mob": "lava_golem"}
		],
		"mobs": ["imp_elite", "felguard", "lava_golem"], "boss": "boss_voidlord", "decor": "volcano"
	}
]

# Уникальная нелинейная сеть извилистых трактов (без шаблонных лучей!)
const ROAD_CHAINS: Array = [
	# Главный западный тракт Элвинна (Златоземье -> Волчья чаща -> Бухта Братства -> Дрог)
	[Vector2(68, 238), Vector2(108, 218), Vector2(154, 224), Vector2(132, 290), Vector2(106, 342), Vector2(166, 352)],
	# Северная ветка Элвинна к Шахте и дальше в горы Стальгорна!
	[Vector2(68, 238), Vector2(92, 185), Vector2(114, 152), Vector2(162, 128), Vector2(204, 108)],
	# Перевал Замёрзших Пиков (петля по горам)
	[Vector2(204, 108), Vector2(176, 56), Vector2(236, 48), Vector2(294, 62), Vector2(336, 118), Vector2(262, 146), Vector2(204, 108)],
	# Мост через Чёрную реку (Элвинн -> Сумеречный Лес -> Тёмный Дозор -> Перекрёсток)
	[Vector2(154, 224), Vector2(202, 250), Vector2(246, 272), Vector2(330, 256), Vector2(418, 242)],
	# Петля Сумеречного леса
	[Vector2(246, 272), Vector2(228, 358), Vector2(294, 366), Vector2(334, 384), Vector2(346, 312), Vector2(246, 272)],
	# Каньоны Багровых Пустошей
	[Vector2(418, 242), Vector2(452, 174), Vector2(512, 224), Vector2(514, 286), Vector2(464, 318), Vector2(416, 316), Vector2(418, 242)],
	# Дорога на север в Чумные Земли и кольцо вокруг Кратера Чумы
	[Vector2(452, 174), Vector2(458, 92), Vector2(506, 62), Vector2(552, 64), Vector2(592, 96), Vector2(568, 142), Vector2(488, 146), Vector2(458, 92)],
	# Вулканический мост на остров Тлеющих Врат и кольцо Кальдеры!
	[Vector2(514, 286), Vector2(532, 318), Vector2(546, 344), Vector2(608, 336), Vector2(596, 386), Vector2(578, 404), Vector2(532, 396), Vector2(546, 344)]
]

var DUNGEONS: Array = [
	{
		"id": "deadmines", "name": "Затопленные Штольни", "kind": "Подземелье (3 героя)",
		"min_lv": 6, "party_size": 3, "is_raid": false,
		"floor": Color(0.24, 0.21, 0.18), "wall": Color(0.14, 0.12, 0.11),
		"light": Color(1.0, 0.72, 0.36),
		"mobs": ["kobold", "bandit", "bandit"], "boss": "boss_vancleef",
		"desc": "Заброшенные рудники Корсаров. В глубине ждёт Капитан Красный Парус."
	},
	{
		"id": "scarlet", "name": "Обитель Багряного Завета", "kind": "Подземелье (3 героя)",
		"min_lv": 22, "party_size": 3, "is_raid": false,
		"floor": Color(0.36, 0.22, 0.20), "wall": Color(0.46, 0.40, 0.36),
		"light": Color(1.0, 0.85, 0.55),
		"mobs": ["scarlet_monk", "scarlet_knight", "scarlet_monk"], "boss": "boss_whitemane",
		"desc": "Цитадель фанатиков. Прорвитесь к Инквизитору Кассиану."
	},
	{
		"id": "molten_core", "name": "Разлом Пепла [РЕЙД]", "kind": "Рейд (5 героев)",
		"min_lv": 45, "party_size": 5, "is_raid": true,
		"floor": Color(0.19, 0.09, 0.08), "wall": Color(0.12, 0.07, 0.07),
		"light": Color(1.0, 0.42, 0.12),
		"mobs": ["imp_elite", "lava_golem", "felguard"], "boss": "boss_ragnaros",
		"desc": "Древнее логово огненных великанов. Владыка глубин: Игнисар Повелитель Огня!"
	},
	{
		"id": "icecrown", "name": "Престол Вечной Зимы [РЕЙД]", "kind": "Рейд (5 героев)",
		"min_lv": 55, "party_size": 5, "is_raid": true,
		"floor": Color(0.16, 0.22, 0.30), "wall": Color(0.10, 0.14, 0.22),
		"light": Color(0.45, 0.82, 1.0),
		"mobs": ["ice_elem", "abomination", "necro"], "boss": "boss_arthas",
		"desc": "Финальный рейд. Бросьте вызов Владыке Вечной Зимы!"
	}
]

var CLASSES: Dictionary = {
	"warrior": {
		"name": "Воин", "color": Color(0.86, 0.54, 0.28),
		"res_name": "Ярость", "res_color": Color(0.92, 0.22, 0.18),
		"base_hp": 165.0, "hp_lv": 26.0, "base_res": 100.0, "res_lv": 0.0,
		"base_atk": 17.0, "atk_lv": 4.4, "base_arm": 9.0, "arm_lv": 2.2,
		"range": 3.0, "ranged": false,
		"desc": "Закалённый танк и рубака. Мощные удары, вихрь клинков, рывок и казнь.",
		"skills": [
			{"id": "w1", "unlock_lv": 1, "name": "Удар героя", "key": "1", "cd": 2.0, "cost": 15.0, "range": 3.5, "mult": 1.75, "type": "melee", "desc": "Сокрушительный удар оружием."},
			{"id": "w2", "unlock_lv": 3, "name": "Вихрь стали", "key": "2", "cd": 5.0, "cost": 25.0, "range": 5.2, "mult": 1.50, "type": "aoe_self", "desc": "Круговая атака по всем врагам вокруг."},
			{"id": "w3", "unlock_lv": 6, "name": "Рывок", "key": "3", "cd": 7.0, "cost": 0.0, "range": 12.0, "mult": 1.15, "type": "charge", "stun": 2.0, "desc": "Рывок к цели + оглушение 2с и +25 Ярости."},
			{"id": "w4", "unlock_lv": 10, "name": "Глухая оборона", "key": "4", "cd": 16.0, "cost": 15.0, "range": 0.0, "mult": 0.0, "type": "shield", "dur": 6.0, "desc": "-55% входящего урона на 6с + лечение 20% HP."},
			{"id": "w5", "unlock_lv": 15, "name": "Казнь", "key": "5", "cd": 7.5, "cost": 30.0, "range": 3.8, "mult": 2.8, "type": "execute", "desc": "Огромный урон (до 460% по целям <35% HP)."}
		]
	},
	"mage": {
		"name": "Маг", "color": Color(0.28, 0.72, 1.0),
		"res_name": "Мана", "res_color": Color(0.20, 0.50, 0.98),
		"base_hp": 112.0, "hp_lv": 16.0, "base_res": 140.0, "res_lv": 15.0,
		"base_atk": 20.0, "atk_lv": 5.0, "base_arm": 4.0, "arm_lv": 1.1,
		"range": 11.5, "ranged": true,
		"desc": "Повелитель стихий. Огненные шары, ледяная заморозка, скачок и метеорит.",
		"skills": [
			{"id": "m1", "unlock_lv": 1, "name": "Огненный шар", "key": "1", "cd": 1.6, "cost": 18.0, "range": 13.0, "mult": 1.80, "type": "proj_burn", "desc": "Снаряд огня + горение на 4с."},
			{"id": "m2", "unlock_lv": 3, "name": "Кольцо льда", "key": "2", "cd": 7.5, "cost": 26.0, "range": 6.2, "mult": 1.25, "type": "frost_nova", "stun": 2.4, "desc": "Замораживает врагов вокруг на 2.4с."},
			{"id": "m3", "unlock_lv": 6, "name": "Скачок", "key": "3", "cd": 6.0, "cost": 15.0, "range": 9.0, "mult": 0.0, "type": "blink", "desc": "Мгновенная телепортация вперёд."},
			{"id": "m4", "unlock_lv": 10, "name": "Ледяная преграда", "key": "4", "cd": 15.0, "cost": 25.0, "range": 0.0, "mult": 0.0, "type": "shield", "dur": 7.0, "desc": "Щит (-55% урона на 7с) + восстановление 28% маны."},
			{"id": "m5", "unlock_lv": 15, "name": "Метеорит", "key": "5", "cd": 10.0, "cost": 42.0, "range": 13.0, "mult": 3.4, "type": "aoe_target", "desc": "Обрушивает с неба метеорит по площади!"}
		]
	},
	"paladin": {
		"name": "Паладин", "color": Color(0.96, 0.72, 0.88),
		"res_name": "Мана", "res_color": Color(0.25, 0.58, 0.98),
		"base_hp": 148.0, "hp_lv": 23.0, "base_res": 120.0, "res_lv": 12.0,
		"base_atk": 16.0, "atk_lv": 4.1, "base_arm": 8.0, "arm_lv": 2.0,
		"range": 3.1, "ranged": false,
		"desc": "Рыцарь Света. Латы, освящение земли, оглушающий молот и неуязвимость.",
		"skills": [
			{"id": "p1", "unlock_lv": 1, "name": "Удар Света", "key": "1", "cd": 2.0, "cost": 14.0, "range": 3.6, "mult": 1.65, "type": "melee", "desc": "Святой удар клинком."},
			{"id": "p2", "unlock_lv": 3, "name": "Освящение", "key": "2", "cd": 5.5, "cost": 22.0, "range": 5.8, "mult": 1.60, "type": "aoe_self", "desc": "Освящает землю под ногами, обжигая врагов."},
			{"id": "p3", "unlock_lv": 6, "name": "Молот правосудия", "key": "3", "cd": 8.5, "cost": 18.0, "range": 9.5, "mult": 1.50, "type": "proj_stun", "stun": 2.6, "desc": "Метает молот Света, оглушая врага на 2.6с."},
			{"id": "p4", "unlock_lv": 10, "name": "Свет небес", "key": "4", "cd": 6.5, "cost": 24.0, "range": 0.0, "mult": 0.45, "type": "heal", "desc": "Мгновенно исцеляет 45% здоровья."},
			{"id": "p5", "unlock_lv": 15, "name": "Божественный щит", "key": "5", "cd": 22.0, "cost": 32.0, "range": 0.0, "mult": 0.0, "type": "invuln", "dur": 5.0, "desc": "Полная неуязвимость 5с + святой взрыв!"}
		]
	},
	"ranger": {
		"name": "Охотник", "color": Color(0.38, 0.88, 0.42),
		"res_name": "Энергия", "res_color": Color(0.95, 0.78, 0.20),
		"base_hp": 124.0, "hp_lv": 19.0, "base_res": 100.0, "res_lv": 0.0,
		"base_atk": 18.5, "atk_lv": 4.7, "base_arm": 5.5, "arm_lv": 1.4,
		"range": 12.0, "ranged": true,
		"desc": "Меткий следопыт с верным боевым волком. Град стрел и снайперские залпы.",
		"skills": [
			{"id": "r1", "unlock_lv": 1, "name": "Прицельный выстрел", "key": "1", "cd": 1.7, "cost": 18.0, "range": 13.5, "mult": 1.85, "type": "proj_burn", "desc": "Стрела с кровотечением на 4с."},
			{"id": "r2", "unlock_lv": 3, "name": "Град стрел", "key": "2", "cd": 5.5, "cost": 28.0, "range": 12.5, "mult": 1.65, "type": "aoe_target", "desc": "Ливень стрел по области цели."},
			{"id": "r3", "unlock_lv": 6, "name": "Ледяная стрела", "key": "3", "cd": 8.0, "cost": 20.0, "range": 13.0, "mult": 1.35, "type": "proj_stun", "stun": 2.4, "desc": "Оглушает цель морозом на 2.4с."},
			{"id": "r4", "unlock_lv": 10, "name": "Звериный зов", "key": "4", "cd": 14.0, "cost": 20.0, "range": 0.0, "mult": 0.0, "type": "shield", "dur": 6.5, "desc": "Уклонение (-55% урона) + лечит 20% HP."},
			{"id": "r5", "unlock_lv": 15, "name": "Снайперский залп", "key": "5", "cd": 9.0, "cost": 35.0, "range": 14.0, "mult": 3.2, "type": "execute", "desc": "Смертельный выстрел по раненой цели."}
		]
	},
	"rogue": {
		"name": "Разбойник", "color": Color(0.98, 0.88, 0.28),
		"res_name": "Энергия", "res_color": Color(0.98, 0.82, 0.16),
		"base_hp": 130.0, "hp_lv": 20.0, "base_res": 100.0, "res_lv": 0.0,
		"base_atk": 21.0, "atk_lv": 5.1, "base_arm": 5.0, "arm_lv": 1.3,
		"range": 3.0, "ranged": false,
		"desc": "Мастер кинжалов и ядов. Шаг сквозь тень, веер клинков и смертельный крит.",
		"skills": [
			{"id": "w1", "unlock_lv": 1, "name": "Коварный удар", "key": "1", "cd": 1.4, "cost": 16.0, "range": 3.4, "mult": 1.70, "type": "melee", "desc": "Быстрый удар отравленным клинком."},
			{"id": "w2", "unlock_lv": 3, "name": "Веер клинков", "key": "2", "cd": 4.8, "cost": 26.0, "range": 5.0, "mult": 1.55, "type": "aoe_self", "desc": "Метает кинжалы во всех врагов вокруг."},
			{"id": "m3", "unlock_lv": 6, "name": "Шаг сквозь тень", "key": "3", "cd": 6.5, "cost": 12.0, "range": 11.5, "mult": 1.35, "type": "charge", "stun": 1.6, "desc": "Рывок за спину цели со станом на 1.6с."},
			{"id": "w4", "unlock_lv": 10, "name": "Ускользание", "key": "4", "cd": 14.0, "cost": 15.0, "range": 0.0, "mult": 0.0, "type": "shield", "dur": 6.0, "desc": "Уклонение: -55% урона на 6с + 20% HP."},
			{"id": "w5", "unlock_lv": 15, "name": "Потрошение", "key": "5", "cd": 7.0, "cost": 35.0, "range": 3.6, "mult": 3.1, "type": "execute", "desc": "Сокрушительный финишер (460% при <35% HP)."}
		]
	},
	"priest": {
		"name": "Жрец", "color": Color(0.95, 0.95, 0.98),
		"res_name": "Мана", "res_color": Color(0.24, 0.56, 0.98),
		"base_hp": 118.0, "hp_lv": 18.0, "base_res": 145.0, "res_lv": 15.0,
		"base_atk": 18.5, "atk_lv": 4.7, "base_arm": 4.5, "arm_lv": 1.2,
		"range": 11.5, "ranged": true,
		"desc": "Хранитель Света и Тьмы. Карает проклятиями, исцеляет и ставит барьер души.",
		"skills": [
			{"id": "p1", "unlock_lv": 1, "name": "Кара небес", "key": "1", "cd": 1.7, "cost": 16.0, "range": 12.5, "mult": 1.75, "type": "proj_burn", "desc": "Святой разряд + горение Тьмы на 4с."},
			{"id": "p4", "unlock_lv": 3, "name": "Молитва исцеления", "key": "2", "cd": 5.5, "cost": 22.0, "range": 0.0, "mult": 0.45, "type": "heal", "desc": "Восстанавливает 45% здоровья."},
			{"id": "m2", "unlock_lv": 6, "name": "Ментальный крик", "key": "3", "cd": 8.0, "cost": 24.0, "range": 6.0, "mult": 1.20, "type": "frost_nova", "stun": 2.5, "desc": "Ужас: оглушает врагов вокруг на 2.5с."},
			{"id": "m4", "unlock_lv": 10, "name": "Слово силы: Щит", "key": "4", "cd": 14.0, "cost": 25.0, "range": 0.0, "mult": 0.0, "type": "shield", "dur": 7.0, "desc": "Щит души (-55% урона) + 28% маны."},
			{"id": "p5", "unlock_lv": 15, "name": "Взрыв разума", "key": "5", "cd": 9.5, "cost": 38.0, "range": 12.5, "mult": 3.3, "type": "aoe_target", "desc": "Мощный пси-взрыв по области цели!"}
		]
	},
	"warlock": {
		"name": "Чернокнижник", "color": Color(0.68, 0.36, 0.96),
		"res_name": "Мана", "res_color": Color(0.55, 0.25, 0.96),
		"base_hp": 126.0, "hp_lv": 19.0, "base_res": 135.0, "res_lv": 14.0,
		"base_atk": 19.5, "atk_lv": 4.9, "base_arm": 4.5, "arm_lv": 1.2,
		"range": 11.5, "ranged": true,
		"desc": "Повелитель демонов и Скверны. Сопровождается Бесом, жжёт порчей и хаосом.",
		"skills": [
			{"id": "m1", "unlock_lv": 1, "name": "Стрела Тьмы", "key": "1", "cd": 1.7, "cost": 18.0, "range": 13.0, "mult": 1.85, "type": "proj_burn", "desc": "Тёмная стрела + проклятие Порчи."},
			{"id": "w2", "unlock_lv": 3, "name": "Адское пламя", "key": "2", "cd": 5.5, "cost": 26.0, "range": 5.8, "mult": 1.65, "type": "aoe_self", "desc": "Огненное кольцо Скверны вокруг себя."},
			{"id": "p3", "unlock_lv": 6, "name": "Лик смерти", "key": "3", "cd": 8.5, "cost": 22.0, "range": 10.5, "mult": 1.50, "type": "proj_stun", "stun": 2.4, "desc": "Ужас: оглушает врага на 2.4с."},
			{"id": "w4", "unlock_lv": 10, "name": "Броня демона", "key": "4", "cd": 15.0, "cost": 24.0, "range": 0.0, "mult": 0.0, "type": "shield", "dur": 7.0, "desc": "Поглощает 55% урона и лечит 20% HP."},
			{"id": "m5", "unlock_lv": 15, "name": "Ливень хаоса", "key": "5", "cd": 10.5, "cost": 42.0, "range": 13.0, "mult": 3.5, "type": "aoe_target", "desc": "Призывает адский метеорит по площади!"}
		]
	},
	"shaman": {
		"name": "Шаман", "color": Color(0.18, 0.56, 0.92),
		"res_name": "Мана", "res_color": Color(0.20, 0.52, 0.96),
		"base_hp": 138.0, "hp_lv": 21.0, "base_res": 130.0, "res_lv": 13.0,
		"base_atk": 18.0, "atk_lv": 4.6, "base_arm": 6.5, "arm_lv": 1.7,
		"range": 10.5, "ranged": true,
		"desc": "Дух стихий. Грозовые молнии, тотем исцеления, ледяной шок и цепная буря.",
		"skills": [
			{"id": "m3", "unlock_lv": 1, "name": "Молния", "key": "1", "cd": 1.6, "cost": 16.0, "range": 12.0, "mult": 1.75, "type": "proj_burn", "desc": "Разряд молнии с электрическим шоком."},
			{"id": "p4", "unlock_lv": 3, "name": "Тотем исцеления", "key": "2", "cd": 6.5, "cost": 22.0, "range": 0.0, "mult": 0.42, "type": "heal", "desc": "Сила земли восстанавливает 42% HP."},
			{"id": "r3", "unlock_lv": 6, "name": "Ледяной шок", "key": "3", "cd": 8.0, "cost": 20.0, "range": 10.5, "mult": 1.45, "type": "proj_stun", "stun": 2.4, "desc": "Замораживает врага на 2.4с."},
			{"id": "p2", "unlock_lv": 10, "name": "Вскипание лавы", "key": "4", "cd": 5.5, "cost": 25.0, "range": 5.8, "mult": 1.65, "type": "aoe_self", "desc": "Взрыв магмы вокруг шамана."},
			{"id": "m5", "unlock_lv": 15, "name": "Цепная буря", "key": "5", "cd": 9.5, "cost": 38.0, "range": 12.0, "mult": 3.25, "type": "aoe_target", "desc": "Шторм молний бьёт по всей группе врагов!"}
		]
	}
}

var TALENTS: Array = [
	{"id": "might", "name": "Мощь титана", "max": 5, "desc": "+8% ко всему урону за ранг"},
	{"id": "vitality", "name": "Кровь предков", "max": 5, "desc": "+10% к макс. здоровью за ранг"},
	{"id": "precision", "name": "Точность мастера", "max": 5, "desc": "+4% к шансу крита за ранг"},
	{"id": "haste", "name": "Стремительность", "max": 5, "desc": "-6% перезарядки умений за ранг"},
	{"id": "vamp", "name": "Жажда битвы", "max": 5, "desc": "+3% вампиризма от урона за ранг"},
	{"id": "greed", "name": "Дар искателя", "max": 5, "desc": "+15% опыта и золота за ранг"}
]

var RARITIES: Array = [
	{"name": "Обычный", "color": Color(0.88, 0.88, 0.88), "hex": "#e0e0e0", "mult": 1.0},
	{"name": "Необычный", "color": Color(0.24, 0.94, 0.34), "hex": "#3df057", "mult": 1.32},
	{"name": "Редкий", "color": Color(0.28, 0.62, 1.0), "hex": "#479eff", "mult": 1.72},
	{"name": "Эпический", "color": Color(0.78, 0.34, 1.0), "hex": "#c757ff", "mult": 2.25},
	{"name": "Легендарный", "color": Color(1.0, 0.58, 0.12), "hex": "#ff941f", "mult": 3.0}
]

var SLOTS: Array = ["weapon", "armor", "helm", "shoulders", "amulet", "ring"]
var SLOT_NAMES: Dictionary = {
	"weapon": "Оружие", "armor": "Доспех", "helm": "Шлем",
	"shoulders": "Наплечники", "amulet": "Амулет", "ring": "Кольцо"
}

var MOBS: Dictionary = {
	"wolf": {"name": "Лесной волк", "lv": 2, "hp": 72.0, "atk": 7.0, "xp": 18, "gold": 4, "speed": 4.2, "col": Color(0.55, 0.52, 0.48), "shape": "beast", "boss": false, "ranged": false},
	"kobold": {"name": "Кобольд-рудокоп", "lv": 5, "hp": 125.0, "atk": 11.0, "xp": 28, "gold": 7, "speed": 3.8, "col": Color(0.78, 0.55, 0.30), "shape": "kobold", "boss": false, "ranged": false},
	"bandit": {"name": "Корсар Чёрного Флага", "lv": 8, "hp": 190.0, "atk": 16.0, "xp": 42, "gold": 12, "speed": 4.2, "col": Color(0.75, 0.22, 0.20), "shape": "humanoid", "boss": false, "ranged": false},
	"boss_drog": {"name": "Громила Дрог [БОСС]", "lv": 11, "hp": 1050.0, "atk": 30.0, "xp": 260, "gold": 110, "speed": 4.0, "col": Color(0.88, 0.22, 0.14), "shape": "boss", "boss": true, "ranged": false},

	"skeleton": {"name": "Скелет-воин", "lv": 13, "hp": 280.0, "atk": 24.0, "xp": 64, "gold": 18, "speed": 3.9, "col": Color(0.84, 0.86, 0.80), "shape": "undead", "boss": false, "ranged": false},
	"worgen": {"name": "Ночной оборотень", "lv": 16, "hp": 390.0, "atk": 32.0, "xp": 90, "gold": 25, "speed": 4.7, "col": Color(0.32, 0.34, 0.44), "shape": "beast", "boss": false, "ranged": false},
	"ghost": {"name": "Мрачный дух", "lv": 19, "hp": 470.0, "atk": 40.0, "xp": 120, "gold": 34, "speed": 4.3, "col": Color(0.45, 0.88, 0.94), "shape": "elemental", "boss": false, "ranged": true},
	"boss_stitches": {"name": "Костяной Мясник [БОСС]", "lv": 21, "hp": 2500.0, "atk": 58.0, "xp": 620, "gold": 280, "speed": 3.8, "col": Color(0.45, 0.76, 0.34), "shape": "boss", "boss": true, "ranged": false},

	"scorpid": {"name": "Пустынный скорпид", "lv": 23, "hp": 620.0, "atk": 48.0, "xp": 155, "gold": 44, "speed": 4.3, "col": Color(0.84, 0.42, 0.16), "shape": "scorpid", "boss": false, "ranged": false},
	"orc": {"name": "Орк-налётчик", "lv": 26, "hp": 810.0, "atk": 58.0, "xp": 205, "gold": 58, "speed": 4.4, "col": Color(0.32, 0.60, 0.24), "shape": "humanoid", "boss": false, "ranged": false},
	"ogre": {"name": "Огр-крушитель", "lv": 29, "hp": 1100.0, "atk": 70.0, "xp": 270, "gold": 76, "speed": 3.7, "col": Color(0.68, 0.50, 0.36), "shape": "humanoid", "boss": false, "ranged": false},
	"boss_warlord": {"name": "Вождь Каргаш [БОСС]", "lv": 31, "hp": 4800.0, "atk": 98.0, "xp": 1200, "gold": 540, "speed": 4.3, "col": Color(0.78, 0.16, 0.12), "shape": "boss", "boss": true, "ranged": false},

	"yeti": {"name": "Снежный йети", "lv": 33, "hp": 1350.0, "atk": 82.0, "xp": 340, "gold": 96, "speed": 4.1, "col": Color(0.86, 0.92, 0.98), "shape": "beast", "boss": false, "ranged": false},
	"frost_troll": {"name": "Ледяной тролль", "lv": 36, "hp": 1680.0, "atk": 98.0, "xp": 420, "gold": 120, "speed": 4.4, "col": Color(0.34, 0.66, 0.80), "shape": "humanoid", "boss": false, "ranged": true},
	"ice_elem": {"name": "Элементаль бури", "lv": 39, "hp": 2050.0, "atk": 115.0, "xp": 510, "gold": 148, "speed": 4.2, "col": Color(0.45, 0.86, 1.0), "shape": "elemental", "boss": false, "ranged": true},
	"boss_frostwyrm": {"name": "Ледяной Змей Морвей [БОСС]", "lv": 41, "hp": 8400.0, "atk": 152.0, "xp": 2200, "gold": 980, "speed": 4.5, "col": Color(0.36, 0.84, 1.0), "shape": "dragon", "boss": true, "ranged": true},

	"ghoul": {"name": "Чумной вурдалак", "lv": 43, "hp": 2480.0, "atk": 134.0, "xp": 620, "gold": 180, "speed": 4.8, "col": Color(0.42, 0.58, 0.28), "shape": "undead", "boss": false, "ranged": false},
	"necro": {"name": "Некромант Культа", "lv": 46, "hp": 2900.0, "atk": 158.0, "xp": 760, "gold": 220, "speed": 4.1, "col": Color(0.56, 0.24, 0.78), "shape": "humanoid", "boss": false, "ranged": true},
	"abomination": {"name": "Мясное поганище", "lv": 49, "hp": 3850.0, "atk": 180.0, "xp": 940, "gold": 270, "speed": 3.7, "col": Color(0.52, 0.68, 0.34), "shape": "undead", "boss": false, "ranged": false},
	"boss_lich": {"name": "Архилич Мортис [БОСС]", "lv": 51, "hp": 14200.0, "atk": 230.0, "xp": 3800, "gold": 1650, "speed": 4.3, "col": Color(0.70, 0.32, 1.0), "shape": "boss", "boss": true, "ranged": true},

	"imp_elite": {"name": "Бес Инферно", "lv": 53, "hp": 4300.0, "atk": 210.0, "xp": 1150, "gold": 330, "speed": 4.6, "col": Color(0.96, 0.36, 0.14), "shape": "elemental", "boss": false, "ranged": true},
	"felguard": {"name": "Страж Бездны", "lv": 56, "hp": 5450.0, "atk": 250.0, "xp": 1450, "gold": 410, "speed": 4.5, "col": Color(0.74, 0.14, 0.22), "shape": "humanoid", "boss": false, "ranged": false},
	"lava_golem": {"name": "Лавовый колосс", "lv": 59, "hp": 6900.0, "atk": 290.0, "xp": 1800, "gold": 510, "speed": 3.8, "col": Color(1.0, 0.48, 0.12), "shape": "elemental", "boss": false, "ranged": false},
	"boss_voidlord": {"name": "Повелитель Бездны [БОСС]", "lv": 60, "hp": 22500.0, "atk": 330.0, "xp": 6500, "gold": 3000, "speed": 4.3, "col": Color(0.88, 0.20, 0.44), "shape": "boss", "boss": true, "ranged": true},

	"boss_vancleef": {"name": "Капитан Красный Парус [ДАНЖ]", "lv": 11, "hp": 1950.0, "atk": 34.0, "xp": 820, "gold": 340, "speed": 4.4, "col": Color(0.86, 0.18, 0.18), "shape": "boss", "boss": true, "ranged": false},
	"scarlet_monk": {"name": "Багряный монах", "lv": 24, "hp": 760.0, "atk": 50.0, "xp": 190, "gold": 60, "speed": 4.5, "col": Color(0.86, 0.22, 0.20), "shape": "humanoid", "boss": false, "ranged": false},
	"scarlet_knight": {"name": "Багряный паладин", "lv": 26, "hp": 990.0, "atk": 60.0, "xp": 250, "gold": 78, "speed": 4.1, "col": Color(0.92, 0.28, 0.22), "shape": "humanoid", "boss": false, "ranged": false},
	"boss_whitemane": {"name": "Инквизитор Кассиан [ДАНЖ]", "lv": 28, "hp": 5200.0, "atk": 88.0, "xp": 1850, "gold": 840, "speed": 4.2, "col": Color(0.98, 0.24, 0.30), "shape": "boss", "boss": true, "ranged": true},
	"boss_ragnaros": {"name": "ИГНИСАР ПОВЕЛИТЕЛЬ ОГНЯ [РЕЙД]", "lv": 52, "hp": 27000.0, "atk": 295.0, "xp": 8500, "gold": 4000, "speed": 3.5, "col": Color(1.0, 0.36, 0.06), "shape": "ragnaros", "boss": true, "ranged": true},
	"boss_arthas": {"name": "ВЛАДЫКА ВЕЧНОЙ ЗИМЫ [РЕЙД]", "lv": 60, "hp": 40000.0, "atk": 385.0, "xp": 14000, "gold": 7200, "speed": 4.4, "col": Color(0.32, 0.78, 1.0), "shape": "lichking", "boss": true, "ranged": true}
}

var QUESTS: Array = [
	{"id": "q1", "zone": "elwynn", "npc_id": "elwynn_cmd", "min_lv": 1, "req": "", "type": "kill", "title": "Волчья стая у тракта", "desc": "Стая волков перерезала дорогу в Яснодол. Охоться в Волчьей Чаще и убей 6 Лесных волков.", "target": "wolf", "need": 6, "xp": 160, "gold": 35, "reward_rarity": 1, "reward_lv": 2},
	{"id": "q1b", "zone": "elwynn", "npc_id": "elwynn_cmd", "min_lv": 2, "req": "q1", "type": "collect", "title": "Целебные травы Рассвета", "desc": "Собери 4 куста Светлоцвета на лугах [E] для лазарета Яснодола.", "target": "node_elwynn", "need": 4, "xp": 240, "gold": 55, "reward_rarity": 1, "reward_lv": 3},
	{"id": "q2_exp", "zone": "elwynn", "npc_id": "elwynn_cmd", "min_lv": 3, "req": "q1", "type": "explore", "title": "Разведка Копей", "desc": "Кобольды заняли рудник на севере. Доберись до Копей Тёмного Ручья и отыщи бригадира!", "target": "lm_mine", "need": 1, "xp": 290, "gold": 70, "reward_rarity": 1, "reward_lv": 4},
	{"id": "q2", "zone": "elwynn", "npc_id": "elwynn_f1", "min_lv": 4, "req": "", "type": "kill", "title": "Свечи во тьме", "desc": "Очисти подходы к Копям Тёмного Ручья: убей 7 Кобольдов-рудокопов.", "target": "kobold", "need": 7, "xp": 460, "gold": 95, "reward_rarity": 2, "reward_lv": 5},
	{"id": "q2_ore", "zone": "elwynn", "npc_id": "elwynn_f1", "min_lv": 5, "req": "q2", "type": "collect", "title": "Кристаллы для горна", "desc": "Собери 4 Светлоцвета у северных скал [E], чтобы поддержать дозор рудника.", "target": "node_elwynn", "need": 4, "xp": 540, "gold": 115, "reward_rarity": 2, "reward_lv": 6},
	{"id": "q3", "zone": "elwynn", "npc_id": "elwynn_f2", "min_lv": 6, "req": "", "type": "kill", "title": "Бухта Корсаров", "desc": "Корсары разбили лагерь в Бухте на юге. Победи 7 корсаров!", "target": "bandit", "need": 7, "xp": 740, "gold": 140, "reward_rarity": 2, "reward_lv": 8},
	{"id": "q4", "zone": "elwynn", "npc_id": "elwynn_f2", "min_lv": 9, "req": "q3", "type": "kill", "title": "Твердыня Громилы Дрога", "desc": "Уничтожь главаря корсаров — Громилу Дрога на южном утёсе!", "target": "boss_drog", "need": 1, "xp": 1350, "gold": 320, "reward_rarity": 2, "reward_lv": 11},
	{"id": "qd1", "zone": "elwynn", "npc_id": "elwynn_cmd", "min_lv": 6, "req": "", "type": "kill", "title": "[ДАНЖ] Тайна Затопленных Штолен", "desc": "Отправляйся в 'Затопленные Штольни' и сокруши Капитана Красного Паруса!", "target": "boss_vancleef", "need": 1, "xp": 1900, "gold": 520, "reward_rarity": 3, "reward_lv": 12},

	{"id": "q5_exp", "zone": "duskwood", "npc_id": "duskwood_cmd", "min_lv": 11, "req": "", "type": "explore", "title": "Тени Вороньего Кладбища", "desc": "Разведай Воронье Кладбище на юге Сумеречного Леса.", "target": "lm_grave", "need": 1, "xp": 950, "gold": 180, "reward_rarity": 1, "reward_lv": 13},
	{"id": "q5", "zone": "duskwood", "npc_id": "duskwood_f1", "min_lv": 12, "req": "", "type": "kill", "title": "Пробуждение мёртвых", "desc": "Уничтожь 8 Скелетов-воинов на Кладбище.", "target": "skeleton", "need": 8, "xp": 1450, "gold": 250, "reward_rarity": 2, "reward_lv": 14},
	{"id": "q5b", "zone": "duskwood", "npc_id": "duskwood_f1", "min_lv": 13, "req": "q5", "type": "collect", "title": "Проклятые реликвии", "desc": "Собери 5 Древних черепов среди могил [E].", "target": "node_duskwood", "need": 5, "xp": 1750, "gold": 310, "reward_rarity": 2, "reward_lv": 15},
	{"id": "q6", "zone": "duskwood", "npc_id": "duskwood_f2", "min_lv": 15, "req": "", "type": "kill", "title": "Вой полнолуния", "desc": "Одолей 8 Ночных оборотней в их логове.", "target": "worgen", "need": 8, "xp": 2250, "gold": 370, "reward_rarity": 2, "reward_lv": 17},
	{"id": "q7", "zone": "duskwood", "npc_id": "duskwood_cmd", "min_lv": 17, "req": "", "type": "kill", "title": "Шёпот Склепа", "desc": "Упокой 8 Мрачных духов у Проклятого Склепа.", "target": "ghost", "need": 8, "xp": 2950, "gold": 490, "reward_rarity": 2, "reward_lv": 19},
	{"id": "q8", "zone": "duskwood", "npc_id": "duskwood_f1", "min_lv": 19, "req": "q5b", "type": "kill", "title": "Кошмар Темнолесья", "desc": "Чудовище Костяной Мясник бродит в южной топи. Победи босса!", "target": "boss_stitches", "need": 1, "xp": 4600, "gold": 860, "reward_rarity": 3, "reward_lv": 21},

	{"id": "q9", "zone": "barrens", "npc_id": "barrens_f1", "min_lv": 21, "req": "", "type": "kill", "title": "Ядовитый каньон", "desc": "Очисти Каньон от 8 Пустынных скорпидов.", "target": "scorpid", "need": 8, "xp": 3800, "gold": 620, "reward_rarity": 2, "reward_lv": 23},
	{"id": "q9b", "zone": "barrens", "npc_id": "barrens_f1", "min_lv": 23, "req": "q9", "type": "collect", "title": "Кровавые кристаллы Пустошей", "desc": "Добудь 5 Багровых кристаллов в каньонах [E].", "target": "node_barrens", "need": 5, "xp": 4600, "gold": 780, "reward_rarity": 2, "reward_lv": 25},
	{"id": "q10", "zone": "barrens", "npc_id": "barrens_cmd", "min_lv": 24, "req": "", "type": "kill", "title": "Штурм Орочьего Форта", "desc": "Разбей 9 Орков-налётчиков в Орочьем Форте.", "target": "orc", "need": 9, "xp": 5400, "gold": 880, "reward_rarity": 2, "reward_lv": 27},
	{"id": "q11", "zone": "barrens", "npc_id": "barrens_f2", "min_lv": 27, "req": "", "type": "kill", "title": "Курганы великанов", "desc": "Одолей 8 Огров-крушителей у Курганов.", "target": "ogre", "need": 8, "xp": 7200, "gold": 1150, "reward_rarity": 2, "reward_lv": 29},
	{"id": "q12", "zone": "barrens", "npc_id": "barrens_f2", "min_lv": 29, "req": "q11", "type": "kill", "title": "Падение Вождя", "desc": "Брось вызов Вождю Каргашу!", "target": "boss_warlord", "need": 1, "xp": 10800, "gold": 1950, "reward_rarity": 3, "reward_lv": 31},
	{"id": "qd2", "zone": "barrens", "npc_id": "barrens_cmd", "min_lv": 22, "req": "", "type": "kill", "title": "[ДАНЖ] Очищение Обители", "desc": "Пройди 'Обитель Багряного Завета' и победи Инквизитора Кассиана.", "target": "boss_whitemane", "need": 1, "xp": 8900, "gold": 2100, "reward_rarity": 3, "reward_lv": 29},

	{"id": "q13", "zone": "frostpeak", "npc_id": "frostpeak_cmd", "min_lv": 31, "req": "", "type": "kill", "title": "Мех для гарнизона", "desc": "Убей 8 Снежных йети у Пещеры Йети.", "target": "yeti", "need": 8, "xp": 9200, "gold": 1400, "reward_rarity": 2, "reward_lv": 33},
	{"id": "q13b", "zone": "frostpeak", "npc_id": "frostpeak_cmd", "min_lv": 33, "req": "q13", "type": "collect", "title": "Ледяные осколки рун", "desc": "Собери 5 Ледяных рун на ледниках [E].", "target": "node_frostpeak", "need": 5, "xp": 11200, "gold": 1650, "reward_rarity": 2, "reward_lv": 35},
	{"id": "q14", "zone": "frostpeak", "npc_id": "frostpeak_f1", "min_lv": 35, "req": "", "type": "kill", "title": "Копья Севера", "desc": "Убей 9 Ледяных троллей в Стойбище Троллей.", "target": "frost_troll", "need": 9, "xp": 12400, "gold": 1850, "reward_rarity": 2, "reward_lv": 37},
	{"id": "q15", "zone": "frostpeak", "npc_id": "frostpeak_f2", "min_lv": 37, "req": "", "type": "kill", "title": "Сердце метели", "desc": "Рассей 8 Элементалей бури на Хрустальном Леднике.", "target": "ice_elem", "need": 8, "xp": 15600, "gold": 2250, "reward_rarity": 3, "reward_lv": 39},
	{"id": "q16", "zone": "frostpeak", "npc_id": "frostpeak_f2", "min_lv": 39, "req": "q15", "type": "kill", "title": "Дыхание Зимы", "desc": "Сразись с древним Ледяным Змеем Морвеем!", "target": "boss_frostwyrm", "need": 1, "xp": 22500, "gold": 3700, "reward_rarity": 3, "reward_lv": 41},

	{"id": "q17", "zone": "plaguelands", "npc_id": "plaguelands_f1", "min_lv": 41, "req": "", "type": "kill", "title": "Заражённая ферма", "desc": "Зачисти 9 Чумных вурдалаков на Заражённой Ферме.", "target": "ghoul", "need": 9, "xp": 19500, "gold": 2800, "reward_rarity": 2, "reward_lv": 43},
	{"id": "q17b", "zone": "plaguelands", "npc_id": "plaguelands_f1", "min_lv": 43, "req": "q17", "type": "collect", "title": "Грибы чумы", "desc": "Собери 5 Чумных грибов для алхимиков Часовни [E].", "target": "node_plaguelands", "need": 5, "xp": 23500, "gold": 3400, "reward_rarity": 3, "reward_lv": 45},
	{"id": "q18", "zone": "plaguelands", "npc_id": "plaguelands_cmd", "min_lv": 44, "req": "", "type": "kill", "title": "Тёмный ритуал", "desc": "Уничтожь 8 Некромантов Культа в Склепе Культа.", "target": "necro", "need": 8, "xp": 25000, "gold": 3600, "reward_rarity": 3, "reward_lv": 47},
	{"id": "q19", "zone": "plaguelands", "npc_id": "plaguelands_f2", "min_lv": 47, "req": "", "type": "kill", "title": "Монстры склепа", "desc": "Одолей 8 Мясных поганищ в Топи Поганищ.", "target": "abomination", "need": 8, "xp": 31000, "gold": 4400, "reward_rarity": 3, "reward_lv": 49},
	{"id": "q20", "zone": "plaguelands", "npc_id": "plaguelands_f2", "min_lv": 49, "req": "q19", "type": "kill", "title": "Филактерия Архилича", "desc": "Уничтожь Архилича Мортиса!", "target": "boss_lich", "need": 1, "xp": 44000, "gold": 7000, "reward_rarity": 3, "reward_lv": 51},
	{"id": "qr1", "zone": "plaguelands", "npc_id": "plaguelands_cmd", "min_lv": 45, "req": "", "type": "kill", "title": "[РЕЙД] Сердце Разлома Пепла", "desc": "Собери отряд в 'Разлом Пепла' и срази Игнисара!", "target": "boss_ragnaros", "need": 1, "xp": 54000, "gold": 12000, "reward_rarity": 4, "reward_lv": 55},

	{"id": "q21", "zone": "citadel", "npc_id": "citadel_f1", "min_lv": 51, "req": "", "type": "kill", "title": "Искра Инферно", "desc": "Убей 9 Бесов Инферно на Полях Инферно.", "target": "imp_elite", "need": 9, "xp": 38000, "gold": 5400, "reward_rarity": 3, "reward_lv": 53},
	{"id": "q21b", "zone": "citadel", "npc_id": "citadel_f1", "min_lv": 53, "req": "q21", "type": "collect", "title": "Слитки демонической стали", "desc": "Добудь 5 Залежей Скверны у Кузни Легиона [E].", "target": "node_citadel", "need": 5, "xp": 44000, "gold": 6200, "reward_rarity": 3, "reward_lv": 55},
	{"id": "q22", "zone": "citadel", "npc_id": "citadel_f2", "min_lv": 54, "req": "", "type": "kill", "title": "Железный Легион", "desc": "Уничтожь 9 Стражей Бездны у Кузни Легиона.", "target": "felguard", "need": 9, "xp": 48000, "gold": 6700, "reward_rarity": 3, "reward_lv": 56},
	{"id": "q23", "zone": "citadel", "npc_id": "citadel_f2", "min_lv": 57, "req": "q22", "type": "kill", "title": "Ядро вулкана", "desc": "Разбей 8 Лавовых колоссов в Кальдере.", "target": "lava_golem", "need": 8, "xp": 60000, "gold": 8600, "reward_rarity": 3, "reward_lv": 59},
	{"id": "q24", "zone": "citadel", "npc_id": "citadel_cmd", "min_lv": 59, "req": "", "type": "kill", "title": "Владыка Бездны", "desc": "Одолей Повелителя Бездны у Тлеющих Врат!", "target": "boss_voidlord", "need": 1, "xp": 82000, "gold": 15000, "reward_rarity": 4, "reward_lv": 60},
	{"id": "qr2", "zone": "citadel", "npc_id": "citadel_cmd", "min_lv": 55, "req": "", "type": "kill", "title": "[РЕЙД] Падение Владыки Зимы", "desc": "Штурмуй 'Престол Вечной Зимы' и победи Владыку Вечной Зимы!", "target": "boss_arthas", "need": 1, "xp": 120000, "gold": 28000, "reward_rarity": 4, "reward_lv": 60}
]

const PREFIXES: Array = ["Закалённый", "Древний", "Рунный", "Кровавый", "Небесный", "Теневой", "Грозовой", "Титанский"]
const SUFFIXES: Array = ["Ярости", "Архимага", "Защитника", "Бездны", "Феникса", "Королей", "Вечности", "Шторма"]
const SLOT_BASES: Dictionary = {
	"weapon": ["Клинок", "Посох", "Молот", "Секира", "Лук", "Кинжал"],
	"armor": ["Кираса", "Мантия", "Латы", "Кольчуга"],
	"helm": ["Шлем", "Корона", "Капюшон", "Венец"],
	"shoulders": ["Наплечники", "Нарамники", "Оплечье", "Крылья"],
	"amulet": ["Амулет", "Талисман", "Медальон"],
	"ring": ["Кольцо", "Перстень", "Печатка"]
}

func xp_for_level(lv: int) -> int:
	return int(round(240.0 * pow(float(lv), 1.82)))

func get_zone_by_id(zid: String) -> Dictionary:
	for z in ZONES:
		if str(z["id"]) == zid:
			return z
	return ZONES[0]

# Органическое разделение континента на зоны (не квадратная сетка!)
func get_zone_at(pos: Vector3) -> Dictionary:
	return get_zone_blended(pos.x, pos.z)

func get_zone_blended(x: float, z: float) -> Dictionary:
	var wx: float = x + sin(z * 0.032) * 14.0 + cos(x * 0.04) * 7.0
	var wz: float = z + cos(x * 0.030) * 14.0 + sin(z * 0.04) * 7.0
	var best_z: Dictionary = ZONES[0]
	var best_d: float = 999999.0
	for zn in ZONES:
		var c: Vector2 = zn["center"]
		var d: float = Vector2(wx - c.x, wz - c.y).length()
		# Слегка вытягиваем/сжимаем разные локации для неповторимых очертаний
		if str(zn["id"]) == "barrens":
			d *= 0.88
		elif str(zn["id"]) == "citadel":
			d *= 1.18
		elif str(zn["id"]) == "frostpeak":
			d *= 0.94
		if d < best_d:
			best_d = d
			best_z = zn
	return best_z

func _seg_dist(px: float, pz: float, ax: float, az: float, bx: float, bz: float) -> float:
	var vx: float = bx - ax
	var vz: float = bz - az
	var wx: float = px - ax
	var wz: float = pz - az
	var c1: float = wx * vx + wz * vz
	if c1 <= 0.0:
		return sqrt(wx * wx + wz * wz)
	var c2: float = vx * vx + vz * vz
	if c2 <= c1:
		var dx: float = px - bx
		var dz: float = pz - bz
		return sqrt(dx * dx + dz * dz)
	var b: float = c1 / c2
	var projx: float = ax + b * vx
	var projz: float = az + b * vz
	return sqrt((px - projx) * (px - projx) + (pz - projz) * (pz - projz))

func get_road_dist(x: float, z: float) -> float:
	var wx: float = x + sin(z * 0.042) * 4.5
	var wz: float = z + cos(x * 0.042) * 4.5
	var best: float = 9999.0
	for chain in ROAD_CHAINS:
		for i in range(chain.size() - 1):
			var a: Vector2 = chain[i]
			var b: Vector2 = chain[i + 1]
			best = minf(best, _seg_dist(wx, wz, a.x, a.y, b.x, b.y))
	return best

func is_land(x: float, z: float) -> bool:
	return get_coast_signed_dist(x, z) > 0.0

# Положительное значение = суша, отрицательное = океан/заливы!
func get_coast_signed_dist(x: float, z: float) -> float:
	# Основной материк (неравномерная клякса с фьордами и бухтами)
	var dx: float = (x - 325.0) / 285.0
	var dz: float = (z - 215.0) / 188.0
	var warp: float = sin(x * 0.022 + z * 0.015) * 0.14 + cos(z * 0.028 - x * 0.012) * 0.11
	var main_d: float = 1.0 - sqrt(dx * dx + dz * dz) + warp

	# Западный полуостров Элвинна (вокруг Златоземья и Бухты)
	var ex: float = (x - 118.0) / 96.0
	var ez: float = (z - 260.0) / 138.0
	var elw_d: float = 1.0 - sqrt(ex * ex + ez * ez) + warp * 0.7

	# Северные Замёрзшие Пики
	var fx: float = (x - 256.0) / 132.0
	var fz: float = (z - 96.0) / 76.0
	var frs_d: float = 1.0 - sqrt(fx * fx + fz * fz) + warp * 0.5

	# Вулканический остров Тлеющих Врат на юго-востоке
	var cx: float = (x - 570.0) / 74.0
	var cz: float = (z - 368.0) / 62.0
	var cit_d: float = 1.0 - sqrt(cx * cx + cz * cz) + sin(x * 0.05) * 0.08

	# Пролив между материком и вулканическим островом
	var strait: float = 0.0
	if x > 475.0 and z > 295.0:
		var sd: float = absf((x - 510.0) + (z - 325.0) * 0.7)
		if sd < 18.0 and cit_d < 0.32:
			strait = -0.35

	return maxf(maxf(main_d, elw_d), maxf(frs_d, cit_d)) + strait

func get_river_dist(x: float, z: float) -> float:
	# Чёрная река между Элвинном и Сумеречным лесом
	var rx1: float = 196.0 + sin(z * 0.024) * 16.0 + cos(z * 0.055) * 5.0
	var d1: float = absf(x - rx1)
	# Восточный каньонный поток в Чумных Землях
	var rx2: float = 528.0 + sin(z * 0.035) * 14.0
	var d2: float = absf(x - rx2) if z < 210.0 else 999.0
	# Кратер Чумы (токсичное озеро) и Ледниковое озеро
	var dlake1: float = Vector2(x - 525.0, z - 108.0).length() - 12.0
	var dlake2: float = Vector2(x - 246.0, z - 102.0).length() - 9.0
	return minf(minf(d1, d2), minf(maxf(0.0, dlake1), maxf(0.0, dlake2)))

func get_terrain_height(x: float, z: float) -> float:
	var coast: float = get_coast_signed_dist(x, z)
	var zb: Dictionary = get_zone_blended(x, z)
	var base_elev: float = float(zb.get("elev", 1.0))
	var h: float = base_elev + sin(x * 0.036) * cos(z * 0.034) * 1.25 + sin(x * 0.085 + z * 0.065) * 0.42

	# Береговая линия плавно опускается в океан (если далеко от дорог)
	var r_dist: float = get_road_dist(x, z)
	var road_flat: float = clampf((r_dist - 3.5) / 8.0, 0.0, 1.0)
	if coast < 0.08:
		var cf: float = clampf((coast + 0.06) / 0.14, 0.0, 1.0)
		var sea_h: float = lerpf(-2.2, h, cf)
		h = lerpf(maxf(h, 0.70), sea_h, road_flat)

	# Локальный рельеф (в Пиках выше, в Сумеречном болотистее)
	h = h * (0.30 + 0.70 * road_flat)

	# Выравнивание городов, ориентиров и боссов
	for zn in ZONES:
		var hub: Vector3 = zn["hub"]
		var dh: float = Vector2(x - hub.x, z - hub.z).length()
		if dh < 22.0:
			var f: float = clampf((dh - 14.0) / 8.0, 0.0, 1.0)
			h = lerpf(maxf(0.7, base_elev * 0.5), h, f)
		var bpos: Vector3 = zn["boss_pos"]
		var db: float = Vector2(x - bpos.x, z - bpos.z).length()
		if db < 18.0:
			var fb: float = clampf((db - 11.0) / 7.0, 0.0, 1.0)
			h = lerpf(base_elev + 0.6, h, fb)
		for lm in zn["landmarks"]:
			var lp: Vector3 = lm["pos"]
			var dl: float = Vector2(x - lp.x, z - lp.z).length()
			if dl < 14.0:
				var fl: float = clampf((dl - 8.0) / 6.0, 0.0, 1.0)
				h = lerpf(maxf(0.8, base_elev * 0.6), h, fl)

	# Реки и озёра (под дорогами проходят мосты!)
	var riv: float = get_river_dist(x, z)
	if riv < 7.0:
		var rf: float = clampf((riv - 2.8) / 4.2, 0.0, 1.0)
		var bridge_f: float = clampf((r_dist - 4.0) / 3.8, 0.0, 1.0)
		h = lerpf(maxf(h, 0.70), lerpf(-1.65, h, rf), bridge_f)

	return h

func get_dungeon_by_id(did: String) -> Dictionary:
	for d in DUNGEONS:
		if str(d["id"]) == did:
			return d
	return DUNGEONS[0]

func get_quest_by_id(qid: String) -> Dictionary:
	for q in QUESTS:
		if str(q["id"]) == qid:
			return q
	return {}

func generate_item(ilvl: int, forced_rarity: int = -1, forced_slot: String = "") -> Dictionary:
	var lv: int = clampi(ilvl, 1, 60)
	var rarity: int = forced_rarity
	if rarity < 0:
		var roll: float = randf()
		if roll < 0.015:
			rarity = 4
		elif roll < 0.08:
			rarity = 3
		elif roll < 0.25:
			rarity = 2
		elif roll < 0.60:
			rarity = 1
		else:
			rarity = 0
	rarity = clampi(rarity, 0, 4)

	var slot: String = forced_slot
	if slot == "":
		slot = str(SLOTS[randi() % SLOTS.size()])

	var bases: Array = SLOT_BASES[slot]
	var base_name: String = str(bases[randi() % bases.size()])
	var full_name: String = base_name
	if rarity >= 1:
		full_name = str(PREFIXES[randi() % PREFIXES.size()]) + " " + base_name
	if rarity >= 2:
		full_name += " " + str(SUFFIXES[randi() % SUFFIXES.size()])

	var mult: float = float(RARITIES[rarity]["mult"])
	var power: float = (4.5 + float(lv) * 2.6) * mult

	var atk: int = 0
	var arm: int = 0
	var hp: int = 0
	var crit: float = 0.0

	match slot:
		"weapon":
			atk = int(round(power * 1.38))
			crit = round(float(rarity) * 1.5)
		"armor":
			arm = int(round(power * 0.92))
			hp = int(round(power * 5.2))
		"helm":
			arm = int(round(power * 0.56))
			hp = int(round(power * 3.5))
			atk = int(round(power * 0.25))
		"shoulders":
			arm = int(round(power * 0.65))
			hp = int(round(power * 3.0))
			atk = int(round(power * 0.40))
		"amulet":
			atk = int(round(power * 0.58))
			hp = int(round(power * 2.8))
			crit = round((float(rarity) + 1.0) * 1.5)
		"ring":
			atk = int(round(power * 0.48))
			crit = round((float(rarity) + 1.0) * 1.8)

	return {
		"id": str(Time.get_ticks_msec()) + "_" + str(randi() % 99999),
		"name": full_name,
		"slot": slot,
		"rarity": rarity,
		"ilvl": lv,
		"upgrade": 0,
		"atk": atk,
		"arm": arm,
		"hp": hp,
		"crit": crit,
		"value": int(round((14.0 + float(lv) * 8.5) * mult))
	}

func item_display_name(item: Dictionary) -> String:
	var upg: int = int(item.get("upgrade", 0))
	var suffix: String = (" +%d" % upg) if upg > 0 else ""
	return str(item.get("name", "Предмет")) + suffix

func item_effective_stat(item: Dictionary, stat_key: String) -> float:
	var base_val: float = float(item.get(stat_key, 0.0))
	var upg: int = int(item.get("upgrade", 0))
	return base_val * (1.0 + float(upg) * 0.14)

# ==============================================================================
# РОСТЕР ПЕРСОНАЖЕЙ (до 6 слотов сохранения!)
# ==============================================================================
func load_roster() -> Array:
	var roster: Array = []
	if FileAccess.file_exists(ROSTER_PATH):
		var f: FileAccess = FileAccess.open(ROSTER_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_ARRAY:
				roster = parsed
	elif FileAccess.file_exists(LEGACY_SAVE_PATH):
		var fl: FileAccess = FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
		if fl != null:
			var p2: Variant = JSON.parse_string(fl.get_as_text())
			fl.close()
			if typeof(p2) == TYPE_DICTIONARY and not p2.is_empty():
				if not p2.has("char_id"):
					p2["char_id"] = "char_legacy_1"
				roster.append(p2)
				save_roster(roster)
	return roster

func save_roster(roster: Array) -> bool:
	var f: FileAccess = FileAccess.open(ROSTER_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(roster, "\t"))
	f.close()
	return true

func save_character(state: Dictionary) -> bool:
	var roster: Array = load_roster()
	var cid: String = str(state.get("char_id", ""))
	if cid == "":
		cid = "char_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 9999)
		state["char_id"] = cid
	var replaced: bool = false
	for i in range(roster.size()):
		if typeof(roster[i]) == TYPE_DICTIONARY and str(roster[i].get("char_id", "")) == cid:
			roster[i] = state
			replaced = true
			break
	if not replaced:
		roster.append(state)
	return save_roster(roster)

func delete_character(char_id: String) -> void:
	var roster: Array = load_roster()
	for i in range(roster.size() - 1, -1, -1):
		if typeof(roster[i]) == TYPE_DICTIONARY and str(roster[i].get("char_id", "")) == char_id:
			roster.remove_at(i)
	save_roster(roster)
