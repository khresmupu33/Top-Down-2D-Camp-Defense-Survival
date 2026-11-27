extends Node
## Antarmuka game (pengganti DOM halaman mudah/normal/sulit/santai/dalang.html + CSS game/*).
## Autoload: GameUI. build(root) membuat semua node UI pada ruang logis 800x600;
## node(id) mengembalikan node dengan id HTML aslinya.

const W := 800.0
const H := 600.0

const PALETTES := {
	"red": {
		"accent": "#ef4444", "accent_text": "#ef2222", "hot": "#ff0000", "title": "#ff3333",
		"glow": Color(1, 0, 0, 0.7), "soft": Color(1, 0, 0, 0.55),
		"btn_from": "#991b1b", "btn_to": "#450a0a", "btn_shadow": "#280303", "panel": "#160406",
		"bg": ["#020305", "#020305"], "bg_at": [0.0, 1.0],
		"frame": Color(0, 0, 0, 0), "frame_glow": Color(1, 0, 0, 0.12), "frame_size": 60,
	},
	"hard": {
		"accent": "#a855f7", "accent_text": "#c084fc", "hot": "#a855f7", "title": "#c084fc",
		"glow": Color(0.659, 0.333, 0.969, 0.7), "soft": Color(0.659, 0.333, 0.969, 0.55),
		"btn_from": "#581c87", "btn_to": "#2e1065", "btn_shadow": "#17052f", "panel": "#16051f",
		"bg": ["#18052b", "#050208", "#010102"], "bg_at": [0.0, 0.48, 1.0],
		"frame": Color(0.753, 0.518, 0.988, 0.22), "frame_glow": Color(0.659, 0.333, 0.969, 0.28), "frame_size": 35,
	},
	"santai": {
		"accent": "#34d399", "accent_text": "#6ee7b7", "hot": "#34d399", "title": "#6ee7b7",
		"glow": Color(0.204, 0.827, 0.6, 0.7), "soft": Color(0.204, 0.827, 0.6, 0.55),
		"btn_from": "#047857", "btn_to": "#022c22", "btn_shadow": "#01150f", "panel": "#04140f",
		"bg": ["#052e22", "#020a07", "#010302"], "bg_at": [0.0, 0.52, 1.0],
		"frame": Color(0.431, 0.906, 0.718, 0.2), "frame_glow": Color(0.204, 0.827, 0.6, 0.2), "frame_size": 35,
	},
	"dalang": {
		"accent": "#22d3ee", "accent_text": "#67e8f9", "hot": "#22d3ee", "title": "#67e8f9",
		"glow": Color(0.133, 0.827, 0.933, 0.7), "soft": Color(0.133, 0.827, 0.933, 0.55),
		"btn_from": "#0e7490", "btn_to": "#083344", "btn_shadow": "#04202b", "panel": "#04141a",
		"bg": ["#04202b", "#02060a", "#010203"], "bg_at": [0.0, 0.52, 1.0],
		"frame": Color(0.404, 0.91, 0.976, 0.2), "frame_glow": Color(0.133, 0.827, 0.933, 0.22), "frame_size": 35,
	},
}

## Palet aktif (token warna --accent dst). Dibaca juga oleh GameMenuButton.
var pal: Dictionary = PALETTES["red"]
var is_dalang := false
var _reg: Dictionary = {}
var _font_bold: Font = null
var _font_reg: Font = null
## Papan 800x600 (Board) tempat seluruh UI dan Arena berada.
var board: Control = null


## Node dengan id HTML asli (atau null).
func node(id: String):
	var n = _reg.get(id)
	if n != null and not is_instance_valid(n):
		return null
	return n


func _put(id: String, n: Node) -> Node:
	_reg[id] = n
	return n


# ── pembantu gaya ─────────────────────────────────────────────────────────
func _c(hex) -> Color:
	return hex if hex is Color else Color(hex)


func sbox(bg: Color, border = null, bw := 0, radius := 0, pad_h := 0, pad_v := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if border != null and bw > 0:
		s.border_color = _c(border)
		s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	s.anti_aliasing = true
	return s


func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Control polos (tidak menangkap mouse) pada rect x,y,w,h.
func ctl(parent: Node, x: float, y: float, w: float, h: float) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)
	_adopt(parent, c)
	return c


func _full(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Label berteks. shadow = bayangan kecil hitam (2px). glow > 0 = bayangan berpendar berwarna glow_color (text-shadow CSS).
func lbl(parent: Node, text: String, size: int, color, bold := true, align := HORIZONTAL_ALIGNMENT_LEFT, shadow := true, spacing := 0, glow_color := Color(0, 0, 0, 0), glow := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", _c(color))
	l.add_theme_font_override("font", UiKit.spaced_font(bold, spacing))
	if glow > 0:
		l.add_theme_color_override("font_shadow_color", glow_color)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)
		l.add_theme_constant_override("shadow_outline_size", glow)
	elif shadow:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("shadow_offset_x", 2)
		l.add_theme_constant_override("shadow_offset_y", 2)
	if parent != null:
		_adopt(parent, l)
	return l


## Teks kaya (BBCode) untuk briefing dalang.
func rich(parent: Node, bbcode: String, size: int, color, align := "left") -> RichTextLabel:
	var r := RichTextLabel.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", _c(color))
	r.add_theme_font_override("normal_font", _font_reg)
	r.add_theme_font_override("bold_font", _font_bold)
	r.text = "[%s]%s[/%s]" % [align, bbcode, align]
	_adopt(parent, r)
	return r


## Tombol bergaya CSS: kind = "red" | "dark" | "light". Gradien vertikal, bayangan bawah tegas, sudut membulat.
func make_button(parent: Node, text: String, kind := "light", size := 17, pad_v := 13, pad_h := 20, spacing := 0) -> Button:
	var top := Color("#f8fafc")
	var bottom := Color("#cbd5e1")
	var border := Color("#64748b")
	var shadow := Color("#475569")
	var fg := Color("#111827")
	match kind:
		"red":
			top = _c(pal.btn_from)
			bottom = _c(pal.btn_to)
			border = _c(pal.accent)
			shadow = _c(pal.btn_shadow)
			fg = Color.WHITE
		"dark":
			top = Color("#334155")
			bottom = Color("#111827")
			fg = Color.WHITE
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(b,
		UiKit.grad_box(top, bottom, border, shadow, 8, 4, 1.0, pad_h, pad_v),
		UiKit.grad_box(top, bottom, border, shadow, 8, 4, 1.08, pad_h, pad_v),
		UiKit.grad_box(top, bottom, border, shadow, 8, 2, 0.92, pad_h, pad_v),
		size, fg, true, spacing)
	if parent != null:
		_adopt(parent, b)
	return b


func _grad_tex(colors: Array, offsets: Array, radial: bool, from := Vector2(0.5, 0.5), to := Vector2(1, 1), w := 64, h := 64) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = w
	t.height = h
	t.fill = GradientTexture2D.FILL_RADIAL if radial else GradientTexture2D.FILL_LINEAR
	t.fill_from = from
	t.fill_to = to
	return t


func _tex_rect(parent: Node, tex: Texture2D) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(parent, t)
	return t


func _spacer(parent: Node, h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(parent, c)


# ── pembangunan UI ────────────────────────────────────────────────────────
func build(root: Control) -> void:
	_reg = {}
	board = root
	var lv = State.page_level
	is_dalang = str(lv) == "dalang"
	if is_dalang:
		pal = PALETTES["dalang"]
	elif State.spectator_mode:
		pal = PALETTES["santai"]
	elif str(lv) == "hard":
		pal = PALETTES["hard"]
	else:
		pal = PALETTES["red"]

	_font_reg = UiKit.font(false)
	_font_bold = UiKit.font(true)
	var th := Theme.new()
	th.default_font = _font_reg
	root.theme = th

	_build_game_screen(root)
	_build_end_screen(root)
	_build_true_ending(root)


## Latar halaman (radial, seperti body.game-page di CSS tema) di belakang papan + bingkai papan (#gameWrapper).
## Dipanggil setelah build(); frame = papan 800x600.
func build_stage(root: Control, frame: Control) -> void:
	var colors: Array = []
	for h in pal.bg:
		colors.append(_c(h))
	var bg := UiKit.radial_bg(root, Vector2(0.5, 0.3), colors, pal.bg_at, colors[colors.size() - 1])
	root.move_child(bg, 0)
	var bw := 1 if (pal.frame as Color).a > 0.0 else 0
	frame.add_theme_stylebox_override("panel", UiKit.box(Color("#050505"), pal.frame, bw, 0, pal.frame_size, pal.frame_glow, 0))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_game_screen(root: Control) -> void:
	var gs := Control.new()
	gs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(root, gs)
	_full(gs)
	_put("gameScreen", gs)

	if is_dalang:
		_build_dalang_hurt(gs)
	_build_hud(gs)
	if is_dalang:
		_build_dalang_hud(gs)
	_build_top_buttons(gs)
	_build_overlays(gs)
	_build_subtitle_and_badge(gs)
	if is_dalang:
		_build_dalang_dock(gs)
		_build_dalang_brief(gs)
	else:
		_build_mobile_controls(gs)
	# Tombol MENU + dialog konfirmasi (paling atas).
	GameMenuButton.build(gs)


# HUD: skor, status power, nyawa
func _build_hud(gs: Control) -> void:
	var hud := ctl(gs, 0, 0, W, 52 if is_dalang else 65)
	_put("hud", hud)
	var score_size := 19 if is_dalang else 23
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)
	row.position = Vector2(20, 15 if not is_dalang else 12)
	_adopt(hud, row)
	_put("scoreText", row)
	var num_color = "#67e8f9" if is_dalang else pal.accent
	lbl(row, "WAKTU : " if is_dalang else "Poin : ", score_size, Color.WHITE)
	var num := lbl(row, "0.0" if is_dalang else "0", score_size, num_color)
	_put("scoreNumber", num)
	if is_dalang:
		lbl(row, " dtk", score_size, Color.WHITE)

	# status power (kapsul emas di tengah atas)
	var ps := PanelContainer.new()
	ps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ps.add_theme_stylebox_override("panel", sbox(Color(20 / 255.0, 10 / 255.0, 0, 0.88), "#facc15", 1, 14, 11, 6))
	_adopt(strip(hud, 12, 36), ps)
	ps.visible = false
	var pr := HBoxContainer.new()
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pr.add_theme_constant_override("separation", 7)
	_adopt(ps, pr)
	lbl(pr, "⚡", 18, "#fde68a", true, HORIZONTAL_ALIGNMENT_LEFT, false)
	var pt := lbl(pr, "KILL", 13, "#fde68a", true, HORIZONTAL_ALIGNMENT_LEFT, false)
	_put("powerStatus", ps)
	_put("powerText", pt)

	# nyawa (dipindah di bawah baris tombol agar tidak tumpang tindih dengan PAUSE/MENU)
	var lives := HBoxContainer.new()
	lives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives.add_theme_constant_override("separation", 8)
	lives.position = Vector2(W - 20 - (32 * 3 + 16), 52)
	_adopt(gs, lives)
	_put("lives", lives)
	for i in 3:
		var life := Control.new()
		life.custom_minimum_size = Vector2(32, 32)
		life.mouse_filter = Control.MOUSE_FILTER_IGNORE
		life.set_meta("dead", false)
		life.draw.connect(_draw_life.bind(life))
		_adopt(lives, life)


func _draw_life(c: Control) -> void:
	var dead: bool = c.get_meta("dead", false)
	var ctr := Vector2(16, 16)
	if dead:
		c.draw_circle(ctr, 16, Color(0.067, 0.094, 0.153, 0.6))
		c.draw_circle(ctr, 11, Color(0.216, 0.255, 0.318, 0.6))
		c.draw_circle(ctr, 6, Color(0.216, 0.255, 0.318, 0.6))
	else:
		c.draw_circle(ctr, 19, Color(0.133, 0.773, 0.369, 0.18))
		c.draw_circle(ctr, 16, Color("#065f46"))
		c.draw_circle(ctr, 12, Color("#16a34a"))
		c.draw_circle(ctr, 7, Color("#4ade80"))
	var col := Color("#64748b") if dead else Color.WHITE
	c.draw_line(Vector2(9, 15), Vector2(23, 15), col, 3.5)
	c.draw_line(Vector2(16, 8), Vector2(16, 22), col, 3.5)


# Tombol PAUSE / bisu (kanan atas)
func _build_top_buttons(gs: Control) -> void:
	var mute := make_button(gs, "🔊", "dark", 16, 9, 0)
	mute.position = Vector2(W - 127 - 44, 12)
	mute.size = Vector2(44, 34)
	mute.pressed.connect(func(): GameAudio.toggle_mute())
	_put("muteButton", mute)

	var pause := make_button(gs, "⏸ PAUSE", "dark", 13, 9, 12)
	pause.position = Vector2(W - 12 - 105, 12)
	pause.size = Vector2(105, 34)
	pause.visible = false
	pause.pressed.connect(func(): GameFlow.toggle_pause())
	_put("pauseButton", pause)


# Overlay: pause, siap, peringatan killer
func _build_overlays(gs: Control) -> void:
	var pt := VBoxContainer.new()
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pt.add_theme_constant_override("separation", 0)
	_adopt(strip(gs, 90, 60), pt)
	pt.visible = false
	lbl(pt, "⏸ PAUSED", 29, "#facc15", true, HORIZONTAL_ALIGNMENT_CENTER)
	lbl(pt, "Tekan P atau PAUSE untuk lanjut", 14, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER, false)
	_put("pauseText", pt)

	var ro := lbl(gs, "" if is_dalang else "BERSIAPLAH\n\nTekan tombol apapun", 31, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_full(ro)
	ro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ro.add_theme_constant_override("shadow_offset_x", 3)
	ro.add_theme_constant_override("shadow_offset_y", 3)
	if is_dalang:
		ro.visible = false
	_put("readyOverlay", ro)

	var sw := VBoxContainer.new()
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sw.add_theme_constant_override("separation", 8)
	_adopt(strip(gs, 0, H), sw)
	sw.visible = false
	if not is_dalang:
		var st := lbl(sw, "⚠ KILLER TERDETEKSI ⚠", 27, "#ff2222", true, HORIZONTAL_ALIGNMENT_CENTER)
		st.add_theme_color_override("font_outline_color", Color(pal.hot).darkened(0.1) * Color(1, 1, 1, 0.45))
		st.add_theme_constant_override("outline_size", 6)
		lbl(sw, "SESUTU SEDANG MUNCUL...", 13, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		var tw := sw.create_tween().set_loops()
		tw.tween_property(sw, "modulate:a", 0.35, 0.3)
		tw.tween_property(sw, "modulate:a", 1.0, 0.3)
	_put("spawnWarning", sw)


# Subtitle Lord Vindex + lencana penonton
func _build_subtitle_and_badge(gs: Control) -> void:
	var sub := Label.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_font_override("font", _font_bold)
	sub.add_theme_color_override("font_color", Color("#f8fafc"))
	sub.add_theme_stylebox_override("normal", sbox(Color(8 / 255.0, 2 / 255.0, 16 / 255.0, 0.9), Color(0.659, 0.333, 0.969, 0.6), 1, 12, 14, 9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.position = Vector2(80, 548)
	sub.size = Vector2(640, 42)
	sub.modulate = Color(1, 1, 1, 0)
	_adopt(gs, sub)
	_put("hardSubtitle", sub)

	var badge := lbl(null, "👁 MODE PENONTON — BOT YANG BERMAIN", 12, "#e9d5ff", true, HORIZONTAL_ALIGNMENT_CENTER, false)
	badge.add_theme_stylebox_override("normal", sbox(Color(8 / 255.0, 2 / 255.0, 16 / 255.0, 0.8), Color(0.659, 0.333, 0.969, 0.5), 1, 12, 12, 4))
	_adopt(strip(gs, H - 34, 26), badge)
	badge.visible = State.spectator_mode
	_put("spectatorBadge", badge)


# Kontrol sentuh (data-key): panah kiri/kanan di kiri, atas/bawah di kanan
func _build_mobile_controls(gs: Control) -> void:
	var mc := Control.new()
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(gs, mc)
	_full(mc)
	_put("mobileControls", mc)
	mc.visible = DisplayServer.is_touchscreen_available() and not State.spectator_mode
	var gh := 58 * 2 + 12
	var y0 := H / 2.0 - gh / 2.0
	var defs := [
		["◀", "ArrowLeft", 8.0, y0],
		["▶", "ArrowRight", 8.0, y0 + 70],
		["▲", "ArrowUp", W - 8 - 58, y0],
		["▼", "ArrowDown", W - 8 - 58, y0 + 70],
	]
	for d in defs:
		var b := Button.new()
		b.text = d[0]
		b.focus_mode = Control.FOCUS_NONE
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		b.position = Vector2(d[2], d[3])
		b.size = Vector2(58, 58)
		b.add_theme_font_size_override("font_size", 25)
		b.add_theme_font_override("font", _font_bold)
		var bg := Color(15 / 255.0, 23 / 255.0, 42 / 255.0, 0.78)
		for st in ["normal", "hover", "pressed", "focus"]:
			var c := bg if st != "pressed" else Color(30 / 255.0, 41 / 255.0, 59 / 255.0, 0.95)
			b.add_theme_stylebox_override(st, sbox(c, Color(1, 1, 1, 0.18), 1, 15))
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(k, Color.WHITE)
		b.modulate = Color(1, 1, 1, 0.78)
		var key: String = d[1]
		b.button_down.connect(func():
			GameInput.control_down(key)
			GameInput.pointer_down())
		b.button_up.connect(func(): GameInput.control_up(key))
		_adopt(mc, b)


# ── layar akhir ───────────────────────────────────────────────────────────
func _end_bg(parent: Control) -> Control:
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_adopt(parent, bg)
	_full(bg)
	var tex := _grad_tex([Color("#1f2937"), Color("#050609"), Color.BLACK], [0.0, 0.65, 1.0], true, Vector2(0.5, 0.5), Vector2(1.0, 1.0), 128, 128)
	var tr := _tex_rect(bg, tex)
	_full(tr)
	return bg


func _build_end_screen(root: Control) -> void:
	var es := _end_bg(root)
	es.visible = false
	_put("endScreen", es)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	_adopt(es, vb)
	_full(vb)
	var hard := str(State.page_level) == "hard"

	var title := lbl(vb, "GAME OVER", 54, pal.accent, true, HORIZONTAL_ALIGNMENT_CENTER, false)
	title.add_theme_color_override("font_outline_color", Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.35))
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_stylebox_override("normal", sbox(Color(0, 0, 0, 0), null, 0, 0, 0, 0))
	_put("endTitle", title)
	_spacer(vb, 15)

	var score := lbl(vb, "Poin : 0", 32, Color.WHITE, false, HORIZONTAL_ALIGNMENT_CENTER, false)
	_put("finalScore", score)
	_spacer(vb, 12 if (hard or is_dalang) else 40)

	if is_dalang:
		var wrap := MarginContainer.new()
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_theme_constant_override("margin_bottom", 26)
		wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_adopt(vb, wrap)
		var rr := RichTextLabel.new()
		rr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rr.bbcode_enabled = true
		rr.fit_content = true
		rr.scroll_active = false
		rr.autowrap_mode = TextServer.AUTOWRAP_OFF
		rr.custom_minimum_size = Vector2(420, 0)
		rr.add_theme_font_size_override("normal_font_size", 15)
		rr.add_theme_font_size_override("bold_font_size", 15)
		rr.add_theme_font_override("normal_font", _font_reg)
		rr.add_theme_font_override("bold_font", _font_bold)
		rr.add_theme_color_override("default_color", Color("#cbd5e1"))
		rr.add_theme_stylebox_override("normal", sbox(Color(8 / 255.0, 47 / 255.0, 73 / 255.0, 0.35), Color(0.404, 0.91, 0.976, 0.35), 1, 14, 22, 12))
		rr.visible = false
		_adopt(wrap, rr)
		_put("dlResult", rr)

	var hwrap := MarginContainer.new()
	hwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hwrap.add_theme_constant_override("margin_bottom", 28 if hard else 0)
	hwrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_adopt(vb, hwrap)
	var msg := Label.new()
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.custom_minimum_size = Vector2(600, 0)
	msg.add_theme_font_size_override("font_size", 18)
	msg.add_theme_font_override("font", _font_reg)
	msg.add_theme_color_override("font_color", Color("#e9d5ff"))
	msg.add_theme_stylebox_override("normal", sbox(Color(59 / 255.0, 7 / 255.0, 100 / 255.0, 0.18), Color(0.659, 0.333, 0.969, 0.5), 1, 14, 20, 15))
	msg.visible = false
	_adopt(hwrap, msg)
	_put("hardDeathMessage", msg)

	var eb := VBoxContainer.new()
	eb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eb.custom_minimum_size = Vector2(250, 0)
	eb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	eb.add_theme_constant_override("separation", 12)
	_adopt(vb, eb)
	_put("endButtons", eb)
	var again := make_button(eb, "MAIN LAGI", "light")
	again.pressed.connect(func(): GameFlow.restart_game())
	_put("endRestartButton", again)
	var menu := make_button(eb, "MENU", "dark")
	menu.pressed.connect(func(): GameFlow.show_menu())
	_put("endMenuButton", menu)


func _build_true_ending(root: Control) -> void:
	var te := _end_bg(root)
	te.visible = false
	_put("trueEndingScreen", te)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	_adopt(te, vb)
	_full(vb)
	var cg := lbl(vb, "🎉 SELAMAT 🎉", 48, "#facc15", true, HORIZONTAL_ALIGNMENT_CENTER, false)
	cg.add_theme_color_override("font_outline_color", Color(0.98, 0.8, 0.08, 0.3))
	cg.add_theme_constant_override("outline_size", 8)
	_spacer(vb, 28)
	lbl(vb, "KAMU MENAKLUKKAN\nKILLER & GADFLY", 29, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER, false)
	_spacer(vb, 20)
	var te_l := lbl(vb, "TRUE ENDING", 22, "#67e8f9", false, HORIZONTAL_ALIGNMENT_CENTER, false)
	te_l.add_theme_font_override("font", _font_italic())
	_spacer(vb, 40)
	var bw := CenterContainer.new()
	bw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(vb, bw)
	var back := make_button(bw, "KEMBALI KE MENU", "light")
	back.pressed.connect(func(): GameFlow.show_menu())


func _font_italic() -> Font:
	return UiKit.font_italic()


# ── DALANG ────────────────────────────────────────────────────────────────
func _build_dalang_hurt(gs: Control) -> void:
	var hurt := Control.new()
	hurt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(gs, hurt)
	_full(hurt)
	hurt.modulate = Color(1, 1, 1, 0)
	hurt.draw.connect(func():
		for i in 22:
			var a := 0.75 * pow(1.0 - i / 22.0, 2.0)
			hurt.draw_rect(Rect2(i * 4 + 2, i * 4 + 2, W - i * 8 - 4, H - i * 8 - 4), Color(0.133, 0.827, 0.933, a), false, 4.0))
	_put("dlHurt", hurt)


func _pill(text: String, size: int, color, bg: Color, border, radius: int, pad_h: int, pad_v: int) -> Label:
	var l := lbl(null, text, size, color, true, HORIZONTAL_ALIGNMENT_CENTER, false)
	l.add_theme_stylebox_override("normal", sbox(bg, border, 1, radius, pad_h, pad_v))
	return l


func _build_dalang_hud(gs: Control) -> void:
	# bar energi
	var en := Panel.new()
	en.mouse_filter = Control.MOUSE_FILTER_IGNORE
	en.clip_contents = true
	en.add_theme_stylebox_override("panel", sbox(Color(2 / 255.0, 10 / 255.0, 16 / 255.0, 0.85), Color(0.404, 0.91, 0.976, 0.55), 1, 9))
	en.position = Vector2(250, 44)
	en.size = Vector2(300, 17)
	_adopt(gs, en)
	_put("dlEnergy", en)
	var fill := Panel.new()
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.add_theme_stylebox_override("panel", sbox(Color("#22d3ee"), null, 0, 8))
	fill.position = Vector2(0, 0)
	fill.size = Vector2(180, 17)
	_adopt(en, fill)
	_put("dlEnergyFill", fill)
	var et := lbl(en, "ENERGI 60 / 100", 10, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	et.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	et.add_theme_constant_override("shadow_offset_x", 0)
	et.add_theme_constant_override("shadow_offset_y", 1)
	_full(et)
	_put("dlEnergyText", et)

	# rekor waktu
	var best := _pill("REKOR —", 11, "#fde68a", Color(2 / 255.0, 10 / 255.0, 16 / 255.0, 0.85), Color(0.98, 0.8, 0.08, 0.55), 6, 8, 2)
	best.position = Vector2(20, 40)
	_adopt(gs, best)
	_put("dlBest", best)

	# chip BOT terkunci
	var fz := _pill("❄ BOT TERKUNCI", 12, "#ede9fe", Color(46 / 255.0, 16 / 255.0, 101 / 255.0, 0.85), "#c4b5fd", 14, 12, 4)
	_adopt(strip(gs, 68, 30), fz)
	fz.visible = false
	_put("dlFreezeChip", fz)

	# toast
	var ts := _pill("", 13, "#e0f2fe", Color(3 / 255.0, 14 / 255.0, 22 / 255.0, 0.92), Color(0.404, 0.91, 0.976, 0.55), 10, 14, 7)
	_adopt(strip(gs, H - 122, 30), ts)
	ts.visible = false
	_put("dlToast", ts)


func _build_dalang_dock(gs: Control) -> void:
	# latar gradien dock (CSS #dlDock)
	var bg := _tex_rect(gs, _grad_tex([Color(2 / 255.0, 8 / 255.0, 14 / 255.0, 0.0), Color(2 / 255.0, 8 / 255.0, 14 / 255.0, 0.55), Color(2 / 255.0, 8 / 255.0, 14 / 255.0, 0.94)], [0.0, 0.38, 1.0], false, Vector2(0, 0), Vector2(0, 1), 4, 64))
	bg.position = Vector2(0, H - 84)
	bg.size = Vector2(W, 84)
	# dock: enam tombol skill, urutan = tombol 1..6 (DalangConfig.DL_SKILLS)
	var dock := HBoxContainer.new()
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_theme_constant_override("separation", 6)
	dock.position = Vector2(8, H - 8 - 58)
	dock.size = Vector2(W - 16, 58)
	_adopt(gs, dock)
	_put("dlDock", dock)
	for sk in DalangConfig.DL_SKILLS:
		dock.add_child(_skill_tile(sk))

	# tombol putar arah laser (CSS #dlRotate)
	var rot := Button.new()
	rot.text = "↻ ARAH"
	rot.focus_mode = Control.FOCUS_NONE
	rot.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	UiKit.style_button(rot,
		UiKit.grad_box(Color("#0e7490"), Color("#083344"), Color("#67e8f9"), Color("#02080c"), 8, 3, 1.0, 12, 9),
		UiKit.grad_box(Color("#0e7490"), Color("#083344"), Color("#67e8f9"), Color("#02080c"), 8, 3, 1.1, 12, 9),
		null, 13, Color.WHITE, true, 0)
	rot.position = Vector2(W - 12 - 92, H - 84 - 36)
	rot.size = Vector2(92, 36)
	rot.visible = false
	_adopt(gs, rot)
	rot.button_down.connect(func():
		var d = DalangFlow.dl
		if d != null:
			d.laser_step = (d.laser_step + 1) % 12)
	_put("dlRotate", rot)


func _kv(parent: Node, head: String, body: String) -> void:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", sbox(Color(14 / 255.0, 116 / 255.0, 144 / 255.0, 0.18), Color(0.404, 0.91, 0.976, 0.25), 1, 9, 7, 6))
	_adopt(parent, p)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	_adopt(p, v)
	lbl(v, head, 11, "#a5f3fc", true, HORIZONTAL_ALIGNMENT_CENTER, false)
	var b := lbl(v, body, 10, "#e2e8f0", false, HORIZONTAL_ALIGNMENT_CENTER, false)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(150, 0)


func _build_dalang_brief(gs: Control) -> void:
	var brief := Panel.new()
	brief.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	brief.mouse_filter = Control.MOUSE_FILTER_STOP
	_adopt(gs, brief)
	_full(brief)
	_put("dlBrief", brief)
	var tex := _grad_tex([Color(5 / 255.0, 40 / 255.0, 54 / 255.0, 0.94), Color(1 / 255.0, 5 / 255.0, 9 / 255.0, 0.97)], [0.0, 0.7], true, Vector2(0.5, 0.4), Vector2(1.0, 1.0), 128, 128)
	_full(_tex_rect(brief, tex))
	brief.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			GameFlow.begin_play())

	var card := VBoxContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_constant_override("separation", 6)
	card.custom_minimum_size = Vector2(650, 0)
	_adopt(strip(brief, 0, H), card)

	lbl(card, "LEVEL KHUSUS", 10, "#94a3b8", false, HORIZONTAL_ALIGNMENT_CENTER, false, 6)
	_adopt(card, UiKit.glow_text("DALANG", 46, Color("#67e8f9"), true, 7, Color(0.133, 0.827, 0.933, 1.0), [[16, 0.10], [9, 0.20], [4, 0.30]]))
	rich(card, "Kali ini [b][color=#67e8f9]kamu[/color][/b] yang memberi tantangan. [b][color=#67e8f9]BOT-X[/color][/b] terus berkeliling & menghindar. Habiskan [b][color=#67e8f9]3 nyawanya[/color][/b] secepat mungkin — [b][color=#67e8f9]makin singkat waktunya, makin bagus rekormu.[/color][/b]", 14, "#e2e8f0", "center")

	var grid := GridContainer.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_adopt(card, grid)
	_kv(grid, "💀 KILLER", "mengejar setelah 2 dtk mengisi daya")
	_kv(grid, "🏹 ARCHER", "menembak panah dari jauh")
	_kv(grid, "☄️ HUJAN", "jalur meteor 300 px")
	_kv(grid, "🪨 METEOR BESAR", "2 nyawa bila telak")
	_kv(grid, "⚡ LASER", "sinar lurus 2 nyawa")
	_kv(grid, "⏳ TIME STOP", "BOT beku 3 dtk & berperisai")

	var gold := "[b][color=#fde68a]%s[/color][/b]"
	var rules := ""
	rules += "• " + (gold % "Energi terbatas") + " & tiap skill punya cooldown. Nyawa BOT yang berhasil kamu ambil mengisi energi lagi.\n"
	rules += "• BOT " + (gold % "pintar") + ": membaca semua bencana, mengambil " + (gold % "Power Kill") + " (Killer & Archer-mu mati) dan " + (gold % "Time Stop") + " (bencanamu melambat), lalu " + (gold % "belajar") + " dari serangan yang mengenainya.\n"
	rules += "• BOT " + (gold % "beradaptasi") + ": saat beku ia punya " + (gold % "Perisai Waktu") + " (menahan 2 poin serangan pertama) dan beku selama 3 detik. Setelah terluka atau lepas dari beku, ia " + (gold % "MENGAMUK") + " — lari 35% lebih cepat ±2 dtk.\n"
	rules += "• BOT bisa " + (gold % "menembus dinding") + ": keluar dari satu sisi arena, muncul di sisi seberang — Killer yang mengejar harus menyeberang seluruh arena. Jangan hanya menyudutkannya ke tepi.\n"
	rules += "• Tidak ada Inti & tidak ada batas waktu: " + (gold % "jam terus berjalan") + " sampai BOT tumbang. Jangan buang energi — kuncinya " + (gold % "kombo") + ": kurung BOT dengan Killer & hujan, lalu bekukan dia."
	rich(card, rules, 11, "#cbd5e1", "left")

	var kb := "[bgcolor=#0f2a36][color=#a5f3fc] %s [/color][/bgcolor]"
	rich(card, (kb % "1") + "–" + (kb % "6") + " pilih skill     [b][color=#e2e8f0]klik / tap[/color][/b] arena = pasang     Laser: [b][color=#e2e8f0]seret[/color][/b] arah, " + (kb % "R") + " / roda = putar     " + (kb % "Esc") + " batal · " + (kb % "P") + " jeda", 11, "#94a3b8", "center")

	var bw := CenterContainer.new()
	bw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(card, bw)
	var start := make_button(bw, "MULAI MENJADI DALANG", "red", 15, 12, 22, 1)
	start.pressed.connect(func(): GameFlow.begin_play())
	lbl(card, "atau ketuk layar / tekan tombol apa saja", 10, "#64748b", false, HORIZONTAL_ALIGNMENT_CENTER, false, 2)


## Tambahkan anak hanya jika belum punya parent (helper seperti lbl() sudah menambahkannya).
func _adopt(parent: Node, child: Node) -> void:
	if child.get_parent() == null:
		parent.add_child(child)


## Tile skill dock (CSS .dl-skill): nomor tombol, ikon, nama, biaya. Tekan = pilih skill (DalangSkills).
func _skill_tile(sk: Dictionary) -> Button:
	var b := Button.new()
	b.text = ""
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	b.custom_minimum_size = Vector2(0, 58)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.set_meta("skill", sk.id)
	b.set_meta("cd", 0.0)
	b.set_meta("is_sel", false)
	b.set_meta("is_ready", false)
	b.set_meta("is_low", false)
	var skill_id: String = sk.id
	b.button_down.connect(func(): DalangSkills.on_skill_pressed(skill_id))
	b.draw.connect(_skill_draw.bind(b))
	var key := lbl(null, str(sk.key), 9, "#67e8f9", true, HORIZONTAL_ALIGNMENT_LEFT, false)
	key.position = Vector2(5, 2)
	_adopt(b, key)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 1)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_adopt(b, col)
	lbl(col, str(sk.icon), 20, "#ffffff", true, HORIZONTAL_ALIGNMENT_CENTER, false)
	lbl(col, str(sk.label), 10, "#e0f2fe", true, HORIZONTAL_ALIGNMENT_CENTER, false)
	b.set_meta("cost_lbl", lbl(col, "%d⚡" % int(sk.cost), 10, "#67e8f9", true, HORIZONTAL_ALIGNMENT_CENTER, false))
	skin_skill(b)
	return b


## Gaya tile skill sesuai keadaan (CSS .is-sel / .is-ready / .is-low). Dipanggil tiap frame oleh DalangFlow.
func skin_skill(b: Button) -> void:
	var is_sel: bool = b.get_meta("is_sel", false)
	var is_ready: bool = b.get_meta("is_ready", false)
	var is_low: bool = b.get_meta("is_low", false)
	var top := Color("#123342")
	var bottom := Color("#08161f")
	var border := Color(0.404, 0.91, 0.976, 0.35)
	if is_sel:
		top = Color("#0e7490")
		bottom = Color("#083344")
		border = Color.WHITE
	elif is_ready:
		border = Color("#67e8f9")
	var shadow := Color("#02080c")
	var normal := UiKit.grad_box(top, bottom, border, shadow, 11, 3, 1.0, 2, 4)
	var hover := UiKit.grad_box(top, bottom, border, shadow, 11, 3, 1.15, 2, 4)
	for st in ["normal", "disabled", "focus", "pressed"]:
		b.add_theme_stylebox_override(st, normal)
	b.add_theme_stylebox_override("hover", hover)
	b.modulate.a = 0.62 if is_low else 1.0
	var cl = b.get_meta("cost_lbl", null)
	if cl is Label:
		cl.add_theme_color_override("font_color", Color("#f87171") if is_low else Color("#67e8f9"))
	b.queue_redraw()


## Overlay cooldown dari bawah (CSS ::after dengan scaleY(--cd)).
func _skill_draw(b: Button) -> void:
	var cd: float = clampf(float(b.get_meta("cd", 0.0)), 0.0, 1.0)
	if cd <= 0.0:
		return
	var sz: Vector2 = b.size
	b.draw_rect(Rect2(0, sz.y * (1.0 - cd), sz.x, sz.y * cd), Color(0, 0, 0, 0.66))


## Pita selebar papan di posisi y (tinggi h) berisi CenterContainer. Overlay di dalamnya rata tengah
## secara andal (menggantikan anchor + grow yang bisa salah posisi saat UI dibangun).
func strip(parent: Node, y: float, h: float) -> CenterContainer:
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(0, y)
	c.size = Vector2(W, h)
	_adopt(parent, c)
	return c
