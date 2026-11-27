extends SceneTree
## Verifikasi kompilasi: memuat semua .gd di res://scripts (godot --headless --path . --script res://tests/compile_check.gd): memuat semua .gd di res://scripts dan melaporkan error kompilasi.
## Dijalankan pada frame pertama agar autoload sudah terdaftar.
var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var files: Array = []
	_collect("res://scripts", files)
	var bad := 0
	for f in files:
		var s = load(f)
		if s == null or not s.can_instantiate():
			bad += 1
			print("LOAD FAILED: ", f)
	print("COMPILE CHECK: ", files.size(), " script, gagal: ", bad)
	quit(1 if bad > 0 else 0)
	return true

func _collect(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_collect(dir + "/" + sub, out)
	for fn in d.get_files():
		if fn.ends_with(".gd"):
			out.append(dir + "/" + fn)
