extends Node2D

const W := 720.0
const H := 1280.0
const SAVE_PATH := "user://relic_v03_save.json"

const RARITIES := [
	"Common","Uncommon","Rare","Superior","Elite","Epic","Heroic","Legendary","Mythic","Ancient",
	"Relic","Sacred","Arcane","Enchanted","Runic","Royal","Imperial","Ascended","Exalted","Divine",
	"Celestial","Ethereal","Astral","Stellar","Lunar","Solar","Cosmic","Galactic","Nebula","Supernova",
	"Void","Abyssal","Chaotic","Primordial","Genesis","Transcendent","Eternal","Infinite","Sovereign","Apex",
	"Omega","Paragon","Absolute","Immortal","Reality","Multiversal","Omniversal","Origin","Beyond","Singularity"
]
const SLOT_NAMES := ["Weapon","Armor","Charm","Relic"]
const ITEM_BASES := [
	["Twigblade","Sunblade","Moonfang","Verdant Edge","Star Needle","Cloud Saber"],
	["Leafguard","Moss Mail","Petal Coat","Barkplate","Moonweave","Star Mantle"],
	["Dew Charm","Acorn Sigil","Bloom Ring","Moonbell","Sun Crest","Dream Knot"],
	["Seed Idol","Forest Rune","Sky Totem","Astral Seed","Void Bloom","Origin Stone"]
]

var font: Font
var rng := RandomNumberGenerator.new()

var gold := 560
var essence := 36
var gems := 8
var stage := 1
var stage_kills := 0
var total_kills := 0

var core_level := 1
var luck_level := 1
var quality_level := 1
var pity := 0
var hard_pity := 28
var auto_roll := false

var hero_power := 42.0
var hero_hp := 120.0
var hero_hp_max := 120.0
var enemy_hp := 86.0
var enemy_hp_max := 86.0

var battle_timer := 0.0
var enemy_timer := 0.0
var auto_roll_timer := 0.0
var time_alive := 0.0
var hit_flash := 0.0
var enemy_hit_flash := 0.0
var loot_flash := 0.0
var shake := 0.0
var toast := ""
var toast_timer := 0.0

var current_item: Dictionary = {}
var equipped := [{},{},{},{}]
var active_tab := 2
var panel_open := false

var damage_numbers: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var particles: Array[Dictionary] = []

func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	_load_save()
	_reset_enemy()
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	time_alive += delta
	battle_timer += delta
	enemy_timer += delta
	hit_flash = maxf(0.0, hit_flash - delta * 5.0)
	enemy_hit_flash = maxf(0.0, enemy_hit_flash - delta * 5.0)
	loot_flash = maxf(0.0, loot_flash - delta * 2.4)
	shake = maxf(0.0, shake - delta * 18.0)
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast = ""

	if battle_timer >= 0.78:
		battle_timer = 0.0
		_hero_attack()
	if enemy_timer >= 1.55:
		enemy_timer = 0.0
		_enemy_attack()

	if auto_roll:
		auto_roll_timer += delta
		if auto_roll_timer >= maxf(0.45, 1.15 - float(core_level) * 0.004):
			auto_roll_timer = 0.0
			if current_item.is_empty():
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
		if Rect2(92, 890, 250, 74).has_point(p):
			_equip_current()
			return
		if Rect2(378, 890, 250, 74).has_point(p):
			_sell_current()
			return

	if Rect2(238, 828, 244, 214).has_point(p):
		_roll_loot()
		return
	if Rect2(42, 932, 150, 62).has_point(p):
		_upgrade_core()
		return
	if Rect2(528, 932, 150, 62).has_point(p):
		auto_roll = not auto_roll
		_show_toast("Auto Draw %s" % ("ON" if auto_roll else "OFF"))
		return

	if p.y >= 1176.0:
		active_tab = clampi(int(p.x / 144.0), 0, 4)
		panel_open = active_tab != 2
		_show_toast(["Gear","Skills","Core","Companions","Quests"][active_tab])
		return

	if panel_open and Rect2(40, 722, 640, 410).has_point(p):
		panel_open = false
		active_tab = 2

func _hero_attack() -> void:
	var crit_chance := 0.11 + float(quality_level) * 0.002
	var crit := rng.randf() < crit_chance
	var dmg := hero_power * rng.randf_range(0.88, 1.14) * (1.75 if crit else 1.0)
	enemy_hp -= dmg
	projectiles.append({
		"from": Vector2(238, 575),
		"to": Vector2(500, 550),
		"t": 0.0,
		"life": 0.28,
		"color": Color(0.65, 1.0, 0.32)
	})
	damage_numbers.append({
		"pos": Vector2(510 + rng.randf_range(-22,22), 505),
		"text": ("%d!" % int(dmg)) if crit else ("%d" % int(dmg)),
		"life": 0.9,
		"crit": crit
	})
	enemy_hit_flash = 1.0
	shake = 5.0 if crit else 2.0
	if enemy_hp <= 0.0:
		_on_enemy_defeated()

func _enemy_attack() -> void:
	if enemy_hp <= 0.0:
		return
	var dmg := maxf(3.0, enemy_hp_max * 0.055)
	hero_hp -= dmg
	hit_flash = 1.0
	damage_numbers.append({
		"pos": Vector2(230, 500),
		"text": "-%d" % int(dmg),
		"life": 0.75,
		"crit": false
	})
	if hero_hp <= 0.0:
		hero_hp = hero_hp_max
		_show_toast("Recovered at camp")

func _on_enemy_defeated() -> void:
	total_kills += 1
	stage_kills += 1
	gold += 18 + stage * 4
	essence += 1 + int(stage / 4)
	for i in 10:
		particles.append({
			"pos": Vector2(500, 550),
			"vel": Vector2(rng.randf_range(-120,120), rng.randf_range(-180,-60)),
			"life": rng.randf_range(0.45,0.85),
			"color": Color.from_hsv(rng.randf(),0.55,1.0)
		})
	if stage_kills >= 8:
		stage += 1
		stage_kills = 0
		_show_toast("Stage %d!" % stage)
	_reset_enemy()
	_save()

func _reset_enemy() -> void:
	enemy_hp_max = 72.0 + pow(float(stage), 1.34) * 17.0
	enemy_hp = enemy_hp_max

func _roll_loot() -> void:
	if essence <= 0:
		_show_toast("Need more Core Energy")
		auto_roll = false
		return
	essence -= 1
	pity += 1
	var rarity := _roll_rarity()
	var slot := rng.randi_range(0,3)
	var q := 0.88 + rng.randf() * 0.28 + float(quality_level) * 0.008
	var mult := pow(1.34, float(rarity))
	var power := int((24.0 + float(core_level) * 3.8 + float(stage) * 1.9) * mult * q)
	var base_name: String = ITEM_BASES[slot][rng.randi_range(0, ITEM_BASES[slot].size()-1)]
	current_item = {
		"rarity": rarity,
		"slot": slot,
		"name": "%s %s" % [RARITIES[rarity], base_name],
		"power": power,
		"crit": snappedf(rng.randf_range(0.4, 2.4) + rarity * 0.11, 0.1),
		"haste": snappedf(rng.randf_range(0.2, 1.8) + rarity * 0.07, 0.1)
	}
	loot_flash = 1.0
	for i in 14:
		particles.append({
			"pos": Vector2(360, 910),
			"vel": Vector2(rng.randf_range(-150,150), rng.randf_range(-220,-65)),
			"life": rng.randf_range(0.5,1.0),
			"color": _rarity_color(rarity)
		})
	_save()

func _roll_rarity() -> int:
	var max_rarity := mini(49, 5 + int(core_level / 2))
	if pity >= hard_pity:
		pity = 0
		return mini(max_rarity, maxi(5, int(max_rarity * 0.72)))
	var weights: Array[float] = []
	var total := 0.0
	for i in max_rarity + 1:
		var w := pow(0.53, float(i))
		w *= 1.0 + float(luck_level) * 0.012 * float(i)
		if pity >= 10 and i >= 4:
			w *= 1.0 + float(pity - 9) * 0.08
		weights.append(w)
		total += w
	var r := rng.randf() * total
	var acc := 0.0
	for i in weights.size():
		acc += weights[i]
		if r <= acc:
			if i >= 6:
				pity = 0
			return i
	return 0

func _equip_current() -> void:
	if current_item.is_empty():
		return
	var slot := int(current_item["slot"])
	var old_power := 0
	if not equipped[slot].is_empty():
		old_power = int(equipped[slot].get("power",0))
	if int(current_item["power"]) >= old_power:
		equipped[slot] = current_item.duplicate(true)
		_recalc_power()
		_show_toast("Equipped!")
	else:
		_show_toast("Lower power — sold")
		gold += maxi(5, int(current_item["power"]) / 8)
	current_item = {}
	_save()

func _sell_current() -> void:
	if current_item.is_empty():
		return
	gold += maxi(6, int(current_item["power"]) / 7)
	_show_toast("+%d Gold" % maxi(6, int(current_item["power"]) / 7))
	current_item = {}
	_save()

func _upgrade_core() -> void:
	var cost := _core_cost()
	if gold < cost:
		_show_toast("Need %d Gold" % cost)
		return
	gold -= cost
	core_level += 1
	if core_level % 3 == 0:
		luck_level += 1
	if core_level % 5 == 0:
		quality_level += 1
	loot_flash = 1.0
	_show_toast("Core Lv.%d" % core_level)
	_save()

func _core_cost() -> int:
	return int(90.0 * pow(1.105, float(core_level - 1)))

func _recalc_power() -> void:
	var sum := 0
	for item in equipped:
		if not item.is_empty():
			sum += int(item.get("power",0))
	hero_power = 42.0 + float(stage) * 2.3 + float(sum) * 0.18
	hero_hp_max = 120.0 + float(sum) * 0.11
	hero_hp = minf(hero_hp, hero_hp_max)

func _update_fx(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		projectiles[i]["t"] = float(projectiles[i]["t"]) + delta
		if float(projectiles[i]["t"]) >= float(projectiles[i]["life"]):
			projectiles.remove_at(i)
	for i in range(damage_numbers.size()-1,-1,-1):
		damage_numbers[i]["life"] = float(damage_numbers[i]["life"]) - delta
		damage_numbers[i]["pos"].y -= 45.0 * delta
		if float(damage_numbers[i]["life"]) <= 0.0:
			damage_numbers.remove_at(i)
	for i in range(particles.size()-1,-1,-1):
		particles[i]["life"] = float(particles[i]["life"]) - delta
		particles[i]["pos"] += Vector2(particles[i]["vel"]) * delta
		particles[i]["vel"].y += 320.0 * delta
		if float(particles[i]["life"]) <= 0.0:
			particles.remove_at(i)

func _draw() -> void:
	_draw_background()
	_draw_top_hud()
	_draw_battlefield()
	_draw_core_zone()
	_draw_bottom_nav()
	_draw_fx()
	if panel_open:
		_draw_tab_panel()
	if not current_item.is_empty():
		_draw_loot_popup()
	if toast != "":
		_panel(Rect2(170, 1080, 380, 54), Color(0.06,0.07,0.08,0.92), Color(1,1,1,0.15), 18)
		_text(toast, Vector2(360,1115), 23, Color.WHITE, true)

func _draw_background() -> void:
	draw_rect(Rect2(0,0,W,H), Color("#b7e9ff"))
	for y in range(0, 420, 35):
		var t := float(y) / 420.0
		draw_rect(Rect2(0,y,W,38), Color(0.66 + t*0.08, 0.88 + t*0.04, 1.0, 1))
	draw_circle(Vector2(602,158), 74, Color(1.0,0.92,0.48,0.45))
	draw_colored_polygon(PackedVector2Array([Vector2(0,420),Vector2(145,260),Vector2(280,410),Vector2(410,238),Vector2(560,405),Vector2(720,285),Vector2(720,540),Vector2(0,540)]), Color("#9fcf8d"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,470),Vector2(120,355),Vector2(235,465),Vector2(360,330),Vector2(510,470),Vector2(650,350),Vector2(720,420),Vector2(720,580),Vector2(0,580)]), Color("#77b96f"))
	draw_rect(Rect2(0,520,W,280), Color("#69b85b"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,665),Vector2(720,615),Vector2(720,815),Vector2(0,815)]), Color("#e7c77d"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,705),Vector2(720,650),Vector2(720,815),Vector2(0,815)]), Color("#f2d997"))
	for x in [58,132,618,680]:
		_draw_mushroom(Vector2(x,510 + sin(x)*12), 0.8 if x < 200 else 1.05)
	for x in [32,91,168,552,625,700]:
		draw_circle(Vector2(x,615 + sin(x)*15), 20, Color("#3d944d"))
		draw_circle(Vector2(x+14,610 + sin(x)*15), 15, Color("#4aa75a"))

func _draw_top_hud() -> void:
	_panel(Rect2(18,18,684,148), Color(0.08,0.10,0.09,0.78), Color(1,1,1,0.14), 26)
	_draw_avatar(Vector2(72,70))
	_text("SPROUT", Vector2(118,61), 26, Color("#fff3c4"))
	_text("Power %d" % int(hero_power), Vector2(118,93), 20, Color("#c9ffd1"))
	_bar(Rect2(118,108,250,18), hero_hp/hero_hp_max, Color("#5be36f"), Color(0.12,0.16,0.13,0.8))
	_currency(Vector2(426,54), "G", gold, Color("#ffd653"))
	_currency(Vector2(426,100), "E", essence, Color("#9bf7ff"))
	_currency(Vector2(585,54), "♦", gems, Color("#ff79da"))
	_panel(Rect2(470,118,210,34), Color(0.05,0.06,0.06,0.5), Color(1,1,1,0.1), 14)
	_text("STAGE %d  •  %d/8" % [stage,stage_kills], Vector2(575,142), 19, Color.WHITE, true)

func _draw_battlefield() -> void:
	var bob := sin(time_alive*5.0)*5.0
	var enemy_bob := sin(time_alive*4.1+1.2)*4.0
	var shake_x := sin(time_alive*70.0)*shake
	_draw_hero(Vector2(215+shake_x,570+bob))
	_draw_enemy(Vector2(505-shake_x,565+enemy_bob))
	_bar(Rect2(425,430,205,22), enemy_hp/enemy_hp_max, Color("#ff5f68"), Color(0.18,0.08,0.08,0.72))
	_text("Wild Puff Lv.%d" % stage, Vector2(527,420), 20, Color("#3e2a20"), true)
	_text("AUTO BATTLE", Vector2(360,196), 18, Color(0.13,0.22,0.16,0.72), true)

func _draw_hero(pos: Vector2) -> void:
	var tint := Color.WHITE.lerp(Color("#ff877f"), hit_flash*0.45)
	draw_ellipse(pos+Vector2(0,40), Vector2(57,18), Color(0,0,0,0.15))
	draw_circle(pos+Vector2(0,8), 54, Color("#f4e5bc")*tint)
	draw_circle(pos+Vector2(-25,-2), 7, Color("#362c2b"))
	draw_circle(pos+Vector2(25,-2), 7, Color("#362c2b"))
	draw_arc(pos+Vector2(0,8), 19, 0.25, 2.9, 18, Color("#8b5943"), 4.0)
	draw_circle(pos+Vector2(0,-46), 52, Color("#66b95c"))
	draw_colored_polygon(PackedVector2Array([
		pos+Vector2(-50,-45),pos+Vector2(-15,-86),pos+Vector2(6,-55),pos+Vector2(42,-85),pos+Vector2(50,-43)
	]), Color("#4e9e47"))
	draw_circle(pos+Vector2(8,-77), 9, Color("#d8f06d"))
	draw_rect(Rect2(pos+Vector2(-43,48),Vector2(86,74)), Color("#4d8f55"))
	draw_circle(pos+Vector2(-35,84), 17, Color("#f1d29f"))
	draw_circle(pos+Vector2(35,84), 17, Color("#f1d29f"))
	var weapon_col := Color("#eaf8ff")
	if not equipped[0].is_empty():
		weapon_col = _rarity_color(int(equipped[0].get("rarity",0)))
	draw_line(pos+Vector2(46,48),pos+Vector2(94,0),weapon_col,10.0)
	draw_circle(pos+Vector2(95,-2), 10, weapon_col.lightened(0.25))

func _draw_enemy(pos: Vector2) -> void:
	var c := Color("#d36f7d").lerp(Color.WHITE, enemy_hit_flash*0.62)
	draw_ellipse(pos+Vector2(0,56),Vector2(66,18),Color(0,0,0,0.16))
	draw_circle(pos,64,c)
	draw_circle(pos+Vector2(-45,-43),27,c.darkened(0.08))
	draw_circle(pos+Vector2(45,-43),27,c.darkened(0.08))
	draw_circle(pos+Vector2(-21,-8),8,Color("#2d2530"))
	draw_circle(pos+Vector2(21,-8),8,Color("#2d2530"))
	draw_arc(pos+Vector2(0,10),22,0.25,2.9,18,Color("#6a3740"),4.0)
	draw_circle(pos+Vector2(0,42),16,Color("#f6c971"))

func _draw_core_zone() -> void:
	_panel(Rect2(18,806,684,342), Color("#2d241f"), Color("#8a674d"), 30)
	_text("RELIC CORE", Vector2(360,842), 24, Color("#ffe9b0"), true)
	var pulse := 1.0 + sin(time_alive*3.6)*0.03
	var core_pos := Vector2(360,928)
	draw_circle(core_pos,96*pulse,Color(0.35,0.73,1.0,0.12 + loot_flash*0.18))
	draw_circle(core_pos,72*pulse,Color("#d7b25e"))
	draw_circle(core_pos,58*pulse,Color("#604b8c"))
	draw_circle(core_pos,42*pulse,Color("#65e7ff").lerp(Color.WHITE,loot_flash*0.5))
	draw_colored_polygon(PackedVector2Array([
		core_pos+Vector2(-58,45),core_pos+Vector2(-34,82),core_pos+Vector2(34,82),core_pos+Vector2(58,45)
	]),Color("#7e5835"))
	_text("Lv.%d" % core_level, core_pos+Vector2(0,8), 24, Color.WHITE, true)
	_text("TAP", core_pos+Vector2(0,39), 18, Color("#20323b"), true)

	_panel(Rect2(42,932,150,62), Color("#6a4c2f"), Color("#e4c27d"), 18)
	_text("UPGRADE", Vector2(117,958), 17, Color.WHITE, true)
	_text("%d G" % _core_cost(), Vector2(117,982), 14, Color("#ffe292"), true)
	_panel(Rect2(528,932,150,62), Color("#273f38") if auto_roll else Color("#403a35"), Color("#7fe8c2") if auto_roll else Color("#8a7c70"), 18)
	_text("AUTO %s" % ("ON" if auto_roll else "OFF"), Vector2(603,969), 18, Color.WHITE, true)

	_text("Luck %d   Quality %d   Pity %d/%d" % [luck_level,quality_level,pity,hard_pity], Vector2(360,1080), 18, Color("#d8cbbd"), true)
	var max_r := mini(49,5+int(core_level/2))
	_text("Best unlocked: %s" % RARITIES[max_r], Vector2(360,1112), 17, _rarity_color(max_r), true)

func _draw_bottom_nav() -> void:
	draw_rect(Rect2(0,1158,W,122),Color("#211c19"))
	var labels := ["GEAR","SKILLS","CORE","PETS","QUESTS"]
	for i in 5:
		var x := 72.0 + i*144.0
		if i == active_tab:
			draw_circle(Vector2(x,1188),31,Color("#5a4734"))
		draw_circle(Vector2(x,1188),18,_nav_color(i))
		_text(labels[i],Vector2(x,1240),15,Color.WHITE,true)

func _draw_tab_panel() -> void:
	_panel(Rect2(40,722,640,410),Color(0.10,0.09,0.08,0.96),Color("#81664b"),26)
	_text(["GEAR","SKILLS","CORE","COMPANIONS","QUESTS"][active_tab],Vector2(360,768),28,Color("#ffe3aa"),true)
	if active_tab == 0:
		for i in 4:
			var y := 810 + i*66
			_panel(Rect2(82,y,556,52),Color("#28211c"),Color(1,1,1,0.1),14)
			var item: Dictionary = equipped[i]
			_text(SLOT_NAMES[i],Vector2(103,y+32),18,Color("#d6c2a8"))
			_text("Empty" if item.is_empty() else str(item.get("name","")),Vector2(240,y+32),17,Color("#ffffff"))
	elif active_tab == 1:
		_text("Auto Slash",Vector2(120,835),22,Color.WHITE)
		_text("Leaf Burst",Vector2(120,895),22,Color.WHITE)
		_text("Bloom Guard",Vector2(120,955),22,Color.WHITE)
		_text("More skill paths unlock with stages.",Vector2(120,1030),18,Color("#bfb4a6"))
	elif active_tab == 3:
		_text("Companions join your auto-battle.",Vector2(360,855),21,Color.WHITE,true)
		_text("First companion unlocks at Stage 5.",Vector2(360,910),18,Color("#bfb4a6"),true)
	elif active_tab == 4:
		_text("Defeat enemies",Vector2(120,840),21,Color.WHITE)
		_text("%d total defeated" % total_kills,Vector2(120,878),18,Color("#bfb4a6"))
		_text("Upgrade the Relic Core",Vector2(120,950),21,Color.WHITE)
		_text("Current level %d" % core_level,Vector2(120,988),18,Color("#bfb4a6"))
	_text("Tap panel to close",Vector2(360,1090),16,Color("#8f8378"),true)

func _draw_loot_popup() -> void:
	draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.42))
	var r := int(current_item.get("rarity",0))
	var col := _rarity_color(r)
	_panel(Rect2(54,420,612,570),Color("#251f1b"),col,30,4.0)
	_text("NEW EQUIPMENT",Vector2(360,468),18,Color("#cdbba7"),true)
	draw_circle(Vector2(360,580),88,Color(col.r,col.g,col.b,0.15))
	draw_circle(Vector2(360,580),62,Color("#493d34"))
	_draw_item_icon(Vector2(360,580),int(current_item.get("slot",0)),col)
	_text(str(current_item.get("name","")),Vector2(360,700),26,col,true)
	_text(SLOT_NAMES[int(current_item.get("slot",0))],Vector2(360,734),18,Color("#d7c7b6"),true)
	_text("Power  %d" % int(current_item.get("power",0)),Vector2(360,782),28,Color.WHITE,true)
	_text("Crit +%.1f%%     Haste +%.1f%%" % [float(current_item.get("crit",0.0)),float(current_item.get("haste",0.0))],Vector2(360,824),18,Color("#c7f5d8"),true)

	var slot := int(current_item.get("slot",0))
	var old := 0
	if not equipped[slot].is_empty():
		old = int(equipped[slot].get("power",0))
	var delta := int(current_item.get("power",0)) - old
	_text(("%+d vs equipped" % delta),Vector2(360,862),19,Color("#6df58b") if delta>=0 else Color("#ff8d8d"),true)

	_panel(Rect2(92,890,250,74),Color("#3c8f50"),Color("#8af0a2"),18)
	_text("EQUIP",Vector2(217,936),23,Color.WHITE,true)
	_panel(Rect2(378,890,250,74),Color("#65463d"),Color("#d69a84"),18)
	_text("SELL",Vector2(503,936),23,Color.WHITE,true)

func _draw_fx() -> void:
	for pr in projectiles:
		var t := clampf(float(pr["t"])/float(pr["life"]),0.0,1.0)
		var pos := Vector2(pr["from"]).lerp(Vector2(pr["to"]),t)
		draw_circle(pos,9,Color(pr["color"]))
		draw_circle(pos,18,Color(Color(pr["color"]).r,Color(pr["color"]).g,Color(pr["color"]).b,0.18))
	for d in damage_numbers:
		_text(str(d["text"]),Vector2(d["pos"]),27 if bool(d["crit"]) else 22,Color("#fff06b") if bool(d["crit"]) else Color.WHITE,true)
	for pt in particles:
		draw_circle(Vector2(pt["pos"]),5,Color(pt["color"]))

func _draw_mushroom(pos: Vector2, scale: float) -> void:
	draw_rect(Rect2(pos+Vector2(-8,-2)*scale,Vector2(16,34)*scale),Color("#e8d7b6"))
	draw_circle(pos+Vector2(0,-6)*scale,27*scale,Color("#c36b6d"))
	draw_circle(pos+Vector2(-10,-14)*scale,5*scale,Color("#f4d9be"))
	draw_circle(pos+Vector2(9,-4)*scale,4*scale,Color("#f4d9be"))

func _draw_avatar(pos: Vector2) -> void:
	draw_circle(pos,38,Color("#5db65c"))
	draw_circle(pos+Vector2(0,10),25,Color("#efd9aa"))
	draw_circle(pos+Vector2(-9,6),4,Color("#2a2927"))
	draw_circle(pos+Vector2(9,6),4,Color("#2a2927"))

func _draw_item_icon(pos: Vector2, slot: int, color: Color) -> void:
	if slot == 0:
		draw_line(pos+Vector2(-28,35),pos+Vector2(30,-35),color,16.0)
		draw_line(pos+Vector2(-30,16),pos+Vector2(-7,38),Color("#c49a5a"),9.0)
	elif slot == 1:
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-38,-36),pos+Vector2(38,-36),pos+Vector2(27,40),pos+Vector2(-27,40)]),color)
	elif slot == 2:
		draw_circle(pos,36,color)
		draw_circle(pos,22,Color("#493d34"))
	else:
		draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-44),pos+Vector2(36,0),pos+Vector2(0,44),pos+Vector2(-36,0)]),color)

func _currency(pos: Vector2, mark: String, value: int, color: Color) -> void:
	draw_circle(pos,17,color)
	_text(mark,pos+Vector2(0,6),14,Color("#30271f"),true)
	_text(_short_num(value),pos+Vector2(29,7),18,Color.WHITE)

func _bar(rect: Rect2, ratio: float, color: Color, bg: Color) -> void:
	_panel(rect,bg,Color(1,1,1,0.08),rect.size.y*0.5)
	var inner := rect.grow(-3)
	inner.size.x *= clampf(ratio,0.0,1.0)
	draw_rect(inner,color)

func _panel(rect: Rect2, fill: Color, border: Color, radius: float, border_width: float = 2.0) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(int(border_width))
	box.corner_radius_top_left = int(radius)
	box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius)
	box.corner_radius_bottom_right = int(radius)
	draw_style_box(box,rect)

func _text(text: String, pos: Vector2, size: int, color: Color = Color.WHITE, centered: bool = false) -> void:
	if font == null:
		return
	var p := pos
	if centered:
		var s := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size)
		p.x -= s.x*0.5
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * float(i) / 32.0
		pts.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(pts,color)

func _rarity_color(index: int) -> Color:
	if index <= 0:
		return Color("#c7c7c7")
	var hue := fmod(0.56 + float(index)*0.071,1.0)
	var sat := clampf(0.50 + float(index)*0.007,0.5,0.88)
	var val := clampf(0.82 + float(index)*0.004,0.82,1.0)
	return Color.from_hsv(hue,sat,val)

func _nav_color(i: int) -> Color:
	return [Color("#d5b067"),Color("#e88e6b"),Color("#70d7e8"),Color("#87d27d"),Color("#d49be2")][i]

func _show_toast(t: String) -> void:
	toast = t
	toast_timer = 1.7

func _short_num(v: int) -> String:
	if v >= 1000000000:
		return "%.1fB" % (float(v)/1000000000.0)
	if v >= 1000000:
		return "%.1fM" % (float(v)/1000000.0)
	if v >= 1000:
		return "%.1fK" % (float(v)/1000.0)
	return str(v)

func _save() -> void:
	var data := {
		"gold":gold,"essence":essence,"gems":gems,"stage":stage,"stage_kills":stage_kills,
		"total_kills":total_kills,"core_level":core_level,"luck_level":luck_level,
		"quality_level":quality_level,"pity":pity,"equipped":equipped
	}
	var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	gold = int(parsed.get("gold",gold))
	essence = int(parsed.get("essence",essence))
	gems = int(parsed.get("gems",gems))
	stage = int(parsed.get("stage",stage))
	stage_kills = int(parsed.get("stage_kills",stage_kills))
	total_kills = int(parsed.get("total_kills",total_kills))
	core_level = int(parsed.get("core_level",core_level))
	luck_level = int(parsed.get("luck_level",luck_level))
	quality_level = int(parsed.get("quality_level",quality_level))
	pity = int(parsed.get("pity",pity))
	var eq = parsed.get("equipped",[])
	if eq is Array and eq.size() == 4:
		equipped = eq
	_recalc_power()
