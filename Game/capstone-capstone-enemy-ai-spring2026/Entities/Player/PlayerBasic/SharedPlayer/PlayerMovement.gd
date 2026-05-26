class_name PlayerMovement
extends Node
 
# ==============================
# PLAYER REFERENCE
# ==============================
var player: Player
 
# ==============================
# SPEED STATE
# ==============================
var current_speed: float = 0.0
 
# ==============================
# STAMINA STATE
# ==============================
var current_stamina: float = 0.0
var st_recovery_timer: float = 0.0

# knockback stuff
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 800.0

"""
	This function applies knockback onto the player depending on the amount of strength
	sent as a parameter.
	
	@param from_position: The position to knock the player away from
	@param strength: The strength of the knockback
"""
func apply_knockback(from_position: Vector2, strength: float = 300.0) -> void:
	# checks
	if player.health_component.is_dead or player.health_component.is_reviving:
		return
	
	# do the knockback
	var dir = (player.global_position - from_position).normalized()
	knockback_velocity = dir * strength
 
"""
	Called by PlayerBase._ready() to inject the player reference
	and initialize stamina from class data.
"""
func setup(p: Player) -> void:
	player = p
	current_stamina = player.class_data.max_stamina
 
"""
	Called every physics frame (when the player is not attacking or stunned).
	Reads input, updates stamina, drives velocity, and triggers animations.
"""
func handle(delta: float) -> void:
	var direction := _get_input_direction()
	var is_sprinting := _handle_stamina(direction, delta)
	
	current_speed = lerp(current_speed, _target_speed(is_sprinting), 0.2)
	
	var input_velocity := player.velocity
	
	if player.is_using_special:
		player.anim_sprite.play("Special_" + player.dir)
		
	elif direction != Vector2.ZERO:
		input_velocity = Vector2.ZERO
		input_velocity = direction.normalized() * current_speed
		player.play_run_animation(direction)
	else:
		input_velocity = Vector2.ZERO
		player.play_idle_animation()
		
	# knockback player
	player.velocity = input_velocity + knockback_velocity
	player.move_and_slide()
		
	# decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
 
"""
	Updates player.dir and notifies the attack component to flip hitboxes.
	Called before attack and movement handling each frame.
"""
func update_direction() -> void:
	if player.velocity.x < 0:
		player.dir = "Left"
		if player.attack_component.has_method("update_hitbox_direction"):
			player.attack_component.update_hitbox_direction("Left")
	elif player.velocity.x > 0 or player.velocity.y != 0:
		player.dir = "Right"
		if player.attack_component.has_method("update_hitbox_direction"):
			player.attack_component.update_hitbox_direction("Right")
 
# ==============================
# INTERNAL HELPERS
# ==============================

"""
	Reads the player's movement input axes and returns them as a direction vector.
"""
func _get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
 
"""
	Burns or recovers stamina based on sprint input and direction.
	Returns true if the player is actively sprinting this frame.
"""
func _handle_stamina(direction: Vector2, delta: float) -> bool:
	var is_sprinting := false
	
	if Input.is_action_pressed("sprint") \
			and current_stamina > 0 \
			and direction != Vector2.ZERO:
		is_sprinting = true
		current_stamina -= player.class_data.stamina_burn * delta
		current_stamina = maxf(0.0, current_stamina)
		st_recovery_timer = 0.0
	
	if not is_sprinting and current_stamina < player.class_data.max_stamina:
		st_recovery_timer += delta
		if st_recovery_timer >= player.class_data.stamina_recovery_delay:
			current_stamina += player.class_data.stamina_recovery * delta
			current_stamina = minf(current_stamina, player.class_data.max_stamina)
	
	return is_sprinting
 
"""
	Returns the appropriate target speed for this frame based on whether
	the player is sprinting or walking.
"""
func _target_speed(is_sprinting: bool) -> float:
	if is_sprinting:
		return player.class_data.walk_speed * player.class_data.run_multiplier
	return player.class_data.walk_speed
