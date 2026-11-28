extends Control
## Akar scene game (pengganti game/main.js). Susunan: latar penuh jendela + papan 800x600 di tengah
## (Board, berisi Arena dan seluruh UI). Papan ikut membesar mengikuti tinggi jendela (rasio 4:3 tetap);
## sisa jendela diisi latar, jadi layar selalu memakai lebar yang tersedia.

@onready var board: Panel = $Board


func _ready() -> void:
	State.in_game = true
	# Lapisan di luar arena: ukuran & posisi sama dengan Board, tetapi tidak dipotong (clip) sehingga
	# nyawa, tombol MENU/audio, dan dialog Vindex bisa digambar di luar bingkai arena.
	var outer := Control.new()
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.set_anchors_preset(Control.PRESET_CENTER)
	outer.offset_left = -400.0
	outer.offset_top = -300.0
	outer.offset_right = 400.0
	outer.offset_bottom = 300.0
	outer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	outer.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(outer)
	GameUI.outer = outer
	GameUI.build(board)
	GameUI.build_stage(self, board)
	if State.page_level != null and State.page_level != "":
		GameFlow.start_game(State.page_level)
	else:
		GameFlow.show_menu()


func _exit_tree() -> void:
	State.in_game = false


func _process(_delta: float) -> void:
	if State.in_game:
		Hud.update_hud()
