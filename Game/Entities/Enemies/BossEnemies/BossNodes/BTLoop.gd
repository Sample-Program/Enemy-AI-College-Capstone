"""
Loop Node: Decorator node that repeats its child until failure or until a loop limit is reached.
If loop_count is -1, the child loops indefinitely until it fails. If loop_count
is set to a positive value, the child loops until it fails or completes the
specified number of successful executions.
@authors: Sam Plemmons
"""
extends BTDecorator
class_name BTLoop

var loop_count: int = -1
var current_count: int = 0

"""
Initializes the loop decorator.

@param child_node: Child node that will be repeated.
@param count: Number of successful executions before stopping. Use -1 for infinite looping.
"""
func _init(child_node: BTNode, count: int = -1):
	display_name = "BTLoop"
	child = child_node
	loop_count = count

"""
Runs the child node repeatedly.

If the child fails, the loop stops and returns SUCCESS. If the child is still
running, this node returns RUNNING. If the child succeeds, the loop either
runs again or stops once the loop count has been reached.
"""
func execute(delta: float, context: Dictionary) -> int:
	if child == null:
		return BTNode.Status.FAILURE 
	var result = child.execute(delta, context)
	match result:
		# Node Failed and we will end the loop
		BTNode.Status.FAILURE:
			current_count = 0
			return BTNode.Status.SUCCESS
		BTNode.Status.RUNNING:
			return BTNode.Status.RUNNING
		BTNode.Status.SUCCESS:
			current_count += 1
			# loop
			if loop_count == -1 or current_count < loop_count:
				return execute(delta, context)
			else:
				current_count = 0
				return BTNode.Status.SUCCESS
	# fallback (ends loop)
	current_count = 0
	return BTNode.Status.SUCCESS
