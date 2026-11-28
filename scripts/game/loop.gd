extends Node
## Logika per-tick (60 FPS tetap) + dispatcher pusat loop permainan (dari game/loop.js). Autoload: GameLoop.
## Godot sudah memanggil _physics_process pada 60 Hz, jadi accumulator fixed-step JS tidak diperlukan.


func _physics_process(_delta: float) -> void:
	if not State.in_game:
		return
	match State.game_state:
		"playing":
			run_game()
		"hardIntro":
			HardIntro.run_hard_intro()
		"ending":
			GameFlow.run_ending_animation()


func update_game() -> void:
	var now: float = Util.now()
	if State.level == "hard" and State.hard25_sequence_active:
		HardSequence.update_hard25_sequence()
		return
	if State.player_death_timer > 0:
		State.player_death_timer -= 1
		Particles.update_particles()
		if State.player_death_timer <= 0:
			GameFlow.show_end()
			return
		return
	# Otomatis pindah.
	if now - State.target_spawn_time > 10000:
		Items.spawn_target()
	if State.health and not State.health.visible and now >= State.health_spawn_time and State.lives < 3:
		Items.spawn_health()
	if State.powerup and not State.powerup.visible and now >= State.powerup_spawn_time and State.power_active <= 0:
		Items.spawn_powerup()
	if now >= State.killer_spawn_time and State.killers.size() < Config.MAX_KILLERS:
		Killers.add_killer()
		State.killer_spawn_time = now + State.next_killer_spawn_delay
	# Player tetap bisa bergerak hanya saat tidak pause.
	Player.update_player()
	# Power-up pickup terjadi sebelum Killer bergerak agar perilaku panik/kabur
	# mulai tepat pada frame pemain mendapat Power Kill.
	Player.check_player_powerup()
	TimeStop.check_time_stop_powerup()
	TimeStop.update_time_stop()
	VindexAttacks.update_vindex_time_stop()
	# Hujan meteor.
	Meteors.update_meteors()
	Meteors.check_meteor_collisions()
	if State.player_death_timer > 0:
		return
	# Killer.
	Killers.update_killers()
	Archers.update_archers()
	LordVindex.update_lord_vindex()
	VindexAttacks.update_vindex_specials()
	LordVindex.check_vindex_enemy_collisions()
	# Killer collision.
	Killers.update_killer_collisions()
	Archers.check_archer_collisions()
	LordVindex.check_lord_collision()
	# Gadfly.
	Gadflies.update_gadflies()
	# Player target.
	Player.check_player_target()
	Story.update_story_triggers()
	if State.game_state != "playing":
		return
	# Health.
	Player.check_player_health()
	# Gadfly.
	Gadflies.check_player_gadflies()
	# Killer.
	Killers.check_player_killers()
	# Power timer.
	if State.power_active > 0:
		State.power_active -= TimeStop.world_slow_factor()
		if State.power_active < 0:
			State.power_active = 0
	# Freeze.
	Killers.update_global_freeze()
	# Partikel.
	Particles.update_particles()


## Satu tick permainan (JS runGame). Jeda ditangani di sini.
func run_game() -> void:
	if State.game_state != "playing":
		return
	if State.paused:
		_set_visible("pauseText", true)
		return
	_set_visible("pauseText", false)
	update_game()


func _set_visible(id: String, on: bool) -> void:
	var n = GameUI.node(id)
	if n:
		n.visible = on
