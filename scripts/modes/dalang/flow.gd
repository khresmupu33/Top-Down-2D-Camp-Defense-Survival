extends Node
## Alur mode DALANG: mulai, loop, item untuk BOT, gambar efek dalang, input, akhir (dari modes/dalang/flow.js).
## Memakai ulang entitas engine (Killer, Archer, meteor, sprite) dengan `State.player` = BOT.
## Status jalannya level ada di `dl` (DalangFlow.dl). Digambar lewat draw_dalang(canvas) (dipanggil DrawGame.draw_fx
## saat State.level == "dalang"); sprite BOT sendiri digambar Sprites, hiasan BOT (label/beku/amuk) di dl_decorate_bot().

var dl = null                 # objek status dalang (null sebelum dalang_start)
var _toast_token := 0         # pengganti clearTimeout(dlToast._t)
const _END_COLOR := Color("#4ade80")


func _frames(sec: float) -> int:
	return roundi(sec * 60)


func _rand_range_frames(r: Array) -> int:
	return Util.random_int(_frames(r[0]), _frames(r[1]))


func _ui(id: String):
	return GameUI.node(id)


# ── mulai ─────────────────────────────────────────────────────────────────
func dalang_start() -> void:
	var DL: Dictionary = DalangConfig.DL
	State.in_game = true
	State.level = "dalang"
	State.score = 0
	State.lives = 3
	State.paused = false
	GameAudio.set_paused(false)
	State.hit_cooldown = 0
	State.global_freeze = 0
	State.power_active = 0
	State.particle_list = []
	State.screen_shake = 0
	State.player_death_timer = 0
	State.player_death_max = 0
	State.meteors = []
	State.killers = []
	State.gadflies = []
	State.archers = []
	State.archer_arrows = []
	State.large_meteor = null
	State.large_meteor_warning = null
	State.large_meteor_pending = false
	State.large_meteor_impact_state = null
	State.meteor_shockwave = null
	State.time_stop = 0
	State.time_stop_wave = 0
	State.time_stop_wave_pulse = 0
	State.vindex_time_stop = 0
	State.player_shock_timer = 0
	State.player_shock_x = 0
	State.player_shock_y = 0
	State.collectible_relocate_cooldown = 0
	State.story_message = ""
	State.story_message_timer = 0
	State.pressed_keys.clear()

	State.player = {"x": 390, "y": 300, "w": 20, "h": 20}
	State.target = null                                   # level ini tanpa Inti
	State.health = {"x": 0, "y": 0, "w": 25, "h": 25, "visible": false, "pulse": 0}
	State.powerup = {"x": 0, "y": 0, "w": 26, "h": 26, "visible": false, "pulse": 0}
	State.time_stop_powerup = {"x": 0, "y": 0, "w": 28, "h": 28, "visible": false, "pulse": 0}

	dl = {
		"t": 0,
		"energy": float(DL.ENERGY_START),
		"cd": {"killer": 0, "archer": 0, "rain": 0, "big": 0, "laser": 0, "freeze": 0},
		"rains": [], "lasers": [],
		"freeze": 0, "freeze_max": DL.FREEZE, "freeze_len": DL.FREEZE, "freeze_uses": 0, "rage": 0, "shield": 0, "shield_flash": 0,
		"freeze_origin": {"x": 0, "y": 0}, "freeze_wave": 0,
		"learn": {"killer": 1.0, "arrow": 1.0, "meteor": 1.0, "big": 1.0, "laser": 1.0},
		"hits": 0, "spent": 0, "casts": {}, "hit_flash": 0,
		"power_at": _rand_range_frames(DL.POWER_FIRST), "ts_at": _rand_range_frames(DL.TS_FIRST), "health_at": _rand_range_frames(DL.HEALTH_FIRST),
		"sel": null, "laser_step": 3,
		"aim": {"on": false, "x": 400, "y": 300, "dragging": false, "ax": 0, "ay": 0, "moved": false, "angle": 0.0},
		"toast": "", "toast_t": 0, "death_fx": false, "ended": false,
	}
	DalangBot.bot_reset()

	State.game_state = "ready"
	GameFlow.show_only("gameScreen")
	_set_visible("readyOverlay", false)
	_set_visible("pauseText", false)
	_set_visible("dlBrief", true)
	dl_update_ui()


func _set_visible(id: String, v: bool) -> void:
	var n = _ui(id)
	if n != null:
		n.visible = v


func dl_hide_brief() -> void:
	_set_visible("dlBrief", false)


func dalang_begin() -> void:
	if State.game_state == "playing":
		dl_hide_brief()   # sudah jalan: pastikan briefing tertutup
		return
	if State.game_state != "ready":
		return
	State.game_state = "playing"
	_set_visible("dlBrief", false)
	GameAudio.start_music()


# ── loop ──────────────────────────────────────────────────────────────────
## Satu tick per frame fisika (60 Hz), dipanggil dispatcher pusat selama State.level == "dalang".
func run_dalang() -> void:
	if State.game_state != "playing" or State.level != "dalang" or dl == null:
		return
	if State.paused:
		_set_visible("pauseText", true)
		GameAudio.tick()
		Hud.update_hud()
		dl_update_ui()
		return
	_set_visible("pauseText", false)
	dl_hide_brief()
	dalang_tick()
	GameAudio.tick()
	Hud.update_hud()
	dl_update_ui()


# ── satu tick logika ──────────────────────────────────────────────────────
func dalang_tick() -> void:
	var DL: Dictionary = DalangConfig.DL
	if State.player_death_timer > 0:                       # BOT tumbang: animasi lalu kemenangan dalang
		State.player_death_timer -= 1
		if State.screen_shake > 0:
			State.screen_shake -= 1
		Particles.update_particles()
		if State.player_death_timer <= 0:
			dl_end()
		return
	dl.t += 1
	dl.energy = minf(DL.ENERGY_MAX, dl.energy + DL.ENERGY_REGEN)
	for id in dl.cd:
		if dl.cd[id] > 0:
			dl.cd[id] -= 1
	if dl.hit_flash > 0:
		dl.hit_flash -= 1
	if dl.shield_flash > 0:
		dl.shield_flash -= 1
	if dl.toast_t > 0:
		dl.toast_t -= 1
	if dl.freeze > 0:
		dl.freeze -= 1
		dl.freeze_wave += 1
		if dl.freeze == 0:
			dl.shield = 0
			dl.rage = DL.RAGE_AFTER_FREEZE
			State.story_message = "🔥 BOT LEPAS DARI BEKU — MENGAMUK!"
			State.story_message_timer = 90
	elif dl.rage > 0:
		dl.rage -= 1

	# item & BOT
	dl_spawn_items()
	DalangBot.dl_bot_think()
	DalangBot.dl_move_bot()
	dl_check_pickups()
	TimeStop.update_time_stop()

	# bencana dalang
	DalangSkills.dl_update_rain()
	DalangSkills.dl_update_lasers()
	DalangSkills.dl_update_big_meteor()
	DalangSkills.dl_update_meteors()
	DalangSkills.dl_track("meteor", Callable(Meteors, "check_meteor_collisions"))
	dl_check_death()
	if State.player_death_timer > 0:
		return

	Killers.update_killers()
	Archers.update_archers()
	Killers.update_killer_collisions()
	DalangSkills.dl_track("arrow", Callable(Archers, "check_archer_collisions"))
	Items.update_collectible_relocate_cooldown()
	DalangSkills.dl_track("killer", Callable(Killers, "check_player_killers"))
	dl_check_death()

	if State.power_active > 0:
		State.power_active = maxi(0, State.power_active - 1)
	Killers.update_global_freeze()
	Particles.update_particles()
	if State.story_message_timer > 0 and State.game_state != "playing":
		State.story_message_timer = 0


## Pastikan animasi kematian berjalan bila nyawa BOT habis lewat jalur manapun.
func dl_check_death() -> void:
	if State.lives > 0 or dl.death_fx:
		return
	dl.death_fx = true
	if State.player_death_timer <= 0:
		State.player_death_max = 100
		State.player_death_timer = 100
	State.global_freeze = 100
	Player.create_player_death_particles()
	State.screen_shake = 18
	State.story_message = "💥 BOT TUMBANG!"
	State.story_message_timer = 120


# ── item untuk BOT ────────────────────────────────────────────────────────
func dl_spawn_items() -> void:
	if not State.health.visible and State.lives < 3 and dl.t >= dl.health_at:
		Items.spawn_health()
	if not State.powerup.visible and State.power_active <= 0 and dl.t >= dl.power_at:
		Items.spawn_powerup()
	if not State.time_stop_powerup.visible and State.time_stop <= 0 and dl.t >= dl.ts_at:
		Items.spawn_time_stop_powerup()
	if State.health.visible:
		State.health.pulse += .12
	if State.powerup.visible:
		State.powerup.pulse += .12


func dl_check_pickups() -> void:
	var DL: Dictionary = DalangConfig.DL
	var player: Dictionary = State.player
	if State.health.visible and Util.collide(player, State.health) and State.lives < 3:
		State.lives += 1
		GameAudio.play("health")
		State.health.visible = false
		dl.health_at = dl.t + _rand_range_frames(DL.HEALTH_RESPAWN)
		State.screen_shake = 5
		State.story_message = "💚 BOT mengambil Nyawa"
		State.story_message_timer = 100
	if State.powerup.visible and Util.collide(player, State.powerup):
		State.powerup.visible = false
		GameAudio.play("power_kill")
		State.power_active = Config.POWER_DURATION
		dl.power_at = dl.t + _rand_range_frames(DL.POWER_RESPAWN)
		State.screen_shake = 8
		State.story_message = "⚡ BOT mengambil POWER KILL — Killer & Archer-mu dalam bahaya!"
		State.story_message_timer = 150
	if State.time_stop_powerup.visible and Util.collide(player, State.time_stop_powerup):
		State.time_stop_powerup.visible = false
		GameAudio.play("time_stop")
		State.time_stop = Config.TIME_STOP_DURATION
		State.time_stop_wave = 0
		State.time_stop_origin_x = player.x + player.w / 2.0
		State.time_stop_origin_y = player.y + player.h / 2.0
		dl.ts_at = dl.t + _rand_range_frames(DL.TS_RESPAWN)
		State.screen_shake = 7
		State.story_message = "⏳ BOT mengambil TIME STOP — bencanamu melambat 5 detik & Archer diburu!"
		State.story_message_timer = 150


# ── akhir ─────────────────────────────────────────────────────────────────
const _RECORD_FILE := "user://dalang_best.cfg"


func dl_best_time() -> float:
	var cf := ConfigFile.new()
	if cf.load(_RECORD_FILE) != OK:
		return 0.0   # penyimpanan tidak tersedia
	var v: float = float(cf.get_value("dalang", DalangConfig.DL.RECORD_KEY, 0.0))
	return v if v > 0 else 0.0


func _save_best_time(t: float) -> void:
	var cf := ConfigFile.new()
	cf.load(_RECORD_FILE)
	cf.set_value("dalang", DalangConfig.DL.RECORD_KEY, t)
	cf.save(_RECORD_FILE)


## Level ini adu cepat: satu-satunya akhir adalah BOT tumbang. Waktu makin singkat = rekor makin bagus.
func dl_end() -> void:
	if dl.ended:
		return
	dl.ended = true
	GameAudio.stop_music()
	State.game_state = "end"
	var time: float = dl.t / 60.0
	var title = _ui("endTitle")
	var final_score = _ui("finalScore")
	var result = _ui("dlResult")
	_set_visible("hardDeathMessage", false)
	if title != null:
		title.text = "BOT TUMBANG!"
		title.add_theme_color_override("font_color", _END_COLOR)
	if final_score != null:
		final_score.text = "Waktu : %.1f dtk" % time
	var prev: float = dl_best_time()
	var best: String
	if prev <= 0.0 or time < prev:
		_save_best_time(time)
		best = ("REKOR BARU! (sebelumnya %.1f dtk)" % prev) if prev > 0.0 else "REKOR BARU!"
	else:
		best = "Rekor tercepat: %.1f dtk" % prev
	GameFlow.show_only("endScreen")
	if result != null:
		if result is RichTextLabel:
			result.bbcode_enabled = true
			result.text = "[center][b]%.1f[/b] dtk sampai BOT tumbang\n[b]%d[/b] nyawa BOT berhasil diambil\n[b]%d[/b] energi terpakai\n[color=#fde047]%s[/color][/center]" % [time, dl.hits, roundi(dl.spent), best]
		else:
			result.text = "%.1f dtk sampai BOT tumbang\n%d nyawa BOT berhasil diambil\n%d energi terpakai\n%s" % [time, dl.hits, roundi(dl.spent), best]
		result.visible = true


# ── gambar ────────────────────────────────────────────────────────────────
## Efek dalang di atas sprite (JS drawDalang bagian fxCtx). Latar digambar DrawGame.draw_bg, sprite oleh Sprites.
func draw_dalang(canvas: CanvasItem) -> void:
	if dl == null:
		return
	dl_decorate_bot(canvas)
	dl_draw_rain(canvas)
	dl_draw_lasers(canvas)
	Effects.draw_meteor_effects(canvas)
	Effects.draw_time_stop_wave(canvas)
	dl_draw_freeze(canvas)
	dl_draw_aim(canvas)
	Effects.draw_story_message(canvas)
	Effects.draw_particles(canvas)


## Tampilan khusus BOT: label status, efek beku & amuk (warna biru-hijau BOT diurus Sprites).
func dl_decorate_bot(canvas: CanvasItem) -> void:
	if State.player == null:
		return
	var p: Dictionary = State.player
	var cx: float = p.x + p.w / 2.0
	var cy: float = p.y + p.h / 2.0
	if dl.freeze > 0:
		# bingkai segel beku: inset -16, border 5px #ddd6fe, isi ungu muda
		DrawKit.glow(canvas, cx, cy, 36, Color(0.655, 0.545, 0.98, 0.5))
		DrawKit.rounded_rect(canvas, p.x - 16, p.y - 16, p.w + 32, p.h + 32, Color(0.769, 0.71, 0.992, 0.25), 22)
		DrawKit.rect_outline(canvas, p.x - 16, p.y - 16, p.w + 32, p.h + 32, Color("#ddd6fe"), 5)
	elif dl.rage > 0:
		DrawKit.glow(canvas, cx, cy, 22, Color(0.984, 0.576, 0.235, 0.6))
	var text := ""
	if State.player_death_timer <= 0:
		text = DalangBot.dl_bot_label()
	if text != "":
		var w: float = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 12
		var bx: float = cx - w / 2.0
		var by: float = p.y - 27
		var border := Color("#7dd3fc") if State.time_stop > 0 else Color(0.404, 0.91, 0.976, 0.45)
		DrawKit.rounded_rect(canvas, bx, by, w, 15, Color(0.012, 0.055, 0.086, 0.82), 6)
		DrawKit.rect_outline(canvas, bx, by, w, 15, border, 1)
		DrawKit.text(canvas, bx + 6, by + 7.5, text, 9, Color("#cffafe"))


func _dash_line(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var total: float = a.distance_to(b)
	if total <= 0.0:
		return
	var dir: Vector2 = (b - a) / total
	var d := 0.0
	while d < total:
		var e: float = minf(d + dash, total)
		canvas.draw_line(a + dir * d, a + dir * e, color, width)
		d += dash + gap


func _dash_circle(canvas: CanvasItem, c: Vector2, r: float, color: Color, width: float, dash: float, gap: float) -> void:
	var circ: float = TAU * r
	var step: float = (dash + gap) / r
	var a := 0.0
	while a < TAU:
		var e: float = minf(a + dash / r, TAU)
		canvas.draw_arc(c, r, a, e, 6, color, width, true)
		a += step
	if circ <= 0.0:
		return


func dl_draw_rain(canvas: CanvasItem) -> void:
	var DL: Dictionary = DalangConfig.DL
	for r in dl.rains:
		var x0: float = r.x - DL.RAIN_HALF_WIDTH
		var w: float = DL.RAIN_HALF_WIDTH * 2.0
		var warning: bool = r.warn > 0
		var fa: float = (.13 + .1 * sin(dl.t * .3)) if warning else .07
		DrawKit.rect(canvas, x0, 0, w, Config.HEIGHT, Color(0.984, 0.576, 0.235, fa))
		var la: float = .85 if warning else .35
		var lc := Color(0.992, 0.729, 0.455, la)
		_dash_line(canvas, Vector2(x0, 0), Vector2(x0, Config.HEIGHT), lc, 2, 12, 10)
		_dash_line(canvas, Vector2(x0 + w, 0), Vector2(x0 + w, Config.HEIGHT), lc, 2, 12, 10)
		if warning:
			var tc := Color(1.0, 0.929, 0.835, .9)
			DrawKit.text_center(canvas, r.x, 96, "☄ HUJAN METEOR ☄", 16, tc)
			DrawKit.text_center(canvas, r.x, 114, str(ceilf(r.warn / 60.0 * 10) / 10) + " dtk", 12, tc)


func dl_draw_lasers(canvas: CanvasItem) -> void:
	var DL: Dictionary = DalangConfig.DL
	var length: float = Vector2(Config.WIDTH, Config.HEIGHT).length() * 1.2
	for L in dl.lasers:
		DrawKit.set_transform(canvas, L.x, L.y, L.angle)
		var W: float = DL.LASER_WIDTH
		if L.warn > 0:
			var p: float = 1.0 - L.warn / float(DL.LASER_WARN)
			DrawKit.rect(canvas, -length, -W / 2.0, length * 2, W, Color(0.937, 0.267, 0.267, .10 + .16 * p + .05 * sin(dl.t * .5)))
			var lc := Color(0.996, 0.792, 0.792, .8)
			_dash_line(canvas, Vector2(-length, -W / 2.0), Vector2(length, -W / 2.0), lc, 2, 16, 10)
			_dash_line(canvas, Vector2(-length, W / 2.0), Vector2(length, W / 2.0), lc, 2, 16, 10)
		else:
			var p2: float = L.fire / float(DL.LASER_FIRE)
			var pulse: float = .75 + .25 * sin(dl.t * .9)
			DrawKit.rect(canvas, -length, -W / 2.0, length * 2, W, Color(0.973, 0.443, 0.443, .28 + .3 * p2))
			DrawKit.rect(canvas, -length, -W * .2, length * 2, W * .4, Color(0.996, 0.886, 0.886, .95))
			DrawKit.rect(canvas, -length, -3, length * 2, 6, Color(1, 1, 1, .8 * pulse))
		DrawKit.clear_transform(canvas)
		if L.warn > 0:
			DrawKit.text_center(canvas, L.x, L.y - 8, "⚡ LASER %.1fs" % (ceilf(L.warn / 6.0) / 10.0), 13, Color("#fee2e2"))


## Gelombang & tint Time Stop dalang.
func dl_draw_freeze(canvas: CanvasItem) -> void:
	if dl.freeze <= 0:
		return
	var max_r: float = Vector2(Config.WIDTH, Config.HEIGHT).length() * .7
	var bot: Dictionary = DalangSkills.dl_bot_center()
	var fo: Dictionary = dl.freeze_origin
	for i in range(3):
		var wp: float = minf(1.0, maxf(0.0, minf(1.0, dl.freeze_wave / 70.0) - i * .16))
		DrawKit.ring(canvas, fo.x, fo.y, 20 + wp * max_r, 4 - i, Color(0.769, 0.71, 0.992, (1 - wp) * .45))
	DrawKit.rect(canvas, 0, 0, Config.WIDTH, Config.HEIGHT, Color(0.486, 0.227, 0.929, .10 + sin(dl.t * .2) * .03))
	# cincin segel di BOT
	_dash_circle(canvas, Vector2(bot.x, bot.y), 24 + sin(dl.t * .3) * 2, Color(0.867, 0.839, 0.996, .9), 3, 6, 5)
	if dl.shield > 0:                       # Perisai Waktu masih utuh
		DrawKit.ring(canvas, bot.x, bot.y, 32, 4, Color(0.992, 0.878, 0.278, .55 + .25 * sin(dl.t * .4)))
	var label := "BEKU %.1fs" % (ceilf(dl.freeze / 6.0) / 10.0) + ("  🛡" if dl.shield > 0 else "  (perisai pecah)")
	DrawKit.text_center(canvas, bot.x, bot.y + 46, label, 13, Color(0.929, 0.914, 0.996, .9))


## Pratinjau bidikan skill yang sedang dipilih.
func dl_draw_aim(canvas: CanvasItem) -> void:
	if dl.sel == null or not dl.aim.on or State.game_state != "playing":
		return
	var DL: Dictionary = DalangConfig.DL
	var sel: String = dl.sel
	var sk: Dictionary = DalangConfig.DL_SKILL[sel]
	var bot: Dictionary = DalangSkills.dl_bot_center()
	var pt: Dictionary = dl_aim_point()
	var ready: bool = dl.cd[sel] <= 0 and dl.energy >= sk.cost
	var valid: bool = ready
	var dist: float = Vector2(pt.x - bot.x, pt.y - bot.y).length()
	var red := Color("#f87171")
	var cyan := Color("#22d3ee")

	if sel == "killer" or sel == "archer":
		var min_d: float = DL.KILLER_MIN_DIST if sel == "killer" else DL.ARCHER_MIN_DIST
		valid = valid and dist >= min_d
		DrawKit.circle(canvas, bot.x, bot.y, min_d, Color(0.973, 0.443, 0.443, .07))
		_dash_circle(canvas, Vector2(bot.x, bot.y), min_d, Color(red, .55), 2, 8, 8)
		var c: Color = cyan if valid else red
		DrawKit.circle(canvas, pt.x, pt.y, 16, Color(c, .18))
		DrawKit.ring(canvas, pt.x, pt.y, 16, 2, Color(c, .95))
		DrawKit.text_center(canvas, pt.x, pt.y + 1, sk.icon, 16, Color.WHITE)
	elif sel == "rain":
		var x0: float = pt.x - DL.RAIN_HALF_WIDTH
		DrawKit.rect(canvas, x0, 0, DL.RAIN_HALF_WIDTH * 2, Config.HEIGHT, Color(cyan if valid else red, .16))
		var lc := Color("#67e8f9") if valid else Color("#fca5a5")
		lc.a = .9
		_dash_line(canvas, Vector2(x0, 0), Vector2(x0, Config.HEIGHT), lc, 2, 10, 8)
		_dash_line(canvas, Vector2(x0 + DL.RAIN_HALF_WIDTH * 2, 0), Vector2(x0 + DL.RAIN_HALF_WIDTH * 2, Config.HEIGHT), lc, 2, 10, 8)
	elif sel == "big":
		var r: float = Config.LARGE_METEOR_SIZE * .62
		DrawKit.circle(canvas, pt.x, pt.y, r, Color(cyan if valid else red, .2))
		var lc2 := Color("#67e8f9") if valid else Color("#fca5a5")
		lc2.a = .95
		_dash_circle(canvas, Vector2(pt.x, pt.y), r, lc2, 2, 9, 7)
		DrawKit.rect_outline(canvas, pt.x - 50, pt.y - 50, 100, 100, lc2, 2)
	elif sel == "laser":
		var length: float = Vector2(Config.WIDTH, Config.HEIGHT).length() * 1.2
		var half: float = DL.LASER_WIDTH / 2.0
		DrawKit.set_transform(canvas, pt.x, pt.y, pt.angle)
		DrawKit.rect(canvas, -length, -half, length * 2, DL.LASER_WIDTH, Color(cyan if valid else red, .15))
		var lc3 := Color("#67e8f9") if valid else Color("#fca5a5")
		lc3.a = .9
		_dash_line(canvas, Vector2(-length, -half), Vector2(length, -half), lc3, 2, 12, 8)
		_dash_line(canvas, Vector2(-length, half), Vector2(length, half), lc3, 2, 12, 8)
		DrawKit.ring(canvas, 0, 0, 7, 2, lc3)
		DrawKit.clear_transform(canvas)


# ── bidikan & input ───────────────────────────────────────────────────────
## Titik & sudut bidik saat ini (laser: titik tekan + arah seret).
func dl_aim_point() -> Dictionary:
	var A: Dictionary = dl.aim
	if dl.sel == "laser":
		if A.dragging and A.moved:
			return {"x": A.ax, "y": A.ay, "angle": A.angle}
		return {"x": A.x, "y": A.y, "angle": dl.laser_step * PI / 12.0}
	return {"x": A.x, "y": A.y, "angle": 0.0}


func dl_toast(msg: String) -> void:
	dl.toast = msg
	dl.toast_t = 100
	var el = _ui("dlToast")
	if el != null:
		el.text = msg
		el.visible = true
		_toast_token += 1
		var token := _toast_token
		Util.after_ms(1500, func():
			if token == _toast_token and is_instance_valid(el):
				el.visible = false)


func dl_select(id: String) -> void:
	if State.game_state != "playing" or State.paused or dl == null:
		return
	var sk = DalangConfig.DL_SKILL.get(id)
	if sk == null:
		return
	if sk.aim == "instant":
		var r: Dictionary = DalangSkills.dl_cast(id, 0, 0, 0)
		if not r.ok and r.msg != "":
			dl_toast(r.msg)
		return
	dl.sel = null if dl.sel == id else id
	if dl.sel != null:
		dl_toast(sk.tip)
	dl_update_ui()


func dl_fire_aim() -> void:
	var pt: Dictionary = dl_aim_point()
	var r: Dictionary = DalangSkills.dl_cast(dl.sel, pt.x, pt.y, pt.angle)
	if not r.ok and r.msg != "":
		dl_toast(r.msg)


## Perbarui dock, bar energi, tombol rotasi. (Tombol dibuat GameUI; tiap tombol punya meta "skill".)
func dl_update_ui() -> void:
	if dl == null:
		return
	var DL: Dictionary = DalangConfig.DL
	var fill = _ui("dlEnergyFill")
	if fill != null:
		var ratio: float = clampf(dl.energy / float(DL.ENERGY_MAX), 0.0, 1.0)
		if fill is Range:
			fill.max_value = 100.0
			fill.value = ratio * 100.0
		elif fill is Control and fill.get_parent() is Control:
			fill.size.x = fill.get_parent().size.x * ratio
		var et = _ui("dlEnergyText")
		if et != null:
			et.text = "ENERGI %d / %d" % [floori(dl.energy), DL.ENERGY_MAX]
	var dock = _ui("dlDock")
	if dock != null:
		for b in dock.get_children():
			if not b.has_meta("skill"):
				continue
			var sk: Dictionary = DalangConfig.DL_SKILL[b.get_meta("skill")]
			var cd_left: float = dl.cd[sk.id]
			var is_sel: bool = dl.sel == sk.id
			var is_low: bool = cd_left <= 0 and dl.energy < sk.cost
			var is_ready: bool = cd_left <= 0 and dl.energy >= sk.cost
			b.set_meta("cd", cd_left / float(sk.cd))   # sisa cooldown 0..1 (setara --cd)
			b.set_meta("is_sel", is_sel)
			b.set_meta("is_low", is_low)
			b.set_meta("is_ready", is_ready)
			GameUI.skin_skill(b)
	_set_visible("dlRotate", dl.sel == "laser")
	_set_visible("dlFreezeChip", dl.freeze > 0)
	var hit = _ui("dlHurt")
	if hit != null:
		hit.modulate.a = (dl.hit_flash / 30.0 * .5) if dl.hit_flash > 0 else 0.0
	var clock = _ui("scoreNumber")
	if clock != null:
		clock.text = "%.1f" % (dl.t / 60.0)
	var best_el = _ui("dlBest")
	if best_el != null:
		var b2: float = dl_best_time()
		best_el.text = ("REKOR %.1f dtk" % b2) if b2 > 0.0 else "REKOR —"


# ── input arena (pengganti pointer/keyboard listener JS) ──────────────────
func _active() -> bool:
	return State.in_game and State.level == "dalang" and dl != null and State.game_state == "playing" and not State.paused


## Titik pointer (koordinat viewport) -> koordinat papan 800x600 (papan berada di tengah layar).
func _board_pos(p: Vector2) -> Vector2:
	var board: Control = GameUI.board
	if board == null:
		return p
	return board.get_global_transform_with_canvas().affine_inverse() * p


func _in_arena(p: Vector2) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x <= Config.WIDTH and p.y <= Config.HEIGHT


func _over_button() -> bool:
	var h = get_viewport().gui_get_hovered_control()
	return h != null and h is BaseButton


func _input(event: InputEvent) -> void:
	if not _active():
		return
	var A: Dictionary = dl.aim
	if event is InputEventMouseMotion:
		var p: Vector2 = _board_pos(event.position)
		A.x = p.x
		A.y = p.y
		A.on = event.device != InputEvent.DEVICE_ID_EMULATION or A.dragging
		if A.dragging and dl.sel == "laser" and Vector2(p.x - A.ax, p.y - A.ay).length() > 26:
			A.moved = true
			A.angle = atan2(p.y - A.ay, p.x - A.ax)
	elif event is InputEventMouseButton:
		var p2: Vector2 = _board_pos(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if dl.sel == null or not _in_arena(p2) or _over_button():
					return
				A.on = true
				A.x = p2.x
				A.y = p2.y
				A.ax = p2.x
				A.ay = p2.y
				A.dragging = true
				A.moved = false
				get_viewport().set_input_as_handled()
			elif A.dragging:
				if dl.sel != null:
					A.x = p2.x
					A.y = p2.y
					if dl.sel == "laser" and not A.moved:
						A.ax = p2.x
						A.ay = p2.y
					dl_fire_aim()
				A.dragging = false
				A.moved = false
				if event.device == InputEvent.DEVICE_ID_EMULATION:
					A.on = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			dl.sel = null
			A.dragging = false
			dl_update_ui()
		elif event.pressed and dl.sel == "laser" and (event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP):
			dl.laser_step = (dl.laser_step + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 11)) % 12
	elif event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.keycode
		if kc >= KEY_1 and kc <= KEY_6:
			dl_select(DalangConfig.DL_SKILLS[kc - KEY_1].id)
		elif kc == KEY_R:
			dl.laser_step = (dl.laser_step + 1) % 12
			if dl.sel != "laser":
				dl_select("laser")
		elif kc == KEY_ESCAPE:
			dl.sel = null
			dl_update_ui()
