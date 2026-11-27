extends Node
## Serangan Lord Vindex: Time Stop, laser terkunci, serangan kekuatan
## (Rentetan Laser & Pusaran Ungu). Port dari modes/hard/vindex-attacks.js.
## Dibaca oleh Effects: State.vindex_barrage {phase, t, round, beams:[{angle}], origin_x, origin_y, hit}
## dan State.vindex_vortex {x, y, age, exploded}.


func lock_vindex_laser_target() -> void:
	if State.player == null or State.lord_vindex == null:
		return
	var lv: Dictionary = State.lord_vindex
	var p: Dictionary = State.player
	var sx: float = lv.x + lv.w / 2.0
	var sy: float = lv.y + lv.h / 2.0
	var px: float = p.x + p.w / 2.0
	var py: float = p.y + p.h / 2.0
	var ang: float = atan2(py - sy, px - sx)
	State.vindex_laser_angle = ang
	# Jangan jadikan posisi player sebagai ujung laser.
	# Laser harus berupa jalur panjang dari Vindex sampai keluar arena,
	# sehingga player yang berada di jalurnya benar-benar terkena.
	var dx: float = cos(ang)
	var dy: float = sin(ang)
	var distances: Array = []
	if absf(dx) > 0.0001:
		distances.append((0.0 - sx) / dx)
		distances.append((Config.WIDTH - sx) / dx)
	if absf(dy) > 0.0001:
		distances.append((0.0 - sy) / dy)
		distances.append((Config.HEIGHT - sy) / dy)
	var far: float = Vector2(Config.WIDTH, Config.HEIGHT).length() * 1.5
	for d in distances:
		if d > 0.0 and is_finite(d):
			far = maxf(far, d)
	State.vindex_laser_x = sx + dx * (far + 40.0)
	State.vindex_laser_y = sy + dy * (far + 40.0)


func set_vindex_time_stop_escape_target() -> void:
	if State.lord_vindex == null or State.player == null:
		return
	var p: Dictionary = State.player
	var px: float = p.x + p.w / 2.0
	var py: float = p.y + p.h / 2.0
	var corners: Array = [Vector2(90, 75), Vector2(Config.WIDTH - 90, 75), Vector2(90, Config.HEIGHT - 75), Vector2(Config.WIDTH - 90, Config.HEIGHT - 75)]
	var best: Vector2 = corners[0]
	var best_d: float = -1.0
	for c in corners:
		var d: float = Vector2(c.x - px, c.y - py).length()
		if d > best_d:
			best_d = d
			best = c
	State.vindex_time_stop_move_x = best.x
	State.vindex_time_stop_move_y = best.y
	State.vindex_time_stop_move_timer = 300


func trigger_vindex_time_stop() -> void:
	var lv = State.lord_vindex
	if State.level != "hard" or lv == null or lv.dead or State.player == null or State.vindex_time_stop > 0 or State.vindex_laser_countdown > 0 or State.score < 25 or not State.hard25_completed or State.hard25_sequence_active or vindex_special_busy():
		return
	var dx: float = State.player.x - lv.x
	var dy: float = State.player.y - lv.y
	var dist: float = Vector2(dx, dy).length()
	if dist == 0.0:
		dist = 1.0
	if dist < 190.0 or dist > 520.0:
		return
	# TIME STOP terlebih dahulu. Laser BELUM menyerang.
	State.vindex_time_stop = 300
	State.vindex_time_stop_cooldown = Util.random_int(2100, 3000)
	State.vindex_laser_active = true
	State.vindex_laser_countdown = 0
	State.vindex_laser_pulse = 0
	# Wave dikunci di titik Vindex saat Time Stop DIAKTIFKAN.
	State.time_stop_origin_x = lv.x + lv.w / 2.0
	State.time_stop_origin_y = lv.y + lv.h / 2.0
	# Saat Time Stop dimulai, tentukan pojok terjauh. Vindex bergerak ke sana, TANPA teleport.
	set_vindex_time_stop_escape_target()
	# Daerah target mulai mengejar player PERSIS saat Time Stop dimulai.
	lock_vindex_laser_target()
	lv.react = 40
	State.story_message = 'LORD VINDEX: "TIME STOP. SEMUANYA MELAMBAT... KECUALI AKU."'
	State.story_message_timer = 190
	State.screen_shake = 8


func vindex_laser_hits_player() -> bool:
	if State.player == null or State.lord_vindex == null:
		return false
	var p: Dictionary = State.player
	var sx: float = State.vindex_laser_origin_x
	var sy: float = State.vindex_laser_origin_y
	var ex: float = State.vindex_laser_x
	var ey: float = State.vindex_laser_y
	var px: float = p.x + p.w / 2.0
	var py: float = p.y + p.h / 2.0
	var vx: float = ex - sx
	var vy: float = ey - sy
	var len2: float = vx * vx + vy * vy
	if len2 == 0.0:
		len2 = 1.0
	# Laser dimulai dari Vindex dan membentang jauh melewati arena.
	var t: float = ((px - sx) * vx + (py - sy) * vy) / len2
	if t < 0.0:
		return false
	var qx: float = sx + vx * t
	var qy: float = sy + vy * t
	return Vector2(px - qx, py - qy).length() <= Config.VINDEX_POWER_BEAM_WIDTH / 2.0 + maxf(p.w, p.h) * 0.35


func vindex_laser_hits_rect(entity) -> bool:
	if entity == null:
		return false
	var sx: float = State.vindex_laser_origin_x
	var sy: float = State.vindex_laser_origin_y
	var ex: float = State.vindex_laser_x
	var ey: float = State.vindex_laser_y
	var cx: float = entity.x + entity.w / 2.0
	var cy: float = entity.y + entity.h / 2.0
	var vx: float = ex - sx
	var vy: float = ey - sy
	var len2: float = vx * vx + vy * vy
	if len2 == 0.0:
		len2 = 1.0
	var t: float = maxf(0.0, minf(1.0, ((cx - sx) * vx + (cy - sy) * vy) / len2))
	var qx: float = sx + vx * t
	var qy: float = sy + vy * t
	var radius: float = Config.VINDEX_POWER_BEAM_WIDTH / 2.0 + Vector2(entity.w, entity.h).length() * 0.42
	return Vector2(cx - qx, cy - qy).length() <= radius


func destroy_enemy_by_vindex_laser(enemy) -> void:
	if enemy == null:
		return
	if enemy.get("disintegrating", false) or enemy.get("dead", false):
		return
	enemy.disintegrating = true
	enemy.disintegrate_timer = 38
	enemy.hit_flash = 18
	enemy.panic = false
	Killers.create_disintegration_particles(enemy)


func kill_enemies_by_vindex_laser() -> void:
	if State.lord_vindex == null:
		return
	for k in State.killers:
		if k != null and k.loading <= 0 and not k.disintegrating and vindex_laser_hits_rect(k):
			destroy_enemy_by_vindex_laser(k)
	for a in State.archers:
		if a != null and not a.dead and vindex_laser_hits_rect(a):
			a.dead = true
			Killers.create_disintegration_particles(a)


func update_vindex_time_stop() -> void:
	if State.level != "hard":
		return
	var lv = State.lord_vindex
	# =========================
	# 1. TIME STOP
	# Mekanik Time Stop tetap seperti sebelumnya.
	# Vindex bergerak sendiri, bukan mengejar player.
	# =========================
	if State.vindex_time_stop > 0:
		State.vindex_time_stop -= 1
		State.vindex_laser_pulse += 0.18
		if lv != null and State.vindex_time_stop_move_timer > 0:
			State.vindex_time_stop_move_timer -= 1
		if lv != null:
			var tx: float = State.vindex_time_stop_move_x - (lv.x + lv.w / 2.0)
			var ty: float = State.vindex_time_stop_move_y - (lv.y + lv.h / 2.0)
			var td: float = Vector2(tx, ty).length()
			if td == 0.0:
				td = 1.0
			lv.x += tx / td * Config.LORD_EVADE_SPEED * 1.15
			lv.y += ty / td * Config.LORD_EVADE_SPEED * 1.15
			lv.x = maxf(35.0, minf(Config.WIDTH - lv.w - 35.0, lv.x))
			lv.y = maxf(25.0, minf(Config.HEIGHT - lv.h - 35.0, lv.y))
		# Daerah target benar-benar mengikuti arah player selama Time Stop.
		lock_vindex_laser_target()
		if State.vindex_time_stop <= 0:
			# Time Stop selesai: target sudah mendapat arah player terakhir, lalu DIKUNCI.
			lock_vindex_laser_target()
			State.vindex_laser_countdown = 60
			# Selama countdown Vindex TIDAK bergerak.
			State.vindex_laser_fire_timer = 0
			State.vindex_laser_has_hit = false
			State.story_message = 'LORD VINDEX: "TARGET TERKUNCI. SATU DETIK SEBELUM LASER..."'
			State.story_message_timer = 100
		return
	# =========================
	# 2. INDIKATOR / TARGETING
	# Hanya garis/daerah peringatan yang mengikuti player.
	# Laser BELUM ditembakkan.
	# =========================
	if State.vindex_laser_countdown > 0:
		# 1 detik terakhir: daerah target sudah TERKUNCI, tidak mengejar player.
		State.vindex_laser_countdown -= 1
		State.vindex_laser_pulse += 0.32
		if State.vindex_laser_countdown <= 0 and State.player != null and lv != null and State.lives > 0:
			# DETIK TEMBAK: simpan posisi Vindex + arah + ujung laser (tanpa relock lagi).
			State.vindex_laser_origin_x = lv.x + lv.w / 2.0
			State.vindex_laser_origin_y = lv.y + lv.h / 2.0
			State.vindex_laser_fire_timer = 42
			State.vindex_laser_has_hit = false
			State.vindex_laser_active = true
			# Damage hanya dihitung sekali ketika laser benar-benar menembak.
			kill_enemies_by_vindex_laser()
			if vindex_laser_hits_player():
				State.vindex_laser_has_hit = true
				State.lives = maxi(0, State.lives - Config.VINDEX_POWER_DAMAGE)
				State.hit_cooldown = 50
				State.screen_shake = 16
				State.story_message = "⚡ LASER VINDEX — 2 NYAWA HILANG"
				State.story_message_timer = 130
				Meteors.create_meteor_impact_particles(State.vindex_laser_x, State.vindex_laser_y)
				if State.lives <= 0:
					State.lives = 0
					State.player_death_max = 100
					State.player_death_timer = 100
					Player.create_player_death_particles()
			else:
				State.story_message = "⚡ LASER VINDEX — MENGHANCURKAN AREA"
				State.story_message_timer = 90
		return
	# =========================
	# 3. LASER SEDANG MENEMBAK
	# Arah dan posisi TETAP. Tidak mengejar player.
	# =========================
	if State.vindex_laser_fire_timer > 0:
		State.vindex_laser_fire_timer -= 1
		State.vindex_laser_pulse += 0.48
		if State.vindex_laser_fire_timer <= 0:
			State.vindex_laser_active = false
			State.vindex_laser_has_hit = false
			State.vindex_move_delay = 0
		return
	# =========================
	# 4. COOLDOWN
	# =========================
	if State.vindex_time_stop_cooldown > 0:
		State.vindex_time_stop_cooldown -= 1
	if State.vindex_time_stop_cooldown <= 0:
		trigger_vindex_time_stop()


# =====================================================================
# TANTANGAN KHUSUS VINDEX (setelah poin 25)
# - Rentetan Laser (poin > 50)  : Vindex ke tengah arena, 3 gelombang x 3 laser
# - Pusaran Ungu   (poin >= 75) : lubang hisap 4 detik lalu meledak
# Ketiganya (plus Time Stop Vindex) TIDAK PERNAH berjalan bersamaan.
# =====================================================================

## True bila ada tantangan Vindex yang sedang berjalan (selain Time Stop biasa).
func vindex_special_busy() -> bool:
	return State.vindex_barrage != null or State.vindex_vortex != null


func vindex_anything_busy() -> bool:
	return vindex_special_busy() or State.vindex_time_stop > 0 or State.vindex_laser_countdown > 0 or State.vindex_laser_fire_timer > 0


## Titik (x,y) berada di zona berbahaya yang tidak boleh ditempati item/spawn?
func in_vindex_hazard_zone(x: float, y: float) -> bool:
	if State.vindex_barrage != null and Vector2(x - Config.WIDTH / 2.0, y - Config.HEIGHT / 2.0).length() < Config.VINDEX_BARRAGE_SAFE_RADIUS:
		return true
	var v = State.vindex_vortex
	if v != null and Vector2(x - v.x, y - v.y).length() < Config.VORTEX_SAFE_RADIUS:
		return true
	return false


## Pindahkan item yang terlanjur berada di zona berbahaya.
func move_collectibles_out_of_vindex_zones() -> void:
	for item in [State.target, State.health, State.powerup, State.time_stop_powerup]:
		if item == null or item.get("visible", true) == false:
			continue
		if in_vindex_hazard_zone(item.x + item.w / 2.0, item.y + item.h / 2.0):
			var p: Dictionary = Util.random_pos_away_from_player()
			item.x = p.x
			item.y = p.y
			item.pulse = 0


func vindex_damage_player(amount: int, cause: String, message: String, shake: int = 16) -> void:
	if State.player == null or State.lives <= 0 or State.player_death_timer > 0:
		return
	State.lives = maxi(0, State.lives - amount)
	State.hit_cooldown = 50
	State.screen_shake = shake
	State.story_message = message
	State.story_message_timer = 130
	if State.lives <= 0:
		State.hard_death_cause = cause
		State.player_death_max = 100
		State.player_death_timer = 100
		Player.create_player_death_particles()


func update_vindex_specials() -> void:
	var lv = State.lord_vindex
	if State.level != "hard" or lv == null or lv.dead or State.player == null or State.game_state != "playing":
		return
	if State.hard25_sequence_active or not State.hard25_completed or State.player_death_timer > 0:
		return
	if State.vindex_barrage != null:
		update_vindex_barrage()
	if State.vindex_vortex != null:
		update_vindex_vortex()
	if vindex_special_busy():
		move_collectibles_out_of_vindex_zones()
		return
	if State.vindex_barrage_cooldown > 0:
		State.vindex_barrage_cooldown -= 1
	if State.vindex_vortex_cooldown > 0:
		State.vindex_vortex_cooldown -= 1
	if vindex_anything_busy():
		return
	if State.score >= Config.VORTEX_MIN_SCORE and State.vindex_vortex_cooldown <= 0:
		start_vindex_vortex()
	elif State.score >= Config.VINDEX_BARRAGE_MIN_SCORE and State.vindex_barrage_cooldown <= 0:
		start_vindex_barrage()


# ─────────────── RENTETAN LASER ───────────────

func start_vindex_barrage() -> void:
	State.vindex_barrage = {"phase": "gather", "t": 0, "round": 0, "beams": [], "origin_x": Config.WIDTH / 2.0, "origin_y": Config.HEIGHT / 2.0, "hit": false}
	State.vindex_barrage_cooldown = Util.random_int(Config.VINDEX_BARRAGE_COOLDOWN_MIN, Config.VINDEX_BARRAGE_COOLDOWN_MAX)
	State.lord_vindex.react = 60
	State.screen_shake = 6
	State.story_message = 'LORD VINDEX: "Berdirilah jauh dariku. Kali ini aku tidak membidikmu."'
	State.story_message_timer = 170


func _angle_diff(a: float, b: float) -> float:
	return absf(atan2(sin(a - b), cos(a - b)))


## Pilih sudut laser: saling berjauhan dan TIDAK langsung mengarah ke pemain.
func pick_barrage_angles() -> Array:
	var p: Dictionary = State.player
	var cx: float = Config.WIDTH / 2.0
	var cy: float = Config.HEIGHT / 2.0
	var to_player: float = atan2(p.y + p.h / 2.0 - cy, p.x + p.w / 2.0 - cx)
	var angles: Array = []
	var tries := 0
	while tries < 300 and angles.size() < Config.VINDEX_BARRAGE_BEAMS:
		tries += 1
		var a: float = randf() * PI * 2.0
		if _angle_diff(a, to_player) < Config.VINDEX_BARRAGE_MIN_FROM_PLAYER:
			continue
		var ok := true
		for o in angles:
			if _angle_diff(a, o) < Config.VINDEX_BARRAGE_MIN_SPREAD:
				ok = false
				break
		if ok:
			angles.append(a)
	# cadangan deterministik bila undian gagal (sangat jarang)
	var k := 0
	while angles.size() < Config.VINDEX_BARRAGE_BEAMS and k < 12:
		var a: float = to_player + Config.VINDEX_BARRAGE_MIN_FROM_PLAYER + 0.05 + k * (PI * 2.0 / 12.0)
		var ok2 := _angle_diff(a, to_player) >= Config.VINDEX_BARRAGE_MIN_FROM_PLAYER
		if ok2:
			for o in angles:
				if _angle_diff(a, o) < Config.VINDEX_BARRAGE_MIN_SPREAD:
					ok2 = false
					break
		if ok2:
			angles.append(a)
		k += 1
	return angles


func barrage_beam_hits(angle: float, ent) -> bool:
	var b: Dictionary = State.vindex_barrage
	var sx: float = b.origin_x
	var sy: float = b.origin_y
	var cx: float = ent.x + ent.w / 2.0
	var cy: float = ent.y + ent.h / 2.0
	var dx: float = cos(angle)
	var dy: float = sin(angle)
	var along: float = (cx - sx) * dx + (cy - sy) * dy
	if along < 0.0:
		return false
	var perp: float = absf((cx - sx) * dy - (cy - sy) * dx)
	return perp <= Config.VINDEX_BARRAGE_WIDTH / 2.0 + Vector2(ent.w, ent.h).length() * 0.38


func update_vindex_barrage() -> void:
	var b: Dictionary = State.vindex_barrage
	var l: Dictionary = State.lord_vindex
	b.t += 1
	l.fire = maxi(l.fire, 30)
	l.react = maxi(l.react, 1)
	if b.phase == "gather":
		# Vindex berjalan ke tengah arena dan berhenti di sana.
		var tx: float = Config.WIDTH / 2.0 - (l.x + l.w / 2.0)
		var ty: float = Config.HEIGHT / 2.0 - (l.y + l.h / 2.0)
		var td: float = Vector2(tx, ty).length()
		if td > 6.0:
			var sp: float = minf(td, Config.LORD_EVADE_SPEED * 1.2)
			l.x += tx / td * sp
			l.y += ty / td * sp
		if td <= 6.0 or b.t >= Config.VINDEX_BARRAGE_GATHER:
			l.x = Config.WIDTH / 2.0 - l.w / 2.0
			l.y = Config.HEIGHT / 2.0 - l.h / 2.0
			start_barrage_round(b)
		return
	if b.phase == "warn":
		if b.t >= Config.VINDEX_BARRAGE_WARN:
			fire_barrage_round(b)
		return
	if b.phase == "fire":
		if b.t >= Config.VINDEX_BARRAGE_FIRE:
			b["round"] += 1
			if b["round"] >= Config.VINDEX_BARRAGE_ROUNDS:
				State.vindex_barrage = null
				State.vindex_move_delay = 60
				State.story_message = 'LORD VINDEX: "Cukup. Untuk sekarang."'
				State.story_message_timer = 110
				return
			b.phase = "gap"
			b.t = 0
		return
	if b.phase == "gap" and b.t >= Config.VINDEX_BARRAGE_GAP:
		start_barrage_round(b)


func start_barrage_round(b: Dictionary) -> void:
	b.phase = "warn"
	b.t = 0
	b.hit = false
	b.origin_x = Config.WIDTH / 2.0
	b.origin_y = Config.HEIGHT / 2.0
	var beams: Array = []
	for a in pick_barrage_angles():
		beams.append({"angle": a})
	b.beams = beams
	if b["round"] == 0:
		State.story_message = 'LORD VINDEX: "Tiga sinar. Dua detik untuk menyingkir."'
		State.story_message_timer = 150
	else:
		State.story_message = 'LORD VINDEX: "Lagi! Gelombang ' + str(b["round"] + 1) + ' dari ' + str(Config.VINDEX_BARRAGE_ROUNDS) + '."'
		State.story_message_timer = 110


func fire_barrage_round(b: Dictionary) -> void:
	b.phase = "fire"
	b.t = 0
	State.screen_shake = 14
	for beam in b.beams:
		for k in State.killers:
			if k != null and k.loading <= 0 and not k.disintegrating and barrage_beam_hits(beam.angle, k):
				destroy_enemy_by_vindex_laser(k)
		for a in State.archers:
			if a != null and not a.dead and barrage_beam_hits(beam.angle, a):
				a.dead = true
				Killers.create_disintegration_particles(a)
	var hits_player := false
	for beam in b.beams:
		if barrage_beam_hits(beam.angle, State.player):
			hits_player = true
			break
	if State.hit_cooldown <= 0 and hits_player:
		b.hit = true
		vindex_damage_player(Config.VINDEX_POWER_DAMAGE, 'Lord Vindex: "Sudah kuperingatkan. Dua detik itu cukup."', "⚡ LASER VINDEX — " + str(Config.VINDEX_POWER_DAMAGE) + " NYAWA HILANG", 18)
		Meteors.create_meteor_impact_particles(State.player.x + State.player.w / 2.0, State.player.y + State.player.h / 2.0)


# ─────────────── PUSARAN UNGU ───────────────

func start_vindex_vortex() -> void:
	var p: Dictionary = State.player
	var lv: Dictionary = State.lord_vindex
	var pos = null
	var n := 0
	while n < 80 and pos == null:
		n += 1
		var x: int = Util.random_int(110, Config.WIDTH - 110)
		var y: int = Util.random_int(150, Config.HEIGHT - 100)
		var pc := Vector2(p.x + p.w / 2.0, p.y + p.h / 2.0)
		var lc := Vector2(lv.x + lv.w / 2.0, lv.y + lv.h / 2.0)
		if Vector2(x - pc.x, y - pc.y).length() >= Config.VORTEX_SPAWN_MIN_PLAYER and Vector2(x - lc.x, y - lc.y).length() >= Config.VORTEX_SPAWN_MIN_VINDEX:
			pos = {"x": x, "y": y}
	if pos == null:
		pos = {"x": (Config.WIDTH - 160) if p.x < Config.WIDTH / 2.0 else 160, "y": (Config.HEIGHT - 150) if p.y < Config.HEIGHT / 2.0 else 170}
	State.vindex_vortex = {"x": pos.x, "y": pos.y, "age": 0, "exploded": false}
	State.vindex_vortex_cooldown = Util.random_int(Config.VORTEX_COOLDOWN_MIN, Config.VORTEX_COOLDOWN_MAX)
	State.screen_shake = 8
	State.story_message = 'LORD VINDEX: "Pusaran itu akan menelan semuanya. Kecuali aku."'
	State.story_message_timer = 170


## Tarik entitas ke pusat pusaran. Kekuatan naik mendekati lingkaran maut.
func vortex_pull(ent, strength: float, _margin: float = 10.0) -> void:
	var v: Dictionary = State.vindex_vortex
	var cx: float = ent.x + ent.w / 2.0
	var cy: float = ent.y + ent.h / 2.0
	var dx: float = v.x - cx
	var dy: float = v.y - cy
	var d: float = Vector2(dx, dy).length()
	if d == 0.0:
		d = 1.0
	if d > Config.VORTEX_PULL_RADIUS:
		return
	var k: float = 1.0 - (d - Config.VORTEX_KILL_RADIUS) / (Config.VORTEX_PULL_RADIUS - Config.VORTEX_KILL_RADIUS)
	var sp: float = Config.VORTEX_PULL_MAX * (0.28 + 0.72 * maxf(0.0, minf(1.0, k))) * strength
	ent.x += dx / d * sp
	ent.y += dy / d * sp
	ent.x = maxf(-ent.w, minf(Config.WIDTH, ent.x))
	ent.y = maxf(-ent.h, minf(Config.HEIGHT, ent.y))


func vortex_inside(ent) -> bool:
	var v: Dictionary = State.vindex_vortex
	return Vector2(ent.x + ent.w / 2.0 - v.x, ent.y + ent.h / 2.0 - v.y).length() <= Config.VORTEX_KILL_RADIUS


func update_vindex_vortex() -> void:
	var v: Dictionary = State.vindex_vortex
	v.age += 1
	var ramp: float = minf(1.0, v.age / 30.0) # hisapan menguat dalam 0,5 detik pertama
	# Pemain terhisap (tidak ada gerak pemain yang diganti: hanya ditarik tiap frame).
	if State.player != null and State.player_death_timer <= 0:
		vortex_pull(State.player, ramp, 0.0)
	for k in State.killers:
		if k.disintegrating:
			continue
		vortex_pull(k, ramp * 1.15)
		if vortex_inside(k):
			destroy_enemy_by_vindex_laser(k)
			k.disintegrate_timer = 24
	for a in State.archers:
		if a.dead:
			continue
		vortex_pull(a, ramp * 1.15)
		if vortex_inside(a):
			a.dead = true
			Killers.create_disintegration_particles(a)
	# Masuk lingkaran = mati seketika, apa pun status Power Kill / Time Stop.
	if State.player != null and State.player_death_timer <= 0 and State.lives > 0 and vortex_inside(State.player):
		State.lives = 0
		State.hard_death_cause = 'Lord Vindex: "Pusaran itu tidak mengenal ampun."'
		State.player_death_max = 100
		State.player_death_timer = 100
		State.global_freeze = 100
		State.hit_cooldown = 100
		Player.create_player_death_particles()
		State.screen_shake = 22
		State.vindex_vortex = null
		return
	if v.age >= Config.VORTEX_ACTIVE_TIME:
		explode_vindex_vortex()


## Ledakan akhir: gelombang menjauhkan pemain, Killer, dan Archer dari pusaran (seperti meteor besar).
func explode_vindex_vortex() -> void:
	var v: Dictionary = State.vindex_vortex
	State.vindex_vortex = null
	GameAudio.play("meteor_big")
	Meteors.create_large_meteor_impact_particles(v.x, v.y)
	Meteors.large_meteor_shockwave(v.x, v.y)
	State.screen_shake = 20
	var max_dist: float = Vector2(Config.WIDTH, Config.HEIGHT).length() / 2.0
	if State.player != null and State.player_death_timer <= 0:
		var q: Dictionary = _vortex_push(State.player, v, max_dist)
		State.player_shock_timer = 34
		State.player_shock_x = q.nx * q.power
		State.player_shock_y = q.ny * q.power
	for k in State.killers:
		if k == null or k.loading > 0 or k.disintegrating:
			continue
		var q2: Dictionary = _vortex_push(k, v, max_dist)
		k.knockback_x = q2.nx * q2.power
		k.knockback_y = q2.ny * q2.power
		k.knockback_timer = 34
		k.hit_flash = 16
	for a in State.archers:
		if a == null or a.dead:
			continue
		var q3: Dictionary = _vortex_push(a, v, max_dist)
		a.knockback_x = q3.nx * q3.power
		a.knockback_y = q3.ny * q3.power
		a.knockback_timer = 34
		a.flash = 16
	State.story_message = 'LORD VINDEX: "Pusaran itu meledak. Semuanya terlempar."'
	State.story_message_timer = 120


func _vortex_push(ent, v: Dictionary, max_dist: float) -> Dictionary:
	var dx: float = ent.x + ent.w / 2.0 - v.x
	var dy: float = ent.y + ent.h / 2.0 - v.y
	var d: float = Vector2(dx, dy).length()
	if d == 0.0:
		d = 1.0
	var f: float = maxf(0.18, 1.0 - minf(d / max_dist, 1.0) * 0.72)
	var power: float = 5.0 + Config.VORTEX_BLAST_POWER * f
	return {"nx": dx / d, "ny": dy / d, "power": power}
