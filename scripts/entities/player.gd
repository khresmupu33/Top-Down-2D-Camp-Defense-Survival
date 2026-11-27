extends Node
## Pemain: gerak, pengambilan target/nyawa/power, partikel kematian (dari entities/player.js).


func update_player() -> void:
	var sf: float = TimeStop.world_slow_factor()
	var p = State.player
	if State.player_shock_timer > 0 and State.player_death_timer <= 0:
		p.x += State.player_shock_x * sf
		p.y += State.player_shock_y * sf
		State.player_shock_x *= .86
		State.player_shock_y *= .86
		p.x = maxf(0, minf(Config.WIDTH - p.w, p.x))
		p.y = maxf(0, minf(Config.HEIGHT - p.h, p.y))
	for key in State.pressed_keys.keys():
		if key == "ArrowUp":
			p.y -= Config.PLAYER_SPEED * sf
		if key == "ArrowDown":
			p.y += Config.PLAYER_SPEED * sf
		if key == "ArrowLeft":
			p.x -= Config.PLAYER_SPEED * sf
		if key == "ArrowRight":
			p.x += Config.PLAYER_SPEED * sf
	Util.wrap_obj(p)


func check_player_target() -> void:
	if not Util.collide(State.player, State.target):
		return
	State.score += 1
	GameAudio.play("point")
	Meteors.check_large_meteor_milestone()
	if State.score == Config.METEOR_TRIGGER_SCORE:
		Meteors.begin_meteor_preparation()
		Meteors.schedule_next_large_meteor()
	Items.spawn_target()
	# TRUE ENDING.
	if State.score >= 100:
		State.score = 100
		GameFlow.start_ending()


func check_player_health() -> void:
	var h = State.health
	if h == null or not h.visible or not Util.collide(State.player, h):
		return
	if State.lives < 3:
		State.lives += 1
		GameAudio.play("health")
		h.visible = false
		State.health_spawn_time = Util.now() + Util.random_int(Config.HEALTH_RESPAWN_MIN, Config.HEALTH_RESPAWN_MAX)
		State.screen_shake = 5


func check_player_powerup() -> void:
	var pu = State.powerup
	if pu == null or not pu.visible or not Util.collide(State.player, pu):
		return
	pu.visible = false
	GameAudio.play("power_kill")
	State.power_active = Config.POWER_DURATION
	State.powerup_spawn_time = Util.now() + Util.random_int(Config.POWER_RESPAWN_MIN, Config.POWER_RESPAWN_MAX)
	State.screen_shake = 8


func create_player_death_particles() -> void:
	var cx: float = State.player.x + State.player.w / 2.0
	var cy: float = State.player.y + State.player.h / 2.0
	for i in range(30):
		var angle: float = randf() * PI * 2
		var speed: float = 1.5 + randf() * 5.5
		State.particle_list.append({
			"x": cx,
			"y": cy,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - 1,
			"size": 2 + randf() * 4,
			"life": 35 + randf() * 45,
			"max_life": 80,
			"death_particle": true
		})
