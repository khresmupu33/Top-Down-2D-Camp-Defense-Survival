extends Control
## Akar scene game (pengganti game/main.js). Susunan: latar penuh jendela + papan 800x600 di tengah
## (Board, berisi Arena dan seluruh UI). Papan ikut membesar mengikuti tinggi jendela (rasio 4:3 tetap);
## sisa jendela diisi latar, jadi layar selalu memakai lebar yang tersedia.

@onready var board: Panel = $Board


func _ready() -> void:
	State.in_game = true
	GameUI.build(board)
	GameUI.build_stage(self, board)
	if State.page_level == "dalang":
		DalangFlow.dalang_start()
	elif State.page_level != null and State.page_level != "":
		GameFlow.start_game(State.page_level)
	else:
		GameFlow.show_menu()


func _exit_tree() -> void:
	State.in_game = false


func _process(_delta: float) -> void:
	if State.in_game:
		Hud.update_hud()
