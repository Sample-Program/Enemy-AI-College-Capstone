"""
Check Status Node: Condition node that checks a specific status on the agent.
@authors: Sam Plemmons
"""
extends BTCondition
class_name BTCheckStatus

## Status value this condition checks for.
var status_check: String

"""
Initializes the status check condition.

@param status: Status name to check, such as "dead", "sleep", "awake", "stealth", "visible", or "stunned".
"""
func _init(status: String) -> void:
	display_name = "BTCheckStatus"
	status_check = status

"""
Checks whether the agent matches the requested status.

Returns SUCCESS if the requested status condition is true. Returns FAILURE if
the agent is missing, the status condition is false, or the provided status
name is not supported.
"""
func check(context: Dictionary) -> int:
	var agent = context.get("self")
	match status_check:
		"dead":
			if agent == null:
				return BTNode.Status.FAILURE
			# Check Dead
			if agent.is_dead():
				return BTNode.Status.SUCCESS
			return BTNode.Status.FAILURE
		"sleep":
			if agent == null:
				return BTNode.Status.FAILURE
			# Check Sleep
			if agent.is_asleep():
				return BTNode.Status.SUCCESS
			return BTNode.Status.FAILURE
		"awake":
			if agent == null:
				return BTNode.Status.FAILURE
			# Check Sleep
			if agent.is_asleep():
				return BTNode.Status.FAILURE
			return BTNode.Status.SUCCESS
		"stealth":
			if agent == null:
				return BTNode.Status.FAILURE
			# Check Stealth
			if agent.is_stealth():
				return BTNode.Status.SUCCESS
			return BTNode.Status.FAILURE
		"visible":
			if agent == null:
				return BTNode.Status.FAILURE
			# Check Stealth
			if agent.is_stealth():
				return BTNode.Status.FAILURE
			return BTNode.Status.SUCCESS
		"stunned":
			if agent == null:
				return BTNode.Status.FAILURE
			# Check Stealth
			if agent.is_stunned_flag:
				return BTNode.Status.SUCCESS
			return BTNode.Status.FAILURE
	#fallback
	return BTNode.Status.FAILURE 
