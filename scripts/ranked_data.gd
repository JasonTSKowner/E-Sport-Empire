class_name RankedData
extends RefCounted

const PLAYLISTS := ["1v1", "2v2", "3v3"]
const DIVISION_ROMAN := ["I", "II", "III", "IV"]

const FAMILY_COLORS := {
	"Unranked": Color("74829d"),
	"Bronze": Color("c47b46"),
	"Silver": Color("c8d2df"),
	"Gold": Color("f3c34f"),
	"Platinum": Color("43ddd1"),
	"Diamond": Color("4d91ff"),
	"Champion": Color("a763f5"),
	"Grand Champion": Color("ff4f87"),
	"Supersonic Legend": Color("f4f3ff"),
}

const FAMILY_SHORT := {
	"Unranked": "UNRANKED",
	"Bronze": "BRONZE",
	"Silver": "SILVER",
	"Gold": "GOLD",
	"Platinum": "PLAT",
	"Diamond": "DIAMOND",
	"Champion": "CHAMP",
	"Grand Champion": "GC",
	"Supersonic Legend": "SSL",
}

# Tier I boundaries follow the requested Rocket League-style anchors. The
# intermediate tier boundaries are deliberately approximate and evenly split
# into four divisions by the helpers below.
const TIER_STARTS := {
	"1v1": [
		{"tier_name": "Bronze I", "family": "Bronze", "tier": 1, "minimum": 0},
		{"tier_name": "Bronze II", "family": "Bronze", "tier": 2, "minimum": 105},
		{"tier_name": "Bronze III", "family": "Bronze", "tier": 3, "minimum": 210},
		{"tier_name": "Silver I", "family": "Silver", "tier": 1, "minimum": 310},
		{"tier_name": "Silver II", "family": "Silver", "tier": 2, "minimum": 365},
		{"tier_name": "Silver III", "family": "Silver", "tier": 3, "minimum": 420},
		{"tier_name": "Gold I", "family": "Gold", "tier": 1, "minimum": 470},
		{"tier_name": "Gold II", "family": "Gold", "tier": 2, "minimum": 520},
		{"tier_name": "Gold III", "family": "Gold", "tier": 3, "minimum": 570},
		{"tier_name": "Platinum I", "family": "Platinum", "tier": 1, "minimum": 620},
		{"tier_name": "Platinum II", "family": "Platinum", "tier": 2, "minimum": 665},
		{"tier_name": "Platinum III", "family": "Platinum", "tier": 3, "minimum": 710},
		{"tier_name": "Diamond I", "family": "Diamond", "tier": 1, "minimum": 760},
		{"tier_name": "Diamond II", "family": "Diamond", "tier": 2, "minimum": 810},
		{"tier_name": "Diamond III", "family": "Diamond", "tier": 3, "minimum": 860},
		{"tier_name": "Champion I", "family": "Champion", "tier": 1, "minimum": 910},
		{"tier_name": "Champion II", "family": "Champion", "tier": 2, "minimum": 995},
		{"tier_name": "Champion III", "family": "Champion", "tier": 3, "minimum": 1080},
		{"tier_name": "Grand Champion I", "family": "Grand Champion", "tier": 1, "minimum": 1170},
		{"tier_name": "Grand Champion II", "family": "Grand Champion", "tier": 2, "minimum": 1225},
		{"tier_name": "Grand Champion III", "family": "Grand Champion", "tier": 3, "minimum": 1280},
		{"tier_name": "Supersonic Legend", "family": "Supersonic Legend", "tier": 0, "minimum": 1330},
	],
	"2v2": [
		{"tier_name": "Bronze I", "family": "Bronze", "tier": 1, "minimum": 0},
		{"tier_name": "Bronze II", "family": "Bronze", "tier": 2, "minimum": 125},
		{"tier_name": "Bronze III", "family": "Bronze", "tier": 3, "minimum": 250},
		{"tier_name": "Silver I", "family": "Silver", "tier": 1, "minimum": 370},
		{"tier_name": "Silver II", "family": "Silver", "tier": 2, "minimum": 430},
		{"tier_name": "Silver III", "family": "Silver", "tier": 3, "minimum": 490},
		{"tier_name": "Gold I", "family": "Gold", "tier": 1, "minimum": 550},
		{"tier_name": "Gold II", "family": "Gold", "tier": 2, "minimum": 600},
		{"tier_name": "Gold III", "family": "Gold", "tier": 3, "minimum": 650},
		{"tier_name": "Platinum I", "family": "Platinum", "tier": 1, "minimum": 700},
		{"tier_name": "Platinum II", "family": "Platinum", "tier": 2, "minimum": 750},
		{"tier_name": "Platinum III", "family": "Platinum", "tier": 3, "minimum": 800},
		{"tier_name": "Diamond I", "family": "Diamond", "tier": 1, "minimum": 850},
		{"tier_name": "Diamond II", "family": "Diamond", "tier": 2, "minimum": 910},
		{"tier_name": "Diamond III", "family": "Diamond", "tier": 3, "minimum": 970},
		{"tier_name": "Champion I", "family": "Champion", "tier": 1, "minimum": 1020},
		{"tier_name": "Champion II", "family": "Champion", "tier": 2, "minimum": 1140},
		{"tier_name": "Champion III", "family": "Champion", "tier": 3, "minimum": 1275},
		{"tier_name": "Grand Champion I", "family": "Grand Champion", "tier": 1, "minimum": 1435},
		{"tier_name": "Grand Champion II", "family": "Grand Champion", "tier": 2, "minimum": 1540},
		{"tier_name": "Grand Champion III", "family": "Grand Champion", "tier": 3, "minimum": 1660},
		{"tier_name": "Supersonic Legend", "family": "Supersonic Legend", "tier": 0, "minimum": 1860},
	],
	"3v3": [
		{"tier_name": "Bronze I", "family": "Bronze", "tier": 1, "minimum": 0},
		{"tier_name": "Bronze II", "family": "Bronze", "tier": 2, "minimum": 130},
		{"tier_name": "Bronze III", "family": "Bronze", "tier": 3, "minimum": 260},
		{"tier_name": "Silver I", "family": "Silver", "tier": 1, "minimum": 390},
		{"tier_name": "Silver II", "family": "Silver", "tier": 2, "minimum": 450},
		{"tier_name": "Silver III", "family": "Silver", "tier": 3, "minimum": 510},
		{"tier_name": "Gold I", "family": "Gold", "tier": 1, "minimum": 570},
		{"tier_name": "Gold II", "family": "Gold", "tier": 2, "minimum": 620},
		{"tier_name": "Gold III", "family": "Gold", "tier": 3, "minimum": 670},
		{"tier_name": "Platinum I", "family": "Platinum", "tier": 1, "minimum": 720},
		{"tier_name": "Platinum II", "family": "Platinum", "tier": 2, "minimum": 770},
		{"tier_name": "Platinum III", "family": "Platinum", "tier": 3, "minimum": 820},
		{"tier_name": "Diamond I", "family": "Diamond", "tier": 1, "minimum": 870},
		{"tier_name": "Diamond II", "family": "Diamond", "tier": 2, "minimum": 930},
		{"tier_name": "Diamond III", "family": "Diamond", "tier": 3, "minimum": 990},
		{"tier_name": "Champion I", "family": "Champion", "tier": 1, "minimum": 1040},
		{"tier_name": "Champion II", "family": "Champion", "tier": 2, "minimum": 1160},
		{"tier_name": "Champion III", "family": "Champion", "tier": 3, "minimum": 1290},
		{"tier_name": "Grand Champion I", "family": "Grand Champion", "tier": 1, "minimum": 1435},
		{"tier_name": "Grand Champion II", "family": "Grand Champion", "tier": 2, "minimum": 1540},
		{"tier_name": "Grand Champion III", "family": "Grand Champion", "tier": 3, "minimum": 1660},
		{"tier_name": "Supersonic Legend", "family": "Supersonic Legend", "tier": 0, "minimum": 1860},
	],
}

const TOP_NAMES := [
	"ZEN", "SOLAR", "RIFT", "KAIRO", "AERO", "ZENITH",
	"NEXO", "POLAR", "ONYX", "DRIFT", "PULSE", "ECHO",
]

const AROUND_NAMES := [
	"ArcNova", "Kinetic", "Mako", "Lynx", "Frostbyte", "Cairo",
	"Axiom", "Volt", "Sage", "Blaze", "Orbit", "Reign", "Clutch",
]


static func normalize_playlist(playlist: String) -> String:
	return playlist if playlist in PLAYLISTS else "1v1"


static func color_for_family(family: String) -> Color:
	return FAMILY_COLORS.get(family, FAMILY_COLORS["Unranked"])


static func unranked_data(mmr: int = 100) -> Dictionary:
	return {
		"name": "UNRANKED",
		"compact_name": "UNRANKED",
		"tier_name": "UNRANKED",
		"family": "Unranked",
		"family_short": "UNRANKED",
		"tier": 0,
		"division": 0,
		"division_roman": "",
		"minimum": 0,
		"next_minimum": 0,
		"maximum": 0,
		"mmr": mmr,
		"accent": color_for_family("Unranked").to_html(false),
	}


static func rank_for_mmr(mmr: int, playlist: String) -> Dictionary:
	var key := normalize_playlist(playlist)
	var starts: Array = TIER_STARTS[key]
	var tier_index := 0
	for index in range(starts.size()):
		if mmr >= int(starts[index]["minimum"]):
			tier_index = index
	var tier_data: Dictionary = starts[tier_index]
	var family := str(tier_data["family"])
	var accent := color_for_family(family)
	if family == "Supersonic Legend":
		return {
			"name": "Supersonic Legend",
			"compact_name": "SSL",
			"tier_name": "Supersonic Legend",
			"family": family,
			"family_short": FAMILY_SHORT[family],
			"tier": 0,
			"division": 0,
			"division_roman": "",
			"minimum": int(tier_data["minimum"]),
			"next_minimum": int(tier_data["minimum"]),
			"maximum": 9999,
			"mmr": mmr,
			"accent": accent.to_html(false),
		}

	var next_tier_min := int(starts[tier_index + 1]["minimum"])
	var tier_min := int(tier_data["minimum"])
	var division_step := maxf(1.0, float(next_tier_min - tier_min) / 4.0)
	var division := clampi(int(floor(float(mmr - tier_min) / division_step)) + 1, 1, 4)
	var division_min := int(round(float(tier_min) + division_step * float(division - 1)))
	var division_next := int(round(float(tier_min) + division_step * float(division)))
	if division == 4:
		division_next = next_tier_min
	var division_roman: String = str(DIVISION_ROMAN[division - 1])
	return {
		"name": "%s Division %s" % [str(tier_data["tier_name"]), division_roman],
		"compact_name": "%s • Div %s" % [str(tier_data["tier_name"]), division_roman],
		"tier_name": str(tier_data["tier_name"]),
		"family": family,
		"family_short": FAMILY_SHORT[family],
		"tier": int(tier_data["tier"]),
		"division": division,
		"division_roman": division_roman,
		"minimum": division_min,
		"next_minimum": division_next,
		"maximum": division_next - 1,
		"mmr": mmr,
		"accent": accent.to_html(false),
	}


static func next_rank_for_mmr(mmr: int, playlist: String) -> Dictionary:
	var current := rank_for_mmr(mmr, playlist)
	if str(current["family"]) == "Supersonic Legend":
		return current
	return rank_for_mmr(int(current["next_minimum"]), playlist)


static func progress_for_mmr(mmr: int, playlist: String) -> Dictionary:
	var current := rank_for_mmr(mmr, playlist)
	if str(current["family"]) == "Supersonic Legend":
		return {"value": 1, "maximum": 1, "percent": 100.0}
	var value := maxi(0, mmr - int(current["minimum"]))
	var maximum := maxi(1, int(current["next_minimum"]) - int(current["minimum"]))
	return {"value": value, "maximum": maximum, "percent": float(value) / float(maximum) * 100.0}


static func tier_rows(playlist: String) -> Array:
	var key := normalize_playlist(playlist)
	var starts: Array = TIER_STARTS[key]
	var rows: Array = []
	for index in range(starts.size()):
		var source: Dictionary = starts[index]
		var row := source.duplicate(true)
		row["accent"] = color_for_family(str(source["family"])).to_html(false)
		row["divisions"] = []
		if str(source["family"]) == "Supersonic Legend":
			row["divisions"].append({"division": "", "minimum": int(source["minimum"]), "maximum": 9999})
		else:
			var tier_min := int(source["minimum"])
			var next_min := int(starts[index + 1]["minimum"])
			var step := maxf(1.0, float(next_min - tier_min) / 4.0)
			for division_index in range(4):
				var minimum := int(round(float(tier_min) + step * float(division_index)))
				var maximum := int(round(float(tier_min) + step * float(division_index + 1))) - 1
				if division_index == 3:
					maximum = next_min - 1
				row["divisions"].append({
					"division": DIVISION_ROMAN[division_index],
					"minimum": minimum,
					"maximum": maximum,
				})
		rows.append(row)
	return rows


static func win_rate(record: Dictionary, season_only: bool = false) -> float:
	var wins := int(record.get("season_wins" if season_only else "wins", 0))
	var losses := int(record.get("season_losses" if season_only else "losses", 0))
	var total := wins + losses
	return 0.0 if total <= 0 else float(wins) / float(total) * 100.0


static func estimated_position(mmr: int, playlist: String) -> int:
	var key := normalize_playlist(playlist)
	var top_rows := top_ladder(key)
	for index in range(top_rows.size()):
		if mmr >= int(top_rows[index]["mmr"]):
			return index + 1
	var twelfth_mmr := int(top_rows[top_rows.size() - 1]["mmr"])
	var position := int(round(12.0 * exp(float(twelfth_mmr - mmr) / 180.0)))
	return clampi(position, 13, _playlist_population(key))


static func _playlist_population(playlist: String) -> int:
	if playlist == "2v2":
		return 138000
	if playlist == "3v3":
		return 112000
	return 82000


static func _mmr_for_position(position: int, playlist: String) -> int:
	var top_rows := top_ladder(playlist)
	if position <= top_rows.size():
		return int(top_rows[maxi(0, position - 1)]["mmr"])
	var twelfth_mmr := int(top_rows[top_rows.size() - 1]["mmr"])
	return maxi(0, twelfth_mmr - int(round(180.0 * log(float(position) / 12.0))))


static func top_ladder(playlist: String) -> Array:
	var key := normalize_playlist(playlist)
	var start := 1742
	if key == "2v2":
		start = 3002
	elif key == "3v3":
		start = 2246
	var gaps := [0, 21, 39, 58, 76, 93, 111, 129, 148, 169, 191, 216]
	var result: Array = []
	for index in range(TOP_NAMES.size()):
		var rating := start - int(gaps[index])
		result.append({
			"position": index + 1,
			"name": TOP_NAMES[index],
			"mmr": rating,
			"rank": rank_for_mmr(rating, key),
			"is_player": false,
		})
	return result


static func around_player(mmr: int, playlist: String) -> Array:
	var key := normalize_playlist(playlist)
	var own_position := estimated_position(mmr, key)
	var seed: int = absi((mmr * 17 + key.hash()) % AROUND_NAMES.size())
	var population := _playlist_population(key)
	var first_position := clampi(own_position - 3, 1, maxi(1, population - 6))
	var result: Array = []
	for row_index in range(7):
		var position := first_position + row_index
		var is_player := position == own_position
		var rating := mmr if is_player else _mmr_for_position(position, key)
		result.append({
			"position": position,
			"name": "KESHI" if is_player else AROUND_NAMES[(seed + row_index) % AROUND_NAMES.size()],
			"mmr": rating,
			"rank": rank_for_mmr(rating, key),
			"is_player": is_player,
		})
	return result
