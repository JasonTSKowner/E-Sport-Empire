class_name AppConfig
extends RefCounted

const APP_NAME := "E-Sport Empire"
const VERSION := "1.1.0-ui-fx"
const VERSION_BADGE := "V1.1 FX"
const BUILD_CHANNEL := "UI_FX_OVERHAUL"
const DEFAULT_PAGE := "home"

const NAV_ENTRIES := [
	["home", "HOME", "01"],
	["team", "TEAM", "02"],
	["play", "PLAY", "03"],
	["market", "SCOUT", "04"],
	["empire", "EMPIRE", "05"],
]


static func navigation_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in NAV_ENTRIES:
		ids.append(str(entry[0]))
	return ids
