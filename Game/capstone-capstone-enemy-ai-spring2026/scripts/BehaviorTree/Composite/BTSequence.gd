"""
Sequence Node: Runs child nodes in order until one fails or all children succeed.
@authors: Sam Plemmons
"""
extends BTNode
class_name BTSequence

"""
Index of the child node currently being evaluated.
"""
var child_index: int = 0

"""
Evaluates each child node in order.

Returns RUNNING if the current child is still executing, FAILURE if any child
fails, and SUCCESS only if every child succeeds. The child index is reset after
a failure or complete success so the sequence starts from the first child on
the next tick.
"""
func execute(delta: float, context: Dictionary) -> int:
	while child_index < get_child_count():
		var child: BTNode = get_child(child_index)
		var result := child.tick(delta, context)
		
		if result == BTNode.Status.RUNNING:
			return BTNode.Status.RUNNING
			
		if result == BTNode.Status.FAILURE:
			child_index = 0
			return BTNode.Status.FAILURE
			
		child_index += 1
		
	child_index = 0
	return BTNode.Status.SUCCESS
