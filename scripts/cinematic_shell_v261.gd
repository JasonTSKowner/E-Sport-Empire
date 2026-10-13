extends "res://scripts/cinematic_shell_v26.gd"

const UIV261 = preload("res://scripts/ui_kit.gd")
const RankedV261 = preload("res://scripts/ranked_data.gd")
const RankEmblemV261 = preload("res://scripts/rank_emblem.gd")
const StageV261 = preload("res://scripts/visual_stage_v26.gd")

func _home_hero_v243() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV261.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV261.unranked_data(mmr)
	var accent := RankedV261.color_for_family(str(shown_rank.get("family", "Unranked")))
	var stage := StageV261.new().configure(accent, "home")
	stage.custom_minimum_size.y = 610

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	stage.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV261.label("SEASON 1  /  ROCKET LEAGUE", 8, UIV261.CYAN, 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV261.badge(playlist, UIV261.CYAN))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 4)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV261.label("DEIN COMPETITIVE RUN", 9, UIV261.MUTED, 800))
	copy.add_child(UIV261.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 36, UIV261.TEXT, 800))
	copy.add_child(UIV261.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 10, UIV261.MUTED, 700))
	copy.add_child(UIV261.v_space(10))
	copy.add_child(UIV261.label("%d SIEGE   ·   %d NIEDERLAGEN" % [int(record.get("wins", 0)), int(record.get("losses", 0))], 9, UIV261.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblemV261.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(166, 166)
	hero.add_child(emblem)
	box.add_child(hero)

	# Let the perspective arena breathe through the middle instead of leaving dead space below the CTA.
	box.add_child(UIV261.v_space(116))

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV261.CYAN))
	status.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV261.GREEN))
	status.add_child(_metric_block("SPIELE", str(int(record.get("played", 0))), UIV261.GOLD))
	box.add_child(status)

	var objective := HBoxContainer.new()
	objective.add_theme_constant_override("separation", 8)
	var objective_copy := VBoxContainer.new()
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.add_theme_constant_override("separation", 0)
	objective_copy.add_child(UIV261.label("NÄCHSTES ZIEL", 7, UIV261.DIM, 800))
	objective_copy.add_child(UIV261.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "NÄCHSTEN RANK ANGRIFFEN", 14, UIV261.TEXT, 800))
	objective.add_child(objective_copy)
	objective.add_child(UIV261.badge("%d/10" % mini(placements, 10) if not placed else "%d MMR" % mmr, accent))
	box.add_child(objective)

	if not placed:
		box.add_child(UIV261.progress(placements, 10, accent, 7))
	else:
		var progress := RankedV261.progress_for_mmr(mmr, playlist)
		box.add_child(UIV261.progress(float(progress.get("value", 0)), float(progress.get("maximum", 1)), accent, 7))

	var action := UIV261.button("MATCH STARTEN", accent, true)
	action.custom_minimum_size.y = 56
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return stage
