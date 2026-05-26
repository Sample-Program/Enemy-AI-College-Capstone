"""
Pyromancer Projectile: Projectile used for the Pyromancer's attacks and skills.
@authors: Sam
"""

extends Projectile

var is_heavy = false
var is_skill = false
var burn_stacks = 1.0


"""
Handles collision with another body.

If the projectile hits a non-player target that can take damage, it applies
burn if possible, deals damage, and removes itself from the scene.
"""
func _on_body_entered(body: Node) -> void:
	## If target can take damage
	if body.has_method("take_damage") and !(body is Player):
		#apply burn (prevent hurt anim)
		if body.has_method("apply_burn"):
			body.apply_burn(burn_stacks)
			body.take_damage(damage, false)
		else:
			body.take_damage(damage)
		queue_free()
	elif body is Player:
		return
	queue_free()

"""
Plays the projectile's starting flight animation.
"""
func play_start_animation():
	if facing == "Left":
		$projectile_animation.play("Fly_Right")
	else:
		$projectile_animation.flip_h = false
		$projectile_animation.play("Fly_Right")
