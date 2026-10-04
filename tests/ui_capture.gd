extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")

func _initialize() -> void:
	root.size = Vector2i(450, 900)
	call_deferred("_capture_all")


func _capture_all() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await create_timer(0.20).timeout

	var capture_dir := ProjectSettings.globalize_path("res://build/ui-captures")
	DirAccess.make_dir_recursive_absolute(capture_dir)

	for page in ["home", "team", "play", "market", "empire"]:
		main._show_page(page, false)
		await process_frame
		await process_frame
		await create_timer(0.08).timeout
		var image := root.get_texture().get_image()
		var path := "res://build/ui-captures/%s.png" % page
		var err := image.save_png(path)
		if err != OK:
			push_error("Could not save UI capture: %s" % path)

	quit()
