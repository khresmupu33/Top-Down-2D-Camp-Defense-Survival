extends Node
## Urutan poin 25: kematian palsu -> transisi ke fase lanjutan.
## Port dari modes/hard/hard-sequence.js.


func _hide_item(item) -> void:
	if item != null:
		item.visible = false
		item.x = -100
		item.y = -100


func hide_hard25_collectibles() -> void:
	_hide_item(State.target)
	_hide_item(State.health)
	_hide_item(State.powerup)
	_hide_item(State.time_stop_powerup)


func trigger_hard25_sequence() -> void:
	if State.hard25_sequence_active or State.hard25_triggered:
		return
	State.hard25_triggered = true
	GameAudio.stop_music()
	State.hard25_sequence_active = true
	State.hard25_sequence_timer = 0
	State.hard25_sequence_phase = 0
	State.hard_meteor_permanent = true
	State.meteor_session_active = false
	State.meteors.clear()
	State.large_meteor = null
	State.large_meteor_warning = null
	State.large_meteor_pending = false
	hide_hard25_collectibles()
	State.screen_shake = 12
	State.story_message = 'LORD VINDEX: "Oh... terlalu besar. Aku salah mengukurnya."'
	State.story_message_timer = 180


## Tampilkan/sembunyikan tombol layar akhir (#endScreen .endButtons button).
func _set_end_buttons_visible(on: bool) -> void:
	var box = GameUI.node("endButtons")
	if box != null:
		for c in box.get_children():
			if c is CanvasItem:
				c.visible = on
	for id in ["restartButton", "menuButton", "endRestartButton", "endMenuButton"]:
		var b = GameUI.node(id)
		if b != null:
			b.visible = on


func update_hard25_sequence() -> void:
	State.hard25_sequence_timer += 1
	var t: int = State.hard25_sequence_timer
	# 0-10 detik: aftermath / jeda panjang setelah ledakan.
	if t < 600:
		State.hard25_sequence_phase = 0
	# 10-15 detik: dialog Vindex.
	elif t < 900:
		State.hard25_sequence_phase = 1
	# Setelah dialog: arena disiapkan ulang otomatis (tanpa pindah halaman).
	else:
		State.hard25_sequence_phase = 2
	if t >= 1080:
		finish_hard25_sequence()
		return
	if t == 150:
		State.lives = 0
		State.player_death_timer = 0
		Player.create_player_death_particles()
		State.screen_shake = 28
	if t == 205:
		var title = GameUI.node("endTitle")
		var msg = GameUI.node("hardDeathMessage")
		var fs = GameUI.node("finalScore")
		if fs != null:
			fs.text = "Poin : " + str(State.score)
		if title != null:
			title.text = "GAME OVER"
		if msg != null:
			msg.text = 'Lord Vindex: "..."'
			msg.visible = true
		_set_end_buttons_visible(false)
		GameFlow.show_only("endScreen")
	if t == 600:
		var msg2 = GameUI.node("hardDeathMessage")
		if msg2 != null:
			msg2.visible = false
		var ro = GameUI.node("readyOverlay")
		if ro != null:
			ro.visible = false
		GameFlow.show_only("gameScreen")
		State.lives = 3
		State.player_death_timer = 0
		State.player_death_max = 0
		State.hit_cooldown = 100
		State.global_freeze = 0
		State.player.x = 390
		State.player.y = 300
		if State.lord_vindex != null:
			State.lord_vindex.x = State.player.x + 150
			State.lord_vindex.y = State.player.y - 100
		State.hard25_dialogue_timer = 300
		State.story_message = 'LORD VINDEX: "OH TIDAK... AKU TERLALU KUAT."'
		State.story_message_timer = 300
		State.screen_shake = 16
	if t == 900:
		State.hard25_ready_for_input = true
		State.story_message = 'LORD VINDEX: "Ini yang membedakan diriku dengan yang lain, kesempatan."'
		State.story_message_timer = 260


## Urutan poin 25 selesai: arena disiapkan ulang di halaman yang sama (tanpa pindah halaman),
## skor tetap 25, nyawa penuh, lalu pemain bersiap. Mulai saat ini Vindex bisa memakai Time Stop.
func finish_hard25_sequence() -> void:
	if not State.hard25_sequence_active:
		return
	State.hard25_sequence_active = false
	State.hard25_ready_for_input = false
	GameFlow.reset_run_state()
	GameSetup.create_game_objects()
	# create_game_objects() memulai ulang penanda urutan; tandai bahwa urutan 25 sudah dijalani.
	State.hard25_triggered = true
	State.hard25_completed = true
	State.hard_meteor_permanent = true
	State.vindex_time_stop_cooldown = Util.random_int(180, 300)
	State.story_message = 'LORD VINDEX: "Ini yang membedakan diriku dengan yang lain, kesempatan."'
	State.story_message_timer = 220
	var msg = GameUI.node("hardDeathMessage")
	if msg != null:
		msg.visible = false
	_set_end_buttons_visible(true)
	State.game_state = "ready"
	GameFlow.show_only("gameScreen")
	var ro = GameUI.node("readyOverlay")
	if ro != null:
		ro.visible = true
	var pt = GameUI.node("pauseText")
	if pt != null:
		pt.visible = false
	Hud.update_hud()


func continue_after_hard25() -> void:
	if State.level != "hard" or not State.hard25_sequence_active or not State.hard25_ready_for_input:
		return
	finish_hard25_sequence()
