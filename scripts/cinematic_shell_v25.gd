extends "res://scripts/cinematic_shell_v243.gd"

const Arena3DRef = preload("res://scripts/arena_3d_stage.gd")
const MatchVizV25Ref = preload("res://scripts/match_visualizer_v25.gd")
const TrainingVizV25Ref = preload("res://scripts/training_visualizer_v25.gd")
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
	var replacement := MatchVizV25Ref.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.60


func _build_home_page() -> void:
	page_content.add_child(_home_3d_hero_v25())
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	var record := game.playlist_record(game.selected_rl_playlist())
	strip.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UIV25.CYAN))
	strip.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UIV25.GREEN))
	strip.add_child(_metric_block("SPIELE", str(int(record.get("played", 0))), UIV25.GOLD))
	page_content.add_child(strip)


func _home_3d_hero_v25() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV25.unranked_data(mmr)
	var rank_accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))

	var root := Control.new()
	root.custom_minimum_size.y = 430
	root.clip_contents = true

	var arena := Arena3DRef.new()
	arena.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena.offset_left = 0
	arena.offset_top = 0
	arena.offset_right = 0
	arena.offset_bottom = 0
	arena.configure_team_count(1)
	arena.set_match_state(
		[Vector2(0.34,0.68)], [Vector2(0.72,0.34)],
		[Vector2(0.06,-0.02)], [Vector2(-0.04,0.02)],
		[Vector2(0.48,0.52)], Vector2(0.54,0.48), 0.18,
		Vector2(0.72,0.42), 0.42, 0, -1, "buildup", 0.0
	)
	root.add_child(arena)

	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_top = 12
	top.offset_right = -12
	top.offset_bottom = 96
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top.add_child(top_row)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", -2)
	brand.add_child(UIV25.label("E-SPORT EMPIRE", 11, UIV25.TEXT, 800))
	brand.add_child(UIV25.label("ROCKET LEAGUE  /  SEASON 1", 7, UIV25.CYAN, 800))
	top_row.add_child(brand)
	top_row.add_child(UIV25.badge(playlist, UIV25.CYAN))

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 10
	bottom.offset_top = -172
	bottom.offset_right = -10
	bottom.offset_bottom = -10
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012,0.018,0.027,0.91)
	style.border_width_top = 1
	style.border_color = Color(rank_accent.r,rank_accent.g,rank_accent.b,0.24)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	bottom.add_theme_stylebox_override("panel", style)
	root.add_child(bottom)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	bottom.add_child(box)
	var row := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", -1)
	copy.add_child(UIV25.label("COMPETITIVE RUN", 8, UIV25.MUTED, 800))
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 28, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 9, UIV25.MUTED, 700))
	row.add_child(copy)
	var emblem := RankEmblemV25.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(92,92)
	row.add_child(emblem)
	box.add_child(row)

	var action := UIV25.button("MATCH STARTEN", rank_accent, true)
	action.custom_minimum_size.y = 48
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)
	return root


func _origin_card() -> Control:
	return _home_3d_hero_v25()


func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var rank_data := RankedV25.rank_for_mmr(mmr, playlist)
	var shown_rank := rank_data if placed else RankedV25.unranked_data(mmr)
	var accent := RankedV25.color_for_family(str(shown_rank.get("family", "Unranked")))

	var root := Control.new()
	root.custom_minimum_size.y = 340
	root.clip_contents = true
	var arena := Arena3DRef.new()
	arena.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena.offset_left = 0
	arena.offset_top = 0
	arena.offset_right = 0
	arena.offset_bottom = 0
	arena.configure_team_count(1)
	arena.set_match_state(
		[Vector2(0.38,0.62)], [Vector2(0.68,0.38)],
		[Vector2(0.05,-0.02)], [Vector2(-0.04,0.02)],
		[Vector2(0.56,0.50)], Vector2(0.58,0.46), 0.24,
		Vector2(0.82,0.45), 0.50, 0, -1, "challenge", 0.0
	)
	root.add_child(arena)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 10
	panel.offset_top = -146
	panel.offset_right = -10
	panel.offset_bottom = -10
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012,0.018,0.027,0.92)
	style.border_width_top = 1
	style.border_color = Color(accent.r,accent.g,accent.b,0.22)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", -1)
	copy.add_child(UIV25.label("%s RANKED" % playlist, 8, UIV25.CYAN, 800))
	copy.add_child(UIV25.label("UNRANKED" if not placed else str(rank_data.get("tier_name", "RANKED")), 27, UIV25.TEXT, 800))
	copy.add_child(UIV25.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(rank_data.get("division_roman", "I"))], 9, UIV25.MUTED, 700))
	copy.add_child(UIV25.label("%d–%d  ·  %.1f%% WINRATE" % [int(record.get("wins",0)), int(record.get("losses",0)), RankedV25.win_rate(record)], 8, UIV25.DIM, 700))
	row.add_child(copy)
	var emblem := RankEmblemV25.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(100,100)
	row.add_child(emblem)
	return root


func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)

	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", -1)
	identity.add_child(UIV25.label("PERFORMANCE LAB", 8, UIV25.CYAN, 800))
	identity.add_child(UIV25.label(str(player.get("name", "SPIELER")).to_upper(), 24, UIV25.TEXT, 800))
	header.add_child(identity)
	header.add_child(UIV25.badge("3D SESSION", accent))
	root.add_child(header)

	var training := TrainingVizV25Ref.new()
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
		root.add_child(UIV25.label(
			"%s  %d%%   ·   SET %d   CTRL %d   READ %d   FIN %d" % [
				str(best.get("label", "MECHANIC")).to_upper(), mastery,
				int(detail.get("setup", mastery)), int(detail.get("control", mastery)),
				int(detail.get("read", mastery)), int(detail.get("finish", mastery))
			], 8, UIV25.MUTED, 700
		))

	root.add_child(UIV25.label("DRILL WÄHLEN", 8, UIV25.DIM, 800))
	root.add_child(_training_program_grid(player))
	var upcoming := state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		root.add_child(UIV25.label("NÄCHSTER UNLOCK  ·  %s  ·  %d%%" % [str(next.get("label", "MECHANIC")), MechanicsV25.progress(player, next)], 8, UIV25.MUTED, 700))
	return root
