extends Node
## Konfigurasi & konstanta gameplay (dari core/config.js).
## Semua angka penyeimbang ada di sini (satuan: frame @60 FPS atau ms).
## Akses: Config.NAMA_KONSTANTA


# ── Arena ───────────────────────────────────────────────────────────────
const WIDTH = 800
const HEIGHT = 600



# ── Pemain ────────────────────────────────────────────────────────────
const PLAYER_SPEED = 4

# ── Killer ────────────────────────────────────────────────────────────
const KILLER_LOAD_TIME = 120
const KILLER_KNOCKBACK_TIME = 35
const KILLER_KNOCKBACK_POWER = 11
const KILLER_COLLISION_COOLDOWN = 22
const GLOBAL_KILLER_FREEZE = 45
const KILLER_FIRST_TIME = 9000
const KILLER_NEXT_TIME = 9000
const MAX_KILLERS = 12

# ── Gadfly ────────────────────────────────────────────────────────────
const GADFLY_HIT_TIME = 28

# ── Item: power kill, nyawa ───────────────────────────────────────────
const POWER_DURATION = 600
const POWER_FIRST_MIN = 30000
const POWER_FIRST_MAX = 40000
const POWER_RESPAWN_MIN = 30000
const POWER_RESPAWN_MAX = 40000
const POWER_FLEE_SPEED_MULTIPLIER = 1
const POWER_SAFE_MARGIN = 32
const HEALTH_FIRST_MIN = 20000
const HEALTH_FIRST_MAX = 30000
const HEALTH_RESPAWN_MIN = 20000
const HEALTH_RESPAWN_MAX = 30000

# ── Meteor besar ──────────────────────────────────────────────────────
const LARGE_METEOR_RANDOM_MIN = 2100
const LARGE_METEOR_RANDOM_MAX = 3900
const LARGE_METEOR_WARNING_TIME = 150
const LARGE_METEOR_DELAY_MIN = 30
const LARGE_METEOR_DELAY_MAX = 55
const LARGE_METEOR_SPEED = 5.2
const LARGE_METEOR_SIZE = 100
const LARGE_METEOR_BLAST_RADIUS = 150
const LARGE_METEOR_MAX_IMPACT_PARTICLES = 18
const LARGE_METEOR_PLAYER_DAMAGE = 2
const LARGE_METEOR_SHOCK_POWER = 18
const LARGE_METEOR_DIRECT_RADIUS = 60

# ── Meteor ────────────────────────────────────────────────────────────
const METEOR_FIRST_MIN = 1200
const METEOR_FIRST_MAX = 1800
const METEOR_SESSION_DURATION = 1080
const METEOR_SPAWN_INTERVAL = 34
const METEOR_SPEED_MIN = 5
const METEOR_SPEED_MAX = 8
const METEOR_PLAYER_COOLDOWN = 55
const METEOR_SAFE_MARGIN = 8
const METEOR_FIRST_BURST = 12
const METEOR_SECOND_BURST = 10
const METEOR_SECOND_BURST_TIME = 420
const METEOR_BURST_COOLDOWN = 55
const METEOR_NEXT_SESSION_MIN = 1500
const METEOR_NEXT_SESSION_MAX = 2700
const METEOR_TRIGGER_SCORE = 10
const METEOR_PRE_SHOWER_MIN = 1200
const METEOR_PRE_SHOWER_MAX = 1800
const METEOR_PRE_SHOWER_SPAWN_INTERVAL_MIN = 150
const METEOR_PRE_SHOWER_SPAWN_INTERVAL_MAX = 300
const METEOR_PRE_SHOWER_MAX_METEORS = 5

# ── Archer ────────────────────────────────────────────────────────────
const MAX_ARCHERS = 5
const ARCHER_LOAD_TIME = 110
const ARCHER_SPEED = 1.8
const ARCHER_ARROW_SPEED = 5.2
const ARCHER_FIRE_INTERVAL = 145
const ARCHER_FIRST_SCORE = 5
const ARCHER_SPAWN_MIN = 15000
const ARCHER_SPAWN_MAX = 22000
const ARCHER_POWER_EVADE_DISTANCE = 190
const ARCHER_POWER_TELEPORT_DISTANCE = 260
const ARCHER_ARROW_DAMAGE_COOLDOWN = 35

# ── Time Stop ─────────────────────────────────────────────────────────
const TIME_STOP_DURATION = 300
const TIME_STOP_SLOW = 0.18
const TIME_STOP_FIRST_MIN = 18000
const TIME_STOP_FIRST_MAX = 26000
const TIME_STOP_RESPAWN_MIN = 26000
const TIME_STOP_RESPAWN_MAX = 38000

# ── Lord Vindex (SULIT) ───────────────────────────────────────────────
const VINDEX_MOVE_DELAY = 300
const VINDEX_POWER_BEAM_WIDTH = 82
const VINDEX_POWER_DAMAGE = 2
const LORD_SPEED = 2.5
const LORD_EVADE_SPEED = 5.0

# ── Lord Vindex: tantangan khusus setelah poin 25 ────────────────────
# Time Stop Vindex, Rentetan Laser, dan Pusaran Ungu tidak pernah berjalan bersamaan.
const VINDEX_BARRAGE_MIN_SCORE = 51 # aktif di atas poin 50
const VINDEX_BARRAGE_COOLDOWN_MIN = 1500 # jeda antar-rentetan (frame)
const VINDEX_BARRAGE_COOLDOWN_MAX = 2400
const VINDEX_BARRAGE_GATHER = 110 # Vindex berjalan ke tengah arena (maks frame)
const VINDEX_BARRAGE_ROUNDS = 3 # jumlah gelombang tembakan
const VINDEX_BARRAGE_BEAMS = 3 # laser per gelombang
const VINDEX_BARRAGE_WARN = 120 # 2 detik peringatan sebelum menembak
const VINDEX_BARRAGE_FIRE = 34 # lama laser menyala
const VINDEX_BARRAGE_GAP = 16 # jeda singkat antar-gelombang
const VINDEX_BARRAGE_WIDTH = 54 # lebar tiap laser
const VINDEX_BARRAGE_SAFE_RADIUS = 135 # titik/item tidak boleh muncul sedekat ini dari pusat saat rentetan
const VINDEX_BARRAGE_MIN_SPREAD = 0.62 # sudut minimal antar-laser (rad)
const VINDEX_BARRAGE_MIN_FROM_PLAYER = 0.42 # laser tidak boleh langsung mengarah ke pemain (rad)

const VORTEX_MIN_SCORE = 75 # aktif pada poin 75 ke atas
const VORTEX_COOLDOWN_MIN = 1000
const VORTEX_COOLDOWN_MAX = 1700
const VORTEX_ACTIVE_TIME = 240 # menyala 4 detik
const VORTEX_KILL_RADIUS = 46 # siapa pun yang masuk lingkaran ini mati
const VORTEX_PULL_RADIUS = 270 # jangkauan hisapan
const VORTEX_PULL_MAX = 2.7 # kecepatan hisap maksimum di tepi lingkaran maut (px/frame)
const VORTEX_SPAWN_MIN_PLAYER = 230 # jarak minimal dari pemain saat muncul
const VORTEX_SPAWN_MIN_VINDEX = 120
const VORTEX_BLAST_POWER = 22 # dorongan ledakan (seperti meteor besar)
const VORTEX_SAFE_RADIUS = 150 # item tidak boleh muncul sedekat ini dari pusaran

# ── Lainnya ───────────────────────────────────────────────────────────
const MAX_LEVEL = 100

# ── Audio ───────────────────────────────────────────────────────────────
# Letakkan file audio di assets/audio/ dengan nama persis seperti di bawah.
# File yang belum ada otomatis dilewati (game tetap jalan). Isi `null` untuk menonaktifkan satu suara.
    # jeda minimal antar pemutaran (ms) agar suara tidak menumpuk

# ── Tautan antar halaman (scene Godot) ─────────────────────────────────
const PAGES = {
	"menu": "res://scenes/menu/menu.tscn",
	"rules": "res://scenes/menu/rules.tscn",
	"game": "res://scenes/game/game.tscn",
}

# ── Audio ───────────────────────────────────────────────────────────────
# Taruh file audio di assets/audio/ dengan nama persis seperti di bawah.
# File yang belum ada otomatis dilewati (game tetap jalan). Isi null untuk menonaktifkan satu suara.
const AUDIO = {
	"base_path": "res://assets/audio/",   # folder audio
	"master_volume": 1.0,
	"music_volume": 0.45,                 # volume lagu normal
	"muffled_music_volume": 0.22,         # volume lagu saat Time Stop (teredam)
	"muffled_frequency": 380.0,           # Hz — makin kecil makin "terpendam"
	"sfx_volume": 0.85,
	"files": {
		"music": "music-main.mp3",          # lagu latar (loop) — Mudah & Normal
		"music_hard": null,                 # lagu khusus Sulit (opsional): isi "music-hard.mp3"; null = pakai music-main
		"point": "sfx-point.mp3",           # dapat poin
		"health": "sfx-health.mp3",         # dapat nyawa
		"power_kill": "sfx-power-kill.mp3", # ambil Power Kill
		"time_stop": "sfx-time-stop.mp3",   # ambil Time Stop
		"hit": "sfx-hit.mp3",               # pemain terkena serangan apa pun
		"killer_laugh": "sfx-killer-laugh.mp3", # tawa Killer (tambahan saat Killer yang mengenai pemain)
		"meteor_pass": "sfx-meteor-pass.mp3",   # satu meteor kecil lewat
		"meteor_big": "sfx-meteor-big.mp3",     # meteor besar jatuh
	},
	# jeda minimal antar pemutaran (ms) agar suara tidak menumpuk
	"min_gap": {"point": 0, "hit": 120, "meteor_pass": 280},
}
