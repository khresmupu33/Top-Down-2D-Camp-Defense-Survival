extends RefCounted
## Pembantu bentuk untuk Sprites: poligon bulat/ellipse, pemotongan setengah bidang,
## dan gradien linear (dipecah jadi pita poligon berwarna per-vertex).
## Hanya dipakai saat membangun cache (sekali), bukan tiap frame.


## Persegi membulat sebagai poligon (searah jarum jam, sumbu y ke bawah).
static func rr_pts(x: float, y: float, w: float, h: float, r: float, seg: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	r = minf(r, minf(w, h) / 2.0)
	if r <= 0.01:
		pts.append(Vector2(x, y))
		pts.append(Vector2(x + w, y))
		pts.append(Vector2(x + w, y + h))
		pts.append(Vector2(x, y + h))
		return pts
	var centers := [Vector2(x + w - r, y + r), Vector2(x + w - r, y + h - r), Vector2(x + r, y + h - r), Vector2(x + r, y + r)]
	var starts := [-PI / 2.0, 0.0, PI / 2.0, PI]
	for ci in range(4):
		for i in range(seg + 1):
			var a: float = starts[ci] + (PI / 2.0) * float(i) / float(seg)
			pts.append(centers[ci] + Vector2(cos(a), sin(a)) * r)
	return pts


static func ellipse_pts(cx: float, cy: float, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts


## Poligon dari daftar persen [x1, y1, x2, y2, ...] terhadap kotak (x, y, w, h).
static func pct_pts(x: float, y: float, w: float, h: float, pairs: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(0, pairs.size(), 2):
		pts.append(Vector2(x + w * float(pairs[i]) / 100.0, y + h * float(pairs[i + 1]) / 100.0))
	return pts


## Potong poligon: pertahankan titik dengan nx*x + ny*y >= c (Sutherland-Hodgman).
static func clip(pts: PackedVector2Array, nx: float, ny: float, c: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var da: float = a.x * nx + a.y * ny - c
		var db: float = b.x * nx + b.y * ny - c
		if da >= 0.0:
			out.append(a)
		if (da >= 0.0) != (db >= 0.0):
			out.append(a.lerp(b, da / (da - db)))
	# buang titik kembar berurutan
	var clean := PackedVector2Array()
	for p in out:
		if clean.is_empty() or clean[clean.size() - 1].distance_to(p) > 0.0001:
			clean.append(p)
	if clean.size() > 1 and clean[0].distance_to(clean[clean.size() - 1]) <= 0.0001:
		clean.remove_at(clean.size() - 1)
	return clean


## Warna gradien pada posisi t. stops = [[t, Color], ...] terurut.
static func color_at(stops: Array, t: float) -> Color:
	if t <= float(stops[0][0]):
		return stops[0][1]
	for i in range(stops.size() - 1):
		var t0: float = stops[i][0]
		var t1: float = stops[i + 1][0]
		if t <= t1:
			var f: float = 0.0 if t1 <= t0 else (t - t0) / (t1 - t0)
			return (stops[i][1] as Color).lerp(stops[i + 1][1], f)
	return stops[stops.size() - 1][1]


## Gradien linear CSS (sudut dalam derajat, 180 = ke bawah) pada kotak (bx, by, bw, bh),
## diterapkan pada poligon `pts`. Hasil: Array berisi [PackedVector2Array, PackedColorArray].
static func lin_layers(pts: PackedVector2Array, bx: float, by: float, bw: float, bh: float, angle_deg: float, stops: Array) -> Array:
	var a: float = deg_to_rad(angle_deg)
	var u := Vector2(sin(a), -cos(a))
	var ln: float = absf(bw * sin(a)) + absf(bh * cos(a))
	var center := Vector2(bx + bw / 2.0, by + bh / 2.0)
	var start: Vector2 = center - u * ln / 2.0
	var s0: float = start.dot(u)
	var layers := []
	if stops.size() == 2:
		layers.append([pts, _cols(pts, stops, s0, u, ln)])
		return layers
	for i in range(stops.size() - 1):
		var band := pts
		if i > 0:
			band = clip(band, u.x, u.y, s0 + float(stops[i][0]) * ln)
		if i < stops.size() - 2:
			band = clip(band, -u.x, -u.y, -(s0 + float(stops[i + 1][0]) * ln))
		if band.size() < 3:
			continue
		layers.append([band, _cols(band, stops, s0, u, ln)])
	return layers


static func _cols(pts: PackedVector2Array, stops: Array, s0: float, u: Vector2, ln: float) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		cols.append(color_at(stops, (p.dot(u) - s0) / ln))
	return cols
