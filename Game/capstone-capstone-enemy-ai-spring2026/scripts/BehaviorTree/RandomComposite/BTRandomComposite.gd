"""
Random Composite: Base class for composite nodes that evaluate children in a randomized order.
@authors: Sam Plemmons
"""
extends BTNode
class_name BTRandomComposite

"""
Randomized order of child node indexes.
"""
var order: Array[int] = []

"""
Index used to track the current position in the randomized order.
"""
var child_index: int = 0

"""
Builds a randomized order of child node indexes using Godot's built-in
array functions.
"""
func build_order():
	order.clear()
	for child in range(get_child_count()):
		order.append(child)
	order.shuffle()
	#print(order)

"""
Resets the randomized order and starts iteration from the beginning.
"""
func reset():
	child_index = 0
	order.clear()
