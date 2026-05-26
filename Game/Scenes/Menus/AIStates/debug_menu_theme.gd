class_name DebugMenuTheme
extends Object

const COLORS = {
	"background": Color("#1a1a2e", 0.92),
	"panel_border": Color("#4a4a6a"),
	"title": Color("#ffaa44"),
	"text": Color("#e0e0e0"),
	"text_secondary": Color("#aaaaaa"),
	"state_idle": Color(0.20, 0.75, 0.45),
	"state_wander": Color(0.20, 0.50, 0.90),
	"state_chase": Color(0.80, 0.65, 0.20),
	"state_search": Color(0.70, 0.40, 0.85),
	"state_attack": Color(0.95, 0.75, 0.20),
	"state_retreat": Color(0.90, 0.35, 0.35),
	"state_hurt": Color(0.40, 0.60, 0.90),
	"state_stunned": Color(0.20, 0.50, 0.90),
	"state_dead": Color(0.90, 0.35, 0.35),
	"state_btselector": Color(0.20, 0.75, 0.45),
	"state_btsequence": Color(0.20, 0.50, 0.90),
	"state_btdecorator": Color(0.80, 0.65, 0.20),
	"state_btparallel": Color(0.70, 0.40, 0.85),
	"state_btcondition": Color(0.95, 0.75, 0.20),
	"state_btaction": Color(0.90, 0.35, 0.35),
	"state_btcheckarea": Color(0.40, 0.60, 0.90),
	"state_btplayanimation": Color(0.40, 0.85, 0.75),
	"state_btmove": Color(0.20, 0.50, 0.90),
	"state_btrandomselector": Color(0.90, 0.35, 0.35),
	"state_btcheckstatus": Color(0.95, 0.75, 0.20),
	"state_btcheckhealth": Color(0.40, 0.85, 0.75),
	"state_btcheckfordeadenemies": Color(0.70, 0.40, 0.85),
	"state_btresurrectattack": Color(0.90, 0.35, 0.35),
	"state_btcooldown": Color(0.60, 0.60, 0.65),
	"state_btsuperattack": Color(0.95, 0.30, 0.30),
	"button_normal": Color("#2a2a3a"),
	"button_hover": Color("#3a3a4a"),
	"button_pressed": Color("#1a1a2a"),
	"checkbox_checked": Color("#4caf50"),
	"checkbox_unchecked": Color("#757575"),
	"scrollbar": Color("#6a6a8a"),
	"unkown": Color("757575")
}




const SPACING = {
	"margin": 16,
	"padding": 16,
	"section_gap": 16,
	"element_gap": 8,
	"item_gap": 2,
	"button_gap": 8,
}

static func apply_theme(debug_menu: Control):
	"""Apply all theme settings to the debug menu"""
	
	# Get references to UI elements
	var background_panel: Panel = debug_menu.get_node("Background")
	var main_vbox: VBoxContainer = debug_menu.get_node("MainVBox")
	var title_label: Label = main_vbox.get_node("TitleLabel")
	var npc_section_label: Label = main_vbox.get_node("NPCSectionLabel")
	var state_display: HBoxContainer = main_vbox.get_node("StateDisplay")
	var left_label: RichTextLabel   = state_display.get_node("LeftLabel")
	var right_label: RichTextLabel  = state_display.get_node("RightLabel")
	var pause_button: Button = main_vbox.get_node("PauseButton")
	var close_button: Button = main_vbox.get_node("CloseButton")
	var graph_button: Button = main_vbox.get_node("GraphButton")
	
	# Apply background panel style
	var panel_style = create_panel_style()
	background_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Title styling
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", COLORS["title"])
	
	# Section labels
	npc_section_label.add_theme_font_size_override("font_size", 14)
	npc_section_label.add_theme_color_override("font_color", COLORS["text"])
	
	# Hiding the fact there are 2 RichText's by merging labels
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color("#1a1a2e", 0.0)  # fully transparent — inherits panel bg
	bg.set_border_width_all(0)
	
	for label in [left_label, right_label]:
		label.add_theme_font_size_override("normal_font_size", 14)
		label.add_theme_stylebox_override("normal", bg)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		label.bbcode_enabled = true
		# prevents scrollbars breaking the illusion
		label.scroll_active = false  
	
	state_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Center all labels
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	npc_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Style all buttons
	style_all_buttons(debug_menu)
	
	# Style pause and close button's differently
	pause_button.add_theme_color_override("font_color", Color("#aaffaa"))
	close_button.add_theme_color_override("font_color", Color("#ffaaaa"))
	graph_button.add_theme_color_override("font_color", Color("#aaaaff"))

static func style_all_buttons(debug_menu: Control):
	"""Apply consistent styling to all buttons"""
	var main_vbox: VBoxContainer = debug_menu.get_node("MainVBox")
	
	# Get button containers
	var top_button_row: HBoxContainer = main_vbox.get_node("TopButtonRow")
	var state_buttons_row: HBoxContainer = main_vbox.get_node("StateButtonsRow")
	var pause_button: Button = main_vbox.get_node("PauseButton")
	var close_button: Button = main_vbox.get_node("CloseButton")
	var graph_button: Button = main_vbox.get_node("GraphButton")
	
	top_button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_buttons_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Style buttons in top row
	for button in top_button_row.get_children():
		if button is Button:
			style_button(button)
	
	# Style buttons in state row
	for button in state_buttons_row.get_children():
		if button is Button:
			style_button(button)
	
	# Style pause, close and graph buttons
	style_button(pause_button)
	pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	style_button(close_button)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	style_button(graph_button)
	graph_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

static func style_button(button: Button):
	"""Apply styling to an individual button"""
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Fill available width
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL    # Fill available height
	button.add_theme_font_size_override("font_size", 13)
	
	# Create button styles
	var normal_style = create_button_style(COLORS["button_normal"], Color("#4a4a6a"), 6)
	var hover_style = create_button_style(COLORS["button_hover"], Color("#6a6a8a"), 6)
	var pressed_style = create_button_style(COLORS["button_pressed"], Color("#8a8aaa"), 6)
	var disabled_style = create_button_style(COLORS["button_normal"] * Color(1,1,1,0.5), Color("#4a4a6a"), 6)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)

static func create_button_style(bg_color: Color, border_color: Color, corner_radius: int,
								 margin_left: int = 12, margin_top: int = 4, margin_bottom: int = 4) -> StyleBoxFlat:
	"""Create a styled button StyleBox"""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(1)
	style.border_color = border_color
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = margin_left
	style.content_margin_right = margin_left
	style.content_margin_top = margin_top
	style.content_margin_bottom = margin_bottom
	return style

static func create_panel_style() -> StyleBoxFlat:
	"""Create the main panel background style"""
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS["background"]
	style.set_border_width_all(1)
	style.border_color = COLORS["panel_border"]
	style.set_corner_radius_all(12)
	style.content_margin_left = SPACING["padding"]
	style.content_margin_right = SPACING["padding"]
	style.content_margin_top = SPACING["padding"]
	style.content_margin_bottom = SPACING["padding"]
	return style

static func style_dynamic_checkbutton(check_button: CheckButton):
	"""Style checkbuttons that are created dynamically"""
	check_button.add_theme_font_size_override("font_size", 13)
	
	var normal_style = create_check_style(Color("#1e1e2e"), Color("#3a3a5a"), 4, 8, 6, 6)
	var hover_style = create_check_style(Color("#2a2a3a"), Color("#4a4a6a"), 4, 8, 6, 6)
	
	check_button.add_theme_stylebox_override("normal", normal_style)
	check_button.add_theme_stylebox_override("hover", hover_style)

static func create_check_style(bg_color: Color, border_color: Color, corner_radius: int,
								margin_left: int = 8, margin_top: int = 6, margin_bottom: int = 6) -> StyleBoxFlat:
	"""Create a styled checkbutton StyleBox"""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(1)
	style.border_color = border_color
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = margin_left
	style.content_margin_right = margin_left
	style.content_margin_top = margin_top
	style.content_margin_bottom = margin_bottom
	return style

static func get_state_name(state: int) -> String:
	match state:
		0: return "Idle"
		1: return "Wander"
		2: return "Chase"
		3: return "Search"
		4: return "Attack"
		5: return "Retreat"
		6: return "Hurt"
		7: return "Stunned"
		8: return "Dead"
		9: return "BTSelector"
		10: return "BTSequence"
		11: return "BTDecorator"
		12: return "BTParallel"
		13: return "BTCondition"
		14: return "BTAction"
		15: return "BTCheckArea"
		16: return "BTPlayAnimation"
		17: return "BTMove"
		18: return "BTRandomSelector"
		19: return "BTCheckStatus"
		20: return "BTCheckHealth"
		21: return "BTCheckForDeadEnemies"
		22: return "BTResurrectAttack"
		23: return "BTCooldown"
		24: return "BTSuperAttack"
		_: return "Unknown"

static func get_state_color(state: int) -> Color:
	"""Return color for different states"""
	match state:
		0: return COLORS["state_idle"]
		1: return COLORS["state_wander"]
		2: return COLORS["state_chase"]
		3: return COLORS["state_attack"]
		4: return COLORS["state_search"]
		5: return COLORS["state_retreat"]
		6: return COLORS["state_hurt"]
		7: return COLORS["state_stunned"]
		8: return COLORS["state_dead"]
		9: return COLORS["state_btselector"]
		10: return COLORS["state_btsequence"]
		11: return COLORS["state_btdecorator"]
		12: return COLORS["state_btparallel"]
		13: return COLORS["state_btcondition"]
		14: return COLORS["state_btaction"]
		15: return COLORS["state_btcheckarea"]
		16: return COLORS["state_btplayanimation"]
		17: return COLORS["state_btmove"]
		18: return COLORS["state_btrandomselector"]
		19: return COLORS["state_btcheckstatus"]
		20: return COLORS["state_btcheckhealth"]
		21: return COLORS["state_btcheckfordeadenemies"]
		22: return COLORS["state_btresurrectattack"]
		23: return COLORS["state_btcooldown"]
		24: return COLORS["state_btsuperattack"]
		100: return COLORS["unkown"]
		_: return COLORS["text"]
