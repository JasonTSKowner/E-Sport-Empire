extends SceneTree

const AppConfig = preload("res://scripts/app_config.gd")
const ChangelogData = preload("res://scripts/changelog_data.gd")
const StaffAccess = preload("res://scripts/staff_access.gd")
const StaffPanel = preload("res://scripts/staff_panel.gd")
const ShellV26 = preload("res://scripts/cinematic_shell_v26.gd")

var failures: Array[String] = []


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("V2.6 1/5: release metadata")
	_check(AppConfig.VERSION.begins_with("2.6."), "v2.6 app version")
	_check(ChangelogData.CURRENT_VERSION == "2.6.0", "v2.6 changelog version")

	print("V2.6 2/5: staff roles")
	_check(StaffAccess.ROLES.size() == 5, "five staff roles")
	var owner := StaffAccess.make_session("owner", "owner-test", "server", true)
	var admin := StaffAccess.make_session("admin", "admin-test", "server", true)
	var moderator := StaffAccess.make_session("moderator", "mod-test", "server", true)
	var support := StaffAccess.make_session("support", "support-test", "server", true)
	var qa := StaffAccess.make_session("qa", "qa-test", "server", true)
	_check(StaffAccess.can(owner, "staff_manage"), "owner can manage staff")
	_check(StaffAccess.can(owner, "destructive"), "owner can use destructive save tools")
	_check(StaffAccess.can(admin, "economy") and StaffAccess.can(admin, "moderation"), "admin has game and moderation tools")
	_check(not StaffAccess.can(admin, "staff_manage"), "admin cannot manage staff roles")
	_check(StaffAccess.can(moderator, "moderation") and not StaffAccess.can(moderator, "economy"), "moderator cannot edit economy")
	_check(StaffAccess.can(support, "view") and not StaffAccess.can(support, "ranked"), "support is read-only")
	_check(StaffAccess.can(qa, "debug") and not StaffAccess.can(qa, "destructive"), "qa gets gameplay debug without destructive saves")

	print("V2.6 3/5: production authentication boundary")
	var fake_backend := StaffAccess.session_from_backend({"user_id":"fake", "role":"owner", "server_verified":false})
	_check(not StaffAccess.is_active(fake_backend), "unverified backend payload cannot become staff")
	var verified_backend := StaffAccess.session_from_backend({"user_id":"verified-admin", "role":"admin", "server_verified":true})
	_check(StaffAccess.is_active(verified_backend), "verified backend session activates staff")
	_check(StaffAccess.can_action(verified_backend, "add_cash"), "verified admin can use economy action")
	_check(not StaffAccess.can_action(moderator, "add_cash"), "moderator action boundary enforced")
	_check(not StaffAccess.can_action(owner, "unknown_action"), "unknown staff actions denied")

	print("V2.6 4/5: panel compile")
	var panel := StaffPanel.new().configure(owner, {
		"build":"V2.6", "save_version":1, "level":1, "roster":1,
		"cash":"€0", "fans":"0", "playlist":"1v1", "mmr":100,
		"placements":0, "backup_enabled":false, "audit":[],
	})
	_check(panel != null, "staff panel compiles")
	_check(panel.get_child_count() >= 2, "staff panel builds mobile overlay")
	_check(not panel.visible, "staff panel starts hidden")
	panel.open_with(owner, {"build":"V2.6", "cash":"€0", "fans":"0", "audit":[]})
	_check(panel.visible, "staff panel opens for active staff")
	panel.free()

	print("V2.6 5/5: shell and main scene")
	var shell := ShellV26.new()
	_check(shell != null, "v2.6 shell compiles")
	shell.free()
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	_check(main_scene != null, "Main scene loads")
	if main_scene != null:
		var main := main_scene.instantiate()
		_check(main != null, "Main scene instantiates with staff shell")
		main.free()

	if failures.is_empty():
		print("E-Sport Empire v2.6 staff control smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("V2.6 staff control smoke test failed: %s" % failure)
		quit(1)
