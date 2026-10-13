extends "res://scripts/cinematic_shell_v25.gd"

const StaffAccessV26 = preload("res://scripts/staff_access.gd")
const StaffPanelV26 = preload("res://scripts/staff_panel.gd")
const UIV26 = preload("res://scripts/ui_kit.gd")
const GameDataV26 = preload("res://scripts/game_data.gd")
const AppConfigV26 = preload("res://scripts/app_config.gd")

var staff_session: Dictionary = {}
var staff_panel: StaffPanel
var staff_audit: Array[String] = []


func _ready() -> void:
	staff_session = StaffAccessV26.debug_session()
	super._ready()
	_ensure_staff_panel()


func _build_top_bar() -> Control:
	var bar := super._build_top_bar()
	if not StaffAccessV26.is_active(staff_session):
		return bar
	if bar.get_child_count() <= 0:
		return bar
	var row := bar.get_child(0) as HBoxContainer
	if row == null:
		return bar
	var button := UIV26.button("STAFF", Color(str(staff_session.get("color", "FF6B7A"))), false, true)
	button.custom_minimum_size = Vector2(52, 32)
	button.add_theme_font_size_override("font_size", 8)
	button.tooltip_text = "Internal Staff Control"
	button.pressed.connect(_open_staff_panel)
	row.add_child(button)
	return bar


func _ensure_staff_panel() -> void:
	if staff_panel != null and is_instance_valid(staff_panel):
		return
	staff_panel = StaffPanelV26.new().configure(staff_session, _staff_snapshot())
	staff_panel.action_requested.connect(_on_staff_action)
	add_child(staff_panel)


func _open_staff_panel() -> void:
	if not StaffAccessV26.is_active(staff_session):
		return
	_ensure_staff_panel()
	staff_panel.open_with(staff_session, _staff_snapshot())


func _staff_snapshot() -> Dictionary:
	var playlist := game.selected_rl_playlist()
	var record := game.playlist_record(playlist)
	return {
		"build": AppConfigV26.VERSION_BADGE,
		"save_version": int(game.data.get("version", 0)),
		"level": game.career_level(),
		"roster": game.roster_for("Rocket League").size(),
		"cash": GameDataV26.format_cash(int(game.data.get("cash", 0))),
		"fans": GameDataV26.format_number(int(game.data.get("fans", 0))),
		"reputation": int(game.data.get("reputation", 0)),
		"playlist": playlist,
		"mmr": int(record.get("mmr", 100)),
		"placements": int(record.get("placements", 0)),
		"backup_enabled": _v23().backup_enabled(),
		"audit": staff_audit.duplicate(),
	}


func _on_staff_action(action: String, payload: Dictionary) -> void:
	if not StaffAccessV26.can_action(staff_session, action):
		_staff_result("Aktion blockiert: fehlende Berechtigung.", true)
		return

	var message := "Staff-Aktion ausgeführt."
	var refresh_game_ui := true
	match action:
		"add_cash":
			var cash_amount := maxi(0, int(payload.get("amount", 0)))
			game.data["cash"] = int(game.data.get("cash", 0)) + cash_amount
			game.save_game()
			message = "+%s Guthaben" % GameDataV26.format_cash(cash_amount)
		"add_fans":
			var fan_amount := maxi(0, int(payload.get("amount", 0)))
			game.data["fans"] = int(game.data.get("fans", 0)) + fan_amount
			game.save_game()
			message = "+%s Fans" % GameDataV26.format_number(fan_amount)
		"add_reputation":
			var rep_amount := maxi(0, int(payload.get("amount", 0)))
			game.data["reputation"] = clampi(int(game.data.get("reputation", 0)) + rep_amount, 0, 9999)
			game.save_game()
			message = "+%d Reputation" % rep_amount
		"mmr_delta":
			var playlist := game.selected_rl_playlist()
			var record := game.playlist_record(playlist)
			var before := int(record.get("mmr", 100))
			var after := clampi(before + int(payload.get("delta", 0)), 0, 4000)
			record["mmr"] = after
			record["peak_mmr"] = maxi(int(record.get("peak_mmr", after)), after)
			var history: Array = record.get("mmr_history", [])
			history.append(after)
			while history.size() > 120:
				history.pop_front()
			record["mmr_history"] = history
			game.save_game()
			message = "%s MMR: %d → %d" % [playlist, before, after]
		"complete_placements":
			var record := game.playlist_record(game.selected_rl_playlist())
			record["placements"] = 10
			game.save_game()
			message = "Placements auf 10/10 gesetzt"
		"recover_training":
			for player in game.data.get("roster", []):
				player["fatigue"] = 0
				player["training_history"] = []
			game.data["fatigue_updated_at"] = int(Time.get_unix_time_from_system())
			game.save_game()
			message = "Müdigkeit entfernt und Fokus wiederhergestellt"
		"save_now":
			game.save_game()
			message = "Spielstand manuell gespeichert"
			refresh_game_ui = false
		"create_backup":
			var backup := _v23().create_backup_code()
			if bool(backup.get("ok", false)):
				var code := str(backup.get("code", ""))
				if not code.is_empty():
					DisplayServer.clipboard_set(code)
				message = "Backup-Code erstellt und kopiert"
			else:
				_staff_result(str(backup.get("message", "Backup fehlgeschlagen.")), true)
				return
			refresh_game_ui = false
		"reset_save":
			game.reset_game()
			message = "Spielstand vollständig zurückgesetzt"
		"refresh_ui":
			message = "UI neu geladen"
		_:
			_staff_result("Unbekannte Staff-Aktion.", true)
			return

	_staff_log(action, message)
	if refresh_game_ui:
		_show_page(current_page, false)
	_staff_result(message, false)


func _staff_log(action: String, message: String) -> void:
	var stamp := Time.get_time_string_from_system()
	var role := str(staff_session.get("label", "STAFF"))
	staff_audit.push_front("%s  ·  %s  ·  %s  ·  %s" % [stamp, role, action.to_upper(), message])
	while staff_audit.size() > 30:
		staff_audit.pop_back()


func _staff_result(message: String, is_error: bool) -> void:
	if staff_panel == null or not is_instance_valid(staff_panel):
		return
	staff_panel.refresh(_staff_snapshot())
	staff_panel.visible = true
	staff_panel.set_status(message, is_error)
