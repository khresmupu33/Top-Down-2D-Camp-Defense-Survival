extends Node
## Archer: bidik, tembak panah, teleport (dari entities/archers.js).


func spawn_archer(x = null, y = null) -> void:
	if State.level == "easy":
		return
	if State.level != "dalang" and State.archers.size() >= Config.MAX_ARCHERS:
		return
	var p: Dictionary = Util.random_pos_away_from_player()
	var a := {
		"x": p.x if x == null else x,
		"y": p.y if y == null else y,
		"w": 22, "h": 22,
		"loading": Config.ARCHER_LOAD_TIME,
		"aim": 0.0,
		"fire": 35,
		"phase": randf() * 6.28,
		"flash": 0,
		"dead": false,
		"evade_cooldown": 0,
		"spawn_anim": 1.0,
		"teleport_anim": 0.0
	}
	State.archers.append(a)


func update_archers() -> void:
	if State.player == null or State.level == "easy":
		return
	var player = State.player
	var slow: float = TimeStop.enemy_slow_factor()
	for i in range(State.archers.size() - 1, -1, -1):
		var a = State.archers[i]
		if a.dead:
			State.archers.remove_at(i)
			continue
		if a.get("vindex_knockback_cooldown", 0) > 0:
			a.vindex_knockback_cooldown -= 1
		Items.relocate_collectible_from_enemy(a)
		if a.get("knockback_timer", 0) > 0:
			a.x += a.knockback_x * slow
			a.y += a.knockback_y * slow
			a.knockback_x *= pow(.91, slow)
			a.knockback_y *= pow(.91, slow)
			a.knockback_timer -= slow
			a.x = maxf(12, minf(Config.WIDTH - a.w - 12, a.x))
			a.y = maxf(70, minf(Config.HEIGHT - a.h - 12, a.y))
		a.phase += .1 * slow
		a.spawn_anim = maxf(0, a.spawn_anim - .045 * slow)
		a.teleport_anim = maxf(0, a.teleport_anim - .08 * slow)
		a.flash = maxf(0, a.flash - 1 * slow)
		a.aim = Util.angle_to(a, player)
		if a.evade_cooldown > 0:
			a.evade_cooldown -= slow
		if a.loading > 0:
			a.loading -= slow
			continue
		var dx: float = player.x - a.x
		var dy: float = player.y - a.y
		var dist: float = Vector2(dx, dy).length()
		if dist == 0.0:
			dist = 1.0
		# Power Kill membuat Archer panik dan berpindah INSTAN.
		# Ia tidak lari sedikit demi sedikit, sehingga player tidak
		# bisa sekadar mengejar dan menyentuhnya.
		# Jika player sudah benar-benar menyentuh Archer pada frame
		# sebelum teleport, collision tetap bisa membunuhnya.
		if State.power_active > 0 and dist < Config.ARCHER_POWER_EVADE_DISTANCE and a.evade_cooldown <= 0:
			var safe = null
			for n in range(30):
				var p: Dictionary = Util.random_pos_away_from_player()
				var d: float = Vector2(p.x - a.x, p.y - a.y).length()
				if d >= Config.ARCHER_POWER_TELEPORT_DISTANCE:
					safe = p
					break
			if safe == null:
				safe = Util.random_pos_away_from_player()
			var old_x: float = a.x + a.w / 2.0
			var old_y: float = a.y + a.h / 2.0
			create_teleport_particles(old_x, old_y, 18)
			a.x = safe.x
			a.y = safe.y
			create_teleport_particles(a.x + a.w / 2.0, a.y + a.h / 2.0, 18)
			a.evade_cooldown = 28
			a.flash = 10
			a.teleport_anim = 1.0
			a.aim = Util.angle_to(a, player)
		elif State.power_active <= 0:
			# Di luar Power Kill, Archer menjaga jarak dan tidak mengejar cepat.
			var desired := 250.0
			if dist > desired:
				a.x += (dx / dist) * Config.ARCHER_SPEED * .28 * slow
				a.y += (dy / dist) * Config.ARCHER_SPEED * .28 * slow
			elif dist < 170:
				a.x -= (dx / dist) * Config.ARCHER_SPEED * .18 * slow
				a.y -= (dy / dist) * Config.ARCHER_SPEED * .18 * slow
		a.x = maxf(12, minf(Config.WIDTH - a.w - 12, a.x))
		a.y = maxf(70, minf(Config.HEIGHT - a.h - 12, a.y))
		a.fire -= slow
		if a.fire <= 0:
			var ang: float = a.aim
			State.archer_arrows.append({
				"x": a.x + a.w / 2.0, "y": a.y + a.h / 2.0, "w": 8, "h": 8,
				"vx": cos(ang) * Config.ARCHER_ARROW_SPEED,
				"vy": sin(ang) * Config.ARCHER_ARROW_SPEED,
				"life": 180
			})
			a.fire = Config.ARCHER_FIRE_INTERVAL + Util.random_int(-25, 30)
	# Panah juga terkena efek Time Stop, tetapi tidak terkena slow dua kali.
	var arrow_slow: float = TimeStop.enemy_slow_factor()
	for i in range(State.archer_arrows.size() - 1, -1, -1):
		var q = State.archer_arrows[i]
		q.x += q.vx * arrow_slow
		q.y += q.vy * arrow_slow
		q.life -= arrow_slow
		if q.life <= 0 or q.x < -20 or q.x > Config.WIDTH + 20 or q.y < -20 or q.y > Config.HEIGHT + 20:
			State.archer_arrows.remove_at(i)
			continue


func check_archer_collisions() -> void:
	if State.level == "easy" or State.player == null:
		return
	for a in State.archers:
		if a.dead:
			continue
		if Util.collide(State.player, a):
			if State.power_active > 0 or State.time_stop > 0:
				a.dead = true
				Killers.create_disintegration_particles(a)
				State.screen_shake = 8
				continue
			if State.hit_cooldown <= 0:
				State.lives -= 1
				State.hit_cooldown = Config.ARCHER_ARROW_DAMAGE_COOLDOWN
				State.global_freeze = 20
				State.screen_shake = 8
				if State.lives <= 0:
					State.lives = 0
					State.player_death_max = 100
					State.player_death_timer = 100
					Player.create_player_death_particles()
					return
	if State.time_stop > 0:
		return
	if State.hit_cooldown > 0:
		return
	for i in range(State.archer_arrows.size() - 1, -1, -1):
		if Util.collide(State.player, State.archer_arrows[i]):
			State.lives -= 1
			State.hit_cooldown = Config.ARCHER_ARROW_DAMAGE_COOLDOWN
			State.screen_shake = 9
			State.archer_arrows.remove_at(i)
			if State.lives <= 0:
				State.lives = 0
				State.player_death_max = 100
				State.player_death_timer = 100
				Player.create_player_death_particles()
				return


func create_teleport_particles(x: float, y: float, amount: int = 14) -> void:
	for i in range(amount):
		var a: float = randf() * PI * 2
		var speed: int = Util.random_int(2, 6)
		State.particle_list.append({"x": x, "y": y, "vx": cos(a) * speed, "vy": sin(a) * speed, "size": Util.random_int(2, 4), "life": Util.random_int(18, 32), "max_life": 32})
