extends Node
## Item & target: spawn, relokasi dari musuh (dari entities/items.js).


func spawn_target() -> void:
	if State.level == "hard" and State.hard25_sequence_active:
		return
	var p: Dictionary = Util.random_pos_away_from_player()
	State.target.x = p.x
	State.target.y = p.y
	State.target_spawn_time = Util.now()


func spawn_health() -> void:
	if State.level == "hard" and State.hard25_sequence_active:
		return
	var p: Dictionary = Util.random_pos_away_from_player()
	State.health.x = p.x
	State.health.y = p.y
	State.health.visible = true
	State.health.pulse = 0
	State.health_spawn_time = Util.now()


func spawn_powerup() -> void:
	if State.level == "hard" and State.hard25_sequence_active:
		return
	var p: Dictionary = Util.random_pos_away_from_player()
	State.powerup.x = p.x
	State.powerup.y = p.y
	State.powerup.visible = true
	State.powerup.pulse = 0
	State.powerup_spawn_time = Util.now()


func spawn_time_stop_powerup() -> void:
	if State.level == "easy" or State.time_stop_powerup == null or (State.level == "hard" and State.hard25_sequence_active):
		return
	var p: Dictionary = Util.random_pos_away_from_player()
	State.time_stop_powerup.x = p.x
	State.time_stop_powerup.y = p.y
	State.time_stop_powerup.visible = true
	State.time_stop_powerup.pulse = 0


func relocate_collectible_from_enemy(enemy: Dictionary) -> void:
	if State.player == null or State.collectible_relocate_cooldown > 0:
		return
	var items = [State.target, State.health, State.powerup, State.time_stop_powerup]
	var moved := false
	for item in items:
		if item == null or not item.get("visible", false):
			continue
		if Util.collide(enemy, item):
			var p: Dictionary = Util.random_pos_away_from_player()
			item.x = p.x
			item.y = p.y
			item.pulse = 0
			moved = true
	if moved:
		State.collectible_relocate_cooldown = 18


func update_collectible_relocate_cooldown() -> void:
	if State.collectible_relocate_cooldown > 0:
		State.collectible_relocate_cooldown -= 1
