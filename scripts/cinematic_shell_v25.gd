extends "res://scripts/cinematic_shell_v243.gd"

const MatchVizV25Ref = preload("res://scripts/match_visualizer_v25.gd")
const TrainingVizV25Ref = preload("res://scripts/training_visualizer_v25.gd")
const UIV25 = preload("res://scripts/ui_kit.gd")
const MechanicsV25 = preload("res://scripts/mechanics_catalog_v23.gd")


func _build_match_overlay() -> void:
	super._build_match_overlay()
	if match_visualizer == null or not is_instance_valid(match_visualizer):
		return
	var old := match_visualizer
	var parent := old.get_parent()
	var index := old.get_index()
	if parent == null:
		return
	parent.remove_child(old)
	old.queue_free()
	var replacement := MatchVizV25Ref.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		# Mechanical sequences need enough time to read the wall setup, ball arc,
		# rotation change and finish instead of flashing past the player.
		match_timer.wait_time = 1.78


func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", -1)
	identity.add_child(UIV25.label("PERFORMANCE LAB  /  3D SESSION", 8, UIV25.CYAN, 800))
	identity.add_child(UIV25.label(str(player.get("name", "SPIELER")).to_upper(), 25, UIV25.TEXT, 800))
	header.add_child(identity)
	header.add_child(UIV25.badge("LIVE", accent))
	root.add_child(header)

	var training := TrainingVizV25Ref.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var unlocked := state.unlocked_mechanics_v23(player)
	var mastery := 0
	var best_label := "BASICS"
	var detail := {"setup":0, "control":0, "read":0, "finish":0}
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size() - 1]
		var mech_id := str(best.get("id", ""))
		best_label = str(best.get("label", "MECHANIC")).to_upper()
		mastery = state.mechanic_mastery(player, mech_id)
		detail = state.mechanic_components(player, mech_id)

	var session_bar := HBoxContainer.new()
	session_bar.add_theme_constant_override("separation", 4)
	session_bar.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 5))], UIV25.CYAN))
	session_bar.add_child(_metric_block("MÜDIGKEIT", "%d" % int(player.get("fatigue", 0)), UIV25.GOLD))
	session_bar.add_child(_metric_block("MASTERY", "%d%%" % mastery, accent))
	root.add_child(session_bar)

	var mastery_row := HBoxContainer.new()
	mastery_row.add_theme_constant_override("separation", 8)
	var mechanic_copy := VBoxContainer.new()
	mechanic_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mechanic_copy.add_theme_constant_override("separation", -1)
	mechanic_copy.add_child(UIV25.label(best_label, 10, UIV25.TEXT, 800))
	mechanic_copy.add_child(UIV25.label(
		"SET %d   CTRL %d   READ %d   FIN %d" % [
			int(detail.get("setup", mastery)),
			int(detail.get("control", mastery)),
			int(detail.get("read", mastery)),
			int(detail.get("finish", mastery))
		], 8, UIV25.MUTED, 700
	))
	mastery_row.add_child(mechanic_copy)

	var upcoming := state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		mastery_row.add_child(UIV25.badge("NEXT %d%%" % MechanicsV25.progress(player, next), UIV25.PURPLE))
	root.add_child(mastery_row)

	root.add_child(UIV25.label("DRILL WÄHLEN", 8, UIV25.DIM, 800))
	root.add_child(_training_program_grid(player))
	return root
