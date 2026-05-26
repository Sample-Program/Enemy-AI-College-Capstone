"""
Action Node: Base class for behavior tree nodes that perform an action.
@authors: Sam Plemmons
"""
extends BTNode
class_name BTAction

"""
Executes this action node.

Child action nodes should override this method with the behavior the entity
performs when the node is ticked.
"""
func execute(_delta: float, _context: Dictionary) -> int:
	return BTNode.Status.SUCCESS
