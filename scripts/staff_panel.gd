class_name StaffPanel
extends Control

signal action_requested(action: String, payload: Dictionary)
signal closed

const UI = preload("res://scripts/ui_kit.gd")
const StaffAccessRef = preload("res://scripts/staff_access.gd")

var session: Dictionary = {}
var snapshot: Dictionary = {}
var status_label: Label
var reset_button: Button
var reset_armed := false


func configure(staff_session: Dictionary, state_snapshot: Dictionary) -> StaffPanel:
	session = staff_session.duplicate(true)
	snapshot = state_snapshot.duplicate(true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 900
	_build()
	visible = false
	return self


func open_with(staff_session: Dictionary, state_snapshot: Dictionary) -> void:
	session = staff_session.duplicate(true)
	snapshot = state_snapshot.duplicate(true)
	reset_armed = false
	_build()
	visible = true


func refresh(state_snapshot: Dictionary) -> void:
	snapshot = state_snapshot.duplicate(true)
	var was_visible := visible
	_build()
	visible = was_visible


func set_status(message: String, is_error: bool = false) -> void:
	if status_label == null or not is_instance_valid(status_label):
		return
	status_label.text = message
	status_label.add_theme_color_override("font_color", UI.RED if is_error else UI.GREEN)


func _build() -> void:
	for child in get_children():
		child.queue_free()

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 8)
	outer.add_theme_constant_override("margin_right", 8)
	outer.add_theme_constant_override("margin_top", 26)
	outer.add_theme_constant_override("margin_bottom", 18)
	add_child(outer)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(Color("090D13"), 18, Color(0.45, 0.70, 0.82, 0.20), 1))
	outer.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	content.add_child(_header())
	content.add_child(UI.separator())
	content.add_child(_overview_section())
	content.add_child(UI.separator())
	content.add_child(_economy_section())
	content.add_child(UI.separator())
	content.add_child(_ranked_section())
	content.add_child(UI.separator())
	content.add_child(_training_section())
	content.add_child(UI.separator())
	content.add_child(_save_section())
	content.add_child(UI.separator())
	content.add_child(_roles_section())
	content.add_child(UI.separator())
	content.add_child(_audit_section())

	status_label = UI.label("STAFF CONTROL BEREIT", 8, UI.GREEN, 800)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status_label)

	var close := UI.button("PANEL SCHLIESSEN", UI.CYAN, false, true)
	close.pressed.connect(_close)
	content.add_child(close)


func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.add_child(UI.label("INTERNAL STAFF CONTROL", 7, UI.DIM, 800))
	copy.add_child(UI.label("ADMIN PANEL", 26, UI.TEXT, 800))
	copy.add_child(UI.label("%s  ·  %s" % [str(snapshot.get("build", "DEV")), str(session.get("source", "debug")).to_upper()], 8, UI.MUTED, 700))
	row.add_child(copy)
	var role_color := Color(str(session.get("color", "74DFF7")))
	row.add_child(UI.badge(str(session.get("label", "STAFF")), role_color))
	return row


func _overview_section() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(UI.label("ÜBERSICHT", 9, UI.TEXT, 800))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.add_child(UI.metric_tile("KARRIERE", "LV %d" % int(snapshot.get("level", 1)), UI.CYAN))
	grid.add_child(UI.metric_tile("ROSTER", str(int(snapshot.get("roster", 0))), UI.PURPLE))
	grid.add_child(UI.metric_tile("GUTHABEN", str(snapshot.get("cash", "€0")), UI.GOLD))
	grid.add_child(UI.metric_tile("FANS", str(snapshot.get("fans", "0")), UI.GREEN))
	grid.add_child(UI.metric_tile("SAVE", "V%s" % str(snapshot.get("save_version", "?")), UI.MUTED))
	grid.add_child(UI.metric_tile("BACKUP", "AN" if bool(snapshot.get("backup_enabled", false)) else "AUS", UI.GREEN if bool(snapshot.get("backup_enabled", false)) else UI.DIM))
	box.add_child(grid)
	return box


func _economy_section() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_section_head("ECONOMY", "Nur Owner/Admin"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.add_child(_action_button("+10K €", "add_cash", {"amount": 10000}, "economy", UI.GOLD))
	grid.add_child(_action_button("+100K €", "add_cash", {"amount": 100000}, "economy", UI.GOLD))
	grid.add_child(_action_button("+10K FANS", "add_fans", {"amount": 10000}, "economy", UI.GREEN))
	grid.add_child(_action_button("+25 REPUTATION", "add_reputation", {"amount": 25}, "economy", UI.PURPLE))
	box.add_child(grid)
	return box


func _ranked_section() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_section_head("RANKED CONTROL", "%s  ·  %d MMR  ·  %d/10" % [str(snapshot.get("playlist", "1v1")), int(snapshot.get("mmr", 100)), int(snapshot.get("placements", 0))]))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.add_child(_action_button("MMR -100", "mmr_delta", {"delta": -100}, "ranked", UI.RED))
	grid.add_child(_action_button("MMR +100", "mmr_delta", {"delta": 100}, "ranked", UI.CYAN))
	grid.add_child(_action_button("MMR +500", "mmr_delta", {"delta": 500}, "ranked", UI.PURPLE))
	grid.add_child(_action_button("PLACEMENTS 10/10", "complete_placements", {}, "ranked", UI.GREEN))
	box.add_child(grid)
	return box


func _training_section() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_section_head("PLAYER / TRAINING", "Debug- und Recovery-Tools"))
	var button := _action_button("MÜDIGKEIT + FOKUS RESET", "recover_training", {}, "training", UI.CYAN)
	box.add_child(button)
	return box


func _save_section() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_section_head("SAVE & BACKUP", "Destruktive Aktionen sind getrennt"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.add_child(_action_button("JETZT SPEICHERN", "save_now", {}, "save", UI.GREEN))
	grid.add_child(_action_button("BACKUP-CODE", "create_backup", {}, "save", UI.CYAN))
	grid.add_child(_action_button("UI REFRESH", "refresh_ui", {}, "view", UI.MUTED))
	reset_button = UI.button("SAVE RESET", UI.RED, false, true)
	reset_button.disabled = not StaffAccessRef.can(session, "destructive")
	reset_button.pressed.connect(_reset_pressed)
	grid.add_child(reset_button)
	box.add_child(grid)
	return box


func _roles_section() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.add_child(_section_head("STAFF ROLLEN", "Berechtigungen werden zentral geprüft"))
	for role_value in StaffAccessRef.roles_for_ui():
		var role: Dictionary = role_value
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var color := Color(str(role.get("color", "74DFF7")))
		row.add_child(UI.badge(str(role.get("label", "STAFF")), color))
		var permissions: Array = role.get("permissions", [])
		var summary := UI.label(_permission_summary(permissions), 8, UI.MUTED, 700)
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(summary)
		box.add_child(row)
	var note := UI.label("Produktiv: Rolle muss vom Server bestätigt werden. Lokale Debug-Rollen sind keine echte Authentifizierung.", 8, UI.DIM, 600)
	box.add_child(note)
	return box


func _audit_section() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(_section_head("AUDIT LOG", "Aktuelle Staff-Session"))
	var logs: Array = snapshot.get("audit", [])
	if logs.is_empty():
		box.add_child(UI.label("Noch keine Staff-Aktion in dieser Session.", 8, UI.DIM, 600))
	else:
		for i in range(mini(6, logs.size())):
			box.add_child(UI.label(str(logs[i]), 8, UI.MUTED, 700))
	if StaffAccessRef.can(session, "moderation"):
		box.add_child(UI.label("SERVER-MODERATION: vorbereitet, aber noch kein User-Backend verbunden.", 8, UI.CYAN, 700))
	return box


func _section_head(title: String, subtitle: String) -> Control:
	var row := HBoxContainer.new()
	var title_label := UI.label(title, 9, UI.TEXT, 800)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	var sub := UI.label(subtitle, 7, UI.DIM, 700)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(sub)
	return row


func _action_button(text: String, action: String, payload: Dictionary, permission: String, accent: Color) -> Button:
	var button := UI.button(text, accent, false, true)
	button.disabled = not StaffAccessRef.can(session, permission)
	button.pressed.connect(_emit_action.bind(action, payload))
	return button


func _emit_action(action: String, payload: Dictionary) -> void:
	if not StaffAccessRef.can_action(session, action):
		set_status("KEINE BERECHTIGUNG", true)
		return
	action_requested.emit(action, payload)


func _reset_pressed() -> void:
	if not StaffAccessRef.can(session, "destructive"):
		set_status("KEINE BERECHTIGUNG", true)
		return
	if not reset_armed:
		reset_armed = true
		if reset_button != null:
			reset_button.text = "NOCHMAL TIPPEN"
		set_status("RESET MUSS BESTÄTIGT WERDEN", true)
		return
	reset_armed = false
	action_requested.emit("reset_save", {})


func _permission_summary(permissions: Array) -> String:
	if "staff_manage" in permissions:
		return "ALLE RECHTE"
	if "economy" in permissions and "destructive" in permissions:
		return "GAME · SAVE · MOD"
	if "moderation" in permissions:
		return "MOD · LOGS"
	if "debug" in permissions:
		return "GAMEPLAY · QA"
	return "READ ONLY"


func _close() -> void:
	visible = false
	reset_armed = false
	closed.emit()
