"""
Health Check Node: Condition node that checks whether the agent's health is below a threshold.
@authors: Sam Plemmons
"""
extends BTCondition
class_name BTHealthCheck

## Health value required for this condition to succeed.
var health_threshold: int = 0

"""
Initializes the health check condition.

@param hp: Health threshold used to determine when this condition succeeds.
"""
func _init(hp: int):
	display_name = "BTCheckHealth"
	health_threshold = hp


"""
Checks whether the agent's current health is at or below the threshold.

Returns SUCCESS if the agent's health is less than or equal to health_threshold.
Returns FAILURE if the agent is missing or its health is above the threshold.
"""
func check(context: Dictionary) -> int:
	var agent = context.get("self")
	if agent == null:
		return BTNode.Status.FAILURE
	# Check Health
	var current_health = agent.get_health()
	if current_health <= health_threshold:
		return BTNode.Status.SUCCESS
	return BTNode.Status.FAILURE
