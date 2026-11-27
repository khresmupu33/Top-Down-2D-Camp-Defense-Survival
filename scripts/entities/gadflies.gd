extends Node
## Gadfly (4 sisi arena): gerak mengikuti pemain + tabrakan (dari entities/gadflies.js).


func update_gadflies() -> void:
	var sf: float = TimeStop.enemy_slow_factor()
	var player_center_x: float = State.player.x + State.player.w / 2.0
	var player_center_y: float = State.player.y + State.player.h / 2.0
	for g in State.gadflies:
		# ANIMASI TERKENA PLAYER
		if g.hit_anim > 0:
			g.hit_anim -= sf
			g.x += g.hit_vx * sf
			g.y += g.hit_vy * sf
			g.hit_vx *= .90
			g.hit_vy *= .90
			g.rotation += g.rotation_speed * sf
			g.rotation_speed *= .96
			# Setelah animasi kembali ke posisi tepi.
			if g.hit_anim == 0:
				if g.name == "top":
					g.y = 0
				elif g.name == "bottom":
					g.y = Config.HEIGHT - g.h
				elif g.name == "left":
					g.x = 0
				else:
					g.x = Config.WIDTH - g.w
				g.rotation = 0
			continue
		if g.freeze > 0:
			g.freeze -= sf
			continue
		# ATAS / BAWAH: HANYA HORIZONTAL.
		if g.name == "top" or g.name == "bottom":
			Util.move_horizontal(g, player_center_x, 3 * sf)
		# KIRI / KANAN: HANYA VERTIKAL.
		else:
			Util.move_vertical(g, player_center_y, 3 * sf)
		# Menyentuh target.
		if State.target != null and Util.collide(g, State.target):
			Items.spawn_target()
		# Menyentuh health.
		if State.health != null and Util.collide(g, State.health):
			Items.spawn_health()


func check_player_gadflies() -> void:
	for g in State.gadflies:
		if g.hit_anim > 0:
			continue
		if Util.collide(State.player, g):
			if State.score > 0:
				State.score -= 1
			# Tentukan arah Gadfly terpental.
			var gx: float = g.x + g.w / 2.0
			var gy: float = g.y + g.h / 2.0
			var px: float = State.player.x + State.player.w / 2.0
			var py: float = State.player.y + State.player.h / 2.0
			var dx: float = gx - px
			var dy: float = gy - py
			var distance: float = Vector2(dx, dy).length()
			if distance < .01:
				distance = 1
				dx = 1
				dy = 0
			dx /= distance
			dy /= distance
			g.hit_vx = dx * 9
			g.hit_vy = dy * 9
			# Animasi putar.
			g.rotation_speed = .35 if dx > 0 else -.35
			g.hit_anim = Config.GADFLY_HIT_TIME
			g.freeze = 0
