"""
Condition Node: Base class for behavior tree nodes that check whether a condition is met.
@authors: Sam Plemmons
"""
extends BTNode
class_name BTCondition


"""
Runs this condition node by calling check().

Child condition nodes should override check() with the condition the entity
needs to evaluate before performing an action.
"""
func execute(_delta: float, context: Dictionary) -> int:
	return check(context)

"""
Checks whether this condition is met.

Returns FAILURE by default so incomplete or unimplemented conditions fail safely.
"""
func check(_context: Dictionary) -> int:
	return BTNode.Status.FAILURE
