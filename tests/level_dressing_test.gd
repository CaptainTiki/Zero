extends SceneTree
## Exercise real rebakes and inherited scene reloads with a placed prop and override.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok:
		failures += 1
func inspect(path: String, label: String) -> void:
	var scene: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	check(scene != null, label + " reloads")
	if scene == null:
		return
	var node := scene.instantiate()
	check(node.has_node("Player") and node.has_node("WorldEnvironment"), label + " keeps direct gameplay paths")
	var prop := node.get_node("ManualDressing/ReviewProp") as MeshInstance3D
	check(prop.position == Vector3(2.25, 1.5, -3.75) and prop.mesh is BoxMesh, label + " retains placed prop and mesh")
	check(prop.mesh.material.albedo_color == Color(0.25, 0.5, 0.75, 1), label + " retains local material")
	check(node.get_node("WorldEnvironment").get_meta("review_note") == "keep this", label + " retains inherited override")
	node.free()
func run() -> void:
	for spec in [
		["res://scenes/levels/factory.tscn", "res://tools/build_factory.gd"],
		["res://scenes/levels/l01_district04.tscn", "res://tools/build_l01_greybox.gd"],
		["res://scenes/fidelity_test.tscn", "res://tools/build_fidelity_test.gd"]]:
		var public: String = spec[0]
		var name_text := public.get_file().get_basename()
		var original := FileAccess.get_file_as_string(public)
		var fixture := "res://.godot/dressing_%s.tscn" % name_text
		var contents := original.replace("[gd_scene load_steps=2", "[gd_scene load_steps=4")
		var start := contents.find("[node ")
		contents = contents.insert(start, '[sub_resource type="StandardMaterial3D" id="ReviewMaterial"]\nalbedo_color = Color(0.25, 0.5, 0.75, 1)\n\n[sub_resource type="BoxMesh" id="ReviewMesh"]\nmaterial = SubResource("ReviewMaterial")\n\n')
		contents += '\n[node name="ReviewProp" type="MeshInstance3D" parent="ManualDressing"]\nposition = Vector3(2.25, 1.5, -3.75)\nmesh = SubResource("ReviewMesh")\n\n[node name="WorldEnvironment" parent="."]\nmetadata/review_note = "keep this"\n'
		var file := FileAccess.open(fixture, FileAccess.WRITE)
		file.store_string(contents)
		file.close()
		inspect(fixture, name_text + " before bake")
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", "res://.godot/dressing_%s_build.log" % name_text, "-s", spec[1]], output, true)
		check(code == 0, name_text + " builder succeeds")
		if code != 0:
			print(output)
		check(FileAccess.get_file_as_string(public) == original, name_text + " public scene is unchanged by rebake")
		inspect(fixture, name_text + " after bake")
	print("LEVEL DRESSING: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
