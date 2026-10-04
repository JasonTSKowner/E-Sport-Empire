class_name AppConfig
extends RefCounted

const APP_NAME := "E-Sport Empire"
const VERSION := "2.0.0-art-direction"
const VERSION_BADGE := "V2.0"
const BUILD_CHANNEL := "ART_DIRECTION_RESET"
const DEFAULT_PAGE := "home"

const NAV_ENTRIES := [
	["home", "START", "01"],
	["play", "RANKED", "02"],
	["team", "TEAM", "03"],
	["empire", "VEREIN", "04"],
]


static func navigation_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in NAV_ENTRIES:
		ids.append(str(entry[0]))
	return ids
