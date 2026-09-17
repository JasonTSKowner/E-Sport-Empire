class_name TitleData
extends RefCounted

const RANK_REWARD_WINS := 10

const COLOR_GC := "ff5b93"
const COLOR_SSL := "f2efff"
const COLOR_TOP_100 := "3fe3ff"
const COLOR_TOP_10 := "b47aff"
const COLOR_WORLD_ONE := "ffc76b"

const RANK_FAMILIES := [
	"Bronze",
	"Silver",
	"Gold",
	"Platinum",
	"Diamond",
	"Champion",
	"Grand Champion",
	"Supersonic Legend",
]

const RANK_TITLE_META := {
	"Bronze": {"accent": "c9824b", "rarity": "ROOKIE"},
	"Silver": {"accent": "b9c4d6", "rarity": "COMMON"},
	"Gold": {"accent": "f0ca4d", "rarity": "UNCOMMON"},
	"Platinum": {"accent": "54d9e8", "rarity": "RARE"},
	"Diamond": {"accent": "3f9dff", "rarity": "PRESTIGE"},
	"Champion": {"accent": "a66cff", "rarity": "EPIC"},
	"Grand Champion": {"accent": COLOR_GC, "rarity": "ELITE"},
	"Supersonic Legend": {"accent": COLOR_SSL, "rarity": "LEGENDARY"},
}


static func rank_title(season: int, family: String, playlist: String) -> Dictionary:
	var normalized_family := family if family in RANK_FAMILIES else "Bronze"
	var meta: Dictionary = RANK_TITLE_META[normalized_family]
	var slug := normalized_family.to_lower().replace(" ", "_")
	var elite_reward := normalized_family in ["Grand Champion", "Supersonic Legend"]
	return {
		"id": "s%d_%s" % [season, slug],
		"label": "S%d %s" % [season, normalized_family.to_upper()],
		"category": "SEASON RANK",
		"rarity": str(meta.get("rarity", "RARE")),
		"accent": str(meta.get("accent", COLOR_TOP_100)),
		"season": season,
		"playlist": playlist,
		"source": (
			"%s ranked reward • %d wins" % [playlist, RANK_REWARD_WINS]
			if elite_reward
			else "Reached %s after ranked placements" % normalized_family
		),
	}


static func placement_title(season: int, playlist: String, position: int) -> Dictionary:
	var placement_key := "top_100"
	var placement_label := "TOP 100"
	var rarity := "ELITE"
	var accent := COLOR_TOP_100
	if position == 1:
		placement_key = "world_1"
		placement_label = "WORLD #1"
		rarity = "MYTHIC"
		accent = COLOR_WORLD_ONE
	elif position <= 10:
		placement_key = "top_10"
		placement_label = "TOP 10"
		rarity = "LEGENDARY"
		accent = COLOR_TOP_10
	return {
		"id": "s%d_%s_%s" % [season, playlist.replace("v", "x"), placement_key],
		"label": "S%d %s %s" % [season, playlist, placement_label],
		"category": "SEASON FINISH",
		"rarity": rarity,
		"accent": accent,
		"season": season,
		"playlist": playlist,
		"source": "Finished season %d at #%d in %s" % [season, position, playlist],
	}


static func circuit_title(season: int, event_id: String, event_name: String) -> Dictionary:
	var accent := "2de2ff"
	var rarity := "PRESTIGE"
	if event_id == "challenger_circuit":
		accent = "a779ff"
		rarity = "ELITE"
	elif event_id == "elite_circuit":
		accent = COLOR_WORLD_ONE
		rarity = "MYTHIC"
	return {
		"id": "s%d_circuit_%s" % [season, event_id],
		"label": "S%d %s CHAMPION" % [season, event_name.to_upper()],
		"category": "PRO CIRCUIT",
		"rarity": rarity,
		"accent": accent,
		"season": season,
		"playlist": "",
		"source": "Won all three rounds of %s" % event_name,
	}


static func color_for(title: Dictionary) -> Color:
	return Color(str(title.get("accent", COLOR_TOP_100)))
