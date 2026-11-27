extends Node2D
## Kanvas arena 800×600. Urutan gambar sama dengan 3 lapis canvas di versi JS:
## latar (gameCanvas) -> karakter (spriteLayer) -> efek (fxCanvas).
## Digambar ulang tiap frame; posisinya bergeser saat layar bergetar (screen shake).


func _process(_delta: float) -> void:
	position = DrawGame.get_shake_offset()
	queue_redraw()


func _draw() -> void:
	if not State.in_game:
		return
	DrawGame.draw_bg(self)
	Sprites.draw_all(self)
	DrawGame.draw_fx(self)
