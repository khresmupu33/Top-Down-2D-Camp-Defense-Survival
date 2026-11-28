extends Control
## Layar CARA MAIN (dari app/pages/cara-main.html + assets/css/pages/rules.css).
## Ikon pratinjau karakter digambar sederhana dengan warna dari CSS karakter.

# [jenis ikon, judul, isi, hard?]
const ITEMS := [
	["player", "PLAYER", "Kamu adalah kotak hijau. Gunakan tombol panah untuk bergerak.", false],
	["target", "TARGET", "Kotak putih = +1 poin.", false],
	["health", "NYAWA", "Icon + hijau = +1 nyawa. Maksimal 3.", false],
	["gadfly", "GADFLY", "Gadfly atas dan bawah bergerak horizontal mengikuti player. Gadfly kiri dan kanan bergerak vertikal mengikuti player.", false],
	["killer", "KILLER", "Killer memiliki loading sebelum mengejar. Saat loading mereka belum dapat menyerang.", false],
	["archer", "ARCHER", "Pada NORMAL dan SULIT, Archer membidik player dengan garis arah dan menembakkan panah. Benturan tubuh maupun panah dapat mengurangi nyawa.", false],
	["power", "POWER KILL", "Killer biasa dapat dibunuh ketika menyentuh player saat Power Kill aktif. Archer juga dapat dihancurkan. Mereka akan menghindar selama kekuatan aktif.", false],
	["timestop", "TIME STOP", "Ambil power khusus untuk menghentikan waktu selama 5 detik. Player tetap gesit, musuh dan panah melambat. Archer bisa dibunuh saat Time Stop.", false],
	["vindex", "LORD VINDEX", "Hanya muncul pada SULIT. Ia tidak dapat dibunuh dengan Power Kill maupun Time Stop. Saat Time Stop, insting menghindarnya menjadi jauh lebih cepat, tetapi serangannya tetap melambat.", true],
	["meteor", "METEOR", "Mulai sistem hujan meteor pada milestone tertentu. Pada SULIT, mulai poin 25 hujan meteor menjadi tidak berhenti sampai player mati.", false],
	["💀", "SULIT", "Awal permainan menampilkan Lord Vindex, 2 Killer, dan 2 Archer. Mereka menunggu sampai poin 5 sebelum bergerak. Pada poin 25 terjadi ledakan besar, lalu permainan berlanjut di arena yang sama dengan hujan meteor tanpa akhir dan Lord Vindex mulai bisa menghentikan waktu. Di atas poin 50 Vindex berdiri di tengah arena dan menembakkan 3 laser sebanyak 3 gelombang (garis peringatan 2 detik sebelum menembak). Pada poin 75 ke atas muncul Pusaran Ungu: menyala 4 detik, menghisap player, Killer, dan Archer (bukan Vindex), lalu meledak dan melempar semuanya menjauh. Siapa pun yang masuk lingkaran pusaran akan mati, termasuk player.", true],
	["🏆", "TRUE ENDING", "Capai 100 poin. Pada SULIT, Lord Vindex, Archer, dan Killer ikut jatuh dalam ending terakhir.", false],
	["⏸", "PAUSE & MENU", "Tekan P atau tombol PAUSE untuk jeda. Tombol MENU di pojok kanan atas membawamu kembali ke menu (ada konfirmasi dulu).", false],
]


## Ikon pratinjau 84x84 (gambar sederhana per jenis karakter).
class Preview extends Control:
	var kind := ""

	func _init(k: String = "") -> void:
		kind = k
		custom_minimum_size = Vector2(84, 84)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _rrect(r: Rect2, fill: Color, border: Color, bw: float, radius: int) -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = fill
		s.border_color = border
		s.set_border_width_all(int(bw))
		s.set_corner_radius_all(radius)
		draw_style_box(s, r)

	func _draw() -> void:
		var c := Vector2(42, 42)
		match kind:
			"player":
				_rrect(Rect2(22, 22, 40, 40), Color("22c55e"), Color("052e16"), 3, 7)
				draw_rect(Rect2(30, 34, 8, 8), Color("f0fdf4"))
				draw_rect(Rect2(46, 34, 8, 8), Color("f0fdf4"))
			"target":
				_rrect(Rect2(24, 24, 36, 36), Color("f3f4f6"), Color("d1d5db"), 3, 8)
			"health":
				draw_circle(c, 22, Color("22c55e"))
				draw_arc(c, 21, 0, TAU, 32, Color("bbf7d0"), 3.0)
				draw_rect(Rect2(36, 24, 12, 36), Color.WHITE)
				draw_rect(Rect2(24, 36, 36, 12), Color.WHITE)
			"gadfly":
				_rrect(Rect2(24, 26, 36, 32), Color("64748b"), Color("334155"), 3, 7)
				draw_rect(Rect2(31, 34, 8, 8), Color("f8fafc"))
				draw_rect(Rect2(45, 34, 8, 8), Color("f8fafc"))
			"killer":
				_rrect(Rect2(20, 14, 44, 56), Color("7a1620"), Color("210307"), 3, 6)
				draw_rect(Rect2(28, 32, 10, 8), Color("ff1111"))
				draw_rect(Rect2(46, 32, 10, 8), Color("ff1111"))
				draw_rect(Rect2(32, 52, 20, 5), Color("f8fafc"))
			"archer":
				_rrect(Rect2(22, 22, 40, 40), Color("ef4444"), Color("7e22ce"), 3, 8)
				draw_rect(Rect2(31, 36, 8, 8), Color("111827"))
				draw_rect(Rect2(45, 36, 8, 8), Color("111827"))
				draw_arc(Vector2(14, 42), 22, -PI / 3.0, PI / 3.0, 16, Color("facc15"), 2.5)
			"power":
				draw_circle(c, 22, Color("ef4444"))
				draw_arc(c, 21, 0, TAU, 32, Color("fca5a5"), 4.0)
				draw_string(ThemeDB.fallback_font, Vector2(33, 52), "P", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("facc15"))
			"timestop":
				draw_circle(c, 22, Color("1d4ed8"))
				draw_arc(c, 21, 0, TAU, 32, Color("93c5fd"), 4.0)
				draw_line(c, c + Vector2(0, -14), Color("e0f2fe"), 3.0)
				draw_line(c, c + Vector2(10, 4), Color("e0f2fe"), 3.0)
			"vindex":
				_rrect(Rect2(18, 14, 48, 56), Color("3b0764"), Color("7e22ce"), 4, 10)
				draw_rect(Rect2(28, 32, 10, 8), Color("fbbf24"))
				draw_rect(Rect2(46, 32, 10, 8), Color("fbbf24"))
			"meteor":
				draw_circle(Vector2(52, 52), 14, Color("fdba74"))
				draw_arc(Vector2(52, 52), 13, 0, TAU, 24, Color("ef4444"), 3.0)
				draw_line(Vector2(40, 40), Vector2(8, 8), Color("fbbf24", 0.6), 6.0)
			_:
				draw_string(ThemeDB.fallback_font, Vector2(0, 54), kind, HORIZONTAL_ALIGNMENT_CENTER, 84, 38, Color.WHITE)


const PANEL_W_MIN := 844.0    # web: .rules 900px dikurangi padding 28px kiri-kanan
var _panel: PanelContainer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# body halaman cara main = latar menu (menu.css)
	UiKit.radial_bg(self, Vector2(0.5, 0.45), [Color(0.498, 0.114, 0.114, 0.28), Color(0.498, 0.114, 0.114, 0.0)], [0.0, 0.4], Color("0b0d12"))

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.02, 0.02, 0.02, 0.88), Color("334155"), 1, 22, 60, Color(0, 0, 0, 0.45), 20, 30, 30))
	add_child(_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	_panel.add_child(outer)

	outer.add_child(UiKit.make_label("CARA MAIN", 48, Color("ff3333"), true, HORIZONTAL_ALIGNMENT_CENTER))
	outer.add_child(_spacer(24))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	for i in ITEMS.size():
		list.add_child(_make_item(ITEMS[i], i == ITEMS.size() - 1))

	outer.add_child(_spacer(18))
	var back := UiKit.menu_button("KEMBALI KE MENU", Color("334155"), Color("111827"), Color.WHITE, Color("64748b"), Color("475569"), Vector2(0, 54), 16, 1)
	back.pressed.connect(func(): Util.goto_page("menu"))
	outer.add_child(back)

	resized.connect(_layout)
	_layout()


## Panel di tengah: lebar 844 (seperti web), melebar sampai 1100 di layar lebar; tinggi 86% (max-height: 86vh).
func _layout() -> void:
	var w: float = clampf(size.x * 0.7, PANEL_W_MIN, 1100.0)
	var h: float = size.y * 0.86
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -w * 0.5
	_panel.offset_right = w * 0.5
	_panel.offset_top = -h * 0.5
	_panel.offset_bottom = h * 0.5


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _make_item(it: Array, last: bool) -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 15)
	pad.add_theme_constant_override("margin_bottom", 15)
	wrap.add_child(pad)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	pad.add_child(row)

	var icon := Preview.new(it[0])
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var title_color := "d8b4fe" if it[3] else "fca5a5"
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rt.add_theme_font_override("normal_font", UiKit.font(false))
	rt.add_theme_font_override("bold_font", UiKit.font(true))
	rt.add_theme_font_size_override("normal_font_size", 16)
	rt.add_theme_font_size_override("bold_font_size", 16)
	rt.add_theme_constant_override("line_separation", 5)
	rt.add_theme_color_override("default_color", Color("e5e7eb"))
	var title: String = str(it[1]).replace("[", "[lb]")
	rt.text = "[color=#%s][b]%s[/b][/color]\n%s" % [title_color, title, str(it[2]).replace("[", "[lb]")]
	row.add_child(rt)

	if not last:
		var sep := ColorRect.new()
		sep.custom_minimum_size = Vector2(0, 1)
		sep.color = Color(0.58, 0.64, 0.72, 0.14)
		wrap.add_child(sep)
	return wrap
