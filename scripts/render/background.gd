extends Node
## Latar arena (dari render/background.js). Autoload: Background.
## Papan catur 40px + garis tipis + vignette ringan. Vignette dibuat sekali sebagai tekstur kecil.
## Bila foto peta tersedia (PhotoKit, kunci "map"), foto menggantikan papan catur; vignette tetap
## bisa dipakai di atasnya (Config.PHOTOS.vignette).

const CELL := 40
const VIG_W := 200
const VIG_H := 150

var _vignette_tex: ImageTexture = null


func _make_vignette() -> void:
	# Gradien radial: transparan di jari-jari 150, rgba(0,0,0,.45) di jari-jari 550 (dari pusat arena).
	var img := Image.create(VIG_W, VIG_H, false, Image.FORMAT_RGBA8)
	var sx: float = float(Config.WIDTH) / VIG_W
	var sy: float = float(Config.HEIGHT) / VIG_H
	for j in range(VIG_H):
		for i in range(VIG_W):
			var dx: float = (i + 0.5) * sx - Config.WIDTH / 2.0
			var dy: float = (j + 0.5) * sy - Config.HEIGHT / 2.0
			var d: float = sqrt(dx * dx + dy * dy)
			var a: float = 0.45 * clampf((d - 150.0) / 400.0, 0.0, 1.0)
			img.set_pixel(i, j, Color(0, 0, 0, a))
	_vignette_tex = ImageTexture.create_from_image(img)


func draw_game_background(canvas: CanvasItem) -> void:
	var w: int = Config.WIDTH
	var h: int = Config.HEIGHT
	# Versi foto: foto peta memenuhi arena 800x600.
	if PhotoKit.draw_fit(canvas, "map", Rect2(0, 0, w, h), "cover"):
		if Config.PHOTOS.vignette:
			_draw_vignette(canvas, w, h)
		return
	# Background hitam, lalu kotak-kotak besar (sel genap #101010, ganjil #171717).
	DrawKit.rect(canvas, 0, 0, w, h, Color("#101010"))
	var odd := Color("#171717")
	var cy := 0
	while cy < h:
		var cx := 0
		while cx < w:
			if ((cx / CELL) + (cy / CELL)) % 2 == 1:
				canvas.draw_rect(Rect2(cx, cy, CELL, CELL), odd)
			cx += CELL
		cy += CELL
	# Garis tipis (tiap garis dilukis dua kali oleh strokeRect tetangga -> lebih pekat di bagian dalam).
	var lc := Color(0x22 / 255.0, 0x22 / 255.0, 0x22 / 255.0, 0.75)
	var x := 0
	while x <= w:
		canvas.draw_line(Vector2(x, 0), Vector2(x, h), lc, 2.0)
		x += CELL
	var y := 0
	while y <= h:
		canvas.draw_line(Vector2(0, y), Vector2(w, y), lc, 2.0)
		y += CELL
	# Vignette ringan.
	_draw_vignette(canvas, w, h)


func _draw_vignette(canvas: CanvasItem, w: int, h: int) -> void:
	if _vignette_tex == null:
		_make_vignette()
	canvas.draw_texture_rect(_vignette_tex, Rect2(0, 0, w, h), false)
