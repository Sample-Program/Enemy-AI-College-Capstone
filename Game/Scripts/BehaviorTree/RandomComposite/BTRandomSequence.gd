"""
Randomized Sequence: Sequence node that evaluates child nodes in a randomized order.
@authors: Sam Plemmons
"""
extends BTRandomComposite
class_name BTRandomSequence

"""
Evaluates each child node in a randomized order.

Builds a randomized child order if one does not already exist. Follows the same
logic as a standard sequence: returns RUNNING if the current child is still
executing, FAILURE if any child fails, and SUCCESS only if every child succeeds.
The randomized order is reset after a failure or complete success.
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
		# Sequence logic
		if result == BTNode.Status.RUNNING:
			return BTNode.Status.RUNNING

		if result == BTNode.Status.FAILURE:
			reset()
			return BTNode.Status.FAILURE

		child_index += 1

	reset()
	return BTNode.Status.SUCCESS
