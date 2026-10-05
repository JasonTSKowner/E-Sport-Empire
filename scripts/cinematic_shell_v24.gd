extends "res://scripts/cinematic_shell_v23_release.gd"

const MatchVizV24Ref = preload("res://scripts/match_visualizer_v24.gd")
const TrainingVizV24Ref = preload("res://scripts/training_visualizer_v24.gd")
const StageV24Ref = preload("res://scripts/visual_stage_v24.gd")
const UIV24 = preload("res://scripts/ui_kit.gd")
const RankedV24 = preload("res://scripts/ranked_data.gd")
const RankEmblemV24 = preload("res://scripts/rank_emblem.gd")
const PortraitV24 = preload("res://scripts/player_portrait.gd")
const MechanicsV24 = preload("res://scripts/mechanics_catalog_v23.gd")


func _build_match_overlay() -> void:
	super._build_match_overlay()
	if match_visualizer != null and is_instance_valid(match_visualizer):
		var old := match_visualizer
		var parent := old.get_parent()
		var index := old.get_index()
		if parent != null:
			parent.remove_child(old)
			old.queue_free()
			var replacement := MatchVizV24Ref.new()
			replacement.configure(match_result)
			parent.add_child(replacement)
			parent.move_child(replacement, index)
			match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.34


func _advance_match() -> void:
	super._advance_match()
	if match_timer != null and not match_finished:
		match_timer.wait_time *= 1.10


func _build_home_page() -> void:
	page_content.add_child(_home_stage_v24())

	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 4)
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	quick.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV24.CYAN))
	quick.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV24.GREEN))
	quick.add_child(_metric_block("SPIELE", str(int(record.get("played", 0))), UIV24.GOLD))
	page_content.add_child(quick)

	page_content.add_child(_section_title("LETZTE SPIELE", ""))
	_build_history_list(page_content, 2)


func _home_stage_v24() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV24.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV24.unranked_data(mmr)
	var accent := RankedV24.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV24Ref.new().configure(accent, "home")
	stage.custom_minimum_size.y = 292

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	box.add_child(UIV24.label("E-SPORT EMPIRE  /  ROCKET LEAGUE", 8, Color(accent.r,accent.g,accent.b,0.92), 800))

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV24.label("DEIN RUN", 11, UIV24.MUTED, 800))
	copy.add_child(UIV24.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 32, UIV24.TEXT, 800))
	copy.add_child(UIV24.label("%s  ·  %d/%d PLACEMENTS" % [playlist, placements, 10] if not placed else "%s  ·  %d MMR  ·  DIV %s" % [playlist, mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV24.MUTED, 700))
	copy.add_child(UIV24.v_space(8))
	copy.add_child(UIV24.label("%d SIEGE   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV24.DIM, 700))
	hero.add_child(copy)

	var emblem := RankEmblemV24.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(142, 142)
	hero.add_child(emblem)
	box.add_child(hero)

	if not placed:
		box.add_child(UIV24.progress(placements, 10, accent, 6))
	else:
		var progress := RankedV24.progress_for_mmr(mmr, playlist)
		box.add_child(UIV24.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 6))

	var action := UIV24.button("RANKED STARTEN", accent, true)
	action.custom_minimum_size.y = 50
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return stage


func _origin_card() -> Control:
	return _home_stage_v24()


func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV24.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV24.unranked_data(mmr)
	var accent := RankedV24.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV24Ref.new().configure(accent, "rank")
	stage.custom_minimum_size.y = 252

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var row := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV24.label("%s RANKED" % playlist, 8, Color(accent.r,accent.g,accent.b,0.92), 800))
	copy.add_child(UIV24.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 30, UIV24.TEXT, 800))
	copy.add_child(UIV24.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV24.MUTED, 700))
	copy.add_child(UIV24.v_space(7))
	copy.add_child(UIV24.label("BILANZ  %d–%d   ·   %.1f%% WINRATE" % [int(record.get("wins", 0)), int(record.get("losses", 0)), RankedV24.win_rate(record)], 8, UIV24.DIM, 700))
	row.add_child(copy)
	var emblem := RankEmblemV24.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(138, 138)
	row.add_child(emblem)
	box.add_child(row)

	if not placed:
		box.add_child(UIV24.progress(placements, 10, accent, 6))
	else:
		var progress := RankedV24.progress_for_mmr(mmr, playlist)
		box.add_child(UIV24.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 6))
	return stage


func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var stage := StageV24Ref.new().configure(accent, "player")
	stage.custom_minimum_size.y = 244
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var portrait := PortraitV24.new().configure(str(player.get("name", "SPIELER")), accent)
	portrait.custom_minimum_size = Vector2(120, 142)
	row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(UIV24.label(str(player.get("name", "SPIELER")).to_upper(), 26, UIV24.TEXT, 800))
	copy.add_child(UIV24.label("%s  /  %s  /  %d J." % [str(player.get("role", "SPIELER")).to_upper(), str(player.get("region", "EU")), int(player.get("age", 16))], 8, UIV24.MUTED, 700))
	copy.add_child(UIV24.v_space(8))
	copy.add_child(UIV24.label("%d OVR" % game.player_overall(player), 28, UIV24.TEXT, 800))
	copy.add_child(UIV24.label("POTENZIAL %d" % int(player.get("potential", 99)), 9, UIV24.GREEN, 800))
	row.add_child(copy)
	box.add_child(row)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	stats.add_child(_metric_block("MECH", str(int(player.get("mechanics", 50))), UIV24.CYAN))
	stats.add_child(_metric_block("SHOT", str(int(player.get("shooting", 50))), UIV24.GOLD))
	stats.add_child(_metric_block("DEF", str(int(player.get("defense", 50))), UIV24.GREEN))
	stats.add_child(_metric_block("SENSE", str(int(player.get("game_sense", 50))), UIV24.PURPLE))
	box.add_child(stats)
	return stage


func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)

	var header := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(UIV24.label("PERFORMANCE LAB", 8, UIV24.DIM, 800))
	copy.add_child(UIV24.label(str(player.get("name", "SPIELER")).to_upper(), 24, UIV24.TEXT, 800))
	header.add_child(copy)
	header.add_child(UIV24.badge("GRATIS", UIV24.GREEN))
	root.add_child(header)

	var training := TrainingVizV24Ref.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 5))], UIV24.CYAN))
	status.add_child(_metric_block("MÜDE", str(int(player.get("fatigue", 0))), UIV24.GOLD))
	status.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV24.PURPLE))
	root.add_child(status)

	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size() - 1]
		var mech_id := str(best.get("id", ""))
		var mastery := state.mechanic_mastery(player, mech_id)
		var detail := state.mechanic_components(player, mech_id)
		var mech_row := HBoxContainer.new()
		var name := UIV24.label(str(best.get("label", "MECHANIC")).to_upper(), 10, UIV24.TEXT, 800)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mech_row.add_child(name)
		mech_row.add_child(UIV24.badge("%d%%" % mastery, accent))
		root.add_child(mech_row)
		root.add_child(UIV24.label("SET %d   CTRL %d   READ %d   FIN %d" % [int(detail.get("setup", mastery)), int(detail.get("control", mastery)), int(detail.get("read", mastery)), int(detail.get("finish", mastery))], 8, UIV24.MUTED, 700))

	root.add_child(UIV24.label("DRILL WÄHLEN", 8, UIV24.DIM, 800))
	root.add_child(_training_program_grid(player))

	var upcoming := state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		root.add_child(UIV24.label("NÄCHSTER UNLOCK  ·  %s  ·  %d%%" % [str(next.get("label", "MECHANIC")), MechanicsV24.progress(player, next)], 8, UIV24.MUTED, 700))
	return root
