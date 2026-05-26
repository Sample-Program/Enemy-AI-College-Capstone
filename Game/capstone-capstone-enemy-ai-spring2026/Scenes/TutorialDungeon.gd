"""
	This script sets various variables that are used in the scene. This makes sure
	that theres a reference to the pause menu, the GUI, and enables the pathfinding
	to use the TileMapLayers once they are fully loaded in.
"""

extends Node2D

## Pointer's to child node's of the Player node
@onready var Pause_Menu = $"PlayerBase/TheCamera/Pause_Menu"
@onready var GUI = $"PlayerBase/TheCamera/GUI"
var paused = false

"""
	This function is called when the node enters the scene tree for the 
	first time. This makes sure that the pathfinding can access the correct
	TileMapLayers once they are ready to be referenced.
"""
func _ready() -> void:
	var pathfinding = $Pathfinding
	var tilemap_layer = $"/root/NavMeshTesting/NavigationRegion2D/Grass"
	pathfinding.create_navigation_map(tilemap_layer)

"""
	This function is called every frame. It handles checking for when the user presses
	the pause button.
"""
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not get_tree().paused:
		pause_menu()

"""
	This function handles how the pause menu is shown to the user.
"""
func pause_menu() -> void:
	if paused:
		Pause_Menu.hide()
		get_tree().paused = false
	else:
		Pause_Menu.show()
		get_tree().paused = true
	
	paused = !paused
