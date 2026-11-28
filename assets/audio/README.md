# Daftar audio

Taruh file di folder ini dengan **nama persis** seperti tabel. File bawaan adalah placeholder
**hening** supaya tidak ada error — cukup timpa dengan file asli (format **.mp3**, nama sama).

| File | Kapan diputar | Catatan |
|---|---|---|
| `music-main.mp3` | Lagu latar saat permainan dimulai (loop) | Terpendam otomatis saat Time Stop. Disarankan 1–3 menit, bisa di-loop mulus |
| `sfx-point.mp3` | Pemain mengambil target (dapat poin) | Pendek, ±0,1–0,3 dtk |
| `sfx-health.mp3` | Pemain mengambil nyawa (+) | |
| `sfx-power-kill.mp3` | Pemain mengambil Power Kill | |
| `sfx-time-stop.mp3` | Pemain mengambil item Time Stop | |
| `sfx-hit.mp3` | Pemain terkena serangan apa pun (Killer, Gadfly, panah, meteor, Vindex) | |
| `sfx-killer-laugh.mp3` | Tawa Killer — **tambahan** saat yang mengenai pemain adalah Killer | Berbunyi bersamaan dengan `sfx-hit` |
| `sfx-meteor-pass.mp3` | Setiap satu meteor kecil muncul/lewat | Dibatasi maks. 1× per 0,28 dtk dan nadanya bervariasi agar tidak berisik |
| `sfx-meteor-big.mp3` | Meteor besar jatuh (saat menghantam arena) | Bisa lebih panjang & berat |

## Opsional
- Lagu khusus mode Sulit: taruh `music-hard.mp3`, lalu di `app/js/core/config.js` ubah
  `musicHard: null` menjadi `musicHard: 'music-hard.mp3'`. Kalau dibiarkan `null`, Sulit memakai `music-main.mp3`.
- Mematikan satu suara: ubah nilainya menjadi `null` di `AUDIO.files` (config.js).
- Volume, tingkat "terpendam", dan jeda antar suara diatur di blok `AUDIO` pada `config.js`.

## Perilaku
- Lagu mulai saat permainan benar-benar dimulai (setelah tombol/sentuhan pertama), berhenti saat game over / ending,
  ikut jeda saat PAUSE atau tab disembunyikan.
- Saat Time Stop (dan Time Stop Lord Vindex) lagu diredam (filter low-pass + volume turun) lalu pulih sendiri.
- Tombol **M** atau tombol 🔊 di kiri tombol PAUSE untuk bisu; pilihan tersimpan di peramban.
- Browser baru mengizinkan suara setelah ada interaksi pengguna — game sudah menangani ini otomatis.
- Dibuka lewat `file://` tetap berfungsi (efek suara & lagu jalan, hanya peredaman memakai volume saja).
  Untuk peredaman penuh dan performa terbaik, jalankan lewat hosting / server web.
