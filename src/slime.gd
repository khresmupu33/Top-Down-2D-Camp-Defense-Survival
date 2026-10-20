
extends CharacterBody2D

@export var speed: float = 100.0
@export var player_detection_range: float = 300.0
@export var attack_range: float = 30.0
@export var max_hp: int = 100

var hp: int = 100
var player: Node2D
var base: Node2D
var is_dead: bool = false

@onready var body_polygon: Polygon2D = $Polygon2D


func _ready():
	hp = max_hp

	var scene = get_parent()
	player = scene.get_node_or_null("Main Character") as Node2D
	base = scene.get_node_or_null("Base") as Node2D


func _physics_process(_delta):
	if is_dead:
		return

	if player == null or base == null:
		velocity = Vector2.ZERO
		return

	var player_distance = global_position.distance_to(
		player.global_position
	)

	var target: Node2D

	if player_distance <= player_detection_range:
		target = player
	else:
		target = base

	var distance = global_position.distance_to(
		target.global_position
	)

	if distance > attack_range:
		var direction = global_position.direction_to(
			target.global_position
		)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func take_damage(amount: int):
	if is_dead:
		return

	hp = maxi(hp - amount, 0)

	# Tampilkan angka damage
	var damage_label = Label.new()
	damage_label.text = "-" + str(amount)
	damage_label.position = Vector2(-10, -35)
	damage_label.add_theme_color_override(
		"font_color", Color.YELLOW
	)
	damage_label.add_theme_font_size_override(
		"font_size", 16
	)
	add_child(damage_label)

	show_damage_number(damage_label)

	# Mati jika HP habis
	if hp <= 0:
		die()


func show_damage_number(damage_label: Label) -> void:
	damage_label.position.y = -35

	await get_tree().create_timer(0.6).timeout

	if is_instance_valid(damage_label):
		damage_label.queue_free()


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO

	# Ubah slime menjadi hitam
	body_polygon.color = Color.BLACK

	# Hilang setelah jeda singkat
	await get_tree().create_timer(0.4).timeout

	queue_free()
