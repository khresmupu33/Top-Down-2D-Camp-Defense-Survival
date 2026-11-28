extends Node
## Pemicu cerita/dialog & spawn Archer berdasarkan skor (dari systems/story.js). Autoload: Story.


func update_story_triggers() -> void:
	var now: float = Util.now()
	Items.update_collectible_relocate_cooldown()
	# Normal: Archer diberi warning sebelum benar-benar spawn.
	if (State.level == "normal" or State.level == "hard") and State.score >= Config.ARCHER_FIRST_SCORE and State.archers.size() < Config.MAX_ARCHERS:
		if State.archer_warning_timer <= 0 and now >= State.archer_next_spawn_time:
			State.archer_warning_timer = 180
			State.archer_warning_text = "⚠ ARCHER AKAN MUNCUL! SIAP-SIAP!"
		if State.archer_warning_timer > 0:
			State.archer_warning_timer -= 1
			if State.archer_warning_timer <= 0:
				Archers.spawn_archer()
				State.archer_next_spawn_time = now + Util.random_int(Config.ARCHER_SPAWN_MIN, Config.ARCHER_SPAWN_MAX)
	if State.level == "hard" and State.score == 1 and State.story_message_timer <= 0:
		State.story_message = 'Lord Vindex: "Aku adalah Vindex. Dan kau tidak akan keluar hidup-hidup."'
		State.story_message_timer = 300
	if State.level == "hard" and State.score >= 25 and not State.hard25_triggered and not State.hard25_completed:
		HardSequence.trigger_hard25_sequence()
