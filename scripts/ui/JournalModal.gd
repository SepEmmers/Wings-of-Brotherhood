extends PanelContainer

## 4-Tab Character Sheet, Satchel Inventory, Boy's Diary, Field Bestiary, & Knots Modal.

signal close_requested

const CharacterInventoryPanelScript := preload("res://scripts/ui/CharacterInventoryPanel.gd")
const JournalLoreDataScript := preload("res://scripts/data/JournalLoreData.gd")

var tab_idx: int = 0
var tab_btns: Array[Button] = []
var inv_screen: HBoxContainer
var journal_text: RichTextLabel


func setup(assets_ref) -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -390
	offset_top = -255
	offset_right = 390
	offset_bottom = 255
	visible = false
	assets_ref.style_parchment_panel(self)

	var j_vbox := VBoxContainer.new()
	j_vbox.add_theme_constant_override("separation", 10)
	add_child(j_vbox)

	var j_tabs := HBoxContainer.new()
	j_tabs.add_theme_constant_override("separation", 8)
	j_vbox.add_child(j_tabs)

	tab_btns.clear()
	for t_info in [
		[0, "1. Character & Bag [I]"],
		[1, "2. Boy's Diary [Tab]"],
		[2, "3. Field Bestiary"],
		[3, "4. Knots & Controls"]
	]:
		var tb := Button.new()
		tb.text = t_info[1]
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx: int = t_info[0]
		tb.pressed.connect(func():
			SoundManager.play_ui_click()
			tab_idx = idx
			refresh()
		)
		j_tabs.add_child(tb)
		tab_btns.append(tb)

	var j_close_btn := Button.new()
	j_close_btn.text = "X"
	j_close_btn.custom_minimum_size = Vector2(36, 30)
	j_close_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		visible = false
		emit_signal("close_requested")
	)
	j_tabs.add_child(j_close_btn)

	inv_screen = CharacterInventoryPanelScript.new()
	inv_screen.setup(assets_ref)
	j_vbox.add_child(inv_screen)

	journal_text = RichTextLabel.new()
	journal_text.bbcode_enabled = true
	journal_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_text.visible = false
	j_vbox.add_child(journal_text)


func apply_post_theme_fixes() -> void:
	if inv_screen != null:
		inv_screen.apply_slot_button_styles()


func refresh() -> void:
	for ti in range(tab_btns.size()):
		tab_btns[ti].modulate = Color(1.18, 1.05, 0.78) if ti == tab_idx else Color(0.84, 0.80, 0.76)

	var is_inv_tab := (tab_idx == 0)
	if inv_screen != null:
		inv_screen.visible = is_inv_tab
	if journal_text != null:
		journal_text.visible = not is_inv_tab

	if tab_idx == 0:
		if inv_screen != null:
			inv_screen.refresh()
	elif tab_idx == 2:
		journal_text.text = JournalLoreDataScript.get_bestiary_bbcode()
	elif tab_idx == 3:
		journal_text.text = JournalLoreDataScript.get_controls_bbcode()
	else:
		journal_text.text = (
			"[color=#f2d17a][b]%s's Pocket Notes[/b][/color]\n\n" % GameState.player_name
			+ "%s\n\n" % JournalLoreDataScript.get_diary_summary()
			+ "[color=#b9b3a3][i]Press [Tab], [J], or [I] to close.[/i][/color]"
		)
