"""
Fire AoE Node: Ground hazard used to create damage-over-time fire fields.
@author: Sam Plemmons
"""
extends Area2D

@export var damage_per_tick: int = 10
@export var burn_application: int = 1
@export var tick_rate: float = 1.0
@export var lifetime: float = 5.0
@export var is_boss: bool = false
@export var is_player: bool = false
@export var color: Color = Color(1,0,0,0.3)

"""
Starts the fire AoE's damage loop and removes the hazard after its lifetime ends.
"""
func _ready():
	# start damage over time
	start_damage_loop()
	# remove hazard area after lifetime reaches 0
	await get_tree().create_timer(lifetime).timeout
	queue_free()

"""
Applies burn effects to valid targets at regular intervals.

If the AoE was spawned by the boss, it burns the player and heals non-Colossus
enemies standing inside the area. If the AoE was spawned by the player, it
burns enemies standing inside the area.
"""
func start_damage_loop():
	while true:
		self.modulate = color
		# stops loop that ticks down based on tick rate
		await get_tree().create_timer(tick_rate).timeout
		for body in get_overlapping_bodies():
			if is_boss:
				if (body is Player):
					body.apply_burn(burn_application)
				elif (body is Enemy) and !(body is Collosus):
					body.set_health(body.get_health() + damage_per_tick)
			if is_player:
				if (body is Enemy):
					body.apply_burn(burn_application)
			'''
			if body is Player or body is Enemy:
				body.apply_burn(burn_application)
			'''
