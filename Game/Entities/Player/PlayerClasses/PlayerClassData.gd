extends Resource

class_name PlayerClassData

# Class
@export var type: String

# Movement
@export var walk_speed: float = 0.0
@export var run_multiplier: float = 0.0

# Health
@export var max_hp: int = 0
@export var revive_time = 0.0
@export var health_tick_rate = 0.0
@export var health_tick_amount = 0

# Stamina
@export var max_stamina: float = 0.0
@export var stamina_burn: float = 0.0
@export var stamina_recovery: float = 0.0
@export var stamina_recovery_delay: float = 0.0

# Attack Damage
@export var light_damage: int = 0
@export var heavy_damage: int = 0
@export var skill_damage: int = 0

# Cooldowns
@export var light_cooldown: float = 0.0
@export var heavy_cooldown: float = 0.0
@export var skill_cooldown: float = 0.0

# Scripts
@export var attack_component_script: Script

# Scene
@export var player_scene: PackedScene
