extends Node

var pools: Dictionary = {}
var mus_players: Array = []
var active_mus_idx: int = 0
var current_music_key: String = ""
var mus_tween: Tween = null
var music_muted: bool = false

const MUSIC_TRACKS: Dictionary = {
	"lobby": "res://assets/music/lobby.ogg",
	"elwynn": "res://assets/music/elwynn.mp3",
	"duskwood": "res://assets/music/duskwood.ogg",
	"barrens": "res://assets/music/barrens.mp3",
	"frostpeak": "res://assets/music/frostpeak.mp3",
	"plaguelands": "res://assets/music/plaguelands.ogg",
	"citadel": "res://assets/music/battle.ogg",
	"dungeon": "res://assets/music/dungeon.ogg",
	"raid": "res://assets/music/battle.ogg"
}

func _ready() -> void:
	# Боевые и системные звуки
	_add_audio("hit", "res://assets/sfx/swing1.wav", -6.0)
	_add_audio("hit", "res://assets/sfx/swing2.wav", -6.0)
	_add_audio("hit", "res://assets/sfx/swing3.wav", -6.0)
	_add_audio("crit", "res://assets/sfx/crit_metal.wav", -5.0)
	_add_audio("sword", "res://assets/sfx/sword_draw.wav", -7.0)
	_add_audio("spell", "res://assets/sfx/spell.wav", -6.0)
	_add_audio("spell", "res://assets/sfx/magic1.wav", -6.0)
	_add_audio("heal", "res://assets/sfx/magic1.wav", -8.0)
	_add_audio("potion", "res://assets/sfx/potion.wav", -5.0)
	_add_audio("loot", "res://assets/sfx/coin.wav", -6.0)
	_add_audio("loot", "res://assets/sfx/coin2.wav", -6.0)
	_add_audio("equip", "res://assets/sfx/equip.wav", -6.0)
	_add_audio("cloth", "res://assets/sfx/cloth1.ogg", -7.0)
	_add_audio("cloth", "res://assets/sfx/cloth2.ogg", -7.0)
	_add_audio("book", "res://assets/sfx/bookOpen.ogg", -6.0)
	_add_audio("chest", "res://assets/sfx/chest.wav", -5.0)
	_add_audio("boss", "res://assets/sfx/boss_roar.wav", -4.0)
	_add_audio("boss", "res://assets/sfx/ogre_roar.wav", -4.0)
	_add_audio("death", "res://assets/sfx/shade_hit.wav", -4.0)
	_add_audio("ui", "res://assets/sfx/ui1.wav", -10.0)
	_add_audio("ui", "res://assets/sfx/ui2.wav", -10.0)
	_add_audio("door", "res://assets/sfx/door.wav", -6.0)
	_add_audio("hearth", "res://assets/sfx/freeze_hearth.wav", -6.0)

	# Открытые CC0 звуки шагов по разным поверхностям (Kenney RPG Audio & DifferentSteps)
	for i in range(6):
		_add_audio("step_stone", "res://assets/sfx/step_stone_footstep0%d.ogg" % i, -12.0)
	_add_audio("step_stone", "res://assets/sfx/step_stone_1.ogg", -11.0)
	_add_audio("step_grass", "res://assets/sfx/step_leaves_1.ogg", -10.0)
	_add_audio("step_grass", "res://assets/sfx/step_leaves_2.ogg", -10.0)
	_add_audio("step_grass", "res://assets/sfx/step_mud_1.ogg", -12.0)
	_add_audio("step_sand", "res://assets/sfx/step_gravel_1.ogg", -11.0)
	_add_audio("step_sand", "res://assets/sfx/step_mud_1.ogg", -12.0)
	_add_audio("step_snow", "res://assets/sfx/step_gravel_1.ogg", -10.0)
	_add_audio("step_snow", "res://assets/sfx/step_leaves_1.ogg", -12.0)
	_add_audio("step_wood", "res://assets/sfx/step_wood_1.ogg", -10.0)
	_add_audio("step_wood", "res://assets/sfx/step_wood_2.ogg", -10.0)
	_add_audio("step_wood", "res://assets/sfx/step_wood_3.ogg", -10.0)
	_add_audio("horse_step", "res://assets/sfx/horse_trot.ogg", -11.0)

	_add_stream("levelup", _gen_levelup(), -4.0)
	_add_stream("quest", _gen_quest(), -5.0)
	_add_stream("portal", _gen_portal(), -6.0)

	# Плееры для плавного переключения музыки лобби и локаций
	for _i in range(2):
		var mp: AudioStreamPlayer = AudioStreamPlayer.new()
		mp.volume_db = -40.0
		add_child(mp)
		mus_players.append(mp)

func play_music(track_key: String) -> void:
	if track_key == current_music_key:
		return
	var path: String = str(MUSIC_TRACKS.get(track_key, ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path)
	if st == null:
		return
	st.set("loop", true)
	current_music_key = track_key

	var prev_mp: AudioStreamPlayer = mus_players[active_mus_idx]
	active_mus_idx = 1 - active_mus_idx
	var next_mp: AudioStreamPlayer = mus_players[active_mus_idx]

	next_mp.stream = st
	next_mp.volume_db = -36.0
	next_mp.play()

	var target_db: float = -80.0 if music_muted else -12.5
	if is_instance_valid(mus_tween):
		mus_tween.kill()
	mus_tween = create_tween().set_parallel(true)
	if prev_mp.playing:
		mus_tween.tween_property(prev_mp, "volume_db", -42.0, 1.2)
		mus_tween.chain().tween_callback(func() -> void:
			if not prev_mp == mus_players[active_mus_idx]:
				prev_mp.stop()
		)
	mus_tween.tween_property(next_mp, "volume_db", target_db, 1.4)

func play(sfx_name: String) -> void:
	if not pools.has(sfx_name):
		return
	var arr: Array = pools[sfx_name]
	if arr.is_empty():
		return
	var p: AudioStreamPlayer = arr[randi() % arr.size()]
	if sfx_name == "horse_step":
		p.pitch_scale = randf_range(0.95, 1.05)
		if not p.playing:
			p.play(randf_range(0.0, 1.2))
		return
	p.pitch_scale = randf_range(0.92, 1.09)
	p.play()

func stop_horse() -> void:
	if pools.has("horse_step"):
		for p in pools["horse_step"]:
			if is_instance_valid(p) and p.playing:
				p.stop()

func _add_audio(key: String, path: String, vol: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path)
	if st != null:
		st.set("loop", false)
		_add_stream(key, st, vol)

func _add_stream(key: String, st: AudioStream, vol: float) -> void:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = vol
	add_child(p)
	if not pools.has(key):
		pools[key] = []
	pools[key].append(p)

func _build(dur: float, rate: int, fn: Callable) -> AudioStreamWAV:
	var count: int = int(dur * float(rate))
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var sample: float = clampf(float(fn.call(t, dur)), -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 32767.0))
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

func _gen_levelup() -> AudioStreamWAV:
	return _build(0.95, 22050, func(t: float, _d: float) -> float:
		var f: float = 440.0
		if t > 0.16:
			f = 554.37
		if t > 0.32:
			f = 659.25
		if t > 0.48:
			f = 880.0
		var sig: float = sin(TAU * f * t) * 0.45 + sin(TAU * f * 1.5 * t) * 0.25 + sin(TAU * f * 2.0 * t) * 0.18
		return exp(-t * 2.2) * sig
	)

func _gen_quest() -> AudioStreamWAV:
	return _build(0.45, 22050, func(t: float, _d: float) -> float:
		var f: float = 392.0 if t < 0.14 else (493.88 if t < 0.28 else 587.33)
		return exp(-t * 4.5) * (sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.0 * t) * 0.18)
	)

func _gen_portal() -> AudioStreamWAV:
	return _build(0.55, 22050, func(t: float, _d: float) -> float:
		var f: float = 190.0 + sin(t * 20.0) * 70.0 + t * 380.0
		return exp(-t * 4.0) * (sin(TAU * f * t) * 0.5 + randf_range(-0.08, 0.08))
	)
