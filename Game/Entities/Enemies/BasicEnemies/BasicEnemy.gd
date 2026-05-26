"""
This script handles the specific pathfinding for the basic enemy logic.
"""

class_name BasicEnemy
extends Enemy

signal state_changed(from_state: String, to_state: String)

# prevent a local var
var grass_layer: TileMapLayer = null
var wall_layer: TileMapLayer = null

## Basic Enemy Fields
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var facing_right: bool = true
var ready_to_attack: bool = false
var speed: float = 50
var max_hp: int = 75
var critical_health: int = 25
var base_resit: float = 1.0
var hurt_resit: float = 0.9
var return_location: Vector2
var wandering_point: Vector2 = Vector2.ZERO
var attack_damage: int = 10
var retreat_allies: Array[Enemy] = []
var last_position: Vector2 = Vector2.ZERO # used for above
var retreat_initialized: bool = false
var has_retreated: bool = false
var desired_attack_range: float = 20.0
var idle_timer: float = 0.0
var idle_duration: float = 2.0
var collision_floor_layer: int = 1

## Bleeding values
var bleed_stacks: int = 0
var bleed_timer: float = 0.0
var bleed_duration: float = 10 # last for 10 secs
var cur_bleed_duration: float = 0 #how long current bleed is
var bleed_tick_rate: float = 1.0
var bleed_damage: int = 2

@onready var status_root: Node2D = $StatusIcons
@onready var bleed_icon: Sprite2D = $StatusIcons/bleed_sprite
@onready var stun_icon: Sprite2D = $StatusIcons/stun_sprite
@onready var burn_icon: Sprite2D = $StatusIcons/burn_sprite

## Stunned values
var stun_duration: float = 0.0
var stun_timer: float = 0.0
var is_stunned_flag = false

## Burning values
var burn_stacks: int = 0
var burn_timer: float = 0.0
var burn_duration: float = 10 # last for 10 secs
var cur_burn_duration: float = 0 #how long current bleed is
var burn_tick_rate: float = 0.5
var burn_damage: int = 2

var status_effects: Array = [] # holds the effects

"""
	Adds a status effect to the list of status effects after verifying that they exist
	to prevent null errors. Sets the status effect visible for the player to see.
	
	@param id: the ID of the status effect to add (just the name)
	@param node: the node that holds that sprite to turn visible
"""
func add_status(id: String, node: Sprite2D):
	status_effects.append({
		"id": id,
		"node": node
	})
	
	node.visible = true
	
	_reposition_status_icons()
	
"""
	Removes a status effect from the list of status effects and turns off the visual
	that informs the player that they have the status effect.
	
	@param id: the ID of the status effect to add (just the name)
"""
func remove_status(id: String):
	for i in range(status_effects.size()):
		if status_effects[i]["id"] == id:
			var node = status_effects[i]["node"]
			
			#node.queue_free() # or node.visible = false
			node.visible = false
			status_effects.remove_at(i)
			break
			
	_reposition_status_icons()

"""
	Reorganizes the existing status effects using the spacing and offset
	to dyanmically place the status effects next to the enemy's HP.
"""
func _reposition_status_icons():
	var spacing = 8
	var start_offset = Vector2(15, -39)
	
	for i in range(status_effects.size()):
		var icon = status_effects[i]["node"]
		
		if icon == null or not is_instance_valid(icon):
			continue
			
		icon.position = start_offset + Vector2(i * spacing, 0)

func _ready() -> void:
	# NavMesh
	nav_agent.path_desired_distance = 12.0
	nav_agent.target_desired_distance = 12.0
	nav_agent.avoidance_enabled = true
	print('onready')
	# bind nodes once (status effects)
	for effect in status_effects:
		match effect["id"]:
			"bleed":
				effect["node"] = bleed_icon
			"stun":
				effect["node"] = stun_icon
			"burn":
				effect["node"] = burn_icon

func _process(delta: float) -> void:
	if target != null:
		flip_enemy(target.global_position.x < global_position.x)
		_force_check_attack_hitbox()
		_process_status(delta)

"""
	Applies burn stacks onto the enemy and turns on the burn icon.
"""
func apply_burn(stacks: int) -> void:
	burn_stacks += stacks
	# show icon in UI system
	if !(burn_icon.visible == true):
		add_status("burn", burn_icon)

"""
	Applies stun to the enemy and turns on the stun icon.
"""
func apply_stun(duration: float) -> void:
	stun_duration = duration
	stun_timer = 0.0
	ready_to_attack = false
	is_stunned_flag = true
	add_status("stun", stun_icon)
	_stop_movement_and_animation()
	_set_state(EnemyState.STUNNED)

"""
	Ensures the enemy cannot move and does not play any animations while stunned.
	Also prevents any other actions.
"""
func _stunned_state(animation: String) -> void:
	if get_health() <= 0:
		_set_state(EnemyState.DEAD)
		return

	# Stop movement only
	velocity = Vector2.ZERO
	move_and_slide()

	# Play animation
	$sprite_animations.sprite_frames.set_animation_loop(animation, false)
	$sprite_animations.play(animation)
		

"""
	Processes all active status effects on the enemy by managing their timers
	such as enabling/disabling stun, and ticking status effects such as burn or bleed.
"""
func _process_status(delta: float) -> void:
	# DEAD CHECK
	if get_health() <= 0:
		_set_state(EnemyState.DEAD)
		return
	
	# STUNNED CHECK (ensure stun is authoritative over state changes)
	if is_stunned_flag:
		if current_state != EnemyState.STUNNED:
			_set_state(EnemyState.STUNNED)
	
	# BURN (functions similarly to bleed)
	if burn_stacks > 0:
		#print("burn stacks: ", burn_stacks)
		burn_timer += delta
		cur_burn_duration += delta
		
		if cur_burn_duration >= burn_duration:
			burn_stacks -= 1
			#decay over time
		
		if burn_timer >= burn_tick_rate:
			burn_timer = 0.0
			
			take_damage(burn_stacks * burn_damage, false)
	if burn_stacks <= 0:
		burn_stacks = 0
		remove_status("burn")
	
	# STUN
	if is_stunned_flag:
		stun_timer += delta
		
		if stun_timer >= stun_duration:
			remove_status("stun")
			is_stunned_flag = false
			stun_timer = 0.0
			stun_duration = 0.0
			_set_state(EnemyState.IDLE)
	
	# BLEED 
	if bleed_stacks > 0:
		#print("bleed stacks: ", bleed_stacks)
		bleed_timer += delta
		cur_bleed_duration += delta
		
		if cur_bleed_duration >= bleed_duration:
			bleed_stacks -= 1
			#decay over time
		
		if bleed_timer >= bleed_tick_rate:
			bleed_timer = 0.0
			
			take_damage(bleed_stacks * bleed_damage, false)
	if bleed_stacks <= 0:
		bleed_stacks = 0
		remove_status("bleed")

"""
	Applies bleed stacks onto the enemy and enables the icon.
"""
func apply_bleed(stacks: int = 1) -> void:
	bleed_stacks += stacks

	# show icon in UI system
	add_status("bleed", bleed_icon)

"""
	This function handles the logic for the IDLE state that a mushroom enemy can be in.
"""
func _idle_state(animation: String) -> void:	
	# IDLE timer
	idle_timer += get_process_delta_time()
	# DEAD State
	if get_health() <= 0:
		_set_state(EnemyState.DEAD)
	# CHECK FOR STUN BEFORE CHANGING STATES
	# RETREAT State
	if get_health() <= critical_health and get_closest_ally() != null and !has_retreated:
		_set_state(EnemyState.RETREAT)
	# HURT State
	elif is_damaged() and current_state != EnemyState.STUNNED and stun_duration > 0:
		_set_state(EnemyState.HURT)
	# WANDER State
	elif target == null and idle_timer >= idle_duration:
		_set_state(EnemyState.WANDER)
	# CHASE State
	elif target != null:
		_set_state(EnemyState.CHASE)
	else:
		# set animation to IDLEs
		$sprite_animations.sprite_frames.set_animation_loop(animation, true)
		$sprite_animations.play(animation)

## WANDER State
"""
	This function handles the logic for the wander state. It selects a random point within the
	mushroom enemy's field of view and ensures that it is a valid point to walk to. If so, it
	calls _update_path_to_target and then move and slide to walk towards it.
	@author: Sam Plemmons
"""
func _wander_state(animation: String) -> void:
	# DEAD State
	if get_health() <= 0:
		_set_state(EnemyState.DEAD)
	# RETREAT State
	elif get_health() <= critical_health and get_closest_ally() != null and !has_retreated:
		_set_state(EnemyState.RETREAT)
	# HURT State
	elif is_damaged():
		_set_state(EnemyState.HURT)
	# CHASE State
	elif target != null:
		_set_state(EnemyState.CHASE)
	# WANDERING State
	elif target == null:
		if wandering_point == Vector2.ZERO:
			var field_of_view: CollisionShape2D = $field_of_view_area/field_of_view
			var attempts := 0
			var found_point := false
			
			while not found_point and attempts < 5:
				attempts += 1
			
				var random_angle = randf_range(0.0, TAU)
				var random_distance = randf_range(0.0, field_of_view.shape.radius)
				
				var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
				var candidate = global_position + offset
				
				var nav_point = NavigationServer2D.map_get_closest_point(
					nav_agent.get_navigation_map(),
					candidate
				)
				
				if nav_point.distance_to(global_position) <= field_of_view.shape.radius:
					wandering_point = nav_point
					found_point = true
				
			if not found_point:
				_set_state(EnemyState.IDLE)
				return
			
		set_path(wandering_point) #go 2 point
		# set animation to CHASE
		$sprite_animations.sprite_frames.set_animation_loop(animation, true)
		$sprite_animations.play(animation)
		if nav_agent.is_navigation_finished():
			wandering_point = Vector2.ZERO
			_set_state(EnemyState.IDLE)

"""
	This function handles the logic for the chase state. This includes how it can transition into
	DEAD state, RETREAT state, ATTACK state, and IDLE state when the player has moved out of its 
	view. 
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
	
	elif target != null:
		# Normal chase behavior
		set_path(target.global_position)
		# set animation to CHASE
		$sprite_animations.sprite_frames.set_animation_loop(animation, false)
		$sprite_animations.play(animation)
	# IDLE State
	else:
		_set_state(EnemyState.IDLE)

"""
	Basic perform attack that will be overriden when an enemy inflicts a status effect.
"""
func perform_attack(animation: String) -> void:
	# Default attack behavior
	#print('in perform')
	#print(target, ready_to_attack)
	if target and ready_to_attack:
		#print('starting attack')
		ready_to_attack = false
		# set animation to ATTACK IMPACT
		$sprite_animations.sprite_frames.set_animation_loop(animation, false)
		$sprite_animations.play(animation)
		#target.take_damage(attack_damage)
"""
	This function handles the health, entering DEAD state, and determines if the enemy is ready
	to attack. If so, it plays the correct animations accordingly.
"""
func _attack_state(animation: String) -> void:
	# DEAD State
	#print(ready_to_attack)
	if get_health() <= 0:
		#print("dead")
		_set_state(EnemyState.DEAD)
	# RETREAT State
	elif get_health() <= critical_health and get_closest_ally() != null and !has_retreated:
		#print("retreating")
		_set_state(EnemyState.RETREAT)
	# ATTACK State
	elif target != null and ready_to_attack:
		#print('attempting attack')
		if previous_state != EnemyState.RETREAT:
			#print('can attack')
			# Stop Movement
			#velocity = Vector2.ZERO
			var is_attack_anim = $sprite_animations.animation == animation \
			and $sprite_animations.is_playing()
			
			if is_attack_anim:
				# Lock movement during attack swing
				velocity = Vector2.ZERO
				move_and_slide()
			else:
				# Keep moving toward player if not currently attacking
				if target:
					set_path(target.global_position)
		# HURT State
		if is_damaged():
			_set_state(EnemyState.HURT)
		
		#print('doing attack')
		# send to handle specific attack
		perform_attack(animation)
		
	# CHASE State
	elif target != null:
		var distance = global_position.distance_to(target.global_position)
		
		if distance > desired_attack_range:
			_set_state(EnemyState.CHASE)
	# IDLE State
	else:
		_set_state(EnemyState.IDLE)

"""
	This function handles the RETREAT state that the mushroom enemy can use to retreat to a nearby
	ally when it reaches a critical point in it's health.
"""
func _retreat_state(moving_anim: String, still_anim: String) -> void:
	# DEAD State
	if get_health() <= 0:
		_set_state(EnemyState.DEAD)
	# HURT State
	elif is_damaged():
		_set_state(EnemyState.HURT)
	# Checks if we should retreat or not
	elif get_health() > critical_health:
		_reset_retreat(true, still_anim)
		print("retreat")
		_set_state(EnemyState.IDLE)
	
	# RETREAT State
	var ally := get_closest_ally()
	if ally:
		var safe_point = get_point_near_ally(ally)
		
		# Only print's message once, and initalize's the path
		if !retreat_initialized:
			# TESTING
			#print("Retreat to Ally at: ", ally.position)
			retreat_initialized = true
			#_update_path_to_target(safe_point)
		
		# Continue following the path
		set_path(safe_point)
		
		# Check if we've reached the point or not
		if path.size() > 0:
			var distance_to_target = global_position.distance_to(safe_point)
			# A random distance to be considered "safe" (idk what number to use)
			if distance_to_target < 30.0 and !ally.has_method("_deal_damage"): 
				# TESTING 
				#print("Reached safe point, stopping retreat")
				_reset_retreat(true, still_anim)
				print("retreat 2")
				_set_state(EnemyState.IDLE)
				return
		
		# Only set chase animation if we're actually moving
		if velocity.length() > 0.1:
			# set animation to CHASE
			$sprite_animations.sprite_frames.set_animation_loop(moving_anim, false)
			$sprite_animations.play(moving_anim)
		else:
			# If not moving, play idle
			$sprite_animations.play(still_anim)
	else:
		# TESTING
		#print("No allies to retreat to")
		# No allies to retreat to
		_reset_retreat(false, "idle")
		print("retreat 3")
		_set_state(EnemyState.IDLE)

"""
	Manually check if player is in attack hitbox (for stuck situations). This was necessary
	as the mushroom enemy would stop a few pixels away from the player (ex: 43) when the
	required range for attacking the player is roughly 40 pixels.
"""
func _force_check_attack_hitbox() -> void:
	if target == null:
		ready_to_attack = false
		return
		
	var in_hitbox := false
	
	var attack_area = $attack_hitbox_area
	if attack_area:
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body == target:
				in_hitbox = true
				break
				
	# Distance fallback to prevent shape inconsistencies 
	# (causing issues w ready to attack)
	var distance = global_position.distance_to(target.global_position)
	var in_range = distance <= desired_attack_range
	
	# combine both into one to determine if ready
	ready_to_attack = in_hitbox or in_range

"""
	This function sets the enemy's flags to indicate they have retreated already which
	should prevent repeated unnecessary retreating.
	@param: The ally to retreat to
"""
func _reset_retreat(found_ally: bool, animation: String) -> void:
	# If the NPC found an ally and ran to them, then they properly  "retreated"
	# otherwise they should still look for an ally to run to
	if found_ally:
		has_retreated = true
	
	retreat_initialized = false
	path = []
	current_path_index = 0
	velocity = Vector2.ZERO
	
	# Stop any movement immediately
	move_and_slide()
	
	# Explicitly set to idle animation
	$sprite_animations.sprite_frames.set_animation_loop(animation, true)
	$sprite_animations.play(animation)

"""
	This function handles the logic for the HURT state. This state handles playing a
	damaged animation and stopping the mushroom enemy from attacking (essentially
	stunning it).
	@author: Sam Plemmons
"""
func _hurt_state(animation: String) -> void:
	# DEAD State
	if get_health() <= 0:
		_set_state(EnemyState.DEAD)
		return
	
	# Stop Movement
	velocity = Vector2.ZERO
	move_and_slide()  # ensure the velocity stop is applied this frame
	
	# Make enemy temporarily resistant to further hits
	set_resistance(hurt_resit)
	
	# Play the hurt animation
	if $sprite_animations.animation != animation:
		# stops any running animation like "chase"
		$sprite_animations.stop()  
		$sprite_animations.sprite_frames.set_animation_loop(animation, false)
		$sprite_animations.play(animation)

"""
	This function handles the logic for the DEAD state. This ensures that the
	mushroom plays the dead animation.
	@author: Sam Plemmons
"""
func _dead_state(animation: String) -> void:
	## Bro doesn't have an icon 💀
	#i dont have an icon yet, but uncomment when i get one
	#burn_icon.visible = false
	bleed_icon.visible = false
	stun_icon.visible = false
	burn_icon.visible = false
	# turn off collision
	set_collision_layer_value(1, false)
	set_collision_layer_value(8, true)
	if $sprite_animations.animation != animation:
		# Dead animation
		$sprite_animations.sprite_frames.set_animation_loop(animation, false)
		# Start the hurt animation
		$sprite_animations.play(animation)

"""
	This function finds the nearest allied enemy and returns it as an Enemy object for
	for reference.
"""
func get_closest_ally() -> Enemy:
	var closest: Enemy = null
	var ally_distance: float
	var closest_distance: float
	
	for ally in retreat_allies:
		if !ally.is_dead():
			if closest == null:
				closest = ally
			else:
				ally_distance = self.position.distance_to(ally.position)
				closest_distance = self.position.distance_to(closest.position)
				if ally_distance < closest_distance:
					closest =  ally
	return closest

"""
	This function checks for any nearby allies in a critical state. This allows enemies to
	help other enemies in their field of view.
"""
func _check_allies() -> void:
	for ally in retreat_allies:
		if ally.is_critical():
			if get_target() != ally.get_target():
				#print("Going to Help Ally")
				pass
			set_target(ally.get_target())
			
"""
	This helper function gets the constant critical health that is specific for this enemy.
	@author: Sam Plemmons
"""
func get_critical_health() -> int:
	return critical_health

"""
	This function is what gets the path via the navigation agent to the player (or
	location) that the enemy wants to move towards.
"""
func set_path(location: Vector2) -> void:
	# Only update target if it changed significantly
	if nav_agent.target_position.distance_to(location) > 5.0:
		nav_agent.target_position = location

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()

	velocity = direction * speed
	nav_agent.velocity = velocity
	move_and_slide()

"""
	This helper method handles when the mushroom enemy needs to stop moving.
	It does this by setting its velocity to zero and calls move_and_slide to 
	update accordingly. It then plays the idle animation.
"""
func _stop_movement_and_animation():
	velocity = Vector2.ZERO
	move_and_slide()
	print("stop move")
	_set_state(EnemyState.IDLE)

"""
	Overwrites entity's take damage method to set the target to critical.
	
	- Bleed + Stun additons;
	Takes a 'triggers_hurt' boolean to prevent bleed (and other DoT) ticks 
	from triggering the hurt animation.
"""
func take_damage(dmg_taken: int, trigger_hurt: bool = true) -> void:
	damage_taken = (dmg_taken * get_resistance())
	health -= (dmg_taken * get_resistance())
	# check for bleed damage to prevent ticks
	# (true = not DoT...false = DoT)
	if (trigger_hurt):
		set_damaged(true)
	else:
		print("DoT effect: ", trigger_hurt)
	if get_health() < critical_health:
		set_critical(true)

'''
Resurrect Enemy

Resets all flags and values of the enemy so they can resurrected back to
an "initial state" by the boss.
'''
func resurrect():
	# Reset health
	health = max_hp
	set_critical(false)
	set_damaged(false)
	
	# Reset state flags
	has_retreated = false
	retreat_initialized = false
	ready_to_attack = false
	bleed_stacks = 0
	is_stunned_flag = false
	
	# Reset timers
	stun_timer = 0.0
	bleed_timer = 0.0
	bleed_duration = 0.0
	idle_timer = 0.0
	
	# Reset velocity
	velocity = Vector2.ZERO
	
	# Reset Collision
	set_collision_layer_value(1, true)
	set_collision_layer_value(8, false)
	
	# Transition back to idle
	_set_state(EnemyState.IDLE)

'''
Is Dead
Returns whether or not the enemy is in the dead state.
'''
func is_dead() -> bool:
	return current_state == EnemyState.DEAD

'''
Transition To

Parameters:
	new_state: String -> name of the state the enemy is being
	sent to
	
Transitions the enemy to a new state by updating the value of
current_state. Also stores the values of the previous and new state to
signal to the state machine GUI.
'''
func transition_to(new_state: String) -> void:
	var prev = EnemyState.keys()[current_state]
	match new_state:
		"IDLE": current_state = EnemyState.IDLE
		"WANDER": current_state = EnemyState.WANDER
		"CHASE": current_state = EnemyState.CHASE
		"ATTACK": current_state = EnemyState.ATTACK
		"HURT": current_state = EnemyState.HURT
		"DEAD": current_state = EnemyState.DEAD
	emit_signal("state_changed", prev, new_state)

'''
Flip Enemy
@author: Same Plemmons

Parameters:
	Right: bool -> this a field that is updated to true when the
	enemy is facing to the right and false when they are facing to
	the left
	
This flips most of the nodes within the enemy scene. Some nodes are
excluded from this since they are related to visual indicators or navigation.
Flipping those nodes will cause the enemy to break. For most cases, all
sprite, telegraph, and field of views nodes should be flipped.
'''
func flip_enemy(right: bool) -> void:
	if right != facing_right and !is_dead():
		facing_right = right
		var flip: int = -1
		if right: 
			flip = 1
		for child in get_children():
			if !(child is NavigationAgent2D or child is Timer or child is ProgressBar or child is Sprite2D or child.name == "StatusIcons"):
				child.scale.x = flip
