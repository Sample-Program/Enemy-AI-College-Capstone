"""
	This script acts as a wrapper, as attaching the existing Pathfinding.gd
	script was causing issues. This script will most likely eventually replace
	the old Pathfinding.gd script, but as of right not it is not a priority.
"""

extends "res://scripts/EnemyPathfinding/Pathfinding.gd"
##Wrapper for right now? It's fighting me when I attach the script so..... whatever

"""
	This function is called when the node enters the scene tree for the
	first time.
"""
func _ready() -> void:
	pass # Replace with function body.

"""
	This function is called every frame.
"""
func _process(_delta: float) -> void:
	pass
