extends Node
## BOT-X: pemain AI yang jago & pintar (mode DALANG), dari modes/dalang/bot.js.
##
## Cara berpikir (tiap BOT_EVERY frame):
##   1. Foto semua bahaya: Killer, panah (+ panah yang AKAN ditembakkan Archer), meteor,
##      lingkaran meteor besar, laser, jalur hujan, Time Stop dalang.
##   2. Pilih tujuan: Nyawa / Power Kill / Time Stop / buru Killer / buru Archer (saat Time Stop), atau berkeliling.
##      BOT boleh menembus dinding; jarak & simulasi memakai ruang melingkar.
##   3. Simulasikan 81 rencana gerak (2 arah berurutan, 46 frame ke depan) memakai
##      aturan fisika yang SAMA dengan engine, lalu pilih yang biayanya terkecil.
##
## Kelemahan yang bisa dimanfaatkan: horizon pendek, jalur keliling bisa ditebak,
## tidak melihat Time Stop dalang sebelum dipakai, dan tidak bisa menembus tembok
## Killer + laser + meteor yang menutup semua celah.
## Status dalang (dl) dibaca dari DalangFlow.dl.

const BOT_DIRS := [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]]
const BOT_H := 46        # horizon simulasi (frame)
const BOT_L1 := 13       # lama arah pertama
const BOT_EVERY := 4     # berpikir tiap N frame
const BOT_LAG := 2       # waktu reaksi: keputusan baru berlaku N frame kemudian
const BOT_SPEED := 3.95  # px/frame lurus (pemain 4). Diagonal dinormalkan
const DIAG := 0.7071
const BOT_MARGIN := 2    # jarak aman (reaksi & percepatan tidak instan)
const BOT_LAPSE_CHANCE := 0.006
const BOT_LAPSE_FRAMES := 16   # sesekali lengah sesaat, seperti manusia
const BOT_MAXK := 24
const BOT_MAXA := 96
const BOT_MAXM := 44
const BOT_MAXR := 16
const BOT_MAXZ := 3
const BOT_MAXL := 4
const BOT_MAXRN := 4
const BOT_KILLER_SPEED := 2.5

## Pikiran BOT (dibaca/di-reset oleh DalangFlow). Kunci snake_case dari botMind JS.
var bot_mind := {
	"pending": null, "lapse": 0, "vx": 0.0, "vy": 0.0, "dir": 0,
	"goal_type": "roam", "goal_x": 400.0, "goal_y": 300.0, "goal_r": 18.0,
	"lock": 0, "think": 0, "label": "BERKELILING", "alert": 0.0,
	"roam_at": 0, "wrap_fx": 0, "cost": 0.0,
}

# buffer dasar (diisi tiap berpikir) & buffer kerja (disalin tiap simulasi), dialokasikan sekali
var _KB := PackedFloat64Array()
var _K := PackedFloat64Array()
var _AB := PackedFloat64Array()
var _A := PackedFloat64Array()
var _RB := PackedFloat64Array()
var _R := PackedFloat64Array()
var _MB := PackedFloat64Array()
var _M := PackedFloat64Array()
var _ZB := PackedFloat64Array()
var _LB := PackedFloat64Array()
var _NB := PackedFloat64Array()
var _zf := PackedByteArray()
var _lf := PackedByteArray()

# BS: foto dunia
var _rage: float = 0.0
var _nK := 0
var _nA := 0
var _nR := 0
var _nM := 0
var _nZ := 0
var _nL := 0
var _nN := 0
var _px := 0.0
var _py := 0.0
var _cd := 0.0
var _ts := 0.0
var _power := 0.0
var _freeze := 0.0
var _life_mult := 1.0
var _gx := 0.0
var _gy := 0.0
var _gr := 18.0
var _gw := 1.12
var _roam := false
var _lK := 1.0
var _lA := 1.0
var _lM := 1.0
var _lB := 1.0
var _lL := 1.0
var _kR := 100.0
var _hunting := false

# tembus dinding: periode lingkaran (sama dengan wrap_obj, pada titik tengah)
const BOT_PX := Config.WIDTH + 20
const BOT_PY := Config.HEIGHT + 20


func _init() -> void:
	_KB.resize(BOT_MAXK * 7)
	_K.resize(BOT_MAXK * 7)
	_AB.resize(BOT_MAXA * 5)
	_A.resize(BOT_MAXA * 5)
	_RB.resize(BOT_MAXR * 3)
	_R.resize(BOT_MAXR * 3)
	_MB.resize(BOT_MAXM * 6)
	_M.resize(BOT_MAXM * 6)
	_ZB.resize(BOT_MAXZ * 3)
	_LB.resize(BOT_MAXL * 6)
	_NB.resize(BOT_MAXRN * 4)
	_zf.resize(BOT_MAXZ)
	_lf.resize(BOT_MAXL)


## Reset pikiran BOT (dipakai DalangFlow saat mulai).
func bot_reset() -> void:
	var m := bot_mind
	m.dir = 0
	m.pending = null
	m.lapse = 0
	m.vx = 0.0
	m.vy = 0.0
	m.think = 0
	m.goal_type = "roam"
	m.goal_x = 400.0
	m.goal_y = 300.0
	m.roam_at = 0
	m.wrap_fx = 0
	m.lock = 0
	m.alert = 999.0


func bot_wrap_d(a: float, b: float, period: float) -> float:
	var d := absf(a - b)
	return period - d if d > period / 2.0 else d


## Jarak terdekat dua titik, boleh lewat dinding.
func bot_dist(x1: float, y1: float, x2: float, y2: float) -> float:
	return Vector2(bot_wrap_d(x1, x2, BOT_PX), bot_wrap_d(y1, y2, BOT_PY)).length()


## Foto kondisi dunia dari sudut pandang BOT. Mengembalikan ancaman (0 = aman).
func bot_snapshot() -> float:
	var dl: Dictionary = DalangFlow.dl
	var pl: Dictionary = State.player
	var bx: float = pl.x + pl.w / 2.0
	var by: float = pl.y + pl.h / 2.0
	_px = bx
	_py = by
	_cd = maxf(0, State.hit_cooldown)
	_ts = maxf(0, State.time_stop)
	_power = maxf(0, State.power_active)
	_freeze = dl.freeze if dl.freeze > 0 else 0.0
	_rage = 0.0 if dl.freeze > 0 else dl.rage
	_life_mult = 1.0 if State.lives >= 3 else (1.4 if State.lives == 2 else 2.4)
	_lK = dl.learn.killer
	_lA = dl.learn.arrow
	_lM = dl.learn.meteor
	_lB = dl.learn.big
	_lL = dl.learn.laser
	# makin waspada terhadap Killer bila Time Stop dalang siap dipakai
	_kR = 100.0 * _lK * (1.45 if DalangSkills.dl_freeze_ready() else 1.0)

	var threat := 0.0
	var near := 1e9
	var power_on: bool = State.power_active > 0
	var gfreeze: float = State.global_freeze

	# Killer (terdekat dulu)
	var n := 0
	var ks: Array = []
	for k in State.killers:
		if not k.disintegrating:
			ks.append(k)
	ks.sort_custom(func(a, b): return Vector2(a.x - bx, a.y - by).length() < Vector2(b.x - bx, b.y - by).length())
	for i in range(ks.size()):
		if n >= BOT_MAXK:
			break
		var k: Dictionary = ks[i]
		var o := n * 7
		var idle: float = maxf(gfreeze, maxf(k.celebrating if k.celebrating > 0 else 0.0, k.disappointed if k.disappointed > 0 else 0.0))
		_KB[o] = k.x + 10
		_KB[o + 1] = k.y + 10
		_KB[o + 2] = k.loading if k.loading > 0 else 0.0
		_KB[o + 3] = idle
		var kb: bool = k.knockback_timer > 0
		_KB[o + 4] = k.knockback_x if kb else 0.0
		_KB[o + 5] = k.knockback_y if kb else 0.0
		_KB[o + 6] = k.knockback_timer if kb else 0.0
		n += 1
		if k.loading <= 0 and not power_on:
			var d: float = Vector2(k.x + 10 - bx, k.y + 10 - by).length()
			near = minf(near, d)
			if d < 250:
				threat += 1 + (1 if d < 150 else 0)
	_nK = n

	# Panah yang sudah terbang
	n = 0
	var arrows: Array = State.archer_arrows
	for i in range(arrows.size()):
		if n >= BOT_MAXA - 24:
			break
		var q: Dictionary = arrows[i]
		var o := n * 5
		_AB[o] = q.x + 4
		_AB[o + 1] = q.y + 4
		_AB[o + 2] = q.vx
		_AB[o + 3] = q.vy
		_AB[o + 4] = 1
		n += 1
		var d: float = Vector2(q.x - bx, q.y - by).length()
		if d < 170:
			threat += 0.4
		near = minf(near, d - 20)
	_nA = n
	# slot kosong untuk panah yang akan ditembakkan di masa depan
	for i in range(n, BOT_MAXA):
		_AB[i * 5 + 4] = 0

	# Archer (jadwal tembak)
	n = 0
	var ar: Array = []
	for q in State.archers:
		if not q.dead:
			ar.append(q)
	ar.sort_custom(func(p, q): return Vector2(p.x - bx, p.y - by).length() < Vector2(q.x - bx, q.y - by).length())
	for a in ar:
		if n >= BOT_MAXR:
			break
		var o := n * 3
		_RB[o] = a.x + 11
		_RB[o + 1] = a.y + 11
		_RB[o + 2] = (a.loading if a.loading > 0 else 0.0) + maxf(0, a.fire)
		n += 1
	_nR = n

	# Meteor kecil (terdekat dulu)
	n = 0
	var ms: Array = State.meteors
	if ms.size() > BOT_MAXM:
		ms = ms.duplicate()
		ms.sort_custom(func(a, b): return Vector2(a.x - bx, a.y - by).length() < Vector2(b.x - bx, b.y - by).length())
	for i in range(ms.size()):
		if n >= BOT_MAXM:
			break
		var m: Dictionary = ms[i]
		var o := n * 6
		_MB[o] = m.x + m.w / 2.0
		_MB[o + 1] = m.y + m.h / 2.0
		_MB[o + 2] = m.vx
		_MB[o + 3] = m.vy
		_MB[o + 4] = m.w / 2.0
		_MB[o + 5] = 1
		n += 1
		var d: float = Vector2(m.x - bx, m.y - by).length()
		if d < 180:
			threat += 0.3
		near = minf(near, d - m.w)
	_nM = n

	# Meteor besar: kapan menghantam & di mana
	n = 0
	var lmw = State.large_meteor_warning
	var lm = State.large_meteor
	if State.large_meteor_pending and lmw != null:
		_ZB[0] = lmw.x
		_ZB[1] = lmw.y
		_ZB[2] = ceilf(lmw.life) + ceilf((lmw.y + 150) / Config.LARGE_METEOR_SPEED)
		n = 1
	elif lm != null and lm.active:
		var cx: float = lm.x + lm.w / 2.0
		var cy: float = lm.y + lm.h / 2.0
		_ZB[0] = lm.target_x
		_ZB[1] = lm.target_y
		_ZB[2] = maxf(1, ceilf(Vector2(lm.target_x - cx, lm.target_y - cy).length() / Config.LARGE_METEOR_SPEED))
		n = 1
	if n:
		var d: float = Vector2(_ZB[0] - bx, _ZB[1] - by).length()
		if d < 230:
			threat += 1.2
	_nZ = n

	# Laser
	n = 0
	for L in dl.lasers:
		if n >= BOT_MAXL or L.hit:
			continue
		var o := n * 6
		_LB[o] = L.x
		_LB[o + 1] = L.y
		_LB[o + 2] = cos(L.angle)
		_LB[o + 3] = sin(L.angle)
		_LB[o + 4] = maxf(0, L.warn)
		_LB[o + 5] = DalangConfig.DL.LASER_FIRE if L.warn > 0 else maxf(0, L.fire)
		n += 1
		if DalangSkills.dl_laser_dist(L, bx, by) < 120:
			threat += 1.2
	_nL = n

	# jalur hujan
	n = 0
	for r in dl.rains:
		if n >= BOT_MAXRN:
			continue
		var o := n * 4
		_NB[o] = r.x
		_NB[o + 1] = DalangConfig.DL.RAIN_HALF_WIDTH + 18
		_NB[o + 2] = maxf(0, r.warn)
		_NB[o + 3] = maxf(0, r.warn) + maxf(0, r.left) + 40
		n += 1
		if absf(bx - r.x) < DalangConfig.DL.RAIN_HALF_WIDTH + 20:
			threat += 1
	_nN = n

	bot_mind.alert = near
	return threat


## Pengali 0..1: seberapa aman sebuah titik (item) dari bencana yang sedang/akan aktif. 1 = aman.
func bot_spot_safety(x: float, y: float) -> float:
	var dl: Dictionary = DalangFlow.dl
	var s := 1.0
	for L in dl.lasers:
		if not L.hit and DalangSkills.dl_laser_dist(L, x, y) < DalangConfig.DL.LASER_WIDTH / 2.0 + 28:
			s *= 0.3
	for r in dl.rains:
		if absf(x - r.x) < DalangConfig.DL.RAIN_HALF_WIDTH + 12:
			s *= 0.45
	var lmw = State.large_meteor_warning
	var lm = State.large_meteor
	if State.large_meteor_pending and lmw != null and absf(x - lmw.x) < 90 and absf(y - lmw.y) < 90:
		s *= 0.3
	elif lm != null and lm.active and absf(x - lm.target_x) < 90 and absf(y - lm.target_y) < 90:
		s *= 0.3
	for k in State.killers:
		if k.disintegrating or k.loading > 0 or State.power_active > 0:
			continue
		if Vector2(k.x + 10 - x, k.y + 10 - y).length() < 70:
			s *= 0.6   # Killer berjaga di dekat item
	return s


## Pilih tujuan: nilai tinggi & dekat menang.
func bot_choose_goal(threat: float) -> void:
	var dl: Dictionary = DalangFlow.dl
	var pl: Dictionary = State.player
	var bx: float = pl.x + pl.w / 2.0
	var by: float = pl.y + pl.h / 2.0
	var m := bot_mind
	_hunting = false

	# Time Stop BOT aktif: Archer melambat, tak bisa kabur, dan mati bila disentuh: buru Archer terdekat
	# yang masih terkejar sebelum Time Stop habis.
	if State.time_stop > 30:
		var spd: float = BOT_SPEED * (DalangConfig.DL.RAGE_SPEED if dl.rage > 0 else 1.0)
		var best_a = null
		var bd := 1e9
		for a in State.archers:
			if a.dead:
				continue
			var d := bot_dist(a.x + a.w / 2.0, a.y + a.h / 2.0, bx, by)
			if d / spd + 8 > State.time_stop:
				continue   # tak terkejar sebelum Time Stop habis
			if d < bd:
				bd = d
				best_a = a
		if best_a != null:
			m.goal_type = "huntA"
			m.goal_x = best_a.x + best_a.w / 2.0
			m.goal_y = best_a.y + best_a.h / 2.0
			m.goal_r = 20.0
			m.label = "BURU ARCHER"
			return

	# Power Kill aktif: buru Killer terdekat selama waktunya cukup
	if State.power_active > 80:
		var best_k = null
		var bd2 := 1e9
		for k in State.killers:
			if k.disintegrating or k.loading > 0:
				continue
			var d := bot_dist(k.x + 10, k.y + 10, bx, by)
			if d < bd2:
				bd2 = d
				best_k = k
		if best_k != null and bd2 < 420:
			m.goal_type = "hunt"
			m.goal_x = best_k.x + 10
			m.goal_y = best_k.y + 10
			m.goal_r = 20.0
			m.label = "BERBURU KILLER"
			_hunting = true
			return

	var cands: Array = []
	var live_k := 0
	for k in State.killers:
		if not k.disintegrating:
			live_k += 1
	var live_a := 0
	for a in State.archers:
		if not a.dead:
			live_a += 1
	var foes := live_k + live_a
	# Semua item yang muncul SELALU diincar; yang berubah hanya seberapa ngotot (nilai).
	# Item yang sedang tertutup bencana dinilai rendah dulu, lalu diincar lagi begitu aman.
	var health = State.health
	var powerup = State.powerup
	var tsp = State.time_stop_powerup
	if health != null and health.visible and State.lives < 3:
		var v: float = (3.4 if State.lives <= 1 else 2.1) * bot_spot_safety(health.x + 12.5, health.y + 12.5)
		cands.append({"type": "health", "x": health.x + 12.5, "y": health.y + 12.5, "r": 21.0, "val": v, "label": "MENCARI NYAWA"})
	if powerup != null and powerup.visible and State.power_active <= 0:
		var pv := 1.2
		if foes >= 3:
			pv = 2.5
		elif foes == 2:
			pv = 2.1
		elif foes == 1:
			pv = 1.7
		var v: float = pv * bot_spot_safety(powerup.x + 13, powerup.y + 13)
		cands.append({"type": "power", "x": powerup.x + 13, "y": powerup.y + 13, "r": 22.0, "val": v, "label": "AMBIL POWER KILL"})
	if tsp != null and tsp.visible and State.time_stop <= 0:
		var v := 1.5
		if threat >= 2.6:
			v = 2.7
		elif State.lives <= 1 and threat >= 1:
			v = 2.4
		elif DalangSkills.dl_freeze_ready() and threat >= 1.6:
			v = 2.0
		if live_a > 0:
			v += 0.4   # Archer hidup: Time Stop = kesempatan berburu
		v *= bot_spot_safety(tsp.x + 14, tsp.y + 14)
		cands.append({"type": "timestop", "x": tsp.x + 14, "y": tsp.y + 14, "r": 23.0, "val": v, "label": "AMBIL TIME STOP"})
	var best = null
	var bs := -1.0
	for c in cands:
		var s: float = c.val / (bot_dist(c.x, c.y, bx, by) + 90.0)
		if c.type == m.goal_type:
			s *= 1.25   # histeresis agar tidak plin-plan
		if s > bs:
			bs = s
			best = c
	if best != null:
		m.goal_type = best.type
		m.goal_x = best.x
		m.goal_y = best.y
		m.goal_r = best.r
		m.label = best.label
		return
	# Tidak ada yang layak diambil: BOT berkeliling ke titik acak & terus menghindar.
	var arrived := bot_dist(m.goal_x, m.goal_y, bx, by) < 40
	if m.goal_type != "roam" or arrived or dl.t >= m.roam_at:
		m.goal_x = float(Util.random_int(70, Config.WIDTH - 70))
		m.goal_y = float(Util.random_int(110, Config.HEIGHT - 70))
		m.roam_at = dl.t + DalangConfig.DL.ROAM_EVERY
	m.goal_type = "roam"
	m.goal_r = 18.0
	m.label = "BERKELILING"


## Simulasikan satu rencana (arah d1 lalu d2). Biaya lebih kecil = lebih baik.
func bot_eval(d1: int, d2: int) -> float:
	var dl: Dictionary = DalangFlow.dl
	var m := bot_mind
	var nK := _nK
	var nR := _nR
	var nM := _nM
	var nZ := _nZ
	var nL := _nL
	var nN := _nN
	var nA := _nA
	# salin buffer dasar ke buffer kerja (hanya bagian terpakai, tanpa alokasi)
	for i in range(nK * 7):
		_K[i] = _KB[i]
	for i in range(nA * 5):
		_A[i] = _AB[i]
	for i in range(nR * 3):
		_R[i] = _RB[i]
	for i in range(nM * 6):
		_M[i] = _MB[i]
	for i in range(BOT_MAXZ):
		_zf[i] = 0
	for i in range(BOT_MAXL):
		_lf[i] = 0

	var px := _px
	var py := _py
	var cd := _cd
	var cost := 0.0
	var reached := false
	var dir_now: Array = BOT_DIRS[m.dir]
	var dx0: float = dir_now[0]
	var dy0: float = dir_now[1]
	# perintah arah yang masih dalam antrean (belum berlaku) ikut disimulasikan
	var pend = m.pending
	var rem := 0.0
	var dxp := dx0
	var dyp := dy0
	if pend != null:
		rem = maxf(0, pend.at - dl.t)
		var pd: Array = BOT_DIRS[pend.dir]
		dxp = pd[0]
		dyp = pd[1]
	var da: Array = BOT_DIRS[d1]
	var db: Array = BOT_DIRS[d2]
	var dx1: float = da[0]
	var dy1: float = da[1]
	var dx2: float = db[0]
	var dy2: float = db[1]
	var lm := _life_mult
	var kR := _kR
	var hunting := _hunting
	var freeze := _freeze
	var rage := _rage
	var ts := _ts
	var power := _power
	var lK := _lK
	var lA := _lA
	var lM := _lM
	var lB := _lB
	var lL := _lL
	var gx := _gx
	var gy := _gy
	var gr := _gr
	var gw := _gw
	var roam := _roam
	var freeze_f: float = DalangConfig.DL.FREEZE_FACTOR
	var rage_f: float = DalangConfig.DL.RAGE_SPEED
	var laser_half: float = DalangConfig.DL.LASER_WIDTH / 2.0
	var W: float = Config.WIDTH
	var H: float = Config.HEIGHT
	var ts_slow: float = Config.TIME_STOP_SLOW
	var arrow_speed: float = Config.ARCHER_ARROW_SPEED
	var fire_iv: float = Config.ARCHER_FIRE_INTERVAL
	var arrow_cd: float = Config.ARCHER_ARROW_DAMAGE_COOLDOWN
	var met_cd: float = Config.METEOR_PLAYER_COOLDOWN

	for s in range(1, BOT_H + 1):
		var dx: float
		var dy: float
		if s <= BOT_LAG:   # masa reaksi: arah lama, lalu perintah yang sudah mengantre
			if s <= rem:
				dx = dx0
				dy = dy0
			else:
				dx = dxp
				dy = dyp
		elif s <= BOT_LAG + BOT_L1:
			dx = dx1
			dy = dy1
		else:
			dx = dx2
			dy = dy2
		var spm := 1.0
		if s <= freeze:
			spm = freeze_f
		elif s <= rage:
			spm = rage_f
		var sp: float = BOT_SPEED * (DIAG if (dx != 0.0 and dy != 0.0) else 1.0) * spm
		px += dx * sp
		py += dy * sp
		if px < -10:
			px += BOT_PX
		elif px > W + 10:
			px -= BOT_PX   # tembus dinding (sama dengan wrap_obj)
		if py < -10:
			py += BOT_PY
		elif py > H + 10:
			py -= BOT_PY
		var es: float = ts_slow if s <= ts else 1.0
		var powered: bool = s <= power
		var arrow_safe: bool = s <= ts
		if cd > 0:
			cd -= 1

		# ── Killer ──
		for i in range(nK):
			var o := i * 7
			var kx: float = _K[o]
			var ky: float = _K[o + 1]
			if _K[o + 3] > 0:
				_K[o + 3] -= 1   # celebrating / disappointed / global freeze
			elif _K[o + 2] > 0:
				_K[o + 2] -= 1   # loading
			elif powered:   # kabur dari BOT yang ber-Power Kill
				var ddx0 := kx - px
				var ddy0 := ky - py
				var dd := sqrt(ddx0 * ddx0 + ddy0 * ddy0)
				if dd == 0.0:
					dd = 1.0
				kx += ddx0 / dd * BOT_KILLER_SPEED * es
				ky += ddy0 / dd * BOT_KILLER_SPEED * es
			else:
				var sp2: float = BOT_KILLER_SPEED * es
				if _K[o + 6] > 0:   # terpental
					kx += _K[o + 4]
					ky += _K[o + 5]
					_K[o + 4] *= 0.91
					_K[o + 5] *= 0.91
					_K[o + 6] -= 1
					sp2 *= 0.4
				if kx < px:
					kx += sp2
				elif kx > px:
					kx -= sp2
				if ky < py:
					ky += sp2
				elif ky > py:
					ky -= sp2
			_K[o] = kx
			_K[o + 1] = ky
			if _K[o + 2] > 0 or powered:
				if powered and hunting and absf(kx - px) <= 20 and absf(ky - py) <= 20:
					cost -= 8
				continue
			var ddx := absf(kx - px)
			var ddy := absf(ky - py)
			if ddx <= 20 + BOT_MARGIN and ddy <= 20 + BOT_MARGIN:
				if cd <= 0:
					cost += 900 * lK * lm
					cd = 30
					for j in range(nK):
						if _K[j * 7 + 3] < 65:
							_K[j * 7 + 3] = 65
			else:
				var d := sqrt(ddx * ddx + ddy * ddy)
				if d < kR:
					var f := 1 - d / kR
					cost += f * f * 18

		# ── Archer menembak di masa depan ──
		for j in range(nR):
			var o := j * 3
			_R[o + 2] -= es
			if _R[o + 2] <= 0 and nA < BOT_MAXA:
				var ang := atan2(py - _R[o + 1], px - _R[o])
				var a := nA * 5
				_A[a] = _R[o]
				_A[a + 1] = _R[o + 1]
				_A[a + 2] = cos(ang) * arrow_speed
				_A[a + 3] = sin(ang) * arrow_speed
				_A[a + 4] = 1
				nA += 1
				_R[o + 2] = fire_iv
		# ── panah ──
		for i in range(nA):
			var o := i * 5
			if _A[o + 4] == 0:
				continue
			_A[o] += _A[o + 2] * es
			_A[o + 1] += _A[o + 3] * es
			var ax: float = _A[o]
			var ay: float = _A[o + 1]
			if ax < -20 or ax > W + 20 or ay < -20 or ay > H + 20:
				_A[o + 4] = 0
				continue
			if arrow_safe:
				continue
			var ddx := absf(ax - px)
			var ddy := absf(ay - py)
			if ddx <= 14 + BOT_MARGIN and ddy <= 14 + BOT_MARGIN:
				if cd <= 0:
					cost += 700 * lA * lm
					cd = arrow_cd
					_A[o + 4] = 0
			else:
				var d := sqrt(ddx * ddx + ddy * ddy)
				if d < 40:
					var f := 1 - d / 40.0
					cost += f * f * 9

		# ── meteor kecil ──
		for i in range(nM):
			var o := i * 6
			if _M[o + 5] == 0:
				continue
			var mx: float = _M[o] + _M[o + 2] * es
			var my: float = _M[o + 1] + _M[o + 3] * es
			var hw: float = _M[o + 4]
			if mx - hw < 0:
				mx = hw
				_M[o + 2] = absf(_M[o + 2])
			elif mx + hw > W:
				mx = W - hw
				_M[o + 2] = -absf(_M[o + 2])
			_M[o] = mx
			_M[o + 1] = my
			if my > H + 70:
				_M[o + 5] = 0
				continue
			var ddx := absf(mx - px)
			var ddy := absf(my - py)
			if ddx <= hw + 10 + BOT_MARGIN and ddy <= hw + 10 + BOT_MARGIN:
				if cd <= 0:
					cost += 800 * lM * lm
					cd = met_cd
					_M[o + 5] = 0
			elif ddx < hw + 32 and ddy < hw + 32:
				cost += 5

		# ── lingkaran meteor besar ──
		for z in range(nZ):
			var o := z * 3
			var t: float = _ZB[o + 2]
			var inside: bool = absf(px - _ZB[o]) <= 76 + BOT_MARGIN and absf(py - _ZB[o + 1]) <= 76 + BOT_MARGIN
			if not inside:
				continue
			if s >= t - 2 and s <= t + 1:
				if _zf[z] == 0:
					_zf[z] = 1
					cost += 1500 * lB * lm
			elif s < t and s >= t - 30:
				cost += 7

		# ── laser ──
		for l in range(nL):
			var o := l * 6
			var warn: float = _LB[o + 4]
			var fire: float = _LB[o + 5]
			var dist := absf((px - _LB[o]) * -_LB[o + 3] + (py - _LB[o + 1]) * _LB[o + 2])
			if s > warn and s <= warn + fire:
				if dist <= laser_half + 17 + BOT_MARGIN and _lf[l] == 0:
					_lf[l] = 1
					cost += 1500 * lL * lm
			elif s <= warn and s >= warn - 22 and dist <= laser_half + 20:
				cost += 8

		# ── jalur hujan (perkiraan kepadatan) ──
		for r in range(nN):
			var o := r * 4
			if s >= _NB[o + 2] - 6 and s <= _NB[o + 3] and absf(px - _NB[o]) < _NB[o + 1]:
				cost += 8 * lM

		# ── dinding bukan lagi penghalang: tak ada penalti tepi ──

		# ── mencapai tujuan ──
		if not roam and not reached and bot_wrap_d(px, gx, BOT_PX) <= gr and bot_wrap_d(py, gy, BOT_PY) <= gr:
			reached = true
			cost -= 260 + (BOT_H - s) * 2.5
			break   # sampai: sisanya tidak dihitung (BOT berpikir ulang)
	if not reached:
		var wx := bot_wrap_d(px, gx, BOT_PX)
		var wy := bot_wrap_d(py, gy, BOT_PY)
		cost += gw * sqrt(wx * wx + wy * wy)
	return cost


## Dipanggil tiap tick oleh dalang_tick().
func dl_bot_think() -> void:
	var dl: Dictionary = DalangFlow.dl
	var m := bot_mind
	m.think -= 1
	if m.think > 0:
		return
	m.think = BOT_EVERY
	if m.lapse > 0:   # sedang lengah
		m.lapse -= BOT_EVERY
		return
	if randf() < BOT_LAPSE_CHANCE:
		m.lapse = BOT_LAPSE_FRAMES
		return
	var threat := bot_snapshot()
	bot_choose_goal(threat)
	_gx = m.goal_x
	_gy = m.goal_y
	_gr = m.goal_r
	_roam = m.goal_type == "roam"
	_gw = DalangConfig.DL.ROAM_WEIGHT if _roam else 1.12

	var best_cost := INF
	var best_dir: int = m.dir
	for i in range(9):
		var turn := 0.0 if i == m.dir else 4.0   # komitmen arah: tidak zigzag
		for j in range(9):
			var c := bot_eval(i, j) + turn + randf() * 1.5
			if c < best_cost:
				best_cost = c
				best_dir = i
	m.cost = best_cost
	if best_dir != m.dir and not (m.pending != null and m.pending.dir == best_dir):
		m.pending = {"dir": best_dir, "at": dl.t + BOT_LAG}   # baru berlaku setelah waktu reaksi
	elif best_dir == m.dir:
		m.pending = null


## Gerak BOT (aturan sama seperti pemain; tembus dinding).
func dl_move_bot() -> void:
	var dl: Dictionary = DalangFlow.dl
	var m := bot_mind
	var pl: Dictionary = State.player
	if State.player_shock_timer > 0 and State.player_death_timer <= 0:
		pl.x += State.player_shock_x
		pl.y += State.player_shock_y
		State.player_shock_x *= 0.86
		State.player_shock_y *= 0.86
	if m.pending != null and dl.t >= m.pending.at:
		m.dir = m.pending.dir
		m.pending = null
	var f: float = 1.0
	if dl.freeze > 0:
		f = DalangConfig.DL.FREEZE_FACTOR
	elif dl.rage > 0:
		f = DalangConfig.DL.RAGE_SPEED
	var d: Array = BOT_DIRS[m.dir]
	var k: float = BOT_SPEED * f * (DIAG if (d[0] != 0 and d[1] != 0) else 1.0)
	# percepatan halus (tidak langsung 0 -> penuh)
	m.vx += (d[0] * k - m.vx) * 0.35
	m.vy += (d[1] * k - m.vy) * 0.35
	pl.x += m.vx
	pl.y += m.vy
	var ox: float = pl.x
	var oy: float = pl.y
	Util.wrap_obj(pl)   # BOT boleh menembus dinding seperti pemain
	if absf(pl.x - ox) > 300 or absf(pl.y - oy) > 300:
		var nx: float = pl.x + pl.w / 2.0
		var ny: float = pl.y + pl.h / 2.0
		Archers.create_teleport_particles(maxf(4, minf(Config.WIDTH - 4, ox + pl.w / 2.0)), maxf(4, minf(Config.HEIGHT - 4, oy + pl.h / 2.0)), 8)
		Archers.create_teleport_particles(maxf(4, minf(Config.WIDTH - 4, nx)), maxf(4, minf(Config.HEIGHT - 4, ny)), 8)
		m.wrap_fx = 45
	if m.wrap_fx > 0:
		m.wrap_fx -= 1


## Teks status BOT di atas kepalanya.
func dl_bot_label() -> String:
	var dl: Dictionary = DalangFlow.dl
	var m := bot_mind
	if dl.freeze > 0:
		return "❄ TERKUNCI 🛡" if dl.shield > 0 else "❄ TERKUNCI"
	if m.wrap_fx > 0:
		return "🌀 TEMBUS DINDING"
	if dl.rage > 0:
		return "🔥 AMUK!"
	if State.power_active > 0:
		return "BERBURU KILLER" if m.goal_type == "hunt" else "POWER KILL"
	if State.time_stop > 0:
		return "BURU ARCHER" if m.goal_type == "huntA" else "TIME STOP"
	if m.alert < 70:
		return "MENGHINDAR!"
	return m.label
