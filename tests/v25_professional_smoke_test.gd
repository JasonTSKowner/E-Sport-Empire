extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const StageV25 = preload("res://scripts/professional_stage_v25.gd")
const ShowcaseV25 = preload("res://scripts/player_showcase_v25.gd")
const ShellV25 = preload("res://scripts/cinematic_shell_v25.gd")
const StateV23 = preload("res://scripts/game_state_v23.gd")

var failures: Array[String] = []

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("V2.5 1/5: release metadata")
	_check(AppConfig.VERSION.begins_with("2.5."), "v2.5 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.5.0", "v2.5 changelog version")

	print("V2.5 2/5: professional stage")
	var stage := StageV25.new().configure(Color("74DFF7"), "hero")
	_check(stage.custom_minimum_size.y >= 300.0, "professional hero stage has enough visual height")
	stage.free()

	print("V2.5 3/5: player showcase")
	var state := StateV23.new()
	state.reset_game()
	var player: Dictionary = state.data["roster"][0]
	var showcase := ShowcaseV25.new().configure(player, Color("74DFF7"), state.player_overall(player))
	_check(showcase.custom_minimum_size.y >= 180.0, "player showcase is visually substantial")
	showcase.free()

	print("V2.5 4/5: shell compile")
	var shell := ShellV25.new()
	_check(shell != null, "professional shell compiles")
	shell.free()

	print("V2.5 5/5: main scene")
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	_check(main_scene != null, "Main scene loads")
	if main_scene != null:
		var main := main_scene.instantiate()
		_check(main != null, "Main scene instantiates")
		main.free()

	if failures.is_empty():
		print("E-Sport Empire v2.5 professional rebuild smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.5 smoke test failed: %s" % failure)
		quit(1)
