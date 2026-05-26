"""
    This script handles the main menu buttons for the game.
    It switches to the tutorial dungeon scene when Play is pressed
    and exits the game when Quit is pressed.
"""
extends Node2D

"""
    Called when the Play button is pressed. Loads and switches to 
	the Tutorial Dungeon scene.
"""
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/ClassPicker/PickClass.tscn")


"""
    Called when the Quit button is pressed. Exits the game application.
"""
func _on_quit_button_pressed() -> void:
		get_tree().quit()
