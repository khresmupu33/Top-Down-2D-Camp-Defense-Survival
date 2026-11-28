extends Node
## Time Stop: faktor perlambatan dunia/musuh + item (dari systems/time-stop.js). Autoload: TimeStop.


func enemy_slow_factor() -> float:
	return Config.TIME_STOP_SLOW if (State.time_stop > 0 or State.vindex_time_stop > 0) else 1.0


func world_slow_factor() -> float:
	return Config.TIME_STOP_SLOW if State.vindex_time_stop > 0 else 1.0


func check_time_stop_powerup() -> void:
	# Level mudah tidak menggunakan mekanik Time Stop sama sekali.
	if State.level == "easy":
		State.time_stop = 0
		State.time_stop_wave = 0
		if State.time_stop_powerup:
			State.time_stop_powerup.visible = false
		return
	var tp = State.time_stop_powerup
	if tp and tp.visible and Util.collide(State.player, tp):
		tp.visible = false
		GameAudio.play("time_stop")
		State.time_stop = Config.TIME_STOP_DURATION
		State.time_stop_wave = 0
		State.time_stop_origin_x = State.player.x + State.player.w / 2.0
		State.time_stop_origin_y = State.player.y + State.player.h / 2.0
		State.screen_shake = 7
		State.story_message = "⏳ TIME STOP — DUNIA MELAMBAT 5 DETIK"
		State.story_message_timer = 130
		State.time_stop_spawn_time = Util.now() + Util.random_int(Config.TIME_STOP_RESPAWN_MIN, Config.TIME_STOP_RESPAWN_MAX)
	if tp and not tp.visible and Util.now() >= State.time_stop_spawn_time and State.time_stop <= 0:
		Items.spawn_time_stop_powerup()


func update_time_stop() -> void:
	if State.level == "easy":
		State.time_stop = 0
		State.time_stop_wave = 0
		State.time_stop_wave_pulse = 0
		if State.time_stop_powerup:
			State.time_stop_powerup.visible = false
		return
	if State.time_stop > 0:
		State.time_stop -= 1
		State.time_stop_wave = mini(Config.TIME_STOP_DURATION, State.time_stop_wave + 1)
		State.time_stop_wave_pulse += 0.055
	else:
		State.time_stop_wave = 0
		State.time_stop_wave_pulse = 0
	if State.time_stop_powerup and State.time_stop_powerup.visible:
		State.time_stop_powerup.pulse += 0.12 * enemy_slow_factor()
