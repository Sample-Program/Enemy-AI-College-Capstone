"""
	This script handles behavior for the flying "bug" enemy such as it's state transitions and
	other factors such as health, speed, and wandering.
"""

extends BasicEnemy

var projectile_scene := preload("res://Components/Projectiles/FlyingBugProjectile/FlyingBugProjectile.tscn")

var attack_locked: bool = false
var attack_cooldown: float = 1.0  # 1 second between attacks
var attack_timer: float = 0.0

# Bleed attack variable (exclusive to flying enemy)
var is_bleed_attack: bool = false
var attack_bleed_cooldown: float = 6.0
var attack_bleed_timer: float = 0.0
var attack_bleed_chance: float = 0.25 # change if too frequent/infrequent

"""
	Overrides the basic perform_attack in BasicEnemy.gd to allow for enemy-specific attacks.
	In this case, allows for a projectile to have a bleed attribute to apply bleed to the player.
	
	@param: The animation to play when attacking
"""
func perform_attack(animation: String = "attack_impact") -> void:
	if target == null:
		return
	
	# Only lock if the ATTACK animation is currently playing
	if attack_locked or $sprite_animations.animation == animation:
		return
	
	# Lock attack
	attack_locked = true
	attack_timer = attack_cooldown
	
	if attack_bleed_timer <= 0 and randf() < attack_bleed_chance:
		is_bleed_attack = true
		attack_bleed_timer = attack_bleed_cooldown
	else:
		is_bleed_attack = false
	
	# Play attack animation
	$sprite_animations.sprite_frames.set_animation_loop(animation, false)
	$sprite_animations.play(animation)

"""
	This function is ran on startup of the game, and sets various values that the mushroom enemy
	has so that they can be used later.
	@authors: Sam Plemmons
"""
func _ready() -> void:
	# Add to group "enemies" for pathfinding avoidance
	add_to_group("enemies")
	# Sets the current state
	_set_state(EnemyState.IDLE)
	# Connects Animation Finishd
	$sprite_animations.animation_finished.connect(_on_animation_finished)
	# Find the pathfinding node to reference later
	#pathfinding = get_tree().root.get_node("PathfindingTestMap/Pathfinding")
	
	# Attack Fields
	attack_damage = 5
	desired_attack_range = 20
	
	# Health Fields
	max_hp = 75
	set_health(max_hp)
	critical_health = 0
	collision_floor_layer = 4
	
	# Pathfinding Fields
	idle_duration = 4.0

"""
	Processes the enemy logic every frame and calls the current state's respective helper method that
	contains the logic of the current state.
	@param: The time elapsed in seconds since the previous frame.
"""
func _physics_process(delta: float) -> void:
	_check_allies()

	# Countdown attack timer
	if attack_timer > 0.0:
		attack_timer = max(attack_timer - delta, 0.0)
	else:
		attack_locked = false  # unlock attack when timer reaches 0

	# set the timer cooldown
	attack_bleed_timer = max(attack_bleed_timer - delta, 0.0)

	match(current_state):
		EnemyState.IDLE: _idle_state("idle")
		EnemyState.WANDER: _wander_state("idle")
		EnemyState.CHASE: _chase_state("idle")
		EnemyState.ATTACK: _attack_state("attack_impact")
		EnemyState.RETREAT: _retreat_state("idle", "idle")
		EnemyState.HURT: _hurt_state("hurt")
		EnemyState.DEAD: _dead_state("dead")

"""
	This function handles setting the bug enemy's states. It receives the new state
	to transition into and sets the current and previous state variables to reflect accordingly.
	It also resets values and animations if necessary.
	@param: The new state to set the enemy to
"""
func _set_state(new_state: EnemyState):
	# change state
	if new_state != current_state:
		previous_state = current_state
		current_state = new_state
		
		# reset the timers
		if current_state == EnemyState.IDLE:
			idle_timer = 0.0 # idle timer reset
			$sprite_animations.play("idle")
		
		# force pathfind immediately
		if current_state == EnemyState.CHASE:
			repath_timer = REPATH_TIME
		
		if previous_state == EnemyState.WANDER:
			wandering_point = Vector2.ZERO
			
"""
	This function handles whether the player is within the mushroom enemy's view area.
	@param: The entity that has walked into this area
	@author: Sam Plemmons
"""
func _on_field_of_view_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not (body is Enemy):
		set_target(body)

"""
	This function handles whether an ally is within the mushroom enemy's retreat area.
	@param: The entity that has walked into this area
	@author: Sam Plemmons
"""
func _on_retreat_area_body_entered(body: Node2D) -> void:
	if body is Enemy and not (body == self):
		retreat_allies.append(body)

"""
	This function handles when an ally exits the bug enemy's retreat area.
	@param: The entity that has walked into this area
	@author: Sam Plemmons
"""
func _on_retreat_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and not (body is Enemy):
		set_target(null)
	elif body is Enemy and not (body == self):
		if retreat_allies.has(body):
			retreat_allies.erase(body)

"""
	This helper method handles when a player enters the enemy's hitbox.
	@param: The entity that has walked into this hitbox
	@author: Sam Plemmons
"""
func _on_attack_range_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not (body is Enemy):
		ready_to_attack = true

"""
	This helper method handles when a player exits the enemy's hitbox.
	@param: The entity that has walked into this hitbox
	@author: Sam Plemmons
"""
func _on_attack_range_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and not (body is Enemy):
		ready_to_attack = false

"""
	This makes sure animations are not skipped by ensuring they are played the full length.
	It also handles checking to retreat after being hurt.
"""
func _on_animation_finished():
	# HURT Animation
	if $sprite_animations.animation == "hurt":
		set_damaged(false)
		set_resistance(base_resit)
		
		# After hurt animation, check if we should retreat
		if (get_health() <= critical_health and get_closest_ally() != null 
		and !has_retreated):
		
			_set_state(EnemyState.RETREAT)
		else:
			# Back to previous state
			_set_state(EnemyState.IDLE)
			
	# ATTACK Animation
	elif $sprite_animations.animation == "attack_impact":
		_fire_projectile()  # actually spawn the projectile
		# Play recovery animation
		$sprite_animations.sprite_frames.set_animation_loop("attack_recover", false)
		$sprite_animations.play("attack_recover")
	elif $sprite_animations.animation == "attack_recover":
		# Unlock attack so it can happen again
		attack_locked = false
		# Return to idle or previous state
		_set_state(EnemyState.IDLE)
	# DEAD Animation
	elif $sprite_animations.animation == "dead":
		pass
"""
	Creates and fires a projetile object at the target. Uses the target's current
	position and this enemy's position to find a vector for the projectile to
	travel along.
"""
func _fire_projectile() -> void:
	if target == null:
		return
	var projectile = projectile_scene.instantiate()
	#initialize the attack type
	projectile.init(is_bleed_attack, 5)
	if (is_bleed_attack):
		projectile.modulate = Color(0.792, 0.0, 0.075, 1.0) # red tint
	# Spawn at enemy position (or use a muzzle offset)
	projectile.global_position = global_position
	# Direction toward the target
	projectile.direction = (target.global_position - global_position).normalized()
	# Apply same damage as the ATTACK_DAMAGE
	projectile.damage = attack_damage
	# flip projectile
	for child in projectile.get_children():
		child.scale.x = -1
	# Add to main scene
	get_tree().current_scene.add_child(projectile)
