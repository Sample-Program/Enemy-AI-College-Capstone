"""
Appear Attack Node: Action node used when the Assassin attacks after appearing.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTAppearAttack

var animation_name: String = ""
var telegraph_name: String = ""
var damage_frames: Array = []
var damage_amount: int = 1
var last_frame: int = -1


"""
Initializes the appear attack with its animation, telegraph, damage frames, and damage value.

@param anim_name: Name of the animation used for this attack.
@param telegraph: Name of the telegraph Area2D used to detect valid targets.
@param frames: Animation frames where damage should be applied.
@param damage: Amount of damage dealt when the attack connects.
"""
func _init(anim_name: String, telegraph: String, frames: Array, damage: int):
	display_name = "BTAppearAttack"
	animation_name = anim_name
	telegraph_name = telegraph
	damage_frames = frames
	damage_amount = damage

"""
Runs the Assassin's appear attack.

The attack checks specific animation frames for damage, briefly displays the
telegraph during active damage frames, and damages the target if they are inside
the telegraph area. The node continues running until the animation finishes.
"""
func execute(_delta: float, context: Dictionary) -> int:
	var agent = context.get("self")
	var target = context.get("target")
	if agent == null or target == null:
		return BTNode.Status.FAILURE
	# Display telegraph
	var telegraph = agent.get_node_or_null(telegraph_name)
	# Deal damage during specified frames
	if agent.sprite_offset.frame in damage_frames:
		if telegraph != null and telegraph is Area2D:
			# Flash color at damage frame (blends white and red)
			telegraph.visible = true
			telegraph.modulate = Color(1,0,0,0.3)
			telegraph.modulate = Color(1,1,1,0.5)
			# Deal damage
			if target in telegraph.get_overlapping_bodies() and agent.sprite_offset.frame != last_frame:
				target.take_damage(damage_amount)
				# increment attack count
				if "attack_count" in agent:
					agent.attack_count += 1
				last_frame = agent.sprite_offset.frame
	# Keep node running until animation finishes
	if agent.sprite_offset.is_playing():
		return BTNode.Status.RUNNING
	else:
		if telegraph != null:
			telegraph.visible = false
		last_frame = -1 # reset last frame
		return BTNode.Status.SUCCESS
