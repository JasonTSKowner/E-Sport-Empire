class_name AppConfig
extends RefCounted

const APP_NAME := "E-Sport Empire"
const VERSION := "1.3.0-visual-rebuild"
const VERSION_BADGE := "V1.3 FX"
const BUILD_CHANNEL := "VISUAL_REBUILD"
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
