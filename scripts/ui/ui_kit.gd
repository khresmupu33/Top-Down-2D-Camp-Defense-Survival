extends Node
## Pembantu UI bersama (autoload UiKit): meniru CSS web (font Arial/Helvetica, jarak huruf,
## bayangan teks, tombol bergradien dengan bayangan bawah tegas, latar radial).
## Kanvas UI memakai ukuran halaman web 1200x900; papan permainan 800x600 berada di tengahnya.

const BOARD_W := 800.0
const BOARD_H := 600.0
const CANVAS_W := 1200.0
const CANVAS_H := 900.0

var FONT_NAMES := PackedStringArray(["Arial", "Helvetica", "Liberation Sans", "Arimo", "DejaVu Sans", "sans-serif"])

## Jumlah baris gradien pada tekstur tombol (semakin banyak, semakin halus).
const GRAD_ROWS := 32

var _fonts: Dictionary = {}
var _tex: Dictionary = {}


## Font sans (Arial / Helvetica bila ada). bold = tebal (700), normal = 400.
func font(bold: bool = false) -> Font:
	var key: String = "b" if bold else "n"
	if not _fonts.has(key):
		var sf := SystemFont.new()
		sf.font_names = FONT_NAMES
		sf.font_weight = 700 if bold else 400
		_fonts[key] = sf
	return _fonts[key]


## Font miring (teks true ending).
func font_italic() -> Font:
	if not _fonts.has("i"):
		var sf := SystemFont.new()
		sf.font_names = FONT_NAMES
		sf.font_italic = true
		_fonts["i"] = sf
	return _fonts["i"]


## Font dengan jarak antar huruf (letter-spacing CSS) dalam piksel.
func spaced_font(bold: bool, spacing: int) -> Font:
	if spacing <= 0:
		return font(bold)
	var key: String = ("b" if bold else "n") + str(spacing)
	if not _fonts.has(key):
		var fv := FontVariation.new()
		fv.base_font = font(bold)
		fv.spacing_glyph = spacing
		_fonts[key] = fv
	return _fonts[key]


## Label siap pakai. spacing = letter-spacing (px). shadow_size > 0 = bayangan berpendar (text-shadow glow).
func make_label(text: String, size: int, color: Color, bold: bool = true, align: int = HORIZONTAL_ALIGNMENT_LEFT, spacing: int = 0, shadow_color: Color = Color(0, 0, 0, 0), shadow_size: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", spaced_font(bold, spacing))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if shadow_size > 0:
		l.add_theme_color_override("font_shadow_color", shadow_color)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)
		l.add_theme_constant_override("shadow_outline_size", shadow_size)
	return l


## StyleBox polos: isi, border, sudut membulat, bayangan (shadow = blur, shadow_offset_y = jarak ke bawah).
func box(bg: Color, border: Color = Color(0, 0, 0, 0), border_w: int = 0, radius: int = 0, shadow: int = 0, shadow_color: Color = Color(0, 0, 0, 0.5), shadow_offset_y: int = 0, pad_h: int = 0, pad_v: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_size = shadow
	sb.shadow_color = shadow_color
	sb.shadow_offset = Vector2(0, shadow_offset_y)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


## Terapkan gaya tombol (normal / hover / pressed) beserta font. Fokus dimatikan agar tidak ada kotak putih.
func style_button(btn: Button, normal: StyleBox, hover: StyleBox = null, pressed: StyleBox = null, font_size: int = 16, color: Color = Color.WHITE, bold: bool = true, spacing: int = 0) -> void:
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover if hover != null else normal)
	btn.add_theme_stylebox_override("pressed", pressed if pressed != null else normal)
	btn.add_theme_stylebox_override("disabled", normal)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_font_override("font", spaced_font(bold, spacing))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_color_override("font_pressed_color", color)
	btn.add_theme_color_override("font_focus_color", color)


## Kotak bergradien vertikal (CSS linear-gradient 180deg) + bayangan bawah tegas (box-shadow 0 dy 0) + sudut membulat.
## Dibuat sebagai tekstur 9-slice; bright = pengali kecerahan (CSS filter: brightness).
func grad_box(top: Color, bottom: Color, border: Color, shadow: Color, radius: int = 8, dy: int = 4, bright: float = 1.0, pad_h: int = 0, pad_v: int = 0, bw: int = 1) -> StyleBoxTexture:
	var key: String = "%s|%s|%s|%s|%d|%d|%.2f|%d" % [top.to_html(), bottom.to_html(), border.to_html(), shadow.to_html(), radius, dy, bright, bw]
	if not _tex.has(key):
		_tex[key] = _bake(_bright(top, bright), _bright(bottom, bright), _bright(border, bright), shadow, radius, dy, bw)
	var m: int = radius + 2
	var sb := StyleBoxTexture.new()
	sb.texture = _tex[key]
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m + dy
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


## Tombol bergaya CSS a.btn (menu & cara main): gradien, border, bayangan bawah, teks tebal berjarak.
func menu_button(text: String, top: Color, bottom: Color, fg: Color, border: Color, shadow: Color, min_size: Vector2, font_size: int = 16, spacing: int = 1) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	style_button(b,
		grad_box(top, bottom, border, shadow, 12, 4, 1.0, 20, 14),
		grad_box(top, bottom, border, shadow, 12, 4, 1.08, 20, 14),
		grad_box(top, bottom, border, shadow, 12, 2, 0.92, 20, 14),
		font_size, fg, true, spacing)
	return b


## Latar radial (CSS radial-gradient) di atas warna dasar, mengisi parent sepenuhnya.
## colors/offsets = titik henti gradien (Color & float); center = pusat dalam koordinat 0..1.
func radial_bg(parent: Node, center: Vector2, colors: Array, offsets: Array, base: Color) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_rect := ColorRect.new()
	base_rect.color = base
	base_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(base_rect)
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offsets)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = center
	tex.fill_to = center + Vector2(0.5, 0.0)
	tex.width = 256
	tex.height = 256
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tr)
	parent.add_child(root)
	return root


func _bright(c: Color, k: float) -> Color:
	if k == 1.0:
		return c
	return Color(minf(c.r * k, 1.0), minf(c.g * k, 1.0), minf(c.b * k, 1.0), c.a)


## Membuat gambar tombol. Baris tengah (GRAD_ROWS) adalah bagian yang diregangkan dan membawa gradien;
## baris atas/bawah dan sudut tetap. Bayangan bawah = dy baris di bawah badan tombol.
func _bake(top: Color, bottom: Color, border: Color, shadow: Color, r: int, dy: int, bw: int) -> ImageTexture:
	var m: int = r + 2
	var c: int = GRAD_ROWS
	var w: int = 2 * m + 4
	var bh: int = 2 * m + c
	var img := Image.create(w, bh + dy, false, Image.FORMAT_RGBA8)
	var hx: float = w * 0.5
	var hy: float = bh * 0.5
	for y in range(bh + dy):
		var t: float = 0.0
		if y >= m + c:
			t = 1.0
		elif y >= m:
			t = (float(y - m) + 0.5) / float(c)
		var fill: Color = top.lerp(bottom, t)
		for x in range(w):
			var px: float = x + 0.5 - hx
			var d_body: float = _sd_round(px, y + 0.5 - hy, hx, hy, r)
			var a_body: float = clampf(0.5 - d_body, 0.0, 1.0)
			var d_sh: float = _sd_round(px, y + 0.5 - dy - hy, hx, hy, r)
			var a_sh: float = clampf(0.5 - d_sh, 0.0, 1.0) * shadow.a
			var col: Color = border if d_body > -bw else fill
			var a_out: float = a_body + a_sh * (1.0 - a_body)
			if a_out <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var k: float = a_sh * (1.0 - a_body)
			img.set_pixel(x, y, Color(
				(col.r * a_body + shadow.r * k) / a_out,
				(col.g * a_body + shadow.g * k) / a_out,
				(col.b * a_body + shadow.b * k) / a_out,
				a_out))
	return ImageTexture.create_from_image(img)


## Teks berpendar (CSS text-shadow glow): lapis label transparan berbayangan (outline px, pengali alpha)
## di bawah teks utama. Mengembalikan Control seukuran teks (cocok di dalam VBox, rata tengah).
func glow_text(text: String, size: int, color: Color, bold: bool, spacing: int, glow_color: Color, layers: Array) -> Control:
	var sz: Vector2 = spaced_font(bold, spacing).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var root := Control.new()
	root.custom_minimum_size = Vector2(ceilf(sz.x), ceilf(sz.y))
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for layer in layers:
		var gc := Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * float(layer[1]))
		var g := make_label(text, size, Color(0, 0, 0, 0), bold, HORIZONTAL_ALIGNMENT_CENTER, spacing, gc, int(layer[0]))
		g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(g)
	var main := make_label(text, size, color, bold, HORIZONTAL_ALIGNMENT_CENTER, spacing)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(main)
	return root


## Jarak bertanda ke tepi kotak membulat (negatif = di dalam).
func _sd_round(x: float, y: float, hx: float, hy: float, r: float) -> float:
	var qx: float = absf(x) - (hx - r)
	var qy: float = absf(y) - (hy - r)
	var ox: float = maxf(qx, 0.0)
	var oy: float = maxf(qy, 0.0)
	return Vector2(ox, oy).length() + minf(maxf(qx, qy), 0.0) - r
