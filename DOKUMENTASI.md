# Dokumentasi: Killer & Gadfly (Godot 4.5)

Dokumen ini menjelaskan seluruh proyek: isi root, kegunaan setiap folder, kegunaan setiap berkas, dan kegunaan setiap metode. Bagian 4, 5, dan 9 dibuat langsung dari kode. Bagian lain disusun dari `project.godot`, `README.md`, `docs/ARSITEKTUR.md`, dan kode.

**Daftar isi**

1. [Gambaran umum](#1-gambaran-umum)
2. [Cara menjalankan dan menguji](#2-cara-menjalankan-dan-menguji)
3. [Root proyek](#3-root-proyek)
4. [Kegunaan setiap folder](#4-kegunaan-setiap-folder)
5. [Autoload (singleton)](#5-autoload-singleton)
6. [Alur frame](#6-alur-frame)
7. [Scene](#7-scene)
8. [Aset audio dan foto](#8-aset-audio-dan-foto)
9. [Dokumentasi per berkas dan metode](#9-dokumentasi-per-berkas-dan-metode)
10. [Catatan, temuan, dan batasan](#10-catatan-temuan-dan-batasan)

## 1. Gambaran umum

Killer & Gadfly adalah game arena 800×600. Pemain mengumpulkan target dan menghindari Gadfly, Killer, Archer, meteor, dan (mode SULIT) Lord Vindex. Proyek ini adalah port Godot dari versi web. Logika dan angka penyeimbang dipertahankan; loop, gambar, dan UI memakai pola Godot.

Angka proyek:

- 44 berkas GDScript dengan 397 fungsi.
- 37 autoload (singleton).
- 3 scene (`.tscn`).
- Godot 4.5.1 standar, renderer GL Compatibility, physics 60 tick per detik.
- Kanvas dasar 1200×900 (ukuran halaman web). Papan permainan 800×600 berada di tengahnya.

Mode permainan (dari `README.md`):

- **MUDAH** dan **NORMAL**: kumpulkan target, hindari Gadfly, Killer, dan meteor. Normal juga memunculkan Archer.
- **SULIT**: sampai poin 100, dengan Lord Vindex (Time Stop di poin 25, Rentetan Laser di atas 50, Pusaran Ungu dari 75).
- **CARA MAIN**: aturan dan penjelasan tiap karakter.

## 2. Cara menjalankan dan menguji

Menjalankan: buka `project.godot` dengan Godot 4.5 lalu tekan F5. Dari terminal, cukup `godot --path .`.

Tes headless, dijalankan dari folder proyek:

```
godot --headless --path . --script res://tests/compile_check.gd
godot --headless --path . --script res://tests/smoke_test.gd
```

- `compile_check.gd` memuat semua skrip di `res://scripts`, mencetak `LOAD FAILED` untuk yang gagal, lalu keluar dengan kode 1 bila ada kegagalan.
- `smoke_test.gd` memainkan tiga run (MUDAH, NORMAL, dan SULIT). Tiap run sekitar 2600 frame dengan input acak. Setelah semua run selesai, skrip keluar dengan `quit(0)`.

## 3. Root proyek

Isi folder `killer-gadfly-godot/`. Folder `.godot/` hanya disebut sebagai catatan karena dibuat otomatis oleh editor Godot.

| Berkas / folder | Kegunaan |
|---|---|
| `project.godot` | Konfigurasi proyek: nama, scene awal `res://scenes/menu/menu.tscn`, daftar 37 autoload, ukuran layar 1200×900, mode jendela maksimal (`window/size/mode=2`), stretch `canvas_items` dengan aspect `expand`, physics 60 tick per detik, dan renderer `gl_compatibility`. Sebaiknya diatur lewat editor Godot, bukan diedit manual. |
| `README.md` | Cara menjalankan, kontrol, daftar mode, struktur folder, catatan audio, dan catatan porting dari versi web. |
| `icon.svg` | Ikon proyek 128×128 (`config/icon`). |
| `.gitignore` | Mengabaikan `.godot/`, `*.translation`, dan `export_presets.cfg.bak`. |
| `docs/` | Dokumentasi. Berisi `ARSITEKTUR.md` (arsitektur, konvensi, dan pemetaan dari versi web) dan `DOKUMENTASI.md` (dokumen ini). |
| `assets/` | Aset non-kode: `audio/` (efek suara) dan `photos/` (foto peta dan entitas). |
| `scenes/` | Scene Godot (`.tscn`), dibagi menjadi `game/` dan `menu/`. |
| `scripts/` | Seluruh kode GDScript, dibagi menurut tanggung jawab (lihat bagian 4). |
| `tests/` | Dua skrip uji yang dijalankan dengan `--script`. Skrip ini bukan autoload. |
| `.godot/` | Cache dan hasil impor yang dibuat otomatis oleh editor. Tidak perlu disalin, dan sudah diabaikan oleh `.gitignore`. |

## 4. Kegunaan setiap folder

Jumlah berkas dan fungsi dihitung dari kode. Folder `.godot/` tidak termasuk.

| Folder | Kegunaan | Berkas `.gd` | Fungsi |
|---|---|---|---|
| `assets/audio/` | Efek suara `.mp3` (placeholder hening) dan `README.md` yang mendaftar nama berkas yang diharapkan. | - | - |
| `assets/photos/` | Foto peta (`map/`) dan entitas (`entities/`) yang dibaca `PhotoKit` sesuai `Config.PHOTOS.files`, plus `README.md` yang mendaftar nama berkas dan ukuran. Berkas yang belum ada dilewati. | - | - |
| `docs/` | Dokumentasi: `ARSITEKTUR.md` (arsitektur dan pemetaan dari versi web) serta dokumen ini. | - | - |
| `scenes/game/` | Scene arena permainan `game.tscn` (Game → Board → Arena), dipakai semua mode. | - | - |
| `scenes/menu/` | Scene menu utama `menu.tscn` (scene awal) dan CARA MAIN `rules.tscn`. | - | - |
| `scripts/core/` | Konstanta gameplay (`config.gd`), variabel status global (`state.gd`), dan utilitas umum (`util.gd`). | 3 | 11 |
| `scripts/game/` | Alur permainan: akar scene (`game_root.gd`), penyiapan objek (`setup.gd`), dispatcher 60 Hz (`loop.gd`), alur mulai/jeda/ending (`flow.gd`), dan input (`input.gd`). | 5 | 29 |
| `scripts/systems/` | Sistem pendukung: musik dan SFX (`audio.gd`), HUD (`hud.gd`), tombol MENU (`menu_button.gd`), partikel, cerita, subtitle SULIT, dan Time Stop. | 7 | 33 |
| `scripts/render/` | Penggambaran arena: latar, efek, sprite semua karakter, pembantu gambar `DrawKit`, dan pemuat foto `PhotoKit`. | 7 | 82 |
| `scripts/render/sprites/` | Pembantu bentuk (`shapes.gd`) untuk membangun cache sprite. | 1 | 7 |
| `scripts/entities/` | Entitas mode umum: pemain, item, Killer, Gadfly, Archer, meteor, dan Lord Vindex. | 7 | 49 |
| `scripts/modes/hard/` | Mode SULIT: adegan pembuka, urutan poin 25, serangan Lord Vindex, dan bot penonton SANTAI (`test_bot.gd`). | 4 | 63 |
| `scripts/ui/` | UI: pembantu gaya (`ui_kit.gd`), pembangun layar game (`game_ui.gd`), menu (`menu_screen.gd`), dan CARA MAIN (`rules_screen.gd`). | 4 | 62 |
| `tests/` | Skrip uji: pemeriksaan kompilasi (`compile_check.gd`) dan uji asap lima mode (`smoke_test.gd`). Dijalankan dengan `--script`, bukan autoload. | 2 | 3 |

## 5. Autoload (singleton)

Autoload adalah singleton yang bisa dipanggil dari mana saja sebagai `Nama.fungsi()`. Nama JS camelCase diubah menjadi snake_case (`hitVX` → `hit_vx`). `GameMenuButton` diberi nama berbeda karena `MenuButton` sudah dipakai class bawaan Godot.

Skrip yang tidak di-autoload: `game_root.gd`, `arena.gd`, `menu_screen.gd`, dan `rules_screen.gd` (dipasang ke scene); `shapes.gd` (di-preload oleh `sprites.gd` sebagai `Shapes`); serta `compile_check.gd` dan `smoke_test.gd` (dijalankan dengan `--script`).

| Nama | Berkas | Peran |
|---|---|---|
| `Config` | `res://scripts/core/config.gd` | Konstanta gameplay dan konfigurasi audio. |
| `State` | `res://scripts/core/state.gd` | Seluruh variabel status permainan. |
| `Util` | `res://scripts/core/util.gd` | Waktu, timer, pindah scene, angka acak, tabrakan, dan gerak dasar. |
| `DrawKit` | `res://scripts/render/draw_kit.gd` | Pembantu gambar pengganti `ctx.*` canvas JS. |
| `PhotoKit` | `res://scripts/render/photo_kit.gd` | Pemuat dan penggambar foto peta dan entitas (versi foto). |
| `GameAudio` | `res://scripts/systems/audio.gd` | Musik latar dan efek suara. |
| `TimeStop` | `res://scripts/systems/time_stop.gd` | Faktor perlambatan dan item Time Stop. |
| `Particles` | `res://scripts/systems/particles.gd` | Pembaruan partikel. |
| `Story` | `res://scripts/systems/story.gd` | Pemicu cerita dan kemunculan Archer berdasar skor. |
| `Hud` | `res://scripts/systems/hud.gd` | Teks skor, ikon nyawa, status power, dan tombol pause. |
| `HardSubtitle` | `res://scripts/systems/subtitle.gd` | Subtitle Lord Vindex mode SULIT. |
| `GameMenuButton` | `res://scripts/systems/menu_button.gd` | Tombol MENU dan kotak konfirmasi. |
| `Sprites` | `res://scripts/render/sprites.gd` | Penggambar semua karakter dan item. |
| `Effects` | `res://scripts/render/effects.gd` | Efek di atas karakter (Time Stop, peringatan, laser, pusaran). |
| `Background` | `res://scripts/render/background.gd` | Latar papan catur dan vignette. |
| `DrawGame` | `res://scripts/render/draw_game.gd` | Menyusun satu frame gambar (latar, efek, getaran layar). |
| `Player` | `res://scripts/entities/player.gd` | Logika pemain. |
| `Items` | `res://scripts/entities/items.gd` | Kemunculan dan pemindahan item koleksi. |
| `Killers` | `res://scripts/entities/killers.gd` | Killer: spawn, pengejaran, tabrakan, dan penguraian. |
| `Gadflies` | `res://scripts/entities/gadflies.gd` | Gadfly yang bergerak di tepi arena. |
| `Archers` | `res://scripts/entities/archers.gd` | Archer dan anak panah. |
| `Meteors` | `res://scripts/entities/meteors.gd` | Hujan meteor dan meteor besar. |
| `LordVindex` | `res://scripts/entities/lord_vindex.gd` | Lord Vindex (bos mode SULIT). |
| `VindexAttacks` | `res://scripts/modes/hard/vindex_attacks.gd` | Serangan Lord Vindex mode SULIT. |
| `HardIntro` | `res://scripts/modes/hard/hard_intro.gd` | Adegan pembuka mode SULIT. |
| `HardSequence` | `res://scripts/modes/hard/hard_sequence.gd` | Urutan poin 25 mode SULIT. |
| `GameSetup` | `res://scripts/game/setup.gd` | Membuat objek awal permainan. |
| `GameLoop` | `res://scripts/game/loop.gd` | Dispatcher loop 60 Hz dan satu tick permainan. |
| `GameFlow` | `res://scripts/game/flow.gd` | Alur mulai, jeda, ending, game over, dan pindah layar. |
| `GameInput` | `res://scripts/game/input.gd` | Input keyboard, sentuh, dan klik. |
| `GameUI` | `res://scripts/ui/game_ui.gd` | Pembangun seluruh UI layar game. |
| `UiKit` | `res://scripts/ui/ui_kit.gd` | Pembantu UI bersama (font, tombol, latar, teks berpendar). |

## 6. Alur frame

Semua logika permainan berjalan dari `GameLoop._physics_process` pada 60 Hz:

```
if not State.in_game: return
if State.level == "dalang": DalangFlow.run_dalang()
else match State.game_state:
    "playing":   GameLoop.run_game()          # TestBot.tick() bila penonton, lalu GameLoop.update_game()
    "hardIntro": HardIntro.run_hard_intro()
    "ending":    GameFlow.run_ending_animation()
```

Di luar loop itu:

- `Arena._process` menggeser posisi `Arena` dengan `DrawGame.get_shake_offset()` untuk getaran layar, lalu meminta gambar ulang.
- `Arena._draw` memanggil `DrawGame.draw_bg`, `Sprites.draw_all`, dan `DrawGame.draw_fx`, berurutan.
- `GameRoot._process` memanggil `Hud.update_hud()` tiap frame selama `State.in_game`.
- Input keyboard ditangani `GameInput._input`. Klik dan sentuh yang tidak ditangani kontrol lain ditangani `GameInput._unhandled_input`. Tombol layar sentuh di `GameUI` memanggil `GameInput.control_down` dan `control_up`. Mode DALANG punya input sendiri di `DalangFlow._input`.
- Timer berbasis frame memakai hitungan frame. Timer berbasis waktu nyata memakai `Util.now()`. Penundaan memakai `Util.after_ms()`.
- Pindah layar lewat `Util.goto_page("menu" | "rules" | "game")`. Level dan mode penonton dikirim lewat `State.page_level` dan `State.spectator_mode`.

## 7. Scene

Proyek punya tiga scene. Semua UI permainan dibangun dengan kode, sehingga scene hanya menyediakan node akar dan papan.

**`scenes/game/game.tscn`** (dipakai semua mode):

```
Game     (Control penuh; script game_root.gd)
└── Board  (Panel 800×600 di tengah; clip_contents; mouse_filter abaikan)
    └── Arena  (Node2D; script arena.gd)
```

HUD, overlay, layar akhir, dan panel DALANG dibuat oleh `GameUI.build` di dalam `Board`. Latar dan bingkai papan dipasang oleh `GameUI.build_stage(self, board)`.

**`scenes/menu/menu.tscn`**: `Menu` (Control penuh; script `ui/menu_screen.gd`). Judul dan tombol dibangun di `_ready()`. Ini scene awal.

**`scenes/menu/rules.tscn`**: `Rules` (Control penuh; script `ui/rules_screen.gd`). Panel dan daftar aturan dibangun di `_ready()`.

## 8. Aset audio dan foto

### Aset audio

Lokasi: `assets/audio/`. Nama berkas harus sama dengan nilai di `Config.AUDIO.files` (`scripts/core/config.gd`).

| Berkas | Kunci di `Config.AUDIO.files` | Kapan diputar |
|---|---|---|
| `music-main.mp3` | `music` | Lagu latar saat permainan dimulai. Diredam saat Time Stop, dan berhenti saat game over atau ending. **Belum ada di folder ini.** |
| `music-hard.mp3` (opsional) | `music_hard` | Lagu khusus SULIT. Bila tidak ada, SULIT memakai `music`. |
| `sfx-point.mp3` | `point` | Pemain mengambil target dan dapat poin. |
| `sfx-health.mp3` | `health` | Pemain mengambil item nyawa. |
| `sfx-power-kill.mp3` | `power_kill` | Pemain mengambil Power Kill. |
| `sfx-time-stop.mp3` | `time_stop` | Pemain mengambil item Time Stop. |
| `sfx-hit.mp3` | `hit` | Pemain terkena serangan (Killer, Gadfly, panah, meteor, atau Vindex). |
| `sfx-killer-laugh.mp3` | `killer_laugh` | Tawa Killer. Diputar bersama `hit` bila Killer yang mengenai pemain. |
| `sfx-meteor-pass.mp3` | `meteor_pass` | Satu meteor kecil muncul. Dibatasi satu kali tiap 0,28 detik. |
| `sfx-meteor-big.mp3` | `meteor_big` | Meteor besar jatuh. |

Keadaan saat ini:

- Delapan berkas `sfx-*.mp3` adalah placeholder hening (539 byte). Ganti dengan file asli dengan nama yang sama.
- Berkas yang tidak ada diabaikan tanpa error (`GameAudio._get_stream` mengembalikan `null`). Karena itu `music-main.mp3` yang belum ada membuat lagu latar diam, tetapi game tetap berjalan.
- Volume, tingkat redaman, dan jeda antar-suara diatur di blok `AUDIO` pada `config.gd`.

### Aset foto

Lokasi: `assets/photos/` (`map/` dan `entities/`). Nama berkas harus sama dengan nilai di `Config.PHOTOS.files` (`scripts/core/config.gd`). Daftar lengkap nama, ukuran tampil, rasio, dan arah ada di `assets/photos/README.md`.

- Pola sama dengan audio: berkas yang belum ada dilewati tanpa error, dan bagian itu tetap digambar dengan gaya vektor bawaan. Foto boleh diisi satu per satu.
- `PhotoKit` memuat semua foto sekali saat game dibuka (dengan mipmap supaya foto besar tetap halus saat diperkecil). Di build debug, konsol mencetak jumlah foto yang dimuat dan daftar yang belum ada.
- Peta: `map` (latar arena semua level, dipotong dari tengah bila rasio bukan 4:3, vignette tetap di atasnya), `map_hard_intro` (adegan pembuka SULIT), `map_ending` (adegan ending, digelapkan 45%).
- Entitas: `player` (juga BOT-X), `target`, `health`, `power`, `timestop`, `gadfly` (+ `gadfly_frozen`), `killer`, `archer`, `arrow` (+ `arrow_lord`), `vindex`, `meteor` (+ `meteor_hard`), `meteor_big`.
- Foto digambar pada kotak desain yang sama dengan gambar vektor di `Sprites`, jadi pose, rotasi, skala, denyut, kedip terkena, dan urutan tumpukan tidak berubah. Efek tetap vektor: ekor meteor, cincin pengisian Killer, ikon `!` dan `HA!`, label `AIM`, aura Power Kill, aura Vindex, laser, pusaran, partikel, HUD.
- Foto opsional yang tidak ada diganti pewarnaan dari foto dasarnya: `gadfly_frozen` (warna dingin), `arrow_lord` (ungu), `meteor_hard` (ungu).
- Mematikan semua foto: `Config.PHOTOS.enabled = false`.
- `tools/make_placeholder_photos.py` (Python + Pillow) membuat 18 gambar pengganti (ilustrasi, bukan foto) untuk mengetes jalur foto; tanpa `--force` file yang sudah ada tidak ditimpa.

## 9. Dokumentasi per berkas dan metode

Setiap berkas punya blok: peran, asal port (bila ada), jumlah fungsi, konstanta (bila ada), dan tabel metode. Arti kolom tabel metode:

- **Metode**: nama dan parameter sesuai kode.
- **Parameter**: tipe tiap parameter. `(tanpa tipe)` berarti tidak diketik.
- **Kembalian**: tipe hasil. `void` berarti tidak mengembalikan nilai.
- **Kegunaan**: fungsi metode, dibaca dari kode.
- **Dipakai oleh**: pemanggil yang ditemukan di kode. `Owner.fungsi` adalah pemanggil di berkas lain, dengan `Owner` berupa nama autoload atau nama kelas scene (`GameRoot`, `Arena`, `MenuScreen`, `RulesScreen`). `internal` berarti dipanggil dari berkas yang sama. `Callable` berarti dilewatkan sebagai referensi (sinyal, timer, atau `.bind`). `engine (Godot)` berarti callback yang dipanggil engine. `tidak ada pemanggil ditemukan` berarti tidak dipakai di kode.

### 9.1 `scripts/core`

#### `scripts/core/config.gd`

**Peran:** autoload `Config` (extends Node) — kumpulan konstanta gameplay (satuan frame @60 FPS atau ms), tautan scene, dan konfigurasi audio. Diakses sebagai `Config.NAMA`.
**Port dari:** `core/config.js`
**Jumlah fungsi:** 0

##### Konstanta & variabel

**Arena**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `WIDTH`, `HEIGHT` | `800`, `600` | Ukuran arena dalam piksel. |

**Pemain**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `PLAYER_SPEED` | `4` | Kecepatan gerak pemain. |

**Killer**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `KILLER_LOAD_TIME` | `120` | Waktu muat/persiapan killer (frame). |
| `KILLER_KNOCKBACK_TIME`, `KILLER_KNOCKBACK_POWER` | `35`, `11` | Durasi dan kekuatan dorongan killer saat terpental. |
| `KILLER_COLLISION_COOLDOWN` | `22` | Jeda antar tabrakan killer. |
| `GLOBAL_KILLER_FREEZE` | `45` | Durasi pembekuan global killer. |
| `KILLER_FIRST_TIME`, `KILLER_NEXT_TIME` | `9000`, `9000` | Jeda (ms) munculnya killer pertama/berikutnya. |
| `MAX_KILLERS` | `12` | Batas jumlah killer. |

**Gadfly**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `GADFLY_HIT_TIME` | `28` | Durasi animasi/efek Gadfly terkena (frame). |

**Item: power kill, nyawa**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `POWER_DURATION` | `600` | Durasi Power Kill (frame). |
| `POWER_FIRST_MIN/MAX`, `POWER_RESPAWN_MIN/MAX` | `30000`-`40000` | Rentang waktu (ms) kemunculan pertama dan respawn Power Kill. |
| `POWER_FLEE_SPEED_MULTIPLIER`, `POWER_SAFE_MARGIN` | `1`, `32` | Pengali kecepatan kabur dan margin aman terkait Power Kill. |
| `HEALTH_FIRST_MIN/MAX`, `HEALTH_RESPAWN_MIN/MAX` | `20000`-`30000` | Rentang waktu (ms) kemunculan pertama dan respawn item nyawa. |

**Meteor besar**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `LARGE_METEOR_RANDOM_MIN/MAX` | `2100`-`3900` | Rentang acak waktu spawn meteor besar. |
| `LARGE_METEOR_WARNING_TIME` | `150` | Durasi peringatan sebelum jatuh. |
| `LARGE_METEOR_DELAY_MIN/MAX` | `30`-`55` | Rentang jeda meteor besar. |
| `LARGE_METEOR_SPEED`, `LARGE_METEOR_SIZE` | `5.2`, `100` | Kecepatan dan ukuran. |
| `LARGE_METEOR_BLAST_RADIUS`, `LARGE_METEOR_DIRECT_RADIUS` | `150`, `60` | Radius ledakan dan radius tumbukan langsung. |
| `LARGE_METEOR_MAX_IMPACT_PARTICLES` | `18` | Batas partikel tumbukan. |
| `LARGE_METEOR_PLAYER_DAMAGE`, `LARGE_METEOR_SHOCK_POWER` | `2`, `18` | Kerusakan ke pemain dan dorongan kejut. |

**Meteor**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `METEOR_FIRST_MIN/MAX` | `1200`-`1800` | Rentang waktu hujan meteor pertama. |
| `METEOR_SESSION_DURATION`, `METEOR_SPAWN_INTERVAL` | `1080`, `34` | Durasi sesi hujan meteor dan interval spawn. |
| `METEOR_SPEED_MIN/MAX` | `5`-`8` | Rentang kecepatan meteor. |
| `METEOR_PLAYER_COOLDOWN`, `METEOR_SAFE_MARGIN` | `55`, `8` | Jeda kena meteor untuk pemain dan margin aman. |
| `METEOR_FIRST_BURST`, `METEOR_SECOND_BURST`, `METEOR_SECOND_BURST_TIME`, `METEOR_BURST_COOLDOWN` | `12`, `10`, `420`, `55` | Parameter gelombang (burst) meteor. |
| `METEOR_NEXT_SESSION_MIN/MAX` | `1500`-`2700` | Rentang jeda sesi berikutnya. |
| `METEOR_TRIGGER_SCORE` | `10` | Skor pemicu hujan meteor. |
| `METEOR_PRE_SHOWER_MIN/MAX`, `METEOR_PRE_SHOWER_SPAWN_INTERVAL_MIN/MAX`, `METEOR_PRE_SHOWER_MAX_METEORS` | `1200`-`1800`, `150`-`300`, `5` | Parameter fase pra-hujan meteor (durasi, interval spawn, jumlah maksimum). |

**Archer**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `MAX_ARCHERS` | `5` | Batas jumlah archer. |
| `ARCHER_LOAD_TIME`, `ARCHER_FIRE_INTERVAL` | `110`, `145` | Waktu muat dan interval tembak. |
| `ARCHER_SPEED`, `ARCHER_ARROW_SPEED` | `1.8`, `5.2` | Kecepatan archer dan anak panah. |
| `ARCHER_FIRST_SCORE` | `5` | Skor kemunculan archer pertama. |
| `ARCHER_SPAWN_MIN/MAX` | `15000`-`22000` | Rentang waktu (ms) spawn archer. |
| `ARCHER_POWER_EVADE_DISTANCE`, `ARCHER_POWER_TELEPORT_DISTANCE` | `190`, `260` | Jarak menghindar/teleport archer saat pemain punya Power Kill. |
| `ARCHER_ARROW_DAMAGE_COOLDOWN` | `35` | Jeda kerusakan antar anak panah. |

**Time Stop**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `TIME_STOP_DURATION`, `TIME_STOP_SLOW` | `300`, `0.18` | Durasi dan faktor perlambatan dunia. |
| `TIME_STOP_FIRST_MIN/MAX` | `18000`-`26000` | Rentang waktu (ms) kemunculan pertama item. |
| `TIME_STOP_RESPAWN_MIN/MAX` | `26000`-`38000` | Rentang waktu (ms) respawn item. |

**Lord Vindex (SULIT)**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `VINDEX_MOVE_DELAY` | `300` | Jeda gerak Vindex. |
| `VINDEX_POWER_BEAM_WIDTH`, `VINDEX_POWER_DAMAGE` | `82`, `2` | Lebar sinar dan kerusakan serangan power Vindex. |
| `LORD_SPEED`, `LORD_EVADE_SPEED` | `2.5`, `5.0` | Kecepatan normal dan menghindar Lord. |

**Lord Vindex: tantangan khusus setelah poin 25**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `VINDEX_BARRAGE_MIN_SCORE` | `51` | Rentetan Laser aktif di atas poin 50. |
| `VINDEX_BARRAGE_COOLDOWN_MIN/MAX` | `1500`-`2400` | Jeda antar-rentetan (frame). |
| `VINDEX_BARRAGE_GATHER`, `_ROUNDS`, `_BEAMS`, `_WARN`, `_FIRE`, `_GAP`, `_WIDTH` | `110`, `3`, `3`, `120`, `34`, `16`, `54` | Fase kumpul, jumlah gelombang, laser per gelombang, peringatan, lama menyala, jeda, lebar laser. |
| `VINDEX_BARRAGE_SAFE_RADIUS` | `135` | Titik/item tidak muncul sedekat ini dari pusat saat rentetan. |
| `VINDEX_BARRAGE_MIN_SPREAD`, `VINDEX_BARRAGE_MIN_FROM_PLAYER` | `0.62`, `0.42` | Sudut minimal antar-laser dan dari arah pemain (rad). |
| `VORTEX_MIN_SCORE` | `75` | Pusaran Ungu aktif pada poin 75 ke atas. |
| `VORTEX_COOLDOWN_MIN/MAX`, `VORTEX_ACTIVE_TIME` | `1000`-`1700`, `240` | Jeda dan lama aktif pusaran. |
| `VORTEX_KILL_RADIUS`, `VORTEX_PULL_RADIUS`, `VORTEX_PULL_MAX` | `46`, `270`, `2.7` | Radius maut, jangkauan hisap, kecepatan hisap maksimum. |
| `VORTEX_SPAWN_MIN_PLAYER`, `VORTEX_SPAWN_MIN_VINDEX` | `230`, `120` | Jarak minimal spawn dari pemain dan Vindex. |
| `VORTEX_BLAST_POWER`, `VORTEX_SAFE_RADIUS` | `22`, `150` | Dorongan ledakan dan radius aman item. |

**Lainnya**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `MAX_LEVEL` | `100` | Angka level akhir; dipakai sebagai judul "LEVEL N" di latar ending (`DrawGame`). |

**Audio (blok komentar lama)** — hanya komentar tanpa konstanta (sisa duplikat; konstanta `AUDIO` ada di kelompok Audio di bawah).

**Tautan antar halaman (scene Godot)**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `PAGES` | `Dictionary` kunci `"menu"`, `"rules"`, `"game"` ke path `.tscn` | Peta kunci halaman ke scene; dipakai `Util.goto_page`. |

**Audio**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `AUDIO` | `Dictionary` | Konfigurasi audio: `base_path` (`res://assets/audio/`), `master_volume` 1.0, `music_volume` 0.45, `muffled_music_volume` 0.22, `muffled_frequency` 380 Hz, `sfx_volume` 0.85. |
| `AUDIO.files` | `Dictionary` nama suara ke nama file (atau `null`) | Daftar file: music, music_hard (null), point, health, power_kill, time_stop, hit, killer_laugh, meteor_pass, meteor_big. |
| `AUDIO.min_gap` | `{"point": 0, "hit": 120, "meteor_pass": 280}` | Jeda minimal (ms) antar pemutaran agar suara tidak menumpuk. |
| `PHOTOS` | `Dictionary` | Konfigurasi foto: `enabled` (true), `base_path` (`res://assets/photos/`), `vignette` (true, bayangan tepi di atas foto peta). |
| `PHOTOS.files` | `Dictionary` kunci foto ke nama file (atau `null`) | 18 foto: `map`, `map_hard_intro`, `map_ending`, `player`, `target`, `health`, `power`, `timestop`, `gadfly`, `gadfly_frozen`, `killer`, `archer`, `arrow`, `arrow_lord`, `vindex`, `meteor`, `meteor_hard`, `meteor_big`. |


#### `scripts/core/state.gd`

**Peran:** autoload `State` (extends Node) — menyimpan seluruh variabel global permainan (port dari `let` di JS), snake_case. Set JS menjadi Dictionary, array JS menjadi Array.
**Port dari:** `core/state.js`
**Jumlah fungsi:** 0

##### Konstanta & variabel

**Alur permainan**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `game_state` | `"menu"` | Status alur (menu, ready, playing, hardIntro, ending, end, hardDeath). |
| `level` | `"easy"` | Level aktif. |
| `score`, `lives` | `0`, `3` | Poin dan nyawa. |
| `paused` | `false` | Status jeda. |
| `pressed_keys` | `{}` | Set tombol yang sedang ditekan. |
| `global_freeze` | `0` | Penghitung pembekuan global killer. |
| `enemies_awake` | `true` | Penanda musuh aktif. |

**Objek utama**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `player`, `target`, `health` | `null` (Dictionary) | Objek pemain, target poin, dan item nyawa. |
| `killers`, `gadflies` | `[]` | Daftar killer dan Gadfly. |
| `hit_cooldown` | `0` | Jeda setelah pemain terkena. |
| `target_spawn_time`, `health_spawn_time` | `0` | Waktu spawn target/item nyawa. |
| `player_shock_timer`, `player_shock_x`, `player_shock_y` | `0` | Efek kejut/dorongan pemain. |
| `player_death_timer`, `player_death_max` | `0` | Animasi kematian pemain. |

**Penghitung spawn**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `powerup`, `powerup_spawn_time`, `power_active` | `null`, `0`, `0` | Item Power Kill, waktu spawn, dan sisa durasi aktif. |
| `killer_spawn_time`, `next_killer_spawn_delay` | `0`, `10000` | Waktu spawn killer berikutnya dan jedanya. |
| `ending_index` | `0` | Indeks ending. |
| `collectible_relocate_cooldown` | `0` | Jeda relokasi item koleksi. |

**Archer**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `archers`, `archer_arrows` | `[]` | Daftar archer dan anak panah. |
| `archer_next_spawn_time` | `0` | Waktu spawn archer berikutnya. |
| `archer_warning_timer`, `archer_warning_text` | `0`, `''` | Peringatan kemunculan archer. |

**Time Stop**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `time_stop`, `time_stop_wave`, `time_stop_wave_pulse` | `0` | Sisa durasi Time Stop dan efek gelombangnya. |
| `time_stop_origin_x`, `time_stop_origin_y` | `0` | Titik asal gelombang. |
| `time_stop_powerup`, `time_stop_spawn_time` | `null`, `0` | Item Time Stop dan waktu spawn. |

**Lord Vindex**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `lord_vindex` | `null` | Objek Lord Vindex. |
| `vindex_time_stop_move_x/y/timer`, `vindex_time_stop`, `vindex_time_stop_cooldown` | `0` | Time Stop milik Vindex (gerak, sisa durasi, jeda). |
| `vindex_laser_countdown`, `_active`, `_x`, `_y`, `_angle`, `_origin_x`, `_origin_y`, `_pulse`, `_fire_timer`, `_has_hit` | angka/bool | Status laser Vindex. |
| `vindex_barrage`, `vindex_barrage_cooldown` | `null`, `0` | Rentetan Laser: dict `{phase, t, round, beams, originX, originY}` dan jeda. |
| `vindex_vortex`, `vindex_vortex_cooldown` | `null`, `0` | Pusaran Ungu: dict `{x, y, age, exploded}` dan jeda. |
| `hard_death_cause` | `''` | Teks penyebab kematian mode SULIT. |
| `vindex_move_delay` | `0` | Jeda gerak Vindex. |

**Mode SULIT: intro & urutan poin 25**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `hard_revival_timer` | `null` | Timer kebangkitan (Node atau null). |
| `hard_meteor_permanent`, `hard_finale_triggered`, `hard25_triggered`, `hard25_completed` | `false` | Penanda tahapan mode SULIT. |
| `hard_intro_timer`, `hard_intro_last_time`, `hard_intro_ready`, `hard_intro_meteor_list` | `0`, `0`, `false`, `[]` | Status adegan pembuka. |
| `hard25_sequence_active`, `hard25_sequence_timer`, `hard25_sequence_phase`, `hard25_ready_for_input`, `hard25_arena_resume_requested`, `hard25_dialogue_timer` | bool/angka | Status urutan poin 25. |

**Cerita, partikel, getaran**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `story_message_timer`, `story_message` | `0`, `''` | Pesan cerita dan durasinya. |
| `particle_list` | `[]` | Daftar partikel. |
| `screen_shake` | `0` | Kekuatan getaran layar. |

**Meteor**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `meteor_shockwave`, `large_meteor_impact_state`, `large_meteor`, `large_meteor_warning` | `null` | Objek/efek meteor besar dan gelombang kejut. |
| `meteors` | `[]` | Daftar meteor kecil. |
| `meteor_session_active/timer/used`, `meteor_next_spawn`, `meteor_next_session_timer` | bool/angka | Status sesi hujan meteor. |
| `meteor_pre_shower_active/timer/next_spawn/spawned` | bool/angka | Status fase pra-hujan. |
| `meteor_shower_unlocked`, `meteor_warning_timer`, `meteor_phase` (`'idle'`), `meteor_phase_timer`, `meteor_burst_cooldown` | campuran | Status fase dan peringatan hujan meteor. |
| `large_meteor_pending`, `large_meteor_spawn_timer`, `large_meteor_milestones` | `false`, `0`, `{}` | Antrean, penghitung spawn, dan set tonggak meteor besar. |

**Lainnya (ending)**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `ending_destroy_index`, `ending_destroyed_count`, `ending_destroy_timer`, `ending_wait_timer` | `0` | Penghitung animasi ending. |
| `ending_raf` | `0` | Sisa dari versi web (id requestAnimationFrame). Tidak dipakai di kode; aman dihapus. |

**Tambahan khusus Godot**

| Nama | Nilai/tipe | Kegunaan |
|---|---|---|
| `page_level` | `null` | Level pilihan menu: easy, normal, hard, dalang. |
| `spectator_mode` | `false` | `true` = SANTAI (mode penonton). |
| `in_game` | `false` | `true` selama scene game aktif; input dan loop hanya jalan saat true. |


#### `scripts/core/util.gd`

**Peran:** autoload `Util` (extends Node) — utilitas umum: waktu, timer, pindah scene, angka acak, tabrakan AABB, wrap, dan gerak dasar. Entitas berupa Dictionary berkunci x, y, w, h.
**Port dari:** `core/utils.js`
**Jumlah fungsi:** 11

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `now()` | - | `float` | Pengganti `performance.now()`: waktu dalam milidetik dari `Time.get_ticks_msec()`. | `Effects.draw_archer_warning`, `GameAudio.play`, `GameLoop.update_game`, `GameSetup.create_game_objects`, `HardIntro.run_hard_intro`, `Items.spawn_health`, `Items.spawn_powerup`, `Items.spawn_target`, `Player.check_player_health`, `Player.check_player_powerup`, `Sprites._tick`, `Story.update_story_triggers`, `TimeStop.check_time_stop_powerup` |
| `after_ms(ms: float, callback: Callable)` | `ms: float`, `callback: Callable` | `void` | Pengganti `setTimeout`: memanggil callback sekali setelah ms milidetik lewat timer scene tree. | `DalangFlow.dl_toast`, `GameFlow.run_ending_animation`, `Killers.show_spawn_warning`, `TestBot._advance_start`, `TestBot.start_spectator` |
| `goto_page(key: String)` | `key: String` | `void` | Pindah scene sesuai `Config.PAGES[key]`. | `GameFlow.show_menu`, `MenuScreen._ready`, `MenuScreen._start_mode`, `RulesScreen._ready` |
| `random_int(min_v: int, max_v: int)` | `min_v: int`, `max_v: int` | `int` | Angka bulat acak inklusif lewat `randi_range`. | internal (`random_pos_away_from_player`); `Archers.create_teleport_particles`, `Archers.update_archers`, `DalangBot.bot_choose_goal`, `DalangFlow._rand_range_frames`, `DalangSkills.dl_spawn_rain_meteor`, `DalangSkills.dl_update_rain`, `GameSetup.create_game_objects`, `HardIntro.init_hard_intro`, `HardSequence.finish_hard25_sequence`, `Killers.create_disintegration_particles`, `Meteors.begin_meteor_preparation`, `Meteors.schedule_next_large_meteor`, `Meteors.spawn_large_meteor`, `Meteors.spawn_meteor`, `Meteors.start_meteor_session`, `Meteors.trigger_rare_large_meteor`, `Meteors.update_meteor_preparation`, `Meteors.update_meteors`, `Player.check_player_health`, `Player.check_player_powerup`, `Story.update_story_triggers`, `TestBot._base_goal`, `TimeStop.check_time_stop_powerup`, `VindexAttacks.start_vindex_barrage`, `VindexAttacks.start_vindex_vortex`, `VindexAttacks.trigger_vindex_time_stop` |
| `random_pos_away_from_player()` | - | `Dictionary` | Memilih posisi acak `{x, y}` (maks 100 percobaan) yang tidak dekat pemain (<120 px) dan, di level hard, di luar zona bahaya Vindex. | `Archers.spawn_archer`, `Archers.update_archers`, `Items.relocate_collectible_from_enemy`, `Items.spawn_health`, `Items.spawn_powerup`, `Items.spawn_target`, `Items.spawn_time_stop_powerup`, `Killers.add_killer`, `LordVindex.update_lord_vindex`, `VindexAttacks.move_collectibles_out_of_vindex_zones` |
| `collide(a: Dictionary, b: Dictionary)` | `a: Dictionary`, `b: Dictionary` | `bool` | Tes tabrakan dua kotak AABB. | `Archers.check_archer_collisions`, `DalangFlow.dl_check_pickups`, `Gadflies.check_player_gadflies`, `Gadflies.update_gadflies`, `Items.relocate_collectible_from_enemy`, `Killers.check_player_killers`, `Killers.update_killer_collisions`, `Killers.update_killers`, `LordVindex.check_lord_collision`, `LordVindex.check_vindex_enemy_collisions`, `Meteors.check_meteor_collisions`, `Meteors.process_large_meteor_impact`, `Player.check_player_health`, `Player.check_player_powerup`, `Player.check_player_target`, `TimeStop.check_time_stop_powerup` |
| `wrap_obj(obj: Dictionary)` | `obj: Dictionary` | `void` | Membungkus objek yang keluar arena ke sisi seberang (mengubah x/y). | `DalangBot.dl_move_bot`, `Killers.update_killers`, `Player.update_player`, `TestBot._move_bot` |
| `move_horizontal(obj: Dictionary, target_x: float, speed: float)` | `obj: Dictionary`, `target_x: float`, `speed: float` | `void` | Menggeser obj horizontal sebesar speed menuju target_x (berdasarkan pusat obj). | `Gadflies.update_gadflies` |
| `move_vertical(obj: Dictionary, target_y: float, speed: float)` | `obj: Dictionary`, `target_y: float`, `speed: float` | `void` | Menggeser obj vertikal sebesar speed menuju target_y (berdasarkan pusat obj). | `Gadflies.update_gadflies` |
| `move_towards(obj: Dictionary, target_obj: Dictionary, speed: float)` | `obj: Dictionary`, `target_obj: Dictionary`, `speed: float` | `void` | Menggeser obj pada tiap sumbu sebesar speed menuju pusat target_obj. | `Killers.update_killers` |
| `angle_to(a: Dictionary, b: Dictionary)` | `a: Dictionary`, `b: Dictionary` | `float` | Sudut (radian) dari pusat a ke pusat b. | `Archers.update_archers` |


### 9.2 `scripts/game`

#### `scripts/game/game_root.gd`

**Peran:** scene (script akar `scenes/game/game.tscn`, extends Control) — akar scene game; membangun UI di Board, lalu memulai mode sesuai `State.page_level`, dan memperbarui HUD tiap frame.
**Port dari:** `game/main.js` (komentar kepala: "pengganti game/main.js")
**Jumlah fungsi:** 3

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_ready()` | - | `void` | Set `State.in_game = true`, bangun UI (`GameUI.build`, `build_stage`), lalu mulai Dalang, `GameFlow.start_game(page_level)`, atau kembali ke menu bila level belum dipilih. | engine (Godot) |
| `_exit_tree()` | - | `void` | Set `State.in_game = false` saat scene dilepas. | engine (Godot) |
| `_process(_delta: float)` | `_delta: float` | `void` | Memanggil `Hud.update_hud()` tiap frame selama `State.in_game`. | engine (Godot) |


#### `scripts/game/setup.gd`

**Peran:** autoload `GameSetup` — membuat/mengatur ulang semua objek awal permainan (pemain, target, item, Gadfly, killer pertama, timer meteor/Time Stop/Vindex) menurut level.
**Port dari:** `game/setup.js`
**Jumlah fungsi:** 1

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `create_game_objects()` | - | `void` | Menginisialisasi seluruh `State` objek dan timer permainan, menambah killer pertama, 4 Gadfly, archer (normal/hard), spawn Lord Vindex (hard), target, serta jadwal item nyawa dan Power Kill. | `GameFlow.start_game`, `HardSequence.finish_hard25_sequence` |


#### `scripts/game/loop.gd`

**Peran:** autoload `GameLoop` — dispatcher pusat loop 60 Hz (`_physics_process`) dan logika satu tick permainan.
**Port dari:** `game/loop.js`
**Jumlah fungsi:** 4

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_physics_process(_delta: float)` | `_delta: float` | `void` | Bila `State.in_game`, mengarahkan tick ke `DalangFlow.run_dalang`, atau menurut `game_state`: `run_game`, `HardIntro.run_hard_intro`, `GameFlow.run_ending_animation`. | engine (Godot) |
| `update_game()` | - | `void` | Satu tick logika: urutan sequence poin 25, timer kematian, spawn otomatis, update pemain/item/Time Stop/meteor/killer/archer/Vindex/Gadfly, cek tabrakan, timer power, freeze, partikel. | internal (`run_game`) |
| `run_game()` | - | `void` | Satu tick `playing`: menampilkan teks pause bila `State.paused`, menjalankan `TestBot.tick()` di mode penonton, lalu `update_game()`. | internal (`_physics_process`) |
| `_set_visible(id: String, on: bool)` | `id: String`, `on: bool` | `void` | Menampilkan/menyembunyikan node UI berdasarkan id lewat `GameUI.node` (aman bila null). | internal (`run_game`) |


#### `scripts/game/flow.gd`

**Peran:** autoload `GameFlow` — alur permainan: mulai, mulai bermain, jeda, ending, game over, ulang, pindah layar, dan animasi ending.
**Port dari:** `game/flow.js`
**Jumlah fungsi:** 14

Variabel/konstanta: `SCREEN_IDS` (id tiga layar), `ending_all_gone_text` (dibaca `DrawGame`), `_true_ending_scheduled` (penjaga timer ending).

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_set_visible(id: String, on: bool)` | `id: String`, `on: bool` | `void` | Mengatur visibilitas node UI berdasarkan id (aman bila null). | internal (`begin_play`, `show_end`, `show_only`, `start_game`) |
| `_set_text(id: String, t: String)` | `id: String`, `t: String` | `void` | Mengatur teks node UI berdasarkan id (aman bila null). | internal (`show_end`) |
| `reset_run_state()` | - | `void` | Mengembalikan nyawa, jeda, audio jeda, timer revival, freeze, power, meteor, partikel, dan tombol ke nilai awal. | internal (`start_game`); `HardSequence.finish_hard25_sequence` |
| `start_game(lv: String, initial_score = null)` | `lv: String`, `initial_score = null` (tanpa tipe) | `void` | Menyetel level dan skor, reset, membuat objek, menyiapkan intro hard, menampilkan `gameScreen`, HUD, dan bot penonton. | internal (`restart_game`); `GameRoot._ready` |
| `begin_play()` | - | `void` | Mengubah status ke `playing` (dari ready atau hardIntro yang siap) dan memulai musik; level dalang diteruskan ke `DalangFlow.dalang_begin`. | `GameInput._input`, `GameInput.control_down`, `GameInput.pointer_down`, `GameUI._build_dalang_brief`, `TestBot._advance_start` |
| `toggle_pause()` | - | `void` | Membalik `State.paused` hanya saat `playing`, memberi tahu audio, dan memperbarui HUD. | `GameInput._input`, `GameMenuButton._close`, `GameMenuButton._open`, `GameUI._build_top_buttons` |
| `start_ending()` | - | `void` | Memulai ending: hentikan musik, bersihkan efek serangan Vindex (hard), set status `ending`, dan reset penghitung ending. | `Player.check_player_target` |
| `show_true_ending()` | - | `void` | Set status `end` dan tampilkan `trueEndingScreen`. | internal (`_finish_true_ending`) |
| `show_end()` | - | `void` | Hentikan musik dan tampilkan layar akhir; pada hard dengan skor < 100 masuk `hardDeath` dengan pesan penyebab. | `GameLoop.update_game` |
| `restart_game()` | - | `void` | Mengulang: `DalangFlow.dalang_start()` untuk dalang, selain itu `start_game(State.level)`. | `GameUI._build_end_screen` |
| `show_only(id: String)` | `id: String` | `void` | Menyembunyikan semua layar di `SCREEN_IDS` lalu menampilkan layar `id`. | internal (`show_end`, `show_true_ending`, `start_game`); `DalangFlow.dalang_start`, `DalangFlow.dl_end`, `HardSequence.finish_hard25_sequence`, `HardSequence.update_hard25_sequence` |
| `show_menu()` | - | `void` | Kembali ke menu lewat `Util.goto_page("menu")`. | `GameMenuButton.build`, `GameRoot._ready`, `GameUI._build_end_screen`, `GameUI._build_true_ending` |
| `_finish_true_ending()` | - | `void` | Callback timer: memanggil `show_true_ending` bila masih in_game dan status `ending`. | Callable internal (`run_ending_animation`) |
| `run_ending_animation()` | - | `void` | Satu tick animasi ending: mematikan Lord Vindex/archer (hard), menghancurkan killer satu per satu, lalu menjadwalkan layar true ending. | `GameLoop._physics_process` |


#### `scripts/game/input.gd`

**Peran:** autoload `GameInput` — input keyboard (panah/WASD/P/M/F11), tombol layar sentuh, dan ketuk/klik layar.
**Port dari:** `game/input.js`
**Jumlah fungsi:** 7

Konstanta: `IGNORED_START_KEYS` (tombol pengubah yang tidak memulai permainan), `WASD_MAP` (w/a/s/d ke tombol panah).

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_raw_key(event: InputEventKey)` | `event: InputEventKey` | `String` | Menerjemahkan event tombol Godot ke nama gaya JS (`ArrowUp`, `" "`, `Enter`, karakter unicode, dst). | internal (`_input`) |
| `_map_key(raw_key: String)` | `raw_key: String` | `String` | Memetakan w/a/s/d ke tombol panah; lainnya tetap. | internal (`_input`) |
| `_input(event: InputEvent)` | `event: InputEvent` | `void` | Menangani keyup/keydown: F11 layar penuh, M mute, tombol mulai intro hard, lanjut setelah poin 25, P pause/mulai, mulai dari ready, dan mengisi `State.pressed_keys`. | engine (Godot) |
| `_unhandled_input(event: InputEvent)` | `event: InputEvent` | `void` | Klik mouse/sentuh yang tidak ditangani kontrol lain memanggil `pointer_down()` (kecuali spectator). | engine (Godot) |
| `control_down(key: String)` | `key: String` | `void` | Tombol layar ditekan: lanjut poin 25, mulai dari ready/hardIntro, atau menandai tombol pada `pressed_keys`. | `GameUI._build_mobile_controls` |
| `control_up(key: String)` | `key: String` | `void` | Menghapus tombol dari `State.pressed_keys`. | `GameUI._build_mobile_controls` |
| `pointer_down()` | - | `void` | Ketuk/klik sebagai "tekan tombol apa saja": mulai intro hard, lanjut poin 25, atau mulai dari ready (bukan dalang). | internal (`_unhandled_input`); `GameUI._build_mobile_controls` |


### 9.3 `scripts/systems`

#### `scripts/systems/audio.gd`

**Peran:** autoload `GameAudio` — mengelola lagu latar (loop, fade, efek terpendam low-pass saat Time Stop) dan efek suara dengan batas jeda per kunci. Suara yang file-nya tidak ada diabaikan tanpa error.
**Port dari:** `systems/audio.js`
**Jumlah fungsi:** 17

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_ready()` | - | `void` | Mengatur `process_mode` ke ALWAYS (tetap jalan saat tree dijeda) lalu menyiapkan bus musik. | engine (Godot) |
| `_setup_bus()` | - | `void` | Mencari/membuat bus "GameMusic" (dikirim ke Master) dengan `AudioEffectLowPassFilter` terbuka di 22000 Hz, lalu menerapkan status bisu/volume master. | internal (`_ready`) |
| `unlock()` | - | `void` | No-op aman (di Godot tidak perlu gestur pengguna untuk membuka audio). | tidak ada pemanggil ditemukan |
| `_get_stream(key: String)` | `key: String` | `AudioStream` | Memuat stream dari `Config.AUDIO.files[key]` (cache di `_streams`); file hilang/rusak menghasilkan `null`, mp3 non-import dimuat via `AudioStreamMP3.load_from_file`. | internal (`_pick_music`, `play`, `start_music`) |
| `play(key: String, volume: float = 1.0, rate: float = -1.0)` | `key: String`, `volume: float = 1.0`, `rate: float = -1.0` | `void` | Memutar efek suara lewat `AudioStreamPlayer` sekali pakai di bus Master; dilewati bila bisu/jeda/kunci tak ada atau belum melewati `min_gap`; pitch deterministik (variasi 5 langkah untuk `meteor_pass`) bila `rate` < 0. | internal (`tick`); `DalangFlow.dl_check_pickups`, `DalangSkills.dl_cast`, `DalangSkills.dl_spawn_rain_meteor`, `DalangSkills.dl_update_lasers`, `Killers.check_player_killers`, `Meteors.process_large_meteor_impact`, `Meteors.spawn_meteor`, `Player.check_player_health`, `Player.check_player_powerup`, `Player.check_player_target`, `TimeStop.check_time_stop_powerup`, `VindexAttacks.explode_vindex_vortex` |
| `_pick_music()` | - | `String` | Memilih kunci lagu: `music_hard` bila level "hard" dan stream-nya ada, selain itu `music`. | internal (`start_music`) |
| `start_music()` | - | `void` | Menandai `want_music`, lalu memulai lagu terpilih (loop, bus GameMusic) kecuali lagu yang sama sedang berjalan; mengganti lagu lama dan menerapkan muffle seketika. | `DalangFlow.dalang_begin`, `GameFlow.begin_play` |
| `_music_volume()` | - | `float` | Volume linear lagu: `muffled_music_volume` bila terpendam, selain itu `music_volume` (minimal 0.0001). | internal (`_apply_muffle`, `start_music`) |
| `_stop_node(fade: float)` | `fade: float` | `void` | Melepas pemutar lagu saat ini; dengan `fade` > 0 volume di-tween ke -80 dB lalu di-free, kalau tidak langsung stop dan free. | internal (`start_music`, `stop_music`) |
| `stop_music(fade: float = 0.6)` | `fade: float = 0.6` | `void` | Menandai `want_music = false` dan menghentikan lagu dengan fade out. | `DalangFlow.dl_end`, `GameFlow.show_end`, `GameFlow.start_ending`, `HardSequence.trigger_hard25_sequence` |
| `_apply_muffle(instant: bool)` | `instant: bool` | `void` | Tween paralel cutoff filter low-pass dan volume lagu ke nilai terpendam/terbuka (0.001 dtk bila instan, selain itu 0.12 dtk). | internal (`set_muffled`, `start_music`) |
| `set_muffled(on: bool)` | `on: bool` | `void` | Mengubah status terpendam lagu bila berubah, lalu menerapkan efeknya. | internal (`tick`) |
| `set_paused(on: bool)` | `on: bool` | `void` | Menjeda/melanjutkan lagu dan semua pemutar efek suara anak node. | `DalangFlow.dalang_start`, `GameFlow.reset_run_state`, `GameFlow.toggle_pause` |
| `_apply_mute()` | - | `void` | Menerapkan status bisu dan volume `master_volume` pada bus 0 (Master). | internal (`_setup_bus`, `set_muted`) |
| `set_muted(on: bool)` | `on: bool` | `void` | Menyetel status bisu, menerapkannya, dan memperbarui teks tombol "muteButton" di GameUI (🔇/🔊) bila ada. | internal (`toggle_mute`) |
| `toggle_mute()` | - | `void` | Membalik status bisu. | `GameInput._input`, `GameUI._build_top_buttons` |
| `tick()` | - | `void` | Dipanggil tiap frame: memutar "hit" bila nyawa berkurang saat "playing", dan menyalakan muffle selama `time_stop` atau `vindex_time_stop` > 0. | `DalangFlow.run_dalang`, `DrawGame.get_shake_offset` |


#### `scripts/systems/hud.gd`

**Peran:** autoload `Hud` — memperbarui HUD: skor, ikon nyawa, status power (KILL / TIME STOP), dan tombol pause.
**Port dari:** `systems/hud.js`
**Jumlah fungsi:** 1

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `update_hud()` | - | `void` | Mengisi teks skor (kecuali level dalang), menandai ikon nyawa mati/hidup dan menggambar ulang yang berubah, menampilkan hitung mundur "KILL"/"TIME STOP" dalam detik (frame/60), serta mengatur visibilitas dan teks tombol pause (⏸ PAUSE / ▶ LANJUT). | `DalangFlow.run_dalang`, `GameFlow.start_game`, `GameFlow.toggle_pause`, `GameRoot._process`, `HardSequence.finish_hard25_sequence` |


#### `scripts/systems/menu_button.gd`

**Peran:** autoload `GameMenuButton` — tombol "☰ MENU" saat bermain beserta kotak konfirmasi "Kembali ke menu?"; menjeda permainan dulu supaya progres tidak hilang karena salah tekan. Dibangun oleh `GameUI` lewat `build(layar_game)`.
**Port dari:** `systems/menu-button.js`
**Jumlah fungsi:** 6

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `build(screen: Control)` | `screen: Control` | `void` | Membuat tombol MENU (disembunyikan awal), overlay konfirmasi gelap dengan kartu berisi tombol "KE MENU" dan "LANJUT MAIN", node penyaring input keyboard (skrip dinamis memanggil `_gate_input`), serta Timer 0,12 dtk yang menyinkronkan visibilitas. | `GameUI._build_game_screen` |
| `_alive()` | - | `bool` | Memeriksa tombol dan overlay konfirmasi masih valid (belum di-free). | internal (`_close`, `_gate_input`, `_open`, `_sync_visibility`) |
| `_sync_visibility()` | - | `void` | Menampilkan tombol hanya saat `State.game_state` termasuk "ready", "hardIntro", atau "playing". | Callable internal (`build`) |
| `_open()` | - | `void` | Membuka konfirmasi; bila sedang "playing" dan belum pause, memanggil `GameFlow.toggle_pause()` dan mengingat bahwa dijeda oleh tombol ini; fokus ke "LANJUT MAIN". | Callable internal (`build`) |
| `_close()` | - | `void` | Menutup konfirmasi dan melanjutkan permainan bila sebelumnya dijeda oleh tombol ini. | internal (`_gate_input`); Callable internal (`build`) |
| `_gate_input(event: InputEvent)` | `event: InputEvent` | `void` | Saat konfirmasi terbuka, mencegat semua tombol keyboard (Esc = tutup, Enter/Spasi = tekan tombol fokus, Tab/panah = pindah fokus) dan menandai input sudah ditangani agar tak sampai ke game. | Callable internal (`build`) |


#### `scripts/systems/particles.gd`

**Peran:** autoload `Particles` — memperbarui daftar partikel `State.particle_list` tiap frame (gerak, redaman, gravitasi, umur).
**Port dari:** `systems/particles.js`
**Jumlah fungsi:** 1

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `update_particles()` | - | `void` | Menggerakkan partikel dengan faktor `TimeStop.enemy_slow_factor()`, meredam kecepatan (0,97), menambah gravitasi 0,08, mengurangi `life`, membuang yang habis, dan membatasi maksimum 300 partikel. | `DalangFlow.dalang_tick`, `GameFlow.run_ending_animation`, `GameLoop.update_game` |


#### `scripts/systems/story.gd`

**Peran:** autoload `Story` — pemicu cerita dan spawn Archer berdasarkan skor (peringatan Archer, dialog Lord Vindex di level hard, pemicu urutan hard 25).
**Port dari:** `systems/story.js`
**Jumlah fungsi:** 1

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `update_story_triggers()` | - | `void` | Memperbarui cooldown relokasi collectible; di level normal/hard memulai peringatan Archer 180 frame lalu memanggil `Archers.spawn_archer()` dan menjadwalkan spawn berikutnya; di hard menampilkan dialog Vindex pada skor 1 dan memicu `HardSequence.trigger_hard25_sequence()` pada skor >= 25. | `GameLoop.update_game` |


#### `scripts/systems/subtitle.gd`

**Peran:** autoload `HardSubtitle` — subtitle Lord Vindex mode SULIT, memakai Label "hardSubtitle" dari GameUI di bawah arena. Cache dibaca dari Label itu sendiri.
**Port dari:** `systems/subtitle.js`
**Jumlah fungsi:** 3

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_label()` | - | `void` | Mengambil Label "hardSubtitle" dari GameUI bila masih valid. | internal (`hide_subtitle`, `show_subtitle`) |
| `show_subtitle(text = "", alpha: float = 1.0)` | `text = ""` (tanpa tipe), `alpha: float = 1.0` | `void` | Hanya di level "hard": mengisi teks, menyetel alpha (dibulatkan kelipatan 0,05), dan menampilkan Label; teks kosong/null memanggil `hide_subtitle()`. | `Effects.draw_story_message` |
| `hide_subtitle()` | - | `void` | Membuat alpha Label 0 dan mengosongkan teksnya. | internal (`show_subtitle`); `Effects.draw_story_message` |


#### `scripts/systems/time_stop.gd`

**Peran:** autoload `TimeStop` — faktor perlambatan dunia/musuh, pengambilan item Time Stop, dan hitung mundur efeknya.
**Port dari:** `systems/time-stop.js`
**Jumlah fungsi:** 4

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `enemy_slow_factor()` | - | `float` | `Config.TIME_STOP_SLOW` bila `time_stop` atau `vindex_time_stop` > 0, selain itu 1.0 (faktor untuk musuh). | internal (`update_time_stop`); `Archers.update_archers`, `DalangSkills.dl_update_meteors`, `DalangSkills.dl_update_rain`, `Gadflies.update_gadflies`, `Killers.get_killer_speed`, `Meteors.update_meteors`, `Particles.update_particles` |
| `world_slow_factor()` | - | `float` | `Config.TIME_STOP_SLOW` hanya bila `vindex_time_stop` > 0, selain itu 1.0 (faktor untuk dunia, termasuk pemain). | `GameLoop.update_game`, `Killers.update_killers`, `Player.update_player`, `TestBot._control` |
| `check_time_stop_powerup()` | - | `void` | Level easy: mematikan Time Stop dan menyembunyikan item. Lainnya: bila pemain menyentuh item, mengaktifkan Time Stop (suara, durasi, asal gelombang, shake 7, pesan cerita, jadwal respawn); bila item tersembunyi dan waktunya tiba tanpa Time Stop aktif, memanggil `Items.spawn_time_stop_powerup()`. | `GameLoop.update_game` |
| `update_time_stop()` | - | `void` | Level easy: mereset semua status Time Stop. Lainnya: mengurangi `time_stop` per frame, memajukan `time_stop_wave` dan `time_stop_wave_pulse`, mereset keduanya saat selesai, serta menambah `pulse` item power-up yang terlihat. | `DalangFlow.dalang_tick`, `GameLoop.update_game` |


### 9.4 `scripts/render`

#### `scripts/render/arena.gd`

**Peran:** scene (skrip `Node2D` pada `scenes/game/game.tscn`) — kanvas arena 800x600 yang digambar ulang tiap frame dengan urutan latar, karakter, efek; posisinya digeser untuk screen shake.
**Port dari:** — (komentar menyebut 3 lapis canvas JS: gameCanvas, spriteLayer, fxCanvas)
**Jumlah fungsi:** 2

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_process(_delta: float)` | `_delta: float` | `void` | Menyetel `position` ke `DrawGame.get_shake_offset()` dan meminta gambar ulang. | engine (Godot) |
| `_draw()` | - | `void` | Bila `State.in_game`, menggambar `DrawGame.draw_bg`, `Sprites.draw_all`, lalu `DrawGame.draw_fx` secara berurutan. | engine (Godot) |


#### `scripts/render/background.gd`

**Peran:** autoload `Background` — menggambar latar arena: papan catur 40 px, garis tipis, dan vignette ringan (tekstur kecil dibuat sekali).
**Port dari:** `render/background.js`
**Jumlah fungsi:** 3

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_make_vignette()` | - | `void` | Membuat `ImageTexture` 200x150 berisi gradien radial hitam transparan (alpha 0 hingga 0,45 antara radius 150 dan 550 dari pusat arena). | internal (`draw_game_background`) |
| `_draw_vignette(canvas: CanvasItem, w: int, h: int)` | `canvas: CanvasItem`, `w: int`, `h: int` | `void` | Menggambar vignette (membuat teksturnya bila belum ada). | internal (`draw_game_background`) |
| `draw_game_background(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Bila foto `map` ada: menggambar foto (mode `cover`) lalu vignette bila `Config.PHOTOS.vignette`. Selain itu menggambar dasar #101010, sel ganjil #171717, garis grid #222222 (alpha 0,75, tebal 2), lalu vignette (dibuat bila belum ada). | `DrawGame.draw_bg` |


#### `scripts/render/draw_game.gd`

**Peran:** autoload `DrawGame` — menyusun satu frame permainan, dipanggil oleh Arena: latar (`draw_bg`), efek dan teks (`draw_fx`), serta offset getaran layar.
**Port dari:** `render/draw-game.js`
**Jumlah fungsi:** 4

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `draw_bg(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar latar sesuai `game_state`: adegan `HardIntro` saat "hardIntro", latar ending saat "ending", selain itu latar arena biasa. | `Arena._draw` |
| `_draw_ending_backdrop(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar latar gelap #030305 dengan judul "LEVEL N" dan "SEMUA KILLER DIHAPUS...". | internal (`draw_bg`) |
| `draw_fx(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar efek di atas karakter: kosong saat hardIntro; partikel plus teks "SEMUA KILLER HANCUR" saat ending; `DalangFlow.draw_dalang` untuk level dalang; selain itu rangkaian efek Effects (meteor, peringatan archer, gelombang/laser/barrage/vortex Vindex, overlay hard25, gelombang time stop, pesan cerita, partikel). | `Arena._draw` |
| `get_shake_offset()` | - | `Vector2` | Memanggil `GameAudio.tick()` saat in_game, bukan dalang, dan "playing"; mengembalikan offset acak bulat bila `screen_shake` > 0, selain itu `Vector2.ZERO`. | `Arena._process` |


#### `scripts/render/draw_kit.gd`

**Peran:** autoload `DrawKit` — pembantu gambar sebagai pengganti pemanggilan `ctx.*` canvas 2D JS; semua fungsi menerima `canvas` (CanvasItem yang sedang di dalam `_draw()`).
**Port dari:** — (pengganti API ctx canvas 2D JavaScript)
**Jumlah fungsi:** 13

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `rect(canvas: CanvasItem, x: float, y: float, w: float, h: float, color: Color)` | `canvas: CanvasItem`, `x: float`, `y: float`, `w: float`, `h: float`, `color: Color` | `void` | Menggambar persegi panjang terisi. | `Background.draw_game_background`, `DalangFlow.dl_draw_aim`, `DalangFlow.dl_draw_freeze`, `DalangFlow.dl_draw_lasers`, `DalangFlow.dl_draw_rain`, `DrawGame._draw_ending_backdrop`, `Effects.draw_hard25_sequence_overlay`, `Effects.draw_time_stop_wave`, `Effects.draw_vindex_barrage`, `Effects.draw_vindex_laser`, `Effects.draw_vindex_time_stop_wave`, `HardIntro.draw_hard_intro_bg`, `HardIntro.draw_hard_intro_fx` |
| `rect_outline(canvas: CanvasItem, x: float, y: float, w: float, h: float, color: Color, width: float = 2.0)` | `canvas: CanvasItem`, `x: float`, `y: float`, `w: float`, `h: float`, `color: Color`, `width: float = 2.0` | `void` | Menggambar garis tepi persegi panjang. | `DalangFlow.dl_decorate_bot`, `DalangFlow.dl_draw_aim` |
| `rounded_rect(canvas: CanvasItem, x: float, y: float, w: float, h: float, color: Color, radius: float)` | `canvas: CanvasItem`, `x: float`, `y: float`, `w: float`, `h: float`, `color: Color`, `radius: float` | `void` | Menggambar kotak membulat terisi memakai `StyleBoxFlat`. | `DalangFlow.dl_decorate_bot` |
| `circle(canvas: CanvasItem, cx: float, cy: float, r: float, color: Color)` | `canvas: CanvasItem`, `cx: float`, `cy: float`, `r: float`, `color: Color` | `void` | Menggambar lingkaran terisi. | `DalangFlow.dl_draw_aim` |
| `ring(canvas: CanvasItem, cx: float, cy: float, r: float, width: float, color: Color)` | `canvas: CanvasItem`, `cx: float`, `cy: float`, `r: float`, `width: float`, `color: Color` | `void` | Menggambar cincin (busur penuh 48 segmen, antialias). | `DalangFlow.dl_draw_aim`, `DalangFlow.dl_draw_freeze` |
| `line(canvas: CanvasItem, x1: float, y1: float, x2: float, y2: float, width: float, color: Color)` | `canvas: CanvasItem`, `x1: float`, `y1: float`, `x2: float`, `y2: float`, `width: float`, `color: Color` | `void` | Menggambar garis antialias. | tidak ada pemanggil ditemukan |
| `poly(canvas: CanvasItem, points: PackedVector2Array, color: Color)` | `canvas: CanvasItem`, `points: PackedVector2Array`, `color: Color` | `void` | Menggambar poligon berwarna terisi. | `HardIntro.draw_hard_intro_bg` |
| `glow(canvas: CanvasItem, cx: float, cy: float, r: float, color: Color, layers: int = 4)` | `canvas: CanvasItem`, `cx: float`, `cy: float`, `r: float`, `color: Color`, `layers: int = 4` | `void` | Membuat cahaya lembut dari lingkaran bertumpuk yang mengecil ke pusat. | `DalangFlow.dl_decorate_bot`, `HardIntro.draw_hard_intro_bg` |
| `text(canvas: CanvasItem, x: float, y: float, s: String, size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0)` | `canvas: CanvasItem`, `x: float`, `y: float`, `s: String`, `size: int`, `color: Color`, `align: int = HORIZONTAL_ALIGNMENT_LEFT`, `width: float = -1.0` | `void` | Menggambar teks dengan font fallback; y digeser 0,35 x ukuran agar mirip baseline 'middle'. | internal (`text_center`); `DalangFlow.dl_decorate_bot` |
| `text_center(canvas: CanvasItem, x: float, y: float, s: String, size: int, color: Color)` | `canvas: CanvasItem`, `x: float`, `y: float`, `s: String`, `size: int`, `color: Color` | `void` | Menggambar teks rata tengah di titik (x, y) memakai kotak selebar 800. | `DalangFlow.dl_draw_aim`, `DalangFlow.dl_draw_freeze`, `DalangFlow.dl_draw_lasers`, `DalangFlow.dl_draw_rain`, `DrawGame._draw_ending_backdrop`, `DrawGame.draw_fx`, `Effects._txt`, `Effects.draw_hard25_sequence_overlay`, `HardIntro.draw_hard_intro_fx` |
| `alpha(c: Color, a: float)` | `c: Color`, `a: float` | `Color` | Mengembalikan warna yang sama dengan alpha baru (dijepit 0 sampai 1). | tidak ada pemanggil ditemukan |
| `set_transform(canvas: CanvasItem, x: float, y: float, rot: float = 0.0, sx: float = 1.0, sy: float = 1.0)` | `canvas: CanvasItem`, `x: float`, `y: float`, `rot: float = 0.0`, `sx: float = 1.0`, `sy: float = 1.0` | `void` | Menyetel transformasi gambar lokal (translasi, rotasi, skala); harus diikuti `clear_transform`. | `DalangFlow.dl_draw_aim`, `DalangFlow.dl_draw_lasers`, `Effects.draw_vindex_barrage`, `Effects.draw_vindex_laser`, `HardIntro.draw_hard_intro_bg` |
| `clear_transform(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Mengembalikan transformasi gambar ke identitas. | `DalangFlow.dl_draw_aim`, `DalangFlow.dl_draw_lasers`, `Effects.draw_vindex_barrage`, `Effects.draw_vindex_laser`, `HardIntro.draw_hard_intro_bg` |


#### `scripts/render/effects.gd`

**Peran:** autoload `Effects` — efek kanvas yang digambar di atas karakter: partikel, gelombang Time Stop, peringatan archer, pesan cerita, overlay urutan poin 25 (SULIT), laser/rentetan/pusaran Lord Vindex, dan efek meteor. Semua fungsi publik menerima `canvas` (CanvasItem) sebagai parameter pertama dan menggambar langsung ke sana; ukuran arena tetap `W=800`, `H=600`.
**Port dari:** `render/effects.js`
**Jumlah fungsi:** 17

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_txt(canvas: CanvasItem, x: float, base_y: float, s: String, size: int, color: Color)` | `canvas: CanvasItem`, `x: float`, `base_y: float`, `s: String`, `size: int`, `color: Color` | `void` | Menggambar teks rata tengah dengan baseline alfabetis di `base_y` (meniru `ctx.fillText`) lewat `DrawKit.text_center`. | internal (`draw_archer_warning`, `draw_meteor_effects`, `draw_story_message`, `draw_vindex_barrage`, `draw_vindex_laser`, `draw_vindex_vortex`) |
| `_rrect(canvas: CanvasItem, x: float, y: float, w: float, h: float, r: int, fill: Color, border: Color, bw: int)` | `canvas: CanvasItem`, `x: float`, `y: float`, `w: float`, `h: float`, `r: int`, `fill: Color`, `border: Color`, `bw: int` | `void` | Menggambar persegi membulat berisi warna dan border memakai `StyleBoxFlat` bersama (`_style`). | internal (`draw_archer_warning`, `draw_story_message`) |
| `_dash_line(canvas: CanvasItem, a: Vector2, b: Vector2, dash: float, gap: float, offset: float, color: Color, width: float)` | `canvas: CanvasItem`, `a: Vector2`, `b: Vector2`, `dash: float`, `gap: float`, `offset: float`, `color: Color`, `width: float` | `void` | Menggambar garis putus-putus dari `a` ke `b` (setara `setLineDash` + `lineDashOffset`); tidak menggambar jika panjang 0. | internal (`draw_vindex_barrage`, `draw_vindex_laser`) |
| `_dash_circle(canvas: CanvasItem, c: Vector2, r: float, dash: float, gap: float, offset: float, color: Color, width: float)` | `canvas: CanvasItem`, `c: Vector2`, `r: float`, `dash: float`, `gap: float`, `offset: float`, `color: Color`, `width: float` | `void` | Menggambar lingkaran putus-putus pusat `c`, jari-jari `r`, sebagai rangkaian busur; `offset` memutar pola; keluar bila `r <= 0`. | internal (`draw_meteor_effects`, `draw_vindex_barrage`, `draw_vindex_vortex`) |
| `_col(hex: String, a: float)` | `hex: String`, `a: float` | `Color` | Mengubah string hex menjadi `Color` dengan alpha dijepit ke 0..1. | internal (`_wave_rings`, `draw_archer_warning`, `draw_hard25_sequence_overlay`, `draw_meteor_effects`, `draw_story_message`, `draw_time_stop_wave`, `draw_vindex_barrage`, `draw_vindex_laser`, `draw_vindex_time_stop_wave`, `draw_vindex_vortex`) |
| `draw_particles(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar setiap partikel di `State.particle_list` sebagai kotak kecil; warna merah muda (death), oranye (meteor), atau merah bawaan, alpha = `life/max_life`. | `DalangFlow.draw_dalang`, `DrawGame.draw_fx` |
| `_wave_rings(canvas: CanvasItem, cx: float, cy: float, eased: float, color: String)` | `canvas: CanvasItem`, `cx: float`, `cy: float`, `eased: float`, `color: String` | `void` | Menggambar 3 cincin gelombang yang membesar dan memudar dari titik (cx, cy), dipakai oleh gelombang Time Stop pemain dan Vindex. | internal (`draw_time_stop_wave`, `draw_vindex_time_stop_wave`) |
| `draw_time_stop_wave(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar gelombang Time Stop pemain (cincin biru muda + lapisan biru berdenyut) dari posisi pemain atau titik asal Time Stop; keluar bila `time_stop` dan `time_stop_wave` sama-sama <= 0. | `DalangFlow.draw_dalang`, `DrawGame.draw_fx` |
| `draw_archer_warning(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar banner peringatan archer berdenyut di atas arena; hanya saat level "normal" dan `archer_warning_timer > 0`. | `DrawGame.draw_fx` |
| `draw_story_message(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar kotak pesan cerita di bawah (mode non-SULIT) atau meneruskannya ke `HardSubtitle` (mode SULIT); mengurangi `State.story_message_timer` sekali per tick fisika. | `DalangFlow.draw_dalang`, `DrawGame.draw_fx` |
| `draw_hard25_sequence_overlay(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar overlay urutan poin 25 mode SULIT bertahap menurut `hard25_sequence_timer` (ledakan ungu, GAME OVER, dialog Lord Vindex, kembali ke arena, fade). | `DrawGame.draw_fx` |
| `draw_vindex_time_stop_wave(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar gelombang Time Stop Lord Vindex (cincin ungu + lapisan ungu) di level SULIT selama `vindex_time_stop > 0`. | `DrawGame.draw_fx` |
| `draw_vindex_laser(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar laser Vindex: indikator target (garis putus + garis ke pemain) saat membidik/Time Stop, atau sinar penuh dengan origin beku saat menembak, plus teks status. | `DrawGame.draw_fx` |
| `draw_meteor_effects(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar gelombang kejut meteor, peringatan meteor besar (lingkaran + label), dan banner "METEOR AKAN DATANG"/"HUJAN METEOR". | `DalangFlow.draw_dalang`, `DrawGame.draw_fx` |
| `draw_vindex_barrage(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar Rentetan Laser Vindex: lingkaran area aman (fase gather), garis peringatan berkedip (warn), atau sinar menyala (fire), plus pusat energi dan teks hitung mundur. | `DrawGame.draw_fx` |
| `_core_color(r: float)` | `r: float` | `Color` | Menghitung warna inti pusaran pada jari-jari `r` (gradien hitam -> #2e1065 -> #7e22ce) berdasarkan `Config.VORTEX_KILL_RADIUS`. | internal (`draw_vindex_vortex`) |
| `draw_vindex_vortex(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar Pusaran Ungu: medan hisap bergradien, cincin putus-putus, 4 lengan spiral, inti + lingkaran maut, dan teks peringatan ledakan; hanya di level SULIT bila `State.vindex_vortex` ada. | `DrawGame.draw_fx` |


#### `scripts/render/photo_kit.gd`

**Peran:** autoload `PhotoKit` — pemuat dan penggambar foto peta dan entitas (versi foto). Nama berkas dari `Config.PHOTOS.files`; berkas hilang atau rusak menghasilkan `null` sehingga pemanggil jatuh kembali ke gambar vektor bawaan. Semua foto dimuat sekali di `_ready()` dan diberi mipmap.
**Port dari:** — (fitur baru, polanya mengikuti `GameAudio._get_stream`)
**Jumlah fungsi:** 6

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_ready()` | - | `void` | Memanggil `reload()`. | engine (Godot) |
| `reload()` | - | `void` | Mengosongkan cache lalu memuat semua foto di `Config.PHOTOS.files`; di build debug mencetak jumlah yang dimuat dan daftar yang belum ada. | internal (`_ready`) |
| `_load(key: String)` | `key: String` | `Texture2D` | Memuat satu foto: lewat `ResourceLoader` bila sudah diimpor, atau `Image.load_from_file` bila baru ditaruh. Memperkecil sisi terpanjang di atas 2048, membuat mipmap, lalu mengembalikan `ImageTexture`; gagal menghasilkan `null`. | internal (`reload`) |
| `has(key: String)` | `key: String` | `bool` | True bila foto tersedia dan `Config.PHOTOS.enabled` aktif. | `HardIntro._draw_intro_meteors`, `Sprites._draw_archer`, `Sprites._draw_meteor`, `Sprites._draw_arrow`, `Sprites._draw_gadfly`, `Sprites._draw_player`, `Sprites._killer_art`, `Sprites._photo_item` |
| `get_tex(key: String)` | `key: String` | `Texture2D` | Mengembalikan tekstur foto, atau `null` bila tidak ada atau foto dimatikan. | internal (`has`, `draw_fit`) |
| `draw_fit(canvas: CanvasItem, key: String, box: Rect2, mode: String = "contain", modulate: Color = Color.WHITE)` | `canvas: CanvasItem`, `key: String`, `box: Rect2`, `mode: String = "contain"`, `modulate: Color = Color.WHITE` | `bool` | Menggambar foto di dalam `box`: `contain` utuh di tengah (entitas), `cover` memenuhi kotak dengan pemotongan dari tengah (peta). Menyetel filter canvas ke linear + mipmap. False bila foto tidak ada. | `Background.draw_game_background`, `DrawGame._draw_ending_backdrop`, `HardIntro.draw_hard_intro_bg`, `HardIntro._draw_intro_meteors`, `Sprites._photo` |


#### `scripts/render/sprites.gd`

**Peran:** autoload `Sprites` — renderer semua karakter dan item (target, health, power, time stop, meteor, gadfly, killer, archer, panah, Lord Vindex, pemain), digambar langsung dari `State` lewat `draw_all(canvas)` tiap frame. Desain memakai skala 4x (`KS = 0.25`), animasi CSS diganti rumus waktu dari `_clock` (melambat saat Time Stop, berhenti saat jeda), dan bentuk rumit di-cache sekali di `_build()` memakai `shapes.gd` (di-`preload` sebagai konstanta `Shapes`). Versi foto: tiap karakter memakai foto dari `PhotoKit` bila ada (digambar pada kotak desain yang sama), kalau tidak memakai gambar vektor.
**Port dari:** `render/sprites.js` + `sprite-templates.js` + `assets/css/characters/*.css`
**Jumlah fungsi:** 37

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `show_cinematic_vindex(x: float, y: float, scale_mul: float)` | `x: float`, `y: float`, `scale_mul: float` | `void` | Menyalakan Lord Vindex besar untuk adegan pembuka SULIT di pusat (x, y) dengan pengali ukuran `scale_mul`. | `HardIntro.run_hard_intro` |
| `hide_cinematic_vindex()` | - | `void` | Mematikan flag Vindex sinematik (`_cine_on = false`). Tidak ada pemanggil di kode; `draw_all` juga mereset flag ini. | tidak ada pemanggil ditemukan |
| `draw_all(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Titik masuk gambar: membangun cache sekali, memajukan jam animasi, lalu menggambar sesuai `State.game_state` (Vindex sinematik di hardIntro, hanya killer di ending, dunia penuh untuk lainnya, tidak ada di menu/end). | `Arena._draw` |
| `_tick()` | - | `void` | Menghitung delta waktu (maks 0,1 dtk), mengatur `_slow` (0,18 saat Time Stop/Vindex Time Stop), memajukan `_clock` bila tidak jeda, dan mengisi `_font`. | internal (`draw_all`) |
| `_wave(dur: float)` | `dur: float` | `float` | Gelombang segitiga halus 0 -> 1 -> 0 berperiode `dur` detik dari `_clock` (pengganti keyframe CSS). | internal (`_draw_archer`, `_draw_gadfly`, `_draw_health`, `_draw_meteor`, `_draw_player`, `_draw_power`, `_draw_target`, `_draw_timestop`, `_killer_art`) |
| `_ca(c: Color)` | `c: Color` | `Color` | Mengalikan alpha warna dengan `_alpha` global. | internal (`_box`, `_circle`, `_draw_archer`, `_draw_player`, `_draw_target`, `_draw_vindex_art`, `_killer_art`, `_poly`, `_rect`, `_ring`, `_sphere`, `_text`) |
| `_begin_art(cx: float, cy: float, rot: float, psx: float, psy: float, s: float, aw: float, ah: float)` | `cx: float`, `cy: float`, `rot: float`, `psx: float`, `psy: float`, `s: float`, `aw: float`, `ah: float` | `void` | Memulai kotak desain: pose (rotasi + skala) di pusat (cx, cy) lalu skala `s`, menyimpan matriks di `_base` dan menerapkannya ke canvas. | internal (`_draw_archer`, `_draw_arrow`, `_draw_gadfly`, `_draw_health`, `_draw_killer`, `_draw_meteor`, `_draw_player`, `_draw_power`, `_draw_target`, `_draw_timestop`, `_draw_vindex_art`) |
| `_about(ox: float, oy: float, rot: float, sx: float, sy: float)` | `ox: float`, `oy: float`, `rot: float`, `sx: float`, `sy: float` | `void` | Menerapkan transformasi tambahan (rotasi lalu skala) terhadap titik (ox, oy) pada koordinat desain di atas `_base`. | internal (`_draw_archer`, `_draw_gadfly`, `_draw_health`, `_draw_player`, `_draw_power`, `_draw_timestop`, `_draw_vindex_art`) |
| `_reset_art()` | - | `void` | Mengembalikan transformasi canvas ke `_base`. | internal (`_draw_archer`, `_draw_gadfly`, `_draw_health`, `_draw_player`, `_draw_power`, `_draw_timestop`, `_draw_vindex_art`, `_killer_art`) |
| `_root_at(cx: float, cy: float, rot: float = 0.0)` | `cx: float`, `cy: float`, `rot: float = 0.0` | `void` | Mengatur transformasi ke koordinat dunia (piksel game) berpusat di (cx, cy) dengan rotasi opsional. | internal (`_draw_archer`, `_draw_killer`, `_draw_meteor`, `_draw_player`, `_draw_vindex`) |
| `_box(x: float, y: float, w: float, h: float, r: float, fill: Color, bw: float = 0.0, bc: Color = C_CLEAR, sh: float = 0.0, shc: Color = C_CLEAR)` | `x: float`, `y: float`, `w: float`, `h: float`, `r: float`, `fill: Color`, `bw: float = 0.0`, `bc: Color = C_CLEAR`, `sh: float = 0.0`, `shc: Color = C_CLEAR` | `void` | Menggambar kotak membulat dengan isi, border, dan cahaya (box-shadow) opsional lewat `StyleBoxFlat`. | internal (`_draw_archer`, `_draw_arrow`, `_draw_gadfly`, `_draw_health`, `_draw_player`, `_draw_power`, `_draw_target`, `_draw_timestop`, `_draw_vindex_art`, `_killer_art`) |
| `_rect(x: float, y: float, w: float, h: float, c: Color)` | `x: float`, `y: float`, `w: float`, `h: float`, `c: Color` | `void` | Menggambar persegi panjang berisi warna (alpha dikali `_alpha`). | internal (`_draw_gadfly`, `_draw_player`, `_draw_vindex_art`, `_killer_art`) |
| `_poly(pts: PackedVector2Array, c: Color)` | `pts: PackedVector2Array`, `c: Color` | `void` | Menggambar poligon berwarna tunggal. | internal (`_draw_arrow`, `_draw_gadfly`, `_draw_player`, `_draw_power`, `_draw_timestop`, `_draw_vindex_art`, `_killer_art`) |
| `_layers(layers: Array)` | `layers: Array` | `void` | Menggambar daftar lapisan poligon berwarna per-vertex hasil `Shapes.lin_layers`, menerapkan `_alpha` bila < 0,999. | internal (`_draw_gadfly`, `_draw_meteor`, `_draw_player`, `_draw_target`, `_draw_timestop`, `_killer_art`) |
| `_circle(cx: float, cy: float, r: float, c: Color)` | `cx: float`, `cy: float`, `r: float`, `c: Color` | `void` | Menggambar lingkaran berisi warna. Tidak dipakai di kode (tanpa pemanggil). | tidak ada pemanggil ditemukan |
| `_ring(r: float, bw: float, c: Color, dashed: bool = false)` | `r: float`, `bw: float`, `c: Color`, `dashed: bool = false` | `void` | Menggambar cincin tepi berjari-jari luar `r` dan tebal `bw` di titik asal transformasi; mode `dashed` memecahnya menjadi 18 busur. | internal (`_draw_archer`, `_draw_killer`, `_draw_player`, `_draw_vindex`) |
| `_sphere(cx: float, cy: float, rad: float, w: float, fxp: float, fyp: float, stops: Array)` | `cx: float`, `cy: float`, `rad: float`, `w: float`, `fxp: float`, `fyp: float`, `stops: Array` | `void` | Menggambar bola berbayang (pengganti radial-gradient) dari 9 lingkaran menyusut yang bergeser ke titik fokus, warna dari `Shapes.color_at`. | internal (`_draw_health`, `_draw_power`, `_draw_timestop`, `_draw_vindex_art`) |
| `_tail(tl: float, th: float, c: Color)` | `tl: float`, `th: float`, `c: Color` | `void` | Menggambar segitiga ekor meteor: ujung (-tl, 0) transparan, pangkal berwarna `c`. | internal (`_draw_meteor`) |
| `_text(x: float, y: float, s: String, size: int, c: Color, glow: Color)` | `x: float`, `y: float`, `s: String`, `size: int`, `c: Color`, `glow: Color` | `void` | Menggambar teks rata tengah di x (y = tengah garis) dengan outline cahaya opsional bila `glow.a > 0`. | internal (`_draw_power`, `_killer_art`) |
| `_photo(key: String, aw: float, ah: float, tint: Color = C_WHITE)` | `key: String`, `aw: float`, `ah: float`, `tint: Color = C_WHITE` | `bool` | Menggambar foto `key` pada kotak desain (0, 0, aw, ah) lewat `PhotoKit.draw_fit`; alpha global ikut berlaku. False bila foto tidak ada (pakai versi vektor). | internal (`_draw_archer`, `_draw_arrow`, `_draw_gadfly`, `_draw_meteor`, `_draw_player`, `_draw_vindex_art`, `_killer_art`, `_photo_item`) |
| `_photo_item(key: String, size: float, period: float, amp: float)` | `key: String`, `size: float`, `period: float`, `amp: float` | `bool` | Foto item (target, health, power, timestop) dengan denyut skala seperti bola vektornya. False bila foto tidak ada. | internal (`_draw_health`, `_draw_power`, `_draw_target`, `_draw_timestop`) |
| `_draw_world()` | - | `void` | Menggambar seluruh dunia dengan urutan z: target, item (health/power/timestop), meteor, gadfly, killer, archer, panah, Vindex, pemain (pemain disembunyikan pada jendela urutan poin 25). | internal (`draw_all`) |
| `_draw_target(t)` | `t` (tanpa tipe) | `void` | Menggambar item target (kotak putih dengan titik merah, cahaya berdenyut). | internal (`_draw_world`) |
| `_draw_health(h)` | `h` (tanpa tipe) | `void` | Menggambar item health (bola hijau dengan tanda plus, berdenyut). | internal (`_draw_world`) |
| `_draw_power(p)` | `p` (tanpa tipe) | `void` | Menggambar item power-up (bola kuning, petir, label "KILL"). | internal (`_draw_world`) |
| `_draw_timestop(p)` | `p` (tanpa tipe) | `void` | Menggambar item Time Stop (bola biru dengan jam pasir yang berbalik tiap 1,5 detik). | internal (`_draw_world`) |
| `_draw_meteor(m, big: bool, hard: bool)` | `m` (tanpa tipe), `big: bool`, `hard: bool` | `void` | Menggambar meteor kecil atau besar dengan ekor mengikuti arah gerak, rotasi, kawah dan retakan menyala (besar); tema ungu bila `hard`. | internal (`_draw_world`) |
| `_draw_gadfly(g)` | `g` (tanpa tipe) | `void` | Menggambar gadfly (badan, sayap mengepak, antena, mata, mulut bertaring); tampil abu-abu saat beku dan berkedip saat terkena. | internal (`_draw_world`) |
| `_draw_killer(k)` | `k` (tanpa tipe) | `void` | Menentukan pose killer (hancur, mengisi serangan dengan cincin berkedip, kecewa, atau normal) lalu memanggil `_killer_art`. | internal (`_draw_world`, `draw_all`) |
| `_killer_art(k, sad: bool)` | `k` (tanpa tipe), `sad: bool` | `void` | Menggambar badan killer: badan, kepala, goresan, mata merah berdenyut, mulut bergigi, darah, wajah kecewa, kilatan terkena, serta ikon panik "!" / tertawa "HA!". | internal (`_draw_killer`) |
| `_killer_mood(k)` | `k` (tanpa tipe) | `void` | Menggambar suasana Killer: ikon panik `!` atau tertawa `HA!` dengan empat sinar emas berputar. Dipakai versi vektor dan versi foto. | internal (`_killer_art`) |
| `_draw_archer(a)` | `a` (tanpa tipe) | `void` | Menggambar archer (cincin kemunculan/teleport, badan bulat, busur, label "AIM" saat mengisi) dengan skala dan arah bidik. | internal (`_draw_world`) |
| `_draw_arrow(q)` | `q` (tanpa tipe) | `void` | Menggambar panah archer searah kecepatan; panah milik "lord" bergaya ungu muda dengan cahaya. | internal (`_draw_world`) |
| `_draw_vindex(l)` | `l` (tanpa tipe) | `void` | Menggambar Lord Vindex di dunia: menghitung cahaya (berdenyut, bertambah saat bereaksi), cincin putus-putus saat `react`, lalu memanggil `_draw_vindex_art`. | internal (`_draw_world`) |
| `_draw_vindex_art(cx: float, cy: float, glow: float, s: float)` | `cx: float`, `cy: float`, `glow: float`, `s: float` | `void` | Menggambar seni Vindex (aura berdenyut, orb bergradien, mata marah, mulut bergigi) pada skala `s`; dipakai juga untuk adegan sinematik. | internal (`_draw_vindex`, `draw_all`) |
| `_draw_player(p)` | `p` (tanpa tipe) | `void` | Menggambar pemain (badan, aura Power Kill, kedip terluka, animasi mati, mata yang melirik arah gerak) dan mengingat posisi sebelumnya. | internal (`_draw_world`) |
| `_build()` | - | `void` | Membangun sekali semua cache bentuk dan gradien (`_st_*`, `_l_*`, `_p_*`, `_met_*`) memakai `Shapes`; dipanggil pada `draw_all` pertama. | internal (`draw_all`) |


#### `scripts/render/sprites/shapes.gd`

**Peran:** modul biasa (`extends RefCounted`, di-`preload` oleh `sprites.gd` sebagai `Shapes`) — pembantu bentuk: poligon persegi membulat dan ellipse, poligon dari persen, pemotongan poligon, dan gradien linear yang dipecah menjadi pita poligon berwarna per-vertex. Hanya dipakai saat membangun cache.
**Port dari:** — (komentar kepala tidak menyebut file JS; terkait gradien CSS dari `assets/css/characters/*.css`)
**Jumlah fungsi:** 7

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `rr_pts(x: float, y: float, w: float, h: float, r: float, seg: int = 6)` | `x: float`, `y: float`, `w: float`, `h: float`, `r: float`, `seg: int = 6` | `PackedVector2Array` | Membuat poligon persegi membulat (searah jarum jam); radius dijepit ke setengah sisi terkecil, bila ~0 menjadi persegi 4 titik. | `Sprites._build` |
| `ellipse_pts(cx: float, cy: float, rx: float, ry: float, n: int = 28)` | `cx: float`, `cy: float`, `rx: float`, `ry: float`, `n: int = 28` | `PackedVector2Array` | Membuat poligon ellipse dengan `n` titik. | `Sprites._build` |
| `pct_pts(x: float, y: float, w: float, h: float, pairs: Array)` | `x: float`, `y: float`, `w: float`, `h: float`, `pairs: Array` | `PackedVector2Array` | Mengubah daftar persen `[x1, y1, x2, y2, ...]` terhadap kotak (x, y, w, h) menjadi poligon. | `Sprites._build` |
| `clip(pts: PackedVector2Array, nx: float, ny: float, c: float)` | `pts: PackedVector2Array`, `nx: float`, `ny: float`, `c: float` | `PackedVector2Array` | Memotong poligon dengan algoritma Sutherland-Hodgman, mempertahankan titik dengan `nx*x + ny*y >= c`, dan membuang titik kembar berurutan. | internal (`lin_layers`); `Sprites._build` |
| `color_at(stops: Array, t: float)` | `stops: Array`, `t: float` | `Color` | Mengembalikan warna gradien pada posisi `t` dari `stops = [[t, Color], ...]` terurut dengan interpolasi linear. | internal (`_cols`); `Sprites._sphere` |
| `lin_layers(pts: PackedVector2Array, bx: float, by: float, bw: float, bh: float, angle_deg: float, stops: Array)` | `pts: PackedVector2Array`, `bx: float`, `by: float`, `bw: float`, `bh: float`, `angle_deg: float`, `stops: Array` | `Array` | Menerapkan gradien linear gaya CSS (sudut derajat, 180 = ke bawah) pada poligon `pts`, hasilnya daftar `[PackedVector2Array, PackedColorArray]` (satu pita per pasang stop). | `Sprites._build` |
| `_cols(pts: PackedVector2Array, stops: Array, s0: float, u: Vector2, ln: float)` | `pts: PackedVector2Array`, `stops: Array`, `s0: float`, `u: Vector2`, `ln: float` | `PackedColorArray` | Menghitung warna per-vertex untuk poligon dengan memproyeksikan tiap titik ke arah gradien lalu memanggil `color_at`. | internal (`lin_layers`) |


### 9.5 `scripts/entities`

#### `scripts/entities/player.gd`

**Peran:** autoload `Player` — logika pemain: gerak berdasar tombol dan dorongan kejut, pengambilan target/health/powerup, dan partikel kematian.
**Port dari:** `entities/player.js`
**Jumlah fungsi:** 5

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `update_player()` | - | `void` | Menerapkan dorongan kejut (`player_shock_*`) bila ada, menggerakkan pemain sesuai `State.pressed_keys` dengan `Config.PLAYER_SPEED` dan efek Time Stop, lalu wrap di tepi arena. | `GameLoop.update_game` |
| `check_player_target()` | - | `void` | Bila pemain menyentuh target: skor +1, suara "point", cek milestone/persiapan meteor di `Config.METEOR_TRIGGER_SCORE`, pindahkan target, dan mulai True Ending saat skor >= 100. | `GameLoop.update_game` |
| `check_player_health()` | - | `void` | Bila menyentuh health yang terlihat dan nyawa < 3: nyawa +1, suara "health", health disembunyikan dan jadwal respawn diset. | `GameLoop.update_game` |
| `check_player_powerup()` | - | `void` | Bila menyentuh powerup yang terlihat: powerup disembunyikan, suara "power_kill", `power_active` diset ke `Config.POWER_DURATION`, jadwal respawn diset. | `GameLoop.update_game` |
| `create_player_death_particles()` | - | `void` | Menambah 30 partikel kematian di pusat pemain ke `State.particle_list`. | `Archers.check_archer_collisions`, `DalangFlow.dl_check_death`, `DalangSkills.dl_damage_bot`, `HardSequence.update_hard25_sequence`, `Killers.check_player_killers`, `LordVindex.check_lord_collision`, `Meteors.check_meteor_collisions`, `VindexAttacks.update_vindex_time_stop`, `VindexAttacks.update_vindex_vortex`, `VindexAttacks.vindex_damage_player` |


#### `scripts/entities/items.gd`

**Peran:** autoload `Items` — mengatur kemunculan dan pemindahan item koleksi (target, health, powerup, Time Stop powerup), termasuk memindahkan item yang tertimpa musuh.
**Port dari:** `entities/items.js`
**Jumlah fungsi:** 6

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `spawn_target()` | - | `void` | Memindahkan `State.target` ke posisi acak jauh dari pemain dan mencatat `target_spawn_time`; dilewati selama urutan hard-25 aktif. | `Gadflies.update_gadflies`, `GameLoop.update_game`, `GameSetup.create_game_objects`, `Killers.update_killers`, `Player.check_player_target` |
| `spawn_health()` | - | `void` | Memindahkan `State.health` ke posisi acak, menampilkannya, mereset `pulse`, dan mencatat `health_spawn_time`; dilewati selama urutan hard-25 aktif. | `DalangFlow.dl_spawn_items`, `Gadflies.update_gadflies`, `GameLoop.update_game`, `Killers.update_killers` |
| `spawn_powerup()` | - | `void` | Memindahkan `State.powerup` (Power Kill) ke posisi acak, menampilkannya, mereset `pulse`, dan mencatat `powerup_spawn_time`; dilewati selama urutan hard-25 aktif. | `DalangFlow.dl_spawn_items`, `GameLoop.update_game` |
| `spawn_time_stop_powerup()` | - | `void` | Memindahkan dan menampilkan `State.time_stop_powerup` di posisi acak; dilewati di level "easy", bila item null, atau selama urutan hard-25 aktif. | `DalangFlow.dl_spawn_items`, `TimeStop.check_time_stop_powerup` |
| `relocate_collectible_from_enemy(enemy: Dictionary)` | `enemy: Dictionary` | `void` | Jika musuh bertabrakan dengan item yang terlihat, item dipindah ke posisi acak dan `collectible_relocate_cooldown` diset 18; tidak jalan bila pemain null atau cooldown aktif. | `Archers.update_archers`, `Killers.update_killers`, `LordVindex.update_lord_vindex` |
| `update_collectible_relocate_cooldown()` | - | `void` | Mengurangi `State.collectible_relocate_cooldown` sebesar 1 per tick bila > 0. | `DalangFlow.dalang_tick`, `Story.update_story_triggers` |


#### `scripts/entities/killers.gd`

**Peran:** autoload `Killers` — Killer, musuh utama: spawn, AI mengejar pemain (atau kabur saat Power Kill), tabrakan antar-Killer (sikutan), tabrakan dengan pemain, penguraian (disintegrasi), dan pengurangan efek global freeze/shake. Karakter digambar dari state oleh `Sprites`, tidak ada DOM.
**Port dari:** `entities/killers.js`
**Jumlah fungsi:** 9

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `get_killer_speed()` | - | `float` | Mengembalikan kecepatan dasar Killer (2 untuk "easy", 2.5 untuk lainnya) dikalikan `TimeStop.enemy_slow_factor()`. | internal (`update_killers`) |
| `add_killer(first: bool = false)` | `first: bool = false` | `void` | Menambah Killer baru (Dictionary dengan state animasi) di posisi acak jauh dari pemain ke `State.killers`, memuat 90 frame bila pertama atau `Config.KILLER_LOAD_TIME`, lalu menampilkan peringatan spawn. | `DalangSkills.dl_cast`, `GameLoop.update_game`, `GameSetup.create_game_objects` |
| `show_spawn_warning()` | - | `void` | Menampilkan node UI `spawnWarning` selama 900 ms dan menyembunyikannya lagi lewat token agar pemanggilan beruntun tidak saling menimpa. | internal (`add_killer`) |
| `update_killers()` | - | `void` | Per tick untuk tiap Killer: memindahkan item yang tertimpa, mengurus disintegrasi, cooldown, perayaan, kecewa, global freeze, mode kabur dengan steering dinding saat Power Kill, loading spawn, knockback, pengejaran pemain, animasi tilt/skala, wrap layar, dan pemindahan target/health yang disentuh. | `DalangFlow.dalang_tick`, `GameLoop.update_game` |
| `update_killer_collisions()` | - | `void` | Memeriksa semua pasangan Killer; yang bertabrakan saling menyikut: Killer kedua terkena knockback, tilt, squash, flash, kedua cooldown diset, dan keduanya didorong terpisah. | `DalangFlow.dalang_tick`, `GameLoop.update_game` |
| `check_player_killers()` | - | `void` | Saat Power Kill aktif, Killer yang disentuh pemain mulai terurai; selain itu, sentuhan mengurangi nyawa, memberi freeze global, membuat Killer perayaan dan lainnya kecewa, serta memicu kematian pemain bila nyawa 0. Juga mengurangi `hit_cooldown`. | `GameLoop.update_game` |
| `update_disintegrating_killer(k: Dictionary)` | `k: Dictionary` | `void` | Mengurangi `disintegrate_timer` Killer dan menghapusnya dari `State.killers` (berdasar identitas objek) saat timer mencapai 0. | internal (`update_killers`) |
| `create_disintegration_particles(k: Dictionary)` | `k: Dictionary` | `void` | Menambah 18 partikel radial di pusat Killer ke `State.particle_list`. | internal (`check_player_killers`); `Archers.check_archer_collisions`, `GameFlow.run_ending_animation`, `Meteors.check_meteor_collisions`, `Meteors.process_large_meteor_impact`, `VindexAttacks.destroy_enemy_by_vindex_laser`, `VindexAttacks.fire_barrage_round`, `VindexAttacks.kill_enemies_by_vindex_laser`, `VindexAttacks.update_vindex_vortex` |
| `update_global_freeze()` | - | `void` | Mengurangi satu per tick: umur `meteor_shockwave` (dihapus bila habis), `player_shock_timer` (dengan peredaman dorongan), `global_freeze`, dan `screen_shake`. | `DalangFlow.dalang_tick`, `GameLoop.update_game` |


#### `scripts/entities/gadflies.gd`

**Peran:** autoload `Gadflies` — Gadfly yang menempel di empat sisi arena: bergerak mengikuti pemain sepanjang sisinya, menggeser target/health yang disentuh, dan terpental saat disentuh pemain.
**Port dari:** `entities/gadflies.js`
**Jumlah fungsi:** 2

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `update_gadflies()` | - | `void` | Per tick: menjalankan animasi terpental (`hit_anim`) lalu mengembalikan Gadfly ke tepi, menghitung mundur `freeze`, menggerakkan Gadfly atas/bawah secara horizontal dan kiri/kanan secara vertikal mengikuti pemain (kecepatan 3), dan memindahkan target/health bila disentuh. | `GameLoop.update_game` |
| `check_player_gadflies()` | - | `void` | Jika pemain menyentuh Gadfly yang tidak sedang terpental: skor berkurang 1 (minimal 0), Gadfly terlempar menjauhi pemain dengan putaran, dan `hit_anim` diset ke `Config.GADFLY_HIT_TIME`. | `GameLoop.update_game` |


#### `scripts/entities/archers.gd`

**Peran:** autoload `Archers` — Archer (musuh penembak panah) yang menjaga jarak, membidik pemain, menembak, dan berteleportasi saat Power Kill aktif. Berisi juga tabrakan Archer/panah dengan pemain dan partikel teleportasi.
**Port dari:** `entities/archers.js`
**Jumlah fungsi:** 4

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `spawn_archer(x = null, y = null)` | `x = null` (tanpa tipe), `y = null` (tanpa tipe) | `void` | Menambah satu Archer ke `State.archers` (posisi acak jauh dari pemain bila x/y null); diabaikan di level "easy" dan bila jumlah sudah mencapai `Config.MAX_ARCHERS` (kecuali "dalang"). | `DalangSkills.dl_cast`, `Story.update_story_triggers` |
| `update_archers()` | - | `void` | Per tick: membuang Archer mati, menerapkan knockback, animasi, gerak menjaga jarak (250 px ideal, mundur bila < 170), teleport instan saat Power Kill dan pemain dekat, menembak panah, lalu menggerakkan/menghapus panah di `State.archer_arrows`. Terkena efek Time Stop. | `DalangFlow.dalang_tick`, `GameLoop.update_game` |
| `check_archer_collisions()` | - | `void` | Memeriksa tabrakan pemain dengan Archer (mati bila Power Kill/Time Stop aktif, kalau tidak kurangi nyawa) dan dengan panah (kurangi nyawa, hapus panah); memicu kematian pemain bila nyawa 0. | `GameLoop.update_game` |
| `create_teleport_particles(x: float, y: float, amount: int = 14)` | `x: float`, `y: float`, `amount: int = 14` | `void` | Menambah `amount` partikel radial ke `State.particle_list` di titik (x, y) sebagai efek teleportasi. | internal (`update_archers`); `DalangBot.dl_move_bot`, `DalangSkills.dl_cast`, `DalangSkills.dl_track`, `LordVindex.check_lord_collision`, `LordVindex.push_enemy_by_vindex`, `LordVindex.update_lord_vindex`, `TestBot._move_bot` |


#### `scripts/entities/meteors.gd`

**Peran:** autoload `Meteors` — hujan meteor (sesi, fase, burst), meteor besar dengan peringatan dan dampak berlapis (stage), serta tabrakan meteor dengan pemain/Killer dan partikelnya.
**Port dari:** `entities/meteors.js`
**Jumlah fungsi:** 17

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `start_meteor_session()` | - | `void` | Memulai sesi hujan meteor (timer, fase "firstBurst", cooldown burst, guncangan) dan memunculkan `Config.METEOR_FIRST_BURST` meteor diagonal; tidak jalan bila sesi aktif atau game_state bukan "playing". | internal (`update_meteor_preparation`, `update_meteors`) |
| `spawn_meteor(offset_y: float = 0, force_diagonal: bool = false)` | `offset_y: float = 0`, `force_diagonal: bool = false` | `void` | Menambah satu meteor kecil (ukuran 12-20, kecepatan acak, kemungkinan diagonal) di atas layar ke `State.meteors` dan memutar suara "meteor_pass". | internal (`start_meteor_session`, `update_meteor_preparation`, `update_meteors`) |
| `spawn_large_meteor()` | - | `void` | Membuat `State.large_meteor` dari atas layar yang meluncur ke titik peringatan (atau titik acak) lalu menghapus `large_meteor_warning`; tidak jalan bila sudah ada atau tidak "playing". | internal (`update_large_meteor_random_event`); `DalangSkills.dl_update_big_meteor` |
| `trigger_rare_large_meteor()` | - | `void` | Membuat `State.large_meteor_warning` (lingkaran peringatan) dan menandai `large_meteor_pending`; tidak jalan di level "hard". | internal (`update_large_meteor_random_event`) |
| `check_large_meteor_milestone()` | - | `void` | Bila skor >= `Config.METEOR_TRIGGER_SCORE`, mencatat skor itu di `State.large_meteor_milestones` (sebagai set). | `Player.check_player_target` |
| `schedule_next_large_meteor()` | - | `void` | Mengatur `large_meteor_spawn_timer` acak (antara `LARGE_METEOR_RANDOM_MIN` dan `MAX`), atau 999999 bila skor belum mencapai pemicu. | internal (`process_large_meteor_impact`); `Player.check_player_target` |
| `begin_meteor_preparation()` | - | `void` | Memulai fase pra-hujan (`meteor_pre_shower_*`) dan membuka `meteor_shower_unlocked`; syarat skor >= pemicu dan belum ada sesi/pra-hujan. | internal (`update_meteors`); `Player.check_player_target` |
| `update_meteor_preparation()` | - | `void` | Per tick selama pra-hujan: menjatuhkan beberapa meteor awal secara berkala, lalu saat timer habis menutup fase dan memulai sesi hujan. | internal (`update_meteors`) |
| `update_large_meteor_random_event()` | - | `void` | Mengelola peringatan meteor besar (gerak lingkaran, hitung mundur lalu `spawn_large_meteor`) dan timer kemunculan acak berikutnya; tidak berlaku di level "hard". | internal (`update_meteors`) |
| `update_large_meteor()` | - | `void` | Menggerakkan meteor besar (jejak, pantul dinding kiri/kanan); saat tiba di target atau lewat bawah, menonaktifkannya dan antre dampak. | internal (`update_meteors`); `DalangSkills.dl_update_big_meteor` |
| `update_meteors()` | - | `void` | Per tick: mengaktifkan hujan permanen di "hard" skor >= 25, memanggil event meteor besar, menjalankan fase sesi (burst pertama/kedua, acak, selesai), lalu menggerakkan meteor kecil (jejak, pantul, hapus bila keluar bawah). | `GameLoop.update_game` |
| `queue_large_meteor_impact(x: float, y: float)` | `x: float`, `y: float` | `void` | Mengantre dampak meteor besar di (x, y) ke `State.large_meteor_impact_state` (stage 0) bila belum ada dan "playing". | internal (`update_large_meteor`) |
| `process_large_meteor_impact()` | - | `void` | Memproses dampak per tahap: stage 0 (suara, kerusakan langsung ke pemain, Killer di kotak dampak terurai), stage 1 (partikel), stage 2 (dorongan gelombang kejut ke pemain/Killer, shockwave, jadwalkan meteor berikutnya). | internal (`update_meteors`) |
| `create_large_meteor_impact_particles(x: float, y: float)` | `x: float`, `y: float` | `void` | Menambah 8 partikel meteor (dengan sedikit gaya ke atas) di titik dampak. | internal (`process_large_meteor_impact`); `VindexAttacks.explode_vindex_vortex` |
| `large_meteor_shockwave(x: float, y: float)` | `x: float`, `y: float` | `void` | Membuat `State.meteor_shockwave` (radius awal 8, hidup 42 frame) di titik (x, y). | internal (`process_large_meteor_impact`); `VindexAttacks.explode_vindex_vortex` |
| `check_meteor_collisions()` | - | `void` | Meteor kecil yang menyentuh pemain dihapus, memberi partikel dan kurangi nyawa (dengan cooldown, memicu kematian bila 0); yang menyentuh Killer membuat Killer terurai dan meteor dihapus. Juga mengurangi `hit_cooldown`. | `GameLoop.update_game` |
| `create_meteor_impact_particles(x: float, y: float)` | `x: float`, `y: float` | `void` | Menambah 8 partikel meteor di titik tabrakan meteor kecil. | internal (`check_meteor_collisions`); `VindexAttacks.fire_barrage_round`, `VindexAttacks.update_vindex_time_stop` |


#### `scripts/entities/lord_vindex.gd`

**Peran:** autoload `LordVindex` — Lord Vindex, bos khusus mode SULIT: spawn, gerak (mengejar atau menghindar saat Power Kill, teleport), menembak panah, tabrakan dengan pemain, mendorong musuh lain, dan memisahkan pemain dari bos. Serangan khusus ada di `VindexAttacks`.
**Port dari:** `entities/lord-vindex.js`
**Jumlah fungsi:** 6

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `spawn_lord_vindex()` | - | `void` | Membuat `State.lord_vindex` (42x42 di 389,45) dan mengisi `State.vindex_move_delay` dengan `Config.VINDEX_MOVE_DELAY`. | `GameSetup.create_game_objects` |
| `update_lord_vindex()` | - | `void` | Per tick (hanya level "hard"): menahan gerak bila ada serangan khusus aktif atau delay awal; selain itu mengejar pemain, atau saat Power Kill menjauh/berteleportasi, lalu menembak panah "lord" tiap 145 frame. Memindahkan item yang tertimpa. | `GameLoop.update_game` |
| `check_lord_collision()` | - | `void` | Saat bersentuhan dengan pemain: keduanya dipisahkan; bila tidak ada Power Kill/Time Stop pemain kehilangan 1 nyawa (dengan cooldown, freeze, pesan cerita), dan memicu kematian pemain bila nyawa 0. | `GameLoop.update_game` |
| `push_enemy_by_vindex(enemy, force: float = 42)` | `enemy` (tanpa tipe), `force: float = 42` | `void` | Mendorong musuh (Killer/Archer) menjauhi Lord Vindex sejauh `force`, memberi flash, knockback, dan partikel teleportasi; dilewati bila mati/terurai atau `vindex_knockback_cooldown` > 0 (diset 14). | internal (`check_vindex_enemy_collisions`) |
| `check_vindex_enemy_collisions()` | - | `void` | Untuk tiap Killer (yang sudah aktif dan tidak terurai) dan Archer hidup yang bertabrakan dengan Lord Vindex, memanggil `push_enemy_by_vindex(..., 46)`. | `GameLoop.update_game` |
| `separate_player_and_vindex(push: float = 7)` | `push: float = 7` | `void` | Mendorong pemain (58%) dan Lord Vindex (42%) berlawanan arah sepanjang garis pusat keduanya, lalu membatasi posisi dalam arena. | internal (`check_lord_collision`) |


### 9.6 `scripts/modes/dalang`

#### `scripts/modes/dalang/config.gd`

**Peran:** autoload `DalangConfig` — pusat konstanta penyeimbang mode DALANG (energi, batas panggil, durasi bencana, Time Stop dalang, amuk, ritme item, kecerdasan BOT) dan daftar 6 skill dalang.
**Port dari:** modes/dalang/config.js
**Jumlah fungsi:** 1

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_build_skill_map()` | - | `Dictionary` | Membangun peta `id skill -> data skill` dari `DL_SKILLS`; hasilnya disimpan ke variabel `DL_SKILL` saat inisialisasi. | internal (`(inisialisasi)`) |

##### Konstanta & variabel
| Nama | Tipe | Kegunaan | Dipakai oleh |
|---|---|---|---|
| `DL` | `const Dictionary` | Semua angka penyeimbang (RECORD_KEY, ROAM_*, ENERGY_*, HIT_REWARD, *_MIN_DIST, RAIN_*, BIG_WARN, LASER_*, FREEZE*, RAGE_*, *_FIRST/*_RESPAWN item, LEARN_*). | `DL_SKILLS` | `const Array` | Daftar 6 skill (killer, archer, rain, big, laser, freeze) dengan id, tombol, label, ikon, biaya, cooldown, jenis bidikan, tip; urutan = tombol 1..6. | `GameUI` (`scripts/ui/game_ui.gd`), `DalangFlow._input` |
| `DL_SKILL` | `var Dictionary` | Peta id skill ke data skill, dibangun dari `DL_SKILLS`. 

#### `scripts/modes/dalang/bot.gd`

**Peran:** autoload `DalangBot` — AI pemain BOT-X untuk mode DALANG. Tiap 4 frame BOT memotret bahaya, memilih tujuan (item/buru musuh/berkeliling), mensimulasikan 81 rencana gerak (2 arah berurutan, 46 frame) dengan fisika engine, lalu memilih rencana berbiaya terkecil; juga menggerakkan BOT dan memberi label status.
**Port dari:** modes/dalang/bot.js
**Jumlah fungsi:** 11

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_init()` | - | `void` | Mengalokasikan sekali semua buffer PackedFloat64Array/PackedByteArray (Killer, panah, Archer, meteor, meteor besar, laser, hujan) sesuai batas BOT_MAX*. | engine (Godot) |
| `bot_reset()` | - | `void` | Mengembalikan `bot_mind` ke keadaan awal (arah 0, tanpa perintah tertunda, tujuan "roam" di tengah, alert 999). | `DalangFlow.dalang_start` |
| `bot_wrap_d(a: float, b: float, period: float)` | `a: float`, `b: float`, `period: float` | `float` | Selisih mutlak dua koordinat pada ruang melingkar berperiode `period` (jarak terpendek lewat dinding). | internal (`bot_dist`, `bot_eval`) |
| `bot_dist(x1: float, y1: float, x2: float, y2: float)` | `x1: float`, `y1: float`, `x2: float`, `y2: float` | `float` | Jarak terdekat dua titik dengan memperhitungkan tembus dinding (periode BOT_PX/BOT_PY). | internal (`bot_choose_goal`) |
| `bot_snapshot()` | - | `float` | Memotret dunia (Killer, panah, jadwal tembak Archer, meteor kecil, meteor besar, laser, jalur hujan, parameter belajar/amuk/beku) ke buffer dasar, menyimpan jarak bahaya terdekat di `bot_mind.alert`, dan mengembalikan skor ancaman (0 = aman). | internal (`dl_bot_think`) |
| `bot_spot_safety(x: float, y: float)` | `x: float`, `y: float` | `float` | Pengali 0..1 seberapa aman sebuah titik item dari laser, jalur hujan, meteor besar, dan Killer yang berjaga (1 = aman). | internal (`bot_choose_goal`) |
| `bot_choose_goal(threat: float)` | `threat: float` | `void` | Memilih tujuan BOT: buru Archer saat Time Stop BOT aktif, buru Killer saat Power Kill, atau item (nyawa/power/time stop) bernilai tertinggi dibagi jarak, jika tidak ada maka berkeliling ke titik acak; mengisi `bot_mind.goal_*` dan `label`. | internal (`dl_bot_think`) |
| `bot_eval(d1: int, d2: int)` | `d1: int`, `d2: int` | `float` | Mensimulasikan 46 frame rencana arah d1 lalu d2 terhadap semua bahaya (dengan lag reaksi, beku, amuk, Time Stop, Power Kill) dan mengembalikan total biaya (kena = penalti besar, dekat bahaya = penalti kecil, sampai tujuan = bonus, plus jarak ke tujuan); lebih kecil lebih baik. | internal (`dl_bot_think`) |
| `dl_bot_think()` | - | `void` | Satu langkah berpikir per tick: menghitung mundur `think`, sesekali "lengah", lalu snapshot, pilih tujuan, evaluasi 9x9 rencana, dan menjadwalkan arah terbaik sebagai `pending` yang berlaku setelah BOT_LAG frame. | `DalangFlow.dalang_tick` |
| `dl_move_bot()` | - | `void` | Menggerakkan `State.player`: menerapkan hentakan kejut, arah tertunda yang sudah jatuh tempo, kecepatan (beku/amuk/diagonal) dengan percepatan halus, lalu `Util.wrap_obj`; memicu partikel teleport dan `wrap_fx` bila menembus dinding. | `DalangFlow.dalang_tick` |
| `dl_bot_label()` | - | `String` | Mengembalikan teks status di atas kepala BOT sesuai prioritas: terkunci, tembus dinding, amuk, Power Kill, Time Stop, menghindar, atau label tujuan. | `DalangFlow.dl_decorate_bot` |


#### `scripts/modes/dalang/flow.gd`

**Peran:** autoload `DalangFlow` — alur mode DALANG: inisialisasi level dan status `dl`, loop per-tick, item untuk BOT, rekor waktu, layar akhir, gambar efek dalang, serta input mouse/keyboard untuk membidik dan memanggil skill. Memakai ulang entitas engine dengan `State.player` sebagai BOT.
**Port dari:** modes/dalang/flow.js
**Jumlah fungsi:** 33

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_frames(sec: float)` | `sec: float` | `int` | Mengubah detik menjadi frame (x60, dibulatkan). | internal (`_rand_range_frames`) |
| `_rand_range_frames(r: Array)` | `r: Array` | `int` | Mengambil angka acak (dalam frame) dari rentang detik `[min, max]`. | internal (`dalang_start`, `dl_check_pickups`) |
| `_ui(id: String)` | `id: String` | `void` | Mengambil node UI berdasarkan id lewat `GameUI.node`. | internal (`_set_visible`, `dl_end`, `dl_toast`, `dl_update_ui`) |
| `dalang_start()` | - | `void` | Mereset seluruh `State` untuk level dalang, membuat BOT di (390,300), membuat objek status `dl`, mereset BOT, menampilkan layar game dan briefing, dan memperbarui UI. | `GameFlow.restart_game`, `GameRoot._ready` |
| `_set_visible(id: String, v: bool)` | `id: String`, `v: bool` | `void` | Menampilkan/menyembunyikan node UI bila ada. | internal (`dalang_begin`, `dalang_start`, `dl_end`, `dl_hide_brief`, `dl_update_ui`, `run_dalang`) |
| `dl_hide_brief()` | - | `void` | Menyembunyikan overlay briefing `dlBrief`. | internal (`dalang_begin`, `run_dalang`) |
| `dalang_begin()` | - | `void` | Memulai permainan dari status "ready" menjadi "playing", menutup briefing, dan memulai musik; bila sudah berjalan hanya memastikan briefing tertutup. | `GameFlow.begin_play` |
| `run_dalang()` | - | `void` | Satu tick per frame fisika: bila jeda hanya memperbarui teks pause/audio/HUD/UI, bila tidak menjalankan `dalang_tick` lalu audio, HUD, dan UI. | `GameLoop._physics_process` |
| `dalang_tick()` | - | `void` | Satu tick logika: animasi tumbang BOT, regen energi, cooldown, hitung mundur beku/amuk, item, pikir dan gerak BOT, update bencana (hujan, laser, meteor besar, meteor), Killer, Archer, tabrakan terlacak lewat `dl_track`, cek kematian, dan partikel. | internal (`run_dalang`) |
| `dl_check_death()` | - | `void` | Memastikan animasi kematian BOT berjalan sekali bila nyawa habis lewat jalur apa pun (partikel, getar, pesan). | internal (`dalang_tick`) |
| `dl_spawn_items()` | - | `void` | Memunculkan item nyawa/power/time stop untuk BOT sesuai jadwal (`health_at`, `power_at`, `ts_at`) dan menambah denyut animasinya. | internal (`dalang_tick`) |
| `dl_check_pickups()` | - | `void` | Memproses BOT mengambil item (nyawa, Power Kill, Time Stop BOT), menjadwalkan kemunculan berikutnya, dan memberi efek serta pesan. | internal (`dalang_tick`) |
| `dl_best_time()` | - | `float` | Membaca rekor waktu tercepat dari `user://dalang_best.cfg`; mengembalikan 0.0 bila tidak ada. | internal (`dl_end`, `dl_update_ui`) |
| `_save_best_time(t: float)` | `t: float` | `void` | Menyimpan waktu rekor baru ke `user://dalang_best.cfg`. | internal (`dl_end`) |
| `dl_end()` | - | `void` | Mengakhiri level (sekali): menghentikan musik, menghitung waktu, mengisi judul/skor/ringkasan di layar akhir, memperbarui rekor bila lebih cepat, dan menampilkan `endScreen`. | internal (`dalang_tick`) |
| `draw_dalang(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar semua efek dalang di atas sprite (hiasan BOT, hujan, laser, efek meteor, gelombang Time Stop, beku, bidikan, pesan cerita, partikel). | `DrawGame.draw_fx` |
| `dl_decorate_bot(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar hiasan BOT: bingkai segel saat beku, cahaya saat amuk, dan label status dari `DalangBot.dl_bot_label`. | internal (`draw_dalang`) |
| `_dash_line(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float, dash: float, gap: float)` | `canvas: CanvasItem`, `a: Vector2`, `b: Vector2`, `color: Color`, `width: float`, `dash: float`, `gap: float` | `void` | Menggambar garis putus-putus dari a ke b. | internal (`dl_draw_aim`, `dl_draw_lasers`, `dl_draw_rain`) |
| `_dash_circle(canvas: CanvasItem, c: Vector2, r: float, color: Color, width: float, dash: float, gap: float)` | `canvas: CanvasItem`, `c: Vector2`, `r: float`, `color: Color`, `width: float`, `dash: float`, `gap: float` | `void` | Menggambar lingkaran putus-putus sebagai busur-busur pendek (panjang keliling `circ` dihitung dulu). | internal (`dl_draw_aim`, `dl_draw_freeze`) |
| `dl_draw_rain(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar jalur hujan meteor (area, garis tepi putus-putus, dan teks peringatan beserta hitung mundur saat masih warn). | internal (`draw_dalang`) |
| `dl_draw_lasers(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar tiap laser: pita peringatan merah saat warn, sinar menyala saat fire, dan teks hitung mundur. | internal (`draw_dalang`) |
| `dl_draw_freeze(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar gelombang cincin, tint ungu layar, cincin segel pada BOT, cincin perisai bila ada, dan label sisa beku saat Time Stop dalang. | internal (`draw_dalang`) |
| `dl_draw_aim(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar pratinjau bidikan skill terpilih (lingkaran jarak minimal Killer/Archer, jalur hujan, lingkaran meteor besar, pita laser) dengan warna cyan bila valid dan merah bila tidak. | internal (`draw_dalang`) |
| `dl_aim_point()` | - | `Dictionary` | Mengembalikan `{x, y, angle}` titik bidik saat ini; untuk laser memakai titik tekan + arah seret atau sudut `laser_step`. | internal (`dl_draw_aim`, `dl_fire_aim`) |
| `dl_toast(msg: String)` | `msg: String` | `void` | Menampilkan toast `dlToast` dengan pesan dan menyembunyikannya setelah 1500 ms (dijaga token agar toast lama tidak menimpa yang baru). | internal (`dl_fire_aim`, `dl_select`) |
| `dl_select(id: String)` | `id: String` | `void` | Memilih/membatalkan skill: skill instan langsung dipakai lewat `DalangSkills.dl_cast`, skill bidik di-toggle dan menampilkan tip. | internal (`_input`); `DalangSkills.on_skill_pressed` |
| `dl_fire_aim()` | - | `void` | Menembakkan skill terpilih di titik bidik via `DalangSkills.dl_cast` dan menampilkan toast bila gagal. | internal (`_input`) |
| `dl_update_ui()` | - | `void` | Memperbarui bar/teks energi, status tiap tombol dock (cooldown, terpilih, rendah, siap), tombol rotasi, chip beku, kilat terluka, jam waktu (`scoreNumber`), dan teks rekor. | internal (`_input`, `dalang_start`, `dl_select`, `run_dalang`) |
| `_active()` | - | `bool` | True bila level dalang sedang berjalan dan tidak dijeda. | internal (`_input`) |
| `_board_pos(p: Vector2)` | `p: Vector2` | `Vector2` | Mengubah koordinat viewport ke koordinat papan 800x600 lewat transform `GameUI.board`. | internal (`_input`) |
| `_in_arena(p: Vector2)` | `p: Vector2` | `bool` | Memeriksa titik berada di dalam arena (0..WIDTH, 0..HEIGHT). | internal (`_input`) |
| `_over_button()` | - | `bool` | True bila kursor sedang di atas kontrol `BaseButton`. | internal (`_input`) |
| `_input(event: InputEvent)` | `event: InputEvent` | `void` | Menangani gerak mouse (bidikan, arah laser), klik kiri (mulai seret lalu tembak saat lepas), klik kanan (batal), roda mouse (putar laser), tombol 1-6 (pilih skill), R (putar/pilih laser), dan Esc (batal). | engine (Godot) |


#### `scripts/modes/dalang/skills.gd`

**Peran:** autoload `DalangSkills` — logika skill dalang (Killer, Archer, Hujan Meteor, Meteor Besar, Laser, Time Stop), pembaruan efek bencana per tick, serta pelacakan kerusakan BOT (Perisai Waktu, hadiah energi, pembelajaran BOT).
**Port dari:** modes/dalang/skills.js
**Jumlah fungsi:** 13

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `on_skill_pressed(skill_id: String)` | `skill_id: String` | `void` | Meneruskan penekanan tombol skill di dock ke `DalangFlow.dl_select`. | `GameUI._skill_tile` |
| `dl_bot_center()` | - | `Dictionary` | Mengembalikan `{x, y}` titik tengah BOT (`State.player`). | internal (`dl_cast`, `dl_update_lasers`); `DalangFlow.dl_draw_aim`, `DalangFlow.dl_draw_freeze` |
| `dl_freeze_ready()` | - | `bool` | True bila Time Stop dalang tidak cooldown dan energi cukup. | `DalangBot.bot_choose_goal`, `DalangBot.bot_snapshot` |
| `dl_laser_dist(L: Dictionary, px: float, py: float)` | `L: Dictionary`, `px: float`, `py: float` | `float` | Jarak tegak lurus titik ke garis laser `L`. | internal (`dl_update_lasers`); `DalangBot.bot_snapshot`, `DalangBot.bot_spot_safety` |
| `dl_cast(id: String, x: float, y: float, angle: float)` | `id: String`, `x: float`, `y: float`, `angle: float` | `Dictionary` | Mencoba memakai skill (cek cooldown, energi, jarak minimal, batas meteor besar/laser), memunculkan efeknya, dan memotong energi/cooldown hanya bila berhasil; mengembalikan `{ok, msg}`. | `DalangFlow.dl_fire_aim`, `DalangFlow.dl_select` |
| `dl_spawn_rain_meteor(r: Dictionary)` | `r: Dictionary` | `void` | Memunculkan satu meteor kecil acak di dalam jalur hujan `r` ke `State.meteors` dan memutar suara. | internal (`dl_update_rain`) |
| `dl_update_rain()` | - | `void` | Memperbarui tiap hujan: hitung mundur peringatan, lalu memunculkan meteor berkala (kadang dua) sampai durasi habis, dipengaruhi perlambatan Time Stop BOT. | `DalangFlow.dalang_tick` |
| `dl_update_meteors()` | - | `void` | Menggerakkan meteor kecil (jejak, rotasi, pantul di dinding samping, hapus bila lewat bawah) dengan faktor perlambatan musuh. | `DalangFlow.dalang_tick` |
| `dl_update_big_meteor()` | - | `void` | Menghitung mundur peringatan meteor besar lalu memanggil `Meteors.spawn_large_meteor`, memperbarui meteor besar, dan melacak dampaknya lewat `dl_track("big", ...)`. | `DalangFlow.dalang_tick` |
| `dl_update_lasers()` | - | `void` | Memperbarui laser: hitung mundur peringatan, suara saat menyala, cek kena BOT (sekali per laser) yang memicu `dl_damage_bot` via `dl_track`, dan hapus saat selesai. | `DalangFlow.dalang_tick` |
| `dl_damage_bot(n: int)` | `n: int` | `void` | Mengurangi nyawa BOT sebanyak n (bila tidak kebal), mengatur cooldown/getar, dan memicu animasi tumbang bila nyawa habis. | internal (`dl_update_lasers`) |
| `dl_track(source: String, fn: Callable)` | `source: String`, `fn: Callable` | `void` | Menjalankan fungsi engine lalu mendeteksi nyawa BOT berkurang; menerapkan Perisai Waktu (poin maya), iframe saat beku, dan memanggil `dl_on_bot_hit`. | internal (`dl_update_big_meteor`, `dl_update_lasers`); `DalangFlow.dalang_tick` |
| `dl_on_bot_hit(n: int, source: String)` | `n: int`, `source: String` | `void` | Mencatat serangan yang mengenai BOT: tambah `hits`, energi hadiah, naikkan kewaspadaan BOT terhadap jenis serangan, kilat, amuk, dan pesan cerita. | internal (`dl_track`) |


### 9.7 `scripts/modes/hard`

#### `scripts/modes/hard/hard_intro.gd`

**Peran:** autoload `HardIntro` — adegan pembuka mode SULIT: latar gradien ungu, hujan meteor yang "ditiup" Lord Vindex, kilat/tint, dan teks dialog. Pewaktu adegan (`State.hard_intro_timer`) dimajukan per physics tick oleh `run_hard_intro`, sedangkan penggambaran dilakukan lewat `draw_hard_intro` yang dipanggil `DrawGame`.
**Port dari:** modes/hard/hard-intro.js
**Jumlah fungsi:** 8

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `init_hard_intro()` | - | `void` | Mereset pewaktu/penanda intro di `State` dan membuat 18 meteor acak (x, y di atas layar, speed, size, drift, rot) ke `State.hard_intro_meteor_list`. | `GameFlow.start_game` |
| `_grad_color(d: float)` | `d: float` | `Color` | Menghitung warna gradien radial (ungu transparan ke hampir hitam) untuk jarak `d` dari pusat, jari-jari 20..560. | internal (`draw_hard_intro_bg`) |
| `_draw_intro_meteors(canvas: CanvasItem, _W: float, H: float)` | `canvas: CanvasItem`, `_W: float`, `H: float` | `void` | Menggambar meteor jatuh adegan pembuka (foto `meteor_hard`, atau `meteor` berwarna ungu, atau berlian ungu bawaan). | internal (`draw_hard_intro_bg`) |
| `draw_hard_intro_bg(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar latar: kotak gelap, gradien radial via kipas segitiga berwarna per titik, lalu meteor jatuh (dengan efek "tertiup" setelah t > 150) selama t < 270. | internal (`draw_hard_intro`) |
| `_bezier(p0: Vector2, p1: Vector2, p2: Vector2, u: float)` | `p0: Vector2`, `p1: Vector2`, `p2: Vector2`, `u: float` | `Vector2` | Titik pada kurva Bezier kuadratik pada parameter `u`. | internal (`draw_hard_intro_fx`) |
| `draw_hard_intro_fx(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar efek di atas sprite: tujuh kurva kilat (t 80..255), tint ungu (t 150..360), serta teks "LORD VINDEX", dialog yang berganti per tahap, dan petunjuk "TEKAN TOMBOL APA SAJA" saat t >= 360. | internal (`draw_hard_intro`) |
| `draw_hard_intro(canvas: CanvasItem)` | `canvas: CanvasItem` | `void` | Menggambar seluruh adegan: memanggil latar lalu efek. | `DrawGame.draw_bg` |
| `run_hard_intro()` | - | `void` | Hanya saat `game_state == "hardIntro"`: memajukan `hard_intro_timer` (maks 420, berdasarkan waktu nyata dibagi 1/60 detik, selisih dibatasi 100 ms), menampilkan sprite sinematik Vindex lewat `Sprites.show_cinematic_vindex`, dan menandai `hard_intro_ready` saat timer >= 360. | `GameLoop._physics_process` |


#### `scripts/modes/hard/hard_sequence.gd`

**Peran:** autoload `HardSequence` — urutan poin 25 mode SULIT: kematian palsu pemain setelah meteor besar, layar "GAME OVER" palsu, dialog Vindex, lalu arena disiapkan ulang dan fase lanjutan dimulai (Vindex boleh memakai Time Stop). Seluruhnya dikendalikan oleh pewaktu frame `State.hard25_sequence_timer` (0 sampai 1080).
**Port dari:** modes/hard/hard-sequence.js
**Jumlah fungsi:** 7

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_hide_item(item)` | `item` (tanpa tipe) | `void` | Bila `item` tidak null: menyembunyikan (`visible = false`) dan memindahkannya ke (-100, -100). | internal (`hide_hard25_collectibles`) |
| `hide_hard25_collectibles()` | - | `void` | Menyembunyikan target, health, powerup, dan time_stop_powerup. | internal (`trigger_hard25_sequence`) |
| `trigger_hard25_sequence()` | - | `void` | Memulai urutan 25 sekali saja: menghentikan musik, mengaktifkan urutan, meteor permanen, membersihkan meteor, menyembunyikan item, getar layar, dan pesan cerita Vindex. | `Story.update_story_triggers` |
| `_set_end_buttons_visible(on: bool)` | `on: bool` | `void` | Menampilkan/menyembunyikan tombol layar akhir (kontainer `endButtons` dan tombol restart/menu) lewat `GameUI.node`. | internal (`finish_hard25_sequence`, `update_hard25_sequence`) |
| `update_hard25_sequence()` | - | `void` | Dipanggil tiap tick: menambah timer, menentukan fase (0 jeda, 1 dialog, 2 siap) dan menjalankan kejadian terjadwal (t=150 kematian palsu, t=205 layar GAME OVER, t=600 kembali ke gameScreen dengan nyawa 3 dan dialog, t=900 input siap), serta memanggil `finish_hard25_sequence` pada t >= 1080. | `GameLoop.update_game` |
| `finish_hard25_sequence()` | - | `void` | Mengakhiri urutan: reset run, buat ulang objek game, tandai `hard25_completed`, atur cooldown Time Stop Vindex acak 180-300, tampilkan overlay "ready", dan perbarui HUD. | internal (`continue_after_hard25`, `update_hard25_sequence`) |
| `continue_after_hard25()` | - | `void` | Bila level "hard", urutan aktif, dan input sudah siap, memotong urutan dengan memanggil `finish_hard25_sequence` (dipicu input pemain). | `GameInput._input`, `GameInput.control_down`, `GameInput.pointer_down` |


#### `scripts/modes/hard/test_bot.gd`

**Peran:** autoload `TestBot` — bot penguji/penonton untuk mode SANTAI/uji (`?bot`, `State.spectator_mode`). Bot memainkan level SULIT 0-100 secara otomatis dan tidak bisa mati (nyawa dipulihkan tiap tick); pemain hanya menonton. Cara kerjanya sama dengan BOT-X (DALANG): memotret bahaya, mensimulasikan 81 rencana gerak (9 arah x 9 arah), memilih biaya terkecil, lalu menggerakkan `State.player` langsung (bukan lewat tombol); prioritas utama adalah kotak putih (target). Hanya mode PINTAR yang diport.
**Port dari:** modes/hard/test-bot.js
**Jumlah fungsi:** 21

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_init()` | - | `void` | Mengalokasikan ukuran semua buffer simulasi (killer, panah, archer, meteor, zona meteor besar, laser, gadfly) lalu memanggil `_reset_mind`. | engine (Godot) |
| `_reset_mind()` | - | `void` | Mereset "pikiran" bot (`_mind`: arah, tujuan, antrean, dst), pewaktu `_t`, dan daftar laser. | internal (`_init`, `start_spectator`) |
| `start_spectator()` | - | `void` | Dipanggil sekali di awal run penonton: mereset pikiran, menaikkan `_run_id`, dan menjadwalkan `_advance_start` tiap 250 ms. | `GameFlow.start_game` |
| `_advance_start(tok: int)` | `tok: int` | `void` | Bila token masih berlaku dan masih dalam game mode penonton: dari "hardIntro"/"ready" memanggil `GameFlow.begin_play`, lalu menjadwalkan dirinya lagi 250 ms kemudian. | internal (`_advance_start`, `start_spectator`) |
| `tick()` | - | `void` | Dipanggil tiap tick tepat sebelum `GameLoop.update_game()`: saat "playing" memulihkan nyawa ke 3 dan membatalkan kematian (mode dewa), lalu memanggil `_control`. | `GameLoop.run_game` |
| `_control()` | - | `void` | Mengosongkan `pressed_keys`, menaikkan `_t`, mengumpan laser, berpikir (maks tiap 3 frame), menggerakkan bot, dan memperlambat gerak bot saat Time Stop Vindex; dilewati bila pemain null, tidak "playing", mati, urutan 25 aktif, atau pause. | internal (`tick`) |
| `_feed_lasers()` | - | `void` | Mengubah laser Time Stop Vindex (tiga garis sejajar) dan Rentetan Laser (fase warn/fire) menjadi format laser DALANG di `_lasers`. | internal (`_control`) |
| `_push_laser(out: Array, x: float, y: float, ang: float, warn: float, fire: float, off: float)` | `out: Array`, `x: float`, `y: float`, `ang: float`, `warn: float`, `fire: float`, `off: float` | `void` | Menambahkan satu laser (dengan offset tegak lurus `off`) ke array `out`. | internal (`_feed_lasers`) |
| `_wrap_d(a: float, b: float, period: float)` | `a: float`, `b: float`, `period: float` | `float` | Jarak satu sumbu pada ruang melingkar (tembus dinding) dengan periode `period`. | internal (`_dist`, `_eval`, `_eval_base`, `_smart_dist`) |
| `_dist(x1: float, y1: float, x2: float, y2: float)` | `x1: float`, `y1: float`, `x2: float`, `y2: float` | `float` | Jarak terdekat dua titik dengan mempertimbangkan tembus dinding. | internal (`_base_goal`, `_smart_goal`) |
| `_laser_dist(L: Dictionary, px: float, py: float)` | `L: Dictionary`, `px: float`, `py: float` | `float` | Jarak tegak lurus titik (px, py) ke garis laser `L`. | internal (`_snapshot`, `_spot_safety`) |
| `_snapshot()` | - | `float` | Memotret dunia ke buffer dasar (killer, panah, archer, meteor kecil/besar, laser, Vindex sebagai killer pengejar, gadfly) dan mengembalikan nilai ancaman; juga mengisi `_mind.alert`. | internal (`_bot_think`) |
| `_spot_safety(x: float, y: float)` | `x: float`, `y: float` | `float` | Pengali 0..1 seberapa aman titik item dari laser, meteor besar, dan Killer di dekatnya (1 = aman). | internal (`_base_goal`, `_smart_goal`) |
| `_set_goal(type: String, x: float, y: float, r: float, label: String)` | `type: String`, `x: float`, `y: float`, `r: float`, `label: String` | `void` | Menyimpan tujuan bot (jenis, posisi, radius, label) ke `_mind`. | internal (`_base_goal`, `_smart_goal`) |
| `_smart_goal()` | - | `void` | Mode pintar: tujuan tetap kotak putih; Power Kill/Time Stop/Nyawa dipungut hanya bila jalan memutarnya kecil (dibatasi `DETOUR_MAX` x keamanan titik); bila tidak ada target memakai `_base_goal`. | internal (`_bot_think`) |
| `_base_goal(threat: float)` | `threat: float` | `void` | Tujuan dasar BOT-X (dipakai hanya bila kotak putih tidak ada): memburu Archer/Killer saat Time Stop/Power Kill aktif, memilih item bernilai tertinggi, atau berkeliling acak. | internal (`_smart_goal`) |
| `_eval_base(d1: int, d2: int, gw: float)` | `d1: int`, `d2: int`, `gw: float` | `float` | Simulasi dasar BOT-X untuk rencana arah d1 lalu d2 selama horizon `BOT_H` frame (Killer, panah/Archer, meteor kecil, lingkaran meteor besar, laser, pencapaian tujuan) dan mengembalikan biaya (lebih kecil = lebih baik). | internal (`_eval`) |
| `_smart_dist(px: float, py: float)` | `px: float`, `py: float` | `float` | Jarak ke tujuan: lurus biasa, kecuali lewat dinding menghemat lebih dari `WRAP_MIN_SAVING`. | internal (`_eval`) |
| `_eval(d1: int, d2: int)` | `d1: int`, `d2: int` | `float` | Biaya total rencana: biaya dasar ditambah penalti Pusaran Ungu, zona tengah saat Rentetan Laser, sentuhan Gadfly, hadiah mencapai kotak putih, dan tarikan jarak ke tujuan. | internal (`_bot_think`) |
| `_bot_think()` | - | `void` | Berpikir tiap `BOT_EVERY` frame: memotret, memilih tujuan, mengevaluasi 9x9 rencana arah, dan mengantrekan arah terbaik (`pending`) agar berlaku setelah waktu reaksi `BOT_LAG`. | internal (`_control`) |
| `_move_bot()` | - | `void` | Menggerakkan pemain: menerapkan guncangan ledakan, mengaktifkan arah yang antre, percepatan halus, tembus dinding (`Util.wrap_obj`), dan partikel teleport saat melompat sisi layar. | internal (`_control`) |


#### `scripts/modes/hard/vindex_attacks.gd`

**Peran:** autoload `VindexAttacks` — serangan Lord Vindex di mode SULIT: Time Stop dengan laser terkunci, serta tantangan khusus setelah poin 25 yaitu Rentetan Laser (poin > 50) dan Pusaran Ungu (poin >= 75). Semuanya tidak berjalan bersamaan. State serangan dibaca oleh `Effects` (`State.vindex_barrage`, `State.vindex_vortex`).
**Port dari:** modes/hard/vindex-attacks.js
**Jumlah fungsi:** 27

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `lock_vindex_laser_target()` | - | `void` | Mengunci sudut laser ke arah pemain dan menghitung ujung laser (`vindex_laser_x/y`) jauh melewati tepi arena. | internal (`trigger_vindex_time_stop`, `update_vindex_time_stop`) |
| `set_vindex_time_stop_escape_target()` | - | `void` | Memilih pojok arena terjauh dari pemain sebagai tujuan gerak Vindex saat Time Stop (300 frame, tanpa teleport). | internal (`trigger_vindex_time_stop`) |
| `trigger_vindex_time_stop()` | - | `void` | Bila syarat terpenuhi (level hard, skor >= 25, urutan 25 selesai, tidak sibuk, jarak pemain 190-520), memulai Time Stop 300 frame, cooldown acak, mengunci titik asal gelombang, dan menampilkan pesan. | internal (`update_vindex_time_stop`) |
| `vindex_laser_hits_player()` | - | `bool` | Mengecek apakah pemain terkena garis laser dari titik asal tembak (hanya ke depan, jarak <= setengah lebar sinar + 0,35 ukuran pemain). | internal (`update_vindex_time_stop`) |
| `vindex_laser_hits_rect(entity)` | `entity` (tanpa tipe) | `bool` | Mengecek apakah sebuah entitas berkotak (x, y, w, h) terkena segmen laser. | internal (`kill_enemies_by_vindex_laser`) |
| `destroy_enemy_by_vindex_laser(enemy)` | `enemy` (tanpa tipe) | `void` | Memulai disintegrasi musuh (timer 38, flash, partikel) bila belum hancur/mati. | internal (`fire_barrage_round`, `kill_enemies_by_vindex_laser`, `update_vindex_vortex`) |
| `kill_enemies_by_vindex_laser()` | - | `void` | Menghancurkan Killer dan Archer yang terkena laser saat laser ditembakkan. | internal (`update_vindex_time_stop`) |
| `update_vindex_time_stop()` | - | `void` | Mesin status per tick untuk level hard: fase Time Stop (Vindex bergerak ke pojok), countdown penguncian 60 frame, tembak laser 42 frame (sekali damage + kematian bila nyawa habis), lalu cooldown dan pemicu Time Stop berikutnya. | `GameLoop.update_game` |
| `vindex_special_busy()` | - | `bool` | True bila Rentetan Laser atau Pusaran Ungu sedang berjalan. | internal (`trigger_vindex_time_stop`, `update_vindex_specials`, `vindex_anything_busy`); `TestBot._snapshot` |
| `vindex_anything_busy()` | - | `bool` | True bila ada serangan Vindex apa pun yang berjalan (khusus, Time Stop, countdown, atau tembakan laser). | internal (`update_vindex_specials`) |
| `in_vindex_hazard_zone(x: float, y: float)` | `x: float`, `y: float` | `bool` | Apakah titik berada di zona aman-rentetan (tengah arena) atau radius pusaran sehingga tidak boleh ditempati item/spawn. | internal (`move_collectibles_out_of_vindex_zones`); `Util.random_pos_away_from_player` |
| `move_collectibles_out_of_vindex_zones()` | - | `void` | Memindahkan item (target, health, powerup, time stop powerup) yang terlanjur berada di zona berbahaya ke posisi acak jauh dari pemain. | internal (`update_vindex_specials`) |
| `vindex_damage_player(amount: int, cause: String, message: String, shake: int = 16)` | `amount: int`, `cause: String`, `message: String`, `shake: int = 16` | `void` | Mengurangi nyawa pemain, mengatur cooldown hit, getar, dan pesan; bila nyawa habis mencatat penyebab kematian dan memulai animasi mati. | internal (`fire_barrage_round`) |
| `update_vindex_specials()` | - | `void` | Per tick: menjalankan update rentetan/pusaran yang aktif, menurunkan cooldown, dan memulai Pusaran (skor >= `VORTEX_MIN_SCORE`) atau Rentetan (skor >= `VINDEX_BARRAGE_MIN_SCORE`) bila tidak ada serangan lain; dilewati bila bukan "playing"/urutan 25 belum selesai. | `GameLoop.update_game` |
| `start_vindex_barrage()` | - | `void` | Memulai Rentetan Laser (fase "gather" di tengah arena), mengatur cooldown acak, getar, dan pesan. | internal (`update_vindex_specials`) |
| `_angle_diff(a: float, b: float)` | `a: float`, `b: float` | `float` | Selisih mutlak dua sudut (dinormalisasi, rentang 0..PI). | internal (`pick_barrage_angles`) |
| `pick_barrage_angles()` | - | `Array` | Memilih sudut sinar yang saling berjauhan dan tidak langsung mengarah ke pemain, dengan cadangan deterministik bila undian gagal. | internal (`start_barrage_round`) |
| `barrage_beam_hits(angle: float, ent)` | `angle: float`, `ent` (tanpa tipe) | `bool` | Apakah sinar rentetan pada sudut `angle` dari titik asal mengenai entitas `ent`. | internal (`fire_barrage_round`) |
| `update_vindex_barrage()` | - | `void` | Mesin fase rentetan: gather (Vindex ke tengah) -> warn -> fire -> gap, berulang `VINDEX_BARRAGE_ROUNDS` gelombang, lalu selesai (`vindex_barrage = null`). | internal (`update_vindex_specials`) |
| `start_barrage_round(b: Dictionary)` | `b: Dictionary` | `void` | Memulai satu gelombang: fase "warn", memilih sudut sinar baru, dan pesan sesuai nomor gelombang. | internal (`update_vindex_barrage`) |
| `fire_barrage_round(b: Dictionary)` | `b: Dictionary` | `void` | Menembakkan gelombang: getar, menghancurkan Killer/Archer yang terkena, dan melukai pemain bila terkena serta tidak dalam cooldown. | internal (`update_vindex_barrage`) |
| `start_vindex_vortex()` | - | `void` | Membuat Pusaran Ungu di posisi acak yang cukup jauh dari pemain dan Vindex (cadangan: pojok), mengatur cooldown, getar, dan pesan. | internal (`update_vindex_specials`) |
| `vortex_pull(ent, strength: float, _margin: float = 10.0)` | `ent` (tanpa tipe), `strength: float`, `_margin: float = 10.0` | `void` | Menarik entitas ke pusat pusaran dengan kekuatan naik mendekati lingkaran maut dan membatasi posisi dalam arena; `_margin` tidak dipakai. | internal (`update_vindex_vortex`) |
| `vortex_inside(ent)` | `ent` (tanpa tipe) | `bool` | Apakah pusat entitas berada dalam radius maut pusaran. | internal (`update_vindex_vortex`) |
| `update_vindex_vortex()` | - | `void` | Per tick: menarik pemain/Killer/Archer, menghancurkan musuh di dalam lingkaran, membunuh pemain yang masuk lingkaran seketika, dan meledakkan pusaran saat umur >= `VORTEX_ACTIVE_TIME`. | internal (`update_vindex_specials`) |
| `explode_vindex_vortex()` | - | `void` | Ledakan akhir: audio, partikel, gelombang kejut meteor besar, dan melempar pemain, Killer, serta Archer menjauhi pusaran. | internal (`update_vindex_vortex`) |
| `_vortex_push(ent, v: Dictionary, max_dist: float)` | `ent` (tanpa tipe), `v: Dictionary`, `max_dist: float` | `Dictionary` | Menghitung arah normal (`nx`, `ny`) dan kekuatan dorong (`power`) ledakan untuk entitas berdasarkan jaraknya dari pusaran. | internal (`explode_vindex_vortex`) |


### 9.8 `scripts/ui`

#### `scripts/ui/ui_kit.gd`

**Peran:** autoload `UiKit` — pembantu UI bersama yang meniru CSS web: font sans, letter-spacing, label bayangan/glow, StyleBox, tombol bergradien dengan bayangan bawah tegas (di-bake ke tekstur 9-slice), dan latar radial. Kanvas UI 1200x900 dengan papan 800x600 di tengah.
**Port dari:** — (meniru CSS web; tidak ada file JS asal di komentar)
**Jumlah fungsi:** 13

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `font(bold: bool = false)` | `bold: bool = false` | `Font` | Mengembalikan SystemFont sans (Arial/Helvetica dst.) bobot 400 atau 700, di-cache di `_fonts`. | internal (`spaced_font`); Callable internal (`make_label`, `style_button`); `GameUI.build`, `RulesScreen._make_item` |
| `font_italic()` | - | `Font` | Mengembalikan SystemFont miring (di-cache), untuk teks true ending. | `GameUI._font_italic` |
| `spaced_font(bold: bool, spacing: int)` | `bold: bool`, `spacing: int` | `Font` | Mengembalikan font dengan jarak antar huruf (FontVariation, di-cache); bila spacing <= 0 memakai `font(bold)`. | internal (`glow_text`, `make_label`, `style_button`); `GameUI.lbl` |
| `make_label(text: String, size: int, color: Color, bold: bool = true, align: int = HORIZONTAL_ALIGNMENT_LEFT, spacing: int = 0, shadow_color: Color = Color(0, 0, 0, 0), shadow_size: int = 0)` | `text: String`, `size: int`, `color: Color`, `bold: bool = true`, `align: int = HORIZONTAL_ALIGNMENT_LEFT`, `spacing: int = 0`, `shadow_color: Color = Color(0, 0, 0, 0)`, `shadow_size: int = 0` | `Label` | Membuat Label siap pakai dengan font berjarak, warna, dan bayangan berpendar bila `shadow_size > 0`. | internal (`glow_text`); `MenuScreen._ready`, `RulesScreen._ready` |
| `box(bg: Color, border: Color = Color(0, 0, 0, 0), border_w: int = 0, radius: int = 0, shadow: int = 0, shadow_color: Color = Color(0, 0, 0, 0.5), shadow_offset_y: int = 0, pad_h: int = 0, pad_v: int = 0)` | `bg: Color`, `border: Color = Color(0, 0, 0, 0)`, `border_w: int = 0`, `radius: int = 0`, `shadow: int = 0`, `shadow_color: Color = Color(0, 0, 0, 0.5)`, `shadow_offset_y: int = 0`, `pad_h: int = 0`, `pad_v: int = 0` | `StyleBoxFlat` | Membuat StyleBoxFlat dengan isi, border, sudut, bayangan (blur dan offset y), dan padding konten. | `GameUI.build_stage`, `RulesScreen._ready` |
| `style_button(btn: Button, normal: StyleBox, hover: StyleBox = null, pressed: StyleBox = null, font_size: int = 16, color: Color = Color.WHITE, bold: bool = true, spacing: int = 0)` | `btn: Button`, `normal: StyleBox`, `hover: StyleBox = null`, `pressed: StyleBox = null`, `font_size: int = 16`, `color: Color = Color.WHITE`, `bold: bool = true`, `spacing: int = 0` | `void` | Menerapkan stylebox normal/hover/pressed/disabled, fokus kosong, font, ukuran, dan warna teks pada tombol. | internal (`menu_button`); `GameUI._build_dalang_dock`, `GameUI.make_button` |
| `grad_box(top: Color, bottom: Color, border: Color, shadow: Color, radius: int = 8, dy: int = 4, bright: float = 1.0, pad_h: int = 0, pad_v: int = 0, bw: int = 1)` | `top: Color`, `bottom: Color`, `border: Color`, `shadow: Color`, `radius: int = 8`, `dy: int = 4`, `bright: float = 1.0`, `pad_h: int = 0`, `pad_v: int = 0`, `bw: int = 1` | `StyleBoxTexture` | Membuat kotak gradien vertikal 9-slice dengan border dan bayangan bawah tegas; tekstur di-bake lewat `_bake` dan di-cache per kombinasi parameter. | internal (`menu_button`); `GameUI._build_dalang_dock`, `GameUI.make_button`, `GameUI.skin_skill` |
| `menu_button(text: String, top: Color, bottom: Color, fg: Color, border: Color, shadow: Color, min_size: Vector2, font_size: int = 16, spacing: int = 1)` | `text: String`, `top: Color`, `bottom: Color`, `fg: Color`, `border: Color`, `shadow: Color`, `min_size: Vector2`, `font_size: int = 16`, `spacing: int = 1` | `Button` | Membuat tombol bergaya CSS `a.btn` (gradien, border, bayangan bawah; hover lebih terang, pressed lebih gelap dan lebih datar). | `MenuScreen._make_button`, `RulesScreen._ready` |
| `radial_bg(parent: Node, center: Vector2, colors: Array, offsets: Array, base: Color)` | `parent: Node`, `center: Vector2`, `colors: Array`, `offsets: Array`, `base: Color` | `Control` | Membuat latar radial full-rect (ColorRect dasar + gradien radial) dan menambahkannya ke parent. | `GameUI.build_stage`, `MenuScreen._ready`, `RulesScreen._ready` |
| `_bright(c: Color, k: float)` | `c: Color`, `k: float` | `Color` | Mengalikan RGB warna dengan k (maks 1.0) untuk meniru `filter: brightness`; k = 1 mengembalikan warna asli. | internal (`grad_box`) |
| `_bake(top: Color, bottom: Color, border: Color, shadow: Color, r: int, dy: int, bw: int)` | `top: Color`, `bottom: Color`, `border: Color`, `shadow: Color`, `r: int`, `dy: int`, `bw: int` | `ImageTexture` | Merender gambar tombol piksel demi piksel (gradien, border, sudut membulat, bayangan bawah sedalam dy) menjadi ImageTexture. | internal (`grad_box`) |
| `glow_text(text: String, size: int, color: Color, bold: bool, spacing: int, glow_color: Color, layers: Array)` | `text: String`, `size: int`, `color: Color`, `bold: bool`, `spacing: int`, `glow_color: Color`, `layers: Array` | `Control` | Membuat teks berpendar dengan menumpuk label transparan berbayangan (tiap layer: outline px dan pengali alpha) di bawah teks utama. | `GameUI._build_dalang_brief`, `MenuScreen._ready` |
| `_sd_round(x: float, y: float, hx: float, hy: float, r: float)` | `x: float`, `y: float`, `hx: float`, `hy: float`, `r: float` | `float` | Menghitung jarak bertanda ke tepi kotak membulat (negatif = di dalam); dipakai `_bake`. | internal (`_bake`) |


#### `scripts/ui/game_ui.gd`

**Peran:** autoload `GameUI` — pengganti DOM halaman game (mudah/normal/sulit/santai/dalang.html + CSS game). `build(root)` membuat seluruh node UI pada ruang logis 800x600 (HUD, overlay, layar akhir, true ending, UI dalang), dan `node(id)` mengembalikan node berdasarkan id HTML aslinya. Juga menyimpan palet warna aktif (`pal`) per level.
**Port dari:** halaman game HTML (mudah/normal/sulit/santai/dalang.html) + CSS game/* (dari komentar kepala file)
**Jumlah fungsi:** 37

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `node(id: String)` | `id: String` | `void` | Mengambil node terdaftar berdasarkan id HTML asli; mengembalikan null bila tidak ada atau sudah tidak valid. | `DalangFlow._ui`, `GameFlow._set_text`, `GameFlow._set_visible`, `GameFlow.show_end`, `GameLoop._set_visible`, `HardSequence._set_end_buttons_visible`, `HardSequence.finish_hard25_sequence`, `HardSequence.update_hard25_sequence`, `HardSubtitle._label`, `Hud.update_hud`, `Killers.show_spawn_warning` |
| `_put(id: String, n: Node)` | `id: String`, `n: Node` | `Node` | Mendaftarkan node ke registri `_reg` dengan id-nya lalu mengembalikan node itu. | internal (`_build_dalang_brief`, `_build_dalang_dock`, `_build_dalang_hud`, `_build_dalang_hurt`, `_build_end_screen`, `_build_game_screen`, `_build_hud`, `_build_mobile_controls`, `_build_overlays`, `_build_subtitle_and_badge`, `_build_top_buttons`, `_build_true_ending`); `GameMenuButton.build` |
| `_c(hex)` | `hex` (tanpa tipe) | `Color` | Mengubah string hex menjadi `Color`; bila sudah `Color` dikembalikan apa adanya. | internal (`build_stage`, `lbl`, `make_button`, `rich`, `sbox`) |
| `sbox(bg: Color, border = null, bw := 0, radius := 0, pad_h := 0, pad_v := 0)` | `bg: Color`, `border = null` (tanpa tipe), `bw := 0`, `radius := 0`, `pad_h := 0`, `pad_v := 0` | `StyleBoxFlat` | Membuat StyleBoxFlat dengan warna isi, border opsional, sudut membulat, dan padding konten, anti-aliasing aktif. | internal (`_build_dalang_hud`, `_build_end_screen`, `_build_hud`, `_build_mobile_controls`, `_build_subtitle_and_badge`, `_kv`, `_pill`); `GameMenuButton.build` |
| `_ignore(c: Control)` | `c: Control` | `Control` | Mengatur mouse_filter ke IGNORE lalu mengembalikan control; tidak ada pemanggil di kode yang dibaca. | tidak ada pemanggil ditemukan |
| `ctl(parent: Node, x: float, y: float, w: float, h: float)` | `parent: Node`, `x: float`, `y: float`, `w: float`, `h: float` | `Control` | Membuat Control polos yang tidak menangkap mouse pada rect x,y,w,h dan memasangkannya ke parent. | internal (`_build_hud`) |
| `_full(c: Control)` | `c: Control` | `void` | Mengatur anchor/offset control ke preset FULL_RECT. | internal (`_build_dalang_brief`, `_build_dalang_hud`, `_build_dalang_hurt`, `_build_end_screen`, `_build_game_screen`, `_build_mobile_controls`, `_build_overlays`, `_build_true_ending`, `_end_bg`) |
| `lbl(parent: Node, text: String, size: int, color, bold := true, align := HORIZONTAL_ALIGNMENT_LEFT, shadow := true, spacing := 0, glow_color := Color(0, 0, 0, 0), glow := 0)` | `parent: Node`, `text: String`, `size: int`, `color` (tanpa tipe), `bold := true`, `align := HORIZONTAL_ALIGNMENT_LEFT`, `shadow := true`, `spacing := 0`, `glow_color := Color(0, 0, 0, 0)`, `glow := 0` | `Label` | Membuat Label bergaya (font berjarak huruf, warna, bayangan hitam 2px atau bayangan berpendar bila `glow > 0`); dipasang ke parent bila parent tidak null. | internal (`_build_dalang_brief`, `_build_dalang_hud`, `_build_end_screen`, `_build_hud`, `_build_overlays`, `_build_subtitle_and_badge`, `_build_true_ending`, `_kv`, `_pill`, `_skill_tile`); `GameMenuButton.build` |
| `rich(parent: Node, bbcode: String, size: int, color, align := "left")` | `parent: Node`, `bbcode: String`, `size: int`, `color` (tanpa tipe), `align := "left"` | `RichTextLabel` | Membuat teks BBCode (fit_content, tanpa scroll, autowrap) yang dibungkus tag align; dipakai untuk briefing dalang. | internal (`_build_dalang_brief`) |
| `make_button(parent: Node, text: String, kind := "light", size := 17, pad_v := 13, pad_h := 20, spacing := 0)` | `parent: Node`, `text: String`, `kind := "light"`, `size := 17`, `pad_v := 13`, `pad_h := 20`, `spacing := 0` | `Button` | Membuat tombol bergradien bergaya CSS dengan varian "red" (palet aktif), "dark", atau "light" beserta gaya hover/pressed. | internal (`_build_dalang_brief`, `_build_end_screen`, `_build_top_buttons`, `_build_true_ending`); `GameMenuButton.build` |
| `_grad_tex(colors: Array, offsets: Array, radial: bool, from := Vector2(0.5, 0.5), to := Vector2(1, 1), w := 64, h := 64)` | `colors: Array`, `offsets: Array`, `radial: bool`, `from := Vector2(0.5, 0.5)`, `to := Vector2(1, 1)`, `w := 64`, `h := 64` | `GradientTexture2D` | Membuat tekstur gradien linear atau radial dari daftar warna dan offset. | internal (`_build_dalang_brief`, `_build_dalang_dock`, `_end_bg`) |
| `_tex_rect(parent: Node, tex: Texture2D)` | `parent: Node`, `tex: Texture2D` | `TextureRect` | Membuat TextureRect skala-regang yang mengabaikan mouse dan memasangkannya ke parent. | internal (`_build_dalang_brief`, `_build_dalang_dock`, `_end_bg`) |
| `_spacer(parent: Node, h: float)` | `parent: Node`, `h: float` | `void` | Menambahkan Control kosong setinggi h sebagai pengisi jarak vertikal. | internal (`_build_end_screen`, `_build_true_ending`) |
| `build(root: Control)` | `root: Control` | `void` | Titik masuk: mereset registri, memilih palet (dalang/santai/hard/red) dari `State.page_level` dan `State.spectator_mode`, memasang tema font, lalu membangun layar game, layar akhir, dan true ending. | `GameRoot._ready` |
| `build_stage(root: Control, frame: Control)` | `root: Control`, `frame: Control` | `void` | Memasang latar radial halaman di belakang papan (child indeks 0) dan gaya bingkai papan sesuai palet; dipanggil setelah `build()`. | `GameRoot._ready` |
| `_build_game_screen(root: Control)` | `root: Control` | `void` | Membuat node `gameScreen` lalu menyusun HUD, tombol atas, overlay, subtitle/lencana, elemen dalang atau kontrol sentuh, dan tombol MENU. | internal (`build`) |
| `_build_hud(gs: Control)` | `gs: Control` | `void` | Membangun HUD: teks skor/waktu, kapsul status power, dan tiga ikon nyawa (didaftarkan sebagai `hud`, `scoreText`, `scoreNumber`, `powerStatus`, `powerText`, `lives`). | internal (`_build_game_screen`) |
| `_draw_life(c: Control)` | `c: Control` | `void` | Callback gambar satu ikon nyawa (hijau bila hidup, abu-abu bila meta `dead` true) dengan tanda plus. | Callable internal (`_build_hud`) |
| `_build_top_buttons(gs: Control)` | `gs: Control` | `void` | Membuat tombol bisu (`muteButton`, memanggil `GameAudio.toggle_mute`) dan tombol PAUSE (`pauseButton`, memanggil `GameFlow.toggle_pause`, awalnya tersembunyi). | internal (`_build_game_screen`) |
| `_build_overlays(gs: Control)` | `gs: Control` | `void` | Membuat overlay `pauseText`, `readyOverlay` ("BERSIAPLAH"), dan `spawnWarning` (peringatan killer berkedip dengan tween loop; kosong untuk dalang). | internal (`_build_game_screen`) |
| `_build_subtitle_and_badge(gs: Control)` | `gs: Control` | `void` | Membuat label `hardSubtitle` (subtitle Lord Vindex, awalnya transparan) dan lencana `spectatorBadge` yang terlihat hanya pada mode penonton. | internal (`_build_game_screen`) |
| `_build_mobile_controls(gs: Control)` | `gs: Control` | `void` | Membuat empat tombol panah sentuh (dalam `mobileControls`) yang memanggil `GameInput.control_down/up` dan `pointer_down`; terlihat hanya bila ada layar sentuh dan bukan mode penonton. | internal (`_build_game_screen`) |
| `_end_bg(parent: Control)` | `parent: Control` | `Control` | Membuat Panel latar layar akhir (penangkap mouse, gradien radial gelap, full rect). | internal (`_build_end_screen`, `_build_true_ending`) |
| `_build_end_screen(root: Control)` | `root: Control` | `void` | Membangun layar GAME OVER (`endScreen`, `endTitle`, `finalScore`, `dlResult` untuk dalang, `hardDeathMessage`, `endButtons`, tombol MAIN LAGI -> `GameFlow.restart_game`, MENU -> `GameFlow.show_menu`). | internal (`build`) |
| `_build_true_ending(root: Control)` | `root: Control` | `void` | Membangun layar `trueEndingScreen` (SELAMAT, TRUE ENDING, tombol KEMBALI KE MENU -> `GameFlow.show_menu`). | internal (`build`) |
| `_font_italic()` | - | `Font` | Pembungkus untuk `UiKit.font_italic()`. | internal (`_build_true_ending`) |
| `_build_dalang_hurt(gs: Control)` | `gs: Control` | `void` | Membuat overlay `dlHurt`, bingkai sian berlapis yang digambar lewat sinyal draw (awalnya transparan) sebagai efek terluka. | internal (`_build_game_screen`) |
| `_pill(text: String, size: int, color, bg: Color, border, radius: int, pad_h: int, pad_v: int)` | `text: String`, `size: int`, `color` (tanpa tipe), `bg: Color`, `border` (tanpa tipe), `radius: int`, `pad_h: int`, `pad_v: int` | `Label` | Membuat label kapsul berlatar dan border (tanpa parent) untuk chip/toast dalang. | internal (`_build_dalang_hud`) |
| `_build_dalang_hud(gs: Control)` | `gs: Control` | `void` | Membuat HUD dalang: bar energi (`dlEnergy`, `dlEnergyFill`, `dlEnergyText`), rekor (`dlBest`), chip BOT terkunci (`dlFreezeChip`), dan toast (`dlToast`). | internal (`_build_game_screen`) |
| `_build_dalang_dock(gs: Control)` | `gs: Control` | `void` | Membuat dock enam tile skill dari `DalangConfig.DL_SKILLS` (`dlDock`) dan tombol putar arah laser `dlRotate` yang menambah `laser_step` modulo 12 pada `DalangFlow.dl`. | internal (`_build_game_screen`) |
| `_kv(parent: Node, head: String, body: String)` | `parent: Node`, `head: String`, `body: String` | `void` | Menambahkan kartu kecil judul + isi untuk grid info briefing dalang. | internal (`_build_dalang_brief`) |
| `_build_dalang_brief(gs: Control)` | `gs: Control` | `void` | Membuat layar briefing `dlBrief` (judul DALANG, penjelasan, grid info, aturan, petunjuk tombol, tombol MULAI); klik apa pun atau tombol memanggil `GameFlow.begin_play`. | internal (`_build_game_screen`) |
| `_adopt(parent: Node, child: Node)` | `parent: Node`, `child: Node` | `void` | Menambahkan child ke parent hanya bila child belum punya parent. | internal (`_build_dalang_brief`, `_build_dalang_dock`, `_build_dalang_hud`, `_build_dalang_hurt`, `_build_end_screen`, `_build_game_screen`, `_build_hud`, `_build_mobile_controls`, `_build_overlays`, `_build_subtitle_and_badge`, `_build_true_ending`, `_end_bg`, `_kv`, `_skill_tile`, `_spacer`, `_tex_rect`, `ctl`, `lbl`, `make_button`, `rich`, `strip`) |
| `_skill_tile(sk: Dictionary)` | `sk: Dictionary` | `Button` | Membuat tile skill dock (nomor tombol, ikon, nama, biaya) dengan meta keadaan; tekan memanggil `DalangSkills.on_skill_pressed(id)`. | internal (`_build_dalang_dock`) |
| `skin_skill(b: Button)` | `b: Button` | `void` | Menerapkan gaya tile skill berdasarkan meta `is_sel`/`is_ready`/`is_low` (gradien, border, alpha, warna biaya) lalu meminta redraw. | internal (`_skill_tile`); `DalangFlow.dl_update_ui` |
| `_skill_draw(b: Button)` | `b: Button` | `void` | Callback gambar overlay cooldown gelap dari bawah sesuai meta `cd` (0..1). | Callable internal (`_skill_tile`) |
| `strip(parent: Node, y: float, h: float)` | `parent: Node`, `y: float`, `h: float` | `CenterContainer` | Membuat pita selebar papan (800) pada posisi y setinggi h berisi CenterContainer untuk memusatkan overlay. | internal (`_build_dalang_brief`, `_build_dalang_hud`, `_build_hud`, `_build_overlays`, `_build_subtitle_and_badge`); `GameMenuButton.build` |


#### `scripts/ui/menu_screen.gd`

**Peran:** scene `scenes/menu/menu.tscn` (skrip root, `extends Control`) — layar menu utama. Menampilkan judul dan tombol mode; tombol mode mengisi `State.page_level`/`State.spectator_mode` lalu pindah ke scene game.
**Port dari:** app/pages/menu.html + assets/css/pages/menu.css (dari komentar kepala file)
**Jumlah fungsi:** 5

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_ready()` | - | `void` | Menyusun UI menu: latar radial, judul bergelombang, garis merah, tombol mode (SANTAI/MUDAH/NORMAL/SULIT/DALANG), CARA MAIN (`Util.goto_page("rules")`), dan KEMBALI (keluar game). | engine (Godot) |
| `_start_mode(level: String, spectator: bool)` | `level: String`, `spectator: bool` | `void` | Menyimpan `State.page_level` dan `State.spectator_mode` lalu `Util.goto_page("game")`. | Callable internal (`_ready`) |
| `_make_button(text: String, kind: String)` | `text: String`, `kind: String` | `Button` | Membuat tombol menu dengan warna dari `STYLES[kind]` lewat `UiKit.menu_button` (ukuran 330x54). | internal (`_ready`) |
| `_line()` | - | `Control` | Membuat garis merah tipis 520x1 berupa gradien transparan-merah-transparan. | internal (`_ready`) |
| `_spacer(h: float)` | `h: float` | `Control` | Membuat Control kosong setinggi h sebagai pengisi jarak (tidak dipasang otomatis). | internal (`_ready`) |


#### `scripts/ui/rules_screen.gd`

**Peran:** scene `scenes/menu/rules.tscn` (skrip root, `extends Control`) — layar CARA MAIN: panel bergulir berisi daftar `ITEMS` (ikon pratinjau + judul + penjelasan) dan tombol kembali ke menu (`Util.goto_page("menu")`). Berisi kelas dalam `Preview` untuk menggambar ikon karakter.
**Port dari:** app/pages/cara-main.html + assets/css/pages/rules.css (dari komentar kepala file)
**Jumlah fungsi:** 7

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_init(k: String = "")` | `k: String = ""` | `void` | Konstruktor: menyimpan jenis ikon, mengatur ukuran minimum 84x84 dan mengabaikan mouse. | engine (Godot) |
| `_rrect(r: Rect2, fill: Color, border: Color, bw: float, radius: int)` | `r: Rect2`, `fill: Color`, `border: Color`, `bw: float`, `radius: int` | `void` | Menggambar kotak membulat berisi dan berborder memakai StyleBoxFlat. | internal (`_draw`) |
| `_draw()` | - | `void` | Menggambar ikon sesuai `kind` (player, target, health, gadfly, killer, archer, power, timestop, vindex, meteor); selain itu menulis `kind` sebagai teks/emoji. | engine (Godot) |
| `_ready()` | - | `void` | Membangun layar: latar radial, panel tengah, judul CARA MAIN, daftar bergulir dari `ITEMS`, tombol KEMBALI KE MENU, dan menghubungkan `resized` ke `_layout`. | engine (Godot) |
| `_layout()` | - | `void` | Menempatkan panel di tengah dengan lebar `clampf(size.x*0.7, 844, 1100)` dan tinggi 86% layar. | internal (`_ready`); Callable internal (`_ready`) |
| `_spacer(h: float)` | `h: float` | `Control` | Membuat Control kosong setinggi h sebagai pengisi jarak. | internal (`_ready`) |
| `_make_item(it: Array, last: bool)` | `it: Array`, `last: bool` | `Control` | Membuat satu baris item (ikon `Preview` + RichTextLabel judul berwarna/isi, BBCode `[` di-escape) dan pemisah tipis bila bukan item terakhir. | internal (`_ready`) |


### 9.9 `tests`

#### `tests/compile_check.gd`

**Peran:** modul biasa (skrip `SceneTree` untuk `--script`, di luar autoload) — memuat semua `.gd` di `res://scripts` dan melaporkan kegagalan kompilasi; exit code 1 bila ada yang gagal.
**Port dari:** —
**Jumlah fungsi:** 2

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_process(_delta: float)` | `_delta: float` | `bool` | Pada frame pertama mengumpulkan skrip, me-`load` tiap file, mencetak `LOAD FAILED` dan ringkasan, lalu `quit`. | engine (Godot) |
| `_collect(dir: String, out: Array)` | `dir: String`, `out: Array` | `void` | Menelusuri folder secara rekursif dan menambahkan path `.gd` ke `out`. | internal (`_collect`, `_process`) |


#### `tests/smoke_test.gd`

**Peran:** modul biasa (skrip `SceneTree` untuk `--script`) — uji asap runtime: memainkan tiap level (easy, normal, hard, dalang, hard penonton) dengan input acak selama ~2600 frame dan mencetak status akhir.
**Port dari:** —
**Jumlah fungsi:** 1

| Metode | Parameter | Kembalian | Kegunaan | Dipakai oleh |
|---|---|---|---|---|
| `_process(_delta: float)` | `_delta: float` | `bool` | State machine per frame: memuat scene game, memulai permainan, menekan tombol acak, menaikkan skor pada frame tertentu, mencetak hasil tiap run, lalu `quit(0)` setelah semua run. | engine (Godot) |


## 10. Catatan, temuan, dan batasan

### Temuan dari pemeriksaan

1. **Lagu latar belum ada.** `Config.AUDIO.files.music` mengarah ke `music-main.mp3`, tetapi berkas itu tidak ada di `assets/audio/`. Game tetap berjalan tanpa musik. Tambahkan berkas dengan nama itu, atau ubah nilainya di `scripts/core/config.gd`.
2. **`assets/audio/README.md` masih berisi rujukan versi web.** Rujukannya ke `app/js/core/config.js`, catatan "dibuka lewat file://", dan saran hosting tidak berlaku di Godot. Sumber konfigurasi yang benar adalah `Config.AUDIO` di `scripts/core/config.gd`. Tombol M dan tombol 🔊 di layar tetap berlaku.
3. **Enam fungsi tidak dipakai di kode.** Ini bukan galat, tetapi kandidat untuk dihapus:

   - `DrawKit.line()` — `scripts/render/draw_kit.gd` baris 32
   - `DrawKit.alpha()` — `scripts/render/draw_kit.gd` baris 58
   - `GameAudio.unlock()` — `scripts/systems/audio.gd` baris 61
   - `GameUI._ignore()` — `scripts/ui/game_ui.gd` baris 83
   - `Sprites.hide_cinematic_vindex()` — `scripts/render/sprites.gd` baris 88
   - `Sprites._circle()` — `scripts/render/sprites.gd` baris 205

   `GameAudio.unlock()` adalah no-op. Di Godot tidak perlu gestur pengguna untuk membuka audio, jadi fungsi ini tidak punya tugas.
4. **`State.ending_raf` tidak dipakai.** Variabel ini hanya dideklarasikan. Isinya sisa dari versi web (id `requestAnimationFrame`) dan aman dihapus.

### Kolom "Dipakai oleh" dibuat dari kode

Kolom ini dihasilkan oleh pemeriksa yang membaca setiap berkas, bukan ditulis tangan. Pemanggilan lintas berkas dikenali lewat nama autoload dan nama `preload` (mis. `Shapes`). Pemanggilan tanpa kualifier hanya dihitung di berkas yang sama. Batasannya: pemanggilan lewat variabel objek (`obj.fungsi()` dengan `obj` bukan autoload) tidak terdeteksi. Bila menambah pola itu, perbarui kolom secara manual.

### Deskripsi kegunaan

Signature, tipe kembalian, dan pemanggil diperiksa dari kode. Deskripsi kegunaan ditulis dari membaca kode dan belum diuji satu per satu lewat permainan. Bila ada yang tidak sesuai, kode adalah sumber kebenaran.

### Platform dan pengujian

- Diuji di Godot 4.5.1 headless pada Linux: kompilasi semua skrip, smoke test lima mode, dan screenshot. Belum diuji di perangkat nyata, Windows, macOS, atau Android.
- Versi foto (`PhotoKit` dan percabangannya di `Sprites`, `Background`, `DrawGame`, `HardIntro`) ditambahkan tanpa Godot di lingkungan penulisan, jadi belum dijalankan. Jalankan `compile_check.gd` dan `smoke_test.gd`, lalu taruh satu foto di `assets/photos/` untuk memeriksa tampilannya.
- Emoji di UI (☰, ⏸, ▶, 🔊, 🔇) bergantung pada font emoji sistem. Di lingkungan uji tanpa font emoji, emoji tidak tampil.
- Tampilan dibuat mirip dengan versi web, tetapi belum identik piksel demi piksel (gradien dan beberapa bayangan didekati).
