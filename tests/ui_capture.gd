extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")


func _initialize() -> void:
	root.size = Vector2i(450, 900)
	call_deferred("_capture_all")


func _save_current(name: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.14).timeout
	var image := root.get_texture().get_image()
	var path := "res://build/ui-captures/%s.png" % name
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save UI capture: %s" % path)


func _capture(main, name: String, page: String) -> void:
	main._show_page(page, false)
	await _save_current(name)


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

	# Capture the actual live match presentation as part of visual regression.
	main._start_match("Rocket League")
	await process_frame
	await process_frame
	if main.match_timer != null:
		main.match_timer.stop()
	# Advance into an active play so cars, ball trajectory and rotation are visible.
	if not main.match_finished:
		main._advance_match()
	await _save_current("match")
	if main.match_overlay != null:
		await main._close_match()

	main.team_view = "roster"
	await _capture(main, "team-roster", "team")

	main.team_view = "training"
	await _capture(main, "team-training", "team")

	main.team_view = "scouting"
	await _capture(main, "team-scout", "team")

	main.empire_view = "overview"
	await _capture(main, "empire", "empire")

	quit()
