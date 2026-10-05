class_name SetupData
extends RefCounted

const CATEGORIES := ["controller", "display", "internet", "desk", "audio"]

const SETUPS := {
	"controller": {
		"name": "Controller",
		"icon": "PAD",
		"tiers": [
			{"name": "Standard Pad", "cost": 0, "training": 0.00, "consistency": 0.00},
			{"name": "Hall-Effect Pad", "cost": 95, "training": 0.015, "consistency": 0.012},
			{"name": "Pro Controller", "cost": 240, "training": 0.028, "consistency": 0.022},
			{"name": "Custom Team Pad", "cost": 520, "training": 0.040, "consistency": 0.032},
		],
	},
	"display": {
		"name": "Display",
		"icon": "HZ",
		"tiers": [
			{"name": "60 Hz TV", "cost": 0, "training": 0.00, "consistency": 0.00},
			{"name": "120 Hz Monitor", "cost": 180, "training": 0.012, "consistency": 0.010},
			{"name": "240 Hz Esports Monitor", "cost": 430, "training": 0.022, "consistency": 0.018},
			{"name": "360 Hz Pro Display", "cost": 760, "training": 0.030, "consistency": 0.026},
		],
	},
	"internet": {
		"name": "Internet",
		"icon": "NET",
		"tiers": [
			{"name": "Basis-WLAN", "cost": 0, "stability": 0.88, "ping": 46, "consistency": -0.012},
			{"name": "Wi-Fi 6 Router", "cost": 110, "stability": 0.94, "ping": 36, "consistency": 0.000},
			{"name": "LAN + Gaming Router", "cost": 230, "stability": 0.975, "ping": 28, "consistency": 0.012},
			{"name": "Fiber + Pro LAN", "cost": 490, "stability": 0.995, "ping": 20, "consistency": 0.020},
		],
	},
	"desk": {
		"name": "Desk & Ergonomie",
		"icon": "ERG",
		"tiers": [
			{"name": "Starter Desk", "cost": 0, "fatigue_relief": 0},
			{"name": "Ergo Chair + Desk", "cost": 170, "fatigue_relief": 1},
			{"name": "Pro Gaming Setup", "cost": 390, "fatigue_relief": 2},
			{"name": "Team Practice Station", "cost": 720, "fatigue_relief": 3},
		],
	},
	"audio": {
		"name": "Audio",
		"icon": "AUD",
		"tiers": [
			{"name": "Basic Headset", "cost": 0, "sense": 0.00},
			{"name": "Studio Headset", "cost": 90, "sense": 0.008},
			{"name": "Competitive Audio", "cost": 220, "sense": 0.014},
			{"name": "Team Comms Rig", "cost": 410, "sense": 0.020},
		],
	},
}


static func definition(key: String) -> Dictionary:
	return SETUPS.get(key, {}).duplicate(true)


static func max_level(key: String) -> int:
	var tiers: Array = SETUPS.get(key, {}).get("tiers", [])
	return maxi(0, tiers.size() - 1)


static func tier(key: String, level: int) -> Dictionary:
	var tiers: Array = SETUPS.get(key, {}).get("tiers", [])
	if tiers.is_empty():
		return {}
	return tiers[clampi(level, 0, tiers.size() - 1)].duplicate(true)


static func next_cost(key: String, level: int) -> int:
	if level >= max_level(key):
		return 0
	return int(tier(key, level + 1).get("cost", 0))
