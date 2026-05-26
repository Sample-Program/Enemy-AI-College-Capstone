"""
Base Behavior Tree Node: used to track and return node statuses.
@authors: Sam Plemmons
"""
extends Node
class_name BTNode

var display_name = ""


"""
Represents the possible results of a behavior tree node.

SUCCESS: The node completed its task successfully.
FAILURE: The node failed to complete its task.
RUNNING: The node is still processing its task.
"""
enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

"""
Called each engine tick to update this behavior tree node.

Leaf nodes should override execute() to define their behavior. This method
handles execution and emits a debug signal when a behavior tree is available
in the context.
"""
func tick(delta: float, context: Dictionary) -> int:
	var result = execute(delta, context)
	
	# Emit debug signal
	if context.has("tree"):
		var tree: BehaviorTree = context["tree"]
		tree.emit_signal("node_ticked", self, result)
	
	return result

"""
Default execution behavior for a behavior tree node.

Returns FAILURE by default so incomplete or unimplemented nodes fail safely.
"""
func execute(_delta: float, _context: Dictionary):
	return BTNode.Status.FAILURE
