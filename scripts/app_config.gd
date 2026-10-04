class_name AppConfig
extends RefCounted

const APP_NAME := "E-Sport Empire"
const VERSION := "1.2.0-mobile-de"
const VERSION_BADGE := "V1.2 DE"
const BUILD_CHANNEL := "MOBILE_DE_REWORK"
const DEFAULT_PAGE := "home"

const NAV_ENTRIES := [
	["home", "START", "01"],
	["team", "TEAM", "02"],
	["play", "SPIELEN", "03"],
	["market", "SCOUTING", "04"],
	["empire", "VEREIN", "05"],
]


static func navigation_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in NAV_ENTRIES:
		ids.append(str(entry[0]))
	return ids
