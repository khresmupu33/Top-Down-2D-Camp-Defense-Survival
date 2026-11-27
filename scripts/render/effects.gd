extends Node
## Efek kanvas di atas karakter (dari render/effects.js): partikel, gelombang Time Stop, laser,
## banner, overlay. Autoload: Effects. Semua fungsi menerima `canvas` sebagai parameter pertama.
## Catatan: simbol emoji (peringatan/meteor/petir) pada teks dihilangkan karena font bawaan tidak memilikinya.

const W := 800.0
const H := 600.0

var _style := StyleBoxFlat.new()
var _pts := PackedVector2Array()
var _story_frame := -1   # frame fisika terakhir saat story_message_timer dikurangi


# ── pembantu ──────────────────────────────────────────────────────────
## Teks rata tengah dengan baseline 'alphabetic' di y (default ctx.fillText).
func _txt(canvas: CanvasItem, x: float, base_y: float, s: String, size: int, color: Color) -> void:
	DrawKit.text_center(canvas, x, base_y - size * 0.35, s, size, color)


func _rrect(canvas: CanvasItem, x: float, y: float, w: float, h: float, r: int, fill: Color, border: Color, bw: int) -> void:
	_style.bg_color = fill
	_style.border_color = border
	_style.set_border_width_all(bw)
	_style.set_corner_radius_all(r)
	canvas.draw_style_box(_style, Rect2(x, y, w, h))


## Garis putus-putus dari a ke b (setLineDash([dash, gap]) + lineDashOffset).
func _dash_line(canvas: CanvasItem, a: Vector2, b: Vector2, dash: float, gap: float, offset: float, color: Color, width: float) -> void:
	var total: float = a.distance_to(b)
	if total <= 0.0:
		return
	var dir: Vector2 = (b - a) / total
	var period: float = dash + gap
	var s: float = fposmod(-offset, period) - period
	while s < total:
		var s0: float = maxf(s, 0.0)
		var s1: float = minf(s + dash, total)
		if s1 > s0:
			canvas.draw_line(a + dir * s0, a + dir * s1, color, width)
		s += period


## Lingkaran putus-putus di pusat c (lokal), jari-jari r.
func _dash_circle(canvas: CanvasItem, c: Vector2, r: float, dash: float, gap: float, offset: float, color: Color, width: float) -> void:
	if r <= 0.0:
		return
	var period: float = dash + gap
	var s: float = fposmod(-offset, period) - period
	var circ: float = TAU * r
	while s < circ:
		var s0: float = maxf(s, 0.0)
		var s1: float = minf(s + dash, circ)
		if s1 > s0:
			var segs: int = maxi(2, ceili((s1 - s0) / 6.0))
			canvas.draw_arc(c, r, s0 / r, s1 / r, segs, color, width, true)
		s += period


func _col(hex: String, a: float) -> Color:
	var c := Color(hex)
	c.a = clampf(a, 0.0, 1.0)
	return c


# ── partikel ──────────────────────────────────────────────────────────
func draw_particles(canvas: CanvasItem) -> void:
	var c_death := Color("#f472b6")
	var c_meteor := Color("#f97316")
	var c_def := Color("#ef4444")
	for p in State.particle_list:
		var a: float = maxf(0.0, float(p.life) / float(p.max_life))
		var col: Color = c_def
		if p.get("death_particle", false):
			col = c_death
		elif p.get("meteor_particle", false):
			col = c_meteor
		col.a = a
		canvas.draw_rect(Rect2(p.x, p.y, p.size, p.size), col)


# ── gelombang Time Stop ───────────────────────────────────────────────
func _wave_rings(canvas: CanvasItem, cx: float, cy: float, eased: float, color: String) -> void:
	var max_r: float = Vector2(W, H).length() * .72
	for i in range(3):
		var offset: float = i * .14
		var wp: float = minf(1.0, maxf(0.0, eased - offset))
		var r: float = 25.0 + wp * max_r
		var a: float = (1.0 - wp) * .22
		canvas.draw_arc(Vector2(cx, cy), r, 0.0, TAU, 96, _col(color, a), 3.0 - i * .55, true)


func draw_time_stop_wave(canvas: CanvasItem) -> void:
	if State.time_stop <= 0 and State.time_stop_wave <= 0:
		return
	var progress: float = minf(1.0, float(State.time_stop_wave) / Config.TIME_STOP_DURATION)
	var slow_progress: float = 1.0 - pow(1.0 - progress, 0.72)
	var cx: float = W / 2.0
	var cy: float = H / 2.0
	if State.player != null:
		cx = State.player.x + State.player.w / 2.0
		cy = State.player.y + State.player.h / 2.0
	if State.time_stop_origin_x != 0:
		cx = State.time_stop_origin_x
	if State.time_stop_origin_y != 0:
		cy = State.time_stop_origin_y
	_wave_rings(canvas, cx, cy, slow_progress, "#7dd3fc")
	DrawKit.rect(canvas, 0, 0, W, H, _col("#38bdf8", .10 + sin(State.time_stop_wave_pulse) * .025))


# ── peringatan archer ─────────────────────────────────────────────────
func draw_archer_warning(canvas: CanvasItem) -> void:
	if State.level != "normal" or State.archer_warning_timer <= 0:
		return
	var pulse: float = 0.72 + sin(Util.now() * 0.018) * 0.28
	_rrect(canvas, 180, 18, 440, 42, 12, Color(127.0 / 255.0, 29.0 / 255.0, 29.0 / 255.0, .88 * pulse), _col("#fb923c", pulse), 2)
	_txt(canvas, W / 2.0, 45, str(State.archer_warning_text), 15, _col("#fff7ed", pulse))


# ── pesan cerita ──────────────────────────────────────────────────────
func draw_story_message(canvas: CanvasItem) -> void:
	# Timer dikurangi sekali per tick fisika (60 Hz), bukan per frame render.
	var pf: int = Engine.get_physics_frames()
	var tick: bool = pf != _story_frame
	_story_frame = pf
	if State.level == "hard":
		# SULIT: subtitle Vindex berada di luar arena (lihat systems/subtitle.gd).
		if State.story_message_timer > 0 and State.story_message != "":
			HardSubtitle.show_subtitle(State.story_message, minf(1.0, State.story_message_timer / 25.0))
			if tick:
				State.story_message_timer -= 1
		else:
			HardSubtitle.hide_subtitle()
		return
	if State.story_message_timer <= 0 or State.story_message == "":
		return
	var a: float = minf(1.0, State.story_message_timer / 25.0)
	_rrect(canvas, 115, H - 70, 570, 44, 12, Color(2.0 / 255.0, 3.0 / 255.0, 5.0 / 255.0, .88 * a), Color(168.0 / 255.0, 85.0 / 255.0, 247.0 / 255.0, .7 * a), 1)
	_txt(canvas, W / 2.0, H - 43, str(State.story_message), 14, _col("#f8fafc", a))
	if tick:
		State.story_message_timer -= 1


# ── overlay urutan poin 25 (SULIT) ────────────────────────────────────
func draw_hard25_sequence_overlay(canvas: CanvasItem) -> void:
	if State.level != "hard" or not State.hard25_sequence_active:
		return
	var t: float = State.hard25_sequence_timer
	if t < 150.0:
		var p: float = minf(1.0, t / 150.0)
		var ease_v: float = 1.0 - pow(1.0 - p, 3.0)
		DrawKit.rect(canvas, 0, 0, W, H, _col("#7e22ce", .10 + .82 * p))
		canvas.draw_circle(Vector2(400, 300), 28.0 + ease_v * 82.0, _col("#f5d0fe", .95 * (1.0 - p * .35)))
		for i in range(18):
			var a: float = i * TAU / 18.0
			var r: float = 45.0 + ease_v * (95.0 + (i % 5) * 22.0)
			var ca: float = cos(a)
			var sa: float = sin(a)
			canvas.draw_line(Vector2(400.0 + ca * (r - 25.0), 300.0 + sa * (r - 25.0)), Vector2(400.0 + ca * r, 300.0 + sa * r), _col("#e9d5ff", .9 * (1.0 - p)), 4.0 + (i % 3), true)
		for ring in range(4):
			var col: String = "#c084fc" if ring % 2 == 1 else "#f5d0fe"
			canvas.draw_arc(Vector2(400, 300), 60.0 + ease_v * (70.0 + ring * 70.0), 0.0, TAU, 96, _col(col, (.8 - ring * .15) * (1.0 - p)), 7.0 - ring, true)
	elif t < 600.0:
		DrawKit.rect(canvas, 0, 0, W, H, Color(3.0 / 255.0, 3.0 / 255.0, 8.0 / 255.0, .94 * .94))
		DrawKit.text_center(canvas, 400, 245, "GAME OVER", 34, _col("#f8fafc", .94))
		DrawKit.text_center(canvas, 400, 285, "Poin : " + str(State.score), 16, _col("#d8b4fe", .94))
		var remain: int = maxi(0, ceili((600.0 - t) / 60.0))
		DrawKit.text_center(canvas, 400, 325, "Vindex sedang menyiapkan sesuatu... " + str(remain), 14, _col("#a78bfa", .94))
	elif t < 900.0:
		var p2: float = (t - 600.0) / 300.0
		DrawKit.rect(canvas, 0, 0, W, H, _col("#7e22ce", .18 + .18 * sin(p2 * PI)))
		DrawKit.text_center(canvas, 400, 245, "LORD VINDEX", 30, Color("#f8fafc"))
		DrawKit.text_center(canvas, 400, 285, '"OH TIDAK... AKU TERLALU KUAT."', 18, Color("#d8b4fe"))
		DrawKit.text_center(canvas, 400, 320, '"Tapi aku akan memberimu kesempatan sekali lagi."', 15, Color("#c4b5fd"))
	elif t < 1080.0:
		DrawKit.rect(canvas, 0, 0, W, H, Color(3.0 / 255.0, 3.0 / 255.0, 8.0 / 255.0, .72 * .96))
		DrawKit.text_center(canvas, 400, 245, "KEMBALI KE ARENA", 30, _col("#f8fafc", .96))
		DrawKit.text_center(canvas, 400, 292, '"Ini yang membedakan diriku dengan yang lain, kesempatan."', 16, _col("#d8b4fe", .96))
		DrawKit.text_center(canvas, 400, 355, "BERSIAP... PERMAINAN DILANJUTKAN", 19, _col("#ffffff", .96))
		DrawKit.text_center(canvas, 400, 382, "Mulai sekarang Lord Vindex bisa menghentikan waktu.", 12, _col("#a78bfa", .96))
	else:
		var p3: float = minf(1.0, (t - 1080.0) / 90.0)
		DrawKit.rect(canvas, 0, 0, W, H, _col("#05020a", .35 + .65 * p3))
		DrawKit.text_center(canvas, 400, 300, "PERMAINAN DILANJUTKAN", 24, _col("#d8b4fe", .9 * (1.0 - p3)))


# ── Time Stop Vindex & laser ──────────────────────────────────────────
func draw_vindex_time_stop_wave(canvas: CanvasItem) -> void:
	var lv = State.lord_vindex
	if State.level != "hard" or State.vindex_time_stop <= 0 or lv == null or lv.get("dead", false):
		return
	var progress: float = 1.0 - (State.vindex_time_stop / 300.0)
	var eased: float = 1.0 - pow(1.0 - progress, .72)
	var cx: float = lv.x + lv.w / 2.0
	var cy: float = lv.y + lv.h / 2.0
	if State.time_stop_origin_x != 0:
		cx = State.time_stop_origin_x
	if State.time_stop_origin_y != 0:
		cy = State.time_stop_origin_y
	_wave_rings(canvas, cx, cy, eased, "#c084fc")
	DrawKit.rect(canvas, 0, 0, W, H, _col("#a855f7", .08 + sin(State.vindex_laser_pulse) * .035))


func draw_vindex_laser(canvas: CanvasItem) -> void:
	var lv = State.lord_vindex
	if State.level != "hard" or not State.vindex_laser_active or lv == null or lv.get("dead", false):
		return
	var targeting: bool = State.vindex_laser_countdown > 0
	var time_stopping: bool = State.vindex_time_stop > 0
	var chasing: bool = time_stopping or targeting
	var firing: bool = State.vindex_laser_fire_timer > 0
	if not chasing and not firing:
		return
	# TARGETING: pusat visual mengikuti Vindex (hanya indikator).
	# FIRING: pakai origin yang disimpan saat laser ditembakkan (tidak mengikuti player lagi).
	var cx: float = State.vindex_laser_origin_x if firing else lv.x + lv.w / 2.0
	var cy: float = State.vindex_laser_origin_y if firing else lv.y + lv.h / 2.0
	var pulse: float = .65 + .35 * sin(State.vindex_laser_pulse)
	var beam_len: float = Vector2(W, H).length() * 1.1
	var bw: float = Config.VINDEX_POWER_BEAM_WIDTH
	var lp: float = State.vindex_laser_pulse
	DrawKit.set_transform(canvas, cx, cy, State.vindex_laser_angle)
	if chasing:
		# Selama Time Stop target mengejar player; setelah itu target diam 1 detik.
		DrawKit.rect(canvas, 0, -bw / 2.0, beam_len, bw, _col("#c084fc", .10 + .08 * sin(lp * 1.4)))
		var dc: Color = _col("#f5d0fe", .65 + .2 * sin(lp * 1.4))
		_dash_line(canvas, Vector2(0, -bw / 2.0), Vector2(beam_len, -bw / 2.0), 18, 12, 0, dc, 2.0)
		_dash_line(canvas, Vector2(0, bw / 2.0), Vector2(beam_len, bw / 2.0), 18, 12, 0, dc, 2.0)
	elif firing:
		# Laser aktif: posisi dan arah sudah FROZEN.
		DrawKit.rect(canvas, 0, -bw / 2.0, beam_len, bw, _col("#c084fc", .22 + .12 * pulse))
		DrawKit.rect(canvas, 0, -maxf(3.0, bw * .22), beam_len, maxf(6.0, bw * .44), _col("#f5d0fe", .92))
		canvas.draw_line(Vector2(0, 0), Vector2(beam_len, 0), _col("#ffffff", .75), 2.0 + pulse * 2.0, true)
	DrawKit.clear_transform(canvas)
	# Garis menuju player hanya saat targeting.
	if chasing:
		_dash_line(canvas, Vector2(cx, cy), Vector2(State.vindex_laser_x, State.vindex_laser_y), 10, 8, 0, _col("#d8b4fe", .9), 2.0)
	var tc := _col("#f5d0fe", .9)
	if time_stopping:
		_txt(canvas, W / 2.0, 82, "TIME STOP VINDEX — DUNIA MELAMBAT", 13, tc)
	elif targeting:
		_txt(canvas, W / 2.0, 82, "LASER DALAM " + str(ceili(State.vindex_laser_countdown / 60.0)) + "s — TARGET TERKUNCI", 13, tc)
	elif firing:
		_txt(canvas, W / 2.0, 82, "LASER VINDEX — TARGET TERKUNCI", 13, tc)


# ── meteor ────────────────────────────────────────────────────────────
## Efek meteor di atas karakter: peringatan, gelombang kejut, banner.
func draw_meteor_effects(canvas: CanvasItem) -> void:
	var sw = State.meteor_shockwave
	if sw != null and sw.life > 0:
		var r: float = sw.r + (sw.max - sw.r) * (1.0 - sw.life / 42.0)
		canvas.draw_arc(Vector2(sw.x, sw.y), r, 0.0, TAU, 96, _col("#fef08a", sw.life / 42.0), 5.0, true)
	var w = State.large_meteor_warning
	if w != null:
		var hard: bool = State.level == "hard"
		var rad: float = w.radius * (1.0 + sin(w.phase * 2.0) * .06)
		canvas.draw_circle(Vector2(w.x, w.y), rad, _col("#7e22ce" if hard else "#ef4444", .25))
		_dash_circle(canvas, Vector2(w.x, w.y), rad, 10, 8, 0, _col("#d8b4fe" if hard else "#fca5a5", .9), 3.0)
		_txt(canvas, w.x, w.y - w.radius - 12, "METEOR BATU BESAR", 16, Color("#fee2e2"))
	if State.meteor_pre_shower_active:
		_txt(canvas, W / 2.0, 42, "METEOR AKAN DATANG", 17, _col("#fbbf24", .95))
		_txt(canvas, W / 2.0, 61, "Persiapan...", 12, _col("#fde68a", .95))
	elif State.meteor_warning_timer > 0:
		_txt(canvas, W / 2.0, 42, "HUJAN METEOR", 18, _col("#fb923c", .95))


# ── Rentetan Laser Vindex ─────────────────────────────────────────────
## Garis peringatan 2 detik, lalu laser menyala.
func draw_vindex_barrage(canvas: CanvasItem) -> void:
	var lv = State.lord_vindex
	var b = State.vindex_barrage
	if State.level != "hard" or b == null or lv == null or lv.get("dead", false):
		return
	var cx: float = b.origin_x
	var cy: float = b.origin_y
	var length: float = Vector2(W, H).length() * 1.1
	var w: float = Config.VINDEX_BARRAGE_WIDTH
	var bt: float = b.t
	if b.phase == "gather":
		# area aman di sekitar pusat: titik/item tidak muncul di sini
		_dash_circle(canvas, Vector2(W / 2.0, H / 2.0), Config.VINDEX_BARRAGE_SAFE_RADIUS, 8, 8, 0, _col("#d8b4fe", .18 + .1 * sin(bt * .25)), 2.0)
	elif b.phase == "warn" or b.phase == "fire":
		var warn: bool = b.phase == "warn"
		var p: float = bt / Config.VINDEX_BARRAGE_WARN if warn else 1.0 - bt / Config.VINDEX_BARRAGE_FIRE
		for beam in b.beams:
			DrawKit.set_transform(canvas, cx, cy, beam.angle)
			if warn:
				var blink: float = 1.0
				if bt > Config.VINDEX_BARRAGE_WARN - 30:
					blink = 1.0 if floori(bt / 4.0) % 2 == 1 else .55
				DrawKit.rect(canvas, 0, -w / 2.0, length, w, _col("#c084fc", (.08 + .16 * p) * blink))
				var dc: Color = _col("#f5d0fe", (.55 + .35 * p) * blink)
				_dash_line(canvas, Vector2(0, -w / 2.0), Vector2(length, -w / 2.0), 16, 10, -bt * .8, dc, 2.0)
				_dash_line(canvas, Vector2(0, w / 2.0), Vector2(length, w / 2.0), 16, 10, -bt * .8, dc, 2.0)
			else:
				DrawKit.rect(canvas, 0, -w / 2.0, length, w, _col("#c084fc", .22 + .4 * p))
				DrawKit.rect(canvas, 0, -w * .22, length, w * .44, _col("#f5d0fe", .95))
				DrawKit.rect(canvas, 0, -3, length, 6, _col("#ffffff", .8))
			DrawKit.clear_transform(canvas)
		# pusat energi di Vindex
		canvas.draw_circle(Vector2(cx, cy), 20.0 + p * 22.0 if warn else 46.0, _col("#e9d5ff", .35 + .5 * p if warn else .9))
		if warn:
			var left: float = maxf(0.0, Config.VINDEX_BARRAGE_WARN - bt)
			_txt(canvas, W / 2.0, 82, "LASER DALAM %.1f dtk — GELOMBANG %d/%d" % [left / 60.0, int(b["round"]) + 1, Config.VINDEX_BARRAGE_ROUNDS], 13, _col("#f5d0fe", .95))


# ── Pusaran Ungu ──────────────────────────────────────────────────────
func _core_color(r: float) -> Color:
	var kr: float = Config.VORTEX_KILL_RADIUS
	var t: float = clampf((r - 4.0) / (kr - 4.0), 0.0, 1.0)
	var c0 := Color("#000000")
	var c1 := Color("#2e1065")
	var c2 := Color("#7e22ce")
	if t < .6:
		return c0.lerp(c1, t / .6)
	return c1.lerp(c2, (t - .6) / .4)


## Lingkaran maut + medan hisap yang berputar.
func draw_vindex_vortex(canvas: CanvasItem) -> void:
	var v = State.vindex_vortex
	if State.level != "hard" or v == null:
		return
	var t: float = v.age
	var grow: float = minf(1.0, t / 30.0)
	var rem: float = maxf(0.0, Config.VORTEX_ACTIVE_TIME - t)
	var flicker: float = 1.0
	if rem < 60.0:
		flicker = 1.0 if floori(t / 3.0) % 2 == 1 else .6
	var kr: float = Config.VORTEX_KILL_RADIUS
	var pr: float = Config.VORTEX_PULL_RADIUS
	var c := Vector2(v.x, v.y)
	# jangkauan hisap: gradien radial rgba(168,85,247,.9) -> rgba(88,28,135,0), alpha global .1*grow
	var steps := 14
	var dr: float = (pr - kr) / steps
	var g0 := Color(168.0 / 255.0, 85.0 / 255.0, 247.0 / 255.0)
	var g1 := Color(88.0 / 255.0, 28.0 / 255.0, 135.0 / 255.0)
	canvas.draw_circle(c, kr, Color(g0.r, g0.g, g0.b, .9 * .1 * grow))
	for i in range(steps):
		var f: float = (i + 0.5) / steps
		var col: Color = g0.lerp(g1, f)
		col.a = (.9 * (1.0 - f)) * .1 * grow
		canvas.draw_arc(c, kr + dr * (i + 0.5), 0.0, TAU, 64, col, dr, false)
	_dash_circle(canvas, c, pr, 10, 12, t * .9, _col("#c084fc", .28 * grow * flicker), 2.0)
	# lengan spiral
	if _pts.size() != 41:
		_pts.resize(41)
	for arm in range(4):
		var ac: String = "#a855f7" if arm % 2 == 1 else "#e9d5ff"
		for i in range(41):
			var k: float = i / 40.0
			var ang: float = arm * PI / 2.0 - t * .09 + k * 4.2
			var r: float = kr + k * (pr * .72)
			_pts[i] = Vector2(c.x + cos(ang) * r * grow, c.y + sin(ang) * r * grow)
		canvas.draw_polyline(_pts, _col(ac, .55 * grow * flicker), 3.0, true)
	# inti + lingkaran maut: gradien radial (#000 -> #2e1065 -> #7e22ce) dari r=4 ke r=KILL
	var cr: float = kr * grow
	var bands := 12
	var core_a: float = .96 * grow
	if cr > 0.5:
		var c_in: Color = _core_color(0.0)
		c_in.a = core_a
		canvas.draw_circle(c, cr / bands, c_in)
		for i in range(1, bands):
			var r0: float = cr * i / bands
			var r1: float = cr * (i + 1) / bands
			var cc: Color = _core_color((r0 + r1) * .5)
			cc.a = core_a
			canvas.draw_arc(c, (r0 + r1) * .5, 0.0, TAU, 48, cc, r1 - r0 + .6, false)
		canvas.draw_arc(c, cr, 0.0, TAU, 64, _col("#f5d0fe", (.7 + .3 * sin(t * .3)) * grow), 3.0, true)
	_txt(canvas, W / 2.0, 82, "PUSARAN MELEDAK DALAM %.1f dtk — JANGAN MASUK LINGKARAN" % (rem / 60.0), 13, _col("#f5d0fe", .95))
