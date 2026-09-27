extends Node

const LEAF_COUNT := 195

const TREES := {
	"maple": {
		"blurb": "sweet and classic. snow doesn't scare it, but wind sure does.",
	},
	"birch": {
		"blurb": "pale and papery. loves the cold, not so great with fire.",
	},
	"oak": {
		"blurb": "big, old and stubborn. shrugs off quakes and hail.",
	},
	"aspen": {
		"blurb": "shaky but bendy. aspens are famous for bouncing back from fire.",
	},
}

const DISASTERS := ["tornado", "wildfire", "flood", "blizzard", "hailstorm", "earthquake"]

const BASE_ODDS := {
	"maple": {"tornado": 35, "wildfire": 45, "flood": 50, "blizzard": 65, "hailstorm": 50, "earthquake": 55},
	"birch": {"tornado": 45, "wildfire": 30, "flood": 50, "blizzard": 70, "hailstorm": 45, "earthquake": 50},
	"oak":   {"tornado": 40, "wildfire": 45, "flood": 55, "blizzard": 50, "hailstorm": 65, "earthquake": 70},
	"aspen": {"tornado": 60, "wildfire": 60, "flood": 45, "blizzard": 55, "hailstorm": 45, "earthquake": 50},
}

const STATS := {
	"tornado": "aerodynamics",
	"wildfire": "heat resistance",
	"flood": "waterproofing",
	"blizzard": "insulation",
	"hailstorm": "toughness",
	"earthquake": "grip",
}

const STAT_CAP := 90

const LARGE_DISASTER_CHANCE := 0.1
const LARGE_DISASTER_ODDS_MULTIPLIER := 0.3

const TRAITS := {
	"bendy":  {"blurb": "sways with the wind", "bonus": {"tornado": 25, "hailstorm": 10}},
	"clingy": {"blurb": "holds on super tight", "bonus": {"earthquake": 25, "flood": 10}},
	"waxy":   {"blurb": "shiny and waterproof", "bonus": {"flood": 25, "blizzard": 10}},
	"lucky":  {"blurb": "a little bit of everything", "bonus": {"tornado": 8, "wildfire": 8, "flood": 8, "blizzard": 8, "hailstorm": 8, "earthquake": 8}},
}

const COLORS := {
	"red": Color(0.78, 0.2, 0.12),
	"orange": Color(0.93, 0.47, 0.1),
	"golden": Color(0.96, 0.74, 0.2),
	"green": Color(0.55, 0.6, 0.2),
	"deep": Color(0.42, 0.12, 0.13),
}

const STEPS := ["color", "personality", "name", "stem", "coating", "veins", "hat", "buddy", "training", "snack", "pep_talk", "review"]

const STARTING_SAP := 40
const SAP_FOR_SURVIVING := 25
const SAP_FOR_SURVIVING_LARGE := 60

const SAVE_PATH := "user://save.cfg"

var tree := "maple"
var leaf_color := "orange"
var leaf_trait := "lucky"
var leaf_name := "leafy"

var survived_count := 0
var lost_count := 0

var sap := STARTING_SAP
var owned := {}
var equipped := {}


func _ready() -> void:
	for category: String in Shop.CATEGORIES:
		equipped[category] = Shop.CATEGORIES[category]["options"][0]["id"]
	load_game()


func leaf_index() -> int:
	var options: Array = LeafCatalog.LEAVES[tree][leaf_color]
	var pick := absi(hash(leaf_trait + ":" + leaf_name))
	return options[pick % options.size()]


func leaf_texture(index: int = -1) -> Texture2D:
	if index < 0:
		index = leaf_index()
	return load("res://autumn_leaves/leaf_%03d.png" % index)


func random_leaf_texture() -> Texture2D:
	return leaf_texture(randi_range(1, LEAF_COUNT))


func stat(disaster: String, swap := {}) -> int:
	if is_goomba():
		return 100
	var quirk := absi(hash([leaf_index(), disaster])) % 11 - 5
	var value: int = BASE_ODDS[tree][disaster] + TRAITS[leaf_trait]["bonus"].get(disaster, 0) + quirk
	for category: String in Shop.CATEGORIES:
		var option := shop_option(category, swap.get(category, equipped[category]))
		value += item_bonus(option, disaster)
	return clampi(value, 5, STAT_CAP)


func item_bonus(option: Dictionary, disaster: String) -> int:
	var stats: Dictionary = option["stats"]
	return stats.get(STATS[disaster], 0) + stats.get("all", 0)


func shop_option(category: String, id: String) -> Dictionary:
	for option: Dictionary in Shop.CATEGORIES[category]["options"]:
		if option["id"] == id:
			return option
	return Shop.CATEGORIES[category]["options"][0]


func equipped_option(category: String) -> Dictionary:
	return shop_option(category, equipped[category])


func is_owned(category: String, option: Dictionary) -> bool:
	return option["cost"] == 0 or owned.has(category + "/" + option["id"])


func buy(category: String, option: Dictionary) -> bool:
	if is_owned(category, option):
		return true
	if sap < option["cost"]:
		return false
	sap -= option["cost"]
	owned[category + "/" + option["id"]] = true
	save_game()
	return true


func leaf_tint(swap := {}) -> Color:
	return shop_option("coating", swap.get("coating", equipped["coating"])).get("tint", Color.WHITE)


func dressed_leaf(swap := {}) -> Dictionary:
	return GearArt.dress_leaf(leaf_texture(), leaf_tint(swap),
		swap.get("hat", equipped["hat"]), swap.get("buddy", equipped["buddy"]))


func reward(survived: bool, large: bool) -> int:
	var earned := 0
	if survived:
		earned = SAP_FOR_SURVIVING_LARGE if large else SAP_FOR_SURVIVING
	sap += earned
	save_game()
	return earned


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "sap", sap)
	config.set_value("progress", "owned", owned.keys())
	config.set_value("progress", "survived", survived_count)
	config.set_value("progress", "lost", lost_count)
	config.set_value("leaf", "tree", tree)
	config.set_value("leaf", "color", leaf_color)
	config.set_value("leaf", "trait", leaf_trait)
	config.set_value("leaf", "name", leaf_name)
	config.set_value("leaf", "equipped", equipped)
	config.save(SAVE_PATH)


func load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	sap = config.get_value("progress", "sap", STARTING_SAP)
	for key: String in config.get_value("progress", "owned", []):
		owned[key] = true
	survived_count = config.get_value("progress", "survived", 0)
	lost_count = config.get_value("progress", "lost", 0)
	tree = config.get_value("leaf", "tree", tree)
	leaf_color = config.get_value("leaf", "color", leaf_color)
	leaf_trait = config.get_value("leaf", "trait", leaf_trait)
	leaf_name = config.get_value("leaf", "name", leaf_name)
	var saved_equipped: Dictionary = config.get_value("leaf", "equipped", {})
	for category: String in saved_equipped:
		if equipped.has(category):
			equipped[category] = saved_equipped[category]


func is_goomba() -> bool:
	return leaf_name.strip_edges().to_lower() == "goomba"


func survival_chance(disaster: String, large := false) -> int:
	if is_goomba():
		return 100
	var chance := stat(disaster)
	if large:
		chance = maxi(1, roundi(chance * LARGE_DISASTER_ODDS_MULTIPLIER))
	return chance
