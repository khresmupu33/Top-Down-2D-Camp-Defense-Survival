extends Node
## Konfigurasi mode DALANG (dari modes/dalang/config.js).
## Kamu menjadi PEMBERI TANTANGAN (dalang bencana); BOT-X yang bermain.
## Semua angka penyeimbang ada di sini (satuan: frame @60FPS, kecuali disebut lain).
## Pemakaian: DalangConfig.DL.ENERGY_MAX, DalangConfig.DL_SKILLS, DalangConfig.DL_SKILL["killer"].

const DL := {
	# ── tujuan level: ADU CEPAT ──
	# Tidak ada Inti. Habiskan 3 nyawa BOT secepat mungkin; makin singkat waktunya, makin bagus rekornya.
	"RECORD_KEY": "dalang-best-v2",   # kunci penyimpanan rekor (waktu tersingkat, dtk)
	"ROAM_EVERY": 150,                # BOT ganti titik jelajah tiap +- sekian frame
	"ROAM_WEIGHT": 0.45,              # seberapa kuat BOT tertarik ke titik jelajah (lebih kecil dari mengejar tujuan)

	# ── ekonomi energi dalang ──
	"ENERGY_MAX": 100,
	"ENERGY_START": 60,
	"ENERGY_REGEN": 0.085,      # per frame (sekitar 5,1 energi / detik)
	"HIT_REWARD": 12,           # energi bonus tiap 1 nyawa BOT berhasil dikurangi

	# ── batas pemanggilan ──
	# (tidak ada batas jumlah Killer / Archer; hanya energi & cooldown yang membatasi)
	"KILLER_MIN_DIST": 130,     # tidak boleh dipanggil menempel BOT (px)
	"ARCHER_MIN_DIST": 170,

	# ── Hujan Meteor ──
	"RAIN_WARN": 50,            # peringatan sebelum hujan turun
	"RAIN_DURATION": 230,
	"RAIN_HALF_WIDTH": 150,     # lebar jalur = 2 x ini
	"RAIN_INTERVAL": 8,

	# ── Meteor Besar ──
	"BIG_WARN": 70,             # peringatan lingkaran sebelum batu jatuh

	# ── Laser ──
	"LASER_WARN": 52,
	"LASER_FIRE": 38,
	"LASER_WIDTH": 56,
	"LASER_DAMAGE": 2,

	# ── Time Stop dalang: BOT membeku sementara, bencana tetap bergerak ──
	"FREEZE": 180,              # 3 detik, tetap sama tiap dipakai
	"FREEZE_FACTOR": 0.08,      # kecepatan BOT selama beku
	"FREEZE_DECAY": 1,          # pengali durasi tiap Time Stop dipakai (1 = tetap 3 detik; <1 = makin singkat)
	"FREEZE_SHIELD": 2,         # PERISAI WAKTU: BOT menahan sekian poin kerusakan pertama selama beku
	"FREEZE_IFRAMES": 62,       # selama beku, jeda kebal setelah terkena diperpanjang (anti-tumpuk serangan)
	"FREEZE_MIN": 55,           # durasi terpendek bila FREEZE_DECAY < 1

	# ── AMUK: BOT lari lebih cepat sesaat setelah terluka / lepas dari beku ──
	"RAGE_SPEED": 1.35,
	"RAGE_AFTER_HIT": 120,
	"RAGE_AFTER_FREEZE": 150,

	# ── item untuk BOT (detik): mengikuti ritme level Normal, dipercepat ──
	"POWER_FIRST": [20, 28],
	"POWER_RESPAWN": [26, 36],
	"TS_FIRST": [12, 18],
	"TS_RESPAWN": [24, 34],
	"HEALTH_FIRST": [18, 26],
	"HEALTH_RESPAWN": [20, 30],

	# ── kecerdasan BOT ──
	"LEARN_STEP": 0.2,          # tiap kena jenis serangan X, BOT lebih waspada pada X
	"LEARN_MAX": 1.8,
}

## Daftar skill dalang (urutan = tombol 1..6).
const DL_SKILLS := [
	{"id": "killer", "key": "1", "label": "KILLER", "icon": "💀", "cost": 16, "cd": 200, "aim": "point", "tip": "Klik arena: panggil Killer. Ia mengisi daya 2 detik lalu mengejar BOT. Jumlahnya tak dibatasi."},
	{"id": "archer", "key": "2", "label": "ARCHER", "icon": "🏹", "cost": 20, "cd": 330, "aim": "point", "tip": "Klik arena: panggil Archer penembak panah. Jumlahnya tak dibatasi."},
	{"id": "rain", "key": "3", "label": "HUJAN", "icon": "☄️", "cost": 30, "cd": 600, "aim": "lane", "tip": "Klik arena: jalur hujan meteor selebar 300 px selama ±4 detik."},
	{"id": "big", "key": "4", "label": "METEOR BESAR", "icon": "🪨", "cost": 38, "cd": 420, "aim": "point", "tip": "Klik arena: lingkaran peringatan, lalu batu raksasa menghantam (2 nyawa)."},
	{"id": "laser", "key": "5", "label": "LASER", "icon": "⚡", "cost": 30, "cd": 420, "aim": "beam", "tip": "Tekan & seret untuk mengarahkan sinar (atau R / roda mouse untuk memutar). Lepas untuk menembak."},
	{"id": "freeze", "key": "6", "label": "TIME STOP", "icon": "⏳", "cost": 55, "cd": 1500, "aim": "instant", "tip": "Seketika: BOT membeku 3 dtk & bencanamu tetap bergerak. Tapi Perisai Waktu menahan 2 poin serangan pertama!"},
]

## Peta id skill -> skill (dibangun sekali dari DL_SKILLS).
var DL_SKILL: Dictionary = _build_skill_map()


func _build_skill_map() -> Dictionary:
	var m := {}
	for s in DL_SKILLS:
		m[s.id] = s
	return m
