extends Node
## Adegan pembuka mode SULIT. Port dari modes/hard/hard-intro.js.
## Latar + efek digambar lewat draw_hard_intro(canvas); sprite Lord Vindex
## dimunculkan lewat Sprites.show_cinematic_vindex() dari run_hard_intro().

const FIXED_STEP_MS := 1000.0 / 60.0


func init_hard_intro() -> void:
	State.hard_intro_timer = 0
	State.hard_intro_last_time = 0
	State.hard_intro_ready = false
	var lst: Array = []
	for i in range(18):
		lst.append({
			"x": Util.random_int(20, Config.WIDTH - 20),
			"y": -Util.random_int(30, 500),
			"speed": Util.random_int(3, 7),
			"size": Util.random_int(10, 24),
			"drift": (randf() - 0.5) * 1.5,
			"rot": randf() * 6.28,
		})
	State.hard_intro_meteor_list = lst


func _grad_color(d: float) -> Color:
	# gradien radial: rgba(126,34,206,.22) -> rgba(2,3,5,.96), jari-jari 20..560
	var k: float = clampf((d - 20.0) / 540.0, 0.0, 1.0)
	var c0 := Color(126.0 / 255.0, 34.0 / 255.0, 206.0 / 255.0, 0.22)
	var c1 := Color(2.0 / 255.0, 3.0 / 255.0, 5.0 / 255.0, 0.96)
	return c0.lerp(c1, k)


## Latar (JS: bgCtx).
func draw_hard_intro_bg(canvas: CanvasItem) -> void:
	var W: float = Config.WIDTH
	var H: float = Config.HEIGHT
	DrawKit.rect(canvas, 0, 0, W, H, Color("#05010a"))
	# Versi foto: foto latar menggantikan gradien ungu (meteor jatuh di bawah tetap digambar).
	if PhotoKit.draw_fit(canvas, "map_hard_intro", Rect2(0, 0, W, H), "cover"):
		_draw_intro_meteors(canvas, W, H)
		return
	# Gradien radial lewat kipas segitiga dengan warna per titik (dipotong pada tepi arena).
	var ctr := Vector2(400, 280)
	var ring: Array = []
	var xs: Array = [0.0, 200.0, 400.0, 600.0, 800.0]
	var ys: Array = [0.0, 150.0, 300.0, 450.0, 600.0]
	for x in xs:
		ring.append(Vector2(x, 0))
	for y in ys.slice(1):
		ring.append(Vector2(W, y))
	for i in range(xs.size() - 2, -1, -1):
		ring.append(Vector2(xs[i], H))
	for i in range(ys.size() - 2, 0, -1):
		ring.append(Vector2(0, ys[i]))
	var cc: Color = _grad_color(0.0)
	for i in range(ring.size()):
		var p1: Vector2 = ring[i]
		var p2: Vector2 = ring[(i + 1) % ring.size()]
		var pts := PackedVector2Array([ctr, p1, p2])
		var cols := PackedColorArray([cc, _grad_color(ctr.distance_to(p1)), _grad_color(ctr.distance_to(p2))])
		canvas.draw_primitive(pts, cols, PackedVector2Array())
	_draw_intro_meteors(canvas, W, H)


## Meteor jatuh di adegan pembuka. Memakai foto meteor (kunci "meteor_hard" lalu "meteor") bila ada,
## kalau tidak memakai berlian ungu bawaan.
func _draw_intro_meteors(canvas: CanvasItem, _W: float, H: float) -> void:
	var t: float = State.hard_intro_timer
	if t < 270.0:
		var pkey := "meteor_hard" if PhotoKit.has("meteor_hard") else "meteor"
		var tint := Color.WHITE if pkey == "meteor_hard" else Color(0.78, 0.6, 1.0)
		for m in State.hard_intro_meteor_list:
			var fall_y: float = m.y + t * m.speed
			if fall_y > H + 40.0:
				continue
			var x: float = m.x + m.drift * t * 0.2
			var y: float = fall_y
			if t > 150.0:
				var blow: float = minf(1.0, (t - 150.0) / 90.0)
				x += blow * 430.0 + sin(m.rot + t * 0.03) * 35.0
				y -= blow * 150.0
			var sz: float = m.size
			DrawKit.glow(canvas, x, y, sz * 1.5, Color("#c084fc", 0.5), 3)
			DrawKit.set_transform(canvas, x, y, m.rot + t * 0.04)
			if not PhotoKit.draw_fit(canvas, pkey, Rect2(-sz, -sz, sz * 2.0, sz * 2.0), "contain", tint):
				var pts2 := PackedVector2Array([Vector2(0, -sz), Vector2(sz * 0.55, 0), Vector2(0, sz), Vector2(-sz * 0.55, 0)])
				DrawKit.poly(canvas, pts2, Color("#7e22ce"))
			DrawKit.clear_transform(canvas)


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, u: float) -> Vector2:
	var a: Vector2 = p0.lerp(p1, u)
	var b: Vector2 = p1.lerp(p2, u)
	return a.lerp(b, u)


## Efek di atas sprite (JS: fxCtx) + teks.
func draw_hard_intro_fx(canvas: CanvasItem) -> void:
	var W: float = Config.WIDTH
	var H: float = Config.HEIGHT
	var t: float = State.hard_intro_timer
	if t > 80.0 and t < 255.0:
		for i in range(7):
			var p0 := Vector2(55 + i * 16, 95 + i * 18)
			var pts := PackedVector2Array()
			for s in range(17):
				pts.append(_bezier(p0, Vector2(250, 245), Vector2(380, 235), s / 16.0))
			canvas.draw_polyline(pts, Color(168.0 / 255.0, 85.0 / 255.0, 247.0 / 255.0, 0.3), 12.0, true)
			canvas.draw_polyline(pts, Color(216.0 / 255.0, 180.0 / 255.0, 254.0 / 255.0, 0.7), 5.0, true)
	if t >= 150.0 and t < 280.0:
		var a: float = 0.15 + 0.35 * minf(1.0, (t - 150.0) / 80.0)
		DrawKit.rect(canvas, 0, 0, W, H, Color("#a855f7", a))
	if t >= 255.0 and t < 360.0:
		var a2: float = minf(1.0, (t - 255.0) / 40.0)
		DrawKit.rect(canvas, 0, 0, W, H, Color(126.0 / 255.0, 34.0 / 255.0, 206.0 / 255.0, 0.32 * a2))
	DrawKit.text_center(canvas, W / 2.0, 385, "LORD VINDEX", 28, Color("#f8fafc"))
	var line_col := Color("#d8b4fe")
	if t < 90.0:
		DrawKit.text_center(canvas, W / 2.0, 415, "AKU YANG BERTANGGUNG JAWAB ATAS SIAPA YANG MENANG.", 15, line_col)
	elif t < 255.0:
		DrawKit.text_center(canvas, W / 2.0, 415, '"LIHAT BAIK-BAIK. METEOR PUN TUNDUK PADAKU."', 15, line_col)
	else:
		DrawKit.text_center(canvas, W / 2.0, 415, '"KALI INI PERMAINAN DI TANGANKU."', 15, line_col)
	if t >= 360.0:
		DrawKit.text_center(canvas, W / 2.0, 475, "TEKAN TOMBOL APA SAJA ATAU SENTUH LAYAR", 18, Color("#ffffff"))
		DrawKit.text_center(canvas, W / 2.0, 500, "Kali ini tidak ada yang mengatur jalanku selain Vindex.", 12, Color("#a78bfa"))


## Menggambar seluruh adegan (latar lalu efek). Dipanggil DrawGame.draw_bg saat game_state == "hardIntro".
func draw_hard_intro(canvas: CanvasItem) -> void:
	draw_hard_intro_bg(canvas)
	draw_hard_intro_fx(canvas)


## Pengganti loop requestAnimationFrame(runHardIntro): dipanggil sekali per physics tick.
func run_hard_intro() -> void:
	if State.game_state != "hardIntro":
		return
	var now: float = Util.now()
	if State.hard_intro_last_time == 0:
		State.hard_intro_last_time = now
	var elapsed: float = now - State.hard_intro_last_time
	State.hard_intro_last_time = now
	if elapsed > 100.0:
		elapsed = 100.0
	State.hard_intro_timer = minf(420.0, State.hard_intro_timer + elapsed / FIXED_STEP_MS)
	# Lord Vindex = sprite (di atas latar, di bawah kilat/tint/teks)
	Sprites.show_cinematic_vindex(400, 235 + sin(State.hard_intro_timer * 0.025) * 4.0, 38.0 / 22.0)
	if State.hard_intro_timer >= 360.0:
		State.hard_intro_ready = true
