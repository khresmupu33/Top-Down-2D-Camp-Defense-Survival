extends SceneTree
## Uji asap runtime: memainkan tiap level dengan input acak (jalankan: godot --headless --path . --script res://tests/smoke_test.gd): memainkan tiap level dengan input acak.
## Autoload diambil dinamis lewat /root/<Nama> karena skrip ini di luar proyek.
var runs := [["easy", false], ["normal", false], ["hard", false]]
var idx := 0
var frames := 0
var phase := 0
var keys := ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"]
var st
var gf

func _process(_delta: float) -> bool:
	if st == null:
		st = root.get_node("State")
		gf = root.get_node("GameFlow")
	frames += 1
	if phase == 0:
		var r = runs[idx]
		st.page_level = r[0]
		print("== RUN ", idx, " level=", r[0])
		change_scene_to_file("res://scenes/game/game.tscn")
		phase = 1
		frames = 0
		return false
	if phase == 1:
		if frames > 5:
			phase = 2
			frames = 0
		return false
	if phase == 2:
		if frames == 3 and st.game_state != "playing":
			gf.begin_play()
		if st.game_state == "hardIntro" and frames % 60 == 0:
			gf.begin_play()
		if frames % 25 == 0 and true:
			st.pressed_keys.clear()
			for k in keys:
				if randf() < 0.4:
					st.pressed_keys[k] = true
		if frames == 900 and st.level == "hard":
			st.score = 26
		if frames == 1400 and st.level == "hard":
			st.score = 55
		if frames == 1900 and st.level == "hard":
			st.score = 80
		if frames == 2400 and st.level == "normal":
			st.score = 12
		if frames > 2600:
			print("   END game_state=", st.game_state, " level=", st.level, " score=", st.score, " lives=", st.lives)
			idx += 1
			phase = 0
			if idx >= runs.size():
				print("SMOKE DONE")
				quit(0)
				return true
	return false
