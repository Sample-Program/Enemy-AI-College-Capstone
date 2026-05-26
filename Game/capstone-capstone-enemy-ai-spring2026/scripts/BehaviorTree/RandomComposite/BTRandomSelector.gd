"""
Randomized Selector: Selector node that evaluates child nodes in a randomized order.
@authors: Sam Plemmons
"""
extends BTRandomComposite
class_name BTRandomSelector

"""
Evaluates each child node in a randomized order.

Builds a randomized child order if one does not already exist. Follows the same
logic as a standard selector: returns RUNNING if the current child is still
executing, SUCCESS if any child succeeds, and FAILURE if all children fail.
The randomized order is reset after a success or complete failure.
"""
func execute(delta: float, context: Dictionary) -> int:
	# Build order
	if order.is_empty():
		build_order()
	# Go through child nodes
	while child_index < order.size():
		# Get first child in the randomized order
		var child := get_child(order[child_index]) as BTNode
		if child == null:
			return BTNode.Status.FAILURE
		var result := child.tick(delta, context)
		# Selector logic
		if result == BTNode.Status.RUNNING:
			return BTNode.Status.RUNNING

		if result == BTNode.Status.SUCCESS:
			reset()
			return BTNode.Status.SUCCESS

		child_index += 1

	reset()
	return BTNode.Status.FAILURE
