"""
AoE Projectile: Pyromancer projectile used for heavy attacks and skills.

Spawns a telegraphed fire hazard on the ground that applies burn damage over time.
@author: Sam Plemmons
"""
extends Projectile

# Fire AoE scene spawned when this projectile explodes.
var fire_aoe = preload("res://Components/Telegraphs/FireAOE/Fire.tscn")

var is_heavy = false
var is_skill = false
var telegraph_name: String = ""
var burn: int = 1
var tick_rate: float = 1.0


"""
Handles collision with another body.

If the projectile hits a non-player target that can take damage, it applies
initial damage and burn before triggering the AoE explosion.
"""
func _on_body_entered(body: Node) -> void:
	## If target can take damage
	if body.has_method("take_damage") and !(body is Player):
		#apply burn (prevent hurt anim)
		if body.has_method("apply_burn"):
			body.apply_burn(burn)
			body.take_damage(damage, false)
		else:
			body.take_damage(damage)
	if body is Player:
		return
	call_deferred("explode")

"""
Spawns the fire AoE hazard at the matching telegraph position.

The hazard uses the telegraph's shape, then applies burn and damage over time
based on this projectile's damage, burn, tick_rate, and lifetime values.
"""
func explode():
	direction = Vector2.ZERO
	# Display telegraph
	var telegraph = get_node_or_null(telegraph_name)
	if telegraph == null:
		queue_free()
		return
	var hazard = fire_aoe.instantiate()
	hazard.is_player = true
	hazard.color = Color(1,0.5,0,0.5)
	hazard.global_position = telegraph.get_node("telegraph").global_position
	hazard.get_node("telegraph").shape = telegraph.get_node("telegraph").shape
	hazard.damage_per_tick = damage
	hazard.burn_application = burn
	hazard.tick_rate = tick_rate
	hazard.lifetime = lifetime
	get_parent().add_child(hazard)
	queue_free()

"""
Plays the AoE projectile's starting flight animation.
"""
func play_start_animation():
	if facing == "Left":
		$projectile_animation.play("Fly_Right")
	else:
		$projectile_animation.flip_h = false
		$projectile_animation.play("Fly_Right")
