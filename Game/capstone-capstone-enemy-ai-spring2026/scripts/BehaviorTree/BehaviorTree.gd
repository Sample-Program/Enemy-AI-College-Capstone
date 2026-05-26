"""
Behavior Tree: Calls and updates the root node of the behavior tree.
@authors: Sam Plemmons
"""
extends Node
class_name BehaviorTree

@warning_ignore("unused_signal")
signal node_ticked(node: BTNode, status: int)

"""
Root node of the behavior tree.
"""
var root: BTNode

"""
Shared data for the entity using this behavior tree.

The context stores information that needs to be accessed by multiple nodes,
such as the owner, target, navigation data, or tree reference.
"""
var context := {}

"""
Updates the behavior tree by ticking the root node.

The root is usually a composite node that controls the flow of execution for
its child nodes. If no root exists, the tree fails safely.
"""
func tick(delta: float) -> int:
	if root == null:
		print("root is null")
		return BTNode.Status.FAILURE
	
	#print("calling tick on root")
	return root.tick(delta, context)
