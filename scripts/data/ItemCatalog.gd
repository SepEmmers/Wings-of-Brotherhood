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
			"icon": "prop_dropped_note.png",
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
	if "decree" in n or "abbey" in n or "warrant" in n:
		return {
			"icon": "prop_dropped_note.png",
			"category": "Abbey Scriptorium Evidence",
			"desc": "Signed Church Decree ordering Inquisitors to bury the Old Heverlee Shrine Key affair—paired with a five-year requisition sending 'Clara of Bruges, rig-master' east to Namur's quarries."
		}
	if "river clay" in n or "clay" in n:
		return {
			"icon": "icon_clay.png",
			"category": "Dijle Foundry Clay",
			"desc": "Fine grey alluvial clay dug along the Dijle bank to seal the hairline fracture in Master Pieter's cracked bell-mould."
		}
	if "hunter" in n or "brass ring" in n or "signet" in n:
		return {
			"icon": "icon_carabiner.png",
			"category": "Old Heverlee Relic",
			"desc": "Tarnished guild brass signet recovered for the one-eyed Old Heverlee survivor—bearing the same oak-and-hound stamp as your parents' field kit."
		}
	if "chime" in n or "resonance" in n:
		return {
			"icon": "prop_resonance_chime.png",
			"category": "Stealth Distraction",
			"desc": "Harmonic hand-cast bronze chime from the Louvain Foundry; drop or ring it near patrols to draw Catchpoles out of lanes."
		}
	if "smoke" in n or "pellet" in n:
		return {
			"icon": "prop_smoke_pellet.png",
			"category": "Alchemical Cover",
			"desc": "Beeswaxed ash-and-herb pellet steeped by Louvain's Dyers' Quarter herbalist; bursts into concealing soot-fog for five seconds."
		}
	if "reliquary" in n or "crimson" in n:
		return {
			"icon": "prop_treasure_chest_closed.png",
			"category": "Catacombs Secret Relic",
			"desc": "Ruby-sealed Brotherhood reliquary unearthed beneath the eastern Chalice tomb in St. Peter's Crypt—fortified your vitality (+1 Max Heart) and deepened your bond."
		}
	if "ashlar" in n or "gobertange" in n:
		return {
			"icon": "icon_mason_stone.png",
			"category": "Sint-Pieterskerk Quarry Load",
			"desc": "Heavy bundle of white Gobertange ashlar blocks unlashed from Vismarkt Stone Quay for Master Mason Matthijs's tower race against Brussels."
		}
	if "plumb" in n or "mason" in n:
		return {
			"icon": "icon_plumb_signet.png",
			"category": "Guild Master Craft Signet",
			"desc": "Gilded mason's plumb-bob awarded by Master Mason Matthijs once Sint-Pieterskerk's limestone spire rose higher than Brussels' belfry."
		}
	if "shrine key" in n or "heverlee" in n:
		return {
			"icon": "icon_heverlee_key.png",
			"category": "Golden Shrine Key Relic",
			"desc": "Ancient double-warded bronze and gold key your parents died hiding beneath Old Heverlee Woods to keep the Devildragon sealed."
		}
	if "cipher" in n or "scout" in n:
		return {
			"icon": "prop_dropped_note.png",
			"category": "Inquisitor Field Dispatch",
			"desc": "Wax-stamped Church hunting order recovered from the Old Heverlee scout ridge naming Namur's Quarry and the Meuse blood-barge convoy."
		}
	if "satchel" in n or "hesbaye supply" in n:
		return {
			"icon": "icon_hemp_bundle.png",
			"category": "Brotherhood Courier Drop",
			"desc": "Captain Anna's stitched leather dispatch pack filled with dried river rations, tarred hemp, and Ember-tallow for Hesbaye."
		}
	return {
		"icon": "icon_knot.png",
		"category": "Satchel Item",
		"desc": "Carried field possession stored safely inside your oilskin dock satchel."
	}


static func get_item_badge(item_name: String) -> String:
	var nl := item_name.to_lower()
	if "beeswax" in nl or "compass" in nl or "timing" in nl:
		return "PASSIVE"
	if "shuttle" in nl or "strap" in nl or "requisition" in nl or "writ" in nl or "decree" in nl or "signet" in nl:
		return "CLUE"
	if "bread" in nl or "biscuit" in nl or "ration" in nl:
		return "FOOD"
	if "chime" in nl or "smoke" in nl:
		return "STEALTH"
	if "egg" in nl:
		return "RELIC"
	return "GEAR"
