class_name KnotCatalog
extends RefCounted

## Canonical knot progression order, gameplay parameters, and pegboard geometries.

const KNOT_ORDER: Array[String] = [
	"clove_hitch",
	"bruges_whipping",
	"bowline",
	"dragon_splice"
]

const KNOT_DATA := {
	"clove_hitch": {
		"name": "Clove Hitch",
		"subtitle": "Dockboy's Mooring Knot",
		"throw_style": "Figure-Eight Double-Loop Cast",
		"ability": "Mooring Lash (155px) — Binds ship cleats, bollards & timber posts",
		"ability_short": "Lash Bollards & Cleats (155px)",
		"range": 155.0,
		"time_limit": 14.0,
		"sweet_width": 0.22,
		"tension_speed": 1.75,
		"desc": "Two opposing loops cinched around a bollard or piling. Standard shipboard mooring.",
		"pegs": [Vector2(105, 185), Vector2(215, 85), Vector2(215, 205), Vector2(365, 85), Vector2(365, 205), Vector2(485, 145)],
		"snags": [Vector2(215, 145), Vector2(365, 145)]
	},
	"bruges_whipping": {
		"name": "Bruges Whipping-Knot",
		"subtitle": "Ropewalk Grapple Bind",
		"throw_style": "S-Curve Whip + 3-Prong Brass Hook",
		"ability": "Heavy Brass Grapple (215px) — Hooks & hauls heavy waterlogged canal crates",
		"ability_short": "Heavy Grapple Hook (215px)",
		"range": 215.0,
		"time_limit": 13.0,
		"sweet_width": 0.18,
		"tension_speed": 1.95,
		"desc": "Tight hemp whipping learned at the Bruges Ropewalk. Secures a heavy brass grapple for long snags.",
		"pegs": [Vector2(95, 150), Vector2(195, 78), Vector2(285, 210), Vector2(375, 78), Vector2(465, 205), Vector2(515, 115), Vector2(285, 135)],
		"snags": [Vector2(240, 145), Vector2(330, 145), Vector2(430, 135)]
	},
	"bowline": {
		"name": "Bowline Rescue Loop",
		"subtitle": "King of Knots",
		"throw_style": "Wide Sweeping Lasso Ring",
		"ability": "Wide Rescue Lasso (195px, 2.2x AoE) — Sweeps wide to catch bobbing canal pouches",
		"ability_short": "Wide Rescue Lasso (195px, 2x AoE)",
		"range": 195.0,
		"time_limit": 12.0,
		"sweet_width": 0.16,
		"tension_speed": 2.10,
		"desc": "The rabbit comes out of the hole, round the tree, and back down. Forms a non-slip rescue loop.",
		"pegs": [Vector2(110, 205), Vector2(205, 90), Vector2(335, 78), Vector2(475, 145), Vector2(365, 218), Vector2(235, 198), Vector2(265, 138)],
		"snags": [Vector2(195, 148), Vector2(325, 148), Vector2(405, 145)]
	},
	"dragon_splice": {
		"name": "Brotherhood Harness Splice",
		"subtitle": "Aerial Rider's Cross-Lash",
		"throw_style": "Twin-Strand Carabiner Cross-Lash",
		"ability": "Aerial Harness Winch-Dash (245px) — Latches posts & pulls you swiftly across gaps",
		"ability_short": "Winch-Dash Grapple (245px)",
		"range": 245.0,
		"time_limit": 11.0,
		"sweet_width": 0.14,
		"tension_speed": 2.30,
		"desc": "Interwoven leather-and-hemp rigging splice used by the Secret Brotherhood to anchor mid-flight riders.",
		"pegs": [Vector2(90, 95), Vector2(215, 210), Vector2(335, 82), Vector2(465, 210), Vector2(510, 105), Vector2(335, 210), Vector2(215, 82), Vector2(495, 155)],
		"snags": [Vector2(160, 150), Vector2(275, 146), Vector2(395, 146), Vector2(445, 150)]
	}
}
