extends "res://scripts/cinematic_shell_v24.gd"

const MatchVizV241Ref = preload("res://scripts/match_visualizer_v241.gd")
const TrainingVizV241Ref = preload("res://scripts/training_visualizer_v241.gd")
const HomeStageV241Ref = preload("res://scripts/visual_stage_v24.gd")
const UIV241 = preload("res://scripts/ui_kit.gd")
const MechanicsV241 = preload("res://scripts/mechanics_catalog_v23.gd")

func _build_home_page() -> void:
	super._build_home_page()
	page_content.add_child(_home_progress_stage_v241())

func _home_progress_stage_v241() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var placements := int(record.get("placements", 0))
	var played := int(record.get("played", 0))
	var wins := int(record.get("wins", 0))
	var stage := HomeStageV241Ref.new().configure(UIV241.CYAN, "player")
	stage.custom_minimum_size.y = 166

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var title_row := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV241.label("SEASON TRACK", 8, UIV241.CYAN, 800))
	copy.add_child(UIV241.label("ERSTER RANK", 20, UIV241.TEXT, 800))
	title_row.add_child(copy)
	title_row.add_child(UIV241.badge("%d/10" % mini(placements, 10), UIV241.CYAN))
	box.add_child(title_row)

	box.add_child(UIV241.progress(mini(placements, 10), 10, UIV241.CYAN, 6))

	var milestones := HBoxContainer.new()
	milestones.add_theme_constant_override("separation", 4)
	milestones.add_child(_metric_block("START", "%d SPIELE" % played, UIV241.MUTED))
	milestones.add_child(_metric_block("HALBZEIT", "%d/5" % mini(placements, 5), UIV241.PURPLE))
	milestones.add_child(_metric_block("RANK", "%d FEHLEN" % maxi(0, 10 - placements), UIV241.CYAN))
	box.add_child(milestones)

	var footer := "NÄCHSTES ZIEL  ·  %s" % ("PLACEMENTS ABSCHLIESSEN" if placements < 10 else "%d SIEGE  ·  RANK PUSH" % wins)
	box.add_child(UIV241.label(footer, 8, UIV241.DIM, 700))
	return stage

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
	var replacement := MatchVizV241Ref.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.42

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	identity.add_child(UIV241.label("PERFORMANCE LAB", 8, UIV241.DIM, 800))
	identity.add_child(UIV241.label(str(player.get("name", "SPIELER")).to_upper(), 25, UIV241.TEXT, 800))
	header.add_child(identity)
	header.add_child(UIV241.badge("LIVE TRAINING", accent))
	root.add_child(header)

	var training := TrainingVizV241Ref.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 5))], UIV241.CYAN))
	status.add_child(_metric_block("MÜDE", str(int(player.get("fatigue", 0))), UIV241.GOLD))
	status.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV241.PURPLE))
	root.add_child(status)

	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size() - 1]
		var mech_id := str(best.get("id", ""))
		var mastery := state.mechanic_mastery(player, mech_id)
		var detail := state.mechanic_components(player, mech_id)
		var mastery_row := HBoxContainer.new()
		var mech_name := UIV241.label(str(best.get("label", "MECHANIC")).to_upper(), 10, UIV241.TEXT, 800)
		mech_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mastery_row.add_child(mech_name)
		mastery_row.add_child(UIV241.badge("%d%%" % mastery, accent))
		root.add_child(mastery_row)
		root.add_child(UIV241.label(
			"SET %d   CTRL %d   READ %d   FIN %d" % [
				int(detail.get("setup", mastery)), int(detail.get("control", mastery)),
				int(detail.get("read", mastery)), int(detail.get("finish", mastery))
			], 8, UIV241.MUTED, 700
		))

	root.add_child(UIV241.label("DRILL WÄHLEN", 8, UIV241.DIM, 800))
	root.add_child(_training_program_grid(player))

	var upcoming := state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		root.add_child(UIV241.label(
			"NÄCHSTER UNLOCK  ·  %s  ·  %d%%" % [str(next.get("label", "MECHANIC")), MechanicsV241.progress(player, next)],
			8, UIV241.MUTED, 700
		))
	return root
