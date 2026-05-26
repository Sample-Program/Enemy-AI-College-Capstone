"""
	This script handles the pyromancer's attack mechanics, specifically fireball
	spawning and timing. It listens to the player's animation frames and
	spawns fireballs at the appropriate moments during attack animations.
	Supports an AOE fireball attack for the heavy and skill abilities.
"""
extends Node

var player_class

var fireball_scene = preload("res://Components/Projectiles/PyromancerProjectile/PyromancerProjectile.tscn")
var aoe_fireball_scene = preload("res://Components/Projectiles/PyromancerProjectile/AOEProjectile/PyromancerAOEProjectile.tscn")

var pending_attack_type = ""
var fireballs_spawned = 0
var total_fireballs_to_spawn = 1

var left_rays
var right_rays

@export var light_attack_frame: int = 3
@export var heavy_attack_frame: int = 5
@export var skill_attack_frames: Array[int] = [6, 7]

"""
	Sets up the attack component with a reference to the player and caches
	the directional raycasts used for fireball targeting.
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
	animation signals to time fireball spawning correctly.
"""
func attack(attack_type):
	pending_attack_type = attack_type
	fireballs_spawned = 0
	
	match attack_type:
		"skill":
			total_fireballs_to_spawn = skill_attack_frames.size()
		_:
			total_fireballs_to_spawn = 1
	
	if not player_class.anim_sprite.frame_changed.is_connected(_on_player_animation_frame_changed):
		player_class.anim_sprite.frame_changed.connect(_on_player_animation_frame_changed)
	if not player_class.anim_sprite.animation_finished.is_connected(_on_player_animation_finished):
		player_class.anim_sprite.animation_finished.connect(_on_player_animation_finished)

"""
	Called every time the player's animation frame changes. Checks if the
	current frame matches the spawn frame for the pending attack type.
"""
func _on_player_animation_frame_changed():
	var current_anim = player_class.anim_sprite.animation
	var current_frame = player_class.anim_sprite.frame
	
	match pending_attack_type:
		"light":
			if current_anim.begins_with("Light") and current_frame == light_attack_frame:
				spawn_fireball("light")
				_disconnect_signals()
		"heavy":
			if current_anim.begins_with("Heavy") and current_frame == heavy_attack_frame:
				spawn_fireball("heavy")
				_disconnect_signals()
		"skill":
			if current_anim.begins_with("Skill") and current_frame in skill_attack_frames:
				spawn_fireball("skill")
				fireballs_spawned += 1
				if fireballs_spawned >= total_fireballs_to_spawn:
					_disconnect_signals()

"""
	Backup function that triggers if the animation finishes before all fireballs
	have been spawned. Ensures the intended number of fireballs still fire.
"""
func _on_player_animation_finished():
	if pending_attack_type != "" and fireballs_spawned < total_fireballs_to_spawn:
		var remaining = total_fireballs_to_spawn - fireballs_spawned
		for i in range(remaining):
			spawn_fireball(pending_attack_type)
		_disconnect_signals()

"""
	Disconnects all animation signals and resets the attack state.
	Should be called after all fireballs for an attack have been spawned.
"""
func _disconnect_signals():
	if player_class and player_class.anim_sprite:
		if player_class.anim_sprite.frame_changed.is_connected(_on_player_animation_frame_changed):
			player_class.anim_sprite.frame_changed.disconnect(_on_player_animation_frame_changed)
		if player_class.anim_sprite.animation_finished.is_connected(_on_player_animation_finished):
			player_class.anim_sprite.animation_finished.disconnect(_on_player_animation_finished)
	pending_attack_type = ""
	fireballs_spawned = 0

"""
	Creates and configures a fireball instance, then adds it to the scene.
	Routes heavy and skill attacks to spawn_aoe_fireball instead.
	Handles positioning, direction, and damage based on attack type.
"""
func spawn_fireball(attack_type):
	if attack_type == "heavy" or attack_type == "skill":
		spawn_aoe_fireball(attack_type)
		return
	
	var fireball = fireball_scene.instantiate()
	
	var spread_offset = 0
	if attack_type == "skill" and total_fireballs_to_spawn > 1:
		spread_offset = (fireballs_spawned - (total_fireballs_to_spawn - 1) / 2.0) * 20
	
	var offset = 30
	if player_class.dir == "Right":
		var target_pos = null
		for raycast in right_rays:
			if raycast.is_colliding():
				target_pos = raycast.get_collision_point()
				break
		var spawn_pos = player_class.global_position + Vector2(offset, spread_offset)
		fireball.global_position = spawn_pos
		fireball.direction = (target_pos - spawn_pos).normalized() if target_pos else Vector2.RIGHT
		fireball.facing = "Right"
	else:
		var target_pos = null
		for raycast in left_rays:
			if raycast.is_colliding():
				target_pos = raycast.get_collision_point()
				break
		var spawn_pos = player_class.global_position + Vector2(-offset, spread_offset)
		fireball.global_position = spawn_pos
		fireball.direction = (target_pos - spawn_pos).normalized() if target_pos else Vector2.LEFT
		fireball.facing = "Left"
	
	match attack_type:
		"light":
			fireball.damage = player_class.class_data.light_damage
			player_class.attack_manager._reduce_cooldowns()
		"skill":
			fireball.damage = player_class.class_data.skill_damage
			fireball.is_skill = true
	
	get_tree().current_scene.add_child(fireball)
	fireball.play_start_animation()

"""
	Spawns an AOE fireball that travels to the nearest target and explodes
	in a radius on impact, damaging all enemies within range.
"""
func spawn_aoe_fireball(attack_type):
	var aoe = aoe_fireball_scene.instantiate()
	
	var spread_offset = 0
	if attack_type == "skill" and total_fireballs_to_spawn > 1:
		spread_offset = (fireballs_spawned - (total_fireballs_to_spawn - 1) / 2.0) * 20
	
	var offset = 30
	if player_class.dir == "Right":
		var target_pos = null
		for raycast in right_rays:
			if raycast.is_colliding():
				target_pos = raycast.get_collision_point()
				break
		var spawn_pos = player_class.global_position + Vector2(offset, spread_offset)
		aoe.global_position = spawn_pos
		aoe.direction = (target_pos - spawn_pos).normalized() if target_pos else Vector2.RIGHT
		aoe.facing = "Right"
	else:
		var target_pos = null
		for raycast in left_rays:
			if raycast.is_colliding():
				target_pos = raycast.get_collision_point()
				break
		var spawn_pos = player_class.global_position + Vector2(-offset, spread_offset)
		aoe.global_position = spawn_pos
		aoe.direction = (target_pos - spawn_pos).normalized() if target_pos else Vector2.LEFT
		aoe.facing = "Left"
		aoe.lifetime = 5
	
	match attack_type:
		"heavy":
			aoe.damage = player_class.class_data.heavy_damage
			aoe.telegraph_name = "heavy_telegraph"
			aoe.damage = 15
			aoe.burn = 2
			aoe.is_heavy = true
		"skill":
			aoe.damage = player_class.class_data.skill_damage
			aoe.telegraph_name = "skill_telegraph"
			aoe.damage = 20
			aoe.burn = 3
			aoe.is_skill = true
	
	get_tree().current_scene.add_child(aoe)
	aoe.play_start_animation()

"""
	Returns the incoming damage unmodified. The Pyromancer has no
	damage reduction or blocking mechanic.
"""
func modify_incoming_damage(amount: int) -> int:
	return amount

"""
	Blink — the Pyromancer's special ability. Teleports forward a short
	distance in the movement direction, leaving a fire trail behind.
"""
func special():
	var blink_distance = 300.0
	var blink_dir = Vector2.RIGHT if player_class.dir == "Right" else Vector2.LEFT
	
	if player_class.velocity != Vector2.ZERO:
		blink_dir = player_class.velocity.normalized()
	
	player_class.anim_sprite.self_modulate = Color(3, 1.5, 0.5)
	player_class.global_position += blink_dir * blink_distance
	
	var tween = create_tween()
	tween.tween_property(player_class.anim_sprite, "self_modulate", Color.WHITE, 0.3)
	
	await player_class.anim_sprite.animation_finished
	player_class.is_using_special = false
