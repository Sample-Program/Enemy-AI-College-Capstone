"""
	This script handles behavior for the slime enemy, such as it's state transitions and
	other factors such as health, speed, and wandering. This enemy has a unique behavior,
	and splits upon death into two smaller slimes.
"""

extends BasicEnemy

var slime_scene = preload("res://Entities/Enemies/BasicEnemies/SlimeEnemy/SlimeEnemy.tscn") 
# get the scene so small slimes can spawn ^

@export var can_split := true # no infinite spawning
@export var can_retreat: bool = true # smaller slimes dont retreat
var is_spawned_slime: bool = false # if the current slime is a smaller slime

"""
	This method finds a position for the smaller slimes to spawn onto.
	It avoids spawning inside walls, other enemies, or obstacles.
"""
func find_free_spawn_position() -> Vector2:
	var nav_region = get_node("/root/Node2D/NavigationRegion2D")
	var nav_map = nav_region.get_navigation_map()  # this is a RID (resource id) directly
	
	for i in range(10):
		var random_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var test_pos = global_position + random_offset
		
		# Query the navmesh using NavigationServer2D
		var nav_pos = NavigationServer2D.map_get_closest_point(nav_map, test_pos)
		
		if nav_pos.distance_to(test_pos) < 10:
			return nav_pos
		
	# fallback: snap to slime's current position on navmesh
	return NavigationServer2D.map_get_closest_point(nav_map, global_position)

"""
	This method is what creates the two new slimes. It verifies it's parent is a slime
	that can split (so no infinite splitting) and then finds a free nearby location to spawn
	onto. It sets the (weaker) values for the smaller slimes as well.
"""
func split_slime():
	if !can_split:
		return
	
	for i in range(2):
		var new_slime = slime_scene.instantiate()
		var spawn_pos = find_free_spawn_position()
		
		# Set properties BEFORE adding to the scene
		new_slime.is_spawned_slime = true
		new_slime.can_retreat = false
		new_slime.can_split = false
		new_slime.scale = scale * 0.75
		new_slime.global_position = spawn_pos
	
		# Add to scene first so child nodes exist
		get_parent().add_child(new_slime)
		new_slime.set_health(new_slime.max_hp * 0.5)
		new_slime.critical_health = 0
		
		# Now safely access nav_agent
		if target != null:
			new_slime.set_target(target)
			if new_slime.nav_agent != null:
				new_slime.nav_agent.target_position = target.global_position
			new_slime.call_deferred("_set_state", EnemyState.CHASE)
		else:
			new_slime.set_target(null)
			new_slime.call_deferred("_set_state", EnemyState.IDLE)

"""
	This function is ran on startup of the game, and sets various values that the mushroom enemy
	has so that they can be used later.
"""
func _ready() -> void:
	add_to_group("enemies")
	
	if not is_spawned_slime:
		_set_state(EnemyState.IDLE)
	
	$sprite_animations.animation_finished.connect(_on_animation_finished)
	
	# Attack Fields
	attack_damage = 10
	if is_spawned_slime:
		attack_damage *= 0.5  # small slimes deal half damage
	desired_attack_range = 4
	speed = 90
	
	# Health Fields
	max_hp = 75
	set_health(max_hp)
	critical_health = 25
	hurt_resit = 0.75
	set_resistance(base_resit)
	collision_floor_layer = 3

"""
	Overrides the basic perform_attack in BasicEnemy.gd to allow for enemy-specific attacks.
	
	@param: The animation to play when attacking
"""
func perform_attack(animation: String) -> void:
	if target == null:
		return
		
	# If animation already playing, don't restart or re-roll
	if $sprite_animations.animation == animation and $sprite_animations.is_playing():
		return

	$sprite_animations.sprite_frames.set_animation_loop(animation, false)
	$sprite_animations.play(animation)

"""
	Processes the enemy logic every frame and calls the current state's respective helper method that
	contains the logic of the current state.
	@param: The time elapsed in seconds since the previous frame.
	@author: Sam Plemmons
"""
func _physics_process(_delta: float) -> void:
	# Only check allies if this slime can retreat
	if can_retreat:
		_check_allies()
	
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
	This makes sure animations are not skipped by ensuring they are played the full length.
	It also handles checking to retreat after being hurt.
"""
func _on_animation_finished():
	# HURT Animation
	if $sprite_animations.animation == "hurt":
		set_damaged(false)
		set_resistance(base_resit)
		
		# After hurt animation, check if we should retreat
		if (get_health() <= critical_health and get_closest_ally() != null and !has_retreated and can_retreat):
			_set_state(EnemyState.RETREAT)
		else:
			# Back to previous state
			_set_state(EnemyState.IDLE)
			
	# ATTACK Animation
	elif $sprite_animations.animation == "attack_impact":
		target.take_damage(attack_damage)
		$sprite_animations.sprite_frames.set_animation_loop("attack_recover", false)
		$sprite_animations.play("attack_recover")
	# DEAD Animation
	elif $sprite_animations.animation == "dead":
		split_slime()

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
