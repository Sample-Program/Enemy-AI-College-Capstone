"""
This script handles the projectile that is fired by the Flying Bug Enemy. This 
projectile has a chance to apply bleed to the player, and is also handled here.

@authors: Sam Plemmons
"""

extends Projectile

# do base variable stuff
var is_bleed_attack = false
var bleed_duration = 5.0

#@onready var sprite: Sprite2D = $Sprite2D

"""
	Initializes the projectile.
	
	@param is_bleed_attack: Whether the projectile applies bleed.
	@param bleed_duration: Duration of the bleed effect in seconds.
"""
func init(bleed_attack: bool, bleed_timer: float) -> void:
	self.is_bleed_attack = bleed_attack
	self.bleed_duration = bleed_timer
	$projectile_animation.play()

"""
	Applies damage to valid targets and optionally applies bleed.
	The projectile is destroyed after collision unless the body is an Enemy.
	
	@param body: The physics body that was entered.
"""
func _on_body_entered(body: Node) -> void:
	## If target can take damage
	if body.has_method("take_damage") and !(body is Enemy):
		body.take_damage(damage)
		if (is_bleed_attack):
			body.apply_bleed(5) #5 dmg per tick (in case we want a stronger enemy's bleed)
		queue_free()
	elif body is Enemy:
		return
	queue_free()
