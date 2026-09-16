class_name CoachingData
extends RefCounted

const FREE_OFFER_CHANCE := 0.0125
const OFFER_COUNT := 4

const COACH_NAMES := [
	"Aerial Aki",
	"Coach Cairo",
	"Dexo",
	"Echo",
	"Frost",
	"Kairo",
	"Mako",
	"Nexo",
	"Nova",
	"Onyx",
	"Pulse",
	"Rift",
	"Solar",
	"Vanta",
	"Volt",
]

const STYLES := [
	"Replay analyst",
	"Ranked specialist",
	"Mechanical coach",
	"Decision coach",
	"Pressure trainer",
	"Consistency mentor",
]

# Every paid session has a guaranteed improvement. The displayed chance only
# rolls the transparent extra gain, so coaching never behaves like a loot box.
const RANKS := [
	{
		"family": "Bronze",
		"tier": 3,
		"label": "Bronze III",
		"base_weight": 34.0,
		"base_price": 22,
		"guaranteed_gain": 1,
		"bonus_gain": 1,
		"bonus_chance": 0.10,
		"fatigue": 2,
	},
	{
		"family": "Silver",
		"tier": 3,
		"label": "Silver III",
		"base_weight": 24.0,
		"base_price": 38,
		"guaranteed_gain": 1,
		"bonus_gain": 1,
		"bonus_chance": 0.16,
		"fatigue": 2,
	},
	{
		"family": "Gold",
		"tier": 3,
		"label": "Gold III",
		"base_weight": 17.0,
		"base_price": 62,
		"guaranteed_gain": 2,
		"bonus_gain": 1,
		"bonus_chance": 0.22,
		"fatigue": 3,
	},
	{
		"family": "Platinum",
		"tier": 3,
		"label": "Platinum III",
		"base_weight": 11.0,
		"base_price": 96,
		"guaranteed_gain": 2,
		"bonus_gain": 1,
		"bonus_chance": 0.30,
		"fatigue": 3,
	},
	{
		"family": "Diamond",
		"tier": 3,
		"label": "Diamond III",
		"base_weight": 7.0,
		"base_price": 148,
		"guaranteed_gain": 3,
		"bonus_gain": 1,
		"bonus_chance": 0.38,
		"fatigue": 3,
	},
	{
		"family": "Champion",
		"tier": 3,
		"label": "Champion III",
		"base_weight": 4.0,
		"base_price": 225,
		"guaranteed_gain": 3,
		"bonus_gain": 2,
		"bonus_chance": 0.46,
		"fatigue": 4,
	},
	{
		"family": "Grand Champion",
		"tier": 3,
		"label": "Grand Champion III",
		"base_weight": 2.0,
		"base_price": 360,
		"guaranteed_gain": 4,
		"bonus_gain": 2,
		"bonus_chance": 0.56,
		"fatigue": 4,
	},
	{
		"family": "Supersonic Legend",
		"tier": 0,
		"label": "Supersonic Legend",
		"base_weight": 0.6,
		"base_price": 575,
		"guaranteed_gain": 5,
		"bonus_gain": 2,
		"bonus_chance": 0.68,
		"fatigue": 5,
	},
]


static func rank_definition(index: int) -> Dictionary:
	if index < 0 or index >= RANKS.size():
		return RANKS[0]
	return RANKS[index]

