"""
Boss Enemy: Base class for boss enemies.
@authors: Sam Plemmons
"""
extends Enemy
class_name BossEnemy

## Behavior tree used to control boss AI.
var tree: BehaviorTree = BehaviorTree.new()
var root: BTSelector = BTSelector.new()

## Enemy state values.
var current_hp: int
var dead: bool =  false
var sleep: bool = true
var attacking: bool = false
var move_direction: Vector2 = Vector2.ZERO
var facing_right: bool = true

## Active status effects currently displayed on the boss.
var status_effects: Array = [] # holds the effects

## Stun values.
var stun_bar: float = 100 # amount to fill to stun enemy
var stun_fill: float = 50 # amount of stun per attack
var cur_stun_val: float = 0 # current amount of stun on the enemy
var stun_time: float = 2 # how long to stun the enemy for
var cur_stun_time: float = 0 # how long the enemies been currently stunned for
var is_stunned_flag = false

## Bleed values.
var bleed_stacks: int = 0
var bleed_timer: float = 0.0
var bleed_duration: float = 10 # last for 10 secs
var cur_bleed_duration: float = 0 #how long current bleed is
var bleed_tick_rate: float = 1.0
var bleed_damage: int = 2

## Burn values.
var burn_stacks: int = 0
var burn_timer: float = 0.0
var burn_duration: float = 10 # last for 10 secs
var cur_burn_duration: float = 0 #how long current bleed is
var burn_tick_rate: float = 0.5
var burn_damage: int = 3

"""
Adds a status effect icon to the boss if it is not already active.

The node is checked before being used to prevent null reference errors. Once
added, the icon is made visible and the status icons are repositioned.

@param id: Name or ID of the status effect.
@param node: Sprite node used to visually display the status effect.
"""
func add_status(id: String, node: Sprite2D):
	if node == null or not is_instance_valid(node):
		return
	for e in status_effects:
		if e["id"] == id:
			return
	status_effects.append({
		"id": id,
		"node": node
	})
	node.visible = true
	_reposition_status_icons()
	
"""
Removes a status effect icon from the boss.

If the status effect is found, its visual icon is hidden, removed from the
active status effect list, and the remaining icons are repositioned.

@param id: Name or ID of the status effect to remove.
"""
func remove_status(id: String):
	for i in range(status_effects.size()):
		if status_effects[i]["id"] == id:
			var node = status_effects[i]["node"]
			node.visible = false
			status_effects.remove_at(i)
			break
	_reposition_status_icons()

"""
Repositions the boss's status effect icons.

This is implemented separately by each boss because icon positioning depends
on the boss's sprite size and scene layout.
"""
func _reposition_status_icons():
	return

"""
Applies damage to the boss and marks the boss as damaged.

@param dmg_taken: Amount of damage to subtract from the boss's current health.
@param trigger_hurt: Whether the boss should play a hurt reaction.
"""
func take_damage(dmg_taken: int, trigger_hurt: bool = false) -> void:
	#print("----------\nDamage Info\n----------")
	#print("Initial Damage: ", dmg_taken)
	#print("Health Before Attack: ", current_hp)
	current_hp -= dmg_taken
	#print("Health After Attack: ", current_hp)
	set_damaged(true)
	
"""
Returns the boss's current health.
"""
func get_health() -> int:
	return current_hp
	
"""
Sets the boss's current health.
"""
func set_health(hp: int) -> void:
	current_hp = hp
	
"""
Returns whether the boss is dead.
"""
func is_dead() -> bool:
	return dead
	
"""
Sets whether the boss is dead.
"""
func set_dead(unalive: bool) -> void:
	dead = unalive
	
"""
Returns whether the boss is asleep.
"""
func is_asleep() -> bool:
	return sleep
	
"""
Sets whether the boss is asleep.
"""
func set_sleep(sleepy: bool) -> void:
	sleep = sleepy
	
"""
Returns whether the boss is currently attacking.
"""
func is_attacking() -> bool:
	return attacking
	
"""
Sets whether the boss is currently attacking.
"""
func set_attacking(attack: bool) -> void:
	attacking = attack
	
"""
Flips the boss to face left or right.

Only visual and attack-related child nodes are flipped. Navigation, behavior
tree, health bar, and status icon nodes are excluded because flipping them can
break movement, AI logic, or UI positioning.

@param right: True if the boss should face right, false if it should face left.
"""
func flip_enemy(right: bool) -> void:
	if right != facing_right and !attacking and !dead:
		facing_right = right
		var flip: int = -1
		if right: 
			flip = 1
		for child in get_children():
			if !(child is NavigationAgent2D or child is BehaviorTree or child is ProgressBar or child.name == "StatusIcons"):
				child.scale.x = flip
