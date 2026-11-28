# Daftar foto

Taruh foto di folder ini dengan **nama persis** seperti tabel. Pola kerjanya sama dengan `assets/audio/`:
nama file dibaca dari `Config.PHOTOS.files` (`scripts/core/config.gd`), dan **file yang belum ada
dilewati**. Bagian itu tetap digambar dengan gaya vektor bawaan, jadi foto boleh diisi satu per satu.

Foto dimuat sekali saat game dibuka oleh autoload `PhotoKit` (`scripts/render/photo_kit.gd`).
Setelah menaruh file baru, buka editor Godot sekali agar file diimpor, lalu jalankan game.
Di konsol debug akan tercetak `[PhotoKit] N/18 foto dimuat` dan daftar foto yang belum ada.

## Peta: `map/`

| File | Dipakai di | Ukuran disarankan | Catatan |
|---|---|---|---|
| `map/arena.png` | Latar arena semua level (`Background.draw_game_background`) | 1600×1200 (rasio 4:3) | Papan arena 800×600. Rasio lain dipotong dari tengah (tidak gepeng). Bayangan tepi (vignette) tetap dipasang di atasnya, matikan lewat `Config.PHOTOS.vignette`. |
| `map/hard-intro.png` | Adegan pembuka SULIT (`HardIntro.draw_hard_intro_bg`) | 1600×1200 | Opsional. Menggantikan gradien ungu. |
| `map/ending.png` | Adegan ending (`DrawGame._draw_ending_backdrop`) | 1600×1200 | Opsional. Otomatis digelapkan 45% agar teks terbaca. |

## Entitas: `entities/`

Ukuran tampil di game kecil (22–44 px). Foto besar diperkecil halus oleh mipmap, tetapi
subjek yang rapat mengisi bingkai akan lebih jelas terbaca daripada foto dengan banyak ruang kosong.
Foto **PNG dengan latar transparan** (objek sudah dipotong) paling bagus. Foto persegi biasa (JPG/PNG tanpa alpha)
tetap bisa, tetapi tampil sebagai kotak foto.

| File | Entitas | Ukuran tampil | Rasio | Arah / catatan |
|---|---|---|---|---|
| `entities/player.png` | Pemain | 24×24 | 1:1 | Tidak berputar saat bermain. |
| `entities/target.png` | Target poin | 22×22 | 1:1 | Berdenyut pelan. |
| `entities/health.png` | Item nyawa | 25×25 | 1:1 | Berdenyut. |
| `entities/power.png` | Item Power Kill | 26×26 | 1:1 | Berdenyut. |
| `entities/timestop.png` | Item Time Stop | 28×28 | 1:1 | Berdenyut. |
| `entities/gadfly.png` | Gadfly | 32×24 | 4:3 | **Kepala menghadap atas.** Berputar sesuai gerak. |
| `entities/gadfly-frozen.png` | Gadfly beku | 32×24 | 4:3 | Opsional. Bila tidak ada, `gadfly.png` diberi warna dingin. |
| `entities/killer.png` | Killer | 30×30 | 1:1 | Miring, membesar, dan hancur lewat animasi bawaan. Cincin pengisian serangan, `!`, dan `HA!` tetap efek bawaan. |
| `entities/archer.png` | Archer | 32×32 | 1:1 | **Menghadap kanan**, berputar mengikuti arah bidik. Label `AIM` tetap efek bawaan. |
| `entities/arrow.png` | Anak panah Archer | 24×12 | 2:1 | **Ujung ke kanan.** |
| `entities/arrow-lord.png` | Panah Lord Vindex | 24×12 | 2:1 | Opsional. Bila tidak ada, `arrow.png` diberi warna ungu. |
| `entities/vindex.png` | Lord Vindex | 44×44 | 1:1 | Dipakai juga di adegan pembuka SULIT (ukuran besar, sekitar 76 px). Aura ungu berdenyut tetap digambar di sekelilingnya. |
| `entities/meteor-small.png` | Meteor kecil | 1,2–1,3× lebar meteor | 1:1 | Berputar. Ekor api tetap efek bawaan. Dipakai juga di adegan pembuka SULIT. |
| `entities/meteor-small-hard.png` | Meteor kecil mode SULIT | sama | 1:1 | Opsional. Bila tidak ada, `meteor-small.png` diberi warna ungu. |
| `entities/meteor-big.png` | Meteor besar (bukan SULIT) | 120 px (`LARGE_METEOR_SIZE` 100 × 1,2) | 1:1 | Berputar. |

## Yang tetap digambar vektor

Efek dan UI tidak diganti foto: ekor meteor, cincin dan peringatan, laser, pusaran, gelombang Time Stop,
partikel, teks cerita, HUD, tombol, serta kerangka Dalang (segel beku, label BOT-X).

## Mematikan / mengubah

- Matikan semua foto: `Config.PHOTOS.enabled = false` (`scripts/core/config.gd`).
- Matikan satu foto: ubah nilainya menjadi `null` di `Config.PHOTOS.files`.
- Ganti nama atau format file: ubah nilainya di `Config.PHOTOS.files`. Format apa pun yang bisa diimpor Godot
  (png, jpg, webp) boleh dipakai.

## Gambar pengganti (placeholder)

File PNG yang ada di folder ini saat ini dibuat oleh `tools/make_placeholder_photos.py`: ilustrasi sementara, **bukan foto asli**,
hanya untuk mengetes jalur foto. Timpa dengan foto asli bernama sama kapan saja.

```
pip install pillow
python3 tools/make_placeholder_photos.py          # hanya membuat file yang belum ada (foto asli aman)
python3 tools/make_placeholder_photos.py --force  # timpa semuanya dengan gambar pengganti
```

Untuk kembali ke gambar vektor bawaan, hapus file PNG-nya atau setel `Config.PHOTOS.enabled = false`.
