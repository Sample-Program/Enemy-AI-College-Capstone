"""
	This script handles anything related to the training dummy enemy. This 
	enemy is used as a punching bag for the player to test their skills and
	attacks. It has a large health pool and cannot move.
	
	Due to no longer needing the training dummy, it has not been updated since
	Semester 1.
	
	@Author: Sam Plemmons
"""

extends Enemy

## Enums for Training Dummy
# IDLE: when no entity is attacking the dummy
# HURT: the player (or another entity) hits the dummy
# DEAD: when the dummy's hp hits 0

## Variables for Health
var max_hp: int = 50
var critical_health: int = 49
var resist: float = 1.0

var current_health: int = max_hp

## On startup
"""
	This function runs on startup and makes sure the enemy is in IDLE state,
	as well as sets its values such as health, resistance. 
	@author: Sam Plemmons
"""
func _ready() -> void:
	add_to_group("enemies")
	# Sets the current state
	_set_state(EnemyState.IDLE)
	$sprite_animations.animation_finished.connect(_on_animation_finished)
	# Set HP value
	set_resistance(resist)
	set_health(max_hp)
	set_damaged(false)
	set_critical(false)

"""
	This is ran every frame to get the enemy's health and make sure it
	correct represents the state it should be in.
	@param: Time in seconds since the previous frame
	@author: Sam Plemmons
"""
func _physics_process(_delta: float) -> void:
	current_health = get_health()
	match(current_state):
		EnemyState.IDLE: _idle_state()
		EnemyState.DEAD: _dead_state()

## Logic for the IDLE state
"""
	This function handles the logic for the IDLE state. It handles any
	transitions keeps track of the training dummy's health. It plays animations
	accordingly if hit by the player as well. 
	@author: Sam Plemmons
"""
func _idle_state() -> void:
	# Transition check for HURT state
	if is_damaged():
		if get_health() < critical_health:
			set_critical(true)
		$sprite_animations.sprite_frames.set_animation_loop("hurt", false)
		# Start the hurt animation
		$sprite_animations.play("hurt")
	elif get_health() <= 0:
		_set_state(EnemyState.DEAD)
	else:
		# set animation to IDLE
		$sprite_animations.play("idle")

## Logic for the DEAD state
"""
	This state keeps track of the training dummy if it has entered the DEAD state.
	At this point it should no longer take damage, but eventually regains its HP and 
	re-enters the idle state. 
	@author: Sam Plemmons
"""
func _dead_state() -> void:
	## TESTING
	print("Enter DEAD State\nHP:", get_health())
	# Reset health of enemy
	set_health(max_hp)
	# Set state back to IDLE
	_set_state(EnemyState.IDLE)

"""
	This function makes it so animations are not skipped. 
	@author: Sam Plemmons
"""
func _on_animation_finished():
	if $sprite_animations.animation == "hurt":
		set_damaged(false)
		# Check for state transitions after animation completes
			 
	elif $sprite_animations.animation == "dead":
		# Handle dead animation finished
		#set_health(MAX_HP)
		#_set_state(EnemyState.IDLE)
		pass

"""
	This function returns what the critical health amount of the training
	dummy is. 
	@author: Sam Plemmons
"""
func get_critical_health() -> int:
	return critical_health
