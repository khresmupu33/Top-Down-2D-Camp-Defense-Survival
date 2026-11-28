extends Node
## Antarmuka game (pengganti DOM halaman mudah/normal/sulit.html + CSS game/*).
## Autoload: GameUI. build(root) membuat semua node UI pada ruang logis 800x600;
## node(id) mengembalikan node dengan id HTML aslinya.

const W := 800.0
const OUT_TOP := -46.0  # baris di atas arena (nyawa, MENU, audio)
const OUT_BOTTOM := 608.0  # dialog Vindex tepat di bawah arena
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
}

## Palet aktif (token warna --accent dst). Dibaca juga oleh GameMenuButton.
var pal: Dictionary = PALETTES["red"]
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
	if str(lv) == "hard":
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


## Lapisan tanpa clip di luar arena (diisi oleh game_root.gd sebelum build()).
var outer: Control = null


func _build_game_screen(root: Control) -> void:
	var gs := Control.new()
	gs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(root, gs)
	_full(gs)
	_put("gameScreen", gs)
	if outer != null:
		_put("outerGame", outer)

	_build_hud(gs)
	_build_top_buttons(gs)
	_build_overlays(gs)
	_build_subtitle_and_badge(gs)
	_build_mobile_controls(gs)
	# Tombol MENU + dialog konfirmasi (paling atas).
	GameMenuButton.build(gs)


# HUD: skor, status power, nyawa
func _build_hud(gs: Control) -> void:
	var hud := ctl(gs, 0, 0, W, 65)
	_put("hud", hud)
	var score_size := 23
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)
	row.position = Vector2(20, 15)
	_adopt(hud, row)
	_put("scoreText", row)
	var num_color = pal.accent
	lbl(row, "Poin : ", score_size, Color.WHITE)
	var num := lbl(row, "0", score_size, num_color)
	_put("scoreNumber", num)

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

	# nyawa (di luar arena, kiri atas bingkai)
	var lives := HBoxContainer.new()
	lives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives.add_theme_constant_override("separation", 8)
	lives.position = Vector2(4, OUT_TOP + 1)
	_adopt(outer if outer != null else gs, lives)
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
	var mute := make_button(outer if outer != null else gs, "🔊", "dark", 16, 9, 0)
	mute.position = Vector2(W - 44, OUT_TOP)
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

	var ro := lbl(gs, "BERSIAPLAH\n\nTekan tombol apapun", 31, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_full(ro)
	ro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ro.add_theme_constant_override("shadow_offset_x", 3)
	ro.add_theme_constant_override("shadow_offset_y", 3)
	_put("readyOverlay", ro)

	var sw := VBoxContainer.new()
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sw.add_theme_constant_override("separation", 8)
	_adopt(strip(gs, 0, H), sw)
	sw.visible = false
	var st := lbl(sw, "⚠ KILLER TERDETEKSI ⚠", 27, "#ff2222", true, HORIZONTAL_ALIGNMENT_CENTER)
	st.add_theme_color_override("font_outline_color", Color(pal.hot).darkened(0.1) * Color(1, 1, 1, 0.45))
	st.add_theme_constant_override("outline_size", 6)
	lbl(sw, "SESUTU SEDANG MUNCUL...", 13, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	var tw := sw.create_tween().set_loops()
	tw.tween_property(sw, "modulate:a", 0.35, 0.3)
	tw.tween_property(sw, "modulate:a", 1.0, 0.3)
	_put("spawnWarning", sw)


# Subtitle Lord Vindex
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
	sub.position = Vector2(40, OUT_BOTTOM)
	sub.size = Vector2(720, 56)
	sub.modulate = Color(1, 1, 1, 0)
	_adopt(outer if outer != null else gs, sub)
	_put("hardSubtitle", sub)


# Kontrol sentuh (data-key): panah kiri/kanan di kiri, atas/bawah di kanan
func _build_mobile_controls(gs: Control) -> void:
	var mc := Control.new()
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(gs, mc)
	_full(mc)
	_put("mobileControls", mc)
	mc.visible = DisplayServer.is_touchscreen_available()
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
	_spacer(vb, 12 if hard else 40)

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


## Tambahkan anak hanya jika belum punya parent (helper seperti lbl() sudah menambahkannya).
func _adopt(parent: Node, child: Node) -> void:
	if child.get_parent() == null:
		parent.add_child(child)


## Pita selebar papan di posisi y (tinggi h) berisi CenterContainer. Overlay di dalamnya rata tengah
## secara andal (menggantikan anchor + grow yang bisa salah posisi saat UI dibangun).
func strip(parent: Node, y: float, h: float) -> CenterContainer:
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(0, y)
	c.size = Vector2(W, h)
	_adopt(parent, c)
	return c
