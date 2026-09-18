extends RefCounted

const RARITIES := [
	"Common","Uncommon","Rare","Superior","Elite","Epic","Heroic","Legendary","Mythic","Ancient",
	"Relic","Sacred","Arcane","Enchanted","Runic","Royal","Imperial","Ascended","Exalted","Divine",
	"Celestial","Ethereal","Astral","Stellar","Lunar","Solar","Cosmic","Galactic","Nebula","Supernova",
	"Void","Abyssal","Chaotic","Primordial","Genesis","Transcendent","Eternal","Infinite","Sovereign","Apex",
	"Omega","Paragon","Absolute","Immortal","Reality","Multiversal","Omniversal","Origin","Beyond","Singularity"
]

const SLOTS := ["Weapon","Armor","Helm","Boots","Charm","Relic"]
const ITEM_BASES := [
	["Twigblade","Sunblade","Moonfang","Verdant Edge","Star Needle","Cloud Saber","Bloom Scythe","Dawn Pike"],
	["Leafguard","Moss Mail","Petal Coat","Barkplate","Moonweave","Star Mantle","Thorn Vest","Dewplate"],
	["Acorn Crown","Leaf Hood","Sun Helm","Bloom Cap","Moon Circlet","Starcrest","Moss Mask","Cloud Tiara"],
	["Rootwalkers","Petal Boots","Dewsteps","Moon Treads","Sunstride","Cloud Shoes","Thorn Greaves","Starsteps"],
	["Dew Charm","Acorn Sigil","Bloom Ring","Moonbell","Sun Crest","Dream Knot","Wildheart","Sky Pendant"],
	["Seed Idol","Forest Rune","Sky Totem","Astral Seed","Void Bloom","Origin Stone","Dream Core","Worldroot"]
]

const BIOMES := [
	{"name":"Emerald Meadow","sky":"#9ee8ff","far":"#b8d98b","near":"#69b85b","ground":"#efd58e","accent":"#76e06b","weather":"petals"},
	{"name":"Amber Grove","sky":"#ffd7a8","far":"#d9a56e","near":"#9c7a45","ground":"#c98e52","accent":"#ffd35a","weather":"leaves"},
	{"name":"Moonlit Marsh","sky":"#6f86cb","far":"#6b7394","near":"#3f6a68","ground":"#50665d","accent":"#8cf3e2","weather":"fireflies"},
	{"name":"Crystal Cavern","sky":"#5a659e","far":"#7b68a7","near":"#4e4876","ground":"#4f506f","accent":"#a0f2ff","weather":"crystals"},
	{"name":"Sunken Ruins","sky":"#79c5c8","far":"#7caa91","near":"#547f70","ground":"#b3a57e","accent":"#87ffe0","weather":"bubbles"},
	{"name":"Frostpine","sky":"#c7e9ff","far":"#b9d0d9","near":"#7394a3","ground":"#e6f2f5","accent":"#9feaff","weather":"snow"},
	{"name":"Ashen Ridge","sky":"#b06f67","far":"#8b625c","near":"#634744","ground":"#7a5a4f","accent":"#ff8c66","weather":"embers"},
	{"name":"Astral Garden","sky":"#55508e","far":"#7064a7","near":"#4d557e","ground":"#75689d","accent":"#e692ff","weather":"stars"}
]

const ENEMIES := [
	{"name":"Wild Puff","color":"#d36f7d","shape":"puff","speed":1.0,"hp":1.0,"atk":1.0},
	{"name":"Moss Boar","color":"#6d9250","shape":"boar","speed":0.82,"hp":1.3,"atk":1.15},
	{"name":"Petal Wisp","color":"#c77fcf","shape":"wisp","speed":1.3,"hp":0.82,"atk":1.05},
	{"name":"Stonebud","color":"#82909b","shape":"golem","speed":0.72,"hp":1.55,"atk":1.2},
	{"name":"Frostling","color":"#82cbe0","shape":"puff","speed":1.05,"hp":1.12,"atk":1.22},
	{"name":"Ash Imp","color":"#df795b","shape":"wisp","speed":1.22,"hp":0.95,"atk":1.35}
]

const BOSSES := [
	{"name":"Thorn King","color":"#6c9d52"},
	{"name":"Moon Maw","color":"#7976bd"},
	{"name":"Crystal Behemoth","color":"#6cd0df"},
	{"name":"Ashen Warden","color":"#d46d52"},
	{"name":"Astral Regent","color":"#c579e0"}
]

const AFFIXES := [
	{"name":"Power","key":"power","min":4.0,"max":16.0},
	{"name":"Vitality","key":"hp","min":3.0,"max":14.0},
	{"name":"Critical","key":"crit","min":0.3,"max":2.2},
	{"name":"Haste","key":"haste","min":0.3,"max":2.0},
	{"name":"Dodge","key":"dodge","min":0.2,"max":1.5},
	{"name":"Leech","key":"leech","min":0.15,"max":1.1}
]

const SETS := ["Verdant","Solar","Lunar","Astral","Wildheart","Dreamer","Voidborn","Origin"]

const SKILLS := [
	{"name":"Leaf Burst","color":"#79ed69","unlock":1,"cd":4.6,"mult":2.2},
	{"name":"Starfall","color":"#91d9ff","unlock":7,"cd":7.2,"mult":3.6},
	{"name":"Bloom Guard","color":"#ffdc75","unlock":14,"cd":10.0,"mult":0.0}
]

const PETS := [
	{"name":"Pip","unlock":3,"color":"#ffd36b","bonus":"Gold"},
	{"name":"Misty","unlock":8,"color":"#86e8ef","bonus":"Haste"},
	{"name":"Rook","unlock":16,"color":"#d095ff","bonus":"Crit"},
	{"name":"Ember","unlock":25,"color":"#ff8b69","bonus":"Damage"},
	{"name":"Nova","unlock":40,"color":"#ffb6f2","bonus":"Luck"}
]
