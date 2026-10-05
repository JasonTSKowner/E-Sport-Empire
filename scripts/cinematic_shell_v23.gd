extends "res://scripts/cinematic_shell_v22.gd"

const StateV23Ref = preload("res://scripts/game_state_v23.gd")
const MatchVizV23Ref = preload("res://scripts/match_visualizer_v23.gd")
const TrainingVizV23Ref = preload("res://scripts/training_visualizer_v23.gd")
const MechanicsV23Ref = preload("res://scripts/mechanics_catalog_v23.gd")
const UIV23 = preload("res://scripts/ui_kit.gd")
const SurfaceV23 = preload("res://scripts/cinematic_surface.gd")
const AppConfigV23 = preload("res://scripts/app_config.gd")


func _ready() -> void:
	game = StateV23Ref.new()
	var offline: Dictionary = game.load_game()
	_build_shell()
	_show_page(AppConfigV23.DEFAULT_PAGE, false)
	if int(offline.get("seconds", 0)) >= 60 and (int(offline.get("cash", 0)) > 0 or int(offline.get("fans", 0)) > 0):
		call_deferred("_show_offline_message", offline)


func _v23() -> EmpireStateV23:
	return game as EmpireStateV23


func _build_match_overlay() -> void:
	super._build_match_overlay()
	if match_visualizer != null and is_instance_valid(match_visualizer):
		var old := match_visualizer
		var parent := old.get_parent()
		var index := old.get_index()
		if parent != null:
			parent.remove_child(old)
			old.queue_free()
			var replacement := MatchVizV23Ref.new()
			replacement.configure(match_result)
			parent.add_child(replacement)
			parent.move_child(replacement, index)
			match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.20


func _set_match_speed(speed: int) -> void:
	if match_finished:
		return
	match_speed = speed
	if match_timer != null:
		match_timer.wait_time = 1.20 / float(maxi(1, speed))
		match_timer.start()


func _advance_match() -> void:
	if match_finished:
		return
	var events: Array = match_result.get("broadcast_events", match_result.get("events", []))
	var phase := "reset"
	if match_event_index < events.size():
		phase = str(events[match_event_index].get("phase", "reset"))
	super._advance_match()
	if match_timer == null or match_finished:
		return
	var slow_phases := [
		"psycho_setup", "own_wall_carry", "backwall_musty", "backwall_touch", "psycho_contact",
		"teammate_prejump", "redirect_finish", "reset_1", "reset_2", "reset_3", "reset_4",
		"reset_contact", "reset_control", "ceiling_setup", "ceiling_drop", "pogo_drop", "pogo_bounce",
		"team_sync", "pinch_release", "double_tap_finish", "mechanic_fail"
	]
	var medium_phases := [
		"wall_setup", "air_carry", "air_carry_2", "air_pass", "flick_load", "flick_release",
		"backboard_shot", "backboard_read", "redirect_read", "prejump", "pinch_setup", "pinch_contact",
		"defense_read", "save_line", "clear_touch", "freestyle_transition"
	]
	var delay := 1.10
	if phase in slow_phases:
		delay = 1.46
	elif phase in medium_phases:
		delay = 1.30
	elif phase in ["goal_ours", "goal_theirs"]:
		delay = 1.55
	elif phase in ["rotation_switch", "challenge"]:
		delay = 1.18
	match_timer.wait_time = delay / float(maxi(1, match_speed))


func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var panel := super._player_training_panel(player, accent)
	var box := panel.get_child(0) as VBoxContainer
	if box != null:
		if box.get_child_count() > 0:
			var header := box.get_child(0)
			if header is HBoxContainer and header.get_child_count() > 1:
				var badge := header.get_child(1)
				if badge.get_child_count() > 0 and badge.get_child(0) is Label:
					(badge.get_child(0) as Label).text = "GRATIS"
		box.add_child(_mechanic_library_panel(player, accent))
	return panel


func _mechanic_library_panel(player: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var unlocked := state.unlocked_mechanics_v23(player)
	var upcoming := state.next_mechanics_v23(player, 4)
	var total := MechanicsV23Ref.MECHANICS.size()
	var panel := SurfaceV23.new().configure(accent, "player", 0.82)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var header := HBoxContainer.new()
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(UIV23.label("MECHANIC TREE", 7, UIV23.DIM, 800))
	title.add_child(UIV23.label("%d / %d freigeschaltet" % [unlocked.size(), total], 16, UIV23.TEXT, 800))
	header.add_child(title)
	header.add_child(UIV23.badge("%d%%" % int(round(float(unlocked.size()) / float(maxi(1, total)) * 100.0)), accent))
	box.add_child(header)
	box.add_child(UIV23.progress(unlocked.size(), total, accent, 5))

	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 3)
	for category in ["movement", "aerial", "reset", "freestyle"]:
		var unlocked_count := 0
		for item_value in unlocked:
			var item: Dictionary = item_value
			if str(item.get("category", "")) == category:
				unlocked_count += 1
		categories.add_child(_metric_block(category.left(4).to_upper(), "%d/%d" % [unlocked_count, MechanicsV23Ref.category_count(category)], accent))
	box.add_child(categories)

	if not unlocked.is_empty():
		box.add_child(UIV23.label("BESTE VERFÜGBARE MECHANICS", 8, UIV23.DIM, 800))
		var best := unlocked.duplicate(true)
		best.sort_custom(func(a: Dictionary, b: Dictionary):
			var score_a := state.mechanic_mastery(player, str(a.get("id", ""))) + int(a.get("tier", 1)) * 8
			var score_b := state.mechanic_mastery(player, str(b.get("id", ""))) + int(b.get("tier", 1)) * 8
			return score_a > score_b
		)
		for index in range(mini(4, best.size())):
			box.add_child(_mechanic_mastery_row(player, best[index], accent))

	if not upcoming.is_empty():
		box.add_child(UIV23.label("NÄCHSTE UNLOCKS", 8, UIV23.DIM, 800))
		for item_value in upcoming:
			var item: Dictionary = item_value
			var row := HBoxContainer.new()
			var name := UIV23.label(str(item.get("label", "MECHANIC")), 10, UIV23.TEXT, 700)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name)
			row.add_child(UIV23.badge("%d%%" % MechanicsV23Ref.progress(player, item), UIV23.MUTED))
			box.add_child(row)
	return panel


func _mechanic_mastery_row(player: Dictionary, item: Dictionary, accent: Color) -> Control:
	var state := _v23()
	var mechanic_id := str(item.get("id", ""))
	var mastery := state.mechanic_mastery(player, mechanic_id)
	var detail := state.mechanic_components(player, mechanic_id)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 3)
	var row := HBoxContainer.new()
	var title := UIV23.label(str(item.get("label", mechanic_id)), 10, UIV23.TEXT, 800)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(UIV23.badge("T%d  •  %d%%" % [int(item.get("tier", 1)), mastery], accent))
	wrapper.add_child(row)
	var components := UIV23.label(
		"SET %d   CTRL %d   READ %d   FIN %d" % [
			int(detail.get("setup", mastery)), int(detail.get("control", mastery)),
			int(detail.get("read", mastery)), int(detail.get("finish", mastery))
		],
		8,
		UIV23.MUTED,
		700
	)
	wrapper.add_child(components)
	wrapper.add_child(UIV23.progress(mastery, 100, accent, 4))
	return wrapper
