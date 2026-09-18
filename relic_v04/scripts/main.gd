extends Node2D

const D = preload("res://scripts/game_data.gd")
const W := 720.0
const H := 1280.0
const SAVE_PATH := "user://relic_v04_save.json"
const MAX_INV := 30

var font: Font
var rng := RandomNumberGenerator.new()

# Economy / progression
var gold := 1200
var essence := 45
var gems := 20
var shards := 0
var ascension_seeds := 0
var stage := 1
var wave := 0
var total_kills := 0
var boss_kills := 0
var player_level := 1
var player_xp := 0
var ascensions := 0

# Relic Core progression
var core_level := 1
var luck_level := 1
var quality_level := 1
var speed_level := 1
var pity_level := 1
var pity := 0
var auto_roll := false
var auto_equip := true
var auto_sell_threshold := 0

# Combat stats
var hero_power := 48.0
var hero_hp := 160.0
var hero_hp_max := 160.0
var crit_chance := 0.12
var crit_mult := 1.75
var haste := 0.0
var dodge := 0.03
var leech := 0.0
var armor := 0.0
var shield := 0.0
var rage := 0.0
var combo := 0
var combo_timer := 0.0
var skill_levels := [1, 1, 1]
var skill_timers := [0.0, 0.0, 0.0]
var active_pet := 0
var pet_levels := [1, 1, 1, 1, 1]

# Enemy state
var enemy: Dictionary = {}
var enemy_hp := 100.0
var enemy_hp_max := 100.0
var enemy_attack_cd := 1.6
var enemy_timer := 0.0
var enemy_elite := false
var enemy_boss := false

# Gear / loot
var equipped := [{},{},{},{},{},{}]
var inventory: Array[Dictionary] = []
var current_item: Dictionary = {}
var loot_history: Array[String] = []
var codex_seen := {}
var set_counts := {}

# Meta
var daily_claim_day := -1
var quests_claimed := [false,false,false,false,false,false]
var achievements_claimed := [false,false,false,false,false,false]
var last_save_unix := 0
var offline_message := ""

# UI / animation
var active_tab := 2
var panel_open := false
var panel_page := 0
var toast := ""
var toast_timer := 0.0
var time_alive := 0.0
var battle_timer := 0.0
var auto_roll_timer := 0.0
var hit_flash := 0.0
var enemy_hit_flash := 0.0
var loot_flash := 0.0
var core_pulse := 0.0
var camera_shake := 0.0
var boss_intro := 0.0
var weather_clock := 0.0
var skill_flash := 0.0
var last_crit := false

var projectiles: Array[Dictionary] = []
var damage_numbers: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var weather_particles: Array[Dictionary] = []
var screen_rings: Array[Dictionary] = []

func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	_load_save()
	_apply_offline_rewards()
	_daily_claim()
	_recalc_stats()
	_spawn_enemy()
	_seed_weather()
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	time_alive += delta
	weather_clock += delta
	battle_timer += delta
	enemy_timer += delta
	auto_roll_timer += delta
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo = 0
	hero_hp = minf(hero_hp + hero_hp_max * 0.003 * delta, hero_hp_max)
	hit_flash = maxf(0.0, hit_flash - delta * 4.5)
	enemy_hit_flash = maxf(0.0, enemy_hit_flash - delta * 6.5)
	loot_flash = maxf(0.0, loot_flash - delta * 2.4)
	core_pulse = maxf(0.0, core_pulse - delta * 2.8)
	camera_shake = maxf(0.0, camera_shake - delta * 24.0)
	boss_intro = maxf(0.0, boss_intro - delta)
	skill_flash = maxf(0.0, skill_flash - delta * 4.0)
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast = ""

	for i in 3:
		skill_timers[i] = maxf(0.0, float(skill_timers[i]) - delta)

	var attack_interval := maxf(0.31, 0.82 / (1.0 + haste))
	if battle_timer >= attack_interval:
		battle_timer = 0.0
		_hero_attack()

	if enemy_timer >= enemy_attack_cd:
		enemy_timer = 0.0
		_enemy_attack()

	_try_auto_skills()

	if auto_roll and current_item.is_empty():
		var roll_delay := maxf(0.34, 1.05 - float(speed_level) * 0.025)
		if auto_roll_timer >= roll_delay:
			auto_roll_timer = 0.0
			_roll_loot()

	_update_fx(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	var p := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		p = event.position
		pressed = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		p = event.position
		pressed = true
	if not pressed:
		return

	if not current_item.is_empty():
		if Rect2(55, 914, 185, 72).has_point(p):
			_equip_current()
			return
		if Rect2(268, 914, 185, 72).has_point(p):
			_keep_current()
			return
		if Rect2(481, 914, 185, 72).has_point(p):
			_sell_current()
			return
		return

	if boss_intro > 0.15:
		return

	if panel_open:
		if _handle_panel_input(p):
			return
		if not Rect2(30, 690, 660, 445).has_point(p):
			panel_open = false
			active_tab = 2
			queue_redraw()
		return

	# Daily gift / top badge
	if Rect2(605, 178, 88, 48).has_point(p):
		_show_toast("Daily reward already checked")
		return

	# Skills
	for i in 3:
		var rect := Rect2(210 + i * 102, 698, 86, 86)
		if rect.has_point(p) and stage >= int(D.SKILLS[i]["unlock"]):
			_cast_skill(i, true)
			return

	# Ultimate
	if Rect2(532, 696, 105, 88).has_point(p) and rage >= 100.0:
		_cast_ultimate()
		return

	# Relic core
	if Rect2(237, 820, 246, 218).has_point(p):
		_roll_loot()
		return
	if Rect2(38, 932, 162, 62).has_point(p):
		_upgrade_core()
		return
	if Rect2(520, 932, 162, 62).has_point(p):
		auto_roll = not auto_roll
		_show_toast("Auto Draw %s" % ("ON" if auto_roll else "OFF"))
		_save()
		return

	# Bottom navigation
	if p.y >= 1162.0:
		active_tab = clampi(int(p.x / 144.0), 0, 4)
		panel_open = true
		panel_page = 0
		return

func _handle_panel_input(p: Vector2) -> bool:
	if not Rect2(30,690,660,445).has_point(p):
		return false

	# close
	if Rect2(632,704,42,42).has_point(p):
		panel_open = false
		active_tab = 2
		return true

	match active_tab:
		0:
			if Rect2(60,1038,180,58).has_point(p):
				_auto_equip_inventory()
				return true
			if Rect2(270,1038,180,58).has_point(p):
				_salvage_inventory()
				return true
			if Rect2(480,1038,180,58).has_point(p):
				auto_sell_threshold = (auto_sell_threshold + 1) % 8
				_show_toast("Auto-sell below %s" % D.RARITIES[auto_sell_threshold])
				_save()
				return true
		1:
			for i in 3:
				if Rect2(72,800+i*88,576,68).has_point(p):
					_upgrade_skill(i)
					return true
		2:
			var rects := [
				Rect2(65,812,270,70), Rect2(385,812,270,70),
				Rect2(65,902,270,70), Rect2(385,902,270,70)
			]
			for i in 4:
				if rects[i].has_point(p):
					_upgrade_core_stat(i)
					return true
			if Rect2(185,1002,350,72).has_point(p):
				_try_ascend()
				return true
		3:
			for i in 5:
				if Rect2(65,786+i*58,390,48).has_point(p):
					if stage >= int(D.PETS[i]["unlock"]):
						active_pet = i
						_show_toast("%s is now active" % D.PETS[i]["name"])
						_recalc_stats()
						_save()
					else:
						_show_toast("Unlocks at Stage %d" % int(D.PETS[i]["unlock"]))
					return true
			if Rect2(475,904,175,62).has_point(p):
				_upgrade_pet()
				return true
		4:
			if Rect2(180,1035,360,62).has_point(p):
				_claim_all_quests()
				return true
	return true

# -------------------------------------------------------------------
# COMBAT
# -------------------------------------------------------------------

func _hero_attack() -> void:
	if enemy.is_empty() or enemy_hp <= 0.0:
		return
	var crit := rng.randf() < crit_chance
	var base := hero_power * rng.randf_range(0.90,1.12)
	var combo_mult := 1.0 + minf(0.35, float(combo) * 0.015)
	var dmg := base * combo_mult * (crit_mult if crit else 1.0)
	last_crit = crit
	_deal_damage(dmg, crit, Color("#8dff77"), "basic")
	combo += 1
	combo_timer = 2.2
	rage = minf(100.0, rage + (7.0 if crit else 4.0))

func _deal_damage(dmg: float, crit: bool, color: Color, kind: String) -> void:
	enemy_hp -= dmg
	enemy_hit_flash = 1.0
	camera_shake = 7.0 if crit else 2.5
	var yoff := rng.randf_range(-25,18)
	projectiles.append({
		"from":Vector2(254,552),
		"to":Vector2(502,535+yoff),
		"t":0.0,
		"life":0.20 if kind == "basic" else 0.34,
		"color":color,
		"size":8.0 if kind == "basic" else 13.0
	})
	damage_numbers.append({
		"pos":Vector2(520+rng.randf_range(-30,30),470+rng.randf_range(-10,18)),
		"text":("%d!" % int(dmg)) if crit else ("%d" % int(dmg)),
		"life":0.82,
		"color":Color("#ffe66e") if crit else color,
		"size":30 if crit else 23
	})
	if leech > 0.0:
		hero_hp = minf(hero_hp_max, hero_hp + dmg * leech)
	if enemy_hp <= 0.0:
		_on_enemy_defeated()

func _enemy_attack() -> void:
	if enemy.is_empty() or enemy_hp <= 0.0:
		return
	if rng.randf() < dodge:
		damage_numbers.append({"pos":Vector2(220,470),"text":"DODGE","life":0.7,"color":Color("#9ff8ff"),"size":21})
		return
	var attack_mult := float(enemy.get("atk",1.0))
	var dmg := (7.0 + pow(float(stage),1.18)*1.9) * attack_mult
	dmg *= maxf(0.35, 1.0 - armor)
	if shield > 0.0:
		var absorbed := minf(shield,dmg)
		shield -= absorbed
		dmg -= absorbed
		damage_numbers.append({"pos":Vector2(230,492),"text":"BLOCK %d" % int(absorbed),"life":0.65,"color":Color("#ffe98a"),"size":18})
	if dmg > 0.0:
		hero_hp -= dmg
		hit_flash = 1.0
		camera_shake = 3.5
		damage_numbers.append({"pos":Vector2(220,468),"text":"-%d" % int(dmg),"life":0.75,"color":Color("#ff9f9f"),"size":22})
	if hero_hp <= 0.0:
		hero_hp = hero_hp_max
		shield = 0.0
		combo = 0
		rage = maxf(0.0,rage-30.0)
		_show_toast("Sprout recovered at camp")

func _try_auto_skills() -> void:
	for i in 3:
		if stage < int(D.SKILLS[i]["unlock"]):
			continue
		if float(skill_timers[i]) <= 0.0:
			_cast_skill(i, false)

func _cast_skill(index: int, manual: bool) -> void:
	if index < 0 or index >= 3:
		return
	if stage < int(D.SKILLS[index]["unlock"]):
		return
	if manual and float(skill_timers[index]) > 0.0:
		return
	var skill: Dictionary = D.SKILLS[index]
	skill_timers[index] = maxf(1.0, float(skill["cd"]) * (1.0 - minf(0.35,haste*0.2)))
	var lvl := float(skill_levels[index])
	skill_flash = 1.0
	if index == 2:
		shield = maxf(shield, hero_hp_max * (0.18 + lvl*0.018))
		_spawn_burst(Vector2(235,535),Color(skill["color"]),18)
		damage_numbers.append({"pos":Vector2(235,450),"text":"GUARD","life":0.9,"color":Color(skill["color"]),"size":26})
	else:
		var mult := float(skill["mult"]) * (1.0 + (lvl-1.0)*0.08)
		var crit := rng.randf() < crit_chance * 0.7
		_deal_damage(hero_power*mult*(crit_mult if crit else 1.0),crit,Color(skill["color"]),"skill")
		_spawn_burst(Vector2(505,525),Color(skill["color"]),22)

func _cast_ultimate() -> void:
	rage = 0.0
	skill_flash = 1.0
	screen_rings.append({"pos":Vector2(360,520),"r":20.0,"life":0.8,"color":Color("#fff091")})
	var dmg := hero_power * 7.5 * (1.0 + float(ascensions)*0.05)
	_deal_damage(dmg,true,Color("#fff091"),"ultimate")
	_spawn_burst(Vector2(505,525),Color("#fff091"),38)
	_show_toast("WILDBLOOM!")

func _on_enemy_defeated() -> void:
	total_kills += 1
	player_xp += 8 + stage * 2
	gold += int((20 + stage*5) * _gold_bonus())
	essence += 1 + int(stage/5)
	if enemy_elite:
		shards += 2 + int(stage/10)
	if enemy_boss:
		boss_kills += 1
		gems += 3 + int(stage/10)
		shards += 5 + int(stage/6)
		ascension_seeds += 1
		_show_toast("Boss defeated!")
		_spawn_burst(Vector2(510,525),Color("#ffe27a"),32)
	while player_xp >= _xp_needed():
		player_xp -= _xp_needed()
		player_level += 1
		gems += 1
		_show_toast("Level %d!" % player_level)

	wave += 1
	if wave >= (1 if enemy_boss else 6):
		wave = 0
		stage += 1
		_on_stage_advance()
	_spawn_enemy()
	_save()

func _on_stage_advance() -> void:
	var biome := _biome_index()
	if stage % 10 == 0:
		boss_intro = 1.2
	if stage % 5 == 1:
		_show_toast("%s" % D.BIOMES[biome]["name"])
		_seed_weather()

func _spawn_enemy() -> void:
	enemy_boss = stage % 10 == 0 and wave == 0
	enemy_elite = not enemy_boss and stage >= 5 and rng.randf() < minf(0.22,0.08+stage*0.002)
	if enemy_boss:
		var bidx := int(stage/10-1) % D.BOSSES.size()
		enemy = D.BOSSES[bidx].duplicate(true)
		enemy["shape"] = "boss"
		enemy["hp"] = 4.2
		enemy["atk"] = 1.65
		enemy["speed"] = 0.72
	else:
		var idx := (stage + wave + rng.randi_range(0,2)) % D.ENEMIES.size()
		enemy = D.ENEMIES[idx].duplicate(true)
	var hp_mult := float(enemy.get("hp",1.0))
	if enemy_elite:
		hp_mult *= 2.1
	enemy_hp_max = (82.0 + pow(float(stage),1.36)*19.0) * hp_mult * (1.0 + float(ascensions)*0.18)
	enemy_hp = enemy_hp_max
	enemy_attack_cd = maxf(0.65,1.62/float(enemy.get("speed",1.0)))
	enemy_timer = 0.0

func _xp_needed() -> int:
	return 30 + player_level * 16

func _gold_bonus() -> float:
	var bonus := 1.0
	if active_pet == 0 and stage >= int(D.PETS[0]["unlock"]):
		bonus += 0.12 + float(pet_levels[0])*0.008
	return bonus

# -------------------------------------------------------------------
# LOOT / ITEMS
# -------------------------------------------------------------------

func _roll_loot() -> void:
	if essence <= 0:
		auto_roll = false
		_show_toast("Need Core Energy")
		return
	essence -= 1
	pity += 1
	var rarity := _roll_rarity()
	var slot := rng.randi_range(0,D.SLOTS.size()-1)
	var roll_quality := 0.86 + rng.randf()*0.32 + float(quality_level)*0.012
	var rarity_mult := pow(1.29,float(rarity))
	var base_power := 26.0 + float(core_level)*4.1 + float(stage)*2.1 + float(ascensions)*22.0
	var power := int(base_power*rarity_mult*roll_quality)
	var name_pool: Array = D.ITEM_BASES[slot]
	var base_name := str(name_pool[rng.randi_range(0,name_pool.size()-1)])
	var item := {
		"id": "%d_%d" % [Time.get_unix_time_from_system(),rng.randi()],
		"rarity":rarity,
		"slot":slot,
		"name":"%s %s" % [D.RARITIES[rarity],base_name],
		"power":power,
		"level":0,
		"locked":false,
		"set":"",
		"affixes":[]
	}
	var affix_count := clampi(1 + int(rarity/5),1,4)
	for i in affix_count:
		var aff: Dictionary = D.AFFIXES[rng.randi_range(0,D.AFFIXES.size()-1)]
		var value := rng.randf_range(float(aff["min"]),float(aff["max"])) * (1.0 + rarity*0.035)
		item["affixes"].append({"name":aff["name"],"key":aff["key"],"value":snappedf(value,0.1)})
	if rarity >= 5:
		item["set"] = D.SETS[(slot + rarity + rng.randi_range(0,3)) % D.SETS.size()]
	current_item = item
	codex_seen[D.RARITIES[rarity]] = true
	loot_history.push_front("%s · %s" % [D.RARITIES[rarity],base_name])
	if loot_history.size() > 10:
		loot_history.resize(10)
	loot_flash = 1.0
	core_pulse = 1.0
	_spawn_burst(Vector2(360,918),_rarity_color(rarity),18+mini(30,rarity))
	if rarity < auto_sell_threshold:
		_sell_current(true)
	elif auto_equip and _is_upgrade(item):
		_equip_current(true)
	_save()

func _roll_rarity() -> int:
	var max_rarity := mini(49,6 + int(core_level/2) + ascensions*2)
	var hard_pity := maxi(12,30-pity_level)
	if pity >= hard_pity:
		pity = 0
		return mini(max_rarity,maxi(5,int(max_rarity*0.68)))
	var weights: Array[float] = []
	var total := 0.0
	for i in max_rarity+1:
		var w := pow(0.50,float(i))
		w *= 1.0 + float(luck_level)*0.018*float(i)
		if pity >= 8 and i >= 4:
			w *= 1.0 + float(pity-7)*0.12
		weights.append(w)
		total += w
	var r := rng.randf()*total
	var acc := 0.0
	for i in weights.size():
		acc += weights[i]
		if r <= acc:
			if i >= 6:
				pity = 0
			return i
	return 0

func _is_upgrade(item: Dictionary) -> bool:
	var slot := int(item.get("slot",0))
	if equipped[slot].is_empty():
		return true
	return _item_score(item) > _item_score(equipped[slot])

func _item_score(item: Dictionary) -> float:
	var score := float(item.get("power",0))
	for a in item.get("affixes",[]):
		score += float(a.get("value",0.0))*8.0
	score *= 1.0 + float(item.get("level",0))*0.04
	return score

func _equip_current(silent := false) -> void:
	if current_item.is_empty():
		return
	var slot := int(current_item["slot"])
	if not equipped[slot].is_empty():
		_store_item(equipped[slot])
	equipped[slot] = current_item.duplicate(true)
	current_item = {}
	_recalc_stats()
	if not silent:
		_show_toast("Equipped!")
	_save()

func _keep_current() -> void:
	if current_item.is_empty():
		return
	if inventory.size() >= MAX_INV:
		_show_toast("Inventory full")
		return
	inventory.append(current_item.duplicate(true))
	current_item = {}
	_show_toast("Stored")
	_save()

func _sell_current(silent := false) -> void:
	if current_item.is_empty():
		return
	var gain := maxi(8,int(_item_score(current_item)/8.0))
	gold += gain
	if int(current_item.get("rarity",0)) >= 5:
		shards += 1 + int(current_item.get("rarity",0)/8)
	current_item = {}
	if not silent:
		_show_toast("+%d Gold" % gain)
	_save()

func _store_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	if inventory.size() < MAX_INV:
		inventory.append(item.duplicate(true))
	else:
		gold += maxi(5,int(_item_score(item)/10.0))

func _auto_equip_inventory() -> void:
	var changed := false
	for idx in range(inventory.size()-1,-1,-1):
		var item: Dictionary = inventory[idx]
		if _is_upgrade(item):
			var slot := int(item.get("slot",0))
			if not equipped[slot].is_empty():
				inventory.append(equipped[slot].duplicate(true))
			equipped[slot] = item.duplicate(true)
			inventory.remove_at(idx)
			changed = true
	_recalc_stats()
	_show_toast("Best gear equipped" if changed else "Already optimal")
	_save()

func _salvage_inventory() -> void:
	var keep: Array[Dictionary] = []
	var gained_gold := 0
	var gained_shards := 0
	for item in inventory:
		if bool(item.get("locked",false)) or int(item.get("rarity",0)) >= maxi(4,auto_sell_threshold):
			keep.append(item)
		else:
			gained_gold += maxi(5,int(_item_score(item)/10.0))
			if int(item.get("rarity",0)) >= 5:
				gained_shards += 1
	inventory = keep
	gold += gained_gold
	shards += gained_shards
	_show_toast("Salvaged +%dG +%d shards" % [gained_gold,gained_shards])
	_save()

# -------------------------------------------------------------------
# UPGRADES / META
# -------------------------------------------------------------------

func _upgrade_core() -> void:
	var cost: int = _core_cost()
	if gold < cost:
		_show_toast("Need %d Gold" % cost)
		return
	gold -= cost
	core_level += 1
	if core_level % 3 == 0: luck_level += 1
	if core_level % 5 == 0: quality_level += 1
	if core_level % 7 == 0: speed_level += 1
	core_pulse = 1.0
	_show_toast("Relic Core Lv.%d" % core_level)
	_save()

func _core_cost() -> int:
	return int(120.0*pow(1.11,float(core_level-1)))

func _upgrade_core_stat(index: int) -> void:
	var names := ["Luck","Quality","Speed","Pity"]
	var levels := [luck_level,quality_level,speed_level,pity_level]
	var cost: int = 6 + int(levels[index])*3
	if shards < cost:
		_show_toast("Need %d shards" % cost)
		return
	shards -= cost
	match index:
		0: luck_level += 1
		1: quality_level += 1
		2: speed_level += 1
		3: pity_level += 1
	_show_toast("%s upgraded" % names[index])
	_save()

func _upgrade_skill(index: int) -> void:
	if stage < int(D.SKILLS[index]["unlock"]):
		_show_toast("Unlocks at Stage %d" % int(D.SKILLS[index]["unlock"]))
		return
	var cost: int = 180*(skill_levels[index]+1)
	if gold < cost:
		_show_toast("Need %d Gold" % cost)
		return
	gold -= cost
	skill_levels[index] += 1
	_show_toast("%s Lv.%d" % [D.SKILLS[index]["name"],skill_levels[index]])
	_save()

func _upgrade_pet() -> void:
	if stage < int(D.PETS[active_pet]["unlock"]):
		_show_toast("Pet not unlocked")
		return
	var cost: int = 4 + pet_levels[active_pet]*2
	if shards < cost:
		_show_toast("Need %d shards" % cost)
		return
	shards -= cost
	pet_levels[active_pet] += 1
	_recalc_stats()
	_show_toast("%s Lv.%d" % [D.PETS[active_pet]["name"],pet_levels[active_pet]])
	_save()

func _try_ascend() -> void:
	var required_stage := 50 + ascensions*25
	if stage < required_stage:
		_show_toast("Reach Stage %d" % required_stage)
		return
	var required_seeds := 5 + ascensions*2
	if ascension_seeds < required_seeds:
		_show_toast("Need %d Ascension Seeds" % required_seeds)
		return
	ascension_seeds -= required_seeds
	ascensions += 1
	stage = 1
	wave = 0
	player_xp = 0
	hero_hp = hero_hp_max
	essence += 40 + ascensions*10
	gems += 15
	_show_toast("ASCENSION %d!" % ascensions)
	_spawn_enemy()
	_recalc_stats()
	_save()

func _recalc_stats() -> void:
	var power_sum := 0.0
	var hp_bonus := 0.0
	var crit_bonus := 0.0
	var haste_bonus := 0.0
	var dodge_bonus := 0.0
	var leech_bonus := 0.0
	set_counts.clear()
	for item in equipped:
		if item.is_empty(): continue
		power_sum += float(item.get("power",0))*(1.0+float(item.get("level",0))*0.04)
		var set_name := str(item.get("set",""))
		if set_name != "":
			set_counts[set_name] = int(set_counts.get(set_name,0))+1
		for a in item.get("affixes",[]):
			var key := str(a.get("key",""))
			var value := float(a.get("value",0.0))
			match key:
				"power": power_sum += value*5.0
				"hp": hp_bonus += value
				"crit": crit_bonus += value/100.0
				"haste": haste_bonus += value/100.0
				"dodge": dodge_bonus += value/100.0
				"leech": leech_bonus += value/100.0
	var set_bonus := 0.0
	for set_name in set_counts.keys():
		var count := int(set_counts[set_name])
		if count >= 2: set_bonus += 0.06
		if count >= 4: set_bonus += 0.12
		if count >= 6: set_bonus += 0.20
	hero_power = (48.0 + player_level*3.0 + power_sum*0.19) * (1.0+set_bonus+float(ascensions)*0.12)
	hero_hp_max = (160.0 + player_level*11.0 + power_sum*0.12) * (1.0+hp_bonus/100.0+float(ascensions)*0.08)
	crit_chance = clampf(0.12+crit_bonus,0.05,0.65)
	haste = clampf(haste_bonus,0.0,1.1)
	dodge = clampf(0.03+dodge_bonus,0.0,0.35)
	leech = clampf(leech_bonus,0.0,0.22)
	armor = clampf(power_sum/200000.0,0.0,0.42)
	if active_pet == 1 and stage >= int(D.PETS[1]["unlock"]): haste += 0.04+pet_levels[1]*0.004
	if active_pet == 2 and stage >= int(D.PETS[2]["unlock"]): crit_chance += 0.025+pet_levels[2]*0.002
	if active_pet == 3 and stage >= int(D.PETS[3]["unlock"]): hero_power *= 1.06+pet_levels[3]*0.005
	if active_pet == 4 and stage >= int(D.PETS[4]["unlock"]): luck_level += 0 # visual/meta handled in rarity formula
	hero_hp = minf(hero_hp,hero_hp_max)
	if hero_hp <= 0.0: hero_hp = hero_hp_max

# -------------------------------------------------------------------
# QUESTS / REWARDS / SAVE
# -------------------------------------------------------------------

func _quest_data() -> Array[Dictionary]:
	return [
		{"name":"Defeat 25 enemies","now":mini(total_kills,25),"goal":25,"reward":"300G"},
		{"name":"Reach Stage 10","now":mini(stage,10),"goal":10,"reward":"8 Gems"},
		{"name":"Core Level 8","now":mini(core_level,8),"goal":8,"reward":"12 Shards"},
		{"name":"Defeat 3 bosses","now":mini(boss_kills,3),"goal":3,"reward":"15 Gems"},
		{"name":"Collect 8 rarities","now":mini(codex_seen.size(),8),"goal":8,"reward":"25 Energy"},
		{"name":"Reach Player Lv.10","now":mini(player_level,10),"goal":10,"reward":"800G"}
	]

func _claim_all_quests() -> void:
	var q := _quest_data()
	var claimed_any := false
	for i in q.size():
		if not quests_claimed[i] and int(q[i]["now"]) >= int(q[i]["goal"]):
			quests_claimed[i] = true
			claimed_any = true
			match i:
				0: gold += 300
				1: gems += 8
				2: shards += 12
				3: gems += 15
				4: essence += 25
				5: gold += 800
	_show_toast("Quest rewards claimed" if claimed_any else "No rewards ready")
	_save()

func _daily_claim() -> void:
	var today := int(Time.get_date_dict_from_system()["day"])
	if daily_claim_day == today:
		return
	daily_claim_day = today
	gold += 250 + player_level*25
	essence += 12
	gems += 2
	offline_message = "Daily Gift: +Gold +Energy +2 Gems"

func _apply_offline_rewards() -> void:
	var now := int(Time.get_unix_time_from_system())
	if last_save_unix <= 0:
		last_save_unix = now
		return
	var elapsed := clampi(now-last_save_unix,0,43200)
	if elapsed < 60:
		return
	var minutes := int(elapsed/60)
	var reward_gold := minutes*(4+stage)
	var reward_energy := int(minutes/8)
	gold += reward_gold
	essence += reward_energy
	offline_message = "Offline %dm: +%dG +%d Energy" % [minutes,reward_gold,reward_energy]

func _save() -> void:
	last_save_unix = int(Time.get_unix_time_from_system())
	var data := {
		"gold":gold,"essence":essence,"gems":gems,"shards":shards,"ascension_seeds":ascension_seeds,
		"stage":stage,"wave":wave,"total_kills":total_kills,"boss_kills":boss_kills,
		"player_level":player_level,"player_xp":player_xp,"ascensions":ascensions,
		"core_level":core_level,"luck_level":luck_level,"quality_level":quality_level,
		"speed_level":speed_level,"pity_level":pity_level,"pity":pity,
		"auto_roll":auto_roll,"auto_equip":auto_equip,"auto_sell_threshold":auto_sell_threshold,
		"equipped":equipped,"inventory":inventory,"loot_history":loot_history,"codex_seen":codex_seen,
		"active_pet":active_pet,"pet_levels":pet_levels,"skill_levels":skill_levels,
		"daily_claim_day":daily_claim_day,"quests_claimed":quests_claimed,
		"last_save_unix":last_save_unix
	}
	var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data))

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f: return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return
	gold=int(parsed.get("gold",gold)); essence=int(parsed.get("essence",essence)); gems=int(parsed.get("gems",gems))
	shards=int(parsed.get("shards",shards)); ascension_seeds=int(parsed.get("ascension_seeds",ascension_seeds))
	stage=int(parsed.get("stage",stage)); wave=int(parsed.get("wave",wave)); total_kills=int(parsed.get("total_kills",total_kills))
	boss_kills=int(parsed.get("boss_kills",boss_kills)); player_level=int(parsed.get("player_level",player_level))
	player_xp=int(parsed.get("player_xp",player_xp)); ascensions=int(parsed.get("ascensions",ascensions))
	core_level=int(parsed.get("core_level",core_level)); luck_level=int(parsed.get("luck_level",luck_level))
	quality_level=int(parsed.get("quality_level",quality_level)); speed_level=int(parsed.get("speed_level",speed_level))
	pity_level=int(parsed.get("pity_level",pity_level)); pity=int(parsed.get("pity",pity))
	auto_roll=bool(parsed.get("auto_roll",auto_roll)); auto_equip=bool(parsed.get("auto_equip",auto_equip))
	auto_sell_threshold=int(parsed.get("auto_sell_threshold",auto_sell_threshold))
	active_pet=int(parsed.get("active_pet",active_pet)); daily_claim_day=int(parsed.get("daily_claim_day",daily_claim_day))
	last_save_unix=int(parsed.get("last_save_unix",last_save_unix))
	var eq=parsed.get("equipped",equipped); if eq is Array and eq.size()==6: equipped=eq
	var inv=parsed.get("inventory",[]); if inv is Array: inventory=inv
	var hist=parsed.get("loot_history",[]); if hist is Array: loot_history=hist
	var cod=parsed.get("codex_seen",{}); if cod is Dictionary: codex_seen=cod
	var pl=parsed.get("pet_levels",pet_levels); if pl is Array and pl.size()==5: pet_levels=pl
	var sl=parsed.get("skill_levels",skill_levels); if sl is Array and sl.size()==3: skill_levels=sl
	var qc=parsed.get("quests_claimed",quests_claimed); if qc is Array and qc.size()==6: quests_claimed=qc

# -------------------------------------------------------------------
# FX
# -------------------------------------------------------------------

func _spawn_burst(pos: Vector2, color: Color, amount: int) -> void:
	for i in amount:
		var angle := rng.randf()*TAU
		var speed := rng.randf_range(70.0,230.0)
		particles.append({"pos":pos,"vel":Vector2(cos(angle),sin(angle))*speed,"life":rng.randf_range(0.35,0.9),"color":color,"size":rng.randf_range(2.5,7.5)})

func _seed_weather() -> void:
	weather_particles.clear()
	var kind := str(D.BIOMES[_biome_index()]["weather"])
	for i in 32:
		weather_particles.append({
			"pos":Vector2(rng.randf_range(0,W),rng.randf_range(170,800)),
			"speed":rng.randf_range(12,48),
			"phase":rng.randf()*TAU,
			"kind":kind
		})

func _update_fx(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		projectiles[i]["t"]=float(projectiles[i]["t"])+delta
		if float(projectiles[i]["t"])>=float(projectiles[i]["life"]): projectiles.remove_at(i)
	for i in range(damage_numbers.size()-1,-1,-1):
		damage_numbers[i]["life"]=float(damage_numbers[i]["life"])-delta
		damage_numbers[i]["pos"].y-=42.0*delta
		if float(damage_numbers[i]["life"])<=0.0: damage_numbers.remove_at(i)
	for i in range(particles.size()-1,-1,-1):
		particles[i]["life"]=float(particles[i]["life"])-delta
		particles[i]["pos"]+=Vector2(particles[i]["vel"])*delta
		particles[i]["vel"]*=0.97
		particles[i]["vel"].y+=130.0*delta
		if float(particles[i]["life"])<=0.0: particles.remove_at(i)
	for i in range(screen_rings.size()-1,-1,-1):
		screen_rings[i]["life"]=float(screen_rings[i]["life"])-delta
		screen_rings[i]["r"]=float(screen_rings[i]["r"])+260.0*delta
		if float(screen_rings[i]["life"])<=0.0: screen_rings.remove_at(i)
	for w in weather_particles:
		w["pos"].y += float(w["speed"])*delta
		w["pos"].x += sin(time_alive*1.2+float(w["phase"]))*10.0*delta
		if w["pos"].y>810:
			w["pos"].y=180
			w["pos"].x=rng.randf_range(0,W)

# -------------------------------------------------------------------
# RENDER
# -------------------------------------------------------------------

func _draw() -> void:
	var shake_offset := Vector2(sin(time_alive*71.0),cos(time_alive*63.0))*camera_shake
	draw_set_transform(shake_offset)
	_draw_world()
	_draw_top_hud()
	_draw_battlefield()
	_draw_skill_row()
	_draw_core_shrine()
	_draw_bottom_nav()
	_draw_fx()
	draw_set_transform(Vector2.ZERO)
	if panel_open: _draw_panel()
	if not current_item.is_empty(): _draw_loot_popup()
	if boss_intro>0.0: _draw_boss_intro()
	if offline_message!="":
		_panel(Rect2(92,235,536,58),Color(0.05,0.07,0.08,0.92),Color("#89e8ff"),20,2)
		_text(offline_message,Vector2(360,272),17,Color("#dfffff"),true)
		if time_alive>4.0: offline_message=""
	if toast!="":
		_panel(Rect2(150,1088,420,52),Color(0.05,0.06,0.06,0.93),Color(1,1,1,0.13),18,2)
		_text(toast,Vector2(360,1121),21,Color.WHITE,true)

func _draw_world() -> void:
	var biome: Dictionary = D.BIOMES[_biome_index()]
	var sky := Color(str(biome["sky"]))
	var far := Color(str(biome["far"]))
	var near := Color(str(biome["near"]))
	var ground := Color(str(biome["ground"]))
	for y in range(0,480,24):
		var t:=float(y)/480.0
		draw_rect(Rect2(0,y,W,26),sky.lerp(far,t*0.45))
	var sun_pos:=Vector2(585,220)
	draw_circle(sun_pos,72,Color(1,0.92,0.58,0.24))
	draw_circle(sun_pos,48,Color(1,0.94,0.68,0.65))

	# moving cloud layers
	for i in 6:
		var cx:=fmod(float(i*155)+time_alive*(8.0+i),900.0)-90.0
		var cy:=210.0+(i%3)*58.0
		_draw_cloud(Vector2(cx,cy),0.7+0.13*(i%2),Color(1,1,1,0.45))

	# far / near parallax silhouettes
	draw_colored_polygon(PackedVector2Array([Vector2(0,510),Vector2(80,380),Vector2(180,500),Vector2(290,335),Vector2(420,500),Vector2(555,350),Vector2(720,470),Vector2(720,650),Vector2(0,650)]),far)
	draw_colored_polygon(PackedVector2Array([Vector2(0,590),Vector2(100,470),Vector2(205,575),Vector2(350,435),Vector2(500,575),Vector2(640,455),Vector2(720,530),Vector2(720,700),Vector2(0,700)]),near.darkened(0.04))

	# path + grass
	draw_rect(Rect2(0,555,W,270),near)
	draw_colored_polygon(PackedVector2Array([Vector2(0,690),Vector2(720,620),Vector2(720,825),Vector2(0,825)]),ground)
	draw_colored_polygon(PackedVector2Array([Vector2(0,732),Vector2(720,660),Vector2(720,825),Vector2(0,825)]),ground.lightened(0.08))

	# environmental props
	for x in [42,115,650,705]:
		_draw_tree(Vector2(x,565+sin(float(x))*9.0),0.76 if x<200 else 0.92,near.darkened(0.22))
	for x in [82,152,585,630,692]:
		_draw_plant(Vector2(x,650+sin(float(x))*8.0),Color(str(biome["accent"])),0.8)
	for x in [25,185,545,670]:
		_draw_rock(Vector2(x,704+sin(float(x))*5.0),0.8)

	_draw_weather()

func _draw_weather() -> void:
	var accent:=Color(str(D.BIOMES[_biome_index()]["accent"]))
	for w in weather_particles:
		var pos:=Vector2(w["pos"])
		match str(w["kind"]):
			"snow": draw_circle(pos,3.0,Color(1,1,1,0.72))
			"embers": draw_circle(pos,3.0,Color("#ff9b67"))
			"fireflies": draw_circle(pos,3.5,Color("#e8ff87"))
			"crystals": _diamond(pos,5.0,accent)
			"bubbles": draw_arc(pos,5.0,0,TAU,12,Color(0.8,1,1,0.55),1.3)
			"stars": _star(pos,5.5,accent)
			_: _leaf(pos,accent)

func _draw_top_hud() -> void:
	_panel(Rect2(14,14,692,174),Color(0.035,0.055,0.055,0.88),Color(0.8,1,0.9,0.13),28,2)
	_draw_avatar(Vector2(65,67))
	_text("SPROUTBOUND",Vector2(112,52),24,Color("#fff0bc"))
	_text("Lv.%d  •  Power %s" % [player_level,_short_num(int(hero_power))],Vector2(112,80),17,Color("#d9ffe2"))
	_bar(Rect2(112,92,254,14),float(player_xp)/float(_xp_needed()),Color("#6cf09b"),Color("#132a24"))
	_bar(Rect2(112,114,254,17),hero_hp/hero_hp_max,Color("#64e57b"),Color("#2b2020"))
	if shield>0.0:
		_bar(Rect2(112,136,254,9),minf(1.0,shield/maxf(1.0,hero_hp_max*0.3)),Color("#ffe58b"),Color("#2a2820"))
	_currency(Vector2(416,49),"G",gold,Color("#ffd85a"))
	_currency(Vector2(416,90),"E",essence,Color("#8cecff"))
	_currency(Vector2(561,49),"♦",gems,Color("#ff8fe6"))
	_currency(Vector2(561,90),"S",shards,Color("#c39cff"))
	_panel(Rect2(394,124,292,44),Color(0.03,0.04,0.04,0.65),Color(1,1,1,0.08),15,1)
	_text("%s  •  Stage %d-%d" % [D.BIOMES[_biome_index()]["name"],stage,wave+1],Vector2(540,152),16,Color.WHITE,true)
	_panel(Rect2(605,178,88,48),Color("#704d32"),Color("#f7d47e"),16,2)
	_text("GIFT",Vector2(649,209),15,Color.WHITE,true)

func _draw_battlefield() -> void:
	var hero_pos:=Vector2(220,550+sin(time_alive*4.8)*5.0)
	var enemy_pos:=Vector2(510,535+sin(time_alive*4.1+1.1)*4.0)
	_draw_pet(Vector2(120,590+sin(time_alive*5.2)*4.0))
	_draw_hero(hero_pos)
	_draw_enemy(enemy_pos)
	_bar(Rect2(412,398,222,21),enemy_hp/enemy_hp_max,Color("#ff6670"),Color("#35191c"))
	var enemy_name:=str(enemy.get("name","Enemy"))
	if enemy_elite: enemy_name="ELITE "+enemy_name
	if enemy_boss: enemy_name="BOSS · "+enemy_name
	_text(enemy_name,Vector2(523,386),19,Color("#3b2825"),true)
	if combo>=2:
		_text("COMBO x%d" % combo,Vector2(360,350),25,Color("#fff08c"),true)
	_bar(Rect2(520,665,120,13),rage/100.0,Color("#ffcc59"),Color("#3b2b18"))
	_text("RAGE",Vector2(580,657),12,Color("#6e4e19"),true)

func _draw_hero(pos: Vector2) -> void:
	var hurt:=Color.WHITE.lerp(Color("#ff8f88"),hit_flash*0.45)
	draw_ellipse_custom(pos+Vector2(0,78),58,17,Color(0,0,0,0.15))
	# aura / set glow
	if set_counts.size()>0:
		draw_arc(pos+Vector2(0,25),82+sin(time_alive*3.0)*3.0,0,TAU,40,Color(0.55,1,0.65,0.18),5.0)
	# cape/body
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-42,25),pos+Vector2(-58,98),pos+Vector2(58,98),pos+Vector2(42,25)]),Color("#347c58")*hurt)
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-34,36),pos+Vector2(0,70),pos+Vector2(34,36),pos+Vector2(26,102),pos+Vector2(-26,102)]),Color("#4f9a66")*hurt)
	# face
	draw_circle(pos,53,Color("#f2ddb0")*hurt)
	draw_circle(pos+Vector2(-20,-5),7,Color("#2e2c2a"))
	draw_circle(pos+Vector2(20,-5),7,Color("#2e2c2a"))
	draw_circle(pos+Vector2(-17,-8),2.5,Color.WHITE)
	draw_circle(pos+Vector2(23,-8),2.5,Color.WHITE)
	draw_arc(pos+Vector2(0,8),18,0.25,2.9,18,Color("#8c604b"),3.5)
	# leaf crown
	draw_circle(pos+Vector2(0,-46),51,Color("#63b95a"))
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-48,-48),pos+Vector2(-24,-83),pos+Vector2(-5,-58),pos+Vector2(19,-92),pos+Vector2(34,-58),pos+Vector2(51,-48)]),Color("#4b9b4a"))
	_leaf(pos+Vector2(7,-92),Color("#d6ef6b"))
	# boots/hands
	draw_circle(pos+Vector2(-38,86),16,Color("#eac99a"))
	draw_circle(pos+Vector2(38,86),16,Color("#eac99a"))
	# weapon with rarity glow
	var wc:=Color("#e9f7ff")
	if not equipped[0].is_empty(): wc=_rarity_color(int(equipped[0].get("rarity",0)))
	var swing:=sin(time_alive*10.0)*0.13
	var hand:=pos+Vector2(48,52)
	var tip:=hand+Vector2(68*cos(-0.8+swing),68*sin(-0.8+swing))
	draw_line(hand,tip,Color("#755338"),11.0)
	draw_line(hand+Vector2(15,-15),tip+Vector2(8,-8),wc,12.0)
	draw_circle(tip+Vector2(8,-8),9,wc.lightened(0.25))

func _draw_pet(pos: Vector2) -> void:
	if stage < int(D.PETS[active_pet]["unlock"]): return
	var pet: Dictionary=D.PETS[active_pet]
	var c:=Color(str(pet["color"]))
	draw_ellipse_custom(pos+Vector2(0,35),29,8,Color(0,0,0,0.12))
	draw_circle(pos,28,c)
	draw_circle(pos+Vector2(-9,-2),4,Color("#2d2b2d"))
	draw_circle(pos+Vector2(9,-2),4,Color("#2d2b2d"))
	draw_circle(pos+Vector2(0,-26),13,c.lightened(0.1))
	draw_arc(pos,36+sin(time_alive*4.0)*2.0,0,TAU,24,Color(c.r,c.g,c.b,0.18),4.0)
	_text("Lv.%d" % pet_levels[active_pet],pos+Vector2(0,54),12,Color.WHITE,true)

func _draw_enemy(pos: Vector2) -> void:
	var base:=Color(str(enemy.get("color","#d36f7d")))
	var c:=base.lerp(Color.WHITE,enemy_hit_flash*0.62)
	if enemy_elite:
		draw_arc(pos,83+sin(time_alive*5.0)*4.0,0,TAU,32,Color(1,0.82,0.3,0.35),6.0)
	if enemy_boss:
		draw_arc(pos,101+sin(time_alive*3.0)*5.0,0,TAU,36,Color(1,0.45,0.26,0.35),8.0)
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-34,-72),pos+Vector2(-18,-108),pos+Vector2(0,-82),pos+Vector2(20,-110),pos+Vector2(36,-72)]),Color("#ffd45e"))
	draw_ellipse_custom(pos+Vector2(0,70),72,18,Color(0,0,0,0.16))
	match str(enemy.get("shape","puff")):
		"boar":
			draw_ellipse_custom(pos,72,58,c)
			draw_circle(pos+Vector2(57,4),34,c.darkened(0.05))
			draw_circle(pos+Vector2(68,10),17,Color("#e7ac9a"))
			draw_circle(pos+Vector2(49,-8),6,Color("#29252a"))
			draw_colored_polygon(PackedVector2Array([pos+Vector2(-50,-35),pos+Vector2(-32,-70),pos+Vector2(-18,-37)]),c.darkened(0.12))
		"wisp":
			draw_circle(pos,55,c)
			draw_colored_polygon(PackedVector2Array([pos+Vector2(-40,30),pos+Vector2(0,88),pos+Vector2(40,30)]),c)
			draw_circle(pos+Vector2(-18,-5),7,Color("#2e2a31")); draw_circle(pos+Vector2(18,-5),7,Color("#2e2a31"))
		"golem":
			draw_rect(Rect2(pos+Vector2(-55,-48),Vector2(110,105)),c)
			draw_circle(pos+Vector2(-25,-5),7,Color("#ffe88a")); draw_circle(pos+Vector2(25,-5),7,Color("#ffe88a"))
			draw_rect(Rect2(pos+Vector2(-75,5),Vector2(25,60)),c.darkened(0.12)); draw_rect(Rect2(pos+Vector2(50,5),Vector2(25,60)),c.darkened(0.12))
		"boss":
			draw_circle(pos,76,c)
			draw_circle(pos+Vector2(-50,-42),30,c.darkened(0.1)); draw_circle(pos+Vector2(50,-42),30,c.darkened(0.1))
			draw_circle(pos+Vector2(-24,-8),9,Color("#301d28")); draw_circle(pos+Vector2(24,-8),9,Color("#301d28"))
			draw_arc(pos+Vector2(0,18),25,3.35,6.05,18,Color("#5b2935"),5.0)
		_:
			draw_circle(pos,64,c)
			draw_circle(pos+Vector2(-45,-43),27,c.darkened(0.08)); draw_circle(pos+Vector2(45,-43),27,c.darkened(0.08))
			draw_circle(pos+Vector2(-21,-8),8,Color("#2d2530")); draw_circle(pos+Vector2(21,-8),8,Color("#2d2530"))
			draw_arc(pos+Vector2(0,10),22,0.25,2.9,18,Color("#6a3740"),4.0)

func _draw_skill_row() -> void:
	_panel(Rect2(190,684,468,108),Color(0.05,0.07,0.07,0.78),Color(1,1,1,0.08),24,2)
	for i in 3:
		var pos:=Vector2(253+i*102,736)
		var skill: Dictionary=D.SKILLS[i]
		var unlocked:=stage>=int(skill["unlock"])
		var col:=Color(str(skill["color"])) if unlocked else Color("#555b5b")
		draw_circle(pos,36,Color(0.07,0.08,0.09,0.92))
		draw_circle(pos,30,col.darkened(0.18))
		if i==0: _leaf(pos,col.lightened(0.2))
		elif i==1: _star(pos,18,col.lightened(0.2))
		else:
			draw_arc(pos,19,0,TAU,24,col.lightened(0.2),6.0)
		var cd:=float(skill_timers[i])
		if cd>0.0:
			_text("%.1f" % cd,pos+Vector2(0,7),16,Color.WHITE,true)
		if not unlocked:
			_text("S%d" % int(skill["unlock"]),pos+Vector2(0,53),12,Color("#c8c8c8"),true)
		else:
			_text("Lv.%d" % skill_levels[i],pos+Vector2(0,53),12,Color.WHITE,true)
	var upos:=Vector2(585,736)
	draw_circle(upos,42,Color("#503a1f"))
	draw_arc(upos,36,-PI/2,-PI/2+TAU*(rage/100.0),32,Color("#ffd45a"),7.0)
	_star(upos,18,Color("#fff09a"))
	if rage<100.0: _text("%d" % int(rage),upos+Vector2(0,6),14,Color.WHITE,true)

func _draw_core_shrine() -> void:
	_panel(Rect2(16,808,688,342),Color("#211d21"),Color("#6f5a78"),28,2)
	# stone shrine
	draw_colored_polygon(PackedVector2Array([Vector2(246,1020),Vector2(275,860),Vector2(445,860),Vector2(474,1020)]),Color("#51485a"))
	draw_rect(Rect2(267,1005,186,45),Color("#403948"))
	for x in [266,454]:
		draw_rect(Rect2(x,868,18,146),Color("#6e6478"))
	# rings / core
	var p:=Vector2(360,918)
	var pulse:=1.0+sin(time_alive*4.0)*0.035+core_pulse*0.08
	draw_circle(p,99*pulse,Color(0.34,0.74,1.0,0.08+loot_flash*0.16))
	draw_arc(p,78*pulse,time_alive*0.7,time_alive*0.7+TAU*0.76,44,Color("#8de8ff"),6.0)
	draw_arc(p,64*pulse,-time_alive*1.0,-time_alive*1.0+TAU*0.64,40,Color("#d394ff"),5.0)
	draw_circle(p,49*pulse,Color("#5c4a80"))
	draw_circle(p,35*pulse,Color("#72e8ff").lerp(Color.WHITE,loot_flash*0.6))
	_diamond(p,19,Color.WHITE)
	_text("Lv.%d" % core_level,p+Vector2(0,7),18,Color("#23333a"),true)

	_panel(Rect2(38,932,162,62),Color("#6f5030"),Color("#f0cb79"),18,2)
	_text("UPGRADE",Vector2(119,958),16,Color.WHITE,true)
	_text("%s G" % _short_num(_core_cost()),Vector2(119,982),13,Color("#ffe7a6"),true)
	_panel(Rect2(520,932,162,62),Color("#245a4d") if auto_roll else Color("#3b3739"),Color("#7df0c7") if auto_roll else Color("#7d7578"),18,2)
	_text("AUTO %s" % ("ON" if auto_roll else "OFF"),Vector2(601,968),17,Color.WHITE,true)
	_text("Luck %d  Quality %d  Speed %d  Pity %d/%d" % [luck_level,quality_level,speed_level,pity,maxi(12,30-pity_level)],Vector2(360,1080),16,Color("#d8cadf"),true)
	var max_r:=mini(49,6+int(core_level/2)+ascensions*2)
	_text("Unlocked: %s" % D.RARITIES[max_r],Vector2(360,1110),16,_rarity_color(max_r),true)

func _draw_bottom_nav() -> void:
	draw_rect(Rect2(0,1158,W,122),Color("#171719"))
	var labels:=["GEAR","SKILLS","CORE","PETS","QUESTS"]
	for i in 5:
		var x:=72.0+i*144.0
		var selected:=panel_open and active_tab==i
		if selected:
			draw_circle(Vector2(x,1188),34,Color("#53435c"))
		draw_circle(Vector2(x,1188),21,_nav_color(i))
		_draw_nav_icon(Vector2(x,1188),i,Color("#1d2023"))
		_text(labels[i],Vector2(x,1244),15,Color.WHITE,true)
		if _has_notification(i):
			draw_circle(Vector2(x+25,1169),8,Color("#ff625e"))

func _draw_panel() -> void:
	draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.28))
	_panel(Rect2(30,690,660,445),Color(0.055,0.055,0.065,0.98),Color("#796a86"),28,2)
	var titles:=["GEAR & INVENTORY","SKILLS","RELIC CORE","COMPANIONS","QUESTS"]
	_text(titles[active_tab],Vector2(360,736),27,Color("#fff0c7"),true)
	_panel(Rect2(632,704,42,42),Color("#4a3b42"),Color("#8f7a84"),14,1)
	_text("×",Vector2(653,733),24,Color.WHITE,true)
	match active_tab:
		0: _draw_gear_panel()
		1: _draw_skills_panel()
		2: _draw_core_panel()
		3: _draw_pets_panel()
		4: _draw_quests_panel()

func _draw_gear_panel() -> void:
	for i in 6:
		var col:=i%2
		var row:=int(i/2)
		var rect:=Rect2(55+col*315,775+row*76,290,62)
		_panel(rect,Color("#242329"),Color(1,1,1,0.08),15,1)
		var item: Dictionary=equipped[i]
		_text(D.SLOTS[i],Vector2(rect.position.x+14,rect.position.y+24),14,Color("#a9a1ad"))
		if item.is_empty():
			_text("Empty",Vector2(rect.position.x+14,rect.position.y+48),17,Color("#6f6973"))
		else:
			_text(str(item.get("name","")),Vector2(rect.position.x+14,rect.position.y+48),14,_rarity_color(int(item.get("rarity",0))))
	_text("Inventory %d/%d  •  Auto-sell < %s" % [inventory.size(),MAX_INV,D.RARITIES[auto_sell_threshold]],Vector2(360,1018),15,Color("#bcb4c2"),true)
	_small_button(Rect2(60,1038,180,58),"AUTO EQUIP",Color("#386b50"))
	_small_button(Rect2(270,1038,180,58),"SALVAGE",Color("#76503d"))
	_small_button(Rect2(480,1038,180,58),"FILTER",Color("#4c4a72"))

func _draw_skills_panel() -> void:
	for i in 3:
		var y:=786+i*88
		var skill: Dictionary=D.SKILLS[i]
		var unlocked:=stage>=int(skill["unlock"])
		_panel(Rect2(72,y,576,68),Color("#242329"),Color(str(skill["color"])) if unlocked else Color("#55555c"),16,2)
		_text(str(skill["name"]),Vector2(94,y+28),20,Color.WHITE if unlocked else Color("#888891"))
		_text("Lv.%d  CD %.1fs" % [skill_levels[i],float(skill["cd"])],Vector2(94,y+53),14,Color("#bbb5c0"))
		var cost: int =180*(skill_levels[i]+1)
		_text("%sG" % _short_num(cost),Vector2(610,y+42),15,Color("#ffe08d"),true)
	_text("Skills cast automatically. Tap them in battle for timing.",Vector2(360,1080),15,Color("#9e96a4"),true)

func _draw_core_panel() -> void:
	var names:=["LUCK","QUALITY","SPEED","PITY"]
	var levels:=[luck_level,quality_level,speed_level,pity_level]
	for i in 4:
		var col:=i%2; var row:=int(i/2)
		var rect:=Rect2(65+col*320,812+row*90,270,70)
		_panel(rect,Color("#25232c"),Color("#775d8a"),16,2)
		_text(names[i],Vector2(rect.position.x+18,rect.position.y+28),16,Color("#d8c9e4"))
		_text("Lv.%d" % levels[i],Vector2(rect.position.x+18,rect.position.y+53),18,Color.WHITE)
		_text("%d S" % (6+levels[i]*3),Vector2(rect.end.x-34,rect.position.y+43),14,Color("#c7a9ff"),true)
	var req_stage:=50+ascensions*25
	var req_seed:=5+ascensions*2
	_small_button(Rect2(185,1002,350,72),"ASCEND  S%d / %d  •  Stage %d" % [ascension_seeds,req_seed,req_stage],Color("#70507d"))
	_text("Ascension %d permanently boosts stats and rarity access." % ascensions,Vector2(360,1098),14,Color("#aaa0b0"),true)

func _draw_pets_panel() -> void:
	for i in 5:
		var y:=780+i*58
		var pet: Dictionary=D.PETS[i]
		var unlocked:=stage>=int(pet["unlock"])
		var selected:=i==active_pet
		_panel(Rect2(65,y,390,48),Color("#2d2a31") if not selected else Color("#3b394c"),Color(str(pet["color"])) if unlocked else Color("#55545b"),14,2)
		draw_circle(Vector2(92,y+24),14,Color(str(pet["color"])) if unlocked else Color("#55545b"))
		_text("%s  Lv.%d" % [pet["name"],pet_levels[i]],Vector2(118,y+30),17,Color.WHITE if unlocked else Color("#77747c"))
		_text(str(pet["bonus"]),Vector2(395,y+30),14,Color("#c6becb"),true)
		if not unlocked: _text("S%d" % int(pet["unlock"]),Vector2(430,y+30),13,Color("#938b99"),true)
	_draw_pet(Vector2(555,840))
	_text(str(D.PETS[active_pet]["name"]),Vector2(555,895),20,Color.WHITE,true)
	_small_button(Rect2(475,904,175,62),"UPGRADE",Color("#4e6c65"))
	_text("Cost %d shards" % (4+pet_levels[active_pet]*2),Vector2(562,990),14,Color("#c8c0ce"),true)

func _draw_quests_panel() -> void:
	var q:=_quest_data()
	for i in q.size():
		var col:=i%2; var row:=int(i/2)
		var rect:=Rect2(52+col*319,778+row*78,300,68)
		var complete:=int(q[i]["now"])>=int(q[i]["goal"])
		_panel(rect,Color("#252329"),Color("#6bd68a") if complete and not quests_claimed[i] else Color(1,1,1,0.08),14,2)
		_text(str(q[i]["name"]),Vector2(rect.position.x+12,rect.position.y+24),14,Color.WHITE)
		_text("%d/%d  •  %s" % [q[i]["now"],q[i]["goal"],q[i]["reward"]],Vector2(rect.position.x+12,rect.position.y+51),13,Color("#bbb3c0"))
		if quests_claimed[i]: _text("✓",Vector2(rect.end.x-24,rect.position.y+42),22,Color("#73e68f"),true)
	_small_button(Rect2(180,1035,360,62),"CLAIM ALL",Color("#4f795b"))
	_text("Bosses %d  •  Kills %d  •  Codex %d/50" % [boss_kills,total_kills,codex_seen.size()],Vector2(360,1120),14,Color("#a79fac"),true)

func _draw_loot_popup() -> void:
	draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.58))
	var r:=int(current_item.get("rarity",0))
	var col:=_rarity_color(r)
	_panel(Rect2(42,350,636,660),Color("#19181d"),col,30,4)
	_text("RELIC CORE DROP",Vector2(360,397),17,Color("#b9b2bf"),true)
	for rad in [122.0,96.0,72.0]:
		draw_arc(Vector2(360,532),rad,time_alive*(0.5+rad/300.0),time_alive*(0.5+rad/300.0)+TAU*0.7,44,Color(col.r,col.g,col.b,0.15+0.1*(rad/122.0)),4)
	draw_circle(Vector2(360,532),62,Color("#302d37"))
	_draw_item_icon(Vector2(360,532),int(current_item.get("slot",0)),col)
	_text(str(current_item.get("name","")),Vector2(360,650),26,col,true)
	var set_name:=str(current_item.get("set",""))
	if set_name!="": _text("%s Set" % set_name,Vector2(360,680),17,Color("#e5d5ff"),true)
	_text("%s  •  Power %s" % [D.SLOTS[int(current_item.get("slot",0))],_short_num(int(current_item.get("power",0)))],Vector2(360,717),20,Color.WHITE,true)
	var y:=758
	for aff in current_item.get("affixes",[]):
		_text("+%.1f %s" % [float(aff.get("value",0)),str(aff.get("name",""))],Vector2(360,y),16,Color("#c8f7d4"),true)
		y+=25
	var slot:=int(current_item.get("slot",0))
	var old_score:=0.0 if equipped[slot].is_empty() else _item_score(equipped[slot])
	var delta:=_item_score(current_item)-old_score
	_text("%+.0f score vs equipped" % delta,Vector2(360,884),18,Color("#79ee91") if delta>=0 else Color("#ff8e95"),true)
	_small_button(Rect2(55,914,185,72),"EQUIP",Color("#3d8455"))
	_small_button(Rect2(268,914,185,72),"KEEP",Color("#4a5679"))
	_small_button(Rect2(481,914,185,72),"SELL",Color("#7a493e"))

func _draw_boss_intro() -> void:
	var alpha:=clampf(boss_intro,0.0,1.0)
	draw_rect(Rect2(0,300,W,180),Color(0.12,0.02,0.03,0.75*alpha))
	_text("BOSS STAGE",Vector2(360,365),36,Color(1,0.86,0.57,alpha),true)
	_text(str(enemy.get("name","Boss")),Vector2(360,416),24,Color(1,1,1,alpha),true)

func _draw_fx() -> void:
	for pr in projectiles:
		var t:=clampf(float(pr["t"])/float(pr["life"]),0.0,1.0)
		var from:=Vector2(pr["from"]); var to:=Vector2(pr["to"])
		var pos:=from.lerp(to,t)
		var arc:=sin(t*PI)*-46.0
		pos.y+=arc
		var col:=Color(pr["color"])
		draw_line(from.lerp(to,maxf(0.0,t-0.12)),pos,Color(col.r,col.g,col.b,0.32),float(pr["size"])*1.6)
		draw_circle(pos,float(pr["size"]),col)
	for d in damage_numbers:
		_text(str(d["text"]),Vector2(d["pos"]),int(d["size"]),Color(d["color"]),true)
	for pt in particles:
		var c:=Color(pt["color"]); c.a=clampf(float(pt["life"])*1.8,0.0,1.0)
		draw_circle(Vector2(pt["pos"]),float(pt["size"]),c)
	for ring in screen_rings:
		var c:=Color(ring["color"]); c.a=clampf(float(ring["life"]),0.0,1.0)
		draw_arc(Vector2(ring["pos"]),float(ring["r"]),0,TAU,48,c,7.0)

# -------------------------------------------------------------------
# DRAW HELPERS
# -------------------------------------------------------------------

func _biome_index() -> int:
	return int((stage-1)/5)%D.BIOMES.size()

func _has_notification(tab: int) -> bool:
	if tab==0: return inventory.size()>=MAX_INV-3
	if tab==1:
		for i in 3:
			if stage>=int(D.SKILLS[i]["unlock"]) and gold>=180*(skill_levels[i]+1): return true
	if tab==3:
		for i in 5:
			if stage==int(D.PETS[i]["unlock"]): return true
	if tab==4:
		var q:=_quest_data()
		for i in q.size():
			if not quests_claimed[i] and int(q[i]["now"])>=int(q[i]["goal"]): return true
	return false

func _rarity_color(index: int) -> Color:
	if index<=0: return Color("#c8c8cc")
	var hue:=fmod(0.56+float(index)*0.071,1.0)
	return Color.from_hsv(hue,clampf(0.54+index*0.006,0.54,0.9),clampf(0.84+index*0.003,0.84,1.0))

func _nav_color(i: int) -> Color:
	return [Color("#d8b56b"),Color("#ff9671"),Color("#75dff1"),Color("#8cdd82"),Color("#d798ef")][i]

func _panel(rect: Rect2,fill: Color,border: Color,radius: float,border_width:=2.0) -> void:
	var box:=StyleBoxFlat.new()
	box.bg_color=fill; box.border_color=border; box.set_border_width_all(int(border_width))
	box.corner_radius_top_left=int(radius); box.corner_radius_top_right=int(radius)
	box.corner_radius_bottom_left=int(radius); box.corner_radius_bottom_right=int(radius)
	draw_style_box(box,rect)

func _small_button(rect: Rect2,label: String,color: Color) -> void:
	_panel(rect,color,color.lightened(0.25),17,2)
	_text(label,rect.get_center()+Vector2(0,7),17,Color.WHITE,true)

func _text(text: String,pos: Vector2,size: int,color:=Color.WHITE,centered:=false) -> void:
	if font==null: return
	var p:=pos
	if centered:
		p.x-=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _bar(rect: Rect2,ratio: float,color: Color,bg: Color) -> void:
	_panel(rect,bg,Color(1,1,1,0.06),rect.size.y*0.5,1)
	var inner:=rect.grow(-2)
	inner.size.x*=clampf(ratio,0.0,1.0)
	draw_rect(inner,color)

func _currency(pos: Vector2,mark: String,value: int,color: Color) -> void:
	draw_circle(pos,15,color)
	_text(mark,pos+Vector2(0,5),12,Color("#2b2725"),true)
	_text(_short_num(value),pos+Vector2(24,6),16,Color.WHITE)

func draw_ellipse_custom(center: Vector2,rx: float,ry: float,color: Color) -> void:
	var pts:=PackedVector2Array()
	for i in 32:
		var a:=TAU*float(i)/32.0
		pts.append(center+Vector2(cos(a)*rx,sin(a)*ry))
	draw_colored_polygon(pts,color)

func _draw_cloud(pos: Vector2,scale: float,color: Color) -> void:
	draw_circle(pos,24*scale,color); draw_circle(pos+Vector2(25,-8)*scale,31*scale,color)
	draw_circle(pos+Vector2(56,2)*scale,22*scale,color)
	draw_rect(Rect2(pos+Vector2(-8,0)*scale,Vector2(78,22)*scale),color)

func _draw_tree(pos: Vector2,scale: float,color: Color) -> void:
	draw_rect(Rect2(pos+Vector2(-8,-20)*scale,Vector2(16,84)*scale),Color("#684c39"))
	draw_circle(pos+Vector2(-22,-35)*scale,34*scale,color)
	draw_circle(pos+Vector2(18,-48)*scale,39*scale,color.lightened(0.06))
	draw_circle(pos+Vector2(35,-18)*scale,30*scale,color)

func _draw_plant(pos: Vector2,color: Color,scale: float) -> void:
	draw_line(pos,pos+Vector2(0,-29)*scale,Color("#357c45"),4)
	_leaf(pos+Vector2(-8,-22)*scale,color)
	_leaf(pos+Vector2(9,-30)*scale,color.lightened(0.08))

func _draw_rock(pos: Vector2,scale: float) -> void:
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-22,0)*scale,pos+Vector2(-13,-24)*scale,pos+Vector2(13,-28)*scale,pos+Vector2(27,0)*scale]),Color("#7e7d7a"))

func _leaf(pos: Vector2,color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-12),pos+Vector2(10,-1),pos+Vector2(0,13),pos+Vector2(-9,-1)]),color)
	draw_line(pos+Vector2(0,-9),pos+Vector2(0,9),color.darkened(0.2),2)

func _diamond(pos: Vector2,size: float,color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-size),pos+Vector2(size*0.72,0),pos+Vector2(0,size),pos+Vector2(-size*0.72,0)]),color)

func _star(pos: Vector2,size: float,color: Color) -> void:
	var pts:=PackedVector2Array()
	for i in 10:
		var a:=-PI/2+TAU*float(i)/10.0
		var r:=size if i%2==0 else size*0.44
		pts.append(pos+Vector2(cos(a),sin(a))*r)
	draw_colored_polygon(pts,color)

func _draw_avatar(pos: Vector2) -> void:
	draw_circle(pos,38,Color("#4f9b58"))
	draw_circle(pos+Vector2(0,8),25,Color("#efd6aa"))
	draw_circle(pos+Vector2(-9,4),4,Color("#28282a")); draw_circle(pos+Vector2(9,4),4,Color("#28282a"))
	_leaf(pos+Vector2(4,-30),Color("#d4ee6d"))

func _draw_item_icon(pos: Vector2,slot: int,color: Color) -> void:
	match slot:
		0:
			draw_line(pos+Vector2(-28,34),pos+Vector2(30,-35),color,16)
			draw_line(pos+Vector2(-31,17),pos+Vector2(-7,39),Color("#bd9258"),9)
		1:
			draw_colored_polygon(PackedVector2Array([pos+Vector2(-38,-36),pos+Vector2(38,-36),pos+Vector2(27,40),pos+Vector2(-27,40)]),color)
		2:
			draw_arc(pos,34,0,TAU,30,color,13)
			draw_colored_polygon(PackedVector2Array([pos+Vector2(-24,-17),pos+Vector2(0,-44),pos+Vector2(24,-17)]),color)
		3:
			draw_colored_polygon(PackedVector2Array([pos+Vector2(-35,-22),pos+Vector2(25,-22),pos+Vector2(38,25),pos+Vector2(-15,38)]),color)
		4:
			draw_circle(pos,36,color); draw_circle(pos,21,Color("#302d37"))
		_:
			_diamond(pos,42,color)

func _draw_nav_icon(pos: Vector2,index: int,color: Color) -> void:
	match index:
		0: _draw_item_icon(pos,1,color)
		1: _star(pos,13,color)
		2: _diamond(pos,15,color)
		3: draw_circle(pos,12,color)
		4:
			draw_rect(Rect2(pos+Vector2(-12,-14),Vector2(24,29)),color)
			draw_line(pos+Vector2(-7,-5),pos+Vector2(7,-5),Color.WHITE,2)

func _short_num(v: int) -> String:
	if v>=1000000000000: return "%.1fT" % (float(v)/1000000000000.0)
	if v>=1000000000: return "%.1fB" % (float(v)/1000000000.0)
	if v>=1000000: return "%.1fM" % (float(v)/1000000.0)
	if v>=1000: return "%.1fK" % (float(v)/1000.0)
	return str(v)

func _show_toast(t: String) -> void:
	toast=t
	toast_timer=1.8
