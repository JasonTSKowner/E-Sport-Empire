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


const EVOLUTIONS := [
	{"name":"Sproutling","level":1,"stage":1,"core":1,"color":"#77d36a"},
	{"name":"Bloom Scout","level":8,"stage":8,"core":5,"color":"#7ce7a0"},
	{"name":"Verdant Ranger","level":16,"stage":18,"core":12,"color":"#7bd7ff"},
	{"name":"Astral Warden","level":28,"stage":35,"core":22,"color":"#b09cff"},
	{"name":"Solar Herald","level":42,"stage":55,"core":35,"color":"#ffd66f"},
	{"name":"Void Keeper","level":60,"stage":80,"core":50,"color":"#d384ff"},
	{"name":"Origin Sage","level":82,"stage":110,"core":70,"color":"#ff9bdc"},
	{"name":"Mythic Wildbound","level":110,"stage":150,"core":95,"color":"#fff1a8"}
]

const DUNGEONS := [
	{"name":"Root Vault","unlock":12,"color":"#76d477","hp_mult":2.0,"gold":700,"shards":4},
	{"name":"Moon Hollow","unlock":25,"color":"#8ea0ff","hp_mult":3.0,"gold":1600,"shards":8},
	{"name":"Crystal Depths","unlock":40,"color":"#78edff","hp_mult":4.3,"gold":3400,"shards":14},
	{"name":"Ash Citadel","unlock":65,"color":"#ff8a6d","hp_mult":6.0,"gold":7200,"shards":22},
	{"name":"Astral Rift","unlock":95,"color":"#e58cff","hp_mult":8.5,"gold":15000,"shards":35}
]

const CROPS := [
	{"name":"Sunberry","time":45,"gold":160,"energy":1,"color":"#ffd75d"},
	{"name":"Moonmint","time":90,"gold":330,"energy":2,"color":"#9eefff"},
	{"name":"Starroot","time":180,"gold":720,"energy":4,"color":"#d39cff"},
	{"name":"Emberpod","time":300,"gold":1280,"energy":6,"color":"#ff8a6d"},
	{"name":"Dreamfruit","time":480,"gold":2200,"energy":9,"color":"#ff9fd9"},
	{"name":"Origin Bloom","time":720,"gold":4200,"energy":14,"color":"#fff0a3"}
]

const ADVENTURE_RANKS := [
	"Novice","Pathfinder","Trailblazer","Vanguard","Warden","Champion","Ascendant","Mythic","Origin"
]

const FORGE_TITLES := [
	"Rough Forge","Verdant Forge","Runic Forge","Astral Forge","Divine Forge","Origin Forge"
]
