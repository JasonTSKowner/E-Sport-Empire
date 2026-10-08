extends "res://scripts/cinematic_shell_v243.gd"

const StageV30 = preload("res://scripts/commercial_stage_v30.gd")
const MatchV30 = preload("res://scripts/match_visualizer_v30.gd")
const TrainingV30 = preload("res://scripts/training_visualizer_v30.gd")
const UI30 = preload("res://scripts/ui_kit.gd")
const Ranked30 = preload("res://scripts/ranked_data.gd")
const RankEmblem30 = preload("res://scripts/rank_emblem.gd")
const Portrait30 = preload("res://scripts/player_portrait.gd")
const Mechanics30 = preload("res://scripts/mechanics_catalog_v23.gd")

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
	var replacement := MatchV30.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.62

func _build_home_page() -> void:
	page_content.add_child(_home_v30())
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var pulse := HBoxContainer.new()
	pulse.add_theme_constant_override("separation", 6)
	pulse.add_child(_metric_block("TEAM", "%d OVR" % game.team_overall("Rocket League"), UI30.CYAN))
	pulse.add_child(_metric_block("CHEMIE", "%d%%" % game.team_chemistry("Rocket League"), UI30.GREEN))
	pulse.add_child(_metric_block("FORM", "%d-%d" % [int(record.get("wins",0)),int(record.get("losses",0))], UI30.GOLD))
	page_content.add_child(pulse)
	page_content.add_child(_section_title("MATCH FEED", ""))
	_build_history_list(page_content, 1)

func _home_v30() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr",100))
	var placements := int(record.get("placements",0))
	var placed := placements >= 10
	var actual := Ranked30.rank_for_mmr(mmr,playlist)
	var shown := actual if placed else Ranked30.unranked_data(mmr)
	var accent := Ranked30.color_for_family(str(shown.get("family","Unranked")))
	var stage := StageV30.new().configure(accent,"home")
	stage.custom_minimum_size.y = 392

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",16)
	margin.add_theme_constant_override("margin_right",15)
	margin.add_theme_constant_override("margin_top",15)
	margin.add_theme_constant_override("margin_bottom",16)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",9)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var live := UI30.label("SEASON 1  •  MATCH NIGHT",8,UI30.CYAN,800)
	live.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(live)
	meta.add_child(UI30.badge(playlist,accent))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation",6)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation",0)
	copy.add_child(UI30.label(str(game.data.get("club_name","TSK ESPORTS")).to_upper(),10,UI30.MUTED,800))
	copy.add_child(UI30.label("UNRANKED" if not placed else str(actual.get("tier_name","RANKED")),36,UI30.TEXT,800))
	copy.add_child(UI30.label("%d / 10 PLACEMENTS"%placements if not placed else "%d MMR  •  DIV %s"%[mmr,str(actual.get("division_roman","I"))],10,UI30.MUTED,700))
	copy.add_child(UI30.v_space(10))
	copy.add_child(UI30.label("NEXT UP",7,UI30.DIM,800))
	copy.add_child(UI30.label("PLACEMENT %d"%mini(10,placements+1) if not placed else "RANK PUSH",17,UI30.TEXT,800))
	hero.add_child(copy)
	var emblem := RankEmblem30.new().configure(shown)
	emblem.custom_minimum_size = Vector2(162,162)
	hero.add_child(emblem)
	box.add_child(hero)

	if not placed:
		box.add_child(UI30.progress(placements,10,accent,7))
	else:
		var progress := Ranked30.progress_for_mmr(mmr,playlist)
		box.add_child(UI30.progress(float(progress.get("value",0)),float(progress.get("maximum",1)),accent,7))

	var action := UI30.button("RANKED MATCH STARTEN",accent,true)
	action.custom_minimum_size.y = 56
	action.pressed.connect(_show_page.bind("play",true))
	box.add_child(action)
	return stage

func _origin_card() -> Control:
	return _home_v30()

func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr",100))
	var placements := int(record.get("placements",0))
	var placed := placements >= 10
	var actual := Ranked30.rank_for_mmr(mmr,playlist)
	var shown := actual if placed else Ranked30.unranked_data(mmr)
	var accent := Ranked30.color_for_family(str(shown.get("family","Unranked")))
	var stage := StageV30.new().configure(accent,"rank")
	stage.custom_minimum_size.y = 330

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",16)
	margin.add_theme_constant_override("margin_right",14)
	margin.add_theme_constant_override("margin_top",14)
	margin.add_theme_constant_override("margin_bottom",14)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	margin.add_child(box)

	var top := HBoxContainer.new()
	var title := UI30.label("COMPETITIVE  •  %s"%playlist,8,UI30.CYAN,800)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	top.add_child(UI30.badge("QUEUE READY",UI30.GREEN))
	box.add_child(top)

	var hero := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation",1)
	copy.add_child(UI30.label("UNRANKED" if not placed else str(actual.get("tier_name","RANKED")),34,UI30.TEXT,800))
	copy.add_child(UI30.label("%d / 10 PLACEMENTS"%placements if not placed else "%d MMR  •  DIV %s"%[mmr,str(actual.get("division_roman","I"))],10,UI30.MUTED,700))
	copy.add_child(UI30.v_space(10))
	copy.add_child(UI30.label("%d W   %d L"%[int(record.get("wins",0)),int(record.get("losses",0))],11,UI30.TEXT,800))
	copy.add_child(UI30.label("%.1f%% WINRATE"%Ranked30.win_rate(record),8,UI30.DIM,700))
	hero.add_child(copy)
	var emblem := RankEmblem30.new().configure(shown)
	emblem.custom_minimum_size = Vector2(164,164)
	hero.add_child(emblem)
	box.add_child(hero)
	if not placed:
		box.add_child(UI30.progress(placements,10,accent,7))
	else:
		var progress := Ranked30.progress_for_mmr(mmr,playlist)
		box.add_child(UI30.progress(float(progress.get("value",0)),float(progress.get("maximum",1)),accent,7))
	return stage

func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var stage := StageV30.new().configure(accent,"player")
	stage.custom_minimum_size.y = 314
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",14)
	margin.add_theme_constant_override("margin_right",14)
	margin.add_theme_constant_override("margin_top",14)
	margin.add_theme_constant_override("margin_bottom",14)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",9)
	margin.add_child(box)

	var tag := HBoxContainer.new()
	var tag_text := UI30.label("STARTING ROSTER  •  ROCKET LEAGUE",8,UI30.CYAN,800)
	tag_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.add_child(tag_text)
	tag.add_child(UI30.badge("ACTIVE",UI30.GREEN))
	box.add_child(tag)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation",12)
	var portrait := Portrait30.new().configure(str(player.get("name","SPIELER")),accent)
	portrait.custom_minimum_size = Vector2(132,158)
	hero.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation",1)
	identity.add_child(UI30.label(str(player.get("name","SPIELER")).to_upper(),28,UI30.TEXT,800))
	identity.add_child(UI30.label("%s  •  %s  •  %d J."%[str(player.get("role","SPIELER")).to_upper(),str(player.get("region","EU")),int(player.get("age",16))],8,UI30.MUTED,700))
	identity.add_child(UI30.v_space(9))
	identity.add_child(UI30.label("%d OVR"%game.player_overall(player),31,UI30.TEXT,800))
	identity.add_child(UI30.label("POTENZIAL %d"%int(player.get("potential",99)),9,UI30.GREEN,800))
	hero.add_child(identity)
	box.add_child(hero)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation",5)
	stats.add_child(_metric_block("MECH",str(int(player.get("mechanics",50))),UI30.CYAN))
	stats.add_child(_metric_block("SHOT",str(int(player.get("shooting",50))),UI30.GOLD))
	stats.add_child(_metric_block("DEF",str(int(player.get("defense",50))),UI30.GREEN))
	stats.add_child(_metric_block("SENSE",str(int(player.get("game_sense",50))),UI30.PURPLE))
	box.add_child(stats)
	return stage

func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var stage := StageV30.new().configure(accent,"scout")
	stage.custom_minimum_size.y = 286
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",14)
	margin.add_theme_constant_override("margin_right",14)
	margin.add_theme_constant_override("margin_top",12)
	margin.add_theme_constant_override("margin_bottom",13)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	margin.add_child(box)
	var top := HBoxContainer.new()
	var report := UI30.label("SCOUTING  •  LIVE REPORT",8,UI30.CYAN,800)
	report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(report)
	top.add_child(UI30.badge("%d POT"%int(player.get("potential",50)),UI30.GREEN))
	box.add_child(top)
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation",10)
	var portrait := Portrait30.new().configure(str(player.get("name","SPIELER")),accent)
	portrait.custom_minimum_size = Vector2(110,130)
	hero.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(UI30.label(str(player.get("name","SPIELER")).to_upper(),24,UI30.TEXT,800))
	copy.add_child(UI30.label("%s  •  %s  •  %d J."%[str(player.get("role","SPIELER")).to_upper(),str(player.get("region","EU")),int(player.get("age",16))],8,UI30.MUTED,700))
	copy.add_child(UI30.v_space(8))
	copy.add_child(UI30.label("%d OVR"%game.player_overall(player),28,UI30.TEXT,800))
	hero.add_child(copy)
	box.add_child(hero)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation",4)
	stats.add_child(_metric_block("MECH",str(int(player.get("mechanics",50))),UI30.CYAN))
	stats.add_child(_metric_block("ROT",str(int(player.get("rotation",50))),UI30.PURPLE))
	stats.add_child(_metric_block("SHOT",str(int(player.get("shooting",50))),UI30.GOLD))
	stats.add_child(_metric_block("DEF",str(int(player.get("defense",50))),UI30.GREEN))
	box.add_child(stats)
	var price := int(player.get("contract",0))
	var sign := UI30.button("VERPFLICHTEN  •  %s"%ShellGameData.format_cash(price),accent,true)
	sign.disabled = int(game.data.get("cash",0)) < price
	sign.custom_minimum_size.y = 48
	sign.pressed.connect(_sign_player.bind(str(player.get("id",""))))
	box.add_child(sign)
	return stage

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UI30.label("PERFORMANCE LAB",8,UI30.CYAN,800))
	identity.add_child(UI30.label(str(player.get("name","SPIELER")).to_upper(),25,UI30.TEXT,800))
	header.add_child(identity)
	header.add_child(UI30.badge("LIVE",UI30.GREEN))
	root.add_child(header)
	var training := TrainingV30.new()
	training.configure(player,readiness,accent)
	root.add_child(training)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation",4)
	status.add_child(_metric_block("FOKUS","%d/%d"%[int(readiness.get("slots_remaining",0)),int(readiness.get("limit",5))],UI30.CYAN))
	status.add_child(_metric_block("MÜDE",str(int(player.get("fatigue",0))),UI30.GOLD))
	status.add_child(_metric_block("SETUP","%d%%"%state.setup_rating(),UI30.PURPLE))
	root.add_child(status)
	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size()-1]
		var mech_id := str(best.get("id",""))
		var mastery := state.mechanic_mastery(player,mech_id)
		var detail := state.mechanic_components(player,mech_id)
		root.add_child(UI30.label("SIGNATURE  •  %s  •  %d%%"%[str(best.get("label","MECHANIC")).to_upper(),mastery],10,UI30.TEXT,800))
		root.add_child(UI30.label("SET %d   CTRL %d   READ %d   FIN %d"%[int(detail.get("setup",mastery)),int(detail.get("control",mastery)),int(detail.get("read",mastery)),int(detail.get("finish",mastery))],8,UI30.MUTED,700))
	root.add_child(UI30.label("DRILL WÄHLEN",8,UI30.DIM,800))
	root.add_child(_training_program_grid(player))
	return root
