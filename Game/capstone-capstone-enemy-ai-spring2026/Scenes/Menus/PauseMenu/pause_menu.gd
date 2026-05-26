"""
	This script handles the pause menu that appears when the
	user presses the escape key. It has several buttons,
	Quit, Return, AI States, and Main Menu.
"""
extends Control

## Pointers to nodes in the parent scene
@onready var main = $"../../../"
@onready var Main_Menu_Confirmation = $Main_Menu_Confirmation
@onready var Quit_Menu_Confirmation = $Quit_Menu_Confirmation
@onready var camera = $"../"
@onready var gui = $"../GUI"

@onready var debug_menu = $"../CanvasLayer/DebugMenu"

"""
	The ready function that run's before the game boot's up, set's signal 
	for popup_closed for the AIStates Return Button
"""
func _ready():
	# Needed so mouse clicks can still be registered even though
	# the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

# ========== Main Menu ==========
"""
	What happens when the user selects the Main Menu button.
"""
func _on_main_menu_pressed() -> void:
	Main_Menu_Confirmation.dialog_text = "Return to Main Menu? \
	Any unsaved progress will be lost."
	Main_Menu_Confirmation.popup_centered()
 
"""
	Confirmed: go to the main menu scene.
"""
func _on_main_menu_confirmation_confirmed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(
		"res://Scenes/Menus/MainMenu/MainMenu.tscn")
 
"""
	Cancelled: just hide the confirmation dialog.
"""
func _on_main_menu_confirmation_canceled() -> void:
	Main_Menu_Confirmation.hide()
 
# ========== Quit ==========
"""
	What happens when the user selects the Quit button.
"""
func _on_quit_button_pressed() -> void:
	Quit_Menu_Confirmation.dialog_text = "Are you sure you want to quit?"
	Quit_Menu_Confirmation.popup_centered()
 
"""
	Confirmed: quit the application.
"""
func _on_quit_menu_confirmation_confirmed() -> void:
	get_tree().quit()
 
"""
	Cancelled: just hide the confirmation dialog.
"""
func _on_quit_menu_confirmation_canceled() -> void:
	Quit_Menu_Confirmation.hide()
 
# ========== Return ==========
"""
	What happens when the user selects the Return button.
	The debug menu stays visible if it was already open —
	the player returns to gameplay with it as an overlay.
"""
func _on_return_pressed() -> void:
	if not gui.visible:
		gui.show()
	main.pause_menu()

# ========== AI States ==========
"""
	What happens when the user selects the AI States button.
	Hides the pause menu UI, activates the debug menu overlay,
	and resumes the game so state transitions are visible live.
"""
func _on_ai_states_pressed() -> void:
	# Hide the pause menu itself
	main.Pause_Menu.hide()
	main.GUI.hide()
	
	# Activate the debug menu
	debug_menu.activate()
