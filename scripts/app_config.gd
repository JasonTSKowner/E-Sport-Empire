class_name AppConfig
extends RefCounted

const APP_NAME := "E-Sport Empire"
const VERSION := "3.0.0-visual-rebuild"
const VERSION_BADGE := "V3.0"
const BUILD_CHANNEL := "VISUAL_REBUILD_3"
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
