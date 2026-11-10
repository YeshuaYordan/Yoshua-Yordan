extends Node
## Card database (autoload "CardDB").
## Holds every element, its stats, the fusion recipes, rarity rules and save data.

const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Myth", "Legend"]
const RARITY_COLORS := [
	Color("#a89878"), Color("#5fae5a"), Color("#4f8fd6"),
	Color("#a160e0"), Color("#e0533f"), Color("#f2c14e"),
]
const RARITY_DMG := [1.0, 1.7, 2.8, 4.5, 7.0, 11.0]
const RARITY_RATE := [1.0, 1.08, 1.16, 1.26, 1.38, 1.5]
const RARITY_PRICE := [3, 6, 12, 24, 45, 80]
const MAX_RARITY := 5

const BASE_ELEMENTS := ["fire", "water", "earth", "wind"]
## Element on the left beats the element on the right.
const COUNTERS := {"water": "fire", "fire": "wind", "wind": "earth", "earth": "water"}

## Stats are for a Common card. Optional effect keys:
## burn (dps), knock (px), splash (radius), pierce (extra enemies), chain (targets),
## root (sec), slow (speed multiplier), cloud / puddle (lingering zone radius), multishot.
var elements := {
	# --- Tier I: base elements (sold in the shop) ---
	"fire": {"name": "Fire", "tier": 1, "color": Color("#ff7a2f"), "shape": "flame", "parts": ["fire"],
		"desc": "Sets enemies ablaze.", "dmg": 8.0, "rate": 1.4, "speed": 720.0, "burn": 4.0},
	"water": {"name": "Water", "tier": 1, "color": Color("#3fb8d8"), "shape": "drop", "parts": ["water"],
		"desc": "Splashes enemies back.", "dmg": 9.0, "rate": 1.2, "speed": 660.0, "knock": 18.0},
	"earth": {"name": "Earth", "tier": 1, "color": Color("#9a7a4a"), "shape": "rock", "parts": ["earth"],
		"desc": "Hurls heavy boulders.", "dmg": 20.0, "rate": 0.6, "speed": 480.0, "splash": 45.0},
	"wind": {"name": "Wind", "tier": 1, "color": Color("#bfe6e0"), "shape": "swirl", "parts": ["wind"],
		"desc": "Fast gusts pierce foes.", "dmg": 6.0, "rate": 2.0, "speed": 980.0, "pierce": 2},
	# --- Tier II: fusions of two base elements ---
	"steam": {"name": "Steam", "tier": 2, "color": Color("#d8d4e8"), "shape": "cloud", "parts": ["fire", "water"],
		"desc": "Scalding cloud hurts all inside.", "dmg": 8.0, "rate": 0.8, "speed": 600.0, "cloud": 80.0, "cloud_dps": 12.0},
	"lava": {"name": "Lava", "tier": 2, "color": Color("#e8452c"), "shape": "rock", "parts": ["fire", "earth"],
		"desc": "Leaves burning magma pools.", "dmg": 16.0, "rate": 0.9, "speed": 560.0, "puddle": 55.0, "puddle_dps": 10.0, "burn": 4.0},
	"lightning": {"name": "Lightning", "tier": 2, "color": Color("#ffe34a"), "shape": "spiky", "parts": ["fire", "wind"],
		"desc": "Thunderbird bolt chains 3 foes.", "dmg": 14.0, "rate": 1.0, "chain": 3},
	"plant": {"name": "Plant", "tier": 2, "color": Color("#5cc36a"), "shape": "leaf", "parts": ["water", "earth"],
		"desc": "Dryad vines root enemies.", "dmg": 12.0, "rate": 0.9, "speed": 620.0, "root": 1.0},
	"ice": {"name": "Ice", "tier": 2, "color": Color("#9fdcff"), "shape": "crystal", "parts": ["water", "wind"],
		"desc": "Frost wolf bite slows foes.", "dmg": 11.0, "rate": 1.1, "speed": 700.0, "slow": 0.5},
	"sand": {"name": "Sand", "tier": 2, "color": Color("#e6c36a"), "shape": "blob", "parts": ["earth", "wind"],
		"desc": "Djinn sandblast pushes foes back.", "dmg": 10.0, "rate": 1.0, "speed": 640.0, "knock": 55.0, "splash": 40.0},
	# --- Tier III: fusions of fusions ---
	"storm": {"name": "Storm", "tier": 3, "color": Color("#8a7dff"), "shape": "cloud", "parts": ["fire", "wind", "water"],
		"desc": "Chains 5 foes and slows them.", "dmg": 22.0, "rate": 1.1, "chain": 5, "slow": 0.6},
	"blizzard": {"name": "Blizzard", "tier": 3, "color": Color("#e6f6ff"), "shape": "crystal", "parts": ["water", "wind"],
		"desc": "Freezing blast slows a wide area.", "dmg": 14.0, "rate": 0.9, "speed": 640.0, "splash": 110.0, "slow": 0.45},
	"obsidian": {"name": "Obsidian", "tier": 3, "color": Color("#4a3a5e"), "shape": "rock", "parts": ["fire", "earth", "water"],
		"desc": "Volcanic glass pierces 5 foes.", "dmg": 40.0, "rate": 0.8, "speed": 820.0, "pierce": 5},
	"grove": {"name": "Grove", "tier": 3, "color": Color("#2f9e55"), "shape": "leaf", "parts": ["water", "earth"],
		"desc": "Ancient roots trap a whole area.", "dmg": 20.0, "rate": 0.8, "speed": 560.0, "splash": 90.0, "root": 1.2},
	"wildfire": {"name": "Wildfire", "tier": 3, "color": Color("#ff4f1f"), "shape": "flame", "parts": ["fire", "water", "earth"],
		"desc": "Spreading flames burn an area.", "dmg": 14.0, "rate": 1.2, "speed": 640.0, "splash": 70.0, "burn": 12.0},
	"crystal": {"name": "Crystal", "tier": 3, "color": Color("#ff8ad8"), "shape": "crystal", "parts": ["earth", "wind", "fire"],
		"desc": "Fires 3 prism shards at once.", "dmg": 16.0, "rate": 1.2, "speed": 760.0, "multishot": 3},
}

## [a, b, result]. Order of a and b does not matter.
const RECIPE_LIST := [
	["fire", "water", "steam"],
	["fire", "earth", "lava"],
	["fire", "wind", "lightning"],
	["water", "earth", "plant"],
	["water", "wind", "ice"],
	["earth", "wind", "sand"],
	["lightning", "water", "storm"],
	["ice", "wind", "blizzard"],
	["lava", "water", "obsidian"],
	["plant", "earth", "grove"],
	["plant", "fire", "wildfire"],
	["sand", "lightning", "crystal"],
]

var recipes := {}

# --- Save data ---
const SAVE_PATH := "user://save.cfg"
var discovered := {}
var best_wave := 0
var save_enabled := true  # tests turn this off


func _ready() -> void:
	for r in RECIPE_LIST:
		recipes[recipe_key(r[0], r[1])] = r[2]
	load_save()


func recipe_key(a: String, b: String) -> String:
	var arr := [a, b]
	arr.sort()
	return "%s+%s" % [arr[0], arr[1]]


## Returns {"element", "rarity"} if the two cards can fuse, or {} if they can't.
func merge(a_el: String, a_r: int, b_el: String, b_r: int) -> Dictionary:
	if a_el == b_el:
		if a_r == b_r and a_r < MAX_RARITY:
			return {"element": a_el, "rarity": a_r + 1}
		return {}
	var key := recipe_key(a_el, b_el)
	if recipes.has(key):
		return {"element": recipes[key], "rarity": mini(a_r, b_r)}
	return {}


func damage(el: String, r: int) -> float:
	return float(elements[el]["dmg"]) * RARITY_DMG[r]


func rate(el: String, r: int) -> float:
	return float(elements[el]["rate"]) * RARITY_RATE[r]


func price(el: String, r: int) -> int:
	return RARITY_PRICE[r] * int(elements[el]["tier"])


func sell_value(el: String, r: int) -> int:
	return maxi(1, price(el, r) / 2)


## Damage multiplier for element-vs-enemy matchups.
func element_multiplier(el: String, resist: String, flying: bool) -> float:
	var m := 1.0
	var parts: Array = elements[el]["parts"]
	if resist != "":
		if parts.has(resist):
			m *= 0.5
		for p in parts:
			if COUNTERS.get(p, "") == resist:
				m *= 1.5
				break
	if flying:
		if parts.has("wind"):
			m *= 1.6
		elif parts.size() == 1 and parts[0] == "earth":
			m *= 0.6
	return m


func roll_rarity(wave: int) -> int:
	var w := float(wave)
	var weights := [
		maxf(8.0, 70.0 - 2.5 * w),
		22.0 + 0.8 * w,
		6.0 + 0.7 * w,
		maxf(0.0, 0.5 + 0.45 * (w - 2.0)),
		maxf(0.0, 0.25 * (w - 8.0)),
		maxf(0.0, 0.12 * (w - 15.0)),
	]
	var total := 0.0
	for x in weights:
		total += x
	var pick := randf() * total
	for i in weights.size():
		pick -= weights[i]
		if pick <= 0.0:
			return i
	return 0


func random_base() -> String:
	return BASE_ELEMENTS[randi() % BASE_ELEMENTS.size()]


func describe(el: String, r: int) -> String:
	var d: Dictionary = elements[el]
	return "%s %s  -  %d dmg, %.1f shots/s. %s" % [
		RARITY_NAMES[r], d["name"], roundi(damage(el, r)), rate(el, r), d["desc"]]


func color_hex(el: String) -> String:
	return (elements[el]["color"] as Color).to_html(false)


# --- Save / load ---

func load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	best_wave = int(cf.get_value("progress", "best_wave", 0))
	for e in cf.get_value("progress", "discovered", []):
		discovered[e] = true


func save() -> void:
	if not save_enabled:
		return
	var cf := ConfigFile.new()
	cf.set_value("progress", "best_wave", best_wave)
	cf.set_value("progress", "discovered", discovered.keys())
	cf.save(SAVE_PATH)


## Marks a fused element as discovered. Returns true if it is new.
func discover(el: String) -> bool:
	if discovered.has(el):
		return false
	discovered[el] = true
	save()
	return true
