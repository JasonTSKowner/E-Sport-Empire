class_name DynastyData
extends RefCounted

const STAFF_ROLES := [
	{
		"id": "head_coach",
		"name": "Head Coach",
		"short": "COACH",
		"color": "a779ff",
		"effect": "+0.25 team strength and +1 scrim chemistry per level.",
	},
	{
		"id": "tactical_analyst",
		"name": "Tactical Analyst",
		"short": "ANALYST",
		"color": "2de2ff",
		"effect": "+0.6 percentage points scoring chance per level, shown before every call.",
	},
	{
		"id": "performance_director",
		"name": "Performance Director",
		"short": "PERFORMANCE",
		"color": "58e39b",
		"effect": "3% training discount and +1.5 percentage points breakthrough chance per level.",
	},
	{
		"id": "content_director",
		"name": "Content Director",
		"short": "CONTENT",
		"color": "ffbf69",
		"effect": "+10% stream reach and +5% sponsor income per level.",
	},
]

const STAFF_CANDIDATES := [
	{
		"id": "coach_mara",
		"role": "head_coach",
		"name": "Mara Voss",
		"level": 1,
		"fee": 110,
		"rank": "Champion",
		"specialty": "Structure",
	},
	{
		"id": "coach_ren",
		"role": "head_coach",
		"name": "Ren Kova",
		"level": 2,
		"fee": 290,
		"rank": "Grand Champion",
		"specialty": "Team identity",
	},
	{
		"id": "coach_sol",
		"role": "head_coach",
		"name": "Sol Mercer",
		"level": 3,
		"fee": 620,
		"rank": "Supersonic Legend",
		"specialty": "Championship systems",
	},
	{
		"id": "analyst_ivy",
		"role": "tactical_analyst",
		"name": "Ivy Chen",
		"level": 1,
		"fee": 100,
		"rank": "Diamond",
		"specialty": "Opponent tendencies",
	},
	{
		"id": "analyst_orion",
		"role": "tactical_analyst",
		"name": "Orion Vale",
		"level": 2,
		"fee": 275,
		"rank": "Grand Champion",
		"specialty": "Live reads",
	},
	{
		"id": "analyst_nyx",
		"role": "tactical_analyst",
		"name": "Nyx Rahal",
		"level": 3,
		"fee": 590,
		"rank": "Supersonic Legend",
		"specialty": "Predictive analysis",
	},
	{
		"id": "performance_juno",
		"role": "performance_director",
		"name": "Juno Park",
		"level": 1,
		"fee": 95,
		"rank": "Champion",
		"specialty": "Efficient sessions",
	},
	{
		"id": "performance_kael",
		"role": "performance_director",
		"name": "Kael Stern",
		"level": 2,
		"fee": 260,
		"rank": "Grand Champion",
		"specialty": "Mechanical growth",
	},
	{
		"id": "performance_aya",
		"role": "performance_director",
		"name": "Aya North",
		"level": 3,
		"fee": 560,
		"rank": "Supersonic Legend",
		"specialty": "Elite development",
	},
	{
		"id": "content_milo",
		"role": "content_director",
		"name": "Milo Knox",
		"level": 1,
		"fee": 85,
		"rank": "Creator",
		"specialty": "Short-form clips",
	},
	{
		"id": "content_sena",
		"role": "content_director",
		"name": "Sena Cruz",
		"level": 2,
		"fee": 235,
		"rank": "Partner",
		"specialty": "Live audience",
	},
	{
		"id": "content_echo",
		"role": "content_director",
		"name": "Echo Laurent",
		"level": 3,
		"fee": 520,
		"rank": "Global",
		"specialty": "Brand growth",
	},
]

const SPONSOR_CONTRACTS := [
	{
		"id": "local_launch",
		"name": "LOCAL LAUNCH",
		"brand": "Nova Hydration",
		"color": "58e39b",
		"min_reputation": 1,
		"min_fans": 25,
		"duration": 6,
		"win_target": 2,
		"upfront": 60,
		"per_match": 4,
		"per_win": 8,
		"completion": 70,
	},
	{
		"id": "creator_push",
		"name": "CREATOR PUSH",
		"brand": "Pulse Gear",
		"color": "2de2ff",
		"min_reputation": 3,
		"min_fans": 100,
		"duration": 10,
		"win_target": 5,
		"upfront": 150,
		"per_match": 7,
		"per_win": 12,
		"completion": 180,
	},
	{
		"id": "pro_standard",
		"name": "PRO STANDARD",
		"brand": "Vertex Performance",
		"color": "a779ff",
		"min_reputation": 7,
		"min_fans": 500,
		"duration": 14,
		"win_target": 8,
		"upfront": 350,
		"per_match": 12,
		"per_win": 18,
		"completion": 400,
	},
]

const CIRCUIT_EVENTS := [
	{
		"id": "open_circuit",
		"name": "OPEN CIRCUIT",
		"tier": "OPEN",
		"color": "2de2ff",
		"min_matches": 3,
		"min_level": 1,
		"min_reputation": 0,
		"prize": 180,
		"fans": 45,
		"xp": 140,
		"strength_mod": -1.5,
		"detail": "An eight-team bracket and the first real trophy path.",
	},
	{
		"id": "challenger_circuit",
		"name": "CHALLENGER SERIES",
		"tier": "CHALLENGER",
		"color": "a779ff",
		"min_matches": 12,
		"min_level": 3,
		"min_reputation": 3,
		"prize": 420,
		"fans": 110,
		"xp": 260,
		"strength_mod": 3.0,
		"detail": "A stronger field with serious organization attention.",
	},
	{
		"id": "elite_circuit",
		"name": "ELITE INVITATIONAL",
		"tier": "ELITE",
		"color": "ffbf69",
		"min_matches": 28,
		"min_level": 6,
		"min_reputation": 8,
		"prize": 950,
		"fans": 260,
		"xp": 500,
		"strength_mod": 7.0,
		"detail": "The hardest non-ranked event in the current build.",
	},
]

const CIRCUIT_TEAMS := [
	{"name": "Nova Union", "seed": 1, "strength": 4.0},
	{"name": "Apex Core", "seed": 2, "strength": 3.0},
	{"name": "Titan Forge", "seed": 3, "strength": 2.0},
	{"name": "Royal Pulse", "seed": 4, "strength": 1.0},
	{"name": "Orbit Blue", "seed": 5, "strength": 0.0},
	{"name": "Vanguard", "seed": 6, "strength": -1.0},
	{"name": "Nightshift", "seed": 7, "strength": -2.0},
	{"name": "Solaris", "seed": 8, "strength": -3.0},
	{"name": "Zero Point", "seed": 9, "strength": 2.5},
	{"name": "Vertex Club", "seed": 10, "strength": 1.5},
	{"name": "Monarch RL", "seed": 11, "strength": 3.5},
	{"name": "Kinetic", "seed": 12, "strength": -0.5},
]

const SEASON_OBJECTIVES := [
	{
		"id": "season_matches",
		"label": "SHOW UP",
		"detail": "Play 10 competitive matches this season.",
		"key": "matches",
		"target": 10,
		"cash": 90,
		"xp": 70,
	},
	{
		"id": "season_wins",
		"label": "WINNING RECORD",
		"detail": "Win 5 competitive matches this season.",
		"key": "wins",
		"target": 5,
		"cash": 120,
		"xp": 90,
	},
	{
		"id": "season_reads",
		"label": "READ THE SERVER",
		"detail": "Make 12 perfect tactical reads.",
		"key": "perfect_reads",
		"target": 12,
		"cash": 110,
		"xp": 95,
	},
	{
		"id": "season_streams",
		"label": "BUILD THE AUDIENCE",
		"detail": "Stream 4 competitive matches.",
		"key": "streamed_matches",
		"target": 4,
		"cash": 100,
		"xp": 80,
	},
	{
		"id": "season_staff",
		"label": "FRONT OFFICE",
		"detail": "Hire 2 staff members.",
		"key": "staff_hires",
		"target": 2,
		"cash": 140,
		"xp": 110,
	},
	{
		"id": "season_circuit",
		"label": "LIFT THE TROPHY",
		"detail": "Win one Pro Circuit bracket.",
		"key": "circuit_titles",
		"target": 1,
		"cash": 250,
		"xp": 180,
	},
]


static func staff_role(role_id: String) -> Dictionary:
	for role_value in STAFF_ROLES:
		var role: Dictionary = role_value
		if str(role.get("id", "")) == role_id:
			return role
	return {}


static func staff_candidate(candidate_id: String) -> Dictionary:
	for candidate_value in STAFF_CANDIDATES:
		var candidate: Dictionary = candidate_value
		if str(candidate.get("id", "")) == candidate_id:
			return candidate
	return {}


static func sponsor_contract(contract_id: String) -> Dictionary:
	for contract_value in SPONSOR_CONTRACTS:
		var contract: Dictionary = contract_value
		if str(contract.get("id", "")) == contract_id:
			return contract
	return {}


static func circuit_event(event_id: String) -> Dictionary:
	for event_value in CIRCUIT_EVENTS:
		var event: Dictionary = event_value
		if str(event.get("id", "")) == event_id:
			return event
	return {}


static func season_objective(objective_id: String) -> Dictionary:
	for objective_value in SEASON_OBJECTIVES:
		var objective: Dictionary = objective_value
		if str(objective.get("id", "")) == objective_id:
			return objective
	return {}
