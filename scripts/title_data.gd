class_name TitleData
extends RefCounted

const RANK_REWARD_WINS := 10

const COLOR_GC := "ff5b93"
const COLOR_SSL := "f2efff"
const COLOR_TOP_100 := "3fe3ff"
const COLOR_TOP_10 := "b47aff"
const COLOR_WORLD_ONE := "ffc76b"


static func rank_title(season: int, family: String, playlist: String) -> Dictionary:
	var is_ssl := family == "Supersonic Legend"
	var slug := "supersonic_legend" if is_ssl else "grand_champion"
	return {
		"id": "s%d_%s" % [season, slug],
		"label": "S%d SUPERSONIC LEGEND" % season if is_ssl else "S%d GRAND CHAMPION" % season,
		"category": "SEASON RANK",
		"rarity": "LEGENDARY" if is_ssl else "ELITE",
		"accent": COLOR_SSL if is_ssl else COLOR_GC,
		"season": season,
		"playlist": playlist,
		"source": "%s ranked reward • %d wins" % [playlist, RANK_REWARD_WINS],
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


static func color_for(title: Dictionary) -> Color:
	return Color(str(title.get("accent", COLOR_TOP_100)))
