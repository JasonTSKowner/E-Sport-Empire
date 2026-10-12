extends "res://scripts/cinematic_shell_v25.gd"

const CareerProgressV251Ref = preload("res://scripts/career_progress_v25.gd")
const PlayerDevelopmentV251Ref = preload("res://scripts/player_development_v25.gd")
const MechanicsV251Ref = preload("res://scripts/mechanics_catalog_v23.gd")
const UIV251 = preload("res://scripts/ui_kit.gd")

func _build_home_page() -> void:
	super._build_home_page()
	var state := _v23()
	var roster: Array = game.roster_for("Rocket League")
	var best_label := "BASICS"
	var best_mastery := 0
	var next_label := "FIRST UNLOCK"
	var next_progress := 0
	if not roster.is_empty():
		var player: Dictionary = roster[0]
		var unlocked: Array = state.unlocked_mechanics_v23(player)
		if not unlocked.is_empty():
			var best: Dictionary = unlocked[unlocked.size() - 1]
			best_label = str(best.get("label", "BASICS"))
			best_mastery = state.mechanic_mastery(player, str(best.get("id", "")))
		var upcoming: Array = state.next_mechanics_v23(player, 1)
		if not upcoming.is_empty():
			var next: Dictionary = upcoming[0]
			next_label = str(next.get("label", "NEXT MECHANIC"))
			next_progress = MechanicsV251Ref.progress(player, next)
	var deck := CareerProgressV251Ref.new().configure(
		UIV251.CYAN,
		game.career_level(),
		state.setup_rating(),
		state.connection_ping(),
		best_label,
		best_mastery,
		next_label,
		next_progress
	)
	page_content.add_child(deck)

func _player_profile_panel(player: Dictionary, accent: Color) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	root.add_child(super._player_profile_panel(player, accent))
	var state := _v23()
	var unlocked: Array = state.unlocked_mechanics_v23(player)
	var signature_label := "BASICS"
	var signature_mastery := 0
	if not unlocked.is_empty():
		var best: Dictionary = unlocked[unlocked.size() - 1]
		signature_label = str(best.get("label", "BASICS"))
		signature_mastery = state.mechanic_mastery(player, str(best.get("id", "")))
	var next_label := "MAX TREE"
	var next_progress := 100
	var upcoming: Array = state.next_mechanics_v23(player, 1)
	if not upcoming.is_empty():
		var next: Dictionary = upcoming[0]
		next_label = str(next.get("label", "NEXT MECHANIC"))
		next_progress = MechanicsV251Ref.progress(player, next)
	var development := PlayerDevelopmentV251Ref.new().configure(
		accent,
		unlocked.size(),
		signature_label,
		signature_mastery,
		next_label,
		next_progress,
		int(player.get("mechanics", 50)),
		int(player.get("game_sense", 50)),
		int(player.get("consistency", 50))
	)
	root.add_child(development)
	return root
