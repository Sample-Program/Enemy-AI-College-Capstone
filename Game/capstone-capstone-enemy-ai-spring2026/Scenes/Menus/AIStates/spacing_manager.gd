class_name SpacingManager
extends Object

const SPACING = {
	"margin": 10,
	"padding": 16,
	"section_gap": 16,
	"element_gap": 8,
	"item_gap": 2,
	"button_gap": 8,
}

static func apply_spacing(debug_menu: Control):
	"""Apply all spacing to the debug menu"""
	
	var main_vbox: VBoxContainer = debug_menu.get_node("MainVBox")
	var background_panel: Panel = debug_menu.get_node("Background")
	var top_button_row: HBoxContainer = main_vbox.get_node("TopButtonRow")
	var state_buttons_row: HBoxContainer = main_vbox.get_node("StateButtonsRow")
	var npc_list_container: VBoxContainer = main_vbox.get_node("NPCScroll/NPCListContainer")
	var separator1: HSeparator = main_vbox.get_node("Separator1")
	var separator2: HSeparator = main_vbox.get_node("Separator2")
	var state_display: HBoxContainer = main_vbox.get_node("StateDisplay")
	var window: Window = debug_menu.get_node("Window")
	var state_graph: GraphEdit = window.get_node("StatesGraph")
	
	# Main container spacing
	main_vbox.add_theme_constant_override("separation", SPACING["element_gap"])
	
	# Push MainVBox away from panel edges
	main_vbox.position = Vector2(SPACING["margin"], SPACING["margin"])
	main_vbox.size = Vector2(
		background_panel.size.x - (SPACING["margin"] * 2),
		background_panel.size.y - (SPACING["margin"] * 2)
	)
	
	# Button row spacing
	top_button_row.add_theme_constant_override("separation", SPACING["button_gap"])
	state_buttons_row.add_theme_constant_override("separation", SPACING["button_gap"])
	
	# NPC list item spacing
	npc_list_container.add_theme_constant_override("separation", SPACING["item_gap"])
	
	# Separator spacing
	separator1.add_theme_constant_override("separation", SPACING["section_gap"])
	separator2.add_theme_constant_override("separation", SPACING["section_gap"])
	
	state_display.custom_minimum_size.y = 120
	
	window.size = Vector2i(500, 300)
	window.min_size = Vector2i(400, 200)
	
	state_graph.anchor_right = 1.0
	state_graph.anchor_bottom = 1.0
	state_graph.offset_right = 1.0
	state_graph.offset_bottom = 1.0
	state_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	state_graph.minimap_enabled = false
	
	# Make background panel fill the entire control
	background_panel.anchor_right = 1.0
	background_panel.anchor_bottom = 1.0
	background_panel.offset_right = 1.0
	background_panel.offset_bottom = 1.0
	
	npc_list_container.add_theme_constant_override("separation", 0)
	var npc_scroll: ScrollContainer = main_vbox.get_node("NPCScroll")
	npc_scroll.custom_minimum_size.y = 60
	npc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func set_root_position(debug_menu: Control):
	debug_menu.custom_minimum_size = Vector2(290, 480)
	
	debug_menu.anchor_left = 1.0
	debug_menu.anchor_top = 0.0
	debug_menu.anchor_right = 1.0
	debug_menu.anchor_bottom = 0.0
	
	debug_menu.offset_left = -300
	debug_menu.offset_top = 20
	debug_menu.offset_right = -20
	debug_menu.offset_bottom = 520
	
	debug_menu.show_behind_parent = false
	debug_menu.process_mode = Control.PROCESS_MODE_ALWAYS
