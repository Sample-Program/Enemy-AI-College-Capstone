"""
Attack Node: Action node that damages the target during specific animation frames.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTAttack

var animation_name: String = ""
var telegraph_name: String = ""
var damage_frames: Array = []
var damage_amount: int = 1
var last_frame: int = -1

"""
Initializes the attack with its animation, telegraph, damage frames, and damage value.

@param anim_name: Name of the animation used for this attack.
@param telegraph: Name of the telegraph Area2D used to detect valid targets.
@param frames: Animation frames where damage should be applied.
@param damage: Amount of damage dealt when the attack connects.
"""
func _init(anim_name: String, telegraph: String, frames: Array, damage: int):
	display_name = "BTAttack"
	animation_name = anim_name
	telegraph_name = telegraph
	damage_frames = frames
	damage_amount = damage

"""
Runs the attack behavior.

The telegraph is shown while the attack is active. During the specified damage
frames, the telegraph flashes and the target takes damage if they are inside
the telegraph area. The node continues running until the animation finishes.
"""
func execute(_delta: float, context: Dictionary) -> int:
	var agent = context.get("self")
	var target = context.get("target")
	if agent == null or target == null:
		return BTNode.Status.FAILURE
	# Display telegraph
	var telegraph = agent.get_node_or_null(telegraph_name)
	if telegraph != null:
		telegraph.visible = true
	# Deal damage during specified frames
	if agent.sprite.frame in damage_frames:
		if telegraph != null and telegraph is Area2D:
			# Flash color at damage frame
			telegraph.modulate = Color(1,1,1,0.5)
			# Deal damage
			if target in telegraph.get_overlapping_bodies() and agent.sprite.frame != last_frame:
				target.take_damage(damage_amount)
				# increment attack count
				if "attack_count" in agent:
					agent.attack_count += 1
				last_frame = agent.sprite.frame
	# Telegraph attack area
	else:
		if telegraph != null:
			telegraph.modulate = Color(1,0,0,0.3)
	# Keep node running until animation finishes
	if agent.sprite.is_playing():
		return BTNode.Status.RUNNING
	else:
		if telegraph != null:
			telegraph.visible = false
		return BTNode.Status.SUCCESS
