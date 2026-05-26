"""
Stunned Node: Action node that stops the enemy while stunned.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTStunned

var stun_icon: Sprite2D

"""
Initializes the stunned action.

@param icon: Sprite used to display the stun status effect.
"""
func _init(icon: Sprite2D):
	display_name = "BTStunned"
	stun_icon = icon

"""
Stops the enemy's movement and resets its stun buildup.

The stun value is reset so the enemy can build up stun again after recovering.
"""
func execute(_delta: float, context: Dictionary) -> int:
	var agent = context.get("self")
	agent.velocity = Vector2.ZERO
	agent.move_and_slide()
	#agent.add_status("stun", stun_icon)
	#reset stun value to zero for stunning again later
	agent.cur_stun_val = 0
	return BTNode.Status.SUCCESS
