extends Node
## Pembantu gambar: pengganti pemanggilan ctx.* (canvas 2D) di JavaScript.
## Setiap fungsi menerima `canvas` = CanvasItem yang sedang menggambar,
## yaitu node yang sedang berada di dalam _draw() (mis. arena).


func rect(canvas: CanvasItem, x: float, y: float, w: float, h: float, color: Color) -> void:
	canvas.draw_rect(Rect2(x, y, w, h), color)


func rect_outline(canvas: CanvasItem, x: float, y: float, w: float, h: float, color: Color, width: float = 2.0) -> void:
	canvas.draw_rect(Rect2(x, y, w, h), color, false, width)


## Kotak membulat (isi saja).
func rounded_rect(canvas: CanvasItem, x: float, y: float, w: float, h: float, color: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	canvas.draw_style_box(sb, Rect2(x, y, w, h))


func circle(canvas: CanvasItem, cx: float, cy: float, r: float, color: Color) -> void:
	canvas.draw_circle(Vector2(cx, cy), r, color)


## Cincin (lingkaran berongga).
func ring(canvas: CanvasItem, cx: float, cy: float, r: float, width: float, color: Color) -> void:
	canvas.draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, color, width, true)


func line(canvas: CanvasItem, x1: float, y1: float, x2: float, y2: float, width: float, color: Color) -> void:
	canvas.draw_line(Vector2(x1, y1), Vector2(x2, y2), color, width, true)


func poly(canvas: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	canvas.draw_colored_polygon(points, color)


## Cahaya lembut: lingkaran-lingkaran bertumpuk, makin ke pusat makin terang.
func glow(canvas: CanvasItem, cx: float, cy: float, r: float, color: Color, layers: int = 4) -> void:
	for i in range(layers):
		var f: float = 1.0 - float(i) / float(layers)
		canvas.draw_circle(Vector2(cx, cy), r * f, Color(color.r, color.g, color.b, color.a / float(layers) * 1.6))


## Teks dengan titik acuan di tengah-kiri (mirip textBaseline 'middle').
func text(canvas: CanvasItem, x: float, y: float, s: String, size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(x, y + size * 0.35), s, align, width, size, color)


## Teks rata tengah di (x, y) dengan baseline 'middle'.
func text_center(canvas: CanvasItem, x: float, y: float, s: String, size: int, color: Color) -> void:
	text(canvas, x - 400.0, y, s, size, color, HORIZONTAL_ALIGNMENT_CENTER, 800.0)


## Ganti warna dengan alpha baru.
func alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0))


## Transformasi lokal (pengganti ctx.translate/rotate/scale). Panggil clear_transform() setelahnya.
func set_transform(canvas: CanvasItem, x: float, y: float, rot: float = 0.0, sx: float = 1.0, sy: float = 1.0) -> void:
	canvas.draw_set_transform(Vector2(x, y), rot, Vector2(sx, sy))


func clear_transform(canvas: CanvasItem) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
