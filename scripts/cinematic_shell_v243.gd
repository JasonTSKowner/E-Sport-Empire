extends "res://scripts/cinematic_shell_v241.gd"

const StageV243 = preload("res://scripts/visual_stage_v243.gd")
const UIV243 = preload("res://scripts/ui_kit.gd")
const RankedV243 = preload("res://scripts/ranked_data.gd")
const RankEmblemV243 = preload("res://scripts/rank_emblem.gd")

func _build_home_page() -> void:
	page_content.add_child(_home_hero_v243())

	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	strip.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV243.CYAN))
	strip.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV243.GREEN))
	strip.add_child(_metric_block("SPIELE", str(int(record.get("played", 0))), UIV243.GOLD))
	page_content.add_child(strip)

	page_content.add_child(_section_title("LETZTES SPIEL", ""))
	_build_history_list(page_content, 1)

func _home_hero_v243() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV243.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV243.unranked_data(mmr)
	var rank_accent := RankedV243.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV243.new().configure(rank_accent, "home")
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
	var season := UIV243.label("SEASON 1  /  ROCKET LEAGUE", 8, UIV243.CYAN, 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV243.badge("%s" % playlist, UIV243.CYAN))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV243.label("DEIN COMPETITIVE RUN", 9, UIV243.MUTED, 800))
	copy.add_child(UIV243.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 34, UIV243.TEXT, 800))
	copy.add_child(UIV243.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 10, UIV243.MUTED, 700))
	copy.add_child(UIV243.v_space(8))
	copy.add_child(UIV243.label("%d SIEGE   ·   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV243.DIM, 700))
	hero.add_child(copy)

	var emblem := RankEmblemV243.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(154, 154)
	hero.add_child(emblem)
	box.add_child(hero)

	var objective := HBoxContainer.new()
	objective.add_theme_constant_override("separation", 8)
	var objective_copy := VBoxContainer.new()
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.add_theme_constant_override("separation", 0)
	objective_copy.add_child(UIV243.label("NÄCHSTES ZIEL", 7, UIV243.DIM, 800))
	objective_copy.add_child(UIV243.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "RANK PUSH STARTEN", 13, UIV243.TEXT, 800))
	objective.add_child(objective_copy)
	objective.add_child(UIV243.badge("%d/10" % mini(placements, 10) if not placed else "%d MMR" % mmr, rank_accent))
	box.add_child(objective)

	if not placed:
		box.add_child(UIV243.progress(placements, 10, UIV243.CYAN, 6))
	else:
		var progress := RankedV243.progress_for_mmr(mmr, playlist)
		box.add_child(UIV243.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), UIV243.CYAN, 6))

	var action := UIV243.button("MATCH STARTEN", UIV243.CYAN, true)
	action.custom_minimum_size.y = 52
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
	var actual_rank := RankedV243.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV243.unranked_data(mmr)
	var accent := RankedV243.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV243.new().configure(accent, "rank")
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
	var tag := UIV243.label("COMPETITIVE  /  %s" % playlist, 8, UIV243.CYAN, 800)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	top.add_child(UIV243.badge("BEREIT", UIV243.GREEN))
	box.add_child(top)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UIV243.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 32, UIV243.TEXT, 800))
	copy.add_child(UIV243.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 10, UIV243.MUTED, 700))
	copy.add_child(UIV243.v_space(9))
	copy.add_child(UIV243.label("BILANZ  %d–%d" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV243.DIM, 700))
	copy.add_child(UIV243.label("WINRATE %.1f%%" % RankedV243.win_rate(record), 9, UIV243.DIM, 700))
	row.add_child(copy)
	var emblem := RankEmblemV243.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(150, 150)
	row.add_child(emblem)
	box.add_child(row)

	if not placed:
		box.add_child(UIV243.progress(placements, 10, UIV243.CYAN, 6))
	else:
		var progress := RankedV243.progress_for_mmr(mmr, playlist)
		box.add_child(UIV243.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), UIV243.CYAN, 6))
	return stage
