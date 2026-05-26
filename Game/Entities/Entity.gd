"""
	This script handles all entities in the game. Almost all of the enemies, objects,
	and any instance of the Player will extend from here. This is the overarching 'Parent'
	of all things that have health, resistance, damged, and damage_taken attributes.
	@author: Sam Plemmons
"""

extends CharacterBody2D

## CLass for all interactable entities on the scene
class_name Entity

## Main fields of an entity class
var health: int
var resistance: float
var damaged: bool = false
var damage_taken: float

"""
	This function sets the health of the entity. 
	@param: How much hp to set
	@author: Sam Plemmons
"""
func set_health(hp: int) -> void:
	health = hp

"""
	This function gets the health of the entity. 
	@author: Sam Plemmons
"""
func get_health() -> int:
	return health

"""
	This function sets the field for the whether the entity was damaged. 
	@param: Whether it was damaged or not
	@author: Sam Plemmons
"""
func set_damaged(dmg: bool) -> void:
	damaged = dmg

"""
	This returns whether the entity was damaged or not.
	@author: Sam Plemmons
"""
func is_damaged() -> bool:
	return damaged

"""
	This function returns how much damage was taken. 
	@author: Sam Plemmons
"""
func get_damage_taken() -> float:
	return damage_taken

"""
	This function sets the resistance field. This is how much an entity can resist 
	damage taken. 
	@author: Sam Plemmons
"""
func set_resistance(resist: float) -> void:
	resistance = resist

"""
	This function returns how much resistance the entity has. 
	@author: Sam Plemmons
"""
func get_resistance() -> float:
	return resistance

"""
	This function handles when an entity takes damage. It also changes the damaged 
	boolean to true as well. 
	@author: Sam Plemmons
"""
func take_damage(dmg_taken: int) -> void:
	print("----------\nTESTING: Damage Info\n----------")
	print("Health Before Attack: ", health)
	damage_taken = (dmg_taken * get_resistance())
	health -= (dmg_taken * get_resistance())
	print("Health After Attack: ", health)
	print("Damage Taken: ", (damage_taken * get_resistance()))
	set_damaged(true)
