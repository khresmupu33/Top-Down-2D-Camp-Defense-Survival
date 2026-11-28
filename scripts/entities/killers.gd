extends Node
## Killer: spawn, AI mengejar, tabrakan, kehancuran (dari entities/killers.js).
## Sentuhan DOM/sprite dibuang: karakter digambar dari state oleh Sprites.

var _warning_token: int = 0


func get_killer_speed() -> float:
	if State.level == "easy":
		return 2 * TimeStop.enemy_slow_factor()
	if State.level == "normal":
		return 2.5 * TimeStop.enemy_slow_factor()
	return 2.5 * TimeStop.enemy_slow_factor()


func add_killer(first: bool = false) -> void:
	var p: Dictionary = Util.random_pos_away_from_player()
	var killer := {
		"x": p.x,
		"y": p.y,
		"w": 20,
		"h": 20,
		"loading": 90 if first else Config.KILLER_LOAD_TIME,
		"pulse": randf() * PI * 2,
		"knockback_x": 0.0,
		"knockback_y": 0.0,
		"knockback_timer": 0,
		"elbow_cooldown": 0,
		"tilt": 0.0,
		"target_tilt": 0.0,
		"scale_x": 1.0,
		"scale_y": 1.0,
		"hit_flash": 0,
		"disappointed": 0,
		"celebrating": 0,
		"celebrating_phase": 0.0,
		"panic": false,
		"panic_phase": randf() * PI * 2,
		"panic_timer": 0.0,
		"disappointed_phase": randf() * PI * 2,
		"disintegrating": false,
		"disintegrate_timer": 0,
		"phase": randf() * PI * 2
	}
	State.killers.append(killer)
	show_spawn_warning()


func show_spawn_warning() -> void:
	var warning = GameUI.node("spawnWarning")
	if warning == null:
		return
	warning.visible = true
	_warning_token += 1
	var token: int = _warning_token
	Util.after_ms(900, func():
		if token == _warning_token:
			var w = GameUI.node("spawnWarning")
			if w != null:
				w.visible = false
	)


func update_killers() -> void:
	var sf: float = TimeStop.world_slow_factor()
	var speed: float = get_killer_speed()
	var player = State.player
	var idx := 0
	while idx < State.killers.size():
		var k = State.killers[idx]
		idx += 1
		if k.get("vindex_knockback_cooldown", 0) > 0:
			k.vindex_knockback_cooldown -= sf
		if k.loading <= 0 and not k.disintegrating:
			Items.relocate_collectible_from_enemy(k)
		# Jika sedang bersurai.
		if k.disintegrating:
			update_disintegrating_killer(k)
			continue
		# Cooldown.
		if k.elbow_cooldown > 0:
			k.elbow_cooldown -= sf
		if k.hit_flash > 0:
			k.hit_flash -= sf
		k.pulse += .13 * sf
		# Merayakan setelah mengenai player.
		if k.celebrating > 0:
			k.celebrating -= sf
			k.celebrating_phase += .28 * sf
			k.target_tilt = sin(k.celebrating_phase) * .28
			k.scale_x = 1 + sin(k.celebrating_phase * 2) * .12
			k.scale_y = 1 - sin(k.celebrating_phase * 2) * .08
			continue
		# Kecewa.
		if k.disappointed > 0:
			k.disappointed -= sf
			k.disappointed_phase += .15 * sf
			# Masih diam selama freeze global.
			continue
		# Global freeze.
		if State.global_freeze > 0:
			continue
		# POWER KILL:
		# Killer panik dan menjauh dari icon Power Kill.
		# Setelah icon diambil, mereka menjauh dari player.
		# Kecepatan tetap sama dengan kecepatan normal.
		if State.power_active > 0 and k.loading <= 0:
			var danger_x: float = player.x + player.w / 2.0
			var danger_y: float = player.y + player.h / 2.0
			var kx: float = k.x + k.w / 2.0
			var ky: float = k.y + k.h / 2.0
			var dx: float = kx - danger_x
			var dy: float = ky - danger_y
			var dist: float = Vector2(dx, dy).length()
			if dist < .001:
				dx = -1.0 if k.x < Config.WIDTH / 2.0 else 1.0
				dy = -1.0 if k.y < Config.HEIGHT / 2.0 else 1.0
				dist = Vector2(dx, dy).length()
			# Steering ala NPC:
			# jangan hanya bergerak lurus menjauh, tetapi juga
			# membaca dinding/pojok agar bisa membelok sebelum mentok.
			var flee_x: float = dx / dist
			var flee_y: float = dy / dist
			var margin: float = Config.POWER_SAFE_MARGIN
			var cx: float = k.x + k.w / 2.0
			var cy: float = k.y + k.h / 2.0
			var left_gap: float = cx - margin
			var right_gap: float = Config.WIDTH - margin - cx
			var top_gap: float = cy - margin
			var bottom_gap: float = Config.HEIGHT - margin - cy
			var wall_range := 95.0
			# Dorongan menjauh dari dinding. Makin dekat dinding,
			# makin kuat dorongannya sehingga NPC berbelok.
			if left_gap < wall_range:
				flee_x += (1 - left_gap / wall_range) * 1.8
			if right_gap < wall_range:
				flee_x -= (1 - right_gap / wall_range) * 1.8
			if top_gap < wall_range:
				flee_y += (1 - top_gap / wall_range) * 1.8
			if bottom_gap < wall_range:
				flee_y -= (1 - bottom_gap / wall_range) * 1.8
			# Kalau sudah sangat dekat sudut, prioritaskan keluar dari
			# sudut dengan gerakan menyamping, bukan terus menabrak.
			var corner_x: float = minf(left_gap, right_gap)
			var corner_y: float = minf(top_gap, bottom_gap)
			if corner_x < 42 and corner_y < 42:
				if left_gap < right_gap:
					flee_x = absf(flee_x) + .9
				else:
					flee_x = -absf(flee_x) - .9
				if top_gap < bottom_gap:
					flee_y = absf(flee_y) + .9
				else:
					flee_y = -absf(flee_y) - .9
			var steer_dist: float = Vector2(flee_x, flee_y).length()
			if steer_dist == 0.0:
				steer_dist = 1.0
			flee_x /= steer_dist
			flee_y /= steer_dist
			var flee_speed: float = speed * Config.POWER_FLEE_SPEED_MULTIPLIER
			k.x += flee_x * flee_speed * sf
			k.y += flee_y * flee_speed * sf
			k.x = maxf(margin, minf(Config.WIDTH - k.w - margin, k.x))
			k.y = maxf(margin, minf(Config.HEIGHT - k.h - margin, k.y))
			# Sedikit belokan visual mengikuti arah gerak.
			k.target_tilt = maxf(-.28, minf(.28, flee_x * .18))
			k.panic_phase += .55 * sf
			k.panic_timer = maxf(k.panic_timer, 3 * sf)
			k.target_tilt = sin(k.panic_phase * 1.7) * .22
			k.scale_x = .78 + sin(k.panic_phase * 2.1) * .06
			k.scale_y = 1.16 + absf(sin(k.panic_phase * 2.1)) * .08
			k.panic = true
			continue
		k.panic = false
		# Loading spawn.
		if k.loading > 0:
			k.loading -= sf
			k.target_tilt *= .9
			k.tilt += (k.target_tilt - k.tilt) * .2
			continue
		# Knockback.
		if k.knockback_timer > 0:
			k.x += k.knockback_x
			k.y += k.knockback_y
			k.knockback_x *= pow(.91, sf)
			k.knockback_y *= pow(.91, sf)
			k.knockback_timer -= sf
			# Tetap mengejar.
			Util.move_towards(k, player, speed * .4 * sf)
		else:
			Util.move_towards(k, player, speed * sf)
		# Animasi badan kembali.
		k.target_tilt *= pow(.80, sf)
		k.tilt += (k.target_tilt - k.tilt) * .17
		k.scale_x += (1 - k.scale_x) * .14
		k.scale_y += (1 - k.scale_y) * .14
		Util.wrap_obj(k)
		# Killer mengenai item.
		if State.target != null and Util.collide(k, State.target):
			Items.spawn_target()
		if State.health != null and State.health.visible and Util.collide(k, State.health):
			Items.spawn_health()


func update_killer_collisions() -> void:
	var killers: Array = State.killers
	for i in range(killers.size()):
		for j in range(i + 1, killers.size()):
			var k1 = killers[i]
			var k2 = killers[j]
			if k1.disintegrating or k2.disintegrating:
				continue
			if k1.loading > 0 or k2.loading > 0:
				continue
			if k1.elbow_cooldown > 0 or k2.elbow_cooldown > 0:
				continue
			if not Util.collide(k1, k2):
				continue
			var dx: float = (k2.x + k2.w / 2.0) - (k1.x + k1.w / 2.0)
			var dy: float = (k2.y + k2.h / 2.0) - (k1.y + k1.h / 2.0)
			var distance: float = Vector2(dx, dy).length()
			if distance < .01:
				var angle: float = randf() * PI * 2
				dx = cos(angle)
				dy = sin(angle)
				distance = 1
			dx /= distance
			dy /= distance
			# SIKUTAN SANGAT JAUH.
			# 11 px/frame selama 35 frame lalu melambat.
			k2.knockback_x = dx * Config.KILLER_KNOCKBACK_POWER
			k2.knockback_y = dy * Config.KILLER_KNOCKBACK_POWER
			k2.knockback_timer = Config.KILLER_KNOCKBACK_TIME
			# Gerakan miring.
			k2.target_tilt = atan2(dy, dx) * .55
			k2.scale_x = 1.35
			k2.scale_y = .68
			k2.hit_flash = 8
			# Cooldown.
			k1.elbow_cooldown = Config.KILLER_COLLISION_COOLDOWN
			k2.elbow_cooldown = Config.KILLER_COLLISION_COOLDOWN
			# Pisahkan.
			k2.x += dx * 5
			k2.y += dy * 5
			k1.x -= dx * 1.5
			k1.y -= dy * 1.5


func check_player_killers() -> void:
	var player = State.player
	if State.power_active > 0:
		for i in range(State.killers.size()):
			var k = State.killers[i]
			if k.loading > 0 or k.disintegrating:
				continue
			if Util.collide(player, k):
				k.disintegrating = true
				k.disintegrate_timer = 32
				create_disintegration_particles(k)
				k.hit_flash = 12
				State.screen_shake = 9
		return
	if State.hit_cooldown > 0:
		State.hit_cooldown -= 1
		return
	for i in range(State.killers.size()):
		var k = State.killers[i]
		if k.loading > 0 or k.disintegrating:
			continue
		if Util.collide(player, k):
			State.lives -= 1
			State.hit_cooldown = 30
			State.global_freeze = Config.GLOBAL_KILLER_FREEZE
			# Killer yang menyerang MERAYAKAN.
			k.celebrating = Config.GLOBAL_KILLER_FREEZE + 20
			GameAudio.play("killer_laugh")
			k.celebrating_phase = 0.0
			k.target_tilt = 0.0
			k.scale_x = 1.12
			k.scale_y = .90
			# Killer lain kecewa dengan timing yang sama.
			for other in State.killers:
				if other != k and not other.disintegrating:
					other.disappointed = Config.GLOBAL_KILLER_FREEZE + 20
					other.target_tilt = .35
					other.scale_x = .85
					other.scale_y = 1.15
			State.screen_shake = 12
			if State.lives <= 0:
				State.lives = 0
				State.player_death_max = 100
				State.player_death_timer = State.player_death_max
				State.global_freeze = State.player_death_max
				State.hit_cooldown = State.player_death_max
				Player.create_player_death_particles()
				State.screen_shake = 18
				return
			break


func update_disintegrating_killer(k: Dictionary) -> void:
	if k.disintegrate_timer > 0:
		k.disintegrate_timer -= 1
	if k.disintegrate_timer == 0:
		# Pencarian berdasarkan identitas objek (indexOf di JS).
		for i in range(State.killers.size()):
			if is_same(State.killers[i], k):
				State.killers.remove_at(i)
				break


func create_disintegration_particles(k: Dictionary) -> void:
	var cx: float = k.x + k.w / 2.0
	var cy: float = k.y + k.h / 2.0
	for i in range(18):
		var angle: float = randf() * PI * 2
		var speed: int = Util.random_int(2, 7)
		State.particle_list.append({
			"x": cx,
			"y": cy,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"size": Util.random_int(2, 5),
			"life": Util.random_int(25, 50),
			"max_life": 50
		})


func update_global_freeze() -> void:
	if State.meteor_shockwave != null and State.meteor_shockwave.life > 0:
		State.meteor_shockwave.life -= 1
	elif State.meteor_shockwave != null:
		State.meteor_shockwave = null
	if State.player_shock_timer > 0:
		State.player_shock_timer -= 1
		State.player_shock_x *= .9
		State.player_shock_y *= .9
	if State.global_freeze > 0:
		State.global_freeze -= 1
	if State.screen_shake > 0:
		State.screen_shake -= 1
