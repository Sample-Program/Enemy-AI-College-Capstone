"""
Play Animation Node: Action node that plays and manages enemy animations.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTPlayAnimation

## Name of the animation this node should play.
var animation: String = ""

## Number of times the animation should repeat.
var repeat_times: int = 0
var max_repeats: int = 0

## Last frame played by the animation.
var last_frame: int = -1

"""
Initializes the animation node.

@param anim: Name of the animation to play.
@param repeat: Number of times the animation should repeat.
"""
func _init(anim: String, repeat: int = 1):
	display_name = "BTPlayAnimation"
	animation = anim
	max_repeats = repeat

"""
Plays the selected animation and applies any related enemy state changes.

Idle, sleep, and move animations finish immediately. One-shot animations such
as death, wake up, vanish, appear, and attacks return RUNNING until their
animation finishes, then update the enemy's state.
"""
func execute(_delta: float, context: Dictionary) -> int:
	var agent = context.get("self")
	if agent == null:
		return BTNode.Status.FAILURE
	# NavMesh
	match animation:
		"idle":
			play_animation(context, animation)
			return BTNode.Status.SUCCESS
		"sleep":
			play_animation(context, animation)
			return BTNode.Status.SUCCESS
		"dead":
			play_animation_once(context, animation)
			agent.bleed_icon.visible = false
			agent.stun_icon.visible = false
			agent.burn_icon.visible = false
			if agent.sprite.is_playing():
				return BTNode.Status.RUNNING
			agent.set_dead(true)
			agent.collision.disabled = true
			return BTNode.Status.SUCCESS
		"wake_up":
			play_animation_once(context, animation)
			if agent.sprite.is_playing():
				return BTNode.Status.RUNNING
			agent.set_sleep(false)
			return BTNode.Status.SUCCESS
		"move":
			agent.sprite.play(animation)
			return BTNode.Status.SUCCESS
		"melee_attack":
			return attack_animations(context, animation)
		"range_attack":
			return attack_animations(context, animation)
		"super_attack":
			return attack_animations(context, animation)
		"resurrect_attack":
			return attack_animations(context, animation)
		## Attack Animations for Assassin
		"attack":
			return attack_animations(context, animation)
		"attack_first_continuous":
			return attack_animations(context, animation)
		"attack_second_continuous":
			return attack_animations(context, animation)
		"magic_attack":
			return attack_animations(context, animation)
		"vanish":
			play_animation_once(context, animation)
			if agent.sprite.is_playing():
				return BTNode.Status.RUNNING
			agent.set_stealth(true)
			return BTNode.Status.SUCCESS
		## Offset Animations for Assassin
		"appear":
			agent.set_attacking(true)
			if agent.sprite_offset.animation != animation:
				agent.sprite_offset.sprite_frames.set_animation_loop(animation, false)
				agent.sprite_offset.play(animation)
			agent.move_direction = Vector2.ZERO
			agent.nav_agent.set_velocity(Vector2.ZERO)
			if agent.sprite_offset.is_playing():
				return BTNode.Status.RUNNING
			agent.set_attacking(false)
			agent.set_stealth(false)
			agent.set_sleep(false)
			return BTNode.Status.SUCCESS
		"invisible":
			agent.sprite_offset.play(animation)
			#agent.move_direction = Vector2.ZERO
			#agent.nav_agent.set_velocity(Vector2.ZERO)
			return BTNode.Status.SUCCESS
	return BTNode.Status.FAILURE

"""
Plays an animation once and stops the agent's movement.

The animation is only restarted if the requested animation is not already
playing.
"""
func play_animation_once(context: Dictionary, anim: String) -> void:
	var agent = context.get("self")
	if agent.sprite.animation != anim:
		agent.sprite.sprite_frames.set_animation_loop(anim, false)
		agent.sprite.play(anim)
	agent.move_direction = Vector2.ZERO
	agent.nav_agent.set_velocity(Vector2.ZERO)

"""
Plays a looping animation and stops the agent's movement.
"""
func play_animation(context: Dictionary, anim: String) -> void:
	var agent = context.get("self")
	agent.sprite.play(anim)
	agent.move_direction = Vector2.ZERO
	agent.nav_agent.set_velocity(Vector2.ZERO)

"""
Plays an attack animation and keeps the node running until the animation ends.

The agent is marked as attacking while the animation is active.
"""
func attack_animations(context: Dictionary, anim: String) -> BTNode.Status:
	var agent = context.get("self")
	agent.set_attacking(true)
	play_animation_once(context, anim)
	if agent.sprite.is_playing():
		return BTNode.Status.RUNNING
	agent.set_attacking(false)
	return BTNode.Status.SUCCESS
