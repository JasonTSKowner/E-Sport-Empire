extends "res://scripts/cinematic_shell_v25_release.gd"

const ProStageV26 = preload("res://scripts/professional_stage_v26.gd")
const UIV26 = preload("res://scripts/ui_kit.gd")
const RankedV26 = preload("res://scripts/ranked_data.gd")
const RankEmblemV26 = preload("res://scripts/rank_emblem.gd")
const PortraitV26 = preload("res://scripts/player_portrait.gd")
const DevelopmentV26 = preload("res://scripts/development_data.gd")
const GameDataV26 = preload("res://scripts/game_data.gd")


func _build_top_bar() -> Control:
	var outer := PanelContainer.new()
	outer.custom_minimum_size.y = 62.0
	var style := UIV26.box(Color("070A0F"), 0, Color(1,1,1,0.045), 0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	outer.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	outer.add_child(row)

	var mark := BrandMarkRef.new()
	mark.custom_minimum_size = Vector2(34,34)
	row.add_child(mark)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", -2)
	identity.add_child(UIV26.label(str(game.data.get("club_name", "TSK ESPORTS")), 14, UIV26.TEXT, 800))
	season_label = UIV26.label("", 7, UIV26.DIM, 700)
	identity.add_child(season_label)
	row.add_child(identity)

	var economy := HBoxContainer.new()
	economy.add_theme_constant_override("separation", 12)
	var cash := VBoxContainer.new()
	cash.add_theme_constant_override("separation", -2)
	var cap := UIV26.label("GUTHABEN", 6, UIV26.DIM, 800)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cash_label = UIV26.label("€0", 12, UIV26.TEXT, 800)
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cash.add_child(cap)
	cash.add_child(cash_label)
	economy.add_child(cash)

	var rep := VBoxContainer.new()
	rep.add_theme_constant_override("separation", -2)
	var rep_cap := UIV26.label("REP", 6, UIV26.DIM, 800)
	rep_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reputation_label = UIV26.label("0", 12, UIV26.GREEN, 800)
	reputation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rep.add_child(rep_cap)
	rep.add_child(reputation_label)
	economy.add_child(rep)
	row.add_child(economy)
	fans_label = null
	return outer


func _build_bottom_navigation() -> Control:
	var wrapper := MarginContainer.new()
	wrapper.custom_minimum_size.y = 72
	wrapper.add_theme_constant_override("margin_left", 8)
	wrapper.add_theme_constant_override("margin_right", 8)
	wrapper.add_theme_constant_override("margin_top", 5)
	wrapper.add_theme_constant_override("margin_bottom", 8)

	var dock := PanelContainer.new()
	var dock_style := UIV26.box(Color(0.035,0.043,0.055,0.985), 17, Color(1,1,1,0.09), 1)
	dock_style.shadow_size = 14
	dock_style.shadow_color = Color(0,0,0,0.34)
	dock_style.shadow_offset = Vector2(0,5)
	dock_style.content_margin_left = 4
	dock_style.content_margin_right = 4
	dock_style.content_margin_top = 4
	dock_style.content_margin_bottom = 4
	dock.add_theme_stylebox_override("panel", dock_style)
	wrapper.add_child(dock)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	dock.add_child(row)
	for entry in AppConfigRef.NAV_ENTRIES:
		var page_id := str(entry[0])
		var button := Button.new()
		button.text = "\n" + str(entry[1])
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 54
		button.add_theme_font_override("font", AppFontRef)
		button.add_theme_font_size_override("font_size", 8)
		var icon := NavIconRef.new()
		icon.configure(page_id, UIV26.MUTED)
		icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
		icon.offset_left = -11
		icon.offset_right = 11
		icon.offset_top = 4
		icon.offset_bottom = 24
		button.add_child(icon)
		button.set_meta("nav_icon", icon)
		button.pressed.connect(_show_page.bind(page_id, true))
		row.add_child(button)
		nav_buttons[page_id] = button
	return wrapper


func _refresh_nav() -> void:
	for key in nav_buttons:
		var button: Button = nav_buttons[key]
		var selected := str(key) == current_page
		button.add_theme_color_override("font_color", UIV26.TEXT if selected else UIV26.DIM)
		button.add_theme_color_override("font_hover_color", UIV26.TEXT)
		button.add_theme_color_override("font_pressed_color", UIV26.TEXT)
		var icon: Control = button.get_meta("nav_icon", null)
		if icon != null and icon.has_method("set_accent"):
			icon.set_accent(UIV26.CYAN if selected else UIV26.MUTED)
		var normal := UIV26.box(Color(UIV26.CYAN.r,UIV26.CYAN.g,UIV26.CYAN.b,0.10) if selected else Color.TRANSPARENT, 13)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", UIV26.box(Color(1,1,1,0.035), 13))
		button.add_theme_stylebox_override("pressed", UIV26.box(Color(UIV26.CYAN.r,UIV26.CYAN.g,UIV26.CYAN.b,0.14), 13))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _build_home_page() -> void:
	page_content.add_child(_home_stage_v26())


func _home_stage_v26() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr", 100))
	var placements := int(record.get("placements", 0))
	var placed := placements >= 10
	var actual_rank := RankedV26.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV26.unranked_data(mmr)
	var accent := UIV26.CYAN if not placed else RankedV26.color_for_family(str(actual_rank.get("family", "Unranked")))

	var stage := ProStageV26.new().configure(accent, "hero")
	stage.custom_minimum_size.y = 650
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var season := UIV26.label("SEASON %d  /  ROCKET LEAGUE" % int(game.data.get("season", 1)), 8, accent, 800)
	season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(season)
	meta.add_child(UIV26.badge(playlist, accent))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 8)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(UIV26.label("COMPETITIVE STATUS", 8, UIV26.MUTED, 800))
	copy.add_child(UIV26.label("UNRANKED" if not placed else str(actual_rank.get("tier_name", "RANKED")), 38, UIV26.TEXT, 800))
	copy.add_child(UIV26.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr, str(actual_rank.get("division_roman", "I"))], 11, UIV26.MUTED, 700))
	copy.add_child(UIV26.v_space(10))
	copy.add_child(UIV26.label("%d SIEGE   %d NIEDERLAGEN" % [int(record.get("wins",0)), int(record.get("losses",0))], 9, UIV26.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblemV26.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(170,170)
	hero.add_child(emblem)
	box.add_child(hero)

	box.add_child(UIV26.v_space(18))
	var objective := VBoxContainer.new()
	objective.add_theme_constant_override("separation", 2)
	objective.add_child(UIV26.label("NÄCHSTER SCHRITT", 7, UIV26.DIM, 800))
	objective.add_child(UIV26.label("PLACEMENT %d ABSCHLIESSEN" % mini(10, placements + 1) if not placed else "RANK PUSH FORTSETZEN", 20, UIV26.TEXT, 800))
	box.add_child(objective)
	if not placed:
		box.add_child(UIV26.progress(placements, 10, accent, 7))
	else:
		var p := RankedV26.progress_for_mmr(mmr, playlist)
		box.add_child(UIV26.progress(float(p.get("value",0)), float(p.get("maximum",1)), accent, 7))

	var action := UIV26.button("RANKED SPIELEN", accent, true)
	action.custom_minimum_size.y = 60
	action.add_theme_font_size_override("font_size", 14)
	action.pressed.connect(_show_page.bind("play", true))
	box.add_child(action)

	box.add_child(UIV26.v_space(10))
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 6)
	metrics.add_child(_pro_metric_v26("TEAM", "%d" % game.team_overall("Rocket League"), "OVR", UIV26.CYAN))
	metrics.add_child(_pro_metric_v26("CHEMIE", "%d" % game.team_chemistry("Rocket League"), "%", UIV26.GREEN))
	metrics.add_child(_pro_metric_v26("PING", "%d" % _v23().connection_ping(), "MS", UIV26.PURPLE))
	box.add_child(metrics)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	var career := VBoxContainer.new()
	career.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	career.add_child(UIV26.label("KARRIERE", 7, UIV26.DIM, 800))
	career.add_child(UIV26.label("LEVEL %d" % game.career_level(), 15, UIV26.TEXT, 800))
	bottom.add_child(career)
	var played := int(record.get("played",0))
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var form_cap := UIV26.label("MATCHES", 7, UIV26.DIM, 800)
	form_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	form.add_child(form_cap)
	var form_value := UIV26.label(str(played), 15, UIV26.TEXT, 800)
	form_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	form.add_child(form_value)
	bottom.add_child(form)
	box.add_child(bottom)
	return stage


func _origin_card() -> Control:
	return _home_stage_v26()


func _build_play_page() -> void:
	if game.selected_mode() != "Rocket League" or ranked_view != "overview":
		super._build_play_page()
		return
	page_content.add_child(_playlist_bar_v26())
	page_content.add_child(_ranked_stage_v26())
	page_content.add_child(_ranked_secondary_actions_v26())


func _playlist_bar_v26() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var selected := game.selected_rl_playlist()
	var roster_size := game.roster_for("Rocket League").size()
	for playlist in RankedV26.PLAYLISTS:
		var required := game.playlist_required_players(str(playlist))
		var available := roster_size >= required
		var button := UIV26.button(str(playlist), UIV26.CYAN if str(playlist) == selected else UIV26.DIM, str(playlist) == selected)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 46
		button.add_theme_font_size_override("font_size", 10)
		button.tooltip_text = "Bereit" if available else "%d von %d Spielern" % [roster_size, required]
		button.pressed.connect(_select_rl_playlist.bind(str(playlist)))
		row.add_child(button)
	return row


func _ranked_stage_v26() -> Control:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	var mmr := int(record.get("mmr",100))
	var placements := int(record.get("placements",0))
	var placed := placements >= 10
	var actual_rank := RankedV26.rank_for_mmr(mmr, playlist)
	var shown_rank := actual_rank if placed else RankedV26.unranked_data(mmr)
	var accent := UIV26.CYAN if not placed else RankedV26.color_for_family(str(actual_rank.get("family","Unranked")))
	var available := game.can_queue_playlist(playlist)
	var required := game.playlist_required_players(playlist)
	var roster_size := game.roster_for("Rocket League").size()

	var stage := ProStageV26.new().configure(accent, "rank")
	stage.custom_minimum_size.y = 590
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 17)
	margin.add_theme_constant_override("margin_bottom", 17)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	margin.add_child(box)

	var meta := HBoxContainer.new()
	var title := UIV26.label("ROCKET LEAGUE  /  %s" % playlist, 8, accent, 800)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(title)
	meta.add_child(UIV26.badge("BEREIT" if available else "GESPERRT", UIV26.GREEN if available else UIV26.RED))
	box.add_child(meta)

	var hero := HBoxContainer.new()
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(UIV26.label("UNRANKED" if not placed else str(actual_rank.get("tier_name","RANKED")), 38, UIV26.TEXT, 800))
	copy.add_child(UIV26.label("%d / 10 PLACEMENTS" % placements if not placed else "%d MMR  ·  DIV %s" % [mmr,str(actual_rank.get("division_roman","I"))], 11, UIV26.MUTED, 700))
	copy.add_child(UIV26.v_space(12))
	copy.add_child(UIV26.label("BILANZ  %d–%d" % [int(record.get("wins",0)),int(record.get("losses",0))], 9, UIV26.DIM, 700))
	copy.add_child(UIV26.label("WINRATE  %.1f%%" % RankedV26.win_rate(record), 9, UIV26.DIM, 700))
	hero.add_child(copy)
	var emblem := RankEmblemV26.new().configure(shown_rank)
	emblem.custom_minimum_size = Vector2(176,176)
	hero.add_child(emblem)
	box.add_child(hero)

	if not placed:
		box.add_child(UIV26.progress(placements,10,accent,7))
	else:
		var progress := RankedV26.progress_for_mmr(mmr,playlist)
		box.add_child(UIV26.progress(float(progress.get("value",0)),float(progress.get("maximum",1)),accent,7))

	box.add_child(UIV26.v_space(16))
	var queue_label := UIV26.label("SPIELSUCHE",7,UIV26.DIM,800)
	box.add_child(queue_label)
	box.add_child(UIV26.label("%s RANKED" % playlist,21,UIV26.TEXT,800))
	var queue_text := "MATCH SUCHEN" if available else "NOCH %d SPIELER BENÖTIGT" % maxi(0, required-roster_size)
	var queue := UIV26.button(queue_text, accent, available)
	queue.disabled = not available
	queue.custom_minimum_size.y = 62
	queue.add_theme_font_size_override("font_size",14)
	queue.pressed.connect(_start_match.bind("Rocket League"))
	box.add_child(queue)

	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation",6)
	metrics.add_child(_pro_metric_v26("TEAM","%d" % game.team_overall("Rocket League"),"OVR",UIV26.CYAN))
	metrics.add_child(_pro_metric_v26("CHEMIE","%d" % game.team_chemistry("Rocket League"),"%",UIV26.GREEN))
	metrics.add_child(_pro_metric_v26("PING","%d" % _v23().connection_ping(),"MS",UIV26.PURPLE))
	box.add_child(metrics)
	return stage


func _ranked_secondary_actions_v26() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	for entry in [["circuit","TURNIER"],["ladder","RANGLISTE"],["titles","TITEL"]]:
		var button := UIV26.button(str(entry[1]),UIV26.DIM,false)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size",8)
		button.pressed.connect(_select_ranked_view.bind(str(entry[0])))
		row.add_child(button)
	return row


func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var stage := ProStageV26.new().configure(accent,"player")
	stage.custom_minimum_size.y = 314
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",14)
	margin.add_theme_constant_override("margin_right",14)
	margin.add_theme_constant_override("margin_top",14)
	margin.add_theme_constant_override("margin_bottom",14)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	margin.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	var portrait := PortraitV26.new().configure(str(player.get("name","SPIELER")),accent)
	portrait.custom_minimum_size = Vector2(118,154)
	row.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation",2)
	identity.add_child(UIV26.label("STARTER  /  ROCKET LEAGUE",7,accent,800))
	identity.add_child(UIV26.label(str(player.get("name","SPIELER")).to_upper(),27,UIV26.TEXT,800))
	identity.add_child(UIV26.label("%s  ·  %s  ·  %d J." % [str(player.get("role","SPIELER")).to_upper(),str(player.get("region","EU")),int(player.get("age",16))],8,UIV26.MUTED,700))
	var archetype := DevelopmentV26.player_archetype(player)
	identity.add_child(UIV26.label(str(archetype.get("label","KOMPLETTER SPIELER")).to_upper(),8,Color(str(archetype.get("color","F1F4F7"))),800))
	identity.add_child(UIV26.v_space(10))
	identity.add_child(UIV26.label("%d" % game.player_overall(player),34,UIV26.TEXT,800))
	identity.add_child(UIV26.label("OVERALL   ·   POTENZIAL %d" % int(player.get("potential",99)),8,UIV26.GREEN,800))
	row.add_child(identity)
	box.add_child(row)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation",5)
	stats.add_child(_pro_metric_v26("MECH",str(int(player.get("mechanics",50))),"",UIV26.CYAN))
	stats.add_child(_pro_metric_v26("SCHUSS",str(int(player.get("shooting",50))),"",UIV26.GOLD))
	stats.add_child(_pro_metric_v26("DEF",str(int(player.get("defense",50))),"",UIV26.GREEN))
	stats.add_child(_pro_metric_v26("SENSE",str(int(player.get("game_sense",50))),"",UIV26.PURPLE))
	box.add_child(stats)
	return stage


func _prospect_card(player: Dictionary, accent: Color) -> Control:
	var stage := ProStageV26.new().configure(accent,"scout")
	stage.custom_minimum_size.y = 226
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",12)
	margin.add_theme_constant_override("margin_right",12)
	margin.add_theme_constant_override("margin_top",12)
	margin.add_theme_constant_override("margin_bottom",12)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	margin.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	var portrait := PortraitV26.new().configure(str(player.get("name","SPIELER")),accent)
	portrait.custom_minimum_size = Vector2(88,112)
	row.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UIV26.label("SCOUTING REPORT",7,accent,800))
	identity.add_child(UIV26.label(str(player.get("name","SPIELER")),22,UIV26.TEXT,800))
	identity.add_child(UIV26.label("%s  ·  %s  ·  %d J." % [str(player.get("role","SPIELER")).to_upper(),str(player.get("region","EU")),int(player.get("age",16))],8,UIV26.MUTED,700))
	row.add_child(identity)
	var rating := VBoxContainer.new()
	var ovr := UIV26.label(str(game.player_overall(player)),30,UIV26.TEXT,800)
	ovr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var pot := UIV26.label("POT %d" % int(player.get("potential",50)),8,UIV26.GREEN,800)
	pot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rating.add_child(ovr)
	rating.add_child(pot)
	row.add_child(rating)
	box.add_child(row)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation",4)
	stats.add_child(_pro_metric_v26("MECH",str(int(player.get("mechanics",50))),"",UIV26.CYAN))
	stats.add_child(_pro_metric_v26("ROT",str(int(player.get("rotation",50))),"",UIV26.PURPLE))
	stats.add_child(_pro_metric_v26("SHOT",str(int(player.get("shooting",50))),"",UIV26.GOLD))
	stats.add_child(_pro_metric_v26("DEF",str(int(player.get("defense",50))),"",UIV26.GREEN))
	box.add_child(stats)
	var price := int(player.get("contract",0))
	var sign := UIV26.button("VERPFLICHTEN  ·  %s" % GameDataV26.format_cash(price),accent,true)
	sign.disabled = int(game.data.get("cash",0)) < price
	sign.custom_minimum_size.y = 44
	sign.pressed.connect(_sign_player.bind(str(player.get("id",""))))
	box.add_child(sign)
	return stage


func _build_empire_page() -> void:
	if empire_view != "overview":
		super._build_empire_page()
		return
	_page_header("VEREINSZENTRALE","Verein","")
	_empire_view_switch()
	var stage := ProStageV26.new().configure(UIV26.GOLD,"club")
	stage.custom_minimum_size.y = 430
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",16)
	margin.add_theme_constant_override("margin_right",16)
	margin.add_theme_constant_override("margin_top",16)
	margin.add_theme_constant_override("margin_bottom",16)
	stage.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	margin.add_child(box)
	box.add_child(UIV26.label("ORGANISATION",7,UIV26.GOLD,800))
	box.add_child(UIV26.label(str(game.data.get("club_name","TSK ESPORTS")),29,UIV26.TEXT,800))
	box.add_child(UIV26.label("Dein Club wächst mit Team, Staff, Setup und Infrastruktur.",9,UIV26.MUTED,600))
	box.add_child(UIV26.v_space(12))
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation",6)
	status.add_child(_pro_metric_v26("GUTHABEN",GameDataV26.format_cash(int(game.data.get("cash",0))),"",UIV26.GOLD))
	status.add_child(_pro_metric_v26("FANS",GameDataV26.format_number(int(game.data.get("fans",0))),"",UIV26.CYAN))
	status.add_child(_pro_metric_v26("REP",str(int(game.data.get("reputation",0))),"",UIV26.GREEN))
	box.add_child(status)
	box.add_child(UIV26.v_space(14))
	var income := HBoxContainer.new()
	income.add_theme_constant_override("separation",6)
	income.add_child(_pro_metric_v26("EINKOMMEN",GameDataV26.format_cash(game.passive_income_per_hour()),"/H",UIV26.GOLD))
	income.add_child(_pro_metric_v26("FANWACHSTUM","+%s" % GameDataV26.format_number(game.passive_fans_per_hour()),"/H",UIV26.CYAN))
	box.add_child(income)
	box.add_child(UIV26.v_space(10))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",6)
	for entry in [["staff","STAFF"],["facilities","ANLAGEN"]]:
		var button := UIV26.button(str(entry[1]),UIV26.DIM,false)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 48
		button.pressed.connect(_select_empire_view.bind(str(entry[0])))
		actions.add_child(button)
	box.add_child(actions)
	page_content.add_child(stage)
	page_content.add_child(_club_identity_card())


func _pro_metric_v26(caption: String, value: String, suffix: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := UIV26.box(Color(0.035,0.045,0.058,0.82),10,Color(1,1,1,0.055),1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",-1)
	var cap := UIV26.label(caption.to_upper(),7,Color(accent.r,accent.g,accent.b,0.88),800)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value_text := value + (" " + suffix if not suffix.is_empty() else "")
	var val := UIV26.label(value_text,16 if value_text.length() < 9 else 12,UIV26.TEXT,800)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(val)
	panel.add_child(box)
	return panel
