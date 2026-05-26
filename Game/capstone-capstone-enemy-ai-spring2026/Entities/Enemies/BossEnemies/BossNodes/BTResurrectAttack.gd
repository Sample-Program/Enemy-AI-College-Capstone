"""
Resurrect Attack Node: Action node that allows the Colossus to resurrect nearby basic enemies.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTResurrectAttack

var animation_name: String = ""
var telegraph_name: String = ""
var res_frames: Array = []
var damage_amount: int = 1
var last_frame: int = -1

"""
Initializes the resurrect attack.

@param anim_name: Name of the animation used for this attack.
@param telegraph: Name of the telegraph Area2D used to detect targets and dead enemies.
@param frames: Animation frames where damage and resurrection should occur.
@param damage: Amount of damage dealt to the target when the attack connects.
"""
func _init(anim_name: String, telegraph: String, frames: Array, damage: int):
	display_name = "BTResurrectAttack"
	animation_name = anim_name
	telegraph_name = telegraph
	res_frames = frames
	damage_amount = damage


"""
Runs the Colossus resurrect attack.

During the specified resurrection frames, the telegraph flashes, the player is
damaged and knocked back if inside the attack area, and any dead BasicEnemy
objects inside the area are resurrected. The node continues running until the
animation finishes.
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
	if agent.sprite.frame in res_frames:
		if telegraph != null and telegraph is Area2D:
			# Flash color at damage frame
			telegraph.modulate = Color(1,1,1,0.5)
			# Deal damage
			if target in telegraph.get_overlapping_bodies() and agent.sprite.frame != last_frame:
				target.movement_component.apply_knockback(telegraph.global_position, 500.0)
				target.take_damage(damage_amount)
				last_frame = agent.sprite.frame
			# Res basic enemies
			for body in telegraph.get_overlapping_bodies():
				if body is BasicEnemy and body.is_dead():
					body.resurrect()
					agent.scale.x += 0.1
					agent.scale.y += 0.1
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
		#agent.scale.x = agent.size
		#agent.scale.y = agent.size
		return BTNode.Status.SUCCESS
