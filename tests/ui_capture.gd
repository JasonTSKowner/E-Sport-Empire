extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")


func _initialize() -> void:
	root.size = Vector2i(450, 900)
	call_deferred("_capture_all")


func _capture(main, name: String, page: String) -> void:
	main._show_page(page, false)
	await process_frame
	await process_frame
	await create_timer(0.08).timeout
	var image := root.get_texture().get_image()
	var path := "res://build/ui-captures/%s.png" % name
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save UI capture: %s" % path)


func _capture_all() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await create_timer(0.20).timeout

	var capture_dir := ProjectSettings.globalize_path("res://build/ui-captures")
	DirAccess.make_dir_recursive_absolute(capture_dir)

	main.home_view = "dashboard"
	await _capture(main, "home", "home")

	main.ranked_view = "overview"
	await _capture(main, "ranked", "play")

	main.team_view = "roster"
	await _capture(main, "team-roster", "team")

	main.team_view = "training"
	await _capture(main, "team-training", "team")

	main.team_view = "scouting"
	await _capture(main, "team-scout", "team")

	main.empire_view = "overview"
	await _capture(main, "empire", "empire")

	quit()
