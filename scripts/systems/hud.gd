extends Node
## HUD: skor, nyawa, status power, tombol pause (port dari systems/hud.js). Autoload: Hud.


func update_hud() -> void:
	var sn = GameUI.node("scoreNumber")
	if sn != null:
		sn.text = str(State.score)
	# Nyawa: lingkaran hijau, abu-abu bila hilang.
	var lives = GameUI.node("lives")
	if lives != null:
		var idx := 0
		for life in lives.get_children():
			var dead: bool = idx >= State.lives
			if life.get_meta("dead", false) != dead:
				life.set_meta("dead", dead)
				life.queue_redraw()
			idx += 1
	var power_status = GameUI.node("powerStatus")
	var power_text = GameUI.node("powerText")
	if power_status != null and power_text != null:
		if State.power_active > 0:
			power_status.visible = true
			power_text.text = "KILL " + str(ceili(State.power_active / 60.0)) + "s"
		elif State.time_stop > 0:
			power_status.visible = true
			power_text.text = "TIME STOP " + str(ceili(State.time_stop / 60.0)) + "s"
		else:
			power_status.visible = false
	# Tombol pause hanya tampil saat gameplay aktif.
	var pause_button = GameUI.node("pauseButton")
	if pause_button != null:
		pause_button.visible = State.game_state == "playing" or State.paused
		pause_button.text = "▶ LANJUT" if State.paused else "⏸ PAUSE"
