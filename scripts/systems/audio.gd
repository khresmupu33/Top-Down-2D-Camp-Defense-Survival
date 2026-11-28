extends Node
## Audio game: lagu latar + efek suara (dari systems/audio.js).
##
##   GameAudio.play("point")        efek suara (kunci = kunci di Config.AUDIO.files)
##   GameAudio.start_music()        mulai lagu latar (loop)
##   GameAudio.stop_music()         hentikan lagu (fade out)
##   GameAudio.set_muffled(true)    lagu "terpendam" (dipakai saat Time Stop)
##   GameAudio.set_paused(true)     jeda semua suara
##   GameAudio.toggle_mute()        bisu / bunyi (disimpan di memori)
##   GameAudio.tick()               dipanggil tiap frame: deteksi nyawa berkurang + Time Stop
##
## Aman dipakai tanpa file audio: suara yang tidak ada diabaikan, tidak ada error.
## Efek terpendam memakai AudioEffectLowPassFilter pada bus "GameMusic".
## Tidak memakai randf agar logika permainan tetap deterministik.

const MUSIC_BUS := "GameMusic"
const OPEN_CUTOFF := 22000.0

var muted := false           # status bisu (di memori)
var paused := false
var muffled := false
var want_music := false

var _streams := {}           # kunci -> AudioStream (atau null bila tidak ada)
var _music_player: AudioStreamPlayer = null
var _music_name := ""
var _music_bus_idx := -1
var _filter: AudioEffectLowPassFilter = null
var _last_played := {}       # kunci -> ms terakhir diputar
var _pitch_step := 0
var _prev_lives = null
var _muffle_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_bus()


## Membuat bus musik dengan filter low-pass (tanpa memanggil autoload lain).
func _setup_bus() -> void:
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus_idx == -1:
		AudioServer.add_bus()
		_music_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus_idx, MUSIC_BUS)
		AudioServer.set_bus_send(_music_bus_idx, "Master")
		_filter = AudioEffectLowPassFilter.new()
		_filter.cutoff_hz = OPEN_CUTOFF
		AudioServer.add_bus_effect(_music_bus_idx, _filter)
	else:
		for i in AudioServer.get_bus_effect_count(_music_bus_idx):
			var fx := AudioServer.get_bus_effect(_music_bus_idx, i)
			if fx is AudioEffectLowPassFilter:
				_filter = fx
				break
	_apply_mute()


## Membuka audio (di Godot tidak perlu gestur pengguna; dibiarkan sebagai no-op aman).
func unlock() -> void:
	pass


## Memuat stream sesuai kunci; file hilang/rusak -> null (diabaikan diam-diam).
func _get_stream(key: String) -> AudioStream:
	if _streams.has(key):
		return _streams[key]
	var stream: AudioStream = null
	var file = Config.AUDIO.files.get(key)
	if file != null and str(file) != "":
		var path: String = Config.AUDIO.base_path + str(file)
		if ResourceLoader.exists(path):
			var res = ResourceLoader.load(path)
			if res is AudioStream:
				stream = res
		elif FileAccess.file_exists(path) and path.get_extension().to_lower() == "mp3":
			stream = AudioStreamMP3.load_from_file(path)
	_streams[key] = stream
	return stream


# ── Efek suara ─────────────────────────────────────────────────────────────

func play(key: String, volume: float = 1.0, rate: float = -1.0) -> void:
	if not Config.AUDIO.files.has(key) or Config.AUDIO.files[key] == null:
		return
	if muted or paused:
		return
	var now := Util.now()
	var gap: float = float(Config.AUDIO.min_gap.get(key, 0))
	if gap > 0.0 and _last_played.has(key) and now - float(_last_played[key]) < gap:
		return
	_last_played[key] = now

	var stream := _get_stream(key)
	if stream == null:
		return
	# variasi nada deterministik
	_pitch_step = (_pitch_step + 1) % 5
	var pitch := rate
	if pitch < 0.0:
		pitch = (0.92 + _pitch_step * 0.04) if key == "meteor_pass" else 1.0
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Master"
	p.pitch_scale = pitch
	p.volume_db = linear_to_db(maxf(0.0001, Config.AUDIO.sfx_volume * volume))
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# ── Lagu latar ─────────────────────────────────────────────────────────────

func _pick_music() -> String:
	if State.level == "hard" and _get_stream("music_hard") != null:
		return "music_hard"
	return "music"


func start_music() -> void:
	want_music = true
	var key := _pick_music()
	if _music_player != null and _music_name == key:
		return
	_stop_node(0.0)
	var stream := _get_stream(key)
	if stream == null:
		return
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis or stream is AudioStreamWAV:
		stream = stream.duplicate()
		stream.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = MUSIC_BUS
	p.volume_db = linear_to_db(_music_volume())
	p.stream_paused = paused
	add_child(p)
	p.play()
	_music_player = p
	_music_name = key
	_apply_muffle(true)


func _music_volume() -> float:
	var v: float = Config.AUDIO.muffled_music_volume if muffled else Config.AUDIO.music_volume
	return maxf(0.0001, v)


func _stop_node(fade: float) -> void:
	var node := _music_player
	if node == null:
		return
	_music_player = null
	_music_name = ""
	if fade > 0.0 and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(node, "volume_db", -80.0, fade)
		tw.tween_callback(node.queue_free)
	else:
		node.stop()
		node.queue_free()


func stop_music(fade: float = 0.6) -> void:
	want_music = false
	_stop_node(fade)


## Redam lagu (low-pass + volume turun) saat Time Stop.
func _apply_muffle(instant: bool) -> void:
	var cutoff: float = Config.AUDIO.muffled_frequency if muffled else OPEN_CUTOFF
	var tc := 0.001 if instant else 0.12
	if _muffle_tween != null and _muffle_tween.is_valid():
		_muffle_tween.kill()
	_muffle_tween = create_tween()
	_muffle_tween.set_parallel(true)
	if _filter != null:
		_muffle_tween.tween_property(_filter, "cutoff_hz", cutoff, tc)
	if _music_player != null:
		_muffle_tween.tween_property(_music_player, "volume_db", linear_to_db(_music_volume()), tc)


func set_muffled(on: bool) -> void:
	on = bool(on)
	if on == muffled:
		return
	muffled = on
	_apply_muffle(false)


# ── Jeda & bisu ────────────────────────────────────────────────────────────

func set_paused(on: bool) -> void:
	paused = bool(on)
	if _music_player != null:
		_music_player.stream_paused = paused
	for c in get_children():
		if c is AudioStreamPlayer and c != _music_player:
			c.stream_paused = paused


func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, Config.AUDIO.master_volume)))


func set_muted(on: bool) -> void:
	muted = bool(on)
	_apply_mute()
	# perbarui tombol bisu di halaman game bila ada
	var ui = get_node_or_null("/root/GameUI")
	var btn = ui.node("muteButton") if ui != null and ui.has_method("node") else null
	if btn != null:
		btn.text = "🔇" if muted else "🔊"


func toggle_mute() -> void:
	set_muted(not muted)


# ── Dipanggil tiap frame ───────────────────────────────────────────────────

func tick() -> void:
	var lives = State.lives
	if _prev_lives != null and lives < _prev_lives and State.game_state == "playing":
		play("hit")
	_prev_lives = lives
	set_muffled(State.time_stop > 0 or State.vindex_time_stop > 0)
