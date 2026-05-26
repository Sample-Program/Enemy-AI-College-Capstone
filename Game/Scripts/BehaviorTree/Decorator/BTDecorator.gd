"""
Decorator Node: Base class for nodes that modify the behavior of a single child node.
@authors: Sam Plemmons
"""
extends BTNode
class_name BTDecorator

"""
Child node whose behavior is modified by this decorator.
"""
var child: BTNode

"""
Initializes the decorator with the child node it will wrap.
"""
func _init(node: BTNode):
	child = node
	add_child(child)


"""
Ticks the child node and returns its result.

If no child node is assigned, the decorator returns FAILURE so it fails safely.
"""
func execute(delta: float, context: Dictionary) -> int:
	if child == null:
		return Status.FAILURE
	return child.tick(delta, context)
