"""
Assassin Mini-Boss: Script for the second boss encounter.
@authors: Sam Plemmons
"""
extends BossEnemy
class_name Assassin

## Enemy components.
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Animations
@onready var sprite_offset: AnimatedSprite2D = $Offset_Animations
@onready var collision: CollisionShape2D = $sprite_collision

## Tracks successful attacks used to trigger the Assassin's special attack.
var attack_count: int = 0

## Damage and speed boost gained after certain attack conditions are met.
var boost: int = 1.0

## Whether the Assassin is currently invisible/stealthed.
var stealth: bool = false

## Enemy stats.
const max_hp: int = 150
var speed: float = 150

## Status effect icon nodes.
@onready var status_root: Node2D = $StatusIcons
@onready var bleed_icon: Sprite2D = $StatusIcons/bleed_sprite
@onready var stun_icon: Sprite2D = $StatusIcons/stun_sprite
@onready var burn_icon: Sprite2D = $StatusIcons/burn_sprite

"""
Applies stun buildup to the Assassin.

Once the stun buildup reaches the stun bar threshold, the Assassin becomes
stunned for the given duration and the stun icon is displayed.

@param duration: Amount of time the Assassin remains stunned.
"""
func apply_stun(duration: float) -> void:
	if is_stunned_flag:
		return
	cur_stun_val = cur_stun_val + stun_fill
	if cur_stun_val >= stun_bar:
		#enemy is stunned now
		stun_time = duration
		is_stunned_flag = true
		add_status("stun", stun_icon)

"""
Applies burn stacks to the Assassin and displays the burn icon.

@param stacks: Number of burn stacks to add.
"""
func apply_burn(stacks: int = 1) -> void:
	burn_stacks += stacks
	# show icon
	add_status("burn", burn_icon)

"""
Applies bleed stacks to the Assassin and displays the bleed icon.

@param stacks: Number of bleed stacks to add.
"""
func apply_bleed(stacks: int = 1) -> void:
	bleed_stacks += stacks
	# show icon in UI system
	add_status("bleed", bleed_icon)

"""
Initializes the Assassin's navigation, animation state, status icons, stats,
and behavior tree.
"""
func _ready() -> void:
	# NavMesh
	nav_agent.path_desired_distance = 12.0
	nav_agent.target_desired_distance = 12.0
	nav_agent.avoidance_enabled = true
	# Animations
	sprite.visible = false
	sprite_offset.visible = true
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
	current_hp = max_hp
	add_to_group("enemies")
	stun_fill = 50 # 2 stun attacks to stun assassin
	# Context for Nodes
	tree.context = {
		"self": self,
		"target": null,
		"tree": tree
	}
	
	## Behavior Tree
	tree.root = root
	## Dead
	root.add_child(dead_animation())
	## Stunned
	root.add_child(stunned_sequence())
	## Spawn In
	root.add_child(spawn_in(25*boost))
	## Sneak Attack
	root.add_child(sneak_attack(25*boost))
	## Special Teleport Attack Sequence
	root.add_child(magci_attack_sequence(10, 10*boost))
	## Basic Attack Sequence
	root.add_child(basic_attack(5*boost,5*boost))
	## Move to Target
	root.add_child(movement_selector(10, "detect_player", 1.0, 30))
	## Idle
	root.add_child(idle_animation())

"""
Updates the Assassin each frame.

The Assassin faces its current target, updates its behavior tree, and processes
active status effects.
"""
func _process(delta: float) -> void:
	# always face target
	target = tree.context["target"]
	if target != null:
		flip_enemy(target.global_position.x > global_position.x)
	# behavrior tree
	tree.tick(delta)
	_process_status(delta)
	
"""
Processes all active status effects on the Assassin.

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
Repositions the status effect icons based on the Assassin's sprite size.
"""
func _reposition_status_icons():
	var spacing = 18
	var start_offset = Vector2(15, -39)
	for i in range(status_effects.size()):
		var icon = status_effects[i]["node"]
		if icon == null or not is_instance_valid(icon):
			continue
		icon.position = start_offset + Vector2(i * spacing, 0)

"""
Updates the Assassin's target when a body enters its detection area.
"""
func _on_detect_player_body_entered(body: Node2D) -> void:
	if body is Enemy:
		'''
		Target is set to enemy if they have 10 or less HP to then kill
		them (like the N Corp due from Limbus)
		'''
		pass
	elif body is Player:
		tree.context["target"] = body
		print("targetting player", tree.context["target"])

"""
Clears the Assassin's target when the player leaves its detection area.
"""
func _on_detect_player_body_exited(body: Node2D) -> void:
	if body is Enemy:
		'''
		Target is set to enemy if they have 10 or less HP to then kill
		them (like the N Corp due from Limbus)
		'''
		pass
	elif body is Player:
		tree.context["target"] = null
		print("stop targetting player")

"""
Returns whether the Assassin is currently stealthed.
"""
func is_stealth() -> bool:
	return stealth

"""
Sets whether the Assassin is currently stealthed.
"""
func set_stealth(invis: bool) -> void:
	stealth = invis

"""
Creates the behavior sequence used when the Assassin dies.
"""
func dead_animation() -> BTSequence:
	var dead_seq: BTSequence = BTSequence.new()
	dead_seq.add_child(BTHealthCheck.new(0))
	dead_seq.add_child(BTPlayAnimation.new("dead"))
	return dead_seq

"""
Creates the idle behavior selector.

The Assassin plays a normal idle animation while awake and an invisible
animation while asleep.
"""
func idle_animation() -> BTSelector:
	var idle_sel: BTSelector = BTSelector.new()
	# idle animation (awake)
	var idle_seq: BTSequence = BTSequence.new()
	idle_seq.add_child(BTCheckStatus.new("awake"))
	idle_seq.add_child(BTPlayAnimation.new("idle"))
	idle_sel.add_child(idle_seq)
	# invisible animation (asleep)
	var invis_seq: BTSequence = BTSequence.new()
	invis_seq.add_child(BTCheckStatus.new("sleep"))
	invis_seq.add_child(BTPlayAnimation.new("invisible"))
	idle_sel.add_child(invis_seq)
	return idle_sel

"""
Creates the Assassin's spawn-in behavior.

If the player is within sneak attack range while the Assassin is asleep, the
Assassin appears and attacks. Otherwise, the Assassin remains invisible.
"""
func spawn_in(dmg: int) -> BTSequence:
	# spawning in
	var spawn_seq: BTSequence = BTSequence.new()
	spawn_seq.add_child(BTCheckStatus.new("sleep"))
	var stay_invs_sel: BTSelector = BTSelector.new()
	# decide to either spawn in or stay invisible
	var spawning_in_seq: BTSequence = BTSequence.new()
	spawning_in_seq.add_child(BTCheckArea.new("sneak_attack"))
	var spawn_in_par: BTParallel = BTParallel.new()
	spawn_in_par.add_child_node(BTPlayAnimation.new("appear"))
	spawn_in_par.add_child_node(BTAppearAttack.new("appear", "attack_telegraph", [9], dmg))
	spawning_in_seq.add_child(spawn_in_par)
	spawning_in_seq.add_child(BTPlayAnimation.new("invisible"))
	spawning_in_seq.add_child(BTChangeSprite.new(sprite_offset, sprite))
	stay_invs_sel.add_child(spawning_in_seq)
	# stay invisible
	var stay_invs_seq: BTSequence = BTSequence.new()
	stay_invs_seq.add_child(BTChangeSprite.new(sprite, sprite_offset))
	stay_invs_seq.add_child(BTPlayAnimation.new("invisible"))
	stay_invs_sel.add_child(stay_invs_seq)
	spawn_seq.add_child(stay_invs_sel)
	return spawn_seq

"""
Creates the Assassin's sneak attack behavior.

When stealthed and close enough to the player, the Assassin appears, attacks,
then returns to its normal sprite.
"""
func sneak_attack(dmg: int) -> BTSequence:
	var stealth_seq: BTSequence = BTSequence.new()
	stealth_seq.add_child(BTCheckStatus.new("stealth"))
	stealth_seq.add_child(BTCheckArea.new("sneak_attack"))
	var stealth_par: BTParallel = BTParallel.new()
	stealth_par.add_child_node(BTPlayAnimation.new("appear"))
	stealth_par.add_child_node(BTAppearAttack.new("appear", "attack_telegraph", [9], dmg))
	stealth_seq.add_child(stealth_par)
	stealth_seq.add_child(BTPlayAnimation.new("invisible"))
	stealth_seq.add_child(BTChangeSprite.new(sprite_offset, sprite))
	return stealth_seq

"""
Creates the movement selector.

The Assassin first attempts to teleport on cooldown. If teleporting is not
available, it moves toward the target normally.
"""
func movement_selector(cooldown: float, area: String, spd: float, distance: int) -> BTSelector:
	var movement_sel: BTSelector = BTSelector.new()
	var teleport_seq: BTSequence = BTSequence.new()
	var teleport_seq_cooldown: BTCooldown = BTCooldown.new(teleport_seq, cooldown)
	teleport_seq_cooldown.add_child(teleport_seq)
	# add logic to teleport_seq
	teleport_seq.add_child(BTCheckArea.new(area))
	#teleport_seq.add_child(BTCheckTarget.new("health", hp))
	teleport_seq.add_child(BTPlayAnimation.new("vanish"))
	teleport_seq.add_child(BTChangeSprite.new(sprite, sprite_offset))
	teleport_seq.add_child(BTPlayAnimation.new("invisible"))
	# add logic to move to a random point
	teleport_seq.add_child(BTTeleport.new("sneak_attack/detection", "teleport_range/detection", 10))
	# end of teleport logic
	movement_sel.add_child(teleport_seq_cooldown)
	movement_sel.add_child(move_to_target(area, spd, distance))
	return movement_sel

"""
Creates the normal movement behavior used to approach the target.
"""
func move_to_target(area: String, spd: float, distance: int) -> BTSequence:
	var move: BTSequence = BTSequence.new()
	move.add_child(BTCheckArea.new(area))
	move.add_child(BTPlayAnimation.new("move"))
	move.add_child(BTMove.new(spd, distance))
	return move

"""
Creates the Assassin's basic attack behavior.

The behavior checks that the Assassin is visible and that the target is inside
the attack hitbox before playing the attack animation and applying damage.
"""
func basic_attack(bsc_dmg: int, flw_dmg: int) -> BTSequence:
	var attack: BTSequence = BTSequence.new()
	attack.add_child(BTCheckStatus.new("visible"))
	attack.add_child(BTCheckArea.new("attack_hitbox"))
	var attack_par: BTParallel = BTParallel.new()
	attack_par.add_child_node(BTPlayAnimation.new("attack"))
	attack_par.add_child_node(BTAttack.new("attack", "attack_telegraph", [1, 4], bsc_dmg))
	attack.add_child(attack_par)
	attack.add_child(follow_up(flw_dmg))
	return attack

"""
Creates the Assassin's looping follow-up attack chain.
"""
func follow_up(flw_dmg: int) -> BTLoop:
	var follow_up_seq: BTSequence = BTSequence.new()
	var attack_aniamtions: Array = ["attack_first_continuous", "attack_second_continuous"]
	for animation in attack_aniamtions:
		var cont_attack: BTSequence = BTSequence.new()
		cont_attack.add_child(BTCheckArea.new("attack_hitbox"))
		var cont_attack_par: BTParallel = BTParallel.new()
		cont_attack_par.add_child_node(BTPlayAnimation.new(animation))
		cont_attack_par.add_child_node(BTAttack.new(animation, "attack_telegraph", [0, 2], flw_dmg))
		cont_attack.add_child(cont_attack_par)
		follow_up_seq.add_child(cont_attack)
	return BTLoop.new(follow_up_seq)

"""
Creates the Assassin's magic attack behavior.

The magic attack becomes available once the Assassin has reached the required
attack count and the player is inside the magic hitbox.
"""
func magci_attack_sequence(atk_condition: int, magic_dmg: int) -> BTSequence:
	var magic_hand_seq: BTSequence = BTSequence.new()
	magic_hand_seq.add_child(BTCheckStatus.new("visible"))
	magic_hand_seq.add_child(BTCheckArea.new("magic_hitbox"))
	magic_hand_seq.add_child(BTCheckAttackCount.new(atk_condition))
	var magic_par: BTParallel = BTParallel.new()
	magic_par.add_child_node(BTPlayAnimation.new("magic_attack"))
	magic_par.add_child_node(BTAttack.new("magic_attack", "magic_telegraph", [8, 9, 10], magic_dmg))
	magic_hand_seq.add_child(magic_par)
	return magic_hand_seq

"""
Creates the behavior sequence used while the Assassin is stunned.
"""
func stunned_sequence() -> BTSequence:
	var stun_seq: BTSequence = BTSequence.new()
	stun_seq.add_child(BTCheckStatus.new("stunned"))
	# stunned parallel anaimation
	var stun_par: BTParallel = BTParallel.new()
	stun_par.add_child(BTStunned.new(stun_icon))
	stun_seq.add_child(stun_par)
	return stun_seq
