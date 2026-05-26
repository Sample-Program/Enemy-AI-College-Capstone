"""
Change Collision Node: Action node that enables or disables a collision shape.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTChangeCollision

var change_collision: bool
var collision: CollisionShape2D

"""
Initializes the collision change action.

@param col: Collision shape to enable or disable.
@param ch_col: True to disable the collision shape, false to enable it.
"""
func _init(col: CollisionShape2D, ch_col: bool):
	display_name = "BTChangeCollision"
	collision = col
	change_collision = ch_col

"""
Enables or disables the assigned collision shape.
"""
func execute(_delta: float, context: Dictionary) -> int:
	# no more collision
	if change_collision:
		collision.disabled = true
	# enable collision
	else:
		collision.disabled = false
	return BTNode.Status.SUCCESS
