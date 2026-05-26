class_name Hitbox
extends Node2D

var damage: int = 0
var attack_component

"""
	Initializes the hitbox with a reference to its owning attack component.
	Called once after the hitbox is added to the scene.
"""
func setup(comp) -> void:
	attack_component = comp

# Light attack hitbox detection
func _on_light_body_entered(body: Node2D):
	if body.has_method("take_damage"):
		if not attack_component:
			return
		if body not in attack_component.enemies_in_range_light:
			attack_component.enemies_in_range_light.append(body)

"""
	Called when a body leaves the light attack hitbox. Removes the body
	from the light attack enemy tracking list.
"""	
func _on_light_body_exited(body: Node2D):
	if body.has_method("take_damage"):
		if not attack_component:
			return
		attack_component.enemies_in_range_light.erase(body)

# Heavy attack hitbox detection
func _on_heavy_body_entered(body: Node2D):
	if body.has_method("take_damage"):
		if not attack_component:
			return
		if body not in attack_component.enemies_in_range_heavy:
			attack_component.enemies_in_range_heavy.append(body)

"""
	Called when a body leaves the heavy attack hitbox. Removes the body
	from the heavy attack enemy tracking list.
"""
func _on_heavy_body_exited(body: Node2D):
	if body.has_method("take_damage"):
		if not attack_component:
			return
		attack_component.enemies_in_range_heavy.erase(body)

# Skill attack hitbox detection
func _on_skill_body_entered(body: Node2D):
	if body.has_method("take_damage"):
		if not attack_component:
			return
		if body not in attack_component.enemies_in_range_skill:
			attack_component.enemies_in_range_skill.append(body)

"""
	Called when a body leaves the skill attack hitbox. Removes the body
	from the skill attack enemy tracking list.
"""
func _on_skill_body_exited(body: Node2D):
	if body.has_method("take_damage"):
		if not attack_component:
			return
		attack_component.enemies_in_range_skill.erase(body)
