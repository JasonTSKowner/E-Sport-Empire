extends "res://scripts/cinematic_shell_v24.gd"

const MatchVizV241Ref = preload("res://scripts/match_visualizer_v241.gd")
const TrainingVizV241Ref = preload("res://scripts/training_visualizer_v241.gd")

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
	var replacement := MatchVizV241Ref.new()
	replacement.configure(match_result)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	match_visualizer = replacement
	if match_timer != null:
		match_timer.wait_time = 1.42

func _player_training_panel(player: Dictionary, accent: Color) -> Control:
	var root := super._player_training_panel(player, accent)
	var readiness := _v23().training_readiness(player)
	_replace_training_renderer(root, player, readiness, accent)
	return root

func _replace_training_renderer(node: Node, player: Dictionary, readiness: Dictionary, accent: Color) -> bool:
	for child in node.get_children():
		if child is TrainingVisualizerV24:
			var parent := child.get_parent()
			var index := child.get_index()
			parent.remove_child(child)
			child.queue_free()
			var replacement := TrainingVizV241Ref.new()
			replacement.configure(player, readiness, accent)
			parent.add_child(replacement)
			parent.move_child(replacement, index)
			return true
		if _replace_training_renderer(child, player, readiness, accent):
			return true
	return false
