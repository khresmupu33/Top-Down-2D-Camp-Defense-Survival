extends Node
## Tombol "MENU" saat bermain (semua level), port dari systems/menu-button.js. Autoload: GameMenuButton.
## Menjeda permainan lalu meminta konfirmasi, supaya progres tidak hilang karena salah tekan.
## Dibangun oleh GameUI.build() lewat GameMenuButton.build(layar_game).

const VISIBLE_STATES = ["ready", "hardIntro", "playing"]

var _button: Button = null
var _confirm: Control = null
var _stay: Button = null
var _leave: Button = null
var _paused_by_me := false
var _timer: Timer = null


func build(screen: Control) -> void:
	_paused_by_me = false
	_button = GameUI.make_button(screen, "☰ MENU", "dark", 13, 9, 0)
	_button.position = Vector2(800 - 183 - 92, 12)
	_button.size = Vector2(92, 34)
	_button.visible = false
	_button.pressed.connect(_open)
	GameUI._put("menuButton", _button)

	# Kotak konfirmasi: latar gelap menutup layar & menelan klik.
	var cf := ColorRect.new()
	cf.color = Color(0, 0, 0, 0.72)
	cf.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(cf)
	cf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cf.visible = false
	_confirm = cf
	GameUI._put("menuConfirm", cf)

	var card := PanelContainer.new()
	var st := GameUI.sbox(Color(GameUI.pal.panel), GameUI.pal.accent, 1, 14, 22, 20)
	st.shadow_color = GameUI.pal.soft
	st.shadow_size = 16
	card.add_theme_stylebox_override("panel", st)
	card.custom_minimum_size = Vector2(340, 0)
	GameUI.strip(cf, 0, GameUI.H).add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	card.add_child(vb)
	GameUI.lbl(vb, "Kembali ke menu?", 22, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER, false)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	vb.add_child(sp)
	var tx := GameUI.lbl(vb, "Permainan yang sedang berjalan akan hilang.", 14, Color(1, 1, 1, 0.85), false, HORIZONTAL_ALIGNMENT_CENTER, false)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 18)
	vb.add_child(sp2)
	var bb := VBoxContainer.new()
	bb.add_theme_constant_override("separation", 10)
	vb.add_child(bb)
	_leave = GameUI.make_button(bb, "KE MENU", "red", 15, 11, 14)
	_leave.pressed.connect(func(): GameFlow.show_menu())
	_stay = GameUI.make_button(bb, "LANJUT MAIN", "dark", 15, 11, 14)
	_stay.pressed.connect(_close)
	_leave.focus_mode = Control.FOCUS_ALL
	_stay.focus_mode = Control.FOCUS_ALL

	# Saat konfirmasi terbuka, tombol keyboard tidak boleh sampai ke game (mis. memulai permainan).
	var gate := GDScript.new()
	gate.source_code = "extends Node\nvar cb: Callable\nfunc _input(e):\n\tif cb.is_valid():\n\t\tcb.call(e)\n"
	gate.reload()
	var gn := Node.new()
	gn.set_script(gate)
	gn.set("cb", Callable(self, "_gate_input"))
	cf.add_child(gn)

	# Tampil hanya selama permainan berlangsung (layar game over / ending punya tombol MENU sendiri).
	if _timer == null:
		_timer = Timer.new()
		_timer.wait_time = 0.12
		_timer.one_shot = false
		_timer.timeout.connect(_sync_visibility)
		add_child(_timer)
		_timer.start()


func _alive() -> bool:
	return _button != null and is_instance_valid(_button) and _confirm != null and is_instance_valid(_confirm)


func _sync_visibility() -> void:
	if not _alive():
		return
	var show_it: bool = VISIBLE_STATES.has(State.game_state)
	if _button.visible != show_it:
		_button.visible = show_it


func _open() -> void:
	if not _alive() or _confirm.visible:
		return
	_paused_by_me = false
	if State.game_state == "playing" and not State.paused:
		GameFlow.toggle_pause()
		_paused_by_me = true
	_confirm.visible = true
	_stay.grab_focus()


func _close() -> void:
	if not _alive():
		return
	_confirm.visible = false
	if _paused_by_me and State.game_state == "playing" and State.paused:
		GameFlow.toggle_pause()
	_paused_by_me = false


func _gate_input(event: InputEvent) -> void:
	if not _alive() or not _confirm.visible:
		return
	if not (event is InputEventKey):
		return
	var viewport := _confirm.get_viewport()
	if event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_close()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				var f = viewport.gui_get_focus_owner()
				if f is BaseButton:
					f.pressed.emit()
			KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT:
				var f2 = viewport.gui_get_focus_owner()
				if f2 == _stay:
					_leave.grab_focus()
				else:
					_stay.grab_focus()
	viewport.set_input_as_handled()
