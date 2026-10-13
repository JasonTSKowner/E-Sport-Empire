class_name StaffAccess
extends RefCounted

const ROLES := {
	"owner": {
		"label": "OWNER",
		"color": "FFB86B",
		"permissions": [
			"view", "economy", "ranked", "training", "save", "destructive",
			"moderation", "audit", "staff_manage", "debug"
		],
	},
	"admin": {
		"label": "ADMIN",
		"color": "FF6B7A",
		"permissions": [
			"view", "economy", "ranked", "training", "save", "destructive",
			"moderation", "audit", "debug"
		],
	},
	"moderator": {
		"label": "MODERATOR",
		"color": "74DFF7",
		"permissions": ["view", "moderation", "audit"],
	},
	"support": {
		"label": "SUPPORT",
		"color": "5DE1A5",
		"permissions": ["view", "audit"],
	},
	"qa": {
		"label": "QA / TEST",
		"color": "9DA8B7",
		"permissions": ["view", "ranked", "training", "audit", "debug"],
	},
}

const ACTION_PERMISSIONS := {
	"add_cash": "economy",
	"add_fans": "economy",
	"add_reputation": "economy",
	"mmr_delta": "ranked",
	"complete_placements": "ranked",
	"recover_training": "training",
	"save_now": "save",
	"create_backup": "save",
	"reset_save": "destructive",
	"refresh_ui": "view",
}


static func inactive_session() -> Dictionary:
	return {
		"active": false,
		"role": "none",
		"label": "NO STAFF ACCESS",
		"user_id": "",
		"source": "none",
		"server_verified": false,
		"permissions": [],
	}


static func role_definition(role: String) -> Dictionary:
	var key := role.to_lower()
	if not ROLES.has(key):
		return {}
	return (ROLES[key] as Dictionary).duplicate(true)


static func make_session(role: String, user_id: String = "staff", source: String = "server", server_verified: bool = true) -> Dictionary:
	var key := role.to_lower()
	var definition := role_definition(key)
	if definition.is_empty():
		return inactive_session()
	return {
		"active": true,
		"role": key,
		"label": str(definition.get("label", key.to_upper())),
		"color": str(definition.get("color", "74DFF7")),
		"user_id": user_id,
		"source": source,
		"server_verified": server_verified,
		"permissions": (definition.get("permissions", []) as Array).duplicate(),
	}


static func debug_session() -> Dictionary:
	# Debug APKs get a local OWNER preview so the staff UI can be tested without a backend.
	# Release builds intentionally get no staff session at all.
	if OS.is_debug_build():
		return make_session("owner", "local-debug-owner", "debug", false)
	return inactive_session()


static func session_from_backend(payload: Dictionary) -> Dictionary:
	# Production staff access must be confirmed by a trusted backend.
	if not bool(payload.get("server_verified", false)):
		return inactive_session()
	var role := str(payload.get("role", "")).to_lower()
	var user_id := str(payload.get("user_id", ""))
	if user_id.is_empty():
		return inactive_session()
	return make_session(role, user_id, "server", true)


static func is_active(session: Dictionary) -> bool:
	return bool(session.get("active", false)) and ROLES.has(str(session.get("role", "")).to_lower())


static func can(session: Dictionary, permission: String) -> bool:
	if not is_active(session):
		return false
	return permission in (session.get("permissions", []) as Array)


static func can_action(session: Dictionary, action: String) -> bool:
	var permission := str(ACTION_PERMISSIONS.get(action, ""))
	if permission.is_empty():
		return false
	return can(session, permission)


static func roles_for_ui() -> Array:
	var result: Array = []
	for key in ["owner", "admin", "moderator", "support", "qa"]:
		var definition := role_definition(key)
		definition["id"] = key
		result.append(definition)
	return result
