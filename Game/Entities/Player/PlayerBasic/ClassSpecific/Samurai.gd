extends Node

var hit_particles

var player_class
var is_blocking: bool = false

var enemies_in_range_light: Array = []
var enemies_in_range_heavy: Array = []
var enemies_in_range_skill: Array = []
var enemies_in_range = [
	enemies_in_range_light, 
	enemies_in_range_heavy, 
	enemies_in_range_skill
]

"""
	Sets up the attack component with a reference to the player. Configures
	the hit particle system and connects the hitbox node to this component.
"""
func setup(p, class_root):
	player_class = p
	hit_particles = class_root.get_node("HitParticles")
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.color = Color(1, 0.8, 0.2)
	hit_particles.process_material = material
	hit_particles.amount = 16
	hit_particles.lifetime = 0.4
	hit_particles.one_shot = true
	hit_particles.emitting = false
	
	# Wait for the class scene to be ready before finding hitboxes
	await player_class.get_tree().process_frame
	
	var class_scene = null
	for child in player_class.get_children():
		if child.has_node("Hitboxes"):
			class_scene = child
			break
	
	if not class_scene:
		push_error("Samurai: could not find Hitboxes node")
		return
	
	var hitbox_node = class_scene.get_node_or_null("Hitboxes")
	if hitbox_node:
		if hitbox_node.has_method("setup"):
			hitbox_node.setup(self)

"""
	Performs a melee attack of the specified type. Deals damage to all enemies
	currently in the corresponding hitbox range, applies bleed on heavy and skill
	attacks, and plays hit particles and camera effects accordingly.
"""
func attack(attack_type: String):
	var dmg = 0
	var ind = 0
	var bleed = false
	
	match attack_type:
		"light":
			dmg = player_class.class_data.light_damage
			player_class.attack_manager._reduce_cooldowns()
			ind = 0
			_flash_character(Color(1.5, 1.5, 1.5))
		"heavy":
			dmg = player_class.class_data.heavy_damage
			ind = 1
			bleed = true
			_flash_character(Color(2, 0.3, 0.3))
			_shake_camera()
		"skill":
			dmg = player_class.class_data.skill_damage
			ind = 2
			bleed = true
			_flash_character(Color(2, 1.5, 0.2))
			_shake_camera()
	
	# Damage all enemies in range
	if not enemies_in_range[ind].is_empty():
		for enemy in enemies_in_range[ind]:
			if enemy and enemy.has_method("take_damage") and enemy is Enemy:
				enemy.take_damage(dmg)
				if bleed and enemy.has_method("apply_bleed"):
					enemy.apply_bleed(1) # 1 tick dmg
				if enemy.has_method("set_target"):
					enemy.set_target(player_class)
				hit_particles.global_position = enemy.global_position
				hit_particles.emitting = true
	bleed = false

"""
	Flips all hitbox collision shapes to match the player's current facing
	direction so melee attacks always connect on the correct side.
"""
func update_hitbox_direction(direction: String):
	var class_scene = null
	for child in player_class.get_children():
		if child.has_node("Hitboxes"):
			class_scene = child
			break
	
	if not class_scene:
		return
	
	# Get all hitboxes
	var light = class_scene.get_node_or_null("Hitboxes/LightHitbox/AttackArea Light")
	var heavy = class_scene.get_node_or_null("Hitboxes/HeavyHitbox/AttackArea Heavy")
	var skill = class_scene.get_node_or_null("Hitboxes/SkillHitbox/AttackArea Skill")
	
	if direction == "Left":
		if light:
			light.scale.x = -1
		if heavy:
			heavy.scale.x = -1
		if skill:
			skill.scale.x = -1
	else:  # Right
		if light:
			light.scale.x = 1
		if heavy:
			heavy.scale.x = 1
		if skill:
			skill.scale.x = 1

"""
	Returns the incoming damage, halved if the Samurai is currently blocking.
	The result is floored to the nearest integer.
"""
func modify_incoming_damage(amount: int) -> int:
	if is_blocking:
		@warning_ignore("integer_division")
		return floori(amount / 2)
	return amount

"""
	This is a block ability function for the Samurai player class.
	Block is a class specific/special ability for the Samurai.
"""
func special():
	is_blocking = true
	player_class.movement_component.current_speed = 0.0
	
	if player_class.attacker != null:
		if player_class.attacker.has_method("apply_stun"):
			player_class.attacker.apply_stun(1.5)
	
	await player_class.anim_sprite.animation_finished
	player_class.is_using_special = false
	is_blocking = false

"""
	Briefly tints the player's sprite to the given color, then tweens it
	back to white. Used to give visual feedback on different attack types.
"""
func _flash_character(color: Color):
	player_class.anim_sprite.self_modulate = color
	var tween = player_class.create_tween()
	tween.tween_property(player_class.anim_sprite, "self_modulate", Color.WHITE, 0.15)

"""
	Shakes the active Camera2D by randomly offsetting it over a short duration,
	then snaps it back to its original position. Used on heavy and skill attacks.
"""
func _shake_camera():
	var camera = player_class.get_viewport().get_camera_2d()
	if not camera:
		return
	var original_offset = camera.offset
	var tween = player_class.create_tween()
	tween.tween_method(func(t):
		camera.offset = original_offset + Vector2(
			randf_range(-6, 6),
			randf_range(-6, 6)
		), 0.0, 1.0, 0.2)
	tween.tween_property(camera, "offset", original_offset, 0.05)
