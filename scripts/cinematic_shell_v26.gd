extends "res://scripts/cinematic_shell_v25.gd"

const MatchVizV26Ref = preload("res://scripts/match_visualizer_v26.gd")
const TrainingVizV26Ref = preload("res://scripts/training_visualizer_v26.gd")
const WorldStageV26Ref = preload("res://scripts/world_stage_v26.gd")
const PlayerV26Ref = preload("res://scripts/player_presentation_v26.gd")
const RadarV26Ref = preload("res://scripts/stat_radar_v26.gd")
const UIV26 = preload("res://scripts/ui_kit.gd")
const RankedV26 = preload("res://scripts/ranked_data.gd")
const RankEmblemV26 = preload("res://scripts/rank_emblem.gd")
const GameDataV26 = preload("res://scripts/game_data.gd")
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
	parent.move_child(replacement,index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.92

func _build_home_page() -> void:
	page_content.add_child(_home_world_v26())
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation",4)
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	strip.add_child(_metric_block("TEAM","%d OVR"%game.team_overall("Rocket League"),UIV26.CYAN))
	strip.add_child(_metric_block("CHEMIE","%d%%"%game.team_chemistry("Rocket League"),UIV26.GREEN))
	strip.add_child(_metric_block("SPIELE",str(int(record.get("played",0))),UIV26.GOLD))
	page_content.add_child(strip)
	page_content.add_child(_section_title("LETZTES SPIEL",""))
	_build_history_list(page_content,1)

func _home_world_v26() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr",100))
	var placements := int(record.get("placements",0))
	var placed := placements>=10
	var rank_data := RankedV26.rank_for_mmr(mmr,playlist)
	var shown_rank := rank_data if placed else RankedV26.unranked_data(mmr)
	var accent := RankedV26.color_for_family(str(shown_rank.get("family","Unranked")))
	var stage := WorldStageV26Ref.new().configure(accent,"home")

	var margin := MarginContainer.new()
	for entry in [["margin_left",15],["margin_right",14],["margin_top",14],["margin_bottom",14]]:
		margin.add_theme_constant_override(entry[0],entry[1])
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",7)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV26.label("SEASON 1  /  ROCKET LEAGUE",8,UIV26.CYAN,800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV26.badge(playlist,accent))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation",5)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation",0)
	copy.add_child(UIV26.label("DEIN COMPETITIVE RUN",8,UIV26.MUTED,800))
	copy.add_child(UIV26.label("UNRANKED" if not placed else str(rank_data.get("tier_name","RANKED")),33,UIV26.TEXT,800))
	copy.add_child(UIV26.label("%d / 10 PLACEMENTS"%placements if not placed else "%d MMR  ·  DIV %s"%[mmr,str(rank_data.get("division_roman","I"))],10,UIV26.MUTED,700))
	copy.add_child(UIV26.v_space(9))
	copy.add_child(UIV26.label("%d SIEGE  ·  %d NIEDERLAGEN"%[int(record.get("wins",0)),int(record.get("losses",0))],9,UIV26.DIM,700))
	hero.add_child(copy)

	var visual := Control.new()
	visual.custom_minimum_size = Vector2(152,184)
	var roster := game.roster_for("Rocket League")
	if not roster.is_empty():
		var captain: Dictionary = roster[0]
		var person := PlayerV26Ref.new().configure(str(captain.get("name","KESHI")),accent,game.player_overall(captain),int(captain.get("potential",99)),"hero")
		person.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		visual.add_child(person)
	var emblem := RankEmblemV26.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(72,72)
	emblem.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	emblem.offset_left = -76
	emblem.offset_right = -4
	emblem.offset_top = 2
	emblem.offset_bottom = 74
	visual.add_child(emblem)
	hero.add_child(visual)
	box.add_child(hero)

	var objective := HBoxContainer.new()
	var ocopy := VBoxContainer.new()
	ocopy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ocopy.add_theme_constant_override("separation",0)
	ocopy.add_child(UIV26.label("NÄCHSTES ZIEL",7,UIV26.DIM,800))
	ocopy.add_child(UIV26.label("PLACEMENT %d ABSCHLIESSEN"%mini(10,placements+1) if not placed else "RANK PUSH STARTEN",13,UIV26.TEXT,800))
	objective.add_child(ocopy)
	objective.add_child(UIV26.badge("%d/10"%mini(placements,10) if not placed else "%d MMR"%mmr,accent))
	box.add_child(objective)
	if not placed:
		box.add_child(UIV26.progress(placements,10,accent,6))
	else:
		var progress := RankedV26.progress_for_mmr(mmr,playlist)
		box.add_child(UIV26.progress(float(progress.get("value",0)),float(progress.get("maximum",1)),accent,6))
	var action := UIV26.button("MATCH STARTEN",accent,true)
	action.custom_minimum_size.y=52
	action.pressed.connect(_show_page.bind("play",true))
	box.add_child(action)
	return stage

func _origin_card() -> Control:
	return _home_world_v26()

func _rank_profile_card(playlist: String) -> Control:
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr",100))
	var placements := int(record.get("placements",0))
	var placed := placements>=10
	var actual := RankedV26.rank_for_mmr(mmr,playlist)
	var shown := actual if placed else RankedV26.unranked_data(mmr)
	var accent := RankedV26.color_for_family(str(shown.get("family","Unranked")))
	var stage := WorldStageV26Ref.new().configure(accent,"rank")
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",15)
	margin.add_theme_constant_override("margin_right",14)
	margin.add_theme_constant_override("margin_top",13)
	margin.add_theme_constant_override("margin_bottom",12)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",7)
	margin.add_child(box)
	var top := HBoxContainer.new()
	var tag := UIV26.label("COMPETITIVE  /  %s"%playlist,8,UIV26.CYAN,800)
	tag.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	top.add_child(UIV26.badge("BEREIT",UIV26.GREEN))
	box.add_child(top)
	var row := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation",0)
	copy.add_child(UIV26.label("UNRANKED" if not placed else str(actual.get("tier_name","RANKED")),32,UIV26.TEXT,800))
	copy.add_child(UIV26.label("%d / 10 PLACEMENTS"%placements if not placed else "%d MMR  ·  DIV %s"%[mmr,str(actual.get("division_roman","I"))],10,UIV26.MUTED,700))
	copy.add_child(UIV26.v_space(7))
	copy.add_child(UIV26.label("BILANZ %d–%d  ·  %.1f%% WR"%[int(record.get("wins",0)),int(record.get("losses",0)),RankedV26.win_rate(record)],9,UIV26.DIM,700))
	row.add_child(copy)
	var emblem := RankEmblemV26.new().configure(shown)
	emblem.custom_minimum_size=Vector2(145,145)
	row.add_child(emblem)
	box.add_child(row)
	if not placed:
		box.add_child(UIV26.progress(placements,10,accent,6))
	else:
		var progress := RankedV26.progress_for_mmr(mmr,playlist)
		box.add_child(UIV26.progress(float(progress.get("value",0)),float(progress.get("maximum",1)),accent,6))
	return stage

func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var stage := WorldStageV26Ref.new().configure(accent,"player")
	stage.custom_minimum_size.y=302
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",12)
	margin.add_theme_constant_override("margin_right",12)
	margin.add_theme_constant_override("margin_top",10)
	margin.add_theme_constant_override("margin_bottom",10)
	stage.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	margin.add_child(row)
	var person := PlayerV26Ref.new().configure(str(player.get("name","SPIELER")),accent,game.player_overall(player),int(player.get("potential",99)),"profile")
	person.custom_minimum_size=Vector2(145,250)
	row.add_child(person)
	var right := VBoxContainer.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",3)
	right.add_child(UIV26.label(str(player.get("name","SPIELER")).to_upper(),25,UIV26.TEXT,800))
	right.add_child(UIV26.label("%s  /  %s  /  %d J."%[str(player.get("role","SPIELER")).to_upper(),str(player.get("region","EU")),int(player.get("age",16))],8,UIV26.MUTED,700))
	right.add_child(UIV26.label("%d OVR  ·  POT %d"%[game.player_overall(player),int(player.get("potential",99))],17,UIV26.CYAN,800))
	var radar := RadarV26Ref.new().configure({"MECH":int(player.get("mechanics",50)),"SHOT":int(player.get("shooting",50)),"DEF":int(player.get("defense",50)),"SENSE":int(player.get("game_sense",50))},accent)
	radar.custom_minimum_size=Vector2(132,132)
	right.add_child(radar)
	var line := UIV26.label("MECH %d  ·  ROT %d  ·  CONS %d"%[int(player.get("mechanics",50)),int(player.get("rotation",50)),int(player.get("consistency",50))],8,UIV26.DIM,700)
	right.add_child(line)
	row.add_child(right)
	return stage

func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var stage := WorldStageV26Ref.new().configure(accent,"scout")
	stage.custom_minimum_size.y=244
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",11)
	margin.add_theme_constant_override("margin_right",11)
	margin.add_theme_constant_override("margin_top",9)
	margin.add_theme_constant_override("margin_bottom",9)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",6)
	margin.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",9)
	var person := PlayerV26Ref.new().configure(str(player.get("name","SPIELER")),accent,game.player_overall(player),int(player.get("potential",50)),"card")
	person.custom_minimum_size=Vector2(104,166)
	row.add_child(person)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	copy.add_child(UIV26.label("SCOUTING  /  PROSPECT",7,UIV26.DIM,800))
	copy.add_child(UIV26.label(str(player.get("name","SPIELER")).to_upper(),21,UIV26.TEXT,800))
	copy.add_child(UIV26.label("%s  ·  %s  ·  %d J."%[str(player.get("role","SPIELER")).to_upper(),str(player.get("region","EU")),int(player.get("age",16))],8,UIV26.MUTED,700))
	copy.add_child(UIV26.label("%d OVR"%game.player_overall(player),25,UIV26.TEXT,800))
	copy.add_child(UIV26.label("POTENZIAL %d"%int(player.get("potential",50)),9,UIV26.GREEN,800))
	copy.add_child(UIV26.v_space(3))
	copy.add_child(UIV26.label("MECH %d   ROT %d   DEF %d"%[int(player.get("mechanics",50)),int(player.get("rotation",50)),int(player.get("defense",50))],8,UIV26.DIM,700))
	row.add_child(copy)
	box.add_child(row)
	var price := int(player.get("contract",0))
	var sign := UIV26.button("VERPFLICHTEN  ·  %s"%GameDataV26.format_cash(price),accent,true,true)
	sign.disabled=int(game.data.get("cash",0))<price
	sign.pressed.connect(_sign_player.bind(str(player.get("id",""))))
	box.add_child(sign)
	return stage

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var readiness := state.training_readiness(player)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	var header := HBoxContainer.new()
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation",0)
	identity.add_child(UIV26.label("PERFORMANCE LAB",7,UIV26.DIM,800))
	identity.add_child(UIV26.label(str(player.get("name","SPIELER")).to_upper(),24,UIV26.TEXT,800))
	header.add_child(identity)
	header.add_child(UIV26.badge("LIVE",accent))
	root.add_child(header)
	var training := TrainingVizV26Ref.new()
	training.configure(player,readiness,accent)
	root.add_child(training)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation",4)
	status.add_child(_metric_block("FOKUS","%d/%d"%[int(readiness.get("slots_remaining",0)),int(readiness.get("limit",5))],UIV26.CYAN))
	status.add_child(_metric_block("MÜDE",str(int(player.get("fatigue",0))),UIV26.GOLD))
	status.add_child(_metric_block("SETUP","%d%%"%state.setup_rating(),UIV26.PURPLE))
	root.add_child(status)
	var unlocked := state.unlocked_mechanics_v23(player)
	if not unlocked.is_empty():
		var best: Dictionary=unlocked[unlocked.size()-1]
		var mech_id:=str(best.get("id",""))
		var mastery:=state.mechanic_mastery(player,mech_id)
		var detail:=state.mechanic_components(player,mech_id)
		var mr:=HBoxContainer.new()
		var name:=UIV26.label(str(best.get("label","MECHANIC")).to_upper(),9,UIV26.TEXT,800)
		name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		mr.add_child(name)
		mr.add_child(UIV26.badge("%d%%"%mastery,accent))
		root.add_child(mr)
		root.add_child(UIV26.label("SET %d   CTRL %d   READ %d   FIN %d"%[int(detail.get("setup",mastery)),int(detail.get("control",mastery)),int(detail.get("read",mastery)),int(detail.get("finish",mastery))],8,UIV26.MUTED,700))
	root.add_child(UIV26.label("DRILL WÄHLEN",7,UIV26.DIM,800))
	root.add_child(_training_program_grid(player))
	var upcoming:=state.next_mechanics_v23(player,1)
	if not upcoming.is_empty():
		var next: Dictionary=upcoming[0]
		root.add_child(UIV26.label("NÄCHSTER UNLOCK  ·  %s  ·  %d%%"%[str(next.get("label","MECHANIC")),MechanicsV26.progress(player,next)],8,UIV26.MUTED,700))
	return root

func _build_empire_page() -> void:
	_page_header("VEREINSZENTRALE","Verein","")
	_empire_view_switch()
	match empire_view:
		"staff":
			page_content.add_child(_staff_hq_card())
		"facilities":
			page_content.add_child(_section_title("ANLAGEN",""))
			for key in GameDataV26.FACILITIES:
				page_content.add_child(_facility_card(key))
		_:
			var stage:=WorldStageV26Ref.new().configure(UIV26.GOLD,"club")
			var margin:=MarginContainer.new()
			margin.add_theme_constant_override("margin_left",14)
			margin.add_theme_constant_override("margin_right",14)
			margin.add_theme_constant_override("margin_top",13)
			margin.add_theme_constant_override("margin_bottom",12)
			stage.add_child(margin)
			var box:=VBoxContainer.new()
			box.add_theme_constant_override("separation",6)
			margin.add_child(box)
			box.add_child(UIV26.label("ORGANISATION HQ",7,UIV26.GOLD,800))
			box.add_child(UIV26.label(str(game.data.get("club_name","TSK ESPORTS")),27,UIV26.TEXT,800))
			box.add_child(UIV26.label("Dein Verein wächst mit Team, Staff, Setup und Infrastruktur.",8,UIV26.MUTED,600))
			var metrics:=HBoxContainer.new()
			metrics.add_theme_constant_override("separation",4)
			metrics.add_child(_metric_block("€ / H",GameDataV26.format_cash(game.passive_income_per_hour()),UIV26.GOLD))
			metrics.add_child(_metric_block("FANS / H","+%s"%GameDataV26.format_number(game.passive_fans_per_hour()),UIV26.CYAN))
			metrics.add_child(_metric_block("OFFLINE","8H",UIV26.MUTED))
			box.add_child(metrics)
			page_content.add_child(stage)
			page_content.add_child(_club_identity_card())
