extends RefCounted

## City side stories for LouvainCityRegion (Bell-Founder Pieter, Herbalist Katelijne,
## Veteran Martijn, Tavern Aleidis, University Beadle Hendrik, and Master Mason Matthijs's
## Louvain vs. Brussels Sint-Pieterskerk spire-raising crane quest).


static func on_interact_clay(r) -> void:
	if GameState.louvain_clay_collected or GameState.louvain_bell_mould_fixed:
		return
	GameState.louvain_clay_collected = true
	GameState.add_item("Dijle River Clay")
	SoundManager.play_chime()
	r.ui.pulse_hud_icon("bag")


static func on_interact_pieter(r) -> void:
	if GameState.louvain_bell_mould_fixed:
		r.ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Listen to that bronze timbre ring cleanly across the Dijle! Carry those Resonance Chimes safely—ring one down an alley and Catchpoles chase echoes all day."}])
		return
	if GameState.louvain_clay_collected:
		r.ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Aye—fine blue Dijle clay! Now lay a tight rope hitch onto the foundry gantry wheel beside the mould so I can draw the jacket true."}])
		return
	r.ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "The Church Catchpoles ordered six alarm-bells overnight and cracked my master mould! Dig wet clay down by the Dijle river bank and haul my gantry pulley taut if you want proper bronze Resonance Chimes."}])


static func repair_foundry_hoist(r, MapData, _knot_id: String = "") -> void:
	if GameState.louvain_bell_mould_fixed:
		return
	if not GameState.louvain_clay_collected:
		r.ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Hold up lad—pack wet alluvial clay from the Dijle River Slip first before hoisting the casing!"}])
		return
	r.ui.open_knot_minigame("clove_hitch", func(_id: String):
		GameState.louvain_bell_mould_fixed = true
		GameState.remove_item("Dijle River Clay")
		GameState.resonance_chimes += 2
		GameState.add_item("Bronze Resonance Chime")
		GameState.add_dragon_bond(5)
		SoundManager.play_chime()
		r._spawn_sparks(MapData.FOUNDRY_WINCH_POS, Color(0.98, 0.86, 0.36), 14)
		r.ui.show_dialogue([{"speaker": "Bell-Founder Pieter", "portrait": "portrait_uncle.png", "text": "Seated tight as Flemish oak! Take two tuned Bronze Resonance Chimes—and slip into your hood whenever Catchpoles pace the bridge."}])
		r.ui.refresh_hud()
	)


static func on_interact_aleidis(r) -> void:
	GameState.louvain_guild_visited = true
	r.ui.refresh_hud()
	r.ui.show_dialogue([
		{"speaker": "Guildmistress Aleidis", "portrait": "portrait_clara.png", "text": "Bless me—you have your mother's eyes, %s! Years back after your parents rode out to Old Heverlee, they marched straight into this tavern and burned their Church hunting seals in the hearth." % GameState.player_name},
		{"speaker": "Guildmistress Aleidis", "portrait": "portrait_clara.png", "text": "Swore someone above St. Donatian's altar was excavating something older than Flanders. Two nights later, men in black tabards seized every deed from the Abbey Scriptorium northeast across the bridge."}
	])


static func on_interact_martijn(r) -> void:
	if GameState.louvain_survivor_done:
		r.ui.show_dialogue([{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "The High Inquisitor never told the parish a dragon killed your folks—he paid crossbowmen to ambush us by an ancient gold-carved stone vault in Old Heverlee."}])
		return
	if GameState.louvain_ring_found:
		GameState.louvain_survivor_done = true
		GameState.remove_item("Old Hunters' Brass Signet")
		GameState.add_dragon_bond(10)
		SoundManager.play_chime()
		r.ui.show_dialogue([
			{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "My old Oak-and-Hound signet! You pulled it back from those Abbey thieves..."},
			{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "Hear the truth then, boy: no beast slaughtered your mother and father at Old Heverlee. Church Inquisitors rode down our camp when your father refused to hand over a bronze shrine key they dug out beneath the oaks!"}
		])
		return
	r.ui.show_dialogue([{"speaker": "Veteran Martijn", "portrait": "portrait_watchman.png", "text": "Leave an old one-eyed hunter to his ale, lad... unless you pry my Oak-and-Hound signet ring back from the watch chest Catchpoles locked away east behind Tiensestraat."}])


static func on_interact_katelijne(r) -> void:
	if GameState.louvain_herbalist_done:
		r.ui.show_dialogue([{"speaker": "Sister Katelijne", "portrait": "portrait_maren.png", "text": "Keep those Smoke-Pellets beside your belt—cast one under foot if Catchpole crossbows lock the square, and search the garrison watch-crate east down Tiensestraat for confiscated guild trinkets."}])
		return
	r.ui.show_dialogue([{"speaker": "Sister Katelijne", "portrait": "portrait_maren.png", "text": "Rust wedged my dye-vat sluice shut while Catchpoles camp at the gate! Snap the jammed lever free with a strong rope or warm ember and I'll pack fresh Smoke-Pellets for you."}])


static func clear_herbalist_sluice(r, MapData) -> void:
	if GameState.louvain_herbalist_done:
		return
	GameState.louvain_herbalist_done = true
	GameState.smoke_pellets += 2
	GameState.add_item("Smoke-Pellet")
	GameState.add_dragon_bond(5)
	SoundManager.play_chime()
	r._spawn_sparks(MapData.HERBALIST_SLUICE_POS, Color(0.55, 0.90, 0.68), 16)
	r.ui.show_dialogue([{"speaker": "Sister Katelijne", "portrait": "portrait_maren.png", "text": "Clean water at last! Here—two ash-and-wax Smoke-Pellets. Oh, and Catchpoles dumped an old hunter's brass signet inside the garrison watch-chest east up Tiensestraat."}])
	r.ui.refresh_hud()


static func on_interact_ring_chest(r) -> void:
	if GameState.louvain_ring_found or GameState.louvain_survivor_done:
		return
	GameState.louvain_ring_found = true
	GameState.add_item("Old Hunters' Brass Signet")
	SoundManager.play_chime()
	r.ui.pulse_hud_icon("bag")


static func on_interact_mason(r) -> void:
	if GameState.louvain_mason_done:
		r.ui.show_dialogue([{"speaker": "Master Mason Matthijs", "portrait": "portrait_uncle.png", "text": "Look up at that pale limestone spire crowning Sint-Pieterskerk! Brussels' stewards can crane their necks all winter—Louvain touches the clouds first!"}])
		return
	if GameState.louvain_mason_stone_hauled:
		open_crane_builder(r)
		return
	GameState.louvain_mason_started = true
	r.ui.show_dialogue([
		{"speaker": "Master Mason Matthijs", "portrait": "portrait_uncle.png", "text": "Brussels brags their belfry spire will scrape the clouds first! My quarry barge docked over at Vismarkt Harbor Quay loaded with white Gobertange ashlar stone, then Catchpoles hauled the carter off."},
		{"speaker": "Master Mason Matthijs", "portrait": "portrait_uncle.png", "text": "Unlash that ashlar stone crate on Vismarkt Quay and man the timber hoist crane right beside me—we'll stack the highest spire in Brabant!"}
	])


static func on_interact_mason_stone(r, MapData) -> void:
	if GameState.louvain_mason_stone_hauled or GameState.louvain_mason_done:
		return
	GameState.louvain_mason_started = true
	GameState.louvain_mason_stone_hauled = true
	GameState.add_item("Gobertange Ashlar Load")
	SoundManager.play_chime()
	r._spawn_sparks(MapData.MASON_STONE_POS, Color(0.95, 0.90, 0.72), 14)
	r.ui.pulse_hud_icon("bag")
	r.ui.show_dialogue([{"speaker": GameState.gold_dragon_name, "telepathic": true, "text": "Pale quarry limestone in our satchel—Matthijs's hoist crane by Sint-Pieterskerk is ready when we are."}])


static func open_crane_builder(r) -> void:
	if GameState.louvain_mason_done:
		return
	if not GameState.louvain_mason_stone_hauled:
		GameState.louvain_mason_started = true
		r.ui.show_dialogue([{"speaker": "Master Mason Matthijs", "portrait": "portrait_uncle.png", "text": "Nothing left to sling yet, apprentice! Fetch our lashed Gobertange Ashlar Crate down on Vismarkt Stone Quay west across the bridge first."}])
		return
	r.ui.open_mason_minigame(func():
		complete_mason_spire(r)
	)


static func complete_mason_spire(r) -> void:
	if GameState.louvain_mason_done:
		return
	GameState.louvain_mason_done = true
	GameState.remove_item("Gobertange Ashlar Load")
	GameState.add_item("Master Mason's Plumb-Signet")
	GameState.boy_hp = GameState.boy_max_hp
	GameState.smoke_pellets += 1
	GameState.add_dragon_bond(15)
	SoundManager.play_chime()
	r._spawn_sparks(Vector2(1038, 512), Color(1.0, 0.88, 0.38), 28)
	r.ui.refresh_hud()
	r.ui.show_dialogue([
		{"speaker": "Master Mason Matthijs", "portrait": "portrait_uncle.png", "text": "By St. Peter's keys—every limestone course plumb and a slate spire piercing high above Brussels!"},
		{"speaker": "Master Mason Matthijs", "portrait": "portrait_uncle.png", "text": "Take my Guild Plumb-Signet, hot quarry rations for your belly, and an ash flask my apprentice found behind the cloister wall!"}
	])


static func on_interact_scholar(r) -> void:
	if GameState.louvain_mason_done:
		r.ui.show_dialogue([{"speaker": "Beadle Hendrik", "portrait": "portrait_watchman.png", "text": "Ha! Two Brussels aldermen nearly choked on their abbey ale peering up at Sint-Pieterskerk's new limestone spire—Matthijs sends his regards!"}])
		return
	r.ui.show_dialogue([{"speaker": "Beadle Hendrik", "portrait": "portrait_watchman.png", "text": "Mind the cobbles beneath De Lakenhalle's arches, lad—the Duke's new 1425 University masters lodge upstairs above the Cloth Hall looms, and Catchpoles have been questioning every clerk carrying Latin ink."}])
