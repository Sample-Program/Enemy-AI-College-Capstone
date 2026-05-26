"""
Check Target Node: Condition node that checks a specified value on the target.
@authors: Sam Plemmons
"""
extends BTCondition
class_name BTCheckTarget

## Health threshold used when checking the target's health.
var health_check: int

## Target field this condition checks.
var target_field: String

"""
Initializes the target check condition.

@param field: Target field to check, such as "health".
@param hp: Health threshold used when checking the target's health.
"""
func _init(field: String, hp: int):
	display_name = "BTCheckTarget"
	target_field = field
	health_check = hp

"""
Checks the requested target field.

Currently supports checking whether a Player target's current health is less
than or equal to the provided health threshold.
"""
func check(context: Dictionary) -> int:
	var target = context.get("target")
	if target is Player:
		match target_field:
			"health":
				# health is less than specified amount
				if target.health_component.current_health <= health_check:
					return BTNode.Status.SUCCESS
	# fallback
	return BTNode.Status.FAILURE
