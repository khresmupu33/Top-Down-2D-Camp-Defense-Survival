extends Node
## Menyusun satu frame permainan (dari render/draw-game.js). Autoload: DrawGame.
## Dipanggil Arena: draw_bg (latar) -> Sprites.draw_all (karakter) -> draw_fx (efek & teks).
## Getaran layar: get_shake_offset() dipanggil sekali per frame oleh Arena.
## (State.screen_shake dikurangi oleh logika game, bukan di sini, seperti di JS.)



## Latar. Saat hardIntro: adegan intro; saat ending: latar gelap + judul.
func draw_bg(canvas: CanvasItem) -> void:
	var gs = State.game_state
	if gs == "hardIntro":
		HardIntro.draw_hard_intro(canvas)
		return
	if gs == "ending":
		_draw_ending_backdrop(canvas)
		return
	Background.draw_game_background(canvas)


func _draw_ending_backdrop(canvas: CanvasItem) -> void:
	var w: float = Config.WIDTH
	var h: float = Config.HEIGHT
	if PhotoKit.draw_fit(canvas, "map_ending", Rect2(0, 0, w, h), "cover"):
		DrawKit.rect(canvas, 0, 0, w, h, Color(0, 0, 0, 0.45))  # peredam foto agar teks tetap terbaca
	else:
		DrawKit.rect(canvas, 0, 0, w, h, Color("#030305"))
	DrawKit.text_center(canvas, w / 2.0, h / 2.0 - 105.0, "LEVEL %d" % Config.MAX_LEVEL, 36, Color("#facc15"))
	DrawKit.text_center(canvas, w / 2.0, h / 2.0 - 65.0, "SEMUA KILLER DIHAPUS...", 25, Color("#ef4444"))


## Efek di atas karakter, urutan sama dengan drawGame JS.
func draw_fx(canvas: CanvasItem) -> void:
	var gs = State.game_state
	if gs == "hardIntro":
		return  # efek intro sudah digambar di draw_bg (HardIntro.draw_hard_intro)
	if gs == "ending":
		Effects.draw_particles(canvas)
		if GameFlow.ending_all_gone_text:
			DrawKit.text_center(canvas, Config.WIDTH / 2.0, Config.HEIGHT / 2.0 + 10.0, "SEMUA KILLER HANCUR", 22, Color("#22c55e"))
		return
	Effects.draw_meteor_effects(canvas)
	Effects.draw_archer_warning(canvas)
	Effects.draw_vindex_time_stop_wave(canvas)
	Effects.draw_vindex_laser(canvas)
	Effects.draw_vindex_barrage(canvas)
	Effects.draw_vindex_vortex(canvas)
	Effects.draw_hard25_sequence_overlay(canvas)
	Effects.draw_time_stop_wave(canvas)
	Effects.draw_story_message(canvas)
	Effects.draw_particles(canvas)


## Offset getaran layar (Stage.shake di JS). Dipanggil sekali per frame.
func get_shake_offset() -> Vector2:
	if State.in_game and State.game_state == "playing":
		GameAudio.tick()
	if State.screen_shake > 0:
		var shake: float = randf() * 4.0
		# randomInt(-shake, shake) dengan batas desimal, seperti JS
		var sx: float = floorf(randf() * (2.0 * shake + 1.0)) - shake
		var sy: float = floorf(randf() * (2.0 * shake + 1.0)) - shake
		return Vector2(sx, sy)
	return Vector2.ZERO
