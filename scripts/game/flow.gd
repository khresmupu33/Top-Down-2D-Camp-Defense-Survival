extends Node
## Alur permainan: mulai, jeda, ending, game over, ulang (dari game/flow.js). Autoload: GameFlow.

const SCREEN_IDS = ["gameScreen", "endScreen", "trueEndingScreen"]

## true setelah semua killer hancur pada animasi ending: teks "SEMUA KILLER HANCUR" digambar oleh DrawGame.
var ending_all_gone_text := false
var _true_ending_scheduled := false


func _set_visible(id: String, on: bool) -> void:
	var n = GameUI.node(id)
	if n:
		n.visible = on


func _set_text(id: String, t: String) -> void:
	var n = GameUI.node(id)
	if n:
		n.text = t


## Mengembalikan nilai awal satu putaran permainan (dipakai saat mulai & saat lanjut setelah poin 25).
func reset_run_state() -> void:
	State.lives = 3
	State.paused = false
	GameAudio.set_paused(false)
	if State.hard_revival_timer != null:
		if State.hard_revival_timer is Node and is_instance_valid(State.hard_revival_timer):
			State.hard_revival_timer.queue_free()
		State.hard_revival_timer = null
	State.hit_cooldown = 0
	State.global_freeze = 0
	State.power_active = 0
	State.killer_spawn_time = 0
	State.particle_list = []
	State.screen_shake = 0
	State.player_death_timer = 0
	State.player_death_max = 0
	State.meteors = []
	State.meteor_session_active = false
	State.meteor_session_timer = 0
	State.meteor_next_spawn = 0
	State.meteor_session_used = false
	State.meteor_warning_timer = 0
	State.meteor_pre_shower_active = false
	State.meteor_pre_shower_timer = 0
	State.meteor_pre_shower_next_spawn = 0
	State.meteor_pre_shower_spawned = 0
	State.meteor_shower_unlocked = false
	State.pressed_keys.clear()


func start_game(lv: String, initial_score = null) -> void:
	State.level = lv
	State.score = 0 if initial_score == null else initial_score
	reset_run_state()
	ending_all_gone_text = false
	_true_ending_scheduled = false
	State.game_state = "hardIntro" if State.level == "hard" else "ready"
	GameSetup.create_game_objects()
	if State.level == "hard":
		HardIntro.init_hard_intro()
	show_only("gameScreen")
	_set_visible("readyOverlay", State.level != "hard")
	_set_visible("pauseText", false)
	_set_visible("spawnWarning", false)
	Hud.update_hud()


func begin_play() -> void:
	if State.level == "hard" and State.game_state == "hardIntro":
		if not State.hard_intro_ready:
			return
		State.game_state = "playing"
		State.story_message = 'LORD VINDEX: "Permainan dimulai."'
		State.story_message_timer = 140
		_set_visible("readyOverlay", false)
		GameAudio.start_music()
		return
	if State.game_state != "ready":
		return
	State.game_state = "playing"
	_set_visible("readyOverlay", false)
	GameAudio.start_music()


func toggle_pause() -> void:
	if State.game_state != "playing":
		return
	State.paused = not State.paused
	GameAudio.set_paused(State.paused)
	Hud.update_hud()


func start_ending() -> void:
	if State.game_state == "ending":
		return
	GameAudio.stop_music()
	if State.level == "hard":
		State.hard_meteor_permanent = false
		State.meteor_session_active = false
		State.archer_arrows = []
		State.vindex_time_stop = 0
		State.vindex_laser_active = false
		State.vindex_laser_countdown = 0
		State.vindex_laser_fire_timer = 0
		State.vindex_laser_has_hit = false
		State.story_message = 'Lord Vindex: "Aku mengaku kalah. Aku yang mengakhiri permainan ini."'
		State.story_message_timer = 180
	State.game_state = "ending"
	State.ending_index = 0
	State.ending_destroy_index = 0
	State.ending_destroyed_count = 0
	State.ending_destroy_timer = 0
	State.ending_wait_timer = 0
	State.particle_list = []
	ending_all_gone_text = false
	_true_ending_scheduled = false


func show_true_ending() -> void:
	State.game_state = "end"
	show_only("trueEndingScreen")


func show_end() -> void:
	GameAudio.stop_music()
	if State.level == "hard" and State.score < 100:
		if State.hard_revival_timer != null:
			if State.hard_revival_timer is Node and is_instance_valid(State.hard_revival_timer):
				State.hard_revival_timer.queue_free()
			State.hard_revival_timer = null
		State.game_state = "hardDeath"
		_set_text("finalScore", "Poin : " + str(State.score))
		_set_text("endTitle", "GAME OVER")
		var msg = GameUI.node("hardDeathMessage")
		if msg:
			var cause: String = State.hard_death_cause
			msg.text = cause if cause != "" else 'Lord Vindex: "Kali ini permainan benar-benar berakhir."'
			msg.visible = true
		show_only("endScreen")
		return
	State.game_state = "end"
	_set_text("finalScore", "Poin : " + str(State.score))
	_set_visible("hardDeathMessage", false)
	show_only("endScreen")


func restart_game() -> void:
	start_game(State.level)


func show_only(id: String) -> void:
	for sid in SCREEN_IDS:
		_set_visible(sid, false)
	_set_visible(id, true)
	# Lapisan di luar arena (nyawa, MENU, audio, dialog Vindex) hanya ikut layar game.
	_set_visible("outerGame", id == "gameScreen")


## Kembali ke halaman menu.
func show_menu() -> void:
	Util.goto_page("menu")


func _finish_true_ending() -> void:
	if State.in_game and State.game_state == "ending":
		show_true_ending()


## Animasi ending: setiap killer dihancurkan satu per satu.
func run_ending_animation() -> void:
	if State.game_state != "ending":
		return
	if State.level == "hard" and State.lord_vindex and not State.lord_vindex.get("dead", false):
		State.lord_vindex.dead = true
		for a in State.archers:
			a.dead = true
		State.archers = []
		State.archer_arrows = []
		State.story_message = "LORD VINDEX TERJATUH — SEMUA PEMBURU HANCUR"
		State.story_message_timer = 220
	# Latar + judul digambar oleh DrawGame berdasarkan State.game_state == "ending".
	var all_gone := false
	if State.ending_destroy_index < State.killers.size():
		var k = State.killers[State.ending_destroy_index]
		if not k.get("_ending_triggered", false):
			k._ending_triggered = true
			k.disintegrating = true
			k.disintegrate_timer = 40
			Killers.create_disintegration_particles(k)
			State.screen_shake = 7
		k.disintegrate_timer = maxi(0, k.disintegrate_timer - 1)
	else:
		all_gone = true
	# Efek (partikel digambar oleh DrawGame).
	if not all_gone:
		var k2 = State.killers[State.ending_destroy_index]
		if k2.disintegrate_timer <= 0:
			State.killers.remove_at(State.ending_destroy_index)
			State.ending_destroyed_count += 1
			State.ending_wait_timer = 16
	else:
		State.ending_wait_timer -= 1
		if State.ending_wait_timer <= -35:
			ending_all_gone_text = true
			if not _true_ending_scheduled:
				_true_ending_scheduled = true
				Util.after_ms(700, Callable(self, "_finish_true_ending"))
			return
	Particles.update_particles()
