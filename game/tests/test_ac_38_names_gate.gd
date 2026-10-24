extends ViewTest
## AC-38: the names gate fails when a listed name appears in a file and passes when none does.

func _run(names_file: String, dir: String) -> int:
	var out := []
	return OS.execute("bash", [ProjectSettings.globalize_path("res://../tools/check-names.sh"), names_file, dir], out)


func _init() -> void:
	var tmp := OS.get_cache_dir().path_join("names_gate_test")
	DirAccess.make_dir_recursive_absolute(tmp.path_join("tree"))
	var f := FileAccess.open(tmp.path_join("tree/doc.md"), FileAccess.WRITE)
	f.store_string("Written by Zebediah Quux.\n")
	f.close()
	var bad := FileAccess.open(tmp.path_join("bad.txt"), FileAccess.WRITE)
	bad.store_string("quux\n")
	bad.close()
	var good := FileAccess.open(tmp.path_join("good.txt"), FileAccess.WRITE)
	good.store_string("nobodyhere\n")
	good.close()
	check("ac_38 a listed name in a file fails the gate", _run(tmp.path_join("bad.txt"), tmp.path_join("tree")) == 1)
	check("ac_38 an unlisted name passes", _run(tmp.path_join("good.txt"), tmp.path_join("tree")) == 0)
	finish()
