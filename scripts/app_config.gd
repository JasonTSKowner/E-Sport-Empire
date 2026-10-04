class_name AppConfig
extends RefCounted

const APP_NAME := "E-Sport Empire"
const VERSION := "2.0.0-full-ui-rebuild"
const VERSION_BADGE := "V2.0"
const BUILD_CHANNEL := "FULL_UI_REBUILD"
const DEFAULT_PAGE := "home"

const NAV_ENTRIES := [
	["home", "START", "01"],
	["team", "TEAM", "02"],
	["play", "RANKED", "03"],
	["market", "SCOUT", "04"],
	["empire", "VEREIN", "05"],
]


static func navigation_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in NAV_ENTRIES:
		ids.append(str(entry[0]))
	return ids
