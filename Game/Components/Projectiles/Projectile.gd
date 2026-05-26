"""
	This script handles the properties of a projectile that can be used
	by any entity (if allowed). This script sets the speed, damage, direction,
	and lifetime of the projectile and handles how it acts after being shot.
	@author: Sam Plemmons
"""
extends Area2D

class_name Projectile

var speed: float = 100.0
var damage: int = 10
var direction: Vector2 = Vector2.ZERO
var lifetime: float = 10.0

## Added this variable so that I can control the animation of the arrow
var facing = "Right"

"""
	This function handles if the projectile collides with a body object.
	It ensures that the body that was hit takes damage.
	@author: Sam Plemmons
"""
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

"""
	This function handles the physics of the projectile, which is its
	direction that it moves in. It also handles despawning.
	@paramL The time in seconds since the previous frame
	@author: Sam Plemmons
"""
func _physics_process(delta: float) -> void:
	## Move projectile
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
	
	## Despawn after set amount of time
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

"""
	This function handles when a body gets hit by the projectile. It
	ensures that the entity can take damage, and if so, damages the
	enemy with the damage field.
	@author: Sam Plemmons
"""
func _on_body_entered(body: Node) -> void:
	## If target can take damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

"""
	This function handles playing the correct animation for the Ranger arrow.
	In Ranger attack arrow.facing set's where the arrow is facing, and this
	function plays the correct animation!
"""
func play_start_animation():
	if facing == "Left":
		$projectile_animation.play("Fly_Left")
	else:
		$projectile_animation.play("Fly_Right")
