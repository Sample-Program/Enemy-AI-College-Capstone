class_name PlayerHealth
extends Node
 
# ==============================
# PLAYER REFERENCE
# ==============================
var player: Player
 
# ==============================
# HEALTH STATE
# ==============================
var current_health: int = 0
var is_dead: bool = false
var is_reviving: bool = false
 
var death_timer: float = 0.0
var revive_health_timer: float = 0.0
var health_tick_timer: float = 0.0
 
# ==============================
# SIGNALS
# ==============================
signal health_changed(new_value: int)
signal player_died
signal player_revived
 
"""
	Called by PlayerBase._ready() to inject the player reference and
	initialize health from class data.
"""
func setup(p: Player) -> void:
	player = p
	current_health = player.class_data.max_hp
 
"""
	Called every physics frame when the player is dead or reviving.
	Ticks the death wait timer, then ticks health regeneration during revive.
"""
func tick(delta: float) -> void:
	if is_dead and not is_reviving:
		death_timer += delta
		if death_timer >= player.class_data.revive_time:
			revive()
		return
	
	if is_reviving:
		_handle_revive_tick(delta)
 
"""
	Reduces current health by amount. Triggers die() if health reaches zero.
	Does nothing if the player is already dead.
"""
func take_damage(amount: int) -> void:
	if is_dead or is_reviving:
		return
	
	current_health -= amount
	current_health = maxi(0, current_health)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		die()
 
"""
	Marks the player as dead, stops attacking, plays the death animation,
	and emits player_died for any listeners (e.g. game manager, UI).
"""
func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	player.is_attacking = false
	player_died.emit()
	
	if player.anim_sprite:
		player.anim_sprite.play("Death_" + player.dir)
	else:
		push_error("No animated sprite available to play death animation")
 
"""
	Begins the revive sequence: clears dead state, resets all timers,
	sets health to 1, and plays the revive animation.
"""
func revive() -> void:
	is_reviving = true
	is_dead = false
	current_health = 1
	
	death_timer = 0.0
	revive_health_timer = 0.0
	health_tick_timer = 0.0
	
	health_changed.emit(current_health)
	player_revived.emit()
	
	if player.anim_sprite:
		player.anim_sprite.play("Revive_" + player.dir)
	else:
		push_error("No animated sprite available to play revive animation")
 
"""
	Called by PlayerBase._on_animation_finished() when the revive animation
	completes. Clears the reviving flag.
"""
func finish_revive() -> void:
	is_reviving = false
 
# ==============================
# INTERNAL HELPERS
# ==============================
 
"""
	Ticks health regeneration during the revive sequence.
	Restores health in increments defined by class data until max HP is reached.
"""
func _handle_revive_tick(delta: float) -> void:
	revive_health_timer += delta
	health_tick_timer += delta
	
	if health_tick_timer >= player.class_data.health_tick_rate \
			and current_health < player.class_data.max_hp:
		health_tick_timer = 0.0
		current_health = mini(
			player.class_data.max_hp,
			current_health + player.class_data.health_tick_amount
		)
		health_changed.emit(current_health)
