extends "res://scripts/cinematic_shell_v251.gd"

func _empire_view_switch() -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	for entry in [["overview", "ÜBERSICHT"], ["staff", "STAFF"], ["facilities", "ANLAGEN"]]:
		var target := str(entry[0])
		var button := _flat_tab_v251(str(entry[1]), empire_view == target, FlatUIV251.GOLD)
		button.pressed.connect(_select_empire_view.bind(target))
		row.add_child(button)
	wrap.add_child(row)
	wrap.add_child(_flat_nav_divider_v251())
	page_content.add_child(wrap)
