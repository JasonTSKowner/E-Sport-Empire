extends "res://scripts/cinematic_shell_v243.gd"

const TrainingVizV25 = preload("res://scripts/training_visualizer_v25.gd")
const MatchVizV25 = preload("res://scripts/match_visualizer_v25.gd")
const UIV25 = preload("res://scripts/ui_kit.gd")
const GameDataV25 = preload("res://scripts/game_data.gd")

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
	var replacement := MatchVizV25.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 2.0

func _advance_match() -> void:
	super._advance_match()
	if match_timer == null or match_finished or match_visualizer == null:
		return
	var mechanic_play := not str(match_visualizer.mechanic_label).is_empty()
	var important_phase := str(match_visualizer.phase) in ["shot","save","goal","psycho_contact","redirect_finish","reset_2","reset_3","reset_4"]
	match_timer.wait_time = 2.35 if important_phase else 2.15 if mechanic_play else 1.85

func _build_team_page() -> void:
	if team_view != "training":
		super._build_team_page()
		return

	game.apply_real_time_fatigue_recovery(false)
	var mode: String = game.selected_mode()
	var accent: Color = GameDataV25.MODE_COLORS.get(mode, UIV25.CYAN)
	var roster := game.roster_for(mode)
	var selected_player: Dictionary = {}
	if not roster.is_empty():
		selected_player = roster[0]
		for roster_player in roster:
			if str(roster_player.get("id", "")) == selected_team_player_id:
				selected_player = roster_player
				break
		selected_team_player_id = str(selected_player.get("id", "captain"))

	page_content.add_child(_training_nav_v25(accent))
	if selected_player.is_empty():
		var empty := UIV25.label("Kein Spieler für Training verfügbar.", 11, UIV25.MUTED, 700)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page_content.add_child(empty)
		return
	page_content.add_child(_training_scene_v25(selected_player, accent))

func _training_nav_v25(accent: Color) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)

	var title_row := HBoxContainer.new()
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_constant_override("separation", -1)
	title.add_child(UIV25.label("PERFORMANCE LAB", 8, accent, 800))
	title.add_child(UIV25.label("Training", 23, UIV25.TEXT, 800))
	title_row.add_child(title)
	title_row.add_child(UIV25.badge("ROCKET LEAGUE", accent))
	root.add_child(title_row)

	var switch := HBoxContainer.new()
	switch.add_theme_constant_override("separation", 4)
	for entry in [["roster","KADER"],["training","TRAINING"],["coaching","COACH"],["scouting","SCOUT"]]:
		var view_id := str(entry[0])
		var selected := view_id == "training"
		var button := UIV25.button(str(entry[1]), accent if selected else UIV25.DIM, selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 38
		button.add_theme_font_size_override("font_size", 8)
		button.disabled = selected
		if not selected:
			button.pressed.connect(_select_team_view.bind(view_id))
		switch.add_child(button)
	root.add_child(switch)
	return root

func _training_scene_v25(player: Dictionary, accent: Color) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	var state := _v23()
	var readiness := state.training_readiness(player)

	var training := TrainingVizV25.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var action_header := HBoxContainer.new()
	var drill_label := UIV25.label("DRILL WÄHLEN", 8, UIV25.DIM, 800)
	drill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_header.add_child(drill_label)
	var free := UIV25.label("NORMALES TRAINING · GRATIS", 7, UIV25.GREEN, 800)
	free.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action_header.add_child(free)
	root.add_child(action_header)

	root.add_child(_training_program_grid_v25(player, accent))
	return root

func _training_program_grid_v25(player: Dictionary, accent: Color) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	var readiness := game.training_readiness(player)
	var focus_ready := bool(readiness.get("ok", false))
	for program_value in game.development_programs():
		var program: Dictionary = program_value
		var program_id := str(program.get("id", ""))
		var short_name := str(program.get("short", "DRILL")).replace(" TRAINING", "").replace(" REVIEW", "")
		var button := UIV25.button(short_name, accent, false, true)
		button.disabled = not focus_ready
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 8)
		if not focus_ready:
			button.tooltip_text = "Training aktuell nicht bereit."
		button.pressed.connect(_train_player.bind(str(player.get("id", "")), program_id))
		grid.add_child(button)
	return grid
