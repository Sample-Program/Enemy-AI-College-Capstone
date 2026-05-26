class_name PlayerAttack
extends Node
 
# ==============================
# PLAYER REFERENCE
# ==============================
var player: Player
 
# ==============================
# COOLDOWN TIMERS
# ==============================
@onready var light_cooldown_timer: Timer = $LightCooldown
@onready var heavy_cooldown_timer: Timer = $HeavyCooldown
@onready var skill_cooldown_timer: Timer = $SkillCooldown
 
# ==============================
# COOLDOWN STATE
# ==============================
var can_light_attack: bool = true
var can_heavy_attack: bool = true
var can_skill_attack: bool = true
 
"""
	Called by PlayerBase._ready() to inject the player reference and
	connect all cooldown timer signals.
"""
func setup(p: Player) -> void:
	player = p
	
	if has_node("LightCooldown"):
		light_cooldown_timer.timeout.connect(_on_light_cooldown_timeout)
	if has_node("HeavyCooldown"):
		heavy_cooldown_timer.timeout.connect(_on_heavy_cooldown_timeout)
	if has_node("SkillCooldown"):
		skill_cooldown_timer.timeout.connect(_on_skill_cooldown_timeout)
 
"""
	Called every physics frame (when the player is alive and not stunned).
	Reads attack inputs and fires the appropriate attack if off cooldown.
"""
func handle() -> void:
	if Input.is_action_just_pressed("class_special") and not player.is_using_special:
		player.is_using_special = true
		player.attack_component.special()
		return
	
	if Input.is_action_just_pressed("light_attack") and can_light_attack:
		_trigger_attack("light", "LightCooldown", player.class_data.light_cooldown)
		can_light_attack = false
	
	elif Input.is_action_just_pressed("heavy_attack") and can_heavy_attack:
		_trigger_attack("heavy", "HeavyCooldown", player.class_data.heavy_cooldown)
		can_heavy_attack = false
	
	elif Input.is_action_just_pressed("skill_attack") and can_skill_attack:
		_trigger_attack("skill", "SkillCooldown", player.class_data.skill_cooldown)
		can_skill_attack = false
 
# ==============================
# INTERNAL HELPERS
# ==============================
 
"""
	Starts the cooldown timer, flags the player as attacking,
	plays the attack animation, and notifies the class attack component.
"""
func _trigger_attack(attack_type: String, timer_node: String, cooldown: float) -> void:
	if has_node(timer_node):
		get_node(timer_node).start(cooldown)
	
	player.is_attacking = true
	
	var anim := attack_type.capitalize() + "_" + player.dir
	if player.anim_sprite:
		player.anim_sprite.play(anim)
	else:
		push_error("No animated sprite available to play: " + anim)
	
	player.attack_component.attack(attack_type)

"""
	Reduces the remaining heavy and skill cooldown timers as a reward for
	landing a light attack. Restarts each timer with the reduced time.
""" 
func _reduce_cooldowns() -> void:
	if heavy_cooldown_timer.time_left > 1:
		var new_time = heavy_cooldown_timer.time_left - 1
		heavy_cooldown_timer.stop()
		heavy_cooldown_timer.wait_time = new_time
		heavy_cooldown_timer.start()
	
	if skill_cooldown_timer.time_left > 2:
		var new_time = skill_cooldown_timer.time_left - 2
		skill_cooldown_timer.stop()
		skill_cooldown_timer.wait_time = new_time
		skill_cooldown_timer.start()

# ==============================
# TIMER CALLBACKS
# ==============================
 
"""
	Re-enables light attack after cooldown expires.
"""
func _on_light_cooldown_timeout() -> void:
	can_light_attack = true
	light_cooldown_timer.stop()
 
"""
	Re-enables heavy attack after cooldown expires.
"""
func _on_heavy_cooldown_timeout() -> void:
	can_heavy_attack = true
	heavy_cooldown_timer.stop()
 
"""
	Re-enables skill attack after cooldown expires.
"""
func _on_skill_cooldown_timeout() -> void:
	can_skill_attack = true
	skill_cooldown_timer.stop()
