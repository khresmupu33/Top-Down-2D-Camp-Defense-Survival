# Arsitektur

Versi Godot mempertahankan logika dan angka penyeimbang dari versi web. Perbedaan utamanya: loop, gambar, dan UI memakai pola Godot, tetapi aturan permainannya tetap sama.

## Autoload (singleton)

Setiap modul JS menjadi satu autoload. Pemanggilan lintas modul ditulis `Owner.nama_fungsi(...)` (nama JS dalam snake_case).

| Autoload | File | Asal (JS) |
|---|---|---|
| `Config` | `scripts/core/config.gd` | `core/config.js` (konstanta) |
| `State` | `scripts/core/state.gd` | `core/state.js` (semua variabel global) |
| `Util` | `scripts/core/util.gd` | `core/utils.js` + `now()`, `after_ms()`, `goto_page()` |
| `DrawKit` | `scripts/render/draw_kit.gd` | pengganti `ctx.*` canvas 2D |
| `PhotoKit` | `scripts/render/photo_kit.gd` | baru: pemuat foto peta dan entitas (versi foto) |
| `GameAudio` | `scripts/systems/audio.gd` | `systems/audio.js` |
| `TimeStop`, `Particles`, `Story`, `Hud` | `scripts/systems/*.gd` | `systems/*.js` |
| `HardSubtitle`, `GameMenuButton` | `scripts/systems/subtitle.gd`, `menu_button.gd` | `systems/subtitle.js`, `menu-button.js` |
| `Player`, `Items`, `Killers`, `Gadflies`, `Archers`, `Meteors`, `LordVindex` | `scripts/entities/*.gd` | `entities/*.js` |
| `VindexAttacks`, `HardIntro`, `HardSequence`, `TestBot` | `scripts/modes/hard/*.gd` | `modes/hard/*.js` |
| `GameSetup`, `GameLoop`, `GameFlow`, `GameInput` | `scripts/game/*.gd` | `game/*.js` |
| `Sprites`, `Effects`, `Background`, `DrawGame` | `scripts/render/*.gd` | `render/*.js` + `characters/*.css` |
| `GameUI` | `scripts/ui/game_ui.gd` | DOM halaman game + `assets/css/game/*.css` |
| `UiKit` | `scripts/ui/ui_kit.gd` | gaya CSS bersama: font Arial, jarak huruf, tombol bergradien, teks berpendar, latar radial |

Catatan: `GameMenuButton` diberi nama berbeda karena `MenuButton` sudah dipakai class bawaan Godot.

## Loop permainan

`GameLoop._physics_process` berjalan 60 Hz (sama dengan frame 60 FPS di versi web) dan mengirim ke fungsi yang sesuai:

```
if not State.in_game: return
if State.level == "dalang": DalangFlow.run_dalang()
else match State.game_state:
    "playing":   GameLoop.run_game()
    "hardIntro": HardIntro.run_hard_intro()
    "ending":    GameFlow.run_ending_animation()
```

Setiap `requestAnimationFrame(...)` di JS menjadi panggilan dari dispatcher ini. Timer berbasis frame tetap berupa hitungan frame; timer berbasis waktu nyata memakai `Util.now()`.

## Gambar

Logika tidak pernah menggambar langsung. Node `Arena` (`scripts/render/arena.gd`) menggambar ulang tiap frame:

1. `DrawGame.draw_bg(canvas)` — latar (dan adegan pembuka SULIT)
2. `Sprites.draw_all(canvas)` — semua karakter, dibaca dari `State` dan Dictionary entitas
3. `DrawGame.draw_fx(canvas)` — efek, teks cerita, partikel, gelombang Time Stop

`DrawGame.get_shake_offset()` menggeser `Arena` saat layar bergetar. Setiap fungsi gambar menerima `canvas: CanvasItem` sebagai parameter pertama.

### Versi foto

`PhotoKit` memuat foto dari `assets/photos/` (nama berkas di `Config.PHOTOS.files`, pola sama dengan `Config.AUDIO`). Pemanggilan gambar tidak berubah: `Arena` tetap memanggil `DrawGame.draw_bg`, `Sprites.draw_all`, `DrawGame.draw_fx`. Di dalamnya, tiap fungsi gambar bertanya `PhotoKit.has(kunci)`. Bila foto ada, foto digambar pada kotak desain yang sama dengan versi vektor (pose, rotasi, skala, dan denyut tetap). Bila foto belum ada, versi vektor dipakai seperti semula. Efek (ekor meteor, cincin, laser, partikel) dan HUD tetap vektor.

## Data

- Objek permainan (pemain, target, Killer, Gadfly, Archer, meteor, Lord Vindex, dll.) adalah **Dictionary** dengan kunci yang sama seperti objek JS, dalam snake_case (`hitVX` → `hit_vx`).
- `Set` JS menjadi Dictionary (kunci → `true`).
- Array typed JS menjadi `PackedFloat64Array` dan sejenisnya.

## UI

`GameUI.build(board)` membuat semua overlay game (HUD, layar akhir, tombol kontrol sentuh, panel Dalang) di dalam papan 800×600. `GameUI.build_stage(root, board)` memasang latar radial dan bingkai papan sesuai tema level. `GameUI.node("id")` mengembalikan node dengan ID HTML asli, sehingga logika yang mengubah `style.display`, `textContent`, dan sejenisnya cukup diganti menjadi `visible` dan `text`.

### Susunan layar
- `scenes/game/game.tscn`: `Game` (Control penuh) → `Board` (Panel 800×600 di tengah, `clip_contents`) → `Arena` (Node2D). Overlay UI juga berada di `Board`, sehingga koordinatnya sama dengan versi web.
- Basis kanvas (`project.godot`): 1200×900 (ukuran halaman web), `stretch/aspect = expand`. Pada jendela 1200×900, susunannya identik dengan web. Pada jendela lebih lebar, latar dan menu melebar, dan papan membesar mengikuti tinggi jendela.
- Overlay yang rata tengah memakai `GameUI.strip(parent, y, h)` (pita selebar papan berisi `CenterContainer`), bukan anchor + grow, karena posisi anchor yang dihitung saat UI dibangun bisa salah.
- Klik/pointer dari viewport dikonversi ke koordinat papan oleh `DalangFlow._board_pos` (dipakai untuk membidik laser).
- Tombol skill dock dibuat oleh `GameUI` dari `DalangConfig.DL_SKILLS`; `DalangFlow` memperbarui gayanya tiap frame lewat `GameUI.skin_skill`.

Navigasi antarhalaman memakai `Util.goto_page("menu" | "rules" | "game")`. Level dan mode penonton dikirim lewat `State.page_level` dan `State.spectator_mode` (pengganti `document.body.dataset`).
