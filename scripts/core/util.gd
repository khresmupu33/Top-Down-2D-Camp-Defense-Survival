extends Node
## Utilitas umum (dari core/utils.js): angka acak, tabrakan (AABB), wrap & pergerakan dasar.
## Pemakaian: Util.random_int(1, 6), Util.collide(a, b), dst.
## Entitas = Dictionary dengan kunci x, y, w, h (sama seperti objek JS).


## Pengganti performance.now() (milidetik, float).
func now() -> float:
	return float(Time.get_ticks_msec())


## Pengganti setTimeout(fn, ms): memanggil callable sekali setelah ms milidetik.
func after_ms(ms: float, callback: Callable) -> void:
	get_tree().create_timer(ms / 1000.0).timeout.connect(callback, CONNECT_ONE_SHOT)


## Pindah scene berdasarkan kunci di Config.PAGES ("menu", "rules", "game").
func goto_page(key: String) -> void:
	get_tree().change_scene_to_file(Config.PAGES[key])


## Angka bulat acak inklusif [min_v, max_v].
func random_int(min_v: int, max_v: int) -> int:
	return randi_range(min_v, max_v)


func random_pos_away_from_player() -> Dictionary:
	var x := 0
	var y := 0
	var attempts := 0
	while true:
		x = random_int(50, Config.WIDTH - 50)
		y = random_int(50, Config.HEIGHT - 50)
		attempts += 1
		if State.player == null:
			break
		var too_close: bool = absf(x - State.player.x) < 120 and absf(y - State.player.y) < 120
		var in_hazard: bool = State.level == "hard" and VindexAttacks.in_vindex_hazard_zone(x, y)
		if not ((too_close or in_hazard) and attempts < 100):
			break
	return {"x": x, "y": y}


## Tabrakan dua kotak (AABB) dengan kunci x, y, w, h.
func collide(a: Dictionary, b: Dictionary) -> bool:
	return not (a.x + a.w < b.x or a.x > b.x + b.w or a.y + a.h < b.y or a.y > b.y + b.h)


## Membungkus objek yang keluar arena ke sisi seberang.
func wrap_obj(obj: Dictionary) -> void:
	if obj.x + obj.w < 0:
		obj.x = Config.WIDTH
	if obj.x > Config.WIDTH:
		obj.x = -obj.w
	if obj.y + obj.h < 0:
		obj.y = Config.HEIGHT
	if obj.y > Config.HEIGHT:
		obj.y = -obj.h


func move_horizontal(obj: Dictionary, target_x: float, speed: float) -> void:
	var center: float = obj.x + obj.w / 2.0
	if center < target_x:
		obj.x += speed
	elif center > target_x:
		obj.x -= speed


func move_vertical(obj: Dictionary, target_y: float, speed: float) -> void:
	var center: float = obj.y + obj.h / 2.0
	if center < target_y:
		obj.y += speed
	elif center > target_y:
		obj.y -= speed


func move_towards(obj: Dictionary, target_obj: Dictionary, speed: float) -> void:
	var cx: float = obj.x + obj.w / 2.0
	var cy: float = obj.y + obj.h / 2.0
	var tx: float = target_obj.x + target_obj.w / 2.0
	var ty: float = target_obj.y + target_obj.h / 2.0
	if cx < tx:
		obj.x += speed
	if cx > tx:
		obj.x -= speed
	if cy < ty:
		obj.y += speed
	if cy > ty:
		obj.y -= speed


## Sudut (radian) dari pusat a ke pusat b.
func angle_to(a: Dictionary, b: Dictionary) -> float:
	return atan2((b.y + b.h / 2.0) - (a.y + a.h / 2.0), (b.x + b.w / 2.0) - (a.x + a.w / 2.0))
