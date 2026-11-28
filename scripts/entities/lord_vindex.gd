extends Node
## Lord Vindex (khusus mode SULIT): gerak, tabrakan, dorongan (dari entities/lord-vindex.js).
## Autoload: LordVindex. Serangan khusus ada di VindexAttacks.


func spawn_lord_vindex() -> void:
	State.lord_vindex = {"x": 389, "y": 45, "w": 42, "h": 42, "phase": 0, "fire": 45, "attack": 0, "flash": 0, "dead": false, "react": 0, "evade_cooldown": 0, "contact_cooldown": 0}
	State.vindex_move_delay = Config.VINDEX_MOVE_DELAY


func update_lord_vindex() -> void:
	if State.level != "hard" or State.lord_vindex == null or State.lord_vindex.dead or State.player == null:
		return
	var l = State.lord_vindex
	var player = State.player
	Items.relocate_collectible_from_enemy(l)
	l.phase += .07
	l.flash = maxf(0, l.flash - 1)
	var dx: float = player.x - l.x
	var dy: float = player.y - l.y
	var dist: float = Vector2(dx, dy).length()
	if dist == 0.0:
		dist = 1.0
	var ang: float = atan2(dy, dx)
	if l.contact_cooldown > 0:
		l.contact_cooldown -= 1
	if State.vindex_time_stop > 0 or State.vindex_laser_countdown > 0 or State.vindex_laser_fire_timer > 0 or State.vindex_barrage != null:
		l.fire = maxf(l.fire, 30)
		l.react = maxf(l.react, 1)
		return
	if State.vindex_move_delay > 0:
		State.vindex_move_delay -= 1
		l.fire = maxf(l.fire, 30)
		l.react = maxf(l.react, 1)
		return
	if State.vindex_time_stop > 0:
		pass # Gerak random Time Stop ditangani VindexAttacks.update_vindex_time_stop().
	elif State.power_active > 0:
		if l.evade_cooldown > 0:
			l.evade_cooldown -= 1
		if dist < Config.ARCHER_POWER_EVADE_DISTANCE and l.evade_cooldown <= 0:
			var safe = null
			for n in range(30):
				var p: Dictionary = Util.random_pos_away_from_player()
				var d: float = Vector2(p.x - l.x, p.y - l.y).length()
				if d >= Config.ARCHER_POWER_TELEPORT_DISTANCE:
					safe = p
					break
			if safe == null:
				safe = Util.random_pos_away_from_player()
			var old_x: float = l.x + l.w / 2.0
			var old_y: float = l.y + l.h / 2.0
			Archers.create_teleport_particles(old_x, old_y, 22)
			l.x = safe.x
			l.y = safe.y
			Archers.create_teleport_particles(l.x + l.w / 2.0, l.y + l.h / 2.0, 22)
			l.evade_cooldown = 12 if State.vindex_time_stop > 0 else 24
			l.flash = 12
			l.react = 36
			l.attack += .3
		else:
			var mult: float = 1.25 if State.vindex_time_stop > 0 else 1.0
			l.x -= cos(ang) * Config.LORD_EVADE_SPEED * mult
			l.y -= sin(ang) * Config.LORD_EVADE_SPEED * mult
			l.react = 24
	else:
		l.x += cos(ang) * Config.LORD_SPEED
		l.y += sin(ang) * Config.LORD_SPEED
	l.x = maxf(35, minf(Config.WIDTH - l.w - 35, l.x))
	l.y = maxf(25, minf(Config.HEIGHT - l.h - 35, l.y))
	l.fire -= 1
	if l.fire <= 0:
		State.archer_arrows.append({"x": l.x + l.w / 2.0, "y": l.y + l.h / 2.0, "w": 11, "h": 11, "vx": cos(ang) * 4.2, "vy": sin(ang) * 4.2, "life": 190, "lord": true})
		l.fire = 145
	l.attack += .045
	l.react = maxf(0, l.react - .5)


func check_lord_collision() -> void:
	if State.level != "hard" or State.lord_vindex == null or State.lord_vindex.dead or State.player == null:
		return
	var lv = State.lord_vindex
	if Util.collide(State.player, lv):
		# Saat bersentuhan, keduanya saling terpental sedikit agar tidak menempel.
		separate_player_and_vindex(9 if lv.contact_cooldown <= 0 else 4)
		lv.contact_cooldown = 8
		lv.react = 28
		if State.power_active > 0 or State.time_stop > 0 or State.vindex_time_stop > 0:
			if State.power_active > 0:
				lv.evade_cooldown = 0
				Archers.create_teleport_particles(lv.x + lv.w / 2.0, lv.y + lv.h / 2.0, 12)
			if State.power_active > 0 and State.time_stop > 0:
				State.story_message = 'LORD VINDEX: "TIME STOP TIDAK BERFUNGSI PADAKU."'
				State.story_message_timer = 95
			return
		if State.hit_cooldown <= 0:
			State.lives = maxi(0, State.lives - 1)
			State.hit_cooldown = 45
			State.global_freeze = 28
			State.screen_shake = 10
			State.story_message = "LORD VINDEX MENYENTUHMU — 1 NYAWA HILANG"
			State.story_message_timer = 90
			if State.lives <= 0:
				State.lives = 0
				State.player_death_max = 100
				State.player_death_timer = 100
				Player.create_player_death_particles()


func push_enemy_by_vindex(enemy, force: float = 42) -> void:
	if enemy == null or enemy.get("dead") == true or enemy.get("disintegrating") == true:
		return
	if enemy.get("vindex_knockback_cooldown") != null and enemy.vindex_knockback_cooldown > 0:
		return
	var lv = State.lord_vindex
	enemy.vindex_knockback_cooldown = 14
	var vx: float = enemy.x + enemy.w / 2.0 - (lv.x + lv.w / 2.0)
	var vy: float = enemy.y + enemy.h / 2.0 - (lv.y + lv.h / 2.0)
	var d: float = Vector2(vx, vy).length()
	var nx: float
	var ny: float
	if d < .001:
		var a: float = randf() * PI * 2
		nx = cos(a)
		ny = sin(a)
		d = 1
	else:
		nx = vx / d
		ny = vy / d
	var old_x: float = enemy.x + enemy.w / 2.0
	var old_y: float = enemy.y + enemy.h / 2.0
	enemy.x += nx * force
	enemy.y += ny * force
	var margin: float = 12 if enemy.w <= 22 else 18
	enemy.x = maxf(margin, minf(Config.WIDTH - enemy.w - margin, enemy.x))
	enemy.y = maxf(70, minf(Config.HEIGHT - enemy.h - margin, enemy.y))
	enemy.hit_flash = 10
	enemy.flash = 10
	enemy.knockback_x = nx * 4
	enemy.knockback_y = ny * 4
	enemy.knockback_timer = 12
	if enemy.has("panic_timer"):
		enemy.panic_timer = 12
	Archers.create_teleport_particles(old_x, old_y, 10)
	Archers.create_teleport_particles(enemy.x + enemy.w / 2.0, enemy.y + enemy.h / 2.0, 10)


func check_vindex_enemy_collisions() -> void:
	if State.level != "hard" or State.lord_vindex == null or State.lord_vindex.dead:
		return
	for k in State.killers:
		if k.loading > 0 or k.disintegrating:
			continue
		if Util.collide(State.lord_vindex, k):
			push_enemy_by_vindex(k, 46)
	for a in State.archers:
		if a.dead:
			continue
		if Util.collide(State.lord_vindex, a):
			push_enemy_by_vindex(a, 46)


func separate_player_and_vindex(push: float = 7) -> void:
	if State.player == null or State.lord_vindex == null:
		return
	var player = State.player
	var lv = State.lord_vindex
	var pcx: float = player.x + player.w / 2.0
	var pcy: float = player.y + player.h / 2.0
	var vcx: float = lv.x + lv.w / 2.0
	var vcy: float = lv.y + lv.h / 2.0
	var dx: float = pcx - vcx
	var dy: float = pcy - vcy
	var dist: float = Vector2(dx, dy).length()
	if dist < 0.001:
		dx = 1
		dy = 0
	else:
		dx /= dist
		dy /= dist
	var player_push: float = push * .58
	var vindex_push: float = push * .42
	player.x += dx * player_push
	player.y += dy * player_push
	lv.x -= dx * vindex_push
	lv.y -= dy * vindex_push
	player.x = maxf(10, minf(Config.WIDTH - player.w - 10, player.x))
	player.y = maxf(70, minf(Config.HEIGHT - player.h - 10, player.y))
	lv.x = maxf(35, minf(Config.WIDTH - lv.w - 35, lv.x))
	lv.y = maxf(25, minf(Config.HEIGHT - lv.h - 35, lv.y))
