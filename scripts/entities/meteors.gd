extends Node
## Hujan meteor, meteor besar, dan dampaknya (dari entities/meteors.js). Autoload: Meteors.


func start_meteor_session() -> void:
	if State.meteor_session_active or State.game_state != "playing":
		return
	State.meteor_session_used = true
	State.meteor_session_active = true
	State.meteor_session_timer = Config.METEOR_SESSION_DURATION
	State.meteor_next_spawn = Util.random_int(150, 300)
	State.meteor_warning_timer = 120
	State.meteor_phase = "firstBurst"
	State.meteor_phase_timer = 0
	State.meteor_burst_cooldown = Config.METEOR_BURST_COOLDOWN
	State.screen_shake = 6
	for i in range(Config.METEOR_FIRST_BURST):
		spawn_meteor(-i * 55, true)


func spawn_meteor(offset_y: float = 0, force_diagonal: bool = false) -> void:
	GameAudio.play("meteor_pass")
	var size: int = Util.random_int(12, 20)
	var x: int = Util.random_int(Config.METEOR_SAFE_MARGIN, Config.WIDTH - size - Config.METEOR_SAFE_MARGIN)
	var diagonal: bool = force_diagonal or randf() < .72
	var direction: int = -1 if randf() < .5 else 1
	var vx: float
	if diagonal:
		vx = direction * Util.random_int(2, 4)
	else:
		vx = (randf() - .5) * 1.4
	State.meteors.append({
		"x": x, "y": -size - 20 + offset_y, "w": size, "h": size,
		"vx": vx, "vy": Util.random_int(Config.METEOR_SPEED_MIN, Config.METEOR_SPEED_MAX),
		"rotation": randf() * PI * 2, "rotation_speed": (randf() - .5) * .18,
		"life": 180, "trail": [], "large": false, "impacted": false
	})


func spawn_large_meteor() -> void:
	if State.large_meteor != null or State.game_state != "playing":
		return
	var size: float = Config.LARGE_METEOR_SIZE
	var warn = State.large_meteor_warning
	var target_x: float = warn.x if warn != null else Util.random_int(60, Config.WIDTH - 60)
	var target_y: float = warn.y if warn != null else Util.random_int(150, Config.HEIGHT - 100)
	var start_x: float = maxf(0, minf(Config.WIDTH - size, target_x - size / 2.0 + Util.random_int(-170, 170)))
	var start_y: float = -size - 45
	var dx: float = target_x - (start_x + size / 2.0)
	var dy: float = target_y - (start_y + size / 2.0)
	var dist: float = Vector2(dx, dy).length()
	if dist == 0.0:
		dist = 1.0
	State.large_meteor = {
		"x": start_x, "y": start_y, "w": size, "h": size,
		"vx": dx / dist * Config.LARGE_METEOR_SPEED, "vy": dy / dist * Config.LARGE_METEOR_SPEED,
		"rotation": randf() * PI * 2, "rotation_speed": .08 * (-1.0 if randf() < .5 else 1.0),
		"target_x": target_x, "target_y": target_y, "trail": [], "active": true
	}
	State.large_meteor_warning = null


func trigger_rare_large_meteor() -> void:
	if State.level == "hard":
		return
	if State.large_meteor_pending or State.large_meteor_warning != null or State.game_state != "playing":
		return
	State.large_meteor_pending = true
	State.large_meteor_spawn_timer = Config.LARGE_METEOR_WARNING_TIME
	State.large_meteor_warning = {
		"x": Util.random_int(80, Config.WIDTH - 80),
		"y": Util.random_int(130, Config.HEIGHT - 100),
		"target_x": Util.random_int(80, Config.WIDTH - 80),
		"target_y": Util.random_int(130, Config.HEIGHT - 100),
		"radius": Config.LARGE_METEOR_SIZE * .62,
		"life": Config.LARGE_METEOR_WARNING_TIME,
		"phase": randf() * PI * 2
	}
	State.screen_shake = 3


func check_large_meteor_milestone() -> void:
	if State.score < Config.METEOR_TRIGGER_SCORE or State.large_meteor_milestones.has(State.score):
		return
	State.large_meteor_milestones[State.score] = true


func schedule_next_large_meteor() -> void:
	if State.score < Config.METEOR_TRIGGER_SCORE:
		State.large_meteor_spawn_timer = 999999
		return
	State.large_meteor_spawn_timer = Util.random_int(Config.LARGE_METEOR_RANDOM_MIN, Config.LARGE_METEOR_RANDOM_MAX)


func begin_meteor_preparation() -> void:
	if State.meteor_pre_shower_active or State.meteor_session_active or State.game_state != "playing" or State.score < Config.METEOR_TRIGGER_SCORE:
		return
	State.meteor_shower_unlocked = true
	State.meteor_pre_shower_active = true
	State.meteor_pre_shower_timer = Util.random_int(Config.METEOR_PRE_SHOWER_MIN, Config.METEOR_PRE_SHOWER_MAX)
	State.meteor_pre_shower_next_spawn = Util.random_int(45, 90)
	State.meteor_pre_shower_spawned = 0
	State.meteor_warning_timer = 0
	State.screen_shake = 3


func update_meteor_preparation() -> void:
	if not State.meteor_pre_shower_active:
		return
	if State.game_state != "playing":
		return
	State.meteor_pre_shower_timer -= 1
	if State.meteor_pre_shower_spawned < Config.METEOR_PRE_SHOWER_MAX_METEORS:
		if State.meteor_pre_shower_next_spawn <= 0:
			spawn_meteor(0, false)
			State.meteor_pre_shower_spawned += 1
			State.meteor_pre_shower_next_spawn = Util.random_int(Config.METEOR_PRE_SHOWER_SPAWN_INTERVAL_MIN, Config.METEOR_PRE_SHOWER_SPAWN_INTERVAL_MAX)
		else:
			State.meteor_pre_shower_next_spawn -= 1
	if State.meteor_pre_shower_timer <= 0:
		State.meteor_pre_shower_active = false
		State.meteor_session_used = false
		start_meteor_session()


func update_large_meteor_random_event() -> void:
	if State.game_state != "playing" or State.score < Config.METEOR_TRIGGER_SCORE or not State.meteor_shower_unlocked or State.meteor_pre_shower_active:
		return
	# SULIT tidak memakai meteor besar / meteor-laser; Vindex punya tantangannya sendiri (vindex_attacks.gd).
	if State.level == "hard":
		return
	if State.large_meteor_pending:
		var w = State.large_meteor_warning
		if w != null:
			w.life -= 1
			w.phase += .14
			var nx: float = w.x + (w.target_x - w.x) * .035
			var ny: float = w.y + (w.target_y - w.y) * .035
			w.x = nx + sin(w.phase) * 5
			w.y = ny + cos(w.phase * 1.3) * 3
			if w.life <= 0:
				State.large_meteor_pending = false
				spawn_large_meteor()
				State.screen_shake = 8
		return
	State.large_meteor_spawn_timer -= 1
	if State.large_meteor_spawn_timer <= 0:
		trigger_rare_large_meteor()


func update_large_meteor() -> void:
	var m = State.large_meteor
	if m != null and m.active:
		m.trail.append({"x": m.x + m.w / 2.0, "y": m.y + m.h / 2.0})
		if m.trail.size() > 4:
			m.trail.pop_front()
		m.x += m.vx
		m.y += m.vy
		m.rotation += m.rotation_speed
		if m.x < 0:
			m.x = 0
			m.vx = absf(m.vx)
		if m.x + m.w > Config.WIDTH:
			m.x = Config.WIDTH - m.w
			m.vx = -absf(m.vx)
		var cx: float = m.x + m.w / 2.0
		var cy: float = m.y + m.h / 2.0
		if Vector2(m.target_x - cx, m.target_y - cy).length() <= maxf(8, m.w * .13) or m.y > Config.HEIGHT + 80:
			m.active = false
			queue_large_meteor_impact(m.target_x, m.target_y)
			State.large_meteor = null
			State.screen_shake = 12


func update_meteors() -> void:
	var world_slow: float = TimeStop.enemy_slow_factor()
	if State.level == "hard" and State.score >= 25:
		State.hard_meteor_permanent = true
		State.meteor_shower_unlocked = true
		if not State.meteor_session_active and not State.meteor_pre_shower_active:
			State.meteor_session_active = true
			State.meteor_session_timer = 999999
			State.meteor_phase = "random2"
			var ns = State.meteor_next_spawn
			State.meteor_next_spawn = minf(ns if ns != 0 else 1, 8)
	update_large_meteor_random_event()
	if State.level != "hard":
		update_large_meteor()
		process_large_meteor_impact()
	if State.score >= Config.METEOR_TRIGGER_SCORE and not State.meteor_shower_unlocked:
		begin_meteor_preparation()
	update_meteor_preparation()
	if not State.meteor_session_active and not State.meteor_pre_shower_active:
		if State.meteor_shower_unlocked and State.meteor_session_used:
			if State.meteor_next_session_timer > 0:
				State.meteor_next_session_timer -= world_slow
			if State.meteor_next_session_timer <= 0:
				start_meteor_session()
	elif State.meteor_session_active:
		State.meteor_session_timer -= world_slow
		State.meteor_phase_timer += world_slow
		if State.meteor_burst_cooldown > 0:
			State.meteor_burst_cooldown = maxf(0, State.meteor_burst_cooldown - world_slow)
		if State.meteor_phase == "firstBurst" and State.meteor_phase_timer > 75:
			State.meteor_phase = "random"
			State.meteor_phase_timer = 0
			State.meteor_next_spawn = Util.random_int(150, 300)
		elif State.meteor_phase == "random":
			if State.meteor_phase_timer >= Config.METEOR_SECOND_BURST_TIME:
				State.meteor_phase = "secondBurst"
				State.meteor_phase_timer = 0
				State.meteor_burst_cooldown = Config.METEOR_BURST_COOLDOWN
				for i in range(Config.METEOR_SECOND_BURST):
					spawn_meteor(-i * 62, true)
			elif State.meteor_next_spawn <= 0:
				spawn_meteor()
				State.meteor_next_spawn = Util.random_int(150, 300)
			else:
				State.meteor_next_spawn -= world_slow
		elif State.meteor_phase == "secondBurst" and State.meteor_phase_timer > 70:
			State.meteor_phase = "random2"
			State.meteor_phase_timer = 0
			State.meteor_next_spawn = Util.random_int(150, 300)
		elif State.meteor_phase == "random2":
			if State.meteor_next_spawn <= 0:
				spawn_meteor()
				State.meteor_next_spawn = Util.random_int(180, 330)
			else:
				State.meteor_next_spawn -= world_slow
		if State.meteor_session_timer <= 0 and not State.hard_meteor_permanent:
			State.meteor_session_active = false
			State.meteor_phase = "idle"
			State.meteor_next_session_timer = Util.random_int(Config.METEOR_NEXT_SESSION_MIN, Config.METEOR_NEXT_SESSION_MAX)
			State.meteors.clear()
	var i: int = State.meteors.size() - 1
	while i >= 0:
		var m = State.meteors[i]
		m.trail.append({"x": m.x + m.w / 2.0, "y": m.y + m.h / 2.0})
		if m.trail.size() > 3:
			m.trail.pop_front()
		m.x += m.vx * world_slow
		m.y += m.vy * world_slow
		m.rotation += m.rotation_speed * world_slow
		if m.x < 0:
			m.x = 0
			m.vx = absf(m.vx)
		if m.x + m.w > Config.WIDTH:
			m.x = Config.WIDTH - m.w
			m.vx = -absf(m.vx)
		if m.y > Config.HEIGHT + 70:
			State.meteors.remove_at(i)
		i -= 1


func queue_large_meteor_impact(x: float, y: float) -> void:
	if State.large_meteor_impact_state != null or State.game_state != "playing":
		return
	State.large_meteor_impact_state = {"x": x, "y": y, "stage": 0, "player_direct": false}
	State.screen_shake = 12


func process_large_meteor_impact() -> void:
	var st = State.large_meteor_impact_state
	if st == null:
		return
	if State.game_state != "playing":
		State.large_meteor_impact_state = null
		return
	if st.stage == 0:
		GameAudio.play("meteor_big")
		var box := {"x": st.x - Config.LARGE_METEOR_SIZE / 2.0, "y": st.y - Config.LARGE_METEOR_SIZE / 2.0, "w": Config.LARGE_METEOR_SIZE, "h": Config.LARGE_METEOR_SIZE}
		st.player_direct = State.player != null and Util.collide(State.player, box)
		if st.player_direct and State.hit_cooldown <= 0 and State.lives > 0:
			State.lives = maxi(0, State.lives - Config.LARGE_METEOR_PLAYER_DAMAGE)
			State.hit_cooldown = Config.METEOR_PLAYER_COOLDOWN
			State.screen_shake = 20
			if State.lives <= 0:
				State.lives = 0
				State.player_death_max = 100
				State.player_death_timer = State.player_death_max
				State.global_freeze = State.player_death_max
				State.hit_cooldown = State.player_death_max
		var i: int = State.killers.size() - 1
		while i >= 0:
			var k = State.killers[i]
			i -= 1
			if k == null or k.loading > 0 or k.disintegrating:
				continue
			if Util.collide(k, box):
				k.disintegrating = true
				k.disintegrate_timer = 38
				k.hit_flash = 18
				k.panic = false
				Killers.create_disintegration_particles(k)
		st.stage = 1
		return
	if st.stage == 1:
		create_large_meteor_impact_particles(st.x, st.y)
		st.stage = 2
		return
	if st.stage == 2:
		var max_dist: float = Vector2(Config.WIDTH, Config.HEIGHT).length() / 2.0
		if not st.player_direct and State.player != null and State.player_death_timer <= 0:
			var p = State.player
			var dx: float = p.x + p.w / 2.0 - st.x
			var dy: float = p.y + p.h / 2.0 - st.y
			var d: float = Vector2(dx, dy).length()
			if d == 0.0:
				d = 1.0
			var f: float = maxf(.18, 1 - minf(d / max_dist, 1) * .72)
			State.player_shock_timer = 34
			State.player_shock_x = (dx / d) * (5 + Config.LARGE_METEOR_SHOCK_POWER * f)
			State.player_shock_y = (dy / d) * (5 + Config.LARGE_METEOR_SHOCK_POWER * f)
		for k in State.killers:
			if k == null or k.loading > 0 or k.disintegrating:
				continue
			var dx: float = k.x + k.w / 2.0 - st.x
			var dy: float = k.y + k.h / 2.0 - st.y
			var d: float = Vector2(dx, dy).length()
			if d == 0.0:
				d = 1.0
			var f: float = maxf(.18, 1 - minf(d / max_dist, 1) * .72)
			var power: float = 5 + Config.LARGE_METEOR_SHOCK_POWER * f
			k.knockback_x = (dx / d) * power
			k.knockback_y = (dy / d) * power
			k.knockback_timer = 34
			k.hit_flash = 16
		large_meteor_shockwave(st.x, st.y)
		schedule_next_large_meteor()
		State.large_meteor_impact_state = null


func create_large_meteor_impact_particles(x: float, y: float) -> void:
	var count := 8
	for i in range(count):
		var a: float = randf() * PI * 2
		var sp: float = 2 + randf() * 4
		State.particle_list.append({"x": x, "y": y, "vx": cos(a) * sp, "vy": sin(a) * sp - 1, "size": 2 + randf() * 3, "life": 20 + randf() * 18, "max_life": 40, "meteor_particle": true})


func large_meteor_shockwave(x: float, y: float) -> void:
	State.meteor_shockwave = {"x": x, "y": y, "r": 8, "max": Vector2(Config.WIDTH, Config.HEIGHT).length() * .72, "life": 42}


func check_meteor_collisions() -> void:
	if State.meteors.is_empty():
		return
	if State.hit_cooldown > 0:
		State.hit_cooldown -= 1
	var i: int = State.meteors.size() - 1
	while i >= 0:
		if i >= State.meteors.size():
			i = State.meteors.size() - 1
			if i < 0:
				break
		var m = State.meteors[i]
		if m.large:
			i -= 1
			continue
		if Util.collide(State.player, m):
			if i < State.meteors.size():
				State.meteors.remove_at(i)
			create_meteor_impact_particles(m.x + m.w / 2.0, m.y + m.h / 2.0)
			State.screen_shake = 14
			if State.hit_cooldown <= 0 and State.lives > 0:
				State.lives -= 1
				State.hit_cooldown = Config.METEOR_PLAYER_COOLDOWN
				if State.lives <= 0:
					State.lives = 0
					State.player_death_max = 100
					State.player_death_timer = State.player_death_max
					State.global_freeze = State.player_death_max
					State.hit_cooldown = State.player_death_max
					Player.create_player_death_particles()
					State.screen_shake = 18
					return
		var ki: int = State.killers.size() - 1
		while ki >= 0:
			var killer = State.killers[ki]
			ki -= 1
			if killer.loading > 0 or killer.disintegrating:
				continue
			if Util.collide(killer, m):
				killer.disintegrating = true
				killer.disintegrate_timer = 32
				Killers.create_disintegration_particles(killer)
				killer.hit_flash = 12
				State.screen_shake = 8
				if i < State.meteors.size():
					State.meteors.remove_at(i)
				break
		i -= 1


func create_meteor_impact_particles(x: float, y: float) -> void:
	for i in range(8):
		var a: float = randf() * PI * 2
		var sp: float = 1.5 + randf() * 4
		State.particle_list.append({"x": x, "y": y, "vx": cos(a) * sp, "vy": sin(a) * sp, "size": 2 + randf() * 3, "life": 18 + randf() * 22, "max_life": 40, "meteor_particle": true})
