class_name SanctuaryNarrative
extends RefCounted

## Scripted multi-year character interactions, Brotherhood dragon-trust dialogues,
## and time-skip transition montages for SanctuaryRegion (Age 12 -> 14 -> 17).

const SanctuaryMontageCutsceneScript := preload("res://scripts/regions/SanctuaryMontageCutscene.gd")
const SanctuaryAct4Script := preload("res://scripts/regions/SanctuaryAct4.gd")


static func intro_after_abduction(r) -> void:
	r.ui.set_fade(1.0, true)
	r.ui.set_fade(0.0, false)
	r.player.set_cutscene_pose("", false, true)
	r.ui.show_dialogue([
		{"speaker": "Hooded Captain", "portrait": "portrait_anna.png", "text": "Pull the blindfold off him. Watch your boots along the drop, boy."}
	], func():
		r.player.set_cutscene_pose("")
		SoundManager.play_door()
		r.ui.show_dialogue([
			{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Keep that thing back! What did you do with my sister?!"},
			{"speaker": "Hooded Captain", "portrait": "portrait_anna.png", "text": "We don't abduct ropewalk girls. Church-backed slavers strip salvaged wyrm-hide straps off shot wild dragons to truss prisoners—and force Bruges's finest cordage weavers to braid heavy suppression harnesses inland."},
			{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Liar! Then why knock me out on the cobbles?!"},
			{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Because three steps more would have brought an Inquisitor's torch down on everyone here. Name's Anna. You want bread and answers? Start under Saddler Hendrick by the south rack."}
		])
	)


static func interact_hendrick(r) -> void:
	if GameState.sanctuary_phase == 1:
		if GameState.sanctuary_carrying_item == "leather":
			GameState.sanctuary_carrying_item = ""
			GameState.sanctuary_leather_chore_done = true
			GameState.add_dragon_trust(10)
			SoundManager.play_knot_cinch()
			SoundManager.play_chime()
			r.ui.refresh_hud()
			r.ui.show_dialogue([
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Set it across the trestle. Not bad—you carry heavy cordage like a real river-lad, not a soft clerk."},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Why soften dragon-leather with tallow if these beasts tear steel chains apart?"},
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Raw straps saw straight into wing-sinew in wet weather. Keep a harness supple and she spares her skin; rush it and a rider drops three leagues. Take a look at Virelai's starboard shoulder-ring."}
			])
		elif not GameState.sanctuary_leather_chore_done:
			r.ui.show_dialogue([
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "So Anna dragged a Louvain-born dockrat out of the Zwin mist. Wipe that scowl off—while you stand on this cliff, you work for your porridge."},
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "My curing bench's running bare—there's salted wyrm-hide rolled down by the south store-crates if your back works better than your mouth."}
			])
		elif not GameState.virelai_harness_spliced:
			r.ui.show_dialogue([
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Hide's soaking well. See if Virelai holds still long enough for you to mend that frayed bronze shoulder-ring."}
			])
		else:
			r.ui.show_dialogue([
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Huh. Steady thumb-twist—better than half my greenhorns last spring. Sister Maren looked short-handed up by the northern cauldron."}
			])
	elif GameState.sanctuary_phase == 2:
		if not GameState.sanctuary_hendrick_y3_done:
			GameState.sanctuary_hendrick_y3_done = true
			GameState.add_dragon_trust(5)
			r.ui.show_dialogue([
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Two winters on and you've put an inch on your wrists, %s. Good fit in that tan apprentice leather—not a Bruges dockrat anymore." % GameState.player_name},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Never let a wet salt-knot freeze under a buckle. Old habit."},
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Keep it. Test your speed on that oak Drill Board beside my rack whenever you've a spare minute—clear the sand-glass cleanly and my Topman's Timing Ring is yours."}
			])
		else:
			var board_tip := " That oak speed-drill board beside me still wants breaking in if your fingers feel stiff." if not GameState.sanctuary_drill_mastered else ""
			r.ui.show_dialogue([
				{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Bellman Matthijs went over the east gorge testing wind-pennants, and Kestrel's squawking for scrap fish by the fire. Virelai also keeps glancing at her left wing-hinge." + board_tip}
			])
	elif GameState.sanctuary_phase == 4:
		r.ui.show_dialogue([
			{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Don't glare at me like I stole your purse, %s. An unknown black egg brings Church Catchpoles straight to our cliffs—as soon as you bring word back from Bruges, the elders decide where it's locked away." % GameState.player_name}
		])
	else:
		r.ui.show_dialogue([
			{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Five winters since I dropped a splicing needle in your fist, lad. Look at you in that oiled coat—broad enough across the ribs for a senior chest-band."},
			{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Wait till this gale clears, Hendrick. If scouts find any word out of Louvain or east of Bruges—"},
			{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "We haven't forgotten your sister, %s. Bring Anna and Virelai back whole through the thunderheads first." % GameState.player_name}
		])


static func interact_maren(r) -> void:
	if GameState.sanctuary_phase == 1:
		if GameState.sanctuary_carrying_item == "water":
			GameState.sanctuary_carrying_item = ""
			GameState.sanctuary_poultice_brewed = true
			GameState.add_item("Cliffsage Wing-Poultice")
			GameState.add_dragon_trust(5)
			SoundManager.play_chime()
			r.player.show_held_item(r.assets.get_tex("icon_poultice.png"), 1.2)
			r.ui.refresh_hud()
			r.ui.show_dialogue([
				{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Steady pour—mind the steam. Cliffsage, crushed yarrow, and wild honey soften scorched hide faster than mutton grease."},
				{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Keep the jar tucked near your chest so it stays warm—and gentle hands around a cornered dragon, alright?"}
			])
		elif not GameState.sanctuary_poultice_brewed:
			r.ui.show_dialogue([
				{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Easy, little shiphand—don't hover so stiff near the fire. Scouts rescued a young Greyling from a Church hunter wagon last night, still bleeding and bound in bolted iron wing-cuffs."},
				{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Can't steep cliffsage in an empty kettle—and my back won't haul a cold bucket up from the east spring today."}
			])
		elif not GameState.sanctuary_greyling_treated:
			r.ui.show_dialogue([
				{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "The jar's still warm—hurry back across the east chasm. Once those forged hunter shackles break loose, she'll need that salve fast."}
			])
		else:
			r.ui.show_dialogue([
				{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Did you see how quietly she tucked her snout against your sleeve once the stinging stopped? Even fear knows kindness when it smells warm herbs."}
			])
	elif GameState.sanctuary_phase == 2:
		r.ui.show_dialogue([
			{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Still drying bundles before frost, %s. Kestrel's wings healed clean last summer—you can visit her uncovered on the sunny east shelf." % GameState.player_name}
		])
	elif GameState.sanctuary_phase == 4:
		r.ui.show_dialogue([
			{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Rest easy, %s—I'm keeping fresh beech-coals stoked under that brazier stand myself. Hendrick won't lay a finger on your black egg while you're scouting inside Bruges." % GameState.player_name}
		])
	else:
		r.ui.show_dialogue([
			{"speaker": "Sister Maren", "portrait": "portrait_maren.png", "text": "Seventeen already, and tall enough to duck under the drying beam. Pack two linen rolls beneath your jerkin—storm winds carry cold sleet up high."}
		])


static func interact_matthijs(r) -> void:
	if GameState.sanctuary_phase == 2:
		if not GameState.sanctuary_pennants_strung:
			r.ui.show_dialogue([
				{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Hah—you took that chasm post one-handed like you've lived on ropes your whole life! Almost forgot you used to white-knuckle the plank bridge back at twelve."},
				{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Before you muster up for Coast Patrol, help me heave the east gale-pennant taut on that signal mast beside the drop. Tie a clean Bowline so we read wind-shear cleanly."}
			])
		else:
			r.ui.show_dialogue([
				{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Pennant's snapping crisp east-by-northeast! Head back west and check Virelai's wing-hinge before Anna blows takeoff."}
			])
	elif GameState.sanctuary_phase == 4:
		r.ui.show_dialogue([
			{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Half the camp's still shouting over that black-and-gold egg—half say take it off you and vault it at Ghent, half swear it belongs beside you. Go down the West Trail into Bruges and learn what the Church is mustering before first light!"}
		])
	else:
		if not GameState.sanctuary_jerkin_earned:
			GameState.sanctuary_jerkin_earned = true
			GameState.add_item("Brotherhood Flight-Jerkin")
			GameState.add_dragon_trust(10)
			SoundManager.play_chime()
			r.player.show_held_item(r.assets.get_tex("icon_jerkin.png"), 1.35)
			r.ui.refresh_hud()
			r.ui.show_dialogue([
				{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Catch—still smells of oak bark and beeswax. Hendrick stitched those extra brass D-rings under the arms for your seventeen-year-old reach."},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Fits clean across the shoulders... Beats my patched tan apprentice leather by ten miles."},
				{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Well, retire it at last, senior harness-man. Anna and Virelai are waiting at the cliff perch for the Eastern Ridge Storm Recon."}
			])
		else:
			r.ui.show_dialogue([
				{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Keep both waist-carabiners clipped in the thunderheads, %s. We'll light the cliff beacons till Virelai banks home." % GameState.player_name}
			])


static func interact_virelai_talk_y3(r) -> void:
	if GameState.sanctuary_phase == 2 and not GameState.sanctuary_virelai_talk_done:
		r.player.facing = Vector2.UP
		r.player.set_cutscene_pose("boy_kneel.png")
		r.ui.show_dialogue([
			{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Hold steady, girl—just scrubbing winter sea-salt out from under your wing-fold before the patrol."}
		], func():
			GameState.sanctuary_virelai_oiled = true
			GameState.sanctuary_virelai_talk_done = true
			GameState.add_dragon_trust(15)
			SoundManager.play_dragon_purr()
			r.virelai_splice_flash = 0.9
			r.player.set_cutscene_pose("")
			r.ui.refresh_hud()
			r.ui.show_dialogue([
				{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "Your hands are steadier than they were two snowfalls ago, young mariner. And colder water burns less than vinegar."},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "You usually stay silent around the trestle... Can I ask you something straight, Virelai?"},
				{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "You wish to ask about Old Heverlee. Anna never hid the Louvain reports about your parents."},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_angry.png", "text": "Four hunters went into the woods with hemp and torches, and none came home. Why should I trust any wyrm not to kill the moment she breaks chain?!"},
				{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "Because chains bring harpoons, fire, and crying eggs crushed in stone pits. Yet hear me carefully: I flew low above Old Heverlee two winters later, and no dragon's scorching breath scarred those beech trees—only broken hunter iron."},
				{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "Neither Anna nor I demand you forget the dead, %s. Only look with clear eyes—and beware those who pay gold to keep wild skies silent." % GameState.player_name},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "...Fair enough. Keep an eye on me up on that shoulder-rig today, alright?"}
			])
		)
	elif GameState.sanctuary_phase == 4:
		SoundManager.play_dragon_purr()
		r.ui.show_dialogue([
			{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "Your new charge sleeps peacefully above those beech-coals, %s. Neither Hendrick nor any cold vault will touch its shell while my wing covers the stand. Go see what mischief stirs inside Bruges." % GameState.player_name}
		])
	elif GameState.sanctuary_phase >= 3:
		SoundManager.play_dragon_purr()
		r.ui.show_dialogue([
			{"speaker": "Virelai", "portrait": "portrait_virelai.png", "text": "Five winters since a glaring boy tied my first brass snap-ring without blinking. You belong in the harness now, %s." % GameState.player_name}
		])


static func interact_anna(r) -> void:
	if GameState.sanctuary_phase == 1:
		if not GameState.sanctuary_leather_chore_done or not GameState.virelai_harness_spliced:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Old Hendrick says he's short leather on the south bench, and Virelai's shoulder-ring still wants a proper splice before dusk."}
			])
		elif not GameState.sanctuary_greyling_treated:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Virelai's ring is solid. Maren's still fussing over her northern kettle, and that rescued Silver-Slate courier across the gorge is still tangled in hunter iron until someone breaks her loose."}
			])
		else:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "You dressed Kestrel's torn wing and stopped flinching when Virelai breathes near you."},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Doesn't mean I belong here. As soon as winter breaks, I want word on Clara."},
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "And we've scouts watching every eastern road. Until we locate those hunter wagons, learn the clouds with us—no twelve-year-old rides a storm-sortie raw."}
			], func(): trigger_time_skip_to_year3(r))
	elif GameState.sanctuary_phase == 2:
		if not GameState.sanctuary_pennants_strung:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Wind's shifting off the sea. Matthijs went over the east gorge trying to string a fresh gale-pennant before patrol."}
			])
		elif not GameState.sanctuary_virelai_talk_done:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Streams read clean off the point. Virelai's left wing-hinge still has crusted sea-salt chafing under the bronze buckle if you've a damp cloth handy."}
			])
		elif not GameState.sanctuary_virelai_fed:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Not with Virelai eyeing an empty rack like that! Stockman Joost's out by the sheepfold if you've strong wrists for a cleaver."}
			])
		elif not GameState.flight_sortie1_done:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Two winters in the harness drill paid off, %s. Ready to man Virelai's forward bolt-rig above the Flemish coast?" % GameState.player_name},
				{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Hooks locked and belt cinch doubled. Take us up, Captain!"}
			], func(): r.director.load_region("flight", {"sortie": 1}))
	elif GameState.sanctuary_phase == 4:
		if GameState.city_bounty_overheard and not GameState.act4_lied_to_council:
			SanctuaryAct4Script._run_return_lie_dialogue(r)
		else:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Maren and I won't let Hendrick take your egg to the cold vaults while the coals are lit. Take the West Cliff Trail down into the Walled City of Bruges and find out what major action the Church is staging."}
			])
	else:
		if not GameState.sanctuary_jerkin_earned:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Don't climb into thunderheads in your old wool tunic—Matthijs and Hendrick left your fitted Flight-Jerkin beside the map table."}
			])
		elif not GameState.sanctuary_virelai_fed:
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Heavy storm-headwinds over the ridge today, %s. Visit Stockman Joost to butcher fresh mutton onto Virelai's rack before we mount up for Storm Recon." % GameState.player_name}
			])
		else:
			GameState.sanctuary_final_brief_done = true
			r.ui.show_dialogue([
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Five years since we hauled you out of a Bruges alley, %s. You can splice a carabiner blindfolded in crosswinds." % GameState.player_name},
				{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Lightning's banking hard over the eastern border ridge, and scouts caught a Crimson Acid-Spitter tangled near Church outriders. Climb aboard Virelai—stay tight on that forward strap."}
			], func(): r.director.load_region("flight", {"sortie": 2}))


static func handle_return_sortie1(r) -> void:
	GameState.flight_sortie1_done = true
	r.ui.show_dialogue([
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Touchdown clear on the perch! Not half bad for fourteen years old on your first live sortie!"},
		{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "...She wheeled smooth whenever I sighted down a ballista barrel. Never knew a dragon watched her own rigman like a sister watches a helm."},
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "She's listening to you, %s—season after season, gale after gale. Keep flying beside us." % GameState.player_name}
	], func(): trigger_time_skip_to_year5(r))


static func trigger_time_skip_to_year3(r) -> void:
	SanctuaryMontageCutsceneScript.start_montage(r, SanctuaryMontageCutsceneScript.KIND_YEAR3, true)


static func interact_drill_board(r) -> void:
	if not GameState.sanctuary_drill_mastered:
		r.ui.show_dialogue([
			{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Topman's Speed-Splice Board: whip and lock a full Brotherhood Harness Splice before the sand drops cleanly. Beat the post and wear my brass Timing Ring permanently."}
		], func():
			r.ui.open_knot_minigame("dragon_splice", func(_id):
				GameState.sanctuary_drill_mastered = true
				GameState.add_item("Brotherhood Topman's Timing Ring")
				GameState.add_dragon_trust(5)
				SoundManager.play_knot_cinch()
				SoundManager.play_chime()
				r.player.show_held_item(r.assets.get_tex("icon_carabiner.png"), 1.35)
				r.ui.refresh_hud()
				r.queue_redraw()
				r.ui.show_dialogue([
					{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Crack shot under pressure! Slide that brass Timing Ring onto your right thumb—every mid-air splice from today onward comes faster and cleaner."}
				])
			, func(_id):
				r.ui.show_dialogue([{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Bobbled a half-hitch on the turn! Step up again whenever you want another run at the Timing Ring."}])
			)
		)
	else:
		r.ui.open_knot_minigame("dragon_splice", func(_id):
			SoundManager.play_knot_cinch()
			r.ui.show_dialogue([{"speaker": "Saddler Hendrick", "portrait": "portrait_hendrick.png", "text": "Still lightning-quick, Topman! Keep those wrists warm for gale weather."}])
		)


static func kestrel_fed_dialogue(r) -> void:
	GameState.sanctuary_kestrel_fed = true
	GameState.add_dragon_trust(10)
	SoundManager.play_dragon_purr()
	SoundManager.play_chime()
	r.ui.refresh_hud()
	r.queue_redraw()
	r.ui.show_dialogue([
		{"speaker": "Bellman Matthijs", "portrait": "portrait_matthijs.png", "text": "Hah! One scrap fish from the hearth and she remembers your sleeve forever. No creature holds loyalty finer than a Silver-Slate courier."}
	])


static func trigger_time_skip_to_year5(r) -> void:
	SanctuaryMontageCutsceneScript.start_montage(r, SanctuaryMontageCutsceneScript.KIND_YEAR5, true)


static func interact_cook_mieke(r) -> void:
	var ph := GameState.sanctuary_phase
	if ph == 1:
		r.ui.show_dialogue([
			{"speaker": "Camp Cook Mieke", "portrait": "portrait_cook.png", "text": "Mind the kettle steam, dock-lad! Mutton pottage and barley bread stay hot on the long oak tables from noon bell till twilight watch."},
			{"speaker": GameState.player_name, "portrait": "portrait_boy_neutral.png", "text": "Didn't think outlaw dragon-folk kept two whole trestles just for dinner."},
			{"speaker": "Camp Cook Mieke", "portrait": "portrait_cook.png", "text": "Harness-men, scouts, and chirurgeons starve just as quick as dockworkers, boy. Grab a trencher whenever your knees shake from climbing rocks."}
		])
	elif ph == 2:
		r.ui.show_dialogue([
			{"speaker": "Camp Cook Mieke", "portrait": "portrait_cook.png", "text": "Look at how fast you sprout! Two winters ago you stood hunched by the post scowling at my stew ladle—now you lick the wooden bowl dry before Hendrick finishes grace."}
		])
	elif ph == 4:
		r.ui.show_dialogue([
			{"speaker": "Camp Cook Mieke", "portrait": "portrait_cook.png", "text": "Whole mess-yard heard you and Old Hendrick barking over that black-and-gold egg! Wrap some rye bread under your cloak before walking into Bruges tonight—Church bailiffs have sharpened every pike along the gates."}
		])
	else:
		r.ui.show_dialogue([
			{"speaker": "Camp Cook Mieke", "portrait": "portrait_cook.png", "text": "Beef broth and hard Damme cheese packed for high altitude, %s. Drink deep before Anna whistles mount-up—storm air steals heat straight through oiled leather." % GameState.player_name}
		])


static func interact_herdsman_bram(r) -> void:
	var ph := GameState.sanctuary_phase
	if ph == 1:
		r.ui.show_dialogue([
			{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Easy around the rails—no sudden waving near the pied bullocks. Keeping dragons secret on this ridge means hiding an appetite bigger than twenty plow-horses."},
			{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Cousins near Sluis smuggle ewes and old oxen up our back sheep-track after moonset. One beef quarter on Virelai's rack keeps her wing-muscles strong without torching a farmer's fold."}
		])
		return
	if ph >= 4:
		r.ui.show_dialogue([
			{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Even the ewes looked up when Hendrick started yelling about taking that black egg away from you! Keep your collar high inside Bruges's walls, %s—scouts swear half the Catchpoles in Flanders rode in before dusk." % GameState.player_name}
		])
		return
	if not GameState.sanctuary_virelai_fed:
		if GameState.sanctuary_carrying_item == "mutton":
			r.ui.show_dialogue([
				{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Clean quartering already done, lad! Carry that mutton joint back over the timber bridge and hang it on Virelai's Butcher Rack west of her perch."}
			])
		elif GameState.sanctuary_carrying_item != "":
			r.ui.show_dialogue([
				{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Set down whatever your hands are full with first—takes two steady wrists on the cleaver handle to portion dragon-rations cleanly."}
			])
		else:
			var intro_line := "Coast Patrol lifts in twenty minutes, lad! Help me cleave a cured Sluis ewe into four whole quarters on the block—splintered ribs choke an emerald's throat." if ph == 2 else "Black clouds piling fast over Brabant—and Virelai flies hungriest into a headwind! Grab my heavy cleaver and cut four clean mutton joints before launch."
			r.ui.show_dialogue([
				{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": intro_line}
			], func():
				r.ui.open_butcher_minigame(func():
					GameState.sanctuary_carrying_item = "mutton"
					GameState.add_dragon_trust(5)
					SoundManager.play_crate_pickup()
					r.player.show_held_item(r.assets.get_tex("icon_mutton.png"), 1.3)
					r.ui.refresh_hud()
					r.queue_redraw()
					r.ui.show_dialogue([
						{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Dead on every seam—no bone splinters! Bring that quarter over to Virelai's rack before the crows smell blood."}
					])
				)
			)
		return
	if ph == 2:
		r.ui.show_dialogue([
			{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Lambing went quiet this spring and not one Church bailiff sniffed our smoke. Watch how sleek Virelai's flanks stay when she's fed proper pasture mutton."}
		])
	else:
		r.ui.show_dialogue([
			{"speaker": "Stockman Joost", "portrait": "portrait_herdsman.png", "text": "Five winters since you jumped at a sheep-dog barking behind my barn! Pasture gates are latched tight for tonight's gale, topman—fly safe above those black clouds."}
		])


static func interact_virelai_butcher_rack(r) -> void:
	if GameState.sanctuary_carrying_item != "mutton" or r.virelai_eat_timer > 0.0:
		return
	GameState.sanctuary_carrying_item = ""
	GameState.sanctuary_virelai_fed = true
	GameState.add_dragon_trust(10)
	r.virelai_eat_timer = 1.65
	r.player.facing = Vector2.RIGHT
	r.player.can_move = false
	SoundManager.play_dragon_chomp()
	SoundManager.play_dragon_purr()
	r.ui.refresh_hud()
	r.queue_redraw()


static func virelai_fed_dialogue(r) -> void:
	SoundManager.play_chime()
	r.ui.refresh_hud()
	r.queue_redraw()
	r.ui.show_dialogue([
		{"speaker": "Captain Anna", "portrait": "portrait_anna.png", "text": "Look at her crests lift—well portioned, %s. Whenever you're ready at the harness board, patrol's yours to whistle off." % GameState.player_name}
	])


static func interact_victual_stall(r) -> void:
	r.victual_flash = 0.85
	SoundManager.play_crate_pickup()
	r.spawn_fx_burst(Vector2(302, 580), 8, Color(0.98, 0.86, 0.44), 24.0, 56.0, 0.45, 2.2)
	r.queue_redraw()


static func interact_covert_watch(r) -> void:
	if GameState.sanctuary_phase == 4:
		r.ui.show_dialogue([
			{"speaker": "Brotherhood Scout", "portrait": "portrait_brotherhood.png", "text": "Iron-shod wagons and Church horns have been crowding the South Port Gate of Bruges City since sunset. Something major's brewing behind those ramparts."}
		])
		return
	r.ui.show_dialogue([
		{"speaker": "Brotherhood Scout", "portrait": "portrait_brotherhood.png", "text": "Fog lies thick over the bridge gorge tonight—no patrol lanterns moving along the polder dyke below. Crew bunkhouse and pastures rest easy behind the mist."}
	])


static func interact_livestock_pen(r, kind: String) -> void:
	var pen_pos := Vector2(1375, 495)
	var col := Color(0.92, 0.84, 0.56)
	match kind:
		"sheep":
			pen_pos = Vector2(1375, 495)
			SoundManager.play_blip(1.35)
		"cow":
			pen_pos = Vector2(1320, 625)
			SoundManager.play_blip(0.55)
		_:
			pen_pos = Vector2(1015, 625)
			SoundManager.play_blip(0.85)
	r.livestock_bounce_kind = kind
	r.livestock_bounce_timer = 0.65
	r.spawn_fx_burst(pen_pos, 7, col, 22.0, 54.0, 0.45, 2.4)
	r.queue_redraw()
