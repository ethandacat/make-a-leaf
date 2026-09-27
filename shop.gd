class_name Shop

const CATEGORIES := {
	"stem": {
		"title": "pick a stem",
		"blurb": "the stem is what keeps you on the tree. kind of important.",
		"options": [
			{"id": "regular", "name": "regular stem", "cost": 0, "stats": {}},
			{"id": "braided", "name": "braided stem", "cost": 15, "stats": {"grip": 10}},
			{"id": "sap_glued", "name": "sap-glued stem", "cost": 30, "stats": {"grip": 16, "aerodynamics": 4}},
			{"id": "titanium", "name": "titanium stem", "cost": 70, "stats": {"grip": 24, "toughness": 10, "aerodynamics": -6}},
		],
	},
	"coating": {
		"title": "choose a coating",
		"blurb": "a nice protective layer. also makes you shiny.",
		"options": [
			{"id": "none", "name": "no coating", "cost": 0, "stats": {}},
			{"id": "beeswax", "name": "beeswax", "cost": 15, "stats": {"waterproofing": 15}, "tint": Color(1.0, 0.95, 0.75)},
			{"id": "frost_wax", "name": "frost wax", "cost": 15, "stats": {"insulation": 15}, "tint": Color(0.85, 0.95, 1.0)},
			{"id": "clay_dust", "name": "clay dust", "cost": 15, "stats": {"heat resistance": 15}, "tint": Color(1.0, 0.85, 0.8)},
			{"id": "rainbow", "name": "rainbow varnish", "cost": 55, "stats": {"all": 6}, "tint": Color(1.0, 0.9, 1.0)},
		],
	},
	"veins": {
		"title": "upgrade your veins",
		"blurb": "veins are the leaf's skeleton. sort of. don't look it up.",
		"options": [
			{"id": "normal", "name": "normal veins", "cost": 0, "stats": {}},
			{"id": "bendy", "name": "bendy veins", "cost": 20, "stats": {"aerodynamics": 14, "toughness": -4}},
			{"id": "reinforced", "name": "reinforced veins", "cost": 20, "stats": {"toughness": 14, "aerodynamics": -4}},
			{"id": "double", "name": "double veins", "cost": 45, "stats": {"toughness": 10, "grip": 8}},
		],
	},
	"hat": {
		"title": "pick a tiny hat",
		"blurb": "every leaf deserves a hat.",
		"options": [
			{"id": "none", "name": "no hat", "cost": 0, "stats": {}},
			{"id": "acorn_cap", "name": "acorn cap", "cost": 10, "stats": {"toughness": 8}},
			{"id": "beanie", "name": "tiny beanie", "cost": 15, "stats": {"insulation": 12}},
			{"id": "umbrella", "name": "leaf umbrella", "cost": 20, "stats": {"waterproofing": 10, "toughness": 5}},
			{"id": "fire_helmet", "name": "fire helmet", "cost": 35, "stats": {"heat resistance": 18}},
			{"id": "propeller", "name": "propeller hat", "cost": 40, "stats": {"aerodynamics": 16, "grip": -3}},
		],
	},
	"buddy": {
		"title": "bring a buddy",
		"blurb": "a little friend to ride out the storm with you.",
		"options": [
			{"id": "none", "name": "no buddy", "cost": 0, "stats": {}},
			{"id": "ladybug", "name": "ladybug", "cost": 15, "stats": {"grip": 8}},
			{"id": "snail", "name": "snail", "cost": 20, "stats": {"waterproofing": 10, "grip": 4}},
			{"id": "firefly", "name": "firefly", "cost": 25, "stats": {"insulation": 12}},
			{"id": "caterpillar", "name": "caterpillar bodyguard", "cost": 30, "stats": {"toughness": 12, "grip": 5}},
			{"id": "bumblebee", "name": "bumblebee", "cost": 30, "stats": {"aerodynamics": 12, "heat resistance": 4}},
		],
	},
	"training": {
		"title": "sign up for training",
		"blurb": "no pain, no grain. wait, that's wheat.",
		"options": [
			{"id": "none", "name": "skip training", "cost": 0, "stats": {}},
			{"id": "wind_yoga", "name": "wind yoga", "cost": 20, "stats": {"aerodynamics": 12}},
			{"id": "sauna", "name": "sauna sessions", "cost": 20, "stats": {"heat resistance": 12}},
			{"id": "cold_plunge", "name": "cold plunges", "cost": 20, "stats": {"insulation": 12}},
			{"id": "swim", "name": "swim lessons", "cost": 20, "stats": {"waterproofing": 12}},
			{"id": "dodgeball", "name": "hail dodgeball", "cost": 20, "stats": {"toughness": 12}},
			{"id": "climbing", "name": "rock climbing", "cost": 20, "stats": {"grip": 12}},
		],
	},
	"snack": {
		"title": "have a snack",
		"blurb": "you can't face a natural disaster on an empty stomach.",
		"options": [
			{"id": "none", "name": "nothing, thanks", "cost": 0, "stats": {}},
			{"id": "dew", "name": "morning dew", "cost": 5, "stats": {"all": 2}},
			{"id": "smoothie", "name": "sunlight smoothie", "cost": 20, "stats": {"all": 4}},
			{"id": "compost", "name": "gourmet compost bowl", "cost": 40, "stats": {"all": 6}},
		],
	},
	"pep_talk": {
		"title": "get a pep talk",
		"blurb": "believe in yourself. or at least let someone else believe in you.",
		"options": [
			{"id": "none", "name": "no pep talk", "cost": 0, "stats": {}},
			{"id": "you_got_this", "name": "\"you got this\"", "cost": 5, "stats": {"toughness": 3, "grip": 3}},
			{"id": "poster", "name": "motivational poster", "cost": 15, "stats": {"all": 3}},
			{"id": "old_oak", "name": "speech from an old oak", "cost": 45, "stats": {"all": 7}},
		],
	},
}
