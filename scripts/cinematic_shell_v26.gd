extends "res://scripts/cinematic_shell_v25.gd"

const MatchVizV26Ref = preload("res://scripts/match_visualizer_v26.gd")
const TrainingVizV26Ref = preload("res://scripts/training_visualizer_v26.gd")
const StageV26Ref = preload("res://scripts/visual_stage_v26.gd")
const UIV26 = preload("res://scripts/ui_kit.gd")
const RankedV26 = preload("res://scripts/ranked_data.gd")
const RankEmblemV26 = preload("res://scripts/rank_emblem.gd")
const MechanicsV26 = preload("res://scripts/mechanics_catalog_v23.gd")

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
	var replacement := MatchVizV26Ref.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.86

func _build_home_page() -> void:
	page_content.add_child(_home_hero_v243())

func _home_hero_v243() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV26.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV26.unranked_data(mmr)
	var accent := RankedV26.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV26Ref.new().configure(accent, "home")
	stage.custom_minimum_size.y = 610

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV26.label("SEASON 1  /  ROCKET LEAGUE", 8, UIV26.CYAN, 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV26.badge(playlist, UIV26.CYAN))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 4)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV26.label("DEIN COMPETITIVE RUN", 9, UIV26.MUTED, 800))
	copy.add_child(UIV26.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 36, UIV26.TEXT, 800))
	copy.add_child(UIV26.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 10, UIV26.MUTED, 700))
	copy.add_child(UIV26.v_space(10))
	copy.add_child(UIV26.label("%d SIEGE   ·   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV26.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblemV26.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(166, 166)
	hero.add_child(emblem)
	box.add_child(hero)

	box.add_child(UIV26.v_space(34))
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV26.CYAN))
	status.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV26.GREEN))
	status.add_child(_metric_block("SPIELE", str(int(record.get("played", 0))), UIV26.GOLD))
	box.add_child(status)

	var objective := HBoxContainer.new()
	objective.add_theme_constant_override("separation", 8)
	var objective_copy := VBoxContainer.new()
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.add_theme_constant_override("separation", 0)
	objective_copy.add_child(UIV26.label("NÄCHSTES ZIEL", 7, UIV26.DIM, 800))
	objective_copy.add_child(UIV26.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "NÄCHSTEN RANK ANGRIFFEN", 14, UIV26.TEXT, 800))
	objective.add_child(objective_copy)
	objective.add_child(UIV26.badge("%d/10" % mini(placements, 10) if not placed else "%d MMR" % mmr, accent))
	box.add_child(objective)

	if not placed:
		box.add_child(UIV26.progress(placements, 10, accent, 7))
	else:
		var progress := RankedV26.progress_for_mmr(mmr, playlist)
		box.add_child(UIV26.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 7))

	var action := UIV26.button("MATCH STARTEN", accent, true)
	action.custom_minimum_size.y = 56
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return stage

func _origin_card() -> Control:
	return _home_hero_v243()

func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV26.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV26.unranked_data(mmr)
	var accent := RankedV26.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV26Ref.new().configure(accent, "rank")
	stage.custom_minimum_size.y = 350

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var top := HBoxContainer.new()
	var tag := UIV26.label("COMPETITIVE  /  %s" % playlist, 8, UIV26.CYAN, 800)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	top.add_child(UIV26.badge("BEREIT", UIV26.GREEN))
	box.add_child(top)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV26.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 34, UIV26.TEXT, 800))
	copy.add_child(UIV26.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV26.MUTED, 700))
	copy.add_child(UIV26.v_space(8))
	copy.add_child(UIV26.label("BILANZ %d–%d" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV26.DIM, 700))
	copy.add_child(UIV26.label("WINRATE %.1f%%" % RankedV26.win_rate(record), 9, UIV26.DIM, 700))
	row.add_child(copy)
	var emblem := RankEmblemV26.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(162, 162)
	row.add_child(emblem)
	box.add_child(row)
	if not placed:
		box.add_child(UIV26.progress(placements, 10, accent, 7))
	else:
		var progress := RankedV26.progress_for_mmr(mmr, playlist)
		box.add_child(UIV26.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 7))
	return stage

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	identity.add_child(UIV26.label("PERFORMANCE LAB", 7, UIV26.DIM, 800))
	identity.add_child(UIV26.label(str(player.get("name", "SPIELER")).to_upper(), 25, UIV26.TEXT, 800))
	header.add_child(identity)
	header.add_child(UIV26.badge("LIVE", accent))
	root.add_child(header)

	var training := TrainingVizV26Ref.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 5))], UIV26.CYAN))
	status.add_child(_metric_block("MÜDE", str(int(player.get("fatigue", 0))), UIV26.GOLD))
	status.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV26.PURPLE))
	root.add_child(status)

	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size() - 1]
		var mech_id := str(best.get("id", ""))
		var mastery := state.mechanic_mastery(player, mech_id)
		var detail := state.mechanic_components(player, mech_id)
		var mastery_row := HBoxContainer.new()
		var mech_name := UIV26.label(str(best.get("label", "MECHANIC")).to_upper(), 9, UIV26.TEXT, 800)
		mech_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mastery_row.add_child(mech_name)
		mastery_row.add_child(UIV26.badge("%d%%" % mastery, accent))
		root.add_child(mastery_row)
		root.add_child(UIV26.label("SET %d   CTRL %d   READ %d   FIN %d" % [int(detail.get("setup", mastery)), int(detail.get("control", mastery)), int(detail.get("read", mastery)), int(detail.get("finish", mastery))], 8, UIV26.MUTED, 700))

	root.add_child(UIV26.label("DRILL WÄHLEN", 7, UIV26.DIM, 800))
	root.add_child(_training_program_grid(player))
	var upcoming := state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		root.add_child(UIV26.label("NÄCHSTER UNLOCK  ·  %s  ·  %d%%" % [str(next.get("label", "MECHANIC")), MechanicsV26.progress(player, next)], 8, UIV26.MUTED, 700))
	return root
