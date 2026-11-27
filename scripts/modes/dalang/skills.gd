extends Node
## Skill dalang: Killer, Archer, Hujan Meteor, Meteor Besar, Laser, Time Stop (dari modes/dalang/skills.js).
## Semua bencana punya peringatan (telegraph) — adil bagi BOT, sulit bagi dalang.
## Status dalang (dl) ada di DalangFlow.dl. Tombol skill di dock memanggil on_skill_pressed(id).


## Dipanggil tombol skill di dock (meta "skill" = id). JS: pointerdown -> dlSelect(id).
func on_skill_pressed(skill_id: String) -> void:
	DalangFlow.dl_select(skill_id)


# ── utilitas ──────────────────────────────────────────────────────────────
func dl_bot_center() -> Dictionary:
	var p: Dictionary = State.player
	return {"x": p.x + p.w / 2.0, "y": p.y + p.h / 2.0}


func dl_freeze_ready() -> bool:
	var dl = DalangFlow.dl
	return dl != null and dl.cd.freeze <= 0 and dl.energy >= DalangConfig.DL_SKILL["freeze"].cost


## Jarak titik ke garis laser (tegak lurus).
func dl_laser_dist(L: Dictionary, px: float, py: float) -> float:
	return absf((px - L.x) * -sin(L.angle) + (py - L.y) * cos(L.angle))


# ── pemanggilan ───────────────────────────────────────────────────────────
## Coba memakai skill. Mengembalikan {ok, msg}. Energi & cooldown hanya terpakai jika ok.
func dl_cast(id: String, x: float, y: float, angle: float) -> Dictionary:
	var dl = DalangFlow.dl
	var DL: Dictionary = DalangConfig.DL
	var sk = DalangConfig.DL_SKILL.get(id)
	if sk == null or dl == null:
		return {"ok": false, "msg": ""}
	if dl.cd[id] > 0:
		return {"ok": false, "msg": sk.label + " masih cooldown"}
	if dl.energy < sk.cost:
		return {"ok": false, "msg": "Energi kurang (" + str(sk.cost) + " dibutuhkan)"}

	var bot: Dictionary = dl_bot_center()
	var dist: float = Vector2(x - bot.x, y - bot.y).length()
	var ok := true
	var msg := ""

	if id == "killer":
		if dist < DL.KILLER_MIN_DIST:
			ok = false
			msg = "Terlalu dekat BOT"
		else:
			Killers.add_killer(false)
			var k: Dictionary = State.killers[State.killers.size() - 1]
			k.x = maxf(8, minf(Config.WIDTH - k.w - 8, x - k.w / 2.0))
			k.y = maxf(64, minf(Config.HEIGHT - k.h - 8, y - k.h / 2.0))
	elif id == "archer":
		if dist < DL.ARCHER_MIN_DIST:
			ok = false
			msg = "Terlalu dekat BOT"
		else:
			Archers.spawn_archer(x - 11, y - 11)
			if State.archers.size() > 0:
				var a: Dictionary = State.archers[State.archers.size() - 1]
				Archers.create_teleport_particles(a.x + 11, a.y + 11, 14)
	elif id == "rain":
		dl.rains.append({"x": maxf(60, minf(Config.WIDTH - 60, x)), "warn": DL.RAIN_WARN, "left": DL.RAIN_DURATION, "timer": 0})
		State.screen_shake = 4
	elif id == "big":
		if State.large_meteor != null or State.large_meteor_pending or State.large_meteor_impact_state != null:
			ok = false
			msg = "Meteor besar lain sedang jatuh"
		else:
			var tx: float = maxf(60, minf(Config.WIDTH - 60, x))
			var ty: float = maxf(110, minf(Config.HEIGHT - 70, y))
			State.large_meteor_pending = true
			State.large_meteor_warning = {"x": tx, "y": ty, "target_x": tx, "target_y": ty, "radius": Config.LARGE_METEOR_SIZE * .62, "life": DL.BIG_WARN, "phase": 0.0}
			State.screen_shake = 3
	elif id == "laser":
		if dl.lasers.size() >= 3:
			ok = false
			msg = "Maksimal 3 laser"
		else:
			dl.lasers.append({"x": maxf(0, minf(Config.WIDTH, x)), "y": maxf(0, minf(Config.HEIGHT, y)), "angle": angle, "warn": DL.LASER_WARN, "fire": DL.LASER_FIRE, "hit": false, "sounded": false})
			State.screen_shake = 3
	elif id == "freeze":
		dl.freeze = dl.freeze_len
		dl.freeze_max = dl.freeze_len
		dl.freeze_len = maxi(DL.FREEZE_MIN, roundi(dl.freeze_len * DL.FREEZE_DECAY))   # BOT belajar
		dl.freeze_uses += 1
		dl.shield = DL.FREEZE_SHIELD
		dl.freeze_origin = {"x": bot.x, "y": bot.y}
		dl.freeze_wave = 0
		GameAudio.play("time_stop")
		State.screen_shake = 10
		State.story_message = "⏳ TIME STOP DALANG — BOT TERKUNCI " + str(roundi(dl.freeze_max / 60.0)) + " DETIK!"
		State.story_message_timer = 120

	if not ok:
		return {"ok": false, "msg": msg}
	dl.energy -= sk.cost
	dl.cd[id] = sk.cd
	dl.spent += sk.cost
	dl.casts[id] = dl.casts.get(id, 0) + 1
	return {"ok": true, "msg": ""}


# ── pembaruan efek per tick ───────────────────────────────────────────────
func dl_spawn_rain_meteor(r: Dictionary) -> void:
	GameAudio.play("meteor_pass")
	var DL: Dictionary = DalangConfig.DL
	var size: int = Util.random_int(12, 20)
	var x: float = maxf(Config.METEOR_SAFE_MARGIN, minf(Config.WIDTH - size - Config.METEOR_SAFE_MARGIN, r.x + (randf() * 2 - 1) * DL.RAIN_HALF_WIDTH - size / 2.0))
	var diagonal: bool = randf() < .25
	var dir: int = -1 if randf() < .5 else 1
	State.meteors.append({
		"x": x, "y": -size - 20 - randf() * 30, "w": size, "h": size,
		"vx": (dir * Util.random_int(2, 3)) if diagonal else (randf() - .5) * 1.6,
		"vy": Util.random_int(Config.METEOR_SPEED_MIN, Config.METEOR_SPEED_MAX),
		"rotation": randf() * PI * 2, "rotation_speed": (randf() - .5) * .18,
		"life": 180, "trail": [], "large": false, "impacted": false,
	})


func dl_update_rain() -> void:
	var dl = DalangFlow.dl
	var DL: Dictionary = DalangConfig.DL
	var es: float = TimeStop.enemy_slow_factor()
	for i in range(dl.rains.size() - 1, -1, -1):
		var r: Dictionary = dl.rains[i]
		if r.warn > 0:
			r.warn -= 1
			continue
		r.left -= es
		r.timer -= es
		if r.timer <= 0:
			dl_spawn_rain_meteor(r)
			if randf() < .3:
				dl_spawn_rain_meteor(r)
			r.timer = DL.RAIN_INTERVAL + Util.random_int(-2, 3)
		if r.left <= 0:
			dl.rains.remove_at(i)


## Gerak meteor kecil (salinan logika engine, tanpa sesi/otomatisasi level lain).
func dl_update_meteors() -> void:
	var es: float = TimeStop.enemy_slow_factor()
	for i in range(State.meteors.size() - 1, -1, -1):
		var m: Dictionary = State.meteors[i]
		m.trail.append({"x": m.x + m.w / 2.0, "y": m.y + m.h / 2.0})
		if m.trail.size() > 3:
			m.trail.pop_front()
		m.x += m.vx * es
		m.y += m.vy * es
		m.rotation += m.rotation_speed * es
		if m.x < 0:
			m.x = 0
			m.vx = absf(m.vx)
		if m.x + m.w > Config.WIDTH:
			m.x = Config.WIDTH - m.w
			m.vx = -absf(m.vx)
		if m.y > Config.HEIGHT + 70:
			State.meteors.remove_at(i)


func dl_update_big_meteor() -> void:
	var warn = State.large_meteor_warning
	if State.large_meteor_pending and warn != null:
		warn.life -= 1
		warn.phase += .14
		if warn.life <= 0:
			State.large_meteor_pending = false
			Meteors.spawn_large_meteor()       # memakai large_meteor_warning sebagai titik jatuh, lalu mengosongkannya
			State.screen_shake = 8
	Meteors.update_large_meteor()
	dl_track("big", Callable(Meteors, "process_large_meteor_impact"))


func dl_update_lasers() -> void:
	var dl = DalangFlow.dl
	var DL: Dictionary = DalangConfig.DL
	for i in range(dl.lasers.size() - 1, -1, -1):
		var L: Dictionary = dl.lasers[i]
		if L.warn > 0:
			L.warn -= 1
			continue
		if not L.sounded:
			L.sounded = true
			GameAudio.play("meteor_big")
			State.screen_shake = maxf(State.screen_shake, 6)
		L.fire -= 1
		if not L.hit and State.player_death_timer <= 0 and State.lives > 0:
			var bot: Dictionary = dl_bot_center()
			if dl_laser_dist(L, bot.x, bot.y) <= DL.LASER_WIDTH / 2.0 + 9 and State.hit_cooldown <= 0:
				L.hit = true
				dl_track("laser", func(): dl_damage_bot(DL.LASER_DAMAGE))
		if L.fire <= 0:
			dl.lasers.remove_at(i)


# ── kerusakan pada BOT ────────────────────────────────────────────────────
func dl_damage_bot(n: int) -> void:
	if State.hit_cooldown > 0 or State.lives <= 0:
		return
	State.lives = maxi(0, State.lives - n)
	State.hit_cooldown = Config.METEOR_PLAYER_COOLDOWN
	State.screen_shake = 18
	if State.lives <= 0:
		State.player_death_max = 100
		State.player_death_timer = State.player_death_max
		State.global_freeze = State.player_death_max
		State.hit_cooldown = State.player_death_max
		Player.create_player_death_particles()


## Jalankan fungsi engine, lalu catat bila nyawa BOT berkurang (untuk hadiah energi & pembelajaran BOT).
func dl_track(source: String, fn: Callable) -> void:
	var dl = DalangFlow.dl
	var DL: Dictionary = DalangConfig.DL
	var before: int = State.lives
	# PERISAI WAKTU: poin kerusakan "maya" ditambahkan sebelum engine menghitung serangan,
	# lalu dicabut lagi — serangan pertama selama beku terserap sebagian/seluruhnya.
	var sh: int = dl.shield if (dl.shield > 0 and State.lives > 0) else 0
	if sh:
		State.lives += sh
	fn.call()
	if sh:
		var dealt: int = before + sh - State.lives      # kerusakan mentah serangan ini
		if dealt > 0:                                    # perisai terpakai
			dl.shield = 0
			dl.shield_flash = 40
			if State.lives >= before:                    # terserap seluruhnya
				State.lives = before
				State.story_message = "🛡 PERISAI WAKTU menahan seranganmu! Bekunya masih jalan — serang lagi!"
				State.story_message_timer = 110
				Archers.create_teleport_particles(State.player.x + 10, State.player.y + 10, 16)
		else:
			State.lives = before                         # tidak ada serangan: cabut poin maya
	if dl.freeze > 0 and (State.lives < before or (sh and dl.shield == 0 and dl.shield_flash == 40)) and State.lives > 0:
		State.hit_cooldown = maxf(State.hit_cooldown, DL.FREEZE_IFRAMES)
	if State.lives < before:
		dl_on_bot_hit(before - State.lives, source)


func dl_on_bot_hit(n: int, source: String) -> void:
	var dl = DalangFlow.dl
	var DL: Dictionary = DalangConfig.DL
	dl.hits += n
	var gain: int = DL.HIT_REWARD * n
	dl.energy = minf(DL.ENERGY_MAX, dl.energy + gain)
	dl.learn[source] = minf(DL.LEARN_MAX, dl.learn.get(source, 1) + DL.LEARN_STEP * n)
	dl.hit_flash = 30
	if State.lives > 0:
		dl.rage = maxi(dl.rage, DL.RAGE_AFTER_HIT)   # BOT mengamuk
	var names := {"killer": "KILLER", "arrow": "PANAH", "meteor": "METEOR", "big": "METEOR BESAR", "laser": "LASER"}
	if State.lives > 0:
		State.story_message = "🎯 " + names.get(source, "") + " MENGENAI BOT! +" + str(gain) + " energi — BOT makin waspada"
		State.story_message_timer = 110
