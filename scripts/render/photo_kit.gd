extends Node
## Pemuat & penggambar foto untuk peta dan entitas. Autoload: PhotoKit.
## Pola sama dengan GameAudio._get_stream: nama file diambil dari Config.PHOTOS.files, file yang
## belum ada/rusak -> null (diam-diam), dan pemanggil (Sprites, Background, DrawGame, HardIntro)
## jatuh kembali ke gambar vektor bawaan. Jadi foto boleh dipasang satu per satu.
##
## Semua foto dimuat sekali di _ready() (lengkap dengan mipmap supaya foto besar tetap halus
## saat diperkecil ke ukuran karakter 22-44 px), bukan saat pertama digambar, agar tidak ada
## patah-patah di tengah permainan.
##
## Cara pakai dari kode gambar:
##   if PhotoKit.has("player"):
##       PhotoKit.draw_fit(canvas, "player", Rect2(0, 0, 96, 96))
##   # atau langsung: if PhotoKit.draw_fit(...): return

const MAX_SIDE := 2048  # foto yang lebih besar diperkecil saat dimuat (hemat memori)

var _tex := {}  # kunci -> Texture2D (atau null bila tidak ada)


func _ready() -> void:
	reload()


## Muat ulang semua foto dari Config.PHOTOS.files (berguna setelah mengganti file saat game jalan).
func reload() -> void:
	_tex.clear()
	var missing: Array = []
	var total := 0
	for key in Config.PHOTOS.files.keys():
		total += 1
		var t: Texture2D = _load(str(key))
		_tex[str(key)] = t
		if t == null:
			missing.append(str(key))
	if OS.is_debug_build():
		print("[PhotoKit] %d/%d foto dimuat dari %s" % [total - missing.size(), total, Config.PHOTOS.base_path])
		if missing.size() > 0 and missing.size() < total:
			print("[PhotoKit] belum ada (pakai gambar vektor): ", ", ".join(missing))


## Memuat satu foto; file hilang/rusak -> null.
func _load(key: String) -> Texture2D:
	var file = Config.PHOTOS.files.get(key)
	if file == null or str(file) == "":
		return null
	var path: String = Config.PHOTOS.base_path + str(file)
	var img: Image = null
	if ResourceLoader.exists(path):
		# sudah diimpor editor Godot (jalur normal, juga untuk hasil export)
		var res = ResourceLoader.load(path)
		if res is Texture2D:
			img = res.get_image()
	elif FileAccess.file_exists(path):
		# baru ditaruh dan belum diimpor: baca langsung dari disk
		img = Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var longest: int = maxi(img.get_width(), img.get_height())
	if longest > MAX_SIDE:
		var k: float = float(MAX_SIDE) / float(longest)
		img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## True bila foto dengan kunci ini tersedia dan foto sedang diaktifkan.
func has(key: String) -> bool:
	return get_tex(key) != null


func get_tex(key: String) -> Texture2D:
	if not Config.PHOTOS.enabled:
		return null
	var t = _tex.get(key)
	return t as Texture2D


## Menggambar foto ke dalam kotak `box` (pada sistem koordinat canvas saat ini).
## mode "contain": utuh, proporsi dijaga, di tengah kotak (entitas).
## mode "cover":   memenuhi kotak, bagian lebih dipotong dari tengah (peta).
## Mengembalikan false bila foto tidak tersedia, sehingga pemanggil bisa menggambar versi vektor.
func draw_fit(canvas: CanvasItem, key: String, box: Rect2, mode: String = "contain", modulate: Color = Color.WHITE) -> bool:
	var t: Texture2D = get_tex(key)
	if t == null:
		return false
	var ts: Vector2 = t.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return false
	# foto diperkecil jauh -> pakai filter linear + mipmap (bawaan proyek: nearest)
	if canvas.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
		canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if mode == "cover":
		var kc: float = maxf(box.size.x / ts.x, box.size.y / ts.y)
		var src_size: Vector2 = box.size / kc
		var src := Rect2((ts - src_size) * 0.5, src_size)
		canvas.draw_texture_rect_region(t, box, src, modulate)
	else:
		var kf: float = minf(box.size.x / ts.x, box.size.y / ts.y)
		var sz: Vector2 = ts * kf
		canvas.draw_texture_rect(t, Rect2(box.position + (box.size - sz) * 0.5, sz), false, modulate)
	return true
