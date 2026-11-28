extends Control
## Layar menu utama (port app/pages/menu.html + assets/css/pages/menu.css).
## Ukuran dan jarak mengikuti CSS web pada kanvas 1200x900. Kolom tetap di tengah; latar mengisi seluruh jendela.
## Tombol mode mengisi State.page_level lalu pindah ke scene game.

const COL_TITLE := Color("ef2222")

# [teks, level, (tidak dipakai), gaya]
const MODES := [
	["MUDAH", "easy", false, ""],
	["NORMAL", "normal", false, ""],
	["SULIT", "hard", false, "hard"],
]

# gaya -> [isi atas, isi bawah, warna teks, border, bayangan]  (CSS a.btn + modifier)
const STYLES := {
	"": [Color("f8fafc"), Color("cbd5e1"), Color("111827"), Color("64748b"), Color("475569")],
	"hard": [Color("991b1b"), Color("450a0a"), Color("ffffff"), Color("ef4444"), Color("280303")],
	"info": [Color("334155"), Color("111827"), Color("ffffff"), Color("64748b"), Color("475569")],
	"back": [Color("1e293b"), Color("0f172a"), Color("e2e8f0"), Color("475569"), Color("020617")],
}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# body.menu: radial merah lembut di tengah di atas latar gelap
	UiKit.radial_bg(self, Vector2(0.5, 0.45), [Color(0.498, 0.114, 0.114, 0.28), Color(0.498, 0.114, 0.114, 0.0)], [0.0, 0.4], Color("0b0d12"))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	center.add_child(col)

	col.add_child(UiKit.make_label("ULTIMATE HORROR MODE", 12, Color("94a3b8"), false, HORIZONTAL_ALIGNMENT_CENTER, 7))
	col.add_child(_spacer(14))
	col.add_child(UiKit.glow_text("KILLER & GADFLY", 78, COL_TITLE, true, 5, Color(1, 0, 0, 1.0), [[24, 0.10], [14, 0.18], [7, 0.30]]))
	col.add_child(_spacer(12))
	col.add_child(UiKit.make_label("CHOOSE YOUR FATE", 13, Color("cbd5e1"), false, HORIZONTAL_ALIGNMENT_CENTER, 6))
	col.add_child(_spacer(36))
	col.add_child(_line())
	col.add_child(_spacer(35))

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)

	for m in MODES:
		var b := _make_button(m[0], m[3])
		b.pressed.connect(_start_mode.bind(m[1]))
		buttons.add_child(b)
	var rules := _make_button("CARA MAIN", "info")
	rules.pressed.connect(func(): Util.goto_page("rules"))
	buttons.add_child(rules)
	# Tombol KEMBALI di web kembali ke landing page; di Godot = keluar dari game.
	var back := _make_button("↩ KEMBALI", "back")
	back.pressed.connect(func(): get_tree().quit())
	buttons.add_child(back)

	col.add_child(_spacer(32))
	col.add_child(UiKit.make_label("800 × 600 • DESKTOP & MOBILE LANDSCAPE", 12, Color("64748b"), false, HORIZONTAL_ALIGNMENT_CENTER, 2))


func _start_mode(level: String) -> void:
	State.page_level = level
	Util.goto_page("game")


func _make_button(text: String, kind: String) -> Button:
	var st: Array = STYLES[kind]
	return UiKit.menu_button(text, st[0], st[1], st[2], st[3], st[4], Vector2(330, 54), 16, 1)


## Garis merah tipis (linear-gradient transparan → merah → transparan), lebar 520.
func _line() -> Control:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.267, 0.267, 0.0), Color("ef4444"), Color(1, 0.267, 0.267, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 520
	tex.height = 1
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(520, 1)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
