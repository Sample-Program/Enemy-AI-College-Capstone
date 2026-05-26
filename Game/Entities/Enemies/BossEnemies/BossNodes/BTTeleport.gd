"""
Teleport Node: Action node that teleports the agent to a random valid point near the target.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTTeleport

## Minimum distance from the target where the agent can teleport.
var min_range: float

## Name of the node that defines the minimum teleport distance.
var min_node: String

## Maximum distance from the target where the agent can teleport.
var max_range: float 

## Name of the node that defines the maximum teleport distance.
var max_node: String

## Number of random teleport positions to try before failing.
var max_attempts: int

"""
Initializes the teleport node.

@param min_r: Name of the node containing the minimum teleport radius.
@param max_r: Name of the node containing the maximum teleport radius.
@param attempts: Number of teleport positions to try before returning FAILURE.
"""
func _init(min_r: String, max_r: String, attempts: int = 5):
	display_name = "BTTeleport"
	min_node = min_r
	max_node = max_r
	max_attempts = attempts

"""
Teleports the agent to a random point within a ring around the target.

The ring is defined by the minimum and maximum radius nodes. A random point is
chosen inside that range, then snapped to the closest valid NavigationServer2D
point before the agent is moved.
"""
func execute(_delta: float, context: Dictionary) -> int:
	# Agent and Target
	var agent = context.get("self")
	var target = context.get("target")
	min_range = agent.get_node_or_null(min_node).shape.radius
	max_range = agent.get_node_or_null(max_node).shape.radius
	# Stop if either are null
	if agent == null or target == null:
		return BTNode.Status.FAILURE
	# NavMesh stuff
	var nav_agent: NavigationAgent2D = agent.nav_agent
	# teleport
	for i in range(max_attempts):
		# Random point in a ring
		var random_angle = randf_range(0.0, TAU)
		var random_distance = randf_range(min_range, max_range)
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
		var candidate = target.global_position + offset
		var nav_point = NavigationServer2D.map_get_closest_point(
			nav_agent.get_navigation_map(),
			candidate
		)
		agent.global_position = nav_point
		return BTNode.Status.SUCCESS
	return BTNode.Status.FAILURE
