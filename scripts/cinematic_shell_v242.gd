extends "res://scripts/cinematic_shell_v241.gd"

const MatchVizV242Ref = preload("res://scripts/match_visualizer_v242.gd")
const TrainingVizV242Ref = preload("res://scripts/training_visualizer_v242.gd")
const UIV242 = preload("res://scripts/ui_kit.gd")
const MechanicsV242 = preload("res://scripts/mechanics_catalog_v23.gd")

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
	var replacement := MatchVizV242Ref.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.46

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	identity.add_child(UIV242.label("PERFORMANCE LAB", 8, UIV242.DIM, 800))
	identity.add_child(UIV242.label(str(player.get("name", "SPIELER")).to_upper(), 25, UIV242.TEXT, 800))
	header.add_child(identity)
	header.add_child(UIV242.badge("LIVE TRAINING", accent))
	root.add_child(header)

	var training := TrainingVizV242Ref.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 5))], UIV242.CYAN))
	status.add_child(_metric_block("MÜDE", str(int(player.get("fatigue", 0))), UIV242.GOLD))
	status.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV242.PURPLE))
	root.add_child(status)

	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size() - 1]
		var mech_id := str(best.get("id", ""))
		var mastery := state.mechanic_mastery(player, mech_id)
		var detail := state.mechanic_components(player, mech_id)
		var mastery_row := HBoxContainer.new()
		var mech_name := UIV242.label(str(best.get("label", "MECHANIC")).to_upper(), 10, UIV242.TEXT, 800)
		mech_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mastery_row.add_child(mech_name)
		mastery_row.add_child(UIV242.badge("%d%%" % mastery, accent))
		root.add_child(mastery_row)
		root.add_child(UIV242.label(
			"SET %d   CTRL %d   READ %d   FIN %d" % [
				int(detail.get("setup", mastery)), int(detail.get("control", mastery)),
				int(detail.get("read", mastery)), int(detail.get("finish", mastery))
			], 8, UIV242.MUTED, 700
		))

	root.add_child(UIV242.label("DRILL WÄHLEN", 8, UIV242.DIM, 800))
	root.add_child(_training_program_grid(player))

	var upcoming := state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		root.add_child(UIV242.label(
			"NÄCHSTER UNLOCK  ·  %s  ·  %d%%" % [str(next.get("label", "MECHANIC")), MechanicsV242.progress(player, next)],
			8, UIV242.MUTED, 700
		))
	return root
