"""
This script handles the specific pathfinding for the melee enemy (Mushroom in this case).
It also handles other behavior for the mushroom enemy such as it's state transitions and
other factors such as health, speed, and wandering.
"""

extends BasicEnemy

var current_path: Array[Vector2] = []
var path_index: int = 0

# Stun attack variable (exclusive to mushroom enemy)
var is_stun_attack: bool = false
var attack_stun_cooldown: float = 6.0
var attack_stun_timer: float = 0.0
var attack_stun_chance: float = 0.25 # change if too frequent/infrequent
var attack_stun_duration: float = 2.0 # change if too long/short

"""
	This function is ran on startup of the game, and sets various values that the mushroom enemy
	has so that they can be used later.
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
	attack_damage = 10
	desired_attack_range = 4
	speed = 100
	
	# Health Fields
	max_hp = 75
	set_health(max_hp)
	critical_health = 15
	hurt_resit = 0.5
	set_resistance(base_resit)
	collision_floor_layer = 2
	
	# Pathfinding Fields
	idle_duration = 4.0

"""
	This applies a yellow color onto the mushroom enemy when a stun attack is being used, 
	notifying the player that a status effect will be applied if hit.
"""
func _show_stun_indicator() -> void:
	$sprite_animations.modulate = Color(1.5, 1.5, 0.2) # bright yellow
	await get_tree().create_timer(0.3).timeout # how long it lasts
	$sprite_animations.modulate = Color(1, 1, 1) # reset

"""
	Overrides the basic perform_attack in BasicEnemy.gd to allow for enemy-specific attacks.
	In this case, allows for the mushroom enemy to apply stun to the player.
	
	@param: The attack animationt to play
"""
func perform_attack(animation: String) -> void:
	if target == null:
		return

	# If animation already playing, don't restart or re-roll
	if $sprite_animations.animation == animation and $sprite_animations.is_playing():
		return

	if attack_stun_timer <= 0 and randf() < attack_stun_chance:
		is_stun_attack = true
		attack_stun_timer = attack_stun_cooldown
		_show_stun_indicator()
	else:
		is_stun_attack = false

	$sprite_animations.sprite_frames.set_animation_loop(animation, false)
	$sprite_animations.play(animation)

"""
	Processes the enemy logic every frame and calls the current state's respective helper method that
	contains the logic of the current state.
	@param: The time elapsed in seconds since the previous frame.
	@author: Sam Plemmons
"""
func _physics_process(_delta: float) -> void:
	_check_allies()
	
	# set the timer cooldown
	attack_stun_timer = max(attack_stun_timer - _delta, 0.0)
	
	match(current_state):
		EnemyState.IDLE: _idle_state("idle")
		EnemyState.WANDER: _wander_state("chase")
		EnemyState.CHASE: _chase_state("chase")
		EnemyState.ATTACK: _attack_state("attack_impact")
		EnemyState.RETREAT: _retreat_state("chase", "idle")
		EnemyState.HURT: _hurt_state("hurt")
		EnemyState.DEAD: _dead_state("dead")
		
"""
	This function handles setting the mushroom enemy's states. It receives the new state
	to transition into and sets the current and previous state variables to reflect accordingly.
	It also resets values and animations if necessary.
	@param: The new state to set the enemy to
	@author: Sam Plemmons
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
	This function handles when an ally exits the mushroom enemy's retreat area.
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
		# cancel if stunned
		if is_stunned_flag or current_state != EnemyState.ATTACK:
			return
		target.take_damage(attack_damage)
		if is_stun_attack:
			target.apply_stun(attack_stun_duration)
		$sprite_animations.sprite_frames.set_animation_loop("attack_recover", false)
		$sprite_animations.play("attack_recover")
	# DEAD Animation
	elif $sprite_animations.animation == "dead":
		pass

"""
	This helper method handles when a player enters the enemy's hitbox.
	@param: The entity that has walked into this hitbox
	@author: Sam Plemmons
"""
func _on_attack_hitbox_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not (body is Enemy):
		ready_to_attack = true

"""
	This helper method handles when a player exits the enemy's hitbox.
	@param: The entity that has walked into this hitbox
	@author: Sam Plemmons
"""
func _on_attack_hitbox_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and not (body is Enemy):
		ready_to_attack = false
