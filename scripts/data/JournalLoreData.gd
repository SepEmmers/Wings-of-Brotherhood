class_name JournalLoreData
extends RefCounted

## Narrative formatting helpers for the Boy's Diary, Field Bestiary, and Knots & Controls tabs.

const KnotCatalogScript := preload("res://scripts/data/KnotCatalog.gd")


static func get_chapter_subtitle() -> String:
	match GameState.current_step:
		GameState.QuestStep.ON_THE_SHIP:
			return "Ch. 1 — Aboard 'De Zwaan'"
		GameState.QuestStep.EXPLORE_BRUGES:
			return "Ch. 1 — Port of Bruges & Ropewalk"
		GameState.QuestStep.EVENING_HOME:
			return "Ch. 1 — Uncle Willem's Cottage"
		GameState.QuestStep.DAWN_MISSING_CLARA, GameState.QuestStep.SNITCH_TO_CHURCH, GameState.QuestStep.BROTHERHOOD_AMBUSH:
			return "Ch. 1 — Dawn Search in Bruges"
		GameState.QuestStep.ACT2_SANCTUARY:
			match GameState.sanctuary_phase:
				1: return "Ch. 2 — Sanctuary Year 1 (Age 12)"
				2: return "Ch. 2 — Sanctuary Year 3 (Age 14)"
				_: return "Ch. 2 — Sanctuary Year 5 (Age 17)"
		GameState.QuestStep.ACT2_VIRELAI_SORTIE_1:
			return "Ch. 2 — Coast Patrol Sortie (Age 14)"
		GameState.QuestStep.ACT2_VIRELAI_SORTIE_2:
			return "Ch. 2 — Eastern Storm Recon (Age 17)"
		GameState.QuestStep.ACT3_WILDS_TRACKING, GameState.QuestStep.ACT3_EGG_TREK:
			return "Ch. 3 — Frontier Wilds (Age %d)" % GameState.boy_age
		GameState.QuestStep.BOOK1_WATCHTOWER_HEARTH:
			return "Ch. 3 — Watchtower Hearth (Age %d)" % GameState.boy_age
		GameState.QuestStep.ACT4_SANCTUARY_DEBATE:
			return "Ch. 4 — The Egg Council (Age %d)" % GameState.boy_age
		GameState.QuestStep.ACT4_BRUGES_CITY:
			return "Ch. 4 — Walled City of Bruges (Age %d)" % GameState.boy_age
		GameState.QuestStep.ACT4_NIGHT_HEIST:
			return "Ch. 4 — Midnight Heist on Kestrel (Age %d)" % GameState.boy_age
		GameState.QuestStep.BOOK2_BRABANT_FENS:
			return "Book II Ch. 1 — Brabant Fens (Age %d)" % GameState.boy_age
		GameState.QuestStep.BOOK2_LOUVAIN_HATCH:
			return "Book II Ch. 2 — Louvain Awakening (Age %d)" % GameState.boy_age
		GameState.QuestStep.BOOK2_OLD_HEVERLEE:
			return "Book II Ch. 3 — Old Heverlee Shrine (Age %d)" % GameState.boy_age
		GameState.QuestStep.BOOK2_ANNA_SORTIE_1:
			return "Book II — Anna's River Raid"
		GameState.QuestStep.BOOK2_NAMUR_CROSSING:
			return "Book II Ch. 4 — Namur Cliff-Citadel (Age %d)" % GameState.boy_age
		GameState.QuestStep.BOOK2_ANNA_SORTIE_2:
			return "Book II — Anna's Stalling Sortie"
		GameState.QuestStep.BOOK2_ARDENNES_SHED:
			return "Book II Ch. 5 — Ardennes Highlands (Age %d)" % GameState.boy_age
		_:
			return "Book II Finale — Blood-Citadel (Age %d)" % GameState.boy_age


static func get_diary_summary() -> String:
	var s := ""
	if GameState.current_step == GameState.QuestStep.ON_THE_SHIP:
		s += "• Aboard [i]De Zwaan[/i], coming down the Zwin into the Port of Bruges.\n"
		s += "• Moor the bow line once we touch the wharf, and haul the last herring crate ashore."
	elif GameState.current_step == GameState.QuestStep.EXPLORE_BRUGES:
		s += "• Salt-Herring Crate to Warehouse: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.cargo_delivered else "Still waiting on Master Vos\n")
		s += "• Check on Clara at the Ropewalk: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.visited_clara else "Waiting after shift\n")
		s += "• Rye Loaf from Baker Pieter: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.bought_bread else "Needed for Uncle Willem's table\n")
		s += "• Head back to Uncle Willem's cottage once evening chores are settled."
	elif GameState.current_step == GameState.QuestStep.EVENING_HOME:
		s += "• Back at Uncle Willem's cottage. Supper's nearly set—time to turn in before dawn tide."
	elif GameState.current_step == GameState.QuestStep.DAWN_MISSING_CLARA:
		s += "• Dawn broke and Clara's pallet is cold. Something is wedged by the cottage threshold."
	elif GameState.current_step in [GameState.QuestStep.SNITCH_TO_CHURCH, GameState.QuestStep.BROTHERHOOD_AMBUSH]:
		s += "• Clara is gone—only a snapped length of heavy harness-leather tied with her whipping-knot left by the door.\n"
		s += "• Get to the Market Square and tell the Church Inquisitor before the trail goes cold."
	elif GameState.current_step == GameState.QuestStep.ACT2_SANCTUARY:
		if GameState.sanctuary_phase == 1:
			s += "• [b]Year 1 (Age 12):[/b] Kept above the clouds in Captain Anna's cliff Sanctuary.\n"
			s += "• Hauling Leather for Saddler Hendrick: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.sanctuary_leather_chore_done else "Grab the cured bale south of the tent & bring it to Hendrick\n")
			s += "• Repair [i]Virelai[/i]'s frayed shoulder-ring: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.virelai_harness_spliced else "Work the Brotherhood Harness Splice\n")
			s += "• Brew Sage Poultice & Unshackle the Rescued Greyling: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.greyling_documented else ("Speak with Sister Maren by the boiling cauldron" if GameState.sanctuary_water_drawn else "Draw cliff-spring water & aid Sister Maren across the gorge\n"))
			s += "• Once Kestrel is treated and resting, report back to Anna by the flight perch."
		elif GameState.sanctuary_phase == 2:
			s += "• [b]Year 3 (Age 14):[/b] Two winters in the gorge cliffs. Wearing tan apprentice leather—pulling full camp rig duty.\n"
			s += "• Toss a fresh silver herring from the hearth bucket to Kestrel on the east perch: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.sanctuary_kestrel_fed else "Grab a herring by the west campfire\n")
			s += "• [i]Optional Drill:[/i] Pass Hendrick's Topman Knot-Speed Board: " + ("[color=#9fd4a3]Mastered[/color]\n" if GameState.sanctuary_drill_mastered else "Try the training post beside Hendrick\n")
			s += "• String the Gorge Wind-Pennant for Matthijs & inspect spares with Hendrick: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.sanctuary_pennants_strung else "Help Bellman Matthijs on the eastern timber walkway\n")
			s += "• Wash & oil [i]Virelai[/i]'s blistered wing-hinge and hear her out: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.sanctuary_virelai_talk_done else "Approach Virelai calmly on the landing shelf\n")
			s += "• Check with Captain Anna once ready to take the forward rig on Coast Patrol."
		else:
			s += "• [b]Year 5 (Age 17):[/b] Five years since Bruges. Seasoned forward harness-man under Captain Anna.\n"
			s += "• Receive fitted Brotherhood Flight-Jerkin from Matthijs & bid farewell to Hendrick and Maren: " + ("[color=#9fd4a3]Done[/color]\n" if GameState.sanctuary_jerkin_earned else "Speak with Matthijs by the chart-table\n")
			s += "• Meet Anna & Virelai at the cliff perch for the Eastern Ridge Storm Recon."
		s += "\n• [color=#f2d17a]Trust with Dragons:[/color] %d%%" % GameState.dragon_trust
	elif GameState.current_step == GameState.QuestStep.ACT2_VIRELAI_SORTIE_1:
		s += "• [b]Flight Sortie 1 — Coastline Updrafts:[/b] Crewing [i]Virelai[/i]'s forward rig with Anna.\n"
		s += "• Catch coastal updraft currents, roll clear of red ballista lock-lines, shatter hunter capture nets, and log any wild dragons in your Bestiary."
	elif GameState.current_step == GameState.QuestStep.ACT2_VIRELAI_SORTIE_2:
		s += "• [b]Flight Sortie 2 — Eastern Ridge Storm Recon:[/b] Heavy thunderheads over the border.\n"
		s += "• Use storm cloud banks to shake ballista aim, keep [i]Virelai[/i]'s port ring mended under squalls, and free the trapped Crimson Acid-Spitter."
	elif GameState.current_step == GameState.QuestStep.ACT3_WILDS_TRACKING:
		s += "• Thrown clear of Virelai's rig when an unknown black dragon hit us in the storm.\n"
		s += "• Broken boughs, bloodied ash-scales, and a forest ravine trail lead deeper west and north—look for Anna's dropped Border Chart and follow signs of the crashed dragon."
	elif GameState.current_step == GameState.QuestStep.ACT3_EGG_TREK:
		s += "• Carrying the black dragon's egg tucked inside my hemp sling (Last area: %s).\n" % GameState.active_wilds_zone
		s += "• Rely on smoldering watch-fires to preserve the shell's heat and navigate the Whispering Pines by Anna's survey landmarks."
	elif GameState.current_step == GameState.QuestStep.BOOK1_WATCHTOWER_HEARTH:
		s += "• Warmed the obsidian-and-gold egg beside the Watchtower Hearth until living golden veins stirred inside.\n"
		s += "• Speak with Captain Anna to ride back across the clouds to the Bruges Sanctuary."
	elif GameState.current_step == GameState.QuestStep.ACT4_SANCTUARY_DEBATE:
		if GameState.city_bounty_overheard:
			s += "• Overheard the Church Priest & Inquisitor inside Bruges Keep: a bounty on any black-with-gold egg!\n"
			s += "• Speak with Anna carefully—don't let the Council learn how closely the Hunters are closing in."
		else:
			s += "• Returned to the Bruges Sanctuary with the unhatched black-with-gold egg. Hendrick and the Council want to take it.\n"
			s += "• Leave via the Western Path to investigate the Church commotion stirring inside the Walled City of Bruges."
	elif GameState.current_step == GameState.QuestStep.ACT4_BRUGES_CITY:
		s += "• [b]Walled City of Bruges:[/b] Uncover what the Church is staging across the canals.\n"
		s += "• Town Rumors (Optional): Factor Joris at Cloth Hall " + ("[color=#9fd4a3](Asked)[/color]" if GameState.city_clue_cloth_hall else "(Grote Markt)") + " & Sister Beatrijs " + ("[color=#9fd4a3](Asked)[/color]\n" if GameState.city_clue_beguinage else "(Beguinage)\n")
		s += "• Counting-House Wharf Wagon: " + ("[color=#9fd4a3]Dropped Note Found ('St. Donatian\'s at 8th bell')[/color]\n" if GameState.city_clue_counting_house else ("Pick up the note dropped beside the wagon!\n" if GameState.city_watergate_skirmish_won else "Inspect the Church iron-chain wagon west across the canal\n"))
		s += "• St. Donatian's Church -> Main Keep: " + ("[color=#9fd4a3]Bounty Overheard![/color]\n" if GameState.city_bounty_overheard else ("Wait behind the cathedral pulpit until the eighth bell, then tail the priest!\n" if GameState.all_city_clues_found() else "Follow town whispers to find where the Church wagon unloaded"))
	elif GameState.current_step == GameState.QuestStep.ACT4_NIGHT_HEIST:
		s += "• [b]Midnight Sanctuary Heist:[/b] Tonight the egg stays with me—the Council won't take it.\n"
		s += "• Slip past Night-Watch lanterns, cut alarm tripwires with `[V]`, bind threats with `[F]`, grab the Egg from the center pedestal, and reach Kestrel on the east perch!"
	elif GameState.current_step >= GameState.QuestStep.BOOK2_BRABANT_FENS:
		s += "• [b]Book II — The Golden Heir:[/b] Riding east into Brabant beside Kestrel with the Black-and-Gold Egg.\n"
		s += "• [color=#f2d17a]Active Perspective:[/color] %s   •   [color=#f2d17a]Golden Bond:[/color] %d%%" % ["Captain Anna & Virelai" if GameState.active_perspective == "anna" else GameState.player_name, GameState.dragon_bond]
		if GameState.city_heat > 0.0:
			s += "   •   [color=#e07a6a]Church Heat:[/color] %d%%" % int(round(GameState.city_heat))
	if GameState.shuttle_pouch_recovered and not GameState.clara_gift_received:
		s += "\n• Return Clara's Brass Shuttle pouch to her."
	elif GameState.clara_gift_received:
		s += "\n• [color=#9fd4a3]Clara's Gift:[/color] Louvain Beeswax & Brass Thimble (+1 Knot Integrity, +25% Cinch Zone, +20% Cast Range)."
	return s


static func get_bestiary_bbcode() -> String:
	var lines := "[color=#f2d17a][b]FIELD SKETCHES & NOTES[/b][/color]\n"
	lines += "[i]Kept by %s — Port of Bruges[/i]\n\n" % GameState.player_name
	lines += "[b]1. Brabant Woods (Four Years Ago)[/b]\n"
	lines += "[color=#d96b6b]\"Ma and Pa never walked back out from Old Heverlee. Everyone said a dragon caught them in the trees. Let the Church Hunters shoot every last wyrm out of the sky.\"[/color]\n\n"

	if GameState.current_step >= GameState.QuestStep.DAWN_MISSING_CLARA:
		lines += "[b]2. Captain Anna & Virelai[/b]\n"
		if GameState.sanctuary_phase >= 3 or GameState.flight_sortie2_done:
			lines += "[color=#d96b6b][s]\"Outlaw riders using dragon-leather and Bruges cordage to snatch people in the dark.\"[/s][/color]\n"
			lines += "[color=#9fd4a3]\"Five winters flying her forward shoulder-rig (Age %d). Virelai speaks little unless asked, yet waits on the edge of every gale for her crew to hook in safely. I still can't forgive whatever killed Ma and Pa at Old Heverlee, and I haven't stopped looking for Clara—yet Virelai and Kestrel have saved my skin more times than any townsman ever did.\"[/color]\n\n" % GameState.boy_age
		elif GameState.sanctuary_virelai_talk_done or GameState.flight_sortie1_done:
			lines += "[color=#d96b6b][s]\"Outlaw riders using dragon-leather and Bruges cordage to snatch people in the dark.\"[/s][/color]\n"
			lines += "[color=#9fd4a3]\"Cleaned salt-crust under Virelai's wing-hinge before the coast sortie. When I asked why wild beasts butchered my parents, she didn't lie or snarl—just explained what steel harpoons and net-winches drive a terrified mother to do. She even banks mid-bolt so I keep my footing.\"[/color]\n\n"
		elif GameState.virelai_harness_spliced:
			lines += "[color=#d96b6b][s]\"Outlaw riders using dragon-leather and Bruges cordage to snatch people in the dark.\"[/s][/color]\n"
			lines += "[color=#9fd4a3]\"Spliced the green beast's shoulder-ring. Thought she'd snap my arm off—she only watched me with one pale yellow eye and held still. Master Hendrick watches every stitch like a hawk, yet shares bread without lecturing.\"[/color]\n\n"
		elif GameState.current_step >= GameState.QuestStep.ACT2_SANCTUARY:
			lines += "[color=#d96b6b][s]\"Outlaw riders using dragon-leather and Bruges cordage to snatch people in the dark.\"[/s][/color]\n"
			lines += "[color=#9fd4a3]\"Captain Anna kept her crew from leaving me to the Inquisitor, hauled me to a sea-cliff Sanctuary, and put me to work under Saddler Hendrick and Sister Maren. I mend leather for my keep, not because I trust wyrms.\"[/color]\n\n"
		else:
			lines += "[color=#d96b6b]\"Thick oiled harness-leather left at our door, cinched with Clara's own knot. The outlaw riders the priest warned about must have taken her.\"[/color]\n\n"
	else:
		lines += "[color=#888480][b]2. ???[/b] (Undiscovered)[/color]\n\n"

	if GameState.greyling_documented:
		lines += "[b]3. Silver-Slate Coastal Courier ('Kestrel')[/b]\n"
		if GameState.sanctuary_phase >= 3:
			lines += "[color=#9fd4a3]\"Five winters grown: full-shouldered coastal courier rigged in stitched Brotherhood dispatch leather, standing the size of a stout draft-horse beside Virelai yet quick enough to wheel along cliff updrafts.\"[/color]\n\n"
		elif GameState.sanctuary_kestrel_fed:
			lines += "[color=#9fd4a3]\"Mended courier who leaps three yards straight off the shelf to snap salt herring out of the air. When you toss high, her slate wings flare wide like a seabird's.\"[/color]\n\n"
		elif GameState.sanctuary_greyling_treated:
			lines += "[color=#9fd4a3]\"Compact coastal courier with salt-scarred pinions Sister Maren salved with cliffsage poultice. When I reached through with warm herbs instead of iron tongs, Kestrel tucked her chin against my sleeve instead of biting.\"[/color]\n\n"
		else:
			lines += "[color=#9fd4a3]\"Compact coastal courier—gray-silver wings built to tuck onto masts and cliff crags. When the hunter wing-clasp snapped and the heavy net fell slack, I braced for teeth—she only shivered in the straw.\"[/color]\n\n"
	else:
		lines += "[color=#888480][b]3. ???[/b] (Ch. 2 — Sanctuary Gorge)[/color]\n\n"

	if GameState.flight_documented_breeds.has("Ochre Gale-Wing") or GameState.flight_documented_breeds.has("Yellow Reaper"):
		lines += "[b]4. Ochre Gale-Wing (Wild Coast Breed)[/b]\n"
		lines += "[color=#9fd4a3]\"Ochre-gold middleweight with sweeping sail-wings. Freed one from a hunter net off the sandbars—wheeled beside Virelai twice like she remembered Anna's call before banking seaward.\"[/color]\n\n"
	else:
		lines += "[color=#888480][b]4. ???[/b] (Sketch mid-flight on Coast Patrol)[/color]\n\n"

	if GameState.flight_documented_breeds.has("Crimson Acid-Spitter") or GameState.flight_documented_breeds.has("Longwing"):
		lines += "[b]5. Crimson Acid-Spitter[/b]\n"
		lines += "[color=#9fd4a3]\"Fierce amber-and-rose wingspan. Anna kept Virelai well clear of its jaw—swears wild Acid-Spitters spray blistering venom when cornered by net-hunters.\"[/color]\n\n"
	else:
		lines += "[color=#888480][b]5. ???[/b] (Sketch mid-flight on Storm Recon)[/color]\n\n"

	if GameState.black_dragon_found:
		lines += "[b]6. Shadow-Guardian (Black-Scaled)[/b]\n"
		lines += "[color=#9fd4a3]\"Dull obsidian scales like cold slag—nothing like any sketch in Anna's saddlebags. A hunter's ballista bolt took her down. She had me cornered in the ash and never lifted a tooth; only shifted her wing off a warm black-and-gold egg before she stopped breathing.\"[/color]\n\n"
	else:
		lines += "[color=#888480][b]6. ???[/b] (Ch. 3 — Frontier Wilds)[/color]\n\n"

	if GameState.active_companion_stage >= 1:
		lines += "[b]7. %s (Stage %d Golden Lineage)[/b]\n" % [GameState.gold_dragon_name, GameState.active_companion_stage]
		lines += "[color=#f2d17a]\"Hatched from the soot-black shell streaked with gold. Sheds obsidian plates piece by piece as nourishment and ancient shrines awaken the Mythic Golden Dragon bloodline within.\"[/color]\n"
	return lines


static func get_controls_bbcode() -> String:
	var knot_list := ""
	if GameState.clara_gift_received:
		knot_list += "[color=#9fd4a3][b]★ CLARA'S GIFT (Louvain Beeswax & Thimble):[/b] +1 Max Knot Integrity (4), +25% Gold Cinch Zone, +20% Cast Range![/color]\n"
	if GameState.sanctuary_drill_mastered:
		knot_list += "[color=#9fd4a3][b]★ TOPMAN'S TIMING RING:[/b] +18% Gold Cinch Zone, +2.0s Knot Timer![/color]\n"
	if GameState.clara_gift_received or GameState.sanctuary_drill_mastered:
		knot_list += "\n"
	for kid in KnotCatalogScript.KNOT_ORDER:
		var kd: Dictionary = KnotCatalogScript.KNOT_DATA[kid]
		if GameState.unlocked_knots.has(kid):
			knot_list += "• [color=#f2d17a][b]%s[/b][/color] (%s)\n  [color=#9fd4a3]Ability:[/color] %s\n" % [kd["name"], kd["throw_style"], kd.get("ability", "")]
		else:
			knot_list += "• [color=#7a7874]??? (Locked)[/color] — %s\n" % kd.get("subtitle", "")
	var move_str := "%s/%s/%s/%s / Arrows" % [
		GameState.get_action_key_label("move_up"),
		GameState.get_action_key_label("move_left"),
		GameState.get_action_key_label("move_down"),
		GameState.get_action_key_label("move_right"),
	]
	var shift_k := GameState.get_action_key_label("sprint")
	var e_k := GameState.get_action_key_label("interact")
	var f_k := GameState.get_action_key_label("rope_action")
	var v_k := GameState.get_action_key_label("knife_attack")
	var c_k := GameState.get_action_key_label("dodge")
	var r_k := GameState.get_action_key_label("dragon_command")
	var x_k := GameState.get_action_key_label("dragon_posture")
	var q_k := GameState.get_action_key_label("cycle_knot")
	var i_k := GameState.get_action_key_label("inventory_screen")
	var k_k := GameState.get_action_key_label("practice_knot")
	var m_k := GameState.get_action_key_label("toggle_map")
	var j_k := GameState.get_action_key_label("journal")

	return (
		"[color=#f2d17a][b]KNOTCRAFT ABILITIES & FIELD CONTROLS[/b][/color]\n\n"
		+ knot_list
		+ "\n[color=#f2d17a][b]ON-FOOT & DRAGONBACK CONTROLS[/b][/color]\n"
		+ "[%s] Move / Steer Virelai   |   [%s] Run / Wing-Boost\n" % [move_str, shift_k]
		+ "[%s / Space] Interact / Bestiary Aerial Sketch   |   [%s / Right-Click] Cast Knot / Mid-Air Splice\n" % [e_k, f_k]
		+ "[%s / Left-Click] Dock Knife Slash / Cut Briars / Bolts   |   [%s] Dodge-Roll / Barrel-Roll\n" % [v_k, c_k]
		+ (("[%s] Dragon Assist   |   [%s] Companion Posture (Assist/Stay/Sling)\n" % [r_k, x_k]) if (GameState.active_companion_stage >= 1 or GameState.current_step >= GameState.QuestStep.BOOK2_BRABANT_FENS) else "")
		+ "[%s] Switch Knot   |   [%s] Character & Bag   |   [%s] Tie Board Practice   |   [%s] Map   |   [%s] Diary   |   [Esc] Pause / Settings   |   [F1] Jump" % [q_k, i_k, k_k, m_k, j_k]
	)
