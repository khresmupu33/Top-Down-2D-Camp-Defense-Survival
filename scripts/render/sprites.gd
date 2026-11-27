extends Node
## Renderer karakter (dari render/sprites.js + sprite-templates.js + assets/css/characters/*.css).
## Di versi web karakter adalah elemen DOM yang digerakkan tiap frame; di sini semuanya
## digambar langsung dari state oleh draw_all(canvas), urutan tumpukan sama dengan z-index CSS:
## item < meteor < gadfly < killer < archer < panah < vindex < pemain.
## Desain CSS memakai skala 4x (1 piksel game = 4 piksel desain, --kg-s = .25): setiap
## karakter digambar pada koordinat desain lalu diperkecil lewat matriks transformasi.
## Animasi keyframe CSS -> rumus waktu dari _clock (detik; melambat saat Time Stop, berhenti saat jeda).

const Shapes = preload("res://scripts/render/sprites/shapes.gd")

const KS := 0.25   # --kg-s bawaan
const C_WHITE := Color(1, 1, 1, 1)
const C_CLEAR := Color(0, 0, 0, 0)

# ── status render ─────────────────────────────────────────────────────
var _cv: CanvasItem = null
var _clock := 0.0
var _last_ms := -1.0
var _slow := 1.0
var _alpha := 1.0
var _base := Transform2D.IDENTITY
var _sb := StyleBoxFlat.new()
var _cbuf := PackedColorArray()
var _tri_p := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _tri_c := PackedColorArray([C_CLEAR, C_CLEAR, C_CLEAR])
var _built := false
var _font: Font = null

# Vindex sinematik (adegan pembuka SULIT)
var _cine_on := false
var _cine_x := 0.0
var _cine_y := 0.0
var _cine_scale := 1.0

# mata pemain melirik ke arah gerak
var _pl_init := false
var _pl_px := 0.0
var _pl_py := 0.0
var _pl_lx := 0.0
var _pl_ly := 0.0

# ── cache bentuk ──────────────────────────────────────────────────────
var _st_health := []
var _st_power := []
var _st_time := []
var _st_vindex := []
var _l_player := []
var _l_target := []
var _l_gad := []
var _l_gad_frozen := []
var _l_wing_l := []
var _l_wing_r := []
var _l_kbody := []
var _l_kpurple := []
var _l_khead := []
var _l_glass := []
var _p_bolt := PackedVector2Array()
var _p_sand := PackedVector2Array()
var _p_scratch_l := PackedVector2Array()
var _p_scratch_r := PackedVector2Array()
var _p_mouth := PackedVector2Array()
var _p_tooth := PackedVector2Array()
var _p_eye_l := PackedVector2Array()
var _p_eye_r := PackedVector2Array()
var _p_arrow_head := PackedVector2Array()
var _p_arrow_fletch := PackedVector2Array()
var _p_player_inner := PackedVector2Array()
var _p_crack := PackedVector2Array()
var _p_rock_small := PackedVector2Array()
var _p_hourglass := PackedVector2Array()
var _met_small := {}   # tema (0 normal, 1 hard) -> layers
var _met_big := []


# ══════════════════════════════════════════════════════════════════════
#  API publik
# ══════════════════════════════════════════════════════════════════════

## Lord Vindex besar untuk adegan pembuka mode SULIT (x, y = pusat, scale = pengali ukuran).
func show_cinematic_vindex(x: float, y: float, scale_mul: float) -> void:
	_cine_on = true
	_cine_x = x
	_cine_y = y
	_cine_scale = scale_mul


func hide_cinematic_vindex() -> void:
	_cine_on = false


## Gambar semua karakter dari state game (dipanggil Arena tiap frame).
func draw_all(canvas: CanvasItem) -> void:
	if not _built:
		_build()
	_cv = canvas
	_tick()
	var gs: String = State.game_state
	if gs == "hardIntro":
		if _cine_on:
			_alpha = 1.0
			_draw_vindex_art(_cine_x, _cine_y, 24.0, KS * _cine_scale)
	elif gs == "ending":
		# adegan ending: hanya killer yang tersisa
		_cine_on = false
		for k in State.killers:
			_draw_killer(k)
	elif gs == "menu" or gs == "end":
		_cine_on = false
	else:
		_cine_on = false
		_draw_world()
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	_cv = null


# ══════════════════════════════════════════════════════════════════════
#  Dasar
# ══════════════════════════════════════════════════════════════════════

func _tick() -> void:
	var now: float = Util.now()
	if _last_ms < 0.0:
		_last_ms = now
	var dt: float = clampf((now - _last_ms) / 1000.0, 0.0, 0.1)
	_last_ms = now
	# --kg-time: animasi CSS melambat saat Time Stop
	_slow = 0.18 if (State.time_stop > 0 or State.vindex_time_stop > 0) else 1.0
	if not State.paused:
		_clock += dt * _slow
	if _font == null:
		_font = ThemeDB.fallback_font


## Gelombang segitiga halus 0 -> 1 -> 0 (keyframe 50% + ease-in-out) berperiode dur detik.
func _wave(dur: float) -> float:
	var p: float = fmod(_clock / dur, 1.0)
	var u: float = p * 2.0 if p < 0.5 else (1.0 - p) * 2.0
	return u * u * (3.0 - 2.0 * u)


func _ca(c: Color) -> Color:
	return Color(c.r, c.g, c.b, c.a * _alpha)


## Mulai kotak desain: pose (rotasi + skala) di titik pusat (cx, cy), lalu skala --kg-s.
func _begin_art(cx: float, cy: float, rot: float, psx: float, psy: float, s: float, aw: float, ah: float) -> void:
	var pose := Transform2D(rot, Vector2(cx, cy))
	if psx != 1.0 or psy != 1.0:
		pose = pose * Transform2D(Vector2(psx, 0.0), Vector2(0.0, psy), Vector2.ZERO)
	_base = pose * Transform2D(Vector2(s, 0.0), Vector2(0.0, s), Vector2(-aw * 0.5 * s, -ah * 0.5 * s))
	_cv.draw_set_transform_matrix(_base)


## Transformasi tambahan terhadap titik (ox, oy) pada koordinat desain (rotasi lalu skala).
func _about(ox: float, oy: float, rot: float, sx: float, sy: float) -> void:
	var m := Transform2D(rot, Vector2(ox, oy)) * Transform2D(Vector2(sx, 0.0), Vector2(0.0, sy), Vector2.ZERO) * Transform2D(Vector2.RIGHT, Vector2.DOWN, Vector2(-ox, -oy))
	_cv.draw_set_transform_matrix(_base * m)


func _reset_art() -> void:
	_cv.draw_set_transform_matrix(_base)


## Koordinat dunia (satuan piksel game) berpusat di (cx, cy).
func _root_at(cx: float, cy: float, rot: float = 0.0) -> void:
	_cv.draw_set_transform_matrix(Transform2D(rot, Vector2(cx, cy)))


## Kotak membulat dengan isi, border, dan cahaya (box-shadow) opsional.
func _box(x: float, y: float, w: float, h: float, r: float, fill: Color, bw: float = 0.0, bc: Color = C_CLEAR, sh: float = 0.0, shc: Color = C_CLEAR) -> void:
	var sb := _sb
	sb.bg_color = _ca(fill)
	sb.draw_center = fill.a > 0.0
	sb.set_corner_radius_all(int(round(r)))
	sb.corner_detail = 10
	sb.set_border_width_all(int(bw))
	sb.border_color = _ca(bc)
	sb.shadow_size = int(sh)
	sb.shadow_color = _ca(shc)
	_cv.draw_style_box(sb, Rect2(x, y, w, h))


func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	_cv.draw_rect(Rect2(x, y, w, h), _ca(c))


func _poly(pts: PackedVector2Array, c: Color) -> void:
	_cv.draw_colored_polygon(pts, _ca(c))


func _layers(layers: Array) -> void:
	for l in layers:
		var cols: PackedColorArray = l[1]
		if _alpha < 0.999:
			_cbuf.resize(cols.size())
			for i in range(cols.size()):
				var c: Color = cols[i]
				_cbuf[i] = Color(c.r, c.g, c.b, c.a * _alpha)
			_cv.draw_polygon(l[0], _cbuf)
		else:
			_cv.draw_polygon(l[0], cols)


func _circle(cx: float, cy: float, r: float, c: Color) -> void:
	_cv.draw_circle(Vector2(cx, cy), r, _ca(c))


## Cincin tepi (border-box) berjari-jari luar r dan tebal bw pada titik asal transformasi.
func _ring(r: float, bw: float, c: Color, dashed: bool = false) -> void:
	var col := _ca(c)
	var rr: float = r - bw / 2.0
	if rr <= 0.0:
		return
	if not dashed:
		_cv.draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, col, bw, true)
		return
	var n := 18
	for i in range(n):
		var a0: float = TAU * float(i) / float(n)
		_cv.draw_arc(Vector2.ZERO, rr, a0, a0 + TAU / float(n) * 0.5, 4, col, bw, true)


## Bola berbayang: pengganti radial-gradient(circle at fx fy, ...). Lingkaran-lingkaran
## yang mengecil dan bergeser ke titik fokus (fx, fy = pecahan kotak w x h).
func _sphere(cx: float, cy: float, rad: float, w: float, fxp: float, fyp: float, stops: Array) -> void:
	var focus := Vector2(cx + (fxp - 0.5) * w, cy + (fyp - 0.5) * w)
	var c0 := Vector2(cx, cy)
	var far: float = Vector2(maxf(fxp, 1.0 - fxp) * w, maxf(fyp, 1.0 - fyp) * w).length()
	var to_f: Vector2 = focus - c0
	var dist_f: float = to_f.length()
	var dir: Vector2 = to_f / dist_f if dist_f > 0.001 else Vector2.ZERO
	var n := 9
	for i in range(n):
		var k: float = float(i) / float(n)
		var rho: float = rad * (1.0 - k)
		var shift: float = minf(rad - rho, dist_f)
		var ctr: Vector2 = c0 + dir * shift
		var d: float = ctr.distance_to(focus)
		var t: float = sqrt(rho * rho + d * d) / far
		_cv.draw_circle(ctr, rho, _ca(Shapes.color_at(stops, t)))


## Segitiga ekor meteor: ujung (-tl, 0) transparan, pangkal (0, +-th/2) berwarna.
func _tail(tl: float, th: float, c: Color) -> void:
	_tri_p[0] = Vector2(-tl, 0.0)
	_tri_p[1] = Vector2(0.0, -th * 0.5)
	_tri_p[2] = Vector2(0.0, th * 0.5)
	_tri_c[0] = Color(c.r, c.g, c.b, 0.0)
	_tri_c[1] = c
	_tri_c[2] = c
	_cv.draw_polygon(_tri_p, _tri_c)


func _text(x: float, y: float, s: String, size: int, c: Color, glow: Color) -> void:
	# teks rata tengah di x; y = tengah garis (line-height 1)
	var pos := Vector2(x - 200.0, y + size * 0.35)
	if glow.a > 0.0:
		_cv.draw_string_outline(_font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, int(size * 0.2), _ca(glow))
	_cv.draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, _ca(c))


# ══════════════════════════════════════════════════════════════════════
#  Dunia
# ══════════════════════════════════════════════════════════════════════

func _draw_world() -> void:
	var lvl: String = State.level
	if State.target != null:
		_draw_target(State.target)
	if State.health != null and State.health.visible:
		_draw_health(State.health)
	if State.powerup != null and State.powerup.visible:
		_draw_power(State.powerup)
	if State.time_stop_powerup != null and State.time_stop_powerup.visible:
		_draw_timestop(State.time_stop_powerup)
	var hard: bool = lvl == "hard"
	for m in State.meteors:
		_draw_meteor(m, false, hard)
	if not hard and State.large_meteor != null and State.large_meteor.active:
		_draw_meteor(State.large_meteor, true, false)
	for g in State.gadflies:
		_draw_gadfly(g)
	for k in State.killers:
		_draw_killer(k)
	for a in State.archers:
		if not a.dead:
			_draw_archer(a)
	for q in State.archer_arrows:
		_draw_arrow(q)
	if hard and State.lord_vindex != null and not State.lord_vindex.dead:
		_draw_vindex(State.lord_vindex)
	if State.player != null:
		# urutan poin 25: pemain disembunyikan
		if hard and State.hard25_sequence_active and State.hard25_sequence_timer >= 150 and State.hard25_sequence_timer < 245:
			return
		_draw_player(State.player)


# ── item ──────────────────────────────────────────────────────────────

func _draw_target(t) -> void:
	_alpha = 1.0
	_begin_art(t.x + t.w / 2.0, t.y + t.h / 2.0, 0.0, 1.0, 1.0, KS, 88.0, 88.0)
	var g: float = _wave(1.6)
	_box(0, 0, 88, 88, 12, Color("#d1d5db"), 0, C_CLEAR, lerpf(24.0, 42.0, g), Color(1, 1, 1, lerpf(0.30, 0.55, g)))
	_box(6, 6, 76, 76, 6, C_WHITE)
	_layers(_l_target)
	_cv.draw_arc(Vector2(44, 44), 19.0, 0.0, TAU, 32, _ca(Color("#9ca3af")), 6.0, true)
	_box(36, 36, 16, 16, 8, Color("#ef4444"), 0, C_CLEAR, 8, Color(0.94, 0.27, 0.27, 0.4))


func _draw_health(h) -> void:
	_alpha = 1.0
	_begin_art(h.x + h.w / 2.0, h.y + h.h / 2.0, 0.0, 1.0, 1.0, KS, 100.0, 100.0)
	var sc: float = 1.0 + 0.1 * _wave(1.3)
	_about(50, 50, 0.0, sc, sc)
	_box(0, 0, 100, 100, 50, Color("#bbf7d0"), 0, C_CLEAR, 32, Color(0.13, 0.77, 0.37, 0.5))
	_sphere(50, 50, 43, 86, 0.34, 0.28, _st_health)
	_reset_art()
	_box(42, 18, 16, 64, 4, C_WHITE, 0, C_CLEAR, 6, Color(1, 1, 1, 0.4))
	_box(18, 42, 64, 16, 4, C_WHITE, 0, C_CLEAR, 6, Color(1, 1, 1, 0.4))


func _draw_power(p) -> void:
	_alpha = 1.0
	_begin_art(p.x + p.w / 2.0, p.y + p.h / 2.0, 0.0, 1.0, 1.0, KS, 104.0, 104.0)
	var sc: float = 1.0 + 0.1 * _wave(1.0)
	_about(52, 52, 0.0, sc, sc)
	_box(0, 0, 104, 104, 52, Color("#fff7ae"), 0, C_CLEAR, 42, Color(0.98, 0.8, 0.08, 0.55))
	_sphere(52, 52, 45, 90, 0.34, 0.28, _st_power)
	_reset_art()
	_poly(_p_bolt, Color("#4a2c00"))
	_text(52, 142, "KILL", 40, C_WHITE, Color(0.98, 0.8, 0.08, 0.45))


func _draw_timestop(p) -> void:
	_alpha = 1.0
	_begin_art(p.x + p.w / 2.0, p.y + p.h / 2.0, 0.0, 1.0, 1.0, KS, 112.0, 112.0)
	var sc: float = 1.0 + 0.1 * _wave(1.5)
	_about(56, 56, 0.0, sc, sc)
	_box(0, 0, 112, 112, 56, Color("#93c5fd"), 0, C_CLEAR, 48, Color(0.38, 0.65, 0.98, 0.55))
	_sphere(56, 56, 49, 98, 0.34, 0.28, _st_time)
	# jam pasir berbalik tiap 1,5 detik (steps)
	_about(56, 56, PI if fmod(_clock, 3.0) >= 1.5 else 0.0, 1.0, 1.0)
	_layers(_l_glass)
	_reset_art()
	_poly(_p_sand, Color(0.984, 0.749, 0.141, 0.95))


# ── meteor ────────────────────────────────────────────────────────────

func _draw_meteor(m, big: bool, hard: bool) -> void:
	_alpha = 1.0
	var cx: float = m.x + m.w / 2.0
	var cy: float = m.y + m.h / 2.0
	var theme: int = 1 if hard else 0
	# ekor mengikuti arah gerak
	var dist := 0.0
	var ang: float = atan2(m.vy, m.vx)
	if m.trail.size() > 0:
		var t0: Dictionary = m.trail[0]
		dist = Vector2(cx - t0.x, cy - t0.y).length()
		if dist > 0.5:
			ang = atan2(cy - t0.y, cx - t0.x)
	_root_at(cx, cy, ang)
	if big:
		var tl: float = maxf(30.0, dist * 1.4)
		var col := Color("#a855f7") if hard else Color("#ef4444")
		_tail(tl, 46.0, Color(col.r, col.g, col.b, 0.45))
	else:
		var tl2: float = maxf(8.0, dist * 1.1)
		var col2 := Color("#a855f7") if hard else Color("#f59e0b")
		_tail(tl2, m.w * 0.5, Color(col2.r, col2.g, col2.b, 0.55))
	if not big:
		_begin_art(cx, cy, m.rotation, 1.0, 1.0, m.w * 1.3, 1.0, 1.0)
		_layers(_met_small[theme])
		var cc := Color("#fef3c7")
		_cv.draw_circle(Vector2(0.45, 0.48), 0.14, Color(cc.r, cc.g, cc.b, 0.9))
	else:
		_begin_art(cx, cy, m.rotation, 1.0, 1.0, m.w * 1.2, 1.0, 1.0)
		_layers(_met_big)
		# kawah: [x, y, w] dalam persen kotak
		var cr := [[0.22, 0.22, 0.23], [0.60, 0.36, 0.18], [0.38, 0.58, 0.27]]
		for c in cr:
			var rr: float = c[2] / 2.0
			var pc := Vector2(c[0] + rr, c[1] + rr)
			_cv.draw_circle(pc, rr, Color("#6b3f2b"))
			_cv.draw_circle(pc + Vector2(-rr * 0.18, -rr * 0.2), rr * 0.62, Color("#8a5238"))
		# retakan menyala (kecerahan berdenyut)
		var b: float = 1.0 + 0.3 * _wave(2.2)
		var crack: Color = Color("#c084fc") if hard else Color("#f97316")
		_cv.draw_colored_polygon(_p_crack, Color(minf(1.0, crack.r * b), minf(1.0, crack.g * b), minf(1.0, crack.b * b), 1.0))


# ── gadfly ────────────────────────────────────────────────────────────

func _draw_gadfly(g) -> void:
	var frozen: bool = g.freeze > 0
	_alpha = 0.45 if (g.hit_anim > 0 and int(floor(g.hit_anim / 3.0)) % 2 == 0) else 1.0
	_begin_art(g.x + g.w / 2.0, g.y + g.h / 2.0, g.rotation, 1.0, 1.0, KS, 128.0, 96.0)
	# sayap mengepak (skala X di sisi dalam)
	var flap: float = 1.0 if frozen else 1.0 - 0.45 * _wave(0.16)
	_about(34, 48, 0.0, flap, 1.0)
	_layers(_l_wing_l)
	_box(6, 18, 28, 60, 14, C_CLEAR, 3, Color(1, 1, 1, 0.55))
	_about(94, 48, 0.0, flap, 1.0)
	_layers(_l_wing_r)
	_box(94, 18, 28, 60, 14, C_CLEAR, 3, Color(1, 1, 1, 0.55))
	# antena
	_about(43, 20, deg_to_rad(-18.0), 1.0, 1.0)
	_box(40, 0, 6, 20, 3, Color("#7f1d1d"))
	_about(85, 20, deg_to_rad(18.0), 1.0, 1.0)
	_box(82, 0, 6, 20, 3, Color("#7f1d1d"))
	_reset_art()
	# badan
	if frozen:
		_box(24, 8, 80, 80, 12, Color("#334155"), 0, C_CLEAR, 20, Color(0.58, 0.64, 0.72, 0.45))
		_layers(_l_gad_frozen)
		_rect(29, 13, 70, 7, Color(1, 1, 1, 0.25))
		_rect(29, 13, 7, 70, Color(1, 1, 1, 0.25))
		_rect(29, 75, 70, 8, Color(0, 0, 0, 0.25))
		_rect(91, 13, 8, 70, Color(0, 0, 0, 0.25))
	else:
		_box(24, 8, 80, 80, 12, Color("#7e22ce"), 0, C_CLEAR, 22, Color(0.94, 0.27, 0.27, 0.4))
		_layers(_l_gad)
		_rect(29, 13, 70, 7, Color(1, 1, 1, 0.18))
		_rect(29, 13, 7, 70, Color(1, 1, 1, 0.18))
		_rect(29, 75, 70, 8, Color(0, 0, 0, 0.22))
		_rect(91, 13, 8, 70, Color(0, 0, 0, 0.22))
	# mata
	var ink := Color("#111827")
	var tooth := Color("#f8fafc")
	_box(40, 28, 16, 16, 3, ink)
	_rect(44, 32, 4, 4, tooth)
	_box(72, 28, 16, 16, 3, ink)
	_rect(76, 32, 4, 4, tooth)
	# mulut bertaring
	_box(44, 60, 40, 12, 3, ink)
	_poly(PackedVector2Array([Vector2(50, 60), Vector2(58, 60), Vector2(54, 68)]), tooth)
	_poly(PackedVector2Array([Vector2(70, 60), Vector2(78, 60), Vector2(74, 68)]), tooth)


# ── killer ────────────────────────────────────────────────────────────

func _draw_killer(k) -> void:
	var cx: float = k.x + k.w / 2.0
	var cy: float = k.y + k.h / 2.0
	var rot := 0.0
	var psx := 1.0
	var psy := 1.0
	var sad := false
	_alpha = 1.0
	if k.disintegrating:
		var p: float = k.disintegrate_timer / 40.0
		rot = (1.0 - p) * 2.0
		psx = p
		psy = p
		_alpha = clampf(p, 0.0, 1.0)
		if _alpha <= 0.0 or p <= 0.0:
			return
	elif k.loading > 0:
		# mengisi serangan: cincin + badan berkedip
		var progress: float = 1.0 - k.loading / float(Config.KILLER_LOAD_TIME)
		var blink: int = int(floor(k.loading / 8.0)) % 2
		var pulse: float = sin(k.pulse) * 3.0
		_root_at(cx, cy)
		_ring(15.0 + pulse + progress * 12.0, 2.0, Color("#ff1111") if blink == 1 else Color(0.47, 0, 0, 0.25))
		var pr: float = 23.0 + pulse
		if progress > 0.0:
			_cv.draw_arc(Vector2.ZERO, pr - 1.5, -PI / 2.0, -PI / 2.0 + TAU * clampf(progress, 0.0, 1.0), 40, Color("#ef4444"), 3.0, true)
		if blink == 0:
			return
	else:
		if k.disappointed > 0:
			var sd: float = sin(k.disappointed_phase) * 0.12
			rot = k.tilt + 0.22 + sd
			psx = 0.88
			psy = 1.1
			sad = true
		else:
			rot = k.tilt
			psx = k.scale_x
			psy = k.scale_y
	_begin_art(cx, cy, rot, psx, psy, KS, 120.0, 120.0)
	_killer_art(k, sad)


func _killer_art(k, sad: bool) -> void:
	# badan
	_box(12, 16, 96, 92, 6, Color("#210307"), 0, C_CLEAR, 18, Color(0.5, 0, 0, 0.45))
	_layers(_l_kbody)
	_layers(_l_kpurple)
	_cv.draw_rect(Rect2(24, 24, 72, 76), _ca(Color(0, 0, 0, 0.35)), false, 3.0)
	_layers(_l_khead)
	_poly(_p_scratch_l, Color("#dc2626"))
	_poly(_p_scratch_r, Color("#dc2626"))
	# mata merah menyala (kecerahan berdenyut)
	var b: float = 1.0 + 0.35 * _wave(1.1)
	var eye := Color(minf(1.0, b), minf(1.0, 0.067 * b), minf(1.0, 0.067 * b), 1.0)
	_box(32, 48, 20, 12, 0, eye, 0, C_CLEAR, 20, Color(1, 0, 0, 0.5))
	_box(68, 48, 20, 12, 0, eye, 0, C_CLEAR, 20, Color(1, 0, 0, 0.5))
	_rect(44, 48, 8, 12, Color("#050000"))
	_rect(68, 48, 8, 12, Color("#050000"))
	# mulut + gigi
	_poly(_p_mouth, Color("#020000"))
	var tooth := Color("#f8fafc")
	for i in range(4):
		_cv.draw_set_transform_matrix(_base * Transform2D(Vector2.RIGHT, Vector2.DOWN, Vector2(12.8 * i, 0.0)))
		_poly(_p_tooth, tooth)
	_reset_art()
	# darah
	var blood := Color("#dc2626")
	_box(24, 88, 8, 12, 3, blood)
	_box(88, 92, 8, 8, 3, blood)
	# wajah kecewa
	if sad:
		_cv.draw_arc(Vector2(60, 76), 13.0, PI, TAU, 16, _ca(Color("#fca5a5")), 6.0, true)
	# kilatan terkena
	if k.hit_flash > 0:
		_cv.draw_rect(Rect2(12, 12, 96, 96), _ca(Color("#fca5a5")), false, 8.0)
	# suasana: panik "!" / tertawa "HA!"
	var mood := 0
	var bob := 0.0
	var spin := 0.0
	if k.panic:
		mood = 1
		bob = sin(k.panic_phase * 2.4) * 12.0
		spin = k.panic_phase
	elif k.celebrating > 0:
		mood = 2
		bob = sin(k.celebrating_phase) * 16.0
		spin = k.celebrating_phase
	if mood != 0:
		var len_: float = 20.0 if mood == 1 else 16.0
		var gold := Color("#facc15")
		for i in range(4):
			var a: float = spin + float(i) * PI / 2.0
			var d := Vector2(cos(a), sin(a))
			var p0 := Vector2(60, 60) + d * 60.0
			var p1 := Vector2(60, 60) + d * (60.0 + len_)
			_cv.draw_line(p0, p1, _ca(gold), 8.0, true)
			_cv.draw_circle(p0, 4.0, _ca(gold))
			_cv.draw_circle(p1, 4.0, _ca(gold))
		_text(60, -16 + bob, "!" if mood == 1 else "HA!", 48 if mood == 1 else 44, gold, Color(0.98, 0.8, 0.08, 0.3))


# ── archer & panah ────────────────────────────────────────────────────

func _draw_archer(a) -> void:
	_alpha = 1.0
	var cx: float = a.x + a.w / 2.0
	var cy: float = a.y + a.h / 2.0
	var sa: float = a.spawn_anim
	_root_at(cx, cy)
	# cincin kemunculan
	for i in range(3):
		var r: float = 18.0 + 35.0 * (1.0 - sa) - float(i) * 12.0
		if sa > 0.0 and r > 8.0:
			_ring(r + sin(a.phase + r) * 3.0, 2.0, Color(0.984, 0.573, 0.235, 0.65 * (1.0 - sa)))
	var ta: float = a.teleport_anim
	if ta > 0.0:
		_ring(14.0 + 30.0 * ta, 3.0, Color(0.96, 0.62, 0.04, ta * 0.7))
	var spawn_scale: float = 0.35 + 0.65 * (1.0 - sa)
	var tele_scale: float = 1.0 + ta * 0.45
	var sc: float = spawn_scale * tele_scale
	_begin_art(cx, cy, a.aim, sc, sc, KS, 128.0, 128.0)
	var br: float = 1.0 + 0.06 * _wave(1.2)
	_about(64, 64, 0.0, br, br)
	_box(16, 16, 96, 96, 48, Color("#7e22ce"), 8, Color("#fdba74"), 22, Color(0.98, 0.45, 0.09, 0.4))
	_reset_art()
	# busur: busur 138 derajat di sisi bidik
	_cv.draw_arc(Vector2(72, 64), 28.0, deg_to_rad(-69.0), deg_to_rad(69.0), 20, _ca(Color("#7e22ce")), 8.0, true)
	_box(72, 52, 20, 24, 5, Color("#fee2e2"))
	# label AIM tetap tegak
	if a.loading > 0:
		_root_at(cx, cy)
		var pos := Vector2(-100.0, -17.0 + 11.0 * 0.35)
		_cv.draw_string_outline(_font, pos, "AIM", HORIZONTAL_ALIGNMENT_CENTER, 200.0, 11, 3, Color(0.98, 0.75, 0.14, 0.3))
		_cv.draw_string(_font, pos, "AIM", HORIZONTAL_ALIGNMENT_CENTER, 200.0, 11, Color("#fbbf24"))


func _draw_arrow(q) -> void:
	_alpha = 1.0
	var lord: bool = q.get("lord", false)
	_begin_art(q.x, q.y, atan2(q.vy, q.vx), 1.0, 1.0, KS, 96.0, 48.0)
	var main := Color("#a78bfa") if lord else Color("#7e22ce")
	if lord:
		_box(10, 6, 80, 36, 14, Color(0.65, 0.55, 0.98, 0.18), 0, C_CLEAR, 8, Color(0.65, 0.55, 0.98, 0.5))
	_poly(_p_arrow_fletch, Color(main.r, main.g, main.b, 0.85))
	_box(20, 20, 52, 8, 4, Color("#7e22ce"))
	_poly(_p_arrow_head, main)


# ── Lord Vindex ───────────────────────────────────────────────────────

func _draw_vindex(l) -> void:
	_alpha = 1.0
	var cx: float = l.x + l.w / 2.0
	var cy: float = l.y + l.h / 2.0
	var glow: float = 14.0 + sin(l.phase) * 4.0 + (12.0 if l.react > 0 else 0.0)
	if l.react > 0:
		_root_at(cx, cy)
		_ring(30.0 + l.react * 0.35, 3.0, Color(0.914, 0.835, 1.0, 0.35), true)
	_draw_vindex_art(cx, cy, glow, KS)


func _draw_vindex_art(cx: float, cy: float, glow: float, s: float) -> void:
	_begin_art(cx, cy, 0.0, 1.0, 1.0, s, 176.0, 176.0)
	# aura berdenyut (skala .94 -> 1.1, pudar)
	var p: float = fmod(_clock / 2.2, 1.0)
	var e: float = p * p * (3.0 - 2.0 * p)
	var asc: float = lerpf(0.94, 1.1, e)
	_about(88, 88, 0.0, asc, asc)
	_box(-28, -28, 232, 232, 116, C_CLEAR, 6, Color(0.66, 0.33, 0.97, 0.35 * lerpf(0.9, 0.15, e)))
	_reset_art()
	# orb
	_box(0, 0, 176, 176, 88, Color("#3b0764"), 0, C_CLEAR, minf(glow * 3.2, 80.0), Color(0.66, 0.33, 0.97, 0.55))
	_sphere(88, 88, 88, 176, 0.34, 0.26, _st_vindex)
	_cv.draw_arc(Vector2(88, 88), 85.0, 0.0, TAU, 48, _ca(Color(0.75, 0.52, 0.99, 0.35)), 6.0, true)
	# mata marah
	var eye := Color("#c084fc")
	_box(40, 56, 32, 28, 0, C_CLEAR, 0, C_CLEAR, 12, Color(0.75, 0.52, 0.99, 0.5))
	_poly(_p_eye_l, eye)
	_poly(_p_eye_r, eye)
	_rect(52, 64, 12, 12, Color("#111827"))
	_rect(112, 64, 12, 12, Color("#111827"))
	# mulut bergigi
	_box(48, 116, 80, 16, 4, Color("#fef3c7"))
	var line := Color("#d8c98e")
	for i in range(5):
		_rect(60.0 + 14.0 * i, 116, 2, 16, line)
	# mahkota (kelas .kg-vindex__crown tidak punya gaya di CSS: tidak digambar)


# ── pemain ────────────────────────────────────────────────────────────

func _draw_player(p) -> void:
	_alpha = 1.0
	var cx: float = p.x + p.w / 2.0
	var cy: float = p.y + p.h / 2.0
	var prev_x: float = _pl_px if _pl_init else cx
	var prev_y: float = _pl_py if _pl_init else cy
	_pl_init = true
	_pl_px = cx
	_pl_py = cy
	var dying: bool = State.player_death_timer > 0
	var flash := false
	var rot := 0.0
	var sc := 1.0
	if dying:
		var progress: float = 1.0 - float(State.player_death_timer) / maxf(1.0, float(State.player_death_max))
		sc = maxf(0.15, 1.0 - progress * 0.85)
		rot = progress * PI * 3.5
		_alpha = maxf(0.0, 1.0 - progress)
		flash = sin(progress * PI * 12.0) > 0.0
		# cincin merah memudar
		_root_at(cx, cy)
		_ring(14.0 + progress * 28.0, 2.5, Color(0.94, 0.27, 0.27, maxf(0.0, 1.0 - progress * 0.7)))
	else:
		var dx: float = cx - prev_x
		var dy: float = cy - prev_y
		var tx: float = clampf(dx, -1.0, 1.0) * 5.0
		var ty: float = clampf(dy, -1.0, 1.0) * 5.0
		_pl_lx += (tx - _pl_lx) * 0.35
		_pl_ly += (ty - _pl_ly) * 0.35
	var power: bool = (not dying) and State.power_active > 0
	var hurt: bool = (not dying) and State.hit_cooldown > 0 and int(floor(State.hit_cooldown / 4.0)) % 2 == 0
	_begin_art(cx, cy, rot, sc, sc, KS, 96.0, 96.0)
	if hurt:
		_alpha *= 0.35
	# aura Power Kill (di belakang badan)
	if power:
		var w: float = _wave(1.0)
		var asc: float = lerpf(0.9, 1.08, w)
		_about(48, 48, 0.0, asc, asc)
		_box(-22, -22, 140, 140, 34, C_CLEAR, 6, Color("#facc15"), 32, Color(0.98, 0.8, 0.08, 0.5))
		_cv.draw_rect(Rect2(-16, -16, 128, 128), _ca(Color(0.98, 0.8, 0.08, 0.14)), false, 12.0)
		_reset_art()
	# badan
	_box(0, 0, 96, 96, 18, Color("#052e16"), 0, C_CLEAR, 28, Color(0.13, 0.77, 0.37, 0.45))
	if flash:
		_poly(_p_player_inner, C_WHITE)
	else:
		_layers(_l_player)
	_rect(18, 5, 60, 8, Color(1, 1, 1, 0.2))
	_rect(5, 18, 8, 60, Color(1, 1, 1, 0.2))
	_rect(18, 81, 60, 10, Color(0, 0, 0, 0.25))
	_rect(81, 18, 10, 60, Color(0, 0, 0, 0.25))
	_box(14, 14, 24, 24, 7, Color(0.525, 0.937, 0.675, 0.9))
	# mata + pupil melirik
	var eye := Color("#f0fdf4")
	var pup := Color("#052e16")
	for ex in [20.0, 52.0]:
		_box(ex, 40, 24, 28, 9, eye)
		_rect(ex + 2, 64, 20, 4, Color(0, 0, 0, 0.12))
		if dying:
			_box(ex + 7, 54, 12, 4, 2, pup)
		else:
			_box(ex + 7 + _pl_lx, 48 + _pl_ly, 12, 14, 5, pup)
	_box(36, 76, 24, 6, 6, Color(0.02, 0.18, 0.09, 0.75))


# ══════════════════════════════════════════════════════════════════════
#  Cache bentuk (dibangun sekali)
# ══════════════════════════════════════════════════════════════════════

func _build() -> void:
	_built = true
	# gradien bola
	_st_health = [[0.0, Color("#86efac")], [0.52, Color("#22c55e")], [1.0, Color("#15803d")]]
	_st_power = [[0.0, Color("#fde68a")], [0.55, Color("#facc15")], [1.0, Color("#ca8a04")]]
	_st_time = [[0.0, Color("#60a5fa")], [0.58, Color("#1d4ed8")], [1.0, Color("#1e3a8a")]]
	_st_vindex = [[0.0, Color("#7e22ce")], [0.58, Color("#3b0764")], [1.0, Color("#1e0338")]]
	# pemain
	_p_player_inner = Shapes.rr_pts(5, 5, 86, 86, 13)
	_l_player = Shapes.lin_layers(_p_player_inner, 0, 0, 96, 96, 145.0, [[0.0, Color("#4ade80")], [0.48, Color("#16a34a")], [1.0, Color("#14532d")]])
	# target
	_l_target = Shapes.lin_layers(Shapes.rr_pts(12, 12, 64, 64, 0), 0, 0, 88, 88, 145.0, [[0.0, Color("#ffffff")], [0.55, Color("#f3f4f6")], [1.0, Color("#e5e7eb")]])
	# item
	_p_bolt = Shapes.pct_pts(26, 14, 52, 76, [70, 0, 0, 54, 42, 54, 22, 100, 100, 36, 58, 36])
	_p_sand = Shapes.pct_pts(46, 62, 20, 20, [50, 0, 100, 100, 0, 100])
	_l_glass = Shapes.lin_layers(Shapes.pct_pts(36, 24, 40, 64, [0, 0, 100, 0, 100, 9, 58, 50, 100, 91, 100, 100, 0, 100, 0, 91, 42, 50, 0, 9]), 36, 24, 40, 64, 180.0, [[0.0, Color("#e0f2fe")], [1.0, Color("#bae6fd")]])
	# gadfly
	var gb: PackedVector2Array = Shapes.rr_pts(29, 13, 70, 70, 7)
	_l_gad = Shapes.lin_layers(gb, 24, 8, 80, 80, 145.0, [[0.0, Color("#f87171")], [0.5, Color("#ef4444")], [1.0, Color("#b91c1c")]])
	_l_gad_frozen = Shapes.lin_layers(gb, 24, 8, 80, 80, 145.0, [[0.0, Color("#94a3b8")], [0.5, Color("#64748b")], [1.0, Color("#475569")]])
	var wst := [[0.0, Color(1, 1, 1, 0.85)], [1.0, Color(1, 1, 1, 0.45)]]
	_l_wing_l = Shapes.lin_layers(Shapes.rr_pts(6, 18, 28, 60, 14), 6, 18, 28, 60, 180.0, wst)
	_l_wing_r = Shapes.lin_layers(Shapes.rr_pts(94, 18, 28, 60, 14), 94, 18, 28, 60, 180.0, wst)
	# killer
	var kb: PackedVector2Array = Shapes.rr_pts(24, 24, 72, 76, 3, 2)
	_l_kbody = Shapes.lin_layers(kb, 24, 24, 72, 76, 135.0, [[0.0, Color("#991b1b")], [0.45, Color("#450a0a")], [1.0, Color("#130205")]])
	# sorotan ungu radial (28% 22%, memudar sampai 45% jarak terjauh)
	_l_kpurple = []
	var fc := Vector2(24 + 0.28 * 72.0, 24 + 0.22 * 76.0)
	var far: float = Vector2(maxf(0.28, 0.72) * 72.0, maxf(0.22, 0.78) * 76.0).length()
	var prad: float = far * 0.45
	var rings := 6
	var prev_t := 0.0
	for i in range(rings):
		var rad: float = prad * (1.0 - float(i) / float(rings))
		var tt: float = float(i + 1) / float(rings)
		var a: float = (tt - prev_t) / (1.0 - prev_t) if prev_t < 1.0 else 1.0
		prev_t = tt
		var ep: PackedVector2Array = Shapes.ellipse_pts(fc.x, fc.y, rad, rad, 24)
		ep = Shapes.clip(ep, 1, 0, 24)
		ep = Shapes.clip(ep, -1, 0, -96)
		ep = Shapes.clip(ep, 0, 1, 24)
		ep = Shapes.clip(ep, 0, -1, -100)
		if ep.size() < 3:
			continue
		var cols := PackedColorArray()
		for _j in range(ep.size()):
			cols.append(Color(0.494, 0.133, 0.808, a))
		_l_kpurple.append([ep, cols])
	_l_khead = Shapes.lin_layers(Shapes.pct_pts(24, 4, 64, 24, [0, 100, 18.75, 0, 43.75, 83.3, 68.75, 0, 100, 100]), 24, 4, 64, 24, 180.0, [[0.0, Color("#7a1620")], [1.0, Color("#2a0508")]])
	_p_scratch_l = Shapes.pct_pts(28, 28, 12, 28, [0, 0, 35, 0, 100, 57, 35, 100, 0, 100, 55, 57])
	_p_scratch_r = Shapes.pct_pts(80, 32, 12, 28, [100, 0, 65, 0, 0, 57, 65, 100, 100, 100, 45, 57])
	_p_mouth = Shapes.pct_pts(32, 72, 56, 20, [0, 0, 100, 0, 86, 100, 14, 100])
	_p_tooth = Shapes.pct_pts(40, 72, 6.4, 12, [0, 0, 100, 0, 50, 100])
	# archer & panah
	_p_arrow_head = Shapes.pct_pts(66, 8, 26, 32, [0, 0, 100, 50, 0, 100, 22, 50])
	_p_arrow_fletch = Shapes.pct_pts(6, 12, 22, 24, [0, 0, 55, 0, 100, 50, 55, 100, 0, 100, 40, 50])
	# vindex
	_p_eye_l = Shapes.pct_pts(40, 56, 32, 28, [0, 0, 100, 35, 100, 100, 0, 100])
	_p_eye_r = Shapes.pct_pts(104, 56, 32, 28, [0, 35, 100, 0, 100, 100, 0, 100])
	# meteor kecil (kotak satuan 0..1)
	_p_rock_small = Shapes.pct_pts(0, 0, 1, 1, [50, 0, 87, 42, 73, 92, 18, 88, 5, 38])
	_met_small[0] = Shapes.lin_layers(_p_rock_small, 0, 0, 1, 1, 145.0, [[-0.1, Color("#fed7aa")], [0.35, Color("#fb923c")], [1.0, Color("#c2410c")]])
	_met_small[1] = Shapes.lin_layers(_p_rock_small, 0, 0, 1, 1, 145.0, [[-0.1, Color("#fed7aa")], [0.35, Color("#7e22ce")], [1.0, Color("#3b0764")]])
	# meteor besar
	var big_rock: PackedVector2Array = Shapes.pct_pts(0, 0, 1, 1, [50, 5, 82, 12, 94, 46, 85, 82, 58, 96, 26, 90, 8, 54, 22, 18])
	_met_big = Shapes.lin_layers(big_rock, 0, 0, 1, 1, 145.0, [[0.0, Color("#5a3a2c")], [0.55, Color("#3f281f")], [1.0, Color("#26160f")]])
	_p_crack = Shapes.pct_pts(0, 0, 1, 1, [29, 46, 47, 57, 58, 42, 72.5, 60, 72.5, 63.5, 58, 46, 47, 60.5, 29, 49.5])
