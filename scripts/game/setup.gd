extends Node
## Membuat objek awal permainan: pemain, target, Gadfly, killer pertama, mode (dari game/setup.js). Autoload: GameSetup.


func create_game_objects() -> void:
	var now: float = Util.now()
	State.player = {"x": 390, "y": 300, "w": 20, "h": 20}
	State.target = {"x": 350, "y": 250, "w": 20, "h": 20}
	State.health = {"x": 200, "y": 200, "w": 25, "h": 25, "visible": false, "pulse": 0}
	State.powerup = {"x": 0, "y": 0, "w": 26, "h": 26, "visible": true, "pulse": 0}
	State.power_active = 0
	State.meteors = []
	State.meteor_session_active = false
	State.meteor_session_timer = 0
	State.meteor_next_spawn = now + Util.random_int(Config.METEOR_FIRST_MIN, Config.METEOR_FIRST_MAX)
	State.meteor_session_used = false
	State.meteor_next_session_timer = 0
	State.meteor_pre_shower_active = false
	State.meteor_pre_shower_timer = 0
	State.meteor_pre_shower_next_spawn = 0
	State.meteor_pre_shower_spawned = 0
	State.meteor_shower_unlocked = false
	State.meteor_warning_timer = 0
	State.meteor_phase = "idle"
	State.meteor_phase_timer = 0
	State.meteor_burst_cooldown = 0
	State.large_meteor_pending = false
	State.large_meteor_spawn_timer = 0
	State.large_meteor_warning = null
	State.large_meteor_milestones = {}
	State.large_meteor_spawn_timer = Util.random_int(Config.LARGE_METEOR_RANDOM_MIN, Config.LARGE_METEOR_RANDOM_MAX)
	State.meteor_shockwave = null
	State.large_meteor_impact_state = null
	State.large_meteor = null
	State.vindex_barrage = null
	State.vindex_vortex = null
	State.hard_death_cause = ""
	State.vindex_move_delay = 0
	State.player_shock_timer = 0
	State.archers = []
	State.archer_arrows = []
	State.lord_vindex = null
	State.time_stop = 0
	State.time_stop_wave = 0
	State.time_stop_origin_x = 0
	State.time_stop_origin_y = 0
	State.time_stop_powerup = {"x": 0, "y": 0, "w": 28, "h": 28, "visible": false, "pulse": 0}
	State.time_stop_spawn_time = now + Util.random_int(Config.TIME_STOP_FIRST_MIN, Config.TIME_STOP_FIRST_MAX)
	State.enemies_awake = true
	State.hard_meteor_permanent = false
	State.hard_finale_triggered = false
	State.hard25_triggered = false
	State.hard25_completed = false
	State.hard25_sequence_active = false
	State.hard25_sequence_timer = 0
	State.hard25_sequence_phase = 0
	State.hard25_ready_for_input = false
	State.hard25_arena_resume_requested = false
	State.hard25_dialogue_timer = 0
	State.hard_intro_last_time = 0
	State.vindex_time_stop = 0
	# hanya mode SULIT yang memakai Time Stop Vindex (tidak mengonsumsi RNG di mode lain)
	var is_hard: bool = State.level == "hard"
	State.vindex_time_stop_cooldown = Util.random_int(420, 720) if is_hard else 0
	State.vindex_barrage_cooldown = Util.random_int(300, 600) if is_hard else 0
	State.vindex_vortex_cooldown = Util.random_int(500, 900) if is_hard else 0
	State.vindex_laser_countdown = 0
	State.vindex_laser_active = false
	State.vindex_laser_x = 0
	State.vindex_laser_y = 0
	State.vindex_laser_angle = 0
	State.vindex_laser_origin_x = 0
	State.vindex_laser_origin_y = 0
	State.vindex_laser_pulse = 0
	State.vindex_laser_fire_timer = 0
	State.vindex_laser_has_hit = false
	State.story_message_timer = 0
	State.story_message = ""
	State.killer_spawn_time = now + Config.KILLER_FIRST_TIME
	State.next_killer_spawn_delay = Config.KILLER_NEXT_TIME
	State.killers = []
	State.gadflies = []
	State.particle_list = []
	State.global_freeze = 0
	State.screen_shake = 0
	# Killer pertama.
	Killers.add_killer(true)
	# GADFLY
	# Sama dengan pola file awal: TOP/BOTTOM = horizontal, LEFT/RIGHT = vertikal.
	State.gadflies = [
		{"name": "top", "x": 380, "y": 0, "w": 20, "h": 20, "freeze": 0, "hit_anim": 0, "hit_vx": 0, "hit_vy": 0, "rotation": 0, "rotation_speed": 0},
		{"name": "bottom", "x": 380, "y": 580, "w": 20, "h": 20, "freeze": 0, "hit_anim": 0, "hit_vx": 0, "hit_vy": 0, "rotation": 0, "rotation_speed": 0},
		{"name": "left", "x": 0, "y": 280, "w": 20, "h": 20, "freeze": 0, "hit_anim": 0, "hit_vx": 0, "hit_vy": 0, "rotation": 0, "rotation_speed": 0},
		{"name": "right", "x": 780, "y": 280, "w": 20, "h": 20, "freeze": 0, "hit_anim": 0, "hit_vx": 0, "hit_vy": 0, "rotation": 0, "rotation_speed": 0},
	]
	if State.level == "normal" or State.level == "hard":
		State.archer_next_spawn_time = now + Util.random_int(Config.ARCHER_SPAWN_MIN, Config.ARCHER_SPAWN_MAX)
		State.archer_warning_timer = 0
		State.archer_warning_text = ""
	if State.level == "hard":
		LordVindex.spawn_lord_vindex()
		State.story_message = 'Lord Vindex: "Lihat baik-baik. Ini baru permulaan."'
		State.story_message_timer = 300
	Items.spawn_target()
	State.health.visible = false
	State.health_spawn_time = now + Util.random_int(Config.HEALTH_FIRST_MIN, Config.HEALTH_FIRST_MAX)
	State.powerup.visible = false
	State.powerup_spawn_time = now + Util.random_int(Config.POWER_FIRST_MIN, Config.POWER_FIRST_MAX)
