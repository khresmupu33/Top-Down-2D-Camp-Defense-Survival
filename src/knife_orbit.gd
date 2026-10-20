extends Node2D

@export var rotation_speed: float = 4.0

func _process(delta):
	# Karena KnifeOrbit sudah jadi anak Main Character, 
	# rotasi di sini akan otomatis membuat pisau berputar mengelilingi pemain!
	rotation += rotation_speed * delta
