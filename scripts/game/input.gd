extends Node
## Input: keyboard (panah/WASD/P/M/F11), tombol layar sentuh, dan ketuk layar (dari game/input.js). Autoload: GameInput.

## Tombol yang tidak dihitung sebagai "tekan tombol apa saja".
const IGNORED_START_KEYS = ["Shift", "Control", "Alt", "Meta", "CapsLock", "Tab", "Escape", "F5", "F11", "F12"]
const WASD_MAP = {"w": "ArrowUp", "a": "ArrowLeft", "s": "ArrowDown", "d": "ArrowRight"}


## Nama tombol gaya JS (event.key) dari event Godot.
func _raw_key(event: InputEventKey) -> String:
	match event.keycode:
		KEY_UP: return "ArrowUp"
		KEY_DOWN: return "ArrowDown"
		KEY_LEFT: return "ArrowLeft"
		KEY_RIGHT: return "ArrowRight"
		KEY_SPACE: return " "
		KEY_SHIFT: return "Shift"
		KEY_CTRL: return "Control"
		KEY_ALT: return "Alt"
		KEY_META: return "Meta"
		KEY_CAPSLOCK: return "CapsLock"
		KEY_TAB: return "Tab"
		KEY_ESCAPE: return "Escape"
		KEY_F5: return "F5"
		KEY_F11: return "F11"
		KEY_F12: return "F12"
		KEY_ENTER, KEY_KP_ENTER: return "Enter"
	if event.unicode > 0:
		return char(event.unicode)
	return OS.get_keycode_string(event.keycode)


func _map_key(raw_key: String) -> String:
	var low := raw_key.to_lower()
	return WASD_MAP.get(low, raw_key)


func _input(event: InputEvent) -> void:
	if not State.in_game:
		return
	if not (event is InputEventKey):
		return
	var raw_key := _raw_key(event)
	if not event.pressed:
		# keyup
		State.pressed_keys.erase(_map_key(raw_key))
		return
	if event.echo:
		return
	# F11 = layar penuh
	if raw_key == "F11":
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	# M = bisukan / bunyikan suara.
	if raw_key.to_lower() == "m":
		GameAudio.toggle_mute()
		return
	var key := _map_key(raw_key)
	# Adegan pembuka SULIT: tombol APA SAJA (selain tombol pengubah) memulai permainan.
	if State.level == "hard" and State.game_state == "hardIntro":
		if State.hard_intro_ready and not IGNORED_START_KEYS.has(raw_key):
			get_viewport().set_input_as_handled()
			GameFlow.begin_play()
		return
	if State.level == "hard" and State.hard25_ready_for_input:
		get_viewport().set_input_as_handled()
		HardSequence.continue_after_hard25()
		return
	if ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", " "].has(key):
		get_viewport().set_input_as_handled()
	# P = PAUSE
	if key.to_lower() == "p":
		if State.game_state == "ready":
			GameFlow.begin_play()
			return
		if State.game_state == "playing":
			GameFlow.toggle_pause()
			return
	# READY.
	if State.game_state == "ready":
		GameFlow.begin_play()
		return
	# PLAY.
	if State.game_state == "playing" and not State.paused:
		State.pressed_keys[key] = true


## Ketuk / klik layar yang tidak ditangani kontrol lain = "tekan tombol apa saja".
func _unhandled_input(event: InputEvent) -> void:
	if not State.in_game:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		pointer_down()


## Tombol layar sentuh/klik ditekan.
func control_down(key: String) -> void:
	if State.level == "hard" and State.hard25_ready_for_input:
		HardSequence.continue_after_hard25()
		return
	if State.game_state == "ready" or State.game_state == "hardIntro":
		GameFlow.begin_play()
	if State.game_state == "playing" and not State.paused:
		State.pressed_keys[key] = true


func control_up(key: String) -> void:
	State.pressed_keys.erase(key)


## Ketuk/klik = "tekan tombol apa saja": intro SULIT, layar BERSIAPLAH lanjut setelah poin 25.
func pointer_down() -> void:
	if State.level == "hard" and State.game_state == "hardIntro" and State.hard_intro_ready:
		GameFlow.begin_play()
	elif State.level == "hard" and State.hard25_ready_for_input:
		HardSequence.continue_after_hard25()
	elif State.game_state == "ready":
		GameFlow.begin_play()
