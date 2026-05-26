"""
Selector Node: Runs child nodes until one succeeds or all children fail.
@authors: Sam Plemmons
"""
extends BTNode
class_name BTSelector

"""
Index of the child node currently being evaluated.
"""
var child_index: int = 0

"""
Evaluates each child node in order.

Returns RUNNING if the current child is still executing, SUCCESS if any child
succeeds, and FAILURE if every child fails. The child index is reset after a
success or complete failure so the selector starts from the first child on the
next tick.
"""
func execute(delta: float, context: Dictionary) -> int:
	while child_index < get_child_count():
		var child: BTNode = get_child(child_index)
		var result := child.tick(delta, context)
	
		if result == BTNode.Status.RUNNING:
			#print("selector running")
			return BTNode.Status.RUNNING
		if result == BTNode.Status.SUCCESS:
			child_index = 0
			#print("selector success")
			return BTNode.Status.SUCCESS
	
		child_index += 1
	
	child_index = 0
	#print("selector failure")
	return BTNode.Status.FAILURE
