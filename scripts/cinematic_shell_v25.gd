extends "res://scripts/cinematic_shell_v243.gd"

const MatchVizV25 = preload("res://scripts/match_visualizer_v25.gd")
const TrainingVizV25 = preload("res://scripts/training_visualizer_v25.gd")
const StageV25 = preload("res://scripts/visual_stage_v25.gd")
const UIV25 = preload("res://scripts/ui_kit.gd")
const RankedV25 = preload("res://scripts/ranked_data.gd")
const RankEmblemV25 = preload("res://scripts/rank_emblem.gd")
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
	var replacement := MatchVizV25.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.62

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	identity.add_child(UIV25.label("PERFORMANCE LAB", 8, UIV25.DIM, 800))
	identity.add_child(UIV25.label(str(player.get("name", "SPIELER")).to_upper(), 25, UIV25.TEXT, 800))
	header.add_child(identity)
	header.add_child(UIV25.badge("LIVE DRILL", accent))
	root.add_child(header)

	var training := TrainingVizV25.new()
	training.configure(player, readiness, accent)
	root.add_child(training)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("FOKUS", "%d/%d" % [int(readiness.get("slots_remaining", 0)), int(readiness.get("limit", 5))], UIV25.CYAN))
	status.add_child(_metric_block("MÜDE", str(int(player.get("fatigue", 0))), UIV25.GOLD))
	status.add_child(_metric_block("SETUP", "%d%%" % state.setup_rating(), UIV25.PURPLE))
	root.add_child(status)

	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size() - 1]
		var mech_id := str(best.get("id", ""))
		var mastery := state.mechanic_mastery(player, mech_id)
		var detail := state.mechanic_components(player, mech_id)
		var mastery_row := HBoxContainer.new()
		var mech_name := UIV25.label(str(best.get("label", "MECHANIC")).to_upper(), 10, UIV25.TEXT, 800)
		mech_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mastery_row.add_child(mech_name)
		mastery_row.add_child(UIV25.badge("%d%%" % mastery, accent))
		root.add_child(mastery_row)
		root.add_child(UIV25.label(
			"SET %d   CTRL %d   READ %d   FIN %d" % [
				int(detail.get("setup", mastery)), int(detail.get("control", mastery)),
				int(detail.get("read", mastery)), int(detail.get("finish", mastery))
			], 8, UIV25.MUTED, 700
		))

	root.add_child(UIV25.label("DRILL WÄHLEN", 8, UIV25.DIM, 800))
	root.add_child(_training_program_grid(player))

	var upcoming := state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		root.add_child(UIV25.label(
			"NÄCHSTER UNLOCK  ·  %s  ·  %d%%" % [str(next.get("label", "MECHANIC")), MechanicsV25.progress(player, next)],
			8, UIV25.MUTED, 700
		))
	return root

func _home_hero_v243() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV25.unranked_data(mmr)
	var rank_accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV25.new().configure(rank_accent, "home")
	stage.custom_minimum_size.y = 364

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV25.label("SEASON 1  /  ROCKET LEAGUE", 8, UIV25.CYAN, 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV25.badge("%s" % playlist, UIV25.CYAN))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV25.label("DEIN COMPETITIVE RUN", 9, UIV25.MUTED, 800))
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 34, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(8))
	copy.add_child(UIV25.label("%d SIEGE   ·   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV25.DIM, 700))
	hero.add_child(copy)

	var emblem := RankEmblemV25.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(154, 154)
	hero.add_child(emblem)
	box.add_child(hero)

	var objective := HBoxContainer.new()
	objective.add_theme_constant_override("separation", 8)
	var objective_copy := VBoxContainer.new()
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.add_theme_constant_override("separation", 0)
	objective_copy.add_child(UIV25.label("NÄCHSTES ZIEL", 7, UIV25.DIM, 800))
	objective_copy.add_child(UIV25.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "RANK PUSH STARTEN", 13, UIV25.TEXT, 800))
	objective.add_child(objective_copy)
	objective.add_child(UIV25.badge("%d/10" % mini(placements, 10) if not placed else "%d MMR" % mmr, rank_accent))
	box.add_child(objective)

	if not placed:
		box.add_child(UIV25.progress(placements, 10, UIV25.CYAN, 6))
	else:
		var progress := RankedV25.progress_for_mmr(mmr, playlist)
		box.add_child(UIV25.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), UIV25.CYAN, 6))

	var action := UIV25.button("MATCH STARTEN", UIV25.CYAN, true)
	action.custom_minimum_size.y = 52
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return stage

func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV25.new().configure(accent, "rank")
	stage.custom_minimum_size.y = 286

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var top := HBoxContainer.new()
	var tag := UIV25.label("COMPETITIVE  /  %s" % playlist, 8, UIV25.CYAN, 800)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	top.add_child(UIV25.badge("BEREIT", UIV25.GREEN))
	box.add_child(top)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 32, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV25.MUTED, 700))
	copy.add_child(UIV25.v_space(9))
	copy.add_child(UIV25.label("BILANZ  %d–%d" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV25.DIM, 700))
	copy.add_child(UIV25.label("WINRATE %.1f%%" % RankedV25.win_rate(record), 9, UIV25.DIM, 700))
	row.add_child(copy)
	var emblem := RankEmblemV25.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(150, 150)
	row.add_child(emblem)
	box.add_child(row)

	if not placed:
		box.add_child(UIV25.progress(placements, 10, UIV25.CYAN, 6))
	else:
		var progress := RankedV25.progress_for_mmr(mmr, playlist)
		box.add_child(UIV25.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), UIV25.CYAN, 6))
	return stage
