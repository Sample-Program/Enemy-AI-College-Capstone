"""
Cooldown Node: Decorator node that prevents its child from running until a cooldown has passed.
@authors: Sam Plemmons
"""
extends BTDecorator
class_name BTCooldown

var cooldown_time: float
var last_time: float = 0


"""
Initializes the cooldown decorator.

@param seq: Child node controlled by this cooldown.
@param cooldown: Time in seconds before the child can run again.
"""
func _init(seq: BTNode, cooldown: float):
	display_name = "BTCooldown"
	child = seq
	cooldown_time = cooldown

"""
Runs the child node only if the cooldown has finished.

Returns FAILURE while the cooldown is still active. If the child succeeds,
the current time is stored so the cooldown can begin again.
"""
func execute(delta: float, context: Dictionary) -> int:
	# Get game time in seconds
	var current_time = Time.get_ticks_msec() / 1000.0
	# Still on cooldown
	if (current_time - last_time) < cooldown_time:
		return BTNode.Status.FAILURE
	# Run child node
	var result = child.execute(delta, context)
	# If child was successful, reset cooldown
	if result == BTNode.Status.SUCCESS:
		last_time = current_time
	return result
