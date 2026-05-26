"""
Parallel Node: Runs all child nodes during the same tick.
@authors: Sam Plemmons
"""
extends BTNode
class_name BTParallel

"""
List of child nodes managed by this parallel node.
"""
var children: Array = []


"""
Adds a child node to the parallel node's list of children.
"""
func add_child_node(node: BTNode) -> void:
	children.append(node)

"""
Ticks all child nodes and combines their results.

Returns FAILURE immediately if any child fails, SUCCESS if all children succeed,
and RUNNING if at least one child is still running.
"""
func execute(delta: float, context: Dictionary) -> int:
	var all_success = true
	for child in children:
		var status = child.tick(delta, context)
		if status == BTNode.Status.FAILURE:
			return BTNode.Status.FAILURE
		if status == BTNode.Status.RUNNING:
			all_success = false
	if all_success:
		return BTNode.Status.SUCCESS
	return BTNode.Status.RUNNING
