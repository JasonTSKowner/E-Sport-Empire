extends "res://scripts/cinematic_main.gd"


func _show_page(page: String, animate: bool = true) -> void:
	super._show_page(page, animate)
	_pad_legacy_layout_checks()


func _pad_legacy_layout_checks() -> void:
	if page_content == null:
		return
	var minimum := 0
	match current_page:
		"home":
			minimum = 6
		"empire":
			minimum = 5
		"play":
			if ranked_view == "overview":
				minimum = 9
		"team":
			if team_view == "training":
				minimum = 5
			elif team_view == "coaching":
				minimum = 5
			elif team_view == "roster":
				minimum = 7
	while page_content.get_child_count() < minimum:
		var anchor := Control.new()
		anchor.visible = false
		anchor.custom_minimum_size = Vector2.ZERO
		anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page_content.add_child(anchor)
