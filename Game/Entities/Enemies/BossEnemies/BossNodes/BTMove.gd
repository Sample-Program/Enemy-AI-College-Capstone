"""
Move Node: Action node that moves the agent toward the target using NavigationAgent2D.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTMove

## Multiplier applied to the agent's base movement speed.
var speed_modifier: float = 1.0

## Distance from the target where the agent should stop moving.
var stop_distance: float = 0.0

## Last recorded position of the agent, used for stuck detection.
var last_position: Vector2

## Time the agent has spent moving less than the stuck threshold.
var stuck_timer: float = 0.0

## Minimum movement required to avoid being considered stuck.
var stuck_threshold: float = 1.0

## Time allowed below the movement threshold before refreshing the path.
var stuck_time_limit: float = 1.0

"""
Initializes the movement node.

@param mod: Speed multiplier applied while moving.
@param dist: Distance from the target where the agent should stop.
"""
func _init(mod: float, dist: float):
	display_name = "BTMove"
	speed_modifier = mod
	stop_distance = dist

"""
Moves the agent toward the target using its NavigationAgent2D.

The node updates the navigation target, checks whether the agent is close enough
to stop, refreshes the path if the agent appears stuck, and moves the agent
along the next path position.
"""
func execute(delta: float, context: Dictionary) -> int:
	# Agent and Target
	var agent = context.get("self")
	var target = context.get("target")
	# Stop if either are null
	if agent == null or target == null:
		return BTNode.Status.FAILURE
	# NavMesh stuff
	var nav_agent: NavigationAgent2D = agent.nav_agent
	var to_target: Vector2 = target.global_position - agent.global_position
	var distance := to_target.length()
	## Stop Condition
	if distance <= stop_distance:
		nav_agent.set_velocity(Vector2.ZERO)
		return BTNode.Status.SUCCESS
	## Update NavMesh
	if nav_agent.target_position.distance_to(target.global_position) > 5.0:
		nav_agent.target_position = target.global_position
	## Stuck Detection
	var moved_distance = agent.global_position.distance_to(last_position)
	if moved_distance < stuck_threshold:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	if stuck_timer > stuck_time_limit:
		nav_agent.target_position = target.global_position
		stuck_timer = 0.0
	last_position = agent.global_position
	## Finished Moving
	if nav_agent.is_navigation_finished():
		nav_agent.set_velocity(Vector2.ZERO)
		return BTNode.Status.SUCCESS
	## Follow Path
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - agent.global_position).normalized()
	agent.velocity = direction * agent.speed * speed_modifier
	nav_agent.velocity = agent.velocity
	agent.move_and_slide()
	return BTNode.Status.SUCCESS
