extends Projectile

var is_heavy = false
var is_skill = false
var stun_duration = 1.5

func _ready():
	super._ready()
	
	# Hit particles (burst on impact)
	var hit_material = ParticleProcessMaterial.new()
	hit_material.direction = Vector3(0, -1, 0)
	hit_material.spread = 60.0
	hit_material.initial_velocity_min = 50.0
	hit_material.initial_velocity_max = 120.0
	hit_material.gravity = Vector3(0, 200, 0)
	hit_material.scale_min = 1.0
	hit_material.scale_max = 3.0
	hit_material.color = Color(0.8, 0.8, 1.0)
	
	var hit_particles = GPUParticles2D.new()
	hit_particles.process_material = hit_material
	hit_particles.amount = 12
	hit_particles.lifetime = 0.3
	hit_particles.one_shot = true
	hit_particles.emitting = false
	hit_particles.name = "HitParticles"
	add_child(hit_particles)
	
	# Trail particles (continuous while flying)
	var trail_material = ParticleProcessMaterial.new()
	trail_material.direction = Vector3(0, 0, 0)
	trail_material.spread = 20.0
	trail_material.initial_velocity_min = 10.0
	trail_material.initial_velocity_max = 30.0
	trail_material.gravity = Vector3(0, 0, 0)
	trail_material.scale_min = 0.5
	trail_material.scale_max = 1.5
	trail_material.color = Color(0.9, 0.9, 1.0, 0.6)
	
	var trail_particles = GPUParticles2D.new()
	trail_particles.process_material = trail_material
	trail_particles.amount = 8
	trail_particles.lifetime = 0.15
	trail_particles.one_shot = false
	trail_particles.emitting = true
	trail_particles.name = "TrailParticles"
	add_child(trail_particles)
	
	# Muzzle flash particles (burst on spawn)
	var muzzle_material = ParticleProcessMaterial.new()
	muzzle_material.direction = Vector3(0, -1, 0)
	muzzle_material.spread = 90.0
	muzzle_material.initial_velocity_min = 30.0
	muzzle_material.initial_velocity_max = 80.0
	muzzle_material.gravity = Vector3(0, 100, 0)
	muzzle_material.scale_min = 1.0
	muzzle_material.scale_max = 2.5
	muzzle_material.color = Color(1.0, 1.0, 0.6, 0.8)
	
	var muzzle_particles = GPUParticles2D.new()
	muzzle_particles.process_material = muzzle_material
	muzzle_particles.amount = 10
	muzzle_particles.lifetime = 0.2
	muzzle_particles.one_shot = true
	muzzle_particles.emitting = true  # fires immediately on spawn
	muzzle_particles.name = "MuzzleParticles"
	add_child(muzzle_particles)
	
	$projectile_animation.play("Fly_Right")

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage") and !(body is Player):
		_on_hit(body)
		queue_free()
	elif body is Player:
		return
	else:
		# Hit a wall or non-damageable body
		_on_hit_wall()

"""
	Handles hit effects and damage when the arrow strikes a valid target.
"""
func _on_hit(body: Node):
	if is_heavy or is_skill:
		_shake_camera()
	
	# Blue/white burst for hitting an enemy
	_burst_particles("HitParticles", global_position)
	
	if (is_heavy or is_skill) and body.has_method("apply_stun"):
		body.apply_stun(stun_duration)
		body.take_damage(damage, false)
	else:
		body.take_damage(damage)

"""
	Handles effects when the arrow hits a wall or non-damageable surface.
"""
func _on_hit_wall():
	direction = Vector2.ZERO
	lifetime = 999.0
	if facing == "Left":
		$projectile_animation.play("Hit_Right")
	else:
		$projectile_animation.flip_h = false
		$projectile_animation.play("Hit_Right")
	await $projectile_animation.animation_finished
	queue_free()

"""
	Detaches particles from the arrow and emits them so they
	survive after the arrow is freed.
"""
func _burst_particles(particle_name: String, pos: Vector2):
	var particles = get_node_or_null(particle_name)
	if not particles:
		return
	particles.reparent(get_tree().current_scene)
	particles.global_position = pos
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()

func _shake_camera():
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	var original_offset = camera.offset
	var tween = create_tween()
	tween.tween_method(func(t):
		camera.offset = original_offset + Vector2(
			randf_range(-6, 6),
			randf_range(-6, 6)
		), 0.0, 1.0, 0.2)
	tween.tween_property(camera, "offset", original_offset, 0.05)
