class_name ItemCatalog
extends RefCounted

## Canonical metadata catalog (16x16 pixel icon, category badge, lore & effect text)
## and satchel badge classification for all carried items.


static func get_item_info(item_name: String) -> Dictionary:
	var n := item_name.to_lower()
	if "crate" in n or "herring" in n:
		return {
			"icon": "icon_crate.png",
			"category": "Heavy Harbor Cargo",
			"desc": "Salt-cured North Sea herring bound for Quartermaster Vos's storehouse. Demands both hands to carry; you cannot sprint cleanly until it is set down."
		}
	if "egg" in n:
		return {
			"icon": "icon_egg.png",
			"category": "Unseen Dragon Relic",
			"desc": "Pitch-black shell streaked with faint molten-gold veins, shielded beneath a dying mother's wing. Heavy and fever-warm—the Ghent Elders want it locked away, and the Church just cried a bounty on it."
		}
	if "requisition" in n or "writ" in n:
		return {
			"icon": "icon_strap.png",
			"category": "Captured Ambush Note",
			"desc": "Crumpled parchment dropped by Church Catchpoles beside the Counting-House iron-chain wagon: \"...the hollow nest was cold and the egg already taken. Meet Father Anselm at St. Donatian's by the eighth evening bell...\""
		}
	if "compass" in n:
		return {
			"icon": "icon_compass.png",
			"category": "Navigator's Instrument",
			"desc": "Bruges mariner's needle housed in tarnished brass. Helps keep true bearings through the Zwin docks and the wild borderlands beyond Old Heverlee."
		}
	if "beeswax" in n or "thimble" in n:
		return {
			"icon": "icon_beeswax_thimble.png",
			"category": "Ropewalk Blessing (Passive)",
			"desc": "Your mother's Louvain beeswax cake and pitted thimble, kept by Clara. Grants +1 Max Knot Integrity (4 loops), +25% Gold Cinch Zone, and +20% rope cast reach."
		}
	if "shuttle" in n:
		return {
			"icon": "icon_shuttle.png",
			"category": "Ropewalk Tool & Clue",
			"desc": "Clara's polished boxwood and brass shuttle from the Bruges Ropewalk—found fallen with torn cordage outside the silent mill."
		}
	if "strap" in n or "leather" in n:
		return {
			"icon": "icon_strap.png",
			"category": "Oiled Harness Evidence",
			"desc": "Heavy double-stitched wyrm-hide strap cut from a secret rider's flight rig, tied off with a clean Ropewalk bend instead of Hunter knots."
		}
	if "jerkin" in n or "flight-jerkin" in n:
		return {
			"icon": "icon_jerkin.png",
			"category": "Brotherhood Crew Coat",
			"desc": "Oiled wyrm-hide and forest-green flight jerkin stitched by Hendrick over five winters. Fitted with brass carabiner rings for upper-cloud patrol."
		}
	if "poultice" in n or "salve" in n:
		return {
			"icon": "icon_poultice.png",
			"category": "Chirurgeon's Salve",
			"desc": "Sister Maren's cool cliffsage, tallow, and honey poultice used to soothe rope-burns under a dragon's wing-hinge."
		}
	if "carabiner" in n:
		return {
			"icon": "icon_carabiner.png",
			"category": "Brotherhood Rigging Gear",
			"desc": "Forged brass-and-steel quick-link snapped onto Virelai's shoulder harness so mid-flight splices lock before a dive can shear the belly-band."
		}
	if "timing ring" in n or "topman" in n:
		return {
			"icon": "icon_carabiner.png",
			"category": "Topman's Speed-Knot Award",
			"desc": "Burnished brass splice-ring awarded at Hendrick's gorge training board. Steadying your wrist permanently grants +18% Gold Cinch Zone and +2.0s on every knot tie."
		}
	if "hook" in n or "whipping" in n:
		return {
			"icon": "icon_hook_whip.png",
			"category": "Splicing & Grappling Kit",
			"desc": "Tinned mariner's hook and tarred whipping twine used to bind split beams, haul heavy rigging, or snatch timber rings."
		}
	if "biscuit" in n or "twine" in n:
		return {
			"icon": "icon_biscuit_twine.png",
			"category": "Canal Provisions",
			"desc": "Hard-baked ship's biscuit stowed beside a spare coil of light hemp line for emergency splices on the wharf."
		}
	if "hemp" in n or "bundle" in n:
		return {
			"icon": "icon_hemp_bundle.png",
			"category": "Cordage Bundle",
			"desc": "Freshly combed Flanders hemp washed ashore in crates—valued by every quartermaster and sailor along the quay."
		}
	if "bread" in n or "rye" in n:
		return {
			"icon": "icon_bread.png",
			"category": "Warm Supper Loaf",
			"desc": "Crusty evening rye loaf baked by Pieter in Bruges Market, brought home to Uncle Willem and Clara before dusk."
		}
	if "map" in n or "chart" in n:
		return {
			"icon": "icon_map.png",
			"category": "Brotherhood Chart [M]",
			"desc": "Vellum border survey charting safe cairn trails, frost dead-ends, briar thickets, and winched creek crossings toward the Outpost."
		}
	return {
		"icon": "icon_knot.png",
		"category": "Satchel Item",
		"desc": "Carried field possession stored safely inside your oilskin dock satchel."
	}


static func get_item_badge(item_name: String) -> String:
	var nl := item_name.to_lower()
	if "beeswax" in nl or "compass" in nl:
		return "PASSIVE"
	if "shuttle" in nl or "strap" in nl or "requisition" in nl or "writ" in nl:
		return "CLUE"
	if "bread" in nl or "biscuit" in nl:
		return "FOOD"
	if "egg" in nl:
		return "RELIC"
	return "GEAR"
