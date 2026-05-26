class_name Player
extends Entity

# ==============================
# CLASS DATA
# ==============================
var class_data: PlayerClassData
 
# ==============================
# COMPONENTS
# ==============================
var attack_component: Node
 
@onready var movement_component: PlayerMovement = $PlayerMovement
@onready var attack_manager: PlayerAttack = $PlayerAttack
@onready var health_component: PlayerHealth = $PlayerHealth
 
# ==============================
# VISUALS
# ==============================
var anim_sprite: AnimatedSprite2D
var class_visuals: Node2D
var player_child: CharacterBody2D
 
# ==============================
# STATE
# ==============================
var dir: String = "Right"
var is_attacking: bool = false
var is_using_special: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var attacker: Node = null

signal class_data_set
 
# bleed stuff
var bleed_stacks: int = 0
var bleed_timer: float = 0.0
var bleed_duration: float = 10
var cur_bleed_duration: float = 0
var bleed_tick_rate: float = 1.0
var bleed_damage: int = 2

# burn stuff
var burn_stacks: int = 0
var burn_timer: float = 0.0
var burn_duration: float = 10
var cur_burn_duration: float = 0
var burn_tick_rate: float = 1.0
var burn_damage: int = 2

#icons
@onready var status_root: Node2D = $StatusIcons
@onready var bleed_icon: Sprite2D = $StatusIcons/bleed_sprite
@onready var stun_icon: Sprite2D = $StatusIcons/stun_sprite
@onready var burn_icon: Sprite2D = $StatusIcons/burn_sprite

var status_effects: Array = []

"""
	Builds a list that holds all of the active status effects applied onto
	the player. Ensures the node is visible.
	
	@param id: The ID (name) of the status effect to turn visible
	@param node: The 2D sprite reference to turn visible
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
	Removes the status effect from the array and ensures all other status effects 
	are positioned accordingly. 
	
	@param: The id (name) of the status effect to remove
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
	This function handles moving the status effects according to however
	many are active currently.
"""
func _reposition_status_icons():
	var spacing = 18
	var start_offset = Vector2(-20, 30)
	
	for i in range(status_effects.size()):
		var icon = status_effects[i]["node"]
		
		if icon == null or not is_instance_valid(icon):
			continue
			
		icon.position = start_offset + Vector2(i * spacing, 0)

"""
	Applies bleed stacks onto the player that damage the player.
	
	@param: How many bleed stacks to add
"""
func apply_bleed(stacks: int = 1) -> void:
	bleed_stacks += stacks
	add_status("bleed", bleed_icon)

"""
	Method that is called every frame to process the bleed on the player. Removes
	bleed and ticks damage on the player's HP accordingly.
	
	@param: Time in seconds
"""
func _process_bleed(delta: float) -> void:
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
	Applies burn stacks onto the player that deal damage to the player.
	
	@param: How many burn stacks to add
"""
func apply_burn(stacks: int = 1) -> void:
	burn_stacks += stacks
	add_status("burn", burn_icon)

"""
	Method that is called every frame to process the burn on the player. Removes
	burn and ticks damage on the player's HP accordingly.
	
	@param: Time in seconds
"""
func _process_burn(delta: float) -> void:
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
 
"""
	Called when the node enters the scene tree for the first time.
	Loads the player class scene, finds the animated sprite, initializes
	all components, and emits class_data_set when ready.
"""
func _ready() -> void:
	#change the sizes to be easier to see to the player
	bleed_icon.scale = Vector2(.04, .04)
	stun_icon.scale = Vector2(.04, .04)
	burn_icon.scale = Vector2(.04, .04)
	
	class_data = PlayerManager.player_data
	
	if class_data == null:
		push_error("No PlayerClassData assigned!")
		return
	
	if not PlayerManager.player_scene_path:
		push_error("No player scene path set in PlayerManager!")
		return
	
	var class_scene = load(PlayerManager.player_scene_path)
	if not class_scene:
		push_error("Failed to load class scene: " + PlayerManager.player_scene_path)
		return
	
	var class_instance = class_scene.instantiate()
	add_child(class_instance)
	class_visuals = class_instance
	player_child = class_instance
	
	anim_sprite = _find_animated_sprite_in_children(class_instance)
	if anim_sprite:
		if not anim_sprite.animation_finished.is_connected(_on_animation_finished):
			anim_sprite.animation_finished.connect(_on_animation_finished)
		anim_sprite.play("Idle_Right")
	else:
		push_error("No AnimatedSprite2D found in class scene!")
	
	# Instantiate the class-specific attack script from the resource
	attack_component = class_data.attack_component_script.new()
	add_child(attack_component) ## THESE TWO LINES CAUSED ME SOOOO MANY HEADACHES
	attack_component.setup(self, class_instance) ## SO ANNOYING
	
	# Initialize components — pass self so they can reference player data
	movement_component.setup(self)
	attack_manager.setup(self)
	health_component.setup(self)
	
	class_data_set.emit()

"""
	Called every physics frame. Delegates all behaviour to components.
	PlayerBase only decides which component gets to run each frame.
"""
func _physics_process(delta: float) -> void:
	_process_burn(delta)
	_process_bleed(delta)
	# Health component owns death and revive ticking
	if health_component.is_dead or health_component.is_reviving:
		health_component.tick(delta)
		return
	
	# Prevent zero-health frames slipping through before die() is called
	if health_component.current_health <= 0:
		health_component.die()
		return
	
	# Stun is a player-level state that blocks both movement and attacks
	if is_stunned:
		_tick_stun(delta)
		return
	
	movement_component.update_direction()
	attack_manager.handle()
	
	if not is_attacking:
		movement_component.handle(delta)
	else:
		velocity = Vector2.ZERO
 
"""
	Counts down the stun timer and returns player to idle when it expires.
"""
func _tick_stun(delta: float) -> void:
	stun_timer -= delta
	velocity = Vector2.ZERO
	
	if stun_timer <= 0:
		is_stunned = false
		remove_status("stun")
		play_idle_animation()
 
"""
	Apply stun to the player when hit with a stun attack.
	Ignored if the player is already dead, reviving, or stunned.
	
	@param: The duration of the stun
"""
func apply_stun(duration: float) -> void:
	if health_component.is_dead or health_component.is_reviving or is_stunned:
		return
	
	add_status("stun", stun_icon)
	is_stunned = true
	stun_timer = duration
	velocity = Vector2.ZERO
	is_attacking = false
	
	if anim_sprite:
		anim_sprite.play("Hurt_" + dir)
 
"""
	Forwards incoming damage to the health component.
	The attack component gets a chance to modify the value first (e.g. blocking).
"""
func take_damage(amount: int) -> void:
	if health_component.is_dead:
		return
	amount = attack_component.modify_incoming_damage(amount)
	health_component.take_damage(amount)
 
# ==============================
# ANIMATION HELPERS
# Called by components so they don't need a direct anim_sprite reference.
# ==============================

"""
	Plays the idle animation for the player's current facing direction.
	Called by components after movement stops or an action completes.
"""
func play_idle_animation() -> void:
	if anim_sprite:
		anim_sprite.play("Idle_" + dir)
	else:
		push_error("No animated sprite available to play idle animation")

"""
	Plays the run animation for the given movement direction and updates
	the player's facing direction accordingly.
"""
func play_run_animation(direction: Vector2) -> void:
	if direction.x < 0:
		dir = "Left"
	elif direction.x > 0:
		dir = "Right"
	
	if anim_sprite:
		anim_sprite.play("Run_" + dir)
	else:
		push_error("No animated sprite available to play run animation")
 
"""
	Called when an animation finishes. Clears attack/revive state
	and returns the player to idle.
"""
func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		play_idle_animation()
	elif health_component.is_reviving:
		health_component.finish_revive()
		play_idle_animation()
 
"""
	Returns the active attack component so external nodes (e.g. Hitbox) can
	reference it without coupling to PlayerBase internals.
"""
func get_attack_component() -> Node:
	return attack_component
 
"""
	Called when the player's hurtbox detects an overlapping area.
	Ignores areas owned by this player and forwards damage from valid sources.
"""
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.owner == self:
		return
	if area.owner.has_method("get_damage"):
		take_damage(area.owner.get_damage())
 
# ==============================
# INTERNAL HELPERS
# ==============================

"""
	Recursively searches a node's children for an AnimatedSprite2D.
	Returns the first one found, or null if none exists in the subtree.
"""
func _find_animated_sprite_in_children(node: Node) -> AnimatedSprite2D:
	for child in node.get_children():
		if child is AnimatedSprite2D:
			return child
		var found := _find_animated_sprite_in_children(child)
		if found:
			return found
	return null
