"""
Check Attack Count Node: Condition node that checks whether the enemy has reached
a required number of successful attacks. If the required attack count is reached, 
the count is reset and the enemy is given a boost before returning SUCCESS.
@authors: Sam Plemmons
"""
extends BTCondition
class_name BTCheckAttackCount

## Number of successful attacks required before this condition succeeds.
var attack_amount: int

"""
Initializes the attack count condition.

@param atk_amt: Required number of attacks before the condition returns SUCCESS.
"""
func _init(atk_amt: int):
	display_name = "BTCheckAttackCount"
	attack_amount = atk_amt

"""
Checks whether the enemy has reached the required attack count.

Returns SUCCESS if the attack count is high enough, then resets the count and
applies the enemy's boost. Returns FAILURE if the agent is missing, does not
track attack_count, or has not reached the required count yet.
"""
func check(context: Dictionary) -> int:
	var agent = context.get("self")
	# check if agent has attack count as a variable
	if agent == null or !("attack_count" in agent):
		return BTNode.Status.FAILURE
	# Check count
	if agent.attack_count >= attack_amount:
		agent.attack_count = 0
		agent.boost += 0.5
		agent.speed += 25
		return BTNode.Status.SUCCESS
	return BTNode.Status.FAILURE
