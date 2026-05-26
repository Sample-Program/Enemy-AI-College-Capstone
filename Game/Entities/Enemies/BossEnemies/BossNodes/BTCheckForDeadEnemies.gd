"""
Check For Dead Enemies Node: Condition node that checks whether dead basic enemies are within range.
@authors: Sam Plemmons
"""
extends BTCondition
class_name BTCheckForDeadEnemies

## Name of the Area2D node used to detect nearby enemies.
var area_name: String = ""

"""
Initializes the dead enemy area check.

@param area: Name of the Area2D node to check.
"""
func _init(area: String):
	display_name = "BTCheckForDeadEnemies"
	area_name = area

"""
Checks whether any dead BasicEnemy objects are overlapping the selected Area2D.

Returns SUCCESS if at least one dead BasicEnemy is found within the area.
Returns FAILURE if the agent or area cannot be found, or if no dead basic
enemies are currently in range.
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
	for body in area_node.get_overlapping_bodies():
		if body is BasicEnemy and body.is_dead():
			return BTNode.Status.SUCCESS
	return BTNode.Status.FAILURE
