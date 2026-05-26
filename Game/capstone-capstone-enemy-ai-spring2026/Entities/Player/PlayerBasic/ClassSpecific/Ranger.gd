"""
	This script handles the ranger's attack mechanics, specifically arrow 
	spawning and timing. It listens to the player's animation frames and 
	spawns arrows at the appropriate moments during attack animations.
	Supports multi-arrow attacks for skill abilities with configurable 
	spread patterns.
"""
extends Node

## Reference to the player character that owns this attack component
var player_class

## Preloaded arrow scene that will be instantiated for each attack
var arrow_scene = preload("res://Components/Projectiles/RangerProjectile/RangerProjectile.tscn")

## The type of attack currently pending ("light", "heavy", or "skill")
var pending_attack_type = ""

## Counter for how many arrows have been spawned during a multi-arrow attack
var arrows_spawned = 0

## Total number of arrows to spawn for the current attack
var total_arrows_to_spawn = 1

var dash_speed: float = 1000.0

var left_rays
var right_rays

## The frames the arrows are spawned in
@export var light_attack_frame: int = 6
@export var heavy_attack_frame: int = 6
@export var skill_attack_frames: Array[int] = [12, 15, 18]

"""
	Sets up the attack component with a reference to the player.
	Called when the component is added to the player.
	@param p: The player node that owns this component
"""
func setup(p, class_root):
	player_class = p
	left_rays = [
		class_root.get_node("TopLeft"),
		class_root.get_node("TopMidLeft"),
		class_root.get_node("MiddleLeft"),
		class_root.get_node("BotMidLeft"),
		class_root.get_node("BotLeft"),
	]
	right_rays = [
		class_root.get_node("TopRight"),
		class_root.get_node("TopMidRight"),
		class_root.get_node("MiddleRight"),
		class_root.get_node("BotMidRight"),
		class_root.get_node("BotRight"),
	]

"""
	Initiates an attack of the specified type. Connects to the player's
	animation signals to time arrow spawning correctly.
	@param attack_type: The type of attack being performed ("light", "heavy", or "skill")
"""
func attack(attack_type):
	# Store which attack we're waiting to spawn
	pending_attack_type = attack_type
	arrows_spawned = 0
	
	# Set total arrows based on attack type
	match attack_type:
		"skill":
			total_arrows_to_spawn = skill_attack_frames.size()
		_:
			total_arrows_to_spawn = 1
	
	# Connect to the player's animation frame_changed signal
	if not player_class.anim_sprite.frame_changed.is_connected(_on_player_animation_frame_changed):
		player_class.anim_sprite.frame_changed.connect(_on_player_animation_frame_changed)
	
	# Also connect to animation finished
	if not player_class.anim_sprite.animation_finished.is_connected(_on_player_animation_finished):
		player_class.anim_sprite.animation_finished.connect(_on_player_animation_finished)

"""
	Called every time the player's animation frame changes. Checks if the
	current frame matches the spawn frame for the pending attack type.
"""
func _on_player_animation_frame_changed():
	var current_anim = player_class.anim_sprite.animation
	var current_frame = player_class.anim_sprite.frame
	
	# Check if we're in the right animation and at the right frame
	match pending_attack_type:
		"light":
			if current_anim.begins_with("Light") and current_frame == light_attack_frame:
				spawn_arrow("light")
				_disconnect_signals()
		
		"heavy":
			if current_anim.begins_with("Heavy") and current_frame == heavy_attack_frame:
				spawn_arrow("heavy")
				_disconnect_signals()
		
		"skill":
			if current_anim.begins_with("Skill") and current_frame in skill_attack_frames:
				spawn_arrow("skill")
				arrows_spawned += 1
				
				# Only disconnect after all arrows have been spawned
				if arrows_spawned >= total_arrows_to_spawn:
					_disconnect_signals()

"""
	Backup function that triggers if the animation finishes before all arrows
	have been spawned. Ensures that the intended number of arrows still fire.
"""
func _on_player_animation_finished():
	if pending_attack_type != "" and arrows_spawned < total_arrows_to_spawn:
		var remaining = total_arrows_to_spawn - arrows_spawned
		
		for i in range(remaining):
			spawn_arrow(pending_attack_type)
		
		_disconnect_signals()

"""
	Disconnects all animation signals and resets the attack state.
	Should be called after all arrows for an attack have been spawned.
"""
func _disconnect_signals():
	if player_class and player_class.anim_sprite:
		if player_class.anim_sprite.frame_changed.is_connected(_on_player_animation_frame_changed):
			player_class.anim_sprite.frame_changed.disconnect(_on_player_animation_frame_changed)
		if player_class.anim_sprite.animation_finished.is_connected(_on_player_animation_finished):
			player_class.anim_sprite.animation_finished.disconnect(_on_player_animation_finished)
	pending_attack_type = ""
	arrows_spawned = 0

"""
	Creates and configures an arrow instance, then adds it to the scene.
	Handles positioning, direction, damage, and visual spread for multi-arrow attacks.
	@param attack_type: The type of attack that determines damage values
"""
func spawn_arrow(attack_type):
	var arrow = arrow_scene.instantiate()
	
	# Add some spread for multiple arrows
	var spread_offset = 0
	if attack_type == "skill" and total_arrows_to_spawn > 1:
		# Spread arrows vertically based on which one we're spawning
		spread_offset = (arrows_spawned - (total_arrows_to_spawn - 1) / 2.0) * 15
	
	var offset = 30
	if player_class.dir == "Right":
		var target_pos = null
		for raycast in right_rays:
			if raycast.is_colliding():
				target_pos = raycast.get_collision_point()
		
		var spawn_pos = player_class.global_position + Vector2(offset, spread_offset)
		arrow.global_position = spawn_pos
		arrow.direction = (target_pos - spawn_pos).normalized() if target_pos else Vector2.RIGHT
		arrow.facing = "Right"
	else:
		var target_pos = null
		for raycast in left_rays:
			if raycast.is_colliding():
				target_pos = raycast.get_collision_point()
				break
		
		var spawn_pos = player_class.global_position + Vector2(-offset, spread_offset)
		arrow.global_position = spawn_pos
		arrow.direction = (target_pos - spawn_pos).normalized() if target_pos else Vector2.LEFT
		arrow.facing = "Left"
	
	match attack_type:
		"light":
			arrow.damage = player_class.class_data.light_damage
			player_class.attack_manager._reduce_cooldowns()
		"heavy":
			arrow.damage = player_class.class_data.heavy_damage
			arrow.is_heavy = (attack_type == "heavy")
		"skill":
			arrow.damage = player_class.class_data.skill_damage
			arrow.is_skill = (attack_type == "skill")
	
	get_tree().current_scene.add_child(arrow)

"""
	Returns the incoming damage unmodified. The Ranger has no
	damage reduction or blocking mechanic.
"""
func modify_incoming_damage(amount: int) -> int:
	return amount

"""
	This is a dash ability function for the Ranger player class.
	Dash is a class specific/special ability for the Ranger.
"""
func special():
	var dash_dir
	if player_class.velocity != Vector2.ZERO:
		dash_dir = player_class.velocity.normalized()
	else:
		dash_dir = Vector2.RIGHT if player_class.dir == "Right" else Vector2.LEFT
	
	player_class.anim_sprite.self_modulate = Color(3, 3, 3)
	player_class.velocity = dash_dir.normalized() * dash_speed
	player_class.move_and_slide()
	
	var tween = create_tween()
	tween.tween_property(player_class, "velocity", Vector2.ZERO, 0.2)
	tween.parallel().tween_property(player_class.anim_sprite, "self_modulate", Color.WHITE, 0.2)
	await player_class.anim_sprite.animation_finished
	
	player_class.is_using_special = false
