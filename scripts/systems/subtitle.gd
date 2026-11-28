extends Node
## Subtitle Lord Vindex (mode SULIT): ditampilkan di luar arena, tepat di bawahnya,
## supaya teks tidak menutupi pemain. Memakai Label "hardSubtitle" dari GameUI.
## Port dari systems/subtitle.js (HardSubtitle). Cache dibaca dari Label itu sendiri
## (Label dibuat ulang tiap scene game, jadi cache di autoload bisa basi).


func _label():
	var n = GameUI.node("hardSubtitle")
	if n == null or not is_instance_valid(n):
		return null
	return n


func show_subtitle(text = "", alpha: float = 1.0) -> void:
	if State.level != "hard":
		return
	if text == null or str(text) == "":
		hide_subtitle()
		return
	var el = _label()
	if el == null:
		return
	var s: String = str(text)
	if el.text != s:
		el.text = s
	var a: float = roundf(clampf(alpha, 0.0, 1.0) * 20.0) / 20.0
	if not is_equal_approx(el.modulate.a, a):
		var c: Color = el.modulate
		c.a = a
		el.modulate = c
	if not el.visible:
		el.visible = true


func hide_subtitle() -> void:
	var el = _label()
	if el == null:
		return
	if el.modulate.a != 0.0:
		var c: Color = el.modulate
		c.a = 0.0
		el.modulate = c
	el.text = ""
