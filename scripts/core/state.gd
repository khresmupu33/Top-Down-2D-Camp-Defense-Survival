extends Node
## State permainan (dari core/state.js). Autoload: State.
## Semua variabel global JS dipindah ke sini; nama memakai snake_case.
## Set JS -> Dictionary (kunci -> true). Array JS -> Array.


# ── Alur permainan ────────────────────────────────────────────────────
var game_state = "menu"
var level = "easy"
var score = 0
var lives = 3
var paused = false
var pressed_keys = {}
var global_freeze = 0
var enemies_awake = true

# ── Objek utama ───────────────────────────────────────────────────────
var player = null
var target = null
var health = null
var killers = []
var gadflies = []
var hit_cooldown = 0
var target_spawn_time = 0
var health_spawn_time = 0
var player_shock_timer = 0
var player_shock_x = 0
var player_shock_y = 0
var player_death_timer = 0
var player_death_max = 0

# ── Penghitung spawn ──────────────────────────────────────────────────
var powerup = null
var powerup_spawn_time = 0
var power_active = 0
var killer_spawn_time = 0
var next_killer_spawn_delay = 10000
var ending_index = 0
var collectible_relocate_cooldown = 0

# ── Archer ────────────────────────────────────────────────────────────
var archers = []
var archer_next_spawn_time = 0
var archer_warning_timer = 0
var archer_warning_text = ''
var archer_arrows = []

# ── Time Stop ─────────────────────────────────────────────────────────
var time_stop = 0
var time_stop_wave = 0
var time_stop_wave_pulse = 0
var time_stop_origin_x = 0
var time_stop_origin_y = 0
var time_stop_powerup = null
var time_stop_spawn_time = 0

# ── Lord Vindex ───────────────────────────────────────────────────────
var lord_vindex = null
var vindex_time_stop_move_x = 0
var vindex_time_stop_move_y = 0
var vindex_time_stop_move_timer = 0
var vindex_time_stop = 0
var vindex_time_stop_cooldown = 0
var vindex_laser_countdown = 0
var vindex_laser_active = false
var vindex_laser_x = 0
var vindex_laser_y = 0
var vindex_laser_angle = 0
var vindex_laser_origin_x = 0
var vindex_laser_origin_y = 0
var vindex_laser_pulse = 0
var vindex_laser_fire_timer = 0
var vindex_laser_has_hit = false
# Rentetan Laser: { phase:'gather'|'warn'|'fire'|'gap', t, round, beams:[{angle}], originX, originY }
var vindex_barrage = null
var vindex_barrage_cooldown = 0
# Pusaran Ungu: { x, y, age, exploded }
var vindex_vortex = null
var vindex_vortex_cooldown = 0
var hard_death_cause = ''
var vindex_move_delay = 0

# ── Mode SULIT: intro & urutan poin 25 ────────────────────────────────
var hard_revival_timer = null
var hard_meteor_permanent = false
var hard_finale_triggered = false
var hard25_triggered = false
var hard25_completed = false
var hard_intro_timer = 0
var hard_intro_last_time = 0
var hard_intro_ready = false
var hard_intro_meteor_list = []
var hard25_sequence_active = false
var hard25_sequence_timer = 0
var hard25_sequence_phase = 0
var hard25_ready_for_input = false
var hard25_arena_resume_requested = false
var hard25_dialogue_timer = 0

# ── Cerita, partikel, getaran ─────────────────────────────────────────
var story_message_timer = 0
var story_message = ''
var particle_list = []
var screen_shake = 0

# ── Meteor ────────────────────────────────────────────────────────────
var meteor_shockwave = null
var large_meteor_impact_state = null
var large_meteor = null
var meteors = []
var meteor_session_active = false
var meteor_session_timer = 0
var meteor_next_spawn = 0
var meteor_session_used = false
var meteor_next_session_timer = 0
var meteor_pre_shower_active = false
var meteor_pre_shower_timer = 0
var meteor_pre_shower_next_spawn = 0
var meteor_pre_shower_spawned = 0
var meteor_shower_unlocked = false
var meteor_warning_timer = 0
var meteor_phase = 'idle'
var meteor_phase_timer = 0
var meteor_burst_cooldown = 0
var large_meteor_pending = false
var large_meteor_spawn_timer = 0
var large_meteor_warning = null
var large_meteor_milestones = {}

# ── Lainnya ───────────────────────────────────────────────────────────
var ending_destroy_index = 0
var ending_destroyed_count = 0
var ending_destroy_timer = 0
var ending_wait_timer = 0
var ending_raf = 0

# ── Tambahan khusus Godot (pengganti document.body.dataset & status halaman) ──
var page_level = null          # level dari menu: easy | normal | hard (null = belum dipilih)
var in_game = false            # true selama scene game aktif (input & loop hanya jalan saat true)
