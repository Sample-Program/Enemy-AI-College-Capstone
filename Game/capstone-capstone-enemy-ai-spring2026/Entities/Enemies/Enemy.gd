"""
	This class handles all states for the enemies as well as some basic methods that
	they will all use. Any enemy that exists in the scene will extend from this class
	and be required to use states.
	@author: Sam Plemmons
"""

extends Entity

class_name Enemy

## Enums for Enemy States
# IDLE: fallback stationary state
# WANDER: idle walking state
# CHASE: chasing target
# ATTACK: attacking chased target
# RETREAT: the enemy retreat from the player
# DEAD: when the enemy hits 0 hp
enum EnemyState {IDLE, WANDER, CHASE, SEARCH, ATTACK, RETREAT, HURT, STUNNED, DEAD}

## Variables for State Management
var current_state: EnemyState
var previous_state: EnemyState

## Critical Health
var critical: bool

## TESTING
var target: CharacterBody2D

## Pathfinding
var pathfinding: Pathfinding
var path: Array[Vector2] = []
var current_path_index := 0
var repath_timer := 0.0
const REPATH_TIME = 0.2

"""
	Gets the current state of the enemy.
	@author: Sam Plemmons
"""
func get_current_state() -> EnemyState:
	return current_state
	
"""
	Gets the previous state of the enemy.
	@author: Sam Plemmons
"""
func get_previous_state() -> EnemyState:
	return previous_state

"""
	Sets the current state to a new state.
	@author: Sam Plemmons
"""
func _set_state(new_state: EnemyState):
	# update previosu state
	previous_state = current_state
	# update current state
	current_state = new_state

"""
	This method returns true if an enemy is in the CHASE state.
	@author: Sam Plemmons
"""
func _is_chasing():
	if current_state == EnemyState.CHASE:
		return true
	else:
		return false

"""
	This method returns whether the enemy's health has reached the critical
	threshold.
	@author: Sam Plemmons
"""
func is_critical() -> bool:
	return critical

"""
	This sets whether or not the enemy has reached critical health. 
	@author: Sam Plemmons
"""
func set_critical(crit: bool) -> void:
	critical = crit

"""
	This returns the current target of the enemy.
	@author: Sam Plemmons
"""
func get_target() -> CharacterBody2D:
	return target

"""
	This sets the enemy's current target. 
	@author: Sam Plemmons
"""
func set_target(tar: CharacterBody2D) -> void:
	target = tar
	
"""
	Helper method that gets the position of 'moving obstacles' such as other entities. 
	It creates an array of positions where these entities are and then returns the array of
	positions that these entities are occupying.
	@param ignore: An array of entities to ignore
	@param next_tile: The next tile to go to (-9999 so any value is smaller)
"""
func get_moving_obstacles(ignore: Array = [], _next_tile: Vector2i = Vector2i(-9999, -9999)) -> Array[Vector2i]:
	# array to build
	var obstacles: Array[Vector2i] = []
	
	# Get all the enemies in the group (we want to look for other enemies)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or ignore.has(enemy):
			continue
		var tile = pathfinding.grass_layer.local_to_map(pathfinding.grass_layer.to_local(enemy.global_position))
		obstacles.append(tile)
	
	# Get all the objects in the group (training dummy + etc)
	for obj in get_tree().get_nodes_in_group("objects"):
		if ignore.has(obj): # Ignore the training dummy
			continue  
		var tile = pathfinding.grass_layer.local_to_map(pathfinding.grass_layer.to_local(obj.global_position))
		obstacles.append(tile)
	
	return obstacles

"""
	This method retrieves a point near the specified ally instead of the exact location
	the ally is standing on. Prevents collision issues and other pathfinding issues. 
	@param: The enemy we want to get a point near
"""
func get_point_near_ally(enemy: Enemy) -> Vector2:
	# double check we can access
	if pathfinding == null:
		return enemy.position
	
	# Build moving obstacles 
	var obstacles = get_moving_obstacles([enemy])
	
	# Get full path (enemy tile may be unwalkable)
	var full_path := pathfinding.avoid_entities(global_position, enemy.global_position, obstacles)
	
	# make sure theres even a path
	if full_path.size() == 0:
		return enemy.position  # fallback
	
	# If the path only has 1 tile, use that
	if full_path.size() == 1:
		return full_path[0]
	
	# Return the second-to-last point (which is the tile right before the enemy)
	return full_path[full_path.size() - 2]

"""
	Helper method that draws a line for the entities generated path. This shows the path that was found
	via the algorithm.
"""
func _draw():
	if path.size() > 1:
		for i in range(path.size() - 1):
			draw_line(to_local(path[i]), to_local(path[i + 1]), Color.RED, 2)
