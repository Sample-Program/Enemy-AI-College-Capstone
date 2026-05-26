"""
Check Area Node: Condition node that checks whether the target is inside an Area2D.
@authors: Sam Plemmons
"""
extends BTCondition
class_name BTCheckArea

## Name of the Area2D node used for range detection.
var area_name: String = ""

"""
Initializes the area check condition.

@param area: Name of the Area2D node to check.
"""
func _init(area: String):
	display_name = "BTCheckArea"
	area_name = area

"""
Checks whether the target is currently overlapping the selected Area2D.

Returns SUCCESS if the target is inside the area, and FAILURE if the area,
agent, or target cannot be found.
"""
func check(context: Dictionary) -> int:
	var agent = context.get("self")
	if agent == null:
		return BTNode.Status.FAILURE
	# Check Area
	var area_node = agent.get_node_or_null(area_name)
	if area_node == null or not area_node is Area2D:
		print("cannot find area")
		return BTNode.Status.FAILURE
	if context["target"] in area_node.get_overlapping_bodies():
		return BTNode.Status.SUCCESS
	return BTNode.Status.FAILURE
