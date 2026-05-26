"""
Colossus Boss: Script for the first boss encounter.
@authors: Sam Plemmons
"""
extends BossEnemy
class_name Collosus

## Enemy components.
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Animations
@onready var collision: CollisionShape2D = $sprite_collision

## Enemy stats.
const max_hp: int = 500
var speed: float = 75

## Extra stun time added when the Colossus becomes stunned.
var additional_stun = 5

## Status effect icon nodes.
@onready var status_root: Node2D = $StatusIcons
@onready var bleed_icon: Sprite2D = $StatusIcons/bleed_sprite
@onready var stun_icon: Sprite2D = $StatusIcons/stun_sprite
@onready var burn_icon: Sprite2D = $StatusIcons/burn_sprite

"""
Applies stun buildup to the Colossus.

Once the stun buildup reaches the stun bar threshold, the Colossus becomes
stunned for the given duration plus its additional stun time.

@param duration: Base amount of time the Colossus remains stunned.
"""
func apply_stun(duration: float) -> void:
	if is_stunned_flag:
		return
	cur_stun_val = cur_stun_val + stun_fill
	if cur_stun_val >= stun_bar:
		#enemy is stunned now
		stun_time = duration + additional_stun # add another 5 seconds to stun
		is_stunned_flag = true
		add_status("stun", stun_icon)

"""
Applies burn stacks to the Colossus and displays the burn icon.

@param stacks: Number of burn stacks to add.
"""
func apply_burn(stacks: int = 1) -> void:
	burn_stacks += stacks
	# show icon
	add_status("burn", burn_icon)

"""
Applies bleed stacks to the Colossus and displays the bleed icon.

@param stacks: Number of bleed stacks to add.
"""
func apply_bleed(stacks: int = 1) -> void:
	bleed_stacks += stacks
	# show icon in UI system
	add_status("bleed", bleed_icon)

"""
Initializes the Colossus's navigation, status icons, stats, and behavior tree.
"""
func _ready() -> void:
	# NavMesh
	nav_agent.path_desired_distance = 12.0
	nav_agent.target_desired_distance = 12.0
	nav_agent.avoidance_enabled = true
	# bind nodes once (status effects)
	for effect in status_effects:
		match effect["id"]:
			"bleed":
				effect["node"] = bleed_icon
			"stun":
				effect["node"] = stun_icon
			"burn":
				effect["node"] = burn_icon
	# Other Stuff
	stun_fill = 20
	current_hp = max_hp
	add_to_group("enemies")
	# Context for Nodes
	tree.context = {
		"self": self,
		"target": null,
		"tree": tree
	}
	## Behavior Tree
	tree.root = root
	## Stunned
	root.add_child(stunned_sequence())
	## Wake Up Sequence
	root.add_child(wake_up())
	## Dead Sequence
	root.add_child(dead_animation())
	## Resurrect Attack Sequence
	root.add_child(resurrect_attack(1, 20.0, max_hp*0.75))
	## Special Attack Sequence
	root.add_child(super_attack(1, 5, 2, 5, 10))
	## Basic Attack Sequence
	root.add_child(basic_attacks(2, 1, 5, 1, 1, max_hp*0.75))
	## Move to Target
	root.add_child(move_to_target("detect_player", 1.0, 15))
	## Idle Animation
	root.add_child(BTPlayAnimation.new("idle"))

"""
Updates the Colossus each frame.

The behavior tree is ticked, and the Colossus turns to face its current target
when one is available.
"""
func _process(delta: float) -> void:
	tree.tick(delta)
	# always face target
	target = tree.context["target"]
	if target != null:
		flip_enemy(target.global_position.x > global_position.x)
		

"""
Processes all active status effects on the Colossus.

This manages burn and bleed damage over time, stun recovery, stack decay, and
status icon removal when effects end.
"""
func _process_status(delta: float) -> void:
	# DEAD CHECK
	if current_hp <= 0:
		return
	# BURN
	if burn_stacks > 0:
		burn_timer += delta
		cur_burn_duration += delta
		if cur_burn_duration >= burn_duration:
			burn_stacks -= 1
			#decay over time
		if burn_timer >= burn_tick_rate:
			burn_timer = 0.0
			take_damage(burn_stacks * burn_damage)
	if burn_stacks <= 0:
		burn_stacks = 0
		remove_status("burn")
	# STUN
	if is_stunned_flag:
		cur_stun_time += delta
		if cur_stun_time >= stun_time:
			stun_icon.visible = false
			is_stunned_flag = false
			cur_stun_val = 0
			cur_stun_time = 0.0
			remove_status("stun")
			# make sure the enemy can go back to attacking, i removed an idle set here
	# BLEED 
	if bleed_stacks > 0:
		bleed_timer += delta
		cur_bleed_duration += delta
		if cur_bleed_duration >= bleed_duration:
			bleed_stacks -= 1
			#decay over time
		if bleed_timer >= bleed_tick_rate:
			bleed_timer = 0.0
			take_damage(bleed_stacks * bleed_damage)
	if bleed_stacks <= 0:
		bleed_stacks = 0
		remove_status("bleed")
		
"""
Repositions the status effect icons based on the Colossus's sprite size.
"""
func _reposition_status_icons():
	var spacing = 18
	var start_offset = Vector2(15, -81)
	for i in range(status_effects.size()):
		var icon = status_effects[i]["node"]
		if icon == null or not is_instance_valid(icon):
			continue
		icon.position = start_offset + Vector2(i * spacing, 0)

"""
Sets the player as the Colossus's target when they enter the detection area.
"""
func _on_detect_player_body_entered(body: Node2D) -> void:
	if body is Player:
		tree.context["target"] = body
		print("targetting player", tree.context["target"])

"""
Clears the Colossus's target when the player leaves the detection area.
"""
func _on_detect_player_body_exited(body: Node2D) -> void:
	if body is Player:
		tree.context["target"] = null
		print("stop targetting player")

"""
Creates the Colossus's resurrection attack behavior.

The attack only runs below the given health threshold and when dead basic
enemies are inside the resurrection area.
"""
func resurrect_attack(dmg: int, cd: float, hp: int) -> BTCooldown:
	var res_attack_seq: BTSequence = BTSequence.new()
	var res_attack_cooldown: BTCooldown = BTCooldown.new(res_attack_seq, cd)
	res_attack_cooldown.add_child(res_attack_seq)
	# only run if less than half hp
	res_attack_seq.add_child(BTHealthCheck.new(hp))
	# check area for dead basic enemies
	res_attack_seq.add_child(BTCheckForDeadEnemies.new("resurrect_area"))
	# parallel node for resurrect attack and animation
	var res_par: BTParallel = BTParallel.new()
	res_par.add_child_node(BTPlayAnimation.new("resurrect_attack"))
	res_par.add_child_node(BTResurrectAttack.new(
		"resurrect_attack", "resurrect_area", [10], dmg))
	res_attack_seq.add_child(res_par)
	return res_attack_cooldown

"""
Creates the Colossus's super attack behavior.

The attack performs a multi-stage AoE strike, then spawns a fire hazard at the
final telegraph location.
"""
func super_attack(dmg: int, fire_dmg: int, burn_tick: int, fire_time: float, cooldown: int) -> BTCooldown:
	var super_attack_seq: BTSequence = BTSequence.new()
	var super_attack_cooldown: BTCooldown = BTCooldown.new(super_attack_seq, cooldown)
	super_attack_cooldown.add_child(super_attack_seq)
	super_attack_seq.add_child(BTCheckArea.new("super_attack_hitbox"))
	var super_par: BTParallel = BTParallel.new()
	super_par.add_child_node(BTPlayAnimation.new("super_attack"))
	'''
	This will do 12 instances of damage!
	super_par.add_child_node(BTSuperAttack.new("super_attack", [
		{ "telegraph": "super_attack_telegraph1", "frames": [10, 11, 12, 13, 14, 15] },
		{ "telegraph": "super_attack_telegraph2", "frames": [12, 13, 14, 15] },
		{ "telegraph": "super_attack_telegraph3", "frames": [14, 15] }], dmg))
	'''
	super_par.add_child_node(BTSuperAttack.new("super_attack", [
		{ "telegraph": "super_attack_telegraph1", "frames": [10, 11] },
		{ "telegraph": "super_attack_telegraph2", "frames": [12, 13] },
		{ "telegraph": "super_attack_telegraph3", "frames": [14, 15] }], dmg))
	super_attack_seq.add_child(super_par)
	super_attack_seq.add_child(BTASpawnHazard.new("super_attack_telegraph3", fire_dmg, burn_tick, 0.5, fire_time))
	return super_attack_cooldown

"""
Creates the Colossus's basic attack behavior.

The Colossus randomly chooses between melee and ranged attacks. Once below the
given health threshold, each basic attack can also spawn a fire hazard.
"""
func basic_attacks(m_dmg: int, r_dmg: int, fire_dmg: int, burn_tick: int, fire_time: float, hp: int) -> BTSequence:
	var attack_seq: BTSequence = BTSequence.new()
	# Random Between Range and Melee
	var attack_sel: BTRandomSelector = BTRandomSelector.new()
	# Melee Attacks
	var melee_seq: BTSequence = BTSequence.new()
	melee_seq.add_child(BTCheckArea.new("melee_attack_hitbox"))
	var melee_par: BTParallel = BTParallel.new()
	melee_par.add_child_node(BTPlayAnimation.new("melee_attack"))
	melee_par.add_child_node(BTAttack.new(
		"melee_attack", "melee_attack_telegraph", [10, 12, 14], m_dmg))
	melee_seq.add_child(melee_par)
	# spawn fire hazard once below 50
	var melee_fire_aoe: BTSequence = BTSequence.new()
	melee_fire_aoe.add_child(BTHealthCheck.new(hp))
	melee_fire_aoe.add_child(BTASpawnHazard.new("melee_attack_telegraph", fire_dmg, burn_tick, 0.5, fire_time))
	melee_seq.add_child(melee_fire_aoe)
	attack_sel.add_child(melee_seq)
	# Range Attacks
	var range_seq: BTSequence = BTSequence.new()
	#range_seq.add_child(BTMove.new(1.0, 60))
	range_seq.add_child(BTCheckArea.new("range_attack_hitbox"))
	var range_par: BTParallel = BTParallel.new()
	range_par.add_child_node(BTPlayAnimation.new("range_attack"))
	range_par.add_child_node(BTAttack.new(
		"range_attack", "range_attack_telegraph", [10, 12, 14], r_dmg))
	range_seq.add_child(range_par)
	# spawn fire hazard once below 50
	var range_fire_aoe: BTSequence = BTSequence.new()
	range_fire_aoe.add_child(BTHealthCheck.new(hp))
	range_fire_aoe.add_child(BTASpawnHazard.new("range_attack_telegraph", fire_dmg, burn_tick, 0.5, fire_time))
	range_seq.add_child(range_fire_aoe)
	attack_sel.add_child(range_seq)
	# Adding to Attack Sequence
	attack_seq.add_child(attack_sel)
	return attack_seq

"""
Creates the behavior sequence used when the Colossus dies.
"""
func dead_animation() -> BTSequence:
	var dead_seq: BTSequence = BTSequence.new()
	dead_seq.add_child(BTHealthCheck.new(0))
	dead_seq.add_child(BTPlayAnimation.new("dead"))
	return dead_seq

"""
Creates the Colossus's wake-up behavior.

If the player enters the wake-up area while the Colossus is asleep, the boss
plays its wake-up animation. Otherwise, it stays asleep.
"""
func wake_up() -> BTSequence:
	# are they sleepy
	var good_morning_seq: BTSequence = BTSequence.new()
	good_morning_seq.add_child(BTCheckStatus.new("sleep"))
	var should_i_get_up_sel: BTSelector = BTSelector.new()
	# get up if there is a player
	var time_to_get_up_seq: BTSequence = BTSequence.new()
	time_to_get_up_seq.add_child(BTCheckArea.new("woken_up"))
	time_to_get_up_seq.add_child(BTPlayAnimation.new("wake_up"))
	should_i_get_up_sel.add_child(time_to_get_up_seq)
	# or just stay alseep
	should_i_get_up_sel.add_child(BTPlayAnimation.new("sleep"))
	good_morning_seq.add_child(should_i_get_up_sel)
	return good_morning_seq

"""
Creates the normal movement behavior used to approach the target.
"""
func move_to_target(area: String, speed: float, distance: int) -> BTSequence:
	var move: BTSequence = BTSequence.new()
	move.add_child(BTCheckArea.new(area))
	move.add_child(BTPlayAnimation.new("move"))
	move.add_child(BTMove.new(speed, distance))
	return move

"""
Creates the behavior sequence used while the Colossus is stunned.
"""
func stunned_sequence() -> BTSequence:
	var stun_seq: BTSequence = BTSequence.new()
	stun_seq.add_child(BTCheckStatus.new("stunned"))
	# stunned parallel anaimation
	var stun_par: BTParallel = BTParallel.new()
	stun_par.add_child(BTStunned.new(stun_icon))
	stun_seq.add_child(stun_par)
	return stun_seq
