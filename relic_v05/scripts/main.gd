extends Node2D

const D = preload("res://scripts/game_data.gd")
const W := 720.0
const H := 1280.0
const SAVE_PATH := "user://relic_v05_save.json"
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

# Mythic v0.5 systems
var feature_panel := ""
var evolution_tier := 0
var forge_level := 1
var forge_stones := 12
var forge_slot := 0
var dungeon_keys := 3
var dungeon_index := 0
var battle_mode := "normal"
var dungeon_room := 0
var dungeon_time := 0.0
var boss_rush_score := 0
var boss_rush_best := 0
var boss_rush_time := 0.0
var garden_level := 1
var garden_xp := 0
var garden_plots := [0,0,0]
var garden_crop_types := [0,1,2]
var rarity_cutscene := 0.0
var rarity_cutscene_name := ""
var rarity_cutscene_color := Color.WHITE
var screen_flash := 0.0
var achievement_claimed := [false,false,false,false,false,false]

# Colossus v0.6 systems
var tower_floor := 1
var tower_best := 0
var trial_index := 0
var trial_score := 0
var trial_time := 0.0
var talent_points := 3
var talent_levels := [0,0,0,0,0,0,0,0,0,0,0,0]
var artifact_levels := [0,0,0,0,0,0,0,0]
var active_artifact := 0
var selected_skin := 0
var owned_skins := [true,false,false,false,false,false,false,false]
var selected_title := 0
var world_event_index := -1
var world_event_time := 0.0
var world_event_cooldown := 24.0
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var music_track := -1
var biome_overlays: Array[Texture2D] = []
var premium_atlases: Array[Texture2D] = []
var magic_noise_maps: Array[Texture2D] = []
var visual_overkill_fields: Array[Texture2D] = []
var impact_atlases: Array[Texture2D] = []
var loot_beams: Array[Texture2D] = []
var spark_field: Texture2D
var cinematic_timer := 0.0
var cinematic_kind := ""
var impact_timer := 0.0
var loot_beam_timer := 0.0
var boss_phase := 0
var chroma_pulse := 0.0

# v0.8 streamed ultra visuals
var ultra_biome_texture: Texture2D
var ultra_boss_texture: Texture2D
var ultra_cinematic_texture: Texture2D
var ultra_hero_texture: Texture2D
var ultra_enemy_texture: Texture2D
var ultra_biome_loaded := -1
var ultra_boss_loaded := -1
var ultra_cinematic_loaded := -1
var ultra_hero_loaded := -1
var ultra_enemy_loaded := -1
var ultra_ui_cache: Dictionary = {}

# v0.9 gear/core quality rework
var gear_selected_index := -1
var gear_selected_slot := 0
var gear_page := 0
var gear_compare_mode := true
var core_resonance := 0.0
var core_overcharge_flash := 0.0
var core_draw_streak := 0
var vfx_particles_v2: Array[Dictionary] = []
var vfx_slashes: Array[Dictionary] = []
var vfx_bursts: Array[Dictionary] = []

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
	_setup_colossus_assets()
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
	rarity_cutscene = maxf(0.0, rarity_cutscene - delta)
	screen_flash = maxf(0.0, screen_flash - delta * 2.6)
	cinematic_timer = maxf(0.0, cinematic_timer - delta)
	impact_timer = maxf(0.0, impact_timer - delta)
	loot_beam_timer = maxf(0.0, loot_beam_timer - delta)
	chroma_pulse = maxf(0.0, chroma_pulse - delta * 1.7)
	core_overcharge_flash = maxf(0.0, core_overcharge_flash - delta * 1.9)
	_update_vfx_v2(delta)
	_update_boss_phase()
	if battle_mode == "dungeon":
		dungeon_time += delta
	elif battle_mode == "boss_rush":
		boss_rush_time -= delta
		if boss_rush_time <= 0.0:
			_finish_boss_rush()
	elif battle_mode == "trial":
		trial_time -= delta
		if trial_time <= 0.0:
			_finish_trial()
	_update_world_event(delta)
	_refresh_ultra_streamed_assets()
	_update_music_for_biome()
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

	if feature_panel != "":
		_handle_feature_input(p)
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

	# Colossus feature bar
	if Rect2(158,202,96,42).has_point(p):
		_open_feature("tower")
		return
	if Rect2(260,202,96,42).has_point(p):
		_open_feature("trials")
		return
	if Rect2(362,202,96,42).has_point(p):
		_open_feature("talents")
		return
	if Rect2(464,202,96,42).has_point(p):
		_open_feature("style")
		return

	# Mythic feature shortcuts
	if Rect2(18,305,132,46).has_point(p):
		_open_feature("forge")
		return
	if Rect2(18,360,132,46).has_point(p):
		_open_feature("dungeon")
		return
	if Rect2(570,305,132,46).has_point(p):
		_open_feature("garden")
		return
	if Rect2(570,360,132,46).has_point(p):
		_open_feature("evolve")
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
	if crit:
		impact_timer = maxf(impact_timer,0.34)
		chroma_pulse = maxf(chroma_pulse,0.38)
		_spawn_vfx_event("crit",Vector2(505,525),Color("#ffe86f"),1.15)
	elif kind == "basic":
		_spawn_vfx_event("basic",Vector2(505,525),color,0.72)
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
		if battle_mode == "tower":
			_finish_tower()
			return
		if battle_mode == "trial":
			_finish_trial()
			return
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
	cinematic_timer = 0.62
	cinematic_kind = "skill_%d" % index
	impact_timer = maxf(impact_timer,0.48)
	chroma_pulse = 0.65
	_play_sfx("skill_leaf" if index == 0 else ("skill_star" if index == 1 else "ui_confirm"))
	_spawn_vfx_event("skill",Vector2(235,535) if index == 2 else Vector2(505,525),Color(skill["color"]),1.0+index*0.12)
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
	cinematic_timer = 1.25
	cinematic_kind = "ultimate"
	impact_timer = 1.0
	chroma_pulse = 1.0
	screen_flash = 1.0
	camera_shake = 15.0
	_play_sfx("legendary_drop")
	_spawn_vfx_event("ultimate",Vector2(505,525),Color("#fff091"),1.55)
	_spawn_vfx_event("ultimate",Vector2(235,535),Color("#8df6ff"),1.10)
	screen_rings.append({"pos":Vector2(360,520),"r":20.0,"life":0.8,"color":Color("#fff091")})
	var dmg := hero_power * 7.5 * (1.0 + float(ascensions)*0.05)
	_deal_damage(dmg,true,Color("#fff091"),"ultimate")
	_spawn_burst(Vector2(505,525),Color("#fff091"),38)
	_show_toast("WILDBLOOM!")

func _on_enemy_defeated() -> void:
	if battle_mode == "dungeon":
		total_kills += 1
		dungeon_room += 1
		gold += 90 + dungeon_index * 70 + dungeon_room * 25
		forge_stones += 1 if rng.randf() < 0.38 else 0
		if dungeon_room >= 5:
			_finish_dungeon()
		else:
			_spawn_enemy()
		_save()
		return
	if battle_mode == "boss_rush":
		total_kills += 1
		boss_rush_score += 1
		gold += 120 + boss_rush_score * 35
		_spawn_enemy()
		return
	if battle_mode == "tower":
		total_kills += 1
		tower_floor += 1
		tower_best = maxi(tower_best,tower_floor)
		gold += 80 + tower_floor*18
		if tower_floor % 5 == 0:
			shards += 2 + int(tower_floor/10)
			forge_stones += 1
		_spawn_enemy()
		_save()
		return
	if battle_mode == "trial":
		total_kills += 1
		trial_score += 1
		_spawn_enemy()
		return

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
		talent_points += 1
		_show_toast("Level %d! +1 Talent" % player_level)

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

func _update_boss_phase() -> void:
	if not enemy_boss or enemy_hp_max <= 0.0:
		boss_phase = 0
		return
	var ratio := enemy_hp / enemy_hp_max
	var new_phase := 0
	if ratio < 0.66: new_phase = 1
	if ratio < 0.33: new_phase = 2
	if new_phase > boss_phase:
		boss_phase = new_phase
		cinematic_timer = 0.85
		cinematic_kind = "boss_phase"
		screen_flash = 0.72
		chroma_pulse = 1.0
		camera_shake = 12.0
		impact_timer = 0.72
		enemy_attack_cd = maxf(0.45,enemy_attack_cd*0.84)
		_play_sfx("boss_intro")
		var phase_col := Color(str(enemy.get("color","#ff796c")))
		_spawn_vfx_event("boss_phase",Vector2(510,525),phase_col,1.2+boss_phase*0.25)
		_spawn_burst(Vector2(510,525),phase_col,28+boss_phase*12)

func _spawn_enemy() -> void:
	if battle_mode == "tower":
		var theme: Dictionary = D.TOWER_THEMES[int((tower_floor-1)/10)%D.TOWER_THEMES.size()]
		enemy_boss = tower_floor % 10 == 0
		enemy_elite = not enemy_boss and tower_floor % 5 == 0
		enemy = {"name":theme["enemy"],"color":theme["color"],"shape":"boss" if enemy_boss else "golem","hp":1.0+tower_floor*0.075,"atk":1.0+tower_floor*0.028,"speed":0.92+minf(0.35,tower_floor*0.005)}
		enemy_hp_max = (95.0 + pow(float(maxi(stage,10)),1.30)*18.0) * float(enemy["hp"]) * (1.0+ascensions*0.10)
		enemy_hp = enemy_hp_max
		enemy_attack_cd = maxf(0.52,1.50/float(enemy["speed"]))
		enemy_timer = 0.0
		return
	if battle_mode == "trial":
		var tr: Dictionary = D.TRIALS[trial_index]
		enemy_boss = trial_score % 7 == 6
		enemy_elite = not enemy_boss and trial_score % 3 == 2
		enemy = {"name":"%s Echo" % tr["name"],"color":tr["color"],"shape":"wisp" if not enemy_boss else "boss","hp":1.15+trial_score*0.08,"atk":1.05+trial_score*0.025,"speed":1.05+minf(0.30,trial_score*0.012)}
		enemy_hp_max = (90.0 + pow(float(maxi(stage,12)),1.28)*18.0) * float(enemy["hp"])
		enemy_hp = enemy_hp_max
		enemy_attack_cd = maxf(0.55,1.45/float(enemy["speed"]))
		enemy_timer = 0.0
		return
	if battle_mode == "dungeon":
		var dd: Dictionary = D.DUNGEONS[dungeon_index]
		enemy_boss = dungeon_room == 4
		enemy_elite = not enemy_boss
		enemy = {
			"name": ("%s Guardian" % dd["name"]) if not enemy_boss else ("%s Keeper" % dd["name"]),
			"color": dd["color"],
			"shape": "golem" if not enemy_boss else "boss",
			"hp": float(dd["hp_mult"]) * (1.0 + dungeon_room * 0.22),
			"atk": 1.20 + dungeon_index * 0.13,
			"speed": 0.86 + dungeon_index * 0.04
		}
		enemy_hp_max = (105.0 + pow(float(maxi(stage,12)),1.34)*20.0) * float(enemy["hp"]) * (1.0 + ascensions*0.12)
		enemy_hp = enemy_hp_max
		enemy_attack_cd = maxf(0.62,1.55/float(enemy["speed"]))
		enemy_timer = 0.0
		return
	if battle_mode == "boss_rush":
		enemy_boss = true
		enemy_elite = false
		var bidx := boss_rush_score % D.BOSSES.size()
		enemy = D.BOSSES[bidx].duplicate(true)
		enemy["shape"] = "boss"
		enemy["hp"] = 3.1 + boss_rush_score * 0.48
		enemy["atk"] = 1.30 + boss_rush_score * 0.055
		enemy["speed"] = 0.86 + minf(0.42,boss_rush_score*0.02)
		enemy_hp_max = (110.0 + pow(float(maxi(stage,15)),1.32)*18.0) * float(enemy["hp"])
		enemy_hp = enemy_hp_max
		enemy_attack_cd = maxf(0.52,1.45/float(enemy["speed"]))
		enemy_timer = 0.0
		return

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
	bonus += float(talent_levels[7])*0.05
	if world_event_index == 0: bonus *= 2.0
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
	if rarity >= 5 and rng.randf() < minf(0.60,0.18 + rarity*0.015):
		forge_stones += 1 + int(rarity/15)
	if rarity >= 6:
		loot_beam_timer = 1.25 + minf(1.5,float(rarity)*0.035)
		chroma_pulse = maxf(chroma_pulse,0.75)
		_play_sfx("legendary_drop" if rarity >= 10 else "loot_burst")
	if rarity >= 10:
		rarity_cutscene = 1.75
		rarity_cutscene_name = D.RARITIES[rarity]
		rarity_cutscene_color = _rarity_color(rarity)
		screen_flash = 0.82
		camera_shake = 10.0
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
	var evolution_bonus := 1.0 + float(evolution_tier) * 0.075
	var talent_all := 1.0 + float(talent_levels[11]) * 0.05
	var talent_power := 1.0 + float(talent_levels[0]) * 0.03
	var talent_hp := 1.0 + float(talent_levels[3]) * 0.04
	var artifact_power := 1.0
	var artifact_hp := 1.0
	if active_artifact < artifact_levels.size() and stage >= int(D.ARTIFACTS[active_artifact]["unlock"]):
		var al := float(artifact_levels[active_artifact])
		match active_artifact:
			0,3: artifact_power += al*0.025
			2: artifact_hp += al*0.035
			6,7:
				artifact_power += al*0.018
				artifact_hp += al*0.018
	hero_power = (48.0 + player_level*3.0 + power_sum*0.19) * (1.0+set_bonus+float(ascensions)*0.12) * evolution_bonus * talent_all * talent_power * artifact_power
	hero_hp_max = (160.0 + player_level*11.0 + power_sum*0.12) * (1.0+hp_bonus/100.0+float(ascensions)*0.08) * (1.0 + evolution_tier*0.055) * talent_all * talent_hp * artifact_hp
	crit_chance = clampf(0.12+crit_bonus+float(talent_levels[1])*0.01,0.05,0.72)
	haste = clampf(haste_bonus+float(talent_levels[2])*0.02,0.0,1.35)
	dodge = clampf(0.03+dodge_bonus,0.0,0.35)
	leech = clampf(leech_bonus,0.0,0.22)
	armor = clampf(power_sum/200000.0+float(talent_levels[4])*0.02,0.0,0.58)
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
		"evolution_tier":evolution_tier,"forge_level":forge_level,"forge_stones":forge_stones,"forge_slot":forge_slot,
		"dungeon_keys":dungeon_keys,"dungeon_index":dungeon_index,"boss_rush_best":boss_rush_best,
		"garden_level":garden_level,"garden_xp":garden_xp,"garden_plots":garden_plots,"garden_crop_types":garden_crop_types,
		"achievement_claimed":achievement_claimed,
		"tower_floor":tower_floor,"tower_best":tower_best,"trial_index":trial_index,
		"talent_points":talent_points,"talent_levels":talent_levels,"artifact_levels":artifact_levels,"active_artifact":active_artifact,
		"selected_skin":selected_skin,"owned_skins":owned_skins,"selected_title":selected_title,
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
	evolution_tier=clampi(int(parsed.get("evolution_tier",evolution_tier)),0,D.EVOLUTIONS.size()-1)
	forge_level=int(parsed.get("forge_level",forge_level)); forge_stones=int(parsed.get("forge_stones",forge_stones)); forge_slot=clampi(int(parsed.get("forge_slot",forge_slot)),0,5)
	dungeon_keys=int(parsed.get("dungeon_keys",dungeon_keys)); dungeon_index=clampi(int(parsed.get("dungeon_index",dungeon_index)),0,D.DUNGEONS.size()-1)
	boss_rush_best=int(parsed.get("boss_rush_best",boss_rush_best)); garden_level=int(parsed.get("garden_level",garden_level)); garden_xp=int(parsed.get("garden_xp",garden_xp))
	var gp=parsed.get("garden_plots",garden_plots); if gp is Array and gp.size()==3: garden_plots=gp
	var gc=parsed.get("garden_crop_types",garden_crop_types); if gc is Array and gc.size()==3: garden_crop_types=gc
	var ac=parsed.get("achievement_claimed",achievement_claimed); if ac is Array and ac.size()==6: achievement_claimed=ac
	tower_floor=maxi(1,int(parsed.get("tower_floor",tower_floor))); tower_best=int(parsed.get("tower_best",tower_best)); trial_index=clampi(int(parsed.get("trial_index",trial_index)),0,D.TRIALS.size()-1)
	talent_points=int(parsed.get("talent_points",talent_points)); active_artifact=clampi(int(parsed.get("active_artifact",active_artifact)),0,D.ARTIFACTS.size()-1)
	selected_skin=clampi(int(parsed.get("selected_skin",selected_skin)),0,D.SKINS.size()-1); selected_title=clampi(int(parsed.get("selected_title",selected_title)),0,D.TITLES.size()-1)
	var tl=parsed.get("talent_levels",talent_levels); if tl is Array and tl.size()==12: talent_levels=tl
	var ar=parsed.get("artifact_levels",artifact_levels); if ar is Array and ar.size()==8: artifact_levels=ar
	var os=parsed.get("owned_skins",owned_skins); if os is Array and os.size()==8: owned_skins=os

# -------------------------------------------------------------------
# COLOSSUS V0.6 SYSTEMS
# -------------------------------------------------------------------

func _setup_colossus_assets() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -14.0
	add_child(music_player)
	music_player.finished.connect(_restart_music)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -7.0
	add_child(sfx_player)
	for i in 8:
		var p := "res://assets/visual/biome_overlay_%d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex is Texture2D:
				biome_overlays.append(tex)
	if ResourceLoader.exists("res://assets/visual/rune_atlas.png"):
		var rune = load("res://assets/visual/rune_atlas.png")
		if rune is Texture2D:
			biome_overlays.append(rune)
	for i in 4:
		var aura_path := "res://assets/visual/boss_aura_%d.png" % i
		if ResourceLoader.exists(aura_path):
			var aura = load(aura_path)
			if aura is Texture2D:
				premium_atlases.append(aura)
	for i in 4:
		var noise_path := "res://assets/visual/magic_noise_%d.png" % i
		if ResourceLoader.exists(noise_path):
			var noise = load(noise_path)
			if noise is Texture2D:
				magic_noise_maps.append(noise)
	for i in 3:
		var field_path := "res://assets/visual/v07/energy_field_%d.png" % i
		if ResourceLoader.exists(field_path):
			var field = load(field_path)
			if field is Texture2D:
				visual_overkill_fields.append(field)
	for i in 2:
		var impact_path := "res://assets/visual/v07/impact_atlas_%d.png" % i
		if ResourceLoader.exists(impact_path):
			var impact = load(impact_path)
			if impact is Texture2D:
				impact_atlases.append(impact)
	for i in 2:
		var beam_path := "res://assets/visual/v07/loot_beam_%d.png" % i
		if ResourceLoader.exists(beam_path):
			var beam = load(beam_path)
			if beam is Texture2D:
				loot_beams.append(beam)
	var spark_path := "res://assets/visual/v07/spark_field.png"
	if ResourceLoader.exists(spark_path):
		var spark = load(spark_path)
		if spark is Texture2D:
			spark_field = spark

func _refresh_ultra_streamed_assets() -> void:
	var biome_idx := _biome_index()
	if biome_idx != ultra_biome_loaded:
		ultra_biome_texture = null
		var biome_path := "res://assets/visual/v08/ultra_biome_%d.png" % biome_idx
		if ResourceLoader.exists(biome_path):
			var biome_res = ResourceLoader.load(biome_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
			if biome_res is Texture2D:
				ultra_biome_texture = biome_res
		ultra_biome_loaded = biome_idx
	var boss_idx := biome_idx if enemy_boss else -1
	if boss_idx != ultra_boss_loaded:
		ultra_boss_texture = null
		if boss_idx >= 0:
			var boss_path := "res://assets/visual/v08/boss_stage_%d.png" % boss_idx
			if ResourceLoader.exists(boss_path):
				var boss_res = ResourceLoader.load(boss_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
				if boss_res is Texture2D:
					ultra_boss_texture = boss_res
		ultra_boss_loaded = boss_idx
	var hero_idx := clampi(selected_skin,0,7)
	if hero_idx != ultra_hero_loaded:
		ultra_hero_texture = null
		var hero_path := "res://assets/visual/v08/hero_skin_%d.png" % hero_idx
		if ResourceLoader.exists(hero_path):
			var hero_res = ResourceLoader.load(hero_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
			if hero_res is Texture2D:
				ultra_hero_texture = hero_res
		ultra_hero_loaded = hero_idx
	var enemy_idx := biome_idx
	if enemy_idx != ultra_enemy_loaded:
		ultra_enemy_texture = null
		var enemy_path := "res://assets/visual/v08/boss_sprite_%d.png" % enemy_idx
		if ResourceLoader.exists(enemy_path):
			var enemy_res = ResourceLoader.load(enemy_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
			if enemy_res is Texture2D:
				ultra_enemy_texture = enemy_res
		ultra_enemy_loaded = enemy_idx
	var cinematic_idx := _ultra_cinematic_index()
	if cinematic_idx != ultra_cinematic_loaded:
		ultra_cinematic_texture = null
		if cinematic_idx >= 0:
			var cinematic_path := "res://assets/visual/v08/cinematic_%d.png" % cinematic_idx
			if ResourceLoader.exists(cinematic_path):
				var cinematic_res = ResourceLoader.load(cinematic_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
				if cinematic_res is Texture2D:
					ultra_cinematic_texture = cinematic_res
		ultra_cinematic_loaded = cinematic_idx

func _ultra_cinematic_index() -> int:
	if cinematic_timer <= 0.0:
		return -1
	match cinematic_kind:
		"skill_0": return 0
		"skill_1": return 1
		"skill_2": return 2
		"ultimate": return 3
		"boss_phase": return 6
		_: return 4

func _get_ultra_ui_surface(index: int) -> Texture2D:
	if ultra_ui_cache.has(index):
		return ultra_ui_cache[index]
	var path := "res://assets/visual/v08/ui_surface_%d.png" % clampi(index,0,3)
	if not ResourceLoader.exists(path):
		return null
	var res = ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
	if res is Texture2D:
		ultra_ui_cache[index] = res
		if ultra_ui_cache.size() > 2:
			for key in ultra_ui_cache.keys():
				if int(key) != index:
					ultra_ui_cache.erase(key)
					break
		return res
	return null

func _music_paths() -> Array[String]:
	return [
		"res://assets/audio/emerald_wander.wav",
		"res://assets/audio/moonlit_rift.wav",
		"res://assets/audio/crystal_depths.wav",
		"res://assets/audio/ashen_boss.wav",
		"res://assets/audio/astral_origin.wav"
	]

func _update_music_for_biome() -> void:
	if music_player == null: return
	var wanted := _biome_index() % _music_paths().size()
	if enemy_boss or battle_mode in ["boss_rush","tower"]:
		wanted = 3
	if evolution_tier >= 5:
		wanted = 4
	if wanted == music_track and music_player.playing: return
	music_track = wanted
	var path := _music_paths()[wanted]
	if ResourceLoader.exists(path):
		music_player.stream = load(path)
		music_player.play()

func _restart_music() -> void:
	if music_player != null and music_player.stream != null:
		music_player.play()

func _play_sfx(name: String) -> void:
	if sfx_player == null: return
	var path := "res://assets/audio/%s.wav" % name
	if ResourceLoader.exists(path):
		sfx_player.stream = load(path)
		sfx_player.play()

func _update_world_event(delta: float) -> void:
	if world_event_index >= 0:
		world_event_time -= delta
		if world_event_time <= 0.0:
			world_event_index = -1
			world_event_cooldown = 28.0
			_show_toast("World Event ended")
	else:
		world_event_cooldown -= delta
		if world_event_cooldown <= 0.0:
			world_event_index = rng.randi_range(0,D.WORLD_EVENTS.size()-1)
			world_event_time = float(D.WORLD_EVENTS[world_event_index]["duration"])
			_show_toast("WORLD EVENT: %s" % D.WORLD_EVENTS[world_event_index]["name"])
			screen_flash = 0.45

func _start_tower() -> void:
	if stage < 15:
		_show_toast("Tower unlocks at Stage 15")
		return
	battle_mode = "tower"
	tower_floor = maxi(1,tower_best)
	feature_panel = ""
	hero_hp = hero_hp_max
	_spawn_enemy()
	_show_toast("Tower Floor %d" % tower_floor)

func _finish_tower() -> void:
	tower_best = maxi(tower_best,tower_floor)
	var reward := tower_floor*90
	gold += reward
	shards += int(tower_floor/5)
	battle_mode = "normal"
	hero_hp = hero_hp_max
	_show_toast("Tower ended · Best %d" % tower_best)
	_spawn_enemy()
	_save()

func _start_trial() -> void:
	if stage < 10:
		_show_toast("Trials unlock at Stage 10")
		return
	battle_mode = "trial"
	trial_score = 0
	trial_time = 35.0
	feature_panel = ""
	hero_hp = hero_hp_max
	_spawn_enemy()
	_show_toast(str(D.TRIALS[trial_index]["name"]))

func _finish_trial() -> void:
	if battle_mode != "trial": return
	match trial_index:
		0: forge_stones += trial_score
		1: shards += int(trial_score*1.4)
		2: gems += int(trial_score/2)
		3: essence += trial_score*2
	gold += trial_score*160
	battle_mode = "normal"
	trial_time = 0.0
	hero_hp = hero_hp_max
	_show_toast("Trial score %d" % trial_score)
	_spawn_enemy()
	_save()

func _upgrade_talent(index: int) -> void:
	if index < 0 or index >= talent_levels.size(): return
	var t: Dictionary = D.TALENTS[index]
	var level := int(talent_levels[index])
	if level >= int(t["max"]):
		_show_toast("Talent maxed")
		return
	var cost := int(t["cost"]) + int(level/3)
	if talent_points < cost:
		_show_toast("Need %d Talent Points" % cost)
		return
	talent_points -= cost
	talent_levels[index] = level+1
	_recalc_stats()
	_show_toast("%s Lv.%d" % [t["name"],level+1])
	_save()

func _upgrade_artifact() -> void:
	if stage < int(D.ARTIFACTS[active_artifact]["unlock"]):
		_show_toast("Artifact unlocks at Stage %d" % int(D.ARTIFACTS[active_artifact]["unlock"]))
		return
	var level := int(artifact_levels[active_artifact])
	var cost := 4 + level*2
	if shards < cost:
		_show_toast("Need %d Shards" % cost)
		return
	shards -= cost
	artifact_levels[active_artifact] = level+1
	_recalc_stats()
	_play_sfx("awaken")
	_show_toast("%s Lv.%d" % [D.ARTIFACTS[active_artifact]["name"],level+1])
	_save()

func _skin_action(index: int) -> void:
	var sk: Dictionary = D.SKINS[index]
	if not bool(owned_skins[index]):
		if stage < int(sk["unlock"]):
			_show_toast("Unlocks at Stage %d" % int(sk["unlock"]))
			return
		var cost := int(sk["gems"])
		if gems < cost:
			_show_toast("Need %d Gems" % cost)
			return
		gems -= cost
		owned_skins[index] = true
		_play_sfx("evolve")
	selected_skin = index
	screen_flash = 0.35
	_show_toast(str(sk["name"]))
	_save()

func _unlocked_title_count() -> int:
	var count := 1
	for t in D.TITLES:
		if stage >= int(t["need"]): count += 1
	return clampi(count,1,D.TITLES.size())

# -------------------------------------------------------------------
# MYTHIC V0.5 SYSTEMS
# -------------------------------------------------------------------

func _open_feature(name: String) -> void:
	feature_panel = name
	panel_open = false
	_show_toast("")
	queue_redraw()

func _handle_feature_input(p: Vector2) -> void:
	if Rect2(632,236,45,45).has_point(p):
		feature_panel = ""
		return
	match feature_panel:
		"forge":
			if Rect2(64,414,72,58).has_point(p):
				forge_slot = (forge_slot + 5) % 6
				return
			if Rect2(584,414,72,58).has_point(p):
				forge_slot = (forge_slot + 1) % 6
				return
			if Rect2(64,930,180,66).has_point(p):
				_forge_enhance()
				return
			if Rect2(270,930,180,66).has_point(p):
				_forge_reroll()
				return
			if Rect2(476,930,180,66).has_point(p):
				_forge_awaken()
				return
		"dungeon":
			if Rect2(62,448,72,58).has_point(p):
				dungeon_index = (dungeon_index + D.DUNGEONS.size() - 1) % D.DUNGEONS.size()
				return
			if Rect2(586,448,72,58).has_point(p):
				dungeon_index = (dungeon_index + 1) % D.DUNGEONS.size()
				return
			if Rect2(88,900,250,72).has_point(p):
				_start_dungeon()
				return
			if Rect2(382,900,250,72).has_point(p):
				_start_boss_rush()
				return
		"garden":
			for i in 3:
				if Rect2(72+i*196,560,170,230).has_point(p):
					_garden_plot_action(i)
					return
			if Rect2(210,900,300,70).has_point(p):
				_upgrade_garden()
				return
		"evolve":
			if Rect2(185,900,350,76).has_point(p):
				_try_evolution()
				return
		"tower":
			if Rect2(160,890,400,78).has_point(p):
				_start_tower()
				return
		"trials":
			if Rect2(84,430,62,54).has_point(p):
				trial_index = (trial_index + D.TRIALS.size() - 1) % D.TRIALS.size()
				return
			if Rect2(574,430,62,54).has_point(p):
				trial_index = (trial_index + 1) % D.TRIALS.size()
				return
			if Rect2(160,890,400,78).has_point(p):
				_start_trial()
				return
		"talents":
			for i in 12:
				var col := i % 3
				var row := int(i / 3)
				if Rect2(64+col*199,390+row*118,184,98).has_point(p):
					_upgrade_talent(i)
					return
			for i in 8:
				if Rect2(70+i*72,885,62,62).has_point(p):
					active_artifact = i
					_show_toast(str(D.ARTIFACTS[i]["name"]))
					return
			if Rect2(230,970,260,62).has_point(p):
				_upgrade_artifact()
				return
		"style":
			for i in 8:
				var col := i % 4
				var row := int(i / 4)
				if Rect2(66+col*148,382+row*190,132,164).has_point(p):
					_skin_action(i)
					return
			if Rect2(170,810,380,72).has_point(p):
				selected_title = (selected_title + 1) % _unlocked_title_count()
				_save()
				return
			if Rect2(170,900,380,64).has_point(p):
				_claim_achievements()
				return

func _forge_item() -> Dictionary:
	return equipped[forge_slot]

func _forge_enhance() -> void:
	if equipped[forge_slot].is_empty():
		_show_toast("Equip a %s first" % D.SLOTS[forge_slot])
		return
	var item: Dictionary = equipped[forge_slot]
	var level := int(item.get("level",0))
	var stone_cost := 1 + int(level/3)
	var gold_cost := 180 + level*145 + forge_level*60
	if forge_stones < stone_cost or gold < gold_cost:
		_show_toast("Need %d Forge Stone + %sG" % [stone_cost,_short_num(gold_cost)])
		return
	forge_stones -= stone_cost
	gold -= gold_cost
	item["level"] = level + 1
	item["power"] = int(float(item.get("power",0)) * (1.055 + forge_level*0.002))
	equipped[forge_slot] = item
	if (level+1) % 5 == 0:
		forge_level += 1
		screen_flash = 0.35
	_recalc_stats()
	_show_toast("%s +%d" % [D.SLOTS[forge_slot],level+1])
	_save()

func _forge_reroll() -> void:
	if equipped[forge_slot].is_empty():
		_show_toast("Nothing to reroll")
		return
	var item: Dictionary = equipped[forge_slot]
	var rarity := int(item.get("rarity",0))
	var cost := 2 + int(rarity/6)
	if shards < cost:
		_show_toast("Need %d shards" % cost)
		return
	shards -= cost
	var new_affixes: Array = []
	var count := clampi(1 + int(rarity/5),1,4)
	for i in count:
		var aff: Dictionary = D.AFFIXES[rng.randi_range(0,D.AFFIXES.size()-1)]
		var value := rng.randf_range(float(aff["min"]),float(aff["max"])) * (1.0 + rarity*0.04 + forge_level*0.01)
		new_affixes.append({"name":aff["name"],"key":aff["key"],"value":snappedf(value,0.1)})
	item["affixes"] = new_affixes
	equipped[forge_slot] = item
	_recalc_stats()
	_spawn_burst(Vector2(360,690),Color("#a7eaff"),18)
	_show_toast("Affixes rerolled")
	_save()

func _forge_awaken() -> void:
	if equipped[forge_slot].is_empty():
		_show_toast("Nothing to awaken")
		return
	var item: Dictionary = equipped[forge_slot]
	if bool(item.get("awakened",false)):
		_show_toast("Already awakened")
		return
	if int(item.get("rarity",0)) < 5 or int(item.get("level",0)) < 5:
		_show_toast("Requires Epic+ and +5")
		return
	var stone_cost := 8 + int(item.get("rarity",0)/4)
	if forge_stones < stone_cost or shards < 8:
		_show_toast("Need %d Stones + 8 Shards" % stone_cost)
		return
	forge_stones -= stone_cost
	shards -= 8
	item["awakened"] = true
	item["power"] = int(float(item.get("power",0))*1.28)
	equipped[forge_slot] = item
	screen_flash = 0.8
	_spawn_burst(Vector2(360,690),_rarity_color(int(item.get("rarity",0))),34)
	_recalc_stats()
	_show_toast("AWAKENED!")
	_save()

func _start_dungeon() -> void:
	var dd: Dictionary = D.DUNGEONS[dungeon_index]
	if stage < int(dd["unlock"]):
		_show_toast("Unlocks at Stage %d" % int(dd["unlock"]))
		return
	if dungeon_keys <= 0:
		_show_toast("No Dungeon Keys")
		return
	dungeon_keys -= 1
	dungeon_room = 0
	dungeon_time = 0.0
	battle_mode = "dungeon"
	feature_panel = ""
	boss_intro = 0.8
	_spawn_enemy()
	_show_toast("%s entered" % dd["name"])
	_save()

func _finish_dungeon() -> void:
	var dd: Dictionary = D.DUNGEONS[dungeon_index]
	gold += int(dd["gold"])
	shards += int(dd["shards"])
	forge_stones += 3 + dungeon_index
	gems += 1 + dungeon_index
	battle_mode = "normal"
	dungeon_room = 0
	screen_flash = 0.65
	_show_toast("Dungeon cleared!")
	_spawn_enemy()
	_save()

func _start_boss_rush() -> void:
	if stage < 20:
		_show_toast("Boss Rush unlocks at Stage 20")
		return
	if dungeon_keys <= 0:
		_show_toast("No Dungeon Keys")
		return
	dungeon_keys -= 1
	battle_mode = "boss_rush"
	boss_rush_score = 0
	boss_rush_time = 30.0
	feature_panel = ""
	boss_intro = 0.8
	_spawn_enemy()
	_show_toast("30s BOSS RUSH")
	_save()

func _finish_boss_rush() -> void:
	if battle_mode != "boss_rush":
		return
	boss_rush_best = maxi(boss_rush_best,boss_rush_score)
	gold += boss_rush_score * 420
	shards += int(boss_rush_score/2)
	forge_stones += boss_rush_score
	gems += int(boss_rush_score/3)
	battle_mode = "normal"
	boss_rush_time = 0.0
	_show_toast("Boss Rush: %d defeated" % boss_rush_score)
	_spawn_enemy()
	_save()

func _garden_crop(slot: int) -> Dictionary:
	var idx := clampi(int(garden_crop_types[slot]),0,D.CROPS.size()-1)
	return D.CROPS[idx]

func _garden_plot_action(slot: int) -> void:
	var now := int(Time.get_unix_time_from_system())
	var planted := int(garden_plots[slot])
	var crop: Dictionary = _garden_crop(slot)
	if planted <= 0:
		garden_plots[slot] = now
		_show_toast("%s planted" % crop["name"])
		_save()
		return
	var elapsed := now - planted
	if elapsed < int(crop["time"]):
		_show_toast("%ds remaining" % (int(crop["time"])-elapsed))
		return
	gold += int(crop["gold"]) * garden_level
	essence += int(crop["energy"])
	garden_xp += 5 + int(garden_crop_types[slot])*2
	garden_plots[slot] = 0
	garden_crop_types[slot] = mini(D.CROPS.size()-1,int(garden_crop_types[slot]) + (1 if rng.randf()<0.18 else 0))
	if garden_xp >= garden_level*25:
		garden_xp -= garden_level*25
		garden_level += 1
		forge_stones += 2
		_show_toast("Garden Lv.%d!" % garden_level)
	else:
		_show_toast("%s harvested" % crop["name"])
	_save()

func _upgrade_garden() -> void:
	var cost := 800 + garden_level*650
	if gold < cost:
		_show_toast("Need %s Gold" % _short_num(cost))
		return
	gold -= cost
	garden_level += 1
	for i in 3:
		garden_crop_types[i] = mini(D.CROPS.size()-1,int(garden_crop_types[i])+1)
	_show_toast("Garden upgraded")
	_save()

func _try_evolution() -> void:
	if evolution_tier >= D.EVOLUTIONS.size()-1:
		_show_toast("Final evolution reached")
		return
	var next: Dictionary = D.EVOLUTIONS[evolution_tier+1]
	if player_level < int(next["level"]) or stage < int(next["stage"]) or core_level < int(next["core"]):
		_show_toast("Need Lv.%d · Stage %d · Core %d" % [next["level"],next["stage"],next["core"]])
		return
	var gem_cost := 5 + evolution_tier*4
	if gems < gem_cost:
		_show_toast("Need %d Gems" % gem_cost)
		return
	gems -= gem_cost
	evolution_tier += 1
	screen_flash = 1.0
	rarity_cutscene = 2.0
	rarity_cutscene_name = str(D.EVOLUTIONS[evolution_tier]["name"])
	rarity_cutscene_color = Color(str(D.EVOLUTIONS[evolution_tier]["color"]))
	_spawn_burst(Vector2(220,540),rarity_cutscene_color,46)
	_recalc_stats()
	_show_toast("EVOLUTION!")
	_save()

func _adventure_rank_index() -> int:
	var points := stage + player_level + int(core_level/2) + boss_kills*2 + ascensions*10 + evolution_tier*12
	return clampi(int(points/32),0,D.ADVENTURE_RANKS.size()-1)

func _achievement_ready_count() -> int:
	var conditions := [total_kills>=100,boss_kills>=10,core_level>=25,codex_seen.size()>=15,ascensions>=1,evolution_tier>=3]
	var n := 0
	for i in 6:
		if conditions[i] and not achievement_claimed[i]:
			n += 1
	return n

func _claim_achievements() -> void:
	var conditions := [total_kills>=100,boss_kills>=10,core_level>=25,codex_seen.size()>=15,ascensions>=1,evolution_tier>=3]
	var any := false
	for i in 6:
		if conditions[i] and not achievement_claimed[i]:
			achievement_claimed[i] = true
			gems += 4 + i*2
			shards += 3 + i
			any = true
	if any:
		_show_toast("Achievements claimed")
		_save()

# -------------------------------------------------------------------
# FX
# -------------------------------------------------------------------

func _update_vfx_v2(delta: float) -> void:
	for i in range(vfx_particles_v2.size()-1,-1,-1):
		var p: Dictionary = vfx_particles_v2[i]
		p["life"] = float(p["life"]) - delta
		p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
		p["vel"] = Vector2(p["vel"]) * pow(0.055,delta)
		if str(p.get("mode","spark")) == "orb":
			p["vel"].y -= 28.0 * delta
		else:
			p["vel"].y += 72.0 * delta
		if float(p["life"]) <= 0.0:
			vfx_particles_v2.remove_at(i)
	for i in range(vfx_slashes.size()-1,-1,-1):
		var s: Dictionary = vfx_slashes[i]
		s["life"] = float(s["life"]) - delta
		s["radius"] = float(s["radius"]) + float(s.get("grow",90.0)) * delta
		s["angle"] = float(s["angle"]) + float(s.get("spin",0.0)) * delta
		if float(s["life"]) <= 0.0:
			vfx_slashes.remove_at(i)
	for i in range(vfx_bursts.size()-1,-1,-1):
		var b: Dictionary = vfx_bursts[i]
		b["life"] = float(b["life"]) - delta
		b["radius"] = float(b["radius"]) + float(b.get("speed",240.0)) * delta
		if float(b["life"]) <= 0.0:
			vfx_bursts.remove_at(i)

func _spawn_vfx_event(kind: String, pos: Vector2, color: Color, power := 1.0) -> void:
	var particle_count := 14
	var slash_count := 1
	var burst_count := 1
	var speed_min := 90.0
	var speed_max := 240.0
	match kind:
		"crit":
			particle_count = 34
			slash_count = 3
			burst_count = 2
			speed_max = 390.0
		"skill":
			particle_count = 42
			slash_count = 4
			burst_count = 3
			speed_max = 430.0
		"ultimate":
			particle_count = 72
			slash_count = 7
			burst_count = 5
			speed_min = 160.0
			speed_max = 620.0
		"boss_phase":
			particle_count = 58
			slash_count = 6
			burst_count = 4
			speed_max = 520.0
		"core":
			particle_count = 48
			slash_count = 5
			burst_count = 4
			speed_max = 400.0
		"gear":
			particle_count = 30
			slash_count = 3
			burst_count = 2
	for i in particle_count:
		var angle := rng.randf()*TAU
		var speed := rng.randf_range(speed_min,speed_max)*power
		var mode := "streak" if i % 3 == 0 else ("orb" if i % 5 == 0 else "spark")
		vfx_particles_v2.append({
			"pos":pos + Vector2(rng.randf_range(-12,12),rng.randf_range(-12,12)),
			"vel":Vector2(cos(angle),sin(angle))*speed,
			"life":rng.randf_range(0.28,0.82) * (1.0+0.18*power),
			"max_life":0.9,
			"color":color,
			"size":rng.randf_range(2.0,7.5)*(0.75+0.25*power),
			"mode":mode
		})
	for i in slash_count:
		vfx_slashes.append({
			"pos":pos,
			"radius":rng.randf_range(34.0,72.0),
			"angle":rng.randf()*TAU,
			"span":rng.randf_range(0.55,1.45),
			"life":rng.randf_range(0.24,0.52),
			"max_life":0.52,
			"color":color,
			"width":rng.randf_range(3.0,9.0)*(0.8+0.3*power),
			"grow":rng.randf_range(70.0,165.0),
			"spin":rng.randf_range(-2.7,2.7)
		})
	for i in burst_count:
		vfx_bursts.append({
			"pos":pos,
			"radius":16.0+i*9.0,
			"life":0.42+i*0.07,
			"max_life":0.7,
			"color":color,
			"speed":180.0+i*65.0
		})

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
	_draw_colossus_bar()
	_draw_feature_shortcuts()
	_draw_battlefield()
	_draw_skill_row()
	_draw_core_shrine()
	_draw_bottom_nav()
	_draw_fx()
	_draw_vfx_v2()
	_draw_cinematic_vfx()
	draw_set_transform(Vector2.ZERO)
	if feature_panel != "": _draw_feature_panel()
	if panel_open: _draw_panel()
	if not current_item.is_empty(): _draw_loot_popup()
	if boss_intro>0.0: _draw_boss_intro()
	if rarity_cutscene>0.0: _draw_rarity_cutscene()
	if screen_flash>0.0:
		draw_rect(Rect2(0,0,W,H),Color(rarity_cutscene_color.r,rarity_cutscene_color.g,rarity_cutscene_color.b,0.12*screen_flash))
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
	if ultra_biome_texture != null:
		draw_texture_rect(ultra_biome_texture,Rect2(0,118,720,735),false,Color(1,1,1,0.78))
	var sun_pos:=Vector2(585,220)
	draw_circle(sun_pos,72,Color(1,0.92,0.58,0.24))
	draw_circle(sun_pos,48,Color(1,0.94,0.68,0.65))

	# moving cloud layers
	for i in 6:
		var cx:=fmod(float(i*155)+time_alive*(8.0+i),900.0)-90.0
		var cy:=210.0+(i%3)*58.0
		_draw_cloud(Vector2(cx,cy),0.7+0.13*(i%2),Color(1,1,1,0.45))

	# far / near parallax silhouettes
	draw_colored_polygon(PackedVector2Array([Vector2(0,510),Vector2(80,380),Vector2(180,500),Vector2(290,335),Vector2(420,500),Vector2(555,350),Vector2(720,470),Vector2(720,650),Vector2(0,650)]),Color(far.r,far.g,far.b,0.34))
	var near_layer := near.darkened(0.04)
	draw_colored_polygon(PackedVector2Array([Vector2(0,590),Vector2(100,470),Vector2(205,575),Vector2(350,435),Vector2(500,575),Vector2(640,455),Vector2(720,530),Vector2(720,700),Vector2(0,700)]),Color(near_layer.r,near_layer.g,near_layer.b,0.42))

	# path + grass
	draw_rect(Rect2(0,555,W,270),Color(near.r,near.g,near.b,0.42))
	draw_colored_polygon(PackedVector2Array([Vector2(0,690),Vector2(720,620),Vector2(720,825),Vector2(0,825)]),Color(ground.r,ground.g,ground.b,0.52))
	var ground_light := ground.lightened(0.08)
	draw_colored_polygon(PackedVector2Array([Vector2(0,732),Vector2(720,660),Vector2(720,825),Vector2(0,825)]),Color(ground_light.r,ground_light.g,ground_light.b,0.46))

	# premium overlays generated into the Colossus content pack
	if _biome_index() < biome_overlays.size():
		draw_texture_rect(biome_overlays[_biome_index()],Rect2(0,190,720,620),false,Color(1,1,1,0.085))
	if spark_field != null and (evolution_tier >= 2 or world_event_index >= 0):
		var spark_alpha := 0.038 + 0.012*minf(5.0,float(evolution_tier))
		draw_texture_rect(spark_field,Rect2(0,170,720,650),false,Color(1,1,1,spark_alpha))
	if magic_noise_maps.size() > 0 and (world_event_index >= 0 or enemy_boss or evolution_tier >= 4):
		var noise_idx := (_biome_index() + maxi(0,world_event_index) + evolution_tier) % magic_noise_maps.size()
		var noise_alpha := 0.045 if world_event_index >= 0 else 0.028
		draw_texture_rect(magic_noise_maps[noise_idx],Rect2(0,180,720,640),false,Color(1,1,1,noise_alpha))
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
	var hud_surface := _get_ultra_ui_surface(0)
	if hud_surface != null:
		draw_texture_rect(hud_surface,Rect2(10,10,700,182),false,Color(1,1,1,0.26))
	_panel(Rect2(14,14,692,174),Color(0.025,0.04,0.05,0.76),Color(0.8,1,0.9,0.18),28,2)
	_draw_avatar(Vector2(65,67))
	_text(str(D.EVOLUTIONS[evolution_tier]["name"]).to_upper(),Vector2(112,52),22,Color(str(D.EVOLUTIONS[evolution_tier]["color"])))
	_text(D.ADVENTURE_RANKS[_adventure_rank_index()],Vector2(112,69),12,Color("#ffe6a6"))
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
	if enemy_boss and ultra_boss_texture != null:
		var boss_alpha := 0.28 + 0.07*boss_phase + 0.04*sin(time_alive*2.7)
		draw_texture_rect(ultra_boss_texture,Rect2(278,282,435,435),false,Color(1,1,1,boss_alpha))
	if visual_overkill_fields.size() > 0 and (enemy_boss or chroma_pulse > 0.02):
		var field_idx := (_biome_index()+boss_phase+evolution_tier) % visual_overkill_fields.size()
		var aa := 0.035 + chroma_pulse*0.055 + boss_phase*0.025
		draw_texture_rect(visual_overkill_fields[field_idx],Rect2(280,270,460,460),false,Color(1,1,1,aa))
		if enemy_boss and boss_phase >= 1:
			draw_texture_rect(visual_overkill_fields[(field_idx+2)%visual_overkill_fields.size()],Rect2(330,320,360,360),false,Color(1,0.76,0.86,0.035+boss_phase*0.025))
	if premium_atlases.size() > 0 and (enemy_boss or evolution_tier >= 3):
		var aura_idx := (evolution_tier + (1 if enemy_boss else 0)) % premium_atlases.size()
		var aura_alpha := 0.10 if enemy_boss else 0.055
		draw_texture_rect(premium_atlases[aura_idx],Rect2(310,300,400,400),false,Color(1,1,1,aura_alpha))
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
	var skin: Dictionary=D.SKINS[selected_skin]
	var skin_main:=Color(str(skin["color"]))
	var skin_accent:=Color(str(skin["accent"]))
	if ultra_hero_texture != null:
		draw_ellipse_custom(pos+Vector2(0,86),72,20,Color(0,0,0,0.20))
		if evolution_tier > 0:
			var evo_col := Color(str(D.EVOLUTIONS[evolution_tier]["color"]))
			for ring in range(3):
				draw_arc(pos+Vector2(0,20),94+ring*12+sin(time_alive*(2.0+ring*0.3))*5.0,0,TAU,48,Color(evo_col.r,evo_col.g,evo_col.b,0.18-ring*0.03),4.0)
		var hero_rect := Rect2(pos+Vector2(-118,-150),Vector2(236,236))
		draw_texture_rect(ultra_hero_texture,hero_rect,false,Color(hurt.r,hurt.g,hurt.b,1.0))
		if evolution_tier >= 3:
			var wing_col := Color(str(D.EVOLUTIONS[evolution_tier]["color"]))
			draw_arc(pos+Vector2(-58,18),68,-2.2,0.55,24,Color(wing_col.r,wing_col.g,wing_col.b,0.34),11.0)
			draw_arc(pos+Vector2(58,18),68,2.6,5.35,24,Color(wing_col.r,wing_col.g,wing_col.b,0.34),11.0)
		return
	draw_ellipse_custom(pos+Vector2(0,78),58,17,Color(0,0,0,0.15))
	# evolution aura + set glow
	if evolution_tier > 0:
		var evo_col := Color(str(D.EVOLUTIONS[evolution_tier]["color"]))
		draw_arc(pos+Vector2(0,22),88+sin(time_alive*2.6)*4.0,0,TAU,42,Color(evo_col.r,evo_col.g,evo_col.b,0.24),5.0)
		for j in evolution_tier:
			var a := time_alive*0.7 + TAU*float(j)/maxf(1.0,float(evolution_tier))
			draw_circle(pos+Vector2(cos(a),sin(a))*78.0,3.5,evo_col)
	if evolution_tier >= 3:
		var wing_col := Color(str(D.EVOLUTIONS[evolution_tier]["color"]))
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-38,30),pos+Vector2(-82,5),pos+Vector2(-64,54),pos+Vector2(-87,78),pos+Vector2(-38,67)]),Color(wing_col.r,wing_col.g,wing_col.b,0.38))
		draw_colored_polygon(PackedVector2Array([pos+Vector2(38,30),pos+Vector2(82,5),pos+Vector2(64,54),pos+Vector2(87,78),pos+Vector2(38,67)]),Color(wing_col.r,wing_col.g,wing_col.b,0.38))
	if set_counts.size()>0:
		draw_arc(pos+Vector2(0,25),82+sin(time_alive*3.0)*3.0,0,TAU,40,Color(0.55,1,0.65,0.18),5.0)
	# cape/body
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-42,25),pos+Vector2(-58,98),pos+Vector2(58,98),pos+Vector2(42,25)]),skin_main.darkened(0.16)*hurt)
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-34,36),pos+Vector2(0,70),pos+Vector2(34,36),pos+Vector2(26,102),pos+Vector2(-26,102)]),skin_main*hurt)
	# face
	draw_circle(pos,53,Color("#f2ddb0")*hurt)
	draw_circle(pos+Vector2(-20,-5),7,Color("#2e2c2a"))
	draw_circle(pos+Vector2(20,-5),7,Color("#2e2c2a"))
	draw_circle(pos+Vector2(-17,-8),2.5,Color.WHITE)
	draw_circle(pos+Vector2(23,-8),2.5,Color.WHITE)
	draw_arc(pos+Vector2(0,8),18,0.25,2.9,18,Color("#8c604b"),3.5)
	# leaf crown
	draw_circle(pos+Vector2(0,-46),51,skin_main)
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-48,-48),pos+Vector2(-24,-83),pos+Vector2(-5,-58),pos+Vector2(19,-92),pos+Vector2(34,-58),pos+Vector2(51,-48)]),skin_main.darkened(0.14))
	_leaf(pos+Vector2(7,-92),skin_accent)
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
	if ultra_enemy_texture != null and (enemy_boss or enemy_elite):
		draw_ellipse_custom(pos+Vector2(0,82),90,23,Color(0,0,0,0.22))
		if enemy_elite:
			draw_arc(pos,92+sin(time_alive*5.0)*5.0,0,TAU,42,Color(1,0.82,0.3,0.38),7.0)
		if enemy_boss:
			var boss_col := Color(str(enemy.get("color","#ff7868")))
			for ring in range(3):
				draw_arc(pos,112+ring*14+sin(time_alive*(2.4+ring*0.4))*6.0,0,TAU,52,Color(boss_col.r,boss_col.g,boss_col.b,0.30-ring*0.05),7.0)
		var enemy_rect := Rect2(pos+Vector2(-132,-160),Vector2(264,264))
		draw_texture_rect(ultra_enemy_texture,enemy_rect,false,Color(c.r,c.g,c.b,1.0))
		return
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
	draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.62))
	var loot_surface := _get_ultra_ui_surface(2)
	if loot_surface != null:
		draw_texture_rect(loot_surface,Rect2(24,325,672,710),false,Color(1,1,1,0.42))
	var r:=int(current_item.get("rarity",0))
	var col:=_rarity_color(r)
	if r >= 6 and loot_beams.size() > 0:
		var beam_idx := 1 if r >= 20 else 0
		var pulse := 0.38 + 0.10*sin(time_alive*7.0)
		draw_texture_rect(loot_beams[beam_idx],Rect2(150,-40,420,1080),false,Color(col.r,col.g,col.b,pulse))
		draw_texture_rect(loot_beams[beam_idx],Rect2(250,120,220,760),false,Color(1,1,1,0.18))
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



func _draw_vfx_v2() -> void:
	for p in vfx_particles_v2:
		var life := clampf(float(p["life"])/maxf(0.01,float(p.get("max_life",0.9))),0.0,1.0)
		var pos := Vector2(p["pos"])
		var vel := Vector2(p["vel"])
		var col := Color(p["color"])
		var size := float(p["size"])
		var mode := str(p.get("mode","spark"))
		var alpha := life*life
		match mode:
			"streak":
				var dir := vel.normalized()
				var len := 18.0 + vel.length()*0.065
				draw_line(pos-dir*len,pos+dir*4.0,Color(col.r,col.g,col.b,0.18*alpha),size*3.2)
				draw_line(pos-dir*len*0.72,pos+dir*2.0,Color(col.r,col.g,col.b,0.78*alpha),maxf(1.2,size*0.72))
			"orb":
				draw_circle(pos,size*2.8,Color(col.r,col.g,col.b,0.08*alpha))
				draw_circle(pos,size*1.55,Color(col.r,col.g,col.b,0.24*alpha))
				draw_circle(pos,size*0.68,Color(1,1,1,0.78*alpha))
			_:
				draw_line(pos+Vector2(-size*2.2,0),pos+Vector2(size*2.2,0),Color(col.r,col.g,col.b,0.48*alpha),1.6)
				draw_line(pos+Vector2(0,-size*2.2),pos+Vector2(0,size*2.2),Color(col.r,col.g,col.b,0.48*alpha),1.6)
				draw_circle(pos,size,Color(col.r,col.g,col.b,0.72*alpha))
	for s in vfx_slashes:
		var life := clampf(float(s["life"])/maxf(0.01,float(s.get("max_life",0.52))),0.0,1.0)
		var pos := Vector2(s["pos"])
		var col := Color(s["color"])
		var angle := float(s["angle"])
		var span := float(s["span"])
		var radius := float(s["radius"])
		var width := float(s["width"])
		draw_arc(pos,radius,angle,angle+span,28,Color(col.r,col.g,col.b,0.12*life),width*3.1)
		draw_arc(pos,radius,angle,angle+span,28,Color(col.r,col.g,col.b,0.68*life),width)
		draw_arc(pos,radius-5.0,angle+0.05,angle+span-0.04,28,Color(1,1,1,0.42*life),maxf(1.0,width*0.34))
	for b in vfx_bursts:
		var life := clampf(float(b["life"])/maxf(0.01,float(b.get("max_life",0.7))),0.0,1.0)
		var pos := Vector2(b["pos"])
		var col := Color(b["color"])
		var radius := float(b["radius"])
		draw_circle(pos,maxf(0.0,18.0*(1.0-life)),Color(col.r,col.g,col.b,0.12*life))
		draw_arc(pos,radius,0,TAU,56,Color(col.r,col.g,col.b,0.08*life),12.0)
		draw_arc(pos,radius,0,TAU,56,Color(col.r,col.g,col.b,0.52*life),3.2)

func _draw_cinematic_vfx() -> void:
	if cinematic_timer > 0.0 and ultra_cinematic_texture != null:
		var ultra_alpha := 0.12 + 0.12*clampf(cinematic_timer/1.25,0.0,1.0)
		draw_texture_rect(ultra_cinematic_texture,Rect2(-40,145,800,800),false,Color(1,1,1,ultra_alpha))
		draw_texture_rect(ultra_cinematic_texture,Rect2(80,265,560,560),false,Color(1,1,1,ultra_alpha*0.24))
	if impact_timer > 0.0 and impact_atlases.size() > 0:
		var atlas_idx := 1 if cinematic_kind in ["ultimate","boss_phase"] else 0
		var atlas := impact_atlases[atlas_idx]
		var norm := 1.0-clampf(impact_timer/(1.0 if atlas_idx==1 else 0.48),0.0,1.0)
		var frame := clampi(int(norm*15.0),0,15)
		var sx := float((frame%4)*512)
		var sy := float((frame/4)*512)
		var target := Vector2(505,525) if cinematic_kind != "skill_2" else Vector2(235,535)
		var size := 330.0 if atlas_idx==1 else 240.0
		draw_texture_rect_region(atlas,Rect2(target-Vector2(size,size)*0.5,Vector2(size,size)),Rect2(sx,sy,512,512),Color(1,1,1,0.82))
		# faux bloom: larger soft copies
		draw_texture_rect_region(atlas,Rect2(target-Vector2(size*1.35,size*1.35)*0.5,Vector2(size*1.35,size*1.35)),Rect2(sx,sy,512,512),Color(1,1,1,0.10))
	if cinematic_timer > 0.0:
		var t := clampf(cinematic_timer/1.25,0.0,1.0)
		if visual_overkill_fields.size() > 0:
			var idx := int(time_alive*3.0)%visual_overkill_fields.size()
			var alpha := 0.045 + 0.055*t
			draw_texture_rect(visual_overkill_fields[idx],Rect2(0,180,720,640),false,Color(1,1,1,alpha))
		if cinematic_kind == "ultimate":
			draw_rect(Rect2(0,180,720,640),Color(1.0,0.91,0.45,0.035+0.055*t))
			for i in 7:
				var rad := 70.0+i*52.0+(1.0-t)*100.0
				draw_arc(Vector2(505,525),rad,time_alive*(0.6+i*0.04),time_alive*(0.6+i*0.04)+TAU*0.72,72,Color(1,0.91,0.45,0.14*t),4.0)
		elif cinematic_kind == "boss_phase":
			draw_rect(Rect2(0,180,720,640),Color(0.85,0.08,0.17,0.045+0.045*t))
			_text("PHASE %d" % (boss_phase+1),Vector2(360,330),28,Color(1,0.83,0.84,0.85*t),true)

func _draw_colossus_bar() -> void:
	var buttons := [
		{"rect":Rect2(158,202,96,42),"label":"TOWER","col":Color("#76a3d7")},
		{"rect":Rect2(260,202,96,42),"label":"TRIALS","col":Color("#d38a7a")},
		{"rect":Rect2(362,202,96,42),"label":"TALENTS","col":Color("#a783d2")},
		{"rect":Rect2(464,202,96,42),"label":"STYLE","col":Color("#e2a0c7")}
	]
	for b in buttons:
		var rr: Rect2=b["rect"]
		_panel(rr,Color(0.04,0.05,0.06,0.90),Color(b["col"]),12,2)
		_text(str(b["label"]),rr.get_center()+Vector2(0,5),11,Color.WHITE,true)
	if talent_points>0:
		draw_circle(Vector2(450,205),6,Color("#fff075"))
	if world_event_index>=0:
		var ev: Dictionary=D.WORLD_EVENTS[world_event_index]
		_panel(Rect2(198,252,324,38),Color(0.05,0.04,0.07,0.88),Color(str(ev["color"])),14,2)
		_text("%s · %ds" % [ev["name"],int(world_event_time)],Vector2(360,277),13,Color.WHITE,true)

func _draw_feature_shortcuts() -> void:
	var items := [
		{"rect":Rect2(18,305,132,46),"label":"FORGE","col":Color("#bc8d62")},
		{"rect":Rect2(18,360,132,46),"label":"DUNGEON","col":Color("#6a85c9")},
		{"rect":Rect2(570,305,132,46),"label":"GARDEN","col":Color("#67ad6f")},
		{"rect":Rect2(570,360,132,46),"label":"EVOLVE","col":Color("#ad79ca")}
	]
	for e in items:
		var rect: Rect2 = e["rect"]
		_panel(rect,Color(0.06,0.06,0.07,0.84),Color(e["col"]),14,2)
		_text(str(e["label"]),rect.get_center()+Vector2(0,6),13,Color.WHITE,true)
	if dungeon_keys>0:
		draw_circle(Vector2(142,362),7,Color("#ffe56f"))
	if _can_evolve_now():
		draw_circle(Vector2(692,307),7,Color("#ff6f73"))

func _can_evolve_now() -> bool:
	if evolution_tier >= D.EVOLUTIONS.size()-1: return false
	var next: Dictionary = D.EVOLUTIONS[evolution_tier+1]
	return player_level>=int(next["level"]) and stage>=int(next["stage"]) and core_level>=int(next["core"])

func _draw_feature_panel() -> void:
	draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.58))
	_panel(Rect2(38,220,644,840),Color("#17171c"),Color("#71667d"),30,3)
	_panel(Rect2(632,236,45,45),Color("#4b3d47"),Color("#937d8c"),14,1)
	_text("×",Vector2(654,267),25,Color.WHITE,true)
	match feature_panel:
		"forge": _draw_forge_panel()
		"dungeon": _draw_dungeon_panel()
		"garden": _draw_garden_panel()
		"evolve": _draw_evolution_panel()
		"tower": _draw_tower_panel()
		"trials": _draw_trials_panel()
		"talents": _draw_talents_panel()
		"style": _draw_style_panel()


func _draw_tower_panel() -> void:
	_text("ENDLESS WORLD TOWER",Vector2(360,278),30,Color("#a8caff"),true)
	var theme: Dictionary=D.TOWER_THEMES[int((maxi(1,tower_best)-1)/10)%D.TOWER_THEMES.size()]
	var col:=Color(str(theme["color"]))
	draw_arc(Vector2(360,500),118,time_alive*0.35,time_alive*0.35+TAU*0.8,52,col,7)
	for i in 6:
		var yy:=610-i*48
		draw_rect(Rect2(245+i*5,yy,230-i*10,28),Color(col.r,col.g,col.b,0.20+0.06*i))
	_text("BEST FLOOR %d" % tower_best,Vector2(360,680),26,col,true)
	_text("Current start: Floor %d" % maxi(1,tower_best),Vector2(360,718),17,Color.WHITE,true)
	_text("Every 5 floors grants Shards · every 10 floors is a boss.",Vector2(360,770),14,Color("#b4afba"),true)
	_small_button(Rect2(160,890,400,78),"ENTER ENDLESS TOWER",Color("#496c96"))
	_text("Unlock Stage 15",Vector2(360,1018),14,Color("#92909a"),true)

func _draw_trials_panel() -> void:
	_text("DAILY TRIALS",Vector2(360,278),30,Color("#ffd0aa"),true)
	var tr: Dictionary=D.TRIALS[trial_index]
	var col:=Color(str(tr["color"]))
	_small_button(Rect2(84,430,62,54),"◀",Color("#4b4650"))
	_small_button(Rect2(574,430,62,54),"▶",Color("#4b4650"))
	draw_circle(Vector2(360,520),105,Color(col.r,col.g,col.b,0.12))
	_star(Vector2(360,520),58,col)
	_text(str(tr["name"]),Vector2(360,664),26,col,true)
	_text("%s focus · Reward: %s" % [tr["stat"],tr["reward"]],Vector2(360,704),16,Color("#d9d3dd"),true)
	_text("35 seconds · defeat as many echoes as possible.",Vector2(360,756),14,Color("#aba5b0"),true)
	_small_button(Rect2(160,890,400,78),"START TRIAL",Color("#7a5c68"))

func _draw_talents_panel() -> void:
	_text("COLOSSUS TALENT GRID",Vector2(360,268),28,Color("#d4b0ff"),true)
	_text("Talent Points %d" % talent_points,Vector2(360,302),16,Color("#fff0a0"),true)
	for i in 12:
		var col:=i%3
		var row:=int(i/3)
		var rr:=Rect2(64+col*199,390+row*118,184,98)
		var t: Dictionary=D.TALENTS[i]
		var branch_col: Color = Color("#d97669")
		match str(t["branch"]):
			"Guard": branch_col = Color("#73bb8b")
			"Fortune": branch_col = Color("#d5b660")
			"Spirit": branch_col = Color("#9577ca")
		_panel(rr,Color("#242329"),branch_col,15,2)
		_text(str(t["name"]),rr.position+Vector2(92,25),13,Color.WHITE,true)
		_text("%d/%d" % [talent_levels[i],t["max"]],rr.position+Vector2(92,48),13,Color("#ddd6e3"),true)
		_text(str(t["desc"]),rr.position+Vector2(92,73),10,Color("#a8a1ad"),true)
	# artifact strip
	_text("ARTIFACTS",Vector2(360,862),16,Color("#e4d3ff"),true)
	for i in 8:
		var pp:=Vector2(101+i*72,916)
		var art: Dictionary=D.ARTIFACTS[i]
		var unlocked:=stage>=int(art["unlock"])
		draw_circle(pp,27,Color(str(art["color"])) if unlocked else Color("#45434b"))
		_diamond(pp,11,Color("#25232a"))
		if i==active_artifact: draw_arc(pp,34,0,TAU,28,Color.WHITE,3)
		_text(str(artifact_levels[i]),pp+Vector2(0,48),11,Color.WHITE,true)
	_small_button(Rect2(230,970,260,62),"UPGRADE ARTIFACT",Color("#69517e"))

func _draw_style_panel() -> void:
	_text("SKINS & TITLES",Vector2(360,270),29,Color("#ffb6dd"),true)
	for i in 8:
		var col:=i%4
		var row:=int(i/4)
		var rr:=Rect2(66+col*148,382+row*190,132,164)
		var sk: Dictionary=D.SKINS[i]
		var owned:=bool(owned_skins[i])
		_panel(rr,Color("#232229"),Color(str(sk["accent"])) if owned else Color("#55515a"),18,2)
		draw_circle(rr.position+Vector2(66,61),39,Color(str(sk["color"])) if owned else Color("#4b4850"))
		_leaf(rr.position+Vector2(72,28),Color(str(sk["accent"])) if owned else Color("#67636a"))
		_text(str(sk["name"]),rr.position+Vector2(66,117),12,Color.WHITE,true)
		if i==selected_skin: _text("EQUIPPED",rr.position+Vector2(66,143),10,Color("#9dffae"),true)
		elif owned: _text("TAP EQUIP",rr.position+Vector2(66,143),10,Color("#c9c2ce"),true)
		else: _text("S%d · %d♦" % [sk["unlock"],sk["gems"]],rr.position+Vector2(66,143),10,Color("#d4b4c8"),true)
	var title: Dictionary = D.TITLES[min(selected_title,_unlocked_title_count()-1)]
	_small_button(Rect2(170,810,380,72),"TITLE · %s" % title["name"],Color("#5d4d70"))
	_small_button(Rect2(170,900,380,64),"CLAIM ACHIEVEMENTS (%d)" % _achievement_ready_count(),Color("#4f6f5a"))
	_text("Skins change your battle palette. Titles unlock through Stage progress.",Vector2(360,1010),13,Color("#aaa3ae"),true)

func _draw_forge_panel() -> void:
	var forge_surface := _get_ultra_ui_surface(3)
	if forge_surface != null:
		draw_texture_rect(forge_surface,Rect2(48,300,624,730),false,Color(1,1,1,0.32))
	_text("MYTHIC FORGE",Vector2(360,278),30,Color("#ffd9a3"),true)
	_text(D.FORGE_TITLES[mini(D.FORGE_TITLES.size()-1,int(forge_level/5))],Vector2(360,310),15,Color("#c7b4a1"),true)
	_currency(Vector2(275,347),"F",forge_stones,Color("#ffb976"))
	_currency(Vector2(424,347),"S",shards,Color("#c499ff"))
	_panel(Rect2(80,390,560,360),Color("#242229"),Color("#8d775e"),24,2)
	_small_button(Rect2(64,414,72,58),"◀",Color("#4e4752"))
	_small_button(Rect2(584,414,72,58),"▶",Color("#4e4752"))
	_text(D.SLOTS[forge_slot],Vector2(360,446),20,Color("#d8c8b7"),true)
	var item: Dictionary = equipped[forge_slot]
	if item.is_empty():
		_text("EMPTY SLOT",Vector2(360,575),26,Color("#77717a"),true)
		_text("Equip an item before forging.",Vector2(360,615),16,Color("#9b949d"),true)
	else:
		var rc := _rarity_color(int(item.get("rarity",0)))
		for rr in [94.0,73.0,53.0]:
			draw_arc(Vector2(360,570),rr,time_alive*0.45+rr,time_alive*0.45+rr+TAU*0.72,40,Color(rc.r,rc.g,rc.b,0.22),4)
		_draw_item_icon(Vector2(360,570),forge_slot,rc)
		_text(str(item.get("name","")),Vector2(360,690),20,rc,true)
		_text("+%d  •  Power %s" % [int(item.get("level",0)),_short_num(int(item.get("power",0)))],Vector2(360,720),16,Color.WHITE,true)
		if bool(item.get("awakened",false)):
			_text("AWAKENED",Vector2(360,748),15,Color("#fff09d"),true)
	_small_button(Rect2(64,930,180,66),"ENHANCE",Color("#7a5b3b"))
	_small_button(Rect2(270,930,180,66),"REROLL",Color("#4b657d"))
	_small_button(Rect2(476,930,180,66),"AWAKEN",Color("#74507c"))
	_text("Enhance raises raw power · Reroll changes affixes · Awaken unlocks at Epic+ +5",Vector2(360,1028),13,Color("#aaa2ad"),true)

func _draw_dungeon_panel() -> void:
	_text("RIFT DUNGEONS",Vector2(360,278),30,Color("#a9c7ff"),true)
	_text("Keys %d  •  Boss Rush Best %d" % [dungeon_keys,boss_rush_best],Vector2(360,314),16,Color("#d5deef"),true)
	var dd: Dictionary = D.DUNGEONS[dungeon_index]
	var col := Color(str(dd["color"]))
	_panel(Rect2(70,386,580,390),Color("#20232b"),col,26,3)
	_small_button(Rect2(62,448,72,58),"◀",Color("#414a5a"))
	_small_button(Rect2(586,448,72,58),"▶",Color("#414a5a"))
	draw_circle(Vector2(360,515),92,Color(col.r,col.g,col.b,0.12))
	draw_arc(Vector2(360,515),82,time_alive*0.5,time_alive*0.5+TAU*0.75,44,col,6)
	_diamond(Vector2(360,515),42,col.lightened(0.2))
	_text(str(dd["name"]),Vector2(360,642),25,col,true)
	_text("Unlock Stage %d  •  5 Rooms" % int(dd["unlock"]),Vector2(360,676),16,Color("#c8cbd3"),true)
	_text("Reward %sG + %d Shards + Forge Stones" % [_short_num(int(dd["gold"])),int(dd["shards"])],Vector2(360,709),14,Color("#ffe7a1"),true)
	_small_button(Rect2(88,900,250,72),"ENTER DUNGEON",Color("#456c8f"))
	_small_button(Rect2(382,900,250,72),"BOSS RUSH 30s",Color("#7c4e59"))
	_text("Boss Rush unlocks at Stage 20 and scales every kill.",Vector2(360,1024),14,Color("#9e9aa4"),true)

func _draw_garden_panel() -> void:
	_text("EXPEDITION GARDEN",Vector2(360,278),30,Color("#a8eba3"),true)
	_text("Garden Lv.%d  •  XP %d/%d" % [garden_level,garden_xp,garden_level*25],Vector2(360,314),16,Color("#d5ead1"),true)
	var now := int(Time.get_unix_time_from_system())
	for i in 3:
		var rect := Rect2(72+i*196,560,170,230)
		var crop: Dictionary = _garden_crop(i)
		var col := Color(str(crop["color"]))
		_panel(rect,Color("#242920"),col,20,2)
		draw_ellipse_custom(rect.position+Vector2(85,148),62,18,Color("#5d4933"))
		var planted := int(garden_plots[i])
		if planted <= 0:
			_leaf(rect.position+Vector2(85,118),col)
			_text("EMPTY",rect.position+Vector2(85,60),16,Color("#aaa6a7"),true)
			_text("Tap to plant",rect.position+Vector2(85,202),13,Color.WHITE,true)
		else:
			var elapsed := now-planted
			var ratio := clampf(float(elapsed)/float(crop["time"]),0.0,1.0)
			var growth := 0.55+ratio*0.75
			draw_line(rect.position+Vector2(85,148),rect.position+Vector2(85,105),Color("#4f9e5d"),6)
			_leaf(rect.position+Vector2(73,118),col)
			_leaf(rect.position+Vector2(97,105),col.lightened(0.08))
			draw_circle(rect.position+Vector2(85,87),18*growth,col)
			_text(str(crop["name"]),rect.position+Vector2(85,46),15,col,true)
			if ratio>=1.0:
				_text("HARVEST!",rect.position+Vector2(85,202),14,Color("#fff19e"),true)
			else:
				_text("%ds" % maxi(0,int(crop["time"])-elapsed),rect.position+Vector2(85,202),14,Color.WHITE,true)
	_small_button(Rect2(210,900,300,70),"UPGRADE GARDEN",Color("#4f7651"))
	_text("Higher garden levels multiply harvest gold and unlock richer crops.",Vector2(360,1020),14,Color("#9fa89e"),true)

func _draw_evolution_panel() -> void:
	_text("EVOLUTION PATH",Vector2(360,278),30,Color("#e0b0ff"),true)
	var current: Dictionary = D.EVOLUTIONS[evolution_tier]
	var col := Color(str(current["color"]))
	draw_circle(Vector2(360,492),118,Color(col.r,col.g,col.b,0.12))
	for ring in [104.0,82.0,61.0]:
		draw_arc(Vector2(360,492),ring,time_alive*(0.35+ring/400.0),time_alive*(0.35+ring/400.0)+TAU*0.72,42,Color(col.r,col.g,col.b,0.38),4)
	_draw_avatar(Vector2(360,492))
	_text(str(current["name"]),Vector2(360,640),27,col,true)
	_text("Adventure Rank: %s" % D.ADVENTURE_RANKS[_adventure_rank_index()],Vector2(360,676),17,Color("#ffe5a3"),true)
	if evolution_tier < D.EVOLUTIONS.size()-1:
		var next: Dictionary = D.EVOLUTIONS[evolution_tier+1]
		_text("NEXT: %s" % next["name"],Vector2(360,746),20,Color(str(next["color"])),true)
		_text("Player Lv.%d   Stage %d   Core Lv.%d" % [next["level"],next["stage"],next["core"]],Vector2(360,784),16,Color("#d1cad7"),true)
		_text("Your progress: Lv.%d   Stage %d   Core %d" % [player_level,stage,core_level],Vector2(360,816),14,Color("#9f98a5"),true)
		_small_button(Rect2(185,900,350,76),"EVOLVE · %d GEMS" % (5+evolution_tier*4),Color("#76508a"))
	else:
		_text("FINAL EVOLUTION ACHIEVED",Vector2(360,788),22,Color("#fff0a2"),true)
	_text("Each evolution permanently boosts Power and HP and changes your aura.",Vector2(360,1018),14,Color("#a9a1ad"),true)

func _draw_rarity_cutscene() -> void:
	var a := clampf(rarity_cutscene/1.75,0.0,1.0)
	var col := rarity_cutscene_color
	if visual_overkill_fields.size() > 0:
		var field_idx := int(abs(hash(rarity_cutscene_name))) % visual_overkill_fields.size()
		draw_texture_rect(visual_overkill_fields[field_idx],Rect2(-100,120,920,920),false,Color(col.r,col.g,col.b,0.11*a))
	if loot_beams.size() > 0:
		var beam_idx := 1 if rarity_cutscene_name in ["Divine","Celestial","Void","Apex","Origin","Beyond","Singularity"] else 0
		draw_texture_rect(loot_beams[beam_idx],Rect2(120,0,480,1080),false,Color(col.r,col.g,col.b,0.28*a))
	draw_rect(Rect2(0,0,W,H),Color(0.02,0.01,0.04,0.38*a))
	for i in 5:
		var rad := 80.0+i*48.0+(1.0-a)*90.0
		draw_arc(Vector2(360,610),rad,time_alive*(0.35+i*0.08),time_alive*(0.35+i*0.08)+TAU*0.72,64,Color(col.r,col.g,col.b,0.20*a),5)
	_star(Vector2(360,610),46+sin(time_alive*5.0)*6.0,col)
	_text(rarity_cutscene_name.to_upper(),Vector2(360,735),34,Color(col.r,col.g,col.b,a),true)
	_text("MYTHIC DISCOVERY",Vector2(360,774),16,Color(1,1,1,0.8*a),true)

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
