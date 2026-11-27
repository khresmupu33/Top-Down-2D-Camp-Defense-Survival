extends Node
## BOT mode penonton SANTAI (dari modes/hard/test-bot.js, hanya mode PINTAR / SMART). Autoload: TestBot.
##
## Di level SANTAI bot memainkan level SULIT 0-100 dan tidak bisa mati (nyawa dipulihkan tiap tick);
## kamu hanya menonton. Prioritas utama bot = kotak putih (target / poin).
##   - tujuan selalu kotak putih; Power Kill / Time Stop / Nyawa hanya diambil bila hampir searah
##   - tidak pernah lengah, berpikir tiap 3 frame
##   - Gadfly disimulasikan, jadi bot berani lewat tepi bila aman
##   - saat Time Stop Vindex, gerak bot ikut melambat (seperti pemain sungguhan)
## Cara berpikir sama dengan BOT-X (DALANG): foto bahaya -> simulasi 81 rencana gerak -> pilih biaya terkecil.
## Mesin BOT-X disalin ke sini (tanpa hujan meteor / Time Stop dalang / amuk) karena DalangBot terikat DalangFlow.dl.
## Bot menggerakkan pemain langsung (State.player), bukan lewat tombol; State.pressed_keys selalu dikosongkan.
## API: start_spectator() sekali di awal, tick() tiap tick tepat sebelum GameLoop.update_game().

const BOT_DIRS := [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]]
const BOT_H := 46        # horizon simulasi (frame)
const BOT_L1 := 13       # lama arah pertama
const BOT_EVERY := 4     # berpikir tiap N frame (dipotong jadi 3 untuk mode pintar)
const BOT_LAG := 2       # waktu reaksi: keputusan baru berlaku N frame kemudian
const BOT_SPEED := 3.95  # px/frame lurus (pemain 4). Diagonal dinormalkan
const DIAG := 0.7071
const BOT_MARGIN := 2
const BOT_LAPSE_CHANCE := 0.006
const BOT_LAPSE_FRAMES := 16
const BOT_MAXK := 24
const BOT_MAXA := 96
const BOT_MAXM := 44
const BOT_MAXR := 16
const BOT_MAXZ := 3
const BOT_MAXL := 4
const BOT_KILLER_SPEED := 2.5
const BOT_PX := Config.WIDTH + 20   # periode lingkaran (tembus dinding)
const BOT_PY := Config.HEIGHT + 20
const LASER_FIRE := 38       # DL.LASER_FIRE
const LASER_WIDTH := 56      # DL.LASER_WIDTH
const ROAM_WEIGHT := 0.45    # DL.ROAM_WEIGHT
const ROAM_EVERY := 150      # DL.ROAM_EVERY

const DETOUR_MAX := {"power": 110.0, "timestop": 130.0, "health": 70.0}
const GF_N := 4
const GF_HIT_COST := 330.0
const GF_MARGIN := 3.0
const TARGET_BONUS := 300.0
const TARGET_TIME := 3.0
const TARGET_PULL := 0.55
const WRAP_MIN_SAVING := 420.0   # tembus dinding hanya dihitung bila menghemat jarak sebesar ini

## Pikiran bot (botMind JS).
var _mind := {}
var _t := 0               # dl.t
var _lasers: Array = []   # dl.lasers (format DALANG)
var _run_id := 0

# buffer dasar (diisi tiap berpikir) & buffer kerja (disalin tiap simulasi)
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
var _zf := PackedByteArray()
var _lf := PackedByteArray()
var _gfB := PackedFloat64Array()
var _gf := PackedFloat64Array()

# BS: foto dunia
var _nK := 0
var _nA := 0
var _nR := 0
var _nM := 0
var _nZ := 0
var _nL := 0
var _px := 0.0
var _py := 0.0
var _cd := 0.0
var _ts := 0.0
var _power := 0.0
var _life_mult := 1.0
var _gx := 0.0
var _gy := 0.0
var _gr := 18.0
var _gw := 1.12
var _roam := false
var _kR := 100.0
var _hunting := false


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
	_zf.resize(BOT_MAXZ)
	_lf.resize(BOT_MAXL)
	_gfB.resize(GF_N * 5)
	_gf.resize(GF_N * 5)
	_reset_mind()


func _reset_mind() -> void:
	_mind = {"pending": null, "lapse": 0, "vx": 0.0, "vy": 0.0, "dir": 0, "goal_type": "roam", "goal_x": 400.0,
		"goal_y": 300.0, "goal_r": 18.0, "lock": 0, "think": 0, "label": "BERKELILING", "alert": 0.0,
		"roam_at": 0, "wrap_fx": 0, "cost": 0.0}
	_t = 0
	_lasers = []


# ── awal permainan ──────────────────────────────────────────────────────

## Dipanggil sekali di awal run penonton. Memulai permainan sendiri begitu adegan pembuka siap
## (JS: setInterval(advanceStart, 250)).
func start_spectator() -> void:
	_reset_mind()
	_run_id += 1
	var tok := _run_id
	Util.after_ms(250.0, func(): _advance_start(tok))


func _advance_start(tok: int) -> void:
	if tok != _run_id or not State.in_game or not State.spectator_mode:
		return
	if State.game_state == "hardIntro":
		State.hard_intro_ready = true
		GameFlow.begin_play()
	elif State.game_state == "ready":
		GameFlow.begin_play()
	Util.after_ms(250.0, func(): _advance_start(tok))


# ── tick ────────────────────────────────────────────────────────────────

## Dipanggil tiap tick fisika tepat sebelum GameLoop.update_game() saat State.spectator_mode.
func tick() -> void:
	if State.game_state == "playing":
		# GOD: bot tidak bisa mati
		if State.lives < 3 or State.player_death_timer > 0:
			State.lives = 3
			if State.player_death_timer > 0:
				State.player_death_timer = 0
				State.player_death_max = 0
				State.global_freeze = 0
				State.hit_cooldown = 30
	_control()


func _control() -> void:
	var pl = State.player
	if pl == null or State.game_state != "playing" or State.player_death_timer > 0 or State.hard25_sequence_active or State.paused:
		State.pressed_keys.clear()
		return
	State.pressed_keys.clear()   # gerak dilakukan lewat _move_bot (kecepatan & aturan BOT-X)
	_t += 1
	_feed_lasers()
	_mind.lapse = 0   # bot pintar tidak pernah lengah
	_bot_think()
	_mind.lapse = 0
	if _mind.think > 3:
		_mind.think = 3   # berpikir tiap 3 frame (BOT-X: tiap 4)
	var ox: float = pl.x
	var oy: float = pl.y
	_move_bot()
	if State.vindex_time_stop > 0:
		# Time Stop Vindex: dunia melambat, termasuk pemain -> gerak bot ikut melambat
		var sf: float = TimeStop.world_slow_factor()
		var dx: float = pl.x - ox
		var dy: float = pl.y - oy
		if absf(dx) < 300 and absf(dy) < 300:
			pl.x = ox + dx * sf
			pl.y = oy + dy * sf


## Laser Sulit -> format laser DALANG (Time Stop Vindex lebar, jadi tiga garis sejajar).
func _feed_lasers() -> void:
	var out: Array = []
	var lv = State.lord_vindex
	if lv != null and (State.vindex_laser_countdown > 0 or State.vindex_laser_fire_timer > 0):
		var fire_now: bool = State.vindex_laser_fire_timer > 0
		var x: float = State.vindex_laser_origin_x if fire_now else lv.x + 21
		var y: float = State.vindex_laser_origin_y if fire_now else lv.y + 21
		for off in [-16.0, 0.0, 16.0]:
			_push_laser(out, x, y, State.vindex_laser_angle, 0.0 if fire_now else float(State.vindex_laser_countdown),
				float(State.vindex_laser_fire_timer) if fire_now else 42.0, off)
	var b = State.vindex_barrage
	if b != null and (b.phase == "warn" or b.phase == "fire"):
		var warn: float = (Config.VINDEX_BARRAGE_WARN - b.t) if b.phase == "warn" else 0.0
		var fire: float = float(Config.VINDEX_BARRAGE_FIRE) if b.phase == "warn" else float(Config.VINDEX_BARRAGE_FIRE - b.t)
		for bm in b.beams:
			_push_laser(out, Config.WIDTH / 2.0, Config.HEIGHT / 2.0, bm.angle, warn, fire, 0.0)
	_lasers = out


func _push_laser(out: Array, x: float, y: float, ang: float, warn: float, fire: float, off: float) -> void:
	var ox: float = -sin(ang) * off
	var oy: float = cos(ang) * off
	out.append({"x": x + ox, "y": y + oy, "angle": ang, "warn": warn, "fire": fire, "hit": false})


# ── jarak melingkar ─────────────────────────────────────────────────────

func _wrap_d(a: float, b: float, period: float) -> float:
	var d := absf(a - b)
	return period - d if d > period / 2.0 else d


## Jarak terdekat dua titik, boleh lewat dinding.
func _dist(x1: float, y1: float, x2: float, y2: float) -> float:
	return Vector2(_wrap_d(x1, x2, BOT_PX), _wrap_d(y1, y2, BOT_PY)).length()


func _laser_dist(L: Dictionary, px: float, py: float) -> float:
	return absf((px - L.x) * -sin(L.angle) + (py - L.y) * cos(L.angle))


# ── foto dunia ──────────────────────────────────────────────────────────

## Foto kondisi dunia dari sudut pandang bot (+ Vindex sebagai Killer, + Gadfly). Mengembalikan ancaman.
func _snapshot() -> float:
	var pl: Dictionary = State.player
	var bx: float = pl.x + pl.w / 2.0
	var by: float = pl.y + pl.h / 2.0
	_px = bx
	_py = by
	_cd = maxf(0, State.hit_cooldown)
	_ts = maxf(0, State.time_stop)
	_power = maxf(0, State.power_active)
	_life_mult = 1.0 if State.lives >= 3 else (1.4 if State.lives == 2 else 2.4)
	_kR = 100.0   # Time Stop dalang tidak ada di Sulit

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
	for L in _lasers:
		if n >= BOT_MAXL or L.hit:
			continue
		var o := n * 6
		_LB[o] = L.x
		_LB[o + 1] = L.y
		_LB[o + 2] = cos(L.angle)
		_LB[o + 3] = sin(L.angle)
		_LB[o + 4] = maxf(0, L.warn)
		_LB[o + 5] = float(LASER_FIRE) if L.warn > 0 else maxf(0, L.fire)
		n += 1
		if _laser_dist(L, bx, by) < 120:
			threat += 1.2
	_nL = n

	# Vindex dilihat bot sebagai Killer yang mengejar (diam saat ia sedang menyiapkan serangan)
	var lv = State.lord_vindex
	if lv != null and not lv.dead and _nK < BOT_MAXK:
		var still: bool = VindexAttacks.vindex_special_busy() or State.vindex_time_stop > 0 or State.vindex_laser_countdown > 0 \
			or State.vindex_laser_fire_timer > 0 or State.vindex_move_delay > 0
		var o := _nK * 7
		_KB[o] = lv.x + 21
		_KB[o + 1] = lv.y + 21
		_KB[o + 2] = 0
		_KB[o + 3] = 9999 if still else 0
		_KB[o + 4] = 0
		_KB[o + 5] = 0
		_KB[o + 6] = 0
		_nK += 1

	# Gadfly: [horizontal?, tetap, bergerak, kebal, -]
	for i in range(GF_N):
		var o := i * 5
		if i >= State.gadflies.size():
			_gfB[o + 3] = 1e9
			continue
		var g: Dictionary = State.gadflies[i]
		var horiz: bool = g.name == "top" or g.name == "bottom"
		_gfB[o] = 1.0 if horiz else 0.0
		if g.name == "top" or g.name == "left":
			_gfB[o + 1] = 10.0
		else:
			_gfB[o + 1] = (Config.HEIGHT - 10.0) if horiz else (Config.WIDTH - 10.0)
		_gfB[o + 2] = (g.x + 10.0) if horiz else (g.y + 10.0)
		_gfB[o + 3] = g.hit_anim if g.hit_anim > 0 else 0.0   # sedang terpental: kebal
		_gfB[o + 4] = 1.0 if (g.hit_anim > 0 or g.freeze > 0) else 0.0
		if g.hit_anim > 0:
			_gfB[o + 1] = (g.y + 10.0) if horiz else (g.x + 10.0)

	_mind.alert = near
	return threat


## Pengali 0..1: seberapa aman sebuah titik (item) dari bencana. 1 = aman.
func _spot_safety(x: float, y: float) -> float:
	var s := 1.0
	for L in _lasers:
		if not L.hit and _laser_dist(L, x, y) < LASER_WIDTH / 2.0 + 28:
			s *= 0.3
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


# ── tujuan ──────────────────────────────────────────────────────────────

func _set_goal(type: String, x: float, y: float, r: float, label: String) -> void:
	_mind.goal_type = type
	_mind.goal_x = x
	_mind.goal_y = y
	_mind.goal_r = r
	_mind.label = label


## MODE PINTAR: kotak putih adalah tujuan tetap. Item (Power Kill / Time Stop / Nyawa) hanya dipungut bila
## letaknya hampir searah dengan kotak putih: jarak bot->item + item->kotak hanya sedikit lebih jauh dari bot->kotak.
func _smart_goal() -> void:
	var pl: Dictionary = State.player
	var bx: float = pl.x + pl.w / 2.0
	var by: float = pl.y + pl.h / 2.0
	_hunting = false
	var tg = State.target
	if tg == null:
		_base_goal(0.0)
		return
	var tx: float = tg.x + tg.w / 2.0
	var ty: float = tg.y + tg.h / 2.0
	var dT := _dist(tx, ty, bx, by)
	var items: Array = []
	var pw = State.powerup
	var tsp = State.time_stop_powerup
	var hl = State.health
	if pw != null and pw.visible and State.power_active <= 0:
		items.append({"type": "power", "o": pw, "label": "POWER KILL (SEARAH)"})
	if tsp != null and tsp.visible and State.time_stop <= 0:
		items.append({"type": "timestop", "o": tsp, "label": "TIME STOP (SEARAH)"})
	if hl != null and hl.visible and State.lives < 3:
		items.append({"type": "health", "o": hl, "label": "NYAWA (SEARAH)"})
	var best = null
	var best_detour := 1e9
	for it in items:
		var o: Dictionary = it.o
		var ix: float = o.x + o.w / 2.0
		var iy: float = o.y + o.h / 2.0
		var dI := _dist(ix, iy, bx, by)
		var detour := dI + _dist(ix, iy, tx, ty) - dT
		var limit: float = DETOUR_MAX[it.type] * _spot_safety(ix, iy)   # item di tempat berbahaya: nyaris diabaikan
		# item yang sudah sangat dekat selalu layak; selebihnya harus memenuhi batas jalan memutar
		if (detour <= limit or dI < 45) and detour < best_detour:
			best_detour = detour
			best = {"it": it, "ix": ix, "iy": iy}
	if best != null:
		var tp: String = best.it.type
		var r := 22.0 if tp == "power" else (23.0 if tp == "timestop" else 21.0)
		_set_goal(tp, best.ix, best.iy, r, best.it.label)
		return
	_set_goal("target", tx, ty, 14.0, "MENGAMBIL POIN")


## Tujuan dasar BOT-X (dipakai hanya bila kotak putih tidak ada).
func _base_goal(threat: float) -> void:
	var pl: Dictionary = State.player
	var bx: float = pl.x + pl.w / 2.0
	var by: float = pl.y + pl.h / 2.0
	var m := _mind
	_hunting = false

	# Time Stop pemain aktif: buru Archer terdekat yang masih terkejar sebelum Time Stop habis
	if State.time_stop > 30:
		var best_a = null
		var bd := 1e9
		for a in State.archers:
			if a.dead:
				continue
			var d := _dist(a.x + a.w / 2.0, a.y + a.h / 2.0, bx, by)
			if d / BOT_SPEED + 8 > State.time_stop:
				continue
			if d < bd:
				bd = d
				best_a = a
		if best_a != null:
			_set_goal("huntA", best_a.x + best_a.w / 2.0, best_a.y + best_a.h / 2.0, 20.0, "BURU ARCHER")
			return

	# Power Kill aktif: buru Killer terdekat selama waktunya cukup
	if State.power_active > 80:
		var best_k = null
		var bd2 := 1e9
		for k in State.killers:
			if k.disintegrating or k.loading > 0:
				continue
			var d := _dist(k.x + 10, k.y + 10, bx, by)
			if d < bd2:
				bd2 = d
				best_k = k
		if best_k != null and bd2 < 420:
			_set_goal("hunt", best_k.x + 10, best_k.y + 10, 20.0, "BERBURU KILLER")
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
	var health = State.health
	var powerup = State.powerup
	var tsp = State.time_stop_powerup
	if health != null and health.visible and State.lives < 3:
		var v: float = (3.4 if State.lives <= 1 else 2.1) * _spot_safety(health.x + 12.5, health.y + 12.5)
		cands.append({"type": "health", "x": health.x + 12.5, "y": health.y + 12.5, "r": 21.0, "val": v, "label": "MENCARI NYAWA"})
	if powerup != null and powerup.visible and State.power_active <= 0:
		var pv := 1.2
		if foes >= 3:
			pv = 2.5
		elif foes == 2:
			pv = 2.1
		elif foes == 1:
			pv = 1.7
		var v: float = pv * _spot_safety(powerup.x + 13, powerup.y + 13)
		cands.append({"type": "power", "x": powerup.x + 13, "y": powerup.y + 13, "r": 22.0, "val": v, "label": "AMBIL POWER KILL"})
	if tsp != null and tsp.visible and State.time_stop <= 0:
		var v := 1.5
		if threat >= 2.6:
			v = 2.7
		elif State.lives <= 1 and threat >= 1:
			v = 2.4
		if live_a > 0:
			v += 0.4
		v *= _spot_safety(tsp.x + 14, tsp.y + 14)
		cands.append({"type": "timestop", "x": tsp.x + 14, "y": tsp.y + 14, "r": 23.0, "val": v, "label": "AMBIL TIME STOP"})
	var best = null
	var bs := -1.0
	for c in cands:
		var s: float = c.val / (_dist(c.x, c.y, bx, by) + 90.0)
		if c.type == m.goal_type:
			s *= 1.25   # histeresis agar tidak plin-plan
		if s > bs:
			bs = s
			best = c
	if best != null:
		_set_goal(best.type, best.x, best.y, best.r, best.label)
		return
	# Tidak ada yang layak diambil: berkeliling ke titik acak & terus menghindar
	var arrived := _dist(m.goal_x, m.goal_y, bx, by) < 40
	if m.goal_type != "roam" or arrived or _t >= m.roam_at:
		m.goal_x = float(Util.random_int(70, Config.WIDTH - 70))
		m.goal_y = float(Util.random_int(110, Config.HEIGHT - 70))
		m.roam_at = _t + ROAM_EVERY
	m.goal_type = "roam"
	m.goal_r = 18.0
	m.label = "BERKELILING"


# ── simulasi rencana gerak ──────────────────────────────────────────────

## Simulasi dasar BOT-X (arah d1 lalu d2). Biaya lebih kecil = lebih baik. gw = bobot tarikan jarak ke tujuan.
func _eval_base(d1: int, d2: int, gw: float) -> float:
	var m := _mind
	var nK := _nK
	var nR := _nR
	var nM := _nM
	var nZ := _nZ
	var nL := _nL
	var nA := _nA
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
		rem = maxf(0, pend.at - _t)
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
	var ts := _ts
	var power := _power
	var gx := _gx
	var gy := _gy
	var gr := _gr
	var roam := _roam
	var laser_half: float = LASER_WIDTH / 2.0
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
		var sp: float = BOT_SPEED * (DIAG if (dx != 0.0 and dy != 0.0) else 1.0)
		px += dx * sp
		py += dy * sp
		if px < -10:
			px += BOT_PX
		elif px > W + 10:
			px -= BOT_PX   # tembus dinding
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
			elif powered:   # kabur dari bot yang ber-Power Kill
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
					cost += 900 * lm
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
					cost += 700 * lm
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
					cost += 800 * lm
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
					cost += 1500 * lm
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
					cost += 1500 * lm
			elif s <= warn and s >= warn - 22 and dist <= laser_half + 20:
				cost += 8

		# ── mencapai tujuan ──
		if not roam and not reached and _wrap_d(px, gx, BOT_PX) <= gr and _wrap_d(py, gy, BOT_PY) <= gr:
			reached = true
			cost -= 260 + (BOT_H - s) * 2.5
			break
	if not reached:
		var wx := _wrap_d(px, gx, BOT_PX)
		var wy := _wrap_d(py, gy, BOT_PY)
		cost += gw * sqrt(wx * wx + wy * wy)
	return cost


## Jarak ke tujuan (mode pintar): lurus biasa, kecuali lewat dinding jauh lebih dekat. Mencegah bot macet di titik tengah.
func _smart_dist(px: float, py: float) -> float:
	var dE := Vector2(px - _gx, py - _gy).length()
	var dW := Vector2(_wrap_d(px, _gx, BOT_PX), _wrap_d(py, _gy, BOT_PY)).length()
	return dW if dE - dW > WRAP_MIN_SAVING else dE


## Biaya total: simulasi dasar + Pusaran Ungu, zona tengah saat rentetan laser, Gadfly, dan hadiah kotak putih.
func _eval(d1: int, d2: int) -> float:
	var gw_base := _gw
	var cost := _eval_base(d1, d2, 0.0 if not _roam else gw_base)   # tarikan jarak dihitung sendiri di bawah (_smart_dist)
	var px := _px
	var py := _py
	var dn: Array = BOT_DIRS[_mind.dir]
	var dx0: float = dn[0]
	var dy0: float = dn[1]
	var chase: bool = _mind.goal_type == "target"
	var goal_mode: bool = not _roam
	var reached := false
	for i in range(GF_N * 5):
		_gf[i] = _gfB[i]
	var vx = State.vindex_vortex
	var barrage = State.vindex_barrage
	var da: Array = BOT_DIRS[d1]
	var db: Array = BOT_DIRS[d2]
	var W: float = Config.WIDTH
	var H: float = Config.HEIGHT
	for s in range(1, BOT_H + 1):
		var dx: float
		var dy: float
		if s <= BOT_LAG:
			dx = dx0
			dy = dy0
		elif s <= BOT_LAG + BOT_L1:
			dx = da[0]
			dy = da[1]
		else:
			dx = db[0]
			dy = db[1]
		var sp: float = BOT_SPEED * (DIAG if (dx != 0.0 and dy != 0.0) else 1.0)
		px += dx * sp
		py += dy * sp
		if vx != null:
			var ramp: float = minf(1.0, vx.age / 30.0)
			var dd: float = Vector2(vx.x - px, vx.y - py).length()
			if dd == 0.0:
				dd = 1.0
			if dd < Config.VORTEX_PULL_RADIUS:
				var k: float = 1.0 - (dd - Config.VORTEX_KILL_RADIUS) / float(Config.VORTEX_PULL_RADIUS - Config.VORTEX_KILL_RADIUS)
				var pull: float = Config.VORTEX_PULL_MAX * (0.28 + 0.72 * maxf(0.0, minf(1.0, k))) * ramp
				px += (vx.x - px) / dd * pull
				py += (vx.y - py) / dd * pull
			var d3: float = Vector2(vx.x - px, vx.y - py).length()
			if d3 < Config.VORTEX_KILL_RADIUS + 26:
				cost += 5000
			elif s % 4 == 0 and d3 < Config.VORTEX_PULL_RADIUS:
				cost += (Config.VORTEX_PULL_RADIUS - d3) * 0.12
		# Gadfly bergerak mengikuti pemain di tepi (3 px/frame), sentuhan = -1 poin (lalu kebal 28 frame)
		for i in range(GF_N):
			var o := i * 5
			if _gf[o + 3] > 0:
				_gf[o + 3] -= 1
				continue
			if _gf[o + 3] < 0:
				continue
			var horiz: bool = _gf[o] == 1.0
			if _gf[o + 4] == 0.0:
				var tt: float = px if horiz else py
				var c: float = _gf[o + 2]
				_gf[o + 2] = c + 3 if c < tt else (c - 3 if c > tt else c)
			var gx: float = _gf[o + 2] if horiz else _gf[o + 1]
			var gy: float = _gf[o + 1] if horiz else _gf[o + 2]
			if absf(px - gx) <= 20 + GF_MARGIN and absf(py - gy) <= 20 + GF_MARGIN:
				cost += GF_HIT_COST
				_gf[o + 3] = Config.GADFLY_HIT_TIME
		if px < -10:
			px += BOT_PX
		elif px > W + 10:
			px -= BOT_PX
		if py < -10:
			py += BOT_PY
		elif py > H + 10:
			py -= BOT_PY
		if s % 4 == 0 and barrage != null:
			var dc: float = Vector2(px - W / 2.0, py - H / 2.0).length()
			if dc < 150:
				cost += (150 - dc) * 0.5
		# hadiah ekstra bila rencana ini menyentuh kotak putih (makin cepat makin besar)
		if goal_mode and _wrap_d(px, _gx, BOT_PX) <= _gr and _wrap_d(py, _gy, BOT_PY) <= _gr:
			if chase:
				cost -= TARGET_BONUS + (BOT_H - s) * TARGET_TIME
			reached = true
			break
	if goal_mode and not reached:
		cost += (gw_base + (TARGET_PULL if chase else 0.0)) * _smart_dist(px, py)
	return cost


# ── berpikir & bergerak ─────────────────────────────────────────────────

## Berpikir (tiap BOT_EVERY frame; dipotong 3 oleh _control).
func _bot_think() -> void:
	var m := _mind
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
	_snapshot()
	_smart_goal()
	_gx = m.goal_x
	_gy = m.goal_y
	_gr = m.goal_r
	_roam = m.goal_type == "roam"
	_gw = ROAM_WEIGHT if _roam else 1.12

	var best_cost := INF
	var best_dir: int = m.dir
	for i in range(9):
		var turn := 0.0 if i == m.dir else 4.0   # komitmen arah: tidak zigzag
		for j in range(9):
			var c := _eval(i, j) + turn + randf() * 1.5
			if c < best_cost:
				best_cost = c
				best_dir = i
	m.cost = best_cost
	if best_dir != m.dir and not (m.pending != null and m.pending.dir == best_dir):
		m.pending = {"dir": best_dir, "at": _t + BOT_LAG}   # baru berlaku setelah waktu reaksi
	elif best_dir == m.dir:
		m.pending = null


## Gerak bot (4 px/frame per sumbu seperti pemain; tembus dinding).
func _move_bot() -> void:
	var m := _mind
	var pl: Dictionary = State.player
	if State.player_shock_timer > 0 and State.player_death_timer <= 0:
		pl.x += State.player_shock_x
		pl.y += State.player_shock_y
		State.player_shock_x *= 0.86
		State.player_shock_y *= 0.86
	if m.pending != null and _t >= m.pending.at:
		m.dir = m.pending.dir
		m.pending = null
	var d: Array = BOT_DIRS[m.dir]
	var k: float = BOT_SPEED * (DIAG if (d[0] != 0 and d[1] != 0) else 1.0)
	# percepatan halus (tidak langsung 0 -> penuh)
	m.vx += (d[0] * k - m.vx) * 0.35
	m.vy += (d[1] * k - m.vy) * 0.35
	pl.x += m.vx
	pl.y += m.vy
	var ox: float = pl.x
	var oy: float = pl.y
	Util.wrap_obj(pl)   # bot boleh menembus dinding seperti pemain
	if absf(pl.x - ox) > 300 or absf(pl.y - oy) > 300:
		var nx: float = pl.x + pl.w / 2.0
		var ny: float = pl.y + pl.h / 2.0
		Archers.create_teleport_particles(maxf(4, minf(Config.WIDTH - 4, ox + pl.w / 2.0)), maxf(4, minf(Config.HEIGHT - 4, oy + pl.h / 2.0)), 8)
		Archers.create_teleport_particles(maxf(4, minf(Config.WIDTH - 4, nx)), maxf(4, minf(Config.HEIGHT - 4, ny)), 8)
		m.wrap_fx = 45
	if m.wrap_fx > 0:
		m.wrap_fx -= 1
