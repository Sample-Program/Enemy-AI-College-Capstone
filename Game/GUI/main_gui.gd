"""
	This script handles the interaction between user and game when starting up.
	It sets all of the visual aspects that the player will be interacting with
	and seeing for their duration of the game.
	@author: Stephen Donald
"""

extends Control

## Health and Stamina Bar Variables
@onready var health_bar = $Bars/Health_Bar/Health_Progress
@onready var health_perc = $Bars/Health_Bar/Health_Progress/Health_Amount

@onready var stamina_bar = $Bars/Stamina_Bar/Stamina_Progress
@onready var stamina_perc = $Bars/Stamina_Bar/Stamina_Progress/Stamina_Amount

## Attack Cooldown Variables
@onready var input_label_light = $AttackCooldowns/Cooldowns/Light/InputLight
@onready var input_label_heavy = $AttackCooldowns/Cooldowns/Heavy/InputHeavy
@onready var input_label_skill = $AttackCooldowns/Cooldowns/Skill/InputSkill

@onready var light_prog = $AttackCooldowns/Cooldowns/Light/LightProgress
@onready var heavy_prog = $AttackCooldowns/Cooldowns/Heavy/HeavyProgress
@onready var skill_prog = $AttackCooldowns/Cooldowns/Skill/SkillProgress

var input_arr: Array[String]

var parentMain
var parent

"""
	This function sets the parents and values that the player will be using. It also
	sets the names and text for certain on screen effects that the player will want
	to read.
"""
func _ready():
	parentMain = get_parent()
	parent = parentMain.get_parent()
	
	# Update labels when joypad is connected/disconnected
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_input_labels()
	
	if parent.class_data == null:
		await parent.class_data_set
	
	var light_image = $AttackCooldowns/Cooldowns/Light/LightProgress/LightImage
	var heavy_image = $AttackCooldowns/Cooldowns/Heavy/HeavyProgress/HeavyImage
	var skill_image = $AttackCooldowns/Cooldowns/Skill/SkillProgress/SkillImage
	
	if parent.class_data.type == "Ranger":
		light_image.texture = load("res://GUI/AttackCooldownImages/Light_Progress_Ranger.png")
		heavy_image.texture = load("res://GUI/AttackCooldownImages/Heavy_Progress_Ranger.png")
		skill_image.texture = load("res://GUI/AttackCooldownImages/Skill_Progress_Ranger.png")
		
		light_prog.texture_progress = load("res://GUI/AttackCooldownImages/Cooldown_Fill_Ranger.png")
		heavy_prog.texture_progress = load("res://GUI/AttackCooldownImages/Cooldown_Fill_Ranger.png")
		skill_prog.texture_progress = load("res://GUI/AttackCooldownImages/Cooldown_Fill_Ranger.png")
	
	elif parent.class_data.type == "Pyromancer":
		light_image.texture = load("res://GUI/AttackCooldownImages/Light_Progress_Pyro.png")
		heavy_image.texture = load("res://GUI/AttackCooldownImages/Heavy_Progress_Pyro.png")
		skill_image.texture = load("res://GUI/AttackCooldownImages/Skill_Progress_Pyro.png")
		
		light_prog.texture_progress = load("res://GUI/AttackCooldownImages/Cooldown_Fill_Pyro.png")
		heavy_prog.texture_progress = load("res://GUI/AttackCooldownImages/Cooldown_Fill_Pyro.png")
		skill_prog.texture_progress = load("res://GUI/AttackCooldownImages/Cooldown_Fill_Pyro.png")
	
	setup_bars()

func _update_input_labels() -> void:
	input_arr.clear()
	var using_controller = Input.get_connected_joypads().size() > 0
	
	input_arr.append(_get_action_label("light_attack", using_controller))
	input_arr.append(_get_action_label("heavy_attack", using_controller))
	input_arr.append(_get_action_label("skill_attack", using_controller))
	
	input_arr = clean_text(input_arr)
	
	input_label_light.text = input_arr[0]
	input_label_heavy.text = input_arr[1]
	input_label_skill.text = input_arr[2]

func _get_action_label(action: String, prefer_controller: bool) -> String:
	var events = InputMap.action_get_events(action)
	var fallback = ""

	for event in events:
		if prefer_controller and event is InputEventJoypadButton:
			return event.as_text()
		if prefer_controller and event is InputEventJoypadMotion:
			return event.as_text()
		if not prefer_controller and event is InputEventKey:
			return event.as_text()
		if fallback == "":
			fallback = event.as_text()

	return fallback  # rollback

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_input_labels()

"""
	This function removes all text from on screene ffects in the inp_arr.
	@param: An array of strings that holds all of the text
"""
func clean_text(inp_arr: Array[String]):
	for i in range(inp_arr.size()):
		if inp_arr[i].ends_with(" Button"):
			inp_arr[i] = inp_arr[i].replace(" Button", "")
		if inp_arr[i].ends_with(" (Physical)"):
			inp_arr[i] = inp_arr[i].replace(" (Physical)", "")
		
		# Controller cleanup - extract just "X/Square"
		if "Left Action" in inp_arr[i] or "Joypad Button" in inp_arr[i]:
			inp_arr[i] = _parse_joypad_label(inp_arr[i])
	
	return inp_arr

func _parse_joypad_label(text: String) -> String:
	# Extract the right keys
	var start = text.find("(")
	var end = text.find(")")
	if start == -1 or end == -1:
		return text
	
	var inner = text.substr(start + 1, end - start - 1)
	var parts = inner.split(", ")
	
	# Pull out just the button names
	var xbox = ""
	var sony = ""
	for part in parts:
		if part.begins_with("Xbox "):
			xbox = part.replace("Xbox ", "")
		elif part.begins_with("Sony "):
			sony = part.replace("Sony ", "")
	
	if xbox != "" and sony != "":
		return "%s/%s" % [xbox, sony]
	elif xbox != "":
		return xbox
	elif sony != "":
		return sony
	
	return text  # rollback

func setup_bars():
	## Health Bar
	health_bar.max_value = parent.class_data.max_hp
	health_bar.value = parent.health_component.current_health
	health_perc.max_value = parent.class_data.max_hp
	health_perc.value = parent.health_component.current_health
	
	## Stamina Bar
	stamina_bar.max_value = parent.class_data.max_stamina
	stamina_bar.value = parent.movement_component.current_stamina
	stamina_perc.max_value = parent.class_data.max_stamina
	stamina_perc.value = parent.movement_component.current_stamina
	
	## Cooldown Timers
	light_prog.max_value = parent.class_data.light_cooldown
	heavy_prog.max_value = parent.class_data.heavy_cooldown
	skill_prog.max_value = parent.class_data.skill_cooldown

"""
	This function sets the health to the parent health, stamina to the
	parent stamina, and handles the cooldown timers on the skills.
	@param: The time elapsed in seconds since the previous frame
"""
func _process(_delta: float):
	# Update values every frame
	health_bar.value = parent.health_component.current_health
	health_perc.value = parent.health_component.current_health
	
	stamina_bar.value = parent.movement_component.current_stamina
	stamina_perc.value = parent.movement_component.current_stamina
	
	# Update cooldown timers
	light_prog.value = parent.attack_manager.light_cooldown_timer.time_left
	heavy_prog.value = parent.attack_manager.heavy_cooldown_timer.time_left
	skill_prog.value = parent.attack_manager.skill_cooldown_timer.time_left
