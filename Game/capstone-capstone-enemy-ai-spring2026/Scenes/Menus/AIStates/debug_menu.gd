extends Control

@onready var pause_menu = $"../../Pause_Menu"
 
# UI References
@onready var main_vbox: VBoxContainer = $MainVBox
@onready var background_panel: Panel = $Background
@onready var title_label: Label = $MainVBox/TitleLabel
@onready var top_button_row: HBoxContainer = $MainVBox/TopButtonRow
@onready var clear_all_button: Button = $MainVBox/TopButtonRow/RefreshButton
@onready var select_all_button: Button = $MainVBox/TopButtonRow/SelectAllButton
@onready var npc_section_label: Label = $MainVBox/NPCSectionLabel
@onready var npc_scroll: ScrollContainer = $MainVBox/NPCScroll
@onready var npc_list_container: VBoxContainer = $MainVBox/NPCScroll/NPCListContainer
@onready var separator1: HSeparator = $MainVBox/Separator1
@onready var state_display_left: RichTextLabel  = $MainVBox/StateDisplay/LeftLabel
@onready var state_display_right: RichTextLabel = $MainVBox/StateDisplay/RightLabel
@onready var separator2: HSeparator = $MainVBox/Separator2
@onready var state_buttons_row: HBoxContainer = $MainVBox/StateButtonsRow
@onready var idle_button: Button = $MainVBox/StateButtonsRow/IdleButton
@onready var wander_button: Button = $MainVBox/StateButtonsRow/WanderButton
@onready var chase_button: Button = $MainVBox/StateButtonsRow/ChaseButton
@onready var attack_button: Button = $MainVBox/StateButtonsRow/AttackButton
@onready var pause_button: Button = $MainVBox/PauseButton
@onready var close_button: Button = $MainVBox/CloseButton
@onready var graph_button: Button = $MainVBox/GraphButton
@onready var state_graph: GraphEdit = $Window/StatesGraph
@onready var window: Window = $Window

# Selection and state
var selected_npcs: Array = []
var _last_registered_npc: Node = null
var game_paused: bool = false
var npc_active_bt_nodes: Dictionary = {}
 
# Tracks one tween per selected NPC for highlight fade
var npc_tweens: Dictionary = {}
 
# Whether world-click selection is active
var ai_states_active: bool = false
 
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	clear_all_button.text = "Clear All"
	window.hide()
	
	SpacingManager.set_root_position(self)
	DebugMenuTheme.apply_theme(self)
	setup_signals()
	disable_state_buttons(true)
	
	# Defer spacing so the panel has its real size by the time we read it
	call_deferred("_apply_spacing_deferred")
	
	hide()

func _apply_spacing_deferred():
	SpacingManager.apply_spacing(self)
 
func setup_signals():
	clear_all_button.pressed.connect(_on_clear_all_pressed)
	select_all_button.pressed.connect(_on_select_all_pressed)
	idle_button.pressed.connect(_on_set_state_idle)
	wander_button.pressed.connect(_on_set_state_wander)
	chase_button.pressed.connect(_on_set_state_chase)
	attack_button.pressed.connect(_on_set_state_attack)
	pause_button.pressed.connect(_on_pause_button_pressed)
	close_button.pressed.connect(_on_close_pressed)
	graph_button.pressed.connect(_on_graph_pressed)
	window.close_requested.connect(_on_window_closed)
 
# ========== Activation (called by Pause Menu) ==========
func activate():
	"""Called by the pause menu when the player enters AI States mode."""
	ai_states_active = true
	show()
	if game_paused == false:
		_on_pause_button_pressed()
 
func deactivate():
	"""Called if the debug menu should be fully closed and selection mode ended."""
	ai_states_active = false
	_on_clear_all_pressed()
	hide()
 
# ========== Live State Display ==========
func _process(_delta):
	"""Continuously refresh the state display while the menu is open."""
	
	if visible and not selected_npcs.is_empty():
		update_state_display()
 
# ========== World-Click NPC Selection ==========
func _unhandled_input(event):
	if not ai_states_active:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_npc_click()
 
func handle_npc_click():
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	
	var all_npcs = get_tree().get_nodes_in_group("enemies")
	var closest_npc = null
	var closest_dist = INF
	const CLICK_RADIUS = 32.0  # adjust to match your enemy's rough size
	
	for npc in all_npcs:
		if not is_instance_valid(npc):
			continue
		var dist = npc.global_position.distance_to(world_pos)
		if dist < closest_dist and dist < CLICK_RADIUS:
			closest_dist = dist
			closest_npc = npc
		
	if closest_npc != null:
		if closest_npc in selected_npcs:
			deselect_npc(closest_npc)
		else:
			select_npc(closest_npc)
 
# ========== NPC Selection / Deselection ==========
func select_npc(npc: Node):
	"""Add an NPC to the selection, highlight it, and add it to the list."""
	if npc in selected_npcs:
		return
	
	selected_npcs.append(npc)
	highlight_npc(npc)
	add_npc_to_list(npc)
	
	if npc != null:
		if "tree" in npc and npc.tree != null:
			if npc.tree.has_signal("node_ticked"):
				var callable = _on_node_ticked.bind(npc)
				if not npc.tree.node_ticked.is_connected(callable):
					npc.tree.node_ticked.connect(callable)
			npc_active_bt_nodes[npc] = npc.tree.root
	
	update_state_display()
	
	# Show the most recently selected NPC in the graph visualizer
	if _last_registered_npc != npc:
		_last_registered_npc = npc
		state_graph.register_agent(npc)

func deselect_npc(npc: Node):
	"""Remove an NPC from the selection, fade its highlight, remove from list."""
	selected_npcs.erase(npc)
	unhighlight_npc(npc)
	remove_npc_from_list(npc)
	
	if npc != null:
		if "tree" in npc and npc.tree != null:
			if npc.tree.has_signal("node_ticked"):
				var bound = _on_node_ticked.bind(npc)
				if npc.tree.node_ticked.is_connected(bound):
					npc.tree.node_ticked.disconnect(bound)
	
	update_state_display()
	
	# If we deselected the currently visualized NPC, switch to another or clear
	if npc == _last_registered_npc:
		if selected_npcs.is_empty():
			state_graph.clear_graph()
			_last_registered_npc = null
		else:
			_last_registered_npc = selected_npcs.back()
			state_graph.register_agent(_last_registered_npc)

# ========== Highlight Tweens ==========
func highlight_npc(npc: Node):
	"""Flash the NPC blue to confirm selection. Tween is paused mid-fade."""
	var sprite = npc.get_node_or_null("sprite_animations")
	if sprite == null:
		return
	
	# Kill any existing tween for this NPC
	if npc in npc_tweens and npc_tweens[npc] != null:
		npc_tweens[npc].kill()
	
	sprite.modulate = Color.ROYAL_BLUE
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)
	tween.pause()  # Hold the highlight while the NPC is selected
	
	npc_tweens[npc] = tween

func unhighlight_npc(npc: Node):
	"""Resume the fade tween so the NPC returns to its normal colour."""
	if npc in npc_tweens and npc_tweens[npc] != null:
		npc_tweens[npc].play()
		npc_tweens.erase(npc)

# ========== NPC List UI ==========
func add_npc_to_list(npc: Node):
	"""Add a labelled row for this NPC to the scroll list."""
	for child in npc_list_container.get_children():
		if child.get_meta("npc", null) == npc:
			return
	
	var check_button = CheckButton.new()
	check_button.text = npc.name
	check_button.button_pressed = true  # Checked by default
	check_button.set_meta("npc", npc)
	DebugMenuTheme.style_dynamic_checkbutton(check_button)
	npc_list_container.add_child(check_button)
 
func remove_npc_from_list(npc: Node):
	"""Remove this NPC's row from the scroll list."""
	for child in npc_list_container.get_children():
		if child.get_meta("npc", null) == npc:
			child.queue_free()
			return
 
# ========== Button Handlers ==========
func _on_clear_all_pressed():
	"""Deselect every NPC and clear the list."""
	# Iterate over a copy since deselect_npc modifies selected_npcs
	for npc in selected_npcs.duplicate():
		deselect_npc(npc)
 
func _on_select_all_pressed():
	"""Select every NPC currently in the scene."""
	var all_npcs = get_tree().get_nodes_in_group("enemies")
	for npc in all_npcs:
		select_npc(npc)

func _on_close_pressed():
	pause_menu.show()
	deactivate()

func _on_graph_pressed():
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	window.size = Vector2i(500, 300)
	if window.visible == false:
		window.show()
	else:
		window.hide()

func _on_window_closed():
	window.hide()

# ========== State Display ==========
func update_state_display():
	"""Removes or Adds NPC's from display if selected or not"""
	# Removes any NPC's from display that are no longer selected
	selected_npcs = selected_npcs.filter(func(npc): return is_instance_valid(npc))
	
	if selected_npcs.is_empty():
		state_display_left.text = "[b] [/b]"
		state_display_right.text = "[b] [/b]"
		return
	
	state_display_left.bbcode_enabled = true
	state_display_right.bbcode_enabled = true
	
	var left_text = "[b]Selected NPCs:[/b]\n"
	var right_text = "[b] [/b]\n" # blank line to match the title row height
	
	for i in selected_npcs.size():
		var npc = selected_npcs[i]
		var current_state
		if npc.has_method("get_current_state"):
			if npc.has_signal("state_changed"):
				current_state = npc.get_current_state()
			elif npc.tree.has_signal("node_ticked") and npc in npc_active_bt_nodes:
				#var active_node = npc_active_bt_nodes[npc]
				#var node_name = active_node.display_name if active_node.display_name != "" else active_node.get_script().get_global_name()
				#current_state = get_state_name(node_name)
				current_state = get_state_name("BTSelector")
			else:
				#if npc in npc_active_bt_nodes:
				#	current_state = get_state_name(npc.tree.root)
				current_state = get_state_name("Unkown")
		else:
			current_state = get_state_name("Unkown")
		
		var state_name = DebugMenuTheme.get_state_name(current_state)
		var color = DebugMenuTheme.get_state_color(current_state)
		var entry = "[color=#%s]• %s:\n  %s[/color]\n" % [color.to_html(false), npc.name, state_name]
		
		if i % 2 == 0:
			left_text += entry
		else:
			right_text += entry
		
		if _last_registered_npc != null:
			state_graph.register_agent(_last_registered_npc)
		
		state_display_left.text = left_text
		state_display_right.text = right_text

# ========== State Change Handlers ==========
func _on_set_state_idle():
	_set_state_for_selected("idle")
 
func _on_set_state_wander():
	_set_state_for_selected("wander")
 
func _on_set_state_chase():
	_set_state_for_selected("chase")
 
func _on_set_state_attack():
	_set_state_for_selected("attack")
 
func _set_state_for_selected(new_state: String):
	"""Change state for all selected NPCs. Only allowed while paused."""
	if not game_paused:
		print("[DEBUG] Cannot change state — game not paused")
		return
	
	for child in npc_list_container.get_children():
		if child is CheckButton and child.button_pressed:
			var npc = child.get_meta("npc", null)
			if npc and is_instance_valid(npc) and npc.has_method("_set_state"):
				var state_change = get_state_name(new_state)
				npc._set_state(state_change)
				if state_change == 8:
					remove_npc_from_list(npc)
				print("[DEBUG] Set ", npc.name, " to state: ", new_state)
	
	update_state_display()
 
static func get_state_name(state: String) -> int:
	match state.to_lower():
		"idle": return 0
		"wander": return 1 
		"chase": return 2
		"search": return 3
		"attack": return 4
		"retreat": return 5
		"hurt": return 6
		"stunned": return 7
		"dead": return 8
		"btselector": return 9
		"btsequence": return 10
		"btdecorator": return 11
		"btparallel": return 12
		"btcondition": return 13
		"btaction": return 14
		"btcheckarea": return 15
		"btplayanimation": return 16
		"btmove": return 17
		"btrandomselector": return 18
		"btcheckstatus": return 19
		"btcheckhealth": return 20
		"btcheckfordeadenemies": return 21
		"btresurrectattack": return 22
		"btcooldown": return 23
		"btsuperattack": return 24
		_: return 100

func _on_node_ticked(node: BTNode, status: int, npc: Node) -> void:
	if status == 1:
		npc_active_bt_nodes[npc] = node

# ========== Pause Toggle ==========
func disable_state_buttons(disabled: bool):
	idle_button.disabled = disabled
	wander_button.disabled = disabled
	chase_button.disabled = disabled
	attack_button.disabled = disabled
 
func _on_pause_button_pressed():
	game_paused = !game_paused
	
	if game_paused:
		get_tree().paused = true
		pause_button.text = "Resume Game"
		disable_state_buttons(false)
		print("[DEBUG] Game paused — state changes enabled")
	else:
		get_tree().paused = false
		pause_button.text = "Pause Game"
		disable_state_buttons(true)
		print("[DEBUG] Game resumed — state changes disabled")
