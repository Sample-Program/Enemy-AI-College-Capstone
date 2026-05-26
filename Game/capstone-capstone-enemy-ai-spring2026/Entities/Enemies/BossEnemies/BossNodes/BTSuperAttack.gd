"""
Super Attack Node: Action node that handles multi-stage AoE attacks.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTSuperAttack

var animation_name: String = ""
var attack_data: Array = []
var damage_amount: int = 1
var last_frames: Array = []

"""
Expected attack_data format:

[
	{ "telegraph": "telegraph1", "frames": [10, 11] },
	{ "telegraph": "telegraph2", "frames": [12, 13] },
	{ "telegraph": "telegraph3", "frames": [14, 15] }
]

Each entry defines which telegraph is used and which animation frames can deal damage.
"""

"""
Initializes the super attack.

@param anim_name: Name of the animation used for this attack.
@param data: Array of telegraph and damage frame data.
@param dmg: Amount of damage dealt when one attack stage connects.
"""
func _init(anim_name: String, data: Array, dmg: int):
	display_name = "BTSuperAttack"
	animation_name = anim_name
	attack_data = data
	damage_amount = dmg
	last_frames.resize(data.size())
	for i in range(data.size()):
		last_frames[i] = -1

"""
Runs the multi-stage AoE attack.

The active telegraph is chosen based on the current animation frame. During each
stage's damage frames, the selected telegraph flashes and damages the target if
they are inside its area. The node continues running until the animation ends.
"""
func execute(_delta: float, context: Dictionary) -> int:
	var agent = context.get("self")
	var target = context.get("target")
	if agent == null or target == null:
		return BTNode.Status.FAILURE
		
	# set telegraph to be first damage ring initially
	agent.set_attacking(true)
	var telegraph = agent.get_node_or_null(attack_data[0]["telegraph"])
	for frames in attack_data:
		if agent.sprite.frame in frames["frames"]:
			telegraph = agent.get_node_or_null(frames["telegraph"])
	for i in range(attack_data.size()):
		var attack = attack_data[i]
		# Display telegraph
		if telegraph != null:
			telegraph.visible = true
		# Deal damage during specified frames
		if agent.sprite.frame in attack["frames"]:
			if telegraph != null and telegraph is Area2D:
				# Flash color at damage frame
				telegraph.modulate = Color(1,1,1,0.5)
				# Deal damage
				if target in telegraph.get_overlapping_bodies() and agent.sprite.frame != last_frames[i]:
					target.take_damage(damage_amount)
					last_frames[i] = agent.sprite.frame
		# Telegraph attack area
		else:
			if telegraph != null:
				telegraph.modulate = Color(1,0,0,0.3)
		# Keep node running until animation finishes
	if agent.sprite.is_playing():
		return BTNode.Status.RUNNING
	else:
		if telegraph != null:
			for frames in attack_data:
				agent.get_node_or_null(frames["telegraph"]).visible = false
		agent.set_attacking(false)
		return BTNode.Status.SUCCESS
