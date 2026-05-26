"""
	This script handles behavior for the healer "bush" enemy such as it's state transitions and
	other factors such as health, speed, and wandering.
"""

extends BasicEnemy

## Bush Enemy Fields
var targets_in_attack_range: Array[Entity] = []
var heal_amount = 50
var player_in_range: Player

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
	attack_damage = 25
	desired_attack_range = 4
	speed = 75
	
	# Health Fields
	max_hp = 75
	set_health(max_hp)
	critical_health = 0
	hurt_resit = 1
	base_resit = 0.5
	set_resistance(base_resit)
	collision_floor_layer = 5
	
	# Pathfinding Fields
	idle_duration = 4.0

"""
	Processes the enemy logic every frame and calls the current state's respective helper method that
	contains the logic of the current state.
	@param: The time elapsed in seconds since the previous frame.
	@author: Sam Plemmons
"""
func _physics_process(_delta: float) -> void:
	_check_allies()
	match current_state:
		EnemyState.IDLE: _idle_state("idle")
		EnemyState.WANDER: _wander_state("chase")
		EnemyState.CHASE: _chase_state("chase")
		EnemyState.ATTACK: _attack_state("attack_impact")
		EnemyState.RETREAT: _retreat_state("chase", "idle")
		EnemyState.HURT: _hurt_state("hurt")
		EnemyState.DEAD: _dead_state("dead")
		

"""
	If no state transitions occur, the bush enemy will chase to a valid tagret
	within range. This target can either be a player if the bish enemy is targetting
	the player, or a basic enemy if they are at critical health.
	
	Katelyn's additions (slight tweaks now--used to have a lot more 
	before scrapping pathfinding):
		Pathfinding chase behavior to ensure the enemy chases the player.
	
	@param: The specific animation to play
"""
func _chase_state(animation: String) -> void:
	# DEAD State
	if get_health() <= 0:
		_set_state(EnemyState.DEAD)
	
	# RETREAT State
	elif get_health() <= critical_health and get_closest_ally() != null and !has_retreated:
		_set_state(EnemyState.RETREAT)
	
	# HURT State
	elif is_damaged():
		_set_state(EnemyState.HURT)
	
	# ATTACK State - Check if player is in attack hitbox
	elif target != null and ready_to_attack:
		_set_state(EnemyState.ATTACK)
		return  # Stop here if attacking
	
	# CHASE State - Enemy Target
	elif target is BasicEnemy:
		if !target.is_dead():
			var safe_point = get_point_near_ally(target)
			# Continue following the path
			set_path(safe_point)
			#print("chasing to target")
			$sprite_animations.sprite_frames.set_animation_loop(animation, false)
			$sprite_animations.play(animation)
		else:
			# set the target to the player that killed the enemy
			target = target.target

	elif target != null:
		# Normal chase behavior
		set_path(target.position)
		# set animation to CHASE
		$sprite_animations.sprite_frames.set_animation_loop(animation, false)
		$sprite_animations.play(animation)
	# IDLE State
	else:
		_set_state(EnemyState.IDLE)
			
"""
	This function handles setting the mushroom enemy's states. It receives the new state
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
	This makes sure animations are not skipped by ensuring they are played the full length.
	It also handles checking to retreat after being hurt.
	@author: Sam Plemmons
"""
func _on_animation_finished() -> void:
	# HURT Animation
	if $sprite_animations.animation == "hurt":
		set_damaged(false)
		set_resistance(base_resit)
		# Back to prvious state
		_set_state(previous_state)
	# ATTACK Animation
	elif $sprite_animations.animation == "attack_impact":
		_deal_damage()
		$sprite_animations.sprite_frames.set_animation_loop("attack_recover", false)
		$sprite_animations.play("attack_recover")
		ready_to_attack = true
	# DEAD Animation
	elif $sprite_animations.animation == "dead":
		queue_free()
		
'''
	Helper method that handles "dealing damage." If the target in range is a player
	the enemy will deal damage as normal. If they are an enemy, heal them.
'''
func _deal_damage() -> void:
	for tar in targets_in_attack_range:
			# Heal ally is they are being targeted
			if tar is Enemy:
				tar.set_health(tar.get_health() + heal_amount)
				# If target is above critical, resest target
				if tar.get_health() > tar.critical_health:
					#print("more than crit")
					# TESTING
					_set_state(EnemyState.IDLE)
					_set_state(EnemyState.IDLE)
					tar.set_critical(false)
					if tar == get_target():
						print(get_target())
						if player_in_range != null:
							set_target(player_in_range)
						else:
							_set_state(EnemyState.IDLE)
						pass
			# Player takes damage
			else:
				#print('knockback')
				# knock player back
				tar.movement_component.apply_knockback(global_position, 500.0)
				tar.take_damage(attack_damage)

"""
	Overwrites _check_allies to find an ally who is at critical health and begins targetting them.
	@author: Sam Plemmons
"""
func _check_allies() -> void:
	for ally in retreat_allies:
		if ally.is_critical():
			if get_target() != ally:
				if get_target() is Player:
					player_in_range = get_target()
				set_target(ally)
				_set_state(EnemyState.CHASE)
			return  # Only heal one ally at a time
			

"""
	This function handles whether the player or another enemy is within field of view.
	@author: Sam Plemmons
"""
func _on_field_of_view_area_body_entered(body: Node2D) -> void:
	if body is Entity and not (body is Enemy):
		player_in_range = body
		if not (target is Enemy):
			set_target(body)

"""
	This helper method handles when a entity enters the enemy's hitbox.
	@param: The entity that has walked into this hitbox
	@author: Sam Plemmons
"""
func _on_attack_hitbox_area_body_entered(body: Node2D) -> void:
	# Call attack hitbox helper
	_on_attack_hitbox_area_body_helper(body, true)
	# Adds body to attack range array
	if body is Entity && !(body in targets_in_attack_range) && (body != self):
		targets_in_attack_range.append(body)
		
"""
	This helper method handles when a entity exits the enemy's hitbox.
	@param: The entity that has walked into this hitbox
	@author: Sam Plemmons
"""
func _on_attack_hitbox_area_body_exited(body: Node2D) -> void:
	# Call attack hitbox helper
	_on_attack_hitbox_area_body_helper(body, false)
	# Removes body to attack range array
	if body is Entity and targets_in_attack_range.has(body) && (body != self):
		targets_in_attack_range.erase(body)
		
"""
	This helper method handles wwhether the body in the attack area is a player
	or enemy.
	@author: Sam Plemmons
"""
func _on_attack_hitbox_area_body_helper(body: Node2D, attack: bool) -> void:
	# if target is enemy at critical
	if body is Enemy:
		var check_enemy := body as BasicEnemy
		if check_enemy and check_enemy.is_critical():
			ready_to_attack = attack
	# If target is player
	elif body is Player:
		ready_to_attack = attack

"""
	This helper method adds nearby enemies to potential allies this enemy could
	retreat to.
	@author: Sam Plemmons
"""
func _on_heal_detect_range_body_entered(body: Node2D) -> void:
	# add enemy to list
	if body is Enemy and not (body == self):
		retreat_allies.append(body)

"""
	This helper method removes enemies from retreat enemies list and if player
	leaves line of sight.
	@author: Sam Plemmons
"""
func _on_heal_detect_range_body_exited(body: Node2D) -> void:
	if body is Player:
		# player has left line of sight
		player_in_range = null
		if !(get_target() is Enemy):
			set_target(null)
	# remove enemy from list
	elif body is Enemy and not (body == self):
		if retreat_allies.has(body):
			retreat_allies.erase(body)
		
