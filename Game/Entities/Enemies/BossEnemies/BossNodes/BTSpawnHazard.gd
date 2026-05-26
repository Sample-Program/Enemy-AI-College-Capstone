"""
Spawn Hazard Node: Action node that spawns a fire AoE hazard at a telegraph's position.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTASpawnHazard

# Fire AoE scene spawned by this node.
var fire_aoe = preload("res://Components/Telegraphs/FireAOE/Fire.tscn")

var telegraph_name: String = ""
var damage: int
var burn: int
var tick_rate: float
var lifetime: float

"""
Initializes the hazard spawn action.

@param telegraph: Name of the telegraph node used for the hazard position and shape.
@param dmg: Damage dealt by each hazard tick.
@param brn: Burn stacks applied by each hazard tick.
@param rate: Time between each hazard tick.
@param time: How long the hazard remains active.
"""
func _init(telegraph: String, dmg: int, brn: int, rate: float, time: float):
	display_name = "BTASpawnHazard"
	telegraph_name = telegraph
	damage = dmg
	burn = brn
	tick_rate = rate
	lifetime = time

"""
Spawns a boss-owned fire AoE hazard using the selected telegraph.

The hazard copies the telegraph's position, rotation, and collision shape, then
uses this node's damage, burn, tick rate, and lifetime values.
"""
func execute(_delta: float, context: Dictionary) -> int:
	var agent = context.get("self")
	var target = context.get("target")
	if agent == null or target == null or fire_aoe == null:
		return BTNode.Status.FAILURE
	# Display telegraph
	var telegraph = agent.get_node_or_null(telegraph_name)
	var hazard = fire_aoe.instantiate()
	hazard.is_boss = true
	hazard.global_position = telegraph.get_node("telegraph").global_position
	hazard.scale = agent.scale
	hazard.rotation = telegraph.rotation
	hazard.get_node("telegraph").shape = telegraph.get_node("telegraph").shape
	hazard.damage_per_tick = damage
	hazard.burn_application = burn
	hazard.tick_rate = tick_rate
	hazard.lifetime = lifetime
	agent.get_parent().add_child(hazard)
	return BTNode.Status.SUCCESS
