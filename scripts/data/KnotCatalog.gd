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
		"subtitle": "Single-Foe Bind & Mooring",
		"throw_style": "Figure-Eight Double-Loop Cast",
		"ability": "Mooring & Single-Foe Bind (155px) — Lashes bollards & permanently binds ONE foe (binding another frees the first)",
		"ability_short": "Bind 1 Foe & Mooring (155px)",
		"range": 155.0,
		"time_limit": 14.0,
		"sweet_width": 0.22,
		"tension_speed": 1.75,
		"desc": "Two opposing loops cinched around a bollard or foe. Permanently binds one enemy at a time until recast elsewhere.",
		"pegs": [Vector2(105, 185), Vector2(215, 85), Vector2(215, 205), Vector2(365, 85), Vector2(365, 205), Vector2(485, 145)],
		"snags": [Vector2(215, 145), Vector2(365, 145)]
	},
	"bruges_whipping": {
		"name": "Bruges Whipping-Knot",
		"subtitle": "Ranged Whip-Crack & Shield Yank",
		"throw_style": "S-Curve Whip + 3-Prong Brass Hook",
		"ability": "Whip-Crack & Brass Hook (215px) — Deals ranged whip damage, rips shields off foes, yanks closer & hauls canal crates",
		"ability_short": "Whip Damage, Yank & Hook (215px)",
		"range": 215.0,
		"time_limit": 13.0,
		"sweet_width": 0.18,
		"tension_speed": 1.95,
		"desc": "Tight hemp whipping learned at the Bruges Ropewalk. Snaps at range for direct damage, yanks shields, and hooks flotsam.",
		"pegs": [Vector2(95, 150), Vector2(195, 78), Vector2(285, 210), Vector2(375, 78), Vector2(465, 205), Vector2(515, 115), Vector2(285, 135)],
		"snags": [Vector2(240, 145), Vector2(330, 145), Vector2(430, 135)]
	},
	"bowline": {
		"name": "Bowline Rescue Loop",
		"subtitle": "King of Knots (AOE Snare)",
		"throw_style": "Wide Sweeping Lasso Ring",
		"ability": "Wide Loop Snare (195px, 92px AOE) — Temporarily snares enemy clusters (~3.2s) & catches grapple posts or canal pouches",
		"ability_short": "AOE Loop Snare & Grapple (195px)",
		"range": 195.0,
		"time_limit": 12.0,
		"sweet_width": 0.16,
		"tension_speed": 2.10,
		"desc": "Non-slip rescue loop that sweeps wide to snare groups of foes for 3.2 seconds or latch onto heavy grapple posts.",
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
